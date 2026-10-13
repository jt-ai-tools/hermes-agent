# Hermes Agent v0.5.0 (v2026.3.28)

**發佈日期：** 2026 年 3 月 28 日

> 「安全與強化」的版本 —— 新增 Hugging Face 供應商、重構 /model 指令、Telegram 私訊主題、原生 Modal SDK、插件生命週期鉤子、針對 GPT 模型的工具調用強制執行、Nix Flake 支援、50 多項安全性與可靠性修復，以及全面的供應鏈審核。

---

## ✨ 亮點更新

- **Nous Portal 現已支援 400 多種模型** —— Nous Research 的推論門戶已大幅擴展，讓 Hermes Agent 使用者只需透過單一供應商端點即可存取超過 400 種模型。

- **Hugging Face 作為一等公民推論供應商** —— 完整整合 HF 推論 API，包含對應 OpenRouter 代理型模型的精選模型選擇器、即時 `/models` 端點探測以及安裝精靈流程。([#3419](https://github.com/NousResearch/hermes-agent/pull/3419), [#3440](https://github.com/NousResearch/hermes-agent/pull/3440))

- **Telegram 私訊主題 (Private Chat Topics)** —— 支援以專案為基礎的對話，並可為每個主題綁定特定技能，實現在單一 Telegram 聊天室中執行多個隔離的工作流。([#3163](https://github.com/NousResearch/hermes-agent/pull/3163))

- **原生 Modal SDK 後端** —— 以原生 Modal SDK (`Sandbox.create.aio` + `exec.aio`) 取代 swe-rex 依賴，消除了隧道並簡化了 Modal 終端後端。([#3538](https://github.com/NousResearch/hermes-agent/pull/3538))

- **插件生命週期鉤子啟動** —— `pre_llm_call`, `post_llm_call`, `on_session_start` 與 `on_session_end` 鉤子現在已可在代理迴圈及 CLI/網關中觸發，完善了插件鉤子系統。([#3542](https://github.com/NousResearch/hermes-agent/pull/3542))

- **改進 OpenAI 模型可靠性** —— 新增 `GPT_TOOL_USE_GUIDANCE` 以防止 GPT 模型僅描述意圖而不執行工具調用，並能自動從對話歷史中剔除過時的預算警告 (該警告曾導致模型在不同回合間規避使用工具)。([#3528](https://github.com/NousResearch/hermes-agent/pull/3528))

- **Nix Flake 支援** —— 完整的 uv2nix 建置、具備持久化容器模式的 NixOS 模組、從 Python 源碼自動生成的配置鍵，以及對代理友好的後綴 PATH。([#20](https://github.com/NousResearch/hermes-agent/pull/20), [#3274](https://github.com/NousResearch/hermes-agent/pull/3274), [#3061](https://github.com/NousResearch/hermes-agent/pull/3061)) 由 @alt-glitch 貢獻。

- **供應鏈強化** —— 移除了受損的 `litellm` 依賴、鎖定了所有依賴版本範圍、使用雜湊值重新生成了 `uv.lock`、新增了用於掃描 PR 供應鏈攻擊模式的 CI 工作流，並更新了相關依賴以修復 CVE 漏洞。([#2796](https://github.com/NousResearch/hermes-agent/pull/2796), [#2810](https://github.com/NousResearch/hermes-agent/pull/2810), [#2812](https://github.com/NousResearch/hermes-agent/pull/2812), [#2816](https://github.com/NousResearch/hermes-agent/pull/2816), [#3073](https://github.com/NousResearch/hermes-agent/pull/3073))

- **Anthropic 輸出限制修復** —— 以每種模型的原生輸出限制 (Opus 4.6 為 128K, Sonnet 4.6 為 64K) 取代了硬編碼的 16K `max_tokens`，修復了直接使用 Anthropic API 時的「回應截斷 (Response truncated)」與思考預算耗盡問題。([#3426](https://github.com/NousResearch/hermes-agent/pull/3426), [#3444](https://github.com/NousResearch/hermes-agent/pull/3444))

---

## 🏗️ 核心代理與架構

### 新供應商：Hugging Face
- 一等公民級別的 Hugging Face 推論 API 整合，具備認證、安裝精靈與模型選擇器功能 ([#3419](https://github.com/NousResearch/hermes-agent/pull/3419))
- 精選模型列表將 OpenRouter 代理預設模型對應至 HF 等效模型 —— 擁有 8 個以上精選模型的供應商會跳過即時 `/models` 探測以提升速度 ([#3440](https://github.com/NousResearch/hermes-agent/pull/3440))
- Z.AI 供應商模型列表新增 glm-5-turbo ([#3095](https://github.com/NousResearch/hermes-agent/pull/3095))

### 供應商與模型改進
- 重構 `/model` 指令 —— 為 CLI 與網關提取了共用的 `switch_model()` 流程、支援自訂端點、感知供應商的路由機制 ([#2795](https://github.com/NousResearch/hermes-agent/pull/2795), [#2799](https://github.com/NousResearch/hermes-agent/pull/2799))
- 移除 CLI 與網關中的 `/model` 斜線指令，改用 `hermes model` 子指令 ([#3080](https://github.com/NousResearch/hermes-agent/pull/3080))
- 保留 `custom` 供應商名稱，不再靜默重對應至 `openrouter` ([#2792](https://github.com/NousResearch/hermes-agent/pull/2792))
- 支援從 config.yaml 讀取根級別的 `provider` 與 `base_url` 至模型配置中 ([#3112](https://github.com/NousResearch/hermes-agent/pull/3112))
- 將 Nous Portal 模型標籤 (slugs) 與 OpenRouter 命名對齊 ([#3253](https://github.com/NousResearch/hermes-agent/pull/3253))
- 修復阿里巴巴供應商的預設端點與模型列表 ([#3484](https://github.com/NousResearch/hermes-agent/pull/3484))
- 允許 MiniMax 使用者覆蓋 `/v1` → `/anthropic` 的自動校正 ([#3553](https://github.com/NousResearch/hermes-agent/pull/3553))
- 將 OAuth 權杖刷新遷移至 `platform.claude.com` 並具備回退機制 ([#3246](https://github.com/NousResearch/hermes-agent/pull/3246))

### 代理迴圈與對話
- **改進 OpenAI 模型可靠性** —— `GPT_TOOL_USE_GUIDANCE` 可防止 GPT 模型描述動作而非執行工具，且能自動從歷史中剔除預算警告 ([#3528](https://github.com/NousResearch/hermes-agent/pull/3528))
- **呈現生命週期事件** —— 所有重試、回退與壓縮事件現在皆會作為格式化訊息呈現給使用者 ([#3153](https://github.com/NousResearch/hermes-agent/pull/3153))
- **Anthropic 輸出限制** —— 改用每種模型的原生輸出限制，而非硬編碼的 16K `max_tokens` ([#3426](https://github.com/NousResearch/hermes-agent/pull/3426))
- **思考預算耗盡偵測** —— 當模型將所有輸出 Token 用於推理時，跳過無效的續寫重試 ([#3444](https://github.com/NousResearch/hermes-agent/pull/3444))
- API 呼叫一律優先使用串流，以防止子代理掛起 ([#3120](https://github.com/NousResearch/hermes-agent/pull/3120))
- 串流失敗後恢復安全的非串流回退 ([#3020](https://github.com/NousResearch/hermes-agent/pull/3020))
- 給予子代理獨立的迭代預算 ([#3004](https://github.com/NousResearch/hermes-agent/pull/3004))
- 在 `_try_activate_fallback` 中更新 `api_key` 以用於子代理認證 ([#3103](https://github.com/NousResearch/hermes-agent/pull/3103))
- 達到最大重試次數時優雅返回，而非導致執行緒崩潰 ([untagged commit](https://github.com/NousResearch/hermes-agent))
- 將壓縮重啟次數計入重試限制 ([#3070](https://github.com/NousResearch/hermes-agent/pull/3070))
- 在預檢估計中包含工具 Token，並保護上下文探測的持久性 ([#3164](https://github.com/NousResearch/hermes-agent/pull/3164))
- 回退激活後更新上下文壓縮限制 ([#3305](https://github.com/NousResearch/hermes-agent/pull/3305))
- 驗證空的使用者訊息，防止 Anthropic API 400 錯誤 ([#3322](https://github.com/NousResearch/hermes-agent/pull/3322))
- GLM 僅推理回應與最大長度處理 ([#3010](https://github.com/NousResearch/hermes-agent/pull/3010))
- 針對思考緩慢的模型，將預設 API 逾時從 900s 增加至 1800s ([#3431](https://github.com/NousResearch/hermes-agent/pull/3431))
- 針對 Claude/OpenRouter 傳送 `max_tokens` + 對 SSE 連線錯誤進行重試 ([#3497](https://github.com/NousResearch/hermes-agent/pull/3497))
- 防止網關模式下的 AsyncOpenAI/httpx 跨迴圈死鎖 ([#2701](https://github.com/NousResearch/hermes-agent/pull/2701)) 由 @ctlst 貢獻

### 串流與推理
- **跨網關會話回合持久化推理內容**，新增 v6 Schema 欄位 (`reasoning`, `reasoning_details`, `codex_reasoning_items`) ([#2974](https://github.com/NousResearch/hermes-agent/pull/2974))
- 偵測並終止過時的 SSE 連線 ([untagged commit](https://github.com/NousResearch/hermes-agent))
- 修復導致假性 `RemoteProtocolError` 的過時串流偵測器競態問題 ([untagged commit](https://github.com/NousResearch/hermes-agent))
- 串流期間跳過 `<think>` 擷取推理內容的重複回呼 ([#3116](https://github.com/NousResearch/hermes-agent/pull/3116))
- 在 `rewrite_transcript` 中保留推理欄位 ([#3311](https://github.com/NousResearch/hermes-agent/pull/3311))
- 在串流工具調用中保留 Gemini 思考簽章 ([#2997](https://github.com/NousResearch/hermes-agent/pull/2997))
- 確保在推理更新期間觸發第一個增量數據 (delta) ([untagged commit](https://github.com/NousResearch/hermes-agent))

### 會話與記憶
- **會話搜尋最近會話模式** —— 省略查詢詞即可瀏覽具備標題、預覽與時間戳記的最近會話 ([#2533](https://github.com/NousResearch/hermes-agent/pull/2533))
- 在 `/new`, `/reset` 與自動重置時呈現會話配置 ([#3321](https://github.com/NousResearch/hermes-agent/pull/3321))
- **第三方會話隔離** —— 新增 `--source` 旗標以依來源隔離會話 ([#3255](https://github.com/NousResearch/hermes-agent/pull/3255))
- 新增 `/resume` CLI 處理程序、會話日誌截斷保護、`reopen_session` API ([#3315](https://github.com/NousResearch/hermes-agent/pull/3315))
- 在 `/clear` 與 `/new` 時清除壓縮器摘要與回合計數器 ([#3102](https://github.com/NousResearch/hermes-agent/pull/3102))
- 呈現導致會話資料遺失的靜默 SessionDB 失敗 ([#2999](https://github.com/NousResearch/hermes-agent/pull/2999))
- 摘要失敗時提供會話搜尋的回退預覽 ([#3478](https://github.com/NousResearch/hermes-agent/pull/3478))
- 防止排乾代理程式 (flush agent) 覆蓋過時的記憶 ([#2687](https://github.com/NousResearch/hermes-agent/pull/2687))

### 上下文壓縮
- 以基於比例的縮放取代已停用的 `summary_target_tokens` ([#2554](https://github.com/NousResearch/hermes-agent/pull/2554))
- 在 `DEFAULT_CONFIG` 中公開 `compression.target_ratio`, `protect_last_n` 與 `threshold` 選項 ([untagged commit](https://github.com/NousResearch/hermes-agent))
- 恢復合理的預設值，並將摘要上限設為 12K Token ([untagged commit](https://github.com/NousResearch/hermes-agent))
- 在 `/compress` 與衛生壓縮期間保留逐字稿內容 ([#3556](https://github.com/NousResearch/hermes-agent/pull/3556))
- 壓縮後更新上下文壓力警告與 Token 預估 ([untagged commit](https://github.com/NousResearch/hermes-agent))

### 架構與依賴
- **移除 mini-swe-agent 依賴** —— 直接內建 Docker 與 Modal 後端 ([#2804](https://github.com/NousResearch/hermes-agent/pull/2804))
- **針對 Modal 後端改用原生 Modal SDK 取代 swe-rex** ([#3538](https://github.com/NousResearch/hermes-agent/pull/3538))
- **插件生命週期鉤子** —— `pre_llm_call`, `post_llm_call`, `on_session_start`, `on_session_end` 現在已可在代理迴圈中觸發 ([#3542](https://github.com/NousResearch/hermes-agent/pull/3542))
- 修復插件工具集在 `hermes tools` 與獨立進程中不可見的問題 ([#3457](https://github.com/NousResearch/hermes-agent/pull/3457))
- 整合 `get_hermes_home()` 與 `parse_reasoning_effort()` ([#3062](https://github.com/NousResearch/hermes-agent/pull/3062))
- 移除未使用的 Hermes 原生 PKCE OAuth 流程 ([#3107](https://github.com/NousResearch/hermes-agent/pull/3107))
- 移除 55 個檔案中約 100 處未使用的匯入 ([#3016](https://github.com/NousResearch/hermes-agent/pull/3016))
- 修復 154 處 f-strings、簡化 getattr/URL 模式、移除無效程式碼 ([#3119](https://github.com/NousResearch/hermes-agent/pull/3119))

---

## 📱 通訊平台 (網關)

### Telegram
- **私訊主題 (Private Chat Topics)** —— 支援以專案為基礎的對話，並可為每個主題綁定特定技能，實現在單一 Telegram 聊天室中執行隔離的工作流 ([#3163](https://github.com/NousResearch/hermes-agent/pull/3163))
- **當 api.telegram.org 無法連線時，透過 DNS-over-HTTPS 自動搜尋回退 IP** ([#3376](https://github.com/NousResearch/hermes-agent/pull/3376))
- **可配置的回覆討論串模式** ([#2907](https://github.com/NousResearch/hermes-agent/pull/2907))
- 遇到「找不到訊息討論串 (Message thread not found)」BadRequest 時，回退至無 `thread_id` 狀態 ([#3390](https://github.com/NousResearch/hermes-agent/pull/3390))
- 當 `start_polling` 在 502 錯誤後失敗時，自行重新排程連線 ([#3268](https://github.com/NousResearch/hermes-agent/pull/3268))

### Discord
- 代理回合完成後停止幽靈輸入指示器 ([#3003](https://github.com/NousResearch/hermes-agent/pull/3003))

### Slack
- 將工具調用進度訊息傳送至正確的 Slack 討論串 ([#3063](https://github.com/NousResearch/hermes-agent/pull/3063))
- 將進度討論串回退範圍限制在 Slack ([#3488](https://github.com/NousResearch/hermes-agent/pull/3488))

### WhatsApp
- 下載訊息中的文件、音訊與影片媒體 ([#2978](https://github.com/NousResearch/hermes-agent/pull/2978))

### Matrix
- `PLATFORMS` 字典中補上缺失的 Matrix 條目 ([#3473](https://github.com/NousResearch/hermes-agent/pull/3473))
- 強化 E2EE 存取權杖處理 ([#3562](https://github.com/NousResearch/hermes-agent/pull/3562))
- 為同步迴圈中的 `SyncError` 新增退避機制 ([#3280](https://github.com/NousResearch/hermes-agent/pull/3280))

### Signal
- 將 SSE 保活 (keepalive) 註釋視為連線活動進行追蹤 ([#3316](https://github.com/NousResearch/hermes-agent/pull/3316))

### 電子郵件 (Email)
- 防止 EmailAdapter 中 `_seen_uids` 的無限制增長 ([#3490](https://github.com/NousResearch/hermes-agent/pull/3490))

### 網關核心
- **為通訊平台提供配置受控的 `/verbose` 指令** —— 可從聊天中切換工具輸出詳細程度 ([#3262](https://github.com/NousResearch/hermes-agent/pull/3262))
- **背景審查通知** 遞送至使用者聊天 ([#3293](https://github.com/NousResearch/hermes-agent/pull/3293))
- **針對短暫的發送失敗進行重試**，並在次數耗盡時通知使用者 ([#3288](https://github.com/NousResearch/hermes-agent/pull/3288))
- 從掛起的代理程式中恢復 —— `/stop` 現在會強制終止會話鎖 ([#3104](https://github.com/NousResearch/hermes-agent/pull/3104))
- 執行緒安全的 `SessionStore` —— 使用 `threading.Lock` 保護 `_entries` ([#3052](https://github.com/NousResearch/hermes-agent/pull/3052))
- 修復快取代理導致的網關 Token 重複計數 —— 改用絕對設定而非累加 ([#3306](https://github.com/NousResearch/hermes-agent/pull/3306), [#3317](https://github.com/NousResearch/hermes-agent/pull/3317))
- 在代理快取簽章中對完整的認證權杖進行指紋識別 ([#3247](https://github.com/NousResearch/hermes-agent/pull/3247))
- 靜默背景代理程式的終端輸出 ([#3297](https://github.com/NousResearch/hermes-agent/pull/3297))
- 啟動允許清單檢查中包含各平台的 `ALLOW_ALL` 與 `SIGNAL_GROUP` ([#3313](https://github.com/NousResearch/hermes-agent/pull/3313))
- systemd 單元 PATH 中包含使用者本地 bin 路徑 ([#3527](https://github.com/NousResearch/hermes-agent/pull/3527))
- 在 `GatewayRunner` 中追蹤背景任務參考 ([#3254](https://github.com/NousResearch/hermes-agent/pull/3254))
- 為 HA, Email, Mattermost, SMS 適配器新增請求逾時 ([#3258](https://github.com/NousResearch/hermes-agent/pull/3258))
- 為 Mattermost, Slack 與基礎快取新增媒體下載重試功能 ([#3323](https://github.com/NousResearch/hermes-agent/pull/3323))
- 自動偵測虛擬環境路徑，而非硬編碼 `venv/` ([#2797](https://github.com/NousResearch/hermes-agent/pull/2797))
- 使用 `TERMINAL_CWD` 進行上下文檔案搜尋，而非進程當前目錄 ([untagged commit](https://github.com/NousResearch/hermes-agent))
- 停止將 hermes 倉庫的 AGENTS.md 載入網關會話 (節省約 10k Token) ([#2891](https://github.com/NousResearch/hermes-agent/pull/2891))

---

## 🖥️ CLI 與使用者體驗

### 互動式 CLI
- **可配置的忙碌輸入模式** + 修復 `/queue` 始終啟用的問題 ([#3298](https://github.com/NousResearch/hermes-agent/pull/3298))
- **多行貼上時保留使用者輸入內容** ([#3065](https://github.com/NousResearch/hermes-agent/pull/3065))
- **工具生成回呼** —— 在工具參數生成期間顯示串流化的「正在準備終端…」更新 ([untagged commit](https://github.com/NousResearch/hermes-agent))
- 為實質性工具顯示工具進度，而不僅僅是「準備中」 ([untagged commit](https://github.com/NousResearch/hermes-agent))
- 推理預覽區塊緩衝處理並修復重複顯示問題 ([#3013](https://github.com/NousResearch/hermes-agent/pull/3013))
- 防止推理框在工具調用迴圈中重複渲染 3 次 ([#3405](https://github.com/NousResearch/hermes-agent/pull/3405))
- 消除閒置時的 "Event loop is closed" / "按 ENTER 鍵繼續" —— 透過 `neuter_async_httpx_del()`、自訂異常處理程序與過時用戶端清理進行三層修復 ([#3398](https://github.com/NousResearch/hermes-agent/pull/3398))
- 修復狀態列對帶有尾隨零的 Token 計數顯示錯誤 (例如將 260K 顯示為 26K) ([#3024](https://github.com/NousResearch/hermes-agent/pull/3024))
- 修復長時間對話中狀態列重複出現且效能下降的問題 ([#3291](https://github.com/NousResearch/hermes-agent/pull/3291))
- 背景任務輸出前刷新 TUI，以防止與狀態列重疊 ([#3048](https://github.com/NousResearch/hermes-agent/pull/3048))
- 抑制 `patch_stdout` 下的 KawaiiSpinner 動畫 ([#2994](https://github.com/NousResearch/hermes-agent/pull/2994))
- 當 TUI 處理工具進度時跳過 KawaiiSpinner ([#2973](https://github.com/NousResearch/hermes-agent/pull/2973))
- 透過 `_is_tty` 屬性保護 `isatty()` 防止對已關閉串流的操作 ([#3056](https://github.com/NousResearch/hermes-agent/pull/3056))
- 確保工具生成期間串流框僅關閉一次 ([untagged commit](https://github.com/NousResearch/hermes-agent))
- 顯示內容中的上下文壓力百分比上限設為 100% ([#3480](https://github.com/NousResearch/hermes-agent/pull/3480))
- 清理 CLI 顯示中的 HTML 錯誤訊息 ([#3069](https://github.com/NousResearch/hermes-agent/pull/3069))
- 在 API 錯誤輸出中顯示 HTTP 狀態碼與 400 錯誤內容 ([#3096](https://github.com/NousResearch/hermes-agent/pull/3096))
- 從 HTML 錯誤頁面擷取實用資訊，並在達到最大重試次數時傾印除錯資訊 ([untagged commit](https://github.com/NousResearch/hermes-agent))
- 防止啟動時當 `base_url` 為 None 時發生的 TypeError ([#3068](https://github.com/NousResearch/hermes-agent/pull/3068))
- 防止非 TTY 環境下的更新崩潰 ([#3094](https://github.com/NousResearch/hermes-agent/pull/3094))
- 處理會話刪除/修剪確認提示中的 EOFError ([#3101](https://github.com/NousResearch/hermes-agent/pull/3101))
- 捕捉退出時 `flush_memories` 期間與退出清理處理程序中的 KeyboardInterrupt ([#3025](https://github.com/NousResearch/hermes-agent/pull/3025), [#3257](https://github.com/NousResearch/hermes-agent/pull/3257))
- 保護 `.strip()` 防止對 YAML 配置中的 None 值進行操作 ([#3552](https://github.com/NousResearch/hermes-agent/pull/3552))
- 保護 `config.get()` 防止 YAML null 值導致的 AttributeError ([#3377](https://github.com/NousResearch/hermes-agent/pull/3377))
- 儲存 asyncio 任務參考以防止執行中途被垃圾回收 ([#3267](https://github.com/NousResearch/hermes-agent/pull/3267))

### 安裝與配置
- 回訪使用者選單分發改用明確的按鍵映射，而非位置索引 ([#3083](https://github.com/NousResearch/hermes-agent/pull/3083))
- 更新指令中 pip 改用 `sys.executable` 以修復 PEP 668 問題 ([#3099](https://github.com/NousResearch/hermes-agent/pull/3099))
- 強化 `hermes update` 應對分歧歷史、非 main 分支與網關邊緣案例的能力 ([#3492](https://github.com/NousResearch/hermes-agent/pull/3492))
- 修復 OpenClaw 遷移覆蓋預設值以及安裝精靈跳過已匯入章節的問題 ([#3282](https://github.com/NousResearch/hermes-agent/pull/3282))
- 停止遞迴搜尋 AGENTS.md，僅載入頂層檔案 ([#3110](https://github.com/NousResearch/hermes-agent/pull/3110))
- 在瀏覽器與終端 PATH 解析中加入 macOS Homebrew 路徑 ([#2713](https://github.com/NousResearch/hermes-agent/pull/2713))
- `tool_progress` 配置支援 YAML 布林值處理 ([#3300](https://github.com/NousResearch/hermes-agent/pull/3300))
- 將預設 SOUL.md 重置為基準身分文字 ([#3159](https://github.com/NousResearch/hermes-agent/pull/3159))
- 容器終端後端拒絕相對路徑的當前工作目錄 (cwd) ([untagged commit](https://github.com/NousResearch/hermes-agent))
- 為 API 伺服器平台新增明確的 `hermes-api-server` 工具集 ([#3304](https://github.com/NousResearch/hermes-agent/pull/3304))
- 重新調整安裝精靈中的供應商順序 —— OpenRouter 優先 ([untagged commit](https://github.com/NousResearch/hermes-agent))

---

## 🔧 工具系統

### API 伺服器
- **支援 Idempotency-Key**、內文大小限制與 OpenAI 錯誤封裝 ([#2903](https://github.com/NousResearch/hermes-agent/pull/2903))
- CORS 標頭中允許使用 Idempotency-Key ([#3530](https://github.com/NousResearch/hermes-agent/pull/3530))
- SSE 斷線時取消孤立的代理程式並執行真正的中斷 ([#3427](https://github.com/NousResearch/hermes-agent/pull/3427))
- 修復代理程式執行工具調用時串流中斷的問題 ([#2985](https://github.com/NousResearch/hermes-agent/pull/2985))

### 終端與檔案操作
- 處理 V4A 修補解析器中僅包含新增內容的數據塊 (hunks) ([#3325](https://github.com/NousResearch/hermes-agent/pull/3325))
- 持久化 Shell 輪詢採用指數退避機制 ([#2996](https://github.com/NousResearch/hermes-agent/pull/2996))
- `context_references` 中的子進程呼叫新增逾時設定 ([#3469](https://github.com/NousResearch/hermes-agent/pull/3469))

### 瀏覽器與視覺
- 處理視覺工具中的 402 餘額不足錯誤 ([#2802](https://github.com/NousResearch/hermes-agent/pull/2802))
- 修復 `browser_vision` 忽略 `auxiliary.vision.timeout` 配置的問題 ([#2901](https://github.com/NousResearch/hermes-agent/pull/2901))
- 支援透過 config.yaml 配置瀏覽器指令逾時 ([#2801](https://github.com/NousResearch/hermes-agent/pull/2801))

### MCP
- 運行時與配置的 MCP 工具集解析 ([#3252](https://github.com/NousResearch/hermes-agent/pull/3252))
- 新增 MCP 工具名稱衝突保護 ([#3077](https://github.com/NousResearch/hermes-agent/pull/3077))

### 輔助 LLM
- 針對內容為 None 的輔助 LLM 呼叫提供保護 + 推理回退 + 重試 ([#3449](https://github.com/NousResearch/hermes-agent/pull/3449))
- 視覺自動偵測中捕捉 `build_anthropic_client` 導致的 ImportError ([#3312](https://github.com/NousResearch/hermes-agent/pull/3312))

### 其他工具
- 為 `send_message_tool` HTTP 呼叫新增請求逾時 ([#3162](https://github.com/NousResearch/hermes-agent/pull/3162)) 由 @memosr 貢獻
- 自動修復包含無效控制字元的 `jobs.json` ([#3537](https://github.com/NousResearch/hermes-agent/pull/3537))
- 為 Claude/OpenRouter 啟用細粒度的工具串流 ([#3497](https://github.com/NousResearch/hermes-agent/pull/3497))

---

## 🧩 技能生態系統

### 技能系統
- 為技能與使用者配置提供**環境變數透傳** —— 技能可以宣告要透傳的環境變數 ([#2807](https://github.com/NousResearch/hermes-agent/pull/2807))
- 透過共享的 `skill_utils` 模組快取技能提示詞，提升首字產出時間 (TTFT) ([#3421](https://github.com/NousResearch/hermes-agent/pull/3421))
- 避免為技能條件重複讀取檔案 ([#2992](https://github.com/NousResearch/hermes-agent/pull/2992))
- 使用 Git Trees API 防止安裝期間靜默遺失子目錄 ([#2995](https://github.com/NousResearch/hermes-agent/pull/2995))
- 修復深層嵌套倉庫結構下的 skills-sh 安裝問題 ([#2980](https://github.com/NousResearch/hermes-agent/pull/2980))
- 處理技能 Frontmatter 中的 null 元資料 ([untagged commit](https://github.com/NousResearch/hermes-agent))
- 保留對 skills-sh 識別碼的信任 + 減少解析過程中的變動 ([#3251](https://github.com/NousResearch/hermes-agent/pull/3251))
- 修正代理建立的技能被錯誤視為不可信社群內容的問題 ([untagged commit](https://github.com/NousResearch/hermes-agent))

### 新技能
- **G0DM0D3 godmode 越獄技能** + 文件 ([#3157](https://github.com/NousResearch/hermes-agent/pull/3157))
- 選用技能中新增 **Docker 管理技能** ([#3060](https://github.com/NousResearch/hermes-agent/pull/3060))
- **OpenClaw 遷移 v2** —— 包含 17 個新模組與從 OpenClaw 遷移至 Hermes 的終端總結 ([#2906](https://github.com/NousResearch/hermes-agent/pull/2906))

---

## 🔒 安全性與可靠性

### 安全性強化
- `browser_navigate` 新增 **SSRF 防護** ([#3058](https://github.com/NousResearch/hermes-agent/pull/3058))
- `vision_tools` 與 `web_tools` 新增 **SSRF 防護** (已強化) ([#2679](https://github.com/NousResearch/hermes-agent/pull/2679))
- **限制子代理工具集**僅能使用父代理啟用的集合 ([#3269](https://github.com/NousResearch/hermes-agent/pull/3269))
- **防止自我更新中的 Zip-slip 路徑遍歷** ([#3250](https://github.com/NousResearch/hermes-agent/pull/3250))
- **防止 `_expand_path` 中透過 `~user` 路徑後綴進行的 Shell 注入** ([#2685](https://github.com/NousResearch/hermes-agent/pull/2685))
- 在危險指令偵測前進行**輸入正規化** ([#3260](https://github.com/NousResearch/hermes-agent/pull/3260))
- 將 Tirith 阻擋判定改為可核准，而非硬性阻擋 ([#3428](https://github.com/NousResearch/hermes-agent/pull/3428))
- 從依賴中移除受損的 `litellm`/`typer`/`platformdirs` ([#2796](https://github.com/NousResearch/hermes-agent/pull/2796))
- 鎖定所有依賴的版本範圍 ([#2810](https://github.com/NousResearch/hermes-agent/pull/2810))
- 重新生成帶有雜湊值的 `uv.lock`，並在安裝中使用鎖定檔案 ([#2812](https://github.com/NousResearch/hermes-agent/pull/2812))
- 更新依賴以修復 CVE 並重新生成 `uv.lock` ([#3073](https://github.com/NousResearch/hermes-agent/pull/3073))
- 建立用於 PR 掃描的供應鏈審核 CI 工作流 ([#2816](https://github.com/NousResearch/hermes-agent/pull/2816))

### 可靠性
- 修復導致 TUI 凍結 15-20 秒的 **SQLite WAL 寫入鎖競爭** 問題 ([#3385](https://github.com/NousResearch/hermes-agent/pull/3385))
- **SQLite 並行強化** + 確保會話逐字稿完整性 ([#3249](https://github.com/NousResearch/hermes-agent/pull/3249))
- 防止網關崩潰/重啟迴圈時重複觸發 Cron 任務 ([#3396](https://github.com/NousResearch/hermes-agent/pull/3396))
- 任務完成後將 Cron 會話標記為結束 ([#2998](https://github.com/NousResearch/hermes-agent/pull/2998))

---

## ⚡ 效能優化

- **首字產出時間 (TTFT) 啟動優化** —— 整合了多項顯而易見的啟動改進 ([#3395](https://github.com/NousResearch/hermes-agent/pull/3395))
- 透過共享的 `skill_utils` 模組快取技能提示詞 ([#3421](https://github.com/NousResearch/hermes-agent/pull/3421))
- 避免在提示詞構建器中為技能條件重複讀取檔案 ([#2992](https://github.com/NousResearch/hermes-agent/pull/2992))

---

## 🐛 重大 Bug 修復

- 修復快取代理導致的網關 Token 重複計數問題 ([#3306](https://github.com/NousResearch/hermes-agent/pull/3306), [#3317](https://github.com/NousResearch/hermes-agent/pull/3317))
- 修復閒置會話期間的 "Event loop is closed" / "按 ENTER 鍵繼續" 錯誤 ([#3398](https://github.com/NousResearch/hermes-agent/pull/3398))
- 修復工具調用迴圈中推理框渲染 3 次的問題 ([#3405](https://github.com/NousResearch/hermes-agent/pull/3405))
- 修復狀態列將 260K Token 計數錯誤顯示為 26K 的問題 ([#3024](https://github.com/NousResearch/hermes-agent/pull/3024))
- 修復 `/queue` 無視配置始終啟用的問題 ([#3298](https://github.com/NousResearch/hermes-agent/pull/3298))
- 修復代理回合結束後仍殘留 Discord 輸入指示器的問題 ([#3003](https://github.com/NousResearch/hermes-agent/pull/3003))
- 修復 Slack 進度訊息出現在錯誤討論串的問題 ([#3063](https://github.com/NousResearch/hermes-agent/pull/3063))
- 修復 WhatsApp 媒體下載 (文件、音訊、影片) ([#2978](https://github.com/NousResearch/hermes-agent/pull/2978))
- 修復 Telegram 「找不到訊息討論串」導致進度訊息中斷的問題 ([#3390](https://github.com/NousResearch/hermes-agent/pull/3390))
- 修復 OpenClaw 遷移覆蓋預設值的問題 ([#3282](https://github.com/NousResearch/hermes-agent/pull/3282))
- 修復回訪使用者安裝選單分發至錯誤章節的問題 ([#3083](https://github.com/NousResearch/hermes-agent/pull/3083))
- 修復 `hermes update` 遇到的 PEP 668 「環境受外部管理 (externally-managed-environment)」錯誤 ([#3099](https://github.com/NousResearch/hermes-agent/pull/3099))
- 修復子代理因共享預算而過早達到 `max_iterations` 的問題 ([#3004](https://github.com/NousResearch/hermes-agent/pull/3004))
- `tool_progress` 配置支援 YAML 布林值處理 ([#3300](https://github.com/NousResearch/hermes-agent/pull/3300))
- 修復 `config.get()` 在遇到 YAML null 值時崩潰的問題 ([#3377](https://github.com/NousResearch/hermes-agent/pull/3377))
- 修復 `.strip()` 在處理 YAML 配置 None 值時的崩潰問題 ([#3552](https://github.com/NousResearch/hermes-agent/pull/3552))
- 修復網關掛起的代理程式 —— `/stop` 現在會強制終止會話鎖 ([#3104](https://github.com/NousResearch/hermes-agent/pull/3104))
- 修復 `_custom` 供應商被靜默重對應至 `openrouter` 的問題 ([#2792](https://github.com/NousResearch/hermes-agent/pull/2792))
- `PLATFORMS` 字典中補齊 Matrix 條目 ([#3473](https://github.com/NousResearch/hermes-agent/pull/3473))
- 修復 Email 適配器 `_seen_uids` 無限制增長的問題 ([#3490](https://github.com/NousResearch/hermes-agent/pull/3490))

---

## 🧪 測試

- 鎖定 `agent-client-protocol` 版本 < 0.9 以應對上游中斷性更新 ([#3320](https://github.com/NousResearch/hermes-agent/pull/3320))
- 視覺自動偵測測試中捕捉 Anthropic 匯入錯誤 ([#3312](https://github.com/NousResearch/hermes-agent/pull/3312))
- 根據新的優雅返回行為更新重試耗盡測試 ([#3320](https://github.com/NousResearch/hermes-agent/pull/3320))
- 為 null 元資料 Frontmatter 新增回歸測試 ([untagged commit](https://github.com/NousResearch/hermes-agent))

---

## 📚 文檔更新

- 更新所有關於 `/model` 指令重構與自訂供應商支援的文檔 ([#2800](https://github.com/NousResearch/hermes-agent/pull/2800))
- 修正 18 個檔案中過時與錯誤的文檔內容 ([#2805](https://github.com/NousResearch/hermes-agent/pull/2805))
- 為 9 項先前未說明的功編寫文檔 ([#2814](https://github.com/NousResearch/hermes-agent/pull/2814))
- 文檔新增缺失的技能、CLI 指令與網關環境變數 ([#2809](https://github.com/NousResearch/hermes-agent/pull/2809))
- 修正 API 伺服器回應儲存文檔 —— 使用 SQLite 而非記憶體儲存 ([#2819](https://github.com/NousResearch/hermes-agent/pull/2819))
- 為 pip install 額外組件加上引號，以修復 zsh glob 錯誤 ([#2815](https://github.com/NousResearch/hermes-agent/pull/2815))
- 統整鉤子文檔 —— 鉤子頁面新增插件鉤子並增加 `session:end` 事件 ([untagged commit](https://github.com/NousResearch/hermes-agent))
- 釐清 `session_search` Schema 描述中的雙模式行為 ([untagged commit](https://github.com/NousResearch/hermes-agent))
- 修正 Discord 公開機器人設定，支援 Discord 提供的邀請連結 ([#3519](https://github.com/NousResearch/hermes-agent/pull/3519)) 由 @mehmoodosman 貢獻
- 修訂 v0.4.0 變更日誌 —— 修正功能歸屬並重新調整章節順序 ([untagged commit](https://github.com/NousResearch/hermes-agent))

---

## 👥 貢獻者

### 核心團隊
- **@teknium1** —— 157 個 PR，涵蓋本版本的所有範疇

### 社群貢獻者
- **@alt-glitch** (Siddharth Balyan) —— 2 個 PR：具備 uv2nix 建置、NixOS 模組與持久化容器模式的 Nix Flake ([#20])；為 Nix 建置自動生成配置鍵與後綴 PATH ([#3061], [#3274])
- **@ctlst** —— 1 個 PR：防止網關模式下的 AsyncOpenAI/httpx 跨迴圈死鎖 ([#2701])
- **@memosr** (memosr.eth) —— 1 個 PR：為 `send_message_tool` HTTP 呼叫新增請求逾時 ([#3162])
- **@mehmoodosman** (Osman Mehmood) —— 1 PR：修正 Discord 公開機器人設定文檔 ([#3519])

### 所有貢獻者
@alt-glitch, @ctlst, @mehmoodosman, @memosr, @teknium1

---

**完整變更日誌**: [v2026.3.23...v2026.3.28](https://github.com/NousResearch/hermes-agent/compare/v2026.3.23...v2026.3.28)
