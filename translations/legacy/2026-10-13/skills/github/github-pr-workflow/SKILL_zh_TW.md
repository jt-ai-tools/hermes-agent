---
name: github-pr-workflow
description: 完整的 Pull Request 生命週期 — 建立分支、提交變更、開啟 PR、監控 CI 狀態、自動修復失敗並合併。支援使用 gh CLI，或回退至 git + 透過 curl 使用 GitHub REST API。
version: 1.1.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [GitHub, Pull-Requests, CI/CD, Git, Automation, Merge]
    related_skills: [github-auth, github-code-review]
---

# GitHub Pull Request 工作流程

管理 PR 生命週期的完整指南。每個章節會先顯示 `gh` 指令，接著顯示針對沒有 `gh` 的機器所使用的 `git` + `curl` 替代方案。

## 先決條件

- 已通過 GitHub 身份驗證（參閱 `github-auth` 技能）
- 位於具有 GitHub 遠端倉庫的 git 專案中

### 快速驗證偵測

```bash
# 決定在此工作流程中使用哪種方法
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  AUTH="gh"
else
  AUTH="git"
  # 確保具有用於 API 調用的 token
  if [ -z "$GITHUB_TOKEN" ]; then
    if [ -f ~/.hermes/.env ] && grep -q "^GITHUB_TOKEN=" ~/.hermes/.env; then
      GITHUB_TOKEN=$(grep "^GITHUB_TOKEN=" ~/.hermes/.env | head -1 | cut -d= -f2 | tr -d '\n\r')
    elif grep -q "github.com" ~/.git-credentials 2>/dev/null; then
      GITHUB_TOKEN=$(grep "github.com" ~/.git-credentials 2>/dev/null | head -1 | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
    fi
  fi
fi
echo "正在使用: $AUTH"
```

### 從 Git 遠端提取擁有者/倉庫 (Owner/Repo)

許多 `curl` 指令需要 `擁有者/倉庫`。從 git 遠端提取它：

```bash
# 適用於 HTTPS 和 SSH 遠端 URL
REMOTE_URL=$(git remote get-url origin)
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')
OWNER=$(echo "$OWNER_REPO" | cut -d/ -f1)
REPO=$(echo "$OWNER_REPO" | cut -d/ -f2)
echo "擁有者: $OWNER, 倉庫: $REPO"
```

---

## 1. 建立分支

這部分是純 `git` 操作 — 無論哪種方式都相同：

```bash
# 確保您已更新至最新版本
git fetch origin
git checkout main && git pull origin main

# 建立並切換至新分支
git checkout -b feat/add-user-authentication
```

分支命名慣例：
- `feat/描述` — 新功能
- `fix/描述` — 錯誤修復
- `refactor/描述` — 程式碼重構
- `docs/描述` — 文件
- `ci/描述` — CI/CD 變更

## 2. 進行提交 (Commits)

使用 Agent 的檔案工具（`write_file`, `patch`）進行變更，然後提交：

```bash
# 暫存特定檔案
git add src/auth.py src/models/user.py tests/test_auth.py

# 使用約定式提交 (Conventional Commit) 訊息進行提交
git commit -m "feat: 新增基於 JWT 的使用者驗證

- 新增登入/註冊端點
- 新增具有密碼雜湊功能的使用者模型
- 為受保護的路由新增認證中間件
- 為認證流程新增單元測試"
```

提交訊息格式（約定式提交）：
```
類型(範圍): 簡短描述

如果需要，請提供更詳細的解釋。每行不超過 72 個字元。
```

類型：`feat`, `fix`, `refactor`, `docs`, `test`, `ci`, `chore`, `perf`

## 3. 推送並建立 PR

### 推送分支（兩者相同）

```bash
git push -u origin HEAD
```

### 建立 PR

**使用 gh：**

```bash
gh pr create \
  --title "feat: 新增基於 JWT 的使用者驗證" \
  --body "## 摘要
- 新增登入與註冊 API 端點
- JWT token 產生與驗證

## 測試計畫
- [ ] 單元測試通過

Closes #42"
```

選項：`--draft`（草稿）, `--reviewer user1,user2`（審查者）, `--label "enhancement"`（標籤）, `--base develop`（基礎分支）

**使用 git + curl：**

```bash
BRANCH=$(git branch --show-current)

curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$OWNER/$REPO/pulls \
  -d "{
    \"title\": \"feat: 新增基於 JWT 的使用者驗證\",
    \"body\": \"## 摘要\n新增登入與註冊 API 端點。\n\nCloses #42\",
    \"head\": \"$BRANCH\",
    \"base\": \"main\"
  }"
```

回傳的 JSON 包含 PR `number`（編號）— 請儲存以便後續指令使用。

若要建立為草稿，請在 JSON 正文中加入 `"draft": true`。

## 4. 監控 CI 狀態

### 檢查 CI 狀態

**使用 gh：**

```bash
# 單次檢查
gh pr checks

# 持續觀察直到所有檢查完成（每 10 秒輪詢一次）
gh pr checks --watch
```

**使用 git + curl：**

```bash
# 獲取目前分支上最新的提交 SHA
SHA=$(git rev-parse HEAD)

# 查詢組合後的狀態
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/commits/$SHA/status \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"總體狀態: {data['state']}\")
for s in data.get('statuses', []):
    print(f\"  {s['context']}: {s['state']} - {s.get('description', '')}\")"

# 同時檢查 GitHub Actions 的 check runs（不同的端點）
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/commits/$SHA/check-runs \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
for cr in data.get('check_runs', []):
    print(f\"  {cr['name']}: {cr['status']} / {cr['conclusion'] or 'pending'}\")"
```

### 輪詢直到完成 (git + curl)

```bash
# 簡單的輪詢迴圈 — 每 30 秒檢查一次，最多 10 分鐘
SHA=$(git rev-parse HEAD)
for i in $(seq 1 20); do
  STATUS=$(curl -s \
    -H "Authorization: token $GITHUB_TOKEN" \
    https://api.github.com/repos/$OWNER/$REPO/commits/$SHA/status \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['state'])")
  echo "檢查 $i: $STATUS"
  if [ "$STATUS" = "success" ] || [ "$STATUS" = "failure" ] || [ "$STATUS" = "error" ]; then
    break
  fi
  sleep 30
done
```

## 5. 自動修復 CI 失敗

當 CI 失敗時，進行診斷並修復。此迴圈適用於任何一種認證方式。

### 步驟 1：獲取失敗詳情

**使用 gh：**

```bash
# 列出此分支上最近的 workflow 執行記錄
gh run list --branch $(git branch --show-current) --limit 5

# 檢視失敗的日誌
gh run view <RUN_ID> --log-failed
```

**使用 git + curl：**

```bash
BRANCH=$(git branch --show-current)

# 列出此分支上的 workflow 執行記錄
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/actions/runs?branch=$BRANCH&per_page=5" \
  | python3 -c "
import sys, json
runs = json.load(sys.stdin)['workflow_runs']
for r in runs:
    print(f\"執行 ID {r['id']}: {r['name']} - {r['conclusion'] or r['status']}\")"

# 獲取失敗的作業日誌（下載為 zip，解壓縮後讀取）
RUN_ID=<run_id>
curl -s -L \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/runs/$RUN_ID/logs \
  -o /tmp/ci-logs.zip
cd /tmp && unzip -o ci-logs.zip -d ci-logs && cat ci-logs/*.txt
```

### 步驟 2：修復並推送

識別問題後，使用檔案工具（`patch`, `write_file`）進行修復：

```bash
git add <修復的檔案>
git commit -m "fix: 解決 <check_name> 中的 CI 失敗"
git push
```

### 步驟 3：驗證

使用上方第 4 節的指令重新檢查 CI 狀態。

### 自動修復迴圈模式

當被要求自動修復 CI 時，請遵循此迴圈：

1. 檢查 CI 狀態 → 識別失敗
2. 閱讀失敗日誌 → 理解錯誤
3. 使用 `read_file` + `patch`/`write_file` → 修復程式碼
4. `git add . && git commit -m "fix: ..." && git push`
5. 等待 CI → 重新檢查狀態
6. 如果仍然失敗則重複（最多嘗試 3 次，然後詢問使用者）

## 6. 合併 (Merging)

**使用 gh：**

```bash
# 壓縮合併並刪除分支（對功能分支最乾淨的方式）
gh pr merge --squash --delete-branch

# 啟用自動合併（所有檢查通過時自動合併）
gh pr merge --auto --squash --delete-branch
```

**使用 git + curl：**

```bash
PR_NUMBER=<編號>

# 透過 API 合併 PR（壓縮合併）
curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER/merge \
  -d "{
    \"merge_method\": \"squash\",
    \"commit_title\": \"feat: 新增使用者認證 (#$PR_NUMBER)\"
  }"

# 合併後刪除遠端分支
BRANCH=$(git branch --show-current)
git push origin --delete $BRANCH

# 本地切換回 main
git checkout main && git pull origin main
git branch -d $BRANCH
```

合併方法：`"merge"` (合併提交), `"squash"` (壓縮合併), `"rebase"` (變基合併)

### 啟用自動合併 (curl)

```bash
# 自動合併需要倉庫在設定中啟用此功能。
# 由於 REST 不支援自動合併，因此使用 GraphQL API。
PR_NODE_ID=$(curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['node_id'])")

curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/graphql \
  -d "{\"query\": \"mutation { enablePullRequestAutoMerge(input: {pullRequestId: \\\"$PR_NODE_ID\\\", mergeMethod: SQUASH}) { clientMutationId } }\"}"
```

## 7. 完整工作流程範例

```bash
# 1. 從乾淨的 main 開始
git checkout main && git pull origin main

# 2. 建立分支
git checkout -b fix/login-redirect-bug

# 3. (Agent 使用檔案工具進行程式碼變更)

# 4. 提交
git add src/auth/login.py tests/test_login.py
git commit -m "fix: 修正登入後的重新導向 URL

保留 ?next= 參數，而不是一律導向至 /dashboard。"

# 5. 推送
git push -u origin HEAD

# 6. 建立 PR（根據可用工具選擇 gh 或 curl）
# ... (參見第 3 節)

# 7. 監控 CI (參見第 4 節)

# 8. 通過檢查後合併 (參見第 6 節)
```

## 實用 PR 指令參考

| 動作 | gh | git + curl |
|--------|-----|-----------|
| 列出我的 PR | `gh pr list --author @me` | `curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$OWNER/$REPO/pulls?state=open"` |
| 檢視 PR 差異 | `gh pr diff` | `git diff main...HEAD` (本地) 或 `curl -H "Accept: application/vnd.github.diff" ...` |
| 新增評論 | `gh pr comment N --body "..."` | `curl -X POST .../issues/N/comments -d '{"body":"..."}'` |
| 請求審查 | `gh pr edit N --add-reviewer user` | `curl -X POST .../pulls/N/requested_reviewers -d '{"reviewers":["user"]}'` |
| 關閉 PR | `gh pr close N` | `curl -X PATCH .../pulls/N -d '{"state":"closed"}'` |
| 檢出他人的 PR | `gh pr checkout N` | `git fetch origin pull/N/head:pr-N && git checkout pr-N` |
