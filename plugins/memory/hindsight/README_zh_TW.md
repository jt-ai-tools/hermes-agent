# Hindsight 記憶體供應商

具備知識圖譜、實體解析及多策略檢索功能的長期記憶體。支援雲端 (Cloud)、本地嵌入式 (Local Embedded) 及本地外部 (Local External) 模式。

## 系統需求

- **Cloud:** 來自 [ui.hindsight.vectorize.io](https://ui.hindsight.vectorize.io) 的 API key
- **Local Embedded:** 支援的 LLM 供應商 API key (OpenAI, Anthropic, Gemini, Groq, OpenRouter, MiniMax, Ollama, 或任何 OpenAI 相容的端點)。Embeddings 和 Reranking 會在本地執行 —— 不需要額外的 API key。
- **Local External:** 一個正在執行的 Hindsight 實例 (Docker 或自行託管)，可透過 HTTP 連接。

## 安裝設定

```bash
hermes memory setup    # 選擇 "hindsight"
```

設定精靈會自動透過 `uv` 安裝依賴項，並引導您完成設定。

或手動設定 (預設的雲端模式)：
```bash
hermes config set memory.provider hindsight
echo "HINDSIGHT_API_KEY=your-key" >> ~/.hermes/.env
```

### Cloud

連接到 Hindsight Cloud API。需要來自 [ui.hindsight.vectorize.io](https://ui.hindsight.vectorize.io) 的 API key。

### Local Embedded

Hermes 會啟動一個帶有內建 PostgreSQL 的本地 Hindsight daemon。需要一個 LLM API key 用於記憶提取 (extraction) 和綜合 (synthesis)。Daemon 會在第一次使用時自動於背景啟動，並在閒置 5 分鐘後停止。

支援任何 OpenAI 相容的 LLM 端點 (llama.cpp, vLLM, LM Studio 等) —— 選擇 `openai_compatible` 作為供應商並輸入 base URL。

Daemon 啟動日誌：`~/.hermes/logs/hindsight-embed.log`
Daemon 執行日誌：`~/.hindsight/profiles/<profile>.log`

若要開啟 Hindsight web UI (僅限本地嵌入模式)：
```bash
hindsight-embed -p hermes ui start
```

### Local External

將外掛程式指向您已經在執行的現有 Hindsight 實例 (Docker, 自行託管等)。無需 daemon 管理 —— 只需要一個 URL 和一個選用的 API key。

## 設定 (Config)

設定檔路徑：`~/.hermes/hindsight/config.json`

### 連接 (Connection)

| 鍵值 (Key) | 預設值 | 說明 |
|-----|---------|-------------|
| `mode` | `cloud` | `cloud`, `local_embedded`, 或 `local_external` |
| `api_url` | `https://api.hindsight.vectorize.io` | API URL (雲端和 local_external 模式) |

### 記憶庫 (Memory Bank)

| 鍵值 (Key) | 預設值 | 說明 |
|-----|---------|-------------|
| `bank_id` | `hermes` | 記憶庫名稱 |
| `bank_mission` | — | Reflect mission (用於 reflect 推理的身分/框架)。透過 Banks API 套用。 |
| `bank_retain_mission` | — | Retain mission (引導提取的內容)。透過 Banks API 套用。 |

### 回想 (Recall)

| 鍵值 (Key) | 預設值 | 說明 |
|-----|---------|-------------|
| `recall_budget` | `mid` | 回想徹底程度：`low` / `mid` / `high` |
| `recall_prefetch_method` | `recall` | 自動回想方法：`recall` (原始事實) 或 `reflect` (LLM 綜合) |
| `recall_max_tokens` | `4096` | 回想結果的最大 tokens 數 |
| `recall_max_input_chars` | `800` | 自動回想的最大輸入查詢長度 |
| `recall_prompt_preamble` | — | 上下文中回想記憶的自訂前導文字 |
| `recall_tags` | — | 搜尋記憶時用於過濾的標籤 |
| `recall_tags_match` | `any` | 標籤比對模式：`any` / `all` / `any_strict` / `all_strict` |
| `auto_recall` | `true` | 在每輪對話前自動回想記憶 |

### 保留 (Retain)

| 鍵值 (Key) | 預設值 | 說明 |
|-----|---------|-------------|
| `auto_retain` | `true` | 自動保留對話輪次 |
| `retain_async` | `true` | 在 Hindsight 伺服器上非同步處理保留 (retain) |
| `retain_every_n_turns` | `1` | 每 N 輪保留一次 (1 = 每輪都保留) |
| `retain_context` | `conversation between Hermes Agent and the User` | 保留記憶的上下文標籤 |
| `tags` | — | 儲存記憶時套用的標籤 |

### 整合 (Integration)

| 鍵值 (Key) | 預設值 | 說明 |
|-----|---------|-------------|
| `memory_mode` | `hybrid` | 記憶如何整合到代理 (agent) 中 |

**memory_mode:**
- `hybrid` — 自動上下文注入 + LLM 可用的工具
- `context` — 僅自動注入，不開放工具
- `tools` — 僅工具，不進行自動注入

### 本地嵌入式 LLM (Local Embedded LLM)

| 鍵值 (Key) | 預設值 | 說明 |
|-----|---------|-------------|
| `llm_provider` | `openai` | `openai`, `anthropic`, `gemini`, `groq`, `openrouter`, `minimax`, `ollama`, `lmstudio`, `openai_compatible` |
| `llm_model` | 依供應商而定 | 模型名稱 (例如 `gpt-4o-mini`, `qwen/qwen3.5-9b`) |
| `llm_base_url` | — | `openai_compatible` 的端點 URL (例如 `http://192.168.1.10:8080/v1`) |

LLM API key 儲存在 `~/.hermes/.env` 中的 `HINDSIGHT_LLM_API_KEY`。

## 工具 (Tools)

可用於 `hybrid` 和 `tools` 記憶模式：

| 工具 | 說明 |
|------|-------------|
| `hindsight_retain` | 儲存資訊並自動進行實體提取 |
| `hindsight_recall` | 多策略搜尋 (語義 + 實體圖譜) |
| `hindsight_reflect` | 跨記憶綜合 (由 LLM 驅動) |

## 環境變數

| 變數 | 說明 |
|----------|-------------|
| `HINDSIGHT_API_KEY` | Hindsight Cloud 的 API key |
| `HINDSIGHT_LLM_API_KEY` | 本地模式的 LLM API key |
| `HINDSIGHT_API_LLM_BASE_URL` | 本地模式的 LLM Base URL (例如 OpenRouter) |
| `HINDSIGHT_API_URL` | 覆蓋 API 端點 |
| `HINDSIGHT_BANK_ID` | 覆蓋記憶庫名稱 |
| `HINDSIGHT_BUDGET` | 覆蓋回想預算 (recall budget) |
| `HINDSIGHT_MODE` | 覆蓋模式 (`cloud`, `local_embedded`, `local_external`) |

## 用戶端版本 (Client Version)

需要 `hindsight-client >= 0.4.22`。如果偵測到舊版本，外掛程式會在對話開始時自動升級。
