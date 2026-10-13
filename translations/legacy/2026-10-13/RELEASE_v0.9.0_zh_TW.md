# Hermes Agent v0.9.0 (v2026.4.13)

**發佈日期：** 2026 年 4 月 13 日
**自 v0.8.0 以來的變更：** 487 個 commit · 269 個已合併 PR · 167 個已解決 Issue · 493 個檔案變更 · 63,281 行新增 · 24 位貢獻者

> 「無處不在」的版本 —— Hermes 透過 Termux/Android 進入行動端，新增了 iMessage 與微信 (WeChat) 支援，為 OpenAI 與 Anthropic 提供了快速模式 (Fast Mode)，引入了背景進程監控，推出了用於管理代理程式的本地網頁儀表板，並在 16 個支援的平台上進行了至今最深度的安全性強化。

---

## ✨ 亮點更新

- **本地網頁儀表板 (Local Web Dashboard)** —— 用於在本地管理 Hermes Agent 的全新瀏覽器儀表板。無需修改配置檔案或終端，即可透過簡潔的網頁介面配置設定、監控會話、瀏覽技能以及管理網關。這是入門 Hermes 最簡單的方式。

- **快速模式 (Fast Mode, `/fast`)** —— OpenAI 與 Anthropic 模型的高優先級處理。切換 `/fast` 指令即可透過優先隊列路由，大幅降低支援模型 (GPT-5.4, Codex, Claude) 的延遲。支援範圍擴展至所有 OpenAI 優先處理模型及 Anthropic 的快速層級。([#6875](https://github.com/NousResearch/hermes-agent/pull/6875), [#6960](https://github.com/NousResearch/hermes-agent/pull/6960), [#7037](https://github.com/NousResearch/hermes-agent/pull/7037))

- **透過 BlueBubbles 支援 iMessage** —— 完整的 iMessage 整合，將 Hermes 帶入 Apple 的通訊生態系統。包含自動 Webhook 註冊、安裝精靈整合以及崩潰恢復能力。([#6437](https://github.com/NousResearch/hermes-agent/pull/6437), [#6460](https://github.com/NousResearch/hermes-agent/pull/6460), [#6494](https://github.com/NousResearch/hermes-agent/pull/6494))

- **微信 (Weixin) 與 企業微信 (WeCom) 回調模式** —— 透過 iLink Bot API 提供原生微信支援，並為自建企業應用新增了企業微信回調模式適配器。支援串流光標、媒體上傳、Markdown 連結處理以及原子狀態持久化。Hermes 現在已完整覆蓋中國的通訊生態系統。([#7166](https://github.com/NousResearch/hermes-agent/pull/7166), [#7943](https://github.com/NousResearch/hermes-agent/pull/7943))

- **Termux / Android 支援** —— 透過 Termux 在 Android 上原生執行 Hermes。適配了安裝路徑、針對行動裝置螢幕優化了 TUI、支援語音後端，且可在裝置上執行 `/image` 指令。([#6834](https://github.com/NousResearch/hermes-agent/pull/6834))

- **背景進程監控 (`watch_patterns`)** —— 設定監控模式以觀察背景進程輸出，並在匹配時獲得即時通知。可用於監控錯誤、等待特定事件 (如 "listening on port") 或觀察建置日誌 —— 全部無需手動輪詢。([#7635](https://github.com/NousResearch/hermes-agent/pull/7635))

- **原生 xAI 與 Xiaomi MiMo 供應商** —— 為 xAI (Grok) 與 Xiaomi MiMo 提供一等公民級別的供應商支援，具備直接 API 存取、模型目錄以及安裝精靈整合。此外還支援具備 Portal 請求支援的 Qwen OAuth。([#7372](https://github.com/NousResearch/hermes-agent/pull/7372), [#7855](https://github.com/NousResearch/hermes-agent/pull/7855))

- **可插拔上下文引擎 (Pluggable Context Engine)** —— 上下文管理現在可透過 `hermes plugins` 進行插拔。您可以更換自訂的上下文引擎來控制代理程式每回合看到的內容 —— 包含過濾、摘要或特定領域的上下文注入。([#7464](https://github.com/NousResearch/hermes-agent/pull/7464))

- **統一代理支援 (Unified Proxy Support)** —— 在所有網關平台支援 SOCKS 代理、`DISCORD_PROXY` 以及系統代理自動偵測。讓 Hermes 在企業防火牆後也能順暢運作。([#6814](https://github.com/NousResearch/hermes-agent/pull/6814))

- **全面安全性強化** —— 包含檢查點管理器的路徑遍歷保護、沙盒寫入中的 Shell 注入中和、Slack 圖片上傳的 SSRF 重新導向防護、Twilio Webhook 簽章驗證 (修復 SMS RCE)、API 伺服器強制認證、Git 參數注入預防以及核准按鈕授權。([#7933](https://github.com/NousResearch/hermes-agent/pull/7933), [#7944](https://github.com/NousResearch/hermes-agent/pull/7944), [#7940](https://github.com/NousResearch/hermes-agent/pull/7940), [#7151](https://github.com/NousResearch/hermes-agent/pull/7151), [#7156](https://github.com/NousResearch/hermes-agent/pull/7156))

- **`hermes backup` 與 `hermes import`** —— 完整備份與還原您的 Hermes 配置、會話、技能與記憶。方便在機器間遷移或在重大變更前建立快照。([#7997](https://github.com/NousResearch/hermes-agent/pull/7997))

- **支援 16 個平台** —— 隨著 BlueBubbles (iMessage) 與微信的加入，加上原有的 Telegram, Discord, Slack, WhatsApp, Signal, Matrix, Email, SMS, 釘釘 (DingTalk), 飛書 (Feishu), 企業微信 (WeCom), Mattermost, Home Assistant 與 Webhooks，Hermes 現在開箱即可支援 16 個通訊平台。

- **`/debug` 與 `hermes debug share`** —— 全新的除錯工具組：在所有平台提供 `/debug` 斜線指令進行快速診斷，並可透過 `hermes debug share` 將完整的除錯報告上傳至 Pastebin，方便在排除故障時分享。([#8681](https://github.com/NousResearch/hermes-agent/pull/8681))

---

## 🏗️ 核心代理與架構

### 供應商與模型支援
- **原生 xAI (Grok) 供應商**，具備直接 API 存取與模型目錄 ([#7372](https://github.com/NousResearch/hermes-agent/pull/7372))
- **Xiaomi MiMo 作為一等供應商** —— 安裝精靈、模型目錄、空回應恢復 ([#7855](https://github.com/NousResearch/hermes-agent/pull/7855))
- **Qwen OAuth 供應商**，支援 Portal 請求 ([#6282](https://github.com/NousResearch/hermes-agent/pull/6282))
- **快速模式** —— 為 OpenAI 優先處理與 Anthropic 快速層級新增 `/fast` 切換 ([#6875](https://github.com/NousResearch/hermes-agent/pull/6875), [#6960](https://github.com/NousResearch/hermes-agent/pull/6960), [#7037](https://github.com/NousResearch/hermes-agent/pull/7037))
- **結構化 API 錯誤分類**，用於智慧故障轉移決策 ([#6514](https://github.com/NousResearch/hermes-agent/pull/6514))
- **速率限制標頭擷取**，顯示於 `/usage` ([#6541](https://github.com/NousResearch/hermes-agent/pull/6541))
- **API 伺服器模型名稱** 從個人檔案名稱派生 ([#6857](https://github.com/NousResearch/hermes-agent/pull/6857))
- **自訂供應商** 現在包含在 `/model` 列表與解析中 ([#7088](https://github.com/NousResearch/hermes-agent/pull/7088))
- **回退供應商啟用**：在連續出現空回應時自動啟用並向使用者顯示狀態 ([#7505](https://github.com/NousResearch/hermes-agent/pull/7505))
- **OpenRouter 變體標籤** (`:free`, `:extended`, `:fast`) 在模型切換時予以保留 ([#6383](https://github.com/NousResearch/hermes-agent/pull/6383))
- **憑證耗盡重置時間 (TTL)** 從 24 小時縮短至 1 小時 ([#6504](https://github.com/NousResearch/hermes-agent/pull/6504))
- **OAuth 憑證生命週期** 強化 —— 包含失效池金鑰、auth.json 同步、Codex CLI 競態修復 ([#6874](https://github.com/NousResearch/hermes-agent/pull/6874))
- 為推理模型 (MiMo, Qwen, GLM) 提供空回應恢復功能 ([#8609](https://github.com/NousResearch/hermes-agent/pull/8609))
- MiniMax 上下文長度、思考防護、端點校正 ([#6082](https://github.com/NousResearch/hermes-agent/pull/6082), [#7126](https://github.com/NousResearch/hermes-agent/pull/7126))
- Z.AI 端點透過探測與快取實現自動偵測 ([#5763](https://github.com/NousResearch/hermes-agent/pull/5763))

### 代理迴圈與對話
- **可插拔上下文引擎槽**，透過 `hermes plugins` 實現 ([#7464](https://github.com/NousResearch/hermes-agent/pull/7464))
- **背景進程監控** —— `watch_patterns` 提供即時輸出警報 ([#7635](https://github.com/NousResearch/hermes-agent/pull/7635))
- **改進上下文壓縮** —— 更高的限制、工具追蹤、降級警告、Token 預算末端保護 ([#6395](https://github.com/NousResearch/hermes-agent/pull/6395), [#6453](https://github.com/NousResearch/hermes-agent/pull/6453))
- **`/compress <焦點>`** —— 針對特定主題引導壓縮 ([#8017](https://github.com/NousResearch/hermes-agent/pull/8017))
- **分級上下文壓力警告**，具備網關去重功能 ([#6411](https://github.com/NousResearch/hermes-agent/pull/6411))
- **分階段不活動警告**，在逾時升級前發出 ([#6387](https://github.com/NousResearch/hermes-agent/pull/6387))
- **防止代理程式在任務中途停止** —— 上下文下限、預算大修、活動追蹤 ([#7983](https://github.com/NousResearch/hermes-agent/pull/7983))
- 在 `delegate_task` 期間將子代理活動**傳播至父代理** ([#7295](https://github.com/NousResearch/hermes-agent/pull/7295))
- 執行前進行**截斷的串流工具呼叫偵測** ([#6847](https://github.com/NousResearch/hermes-agent/pull/6847))
- 空回應重試 (3 次重試並附帶提示詞引導) ([#6488](https://github.com/NousResearch/hermes-agent/pull/6488))
- 自適應串流退避 + 光標去除，以防止訊息截斷 ([#7683](https://github.com/NousResearch/hermes-agent/pull/7683))
- 壓縮現在使用即時對話模型而非過時的持久化配置 ([#8258](https://github.com/NousResearch/hermes-agent/pull/8258))
- 從 Gemma 4 回應中去除 `<thought>` 標籤 ([#8562](https://github.com/NousResearch/hermes-agent/pull/8562))
- 防止散文中的 `<think>` 標籤抑制回應輸出 ([#6968](https://github.com/NousResearch/hermes-agent/pull/6968))
- 在代理迴圈中新增回合結束診斷日誌 ([#6549](https://github.com/NousResearch/hermes-agent/pull/6549))
- 每個執行緒獨立的工具中斷訊號範圍，防止跨會話洩漏 ([#7930](https://github.com/NousResearch/hermes-agent/pull/7930))

### 記憶與會話
- **Hindsight 記憶插件** —— 功能對齊、安裝精靈、配置改進 —— @nicoloboschi ([#6428](https://github.com/NousResearch/hermes-agent/pull/6428))
- **Honcho** —— 為工具模式提供選用的 `initOnSessionStart` —— @Kathie-yu ([#6995](https://github.com/NousResearch/hermes-agent/pull/6995))
- 在修剪/刪除時使子會話孤立，而非連鎖刪除 ([#6513](https://github.com/NousResearch/hermes-agent/pull/6513))
- Doctor 指令現在僅檢查活動中的記憶供應商 ([#6285](https://github.com/NousResearch/hermes-agent/pull/6285))

---

## 📱 通訊平台 (網關)

### 新支援平台
- **BlueBubbles (iMessage)** —— 具備自動 Webhook 註冊、安裝精靈與崩潰恢復的完整適配器 ([#6437](https://github.com/NousResearch/hermes-agent/pull/6437), [#6460](https://github.com/NousResearch/hermes-agent/pull/6460), [#6494](https://github.com/NousResearch/hermes-agent/pull/6494), [#7107](https://github.com/NousResearch/hermes-agent/pull/7107))
- **微信 (Weixin)** —— 透過 iLink Bot API 提供原生支援，支援串流、媒體上傳、Markdown 連結 ([#7166](https://github.com/NousResearch/hermes-agent/pull/7166), [#8665](https://github.com/NousResearch/hermes-agent/pull/8665))
- **企業微信回調模式 (WeCom Callback)** —— 具備原子狀態持久化的自建企業應用適配器 ([#7943](https://github.com/NousResearch/hermes-agent/pull/7943), [#7928](https://github.com/NousResearch/hermes-agent/pull/7928))

### Discord
- **允許頻道白名單**配置 —— @jarvis-phw ([#7044](https://github.com/NousResearch/hermes-agent/pull/7044))
- 討論串會話中的**論壇頻道主題繼承** —— @hermes-agent-dhabibi ([#6377](https://github.com/NousResearch/hermes-agent/pull/6377))
- **DISCORD_REPLY_TO_MODE** 設定 ([#6333](https://github.com/NousResearch/hermes-agent/pull/6333))
- 接受 `.log` 附件，提高文件大小限制 —— @kira-ariaki ([#6467](https://github.com/NousResearch/hermes-agent/pull/6467))
- 解耦準備就緒與斜線指令同步 ([#8016](https://github.com/NousResearch/hermes-agent/pull/8016))

### Slack
- **整合 Slack 改進** —— 將 7 個社群 PR 整合為一 ([#6809](https://github.com/NousResearch/hermes-agent/pull/6809))
- 處理助手討論串生命週期事件 ([#6433](https://github.com/NousResearch/hermes-agent/pull/6433))

### Matrix
- **從 matrix-nio 遷移至 mautrix-python** ([#7518](https://github.com/NousResearch/hermes-agent/pull/7518))
- 使用 SQLite 加密儲存取代 Pickle (修復 E2EE 解密問題) —— @alt-glitch ([#7981](https://github.com/NousResearch/hermes-agent/pull/7981))
- 為 E2EE 遷移提供跨簽署恢復金鑰驗證 ([#8282](https://github.com/NousResearch/hermes-agent/pull/8282))
- 針對飛書 (Feishu) 提供私訊提及討論串與群組對話事件 ([#7423](https://github.com/NousResearch/hermes-agent/pull/7423))

### 網關核心
- **統一代理支援** —— SOCKS, DISCORD_PROXY, 具備 macOS 自動偵測的多平台支援 ([#6814](https://github.com/NousResearch/hermes-agent/pull/6814))
- **入站文字批次處理**，適用於 Discord, Matrix, 企業微信 + 自適應延遲 ([#6979](https://github.com/NousResearch/hermes-agent/pull/6979))
- 在聊天平台**呈現自然的回合中助手訊息** ([#7978](https://github.com/NousResearch/hermes-agent/pull/7978))
- **感知 WSL 的網關**，具備智慧 systemd 偵測 ([#7510](https://github.com/NousResearch/hermes-agent/pull/7510))
- **將所有缺失平台新增至安裝精靈** ([#7949](https://github.com/NousResearch/hermes-agent/pull/7949))
- **依平台設定 `tool_progress` 覆蓋** ([#6348](https://github.com/NousResearch/hermes-agent/pull/6348))
- **可配置的「仍在工作中」通知間隔** ([#8572](https://github.com/NousResearch/hermes-agent/pull/8572))
- `/model` 切換在不同訊息間持續有效 ([#7081](https://github.com/NousResearch/hermes-agent/pull/7081))
- `/usage` 指令現在可顯示回合間的速率限制、成本與 Token 詳細資訊 ([#7038](https://github.com/NousResearch/hermes-agent/pull/7038))
- 在重新啟動前排乾執行中的任務 ([#7503](https://github.com/NousResearch/hermes-agent/pull/7503))
- 執行失敗時不要逐出快取的代理程式 —— 防止 MCP 重啟迴圈 ([#7539](https://github.com/NousResearch/hermes-agent/pull/7539))
- 使用 `contextvars` 取代 `os.environ` 儲存會話狀態 ([#7454](https://github.com/NousResearch/hermes-agent/pull/7454))
- 從列舉 (Enum) 派生頻道目錄平台，而非硬編碼列表 ([#7450](https://github.com/NousResearch/hermes-agent/pull/7450))
- 快取前驗證圖片下載 (跨平台) ([#7125](https://github.com/NousResearch/hermes-agent/pull/7125))
- 所有平台的跨平台 Webhook 遞送 ([#7095](https://github.com/NousResearch/hermes-agent/pull/7095))
- Cron 支援 Discord `thread_id` 遞送 ([#7106](https://github.com/NousResearch/hermes-agent/pull/7106))
- 飛書 QR 碼機器人入職導覽 ([#8570](https://github.com/NousResearch/hermes-agent/pull/8570))
- 網關狀態範圍鎖定至活動中的個人檔案 ([#7951](https://github.com/NousResearch/hermes-agent/pull/7951))
- 防止背景進程通知觸發錯誤的配對請求 ([#6434](https://github.com/NousResearch/hermes-agent/pull/6434))

---

## 🖥️ CLI 與使用者體驗

### 互動式 CLI
- **Termux / Android 支援** —— 適配安裝路徑、TUI、語音與 `/image` 指令 ([#6834](https://github.com/NousResearch/hermes-agent/pull/6834))
- **原生 `/model` 選擇器視窗**，用於供應商 → 模型選擇 ([#8003](https://github.com/NousResearch/hermes-agent/pull/8003))
- 在 TUI 加載圖示中恢復**即時工具耗時計數器** ([#7359](https://github.com/NousResearch/hermes-agent/pull/7359))
- 在 TUI 中提供**堆疊式工具進度捲動歷史** ([#8201](https://github.com/NousResearch/hermes-agent/pull/8201))
- **新會話開始時隨機顯示小撇步** (CLI + 網關，共 279 條) ([#8225](https://github.com/NousResearch/hermes-agent/pull/8225), [#8237](https://github.com/NousResearch/hermes-agent/pull/8237))
- **`hermes dump`** —— 提供可供複製貼上的安裝摘要，方便除錯 ([#6550](https://github.com/NousResearch/hermes-agent/pull/6550))
- **`hermes backup` / `hermes import`** —— 完整配置備份與還原 ([#7997](https://github.com/NousResearch/hermes-agent/pull/7997))
- 在系統提示詞中新增 **WSL 環境提示** ([#8285](https://github.com/NousResearch/hermes-agent/pull/8285))
- **個人檔案建立體驗** —— 預填 SOUL.md + 憑證警告 ([#8553](https://github.com/NousResearch/hermes-agent/pull/8553))
- 感知 Shell 的 Sudo 偵測，支援空密碼 ([#6517](https://github.com/NousResearch/hermes-agent/pull/6517))
- 在 Curses/終端選單後清除標準輸入，防止轉義序列洩漏 ([#7167](https://github.com/NousResearch/hermes-agent/pull/7167))
- 處理 `prompt_toolkit` 啟動時損壞的標準輸入 ([#8560](https://github.com/NousResearch/hermes-agent/pull/8560))

### 安裝與配置
- **依平台設定顯示詳細程度** ([#8006](https://github.com/NousResearch/hermes-agent/pull/8006))
- **組件分離的日誌系統**，具備會話上下文與過濾功能 ([#7991](https://github.com/NousResearch/hermes-agent/pull/7991))
- **`network.force_ipv4`** 配置，修復 IPv6 逾時問題 ([#8196](https://github.com/NousResearch/hermes-agent/pull/8196))
- **標準化訊息空白與 JSON 格式化** ([#7988](https://github.com/NousResearch/hermes-agent/pull/7988))
- 遷移期間將 **OpenClaw 品牌更名為 Hermes** ([#8210](https://github.com/NousResearch/hermes-agent/pull/8210))
- 輔助設定中 config.yaml 優先級高於環境變數 ([#7889](https://github.com/NousResearch/hermes-agent/pull/7889))
- 強化安裝供應商流程 + 即時 OpenRouter 目錄更新 ([#7078](https://github.com/NousResearch/hermes-agent/pull/7078))
- 在所有介面中標準化推理模型努力程度 (Reasoning Effort) 的排序 ([#6804](https://github.com/NousResearch/hermes-agent/pull/6804))
- 移除過時的 `LLM_MODEL` 環境變數 + 遷移以清理過時條目 ([#6543](https://github.com/NousResearch/hermes-agent/pull/6543))
- 移除 `/prompt` 斜線指令 —— 避免前綴展開陷阱 ([#6752](https://github.com/NousResearch/hermes-agent/pull/6752))
- 新增 `HERMES_HOME_MODE` 環境變數以覆蓋權限 —— @ygd58 ([#6993](https://github.com/NousResearch/hermes-agent/pull/6993))
- 當模型配置為空時回退至預設模型 ([#8303](https://github.com/NousResearch/hermes-agent/pull/8303))
- 當壓縮模型上下文太小時發出警告 ([#7894](https://github.com/NousResearch/hermes-agent/pull/7894))

---

## 🔧 工具系統

### 環境與執行
- **環境統一的單次呼叫生成 (spawn-per-call) 執行層** ([#6343](https://github.com/NousResearch/hermes-agent/pull/6343))
- **統一檔案同步**，具備 mtime 追蹤、刪除與交易狀態 ([#7087](https://github.com/NousResearch/hermes-agent/pull/7087))
- **持久化沙盒環境**在回合間保持存續 ([#6412](https://github.com/NousResearch/hermes-agent/pull/6412))
- 為 SSH/Modal 後端提供**透過 Tar Pipe 的批次檔案同步** —— @alt-glitch ([#8014](https://github.com/NousResearch/hermes-agent/pull/8014))
- **Daytona** —— 批次上傳、配置橋接、靜默磁碟限制 ([#7538](https://github.com/NousResearch/hermes-agent/pull/7538))
- 前台逾時上限，防止會話死鎖 ([#7082](https://github.com/NousResearch/hermes-agent/pull/7082))
- 防範無效指令值 ([#6417](https://github.com/NousResearch/hermes-agent/pull/6417))

### MCP
- 支援 **`hermes mcp add --env` 與 `--preset`** ([#7970](https://github.com/NousResearch/hermes-agent/pull/7970))
- 當同時存在 `content` 與 `structuredContent` 時進行合併 ([#7118](https://github.com/NousResearch/hermes-agent/pull/7118))
- 修復 MCP 工具名稱衝突問題 ([#7654](https://github.com/NousResearch/hermes-agent/pull/7654))

### 瀏覽器
- 瀏覽器強化 —— 移除無效程式碼、快取、捲動效能、安全性、執行緒安全 ([#7354](https://github.com/NousResearch/hermes-agent/pull/7354))
- `/browser connect` 自動啟動現在使用專用的 Chrome 設定檔目錄 ([#6821](https://github.com/NousResearch/hermes-agent/pull/6821))
- 啟動時清理孤立的瀏覽器會話 ([#7931](https://github.com/NousResearch/hermes-agent/pull/7931))

### 語音與視覺
- **Voxtral TTS 供應商** (Mistral AI) ([#7653](https://github.com/NousResearch/hermes-agent/pull/7653))
- 針對 Edge TTS, OpenAI TTS, MiniMax 提供 **TTS 語速支援** ([#8666](https://github.com/NousResearch/hermes-agent/pull/8666))
- **視覺自動縮放**超大圖片，提高限制至 20 MB，失敗重試 ([#7883](https://github.com/NousResearch/hermes-agent/pull/7883), [#7902](https://github.com/NousResearch/hermes-agent/pull/7902))
- 修復 STT 供應商與模型不匹配的問題 (whisper-1 vs faster-whisper) ([#7113](https://github.com/NousResearch/hermes-agent/pull/7113))

### 其他工具
- **`hermes dump`** 指令提供安裝摘要 ([#6550](https://github.com/NousResearch/hermes-agent/pull/6550))
- TODO 儲存區在替換操作期間強制 ID 唯一性 ([#7986](https://github.com/NousResearch/hermes-agent/pull/7986))
- 在 `delegate_task` Schema 描述中列出所有可用工具集 ([#8231](https://github.com/NousResearch/hermes-agent/pull/8231))
- API 伺服器：工具進度改為自訂 SSE 事件，防止模型損壞 ([#7500](https://github.com/NousResearch/hermes-agent/pull/7500))
- API 伺服器：所有對話共享一個 Docker 容器 ([#7127](https://github.com/NousResearch/hermes-agent/pull/7127))

---

## 🧩 技能生態系統

- **集中式技能索引 + 樹狀快取** —— 消除安裝時的頻率限制失敗 ([#8575](https://github.com/NousResearch/hermes-agent/pull/8575))
- 在系統提示詞 (v3) 中新增**更強烈的技能加載指令** ([#8209](https://github.com/NousResearch/hermes-agent/pull/8209), [#8286](https://github.com/NousResearch/hermes-agent/pull/8286))
- **Google Workspace 技能** 遷移至 GWS CLI 後端 ([#6788](https://github.com/NousResearch/hermes-agent/pull/6788))
- **創意發散策略**技能 —— @SHL0MS ([#6882](https://github.com/NousResearch/hermes-agent/pull/6882))
- **創意構思** —— 限制驅動的專案生成 —— @SHL0MS ([#7555](https://github.com/NousResearch/hermes-agent/pull/7555))
- 並行化技能瀏覽/搜尋以防止掛起 ([#7301](https://github.com/NousResearch/hermes-agent/pull/7301))
- 在 `skills_sync` 中從 SKILL.md Frontmatter 讀取名稱 ([#7623](https://github.com/NousResearch/hermes-agent/pull/7623))

---

## 🔒 安全性與可靠性

### 安全性強化
- **Twilio Webhook 簽章驗證** —— 修復 SMS RCE 漏洞 ([#7933](https://github.com/NousResearch/hermes-agent/pull/7933))
- 在 `_write_to_sandbox` 中透過路徑引號中和 **Shell 注入** ([#7940](https://github.com/NousResearch/hermes-agent/pull/7940))
- 檢查點管理員中的 **Git 參數注入**與路徑遍歷防禦 ([#7944](https://github.com/NousResearch/hermes-agent/pull/7944))
- Slack 圖片上傳中的 **SSRF 重新導向繞過** + base.py 快取輔助工具 ([#7151](https://github.com/NousResearch/hermes-agent/pull/7151))
- 修補路徑遍歷、憑證閘門與 `DANGEROUS_PATTERNS` 漏洞 ([#7156](https://github.com/NousResearch/hermes-agent/pull/7156))
- **API 綁定保護** —— 非 loopback 綁定強制要求 `API_SERVER_KEY` ([#7455](https://github.com/NousResearch/hermes-agent/pull/7455))
- **核准按鈕授權** —— 延續會話需經過認證 —— @Cafexss ([#6930](https://github.com/NousResearch/hermes-agent/pull/6930))
- 技能管理員操作中的路徑邊界強制執行 ([#7156](https://github.com/NousResearch/hermes-agent/pull/7156))
- 釘釘/API Webhook URL 來源驗證，拒絕標頭注入 ([#7455](https://github.com/NousResearch/hermes-agent/pull/7455))

### 可靠性
- 針對無效 API 回應提供**上下文錯誤診斷** ([#8565](https://github.com/NousResearch/hermes-agent/pull/8565))
- **防止 400 格式錯誤**在 Codex 上觸發壓縮迴圈 ([#6751](https://github.com/NousResearch/hermes-agent/pull/6751))
- 出現「輸出上限太大」錯誤時不要將 `context_length` 減半 —— @KUSH42 ([#6664](https://github.com/NousResearch/hermes-agent/pull/6664))
- 在出現 OpenAI 傳輸錯誤時**恢復主用戶端** ([#7108](https://github.com/NousResearch/hermes-agent/pull/7108))
- 帳單類別 400 錯誤時進行**憑證池輪換** ([#7112](https://github.com/NousResearch/hermes-agent/pull/7112))
- 為本地 LLM 供應商**自動增加串流讀取逾時** ([#6967](https://github.com/NousResearch/hermes-agent/pull/6967))
- 當 CA 憑證路徑不存在時回退至預設憑證 ([#7352](https://github.com/NousResearch/hermes-agent/pull/7352))
- 錯誤分類器中**消除用量限制模式的歧義** —— @sprmn24 ([#6836](https://github.com/NousResearch/hermes-agent/pull/6836))
- 強化 Cron 腳本逾時與供應商恢復 ([#7079](https://github.com/NousResearch/hermes-agent/pull/7079))
- 網關中斷偵測對監控任務失敗具備恢復力 ([#8208](https://github.com/NousResearch/hermes-agent/pull/8208))
- 防止網關優雅重啟後發生非預期的會話自動重置 ([#8299](https://github.com/NousResearch/hermes-agent/pull/8299))
- 防止網關監視器中重複出現更新提示垃圾訊息 ([#8343](https://github.com/NousResearch/hermes-agent/pull/8343))
- 在 Responses API 輸入中去重推理項 ([#7946](https://github.com/NousResearch/hermes-agent/pull/7946))

### 基礎設施
- **多架構 Docker 映像檔** —— amd64 + arm64 ([#6124](https://github.com/NousResearch/hermes-agent/pull/6124))
- **Docker 以非 root 使用者執行**並具備虛擬環境 —— @benbarclay ([#8226](https://github.com/NousResearch/hermes-agent/pull/8226))
- Docker 依賴解析改**使用 `uv`** 以修復解析深度過深問題 ([#6965](https://github.com/NousResearch/hermes-agent/pull/6965))
- **感知容器的 Nix CLI** —— 自動路由至受管理容器 —— @alt-glitch ([#7543](https://github.com/NousResearch/hermes-agent/pull/7543))
- 為互動式 CLI 使用者提供 **Nix 共享狀態權限模型** —— @alt-glitch ([#6796](https://github.com/NousResearch/hermes-agent/pull/6796))
- **每個個人檔案具備獨立的子進程 HOME 隔離** ([#7357](https://github.com/NousResearch/hermes-agent/pull/7357))
- 修復 Docker 中的個人檔案路徑 —— 個人檔案儲存於掛載卷宗 ([#7170](https://github.com/NousResearch/hermes-agent/pull/7170))
- 強化 Docker 容器網關路徑 ([#8614](https://github.com/NousResearch/hermes-agent/pull/8614))
- 為即時 Docker 日誌啟用無緩衝標準輸出 ([#6749](https://github.com/NousResearch/hermes-agent/pull/6749))
- 在 Docker 映像檔中安裝 procps —— @HiddenPuppy ([#7032](https://github.com/NousResearch/hermes-agent/pull/7032))
- 淺層 Git 複製以加快安裝速度 —— @sosyz ([#8396](https://github.com/NousResearch/hermes-agent/pull/8396))
- `hermes update` 在 Stash 衝突時一律重置 ([#7010](https://github.com/NousResearch/hermes-agent/pull/7010))
- 網關重啟前寫入更新結束代碼 (處理 cgroup kill 競態) ([#8288](https://github.com/NousResearch/hermes-agent/pull/8288))
- Nix：`setupSecrets` 選用，新增 tirith 運行時依賴 —— @devorun, @ethernet8023 ([#6261](https://github.com/NousResearch/hermes-agent/pull/6261), [#6721](https://github.com/NousResearch/hermes-agent/pull/6721))
- launchd 停止改用 `bootout` 以免 `KeepAlive` 重新啟動 ([#7119](https://github.com/NousResearch/hermes-agent/pull/7119))

---

## 🐛 重大 Bug 修復

- 修復：`/model` 切換未能在網關訊息間持久生效 ([#7081](https://github.com/NousResearch/hermes-agent/pull/7081))
- 修復：會話範圍的網關模型覆蓋被忽略的問題 —— @Hygaard ([#7662](https://github.com/NousResearch/hermes-agent/pull/7662))
- 修復：壓縮模型上下文長度忽略配置的問題 —— 包含 3 個相關 Issue ([#8258](https://github.com/NousResearch/hermes-agent/pull/8258), [#8107](https://github.com/NousResearch/hermes-agent/pull/8107))
- 修復：OpenCode.ai 上下文視窗被解析為 128K 而非 1M ([#6472](https://github.com/NousResearch/hermes-agent/pull/6472))
- 修復：Codex 回退 auth-store 查找問題 —— @cherifya ([#6462](https://github.com/NousResearch/hermes-agent/pull/6462))
- 修復：進程被殺死時重複的完成通知 ([#7124](https://github.com/NousResearch/hermes-agent/pull/7124))
- 修復：代理守護進程執行緒防止標籤頁關閉時產生孤立 CLI 進程 ([#8557](https://github.com/NousResearch/hermes-agent/pull/8557))
- 修復：文字貼上與語音輸入時產生過時圖片附件的問題 ([#7077](https://github.com/NousResearch/hermes-agent/pull/7077))
- 修復：私訊討論串會話種子導致跨討論串污染的問題 ([#7084](https://github.com/NousResearch/hermes-agent/pull/7084))
- 修復：OpenClaw 遷移在執行前正確顯示測試預覽 ([#6769](https://github.com/NousResearch/hermes-agent/pull/6769))
- 修復：認證錯誤被錯誤分類為可重試 —— @kuishou68 ([#7027](https://github.com/NousResearch/hermes-agent/pull/7027))
- 修復：缺失 `Copilot-Integration-Id` 標頭的問題 ([#7083](https://github.com/NousResearch/hermes-agent/pull/7083))
- 修復：ACP 會話能力問題 —— @luyao618 ([#6985](https://github.com/NousResearch/hermes-agent/pull/6985))
- 修復：從頂層欄位使用 ACP PromptResponse 的問題 ([#7086](https://github.com/NousResearch/hermes-agent/pull/7086))
- 修復：main 分支上數個失敗/不穩定的測試 —— @dsocolobsky ([#6777](https://github.com/NousResearch/hermes-agent/pull/6777))
- 修復：備份標記檔案名稱問題 —— @sprmn24 ([#8600](https://github.com/NousResearch/hermes-agent/pull/8600))
- 修復：快速模式中的 `NoneType` 問題 —— @0xbyt4 ([#7350](https://github.com/NousResearch/hermes-agent/pull/7350))
- 修復：uninstall.py 中缺失匯入的問題 —— @JiayuuWang ([#7034](https://github.com/NousResearch/hermes-agent/pull/7034))

---

## 📚 文件更新

- 平台適配器開發指南 + 企業微信回調模式文件 ([#7969](https://github.com/NousResearch/hermes-agent/pull/7969))
- Cron 故障排除指南 ([#7122](https://github.com/NousResearch/hermes-agent/pull/7122))
- 本地 LLM 串流逾時自動偵測文件 ([#6990](https://github.com/NousResearch/hermes-agent/pull/6990))
- 擴充工具使用強制執行文件 ([#7984](https://github.com/NousResearch/hermes-agent/pull/7984))
- BlueBubbles 配對說明 ([#6548](https://github.com/NousResearch/hermes-agent/pull/6548))
- Telegram 代理支援章節 ([#6348](https://github.com/NousResearch/hermes-agent/pull/6348))
- `hermes dump` 與 `hermes logs` CLI 參考資料 ([#6552](https://github.com/NousResearch/hermes-agent/pull/6552))
- `tool_progress_overrides` 配置參考資料 ([#6364](https://github.com/NousResearch/hermes-agent/pull/6364))
- 壓縮模型上下文長度警告文件 ([#7879](https://github.com/NousResearch/hermes-agent/pull/7879))

---

## 👥 貢獻者

共計來自 **24 位貢獻者** 的 **487 個 commit**，**269 個已合併 PR**。

### 社群貢獻者
- **@alt-glitch** (6 PRs) —— 感知 Nix 容器的 CLI、共享狀態權限、Matrix SQLite 加密儲存、批次 SSH/Modal 檔案同步、Matrix mautrix 相容性
- **@SHL0MS** (2 PRs) —— 創意發散策略技能、創意構思技能
- **@sprmn24** (2 PRs) —— 錯誤分類器歧義消除、備份標記修復
- **@nicoloboschi** —— Hindsight 記憶插件功能對齊
- **@Hygaard** —— 會話範圍網關模型覆蓋修復
- **@jarvis-phw** —— Discord `allowed_channels` 白名單
- **@Kathie-yu** —— 為工具模式提供 Honcho `initOnSessionStart`
- **@hermes-agent-dhabibi** —— Discord 論壇頻道主題繼承
- **@kira-ariaki** —— Discord `.log` 附件與大小限制
- **@cherifya** —— Codex 回退 auth-store 查找
- **@Cafexss** —— 安全性：會話延續認證
- **@KUSH42** —— 壓縮 `context_length` 修復
- **@kuishou68** —— 認證錯誤可重試分類修復
- **@luyao618** —— ACP 會話能力
- **@ygd58** —— `HERMES_HOME_MODE` 環境變數覆蓋
- **@0xbyt4** —— 快速模式 `NoneType` 修復
- **@JiayuuWang** —— CLI 卸載匯入修復
- **@HiddenPuppy** —— Docker `procps` 安裝
- **@dsocolobsky** —— 測試套件修復
- **@bobashopcashier** (1 PR) —— 重新啟動前網關優雅排乾 (整合至 #7503)
- **@benbarclay** —— Docker 映像檔標籤簡化
- **@sosyz** —— 淺層 Git 複製以加速安裝
- **@devorun** —— Nix `setupSecrets` 選用
- **@ethernet8023** —— Nix `tirith` 運行時依賴

---

**完整變更日誌**: [v2026.4.8...v2026.4.13](https://github.com/NousResearch/hermes-agent/compare/v2026.4.8...v2026.4.13)
