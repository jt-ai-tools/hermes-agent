# Hermes Agent v0.2.0 (v2026.3.12)

**發佈日期：** 2026 年 3 月 12 日

> 自 v0.1.0 (最初的內部預發佈版本) 以來的首個正式標記版本。在短短兩週內，感謝社群貢獻的爆發，Hermes Agent 從一個小型的內部專案演變成功能齊全的 AI 代理平台。本版本包含來自 **63 位貢獻者** 的 **216 個已合併 PR**，解決了 **119 個 Issue**。

---

## ✨ 亮點更新

- **多平台通訊網關** —— 支援 Telegram, Discord, Slack, WhatsApp, Signal, 電子郵件 (IMAP/SMTP) 以及 Home Assistant 平台。具備統一的會話管理、媒體附件支援以及針對各個平台的工具配置功能。

- **MCP (模型內容協定) 用戶端** —— 原生支援 MCP，具備 stdio 與 HTTP 傳輸、重新連線、資源與提示詞發現，以及取樣 (Sampling，由伺服器發起的 LLM 請求) 功能。([#291] —— 由 @0xbyt4 貢獻, [#301], [#753])

- **技能 (Skills) 生態系統** —— 提供超過 70 個內建與選用技能，涵蓋 15 個以上類別。具備供社群發現的技能中心 (Skills Hub)、各平台啟用/禁用、基於工具可用性的條件觸發以及先決條件驗證功能。([#743] —— 由 @teyrebaz33 貢獻, [#785] —— 由 @teyrebaz33 貢獻)

- **集中式供應商路由器** —— 統一的 `call_llm()`/`async_call_llm()` API 取代了散佈於視覺、摘要、壓縮與軌跡儲存中的供應商邏輯。所有輔助取用者皆透過單一程式碼路徑路由，並支援自動憑證解析。([#1003](https://github.com/NousResearch/hermes-agent/pull/1003))

- **ACP 伺服器** —— 透過代理通訊協定 (Agent Communication Protocol) 標準實現與 VS Code, Zed 及 JetBrains 編輯器的整合。([#949](https://github.com/NousResearch/hermes-agent/pull/949))

- **CLI 皮膚/主題引擎** —— 資料驅動的視覺自訂：橫幅、加載圖示、顏色、品牌化。提供 7 款內建皮膚並支援自訂 YAML 皮膚。

- **Git 工作樹 (Worktree) 隔離** —— `hermes -w` 指令可在 Git 工作樹中啟動隔離的代理會話，實現在同一倉庫中安全地進行並行開發。([#654](https://github.com/NousResearch/hermes-agent/pull/654))

- **檔案系統檢查點與回滾** —— 執行具破壞性的操作前會自動建立快照，並可透過 `/rollback` 進行還原。([#824](https://github.com/NousResearch/hermes-agent/pull/824))

- **3,289 個測試** —— 從幾乎為零的測試覆蓋率，發展至涵蓋代理、網關、工具、Cron 與 CLI 的全面測試套件。

---

## 🏗️ 核心代理與架構

### 供應商與模型支援
- 具備 `resolve_provider_client()` + `call_llm()` API 的集中式供應商路由器 ([#1003])
- Nous Portal 在安裝過程中成為一等公民供應商 ([#644])
- OpenAI Codex (Responses API) 支援 ChatGPT 訂閱 ([#43]) —— 由 @grp06 貢獻
- Codex OAuth 視覺支援 + 多模態內容適配器
- 針對即時 API 驗證 `/model`，而非使用硬編碼列表
- 支援自託管 Firecrawl ([#460]) —— 由 @caentzminger 貢獻
- 支援 Kimi Code API ([#635]) —— 由 @christomitov 貢獻
- MiniMax 模型 ID 更新 ([#473]) —— 由 @tars90percent 貢獻
- OpenRouter 供應商路由配置 (provider_preferences)
- 遇到 401 錯誤時自動重新整理 Nous 憑證 ([#571], [#269]) —— 由 @rewbs 貢獻
- z.ai/GLM, Kimi/Moonshot, MiniMax, Azure OpenAI 加入一等公民供應商
- 統整 `/model` 與 `/provider` 為單一檢視介面

### 代理迴圈與對話
- 用於增強供應商復原能力的簡易回退模型 ([#740])
- 父代理與子代理委派間共享的迭代預算
- 透過工具結果注入產生的迭代預算壓力感應
- 可配置具備完整憑證解析功能的子代理供應商/模型
- 上下文過大 (413) 時透過壓縮處理而非直接放棄 ([#153]) —— 由 @tekelala 貢獻
- 壓縮後使用重新建構的負載進行重試 ([#616]) —— 由 @tripledoublev 貢獻
- 自動壓縮異常龐大的網關會話 ([#628])
- 工具調用修復中間件 —— 自動小寫化與無效工具處理
- 推理努力程度配置與 `/reasoning` 指令 ([#921])
- 上下文壓縮後偵測並阻擋檔案重複讀取/搜尋的無窮迴圈 ([#705]) —— 由 @0xbyt4 貢獻

### 會話與記憶
- 具備唯一標題、自動世系、豐富列表與按名稱恢復功能的會話命名系統 ([#720])
- 具備搜尋過濾功能的互動式會話瀏覽器 ([#733])
- 恢復會話時顯示先前的訊息內容 ([#734])
- Honcho AI 原生跨會話使用者建模 ([#38]) —— 由 @erosika 貢獻
- 會話過期時的主動非同步記憶排乾
- 智慧上下文長度探測，具備持久化快取與橫幅顯示功能
- 用於切換至具名會話的 `/resume` 指令 (網關模式)
- 通訊平台的會話重置政策

---

## 📱 通訊平台 (網關)

### Telegram
- 原生檔案附件：send_document + send_video
- 支援 PDF、文字與 Office 檔案的文件處理 —— 由 @tekelala 貢獻
- 論壇主題會話隔離 ([#766]) —— 由 @spanishflu-est1918 貢獻
- 透過 MEDIA: 協定分享瀏覽器螢幕截圖 ([#657])
- 為 find-nearby 技能提供位置資訊支援
- 修復 TTS 語音訊息累積問題 ([#176]) —— 由 @Bartok9 貢獻
- 改進錯誤處理與日誌記錄 ([#763]) —— 由 @aydnOktay 貢獻
- 斜體正則表達式換行修復 + 43 個格式測試 ([#204]) —— 由 @0xbyt4 貢獻

### Discord
- 會話上下文中包含頻道主題 ([#248]) —— 由 @Bartok9 貢獻
- DISCORD_ALLOW_BOTS 配置用於機器人訊息過濾 ([#758])
- 支援文件與影片傳送 ([#784])
- 改進錯誤處理與日誌記錄 ([#761]) —— 由 @aydnOktay 貢獻

### Slack
- App_mention 404 修復 + 支援文件/影片 ([#784])
- 以結構化日誌取代 print 語句 —— 由 @aydnOktay 貢獻

### WhatsApp
- 原生媒體發送 —— 圖片、影片、文件 ([#292]) —— 由 @satelerd 貢獻
- 多使用者會話隔離 ([#75]) —— 由 @satelerd 貢獻
- 跨平台端口清理，取代僅限 Linux 的 fuser ([#433]) —— 由 @Farukest 貢獻
- 私訊中斷鍵不匹配修復 ([#350]) —— 由 @Farukest 貢獻

### Signal
- 透過 signal-cli-rest-api 實現完整的 Signal 網關 ([#405])
- 訊息事件支援媒體 URL ([#871])

### 電子郵件 (IMAP/SMTP)
- 新增電子郵件網關平台 —— 由 @0xbyt4 貢獻

### Home Assistant
- REST 工具 + WebSocket 網關整合 ([#184]) —— 由 @0xbyt4 貢獻
- 服務發現與增強型安裝流程
- 工具集映射修復 ([#538]) —— 由 @Himess 貢獻

### 網關核心
- 向使用者公開子代理工具調用與思考過程 ([#186]) —— 由 @cutepawss 貢獻
- 可配置的背景進程監視器通知 ([#840])
- 為 Telegram/Discord/Slack 提供具備回退機制的 `edit_message()`
- `/compress`, `/usage`, `/update` 斜線指令
- 消除網關會話中 3 倍的 SQLite 訊息重複 ([#873])
- 網關回合間穩定系統提示詞以提升快取命中率 ([#754])
- 網關退出時關閉 MCP 伺服器 ([#796]) —— 由 @0xbyt4 貢獻
- 將 session_db 傳遞給 AIAgent，修復 session_search 錯誤 ([#108]) —— 由 @Bartok9 貢獻
- 在 /retry, /undo 中持久化逐字稿變更；修復 /reset 屬性 ([#217]) —— 由 @Farukest 貢獻
- UTF-8 編碼修復，防止 Windows 崩潰 ([#369]) —— 由 @ch3ronsa 貢獻

---

## 🖥️ CLI 與使用者體驗

### 互動式 CLI
- 資料驅動的皮膚/主題引擎 —— 內建 7 款皮膚 (default, ares, mono, slate, poseidon, sisyphus, charizard) + 自訂 YAML 皮膚
- `/personality` 指令，支援自訂人格與禁用功能 ([#773]) —— 由 @teyrebaz33 貢獻
- 使用者定義的快速指令，可繞過代理迴圈 ([#746]) —— 由 @teyrebaz33 貢獻
- `/reasoning` 指令用於設定努力程度與切換顯示 ([#921])
- `/verbose` 斜線指令用於運行時切換除錯模式 ([#94]) —— 由 @cesareth 貢獻
- `/insights` 指令 —— 用量分析、成本估計與活動模式 ([#552])
- `/background` 指令用於管理背景進程
- `/help` 格式化，按類別歸納指令
- 完成時響鈴 —— 代理程式結束時發出終端鈴聲 ([#738])
- 上/下方向鍵瀏覽歷史紀錄
- 剪貼簿圖片貼上 (Alt+V / Ctrl+V)
- 為執行緩慢的斜線指令新增加載指示器 ([#882])
- 修復 patch_stdout 下的加載圖示閃爍問題 ([#91]) —— 由 @0xbyt4 貢獻
- `--quiet/-Q` 旗標用於程式化單次查詢模式
- `--fuck-it-ship-it` 旗標用於繞過所有核准提示 ([#724]) —— 由 @dmahan93 貢獻
- 工具摘要旗標 ([#767]) —— 由 @luisv-1 貢獻
- 修復 SSH 環境下的終端閃爍 ([#284]) —— 由 @ygd58 貢獻
- 多行貼上偵測修復 ([#84]) —— 由 @0xbyt4 貢獻

### 安裝與配置
- 模組化安裝精靈，具備章節子指令與工具優先的 UX
- 容器資源配置提示
- 針對必要二進位檔案的後端驗證
- 配置遷移系統 (目前為 v7)
- API 金鑰正確路由至 .env 而非 config.yaml ([#469]) —— 由 @ygd58 貢獻
- .env 採用原子寫入，防止崩潰時遺失金鑰 ([#954])
- `hermes tools` —— 具備 curses UI 的每平台工具啟用/禁用
- `hermes doctor` 用於對所有已配置供應商進行健康檢查
- `hermes update` 支援網關服務自動重啟
- CLI 橫幅中顯示更新可用通知
- 支援多個具名的自訂供應商
- 改進 Shell 配置偵測以進行 PATH 設定 ([#317]) —— 由 @mehmetkr-31 貢獻
- 統一的 HERMES_HOME 與 .env 路徑解析 ([#51], [#48]) —— 由 @deankerr 貢獻
- 修復 macOS 上的 Docker 後端問題 + 為 Nous Portal 提供的子代理認證 ([#46]) —— 由 @rsavitt 貢獻

---

## 🔧 工具系統

### MCP (模型內容協定)
- 支援 stdio + HTTP 傳輸的原生 MCP 用戶端 ([#291] —— 由 @0xbyt4 貢獻, [#301])
- 支援取樣 (Sampling) —— 由伺服器發起的 LLM 請求 ([#753])
- 資源與提示詞發現
- 自動重新連線與安全性強化
- 橫幅整合、`/reload-mcp` 指令
- `hermes tools` UI 整合

### 瀏覽器
- 本地瀏覽器後端 —— 零成本的無頭 Chromium (無需 Browserbase)
- 控制台/錯誤工具、具備註解的螢幕截圖、自動錄影、QA 測試技能 ([#745])
- 透過 MEDIA: 在所有通訊平台上分享螢幕截圖 ([#657])

### 終端與執行
- `execute_code` 沙盒，具備 json_parse, shell_quote, 重試輔助功能
- Docker：自訂卷宗掛載 ([#158]) —— 由 @Indelwin 貢獻
- Daytona 雲端沙盒後端 ([#451]) —— 由 @rovle 貢獻
- SSH 後端修復 ([#59]) —— 由 @deankerr 貢獻
- Shell 噪音過濾與登入 Shell 執行，確保環境一致性
- execute_code 標準輸出溢出時的頭尾截斷處理
- 可配置的背景進程通知模式

### 檔案操作
- 檔案系統檢查點與 `/rollback` 指令 ([#824])
- 為 patch 與 search_files 提供結構化的工具結果提示 (下一步引導) ([#722])
- Docker 卷宗傳遞至沙盒容器配置 ([#687]) —— 由 @manuelschipper 貢獻

---

## 🧩 技能生態系統

### 技能系統
- 每平台技能啟用/禁用功能 ([#743]) —— 由 @teyrebaz33 貢獻
- 基於工具可用性的條件式技能啟用 ([#785]) —— 由 @teyrebaz33 貢獻
- 技能先決條件 —— 隱藏依賴項未滿足的技能 ([#659]) —— 由 @kshitijk4poor 貢獻
- 選用技能 —— 已隨附但預設不啟用的技能
- `hermes skills browse` —— 分頁式中心瀏覽
- 技能子類別組織
- 平台條件式技能加載
- 技能檔案原子寫入 ([#551]) —— 由 @aydnOktay 貢獻
- 技能同步資料遺失防護 ([#563]) —— 由 @0xbyt4 貢獻
- 為 CLI 與網關提供動態技能斜線指令

### 新技能 (精選)
- **ASCII 藝術** —— pyfiglet (571 種字體), cowsay, 圖片轉 ASCII ([#209]) —— 由 @0xbyt4 貢獻
- **ASCII 影片** —— 完整的生產管線 ([#854]) —— 由 @SHL0MS 貢獻
- **DuckDuckGo 搜尋** —— Firecrawl 回退方案 ([#267]) —— 由 @gamedevCloudy 貢獻；DDGS API 擴充 ([#598]) —— 由 @areu01or00 貢獻
- **Solana 區塊鏈** —— 錢包餘額、美元價格、代幣名稱 ([#212]) —— 由 @gizdusum 貢獻
- **AgentMail** —— 代理程式擁有的電子郵件信箱 ([#330]) —— 由 @teyrebaz33 貢獻
- **Polymarket** —— 預測市場資料 (唯讀) ([#629])
- **OpenClaw 遷移** —— 官方遷移工具 ([#570]) —— 由 @unmodeled-tyler 貢獻
- **網域情報 (Domain Intelligence)** —— 被動偵察：子網域、SSL、WHOIS、DNS ([#136]) —— 由 @FurkanL0 貢獻
- **Superpowers** —— 軟體開發技能 ([#137]) —— 由 @kaos35 貢獻
- **Hermes-Atropos** —— RL 環境開發技能 ([#815])
- 此外還有：arXiv 搜尋、OCR/文件、Excalidraw 圖表、YouTube 逐字稿、GIF 搜尋、神奇寶貝玩家、我的世界 (Minecraft) 模組包伺服器、OpenHue (飛利浦 Hue)、Google Workspace、Notion、PowerPoint、Obsidian、尋找附近，以及 40 多個 MLOps 技能。

---

## 🔒 安全性與可靠性

### 安全性強化
- skill_view 中的路徑遍歷修復 —— 防止讀取任意檔案 ([#220]) —— 由 @Farukest 貢獻
- sudo 密碼管道傳遞中的 Shell 注入防禦 ([#65]) —— 由 @leonsgithub 貢獻
- 危險指令偵測：修復多行繞過問題 ([#233]) —— 由 @Farukest 貢獻；tee/進程替換模式 ([#280]) —— 由 @dogiladeveloper 貢獻
- skills_guard 中的符號連結邊界檢查修復 ([#386]) —— 由 @Farukest 貢獻
- macOS 寫入禁用清單中的符號連結繞過修復 ([#61]) —— 由 @0xbyt4 貢獻
- 防止多詞提示詞注入繞過 ([#192]) —— 由 @0xbyt4 貢獻
- Cron 提示詞注入掃描器繞過修復 ([#63]) —— 由 @0xbyt4 貢獻
- 對敏感檔案強制執行 0600/0700 檔案權限 ([#757])
- .env 檔案權限限制為僅限擁有者 ([#529]) —— 由 @Himess 貢獻
- `--force` 旗標已正確阻擋其覆蓋危險判定結果 ([#388]) —— 由 @Farukest 貢獻
- FTS5 查詢清理 + 資料庫連線洩漏修復 ([#565]) —— 由 @0xbyt4 貢獻
- 擴充機密資訊遮蔽模式 + 提供禁用配置開關
- 記憶體內的永久允許清單，防止資料洩漏 ([#600]) —— 由 @alireza78a 貢獻

### 原子寫入 (防止資料遺失)
- sessions.json ([#611]) —— 由 @alireza78a 貢獻
- Cron 任務 ([#146]) —— 由 @alireza78a 貢獻
- .env 配置 ([#954])
- 進程檢查點 ([#298]) —— 由 @aydnOktay 貢獻
- 批次執行器 (Batch runner) ([#297]) —— 由 @aydnOktay 貢獻
- 技能檔案 ([#551]) —— 由 @aydnOktay 貢獻

### 可靠性
- 針對 systemd/無頭環境，保護所有 print() 呼叫防止 OSError ([#963])
- 在 `run_conversation` 開始時重置所有重試計數器 ([#607]) —— 由 @0xbyt4 貢獻
- 核准回呼逾時後回傳拒絕而非 None ([#603]) —— 由 @0xbyt4 貢獻
- 修復全程式碼庫中 None 訊息內容導致的崩潰 ([#277])
- 修復本地 LLM 後端上下文溢出導致的崩潰 ([#403]) —— 由 @ch3ronsa 貢獻
- 防止 `_flush_sentinel` 洩漏至外部 API ([#227]) —— 由 @Farukest 貢獻
- 防止呼叫端對 `conversation_history` 的篡改 ([#229]) —— 由 @Farukest 貢獻
- 修復 systemd 重啟迴圈問題 ([#614]) —— 由 @voidborne-d 貢獻
- 關閉檔案控制代碼與 Socket 以防止描述符洩漏 ([#568] —— 由 @alireza78a, [#296] —— 由 @alireza78a, [#709] —— 由 @memosr 貢獻)
- 防止剪貼簿 PNG 轉換時的資料遺失 ([#602]) —— 由 @0xbyt4 貢獻
- 消除終端輸出中的 Shell 噪音 ([#293]) —— 由 @0xbyt4 貢獻
- 為提示詞、Cron 與 execute_code 提供感知時區的 now() 函數 ([#309]) —— 由 @areu01or00 貢獻

### Windows 相容性
- 保護僅限 POSIX 的進程函數 ([#219]) —— 由 @Farukest 貢獻
- 透過 Git Bash 支援原生 Windows + ZIP 格式更新回退機制
- 支援 PTY 的 pywinpty ([#457]) —— 由 @shitcoinsherpa 貢獻
- 對所有配置/資料檔案 I/O 強制執行 UTF-8 編碼 ([#458]) —— 由 @shitcoinsherpa 貢獻
- 相容 Windows 的路徑處理 ([#354], [#390]) —— 由 @Farukest 貢獻
- 針對磁碟機代號路徑的基於 Regex 的搜尋輸出解析 ([#533]) —— 由 @Himess 貢獻
- Windows 認證儲存檔案鎖 ([#455]) —— 由 @shitcoinsherpa 貢獻

---

## 🐛 重大 Bug 修復

- 修復 DeepSeek V3 工具調用解析器靜默捨棄多行 JSON 參數的問題 ([#444]) —— 由 @PercyDikec 貢獻
- 修復網關逐字稿因偏移量不匹配導致每回合遺失 1 條訊息的問題 ([#395]) —— 由 @PercyDikec 貢獻
- 修復 /retry 指令靜默捨棄代理程式最終回應的問題 ([#441]) —— 由 @PercyDikec 貢獻
- 修復最大迭代重試在剔除思考塊後回傳空字串的問題 ([#438]) —— 由 @PercyDikec 貢獻
- 修復最大迭代重試使用硬編碼 max_tokens 的問題 ([#436]) —— 由 @Farukest 貢獻
- 修復 Codex 狀態字典鍵值不匹配 ([#448]) 與可見性過濾問題 ([#446]) —— 由 @PercyDikec 貢獻
- 從最終面向使用者的回應中去除 \<think\> 標籤 ([#174]) —— 由 @Bartok9 貢獻
- 修復 \<think\> 標籤正則表達式在模型字面上討論標籤時會誤刪內容的問題 ([#786])
- 修復助理訊息中殘留的 finish_reason 導致的 Mistral 422 錯誤 ([#253]) —— 由 @Sertug17 貢獻
- 修復全程式碼路徑中 OPENROUTER_API_KEY 的解析順序 ([#295]) —— 由 @0xbyt4 貢獻
- 修復 OPENAI_BASE_URL API 金鑰優先級問題 ([#420]) —— 由 @manuelschipper 貢獻
- 修復 Anthropic 「提示詞太長」 400 錯誤未被偵測為上下文長度錯誤的問題 ([#813])
- 修復 SQLite 會話逐字稿累積重複訊息導致 Token 膨脹 3-4 倍的問題 ([#860])
- 修復安裝精靈在首次安裝時跳過 API 金鑰提示的問題 ([#748])
- 修復安裝精靈為 Nous Portal 顯示 OpenRouter 模型列表的問題 ([#575]) —— 由 @PercyDikec 貢獻
- 修復透過 hermes model 切換時供應商選擇未持久化的問題 ([#881])
- 修復 macOS 上 docker 不在 PATH 時 Docker 後端失敗的問題 ([#889])
- 修復 ClawHub 技能中心適配器因 API 端點變更導致的問題 ([#286]) —— 由 @BP602 貢獻
- 修復 API 金鑰存在時 Honcho 的自動啟用問題 ([#243]) —— 由 @Bartok9 貢獻
- 修復 Python 3.11+ 上重複的 'skills' 子解析器導致的崩潰問題 ([#898])
- 修復記憶工具在內容包含章節符號 (§) 時的條目解析問題 ([#162]) —— 由 @aydnOktay 貢獻
- 修復管道安裝在互動提示失敗時靜默中止的問題 ([#72]) —— 由 @cutepawss 貢獻
- 修復遞迴刪除偵測中的誤報 ([#68]) —— 由 @cutepawss 貢獻
- 修復全程式碼庫的 Ruff lint 警告 ([#608]) —— 由 @JackTheGit 貢獻
- 修復 Anthropic 原生基準 URL 的快速報錯機制 ([#173]) —— 由 @adavyas 貢獻
- 修復 install.sh 在移動 Node.js 目錄前就建立 ~/.hermes 的問題 ([#53]) —— 由 @JoshuaMart 貢獻
- 修復 Ctrl+C 退出清理期間引發的 SystemExit 堆疊追蹤 ([#55]) —— 由 @bierlingm 貢獻
- 恢復缺失的 MIT 授權檔案 ([#620]) —— 由 @stablegenius49 貢獻

---

## 🧪 測試

- 涵蓋代理、網關、工具、Cron 與 CLI 的 **3,289 個測試**
- 透過 pytest-xdist 實現並行化測試套件 ([#802]) —— 由 @OutThisLife 貢獻
- 單元測試批次 1：8 個核心模組 ([#60]) —— 由 @0xbyt4 貢獻
- 單元測試批次 2：另 8 個模組 ([#62]) —— 由 @0xbyt4 貢獻
- 單元測試批次 3：8 個未測試模組 ([#191]) —— 由 @0xbyt4 貢獻
- 單元測試批次 4：5 個安全性/邏輯關鍵模組 ([#193]) —— 由 @0xbyt4 貢獻
- AIAgent (run_agent.py) 單元測試 ([#67]) —— 由 @0xbyt4 貢獻
- 軌跡壓縮器測試 ([#203]) —— 由 @0xbyt4 貢獻
- 澄清工具測試 ([#121]) —— 由 @Bartok9 貢獻
- Telegram 格式測試 —— 43 個關於斜體/粗體/程式碼渲染的測試 ([#204]) —— 由 @0xbyt4 貢獻
- 視覺工具型別提示 + 42 個測試 ([#792])
- 壓縮器工具調用邊界回歸測試 ([#648]) —— 由 @intertwine 貢獻
- 測試結構重組 ([#34]) —— 由 @0xbyt4 貢獻
- 消除 Shell 噪音 + 修復 36 個測試失敗 ([#293]) —— 由 @0xbyt4 貢獻

---

## 🔬 RL 與評估環境

- WebResearchEnv —— 多步驟網頁研究 RL 環境 ([#434]) —— 由 @jackx707 貢獻
- Modal 沙盒並行限制，避免死鎖 ([#621]) —— 由 @voteblake 貢獻
- 內建 hermes-atropos-environments 技能 ([#815])
- 支援評估用的本地 vLLM 實例 —— 由 @dmahan93 貢獻
- YC-Bench 長時程代理基準測試環境
- OpenThoughts-TBLite 評估環境與腳本

---

## 📚 文檔更新

- 完整的文檔網站 (Docusaurus)，包含 37 頁以上內容
- 提供 Telegram, Discord, Slack, WhatsApp, Signal, Email 的詳細平台安裝指南
- AGENTS.md —— AI 程式碼助手的開發指南
- CONTRIBUTING.md ([#117]) —— 由 @Bartok9 貢獻
- 斜線指令參考資料 ([#142]) —— 由 @Bartok9 貢獻
- AGENTS.md 準確性全面稽核 ([#732])
- 皮膚/主題系統文件
- MCP 文檔與範例
- 文檔準確性稽核 —— 35 處以上修正
- 文檔錯字修正 ([#825], [#439]) —— 由 @JackTheGit 貢獻
- CLI 配置優先級與術語標準化 ([#166], [#167], [#168]) —— 由 @Jr-kenny 貢獻
- Telegram Token 正則表達式文檔 ([#713]) —— 由 @VolodymyrBg 貢獻

---

## 👥 貢獻者

感謝讓本版本成為可能的 63 位貢獻者！在短短兩週內，Hermes Agent 社群齊心協力完成了極其大量的工作。

### 核心團隊
- **@teknium1** —— 43 PRs：專案負責人、核心架構、供應商路由器、會話、技能、CLI、文檔

### 傑出社群貢獻者
- **@0xbyt4** —— 40 PRs：MCP 用戶端、Home Assistant、安全修復 (符號連結、提示詞注入、Cron)、廣泛的測試覆蓋 (6 個批次)、ASCII 藝術技能、消除 Shell 噪音、技能同步、Telegram 格式化等數十項貢獻。
- **@Farukest** —— 16 PRs：安全性強化 (路徑遍歷、危險指令偵測、符號連結邊界)、Windows 相容性 (POSIX 保護、路徑處理)、WhatsApp 修復、最大迭代重試、網關修復。
- **@aydnOktay** —— 11 PRs：原子寫入 (進程檢查點、批次執行器、技能檔案)、Telegram, Discord, 程式碼執行, 轉錄, TTS 與技能的錯誤處理改進。
- **@Bartok9** —— 9 PRs：CONTRIBUTING.md、斜線指令參考、Discord 頻道主題、思考塊去除、TTS 修復、Honcho 修復、會話計數修復、測試澄清。
- **@PercyDikec** —— 7 PRs：DeepSeek V3 解析器修復、/retry 回應捨棄、網關逐字稿偏移、Codex 狀態/可見性、最大迭代重試、安裝精靈修復。
- **@teyrebaz33** —— 5 PRs：技能啟用/禁用系統、快速指令、人格自訂、條件式技能啟用。
- **@alireza78a** —— 5 PRs：原子寫入 (Cron, 會話)、描述符洩漏預防、安全允許清單、程式碼執行 Socket 清理。
- **@shitcoinsherpa** —— 3 PRs：Windows 支援 (pywinpty, UTF-8 編碼, 認證儲存鎖)。
- **@Himess** —— 3 PRs：Cron/HomeAssistant/Daytona 修復、Windows 磁碟機代號解析、.env 權限。
- **@satelerd** —— 2 PRs：WhatsApp 原生媒體傳送、多使用者會話隔離。
- **@rovle** —— 1 PR：Daytona 雲端沙盒後端 (4 個 commit)。
- **@erosika** —— 1 PR：Honcho AI 原生記憶整合。
- **@dmahan93** —— 1 PR：--fuck-it-ship-it 旗標 + RL 環境開發。
- **@SHL0MS** —— 1 PR：ASCII 影片技能。

### 所有貢獻者
@0xbyt4, @BP602, @Bartok9, @Farukest, @FurkanL0, @Himess, @Indelwin, @JackTheGit, @JoshuaMart, @Jr-kenny, @OutThisLife, @PercyDikec, @SHL0MS, @Sertug17, @VencentSoliman, @VolodymyrBg, @adavyas, @alireza78a, @areu01or00, @aydnOktay, @batuhankocyigit, @bierlingm, @caentzminger, @cesareth, @ch3ronsa, @christomitov, @cutepawss, @deankerr, @dmahan93, @dogiladeveloper, @dragonkhoi, @erosika, @gamedevCloudy, @gizdusum, @grp06, @intertwine, @jackx707, @jdblackstar, @johnh4098, @kaos35, @kshitijk4poor, @leonsgithub, @luisv-1, @manuelschipper, @mehmetkr-31, @memosr, @PeterFile, @rewbs, @rovle, @rsavitt, @satelerd, @spanishflu-est1918, @stablegenius49, @tars90percent, @tekelala, @teknium1, @teyrebaz33, @tripledoublev, @unmodeled-tyler, @voidborne-d, @voteblake, @ygd58

---

**完整變更日誌**: [v0.1.0...v2026.3.12](https://github.com/NousResearch/hermes-agent/compare/v0.1.0...v2026.3.12)
