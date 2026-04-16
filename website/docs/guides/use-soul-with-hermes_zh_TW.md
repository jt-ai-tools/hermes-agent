---
sidebar_position: 7
title: "在 Hermes 中使用 SOUL.md"
description: "如何使用 SOUL.md 來塑造 Hermes Agent 的預設語氣、哪些內容應該放在這裡，以及它與 AGENTS.md 和 /personality 的區別"
---

# 在 Hermes 中使用 SOUL.md

`SOUL.md` 是您的 Hermes 實例的**核心身份 (Identity)**。它是系統提示語（System Prompt）中的第一項內容 —— 它定義了 Agent 是誰、它如何說話以及它應該避免什麼。

如果您希望每次與 Hermes 對話時它都像同一個助手，或者如果您想用自己的設定完全取代 Hermes 的人格 (Persona)，那麼這就是您需要編輯的檔案。

## SOUL.md 的用途

將 `SOUL.md` 用於：
- 語調 (Tone)
- 個性 (Personality)
- 溝通風格
- Hermes 應該表現得直接還是熱情
- Hermes 在風格上應該避免什麼
- Hermes 應該如何處理不確定性、分歧和模糊情況

簡而言之：
- `SOUL.md` 關乎「Hermes 是誰」以及「Hermes 如何說話」。

## SOUL.md 不該用於什麼

不要將其用於：
- 特定儲存庫的編碼規範
- 檔案路徑
- 指令
- 服務埠號 (Ports)
- 架構筆記
- 專案工作流指令

這些內容應該放在 `AGENTS.md` 中。

一個簡單的原則：
- 如果該規則應套用到「所有地方」，請放在 `SOUL.md`。
- 如果該規則僅屬於「某個專案」，請放在 `AGENTS.md`。

## 檔案位置

Hermes 現在僅使用當前實例的全域 SOUL 檔案：

```text
~/.hermes/SOUL.md
```

如果您使用自訂的家目錄運行 Hermes，則位置為：

```text
$HERMES_HOME/SOUL.md
```

## 首次運行行為

如果 `SOUL.md` 尚不存在，Hermes 會自動為您生成一個初始的 `SOUL.md`。

這意味著大多數使用者現在一開始就擁有一個可以立即閱讀和編輯的實際檔案。

重要提示：
- 如果您已經擁有 `SOUL.md`，Hermes 不會覆寫它。
- 如果檔案存在但內容為空，Hermes 不會從中向提示語添加任何內容。

## Hermes 如何使用它

當 Hermes 開始一個工作階段時，它會從 `HERMES_HOME` 讀取 `SOUL.md`，掃描其中的提示語注入（Prompt Injection）模式，根據需要進行截斷，並將其作為 **Agent 身份** —— 放在系統提示語的第 1 個位置。這意味著 SOUL.md 會完全取代內建的預設身份文本。

如果 `SOUL.md` 缺失、為空或無法載入，Hermes 將退而使用內建的預設身份。

檔案周圍不會添加任何包裝語句。內容本身至關重要 —— 請按照您希望 Agent 思考和說話的方式來撰寫。

## 建議的第一次修改

如果您不想做太多修改，只需打開檔案並更改幾行，讓它聽起來更像您。

例如：

```markdown
你說話直接、冷靜且技術精確。
比起客套話，你更看重實質內容。
當某個想法很糟糕時，請清楚地反駁。
除非更深層的細節有用，否則請保持回答簡明扼要。
```

光是這些修改就能明顯改變 Hermes 給人的感覺。

## 風格範例

### 1. 務實的工程師 (Pragmatic Engineer)

```markdown
你是一位務實的資深工程師。
比起聽起來很厲害，你更在意正確性和運行的實際狀況。

## 風格
- 說話直接
- 除非複雜性需要深度，否則請保持簡潔
- 當某件事是個壞主意時請直說
- 比起理想化的抽象概念，更偏好實際的權衡 (Tradeoffs)

## 避免
- 奉承
- 炒作性語言
- 過度解釋顯而易見的事情
```

### 2. 研究夥伴 (Research Partner)

```markdown
你是一位心思細密的研究合作夥伴。
你充滿好奇心，對不確定性誠實，並對不尋常的想法感到興奮。

## 風格
- 探索各種可能性，而不假裝確定
- 區分推測與證據
- 當想法空間描述不足時，請提出澄清問題
- 比起淺薄的完整性，更偏好概念深度
```

### 3. 老師 / 解說者 (Teacher / Explainer)

```markdown
你是一位有耐心的技術老師。
你在意的是理解，而非表現。

## 風格
- 解釋清晰
- 在有幫助時使用範例
- 除非使用者暗示，否則不要預設對方已具備相關知識
- 從直覺建立到細節
```

### 4. 嚴厲的審查者 (Tough Reviewer)

```markdown
你是一位嚴謹的審查者。
你很公正，但不會軟化重要的批評。

## 風格
- 直接指出薄弱的假設
- 優先考慮正確性而非和諧
- 明確說明風險和權衡 (Tradeoffs)
- 比起模糊的外交辭令，更偏好坦率的清晰
```

## 什麼是強大的 SOUL.md？

強大的 `SOUL.md` 具備以下特點：
- 穩定
- 廣泛適用
- 語氣具體
- 不會充斥著臨時性的指令

弱小的 `SOUL.md` 具備以下特點：
- 充滿專案細節
- 自相矛盾
- 試圖微調每一種回應的形式
- 大多是像「要提供幫助」和「要清晰」之類的通用廢話

Hermes 已經在努力做到提供幫助和清晰了。`SOUL.md` 應該添加真正的個性和風格，而不是重複顯而易見的預設設定。

## 建議結構

您不需要標題，但標題會有所幫助。

一個運作良好的簡單結構：

```markdown
# 身份 (Identity)
Hermes 是誰。

# 風格 (Style)
Hermes 聽起來應該如何。

# 避免 (Avoid)
Hermes 不應該做什麼。

# 預設行為 (Defaults)
當出現模糊情況時，Hermes 應該如何表現。
```

## SOUL.md vs /personality

這兩者是互補的。

使用 `SOUL.md` 作為持久的基準線。
使用 `/personality` 進行臨時的模式切換。

例如：
- 您的預設 SOUL 是務實且直接的。
- 然後在某個工作階段中，您使用 `/personality teacher`。
- 稍後您可以切換回來，而無需更改您的基準語氣檔案。

## SOUL.md vs AGENTS.md

這是最常見的錯誤。

### 放在 SOUL.md 的內容
- 「說話直接。」
- 「避免炒作性語言。」
- 「除非深度有助於理解，否則偏好簡短回答。」
- 「當使用者錯誤時請反駁。」

### 放在 AGENTS.md 的內容
- 「使用 pytest，不要使用 unittest。」
- 「前端程式碼位於 `frontend/`。」
- 「永遠不要直接編輯 Migration 檔案。」
- 「API 運行在 8000 埠。」

## 如何編輯

```bash
nano ~/.hermes/SOUL.md
```

或者

```bash
vim ~/.hermes/SOUL.md
```

然後重啟 Hermes 或開始新的工作階段。

## 實用的工作流

1. 從生成的預設檔案開始。
2. 刪除任何聽起來不符合您想要語氣的內容。
3. 添加 4-8 行明確定義語調和預設行為的內容。
4. 與 Hermes 對話一段時間。
5. 根據感覺不對的地方進行調整。

這種迭代方法比試圖一次設計出完美的人格更有效。

## 故障排除

### 我編輯了 SOUL.md，但 Hermes 聽起來還是老樣子

請檢查：
- 您編輯的是 `~/.hermes/SOUL.md` 或 `$HERMES_HOME/SOUL.md`。
- 而非某個專案本地的 `SOUL.md`。
- 檔案不是空的。
- 編輯後重啟了工作階段。
- 沒有 `/personality` 覆蓋層主導了結果。

### Hermes 忽略了 SOUL.md 的部分內容

可能原因：
- 更高優先級的指令覆蓋了它。
- 檔案中包含相互矛盾的引導。
- 檔案太長而被截斷。
- 部分文本看起來像提示語注入（Prompt Injection）內容，可能被掃描器封鎖或更改。

### 我的 SOUL.md 變得太過針對特定專案

請將專案指令移動到 `AGENTS.md` 中，並保持 `SOUL.md` 專注於身份和風格。

## 相關文件

- [個性設定與 SOUL.md](/docs/user-guide/features/personality)
- [上下文檔案](/docs/user-guide/features/context-files)
- [組態設定](/docs/user-guide/configuration)
- [小技巧與最佳實踐](/docs/guides/tips)
