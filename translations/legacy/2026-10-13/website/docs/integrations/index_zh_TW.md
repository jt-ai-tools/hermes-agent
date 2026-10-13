---
title: "整合"
sidebar_label: "概覽"
sidebar_position: 0
---

# 整合

Hermes Agent 可以連接到外部系統以進行 AI 推論、工具伺服器、IDE 工作流、程式化存取等。這些整合擴展了 Hermes 的功能以及它可以運行的環境。

## AI 提供商與路由

Hermes 開箱即支援多個 AI 推論提供商。使用 `hermes model` 進行互動式配置，或在 `config.yaml` 中進行設定。

- **[AI 提供商](/docs/user-guide/features/provider-routing)** — 支援 OpenRouter、Anthropic、OpenAI、Google 以及任何相容於 OpenAI 的端點。Hermes 會自動偵測每個提供商的功能，如視覺、串流和工具使用。
- **[提供商路由](/docs/user-guide/features/provider-routing)** — 對處理您 OpenRouter 請求的底層提供商進行細粒度控制。透過排序、白名單、黑名單和明確的優先級順序，針對成本、速度或品質進行優化。
- **[備用提供商](/docs/user-guide/features/fallback-providers)** — 當您的主模型遇到錯誤時，自動切換到備用 LLM 提供商。包括主模型備援以及針對視覺、壓縮和網頁擷取的獨立輔助任務備援。

## 工具伺服器 (MCP)

- **[MCP 伺服器](/docs/user-guide/features/mcp)** — 透過模型上下文協定 (Model Context Protocol) 將 Hermes 連接到外部工具伺服器。無需編寫原生 Hermes 工具即可存取來自 GitHub、資料庫、檔案系統、瀏覽器堆疊、內部 API 等的工具。支援 stdio 和 SSE 傳輸、按伺服器過濾工具，以及具備功能感知能力的資源/提示詞註冊。

## 網頁搜尋後端

`web_search` 和 `web_extract` 工具支援四種後端提供商，可透過 `config.yaml` 或 `hermes tools` 配置：

| 後端 | 環境變數 | 搜尋 | 擷取 | 爬取 |
|---------|---------|--------|---------|-------|
| **Firecrawl** (預設) | `FIRECRAWL_API_KEY` | ✔ | ✔ | ✔ |
| **Parallel** | `PARALLEL_API_KEY` | ✔ | ✔ | — |
| **Tavily** | `TAVILY_API_KEY` | ✔ | ✔ | ✔ |
| **Exa** | `EXA_API_KEY` | ✔ | ✔ | — |

快速設定範例：

```yaml
web:
  backend: firecrawl    # firecrawl | parallel | tavily | exa
```

如果未設定 `web.backend`，後端將根據可用的 API 金鑰自動偵測。也支援透過 `FIRECRAWL_API_URL` 使用自代管的 Firecrawl。

## 瀏覽器自動化

Hermes 包含完整的瀏覽器自動化功能，並有多種後端選項，可用於瀏覽網站、填寫表單和擷取資訊：

- **Browserbase** — 具備反機器人工具、驗證碼 (CAPTCHA) 破解和住宅代理功能的託管雲端瀏覽器
- **Browser Use** — 替代的雲端瀏覽器提供商
- **透過 CDP 的在地 Chrome** — 使用 `/browser connect` 連接到您正在運行的 Chrome 實例
- **在地 Chromium** — 透過 `agent-browser` CLI 使用無頭 (Headless) 在地瀏覽器

請參閱 [瀏覽器自動化](/docs/user-guide/features/browser) 以瞭解設定和用法。

## 語音與 TTS 提供商

支援所有即時通訊平台的文字轉語音 (TTS) 和語音轉文字：

| 提供商 | 品質 | 成本 | API 金鑰 |
||----------|---------|------|---------|
|| **Edge TTS** (預設) | 良好 | 免費 | 無需 |
|| **ElevenLabs** | 優異 | 付費 | `ELEVENLABS_API_KEY` |
|| **OpenAI TTS** | 良好 | 付費 | `VOICE_TOOLS_OPENAI_KEY` |
|| **MiniMax** | 良好 | 付費 | `MINIMAX_API_KEY` |
|| **NeuTTS** | 良好 | 免費 | 無需 |

語音轉文字支援三種提供商：在地 Whisper (免費，在裝置上運行)、Groq (快速雲端) 和 OpenAI Whisper API。語音訊息轉錄適用於 Telegram、Discord、WhatsApp 和其他通訊平台。詳情請參閱 [語音與 TTS](/docs/user-guide/features/tts) 和 [語音模式](/docs/user-guide/features/voice-mode)。

## IDE 與編輯器整合

- **[IDE 整合 (ACP)](/docs/user-guide/features/acp)** — 在 VS Code、Zed 和 JetBrains 等相容 ACP 的編輯器中使用 Hermes Agent。Hermes 作為 ACP 伺服器運行，在您的編輯器內渲染聊天訊息、工具活動、檔案差異 (diff) 和終端機指令。

## 程式化存取

- **[API 伺服器](/docs/user-guide/features/api-server)** — 將 Hermes 作為相容 OpenAI 的 HTTP 端點公開。任何支援 OpenAI 格式的前端（如 Open WebUI、LobeChat、LibreChat、NextChat、ChatBox）都可以連接並使用 Hermes 作為帶有完整工具集的後端。

## 記憶與個人化

- **[內建記憶](/docs/user-guide/features/memory)** — 透過 `MEMORY.md` 和 `USER.md` 檔案實現持久化、精選的記憶。代理維護有限範圍的個人筆記和使用者個人資料數據，可跨工作階段保留。
- **[記憶提供商](/docs/user-guide/features/memory-providers)** — 插入外部記憶後端以實現更深層次的個人化。支援七種提供商：Honcho (辯證推理)、OpenViking (分層檢索)、Mem0 (雲端擷取)、Hindsight (知識圖譜)、Holographic (在地 SQLite)、RetainDB (混合搜尋) 和 ByteRover (基於 CLI)。

## 即時通訊平台

Hermes 作為網關機器人運行在超過 15 個通訊平台上，全部透過同一個 `gateway` 子系統配置：

- **[Telegram](/docs/user-guide/messaging/telegram)**, **[Discord](/docs/user-guide/messaging/discord)**, **[Slack](/docs/user-guide/messaging/slack)**, **[WhatsApp](/docs/user-guide/messaging/whatsapp)**, **[Signal](/docs/user-guide/messaging/signal)**, **[Matrix](/docs/user-guide/messaging/matrix)**, **[Mattermost](/docs/user-guide/messaging/mattermost)**, **[Email](/docs/user-guide/messaging/email)**, **[SMS](/docs/user-guide/messaging/sms)**, **[DingTalk (釘釘)](/docs/user-guide/messaging/dingtalk)**, **[Feishu/Lark (飛書)](/docs/user-guide/messaging/feishu)**, **[WeCom (企業微信)](/docs/user-guide/messaging/wecom)**, **[WeCom Callback](/docs/user-guide/messaging/wecom-callback)**, **[Weixin (微信)](/docs/user-guide/messaging/weixin)**, **[BlueBubbles](/docs/user-guide/messaging/bluebubbles)**, **[QQ Bot](/docs/user-guide/messaging/qqbot)**, **[Home Assistant](/docs/user-guide/messaging/homeassistant)**, **[Webhooks](/docs/user-guide/messaging/webhooks)**

請參閱 [即時通訊網關概覽](/docs/user-guide/messaging) 以查看平台比較表和設定指南。

## 家庭自動化

- **[Home Assistant](/docs/user-guide/messaging/homeassistant)** — 透過四個專用工具 (`ha_list_entities`、`ha_get_state`、`ha_list_services`、`ha_call_service`) 控制智慧家庭裝置。當配置 `HASS_TOKEN` 後，Home Assistant 工具集會自動啟動。

## 外掛程式

- **[外掛系統](/docs/user-guide/features/plugins)** — 使用自定義工具、生命週期鉤子 (hooks) 和 CLI 指令擴展 Hermes，而無需修改核心代碼。外掛程式可從 `~/.hermes/plugins/`、專案在地的 `.hermes/plugins/` 和透過 pip 安裝的入口點中被偵測到。
- **[建立外掛程式](/docs/guides/build-a-hermes-plugin)** — 建立帶有工具、鉤子和 CLI 指令的 Hermes 外掛程式的逐步指南。

## 訓練與評估

- **[RL 訓練](/docs/user-guide/features/rl-training)** — 從代理工作階段生成軌跡數據，用於強化學習 (RL) 和模型微調。支援具有自定義獎勵函數的 Atropos 環境。
- **[批次處理](/docs/user-guide/features/batch-processing)** — 平行運行數百個提示詞，生成結構化的 ShareGPT 格式軌跡數據，用於訓練數據生成或評估。
