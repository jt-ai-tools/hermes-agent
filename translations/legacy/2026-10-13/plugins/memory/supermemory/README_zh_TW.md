# Supermemory 記憶體供應商

具備個人檔案回想 (profile recall)、語義搜尋、明確記憶工具及會話結束對話攝入功能的語義長期記憶體。

## 系統需求

- `pip install supermemory`
- 來自 [supermemory.ai](https://supermemory.ai) 的 Supermemory API key

## 安裝設定

```bash
hermes memory setup    # 選擇 "supermemory"
```

或手動設定：

```bash
hermes config set memory.provider supermemory
echo 'SUPERMEMORY_API_KEY=***' >> ~/.hermes/.env
```

## 設定 (Config)

設定檔路徑：`$HERMES_HOME/supermemory.json`

| 鍵值 (Key) | 預設值 | 說明 |
|-----|---------|-------------|
| `container_tag` | `hermes` | 用於搜尋和寫入的容器標籤。支援 `{identity}` 模板，用於 Profile 作用域的標籤 (例如 `hermes-{identity}` → `hermes-coder`)。 |
| `auto_recall` | `true` | 在每輪對話前注入相關的記憶上下文 |
| `auto_capture` | `true` | 在每次回應後儲存清理後的使用者-代理對話輪次 |
| `max_recall_results` | `10` | 格式化到上下文中的最大回想項目數 |
| `profile_frequency` | `50` | 在第一輪和每 N 輪包含個人檔案事實 (profile facts) |
| `capture_mode` | `all` | 預設跳過極小或瑣碎的對話輪次 |
| `search_mode` | `hybrid` | 搜尋模式：`hybrid` (個人檔案 + 記憶), `memories` (僅記憶), `documents` (僅文件) |
| `entity_context` | 內建預設值 | 傳遞給 Supermemory 的提取指引 |
| `api_timeout` | `5.0` | SDK 和攝入 (ingest) 請求的逾時時間 |

### 環境變數

| 變數 | 說明 |
|----------|-------------|
| `SUPERMEMORY_API_KEY` | API key (必填) |
| `SUPERMEMORY_CONTAINER_TAG` | 覆蓋容器標籤 (優先級高於設定檔) |

## 工具 (Tools)

| 工具 | 說明 |
|------|-------------|
| `supermemory_store` | 儲存一條明確的記憶 |
| `supermemory_search` | 透過語義相似度搜尋記憶 |
| `supermemory_forget` | 透過 ID 或最佳比對查詢刪除記憶 |
| `supermemory_profile` | 擷取持久性個人檔案及近期上下文 |

## 行為 (Behavior)

啟用後，Hermes 可以：

- 在每輪對話前預取相關記憶上下文
- 在每次回應完成後儲存清理後的對話輪次
- 在會話結束時攝入完整對話，以進行更豐富的圖譜更新
- 開放用於搜尋、儲存、刪除和個人檔案存取的明確工具

## Profile 作用域容器 (Profile-Scoped Containers)

在 `container_tag` 中使用 `{identity}` 來依 Hermes profile 隔離記憶：

```json
{
  "container_tag": "hermes-{identity}"
}
```

對於名為 `coder` 的 profile，這會解析為 `hermes-coder`。預設 profile 則解析為 `hermes-default`。若不含 `{identity}`，所有 profile 將共用同一個容器。

## 多容器模式 (Multi-Container Mode)

對於進階設定 (例如 OpenClaw 風格的多工作區)，您可以啟用自訂容器標籤，讓代理能跨多個命名容器進行讀寫：

```json
{
  "container_tag": "hermes",
  "enable_custom_container_tags": true,
  "custom_containers": ["project-alpha", "project-beta", "shared-knowledge"],
  "custom_container_instructions": "對於開發任務使用 project-alpha，對於研究使用 project-beta，對於團隊共享事實使用 shared-knowledge。"
}
```

啟用後：
- `supermemory_search`, `supermemory_store`, `supermemory_forget`, 和 `supermemory_profile` 會接受一個選用的 `container_tag` 參數
- 標籤必須在白名單內：主容器 + `custom_containers`
- 自動化操作 (輪次同步、預取、記憶寫入鏡像、會話攝入) 始終僅使用**主容器**
- 自訂容器指令會被注入到系統提示詞中

## 支援 (Support)

- [Supermemory Discord](https://supermemory.link/discord)
- [support@supermemory.com](mailto:support@supermemory.com)
- [supermemory.ai](https://supermemory.ai)
