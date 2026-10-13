---
sidebar_position: 6
title: "在 Hermes 中使用 MCP"
description: "將 MCP 伺服器連接到 Hermes Agent 的實用指南，包含如何篩選其工具以及在實際工作流中安全地使用它們"
---

# 在 Hermes 中使用 MCP

本指南將介紹如何在日常工作流中實際使用 MCP (Model Context Protocol) 搭配 Hermes Agent。

如果功能介紹頁面解釋了什麼是 MCP，那麼本指南則是關於如何快速且安全地從中獲取價值。

## 您應該在何時使用 MCP？

在以下情況使用 MCP：
- 工具已經以 MCP 形式存在，且您不想開發原生的 Hermes 工具。
- 您希望 Hermes 透過乾淨的 RPC 層對本地或遠端系統進行操作。
- 您需要對每個伺服器暴露的內容進行精細的控制。
- 您希望在不修改 Hermes 核心的情況下，將 Hermes 連接到內部 API、資料庫或公司系統。

在以下情況**不要**使用 MCP：
- 內建的 Hermes 工具已經能很好地完成任務。
- 伺服器暴露了大量危險的工具介面，而您還沒準備好進行篩選。
- 您只需要一個非常窄的整合，而原生工具會更簡單且安全。

## 心理模型

將 MCP 視為一個轉接層（Adapter Layer）：

- Hermes 仍然是 Agent（代理）。
- MCP 伺服器提供工具（Tools）。
- Hermes 在啟動或重新載入時探索這些工具。
- 模型可以像使用普通工具一樣使用它們。
- 您可以控制每個伺服器的哪些部分是可見的。

最後一點非常重要。良好的 MCP 使用方式並非「連接所有內容」，而是「以最小的有用介面連接正確的內容」。

## 第 1 步：安裝 MCP 支援

如果您是使用標準安裝指令碼安裝的 Hermes，則已經包含了 MCP 支援（安裝程式會執行 `uv pip install -e ".[all]"`）。

如果您在安裝時沒有包含額外組件，需要單獨添加 MCP 支援：

```bash
cd ~/.hermes/hermes-agent
uv pip install -e ".[mcp]"
```

對於基於 npm 的伺服器，請確保 Node.js 和 `npx` 可供使用。

對於許多 Python MCP 伺服器，`uvx` 是一個不錯的預設選擇。

## 第 2 步：先添加一個伺服器

從一個單一且安全的伺服器開始。

範例：僅限於一個專案目錄的檔案系統存取。

```yaml
mcp_servers:
  project_fs:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-filesystem", "/home/user/my-project"]
```

然後啟動 Hermes：

```bash
hermes chat
```

接著詢問一個具體的問題：

```text
檢查此專案並總結儲存庫的佈局。
```

## 第 3 步：驗證 MCP 是否已載入

您可以透過以下幾種方式驗證 MCP：

- 設定完成後，Hermes 的橫幅（Banner）或狀態（Status）應顯示 MCP 整合。
- 詢問 Hermes 目前有哪些可用工具。
- 在修改設定後使用 `/reload-mcp`。
- 如果伺服器連接失敗，請檢查日誌。

一個實用的測試提示語：

```text
告訴我現在有哪些基於 MCP 的工具可用。
```

## 第 4 步：立即開始篩選

如果伺服器暴露了大量工具，請不要等到以後再處理。

### 範例：僅將您需要的內容列入白名單

```yaml
mcp_servers:
  github:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: "***"
    tools:
      include: [list_issues, create_issue, search_code]
```

對於敏感系統，這通常是最佳的預設做法。

### 範例：將危險操作列入黑名單

```yaml
mcp_servers:
  stripe:
    url: "https://mcp.stripe.com"
    headers:
      Authorization: "Bearer ***"
    tools:
      exclude: [delete_customer, refund_payment]
```

### 範例：同時停用工具程式包裝器 (Utility Wrappers)

```yaml
mcp_servers:
  docs:
    url: "https://mcp.docs.example.com"
    tools:
      prompts: false
      resources: false
```

## 篩選實際上會影響什麼？

在 Hermes 中，MCP 暴露的功能分為兩類：

1. 伺服器原生的 MCP 工具
- 使用以下項目進行篩選：
  - `tools.include`
  - `tools.exclude`

2. Hermes 添加的工具程式包裝器 (Utility Wrappers)
- 使用以下項目進行篩選：
  - `tools.resources`
  - `tools.prompts`

### 您可能會看到的工具程式包裝器

資源（Resources）：
- `list_resources`
- `read_resource`

提示語（Prompts）：
- `list_prompts`
- `get_prompt`

這些包裝器僅在以下情況出現：
- 您的設定允許它們，且
- 該 MCP 伺服器工作階段實際上支援這些能力。

因此，如果伺服器本身不具備資源或提示語能力，Hermes 就不會假裝它有。

## 常見模式

### 模式 1：本地專案助手

當您希望 Hermes 在限定的工作空間內進行推理時，可以對儲存庫本地檔案系統或 Git 伺服器使用 MCP。

```yaml
mcp_servers:
  fs:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-filesystem", "/home/user/project"]

  git:
    command: "uvx"
    args: ["mcp-server-git", "--repository", "/home/user/project"]
```

推薦提示語：

```text
審查專案結構並找出設定檔所在位置。
```

```text
檢查本地 Git 狀態並總結最近有哪些更改。
```

### 模式 2：GitHub 議題篩選助手

```yaml
mcp_servers:
  github:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: "***"
    tools:
      include: [list_issues, create_issue, update_issue, search_code]
      prompts: false
      resources: false
```

推薦提示語：

```text
列出關於 MCP 的未解決議題 (Open Issues)，按主題進行歸類，並針對最常見的錯誤草擬一份高品質的議題。
```

```text
在儲存庫中搜尋 _discover_and_register_server 的用法，並解釋 MCP 工具是如何註冊的。
```

### 模式 3：內部 API 助手

```yaml
mcp_servers:
  internal_api:
    url: "https://mcp.internal.example.com"
    headers:
      Authorization: "Bearer ***"
    tools:
      include: [list_customers, get_customer, list_invoices]
      resources: false
      prompts: false
```

推薦提示語：

```text
查詢客戶 ACME Corp 並總結最近的發票活動。
```

在這種情況下，嚴格的白名單（Include List）遠比黑名單（Exclude List）更好。

### 模式 4：文件 / 知識伺服器

某些 MCP 伺服器暴露的提示語或資源更像是共享的知識資產，而非直接的操作。

```yaml
mcp_servers:
  docs:
    url: "https://mcp.docs.example.com"
    tools:
      prompts: true
      resources: true
```

推薦提示語：

```text
從文件伺服器列出可用的 MCP 資源，然後閱讀入職指南並進行總結。
```

```text
列出文件伺服器暴露的提示語，並告訴我哪些提示語有助於事件應變 (Incident Response)。
```

## 教學：包含篩選的端到端設定

這是一個實際的進階流程。

### 第一階段：添加 GitHub MCP 並使用嚴格白名單

```yaml
mcp_servers:
  github:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: "***"
    tools:
      include: [list_issues, create_issue, search_code]
      prompts: false
      resources: false
```

啟動 Hermes 並詢問：

```text
在程式碼庫中搜尋對 MCP 的引用，並總結主要的整合點。
```

### 第二階段：僅在需要時擴展

如果您稍後也需要更新議題的功能：

```yaml
tools:
  include: [list_issues, create_issue, update_issue, search_code]
```

然後重新載入：

```text
/reload-mcp
```

### 第三階段：添加具有不同策略的第二個伺服器

```yaml
mcp_servers:
  github:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: "***"
    tools:
      include: [list_issues, create_issue, update_issue, search_code]
      prompts: false
      resources: false

  filesystem:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-filesystem", "/home/user/project"]
```

現在 Hermes 可以結合兩者：

```text
檢查本地專案檔案，然後建立一個 GitHub 議題來總結您發現的錯誤。
```

這就是 MCP 強大之處：無需更改 Hermes 核心即可實現跨系統的工作流。

## 安全使用建議

### 對危險系統優先使用允許列表 (Allowlist)

對於任何涉及財務、面向客戶或具有破壞性的系統：
- 使用 `tools.include`。
- 從最小的可用工具集開始。

### 停用不使用的工具程式

如果您不希望模型瀏覽伺服器提供的資源或提示語，請將其關閉：

```yaml
tools:
  resources: false
  prompts: false
```

### 保持伺服器的作用域最小化

範例：
- 將檔案系統伺服器根目錄設定為單一專案目錄，而非整個家目錄。
- 將 Git 伺服器指向單一儲存庫。
- 內部 API 伺服器預設僅暴露讀取類型的工具。

### 修改設定後記得重新載入

```text
/reload-mcp
```

在更改以下內容後執行此操作：
- 包含/排除列表。
- 啟用標記。
- 資源/提示語切換。
- 認證標頭（Headers）或環境變數（Env）。

## 故障排除（按症狀）

### 「伺服器已連接，但我想使用的工具不見了」

可能原因：
- 被 `tools.include` 篩選掉了。
- 被 `tools.exclude` 排除掉了。
- 工具程式包裝器透過 `resources: false` 或 `prompts: false` 停用了。
- 伺服器實際上不支援資源或提示語。

### 「伺服器已設定，但沒有載入任何內容」

請檢查：
- 設定中沒有遺留 `enabled: false`。
- 指令或執行環境存在（`npx`, `uvx` 等）。
- HTTP 端點可連線。
- 認證環境變數或標頭正確。

### 「為什麼我看到的工具比 MCP 伺服器宣稱的要少？」

因為 Hermes 現在會遵循您對每個伺服器的策略以及具備能力感知的註冊機制。這是預期行為，通常也是件好事。

### 「如何在不刪除設定的情況下移除一個 MCP 伺服器？」

使用：

```yaml
enabled: false
```

這會保留設定，但阻止連接和註冊。

## 推薦的首選 MCP 設定

適合大多數使用者的首選伺服器：
- filesystem (檔案系統)
- git
- GitHub
- fetch / 文件 MCP 伺服器
- 單一的特定內部 API

不推薦作為首選的伺服器：
- 具有大量破壞性操作且未經篩選的大型業務系統。
- 任何您不夠瞭解、無法進行有效約束的系統。

## 相關文件

- [MCP (Model Context Protocol)](/docs/user-guide/features/mcp)
- [常見問題 (FAQ)](/docs/reference/faq)
- [斜線指令](/docs/reference/slash-commands)
