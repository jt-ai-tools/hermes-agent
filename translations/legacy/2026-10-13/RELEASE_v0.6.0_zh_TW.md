# Hermes Agent v0.6.0 (v2026.3.30)

**發佈日期：** 2026 年 3 月 30 日

> 「多實例」的版本 —— 提供用於執行隔離代理實例的個人檔案 (Profiles) 功能、MCP 伺服器模式、Docker 容器支援、回退供應商鏈、兩個新通訊平台 (飛書/Lark 與企業微信)、Telegram Webhook 模式、Slack 多工作區 OAuth，兩天內完成了 95 個 PR 與 16 個已解決 Issue。

---

## ✨ 亮點更新

- **個人檔案 (Profiles) —— 多實例 Hermes** —— 在同一個安裝環境下執行多個隔離的 Hermes 實例。每個個人檔案擁有獨立的配置、記憶、會話、技能與網關服務。透過 `hermes profile create` 建立，使用 `hermes -p <名稱>` 切換，並支援匯出/匯入以供分享。完整的權杖鎖 (token-lock) 隔離機制可防止兩個個人檔案使用相同的機器人憑證。([#3681](https://github.com/NousResearch/hermes-agent/pull/3681))

- **MCP 伺服器模式** —— 透過 `hermes mcp serve` 將 Hermes 的對話與會話公開給任何相容 MCP 的用戶端 (如 Claude Desktop, Cursor, VS Code 等)。可瀏覽對話、讀取訊息、跨會話搜尋以及管理附件 —— 全部透過模型內容協定 (Model Context Protocol) 進行。支援 stdio 與可串流的 HTTP 傳輸。([#3795](https://github.com/NousResearch/hermes-agent/pull/3795))

- **Docker 容器** —— 提供官方 Dockerfile 用於在容器中執行 Hermes Agent。支援 CLI 與網關模式，並具備卷宗掛載配置。([#3668](https://github.com/NousResearch/hermes-agent/pull/3668), 關閉 [#850](https://github.com/NousResearch/hermes-agent/issues/850))

- **有序回退供應商鏈** —— 配置多個推論供應商並具備自動故障轉移功能。當主供應商回傳錯誤或無法連線時，Hermes 會自動嘗試鏈中的下一個供應商。可透過 config.yaml 中的 `fallback_providers` 進行配置。([#3813](https://github.com/NousResearch/hermes-agent/pull/3813), 關閉 [#1734](https://github.com/NousResearch/hermes-agent/issues/1734))

- **飛書 (Feishu)/Lark 平台支援** —— 為飛書與 Lark 提供完整的網關適配器，包含事件訂閱、訊息卡片、群組對話、圖片/檔案附件以及互動式卡片回呼。([#3799](https://github.com/NousResearch/hermes-agent/pull/3799), [#3817](https://github.com/NousResearch/hermes-agent/pull/3817), 關閉 [#1788](https://github.com/NousResearch/hermes-agent/issues/1788))

- **企業微信 (WeCom) 平台支援** —— 全新的企業微信網關適配器，支援文字/圖片/語音訊息、群組對話與回呼驗證。([#3847](https://github.com/NousResearch/hermes-agent/pull/3847))

- **Slack 多工作區 OAuth** —— 透過 OAuth 權杖檔案，將單一 Hermes 網關連接至多個 Slack 工作區。每個工作區擁有獨立的機器人權杖，並根據傳入事件動態解析。([#3903](https://github.com/NousResearch/hermes-agent/pull/3903))

- **Telegram Webhook 模式與群組控制** —— 可將 Telegram 適配器切換為 Webhook 模式以替代輪詢 —— 回應速度更快，且更適合部署在反向代理後的生產環境。新的群組提及閘門可控制機器人何時回應：始終回應、僅在被 @提及時回應，或透過正規表達式觸發。([#3880](https://github.com/NousResearch/hermes-agent/pull/3880), [#3870](https://github.com/NousResearch/hermes-agent/pull/3870))

- **Exa 搜尋後端** —— 新增 Exa 作為與 Firecrawl 及 DuckDuckGo 並列的網頁搜尋與內容擷取後端。設定 `EXA_API_KEY` 並將其配置為偏好後端。([#3648](https://github.com/NousResearch/hermes-agent/pull/3648))

- **遠端後端上的技能與憑證** —— 將技能目錄與憑證檔案掛載至 Modal 與 Docker 容器中，使遠端終端會話具備與本地執行相同的技能與機密資訊存取權。([#3890](https://github.com/NousResearch/hermes-agent/pull/3890), [#3671](https://github.com/NousResearch/hermes-agent/pull/3671), 關閉 [#3665](https://github.com/NousResearch/hermes-agent/issues/3665), [#3433](https://github.com/NousResearch/hermes-agent/issues/3433))

---

## 🏗️ 核心代理與架構

### 供應商與模型支援
- **有序回退供應商鏈** —— 在多個已配置的供應商之間實現自動故障轉移 ([#3813](https://github.com/NousResearch/hermes-agent/pull/3813))
- **修正供應商切換時的 api_mode** —— 透過 `hermes model` 切換供應商現在能正確清除過時的 `api_mode`，而非硬編碼為 `chat_completions`，解決了具備 Anthropic 相容端點之供應商的 404 錯誤 ([#3726](https://github.com/NousResearch/hermes-agent/pull/3726), [#3857](https://github.com/NousResearch/hermes-agent/pull/3857), 關閉 [#3685](https://github.com/NousResearch/hermes-agent/issues/3685))
- **停止靜默回退至 OpenRouter** —— 當未配置任何供應商時，Hermes 現在會拋出明確的錯誤，而非靜默地路由至 OpenRouter ([#3807](https://github.com/NousResearch/hermes-agent/pull/3807), [#3862](https://github.com/NousResearch/hermes-agent/pull/3862))
- **Gemini 3.1 預覽模型** —— 已加入 OpenRouter 與 Nous Portal 目錄 ([#3803](https://github.com/NousResearch/hermes-agent/pull/3803), 關閉 [#3753](https://github.com/NousResearch/hermes-agent/issues/3753))
- **Gemini 直接 API 上下文長度** —— 為 Google AI 直接端點提供完整的上下文長度解析 ([#3876](https://github.com/NousResearch/hermes-agent/pull/3876))
- **gpt-5.4-mini** 已加入 Codex 回退目錄 ([#3855](https://github.com/NousResearch/hermes-agent/pull/3855))
- **優先使用精選模型列表**而非即時 API 探測 (當探測回傳的模型較少時) ([#3856](https://github.com/NousResearch/hermes-agent/pull/3856), [#3867](https://github.com/NousResearch/hermes-agent/pull/3867))
- **使用者友好的 429 頻率限制訊息**，具備 Retry-After 倒數顯示 ([#3809](https://github.com/NousResearch/hermes-agent/pull/3809))
- 為無需認證的本地伺服器提供**輔助用戶端佔位金鑰** ([#3842](https://github.com/NousResearch/hermes-agent/pull/3842))
- 為輔助供應商解析提供 **INFO 等級日誌** ([#3866](https://github.com/NousResearch/hermes-agent/pull/3866))

### 代理迴圈與對話
- **子代理狀態報告** —— 當摘要存在時報告 `completed` 狀態，而非泛用的失敗 ([#3829](https://github.com/NousResearch/hermes-agent/pull/3829))
- **壓縮期間更新會話日誌檔案** —— 防止上下文壓縮後產生過時的檔案參考 ([#3835](https://github.com/NousResearch/hermes-agent/pull/3835))
- **省略空的工具參數** —— 當工具列表為空時不傳送 `tools` 參數，而非傳送 `None`，提升與嚴格供應商的相容性 ([#3820](https://github.com/NousResearch/hermes-agent/pull/3820))

### 個人檔案與多實例
- **個人檔案系統** —— 支援 `hermes profile create/list/switch/delete/export/import/rename`。每個個人檔案具備隔離的 HERMES_HOME、網關服務與 CLI 包裝器。權杖鎖機制可防止憑證衝突。支援個人檔案名稱的 Tab 自動補全。([#3681](https://github.com/NousResearch/hermes-agent/pull/3681))
- **感知個人檔案的顯示路徑** —— 所有面向使用者的 `~/.hermes` 路徑皆替換為 `display_hermes_home()` 以顯示正確的個人檔案目錄 ([#3623](https://github.com/NousResearch/hermes-agent/pull/3623))
- **延遲匯入 display_hermes_home** —— 防止 `hermes update` 期間因模組快取過時位元組碼而導致 `ImportError` ([#3776](https://github.com/NousResearch/hermes-agent/pull/3776))
- **受保護路徑遵循 HERMES_HOME** —— `.env` 寫入禁用路徑現在遵循 HERMES_HOME，而非硬編碼的 `~/.hermes` ([#3840](https://github.com/NousResearch/hermes-agent/pull/3840))

---

## 📱 通訊平台 (網關)

### 新支援平台
- **飛書 (Feishu)/Lark** —— 完整適配器，支援事件訂閱、訊息卡片、群組對話、圖片/檔案附件、互動式卡片回呼 ([#3799](https://github.com/NousResearch/hermes-agent/pull/3799), [#3817](https://github.com/NousResearch/hermes-agent/pull/3817))
- **企業微信 (WeCom)** —— 支援文字/圖片/語音訊息、群組對話、回呼驗證 ([#3847](https://github.com/NousResearch/hermes-agent/pull/3847))

### Telegram
- **Webhook 模式** —— 在生產環境部署中可改用 Webhook 端點而非輪詢模式 ([#3880](https://github.com/NousResearch/hermes-agent/pull/3880))
- **群組提及閘門與正規表達式觸發** —— 可配置群組中的回應行為：始終回應、僅 @提及，或正規表達式匹配 ([#3870](https://github.com/NousResearch/hermes-agent/pull/3870))
- **優雅處理已刪除的回覆目標** —— 當回覆的原始訊息已被刪除時不再崩潰 ([#3858](https://github.com/NousResearch/hermes-agent/pull/3858), 關閉 [#3229](https://github.com/NousResearch/hermes-agent/issues/3229))

### Discord
- **訊息處理反應** —— 在處理期間加入反應 Emoji，完成後移除，提供頻道內的視覺回饋 ([#3871](https://github.com/NousResearch/hermes-agent/pull/3871))
- **DISCORD_IGNORE_NO_MENTION** —— 跳過那些提及其他使用者/機器人但未提及 Hermes 的訊息 ([#3640](https://github.com/NousResearch/hermes-agent/pull/3640))
- **清理延遲的「思考中...」** —— 在斜線指令完成後正確移除「思考中...」指示器 ([#3674](https://github.com/NousResearch/hermes-agent/pull/3674), 關閉 [#3595](https://github.com/NousResearch/hermes-agent/issues/3595))

### Slack
- **多工作區 OAuth** —— 透過單一網關與 OAuth 權杖檔案連接多個 Slack 工作區 ([#3903](https://github.com/NousResearch/hermes-agent/pull/3903))

### WhatsApp
- **持久化 aiohttp 會話** —— 跨請求重用 HTTP 會話，而非每條訊息建立新會話 ([#3818](https://github.com/NousResearch/hermes-agent/pull/3818))
- **LID↔電話別名解析** —— 在允許清單中正確匹配 Linked ID 與電話號碼格式 ([#3830](https://github.com/NousResearch/hermes-agent/pull/3830))
- **機器人模式跳過回覆前綴** —— 作為 WhatsApp 機器人執行時，訊息格式更簡潔 ([#3931](https://github.com/NousResearch/hermes-agent/pull/3931))

### Matrix
- **透過 MSC3245 支援原生語音訊息** —— 將語音訊息作為正式的 Matrix 語音事件發送，而非檔案附件 ([#3877](https://github.com/NousResearch/hermes-agent/pull/3877))

### Mattermost
- **可配置的提及行為** —— 支援無需 @提及即可回應訊息 ([#3664](https://github.com/NousResearch/hermes-agent/pull/3664))

### Signal
- **URL 編碼電話號碼**與修正附件 RPC 參數 —— 解決了特定電話號碼格式導致的遞送失敗問題 ([#3670](https://github.com/NousResearch/hermes-agent/pull/3670)) —— @kshitijk4poor

### 電子郵件 (Email)
- **失敗時關閉 SMTP/IMAP 連線** —— 防止錯誤情境下的連線洩漏 ([#3804](https://github.com/NousResearch/hermes-agent/pull/3804))

### 網關核心
- **原子化配置寫入** —— 對 config.yaml 採用原子檔案寫入，防止崩潰時資料遺失 ([#3800](https://github.com/NousResearch/hermes-agent/pull/3800))
- **家頻道環境變數覆蓋** —— 統一套用家頻道的環境變數覆蓋 ([#3796](https://github.com/NousResearch/hermes-agent/pull/3796), [#3808](https://github.com/NousResearch/hermes-agent/pull/3808))
- **以紀錄器 (logger) 取代 print()** —— BasePlatformAdapter 現在使用正式日誌系統而非 print 語句 ([#3669](https://github.com/NousResearch/hermes-agent/pull/3669))
- **Cron 遞送標籤** —— 透過頻道目錄解析人類友好的遞送標籤 ([#3860](https://github.com/NousResearch/hermes-agent/pull/3860), 關閉 [#1945](https://github.com/NousResearch/hermes-agent/issues/1945))
- **加強 Cron [SILENT] 限制** —— 防止代理程式在報告前綴加上 [SILENT] 來規避遞送 ([#3901](https://github.com/NousResearch/hermes-agent/pull/3901))
- **背景任務媒體遞送**與視覺下載逾時修復 ([#3919](https://github.com/NousResearch/hermes-agent/pull/3919))
- **Boot-md 鉤子** —— 內建鉤子範例，用於在網關啟動時執行 BOOT.md 檔案 ([#3733](https://github.com/NousResearch/hermes-agent/pull/3733))

---

## 🖥️ CLI 與使用者體驗

### 互動式 CLI
- **可配置的工具預覽長度** —— 預設顯示完整檔案路徑，而非在 40 字元處截斷 ([#3841](https://github.com/NousResearch/hermes-agent/pull/3841))
- **顯示工具 Token 上下文** —— `hermes tools` 列表現在會顯示每個工具集的預估 Token 消耗 ([#3805](https://github.com/NousResearch/hermes-agent/pull/3805))
- **/bg 加載圖示 TUI 修復** —— 將背景任務加載圖示路由至 TUI 組件，防止與狀態列衝突 ([#3643](https://github.com/NousResearch/hermes-agent/pull/3643))
- **防止狀態列折行**導致重複列出現 ([#3883](https://github.com/NousResearch/hermes-agent/pull/3883)) —— @kshitijk4poor
- **處理已關閉 stdout 的 ValueError** —— 修復網關執行緒關閉期間 stdout 關閉導致的崩潰 ([#3843](https://github.com/NousResearch/hermes-agent/pull/3843), 關閉 [#3534](https://github.com/NousResearch/hermes-agent/issues/3534))
- **從 /tools disable 中移除 input()** —— 消除停用工具時的終端凍結問題 ([#3918](https://github.com/NousResearch/hermes-agent/pull/3918))
- **針對互動式 CLI 指令的 TTY 保護** —— 防止在無終端環境啟動時 CPU 飆升 ([#3933](https://github.com/NousResearch/hermes-agent/pull/3933))
- **Argparse 入口點** —— 在頂層啟動器使用 argparse 以實現更乾淨的錯誤處理 ([#3874](https://github.com/NousResearch/hermes-agent/pull/3874))
- **延遲初始化的工具在橫幅顯示黃色**而非紅色，減少對「缺失」工具的誤報 ([#3822](https://github.com/NousResearch/hermes-agent/pull/3822))
- 配置後在橫幅中顯示 **Honcho 工具** ([#3810](https://github.com/NousResearch/hermes-agent/pull/3810))

### 安裝與配置
- 執行 `hermes setup` 且選擇 Matrix 時，**自動安裝 matrix-nio** ([#3802](https://github.com/NousResearch/hermes-agent/pull/3802), [#3873](https://github.com/NousResearch/hermes-agent/pull/3873))
- **會話匯出支援標準輸出 (stdout)** —— 使用 `-` 將會話匯出至 stdout 以供導流 ([#3641](https://github.com/NousResearch/hermes-agent/pull/3641), 關閉 [#3609](https://github.com/NousResearch/hermes-agent/issues/3609))
- **可配置的核准逾時** —— 設定危險指令核准提示在自動拒絕前的等待時間 ([#3886](https://github.com/NousResearch/hermes-agent/pull/3886), 關閉 [#3765](https://github.com/NousResearch/hermes-agent/issues/3765))
- **更新期間清理 __pycache__** —— 防止 `hermes update` 後因過時位元組碼導致的 ImportError ([#3819](https://github.com/NousResearch/hermes-agent/pull/3819))

---

## 🔧 工具系統

### MCP
- **MCP 伺服器模式** —— 透過 `hermes mcp serve` 向 MCP 用戶端公開對話、會話與附件 ([#3795](https://github.com/NousResearch/hermes-agent/pull/3795))
- **動態工具發現** —— 回應 `notifications/tools/list_changed` 事件，無需重新連線即可從 MCP 伺服器獲取新工具 ([#3812](https://github.com/NousResearch/hermes-agent/pull/3812))
- **改用非棄用的 HTTP 傳輸** —— 從 `sse_client` 切換至 `streamable_http_client` ([#3646](https://github.com/NousResearch/hermes-agent/pull/3646))

### 網頁工具
- **Exa 搜尋後端** —— 作為 Firecrawl 與 DuckDuckGo 的替代方案，用於網頁搜尋與擷取 ([#3648](https://github.com/NousResearch/hermes-agent/pull/3648))

### 瀏覽器
- **防範瀏覽器快照與視覺工具中的 None LLM 回應** ([#3642](https://github.com/NousResearch/hermes-agent/pull/3642))

### 終端與遠端後端
- **將技能目錄掛載**至 Modal 與 Docker 容器 ([#3890](https://github.com/NousResearch/hermes-agent/pull/3890))
- **將憑證檔案掛載**至具備 mtime+大小快取機制的遠端後端 ([#3671](https://github.com/NousResearch/hermes-agent/pull/3671))
- 指令逾時時**保留部分輸出**，而非遺失所有內容 ([#3868](https://github.com/NousResearch/hermes-agent/pull/3868))
- **停止在遠端後端將持久化環境變數標記為缺失** ([#3650](https://github.com/NousResearch/hermes-agent/pull/3650))

### 音訊
- 轉錄工具支援 **.aac 格式** ([#3865](https://github.com/NousResearch/hermes-agent/pull/3865), 關閉 [#1963](https://github.com/NousResearch/hermes-agent/issues/1963))
- **音訊下載重試** —— 為 `cache_audio_from_url` 新增重試邏輯，與現有的圖片下載模式對齊 ([#3401](https://github.com/NousResearch/hermes-agent/pull/3401)) —— @binhnt92

### 視覺
- **拒絕非圖片檔案**並在視覺分析中強制執行「僅限網站」政策 ([#3845](https://github.com/NousResearch/hermes-agent/pull/3845))

### 工具 Schema
- **確保名稱 (name) 欄位始終存在**於工具定義中，修復 `KeyError: 'name'` 崩潰問題 ([#3811](https://github.com/NousResearch/hermes-agent/pull/3811), 關閉 [#3729](https://github.com/NousResearch/hermes-agent/issues/3729))

### ACP (編輯器整合)
- 為 VS Code/Zed/JetBrains 用戶端提供**完整的會話管理介面** —— 包含任務生命週期、取消支援、會話持久化 ([#3675](https://github.com/NousResearch/hermes-agent/pull/3675))

---

## 🧩 技能與插件

### 技能系統
- **外部技能目錄** —— 透過 config.yaml 中的 `skills.external_dirs` 配置額外的技能目錄 ([#3678](https://github.com/NousResearch/hermes-agent/pull/3678))
- **阻擋類別路徑遍歷** —— 防止在技能類別名稱中使用 `../` 進行攻擊 ([#3844](https://github.com/NousResearch/hermes-agent/pull/3844))
- **將 parallel-cli 移至 optional-skills** —— 減少預設技能的佔用空間 ([#3673](https://github.com/NousResearch/hermes-agent/pull/3673)) —— @kshitijk4poor

### 新技能
- **memento-flashcards** —— 間隔重複閃卡系統 ([#3827](https://github.com/NousResearch/hermes-agent/pull/3827))
- **songwriting-and-ai-music** —— 詞曲創作技巧與 AI 音樂生成提示詞 ([#3834](https://github.com/NousResearch/hermes-agent/pull/3834))
- **SiYuan Note** —— 思源筆記 (SiYuan) 整合 ([#3742](https://github.com/NousResearch/hermes-agent/pull/3742))
- **Scrapling** —— 使用 Scrapling 庫的網頁爬取技能 ([#3742](https://github.com/NousResearch/hermes-agent/pull/3742))
- **one-three-one-rule** —— 1-3-1 溝通框架技能 ([#3797](https://github.com/NousResearch/hermes-agent/pull/3797))

### 插件系統
- **插件啟用/停用指令** —— 支援 `hermes plugins enable/disable <名稱>` 以管理插件狀態而無需移除它們 ([#3747](https://github.com/NousResearch/hermes-agent/pull/3747))
- **插件訊息注入** —— 插件現在可以代表使用者透過 `ctx.inject_message()` 向對話流注入訊息 ([#3778](https://github.com/NousResearch/hermes-agent/pull/3778)) —— @winglian
- **支援自託管 Honcho** —— 允許在無需 API 金鑰的情況下使用本地 Honcho 實例 ([#3644](https://github.com/NousResearch/hermes-agent/pull/3644))

---

## 🔒 安全性與可靠性

### 安全性強化
- **加強危險指令偵測** —— 擴充了風險 Shell 指令的模式匹配，並為敏感位置 (`/etc/`, `/boot/`, `docker.sock`) 新增了檔案工具路徑守護 ([#3872](https://github.com/NousResearch/hermes-agent/pull/3872))
- 核准系統中的**敏感路徑寫入檢查** —— 攔截透過檔案工具 (而不僅是終端) 對系統配置檔案的寫入 ([#3859](https://github.com/NousResearch/hermes-agent/pull/3859))
- **擴展機密遮蔽範圍** —— 現在涵蓋 ElevenLabs, Tavily, 與 Exa 的 API 金鑰 ([#3920](https://github.com/NousResearch/hermes-agent/pull/3920))
- **拒絕非圖片檔案的視覺分析** —— 防止資訊洩漏 ([#3845](https://github.com/NousResearch/hermes-agent/pull/3845))
- **阻擋技能類別路徑遍歷** ([#3844](https://github.com/NousResearch/hermes-agent/pull/3844))

### 可靠性
- **原子化 config.yaml 寫入** —— 防止網關崩潰時遺失資料 ([#3800](https://github.com/NousResearch/hermes-agent/pull/3800))
- **更新時清理 __pycache__** —— 防止過時位元組碼導致更新後的 ImportError ([#3819](https://github.com/NousResearch/hermes-agent/pull/3819))
- **針對更新安全的延遲匯入** —— 避免 `hermes update` 期間因模組引用新函數而導致的 ImportError 鏈 ([#3776](https://github.com/NousResearch/hermes-agent/pull/3776))
- **從修補損壞中恢復 terminalbench2** —— 修復了因修補工具的機密遮蔽功能導致受損的檔案 ([#3801](https://github.com/NousResearch/hermes-agent/pull/3801))
- **終端逾時保留部分輸出** ([#3868](https://github.com/NousResearch/hermes-agent/pull/3868))

---

## 🐛 重大 Bug 修復

- **OpenClaw 遷移不再覆蓋模型配置** —— 修復了遷移時將模型配置字典誤改為字串的問題 ([#3924](https://github.com/NousResearch/hermes-agent/pull/3924)) —— @0xbyt4
- **擴展 OpenClaw 遷移範圍** —— 涵蓋會話、Cron、記憶等完整資料足跡 ([#3869](https://github.com/NousResearch/hermes-agent/pull/3869))
- **Telegram 已刪除回覆目標** —— 優雅處理對已刪除訊息的回覆 ([#3858](https://github.com/NousResearch/hermes-agent/pull/3858))
- **Discord 「思考中...」持久性問題** —— 正確清理延遲回應指示器 ([#3674](https://github.com/NousResearch/hermes-agent/pull/3674))
- **WhatsApp LID↔電話別名** —— 修復 Linked ID 格式的允許清單匹配失敗問題 ([#3830](https://github.com/NousResearch/hermes-agent/pull/3830))
- **Signal URL 編碼電話號碼** —— 修復特定格式導致的遞送失敗 ([#3670](https://github.com/NousResearch/hermes-agent/pull/3670))
- **電子郵件連線洩漏** —— 錯誤時正確關閉 SMTP/IMAP 連線 ([#3804](https://github.com/NousResearch/hermes-agent/pull/3804))
- **_safe_print ValueError** —— 解決網關執行緒在 stdout 關閉時的崩潰 ([#3843](https://github.com/NousResearch/hermes-agent/pull/3843))
- **工具 Schema KeyError 'name'** —— 確保定義中始終包含 name 欄位 ([#3811](https://github.com/NousResearch/hermes-agent/pull/3811))
- **供應商切換後 api_mode 過時** —— 使用 `hermes model` 切換時能正確清除 ([#3857](https://github.com/NousResearch/hermes-agent/pull/3857))

---

## 🧪 測試

- 解決了鉤子、tiktoken、插件與技能測試中的 10 多項 CI 失敗 ([#3848](https://github.com/NousResearch/hermes-agent/pull/3848), [#3721](https://github.com/NousResearch/hermes-agent/pull/3721), [#3936](https://github.com/NousResearch/hermes-agent/pull/3936))

---

## 📚 文檔更新

- **完整的 OpenClaw 遷移指南** —— 從 OpenClaw/Claw3D 遷移至 Hermes Agent 的逐步指南 ([#3864](https://github.com/NousResearch/hermes-agent/pull/3864), [#3900](https://github.com/NousResearch/hermes-agent/pull/3900))
- **憑證檔案透傳文檔** —— 說明如何將憑證檔案與環境變數轉發至遠端後端 ([#3677](https://github.com/NousResearch/hermes-agent/pull/3677))
- **釐清 DuckDuckGo 需求** —— 註明對 duckduckgo-search 套件的運行時依賴 ([#3680](https://github.com/NousResearch/hermes-agent/pull/3680))
- **更新技能目錄** —— 新增紅隊測試類別與選用技能列表 ([#3745](https://github.com/NousResearch/hermes-agent/pull/3745))
- **修正飛書文檔 MDX 錯誤** —— 跳脫會破壞 Docusaurus 建置的尖括號 URL ([#3902](https://github.com/NousResearch/hermes-agent/pull/3902))

---

## 👥 貢獻者

### 核心團隊
- **@teknium1** —— 跨所有子系統共 90 個 PR

### 傑出社群貢獻者
- **@kshitijk4poor** —— 3 個 PR：Signal 電話號碼修復 ([#3670](https://github.com/NousResearch/hermes-agent/pull/3670))、parallel-cli 移至選用技能 ([#3673](https://github.com/NousResearch/hermes-agent/pull/3673))、狀態列折行修復 ([#3883](https://github.com/NousResearch/hermes-agent/pull/3883))
- **@winglian** —— 1 個 PR：插件訊息注入介面 ([#3778](https://github.com/NousResearch/hermes-agent/pull/3778))
- **@binhnt92** —— 1 個 PR：音訊下載重試邏輯 ([#3401](https://github.com/NousResearch/hermes-agent/pull/3401))
- **@0xbyt4** —— 1 個 PR：OpenClaw 遷移模型配置修復 ([#3924](https://github.com/NousResearch/hermes-agent/pull/3924))

### 解決社群回報 Issue
@Material-Scientist ([#850](https://github.com/NousResearch/hermes-agent/issues/850)), @hanxu98121 ([#1734](https://github.com/NousResearch/hermes-agent/issues/1734)), @penwyp ([#1788](https://github.com/NousResearch/hermes-agent/issues/1788)), @dan-and ([#1945](https://github.com/NousResearch/hermes-agent/issues/1945)), @AdrianScott ([#1963](https://github.com/NousResearch/hermes-agent/issues/1963)), @clawdbot47 ([#3229](https://github.com/NousResearch/hermes-agent/issues/3229)), @alanfwilliams ([#3404](https://github.com/NousResearch/hermes-agent/issues/3404)), @kentimsit ([#3433](https://github.com/NousResearch/hermes-agent/issues/3433)), @hayka-pacha ([#3534](https://github.com/NousResearch/hermes-agent/issues/3534)), @primmer ([#3595](https://github.com/NousResearch/hermes-agent/issues/3595)), @dagelf ([#3609](https://github.com/NousResearch/hermes-agent/issues/3609)), @HenkDz ([#3685](https://github.com/NousResearch/hermes-agent/issues/3685)), @tmdgusya ([#3729](https://github.com/NousResearch/hermes-agent/issues/3729)), @TypQxQ ([#3753](https://github.com/NousResearch/hermes-agent/issues/3753)), @acsezen ([#3765](https://github.com/NousResearch/hermes-agent/issues/3765))

---

**完整變更日誌**: [v2026.3.28...v2026.3.30](https://github.com/NousResearch/hermes-agent/compare/v2026.3.28...v2026.3.30)
