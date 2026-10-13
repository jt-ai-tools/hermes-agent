---
sidebar_position: 12
title: "Cron 故障排除"
description: "診斷並修復常見的 Hermes cron 問題 — 任務未觸發、傳遞失敗、技能載入錯誤以及效能問題"
---

# Cron 故障排除

當 cron 任務（Job）未按預期運作時，請依序進行以下檢查。大多數問題都屬於這四類：時間、傳遞、權限或技能載入。

---

## 任務未觸發

### 檢查 1：驗證任務是否存在且處於活動狀態

```bash
hermes cron list
```

尋找該任務並確認其狀態為 `[active]`（而非 `[paused]` 或 `[completed]`）。如果顯示為 `[completed]`，表示重複次數可能已用盡 — 請編輯任務以重置。

### 檢查 2：確認排程設定正確

格式錯誤的排程會被靜默地視為單次執行或直接被拒絕。請測試您的表達式：

| 您的表達式 | 應評估為 |
|----------------|-------------------|
| `0 9 * * *` | 每天上午 9:00 |
| `0 9 * * 1` | 每週一上午 9:00 |
| `every 2h` | 從現在起每 2 小時一次 |
| `30m` | 從現在起 30 分鐘後 |
| `2025-06-01T09:00:00` | UTC 時間 2025 年 6 月 1 日上午 9:00 |

如果任務僅觸發一次隨即從列表中消失，則表示它是單次排程（如 `30m`, `1d` 或 ISO 時間戳記） — 這是正常行為。

### 檢查 3：閘道 (Gateway) 是否正在運行？

Cron 任務是由閘道的背景計時執行緒觸發的，該執行緒每 60 秒跳動一次。一般的 CLI 聊天對話**不會**自動觸發 cron 任務。

如果您希望任務自動觸發，則需要運行閘道（`hermes gateway` 或 `hermes serve`）。若要進行單次偵錯，您可以使用 `hermes cron tick` 手動觸發一次計時跳動。

### 檢查 4：檢查系統時鐘和時區

任務使用本地時區。如果您的機器時鐘錯誤或處於非預期的時區，任務將在錯誤的時間觸發。請驗證：

```bash
date
hermes cron list   # 比較 next_run 時間與本地時間
```

---

## 傳遞失敗

### 檢查 1：驗證傳遞目標 (Deliver Target) 是否正確

傳遞目標區分大小寫，且需要配置正確的平台。配置錯誤的目標會導致回應被靜默捨棄。

| 目標 | 需要設定 |
|--------|----------|
| `telegram` | `~/.hermes/.env` 中的 `TELEGRAM_BOT_TOKEN` |
| `discord` | `~/.hermes/.env` 中的 `DISCORD_BOT_TOKEN` |
| `slack` | `~/.hermes/.env` 中的 `SLACK_BOT_TOKEN` |
| `whatsapp` | 已配置 WhatsApp 閘道 |
| `signal` | 已配置 Signal 閘道 |
| `matrix` | 已配置 Matrix 主伺服器 |
| `email` | `config.yaml` 中已配置 SMTP |
| `sms` | 已配置 SMS 供應商 |
| `local` | `~/.hermes/cron/output/` 的寫入權限 |
| `origin` | 傳遞至建立該任務的聊天視窗 |

其他支援的平台包括 `mattermost`、`homeassistant`、`dingtalk`、`feishu` (飛書)、`wecom` (企微)、`weixin` (微信)、`bluebubbles`、`qqbot` 和 `webhook`。您也可以使用 `platform:chat_id` 語法指定特定聊天（例如 `telegram:-1001234567890`）。

即使傳遞失敗，任務仍會運行 — 只是結果不會發送到任何地方。請檢查 `hermes cron list` 中的 `last_error` 欄位（若可用）以獲取更新資訊。

### 檢查 2：檢查 `[SILENT]` 的使用情況

如果您的 cron 任務沒有產生任何輸出，或者代理程式以 `[SILENT]` 回應，傳遞將會被抑制。這對於監控任務是刻意設計的 — 但請確保您的提示詞沒有意外地抑制了所有內容。

如果提示詞寫著「如果沒有任何變更，請回應 [SILENT]」，它也會靜默地吞掉非空回應。請檢查您的條件邏輯。

### 檢查 3：平台 Token 權限

每個即時通訊平台的機器人都需要特定權限才能接收訊息。如果傳遞靜默失敗：

- **Telegram**：機器人必須是目標群組/頻道的管理員。
- **Discord**：機器人必須擁有在目標頻道發送訊息的權限。
- **Slack**：機器人必須已加入工作區並擁有 `chat:write` 權限範圍。

### 檢查 4：回應封裝 (Response Wrapping)

預設情況下，cron 回應會被封裝在頁首和頁尾中（`config.yaml` 中的 `cron.wrap_response: true`）。某些平台或整合可能無法很好地處理這一點。若要停用：

```yaml
cron:
  wrap_response: false
```

---

## 技能載入失敗

### 檢查 1：驗證技能是否已安裝

```bash
hermes skills list
```

技能必須先安裝才能附加到 cron 任務。如果缺少技能，請先使用 `hermes skills install <skill-name>` 或透過 CLI 中的 `/skills` 進行安裝。

### 檢查 2：檢查技能名稱與技能資料夾名稱

技能名稱區分大小寫，且必須與已安裝技能的資料夾名稱完全匹配。如果您的任務指定了 `ai-funding-daily-report`，但技能資料夾是 `ai-funding-daily-report`，請從 `hermes skills list` 確認確切名稱。

### 檢查 3：需要互動工具的技能

Cron 任務在執行時會停用 `cronjob`、`messaging` 和 `clarify` 工具集。這可以防止遞迴建立 cron、直接發送訊息（傳遞由排程器處理）以及互動式提示。如果某個技能依賴這些工具集，它將無法在 cron 上下文中運作。

請檢查技能的文件以確認它是否支援非互動（無頭/Headless）模式。

### 檢查 4：多技能順序

使用多個技能時，它們會按順序載入。如果技能 A 依賴於技能 B 的上下文，請確保 B 先載入：

```bash
/cron add "0 9 * * *" "..." --skill context-skill --skill target-skill
```

在此範例中，`context-skill` 會在 `target-skill` 之前載入。

---

## 任務錯誤與失敗

### 檢查 1：查看最近的任務輸出

如果任務運行後失敗，您可以在以下位置找到錯誤上下文：

1. 任務傳遞到的聊天視窗（如果傳遞成功）
2. `~/.hermes/logs/agent.log` 中的排程器訊息（或 `errors.log` 中的警告訊息）
3. 透過 `hermes cron list` 查看任務的 `last_run` 元數據

### 檢查 2：常見錯誤模式

**腳本顯示 "No such file or directory"**
`script` 路徑必須是絕對路徑（或相對於 Hermes 設定目錄的路徑）。驗證方式：
```bash
ls ~/.hermes/scripts/your-script.py   # 必須存在
hermes cron edit <job_id> --script ~/.hermes/scripts/your-script.py
```

**任務執行時顯示 "Skill not found"**
技能必須安裝在運行排程器的機器上。如果您在不同機器之間移動，技能不會自動同步 — 請使用 `hermes skills install <skill-name>` 重新安裝。

**任務運行但未傳遞任何內容**
可能是傳遞目標問題（見上方的「傳遞失敗」章節）或回應被靜默抑制 (`[SILENT]`)。

**任務掛起或逾時**
排程器使用基於非活動狀態的逾時機制（預設為 600 秒，可透過 `HERMES_CRON_TIMEOUT` 環境變數配置，設定為 `0` 表示無限制）。只要代理程式正在主動調用工具，它就可以持續運行 — 計時器僅在持續不活動後才會觸發。耗時較長的任務應使用腳本處理資料收集，並僅傳遞最終結果。

### 檢查 3：鎖定爭用 (Lock Contention)

排程器使用基於檔案的鎖定機制來防止計時跳動重疊。如果運行了兩個閘道實例（或 CLI 對話與閘道發生衝突），任務可能會延遲或被跳過。

刪除重複的閘道進程：
```bash
ps aux | grep hermes
# 刪除重複進程，僅保留一個
```

### 檢查 4：jobs.json 的權限

任務儲存在 `~/.hermes/cron/jobs.json`。如果您的使用者無法讀取或寫入此檔案，排程器將靜默失敗：

```bash
ls -la ~/.hermes/cron/jobs.json
chmod 600 ~/.hermes/cron/jobs.json   # 應由您的使用者擁有
```

---

## 效能問題

### 任務啟動緩慢

每個 cron 任務都會建立一個全新的 AIAgent 對話，這可能涉及供應商身份驗證和模型載入。對於對時間要求嚴格的排程，請預留緩衝時間（例如使用 `0 8 * * *` 而非 `0 9 * * *`）。

### 過多重疊任務

排程器在每次計時跳動內按順序執行任務。如果多個任務同時到期，它們會一個接一個地運行。請考慮錯開排程（例如分別設定為 `0 9 * * *` 和 `5 9 * * *` 而非同時設定在 `0 9 * * *`）以避免延遲。

### 龐大的腳本輸出

腳本輸出數 MB 的內容會拖慢代理程式速度並可能達到 token 限制。請在腳本層級進行過濾/總結 — 僅輸出代理程式進行推理所需的內容。

---

## 診斷指令

```bash
hermes cron list                    # 顯示所有任務、狀態、下次運行時間
hermes cron run <job_id>            # 排定在下次計時跳動時運行（用於測試）
hermes cron edit <job_id>           # 修復配置問題
hermes logs                         # 查看最近的 Hermes 日誌
hermes skills list                  # 驗證已安裝的技能
```

---

## 獲取更多協助

如果您已閱讀本指南但問題仍然存在：

1. 使用 `hermes cron run <job_id>` 運行任務（將在下次閘道計時跳動時觸發），並觀察聊天輸出中的錯誤。
2. 檢查 `~/.hermes/logs/agent.log` 以獲取排程器訊息，並檢查 `~/.hermes/logs/errors.log` 以獲取警告訊息。
3. 在 [github.com/NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) 提交 Issue，並提供以下資訊：
   - 任務 ID 和排程設定
   - 傳遞目標
   - 預期結果 vs. 實際發生的情況
   - 日誌中相關的錯誤訊息

---

*如需完整的 cron 參考，請參閱 [使用 Cron 自動化一切](/docs/guides/automate-with-cron) 以及 [排程任務 (Cron)](/docs/user-guide/features/cron)。*
