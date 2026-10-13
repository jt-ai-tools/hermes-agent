---
name: plan
description: Hermes 的計畫模式 — 檢查上下文，並在當前工作區的 `.hermes/plans/` 目錄下撰寫 Markdown 計畫，但不執行具體工作。
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [planning, plan-mode, implementation, workflow]
    related_skills: [writing-plans, subagent-driven-development]
---

# 計畫模式 (Plan Mode)

當使用者需要的是計畫而非直接執行時，請使用此技能。

## 核心行為

在本輪對話中，你僅負責規劃。

- 不要編寫程式碼。
- 除了計畫用的 Markdown 檔案外，不要修改專案檔案。
- 不要執行任何具備修改性質的終端機命令、commit、push 或執行外部操作。
- 如有需要，你可以使用唯讀命令/工具來檢查儲存庫或其他上下文。
- 你的交付成果是儲存在當前工作區 `.hermes/plans/` 目錄下的 Markdown 計畫檔案。

## 輸出要求

撰寫一份具體且可執行的 Markdown 計畫。

視情況包含以下內容：
- 目標 (Goal)
- 目前上下文 / 假設 (Current context / assumptions)
- 建議方案 (Proposed approach)
- 逐步計畫 (Step-by-step plan)
- 可能變動的檔案 (Files likely to change)
- 測試 / 驗證 (Tests / validation)
- 風險、權衡與待決問題 (Risks, tradeoffs, and open questions)

如果任務與程式碼相關，請包含確切的檔案路徑、可能的測試目標以及驗證步驟。

## 儲存位置

使用 `write_file` 將計畫儲存在：
- `.hermes/plans/YYYY-MM-DD_HHMMSS-<slug>.md`

請將此路徑視為相對於當前工作目錄 / 後端工作區的路徑。Hermes 的檔案工具具備後端感知能力，因此使用此相對路徑可確保計畫檔案在 local、docker、ssh、modal 及 daytona 等各種後端工作區中保持一致。

如果執行環境提供了特定的目標路徑，請使用該路徑。
否則，請在 `.hermes/plans/` 下自行建立一個包含時間戳記的檔案名稱。

## 互動風格

- 如果請求足夠明確，請直接撰寫計畫。
- 如果 `/plan` 命令沒有伴隨明確說明，請從目前的對話上下文中推斷任務。
- 如果任務確實定義不明，請提出簡短的澄清問題，而不要隨意猜測。
- 儲存計畫後，簡短回覆你規劃的內容以及儲存路徑。
