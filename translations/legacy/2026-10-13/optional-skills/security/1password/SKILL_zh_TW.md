---
name: 1password
description: 設定與使用 1Password CLI (op)。用於安裝 CLI、啟用桌面應用程式整合、登入，以及為命令讀取和注入機密。
version: 1.0.0
author: arceus77-7, enhanced by Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [安全, 機密, 1password, op, cli]
    category: 安全
setup:
  help: "在 https://my.1password.com → 設定 → 服務帳號 建立服務帳號"
  collect_secrets:
    - env_var: OP_SERVICE_ACCOUNT_TOKEN
      prompt: "1Password 服務帳號權杖 (Token)"
      provider_url: "https://developer.1password.com/docs/service-accounts/"
      secret: true
---

# 1Password CLI

當使用者希望透過 1Password 而非純文字環境變數或檔案來管理機密時，請使用此技能。

## 需求

- 1Password 帳號
- 已安裝 1Password CLI (`op`)
- 具備以下之一：桌面應用程式整合、服務帳號權杖 (`OP_SERVICE_ACCOUNT_TOKEN`) 或 Connect 伺服器
- 具備 `tmux`，以便在 Hermes 終端機呼叫期間建立穩定的驗證工作階段 (僅限桌面應用程式流程)

## 何時使用

- 安裝或設定 1Password CLI
- 使用 `op signin` 登入
- 讀取機密引用，如 `op://Vault/Item/field`
- 使用 `op inject` 將機密注入設定檔或範本
- 透過 `op run` 執行帶有機密環境變數的命令

## 驗證方法

### 服務帳號 (推薦給 Hermes 使用)

在 `~/.hermes/.env` 中設定 `OP_SERVICE_ACCOUNT_TOKEN` (此技能在首次載入時會提示輸入)。
不需要桌面應用程式。支援 `op read`, `op inject`, `op run`。

```bash
export OP_SERVICE_ACCOUNT_TOKEN="在此輸入您的權杖"
op whoami  # 驗證 — 應顯示 Type: SERVICE_ACCOUNT
```

### 桌面應用程式整合 (互動式)

1. 在 1Password 桌面應用程式中啟用：設定 → 開發者 → 與 1Password CLI 整合
2. 確保應用程式已解鎖
3. 執行 `op signin` 並核准生物辨識提示

### Connect 伺服器 (自行託管)

```bash
export OP_CONNECT_HOST="http://localhost:8080"
export OP_CONNECT_TOKEN="在此輸入您的 Connect 權杖"
```

## 設定

1. 安裝 CLI：

```bash
# macOS
brew install 1password-cli

# Linux (官方套件/安裝文件)
# 請參閱 references/get-started.md 以獲取特定發行版的連結。

# Windows (winget)
winget install AgileBits.1Password.CLI
```

2. 驗證：

```bash
op --version
```

3. 選擇上述一種驗證方法並進行設定。

## Hermes 執行模式 (桌面應用程式流程)

Hermes 終端機命令預設是非互動式的，且在不同呼叫之間可能會丟失驗證上下文。
為了配合桌面應用程式整合穩定地使用 `op`，請在專用的 tmux 工作階段中執行登入和機密操作。

注意：使用 `OP_SERVICE_ACCOUNT_TOKEN` 時**不需要**這樣做 — 權杖會自動在各個終端機呼叫之間保持有效。

```bash
SOCKET_DIR="${TMPDIR:-/tmp}/hermes-tmux-sockets"
mkdir -p "$SOCKET_DIR"
SOCKET="$SOCKET_DIR/hermes-op.sock"
SESSION="op-auth-$(date +%Y%m%d-%H%M%S)"

tmux -S "$SOCKET" new -d -s "$SESSION" -n shell

# 登入 (出現提示時在桌面應用程式中核准)
tmux -S "$SOCKET" send-keys -t "$SESSION":0.0 -- "eval \"\$(op signin --account my.1password.com)\"" Enter

# 驗證身份
tmux -S "$SOCKET" send-keys -t "$SESSION":0.0 -- "op whoami" Enter

# 讀取範例
tmux -S "$SOCKET" send-keys -t "$SESSION":0.0 -- "op read 'op://Private/Npmjs/one-time password?attribute=otp'" Enter

# 需要時擷取輸出
tmux -S "$SOCKET" capture-pane -p -J -t "$SESSION":0.0 -S -200

# 清理
tmux -S "$SOCKET" kill-session -t "$SESSION"
```

## 常見操作

### 讀取機密

```bash
op read "op://app-prod/db/password"
```

### 獲取一次性密碼 (OTP)

```bash
op read "op://app-prod/npm/one-time password?attribute=otp"
```

### 注入到範本中

```bash
echo "db_password: {{ op://app-prod/db/password }}" | op inject
```

### 執行帶有機密環境變數的命令

```bash
export DB_PASSWORD="op://app-prod/db/password"
op run -- sh -c '[ -n "$DB_PASSWORD" ] && echo "DB_PASSWORD is set" || echo "DB_PASSWORD missing"'
```

## 護欄 (Guardrails)

- 除非使用者明確要求數值，否則切勿將原始機密列印回傳給使用者。
- 優先使用 `op run` / `op inject`，而非將機密寫入檔案。
- 如果命令失敗並顯示 "account is not signed in"，請在同一個 tmux 工作階段中重新執行 `op signin`。
- 如果無法使用桌面應用程式整合 (如無頭環境/CI)，請使用服務帳號權杖流程。

## CI / 無頭環境說明

對於非互動式用途，請使用 `OP_SERVICE_ACCOUNT_TOKEN` 進行驗證，避免使用互動式 `op signin`。
服務帳號需要 CLI v2.18.0+。

## 參考資料

- `references/get-started.md`
- `references/cli-examples.md`
- https://developer.1password.com/docs/cli/
- https://developer.1password.com/docs/service-accounts/
