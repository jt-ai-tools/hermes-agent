# Mem0 記憶供應商 (Memory Provider)

具備語義搜尋、重排序 (Reranking) 與自動去重功能的伺服器端 LLM 事實擷取。

## 需求

- `pip install mem0ai`
- 來自 [app.mem0.ai](https://app.mem0.ai) 的 Mem0 API 金鑰

## 設定

```bash
hermes memory setup    # 選擇 "mem0"
```

或手動設定：
```bash
hermes config set memory.provider mem0
echo "MEM0_API_KEY=your-key" >> ~/.hermes/.env
```

## 配置 (Config)

配置檔案：`$HERMES_HOME/mem0.json`

| 鍵 (Key) | 預設值 | 描述 |
|-----|---------|-------------|
| `user_id` | `hermes-user` | Mem0 上的使用者識別碼 |
| `agent_id` | `hermes` | 代理程式識別碼 |
| `rerank` | `true` | 啟用召回時的重排序功能 |

## 工具

| 工具 | 描述 |
|------|-------------|
| `mem0_profile` | 所有已儲存的關於該使用者的記憶 |
| `mem0_search` | 具備選用重排序功能的語義搜尋 |
| `mem0_conclude` | 逐字儲存事實（不進行 LLM 擷取） |
