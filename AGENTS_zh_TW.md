# Hermes Agent - 開發指南

提供給正在處理 hermes-agent 程式碼庫的 AI 程式碼助手與開發者的指令。

## 開發環境

```bash
source venv/bin/activate  # 執行 Python 之前務必先啟動虛擬環境
```

## 專案結構

```
hermes-agent/
├── run_agent.py          # AIAgent 類別 —— 核心對話迴圈
├── model_tools.py        # 工具編排，discover_builtin_tools(), handle_function_call()
├── toolsets.py           # 工具集定義，_HERMES_CORE_TOOLS 列表
├── cli.py                # HermesCLI 類別 —— 互動式 CLI 編排器
├── hermes_state.py       # SessionDB —— SQLite 會話儲存 (FTS5 搜尋)
├── agent/                # 代理程式內部機制
│   ├── prompt_builder.py     # 系統提示詞組合
│   ├── context_compressor.py # 自動上下文壓縮
│   ├── prompt_caching.py     # Anthropic 提示詞快取
│   ├── auxiliary_client.py   # 輔助 LLM 用戶端 (視覺、摘要)
│   ├── model_metadata.py     # 模型上下文長度、Token 估計
│   ├── models_dev.py         # models.dev 註冊表整合 (感知供應商的上下文)
│   ├── display.py            # KawaiiSpinner，工具預覽格式化
│   ├── skill_commands.py     # 技能斜線指令 (CLI/網關共用)
│   └── trajectory.py         # 軌跡儲存輔助程式
├── hermes_cli/           # CLI 子指令與設定
│   ├── main.py           # 入口點 —— 所有 `hermes` 子指令
│   ├── config.py         # DEFAULT_CONFIG, OPTIONAL_ENV_VARS, 遷移
│   ├── commands.py       # 斜線指令定義 + SlashCommandCompleter
│   ├── callbacks.py      # 終端回呼 (澄清、sudo、核准)
│   ├── setup.py          # 互動式安裝精靈
│   ├── skin_engine.py    # 皮膚/主題引擎 —— CLI 視覺自訂
│   ├── skills_config.py  # `hermes skills` —— 依平台啟用/禁用技能
│   ├── tools_config.py   # `hermes tools` —— 依平台啟用/禁用工具
│   ├── skills_hub.py     # `/skills` 斜線指令 (搜尋、瀏覽、安裝)
│   ├── models.py         # 模型目錄、供應商模型列表
│   ├── model_switch.py   # 共用的 /model 切換流程 (CLI + 網關)
│   └── auth.py           # 供應商憑證解析
├── tools/                # 工具實作 (每個工具一個檔案)
│   ├── registry.py       # 中央工具註冊表 (Schema, 處理程序, 分發)
│   ├── approval.py       # 危險指令偵測
│   ├── terminal_tool.py  # 終端編排
│   ├── process_registry.py # 背景進程管理
│   ├── file_tools.py     # 檔案讀取/寫入/搜尋/修補
│   ├── web_tools.py      # 網頁搜尋/擷取 (並行 + Firecrawl)
│   ├── browser_tool.py   # Browserbase 瀏覽器自動化
│   ├── code_execution_tool.py # execute_code 沙盒
│   ├── delegate_tool.py  # 子代理委派
│   ├── mcp_tool.py       # MCP 用戶端 (~1050 行)
│   └── environments/     # 終端後端 (本地、Docker、SSH、Modal、Daytona、Singularity)
├── gateway/              # 通訊平台網關
│   ├── run.py            # 主迴圈、斜線指令、訊息分發
│   ├── session.py        # SessionStore —— 對話持久化
│   └── platforms/        # 適配器：Telegram, Discord, Slack, WhatsApp, HomeAssistant, Signal, QQBot
├── acp_adapter/          # ACP 伺服器 (VS Code / Zed / JetBrains 整合)
├── cron/                 # 排程器 (jobs.py, scheduler.py)
├── environments/         # RL 訓練環境 (Atropos)
├── tests/                # Pytest 測試套件 (~3000 個測試)
└── batch_runner.py       # 並行批次處理
```

**使用者配置：** `~/.hermes/config.yaml` (設定), `~/.hermes/.env` (API 金鑰)

## 檔案依賴鏈

```
tools/registry.py  (無依賴 —— 被所有工具檔案匯入)
       ↑
tools/*.py  (匯入時各自呼叫 registry.register())
       ↑
model_tools.py  (匯入 tools/registry + 觸發工具偵測)
       ↑
run_agent.py, cli.py, batch_runner.py, environments/
```

---

## AIAgent 類別 (run_agent.py)

```python
class AIAgent:
    def __init__(self,
        model: str = "anthropic/claude-opus-4.6",
        max_iterations: int = 90,
        enabled_toolsets: list = None,
        disabled_toolsets: list = None,
        quiet_mode: bool = False,
        save_trajectories: bool = False,
        platform: str = None,           # "cli", "telegram", 等。
        session_id: str = None,
        skip_context_files: bool = False,
        skip_memory: bool = False,
        # ... 以及供應商、API 模式、回呼、路由參數
    ): ...

    def chat(self, message: str) -> str:
        """簡單介面 —— 回傳最終回應字串。"""

    def run_conversation(self, user_message: str, system_message: str = None,
                         conversation_history: list = None, task_id: str = None) -> dict:
        """完整介面 —— 回傳包含 final_response + messages 的字典。"""
```

### 代理迴圈

核心迴圈位於 `run_conversation()` 內 —— 完全同步：

```python
while api_call_count < self.max_iterations and self.iteration_budget.remaining > 0:
    response = client.chat.completions.create(model=model, messages=messages, tools=tool_schemas)
    if response.tool_calls:
        for tool_call in response.tool_calls:
            result = handle_function_call(tool_call.name, tool_call.args, task_id)
            messages.append(tool_result_message(result))
        api_call_count += 1
    else:
        return response.content
```

訊息遵循 OpenAI 格式：`{"role": "system/user/assistant/tool", ...}`。推理內容儲存在 `assistant_msg["reasoning"]` 中。

---

## CLI 架構 (cli.py)

- 使用 **Rich** 處理橫幅/面板，使用 **prompt_toolkit** 處理具備自動補全功能的輸入
- **KawaiiSpinner** (`agent/display.py`) —— API 呼叫時的動畫表情，工具結果的 `┊` 活動饋送
- cli.py 中的 `load_cli_config()` 會合併硬編碼的預設值與使用者配置 YAML
- **皮膚引擎** (`hermes_cli/skin_engine.py`) —— 資料驅動的 CLI 視覺自訂；啟動時從 `display.skin` 配置鍵初始化；皮膚可自訂橫幅顏色、加載圖示臉部/動詞/翅膀、工具前綴、回應框、品牌文字
- `process_command()` 是 `HermesCLI` 的一個方法 —— 透過中央註冊表的 `resolve_command()` 解析規範指令名稱並進行分發
- 技能斜線指令：`agent/skill_commands.py` 掃描 `~/.hermes/skills/`，作為**使用者訊息** (而非系統提示詞) 注入，以保留提示詞快取

### 斜線指令註冊表 (`hermes_cli/commands.py`)

所有斜線指令都定義在一個中央的 `COMMAND_REGISTRY` 列表中的 `CommandDef` 物件。所有下游取用者會自動從此註冊表派生：

- **CLI** —— `process_command()` 透過 `resolve_command()` 解析別名，依規範名稱分發
- **網關** —— 用於鉤子發射的 `GATEWAY_KNOWN_COMMANDS` 凍結集合，以及用於分發的 `resolve_command()`
- **網關說明** —— `gateway_help_lines()` 生成 `/help` 輸出
- **Telegram** —— `telegram_bot_commands()` 生成機器人指令選單
- **Slack** —— `slack_subcommand_map()` 生成 `/hermes` 子指令路由
- **自動補全** —— `COMMANDS` 扁平字典供 `SlashCommandCompleter` 使用
- **CLI 說明** —— `COMMANDS_BY_CATEGORY` 字典供 `show_help()` 使用

### 新增斜線指令

1. 在 `hermes_cli/commands.py` 的 `COMMAND_REGISTRY` 中新增一個 `CommandDef` 條目：
```python
CommandDef("mycommand", "功能描述", "Session",
           aliases=("mc",), args_hint="[參數]"),
```
2. 在 `cli.py` 的 `HermesCLI.process_command()` 中新增處理程序：
```python
elif canonical == "mycommand":
    self._handle_mycommand(cmd_original)
```
3. 若該指令在網關中可用，在 `gateway/run.py` 中新增處理程序：
```python
if canonical == "mycommand":
    return await self._handle_mycommand(event)
```
4. 對於持久化設定，使用 `cli.py` 中的 `save_config_value()`

**CommandDef 欄位：**
- `name` —— 不含斜線的規範名稱 (例如 `"background"`)
- `description` —— 人類可讀的描述
- `category` —— 類別之一：`"Session"`, `"Configuration"`, `"Tools & Skills"`, `"Info"`, `"Exit"`
- `aliases` —— 別名元組 (例如 `("bg",)`)
- `args_hint` —— 說明中顯示的參數提示 (例如 `"<prompt>"`, `"[name]"`)
- `cli_only` —— 僅在互動式 CLI 中可用
- `gateway_only` —— 僅在通訊平台中可用
- `gateway_config_gate` —— 配置路徑 (例如 `"display.tool_progress_command"`)；若設定在 `cli_only` 指令上，當配置值為真值時，該指令在網關中變為可用。`GATEWAY_KNOWN_COMMANDS` 始終包含受控指令以便網關分發；說明/選單僅在閘門開啟時顯示。

**新增別名** 僅需在現有的 `CommandDef` 的 `aliases` 元組中新增。無需修改其他檔案 —— 分發、說明文字、Telegram 選單、Slack 映射與自動補全都會自動更新。

---

## 新增工具

需要修改 **2 個檔案**：

**1. 建立 `tools/your_tool.py`：**
```python
import json, os
from tools.registry import registry

def check_requirements() -> bool:
    return bool(os.getenv("EXAMPLE_API_KEY"))

def example_tool(param: str, task_id: str = None) -> str:
    return json.dumps({"success": True, "data": "..."})

registry.register(
    name="example_tool",
    toolset="example",
    schema={"name": "example_tool", "description": "...", "parameters": {...}},
    handler=lambda args, **kw: example_tool(param=args.get("param", ""), task_id=kw.get("task_id")),
    check_fn=check_requirements,
    requires_env=["EXAMPLE_API_KEY"],
)
```

**2. 新增至 `toolsets.py`** —— 加入 `_HERMES_CORE_TOOLS` (所有平台) 或新的工具集。

自動偵測：任何包含頂層 `registry.register()` 呼叫的 `tools/*.py` 檔案都會自動匯入 —— 無需手動維護匯入列表。

註冊表負責處理 Schema 收集、分發、可用性檢查與錯誤封裝。所有處理程序務必回傳 JSON 字串。

**工具 Schema 中的路徑參考**：若 Schema 描述提到檔案路徑 (例如預設輸出目錄)，請使用 `display_hermes_home()` 以感知個人檔案路徑。Schema 是在匯入時生成的，這是在 `_apply_profile_override()` 設定 `HERMES_HOME` 之後。

**狀態檔案**：若工具需要儲存持久狀態 (快取、日誌、檢查點)，請使用 `get_hermes_home()` 作為基準目錄 —— 絕不要使用 `Path.home() / ".hermes"`。這確保了每個個人檔案都有獨立的狀態。

**代理等級工具** (todo, memory)：在 `handle_function_call()` 之前會被 `run_agent.py` 攔截。模式請參考 `todo_tool.py`。

---

## 新增配置

### config.yaml 選項：
1. 新增至 `hermes_cli/config.py` 中的 `DEFAULT_CONFIG`
2. 增加 `_config_version` (目前為 5) 以觸發現有使用者的遷移

### .env 變數：
1. 新增至 `hermes_cli/config.py` 中的 `OPTIONAL_ENV_VARS` 並附帶元資料：
```python
"NEW_API_KEY": {
    "description": "用途說明",
    "prompt": "顯示名稱",
    "url": "https://...",
    "password": True,
    "category": "tool",  # provider, tool, messaging, setting
},
```

### 配置加載器 (兩個獨立系統)：

| 加載器 | 用途 | 位置 |
|--------|---------|----------|
| `load_cli_config()` | CLI 模式 | `cli.py` |
| `load_config()` | `hermes tools`, `hermes setup` | `hermes_cli/config.py` |
| 直接 YAML 加載 | 網關 | `gateway/run.py` |

---

## 皮膚/主題系統

皮膚引擎 (`hermes_cli/skin_engine.py`) 提供資料驅動的 CLI 視覺自訂。皮膚是**純資料** —— 無需修改程式碼即可新增皮膚。

### 架構

```
hermes_cli/skin_engine.py    # SkinConfig 資料類別，內建皮膚，YAML 加載器
~/.hermes/skins/*.yaml       # 使用者安裝的自訂皮膚 (隨插即用)
```

- `init_skin_from_config()` —— CLI 啟動時呼叫，從配置讀取 `display.skin`
- `get_active_skin()` —— 回傳目前皮膚快取的 `SkinConfig`
- `set_active_skin(name)` —— 運行時切換皮膚 (用於 `/skin` 指令)
- `load_skin(name)` —— 先從使用者皮膚加載，再從內建皮膚加載，最後回退到預設
- 缺失的皮膚值會自動從 `default` 皮膚繼承

### 皮膚自訂內容

| 元素 | 皮膚鍵名 | 使用位置 |
|---------|----------|---------|
| 橫幅面板邊框 | `colors.banner_border` | `banner.py` |
| 橫幅面板標題 | `colors.banner_title` | `banner.py` |
| 橫幅章節標題 | `colors.banner_accent` | `banner.py` |
| 橫幅暗色文字 | `colors.banner_dim` | `banner.py` |
| 橫幅主體文字 | `colors.banner_text` | `banner.py` |
| 回應框邊框 | `colors.response_border` | `cli.py` |
| 加載圖示臉部 (等待中) | `spinner.waiting_faces` | `display.py` |
| 加載圖示臉部 (思考中) | `spinner.thinking_faces` | `display.py` |
| 加載圖示動詞 | `spinner.thinking_verbs` | `display.py` |
| 加載圖示翅膀 (選用) | `spinner.wings` | `display.py` |
| 工具輸出前綴 | `tool_prefix` | `display.py` |
| 各別工具 Emoji | `tool_emojis` | `display.py` → `get_tool_emoji()` |
| 代理名稱 | `branding.agent_name` | `banner.py`, `cli.py` |
| 歡迎訊息 | `branding.welcome` | `cli.py` |
| 回應框標籤 | `branding.response_label` | `cli.py` |
| 提示符號 | `branding.prompt_symbol` | `cli.py` |

### 內建皮膚

- `default` —— 經典 Hermes 金色/可愛風格 (目前的樣貌)
- `ares` —— 緋紅/青銅戰神主題，具備自訂加載圖示翅膀
- `mono` —— 乾淨的灰階單色
- `slate` —— 酷藍色開發者導向主題

### 新增內建皮膚

新增至 `hermes_cli/skin_engine.py` 中的 `_BUILTIN_SKINS` 字典：

```python
"mytheme": {
    "name": "mytheme",
    "description": "簡短描述",
    "colors": { ... },
    "spinner": { ... },
    "branding": { ... },
    "tool_prefix": "┊",
},
```

### 使用者皮膚 (YAML)

使用者建立 `~/.hermes/skins/<名稱>.yaml`：

```yaml
name: cyberpunk
description: 霓虹終端主題

colors:
  banner_border: "#FF00FF"
  banner_title: "#00FFFF"
  banner_accent: "#FF1493"

spinner:
  thinking_verbs: ["接入中", "解密中", "上傳中"]
  wings:
    - ["⟨⚡", "⚡⟩"]

branding:
  agent_name: "賽博代理"
  response_label: " ⚡ 賽博 "

tool_prefix: "▏"
```

使用 `/skin cyberpunk` 啟動，或在 config.yaml 中設定 `display.skin: cyberpunk`。

---

## 重要政策
### 提示詞快取不可中斷

Hermes-Agent 確保快取在整個對話中保持有效。**請勿實施會導致以下情況的變更：**
- 在對話途中更改過去的上下文
- 在對話途中更改工具集
- 在對話途中重新加載記憶或重新建構系統提示詞

快取中斷會導致成本大幅增加。唯一可以變更上下文的時機是在上下文壓縮期間。

### 工作目錄行為
- **CLI**：使用當前目錄 (`.` → `os.getcwd()`)
- **通訊平台**：使用 `MESSAGING_CWD` 環境變數 (預設：家目錄)

### 背景進程通知 (網關)

當使用 `terminal(background=true, notify_on_complete=true)` 時，網關會運行一個監視器，
偵測進程完成並觸發新的代理回合。透過 config.yaml 中的 `display.background_process_notifications`
(或 `HERMES_BACKGROUND_NOTIFICATIONS` 環境變數) 控制背景進程訊息的詳細程度：

- `all` —— 運行輸出更新 + 最終訊息 (預設)
- `result` —— 僅顯示最終完成訊息
- `error` —— 僅在結束代碼 != 0 時顯示最終訊息
- `off` —— 不顯示監視器訊息

---

## 個人檔案 (Profiles)：多實例支援

Hermes 支援 **個人檔案 (profiles)** —— 多個完全隔離的實例，每個實例都有自己的
`HERMES_HOME` 目錄 (包含配置、API 金鑰、記憶、會話、技能、網關等)。

核心機制：`hermes_cli/main.py` 中的 `_apply_profile_override()` 會在匯入任何模組前
設定 `HERMES_HOME`。程式碼中所有 119 處以上對 `get_hermes_home()` 的引用
都會自動對準目前的個人檔案。

### 個人檔案安全程式碼規則

1. **對所有 HERMES_HOME 路徑使用 `get_hermes_home()`。** 從 `hermes_constants` 匯入。
   絕不要在讀寫狀態的程式碼中硬編碼 `~/.hermes` 或 `Path.home() / ".hermes"`。
   ```python
   # 正確
   from hermes_constants import get_hermes_home
   config_path = get_hermes_home() / "config.yaml"

   # 錯誤 —— 會破壞個人檔案功能
   config_path = Path.home() / ".hermes" / "config.yaml"
   ```

2. **對面向使用者的訊息使用 `display_hermes_home()`。** 從 `hermes_constants` 匯入。
   這對預設檔案會回傳 `~/.hermes`，對個人檔案則回傳 `~/.hermes/profiles/<名稱>`。
   ```python
   # 正確
   from hermes_constants import display_hermes_home
   print(f"配置已儲存至 {display_hermes_home()}/config.yaml")

   # 錯誤 —— 對個人檔案會顯示錯誤路徑
   print("配置已儲存至 ~/.hermes/config.yaml")
   ```

3. **模組級常數是可以的** —— 它們在匯入時快取 `get_hermes_home()`，
   這是在 `_apply_profile_override()` 設定環境變數之後。只需使用 `get_hermes_home()`，
   而非 `Path.home() / ".hermes"`。

4. **模擬 `Path.home()` 的測試也必須設定 `HERMES_HOME`** —— 因為程式碼現在使用
   `get_hermes_home()` (讀取環境變數)，而非 `Path.home() / ".hermes"`：
   ```python
   with patch.object(Path, "home", return_value=tmp_path), \
        patch.dict(os.environ, {"HERMES_HOME": str(tmp_path / ".hermes")}):
       ...
   ```

5. **網關平台適配器應使用權杖鎖 (token locks)** —— 若適配器使用唯一的憑證 (機器人權杖、API 金鑰) 連接，
   請在 `connect()`/`start()` 方法中呼叫來自 `gateway.status` 的 `acquire_scoped_lock()`，
   並在 `disconnect()`/`stop()` 中呼叫 `release_scoped_lock()`。這能防止兩個個人檔案使用相同的憑證。
   規範模式請參考 `gateway/platforms/telegram.py`。

6. **個人檔案操作以 HOME 為基準，而非以 HERMES_HOME 為基準** —— `_get_profiles_root()`
   回傳 `Path.home() / ".hermes" / "profiles"`，而非 `get_hermes_home() / "profiles"`。
   這是特意設計的 —— 這讓 `hermes -p coder profile list` 無論目前哪個個人檔案處於活動狀態，都能看到所有個人檔案。

## 已知陷阱

### 請勿硬編碼 `~/.hermes` 路徑
程式碼路徑請使用 `hermes_constants` 中的 `get_hermes_home()`。面向使用者的列印/日誌訊息
請使用 `display_hermes_home()`。硬編碼 `~/.hermes` 會破壞個人檔案功能 —— 每個個人檔案
都有獨立的 `HERMES_HOME` 目錄。這是 PR #3575 修復的 5 個 Bug 的根源。

### 請勿將 `simple_term_menu` 用於互動式選單
在 tmux/iTerm2 中有渲染 Bug —— 捲動時會出現殘影。請改用 `curses` (標準庫)。模式請參考 `hermes_cli/tools_config.py`。

### 請勿在加載圖示/顯示程式碼中使用 `\033[K` (ANSI 清除至行尾)
在 `prompt_toolkit` 的 `patch_stdout` 下會洩漏為字面值 `?[K` 文字。請使用空格填充：`f"\r{line}{' ' * pad}"`。

### `model_tools.py` 中的 `_last_resolved_tool_names` 是進程全域變數
`delegate_tool.py` 中的 `_run_single_child()` 會在子代理執行前後儲存並還原此全域變數。若你新增讀取此全域變數的程式碼，請注意它在子代理執行期間可能會暫時過時。

### 請勿在 Schema 描述中硬編碼跨工具引用
工具 Schema 描述絕不可直稱其他工具集的工具名稱 (例如 `browser_navigate` 說 "優先使用 web_search")。那些工具可能不可用 (缺少 API 金鑰、工具集已停用)，導致模型幻覺調用不存在的工具。若需要跨工具引用，請在 `model_tools.py` 的 `get_tool_definitions()` 中動態新增 —— 模式請參考 `browser_navigate` / `execute_code` 的後處理區塊。

### 測試絕不可寫入 `~/.hermes/`
`tests/conftest.py` 中的 `_isolate_hermes_home` 自動測試設施會將 `HERMES_HOME` 導向暫存目錄。測試中絕不可硬編碼 `~/.hermes/` 路徑。

**個人檔案測試**：測試個人檔案功能時，同時也要模擬 `Path.home()`，使得
`_get_profiles_root()` 與 `_get_default_hermes_home()` 在暫存目錄中解析。
請使用 `tests/hermes_cli/test_profiles.py` 中的模式：
```python
@pytest.fixture
def profile_env(tmp_path, monkeypatch):
    home = tmp_path / ".hermes"
    home.mkdir()
    monkeypatch.setattr(Path, "home", lambda: tmp_path)
    monkeypatch.setenv("HERMES_HOME", str(home))
    return home
```

---

## 測試

```bash
source venv/bin/activate
python -m pytest tests/ -q          # 完整套件 (~3000 個測試，約 3 分鐘)
python -m pytest tests/test_model_tools.py -q   # 工具集解析
python -m pytest tests/test_cli_init.py -q       # CLI 配置加載
python -m pytest tests/gateway/ -q               # 網關測試
python -m pytest tests/tools/ -q                 # 工具級測試
```

推送變更前務必執行完整測試套件。
