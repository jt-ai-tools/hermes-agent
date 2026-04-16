---
sidebar_position: 9
title: "上下文引擎插件"
description: "如何開發一個上下文引擎插件來替換內建的 ContextCompressor"
---

# 開發上下文引擎插件

上下文引擎插件可以替換內建的 `ContextCompressor`，提供管理對話上下文的替代策略。例如，開發一個無損上下文管理 (LCM) 引擎，透過構建知識有向無環圖 (DAG) 來取代有損摘要。

## 運作原理

代理的上下文管理是建立在 `ContextEngine` 抽象基底類別 (ABC) 之上的 (`agent/context_engine.py`)。內建的 `ContextCompressor` 是其預設實作。插件引擎必須實作相同的介面。

同一時間只能啟用**一個**上下文引擎。選擇機制是由配置驅動的：

```yaml
# config.yaml
context:
  engine: "compressor"    # 預設內建
  engine: "lcm"           # 啟用名為 "lcm" 的插件引擎
```

插件引擎**絕不會自動啟用** — 使用者必須顯式將 `context.engine` 設定為插件的名稱。

## 目錄結構

每個上下文引擎都位於 `plugins/context_engine/<名稱>/`：

```
plugins/context_engine/lcm/
├── __init__.py      # 匯出 ContextEngine 子類別
├── plugin.yaml      # 元數據 (名稱、說明、版本)
└── ...              # 引擎所需的任何其他模組
```

## ContextEngine 抽象基底類別 (ABC)

您的引擎必須實作這些**必要**方法：

```python
from agent.context_engine import ContextEngine

class LCMEngine(ContextEngine):

    @property
    def name(self) -> str:
        """簡短標識符，例如 'lcm'。必須與 config.yaml 中的值匹配。"""
        return "lcm"

    def update_from_response(self, usage: dict) -> None:
        """每次 LLM 呼叫後都會呼叫此方法並傳入 usage 字典。

        根據回應更新 self.last_prompt_tokens、self.last_completion_tokens
        與 self.last_total_tokens。
        """

    def should_compress(self, prompt_tokens: int = None) -> bool:
        """如果本輪應觸發緊實化 (compaction)，則回傳 True。"""

    def compress(self, messages: list, current_tokens: int = None) -> list:
        """緊實化訊息列表，並回傳新的（可能更短的）列表。

        回傳的列表必須是符合 OpenAI 格式的有效訊息序列。
        """
```

### 您的引擎必須維護的類別屬性

代理會直接讀取這些屬性以進行顯示與記錄：

```python
last_prompt_tokens: int = 0
last_completion_tokens: int = 0
last_total_tokens: int = 0
threshold_tokens: int = 0        # 觸發壓縮的閾值
context_length: int = 0          # 模型的完整上下文視窗長度
compression_count: int = 0       # compress() 已執行的次數
```

### 選配方法

這些方法在抽象基底類別中已有合理的預設實作，您可以根據需要進行覆寫：

| 方法 | 預設行為 | 覆寫時機 |
|--------|---------|--------------|
| `on_session_start(session_id, **kwargs)` | 無動作 | 您需要載入持久化狀態 (DAG, 資料庫) |
| `on_session_end(session_id, messages)` | 無動作 | 您需要更新狀態、關閉連線 |
| `on_session_reset()` | 重設 Token 計數器 | 您有需要清除的個別對話狀態 |
| `update_model(model, context_length, ...)` | 更新上下文長度與閾值 | 您需要在模型切換時重新計算預算 |
| `get_tool_schemas()` | 回傳 `[]` | 您的引擎提供代理可呼叫的工具 (例如：`lcm_grep`) |
| `handle_tool_call(name, args, **kwargs)` | 回傳錯誤 JSON | 您實作了工具處理程序 |
| `should_compress_preflight(messages)` | 回傳 `False` | 您可以進行低成本的 API 呼叫前預估 |
| `get_status()` | 標準的 Token/閾值字典 | 您有自定義的指標需要展示 |

## 引擎工具

上下文引擎可以公開供代理直接呼叫的工具。請從 `get_tool_schemas()` 回傳 Schema，並在 `handle_tool_call()` 中處理呼叫：

```python
def get_tool_schemas(self):
    return [{
        "name": "lcm_grep",
        "description": "搜尋上下文知識圖譜",
        "parameters": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "搜尋關鍵字"}
            },
            "required": ["query"],
        },
    }]

def handle_tool_call(self, name, args, **kwargs):
    if name == "lcm_grep":
        results = self._search_dag(args["query"])
        return json.dumps({"results": results})
    return json.dumps({"error": f"未知工具：{name}"})
```

引擎工具會在啟動時自動注入到代理的工具列表中並自動調度 — 無需在註冊表中註冊。

## 註冊方式

### 透過目錄（推薦）

將您的引擎放置在 `plugins/context_engine/<名稱>/`。`__init__.py` 必須匯出一個 `ContextEngine` 的子類別。發現系統會自動尋找並實例化它。

### 透過通用插件系統

通用插件也可以註冊上下文引擎：

```python
def register(ctx):
    engine = LCMEngine(context_length=200000)
    ctx.register_context_engine(engine)
```

同一時間僅能註冊一個引擎。如果第二個插件嘗試註冊引擎，將會被拒絕並發出警告。

## 生命週期

```
1. 引擎實例化 (插件載入或目錄發現)
2. on_session_start() — 對話開始
3. update_from_response() — 每次 API 呼叫後
4. should_compress() — 每輪檢查
5. compress() — 當 should_compress() 回傳 True 時呼叫
6. on_session_end() — 對話界限 (CLI 結束, /reset, 閘道器逾期)
```

當執行 `/new` 或 `/reset` 時會呼叫 `on_session_reset()`，以便在不完全關閉的情況下清除個別對話的狀態。

## 配置

使用者可以透過 `hermes plugins` → 提供者插件 → 上下文引擎來選擇您的引擎，或是直接編輯 `config.yaml`：

```yaml
context:
  engine: "lcm"   # 必須匹配您引擎的 name 屬性
```

`compression` 配置區塊（`compression.threshold`、`compression.protect_last_n` 等）是內建 `ContextCompressor` 專用的。如果需要，您的引擎應定義自己的配置格式，並在初始化期間從 `config.yaml` 讀取。

## 測試

```python
from agent.context_engine import ContextEngine

def test_engine_satisfies_abc():
    engine = YourEngine(context_length=200000)
    assert isinstance(engine, ContextEngine)
    assert engine.name == "your-name"

def test_compress_returns_valid_messages():
    engine = YourEngine(context_length=200000)
    msgs = [{"role": "user", "content": "hello"}]
    result = engine.compress(msgs)
    assert isinstance(result, list)
    assert all("role" in m for m in result)
```

請參閱 `tests/agent/test_context_engine.py` 以瞭解完整的 ABC 契約測試套件。

## 另請參閱

- [上下文壓縮與快取](./context-compression-and-caching) — 內建壓縮器的運作方式
- [記憶提供者插件](./memory-provider-plugin) — 記憶系統中類似的單選插件系統
- [插件](/docs/user-guide/features/plugins) — 通用插件系統概覽
