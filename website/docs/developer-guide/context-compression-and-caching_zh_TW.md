# 上下文壓縮與快取

Hermes Agent 使用雙重壓縮系統與 Anthropic 提示詞快取機制，在長對話中高效管理上下文視窗的使用量。

原始碼檔案：`agent/context_engine.py` (ABC), `agent/context_compressor.py` (預設引擎), `agent/prompt_caching.py`, `gateway/run.py` (對話衛生), `run_agent.py` (搜尋 `_compress_context`)


## 可插拔上下文引擎

上下文管理是建立在 `ContextEngine` 抽象基底類別 (ABC) 之上的 (`agent/context_engine.py`)。內建的 `ContextCompressor` 是預設實作，但插件可以將其替換為其他替代引擎（例如：無損上下文管理，Lossless Context Management）。

```yaml
context:
  engine: "compressor"    # 預設 — 內建的有損摘要
  engine: "lcm"           # 範例 — 提供無損上下文的插件
```

引擎負責：
- 決定何時觸發緊實化 (compaction) (`should_compress()`)
- 執行緊實化 (`compress()`)
- （選配）公開代理可呼叫的工具（例如：`lcm_grep`）
- 追蹤 API 回應中的 Token 使用量

選擇機制是由 `config.yaml` 中的 `context.engine` 配置驅動。解析順序如下：
1. 檢查 `plugins/context_engine/<名稱>/` 目錄
2. 檢查通用插件系統 (`register_context_engine()`)
3. 降級回內建的 `ContextCompressor`

插件引擎**絕不會自動啟用** — 使用者必須顯式將 `context.engine` 設定為插件的名稱。預設值 `"compressor"` 始終使用內建引擎。

可透過 `hermes plugins` → 提供者插件 (Provider Plugins) → 上下文引擎 (Context Engine) 進行配置，或直接編輯 `config.yaml`。

關於建構上下文引擎插件，請參閱 [上下文引擎插件](./context-engine-plugin)。

## 雙重壓縮系統

Hermes 擁有兩層獨立運作的壓縮層：

```
                     ┌──────────────────────────┐
  傳入訊息            │   閘道器對話衛生           │  在上下文達到 85% 時觸發
  ─────────────────► │   (代理前，粗略估算)     │  大型對話的預防措施
                     └─────────────┬────────────┘
                                   │
                                   ▼
                     ┌──────────────────────────┐
                     │   代理 ContextCompressor │  在上下文達到 50% 時觸發 (預設)
                     │   (迴圈內，精確 Token)   │  常規上下文管理
                     └──────────────────────────┘
```

### 1. 閘道器對話衛生 (85% 閾值)

位於 `gateway/run.py` (搜尋 `Session hygiene: auto-compress`)。這是一項在代理處理訊息之前執行的**安全預防措施**。它能防止當對話在兩次輪次之間增長過快（例如：Telegram/Discord 的隔夜訊息累積）時導致 API 失敗。

- **閾值**：固定為模型上下文長度的 85%
- **Token 來源**：優先使用上一輪 API 實際報告的 Token 數；若無則降級回粗略的字元估算 (`estimate_messages_tokens_rough`)
- **觸發條件**：僅當 `len(history) >= 4` 且已啟用壓縮時觸發
- **目的**：捕捉那些避開了代理自身壓縮器的對話

閘道器衛生閾值刻意設定得比代理壓縮器高。若將其設定為 50%（與代理相同），會導致長對話在每一輪都發生過早壓縮。

### 2. 代理 ContextCompressor (50% 閾值，可配置)

位於 `agent/context_compressor.py`。這是**主要的壓縮系統**，在代理的工具迴圈內執行，並能存取精確的、API 報告的 Token 計數。


## 配置

所有壓縮設定皆從 `config.yaml` 的 `compression` 鍵讀取：

```yaml
compression:
  enabled: true              # 啟用/停用壓縮 (預設: true)
  threshold: 0.50            # 上下文視窗的佔比 (預設: 0.50 = 50%)
  target_ratio: 0.20         # 壓縮後保留尾部訊息的 Token 比例 (預設: 0.20)
  protect_last_n: 20         # 始終保護的最少尾部訊息數 (預設: 20)

# 摘要模型/提供者在 auxiliary 下配置：
auxiliary:
  compression:
    model: null              # 覆蓋摘要用的模型 (預設: 自動偵測)
    provider: auto           # 提供者: "auto", "openrouter", "nous", "main" 等
    base_url: null           # 自定義 OpenAI 相容端點
```

### 參數詳解

| 參數 | 預設值 | 範圍 | 說明 |
|-----------|---------|-------|-------------|
| `threshold` | `0.50` | 0.0-1.0 | 當提示詞 Token ≥ `threshold × context_length` 時觸發壓縮 |
| `target_ratio` | `0.20` | 0.10-0.80 | 控制尾部保護的 Token 預算：`threshold_tokens × target_ratio` |
| `protect_last_n` | `20` | ≥1 | 始終保留的最少近期訊息數 |
| `protect_first_n` | `3` | (寫死) | 始終保留系統提示詞 + 第一輪對話 |

### 計算值範例 (以 200K 上下文模型搭配預設值為例)

```
context_length       = 200,000
threshold_tokens     = 200,000 × 0.50 = 100,000
tail_token_budget    = 100,000 × 0.20 = 20,000
max_summary_tokens   = min(200,000 × 0.05, 12,000) = 10,000
```


## 壓縮演算法

`ContextCompressor.compress()` 方法遵循 4 階段演算法：

### 階段 1：修剪舊的工具結果 (成本低，無 LLM 呼叫)

受保護尾部之外的舊工具結果（>200 字元）會被替換為：
```
[Old tool output cleared to save context space]
```

這是一個低成本的預處理步驟，能從冗長的工具輸出（檔案內容、終端機輸出、搜尋結果）中節省大量 Token。

### 階段 2：確定邊界

```
┌─────────────────────────────────────────────────────────────┐
│  訊息列表                                                    │
│                                                             │
│  [0..2]  ← protect_first_n (系統提示詞 + 第一輪對話)          │
│  [3..N]  ← 中間輪次 → 被摘要 (SUMMARIZED)                   │
│  [N..end] ← 尾部 (根據 Token 預算或 protect_last_n)          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

尾部保護是**基於 Token 預算**的：從結尾向後遍歷，累積 Token 直到預算耗盡。如果預算保護的訊息數量少於固定的 `protect_last_n`，則降級回使用該計數。

邊界會進行對齊，以避免分割 tool_call/tool_result 組。`_align_boundary_backward()` 方法會跳過連續的工具結果以尋找父級助理訊息，確保組合完整性。

### 階段 3：生成結構化摘要

:::warning 摘要模型上下文長度
摘要模型的上下文視窗**至少必須與**主代理模型的上下文視窗一樣大。整個中間部分會透過一次 `call_llm(task="compression")` 呼叫傳送給摘要模型。如果摘要模型的上下文較小，API 會傳回上下文長度錯誤 — `_generate_summary()` 會捕捉該錯誤、記錄警告並傳回 `None`。接著壓縮器會**直接丟棄**中間輪次且不附帶摘要，從而無聲地遺失對話上下文。這是導致緊實化品質下降的最常見原因。
:::

中間輪次會使用輔助 LLM 搭配結構化範本進行摘要：

```
## 目標
[使用者試圖完成的事項]

## 約束與偏好
[使用者偏好、編碼風格、約束、重要決定]

## 進度
### 已完成
[已完成的工作 — 特定檔案路徑、執行過的指令、結果]
### 進行中
[目前正在進行的工作]
### 已受阻
[遇到的任何阻礙或問題]

## 關鍵決定
[重要的技術決定及其原因]

## 相關檔案
[讀取過、修改過或建立過的檔案 — 附帶簡短說明]

## 後續步驟
[接下來需要發生的事情]

## 關鍵上下文
[特定數值、錯誤訊息、配置細節]
```

摘要預算會隨著被壓縮內容的多寡而調整：
- 公式：`content_tokens × 0.20` (`_SUMMARY_RATIO` 常數)
- 最小值：2,000 Token
- 最大值：`min(context_length × 0.05, 12,000)` Token

### 階段 4：組裝壓縮後的訊息

壓縮後的訊息列表包含：
1. 頭部訊息 (第一次壓縮時會在系統提示詞後附加註解)
2. 摘要訊息 (角色選擇會避免違反連續相同角色的規定)
3. 尾部訊息 (保持不變)

孤立的 tool_call/tool_result 對會由 `_sanitize_tool_pairs()` 清理：
- 引用已移除呼叫的工具結果 → 移除
- 結果已被移除的工具呼叫 → 注入虛擬 (stub) 結果

### 疊代重新壓縮

在後續的壓縮中，先前的摘要會連同指令傳給 LLM，要求其**更新**摘要而非從頭摘要。這能跨多次緊實化保留資訊 — 項目從「進行中」移動到「已完成」，加入新進度，並移除過時資訊。

壓縮器實例上的 `_previous_summary` 欄位會儲存最後一次摘要文字以供此用途使用。


## 壓縮前後範例

### 壓縮前 (45 條訊息，約 95K Token)

```
[0] system:    "You are a helpful assistant..." (系統提示詞)
[1] user:      "Help me set up a FastAPI project"
[2] assistant: <tool_call> terminal: mkdir project </tool_call>
[3] tool:      "directory created"
[4] assistant: <tool_call> write_file: main.py </tool_call>
[5] tool:      "file written (2.3KB)"
    ... 經過 30 多輪檔案編輯、測試、除錯 ...
[38] assistant: <tool_call> terminal: pytest </tool_call>
[39] tool:      "8 passed, 2 failed\n..."  (5KB 輸出)
[40] user:      "Fix the failing tests"
[41] assistant: <tool_call> read_file: tests/test_api.py </tool_call>
[42] tool:      "import pytest\n..."  (3KB)
[43] assistant: "I see the issue with the test fixtures..."
[44] user:      "Great, also add error handling"
```

### 壓縮後 (25 條訊息，約 45K Token)

```
[0] system:    "You are a helpful assistant...
               [Note: Some earlier conversation turns have been compacted...]"
[1] user:      "Help me set up a FastAPI project"
[2] assistant: "[CONTEXT COMPACTION] Earlier turns were compacted...

               ## 目標
               建立一個包含測試與錯誤處理的 FastAPI 專案

               ## 進度
               ### 已完成
               - 建立了專案結構：main.py, tests/, requirements.txt
               - 在 main.py 中實作了 5 個 API 端點
               - 在 tests/test_api.py 中撰寫了 10 個測試案例
               - 8/10 測試通過

               ### 進行中
               - 修復 2 個失敗的測試 (test_create_user, test_delete_user)

               ## 相關檔案
               - main.py — 包含 5 個端點的 FastAPI 應用程式
               - tests/test_api.py — 10 個測試案例
               - requirements.txt — fastapi, pytest, httpx

               ## 後續步驟
               - 修復失敗的測試 Fixture
               - 加入錯誤處理"
[3] user:      "Fix the failing tests"
[4] assistant: <tool_call> read_file: tests/test_api.py </tool_call>
[5] tool:      "import pytest\n..."
[6] assistant: "I see the issue with the test fixtures..."
[7] user:      "Great, also add error handling"
```


## 提示詞快取 (Anthropic)

原始碼：`agent/prompt_caching.py`

透過快取對話前綴，在多輪對話中降低約 75% 的輸入 Token 成本。使用 Anthropic 的 `cache_control` 斷點。

### 策略：system_and_3

Anthropic 每次請求最多允許 4 個 `cache_control` 斷點。Hermes 使用 "system_and_3" 策略：

```
斷點 1：系統提示詞           (在所有輪次中保持穩定)
斷點 2：倒數第 3 條非系統訊息  ─┐
斷點 3：倒數第 2 條非系統訊息   ├─ 滾動視窗
斷點 4：最後一條非系統訊息      ─┘
```

### 運作原理

`apply_anthropic_cache_control()` 會深拷貝訊息並注入 `cache_control` 標記：

```python
# 快取標記格式
marker = {"type": "ephemeral"}
# 或設定 1 小時 TTL：
marker = {"type": "ephemeral", "ttl": "1h"}
```

標記的套用方式依內容類型而異：

| 內容類型 | 標記位置 |
|-------------|-------------------|
| 字串內容 | 轉換為 `[{"type": "text", "text": ..., "cache_control": ...}]` |
| 列表內容 | 加入最後一個元素的字典中 |
| None/空值 | 作為 `msg["cache_control"]` 加入 |
| 工具訊息 | 作為 `msg["cache_control"]` 加入 (僅限原生 Anthropic) |

### 感知快取的設計模式

1. **穩定的系統提示詞**：系統提示詞是第一個斷點，並在所有輪次中快取。避免在對話中途修改它（壓縮僅在第一次緊實化時附加註解）。

2. **訊息順序至關重要**：快取命中要求前綴匹配。在中間新增或移除訊息會使之後的所有快取失效。

3. **壓縮與快取的交互**：壓縮後，壓縮區域的快取會失效，但系統提示詞快取仍會保留。滾動的 3 條訊息視窗會在 1-2 輪內重新建立快取。

4. **TTL 選擇**：預設為 `5m` (5 分鐘)。對於使用者在輪次之間會休息的長期執行對話，請使用 `1h`。

### 啟用提示詞快取

當滿足以下條件時，會自動啟用提示詞快取：
- 模型是 Anthropic Claude 模型（透過模型名稱偵測）
- 提供者支援 `cache_control` (原生 Anthropic API 或 OpenRouter)

```yaml
# config.yaml — TTL 是可配置的
model:
  cache_ttl: "5m"   # "5m" 或 "1h"
```

CLI 在啟動時會顯示快取狀態：
```
💾 Prompt caching: ENABLED (Claude via OpenRouter, 5m TTL)
```


## 上下文壓力警告

代理會在達到壓縮閾值的 85% 時發出上下文壓力警告（不是上下文的 85% — 是閾值的 85%，而閾值本身是上下文的 50%）：

```
⚠️  Context is 85% to compaction threshold (42,500/50,000 tokens)
```

壓縮後，如果使用量降至閾值的 85% 以下，警告狀態將會清除。如果壓縮未能降至警告水平以下（對話內容過於密集），警告會持續存在，但在超過閾值之前不會再次觸發壓縮。
