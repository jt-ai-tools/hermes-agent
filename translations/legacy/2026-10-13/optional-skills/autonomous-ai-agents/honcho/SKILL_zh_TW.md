---
name: honcho
description: 為 Hermes 設定並使用 Honcho 記憶 — 包含跨工作階段使用者建模、多設定檔同儕隔離、觀察設定與辯證推理。在設定 Honcho、排查記憶問題、管理具有 Honcho 同儕 (peer) 的設定檔，或調整觀察與召回設定時使用。
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [Honcho, 記憶, 設定檔, 觀察, 辯證, 使用者建模]
    homepage: https://docs.honcho.dev
    related_skills: [hermes-agent]
prerequisites:
  pip: [honcho-ai]
---

# Hermes 的 Honcho 記憶

Honcho 提供 AI 原生的跨工作階段使用者建模功能。它能跨對話學習使用者特徵，並為每個 Hermes 設定檔提供專屬的同儕身份，同時共享統一的使用者視圖。

## 何時使用

- 設定 Honcho (雲端或自行託管)
- 排查記憶功能失效 / 同儕同步問題
- 建立多設定檔環境，讓每個代理人擁有自己的 Honcho 同儕
- 調整觀察、召回或寫入頻率設定
- 瞭解 4 個 Honcho 工具的功能及使用時機

## 設定

### 雲端 (app.honcho.dev)

```bash
hermes honcho setup
# 選擇 "cloud"，從 https://app.honcho.dev 貼上 API 金鑰
```

### 自行託管

```bash
hermes honcho setup
# 選擇 "local"，輸入基礎 URL (例如 http://localhost:8000)
```

參閱：https://docs.honcho.dev/v3/guides/integrations/hermes#running-honcho-locally-with-hermes

### 驗證

```bash
hermes honcho status    # 顯示解析後的設定、連線測試與同儕資訊
```

## 架構

### 同儕 (Peers)

Honcho 將對話建模為 **同儕** 之間的互動。Hermes 為每個工作階段建立兩個同儕：

- **使用者同儕** (`peerName`)：代表真人。Honcho 從觀察到的訊息中建立使用者畫像。
- **AI 同儕** (`aiPeer`)：代表此 Hermes 實例。每個設定檔都有自己的 AI 同儕，使代理人能發展出獨立的觀點。

### 觀察 (Observation)

每個同儕都有兩個觀察切換開關，控制 Honcho 從中學習的內容：

| 開關 | 作用 |
|--------|-------------|
| `observeMe` | 觀察同儕自己的訊息 (建立自我表現) |
| `observeOthers` | 觀察其他同儕的訊息 (建立跨同儕理解) |

預設情況：四個開關全部 **開啟** (全向雙向觀察)。

在 `honcho.json` 中按同儕進行設定：

```json
{
  "observation": {
    "user": { "observeMe": true, "observeOthers": true },
    "ai":   { "observeMe": true, "observeOthers": true }
  }
}
```

或者使用簡寫預設值 (presets)：

| 預設值 | 使用者 | AI | 使用場景 |
|--------|------|----|----------|
| `"directional"` (預設) | me:開啟, others:開啟 | me:開啟, others:開啟 | 多代理人，完整記憶 |
| `"unified"` | me:開啟, others:關閉 | me:關閉, others:開啟 | 單一代理人，僅使用者建模 |

在 [Honcho 控制面板](https://app.honcho.dev) 中更改的設定會在工作階段初始化時同步回傳 — 伺服器端設定優先於本地預設值。

### 工作階段 (Sessions)

Honcho 工作階段定義了訊息與觀察的範圍。策略選項：

| 策略 | 行為 |
|----------|----------|
| `per-directory` (預設) | 每個工作目錄一個工作階段 |
| `per-repo` | 每個 Git 儲存庫根目錄一個工作階段 |
| `per-session` | 每次 Hermes 執行時建立新的 Honcho 工作階段 |
| `global` | 所有目錄共享單一工作階段 |

手動覆蓋：`hermes honcho map my-project-name`

### 召回模式 (Recall Modes)

代理人存取 Honcho 記憶的方式：

| 模式 | 自動注入上下文？ | 是否提供工具？ | 使用場景 |
|------|---------------------|-----------------|----------|
| `hybrid` (預設) | 是 | 是 | 代理人決定何時使用工具 vs 自動上下文 |
| `context` | 是 | 否 (隱藏) | 最低權杖成本，無工具呼叫 |
| `tools` | 否 | 是 | 代理人顯式控制所有記憶存取 |

## 多設定檔設定

每個 Hermes 設定檔都會獲得專屬的 Honcho AI 同儕，同時共享相同的空間 (使用者上下文)。這意味著：

- 所有設定檔看到的使用者畫像是一致的。
- 每個設定檔建立自己的 AI 身份與觀察。
- 由一個設定檔寫入的結論可供其他設定檔在共享空間中查看。

### 建立帶有 Honcho 同儕的設定檔

```bash
hermes profile create coder --clone
# 建立主機區塊 hermes.coder，AI 同儕為 "coder"，繼承自預設設定
```

`--clone` 對 Honcho 的作用：
1. 在 `honcho.json` 中建立 `hermes.coder` 主機區塊。
2. 將 `aiPeer` 設定為 "coder" (設定檔名稱)。
3. 繼承 `workspace`, `peerName`, `writeFrequency`, `recallMode` 等預設值。
4. 預先在 Honcho 中建立同儕，以便在第一條訊息前就已存在。

### 補回現有設定檔

```bash
hermes honcho sync    # 為尚未擁有主機區塊的所有設定檔建立主機區塊
```

### 按設定檔進行設定

在主機區塊中覆蓋任何設定：

```json
{
  "hosts": {
    "hermes.coder": {
      "aiPeer": "coder",
      "recallMode": "tools",
      "observation": {
        "user": { "observeMe": true, "observeOthers": false },
        "ai": { "observeMe": true, "observeOthers": true }
      }
    }
  }
}
```

## 工具

代理人擁有 4 個 Honcho 工具 (在 `context` 召回模式下隱藏)：

### `honcho_profile`
快速獲取關於使用者的事實快照 — 包含名稱、角色、偏好、模式。不進行 LLM 呼叫，成本極低。適用於對話開始或快速查閱。

### `honcho_search`
對儲存的上下文進行語意搜尋。返回按相關性排序的原始摘錄，不進行 LLM 合成。預設 800 個權杖，最大 2000 個。當你想要獲取特定的過去事實來自行推理時使用。

### `honcho_context`
由 Honcho 的辯證推理 (Honcho 後端的 LLM 呼叫) 回答自然語言問題。成本較高，品質較高。可以查詢使用者 (預設) 或 AI 同儕。

### `honcho_conclude`
寫入關於使用者的持久事實。結論會隨著時間建立使用者畫像。當使用者陳述偏好、糾正你或分享值得記住的事情時使用。

## 設定參考

設定檔：`$HERMES_HOME/honcho.json` (設定檔本地) 或 `~/.honcho/config.json` (全域)。

### 關鍵設定

| 鍵名 | 預設值 | 描述 |
|-----|---------|-------------|
| `apiKey` | -- | API 金鑰 ([在此獲取](https://app.honcho.dev)) |
| `baseUrl` | -- | 自行託管 Honcho 的基礎 URL |
| `peerName` | -- | 使用者同儕身份 |
| `aiPeer` | host key | AI 同儕身份 |
| `workspace` | host key | 共享空間 ID |
| `recallMode` | `hybrid` | `hybrid`, `context` 或 `tools` |
| `observation` | 全開啟 | 各同儕的 `observeMe`/`observeOthers` 布林值 |
| `writeFrequency` | `async` | `async`, `turn`, `session` 或整數 N |
| `sessionStrategy` | `per-directory` | `per-directory`, `per-repo`, `per-session`, `global` |
| `dialecticReasoningLevel` | `low` | `minimal`, `low`, `medium`, `high`, `max` |
| `dialecticDynamic` | `true` | 根據查詢長度自動提升推理等級。`false` = 固定等級 |
| `messageMaxChars` | `25000` | 每條訊息最大字元數 (超過則分塊) |
| `dialecticMaxInputChars` | `10000` | 辯證查詢輸入的最大字元數 |

### 成本意識 (進階，僅限根設定)

| 鍵名 | 預設值 | 描述 |
|-----|---------|-------------|
| `injectionFrequency` | `every-turn` | `every-turn` (每回合) 或 `first-turn` (第一回合) |
| `contextCadence` | `1` | 上下文 API 呼叫之間的最小回合數 |
| `dialecticCadence` | `1` | 辯證 API 呼叫之間的最小回合數 |

## 疑難排解

### 「Honcho not configured」(Honcho 未設定)
執行 `hermes honcho setup`。確保 `~/.hermes/config.yaml` 中有 `memory.provider: honcho`。

### 記憶無法跨工作階段持久化
檢查 `hermes honcho status` — 驗證 `saveMessages: true` 且 `writeFrequency` 不是 `session` (這僅在退出時寫入)。

### 設定檔未獲得專屬同儕
建立時使用 `--clone`：`hermes profile create <名稱> --clone`。針對現有設定檔：`hermes honcho sync`。

### 控制面板中的觀察變更未反映
觀察設定在每次工作階段初始化時從伺服器同步。在 Honcho UI 中更改設定後，請啟動新的工作階段。

### 訊息被截斷
超過 `messageMaxChars` (預設 25k) 的訊息會自動標記 `[continued]` 並分塊。如果你經常遇到此問題，請檢查工具結果或技能內容是否撐大了訊息體積。

## CLI 命令

| 命令 | 描述 |
|---------|-------------|
| `hermes honcho setup` | 互動式設定精靈 (雲端/本地、身份、觀察、召回、工作階段) |
| `hermes honcho status` | 顯示當前設定檔解析後的設定、連線測試與同儕資訊 |
| `hermes honcho enable` | 為當前設定檔啟用 Honcho (必要時建立主機區塊) |
| `hermes honcho disable` | 為當前設定檔停用 Honcho |
| `hermes honcho peer` | 顯示或更新同儕名稱 (`--user <名稱>`, `--ai <名稱>`, `--reasoning <等級>`) |
| `hermes honcho peers` | 顯示所有設定檔的同儕身份 |
| `hermes honcho mode` | 顯示或設定召回模式 (`hybrid`, `context`, `tools`) |
| `hermes honcho tokens` | 顯示或設定權杖預算 (`--context <N>`, `--dialectic <N>`) |
| `hermes honcho sessions` | 列出已知的目錄對工作階段名稱映射 |
| `hermes honcho map <名稱>` | 將當前工作目錄映射至 Honcho 工作階段名稱 |
| `hermes honcho identity` | 植入 AI 同儕身份或顯示雙方同儕表現 |
| `hermes honcho sync` | 為尚未擁有主機區塊的所有 Hermes 設定檔建立主機區塊 |
| `hermes honcho migrate` | 從 OpenClaw 原生記憶遷移至 Hermes + Honcho 的逐步指南 |
| `hermes memory setup` | 通用記憶供應商選擇器 (選擇 "honcho" 會執行相同的精靈) |
| `hermes memory status` | 顯示作用中的記憶供應商與設定 |
| `hermes memory off` | 停用外部記憶供應商 |
