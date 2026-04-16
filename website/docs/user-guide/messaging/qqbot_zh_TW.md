# QQ 機器人

透過 **QQ 機器人官方 API (v2)** 將 Hermes 連接到 QQ —— 支援私聊 (C2C)、群組 @ 標註、頻道 (Guild) 以及具備語音轉文字功能的直接訊息。

## 概述

QQ 機器人適配器使用 [QQ 機器人官方 API](https://bot.q.qq.com/wiki/develop/api-v2/) 來：

- 透過與 QQ 閘道的持久性 **WebSocket** 連線接收訊息
- 透過 **REST API** 發送文字和 Markdown 回覆
- 下載並處理圖片、語音訊息和檔案附件
- 使用騰訊內建的 ASR 或可設定的 STT 提供者來轉錄語音訊息

## 前置作業

1. **QQ 機器人應用程式** —— 在 [q.qq.com](https://q.qq.com) 註冊：
   - 建立新的應用程式並記下您的 **App ID** 和 **App Secret**
   - 啟用必要的意圖 (Intents)：C2C 訊息、群組 @ 訊息、頻道訊息
   - 設定機器人為沙盒模式進行測試，或發佈以供正式環境使用

2. **依賴項目** —— 適配器需要 `aiohttp` 和 `httpx`：
   ```bash
   pip install aiohttp httpx
   ```

## 設定

### 互動式設定

```bash
hermes setup gateway
```

從平台列表中選擇 **QQ Bot**，並按照提示操作。

### 手動設定

在 `~/.hermes/.env` 中設定必要的環境變數：

```bash
QQ_APP_ID=your-app-id
QQ_CLIENT_SECRET=your-app-secret
```

## 環境變數

| 變數 | 描述 | 預設值 |
|---|---|---|
| `QQ_APP_ID` | QQ 機器人 App ID (必填) | — |
| `QQ_CLIENT_SECRET` | QQ 機器人 App Secret (必填) | — |
| `QQ_HOME_CHANNEL` | 用於排程任務/通知發送的 OpenID | — |
| `QQ_HOME_CHANNEL_NAME` | 主頻道的顯示名稱 | `Home` |
| `QQ_ALLOWED_USERS` | 以逗號分隔的私訊存取使用者 OpenID 列表 | 開放 (所有使用者) |
| `QQ_ALLOW_ALL_USERS` | 設為 `true` 以允許所有私訊 | `false` |
| `QQ_MARKDOWN_SUPPORT` | 啟用 QQ Markdown (msg_type 2) | `true` |
| `QQ_STT_API_KEY` | 語音轉文字提供者的 API 金鑰 | — |
| `QQ_STT_BASE_URL` | STT 提供者的基礎網址 | `https://open.bigmodel.cn/api/coding/paas/v4` |
| `QQ_STT_MODEL` | STT 模型名稱 | `glm-asr` |

## 進階設定

如需精細控制，請在 `~/.hermes/config.yaml` 中加入平台設定：

```yaml
platforms:
  qq:
    enabled: true
    extra:
      app_id: "your-app-id"
      client_secret: "your-secret"
      markdown_support: true
      dm_policy: "open"          # open | allowlist | disabled
      allow_from:
        - "user_openid_1"
      group_policy: "open"       # open | allowlist | disabled
      group_allow_from:
        - "group_openid_1"
      stt:
        provider: "zai"          # zai (GLM-ASR), openai (Whisper) 等
        baseUrl: "https://open.bigmodel.cn/api/coding/paas/v4"
        apiKey: "your-stt-key"
        model: "glm-asr"
```

## 語音訊息 (STT)

語音轉錄分為兩個階段：

1. **QQ 內建 ASR** (免費，一律先嘗試) —— QQ 在語音訊息附件中提供 `asr_refer_text`，這使用的是騰訊自己的語音辨識技術
2. **設定的 STT 提供者** (備援) —— 如果 QQ 的 ASR 沒有傳回文字，適配器會呼叫與 OpenAI 相容的 STT API：

   - **智譜/GLM (zai)**: 預設提供者，使用 `glm-asr` 模型
   - **OpenAI Whisper**: 設定 `QQ_STT_BASE_URL` 和 `QQ_STT_MODEL`
   - 任何與 OpenAI 相容的 STT 端點

## 疑難排解

### 機器人立即斷線 (Quick disconnect)

這通常意味著：
- **App ID / Secret 無效** —— 請再次檢查您在 q.qq.com 上的憑證
- **權限缺失** —— 確保機器人已啟用必要的意圖 (Intents)
- **僅限沙盒的機器人** —— 如果機器人處於沙盒模式，它只能接收來自 QQ 沙盒測試頻道的訊息

### 語音訊息未轉錄

1. 檢查附件資料中是否存在 QQ 內建的 `asr_refer_text`
2. 如果使用自訂 STT 提供者，請確認 `QQ_STT_API_KEY` 設定正確
3. 檢查閘道日誌中的 STT 錯誤訊息

### 訊息未送達

- 在 q.qq.com 驗證機器人的 **意圖 (Intents)** 是否已啟用
- 如果限制了私訊存取，請檢查 `QQ_ALLOWED_USERS`
- 對於群組訊息，確保機器人被 **@標註** (群組政策可能需要加入白名單)
- 檢查 `QQ_HOME_CHANNEL` 以用於排程任務/通知發送

### 連線錯誤

- 確保已安裝 `aiohttp` 和 `httpx`：`pip install aiohttp httpx`
- 檢查與 `api.sgroup.qq.com` 及 WebSocket 閘道的網路連線
- 查看閘道日誌以獲取詳細的錯誤訊息和重新連線行為
