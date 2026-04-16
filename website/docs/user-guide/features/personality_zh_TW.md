---
sidebar_position: 9
title: "個性與 SOUL.md"
description: "使用全域 SOUL.md、內建個性以及自訂人格定義來客製化 Hermes Agent 的個性"
---

# 個性與 SOUL.md

Hermes Agent 的個性是完全可自訂的。`SOUL.md` 是**主要身份** — 它是系統提示中的第一項內容，定義了代理是誰。

- `SOUL.md` — 一個持久的人格檔案，位於 `HERMES_HOME` 中，作為代理的身份（系統提示中的第 1 個插槽）
- 內建或自訂的 `/personality` 預設值 — 工作階段級別的系統提示覆蓋層

如果您想改變 Hermes 的身份 — 或將其替換為完全不同的代理人格 — 請編輯 `SOUL.md`。

## SOUL.md 目前的運作方式

Hermes 現在會自動在以下位置生成預設的 `SOUL.md`：

```text
~/.hermes/SOUL.md
```

更準確地說，它使用目前實例的 `HERMES_HOME`，因此如果您使用自訂主目錄執行 Hermes，它將使用：

```text
$HERMES_HOME/SOUL.md
```

### 重要行為

- **SOUL.md 是代理的主要身份。** 它佔據系統提示中的第 1 個插槽，替換了硬編碼的預設身份。
- 如果 `SOUL.md` 尚不存在，Hermes 會自動創建一個初始的 `SOUL.md`。
- 現有的使用者 `SOUL.md` 檔案絕不會被覆寫。
- Hermes 僅從 `HERMES_HOME` 載入 `SOUL.md`。
- Hermes 不會在目前工作目錄中尋找 `SOUL.md`。
- 如果 `SOUL.md` 存在但為空，或無法載入，Hermes 會回退到內建的預設身份。
- 如果 `SOUL.md` 有內容，該內容在經過安全掃描和截斷後會逐字注入。
- `SOUL.md` **不會**在上下文檔案部分重複出現 — 它僅作為身份出現一次。

這使得 `SOUL.md` 成為一個真正的按使用者或按實例定義的身份，而不僅僅是一個附加層。

## 為什麼這樣設計

這能保持個性的可預測性。

如果 Hermes 從您啟動它的任何目錄載入 `SOUL.md`，您的個性可能會在不同專案之間意外改變。透過僅從 `HERMES_HOME` 載入，個性屬於 Hermes 實例本身。

這也使得教學更容易：
- 「編輯 `~/.hermes/SOUL.md` 以更改 Hermes 的預設個性。」

## 在哪裡編輯

對於大多數使用者：

```bash
~/.hermes/SOUL.md
```

如果您使用自訂主目錄：

```bash
$HERMES_HOME/SOUL.md
```

## SOUL.md 中應該放什麼？

用於持久的語氣和個性引導，例如：
- 語氣
- 溝通風格
- 直接程度
- 預設互動風格
- 風格上要避免的事項
- Hermes 應如何處理不確定性、分歧或模稜兩可

較少用於：
- 一次性的專案指令
- 檔案路徑
- 儲存庫慣例
- 臨時的工作流程細節

這些內容屬於 `AGENTS.md`，而非 `SOUL.md`。

## 良好的 SOUL.md 內容

一個良好的 SOUL 檔案應該：
- 在不同上下文中保持穩定
- 足夠廣泛以適用於多種對話
- 足夠具體以實質性地塑造語氣
- 專注於溝通和身份，而非特定任務的指令

### 範例

```markdown
# 個性 (Personality)

你是一位具有敏銳品味且務實的高級工程師。
你追求真實、清晰和實用，而非客套的禮貌。

## 風格
- 直接而不冷漠
- 內容充實，避免廢話
- 當某個想法很糟糕時，請提出反對意見
- 坦誠承認不確定性
- 除非深度解析有其用處，否則請保持解釋簡潔

## 應避免的事項
- 阿諛奉承
- 炒作語言
- 如果使用者的表述有誤，不要重複使用者的說法
- 過度解釋顯而易見的事情

## 技術立場
- 偏好簡單的系統而非精巧的系統
- 關心營運現實，而非理想化的架構
- 將邊緣案例視為設計的一部分，而非事後清理
```

## Hermes 注入提示詞的內容

`SOUL.md` 的內容直接進入系統提示的第 1 個插槽 — 即代理身份位置。周圍不會添加任何封裝語言。

內容會經過：
- 提示詞注入 (prompt-injection) 掃描
- 如果太大則進行截斷

如果檔案為空、僅包含空白字元或無法讀取，Hermes 會回退到內建的預設身份（「你是 Hermes Agent，由 Nous Research 創建的智慧 AI 助理...」）。此回退也適用於設置了 `skip_context_files` 的情況（例如在子代理/委派上下文中）。

## 安全掃描

與其他包含上下文的檔案一樣，`SOUL.md` 在包含之前會針對提示詞注入模式進行掃描。

這意味著您仍應專注於人格/語氣，而不是試圖潛入奇怪的元指令 (meta-instructions)。

## SOUL.md vs AGENTS.md

這是最重要的區別。

### SOUL.md
用於：
- 身份
- 語氣
- 風格
- 預設溝通方式
- 個性層面的行為

### AGENTS.md
用於：
- 專案架構
- 編碼慣例
- 工具偏好
- 儲存庫特定的工作流程
- 指令、連接埠、路徑、部署筆記

一個有用的規則：
- 如果它應該跟隨您到處去，它屬於 `SOUL.md`
- 如果它屬於某個專案，它屬於 `AGENTS.md`

## SOUL.md vs `/personality`

`SOUL.md` 是您持久的預設個性。

`/personality` 是一個工作階段級別的覆蓋層，用於更改或補充目前的系統提示。

因此：
- `SOUL.md` = 基線語氣
- `/personality` = 暫時的模式切換

範例：
- 保持一個務實的預設 SOUL，然後在輔導對話中使用 `/personality teacher`
- 保持一個簡潔的 SOUL，然後在腦力激盪中使用 `/personality creative`

## 內建個性

Hermes 附帶了可以使用 `/personality` 切換的內建個性。

| 名稱 | 描述 |
|------|-------------|
| **helpful** | 友善、通用的助理 |
| **concise** | 簡短、切中要點的回應 |
| **technical** | 詳細、準確的技術專家 |
| **creative** | 創新、打破框框的思考 |
| **teacher** | 耐心的教育者，提供清晰的範例 |
| **kawaii** | 可愛表情、閃亮亮且充滿熱情 ★ |
| **catgirl** | 貓娘 Neko-chan，帶有貓一樣的表情，nya~ |
| **pirate** | Hermes 船長，精通技術的海盜 |
| **shakespeare** | 帶有戲劇色彩的詩意散文 |
| **surfer** | 完全放鬆的哥兒們氛圍 |
| **noir** | 硬漢派偵探旁白 |
| **uwu** | 搭配 uwu 語體展現極致可愛 |
| **philosopher** | 對每個查詢進行深度思考 |
| **hype** | 能量與熱情爆表！！！ |

## 使用指令切換個性

### CLI

```text
/personality
/personality concise
/personality technical
```

### 通訊平台

```text
/personality teacher
```

這些是方便的覆蓋層，但除非覆蓋層有實質性改變，否則您的全域 `SOUL.md` 仍會為 Hermes 提供其持久的預設個性。

## 配置中的自訂個性

您也可以在 `~/.hermes/config.yaml` 的 `agent.personalities` 下定義具名的自訂個性。

```yaml
agent:
  personalities:
    codereviewer: >
      你是一位細緻的程式碼審查員。請識別錯誤、安全問題、
      效能疑慮和不明確的設計選擇。請保持精確且具建設性。
```

然後使用以下指令切換：

```text
/personality codereviewer
```

## 建議的工作流程

一個強大的預設設置是：

1. 在 `~/.hermes/SOUL.md` 中保持一個深思熟慮的全域 `SOUL.md`
2. 將專案指令放在 `AGENTS.md` 中
3. 僅在您想要暫時切換模式時使用 `/personality`

這為您提供了：
- 穩定的語氣
- 歸屬其位的專案特定行為
- 需要時的臨時控制

## 個性如何與完整提示詞互動

在高層級上，提示詞堆疊 (prompt stack) 包括：
1. **SOUL.md**（代理身份 — 或在 SOUL.md 不可用時的內建回退）
2. 工具感知行為引導
3. 記憶/使用者上下文
4. 技能引導
5. 上下文檔案（`AGENTS.md`、`.cursorrules`）
6. 時間戳記
7. 平台特定格式提示
8. 選用的系統提示覆蓋層（例如 `/personality`）

`SOUL.md` 是基礎 — 其他所有內容都建立在其之上。

## 相關文件

- [上下文檔案](/docs/user-guide/features/context-files)
- [組態設定](/docs/user-guide/configuration)
- [技巧與最佳實踐](/docs/guides/tips)
- [SOUL.md 指南](/docs/guides/use-soul-with-hermes)

## CLI 外觀 vs 對話個性

對話個性與 CLI 外觀是分開的：

- `SOUL.md`、`agent.system_prompt` 和 `/personality` 影響 Hermes 如何說話
- `display.skin` 和 `/skin` 影響 Hermes 在終端機中的外觀

有關終端機外觀，請參閱 [外觀與主題](./skins.md)。
