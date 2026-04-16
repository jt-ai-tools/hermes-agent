---
name: fastmcp
description: 使用 Python 的 FastMCP 建置、測試、檢查、安裝及佈署 MCP 伺服器。在建立新的 MCP 伺服器、將 API 或資料庫封裝為 MCP 工具、公開資源或提示詞，或為 Claude Code、Cursor 或 HTTP 佈署準備 FastMCP 伺服器時使用。
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [MCP, FastMCP, Python, 工具, 資源, 提示詞, 佈署]
    homepage: https://gofastmcp.com
    related_skills: [native-mcp, mcporter]
prerequisites:
  commands: [python3]
---

# FastMCP

使用 Python 的 FastMCP 建置 MCP 伺服器、在本地驗證、將其安裝到 MCP 客戶端，並將其佈署為 HTTP 端點。

## 何時使用

當任務為以下內容時，請使用此技能：

- 使用 Python 建立新的 MCP 伺服器
- 將 API、資料庫、CLI 或檔案處理工作流封裝為 MCP 工具
- 除了工具之外，還公開資源或提示詞
- 在將伺服器接入 Hermes 或其他客戶端之前，使用 FastMCP CLI 進行冒煙測試 (smoke-test)
- 將伺服器安裝到 Claude Code、Claude Desktop、Cursor 或類似的 MCP 客戶端
- 為 HTTP 佈署準備 FastMCP 伺服器儲存庫

當伺服器已存在且僅需要連接到 Hermes 時，請使用 `native-mcp`。當目標是臨時透過 CLI 存取現有 MCP 伺服器而非建置一個時，請使用 `mcporter`。

## 先決條件

先在工作環境中安裝 FastMCP：

```bash
pip install fastmcp
fastmcp version
```

對於 API 範本，如果尚未安裝 `httpx`，請進行安裝：

```bash
pip install httpx
```

## 包含的檔案

### 範本 (Templates)

- `templates/api_wrapper.py` - 具有驗證標頭支援的 REST API 封裝程式
- `templates/database_server.py` - 唯讀的 SQLite 查詢伺服器
- `templates/file_processor.py` - 文字檔案檢查與搜尋伺服器

### 指令稿 (Scripts)

- `scripts/scaffold_fastmcp.py` - 複製入門範本並替換伺服器名稱佔位符

### 參考資料 (References)

- `references/fastmcp-cli.md` - FastMCP CLI 工作流、安裝目標與佈署檢查

## 工作流程

### 1. 選擇最小可行伺服器形態

優先選擇最窄但實用的服務範圍：

- API 封裝：從 1-3 個高價值端點開始，而非整個 API。
- 資料庫伺服器：公開唯讀的內省 (introspection) 和受限的查詢路徑。
- 檔案處理器：公開具有明確路徑參數的確定性操作。
- 提示詞/資源：僅在客戶端需要可重複使用的提示詞範本或可探索的檔案時才加入。

優先考慮名稱、文件字串 (docstrings) 和架構定義良好的輕量化伺服器，而非具有模糊工具的大型伺服器。

### 2. 從範本建構

直接複製範本或使用建構輔助程式：

```bash
python ~/.hermes/skills/mcp/fastmcp/scripts/scaffold_fastmcp.py \
  --template api_wrapper \
  --name "Acme API" \
  --output ./acme_server.py
```

可用範本：

```bash
python ~/.hermes/skills/mcp/fastmcp/scripts/scaffold_fastmcp.py --list
```

如果是手動複製，請將 `__SERVER_NAME__` 替換為真實的伺服器名稱。

### 3. 先實作工具

在加入資源或提示詞之前，先從 `@mcp.tool` 函數開始。

工具設計規則：

- 為每個工具提供具備具體動詞的名稱。
- 將文件字串編寫為面向使用者的工具描述。
- 保持參數明確且帶有類型定義。
- 盡可能返回結構化的 JSON 安全資料。
- 儘早驗證不安全的輸入。
- 第一個版本預設採用唯讀行為。

良好的工具範例：

- `get_customer`
- `search_tickets`
- `describe_table`
- `summarize_text_file`

較差的工具範例：

- `run`
- `process`
- `do_thing`

### 4. 僅在有幫助時加入資源和提示詞

當客戶端能從獲取穩定的唯讀內容（如架構、政策文件或產生的報告）中獲益時，加入 `@mcp.resource`。

當伺服器應為已知工作流提供可重複使用的提示詞範本時，加入 `@mcp.prompt`。

不要將每個文件都變成提示詞。建議：

- 工具用於動作。
- 資源用於資料/文件檢索。
- 提示詞用於可重複使用的 LLM 指令。

### 5. 在整合前測試伺服器

使用 FastMCP CLI 進行本地驗證：

```bash
fastmcp inspect acme_server.py:mcp
fastmcp list acme_server.py --json
fastmcp call acme_server.py search_resources query=router limit=5 --json
```

為了快速迭代除錯，請在本地執行伺服器：

```bash
fastmcp run acme_server.py:mcp
```

要在本地測試 HTTP 傳輸：

```bash
fastmcp run acme_server.py:mcp --transport http --host 127.0.0.1 --port 8000
fastmcp list http://127.0.0.1:8000/mcp --json
fastmcp call http://127.0.0.1:8000/mcp search_resources query=router --json
```

在宣稱伺服器可用之前，務必針對每個新工具執行至少一次真實的 `fastmcp call`。

### 6. 在本地驗證通過後安裝到客戶端

FastMCP 可以將伺服器註冊到受支援的 MCP 客戶端：

```bash
fastmcp install claude-code acme_server.py
fastmcp install claude-desktop acme_server.py
fastmcp install cursor acme_server.py -e .
```

使用 `fastmcp discover` 檢查機器上已設定的具名 MCP 伺服器。

當目標是 Hermes 整合時，請：

- 使用 `native-mcp` 技能在 `~/.hermes/config.yaml` 中設定伺服器，或
- 在開發期間繼續使用 FastMCP CLI 命令，直到介面穩定為止。

### 7. 在本地契約穩定後進行佈署

對於託管服務，Prefect Horizon 是 FastMCP 最直接推薦的路徑。佈署前：

```bash
fastmcp inspect acme_server.py:mcp
```

確保儲存庫包含：

- 帶有 FastMCP 伺服器物件的 Python 檔案。
- `requirements.txt` 或 `pyproject.toml`。
- 佈署所需的任何環境變數文件。

對於通用的 HTTP 託管，請先在本地驗證 HTTP 傳輸，然後佈署到任何可公開伺服器連接埠且與 Python 相容的平台。

## 常見模式

### API 封裝模式

當將 REST 或 HTTP API 公開為 MCP 工具時使用。

推薦的首個切片：

- 一個讀取路徑。
- 一個列表/搜尋路徑。
- 選用的健康檢查。

實作筆記：

- 將驗證資訊保留在環境變數中，而非寫死。
- 將請求邏輯集中在一個輔助程式中。
- 以簡潔的背景資訊呈現 API 錯誤。
- 在返回不一致的上游負載之前對其進行正規化。

從 `templates/api_wrapper.py` 開始。

### 資料庫模式

當公開安全的查詢與檢查功能時使用。

推薦的首個切片：

- `list_tables`
- `describe_table`
- 一個受限的讀取查詢工具。

實作筆記：

- 預設為唯讀資料庫存取。
- 在早期版本中拒絕非 `SELECT` 的 SQL。
- 限制行數。
- 返回行資料以及欄位名稱。

從 `templates/database_server.py` 開始。

### 檔案處理器模式

當伺服器需要按需檢查或轉換檔案時使用。

推薦的首個切片：

- 總結檔案內容。
- 在檔案中進行搜尋。
- 擷取確定性的元資料。

實作筆記：

- 接受明確的檔案路徑。
- 檢查檔案缺失與編碼失敗的情況。
- 限制預覽和結果計數。
- 除非需要特定的外部工具，否則避免執行外部 Shell 命令。

從 `templates/file_processor.py` 開始。

## 品質標準

在交付 FastMCP 伺服器之前，請驗證以下所有項：

- 伺服器能乾淨地匯入。
- `fastmcp inspect <file.py:mcp>` 成功執行。
- `fastmcp list <server spec> --json` 成功執行。
- 每個新工具都至少經過一次真實的 `fastmcp call`。
- 環境變數已記錄。
- 工具範圍足夠精簡，無需猜測即可理解。

## 疑難排解

### FastMCP 命令缺失

在作用中的環境中安裝套件：

```bash
pip install fastmcp
fastmcp version
```

### `fastmcp inspect` 失敗

檢查以下項：

- 檔案在匯入時沒有導致崩潰的副作用。
- 在 `<file.py:object>` 中 FastMCP 實例的命名正確。
- 已安裝範本中的選用依賴項。

### 工具在 Python 中可用，但在 CLI 中不可用

執行：

```bash
fastmcp list server.py --json
fastmcp call server.py your_tool_name --json
```

這通常會暴露出命名不匹配、缺失必要引數或非序列化回傳值的問題。

### Hermes 看不到已佈署的伺服器

伺服器建置部分可能是正確的，但 Hermes 設定有誤。載入 `native-mcp` 技能並在 `~/.hermes/config.yaml` 中設定伺服器，然後重啟 Hermes。

## 參考資料

如需 CLI 細節、安裝目標與佈署檢查，請參閱 `references/fastmcp-cli.md`。
