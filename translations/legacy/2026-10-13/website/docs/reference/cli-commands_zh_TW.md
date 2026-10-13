---
sidebar_position: 1
title: "CLI 指令參考"
description: "Hermes 終端機指令與指令系列的權威參考"
---

# CLI 指令參考

本頁面涵蓋了您在 shell 中運行的 **終端機指令**。

關於聊天內部的斜線指令，請參閱 [斜線指令參考](./slash-commands.md)。

## 全域入口點

```bash
hermes [global-options] <command> [subcommand/options]
```

### 全域選項

| 選項 | 描述 |
|--------|-------------|
| `--version`, `-V` | 顯示版本並退出。 |
| `--profile <name>`, `-p <name>` | 選擇此次調用要使用的 Hermes 設定檔 (profile)。會覆蓋透過 `hermes profile use` 設定的固定預設值。 |
| `--resume <session>`, `-r <session>` | 透過 ID 或標題恢復之前的聊天工作階段。 |
| `--continue [name]`, `-c [name]` | 恢復最近的一個工作階段，或最近一個標題匹配的工作階段。 |
| `--worktree`, `-w` | 在隔離的 git worktree 中啟動，適用於平行代理 (parallel-agent) 工作流。 |
| `--yolo` | 繞過危險指令的核准提示。 |
| `--pass-session-id` | 在代理的系統提示詞中包含工作階段 ID。 |

## 頂層指令

| 指令 | 用途 |
|---------|---------|
| `hermes chat` | 與代理進行互動式或單次 (one-shot) 聊天。 |
| `hermes model` | 互動式選擇預設提供商和模型。 |
| `hermes gateway` | 運行或管理即時通訊網關服務。 |
| `hermes setup` | 用於配置全部或部分設定的互動式設定精靈。 |
| `hermes whatsapp` | 配置並配對 WhatsApp 橋接器。 |
| `hermes auth` | 管理憑證 — 新增、列出、移除、重設、設定策略。處理 Codex/Nous/Anthropic 的 OAuth 流程。 |
| `hermes login` / `logout` | **已棄用** — 請改用 `hermes auth`。 |
| `hermes status` | 顯示代理、驗證和平台狀態。 |
| `hermes cron` | 檢查並觸發 cron 排程器。 |
| `hermes webhook` | 管理用於事件驅動啟動的動態 Webhook 訂閱。 |
| `hermes doctor` | 診斷配置和依賴問題。 |
| `hermes dump` | 用於支援/除錯的、可複製貼上的設定摘要。 |
| `hermes debug` | 除錯工具 — 上傳日誌和系統資訊以獲取支援。 |
| `hermes backup` | 將 Hermes 家目錄備份到 zip 檔案。 |
| `hermes import` | 從 zip 檔案還原 Hermes 備份。 |
| `hermes logs` | 查看、追蹤 (tail) 和過濾代理/網關/錯誤日誌檔案。 |
| `hermes config` | 顯示、編輯、遷移和查詢配置檔案。 |
| `hermes pairing` | 核准或撤銷即時通訊配對碼。 |
| `hermes skills` | 瀏覽、安裝、發佈、稽核與配置技能 (skills)。 |
| `hermes honcho` | 管理 Honcho 跨工作階段記憶整合。 |
| `hermes memory` | 配置外部記憶提供商。 |
| `hermes acp` | 將 Hermes 作為 ACP 伺服器運行，以便與編輯器整合。 |
| `hermes mcp` | 管理 MCP 伺服器配置，並將 Hermes 作為 MCP 伺服器運行。 |
| `hermes plugins` | 管理 Hermes Agent 外掛程式 (安裝、啟用、停用、移除)。 |
| `hermes tools` | 按平台配置啟用的工具。 |
| `hermes sessions` | 瀏覽、匯出、清理、重命名和刪除工作階段。 |
| `hermes insights` | 顯示 Token/成本/活動分析。 |
| `hermes claw` | OpenClaw 遷移輔助工具。 |
| `hermes dashboard` | 啟動網頁儀表板，用於管理配置、API 金鑰和工作階段。 |
| `hermes profile` | 管理設定檔 (Profiles) — 多個隔離的 Hermes 實例。 |
| `hermes completion` | 印出 shell 補全腳本 (bash/zsh)。 |
| `hermes version` | 顯示版本資訊。 |
| `hermes update` | 獲取最新代碼並重新安裝依賴。 |
| `hermes uninstall` | 從系統中移除 Hermes。 |

## `hermes chat`

```bash
hermes chat [options]
```

常用選項：

| 選項 | 描述 |
|--------|-------------|
| `-q`, `--query "..."` | 單次、非互動式提示詞。 |
| `-m`, `--model <model>` | 覆蓋此次運行的模型。 |
| `-t`, `--toolsets <csv>` | 啟用以逗號分隔的工具集。 |
| `--provider <provider>` | 強制指定提供商：`auto`、`openrouter`、`nous`、`openai-codex`、`copilot-acp`、`copilot`、`anthropic`、`gemini`、`huggingface`、`zai`、`kimi-coding`、`minimax`、`minimax-cn`、`kilocode`、`xiaomi`、`arcee`。 |
| `-s`, `--skills <name>` | 為工作階段預載一個或多個技能 (可重複使用或以逗號分隔)。 |
| `-v`, `--verbose` | 詳細輸出。 |
| `-Q`, `--quiet` | 程式化模式：隱藏橫幅 (banner)/轉圈 (spinner)/工具預覽。 |
| `--image <path>` | 在單個查詢中附加在地圖片。 |
| `--resume <session>` / `--continue [name]` | 直接從 `chat` 恢復工作階段。 |
| `--worktree` | 為此次運行建立一個隔離的 git worktree。 |
| `--checkpoints` | 在破壞性的檔案更改前啟用檔案系統檢查點。 |
| `--yolo` | 跳過核准提示。 |
| `--pass-session-id` | 將工作階段 ID 傳遞到系統提示詞中。 |
| `--source <tag>` | 用於過濾的工作階段來源標籤 (預設：`cli`)。對於不應出現在使用者工作階段列表中的第三方整合，請使用 `tool`。 |
| `--max-turns <N>` | 每輪對話的最大工具呼叫迭代次數 (預設：90，或配置中的 `agent.max_turns`)。 |

範例：

```bash
hermes
hermes chat -q "摘要最新的 PR"
hermes chat --provider openrouter --model anthropic/claude-sonnet-4.6
hermes chat --toolsets web,terminal,skills
hermes chat --quiet -q "僅返回 JSON"
hermes chat --worktree -q "審查此儲存庫並提交一個 PR"
```

## `hermes model`

互動式提供商與模型選擇器。**這是用於新增提供商、設定 API 金鑰和運行 OAuth 流程的指令。** 請從您的終端機運行 — 而非在活動的 Hermes 聊天工作階段內運行。

```bash
hermes model
```

當您想要執行以下操作時使用此指令：
- **新增提供商** (OpenRouter, Anthropic, Copilot, DeepSeek, 自定義端點等)
- 登入基於 OAuth 的提供商 (Anthropic, Copilot, Codex, Nous Portal)
- 輸入或更新 API 金鑰
- 從特定提供商的模型列表中選擇
- 配置自定義/自代管端點
- 將新的預設值儲存到配置中

:::warning hermes model 與 /model — 瞭解其區別
**`hermes model`** (從您的終端機運行，在任何 Hermes 工作階段之外) 是 **完整的提供商設定精靈**。它可以新增提供商、運行 OAuth 流程、提示輸入 API 金鑰以及配置端點。

**`/model`** (在活動的 Hermes 聊天工作階段中輸入) 只能在 **您已經設定好的提供商和模型之間切換**。它無法新增提供商、運行 OAuth 或提示輸入 API 金鑰。

**如果您需要新增提供商：** 請先退出您的 Hermes 工作階段 (`Ctrl+C` 或 `/quit`)，然後從終端機提示符號運行 `hermes model`。
:::

### `/model` 斜線指令 (工作階段中途)

在不離開工作階段的情況下切換已配置的模型：

```
/model                              # 顯示當前模型和可用選項
/model claude-sonnet-4              # 切換模型 (自動偵測提供商)
/model zai:glm-5                    # 切換提供商和模型
/model custom:qwen-2.5              # 使用您自定義端點上的模型
/model custom                       # 從自定義端點自動偵測模型
/model custom:local:qwen-2.5        # 使用命名的自定義提供商
/model openrouter:anthropic/claude-sonnet-4  # 切換回雲端提供商
```

預設情況下，`/model` 的更改 **僅適用於當前工作階段**。添加 `--global` 可將更改持久化到 `config.yaml`：

```
/model claude-sonnet-4 --global     # 切換並儲存為新的預設值
```

:::info 如果我只看到 OpenRouter 模型怎麼辦？
如果您僅配置了 OpenRouter，`/model` 將僅顯示 OpenRouter 的模型。要新增其他提供商 (Anthropic, DeepSeek, Copilot 等)，請退出工作階段並從終端機運行 `hermes model`。
:::

提供商和基本 URL 的更改會自動持久化到 `config.yaml`。當從自定義端點切換走時，過時的基本 URL 會被清除，以防止其洩露到其他提供商。

## `hermes gateway`

```bash
hermes gateway <subcommand>
```

子指令：

| 子指令 | 描述 |
|------------|-------------|
| `run` | 在前景運行網關。建議用於 WSL、Docker 和 Termux。 |
| `start` | 啟動安裝的 systemd/launchd 背景服務。 |
| `stop` | 停止服務 (或前景程序)。 |
| `restart` | 重啟服務。 |
| `status` | 顯示服務狀態。 |
| `install` | 作為 systemd (Linux) 或 launchd (macOS) 背景服務安裝。 |
| `uninstall` | 移除已安裝的服務。 |
| `setup` | 互動式即時通訊平台設定。 |

:::tip WSL 使用者
請使用 `hermes gateway run` 而非 `hermes gateway start` — WSL 的 systemd 支援並不穩定。請將其封裝在 tmux 中以實現持久化：`tmux new -s hermes 'hermes gateway run'`。詳情請參閱 [WSL 常見問題](/docs/reference/faq#wsl-gateway-keeps-disconnecting-or-hermes-gateway-start-fails)。
:::

## `hermes setup`

```bash
hermes setup [model|tts|terminal|gateway|tools|agent] [--non-interactive] [--reset]
```

使用完整精靈或跳轉至特定章節：

| 章節 | 描述 |
|---------|-------------|
| `model` | 提供商與模型設定。 |
| `terminal` | 終端機後端與沙盒設定。 |
| `gateway` | 即時通訊平台設定。 |
| `tools` | 按平台啟用/停用工具。 |
| `agent` | 代理行為設定。 |

選項：

| 選項 | 描述 |
|--------|-------------|
| `--non-interactive` | 使用預設值 / 環境變數值，不顯示提示。 |
| `--reset` | 在設定前將配置重設為預設值。 |

## `hermes whatsapp`

```bash
hermes whatsapp
```

運行 WhatsApp 配對/設定流程，包括模式選擇和 QR 碼配對。

## `hermes login` / `hermes logout` *(已棄用)*

:::caution
`hermes login` 已移除。請使用 `hermes auth` 管理 OAuth 憑證、`hermes model` 選擇提供商，或使用 `hermes setup` 進行完整互動式設定。
:::

## `hermes auth`

管理用於同提供商金鑰輪換的憑證池。詳情請參閱 [憑證池](/docs/user-guide/features/credential-pools)。

```bash
hermes auth                                              # 互動式精靈
hermes auth list                                         # 顯示所有憑證池
hermes auth list openrouter                              # 顯示特定提供商
hermes auth add openrouter --api-key sk-or-v1-xxx        # 新增 API 金鑰
hermes auth add anthropic --type oauth                   # 新增 OAuth 憑證
hermes auth remove openrouter 2                          # 按索引移除
hermes auth reset openrouter                             # 清除冷卻時間 (cooldowns)
```

子指令：`add`, `list`, `remove`, `reset`。不帶子指令調用時，會啟動互動式管理精靈。

## `hermes status`

```bash
hermes status [--all] [--deep]
```

| 選項 | 描述 |
|--------|-------------|
| `--all` | 以可分享且經過脫敏 (redacted) 的格式顯示所有詳細資訊。 |
| `--deep` | 運行可能需要較長時間的深度檢查。 |

## `hermes cron`

```bash
hermes cron <list|create|edit|pause|resume|run|remove|status|tick>
```

| 子指令 | 描述 |
|------------|-------------|
| `list` | 顯示已排程的任務。 |
| `create` / `add` | 從提示詞建立排程任務，可選擇透過重複使用 `--skill` 附加一個或多個技能。 |
| `edit` | 更新任務的排程、提示詞、名稱、發送方式、重複次數或附加技能。支援 `--clear-skills`、`--add-skill` 和 `--remove-skill`。 |
| `pause` | 暫停任務而不刪除。 |
| `resume` | 恢復暫停的任務並計算下次運行的時間。 |
| `run` | 在下次排程器觸發時執行任務。 |
| `remove` | 刪除排程任務。 |
| `status` | 檢查 cron 排程器是否正在運行。 |
| `tick` | 運行一次到期的任務並退出。 |

## `hermes webhook`

```bash
hermes webhook <subscribe|list|remove|test>
```

管理用於事件驅動代理啟動的動態 Webhook 訂閱。需要在配置中啟用 webhook 平台 — 如果未配置，將印出設定說明。

| 子指令 | 描述 |
|------------|-------------|
| `subscribe` / `add` | 建立 Webhook 路由。返回要在您的服務上配置的 URL 和 HMAC 密鑰。 |
| `list` / `ls` | 顯示所有由代理建立的訂閱。 |
| `remove` / `rm` | 刪除動態訂閱。來自 `config.yaml` 的靜態路由不受影響。 |
| `test` | 發送測試 POST 以驗證訂閱是否正常。 |

### `hermes webhook subscribe`

```bash
hermes webhook subscribe <name> [options]
```

| 選項 | 描述 |
|--------|-------------|
| `--prompt` | 帶有 `{dot.notation}` 酬載引用的提示詞模板。 |
| `--events` | 要接受的以逗號分隔的事件類型 (例如 `issues,pull_request`)。留空表示接受所有。 |
| `--description` | 人類可讀的描述。 |
| `--skills` | 為代理運行載入的以逗號分隔的技能名稱。 |
| `--deliver` | 傳送目標：`log` (預設)、`telegram`、`discord`、`slack`、`github_comment`。 |
| `--deliver-chat-id` | 用於跨平台傳送的目標聊天/頻道 ID。 |
| `--secret` | 自定義 HMAC 密鑰。省略則自動產生。 |

訂閱會持久化到 `~/.hermes/webhook_subscriptions.json`，並由 webhook 適配器熱載入，無需重啟網關。

## `hermes doctor`

```bash
hermes doctor [--fix]
```

| 選項 | 描述 |
|--------|-------------|
| `--fix` | 嘗試在可能的情況下進行自動修復。 |

## `hermes dump`

```bash
hermes dump [--show-keys]
```

輸出您的整個 Hermes 設定的緊湊純文字摘要。旨在於尋求支援時，可以複製貼上到 Discord、GitHub issues 或 Telegram — 無 ANSI 顏色，無特殊格式，僅有數據。

| 選項 | 描述 |
|--------|-------------|
| `--show-keys` | 顯示遮蔽後的 API 金鑰前綴 (首尾各 4 個字元)，而非僅顯示 `set`/`not set`。 |

### 包含內容

| 章節 | 詳細資訊 |
|---------|---------|
| **標頭 (Header)** | Hermes 版本、發佈日期、git commit 哈希值 |
| **環境 (Environment)** | 作業系統、Python 版本、OpenAI SDK 版本 |
| **身份 (Identity)** | 活動設定檔名稱、HERMES_HOME 路徑 |
| **模型 (Model)** | 配置的預設模型和提供商 |
| **終端機 (Terminal)** | 後端類型 (local, docker, ssh 等) |
| **API 金鑰** | 所有 22 個提供商/工具 API 金鑰的存在性檢查 |
| **功能 (Features)** | 啟用的工具集、MCP 伺服器數量、記憶提供商 |
| **服務 (Services)** | 網關狀態、已配置的即時通訊平台 |
| **工作量 (Workload)** | Cron 任務計數、已安裝的技能數量 |
| **配置覆蓋** | 任何與預設值不同的配置值 |

### 範例輸出

```
--- hermes dump ---
version:          0.8.0 (2026.4.8) [af4abd2f]
os:               Linux 6.14.0-37-generic x86_64
python:           3.11.14
openai_sdk:       2.24.0
profile:          default
hermes_home:      ~/.hermes
model:            anthropic/claude-opus-4.6
provider:         openrouter
terminal:         local

api_keys:
  openrouter           set
  openai               not set
  anthropic            set
  nous                 not set
  firecrawl            set
  ...

features:
  toolsets:           all
  mcp_servers:        0
  memory_provider:    built-in
  gateway:            running (systemd)
  platforms:          telegram, discord
  cron_jobs:          3 active / 5 total
  skills:             42

config_overrides:
  agent.max_turns: 250
  compression.threshold: 0.85
  display.streaming: True
--- end dump ---
```

### 何時使用

- 在 GitHub 上報告錯誤 — 將 dump 貼到您的 issue 中
- 在 Discord 中尋求幫助 — 在代碼塊中分享
- 將您的設定與他人的進行比較
- 當某些功能無法運作時進行快速檢查

:::tip
`hermes dump` 專為分享而設計。對於互動式診斷，請使用 `hermes doctor`。要獲得視覺化概覽，請使用 `hermes status`。
:::

## `hermes debug`

```bash
hermes debug share [options]
```

將除錯報告 (系統資訊 + 最近日誌) 上傳到剪貼簿服務並獲取可分享的網址。適用於快速支援請求 — 包含協助者診斷問題所需的一切。

| 選項 | 描述 |
|--------|-------------|
| `--lines <N>` | 每個日誌檔案包含的行數 (預設：200)。 |
| `--expire <days>` | 貼文有效天數 (預設：7)。 |
| `--local` | 在在地印出報告而非上傳。 |

報告包括系統資訊 (OS, Python 版本, Hermes 版本)、最近的代理和網關日誌 (每個檔案限制 512 KB) 以及脫敏後的 API 金鑰狀態。金鑰始終會被脫敏 — 絕不會上傳任何秘密。

依序嘗試的剪貼簿服務：paste.rs, dpaste.com。

### 範例

```bash
hermes debug share              # 上傳除錯報告，印出網址
hermes debug share --lines 500  # 包含更多日誌行
hermes debug share --expire 30  # 保留 30 天
hermes debug share --local      # 在終端機印出報告 (不上傳)
```

## `hermes backup`

```bash
hermes backup [options]
```

建立 Hermes 配置、技能、工作階段和數據的 zip 存檔。備份不包括 hermes-agent 代碼本身。

| 選項 | 描述 |
|--------|-------------|
| `-o`, `--output <path>` | zip 檔案的輸出路徑 (預設：`~/hermes-backup-<timestamp>.zip`)。 |
| `-q`, `--quick` | 快速快照：僅包含關鍵狀態檔案 (config.yaml, state.db, .env, auth, cron jobs)。比完整備份快得多。 |
| `-l`, `--label <name>` | 快照標籤 (僅與 `--quick` 一起使用)。 |

備份使用 SQLite 的 `backup()` API 進行安全複製，因此即使 Hermes 正在運行也能正常工作 (WAL 模式安全)。

### 範例

```bash
hermes backup                           # 完整備份到 ~/hermes-backup-*.zip
hermes backup -o /tmp/hermes.zip        # 完整備份到指定路徑
hermes backup --quick                   # 僅狀態的快速快照
hermes backup --quick --label "pre-upgrade"  # 帶有標籤的快速快照
```

## `hermes import`

```bash
hermes import <zipfile> [options]
```

將之前建立的 Hermes 備份還原到您的 Hermes 家目錄。

| 選項 | 描述 |
|--------|-------------|
| `-f`, `--force` | 不經確認直接覆寫現有檔案。 |

## `hermes logs`

```bash
hermes logs [log_name] [options]
```

查看、追蹤和過濾 Hermes 日誌檔案。所有日誌都儲存在 `~/.hermes/logs/` (非預設設定檔則在 `<profile>/logs/`)。

### 日誌檔案

| 名稱 | 檔案 | 捕捉內容 |
|------|------|-----------------|
| `agent` (預設) | `agent.log` | 所有代理活動 — API 呼叫、工具分發、工作階段生命週期 (INFO 及以上) |
| `errors` | `errors.log` | 僅警告和錯誤 — agent.log 的過濾子集 |
| `gateway` | `gateway.log` | 即時通訊網關活動 — 平台連接、訊息分發、webhook 事件 |

### 選項

| 選項 | 描述 |
|--------|-------------|
| `log_name` | 要查看的日誌：`agent` (預設)、`errors`、`gateway`，或使用 `list` 顯示可用檔案及其大小。 |
| `-n`, `--lines <N>` | 要顯示的行數 (預設：50)。 |
| `-f`, `--follow` | 即時追蹤日誌，類似 `tail -f`。按 Ctrl+C 停止。 |
| `--level <LEVEL>` | 要顯示的最低日誌層級：`DEBUG`、`INFO`、`WARNING`、`ERROR`、`CRITICAL`。 |
| `--session <ID>` | 過濾包含工作階段 ID 子字串的行。 |
| `--since <TIME>` | 顯示從相對時間之前的行：`30m`、`1h`、`2d` 等。支援 `s` (秒)、`m` (分)、`h` (小時)、`d` (天)。 |
| `--component <NAME>` | 按組件過濾：`gateway`、`agent`、`tools`、`cli`、`cron`。 |

### 範例

```bash
# 查看 agent.log 的最後 50 行 (預設)
hermes logs

# 即時追蹤 agent.log
hermes logs -f

# 查看 gateway.log 的最後 100 行
hermes logs gateway -n 100

# 顯示過去一小時內的警告和錯誤
hermes logs --level WARNING --since 1h

# 按特定工作階段過濾
hermes logs --session abc123

# 從 30 分鐘前開始追蹤 errors.log
hermes logs errors --since 30m -f

# 列出所有日誌檔案及其大小
hermes logs list
```

### 過濾

過濾器可以組合使用。當多個過濾器活動時，日誌行必須通過 **所有** 過濾器才會顯示：

```bash
# 過去 2 小時內包含工作階段 "tg-12345" 的 WARNING+ 行
hermes logs --level WARNING --since 2h --session tg-12345
```

當 `--since` 活動時，沒有可解析時間戳記的行也會包含在內 (它們可能是多行日誌條目的後續行)。當 `--level` 活動時，沒有偵測到層級的行也會包含在內。

### 日誌輪換

Hermes 使用 Python 的 `RotatingFileHandler`。舊日誌會自動輪換 — 請尋找 `agent.log.1`, `agent.log.2` 等。`hermes logs list` 子指令會顯示所有日誌檔案，包括已輪換的檔案。

## `hermes config`

```bash
hermes config <subcommand>
```

子指令：

| 子指令 | 描述 |
|------------|-------------|
| `show` | 顯示當前配置值。 |
| `edit` | 在您的編輯器中開啟 `config.yaml`。 |
| `set <key> <value>` | 設定一個配置值。 |
| `path` | 印出配置檔案路徑。 |
| `env-path` | 印出 `.env` 檔案路徑。 |
| `check` | 檢查缺失或過時的配置。 |
| `migrate` | 互動式新增新引入的選項。 |

## `hermes pairing`

```bash
hermes pairing <list|approve|revoke|clear-pending>
```

| 子指令 | 描述 |
|------------|-------------|
| `list` | 顯示待處理與已核准的使用者。 |
| `approve <platform> <code>` | 核准配對碼。 |
| `revoke <platform> <user-id>` | 撤銷使用者的存取權限。 |
| `clear-pending` | 清除待處理的配對碼。 |

## `hermes skills`

```bash
hermes skills <subcommand>
```

子指令：

| 子指令 | 描述 |
|------------|-------------|
| `browse` | 分頁瀏覽技能註冊庫。 |
| `search` | 搜尋技能註冊庫。 |
| `install` | 安裝技能。 |
| `inspect` | 在不安裝的情況下預覽技能。 |
| `list` | 列出已安裝的技能。 |
| `check` | 檢查已安裝的 Hub 技能是否有上游更新。 |
| `update` | 當上游有更改時，重新安裝 Hub 技能。 |
| `audit` | 重新掃描已安裝的 Hub 技能。 |
| `uninstall` | 移除 Hub 安裝的技能。 |
| `publish` | 將技能發佈到註冊庫。 |
| `snapshot` | 匯出/匯入技能配置。 |
| `tap` | 管理自定義技能來源。 |
| `config` | 互動式配置各平台的技能啟用/停用。 |

常用範例：

```bash
hermes skills browse
hermes skills browse --source official
hermes skills search react --source skills-sh
hermes skills search https://mintlify.com/docs --source well-known
hermes skills inspect official/security/1password
hermes skills inspect skills-sh/vercel-labs/json-render/json-render-react
hermes skills install official/migration/openclaw-migration
hermes skills install skills-sh/anthropics/skills/pdf --force
hermes skills check
hermes skills update
hermes skills config
```

說明：
- `--force` 可以覆蓋針對第三方/社群技能的非危險策略封鎖。
- `--force` 不會覆蓋「危險 (dangerous)」的掃描判定。
- `--source skills-sh` 搜尋公共 `skills.sh` 目錄。
- `--source well-known` 讓您可以將 Hermes 指向公開 `/.well-known/skills/index.json` 的網站。

## `hermes honcho`

```bash
hermes honcho [--target-profile NAME] <subcommand>
```

管理 Honcho 跨工作階段記憶整合。此指令由 Honcho 記憶提供商外掛程式提供，僅當配置中的 `memory.provider` 設定為 `honcho` 時可用。

`--target-profile` 標記讓您可以在不切換的情況下管理另一個設定檔的 Honcho 配置。

子指令：

| 子指令 | 描述 |
|------------|-------------|
| `setup` | 重定向到 `hermes memory setup` (統一設定路徑)。 |
| `status [--all]` | 顯示當前 Honcho 配置和連接狀態。`--all` 顯示跨設定檔概覽。 |
| `peers` | 顯示所有設定檔中的同伴 (peer) 身份。 |
| `sessions` | 列出已知的 Honcho 工作階段映射。 |
| `map [name]` | 將當前目錄映射到一個 Honcho 工作階段名稱。省略 `name` 則列出當前映射。 |
| `peer` | 顯示或更新同伴名稱和辯證推理層級。選項：`--user NAME`、`--ai NAME`、`--reasoning LEVEL`。 |
| `mode [mode]` | 顯示或設定召回模式：`hybrid`、`context` 或 `tools`。省略則顯示當前模式。 |
| `tokens` | 顯示或設定上下文和辯證的 Token 預算。選項：`--context N`、`--dialectic N`。 |
| `identity [file] [--show]` | 播種或顯示 AI 同伴身份表徵。 |
| `enable` | 為活動設定檔啟用 Honcho。 |
| `disable` | 為活動設定檔停用 Honcho。 |
| `sync` | 將 Honcho 配置同步到所有現有設定檔 (建立缺失的主機區塊)。 |
| `migrate` | 從 openclaw-honcho 遷移到 Hermes Honcho 的逐步指南。 |

## `hermes memory`

```bash
hermes memory <subcommand>
```

設定並管理外部記憶提供商外掛程式。可用提供商：honcho, openviking, mem0, hindsight, holographic, retaindb, byterover, supermemory。同一時間只能有一個外部提供商處於活動狀態。內建記憶 (MEMORY.md/USER.md) 始終處於活動狀態。

子指令：

| 子指令 | 描述 |
|------------|-------------|
| `setup` | 互動式提供商選擇與配置。 |
| `status` | 顯示當前記憶提供商配置。 |
| `off` | 停用外部提供商 (僅使用內建記憶)。 |

## `hermes acp`

```bash
hermes acp
```

啟動 Hermes 作為 ACP (Agent Client Protocol) stdio 伺服器，以便與編輯器整合。

相關入口點：

```bash
hermes-acp
python -m acp_adapter
```

請先安裝支援組件：

```bash
pip install -e '.[acp]'
```

請參閱 [ACP 編輯器整合](../user-guide/features/acp.md) 與 [ACP 內部原理](../developer-guide/acp-internals.md)。

## `hermes mcp`

```bash
hermes mcp <subcommand>
```

管理 MCP (Model Context Protocol) 伺服器配置，並將 Hermes 作為 MCP 伺服器運行。

| 子指令 | 描述 |
|------------|-------------|
| `serve [-v\|--verbose]` | 將 Hermes 作為 MCP 伺服器運行 — 向其他代理公開對話。 |
| `add <name> [--url URL] [--command CMD] [--args ...] [--auth oauth\|header]` | 新增具有工具自動偵測功能的 MCP 伺服器。 |
| `remove <name>` (別名: `rm`) | 從配置中移除 MCP 伺服器。 |
| `list` (別名: `ls`) | 列出已配置的 MCP 伺服器。 |
| `test <name>` | 測試與 MCP 伺服器的連接。 |
| `configure <name>` (別名: `config`) | 切換伺服器的工具選擇。 |

請參閱 [MCP 配置參考](./mcp-config-reference.md)、[在 Hermes 中使用 MCP](../guides/use-mcp-with-hermes.md) 與 [MCP 伺服器模式](../user-guide/features/mcp.md#running-hermes-as-an-mcp-server)。

## `hermes plugins`

```bash
hermes plugins [subcommand]
```

統一的外掛管理 — 將一般外掛、記憶提供商和上下文引擎整合在一個地方。不帶子指令運行 `hermes plugins` 會開啟一個包含兩個區段的複合互動式畫面：

- **一般外掛 (General Plugins)** — 多選核取方塊以啟用/停用已安裝的外掛程式。
- **提供商外掛 (Provider Plugins)** — 單選配置記憶提供商和上下文引擎。在類別上按 ENTER 開啟單選器。

| 子指令 | 描述 |
|------------|-------------|
| *(無)* | 複合互動式 UI — 一般外掛開關 + 提供商外掛配置。 |
| `install <identifier> [--force]` | 從 Git URL 或 `owner/repo` 安裝外掛程式。 |
| `update <name>` | 獲取已安裝外掛程式的最新更改。 |
| `remove <name>` (別名: `rm`, `uninstall`) | 移除已安裝的外掛程式。 |
| `enable <name>` | 啟用已停用的外掛程式。 |
| `disable <name>` | 停用外掛程式而不移除。 |
| `list` (別名: `ls`) | 列出已安裝的外掛程式及其啟用/停用狀態。 |

提供商外掛的選擇會儲存到 `config.yaml`：
- `memory.provider` — 活動記憶提供商 (留空則僅使用內建)
- `context.engine` — 活動上下文引擎 (`"compressor"` 為內建預設值)

一般外掛的停用列表儲存在 `config.yaml` 的 `plugins.disabled` 下。

請參閱 [外掛程式](../user-guide/features/plugins.md) 與 [建立 Hermes 外掛程式](../guides/build-a-hermes-plugin.md)。

## `hermes tools`

```bash
hermes tools [--summary]
```

| 選項 | 描述 |
|--------|-------------|
| `--summary` | 印出當前啟用的工具摘要並退出。 |

不帶 `--summary` 時，會啟動按平台的互動式工具配置 UI。

## `hermes sessions`

```bash
hermes sessions <subcommand>
```

子指令：

| 子指令 | 描述 |
|------------|-------------|
| `list` | 列出最近的工作階段。 |
| `browse` | 具備搜尋與恢復功能的互動式工作階段選擇器。 |
| `export <output> [--session-id ID]` | 將工作階段匯出為 JSONL。 |
| `delete <session-id>` | 刪除一個工作階段。 |
| `prune` | 刪除舊的工作階段。 |
| `stats` | 顯示工作階段儲存統計資訊。 |
| `rename <session-id> <title>` | 設定或更改工作階段標題。 |

## `hermes insights`

```bash
hermes insights [--days N] [--source platform]
```

| 選項 | 描述 |
|--------|-------------|
| `--days <n>` | 分析過去 `n` 天 (預設：30)。 |
| `--source <platform>` | 按來源過濾，例如 `cli`, `telegram` 或 `discord`。 |

## `hermes claw`

```bash
hermes claw migrate [options]
```

將您的 OpenClaw 設定遷移到 Hermes。從 `~/.openclaw` (或自定義路徑) 讀取並寫入至 `~/.hermes`。自動偵測舊版目錄名稱 (`~/.clawdbot`, `~/.moltbot`) 和配置文件名稱 (`clawdbot.json`, `moltbot.json`)。

| 選項 | 描述 |
|--------|-------------|
| `--dry-run` | 預覽將要遷移的內容而不實際寫入。 |
| `--preset <name>` | 遷移預設方案：`full` (預設，包含秘密資訊) 或 `user-data` (排除 API 金鑰)。 |
| `--overwrite` | 在衝突時覆寫現有的 Hermes 檔案 (預設：跳過)。 |
| `--migrate-secrets` | 在遷移中包含 API 金鑰 (在 `--preset full` 時預設啟用)。 |
| `--source <path>` | 自定義 OpenClaw 目錄 (預設：`~/.openclaw`)。 |
| `--workspace-target <path>` | 工作區指令 (AGENTS.md) 的目標目錄。 |
| `--skill-conflict <mode>` | 處理技能名稱衝突：`skip` (預設)、`overwrite` 或 `rename`。 |
| `--yes` | 跳過確認提示。 |

### 遷移內容

遷移涵蓋 30 多個類別，包括人設、記憶、技能、模型提供商、即時通訊平台、代理行為、工作階段策略、MCP 伺服器、TTS 等。項目會被 **直接匯入** 到 Hermes 的等效項目中，或者 **存檔** 以供手動審查。

**直接匯入：** SOUL.md, MEMORY.md, USER.md, AGENTS.md, 技能 (4 個來源目錄), 預設模型, 自定義提供商, MCP 伺服器, 即時通訊平台權杖與允許列表 (Telegram, Discord, Slack, WhatsApp, Signal, Matrix, Mattermost), 代理預設值 (推理投入, 壓縮, 人類延遲, 時區, 沙盒), 工作階段重設策略, 核准規則, TTS 配置, 瀏覽器設定, 工具設定, 執行超時, 指令白名單, 網關配置, 以及來自 3 個來源的 API 金鑰。

**存檔供手動審查：** Cron 任務, 外掛程式, 鉤子 (hooks)/webhooks, 記憶後端 (QMD), 技能註冊配置, UI/身份, 日誌, 多代理設定, 頻道綁定, IDENTITY.md, TOOLS.md, HEARTBEAT.md, BOOTSTRAP.md。

**API 金鑰解析** 按優先順序檢查三個來源：配置值 → `~/.openclaw/.env` → `auth-profiles.json`。所有權杖欄位均支援純字串、環境變數模板 (`${VAR}`) 和 SecretRef 對象。

完整的配置鍵映射、SecretRef 處理詳情和遷移後檢查清單，請參閱 **[完整遷移指南](../guides/migrate-from-openclaw.md)**。

### 範例

```bash
# 預覽將要遷移的內容
hermes claw migrate --dry-run

# 包含 API 金鑰的完整遷移
hermes claw migrate --preset full

# 僅遷移使用者數據 (不含秘密資訊)，覆寫衝突
hermes claw migrate --preset user-data --overwrite

# 從自定義 OpenClaw 路徑遷移
hermes claw migrate --source /home/user/old-openclaw
```

## `hermes dashboard`

```bash
hermes dashboard [options]
```

啟動網頁儀表板 — 一個基於瀏覽器的 UI，用於管理配置、API 金鑰和監控工作階段。需要 `pip install hermes-agent[web]` (FastAPI + Uvicorn)。詳情請參閱 [網頁儀表板](/docs/user-guide/features/web-dashboard)。

| 選項 | 預設值 | 描述 |
|--------|---------|-------------|
| `--port` | `9119` | 網頁伺服器運行的埠 |
| `--host` | `127.0.0.1` | 綁定地址 |
| `--no-open` | — | 不要自動開啟瀏覽器 |

```bash
# 預設 — 開啟瀏覽器至 http://127.0.0.1:9119
hermes dashboard

# 自定義埠，不開啟瀏覽器
hermes dashboard --port 8080 --no-open
```

## `hermes profile`

```bash
hermes profile <subcommand>
```

管理設定檔 (Profiles) — 多個隔離的 Hermes 實例，每個實例都有自己的配置、工作階段、技能和家目錄。

| 子指令 | 描述 |
|------------|-------------|
| `list` | 列出所有設定檔。 |
| `use <name>` | 設定一個固定的預設設定檔。 |
| `create <name> [--clone] [--clone-all] [--clone-from <source>] [--no-alias]` | 建立新設定檔。`--clone` 會從活動設定檔複製配置、`.env` 和 `SOUL.md`。`--clone-all` 複製所有狀態。`--clone-from` 指定來源設定檔。 |
| `delete <name> [-y]` | 刪除設定檔。 |
| `show <name>` | 顯示設定檔詳細資訊 (家目錄、配置等)。 |
| `alias <name> [--remove] [--name NAME]` | 管理用於快速存取設定檔的封裝腳本。 |
| `rename <old> <new>` | 重命名設定檔。 |
| `export <name> [-o FILE]` | 將設定檔匯出為 `.tar.gz` 存檔。 |
| `import <archive> [--name NAME]` | 從 `.tar.gz` 存檔匯入設定檔。 |

範例：

```bash
hermes profile list
hermes profile create work --clone
hermes profile use work
hermes profile alias work --name h-work
hermes profile export work -o work-backup.tar.gz
hermes profile import work-backup.tar.gz --name restored
hermes -p work chat -q "Hello from work profile"
```

## `hermes completion`

```bash
hermes completion [bash|zsh]
```

將 shell 補全腳本印出至 stdout。在您的 shell profile 中 source 該輸出，以啟用對 Hermes 指令、子指令和設定檔名稱的 tab 補全。

範例：

```bash
# Bash
hermes completion bash >> ~/.bashrc

# Zsh
hermes completion zsh >> ~/.zshrc
```

## 維護指令

| 指令 | 描述 |
|---------|-------------|
| `hermes version` | 印出版本資訊。 |
| `hermes update` | 獲取最新更改並重新安裝依賴。 |
| `hermes uninstall [--full] [--yes]` | 移除 Hermes，可選刪除所有配置/數據。 |

## 另請參閱

- [斜線指令參考](./slash-commands.md)
- [CLI 介面](../user-guide/cli.md)
- [工作階段](../user-guide/sessions.md)
- [技能系統](../user-guide/features/skills.md)
- [外觀與主題](../user-guide/features/skins.md)
