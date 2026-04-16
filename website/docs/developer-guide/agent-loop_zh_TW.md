---
sidebar_position: 3
title: "代理迴圈內部原理 (Agent Loop Internals)"
description: "深入解析 AIAgent 的執行、API 模式、工具、回呼以及回退 (fallback) 行為"
---

# 代理迴圈內部原理 (Agent Loop Internals)

核心編排引擎是 `run_agent.py` 中的 `AIAgent` 類別——約 10,700 行程式碼，處理從提示詞組裝到工具分派，再到提供者容錯移轉 (failover) 的所有事務。

## 核心職責

`AIAgent` 負責：

- 透過 `prompt_builder.py` 組裝有效的系統提示詞和工具結構描述 (tool schemas)。
- 選擇正確的提供者/API 模式（`chat_completions`、`codex_responses`、`anthropic_messages`）。
- 發起支援取消的可中斷模型呼叫。
- 執行工具呼叫（循序執行或透過執行緒池平行執行）。
- 以 OpenAI 訊息格式維護對話歷史紀錄。
- 處理壓縮、重試以及備援 (fallback) 模型切換。
- 追蹤父代理與子代理之間的疊代預算 (iteration budgets)。
- 在上下文遺失前清除持久化記憶體 (persistent memory)。

## 兩個入口點

```python
# 簡單介面 — 回傳最終回應字串
response = agent.chat("修正 main.py 中的錯誤")

# 完整介面 — 回傳包含訊息、元數據、使用統計的字典
result = agent.run_conversation(
    user_message="修正 main.py 中的錯誤",
    system_message=None,           # 若省略則自動建置
    conversation_history=None,      # 若省略則從工作階段自動載入
    task_id="task_abc123"
)
```

`chat()` 是對 `run_conversation()` 的薄層封裝，僅從結果字典中提取 `final_response` 欄位。

## API 模式

Hermes 支援三種 API 執行模式，根據提供者選擇、明確參數及基礎 URL 啟發式演算法 (heuristics) 進行解析：

| API 模式 | 用途 | 用戶端類型 |
|----------|----------|-------------|
| `chat_completions` | 相容 OpenAI 的端點（OpenRouter、自定義、大多數提供者） | `openai.OpenAI` |
| `codex_responses` | OpenAI Codex / Responses API | 使用 Responses 格式的 `openai.OpenAI` |
| `anthropic_messages` | 原生 Anthropic Messages API | 透過適配器的 `anthropic.Anthropic` |

模式決定了訊息的格式化方式、工具呼叫的結構、回應的解析方式，以及快取/串流的工作原理。這三種模式在 API 呼叫前後都會收斂到相同的內部訊息格式（OpenAI 風格的 `role`/`content`/`tool_calls` 字典）。

**模式解析順序：**
1. 建構子中明確指定的 `api_mode` 參數（最高優先順序）。
2. 提供者專屬檢測（例如 `anthropic` 提供者 → `anthropic_messages`）。
3. 基礎 URL 啟發式演算法（例如 `api.anthropic.com` → `anthropic_messages`）。
4. 預設值：`chat_completions`。

## 輪次生命週期 (Turn Lifecycle)

代理迴圈的每次疊代都遵循以下序列：

```text
run_conversation()
  1. 若未提供則產生 task_id
  2. 將使用者訊息附加到對話歷史紀錄
  3. 建構或重複使用快取的系統提示詞 (prompt_builder.py)
  4. 檢查是否需要執行前壓縮（超過 50% 上下文）
  5. 從對話歷史紀錄建構 API 訊息
     - chat_completions: 直接使用 OpenAI 格式
     - codex_responses: 轉換為 Responses API 輸入項目
     - anthropic_messages: 透過 anthropic_adapter.py 進行轉換
  6. 注入暫時性提示層 (ephemeral prompt layers)（預算警告、上下文壓力）
  7. 若使用 Anthropic 則套用提示詞快取標記
  8. 發起可中斷的 API 呼叫 (_api_call_with_interrupt)
  9. 解析回應：
     - 若有工具呼叫 (tool_calls)：執行工具、附加結果，並回到步驟 5
     - 若為文字回應：持久化工作階段、必要時清除記憶體，然後回傳
```

### 訊息格式

所有訊息在內部均使用相容 OpenAI 的格式：

```python
{"role": "system", "content": "..."}
{"role": "user", "content": "..."}
{"role": "assistant", "content": "...", "tool_calls": [...]}
{"role": "tool", "tool_call_id": "...", "content": "..."}
```

推理內容（來自支援擴展思考的模型）存儲在 `assistant_msg["reasoning"]` 中，並可選擇透過 `reasoning_callback` 顯示。

### 訊息交替規則

代理迴圈強制執行嚴格的訊息角色交替：

- 在系統訊息之後：`使用者 → 代理 (Assistant) → 使用者 → 代理 → ...`
- 工具呼叫期間：`代理 (帶有 tool_calls) → 工具 → 工具 → ... → 代理`
- **絕對不允許** 連續兩個代理訊息
- **絕對不允許** 連續兩個使用者訊息
- **僅** `tool` 角色可以有連續的條目（平行工具結果）

提供者會驗證這些序列，並拒絕格式錯誤的歷史紀錄。

## 可中斷的 API 呼叫

API 請求被封裝在 `_api_call_with_interrupt()` 中，它在背景執行緒執行實際的 HTTP 呼叫，同時監控中斷事件：

```text
┌──────────────────────┐     ┌──────────────┐
│  主執行緒             │     │  API 執行緒   │
│  等待：               │────▶│  HTTP POST    │
│  - 回應就緒           │     │  至提供者      │
│  - 中斷事件           │     └──────────────┘
│  - 超時               │
└──────────────────────┘
```

當中斷發生時（使用者發送新訊息、執行 `/stop` 指令或收到訊號）：
- API 執行緒被放棄（回應被丟棄）。
- 代理可以處理新輸入或乾淨地關閉。
- 不會將部分回應注入對話歷史紀錄中。

## 工具執行

### 順序執行 vs 平行執行

當模型回傳工具呼叫時：

- **單個工具呼叫** → 直接在主執行緒執行。
- **多個工具呼叫** → 透過 `ThreadPoolExecutor` 平行執行。
  - 例外：標記為互動式的工具（例如 `clarify`）會強制順序執行。
  - 無論完成順序為何，結果都會按照原始工具呼叫順序重新插入。

### 執行流程

```text
對 response.tool_calls 中的每個 tool_call：
    1. 從 tools/registry.py 解析處理常式 (handler)
    2. 觸發 pre_tool_call 外掛掛鉤 (plugin hook)
    3. 檢查是否為危險指令 (tools/approval.py)
       - 若為危險指令：調用 approval_callback，等待使用者確認
    4. 使用參數 + task_id 執行處理常式
    5. 觸發 post_tool_call 外掛掛鉤
    6. 將 {"role": "tool", "content": result} 附加到歷史紀錄
```

### 代理層級工具 (Agent-Level Tools)

某些工具在到達 `handle_function_call()` *之前* 會被 `run_agent.py` 攔截：

| 工具 | 攔截原因 |
|------|--------------------|
| `todo` | 讀取/寫入代理本地的任務狀態 |
| `memory` | 寫入具有字元限制的持久化記憶體檔案 |
| `session_search` | 透過代理的工作階段資料庫查詢對話歷史紀錄 |
| `delegate_task` | 產生具有隔離上下文的子代理 |

這些工具直接修改代理狀態，並回傳合成的工具結果，而不經過註冊表。

## 回呼介面 (Callback Surfaces)

`AIAgent` 支援平台專屬的回呼，可在 CLI、閘道和 ACP 整合中實現即時進度顯示：

| 回呼 | 觸發時機 | 使用者 |
|----------|-----------|---------|
| `tool_progress_callback` | 每個工具執行前後 | CLI 轉輪、閘道進度訊息 |
| `thinking_callback` | 模型開始/停止思考時 | CLI "thinking..." 指示器 |
| `reasoning_callback` | 模型回傳推理內容時 | CLI 推理內容顯示、閘道推理區塊 |
| `clarify_callback` | 呼叫 `clarify` 工具時 | CLI 輸入提示、閘道互動式訊息 |
| `step_callback` | 每個完整的代理輪次後 | 閘道步驟追蹤、ACP 進度 |
| `stream_delta_callback` | 每個串流 Token（啟用時） | CLI 串流顯示 |
| `tool_gen_callback` | 從串流解析出工具呼叫時 | CLI 轉輪中的工具預覽 |
| `status_callback` | 狀態變更（思考中、執行中等） | ACP 狀態更新 |

## 預算與回退 (Fallback) 行為

### 疊代預算 (Iteration Budget)

代理透過 `IterationBudget` 追蹤疊代：

- 預設值：90 次疊代（可透過 `agent.max_turns` 配置）。
- 每個代理都有自己的預算。子代理獲得獨立的預算，上限為 `delegation.max_iterations`（預設為 50）——父代理與子代理的總疊代次數可以超過父代理的上限。
- 達到 100% 時，代理停止並回傳已完成工作的摘要。

### 備援模型 (Fallback Model)

當主模型失敗時（429 速率限制、5xx 伺服器錯誤、401/403 驗證錯誤）：

1. 檢查配置中的 `fallback_providers` 列表。
2. 按順序嘗試每個備援。
3. 成功後，使用新提供者繼續對話。
4. 若遇到 401/403，在容錯移轉前嘗試重新整理憑證。

備援系統也獨立覆蓋了輔助任務——視覺、壓縮、網頁提取和工作階段搜尋各自擁有自己的備援鏈，可透過 `auxiliary.*` 配置區段進行設定。

## 壓縮與持久化

### 何時觸發壓縮

- **執行前 (Preflight)**（API 呼叫前）：如果對話超過模型上下文視窗的 50%。
- **閘道自動壓縮**：如果對話超過 85%（更積極，在輪次之間執行）。

### 壓縮期間發生的事

1. 記憶體先清除到磁碟（防止數據遺失）。
2. 中間的對話輪次被縮減為精簡摘要。
3. 保留最後 N 條訊息不變（`compression.protect_last_n`，預設為 20）。
4. 工具呼叫/結果訊息對會保持在一起（絕不拆分）。
5. 產生新的工作階段系譜 ID (lineage ID)（壓縮會建立一個「子」工作階段）。

### 工作階段持久化

每輪之後：
- 訊息儲存到工作階段存儲區（透過 `hermes_state.py` 使用 SQLite）。
- 記憶體變更清除到 `MEMORY.md` / `USER.md`。
- 工作階段稍後可透過 `/resume` 或 `hermes chat --resume` 恢復。

## 關鍵原始碼檔案

| 檔案 | 用途 |
|------|---------|
| `run_agent.py` | AIAgent 類別 — 完整的代理迴圈（約 10,700 行） |
| `agent/prompt_builder.py` | 從記憶體、技能、上下文檔案、個性組裝系統提示詞 |
| `agent/context_engine.py` | ContextEngine ABC — 可插拔的上下文管理 |
| `agent/context_compressor.py` | 預設引擎 — 有損摘要演算法 |
| `agent/prompt_caching.py` | Anthropic 提示詞快取標記與快取指標 |
| `agent/auxiliary_client.py` | 用於側邊任務（視覺、摘要）的輔助 LLM 用戶端 |
| `model_tools.py` | 工具結構描述收集、`handle_function_call()` 分派 |

## 相關文件

- [提供者執行期解析 (Provider Runtime Resolution)](./provider-runtime.md)
- [提示詞組裝 (Prompt Assembly)](./prompt-assembly.md)
- [上下文壓縮與提示詞快取 (Context Compression & Prompt Caching)](./context-compression-and-caching.md)
- [工具執行期 (Tools Runtime)](./tools-runtime.md)
- [架構概覽 (Architecture Overview)](./architecture.md)
