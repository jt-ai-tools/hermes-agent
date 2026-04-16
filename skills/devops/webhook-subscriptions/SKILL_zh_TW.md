---
name: webhook-subscriptions
description: 建立並管理 Webhook 訂閱，用於事件驅動的代理啟動。當使用者希望外部服務自動觸發代理執行時使用。
version: 1.0.0
metadata:
  hermes:
    tags: [webhook, events, automation, integrations]
---

# Webhook 訂閱 (Webhook Subscriptions)

建立動態 Webhook 訂閱，讓外部服務（GitHub、GitLab、Stripe、CI/CD、IoT 感測器、監控工具）能透過向 URL 發送 POST 事件來觸發 Hermes 代理執行。

## 設定 (必須先完成)

在建立訂閱之前，必須先啟用 Webhook 平台。請使用以下命令檢查：
```bash
hermes webhook list
```

如果顯示 "Webhook platform is not enabled"，請進行設定：

### 選項 1：設定精靈
```bash
hermes gateway setup
```
按照提示啟用 Webhook、設定連接埠 (port)，並設定全域 HMAC 密鑰 (secret)。

### 選項 2：手動設定
新增至 `~/.hermes/config.yaml`：
```yaml
platforms:
  webhook:
    enabled: true
    extra:
      host: "0.0.0.0"
      port: 8644
      secret: "在此產生一個強效密鑰"
```

### 選項 3：環境變數
新增至 `~/.hermes/.env`：
```bash
WEBHOOK_ENABLED=true
WEBHOOK_PORT=8644
WEBHOOK_SECRET=在此產生一個強效密鑰
```

設定完成後，啟動（或重啟）gateway：
```bash
hermes gateway run
# 或者如果使用 systemd：
systemctl --user restart hermes-gateway
```

驗證是否正在執行：
```bash
curl http://localhost:8644/health
```

## 命令 (Commands)

所有管理操作都透過 `hermes webhook` CLI 命令進行：

### 建立訂閱
```bash
hermes webhook subscribe <name> \
  --prompt "包含 {payload.fields} 的提示範本" \
  --events "event1,event2" \
  --description "說明此訂閱用途" \
  --skills "skill1,skill2" \
  --deliver telegram \
  --deliver-chat-id "12345" \
  --secret "選填的自訂密鑰"
```

傳回 Webhook URL 和 HMAC 密鑰。使用者將其服務設定為向該 URL 發送 POST 請求。

### 列出訂閱
```bash
hermes webhook list
```

### 移除訂閱
```bash
hermes webhook remove <name>
```

### 測試訂閱
```bash
hermes webhook test <name>
hermes webhook test <name> --payload '{"key": "value"}'
```

## 提示範本 (Prompt Templates)

提示支援 `{dot.notation}` 語法來存取巢狀的 payload 欄位：

- `{issue.title}` — GitHub issue 標題
- `{pull_request.user.login}` — PR 作者
- `{data.object.amount}` — Stripe 付款金額
- `{sensor.temperature}` — IoT 感測器讀數

如果未指定提示，則完整的 JSON payload 將直接放入代理提示中。

## 常見模式 (Common Patterns)

### GitHub：新 issue
```bash
hermes webhook subscribe github-issues \
  --events "issues" \
  --prompt "新的 GitHub issue #{issue.number}: {issue.title}\n\n動作: {action}\n作者: {issue.user.login}\n內容:\n{issue.body}\n\n請對此 issue 進行分類處理。" \
  --deliver telegram \
  --deliver-chat-id "-100123456789"
```

接著在 GitHub 儲存庫設定 (Settings) → Webhooks → Add webhook：
- Payload URL: 填入傳回的 webhook_url
- Content type: application/json
- Secret: 填入傳回的 secret
- Events: 選擇 "Issues"

### GitHub：PR 評論
```bash
hermes webhook subscribe github-prs \
  --events "pull_request" \
  --prompt "PR #{pull_request.number} {action}: {pull_request.title}\n提交者: {pull_request.user.login}\n分支: {pull_request.head.ref}\n\n{pull_request.body}" \
  --skills "github-code-review" \
  --deliver github_comment
```

### Stripe：付款事件
```bash
hermes webhook subscribe stripe-payments \
  --events "payment_intent.succeeded,payment_intent.payment_failed" \
  --prompt "付款狀態 {data.object.status}: 來自 {data.object.receipt_email} 的 {data.object.amount} 分" \
  --deliver telegram \
  --deliver-chat-id "-100123456789"
```

### CI/CD：建置通知
```bash
hermes webhook subscribe ci-builds \
  --events "pipeline" \
  --prompt "專案 {project.name} 分支 {object_attributes.ref} 的建置狀態為 {object_attributes.status}\n提交訊息: {commit.message}" \
  --deliver discord \
  --deliver-chat-id "1234567890"
```

### 一般監控警報
```bash
hermes webhook subscribe alerts \
  --prompt "警報: {alert.name}\n嚴重程度: {alert.severity}\n訊息: {alert.message}\n\n請進行調查並提出補救建議。" \
  --deliver origin
```

## 安全性 (Security)

- 每個訂閱都會獲得自動產生的 HMAC-SHA256 密鑰（或使用 `--secret` 自行提供）。
- Webhook 轉接器會驗證每個傳入 POST 請求的簽章。
- `config.yaml` 中的靜態路由不會被動態訂閱覆蓋。
- 訂閱內容會持久化儲存至 `~/.hermes/webhook_subscriptions.json`。

## 運作原理

1. `hermes webhook subscribe` 將資料寫入 `~/.hermes/webhook_subscriptions.json`。
2. Webhook 轉接器在每次傳入請求時熱重載此檔案（受 mtime 門控，開銷極小）。
3. 當傳入的 POST 符合路由時，轉接器會格式化提示並觸發代理執行。
4. 代理的分析結果將傳送到設定的目標（Telegram、Discord、GitHub 評論等）。

## 疑難排解

如果 Webhook 無法運作：

1. **Gateway 是否正在執行？** 使用 `systemctl --user status hermes-gateway` 或 `ps aux | grep gateway` 檢查。
2. **Webhook 伺服器是否正在監聽？** `curl http://localhost:8644/health` 應傳回 `{"status": "ok"}`。
3. **檢查 Gateway 記錄：** `grep webhook ~/.hermes/logs/gateway.log | tail -20`。
4. **簽章不符合？** 驗證服務中的密鑰是否與 `hermes webhook list` 顯示的一致。GitHub 發送 `X-Hub-Signature-256`，GitLab 發送 `X-Gitlab-Token`。
5. **防火牆/NAT 問題？** 服務必須能夠連線到 Webhook URL。若進行本地開發，請使用隧道工具（如 ngrok, cloudflared）。
6. **事件類型錯誤？** 檢查 `--events` 過濾器是否符合服務發送的內容。使用 `hermes webhook test <name>` 驗證路由是否運作。
