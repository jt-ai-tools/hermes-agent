---
slug: /
sidebar_position: 0
title: "Hermes Agent 文件"
description: "由 Nous Research 開發的自我改良 AI 代理。內建學習迴圈，能從經驗中創造技能、在使用過程中改進技能，並能在不同會話中保持記憶。"
hide_table_of_contents: true
---

# Hermes Agent

由 [Nous Research](https://nousresearch.com) 開發的自我改良 AI 代理。這是唯一內建學習迴圈的代理——它能從經驗中創造技能、在使用過程中改進技能、督促自己留存知識，並在不同會話中建立起對使用者的深度模型。

<div style={{display: 'flex', gap: '1rem', marginBottom: '2rem', flexWrap: 'wrap'}}>
  <a href="/docs/getting-started/installation_zh_TW" style={{display: 'inline-block', padding: '0.6rem 1.2rem', backgroundColor: '#FFD700', color: '#07070d', borderRadius: '8px', fontWeight: 600, textDecoration: 'none'}}>開始使用 →</a>
  <a href="https://github.com/NousResearch/hermes-agent" style={{display: 'inline-block', padding: '0.6rem 1.2rem', border: '1px solid rgba(255,215,0,0.2)', borderRadius: '8px', textDecoration: 'none'}}>在 GitHub 上查看</a>
</div>

## 什麼是 Hermes Agent？

它不是綁定在 IDE 的編碼副駕駛 (copilot)，也不是包裝單一 API 的聊天機器人。它是一個**自主代理 (autonomous agent)**，運行時間越長，功能就越強大。它可以在任何地方運行——無論是 5 美元的 VPS、GPU 叢集，還是閒置時幾乎不產生費用的伺服器端基礎架構（如 Daytona、Modal）。你可以透過 Telegram 與它對談，而它則在雲端虛擬機器 (VM) 上工作，你甚至不需要親自 SSH 進去。它並不受限於你的筆記型電腦。

## 快速連結

| | |
|---|---|
| 🚀 **[安裝](/docs/getting-started/installation_zh_TW)** | 60 秒內在 Linux, macOS 或 WSL2 完成安裝 |
| 📖 **[快速入門教學](/docs/getting-started/quickstart_zh_TW)** | 你的第一次對話與關鍵功能嘗試 |
| 🗺️ **[學習路徑](/docs/getting-started/learning-path_zh_TW)** | 根據你的經驗水平找到合適的文件 |
| ⚙️ **[配置設定](/docs/user-guide/configuration_zh_TW)** | 設定檔、提供商、模型與選項 |
| 💬 **[訊息閘道器](/docs/user-guide/messaging_zh_TW)** | 設定 Telegram, Discord, Slack 或 WhatsApp |
| 🔧 **[工具與工具集](/docs/user-guide/features/tools_zh_TW)** | 47 種內建工具及其設定方式 |
| 🧠 **[記憶系統](/docs/user-guide/features/memory_zh_TW)** | 隨對話增長的持久性記憶 |
| 📚 **[技能系統](/docs/user-guide/features/skills_zh_TW)** | 代理自行建立並重複使用的程序性記憶 |
| 🔌 **[MCP 整合](/docs/user-guide/features/mcp_zh_TW)** | 連接 MCP 伺服器、篩選工具並安全地擴充 Hermes |
| 🧭 **[在 Hermes 中使用 MCP](/docs/guides/use-mcp-with-hermes_zh_TW)** | 實用的 MCP 設定模式、範例與教學 |
| 🎙️ **[語音模式](/docs/user-guide/features/voice-mode_zh_TW)** | CLI, Telegram, Discord 及 Discord 語音頻道中的即時語音互動 |
| 🗣️ **[在 Hermes 中使用語音模式](/docs/guides/use-voice-mode-with-hermes_zh_TW)** | Hermes 語音工作流的動手設定與使用模式 |
| 🎭 **[個性與 SOUL.md](/docs/user-guide/features/personality_zh_TW)** | 透過全域 SOUL.md 定義 Hermes 的預設口吻 |
| 📄 **[上下文檔案](/docs/user-guide/features/context-files_zh_TW)** | 塑造每次對話的專案上下文檔案 |
| 🔒 **[安全性](/docs/user-guide/security_zh_TW)** | 指令核准、授權、容器隔離 |
| 💡 **[提示與最佳實踐](/docs/guides/tips_zh_TW)** | 充分發揮 Hermes 功效的快速技巧 |
| 🏗️ **[架構](/docs/developer-guide/architecture_zh_TW)** | 深入了解底層運作機制 |
| ❓ **[常見問題與疑難排解](/docs/reference/faq_zh_TW)** | 常見問題與解決方案 |

## 主要功能

- **閉環學習迴圈** —— 代理策劃的記憶與週期性提醒、自主技能建立、使用過程中的技能自我改進、具備 LLM 摘要功能的 FTS5 跨會話回溯，以及 [Honcho](https://github.com/plastic-labs/honcho) 對話式使用者建模。
- **隨處運行，不只是筆記型電腦** —— 支援 6 種終端後端：local, Docker, SSH, Daytona, Singularity, Modal。Daytona 與 Modal 提供伺服器端持久化——環境在閒置時會休眠，幾乎不產生費用。
- **生活化的平台** —— 透過單一閘道器支援 15 個以上平台：CLI, Telegram, Discord, Slack, WhatsApp, Signal, Matrix, Mattermost, Email, SMS, DingTalk (釘釘), Feishu (飛書), WeCom (企業微信), BlueBubbles, Home Assistant。
- **由模型訓練專家打造** —— 由 [Nous Research](https://nousresearch.com) 建立，該研究室是 Hermes, Nomos 和 Psyche 模型的幕後推手。相容於 [Nous Portal](https://portal.nousresearch.com), [OpenRouter](https://openrouter.ai), OpenAI 或任何端點。
- **排程自動化** —— 內建 cron 功能，可將結果傳送到任何平台。
- **委派與並行** —— 為並行工作流產生隔離的子代理。透過 `execute_code` 進行程式化工具調用，將多步驟流程簡化為單次推論調用。
- **開放標準技能** —— 相容於 [agentskills.io](https://agentskills.io)。技能具備可移植性、可分享性，並可透過技能中心 (Skills Hub) 進行社群貢獻。
- **全面的網路控制** —— 搜尋、擷取、瀏覽、視覺、影像生成、TTS。
- **MCP 支援** —— 連接任何 MCP 伺服器以擴展工具功能。
- **研究就緒** —— 批次處理、軌跡匯出、使用 Atropos 進行增強學習 (RL) 訓練。由 [Nous Research](https://nousresearch.com)（Hermes, Nomos 和 Psyche 模型背後的實驗室）開發。
