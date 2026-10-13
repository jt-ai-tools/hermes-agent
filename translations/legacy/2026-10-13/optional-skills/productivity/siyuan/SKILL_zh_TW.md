---
name: siyuan
description: 思源筆記 (SiYuan Note) API，用於透過 curl 在自代管知識庫中搜尋、閱讀、建立及管理區塊和文件。
version: 1.0.0
author: FEUAZUR
license: MIT
metadata:
  hermes:
    tags: [SiYuan, Notes, Knowledge Base, PKM, API]
    related_skills: [obsidian, notion]
    homepage: https://github.com/siyuan-note/siyuan
prerequisites:
  env_vars: [SIYUAN_TOKEN]
  commands: [curl, jq]
required_environment_variables:
  - name: SIYUAN_TOKEN
    prompt: 思源 API 權杖 (Token)
    help: "思源桌面版應用程式中的 設定 > 關於"
  - name: SIYUAN_URL
    prompt: 思源實例 URL (預設為 http://127.0.0.1:6806)
    required_for: 遠端實例
---

# 思源筆記 API

透過 curl 使用 [思源](https://github.com/siyuan-note/siyuan) 核心 API，在自代管知識庫中搜尋、閱讀、建立、更新及刪除區塊和文件。不需要額外工具 —— 僅需 curl 和 API 權杖。

## 前置作業

1. 安裝並執行思源（桌面版或 Docker）
2. 取得您的 API 權杖：**設定 > 關於 > API 權杖**
3. 將其儲存至 `~/.hermes/.env`：
   ```
   SIYUAN_TOKEN=your_token_here
   SIYUAN_URL=http://127.0.0.1:6806
   ```
   若未設定，`SIYUAN_URL` 預設為 `http://127.0.0.1:6806`。

## API 基礎

所有思源 API 呼叫皆為 **帶有 JSON 內文的 POST**。每個請求遵循以下模式：

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/..." \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"param": "value"}'
```

回應為 JSON，結構如下：
```json
{"code": 0, "msg": "", "data": { ... }}
```
`code: 0` 表示成功。任何其他值皆為錯誤 —— 請檢查 `msg` 以取得詳細資訊。

**ID 格式：** 思源 ID 看起來像 `20210808180117-6v0mkxr`（14 位數時間戳記 + 7 個英數字元）。

## 快速參考

| 操作 | 端點 (Endpoint) |
|-----------|----------|
| 全文檢索 | `/api/search/fullTextSearchBlock` |
| SQL 查詢 | `/api/query/sql` |
| 讀取區塊 | `/api/block/getBlockKramdown` |
| 讀取子區塊 | `/api/block/getChildBlocks` |
| 取得路徑 | `/api/filetree/getHPathByID` |
| 取得屬性 | `/api/attr/getBlockAttrs` |
| 列出筆記本 | `/api/notebook/lsNotebooks` |
| 列出文件 | `/api/filetree/listDocsByPath` |
| 建立筆記本 | `/api/notebook/createNotebook` |
| 建立文件 | `/api/filetree/createDocWithMd` |
| 附加區塊 | `/api/block/appendBlock` |
| 更新區塊 | `/api/block/updateBlock` |
| 重新命名文件 | `/api/filetree/renameDocByID` |
| 設定屬性 | `/api/attr/setBlockAttrs` |
| 刪除區塊 | `/api/block/deleteBlock` |
| 刪除文件 | `/api/filetree/removeDocByID` |
| 匯出為 Markdown | `/api/export/exportMdContent` |

## 常見操作

### 搜尋（全文檢索）

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/search/fullTextSearchBlock" \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "會議記錄", "page": 0}' | jq '.data.blocks[:5]'
```

### 搜尋（SQL）

直接查詢區塊資料庫。僅 SELECT 語句是安全的。

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/query/sql" \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"stmt": "SELECT id, content, type, box FROM blocks WHERE content LIKE '\''%關鍵字%'\'' AND type='\''p'\'' LIMIT 20"}' | jq '.data'
```

有用的欄位：`id`, `parent_id`, `root_id`, `box`（筆記本 ID）, `path`, `content`, `type`, `subtype`, `created`, `updated`。

### 讀取區塊內容

以 Kramdown（類似 Markdown）格式回傳區塊內容。

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/block/getBlockKramdown" \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"id": "20210808180117-6v0mkxr"}' | jq '.data.kramdown'
```

### 讀取子區塊

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/block/getChildBlocks" \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"id": "20210808180117-6v0mkxr"}' | jq '.data'
```

### 取得人類可讀路徑

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/filetree/getHPathByID" \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"id": "20210808180117-6v0mkxr"}' | jq '.data'
```

### 取得區塊屬性

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/attr/getBlockAttrs" \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"id": "20210808180117-6v0mkxr"}' | jq '.data'
```

### 列出筆記本

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/notebook/lsNotebooks" \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}' | jq '.data.notebooks[] | {id, name, closed}'
```

### 列出筆記本中的文件

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/filetree/listDocsByPath" \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"notebook": "NOTEBOOK_ID", "path": "/"}' | jq '.data.files[] | {id, name}'
```

### 建立文件

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/filetree/createDocWithMd" \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "notebook": "NOTEBOOK_ID",
    "path": "/Meeting Notes/2026-03-22",
    "markdown": "# 會議記錄\n\n- 討論了專案時程\n- 分派了任務"
  }' | jq '.data'
```

### 建立筆記本

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/notebook/createNotebook" \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "我的新筆記本"}' | jq '.data.notebook.id'
```

### 附加區塊至文件

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/block/appendBlock" \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "parentID": "DOCUMENT_OR_BLOCK_ID",
    "data": "在末尾新增的新段落。",
    "dataType": "markdown"
  }' | jq '.data'
```

同樣可用的還有：`/api/block/prependBlock`（相同參數，插入於開頭）以及 `/api/block/insertBlock`（使用 `previousID` 取代 `parentID` 以在特定區塊後插入）。

### 更新區塊內容

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/block/updateBlock" \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "BLOCK_ID",
    "data": "此處為更新後的內容。",
    "dataType": "markdown"
  }' | jq '.data'
```

### 重新命名文件

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/filetree/renameDocByID" \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"id": "DOCUMENT_ID", "title": "新標題"}'
```

### 設定區塊屬性

自定義屬性必須以 `custom-` 為前綴：

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/attr/setBlockAttrs" \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "BLOCK_ID",
    "attrs": {
      "custom-status": "reviewed",
      "custom-priority": "high"
    }
  }'
```

### 刪除區塊

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/block/deleteBlock" \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"id": "BLOCK_ID"}'
```

刪除整個文件：使用 `/api/filetree/removeDocByID` 配合 `{"id": "DOC_ID"}`。
刪除筆記本：使用 `/api/notebook/removeNotebook` 配合 `{"notebook": "NOTEBOOK_ID"}`。

### 匯出文件為 Markdown

```bash
curl -s -X POST "${SIYUAN_URL:-http://127.0.0.1:6806}/api/export/exportMdContent" \
  -H "Authorization: Token $SIYUAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"id": "DOCUMENT_ID"}' | jq -r '.data.content'
```

## 區塊類型

SQL 查詢中常見的 `type` 值：

| 類型 | 說明 |
|------|-------------|
| `d` | 文件 (根區塊) |
| `p` | 段落 |
| `h` | 標題 |
| `l` | 列表 |
| `i` | 列表項目 |
| `c` | 程式碼區塊 |
| `m` | 數學公式區塊 |
| `t` | 表格 |
| `b` | 引用區塊 |
| `s` | 超級區塊 (Super block) |
| `html` | HTML 區塊 |

## 陷阱

- **所有端點皆為 POST** —— 即使是唯讀操作。請勿使用 GET。
- **SQL 安全**：僅使用 SELECT 查詢。INSERT/UPDATE/DELETE/DROP 是危險的，絕不應發送。
- **ID 驗證**：ID 符合 `YYYYMMDDHHmmss-xxxxxxx` 模式。拒絕任何其他格式。
- **錯誤回應**：在處理 `data` 之前，務必檢查回應中的 `code != 0`。
- **大型文件**：區塊內容和匯出結果可能非常大。在 SQL 中使用 `LIMIT` 並透過 `jq` 僅提取您需要的內容。
- **筆記本 ID**：處理特定筆記本時，先透過 `lsNotebooks` 取得其 ID。

## 替代方案：MCP 伺服器

如果您偏好原生整合而非 curl，請安裝思源 MCP 伺服器：

```yaml
# 在 ~/.hermes/config.yaml 的 mcp_servers 下：
mcp_servers:
  siyuan:
    command: npx
    args: ["-y", "@porkll/siyuan-mcp"]
    env:
      SIYUAN_TOKEN: "your_token"
      SIYUAN_URL: "http://127.0.0.1:6806"
```
