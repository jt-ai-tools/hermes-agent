# OpenViking 記憶體供應商

由火山引擎 (Volcengine, 字節跳動) 提供的上下文資料庫，具備檔案系統風格的知識階層、分層檢索及自動記憶提取功能。

## 系統需求

- `pip install openviking`
- OpenViking 伺服器正在執行 (`openviking-server`)
- 已在 `~/.openviking/ov.conf` 中設定 Embedding + VLM 模型

## 安裝設定

```bash
hermes memory setup    # 選擇 "openviking"
```

或手動設定：
```bash
hermes config set memory.provider openviking
echo "OPENVIKING_ENDPOINT=http://localhost:1933" >> ~/.hermes/.env
```

## 設定 (Config)

所有設定均透過 `.env` 中的環境變數進行：

| 環境變數 | 預設值 | 說明 |
|---------|---------|-------------|
| `OPENVIKING_ENDPOINT` | `http://127.0.0.1:1933` | 伺服器 URL |
| `OPENVIKING_API_KEY` | (無) | API key (選用) |

## 工具 (Tools)

| 工具 | 說明 |
|------|-------------|
| `viking_search` | 具備快速/深度/自動模式的語義搜尋 |
| `viking_read` | 讀取 viking:// URI 內容 (摘要/概覽/全文) |
| `viking_browse` | 檔案系統風格的導覽 (列表/樹狀/統計) |
| `viking_remember` | 儲存事實以供會話提交時提取 |
| `viking_add_resource` | 將 URL/文件攝入 (ingest) 知識庫 |
