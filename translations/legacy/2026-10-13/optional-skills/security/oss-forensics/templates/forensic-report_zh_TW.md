# 鑑識調查報告

> **說明**：請填寫所有章節。每個事實陳述都必須引用至少一個 `[EV-XXXX]` 證據 ID。
> 在完成報告前，請刪除預留位置文字和說明備註。將所有機密資訊遮蓋為 `[已遮蓋]`。

---

## 執行摘要 (Executive Summary)

**目標儲存庫**：`OWNER/REPO`
**調查期間**：YYYY-MM-DD 至 YYYY-MM-DD
**判定結果**：<!-- 已遭入侵 / 無虞 / 無法斷定 -->
**信心水準**：<!-- 高 / 中 / 低 -->
**報告日期**：YYYY-MM-DD
**調查人員**：<!-- 代理人階段 ID 或分析師姓名 -->

<!-- 摘要段落：調查內容、發現結果、建議措施。 -->

---

## 事件時間軸 (Timeline of Events)

> 所有時間均使用 UTC 格式。每個事件必須引用至少一個證據 ID。

| 時間戳記 (UTC) | 事件 | 證據 ID | 來源 |
|-----------------|-------|--------------|--------|
| YYYY-MM-DDTHH:MM:SSZ | _描述事件_ | [EV-XXXX] | git / gh_api / gh_archive / web_archive |
| | | | |

---

## 已驗證假說 (Validated Hypotheses)

### 假說 1：<!-- 簡短標題 -->

**狀態**：<!-- 已驗證 / 無法斷定 / 已駁回 -->

**主張**：_假說的完整陳述。_

**支持證據**：
- [EV-XXXX]：_此證據顯示的內容_
- [EV-YYYY]：_此證據顯示的內容_

**已考慮的反證**：_可能證偽此假說的內容，以及為何將其排除或不予排除。_

**信心水準**：<!-- 高 / 中 / 低，以及原因 -->

---

## 入侵指標 (IOC 清單)

| 類型 | 數值 | 狀態 | 證據 |
|------|-------|--------|----------|
| COMMIT_SHA | `abc123...` | 確認惡意 | [EV-XXXX] |
| ACTOR_USERNAME | `handle` | 疑似遭冒用 | [EV-YYYY] |
| FILE_PATH | `src/evil.js` | 確認惡意 | [EV-ZZZZ] |
| DOMAIN | `evil-cdn.io` | 確認為 C2 | [EV-WWWW] |

---

## 受影響版本

| 版本 / 標籤 (Tag) | 發布日期 | 是否包含惡意代碼 | 證據 |
|---------------|-----------|------------------------|----------|
| `v1.2.3` | YYYY-MM-DD | 是 / 否 / 未知 | [EV-XXXX] |

---

## 證據登記簿 (Evidence Registry)

> 生成方式：`python3 SKILL_DIR/scripts/evidence-store.py --store evidence.json export`

<!-- 在此貼上來自 evidence-store.py export 命令輸出的 Markdown 表格 -->

| ID | 類型 | 來源 | 行動者 (Actor) | 驗證狀態 | 事件時間戳記 | URL |
|----|------|--------|-------|--------------|-----------------|-----|
| EV-0001 | | | | | | |

---

## 監管鏈 (Chain of Custody)

> 生成方式：`python3 SKILL_DIR/scripts/evidence-store.py --store evidence.json export`

<!-- 在此貼上 export 輸出中的監管鏈章節 -->

| 證據 ID | 行動 | 時間戳記 | 來源 |
|-------------|--------|-----------|--------|
| EV-0001 | 新增 | | |

---

## 技術發現

### Git 歷史紀錄分析

_總結本地 git 分析的發現：懸空提交 (dangling commits)、reflog 異常、未簽署的提交、新增二進位檔案等。_

### GitHub API 分析

_總結 GitHub REST API 的發現：刪除的 PR/Issue、貢獻者異動、發布版本 (Release) 異常等。_

### GitHub Archive 分析

_總結 BigQuery 的發現：強制推送 (force-push) 事件、刪除事件、工作流異常、成員異動等。_
_備註：若無法使用 BigQuery，請明確說明。_

### Wayback Machine 分析

_總結 archive.org 的發現：復原已刪除的頁面、歷史內容差異等。_

### IOC 富化 (Enrichment)

_總結富化結果：網域的 WHOIS 資料、復原的提交內容、行動者帳號分析等。_

---

## 建議措施

### 緊急行動 (若確認遭入侵)

- [ ] 更換所有可能已洩漏的 GitHub 權杖 (Tokens)、API 金鑰和憑證。
- [ ] 在所有受影響的套件中，將依賴項版本鎖定為特定的雜湊值 (Hashes)。
- [ ] 發布安全性公告 / CVE (若適用)。
- [ ] 通知下游使用者/套件註冊表 (npm, PyPI 等)。
- [ ] 撤銷遭冒用帳號的存取權限，並使用硬體二階段驗證 (2FA) 重新加固。
- [ ] 稽核所有 CI/CD 工作流檔案是否存在未經授權的修改。
- [ ] 審查入侵期間發布的所有版本。

### 監控建議

- [ ] 對 `main`/`master` 分支啟用分支保護 (要求程式碼審查、禁止強制推送)。
- [ ] 啟用強制提交簽署 (GPG/SSH)。
- [ ] 設定 GitHub 稽核日誌串流，以便未來監控。
- [ ] 在鎖定檔案 (lock files) 中將關鍵依賴項鎖定為已知良好的 SHA。

---

## 限制與注意事項

- _列出任何無法取得的資料來源 (例如：無法存取 BigQuery)_
- _註明任何僅有單一來源的證據 (未經獨立驗證)_
- _註明任何無法確認或否認的假說_

---

## 參考資料

- 證據儲存庫：`evidence.json` (SHA-256 完整性校驗：執行 `python3 SKILL_DIR/scripts/evidence-store.py --store evidence.json verify`)
- 相關 Issue：<!-- 連結至 GitHub Issues、CVE、安全性公告 -->
- RAPTOR 框架：https://github.com/gadievron/raptor
