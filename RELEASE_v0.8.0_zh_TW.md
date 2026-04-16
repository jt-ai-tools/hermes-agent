# Hermes Agent v0.8.0 (v2026.4.8)

**發佈日期：** 2026 年 4 月 8 日

> 「智慧強化」的版本 —— 新增背景任務自動通知、Nous Portal 上的免費 MiMo v2 Pro、跨平台即時模型切換、自我優化的 GPT/Codex 引導、原生 Google AI Studio 支援、智慧不活動逾時、核准按鈕、MCP OAuth 2.1，以及 209 個已合併 PR 與 82 個已解決 Issue。

---

## ✨ 亮點更新

- **背景進程自動通知 (`notify_on_complete`)** —— 背景任務現在可以在完成時自動通知代理程式。啟動長時間運行的進程（如 AI 模型訓練、測試套件、部署、建置），代理程式將在完成時收到通知 —— 無需手動輪詢。代理程式可以繼續處理其他事務，並在結果出爐時隨時接手。([#5779](https://github.com/NousResearch/hermes-agent/pull/5779))

- **Nous Portal 支援免費 Xiaomi MiMo v2 Pro** —— Nous Portal 現在為輔助任務（壓縮、視覺、摘要）提供免費層級的 Xiaomi MiMo v2 Pro 模型，並在模型選擇中加入免費模型限制與價格顯示。([#6018](https://github.com/NousResearch/hermes-agent/pull/6018), [#5880](https://github.com/NousResearch/hermes-agent/pull/5880))

- **即時模型切換 (`/model` 指令)** —— 可在 CLI、Telegram、Discord、Slack 或任何網關平台對話中途切換模型與供應商。具備聚合器感知解析功能，盡可能優先使用 OpenRouter/Nous，並在需要時自動跨供應商回退。Telegram 與 Discord 提供具備內嵌按鈕的互動式模型選擇器。([#5181](https://github.com/NousResearch/hermes-agent/pull/5181), [#5742](https://github.com/NousResearch/hermes-agent/pull/5742))

- **自我優化的 GPT/Codex 工具調用引導** —— 代理程式透過自動化行為基準測試診斷並修復了 GPT 與 Codex 工具調用的 5 種失敗模式，顯著提升了在 OpenAI 模型上的可靠性。包含執行規範引導與結構化推理的「僅思考 (thinking-only)」預填續寫。([#6120](https://github.com/NousResearch/hermes-agent/pull/6120), [#5414](https://github.com/NousResearch/hermes-agent/pull/5414), [#5931](https://github.com/NousResearch/hermes-agent/pull/5931))

- **Google AI Studio (Gemini) 原生供應商** —— 透過 Google AI Studio API 直接存取 Gemini 模型。整合了自動化 models.dev 註冊表，實現跨供應商的即時上下文長度偵測。([#5577](https://github.com/NousResearch/hermes-agent/pull/5577))

- **基於活動的代理程式逾時** —— 網關與 Cron 逾時現在追蹤實際的工具活動，而非單純的掛鐘時間。長時間運行且正在活動的任務將不會被強制終止 —— 只有真正閒置的代理程式才會逾時。([#5389](https://github.com/NousResearch/hermes-agent/pull/5389), [#5440](https://github.com/NousResearch/hermes-agent/pull/5440))

- **Slack 與 Telegram 核准按鈕** —— 可透過平台的原生按鈕核准危險指令，無需輸入 `/approve`。Slack 支援討論串上下文保留；Telegram 則使用 Emoji 反應顯示核准狀態。([#5890](https://github.com/NousResearch/hermes-agent/pull/5890), [#5975](https://github.com/NousResearch/hermes-agent/pull/5975))

- **MCP OAuth 2.1 PKCE + OSV 惡意軟體掃描** —— 為 MCP 伺服器認證提供完整、符合標準的 OAuth 支援，並透過 OSV 漏洞資料庫自動掃描 MCP 擴充套件包。([#5420](https://github.com/NousResearch/hermes-agent/pull/5420), [#5305](https://github.com/NousResearch/hermes-agent/pull/5305))

- **集中式日誌與配置驗證** —— 結構化日誌記錄於 `~/.hermes/logs/` (agent.log + errors.log)，配合 `hermes logs` 指令進行追蹤與過濾。配置結構驗證可在啟動時捕捉錯誤的 YAML 格式，避免難以理解的失敗。([#5430](https://github.com/NousResearch/hermes-agent/pull/5430), [#5426](https://github.com/NousResearch/hermes-agent/pull/5426))

- **插件系統擴展** —— 插件現在可以註冊 CLI 子指令、接收具備關聯 ID 的請求級 API 鉤子、在安裝時提示必要的環境變數，並掛接到會話生命週期事件 (finalize/reset)。([#5295](https://github.com/NousResearch/hermes-agent/pull/5295), [#5427](https://github.com/NousResearch/hermes-agent/pull/5427), [#5470](https://github.com/NousResearch/hermes-agent/pull/5470), [#6129](https://github.com/NousResearch/hermes-agent/pull/6129))

- **Matrix 第一梯隊支援與平台強化** —— Matrix 新增反應、讀取回條、富文本格式與房間管理。Discord 增加了頻道控制與忽略頻道選項。Signal 支援完整的 MEDIA: 標籤遞送。Mattermost 支援檔案附件。各平台皆有全面的可靠性修復。([#5275](https://github.com/NousResearch/hermes-agent/pull/5275), [#5975](https://github.com/NousResearch/hermes-agent/pull/5975), [#5602](https://github.com/NousResearch/hermes-agent/pull/5602))

- **安全性強化週期** —— 整合了 SSRF 防護、計時攻擊緩解、Tar 遍歷預防、憑證洩漏保護、Cron 路徑遍歷強化以及跨會話隔離。所有後端的終端工作目錄皆經過清理。([#5944](https://github.com/NousResearch/hermes-agent/pull/5944), [#5613](https://github.com/NousResearch/hermes-agent/pull/5613), [#5629](https://github.com/NousResearch/hermes-agent/pull/5629))

---

## 🏗️ 核心代理與架構

### 供應商與模型支援
- **原生 Google AI Studio (Gemini) 供應商**，整合 models.dev 進行自動上下文長度偵測 ([#5577](https://github.com/NousResearch/hermes-agent/pull/5577))
- **`/model` 指令 —— 供應商與模型系統全面重構** —— 支援 CLI 與所有網關平台的即時切換，具備聚合器感知解析 ([#5181](https://github.com/NousResearch/hermes-agent/pull/5181))
- **Telegram 與 Discord 的互動式模型選擇器** —— 基於內嵌按鈕的模型選擇 ([#5742](https://github.com/NousResearch/hermes-agent/pull/5742))
- **Nous Portal 免費層級模型限制**，並在模型選擇中顯示價格 ([#5880](https://github.com/NousResearch/hermes-agent/pull/5880))
- 為 OpenRouter 與 Nous Portal 供應商**顯示模型價格** ([#5416](https://github.com/NousResearch/hermes-agent/pull/5416))
- 透過 `x-grok-conv-id` 標頭實現 **xAI (Grok) 提示詞快取** ([#5604](https://github.com/NousResearch/hermes-agent/pull/5604))
- **將 Grok 加入工具調用強制執行模型**，支援直接使用 xAI ([#5595](https://github.com/NousResearch/hermes-agent/pull/5595))
- **MiniMax TTS 供應商** (speech-2.8) ([#4963](https://github.com/NousResearch/hermes-agent/pull/4963))
- **非代理型模型警告** —— 當使用者載入非針對工具調用設計的模型時發出警告 ([#5378](https://github.com/NousResearch/hermes-agent/pull/5378))
- **Ollama Cloud 認證、/model 切換持久化**以及別名自動補全 ([#5269](https://github.com/NousResearch/hermes-agent/pull/5269))
- **保留 OpenCode Go 模型名稱中的點** (minimax-m2.7, glm-4.5, kimi-k2.5) ([#5597](https://github.com/NousResearch/hermes-agent/pull/5597))
- **MiniMax 模型 404 修復** —— 針對 OpenCode Go 從 Anthropic 基準 URL 中移除 /v1 ([#4918](https://github.com/NousResearch/hermes-agent/pull/4918))
- 在池化故障轉移中遵循**供應商憑證重置窗口** ([#5188](https://github.com/NousResearch/hermes-agent/pull/5188))
- 憑證池與憑證檔案間的 **OAuth Token 同步** ([#4981](https://github.com/NousResearch/hermes-agent/pull/4981))
- **過時的 OAuth 憑證**不再於自動偵測時阻擋 OpenRouter 使用者 ([#5746](https://github.com/NousResearch/hermes-agent/pull/5746))
- **Codex OAuth 憑證池斷開** + 過期 Token 匯入修復 ([#5681](https://github.com/NousResearch/hermes-agent/pull/5681))
- 憑證耗盡時從 `~/.codex/auth.json` 同步 **Codex 池分錄** —— @GratefulDave ([#5610](https://github.com/NousResearch/hermes-agent/pull/5610))
- **輔助用戶端付款回退** —— 遇到 402 錯誤時嘗試下一個供應商 ([#5599](https://github.com/NousResearch/hermes-agent/pull/5599))
- **輔助用戶端解析命名的自訂供應商**以及 'main' 別名 ([#5978](https://github.com/NousResearch/hermes-agent/pull/5978))
- 在 Nous 免費層級對非視覺輔助任務使用 **mimo-v2-pro** ([#6018](https://github.com/NousResearch/hermes-agent/pull/6018))
- **視覺自動偵測**優先嘗試主供應商 ([#6041](https://github.com/NousResearch/hermes-agent/pull/6041))
- **供應商重排序與快速安裝** —— @austinpickett ([#4664](https://github.com/NousResearch/hermes-agent/pull/4664))
- **Nous OAuth access_token** 不再作為推論 API 金鑰使用 —— @SHL0MS ([#5564](https://github.com/NousResearch/hermes-agent/pull/5564))
- Nous 登入時遵循 **HERMES_PORTAL_BASE_URL 環境變數** —— @benbarclay ([#5745](https://github.com/NousResearch/hermes-agent/pull/5745))
- 為 Nous portal/推論 URL 提供**環境變數覆蓋** ([#5419](https://github.com/NousResearch/hermes-agent/pull/5419))
- 透過探測與快取實現 **Z.AI 端點自動偵測** ([#5763](https://github.com/NousResearch/hermes-agent/pull/5763))
- **MiniMax 上下文長度、模型目錄、思考防護、輔助模型與配置基準 URL** 修正 ([#6082](https://github.com/NousResearch/hermes-agent/pull/6082))
- **社群供應商/模型解析修復** —— 整合了 4 個社群 PR + MiniMax 輔助 URL ([#5983](https://github.com/NousResearch/hermes-agent/pull/5983))

### 代理迴圈與對話
- 透過自動化行為基準測試實現 **GPT/Codex 工具調用自我優化引導** —— 代理程式自行診斷並修復了 5 種失敗模式 ([#6120](https://github.com/NousResearch/hermes-agent/pull/6120))
- 系統提示詞中新增 **GPT/Codex 執行規範引導** ([#5414](https://github.com/NousResearch/hermes-agent/pull/5414))
- 針對結構化推理回應提供**僅思考 (thinking-only) 預填續寫** ([#5931](https://github.com/NousResearch/hermes-agent/pull/5931))
- **接受僅含推理的回應**而無需重試 —— 將內容設為 "(empty)" 而非無限重試 ([#5278](https://github.com/NousResearch/hermes-agent/pull/5278))
- **抖動式重試退避** —— 針對 API 重試使用具備抖動 (jitter) 的指數退避 ([#6048](https://github.com/NousResearch/hermes-agent/pull/6048))
- **智慧思考塊簽章管理** —— 在回合間保留並管理 Anthropic 思考簽章 ([#6112](https://github.com/NousResearch/hermes-agent/pull/6112))
- **強制轉換工具調用參數**以符合 JSON Schema 類型 —— 修復傳送字串而非數字/布林值的模型問題 ([#5265](https://github.com/NousResearch/hermes-agent/pull/5265))
- **將過大的工具結果儲存至檔案**，而非進行破壞性的截斷 ([#5210](https://github.com/NousResearch/hermes-agent/pull/5210))
- **感知沙盒的工具結果持久化** ([#6085](https://github.com/NousResearch/hermes-agent/pull/6085))
- 編輯失敗後改進了**串流回退** ([#6110](https://github.com/NousResearch/hermes-agent/pull/6110))
- 在回退、正規化器與輔助用戶端中彌補了 **Codex 空輸出缺口** ([#5724](https://github.com/NousResearch/hermes-agent/pull/5724), [#5730](https://github.com/NousResearch/hermes-agent/pull/5730), [#5734](https://github.com/NousResearch/hermes-agent/pull/5734))
- 透過 output_item.done 事件進行 **Codex 串流輸出回填** ([#5689](https://github.com/NousResearch/hermes-agent/pull/5689))
- **串流取用者在工具邊界後建立新訊息** ([#5739](https://github.com/NousResearch/hermes-agent/pull/5739))
- **Codex 驗證與正規化對齊**，處理空串流輸出 ([#5940](https://github.com/NousResearch/hermes-agent/pull/5940))
- 在 copilot-acp 適配器中**橋接工具調用** ([#5460](https://github.com/NousResearch/hermes-agent/pull/5460))
- 從 chat-completions 負載中**過濾僅含逐字稿的編號 (roles)** ([#4880](https://github.com/NousResearch/hermes-agent/pull/4880))
- 修復溫度受限模型上的**上下文壓縮失敗**問題 —— @MadKangYu ([#5608](https://github.com/NousResearch/hermes-agent/pull/5608))
- **為所有嚴格 API 清理 tool_calls** (Fireworks, Mistral 等) —— @lumethegreat ([#5183](https://github.com/NousResearch/hermes-agent/pull/5183))

### 記憶與會話
- **Supermemory 記憶供應商** —— 全新的記憶插件，具備多容器、搜尋模式、身分模板與環境變數覆蓋 ([#5737](https://github.com/NousResearch/hermes-agent/pull/5737), [#5933](https://github.com/NousResearch/hermes-agent/pull/5933))
- 預設使用**共享討論串會話** —— 跨網關平台的多使用者討論串支援 ([#5391](https://github.com/NousResearch/hermes-agent/pull/5391))
- **子代理會話連結至父代理**並從會話列表中隱藏 ([#5309](https://github.com/NousResearch/hermes-agent/pull/5309))
- **個人檔案範圍的記憶隔離**與複製支援 ([#4845](https://github.com/NousResearch/hermes-agent/pull/4845))
- 將**網關 user_id 傳遞至記憶插件**，實現每使用者範圍劃分 ([#5895](https://github.com/NousResearch/hermes-agent/pull/5895))
- **Honcho 插件全面重構** + 插件 CLI 註冊系統 ([#5295](https://github.com/NousResearch/hermes-agent/pull/5295))
- 保留 **Honcho 全像提示詞與信任分數** 渲染 ([#4872](https://github.com/NousResearch/hermes-agent/pull/4872))
- **Honcho doctor 修復** —— 使用 recall_mode 而非 memory_mode —— @techguysimon ([#5645](https://github.com/NousResearch/hermes-agent/pull/5645))
- **RetainDB** —— API 路由、寫入佇列、辯證法、代理模型、檔案工具修復 ([#5461](https://github.com/NousResearch/hermes-agent/pull/5461))
- **Hindsight 記憶插件重構** + 記憶安裝精靈修復 ([#5094](https://github.com/NousResearch/hermes-agent/pull/5094))
- **mem0 API v2 相容**、預取上下文圍欄、機密遮蔽 ([#5423](https://github.com/NousResearch/hermes-agent/pull/5423))
- **mem0 環境變數與 mem0.json 合併**，而非二選一 ([#4939](https://github.com/NousResearch/hermes-agent/pull/4939))
- 所有記憶供應商操作皆使用**乾淨的使用者訊息** ([#4940](https://github.com/NousResearch/hermes-agent/pull/4940))
- 修復 /new 與 /resume 時的**靜默記憶排乾失敗**問題 —— @ryanautomated ([#5640](https://github.com/NousResearch/hermes-agent/pull/5640))
- 為會話提交提供 **OpenViking atexit 安全網** ([#5664](https://github.com/NousResearch/hermes-agent/pull/5664))
- 為多租戶伺服器提供 **OpenViking 租戶範圍標頭** ([#4936](https://github.com/NousResearch/hermes-agent/pull/4936))
- **ByteRover brv 查詢**在 LLM 呼叫前同步執行 ([#4831](https://github.com/NousResearch/hermes-agent/pull/4831))

---

## 📱 通訊平台 (網關)

### 網關核心
- **基於活動的代理程式逾時** —— 用智慧活動追蹤取代掛鐘時間逾時；長時間運行的活動任務絕不終止 ([#5389](https://github.com/NousResearch/hermes-agent/pull/5389))
- **Slack 與 Telegram 核准按鈕** + Slack 討論串上下文保留 ([#5890](https://github.com/NousResearch/hermes-agent/pull/5890))
- **即時串流 /update 輸出** + 向使用者轉發互動式提示 ([#5180](https://github.com/NousResearch/hermes-agent/pull/5180))
- **無限逾時支援** + 週期性通知 + 具備行動指引的錯誤訊息 ([#4959](https://github.com/NousResearch/hermes-agent/pull/4959))
- **重複訊息預防** —— 網關去重 + 部分串流防護 ([#4878](https://github.com/NousResearch/hermes-agent/pull/4878))
- **Webhook delivery_info 持久化** + /status 中完整的會話 ID ([#5942](https://github.com/NousResearch/hermes-agent/pull/5942))
- **工具預覽截斷**在 all/new 進度模式中遵循 tool_preview_length ([#5937](https://github.com/NousResearch/hermes-agent/pull/5937))
- 為 all/new 工具進度模式恢復**短預覽截斷** ([#4935](https://github.com/NousResearch/hermes-agent/pull/4935))
- **更新待處理狀態**改為原子寫入以防止損壞 ([#4923](https://github.com/NousResearch/hermes-agent/pull/4923))
- **核准會話金鑰依回合隔離** ([#4884](https://github.com/NousResearch/hermes-agent/pull/4884))
- **活動會話防護繞過**，適用於 /approve, /deny, /stop, /new ([#4926](https://github.com/NousResearch/hermes-agent/pull/4926), [#5765](https://github.com/NousResearch/hermes-agent/pull/5765))
- 核准等待期間**暫停輸入指示器** ([#5893](https://github.com/NousResearch/hermes-agent/pull/5893))
- **標題檢查**使用精確的逐行匹配，而非子字串匹配 (所有平台) ([#5939](https://github.com/NousResearch/hermes-agent/pull/5939))
- 從串流網關訊息中**去除 MEDIA: 標籤** ([#5152](https://github.com/NousResearch/hermes-agent/pull/5152))
- 發送前從 Cron 遞送中**擷取 MEDIA: 標籤** ([#5598](https://github.com/NousResearch/hermes-agent/pull/5598))
- **感知個人檔案的服務單元** + 語音轉錄清理 ([#5972](https://github.com/NousResearch/hermes-agent/pull/5972))
- 具備原子寫入功能的**執行緒安全 PairingStore** —— @CharlieKerfoot ([#5656](https://github.com/NousResearch/hermes-agent/pull/5656))
- 在基準平台日誌中**清理媒體 URL** —— @WAXLYY ([#5631](https://github.com/NousResearch/hermes-agent/pull/5631))
- **減少 Telegram 回退 IP 啟用日誌噪音** —— @MadKangYu ([#5615](https://github.com/NousResearch/hermes-agent/pull/5615))
- **Cron 靜態方法封裝**以防止自我綁定 ([#5299](https://github.com/NousResearch/hermes-agent/pull/5299))
- **過時的 'hermes login' 被取代**為 'hermes auth' + 憑證移除重新播種修復 ([#5670](https://github.com/NousResearch/hermes-agent/pull/5670))

### Telegram
- 超級群組論壇主題的**群組主題技能綁定** ([#4886](https://github.com/NousResearch/hermes-agent/pull/4886))
- 針對核准狀態與通知使用 **Emoji 反應** ([#5975](https://github.com/NousResearch/hermes-agent/pull/5975))
- **防止重複訊息遞送**，處理發送逾時情況 ([#5153](https://github.com/NousResearch/hermes-agent/pull/5153))
- **清理指令名稱**，去除無效字元 ([#5596](https://github.com/NousResearch/hermes-agent/pull/5596))
- Telegram 選單與網關分發遵循**依平台禁用的技能** ([#4799](https://github.com/NousResearch/hermes-agent/pull/4799))
- **/approve 與 /deny** 透過執行中代理程式防護進行路由 ([#4798](https://github.com/NousResearch/hermes-agent/pull/4798))

### Discord
- **頻道控制** —— ignored_channels 與 no_thread_channels 配置選項 ([#5975](https://github.com/NousResearch/hermes-agent/pull/5975))
- 透過共享網關邏輯將**技能註冊為原生斜線指令** ([#5603](https://github.com/NousResearch/hermes-agent/pull/5603))
- 將 **/approve, /deny, /queue, /background, /btw** 註冊為原生斜線指令 ([#4800](https://github.com/NousResearch/hermes-agent/pull/4800), [#5477](https://github.com/NousResearch/hermes-agent/pull/5477))
- 啟動時移除**不必要的成員 Intent** + Token 鎖洩漏修復 ([#5302](https://github.com/NousResearch/hermes-agent/pull/5302))

### Slack
- **討論串互動** —— 在機器人啟動的或被標記的討論串中自動回應 ([#5897](https://github.com/NousResearch/hermes-agent/pull/5897))
- **edit_message 支援 mrkdwn** + 無需 @mentions 的討論串回覆 ([#5733](https://github.com/NousResearch/hermes-agent/pull/5733))

### Matrix
- **第一梯隊功能對齊** —— 反應、讀取回條、富文本格式、房間管理 ([#5275](https://github.com/NousResearch/hermes-agent/pull/5275))
- 支援 **MATRIX_REQUIRE_MENTION 與 MATRIX_AUTO_THREAD** ([#5106](https://github.com/NousResearch/hermes-agent/pull/5106))
- **全面可靠性提升** —— 加密媒體、認證恢復、Cron E2EE、Synapse 相容 ([#5271](https://github.com/NousResearch/hermes-agent/pull/5271))
- **CJK 輸入、E2EE 與重新連線**修復 ([#5665](https://github.com/NousResearch/hermes-agent/pull/5665))

### Signal
- **完整的 MEDIA: 標籤遞送** —— 實作了 send_image_file, send_voice, 與 send_video ([#5602](https://github.com/NousResearch/hermes-agent/pull/5602))

### Mattermost
- **檔案附件** —— 當貼文有檔案附件時將訊息類型設為 DOCUMENT —— @nericervin ([#5609](https://github.com/NousResearch/hermes-agent/pull/5609))

### 飛書 (Feishu)
- **互動式卡片核准按鈕** ([#6043](https://github.com/NousResearch/hermes-agent/pull/6043))
- **重新連線與 ACL** 修復 ([#5665](https://github.com/NousResearch/hermes-agent/pull/5665))

### Webhooks
- **支援 `{__raw__}` 模板 Token** 以及論壇主題的 thread_id 透傳 ([#5662](https://github.com/NousResearch/hermes-agent/pull/5662))

---

## 🖥️ CLI 與使用者體驗

### 互動式 CLI
- **延遲回應內容**直到推理塊完成 ([#5773](https://github.com/NousResearch/hermes-agent/pull/5773))
- 終端縮放時**清除殘留狀態列** ([#4960](https://github.com/NousResearch/hermes-agent/pull/4960))
- **標準化貼上文字中的 \r\n 與 \r 換行符號** ([#4849](https://github.com/NousResearch/hermes-agent/pull/4849))
- **ChatConsole 錯誤、curses 捲動、皮膚感知橫幅、Git 狀態**橫幅修復 ([#5974](https://github.com/NousResearch/hermes-agent/pull/5974))
- 支援**原生 Windows 圖片貼上** ([#5917](https://github.com/NousResearch/hermes-agent/pull/5917))
- **--yolo 與其他旗標**若放在 'chat' 子指令前不再會被靜默捨棄 ([#5145](https://github.com/NousResearch/hermes-agent/pull/5145))

### 安裝與配置
- **配置結構驗證** —— 啟動時偵測錯誤的 YAML 格式並提供可操作的錯誤訊息 ([#5426](https://github.com/NousResearch/hermes-agent/pull/5426))
- **集中式日誌記錄**至 `~/.hermes/logs/` —— agent.log (INFO+), errors.log (WARNING+) 並配合 `hermes logs` 指令 ([#5430](https://github.com/NousResearch/hermes-agent/pull/5430))
- **安裝精靈各章節新增文檔連結** ([#5283](https://github.com/NousResearch/hermes-agent/pull/5283))
- **Doctor 診斷** —— 同步供應商檢查、配置遷移、WAL 與 mem0 診斷 ([#5077](https://github.com/NousResearch/hermes-agent/pull/5077))
- **逾時除錯日誌**與面向使用者的診斷改進 ([#5370](https://github.com/NousResearch/hermes-agent/pull/5370))
- **推理努力程度 (Reasoning effort) 統一**僅由 config.yaml 決定 ([#6118](https://github.com/NousResearch/hermes-agent/pull/6118))
- 啟動時載入**永久指令允許清單** ([#5076](https://github.com/NousResearch/hermes-agent/pull/5076))
- **`hermes auth remove`** 現在會永久清除環境播種的憑證 ([#5285](https://github.com/NousResearch/hermes-agent/pull/5285))
- 更新期間將**內建技能同步至所有個人檔案** ([#5795](https://github.com/NousResearch/hermes-agent/pull/5795))
- **`hermes update` 不再殺死**剛重啟的網關服務 ([#5448](https://github.com/NousResearch/hermes-agent/pull/5448))
- 所有網關 CLI 指令新增 **Subprocess.run() 逾時設定** ([#5424](https://github.com/NousResearch/hermes-agent/pull/5424))
- 修復當 Codex 刷新 Token 被重複使用時的**可操作錯誤訊息** —— @tymrtn ([#5612](https://github.com/NousResearch/hermes-agent/pull/5612))
- **Google Workspace 技能腳本**現在可以直接運行 —— @xinbenlv ([#5624](https://github.com/NousResearch/hermes-agent/pull/5624))

### Cron 系統
- **基於活動的 Cron 逾時** —— 取代掛鐘時間；活動中的任務可無限期運行 ([#5440](https://github.com/NousResearch/hermes-agent/pull/5440))
- 新增**運行前腳本注入**功能，用於資料收集與變更偵測 ([#5082](https://github.com/NousResearch/hermes-agent/pull/5082))
- 任務狀態中加入**遞送失敗追蹤** ([#6042](https://github.com/NousResearch/hermes-agent/pull/6042))
- Cron 提示詞中加入**遞送引導** —— 停止 send_message 的無效反覆 ([#5444](https://github.com/NousResearch/hermes-agent/pull/5444))
- **MEDIA 檔案**作為平台原生附件遞送 ([#5921](https://github.com/NousResearch/hermes-agent/pull/5921))
- **[SILENT] 抑制標籤**在回應中任何位置皆有效 —— @auspic7 ([#5654](https://github.com/NousResearch/hermes-agent/pull/5654))
- **Cron 路徑遍歷**強化 ([#5147](https://github.com/NousResearch/hermes-agent/pull/5147))

---

## 🔧 工具系統

### 終端與執行
- **遠端後端執行 execute_code** —— 程式碼執行現在可在 Docker, SSH, Modal 以及其他遠端終端後端運作 ([#5088](https://github.com/NousResearch/hermes-agent/pull/5088))
- 終端結果中加入常見 CLI 工具的**結束代碼上下文** —— 幫助代理程式理解出錯原因 ([#5144](https://github.com/NousResearch/hermes-agent/pull/5144))
- **漸進式子目錄提示偵測** —— 代理程式在導覽時學習專案結構 ([#5291](https://github.com/NousResearch/hermes-agent/pull/5291))
- **背景進程 notify_on_complete** —— 在長時間運行的任務完成時獲得通知 ([#5779](https://github.com/NousResearch/hermes-agent/pull/5779))
- **Docker 環境配置** —— 透過 docker_env 配置設定明確的容器環境變數 ([#4738](https://github.com/NousResearch/hermes-agent/pull/4738))
- 終端工具結果中**包含核准元資料** ([#5141](https://github.com/NousResearch/hermes-agent/pull/5141))
- 所有後端的終端工具皆**清理工作目錄參數** ([#5629](https://github.com/NousResearch/hermes-agent/pull/5629))
- 修正**分離進程崩潰恢復**狀態 ([#6101](https://github.com/NousResearch/hermes-agent/pull/6101))
- 保留**具備空格的代理瀏覽器路徑** —— @Vasanthdev2004 ([#6077](https://github.com/NousResearch/hermes-agent/pull/6077))
- macOS 上讀取圖片使用**便攜式 base64 編碼** —— @CharlieKerfoot ([#5657](https://github.com/NousResearch/hermes-agent/pull/5657))

### 瀏覽器
- **更換受管理瀏覽器供應商**，從 Browserbase 遷移至 Browser Use —— @benbarclay ([#5750](https://github.com/NousResearch/hermes-agent/pull/5750))
- **Firecrawl 雲端瀏覽器**供應商 —— @alt-glitch ([#5628](https://github.com/NousResearch/hermes-agent/pull/5628))
- 透過 browser_console 的 expression 參數進行 **JS 求值** ([#5303](https://github.com/NousResearch/hermes-agent/pull/5303))
- **Windows 瀏覽器**修復 ([#5665](https://github.com/NousResearch/hermes-agent/pull/5665))

### MCP
- **MCP OAuth 2.1 PKCE** —— 完整支援符合標準的 OAuth 用戶端 ([#5420](https://github.com/NousResearch/hermes-agent/pull/5420))
- MCP 擴充套件包的 **OSV 惡意軟體檢查** ([#5305](https://github.com/NousResearch/hermes-agent/pull/5305))
- **優先使用 structuredContent 而非 text** + no_mcp 標記 ([#5979](https://github.com/NousResearch/hermes-agent/pull/5979))
- 針對 MCP 伺服器名稱**抑制未知工具集警告** ([#5279](https://github.com/NousResearch/hermes-agent/pull/5279))

### 網頁與檔案
- **支援 .zip 文件** + 自動掛載快取目錄至遠端後端 ([#4846](https://github.com/NousResearch/hermes-agent/pull/4846))
- 在 send_message 錯誤中**遮蔽查詢機密資訊** —— @WAXLYY ([#5650](https://github.com/NousResearch/hermes-agent/pull/5650))

### 委派
- 為子代理提供**憑證池共享** + 工作區路徑提示 ([#5748](https://github.com/NousResearch/hermes-agent/pull/5748))

### ACP (VS Code / Zed / JetBrains)
- **綜合 ACP 改進** —— 認證相容性、協定修復、指令宣告、委派、SSE 事件 ([#5292](https://github.com/NousResearch/hermes-agent/pull/5292))

---

## 🧩 技能生態系統

### 技能系統
- **技能配置介面** —— 技能可以宣告需要的 config.yaml 設定，在安裝時提示並在載入時注入 ([#5635](https://github.com/NousResearch/hermes-agent/pull/5635))
- **插件 CLI 註冊系統** —— 插件可註冊自己的 CLI 子指令而無需修改 main.py ([#5295](https://github.com/NousResearch/hermes-agent/pull/5295))
- 插件可使用具備工具調用關聯 ID 的**請求級 API 鉤子** ([#5427](https://github.com/NousResearch/hermes-agent/pull/5427))
- **會話生命週期鉤子** —— 為 CLI + 網關提供 on_session_finalize 與 on_session_reset ([#6129](https://github.com/NousResearch/hermes-agent/pull/6129))
- 插件安裝時**提示必要的環境變數** —— @kshitijk4poor ([#5470](https://github.com/NousResearch/hermes-agent/pull/5470))
- **插件名稱驗證** —— 拒絕解析至插件根目錄的名稱 ([#5368](https://github.com/NousResearch/hermes-agent/pull/5368))
- **pre_llm_call 插件上下文**移至使用者訊息以保留提示詞快取 ([#5146](https://github.com/NousResearch/hermes-agent/pull/5146))

### 新增與更新技能
- **popular-web-designs** —— 54 個生產環境網頁設計系統 ([#5194](https://github.com/NousResearch/hermes-agent/pull/5194))
- **p5js 創意程式碼** —— @SHL0MS ([#5600](https://github.com/NousResearch/hermes-agent/pull/5600))
- **manim-video** —— 數學與技術動畫 —— @SHL0MS ([#4930](https://github.com/NousResearch/hermes-agent/pull/4930))
- **llm-wiki** —— Karpathy 的 LLM Wiki 技能 ([#5635](https://github.com/NousResearch/hermes-agent/pull/5635))
- **gitnexus-explorer** —— 程式碼庫索引與知識服務 ([#5208](https://github.com/NousResearch/hermes-agent/pull/5208))
- **research-paper-writing** —— AI-Scientist 與 GPT-Researcher 模式 —— @SHL0MS ([#5421](https://github.com/NousResearch/hermes-agent/pull/5421))
- **blogwatcher** 更新至 JulienTant 的分支 ([#5759](https://github.com/NousResearch/hermes-agent/pull/5759))
- **claude-code 技能** 全面重寫 v2.0 + v2.2 ([#5155](https://github.com/NousResearch/hermes-agent/pull/5155), [#5158](https://github.com/NousResearch/hermes-agent/pull/5158))
- **程式碼驗證技能** 整合為一個 ([#4854](https://github.com/NousResearch/hermes-agent/pull/4854))
- **Manim CE 參考文件** 擴充 —— 幾何、動畫、LaTeX —— @leotrs ([#5791](https://github.com/NousResearch/hermes-agent/pull/5791))
- **Manim-video 參考資料** —— 設計思考、更新器、論文解釋器、裝飾、生產品質 —— @SHL0MS ([#5588](https://github.com/NousResearch/hermes-agent/pull/5588), [#5408](https://github.com/NousResearch/hermes-agent/pull/5408))

---

## 🔒 安全性與可靠性

### 安全性強化
- **整合安全性** —— SSRF 防護、計時攻擊緩解、Tar 遍歷預防、憑證洩漏防護 ([#5944](https://github.com/NousResearch/hermes-agent/pull/5944))
- **跨會話隔離** + Cron 路徑遍歷強化 ([#5613](https://github.com/NousResearch/hermes-agent/pull/5613))
- 所有後端的終端工具皆**清理工作目錄參數** ([#5629](https://github.com/NousResearch/hermes-agent/pull/5629))
- 防止核准的 **'once' 會話升級** + Cron 遞送平台驗證 ([#5280](https://github.com/NousResearch/hermes-agent/pull/5280))
- 保護**個人檔案範圍的 Google Workspace OAuth Token** ([#4910](https://github.com/NousResearch/hermes-agent/pull/4910))

### 可靠性
- **積極清理工作樹 (worktree) 與分支**以防止堆積 ([#6134](https://github.com/NousResearch/hermes-agent/pull/6134))
- 修復遮蔽正則表達式中的 **O(n²) 災難性回溯** —— 在大型輸出上提升了 100 倍效能 ([#4962](https://github.com/NousResearch/hermes-agent/pull/4962))
- 核心、網頁、委派與瀏覽器工具的**運行時穩定性修復** ([#4843](https://github.com/NousResearch/hermes-agent/pull/4843))
- **API 伺服器串流修復** + 對話歷史支援 ([#5977](https://github.com/NousResearch/hermes-agent/pull/5977))
- 修正 **OpenViking API 端點路徑**與回應解析 ([#5078](https://github.com/NousResearch/hermes-agent/pull/5078))

---

## 🐛 重大 Bug 修復

- **整合 9 個社群 Bug 修復** —— 網關、Cron、依賴、macOS launchd ([#5288](https://github.com/NousResearch/hermes-agent/pull/5288))
- **批量核心 Bug 修復** —— 模型配置、會話重置、別名回退、launchctl、委派、原子寫入 ([#5630](https://github.com/NousResearch/hermes-agent/pull/5630))
- **批量網關/平台修復** —— Matrix E2EE、CJK 輸入、Windows 瀏覽器、飛書重新連線 + ACL ([#5665](https://github.com/NousResearch/hermes-agent/pull/5665))
- **移除過時的測試略過**，修復正則回溯、檔案搜尋 Bug 與測試不穩定性 ([#4969](https://github.com/NousResearch/hermes-agent/pull/4969))
- **Nix Flake** —— 讀取版本、重新生成 uv.lock、新增 hermes_logging —— @alt-glitch ([#5651](https://github.com/NousResearch/hermes-agent/pull/5651))
- **小寫變數遮蔽**回歸測試 ([#5185](https://github.com/NousResearch/hermes-agent/pull/5185))

---

## 🧪 測試

- 修復 14 個檔案中 **57 個失敗的 CI 測試** ([#5823](https://github.com/NousResearch/hermes-agent/pull/5823))
- **測試套件重構** + CI 失敗修復 —— @alt-glitch ([#5946](https://github.com/NousResearch/hermes-agent/pull/5946))
- **全程式碼庫 Lint 清理** —— 移除未使用的匯入、無效程式碼與低效模式 ([#5821](https://github.com/NousResearch/hermes-agent/pull/5821))
- **移除 browser_close 工具** —— 改由自動清理處理 ([#5792](https://github.com/NousResearch/hermes-agent/pull/5792))

---

## 📚 文檔更新

- **全面文檔審核** —— 修正過時資訊、擴充薄弱頁面、增加深度 ([#5393](https://github.com/NousResearch/hermes-agent/pull/5393))
- 修正了文檔與程式碼庫之間的 **40 多處差異** ([#5818](https://github.com/NousResearch/hermes-agent/pull/5818))
- 為上週 PR 中的 **13 項功能編寫文檔** ([#5815](https://github.com/NousResearch/hermes-agent/pull/5815))
- **指南章節重構** —— 修正現有內容並新增 3 個教學 ([#5735](https://github.com/NousResearch/hermes-agent/pull/5735))
- **整合 4 個文檔 PR** —— Docker 安裝、更新後驗證、本地 LLM 指南、signal-cli 安裝 ([#5727](https://github.com/NousResearch/hermes-agent/pull/5727))
- **Discord 配置參考** ([#5386](https://github.com/NousResearch/hermes-agent/pull/5386))
- 新增常見工作流與疑難排解的**社群 FAQ 條目** ([#4797](https://github.com/NousResearch/hermes-agent/pull/4797))
- 本地模型伺服器的 **WSL2 網路指南** ([#5616](https://github.com/NousResearch/hermes-agent/pull/5616))
- **Honcho CLI 參考** + 插件 CLI 註冊文件 ([#5308](https://github.com/NousResearch/hermes-agent/pull/5308))
- llm-wiki 中新增伺服器的 **Obsidian Headless 安裝** ([#5660](https://github.com/NousResearch/hermes-agent/pull/5660))
- 皮膚頁面新增 **Hermes Mod 視覺化皮膚編輯器** ([#6095](https://github.com/NousResearch/hermes-agent/pull/6095))

---

## 👥 貢獻者

### 核心團隊
- **@teknium1** —— 179 個 PR

### 傑出社群貢獻者
- **@SHL0MS** (7 個 PR) —— p5js 創意程式碼技能、manim-video 技能 + 5 個參考資料擴充、論文寫作、Nous OAuth 修復、manim 字型修復
- **@alt-glitch** (3 個 PR) —— Firecrawl 雲端瀏覽器供應商、測試重構 + CI 修復、Nix flake 修復
- **@benbarclay** (2 個 PR) —— Browser Use 受管理供應商切換、Nous portal 基準 URL 修復
- **@CharlieKerfoot** (2 個 PR) —— macOS 便攜式 base64 編碼、執行緒安全 PairingStore
- **@WAXLYY** (2 個 PR) —— send_message 機密遮蔽、網關媒體 URL 清理
- **@MadKangYu** (2 個 PR) —— Telegram 日誌噪音減少、溫度受限模型的上下文壓縮修復

### 所有貢獻者
@alt-glitch, @austinpickett, @auspic7, @benbarclay, @CharlieKerfoot, @GratefulDave, @kshitijk4poor, @leotrs, @lumethegreat, @MadKangYu, @nericervin, @ryanautomated, @SHL0MS, @techguysimon, @tymrtn, @Vasanthdev2004, @WAXLYY, @xinbenlv

---

**完整變更日誌**: [v2026.4.3...v2026.4.8](https://github.com/NousResearch/hermes-agent/compare/v2026.4.3...v2026.4.8)
