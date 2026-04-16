# 貢獻指南 - Hermes Agent

感謝你對 Hermes Agent 的貢獻！本指南涵蓋了你所需的一切：開發環境設定、架構理解、功能開發決策，以及如何讓你的 PR 被合併。

---

## 貢獻優先級

我們按以下順序評估貢獻的重要性：

1. **Bug 修復** —— 程式當機、不正確的行為、資料遺失。始終是最高優先級。
2. **跨平台相容性** —— Windows, macOS, 不同的 Linux 發行版, 不同的終端模擬器。我們希望 Hermes 能在任何地方運行。
3. **安全性強化** —— Shell 注入、提示詞注入 (Prompt Injection)、路徑遍歷、權限提升。參見[安全考量](#安全考量)。
4. **效能與穩健性** —— 重試邏輯、錯誤處理、優雅降級。
5. **新技能 (Skills)** —— 但僅限於具備廣泛用途的。參見[應該開發技能 (Skill) 還是工具 (Tool)？](#應該開發技能-skill-還是工具-tool)
6. **新工具 (Tools)** —— 極少需要。大多數功能應以技能形式實現。見下文。
7. **文件** —— 修復、說明澄清、新範例。

---

## 應該開發技能 (Skill) 還是工具 (Tool)？

這是新貢獻者最常問的問題。答案幾乎總是 **技能 (Skill)**。

### 在以下情況請建立技能 (Skill)：

- 該能力可以透過指令 + Shell 指令 + 現有工具來表達
- 它封裝了代理程式可以透過 `terminal` 或 `web_extract` 呼叫的外部 CLI 或 API
- 它不需要在代理程式核心中內建自訂的 Python 整合或 API 金鑰管理
- 範例：arXiv 搜尋、git 工作流、Docker 管理、PDF 處理、透過 CLI 工具發送電子郵件

### 在以下情況請建立工具 (Tool)：

- 它需要與 API 金鑰、認證流程或由代理程式框架管理的多元組件配置進行端到端整合
- 它需要每次都精確執行的自訂處理邏輯 (而非來自 LLM 解釋的 "盡力而為")
- 它處理無法透過終端傳輸的二進位資料、串流或即時事件
- 範例：瀏覽器自動化 (Browserbase 會話管理)、TTS (音訊編碼 + 平台遞送)、視覺分析 (base64 圖片處理)

### 技能應該被內建嗎？

內建技能 (位於 `skills/`) 會隨每次 Hermes 安裝提供。它們應該是**對大多數使用者都有廣泛用途的**：

- 文件處理、網路研究、常見開發工作流、系統管理
- 被廣泛族群經常使用

如果你的技能是官方開發且實用，但並非所有人皆需 (例如：付費服務整合、重型依賴項)，請放在 **`optional-skills/`** —— 它會隨倉庫提供但預設不啟用。使用者可透過 `hermes skills browse` 發現 (標記為 "official") 並透過 `hermes skills install` 安裝 (無第三方警告，具備內建信任)。

如果你的技能非常專業、由社群貢獻或屬於小眾需求，則更適合放在 **技能中心 (Skills Hub)** —— 將其上傳至技能註冊表並在 [Nous Research Discord](https://discord.gg/NousResearch) 分享。使用者可透過 `hermes skills install` 安裝。

---

## 開發環境設定

### 先決條件

| 需求 | 備註 |
|-------------|-------|
| **Git** | 支援 `--recurse-submodules` |
| **Python 3.11+** | 若缺失，uv 會自動安裝 |
| **uv** | 高速 Python 套件管理器 ([安裝](https://docs.astral.sh/uv/)) |
| **Node.js 18+** | 選用 —— 瀏覽器工具與 WhatsApp 橋接器所需 |

### 複製與安裝

```bash
git clone --recurse-submodules https://github.com/NousResearch/hermes-agent.git
cd hermes-agent

# 使用 Python 3.11 建立虛擬環境
uv venv venv --python 3.11
export VIRTUAL_ENV="$(pwd)/venv"

# 安裝所有額外組件 (通訊網關, cron, CLI 選單, 開發工具)
uv pip install -e ".[all,dev]"

# 選用：RL 訓練子模組
# git submodule update --init tinker-atropos && uv pip install -e "./tinker-atropos"

# 選用：瀏覽器工具
npm install
```

### 開發配置

```bash
mkdir -p ~/.hermes/{cron,sessions,logs,memories,skills}
cp cli-config.yaml.example ~/.hermes/config.yaml
touch ~/.hermes/.env

# 至少新增一個 LLM 供應商金鑰：
echo 'OPENROUTER_API_KEY=sk-or-v1-your-key' >> ~/.hermes/.env
```

### 執行

```bash
# 建立全域存取符號連結
mkdir -p ~/.local/bin
ln -sf "$(pwd)/venv/bin/hermes" ~/.local/bin/hermes

# 驗證
hermes doctor
hermes chat -q "Hello"
```

### 執行測試

```bash
pytest tests/ -v
```

---

## 專案結構

```
hermes-agent/
├── run_agent.py              # AIAgent 類別 —— 核心對話迴圈、工具分發、會話持久化
├── cli.py                    # HermesCLI 類別 —— 互動式 TUI、prompt_toolkit 整合
├── model_tools.py            # 工具編排 (tools/registry.py 的薄層封裝)
├── toolsets.py               # 工具分組與預設值 (hermes-cli, hermes-telegram 等)
├── hermes_state.py           # SQLite 會話資料庫，支援 FTS5 全文檢索與會話標題
├── batch_runner.py           # 用於軌跡生成的並行批次處理
│
├── agent/                    # 代理程式內部機制 (模組化組件)
│   ├── prompt_builder.py         # 系統提示詞組合 (身分, 技能, 上下文檔案, 記憶)
│   ├── context_compressor.py     # 接近上下文限制時的自動摘要
│   ├── auxiliary_client.py       # 解析輔助 OpenAI 用戶端 (摘要, 視覺)
│   ├── display.py                # KawaiiSpinner，工具進度格式化
│   ├── model_metadata.py         # 模型上下文長度、Token 估計
│   └── trajectory.py             # 軌跡儲存輔助程式
│
├── hermes_cli/               # CLI 指令實作
│   ├── main.py                   # 入口點、參數解析、指令分發
│   ├── config.py                 # 配置管理、遷移、環境變數定義
│   ├── setup.py                  # 互動式安裝精靈
│   ├── auth.py                   # 供應商解析、OAuth、Nous Portal
│   ├── models.py                 # OpenRouter 模型選擇列表
│   ├── banner.py                 # 歡迎橫幅、ASCII 藝術
│   ├── commands.py               # 中央斜線指令註冊表 (CommandDef)、自動補全、網關輔助
│   ├── callbacks.py              # 互動式回呼 (澄清、sudo、核准)
│   ├── doctor.py                 # 診斷工具
│   ├── skills_hub.py             # 技能中心 CLI + /skills 斜線指令
│   └── skin_engine.py            # 皮膚/主題引擎 —— 資料驅動的 CLI 視覺自訂
│
├── tools/                    # 工具實作 (自我註冊)
│   ├── registry.py               # 中央工具註冊表 (Schema, 處理程序, 分發)
│   ├── approval.py               # 危險指令偵測 + 每會話核准
│   ├── terminal_tool.py          # 終端編排 (sudo, 環境生命週期, 後端)
│   ├── file_operations.py        # read_file, write_file, search, patch 等
│   ├── web_tools.py              # web_search, web_extract (並行/Firecrawl + Gemini 摘要)
│   ├── vision_tools.py           # 透過多模態模型進行圖片分析
│   ├── delegate_tool.py          # 子代理生成與並行任務執行
│   ├── code_execution_tool.py    # 具備 RPC 工具存取權限的沙盒化 Python
│   ├── session_search_tool.py    # 使用 FTS5 + 摘要搜尋過去的對話紀錄
│   ├── cronjob_tools.py          # 排程任務管理
│   ├── skill_tools.py            # 技能搜尋、加載、管理
│   └── environments/             # 終端執行後端
│       ├── base.py                   # BaseEnvironment 抽象基底類別
│       ├── local.py, docker.py, ssh.py, singularity.py, modal.py, daytona.py
│
├── gateway/                  # 通訊網關
│   ├── run.py                    # GatewayRunner —— 平台生命週期、訊息路由、cron
│   ├── config.py                 # 平台配置解析
│   ├── session.py                # 會話儲存、上下文提示詞、重置政策
│   └── platforms/                # 平台適配器
│       ├── telegram.py, discord_adapter.py, slack.py, whatsapp.py
│
├── scripts/                  # 安裝與橋接腳本
│   ├── install.sh                # Linux/macOS 安裝程式
│   ├── install.ps1               # Windows PowerShell 安裝程式
│   └── whatsapp-bridge/          # Node.js WhatsApp 橋接器 (Baileys)
│
├── skills/                   # 內建技能 (安裝時複製到 ~/.hermes/skills/)
├── optional-skills/          # 官方選用技能 (可透過中心發現，預設不啟用)
├── environments/             # RL 訓練環境 (Atropos 整合)
├── tests/                    # 測試套件
├── website/                  # 文件網站 (hermes-agent.nousresearch.com)
│
├── cli-config.yaml.example   # 配置範例 (複製到 ~/.hermes/config.yaml)
└── AGENTS.md                 # 提供給 AI 程式碼助手的開發指南
```

### 使用者配置 (儲存在 `~/.hermes/`)

| 路徑 | 用途 |
|------|---------|
| `~/.hermes/config.yaml` | 設定 (模型, 終端, 工具集, 壓縮等) |
| `~/.hermes/.env` | API 金鑰與機密資訊 |
| `~/.hermes/auth.json` | OAuth 憑證 (Nous Portal) |
| `~/.hermes/skills/` | 所有活動中的技能 (內建 + 中心安裝 + 代理自行建立) |
| `~/.hermes/memories/` | 持久記憶 (MEMORY.md, USER.md) |
| `~/.hermes/state.db` | SQLite 會話資料庫 |
| `~/.hermes/sessions/` | JSON 會話日誌 |
| `~/.hermes/cron/` | 排程任務資料 |
| `~/.hermes/whatsapp/session/` | WhatsApp 橋接憑證 |

---

## 架構概覽

### 核心迴圈

```
使用者訊息 → AIAgent._run_agent_loop()
  ├── 建構系統提示詞 (prompt_builder.py)
  ├── 建構 API 參數 (model, messages, tools, 推理配置)
  ├── 呼叫 LLM (相容於 OpenAI 的 API)
  ├── 若回應中包含 tool_calls:
  │     ├── 透過註冊表分發執行每個工具
  │     ├── 將工具結果加入對話
  │     └── 迴圈回到 LLM 呼叫
  ├── 若為文字回應:
  │     ├── 將會話持久化至資料庫
  │     └── 回傳最終回應 (final_response)
  └── 若接近 Token 限制則進行上下文壓縮
```

### 關鍵設計模式

- **自我註冊工具**：每個工具檔案在匯入時呼叫 `registry.register()`。`model_tools.py` 透過匯入所有工具模組觸發偵測。
- **工具集分組**：工具被分組為工具集 (`web`, `terminal`, `file`, `browser` 等)，可以依平台啟用/禁用。
- **會話持久化**：所有對話都儲存在 SQLite (`hermes_state.py`)，支援全文檢索與唯一會話標題。JSON 日誌存放在 `~/.hermes/sessions/`。
- **臨時注入**：系統提示詞與預填訊息在 API 呼叫時注入，絕不持久化到資料庫或日誌中。
- **供應商抽象化**：代理程式可與任何相容於 OpenAI 的 API 搭配使用。供應商解析在初始化時進行 (Nous Portal OAuth, OpenRouter API 金鑰, 或自訂端點)。
- **供應商路由**：使用 OpenRouter 時，config.yaml 中的 `provider_routing` 控制供應商選擇 (依吞吐量/延遲/價格排序，允許/忽略特定供應商，資料保留政策)。這些會作為 `extra_body.provider` 注入 API 請求中。

---

## 程式碼風格

- **PEP 8** 並帶有實際的例外 (我們不強制執行嚴格的行長度)
- **註釋**：僅在解釋非顯而易見的意圖、權衡或 API 特性時使用。不要描述程式碼本身做了什麼 —— `# 增加計數器` 沒有任何幫助
- **錯誤處理**：捕捉特定的異常。使用 `logger.warning()`/`logger.error()` 紀錄 —— 對於意外錯誤請使用 `exc_info=True` 以便堆疊追蹤顯示在日誌中
- **跨平台**：絕不假設環境為 Unix。參見[跨平台相容性](#跨平台相容性)

---

## 新增工具

在編寫工具之前，請先問：[這是否應該改為技能？](#應該開發技能-skill-還是工具-tool)

工具會向中央註冊表自我註冊。每個工具檔案應同時包含其 Schema、處理程序與註冊資訊：

```python
"""my_tool — 簡述此工具的功能。"""

import json
from tools.registry import registry


def my_tool(param1: str, param2: int = 10, **kwargs) -> str:
    """處理程序。回傳字串結果 (通常是 JSON)。"""
    result = do_work(param1, param2)
    return json.dumps(result)


MY_TOOL_SCHEMA = {
    "type": "function",
    "function": {
        "name": "my_tool",
        "description": "此工具的功能以及代理程式何時應使用它。",
        "parameters": {
            "type": "object",
            "properties": {
                "param1": {"type": "string", "description": "param1 的定義"},
                "param2": {"type": "integer", "description": "param2 的定義", "default": 10},
            },
            "required": ["param1"],
        },
    },
}


def _check_requirements() -> bool:
    """若此工具的依賴項可用則回傳 True。"""
    return True


registry.register(
    name="my_tool",
    toolset="my_toolset",
    schema=MY_TOOL_SCHEMA,
    handler=lambda args, **kw: my_tool(**args, **kw),
    check_fn=_check_requirements,
)
```

接著將匯入語句新增至 `model_tools.py` 的 `_modules` 列表中：

```python
_modules = [
    # ... 現有模組 ...
    "tools.my_tool",
]
```

如果是新的工具集，請將其新增至 `toolsets.py` 並加入相關的平台預設值。

---

## 新增技能 (Skill)

內建技能存放在 `skills/` 中，按類別組織。官方選用技能在 `optional-skills/` 中使用相同的結構：

```
skills/
├── research/
│   └── arxiv/
│       ├── SKILL.md              # 必要：主指令
│       └── scripts/              # 選用：輔助腳本
│           └── search_arxiv.py
├── productivity/
│   └── ocr-and-documents/
│       ├── SKILL.md
│       ├── scripts/
│       └── references/
└── ...
```

### SKILL.md 格式

```markdown
---
name: my-skill
description: 簡短描述 (顯示於技能搜尋結果)
version: 1.0.0
author: 你的名字
license: MIT
platforms: [macos, linux]          # 選用 —— 限制特定的作業系統平台
                                   #   有效值：macos, linux, windows
                                   #   省略則在所有平台加載 (預設)
required_environment_variables:    # 選用 —— 加載時的安全設定元資料
  - name: MY_API_KEY
    prompt: API 金鑰
    help: 從何處取得
    required_for: 完整功能
prerequisites:                     # 選用舊版運行時需求
  env_vars: [MY_API_KEY]           #   相容舊版的環境變數別名
  commands: [curl, jq]             #   僅供建議；不會隱藏技能
metadata:
  hermes:
    tags: [類別, 子類別, 關鍵字]
    related_skills: [其他技能名稱]
    fallback_for_toolsets: [web]       # 選用 —— 僅在工具集不可用時顯示
    requires_toolsets: [terminal]      # 選用 —— 僅在工具集可用時顯示
---

# 技能標題

簡短介紹。

## 何時使用
觸發條件 —— 代理程式何時應加載此技能？

## 快速參考
常用指令或 API 呼叫表格。

## 流程
代理程式應遵循的逐步指令。

## 陷阱
已知失敗模式及處理方式。

## 驗證
代理程式如何確認操作成功。
```

### 平台特定技能

技能可以透過 Frontmatter 的 `platforms` 欄位宣告支援的 OS 平台。具備此欄位的技能在不相容的平台上會自動從系統提示詞、`skills_list()` 與斜線指令中隱藏。

```yaml
platforms: [macos]            # 僅限 macOS (例如 iMessage, Apple Reminders)
platforms: [macos, linux]     # 支援 macOS 與 Linux
platforms: [windows]          # 僅限 Windows
```

若省略或留空，則在所有平台上加載 (保持向下相容)。範例請參見 `skills/apple/`。

### 條件式技能啟用

技能可以宣告條件，根據目前對話中可用的工具與工具集來控制其是否出現在系統提示詞中。這主要用於 **回退技能 (Fallback Skills)** —— 即僅在主要工具不可用時才顯示的替代方案。

`metadata.hermes` 下支援四個欄位：

```yaml
metadata:
  hermes:
    fallback_for_toolsets: [web]      # 僅當這些工具集不可用時顯示
    requires_toolsets: [terminal]     # 僅當這些工具集可用時顯示
    fallback_for_tools: [web_search]  # 僅當這些特定工具不可用時顯示
    requires_tools: [terminal]        # 僅當這些特定工具可用時顯示
```

**語義：**
- `fallback_for_*`: 該技能為備援。當列出的工具/工具集可用時，它會被**隱藏**；當它們不可用時，它會被**顯示**。可用於昂貴工具的免費替代方案。
- `requires_*`: 該技能需要特定工具才能運作。當列出的工具/工具集不可用時，它會被**隱藏**。用於依賴特定能力的技能 (例如：僅在有終端存取權時才有意義的技能)。
- 若同時指定兩者，則必須滿足所有條件技能才會顯示。
- 若皆未指定，則始終顯示 (向下相容)。

**範例：**

```yaml
# DuckDuckGo 搜尋 —— 當 Firecrawl (web 工具集) 不可用時顯示
metadata:
  hermes:
    fallback_for_toolsets: [web]

# 智慧家庭技能 —— 僅在終端可用時有用
metadata:
  hermes:
    requires_toolsets: [terminal]

# 本地瀏覽器回退 —— 當 Browserbase 不可用時顯示
metadata:
  hermes:
    fallback_for_toolsets: [browser]
```

過濾發生在 `agent/prompt_builder.py` 的提示詞建構期間。`build_skills_system_prompt()` 函數從代理程式接收可用工具與工具集的集合，並使用 `_skill_should_show()` 評估每個技能的條件。

### 技能設定元資料

技能可以透過 Frontmatter 的 `required_environment_variables` 欄位宣告加載時的安全設定需求。缺失值不會隱藏技能，而是在實際加載時觸發僅限 CLI 的安全提示。

```yaml
required_environment_variables:
  - name: TENOR_API_KEY
    prompt: Tenor API 金鑰
    help: 從 https://developers.google.com/tenor 取得金鑰
    required_for: 完整功能
```

使用者可以跳過設定並繼續加載。Hermes 僅向模型公開元資料 (`stored_as`, `skipped`, `validated`) —— 絕不洩漏機密值。

舊版的 `prerequisites.env_vars` 仍受支援，並會正規化為新格式。

```yaml
prerequisites:
  env_vars: [TENOR_API_KEY]       # 舊版別名
  commands: [curl, jq]            # 建議性的 CLI 檢查
```

網關與通訊平台會話絕不會在對話中收集機密；它們會指示使用者在本地執行 `hermes setup` 或更新 `~/.hermes/.env`。

**何時宣告必要的環境變數：**
- 技能使用應在加載時安全收集的 API 金鑰或權杖
- 若使用者跳過設定，技能仍有用處，但功能會優雅降級

**何時宣告指令先決條件：**
- 技能依賴可能未安裝的 CLI 工具 (例如 `himalaya`, `openhue`, `ddgs`)
- 將指令檢查視為引導，而非發現時的隱藏條件

範例請參閱 `skills/gifs/gif-search/` 與 `skills/email/himalaya/`。

### 技能編寫準則

- **除非絕對必要，否則不要使用外部依賴。** 優先使用 Python 標準庫、curl 以及現有的 Hermes 工具 (`web_extract`, `terminal`, `read_file`)。
- **漸進式揭露。** 將最常見的工作流放在首位。邊緣案例與進階用法放在底部。
- **包含輔助腳本** 用於 XML/JSON 解析或複雜邏輯 —— 不要期望 LLM 每次都能即興寫出解析器。
- **進行測試。** 執行 `hermes --toolsets skills -q "使用 X 技能來執行 Y"` 並驗證代理程式是否正確遵循指令。

---

## 新增皮膚 / 主題

Hermes 使用資料驅動的皮膚系統 —— 新增皮膚無需修改程式碼。

**選項 A：使用者皮膚 (YAML 檔案)**

建立 `~/.hermes/skins/<名稱>.yaml`：

```yaml
name: mytheme
description: 主題簡短描述

colors:
  banner_border: "#HEX"     # 面板邊框顏色
  banner_title: "#HEX"      # 面板標題顏色
  banner_accent: "#HEX"     # 章節標題顏色
  banner_dim: "#HEX"        # 弱化/暗色文字顏色
  banner_text: "#HEX"       # 內文顏色
  response_border: "#HEX"   # 回應框邊框

spinner:
  waiting_faces: ["(⚔)", "(⛨)"]
  thinking_faces: ["(⚔)", "(⌁)"]
  thinking_verbs: ["鍛造中", "策劃中"]
  wings:                     # 選用左右裝飾
    - ["⟪⚔", "⚔⟫"]

branding:
  agent_name: "我的代理"
  welcome: "歡迎訊息"
  response_label: " ⚔ 代理 "
  prompt_symbol: "⚔ ❯ "

tool_prefix: "╎"             # 工具輸出的行前綴
```

所有欄位皆為選用 —— 缺失值將從預設皮膚繼承。

**選項 B：內建皮膚**

新增至 `hermes_cli/skin_engine.py` 中的 `_BUILTIN_SKINS` 字典。使用與上述相同的結構但採 Python 字典格式。內建皮膚會隨套件分發並始終可用。

**啟動方式：**
- CLI：執行 `/skin mytheme` 或在 config.yaml 中設定 `display.skin: mytheme`
- 配置：`display: { skin: mytheme }`

完整 Schema 與現有皮膚範例請參閱 `hermes_cli/skin_engine.py`。

---

## 跨平台相容性

Hermes 支援 Linux、macOS 與 Windows。編寫涉及作業系統的程式碼時：

### 關鍵規則

1. **`termios` 與 `fcntl` 僅限 Unix。** 務必同時捕捉 `ImportError` 與 `NotImplementedError`：
   ```python
   try:
       from simple_term_menu import TerminalMenu
       menu = TerminalMenu(options)
       idx = menu.show()
   except (ImportError, NotImplementedError):
       # 回退方案：Windows 上的編號選單
       for i, opt in enumerate(options):
           print(f"  {i+1}. {opt}")
       idx = int(input("請選擇：")) - 1
   ```

2. **檔案編碼。** Windows 可能會以 `cp1252` 儲存 `.env` 檔案。務必處理編碼錯誤：
   ```python
   try:
       load_dotenv(env_path)
   except UnicodeDecodeError:
       load_dotenv(env_path, encoding="latin-1")
   ```

3. **進程管理。** `os.setsid()`、`os.killpg()` 以及訊號處理在 Windows 上有所不同。請使用平台檢查：
   ```python
   import platform
   if platform.system() != "Windows":
       kwargs["preexec_fn"] = os.setsid
   ```

4. **路徑分隔符號。** 使用 `pathlib.Path` 而非使用 `/` 進行字串拼接。

5. **安裝程式中的 Shell 指令。** 若修改了 `scripts/install.sh`，請檢查 `scripts/install.ps1` 是否也需要對應變更。

---

## 安全考量

Hermes 具備終端存取權限。安全性至關重要。

### 現有防護機制

| 層級 | 實作方式 |
|-------|---------------|
| **Sudo 密碼導向** | 使用 `shlex.quote()` 防止 Shell 注入 |
| **危險指令偵測** | 在 `tools/approval.py` 中使用 Regex 模式並配合使用者核准流程 |
| **Cron 提示詞注入** | `tools/cronjob_tools.py` 中的掃描器會阻擋指令覆蓋模式 |
| **寫入禁用列表** | 受保護路徑 (`~/.ssh/authorized_keys`, `/etc/shadow`) 會透過 `os.path.realpath()` 解析以防止符號連結繞過 |
| **技能防護** | 針對中心安裝技能的安全掃描器 (`tools/skills_guard.py`) |
| **程式碼執行沙盒** | `execute_code` 子進程在執行時會從環境中移除 API 金鑰 |
| **容器強化** | Docker：捨棄所有能力、禁止權限提升、PID 限制、大小受限的 tmpfs |

### 貢獻涉及安全性的程式碼時

- 在將使用者輸入內插至 Shell 指令時，**務必使用 `shlex.quote()`**
- 在進行基於路徑的存取控制檢查前，先使用 `os.path.realpath()` **解析符號連結**
- **不要紀錄機密資訊。** API 金鑰、權杖與密碼絕不可出現在日誌輸出中
- 在工具執行周圍**捕捉廣泛的異常**，以免單一失敗導致代理迴圈崩潰
- 若你的變更涉及檔案路徑、進程管理或 Shell 指令，**請在所有平台上進行測試**

若你的 PR 影響安全性，請在描述中明確標註。

---

## Pull Request 流程

### 分支命名規範

```
fix/描述        # Bug 修復
feat/描述       # 新功能
docs/描述       # 文件
test/描述       # 測試
refactor/描述   # 程式碼重構
```

### 提交前檢查

1. **執行測試**：`pytest tests/ -v`
2. **手動測試**：執行 `hermes` 並實際測試你修改的程式碼路徑
3. **檢查跨平台影響**：若涉及檔案 I/O、進程管理或終端處理，請考量 Windows 與 macOS
4. **保持 PR 聚焦**：每個 PR 僅包含一個邏輯變更。不要將 Bug 修復、重構與新功能混在一起。

### PR 描述

請包含：
- 修改了**什麼**以及**為什麼**
- **如何測試** (Bug 的重現步驟、新功能的用法範例)
- 你在**哪些平台**上進行過測試
- 引用任何相關的 Issue

### Commit 訊息

我們遵循 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/v1.0.0/) 規範：

```
<類型>(<範疇>): <描述>
```

| 類型 | 用途 |
|------|---------|
| `fix` | Bug 修復 |
| `feat` | 新功能 |
| `docs` | 文件 |
| `test` | 測試 |
| `refactor` | 程式碼重構 (無行為改變) |
| `chore` | 建置、CI、依賴更新 |

範疇 (Scopes)：`cli`, `gateway`, `tools`, `skills`, `agent`, `install`, `whatsapp`, `security` 等。

範例：
```
fix(cli): 修復當模型為字串時 save_config_value 的崩潰問題
feat(gateway): 新增 WhatsApp 多使用者會話隔離功能
fix(security): 防止 sudo 密碼導向時的 Shell 注入
test(tools): 為 file_operations 新增單元測試
```

---

## 問題回報 (Reporting Issues)

- 請使用 [GitHub Issues](https://github.com/NousResearch/hermes-agent/issues)
- 請包含：OS、Python 版本、Hermes 版本 (`hermes version`)、完整的錯誤堆疊追蹤
- 請包含重現步驟
- 建立前請先檢查是否有重複的 Issue
- 對於安全漏洞，請私下進行回報

---

## 社群

- **Discord**: [discord.gg/NousResearch](https://discord.gg/NousResearch) —— 用於提問、展示專案與分享技能
- **GitHub Discussions**: 用於設計提案與架構討論
- **Skills Hub**: 將專業技能上傳至註冊表並與社群分享

---

## 授權

參與貢獻即代表你同意你的貢獻將遵循 [MIT 授權](LICENSE)。
