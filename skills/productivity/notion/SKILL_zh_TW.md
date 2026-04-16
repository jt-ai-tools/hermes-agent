---
name: notion
description: Notion API 用於透過 curl 建立及管理頁面、資料庫和區塊。直接從終端機搜尋、建立、更新及查詢 Notion 工作區。
version: 1.0.0
author: community
license: MIT
metadata:
  hermes:
    tags: [Notion, Productivity, Notes, Database, API]
    homepage: https://developers.notion.com
prerequisites:
  env_vars: [NOTION_API_KEY]
---

# Notion API

透過 curl 使用 Notion API 來建立、讀取、更新頁面、資料庫 (資料來源) 和區塊。無需額外工具 — 僅需 curl 和 Notion API 金鑰。

## 前置要求

1. 在 https://notion.so/my-integrations 建立一個整合 (integration)
2. 複製 API 金鑰 (以 `ntn_` 或 `secret_` 開頭)
3. 將其儲存在 `~/.hermes/.env` 中：
   ```
   NOTION_API_KEY=ntn_your_key_here
   ```
4. **重要事項：** 在 Notion 中將目標頁面/資料庫分享給您的整合 (點擊 "..." → "Connect to" → 您的整合名稱)

## API 基礎知識

所有請求皆使用此模式：

```bash
curl -s -X GET "https://api.notion.com/v1/..." \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2025-09-03" \
  -H "Content-Type: application/json"
```

必須包含 `Notion-Version` 標頭。此技能使用 `2025-09-03` (最新版本)。在此版本中，資料庫在 API 中被稱為「資料來源 (data sources)」。

## 常見操作

### 搜尋 (Search)

```bash
curl -s -X POST "https://api.notion.com/v1/search" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2025-09-03" \
  -H "Content-Type: application/json" \
  -d '{"query": "page title"}'
```

### 取得頁面 (Get Page)

```bash
curl -s "https://api.notion.com/v1/pages/{page_id}" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2025-09-03"
```

### 取得頁面內容 (區塊 blocks)

```bash
curl -s "https://api.notion.com/v1/blocks/{page_id}/children" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2025-09-03"
```

### 在資料庫中建立頁面

```bash
curl -s -X POST "https://api.notion.com/v1/pages" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2025-09-03" \
  -H "Content-Type: application/json" \
  -d '{
    "parent": {"database_id": "xxx"},
    "properties": {
      "Name": {"title": [{"text": {"content": "New Item"}}]},
      "Status": {"select": {"name": "Todo"}}
    }
  }'
```

### 查詢資料庫

```bash
curl -s -X POST "https://api.notion.com/v1/data_sources/{data_source_id}/query" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2025-09-03" \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {"property": "Status", "select": {"equals": "Active"}},
    "sorts": [{"property": "Date", "direction": "descending"}]
  }'
```

### 建立資料庫

```bash
curl -s -X POST "https://api.notion.com/v1/data_sources" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2025-09-03" \
  -H "Content-Type: application/json" \
  -d '{
    "parent": {"page_id": "xxx"},
    "title": [{"text": {"content": "My Database"}}],
    "properties": {
      "Name": {"title": {}},
      "Status": {"select": {"options": [{"name": "Todo"}, {"name": "Done"}]}},
      "Date": {"date": {}}
    }
  }'
```

### 更新頁面屬性

```bash
curl -s -X PATCH "https://api.notion.com/v1/pages/{page_id}" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2025-09-03" \
  -H "Content-Type: application/json" \
  -d '{"properties": {"Status": {"select": {"name": "Done"}}}}'
```

### 新增內容至頁面

```bash
curl -s -X PATCH "https://api.notion.com/v1/blocks/{page_id}/children" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2025-09-03" \
  -H "Content-Type: application/json" \
  -d '{
    "children": [
      {"object": "block", "type": "paragraph", "paragraph": {"rich_text": [{"text": {"content": "Hello from Hermes!"}}]}}
    ]
  }'
```

## 屬性類型 (Property Types)

資料庫項目的常見屬性格式：

- **標題 (Title):** `{"title": [{"text": {"content": "..."}}]}`
- **富文本 (Rich text):** `{"rich_text": [{"text": {"content": "..."}}]}`
- **選取 (Select):** `{"select": {"name": "Option"}}`
- **多選 (Multi-select):** `{"multi_select": [{"name": "A"}, {"name": "B"}]}`
- **日期 (Date):** `{"date": {"start": "2026-01-15", "end": "2026-01-16"}}`
- **核取方塊 (Checkbox):** `{"checkbox": true}`
- **數字 (Number):** `{"number": 42}`
- **URL:** `{"url": "https://..."}`
- **電子郵件 (Email):** `{"email": "user@example.com"}`
- **關聯 (Relation):** `{"relation": [{"id": "page_id"}]}`

## API 版本 2025-09-03 的關鍵差異

- **資料庫 (Databases) → 資料來源 (Data Sources):** 使用 `/data_sources/` 端點進行查詢和擷取
- **兩個 ID:** 每個資料庫同時擁有 `database_id` 和 `data_source_id`
  - 建立頁面時使用 `database_id` (`parent: {"database_id": "..."}`)
  - 查詢時使用 `data_source_id` (`POST /v1/data_sources/{id}/query`)
- **搜尋結果:** 資料庫會以 `"object": "data_source"` 形式回傳，並包含其 `data_source_id`

## 注意事項

- 頁面/資料庫 ID 是 UUID (可包含或不包含連字號)
- 速率限制：平均每秒約 3 次請求
- API 無法設定資料庫檢視篩選器 — 該功能僅限 UI 操作
- 建立資料來源時使用 `is_inline: true` 可將其嵌入頁面
- 在 curl 指令中加入 `-s` 旗標以隱藏進度條 (讓 Hermes 的輸出更乾淨)
- 透過 `jq` 處理輸出以獲得易讀的 JSON：`... | jq '.results[0].properties'`
