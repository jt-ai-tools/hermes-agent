# RetainDB 記憶體供應商

具備混合搜尋 (Vector + BM25 + Reranking) 功能及 7 種記憶類型的雲端記憶體 API。

## 系統需求

- RetainDB 帳號 (每月 20 美元)，來自 [retaindb.com](https://www.retaindb.com)
- `pip install requests`

## 安裝設定

```bash
hermes memory setup    # 選擇 "retaindb"
```

或手動設定：
```bash
hermes config set memory.provider retaindb
echo "RETAINDB_API_KEY=your-key" >> ~/.hermes/.env
```

## 設定 (Config)

所有設定均透過 `.env` 中的環境變數進行：

| 環境變數 | 預設值 | 說明 |
|---------|---------|-------------|
| `RETAINDB_API_KEY` | (必填) | API key |
| `RETAINDB_BASE_URL` | `https://api.retaindb.com` | API 端點 (endpoint) |
| `RETAINDB_PROJECT` | 自動 (依 profile 隔離) | 專案識別碼 |

## 工具 (Tools)

| 工具 | 說明 |
|------|-------------|
| `retaindb_profile` | 使用者的穩定個人檔案 (stable profile) |
| `retaindb_search` | 語義搜尋 |
| `retaindb_context` | 與任務相關的上下文 |
| `retaindb_remember` | 儲存一條包含類型 + 重要性的事實 |
| `retaindb_forget` | 透過 ID 刪除記憶 |
