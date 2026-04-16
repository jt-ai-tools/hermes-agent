# GitHub REST API 速查表 (GitHub REST API Cheatsheet)

基礎 URL (Base URL): `https://api.github.com`

所有請求皆需帶有：`-H "Authorization: token $GITHUB_TOKEN"`

使用 `gh-env.sh` 輔助腳本自動設定 `$GITHUB_TOKEN`、`$GH_OWNER` 及 `$GH_REPO`：
```bash
source ~/.hermes/skills/github/github-auth/scripts/gh-env.sh
```

## 儲存庫 (Repositories)

| 動作 | 方法 | 端點 (Endpoint) |
|--------|--------|----------|
| 取得儲存庫資訊 | GET | `/repos/{owner}/{repo}` |
| 建立儲存庫 (使用者) | POST | `/user/repos` |
| 建立儲存庫 (組織) | POST | `/orgs/{org}/repos` |
| 更新儲存庫 | PATCH | `/repos/{owner}/{repo}` |
| 刪除儲存庫 | DELETE | `/repos/{owner}/{repo}` |
| 列出您的儲存庫 | GET | `/user/repos?per_page=30&sort=updated` |
| 列出組織儲存庫 | GET | `/orgs/{org}/repos` |
| 衍生儲存庫 (Fork) | POST | `/repos/{owner}/{repo}/forks` |
| 從範本建立 | POST | `/repos/{owner}/{template}/generate` |
| 取得主題 (Topics) | GET | `/repos/{owner}/{repo}/topics` |
| 設定主題 (Topics) | PUT | `/repos/{owner}/{repo}/topics` |

## Pull Requests

| 動作 | 方法 | 端點 (Endpoint) |
|--------|--------|----------|
| 列出 PR | GET | `/repos/{owner}/{repo}/pulls?state=open` |
| 建立 PR | POST | `/repos/{owner}/{repo}/pulls` |
| 取得 PR | GET | `/repos/{owner}/{repo}/pulls/{number}` |
| 更新 PR | PATCH | `/repos/{owner}/{repo}/pulls/{number}` |
| 列出 PR 檔案 | GET | `/repos/{owner}/{repo}/pulls/{number}/files` |
| 合併 PR | PUT | `/repos/{owner}/{repo}/pulls/{number}/merge` |
| 要求審閱者 | POST | `/repos/{owner}/{repo}/pulls/{number}/requested_reviewers` |
| 建立審閱 | POST | `/repos/{owner}/{repo}/pulls/{number}/reviews` |
| 行內註解 | POST | `/repos/{owner}/{repo}/pulls/{number}/comments` |

### PR 合併主體 (PR Merge Body)

```json
{"merge_method": "squash", "commit_title": "feat: description (#N)"}
```

合併方法：`"merge"`, `"squash"`, `"rebase"`

### PR 審閱事件 (PR Review Events)

`"APPROVE"`, `"REQUEST_CHANGES"`, `"COMMENT"`

## Issues

| 動作 | 方法 | 端點 (Endpoint) |
|--------|--------|----------|
| 列出 Issues | GET | `/repos/{owner}/{repo}/issues?state=open` |
| 建立 Issue | POST | `/repos/{owner}/{repo}/issues` |
| 取得 Issue | GET | `/repos/{owner}/{repo}/issues/{number}` |
| 更新 Issue | PATCH | `/repos/{owner}/{repo}/issues/{number}` |
| 新增註解 | POST | `/repos/{owner}/{repo}/issues/{number}/comments` |
| 新增標籤 | POST | `/repos/{owner}/{repo}/issues/{number}/labels` |
| 移除標籤 | DELETE | `/repos/{owner}/{repo}/issues/{number}/labels/{name}` |
| 新增指派對象 | POST | `/repos/{owner}/{repo}/issues/{number}/assignees` |
| 列出所有標籤 | GET | `/repos/{owner}/{repo}/labels` |
| 搜尋 Issues | GET | `/search/issues?q={query}+repo:{owner}/{repo}` |

注意：Issues API 也會回傳 PR。解析時請使用 `"pull_request" not in item` 進行過濾。

## CI / GitHub Actions

| 動作 | 方法 | 端點 (Endpoint) |
|--------|--------|----------|
| 列出工作流 (Workflows) | GET | `/repos/{owner}/{repo}/actions/workflows` |
| 列出執行紀錄 (Runs) | GET | `/repos/{owner}/{repo}/actions/runs?per_page=10` |
| 列出執行紀錄 (依分支) | GET | `/repos/{owner}/{repo}/actions/runs?branch={branch}` |
| 取得執行紀錄 | GET | `/repos/{owner}/{repo}/actions/runs/{run_id}` |
| 下載日誌 | GET | `/repos/{owner}/{repo}/actions/runs/{run_id}/logs` |
| 重新執行 | POST | `/repos/{owner}/{repo}/actions/runs/{run_id}/rerun` |
| 重新執行失敗項目 | POST | `/repos/{owner}/{repo}/actions/runs/{run_id}/rerun-failed-jobs` |
| 觸發手動派遣 (Dispatch) | POST | `/repos/{owner}/{repo}/actions/workflows/{id}/dispatches` |
| Commit 狀態 | GET | `/repos/{owner}/{repo}/commits/{sha}/status` |
| Check runs | GET | `/repos/{owner}/{repo}/commits/{sha}/check-runs` |

## 發佈 (Releases)

| 動作 | 方法 | 端點 (Endpoint) |
|--------|--------|----------|
| 列出發佈 | GET | `/repos/{owner}/{repo}/releases` |
| 建立發佈 | POST | `/repos/{owner}/{repo}/releases` |
| 取得發佈 | GET | `/repos/{owner}/{repo}/releases/{id}` |
| 刪除發佈 | DELETE | `/repos/{owner}/{repo}/releases/{id}` |
| 上傳資產 | POST | `https://uploads.github.com/repos/{owner}/{repo}/releases/{id}/assets?name={filename}` |

## 秘密資訊 (Secrets)

| 動作 | 方法 | 端點 (Endpoint) |
|--------|--------|----------|
| 列出秘密資訊 | GET | `/repos/{owner}/{repo}/actions/secrets` |
| 取得公鑰 | GET | `/repos/{owner}/{repo}/actions/secrets/public-key` |
| 設定秘密資訊 | PUT | `/repos/{owner}/{repo}/actions/secrets/{name}` |
| 刪除秘密資訊 | DELETE | `/repos/{owner}/{repo}/actions/secrets/{name}` |

## 分支保護 (Branch Protection)

| 動作 | 方法 | 端點 (Endpoint) |
|--------|--------|----------|
| 取得保護設定 | GET | `/repos/{owner}/{repo}/branches/{branch}/protection` |
| 設定保護 | PUT | `/repos/{owner}/{repo}/branches/{branch}/protection` |
| 刪除保護 | DELETE | `/repos/{owner}/{repo}/branches/{branch}/protection` |

## 使用者 / 認證 (User / Auth)

| 動作 | 方法 | 端點 (Endpoint) |
|--------|--------|----------|
| 取得目前使用者 | GET | `/user` |
| 列出使用者儲存庫 | GET | `/user/repos` |
| 列出使用者 gists | GET | `/gists` |
| 建立 gist | POST | `/gists` |
| 搜尋儲存庫 | GET | `/search/repositories?q={query}` |

## 分頁 (Pagination)

多數列表端點皆支援：
- `?per_page=100` (最高 100)
- `?page=2` 前往下一頁
- 檢查 `Link` 標頭中的 `rel="next"` URL

## 速率限制 (Rate Limits)

- 已驗證：每小時 5,000 次請求
- 檢查剩餘次數：`curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/rate_limit`

## 常見 curl 模式

```bash
# GET (取得)
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO

# POST (建立)，帶有 JSON 主體
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/issues \
  -d '{"title": "...", "body": "..."}'

# PATCH (更新)
curl -s -X PATCH \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/issues/42 \
  -d '{"state": "closed"}'

# DELETE (刪除)
curl -s -X DELETE \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/issues/42/labels/bug

# 使用 python3 解析 JSON 回應
curl -s ... | python3 -c "import sys,json; data=json.load(sys.stdin); print(data['field'])"
```
