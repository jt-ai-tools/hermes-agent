---
sidebar_position: 5
title: "排程任務 (Cron)"
description: "使用自然語言安排自動化任務，透過單一 cron 工具進行管理，並可附加一或多項技能"
---

# 排程任務 (Cron)

使用自然語言或 Cron 表達式安排任務自動執行。Hermes 透過單一的 `cronjob` 工具提供排程管理，採用「動作導向式操作」，而非拆分成獨立的排程/列表/移除工具。

## 目前 Cron 的功能

Cron 任務可以：

- 安排單次或週期性重複任務
- 暫停、繼續、編輯、觸發及移除任務
- 為任務附加零個、一個或多個技能
- 將結果傳回原始聊天室、本地檔案或配置的平台目標
- 在全新的代理工作階段中執行，並使用標準的靜態工具列表

:::warning
由 Cron 執行的工作階段無法遞迴地建立更多 Cron 任務。Hermes 在 Cron 執行期間會停用排程管理工具，以防止產生失控的排程迴圈。
:::

## 建立排程任務

### 在聊天中使用 `/cron` 指令

```bash
/cron add 30m "提醒我檢查建置狀況"
/cron add "every 2h" "檢查伺服器狀態"
/cron add "every 1h" "摘要新的 feed 項目" --skill blogwatcher
/cron add "every 1h" "同時使用多個技能並結合結果" --skill blogwatcher --skill find-nearby
```

### 從獨立 CLI 建立

```bash
hermes cron create "every 2h" "檢查伺服器狀態"
hermes cron create "every 1h" "摘要新的 feed 項目" --skill blogwatcher
hermes cron create "every 1h" "同時使用多個技能並結合結果" \
  --skill blogwatcher \
  --skill find-nearby \
  --name "技能組合範例"
```

### 透過自然對話

像平常一樣要求 Hermes：

```text
每天早上 9 點，檢查 Hacker News 的 AI 新聞，並在 Telegram 上發送摘要給我。
```

Hermes 會在內部使用統一的 `cronjob` 工具。

## 由技能支援的 Cron 任務

Cron 任務可以在執行提示詞之前載入一或多個技能。

### 單一技能

```python
cronjob(
    action="create",
    skill="blogwatcher",
    prompt="檢查配置的 feeds 並摘要任何新內容。",
    schedule="0 9 * * *",
    name="早晨訂閱摘要",
)
```

### 多個技能

技能會依序載入。提示詞會成為疊加在這些技能之上的任務指令。

```python
cronjob(
    action="create",
    skills=["blogwatcher", "find-nearby"],
    prompt="尋找新的本地活動和附近的有趣地點，然後將它們結合成一份簡短摘要。",
    schedule="every 6h",
    name="在地生活簡報",
)
```

當您希望排程代理繼承可重複使用的流程，而不想將完整的技能文字塞進 Cron 提示詞本身時，這非常有用。

## 編輯任務

您無需刪除並重建任務即可進行修改。

### 聊天介面

```bash
/cron edit <job_id> --schedule "every 4h"
/cron edit <job_id> --prompt "使用修改後的任務說明"
/cron edit <job_id> --skill blogwatcher --skill find-nearby
/cron edit <job_id> --remove-skill blogwatcher
/cron edit <job_id> --clear-skills
```

### 獨立 CLI

```bash
hermes cron edit <job_id> --schedule "every 4h"
hermes cron edit <job_id> --prompt "使用修改後的任務說明"
hermes cron edit <job_id> --skill blogwatcher --skill find-nearby
hermes cron edit <job_id> --add-skill find-nearby
hermes cron edit <job_id> --remove-skill blogwatcher
hermes cron edit <job_id> --clear-skills
```

說明：

- 重複使用 `--skill` 會替換任務原有的技能列表
- `--add-skill` 會在現有列表中追加技能，而不會替換
- `--remove-skill` 會移除特定的附加技能
- `--clear-skills` 會移除所有附加技能

## 生命週期動作

Cron 任務現在擁有比單純建立/移除更完整的生命週期。

### 聊天介面

```bash
/cron list
/cron pause <job_id>
/cron resume <job_id>
/cron run <job_id>
/cron remove <job_id>
```

### 獨立 CLI

```bash
hermes cron list
hermes cron pause <job_id>
hermes cron resume <job_id>
hermes cron run <job_id>
hermes cron remove <job_id>
hermes cron status
hermes cron tick
```

功能說明：

- `pause` — 保留任務但停止排程
- `resume` — 重新啟用任務並計算下一次執行的時間
- `run` — 在下一次排程器檢查 (tick) 時觸發該任務
- `remove` — 徹底刪除任務

## 運作原理

**Cron 執行由閘道器守護行程 (Gateway Daemon) 處理。** 閘道器每 60 秒會觸發一次排程器檢查，並在隔離的代理工作階段中執行任何到期的任務。

```bash
hermes gateway install             # 安裝為使用者服務
sudo hermes gateway install --system   # Linux：安裝為伺服器開機自啟系統服務
hermes gateway                     # 或在前台執行

hermes cron list
hermes cron status
```

### 閘道器排程器行為

在每次檢查 (tick) 時，Hermes 會：

1. 從 `~/.hermes/cron/jobs.json` 載入任務
2. 檢查 `next_run_at` 是否早於或等於當前時間
3. 為每個到期的任務啟動一個全新的 `AIAgent` 工作階段
4. （選擇性地）在該新工作階段中注入一或多個附加技能
5. 執行提示詞直到完成
6. 傳遞最終回應
7. 更新執行詮釋資料 (metadata) 與下一次預定時間

位於 `~/.hermes/cron/.tick.lock` 的檔案鎖可防止重疊的排程器檢查重複執行同一批任務。

## 傳遞選項 (Delivery Options)

安排任務時，您可以指定輸出結果的目的地：

| 選項 | 描述 | 範例 |
|--------|-------------|---------|
| `"origin"` | 傳回任務建立之處 | 即時通訊平台的預設值 |
| `"local"` | 僅儲存至本地檔案 (`~/.hermes/cron/output/`) | CLI 的預設值 |
| `"telegram"` | Telegram 的 Home 頻道 | 使用 `TELEGRAM_HOME_CHANNEL` |
| `"telegram:123456"` | 特定 Telegram 聊天室（依 ID） | 直接傳遞 |
| `"telegram:-100123:17585"` | 特定 Telegram 主題 (Topic) | `chat_id:thread_id` 格式 |
| `"discord"` | Discord 的 Home 頻道 | 使用 `DISCORD_HOME_CHANNEL` |
| `"discord:#engineering"` | 特定 Discord 頻道 | 依頻道名稱 |
| `"slack"` | Slack 的 Home 頻道 | |
| `"whatsapp"` | WhatsApp Home | |
| `"signal"` | Signal | |
| `"matrix"` | Matrix Home Room | |
| `"mattermost"` | Mattermost Home 頻道 | |
| `"email"` | 電子郵件 | |
| `"sms"` | 透過 Twilio 發送簡訊 | |
| `"homeassistant"` | Home Assistant | |
| `"dingtalk"` | 釘釘 (DingTalk) | |
| `"feishu"` | 飛書 (Feishu/Lark) | |
| `"wecom"` | 企業微信 (WeCom) | |
| `"weixin"` | 微信 (WeChat) | |
| `"bluebubbles"` | BlueBubbles (iMessage) | |
| `"qqbot"` | QQ 機器人 (Tencent QQ) | |

代理的最終回應會自動傳遞。您不需要在 Cron 提示詞中呼叫 `send_message`。

### 回應包裝 (Response wrapping)

預設情況下，傳遞的 Cron 輸出會包裝頁首與頁尾，以便收件者辨識其來自排程任務：

```
Cronjob Response: Morning feeds
-------------

<此處為代理的輸出內容>

Note: The agent cannot see this message, and therefore cannot respond to it.
```

若要傳遞不含包裝的原始代理輸出，請將 `cron.wrap_response` 設定為 `false`：

```yaml
# ~/.hermes/config.yaml
cron:
  wrap_response: false
```

### 靜默抑制 (Silent suppression)

如果代理的最終回應以 `[SILENT]` 開頭，傳遞將被完全抑制。輸出仍會儲存在本地以供稽核（位於 `~/.hermes/cron/output/`），但不會向傳遞目標發送訊息。

這對於僅在發生問題時才需要報告的監控任務非常有用：

```text
檢查 nginx 是否正在執行。如果一切正常，僅回傳 [SILENT]。
否則，回報問題。
```

失敗的任務一律會傳遞，不受 `[SILENT]` 標記影響 — 僅成功執行且標記為靜默的任務會被抑制。

## 指令碼逾時 (Script timeout)

透過 `script` 參數附加的預執行指令碼，其預設逾時時間為 120 秒。如果您的指令碼需要更長的時間 — 例如，為了避免機器人偵測而加入隨機延遲 — 您可以調高此數值：

```yaml
# ~/.hermes/config.yaml
cron:
  script_timeout_seconds: 300   # 5 分鐘
```

或設定 `HERMES_CRON_SCRIPT_TIMEOUT` 環境變數。解析順序為：環境變數 → config.yaml → 預設 120 秒。

## 供應商恢復 (Provider recovery)

Cron 任務會繼承您配置的備援供應商與憑證池輪轉。如果主 API 金鑰遇到速率限制或供應商回傳錯誤，Cron 代理可以：

- **切換至備用供應商**：如果您在 `config.yaml` 中設定了 `fallback_providers`（或舊版的 `fallback_model`）。
- **輪轉至下一個憑證**：在同供應商的[憑證池 (Credential Pool)](/docs/user-guide/configuration#credential-pool-strategies) 中進行輪轉。

這意味著在高頻率或高峰時段執行的 Cron 任務會更具韌性 — 單一金鑰的速率限制不會導致整個執行失敗。

## 排程格式

代理的最終回應會自動傳遞 — 您**不需要**在 Cron 提示詞中為同一目的地包含 `send_message`。如果 Cron 執行期間呼叫 `send_message` 至排程器原本就會傳遞的相同目標，Hermes 會跳過該重複傳送，並告知模型將面向使用者的內容放在最終回應中。請僅在需要發送至額外或不同目標時才使用 `send_message`。

### 相對延遲（單次執行）

```text
30m     → 30 分鐘後執行一次
2h      → 2 小時後執行一次
1d      → 1 天後執行一次
```

### 間隔執行（週期重複）

```text
every 30m    → 每 30 分鐘執行一次
every 2h     → 每 2 小時執行一次
every 1d     → 每天執行一次
```

### Cron 表達式

```text
0 9 * * *       → 每天早上 9:00
0 9 * * 1-5     → 每個工作日早上 9:00
0 */6 * * *     → 每 6 小時執行一次
30 8 1 * *      → 每月 1 號 8:30 AM
0 0 * * 0       → 每週日午夜
```

### ISO 時間戳記

```text
2026-03-15T09:00:00    → 在 2026 年 3 月 15 日早上 9:00 執行一次
```

## 重複行為

| 排程類型 | 預設重複次數 | 行為 |
|--------------|----------------|----------|
| 單次執行 (`30m`, 時間戳記) | 1 | 執行一次 |
| 間隔執行 (`every 2h`) | forever (無限) | 持續執行直到被移除 |
| Cron 表達式 | forever (無限) | 持續執行直到被移除 |

您可以覆寫此行為：

```python
cronjob(
    action="create",
    prompt="...",
    schedule="every 2h",
    repeat=5,
)
```

## 透過程式管理任務

面向代理的 API 是單一工具：

```python
cronjob(action="create", ...)
cronjob(action="list")
cronjob(action="update", job_id="...")
cronjob(action="pause", job_id="...")
cronjob(action="resume", job_id="...")
cronjob(action="run", job_id="...")
cronjob(action="remove", job_id="...")
```

對於 `update`，傳遞 `skills=[]` 可移除所有附加技能。

## 任務儲存

任務存放在 `~/.hermes/cron/jobs.json`。任務執行的輸出會儲存在 `~/.hermes/cron/output/{job_id}/{timestamp}.md`。

儲存機制採用原子化檔案寫入 (Atomic file writes)，確保中斷的寫入不會留下損毀的任務檔案。

## 自給自足的提示詞依然重要

:::warning 重要
Cron 任務是在完全全新的代理工作階段中執行的。提示詞必須包含代理所需的一切資訊，除非該資訊已由附加技能提供。
:::

**錯誤範例：** `"檢查那個伺服器問題"`

**正確範例：** `"以使用者 'deploy' 身分 SSH 進入伺服器 192.168.1.100，使用 'systemctl status nginx' 檢查 nginx 是否正在執行，並確認 https://example.com 回傳 HTTP 200。"`

## 安全性

排程任務的提示詞在建立與更新時，皆會經過提示詞注入 (Prompt-injection) 與憑證外洩模式的掃描。包含隱形 Unicode 技巧、SSH 後門企圖或明顯機密外洩負載的提示詞將被封鎖。
