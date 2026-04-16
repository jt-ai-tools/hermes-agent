---
title: "功能概覽"
sidebar_label: "概覽"
sidebar_position: 1
---

# 功能概覽

Hermes Agent 包含一套豐富的功能，遠超基本的對話。從持久化記憶和檔案感知的上下文到瀏覽器自動化和語音對話，這些功能協同工作，使 Hermes 成為一個強大的自主助理。

## 核心功能

- **[工具與工具集 (Tools & Toolsets)](tools.md)** — 工具是擴展代理能力的函數。它們被組織成邏輯工具集，可以根據平台啟用或停用，涵蓋網路搜尋、終端機執行、檔案編輯、記憶、委派等。
- **[技能系統 (Skills System)](skills.md)** — 代理可以在需要時載入的隨選知識文件。技能遵循漸進式揭露模式以減少權杖 (token) 使用量，並相容於 [agentskills.io](https://agentskills.io/specification) 開放標準。
- **[持久化記憶 (Persistent Memory)](memory.md)** — 跨工作階段持久化的有界、精選記憶。Hermes 會透過 `MEMORY.md` 和 `USER.md` 記住您的偏好、專案、環境以及它學到的內容。
- **[上下文檔案 (Context Files)](context-files.md)** — Hermes 自動發現並載入專案上下文檔案 (`.hermes.md`、`AGENTS.md`、`CLAUDE.md`、`SOUL.md`、`.cursorrules`)，這些檔案定義了它在您專案中的行為方式。
- **[上下文引用 (Context References)](context-references.md)** — 輸入 `@` 後接引用，可將檔案、資料夾、git 差異和 URL 直接注入到您的訊息中。Hermes 會在行內展開引用並自動附加內容。
- **[檢查點 (Checkpoints)](../checkpoints-and-rollback.md)** — Hermes 在進行檔案更改之前會自動對您的工作目錄進行快照，為您提供安全網，以便在出錯時使用 `/rollback` 進行回滾。

## 自動化

- **[排程任務 (Cron)](cron.md)** — 使用自然語言或 cron 表達式排程自動執行的任務。作業可以附加技能，將結果傳遞到任何平台，並支援暫停/恢復/編輯操作。
- **[子代理委派 (Subagent Delegation)](delegation.md)** — `delegate_task` 工具會產生具有隔離上下文、受限工具集和各自終端機工作階段的子代理實例。最多可同時執行 3 個子代理進行平行工作流。
- **[程式碼執行 (Code Execution)](code-execution.md)** — `execute_code` 工具讓代理編寫 Python 腳本來以程式化方式呼叫 Hermes 工具，透過沙箱化的 RPC 執行將多步驟工作流合併為單個 LLM 回合。
- **[事件鉤子 (Event Hooks)](hooks.md)** — 在關鍵生命週期點執行自訂程式碼。網關鉤子 (Gateway hooks) 處理記錄、警報和 webhook；外掛程式鉤子 (Plugin hooks) 處理工具攔截、指標和護欄。
- **[批次處理 (Batch Processing)](batch-processing.md)** — 在數百或數千個提示上平行執行 Hermes 代理，生成結構化的 ShareGPT 格式軌跡數據，用於訓練數據生成或評估。

## 多媒體與網路

- **[語音模式 (Voice Mode)](voice-mode.md)** — 橫跨 CLI 和通訊平台的完整語音互動。使用麥克風與代理對談，聽取語音回覆，並在 Discord 語音頻道中進行即時語音對話。
- **[瀏覽器自動化 (Browser Automation)](browser.md)** — 具備多種後端的完整瀏覽器自動化：Browserbase 雲端、Browser Use 雲端、透過 CDP 的本地 Chrome 或本地 Chromium。導覽網站、填寫表單並提取資訊。
- **[視覺與圖片貼上 (Vision & Image Paste)](vision.md)** — 多模態視覺支援。將剪貼簿中的圖片貼到 CLI 中，並要求代理使用任何具備視覺能力的模型進行分析、描述或處理。
- **[圖像生成 (Image Generation)](image-generation.md)** — 使用 FAL.ai 的 FLUX 2 Pro 模型從文字提示生成圖像，並透過 Clarity Upscaler 自動進行 2 倍放大。
- **[語音與 TTS (Voice & TTS)](tts.md)** — 跨所有通訊平台的文字轉語音輸出和語音訊息逐字稿，提供五種供應商選項：Edge TTS（免費）、ElevenLabs、OpenAI TTS、MiniMax 和 NeuTTS。

## 整合

- **[MCP 整合](mcp.md)** — 透過 stdio 或 HTTP 傳輸連接到任何 MCP 伺服器。存取來自 GitHub、資料庫、檔案系統和內部 API 的外部工具，而無需編寫原生 Hermes 工具。包括按伺服器過濾工具和取樣支援。
- **[提供者路由 (Provider Routing)](provider-routing.md)** — 精細控制由哪些 AI 提供者處理您的請求。透過排序、白名單、黑名單和優先順序排序來優化成本、速度或品質。
- **[備用提供者 (Fallback Providers)](fallback-providers.md)** — 當您的主模型遇到錯誤時，自動容錯轉移到備份 LLM 提供者，包括視覺和壓縮等輔助任務的獨立備用機制。
- **[憑證池 (Credential Pools)](credential-pools.md)** — 將 API 呼叫分配到同一個提供者的多個金鑰。在達到速率限制或發生失敗時自動輪換。
- **[記憶提供者 (Memory Providers)](memory-providers.md)** — 插入外部記憶後端（Honcho、OpenViking、Mem0、Hindsight、Holographic、RetainDB、ByteRover），用於跨工作階段的使用者建模和超越內建記憶系統的個性化。
- **[API 伺服器 (API Server)](api-server.md)** — 將 Hermes 暴露為與 OpenAI 相容的 HTTP 端點。連接任何支援 OpenAI 格式的前端 — Open WebUI、LobeChat、LibreChat 等。
- **[IDE 整合 (ACP)](acp.md)** — 在 VS Code、Zed 和 JetBrains 等支援 ACP 的編輯器中使用 Hermes。聊天、工具活動、檔案差異和終端機指令都會在您的編輯器內呈現。
- **[RL 訓練](rl-training.md)** — 從代理工作階段生成軌跡數據，用於強化學習和模型微調。

## 客製化

- **[個性與 SOUL.md (Personality & SOUL.md)](personality.md)** — 完全可自訂的代理個性。`SOUL.md` 是主要的身份檔案 — 系統提示中的第一項內容 — 您可以為每個工作階段切換內建或自訂的 `/personality` 預設。
- **[外觀與主題 (Skins & Themes)](skins.md)** — 自訂 CLI 的視覺呈現：橫幅顏色、載入動畫（spinner）面孔和動詞、回應框標籤、品牌文字以及工具活動前綴。
- **[外掛程式 (Plugins)](plugins.md)** — 在不修改核心程式碼的情況下添加自訂工具、鉤子和整合。三種外掛程式類型：一般外掛程式（工具/鉤子）、記憶提供者（跨工作階段知識）和上下文引擎（替代上下文管理）。透過統一的 `hermes plugins` 互動介面進行管理。
