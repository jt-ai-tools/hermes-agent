# BlueBubbles (iMessage)

透過 [BlueBubbles](https://bluebubbles.app/) 將 Hermes 連接到 Apple iMessage — 這是一個免費且開源的 macOS 伺服器，可將 iMessage 橋接到任何裝置。

## 前提條件

- 一台運行 [BlueBubbles Server](https://bluebubbles.app/) 的 **Mac**（需保持開機狀態）
- 該 Mac 上的「訊息.app」已登入 Apple ID
- BlueBubbles Server v1.0.0+（Webhook 需要此版本）
- Hermes 與 BlueBubbles 伺服器之間的網路連線

## 設定

### 1. 安裝 BlueBubbles Server

從 [bluebubbles.app](https://bluebubbles.app/) 下載並安裝。完成設定精靈 — 使用您的 Apple ID 登入並設定連線方式（區域網路、Ngrok、Cloudflare 或動態 DNS）。

### 2. 獲取您的伺服器 URL 和密碼

在 BlueBubbles Server → **Settings → API** 中，記下：
- **伺服器 URL**（例如 `http://192.168.1.10:1234`）
- **伺服器密碼**

### 3. 設定 Hermes

執行設定精靈：

```bash
hermes gateway setup
```

選擇 **BlueBubbles (iMessage)** 並輸入您的伺服器 URL 和密碼。

或者直接在 `~/.hermes/.env` 中設定環境變數：

```bash
BLUEBUBBLES_SERVER_URL=http://192.168.1.10:1234
BLUEBUBBLES_PASSWORD=your-server-password
```

### 4. 授權使用者

選擇一種方式：

**私訊配對（推薦）：**
當有人傳送 iMessage 給您時，Hermes 會自動傳送配對碼給他們。使用以下指令核准：
```bash
hermes pairing approve bluebubbles <CODE>
```
使用 `hermes pairing list` 查看待處理的配對碼和已核准的使用者。

**預先授權特定使用者**（在 `~/.hermes/.env` 中）：
```bash
BLUEBUBBLES_ALLOWED_USERS=user@icloud.com,+15551234567
```

**開放存取**（在 `~/.hermes/.env` 中）：
```bash
BLUEBUBBLES_ALLOW_ALL_USERS=true
```

### 5. 啟動網關

```bash
hermes gateway run
```

Hermes 將連線到您的 BlueBubbles 伺服器，註冊 Webhook，並開始監聽 iMessage 訊息。

## 運作原理

```
iMessage → 訊息.app → BlueBubbles Server → Webhook → Hermes
Hermes → BlueBubbles REST API → 訊息.app → iMessage
```

- **入站 (Inbound)：** 當有新訊息到達時，BlueBubbles 會傳送 Webhook 事件給本地監聽器。無需輪詢 — 即時傳送。
- **出站 (Outbound)：** Hermes 透過 BlueBubbles REST API 傳送訊息。
- **媒體：** 雙向支援圖片、語音訊息、影片和文件。入站附件會被下載並快取在本地，供代理 (Agent) 處理。

## 環境變數

| 變數 | 必填 | 預設值 | 描述 |
|----------|----------|---------|-------------|
| `BLUEBUBBLES_SERVER_URL` | 是 | — | BlueBubbles 伺服器 URL |
| `BLUEBUBBLES_PASSWORD` | 是 | — | 伺服器密碼 |
| `BLUEBUBBLES_WEBHOOK_HOST` | 否 | `127.0.0.1` | Webhook 監聽器繫結位址 |
| `BLUEBUBBLES_WEBHOOK_PORT` | 否 | `8645` | Webhook 監聽器連接埠 |
| `BLUEBUBBLES_WEBHOOK_PATH` | 否 | `/bluebubbles-webhook` | Webhook URL 路徑 |
| `BLUEBUBBLES_HOME_CHANNEL` | 否 | — | 用於 Cron 傳遞的電話/電子郵件 |
| `BLUEBUBBLES_ALLOWED_USERS` | 否 | — | 以逗號分隔的授權使用者清單 |
| `BLUEBUBBLES_ALLOW_ALL_USERS` | 否 | `false` | 允許所有使用者 |
| `BLUEBUBBLES_SEND_READ_RECEIPTS` | 否 | `true` | 自動將訊息標記為已讀 |

## 功能

### 文字訊息
傳送和接收 iMessage。Markdown 語法會自動清除，以實現純文字傳遞。

### 豐富媒體
- **圖片：** 照片會原生顯示在 iMessage 對話中
- **語音訊息：** 音訊檔案會以 iMessage 語音訊息形式傳送
- **影片：** 影片附件
- **文件：** 檔案以 iMessage 附件形式傳送

### Tapback 回應
喜愛、讚、不喜歡、笑、強調和問題回應。需要 BlueBubbles [Private API 輔助程式](https://docs.bluebubbles.app/helper-bundle/installation)。

### 輸入狀態指示器
當代理正在處理時，在 iMessage 對話中顯示「正在輸入...」。需要 Private API。

### 已讀標記
處理後自動將訊息標記為已讀。需要 Private API。

### 對話位址解析
您可以透過電子郵件或電話號碼指定對話 — Hermes 會自動將其解析為 BlueBubbles 對話 GUID。無需使用原始 GUID 格式。

## Private API

某些功能需要 BlueBubbles [Private API 輔助程式](https://docs.bluebubbles.app/helper-bundle/installation)：
- Tapback 回應
- 輸入狀態指示器
- 已讀標記
- 透過位址建立新對話

如果沒有 Private API，基本文字訊息和媒體功能仍可運作。

## 疑難排解

### 「無法連線到伺服器」
- 驗證伺服器 URL 是否正確，且 Mac 已開機
- 檢查 BlueBubbles Server 是否正在執行
- 確保網路連線正常（防火牆、連接埠轉發）

### 訊息未送達
- 檢查 Webhook 是否已在 BlueBubbles Server → Settings → API → Webhooks 中註冊
- 驗證從 Mac 可以存取 Webhook URL
- 檢查 `hermes logs gateway` 是否有 Webhook 錯誤（或使用 `hermes logs -f` 即時追蹤）

### 「Private API 輔助程式未連線」
- 安裝 Private API 輔助程式：[docs.bluebubbles.app](https://docs.bluebubbles.app/helper-bundle/installation)
- 基本訊息功能在沒有它的情況下仍可運作 — 只有回應、輸入狀態和已讀標記需要它
