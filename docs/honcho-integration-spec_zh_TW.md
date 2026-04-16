# Honcho 整合規格書 (honcho-integration-spec)

Hermes Agent 與 openclaw-honcho 的比較 —— 以及將 Hermes 模式引入其他 Honcho 整合的移植規格。

---

## 概述 (Overview)

針對兩種不同的代理人執行環境，已建構了兩個獨立的 Honcho 整合：**Hermes Agent**（Python，內建於執行器中）和 **openclaw-honcho**（TypeScript 外掛，透過鉤子/工具 API 實作）。兩者都使用相同的 Honcho 同儕範式（Dual Peer 模型、`session.context()`、`peer.chat()`），但它們在每個層次上都做出了不同的權衡。

本文檔對應了這些權衡，並定義了一個移植規格：一組源自 Hermes 的模式，每個模式都以與整合無關的介面呈現，任何 Honcho 整合不論執行環境或語言為何，都可以採用這些模式。

> **範圍** 這兩個整合目前都能正確運作。本規格旨在探討差異點 —— Hermes 中值得推廣的模式，以及 Hermes 最終應採用的 openclaw-honcho 模式。本規格是增補性的，而非強制性的。

---

## 架構比較 (Architecture comparison)

### Hermes：內建執行器 (Baked-in runner)

Honcho 直接在 `AIAgent.__init__` 內部進行初始化。沒有外掛邊界。工作階段 (Session) 管理、上下文 (Context) 注入、非同步預取 (Async prefetch) 和 CLI 介面都是執行器的首要關注點。上下文在每個工作階段中僅注入一次（固定在 `_cached_system_prompt` 中），且絕不在工作階段中重新獲取 —— 這最大化了 LLM 提供者的前綴快取命中率 (Prefix cache hits)。

回合流程 (Turn flow)：

```
使用者訊息
  → _honcho_prefetch()       (讀取快取 — 無 HTTP)
  → _build_system_prompt()   (僅限第一回合，已快取)
  → LLM 呼叫
  → 回應
  → _honcho_fire_prefetch()  (守護執行緒，回合結束時)
       → prefetch_context() 執行緒  ──┐
       → prefetch_dialectic() 執行緒 ─┴→ _context_cache / _dialectic_cache
```

### openclaw-honcho：基於鉤子的外掛 (Hook-based plugin)

該外掛針對 OpenClaw 的事件匯流排註冊鉤子。在每一回合的 `before_prompt_build` 期間，同步獲取上下文。訊息擷取發生在 `agent_end`。透過 `subagent_spawned` 追蹤多代理人階層。此模型是正確的，但每一回合在 LLM 呼叫開始前，都必須支付一次阻塞式的 Honcho HTTP 往返延遲。

回合流程 (Turn flow)：

```
使用者訊息
  → before_prompt_build (阻塞式 HTTP — 每一回合)
       → session.context()
  → 系統提示詞組裝
  → LLM 呼叫
  → 回應
  → agent_end 鉤子
       → session.addMessages()
       → session.setMetadata()
```

---

## 差異對照表 (Diff table)

| 維度 | Hermes Agent | openclaw-honcho |
|---|---|---|
| **上下文注入時機** | 每個工作階段一次（快取）。第一回合後無 HTTP 往返。 | 每一回合，阻塞式。每回合獲取最新內容但增加延遲。 |
| **預取策略** | 守護執行緒在回合結束時觸發；下一回合從快取中讀取。 | 無。在提示詞建構時進行阻塞式呼叫。 |
| **辯證 (peer.chat)** | 非同步預取；結果在下一回合注入系統提示詞。 | 透過 `honcho_recall` / `honcho_analyze` 工具隨選使用。 |
| **推理等級** | 動態：隨訊息長度擴展。下限 = 設定預設值。上限 = "high"。 | 每個工具固定：recall=minimal, analyze=medium。 |
| **記憶模式** | `user_memory_mode` / `agent_memory_mode`：hybrid / honcho / local。 | 無。一律寫入 Honcho。 |
| **寫入頻率** | 非同步（背景佇列）、每回合、每工作階段、每 N 回合。 | 每個 agent_end 之後（無法控制）。 |
| **AI 同儕身分** | `observe_me=True`、`seed_ai_identity()`、`get_ai_representation()`、SOUL.md → AI 同儕。 | 設定時將代理人檔案上傳至代理人同儕。無持續的自我觀察。 |
| **上下文範圍** | 注入使用者同儕 + AI 同儕表徵。 | 注入使用者同儕（擁有者）表徵 + 對話摘要。上下文呼叫使用 `peerPerspective`。 |
| **工作階段命名** | 按目錄 / 全域 / 手動對應 / 基於標題。 | 源自平台工作階段金鑰。 |
| **多代理人** | 僅支援單一代理人。 | 透過 `subagent_spawned` 追蹤父級觀察者階層。 |
| **工具介面** | 單一 `query_user_context` 工具（隨選辯證）。 | 6 個工具：session, profile, search, context (快速) + recall, analyze (LLM)。 |
| **平台中繼資料** | 不移除。 | 在 Honcho 儲存前明確移除。 |
| **訊息去重** | 無。 | 工作階段中繼資料中的 `lastSavedIndex` 防止重複傳送。 |
| **提示詞中的 CLI 介面** | 管理指令注入系統提示詞。代理人知道自己的 CLI。 | 未注入。 |
| **身分中的 AI 同儕名稱** | 設定後替換 DEFAULT_AGENT_IDENTITY 中的 "Hermes Agent"。 | 未實作。 |
| **QMD / 本地檔案搜尋** | 未實作。 | 當設定 QMD 後端時使用透傳工具。 |
| **工作區中繼資料** | 未實作。 | 工作區中繼資料中的 `agentPeerMap` 追蹤 代理人→同儕 ID。 |

---

## 模式 (Patterns)

Hermes 中的六個模式值得在任何 Honcho 整合中採用。每個模式都描述為與整合無關的介面。

**Hermes 貢獻：**
- 非同步預取（零延遲）
- 動態推理等級
- 每同儕記憶模式
- AI 同儕身分形成
- 工作階段命名策略
- CLI 介面注入

**openclaw-honcho 回饋（Hermes 應採用）：**
- `lastSavedIndex` 去重
- 平台中繼資料移除
- 多代理人觀察者階層
- `context()` 呼叫的 `peerPerspective`
- 分層工具介面（快速/LLM）
- 工作區 `agentPeerMap`

---

## 規格：非同步預取 (Async prefetch)

### 問題

在每次 LLM 呼叫前同步呼叫 `session.context()` 和 `peer.chat()` 會在每一回合增加 200–800 毫秒的 Honcho HTTP 往返延遲。

### 模式

在每回合**結束**時，以非阻塞背景任務觸發這兩個呼叫。將結果儲存在以工作階段 ID 為鍵的每工作階段快取中。在下一回合**開始**時，從快取中取出結果 —— 此時 HTTP 請求早已完成。第一回合是冷啟動（快取為空）；後續所有回合在回應路徑上都是零延遲。

### 介面合約

```typescript
interface AsyncPrefetch {
  // 在回合結束時觸發上下文 + 辯證獲取。非阻塞。
  firePrefetch(sessionId: string, userMessage: string): void;

  // 在回合開始時取出快取結果。如果快取為空則回傳空值。
  popContextResult(sessionId: string): ContextResult | null;
  popDialecticResult(sessionId: string): string | null;
}

type ContextResult = {
  representation: string;
  card: string[];
  aiRepresentation?: string;  // 如果啟用，則包含 AI 同儕上下文
  summary?: string;           // 如果獲取，則包含對話摘要
};
```

### 實作說明

- **Python：** `threading.Thread(daemon=True)`。寫入 `dict[session_id, result]` —— GIL 使得簡單的寫入操作是安全的。
- **TypeScript：** 儲存在 `Map<string, Promise<ContextResult>>` 中的 `Promise`。在取出時執行 `await`。如果尚未解析完成，則回傳 null —— 不要阻塞。
- 取出操作是破壞性的：讀取後清除快取項目，以確保舊資料永不累積。
- 預取也應在第一回合觸發（即使直到第二回合才會被取用）。

### openclaw-honcho 採用

將 `session.context()` 從 `before_prompt_build` 移至 `agent_end` 後的背景任務。將結果儲存在 `state.contextCache` 中。在 `before_prompt_build` 中，從快取讀取而非呼叫 Honcho。如果快取為空（第一回合），則不注入任何內容 —— 系統提示詞在第一回合沒有 Honcho 上下文的情況下依然有效。

---

## 規格：動態推理等級 (Dynamic reasoning level)

### 問題

Honcho 的辯證端點支援從 `minimal` 到 `max` 的推理等級。針對每個工具使用固定等級，在處理簡單查詢時會浪費預算，而處理複雜查詢時則服務不足。

### 模式

根據使用者的訊息動態選擇推理等級。使用設定的預設值作為下限。根據訊息長度提升等級。自動選擇上限為 `high` —— 絕不自動選擇 `max`。

### 邏輯

```
< 120 字元   → 預設值 (通常為 "low")
120–400 字元 → 預設值上一級 (上限為 "high")
> 400 字元   → 預設值上兩級 (上限為 "high")
```

### 設定鍵

新增 `dialecticReasoningLevel` (字串, 預設為 `"low"`)。這設定了下限。動態提升一律在此基礎上套用。

### openclaw-honcho 採用

套用於 `honcho_recall` 和 `honcho_analyze`：將固定的 `reasoningLevel` 替換為動態選擇器。`honcho_recall` 使用下限 `"minimal"`，`honcho_analyze` 使用下限 `"medium"` —— 兩者仍會隨訊息長度提升。

---

## 規格：每同儕記憶模式 (Per-peer memory modes)

### 問題

使用者希望獨立控制使用者上下文和代理人上下文是寫入本地、Honcho 還是兩者兼具。

### 模式

| 模式 | 效果 |
|---|---|
| `hybrid` | 同時寫入本地檔案和 Honcho (預設) |
| `honcho` | 僅寫入 Honcho —— 停用對應的本地檔案寫入 |
| `local` | 僅寫入本地檔案 —— 對此同儕跳過 Honcho 同步 |

### 設定綱要 (Config schema)

```json
{
  "memoryMode": "hybrid",
  "userMemoryMode": "honcho",
  "agentMemoryMode": "hybrid"
}
```

解析順序：每同儕欄位優先 → 簡寫 `memoryMode` → 預設 `"hybrid"`。

### 對 Honcho 同步的影響

- `userMemoryMode=local`：跳過將使用者同儕訊息新增至 Honcho
- `agentMemoryMode=local`：跳過將助理同儕訊息新增至 Honcho
- 兩者皆為 local：完全跳過 `session.addMessages()`
- `userMemoryMode=honcho`：停用本地 USER.md 寫入
- `agentMemoryMode=honcho`：停用本地 MEMORY.md / SOUL.md 寫入

---

## 規格：AI 同儕身分形成 (AI peer identity formation)

### 問題

Honcho 藉由觀察使用者的言論有機地建構使用者的表徵。相同的機制也存在於 AI 同儕 —— 但前提是代理人同儕設定了 `observe_me=True`。若無此設定，代理人同儕將不會累積任何內容。

此外，現有的身分檔案（SOUL.md, IDENTITY.md）應在首次啟動時播種 (seed) AI 同儕的 Honcho 表徵。

### A 部分：代理人同儕設定 observe_me=True

```typescript
await session.addPeers([
  [ownerPeer.id, { observeMe: true,  observeOthers: false }],
  [agentPeer.id, { observeMe: true,  observeOthers: true  }], // 原本為 false
]);
```

單行變更。這是基礎。若無此設定，無論代理人說了什麼，AI 同儕的表徵都會保持空白。

### B 部分：seedAiIdentity()

```typescript
async function seedAiIdentity(
  agentPeer: Peer,
  content: string,
  source: string
): Promise<boolean> {
  const wrapped = [
    `<ai_identity_seed>`,
    `<source>${source}</source>`,
    ``,
    content.trim(),
    `</ai_identity_seed>`,
  ].join("\n");

  await agentPeer.addMessage("assistant", wrapped);
  return true;
}
```

### C 部分：在設定時遷移代理人檔案

在 `honcho setup` 期間，透過 `seedAiIdentity()` 而非 `session.uploadFile()` 將代理人的自我檔案（SOUL.md, IDENTITY.md, AGENTS.md）上傳至代理人同儕。這會讓內容經過 Honcho 的觀察管道。

### D 部分：身分中的 AI 同儕名稱

當代理人有設定名稱時，將其加在注入的系統提示詞最前面：

```typescript
const namePrefix = agentName ? `You are ${agentName}.\n\n` : "";
return { systemPrompt: namePrefix + "## User Memory Context\n\n" + sections };
```

### CLI 介面

```
honcho identity <檔案>    # 從檔案播種
honcho identity --show    # 顯示目前 AI 同儕的表徵
```

---

## 規格：工作階段命名策略 (Session naming strategies)

### 問題

單一全域工作階段意味著每個專案都共享相同的 Honcho 上下文。按目錄劃分的工作階段提供隔離，且不需要使用者手動命名工作階段。

### 策略

| 策略 | 工作階段金鑰 | 何時使用 |
|---|---|---|
| `per-directory` | 目前工作目錄 (CWD) 的名稱 | 預設值。每個專案獲得自己的工作階段。 |
| `global` | 固定字串 `"global"` | 單一跨專案工作階段。 |
| 手動對應 | 使用者按路徑設定 | `sessions` 設定對應會覆蓋目錄名稱。 |
| 基於標題 | 淨化後的工作階段標題 | 當代理人支援在對話中設定具名工作階段時使用。 |

### 設定綱要 (Config schema)

```json
{
  "sessionStrategy": "per-directory",
  "sessionPeerPrefix": false,
  "sessions": {
    "/home/user/projects/foo": "foo-project"
  }
}
```

### CLI 介面

```
honcho sessions              # 列出所有對應
honcho map <名稱>            # 將 cwd 對應至工作階段名稱
honcho map                   # 無引數 = 列出對應
```

解析順序：手動對應 → 工作階段標題 → 目錄名稱 → 平台金鑰。

---

## 規格：CLI 介面注入 (CLI surface injection)

### 問題

當使用者詢問「如何變更我的記憶設定？」時，代理人要麼產生幻覺，要麼說它不知道。代理人應該了解自己的管理介面。

### 模式

當 Honcho 啟用時，在系統提示詞後附加精簡的指令參考。保持在 300 字元以內。

```
# Honcho 記憶整合
已啟用。工作階段：{sessionKey}。模式：{mode}。
管理指令：
  honcho status                    — 顯示設定與連線狀態
  honcho mode [hybrid|honcho|local] — 顯示或設定記憶模式
  honcho sessions                  — 列出工作階段對應
  honcho map <名稱>                — 將目錄對應至工作階段
  honcho identity [檔案] [--show]  — 播種或顯示 AI 身分
  honcho setup                     — 完整互動式設定精靈
```

---

## openclaw-honcho 檢查清單

按影響力排序：

- [ ] **非同步預取** — 將 `session.context()` 移出 `before_prompt_build` 並進入 `agent_end` 後的背景 Promise
- [ ] **代理人同儕 observe_me=True** — 在 `session.addPeers()` 中修改一行
- [ ] **動態推理等級** — 新增協助程式；套用於 `honcho_recall` 和 `honcho_analyze`；在設定中新增 `dialecticReasoningLevel`
- [ ] **每同儕記憶模式** — 在設定中新增 `userMemoryMode` / `agentMemoryMode`；控管 Honcho 同步與本地寫入
- [ ] **seedAiIdentity()** — 新增協助程式；在設定遷移 SOUL.md / IDENTITY.md 時使用
- [ ] **工作階段命名策略** — 新增 `sessionStrategy`, `sessions` 對應, `sessionPeerPrefix`
- [ ] **CLI 介面注入** — 將指令參考附加至 `before_prompt_build` 的回傳值
- [ ] **honcho identity 子指令** — 從檔案播種或顯示目前的表徵 (`--show`)
- [ ] **AI 同儕名稱注入** — 若已設定 `aiPeer` 名稱，將其加在注入的系統提示詞最前面
- [ ] **honcho mode / sessions / map** — 達成與 Hermes 一致的 CLI 功能

openclaw-honcho 已完成部分 (無需重複實作)：`lastSavedIndex` 去重、平台中繼資料移除、多代理人父級觀察者、`context()` 的 `peerPerspective`、分層工具介面、工作區 `agentPeerMap`、QMD 透傳、自行託管的 Honcho。

---

## nanobot-honcho 檢查清單

全新 (Greenfield) 整合。從 openclaw-honcho 的架構開始，並從第一天起套用所有 Hermes 模式。

### 第一階段 — 核心正確性

- [ ] 雙同儕模型 (擁有者 + 代理人同儕)，兩者皆設定 `observe_me=True`
- [ ] 回合結束時擷取訊息，並使用 `lastSavedIndex` 去重
- [ ] 在 Honcho 儲存前移除平台中繼資料
- [ ] 從第一天起實作非同步預取 — 不要實作阻塞式的上下文注入
- [ ] 首次啟動時進行舊版檔案遷移 (USER.md → 擁有者同儕, SOUL.md → `seedAiIdentity()`)

### 第二階段 — 設定

- [ ] 設定綱要：`apiKey`, `workspaceId`, `baseUrl`, `memoryMode`, `userMemoryMode`, `agentMemoryMode`, `dialecticReasoningLevel`, `sessionStrategy`, `sessions`
- [ ] 每同儕記憶模式控管
- [ ] 動態推理等級
- [ ] 工作階段命名策略

### 第三階段 — 工具與 CLI

- [ ] 工具介面：`honcho_profile`, `honcho_recall`, `honcho_analyze`, `honcho_search`, `honcho_context`
- [ ] CLI：`setup`, `status`, `sessions`, `map`, `mode`, `identity`
- [ ] 在系統提示詞中注入 CLI 介面
- [ ] 將 AI 同儕名稱連結至代理人身分
