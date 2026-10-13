---
sidebar_position: 2
title: "環境變數"
description: "Hermes Agent 使用的所有環境變數完整參考"
---

# 環境變數參考

所有變數都存放在 `~/.hermes/.env` 中。您也可以使用 `hermes config set VAR value` 來設定它們。

## LLM 提供商

| 變數 | 描述 |
|----------|-------------|
| `OPENROUTER_API_KEY` | OpenRouter API 金鑰 (建議使用以獲得最大靈活性) |
| `OPENROUTER_BASE_URL` | 覆蓋 OpenRouter 相容的基本 URL |
| `AI_GATEWAY_API_KEY` | Vercel AI Gateway API 金鑰 ([ai-gateway.vercel.sh](https://ai-gateway.vercel.sh)) |
| `AI_GATEWAY_BASE_URL` | 覆蓋 AI Gateway 基本 URL (預設：`https://ai-gateway.vercel.sh/v1`) |
| `OPENAI_API_KEY` | 用於自定義 OpenAI 相容端點的 API 金鑰 (與 `OPENAI_BASE_URL` 配合使用) |
| `OPENAI_BASE_URL` | 自定義端點的基本 URL (VLLM, SGLang 等) |
| `COPILOT_GITHUB_TOKEN` | 用於 Copilot API 的 GitHub 權杖 — 第一順位 (OAuth `gho_*` 或細粒度 PAT `github_pat_*`；**不支援** 傳統 PAT `ghp_*`) |
| `GH_TOKEN` | GitHub 權杖 — Copilot 的第二順位 (也被 `gh` CLI 使用) |
| `GITHUB_TOKEN` | GitHub 權杖 — Copilot 的第三順位 |
| `HERMES_COPILOT_ACP_COMMAND` | 覆蓋 Copilot ACP CLI 二進位路徑 (預設：`copilot`) |
| `COPILOT_CLI_PATH` | `HERMES_COPILOT_ACP_COMMAND` 的別名 |
| `HERMES_COPILOT_ACP_ARGS` | 覆蓋 Copilot ACP 參數 (預設：`--acp --stdio`) |
| `COPILOT_ACP_BASE_URL` | 覆蓋 Copilot ACP 基本 URL |
| `GLM_API_KEY` | z.ai / 智譜清言 GLM API 金鑰 ([z.ai](https://z.ai)) |
| `ZAI_API_KEY` | `GLM_API_KEY` 的別名 |
| `Z_AI_API_KEY` | `GLM_API_KEY` 的別名 |
| `GLM_BASE_URL` | 覆蓋 z.ai 基本 URL (預設：`https://api.z.ai/api/paas/v4`) |
| `KIMI_API_KEY` | Kimi / 月之暗面 AI API 金鑰 ([moonshot.ai](https://platform.moonshot.ai)) |
| `KIMI_BASE_URL` | 覆蓋 Kimi 基本 URL (預設：`https://api.moonshot.ai/v1`) |
| `KIMI_CN_API_KEY` | Kimi / 月之暗面中國 API 金鑰 ([moonshot.cn](https://platform.moonshot.cn)) |
| `ARCEEAI_API_KEY` | Arcee AI API 金鑰 ([chat.arcee.ai](https://chat.arcee.ai/)) |
| `ARCEE_BASE_URL` | 覆蓋 Arcee 基本 URL (預設：`https://api.arcee.ai/api/v1`) |
| `MINIMAX_API_KEY` | MiniMax API 金鑰 — 全球端點 ([minimax.io](https://www.minimax.io)) |
| `MINIMAX_BASE_URL` | 覆蓋 MiniMax 基本 URL (預設：`https://api.minimax.io/v1`) |
| `MINIMAX_CN_API_KEY` | MiniMax API 金鑰 — 中國端點 ([minimaxi.com](https://www.minimaxi.com)) |
| `MINIMAX_CN_BASE_URL` | 覆蓋 MiniMax 中國基本 URL (預設：`https://api.minimaxi.com/v1`) |
| `KILOCODE_API_KEY` | Kilo Code API 金鑰 ([kilo.ai](https://kilo.ai)) |
| `KILOCODE_BASE_URL` | 覆蓋 Kilo Code 基本 URL (預設：`https://api.kilo.ai/api/gateway`) |
| `XIAOMI_API_KEY` | 小米 MiMo API 金鑰 ([platform.xiaomimimo.com](https://platform.xiaomimimo.com)) |
| `XIAOMI_BASE_URL` | 覆蓋 小米 MiMo 基本 URL (預設：`https://api.xiaomimimo.com/v1`) |
| `HF_TOKEN` | Hugging Face 推論提供商權杖 ([huggingface.co/settings/tokens](https://huggingface.co/settings/tokens)) |
| `HF_BASE_URL` | 覆蓋 Hugging Face 基本 URL (預設：`https://router.huggingface.co/v1`) |
| `GOOGLE_API_KEY` | Google AI Studio API 金鑰 ([aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)) |
| `GEMINI_API_KEY` | `GOOGLE_API_KEY` 的別名 |
| `GEMINI_BASE_URL` | 覆蓋 Google AI Studio 基本 URL |
| `ANTHROPIC_API_KEY` | Anthropic Console API 金鑰 ([console.anthropic.com](https://console.anthropic.com/)) |
| `ANTHROPIC_TOKEN` | 手動或舊版 Anthropic OAuth/setup-token 覆蓋 |
| `DASHSCOPE_API_KEY` | 阿里巴巴雲 DashScope API 金鑰，用於通義千問模型 ([modelstudio.console.alibabacloud.com](https://modelstudio.console.alibabacloud.com/)) |
| `DASHSCOPE_BASE_URL` | 自定義 DashScope 基本 URL (預設：`https://coding-intl.dashscope.aliyuncs.com/v1`) |
| `DEEPSEEK_API_KEY` | 用於直接存取 DeepSeek 的 API 金鑰 ([platform.deepseek.com](https://platform.deepseek.com/api_keys)) |
| `DEEPSEEK_BASE_URL` | 自定義 DeepSeek API 基本 URL |
| `OPENCODE_ZEN_API_KEY` | OpenCode Zen API 金鑰 — 按量付費存取精選模型 ([opencode.ai](https://opencode.ai/auth)) |
| `OPENCODE_ZEN_BASE_URL` | 覆蓋 OpenCode Zen 基本 URL |
| `OPENCODE_GO_API_KEY` | OpenCode Go API 金鑰 — 每月 10 美元訂閱開放模型 ([opencode.ai](https://opencode.ai/auth)) |
| `OPENCODE_GO_BASE_URL` | 覆蓋 OpenCode Go 基本 URL |
| `CLAUDE_CODE_OAUTH_TOKEN` | 如果您手動匯出權杖，可在此明確覆蓋 Claude Code 權杖 |
| `HERMES_MODEL` | 在程序層級覆蓋模型名稱 (由 cron 排程器使用；正常使用建議偏好 `config.yaml`) |
| `VOICE_TOOLS_OPENAI_KEY` | 用於 OpenAI 語音轉文字 (STT) 和文字轉語音 (TTS) 提供商的偏好 OpenAI 金鑰 |
| `HERMES_LOCAL_STT_COMMAND` | 選配的在地語音轉文字指令模板。支援 `{input_path}`、`{output_dir}`、`{language}` 和 `{model}` 佔位符 |
| `HERMES_LOCAL_STT_LANGUAGE` | 傳遞給 `HERMES_LOCAL_STT_COMMAND` 或自動偵測在地 `whisper` CLI 備援的預設語言 (預設：`en`) |
| `HERMES_HOME` | 覆蓋 Hermes 配置目錄 (預設：`~/.hermes`)。同時也會作用於網關 PID 檔案範圍和 systemd 服務名稱，因此多個安裝實例可以併行運行 |

## 提供商驗證 (OAuth)

對於原生 Anthropic 驗證，Hermes 偏好使用 Claude Code 自身的憑證檔案 (如果存在)，因為這些憑證可以自動刷新。環境變數如 `ANTHROPIC_TOKEN` 仍可用作手動覆蓋，但不再是 Claude Pro/Max 登入的偏好路徑。

| 變數 | 描述 |
|----------|-------------|
| `HERMES_INFERENCE_PROVIDER` | 覆蓋提供商選擇：`auto`、`openrouter`、`nous`、`openai-codex`、`copilot`、`copilot-acp`、`anthropic`、`huggingface`、`zai`、`kimi-coding`、`kimi-coding-cn`、`minimax`、`minimax-cn`、`kilocode`、`xiaomi`、`arcee`、`alibaba`、`deepseek`、`opencode-zen`、`opencode-go`、`ai-gateway` (預設：`auto`) |
| `HERMES_PORTAL_BASE_URL` | 覆蓋 Nous Portal 網址 (用於開發/測試) |
| `NOUS_INFERENCE_BASE_URL` | 覆蓋 Nous 推論 API 網址 |
| `HERMES_NOUS_MIN_KEY_TTL_SECONDS` | 代理金鑰重新鑄造前的最小存活時間 (TTL) (預設：1800 = 30 分鐘) |
| `HERMES_NOUS_TIMEOUT_SECONDS` | Nous 憑證 / 權杖流程的 HTTP 超時時間 |
| `HERMES_DUMP_REQUESTS` | 將 API 請求酬載傾卸至日誌檔案 (`true`/`false`) |
| `HERMES_PREFILL_MESSAGES_FILE` | 在 API 呼叫時注入的臨時預填訊息 JSON 檔案路徑 |
| `HERMES_TIMEZONE` | IANA 時區覆蓋 (例如 `America/New_York`) |

## 工具 API

| 變數 | 描述 |
|----------|-------------|
| `PARALLEL_API_KEY` | AI 原生網頁搜尋 ([parallel.ai](https://parallel.ai/)) |
| `FIRECRAWL_API_KEY` | 網頁爬取與雲端瀏覽器 ([firecrawl.dev](https://firecrawl.dev/)) |
| `FIRECRAWL_API_URL` | 用於自代管實例的自定義 Firecrawl API 端點 (選填) |
| `TAVILY_API_KEY` | Tavily API 金鑰，用於 AI 原生網頁搜尋、擷取和爬取 ([app.tavily.com](https://app.tavily.com/home)) |
| `EXA_API_KEY` | Exa API 金鑰，用於 AI 原生網頁搜尋與內容 ([exa.ai](https://exa.ai/)) |
| `BROWSERBASE_API_KEY` | 瀏覽器自動化 ([browserbase.com](https://browserbase.com/)) |
| `BROWSERBASE_PROJECT_ID` | Browserbase 專案 ID |
| `BROWSER_USE_API_KEY` | Browser Use 雲端瀏覽器 API 金鑰 ([browser-use.com](https://browser-use.com/)) |
| `FIRECRAWL_BROWSER_TTL` | Firecrawl 瀏覽器工作階段存活時間 (秒) (預設：300) |
| `BROWSER_CDP_URL` | 用於在地瀏覽器的 Chrome DevTools Protocol 網址 (透過 `/browser connect` 設定，例如 `ws://localhost:9222`) |
| `CAMOFOX_URL` | Camofox 在地反偵測瀏覽器網址 (預設：`http://localhost:9377`) |
| `BROWSER_INACTIVITY_TIMEOUT` | 瀏覽器工作階段閒置超時時間 (秒) |
| `FAL_KEY` | 圖片生成 ([fal.ai](https://fal.ai/)) |
| `GROQ_API_KEY` | Groq Whisper STT API 金鑰 ([groq.com](https://groq.com/)) |
| `ELEVENLABS_API_KEY` | ElevenLabs 進階 TTS 音色 ([elevenlabs.io](https://elevenlabs.io/)) |
| `STT_GROQ_MODEL` | 覆蓋 Groq STT 模型 (預設：`whisper-large-v3-turbo`) |
| `GROQ_BASE_URL` | 覆蓋 Groq OpenAI 相容 STT 端點 |
| `STT_OPENAI_MODEL` | 覆蓋 OpenAI STT 模型 (預設：`whisper-1`) |
| `STT_OPENAI_BASE_URL` | 覆蓋 OpenAI 相容 STT 端點 |
| `GITHUB_TOKEN` | 用於技能中心 (Skills Hub) 的 GitHub 權杖 (更高 API 速率限制、技能發佈) |
| `HONCHO_API_KEY` | 跨工作階段使用者建模 ([honcho.dev](https://honcho.dev/)) |
| `HONCHO_BASE_URL` | 自代管 Honcho 實例的基本 URL (預設為 Honcho 雲端)。在地實例無需 API 金鑰 |
| `SUPERMEMORY_API_KEY` | 具備設定檔召回與工作階段擷取的語義長期記憶 ([supermemory.ai](https://supermemory.ai)) |
| `TINKER_API_KEY` | RL 訓練 ([tinker-console.thinkingmachines.ai](https://tinker-console.thinkingmachines.ai/)) |
| `WANDB_API_KEY` | RL 訓練指標 ([wandb.ai](https://wandb.ai/)) |
| `DAYTONA_API_KEY` | Daytona 雲端沙盒 ([daytona.io](https://daytona.io/)) |

## 終端機後端

| 變數 | 描述 |
|----------|-------------|
| `TERMINAL_ENV` | 後端類型：`local`, `docker`, `ssh`, `singularity`, `modal`, `daytona` |
| `TERMINAL_DOCKER_IMAGE` | Docker 映像檔 (預設：`nikolaik/python-nodejs:python3.11-nodejs20`) |
| `TERMINAL_DOCKER_FORWARD_ENV` | 要明確轉發至 Docker 終端機工作階段的環境變數名稱 JSON 陣列。注意：技能聲明的 `required_environment_variables` 會自動轉發 — 您僅需為未被任何技能聲明的變數設定此項。 |
| `TERMINAL_DOCKER_VOLUMES` | 額外的 Docker 磁碟卷掛載 (以逗號分隔的 `host:container` 對) |
| `TERMINAL_DOCKER_MOUNT_CWD_TO_WORKSPACE` | 進階選項：將啟動時的當前工作目錄掛載到 Docker `/workspace` (`true`/`false`, 預設：`false`) |
| `TERMINAL_SINGULARITY_IMAGE` | Singularity 映像檔或 `.sif` 路徑 |
| `TERMINAL_MODAL_IMAGE` | Modal 容器映像檔 |
| `TERMINAL_DAYTONA_IMAGE` | Daytona 沙盒映像檔 |
| `TERMINAL_TIMEOUT` | 指令超時時間 (秒) |
| `TERMINAL_LIFETIME_SECONDS` | 終端機工作階段最大存活時間 (秒) |
| `TERMINAL_CWD` | 所有終端機工作階段的工作目錄 |
| `SUDO_PASSWORD` | 在無互動提示的情況下啟用 sudo |

對於雲端沙盒後端，持久性是以檔案系統為導向的。`TERMINAL_LIFETIME_SECONDS` 控制 Hermes 何時清理閒置的終端機工作階段，隨後的恢復可能會重新建立沙盒，而非保持相同的活動程序運行。

## SSH 後端

| 變數 | 描述 |
|----------|-------------|
| `TERMINAL_SSH_HOST` | 遠端伺服器主機名稱 |
| `TERMINAL_SSH_USER` | SSH 使用者名稱 |
| `TERMINAL_SSH_PORT` | SSH 埠號 (預設：22) |
| `TERMINAL_SSH_KEY` | 私鑰路徑 |
| `TERMINAL_SSH_PERSISTENT` | 覆蓋 SSH 的持久化 shell 設定 (預設：跟隨 `TERMINAL_PERSISTENT_SHELL`) |

## 容器資源 (Docker, Singularity, Modal, Daytona)

| 變數 | 描述 |
|----------|-------------|
| `TERMINAL_CONTAINER_CPU` | CPU 核心數 (預設：1) |
| `TERMINAL_CONTAINER_MEMORY` | 記憶體大小 (MB) (預設：5120) |
| `TERMINAL_CONTAINER_DISK` | 磁碟大小 (MB) (預設：51200) |
| `TERMINAL_CONTAINER_PERSISTENT` | 跨工作階段持久化容器檔案系統 (預設：`true`) |
| `TERMINAL_SANDBOX_DIR` | 用於工作區和覆蓋層的主機目錄 (預設：`~/.hermes/sandboxes/`) |

## 持久化 Shell

| 變數 | 描述 |
|----------|-------------|
| `TERMINAL_PERSISTENT_SHELL` | 為非在地後端啟用持久化 shell (預設：`true`)。亦可在 config.yaml 的 `terminal.persistent_shell` 中設定 |
| `TERMINAL_LOCAL_PERSISTENT` | 為在地後端啟用持久化 shell (預設：`false`) |
| `TERMINAL_SSH_PERSISTENT` | 覆蓋 SSH 後端的持久化 shell 設定 (預設：跟隨 `TERMINAL_PERSISTENT_SHELL`) |

## 即時通訊

| 變數 | 描述 |
|----------|-------------|
| `TELEGRAM_BOT_TOKEN` | Telegram 機器人權杖 (來自 @BotFather) |
| `TELEGRAM_ALLOWED_USERS` | 允許使用機器人的以逗號分隔的使用者 ID |
| `TELEGRAM_HOME_CHANNEL` | 用於 cron 傳送的預設 Telegram 聊天/頻道 |
| `TELEGRAM_HOME_CHANNEL_NAME` | Telegram Home 頻道的顯示名稱 |
| `TELEGRAM_WEBHOOK_URL` | 用於 Webhook 模式的公開 HTTPS 網址 (啟用 Webhook 而非輪詢) |
| `TELEGRAM_WEBHOOK_PORT` | Webhook 伺服器的在地監聽埠 (預設：`8443`) |
| `TELEGRAM_WEBHOOK_SECRET` | 用於驗證更新是否來自 Telegram 的秘密權杖 |
| `TELEGRAM_REACTIONS` | 在處理過程中啟用訊息的表情符號回應 (預設：`false`) |
| `DISCORD_BOT_TOKEN` | Discord 機器人權杖 |
| `DISCORD_ALLOWED_USERS` | 允許使用機器人的以逗號分隔的 Discord 使用者 ID |
| `DISCORD_HOME_CHANNEL` | 用於 cron 傳送的預設 Discord 頻道 |
| `DISCORD_HOME_CHANNEL_NAME` | Discord Home 頻道的顯示名稱 |
| `DISCORD_REQUIRE_MENTION` | 在伺服器頻道中需要 @提及 才會回應 |
| `DISCORD_FREE_RESPONSE_CHANNELS` | 不需要提及即可回應的以逗號分隔的頻道 ID |
| `DISCORD_AUTO_THREAD` | 支援時自動為長回覆建立討論串 |
| `DISCORD_REACTIONS` | 在處理過程中啟用訊息的表情符號回應 (預設：`true`) |
| `DISCORD_IGNORED_CHANNELS` | 機器人絕不回應的以逗號分隔的頻道 ID |
| `DISCORD_NO_THREAD_CHANNELS` | 機器人回應但不自動建立討論串的以逗號分隔的頻道 ID |
| `DISCORD_REPLY_TO_MODE` | 回覆引用行為：`off`、`first` (預設) 或 `all` |
| `SLACK_BOT_TOKEN` | Slack 機器人權杖 (`xoxb-...`) |
| `SLACK_APP_TOKEN` | Slack 應用程式層級權杖 (`xapp-...`，Socket 模式必需) |
| `SLACK_ALLOWED_USERS` | 以逗號分隔的 Slack 使用者 ID |
| `SLACK_HOME_CHANNEL` | 用於 cron 傳送的預設 Slack 頻道 |
| `SLACK_HOME_CHANNEL_NAME` | Slack Home 頻道的顯示名稱 |
| `WHATSAPP_ENABLED` | 啟用 WhatsApp 橋接器 (`true`/`false`) |
| `WHATSAPP_MODE` | `bot` (獨立號碼) 或 `self-chat` (給自己發訊息) |
| `WHATSAPP_ALLOWED_USERS` | 以逗號分隔的電話號碼 (含國碼，無 `+`)，或 `*` 允許所有發送者 |
| `WHATSAPP_ALLOW_ALL_USERS` | 無需允許列表即可讓所有 WhatsApp 發送者存取 (`true`/`false`) |
| `WHATSAPP_DEBUG` | 在橋接器中記錄原始訊息事件以便排錯 (`true`/`false`) |
| `SIGNAL_HTTP_URL` | signal-cli 守護程序 HTTP 端點 (例如 `http://127.0.0.1:8080`) |
| `SIGNAL_ACCOUNT` | 以 E.164 格式表示的機器人電話號碼 |
| `SIGNAL_ALLOWED_USERS` | 以逗號分隔的 E.164 電話號碼或 UUID |
| `SIGNAL_GROUP_ALLOWED_USERS` | 以逗號分隔的群組 ID，或 `*` 代表所有群組 |
| `SIGNAL_HOME_CHANNEL_NAME` | Signal Home 頻道的顯示名稱 |
| `SIGNAL_IGNORE_STORIES` | 忽略 Signal 限時動態/狀態更新 |
| `SIGNAL_ALLOW_ALL_USERS` | 無需允許列表即可讓所有 Signal 使用者存取 |
| `TWILIO_ACCOUNT_SID` | Twilio 帳戶 SID (與 telephony 技能共享) |
| `TWILIO_AUTH_TOKEN` | Twilio 驗證權杖 (與 telephony 技能共享；也用於 Webhook 簽章驗證) |
| `TWILIO_PHONE_NUMBER` | 以 E.164 格式表示的 Twilio 電話號碼 (與 telephony 技能共享) |
| `SMS_WEBHOOK_URL` | 用於 Twilio 簽章驗證的公開網址 — 必須與 Twilio Console 中的 Webhook 網址一致 (必需) |
| `SMS_WEBHOOK_PORT` | 接收簡訊的 Webhook 監聽埠 (預設：`8080`) |
| `SMS_WEBHOOK_HOST` | Webhook 綁定位址 (預設：`0.0.0.0`) |
| `SMS_INSECURE_NO_SIGNATURE` | 設為 `true` 以停用 Twilio 簽章驗證 (僅限在地開發 — 不適用於生產環境) |
| `SMS_ALLOWED_USERS` | 允許聊天的以逗號分隔的 E.164 電話號碼 |
| `SMS_ALLOW_ALL_USERS` | 無需允許列表即可讓所有簡訊發送者存取 |
| `SMS_HOME_CHANNEL` | 用於 cron 任務 / 通知傳送的電話號碼 |
| `SMS_HOME_CHANNEL_NAME` | SMS Home 頻道的顯示名稱 |
| `EMAIL_ADDRESS` | 電子郵件網關適配器的信箱位址 |
| `EMAIL_PASSWORD` | 電子郵件帳戶的密碼或應用程式密碼 |
| `EMAIL_IMAP_HOST` | 電子郵件適配器的 IMAP 主機名稱 |
| `EMAIL_IMAP_PORT` | IMAP 埠號 |
| `EMAIL_SMTP_HOST` | 電子郵件適配器的 SMTP 主機名稱 |
| `EMAIL_SMTP_PORT` | SMTP 埠號 |
| `EMAIL_ALLOWED_USERS` | 允許給機器人發送郵件的以逗號分隔的信箱位址 |
| `EMAIL_HOME_ADDRESS` | 預設的主動電子郵件傳送收件人 |
| `EMAIL_HOME_ADDRESS_NAME` | 電子郵件 Home 目標的顯示名稱 |
| `EMAIL_POLL_INTERVAL` | 電子郵件輪詢間隔 (秒) |
| `EMAIL_ALLOW_ALL_USERS` | 允許所有傳入的電子郵件發送者 |
| `DINGTALK_CLIENT_ID` | 來自開發者平台的釘釘機器人 AppKey ([open.dingtalk.com](https://open.dingtalk.com)) |
| `DINGTALK_CLIENT_SECRET` | 釘釘機器人 AppSecret |
| `DINGTALK_ALLOWED_USERS` | 允許給機器人發送訊息的以逗號分隔的釘釘使用者 ID |
| `FEISHU_APP_ID` | 來自 [open.feishu.cn](https://open.feishu.cn/) 的飛書/Lark 機器人 App ID |
| `FEISHU_APP_SECRET` | 飛書/Lark 機器人 App Secret |
| `FEISHU_DOMAIN` | `feishu` (中國) 或 `lark` (國際)。預設：`feishu` |
| `FEISHU_CONNECTION_MODE` | `websocket` (建議) 或 `webhook`。預設：`websocket` |
| `FEISHU_ENCRYPT_KEY` | Webhook 模式的選配加密金鑰 |
| `FEISHU_VERIFICATION_TOKEN` | Webhook 模式的選配驗證權杖 |
| `FEISHU_ALLOWED_USERS` | 允許給機器人發送訊息的以逗號分隔的飛書使用者 ID |
| `FEISHU_HOME_CHANNEL` | 用於 cron 傳送和通知的飛書聊天 ID |
| `WECOM_BOT_ID` | 來自管理後台的企業微信 AI 機器人 ID |
| `WECOM_SECRET` | 企業微信 AI 機器人秘密金鑰 |
| `WECOM_WEBSOCKET_URL` | 自定義 WebSocket 網址 (預設：`wss://openws.work.weixin.qq.com`) |
| `WECOM_ALLOWED_USERS` | 允許與機器人聊天的以逗號分隔的企業微信使用者 ID |
| `WECOM_HOME_CHANNEL` | 用於 cron 傳送和通知的企業微信聊天 ID |
| `WECOM_CALLBACK_CORP_ID` | 回呼 (Callback) 自建應用程式的企業微信企業 ID |
| `WECOM_CALLBACK_CORP_SECRET` | 自建應用程式的企業秘密金鑰 |
| `WECOM_CALLBACK_AGENT_ID` | 自建應用程式的 Agent ID |
| `WECOM_CALLBACK_TOKEN` | 回呼驗證權杖 |
| `WECOM_CALLBACK_ENCODING_AES_KEY` | 用於回呼加密的 AES 金鑰 |
| `WECOM_CALLBACK_HOST` | 回呼伺服器綁定位址 (預設：`0.0.0.0`) |
| `WECOM_CALLBACK_PORT` | 回呼伺服器埠號 (預設：`8645`) |
| `WECOM_CALLBACK_ALLOWED_USERS` | 允許列表的以逗號分隔的使用者 ID |
| `WECOM_CALLBACK_ALLOW_ALL_USERS` | 設為 `true` 以在無允許列表的情況下讓所有使用者存取 |
| `WEIXIN_ACCOUNT_ID` | 透過 iLink Bot API 進行 QR 登入獲取的微信帳號 ID |
| `WEIXIN_TOKEN` | 透過 iLink Bot API 進行 QR 登入獲取的微信驗證權杖 |
| `WEIXIN_BASE_URL` | 覆蓋 微信 iLink Bot API 基本 URL (預設：`https://ilinkai.weixin.qq.com`) |
| `WEIXIN_CDN_BASE_URL` | 覆蓋 微信媒體 CDN 基本 URL (預設：`https://novac2c.cdn.weixin.qq.com/c2c`) |
| `WEIXIN_DM_POLICY` | 私訊策略：`open`、`allowlist`、`pairing`、`disabled` (預設：`open`) |
| `WEIXIN_GROUP_POLICY` | 群組訊息策略：`open`、`allowlist`、`disabled` (預設：`disabled`) |
| `WEIXIN_ALLOWED_USERS` | 允許私訊機器人的以逗號分隔的微信使用者 ID |
| `WEIXIN_GROUP_ALLOWED_USERS` | 允許與機器人互動的以逗號分隔的微信群組 ID |
| `WEIXIN_HOME_CHANNEL` | 用於 cron 傳送和通知的微信聊天 ID |
| `WEIXIN_HOME_CHANNEL_NAME` | 微信 Home 頻道的顯示名稱 |
| `WEIXIN_ALLOW_ALL_USERS` | 無需允許列表即可讓所有微信使用者存取 (`true`/`false`) |
| `BLUEBUBBLES_SERVER_URL` | BlueBubbles 伺服器網址 (例如 `http://192.168.1.10:1234`) |
| `BLUEBUBBLES_PASSWORD` | BlueBubbles 伺服器密碼 |
| `BLUEBUBBLES_WEBHOOK_HOST` | Webhook 監聽器綁定位址 (預設：`127.0.0.1`) |
| `BLUEBUBBLES_WEBHOOK_PORT` | Webhook 監聽器埠號 (預設：`8645`) |
| `BLUEBUBBLES_HOME_CHANNEL` | 用於 cron/通知傳送的電話/郵件 |
| `BLUEBUBBLES_ALLOWED_USERS` | 以逗號分隔的授權使用者 |
| `BLUEBUBBLES_ALLOW_ALL_USERS` | 允許所有使用者 (`true`/`false`) |
| `QQ_APP_ID` | 來自 [q.qq.com](https://q.qq.com) 的 QQ 機器人 App ID |
| `QQ_CLIENT_SECRET` | QQ 機器人 App Secret |
| `QQ_STT_API_KEY` | 外部 STT 備援提供商的 API 金鑰 (選配，用於 QQ 內建 ASR 未回傳文字時) |
| `QQ_STT_BASE_URL` | 外部 STT 提供商的基本 URL (選配) |
| `QQ_STT_MODEL` | 外部 STT 提供商的模型名稱 (選配) |
| `QQ_ALLOWED_USERS` | 允許給機器人發送訊息的以逗號分隔的 QQ 使用者 openID |
| `QQ_GROUP_ALLOWED_USERS` | 具備群組 @訊息存取權限的以逗號分隔的 QQ 群組 ID |
| `QQ_ALLOW_ALL_USERS` | 允許所有使用者 (`true`/`false`，會覆蓋 `QQ_ALLOWED_USERS`) |
| `QQ_HOME_CHANNEL` | 用於 cron 傳送和通知的 QQ 使用者/群組 openID |
| `MATTERMOST_URL` | Mattermost 伺服器網址 (例如 `https://mm.example.com`) |
| `MATTERMOST_TOKEN` | Mattermost 的機器人權杖或個人存取權杖 |
| `MATTERMOST_ALLOWED_USERS` | 允許給機器人發送訊息的以逗號分隔的 Mattermost 使用者 ID |
| `MATTERMOST_HOME_CHANNEL` | 用於主動訊息傳送 (cron, 通知) 的頻道 ID |
| `MATTERMOST_REQUIRE_MENTION` | 在頻道中需要 `@提及` (預設：`true`)。設為 `false` 以回應所有訊息。 |
| `MATTERMOST_FREE_RESPONSE_CHANNELS` | 機器人不需要 `@提及` 即可回應的以逗號分隔的頻道 ID |
| `MATTERMOST_REPLY_MODE` | 回覆風格：`thread` (討論串回覆) 或 `off` (扁平訊息，預設) |
| `MATRIX_HOMESERVER` | Matrix homeserver 網址 (例如 `https://matrix.org`) |
| `MATRIX_ACCESS_TOKEN` | 用於機器人驗證的 Matrix 存取權杖 |
| `MATRIX_USER_ID` | Matrix 使用者 ID (例如 `@hermes:matrix.org`) — 密碼登入必需，存取權杖登入選填 |
| `MATRIX_PASSWORD` | Matrix 密碼 (存取權杖的替代方案) |
| `MATRIX_ALLOWED_USERS` | 允許給機器人發送訊息的以逗號分隔的 Matrix 使用者 ID (例如 `@alice:matrix.org`) |
| `MATRIX_HOME_ROOM` | 用於主動訊息傳送的聊天室 ID (例如 `!abc123:matrix.org`) |
| `MATRIX_ENCRYPTION` | 啟用端對端加密 (`true`/`false`，預設：`false`) |
| `MATRIX_REQUIRE_MENTION` | 在聊天室中需要 `@提及` (預設：`true`)。設為 `false` 以回應所有訊息。 |
| `MATRIX_FREE_RESPONSE_ROOMS` | 機器人不需要 `@提及` 即可回應的以逗號分隔的聊天室 ID |
| `MATRIX_AUTO_THREAD` | 自動為聊天室訊息建立討論串 (預設：`true`) |
| `MATRIX_DM_MENTION_THREADS` | 當機器人在私訊中被 `@提及` 時建立討論串 (預設：`false`) |
| `MATRIX_RECOVERY_KEY` | 在裝置金鑰輪換後用於交叉簽名驗證的恢復金鑰。建議用於啟用了交叉簽名的 E2EE 設定。 |
| `HASS_TOKEN` | Home Assistant 長期存取權杖 (啟用 HA 平台 + 工具) |
| `HASS_URL` | Home Assistant 網址 (預設：`http://homeassistant.local:8123`) |
| `WEBHOOK_ENABLED` | 啟用 Webhook 平台適配器 (`true`/`false`) |
| `WEBHOOK_PORT` | 接收 Webhook 的 HTTP 伺服器埠號 (預設：`8644`) |
| `WEBHOOK_SECRET` | Webhook 簽章驗證的全域 HMAC 秘密金鑰 (當路由未指定自己的金鑰時用作備援) |
| `API_SERVER_ENABLED` | 啟用 OpenAI 相容的 API 伺服器 (`true`/`false`)。與其他平台併行運行。 |
| `API_SERVER_KEY` | API 伺服器驗證的 Bearer 權杖。非 loopback 綁定時強制執行。 |
| `API_SERVER_CORS_ORIGINS` | 允許直接呼叫 API 伺服器的以逗號分隔的瀏覽器來源 (例如 `http://localhost:3000,http://127.0.0.1:3000`)。預設：停用。 |
| `API_SERVER_PORT` | API 伺服器埠號 (預設：`8642`) |
| `API_SERVER_HOST` | API 伺服器主機/綁定位址 (預設：`127.0.0.1`)。使用 `0.0.0.0` 以開放網路存取 — 需設定 `API_SERVER_KEY` 並搭配嚴格的 `API_SERVER_CORS_ORIGINS` 允許列表。 |
| `API_SERVER_MODEL_NAME` | 在 `/v1/models` 公開的模型名稱。預設為設定檔名稱 (預設設定檔為 `hermes-agent`)。對多使用者設定非常有用，如 Open WebUI 這種前端需要為每個連接設定不同模型名稱。 |
| `GATEWAY_PROXY_URL` | 用於轉發訊息的遠端 Hermes API 伺服器網址 ([代理模式](/docs/user-guide/messaging/matrix#proxy-mode-e2ee-on-macos))。設定後，網關僅處理平台 I/O — 所有代理工作都委託給遠端伺服器。亦可在 `config.yaml` 的 `gateway.proxy_url` 中設定。 |
| `GATEWAY_PROXY_KEY` | 在代理模式下與遠端 API 伺服器驗證的 Bearer 權杖。必須與遠端主機上的 `API_SERVER_KEY` 一致。 |
| `MESSAGING_CWD` | 即時通訊模式下終端機指令的工作目錄 (預設：`~`) |
| `GATEWAY_ALLOWED_USERS` | 允許跨平台存取的以逗號分隔的使用者 ID |
| `GATEWAY_ALLOW_ALL_USERS` | 在無允許列表的情況下讓所有使用者存取 (`true`/`false`，預設：`false`) |

## 代理行為

| 變數 | 描述 |
|----------|-------------|
| `HERMES_MAX_ITERATIONS` | 每輪對話的最大工具呼叫迭代次數 (預設：90) |
| `HERMES_TOOL_PROGRESS` | 已棄用的工具進度顯示變數。請偏好使用 `config.yaml` 中的 `display.tool_progress`。 |
| `HERMES_TOOL_PROGRESS_MODE` | 已棄用的工具進度模式變數。請偏好使用 `config.yaml` 中的 `display.tool_progress`。 |
| `HERMES_HUMAN_DELAY_MODE` | 回應節奏：`off`/`natural`/`custom` |
| `HERMES_HUMAN_DELAY_MIN_MS` | 自定義延遲範圍最小值 (ms) |
| `HERMES_HUMAN_DELAY_MAX_MS` | 自定義延遲範圍最大值 (ms) |
| `HERMES_QUIET` | 隱藏非必要輸出 (`true`/`false`) |
| `HERMES_API_TIMEOUT` | LLM API 呼叫超時時間 (秒) (預設：`1800`) |
| `HERMES_STREAM_READ_TIMEOUT` | 串流 Socket 讀取超時時間 (秒) (預設：`120`)。針對在地提供商會自動增加至 `HERMES_API_TIMEOUT`。若在地 LLM 在長代碼生成時超時，請調高此值。 |
| `HERMES_STREAM_STALE_TIMEOUT` | 串流失效偵測超時時間 (秒) (預設：`180`)。針對在地提供商會自動停用。若在此時間內無任何 chunk 抵達，將觸發連線中斷。 |
| `HERMES_EXEC_ASK` | 在網關模式下啟用執行核准提示 (`true`/`false`) |
| `HERMES_ENABLE_PROJECT_PLUGINS` | 啟用從 `./.hermes/plugins/` 自動偵測儲存庫在地外掛程式 (`true`/`false`, 預設：`false`) |
| `HERMES_BACKGROUND_NOTIFICATIONS` | 網關中的背景程序通知模式：`all` (預設), `result`, `error`, `off` |
| `HERMES_EPHEMERAL_SYSTEM_PROMPT` | 在 API 呼叫時注入的臨時系統提示詞 (絕不會持久化到工作階段中) |

## Cron 排程器

| 變數 | 描述 |
|----------|-------------|
| `HERMES_CRON_TIMEOUT` | cron 任務代理運行的閒置超時時間 (秒) (預設：`600`)。當代理正在呼叫工具或接收串流權杖時可以無限期運行 — 此項僅在閒置時觸發。設為 `0` 則不限時。 |
| `HERMES_CRON_SCRIPT_TIMEOUT` | 附加到 cron 任務的執行前腳本超時時間 (秒) (預設：`120`)。針對需要較長執行時間的腳本進行覆蓋 (例如為了避開機器人偵測而設定的隨機延遲)。亦可在 `config.yaml` 的 `cron.script_timeout_seconds` 中設定。 |

## 工作階段設定

| 變數 | 描述 |
|----------|-------------|
| `SESSION_IDLE_MINUTES` | 閒置 N 分鐘後重設工作階段 (預設：1440) |
| `SESSION_RESET_HOUR` | 每日重設小時，採 24 小時制 (預設：4 = 凌晨 4 點) |

## 上下文壓縮 (僅限 config.yaml)

上下文壓縮僅透過 `config.yaml` 進行配置 — 沒有對應的環境變數。閾值設定位於 `compression:` 區塊，而摘要模型/提供商位於 `auxiliary.compression:` 之下。

```yaml
compression:
  enabled: true
  threshold: 0.50
  target_ratio: 0.20         # 保留作為近期尾部的閾值比例
  protect_last_n: 20         # 保持不壓縮的最近訊息最小數量
```

:::info 舊版遷移
帶有 `compression.summary_model`, `compression.summary_provider` 和 `compression.summary_base_url` 的舊版配置在首次載入時會自動遷移到 `auxiliary.compression.*`。
:::

## 輔助任務覆蓋

| 變數 | 描述 |
|----------|-------------|
| `AUXILIARY_VISION_PROVIDER` | 覆蓋視覺任務的提供商 |
| `AUXILIARY_VISION_MODEL` | 覆蓋視覺任務的模型 |
| `AUXILIARY_VISION_BASE_URL` | 用於視覺任務的直接 OpenAI 相容端點 |
| `AUXILIARY_VISION_API_KEY` | 與 `AUXILIARY_VISION_BASE_URL` 配對的 API 金鑰 |
| `AUXILIARY_WEB_EXTRACT_PROVIDER` | 覆蓋網頁擷取/摘要任務的提供商 |
| `AUXILIARY_WEB_EXTRACT_MODEL` | 覆蓋網頁擷取/摘要任務的模型 |
| `AUXILIARY_WEB_EXTRACT_BASE_URL` | 用於網頁擷取/摘要任務的直接 OpenAI 相容端點 |
| `AUXILIARY_WEB_EXTRACT_API_KEY` | 與 `AUXILIARY_WEB_EXTRACT_BASE_URL` 配對的 API 金鑰 |

對於特定任務的直接端點，Hermes 會使用該任務配置的 API 金鑰或 `OPENAI_API_KEY`。它不會將 `OPENROUTER_API_KEY` 用於這些自定義端點。

## 備用模型 (僅限 config.yaml)

主模型備用機制僅透過 `config.yaml` 配置 — 沒有對應的環境變數。添加包含 `provider` 和 `model` 鍵值的 `fallback_model` 區段，以便在主模型遇到錯誤時啟用自動備援。

```yaml
fallback_model:
  provider: openrouter
  model: anthropic/claude-sonnet-4
```

詳情請參閱 [備用提供商](/docs/user-guide/features/fallback-providers)。

## 提供商路由 (僅限 config.yaml)

這些設定位於 `~/.hermes/config.yaml` 的 `provider_routing` 區段下：

| 鍵名 | 描述 |
|-----|-------------|
| `sort` | 提供商排序方式：`"price"` (預設)、`"throughput"` 或 `"latency"` |
| `only` | 允許的提供商簡稱列表 (例如 `["anthropic", "google"]`) |
| `ignore` | 要跳過的提供商簡稱列表 |
| `order` | 要依序嘗試的提供商簡稱列表 |
| `require_parameters` | 僅使用支援所有請求參數的提供商 (`true`/`false`) |
| `data_collection` | `"allow"` (預設) 或 `"deny"` 以排除儲存數據的提供商 |

:::tip
使用 `hermes config set` 來設定環境變數 — 它會自動將它們儲存在正確的檔案中 (`.env` 存放秘密資訊，`config.yaml` 存放其他所有內容)。
:::
