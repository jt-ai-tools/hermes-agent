---
sidebar_position: 7
title: "會話 (Sessions)"
description: "會話持久化、恢復、搜尋、管理，以及跨平台的會話追蹤"
---

# 會話 (Sessions)

Hermes Agent 會自動將每次對話儲存為一個會話。會話功能可實現對話恢復、跨會話搜尋，以及完整的對話歷史管理。

## 會話的運作方式

每一次對話 —— 無論是來自 CLI、Telegram、Discord、Slack、WhatsApp、Signal、Matrix 或任何其他通訊平台 —— 都會作為一個包含完整訊息歷史紀錄的會話進行儲存。會話由兩個互補的系統進行追蹤：

1. **SQLite 資料庫** (`~/.hermes/state.db`) —— 結構化的會話元資料，具備 FTS5 全文檢索功能
2. **JSONL 逐字稿** (`~/.hermes/sessions/`) —— 原始對話逐字稿，包含工具調用 (網關)

SQLite 資料庫儲存以下內容：
- 會話 ID、來源平台、使用者 ID
- **會話標題** (唯一且易於閱讀的名稱)
- 模型名稱與配置
- 系統提示詞快照
- 完整的訊息歷史紀錄 (角色、內容、工具調用、工具結果)
- Token 計數 (輸入/輸出)
- 時間戳記 (started_at, ended_at)
- 父會話 ID (用於因壓縮觸發的會話分割)

### 會話來源

每個會話都會標記其來源平台：

| 來源 | 描述 |
|--------|-------------|
| `cli` | 互動式 CLI (`hermes` 或 `hermes chat`) |
| `telegram` | Telegram 通訊軟體 |
| `discord` | Discord 伺服器/私訊 |
| `slack` | Slack 工作區 |
| `whatsapp` | WhatsApp 通訊軟體 |
| `signal` | Signal 通訊軟體 |
| `matrix` | Matrix 聊天室與私訊 |
| `mattermost` | Mattermost 頻道 |
| `email` | 電子郵件 (IMAP/SMTP) |
| `sms` | 透過 Twilio 發送的簡訊 |
| `dingtalk` | 釘釘 (DingTalk) |
| `feishu` | 飛書 (Feishu/Lark) |
| `wecom` | 企業微信 (WeCom) |
| `weixin` | 個人微信 (Weixin) |
| `bluebubbles` | 透過 BlueBubbles macOS 伺服器存取的 Apple iMessage |
| `qqbot` | 透過官方 API v2 存取的 QQ 機器人 (騰訊 QQ) |
| `homeassistant` | Home Assistant 對話 |
| `webhook` | 傳入的 Webhook |
| `api-server` | API 伺服器請求 |
| `acp` | ACP 編輯器整合 |
| `cron` | 排程 Cron 工作 |
| `batch` | 批次處理執行 |

## CLI 會話恢復

使用 `--continue` 或 `--resume` 從 CLI 恢復先前的對話：

### 延續上一個會話

```bash
# 恢復最近一次的 CLI 會話
hermes --continue
hermes -c

# 或使用 chat 子指令
hermes chat --continue
hermes chat -c
```

這會從 SQLite 資料庫中尋找最近的 `cli` 會話，並加載其完整的對話歷史紀錄。

### 依名稱恢復

如果你已為會話命名 (請參閱下方的 [會話命名](#會話命名))，你可以依名稱恢復它：

```bash
# 恢復指定名稱的會話
hermes -c "my project"

# 若有系列變體 (my project, my project #2, my project #3)，
# 這會自動恢復最近的一個
hermes -c "my project"   # → 恢復 "my project #3"
```

### 恢復特定會話

```bash
# 依 ID 恢復特定會話
hermes --resume 20250305_091523_a1b2c3d4
hermes -r 20250305_091523_a1b2c3d4

# 依標題恢復
hermes --resume "refactoring auth"

# 或使用 chat 子指令
hermes chat --resume 20250305_091523_a1b2c3d4
```

當你退出 CLI 會話時會顯示會話 ID，也可以透過 `hermes sessions list` 找到它們。

### 恢復時的對話回顧

當你恢復一個會話時，Hermes 會在輸入提示符號之前，於一個樣式面板中顯示先前對話的精簡回顧：

<img className="docs-terminal-figure" src="/img/docs/session-recap.svg" alt="恢復 Hermes 會話時顯示的先前對話回顧面板樣式預覽。" />
<p className="docs-figure-caption">恢復模式會在返回即時提示符號前，顯示一個包含最近使用者與助手回合的精簡回顧面板。</p>

該回顧：
- 顯示 **使用者訊息** (金色 `●`) 與 **助手回應** (綠色 `◆`)
- **截斷** 過長的訊息 (使用者 300 字元，助手 200 字元 / 3 行)
- **摺疊工具調用** 為包含工具名稱的計數 (例如 `[3 tool calls: terminal, web_search]`)
- **隱藏** 系統訊息、工具結果與內部推理
- **上限** 為最後 10 次交流，並顯示 "... N earlier messages ..." 指示
- 使用 **暗色樣式** 以區別於當前活動對話

若要停用回顧並保持簡約的單行行為，請在 `~/.hermes/config.yaml` 中設定：

```yaml
display:
  resume_display: minimal   # 預設值：full
```

:::tip
會話 ID 遵循 `YYYYMMDD_HHMMSS_<8位十六進位字元>` 的格式，例如 `20250305_091523_a1b2c3d4`。你可以依 ID 或標題恢復 —— `-c` 與 `-r` 兩者皆適用。
:::

## 會話命名

為會話命名易於閱讀的標題，以便你輕鬆尋找並恢復它們。

### 自動生成的標題

Hermes 會在第一次交流後，為每個會話自動生成一個簡短的描述性標題 (3–7 個字)。這是在背景執行緒中使用快速輔助模型執行的，因此不會增加延遲。當你使用 `hermes sessions list` 或 `hermes sessions browse` 瀏覽會話時，會看到自動生成的標題。

自動命名在每個會話中僅執行一次，如果你已經手動設定了標題，則會跳過此步驟。

### 手動設定標題

在任何對話會話 (CLI 或網關) 中使用 `/title` 斜線指令：

```
/title 我的研究專案
```

標題會立即生效。如果會話尚未在資料庫中建立 (例如，你在發送第一條訊息前執行 `/title`)，它會進入佇列並在會話開始後套用。

你也可以從命令列重新命名現有的會話：

```bash
hermes sessions rename 20250305_091523_a1b2c3d4 "重構驗證模組"
```

### 命名規則

- **唯一性** —— 沒有兩個會話可以共用相同的標題
- **最大 100 字元** —— 保持列表輸出整潔
- **清理過濾** —— 自動移除控制字元、零寬度字元與 RTL 覆蓋字元
- **支援標準 Unicode** —— Emoji、中日韓文字 (CJK)、變音符號皆可使用

### 壓縮時的自動系列化

當一個會話的上下文被壓縮時 (手動透過 `/compress` 或自動壓縮)，Hermes 會建立一個新的延續會話。如果原始會話有標題，新會話會自動獲得一個編號標題：

```
"my project" → "my project #2" → "my project #3"
```

當你依名稱恢復 (`hermes -c "my project"`) 時，它會自動選擇系列中最近的一個會話。

### 通訊平台中的 /title

`/title` 指令可在所有網關平台 (Telegram, Discord, Slack, WhatsApp) 中運作：

- `/title My Research` —— 設定會話標題
- `/title` —— 顯示目前的標題

## 會話管理指令

Hermes 透過 `hermes sessions` 提供了一整套會話管理指令：

### 列出會話

```bash
# 列出最近的會話 (預設：最後 20 個)
hermes sessions list

# 依平台過濾
hermes sessions list --source telegram

# 顯示更多會話
hermes sessions list --limit 50
```

當會話有標題時，輸出會顯示標題、預覽與相對時間戳記：

```
Title                  Preview                                  Last Active   ID
────────────────────────────────────────────────────────────────────────────────────────────────
refactoring auth       Help me refactor the auth module please   2h ago        20250305_091523_a
my project #3          Can you check the test failures?          yesterday     20250304_143022_e
—                      What's the weather in Las Vegas?          3d ago        20250303_101500_f
```

當會話沒有標題時，會使用較簡單的格式：

```
Preview                                            Last Active   Src    ID
──────────────────────────────────────────────────────────────────────────────────────
Help me refactor the auth module please             2h ago        cli    20250305_091523_a
What's the weather in Las Vegas?                    3d ago        tele   20250303_101500_f
```

### 匯出會話

```bash
# 將所有會話匯出至一個 JSONL 檔案
hermes sessions export backup.jsonl

# 匯出特定平台的會話
hermes sessions export telegram-history.jsonl --source telegram

# 匯出單一會話
hermes sessions export session.jsonl --session-id 20250305_091523_a1b2c3d4
```

匯出的檔案每行包含一個 JSON 物件，具備完整的會話元資料與所有訊息。

### 刪除會話

```bash
# 刪除特定會話 (需確認)
hermes sessions delete 20250305_091523_a1b2c3d4

# 無需確認即刪除
hermes sessions delete 20250305_091523_a1b2c3d4 --yes
```

### 重新命名會話

```bash
# 設定或變更會話標題
hermes sessions rename 20250305_091523_a1b2c3d4 "debugging auth flow"

# 在 CLI 中，多個單字的標題不需要引號
hermes sessions rename 20250305_091523_a1b2c3d4 debugging auth flow
```

如果標題已被另一個會話使用，則會顯示錯誤。

### 清理舊會話 (Prune)

```bash
# 刪除超過 90 天 (預設值) 的已結束會話
hermes sessions prune

# 自訂時間閾值
hermes sessions prune --older-than 30

# 僅清理特定平台的會話
hermes sessions prune --source telegram --older-than 60

# 跳過確認
hermes sessions prune --older-than 30 --yes
```

:::info
清理功能僅會刪除 **已結束** 的會話 (已明確結束或自動重設的會話)。使用中的會話絕不會被清理。
:::

### 會話統計數據

```bash
hermes sessions stats
```

輸出範例：

```
Total sessions: 142
Total messages: 3847
  cli: 89 sessions
  telegram: 38 sessions
  discord: 15 sessions
Database size: 12.4 MB
```

若要取得更深度的分析 —— Token 使用量、成本預估、工具細分與活動模式 —— 請使用 [`hermes insights`](/docs/reference/cli-commands#hermes-insights)。

## 會話搜尋工具

代理程式內建一個 `session_search` 工具，使用 SQLite 的 FTS5 引擎對過去所有對話進行全文檢索。

### 運作方式

1. FTS5 搜尋相符的訊息並依關聯性排序
2. 依會話分組結果，取前 N 個唯一的會話 (預設為 3 個)
3. 加載每個會話的對話，截斷至約 10 萬字元，並以相符項為中心
4. 發送至快速摘要模型進行重點摘要
5. 回傳每個會話的摘要，包含元資料與周邊上下文

### FTS5 查詢語法

搜尋支援標準的 FTS5 查詢語法：

- 簡單關鍵字：`docker deployment`
- 精確字句：`"exact phrase"`
- 布林運算：`docker OR kubernetes`, `python NOT java`
- 前綴搜尋：`deploy*`

### 何時使用

代理程式被提示會自動使用會話搜尋：

> *"當使用者提到先前對話中的內容，或者你懷疑存在相關的先前上下文時，請在要求使用者重複之前使用 session_search 進行檢索。"*

## 跨平台的會話追蹤

### 網關會話

在通訊平台上，會話是根據訊息來源構建的確定性會話鍵名 (session key) 來識別的：

| 聊天類型 | 預設鍵名格式 | 行為 |
|-----------|--------------------|----------|
| Telegram 私訊 | `agent:main:telegram:dm:<chat_id>` | 每個私訊聊天一個會話 |
| Discord 私訊 | `agent:main:discord:dm:<chat_id>` | 每個私訊聊天一個會話 |
| WhatsApp 私訊 | `agent:main:whatsapp:dm:<chat_id>` | 每個私訊聊天一個會話 |
| 群組聊天 | `agent:main:<platform>:group:<chat_id>:<user_id>` | 當平台提供使用者 ID 時，群組內每位使用者獨立一個會話 |
| 群組討論串/主題 | `agent:main:<platform>:group:<chat_id>:<thread_id>` | 所有討論串參與者共用會話 (預設)。若開啟 `thread_sessions_per_user: true` 則每位使用者獨立。 |
| 頻道 | `agent:main:<platform>:channel:<chat_id>:<user_id>` | 當平台提供使用者 ID 時，頻道內每位使用者獨立一個會話 |

當 Hermes 無法取得共用聊天的參與者識別碼時，會回退到該聊天室共用一個會話。

### 共用 vs 隔離的群組會話

預設情況下，Hermes 在 `config.yaml` 中使用 `group_sessions_per_user: true`。這意味著：

- Alice 和 Bob 可以在同一個 Discord 頻道中與 Hermes 交談，而不會共用逐字稿歷史紀錄
- 一個使用者耗費大量工具執行的長任務不會污染另一個使用者的上下文視窗
- 中斷處理也會保持在每位使用者級別，因為執行中代理的鍵名與隔離的會話鍵名相符

如果你想要共用的「聊天室大腦」，請設定：

```yaml
group_sessions_per_user: false
```

這會將群組/頻道還原為每個聊天室單一共用會話，這雖然保留了共用的對話上下文，但也會共用 Token 成本、中斷狀態與上下文增長。

### 會話重設策略

網關會話會根據可配置的策略自動重設：

- **idle** (閒置) —— 在閒置 N 分鐘後重設
- **daily** (每日) —— 每天在特定小時重設
- **both** (兩者) —— 視閒置或每日重設哪個先發生而定
- **none** (無) —— 絕不自動重設

在會話自動重設之前，代理程式會獲得一個回合來儲存對話中任何重要的記憶或技能。

具有 **活動中背景進程** 的會話絕不會被自動重設，無論其策略為何。

## 儲存位置

| 類別 | 路徑 | 描述 |
|------|------|-------------|
| SQLite 資料庫 | `~/.hermes/state.db` | 所有會話元資料 + 具備 FTS5 的訊息內容 |
| 網關逐字稿 | `~/.hermes/sessions/` | 每個會話的 JSONL 逐字稿 + sessions.json 索引 |
| 網關索引 | `~/.hermes/sessions/sessions.json` | 將會話鍵名映射至活動中的會話 ID |

SQLite 資料庫使用 WAL 模式以支援並行讀取與單一寫入，這非常適合網關的多平台架構。

### 資料庫 Schema

`state.db` 中的關鍵資料表：

- **sessions** —— 會話元資料 (id, source, user_id, model, title, timestamps, token counts)。標題具有唯一索引 (允許 NULL 標題，但非 NULL 標題必須唯一)。
- **messages** —— 完整的訊息歷史紀錄 (role, content, tool_calls, tool_name, token_count)
- **messages_fts** —— FTS5 虛擬資料表，用於訊息內容的全文檢索

## 會話過期與清理

### 自動清理

- 網關會話根據配置的重設策略自動重設
- 在重設之前，代理程式會從即將過期的會話中儲存記憶與技能
- 已結束的會話會保留在資料庫中，直到被手動清理

### 手動清理

```bash
# 清理超過 90 天的會話
hermes sessions prune

# 刪除特定會話
hermes sessions delete <session_id>

# 在清理前匯出 (備份)
hermes sessions export backup.jsonl
hermes sessions prune --older-than 30 --yes
```

:::tip
資料庫增長緩慢 (典型情況：數百個會話約 10-15 MB)。清理主要用於移除你不再需要搜尋調用的舊對話。
:::
