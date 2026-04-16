# 已刪除內容復原技術

## 核心見解：GitHub 從未完全刪除強制推送的提交

強制推送 (Force-pushed) 的提交會從分支歷史紀錄中移除，但會保留在 GitHub 的伺服器上，直到執行垃圾回收 (Garbage Collection，可能需要數週到數月)。這是復原已刪除提交的基礎。

---

## 方法 1：直接透過 GitHub URL (最快 — 無須驗證)

如果您有提交雜湊 (SHA)，即使它已被強制推送移出分支，仍可直接存取：

```bash
# 檢視提交元數據
curl -s "https://github.com/OWNER/REPO/commit/SHA"

# 下載為補丁檔案 (包含完整差異)
curl -s "https://github.com/OWNER/REPO/commit/SHA.patch" > recovered_commit.patch

# 下載為差異檔案 (diff)
curl -s "https://github.com/OWNER/REPO/commit/SHA.diff" > recovered_commit.diff

# 範例 (Istio 憑證洩漏 - 真實事件)：
curl -s "https://github.com/istio/istio/commit/FORCE_PUSHED_SHA.patch"
```

**適用情況**：已知 SHA (來自 GH Archive、Wayback Machine 或 `git fsck`)
**失敗情況**：GitHub 已對該物件執行垃圾回收 (少見，通常在強制推送後 30–90 天)

---

## 方法 2：GitHub REST API

```bash
# 適用於已從分支強制推送移出，但仍留在伺服器上的提交
# 註：/commits/SHA 可能會回傳 404，但 /git/commits/SHA 對孤立提交通常能成功
curl -s "https://api.github.com/repos/OWNER/REPO/git/commits/SHA" | jq .

# 取得強制推送提交的樹狀結構 (檔案列表)
curl -s "https://api.github.com/repos/OWNER/REPO/git/trees/SHA?recursive=1" | jq .

# 從強制推送提交中取得特定檔案
curl -s "https://api.github.com/repos/OWNER/REPO/contents/PATH?ref=SHA" | jq .content | base64 -d
```

---

## 方法 3：透過 SHA 進行 Git Fetch (本地 — 需複製儲存庫)

```bash
# 直接將孤立提交透過 SHA 抓取到本地儲存庫
cd target_repo
git fetch origin SHA
git log FETCH_HEAD -1   # 檢視該提交
git diff FETCH_HEAD~1 FETCH_HEAD  # 檢視差異

# 如果該 SHA 是最近才被強制推送的，通常仍可抓取
# 一旦 GitHub 執行垃圾回收，此方法即失效
```

---

## 方法 4：透過 git fsck 尋找懸空提交 (Dangling Commits)

```bash
cd target_repo

# 尋找所有無法觸及的物件 (包含強制推送的提交)
git fsck --unreachable --no-reflogs 2>&1 | grep "unreachable commit" | awk '{print $3}' > dangling_shas.txt

# 為每個懸空提交取得元數據
while read sha; do
  echo "=== $sha ===" >> dangling_details.txt
  git show --stat "$sha" >> dangling_details.txt 2>&1
done < dangling_shas.txt

# 註：懸空物件僅存在於本地克隆中 — 與 GitHub 上的副本不同
# GitHub 上的副本在垃圾回收前可透過方法 1-3 存取
```

---

## 復原已刪除的 GitHub Issue 和 PR

### 透過 Wayback Machine CDX API

```bash
# 尋找特定 Issue 的所有已封存快照
curl -s "https://web.archive.org/cdx/search/cdx?url=github.com/OWNER/REPO/issues/NUMBER&output=json&limit=50&fl=timestamp,statuscode,original" | python3 -m json.tool

# 獲取最佳快照
# 使用來自 CDX 結果的時間戳記 (TIMESTAMP)：
# https://web.archive.org/web/TIMESTAMP/https://github.com/OWNER/REPO/issues/NUMBER
curl -s "https://web.archive.org/web/TIMESTAMP/https://github.com/OWNER/REPO/issues/NUMBER" > issue_NUMBER_archived.html

# 在特定日期範圍內尋找儲存庫的所有快照
curl -s "https://web.archive.org/cdx/search/cdx?url=github.com/OWNER/REPO*&output=json&from=20240101&to=20240201&limit=200&fl=timestamp,urlkey,statuscode" | python3 -m json.tool
```

### 透過 GitHub API (有限 — 僅限未刪除內容)

```bash
# 已關閉 (但未刪除) 的 Issue 是可以檢索的
curl -s "https://api.github.com/repos/OWNER/REPO/issues?state=closed&per_page=100" | jq '.[].number'

# 註：已刪除的 Issue/PR 不會出現在 API 中。請使用 Wayback Machine 或 GH Archive。
```

### 透過 GitHub Archive (用於事件歷史 — 而非內容)

```sql
-- 在日期範圍內尋找儲存庫的所有 IssueEvents
SELECT created_at, actor.login, payload.action, payload.issue.number, payload.issue.title
FROM `githubarchive.day.*`
WHERE _TABLE_SUFFIX BETWEEN '20240101' AND '20240201'
  AND type = 'IssuesEvent'
  AND repo.name = 'OWNER/REPO'
ORDER BY created_at
```

---

## 從已知提交中復原已刪除的檔案

```bash
# 如果您有提交雜湊 (即使是強制推送的)：
git show SHA:path/to/file.py > recovered_file.py

# 或透過 API (Base64 編碼內容)：
curl -s "https://api.github.com/repos/OWNER/REPO/contents/path/to/file.py?ref=SHA" | python3 -c "
import sys, json, base64
d = json.load(sys.stdin)
print(base64.b64decode(d['content']).decode())
"
```

---

## 證據記錄

復原任何已刪除內容後，請立即記錄：

```bash
python3 SKILL_DIR/scripts/evidence-store.py --store evidence.json add \
  --source "git fetch origin FORCE_PUSHED_SHA" \
  --content "Recovered commit: FORCE_PUSHED_SHA | Author: attacker@example.com | Date: 2024-01-15 | Added file: malicious.sh" \
  --type git \
  --actor "attacker-handle" \
  --url "https://github.com/OWNER/REPO/commit/FORCE_PUSHED_SHA.patch" \
  --timestamp "2024-01-15T00:00:00Z" \
  --verification single_source \
  --notes "提交於 2024-01-16 從主分支強制推送。透過直接抓取 (direct fetch) 復原。"
```

---

## 復原失敗模式

| 失敗情況 | 原因 | 緩解方法 |
|---------|-------|------------|
| `git fetch origin SHA` 回傳 "not our ref" | GitHub 已執行垃圾回收 | 嘗試方法 1/2，搜尋 Wayback Machine |
| `github.com/OWNER/REPO/commit/SHA` 回傳 404 | 已執行垃圾回收或 SHA 錯誤 | 透過 GH Archive 驗證 SHA；嘗試部分 SHA 搜尋 |
| Wayback Machine 無快照 | 頁面從未被 IA 爬取 | 檢查 `commoncrawl.org` 或 Google 快取 |
| BigQuery 顯示事件但無內容 | GH Archive 僅儲存事件元數據，而非檔案內容 | 復原僅能揭示事件發生，而非具體內容 |
