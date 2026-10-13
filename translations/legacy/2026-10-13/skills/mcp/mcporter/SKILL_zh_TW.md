---
name: mcporter
description: 使用 mcporter CLI 直接列出、配置、驗證和調用 MCP 伺服器/工具 (透過 HTTP 或 stdio)，包括臨時伺服器、配置編輯以及 CLI/類型生成。
version: 1.0.0
author: community
license: MIT
metadata:
  hermes:
    tags: [MCP, Tools, API, Integrations, Interop]
    homepage: https://mcporter.dev
prerequisites:
  commands: [npx]
---

# mcporter

使用 `mcporter` 從終端直接發現、調用和管理 [MCP (Model Context Protocol)](https://modelcontextprotocol.io/) 伺服器和工具。

## 前置條件

需要 Node.js：
```bash
# 無需安裝 (透過 npx 運行)
npx mcporter list

# 或進行全域安裝
npm install -g mcporter
```

## 快速啟動

```bash
# 列出此機器上已配置的 MCP 伺服器
mcporter list

# 列出特定伺服器的工具及其 schema 詳情
mcporter list <server> --schema

# 調用工具
mcporter call <server.tool> key=value
```

## 發現 MCP 伺服器

mcporter 會自動發現機器上由其他 MCP 用戶端 (Claude Desktop, Cursor 等) 配置的伺服器。要尋找新的伺服器，請瀏覽註冊表，如 [mcpfinder.dev](https://mcpfinder.dev) 或 [mcp.so](https://mcp.so)，然後進行臨時連接：

```bash
# 透過 URL 連接到任何 MCP 伺服器 (無需配置)
mcporter list --http-url https://some-mcp-server.com --name my_server

# 或即時運行一個 stdio 伺服器
mcporter list --stdio "npx -y @modelcontextprotocol/server-filesystem" --name fs
```

## 調用工具

```bash
# Key=value 語法
mcporter call linear.list_issues team=ENG limit:5

# 函數語法
mcporter call "linear.create_issue(title: \"Bug fix needed\")"

# 臨時 HTTP 伺服器 (無需配置)
mcporter call https://api.example.com/mcp.fetch url=https://example.com

# 臨時 stdio 伺服器
mcporter call --stdio "bun run ./server.ts" scrape url=https://example.com

# JSON 酬載 (payload)
mcporter call <server.tool> --args '{"limit": 5}'

# 機器可讀的輸出 (推薦給 Hermes 使用)
mcporter call <server.tool> key=value --output json
```

## 身份驗證與配置

```bash
# 伺服器的 OAuth 登錄
mcporter auth <server | url> [--reset]

# 管理配置
mcporter config list
mcporter config get <key>
mcporter config add <server>
mcporter config remove <server>
mcporter config import <path>
```

配置文件位置：`./config/mcporter.json` (使用 `--config` 覆蓋)。

## 守護進程 (Daemon)

用於持久的伺服器連接：
```bash
mcporter daemon start
mcporter daemon status
mcporter daemon stop
mcporter daemon restart
```

## 程式碼生成

```bash
# 為 MCP 伺服器生成 CLI 包裝器
mcporter generate-cli --server <name>
mcporter generate-cli --command <url>

# 檢查生成的 CLI
mcporter inspect-cli <path> [--json]

# 生成 TypeScript 類型/用戶端
mcporter emit-ts <server> --mode client
mcporter emit-ts <server> --mode types
```

## 備註

- 使用 `--output json` 獲取更易於解析的結構化輸出。
- 臨時伺服器 (HTTP URL 或 `--stdio` 命令) 無需任何配置即可工作 —— 適用於單次調用。
- OAuth 驗證可能需要交互式的瀏覽器流程 —— 如有需要，請使用 `terminal(command="mcporter auth <server>", pty=true)`。
