---
name: github-repo-management
description: 複製、建立、衍生 (fork)、配置及管理 GitHub 儲存庫。管理遠端、秘密資訊、發佈 (releases) 及工作流 (workflows)。支援使用 gh CLI，或回退到使用 git + 透過 curl 呼叫 GitHub REST API。
version: 1.1.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [GitHub, Repositories, Git, Releases, Secrets, Configuration]
    related_skills: [github-auth, github-pr-workflow, github-issues]
---

# GitHub 儲存庫管理 (GitHub Repository Management)

建立、複製、衍生 (fork)、配置及管理 GitHub 儲存庫。每個章節優先顯示 `gh` 指令，接著顯示 `git` + `curl` 的回退方案。

## 前置條件

- 已通過 GitHub 驗證（請參閱 `github-auth` 技能）

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

# 取得您的 GitHub 使用者名稱（多項操作需要用到）
if [ "$AUTH" = "gh" ]; then
  GH_USER=$(gh api user --jq '.login')
else
  GH_USER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | python3 -c "import sys,json; print(json.load(sys.stdin)['login'])")
fi
```

如果您已經在儲存庫內：

```bash
REMOTE_URL=$(git remote get-url origin)
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')
OWNER=$(echo "$OWNER_REPO" | cut -d/ -f1)
REPO=$(echo "$OWNER_REPO" | cut -d/ -f2)
```

---

## 1. 複製儲存庫 (Cloning Repositories)

複製 (Cloning) 是純 `git` 操作 —— 兩種方式完全相同：

```bash
# 透過 HTTPS 複製 (適用於認證輔助程式或嵌入權杖的 URL)
git clone https://github.com/owner/repo-name.git

# 複製到特定目錄
git clone https://github.com/owner/repo-name.git ./my-local-dir

# 淺層複製 (對大型儲存庫較快)
git clone --depth 1 https://github.com/owner/repo-name.git

# 複製特定分支
git clone --branch develop https://github.com/owner/repo-name.git

# 透過 SSH 複製 (如果已配置 SSH)
git clone git@github.com:owner/repo-name.git
```

**使用 gh (簡寫)：**

```bash
gh repo clone owner/repo-name
gh repo clone owner/repo-name -- --depth 1
```

## 2. 建立儲存庫 (Creating Repositories)

**使用 gh：**

```bash
# 建立一個公開儲存庫並複製它
gh repo create my-new-project --public --clone

# 私人儲存庫，帶有描述和授權條款
gh repo create my-new-project --private --description "一個有用的工具" --license MIT --clone

# 在組織 (organization) 下建立
gh repo create my-org/my-new-project --public --clone

# 從現有的本地目錄建立
cd /path/to/existing/project
gh repo create my-project --source . --public --push
```

**使用 git + curl：**

```bash
# 透過 API 建立遠端儲存庫
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user/repos \
  -d '{
    "name": "my-new-project",
    "description": "一個有用的工具",
    "private": false,
    "auto_init": true,
    "license_template": "mit"
  }'

# 複製它
git clone https://github.com/$GH_USER/my-new-project.git
cd my-new-project

# -- 或者 -- 將現有本地目錄推送到新儲存庫
cd /path/to/existing/project
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/$GH_USER/my-new-project.git
git push -u origin main
```

在組織下建立：

```bash
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/orgs/my-org/repos \
  -d '{"name": "my-new-project", "private": false}'
```

### 從範本建立 (From a Template)

**使用 gh：**

```bash
gh repo create my-new-app --template owner/template-repo --public --clone
```

**使用 curl：**

```bash
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/owner/template-repo/generate \
  -d '{"owner": "'"$GH_USER"'", "name": "my-new-app", "private": false}'
```

## 3. 衍生儲存庫 (Forking Repositories)

**使用 gh：**

```bash
gh repo fork owner/repo-name --clone
```

**使用 git + curl：**

```bash
# 透過 API 建立衍生 (fork)
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/owner/repo-name/forks

# 等待 GitHub 建立，然後複製
sleep 3
git clone https://github.com/$GH_USER/repo-name.git
cd repo-name

# 將原始儲存庫新增為 "upstream" 遠端
git remote add upstream https://github.com/owner/repo-name.git
```

### 保持衍生儲存庫同步 (Keeping a Fork in Sync)

```bash
# 純 git —— 隨處可用
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

**使用 gh (捷徑)：**

```bash
gh repo sync $GH_USER/repo-name
```

## 4. 儲存庫資訊 (Repository Information)

**使用 gh：**

```bash
gh repo view owner/repo-name
gh repo list --limit 20
gh search repos "machine learning" --language python --sort stars
```

**使用 curl：**

```bash
# 查看儲存庫詳細資訊
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO \
  | python3 -c "
import sys, json
r = json.load(sys.stdin)
print(f\"名稱: {r['full_name']}\")
print(f\"描述: {r['description']}\")
print(f\"星數: {r['stargazers_count']}  衍生數: {r['forks_count']}\")
print(f\"預設分支: {r['default_branch']}\")
print(f\"語言: {r['language']}\")"

# 列出您的儲存庫
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/user/repos?per_page=20&sort=updated" \
  | python3 -c "
import sys, json
for r in json.load(sys.stdin):
    vis = '私人' if r['private'] else '公開'
    print(f\"  {r['full_name']:40}  {vis:8}  {r.get('language', ''):10}  ★{r['stargazers_count']}\")"

# 搜尋儲存庫
curl -s \
  "https://api.github.com/search/repositories?q=machine+learning+language:python&sort=stars&per_page=10" \
  | python3 -c "
import sys, json
for r in json.load(sys.stdin)['items']:
    print(f\"  {r['full_name']:40}  ★{r['stargazers_count']:6}  {r['description'][:60] if r['description'] else ''}\")"
```

## 5. 儲存庫設定 (Repository Settings)

**使用 gh：**

```bash
gh repo edit --description "更新的描述" --visibility public
gh repo edit --enable-wiki=false --enable-issues=true
gh repo edit --default-branch main
gh repo edit --add-topic "machine-learning,python"
gh repo edit --enable-auto-merge
```

**使用 curl：**

```bash
curl -s -X PATCH \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO \
  -d '{
    "description": "更新的描述",
    "has_wiki": false,
    "has_issues": true,
    "allow_auto_merge": true
  }'

# 更新主題 (topics)
curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.mercy-preview+json" \
  https://api.github.com/repos/$OWNER/$REPO/topics \
  -d '{"names": ["machine-learning", "python", "automation"]}'
```

## 6. 分支保護 (Branch Protection)

```bash
# 查看目前的保護設定
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/branches/main/protection

# 設定分支保護
curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/branches/main/protection \
  -d '{
    "required_status_checks": {
      "strict": true,
      "contexts": ["ci/test", "ci/lint"]
    },
    "enforce_admins": false,
    "required_pull_request_reviews": {
      "required_approving_review_count": 1
    },
    "restrictions": null
  }'
```

## 7. 秘密資訊管理 (Secrets Management - GitHub Actions)

**使用 gh：**

```bash
gh secret set API_KEY --body "您的秘密值"
gh secret set SSH_KEY < ~/.ssh/id_rsa
gh secret list
gh secret delete API_KEY
```

**使用 curl：**

秘密資訊需要使用儲存庫的公鑰進行加密 —— 透過 API 操作較為複雜：

```bash
# 取得用於加密秘密資訊的儲存庫公鑰
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/secrets/public-key

# 加密並設定 (需要安裝 PyNaCl 的 Python)
python3 -c "
from base64 import b64encode
from nacl import encoding, public
import json, sys

# 取得公鑰
key_id = '<來自上方的 key_id>'
public_key = '<來自上方的 base64_key>'

# 加密
sealed = public.SealedBox(
    public.PublicKey(public_key.encode('utf-8'), encoding.Base64Encoder)
).encrypt('您的秘密值'.encode('utf-8'))
print(json.dumps({
    'encrypted_value': b64encode(sealed).decode('utf-8'),
    'key_id': key_id
}))"

# 然後 PUT 加密後的秘密資訊
curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/secrets/API_KEY \
  -d '<上方 Python 腳本的輸出內容>'

# 列出秘密資訊 (僅名稱，值會被隱藏)
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/secrets \
  | python3 -c "
import sys, json
for s in json.load(sys.stdin)['secrets']:
    print(f\"  {s['name']:30}  更新於: {s['updated_at']}\")"
```

注意：對於秘密資訊管理，`gh secret set` 要簡單得多。如果需要設定秘密資訊且沒有 `gh`，建議專門為此操作安裝它。

## 8. 發佈 (Releases)

**使用 gh：**

```bash
gh release create v1.0.0 --title "v1.0.0" --generate-notes
gh release create v2.0.0-rc1 --draft --prerelease --generate-notes
gh release create v1.0.0 ./dist/binary --title "v1.0.0" --notes "發佈說明"
gh release list
gh release download v1.0.0 --dir ./downloads
```

**使用 curl：**

```bash
# 建立一個發佈
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/releases \
  -d '{
    "tag_name": "v1.0.0",
    "name": "v1.0.0",
    "body": "## 變更日誌 (Changelog)\n- 功能 A\n- 錯誤修復 B",
    "draft": false,
    "prerelease": false,
    "generate_release_notes": true
  }'

# 列出所有發佈
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/releases \
  | python3 -c "
import sys, json
for r in json.load(sys.stdin):
    tag = r.get('tag_name', '無標籤')
    print(f\"  {tag:15}  {r['name']:30}  {'草稿' if r['draft'] else '已發佈'}\")"

# 上傳發佈資產 (二進位檔案)
RELEASE_ID=<來自建立發佈回應中的 id>
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/octet-stream" \
  "https://uploads.github.com/repos/$OWNER/$REPO/releases/$RELEASE_ID/assets?name=binary-amd64" \
  --data-binary @./dist/binary-amd64
```

## 9. GitHub Actions 工作流 (Workflows)

**使用 gh：**

```bash
gh workflow list
gh run list --limit 10
gh run view <RUN_ID>
gh run view <RUN_ID> --log-failed
gh run rerun <RUN_ID>
gh run rerun <RUN_ID> --failed
gh workflow run ci.yml --ref main
gh workflow run deploy.yml -f environment=staging
```

**使用 curl：**

```bash
# 列出所有工作流
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/workflows \
  | python3 -c "
import sys, json
for w in json.load(sys.stdin)['workflows']:
    print(f\"  {w['id']:10}  {w['name']:30}  {w['state']}\")"

# 列出最近的執行紀錄 (runs)
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/actions/runs?per_page=10" \
  | python3 -c "
import sys, json
for r in json.load(sys.stdin)['workflow_runs']:
    print(f\"  執行紀錄 {r['id']}  {r['name']:30}  {r['conclusion'] or r['status']}\")"

# 下載失敗的執行紀錄日誌
RUN_ID=<run_id>
curl -s -L \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/runs/$RUN_ID/logs \
  -o /tmp/ci-logs.zip
cd /tmp && unzip -o ci-logs.zip -d ci-logs

# 重新執行失敗的工作流
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/runs/$RUN_ID/rerun

# 僅重新執行失敗的工作項目 (jobs)
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/runs/$RUN_ID/rerun-failed-jobs

# 手動觸發工作流 (workflow_dispatch)
WORKFLOW_ID=<workflow_id_或檔案名稱>
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/workflows/$WORKFLOW_ID/dispatches \
  -d '{"ref": "main", "inputs": {"environment": "staging"}}'
```

## 10. Gists

**使用 gh：**

```bash
gh gist create script.py --public --desc "有用的腳本"
gh gist list
```

**使用 curl：**

```bash
# 建立一個 gist
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/gists \
  -d '{
    "description": "有用的腳本",
    "public": true,
    "files": {
      "script.py": {"content": "print(\"hello\")"}
    }
  }'

# 列出您的 gists
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/gists \
  | python3 -c "
import sys, json
for g in json.load(sys.stdin):
    files = ', '.join(g['files'].keys())
    print(f\"  {g['id']}  {g['description'] or '(無描述)':40}  {files}\")"
```

## 快速參考表 (Quick Reference Table)

| 動作 | gh | git + curl |
|--------|-----|-----------|
| 複製 (Clone) | `gh repo clone o/r` | `git clone https://github.com/o/r.git` |
| 建立儲存庫 | `gh repo create name --public` | `curl POST /user/repos` |
| 衍生 (Fork) | `gh repo fork o/r --clone` | `curl POST /repos/o/r/forks` + `git clone` |
| 儲存庫資訊 | `gh repo view o/r` | `curl GET /repos/o/r` |
| 編輯設定 | `gh repo edit --...` | `curl PATCH /repos/o/r` |
| 建立發佈 (Release) | `gh release create v1.0` | `curl POST /repos/o/r/releases` |
| 列出工作流 | `gh workflow list` | `curl GET /repos/o/r/actions/workflows` |
| 重新執行 CI | `gh run rerun ID` | `curl POST /repos/o/r/actions/runs/ID/rerun` |
| 設定秘密資訊 | `gh secret set KEY` | `curl PUT /repos/o/r/actions/secrets/KEY` (+ 加密) |
