# Hermes Agent 自三月起就已具備「常式」（Routines）功能

Anthropic 剛剛發表了 [Claude Code Routines](https://claude.com/blog/introducing-routines-in-claude-code) —— 包含排程任務、GitHub 事件觸發以及 API 觸發的代理程式執行。這結合了提示詞 + 儲存庫 + 連接器，並在他們的基礎設施上執行。

這是一個很好的功能。而我們在兩個月前就已經推出了。

---

## 三種觸發類型 —— 並列比較

Claude Code Routines 提供三種觸發自動化的方式：

**1. 排程（cron）**
> 「每天凌晨 2 點：從 Linear 抓取最前面的 bug，嘗試修復並開啟草稿 PR。」

Hermes 的對應功能 —— 現已可用：
```bash
hermes cron create "0 2 * * *" \
  "從問題追蹤器抓取最前面的 bug，嘗試修復並開啟草稿 PR。" \
  --name "每晚 bug 修復" \
  --deliver telegram
```

**2. GitHub 事件（webhook）**
> 「標記接觸到 /auth-provider 模組的 PR，並發布到 #auth-changes。」

Hermes 的對應功能 —— 現已可用：
```bash
hermes webhook subscribe auth-watch \
  --events "pull_request" \
  --prompt "PR #{pull_request.number}: {pull_request.title} 由 {pull_request.user.login} 提交。檢查它是否涉及 auth-provider 模組。如果是，總結其變更。" \
  --deliver slack
```

**3. API 觸發**
> 「讀取警報內容，找到負責的服務，並將分級總結發布到 #oncall。」

Hermes 的對應功能 —— 現已可用：
```bash
hermes webhook subscribe alert-triage \
  --prompt "警報：{alert.name} — 嚴重性：{alert.severity}。尋找負責的服務並進行調查，發布包含建議初步步驟的分級總結。" \
  --deliver slack
```

他們部落格文章中的每一個案例 —— 待辦清單分級、文件偏差、部署驗證、警報關聯、程式庫移植、客製化 PR 審查 —— 都有現成的 Hermes 實作方式。不需要新功能，自 2026 年 3 月起就已具備。

---

## 有何不同

| | Claude Code Routines | Hermes Agent |
|---|---|---|
| **排程任務** | ✅ 基於排程 | ✅ 任何 cron 表達式 + 人類可讀的時間間隔 |
| **GitHub 觸發** | ✅ PR、Issue、Push 事件 | ✅ 透過 Webhook 訂閱任何 GitHub 事件 |
| **API 觸發** | ✅ POST 到唯一端點 | ✅ POST 到具備 HMAC 認證的 Webhook 路由 |
| **MCP 連接器** | ✅ 原生連接器 | ✅ 完整的 MCP 用戶端支援 |
| **腳本預處理** | ❌ | ✅ 在代理程式之前執行 Python 腳本，注入上下文 |
| **技能鏈結** | ❌ | ✅ 每次自動化可載入多個技能 |
| **每日限制** | 5-25 次執行/日 | **無限制** |
| **模型選擇** | 僅限 Claude | **任何模型** — Claude, GPT, Gemini, DeepSeek, Qwen, 本地模型 |
| **傳送目標** | GitHub 評論 | Telegram, Discord, Slack, SMS, 電子郵件, GitHub 評論, Webhooks, 本地檔案 |
| **基礎設施** | Anthropic 的伺服器 | **您的基礎設施** — VPS、家庭伺服器、筆記型電腦 |
| **數據所在地** | Anthropic 的雲端 | **您的機器** |
| **成本** | Pro/Max/Team/Enterprise 訂閱 | 您的 API 金鑰，您的費率 |
| **開源** | 否 | **是** — MIT 授權 |

---

## Hermes 能做但 Routines 做不到的事

### 腳本注入

在代理程式執行*之前*跑一段 Python 腳本。腳本的標準輸出（stdout）會成為上下文。腳本負責機械性的工作（抓取、比對差異、運算）；代理程式則負責推理。

```bash
hermes cron create "every 1h" \
  "如果檢測到變更（CHANGE DETECTED），總結變更內容。如果沒有變更（NO_CHANGE），回覆 [SILENT]。" \
  --script ~/.hermes/scripts/watch-site.py \
  --name "定價監控" \
  --deliver telegram
```

`[SILENT]` 模式意味著只有在真正有事情發生時，您才會收到通知。沒有垃圾郵件。

### 多技能工作流

將專門的技能鏈結在一起。每個技能教導代理程式一個特定的能力，而提示詞則將它們聯繫起來。

```bash
hermes cron create "0 8 * * *" \
  "在 arXiv 上搜尋關於語言模型推理的論文。將排名前 3 的論文儲存為 Obsidian 筆記。" \
  --skills "arxiv,obsidian" \
  --name "論文摘要"
```

### 隨處傳送

一個自動化，任何目的地：

```bash
--deliver telegram                      # Telegram 主頻道
--deliver discord                       # Discord 主頻道  
--deliver slack                         # Slack 頻道
--deliver sms:+15551234567              # 簡訊
--deliver telegram:-1001234567890:42    # 特定的 Telegram 論壇主題
--deliver local                         # 儲存到檔案，不發送通知
```

### 模型無關

您的每晚分級工作可以在 Claude 上執行。您的部署驗證可以在 GPT 上執行。您的成本敏感型監控則可以在 DeepSeek 或本地模型上執行。同樣的自動化系統，任何後端。

---

## 限制說明了一切

Claude Code Routines：Pro 版**每天 5 個常式**。Enterprise 版 **25 個**。這是他們的天花板。

Hermes 沒有每日限制。如果您願意，每天可以執行 500 個自動化任務。唯一的限制是您的 API 預算，而且您可以選擇針對哪些任務使用哪些模型。

每晚在 Sonnet 上進行待辦清單分級的成本大約為 0.02-0.05 美元。在 DeepSeek 上的監控檢查成本則不到一美分。經濟權在您手中。

---

## 開始使用

Hermes Agent 是開源且免費的。自動化基礎設施 —— cron 排程器、Webhook 平台、技能系統、多平台傳送 —— 都已內建。

```bash
pip install hermes-agent
hermes setup
```

在 30 秒內設定一個排程任務：
```bash
hermes cron create "0 9 * * 1" \
  "生成每週 AI 新聞摘要。在網路上搜尋重大公告、熱門儲存庫和知名論文。保持在 500 字以內並附上連結。" \
  --name "每週摘要" \
  --deliver telegram
```

在 60 秒內設定一個 GitHub Webhook：
```bash
hermes gateway setup    # 啟用 webhooks
hermes webhook subscribe pr-review \
  --events "pull_request" \
  --prompt "審查 PR #{pull_request.number}: {pull_request.title}" \
  --skills "github-code-review" \
  --deliver github_comment
```

完整自動化範本庫：[hermes-agent.nousresearch.com/docs/guides/automation-templates](https://hermes-agent.nousresearch.com/docs/guides/automation-templates)

文件：[hermes-agent.nousresearch.com](https://hermes-agent.nousresearch.com)

GitHub：[github.com/NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)

---

*Hermes Agent 由 [Nous Research](https://nousresearch.com) 打造。開源、模型無關，在您的基礎設施上執行。*
