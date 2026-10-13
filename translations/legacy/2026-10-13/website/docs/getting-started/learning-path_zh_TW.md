---
sidebar_position: 3
title: '學習路徑'
description: '根據你的經驗水平與目標，在 Hermes Agent 文件中選擇你的學習路徑。'
---

# 學習路徑

Hermes Agent 功能強大——可作為 CLI 助手、Telegram/Discord 機器人、任務自動化、RL 訓練等等。本頁面旨在根據你的經驗水平以及你想要達成的目標，幫助你確定從何處開始以及閱讀哪些內容。

:::tip 從這裡開始
如果你尚未安裝 Hermes Agent，請先閱讀 [安裝指南](/docs/getting-started/installation_zh_TW)，然後進行 [快速入門](/docs/getting-started/quickstart_zh_TW)。下方的所有內容皆假設你已完成安裝。
:::

## 如何使用本頁面

- **已知曉自己的水平？** 直接跳轉到 [依經驗水平分類表格](#依經驗水平分類) 並按照適合你的階層閱讀。
- **有明確目標？** 直接跳轉到 [依使用案例分類](#依使用案例分類) 並找到相符的情境。
- **只是隨便看看？** 查看 [主要功能一覽](#主要功能一覽) 表格，快速了解 Hermes Agent 的所有功能。

## 依經驗水平分類

| 水平 | 目標 | 推薦閱讀 | 預估時間 |
|---|---|---|---|
| **初學者** | 完成安裝、進行基礎對話、使用內建工具 | [安裝](/docs/getting-started/installation_zh_TW) → [快速入門](/docs/getting-started/quickstart_zh_TW) → [CLI 使用](/docs/user-guide/cli_zh_TW) → [配置設定](/docs/user-guide/configuration_zh_TW) | ~1 小時 |
| **中級** | 設定訊息機器人、使用記憶、cron 任務與技能等進階功能 | [會話 (Sessions)](/docs/user-guide/sessions_zh_TW) → [訊息功能](/docs/user-guide/messaging_zh_TW) → [工具](/docs/user-guide/features/tools_zh_TW) → [技能](/docs/user-guide/features/skills_zh_TW) → [記憶](/docs/user-guide/features/memory_zh_TW) → [Cron](/docs/user-guide/features/cron_zh_TW) | ~2–3 小時 |
| **進階** | 建立自訂工具、開發技能、使用 RL 訓練模型、貢獻專案 | [架構](/docs/developer-guide/architecture_zh_TW) → [新增工具](/docs/developer-guide/adding-tools_zh_TW) → [建立技能](/docs/developer-guide/creating-skills_zh_TW) → [RL 訓練](/docs/user-guide/features/rl-training_zh_TW) → [貢獻指南](/docs/developer-guide/contributing_zh_TW) | ~4–6 小時 |

## 依使用案例分類

挑選符合你需求的情境。每個情境都依推薦順序連結至相關文件。

### 「我想要一個 CLI 程式碼助手」

將 Hermes Agent 作為互動式終端助手，用於撰寫、審閱與執行程式碼。

1. [安裝](/docs/getting-started/installation_zh_TW)
2. [快速入門](/docs/getting-started/quickstart_zh_TW)
3. [CLI 使用](/docs/user-guide/cli_zh_TW)
4. [程式碼執行](/docs/user-guide/features/code-execution_zh_TW)
5. [上下文檔案 (Context Files)](/docs/user-guide/features/context-files_zh_TW)
6. [提示與技巧](/docs/guides/tips_zh_TW)

:::tip
透過上下文檔案將檔案直接帶入對話。Hermes Agent 可以閱讀、編輯並運行你專案中的程式碼。
:::

### 「我想要一個 Telegram/Discord 機器人」

在常用的訊息平台上部署 Hermes Agent 機器人。

1. [安裝](/docs/getting-started/installation_zh_TW)
2. [配置設定](/docs/user-guide/configuration_zh_TW)
3. [訊息功能概覽](/docs/user-guide/messaging_zh_TW)
4. [Telegram 設定](/docs/user-guide/messaging/telegram_zh_TW)
5. [Discord 設定](/docs/user-guide/messaging/discord_zh_TW)
6. [語音模式](/docs/user-guide/features/voice-mode_zh_TW)
7. [在 Hermes 中使用語音模式](/docs/guides/use-voice-mode-with-hermes_zh_TW)
8. [安全性](/docs/user-guide/security_zh_TW)

完整專案範例請參閱：
- [每日簡報機器人](/docs/guides/daily-briefing-bot_zh_TW)
- [團隊 Telegram 助手](/docs/guides/team-telegram-assistant_zh_TW)

### 「我想要自動化任務」

排定週期性任務、執行批次作業，或串聯代理動作。

1. [快速入門](/docs/getting-started/quickstart_zh_TW)
2. [Cron 排程](/docs/user-guide/features/cron_zh_TW)
3. [批次處理](/docs/user-guide/features/batch-processing_zh_TW)
4. [委派 (Delegation)](/docs/user-guide/features/delegation_zh_TW)
5. [Hooks](/docs/user-guide/features/hooks_zh_TW)

:::tip
Cron 任務讓 Hermes Agent 能依排程執行任務——每日摘要、定期檢查、自動報告——無需你親自在場。
:::

### 「我想要建立自訂工具/技能」

使用自訂工具與可重複使用的技能套件擴充 Hermes Agent。

1. [工具概覽](/docs/user-guide/features/tools_zh_TW)
2. [技能概覽](/docs/user-guide/features/skills_zh_TW)
3. [MCP (模型上下文協議)](/docs/user-guide/features/mcp_zh_TW)
4. [架構](/docs/developer-guide/architecture_zh_TW)
5. [新增工具](/docs/developer-guide/adding-tools_zh_TW)
6. [建立技能](/docs/developer-guide/creating-skills_zh_TW)

:::tip
工具 (Tools) 是代理可以調用的個別功能。技能 (Skills) 是打包在一起的工具、提示 (prompts) 與配置。先從工具開始，再進階到技能。
:::

### 「我想要訓練模型」

使用強化學習 (RL)，透過 Hermes Agent 內建的 RL 訓練流水線來微調模型行為。

1. [快速入門](/docs/getting-started/quickstart_zh_TW)
2. [配置設定](/docs/user-guide/configuration_zh_TW)
3. [RL 訓練](/docs/user-guide/features/rl-training_zh_TW)
4. [提供商路由](/docs/user-guide/features/provider-routing_zh_TW)
5. [架構](/docs/developer-guide/architecture_zh_TW)

:::tip
當你已經了解 Hermes Agent 處理對話與工具調用的基礎知識後，RL 訓練的效果最好。如果你是新手，請先完成初學者路徑。
:::

### 「我想要將它作為 Python 函式庫使用」

透過程式化方式將 Hermes Agent 整合到你自己的 Python 應用程式中。

1. [安裝](/docs/getting-started/installation_zh_TW)
2. [快速入門](/docs/getting-started/quickstart_zh_TW)
3. [Python 函式庫指南](/docs/guides/python-library_zh_TW)
4. [架構](/docs/developer-guide/architecture_zh_TW)
5. [工具](/docs/user-guide/features/tools_zh_TW)
6. [會話 (Sessions)](/docs/user-guide/sessions_zh_TW)

## 主要功能一覽

不確定有哪些功能？以下是主要功能的快速索引：

| 功能 | 作用 | 連結 |
|---|---|---|
| **工具 (Tools)** | 代理可調用的內建工具 (檔案 I/O, 搜尋, shell 等) | [工具](/docs/user-guide/features/tools_zh_TW) |
| **技能 (Skills)** | 可安裝的插件套件，新增功能 | [技能](/docs/user-guide/features/skills_zh_TW) |
| **記憶 (Memory)** | 跨會話的持久性記憶 | [記憶](/docs/user-guide/features/memory_zh_TW) |
| **上下文檔案** | 將檔案與目錄饋送到對話中 | [上下文檔案](/docs/user-guide/features/context-files_zh_TW) |
| **MCP** | 透過模型上下文協議連接外部工具伺服器 | [MCP](/docs/user-guide/features/mcp_zh_TW) |
| **Cron** | 排定代理的週期性任務 | [Cron](/docs/user-guide/features/cron_zh_TW) |
| **委派 (Delegation)** | 產生子代理進行並行工作 | [委派](/docs/user-guide/features/delegation_zh_TW) |
| **程式碼執行** | 在沙盒環境中執行程式碼 | [程式碼執行](/docs/user-guide/features/code-execution_zh_TW) |
| **瀏覽器** | 網頁瀏覽與擷取 | [瀏覽器](/docs/user-guide/features/browser_zh_TW) |
| **Hooks** | 事件驅動的回呼 (callbacks) 與中介軟體 | [Hooks](/docs/user-guide/features/hooks_zh_TW) |
| **批次處理** | 大量處理多個輸入 | [批次處理](/docs/user-guide/features/batch-processing_zh_TW) |
| **RL 訓練** | 使用增強學習微調模型 | [RL 訓練](/docs/user-guide/features/rl-training_zh_TW) |
| **提供商路由** | 在多個 LLM 提供商之間路由請求 | [提供商路由](/docs/user-guide/features/provider-routing_zh_TW) |

## 接下來該閱讀什麼？

根據你目前的情況：

- **剛完成安裝？** → 前往 [快速入門](/docs/getting-started/quickstart_zh_TW) 進行第一次對話。
- **已完成快速入門？** → 閱讀 [CLI 使用](/docs/user-guide/cli_zh_TW) 與 [配置設定](/docs/user-guide/configuration_zh_TW) 以自訂你的設定。
- **已熟悉基礎知識？** → 探索 [工具](/docs/user-guide/features/tools_zh_TW)、[技能](/docs/user-guide/features/skills_zh_TW) 與 [記憶](/docs/user-guide/features/memory_zh_TW) 以釋放代理的所有功能。
- **正為團隊進行設定？** → 閱讀 [安全性](/docs/user-guide/security_zh_TW) 與 [會話 (Sessions)](/docs/user-guide/sessions_zh_TW) 以了解存取控制與對話管理。
- **準備好動手開發？** → 跳轉到 [開發者指南](/docs/developer-guide/architecture_zh_TW) 以了解內部機制並開始貢獻。
- **想要實務範例？** → 查看 [指南](/docs/guides/tips_zh_TW) 部分以獲取真實專案與技巧。

:::tip
你不需要閱讀所有內容。選擇符合你目標的路徑，按順序點擊連結，你很快就能上手。你可以隨時回到本頁面查找下一步。
:::
