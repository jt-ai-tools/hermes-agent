# 全像記憶供應商 (Holographic Memory Provider)

具備 FTS5 搜尋、信任評分、實體解析以及基於 HRR 的組合檢索功能之本地 SQLite 事實儲存空間。

## 需求

無 —— 使用 SQLite（始終可用）。NumPy 對於 HRR 代數計算為選用。

## 設定

```bash
hermes memory setup    # 選擇 "holographic"
```

或手動設定：
```bash
hermes config set memory.provider holographic
```

## 配置 (Config)

位於 `config.yaml` 中的 `plugins.hermes-memory-store` 底下：

| 鍵 (Key) | 預設值 | 描述 |
|-----|---------|-------------|
| `db_path` | `$HERMES_HOME/memory_store.db` | SQLite 資料庫路徑 |
| `auto_extract` | `false` | 在會話結束時自動擷取事實 |
| `default_trust` | `0.5` | 新事實的預設信任評分 |
| `hrr_dim` | `1024` | HRR 向量維度 |

## 工具

| 工具 | 描述 |
|------|-------------|
| `fact_store` | 9 種操作：add (新增), search (搜尋), probe (探測), related (相關), reason (推理), contradict (矛盾), update (更新), remove (移除), list (列表) |
| `fact_feedback` | 將事實評分為有幫助/無幫助（訓練信任評分） |
