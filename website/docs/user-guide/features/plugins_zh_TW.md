---
sidebar_position: 11
sidebar_label: "外掛程式"
title: "外掛程式 (Plugins)"
description: "透過外掛程式系統使用自訂工具、鉤子和整合來擴展 Hermes"
---

# 外掛程式 (Plugins)

Hermes 具備一個外掛程式系統，用於在不修改核心程式碼的情況下添加自訂工具、鉤子和整合。

**→ [開發 Hermes 外掛程式](/docs/guides/build-a-hermes-plugin)** — 包含完整運作範例的逐步指南。

## 快速概覽

將包含 `plugin.yaml` 和 Python 程式碼的目錄放入 `~/.hermes/plugins/`：

```
~/.hermes/plugins/my-plugin/
├── plugin.yaml      # 清單檔案 (manifest)
├── __init__.py      # register() — 將綱要 (schemas) 連接到處理常式 (handlers)
├── schemas.py       # 工具綱要 (LLM 看到的內容)
└── tools.py         # 工具處理常式 (呼叫時執行的內容)
```

啟動 Hermes — 您的工具將與內建工具一起出現。模型可以立即呼叫它們。

### 最小可行範例

這是一個完整的外掛程式，它添加了一個 `hello_world` 工具，並透過鉤子記錄每次工具呼叫。

**`~/.hermes/plugins/hello-world/plugin.yaml`**

```yaml
name: hello-world
version: "1.0"
description: 一個最小的外掛程式範例
```

**`~/.hermes/plugins/hello-world/__init__.py`**

```python
"""最小的 Hermes 外掛程式 — 註冊一個工具和一個鉤子。"""


def register(ctx):
    # --- 工具：hello_world ---
    schema = {
        "name": "hello_world",
        "description": "為指定的名稱返回親切的問候。",
        "parameters": {
            "type": "object",
            "properties": {
                "name": {
                    "type": "string",
                    "description": "要問候的名稱",
                }
            },
            "required": ["name"],
        },
    }

    def handle_hello(params):
        name = params.get("name", "World")
        return f"Hello, {name}! 👋  (來自 hello-world 外掛程式)"

    ctx.register_tool("hello_world", schema, handle_hello)

    # --- 鉤子：記錄每次工具呼叫 ---
    def on_tool_call(tool_name, params, result):
        print(f"[hello-world] 工具已呼叫：{tool_name}")

    ctx.register_hook("post_tool_call", on_tool_call)
```

將這兩個檔案放入 `~/.hermes/plugins/hello-world/`，重新啟動 Hermes，模型即可立即呼叫 `hello_world`。該鉤子會在每次工具呼叫後列印一行日誌。

位於 `./.hermes/plugins/` 下的專案本地外掛程式預設是停用的。請僅針對受信任的儲存庫啟用它們，方法是在啟動 Hermes 之前設置 `HERMES_ENABLE_PROJECT_PLUGINS=true`。

## 外掛程式的功能

| 能力 | 方式 |
|-----------|-----|
| 新增工具 | `ctx.register_tool(name, schema, handler)` |
| 新增鉤子 | `ctx.register_hook("post_tool_call", callback)` |
| 新增 CLI 指令 | `ctx.register_cli_command(name, help, setup_fn, handler_fn)` — 新增 `hermes <plugin> <subcommand>` |
| 注入訊息 | `ctx.inject_message(content, role="user")` — 參見 [注入訊息](#注入訊息) |
| 隨附數據檔案 | `Path(__file__).parent / "data" / "file.yaml"` |
| 綑綁技能 (Skills) | `ctx.register_skill(name, path)` — 命名空間為 `plugin:skill`，透過 `skill_view("plugin:skill")` 載入 |
| 環境變數門檻 | plugin.yaml 中的 `requires_env: [API_KEY]` — 在 `hermes plugins install` 期間提示 |
| 透過 pip 分發 | `[project.entry-points."hermes_agent.plugins"]` |

## 外掛程式發現

| 來源 | 路徑 | 使用案例 |
|--------|------|----------|
| 使用者 | `~/.hermes/plugins/` | 個人外掛程式 |
| 專案 | `.hermes/plugins/` | 專案特定外掛程式 (需設置 `HERMES_ENABLE_PROJECT_PLUGINS=true`) |
| pip | `hermes_agent.plugins` entry_points | 分發的套件 |

## 可用的鉤子 (Hooks)

外掛程式可以為這些生命週期事件註冊回呼 (callbacks)。請參閱 **[事件鉤子頁面](/docs/user-guide/features/hooks#plugin-hooks)** 以獲取完整詳細資訊、回呼簽名和範例。

| 鉤子 (Hook) | 觸發時機 |
|------|-----------|
| [`pre_tool_call`](/docs/user-guide/features/hooks#pre_tool_call) | 任何工具執行之前 |
| [`post_tool_call`](/docs/user-guide/features/hooks#post_tool_call) | 任何工具返回之後 |
| [`pre_llm_call`](/docs/user-guide/features/hooks#pre_llm_call) | 每回合一次，在 LLM 迴圈之前 — 可以返回 `{"context": "..."}` 以[將上下文注入使用者訊息](/docs/user-guide/features/hooks#pre_llm_call) |
| [`post_llm_call`](/docs/user-guide/features/hooks#post_llm_call) | 每回合一次，在 LLM 迴圈之後（僅限成功的輪次） |
| [`on_session_start`](/docs/user-guide/features/hooks#on_session_start) | 創建新工作階段時（僅限第一回合） |
| [`on_session_end`](/docs/user-guide/features/hooks#on_session_end) | 每次 `run_conversation` 呼叫結束時 + CLI 退出處理常式 |

## 外掛程式類型

Hermes 有三種外掛程式：

| 類型 | 功能 | 選擇方式 | 位置 |
|------|-------------|-----------|----------|
| **一般外掛程式** | 新增工具、鉤子、CLI 指令 | 多選（啟用/停用） | `~/.hermes/plugins/` |
| **記憶提供者** | 替換或增強內建記憶 | 單選（一個活動中） | `plugins/memory/` |
| **上下文引擎** | 替換內建的上下文壓縮器 | 單選（一個活動中） | `plugins/context_engine/` |

記憶提供者和上下文引擎是**提供者外掛程式** — 每種類型一次只能有一個處於活動狀態。一般外掛程式可以以任何組合方式啟用。

## 管理外掛程式

```bash
hermes plugins                  # 統一的互動式介面
hermes plugins list             # 表格檢視，顯示啟用/停用狀態
hermes plugins install user/repo  # 從 Git 安裝
hermes plugins update my-plugin   # 拉取最新版本
hermes plugins remove my-plugin   # 卸載
hermes plugins enable my-plugin   # 重新啟用已停用的外掛程式
hermes plugins disable my-plugin  # 停用但不移除
```

### 互動式介面 (Interactive UI)

不帶任何參數執行 `hermes plugins` 會開啟一個綜合互動式畫面：

```
Plugins
  ↑↓ 導覽  SPACE 切換  ENTER 配置/確認  ESC 完成

  一般外掛程式 (General Plugins)
 → [✓] my-tool-plugin — 自訂搜尋工具
   [ ] webhook-notifier — 事件鉤子

  提供者外掛程式 (Provider Plugins)
     記憶提供者 (Memory Provider)      ▸ honcho
     上下文引擎 (Context Engine)       ▸ compressor
```

- **一般外掛程式部分** — 核取方塊，使用 SPACE 切換。
- **提供者外掛程式部分** — 顯示目前選擇。按下 ENTER 進入單選列表來選擇一個活動的提供者。

提供者外掛程式的選擇會儲存到 `config.yaml`：

```yaml
memory:
  provider: "honcho"      # 空字串 = 僅使用內建
```

### 停用一般外掛程式

停用的外掛程式仍保持安裝狀態，但在載入期間會被跳過。停用列表儲存在 `config.yaml` 中的 `plugins.disabled` 下：

```yaml
plugins:
  disabled:
    - my-noisy-plugin
```

在執行中的工作階段中，使用 `/plugins` 可以顯示目前載入的外掛程式。

## 注入訊息

外掛程式可以使用 `ctx.inject_message()` 向活動對話中注入訊息：

```python
ctx.inject_message("來自 webhook 的新數據已送達", role="user")
```

**簽名：** `ctx.inject_message(content: str, role: str = "user") -> bool`

運作方式：

- 如果代理處於**閒置**狀態（等待使用者輸入），訊息將作為下一次輸入進入佇列並開始新回合。
- 如果代理處於**回合中**（正在執行），訊息將中斷目前的運算 — 這與使用者輸入新訊息並按下 Enter 鍵相同。
- 對於非 `"user"` 角色，內容會加上 `[role]` 前綴（例如 `[system] ...`）。
- 如果訊息成功進入佇列，則返回 `True`；如果沒有可用的 CLI 引用（例如在網關模式下），則返回 `False`。

這使得遠端控制檢視器、訊息橋接器或 webhook 接收器等外掛程式能夠將來自外部來源的訊息餵給對話。

:::note
`inject_message` 僅在 CLI 模式下可用。在網關 (gateway) 模式下，由於沒有 CLI 引用，該方法會返回 `False`。
:::

有關處理常式契約、綱要格式、鉤子行為、錯誤處理和常見錯誤，請參閱 **[完整指南](/docs/guides/build-a-hermes-plugin)**。
