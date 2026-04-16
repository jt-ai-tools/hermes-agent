---
name: native-mcp
description: 內置 MCP (Model Context Protocol) 用戶端，可連接到外部 MCP 伺服器，發現其工具，並將其註冊為原生的 Hermes Agent 工具。支持 stdio 和 HTTP 傳輸，具有自動重新連接、安全過濾和零配置工具注入功能。
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [MCP, Tools, Integrations]
    related_skills: [mcporter]
---

# 原生 MCP 用戶端 (Native MCP Client)

Hermes Agent 有一個內置的 MCP 用戶端，可在啟動時連接到 MCP 伺服器，發現其工具，並使其作為代理可以直接調用的一等工具 (first-class tools) 使用。不需要橋接 CLI —— 來自 MCP 伺服器的工具會與 `terminal`、`read_file` 等內置工具並列顯示。

## 何時使用

在以下情況下使用此功能：
- 想從 Hermes Agent 內部連接到 MCP 伺服器並使用其工具
- 透過 MCP 添加外部功能 (文件系統訪問、GitHub、數據庫、API)
- 運行本地基於 stdio 的 MCP 伺服器 (npx, uvx 或任何命令)
- 連接到遠端 HTTP/StreamableHTTP MCP 伺服器
- 讓 MCP 工具自動被發現，並在每次對話中可用

對於在終端中不進行任何配置而進行的臨時、單次 MCP 工具調用，請參閱 [mcporter](../mcporter/SKILL_zh_TW.md) 技能。

## 前置條件

- **mcp Python 套件** —— 選配依賴項；使用 `pip install mcp` 安裝。如果未安裝，MCP 支持將被靜默禁用。
- **Node.js** —— 基於 `npx` 的 MCP 伺服器所需 (大多數社群伺服器)
- **uv** —— 基於 `uvx` 的 MCP 伺服器所需 (基於 Python 的伺服器)

安裝 MCP SDK：

```bash
pip install mcp
# 或者，如果使用 uv：
uv pip install mcp
```

## 快速啟動

在 `~/.hermes/config.yaml` 的 `mcp_servers` 鍵下添加 MCP 伺服器：

```yaml
mcp_servers:
  time:
    command: "uvx"
    args: ["mcp-server-time"]
```

重啟 Hermes Agent。啟動時它將：
1. 連接到伺服器
2. 發現可用工具
3. 使用前綴 `mcp_time_*` 註冊它們
4. 將它們注入所有平台的工具集 (toolsets) 中

然後您就可以自然地使用這些工具了 —— 直接要求代理獲取當前時間即可。

## 配置參考

`mcp_servers` 下的每個條目都是一個伺服器名稱與其配置的映射。有兩種傳輸類型：**stdio** (基於命令) 和 **HTTP** (基於 URL)。

### Stdio 傳輸 (command + args)

```yaml
mcp_servers:
  server_name:
    command: "npx"             # (必填) 要運行的可執行文件
    args: ["-y", "pkg-name"]   # (選填) 命令參數，預設：[]
    env:                       # (選填) 子程序的環境變數
      SOME_API_KEY: "value"
    timeout: 120               # (選填) 每次工具調用的超時時間 (秒)，預設：120
    connect_timeout: 60        # (選填) 初始連接超時時間 (秒)，預設：60
```

### HTTP 傳輸 (url)

```yaml
mcp_servers:
  server_name:
    url: "https://my-server.example.com/mcp"   # (必填) 伺服器 URL
    headers:                                     # (選填) HTTP 標頭
      Authorization: "Bearer sk-..."
    timeout: 180               # (選填) 每次工具調用的超時時間 (秒)，預設：120
    connect_timeout: 60        # (選填) 初始連接超時時間 (秒)，預設：60
```

### 所有配置選項

| 選項            | 類型   | 預設值 | 說明                                       |
|-------------------|--------|---------|---------------------------------------------------|
| `command`         | 字串 | --      | 要運行的可執行文件 (stdio 傳輸，必填)     |
| `args`            | 列表   | `[]`    | 傳遞給命令的參數                   |
| `env`             | 字典   | `{}`    | 子程序的額外環境變數    |
| `url`             | 字串 | --      | 伺服器 URL (HTTP 傳輸，必填)             |
| `headers`         | 字典   | `{}`    | 隨每個請求發送的 HTTP 標頭              |
| `timeout`         | 整數    | `120`   | 每次工具調用的超時時間 (秒)                  |
| `connect_timeout` | 整數    | `60`    | 初始連接和發現的超時時間      |

注意：伺服器配置必須包含 `command` (stdio) 或 `url` (HTTP) 其中之一，不能兩者並存。

## 工作原理

### 啟動發現

當 Hermes Agent 啟動時，會在工具初始化期間調用 `discover_mcp_tools()`：

1. 從 `~/.hermes/config.yaml` 讀取 `mcp_servers`
2. 對於每個伺服器，在專用的後台事件循環中生成一個連接
3. 初始化 MCP 會話並調用 `list_tools()` 以發現可用工具
4. 在 Hermes 工具註冊表中註冊每個工具

### 工具命名規範

MCP 工具的註冊命名模式如下：

```
mcp_{server_name}_{tool_name}
```

為了與 LLM API 兼容，名稱中的連字號 (hyphens) 和點號 (dots) 會被替換為底線。

範例：
- 伺服器 `filesystem`，工具 `read_file` → `mcp_filesystem_read_file`
- 伺服器 `github`，工具 `list-issues` → `mcp_github_list_issues`
- 伺服器 `my-api`，工具 `fetch.data` → `mcp_my_api_fetch_data`

### 自動注入

發現後，MCP 工具會自動注入到所有 `hermes-*` 平台工具集中 (CLI, Discord, Telegram 等)。這意味著 MCP 工具在每次對話中都可用，無需任何額外配置。

### 連接生命週期

- 每個伺服器都作為後台守護線程 (daemon thread) 中的長生命週期 asyncio 任務運行
- 連接在代理進程的生命週期內持續存在
- 如果連接中斷，會啟動帶有指數退避 (exponential backoff) 的自動重新連接 (最多 5 次嘗試，最大 60 秒退避)
- 在代理關閉時，所有連接都會優雅地關閉

### 冪等性

`discover_mcp_tools()` 是冪等的 —— 多次調用它只會連接到尚未連接的伺服器。失敗的伺服器會在後續調用中重試。

## 傳輸類型

### Stdio 傳輸

最常見的傳輸方式。Hermes 將 MCP 伺服器作為子程序啟動，並透過 stdin/stdout 進行通信。

```yaml
mcp_servers:
  filesystem:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-filesystem", "/home/user/projects"]
```

子程序繼承一個**經過過濾的**環境 (見下文安全部分)，以及您在 `env` 中指定的任何變數。

### HTTP / StreamableHTTP 傳輸

用於遠端或共享的 MCP 伺服器。要求 `mcp` 套件包含 HTTP 用戶端支持 (`mcp.client.streamable_http`)。

```yaml
mcp_servers:
  remote_api:
    url: "https://mcp.example.com/mcp"
    headers:
      Authorization: "Bearer sk-..."
```

如果您安裝的 `mcp` 版本中不包含 HTTP 支持，該伺服器將報錯 (ImportError)，而其他伺服器將繼續正常運行。

## 安全性

### 環境變數過濾

對於 stdio 伺服器，Hermes **不會**將完整的 shell 環境傳遞給 MCP 子程序。僅繼承安全的基本變數：

- `PATH`, `HOME`, `USER`, `LANG`, `LC_ALL`, `TERM`, `SHELL`, `TMPDIR`
- 任何 `XDG_*` 變數

除非您透過 `env` 配置鍵顯式添加，否則所有其他環境變數 (API 金鑰、權杖、機密資訊) 都會被排除。這可以防止憑據意外洩漏給不受信任的 MCP 伺服器。

```yaml
mcp_servers:
  github:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      # 僅此權杖會被傳遞給子程序
      GITHUB_PERSONAL_ACCESS_TOKEN: "ghp_..."
```

### 錯誤訊息中的憑據清除

如果 MCP 工具調用失敗，錯誤訊息中任何類似憑據的模式都會在顯示給 LLM 之前被自動遮蔽。這包括：

- GitHub PATs (`ghp_...`)
- OpenAI 風格的金鑰 (`sk-...`)
- 持票人權杖 (Bearer tokens)
- 通用的 `token=`, `key=`, `API_KEY=`, `password=`, `secret=` 模式

## 疑難排解

### "MCP SDK not available -- skipping MCP tool discovery"

未安裝 `mcp` Python 套件。請安裝：

```bash
pip install mcp
```

### "No MCP servers configured"

`~/.hermes/config.yaml` 中沒有 `mcp_servers` 鍵，或者該鍵為空。請至少添加一個伺服器。

### "Failed to connect to MCP server 'X'"

常見原因：
- **找不到命令**：`command` 二進制文件不在 PATH 中。請確保已安裝 `npx`、`uvx` 或相關命令。
- **找不到套件**：對於 npx 伺服器，npm 套件可能不存在，或者需要在參數中加入 `-y` 以便自動安裝。
- **超時**：伺服器啟動時間過長。請增加 `connect_timeout`。
- **端口衝突**：對於 HTTP 伺服器，URL 可能無法訪問。

### "MCP server 'X' requires HTTP transport but mcp.client.streamable_http is not available"

您的 `mcp` 套件版本不包含 HTTP 用戶端支持。請升級：

```bash
pip install --upgrade mcp
```

### 工具未顯示

- 檢查伺服器是否列在 `mcp_servers` 下 (而非 `mcp` 或 `servers`)
- 確保 YAML 縮排正確
- 查看 Hermes Agent 啟動日誌中的連接訊息
- 工具名稱帶有 `mcp_{server}_{tool}` 前綴 —— 請尋找該模式

### 連接不斷中斷

用戶端會嘗試重新連接最多 5 次，並帶有指數退避 (1s, 2s, 4s, 8s, 16s，上限 60s)。如果伺服器根本無法訪問，則在嘗試 5 次後會放棄。請檢查伺服器程序和網路連接。

## 範例

### Time Server (uvx)

```yaml
mcp_servers:
  time:
    command: "uvx"
    args: ["mcp-server-time"]
```

註冊如 `mcp_time_get_current_time` 之類的工具。

### Filesystem Server (npx)

```yaml
mcp_servers:
  filesystem:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-filesystem", "/home/user/documents"]
    timeout: 30
```

註冊如 `mcp_filesystem_read_file`、`mcp_filesystem_write_file`、`mcp_filesystem_list_directory` 之類的工具。

### 帶身份驗證的 GitHub Server

```yaml
mcp_servers:
  github:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: "ghp_xxxxxxxxxxxxxxxxxxxx"
    timeout: 60
```

註冊如 `mcp_github_list_issues`、`mcp_github_create_pull_request` 等工具。

### 遠端 HTTP 伺服器

```yaml
mcp_servers:
  company_api:
    url: "https://mcp.mycompany.com/v1/mcp"
    headers:
      Authorization: "Bearer sk-xxxxxxxxxxxxxxxxxxxx"
      X-Team-Id: "engineering"
    timeout: 180
    connect_timeout: 30
```

### 多個伺服器

```yaml
mcp_servers:
  time:
    command: "uvx"
    args: ["mcp-server-time"]

  filesystem:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"]

  github:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: "ghp_xxxxxxxxxxxxxxxxxxxx"

  company_api:
    url: "https://mcp.internal.company.com/mcp"
    headers:
      Authorization: "Bearer sk-xxxxxxxxxxxxxxxxxxxx"
    timeout: 300
```

所有伺服器的所有工具都會被註冊並同時可用。每個伺服器的工具都帶有其名稱前綴，以避免衝突。

## 採樣 (Sampling，由伺服器發起的 LLM 請求)

Hermes 支持 MCP 的 `sampling/createMessage` 功能 —— MCP 伺服器可以在工具執行期間透過代理請求 LLM 補全。這使得「代理在環 (agent-in-the-loop)」工作流 (數據分析、內容生成、決策制定) 成為可能。

採樣功能**預設啟用**。可按伺服器進行配置：

```yaml
mcp_servers:
  my_server:
    command: "npx"
    args: ["-y", "my-mcp-server"]
    sampling:
      enabled: true           # 預設：true
      model: "gemini-3-flash" # 模型覆蓋 (選填)
      max_tokens_cap: 4096    # 每次請求的最大權杖數
      timeout: 30             # LLM 調用超時 (秒)
      max_rpm: 10             # 每分鐘最大請求數
      allowed_models: []      # 模型白名單 (空 = 全部)
      max_tool_rounds: 5      # 工具循環限制 (0 = 禁用)
      log_level: "info"       # 審計詳細度
```

伺服器還可以在採樣請求中包含 `tools`，用於多輪工具增強型工作流。`max_tool_rounds` 配置可防止無限工具循環。透過 `get_mcp_status()` 追踪各伺服器的審計指標 (請求數、錯誤數、權杖數、工具使用次數)。

對於不受信任的伺服器，請使用 `sampling: { enabled: false }` 禁用採樣。

## 備註

- 從代理的角度來看，MCP 工具是同步調用的，但在專用的後台事件循環中異步運行
- 工具結果以 JSON 返回，包含 `{"result": "..."}` 或 `{"error": "..."}`
- 原生 MCP 用戶端與 `mcporter` 相互獨立 —— 您可以同時使用兩者
- 伺服器連接是持久的，並在同一個代理進程的所有對話中共享
- 添加或移除伺服器需要重啟代理 (目前不支持熱加載)
