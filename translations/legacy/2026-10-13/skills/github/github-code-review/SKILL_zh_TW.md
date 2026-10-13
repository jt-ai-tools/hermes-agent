---
name: github-code-review
description: 透過分析 git diffs、在 PR 上留下行內註解以及執行徹底的推送前審閱來審閱程式碼變更。支援使用 gh CLI，或回退到使用 git + 透過 curl 呼叫 GitHub REST API。
version: 1.1.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [GitHub, Code-Review, Pull-Requests, Git, Quality]
    related_skills: [github-auth, github-pr-workflow]
---

# GitHub 程式碼審閱 (GitHub Code Review)

在推送之前對本地變更執行程式碼審閱，或審閱 GitHub 上開啟的 PR。此技能的大部分內容使用純 `git` —— `gh`/`curl` 的區別僅在於 PR 層級的互動。

## 前置條件

- 已通過 GitHub 驗證（請參閱 `github-auth` 技能）
- 位於 git 儲存庫內

### 設定（用於 PR 互動）

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

## 1. 審閱本地變更 (推送前)

這是純 `git` 操作 —— 隨處可用，無需 API。

### 取得 Diff

```bash
# 已暫存的變更 (即將被 commit 的內容)
git diff --staged

# 所有變更 vs main (PR 將包含的內容)
git diff main...HEAD

# 僅顯示檔案名稱
git diff main...HEAD --name-only

# 統計摘要 (每個檔案的新增/刪除行數)
git diff main...HEAD --stat
```

### 審閱策略

1. **先了解大局：**

```bash
git diff main...HEAD --stat
git log main..HEAD --oneline
```

2. **逐一檔案審閱** —— 對變更的檔案使用 `read_file` 以取得完整上下文，並使用 diff 查看變更內容：

```bash
git diff main...HEAD -- src/auth/login.py
```

3. **檢查常見問題：**

```bash
# 遺留的調試語句、TODO、console.log
git diff main...HEAD | grep -n "print(\|console\.log\|TODO\|FIXME\|HACK\|XXX\|debugger"

# 意外暫存的大檔案
git diff main...HEAD --stat | sort -t'|' -k2 -rn | head -10

# 密鑰或憑證模式
git diff main...HEAD | grep -in "password\|secret\|api_key\|token.*=\|private_key"

# 合併衝突標記
git diff main...HEAD | grep -n "<<<<<<\|>>>>>>\|======="
```

4. **向使用者提供結構化的回饋。**

### 審閱輸出格式

審閱本地變更時，請按此結構呈現結果：

```
## 程式碼審閱摘要 (Code Review Summary)

### 嚴重 (Critical)
- **src/auth.py:45** — SQL 注入：使用者輸入直接傳遞給查詢。
  建議：使用參數化查詢。

### 警告 (Warnings)
- **src/models/user.py:23** — 密碼以明文存儲。請使用 bcrypt 或 argon2。
- **src/api/routes.py:112** — 登入端點缺乏速率限制 (rate limiting)。

### 建議 (Suggestions)
- **src/utils/helpers.py:8** — 與 `src/core/utils.py:34` 中的邏輯重複。請合併。
- **tests/test_auth.py** — 遺漏邊際案例：權杖過期測試。

### 看起來不錯 (Looks Good)
- 中間層 (middleware layer) 的關注點分離清晰
- 正常路徑 (happy path) 的測試覆蓋率良好
```

---

## 2. 審閱 GitHub 上的 Pull Request

### 查看 PR 詳細資訊

**使用 gh：**

```bash
gh pr view 123
gh pr diff 123
gh pr diff 123 --name-only
```

**使用 git + curl：**

```bash
PR_NUMBER=123

# 取得 PR 詳細資訊
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER \
  | python3 -c "
import sys, json
pr = json.load(sys.stdin)
print(f\"標題: {pr['title']}\")
print(f\"作者: {pr['user']['login']}\")
print(f\"分支: {pr['head']['ref']} -> {pr['base']['ref']}\")
print(f\"狀態: {pr['state']}\")
print(f\"描述:\n{pr['body']}\")"

# 列出變更的檔案
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER/files \
  | python3 -c "
import sys, json
for f in json.load(sys.stdin):
    print(f\"{f['status']:10} +{f['additions']:-4} -{f['deletions']:-4}  {f['filename']}\")"
```

### 在本地檢出 PR 以進行完整審閱

這可以使用純 `git` 完成 —— 不需要 `gh`：

```bash
# 擷取 PR 分支並檢出
git fetch origin pull/123/head:pr-123
git checkout pr-123

# 現在您可以使用 read_file, search_files, 執行測試等。

# 查看與基準分支的差異
git diff main...pr-123
```

**使用 gh (捷徑)：**

```bash
gh pr checkout 123
```

### 在 PR 上留下註解

**一般的 PR 註解 —— 使用 gh：**

```bash
gh pr comment 123 --body "整體看起來不錯，下面有一些建議。"
```

**一般的 PR 註解 —— 使用 curl：**

```bash
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues/$PR_NUMBER/comments \
  -d '{"body": "整體看起來不錯，下面有一些建議。"}'
```

### 留下行內審閱註解 (Inline Review Comments)

**單個行內註解 —— 使用 gh (透過 API)：**

```bash
HEAD_SHA=$(gh pr view 123 --json headRefOid --jq '.headRefOid')

gh api repos/$OWNER/$REPO/pulls/123/comments \
  --method POST \
  -f body="這可以使用列表推導式 (list comprehension) 來簡化。" \
  -f path="src/auth/login.py" \
  -f commit_id="$HEAD_SHA" \
  -f line=45 \
  -f side="RIGHT"
```

**單個行內註解 —— 使用 curl：**

```bash
# 取得 head commit SHA
HEAD_SHA=$(curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['head']['sha'])")

curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER/comments \
  -d "{
    \"body\": \"這可以使用列表推導式 (list comprehension) 來簡化。\",
    \"path\": \"src/auth/login.py\",
    \"commit_id\": \"$HEAD_SHA\",
    \"line\": 45,
    \"side\": \"RIGHT\"
  }"
```

### 提交正式審閱 (批准 / 請求變更)

**使用 gh：**

```bash
gh pr review 123 --approve --body "LGTM!"
gh pr review 123 --request-changes --body "請參閱行內註解。"
gh pr review 123 --comment --body "一些建議，並非強制性。"
```

**使用 curl —— 原子性提交多個註解的審閱：**

```bash
HEAD_SHA=$(curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['head']['sha'])")

curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER/reviews \
  -d "{
    \"commit_id\": \"$HEAD_SHA\",
    \"event\": \"COMMENT\",
    \"body\": \"來自 Hermes Agent 的程式碼審閱\",
    \"comments\": [
      {\"path\": \"src/auth.py\", \"line\": 45, \"body\": \"使用參數化查詢以防止 SQL 注入。\"},
      {\"path\": \"src/models/user.py\", \"line\": 23, \"body\": \"在存儲前使用 bcrypt 對密碼進行雜湊。\"},
      {\"path\": \"tests/test_auth.py\", \"line\": 1, \"body\": \"新增權杖過期邊際案例的測試。\"}
    ]
  }"
```

事件值：`"APPROVE"`, `"REQUEST_CHANGES"`, `"COMMENT"`

`line` 欄位指的是檔案 *新* 版本中的行號。對於刪除的行，請使用 `"side": "LEFT"`。

---

## 3. 審閱檢查清單 (Review Checklist)

執行程式碼審閱（本地或 PR）時，請系統地檢查：

### 正確性 (Correctness)
- 程式碼是否符合其聲明的功能？
- 是否處理了邊際案例（空輸入、空值、大數據、並行存取）？
- 錯誤路徑是否得到優雅處理？

### 安全性 (Security)
- 無寫死的秘密、憑證或 API 金鑰
- 對使用者輸入進行驗證
- 無 SQL 注入、XSS 或路徑遍歷
- 必要時進行身份驗證/授權檢查

### 程式碼品質 (Code Quality)
- 命稱清晰（變數、函數、類別）
- 無不必要的複雜性或過早的抽象
- DRY —— 無應提取的重複邏輯
- 函數職責單一 (single responsibility)

### 測試 (Testing)
- 是否測試了新的程式碼路徑？
- 是否涵蓋了正常路徑和錯誤情況？
- 測試是否易讀且易於維護？

### 效能 (Performance)
- 無 N+1 查詢或不必要的迴圈
- 在有益之處使用適當的快取
- 異步程式碼路徑中無阻塞操作

### 文件 (Documentation)
- 公共 API 已記錄
- 非顯而易見的邏輯有註解解釋「為什麼」
- 如果行為改變，README 已更新

---

## 4. 推送前審閱工作流 (Pre-Push Review Workflow)

當使用者要求您「審閱程式碼」或「在推送前檢查」時：

1. `git diff main...HEAD --stat` — 查看變更範圍
2. `git diff main...HEAD` — 閱讀完整 diff
3. 對於每個變更的檔案，如果需要更多上下文，請使用 `read_file`
4. 應用上述檢查清單
5. 以結構化格式（嚴重 / 警告 / 建議 / 看起來不錯）呈現結果
6. 如果發現嚴重問題，在使用者推送前提供修復建議

---

## 5. PR 審閱工作流 (端到端)

當使用者要求您「審閱 PR #N」、「查看此 PR」或提供 PR URL 時，請遵循此流程：

### 步驟 1：設定環境

```bash
source ~/.hermes/skills/github/github-auth/scripts/gh-env.sh
# 或執行此技能頂部的行內設定區塊
```

### 步驟 2：收集 PR 上下文

在深入研究程式碼之前，獲取 PR 元數據、描述和變更檔案列表以瞭解範圍。

**使用 gh：**
```bash
gh pr view 123
gh pr diff 123 --name-only
gh pr checks 123
```

**使用 curl：**
```bash
PR_NUMBER=123

# PR 詳細資訊（標題、作者、描述、分支）
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/pulls/$PR_NUMBER

# 帶有行數統計的變更檔案
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/pulls/$PR_NUMBER/files
```

### 步驟 3：在本地檢出 PR

這讓您可以完整存取 `read_file`、`search_files` 以及執行測試的能力。

```bash
git fetch origin pull/$PR_NUMBER/head:pr-$PR_NUMBER
git checkout pr-$PR_NUMBER
```

### 步驟 4：閱讀 diff 並瞭解變更

```bash
# 與基準分支的完整 diff
git diff main...HEAD

# 或者對於大型 PR 逐一查看檔案
git diff main...HEAD --name-only
# 然後對於每個檔案：
git diff main...HEAD -- path/to/file.py
```

對於每個變更的檔案，使用 `read_file` 查看變更周圍的完整上下文 —— 僅憑 diff 可能會遺漏只有在周圍程式碼中才可見的問題。

### 步驟 5：在本地執行自動化檢查（如果適用）

```bash
# 如果有測試套件，執行測試
python -m pytest 2>&1 | tail -20
# 或：npm test, cargo test, go test ./..., 等。

# 如果已配置，執行 linter
ruff check . 2>&1 | head -30
# 或：eslint, clippy, 等。
```

### 步驟 6：應用審閱檢查清單（第 3 節）

檢查每個類別：正確性、安全性、程式碼品質、測試、效能、文件。

### 步驟 7：將審閱發佈到 GitHub

收集您的發現並將其作為帶有行內註解的正式審閱提交。

**使用 gh：**
```bash
# 如果沒有問題 — 批准
gh pr review $PR_NUMBER --approve --body "由 Hermes Agent 審閱。程式碼看起來很乾淨 —— 測試覆蓋率良好，無安全疑慮。"

# 如果發現問題 — 要求變更並提供行內註解
gh pr review $PR_NUMBER --request-changes --body "發現一些問題 —— 請參閱行內註解。"
```

**使用 curl — 帶有多個行內註解的原子審閱：**
```bash
HEAD_SHA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/pulls/$PR_NUMBER \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['head']['sha'])")

# 建立審閱 JSON — 事件為 APPROVE, REQUEST_CHANGES, 或 COMMENT
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/pulls/$PR_NUMBER/reviews \
  -d "{
    \"commit_id\": \"$HEAD_SHA\",
    \"event\": \"REQUEST_CHANGES\",
    \"body\": \"## Hermes Agent 審閱\n\n發現 2 個問題，1 個建議。請參閱行內註解。\",
    \"comments\": [
      {\"path\": \"src/auth.py\", \"line\": 45, \"body\": \"🔴 **嚴重：** 使用者輸入直接傳遞給 SQL 查詢 —— 請使用參數化查詢。\"},
      {\"path\": \"src/models.py\", \"line\": 23, \"body\": \"⚠️ **警告：** 存儲密碼前未進行雜湊。\"},
      {\"path\": \"src/utils.py\", \"line\": 8, \"body\": \"💡 **建議：** 此邏輯與 core/utils.py:34 重複。\"}
    ]
  }"
```

### 步驟 8：同時發佈摘要註解

除了行內註解外，留下一個頂層摘要，以便 PR 作者能一目了然地看到全貌。請使用 `references/review-output-template.md` 中的審閱輸出格式。

**使用 gh：**
```bash
gh pr comment $PR_NUMBER --body "$(cat <<'EOF'
## 程式碼審閱摘要 (Code Review Summary)

**裁決：要求變更 (Changes Requested)** (2 個問題, 1 個建議)

### 🔴 嚴重 (Critical)
- **src/auth.py:45** — SQL 注入漏洞

### ⚠️ 警告 (Warnings)
- **src/models.py:23** — 明文存儲密碼

### 💡 建議 (Suggestions)
- **src/utils.py:8** — 重複邏輯，考慮合併

### ✅ 看起來不錯 (Looks Good)
- 清晰的 API 設計
- 中間層良好的錯誤處理

---
*由 Hermes Agent 審閱*
EOF
)"
```

### 步驟 9：清理

```bash
git checkout main
git branch -D pr-$PR_NUMBER
```

### 決定：批准 vs 要求變更 vs 註解

- **批准 (Approve)** — 無嚴重或警告級別的問題，僅有微小建議或完全沒問題
- **要求變更 (Request Changes)** — 任何應在合併前修復的嚴重或警告級別問題
- **註解 (Comment)** — 觀察和建議，但非強制性（在您不確定或 PR 是草稿時使用）
