# Hermes Agent v0.3.0 (v2026.3.17)

**發佈日期：** 2026 年 3 月 17 日

> 「串流、插件與供應商」的版本 —— 統一的即時 Token 遞送、一等公民級別的插件架構、重構的 Vercel AI Gateway 供應商系統、原生 Anthropic 供應商支援、智慧核准系統、即時 Chrome CDP 瀏覽器連線、ACP IDE 整合、Honcho 記憶、語音模式、持久化 Shell，以及跨平台 50 多項 Bug 修復。

---

## ✨ 亮點更新

- **統一的串流基礎設施** —— CLI 與所有網關平台皆支援即時 Token 遞送。回應隨生成過程即時串流顯示，而非整塊到達。([#1538](https://github.com/NousResearch/hermes-agent/pull/1538))

- **一等公民級別的插件架構** —— 只需將 Python 檔案放入 `~/.hermes/plugins/`，即可為 Hermes 擴充自訂工具、指令與鉤子。無需 Fork 原始碼。([#1544](https://github.com/NousResearch/hermes-agent/pull/1544), [#1555](https://github.com/NousResearch/hermes-agent/pull/1555))

- **原生 Anthropic 供應商** —— 直接呼叫 Anthropic API，具備 Claude Code 憑證自動偵測、OAuth PKCE 流程以及原生提示詞快取功能。不再需要透過 OpenRouter 轉接。([#1097](https://github.com/NousResearch/hermes-agent/pull/1097))

- **智慧核准 + /stop 指令** —— 受 Codex 啟發的核准系統，能學習哪些指令是安全的並記住您的偏好。`/stop` 指令可立即終止目前的代理執行任務。([#1543](https://github.com/NousResearch/hermes-agent/pull/1543))

- **Honcho 記憶整合** —— 支援非同步記憶寫入、可配置的回憶模式、會話標題整合，以及網關模式下的多使用者隔離。由 @erosika 貢獻。([#736](https://github.com/NousResearch/hermes-agent/pull/736))

- **語音模式** —— CLI 支援一鍵通 (PTT)、Telegram/Discord 支援語音留言、Discord 語音頻道支援，並透過 faster-whisper 提供本地 Whisper 轉錄功能。([#1299](https://github.com/NousResearch/hermes-agent/pull/1299), [#1185](https://github.com/NousResearch/hermes-agent/pull/1185), [#1429](https://github.com/NousResearch/hermes-agent/pull/1429))

- **並行工具執行** —— 透過 ThreadPoolExecutor 同步執行多個獨立的工具調用，顯著降低多工具回合的延遲。([#1152](https://github.com/NousResearch/hermes-agent/pull/1152))

- **PII 資訊遮蔽** —— 當啟用 `privacy.redact_pii` 時，系統會在將上下文發送給 LLM 供應商前，自動清除個人識別資訊 (PII)。([#1542](https://github.com/NousResearch/hermes-agent/pull/1542))

- **透過 CDP 執行 `/browser connect`** —— 透過 Chrome DevTools Protocol 將瀏覽器工具連接至執行中的 Chrome 實例。支援對已開啟的頁面進行除錯、檢查與互動。([#1549](https://github.com/NousResearch/hermes-agent/pull/1549))

- **Vercel AI Gateway 供應商** —— 支援透過 Vercel AI Gateway 路由 Hermes，以存取其模型目錄與基礎設施。([#1628](https://github.com/NousResearch/hermes-agent/pull/1628))

- **集中式供應商路由器** —— 重構了具備 `call_llm` API 的供應商系統，包含統一的 `/model` 指令、模型切換時的供應商自動偵測，以及針對輔助/委派用戶端的直接端點覆蓋。([#1003](https://github.com/NousResearch/hermes-agent/pull/1003), [#1506](https://github.com/NousResearch/hermes-agent/pull/1506), [#1375](https://github.com/NousResearch/hermes-agent/pull/1375))

- **ACP 伺服器 (IDE 整合)** —— VS Code, Zed 與 JetBrains 現在可以將 Hermes 作為代理程式後端連線，並支援完整的斜線指令。([#1254](https://github.com/NousResearch/hermes-agent/pull/1254), [#1532](https://github.com/NousResearch/hermes-agent/pull/1532))

- **持久化 Shell 模式** —— 本地與 SSH 終端後端支援跨工具調用保留 Shell 狀態 —— cd 路徑、環境變數與別名皆可持久存在。由 @alt-glitch 貢獻。([#1067](https://github.com/NousResearch/hermes-agent/pull/1067), [#1483](https://github.com/NousResearch/hermes-agent/pull/1483))

- **代理型在策策略蒸餾 (Agentic On-Policy Distillation, OPD)** —— 用於蒸餾代理策略的新 RL 訓練環境，擴展了 Atropos 訓練生態系統。([#1149](https://github.com/NousResearch/hermes-agent/pull/1149))

---

## 🏗️ 核心代理與架構

### 供應商與模型支援
- **集中式供應商路由器** 具備 `call_llm` API 與統一的 `/model` 指令 —— 實現模型與供應商間的無縫切換 ([#1003](https://github.com/NousResearch/hermes-agent/pull/1003))
- 支援 **Vercel AI Gateway** 供應商 ([#1628](https://github.com/NousResearch/hermes-agent/pull/1628))
- 透過 `/model` 切換模型時**自動偵測供應商** ([#1506](https://github.com/NousResearch/hermes-agent/pull/1506))
- 為輔助與委派用戶端提供**直接端點覆蓋** —— 將視覺/子代理呼叫導向特定端點 ([#1375](https://github.com/NousResearch/hermes-agent/pull/1375))
- **原生 Anthropic 輔助視覺** —— 使用 Claude 的原生視覺 API，而非透過相容 OpenAI 的端點路由 ([#1377](https://github.com/NousResearch/hermes-agent/pull/1377))
- Anthropic OAuth 流程改進 —— 自動執行 `claude setup-token`、重新認證、PKCE 狀態持久化、身分指紋識別 ([#1132](https://github.com/NousResearch/hermes-agent/pull/1132), [#1360](https://github.com/NousResearch/hermes-agent/pull/1360), [#1396](https://github.com/NousResearch/hermes-agent/pull/1396), [#1597](https://github.com/NousResearch/hermes-agent/pull/1597))
- 修復 Claude 4.6 模型在不帶 `budget_tokens` 時的自適應思考問題 —— 由 @ASRagab 貢獻 ([#1128](https://github.com/NousResearch/hermes-agent/pull/1128))
- 修復透過適配器傳送的 Anthropic 快取標記 —— 由 @brandtcormorant 貢獻 ([#1216](https://github.com/NousResearch/hermes-agent/pull/1216))
- 重試 Anthropic 429/529 錯誤並向使用者呈現細節 —— 由 @0xbyt4 貢獻 ([#1585](https://github.com/NousResearch/hermes-agent/pull/1585))
- 修復 Anthropic 適配器的 max_tokens、回退崩潰、代理 base_url 等問題 —— 由 @0xbyt4 貢獻 ([#1121](https://github.com/NousResearch/hermes-agent/pull/1121))
- 修復 DeepSeek V3 解析器捨棄多個並行工具調用的問題 —— 由 @mr-emmett-one 貢獻 ([#1365](https://github.com/NousResearch/hermes-agent/pull/1365), [#1300](https://github.com/NousResearch/hermes-agent/pull/1300))
- 接受未列出的模型並發出警告，而非直接拒絕 ([#1047](https://github.com/NousResearch/hermes-agent/pull/1047), [#1102](https://github.com/NousResearch/hermes-agent/pull/1102))
- 針對不支援 OpenRouter 模型的請求跳過推理參數 ([#1485](https://github.com/NousResearch/hermes-agent/pull/1485))
- MiniMax Anthropic API 相容性修復 ([#1623](https://github.com/NousResearch/hermes-agent/pull/1623))
- 自訂端點 `/models` 驗證與 `/v1` 基準 URL 建議 ([#1480](https://github.com/NousResearch/hermes-agent/pull/1480))
- 支援從 `custom_providers` 配置解析委派供應商 ([#1328](https://github.com/NousResearch/hermes-agent/pull/1328))
- 新增 Kimi 模型並修復 User-Agent 問題 ([#1039](https://github.com/NousResearch/hermes-agent/pull/1039))
- 針對 Mistral 相容性剔除 `call_id`/`response_item_id` ([#1058](https://github.com/NousResearch/hermes-agent/pull/1058))

### 代理迴圈與對話
- 支援 **Anthropic 上下文編輯 (Context Editing) API** ([#1147](https://github.com/NousResearch/hermes-agent/pull/1147))
- 改進上下文壓縮移交摘要 —— 壓縮器現在保留更多可執行的狀態 ([#1273](https://github.com/NousResearch/hermes-agent/pull/1273))
- 運行中上下文壓縮後同步 session_id ([#1160](https://github.com/NousResearch/hermes-agent/pull/1160))
- 會話衛生閾值調整為 50%，以實現更積極的壓縮 ([#1096](https://github.com/NousResearch/hermes-agent/pull/1096), [#1161](https://github.com/NousResearch/hermes-agent/pull/1161))
- 透過 `--pass-session-id` 旗標在系統提示詞中包含會話 ID ([#1040](https://github.com/NousResearch/hermes-agent/pull/1040))
- 防止在重試期間重複使用已關閉的 OpenAI 用戶端 ([#1391](https://github.com/NousResearch/hermes-agent/pull/1391))
- 清理聊天負載與供應商優先級 ([#1253](https://github.com/NousResearch/hermes-agent/pull/1253))
- 處理來自 Codex 與本地後端的字典格式工具調用參數 ([#1393](https://github.com/NousResearch/hermes-agent/pull/1393), [#1440](https://github.com/NousResearch/hermes-agent/pull/1440))

### 記憶與會話
- **改進記憶優先級** —— 使用者偏好與修正的權重高於程序性知識 ([#1548](https://github.com/NousResearch/hermes-agent/pull/1548))
- 系統提示詞中更嚴格的記憶與會話回憶指引 ([#1329](https://github.com/NousResearch/hermes-agent/pull/1329))
- 將 CLI Token 計數持久化至會話資料庫以供 `/insights` 使用 ([#1498](https://github.com/NousResearch/hermes-agent/pull/1498))
- 確保 Honcho 回憶內容不進入快取的系統前綴 ([#1201](https://github.com/NousResearch/hermes-agent/pull/1201))
- 修正 `seed_ai_identity` 以使用 `session.add_messages()` ([#1475](https://github.com/NousResearch/hermes-agent/pull/1475))
- 為多使用者網關隔離 Honcho 會話路由 ([#1500](https://github.com/NousResearch/hermes-agent/pull/1500))

---

## 📱 通訊平台 (網關)

### 網關核心
- **系統網關服務模式** —— 支援作為系統級 systemd 服務執行，而不僅限於使用者級別 ([#1371](https://github.com/NousResearch/hermes-agent/pull/1371))
- **網關安裝範圍提示** —— 安裝時可選擇使用者或系統範圍 ([#1374](https://github.com/NousResearch/hermes-agent/pull/1374))
- **推理設定熱重載** —— 無需重啟網關即可更改推理設定 ([#1275](https://github.com/NousResearch/hermes-agent/pull/1275))
- 預設將群組會話設為每使用者隔離 —— 群組聊天中各使用者不再共享狀態 ([#1495](https://github.com/NousResearch/hermes-agent/pull/1495), [#1417](https://github.com/NousResearch/hermes-agent/pull/1417))
- 強化網關重啟恢復能力 ([#1310](https://github.com/NousResearch/hermes-agent/pull/1310))
- 關機期間取消所有進行中的任務 ([#1427](https://github.com/NousResearch/hermes-agent/pull/1427))
- 為 NixOS 與非標準系統自動偵測 SSL 憑證 ([#1494](https://github.com/NousResearch/hermes-agent/pull/1494))
- 在無頭伺服器上為 `systemctl --user` 自動偵測 D-Bus 會話匯流排 ([#1601](https://github.com/NousResearch/hermes-agent/pull/1601))
- 無頭伺服器網關安裝時自動啟用 systemd linger ([#1334](https://github.com/NousResearch/hermes-agent/pull/1334))
- 當 `hermes` 不在 PATH 時回退至模組入口點 ([#1355](https://github.com/NousResearch/hermes-agent/pull/1355))
- 修復 `hermes update` 後 macOS launchd 出現雙網關的問題 ([#1567](https://github.com/NousResearch/hermes-agent/pull/1567))
- 移除 systemd 單元中的遞迴 ExecStop ([#1530](https://github.com/NousResearch/hermes-agent/pull/1530))
- 防止網關模式下日誌處理程序累積 ([#1251](https://github.com/NousResearch/hermes-agent/pull/1251))
- 遇到可重試的啟動失敗時自動重啟 —— 由 @jplew 貢獻 ([#1517](https://github.com/NousResearch/hermes-agent/pull/1517))
- 代理執行後回填網關會話的模型資訊 ([#1306](https://github.com/NousResearch/hermes-agent/pull/1306))
- 基於 PID 的網關關閉與延遲配置寫入 ([#1499](https://github.com/NousResearch/hermes-agent/pull/1499))

### Telegram
- 緩衝媒體組，防止因照片連發導致的自我中斷 ([#1341](https://github.com/NousResearch/hermes-agent/pull/1341), [#1422](https://github.com/NousResearch/hermes-agent/pull/1422))
- 連接與發送期間遇到暫時性 TLS 失敗時進行重試 ([#1535](https://github.com/NousResearch/hermes-agent/pull/1535))
- 強化輪詢衝突處理 ([#1339](https://github.com/NousResearch/hermes-agent/pull/1339))
- MarkdownV2 中跳脫區塊指標與行內程式碼 ([#1478](https://github.com/NousResearch/hermes-agent/pull/1478), [#1626](https://github.com/NousResearch/hermes-agent/pull/1626))
- 斷開連線前檢查更新程式/應用程式狀態 ([#1389](https://github.com/NousResearch/hermes-agent/pull/1389))

### Discord
- 支援 `/thread` 指令、`auto_thread` 配置與媒體元資料修復 ([#1178](https://github.com/NousResearch/hermes-agent/pull/1178))
- @提及時自動開啟討論串，機器人討論串中跳過提及文字 ([#1438](https://github.com/NousResearch/hermes-agent/pull/1438))
- 系統訊息重試時不帶回覆參考 ([#1385](https://github.com/NousResearch/hermes-agent/pull/1385))
- 保留原生文件與影片附件支援 ([#1392](https://github.com/NousResearch/hermes-agent/pull/1392))
- 延遲 Discord 適配器註解，避免選用匯入導致崩潰 ([#1314](https://github.com/NousResearch/hermes-agent/pull/1314))

### Slack
- 討論串處理重構 —— 進度訊息、回應與會話隔離皆遵循討論串規範 ([#1103](https://github.com/NousResearch/hermes-agent/pull/1103))
- 格式化、反應、使用者解析與指令改進 ([#1106](https://github.com/NousResearch/hermes-agent/pull/1106))
- 修正 MAX_MESSAGE_LENGTH 為 39000 ([#1117](https://github.com/NousResearch/hermes-agent/pull/1117))
- 檔案上傳回退保留討論串上下文 —— 由 @0xbyt4 貢獻 ([#1122](https://github.com/NousResearch/hermes-agent/pull/1122))
- 改進安裝引導 ([#1387](https://github.com/NousResearch/hermes-agent/pull/1387))

### 電子郵件 (Email)
- 修復 IMAP UID 追蹤與 SMTP TLS 驗證 ([#1305](https://github.com/NousResearch/hermes-agent/pull/1305))
- 透過 config.yaml 新增 `skip_attachments` 選項 ([#1536](https://github.com/NousResearch/hermes-agent/pull/1536))

### Home Assistant
- 事件過濾預設為關閉 ([#1169](https://github.com/NousResearch/hermes-agent/pull/1169))

---

## 🖥️ CLI 與使用者體驗

### 互動式 CLI
- **持久化 CLI 狀態列** —— 始終顯示模型、供應商與 Token 計數 ([#1522](https://github.com/NousResearch/hermes-agent/pull/1522))
- 輸入提示中支援**檔案路徑自動補全** ([#1545](https://github.com/NousResearch/hermes-agent/pull/1545))
- **`/plan` 指令** —— 根據規格說明生成實作計畫 ([#1372](https://github.com/NousResearch/hermes-agent/pull/1372), [#1381](https://github.com/NousResearch/hermes-agent/pull/1381))
- **`/rollback` 重大改進** —— 更豐富的檢查點歷史與更清晰的 UX ([#1505](https://github.com/NousResearch/hermes-agent/pull/1505))
- **啟動時預載 CLI 技能** —— 第一條提示詞前技能即就緒 ([#1359](https://github.com/NousResearch/hermes-agent/pull/1359))
- **集中式斜線指令註冊表** —— 所有指令唯一定義，處處取用 ([#1603](https://github.com/NousResearch/hermes-agent/pull/1603))
- `/bg` 作為 `/background` 的別名 ([#1590](https://github.com/NousResearch/hermes-agent/pull/1590))
- 斜線指令支援前綴匹配 —— `/mod` 解析為 `/model` ([#1320](https://github.com/NousResearch/hermes-agent/pull/1320))
- `/new`, `/reset`, `/clear` 現在會啟動真正的全新會話 ([#1237](https://github.com/NousResearch/hermes-agent/pull/1237))
- 會話動作支援使用會話 ID 前綴 ([#1425](https://github.com/NousResearch/hermes-agent/pull/1425))
- TUI 提示符號與強調色輸出現在遵循當前皮膚 ([#1282](https://github.com/NousResearch/hermes-agent/pull/1282))
- 註冊表中集中工具 Emoji 元資料 + 皮膚整合 ([#1484](https://github.com/NousResearch/hermes-agent/pull/1484))
- 危險指令核准中新增「查看完整指令」選項 —— 由 @teknium1 基於社群設計實作 ([#887](https://github.com/NousResearch/hermes-agent/pull/887))
- 非阻塞式啟動更新檢查與橫幅去重 ([#1386](https://github.com/NousResearch/hermes-agent/pull/1386))
- `/reasoning` 指令輸出順序與行內 think 擷取修復 ([#1031](https://github.com/NousResearch/hermes-agent/pull/1031))
- 詳細模式 (Verbose) 顯示完整的未截斷輸出 ([#1472](https://github.com/NousResearch/hermes-agent/pull/1472))
- 修復 `/status` 以報告即時狀態與 Token 數 ([#1476](https://github.com/NousResearch/hermes-agent/pull/1476))
- 預設提供全域 SOUL.md ([#1311](https://github.com/NousResearch/hermes-agent/pull/1311))

### 安裝與配置
- **回訪使用者選單分發** —— 回訪時顯示專屬選單，而非僅限索引 ([#3083](https://github.com/NousResearch/hermes-agent/pull/3083))
- **OpenClaw 遷移** —— 首次安裝精靈中提供遷移選項 —— 由 @kshitijk4poor 貢獻 ([#981](https://github.com/NousResearch/hermes-agent/pull/981))
- `hermes claw migrate` 指令 + 遷移文檔 ([#1059](https://github.com/NousResearch/hermes-agent/pull/1059))
- 智慧視覺設定，尊重使用者選取的供應商 ([#1323](https://github.com/NousResearch/hermes-agent/pull/1323))
- 完整處理無頭 (headless) 環境下的安裝流程 ([#1274](https://github.com/NousResearch/hermes-agent/pull/1274))
- setup.py 中優先使用 curses 而非 `simple_term_menu` ([#1487](https://github.com/NousResearch/hermes-agent/pull/1487))
- `/status` 中顯示實際生效的模型與供應商 ([#1284](https://github.com/NousResearch/hermes-agent/pull/1284))
- 配置設定範例使用預留位置語法 ([#1322](https://github.com/NousResearch/hermes-agent/pull/1322))
- 讓 .env 重新載入優先於過時的 Shell 覆蓋 ([#1434](https://github.com/NousResearch/hermes-agent/pull/1434))
- 修復 is_coding_plan 引發的 NameError 崩潰 —— 由 @0xbyt4 貢獻 ([#1123](https://github.com/NousResearch/hermes-agent/pull/1123))
- setuptools 配置中補上缺失的套件 —— 由 @alt-glitch 貢獻 ([#912](https://github.com/NousResearch/hermes-agent/pull/912))
- 安裝程式：釐清為何每個提示都需要 sudo 權限 ([#1602](https://github.com/NousResearch/hermes-agent/pull/1602))

---

## 🔧 工具系統

### 終端與執行
- **持久化 Shell 模式** —— 本地與 SSH 後端支援跨工具調用保留 Shell 狀態 —— 由 @alt-glitch 貢獻 ([#1067](https://github.com/NousResearch/hermes-agent/pull/1067), [#1483](https://github.com/NousResearch/hermes-agent/pull/1483))
- **Tirith 指令預檢掃描** —— 在執行前分析終端指令的安全層 ([#1256](https://github.com/NousResearch/hermes-agent/pull/1256))
- 從所有子進程環境中去除 Hermes 供應商環境變數 ([#1157](https://github.com/NousResearch/hermes-agent/pull/1157), [#1172](https://github.com/NousResearch/hermes-agent/pull/1172), [#1399](https://github.com/NousResearch/hermes-agent/pull/1399), [#1419](https://github.com/NousResearch/hermes-agent/pull/1419)) —— 初始修復由 @eren-karakus0 貢獻
- SSH 預檢檢查 ([#1486](https://github.com/NousResearch/hermes-agent/pull/1486))
- Docker 後端：當前工作目錄 (cwd) 的工作區掛載改為明確選擇加入 (opt-in) ([#1534](https://github.com/NousResearch/hermes-agent/pull/1534))
- execute_code 沙盒中的 PYTHONPATH 包含專案根目錄 ([#1383](https://github.com/NousResearch/hermes-agent/pull/1383))
- 消除網關平台上 execute_code 的進度騷擾訊息 ([#1098](https://github.com/NousResearch/hermes-agent/pull/1098))
- 更清晰的 Docker 後端預檢錯誤 ([#1276](https://github.com/NousResearch/hermes-agent/pull/1276))

### 瀏覽器
- **`/browser connect`** —— 透過 CDP 將瀏覽器工具連接至現有的 Chrome 實例 ([#1549](https://github.com/NousResearch/hermes-agent/pull/1549))
- 改進瀏覽器清理、本地瀏覽器路徑設定以及螢幕截圖恢復 ([#1333](https://github.com/NousResearch/hermes-agent/pull/1333))

### MCP
- **選擇性工具載入**與公用程式政策 —— 過濾哪些 MCP 工具可用 ([#1302](https://github.com/NousResearch/hermes-agent/pull/1302))
- 當 `mcp_servers` 配置變更時，無需重啟即可自動重新載入 MCP 工具 ([#1474](https://github.com/NousResearch/hermes-agent/pull/1474))
- 解決 npx stdio 連線失敗問題 ([#1291](https://github.com/NousResearch/hermes-agent/pull/1291))
- 儲存平台工具配置時保留 MCP 工具集 ([#1421](https://github.com/NousResearch/hermes-agent/pull/1421))

### 視覺 (Vision)
- 統整視覺後端開關機制 ([#1367](https://github.com/NousResearch/hermes-agent/pull/1367))
- 呈現實際錯誤原因而非泛用訊息 ([#1338](https://github.com/NousResearch/hermes-agent/pull/1338))
- 讓 Claude 的圖片處理功能可以完整運作 ([#1408](https://github.com/NousResearch/hermes-agent/pull/1408))

### Cron
- **將 Cron 管理壓縮為單一工具** —— 單一 `cronjob` 工具取代多個指令 ([#1343](https://github.com/NousResearch/hermes-agent/pull/1343))
- 抑制發送至自動遞送目標的重複 Cron 訊息 ([#1357](https://github.com/NousResearch/hermes-agent/pull/1357))
- 將 Cron 會話持久化至 SQLite ([#1255](https://github.com/NousResearch/hermes-agent/pull/1255))
- 各別任務支援運行時覆蓋 (供應商、模型、base_url) ([#1398](https://github.com/NousResearch/hermes-agent/pull/1398))
- `save_job_output` 採用原子寫入，防止崩潰時資料遺失 ([#1173](https://github.com/NousResearch/hermes-agent/pull/1173))
- `deliver=origin` 遞送模式下保留討論串上下文 ([#1437](https://github.com/NousResearch/hermes-agent/pull/1437))

### 修補工具 (Patch Tool)
- 避免 V4A 修補套用時損壞管道符號 (|) ([#1286](https://github.com/NousResearch/hermes-agent/pull/1286))
- 放寬 `block_anchor` 閾值並支援 Unicode 正規化 ([#1539](https://github.com/NousResearch/hermes-agent/pull/1539))

### 委派 (Delegation)
- 為子代理結果新增可觀測元資料 (模型、Token、耗時、工具軌跡) ([#1175](https://github.com/NousResearch/hermes-agent/pull/1175))

---

## 🧩 技能生態系統

### 技能系統
- **整合 skills.sh** 作為除 ClawHub 外的另一中心來源 ([#1303](https://github.com/NousResearch/hermes-agent/pull/1303))
- 載入時安全地設定技能環境 ([#1153](https://github.com/NousResearch/hermes-agent/pull/1153))
- 危險指令判定遵循政策表規範 ([#1330](https://github.com/NousResearch/hermes-agent/pull/1330))
- 強化 ClawHub 技能搜尋的精確匹配 ([#1400](https://github.com/NousResearch/hermes-agent/pull/1400))
- 修復 ClawHub 技能安裝 —— 使用 `/download` ZIP 端點 ([#1060](https://github.com/NousResearch/hermes-agent/pull/1060))
- 避免將本地技能誤標記為內建 —— 由 @arceus77-7 貢獻 ([#862](https://github.com/NousResearch/hermes-agent/pull/862))

### 新技能
- **Linear** 專案管理 ([#1230](https://github.com/NousResearch/hermes-agent/pull/1230))
- 透過 x-cli 使用 **X/Twitter** ([#1285](https://github.com/NousResearch/hermes-agent/pull/1285))
- **電話通訊 (Telephony)** —— Twilio、SMS 與 AI 通話 ([#1289](https://github.com/NousResearch/hermes-agent/pull/1289))
- **1Password** —— 由 @arceus77-7 貢獻 ([#883](https://github.com/NousResearch/hermes-agent/pull/883), [#1179](https://github.com/NousResearch/hermes-agent/pull/1179))
- **NeuroSkill BCI** 腦機介面整合 ([#1135](https://github.com/NousResearch/hermes-agent/pull/1135))
- 用於 3D 建模的 **Blender MCP** ([#1531](https://github.com/NousResearch/hermes-agent/pull/1531))
- **開源安全鑑識 (OSS Security Forensics)** ([#1482](https://github.com/NousResearch/hermes-agent/pull/1482))
- **Parallel CLI** 研究技能 ([#1301](https://github.com/NousResearch/hermes-agent/pull/1301))
- **OpenCode** CLI 技能 ([#1174](https://github.com/NousResearch/hermes-agent/pull/1174))
- **ASCII Video** 技能重構 —— 由 @SHL0MS 貢獻 ([#1213](https://github.com/NousResearch/hermes-agent/pull/1213), [#1598](https://github.com/NousResearch/hermes-agent/pull/1598))

---

## 🎙️ 語音模式

- 建立語音模式基礎 —— CLI 一鍵通、Telegram/Discord 語音留言 ([#1299](https://github.com/NousResearch/hermes-agent/pull/1299))
- 透過 faster-whisper 提供免費的本地 Whisper 轉錄功能 ([#1185](https://github.com/NousResearch/hermes-agent/pull/1185))
- Discord 語音頻道穩定性修復 ([#1429](https://github.com/NousResearch/hermes-agent/pull/1429))
- 恢復網關語音留言的本地 STT 回退機制 ([#1490](https://github.com/NousResearch/hermes-agent/pull/1490))
- 網關轉錄全面遵循 `stt.enabled: false` 設定 ([#1394](https://github.com/NousResearch/hermes-agent/pull/1394))
- 修復 Telegram 語音留言中錯誤的「無此能力」訊息 (Issue [#1033])

---

## 🔌 ACP (IDE 整合)

- 恢復 ACP 伺服器實作 ([#1254](https://github.com/NousResearch/hermes-agent/pull/1254))
- ACP 適配器支援斜線指令 ([#1532](https://github.com/NousResearch/hermes-agent/pull/1532))

---

## 🧪 RL 訓練

- **代理型在策策略蒸餾 (Agentic On-Policy Distillation, OPD)** 環境 —— 用於代理策略蒸餾的新 RL 訓練環境 ([#1149](https://github.com/NousResearch/hermes-agent/pull/1149))
- 讓 tinker-atropos RL 訓練完全成為選用項目 ([#1062](https://github.com/NousResearch/hermes-agent/pull/1062))

---

## 🔒 安全性與可靠性

### 安全性強化
- **Tirith 指令預檢掃描** —— 終端指令執行前的靜態分析 ([#1256](https://github.com/NousResearch/hermes-agent/pull/1256))
- 啟用 `privacy.redact_pii` 時進行 **PII 資訊遮蔽** ([#1542](https://github.com/NousResearch/hermes-agent/pull/1542))
- 從所有子進程環境中去除 Hermes 供應商/網關/工具的環境變數 ([#1157], [#1172], [#1399], [#1419])
- Docker 當前工作目錄掛載現在為明確選擇加入 —— 絕不自動掛載主機目錄 ([#1534])
- Fork Bomb 正則表達式中跳脫括號與大括號 ([#1397])
- 強化 `.worktreeinclude` 的路徑包含限制 ([#1388])
- 使用描述作為 `pattern_key` 以防止核准衝突 ([#1395])

### 可靠性
- 保護初始化階段的標準 I/O 寫入 ([#1271])
- 會話日誌寫入重用共享的原子 JSON 輔助程式 ([#1280])
- 在中斷發生時保護原子的暫存檔案清理 ([#1401])

---

## 🐛 重大 Bug 修復

- **`/status` 始終顯示 0 tokens** —— 現在可報告即時狀態 (Issue [#1465], [#1476])
- **自訂模型端點無效** —— 恢復了從配置儲存的端點解析功能 (Issue [#1460], [#1373])
- **MCP 工具直到重啟才可見** —— 支援配置變更時自動重載 (Issue [#1036], [#1474])
- **`hermes tools` 曾會移除 MCP 工具** —— 儲存時會保留 MCP 工具集 (Issue [#1247], [#1421])
- **終端子進程繼承 `OPENAI_BASE_URL`** 導致外部工具損壞 (Issue [#1002], [#1399])
- **網關重啟後背景進程遺失** —— 改進了恢復機制 (Issue [#1144])
- **Cron 任務未持久化狀態** —— 現在儲存於 SQLite 中 (Issue [#1416], [#1255])
- **Cron 任務 `deliver: origin` 未保留討論串上下文** (Issue [#1219], [#1437])
- **網關 systemd 服務在瀏覽器進程孤立時無法自動重啟** (Issue [#1617])
- **Telegram 中 `/background` 完成報告被截斷** (Issue [#1443])
- **模型切換未生效** (Issue [#1244], [#1183])
- **`hermes doctor` 將 Cron 任務回報為不可用** (Issue [#878], [#1180])
- **無法從手機接收 WhatsApp 橋接訊息** (Issue [#1142])
- **安裝精靈在無頭 SSH 環境中掛起** (Issue [#905], [#1274])
- **日誌處理程序累積** 導致網關效能下降 (Issue [#990], [#1251])
- **網關在資料庫中產生 NULL 模型** (Issue [#987], [#1306])
- **嚴格的端點拒絕重放的 tool_calls** (Issue [#893])
- **殘留的硬編碼 `~/.hermes` 路徑** —— 現在全部遵循 `HERMES_HOME` (Issue [#892], [#1233])
- **委派工具無法與自訂推論供應商配合運作** (Issue [#1011], [#1328])
- **技能防護 (Skills Guard) 阻擋官方技能** (Issue [#1006], [#1330])
- **安裝程式在選擇模型前就寫入供應商資訊** (Issue [#1182])
- **`GatewayConfig.get()` 引發 AttributeError** 導致訊息處理崩潰 (Issue [#1158], [#1287])
- **`/update` 因「找不到指令」而失敗** (Issue [#1049])
- **圖片分析靜默失敗** (Issue [#1034], [#1338])
- **API 因 `'dict'` 物件無 `'strip'` 屬性而報 `BadRequestError`** (Issue [#1071])
- **斜線指令要求精確的全名** —— 現在支援前綴匹配 (Issue [#928], [#1320])
- **在無頭環境關閉終端時網關停止回應** (Issue [#1005])

---

## 🧪 測試

- 涵蓋空的快取 Anthropic 工具調用回合 ([#1222])
- 修正解析器與快速指令測試中過時的 CI 假設 ([#1236])
- 修復無隱式事件迴圈的網關非同步測試 ([#1278])
- 讓網關非同步測試支援 xdist 並行執行 ([#1281])
- 修復 Cron 跨時區原始時間戳記回歸問題 ([#1319])
- 將 Codex 供應商測試與本地環境隔離 ([#1335])
- 鎖定重試替換語義 ([#1379])
- 改進會話搜尋工具的錯誤日誌 —— 由 @aydnOktay 貢獻 ([#1533])

---

## 📚 文檔更新

- 完整的 SOUL.md 指南 ([#1315])
- 語音模式文檔 ([#1316], [#1362])
- 供應商貢獻指南 ([#1361])
- ACP 與內部系統實作指南 ([#1259])
- 擴大 Docusaurus 對 CLI、工具、技能與皮膚的覆蓋 ([#1232])
- 終端後端與 Windows 疑難排解 ([#1297])
- 技能中心參考章節 ([#1317])
- 檢查點、/rollback 與 git 工作樹指南 ([#1493], [#1524])
- CLI 狀態列與 /usage 參考 ([#1523])
- 回退供應商 + /background 指令文檔 ([#1430])
- 網關服務範圍文檔 ([#1378])
- Slack 討論串回覆行為文檔 ([#1407])
- 使用 Nous 藍色調重新設計首頁 —— 由 @austinpickett 貢獻 ([#974])
- 修正多處文檔錯字 —— 由 @JackTheGit 貢獻 ([#953])
- 穩定網站圖表 ([#1405])
- README 中新增 CLI 與通訊平台快速對照 ([#1491])
- 為 Docusaurus 新增搜尋功能 ([#1053])
- Home Assistant 整合文檔 ([#1170])

---

## 👥 貢獻者

### 核心團隊
- **@teknium1** —— 220 多個 PR，涵蓋程式碼庫的各個領域

### 傑出社群貢獻者

- **@0xbyt4** (4 PRs) —— Anthropic 適配器修復 (max_tokens, 回退崩潰, 429/529 重試)、Slack 檔案上傳討論串上下文、安裝精靈 NameError 修復
- **@erosika** (1 PR) —— Honcho 記憶整合：非同步寫入、記憶模式、會話標題整合
- **@SHL0MS** (2 PRs) —— ASCII 影片技能設計模式與重構
- **@alt-glitch** (2 PRs) —— 本地/SSH 後端持久化 Shell 模式、setuptools 打包修復
- **@arceus77-7** (2 PRs) —— 1Password 技能、修復技能列表誤標記問題
- **@kshitijk4poor** (1 PR) —— 安裝精靈中的 OpenClaw 遷移
- **@ASRagab** (1 PR) —— 修正 Claude 4.6 模型的自適應思考
- **@eren-karakus0** (1 PR) —— 從子進程環境中去除 Hermes 供應商環境變數
- **@mr-emmett-one** (1 PR) —— 修正 DeepSeek V3 解析器多工具調用支援
- **@jplew** (1 PR) —— 遇到可重試啟動失敗時重啟網關
- **@brandtcormorant** (1 PR) —— 修正空文字區塊的 Anthropic 快取控制
- **@aydnOktay** (1 PR) —— 改進會話搜尋工具的錯誤日誌
- **@austinpickett** (1 PR) —— 使用 Nous 藍色調重新設計首頁
- **@JackTheGit** (1 PR) —— 文檔錯字修正

### 所有貢獻者

@0xbyt4, @alt-glitch, @arceus77-7, @ASRagab, @austinpickett, @aydnOktay, @brandtcormorant, @eren-karakus0, @erosika, @JackTheGit, @jplew, @kshitijk4poor, @mr-emmett-one, @SHL0MS, @teknium1

---

**完整變更日誌**: [v2026.3.12...v2026.3.17](https://github.com/NousResearch/hermes-agent/compare/v2026.3.12...v2026.3.17)
