# Hermes Agent v0.7.0 (v2026.4.3)

**發佈日期：** 2026 年 4 月 3 日

> 「穩定與恢復」的版本 —— 可插拔的記憶供應商、憑證池輪換、Camofox 反偵測瀏覽器、行內 Diff 預覽、網關針對競態條件與核准路由的強化，以及涵蓋 168 個 PR 與 46 個已解決 Issue 的深度安全修復。

---

## ✨ 亮點更新

- **可插拔記憶供應商介面** —— 記憶系統現在是一個可擴展的插件系統。第三方記憶後端（Honcho、向量資料庫、自訂資料庫）只需實作簡單的 ABC 供應商介面並透過插件系統註冊即可。內建記憶為預設供應商。Honcho 整合已修復至完整對齊狀態，作為具備個人檔案範圍之主機/對等解析的參考插件。([#4623](https://github.com/NousResearch/hermes-agent/pull/4623), [#4616](https://github.com/NousResearch/hermes-agent/pull/4616), [#4355](https://github.com/NousResearch/hermes-agent/pull/4355))

- **同供應商憑證池** —— 可針對同一個供應商配置多個 API 金鑰並自動輪換。執行緒安全的「最少使用 (least_used)」策略可將負載分配至各個金鑰，且在遇到 401 錯誤時會自動輪換至下一個憑證。可透過安裝精靈或 `credential_pool` 配置進行設定。([#4188](https://github.com/NousResearch/hermes-agent/pull/4188), [#4300](https://github.com/NousResearch/hermes-agent/pull/4300), [#4361](https://github.com/NousResearch/hermes-agent/pull/4361))

- **Camofox 反偵測瀏覽器後端** —— 全新的本地瀏覽器後端，使用 Camoufox 進行隱身瀏覽。支援具備 VNC URL 偵測功能的持久化會話，方便進行視覺化除錯，並可為本地後端配置 SSRF 繞過。可透過 `hermes tools` 自動安裝。([#4008](https://github.com/NousResearch/hermes-agent/pull/4008), [#4419](https://github.com/NousResearch/hermes-agent/pull/4419), [#4292](https://github.com/NousResearch/hermes-agent/pull/4292))

- **行內 Diff 預覽** —— 檔案寫入與修補操作現在會在工具活動饋送中顯示行內 Diff，讓您在代理程式繼續下一步前，能直觀確認變更內容。([#4411](https://github.com/NousResearch/hermes-agent/pull/4411), [#4423](https://github.com/NousResearch/hermes-agent/pull/4423))

- **API 伺服器會話連續性與工具串流** —— API 伺服器（Open WebUI 整合）現在支援即時串流工具進度事件，並支援 `X-Hermes-Session-Id` 標頭以實現跨請求的持久化會話。會話將持久化於共享的 SessionDB。([#4092](https://github.com/NousResearch/hermes-agent/pull/4092), [#4478](https://github.com/NousResearch/hermes-agent/pull/4478), [#4802](https://github.com/NousResearch/hermes-agent/pull/4802))

- **ACP：用戶端提供的 MCP 伺服器** —— 編輯器整合（VS Code, Zed, JetBrains）現在可以註冊自己的 MCP 伺服器，Hermes 會將其識別為額外的代理工具。您的編輯器 MCP 生態系統將直接流入代理程式。([#4705](https://github.com/NousResearch/hermes-agent/pull/4705))

- **網關強化** —— 針對競態條件、照片媒體遞送、流量控制、卡住的會話、核准路由以及壓縮死亡螺旋進行了重大穩定性優化。網關在生產環境中的可靠性顯著提升。([#4727](https://github.com/NousResearch/hermes-agent/pull/4727), [#4750](https://github.com/NousResearch/hermes-agent/pull/4750), [#4798](https://github.com/NousResearch/hermes-agent/pull/4798), [#4557](https://github.com/NousResearch/hermes-agent/pull/4557))

- **安全性：機密外洩阻擋** —— 現在會掃描瀏覽器 URL 與 LLM 回應中的機密模式，阻擋透過 URL 編碼、Base64 或提示詞注入的外洩企圖。憑證目錄保護擴展至 `.docker`, `.azure`, `.config/gh`。`execute_code` 沙盒輸出也會經過遮蔽處理。([#4483](https://github.com/NousResearch/hermes-agent/pull/4483), [#4360](https://github.com/NousResearch/hermes-agent/pull/4360), [#4305](https://github.com/NousResearch/hermes-agent/pull/4305), [#4327](https://github.com/NousResearch/hermes-agent/pull/4327))

---

## 🏗️ 核心代理與架構

### 供應商與模型支援
- **同供應商憑證池** —— 支援配置多個 API 金鑰，具備自動「最少使用」輪換與 401 故障轉移 ([#4188](https://github.com/NousResearch/hermes-agent/pull/4188), [#4300](https://github.com/NousResearch/hermes-agent/pull/4300))
- **憑證池狀態跨智慧路由保留** —— 憑證池狀態在回退供應商切換中保持存續，並在遇到 429 錯誤時推遲過早的回退行為 ([#4361](https://github.com/NousResearch/hermes-agent/pull/4361))
- **每回合恢復主運行時** —— 在使用回退供應商後，代理程式會在下一回合自動恢復主供應商並進行傳輸層恢復 ([#4624](https://github.com/NousResearch/hermes-agent/pull/4624))
- **為 GPT-5 與 Codex 模型提供 `developer` 角色** —— 針對較新模型使用 OpenAI 推薦的系統訊息角色 ([#4498](https://github.com/NousResearch/hermes-agent/pull/4498))
- **Google 模型操作指引** —— 為 Gemini 與 Gemma 模型提供供應商特定的提示指引 ([#4641](https://github.com/NousResearch/hermes-agent/pull/4641))
- **Anthropic 長上下文層級 429 處理** —— 觸發層級限制時自動將上下文縮減至 200k ([#4747](https://github.com/NousResearch/hermes-agent/pull/4747))
- **第三方 Anthropic 端點的 URL 認證** + CI 測試修復 ([#4148](https://github.com/NousResearch/hermes-agent/pull/4148))
- **MiniMax Anthropic 端點的 Bearer 認證** ([#4028](https://github.com/NousResearch/hermes-agent/pull/4028))
- **Fireworks 上下文長度偵測** ([#4158](https://github.com/NousResearch/hermes-agent/pull/4158))
- **阿里巴巴供應商標準 DashScope 國際端點** ([#4133](https://github.com/NousResearch/hermes-agent/pull/4133), 關閉 [#3912](https://github.com/NousResearch/hermes-agent/issues/3912))
- **自訂供應商的上下文長度**在衛生壓縮中獲得遵循 ([#4085](https://github.com/NousResearch/hermes-agent/pull/4085))
- **非 sk-ant 開頭的金鑰**視為一般 API 金鑰，而非 OAuth Token ([#4093](https://github.com/NousResearch/hermes-agent/pull/4093))
- **Claude-sonnet-4.6** 加入 OpenRouter 與 Nous 模型列表 ([#4157](https://github.com/NousResearch/hermes-agent/pull/4157))
- **Qwen 3.6 Plus Preview** 加入模型列表 ([#4376](https://github.com/NousResearch/hermes-agent/pull/4376))
- **MiniMax M2.7** 加入 Hermes 模型選擇器與 OpenCode ([#4208](https://github.com/NousResearch/hermes-agent/pull/4208))
- **自訂端點設定支援從伺服器探測自動偵測模型** ([#4218](https://github.com/NousResearch/hermes-agent/pull/4218))
- **Config.yaml 作為端點 URL 的單一事實來源** —— 解決環境變數與 config.yaml 之間的衝突 ([#4165](https://github.com/NousResearch/hermes-agent/pull/4165))
- **安裝精靈不再覆蓋自訂端點配置** ([#4180](https://github.com/NousResearch/hermes-agent/pull/4180), 關閉 [#4172](https://github.com/NousResearch/hermes-agent/issues/4172))
- **整合安裝精靈與 `hermes model` 的供應商選擇** —— 統一兩者流程的程式碼路徑 ([#4200](https://github.com/NousResearch/hermes-agent/pull/4200))
- **根級別供應商配置**不再會覆蓋 `model.provider` ([#4329](https://github.com/NousResearch/hermes-agent/pull/4329))
- **限制配對拒絕訊息的頻率**以防止垃圾訊息 ([#4081](https://github.com/NousResearch/hermes-agent/pull/4081))

### 代理迴圈與對話
- **跨工具調用回合保留 Anthropic 思考塊簽章** ([#4626](https://github.com/NousResearch/hermes-agent/pull/4626))
- **在重試前對「僅含思考」的空回應進行分類** —— 防止在僅生成思考塊而無內容的模型上發生無限重試 ([#4645](https://github.com/NousResearch/hermes-agent/pull/4645))
- **防止因 API 斷線導致的壓縮死亡螺旋** —— 停止「觸發壓縮、失敗、再次壓縮」的惡性循環 ([#4750](https://github.com/NousResearch/hermes-agent/pull/4750), 關閉 [#2153](https://github.com/NousResearch/hermes-agent/issues/2153))
- **將壓縮後的上下文持久化至網關會話** ([#4095](https://github.com/NousResearch/hermes-agent/pull/4095))
- **「超出上下文」錯誤訊息**現在包含具體的引導說明 ([#4155](https://github.com/NousResearch/hermes-agent/pull/4155), 關閉 [#4061](https://github.com/NousResearch/hermes-agent/issues/4061))
- **從面向使用者的回應中移除孤立的思考/推理標籤** ([#4311](https://github.com/NousResearch/hermes-agent/pull/4311), 關閉 [#4285](https://github.com/NousResearch/hermes-agent/issues/4285))
- **強化 Codex 回應預檢**與串流錯誤處理 ([#4313](https://github.com/NousResearch/hermes-agent/pull/4313))
- **使用確定性的 call_id 回退**取代隨機 UUID，以維持提示詞快取一致性 ([#3991](https://github.com/NousResearch/hermes-agent/pull/3991))
- **防止壓縮後的上下文壓力警告垃圾訊息** ([#4012](https://github.com/NousResearch/hermes-agent/pull/4012))
- **軌跡壓縮器中延遲建立 AsyncOpenAI**，以避免事件迴圈關閉錯誤 ([#4013](https://github.com/NousResearch/hermes-agent/pull/4013))

### 記憶與會話
- **可插拔記憶供應商介面** —— 基於 ABC 的插件系統，支援具備個人檔案隔離的自訂記憶後端 ([#4623](https://github.com/NousResearch/hermes-agent/pull/4623))
- **Honcho 完整整合對齊**作為記憶供應商插件參考 ([#4355](https://github.com/NousResearch/hermes-agent/pull/4355)) —— @erosika
- **Honcho 感知個人檔案**的主機與對等解析 ([#4616](https://github.com/NousResearch/hermes-agent/pull/4616))
- **持久化記憶排乾狀態**，防止網關重啟時發生冗餘的重複排乾 ([#4481](https://github.com/NousResearch/hermes-agent/pull/4481))
- **記憶供應商工具**透過順序執行路徑路由 ([#4803](https://github.com/NousResearch/hermes-agent/pull/4803))
- **Honcho 配置**寫入至實例本地路徑，以實現個人檔案隔離 ([#4037](https://github.com/NousResearch/hermes-agent/pull/4037))
- **API 伺服器會話**持久化至共享的 SessionDB ([#4802](https://github.com/NousResearch/hermes-agent/pull/4802))
- **持久化非 CLI 會話的 Token 用量** ([#4627](https://github.com/NousResearch/hermes-agent/pull/4627))
- **在 FTS5 查詢中為帶點的詞彙加上引號** —— 修復搜尋包含點的詞彙時的問題 ([#4549](https://github.com/NousResearch/hermes-agent/pull/4549))

---

## 📱 通訊平台 (網關)

### 網關核心
- **修復競態條件** —— 一次強化週期解決了照片媒體遺失、流量控制、卡住的會話以及 STT 配置問題 ([#4727](https://github.com/NousResearch/hermes-agent/pull/4727))
- **透過執行代理防護進行核准路由** —— 當代理程式等待核准而被阻塞時，`/approve` 與 `/deny` 現在能正確路由，而非作為中斷被吞掉 ([#4798](https://github.com/NousResearch/hermes-agent/pull/4798), [#4557](https://github.com/NousResearch/hermes-agent/pull/4557), 關閉 [#4542](https://github.com/NousResearch/hermes-agent/issues/4542))
- **/approve 後恢復代理程式執行** —— 執行受阻指令時不再會遺失工具結果 ([#4418](https://github.com/NousResearch/hermes-agent/pull/4418))
- **私訊討論串會話預填父級逐字稿**以保留上下文 ([#4559](https://github.com/NousResearch/hermes-agent/pull/4559))
- **感知技能的斜線指令** —— 網關動態將安裝的技能註冊為斜線指令，具備分頁的 `/commands` 列表，且 Telegram 支援 100 個指令上限 ([#3934](https://github.com/NousResearch/hermes-agent/pull/3934), [#4005](https://github.com/NousResearch/hermes-agent/pull/4005), [#4006](https://github.com/NousResearch/hermes-agent/pull/4006), [#4010](https://github.com/NousResearch/hermes-agent/pull/4010), [#4023](https://github.com/NousResearch/hermes-agent/pull/4023))
- Telegram 選單與網關分發遵循**依平台禁用的技能** ([#4799](https://github.com/NousResearch/hermes-agent/pull/4799))
- **移除面向使用者的壓縮警告** —— 讓訊息流更簡潔 ([#4139](https://github.com/NousResearch/hermes-agent/pull/4139))
- 將 **`-v/-q` 旗標連結至網關服務的 stderr 日誌** ([#4474](https://github.com/NousResearch/hermes-agent/pull/4474))
- 系統服務單元中將 **HERMES_HOME 重新對應**至目標使用者 ([#4456](https://github.com/NousResearch/hermes-agent/pull/4456))
- 針對無效的類布林配置值**遵循預設值** ([#4029](https://github.com/NousResearch/hermes-agent/pull/4029))
- `/update` 指令使用 **setsid 取代 systemd-run**，以避免 systemd 權限問題 ([#4104](https://github.com/NousResearch/hermes-agent/pull/4104), 關閉 [#4017](https://github.com/NousResearch/hermes-agent/issues/4017))
- 第一條訊息顯示 **「正在初始化代理程式...」** 以提升 UX ([#4086](https://github.com/NousResearch/hermes-agent/pull/4086))
- **允許在 root 權限下執行網關服務**，適用於 LXC/容器環境 ([#4732](https://github.com/NousResearch/hermes-agent/pull/4732))

### Telegram
- **指令名稱限制為 32 字元**並具備防衝突機制 ([#4211](https://github.com/NousResearch/hermes-agent/pull/4211))
- 選單強制執行**優先級順序**：核心 > 插件 > 技能 ([#4023](https://github.com/NousResearch/hermes-agent/pull/4023))
- **限制為 50 個指令** —— API 會拒絕超過約 60 個指令的請求 ([#4006](https://github.com/NousResearch/hermes-agent/pull/4006))
- **跳過空/僅含空白的文字**，防止 400 錯誤 ([#4388](https://github.com/NousResearch/hermes-agent/pull/4388))
- 新增 **E2E 網關測試** ([#4497](https://github.com/NousResearch/hermes-agent/pull/4497)) —— @pefontana

### Discord
- **基於按鈕的核准介面** —— 將 `/approve` 與 `/deny` 註冊為具備互動按鈕提示的斜線指令 ([#4800](https://github.com/NousResearch/hermes-agent/pull/4800))
- **可配置的回應 (reactions)** —— 新增 `discord.reactions` 配置選項以禁用訊息處理時的反應 ([#4199](https://github.com/NousResearch/hermes-agent/pull/4199))
- 針對未授權使用者**跳過反應與自動討論串建立** ([#4387](https://github.com/NousResearch/hermes-agent/pull/4387))

### Slack
- **在討論串中回覆** —— 新增 `slack.reply_in_thread` 選項以在討論串中回覆訊息 ([#4643](https://github.com/NousResearch/hermes-agent/pull/4643), 關閉 [#2662](https://github.com/NousResearch/hermes-agent/issues/2662))

### WhatsApp
- **群組對話強制執行 require_mention** ([#4730](https://github.com/NousResearch/hermes-agent/pull/4730))

### Webhook
- **平台支援修復** —— 跳過家頻道提示，為 Webhook 適配器停用工具進度顯示 ([#4660](https://github.com/NousResearch/hermes-agent/pull/4660))

### Matrix
- **E2EE 解密強化** —— 請求缺失金鑰、自動信任裝置、重試緩衝事件 ([#4083](https://github.com/NousResearch/hermes-agent/pull/4083))

---

## 🖥️ CLI 與使用者體驗

### 新增斜線指令
- **`/yolo`** —— 為該會話切換危險指令核准開關 ([#3990](https://github.com/NousResearch/hermes-agent/pull/3990))
- **`/btw`** —— 發送臨時的旁支問題，不影響主對話上下文 ([#4161](https://github.com/NousResearch/hermes-agent/pull/4161))
- **`/profile`** —— 無需離開會話即可顯示活動中的個人檔案資訊 ([#4027](https://github.com/NousResearch/hermes-agent/pull/4027))

### 互動式 CLI
- 檔案寫入與修補操作在工具活動饋送中顯示**行內 Diff 預覽** ([#4411](https://github.com/NousResearch/hermes-agent/pull/4411), [#4423](https://github.com/NousResearch/hermes-agent/pull/4423))
- **TUI 啟動時置底** —— 解決回應區與輸入區之間出現大片空白的問題 ([#4412](https://github.com/NousResearch/hermes-agent/pull/4412), [#4359](https://github.com/NousResearch/hermes-agent/pull/4359), 關閉 [#4398](https://github.com/NousResearch/hermes-agent/issues/4398), [#4421](https://github.com/NousResearch/hermes-agent/issues/4421))
- **`/history` 與 `/resume`** 現在直接呈現最近的會話，無需搜尋 ([#4728](https://github.com/NousResearch/hermes-agent/pull/4728))
- **在 `/insights` 總覽中顯示快取 Token** 以確保總計正確 ([#4428](https://github.com/NousResearch/hermes-agent/pull/4428))
- 為 `hermes chat` 新增 **`--max-turns` 旗標**，限制代理程式迭代次數 ([#4314](https://github.com/NousResearch/hermes-agent/pull/4314))
- **偵測拖曳的檔案路徑**，不再誤認為斜線指令 ([#4533](https://github.com/NousResearch/hermes-agent/pull/4533)) —— @rolme
- **`config set` 允許空字串與假值** ([#4310](https://github.com/NousResearch/hermes-agent/pull/4310), 關閉 [#4277](https://github.com/NousResearch/hermes-agent/issues/4277))
- 配置 PulseAudio 橋接後支援 **WSL 中的語音模式** ([#4317](https://github.com/NousResearch/hermes-agent/pull/4317))
- 針對無障礙需求，**遵循 `NO_COLOR` 環境變數**與 `TERM=dumb` ([#4079](https://github.com/NousResearch/hermes-agent/pull/4079), 關閉 [#4066](https://github.com/NousResearch/hermes-agent/issues/4066)) —— @SHL0MS
- 為 macOS/zsh 使用者提供**正確的 Shell 重新載入指令** ([#4025](https://github.com/NousResearch/hermes-agent/pull/4025))
- 靜默模式下的查詢成功時**回傳零結束碼** ([#4613](https://github.com/NousResearch/hermes-agent/pull/4613), 關閉 [#4601](https://github.com/NousResearch/hermes-agent/issues/4601)) —— @devorun
- 在中斷結束時觸發 **on_session_end 鉤子** ([#4159](https://github.com/NousResearch/hermes-agent/pull/4159))
- **個人檔案列表顯示**能正確讀取 `model.default` 鍵 ([#4160](https://github.com/NousResearch/hermes-agent/pull/4160))
- 重配置選單中顯示**瀏覽器與 TTS** ([#4041](https://github.com/NousResearch/hermes-agent/pull/4041))
- 簡化**網頁後端優先級**偵測 ([#4036](https://github.com/NousResearch/hermes-agent/pull/4036))

### 安裝與配置
- 安裝期間**保留 allowed_users** 並靜默未配置供應商的警告 ([#4551](https://github.com/NousResearch/hermes-agent/pull/4551)) —— @kshitijk4poor
- 為自訂端點**將 API 金鑰儲存至模型配置** ([#4202](https://github.com/NousResearch/hermes-agent/pull/4202), 關閉 [#4182](https://github.com/NousResearch/hermes-agent/issues/4182))
- 安裝精靈觸發時，**Claude Code 憑證**受限於明確的 Hermes 配置 ([#4210](https://github.com/NousResearch/hermes-agent/pull/4210))
- **save_config_value 採用原子寫入**，防止中斷時配置遺失 ([#4298](https://github.com/NousResearch/hermes-agent/pull/4298), [#4320](https://github.com/NousResearch/hermes-agent/pull/4320))
- Token 刷新時將 **scopes 欄位寫入**至 Claude Code 憑證檔案 ([#4126](https://github.com/NousResearch/hermes-agent/pull/4126))

### 更新系統
- `hermes update` 支援 **Fork 偵測與上游同步** ([#4744](https://github.com/NousResearch/hermes-agent/pull/4744))
- 更新期間若其中一個組件失敗，**保留其餘正常的選用組件** ([#4550](https://github.com/NousResearch/hermes-agent/pull/4550))
- 處理 `hermes update` 期間的 **Git Index 衝突** ([#4735](https://github.com/NousResearch/hermes-agent/pull/4735))
- 避開 macOS 上的 **launchd 重啟競態** ([#4736](https://github.com/NousResearch/hermes-agent/pull/4736))
- 為 doctor 與 status 指令新增缺失的 **subprocess.run() 逾時** ([#4009](https://github.com/NousResearch/hermes-agent/pull/4009))

---

## 🔧 工具系統

### 瀏覽器
- **Camofox 反偵測瀏覽器後端** —— 支援本地隱身瀏覽，可透過 `hermes tools` 自動安裝 ([#4008](https://github.com/NousResearch/hermes-agent/pull/4008))
- **持久化 Camofox 會話**，具備視覺化除錯所需的 VNC URL 偵測 ([#4419](https://github.com/NousResearch/hermes-agent/pull/4419))
- **本地後端跳過 SSRF 檢查** (Camofox, 無頭 Chromium) ([#4292](https://github.com/NousResearch/hermes-agent/pull/4292))
- 透過 `browser.allow_private_urls` 提供**可配置的 SSRF 檢查** ([#4198](https://github.com/NousResearch/hermes-agent/pull/4198)) —— @nils010485
- Docker 指令中新增 **CAMOFOX_PORT=9377** ([#4340](https://github.com/NousResearch/hermes-agent/pull/4340))

### 檔案操作
- 寫入與修補動作支援**行內 Diff 預覽** ([#4411](https://github.com/NousResearch/hermes-agent/pull/4411), [#4423](https://github.com/NousResearch/hermes-agent/pull/4423))
- 寫入與修補支援**過時檔案偵測** —— 當檔案自上次讀取後在外部被修改時發出警告 ([#4345](https://github.com/NousResearch/hermes-agent/pull/4345))
- 寫入後**重置過時時間戳記** ([#4390](https://github.com/NousResearch/hermes-agent/pull/4390))
- `read_file` 加入**大小限制、去重與裝置阻擋** ([#4315](https://github.com/NousResearch/hermes-agent/pull/4315))

### MCP
- **穩定性修補包** —— 包含重新載入逾時、關機清理、事件迴圈處理、非阻塞 OAuth ([#4757](https://github.com/NousResearch/hermes-agent/pull/4757), 關閉 [#4462](https://github.com/NousResearch/hermes-agent/issues/4462), [#2537](https://github.com/NousResearch/hermes-agent/issues/2537))

### ACP (編輯器整合)
- **用戶端提供的 MCP 伺服器**註冊為代理工具 —— 編輯器現在能將其 MCP 伺服器傳遞給 Hermes ([#4705](https://github.com/NousResearch/hermes-agent/pull/4705))

### 技能系統
- **代理程式寫入大小限制**與**技能修補模糊匹配** —— 防止過大的技能寫入並提升編輯可靠性 ([#4414](https://github.com/NousResearch/hermes-agent/pull/4414))
- 安裝前**驗證中心套件路徑** —— 阻擋技能套件中的路徑遍歷 ([#3986](https://github.com/NousResearch/hermes-agent/pull/3986))
- 將 `hermes-agent` 與 `hermes-agent-setup` **整合為單一技能** ([#4332](https://github.com/NousResearch/hermes-agent/pull/4332))
- `extract_skill_conditions` 中加入**技能元資料類型檢查** ([#4479](https://github.com/NousResearch/hermes-agent/pull/4479))

### 新增/更新技能
- **research-paper-writing** —— 完整的端到端研究流程 (取代了 ml-paper-writing) ([#4654](https://github.com/NousResearch/hermes-agent/pull/4654)) —— @SHL0MS
- **ascii-video** —— 文字可讀性技術與外部佈局輔助 ([#4054](https://github.com/NousResearch/hermes-agent/pull/4054)) —— @SHL0MS
- **youtube-transcript** 更新以支援 youtube-transcript-api v1.x ([#4455](https://github.com/NousResearch/hermes-agent/pull/4455)) —— @el-analista
- 文檔網站新增**技能瀏覽與搜尋頁面** ([#4500](https://github.com/NousResearch/hermes-agent/pull/4500)) —— @IAvecilla

---

## 🔒 安全性與可靠性

### 安全性強化
- **阻擋機密資訊外洩**：掃描瀏覽器 URL 與 LLM 回應中的機密模式，防範透過 URL 編碼、Base64 與提示詞注入的外洩向量 ([#4483](https://github.com/NousResearch/hermes-agent/pull/4483))
- **遮蔽 execute_code 沙盒輸出中的機密** ([#4360](https://github.com/NousResearch/hermes-agent/pull/4360))
- **保護 `.docker`, `.azure`, `.config/gh` 憑證目錄**，禁止透過檔案工具與終端進行讀寫 ([#4305](https://github.com/NousResearch/hermes-agent/pull/4305), [#4327](https://github.com/NousResearch/hermes-agent/pull/4327)) —— @memosr
- 新增 **GitHub OAuth Token 模式**至遮蔽系統 + 快照遮蔽旗標 ([#4295](https://github.com/NousResearch/hermes-agent/pull/4295))
- Telegram DoH 回退功能中**拒絕私有與 Loopback IP** ([#4129](https://github.com/NousResearch/hermes-agent/pull/4129))
- 憑證檔案註冊時**拒絕路徑遍歷** ([#4316](https://github.com/NousResearch/hermes-agent/pull/4316))
- 個人檔案匯入時**驗證 Tar 壓縮包成員路徑** —— 阻擋 Zip-slip 攻擊 ([#4318](https://github.com/NousResearch/hermes-agent/pull/4318))
- 個人檔案匯出時**排除 auth.json 與 .env** ([#4475](https://github.com/NousResearch/hermes-agent/pull/4475))

### 可靠性
- **防止 API 斷線導致的壓縮死亡螺旋** ([#4750](https://github.com/NousResearch/hermes-agent/pull/4750), 關閉 [#2153](https://github.com/NousResearch/hermes-agent/issues/2153))
- 處理 OpenAI SDK 中的 **`is_closed` 方法** —— 防止誤判用戶端已關閉 ([#4416](https://github.com/NousResearch/hermes-agent/pull/4416), 關閉 [#4377](https://github.com/NousResearch/hermes-agent/issues/4377))
- **從 [all] 額外組件中排除 Matrix** —— 因 python-olm 上游損壞，防止安裝失敗 ([#4615](https://github.com/NousResearch/hermes-agent/pull/4615), 關閉 [#4178](https://github.com/NousResearch/hermes-agent/issues/4178))
- 修復 **OpenCode 模型路由** ([#4508](https://github.com/NousResearch/hermes-agent/pull/4508))
- 優化 **Docker 容器映像檔** ([#4034](https://github.com/NousResearch/hermes-agent/pull/4034)) —— @bcross

### Windows 與跨平台
- 配置 PulseAudio 橋接後支援 **WSL 中的語音模式** ([#4317](https://github.com/NousResearch/hermes-agent/pull/4317))
- **Homebrew 打包**準備工作 ([#4099](https://github.com/NousResearch/hermes-agent/pull/4099))
- 新增 **CI Fork 條件判斷**，防止 Fork 倉庫觸發工作流失敗 ([#4107](https://github.com/NousResearch/hermes-agent/pull/4107))

---

## 🐛 重大 Bug 修復

- **網關核准曾阻塞代理執行緒** —— 核准現在會像 CLI 一樣阻塞代理執行緒，防止工具結果遺失 ([#4557](https://github.com/NousResearch/hermes-agent/pull/4557), 關閉 [#4542](https://github.com/NousResearch/hermes-agent/issues/4542))
- **因 API 斷線導致的壓縮死亡螺旋** —— 現在能偵測並停止，而非無限循環 ([#4750](https://github.com/NousResearch/hermes-agent/pull/4750), 關閉 [#2153](https://github.com/NousResearch/hermes-agent/issues/2153))
- **跨工具回合遺失 Anthropic 思考塊** ([#4626](https://github.com/NousResearch/hermes-agent/pull/4626))
- 使用 `-p` 旗標時**忽略個人檔案模型配置** —— `model.model` 現在能正確提升為 `model.default` ([#4160](https://github.com/NousResearch/hermes-agent/pull/4160), 關閉 [#4486](https://github.com/NousResearch/hermes-agent/issues/4486))
- **CLI 回應區與輸入區之間的空白** ([#4412](https://github.com/NousResearch/hermes-agent/pull/4412), [#4359](https://github.com/NousResearch/hermes-agent/pull/4359), 關閉 [#4398](https://github.com/NousResearch/hermes-agent/issues/4398))
- **拖曳的檔案路徑**被誤認為斜線指令，而非檔案參考 ([#4533](https://github.com/NousResearch/hermes-agent/pull/4533)) —— @rolme
- **孤立的 `</think>` 標籤**洩漏至面向使用者的回應 ([#4311](https://github.com/NousResearch/hermes-agent/pull/4311), 關閉 [#4285](https://github.com/NousResearch/hermes-agent/issues/4285))
- **OpenAI SDK `is_closed` 是方法而非屬性** —— 修正了誤判用戶端關閉的問題 ([#4416](https://github.com/NousResearch/hermes-agent/pull/4416), 關閉 [#4377](https://github.com/NousResearch/hermes-agent/issues/4377))
- **MCP OAuth 伺服器**曾會阻塞 Hermes 啟動，而非優雅降級 ([#4757](https://github.com/NousResearch/hermes-agent/pull/4757), 關閉 [#4462](https://github.com/NousResearch/hermes-agent/issues/4462))
- 關閉具備 HTTP 伺服器的 MCP 時 **Event Loop 關閉錯誤** ([#4757](https://github.com/NousResearch/hermes-agent/pull/4757), 關閉 [#2537](https://github.com/NousResearch/hermes-agent/issues/2537))
- **阿里巴巴供應商**硬編碼至錯誤的端點 ([#4133](https://github.com/NousResearch/hermes-agent/pull/4133), 關閉 [#3912](https://github.com/NousResearch/hermes-agent/issues/3912))
- **Slack reply_in_thread** 缺失配置選項的問題 ([#4643](https://github.com/NousResearch/hermes-agent/pull/4643), 關閉 [#2662](https://github.com/NousResearch/hermes-agent/issues/2662))
- **靜默模式結束代碼** —— 成功的 `-q` 查詢不再回傳非零代碼 ([#4613](https://github.com/NousResearch/hermes-agent/pull/4613), 關閉 [#4601](https://github.com/NousResearch/hermes-agent/issues/4601))
- 文檔網站**行動版側邊欄**因 backdrop-filter 問題僅顯示關閉按鈕 ([#4207](https://github.com/NousResearch/hermes-agent/pull/4207)) —— @xsmyile
- 配置還原因過時分支合併而被撤銷的問題 —— `_config_version` 已修正 ([#4440](https://github.com/NousResearch/hermes-agent/pull/4440))

---

## 🧪 測試

- **Telegram 網關 E2E 測試** —— 為 Telegram 適配器提供完整的整合測試套件 ([#4497](https://github.com/NousResearch/hermes-agent/pull/4497)) —— @pefontana
- **修復 11 個實際測試失敗**並解決 sys.modules 串連污染問題 ([#4570](https://github.com/NousResearch/hermes-agent/pull/4570))
- **解決 7 個 CI 失敗**，涵蓋鉤子、插件與技能測試 ([#3936](https://github.com/NousResearch/hermes-agent/pull/3936))
- 更新 **Codex 401 刷新測試**以相容 CI 環境 ([#4166](https://github.com/NousResearch/hermes-agent/pull/4166))
- 修復過時的 **OPENAI_BASE_URL 測試** ([#4217](https://github.com/NousResearch/hermes-agent/pull/4217))

---

## 📚 文檔更新

- **全面文檔審核** —— 修復 21 個檔案中 9 個高優先級與 20 多個中優先級的缺口 ([#4087](https://github.com/NousResearch/hermes-agent/pull/4087))
- **網站導覽重構** —— 將功能與平台提升至頂層選單 ([#4116](https://github.com/NousResearch/hermes-agent/pull/4116))
- 為 API 伺服器與 Open WebUI 撰寫**工具進度串流**文檔 ([#4138](https://github.com/NousResearch/hermes-agent/pull/4138))
- **Telegram Webhook 模式**文檔 ([#4089](https://github.com/NousResearch/hermes-agent/pull/4089))
- **本地 LLM 供應商指南** —— 包含上下文長度警告的完整安裝指南 ([#4294](https://github.com/NousResearch/hermes-agent/pull/4294))
- 透過 `WHATSAPP_ALLOW_ALL_USERS` 文檔釐清 **WhatsApp 白名單行為** ([#4293](https://github.com/NousResearch/hermes-agent/pull/4293))
- **Slack 配置選項** —— Slack 文檔新增配置章節 ([#4644](https://github.com/NousResearch/hermes-agent/pull/4644))
- 擴充**終端後端章節** + 文檔建置修復 ([#4016](https://github.com/NousResearch/hermes-agent/pull/4016))
- **新增供應商指南**更新以符合統一安裝流程 ([#4201](https://github.com/NousResearch/hermes-agent/pull/4201))
- 修復 **ACP Zed 配置** ([#4743](https://github.com/NousResearch/hermes-agent/pull/4743))
- 新增常見工作流與疑難排解的**社群 FAQ** ([#4797](https://github.com/NousResearch/hermes-agent/pull/4797))
- 文檔網站新增**技能瀏覽與搜尋頁面** ([#4500](https://github.com/NousResearch/hermes-agent/pull/4500)) —— @IAvecilla

---

## 👥 貢獻者

### 核心團隊
- **@teknium1** —— 跨所有子系統共 135 個 commit

### 傑出社群貢獻者
- **@kshitijk4poor** —— 13 個 commit：安裝期間保留 allowed_users ([#4551](https://github.com/NousResearch/hermes-agent/pull/4551)) 及多項修復
- **@erosika** —— 12 個 commit：Honcho 整合對齊，作為記憶供應商插件 ([#4355](https://github.com/NousResearch/hermes-agent/pull/4355))
- **@pefontana** —— 9 個 commit：Telegram 網關 E2E 測試套件 ([#4497](https://github.com/NousResearch/hermes-agent/pull/4497))
- **@bcross** —— 5 個 commit：Docker 容器映像檔優化 ([#4034](https://github.com/NousResearch/hermes-agent/pull/4034))
- **@SHL0MS** —— 4 個 commit：支援 NO_COLOR/TERM=dumb ([#4079](https://github.com/NousResearch/hermes-agent/pull/4079))、ascii-video 技能更新 ([#4054](https://github.com/NousResearch/hermes-agent/pull/4054))、論文寫作技能 ([#4654](https://github.com/NousResearch/hermes-agent/pull/4654))

### 所有貢獻者
@0xbyt4, @arasovic, @Bartok9, @bcross, @binhnt92, @camden-lowrance, @curtitoo, @Dakota, @Dave Tist, @Dean Kerr, @devorun, @dieutx, @Dilee, @el-analista, @erosika, @Gutslabs, @IAvecilla, @Jack, @Johannnnn506, @kshitijk4poor, @Laura Batalha, @Leegenux, @Lume, @MacroAnarchy, @maymuneth, @memosr, @NexVeridian, @Nick, @nils010485, @pefontana, @Penov, @rolme, @SHL0MS, @txchen, @xsmyile

### 解決社群回報 Issue
@acsezen ([#2537](https://github.com/NousResearch/hermes-agent/issues/2537)), @arasovic ([#4285](https://github.com/NousResearch/hermes-agent/issues/4285)), @camden-lowrance ([#4462](https://github.com/NousResearch/hermes-agent/issues/4462)), @devorun ([#4601](https://github.com/NousResearch/hermes-agent/issues/4601)), @eloklam ([#4486](https://github.com/NousResearch/hermes-agent/issues/4486)), @HenkDz ([#3719](https://github.com/NousResearch/hermes-agent/issues/3719)), @hypotyposis ([#2153](https://github.com/NousResearch/hermes-agent/issues/2153)), @kazamak ([#4178](https://github.com/NousResearch/hermes-agent/issues/4178)), @lstep ([#4366](https://github.com/NousResearch/hermes-agent/issues/4366)), @Mark-Lok ([#4542](https://github.com/NousResearch/hermes-agent/issues/4542)), @NoJster ([#4421](https://github.com/NousResearch/hermes-agent/issues/4421)), @patp ([#2662](https://github.com/NousResearch/hermes-agent/issues/2662)), @pr0n ([#4601](https://github.com/NousResearch/hermes-agent/issues/4601)), @saulmc ([#4377](https://github.com/NousResearch/hermes-agent/issues/4377)), @SHL0MS ([#4060](https://github.com/NousResearch/hermes-agent/issues/4060), [#4061](https://github.com/NousResearch/hermes-agent/issues/4061), [#4066](https://github.com/NousResearch/hermes-agent/issues/4066), [#4172](https://github.com/NousResearch/hermes-agent/issues/4172), [#4277](https://github.com/NousResearch/hermes-agent/issues/4277)), @Z-Mackintosh ([#4398](https://github.com/NousResearch/hermes-agent/issues/4398))

---

**完整變更日誌**: [v2026.3.30...v2026.4.3](https://github.com/NousResearch/hermes-agent/compare/v2026.3.30...v2026.4.3)
