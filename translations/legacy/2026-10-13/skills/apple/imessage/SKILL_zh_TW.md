---
name: imessage
description: 透過 macOS 上的 imsg CLI 發送與接收 iMessage/SMS。
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos]
metadata:
  hermes:
    tags: [iMessage, SMS, messaging, macOS, Apple, 通訊]
prerequisites:
  commands: [imsg]
---

# iMessage

使用 `imsg` 透過 macOS 的「訊息」應用程式 (Messages.app) 讀取與發送 iMessage/SMS。

## 先決條件

- **macOS** 並已登入「訊息」應用程式
- 安裝方式：`brew install steipete/tap/imsg`
- 為終端機授予「完全磁碟存取權限」(系統設定 → 隱私權與安全性 → 完全磁碟存取權限)
- 在系統提示時，為「訊息」應用程式授予「自動化」權限

## 何時使用

- 使用者要求發送 iMessage 或簡訊
- 讀取 iMessage 對話歷史紀錄
- 查看最近的「訊息」應用程式聊天紀錄
- 發送訊息至電話號碼或 Apple ID

## 何時不該使用

- Telegram/Discord/Slack/WhatsApp 訊息 → 請使用對應的網關頻道
- 群組聊天管理 (新增/移除成員) → 不支援
- 批次/大量發送訊息 → 務必先與使用者確認

## 快速參考

### 列出聊天紀錄

```bash
imsg chats --limit 10 --json
```

### 查看歷史紀錄

```bash
# 透過聊天 ID
imsg history --chat-id 1 --limit 20 --json

# 包含附件資訊
imsg history --chat-id 1 --limit 20 --attachments --json
```

### 發送訊息

```bash
# 僅限文字
imsg send --to "+14155551212" --text "你好！"

# 包含附件
imsg send --to "+14155551212" --text "看看這個" --file /path/to/image.jpg

# 強制使用 iMessage 或 SMS
imsg send --to "+14155551212" --text "嗨" --service imessage
imsg send --to "+14155551212" --text "嗨" --service sms
```

### 監看新訊息

```bash
imsg watch --chat-id 1 --attachments
```

## 服務選項

- `--service imessage` — 強制使用 iMessage (要求收件者具備 iMessage)
- `--service sms` — 強制使用 SMS (綠色對話泡泡)
- `--service auto` — 讓「訊息」應用程式決定 (預設)

## 規則

1. **發送前務必確認**收件者與訊息內容
2. **絕不發送給未知號碼**，除非獲得使用者明確核准
3. **驗證檔案路徑**在附加前確實存在
4. **不要濫發訊息** — 請自行限制發送頻率

## 範例工作流

使用者：「傳簡訊給媽媽說我會晚點到」

```bash
# 1. 尋找媽媽的對話
imsg chats --limit 20 --json | jq '.[] | select(.displayName | contains("媽媽"))'

# 2. 與使用者確認：「找到位於 +1555123456 的媽媽。要透過 iMessage 發送『我會晚點到』嗎？」

# 3. 確認後發送
imsg send --to "+1555123456" --text "我會晚點到"
```
