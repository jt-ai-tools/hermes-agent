---
sidebar_position: 11
title: "使用 Cron 自動化一切"
description: "使用 Hermes cron 的真實自動化模式 — 監測、報告、管線和多技能工作流"
---

# 使用 Cron 自動化一切

[每日簡報機器人教學](/docs/guides/daily-briefing-bot) 涵蓋了基礎知識。本指南將更進一步 — 提供五個您可以為自己的工作流量身打造的真實自動化模式。

如需完整的功能參考，請參閱 [排程任務 (Cron)](/docs/user-guide/features/cron)。

:::info 核心概念
Cron 任務在全新的代理程式對話中運行，不會繼承您目前的聊天記憶。提示詞（Prompt）必須是**完全自給自足的** — 包含代理程式需要知道的一切資訊。
:::

---

## 模式 1：網站變更監測器

監視一個 URL 的變更，並且只有在內容不同時才收到通知。

`script` 參數是這裡的秘密武器。在每次執行前都會運行一個 Python 腳本，其標準輸出（stdout）會成為代理程式的上下文。腳本負責機械性的工作（抓取、比對）；代理程式則負責推理（這個變更有趣嗎？）。

建立監測腳本：

```bash
mkdir -p ~/.hermes/scripts
```

```python title="~/.hermes/scripts/watch-site.py"
import hashlib, json, os, urllib.request

URL = "https://example.com/pricing"
STATE_FILE = os.path.expanduser("~/.hermes/scripts/.watch-site-state.json")

# 抓取目前內容
req = urllib.request.Request(URL, headers={"User-Agent": "Hermes-Monitor/1.0"})
content = urllib.request.urlopen(req, timeout=30).read().decode()
current_hash = hashlib.sha256(content.encode()).hexdigest()

# 載入先前的狀態
prev_hash = None
if os.path.exists(STATE_FILE):
    with open(STATE_FILE) as f:
        prev_hash = json.load(f).get("hash")

# 儲存目前狀態
with open(STATE_FILE, "w") as f:
    json.dump({"hash": current_hash, "url": URL}, f)

# 輸出給代理程式
if prev_hash and prev_hash != current_hash:
    print(f"CHANGE DETECTED on {URL}")
    print(f"Previous hash: {prev_hash}")
    print(f"Current hash: {current_hash}")
    print(f"\nCurrent content (first 2000 chars):\n{content[:2000]}")
else:
    print("NO_CHANGE")
```

設定 Cron 任務：

```bash
/cron add "every 1h" "如果腳本輸出顯示 CHANGE DETECTED，請總結頁面上更改的內容以及為什麼它很重要。如果顯示 NO_CHANGE，請僅回應 [SILENT]。" --script ~/.hermes/scripts/watch-site.py --name "價格監測" --deliver telegram
```

:::tip [SILENT] 小技巧
當代理程式的最終回應包含 `[SILENT]` 時，傳遞會被抑制。這意味著您只有在真正發生事情時才會收到通知 — 不會在安靜時段收到垃圾訊息。
:::

---

## 模式 2：每週報告

將來自多個來源的資訊彙編成格式化的摘要。此任務每週運行一次，並發送到您的主頻道。

```bash
/cron add "0 9 * * 1" "產生一份每週報告，內容涵蓋：

1. 在網路上搜尋過去一週前 5 大 AI 新聞故事
2. 在 GitHub 上搜尋 'machine-learning' 主題中的熱門儲存庫
3. 查看 Hacker News 上討論最多的 AI/ML 貼文

格式化為乾淨的摘要，每個來源都有對應的章節。包含連結。
字數控制在 500 字以內 — 僅強調重要內容。" --name "每週 AI 摘要" --deliver telegram
```

從 CLI 執行：

```bash
hermes cron create "0 9 * * 1" \
  "產生一份每週報告，內容涵蓋熱門 AI 新聞、熱門 ML GitHub 儲存庫以及 HN 上討論最多的貼文。按章節格式化，包含連結，保持在 500 字以內。" \
  --name "每週 AI 摘要" \
  --deliver telegram
```

`0 9 * * 1` 是標準的 cron 表達式：每週一上午 9:00。

---

## 模式 3：GitHub 儲存庫觀測器

監控儲存庫是否有新的 Issue、PR 或 Release。

```bash
/cron add "every 6h" "檢查 GitHub 儲存庫 NousResearch/hermes-agent 是否有：
- 過去 6 小時內新開的 Issue
- 過去 6 小時內新開或合併的 PR
- 任何新的 Release

使用終端機執行 gh 指令：
  gh issue list --repo NousResearch/hermes-agent --state open --json number,title,author,createdAt --limit 10
  gh pr list --repo NousResearch/hermes-agent --state all --json number,title,author,createdAt,mergedAt --limit 10

篩選僅顯示過去 6 小時內的項目。如果沒有新內容，請回應 [SILENT]。
否則，請提供活動的簡要總結。" --name "儲存庫觀測器" --deliver discord
```

:::warning 自給自足的提示詞
請注意提示詞如何包含確切的 `gh` 指令。Cron 代理程式沒有先前運行或您的偏好設定的記憶 — 請詳盡說明一切。
:::

---

## 模式 4：資料收集管線

定期抓取資料，儲存到檔案，並隨時間偵測趨勢。此模式結合了腳本（用於收集）與代理程式（用於分析）。

```python title="~/.hermes/scripts/collect-prices.py"
import json, os, urllib.request
from datetime import datetime

DATA_DIR = os.path.expanduser("~/.hermes/data/prices")
os.makedirs(DATA_DIR, exist_ok=True)

# 抓取目前資料（例如：加密貨幣價格）
url = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd"
data = json.loads(urllib.request.urlopen(url, timeout=30).read())

# 附加到歷史檔案
entry = {"timestamp": datetime.now().isoformat(), "prices": data}
history_file = os.path.join(DATA_DIR, "history.jsonl")
with open(history_file, "a") as f:
    f.write(json.dumps(entry) + "\n")

# 載入最近的歷史紀錄進行分析
lines = open(history_file).readlines()
recent = [json.loads(l) for l in lines[-24:]]  # 最後 24 個資料點

# 輸出給代理程式
print(f"Current: BTC=${data['bitcoin']['usd']}, ETH=${data['ethereum']['usd']}")
print(f"Data points collected: {len(lines)} total, showing last {len(recent)}")
print(f"\nRecent history:")
for r in recent[-6:]:
    print(f"  {r['timestamp']}: BTC=${r['prices']['bitcoin']['usd']}, ETH=${r['prices']['ethereum']['usd']}")
```

```bash
/cron add "every 1h" "分析腳本輸出的價格資料。報告：
1. 目前價格
2. 過去 6 個資料點的趨勢方向（上漲/下跌/持平）
3. 任何顯著波動（>5% 變化）

如果價格持平且沒有顯著變動，請回應 [SILENT]。
如果有重大波動，請解釋發生了什麼事。" \
  --script ~/.hermes/scripts/collect-prices.py \
  --name "價格追蹤器" \
  --deliver telegram
```

腳本負責機械性的收集；代理程式則加入推理層。

---

## 模式 5：多技能工作流

將多個技能串聯起來執行複雜的排程任務。技能在提示詞執行前會按順序載入。

```bash
# 使用 arxiv 技能尋找論文，然後使用 obsidian 技能儲存筆記
/cron add "0 8 * * *" "在 arXiv 上搜尋過去一天內關於 'language model reasoning' 的 3 篇最有趣的論文。針對每篇論文，建立一個包含標題、作者、摘要總結和關鍵貢獻的 Obsidian 筆記。" \
  --skill arxiv \
  --skill obsidian \
  --name "論文摘要"
```

直接從工具執行：

```python
cronjob(
    action="create",
    skills=["arxiv", "obsidian"],
    prompt="搜尋 arXiv 上過去一天關於 'language model reasoning' 的論文。將前 3 名儲存為 Obsidian 筆記。",
    schedule="0 8 * * *",
    name="論文摘要",
    deliver="local"
)
```

技能按順序載入 — 先是 `arxiv`（教導代理程式如何搜尋論文），然後是 `obsidian`（教導如何撰寫筆記）。提示詞將它們連結在一起。

---

## 管理您的任務

```bash
# 列出所有活動中的任務
/cron list

# 立即觸發任務（用於測試）
/cron run <job_id>

# 暫停任務而不刪除它
/cron pause <job_id>

# 編輯運行中任務的排程或提示詞
/cron edit <job_id> --schedule "every 4h"
/cron edit <job_id> --prompt "更新後的任務描述"

# 從現有任務中新增或移除技能
/cron edit <job_id> --skill arxiv --skill obsidian
/cron edit <job_id> --clear-skills

# 永久移除任務
/cron remove <job_id>
```

---

## 傳遞目標

`--deliver` 標記控制結果的去向：

| 目標 | 範例 | 使用案例 |
|--------|---------|----------|
| `origin` | `--deliver origin` | 建立任務的同一個聊天（預設） |
| `local` | `--deliver local` | 僅儲存到本地檔案 |
| `telegram` | `--deliver telegram` | 您的 Telegram 主頻道 |
| `discord` | `--deliver discord` | 您的 Discord 主頻道 |
| `slack` | `--deliver slack` | 您的 Slack 主頻道 |
| 特定聊天 | `--deliver telegram:-1001234567890` | 特定的 Telegram 群組 |
| 執行緒 | `--deliver telegram:-1001234567890:17585` | 特定的 Telegram 主題執行緒 |

---

## 提示

**使提示詞自給自足。** Cron 任務中的代理程式沒有您的對話記憶。請直接在提示詞中包含 URL、儲存庫名稱、格式偏好和傳遞說明。

**大量使用 `[SILENT]`。** 對於監測任務，請務必包含「如果沒有任何變更，請回應 `[SILENT]`」之類的說明。這可以防止通知噪音。

**使用腳本進行資料收集。** `script` 參數讓 Python 腳本處理無聊的部分（HTTP 請求、檔案 I/O、狀態追蹤）。代理程式只會看到腳本的標準輸出並對其應用推理。這比讓代理程式自己抓取更便宜且更可靠。

**使用 `/cron run` 進行測試。** 在等待排程觸發之前，使用 `/cron run <job_id>` 立即執行並驗證輸出是否正確。

**排程表達式。** 支援的格式：相對延遲（`30m`）、間隔（`every 2h`）、標準 cron 表達式（`0 9 * * *`）以及 ISO 時間戳記（`2025-06-15T09:00:00`）。不支援像 `daily at 9am` 這樣的自然語言 — 請改用 `0 9 * * *`。

---

*如需完整的 cron 參考 — 所有參數、邊緣案例和內部原理 — 請參閱 [排程任務 (Cron)](/docs/user-guide/features/cron)。*
