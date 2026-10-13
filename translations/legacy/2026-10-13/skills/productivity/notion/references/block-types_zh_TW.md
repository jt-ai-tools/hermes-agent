# Notion 區塊類型 (Block Types)

透過 API 建立及讀取所有常見 Notion 區塊類期的參考指南。

## 建立區塊

使用 `PATCH /v1/blocks/{page_id}/children` 並帶入 `children` 陣列。每個區塊遵循此結構：

```json
{"object": "block", "type": "<type>", "<type>": { ... }}
```

### 段落 (Paragraph)

```json
{"type": "paragraph", "paragraph": {"rich_text": [{"text": {"content": "Hello world"}}]}}
```

### 標題 (Headings)

```json
{"type": "heading_1", "heading_1": {"rich_text": [{"text": {"content": "Title"}}]}}
{"type": "heading_2", "heading_2": {"rich_text": [{"text": {"content": "Section"}}]}}
{"type": "heading_3", "heading_3": {"rich_text": [{"text": {"content": "Subsection"}}]}}
```

### 項目符號清單 (Bulleted list)

```json
{"type": "bulleted_list_item", "bulleted_list_item": {"rich_text": [{"text": {"content": "Item"}}]}}
```

### 編號清單 (Numbered list)

```json
{"type": "numbered_list_item", "numbered_list_item": {"rich_text": [{"text": {"content": "Step 1"}}]}}
```

### 待辦事項 / 核取方塊 (To-do / checkbox)

```json
{"type": "to_do", "to_do": {"rich_text": [{"text": {"content": "Task"}}], "checked": false}}
```

### 引用 (Quote)

```json
{"type": "quote", "quote": {"rich_text": [{"text": {"content": "Something wise"}}]}}
```

### 標註 (Callout)

```json
{"type": "callout", "callout": {"rich_text": [{"text": {"content": "Important note"}}], "icon": {"emoji": "💡"}}}
```

### 程式碼 (Code)

```json
{"type": "code", "code": {"rich_text": [{"text": {"content": "print('hello')"}}], "language": "python"}}
```

### 折疊選單 (Toggle)

```json
{"type": "toggle", "toggle": {"rich_text": [{"text": {"content": "Click to expand"}}]}}
```

### 分隔線 (Divider)

```json
{"type": "divider", "divider": {}}
```

### 書籤 (Bookmark)

```json
{"type": "bookmark", "bookmark": {"url": "https://example.com"}}
```

### 圖片 (Image，外部 URL)

```json
{"type": "image", "image": {"type": "external", "external": {"url": "https://example.com/photo.png"}}}
```

## 讀取區塊

從 `GET /v1/blocks/{page_id}/children` 讀取區塊時，每個區塊都有一個 `type` 欄位。依下列方式擷取可讀文字：

| 類型 | 文字位置 | 額外欄位 |
|------|--------------|--------------|
| `paragraph` | `.paragraph.rich_text` | — |
| `heading_1/2/3` | `.heading_N.rich_text` | — |
| `bulleted_list_item` | `.bulleted_list_item.rich_text` | — |
| `numbered_list_item` | `.numbered_list_item.rich_text` | — |
| `to_do` | `.to_do.rich_text` | `.to_do.checked` (布林值) |
| `toggle` | `.toggle.rich_text` | 具有子區塊 |
| `code` | `.code.rich_text` | `.code.language` |
| `quote` | `.quote.rich_text` | — |
| `callout` | `.callout.rich_text` | `.callout.icon.emoji` |
| `divider` | — | — |
| `image` | `.image.caption` | `.image.file.url` 或 `.image.external.url` |
| `bookmark` | `.bookmark.caption` | `.bookmark.url` |
| `child_page` | — | `.child_page.title` |
| `child_database` | — | `.child_database.title` |

富文本陣列包含具有 `.plain_text` 的物件 — 將其串接即可獲得可讀輸出。

---

*貢獻者：[@dogiladeveloper](https://github.com/dogiladeveloper)*
