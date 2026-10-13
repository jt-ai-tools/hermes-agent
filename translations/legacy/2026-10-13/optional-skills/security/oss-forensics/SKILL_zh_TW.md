---
name: oss-forensics
description: |
  針對 GitHub 儲存庫進行供應鏈調查、證據恢復和數位鑑識分析。
  內容涵蓋已刪除提交 (commit) 的恢復、強制推送 (force-push) 偵測、威脅指標 (IOC) 擷取、多來源證據收集、假說形成與驗證，以及結構化數位鑑識報告。
  啟發自 RAPTOR 超過 1800 行的開源軟體 (OSS) 數位鑑識系統。
category: security
triggers:
  - "調查此儲存庫"
  - "調查 [擁有者/儲存庫]"
  - "檢查供應鏈入侵"
  - "恢復已刪除的提交"
  - "數位鑑識分析 [擁有者/儲存庫]"
  - "此儲存庫是否被入侵"
  - "供應鏈攻擊"
  - "可疑提交"
  - "偵測到強制推送"
  - "IOC 擷取"
toolsets:
  - terminal
  - web
  - file
  - delegation
---

# 開源軟體 (OSS) 安全數位鑑識技能

一個用於研究開源軟體供應鏈攻擊的 7 階段多代理人 (multi-agent) 調查框架。
改編自 RAPTOR 的數位鑑識系統。涵蓋 GitHub Archive、Wayback Machine、GitHub API、本地 git 分析、IOC 擷取、基於證據的假說形成與驗證，以及最終數位鑑識報告的生成。

---

## ⚠️ 反幻覺護欄 (Anti-Hallucination Guardrails)

在每個調查步驟之前請閱讀這些規則。違反規則將導致報告失效。

1. **證據優先原則 (Evidence-First Rule)**：報告、假說或摘要中的每一項主張都必須引用至少一個證據 ID (`EV-XXXX`)。禁止提供沒有引用的陳述。
2. **各司其職 (STAY IN YOUR LANE)**：每個子代理人 (調查員) 只有單一資料來源。切勿混合來源。GH Archive 調查員不查詢 GitHub API，反之亦然。角色邊界是強制性的。
3. **事實與假說分離**：將所有未經證實的推論標記為 `[HYPOTHESIS]` (假說)。只有與原始來源驗證過後的陳述才能稱為事實。
4. **禁止偽造證據**：假說驗證員必須在接受假說之前，機械式地檢查所有引用的證據 ID 是否確切存在於證據庫中。
5. **反證需有理**：如果沒有具體、有證據支持的反對論點，則不能駁回假說。「未發現證據」不足以駁回假說 — 這只能使假說處於「不確定」狀態。
6. **SHA/URL 二重驗證**：任何作為證據引用的提交 SHA、URL 或外部識別碼，在標記為已驗證之前，必須獨立地從至少兩個來源獲得確認。
7. **可疑程式碼規則**：切勿在本地執行調查儲存庫中發現的程式碼。僅進行靜態分析，或在沙盒環境中使用 `execute_code`。
8. **機密遮蔽**：在調查過程中發現的任何 API 金鑰、權杖 (token) 或憑證都必須在最終報告中進行遮蔽。僅在內部記錄它們。

---

## 範例場景

- **場景 A：相依性混淆 (Dependency Confusion)**：一個惡意套件 `internal-lib-v2` 被上傳到 NPM，其版本號高於內部版本。調查員必須追蹤該套件首次出現的時間，以及目標儲存庫中的任何 PushEvent 是否將 `package.json` 更新至此版本。
- **場景 B：維護者帳號接管**：長期貢獻者的帳號被用來推送帶有後門的 `.github/workflows/build.yml`。調查員尋找該使用者在長期不活躍之後的 PushEvent，或是來自新 IP/位置的推送 (如果可以透過 BigQuery 偵測)。
- **場景 C：強制推送隱藏 (Force-Push Hide)**：開發者意外提交了生產環境的機密，然後進行強制推送來「修復」它。調查員使用 `git fsck` 和 GH Archive 來恢復原始的提交 SHA 並驗證洩漏的內容。

---

> **路徑慣例**：在本技能中，`SKILL_DIR` 指的是此技能安裝目錄的根目錄 (包含此 `SKILL.md` 的資料夾)。當技能載入時，將 `SKILL_DIR` 解析為實際路徑 — 例如 `~/.hermes/skills/security/oss-forensics/` 或 `optional-skills/` 的等效路徑。所有指令稿 (script) 和範本引用都是相對於它的。

## 第 0 階段：初始化

1. 建立調查工作目錄：
   ```bash
   mkdir investigation_$(echo "REPO_NAME" | tr '/' '_')
   cd investigation_$(echo "REPO_NAME" | tr '/' '_')
   ```
2. 初始化證據庫：
   ```bash
   python3 SKILL_DIR/scripts/evidence-store.py --store evidence.json list
   ```
3. 複製數位鑑識報告範本：
   ```bash
   cp SKILL_DIR/templates/forensic-report.md ./investigation-report.md
   ```
4. 建立 `iocs.md` 檔案，以便追蹤發現的威脅指標 (IOC)。
5. 記錄調查開始時間、目標儲存庫和設定的調查目標。

---

## 第 1 階段：提示詞解析與 IOC 擷取

**目標**：從使用者的請求中擷取所有結構化的調查目標。

**行動**：
- 解析使用者提示詞並擷取：
  - 目標儲存庫 (`owner/repo`)
  - 目標行為者 (GitHub 帳號、電子郵件地址)
  - 關注的時間範圍 (提交日期範圍、PR 時間戳記)
  - 提供的威脅指標：提交 SHA、檔案路徑、套件名稱、IP 地址、網域、API 金鑰/權杖、惡意 URL
  - 任何連結的廠商安全報告或部落格文章

**工具**：僅使用推理，或對大型文字塊使用 `execute_code` 進行正規表達式 (regex) 擷取。

**輸出**：在 `iocs.md` 中填入擷取的 IOC。每個 IOC 必須包含：
- 類型 (包含：COMMIT_SHA, FILE_PATH, API_KEY, SECRET, IP_ADDRESS, DOMAIN, PACKAGE_NAME, ACTOR_USERNAME, MALICIOUS_URL, OTHER)
- 數值
- 來源 (使用者提供、推論)

**參考**：參閱 [evidence-types.md](./references/evidence-types.md) 以瞭解 IOC 分類。

---

## 第 2 階段：平行證據收集

使用 `delegate_task` (批次模式，最多 3 個同時執行) 產生最多 5 個專家調查員子代理人。每個調查員只有 **單一資料來源**，且不得混合來源。

> **協調員筆記**：將第 1 階段的 IOC 清單和調查時間範圍傳遞給每個委派任務的 `context` 欄位。

---

### 調查員 1：本地 Git 調查員

**角色邊界**：僅查詢本地 GIT 儲存庫。不要呼叫任何外部 API。

**行動**：
```bash
# 複製儲存庫
git clone https://github.com/OWNER/REPO.git target_repo && cd target_repo

# 完整的提交日誌及統計資料
git log --all --full-history --stat --format="%H|%ae|%an|%ai|%s" > ../git_log.txt

# 偵測強制推送證據 (孤立/懸空提交)
git fsck --lost-found --unreachable 2>&1 | grep commit > ../dangling_commits.txt

# 檢查 reflog 是否有重寫歷史的紀錄
git reflog --all > ../reflog.txt

# 列出所有分支，包含已刪除的遠端引用
git branch -a -v > ../branches.txt

# 尋找可疑的大型二進位檔案新增
git log --all --diff-filter=A --name-only --format="%H %ai" -- "*.so" "*.dll" "*.exe" "*.bin" > ../binary_additions.txt

# 檢查 GPG 簽署異常
git log --show-signature --format="%H %ai %aN" > ../signature_check.txt 2>&1
```

**要收集的證據** (透過 `python3 SKILL_DIR/scripts/evidence-store.py add` 加入)：
- 每個懸空提交的 SHA → 類型：`git`
- 強制推送證據 (顯示歷史重寫的 reflog) → 類型：`git`
- 來自已驗證貢獻者的未簽署提交 → 類型：`git`
- 可疑的二進位檔案新增 → 類型：`git`

**參考**：參閱 [recovery-techniques.md](./references/recovery-techniques.md) 以瞭解如何存取經強制推送的提交。

---

### 調查員 2：GitHub API 調查員

**角色邊界**：僅查詢 GITHUB REST API。不要在本地執行 git 命令。

**行動**：
```bash
# 提交 (分頁)
curl -s "https://api.github.com/repos/OWNER/REPO/commits?per_page=100" > api_commits.json

# 拉取請求 (PR)，包含已關閉/已刪除的
curl -s "https://api.github.com/repos/OWNER/REPO/pulls?state=all&per_page=100" > api_prs.json

# 議題 (Issues)
curl -s "https://api.github.com/repos/OWNER/REPO/issues?state=all&per_page=100" > api_issues.json

# 貢獻者與協作者變更
curl -s "https://api.github.com/repos/OWNER/REPO/contributors" > api_contributors.json

# 儲存庫事件 (最後 300 個)
curl -s "https://api.github.com/repos/OWNER/REPO/events?per_page=100" > api_events.json

# 檢查特定可疑提交 SHA 的細節
curl -s "https://api.github.com/repos/OWNER/REPO/git/commits/SHA" > commit_detail.json

# 發布 (Releases)
curl -s "https://api.github.com/repos/OWNER/REPO/releases?per_page=100" > api_releases.json

# 檢查特定提交是否存在 (強制推送的提交可能在 commits/ 處返回 404，但在 git/commits/ 處成功)
curl -s "https://api.github.com/repos/OWNER/REPO/commits/SHA" | jq .sha
```

**交叉引用目標** (將差異標記為證據)：
- PR 存在於封存中但在 API 中缺失 → 刪除證據
- 貢獻者存在於封存事件中但在貢獻者清單中缺失 → 權限撤銷證據
- 提交存在於封存 PushEvents 中但在 API 提交清單中缺失 → 強制推送/刪除證據

**參考**：參閱 [evidence-types.md](./references/evidence-types.md) 以瞭解 GH 事件類型。

---

### 調查員 3：Wayback Machine 調查員

**角色邊界**：僅查詢 WAYBACK MACHINE CDX API。不要使用 GitHub API。

**目標**：恢復已刪除的 GitHub 頁面 (README、議題、PR、發布、wiki 頁面)。

**行動**：
```bash
# 搜尋儲存庫主頁的封存快照
curl -s "https://web.archive.org/cdx/search/cdx?url=github.com/OWNER/REPO&output=json&limit=100&from=YYYYMMDD&to=YYYYMMDD" > wayback_main.json

# 搜尋特定已刪除的議題
curl -s "https://web.archive.org/cdx/search/cdx?url=github.com/OWNER/REPO/issues/NUM&output=json&limit=50" > wayback_issue_NUM.json

# 搜尋特定已刪除的 PR
curl -s "https://web.archive.org/cdx/search/cdx?url=github.com/OWNER/REPO/pull/NUM&output=json&limit=50" > wayback_pr_NUM.json

# 擷取頁面的最佳快照
# 使用 Wayback Machine URL: https://web.archive.org/web/TIMESTAMP/ORIGINAL_URL
# 範例: https://web.archive.org/web/20240101000000*/github.com/OWNER/REPO

# 進階：搜尋已刪除的發布/標籤 (tags)
curl -s "https://web.archive.org/cdx/search/cdx?url=github.com/OWNER/REPO/releases/tag/*&output=json" > wayback_tags.json

# 進階：搜尋歷史 wiki 變更
curl -s "https://web.archive.org/cdx/search/cdx?url=github.com/OWNER/REPO/wiki/*&output=json" > wayback_wiki.json
```

**要收集的證據**：
- 包含內容的已刪除議題/PR 的封存快照
- 顯示變更的歷史 README 版本
- 封存中存在但當前 GitHub 狀態中缺失的內容證據

**參考**：參閱 [github-archive-guide.md](./references/github-archive-guide.md) 以瞭解 CDX API 參數。

---

### 調查員 4：GH Archive / BigQuery 調查員

**角色邊界**：僅透過 BIGQUERY 查詢 GITHUB ARCHIVE。這是所有公開 GitHub 事件的不可篡改紀錄。

> **先決條件**：需要具備 BigQuery 存取權限的 Google Cloud 憑證 (`gcloud auth application-default login`)。如果無法使用，請跳過此調查員並在報告中註明。

**成本最佳化規則** (強制執行)：
1. 每次查詢前務必執行 `--dry_run` 以預估成本。
2. 使用 `_TABLE_SUFFIX` 依日期範圍過濾並減少掃描資料量。
3. 僅 SELECT 你需要的欄位。
4. 除非是聚合查詢，否則請加入 LIMIT。

```bash
# 範例：針對 OWNER/REPO 的 PushEvents 進行安全的 BigQuery 查詢
bq query --use_legacy_sql=false --dry_run "
SELECT created_at, actor.login, payload.commits, payload.before, payload.head,
       payload.size, payload.distinct_size
FROM \`githubarchive.month.*\`
WHERE _TABLE_SUFFIX BETWEEN 'YYYYMM' AND 'YYYYMM'
  AND type = 'PushEvent'
  AND repo.name = 'OWNER/REPO'
LIMIT 1000
"
# 如果成本可接受，請移除 --dry_run 重新執行

# 偵測強制推送：distinct_size 為零的 PushEvent 代表提交被強制抹除
# payload.distinct_size = 0 AND payload.size > 0 → 強制推送指標

# 檢查已刪除的分支事件
bq query --use_legacy_sql=false "
SELECT created_at, actor.login, payload.ref, payload.ref_type
FROM \`githubarchive.month.*\`
WHERE _TABLE_SUFFIX BETWEEN 'YYYYMM' AND 'YYYYMM'
  AND type = 'DeleteEvent'
  AND repo.name = 'OWNER/REPO'
LIMIT 200
"
```

**要收集的證據**：
- 強制推送事件 (payload.size > 0, payload.distinct_size = 0)
- 分支/標籤的 DeleteEvent
- 針對可疑 CI/CD 自動化的 WorkflowRunEvent
- git 日誌中出現「缺口」之前的 PushEvent (重寫證據)

**參考**：參閱 [github-archive-guide.md](./references/github-archive-guide.md) 以瞭解所有 12 種事件類型與查詢模式。

---

### 調查員 5：IOC 擴展調查員

**角色邊界**：僅使用被動公開來源來擴展第 1 階段中現有的 IOC。不要執行目標儲存庫中的任何程式碼。

**行動**：
- 針對每個提交 SHA：嘗試透過直接 GitHub URL 恢復 (`github.com/OWNER/REPO/commit/SHA.patch`)
- 針對每個網域/IP：檢查被動 DNS、WHOIS 紀錄 (透過針對公開 WHOIS 服務使用 `web_extract`)
- 針對每個套件名稱：檢查 npm/PyPI 是否有匹配的惡意套件報告
- 針對每個行為者帳號：檢查 GitHub 個人資料、貢獻歷史、帳號建立時間
- 使用 3 種方法恢復強制推送的提交 (參閱 [recovery-techniques.md](./references/recovery-techniques.md))

---

## 第 3 階段：證據整合

所有調查員完成後：

1. 執行 `python3 SKILL_DIR/scripts/evidence-store.py --store evidence.json list` 以查看所有收集的證據。
2. 針對每一項證據，驗證 `content_sha256` 雜湊值是否與原始來源匹配。
3. 依據以下方式對證據進行分組：
   - **時間軸**：依時間順序排列所有帶有時間戳記的證據。
   - **行為者**：依 GitHub 帳號或電子郵件地址分組。
   - **IOC**：將證據與其相關的 IOC 連結。
4. 識別 **差異**：在一個來源中存在但在另一個來源中缺失的項目 (關鍵的刪除指標)。
5. 將證據標記為 `[VERIFIED]` (已驗證，由 2 個以上獨立來源確認) 或 `[UNVERIFIED]` (未驗證，僅單一來源)。

---

## 第 4 階段：假說形成

假說必須：
- 陳述具體主張 (例如：「行為者 X 在日期對 BRANCH 進行了強制推送，以抹除提交 SHA」)
- 引用至少 2 個支持它的證據 ID (`EV-XXXX`, `EV-YYYY`)
- 識別什麼樣的證據可以駁回它
- 在驗證前標記為 `[HYPOTHESIS]`

**常見假說範本** (參閱 [investigation-templates.md](./references/investigation-templates.md))：
- 維護者帳號入侵：合法帳號在被接管後被用於注入惡意程式碼。
- 相依性混淆：套件名稱搶註以截獲安裝。
- CI/CD 注入：惡意工作流變更以在建置期間執行程式碼。
- 網域/套件誤植 (Typosquatting)：針對拼錯者的近乎相同的套件名稱。
- 憑證洩漏：權杖/金鑰意外提交，然後透過強制推送抹除。

針對每個假說，產生一個 `delegate_task` 子代理人，嘗試在確認之前尋找反證。

---

## 第 5 階段：假說驗證

驗證員子代理人必須機械式地檢查：

1. 針對每個假說，擷取所有引用的證據 ID。
2. 驗證每個 ID 是否存在於 `evidence.json` 中 (如果任何 ID 缺失，則發生硬性故障 → 假說因可能偽造而被拒絕)。
3. 驗證每項標記為 `[VERIFIED]` 的證據是否由 2 個以上來源確認。
4. 檢查邏輯一致性：證據描繪的時間軸是否支持假說？
5. 檢查替代解釋：同樣的證據模式是否可能由良性原因引起？

**輸出**：
- `VALIDATED` (已驗證)：引用了所有證據、已驗證、邏輯一致、無合理的替代解釋。
- `INCONCLUSIVE` (不確定)：證據支持假說，但存在替代解釋或證據不足。
- `REJECTED` (已駁回)：缺失證據 ID、將未驗證證據引用為事實、偵測到邏輯不一致。

被駁回的假說將反饋到第 4 階段進行改進 (最多 3 次迭代)。

---

## 第 6 階段：最終報告生成

使用 [forensic-report.md](./templates/forensic-report.md) 中的範本填寫 `investigation-report.md`。

**必要章節**：
- 執行摘要 (Executive Summary)：一段話的判定 (入侵 / 清白 / 不確定) 及信心水準。
- 時間軸：依時間順序重建所有重大事件，並引用證據。
- 已驗證假說：每個假說的狀態及支持的證據 ID。
- 證據登錄表：所有 `EV-XXXX` 條目的表格，包含來源、類型與驗證狀態。
- IOC 清單：所有擷取與擴展的威脅指標。
- 監管鏈 (Chain of Custody)：證據是如何收集的、來自哪些來源、在什麼時間戳記。
- 建議：如果偵測到入侵，則提供立即的緩解措施；提供監控建議。

**報告規則**：
- 每一項事實主張都必須有至少一個 `[EV-XXXX]` 引用。
- 執行摘要必須陳述信心水準 (高 / 中 / 低)。
- 所有機密/憑證都必須遮蔽為 `[REDACTED]`。

---

## 第 7 階段：完成

1. 執行最終證據計數：`python3 SKILL_DIR/scripts/evidence-store.py --store evidence.json list`
2. 將完整的調查目錄封存。
3. 如果入侵確認：
   - 列出立即的緩解措施 (更換憑證、釘選相依性雜湊值、通知受影響的使用者)。
   - 識別受影響的版本/套件。
   - 註明揭露義務 (如果是公開套件：與套件登錄庫進行協調)。
4. 向使用者呈現最終的 `investigation-report.md`。

---

## 道德使用指引

此技能專為 **防禦性安全調查** 而設計 — 保護開源軟體免受供應鏈攻擊。不得用於：

- 對貢獻者或維護者進行 **騷擾或跟蹤**。
- **人肉搜尋 (Doxing)** — 為了惡意目的將 GitHub 活動與真實身份進行關聯。
- **競爭情報** — 在未經授權的情況下調查私有或內部儲存庫。
- **虛假指控** — 在沒有經過驗證的證據下發布調查結果 (參閱反幻覺護欄)。

調查應遵循 **最小入侵** 原則：僅收集驗證或反駁假說所需的證據。發布結果時，應遵循負責任的揭露慣例，並在公開揭露前與受影響的維護者進行協調。

如果調查揭露了真實的入侵，請遵循協調漏洞揭露流程：
1. 先私下通知儲存庫維護者。
2. 給予合理的修復時間 (通常為 90 天)。
3. 如果受影響的是已發布的套件，請與套件登錄庫 (npm, PyPI 等) 協調。
4. 如果合適，申請 CVE。

---

## API 速率限制

GitHub REST API 強制執行的速率限制如果不加管理，將會中斷大型調查。

**已認證請求**：每小時 5,000 次 (需要 `GITHUB_TOKEN` 環境變數或 `gh` CLI 認證)。
**未認證請求**：每小時 60 次 (對調查而言無法使用)。

**最佳做法**：
- 務必進行認證：`export GITHUB_TOKEN=ghp_...` 或使用 `gh` CLI (自動認證)。
- 使用條件式請求 (`If-None-Match` / `If-Modified-Since` 標頭)，以避免在資料未變更時消耗配額。
- 對於分頁端點，按順序擷取所有頁面 — 不要對同一端點進行平行處理。
- 檢查 `X-RateLimit-Remaining` 標頭；如果低於 100，請暫停直到 `X-RateLimit-Reset` 時間戳記。
- BigQuery 有自己的配額 (每天 10 TiB 免費層級) — 務必先執行 dry-run。
- Wayback Machine CDX API：無正式速率限制，但請保持禮貌 (每秒最多 1-2 個請求)。

如果在調查中途受到速率限制，請將部分結果記錄在證據庫中，並在報告中註明該限制。

---

## 參考資料

- [github-archive-guide.md](./references/github-archive-guide.md) — BigQuery 查詢、CDX API、12 種事件類型。
- [evidence-types.md](./references/evidence-types.md) — IOC 分類、證據來源類型、觀察類型。
- [recovery-techniques.md](./references/recovery-techniques.md) — 恢復已刪除的提交、PR、議題。
- [investigation-templates.md](./references/investigation-templates.md) — 依攻擊類型預建的假說範本。
- [evidence-store.py](./scripts/evidence-store.py) — 用於管理證據 JSON 庫的 CLI 工具。
- [forensic-report.md](./templates/forensic-report.md) — 結構化報告範本。
