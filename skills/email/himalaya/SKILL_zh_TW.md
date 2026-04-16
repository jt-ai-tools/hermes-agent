---
name: himalaya
description: 透過 IMAP/SMTP 管理電子郵件的 CLI。使用 himalaya 在終端機中列出、讀取、編寫、回覆、轉寄、搜尋與組織電子郵件。支援多帳號以及使用 MML (MIME Meta Language) 編寫郵件。
version: 1.0.0
author: community
license: MIT
metadata:
  hermes:
    tags: [電子郵件, IMAP, SMTP, CLI, 通訊]
    homepage: https://github.com/pimalaya/himalaya
prerequisites:
  commands: [himalaya]
---

# Himalaya 電子郵件 CLI

Himalaya 是一款 CLI 電子郵件用戶端，讓你可以使用 IMAP、SMTP、Notmuch 或 Sendmail 後端從終端機管理電子郵件。

## 參考文件

- `references/configuration_zh_TW.md` (配置檔案設定 + IMAP/SMTP 身分驗證)
- `references/message-composition_zh_TW.md` (用於編寫電子郵件的 MML 語法)

## 先決條件

1. 已安裝 Himalaya CLI (使用 `himalaya --version` 驗證)
2. 配置檔案位於 `~/.config/himalaya/config.toml`
3. 已設定 IMAP/SMTP 憑證 (密碼需安全地儲存)

### 安裝

```bash
# 預先編譯的二進制檔 (Linux/macOS — 推薦)
curl -sSL https://raw.githubusercontent.com/pimalaya/himalaya/master/install.sh | PREFIX=~/.local sh

# macOS 透過 Homebrew
brew install himalaya

# 或透過 cargo (任何帶有 Rust 的平台)
cargo install himalaya --locked
```

## 配置設定

執行互動式精靈來設定帳號：

```bash
himalaya account configure
```

或手動建立 `~/.config/himalaya/config.toml`：

```toml
[accounts.personal]
email = "you@example.com"
display-name = "Your Name"
default = true

backend.type = "imap"
backend.host = "imap.example.com"
backend.port = 993
backend.encryption.type = "tls"
backend.login = "you@example.com"
backend.auth.type = "password"
backend.auth.cmd = "pass show email/imap"  # 或使用 keyring

message.send.backend.type = "smtp"
message.send.backend.host = "smtp.example.com"
message.send.backend.port = 587
message.send.backend.encryption.type = "start-tls"
message.send.backend.login = "you@example.com"
message.send.backend.auth.type = "password"
message.send.backend.auth.cmd = "pass show email/smtp"
```

## Hermes 整合注意事項

- **讀取、列出、搜尋、移動、刪除** 均可直接透過終端機工具運作。
- **編寫/回覆/轉寄** — 為了可靠性，建議使用管道輸入 (`cat << EOF | himalaya template send`)。互動式 `$EDITOR` 模式可配合 `pty=true` + 背景模式 + 程序工具使用，但需要知道編輯器及其指令。
- 使用 `--output json` 取得結構化輸出，更易於程式化解析。
- `himalaya account configure` 精靈需要互動式輸入 — 請使用 PTY 模式：`terminal(command="himalaya account configure", pty=true)`。

## 常見操作

### 列出資料夾

```bash
himalaya folder list
```

### 列出電子郵件

列出收件匣 (INBOX，預設值) 中的電子郵件：

```bash
himalaya envelope list
```

列出特定資料夾中的電子郵件：

```bash
himalaya envelope list --folder "Sent"
```

使用分頁列出：

```bash
himalaya envelope list --page 1 --page-size 20
```

### 搜尋電子郵件

```bash
himalaya envelope list from john@example.com subject meeting
```

### 讀取電子郵件

透過 ID 讀取電子郵件 (顯示純文字)：

```bash
himalaya message read 42
```

匯出原始 MIME：

```bash
himalaya message export 42 --full
```

### 回覆電子郵件

若要從 Hermes 進行非互動式回覆，請讀取原始郵件、編寫回覆並透過管道傳送：

```bash
# 取得回覆範本，編輯它並發送
himalaya template reply 42 | sed 's/^$/\n在此輸入您的回覆文字\n/' | himalaya template send
```

或手動建構回覆：

```bash
cat << 'EOF' | himalaya template send
From: you@example.com
To: sender@example.com
Subject: Re: Original Subject
In-Reply-To: <original-message-id>

在此輸入您的回覆。
EOF
```

回覆所有人 (互動式 — 需要 $EDITOR，請改用上述的範本方法)：

```bash
himalaya message reply 42 --all
```

### 轉寄電子郵件

```bash
# 取得轉寄範本並透過管道傳送修改內容
himalaya template forward 42 | sed 's/^To:.*/To: newrecipient@example.com/' | himalaya template send
```

### 編寫新郵件

**非互動式 (在 Hermes 中使用此方式)** — 透過 stdin 傳送郵件：

```bash
cat << 'EOF' | himalaya template send
From: you@example.com
To: recipient@example.com
Subject: 測試郵件

來自 Himalaya 的問候！
EOF
```

或使用標頭旗標：

```bash
himalaya message write -H "To:recipient@example.com" -H "Subject:測試" "在此輸入郵件本文"
```

注意：若 `himalaya message write` 未配合管道輸入，將會開啟 `$EDITOR`。這在 `pty=true` + 背景模式下可行，但使用管道更簡單且更可靠。

### 移動/複製電子郵件

移動至資料夾：

```bash
himalaya message move 42 "Archive"
```

複製至資料夾：

```bash
himalaya message copy 42 "Important"
```

### 刪除電子郵件

```bash
himalaya message delete 42
```

### 管理標籤

新增標籤：

```bash
himalaya flag add 42 --flag seen
```

移除標籤：

```bash
himalaya flag remove 42 --flag seen
```

## 多帳號

列出帳號：

```bash
himalaya account list
```

使用特定帳號：

```bash
himalaya --account work envelope list
```

## 附件

儲存郵件中的附件：

```bash
himalaya attachment download 42
```

儲存至特定目錄：

```bash
himalaya attachment download 42 --dir ~/Downloads
```

## 輸出格式

大多數指令都支援 `--output` 以取得結構化輸出：

```bash
himalaya envelope list --output json
himalaya envelope list --output plain
```

## 偵錯

啟用偵錯記錄：

```bash
RUST_LOG=debug himalaya envelope list
```

包含回溯的完整追蹤：

```bash
RUST_LOG=trace RUST_BACKTRACE=1 himalaya envelope list
```

## 提示

- 使用 `himalaya --help` 或 `himalaya <command> --help` 查看詳細用法。
- 郵件 ID 是相對於目前資料夾的；變更資料夾後請重新列出。
- 若要編寫帶有附件的豐富郵件，請使用 MML 語法 (請參閱 `references/message-composition_zh_TW.md`)。
- 使用 `pass`、系統金鑰圈或會輸出密碼的指令來安全地儲存密碼。
