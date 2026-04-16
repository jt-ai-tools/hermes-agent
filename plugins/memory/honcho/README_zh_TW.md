# Honcho 記憶體供應商

AI 原生跨會話使用者建模，具備辯證式問答 (dialectic Q&A)、語義搜尋、同伴卡片 (peer cards) 及持久性結論功能。

> **Honcho 文件：** <https://docs.honcho.dev/v3/guides/integrations/hermes>

## 系統需求

- `pip install honcho-ai`
- 來自 [app.honcho.dev](https://app.honcho.dev) 的 Honcho API key，或自行託管的實例

## 安裝設定

```bash
hermes honcho setup    # 完整互動式精靈 (雲端或本地)
hermes memory setup    # 通用選擇器，同樣有效
```

或手動設定：
```bash
hermes config set memory.provider honcho
echo "HONCHO_API_KEY=your-key" >> ~/.hermes/.env
```

## 設定解析 (Config Resolution)

系統會從第一個存在的檔案讀取設定：

| 優先順序 | 路徑 | 範圍 |
|----------|------|-------|
| 1 | `$HERMES_HOME/honcho.json` | Profile 本地 (隔離的 Hermes 實例) |
| 2 | `~/.hermes/honcho.json` | 預設 Profile (共享的主機區塊) |
| 3 | `~/.honcho/config.json` | 全域 (跨應用程式互通) |

主機鍵值 (Host key) 衍生自作用中的 Hermes profile：`hermes` (預設) 或 `hermes.<profile>`。

## 工具 (Tools)

| 工具 | 呼叫 LLM？ | 說明 |
|------|-----------|-------------|
| `honcho_profile` | 否 | 使用者的同伴卡片 (peer card) —— 關鍵事實快照 |
| `honcho_search` | 否 | 對儲存的上下文進行語義搜尋 (預設 800 tokens，最大 2000) |
| `honcho_context` | 是 | 透過辯證推理 (dialectic reasoning) 產生的 LLM 綜合回答 |
| `honcho_conclude` | 否 | 寫入關於使用者的持久性事實 |

工具可用性取決於 `recallMode`：在 `context` 模式下隱藏，在 `tools` 和 `hybrid` 模式下始終存在。

## 完整設定參考 (Full Configuration Reference)

### 識別與連接 (Identity & Connection)

| 鍵值 (Key) | 類型 | 預設值 | 範圍 | 說明 |
|-----|------|---------|-------|-------------|
| `apiKey` | string | -- | root / host | API key。若未設定則退而使用 `HONCHO_API_KEY` 環境變數 |
| `baseUrl` | string | -- | root | 自行託管 Honcho 的 Base URL。本地 URL (`localhost`, `127.0.0.1`, `::1`) 會自動跳過 API key 驗證 |
| `environment` | string | `"production"` | root / host | SDK 環境映射 |
| `enabled` | bool | auto | root / host | 主開關。當 `apiKey` 或 `baseUrl` 存在時自動啟用 |
| `workspace` | string | host key | root / host | Honcho 工作區 ID |
| `peerName` | string | -- | root / host | 使用者同伴身分 (User peer identity) |
| `aiPeer` | string | host key | root / host | AI 同伴身分 (AI peer identity) |

### 記憶與回想 (Memory & Recall)

| 鍵值 (Key) | 類型 | 預設值 | 範圍 | 說明 |
|-----|------|---------|-------|-------------|
| `recallMode` | string | `"hybrid"` | root / host | `"hybrid"` (自動注入 + 工具), `"context"` (僅自動注入，隱藏工具), `"tools"` (僅工具，無注入)。舊版 `"auto"` 會正規化為 `"hybrid"` |
| `observationMode` | string | `"directional"` | root / host | 簡短預設值：`"directional"` (全部開啟) 或 `"unified"` (共享池)。使用 `observation` 物件進行細粒度控制 |
| `observation` | object | -- | root / host | 每個同伴的觀察設定 (見下文) |

#### 觀察設定 (Observation，細粒度)

1:1 映射到 Honcho 的每個同伴 `SessionPeerConfig`。可在 root 或每個 host 區塊設定 —— 每個 profile 可以有不同的觀察設定。若存在，則覆蓋 `observationMode` 預設值。

```json
"observation": {
  "user": { "observeMe": true, "observeOthers": true },
  "ai":   { "observeMe": true, "observeOthers": true }
}
```

| 欄位 | 預設值 | 說明 |
|-------|-------|----------|
| `user.observeMe` | `true` | 使用者同伴自我觀察 (Honcho 建立使用者表徵) |
| `user.observeOthers` | `true` | 使用者同伴觀察 AI 訊息 |
| `ai.observeMe` | `true` | AI 同伴自我觀察 (Honcho 建立 AI 表徵) |
| `ai.observeOthers` | `true` | AI 同伴觀察使用者訊息 (啟用跨同伴辯證) |

`observationMode` 預設值：
- `"directional"` (預設)：四個布林值皆為 `true`
- `"unified"`：user `observeMe=true`, AI `observeOthers=true`，其餘為 `false`

每個 Profile 的範例 —— coder profile 觀察使用者，但使用者不觀察 coder：

```json
"hosts": {
  "hermes.coder": {
    "observation": {
      "user": { "observeMe": true, "observeOthers": false },
      "ai":   { "observeMe": true, "observeOthers": true }
    }
  }
}
```

在 [Honcho 儀表板](https://app.honcho.dev) 中更改的設定會在對話初始化時同步回傳。

### 寫入行為 (Write Behavior)

| 鍵值 (Key) | 類型 | 預設值 | 範圍 | 說明 |
|-----|------|---------|-------|-------------|
| `writeFrequency` | string 或 int | `"async"` | root / host | `"async"` (背景執行緒), `"turn"` (每輪同步), `"session"` (結束時批次處理), 或整數 N (每 N 輪處理一次) |
| `saveMessages` | bool | `true` | root / host | 是否將訊息保存到 Honcho API |

### 會話解析 (Session Resolution)

| 鍵值 (Key) | 類型 | 預設值 | 範圍 | 說明 |
|-----|------|---------|-------|-------------|
| `sessionStrategy` | string | `"per-directory"` | root / host | `"per-directory"`, `"per-session"` (每次執行建立新的), `"per-repo"` (git 根目錄名稱), `"global"` (單一對話) |
| `sessionPeerPrefix` | bool | `false` | root / host | 在會話鍵值前加上同伴名稱 |
| `sessions` | object | `{}` | root | 手動目錄與對話名稱的映射：`{"/path/to/project": "my-session"}` |

### Token 預算與辯證 (Token Budgets & Dialectic)

| 鍵值 (Key) | 類型 | 預設值 | 範圍 | 說明 |
|-----|------|---------|-------|-------------|
| `contextTokens` | int | SDK 預設 | root / host | `context()` API 呼叫的 token 預算。同時限制預取截斷 (tokens x 4 字元) |
| `dialecticReasoningLevel` | string | `"low"` | root / host | `peer.chat()` 的基礎推理等級：`"minimal"`, `"low"`, `"medium"`, `"high"`, `"max"` |
| `dialecticDynamic` | bool | `true` | root / host | 根據查詢長度自動提升推理等級：`<120` 字元 = 基礎等級, `120-400` = +1, `>400` = +2 (上限為 `"high"`)。設為 `false` 則始終按原樣使用 `dialecticReasoningLevel` |
| `dialecticMaxChars` | int | `600` | root / host | 注入到系統提示詞中的辯證結果最大字元數 |
| `dialecticMaxInputChars` | int | `10000` | root / host | `peer.chat()` 的辯證查詢輸入最大字元數。Honcho 雲端限制：10k |
| `messageMaxChars` | int | `25000` | root / host | 透過 `add_messages()` 發送的每條訊息最大字元數。超過此限制的訊息會用 `[continued]` 標記分塊。Honcho 雲端限制：25k |

### 成本意識 (進階)

這些是從 root 設定物件讀取的，而不是 host 區塊。必須在 `honcho.json` 中手動設定。

| 鍵值 (Key) | 類型 | 預設值 | 說明 |
|-----|------|---------|-------------|
| `injectionFrequency` | string | `"every-turn"` | `"every-turn"` (每輪注入) 或 `"first-turn"` (僅在第 0 輪注入上下文) |
| `contextCadence` | int | `1` | `context()` API 呼叫之間的最少輪數 |
| `dialecticCadence` | int | `1` | `peer.chat()` API 呼叫之間的最少輪數 |
| `reasoningLevelCap` | string | -- | 自動提升推理等級的硬性上限：`"minimal"`, `"low"`, `"mid"`, `"high"` |

### 硬編碼限制 (不可調整)

| 限制 | 數值 | 位置 |
|-------|-------|----------|
| 搜尋工具最大 tokens | 2000 (硬上限), 800 (預設) | `__init__.py` handle_tool_call |
| 同伴卡片抓取 tokens | 200 | `session.py` get_peer_card |

## 設定優先級 (Config Precedence)

對於每個鍵值，解析順序為：**host 區塊 > root > 環境變數 > 預設值**。

主機鍵值衍生：`HERMES_HONCHO_HOST` 環境變數 > 作用中的 profile (`hermes.<profile>`) > `"hermes"`。

## 環境變數

| 變數 | 對應設定 |
|----------|-------------|
| `HONCHO_API_KEY` | `apiKey` |
| `HONCHO_BASE_URL` | `baseUrl` |
| `HONCHO_ENVIRONMENT` | `environment` |
| `HERMES_HONCHO_HOST` | 覆蓋主機鍵值 (Host key) |

## CLI 指令

| 指令 | 說明 |
|---------|-------------|
| `hermes honcho setup` | 完整互動式安裝精靈 |
| `hermes honcho status` | 顯示目前 profile 解析後的設定 |
| `hermes honcho enable` / `disable` | 切換目前 profile 的 Honcho 開關 |
| `hermes honcho mode <mode>` | 更改回想 (recall) 或觀察 (observation) 模式 |
| `hermes honcho peer --user <name>` | 更新使用者同伴名稱 |
| `hermes honcho peer --ai <name>` | 更新 AI 同伴名稱 |
| `hermes honcho tokens --context <N>` | 設定上下文 token 預算 |
| `hermes honcho tokens --dialectic <N>` | 設定辯證最大字元數 |
| `hermes honcho map <name>` | 將目前目錄映射到會話名稱 |
| `hermes honcho sync` | 為所有 Hermes profile 建立主機區塊 (host blocks) |

## 設定範例

```json
{
  "apiKey": "your-key",
  "workspace": "hermes",
  "peerName": "eri",
  "hosts": {
    "hermes": {
      "enabled": true,
      "aiPeer": "hermes",
      "workspace": "hermes",
      "peerName": "eri",
      "recallMode": "hybrid",
      "observation": {
        "user": { "observeMe": true, "observeOthers": true },
        "ai": { "observeMe": true, "observeOthers": true }
      },
      "writeFrequency": "async",
      "sessionStrategy": "per-directory",
      "dialecticReasoningLevel": "low",
      "dialecticMaxChars": 600,
      "saveMessages": true
    },
    "hermes.coder": {
      "enabled": true,
      "aiPeer": "coder",
      "workspace": "hermes",
      "peerName": "eri",
      "observation": {
        "user": { "observeMe": true, "observeOthers": false },
        "ai": { "observeMe": true, "observeOthers": true }
      }
    }
  },
  "sessions": {
    "/home/user/myproject": "myproject-main"
  }
}
```
