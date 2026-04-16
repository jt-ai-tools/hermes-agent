# Hermes Agent v0.4.0 (v2026.3.23)

**發佈日期：** 2026 年 3 月 23 日

> 「平台擴展」的版本 —— 新增相容 OpenAI 的 API 伺服器、6 個新通訊適配器、4 個新推論供應商、具備 OAuth 2.1 的 MCP 伺服器管理、@ 上下文引用功能、網關提示詞快取、預設啟用串流模式，以及包含 200 多項 Bug 修復的全面可靠性提升。

---

## ✨ 亮點更新

- **相容 OpenAI 的 API 伺服器** —— 將 Hermes 作為 `/v1/chat/completions` 端點公開，並新增用於 Cron 任務管理的 `/api/jobs` REST API。具備輸入限制、欄位白名單、SQLite 驅動的回應持久化以及 CORS 來源保護。([#1756](https://github.com/NousResearch/hermes-agent/pull/1756), [#2450](https://github.com/NousResearch/hermes-agent/pull/2450), [#2456](https://github.com/NousResearch/hermes-agent/pull/2456), [#2451](https://github.com/NousResearch/hermes-agent/pull/2451), [#2472](https://github.com/NousResearch/hermes-agent/pull/2472))

- **6 個新通訊平台適配器** —— Signal, 釘釘 (DingTalk), SMS (Twilio), Mattermost, Matrix 與 Webhook 適配器加入了 Telegram, Discord 與 WhatsApp 的行列。網關支援對失敗平台進行具備指數退避機制的自動重新連線。([#2206](https://github.com/NousResearch/hermes-agent/pull/2206), [#1685](https://github.com/NousResearch/hermes-agent/pull/1685), [#1688](https://github.com/NousResearch/hermes-agent/pull/1688), [#1683](https://github.com/NousResearch/hermes-agent/pull/1683), [#2166](https://github.com/NousResearch/hermes-agent/pull/2166), [#2584](https://github.com/NousResearch/hermes-agent/pull/2584))

- **@ 上下文引用** —— 支援類似 Claude Code 的 `@file` 與 `@url` 上下文注入，並在 CLI 中提供 Tab 自動補全。([#2343](https://github.com/NousResearch/hermes-agent/pull/2343), [#2482](https://github.com/NousResearch/hermes-agent/pull/2482))

- **4 個新推論供應商** —— GitHub Copilot (OAuth + 權杖驗證)、阿里雲 / DashScope、Kilo Code 以及 OpenCode Zen/Go。([#1924](https://github.com/NousResearch/hermes-agent/pull/1924), [#1879](https://github.com/NousResearch/hermes-agent/pull/1879) 由 @mchzimm 貢獻, [#1673](https://github.com/NousResearch/hermes-agent/pull/1673), [#1666](https://github.com/NousResearch/hermes-agent/pull/1666), [#1650](https://github.com/NousResearch/hermes-agent/pull/1650))

- **MCP 伺服器管理 CLI** —— 透過 `hermes mcp` 指令安裝、配置與驗證 MCP 伺服器，支援完整的 OAuth 2.1 PKCE 流程。([#2465](https://github.com/NousResearch/hermes-agent/pull/2465))

- **網關提示詞快取** —— 為每個會話快取 AIAgent 實例，跨回合保留 Anthropic 提示詞快取，大幅降低長對話成本。([#2282](https://github.com/NousResearch/hermes-agent/pull/2282), [#2284](https://github.com/NousResearch/hermes-agent/pull/2284), [#2361](https://github.com/NousResearch/hermes-agent/pull/2361))

- **上下文壓縮重構** —— 結構化摘要與迭代更新、Token 預算末端保護、可配置的摘要端點，以及回退模型支援。([#2323](https://github.com/NousResearch/hermes-agent/pull/2323), [#1727](https://github.com/NousResearch/hermes-agent/pull/1727), [#2224](https://github.com/NousResearch/hermes-agent/pull/2224))

- **預設啟用串流模式** —— CLI 預設開啟串流，並在串流期間正確顯示加載圖示/工具進度。包含大量換行與拼接修復。([#2340](https://github.com/NousResearch/hermes-agent/pull/2340), [#2161](https://github.com/NousResearch/hermes-agent/pull/2161), [#2258](https://github.com/NousResearch/hermes-agent/pull/2258))

---

## 🖥️ CLI 與使用者體驗

### 新指令與互動
- **@ 上下文補全** —— 支援 Tab 補全的 `@file`/`@url` 引用，可將檔案內容或網頁注入對話。([#2482](https://github.com/NousResearch/hermes-agent/pull/2482), [#2343](https://github.com/NousResearch/hermes-agent/pull/2343))
- **`/statusbar`** —— 切換顯示於提示符號上方的持久配置列，顯示模型與供應商資訊。([#2240](https://github.com/NousResearch/hermes-agent/pull/2240), [#1917](https://github.com/NousResearch/hermes-agent/pull/1917))
- **`/queue`** —— 在不中斷目前執行的情況下為代理程式排入新的提示詞。([#2191](https://github.com/NousResearch/hermes-agent/pull/2191), [#2469](https://github.com/NousResearch/hermes-agent/pull/2469))
- **`/permission`** —— 在會話期間動態切換核准模式。([#2207](https://github.com/NousResearch/hermes-agent/pull/2207))
- **`/browser`** —— 從 CLI 開啟互動式瀏覽器會話。([#2273](https://github.com/NousResearch/hermes-agent/pull/2273), [#1814](https://github.com/NousResearch/hermes-agent/pull/1814))
- **`/cost`** —— 在網關模式中即時追蹤價格與用量。([#2180](https://github.com/NousResearch/hermes-agent/pull/2180))
- **`/approve` 與 `/deny`** —— 將網關中的純文字核准取代為明確的指令。([#2002](https://github.com/NousResearch/hermes-agent/pull/2002))

### 串流與顯示
- CLI 預設啟用串流功能 ([#2340](https://github.com/NousResearch/hermes-agent/pull/2340))
- 串流模式下顯示加載圖示與工具進度 ([#2161](https://github.com/NousResearch/hermes-agent/pull/2161))
- 啟用 `show_reasoning` 時顯示推理/思考塊 ([#2118](https://github.com/NousResearch/hermes-agent/pull/2118))
- 為 CLI 與網關新增上下文壓力警告 ([#2159](https://github.com/NousResearch/hermes-agent/pull/2159))
- 修復：串流區塊拼接時缺失空格的問題 ([#2258](https://github.com/NousResearch/hermes-agent/pull/2258))
- 修復：迭代邊界換行防止串流拼接 ([#2413](https://github.com/NousResearch/hermes-agent/pull/2413))
- 修復：延遲串流換行以防止空行堆疊 ([#2473](https://github.com/NousResearch/hermes-agent/pull/2473))
- 修復：非 TTY 環境下抑制加載圖示動畫 ([#2216](https://github.com/NousResearch/hermes-agent/pull/2216))
- 修復：API 錯誤訊息中顯示供應商與端點資訊 ([#2266](https://github.com/NousResearch/hermes-agent/pull/2266))
- 修復：解決狀態列列印時亂碼的 ANSI 轉義序列 ([#2448](https://github.com/NousResearch/hermes-agent/pull/2448))
- 修復：將金色 ANSI 顏色更新為真彩色格式 ([#2246](https://github.com/NousResearch/hermes-agent/pull/2246))
- 修復：正規化工具集標籤並在橫幅中使用皮膚顏色 ([#1912](https://github.com/NousResearch/hermes-agent/pull/1912))

### CLI 優化
- 修復：防止退出時顯示「按 ENTER 鍵繼續...」 ([#2555](https://github.com/NousResearch/hermes-agent/pull/2555))
- 修復：代理迴圈期間刷新 stdout 以防止 macOS 顯示凍結 ([#1654](https://github.com/NousResearch/hermes-agent/pull/1654))
- 修復：當 `hermes setup` 遇到權限錯誤時顯示人類可讀的錯誤訊息 ([#2196](https://github.com/NousResearch/hermes-agent/pull/2196))
- 修復：`/stop` 指令崩潰 + 串流媒體遞送中的 UnboundLocalError ([#2463](https://github.com/NousResearch/hermes-agent/pull/2463))
- 修復：支援無需 API 金鑰的自訂/本地端點 ([#2556](https://github.com/NousResearch/hermes-agent/pull/2556))
- 修復：嘗試為 Ghostty/WezTerm 支援 Kitty 鍵盤協定的 Shift+Enter (因 prompt_toolkit 崩潰而撤回) ([#2345](https://github.com/NousResearch/hermes-agent/pull/2345), [#2349](https://github.com/NousResearch/hermes-agent/pull/2349))

### 配置
- config.yaml 支援 **`${ENV_VAR}` 變數替換** ([#2684](https://github.com/NousResearch/hermes-agent/pull/2684))
- **即時配置重載** —— config.yaml 變更無需重啟即可生效 ([#2210](https://github.com/NousResearch/hermes-agent/pull/2210))
- **`custom_models.yaml`** 供使用者自行管理新增的模型 ([#2214](https://github.com/NousResearch/hermes-agent/pull/2214))
- **基於優先級的上下文檔案選擇** + 支援 CLAUDE.md ([#2301](https://github.com/NousResearch/hermes-agent/pull/2301))
- 配置更新時**合併嵌套 YAML 章節**，而非直接替換 ([#2213](https://github.com/NousResearch/hermes-agent/pull/2213))
- 修復：config.yaml 中的 provider 鍵會靜默覆蓋環境變數 ([#2272](https://github.com/NousResearch/hermes-agent/pull/2272))
- 修復：紀錄配置錯誤警告而非靜默吞掉 config.yaml 錯誤 ([#2683](https://github.com/NousResearch/hermes-agent/pull/2683))
- 修復：已禁用的工具集在執行 `hermes tools` 後會自行重新啟用 ([#2268](https://github.com/NousResearch/hermes-agent/pull/2268))
- 修復：平台預設工具集會靜默覆蓋取消選取的工具 ([#2624](https://github.com/NousResearch/hermes-agent/pull/2624))
- 修復：遵循 YAML 中的 `approvals.mode: off` 設定 ([#2620](https://github.com/NousResearch/hermes-agent/pull/2620))
- 修復：`hermes update` 支援帶有回退機制的 `.[all]` 額外組件 ([#1728](https://github.com/NousResearch/hermes-agent/pull/1728))
- 修復：`hermes update` 在 Stash 衝突時重置工作樹前會進行提示 ([#2390](https://github.com/NousResearch/hermes-agent/pull/2390))
- 修復：更新/安裝時使用 git pull --rebase 以避免分歧分支錯誤 ([#2274](https://github.com/NousResearch/hermes-agent/pull/2274))
- 修復：在全新的 macOS 安裝上新增 zprofile 回退並建立 zshrc ([#2320](https://github.com/NousResearch/hermes-agent/pull/2320))
- 修復：移除 `ANTHROPIC_BASE_URL` 環境變數以避免衝突 ([#1675](https://github.com/NousResearch/hermes-agent/pull/1675))
- 修復：若密碼已存在於 Keyring 或環境變數，不再詢問 IMAP 密碼 ([#2212](https://github.com/NousResearch/hermes-agent/pull/2212))
- 修復：OpenCode Zen/Go 曾顯示 OpenRouter 模型而非自己的模型 ([#2277](https://github.com/NousResearch/hermes-agent/pull/2277))

---

## 🏗️ 核心代理與架構

### 新供應商
- **GitHub Copilot** —— 完整的 OAuth 認證、API 路由、權杖驗證與 400k 上下文支援。([#1924](https://github.com/NousResearch/hermes-agent/pull/1924), [#1896](https://github.com/NousResearch/hermes-agent/pull/1896), [#1879](https://github.com/NousResearch/hermes-agent/pull/1879) 由 @mchzimm 貢獻, [#2507](https://github.com/NousResearch/hermes-agent/pull/2507))
- **阿里雲 / DashScope** —— 完整整合 DashScope v1 運行時、保留模型名稱中的點、修復 401 認證問題 ([#1673](https://github.com/NousResearch/hermes-agent/pull/1673), [#2332](https://github.com/NousResearch/hermes-agent/pull/2332), [#2459](https://github.com/NousResearch/hermes-agent/pull/2459))
- **Kilo Code** —— 一等公民級別的推論供應商 ([#1666](https://github.com/NousResearch/hermes-agent/pull/1666))
- **OpenCode Zen 與 OpenCode Go** —— 新的供應商後端 ([#1650](https://github.com/NousResearch/hermes-agent/pull/1650), [#2393](https://github.com/NousResearch/hermes-agent/pull/2393) 由 @0xbyt4 貢獻)
- **NeuTTS** —— 內建安裝流程的本地 TTS 供應商後端，取代舊有的選用技能 ([#1657](https://github.com/NousResearch/hermes-agent/pull/1657), [#1664](https://github.com/NousResearch/hermes-agent/pull/1664))

### 供應商改進
- 遇到頻率限制錯誤時，**主動回退**至備援模型 ([#1730](https://github.com/NousResearch/hermes-agent/pull/1730))
- 為自訂模型提供**端點元資料**（上下文與價格）；支援查詢本地伺服器的實際上下文視窗大小 ([#1906](https://github.com/NousResearch/hermes-agent/pull/1906), [#2091](https://github.com/NousResearch/hermes-agent/pull/2091) 由 @dusterbloom 貢獻)
- **上下文長度偵測重構** —— 整合 models.dev、感知供應商的解析機制、針對自訂端點的模糊匹配、支援 llama.cpp 的 `/v1/props` ([#2158](https://github.com/NousResearch/hermes-agent/pull/2158), [#2051](https://github.com/NousResearch/hermes-agent/pull/2051), [#2403](https://github.com/NousResearch/hermes-agent/pull/2403))
- **模型目錄更新** —— 加入 gpt-5.4-mini, gpt-5.4-nano, healer-alpha, haiku-4.5, minimax-m2.7, 以及支援 1M 上下文的 Claude 4.6 ([#1913](https://github.com/NousResearch/hermes-agent/pull/1913), [#1915](https://github.com/NousResearch/hermes-agent/pull/1915), [#1900](https://github.com/NousResearch/hermes-agent/pull/1900), [#2155](https://github.com/NousResearch/hermes-agent/pull/2155), [#2474](https://github.com/NousResearch/hermes-agent/pull/2474))
- **自訂端點改進** —— 支援 config.yaml 中的 `model.base_url`、針對 Responses API 的 `api_mode` 覆蓋、允許無需 API 金鑰的端點、針對缺失金鑰快速報錯 ([#2330](https://github.com/NousResearch/hermes-agent/pull/2330), [#1651](https://github.com/NousResearch/hermes-agent/pull/1651), [#2556](https://github.com/NousResearch/hermes-agent/pull/2556), [#2445](https://github.com/NousResearch/hermes-agent/pull/2445), [#1994](https://github.com/NousResearch/hermes-agent/pull/1994), [#1998](https://github.com/NousResearch/hermes-agent/pull/1998))
- 在系統提示詞中注入模型與供應商資訊 ([#1929](https://github.com/NousResearch/hermes-agent/pull/1929))
- 將 `api_mode` 綁定至供應商配置，而非環境變數 ([#1656](https://github.com/NousResearch/hermes-agent/pull/1656))
- 修復：防止 Anthropic 權杖洩漏至第三方 `anthropic_messages` 供應商 ([#2389](https://github.com/NousResearch/hermes-agent/pull/2389))
- 修復：防止 Anthropic 回退機制繼承非 Anthropic 的 `base_url` ([#2388](https://github.com/NousResearch/hermes-agent/pull/2388))
- 修復：`auxiliary_is_nous` 旗標永不重置 —— 導致 Nous 標籤洩漏至其他供應商 ([#1713](https://github.com/NousResearch/hermes-agent/pull/1713))
- 修復：Anthropic `tool_choice 'none'` 仍允許工具調用的問題 ([#1714](https://github.com/NousResearch/hermes-agent/pull/1714))
- 修復：Mistral 解析器嵌套 JSON 的回退擷取 ([#2335](https://github.com/NousResearch/hermes-agent/pull/2335))
- 修復：透過預設使用 `anthropic_messages` 解決 MiniMax 401 認證問題 ([#2103](https://github.com/NousResearch/hermes-agent/pull/2103))
- 修復：不分大小寫的模型家族匹配 ([#2350](https://github.com/NousResearch/hermes-agent/pull/2350))
- 修復：在啟用檢查中忽略佔位符供應商金鑰 ([#2358](https://github.com/NousResearch/hermes-agent/pull/2358))
- 修復：在上下文長度偵測中保留 Ollama model:tag 的冒號 ([#2149](https://github.com/NousResearch/hermes-agent/pull/2149))
- 修復：在啟動檢查中識別 Claude Code OAuth 憑證 ([#1663](https://github.com/NousResearch/hermes-agent/pull/1663))
- 修復：動態偵測 Claude Code 版本以用於 OAuth User-Agent ([#1670](https://github.com/NousResearch/hermes-agent/pull/1670))
- 修復：重新整理/回退後 OAuth 旗標過時的問題 ([#1890](https://github.com/NousResearch/hermes-agent/pull/1890))
- 修復：輔助用戶端跳過已過期的 Codex JWT ([#2397](https://github.com/NousResearch/hermes-agent/pull/2397))

### 代理迴圈
- **網關提示詞快取** —— 按會話快取 AIAgent、保留助手回合、修復會話恢復 ([#2282](https://github.com/NousResearch/hermes-agent/pull/2282), [#2284](https://github.com/NousResearch/hermes-agent/pull/2284), [#2361](https://github.com/NousResearch/hermes-agent/pull/2361))
- **上下文壓縮重構** —— 結構化摘要、迭代更新、Token 預算末端保護、可配置的 `summary_base_url` ([#2323](https://github.com/NousResearch/hermes-agent/pull/2323), [#1727](https://github.com/NousResearch/hermes-agent/pull/1727), [#2224](https://github.com/NousResearch/hermes-agent/pull/2224))
- **呼叫前清理與呼叫後工具護欄** ([#1732](https://github.com/NousResearch/hermes-agent/pull/1732))
- **自動恢復**供應商拒絕的 `tool_choice`（嘗試不帶此參數重試） ([#2174](https://github.com/NousResearch/hermes-agent/pull/2174))
- **背景記憶/技能審查**取代了行內提醒 ([#2235](https://github.com/NousResearch/hermes-agent/pull/2235))
- **SOUL.md 作為主代理身分**，取代硬編碼的預設值 ([#1922](https://github.com/NousResearch/hermes-agent/pull/1922))
- 修復：防止上下文壓縮期間靜默遺失工具結果 ([#1993](https://github.com/NousResearch/hermes-agent/pull/1993))
- 修復：工具調用恢復中處理空/null 函數參數 ([#2163](https://github.com/NousResearch/hermes-agent/pull/2163))
- 修復：優雅處理 API 拒絕回應，而非直接崩潰 ([#2156](https://github.com/NousResearch/hermes-agent/pull/2156))
- 修復：防止代理程式在格式錯誤的工具調用上卡住 ([#2114](https://github.com/NousResearch/hermes-agent/pull/2114))
- 修復：向模型回傳 JSON 解析錯誤，而非傳送空參數進行分發 ([#2342](https://github.com/NousResearch/hermes-agent/pull/2342))
- 修復：連續助訊息合併在處理混合類型時捨棄內容的問題 ([#1703](https://github.com/NousResearch/hermes-agent/pull/1703))
- 修復：JSON 恢復與錯誤處理程序中違反訊息角色交替規律的問題 ([#1722](https://github.com/NousResearch/hermes-agent/pull/1722))
- 修復：`compression_attempts` 在每次迭代時重置 —— 導致無限次壓縮 ([#1723](https://github.com/NousResearch/hermes-agent/pull/1723))
- 修復：`length_continue_retries` 永不重置 —— 後續截斷獲得的重試次數減少 ([#1717](https://github.com/NousResearch/hermes-agent/pull/1717))
- 修復：壓縮器摘要角色違反了連續角色限制 ([#1720](https://github.com/NousResearch/hermes-agent/pull/1720), [#1743](https://github.com/NousResearch/hermes-agent/pull/1743))
- 修復：移除硬編碼的 `gemini-3-flash-preview` 作為預設摘要模型 ([#2464](https://github.com/NousResearch/hermes-agent/pull/2464))
- 修復：正確處理空的工具結果 ([#2201](https://github.com/NousResearch/hermes-agent/pull/2201))
- 修復：`tool_calls` 列表中出現 None 條目時的崩潰 ([#2209](https://github.com/NousResearch/hermes-agent/pull/2209) 由 @0xbyt4 貢獻, [#2316](https://github.com/NousResearch/hermes-agent/pull/2316))
- 修復：工作執行緒中每執行緒獨立的持久事件迴圈 ([#2214](https://github.com/NousResearch/hermes-agent/pull/2214) 由 @jquesnelle 貢獻)
- 修復：防止多個非同步工具並行執行時出現「事件迴圈已在運行」的錯誤 ([#2207](https://github.com/NousResearch/hermes-agent/pull/2207))
- 修復：從源頭去除 ANSI 碼 —— 在終端輸出到達模型前進行清理 ([#2115](https://github.com/NousResearch/hermes-agent/pull/2115))
- 修復：針對 OpenRouter 跳過 role:tool 上的頂層 `cache_control` ([#2391](https://github.com/NousResearch/hermes-agent/pull/2391))
- 修復：委派工具 —— 在建立子代理前儲存父代理工具名稱，防止全域變數被篡改 ([#2083](https://github.com/NousResearch/hermes-agent/pull/2083) 由 @ygd58 貢獻, [#1894](https://github.com/NousResearch/hermes-agent/pull/1894))
- 修復：僅在最後一條助手訊息為空字串時才將其剔除 ([#2326](https://github.com/NousResearch/hermes-agent/pull/2326))

### 會話與記憶
- **會話搜尋**與管理斜線指令 ([#2198](https://github.com/NousResearch/hermes-agent/pull/2198))
- **自動會話標題**與 `.hermes.md` 專案配置 ([#1712](https://github.com/NousResearch/hermes-agent/pull/1712))
- 修復：並行記憶寫入時靜默捨棄條目 —— 加入檔案鎖機制 ([#1726](https://github.com/NousResearch/hermes-agent/pull/1726))
- 修復：`session_search` 預設搜尋所有來源 ([#1892](https://github.com/NousResearch/hermes-agent/pull/1892))
- 修復：處理帶連字號的 FTS5 查詢並保留帶引號的字面值 ([#1776](https://github.com/NousResearch/hermes-agent/pull/1776))
- 修復：`load_transcript` 跳過損壞行而非直接崩潰 ([#1744](https://github.com/NousResearch/hermes-agent/pull/1744))
- 修復：正規化會話鍵以防止大小寫差異導致的重複 ([#2157](https://github.com/NousResearch/hermes-agent/pull/2157))
- 修復：防止會話不存在時 `session_search` 崩潰 ([#2194](https://github.com/NousResearch/hermes-agent/pull/2194))
- 修復：新會話重置 Token 計數器以準確顯示用量 ([#2101](https://github.com/NousResearch/hermes-agent/pull/2101) 由 @InB4DevOps 貢獻)
- 修復：防止排乾代理程式 (flush agent) 覆蓋過時的記憶 ([#2687](https://github.com/NousResearch/hermes-agent/pull/2687))
- 修復：移除人造錯誤訊息注入，修復重複失敗後的會話恢復 ([#2303](https://github.com/NousResearch/hermes-agent/pull/2303))
- 修復：帶有 `--resume` 的靜默模式現在會傳遞對話歷史 ([#2357](https://github.com/NousResearch/hermes-agent/pull/2357))
- 修復：統一批次模式下的恢復邏輯 ([#2331](https://github.com/NousResearch/hermes-agent/pull/2331))

### Honcho 記憶
- Honcho 配置修復與 @ 上下文引用整合 ([#2343](https://github.com/NousResearch/hermes-agent/pull/2343))
- 自託管 / Docker 配置文檔 ([#2475](https://github.com/NousResearch/hermes-agent/pull/2475))

---

## 📱 通訊平台 (網關)

### 新平台適配器
- **Signal Messenger** —— 完整的適配器，具備附件處理、群組訊息過濾以及「備忘錄 (Note to Self)」回顯保護功能 ([#2206](https://github.com/NousResearch/hermes-agent/pull/2206), [#2400](https://github.com/NousResearch/hermes-agent/pull/2400), [#2297](https://github.com/NousResearch/hermes-agent/pull/2297), [#2156](https://github.com/NousResearch/hermes-agent/pull/2156))
- **釘釘 (DingTalk)** —— 包含網關連線與安裝文檔的適配器 ([#1685](https://github.com/NousResearch/hermes-agent/pull/1685), [#1690](https://github.com/NousResearch/hermes-agent/pull/1690), [#1692](https://github.com/NousResearch/hermes-agent/pull/1692))
- **SMS (Twilio)** ([#1688](https://github.com/NousResearch/hermes-agent/pull/1688))
- **Mattermost** —— 具備 @提及限定的頻道過濾器 ([#1683](https://github.com/NousResearch/hermes-agent/pull/1683), [#2443](https://github.com/NousResearch/hermes-agent/pull/2443))
- **Matrix** —— 具備視覺支援與圖片快取功能 ([#1683](https://github.com/NousResearch/hermes-agent/pull/1683), [#2520](https://github.com/NousResearch/hermes-agent/pull/2520))
- **Webhook** —— 用於外部事件觸發的平台適配器 ([#2166](https://github.com/NousResearch/hermes-agent/pull/2166))
- **相容 OpenAI 的 API 伺服器** —— 支援 `/v1/chat/completions` 端點與 `/api/jobs` Cron 管理 ([#1756](https://github.com/NousResearch/hermes-agent/pull/1756), [#2450](https://github.com/NousResearch/hermes-agent/pull/2450), [#2456](https://github.com/NousResearch/hermes-agent/pull/2456))

### Telegram 改進
- MarkdownV2 支援 —— 刪除線、劇透、區塊引用、跳脫括號/大括號/反斜線/反引號 ([#2199](https://github.com/NousResearch/hermes-agent/pull/2199), [#2200](https://github.com/NousResearch/hermes-agent/pull/2200) 由 @llbn 貢獻, [#2386](https://github.com/NousResearch/hermes-agent/pull/2386))
- 自動偵測 HTML 標籤並使用 `parse_mode=HTML` ([#1709](https://github.com/NousResearch/hermes-agent/pull/1709))
- Telegram 群組視覺支援 + 基於討論串的會話 ([#2153](https://github.com/NousResearch/hermes-agent/pull/2153))
- 網路中斷後自動重新連線輪詢 ([#2517](https://github.com/NousResearch/hermes-agent/pull/2517))
- 分發前聚合被拆分的文字訊息 ([#1674](https://github.com/NousResearch/hermes-agent/pull/1674))
- 修復：串流配置橋接、未修改、流量控制問題 ([#1782](https://github.com/NousResearch/hermes-agent/pull/1782), [#1783](https://github.com/NousResearch/hermes-agent/pull/1783))
- 修復：edited_message 事件導致的崩潰 ([#2074](https://github.com/NousResearch/hermes-agent/pull/2074))
- 修復：放棄前重試 409 輪詢衝突 ([#2312](https://github.com/NousResearch/hermes-agent/pull/2312))
- 修復：透過 `platform:chat_id:thread_id` 格式進行主題遞送 ([#2455](https://github.com/NousResearch/hermes-agent/pull/2455))

### Discord 改進
- 文件快取與文字檔案注入 ([#2503](https://github.com/NousResearch/hermes-agent/pull/2503))
- 私訊的持續輸入指示器 ([#2468](https://github.com/NousResearch/hermes-agent/pull/2468))
- Discord 私訊視覺 —— 支援行內圖片與附件分析 ([#2186](https://github.com/NousResearch/hermes-agent/pull/2186))
- 網關重啟後保留討論串參與狀態 ([#1661](https://github.com/NousResearch/hermes-agent/pull/1661))
- 修復：網關在非 ASCII 伺服器名稱上崩潰的問題 ([#2302](https://github.com/NousResearch/hermes-agent/pull/2302))
- 修復：討論串權限錯誤 ([#2073](https://github.com/NousResearch/hermes-agent/pull/2073))
- 修復：討論串中的斜線指令事件路由 ([#2460](https://github.com/NousResearch/hermes-agent/pull/2460))
- 修復：移除有問題的追蹤訊息與 `/ask` 指令 ([#1836](https://github.com/NousResearch/hermes-agent/pull/1836))
- 修復：優雅的 WebSocket 重新連線 ([#2127](https://github.com/NousResearch/hermes-agent/pull/2127))
- 修復：啟用串流時的語音頻道 TTS ([#2322](https://github.com/NousResearch/hermes-agent/pull/2322))

### WhatsApp 與其他適配器
- WhatsApp: 出站 `send_message` 路由 ([#1769](https://github.com/NousResearch/hermes-agent/pull/1769) 由 @sai-samarth 貢獻), LID 格式自我對話 ([#1667](https://github.com/NousResearch/hermes-agent/pull/1667)), `reply_prefix` 配置修復 ([#1923](https://github.com/NousResearch/hermes-agent/pull/1923)), 橋接子進程結束後重啟 ([#2334](https://github.com/NousResearch/hermes-agent/pull/2334)), 圖片/橋接改進 ([#2181](https://github.com/NousResearch/hermes-agent/pull/2181))
- Matrix: 修正 `reply_to_message_id` 參數 ([#1895](https://github.com/NousResearch/hermes-agent/pull/1895)), 修正純媒體類型問題 ([#1736](https://github.com/NousResearch/hermes-agent/pull/1736))
- Mattermost: 為媒體附件提供 MIME 類型支援 ([#2329](https://github.com/NousResearch/hermes-agent/pull/2329))

### 網關核心
- 對失敗平台進行具備指數退避機制的**自動重新連線** ([#2584](https://github.com/NousResearch/hermes-agent/pull/2584))
- **會話自動重置時通知使用者** ([#2519](https://github.com/NousResearch/hermes-agent/pull/2519))
- 為會話外回覆提供**回覆訊息上下文** ([#1662](https://github.com/NousResearch/hermes-agent/pull/1662))
- **忽略未授權私訊**的配置選項 ([#1919](https://github.com/NousResearch/hermes-agent/pull/1919))
- 修復：討論串模式下的 `/reset` 重置了全域會話而非討論串會話 ([#2254](https://github.com/NousResearch/hermes-agent/pull/2254))
- 修復：串流回應後遞送 MEDIA: 檔案 ([#2382](https://github.com/NousResearch/hermes-agent/pull/2382))
- 修復：限制中斷遞迴深度以防止資源耗盡 ([#1659](https://github.com/NousResearch/hermes-agent/pull/1659))
- 修復：使用 `--replace` 時偵測已停止的進程並釋放過時鎖 ([#2406](https://github.com/NousResearch/hermes-agent/pull/2406), [#1908](https://github.com/NousResearch/hermes-agent/pull/1908))
- 修復：網關重啟時基於 PID 的等待與強制終止 ([#1902](https://github.com/NousResearch/hermes-agent/pull/1902))
- 修復：防止 `--replace` 模式殺死呼叫者進程 ([#2185](https://github.com/NousResearch/hermes-agent/pull/2185))
- 修復：`/model` 曾顯示活動中的回退模型而非配置預設值 ([#1660](https://github.com/NousResearch/hermes-agent/pull/1660))
- 修復：當會話尚未在 SQLite 中建立時，`/title` 指令失敗的問題 ([#2379](https://github.com/NousResearch/hermes-agent/pull/2379) 由 @ten-jampa 貢獻)
- 修復：代理程式完成後處理 `/queue` 隊列中的訊息 ([#2469](https://github.com/NousResearch/hermes-agent/pull/2469))
- 修復：剔除孤立的 `tool_results` + 允許 `/reset` 繞過執行中代理 ([#2180](https://github.com/NousResearch/hermes-agent/pull/2180))
- 修復：防止代理程式在 systemd 管理外啟動網關 ([#2617](https://github.com/NousResearch/hermes-agent/pull/2617))
- 修復：防止網關連線失敗時發生 systemd 重啟風暴 ([#2327](https://github.com/NousResearch/hermes-agent/pull/2327))
- 修復：systemd 單元中包含已解析的 Node 路徑 ([#1767](https://github.com/NousResearch/hermes-agent/pull/1767) 由 @sai-samarth 貢獻)
- 修復：在網關外部異常處理程序中向使用者傳送錯誤詳情 ([#1966](https://github.com/NousResearch/hermes-agent/pull/1966))
- 修復：改進 429 用量限制與 500 上下文溢出的錯誤處理 ([#1839](https://github.com/NousResearch/hermes-agent/pull/1839))
- 修復：啟動警告檢查中補齊所有缺失的平台允許清單環境變數 ([#2628](https://github.com/NousResearch/hermes-agent/pull/2628))
- 修復：路徑包含空格時媒體遞送失敗的問題 ([#2621](https://github.com/NousResearch/hermes-agent/pull/2621))
- 修復：多平台網關中的重複會話鍵衝突 ([#2171](https://github.com/NousResearch/hermes-agent/pull/2171))
- 修復：Matrix 與 Mattermost 永不回報連線成功的問題 ([#1711](https://github.com/NousResearch/hermes-agent/pull/1711))
- 修復：PII 遮蔽配置永不讀取的問題 —— 補上缺失的 yaml 匯入 ([#1701](https://github.com/NousResearch/hermes-agent/pull/1701))
- 修復：技能斜線指令中的 NameError ([#1697](https://github.com/NousResearch/hermes-agent/pull/1697))
- 修復：在檢查點中持久化監測元資料以供崩潰恢復 ([#1706](https://github.com/NousResearch/hermes-agent/pull/1706))
- 修復：send_image_file, send_document, send_video 中傳遞 `message_thread_id` ([#2339](https://github.com/NousResearch/hermes-agent/pull/2339))
- 修復：快速連續的照片訊息發生媒體組聚合錯誤的問題 ([#2160](https://github.com/NousResearch/hermes-agent/pull/2160))

---

## 🔧 工具系統

### MCP 強化
- **MCP 伺服器管理 CLI** + OAuth 2.1 PKCE 認證 ([#2465](https://github.com/NousResearch/hermes-agent/pull/2465))
- **將 MCP 伺服器公開為獨立工具集** ([#1907](https://github.com/NousResearch/hermes-agent/pull/1907))
- `hermes tools` 中的**互動式 MCP 工具配置** ([#1694](https://github.com/NousResearch/hermes-agent/pull/1694))
- 修復：MCP-OAuth 連接埠不匹配、路徑遍歷與共用處理程序狀態問題 ([#2552](https://github.com/NousResearch/hermes-agent/pull/2552))
- 修復：跨會話重置保留 MCP 工具註冊 ([#2124](https://github.com/NousResearch/hermes-agent/pull/2124))
- 修復：並行檔案存取崩潰 + 重複的 MCP 註冊 ([#2154](https://github.com/NousResearch/hermes-agent/pull/2154))
- 修復：正規化 MCP Schema + 擴充會話列表欄位 ([#2102](https://github.com/NousResearch/hermes-agent/pull/2102))
- 修復：`tool_choice` 的 `mcp_` 前綴處理 ([#1775](https://github.com/NousResearch/hermes-agent/pull/1775))

### 網頁工具後端
- **Tavily** 作為網頁搜尋/擷取/爬取後端 ([#1731](https://github.com/NousResearch/hermes-agent/pull/1731))
- **Parallel** 作為替代的網頁搜尋/擷取後端 ([#1696](https://github.com/NousResearch/hermes-agent/pull/1696))
- **可配置的網頁後端** —— 支援 Firecrawl/BeautifulSoup/Playwright 選擇 ([#2256](https://github.com/NousResearch/hermes-agent/pull/2256))
- 修復：僅含空白的環境變數會繞過網頁後端偵測的問題 ([#2341](https://github.com/NousResearch/hermes-agent/pull/2341))

### 新工具
- **IMAP 電子郵件** 讀取與發送 ([#2173](https://github.com/NousResearch/hermes-agent/pull/2173))
- 使用 Whisper API 的 **STT (語音轉文字)** 工具 ([#2072](https://github.com/NousResearch/hermes-agent/pull/2072))
- **感知路由的價格預估** ([#1695](https://github.com/NousResearch/hermes-agent/pull/1695))

### 工具改進
- TTS：OpenAI TTS 供應商支援 `base_url` ([#2064](https://github.com/NousResearch/hermes-agent/pull/2064) 由 @hanai 貢獻)
- 視覺：可配置逾時、支援路徑波浪號展開、支援多圖片與 Base64 回退的私訊視覺分析 ([#2480](https://github.com/NousResearch/hermes-agent/pull/2480), [#2585](https://github.com/NousResearch/hermes-agent/pull/2585), [#2211](https://github.com/NousResearch/hermes-agent/pull/2211))
- 瀏覽器：修復會話建立中的競態條件 ([#1721](https://github.com/NousResearch/hermes-agent/pull/1721))、處理非預期 LLM 參數的 TypeError ([#1735](https://github.com/NousResearch/hermes-agent/pull/1735))
- 檔案工具：從 write_file 與 patch 內容中去除 ANSI 轉義序列 ([#2532](https://github.com/NousResearch/hermes-agent/pull/2532))、在重複搜尋鍵中包含分頁參數 ([#1824](https://github.com/NousResearch/hermes-agent/pull/1824) 由 @cutepawss 貢獻)、提升模糊匹配準確度 + 重構位置計算 ([#2096](https://github.com/NousResearch/hermes-agent/pull/2096), [#1681](https://github.com/NousResearch/hermes-agent/pull/1681))
- 程式碼執行：修復資源洩漏與雙重 Socket 關閉問題 ([#2381](https://github.com/NousResearch/hermes-agent/pull/2381))
- 委派：並行子代理委派的執行緒安全 ([#1672](https://github.com/NousResearch/hermes-agent/pull/1672))、委派後保留父代理工具列表 ([#1778](https://github.com/NousResearch/hermes-agent/pull/1778))
- 修復：讓並行工具批次處理能感知檔案變更路徑 ([#1914](https://github.com/NousResearch/hermes-agent/pull/1914))
- 修復：在平台分發前對 `send_message_tool` 中的長訊息進行分段 ([#1646](https://github.com/NousResearch/hermes-agent/pull/1646))
- 修復：補上缺失的 'messaging' 工具集 ([#1718](https://github.com/NousResearch/hermes-agent/pull/1718))
- 修復：防止不可用工具名稱洩漏至模型 Schema ([#2072](https://github.com/NousResearch/hermes-agent/pull/2072))
- 修復：傳遞已存取集合的引用，以防止鑽石依賴重複 ([#2311](https://github.com/NousResearch/hermes-agent/pull/2311))
- 修復：Daytona 沙盒查找從 `find_one` 遷移至 `get/list` ([#2063](https://github.com/NousResearch/hermes-agent/pull/2063) 由 @rovle 貢獻)

---

## 🧩 技能生態系統

### 技能系統改進
- **代理建立的技能** —— 允許警示級 (Caution-level) 發現，危險技能改為詢問而非直接阻擋 ([#1840](https://github.com/NousResearch/hermes-agent/pull/1840), [#2446](https://github.com/NousResearch/hermes-agent/pull/2446))
- **`--yes` 旗標**可在 `/skills install` 與卸載時跳過確認 ([#1647](https://github.com/NousResearch/hermes-agent/pull/1647))
- 橫幅、系統提示詞與斜線指令皆會**遵循已禁用的技能** ([#1897](https://github.com/NousResearch/hermes-agent/pull/1897))
- 修復：技能 custom_tools 匯入崩潰 + 沙盒 file_tools 整合 ([#2239](https://github.com/NousResearch/hermes-agent/pull/2239))
- 修復：具備 pip 需求的代理建立技能在安裝時崩潰的問題 ([#2145](https://github.com/NousResearch/hermes-agent/pull/2145))
- 修復：`hub.yaml` 缺失時 `Skills.__init__` 中的競態條件 ([#2242](https://github.com/NousResearch/hermes-agent/pull/2242))
- 修復：安裝前驗證技能元資料並阻擋重複項 ([#2241](https://github.com/NousResearch/hermes-agent/pull/2241))
- 修復：技能中心 inspect/resolve —— 解決了 inspect, 重新導向, 發現, tap 列表中的 4 個 Bug ([#2447](https://github.com/NousResearch/hermes-agent/pull/2447))
- 修復：代理建立的技能在會話重置後仍能持續運作 ([#2121](https://github.com/NousResearch/hermes-agent/pull/2121))

### 新技能
- **OCR-and-documents** —— PDF/DOCX/XLS/PPTX/圖片 OCR，支援選用 GPU ([#2236](https://github.com/NousResearch/hermes-agent/pull/2236), [#2461](https://github.com/NousResearch/hermes-agent/pull/2461))
- **Huggingface-hub** 內建技能 ([#1921](https://github.com/NousResearch/hermes-agent/pull/1921))
- **Sherlock OSINT** 使用者名稱搜尋 ([#1671](https://github.com/NousResearch/hermes-agent/pull/1671))
- **Meme-generation** —— 使用 Pillow 的圖片生成器 ([#2344](https://github.com/NousResearch/hermes-agent/pull/2344))
- **Bioinformatics** 網關技能 —— 索引至 400 多個生物資訊技能 ([#2387](https://github.com/NousResearch/hermes-agent/pull/2387))
- **Inference.sh** 技能 (基於終端) ([#1686](https://github.com/NousResearch/hermes-agent/pull/1686))
- **Base blockchain** 選用技能 ([#1643](https://github.com/NousResearch/hermes-agent/pull/1643))
- **3D-model-viewer** 選用技能 ([#2226](https://github.com/NousResearch/hermes-agent/pull/2226))
- **FastMCP** 選用技能 ([#2113](https://github.com/NousResearch/hermes-agent/pull/2113))
- **Hermes-agent-setup** 技能 ([#1905](https://github.com/NousResearch/hermes-agent/pull/1905))

---

## 🔌 插件系統強化

- **TUI 擴充鉤子** —— 基於 Hermes 構建自訂 CLI ([#2333](https://github.com/NousResearch/hermes-agent/pull/2333))
- **`hermes plugins install/remove/list`** 指令 ([#2337](https://github.com/NousResearch/hermes-agent/pull/2337))
- 插件支援**斜線指令註冊** ([#2359](https://github.com/NousResearch/hermes-agent/pull/2359))
- **`session:end` 生命週期事件** 鉤子 ([#1725](https://github.com/NousResearch/hermes-agent/pull/1725))
- 修復：專案插件發現改為必須手動選擇加入 (opt-in) ([#2215](https://github.com/NousResearch/hermes-agent/pull/2215))

---

## 🔒 安全性與可靠性

### 安全性
- 為 `vision_tools` 與 `web_tools` 新增 **SSRF 防護** ([#2679](https://github.com/NousResearch/hermes-agent/pull/2679))
- **防止 `_expand_path` 中的 Shell 注入** (透過 `~user` 路徑後綴) ([#2685](https://github.com/NousResearch/hermes-agent/pull/2685))
- **阻擋不可信的瀏覽器來源** 存取 API 伺服器 ([#2451](https://github.com/NousResearch/hermes-agent/pull/2451))
- **從子進程環境中阻擋沙盒後端憑證** ([#1658](https://github.com/NousResearch/hermes-agent/pull/1658))
- **阻擋 @ 引用** 讀取工作區外的機密資訊 ([#2601](https://github.com/NousResearch/hermes-agent/pull/2601) 由 @Gutslabs 貢獻)
- 為 `terminal_tool` 新增**惡意程式碼模式預檢掃描器** ([#2245](https://github.com/NousResearch/hermes-agent/pull/2245))
- **強化終端安全性**與沙盒檔案寫入保護 ([#1653](https://github.com/NousResearch/hermes-agent/pull/1653))
- **PKCE 驗證器洩漏**修復 + OAuth 刷新 Content-Type 修正 ([#1775](https://github.com/NousResearch/hermes-agent/pull/1775))
- **消除 `execute()` 呼叫中的 SQL 字串格式化** ([#2061](https://github.com/NousResearch/hermes-agent/pull/2061) 由 @dusterbloom 貢獻)
- **強化 Jobs API** —— 輸入限制、欄位白名單、啟動檢查 ([#2456](https://github.com/NousResearch/hermes-agent/pull/2456))

### 可靠性
- 為 4 個 SessionDB 方法加入執行緒鎖 ([#1704](https://github.com/NousResearch/hermes-agent/pull/1704))
- 為並行記憶寫入加入檔案鎖 ([#1726](https://github.com/NousResearch/hermes-agent/pull/1726))
- 優雅處理 OpenRouter 錯誤 ([#2112](https://github.com/NousResearch/hermes-agent/pull/2112))
- 保護 print() 呼叫防止 OSError ([#1668](https://github.com/NousResearch/hermes-agent/pull/1668))
- 在遮蔽格式化器中安全處理非字串輸入 ([#2392](https://github.com/NousResearch/hermes-agent/pull/2392), [#1700](https://github.com/NousResearch/hermes-agent/pull/1700))
- ACP：模型切換時保留會話供應商、將會話持久化至磁碟 ([#2380](https://github.com/NousResearch/hermes-agent/pull/2380), [#2071](https://github.com/NousResearch/hermes-agent/pull/2071))
- API 伺服器：重啟後從 SQLite 恢復 ResponseStore ([#2472](https://github.com/NousResearch/hermes-agent/pull/2472))
- 修復：`fetch_nous_models` 曾因位置參數導致 TypeError ([#1699](https://github.com/NousResearch/hermes-agent/pull/1699))
- 修復：解決 cli.py 中的合併衝突標記導致的啟動失敗 ([#2347](https://github.com/NousResearch/hermes-agent/pull/2347))
- 修復：Wheel 套件中缺失 `minisweagent_path.py` 的問題 ([#2098](https://github.com/NousResearch/hermes-agent/pull/2098) 由 @JiwaniZakir 貢獻)

### Cron 系統
- **`[SILENT]` 回應** —— Cron 代理程式可抑制訊息遞送 ([#1833](https://github.com/NousResearch/hermes-agent/pull/1833))
- **按排程頻率縮放錯過任務的寬限期** ([#2449](https://github.com/NousResearch/hermes-agent/pull/2449))
- **恢復最近的一次性任務** ([#1918](https://github.com/NousResearch/hermes-agent/pull/1918))
- 修復：正規化 `repeat<=0` 為 None —— 解決 LLM 傳入 -1 時任務在首輪後被刪除的問題 ([#2612](https://github.com/NousResearch/hermes-agent/pull/2612) 由 @Mibayy 貢獻)
- 修復：排程遞送的 platform_map 加入 Matrix ([#2167](https://github.com/NousResearch/hermes-agent/pull/2167) 由 @buntingszn 貢獻)
- 修復：不帶時區的 ISO 時間戳記導致任務在錯誤時間觸發 ([#1729](https://github.com/NousResearch/hermes-agent/pull/1729))
- 修復：`get_due_jobs` 重複讀取 `jobs.json` 導致的競態條件 ([#1716](https://github.com/NousResearch/hermes-agent/pull/1716))
- 修復：靜默任務回傳空回應以跳過遞送 ([#2442](https://github.com/NousResearch/hermes-agent/pull/2442))
- 修復：停止向網關會話歷史注入 Cron 輸出 ([#2313](https://github.com/NousResearch/hermes-agent/pull/2313))
- 修復：當 `asyncio.run()` 拋出 RuntimeError 時關閉遺棄的協程 ([#2317](https://github.com/NousResearch/hermes-agent/pull/2317))

---

## 🧪 測試

- 解決所有持續失敗的測試 ([#2488](https://github.com/NousResearch/hermes-agent/pull/2488))
- 以 `monkeypatch` 取代 `FakePath` 以相容 Python 3.12 ([#2444](https://github.com/NousResearch/hermes-agent/pull/2444))
- 對齊 Hermes 安裝與全套測試的預期結果 ([#1710](https://github.com/NousResearch/hermes-agent/pull/1710))

---

## 📚 文檔更新

- 針對近期功能進行全面文檔更新 ([#1693](https://github.com/NousResearch/hermes-agent/pull/1693), [#2183](https://github.com/NousResearch/hermes-agent/pull/2183))
- 阿里雲與釘釘安裝指南 ([#1687](https://github.com/NousResearch/hermes-agent/pull/1687), [#1692](https://github.com/NousResearch/hermes-agent/pull/1692))
- 詳細的技能文檔 ([#2244](https://github.com/NousResearch/hermes-agent/pull/2244))
- Honcho 自託管 / Docker 配置 ([#2475](https://github.com/NousResearch/hermes-agent/pull/2475))
- 上下文長度偵測 FAQ 與快速入門參考 ([#2179](https://github.com/NousResearch/hermes-agent/pull/2179))
- 修正參考資料與使用者指南之間的文檔不一致處 ([#1995](https://github.com/NousResearch/hermes-agent/pull/1995))
- 修正 MCP 安裝指令 —— 使用 uv 而非純 pip ([#1909](https://github.com/NousResearch/hermes-agent/pull/1909))
- 以 Mermaid 圖表/列表取代 ASCII 圖表 ([#2402](https://github.com/NousResearch/hermes-agent/pull/2402))
- Gemini OAuth 供應商實作計畫 ([#2467](https://github.com/NousResearch/hermes-agent/pull/2467))
- 標註 Discord Server Members Intent 為必要選項 ([#2330](https://github.com/NousResearch/hermes-agent/pull/2330))
- 修正 api-server.md 中的 MDX 建置錯誤 ([#1787](https://github.com/NousResearch/hermes-agent/pull/1787))
- 對齊 venv 路徑以匹配安裝程式 ([#2114](https://github.com/NousResearch/hermes-agent/pull/2114))
- 技能中心索引新增多項技能 ([#2281](https://github.com/NousResearch/hermes-agent/pull/2281))

---

## 👥 貢獻者

### 核心團隊
- **@teknium1** (Teknium) —— 280 個 PR

### 社群貢獻者
- **@mchzimm** (to_the_max) —— GitHub Copilot 供應商整合 ([#1879])
- **@jquesnelle** (Jeffrey Quesnelle) —— 每執行緒持久事件迴圈修復 ([#2214])
- **@llbn** (lbn) —— Telegram MarkdownV2 刪除線、劇透、區塊引用與跳脫修復 ([#2199], [#2200])
- **@dusterbloom** —— SQL 注入預防 + 本地伺服器上下文視窗查詢 ([#2061], [#2091])
- **@0xbyt4** —— Anthropic tool_calls None 保護 + OpenCode-Go 供應商配置修復 ([#2209], [#2393])
- **@sai-samarth** (Saisamarth) —— WhatsApp send_message 路由 + systemd Node 路徑 ([#1769], [#1767])
- **@Gutslabs** (Guts) —— 阻擋 @ 引用讀取機密資訊 ([#2601])
- **@Mibayy** (Mibay) —— Cron 任務重複週期正規化 ([#2612])
- **@ten-jampa** (Tenzin Jampa) —— 網關 /title 指令修復 ([#2379])
- **@cutepawss** (lila) —— 檔案工具搜尋分頁修復 ([#1824])
- **@hanai** (Hanai) —— OpenAI TTS base_url 支援 ([#2064])
- **@rovle** (Lovre Pešut) —— Daytona 沙盒 API 遷移 ([#2063])
- **@buntingszn** (bunting szn) —— Matrix Cron 遞送支援 ([#2167])
- **@InB4DevOps** —— 新會話 Token 計數器重置 ([#2101])
- **@JiwaniZakir** (Zakir Jiwani) —— Wheel 套件缺失檔案修復 ([#2098])
- **@ygd58** (buray) —— 委派工具父代理工具名稱修復 ([#2083])

---

**完整變更日誌**: [v2026.3.17...v2026.3.23](https://github.com/NousResearch/hermes-agent/compare/v2026.3.17...v2026.3.23)
