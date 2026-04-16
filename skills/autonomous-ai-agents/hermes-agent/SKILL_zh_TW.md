---
name: hermes-agent
description: 使用與擴展 Hermes Agent 的完整指南 —— 包含 CLI 用法、安裝、配置、生成額外代理、網關平台、技能、語音、工具、配置文件 (profiles) 以及簡潔的貢獻者參考。當幫助使用者配置 Hermes、排除故障、生成代理實例或進行程式碼貢獻時，請加載此技能。
version: 2.0.0
author: Hermes Agent + Teknium
license: MIT
metadata:
  hermes:
    tags: [hermes, setup, configuration, multi-agent, spawning, cli, gateway, development]
    homepage: https://github.com/NousResearch/hermes-agent
    related_skills: [claude-code, codex, opencode]
---

# Hermes Agent

Hermes Agent 是由 Nous Research 開發的開源 AI 代理框架，可在您的終端、通訊平台和 IDE 中運行。它與 Claude Code (Anthropic)、Codex (OpenAI) 和 OpenClaw 屬於同一類別 —— 即透過工具調用 (tool calling) 與您的系統交互，自主執行編碼和任務的代理。Hermes 支援任何 LLM 提供商 (OpenRouter, Anthropic, OpenAI, DeepSeek, 本地模型以及其他 15+ 個提供商)，並可在 Linux、macOS 和 WSL 上運行。

Hermes 的獨特之處：

- **透過技能進行自我提升** —— Hermes 透過將可重用的程序保存為「技能 (skills)」來從經驗中學習。當它解決了一個複雜問題、發現了一個工作流或得到糾正時，它可以將該知識持久化為技能文件，並在未來的會話中加載。技能隨時間累積，使代理更擅長處理您的特定任務和環境。
- **跨會話的持久記憶** —— 記住您是誰、您的偏好、環境細節以及學到的教訓。可插拔的記憶後端 (內置、Honcho、Mem0 等) 讓您選擇記憶的工作方式。
- **多平台網關 (Gateway)** —— 同一個代理可以在 Telegram、Discord、Slack、WhatsApp、Signal、Matrix、Email 以及其他 10+ 個平台上運行，並具有完整的工具訪問權限，而不僅僅是聊天。
- **提供商無關 (Provider-agnostic)** —— 在工作流中途更換模型和提供商，而無需更改其他任何內容。憑據池 (Credential pools) 會自動在多個 API 金鑰之間輪換。
- **配置文件 (Profiles)** —— 運行多個獨立的 Hermes 實例，具有隔離的配置、會話、技能和記憶。
- **可擴展** —— 支援插件、MCP 伺服器、自定義工具、Webhook 觸發器、Cron 調度以及整個 Python 生態系統。

人們使用 Hermes 進行軟體開發、研究、系統管理、數據分析、內容創作、家庭自動化，以及任何受益於具有持久上下文和完整系統訪問權限的 AI 代理的任務。

**此技能可幫助您有效地使用 Hermes Agent** —— 包括設置、功能配置、生成額外的代理實例、排除故障、查找正確的命令和設置，以及在您需要擴展或貢獻時了解系統的工作原理。

**文件 (Docs)：** https://hermes-agent.nousresearch.com/docs/

## 快速啟動

```bash
# 安裝
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

# 交互式聊天 (預設)
hermes

# 單次查詢
hermes chat -q "法國的首都是哪裡？"

# 設置精靈
hermes setup

# 更改模型/提供商
hermes model

# 檢查健康狀況
hermes doctor
```

---

## CLI 參考

### 全域標籤 (Global Flags)

```
hermes [flags] [command]

  --version, -V             顯示版本
  --resume, -r SESSION      透過 ID 或標題恢復會話
  --continue, -c [NAME]     透過名稱或最近的會話恢復
  --worktree, -w            隔離的 git 工作樹模式 (平行代理)
  --skills, -s SKILL        預加載技能 (以逗號分隔或重複使用)
  --profile, -p NAME        使用指定的配置文件
  --yolo                    跳過危險命令的批准
  --pass-session-id         在系統提示詞中包含會話 ID
```

若無子命令，則預設為 `chat`。

### 聊天 (Chat)

```
hermes chat [flags]
  -q, --query TEXT          單次查詢，非交互式
  -m, --model MODEL         模型 (例如 anthropic/claude-sonnet-4)
  -t, --toolsets LIST       以逗號分隔的工具集
  --provider PROVIDER       強制指定提供商 (openrouter, anthropic, nous 等)
  -v, --verbose             詳細輸出
  -Q, --quiet               隱藏橫幅 (banner)、旋轉圖示 (spinner) 和工具預覽
  --checkpoints             啟用文件系統檢查點 (/rollback)
  --source TAG              會話來源標籤 (預設：cli)
```

### 配置 (Configuration)

```
hermes setup [section]      交互式精靈 (model|terminal|gateway|tools|agent)
hermes model                交互式模型/提供商選擇器
hermes config               查看當前配置
hermes config edit          在 $EDITOR 中打開 config.yaml
hermes config set KEY VAL   設置配置值
hermes config path          列印 config.yaml 路徑
hermes config env-path      列印 .env 路徑
hermes config check         檢查缺失或過時的配置
hermes config migrate       使用新選項更新配置
hermes login [--provider P] OAuth 登錄 (nous, openai-codex)
hermes logout               清除存儲的身份驗證資訊
hermes doctor [--fix]       檢查依賴項和配置
hermes status [--all]       顯示組件狀態
```

### 工具與技能 (Tools & Skills)

```
hermes tools                交互式啟用/禁用工具 (curses UI)
hermes tools list           顯示所有工具及其狀態
hermes tools enable NAME    啟用工具集
hermes tools disable NAME   禁用工具集

hermes skills list          列出已安裝的技能
hermes skills search QUERY  搜索技能庫 (skills hub)
hermes skills install ID    安裝技能
hermes skills inspect ID    不安裝直接預覽
hermes skills config        按平台啟用/禁用技能
hermes skills check         檢查更新
hermes skills update        更新過時的技能
hermes skills uninstall N   移除技能庫中的技能
hermes skills publish PATH  發布到註冊表
hermes skills browse        瀏覽所有可用技能
hermes skills tap add REPO  添加 GitHub 倉庫作為技能源
```

### MCP 伺服器

```
hermes mcp serve            將 Hermes 作為 MCP 伺服器運行
hermes mcp add NAME         添加 MCP 伺服器 (--url 或 --command)
hermes mcp remove NAME      移除 MCP 伺服器
hermes mcp list             列出已配置的伺服器
hermes mcp test NAME        測試連接
hermes mcp configure NAME   切換工具選擇
```

### 網關 (Gateway，訊息平台)

```
hermes gateway run          在前台啟動網關
hermes gateway install      安裝為後台服務
hermes gateway start/stop   控制服務
hermes gateway restart      重啟服務
hermes gateway status       檢查狀態
hermes gateway setup        配置平台
```

支援的平台：Telegram, Discord, Slack, WhatsApp, Signal, Email, SMS, Matrix, Mattermost, Home Assistant, 釘釘 (DingTalk), 飛書 (Feishu), 企微 (WeCom), BlueBubbles (iMessage), 微信 (Weixin), API Server, Webhooks。Open WebUI 透過 API Server 適配器連接。

平台文件：https://hermes-agent.nousresearch.com/docs/user-guide/messaging/

### 會話 (Sessions)

```
hermes sessions list        列出最近的會話
hermes sessions browse      交互式選擇器
hermes sessions export OUT  導出為 JSONL
hermes sessions rename ID T 重命名會話
hermes sessions delete ID   刪除會話
hermes sessions prune       清理舊會話 (--older-than N 天)
hermes sessions stats       會話存儲統計數據
```

### Cron 任務

```
hermes cron list            列出任務 (使用 --all 查看已禁用的)
hermes cron create SCHED    創建：'30m', 'every 2h', '0 9 * * *'
hermes cron edit ID         編輯排程、提示詞、交付方式
hermes cron pause/resume ID 控制任務狀態
hermes cron run ID          在下次跳動時觸發
hermes cron remove ID       刪除任務
hermes cron status          調度程序狀態
```

### Webhooks

```
hermes webhook subscribe N  在 /webhooks/<name> 創建路由
hermes webhook list         列出訂閱
hermes webhook remove NAME  移除訂閱
hermes webhook test NAME    發送測試 POST
```

### 配置文件 (Profiles)

```
hermes profile list         列出所有配置文件
hermes profile create NAME  創建 (--clone, --clone-all, --clone-from)
hermes profile use NAME     設置固定預設值
hermes profile delete NAME  刪除配置文件
hermes profile show NAME    顯示詳細資訊
hermes profile alias NAME   管理包裝腳本 (wrapper scripts)
hermes profile rename A B   重命名配置文件
hermes profile export NAME  導出為 tar.gz
hermes profile import FILE  從存檔導入
```

### 憑據池 (Credential Pools)

```
hermes auth add             交互式憑據精靈
hermes auth list [PROVIDER] 列出池化憑據
hermes auth remove P INDEX  按提供商和索引移除
hermes auth reset PROVIDER  清除耗盡狀態
```

### 其他

```
hermes insights [--days N]  使用情況分析
hermes update               更新到最新版本
hermes pairing list/approve/revoke  私訊授權
hermes plugins list/install/remove  插件管理
hermes honcho setup/status  Honcho 記憶集成 (需要 honcho 插件)
hermes memory setup/status/off  記憶提供商配置
hermes completion bash|zsh  Shell 補全
hermes acp                  ACP 伺服器 (IDE 集成)
hermes claw migrate         從 OpenClaw 遷移
hermes uninstall            解除安裝 Hermes
```

---

## 斜槓命令 (Slash Commands，會話內)

在交互式聊天會話期間輸入這些命令。

### 會話控制
```
/new (/reset)        新會話
/clear               清除螢幕 + 新會話 (CLI)
/retry               重新發送最後一條訊息
/undo                移除最後一次交換
/title [name]        為會話命名
/compress            手動壓縮上下文
/stop                終止後台進程
/rollback [N]        恢復文件系統檢查點
/background <prompt> 在後台運行提示詞
/queue <prompt>      排隊到下一輪
/resume [name]       恢復具名會話
```

### 配置
```
/config              顯示配置 (CLI)
/model [name]        顯示或更改模型
/provider            顯示提供商資訊
/personality [name]  設置個性
/reasoning [level]   設置推理等級 (none|minimal|low|medium|high|xhigh|show|hide)
/verbose             循環切換：off → new → all → verbose
/voice [on|off|tts]  語音模式
/yolo                切換批准繞過
/skin [name]         更改主題 (CLI)
/statusbar           切換狀態列 (CLI)
```

### 工具與技能
```
/tools               管理工具 (CLI)
/toolsets            列出工具集 (CLI)
/skills              搜索/安裝技能 (CLI)
/skill <name>        在會話中加載技能
/cron                管理 Cron 任務 (CLI)
/reload-mcp          重新加載 MCP 伺服器
/plugins             列出插件 (CLI)
```

### 網關 (Gateway)
```
/approve             批准待處理的命令 (網關)
/deny                拒絕待處理的命令 (網關)
/restart             重啟網關 (網關)
/sethome             將當前聊天設置為主頻道 (網關)
/update              更新 Hermes 到最新 (網關)
/platforms (/gateway) 顯示平台連接狀態 (網關)
```

### 實用工具
```
/branch (/fork)      分支當前會話
/btw                 臨時旁支問題 (不中斷主任務)
/fast                切換優先/快速處理
/browser             打開 CDP 瀏覽器連接
/history             顯示對話歷史 (CLI)
/save                將對話保存到文件 (CLI)
/paste               貼上剪貼簿圖片 (CLI)
/image               附加本地圖片文件 (CLI)
```

### 資訊
```
/help                顯示命令
/commands [page]     瀏覽所有命令 (網關)
/usage               權杖使用情況
/insights [days]     使用情況分析
/status              會話資訊 (網關)
/profile             當前配置文件資訊
```

### 退出
```
/quit (/exit, /q)    退出 CLI
```

---

## 關鍵路徑與配置

```
~/.hermes/config.yaml       主配置文件
~/.hermes/.env              API 金鑰與機密資訊
~/.hermes/skills/           已安裝的技能
~/.hermes/sessions/         會話轉錄文本
~/.hermes/logs/             網關和錯誤日誌
~/.hermes/auth.json         OAuth 權杖和憑據池
~/.hermes/hermes-agent/     原始程式碼 (如果是透過 git 安裝)
```

配置文件使用 `~/.hermes/profiles/<name>/` 路徑，佈局相同。

### 配置部分 (Sections)

使用 `hermes config edit` 或 `hermes config set section.key value` 進行編輯。

| 部分 | 關鍵選項 |
|---------|-------------|
| `model` | `default`, `provider`, `base_url`, `api_key`, `context_length` |
| `agent` | `max_turns` (90), `tool_use_enforcement` |
| `terminal` | `backend` (local/docker/ssh/modal), `cwd`, `timeout` (180) |
| `compression` | `enabled`, `threshold` (0.50), `target_ratio` (0.20) |
| `display` | `skin`, `tool_progress`, `show_reasoning`, `show_cost` |
| `stt` | `enabled`, `provider` (local/groq/openai/mistral) |
| `tts` | `provider` (edge/elevenlabs/openai/minimax/mistral/neutts) |
| `memory` | `memory_enabled`, `user_profile_enabled`, `provider` |
| `security` | `tirith_enabled`, `website_blocklist` |
| `delegation` | `model`, `provider`, `base_url`, `api_key`, `max_iterations` (50), `reasoning_effort` |
| `smart_model_routing` | `enabled`, `cheap_model` |
| `checkpoints` | `enabled`, `max_snapshots` (50) |

完整配置參考：https://hermes-agent.nousresearch.com/docs/user-guide/configuration

### 提供商 (Providers)

支援 20+ 個提供商。透過 `hermes model` 或 `hermes setup` 進行設置。

| 提供商 | 驗證方式 | 金鑰環境變數 |
|----------|------|-------------|
| OpenRouter | API 金鑰 | `OPENROUTER_API_KEY` |
| Anthropic | API 金鑰 | `ANTHROPIC_API_KEY` |
| Nous Portal | OAuth | `hermes login --provider nous` |
| OpenAI Codex | OAuth | `hermes login --provider openai-codex` |
| GitHub Copilot | 權杖 (Token) | `COPILOT_GITHUB_TOKEN` |
| Google Gemini | API 金鑰 | `GOOGLE_API_KEY` 或 `GEMINI_API_KEY` |
| DeepSeek | API 金鑰 | `DEEPSEEK_API_KEY` |
| xAI / Grok | API 金鑰 | `XAI_API_KEY` |
| Hugging Face | 權杖 | `HF_TOKEN` |
| Z.AI / GLM | API 金鑰 | `GLM_API_KEY` |
| MiniMax | API 金鑰 | `MINIMAX_API_KEY` |
| MiniMax CN | API 金鑰 | `MINIMAX_CN_API_KEY` |
| Kimi / Moonshot | API 金鑰 | `KIMI_API_KEY` |
| Alibaba / DashScope | API 金鑰 | `DASHSCOPE_API_KEY` |
| Xiaomi MiMo | API 金鑰 | `XIAOMI_API_KEY` |
| Kilo Code | API 金鑰 | `KILOCODE_API_KEY` |
| AI Gateway (Vercel) | API 金鑰 | `AI_GATEWAY_API_KEY` |
| OpenCode Zen | API 金鑰 | `OPENCODE_ZEN_API_KEY` |
| OpenCode Go | API 金鑰 | `OPENCODE_GO_API_KEY` |
| Qwen OAuth | OAuth | `hermes login --provider qwen-oauth` |
| 自定義端點 | 配置 | `config.yaml` 中的 `model.base_url` + `model.api_key` |
| GitHub Copilot ACP | 外部 | `COPILOT_CLI_PATH` 或 Copilot CLI |

完整提供商文件：https://hermes-agent.nousresearch.com/docs/integrations/providers

### 工具集 (Toolsets)

透過 `hermes tools` (交互式) 或 `hermes tools enable/disable NAME` 啟用/禁用。

| 工具集 | 提供功能 |
|---------|-----------------|
| `web` | 網頁搜索與內容提取 |
| `browser` | 瀏覽器自動化 (Browserbase, Camofox 或本地 Chromium) |
| `terminal` | Shell 命令與進程管理 |
| `file` | 文件讀取/寫入/搜索/修補 |
| `code_execution` | 沙盒化的 Python 執行 |
| `vision` | 影像分析 |
| `image_gen` | AI 圖片生成 |
| `tts` | 文字轉語音 (Text-to-speech) |
| `skills` | 技能瀏覽與管理 |
| `memory` | 持久化跨會話記憶 |
| `session_search` | 搜索過去的對話 |
| `delegation` | 子代理任務委派 |
| `cronjob` | 排程任務管理 |
| `clarify` | 向使用者提出澄清問題 |
| `messaging` | 跨平台訊息發送 |
| `search` | 僅限網頁搜索 (`web` 的子集) |
| `todo` | 會話內任務規劃與追踪 |
| `rl` | 強化學習工具 (預設關閉) |
| `moa` | 代理混合模式 (Mixture of Agents，預設關閉) |
| `homeassistant` | 智慧家居控制 (預設關閉) |

工具更改在 `/reset` (新會話) 後生效。為了保留提示詞快取，它們**不會**在對話中途生效。

---

## 語音與轉錄

### STT (語音轉文字)

來自通訊平台的語音訊息會被自動轉錄。

提供商優先級 (自動檢測)：
1. **本地 faster-whisper** — 免費，無需 API 金鑰：`pip install faster-whisper`
2. **Groq Whisper** — 免費層級：設置 `GROQ_API_KEY`
3. **OpenAI Whisper** — 付費：設置 `VOICE_TOOLS_OPENAI_KEY`
4. **Mistral Voxtral** — 設置 `MISTRAL_API_KEY`

配置：
```yaml
stt:
  enabled: true
  provider: local        # local, groq, openai, mistral
  local:
    model: base          # tiny, base, small, medium, large-v3
```

### TTS (文字轉語音)

| 提供商 | 環境變數 | 是否免費？ |
|----------|---------|-------|
| Edge TTS | 無 | 是 (預設) |
| ElevenLabs | `ELEVENLABS_API_KEY` | 有免費層級 |
| OpenAI | `VOICE_TOOLS_OPENAI_KEY` | 付費 |
| MiniMax | `MINIMAX_API_KEY` | 付費 |
| Mistral (Voxtral) | `MISTRAL_API_KEY` | 付費 |
| NeuTTS (本地) | 無 (`pip install neutts[all]` + `espeak-ng`) | 免費 |

語音命令：`/voice on` (語音對語音), `/voice tts` (始終語音), `/voice off`。

---

## 生成額外的 Hermes 實例

將額外的 Hermes 進程作為完全獨立的子進程運行 —— 具有獨立的會話、工具和環境。

### 何時使用此功能 vs delegate_task

| | `delegate_task` | 生成 `hermes` 進程 |
|-|-----------------|--------------------------|
| 隔離性 | 獨立對話，共享進程 | 完全獨立的進程 |
| 持續時間 | 分鐘級 (受限於父級循環) | 小時/天級 |
| 工具訪問 | 父級工具的子集 | 完整工具訪問權限 |
| 交互性 | 否 | 是 (PTY 模式) |
| 用例 | 快速平行子任務 | 長時間自主任務 |

### 單次模式 (One-Shot Mode)

```
terminal(command="hermes chat -q 'Research GRPO papers and write summary to ~/research/grpo.md'", timeout=300)

# 針對長任務的後台模式：
terminal(command="hermes chat -q 'Set up CI/CD for ~/myapp'", background=true)
```

### 交互式 PTY 模式 (透過 tmux)

Hermes 使用 prompt_toolkit，這需要一個真實的終端。使用 tmux 進行交互式生成：

```
# 啟動
terminal(command="tmux new-session -d -s agent1 -x 120 -y 40 'hermes'", timeout=10)

# 等待啟動，然後發送訊息
terminal(command="sleep 8 && tmux send-keys -t agent1 'Build a FastAPI auth service' Enter", timeout=15)

# 讀取輸出
terminal(command="sleep 20 && tmux capture-pane -t agent1 -p", timeout=5)

# 發送後續訊息
terminal(command="tmux send-keys -t agent1 'Add rate limiting middleware' Enter", timeout=5)

# 退出
terminal(command="tmux send-keys -t agent1 '/exit' Enter && sleep 2 && tmux kill-session -t agent1", timeout=10)
```

### 多代理協調

```
# 代理 A：後端
terminal(command="tmux new-session -d -s backend -x 120 -y 40 'hermes -w'", timeout=10)
terminal(command="sleep 8 && tmux send-keys -t backend 'Build REST API for user management' Enter", timeout=15)

# 代理 B：前端
terminal(command="tmux new-session -d -s frontend -x 120 -y 40 'hermes -w'", timeout=10)
terminal(command="sleep 8 && tmux send-keys -t frontend 'Build React dashboard for user management' Enter", timeout=15)

# 檢查進度，並在它們之間傳遞上下文
terminal(command="tmux capture-pane -t backend -p | tail -30", timeout=5)
terminal(command="tmux send-keys -t frontend 'Here is the API schema from the backend agent: ...' Enter", timeout=5)
```

### 會話恢復

```
# 恢復最近的會話
terminal(command="tmux new-session -d -s resumed 'hermes --continue'", timeout=10)

# 恢復特定會話
terminal(command="tmux new-session -d -s resumed 'hermes --resume 20260225_143052_a1b2c3'", timeout=10)
```

### 提示

- **快速子任務優先使用 `delegate_task`** —— 開銷比生成完整進程小。
- **編輯程式碼時使用 `-w` (工作樹模式)** 生成代理 —— 防止 git 衝突。
- **為單次模式設置超時** —— 複雜任務可能需要 5-10 分鐘。
- **對於「發完即忘」的任務使用 `hermes chat -q`** —— 不需要 PTY。
- **交互式會話使用 tmux** —— 原生 PTY 模式在 prompt_toolkit 中存在 `\r` 與 `\n` 的問題。
- **對於計畫任務**，使用 `cronjob` 工具而非生成進程 —— 它能處理交付與重試。

---

## 疑難排解

### 語音無法運作
1. 檢查 `config.yaml` 中的 `stt.enabled: true`。
2. 驗證提供商：`pip install faster-whisper` 或設置 API 金鑰。
3. 在網關中：`/restart`。在 CLI 中：退出並重新啟動。

### 工具不可用
1. `hermes tools` — 檢查該平台是否啟用了該工具集。
2. 某些工具需要環境變數 (檢查 `.env`)。
3. 啟用工具後執行 `/reset`。

### 模型/提供商問題
1. `hermes doctor` — 檢查配置和依賴項。
2. `hermes login` — 重新驗證 OAuth 提供商。
3. 檢查 `.env` 中是否有正確的 API 金鑰。
4. **Copilot 403 錯誤**：`gh auth login` 權杖**不適用**於 Copilot API。您必須透過 `hermes model` → GitHub Copilot 執行 Copilot 特有的 OAuth 裝置代碼流程。

### 更改未生效
- **工具/技能：** `/reset` 會啟動一個帶有更新工具集的會話。
- **配置更改：** 在網關中：`/restart`。在 CLI 中：退出並重新啟動。
- **程式碼更改：** 重啟 CLI 或網關進程。

### 技能未顯示
1. `hermes skills list` — 驗證是否已安裝。
2. `hermes skills config` — 檢查平台啟用情況。
3. 顯式加載：`/skill name` 或 `hermes -s name`。

### 網關問題
先檢查日誌：
```bash
grep -i "failed to send\|error" ~/.hermes/logs/gateway.log | tail -20
```

常見網關問題：
- **SSH 登出後網關停止**：啟用停留 (linger)：`sudo loginctl enable-linger $USER`。
- **關閉 WSL2 後網關停止**：WSL2 需要在 `/etc/wsl.conf` 中設置 `systemd=true` 以使 systemd 服務運作。否則，網關會後退到 `nohup` (會話關閉時即停止)。
- **網關崩潰循環**：重置失敗狀態：`systemctl --user reset-failed hermes-gateway`。

### 平台特定問題
- **Discord 機器人無回應**：必須在 Bot → Privileged Gateway Intents 中啟用 **Message Content Intent**。
- **Slack 機器人僅在私訊中運作**：必須訂閱 `message.channels` 事件。否則，機器人會忽略公開頻道。
- **Windows HTTP 400 "No models provided"**：配置文件編碼問題 (BOM)。確保 `config.yaml` 保存為不帶 BOM 的 UTF-8。

### 輔助模型 (Auxiliary models) 無法運作
如果 `auxiliary` 任務 (vision, compression, session_search) 靜默失敗，說明 `auto` 提供商找不到後端。請設置 `OPENROUTER_API_KEY` 或 `GOOGLE_API_KEY`，或顯式配置每個輔助任務的提供商：
```bash
hermes config set auxiliary.vision.provider <your_provider>
hermes config set auxiliary.vision.model <model_name>
```

---

## 資源查找指南

| 您在尋找... | 位置 |
|----------------|----------|
| 配置選項 | `hermes config edit` 或 [配置文檔](https://hermes-agent.nousresearch.com/docs/user-guide/configuration) |
| 可用工具 | `hermes tools list` 或 [工具參考](https://hermes-agent.nousresearch.com/docs/reference/tools-reference) |
| 斜槓命令 | 會話中的 `/help` 或 [斜槓命令參考](https://hermes-agent.nousresearch.com/docs/reference/slash-commands) |
| 技能目錄 | `hermes skills browse` 或 [技能目錄](https://hermes-agent.nousresearch.com/docs/reference/skills-catalog) |
| 提供商設置 | `hermes model` 或 [提供商指南](https://hermes-agent.nousresearch.com/docs/integrations/providers) |
| 平台設置 | `hermes gateway setup` 或 [訊息傳遞文檔](https://hermes-agent.nousresearch.com/docs/user-guide/messaging/) |
| MCP 伺服器 | `hermes mcp list` 或 [MCP 指南](https://hermes-agent.nousresearch.com/docs/user-guide/features/mcp) |
| 配置文件 (Profiles) | `hermes profile list` 或 [配置文件文檔](https://hermes-agent.nousresearch.com/docs/user-guide/profiles) |
| Cron 任務 | `hermes cron list` 或 [Cron 文檔](https://hermes-agent.nousresearch.com/docs/user-guide/features/cron) |
| 記憶 | `hermes memory status` 或 [記憶文檔](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory) |
| 環境變數 | `hermes config env-path` 或 [環境變數參考](https://hermes-agent.nousresearch.com/docs/reference/environment-variables) |
| CLI 命令 | `hermes --help` 或 [CLI 參考](https://hermes-agent.nousresearch.com/docs/reference/cli-commands) |
| 網關日誌 | `~/.hermes/logs/gateway.log` |
| 會話文件 | `~/.hermes/sessions/` 或 `hermes sessions browse` |
| 原始程式碼 | `~/.hermes/hermes-agent/` |

---

## 貢獻者快速參考

適用於臨時貢獻者和 PR 作者。完整開發者文檔：https://hermes-agent.nousresearch.com/docs/developer-guide/

### 專案佈局

```
hermes-agent/
├── run_agent.py          # AIAgent — 核心對話循環
├── model_tools.py        # 工具發現與分發
├── toolsets.py           # 工具集定義
├── cli.py                # 交互式 CLI (HermesCLI)
├── hermes_state.py       # SQLite 會話存儲
├── agent/                # 提示詞構建器、上下文壓縮、記憶、模型路由、憑據池、技能分發
├── hermes_cli/           # CLI 子命令、配置、設置、命令
│   ├── commands.py       # 斜槓命令註冊表 (CommandDef)
│   ├── config.py         # DEFAULT_CONFIG, 環境變數定義
│   └── main.py           # CLI 入口點與 argparse
├── tools/                # 一個工具一個文件
│   └── registry.py       # 中央工具註冊表
├── gateway/              # 訊息網關
│   └── platforms/        # 平台適配器 (telegram, discord 等)
├── cron/                 # 任務調度器
├── tests/                # 約 3000 個 pytest 測試
└── website/              # Docusaurus 文檔網站
```

配置：`~/.hermes/config.yaml` (設置), `~/.hermes/.env` (API 金鑰)。

### 添加工具 (需要 3 個步驟)

**1. 創建 `tools/your_tool.py`：**
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
    handler=lambda args, **kw: example_tool(
        param=args.get("param", ""), task_id=kw.get("task_id")),
    check_fn=check_requirements,
    requires_env=["EXAMPLE_API_KEY"],
)
```

**2. 添加到 `toolsets.py`** → `_HERMES_CORE_TOOLS` 列表。

自動發現：任何帶有頂層 `registry.register()` 調用的 `tools/*.py` 文件都會被自動導入 —— 無需手動列出。

所有處理程序必須返回 JSON 字串。路徑請使用 `get_hermes_home()`，切勿硬編碼 `~/.hermes`。

### 添加斜槓命令

1. 在 `hermes_cli/commands.py` 的 `COMMAND_REGISTRY` 中添加 `CommandDef`。
2. 在 `cli.py` → `process_command()` 中添加處理程序。
3. (可選) 在 `gateway/run.py` 中添加網關處理程序。

所有消費者 (說明文本、自動補全、Telegram 菜單、Slack 映射) 都會自動從中央註冊表導出。

### 代理循環 (高層級)

```
run_conversation():
  1. 構建系統提示詞
  2. 當迭代次數 < 最大值時循環：
     a. 調用 LLM (OpenAI 格式的訊息 + 工具 schema)
     b. 若有 tool_calls → 透過 handle_function_call() 分發每個調用 → 附加結果 → 繼續
     c. 若有文本回應 → 返回
  3. 接近權杖限制時自動觸發上下文壓縮
```

### 測試

```bash
python -m pytest tests/ -o 'addopts=' -q   # 完整測試集
python -m pytest tests/tools/ -q            # 特定區域測試
```

- 測試會自動將 `HERMES_HOME` 重定向到臨時目錄 —— 絕不會觸動真實的 `~/.hermes/`。
- 在推送任何更改前運行完整測試集。
- 使用 `-o 'addopts='` 清除任何預設的 pytest 標籤。

### 提交規範

```
type: 簡潔的主旨行

(可選) 內文
```

類型 (Types)：`fix:`, `feat:`, `refactor:`, `docs:`, `chore:`

### 關鍵規則

- **切勿破壞提示詞快取** —— 不要在對話中途更改上下文、工具或系統提示詞。
- **訊息角色交替** —— 絕不要連續出現兩個 assistant 或兩個 user 訊息。
- 所有路徑請使用 `hermes_constants` 中的 `get_hermes_home()` (支援配置文件隔離)。
- 配置值放入 `config.yaml`，機密資訊放入 `.env`。
- 新工具需要 `check_fn`，以便僅在滿足要求時顯示。
