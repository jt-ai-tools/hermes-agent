# GitHub Archive 查詢指南 (BigQuery)

GitHub Archive 將 GitHub 上的每個公開事件記錄為不可變的 JSON 記錄。這些數據可透過 Google BigQuery 存取，是鑑識調查最可靠的來源 —— 事件在記錄後無法被刪除或修改。

## 公用資料集

- **專案**：`githubarchive`
- **資料表**：`day.YYYYMMDD`, `month.YYYYMM`, `year.YYYY`
- **成本**：每掃描 1 TiB 為 $6.25 美元。請務必先進行預估執行（dry run）。
- **存取**：需要啟用了 BigQuery 的 Google Cloud 帳戶。免費方案每月包含 1 TiB 的查詢額度。

---

## 12 種 GitHub 事件類型

| 事件類型 | 記錄內容 | 鑑識價值 |
|------------|-----------------|----------------|
| `PushEvent` | 推送到分支的提交 | 強制推送偵測、提交時間軸、作者歸屬 |
| `PullRequestEvent` | PR 開啟、關閉、合併、重新開啟 | 已刪除 PR 的恢復、審閱時間軸 |
| `IssuesEvent` | Issue 開啟、關閉、重新開啟、標記 | 已刪除 Issue 的恢復、社交工程痕跡 |
| `IssueCommentEvent` | Issue 和 PR 上的評論 | 已刪除評論的恢復、溝通模式 |
| `CreateEvent` | 分支、標籤或儲存庫建立 | 可疑分支建立、標籤時間 |
| `DeleteEvent` | 分支或標籤刪除 | 入侵後清理證據 |
| `MemberEvent` | 協作者新增或移除 | 權限變更、權限提升 |
| `PublicEvent` | 儲存庫設為公開 | 私有儲存庫的意外暴露 |
| `WatchEvent` | 用戶收藏儲存庫 | 執行者偵察模式 |
| `ForkEvent` | 儲存庫被 fork | 清理前的程式碼外洩 |
| `ReleaseEvent` | 發行版本發布、編輯、刪除 | 惡意發行版本注入、已刪除發行版本恢復 |
| `WorkflowRunEvent` | GitHub Actions 工作流觸發 | CI/CD 濫用、未經授權的工作流執行 |

---

## 查詢範本

### 基礎：儲存庫的所有事件

```sql
SELECT
  created_at,
  type,
  actor.login,
  repo.name,
  payload
FROM
  `githubarchive.day.20240101`  -- 調整日期
WHERE
  repo.name = 'owner/repo'
  AND type IN ('PushEvent', 'DeleteEvent', 'MemberEvent')
ORDER BY
  created_at ASC
```

### 強制推送偵測

強制推送會產生提交被覆寫的 PushEvents。關鍵指標：
- `payload.distinct_size = 0` 且 `payload.size > 0` → 提交被抹除
- `payload.before` 包含重寫前的 SHA（可恢復）

```sql
SELECT
  created_at,
  actor.login,
  JSON_EXTRACT_SCALAR(payload, '$.before') AS before_sha,
  JSON_EXTRACT_SCALAR(payload, '$.head') AS after_sha,
  JSON_EXTRACT_SCALAR(payload, '$.size') AS total_commits,
  JSON_EXTRACT_SCALAR(payload, '$.distinct_size') AS distinct_commits,
  JSON_EXTRACT_SCALAR(payload, '$.ref') AS branch_ref
FROM
  `githubarchive.month.*`
WHERE
  _TABLE_SUFFIX BETWEEN '202401' AND '202403'
  AND type = 'PushEvent'
  AND repo.name = 'owner/repo'
  AND CAST(JSON_EXTRACT_SCALAR(payload, '$.distinct_size') AS INT64) = 0
ORDER BY
  created_at ASC
```

### 已刪除分支/標籤偵測

```sql
SELECT
  created_at,
  actor.login,
  JSON_EXTRACT_SCALAR(payload, '$.ref') AS deleted_ref,
  JSON_EXTRACT_SCALAR(payload, '$.ref_type') AS ref_type
FROM
  `githubarchive.month.*`
WHERE
  _TABLE_SUFFIX BETWEEN '202401' AND '202403'
  AND type = 'DeleteEvent'
  AND repo.name = 'owner/repo'
ORDER BY
  created_at ASC
```

### 協作者權限變更

```sql
SELECT
  created_at,
  actor.login,
  JSON_EXTRACT_SCALAR(payload, '$.action') AS action,
  JSON_EXTRACT_SCALAR(payload, '$.member.login') AS member
FROM
  `githubarchive.month.*`
WHERE
  _TABLE_SUFFIX BETWEEN '202401' AND '202403'
  AND type = 'MemberEvent'
  AND repo.name = 'owner/repo'
ORDER BY
  created_at ASC
```

### CI/CD 工作流活動

```sql
SELECT
  created_at,
  actor.login,
  JSON_EXTRACT_SCALAR(payload, '$.action') AS action,
  JSON_EXTRACT_SCALAR(payload, '$.workflow_run.name') AS workflow_name,
  JSON_EXTRACT_SCALAR(payload, '$.workflow_run.conclusion') AS conclusion,
  JSON_EXTRACT_SCALAR(payload, '$.workflow_run.head_sha') AS head_sha
FROM
  `githubarchive.month.*`
WHERE
  _TABLE_SUFFIX BETWEEN '202401' AND '202403'
  AND type = 'WorkflowRunEvent'
  AND repo.name = 'owner/repo'
ORDER BY
  created_at ASC
```

### 執行者活動分析

```sql
SELECT
  type,
  COUNT(*) AS event_count,
  MIN(created_at) AS first_event,
  MAX(created_at) AS last_event
FROM
  `githubarchive.month.*`
WHERE
  _TABLE_SUFFIX BETWEEN '202301' AND '202412'
  AND actor.login = 'suspicious-username'
GROUP BY type
ORDER BY event_count DESC
```

---

## 成本優化（強制要求）

1. **務必先進行預估執行**：在 `bq query` 中加入 `--dry_run` 旗標，以在執行前查看預估掃描的位元組數。
2. **使用 `_TABLE_SUFFIX`**：盡可能縮小日期範圍。`day.*` 資料表最適合窄時間窗口；`month.*` 則適合較廣泛的掃描。
3. **僅選取需要的欄位**：避免使用 `SELECT *`。`payload` 欄位很大 —— 請僅選取特定的 JSON 路徑。
4. **加入 LIMIT**：在探索期間使用 `LIMIT 1000`。僅在最終完整查詢時移除。
5. **在 WHERE 中進行欄位過濾**：在提取 payload 之前，先過濾索引欄位（`type`, `repo.name`, `actor.login`）。

**成本估算**：單個月份的 GH Archive 數據未壓縮約為 1-2 TiB。使用 `_TABLE_SUFFIX` 查詢特定儲存庫 + 事件類型通常會掃描 1-10 GiB（約 $0.006-$0.06 美元）。

---

## 透過 Hermes 存取

**選項 A：BigQuery CLI**（若已安裝 `gcloud`）
```bash
bq query --use_legacy_sql=false --format=json "YOUR QUERY"
```

**選項 B：Python**（透過 `execute_code`）
```python
from google.cloud import bigquery
client = bigquery.Client()
query = "YOUR QUERY"
results = client.query(query).result()
for row in results:
    print(dict(row))
```

**選項 C：無 GCP 憑證可用**
若無法使用 BigQuery，請在報告中註明此限制。請使用其他 4 種調查工具（Git、GitHub API、Wayback Machine、IOC 豐富化）—— 它們涵蓋了大多數不需要 BigQuery 的調查需求。
