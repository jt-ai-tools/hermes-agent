# Hermes Agent 安全政策

本文件概述了 **Hermes Agent** 專案的安全協定、信任模型以及部署強化指南。

## 1. 漏洞回報

Hermes Agent **沒有** 運作漏洞賞金計畫。安全問題應透過 [GitHub 安全公告 (GHSA)](https://github.com/NousResearch/hermes-agent/security/advisories/new) 回報，或寄送電子郵件至 **security@nousresearch.com**。請勿針對安全漏洞建立公開的 Issue。

### 提交所需細節
- **標題與嚴重性：** 簡要描述及 CVSS 評分/分級。
- **受影響組件：** 確切的檔案路徑與行號範圍 (例如：`tools/approval.py:120-145`)。
- **環境：** `hermes version` 的輸出、Commit SHA、作業系統以及 Python 版本。
- **重現步驟：** 針對 `main` 分支或最新發佈版本的逐步概念驗證 (PoC)。
- **影響：** 說明跨越了哪種信任邊界。

---

## 2. 信任模型

核心假設是 Hermes 是一個具備單一受信任操作者的 **個人代理程式**。

### 操作者與會話信任
- **單租戶：** 系統保護操作者免受 LLM 行為的影響，而非保護其免受惡意共用租戶的影響。多使用者隔離必須在作業系統/主機層級進行。
- **網關安全：** 經過授權的呼叫者 (Telegram, Discord, Slack 等) 獲得同等的信任。會話金鑰用於路由，而非作為授權邊界。
- **執行：** 預設為 `terminal.backend: local` (直接在主機執行)。容器隔離 (Docker, Modal, Daytona) 是沙盒化的選用項目。

### 危險指令核准
核准系統 (`tools/approval.py`) 是核心安全邊界。終端指令、檔案操作以及其他具備潛在破壞性的行為，在執行前都必須經過使用者的明確確認。核准模式可透過 `config.yaml` 中的 `approvals.mode` 進行配置：
- `"on"` (預設) —— 提示使用者核准危險指令。
- `"auto"` —— 在可配置的延遲後自動核准。
- `"off"` —— 完全停用核准閘門 (僅限緊急情況；參見第 3 節)。

### 輸出遮蔽 (Redaction)
`agent/redact.py` 會在所有顯示輸出到達終端或網關平台之前，去除類似機密資訊的模式 (API 金鑰、權杖、憑證)。這能防止機密資訊意外洩漏在對話日誌、工具預覽與回應文字中。遮蔽僅運作於顯示層 —— 原始值在代理程式內部操作中保持完整。

### 技能 (Skills) 與 MCP 伺服器
- **安裝的技能：** 高信任度。等同於本地主機程式碼；技能可以讀取環境變數並執行任意指令。
- **MCP 伺服器：** 較低信任度。MCP 子進程接收經過過濾的環境 (`tools/mcp_tool.py` 中的 `_build_safe_env()`) —— 僅傳遞安全的基準變數 (`PATH`, `HOME`, `XDG_*`) 以及在伺服器 `env` 配置塊中明確宣告的變數。主機憑證預設會被去除。此外，透過 `npx`/`uvx` 呼叫的套件在啟動前會針對 OSV 惡意軟體資料庫進行檢查。

### 程式碼執行沙盒
`execute_code` 工具 (`tools/code_execution_tool.py`) 在子進程中執行 LLM 生成的 Python 腳本，並從環境中去除 API 金鑰與權杖，以防止憑證外洩。僅有由已加載技能 (透過 `env_passthrough`) 或使用者在 `config.yaml` (`terminal.env_passthrough`) 中明確宣告的環境變數會被傳遞。子進程透過 RPC 存取 Hermes 工具，而非直接進行 API 呼叫。

### 子代理 (Subagents)
- **禁止遞迴委派：** 子代理禁用 `delegate_task` 工具。
- **深度限制：** `MAX_DEPTH = 2` —— 父代理 (深度 0) 可以生成一個子代理 (深度 1)；拒絕生成孫代理。
- **記憶隔離：** 子代理執行時設定 `skip_memory=True`，且無法存取父代理的持久記憶供應商。父代理僅接收任務提示詞與最終回應作為觀測結果。

---

## 3. 不在受理範圍內 (非漏洞)

以下情境**不被視為**安全漏洞：
- **提示詞注入 (Prompt Injection)：** 除非它導致具體繞過核准系統、工具集限制或容器沙盒。
- **公開暴露：** 在沒有外部認證或網路保護的情況下，將網關部署至公開網際網路。
- **受信任狀態存取：** 需要預先具備對 `~/.hermes/`、`.env` 或 `config.yaml` 的寫入權限的回報 (這些是操作者擁有的檔案)。
- **預設行為：** 當 `terminal.backend` 設定為 `local` 時的主機級指令執行 —— 這是文件說明的預設行為，而非漏洞。
- **配置權衡：** 生產環境中刻意的緊急設定，例如 `approvals.mode: "off"` 或 `terminal.backend: local`。
- **工具級讀取/存取限制：** 代理程式設計上可透過 `terminal` 工具進行無限制的 Shell 存取。若某個特定工具 (例如 `read_file`) 可以存取某個資源，但該資源同樣可以透過 `terminal` 存取，則不視為漏洞。工具級的禁用清單僅在與終端側的等效限制 (例如寫入操作，其中 `WRITE_DENIED_PATHS` 與危險指令核准系統配對) 搭配時，才構成有意義的安全邊界。

---

## 4. 部署強化與最佳實踐

### 檔案系統與網路
- **生產環境沙盒化：** 針對不可信的工作負載，使用容器後端 (`docker`, `modal`, `daytona`) 而非 `local`。
- **檔案權限：** 以非 root 身份執行 (Docker 映像檔使用 UID 10000)；在本地安裝中，使用 `chmod 600 ~/.hermes/.env` 保護憑證。
- **網路暴露：** 在沒有 VPN、Tailscale 或防火牆保護的情況下，不要將網關或 API 伺服器暴露於公開網際網路。所有網關平台適配器 (Telegram, Discord, Slack, Matrix, Mattermost 等) 預設啟用了具備重新導向驗證的 SSRF 防護。注意：本地終端後端不套用 SSRF 過濾，因為它運作於受信任的操作者環境中。

### 技能與供應鏈
- **技能安裝：** 在安裝第三方技能前，請審核技能防護報告 (`tools/skills_guard.py`)。位於 `~/.hermes/skills/.hub/audit.log` 的稽核日誌紀錄了每次安裝與移除。
- **MCP 安全：** 在啟動 MCP 伺服器進程前，會自動對 `npx`/`uvx` 套件進行 OSV 惡意軟體檢查。
- **CI/CD：** GitHub Actions 鎖定為完整的 Commit SHA。`supply-chain-audit.yml` 工作流會阻擋包含 `.pth` 檔案或可疑的 `base64`+`exec` 模式的 PR。

### 憑證儲存
- API 金鑰與權杖應僅存放於 `~/.hermes/.env` —— 絕不要放入 `config.yaml` 或提交至版本控制系統。
- 憑證池系統 (`agent/credential_pool.py`) 負責金鑰輪換與回退。憑證是從環境變數解析，而非以明文儲存於資料庫中。

---

## 5. 揭露流程

- **協調披露：** 90 天窗口期，或直到修復程式發佈，以先到者為準。
- **溝通：** 所有更新皆透過 GHSA 討論串或與 security@nousresearch.com 的電子郵件往來進行。
- **致謝：** 除非要求匿名，否則報告者將在發佈說明中獲得致謝。
