---
sidebar_position: 4
title: "MCP (模型上下文協定)"
description: "透過 MCP 將 Hermes Agent 連接到外部工具伺服器 — 並精確控制 Hermes 載入哪些 MCP 工具"
---

# MCP (模型上下文協定 / Model Context Protocol)

MCP 讓 Hermes Agent 可以連接到外部工具伺服器，使代理程式能夠使用 Hermes 本身之外的工具 — 例如 GitHub、資料庫、檔案系統、瀏覽器堆疊、內部 API 等。

如果您曾經希望 Hermes 使用某個已經存在於別處的工具，MCP 通常是最乾淨的做法。

## MCP 帶給您的好處

- 無需編寫原生 Hermes 工具，即可存取外部工具生態系統。
- 在同一個配置中支援本地 stdio 伺服器和遠端 HTTP MCP 伺服器。
- 啟動時自動進行工具發現 (discovery) 與註冊。
- 在伺服器支援的情況下，提供 MCP 資源 (resources) 和提示詞 (prompts) 的輔助封裝。
- 支援個別伺服器過濾，您可以僅公開您真正希望 Hermes 看到的 MCP 工具。

## 快速入門

1. 安裝 MCP 支援（如果您使用的是標準安裝指令碼，則已經包含在內）：

```bash
cd ~/.hermes/hermes-agent
uv pip install -e ".[mcp]"
```

2. 在 `~/.hermes/config.yaml` 中新增一個 MCP 伺服器：

```yaml
mcp_servers:
  filesystem:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-filesystem", "/home/user/projects"]
```

3. 啟動 Hermes：

```bash
hermes chat
```

4. 要求 Hermes 使用 MCP 提供的功能。

例如：

```text
列出 /home/user/projects 中的檔案並摘要此儲存庫的結構。
```

Hermes 將會發現該 MCP 伺服器的工具，並像使用任何其他工具一樣使用它們。

## 兩種 MCP 伺服器

### Stdio 伺服器

Stdio 伺服器作為本地子程序執行，並透過 stdin/stdout 進行通訊。

```yaml
mcp_servers:
  github:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: "***"
```

在以下情況使用 stdio 伺服器：
- 伺服器安裝在本地。
- 您希望低延遲地存取本地資源。
- 您正在參考顯示 `command`、`args` 和 `env` 的 MCP 伺服器文件。

### HTTP 伺服器

HTTP MCP 伺服器是 Hermes 直接連接的遠端端點。

```yaml
mcp_servers:
  remote_api:
    url: "https://mcp.example.com/mcp"
    headers:
      Authorization: "Bearer ***"
```

在以下情況使用 HTTP 伺服器：
- MCP 伺服器代管在其他地方。
- 您的組織公開了內部的 MCP 端點。
- 您不希望 Hermes 為該整合啟動本地子程序。

## 基本配置參考

Hermes 從 `~/.hermes/config.yaml` 的 `mcp_servers` 區段讀取 MCP 配置。

### 常見金鑰 (Common keys)

| 金鑰 | 類型 | 意義 |
|---|---|---|
| `command` | 字串 | stdio MCP 伺服器的可執行檔 |
| `args` | 清單 | stdio 伺服器的參數 |
| `env` | 映射 (mapping) | 傳遞給 stdio 伺服器的環境變數 |
| `url` | 字串 | HTTP MCP 端點 |
| `headers` | 映射 (mapping) | 遠端伺服器的 HTTP 標頭 |
| `timeout` | 數字 | 工具調用超時時間 |
| `connect_timeout` | 數字 | 初始連線超時時間 |
| `enabled` | 布林值 | 如果為 `false`，Hermes 會完全跳過該伺服器 |
| `tools` | 映射 (mapping) | 個別伺服器的工具過濾與輔助工具策略 |

### 最小 stdio 範例

```yaml
mcp_servers:
  filesystem:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"]
```

### 最小 HTTP 範例

```yaml
mcp_servers:
  company_api:
    url: "https://mcp.internal.example.com"
    headers:
      Authorization: "Bearer ***"
```

## Hermes 如何註冊 MCP 工具

Hermes 會為 MCP 工具添加前綴，以免與內建名稱衝突：

```text
mcp_<伺服器名稱>_<工具名稱>
```

範例：

| 伺服器 | MCP 工具 | 註冊名稱 |
|---|---|---|
| `filesystem` | `read_file` | `mcp_filesystem_read_file` |
| `github` | `create-issue` | `mcp_github_create_issue` |
| `my-api` | `query.data` | `mcp_my_api_query_data` |

在實務上，您通常不需要手動調用帶有前綴的名稱 — Hermes 會在正常的推理過程中看到並選擇該工具。

## MCP 輔助工具 (Utility Tools)

在支援的情況下，Hermes 還會針對 MCP 資源 (resources) 和提示詞 (prompts) 註冊輔助工具：

- `list_resources`
- `read_resource`
- `list_prompts`
- `get_prompt`

這些工具會按伺服器註冊，並遵循相同的前綴模式，例如：

- `mcp_github_list_resources`
- `mcp_github_get_prompt`

### 重要事項

這些輔助工具現在具備能力感知 (capability-aware)：
- 僅當 MCP 會話實際支援資源操作時，Hermes 才會註冊資源輔助工具。
- 僅當 MCP 會話實際支援提示詞操作時，Hermes 才會註冊提示詞輔助工具。

因此，僅公開可調用工具但未公開資源/提示詞的伺服器將不會獲得這些額外的封裝工具。

## 個別伺服器過濾 (Per-server filtering)

您可以控制每個 MCP 伺服器向 Hermes 提供哪些工具，從而實現對工具命名空間的精細管理。

### 完全停用某個伺服器

```yaml
mcp_servers:
  legacy:
    url: "https://mcp.legacy.internal"
    enabled: false
```

如果 `enabled: false`，Hermes 會完全跳過該伺服器，甚至不會嘗試連線。

### 工具白名單 (Whitelist)

```yaml
mcp_servers:
  github:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: "***"
    tools:
      include: [create_issue, list_issues]
```

僅註冊這些指定的 MCP 伺服器工具。

### 工具黑名單 (Blacklist)

```yaml
mcp_servers:
  stripe:
    url: "https://mcp.stripe.com"
    tools:
      exclude: [delete_customer]
```

註冊除排除項之外的所有伺服器工具。

### 優先級規則

如果兩者同時存在：

```yaml
tools:
  include: [create_issue]
  exclude: [create_issue, delete_issue]
```

`include`（包含）優先。

### 同時過濾輔助工具

您也可以分別停用由 Hermes 新增的輔助工具封裝：

```yaml
mcp_servers:
  docs:
    url: "https://mcp.docs.example.com"
    tools:
      prompts: false
      resources: false
```

這意味著：
- `tools.resources: false` 停用 `list_resources` 和 `read_resource`。
- `tools.prompts: false` 停用 `list_prompts` 和 `get_prompt`。

### 完整範例

```yaml
mcp_servers:
  github:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: "***"
    tools:
      include: [create_issue, list_issues, search_code]
      prompts: false

  stripe:
    url: "https://mcp.stripe.com"
    headers:
      Authorization: "Bearer ***"
    tools:
      exclude: [delete_customer]
      resources: false

  legacy:
    url: "https://mcp.legacy.internal"
    enabled: false
```

## 如果所有工具都被過濾掉了會怎樣？

如果您的配置過濾掉了所有可調用工具，並且停用或省略了所有受支援的輔助工具，Hermes 就不會為該伺服器建立空的執行階段 MCP 工具集。

這有助於保持工具列表的簡潔。

## 執行階段行為

### 發現階段 (Discovery time)

Hermes 在啟動時發現 MCP 伺服器，並將其工具註冊到正常的工具註冊表中。

### 動態工具發現 (Dynamic Tool Discovery)

MCP 伺服器可以透過發送 `notifications/tools/list_changed` 通知，在執行階段告知 Hermes 其可用工具已發生變化。當 Hermes 收到此通知時，它會自動重新獲取伺服器的工具列表並更新註冊表 — 無需手動執行 `/reload-mcp`。

這對於功能會動態變化的 MCP 伺服器非常有用（例如，當載入新的資料庫架構時新增工具，或當服務離線時移除工具的伺服器）。

此刷新過程受鎖定保護，因此來自同一伺服器的快速連續通知不會導致重複刷新。目前已支援接收提示詞和資源變更通知 (`prompts/list_changed`, `resources/list_changed`)，但尚未實作後續動作。

### 重新載入

如果您更改了 MCP 配置，請使用：

```text
/reload-mcp
```

這會從配置中重新載入 MCP 伺服器並重新整理可用工具列表。對於由伺服器本身推送的執行階段工具更改，請參閱上面的 [動態工具發現](#動態工具發現)。

### 工具集 (Toolsets)

每個配置的 MCP 伺服器在提供至少一個註冊工具時，也會建立一個執行階段工具集：

```text
mcp-<伺服器名稱>
```

這使得在工具集層級更容易對 MCP 伺服器進行推理。

## 安全模型

### Stdio 環境變數過濾

對於 stdio 伺服器，Hermes 不會盲目傳遞您完整的 shell 環境變數。

僅傳遞明確配置的 `env` 以及安全的基準環境。這減少了意外洩露機密的風險。

### 配置層級的公開控制

新的過濾支援也是一種安全控制手段：
- 停用您不希望模型看到的危險工具。
- 針對敏感伺服器僅公開最小白名單。
- 當您不希望公開該介面時，停用資源/提示詞封裝。

## 範例使用場景

### 具有最小問題管理介面的 GitHub 伺服器

```yaml
mcp_servers:
  github:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: "***"
    tools:
      include: [list_issues, create_issue, update_issue]
      prompts: false
      resources: false
```

使用方式如下：

```text
顯示標記為 bug 的未解決問題，然後為不穩定的 MCP 重新連線行為起草一個新問題。
```

### 移除了危險操作的 Stripe 伺服器

```yaml
mcp_servers:
  stripe:
    url: "https://mcp.stripe.com"
    headers:
      Authorization: "Bearer ***"
    tools:
      exclude: [delete_customer, refund_payment]
```

使用方式如下：

```text
查詢最後 10 筆失敗的付款，並摘要常見的失敗原因。
```

### 針對單個專案根目錄的檔案系統伺服器

```yaml
mcp_servers:
  project_fs:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-filesystem", "/home/user/my-project"]
```

使用方式如下：

```text
檢查專案根目錄並解釋目錄佈局。
```

## 疑難排解

### MCP 伺服器無法連線

請檢查：

```bash
# 確認已安裝 MCP 依賴項（標準安裝中已包含）
cd ~/.hermes/hermes-agent && uv pip install -e ".[mcp]"

node --version
npx --version
```

然後確認您的配置並重啟 Hermes。

### 工具沒有出現

可能的原因：
- 伺服器連線失敗。
- 發現 (discovery) 失敗。
- 您的過濾配置排除了這些工具。
- 該伺服器不具備輔助工具功能。
- 伺服器透過 `enabled: false` 被停用。

如果您是刻意進行過濾，則這是正常的。

### 為什麼沒有出現資源或提示詞輔助工具？

因為 Hermes 現在僅在滿足以下兩個條件時才註冊這些封裝工具：
1. 您的配置允許使用它們。
2. 伺服器會話實際支援該功能。

這是刻意的設計，旨在保持工具列表的準確性。

## MCP 採樣 (Sampling) 支援

MCP 伺服器可以透過 `sampling/createMessage` 協定向 Hermes 請求 LLM 推理。這允許 MCP 伺服器要求 Hermes 代其生成文字 — 對於需要 LLM 能力但自身沒有模型存取權限的伺服器非常有用。

對於所有 MCP 伺服器（在 MCP SDK 支援的情況下），採樣功能**預設為啟用**。您可以在 `sampling` 金鑰下為每個伺服器進行配置：

```yaml
mcp_servers:
  my_server:
    command: "my-mcp-server"
    sampling:
      enabled: true            # 啟用採樣（預設：true）
      model: "openai/gpt-4o"  # 覆蓋採樣請求的模型（選填）
      max_tokens_cap: 4096     # 每次採樣回應的最大 token 數（預設：4096）
      timeout: 30              # 每次請求的超時秒數（預設：30）
      max_rpm: 10              # 速率限制：每分鐘最大請求數（預設：10）
      max_tool_rounds: 5       # 採樣迴圈中的最大工具使用輪次（預設：5）
      allowed_models: []       # 伺服器可請求的模型名稱白名單（空值 = 任何模型）
      log_level: "info"        # 稽核日誌層級：debug, info, 或 warning（預設：info）
```

採樣處理程序包含滑動視窗速率限制器、單次請求超時以及工具迴圈深度限制，以防止過度使用。系統會按伺服器實例追蹤指標（請求計數、錯誤、使用的 token 數）。

要停用特定伺服器的採樣功能：

```yaml
mcp_servers:
  untrusted_server:
    url: "https://mcp.example.com"
    sampling:
      enabled: false
```

## 將 Hermes 作為 MCP 伺服器執行 (hermes mcp serve)

除了連接**到** MCP 伺服器之外，Hermes 本身也可以**作為**一個 MCP 伺服器。這讓其他支援 MCP 的代理程式（Claude Code, Cursor, Codex 或任何 MCP 用戶端）可以使用 Hermes 的訊息功能 — 列出對話、讀取訊息歷史記錄，以及在所有已連接的平台上發送訊息。

### 何時使用此功能

- 您希望 Claude Code、Cursor 或其他開發代理程式透過 Hermes 發送和讀取 Telegram/Discord/Slack 訊息。
- 您希望有一個單一的 MCP 伺服器，可以同時橋接到 Hermes 所有已連接的通訊平台。
- 您已經有一個運作中的 Hermes 網關且已連接平台。

### 快速入門

```bash
hermes mcp serve
```

這會啟動一個 stdio MCP 伺服器。MCP 用戶端（而非您）會管理該程序的生命週期。

### MCP 用戶端配置

將 Hermes 新增到您的 MCP 用戶端配置中。例如，在 Claude Code 的 `~/.claude/claude_desktop_config.json` 中：

```json
{
  "mcpServers": {
    "hermes": {
      "command": "hermes",
      "args": ["mcp", "serve"]
    }
  }
}
```

或者，如果您將 Hermes 安裝在特定位置：

```json
{
  "mcpServers": {
    "hermes": {
      "command": "/home/user/.hermes/hermes-agent/venv/bin/hermes",
      "args": ["mcp", "serve"]
    }
  }
}
```

### 可用的工具

MCP 伺服器公開了 10 個工具，與 OpenClaw 的頻道橋接介面一致，並加上了一個 Hermes 特有的頻道瀏覽器：

| 工具 | 說明 |
|------|-------------|
| `conversations_list` | 列出活動中的通訊對話。可按平台過濾或按名稱搜尋。 |
| `conversation_get` | 透過會話金鑰獲取單個對話的詳細資訊。 |
| `messages_read` | 讀取某個對話最近的訊息歷史記錄。 |
| `attachments_fetch` | 從特定訊息中提取非文字附件（圖片、媒體）。 |
| `events_poll` | 從某個游標位置開始輪詢新的對話事件。 |
| `events_wait` | 長輪詢 / 阻塞直到下一個事件到達（近乎即時）。 |
| `messages_send` | 透過平台發送訊息（例如 `telegram:123456`, `discord:#general`）。 |
| `channels_list` | 列出所有平台上可用的訊息目標。 |
| `permissions_list_open` | 列在此橋接會話期間觀察到的待處理核准請求。 |
| `permissions_respond` | 允許或拒絕待處理的核准請求。 |

### 事件系統

MCP 伺服器包含一個即時事件橋接器，會輪詢 Hermes 的會話資料庫以獲取新訊息。這讓 MCP 用戶端能近乎即時地掌握傳入的對話：

```text
# 輪詢新事件（非阻塞）
events_poll(after_cursor=0)

# 等待下一個事件（阻塞直到超時）
events_wait(after_cursor=42, timeout_ms=30000)
```

事件類型：`message`, `approval_requested`, `approval_resolved`

事件佇列位於記憶體中，並在橋接器連線時開始運作。較舊的訊息可透過 `messages_read` 取得。

### 選項

```bash
hermes mcp serve              # 正常模式
hermes mcp serve --verbose    # 在 stderr 上顯示除錯日誌
```

### 運作原理

MCP 伺服器直接從 Hermes 的會話存儲（`~/.hermes/sessions/sessions.json` 和 SQLite 資料庫）讀取對話數據。一個背景執行緒會輪詢資料庫中的新訊息，並維護一個記憶體中的事件佇列。發送訊息時，它使用與 Hermes 代理程式本身相同的 `send_message` 基礎設施。

讀取操作（列出對話、讀取歷史記錄、輪詢事件）不需要運行網關。發送操作**需要**運行網關，因為平台適配器需要活動中的連線。

### 目前限制

- 僅支援 Stdio 傳輸（目前尚不支援 HTTP MCP 傳輸）。
- 透過基於修改時間優化的 (mtime-optimized) 資料庫輪詢，事件輪詢間隔約為 200ms（在檔案未更改時會跳過操作）。
- 尚未支援 `claude/channel` 推送通知協定。
- 僅支援文字發送（不支援透過 `messages_send` 發送媒體/附件）。

## 相關文件

- [在 Hermes 中使用 MCP](/docs/guides/use-mcp-with-hermes)
- [CLI 指令](/docs/reference/cli-commands)
- [斜線指令](/docs/reference/slash-commands)
- [常見問題 (FAQ)](/docs/reference/faq)
