---
sidebar_position: 8
title: "MCP 設定參考"
description: "Hermes Agent MCP 設定鍵值、過濾語義以及輔助工具策略的參考說明"
---

# MCP 設定參考

本頁面是主要 MCP 文件的精簡參考手冊。

關於概念指引，請參閱：
- [MCP (模型上下文協定, Model Context Protocol)](/docs/user-guide/features/mcp)
- [在 Hermes 中使用 MCP](/docs/guides/use-mcp-with-hermes)

## 根設定格式

```yaml
mcp_servers:
  <server_name>:
    command: "..."      # stdio 伺服器
    args: []
    env: {}

    # 或者
    url: "..."          # HTTP 伺服器
    headers: {}

    enabled: true
    timeout: 120
    connect_timeout: 60
    tools:
      include: []
      exclude: []
      resources: true
      prompts: true
```

## 伺服器鍵值

| 鍵值 | 類型 | 適用於 | 意義 |
|---|---|---|---|
| `command` | 字串 | stdio | 要啟動的可執行文件 |
| `args` | 列表 | stdio | 子程序的參數 |
| `env` | 映射 | stdio | 傳遞給子程序的環境變數 |
| `url` | 字串 | HTTP | 遠端 MCP 端點 |
| `headers` | 映射 | HTTP | 遠端伺服器請求的標頭 |
| `enabled` | 布林值 | 兩者皆可 | 當為 false 時完全跳過該伺服器 |
| `timeout` | 數字 | 兩者皆可 | 工具呼叫逾時時間 |
| `connect_timeout` | 數字 | 兩者皆可 | 初始連線逾時時間 |
| `tools` | 映射 | 兩者皆可 | 過濾與輔助工具策略 |
| `auth` | 字串 | HTTP | 驗證方法。設置為 `oauth` 以啟用帶有 PKCE 的 OAuth 2.1 |
| `sampling` | 映射 | 兩者皆可 | 伺服器啟動的 LLM 請求策略 (參閱 MCP 指南) |

## `tools` 策略鍵值

| 鍵值 | 類型 | 意義 |
|---|---|---|
| `include` | 字串或列表 | 伺服器原生 MCP 工具的白名單 |
| `exclude` | 字串或列表 | 伺服器原生 MCP 工具的黑名單 |
| `resources` | 類布林值 | 啟用/停用 `list_resources` + `read_resource` |
| `prompts` | 類布林值 | 啟用/停用 `list_prompts` + `get_prompt` |

## 過濾語義

### `include`

如果設置了 `include`，則僅註冊那些伺服器原生的 MCP 工具。

```yaml
tools:
  include: [create_issue, list_issues]
```

### `exclude`

如果設置了 `exclude` 且未設置 `include`，則除了這些名稱以外的所有伺服器原生 MCP 工具都會被註冊。

```yaml
tools:
  exclude: [delete_customer]
```

### 優先順序

如果兩者都設置了，以 `include` 為準。

```yaml
tools:
  include: [create_issue]
  exclude: [create_issue, delete_issue]
```

結果：
- `create_issue` 仍被允許
- `delete_issue` 被忽略，因為 `include` 具有優先權

## 輔助工具策略

Hermes 可能會為每個 MCP 伺服器註冊這些輔助包裝工具：

資源 (Resources)：
- `list_resources`
- `read_resource`

提示詞 (Prompts)：
- `list_prompts`
- `get_prompt`

### 停用資源

```yaml
tools:
  resources: false
```

### 停用提示詞

```yaml
tools:
  prompts: false
```

### 具備能力感知功能的註冊

即使設置了 `resources: true` 或 `prompts: true`，Hermes 只有在 MCP 工作階段確實公開了對應功能時，才會註冊這些輔助工具。

因此，以下情況是正常的：
- 您啟用了提示詞
- 但沒有出現提示詞輔助工具
- 因為該伺服器不支援提示詞

## `enabled: false`

```yaml
mcp_servers:
  legacy:
    url: "https://mcp.legacy.internal"
    enabled: false
```

行為：
- 不嘗試連線
- 不進行探索
- 不進行工具註冊
- 設定保留在原位以供日後重複使用

## 空結果行為

如果過濾移除了所有伺服器原生工具，且未註冊任何輔助工具，Hermes 就不會為該伺服器建立空的 MCP 執行期工具集。

## 設定範例

### 安全的 GitHub 允許列表

```yaml
mcp_servers:
  github:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: "***"
    tools:
      include: [list_issues, create_issue, update_issue, search_code]
      resources: false
      prompts: false
```

### Stripe 黑名單

```yaml
mcp_servers:
  stripe:
    url: "https://mcp.stripe.com"
    headers:
      Authorization: "Bearer ***"
    tools:
      exclude: [delete_customer, refund_payment]
```

### 僅限資源的文件伺服器

```yaml
mcp_servers:
  docs:
    url: "https://mcp.docs.example.com"
    tools:
      include: []
      resources: true
      prompts: false
```

## 重新載入設定

變更 MCP 設定後，使用以下指令重新載入伺服器：

```text
/reload-mcp
```

## 工具命名

伺服器原生的 MCP 工具會變成：

```text
mcp_<伺服器>_<工具>
```

範例：
- `mcp_github_create_issue`
- `mcp_filesystem_read_file`
- `mcp_my_api_query_data`

輔助工具遵循相同的字首模式：
- `mcp_<伺服器>_list_resources`
- `mcp_<伺服器>_read_resource`
- `mcp_<伺服器>_list_prompts`
- `mcp_<伺服器>_get_prompt`

### 名稱清理 (Sanitization)

伺服器名稱和工具名稱中的連字號 (`-`) 和點 (`.`) 在註冊前都會被替換為底線 (`_`)。這可確保工具名稱對於 LLM 函式呼叫 API 是有效的識別碼。

例如，名為 `my-api` 的伺服器公開了一個名為 `list-items.v2` 的工具，將變為：

```text
mcp_my_api_list_items_v2
```

在撰寫 `include` / `exclude` 過濾器時請記住這一點 — 請使用 **原始** 的 MCP 工具名稱 (包含連字號/點)，而非清理後的版本。

## OAuth 2.1 驗證

對於需要 OAuth 的 HTTP 伺服器，請在伺服器項目上設置 `auth: oauth`：

```yaml
mcp_servers:
  protected_api:
    url: "https://mcp.example.com/mcp"
    auth: oauth
```

行為：
- Hermes 使用 MCP SDK 的 OAuth 2.1 PKCE 流程 (元數據探索、動態用戶端註冊、權杖交換與重新整理)
- 首次連線時，會開啟瀏覽器視窗進行授權
- 權杖會持久化儲存到 `~/.hermes/mcp-tokens/<server>.json` 並在不同工作階段間重複使用
- 權杖重新整理是自動的；僅當重新整理失敗時才會要求重新授權
- 僅適用於 HTTP/StreamableHTTP 傳輸 (基於 `url` 的伺服器)
