---
name: agentmail
description: 透過 AgentMail 給予代理專用的電子郵件收件匣。使用代理擁有的電子郵件地址（例如 hermes-agent@agentmail.to）自主發送、接收及管理電子郵件。
version: 1.0.0
metadata:
  hermes:
    tags: [email, communication, agentmail, mcp]
    category: email
---

# AgentMail — 代理擁有的電子郵件收件匣

## 要求

- **AgentMail API 金鑰** (必需) — 於 https://console.agentmail.to 註冊（免費方案：3 個收件匣，每月 3,000 封電子郵件；付費方案每月 20 美元起）
- Node.js 18+ (用於 MCP 伺服器)

## 何時使用
當您需要執行以下操作時使用此技能：
- 給予代理專用的電子郵件地址
- 代表代理自主發送電子郵件
- 接收並閱讀傳入的電子郵件
- 管理電子郵件對話串與交流
- 透過電子郵件註冊服務或進行身份驗證
- 透過電子郵件與其他代理或人類溝通

這 **不是** 用於閱讀用戶的個人電子郵件（請使用 himalaya 或 Gmail 執行該任務）。
AgentMail 賦予代理自己的身份和收件匣。

## 設定

### 1. 獲取 API 金鑰
- 前往 https://console.agentmail.to
- 建立帳戶並產生 API 金鑰（以 `am_` 開頭）

### 2. 配置 MCP 伺服器
新增至 `~/.hermes/config.yaml`（貼上您的實際金鑰 — MCP 環境變數不會從 .env 展開）：
```yaml
mcp_servers:
  agentmail:
    command: "npx"
    args: ["-y", "agentmail-mcp"]
    env:
      AGENTMAIL_API_KEY: "am_your_key_here"
```

### 3. 重啟 Hermes
```bash
hermes
```
現在 11 個 AgentMail 工具已自動可用。

## 可用工具 (透過 MCP)

| 工具 | 說明 |
|------|-------------|
| `list_inboxes` | 列出所有代理收件匣 |
| `get_inbox` | 獲取特定收件匣的詳情 |
| `create_inbox` | 建立新收件匣（獲得一個真實的電子郵件地址） |
| `delete_inbox` | 刪除收件匣 |
| `list_threads` | 列出收件匣中的電子郵件對話串 |
| `get_thread` | 獲取特定的電子郵件對話串 |
| `send_message` | 發送新郵件 |
| `reply_to_message` | 回覆現有郵件 |
| `forward_message` | 轉寄郵件 |
| `update_message` | 更新郵件標籤/狀態 |
| `get_attachment` | 下載郵件附件 |

## 程序

### 建立收件匣並發送郵件
1. 建立專用收件匣：
   - 使用 `create_inbox` 並提供使用者名稱（例如 `hermes-agent`）
   - 代理獲得地址：`hermes-agent@agentmail.to`
2. 發送郵件：
   - 使用 `send_message` 並提供 `inbox_id`, `to`, `subject`, `text`
3. 檢查回覆：
   - 使用 `list_threads` 查看傳入的對話
   - 使用 `get_thread` 閱讀特定的對話串

### 檢查傳入郵件
1. 使用 `list_inboxes` 尋找您的收件匣 ID
2. 使用 `list_threads` 配合收件匣 ID 查看對話
3. 使用 `get_thread` 閱讀對話串及其訊息

### 回覆郵件
1. 使用 `get_thread` 獲取對話串
2. 使用 `reply_to_message` 並提供訊息 ID 和您的回覆文字

## 範例工作流

**註冊服務：**
```
1. create_inbox (使用者名稱: "signup-bot")
2. 使用該收件匣地址在服務上註冊
3. list_threads 檢查驗證郵件
4. get_thread 閱讀驗證碼
```

**代理對人類的外部聯繫：**
```
1. create_inbox (使用者名稱: "hermes-outreach")
2. send_message (收件者: user@example.com, 主旨: "Hello", 內容: "...")
3. list_threads 檢查回覆
```

## 陷阱
- 免費方案限制為 3 個收件匣，每月 3,000 封郵件。
- 免費方案的郵件來自 `@agentmail.to` 網域（付費方案支援自定義網域）。
- MCP 伺服器需要 Node.js (18+) (`npx -y agentmail-mcp`)。
- 必須安裝 `mcp` Python 套件：`pip install mcp`。
- 即時傳入郵件 (Webhook) 需要公開伺服器 — 對於個人用途，請改用透過 cronjob 輪詢 `list_threads` 的方式。

## 驗證
設定完成後，使用以下方式測試：
```
hermes --toolsets mcp -q "建立一個名為 test-agent 的 AgentMail 收件匣，並告訴我它的電子郵件地址"
```
您應該會看到回傳的新收件匣地址。

## 參考資料
- AgentMail 文件：https://docs.agentmail.to/
- AgentMail 控制台：https://console.agentmail.to
- AgentMail MCP 儲存庫：https://github.com/agentmail-to/agentmail-mcp
- 價格：https://www.agentmail.to/pricing
