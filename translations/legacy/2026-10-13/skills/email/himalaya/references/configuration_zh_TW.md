# Himalaya 配置參考

配置檔案路徑：`~/.config/himalaya/config.toml`

## 最小化 IMAP + SMTP 設定

```toml
[accounts.default]
email = "user@example.com"
display-name = "Your Name"
default = true

# 用於讀取電子郵件的 IMAP 後端
backend.type = "imap"
backend.host = "imap.example.com"
backend.port = 993
backend.encryption.type = "tls"
backend.login = "user@example.com"
backend.auth.type = "password"
backend.auth.raw = "your-password"

# 用於發送電子郵件的 SMTP 後端
message.send.backend.type = "smtp"
message.send.backend.host = "smtp.example.com"
message.send.backend.port = 587
message.send.backend.encryption.type = "start-tls"
message.send.backend.login = "user@example.com"
message.send.backend.auth.type = "password"
message.send.backend.auth.raw = "your-password"
```

## 密碼選項

### 原始密碼 (僅供測試，不推薦)

```toml
backend.auth.raw = "your-password"
```

### 透過指令取得密碼 (推薦)

```toml
backend.auth.cmd = "pass show email/imap"
# backend.auth.cmd = "security find-generic-password -a user@example.com -s imap -w"
```

### 系統金鑰圈 (需要 keyring 功能)

```toml
backend.auth.keyring = "imap-example"
```

接著執行 `himalaya account configure <account>` 來儲存密碼。

## Gmail 配置

```toml
[accounts.gmail]
email = "you@gmail.com"
display-name = "Your Name"
default = true

backend.type = "imap"
backend.host = "imap.gmail.com"
backend.port = 993
backend.encryption.type = "tls"
backend.login = "you@gmail.com"
backend.auth.type = "password"
backend.auth.cmd = "pass show google/app-password"

message.send.backend.type = "smtp"
message.send.backend.host = "smtp.gmail.com"
message.send.backend.port = 587
message.send.backend.encryption.type = "start-tls"
message.send.backend.login = "you@gmail.com"
message.send.backend.auth.type = "password"
message.send.backend.auth.cmd = "pass show google/app-password"
```

**注意：** 若啟用了兩步驟驗證 (2FA)，Gmail 需要使用「應用程式密碼」。

## iCloud 配置

```toml
[accounts.icloud]
email = "you@icloud.com"
display-name = "Your Name"

backend.type = "imap"
backend.host = "imap.mail.me.com"
backend.port = 993
backend.encryption.type = "tls"
backend.login = "you@icloud.com"
backend.auth.type = "password"
backend.auth.cmd = "pass show icloud/app-password"

message.send.backend.type = "smtp"
message.send.backend.host = "smtp.mail.me.com"
message.send.backend.port = 587
message.send.backend.encryption.type = "start-tls"
message.send.backend.login = "you@icloud.com"
message.send.backend.auth.type = "password"
message.send.backend.auth.cmd = "pass show icloud/app-password"
```

**注意：** 請在 appleid.apple.com 生成一個「應用程式專用密碼」。

## 資料夾別名

映射自訂資料夾名稱：

```toml
[accounts.default.folder.alias]
inbox = "INBOX"
sent = "Sent"
drafts = "Drafts"
trash = "Trash"
```

## 多帳號

```toml
[accounts.personal]
email = "personal@example.com"
default = true
# ... 後端配置 ...

[accounts.work]
email = "work@company.com"
# ... 後端配置 ...
```

使用 `--account` 切換帳號：

```bash
himalaya --account work envelope list
```

## Notmuch 後端 (本地郵件)

```toml
[accounts.local]
email = "user@example.com"

backend.type = "notmuch"
backend.db-path = "~/.mail/.notmuch"
```

## OAuth2 身分驗證 (適用於支援該功能的供應商)

```toml
backend.auth.type = "oauth2"
backend.auth.client-id = "your-client-id"
backend.auth.client-secret.cmd = "pass show oauth/client-secret"
backend.auth.access-token.cmd = "pass show oauth/access-token"
backend.auth.refresh-token.cmd = "pass show oauth/refresh-token"
backend.auth.auth-url = "https://provider.com/oauth/authorize"
backend.auth.token-url = "https://provider.com/oauth/token"
```

## 其他選項

### 簽名檔

```toml
[accounts.default]
signature = "Best regards,\nYour Name"
signature-delim = "-- \n"
```

### 下載目錄

```toml
[accounts.default]
downloads-dir = "~/Downloads/himalaya"
```

### 用於編寫的編輯器

透過環境變數設定：

```bash
export EDITOR="vim"
```
