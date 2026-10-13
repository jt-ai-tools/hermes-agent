---
sidebar_position: 8
title: "記憶體提供者外掛"
description: "如何為 Hermes Agent 建立記憶體提供者外掛"
---

# 建立記憶體提供者外掛

記憶體提供者外掛（Memory Provider Plugins）能為 Hermes Agent 提供超越內建 MEMORY.md 與 USER.md 的持久化、跨工作階段知識。本指南將介紹如何建立此類外掛。

:::tip
記憶體提供者是兩種**提供者外掛**類型之一。另一種是[上下文引擎外掛](/docs/developer-guide/context-engine-plugin)，用於替換內建的上下文壓縮器。兩者都遵循相同的模式：單選、設定驅動，並透過 `hermes plugins` 進行管理。
:::

## 目錄結構

每個記憶體提供者都位於 `plugins/memory/<名稱>/`：

```
plugins/memory/my-provider/
├── __init__.py      # MemoryProvider 實作 + register() 入口點
├── plugin.yaml      # 詮釋資料 (名稱, 描述, 掛鉤)
└── README.md        # 安裝說明, 設定參考, 工具說明
```

## MemoryProvider 抽象基礎類別 (ABC)

您的外掛需要實作來自 `agent/memory_provider.py` 的 `MemoryProvider` 抽象基礎類別：

```python
from agent.memory_provider import MemoryProvider

class MyMemoryProvider(MemoryProvider):
    @property
    def name(self) -> str:
        return "my-provider"

    def is_available(self) -> bool:
        """檢查此提供者是否可以啟用。禁止進行網路呼叫。"""
        return bool(os.environ.get("MY_API_KEY"))

    def initialize(self, session_id: str, **kwargs) -> None:
        """在代理人啟動時呼叫一次。

        kwargs 始終包含：
          hermes_home (str): 活動中的 HERMES_HOME 路徑。請用於儲存。
        """
        self._api_key = os.environ.get("MY_API_KEY", "")
        self._session_id = session_id

    # ... 實作其餘方法
```

## 必要方法

### 核心生命週期

| 方法 | 呼叫時機 | 是否必須實作？ |
|--------|-----------|-----------------|
| `name` (屬性) | 始終 | **是** |
| `is_available()` | 代理人初始化時，啟用前 | **是** — 禁止網路呼叫 |
| `initialize(session_id, **kwargs)` | 代理人啟動時 | **是** |
| `get_tool_schemas()` | 初始化後，用於工具注入 | **是** |
| `handle_tool_call(name, args)` | 當代理人使用您的工具時 | **是**（若有工具） |

### 設定

| 方法 | 用途 | 是否必須實作？ |
|--------|---------|-----------------|
| `get_config_schema()` | 為 `hermes memory setup` 宣告設定欄位 | **是** |
| `save_config(values, hermes_home)` | 將非私密設定寫入原生位置 | **是**（除非僅使用環境變數） |

### 選用掛鉤 (Hooks)

| 方法 | 呼叫時機 | 使用案例 |
|--------|-----------|----------|
| `system_prompt_block()` | 系統提示詞組裝時 | 靜態提供者資訊 |
| `prefetch(query)` | 每次 API 呼叫前 | 回傳召回的上下文 |
| `queue_prefetch(query)` | 每輪結束後 | 為下一輪預熱 |
| `sync_turn(user, assistant)` | 每輪完成後 | 持久化對話內容 |
| `on_session_end(messages)` | 對話結束時 | 最終提取/刷新資料 |
| `on_pre_compress(messages)` | 上下文壓縮前 | 在捨棄前儲存洞察 |
| `on_memory_write(action, target, content)` | 內建記憶體寫入時 | 鏡像到您的後端 |
| `shutdown()` | 程序結束時 | 清理連線 |

## 設定結構 (Config Schema)

`get_config_schema()` 回傳一個用於 `hermes memory setup` 的欄位描述符列表：

```python
def get_config_schema(self):
    return [
        {
            "key": "api_key",
            "description": "My Provider API 金鑰",
            "secret": True,           # → 寫入 .env
            "required": True,
            "env_var": "MY_API_KEY",   # 明確的環境變數名稱
            "url": "https://my-provider.com/keys",  # 取得金鑰的網址
        },
        {
            "key": "region",
            "description": "伺服器區域",
            "default": "us-east",
            "choices": ["us-east", "eu-west", "ap-south"],
        },
        {
            "key": "project",
            "description": "專案識別碼",
            "default": "hermes",
        },
    ]
```

標記為 `secret: True` 且有 `env_var` 的欄位會進入 `.env`。非私密欄位則會傳遞給 `save_config()`。

:::tip 精簡型 vs 完整型結構
在執行 `hermes memory setup` 期間，`get_config_schema()` 中的每個欄位都會進行提示。具有多個選項的提供者應保持結構精簡 — 僅包含使用者**必須**設定的欄位（API 金鑰、必要憑證）。將選用的設定項記錄在設定檔參考中（例如 `$HERMES_HOME/myprovider.json`），而不是在安裝期間全部提示。這能讓設定精靈保持快速，同時支援進階設定。請參考 Supermemory 提供者的範例 — 它僅提示 API 金鑰，其餘所有選項都存在於 `supermemory.json` 中。
:::

## 儲存設定

```python
def save_config(self, values: dict, hermes_home: str) -> None:
    """將非私密設定寫入您的原生位置。"""
    import json
    from pathlib import Path
    config_path = Path(hermes_home) / "my-provider.json"
    config_path.write_text(json.dumps(values, indent=2))
```

對於僅使用環境變數的提供者，請保留預設的空操作（No-op）。

## 外掛入口點

```python
def register(ctx) -> None:
    """由記憶體外掛偵測系統呼叫。"""
    ctx.register_memory_provider(MyMemoryProvider())
```

## plugin.yaml

```yaml
name: my-provider
version: 1.0.0
description: "簡短說明此提供者的功能。"
hooks:
  - on_session_end    # 列出您實作的掛鉤
```

## 執行緒規範 (Threading Contract)

**`sync_turn()` 必須是非阻塞（Non-blocking）的。** 如果您的後端有延遲（API 呼叫、LLM 處理），請在守護執行緒（Daemon thread）中執行工作：

```python
def sync_turn(self, user_content, assistant_content):
    def _sync():
        try:
            self._api.ingest(user_content, assistant_content)
        except Exception as e:
            logger.warning("同步失敗：%s", e)

    if self._sync_thread and self._sync_thread.is_alive():
        self._sync_thread.join(timeout=5.0)
    self._sync_thread = threading.Thread(target=_sync, daemon=True)
    self._sync_thread.start()
```

## 設定檔隔離

所有儲存路徑**必須**使用來自 `initialize()` 的 `hermes_home` 參數，而非硬編碼的 `~/.hermes`：

```python
# 正確 — 限定在設定檔範圍內
from hermes_constants import get_hermes_home
data_dir = get_hermes_home() / "my-provider"

# 錯誤 — 在所有設定檔之間共用
data_dir = Path("~/.hermes/my-provider").expanduser()
```

## 測試

請參閱 `tests/agent/test_memory_plugin_e2e.py` 以了解使用真實 SQLite 提供者的完整端對端（E2E）測試模式。

```python
from agent.memory_manager import MemoryManager

mgr = MemoryManager()
mgr.add_provider(my_provider)
mgr.initialize_all(session_id="test-1", platform="cli")

# 測試工具路由
result = mgr.handle_tool_call("my_tool", {"action": "add", "content": "test"})

# 測試生命週期
mgr.sync_all("使用者訊息", "代理人訊息")
mgr.on_session_end([])
mgr.shutdown_all()
```

## 新增 CLI 指令

記憶體提供者外掛可以註冊自己的 CLI 子命令樹（例如：`hermes my-provider status`, `hermes my-provider config`）。這使用基於約定的偵測系統 — 無需修改核心檔案。

### 運作原理

1. 在外掛目錄中新增 `cli.py` 檔案
2. 定義 `register_cli(subparser)` 函數來建構 argparse 樹
3. 記憶體外掛系統在啟動時透過 `discover_plugin_cli_commands()` 偵測它
4. 您的指令將出現在 `hermes <提供者名稱> <子命令>` 之下

**活動提供者限制 (Gating)**：只有當您的提供者是設定中活動的 `memory.provider` 時，您的 CLI 指令才會出現。如果使用者尚未設定您的提供者，您的指令將不會顯示在 `hermes --help` 中。

### 範例

```python
# plugins/memory/my-provider/cli.py

def my_command(args):
    """由 argparse 派發的處理常式。"""
    sub = getattr(args, "my_command", None)
    if sub == "status":
        print("提供者已啟動且已連線。")
    elif sub == "config":
        print("正在顯示設定...")
    else:
        print("用法：hermes my-provider <status|config>")

def register_cli(subparser) -> None:
    """建構 hermes my-provider argparse 樹。

    由 discover_plugin_cli_commands() 在 argparse 設定期間呼叫。
    """
    subs = subparser.add_subparsers(dest="my_command")
    subs.add_parser("status", help="顯示提供者狀態")
    subs.add_parser("config", help="顯示提供者設定")
    subparser.set_defaults(func=my_command)
```

### 參考實作

請參閱 `plugins/memory/honcho/cli.py` 以取得完整範例，其中包含 13 個子命令、跨設定檔管理（`--target-profile`）以及設定的讀寫操作。

### 包含 CLI 的目錄結構

```
plugins/memory/my-provider/
├── __init__.py      # MemoryProvider 實作 + register()
├── plugin.yaml      # 詮釋資料
├── cli.py           # register_cli(subparser) — CLI 指令
└── README.md        # 安裝說明
```

## 單一提供者原則

同一時間只能啟用**一個**外部記憶體提供者。如果使用者嘗試註冊第二個，MemoryManager 將會拒絕並發出警告。這能防止工具結構過於臃腫以及後端衝突。
