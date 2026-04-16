# 證據類型參考指南

開源軟體 (OSS) 鑑識調查中使用的所有證據類型、入侵指標 (IOC) 類型、GitHub 事件類型和觀察類型的分類。

---

## 證據來源類型

| 類型 | 描述 | 範例來源 |
|------|-------------|-----------------|
| `git` | 來自本地 git 儲存庫分析的資料 | `git log`, `git fsck`, `git reflog`, `git blame` |
| `gh_api` | 來自 GitHub REST API 回應的資料 | `/repos/.../commits`, `/repos/.../pulls`, `/repos/.../events` |
| `gh_archive` | 來自 GitHub Archive (BigQuery) 的資料 | `githubarchive.month.*` BigQuery 表格 |
| `web_archive` | 來自 Wayback Machine 的已封存網頁 | CDX API 結果, `web.archive.org/web/...` 快照 |
| `ioc` | 來自任何來源的入侵指標 | 從供應商報告、git 歷史紀錄、網路追蹤中提取 |
| `analysis` | 來自跨來源關聯分析的衍生見解 | 「SHA 存在於封存中但不存在於 API 中」 |
| `vendor_report` | 外部安全性供應商或研究人員報告 | CVE 公告、部落格文章、NVD 紀錄 |
| `manual` | 調查人員手動記錄的觀察結果 | 關於行為模式、時間軸缺口的筆記 |

---

## IOC 類型

| 類型 | 描述 | 範例 |
|------|-------------|---------|
| `COMMIT_SHA` | 與惡意活動相關的 git 提交雜湊 | `abc123def456...` |
| `FILE_PATH` | 儲存庫內的可疑檔案 | `src/utils/crypto.js`, `dist/index.min.js` |
| `API_KEY` | 意外提交的 API 金鑰 | `AKIA...` (AWS), `ghp_...` (GitHub PAT) |
| `SECRET` | 通用的機密資訊 / 憑證 | 資料庫密碼、私鑰區塊 |
| `IP_ADDRESS` | C2 伺服器或攻擊者 IP | `192.0.2.1` |
| `DOMAIN` | 惡意或可疑網域 | `evil-cdn.io`, 拼寫錯誤劫持的套件註冊表網域 |
| `PACKAGE_NAME` | 惡意或拼寫錯誤劫持的套件名稱 | `colo-rs` (劫持 `color`), `lodash-utils` |
| `ACTOR_USERNAME` | 與攻擊相關的 GitHub 帳號 | `malicious-bot-account` |
| `MALICIOUS_URL` | 指向惡意資源的 URL | `https://evil.example.com/payload.sh` |
| `WORKFLOW_FILE` | 可疑的 CI/CD 工作流檔案 | `.github/workflows/release.yml` |
| `BRANCH_NAME` | 可疑的分支 | `refs/heads/temp-fix-do-not-merge` |
| `TAG_NAME` | 可疑的 git 標籤 | `v1.0.0-security-patch` |
| `RELEASE_NAME` | 可疑的發布版本 | 無關聯標籤或變更日誌的發布 |
| `OTHER` | 未分類 IOC 的總稱 | — |

---

## GitHub Archive 事件類型 (12 類)

| 事件類型 | 鑑識相關性 |
|------------|-------------------|
| `PushEvent` | 核心：`payload.distinct_size=0` 且 `payload.size>0` → 強制推送。`payload.before`/`payload.head` 顯示歷史紀錄被重寫。 |
| `PullRequestEvent` | 偵測已刪除的 PR、快速開啟後關閉的模式、來自新帳號的 PR |
| `IssueEvent` | 偵測已刪除的 Issue、協調好的標籤標註、漏洞報告被快速關閉 |
| `IssueCommentEvent` | 已刪除的評論、活動突發爆增 |
| `WatchEvent` | 刷星 (Star-farming) 活動 (來自新帳號的協調點讚) |
| `ForkEvent` | 惡意提交前不尋常的分叉 (Fork) 模式 |
| `CreateEvent` | 分支/標籤建立：預示新的發布或代碼注入點 |
| `DeleteEvent` | 分支/標籤刪除：關鍵 — 常被用來隱藏蹤跡 |
| `ReleaseEvent` | 未經授權的發布、發布成品在發布後被修改 |
| `MemberEvent` | 協作者新增/移除：維護者帳號遭入侵的指標 |
| `PublicEvent` | 儲存庫設為公開 (有時是為了短暫放入惡意代碼) |
| `WorkflowRunEvent` | CI/CD 管線執行：工作流注入、機密外洩 |

---

## 證據驗證狀態

| 狀態 | 意義 |
|-------|---------|
| `unverified` | 從單一來源收集，未經交叉比對 |
| `single_source` | 主要來源已直接確認 (例如 SHA 在 GitHub 上可解析)，但無第二來源 |
| `multi_source_verified` | 已從 2 個以上獨立來源確認 (例如 GH Archive 和 GitHub API 均顯示相同事件) |

僅有標記為 `multi_source_verified` 的證據可在已驗證假說中引用為事實。
`unverified` 和 `single_source` 證據必須標註為 `[UNVERIFIED]` 或 `[SINGLE-SOURCE]`。

---

## 觀察類型 (參考 RAPTOR 模式)

| 類型 | 描述 |
|------|-------------|
| `CommitObservation` | 帶有元數據的特定提交 SHA (作者、日期、變更檔案) |
| `ForceWashObservation` | 提交從分支中被強制抹除的證據 |
| `DanglingCommitObservation` | 雜湊值存在於 git 物件庫中，但無法從任何引用 (Ref) 觸及 |
| `IssueObservation` | 帶有標題、內文、時間戳記的 GitHub Issue (目前或已封存) |
| `PRObservation` | 帶有差異摘要、審查者的 GitHub PR (目前或已封存) |
| `IOC` | 單一入侵指標及其上下文 |
| `TimelineGap` | 預期活動異常缺失的期間 |
| `ActorAnomalyObservation` | 特定 GitHub 行動者的行為異常 |
| `WorkflowAnomalyObservation` | 可疑的 CI/CD 工作流變更或非預期執行 |
| `CrossSourceDiscrepancy` | 項目存在於某一來源但在另一來源缺失 (強烈的刪除指標) |
