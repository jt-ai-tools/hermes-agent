---
sidebar_position: 4
title: "記憶提供者"
description: "外部記憶提供者外掛程式 — Honcho、OpenViking、Mem0、Hindsight、Holographic、RetainDB、ByteRover、Supermemory"
---

# 記憶提供者 (Memory Providers)

Hermes Agent 附帶了 8 個外部記憶提供者外掛程式，讓代理具備超越內建 MEMORY.md 和 USER.md 的持久化、跨工作階段知識。一次只能有一個外部提供者處於活動狀態 — 內建記憶將始終與其並行活動。

## 快速入門

```bash
hermes memory setup      # 互動式選擇器 + 配置
hermes memory status     # 檢查哪些提供者處於活動狀態
hermes memory off        # 停用外部提供者
```

您也可以透過 `hermes plugins` → 提供者外掛程式 (Provider Plugins) → 記憶提供者 (Memory Provider) 來選擇活動的記憶提供者。

或在 `~/.hermes/config.yaml` 中手動設置：

```yaml
memory:
  provider: openviking   # 或 honcho、mem0、hindsight、holographic、retaindb、byterover、supermemory
```

## 運作方式

當記憶提供者處於活動狀態時，Hermes 會自動執行以下操作：

1. **注入提供者上下文** 到系統提示中（提供者所知道的內容）
2. **在每回合之前預取相關記憶**（背景執行，非阻塞）
3. **在每次回應後同步對話回合** 到提供者
4. **在工作階段結束時提取記憶**（針對支援此功能的提供者）
5. **將內建記憶的寫入鏡像到外部提供者**
6. **添加提供者專屬工具**，以便代理可以搜尋、儲存和管理記憶

內建記憶 (MEMORY.md / USER.md) 繼續像以前一樣運作。外部提供者是附加的。

## 可用的提供者

### Honcho

具備辯證式問答、語義搜尋和持久化結論的 AI 原生跨工作階段使用者建模。

| | |
|---|---|
| **最適合** | 具有跨工作階段上下文的多代理系統、使用者-代理對齊 |
| **需要** | `pip install honcho-ai` + [API 金鑰](https://app.honcho.dev) 或自代管實例 |
| **數據儲存** | Honcho 雲端或自代管 |
| **成本** | Honcho 定價（雲端） / 免費（自代管） |

**工具：** `honcho_profile`（同伴卡片）、`honcho_search`（語義搜尋）、`honcho_context`（LLM 合成）、`honcho_conclude`（儲存事實）

**設置嚮導：**
```bash
hermes honcho setup        # (舊版指令) 
# 或
hermes memory setup        # 選擇 "honcho"
```

**配置：** `$HERMES_HOME/honcho.json`（設定檔本地）或 `~/.honcho/config.json`（全域）。解析順序：`$HERMES_HOME/honcho.json` > `~/.hermes/honcho.json` > `~/.honcho/config.json`。請參閱 [配置參考](https://github.com/hermes-ai/hermes-agent/blob/main/plugins/memory/honcho/README.md) 和 [Honcho 整合指南](https://docs.honcho.dev/v3/guides/integrations/hermes)。

<details>
<summary>關鍵配置選項</summary>

| 鍵名 | 預設值 | 描述 |
|-----|---------|-------------|
| `apiKey` | -- | 來自 [app.honcho.dev](https://app.honcho.dev) 的 API 金鑰 |
| `baseUrl` | -- | 自代管 Honcho 的基礎 URL |
| `peerName` | -- | 使用者同伴身份 |
| `aiPeer` | host key | AI 同伴身份（每個設定檔一個） |
| `workspace` | host key | 共享工作區 ID |
| `recallMode` | `hybrid` | `hybrid`（自動注入 + 工具）、`context`（僅注入）、`tools`（僅工具） |
| `observation` | 全部開啟 | 每個同伴的 `observeMe`/`observeOthers` 布林值 |
| `writeFrequency` | `async` | `async`、`turn`、`session` 或整數 N |
| `sessionStrategy` | `per-directory` | `per-directory`、`per-repo`、`per-session`、`global` |
| `dialecticReasoningLevel` | `low` | `minimal`、`low`、`medium`、`high`、`max` |
| `dialecticDynamic` | `true` | 根據查詢長度自動提升推理等級 |
| `messageMaxChars` | `25000` | 每條訊息的最大字元數（超過則分塊） |

</details>

<details>
<summary>最小化 honcho.json (雲端)</summary>

```json
{
  "apiKey": "您的 API 金鑰",
  "hosts": {
    "hermes": {
      "enabled": true,
      "aiPeer": "hermes",
      "peerName": "您的名字",
      "workspace": "hermes"
    }
  }
}
```

</details>

<details>
<summary>最小化 honcho.json (自代管)</summary>

```json
{
  "baseUrl": "http://localhost:8000",
  "hosts": {
    "hermes": {
      "enabled": true,
      "aiPeer": "hermes",
      "peerName": "您的名字",
      "workspace": "hermes"
    }
  }
}
```

</details>

:::tip 從 `hermes honcho` 遷移
如果您以前使用過 `hermes honcho setup`，您的配置和所有伺服器端數據都完好無損。只需再次透過設置嚮導啟用，或手動設置 `memory.provider: honcho` 即可透過新系統重新啟用。
:::

**多代理 / 設定檔 (Profiles)：**

每個 Hermes 設定檔都會獲得自己的 Honcho AI 同伴，同時共享同一個工作區 — 所有設定檔都看到同一個使用者表示，但每個代理都會建立自己的身份和觀察。

```bash
hermes profile create coder --clone   # 創建名為 "coder" 的 honcho 同伴，繼承預設配置
```

`--clone` 的作用：在 `honcho.json` 中創建一個 `hermes.coder` 主機區塊，並設置 `aiPeer: "coder"`，共享 `workspace`，繼承 `peerName`、`recallMode`、`writeFrequency`、`observation` 等。該同伴會在 Honcho 中預先創建，以便在第一條訊息之前就存在。

對於在設置 Honcho 之前創建的設定檔：

```bash
hermes honcho sync   # 掃描所有設定檔，為缺失的設定檔創建主機區塊
```

這將繼承預設 `hermes` 主機區塊的設置，並為每個設定檔創建新的 AI 同伴。此操作是冪等的 — 會跳過已有主機區塊的設定檔。

---

### OpenViking

由火山引擎（字節跳動）提供的上下文數據庫，具備檔案系統風格的知識層級、分層檢索以及自動將記憶提取到 6 個類別中。

| | |
|---|---|
| **最適合** | 具備結構化瀏覽功能的自代管知識管理 |
| **需要** | `pip install openviking` + 執行中的伺服器 |
| **數據儲存** | 自代管（本地或雲端） |
| **成本** | 免費（開源，AGPL-3.0） |

**工具：** `viking_search`（語義搜尋）、`viking_read`（分層：摘要/概覽/全文）、`viking_browse`（檔案系統導覽）、`viking_remember`（儲存事實）、`viking_add_resource`（攝取 URL/文件）

**設置：**
```bash
# 先啟動 OpenViking 伺服器
pip install openviking
openviking-server

# 然後配置 Hermes
hermes memory setup    # 選擇 "openviking"
# 或手動配置：
hermes config set memory.provider openviking
echo "OPENVIKING_ENDPOINT=http://localhost:1933" >> ~/.hermes/.env
```

**關鍵功能：**
- 分層上下文載入：L0（約 100 個權杖）→ L1（約 2k）→ L2（全文）
- 工作階段提交時自動提取記憶（設定檔、偏好、實體、事件、案例、模式）
- 用於層級知識瀏覽的 `viking://` URI 方案

---

### Mem0

具備語義搜尋、重新排序和自動去重的伺服器端 LLM 事實提取。

| | |
|---|---|
| **最適合** | 無需動手的記憶管理 — Mem0 會自動處理提取 |
| **需要** | `pip install mem0ai` + API 金鑰 |
| **數據儲存** | Mem0 雲端 |
| **成本** | Mem0 定價 |

**工具：** `mem0_profile`（所有儲存的記憶）、`mem0_search`（語義搜尋 + 重新排序）、`mem0_conclude`（逐字儲存事實）

**設置：**
```bash
hermes memory setup    # 選擇 "mem0"
# 或手動配置：
hermes config set memory.provider mem0
echo "MEM0_API_KEY=您的金鑰" >> ~/.hermes/.env
```

---

### Hindsight

具備知識圖譜、實體解析和多策略檢索的長期記憶。`hindsight_reflect` 工具提供了其他提供者無法提供的跨記憶合成功能。自動保留完整的對話回合（包括工具呼叫），並具備工作階段級別的文件追蹤。

| | |
|---|---|
| **最適合** | 基於知識圖譜且具備實體關係的回憶 |
| **需要** | 雲端：來自 [ui.hindsight.vectorize.io](https://ui.hindsight.vectorize.io) 的 API 金鑰。本地：LLM API 金鑰 |
| **數據儲存** | Hindsight 雲端或本地嵌入式 PostgreSQL |
| **成本** | Hindsight 定價（雲端）或免費（本地） |

**工具：** `hindsight_retain`（包含實體提取的儲存）、`hindsight_recall`（多策略搜尋）、`hindsight_reflect`（跨記憶合成）

**設置：**
```bash
hermes memory setup    # 選擇 "hindsight"
# 或手動配置：
hermes config set memory.provider hindsight
echo "HINDSIGHT_API_KEY=您的金鑰" >> ~/.hermes/.env
```

設置嚮導會自動安裝依賴項。本地模式 UI：`hindsight-embed -p hermes ui start`。

---

### Holographic

具備 FTS5 全文搜尋、信任評分和用於組合代數查詢的 HRR（全息簡約表示法，Holographic Reduced Representations）的本地 SQLite 事實儲存庫。

| | |
|---|---|
| **最適合** | 具備進階檢索功能的純本地記憶，無外部依賴 |
| **需要** | 無（SQLite 始終可用）。NumPy 針對 HRR 代數是選用的。 |
| **數據儲存** | 本地 SQLite |
| **成本** | 免費 |

**工具：** `fact_store`（9 個操作：新增、搜尋、探測、相關、推理、矛盾、更新、移除、列出）、`fact_feedback`（訓練信任評分的有用/無用評級）

**設置：**
```bash
hermes memory setup    # 選擇 "holographic"
# 或手動配置：
hermes config set memory.provider holographic
```

**獨特能力：**
- `probe` — 特定實體的代數回憶（關於某人/某事的所有事實）
- `reason` — 跨多個實體的組合 AND 查詢
- `contradict` — 自動檢測衝突事實
- 具備非對稱回饋的信任評分（+0.05 有用 / -0.10 無用）

---

### RetainDB

具備混合搜尋（向量 + BM25 + 重新排序）、7 種記憶類型和增量壓縮的雲端記憶 API。

| | |
|---|---|
| **最適合** | 已在使用 RetainDB 基礎設施的團隊 |
| **需要** | RetainDB 帳戶 + API 金鑰 |
| **數據儲存** | RetainDB 雲端 |
| **成本** | 每月 $20 美元 |

**工具：** `retaindb_profile`（使用者設定檔）、`retaindb_search`（語義搜尋）、`retaindb_context`（任務相關上下文）、`retaindb_remember`（按類型 + 重要性儲存）、`retaindb_forget`（刪除記憶）

---

### ByteRover

透過 `brv` CLI 實現的持久化記憶 — 具備分層檢索（模糊文字 → LLM 驅動搜尋）的層級知識樹。本地優先，可選雲端同步。

| | |
|---|---|
| **最適合** | 想要具備 CLI 的可移植、本地優先記憶的開發者 |
| **需要** | ByteRover CLI (`npm install -g byterover-cli`) |
| **數據儲存** | 本地（預設）或 ByteRover 雲端（選用同步） |
| **成本** | 免費（本地）或 ByteRover 定價（雲端） |

**工具：** `brv_query`（搜尋知識樹）、`brv_curate`（儲存事實/決定/模式）、`brv_status`（CLI 版本 + 樹狀統計）

**關鍵功能：**
- 自動預壓縮提取（在上下文壓縮捨棄見解之前將其儲存）
- 儲存在 `$HERMES_HOME/byterover/` 的知識樹（設定檔作用域）
- SOC2 Type II 認證的雲端同步（選用）

---

### Supermemory

具備設定檔回憶、語義搜尋、明確記憶工具以及透過 Supermemory 圖形 API 在工作階段結束時攝取對話的語義長期記憶。

| | |
|---|---|
| **最適合** | 具備使用者建模和工作階段級別圖形建立功能的語義回憶 |
| **需要** | `pip install supermemory` + [API 金鑰](https://supermemory.ai) |
| **數據儲存** | Supermemory 雲端 |
| **成本** | Supermemory 定價 |

**工具：** `supermemory_store`（儲存明確記憶）、`supermemory_search`（語義相似度搜尋）、`supermemory_forget`（按 ID 或最佳匹配查詢刪除）、`supermemory_profile`（持久化設定檔 + 近期上下文）

**設置：**
```bash
hermes memory setup    # 選擇 "supermemory"
# 或手動配置：
hermes config set memory.provider supermemory
echo 'SUPERMEMORY_API_KEY=***' >> ~/.hermes/.env
```

**關鍵功能：**
- 自動上下文圍欄 (Context fencing) — 從擷取的輪次中去除回憶起的記憶，以防止遞迴記憶污染
- 工作階段結束時的對話攝取，用於建立更豐富的圖形級別知識
- 在第一回合和可配置的間隔注入設定檔事實
- 瑣碎訊息過濾（跳過 "ok"、"thanks" 等）
- **設定檔作用域的容器** — 在 `container_tag` 中使用 `{identity}`（例如 `hermes-{identity}` → `hermes-coder`）以隔離每個 Hermes 設定檔的記憶
- **多容器模式** — 讓代理在多個具名容器中讀寫

---

## 提供者比較

| 提供者 | 儲存方式 | 成本 | 工具數 | 依賴項 | 獨特功能 |
|----------|---------|------|-------|-------------|----------------|
| **Honcho** | 雲端 | 付費 | 4 | `honcho-ai` | 辯證式使用者建模 |
| **OpenViking** | 自代管 | 免費 | 5 | `openviking` + 伺服器 | 檔案系統層級 + 分層載入 |
| **Mem0** | 雲端 | 付費 | 3 | `mem0ai` | 伺服器端 LLM 提取 |
| **Hindsight** | 雲端/本地 | 免費/付費 | 3 | `hindsight-client` | 知識圖譜 + 反思合成 |
| **Holographic** | 本地 | 免費 | 2 | 無 | HRR 代數 + 信任評分 |
| **RetainDB** | 雲端 | $20/月 | 5 | `requests` | 增量壓縮 |
| **ByteRover** | 本地/雲端 | 免費/付費 | 3 | `brv` CLI | 預壓縮提取 |
| **Supermemory** | 雲端 | 付費 | 4 | `supermemory` | 上下文圍欄 + 工作階段圖形攝取 |

## 設定檔隔離

每個提供者的數據都按[設定檔 (profile)](/docs/user-guide/profiles) 隔離：

- **本地儲存提供者** (Holographic, ByteRover) 使用隨設定檔而異的 `$HERMES_HOME/` 路徑
- **配置檔案提供者** (Honcho, Mem0, Hindsight, Supermemory) 將配置儲存在 `$HERMES_HOME/` 中，因此每個設定檔都有自己的憑證
- **雲端提供者** (RetainDB) 會自動衍生設定檔作用域的專案名稱
- **環境變數提供者** (OpenViking) 透過每個設定檔的 `.env` 檔案進行配置

## 開發記憶提供者

有關如何創建自己的記憶提供者，請參閱[開發者指南：記憶提供者外掛程式](/docs/developer-guide/memory-provider-plugin)。
