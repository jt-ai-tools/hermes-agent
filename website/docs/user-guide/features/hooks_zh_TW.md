---
sidebar_position: 6
title: "事件鉤子 (Event Hooks)"
description: "在關鍵生命週期節點執行自定義程式碼 — 記錄活動、發送警報、發送到 Webhook"
---

# 事件鉤子 (Event Hooks)

Hermes 擁有兩套鉤子系統，可在關鍵生命週期節點執行自定義程式碼：

| 系統 | 註冊方式 | 運行環境 | 使用場景 |
|--------|---------------|---------|----------|
| **[網關鉤子](#網關事件鉤子-gateway-event-hooks)** | `~/.hermes/hooks/` 中的 `HOOK.yaml` + `handler.py` | 僅限網關 (Gateway) | 日誌記錄、警報、Webhook |
| **[插件鉤子](#插件鉤子-plugin-hooks)** | [插件](/docs/user-guide/features/plugins) 中的 `ctx.register_hook()` | CLI + 網關 | 工具攔截、指標收集、護欄 (Guardrails) |

這兩套系統皆為非阻塞式 — 任何鉤子中的錯誤都會被捕獲並記錄日誌，絕不會導致代理程式崩潰。

## 網關事件鉤子 (Gateway Event Hooks)

網關鉤子在網關運行期間（Telegram、Discord、Slack、WhatsApp）自動觸發，且不會阻塞主要的代理程式管道。

### 建立鉤子

每個鉤子都是 `~/.hermes/hooks/` 下的一個目錄，包含兩個檔案：

```text
~/.hermes/hooks/
└── my-hook/
    ├── HOOK.yaml      # 宣告要監聽哪些事件
    └── handler.py     # Python 處理函式
```

#### HOOK.yaml

```yaml
name: my-hook
description: 將所有代理程式活動記錄到檔案中
events:
  - agent:start
  - agent:end
  - agent:step
```

`events` 清單決定了哪些事件會觸發您的處理程序。您可以訂閱任何事件組合，包括像 `command:*` 這樣的萬用字元。

#### handler.py

```python
import json
from datetime import datetime
from pathlib import Path

LOG_FILE = Path.home() / ".hermes" / "hooks" / "my-hook" / "activity.log"

async def handle(event_type: str, context: dict):
    """針對每個訂閱的事件調用。函式名稱必須為 'handle'。"""
    entry = {
        "timestamp": datetime.now().isoformat(),
        "event": event_type,
        **context,
    }
    with open(LOG_FILE, "a") as f:
        f.write(json.dumps(entry) + "\n")
```

**處理程序規則：**
- 函式名稱必須為 `handle`
- 接收 `event_type` (字串) 和 `context` (字典)
- 可以是 `async def` 或一般的 `def` — 兩者皆可運行
- 錯誤會被捕獲並記錄日誌，絕不會導致代理程式崩潰

### 可用事件

| 事件 | 觸發時機 | 上下文金鑰 (Context keys) |
|-------|---------------|--------------|
| `gateway:startup` | 網關程序啟動時 | `platforms` (活動中的平台名稱清單) |
| `session:start` | 建立新的訊息會話時 | `platform`, `user_id`, `session_id`, `session_key` |
| `session:end` | 會話結束時（重設前） | `platform`, `user_id`, `session_key` |
| `session:reset` | 使用者執行 `/new` 或 `/reset` 時 | `platform`, `user_id`, `session_key` |
| `agent:start` | 代理程式開始處理訊息時 | `platform`, `user_id`, `session_id`, `message` |
| `agent:step` | 工具調用迴圈的每次迭代 | `platform`, `user_id`, `session_id`, `iteration`, `tool_names` |
| `agent:end` | 代理程式完成處理時 | `platform`, `user_id`, `session_id`, `message`, `response` |
| `command:*` | 執行任何斜線指令時 | `platform`, `user_id`, `command`, `args` |

#### 萬用字元比對

為 `command:*` 註冊的處理程序會針對任何 `command:` 事件（如 `command:model`、`command:reset` 等）觸發。透過單次訂閱即可監控所有斜線指令。

### 範例

#### 啟動清單 (BOOT.md) — 內建

網關附帶一個內建的 `boot-md` 鉤子，在每次啟動時都會尋找 `~/.hermes/BOOT.md`。如果該檔案存在，代理程式會在背景會話中執行其中的指令。無需安裝 — 只要建立該檔案即可。

**建立 `~/.hermes/BOOT.md`：**

```markdown
# 啟動清單

1. 檢查昨晚是否有任何定時任務失敗 — 執行 `hermes cron list`
2. 發送訊息到 Discord #general 頻道說：「網關已重啟，所有系統運作正常」
3. 檢查 /opt/app/deploy.log 是否有過去 24 小時內的錯誤
```

代理程式會在背景執行緒中執行這些指令，因此不會阻塞網關啟動。如果不需要處理任何事項，代理程式會回覆 `[SILENT]`，且不會發送任何訊息。

:::tip
沒有 BOOT.md？鉤子會自動跳過 — 零開銷。當您需要啟動自動化時建立該檔案，不需要時將其刪除即可。
:::

#### 任務耗時過長時發送 Telegram 警報

當代理程式執行超過 10 個步驟時發送訊息給自己：

```yaml
# ~/.hermes/hooks/long-task-alert/HOOK.yaml
name: long-task-alert
description: 當代理程式執行步驟過多時發送警報
events:
  - agent:step
```

```python
# ~/.hermes/hooks/long-task-alert/handler.py
import os
import httpx

THRESHOLD = 10
BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
CHAT_ID = os.getenv("TELEGRAM_HOME_CHANNEL")

async def handle(event_type: str, context: dict):
    iteration = context.get("iteration", 0)
    if iteration == THRESHOLD and BOT_TOKEN and CHAT_ID:
        tools = ", ".join(context.get("tool_names", []))
        text = f"⚠️ 代理程式已執行了 {iteration} 個步驟。最後使用的工具：{tools}"
        async with httpx.AsyncClient() as client:
            await client.post(
                f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage",
                json={"chat_id": CHAT_ID, "text": text},
            )
```

#### 指令使用日誌記錄器

追蹤使用了哪些斜線指令：

```yaml
# ~/.hermes/hooks/command-logger/HOOK.yaml
name: command-logger
description: 記錄斜線指令的使用情況
events:
  - command:*
```

```python
# ~/.hermes/hooks/command-logger/handler.py
import json
from datetime import datetime
from pathlib import Path

LOG = Path.home() / ".hermes" / "logs" / "command_usage.jsonl"

def handle(event_type: str, context: dict):
    LOG.parent.mkdir(parents=True, exist_ok=True)
    entry = {
        "ts": datetime.now().isoformat(),
        "command": context.get("command"),
        "args": context.get("args"),
        "platform": context.get("platform"),
        "user": context.get("user_id"),
    }
    with open(LOG, "a") as f:
        f.write(json.dumps(entry) + "\n")
```

#### 會話開始 Webhook

在新會話開始時向外部服務發送 POST 請求：

```yaml
# ~/.hermes/hooks/session-webhook/HOOK.yaml
name: session-webhook
description: 在新會話開始時通知外部服務
events:
  - session:start
  - session:reset
```

```python
# ~/.hermes/hooks/session-webhook/handler.py
import httpx

WEBHOOK_URL = "https://your-service.example.com/hermes-events"

async def handle(event_type: str, context: dict):
    async with httpx.AsyncClient() as client:
        await client.post(WEBHOOK_URL, json={
            "event": event_type,
            **context,
        }, timeout=5)
```

### 運作原理

1. 在網關啟動時，`HookRegistry.discover_and_load()` 會掃描 `~/.hermes/hooks/`。
2. 每個包含 `HOOK.yaml` + `handler.py` 的子目錄都會被動態載入。
3. 處理程序會為其宣告的事件進行註冊。
4. 在每個生命週期節點，`hooks.emit()` 會觸發所有匹配的處理程序。
5. 任何處理程序中的錯誤都會被捕獲並記錄日誌 — 損壞的鉤子永遠不會導致代理程式崩潰。

:::info
網關鉤子僅在**網關 (Gateway)**（Telegram、Discord、Slack、WhatsApp）中觸發。CLI 不會載入網關鉤子。對於適用於所有環境的鉤子，請使用 [插件鉤子](#插件鉤子-plugin-hooks)。
:::

## 插件鉤子 (Plugin Hooks)

[插件](/docs/user-guide/features/plugins) 可以註冊在 **CLI 和網關**會話中都能觸發的鉤子。這些鉤子是在插件的 `register()` 函式中透過 `ctx.register_hook()` 以程式化方式註冊的。

```python
def register(ctx):
    ctx.register_hook("pre_tool_call", my_tool_observer)
    ctx.register_hook("post_tool_call", my_tool_logger)
    ctx.register_hook("pre_llm_call", my_memory_callback)
    ctx.register_hook("post_llm_call", my_sync_callback)
    ctx.register_hook("on_session_start", my_init_callback)
    ctx.register_hook("on_session_end", my_cleanup_callback)
```

**所有鉤子的一般規則：**

- 回調函式接收 **關鍵字參數 (keyword arguments)**。請務必接受 `**kwargs` 以確保向前相容性 — 未來版本可能會新增參數而不會破壞您的插件。
- 如果回調函式**崩潰**，系統會記錄日誌並跳過該回調。其他鉤子和代理程式將正常繼續。行為不當的插件永遠不會破壞代理程式。
- 所有鉤子都是**觸發後即忘的觀察者 (fire-and-forget observers)**，其回傳值會被忽略 — 只有 `pre_llm_call` 例外，它可以[注入上下文](#pre_llm_call)。

### 快速參考

| 鉤子 | 觸發時機 | 回傳值 |
|------|-----------|---------|
| [`pre_tool_call`](#pre_tool_call) | 在任何工具執行前 | 被忽略 |
| [`post_tool_call`](#post_tool_call) | 在任何工具回傳後 | 被忽略 |
| [`pre_llm_call`](#pre_llm_call) | 每輪一次，在工具調用迴圈前 | 上下文注入 |
| [`post_llm_call`](#post_llm_call) | 每輪一次，在工具調用迴圈後 | 被忽略 |
| [`on_session_start`](#on_session_start) | 建立新會話時（僅限第一輪） | 被忽略 |
| [`on_session_end`](#on_session_end) | 會話結束時 | 被忽略 |

---

### `pre_tool_call`

在**每次**工具執行前立即觸發 — 無論是內建工具還是插件工具。

**回調函式簽章：**

```python
def my_callback(tool_name: str, args: dict, task_id: str, **kwargs):
```

| 參數 | 類型 | 說明 |
|-----------|------|-------------|
| `tool_name` | `str` | 即將執行的工具名稱（例如 `"terminal"`, `"web_search"`, `"read_file"`） |
| `args` | `dict` | 模型傳遞給工具的參數 |
| `task_id` | `str` | 會話/任務識別碼。如果未設置則為空字串。 |

**觸發位置：** 在 `model_tools.py` 的 `handle_function_call()` 內，工具處理程序執行之前。每個工具調用觸發一次 — 如果模型並行調用 3 個工具，這將觸發 3 次。

**回傳值：** 被忽略。

**使用案例：** 日誌記錄、稽核追蹤 (Audit trails)、工具調用計數、攔截危險操作（列印警告）、速率限制。

**範例 — 工具調用稽核日誌：**

```python
import json, logging
from datetime import datetime

logger = logging.getLogger(__name__)

def audit_tool_call(tool_name, args, task_id, **kwargs):
    logger.info("TOOL_CALL session=%s tool=%s args=%s",
                task_id, tool_name, json.dumps(args)[:200])

def register(ctx):
    ctx.register_hook("pre_tool_call", audit_tool_call)
```

**範例 — 針對危險工具發出警告：**

```python
DANGEROUS = {"terminal", "write_file", "patch"}

def warn_dangerous(tool_name, **kwargs):
    if tool_name in DANGEROUS:
        print(f"⚠ 正在執行潛在的危險工具：{tool_name}")

def register(ctx):
    ctx.register_hook("pre_tool_call", warn_dangerous)
```

---

### `post_tool_call`

在**每次**工具執行回傳後立即觸發。

**回調函式簽章：**

```python
def my_callback(tool_name: str, args: dict, result: str, task_id: str, **kwargs):
```

| 參數 | 類型 | 說明 |
|-----------|------|-------------|
| `tool_name` | `str` | 剛執行的工具名稱 |
| `args` | `dict` | 模型傳遞給工具的參數 |
| `result` | `str` | 工具的回傳值（始終為 JSON 字串） |
| `task_id` | `str` | 會話/任務識別碼。如果未設置則為空字串。 |

**觸發位置：** 在 `model_tools.py` 的 `handle_function_call()` 內，工具處理程序回傳之後。每個工具調用觸發一次。如果工具拋出了未處理的異常，此鉤子**不會**觸發（錯誤會被捕獲並作為錯誤 JSON 字串回傳，然後 `post_tool_call` 會以該錯誤字串作為 `result` 觸發）。

**回傳值：** 被忽略。

**使用案例：** 記錄工具結果、指標收集、追蹤工具成功/失敗率、在特定工具完成時發送通知。

**範例 — 追蹤工具使用指標：**

```python
from collections import Counter
import json

_tool_counts = Counter()
_error_counts = Counter()

def track_metrics(tool_name, result, **kwargs):
    _tool_counts[tool_name] += 1
    try:
        parsed = json.loads(result)
        if "error" in parsed:
            _error_counts[tool_name] += 1
    except (json.JSONDecodeError, TypeError):
        pass

def register(ctx):
    ctx.register_hook("post_tool_call", track_metrics)
```

---

### `pre_llm_call`

**每輪觸發一次**，在工具調用迴圈開始之前。這是**唯一一個會使用其回傳值的鉤子** — 它可以向當前輪次的使用者訊息注入上下文。

**回調函式簽章：**

```python
def my_callback(session_id: str, user_message: str, conversation_history: list,
                is_first_turn: bool, model: str, platform: str, **kwargs):
```

| 參數 | 類型 | 說明 |
|-----------|------|-------------|
| `session_id` | `str` | 當前會話的唯一識別碼 |
| `user_message` | `str` | 使用者在這一輪的原始訊息（在任何技能注入之前） |
| `conversation_history` | `list` | 完整訊息清單的副本（OpenAI 格式：`[{"role": "user", "content": "..."}]`） |
| `is_first_turn` | `bool` | 如果這是新會話的第一輪則為 `True`，後續輪次為 `False` |
| `model` | `str` | 模型識別碼（例如 `"anthropic/claude-sonnet-4.6"`） |
| `platform` | `str` | 會話運行的平台：`"cli"`, `"telegram"`, `"discord"` 等。 |

**觸發位置：** 在 `run_agent.py` 的 `run_conversation()` 內，經過上下文壓縮後但在主 `while` 迴圈開始前。每個 `run_conversation()` 調用觸發一次（即每個使用者輪次一次），而不是工具迴圈中的每次 API 調用觸發一次。

**回傳值：** 如果回調函式回傳一個包含 `"context"` 金鑰的字典，或一個非空的純字串，該文字會被附加到當前輪次的使用者訊息中。回傳 `None` 則不進行注入。

```python
# 注入上下文
return {"context": "Recall 的記憶：\n- 使用者喜歡 Python\n- 正在開發 hermes-agent"}

# 純字串（效果相同）
return "Recall 的記憶：\n- 使用者喜歡 Python"

# 不注入
return None
```

**注入位置：** 始終注入到**使用者訊息**中，絕不會注入到系統提示 (system prompt) 中。這樣可以保留提示快取 — 系統提示在不同輪次之間保持一致，因此可以重複使用快取標記。系統提示是 Hermes 的領地（模型引導、工具強制執行、個性、技能）。插件則隨同使用者的輸入提供上下文。

所有注入的上下文都是**暫時性的 (ephemeral)** — 僅在 API 調用時添加。對話歷史記錄中的原始使用者訊息永遠不會被修改，也不會持久化到會話數據庫中。

當**多個插件**回傳上下文時，它們的輸出會按照插件發現順序（目錄名稱的字母順序）以雙換行符連接。

**使用案例：** 記憶回想、RAG 上下文注入、護欄 (Guardrails)、每輪分析。

**範例 — 記憶回想：**

```python
import httpx

MEMORY_API = "https://your-memory-api.example.com"

def recall(session_id, user_message, is_first_turn, **kwargs):
    try:
        resp = httpx.post(f"{MEMORY_API}/recall", json={
            "session_id": session_id,
            "query": user_message,
        }, timeout=3)
        memories = resp.json().get("results", [])
        if not memories:
            return None
        text = "Recalled context:\n" + "\n".join(f"- {m['text']}" for m in memories)
        return {"context": text}
    except Exception:
        return None

def register(ctx):
    ctx.register_hook("pre_llm_call", recall)
```

**範例 — 護欄 (Guardrails)：**

```python
POLICY = "未經使用者明確確認，切勿執行刪除檔案的指令。"

def guardrails(**kwargs):
    return {"context": POLICY}

def register(ctx):
    ctx.register_hook("pre_llm_call", guardrails)
```

---

### `post_llm_call`

**每輪觸發一次**，在工具調用迴圈完成且代理程式產生最終回應後觸發。僅在**成功**的輪次中觸發 — 如果該輪次中斷則不會觸發。

**回調函式簽章：**

```python
def my_callback(session_id: str, user_message: str, assistant_response: str,
                conversation_history: list, model: str, platform: str, **kwargs):
```

| 參數 | 類型 | 說明 |
|-----------|------|-------------|
| `session_id` | `str` | 當前會話的唯一識別碼 |
| `user_message` | `str` | 使用者在這一輪的原始訊息 |
| `assistant_response` | `str` | 代理程式在這一輪的最終文字回應 |
| `conversation_history` | `list` | 該輪次完成後的完整訊息清單副本 |
| `model` | `str` | 模型識別碼 |
| `platform` | `str` | 會話運行的平台 |

**觸發位置：** 在 `run_agent.py` 的 `run_conversation()` 內，工具迴圈以最終回應退出後。受 `if final_response and not interrupted` 保護 — 因此當使用者在輪次中途操作中斷或代理程式達到迭代限制而未產生回應時，它**不會**觸發。

**回傳值：** 被忽略。

**使用案例：** 將對話數據同步到外部記憶系統、計算回應品質指標、記錄輪次摘要、觸發後續動作。

**範例 — 同步到外部記憶：**

```python
import httpx

MEMORY_API = "https://your-memory-api.example.com"

def sync_memory(session_id, user_message, assistant_response, **kwargs):
    try:
        httpx.post(f"{MEMORY_API}/store", json={
            "session_id": session_id,
            "user": user_message,
            "assistant": assistant_response,
        }, timeout=5)
    except Exception:
        pass  # 盡力而為

def register(ctx):
    ctx.register_hook("post_llm_call", sync_memory)
```

**範例 — 追蹤回應長度：**

```python
import logging
logger = logging.getLogger(__name__)

def log_response_length(session_id, assistant_response, model, **kwargs):
    logger.info("RESPONSE session=%s model=%s chars=%d",
                session_id, model, len(assistant_response or ""))

def register(ctx):
    ctx.register_hook("post_llm_call", log_response_length)
```

---

### `on_session_start`

當建立一個全新的會話時**觸發一次**。在會話繼續時（當使用者在現有會話中發送第二條訊息時）**不會**觸發。

**回調函式簽章：**

```python
def my_callback(session_id: str, model: str, platform: str, **kwargs):
```

| 參數 | 類型 | 說明 |
|-----------|------|-------------|
| `session_id` | `str` | 新會話的唯一識別碼 |
| `model` | `str` | 模型識別碼 |
| `platform` | `str` | 會話運行的平台 |

**觸發位置：** 在 `run_agent.py` 的 `run_conversation()` 內，新會話的第一輪期間 — 具體是在構建系統提示後但在工具迴圈開始前。檢查條件是 `if not conversation_history`（沒有先前的訊息 = 新會話）。

**回傳值：** 被忽略。

**使用案例：** 初始化會話作用域狀態、預熱快取、向外部服務註冊會話、記錄會話開始。

**範例 — 初始化會話快取：**

```python
_session_caches = {}

def init_session(session_id, model, platform, **kwargs):
    _session_caches[session_id] = {
        "model": model,
        "platform": platform,
        "tool_calls": 0,
        "started": __import__("datetime").datetime.now().isoformat(),
    }

def register(ctx):
    ctx.register_hook("on_session_start", init_session)
```

---

### `on_session_end`

在每次 `run_conversation()` 調用的**最後**觸發，不論結果如何。如果使用者在代理程式運作中途退出 CLI，也會從 CLI 的退出處理程序中觸發。

**回調函式簽章：**

```python
def my_callback(session_id: str, completed: bool, interrupted: bool,
                model: str, platform: str, **kwargs):
```

| 參數 | 類型 | 說明 |
|-----------|------|-------------|
| `session_id` | `str` | 會話的唯一識別碼 |
| `completed` | `bool` | 如果代理程式產生了最終回應則為 `True`，否則為 `False` |
| `interrupted` | `bool` | 如果該輪次中斷則為 `True`（使用者發送新訊息、執行 `/stop` 或退出） |
| `model` | `str` | 模型識別碼 |
| `platform` | `str` | 會話運行的平台 |

**觸發位置：** 在兩個地方：
1. **`run_agent.py`** — 在每次 `run_conversation()` 調用結束時，完成所有清理工作後。始終觸發，即使輪次出錯。
2. **`cli.py`** — 在 CLI 的 atexit 處理程序中，但**僅當**退出發生時代理程式正在運行中 (`_agent_running=True`)。這會捕獲處理期間的 Ctrl+C 和 `/exit`。在這種情況下，`completed=False` 且 `interrupted=True`。

**回傳值：** 被忽略。

**使用案例：** 刷新緩衝區、關閉連線、持久化會話狀態、記錄會話持續時間、清理在 `on_session_start` 中初始化的資源。

**範例 — 刷新與清理：**

```python
_session_caches = {}

def cleanup_session(session_id, completed, interrupted, **kwargs):
    cache = _session_caches.pop(session_id, None)
    if cache:
        # 將累積的數據刷新到磁碟或外部服務
        status = "completed" if completed else ("interrupted" if interrupted else "failed")
        print(f"Session {session_id} ended: {status}, {cache['tool_calls']} tool calls")

def register(ctx):
    ctx.register_hook("on_session_end", cleanup_session)
```

**範例 — 會話持續時間追蹤：**

```python
import time, logging
logger = logging.getLogger(__name__)

_start_times = {}

def on_start(session_id, **kwargs):
    _start_times[session_id] = time.time()

def on_end(session_id, completed, interrupted, **kwargs):
    start = _start_times.pop(session_id, None)
    if start:
        duration = time.time() - start
        logger.info("SESSION_DURATION session=%s seconds=%.1f completed=%s interrupted=%s",
                     session_id, duration, completed, interrupted)

def register(ctx):
    ctx.register_hook("on_session_start", on_start)
    ctx.register_hook("on_session_end", on_end)
```

---

請參閱 **[開發插件指南](/docs/guides/build-a-hermes-plugin)** 以獲取完整逐步說明，包括工具架構、處理程序和高級鉤子模式。
