---
name: github-auth
description: 使用 git（通用）或 gh CLI 為 Agent 設定 GitHub 身份驗證。涵蓋 HTTPS token、SSH 金鑰、憑證輔助程式 (credential helpers) 以及 gh auth — 並具備自動偵測流程以選擇合適的方法。
version: 1.1.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [GitHub, Authentication, Git, gh-cli, SSH, Setup]
    related_skills: [github-pr-workflow, github-code-review, github-issues, github-repo-management]
---

# GitHub 身份驗證設定

此技能用於設定身份驗證，以便 Agent 可以處理 GitHub 儲存庫、PR、Issues 和 CI。涵蓋兩條路徑：

- **`git` (始終可用)** — 使用 HTTPS 個人存取權杖 (personal access tokens) 或 SSH 金鑰
- **`gh` CLI (若已安裝)** — 提供更豐富的 GitHub API 存取權限，且身份驗證流程更簡單

## 偵測流程

當使用者要求您處理 GitHub 時，請先執行此檢查：

```bash
# 檢查可用工具
git --version
gh --version 2>/dev/null || echo "gh not installed"

# 檢查是否已通過身份驗證
gh auth status 2>/dev/null || echo "gh not authenticated"
git config --global credential.helper 2>/dev/null || echo "no git credential helper"
```

**決策樹：**
1. 如果 `gh auth status` 顯示已驗證 → 您已準備就緒，所有操作都使用 `gh`
2. 如果已安裝 `gh` 但未驗證 → 使用下方的 「gh auth」 方法
3. 如果未安裝 `gh` → 使用下方的 「僅限 git」 方法 (不需要 sudo)

---

## 方法 1：僅限 Git 的身份驗證 (無 gh，無 sudo)

這適用於任何已安裝 `git` 的機器。不需要 root 權限。

### 選項 A：使用個人存取權杖 (Personal Access Token) 的 HTTPS (推薦)

這是最可移植的方法 — 適用於任何地方，不需要 SSH 配置。

**步驟 1：建立個人存取權杖**

告知使用者前往： **https://github.com/settings/tokens**

- 點擊 「Generate new token (classic)」
- 給它一個名稱，例如 「hermes-agent」
- 選擇範圍 (scopes)：
  - `repo` (完整的儲存庫存取權限 — 讀取、寫入、推送、PR)
  - `workflow` (觸發並管理 GitHub Actions)
  - `read:org` (如果要處理組織儲存庫)
- 設定到期時間 (預設 90 天是個好選擇)
- 複製權杖 — 它不會再次顯示

**步驟 2：設定 git 以儲存權杖**

```bash
# 設定憑證輔助程式來快取憑證
# "store" 會以純文字形式儲存在 ~/.git-credentials 中 (簡單、持久)
git config --global credential.helper store

# 現在執行一個會觸發身份驗證的測試操作 — git 會提示輸入憑證
# Username: <他們的 GitHub 使用者名稱>
# Password: <貼上個人存取權杖，而不是他們的 GitHub 密碼>
git ls-remote https://github.com/<使用者名稱>/<任一儲存庫>.git
```

輸入一次憑證後，它們就會被儲存並在以後的所有操作中重複使用。

**替代方案：cache 輔助程式 (憑證會從記憶體中過期)**

```bash
# 將憑證在記憶體中快取 8 小時 (28800 秒)，而不是儲存在磁碟上
git config --global credential.helper 'cache --timeout=28800'
```

**替代方案：直接在遠端 URL 中設定權杖 (針對每個儲存庫)**

```bash
# 將權杖嵌入遠端 URL 中 (完全避免憑證提示)
git remote set-url origin https://<使用者名稱>:<權杖>@github.com/<擁有者>/<儲存庫>.git
```

**步驟 3：設定 git 身份**

```bash
# 提交 (commit) 所需 — 設定名稱和電子郵件
git config --global user.name "他們的姓名"
git config --global user.email "their-email@example.com"
```

**步驟 4：驗證**

```bash
# 測試推送存取權限 (現在應該可以直接運作，不需要任何提示)
git ls-remote https://github.com/<使用者名稱>/<任一儲存庫>.git

# 驗證身份
git config --global user.name
git config --global user.email
```

### 選項 B：SSH 金鑰身份驗證

適合偏好 SSH 或已經設定好金鑰的使用者。

**步驟 1：檢查現有的 SSH 金鑰**

```bash
ls -la ~/.ssh/id_*.pub 2>/dev/null || echo "No SSH keys found"
```

**步驟 2：如果需要，生成金鑰**

```bash
# 生成 ed25519 金鑰 (現代、安全、快速)
ssh-keygen -t ed25519 -C "their-email@example.com" -f ~/.ssh/id_ed25519 -N ""

# 顯示公鑰供他們新增到 GitHub
cat ~/.ssh/id_ed25519.pub
```

告知使用者在以下網址新增公鑰： **https://github.com/settings/keys**
- 點擊 「New SSH key」
- 貼上公鑰內容
- 給它一個標題，例如 「hermes-agent-<機器名稱>」

**步驟 3：測試連線**

```bash
ssh -T git@github.com
# 預期結果："Hi <使用者名稱>! You've successfully authenticated..."
```

**步驟 4：設定 git 在 GitHub 上使用 SSH**

```bash
# 自動將 HTTPS GitHub URL 重寫為 SSH
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

**步驟 5：設定 git 身份**

```bash
git config --global user.name "他們的姓名"
git config --global user.email "their-email@example.com"
```

---

## 方法 2：gh CLI 身份驗證

如果已安裝 `gh`，它可以一步處理 API 存取和 git 憑證。

### 互動式瀏覽器登入 (桌面環境)

```bash
gh auth login
# 選擇: GitHub.com
# 選擇: HTTPS
# 透過瀏覽器進行身份驗證
```

### 基於權杖的登入 (無頭伺服器 / SSH 伺服器)

```bash
echo "<他們的權杖>" | gh auth login --with-token

# 透過 gh 設定 git 憑證
gh auth setup-git
```

### 驗證

```bash
gh auth status
```

---

## 在沒有 gh 的情況下使用 GitHub API

當無法使用 `gh` 時，您仍然可以使用帶有個人存取權杖的 `curl` 存取完整的 GitHub API。這也是其他 GitHub 技能實作其回退機制的方式。

### 設定 API 呼叫的權杖

```bash
# 選項 1：匯出為環境變數 (推薦 — 避免出現在指令記錄中)
export GITHUB_TOKEN="<權杖>"

# 然後在 curl 呼叫中使用：
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user
```

### 從 Git 憑證中提取權杖

如果已經配置了 git 憑證 (透過 credential.helper store)，則可以提取權杖：

```bash
# 從 git 憑證儲存庫中讀取
grep "github.com" ~/.git-credentials 2>/dev/null | head -1 | sed 's|https://[^:]*:\([^@]*\)@.*|\1|'
```

### 輔助：偵測身份驗證方法

在任何 GitHub 工作流開始時使用此模式：

```bash
# 先嘗試 gh，若失敗則回退到 git + curl
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  echo "AUTH_METHOD=gh"
elif [ -n "$GITHUB_TOKEN" ]; then
  echo "AUTH_METHOD=curl"
elif [ -f ~/.hermes/.env ] && grep -q "^GITHUB_TOKEN=" ~/.hermes/.env; then
  export GITHUB_TOKEN=$(grep "^GITHUB_TOKEN=" ~/.hermes/.env | head -1 | cut -d= -f2 | tr -d '\n\r')
  echo "AUTH_METHOD=curl"
elif grep -q "github.com" ~/.git-credentials 2>/dev/null; then
  export GITHUB_TOKEN=$(grep "github.com" ~/.git-credentials | head -1 | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
  echo "AUTH_METHOD=curl"
else
  echo "AUTH_METHOD=none"
  echo "Need to set up authentication first"
fi
```

---

## 疑難排解

| 問題 | 解決方案 |
|---------|----------|
| `git push` 要求輸入密碼 | GitHub 已禁用密碼驗證。請使用個人存取權杖作為密碼，或切換到 SSH |
| `remote: Permission to X denied` | 權杖可能缺少 `repo` 範圍 — 請使用正確的範圍重新生成 |
| `fatal: Authentication failed` | 快取的憑證可能已過期 — 執行 `git credential reject` 然後重新驗證 |
| `ssh: connect to host github.com port 22: Connection refused` | 嘗試透過 HTTPS 連接埠使用 SSH：在 `~/.ssh/config` 中為 `Host github.com` 新增 `Port 443` 和 `Hostname ssh.github.com` |
| 憑證無法持久保存 | 檢查 `git config --global credential.helper` — 必須是 `store` 或 `cache` |
| 多個 GitHub 帳號 | 在 `~/.ssh/config` 中為每個主機別名使用不同的 SSH 金鑰，或使用針對每個儲存庫的憑證 URL |
| `gh: command not found` 且無 sudo | 使用上述 方法 1 的僅限 git 方法 — 不需要安裝 |
