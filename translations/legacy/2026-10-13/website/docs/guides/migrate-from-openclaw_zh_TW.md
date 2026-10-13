---
sidebar_position: 10
title: "從 OpenClaw 遷移"
description: "將 OpenClaw / Clawdbot 設置遷移至 Hermes Agent 的完整指南 —— 包含遷移內容、配置映射以及遷移後的檢查事項。"
---

# 從 OpenClaw 遷移

指令 `hermes claw migrate` 可以將你的 OpenClaw（或舊版的 Clawdbot/Moldbot）設置匯入到 Hermes。本指南將詳細說明遷移的具體內容、配置鍵值的映射關係，以及遷移後需要驗證的事項。

## 快速開始

```bash
# 預覽並進行遷移（系統會先顯示預覽，然後要求確認）
hermes claw migrate

# 僅進行預覽，不執行任何更改
hermes claw migrate --dry-run

# 完整遷移（包含 API 金鑰），跳過確認步驟
hermes claw migrate --preset full --yes
```

遷移過程在執行任何更改之前，始終會顯示要匯入內容的完整預覽。請檢查清單，然後確認以繼續。

預設從 `~/.openclaw/` 讀取數據。系統會自動偵測舊版的 `~/.clawdbot/` 或 `~/.moltbot/` 目錄，以及舊版的配置文件名（`clawdbot.json`、`moltbot.json`）。

## 選項

| 選項 | 描述 |
|--------|-------------|
| `--dry-run` | 僅預覽 —— 在顯示將要遷移的內容後停止。 |
| `--preset <name>` | `full`（預設，包含機密資訊）或 `user-data`（不包含 API 金鑰）。 |
| `--overwrite` | 發生衝突時覆寫現有的 Hermes 檔案（預設為跳過）。 |
| `--migrate-secrets` | 包含 API 金鑰（搭配 `--preset full` 時預設開啟）。 |
| `--source <path>` | 自定義 OpenClaw 目錄路徑。 |
| `--workspace-target <path>` | 放置 `AGENTS.md` 的目標位置。 |
| `--skill-conflict <mode>` | 處理技能衝突的模式：`skip`（預設）、`overwrite` 或 `rename`。 |
| `--yes` | 跳過預覽後的確認提示。 |

## 遷移內容

### 人設 (Persona)、記憶與指令

| 內容 | OpenClaw 來源 | Hermes 目標 | 備註 |
|------|----------------|-------------------|-------|
| 人設 (Persona) | `workspace/SOUL.md` | `~/.hermes/SOUL.md` | 直接複製 |
| 工作區指令 | `workspace/AGENTS.md` | `--workspace-target` 指定的 `AGENTS.md` | 需要 `--workspace-target` 參數 |
| 長期記憶 | `workspace/MEMORY.md` | `~/.hermes/memories/MEMORY.md` | 解析為條目，與現有條目合併並去重。使用 `§` 作為分隔符。 |
| 使用者設定檔 | `workspace/USER.md` | `~/.hermes/memories/USER.md` | 使用與記憶相同的合併邏輯。 |
| 每日記憶檔案 | `workspace/memory/*.md` | `~/.hermes/memories/MEMORY.md` | 所有每日檔案合併至主記憶。 |

系統也會檢查 `workspace.default/` 和 `workspace-main/` 作為備用路徑（OpenClaw 在近期的版本中將 `workspace/` 重新命名為 `workspace-main/`，並在多代理設置中使用 `workspace-{agentId}`）。

### 技能 (Skills) (4 個來源)

| 來源 | OpenClaw 位置 | Hermes 目標 |
|--------|------------------|-------------------|
| 工作區技能 | `workspace/skills/` | `~/.hermes/skills/openclaw-imports/` |
| 受管理/共用技能 | `~/.openclaw/skills/` | `~/.hermes/skills/openclaw-imports/` |
| 個人跨專案技能 | `~/.agents/skills/` | `~/.hermes/skills/openclaw-imports/` |
| 專案級共用技能 | `workspace/.agents/skills/` | `~/.hermes/skills/openclaw-imports/` |

技能衝突由 `--skill-conflict` 處理：`skip` 保留現有的 Hermes 技能，`overwrite` 進行替換，`rename` 建立一個帶有 `-imported` 字尾的副本。

### 模型與供應商配置 (Model and Provider)

| 內容 | OpenClaw 配置路徑 | Hermes 目標 | 備註 |
|------|---------------------|-------------------|-------|
| 預設模型 | `agents.defaults.model` | `config.yaml` → `model` | 可以是字串或 `{primary, fallbacks}` 物件 |
| 自定義供應商 | `models.providers.*` | `config.yaml` → `custom_providers` | 映射 `baseUrl`, `apiType`/`api` —— 處理簡寫（"openai", "anthropic"）和帶連字號的名稱。 |
| 供應商 API 金鑰 | `models.providers.*.apiKey` | `~/.hermes/.env` | 需要 `--migrate-secrets`。見下文 [API 金鑰解析](#api-金鑰解析)。 |

### 代理行為 (Agent Behavior)

| 內容 | OpenClaw 配置路徑 | Hermes 配置路徑 | 映射方式 |
|------|---------------------|-------------------|---------|
| 最大輪次 | `agents.defaults.timeoutSeconds` | `agent.max_turns` | `timeoutSeconds / 10`，最高 200 |
| 詳細模式 | `agents.defaults.verboseDefault` | `agent.verbose` | "off" / "on" / "full" |
| 推理力道 | `agents.defaults.thinkingDefault` | `agent.reasoning_effort` | "always"/"high" → "high", "auto"/"medium" → "medium", "off"/"low" → "low" |
| 壓縮 (Compression) | `agents.defaults.compaction.mode` | `compression.enabled` | "off" → false, 其他 → true |
| 壓縮模型 | `agents.defaults.compaction.model` | `compression.summary_model` | 直接複製字串 |
| 人為延遲 | `agents.defaults.humanDelay.mode` | `human_delay.mode` | "natural" / "custom" / "off" |
| 延遲時間 | `agents.defaults.humanDelay.minMs` / `.maxMs` | `human_delay.min_ms` / `.max_ms` | 直接複製 |
| 時區 | `agents.defaults.userTimezone` | `timezone` | 直接複製字串 |
| 執行逾時 | `tools.exec.timeoutSec` | `terminal.timeout` | 直接複製 |
| Docker 沙盒 | `agents.defaults.sandbox.backend` | `terminal.backend` | "docker" → "docker" |
| Docker 映像檔 | `agents.defaults.sandbox.docker.image` | `terminal.docker_image` | 直接複製 |

### 對話階段重置策略 (Session Reset Policies)

| OpenClaw 配置路徑 | Hermes 配置路徑 | 備註 |
|---------------------|-------------------|-------|
| `session.reset.mode` | `session_reset.mode` | "daily"、"idle" 或兩者皆是 |
| `session.reset.atHour` | `session_reset.at_hour` | 每日重置的小時 (0–23) |
| `session.reset.idleMinutes` | `session_reset.idle_minutes` | 閒置分鐘數 |

註：OpenClaw 也有 `session.resetTriggers`（如 `["daily", "idle"]`）。如果結構化的 `session.reset` 不存在，遷移將從 `resetTriggers` 進行推斷。

### MCP 伺服器

| OpenClaw 欄位 | Hermes 欄位 | 備註 |
|----------------|-------------|-------|
| `mcp.servers.*.command` | `mcp_servers.*.command` | Stdio 傳輸 |
| `mcp.servers.*.args` | `mcp_servers.*.args` | |
| `mcp.servers.*.env` | `mcp_servers.*.env` | |
| `mcp.servers.*.cwd` | `mcp_servers.*.cwd` | |
| `mcp.servers.*.url` | `mcp_servers.*.url` | HTTP/SSE 傳輸 |
| `mcp.servers.*.tools.include` | `mcp_servers.*.tools.include` | 工具過濾 |
| `mcp.servers.*.tools.exclude` | `mcp_servers.*.tools.exclude` | |

### 文字轉語音 (TTS)

TTS 設置會依照以下優先順序從 **兩個** OpenClaw 配置位置讀取：

1. `messages.tts.providers.{provider}.*`（標準位置）
2. 最上層的 `talk.providers.{provider}.*`（備用位置）
3. 舊版的扁平鍵值 `messages.tts.{provider}.*`（最舊的格式）

| 內容 | Hermes 目標 |
|------|-------------------|
| 供應商名稱 | `config.yaml` → `tts.provider` |
| ElevenLabs 語音 ID | `config.yaml` → `tts.elevenlabs.voice_id` |
| ElevenLabs 模型 ID | `config.yaml` → `tts.elevenlabs.model_id` |
| OpenAI 模型 | `config.yaml` → `tts.openai.model` |
| OpenAI 語音 | `config.yaml` → `tts.openai.voice` |
| Edge TTS 語音 | `config.yaml` → `tts.edge.voice`（OpenClaw 將 "edge" 重新命名為 "microsoft" —— 兩者皆可辨識） |
| TTS 資產 | `~/.hermes/tts/` (檔案複製) |

### 訊息平台

| 平台 | OpenClaw 配置路徑 | Hermes `.env` 變數 | 備註 |
|----------|---------------------|----------------------|-------|
| Telegram | `channels.telegram.botToken` 或 `.accounts.default.botToken` | `TELEGRAM_BOT_TOKEN` | 支援字串或 [SecretRef](#secretref-處理)。 |
| Telegram | `credentials/telegram-default-allowFrom.json` | `TELEGRAM_ALLOWED_USERS` | 從 `allowFrom[]` 陣列以逗號連接 |
| Discord | `channels.discord.token` | `DISCORD_BOT_TOKEN` | |
| Discord | `channels.discord.allowFrom` | `DISCORD_ALLOWED_USERS` | |
| Slack | `channels.slack.botToken` | `SLACK_BOT_TOKEN` | |
| Slack | `channels.slack.appToken` | `SLACK_APP_TOKEN` | |
| Slack | `channels.slack.allowFrom` | `SLACK_ALLOWED_USERS` | |
| WhatsApp | `channels.whatsapp.allowFrom` | `WHATSAPP_ALLOWED_USERS` | 透過 Baileys QR 配對 —— 遷移後需重新配對 |
| Signal | `channels.signal.account` | `SIGNAL_ACCOUNT` | |
| Signal | `channels.signal.httpUrl` | `SIGNAL_HTTP_URL` | |
| Signal | `channels.signal.allowFrom` | `SIGNAL_ALLOWED_USERS` | |
| Matrix | `channels.matrix.accessToken` | `MATRIX_ACCESS_TOKEN` | 使用 `accessToken` (非 `botToken`) |
| Mattermost | `channels.mattermost.botToken` | `MATTERMOST_BOT_TOKEN` | |

### 其他配置

| 內容 | OpenClaw 路徑 | Hermes 路徑 | 備註 |
|------|-------------|-------------|-------|
| 審核模式 | `approvals.exec.mode` | `config.yaml` → `approvals.mode` | "auto"→"off", "always"→"manual", "smart"→"smart" |
| 指令白名單 | `exec-approvals.json` | `config.yaml` → `command_allowlist` | 模式已合併並去重 |
| 瀏覽器 CDP URL | `browser.cdpUrl` | `config.yaml` → `browser.cdp_url` | |
| 瀏覽器無頭模式 | `browser.headless` | `config.yaml` → `browser.headless` | |
| Brave 搜尋金鑰 | `tools.web.search.brave.apiKey` | `.env` → `BRAVE_API_KEY` | 需要 `--migrate-secrets` |
| Gateway 驗證權杖 | `gateway.auth.token` | `.env` → `HERMES_GATEWAY_TOKEN` | 需要 `--migrate-secrets` |
| 工作目錄 | `agents.defaults.workspace` | `.env` → `MESSAGING_CWD` | |

### 已封存（無直接 Hermes 對應項）

以下內容將儲存至 `~/.hermes/migration/openclaw/<timestamp>/archive/` 供手動檢查：

| 內容 | 封存檔案 | 如何在 Hermes 中重建 |
|------|-------------|--------------------------|
| `IDENTITY.md` | `archive/workspace/IDENTITY.md` | 合併至 `SOUL.md` |
| `TOOLS.md` | `archive/workspace/TOOLS.md` | Hermes 具備內建的工具說明 |
| `HEARTBEAT.md` | `archive/workspace/HEARTBEAT.md` | 使用 Cron 任務處理週期性任務 |
| `BOOTSTRAP.md` | `archive/workspace/BOOTSTRAP.md` | 使用上下文檔案或技能 |
| Cron 任務 | `archive/cron-config.json` | 使用 `hermes cron create` 重建 |
| 外掛程式 | `archive/plugins-config.json` | 參見 [外掛指南](/docs/user-guide/features/hooks) |
| Hook/Webhook | `archive/hooks-config.json` | 使用 `hermes webhook` 或 Gateway Hook |
| 記憶體後端 | `archive/memory-backend-config.json` | 透過 `hermes honcho` 配置 |
| 技能註冊表 | `archive/skills-registry-config.json` | 使用 `hermes skills config` |
| UI/身份標識 | `archive/ui-identity-config.json` | 使用 `/skin` 指令 |
| 日誌記錄 | `archive/logging-diagnostics-config.json` | 在 `config.yaml` 的 logging 章節設置 |
| 多代理清單 | `archive/agents-list.json` | 使用 Hermes Profile (設定檔) |
| 頻道綁定 | `archive/bindings.json` | 針對每個平台手動設置 |

## API 金鑰解析

當啟用 `--migrate-secrets` 時，API 金鑰將按以下優先順序從 **四個來源** 收集：

1. **配置值** — `openclaw.json` 中的 `models.providers.*.apiKey` 和 TTS 供應商金鑰
2. **環境檔案** — `~/.openclaw/.env` (如 `OPENROUTER_API_KEY` 等)
3. **配置環境子物件** — `openclaw.json` 中的 `"env"` 或 `"env"."vars"`
4. **驗證設定檔** — `~/.openclaw/agents/main/agent/auth-profiles.json` (每個代理的憑據)

配置值優先，隨後的來源將填補任何剩餘的空缺。

### 支援的金鑰目標

`OPENROUTER_API_KEY`, `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `DEEPSEEK_API_KEY`, `GEMINI_API_KEY`, `ZAI_API_KEY`, `MINIMAX_API_KEY`, `ELEVENLABS_API_KEY`, `TELEGRAM_BOT_TOKEN`, `VOICE_TOOLS_OPENAI_KEY`

不在白名單中的金鑰將不會被複製。

## SecretRef 處理

OpenClaw 配置中的權杖和 API 金鑰可能採用三種格式：

```json
// 純字串
"channels": { "telegram": { "botToken": "123456:ABC-DEF..." } }

// 環境變數模板
"channels": { "telegram": { "botToken": "${TELEGRAM_BOT_TOKEN}" } }

// SecretRef 物件
"channels": { "telegram": { "botToken": { "source": "env", "id": "TELEGRAM_BOT_TOKEN" } } }
```

遷移程序會解析所有三種格式。對於 `source: "env"` 的 SecretRef，它會在 `~/.openclaw/.env` 中查找。對於 `source: "file"` 或 `source: "exec"`，遷移程序會發出警告，這些值必須手動透過 `hermes config set` 添加到 Hermes。

## 遷移後事項

1. **檢查遷移報告** — 完成後會顯示已遷移、已跳過和衝突項目的計數。

2. **檢查封存檔案** — `~/.hermes/migration/openclaw/<timestamp>/archive/` 中的內容需要手動處理。

3. **啟動新對話** — 匯入的技能和記憶條目將在新的對話階段中生效。

4. **驗證 API 金鑰** — 執行 `hermes status` 檢查供應商驗證狀態。

5. **測試訊息功能** — 如果遷移了平台權杖，請重啟 Gateway：`systemctl --user restart hermes-gateway`

6. **重新配對 WhatsApp** — WhatsApp 使用 QR code 配對，而非權杖遷移。執行 `hermes whatsapp` 進行配對。

7. **清理封存** — 確認一切正常後，執行 `hermes claw cleanup` 將剩餘的 OpenClaw 目錄重新命名為 `.pre-migration/` 以避免狀態混淆。

## 疑難排解

### 「找不到 OpenClaw 目錄」

遷移程序依序檢查 `~/.openclaw/`、`~/.clawdbot/` 和 `~/.moltbot/`。如果你的安裝路徑不同，請使用 `--source /path/to/your/openclaw`。

### 「找不到供應商 API 金鑰」

金鑰可能儲存在多個位置。如果金鑰使用 `source: "file"` 或 `source: "exec"`，則無法自動解析 —— 請透過 `hermes config set` 手動添加。

### 遷移後技能未出現

匯入的技能存放在 `~/.hermes/skills/openclaw-imports/`。啟動新對話或執行 `/skills` 指令以驗證它們是否已載入。
