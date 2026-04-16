---
sidebar_position: 9
title: "工具執行階段"
description: "工具註冊表、工具集、調度與終端機環境的執行階段行為"
---

# 工具執行階段 (Tools Runtime)

Hermes 工具是分組為工具集 (toolsets) 的自我註冊函式，透過中央註冊/調度系統執行。

主要檔案：

- `tools/registry.py`
- `model_tools.py`
- `toolsets.py`
- `tools/terminal_tool.py`
- `tools/environments/*`

## 工具註冊模型 (Tool registration model)

每個工具模組在匯入時會呼叫 `registry.register(...)`。

`model_tools.py` 負責匯入/發現工具模組，並構建模型使用的綱要 (schema) 列表。

### `registry.register()` 如何運作

`tools/` 中的每個工具檔案都會在模組層級呼叫 `registry.register()` 以宣告自己。函式簽署如下：

```python
registry.register(
    name="terminal",               # 唯一的工具名稱 (用於 API 綱要)
    toolset="terminal",            # 該工具所屬的工具集
    schema={...},                  # OpenAI 函式呼叫綱要 (描述、參數)
    handler=handle_terminal,       # 工具被呼叫時執行的函式
    check_fn=check_terminal,       # 選用：返回 True/False 以表示可用性
    requires_env=["SOME_VAR"],     # 選用：需要的環境變數 (用於 UI 顯示)
    is_async=False,                # 處理常式是否為非同步協程 (async coroutine)
    description="Run commands",    # 人類可讀的描述
    emoji="💻",                    # 用於載入動畫/進度顯示的表情符號
)
```

每次呼叫都會建立一個 `ToolEntry`，並存儲在以工具名稱為鍵的單例 (singleton) `ToolRegistry._tools` 字典中。如果不同工具集之間發生名稱衝突，會記錄警告並由較晚註冊的工具勝出。

### 發現：`discover_builtin_tools()`

當匯入 `model_tools.py` 時，它會呼叫 `tools/registry.py` 中的 `discover_builtin_tools()`。此函式使用 AST 解析掃描每個 `tools/*.py` 檔案，尋找包含頂層 `registry.register()` 呼叫的模組，然後匯入它們：

```python
# tools/registry.py (簡化版)
def discover_builtin_tools(tools_dir=None):
    tools_path = Path(tools_dir) if tools_dir else Path(__file__).parent
    for path in sorted(tools_path.glob("*.py")):
        if path.name in {"__init__.py", "registry.py", "mcp_tool.py"}:
            continue
        if _module_registers_tools(path):  # 對頂層 registry.register() 進行 AST 檢查
            importlib.import_module(f"tools.{path.stem}")
```

這種自動發現意味著新工具檔案會被自動載入，無需手動維護列表。AST 檢查僅匹配頂層的 `registry.register()` 呼叫（不包括函式內部的呼叫），因此 `tools/` 中的輔助模組不會被匯入。

每次匯入都會觸發模組的 `registry.register()` 呼叫。選用工具中的錯誤（例如缺少用於圖像產生的 `fal_client`）會被捕獲並記錄，不會影響其他工具的載入。

在核心工具發現之後，也會發現 MCP 工具和插件 (plugin) 工具：

1. **MCP 工具** — `tools.mcp_tool.discover_mcp_tools()` 讀取 MCP 伺服器配置並註冊來自外部伺服器的工具。
2. **插件工具** — `hermes_cli.plugins.discover_plugins()` 載入可能註冊額外工具的使用者/專案/pip 插件。

## 工具可用性檢查 (`check_fn`)

每個工具都可以選用性地提供一個 `check_fn` — 一個在工具可用時返回 `True` 否則返回 `False` 的可呼叫物件。典型的檢查包括：

- **API 金鑰是否存在** — 例如 Web 搜尋使用 `lambda: bool(os.environ.get("SERP_API_KEY"))`
- **服務是否運行中** — 例如檢查 Honcho 伺服器是否已配置
- **執行檔是否已安裝** — 例如驗證瀏覽器工具所需的 `playwright` 是否可用

當 `registry.get_definitions()` 為模型構建綱要列表時，它會執行每個工具的 `check_fn()`：

```python
# 簡化自 registry.py
if entry.check_fn:
    try:
        available = bool(entry.check_fn())
    except Exception:
        available = False   # 發生異常 = 不可用
    if not available:
        continue            # 完全跳過此工具
```

關鍵行為：
- 檢查結果會**在每次呼叫中進行快取** — 如果多個工具共享同一個 `check_fn`，它只會執行一次。
- `check_fn()` 中的異常被視為「不可用」（故障安全）。
- `is_toolset_available()` 方法檢查工具集的 `check_fn` 是否通過，用於 UI 顯示和工具集解析。

## 工具集解析 (Toolset resolution)

工具集是具名的工具組合。Hermes 透過以下方式解析它們：

- 明確的啟用/停用工具集列表
- 平台預設集 (`hermes-cli`, `hermes-telegram` 等)
- 動態 MCP 工具集
- 策劃的特殊用途集，如 `hermes-acp`

### `get_tool_definitions()` 如何過濾工具

主要進入點是 `model_tools.get_tool_definitions(enabled_toolsets, disabled_toolsets, quiet_mode)`：

1. **如果提供了 `enabled_toolsets`** — 僅包含來自這些工具集的工具。每個工具集名稱都透過 `resolve_toolset()` 進行解析，該函式會將複合工具集展開為單個工具名稱。

2. **如果提供了 `disabled_toolsets`** — 從所有工具集開始，然後減去被停用的工具集。

3. **如果兩者都未提供** — 包含所有已知的工具集。

4. **註冊表過濾** — 解析後的工具名稱集被傳遞給 `registry.get_definitions()`，後者套用 `check_fn` 過濾並返回 OpenAI 格式的綱要。

5. **動態綱要修補** — 過濾後，`execute_code` 和 `browser_navigate` 的綱要會動態調整，以僅引用實際通過過濾的工具（防止模型幻覺呼叫不可用的工具）。

### 舊有的工具集名稱

帶有 `_tools` 後綴的舊工具集名稱（例如 `web_tools`, `terminal_tools`）會透過 `_LEGACY_TOOLSET_MAP` 映射到它們現代的工具名稱，以實現回溯相容。

## 調度 (Dispatch)

在執行階段，工具透過中央註冊表進行調度，但某些代理層級的工具（如記憶/待辦事項/會話搜尋處理）在代理迴圈中會有例外處理。

### 調度流程：模型 tool_call → 處理常式執行

當模型返回 `tool_call` 時，流程如下：

```
模型回應帶有 tool_call
    ↓
run_agent.py 代理迴圈
    ↓
model_tools.handle_function_call(name, args, task_id, user_task)
    ↓
[代理迴圈工具?] → 由代理迴圈直接處理 (todo, memory, session_search, delegate_task)
    ↓
[插件前置鉤子 (Pre-hook)] → 呼叫 invoke_hook("pre_tool_call", ...)
    ↓
registry.dispatch(name, args, **kwargs)
    ↓
根據名稱查找 ToolEntry
    ↓
[非同步處理常式?] → 透過 _run_async() 橋接
[同步處理常式?]   → 直接呼叫
    ↓
返回結果字串 (或 JSON 錯誤)
    ↓
[插件後置鉤子 (Post-hook)] → 呼叫 invoke_hook("post_tool_call", ...)
```

### 錯誤封裝

所有工具執行都封裝在兩個層級的錯誤處理中：

1. **`registry.dispatch()`** — 捕獲處理常式的任何異常，並將 `{"error": "Tool execution failed: ExceptionType: message"}` 作為 JSON 返回。

2. **`handle_function_call()`** — 將整個調度封裝在第二層 try/except 中，返回 `{"error": "Error executing tool_name: message"}`。

這確保了模型始終收到格式正確的 JSON 字串，而不會收到未處理的異常。

### 代理迴圈工具 (Agent-loop tools)

有四個工具在註冊表調度之前被攔截，因為它們需要代理層級的狀態（TodoStore, MemoryStore 等）：

- `todo` — 規劃/任務追蹤
- `memory` — 持久化記憶寫入
- `session_search` — 跨會話召回
- `delegate_task` — 產生子代理會話

這些工具的綱要仍會在註冊表中註冊（用於 `get_tool_definitions`），但如果調度以某種方式直接到達它們，它們的處理常式會返回一個存根 (stub) 錯誤。

### 非同步橋接

當工具處理常式是非同步時，`_run_async()` 會將其橋接到同步調度路徑：

- **CLI 路徑 (無運行中迴圈)** — 使用持久的事件迴圈來保持快取的非同步客戶端處於活動狀態
- **閘道器路徑 (有運行中迴圈)** — 使用 `asyncio.run()` 啟動一個臨時執行緒
- **工作執行緒 (併發工具)** — 使用存儲在執行緒局部存儲 (thread-local storage) 中的各執行緒持久迴圈

## 危險模式 (DANGEROUS_PATTERNS) 核准流程

終端機工具整合了 `tools/approval.py` 中定義的危險指令核准系統：

1. **模式檢測** — `DANGEROUS_PATTERNS` 是一個 `(regex, description)` 元組列表，涵蓋了破壞性操作：
   - 遞迴刪除 (`rm -rf`)
   - 檔案系統格式化 (`mkfs`, `dd`)
   - SQL 破壞性操作 (`DROP TABLE`, `DELETE FROM` 且無 `WHERE`)
   - 系統配置覆蓋 (`> /etc/`)
   - 服務操作 (`systemctl stop`)
   - 遠端程式碼執行 (`curl | sh`)
   - Fork 炸彈、進程結束等

2. **檢測** — 在執行任何終端機指令之前，`detect_dangerous_command(command)` 會針對所有模式進行檢查。

3. **核准提示** — 如果發現匹配項：
   - **CLI 模式** — 互動式提示要求使用者核准、拒絕或永久允許
   - **閘道器模式** — 非同步核准回呼會將請求發送到通訊平台
   - **智慧核准** — 選用性地，輔助 LLM 可以自動核准符合模式但低風險的指令（例如 `rm -rf node_modules/` 是安全的，但符合「遞迴刪除」）

4. **會話狀態** — 核准是按會話追蹤的。一旦您為某個會話核准了「遞迴刪除」，隨後的 `rm -rf` 指令就不會再次提示。

5. **永久允許清單** — 「永久允許」選項會將模式寫入 `config.yaml` 的 `command_allowlist` 中，跨會話持久存在。

## 終端機/執行階段環境

終端機系統支援多個後端 (backends)：

- local (本地)
- docker
- ssh
- singularity
- modal
- daytona

它還支援：

- 各任務的當前工作目錄 (cwd) 覆蓋
- 背景進程管理
- PTY 模式
- 危險指令的核准回呼

## 併發 (Concurrency)

工具呼叫可以按順序或併發執行，具體取決於工具組合和互動需求。

## 相關文件

- [工具集參考 (Toolsets Reference)](../reference/toolsets-reference.md)
- [內建工具參考 (Built-in Tools Reference)](../reference/tools-reference.md)
- [代理迴圈內部機制 (Agent Loop Internals)](./agent-loop.md)
- [ACP 內部機制 (ACP Internals)](./acp-internals.md)
