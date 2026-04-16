---
sidebar_position: 7
title: "電子郵件 (Email)"
description: "透過 IMAP/SMTP 將 Hermes Agent 設定為電子郵件助理"
---

# 電子郵件 (Email) 設定

Hermes 可以使用標準的 IMAP 和 SMTP 協定接收和回覆電子郵件。向代理的位址傳送電子郵件，它就會在對話串中回覆 — 不需要特殊的用戶端或機器人 API。適用於 Gmail、Outlook、Yahoo、Fastmail 或任何支援 IMAP/SMTP 的提供商。

:::info 無外部依賴
電子郵件適配器使用 Python 內建的 `imaplib`、`smtplib` 和 `email` 模組。不需要額外的套件或外部服務。
:::

---

## 前提條件

- **一個專門用於 Hermes 代理的電子郵件帳號**（請勿使用您的個人電子郵件）
- 電子郵件帳號已**啟用 IMAP**
- 如果使用 Gmail 或其他具有雙重驗證 (2FA) 的提供商，則需要**應用程式密碼**

### Gmail 設定

1. 在您的 Google 帳號上啟用雙重驗證 (2FA)
2. 前往 [應用程式密碼](https://myaccount.google.com/apppasswords)
3. 建立一個新的應用程式密碼（選擇「郵件」或「其他」）
4. 複製 16 位元的密碼 — 您將使用此密碼代替一般密碼

### Outlook / Microsoft 365

1. 前往 [安全性設定](https://account.microsoft.com/security)
2. 如果尚未啟用，請啟用 2FA
3. 在「其他安全性選項」下建立應用程式密碼
4. IMAP 主機：`outlook.office365.com`，SMTP 主機：`smtp.office365.com`

### 其他提供商

大多數電子郵件提供商都支援 IMAP/SMTP。請查看您提供商的文件以獲取：
- IMAP 主機和連接埠（通常是連接埠 993 搭配 SSL）
- SMTP 主機和連接埠（通常是連接埠 587 搭配 STARTTLS）
- 是否需要應用程式密碼

---

## 步驟 1：設定 Hermes

最簡單的方法：

```bash
hermes gateway setup
```

從平台選單中選擇 **Email**。精靈會提示您輸入電子郵件位址、密碼、IMAP/SMTP 主機以及允許的寄件者。

### 手動設定

將以下內容新增到 `~/.hermes/.env`：

```bash
# 必要
EMAIL_ADDRESS=hermes@gmail.com
EMAIL_PASSWORD=abcd efgh ijkl mnop    # 應用程式密碼（非一般密碼）
EMAIL_IMAP_HOST=imap.gmail.com
EMAIL_SMTP_HOST=smtp.gmail.com

# 安全性（推薦）
EMAIL_ALLOWED_USERS=your@email.com,colleague@work.com

# 選填
EMAIL_IMAP_PORT=993                    # 預設值：993 (IMAP SSL)
EMAIL_SMTP_PORT=587                    # 預設值：587 (SMTP STARTTLS)
EMAIL_POLL_INTERVAL=15                 # 檢查收件匣的間隔秒數（預設值：15）
EMAIL_HOME_ADDRESS=your@email.com      # Cron 任務的預設傳遞目標
```

---

## 步驟 2：啟動網關

```bash
hermes gateway              # 在前景執行
hermes gateway install      # 作為使用者服務安裝
sudo hermes gateway install --system   # 僅限 Linux：開機啟動系統服務
```

啟動時，適配器會：
1. 測試 IMAP 和 SMTP 連線
2. 將所有現有的收件匣訊息標記為「已讀」（僅處理新郵件）
3. 開始輪詢新訊息

---

## 運作原理

### 接收訊息

適配器會以可設定的間隔（預設值：15 秒）輪詢 IMAP 收件匣中的「未讀 (UNSEEN)」訊息。對於每封新郵件：

- **主旨**會作為上下文包含在內（例如 `[Subject: 部署到生產環境]`）
- **回覆郵件**（主旨以 `Re:` 開頭）會跳過主旨前綴 — 對話串上下文已經建立
- **附件**會快取在本地：
  - 圖片 (JPEG, PNG, GIF, WebP) → 可供視覺工具 (Vision Tool) 使用
  - 文件 (PDF, ZIP 等) → 可供檔案存取
- **僅 HTML 的郵件**會清除標籤以進行純文字提取
- **發送給自己的郵件**會被過濾掉以防止回覆迴圈
- **自動化/不回覆寄件者**會被靜默忽略 — 例如 `noreply@`、`mailer-daemon@`、`bounce@`、`no-reply@`，以及帶有 `Auto-Submitted`、`Precedence: bulk` 或 `List-Unsubscribe` 標頭的郵件

### 傳送回覆

回覆透過 SMTP 傳送，並帶有正確的郵件對話串資訊：

- **In-Reply-To** 和 **References** 標頭可維持對話串
- 主旨保留 `Re:` 前綴（不會出現重複的 `Re: Re:`）
- 使用代理的網域產生 **Message-ID**
- 回應以純文字 (UTF-8) 形式傳送

### 檔案附件

代理可以在回覆中傳送檔案附件。在回應中包含 `MEDIA:/path/to/file`，該檔案就會附加到寄出的電子郵件中。

### 跳過附件

若要忽略所有傳入的附件（用於惡意軟體防護或節省頻寬），請在您的 `config.yaml` 中新增：

```yaml
platforms:
  email:
    skip_attachments: true
```

啟用後，附件和行內部份將在解碼負載之前被跳過。郵件內文文字仍會正常處理。

---

## 存取控制

電子郵件存取遵循與所有其他 Hermes 平台相同的模式：

1. **設定了 `EMAIL_ALLOWED_USERS`** → 僅處理來自這些位址的郵件
2. **未設定允許清單** → 未知寄件者會收到配對碼
3. **`EMAIL_ALLOW_ALL_USERS=true`** → 接受任何寄件者（請謹慎使用）

:::warning
**務必設定 `EMAIL_ALLOWED_USERS`。** 如果不設定，任何知道代理電子郵件位址的人都可以傳送指令。代理預設擁有終端存取權限。
:::

---

## 疑難排解

| 問題 | 解決方案 |
|---------|----------|
| **啟動時出現「IMAP 連線失敗」** | 驗證 `EMAIL_IMAP_HOST` 和 `EMAIL_IMAP_PORT`。確保帳號已啟用 IMAP。對於 Gmail，請在「設定」→「轉寄和 POP/IMAP」中啟用。 |
| **啟動時出現「SMTP 連線失敗」** | 驗證 `EMAIL_SMTP_HOST` 和 `EMAIL_SMTP_PORT`。檢查密碼是否正確（Gmail 請使用應用程式密碼）。 |
| **未收到訊息** | 檢查 `EMAIL_ALLOWED_USERS` 是否包含寄件者的電子郵件。檢查垃圾郵件箱 — 某些提供商會標記自動回覆。 |
| **「身分驗證失敗」** | 對於 Gmail，您必須使用應用程式密碼，而非一般密碼。請先確保已啟用 2FA。 |
| **重複回覆** | 確保只有一個網關執行個體正在運行。檢查 `hermes gateway status`。 |
| **回應緩慢** | 預設輪詢間隔為 15 秒。使用 `EMAIL_POLL_INTERVAL=5` 縮短間隔以加快回應（但會增加 IMAP 連線數）。 |
| **回覆未顯示在對話串中** | 適配器使用 In-Reply-To 標頭。某些電子郵件用戶端（尤其是網頁版）可能無法正確處理自動化訊息的對話串。 |

---

## 安全性

:::warning
**請使用專門的電子郵件帳號。** 不要使用您的個人電子郵件 — 代理會將密碼儲存在 `.env` 中，並且可以透過 IMAP 存取整個收件匣。
:::

- 使用**應用程式密碼**而非主密碼（Gmail 啟用 2FA 後是必要的）
- 設定 `EMAIL_ALLOWED_USERS` 以限制誰可以與代理互動
- 密碼儲存在 `~/.hermes/.env` 中 — 請保護此檔案 (`chmod 600`)
- IMAP 預設使用 SSL（連接埠 993），SMTP 預設使用 STARTTLS（連接埠 587） — 連線皆已加密

---

## 環境變數參考資料

| 變數 | 必填 | 預設值 | 描述 |
|----------|----------|---------|-------------|
| `EMAIL_ADDRESS` | 是 | — | 代理的電子郵件位址 |
| `EMAIL_PASSWORD` | 是 | — | 電子郵件密碼或應用程式密碼 |
| `EMAIL_IMAP_HOST` | 是 | — | IMAP 伺服器主機（例如 `imap.gmail.com`） |
| `EMAIL_SMTP_HOST` | 是 | — | SMTP 伺服器主機（例如 `smtp.gmail.com`） |
| `EMAIL_IMAP_PORT` | 否 | `993` | IMAP 伺服器連接埠 |
| `EMAIL_SMTP_PORT` | 否 | `587` | SMTP 伺服器連接埠 |
| `EMAIL_POLL_INTERVAL` | 否 | `15` | 檢查收件匣的間隔秒數 |
| `EMAIL_ALLOWED_USERS` | 否 | — | 以逗號分隔的授權寄件者位址清單 |
| `EMAIL_HOME_ADDRESS` | 否 | — | Cron 任務的預設傳遞目標 |
| `EMAIL_ALLOW_ALL_USERS` | 否 | `false` | 允許所有寄件者（不推薦） |
