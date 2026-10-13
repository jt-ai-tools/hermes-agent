---
sidebar_position: 7
title: "子代理委派"
description: "透過 delegate_task 產生隔離的子代理以執行平行工作流"
---

# 子代理委派 (Subagent Delegation)

`delegate_task` 工具可產生隔離的 AIAgent 子實例，這些子代理擁有獨立的上下文、受限的工具集以及各自的終端機工作階段。每個子代理都會開啟一段全新的對話並獨立運作 — 僅有其最終摘要會進入父代理的上下文中。

## 單一任務 (Single Task)

```python
delegate_task(
    goal="除錯測試失敗的原因",
    context="錯誤訊息：test_foo.py 第 42 行斷言失敗 (assertion fail)",
    toolsets=["terminal", "file"]
)
```

## 平行批次 (Parallel Batch)

最多可同時執行 3 個並行子代理：

```python
delegate_task(tasks=[
    {"goal": "研究主題 A", "toolsets": ["web"]},
    {"goal": "研究主題 B", "toolsets": ["web"]},
    {"goal": "修復建置 (build) 問題", "toolsets": ["terminal", "file"]}
])
```

## 子代理上下文的運作方式

:::warning 重要：子代理對先前對話一無所知
子代理啟動時會開啟一段 **完全全新的對話**。它們對父代理的對話歷史、先前的工具呼叫或委派前討論過的任何內容都一無所知。子代理唯一的內容背景來自您提供的 `goal`（目標）與 `context`（上下文）欄位。
:::

這意味著您必須傳遞子代理所需之 **一切** 資訊：

```python
# 錯誤示範 - 子代理完全不知道「這個錯誤」是什麼
delegate_task(goal="修復錯誤")

# 正確示範 - 子代理擁有所有必要的資訊
delegate_task(
    goal="修復 api/handlers.py 中的 TypeError",
    context="""檔案 api/handlers.py 在第 47 行發生 TypeError：
    'NoneType' object has no attribute 'get'。
    process_request() 函式從 parse_body() 接收一個字典 (dict)，
    但當 Content-Type 缺失時，parse_body() 會傳回 None。
    專案路徑為 /home/user/myproject，使用 Python 3.11。"""
)
```

子代理會收到根據您的目標與內容背景建立的專屬系統提示詞，引導其完成任務並提供結構化的摘要，包含：做了什麼、發現了什麼、修改了哪些檔案以及遇到了哪些問題。

## 實際應用範例

### 平行研究 (Parallel Research)

同時研究多個主題並蒐集摘要：

```python
delegate_task(tasks=[
    {
        "goal": "研究 2025 年 WebAssembly 的現況",
        "context": "重點：瀏覽器支援、非瀏覽器執行環境、語言支援",
        "toolsets": ["web"]
    },
    {
        "goal": "研究 2025 年 RISC-V 的採用現況",
        "context": "重點：伺服器晶片、嵌入式系統、軟體生態系",
        "toolsets": ["web"]
    },
    {
        "goal": "研究 2025 年量子運算的進展",
        "context": "重點：糾錯技術突破、實際應用、關鍵廠商",
        "toolsets": ["web"]
    }
])
```

### 程式碼審閱與修復 (Code Review + Fix)

將審閱與修復工作流委派至全新的上下文中：

```python
delegate_task(
    goal="審閱身分驗證模組的安全問題並修復發現的漏洞",
    context="""專案位於 /home/user/webapp。
    驗證模組檔案：src/auth/login.py, src/auth/jwt.py, src/auth/middleware.py。
    專案使用 Flask, PyJWT 與 bcrypt。
    重點：SQL 注入、JWT 驗證、密碼處理、工作階段管理。
    修復發現的問題並執行測試套件 (pytest tests/auth/)。""",
    toolsets=["terminal", "file"]
)
```

### 多檔案重構 (Multi-File Refactoring)

委派可能會導致父代理上下文膨脹的大型重構任務：

```python
delegate_task(
    goal="重構 src/ 下的所有 Python 檔案，將 print() 取代為適當的 logging",
    context="""專案位於 /home/user/myproject。
    使用 'logging' 模組，配置為 logger = logging.getLogger(__name__)。
    將 print() 呼叫替換為對應的日誌層級：
    - print(f"Error: ...") -> logger.error(...)
    - print(f"Warning: ...") -> logger.warning(...)
    - print(f"Debug: ...") -> logger.debug(...)
    - 其他 print -> logger.info(...)
    不要修改測試檔案或 CLI 輸出中的 print()。
    重構後執行 pytest 以確認功能正常。""",
    toolsets=["terminal", "file"]
)
```

## 批次模式細節 (Batch Mode Details)

當您提供 `tasks` 陣列時，子代理會透過執行緒池 (Thread pool) **平行** 執行：

- **最大並行數**：3 個任務（若 `tasks` 陣列過長，會被截斷至 3 個）。
- **執行緒池**：使用 `ThreadPoolExecutor`，並配置 `MAX_CONCURRENT_CHILDREN = 3`。
- **進度顯示**：在 CLI 模式下，會以樹狀視圖即時顯示每個子代理的工具呼叫及任務完成狀態。在閘道器 (Gateway) 模式下，進度會被批次彙總並傳回給父代理。
- **結果排序**：結果會根據任務索引進行排序，確保與輸入順序一致。
- **中斷傳播 (Interrupt propagation)**：中斷父代理（例如發送新訊息）會同時中斷所有執行中的子代理。

單一任務委派則直接執行，不產生執行緒池開銷。

## 模型覆寫 (Model Override)

您可以透過 `config.yaml` 為子代理配置不同的模型 — 這對於將簡單任務委派給更便宜或更快的模型非常有用：

```yaml
# 在 ~/.hermes/config.yaml 中
delegation:
  model: "google/gemini-flash-2.0"    # 為子代理使用較便宜的模型
  provider: "openrouter"              # (選填) 將子代理路由至不同的供應商
```

若省略此設定，子代理將使用與父代理相同的模型。

## 工具集選取秘訣 (Toolset Selection Tips)

`toolsets` 參數決定了子代理可以存取的工具。請根據任務類型進行選取：

| 工具集模式 | 使用情境 |
|----------------|----------|
| `["terminal", "file"]` | 程式碼編寫、除錯、檔案編輯、建置 (Builds) |
| `["web"]` | 研究、事實查核、查閱文件 |
| `["terminal", "file", "web"]` | 全端任務（預設值） |
| `["file"]` | 唯讀分析、不執行程式碼的審閱 |
| `["terminal"]` | 系統管理、行程管理 |

無論您如何設定，以下工具集對子代理而言 **一律被封鎖**：
- `delegation` — 禁止遞迴委派（防止產生無限循環的子代理）。
- `clarify` — 子代理無法與使用者互動。
- `memory` — 無法寫入共享的持久性記憶體。
- `code_execution` — 子代理應採用逐步推理。
- `send_message` — 無法產生跨平台的副作用（例如發送 Telegram 訊息）。

## 最大迭代次數 (Max Iterations)

每個子代理都有迭代上限（預設為 50），控制其可執行的工具呼叫輪次：

```python
delegate_task(
    goal="快速檔案檢查",
    context="檢查 /etc/nginx/nginx.conf 是否存在並列印前 10 行",
    max_iterations=10  # 簡單任務，不需要太多輪次
)
```

## 深度限制 (Depth Limit)

委派設有 **2 層深度限制** — 父代理（深度 0）可以產生子代理（深度 1），但子代理無法進一步委派。這可防止失控的遞迴委派鏈。

## 關鍵特性總結

- 每個子代理擁有 **各自的終端機工作階段**（與父代理分開）。
- **無巢狀委派** — 子代理無法進一步委派（不會產生孫代理）。
- 子代理 **無法** 呼叫：`delegate_task`, `clarify`, `memory`, `send_message`, `execute_code`。
- **中斷傳播** — 中斷父代理會同時中斷所有活動中的子代理。
- 僅最終摘要進入父代理上下文，有效提升標記 (Token) 使用效率。
- 子代理繼承父代理的 **API 金鑰、供應商配置與憑證池**（使其能在遇到速率限制時輪轉金鑰）。

## 委派 (Delegation) vs 執行程式碼 (execute_code)

| 因素 | delegate_task | execute_code |
|--------|--------------|-------------|
| **推理方式** | 完整的 LLM 推理迴圈 | 僅執行 Python 程式碼 |
| **上下文** | 獨立且全新的對話 | 無對話，僅執行指令稿 |
| **工具存取** | 具備推理能力的所有非封鎖工具 | 透過 RPC 存取 7 種工具，無推理能力 |
| **平行處理** | 最多 3 個並行子代理 | 單一指令稿 |
| **最佳用途** | 需要判斷力的複雜任務 | 機械式的多步驟流程 |
| **Token 成本** | 較高（完整 LLM 迴圈） | 較低（僅傳回 stdout） |
| **使用者互動** | 無（子代理無法進行澄清） | 無 |

**經驗法則**：當子任務需要推理、判斷或多步驟問題解決時，請使用 `delegate_task`。當您需要機械式的資料處理或指令式工作流時，請使用 `execute_code`。

## 設定參考 (Configuration)

```yaml
# 在 ~/.hermes/config.yaml 中
delegation:
  max_iterations: 50                             # 每個子代理的最大輪次（預設 50）
  default_toolsets: ["terminal", "file", "web"]  # 預設工具集
  model: "google/gemini-3-flash-preview"         # (選填) 模型覆寫
  provider: "openrouter"                         # (選填) 供應商覆寫

# 或是直接使用自定義端點而非供應商：
delegation:
  model: "qwen2.5-coder"
  base_url: "http://localhost:1234/v1"
  api_key: "local-key"
```

:::tip
代理會根據任務的複雜程度自動處理委派。您不需要明確要求它委派 — 它會在合理的情況下自動執行。
:::
