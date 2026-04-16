---
sidebar_position: 14
title: "API 伺服器"
description: "將 hermes-agent 作為相容於 OpenAI 的 API 提供給任何前端使用"
---

# API 伺服器

API 伺服器將 hermes-agent 作為相容於 OpenAI 的 HTTP 端點。任何支援 OpenAI 格式的前端 —— 如 Open WebUI、LobeChat、LibreChat、NextChat、ChatBox 等數百種工具 —— 都可以連接到 hermes-agent 並將其作為後端使用。

您的代理程式將使用其完整工具集（終端機、檔案操作、網頁搜尋、記憶、技能）來處理請求並返回最終回應。串流時，工具進度指示器會顯示在行內，讓前端可以展示代理程式正在做什麼。

## 快速入門

### 1. 啟用 API 伺服器

在 `~/.hermes/.env` 中加入：

```bash
API_SERVER_ENABLED=true
API_SERVER_KEY=change-me-local-dev
# 選填：僅當瀏覽器必須直接呼叫 Hermes 時才需要
# API_SERVER_CORS_ORIGINS=http://localhost:3000
```

### 2. 啟動閘道器 (Gateway)

```bash
hermes gateway
```

您將會看到：

```
[API Server] API server listening on http://127.0.0.1:8642
```

### 3. 連接前端

將任何相容於 OpenAI 的用戶端指向 `http://localhost:8642/v1`：

```bash
# 使用 curl 測試
curl http://localhost:8642/v1/chat/completions \
  -H "Authorization: Bearer change-me-local-dev" \
  -H "Content-Type: application/json" \
  -d '{"model": "hermes-agent", "messages": [{"role": "user", "content": "你好！"}]}'
```

或者連接 Open WebUI、LobeChat 或任何其他前端 —— 請參閱 [Open WebUI 整合指南](/docs/user-guide/messaging/open-webui) 以取得逐步說明。

## 端點 (Endpoints)

### POST /v1/chat/completions

標準 OpenAI Chat Completions 格式。無狀態 —— 每次請求都透過 `messages` 陣列包含完整的對話內容。

**請求：**
```json
{
  "model": "hermes-agent",
  "messages": [
    {"role": "system", "content": "你是一位 Python 專家。"},
    {"role": "user", "content": "寫一個費波那契 (fibonacci) 函數"}
  ],
  "stream": false
}
```

**回應：**
```json
{
  "id": "chatcmpl-abc123",
  "object": "chat.completion",
  "created": 1710000000,
  "model": "hermes-agent",
  "choices": [{
    "index": 0,
    "message": {"role": "assistant", "content": "這是一個費波那契函數..."},
    "finish_reason": "stop"
  }],
  "usage": {"prompt_tokens": 50, "completion_tokens": 200, "total_tokens": 250}
}
```

**串流模式** (`"stream": true`): 返回帶有逐字回應區塊的伺服器傳送事件 (SSE)。對於 **Chat Completions**，串流使用標準的 `chat.completion.chunk` 事件，外加 Hermes 自訂的 `hermes.tool.progress` 事件用於工具啟動的 UX。對於 **Responses**，串流使用 OpenAI Responses 事件類型，例如 `response.created`、`response.output_text.delta`、`response.output_item.added`、`response.output_item.done` 和 `response.completed`。

**串流中的工具進度**：
- **Chat Completions**：Hermes 發送 `event: hermes.tool.progress` 以展示工具啟動的可視性，且不會污染持久化的助理文字。
- **Responses**：Hermes 在 SSE 串流期間發送規範原生的 `function_call` 和 `function_call_output` 輸出項，以便用戶端即時渲染結構化的工具 UI。

### POST /v1/responses

OpenAI Responses API 格式。支援透過 `previous_response_id` 實現伺服器端對話狀態 —— 伺服器存儲完整的對話歷史（包括工具呼叫和結果），因此可以在用戶端不管理上下文的情況下保留多輪對話內容。

**請求：**
```json
{
  "model": "hermes-agent",
  "input": "我的專案中有哪些檔案？",
  "instructions": "你是一位很有幫助的程式碼助理。",
  "store": true
}
```

**回應：**
```json
{
  "id": "resp_abc123",
  "object": "response",
  "status": "completed",
  "model": "hermes-agent",
  "output": [
    {"type": "function_call", "name": "terminal", "arguments": "{\"command\": \"ls\"}", "call_id": "call_1"},
    {"type": "function_call_output", "call_id": "call_1", "output": "README.md src/ tests/"},
    {"type": "message", "role": "assistant", "content": [{"type": "output_text", "text": "您的專案有..."}]}
  ],
  "usage": {"input_tokens": 50, "output_tokens": 200, "total_tokens": 250}
}
```

#### 使用 previous_response_id 進行多輪對話

鏈接回應以在輪次之間保留完整的上下文（包括工具呼叫）：

```json
{
  "input": "現在讓我看看 README",
  "previous_response_id": "resp_abc123"
}
```

伺服器會從存儲的回應鏈中重建完整對話 —— 所有之前的工具呼叫和結果都會被保留。鏈接的請求也會共享同一個工作階段，因此多輪對話在儀表板和工作階段歷史中會顯示為單一條目。

#### 具名對話 (Named conversations)

使用 `conversation` 參數而不是追蹤回應 ID：

```json
{"input": "哈囉", "conversation": "my-project"}
{"input": "src/ 目錄下有什麼？", "conversation": "my-project"}
{"input": "執行測試", "conversation": "my-project"}
```

伺服器會自動鏈接到該對話中的最新回應。這與閘道器工作階段的 `/title` 指令類似。

### GET /v1/responses/\{id\}

透過 ID 檢索先前存儲的回應。

### DELETE /v1/responses/\{id\}

刪除存儲的回應。

### GET /v1/models

將代理程式列為可用模型。廣告的模型名稱預設為 [設定檔 (Profile)](/docs/user-guide/features/profiles) 名稱（預設設定檔為 `hermes-agent`）。大多數前端進行模型發現時都需要此功能。

### GET /health

健康檢查。返回 `{"status": "ok"}`。對於期望 `/v1/` 前綴的相容於 OpenAI 的用戶端，也可以透過 **GET /v1/health** 存取。

## 系統提示詞處理

當前端發送 `system` 訊息 (Chat Completions) 或 `instructions` 欄位 (Responses API) 時，hermes-agent 會將其 **疊加** 在其核心系統提示詞之上。您的代理程式會保留其所有工具、記憶和技能 —— 前端的系統提示詞只是添加了額外的指示。

這意味著您可以針對不同的前端自訂行為，而不會失去原有的能力：
- Open WebUI 系統提示詞："你是一位 Python 專家。始終包含型別提示 (type hints)。"
- 代理程式仍然擁有終端機、檔案工具、網頁搜尋、記憶等功能。

## 驗證 (Authentication)

透過 `Authorization` 標頭進行 Bearer 權杖驗證：

```
Authorization: Bearer ***
```

透過 `API_SERVER_KEY` 環境變數配置金鑰。如果您需要瀏覽器直接呼叫 Hermes，還需將 `API_SERVER_CORS_ORIGINS` 設置為明確的允許清單。

:::warning 安全警告
API 伺服器提供了存取 hermes-agent 工具集的完整權限，**包括終端機指令**。當綁定到非迴環位址（如 `0.0.0.0`）時，**必須**設置 `API_SERVER_KEY`。此外，請保持 `API_SERVER_CORS_ORIGINS` 範圍狹窄，以控制瀏覽器的存取。

預設綁定位址 (`127.0.0.1`) 僅供本地端使用。瀏覽器存取預設為禁用；僅對明確信任的來源啟用它。
:::

## 配置

### 環境變數

| 變數 | 預設值 | 描述 |
|----------|---------|-------------|
| `API_SERVER_ENABLED` | `false` | 啟用 API 伺服器 |
| `API_SERVER_PORT` | `8642` | HTTP 伺服器連接埠 |
| `API_SERVER_HOST` | `127.0.0.1` | 綁定位址（預設僅 localhost） |
| `API_SERVER_KEY` | _(無)_ | 用於驗證的 Bearer 權杖 |
| `API_SERVER_CORS_ORIGINS` | _(無)_ | 以逗號分隔的允許瀏覽器來源 |
| `API_SERVER_MODEL_NAME` | _(設定檔名稱)_ | `/v1/models` 上的模型名稱。預設為設定檔名稱，預設設定檔為 `hermes-agent`。 |

### config.yaml

```yaml
# 目前尚不支援 —— 請使用環境變數。
# 將在未來版本中支援 config.yaml。
```

## 安全標頭 (Security Headers)

所有回應都包含安全標頭：
- `X-Content-Type-Options: nosniff` — 防止 MIME 類型探測 (sniffing)
- `Referrer-Policy: no-referrer` — 防止來源洩露

## CORS

API 伺服器預設 **不** 啟用瀏覽器 CORS。

如需瀏覽器直接存取，請設置明確的允許清單：

```bash
API_SERVER_CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

啟用 CORS 時：
- **預檢 (Preflight) 回應** 包含 `Access-Control-Max-Age: 600`（10 分鐘快取）
- **SSE 串流回應** 包含 CORS 標頭，以便瀏覽器 EventSource 用戶端正常運作
- **`Idempotency-Key`** 是一個允許的請求標頭 —— 用戶端可以發送它以進行去重（回應按金鑰快取 5 分鐘）

大多數記錄的前端（如 Open WebUI）是伺服器對伺服器連接，根本不需要 CORS。

## 相容的前端

任何支援 OpenAI API 格式的前端都可以運作。已測試/記錄的整合：

| 前端 | Stars | 連接方式 |
|----------|-------|------------|
| [Open WebUI](/docs/user-guide/messaging/open-webui) | 126k | 提供完整指南 |
| LobeChat | 73k | 自訂提供者端點 |
| LibreChat | 34k | librechat.yaml 中的自訂端點 |
| AnythingLLM | 56k | 通用 OpenAI 提供者 |
| NextChat | 87k | BASE_URL 環境變數 |
| ChatBox | 39k | API Host 設定 |
| Jan | 26k | 遠端模型配置 |
| HF Chat-UI | 8k | OPENAI_BASE_URL |
| big-AGI | 7k | 自訂端點 |
| OpenAI Python SDK | — | `OpenAI(base_url="http://localhost:8642/v1")` |
| curl | — | 直接 HTTP 請求 |

## 搭配設定檔的多使用者設定

要為多個使用者提供各自獨立的 Hermes 實例（獨立配置、記憶、技能），請使用 [設定檔 (Profiles)](/docs/user-guide/features/profiles)：

```bash
# 為每個使用者建立一個設定檔
hermes profile create alice
hermes profile create bob

# 配置每個設定檔的 API 伺服器在不同的連接埠上
hermes -p alice config set API_SERVER_ENABLED true
hermes -p alice config set API_SERVER_PORT 8643
hermes -p alice config set API_SERVER_KEY alice-secret

hermes -p bob config set API_SERVER_ENABLED true
hermes -p bob config set API_SERVER_PORT 8644
hermes -p bob config set API_SERVER_KEY bob-secret

# 啟動每個設定檔的閘道器
hermes -p alice gateway &
hermes -p bob gateway &
```

每個設定檔的 API 伺服器會自動將設定檔名稱作為模型 ID：

- `http://localhost:8643/v1/models` → 模型 `alice`
- `http://localhost:8644/v1/models` → 模型 `bob`

在 Open WebUI 中，將每個連接添加為單獨的連接。模型下拉選單將顯示 `alice` 和 `bob` 為不同的模型，每個模型背後都是一個完全隔離的 Hermes 實例。詳情請參閱 [Open WebUI 指南](/docs/user-guide/messaging/open-webui#multi-user-setup-with-profiles)。

## 限制

- **回應存儲** — 存儲的回應（用於 `previous_response_id`）持久化在 SQLite 中，在閘道器重啟後依然存在。最多存儲 100 個回應（採 LRU 汰換）。
- **無檔案上傳** — 目前 API 尚不支援透過上傳檔案進行視覺/文件分析。
- **模型欄位僅供參考** — 請求中的 `model` 欄位會被接收，但實際使用的 LLM 模型是在伺服器端的 config.yaml 中配置的。

## 代理模式 (Proxy Mode)

API 伺服器還作為 **閘道器代理模式** 的後端。當另一個 Hermes 閘道器實例配置了指向此 API 伺服器的 `GATEWAY_PROXY_URL` 時，它會將所有訊息轉發到此處，而不是執行自己的代理。這支持分離部署 —— 例如，一個處理 Matrix E2EE 的 Docker 容器轉發到主機端的代理程式。

請參閱 [Matrix 代理模式](/docs/user-guide/messaging/matrix#proxy-mode-e2ee-on-macos) 取得完整設定指南。
