---
sidebar_position: 13
title: "Webhooks"
description: "接收來自 GitHub、GitLab 和其他服務的事件以觸發 Hermes 代理程式執行"
---

# Webhooks

接收來自外部服務（GitHub、GitLab、JIRA、Stripe 等）的事件，並自動觸發 Hermes 代理程式執行。Webhook 轉接器會執行一個 HTTP 伺服器，接收 POST 請求、驗證 HMAC 簽章、將有效負載（payload）轉換為代理程式提示詞，並將回應路由回來源或其他設定的平台。

代理程式會處理事件，並可以透過在 PR 上發表評論、向 Telegram/Discord 傳送訊息或記錄結果來進行回應。

---

## 快速開始

1. 透過 `hermes gateway setup` 或環境變數啟用
2. 在 `config.yaml` 中定義路由，**或者**使用 `hermes webhook subscribe` 動態建立路由
3. 將您的服務指向 `http://your-server:8644/webhooks/<route-name>`

---

## 設定

有兩種方式可以啟用 Webhook 轉接器。

### 透過設定精靈

```bash
hermes gateway setup
```

按照提示啟用 Webhook、設定連接埠並設定全域 HMAC 秘密金鑰。

### 透過環境變數

在 `~/.hermes/.env` 中加入：

```bash
WEBHOOK_ENABLED=true
WEBHOOK_PORT=8644        # 預設值
WEBHOOK_SECRET=your-global-secret
```

### 驗證伺服器

當閘道器（Gateway）正在執行時：

```bash
curl http://localhost:8644/health
```

預期回應：

```json
{"status": "ok", "platform": "webhook"}
```

---

## 設定路由 {#configuring-routes}

路由定義了如何處理不同的 Webhook 來源。每個路由都是 `config.yaml` 中 `platforms.webhook.extra.routes` 下的一個命名項目。

### 路由屬性

| 屬性 | 必要 | 說明 |
|----------|----------|-------------|
| `events` | 否 | 要接受的事件類型列表（例如 `["pull_request"]`）。如果為空，則接受所有事件。事件類型從有效負載中的 `X-GitHub-Event`、`X-GitLab-Event` 或 `event_type` 讀取。 |
| `secret` | **是** | 用於簽章驗證的 HMAC 秘密金鑰。如果路由上未設定，則回退到全域 `secret`。僅供測試時設定為 `"INSECURE_NO_AUTH"`（跳過驗證）。 |
| `prompt` | 否 | 具有點號標記法有效負載存取的範本字串（例如 `{pull_request.title}`）。如果省略，則將完整的 JSON 有效負載傾印到提示詞中。 |
| `skills` | 否 | 代理程式執行時要載入的技能名稱列表。 |
| `deliver` | 否 | 回應傳送目的地：`github_comment`、`telegram`、`discord`、`slack`、`signal`、`sms`、`whatsapp`、`matrix`、`mattermost`、`homeassistant`、`email`、`dingtalk`、`feishu`、`wecom`、`weixin`、`bluebubbles`、`qqbot` 或 `log`（預設）。 |
| `deliver_extra` | 否 | 額外的傳遞設定 —— 鍵值取決於 `deliver` 類型（例如 `repo`、`pr_number`、`chat_id`）。值支援與 `prompt` 相同的 `{dot.notation}` 範本。 |

### 完整範例

```yaml
platforms:
  webhook:
    enabled: true
    extra:
      port: 8644
      secret: "global-fallback-secret"
      routes:
        github-pr:
          events: ["pull_request"]
          secret: "github-webhook-secret"
          prompt: |
            請審閱此拉取請求 (Pull Request)：
            儲存庫：{repository.full_name}
            PR #{number}：{pull_request.title}
            作者：{pull_request.user.login}
            URL：{pull_request.html_url}
            Diff URL：{pull_request.diff_url}
            操作：{action}
          skills: ["github-code-review"]
          deliver: "github_comment"
          deliver_extra:
            repo: "{repository.full_name}"
            pr_number: "{number}"
        deploy-notify:
          events: ["push"]
          secret: "deploy-secret"
          prompt: "新推播至 {repository.full_name} 分支 {ref}：{head_commit.message}"
          deliver: "telegram"
```

### 提示詞範本

提示詞使用點號標記法來存取 Webhook 有效負載中的巢狀欄位：

- `{pull_request.title}` 解析為 `payload["pull_request"]["title"]`
- `{repository.full_name}` 解析為 `payload["repository"]["full_name"]`
- `{__raw__}` —— 特別權杖，會傾印**整個有效負載**為縮排的 JSON（截斷為 4000 個字元）。適用於監控告警或代理程式需要完整上下文的通用 Webhook。
- 缺失的鍵值會保留為字面量 `{key}` 字串（不報錯）。
- 巢狀字典和列表會被序列化為 JSON 並截斷為 2000 個字元。

您可以將 `{__raw__}` 與常規範本變數混合使用：

```yaml
prompt: "來自 {pull_request.user.login} 的 PR #{pull_request.number}：{__raw__}"
```

如果路由未設定 `prompt` 範本，則整個有效負載將以縮排的 JSON 形式傾印（截斷為 4000 個字元）。

同樣的點號標記法範本也適用於 `deliver_extra` 的值。

### 論壇主題傳遞

將 Webhook 回應傳送到 Telegram 時，您可以透過在 `deliver_extra` 中包含 `message_thread_id`（或 `thread_id`）來指定特定的論壇主題：

```yaml
webhooks:
  routes:
    alerts:
      events: ["alert"]
      prompt: "告警：{__raw__}"
      deliver: "telegram"
      deliver_extra:
        chat_id: "-1001234567890"
        message_thread_id: "42"
```

如果在 `deliver_extra` 中未提供 `chat_id`，則傳遞將回退到目標平台設定的主頻道。

---

## GitHub PR 審閱（逐步指南） {#github-pr-review}

此指南設定了對每個拉取請求的自動程式碼審閱。

### 1. 在 GitHub 中建立 Webhook

1. 前往您的儲存庫 → **Settings** → **Webhooks** → **Add webhook**
2. 將 **Payload URL** 設定為 `http://your-server:8644/webhooks/github-pr`
3. 將 **Content type** 設定為 `application/json`
4. 設定 **Secret** 以匹配您的路由設定（例如 `github-webhook-secret`）
5. 在 **Which events?** 下，選擇 **Let me select individual events** 並勾選 **Pull requests**
6. 點擊 **Add webhook**

### 2. 加入路由設定

如上例所示，將 `github-pr` 路由加入您的 `~/.hermes/config.yaml`。

### 3. 確保 `gh` CLI 已驗證

`github_comment` 傳遞類型使用 GitHub CLI 來發表評論：

```bash
gh auth login
```

### 4. 測試

在儲存庫上開啟一個拉取請求。Webhook 會觸發，Hermes 處理該事件，並在 PR 上發表審閱評論。

---

## GitLab Webhook 設定 {#gitlab-webhook-setup}

GitLab Webhook 的運作方式類似，但使用不同的驗證機制。GitLab 將秘密金鑰作為純文字 `X-Gitlab-Token` 標頭傳送（精確字串匹配，而非 HMAC）。

### 1. 在 GitLab 中建立 Webhook

1. 前往您的專案 → **Settings** → **Webhooks**
2. 將 **URL** 設定為 `http://your-server:8644/webhooks/gitlab-mr`
3. 輸入您的 **Secret token**
4. 選擇 **Merge request events**（以及任何您想要的其他事件）
5. 點擊 **Add webhook**

### 2. 加入路由設定

```yaml
platforms:
  webhook:
    enabled: true
    extra:
      routes:
        gitlab-mr:
          events: ["merge_request"]
          secret: "your-gitlab-secret-token"
          prompt: |
            請審閱此合併請求 (Merge Request)：
            專案：{project.path_with_namespace}
            MR !{object_attributes.iid}：{object_attributes.title}
            作者：{object_attributes.last_commit.author.name}
            URL：{object_attributes.url}
            操作：{object_attributes.action}
          deliver: "log"
```

---

## 傳送選項 {#delivery-options}

`deliver` 欄位控制代理程式在處理 Webhook 事件後的回應去向。

| 傳送類型 | 說明 |
|-------------|-------------|
| `log` | 將回應記錄到閘道器日誌輸出。這是預設值，適用於測試。 |
| `github_comment` | 透過 `gh` CLI 將回應發表為 PR/Issue 評論。需要 `deliver_extra.repo` 和 `deliver_extra.pr_number`。必須在閘道器主機上安裝 `gh` CLI 並完成驗證 (`gh auth login`)。 |
| `telegram` | 將回應路由到 Telegram。使用主頻道，或在 `deliver_extra` 中指定 `chat_id`。 |
| `discord` | 將回應路由到 Discord。使用主頻道，或在 `deliver_extra` 中指定 `chat_id`。 |
| `slack` | 將回應路由到 Slack。使用主頻道，或在 `deliver_extra` 中指定 `chat_id`。 |
| `signal` | 將回應路由到 Signal。使用主頻道，或在 `deliver_extra` 中指定 `chat_id`。 |
| `sms` | 透過 Twilio 將回應路由到 SMS。使用主頻道，或在 `deliver_extra` 中指定 `chat_id`。 |
| `whatsapp` | 將回應路由到 WhatsApp。使用主頻道，或在 `deliver_extra` 中指定 `chat_id`。 |
| `matrix` | 將回應路由到 Matrix。使用主頻道，或在 `deliver_extra` 中指定 `chat_id`。 |
| `mattermost` | 將回應路由到 Mattermost。使用主頻道，或在 `deliver_extra` 中指定 `chat_id`。 |
| `homeassistant` | 將回應路由到 Home Assistant。使用主頻道，或在 `deliver_extra` 中指定 `chat_id`。 |
| `email` | 將回應路由到電子郵件。使用主頻道，或在 `deliver_extra` 中指定 `chat_id`。 |
| `dingtalk` | 將回應路由到釘釘 (DingTalk)。使用主頻道，或在 `deliver_extra` 中指定 `chat_id`。 |
| `feishu` | 將回應路由到飛書 (Feishu)/Lark。使用主頻道，或在 `deliver_extra` 中指定 `chat_id`。 |
| `wecom` | 將回應路由到企業微信 (WeCom)。使用主頻道，或在 `deliver_extra` 中指定 `chat_id`。 |
| `weixin` | 將回應路由到微信 (Weixin/WeChat)。使用主頻道，或在 `deliver_extra` 中指定 `chat_id`。 |
| `bluebubbles` | 將回應路由到 BlueBubbles (iMessage)。使用主頻道，或在 `deliver_extra` 中指定 `chat_id`。 |

對於跨平台傳送，目標平台也必須在閘道器中啟用並連線。如果 `deliver_extra` 中未提供 `chat_id`，則回應將傳送到該平台設定的主頻道。

---

## 動態訂閱 (CLI) {#dynamic-subscriptions}

除了 `config.yaml` 中的靜態路由外，您還可以使用 `hermes webhook` CLI 指令動態建立 Webhook 訂閱。這在代理程式本身需要設定事件驅動的觸發器時特別有用。

### 建立訂閱

```bash
hermes webhook subscribe github-issues \
  --events "issues" \
  --prompt "新議題 #{issue.number}：{issue.title}\n來自：{issue.user.login}\n\n{issue.body}" \
  --deliver telegram \
  --deliver-chat-id "-100123456789" \
  --description "分流新的 GitHub 議題"
```

這會返回 Webhook URL 和一個自動產生的 HMAC 秘密金鑰。將您的服務設定為向該 URL 發送 POST。

### 列出訂閱

```bash
hermes webhook list
```

### 移除訂閱

```bash
hermes webhook remove github-issues
```

### 測試訂閱

```bash
hermes webhook test github-issues
hermes webhook test github-issues --payload '{"issue": {"number": 42, "title": "Test"}}'
```

### 動態訂閱如何運作

- 訂閱儲存在 `~/.hermes/webhook_subscriptions.json` 中。
- Webhook 轉接器會在每個傳入請求時熱重載此檔案（受修改時間管制，開銷極小）。
- `config.yaml` 中的靜態路由優先權始終高於名稱相同的動態路由。
- 動態訂閱使用與靜態路由相同的路由格式和功能（事件、提示詞範本、技能、傳送）。
- 無需重啟閘道器 —— 訂閱後立即生效。

### 代理程式驅動的訂閱

代理程式在 `webhook-subscriptions` 技能的引導下，可以透過終端工具建立訂閱。要求代理程式「為 GitHub 議題設定 Webhook」，它將執行適當的 `hermes webhook subscribe` 指令。

---

## 安全性 {#security}

Webhook 轉接器包含多層安全性：

### HMAC 簽章驗證

轉接器會使用針對每個來源的適當方法驗證傳入的 Webhook 簽章：

- **GitHub**：`X-Hub-Signature-256` 標頭 —— 以 `sha256=` 為前綴的 HMAC-SHA256 十六進位摘要。
- **GitLab**：`X-Gitlab-Token` 標頭 —— 純文字秘密金鑰字串匹配。
- **通用**：`X-Webhook-Signature` 標頭 —— 原始 HMAC-SHA256 十六進位摘要。

如果設定了秘密金鑰但不存在可識別的簽章標頭，請求將被拒絕。

### 必須設定秘密金鑰

每個路由都必須有一個秘密金鑰 —— 無論是直接在路由上設定，還是繼承自全域 `secret`。沒有秘密金鑰的路由會導致轉接器在啟動時失敗並報錯。僅供開發/測試使用，您可以將秘密金鑰設定為 `"INSECURE_NO_AUTH"` 以完全跳過驗證。

### 速率限制

預設情況下，每個路由的速率限制為**每分鐘 30 個請求**（固定窗口）。可進行全域設定：

```yaml
platforms:
  webhook:
    extra:
      rate_limit: 60  # 每分鐘請求數
```

超過限制的請求將收到 `429 Too Many Requests` 回應。

### 冪等性 {#idempotency}

傳遞 ID（來自 `X-GitHub-Delivery`、`X-Request-ID` 或時間戳回退）會快取 **1 小時**。重複的傳遞（例如 Webhook 重試）將以 `200` 回應靜默跳過，防止重複的代理程式執行。

### 內容大小限制

超過 **1 MB** 的有效負載將在讀取內容之前被拒絕。可進行設定：

```yaml
platforms:
  webhook:
    extra:
      max_body_bytes: 2097152  # 2 MB
```

### 提示詞注入風險

:::warning
Webhook 有效負載包含攻擊者可控的數據 —— PR 標題、提交訊息、議題說明等都可能包含惡意指令。當暴露於網際網路時，請在沙盒環境（Docker、虛擬機）中執行閘道器。考慮使用 Docker 或 SSH 終端後端進行隔離。
:::

---

## 疑難排解 {#troubleshooting}

### Webhook 未到達

- 驗證連接埠已開啟且可從 Webhook 來源訪問。
- 檢查防火牆規則 —— 連接埠 `8644`（或您設定的連接埠）必須開啟。
- 驗證 URL 路徑匹配：`http://your-server:8644/webhooks/<route-name>`。
- 使用 `/health` 端點確認伺服器正在執行。

### 簽章驗證失敗

- 確保路由設定中的秘密金鑰與 Webhook 來源中設定的秘密金鑰完全一致。
- 對於 GitHub，秘密金鑰是基於 HMAC 的 —— 檢查 `X-Hub-Signature-256`。
- 對於 GitLab，秘密金鑰是純權杖匹配 —— 檢查 `X-Gitlab-Token`。
- 檢查閘道器日誌中是否有 `Invalid signature` 警告。

### 事件被忽略

- 檢查事件類型是否在路由的 `events` 列表中。
- GitHub 事件使用 `pull_request`、`push`、`issues` 等值（`X-GitHub-Event` 標頭值）。
- GitLab 事件使用 `merge_request`、`push` 等值（`X-GitLab-Event` 標頭值）。
- 如果 `events` 為空或未設定，則接受所有事件。

### 代理程式未回應

- 在前台執行閘道器以查看日誌：`hermes gateway run`。
- 檢查提示詞範本是否正確渲染。
- 驗證傳送目標已設定且已連線。

### 重複回應

- 冪等性快取應該能防止這種情況 —— 檢查 Webhook 來源是否傳送了傳遞 ID 標頭（`X-GitHub-Delivery` 或 `X-Request-ID`）。
- 傳遞 ID 快取時間為 1 小時。

### `gh` CLI 錯誤（GitHub 評論傳送）

- 在閘道器主機上執行 `gh auth login`。
- 確保經過身分驗證的 GitHub 使用者對儲存庫具有寫入權限。
- 檢查 `gh` 是否已安裝並在 PATH 中。

---

## 環境變數 {#environment-variables}

| 變數 | 說明 | 預設值 |
|----------|-------------|---------|
| `WEBHOOK_ENABLED` | 啟用 Webhook 平台轉接器 | `false` |
| `WEBHOOK_PORT` | 接收 Webhook 的 HTTP 伺服器連接埠 | `8644` |
| `WEBHOOK_SECRET` | 全域 HMAC 秘密金鑰（當路由未指定自己的秘密金鑰時作為回退） | _（無）_ |
