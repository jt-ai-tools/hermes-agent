---
name: github-issues
description: 建立、管理、檢修 (triage) 並關閉 GitHub issue。搜尋現有的 issue、新增標籤、指派人員以及連結至 PR。支援使用 gh CLI，或回退至 git + 透過 curl 使用 GitHub REST API。
version: 1.1.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [GitHub, Issues, Project-Management, Bug-Tracking, Triage]
    related_skills: [github-auth, github-pr-workflow]
---

# GitHub Issue 管理

建立、搜尋、檢修 (triage) 並管理 GitHub issue。每個章節會先顯示 `gh` 指令，接著顯示 `curl` 的替代方案。

## 先決條件

- 已通過 GitHub 身份驗證（參閱 `github-auth` 技能）
- 位於具有 GitHub 遠端倉庫的 git 專案中，或明確指定倉庫

### 設定

```bash
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  AUTH="gh"
else
  AUTH="git"
  if [ -z "$GITHUB_TOKEN" ]; then
    if [ -f ~/.hermes/.env ] && grep -q "^GITHUB_TOKEN=" ~/.hermes/.env; then
      GITHUB_TOKEN=$(grep "^GITHUB_TOKEN=" ~/.hermes/.env | head -1 | cut -d= -f2 | tr -d '\n\r')
    elif grep -q "github.com" ~/.git-credentials 2>/dev/null; then
      GITHUB_TOKEN=$(grep "github.com" ~/.git-credentials 2>/dev/null | head -1 | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
    fi
  fi
fi

REMOTE_URL=$(git remote get-url origin)
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')
OWNER=$(echo "$OWNER_REPO" | cut -d/ -f1)
REPO=$(echo "$OWNER_REPO" | cut -d/ -f2)
```

---

## 1. 檢視 Issue

**使用 gh：**

```bash
gh issue list
gh issue list --state open --label "bug"
gh issue list --assignee @me
gh issue list --search "authentication error" --state all
gh issue view 42
```

**使用 curl：**

```bash
# 列出開啟中的 issue
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/issues?state=open&per_page=20" \
  | python3 -c "
import sys, json
for i in json.load(sys.stdin):
    if 'pull_request' not in i:  # GitHub API 在 /issues 中也會回傳 PR
        labels = ', '.join(l['name'] for l in i['labels'])
        print(f\"#{i['number']:5}  {i['state']:6}  {labels:30}  {i['title']}\")"

# 依標籤篩選
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/issues?state=open&labels=bug&per_page=20" \
  | python3 -c "
import sys, json
for i in json.load(sys.stdin):
    if 'pull_request' not in i:
        print(f\"#{i['number']}  {i['title']}\")"

# 檢視特定 issue
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues/42 \
  | python3 -c "
import sys, json
i = json.load(sys.stdin)
labels = ', '.join(l['name'] for l in i['labels'])
assignees = ', '.join(a['login'] for a in i['assignees'])
print(f\"#{i['number']}: {i['title']}\")
print(f\"狀態: {i['state']}  標籤: {labels}  指派人員: {assignees}\")
print(f\"作者: {i['user']['login']}  建立時間: {i['created_at']}\")
print(f\"\n{i['body']}\")"

# 搜尋 issue
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/search/issues?q=authentication+error+repo:$OWNER/$REPO" \
  | python3 -c "
import sys, json
for i in json.load(sys.stdin)['items']:
    print(f\"#{i['number']}  {i['state']:6}  {i['title']}\")"
```

## 2. 建立 Issue

**使用 gh：**

```bash
gh issue create \
  --title "登入重新導向忽略了 ?next= 參數" \
  --body "## 描述
登入後，使用者總是會導向至 /dashboard。

## 重現步驟
1. 在未登入狀態下導航至 /settings
2. 被重新導向至 /login?next=/settings
3. 登入
4. 實際結果：重新導向至 /dashboard（應該導向至 /settings）

## 預期行為
應採納 ?next= 查詢參數。" \
  --label "bug,backend" \
  --assignee "username"
```

**使用 curl：**

```bash
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues \
  -d '{
    "title": "登入重新導向忽略了 ?next= 參數",
    "body": "## 描述\n登入後，使用者總是會導向至 /dashboard。\n\n## 重現步驟\n1. 在未登入狀態下導航至 /settings\n2. 被重新導向至 /login?next=/settings\n3. 登入\n4. 實際結果：重新導向至 /dashboard\n\n## 預期行為\n應採納 ?next= 查詢參數。",
    "labels": ["bug", "backend"],
    "assignees": ["username"]
  }'
```

### 錯誤報告範本 (Bug Report Template)

```
## 錯誤描述
<發生了什麼事>

## 重現步驟
1. <步驟>
2. <步驟>

## 預期行為
<應該發生什麼事>

## 實際行為
<實際發生了什麼事>

## 環境
- OS: <作業系統>
- 版本: <版本>
```

### 功能需求範本 (Feature Request Template)

```
## 功能描述
<您想要的功能>

## 動機
<為什麼這很有用>

## 建議解決方案
<可以如何運作>

## 考慮過的替代方案
<其他方法>
```

## 3. 管理 Issue

### 新增/移除標籤

**使用 gh：**

```bash
gh issue edit 42 --add-label "priority:high,bug"
gh issue edit 42 --remove-label "needs-triage"
```

**使用 curl：**

```bash
# 新增標籤
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues/42/labels \
  -d '{"labels": ["priority:high", "bug"]}'

# 移除標籤
curl -s -X DELETE \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues/42/labels/needs-triage

# 列出倉庫中可用的標籤
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/labels \
  | python3 -c "
import sys, json
for l in json.load(sys.stdin):
    print(f\"  {l['name']:30}  {l.get('description', '')}\")"
```

### 指派人員

**使用 gh：**

```bash
gh issue edit 42 --add-assignee username
gh issue edit 42 --add-assignee @me
```

**使用 curl：**

```bash
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues/42/assignees \
  -d '{"assignees": ["username"]}'
```

### 發表評論

**使用 gh：**

```bash
gh issue comment 42 --body "已調查 — 根因在於認證中間件。正在處理修復方案。"
```

**使用 curl：**

```bash
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues/42/comments \
  -d '{"body": "已調查 — 根因在於認證中間件。正在處理修復方案。"}'
```

### 關閉與重新開啟

**使用 gh：**

```bash
gh issue close 42
gh issue close 42 --reason "not planned"
gh issue reopen 42
```

**使用 curl：**

```bash
# 關閉
curl -s -X PATCH \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues/42 \
  -d '{"state": "closed", "state_reason": "completed"}'

# 重新開啟
curl -s -X PATCH \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues/42 \
  -d '{"state": "open"}'
```

### 將 Issue 連結至 PR

當 PR 合併且正文中包含正確的關鍵字時，Issue 會自動關閉：

```
Closes #42
Fixes #42
Resolves #42
```

從 Issue 建立分支：

**使用 gh：**

```bash
gh issue develop 42 --checkout
```

**使用 git（手動等效操作）：**

```bash
git checkout main && git pull origin main
git checkout -b fix/issue-42-login-redirect
```

## 4. Issue 檢修 (Triage) 工作流程

當被要求檢修 issue 時：

1. **列出尚未檢修的 issue：**

```bash
# 使用 gh
gh issue list --label "needs-triage" --state open

# 使用 curl
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/issues?labels=needs-triage&state=open" \
  | python3 -c "
import sys, json
for i in json.load(sys.stdin):
    if 'pull_request' not in i:
        print(f\"#{i['number']}  {i['title']}\")"
```

2. **閱讀並分類** 每個 issue（檢視詳情，理解錯誤或功能需求）

3. **套用標籤與優先權**（參閱上方的「管理 Issue」）

4. **指派人員**（如果負責人明確）

5. **視需要留下檢修備註**

## 5. 批量操作

對於批次操作，可將 API 調用與 shell 腳本結合：

**使用 gh：**

```bash
# 關閉所有具有特定標籤的 issue
gh issue list --label "wontfix" --json number --jq '.[].number' | \
  xargs -I {} gh issue close {} --reason "not planned"
```

**使用 curl：**

```bash
# 列出帶有標籤的 issue 編號，然後逐一關閉
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/issues?labels=wontfix&state=open" \
  | python3 -c "import sys,json; [print(i['number']) for i in json.load(sys.stdin)]" \
  | while read num; do
    curl -s -X PATCH \
      -H "Authorization: token $GITHUB_TOKEN" \
      https://api.github.com/repos/$OWNER/$REPO/issues/$num \
      -d '{"state": "closed", "state_reason": "not_planned"}'
    echo "已關閉 #$num"
  done
```

## 快速參考表

| 動作 | gh | curl 端點 |
|--------|-----|--------------|
| 列出 issue | `gh issue list` | `GET /repos/{o}/{r}/issues` |
| 檢視 issue | `gh issue view N` | `GET /repos/{o}/{r}/issues/N` |
| 建立 issue | `gh issue create ...` | `POST /repos/{o}/{r}/issues` |
| 新增標籤 | `gh issue edit N --add-label ...` | `POST /repos/{o}/{r}/issues/N/labels` |
| 指派人員 | `gh issue edit N --add-assignee ...` | `POST /repos/{o}/{r}/issues/N/assignees` |
| 發表評論 | `gh issue comment N --body ...` | `POST /repos/{o}/{r}/issues/N/comments` |
| 關閉 issue | `gh issue close N` | `PATCH /repos/{o}/{r}/issues/N` |
| 搜尋 | `gh issue list --search "..."` | `GET /search/issues?q=...` |
