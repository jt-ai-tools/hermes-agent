# ByteRover 記憶體供應商

透過 `brv` CLI 提供的持久性記憶體 —— 具備分層檢索功能 (模糊文字 → LLM 驅動搜尋) 的階層式知識樹。

## 系統需求

安裝 ByteRover CLI：
```bash
curl -fsSL https://byterover.dev/install.sh | sh
# 或
npm install -g byterover-cli
```

## 安裝設定

```bash
hermes memory setup    # 選擇 "byterover"
```

或手動設定：
```bash
hermes config set memory.provider byterover
# 選用的雲端同步：
echo "BRV_API_KEY=your-key" >> ~/.hermes/.env
```

## 設定 (Config)

| 環境變數 | 是否必填 | 說明 |
|---------|----------|-------------|
| `BRV_API_KEY` | 否 | 雲端同步金鑰 (選用，預設為本地優先) |

工作目錄：`$HERMES_HOME/byterover/` (依 Profile 隔離)。

## 工具 (Tools)

| 工具 | 說明 |
|------|-------------|
| `brv_query` | 搜尋知識樹 |
| `brv_curate` | 儲存事實、決策與模式 |
| `brv_status` | CLI 版本、知識樹統計、同步狀態 |
