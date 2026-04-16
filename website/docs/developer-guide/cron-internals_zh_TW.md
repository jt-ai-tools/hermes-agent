---
sidebar_position: 11
title: "Cron 內部運作機制"
description: "Hermes 如何儲存、排程、編輯、暫停、載入技能以及交付 Cron 任務"
---

# Cron 內部運作機制

Cron 子系統提供排程任務執行功能 — 從簡單的單次延遲到具有技能注入和跨平台交付的重複性 Cron 表達式任務。

## 關鍵檔案

| 檔案 | 用途 |
|------|---------|
| `cron/jobs.py` | 任務模型、儲存、對 `jobs.json` 的不可分割（Atomic）讀寫 |
| `cron/scheduler.py` | 排程器迴圈 — 到期任務偵測、執行、重複追蹤 |
| `tools/cronjob_tools.py` | 面向模型的 `cronjob` 工具註冊與處理常式 |
| `gateway/run.py` | Gateway 整合 — 在長期運作的迴圈中進行 Cron 週期觸發 |
| `hermes_cli/cron.py` | CLI `hermes cron` 子命令 |

## 排程模型

支援四種排程格式：

| 格式 | 範例 | 行為 |
|--------|---------|----------|
| **相對延遲** | `30m`, `2h`, `1d` | 單次執行，在指定時間後觸發 |
| **間隔** | `every 2h`, `every 30m` | 週期性，以固定間隔觸發 |
| **Cron 表達式** | `0 9 * * *` | 標準 5 欄位 Cron 語法（分、時、日、月、週） |
| **ISO 時間戳記** | `2025-01-15T09:00:00` | 單次執行，在確切時間觸發 |

面向模型的操作介面是單一的 `cronjob` 工具，包含動作風格的操作：`create`, `list`, `update`, `pause`, `resume`, `run`, `remove`。

## 任務儲存

任務儲存於 `~/.hermes/cron/jobs.json`，採用不可分割的寫入語意（寫入暫存檔後重新命名）。每條任務記錄包含：

```json
{
  "id": "a1b2c3d4e5f6",
  "name": "Daily briefing",
  "prompt": "Summarize today's AI news and funding rounds",
  "schedule": {
    "kind": "cron",
    "expr": "0 9 * * *",
    "display": "0 9 * * *"
  },
  "skills": ["ai-funding-daily-report"],
  "deliver": "telegram:-1001234567890",
  "repeat": {
    "times": null,
    "completed": 42
  },
  "state": "scheduled",
  "enabled": true,
  "next_run_at": "2025-01-16T09:00:00Z",
  "last_run_at": "2025-01-15T09:00:00Z",
  "last_status": "ok",
  "created_at": "2025-01-01T00:00:00Z",
  "model": null,
  "provider": null,
  "script": null
}
```

### 任務生命週期狀態

| 狀態 | 意義 |
|-------|---------|
| `scheduled` | 啟用中，將在下一個排程時間觸發 |
| `paused` | 已暫停 — 在恢復前不會觸發 |
| `completed` | 重複次數已用罄或是已觸發的單次任務 |
| `running` | 正在執行中（過渡狀態） |

### 回溯相容性

舊有的任務可能只有單一 `skill` 欄位而非 `skills` 陣列。排程器在載入時會進行正規化 — 將單一 `skill` 提升為 `skills: [skill]`。

## 排程器執行階段

### 週期觸發（Tick Cycle）

排程器會定期執行週期觸發（預設：每 60 秒）：

```text
tick()
  1. 獲取排程器鎖定（防止重疊觸發）
  2. 從 jobs.json 載入所有任務
  3. 篩選出到期任務 (next_run <= now 且 state == "scheduled")
  4. 針對每個到期任務：
     a. 將狀態設為 "running"
     b. 建立全新的 AIAgent 工作階段（無對話歷史）
     c. 按順序載入附加的技能（作為使用者訊息注入）
     d. 透過代理人執行任務提示詞
     e. 將回應交付至設定的目標
     f. 更新執行計數，計算下次執行時間
     g. 如果重複次數用罄 → 狀態 = "completed"
     h. 否則 → 狀態 = "scheduled"
  5. 將更新後的任務寫回 jobs.json
  6. 釋放排程器鎖定
```

### Gateway 整合

在 Gateway 模式下，排程器觸發會整合到 Gateway 的主事件迴圈中。Gateway 會在其定期維護週期中呼叫 `scheduler.tick()`，與訊息處理並行運作。

在 CLI 模式下，Cron 任務僅在執行 `hermes cron` 命令或處於活動 CLI 工作階段時才會觸發。

### 全新工作階段隔離

每個 Cron 任務都在完全獨立的代理人工作階段中執行：

- 無先前執行的對話歷史記錄
- 無先前 Cron 執行的記憶（除非已持久化到記憶體/檔案中）
- 提示詞必須是自給自足的 — Cron 任務無法提出釐清性問題
- `cronjob` 工具集會被禁用（遞迴防護）

## 技能支援的任務

Cron 任務可以透過 `skills` 欄位附加一個或多個技能。執行時：

1. 技能依指定順序載入
2. 每個技能的 SKILL.md 內容作為上下文注入
3. 任務提示詞被附加為任務指令
4. 代理人處理組合後的技能上下文 + 提示詞

這實現了可重複使用且經過測試的工作流程，而無需將完整指令貼入 Cron 提示詞。例如：

```
建立每日融資報告 → 附加 "ai-funding-daily-report" 技能
```

### 指令碼支援的任務

任務還可以透過 `script` 欄位附加 Python 指令碼。指令碼在每次代理人輪次 *之前* 執行，其標準輸出（stdout）作為上下文注入提示詞。這支援資料收集和變更偵測模式：

```python
# ~/.hermes/scripts/check_competitors.py
import requests, json
# 獲取競爭對手的發佈說明，與上次執行進行比對
# 將摘要印至 stdout — 代理人分析並報告
```

指令碼逾時預設為 120 秒。`_get_script_timeout()` 透過三層鏈條解析限制：

1. **模組層級覆寫** — `_SCRIPT_TIMEOUT`（用於測試/猴子補丁）。僅在與預設值不同時使用。
2. **環境變數** — `HERMES_CRON_SCRIPT_TIMEOUT`
3. **設定檔** — `config.yaml` 中的 `cron.script_timeout_seconds`（透過 `load_config()` 讀取）
4. **預設值** — 120 秒

### 供應商復原

`run_job()` 將使用者設定的備援供應商（Fallback Providers）和憑證池傳遞到 `AIAgent` 實例中：

- **備援供應商** — 從 `config.yaml` 讀取 `fallback_providers`（列表）或 `fallback_model`（舊式字典），符合 Gateway 的 `_load_fallback_model()` 模式。作為 `fallback_model=` 傳遞給 `AIAgent.__init__`，後者會將兩種格式正規化為備援鏈。
- **憑證池** — 透過 `agent.credential_pool` 中的 `load_pool(provider)` 使用解析後的執行階段供應商名稱進行載入。僅在池中有憑證時傳遞（`pool.has_credentials()`）。這支援在 429/費率限制錯誤時進行同供應商的金鑰輪替。

這鏡像了 Gateway 的行為 — 若無此機制，Cron 代理人將在遇到費率限制時直接失敗，而不會嘗試復原。

## 交付模型

Cron 任務結果可以交付至任何支援的平台：

| 目標 | 語法 | 範例 |
|--------|--------|---------|
| 來源聊天 | `origin` | 交付至建立任務時所在的聊天 |
| 本地檔案 | `local` | 儲存至 `~/.hermes/cron/output/` |
| Telegram | `telegram` 或 `telegram:<chat_id>` | `telegram:-1001234567890` |
| Discord | `discord` 或 `discord:#channel` | `discord:#engineering` |
| Slack | `slack` | 交付至 Slack 主頻道 |
| WhatsApp | `whatsapp` | 交付至 WhatsApp 首頁 |
| Signal | `signal` | 交付至 Signal |
| Matrix | `matrix` | 交付至 Matrix 主房間 |
| Mattermost | `mattermost` | 交付至 Mattermost 首頁 |
| Email | `email` | 透過電子郵件交付 |
| SMS | `sms` | 透過簡訊交付 |
| Home Assistant | `homeassistant` | 交付至 HA 對話 |
| DingTalk | `dingtalk` | 交付至釘釘 |
| Feishu | `feishu` | 交付至飛書 |
| WeCom | `wecom` | 交付至企業微信 |
| Weixin | `weixin` | 交付至微信（WeChat） |
| BlueBubbles | `bluebubbles` | 透過 BlueBubbles 交付至 iMessage |
| QQ Bot | `qqbot` | 透過官方 API v2 交付至 QQ（騰訊） |

對於 Telegram 主題（Topics），請使用格式 `telegram:<chat_id>:<thread_id>`（例如：`telegram:-1001234567890:17585`）。

### 回應封裝

預設情況下（`cron.wrap_response: true`），Cron 交付內容會封裝：
- 識別 Cron 任務名稱與任務內容的標頭
- 說明代理人在對話中無法看到所交付訊息的註腳

Cron 回應中的 `[SILENT]` 前綴會完全抑制交付 — 適用於僅需寫入檔案或執行副作用的任務。

### 工作階段隔離

Cron 交付內容**不會**鏡像到 Gateway 工作階段的對話歷史中。它們僅存在於 Cron 任務自己的工作階段中。這可以防止目標聊天對話中出現訊息交替違規的情況。

## 遞迴防護

Cron 執行的工作階段會禁用 `cronjob` 工具集。這可以防止：
- 排程任務建立新的 Cron 任務
- 可能導致 Token 使用量爆炸的遞迴排程
- 從任務內部意外修改任務排程

## 鎖定機制

排程器使用基於檔案的鎖定，以防止重疊的觸發週期兩次執行同一批到期任務。這在 Gateway 模式中非常重要，因為如果前一個觸發週期的執行時間超過了觸發間隔，多個維護週期可能會發生重疊。

## CLI 介面

`hermes cron` CLI 提供直接的任務管理功能：

```bash
hermes cron list                    # 顯示所有任務
hermes cron create                  # 互動式建立任務 (別名: add)
hermes cron edit <job_id>           # 編輯任務設定
hermes cron pause <job_id>          # 暫停執行中的任務
hermes cron resume <job_id>         # 恢復已暫停的任務
hermes cron run <job_id>            # 觸發立即執行
hermes cron remove <job_id>         # 刪除任務
```

## 相關文件

- [Cron 功能指南](/docs/user-guide/features/cron)
- [Gateway 內部運作機制](./gateway-internals.md)
- [代理人迴圈內部運作機制](./agent-loop.md)
