# FastMCP CLI 參考指南

當工作需要精確的 FastMCP CLI 工作流而非 `SKILL.md` 中的高階指南時，請參考此文件。

## 安裝與驗證

```bash
pip install fastmcp
fastmcp version
```

FastMCP 官方文件將 `pip install fastmcp` 與 `fastmcp version` 列為基準安裝與驗證路徑。

## 執行伺服器

從 Python 文件執行伺服器物件：

```bash
fastmcp run server.py:mcp
```

透過 HTTP 執行相同的伺服器：

```bash
fastmcp run server.py:mcp --transport http --host 127.0.0.1 --port 8000
```

## 檢查伺服器

檢查 FastMCP 會公開哪些內容：

```bash
fastmcp inspect server.py:mcp
```

這也是 FastMCP 建議在部署到 Prefect Horizon 之前進行的檢查。

## 列出並呼叫工具

從 Python 文件列出工具：

```bash
fastmcp list server.py --json
```

從 HTTP 端點列出工具：

```bash
fastmcp list http://127.0.0.1:8000/mcp --json
```

使用鍵值對（key-value）參數呼叫工具：

```bash
fastmcp call server.py search_resources query=router limit=5 --json
```

使用完整 JSON 輸入負載（payload）呼叫工具：

```bash
fastmcp call server.py create_item '{"name": "Widget", "tags": ["sale"]}' --json
```

## 發現已命名的 MCP 伺服器

尋找已在本地支援 MCP 的工具中配置的命名伺服器：

```bash
fastmcp discover
```

FastMCP 支援針對 Claude Desktop、Claude Code、Cursor、Gemini、Goose 以及 `./mcp.json` 的基於名稱的解析。

## 安裝至 MCP 用戶端

在常用的用戶端中註冊伺服器：

```bash
fastmcp install claude-code server.py
fastmcp install claude-desktop server.py
fastmcp install cursor server.py -e .
```

FastMCP 提示用戶端安裝會在隔離環境中執行，因此在需要時請使用 `--with`、`--env-file` 或可編輯安裝等旗標明確聲明依賴項。

## 部署檢查

### Prefect Horizon

在推送到 Horizon 之前：

```bash
fastmcp inspect server.py:mcp
```

FastMCP 的 Horizon 文件要求：

- 一個 GitHub 儲存庫
- 一個包含 FastMCP 伺服器物件的 Python 文件
- 在 `requirements.txt` 或 `pyproject.toml` 中聲明的依賴項
- 一個進入點（entrypoint），例如 `main.py:mcp`

### 通用 HTTP 託管

在發布到任何其他主機之前：

1. 使用 HTTP 傳輸方式在本地啟動伺服器。
2. 針對本地 `/mcp` URL 驗證 `fastmcp list`。
3. 驗證至少一個 `fastmcp call`。
4. 記錄必要的環境變數。
