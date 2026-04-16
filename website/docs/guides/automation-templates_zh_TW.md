---
sidebar_position: 15
title: "自動化範本"
description: "即開即用的自動化食譜 — 排程任務、GitHub 事件觸發、API Webhook 和多技能工作流"
---

# 自動化範本

適用於常見自動化模式的複製即用食譜。每個範本都使用 Hermes 內建的 [cron 排程器](/docs/user-guide/features/cron) 進行時間觸發，以及 [webhook 平台](/docs/user-guide/messaging/webhooks) 進行事件驅動觸發。

每個範本都適用於**任何模型** — 不受單一供應商限制。

:::tip 三種觸發類型
| 觸發方式 | 如何運作 | 工具 |
|---------|-----|------|
| **排程 (Schedule)** | 按節奏運行（每小時、每晚、每週） | `cronjob` 工具或 `/cron` 斜線指令 |
| **GitHub 事件** | 在 PR 開啟、推送 (Push)、Issue、CI 結果時觸發 | Webhook 平台 (`hermes webhook subscribe`) |
| **API 呼叫** | 外部服務向您的端點發送 JSON POST 請求 | Webhook 平台（config.yaml 路由或 `hermes webhook subscribe`） |

這三種方式皆支援傳遞至 Telegram、Discord、Slack、SMS、電子郵件、GitHub 評論或本地檔案。
:::

---

## 開發工作流

### 每晚待辦事項分類 (Backlog Triage)

每晚對新的 Issue 進行標記、排序優先級並彙整摘要。將摘要發送至團隊頻道。

**觸發方式：** 排程（每晚）

```bash
hermes cron create "0 2 * * *" \
  "您是一位負責分類 NousResearch/hermes-agent GitHub 儲存庫的專案經理。

1. 執行：gh issue list --repo NousResearch/hermes-agent --state open --json number,title,labels,author,createdAt --limit 30
2. 識別過去 24 小時內開啟的 Issue
3. 針對每個新 Issue：
   - 建議優先級標籤 (P0-critical, P1-high, P2-medium, P3-low)
   - 建議類別標籤 (bug, feature, docs, security)
   - 撰寫一行分類備註
4. 總結：開啟的 Issue 總數、今日新增數量、按優先級分類

格式化為整潔的摘要。如果沒有新 Issue，請回應 [SILENT]。" \
  --name "每晚待辦事項分類" \
  --deliver telegram
```

### 自動 PR 程式碼審查

在每個 Pull Request 開啟時自動進行審查。直接在 PR 上發佈審查評論。

**觸發方式：** GitHub webhook

**選項 A — 動態訂閱 (CLI)：**

```bash
hermes webhook subscribe github-pr-review \
  --events "pull_request" \
  --prompt "審查此 Pull Request：
儲存庫：{repository.full_name}
PR #{pull_request.number}: {pull_request.title}
作者：{pull_request.user.login}
操作：{action}
Diff URL: {pull_request.diff_url}

使用此指令獲取 diff：curl -sL {pull_request.diff_url}

審查重點：
- 安全性問題（注入、身份驗證繞過、程式碼中的金鑰）
- 效能疑慮（N+1 查詢、無限制迴圈、記憶體洩漏）
- 程式碼品質（命名、重複、錯誤處理）
- 新行為是否缺少測試

發佈簡明扼要的審查。如果 PR 只是瑣碎的文件/錯字修正，請簡短說明。" \
  --skills "github-code-review" \
  --deliver github_comment
```

**選項 B — 靜態路由 (config.yaml)：**

```yaml
platforms:
  webhook:
    enabled: true
    extra:
      port: 8644
      secret: "your-global-secret"
      routes:
        github-pr-review:
          events: ["pull_request"]
          secret: "github-webhook-secret"
          prompt: |
            審查 PR #{pull_request.number}: {pull_request.title}
            儲存庫：{repository.full_name}
            作者：{pull_request.user.login}
            Diff URL: {pull_request.diff_url}
            針對安全性、效能和程式碼品質進行審查。
          skills: ["github-code-review"]
          deliver: "github_comment"
          deliver_extra:
            repo: "{repository.full_name}"
            pr_number: "{pull_request.number}"
```

接著在 GitHub 中：**Settings → Webhooks → Add webhook** → Payload URL: `http://your-server:8644/webhooks/github-pr-review`, Content type: `application/json`, Secret: `github-webhook-secret`, Events: **Pull requests**。

### 文件偏離偵測 (Docs Drift Detection)

每週掃描已合併的 PR，尋找需要更新文件的 API 變更。

**觸發方式：** 排程（每週）

```bash
hermes cron create "0 9 * * 1" \
  "掃描 NousResearch/hermes-agent 儲存庫以偵測文件偏離。

1. 執行：gh pr list --repo NousResearch/hermes-agent --state merged --json number,title,files,mergedAt --limit 30
2. 篩選過去 7 天內合併的 PR
3. 針對每個已合併的 PR，檢查是否修改了：
   - 工具定義 (tools/*.py) — 可能需要更新 docs/reference/tools-reference.md
   - CLI 指令 (hermes_cli/commands.py, hermes_cli/main.py) — 可能需要更新 docs/reference/cli-commands.md
   - 設定選項 (hermes_cli/config.py) — 可能需要更新 docs/user-guide/configuration.md
   - 環境變數 — 可能需要更新 docs/reference/environment-variables.md
4. 交叉比對：針對每個程式碼變更，檢查對應的文件頁面是否也在同一個 PR 中更新

報告程式碼已更改但文件未更改的落差。如果一切同步，請回應 [SILENT]。" \
  --name "文件偏離偵測" \
  --deliver telegram
```

### 依賴項安全性稽核

每日掃描專案依賴項中的已知漏洞。

**觸發方式：** 排程（每日）

```bash
hermes cron create "0 6 * * *" \
  "對 hermes-agent 專案執行依賴項安全性稽核。

1. cd ~/.hermes/hermes-agent && source .venv/bin/activate
2. 執行：pip audit --format json 2>/dev/null || pip audit 2>&1
3. 執行：npm audit --json 2>/dev/null（如果 website/ 目錄存在）
4. 檢查是否有 CVSS 分數 >= 7.0 的 CVE

如果發現漏洞：
- 列出每個漏洞的套件名稱、版本、CVE ID、嚴重程度
- 檢查是否有可用更新
- 註明是直接依賴還是間接依賴

如果沒有漏洞，請回應 [SILENT]。" \
  --name "依賴項稽核" \
  --deliver telegram
```

---

## DevOps 與監控

### 部署驗證

在每次部署後觸發煙霧測試 (Smoke Tests)。您的 CI/CD 管線在部署完成後向 webhook 發送 POST 請求。

**觸發方式：** API 呼叫 (webhook)

```bash
hermes webhook subscribe deploy-verify \
  --events "deployment" \
  --prompt "部署剛剛完成：
服務：{service}
環境：{environment}
版本：{version}
部署者：{deployer}

執行以下驗證步驟：
1. 檢查服務是否有回應：curl -s -o /dev/null -w '%{http_code}' {health_url}
2. 在最近的日誌中搜尋錯誤：檢查部署負載 (payload) 中是否有任何錯誤指標
3. 驗證版本是否匹配：curl -s {health_url}/version

報告：部署狀態（健康/降級/失敗）、回應時間、發現的任何錯誤。
如果健康，請保持簡短。如果降級或失敗，請提供詳細的診斷資訊。" \
  --deliver telegram
```

您的 CI/CD 管線觸發它：

```bash
curl -X POST http://your-server:8644/webhooks/deploy-verify \
  -H "Content-Type: application/json" \
  -H "X-Hub-Signature-256: sha256=$(echo -n '{"service":"api","environment":"prod","version":"2.1.0","deployer":"ci","health_url":"https://api.example.com/health"}' | openssl dgst -sha256 -hmac 'your-secret' | cut -d' ' -f2)" \
  -d '{"service":"api","environment":"prod","version":"2.1.0","deployer":"ci","health_url":"https://api.example.com/health"}'
```

### 警報分類 (Alert Triage)

將監控警報與最近的變更聯繫起來，草擬回應方案。適用於 Datadog、PagerDuty、Grafana 或任何可以發送 JSON POST 請求的警報系統。

**觸發方式：** API 呼叫 (webhook)

```bash
hermes webhook subscribe alert-triage \
  --prompt "收到監控警報：
警報：{alert.name}
嚴重程度：{alert.severity}
服務：{alert.service}
訊息：{alert.message}
時間戳記：{alert.timestamp}

調查：
1. 在網路上搜尋此錯誤模式的已知問題
2. 檢查這是否與最近的部署或設定更改有關
3. 草擬一份分類摘要，包含：
   - 可能的根本原因
   - 建議的初步應對步驟
   - 升級建議 (P1-P4)

請簡潔明瞭。此資訊將發送至值班頻道。" \
  --deliver slack
```

### 運行時間監控 (Uptime Monitor)

每 30 分鐘檢查一次端點。僅在服務斷線時通知。

**觸發方式：** 排程（每 30 分鐘）

```python title="~/.hermes/scripts/check-uptime.py"
import urllib.request, json, time

ENDPOINTS = [
    {"name": "API", "url": "https://api.example.com/health"},
    {"name": "Web", "url": "https://www.example.com"},
    {"name": "Docs", "url": "https://docs.example.com"},
]

results = []
for ep in ENDPOINTS:
    try:
        start = time.time()
        req = urllib.request.Request(ep["url"], headers={"User-Agent": "Hermes-Monitor/1.0"})
        resp = urllib.request.urlopen(req, timeout=10)
        elapsed = round((time.time() - start) * 1000)
        results.append({"name": ep["name"], "status": resp.getcode(), "ms": elapsed})
    except Exception as e:
        results.append({"name": ep["name"], "status": "DOWN", "error": str(e)})

down = [r for r in results if r.get("status") == "DOWN" or (isinstance(r.get("status"), int) and r["status"] >= 500)]
if down:
    print("OUTAGE DETECTED")
    for r in down:
        print(f"  {r['name']}: {r.get('error', f'HTTP {r[\"status\"]}')} ")
    print(f"\nAll results: {json.dumps(results, indent=2)}")
else:
    print("NO_ISSUES")
```

```bash
hermes cron create "every 30m" \
  "如果腳本報告 OUTAGE DETECTED，請總結哪些服務斷線並建議可能的原因。如果顯示 NO_ISSUES，請回應 [SILENT]。" \
  --script ~/.hermes/scripts/check-uptime.py \
  --name "運行時間監控" \
  --deliver telegram
```

---

## 研究與情報

### 競爭對手儲存庫偵察 (Competitive Repository Scout)

監控競爭對手的儲存庫，尋找有趣的 PR、功能和架構決策。

**觸發方式：** 排程（每日）

```bash
hermes cron create "0 8 * * *" \
  "偵察這些 AI 代理程式儲存庫在過去 24 小時內的顯著活動：

要檢查的儲存庫：
- anthropics/claude-code
- openai/codex
- All-Hands-AI/OpenHands
- Aider-AI/aider

針對每個儲存庫：
1. gh pr list --repo <repo> --state all --json number,title,author,createdAt,mergedAt --limit 15
2. gh issue list --repo <repo> --state open --json number,title,labels,createdAt --limit 10

重點關注：
- 正在開發的新功能
- 架構變更
- 我們可以學習的整合模式
- 可能也會影響我們的安全性修復

跳過例行性的依賴項更新和 CI 修復。如果沒有顯著內容，請回應 [SILENT]。
如果有發現，請按儲存庫組織並對每項進行簡要分析。" \
  --skills "competitive-pr-scout" \
  --name "競爭對手偵察" \
  --deliver telegram
```

### AI 新聞摘要

每週彙整 AI/ML 發展情況。

**觸發方式：** 排程（每週）

```bash
hermes cron create "0 9 * * 1" \
  "產生一份涵蓋過去 7 天的每週 AI 新聞摘要：

1. 在網路上搜尋主要的 AI 公告、模型發佈和研究突破
2. 在 GitHub 上搜尋熱門的 ML 儲存庫
3. 在 arXiv 上檢查關於語言模型和代理程式的高引用論文

結構：
## 頭條新聞 (3-5 個主要故事)
## 值得關注的論文 (2-3 篇論文及單句總結)
## 開源項目 (有趣的全新儲存庫或重大發佈)
## 行業動態 (融資、收購、發佈)

每項內容保持在 1-2 句話。包含連結。總字數在 600 字以內。" \
  --name "每週 AI 摘要" \
  --deliver telegram
```

### 包含筆記的論文摘要

每日掃描 arXiv 並將摘要儲存到您的筆記系統中。

**觸發方式：** 排程（每日）

```bash
hermes cron create "0 8 * * *" \
  "在 arXiv 上搜尋過去一天關於 'language model reasoning' 或 'tool-use agents' 的 3 篇最有趣的論文。針對每篇論文，建立一個 Obsidian 筆記，包含標題、作者、摘要總結、關鍵貢獻，以及與 Hermes Agent 開發的潛在相關性。" \
  --skills "arxiv,obsidian" \
  --name "論文摘要" \
  --deliver local
```

---

## GitHub 事件自動化

### Issue 自動標籤

自動為新 Issue 貼上標籤並進行回應。

**觸發方式：** GitHub webhook

```bash
hermes webhook subscribe github-issues \
  --events "issues" \
  --prompt "收到新的 GitHub Issue：
儲存庫：{repository.full_name}
Issue #{issue.number}: {issue.title}
作者：{issue.user.login}
操作：{action}
內文：{issue.body}
標籤：{issue.labels}

如果是新 Issue (action=opened)：
1. 仔細閱讀 Issue 標題和內文
2. 建議適當的標籤 (bug, feature, docs, security, question)
3. 如果是錯誤報告，檢查是否能從描述中識別受影響的元件
4. 發佈一個有幫助的初始回應，確認已收到 Issue

如果是標籤或指派變更，請回應 [SILENT]。" \
  --deliver github_comment
```

### CI 失敗分析

分析 CI 失敗並在 PR 上發佈診斷資訊。

**觸發方式：** GitHub webhook

```yaml
# config.yaml 路由
platforms:
  webhook:
    enabled: true
    extra:
      routes:
        ci-failure:
          events: ["check_run"]
          secret: "ci-secret"
          prompt: |
            CI 檢查失敗：
            儲存庫：{repository.full_name}
            檢查項：{check_run.name}
            狀態：{check_run.conclusion}
            PR: #{check_run.pull_requests.0.number}
            詳情 URL: {check_run.details_url}

            如果結論為 "failure"：
            1. 如果可存取，從詳情 URL 獲取日誌
            2. 識別失敗的可能原因
            3. 建議修復方案
            如果結論為 "success"，請回應 [SILENT]。
          deliver: "github_comment"
          deliver_extra:
            repo: "{repository.full_name}"
            pr_number: "{check_run.pull_requests.0.number}"
```

### 跨儲存庫自動移植變更

當一個儲存庫中的 PR 合併時，自動將等效變更移植到另一個儲存庫。

**觸發方式：** GitHub webhook

```bash
hermes webhook subscribe auto-port \
  --events "pull_request" \
  --prompt "來源儲存庫中的 PR 已合併：
儲存庫：{repository.full_name}
PR #{pull_request.number}: {pull_request.title}
作者：{pull_request.user.login}
操作：{action}
合併 Commit: {pull_request.merge_commit_sha}

如果操作為 'closed' 且 pull_request.merged 為 true：
1. 獲取 diff：curl -sL {pull_request.diff_url}
2. 分析變更內容
3. 確定是否需要將此變更移植到對應的 Go SDK
4. 如果是，建立分支，應用等效變更，並在目標儲存庫開啟 PR
5. 在新 PR 描述中引用原始 PR

如果操作不是 'closed' 或未合併，請回應 [SILENT]。" \
  --skills "github-pr-workflow" \
  --deliver log
```

---

## 商務營運

### Stripe 付款監控

追蹤付款事件並獲取失敗摘要。

**觸發方式：** API 呼叫 (webhook)

```bash
hermes webhook subscribe stripe-payments \
  --events "payment_intent.succeeded,payment_intent.payment_failed,charge.dispute.created" \
  --prompt "收到 Stripe 事件：
事件類型：{type}
金額：{data.object.amount} 分 ({data.object.currency})
客戶：{data.object.customer}
狀態：{data.object.status}

針對 payment_intent.payment_failed：
- 從 {data.object.last_payment_error} 中識別失敗原因
- 建議這是暫時性問題（重試）還是永久性問題（聯繫客戶）

針對 charge.dispute.created：
- 標記為緊急
- 總結爭議詳情

針對 payment_intent.succeeded：
- 僅需簡短確認

請保持回應簡潔，發送至營運頻道。" \
  --deliver slack
```

### 每日營收摘要

每天早晨彙整關鍵業務指標。

**觸發方式：** 排程（每日）

```bash
hermes cron create "0 8 * * *" \
  "產生早晨業務指標摘要。

在網路上搜尋：
1. 目前比特幣和乙太幣價格
2. S&P 500 狀態（盤前或前次收盤）
3. 過去 12 小時內任何重大的科技/AI 行業新聞

格式化為簡短的早晨簡報，最多 3-4 個重點。
以乾淨、易於掃描的訊息傳遞。" \
  --name "早晨簡報" \
  --deliver telegram
```

---

## 多技能工作流

### 安全性稽核管線

結合多個技能進行全面的每週安全性審查。

**觸發方式：** 排程（每週）

```bash
hermes cron create "0 3 * * 0" \
  "對 hermes-agent 程式碼庫執行全面的安全性稽核。

1. 檢查依賴項漏洞 (pip audit, npm audit)
2. 在程式碼庫中搜尋常見的安全性反模式：
   - 硬編碼的金鑰或 API key
   - SQL 注入向量（查詢中的字串格式化）
   - 路徑遍歷風險（檔案路徑中未經驗證的使用者輸入）
   - 不安全的反序列化 (pickle.loads, yaml.load 且未使用 SafeLoader)
3. 審查最近 7 天的 commit，尋找與安全性相關的變更
4. 檢查是否有任何新增的環境變數未被記錄在文件中

撰寫一份安全性報告，按嚴重程度（緊急、高、中、低）對發現的問題進行分類。
如果未發現任何問題，請報告健康狀況良好。" \
  --skills "codebase-security-audit" \
  --name "每週安全性稽核" \
  --deliver telegram
```

### 內容管線

按排程研究、草擬並準備內容。

**觸發方式：** 排程（每週）

```bash
hermes cron create "0 10 * * 3" \
  "研究並草擬一篇關於 AI 代理程式熱門主題的技術部落格文章大綱。

1. 在網路上搜尋本週討論最多的 AI 代理程式主題
2. 挑選一個與開源 AI 代理程式最相關且最有趣的主題
3. 建立大綱，包含：
   - 切入點/簡介角度
   - 3-4 個核心章節
   - 適合開發者的技術深度
   - 具有可操作性建議的結論
4. 將大綱儲存至 ~/drafts/blog-$(date +%Y%m%d).md

大綱保持在 300 字左右。這是一個起點，而非完成的貼文。" \
  --name "部落格大綱" \
  --deliver local
```

---

## 快速參考

### Cron 排程語法

| 表達式 | 意義 |
|-----------|---------|
| `every 30m` | 每 30 分鐘 |
| `every 2h` | 每 2 小時 |
| `0 2 * * *` | 每日凌晨 2:00 |
| `0 9 * * 1` | 每週一上午 9:00 |
| `0 9 * * 1-5` | 工作日上午 9:00 |
| `0 3 * * 0` | 每週日凌晨 3:00 |
| `0 */6 * * *` | 每 6 小時 |

### 傳遞目標

| 目標 | 標記 | 備註 |
|--------|------|-------|
| 同一聊天 | `--deliver origin` | 預設 — 傳遞至建立任務的地點 |
| 本地檔案 | `--deliver local` | 儲存輸出，不發送通知 |
| Telegram | `--deliver telegram` | 主頻道，或使用 `telegram:CHAT_ID` 指定特定頻道 |
| Discord | `--deliver discord` | 主頻道，或使用 `discord:CHANNEL_ID` |
| Slack | `--deliver slack` | 主頻道 |
| SMS | `--deliver sms:+15551234567` | 直接發送到電話號碼 |
| 特定執行緒 | `--deliver telegram:-100123:456` | Telegram 論壇主題 |

### Webhook 範本變數

| 變數 | 描述 |
|----------|-------------|
| `{pull_request.title}` | PR 標題 |
| `{issue.number}` | Issue 編號 |
| `{repository.full_name}` | `擁有者/儲存庫` |
| `{action}` | 事件操作（開啟、關閉等） |
| `{__raw__}` | 完整 JSON 負載（截斷至 4000 字元） |
| `{sender.login}` | 觸發事件的 GitHub 使用者 |

### [SILENT] 模式

當 cron 任務的回應包含 `[SILENT]` 時，傳遞會被抑制。使用此模式可以避免在例行性運行時收到通知噪音：

```
如果沒有發生值得注意的事情，請回應 [SILENT]。
```

這意味著您只有在代理程式有內容需要報告時才會收到通知。
