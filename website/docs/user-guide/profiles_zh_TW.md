---
sidebar_position: 2
---

# Profiles：執行多個 Agent

在同一台機器上執行多個獨立的 Hermes Agent — 每個 Agent 都有自己的配置、API 金鑰、記憶、會話、技能和閘道 (Gateway)。

## 什麼是 Profile？

Profile 是一個完全隔離的 Hermes 環境。每個 Profile 都會有自己的目錄，其中包含自己的 `config.yaml`、`.env`、`SOUL.md`、記憶、會話、技能、cron 工作和狀態資料庫。Profile 讓您可以為不同目的執行不同的 Agent — 例如程式碼編寫助手、個人機器人、研究 Agent — 且彼此互不干擾。

當您建立 Profile 時，它會自動變成一個獨立的指令。例如建立一個名為 `coder` 的 Profile，您就立即擁有了 `coder chat`、`coder setup`、`coder gateway start` 等指令。

## 快速入門

```bash
hermes profile create coder       # 建立 Profile 並產生 "coder" 指令別名
coder setup                       # 配置 API 金鑰與模型
coder chat                        # 開始聊天
```

就這麼簡單。`coder` 現在是一個完全獨立的 Agent。它有自己的配置、自己的記憶，以及它專屬的一切。

## 建立 Profile

### 空白 Profile

```bash
hermes profile create mybot
```

建立一個包含預載隨附技能的新 Profile。執行 `mybot setup` 以配置 API 金鑰、模型與閘道 Token。

### 僅複製配置 (`--clone`)

```bash
hermes profile create work --clone
```

將目前的 `config.yaml`、`.env` 與 `SOUL.md` 複製到新 Profile 中。使用相同的 API 金鑰與模型，但擁有全新的會話與記憶。您可以編輯 `~/.hermes/profiles/work/.env` 使用不同的 API 金鑰，或編輯 `~/.hermes/profiles/work/SOUL.md` 使用不同的個性。

### 完整複製 (`--clone-all`)

```bash
hermes profile create backup --clone-all
```

複製**所有內容** — 配置、API 金鑰、個性、所有記憶、完整的會話歷史記錄、技能、cron 工作、外掛。這是一個完整的快照。適用於備份或分支出一個已經擁有上下文的 Agent。

### 從特定 Profile 複製

```bash
hermes profile create work --clone --clone-from coder
```

:::tip Honcho 記憶與 Profile
啟用 Honcho 時，`--clone` 會自動為新 Profile 建立專用的 AI Peer，同時共享同一個使用者工作區。每個 Profile 都會建立自己的觀察與身分。詳情請參閱 [Honcho -- 多 Agent / Profile](./features/memory-providers.md#honcho)。
:::

## 使用 Profile

### 指令別名

每個 Profile 都會在 `~/.local/bin/<name>` 自動獲得一個指令別名：

```bash
coder chat                    # 與 coder agent 聊天
coder setup                   # 配置 coder 的設定
coder gateway start           # 啟動 coder 的閘道
coder doctor                  # 檢查 coder 的狀態
coder skills list             # 列出 coder 的技能
coder config set model.model anthropic/claude-sonnet-4
```

別名適用於每個 hermes 子指令 — 本質上它就是 `hermes -p <name>`。

### `-p` 標記

您也可以在任何指令中明確指定 Profile：

```bash
hermes -p coder chat
hermes --profile=coder doctor
hermes chat -p coder -q "hello"    # 可放在任何位置
```

### 黏滯性預設值 (`hermes profile use`)

```bash
hermes profile use coder
hermes chat                   # 現在目標會是 coder
hermes tools                  # 配置 coder 的工具
hermes profile use default    # 切換回預設值
```

設定一個預設值，讓單純的 `hermes` 指令指向該 Profile。類似 `kubectl config use-context` 的概念。

### 確認目前位置

CLI 始終會顯示目前正在使用哪個 Profile：

- **提示符**：顯示 `coder ❯` 而非 `❯`
- **橫幅**：啟動時顯示 `Profile: coder`
- **`hermes profile`**：顯示目前 Profile 名稱、路徑、模型、閘道狀態

## 執行閘道 (Gateways)

每個 Profile 都會作為獨立程序執行自己的閘道，並使用自己的機器人 Token：

```bash
coder gateway start           # 啟動 coder 的閘道
assistant gateway start       # 啟動 assistant 的閘道 (獨立程序)
```

### 不同的機器人 Token

每個 Profile 都有自己的 `.env` 檔案。請在各個 Profile 中配置不同的 Telegram/Discord/Slack 機器人 Token：

```bash
# 編輯 coder 的 Token
nano ~/.hermes/profiles/coder/.env

# 編輯 assistant 的 Token
nano ~/.hermes/profiles/assistant/.env
```

### 安全性：Token 鎖定

如果兩個 Profile 意外使用了相同的機器人 Token，第二個閘道會被封鎖，並顯示明確的錯誤訊息，告知衝突的 Profile 名稱。支援 Telegram、Discord、Slack、WhatsApp 與 Signal。

### 持久服務

```bash
coder gateway install         # 建立 hermes-gateway-coder systemd/launchd 服務
assistant gateway install     # 建立 hermes-gateway-assistant 服務
```

每個 Profile 都會獲得自己的服務名稱。它們獨立執行。

## 配置 Profile

每個 Profile 都有專屬的：

- **`config.yaml`** — 模型、提供商、工具集、所有設定
- **`.env`** — API 金鑰、機器人 Token
- **`SOUL.md`** — 個性與指令

```bash
coder config set model.model anthropic/claude-sonnet-4
echo "您是一位專注的程式碼編寫助手。" > ~/.hermes/profiles/coder/SOUL.md
```

## 更新

執行 `hermes update` 會拉取一次程式碼 (共享)，並自動同步新的隨附技能到**所有** Profile：

```bash
hermes update
# → 程式碼已更新 (12 個提交)
# → 技能已同步：default (已是最新), coder (+2 新), assistant (+2 新)
```

使用者修改過的技能絕不會被覆寫。

## 管理 Profile

```bash
hermes profile list           # 顯示所有 Profile 及其狀態
hermes profile show coder     # 單一 Profile 的詳細資訊
hermes profile rename coder dev-bot   # 重新命名 (更新別名與服務)
hermes profile export coder   # 匯出為 coder.tar.gz
hermes profile import coder.tar.gz   # 從封存檔匯入
```

## 刪除 Profile

```bash
hermes profile delete coder
```

這會停止閘道、移除 systemd/launchd 服務、移除指令別名，並刪除所有 Profile 資料。系統會要求您輸入 Profile 名稱以進行確認。

使用 `--yes` 略過確認：`hermes profile delete coder --yes`

:::note
您無法刪除預設 Profile (`~/.hermes`)。若要移除所有內容，請使用 `hermes uninstall`。
:::

## Tab 自動補全

```bash
# Bash
eval "$(hermes completion bash)"

# Zsh
eval "$(hermes completion zsh)"
```

將此行加入您的 `~/.bashrc` 或 `~/.zshrc` 以實現持久補全。可補全 `-p` 後的 Profile 名稱、Profile 子指令以及頂層指令。

## 運作方式

Profile 使用 `HERMES_HOME` 環境變數。當您執行 `coder chat` 時，包裝指令碼會在啟動 hermes 前設定 `HERMES_HOME=~/.hermes/profiles/coder`。由於程式碼庫中有超過 119 個檔案透過 `get_hermes_home()` 解析路徑，因此一切都會自動範圍限定在 Profile 的目錄下 — 包括配置、會話、記憶、技能、狀態資料庫、閘道 PID、日誌和 cron 工作。

預設 Profile 就是 `~/.hermes` 本身。無需遷移 — 現有安裝的運作方式完全相同。
