---
sidebar_position: 8
sidebar_label: "SMS (Twilio)"
title: "SMS (Twilio)"
description: "透過 Twilio 將 Hermes Agent 設定為 SMS 對話機器人"
---

# SMS 設定 (Twilio)

Hermes 透過 [Twilio](https://www.twilio.com/) API 連接到 SMS。人們可以傳送簡訊到您的 Twilio 電話號碼並獲得 AI 的回覆 —— 就像使用 Telegram 或 Discord 一樣的對話體驗，但使用的是標準簡訊。

:::info 共享憑證
SMS 閘道與選用的 [電話技能 (Telephony Skill)](/docs/reference/skills-catalog) 共享憑證。如果您已經為語音通話或單次簡訊設定了 Twilio，閘道可以使用相同的 `TWILIO_ACCOUNT_SID`、`TWILIO_AUTH_TOKEN` 和 `TWILIO_PHONE_NUMBER`。
:::

---

## 前置作業

- **Twilio 帳戶** — 在 [twilio.com 註冊](https://www.twilio.com/try-twilio) (提供免費試用)
- **具備 SMS 功能的 Twilio 電話號碼**
- **一個可公開存取的伺服器** — 當簡訊到達時，Twilio 會發送 Webhook 到您的伺服器
- **aiohttp** — `pip install 'hermes-agent[sms]'`

---

## 步驟 1：取得您的 Twilio 憑證

1. 前往 [Twilio 控制台 (Console)](https://console.twilio.com/)
2. 從儀表板複製您的 **Account SID** 和 **Auth Token**
3. 前往 **Phone Numbers → Manage → Active Numbers** — 記下您的電話號碼，格式需為 E.164 (例如 `+15551234567`)

---

## 步驟 2：設定 Hermes

### 互動式設定 (推薦)

```bash
hermes gateway setup
```

從平台清單中選擇 **SMS (Twilio)**。設定精靈將提示您輸入憑證。

### 手動設定

在 `~/.hermes/.env` 中加入：

```bash
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+15551234567

# 安全性：限制特定的電話號碼 (推薦)
SMS_ALLOWED_USERS=+15559876543,+15551112222

# 選填：設定排程任務的預設傳送目標
SMS_HOME_CHANNEL=+15559876543
```

---

## 步驟 3：設定 Twilio Webhook

Twilio 需要知道要將傳入訊息發送到哪裡。在 [Twilio 控制台](https://console.twilio.com/)中：

1. 前往 **Phone Numbers → Manage → Active Numbers**
2. 點擊您的電話號碼
3. 在 **Messaging → A MESSAGE COMES IN** 下，設定：
   - **Webhook**: `https://your-server:8080/webhooks/twilio`
   - **HTTP Method**: `POST`

:::tip 公開您的 Webhook
如果您在本地執行 Hermes，請使用隧道 (tunnel) 來公開 Webhook：

```bash
# 使用 cloudflared
cloudflared tunnel --url http://localhost:8080

# 使用 ngrok
ngrok http 8080
```

將產生的公開網址設定為您的 Twilio Webhook。
:::

**將 `SMS_WEBHOOK_URL` 設定為您在 Twilio 中配置的相同網址。** 這是 Twilio 簽章驗證所必需的 —— 若未設定，適配器將拒絕啟動：

```bash
# 必須與您的 Twilio 控制台中的 Webhook 網址一致
SMS_WEBHOOK_URL=https://your-server:8080/webhooks/twilio
```

Webhook 埠號預設為 `8080`。若要覆寫請設定：

```bash
SMS_WEBHOOK_PORT=3000
```

---

## 步驟 4：啟動閘道

```bash
hermes gateway
```

您應該會看到：

```
[sms] Twilio webhook server listening on 0.0.0.0:8080, from: +1555***4567
```

如果您看到 `Refusing to start: SMS_WEBHOOK_URL is required`，請將 `SMS_WEBHOOK_URL` 設定為您在 Twilio 控制台中配置的公開網址 (參見步驟 3)。

傳送簡訊到您的 Twilio 號碼 —— Hermes 將透過簡訊回覆。

---

## 環境變數

| 變數 | 必填 | 描述 |
|----------|----------|-------------|
| `TWILIO_ACCOUNT_SID` | 是 | Twilio 帳戶 SID (以 `AC` 開頭) |
| `TWILIO_AUTH_TOKEN` | 是 | Twilio 驗證權杖 (亦用於 Webhook 簽章驗證) |
| `TWILIO_PHONE_NUMBER` | 是 | 您的 Twilio 電話號碼 (E.164 格式) |
| `SMS_WEBHOOK_URL` | 是 | 用於 Twilio 簽章驗證的公開網址 —— 必須與 Twilio 控制台中的 Webhook 網址一致 |
| `SMS_WEBHOOK_PORT` | 否 | Webhook 監聽埠號 (預設：`8080`) |
| `SMS_WEBHOOK_HOST` | 否 | Webhook 綁定位址 (預設：`0.0.0.0`) |
| `SMS_INSECURE_NO_SIGNATURE` | 否 | 設為 `true` 以停用簽章驗證 (僅限本地開發 —— **不可用於正式環境**) |
| `SMS_ALLOWED_USERS` | 否 | 以逗號分隔的 E.164 電話號碼，允許其進行對話 |
| `SMS_ALLOW_ALL_USERS` | 否 | 設為 `true` 以允許任何人 (不推薦) |
| `SMS_HOME_CHANNEL` | 否 | 用於排程任務 / 通知發送的電話號碼 |
| `SMS_HOME_CHANNEL_NAME` | 否 | 主頻道的顯示名稱 (預設：`Home`) |

---

## SMS 特定行為

- **僅限純文字** — Markdown 會被自動移除，因為 SMS 會將其渲染為字面字元
- **1600 字元限制** — 較長的回應會在自然邊界 (換行符，然後是空格) 處拆分為多則訊息
- **回音防止 (Echo Prevention)** — 來自您自己 Twilio 號碼的訊息會被忽略，以防止無限迴圈
- **電話號碼遮蔽** — 電話號碼在日誌中會被遮蔽以保護隱私

---

## 安全性

### Webhook 簽章驗證

Hermes 會透過驗證 `X-Twilio-Signature` 標頭 (HMAC-SHA1) 來確認傳入的 Webhook 確實來自 Twilio。這可以防止攻擊者發送偽造的訊息。

**必須設定 `SMS_WEBHOOK_URL`。** 請將其設定為您在 Twilio 控制台中配置的公開網址。若未設定，適配器將拒絕啟動。

若是在沒有公開網址的本地開發環境，您可以停用驗證：

```bash
# 僅限本地開發 —— 不可用於正式環境
SMS_INSECURE_NO_SIGNATURE=true
```

### 使用者白名單

**閘道預設會拒絕所有使用者。** 請設定白名單：

```bash
# 推薦：限制特定的電話號碼
SMS_ALLOWED_USERS=+15559876543,+15551112222

# 或允許所有人 (對於具有終端機存取權的機器人，不推薦此項)
SMS_ALLOW_ALL_USERS=true
```

:::warning
SMS 沒有內建加密功能。除非您了解其安全性影響，否則請勿將 SMS 用於敏感操作。對於敏感案例，建議優先使用 Signal 或 Telegram。
:::

---

## 疑難排解

### 訊息未送達

1. 檢查您的 Twilio Webhook 網址是否正確且可從公開網路存取
2. 確認 `TWILIO_ACCOUNT_SID` 和 `TWILIO_AUTH_TOKEN` 正確無誤
3. 查看 Twilio 控制台 → **Monitor → Logs → Messaging** 以獲取傳送錯誤資訊
4. 確保您的電話號碼已列在 `SMS_ALLOWED_USERS` 中 (或 `SMS_ALLOW_ALL_USERS=true`)

### 回覆未發送

1. 檢查 `TWILIO_PHONE_NUMBER` 設定是否正確 (E.164 格式，含 `+`)
2. 確認您的 Twilio 帳戶擁有具備 SMS 功能的號碼
3. 檢查 Hermes 閘道日誌中的 Twilio API 錯誤資訊

### Webhook 埠號衝突

如果埠號 8080 已被佔用，請更改埠號：

```bash
SMS_WEBHOOK_PORT=3001
```

並同步更新 Twilio 控制台中的 Webhook 網址。
