# 會話存儲 (Session Storage)

Hermes Agent 使用 SQLite 資料庫 (`~/.hermes/state.db`) 來跨 CLI 和閘道器 (gateway) 會話持久化存儲會話元數據 (metadata)、完整的訊息歷史和模型配置。這取代了早期為每個會話建立 JSONL 檔案的方法。

原始碼檔案：`hermes_state.py`


## 架構概覽

```
~/.hermes/state.db (SQLite, WAL 模式)
├── sessions          — 會話元數據、標記 (token) 計數、計費
├── messages          — 每個會話的完整訊息歷史
├── messages_fts      — 用於全文搜尋的 FTS5 虛擬表
└── schema_version    — 追蹤遷移狀態的單列資料表
```

關鍵設計決策：
- **WAL 模式** 支援併發讀取器 + 一個寫入器（適用於閘道器多平台）
- **FTS5 虛擬表** 支援跨所有會話訊息的快速文本搜尋
- **會話譜系 (Session lineage)** 透過 `parent_session_id` 鏈（由壓縮觸發的分割）實現
- **來源標記 (Source tagging)** (`cli`, `telegram`, `discord` 等）用於平台過濾
- Batch runner 和 RL 軌跡 (trajectories) 不存儲在此處（由獨立系統處理）


## SQLite 綱要 (Schema)

### Sessions 表

```sql
CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    source TEXT NOT NULL,
    user_id TEXT,
    model TEXT,
    model_config TEXT,
    system_prompt TEXT,
    parent_session_id TEXT,
    started_at REAL NOT NULL,
    ended_at REAL,
    end_reason TEXT,
    message_count INTEGER DEFAULT 0,
    tool_call_count INTEGER DEFAULT 0,
    input_tokens INTEGER DEFAULT 0,
    output_tokens INTEGER DEFAULT 0,
    cache_read_tokens INTEGER DEFAULT 0,
    cache_write_tokens INTEGER DEFAULT 0,
    reasoning_tokens INTEGER DEFAULT 0,
    billing_provider TEXT,
    billing_base_url TEXT,
    billing_mode TEXT,
    estimated_cost_usd REAL,
    actual_cost_usd REAL,
    cost_status TEXT,
    cost_source TEXT,
    pricing_version TEXT,
    title TEXT,
    FOREIGN KEY (parent_session_id) REFERENCES sessions(id)
);

CREATE INDEX IF NOT EXISTS idx_sessions_source ON sessions(source);
CREATE INDEX IF NOT EXISTS idx_sessions_parent ON sessions(parent_session_id);
CREATE INDEX IF NOT EXISTS idx_sessions_started ON sessions(started_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_sessions_title_unique
    ON sessions(title) WHERE title IS NOT NULL;
```

### Messages 表

```sql
CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id),
    role TEXT NOT NULL,
    content TEXT,
    tool_call_id TEXT,
    tool_calls TEXT,
    tool_name TEXT,
    timestamp REAL NOT NULL,
    token_count INTEGER,
    finish_reason TEXT,
    reasoning TEXT,
    reasoning_details TEXT,
    codex_reasoning_items TEXT
);

CREATE INDEX IF NOT EXISTS idx_messages_session ON messages(session_id, timestamp);
```

備註：
- `tool_calls` 以 JSON 字串形式存儲（序列化的工具呼叫物件列表）
- `reasoning_details` 和 `codex_reasoning_items` 以 JSON 字串形式存儲
- `reasoning` 存儲提供原始推理文本的供應商所提供的內容
- 時間戳記使用 Unix epoch 浮點數 (`time.time()`)

### FTS5 全文搜尋

```sql
CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts USING fts5(
    content,
    content=messages,
    content_rowid=id
);
```

FTS5 表透過三個在 `messages` 表進行 INSERT、UPDATE 和 DELETE 時觸發的觸發器 (triggers) 保持同步：

```sql
CREATE TRIGGER IF NOT EXISTS messages_fts_insert AFTER INSERT ON messages BEGIN
    INSERT INTO messages_fts(rowid, content) VALUES (new.id, new.content);
END;

CREATE TRIGGER IF NOT EXISTS messages_fts_delete AFTER DELETE ON messages BEGIN
    INSERT INTO messages_fts(messages_fts, rowid, content)
        VALUES('delete', old.id, old.content);
END;

CREATE TRIGGER IF NOT EXISTS messages_fts_update AFTER UPDATE ON messages BEGIN
    INSERT INTO messages_fts(messages_fts, rowid, content)
        VALUES('delete', old.id, old.content);
    INSERT INTO messages_fts(rowid, content) VALUES (new.id, new.content);
END;
```


## 綱要版本與遷移 (Schema Version and Migrations)

當前綱要版本：**6**

`schema_version` 表存儲一個整數。在初始化時，`_init_schema()` 會檢查當前版本並按順序執行遷移：

| 版本 | 變更 |
|---------|--------|
| 1 | 初始綱要 (sessions, messages, FTS5) |
| 2 | 在 messages 表添加 `finish_reason` 欄位 |
| 3 | 在 sessions 表添加 `title` 欄位 |
| 4 | 在 `title` 上添加唯一索引（允許 NULL，非 NULL 必須唯一） |
| 5 | 添加計費相關欄位：`cache_read_tokens`, `cache_write_tokens`, `reasoning_tokens`, `billing_provider`, `billing_base_url`, `billing_mode`, `estimated_cost_usd`, `actual_cost_usd`, `cost_status`, `cost_source`, `pricing_version` |
| 6 | 在 messages 表添加推理相關欄位：`reasoning`, `reasoning_details`, `codex_reasoning_items` |

每次遷移都使用包裹在 try/except 中的 `ALTER TABLE ADD COLUMN` 來處理欄位已存在的情況（冪等性）。每個成功的遷移區塊執行後，版本號都會增加。


## 寫入爭用處理 (Write Contention Handling)

多個 hermes 進程（閘道器 + CLI 會話 + 工作區代理）共用同一個 `state.db`。`SessionDB` 類別透過以下方式處理寫入爭用：

- **短 SQLite 逾時** (1 秒)，而非預設的 30 秒
- **應用程式層級重試**，帶有隨機抖動 (jitter)（20-150 毫秒，最多重試 15 次）
- **BEGIN IMMEDIATE** 交易，在交易開始時即呈現鎖定爭用
- **定期 WAL 檢查點**，每 50 次成功寫入後執行一次 (PASSIVE 模式)

這避免了「護送效應 (convoy effect)」，即 SQLite 確定性的內部退避會導致所有競爭的寫入器在相同的間隔重試。

```
_WRITE_MAX_RETRIES = 15
_WRITE_RETRY_MIN_S = 0.020   # 20 毫秒
_WRITE_RETRY_MAX_S = 0.150   # 150 毫秒
_CHECKPOINT_EVERY_N_WRITES = 50
```


## 常見操作

### 初始化

```python
from hermes_state import SessionDB

db = SessionDB()                           # 預設：~/.hermes/state.db
db = SessionDB(db_path=Path("/tmp/test.db"))  # 自定義路徑
```

### 建立與管理會話

```python
# 建立新會話
db.create_session(
    session_id="sess_abc123",
    source="cli",
    model="anthropic/claude-sonnet-4.6",
    user_id="user_1",
    parent_session_id=None,  # 或用於追蹤譜系的前一個會話 ID
)

# 結束會話
db.end_session("sess_abc123", end_reason="user_exit")

# 重新開啟會話 (清除 ended_at/end_reason)
db.reopen_session("sess_abc123")
```

### 存儲訊息

```python
msg_id = db.append_message(
    session_id="sess_abc123",
    role="assistant",
    content="這是答案...",
    tool_calls=[{"id": "call_1", "function": {"name": "terminal", "arguments": "{}"}}],
    token_count=150,
    finish_reason="stop",
    reasoning="讓我思考一下...",
)
```

### 檢索訊息

```python
# 包含所有元數據的原始訊息
messages = db.get_messages("sess_abc123")

# OpenAI 對話格式 (用於 API 重播)
conversation = db.get_messages_as_conversation("sess_abc123")
# 返回：[{"role": "user", "content": "..."}, {"role": "assistant", ...}]
```

### 會話標題

```python
# 設置標題 (在非 NULL 標題中必須唯一)
db.set_session_title("sess_abc123", "修復 Docker 構建")

# 根據標題解析 (返回譜系中最近的一個)
session_id = db.resolve_session_by_title("修復 Docker 構建")

# 自動產生譜系中的下一個標題
next_title = db.get_next_title_in_lineage("修復 Docker 構建")
# 返回："修復 Docker 構建 #2"
```


## 全文搜尋 (Full-Text Search)

`search_messages()` 方法支援 FTS5 查詢語法，並自動對使用者輸入進行淨化處理。

### 基本搜尋

```python
results = db.search_messages("docker deployment")
```

### FTS5 查詢語法

| 語法 | 範例 | 意義 |
|--------|---------|---------|
| 關鍵字 | `docker deployment` | 兩個詞 (隱式 AND) |
| 帶引號的片語 | `"exact phrase"` | 精確片語比對 |
| 布林 OR | `docker OR kubernetes` | 任一詞 |
| 布林 NOT | `python NOT java` | 排除該詞 |
| 前綴 | `deploy*` | 前綴比對 |

### 過濾搜尋

```python
# 僅搜尋 CLI 會話
results = db.search_messages("error", source_filter=["cli"])

# 排除閘道器會話
results = db.search_messages("bug", exclude_sources=["telegram", "discord"])

# 僅搜尋使用者訊息
results = db.search_messages("help", role_filter=["user"])
```

### 搜尋結果格式

每個結果包含：
- `id`, `session_id`, `role`, `timestamp`
- `snippet` — 由 FTS5 產生的片段，帶有 `>>>match<<<` 標記
- `context` — 比對項前後各 1 則訊息（內容截斷至 200 字元）
- `source`, `model`, `session_started` — 來自父級會話

`_sanitize_fts5_query()` 方法處理邊緣情況：
- 剝離未成對的引號和特殊字元
- 將帶連字號的詞用引號包裹 (`chat-send` → `"chat-send"`)
- 移除結尾的布林運算子 (`hello AND` → `hello`)


## 會話譜系 (Session Lineage)

會話可以透過 `parent_session_id` 形成鏈。這發生在閘道器中上下文壓縮觸發會話分割時。

### 查詢：尋找會話譜系

```sql
-- 尋找會話的所有祖先
WITH RECURSIVE lineage AS (
    SELECT * FROM sessions WHERE id = ?
    UNION ALL
    SELECT s.* FROM sessions s
    JOIN lineage l ON s.id = l.parent_session_id
)
SELECT id, title, started_at, parent_session_id FROM lineage;

-- 尋找會話的所有後代
WITH RECURSIVE descendants AS (
    SELECT * FROM sessions WHERE id = ?
    UNION ALL
    SELECT s.* FROM sessions s
    JOIN descendants d ON s.parent_session_id = d.id
)
SELECT id, title, started_at FROM descendants;
```

### 查詢：帶預覽的最近會話

```sql
SELECT s.*,
    COALESCE(
        (SELECT SUBSTR(m.content, 1, 63)
         FROM messages m
         WHERE m.session_id = s.id AND m.role = 'user' AND m.content IS NOT NULL
         ORDER BY m.timestamp, m.id LIMIT 1),
        ''
    ) AS preview,
    COALESCE(
        (SELECT MAX(m2.timestamp) FROM messages m2 WHERE m2.session_id = s.id),
        s.started_at
    ) AS last_active
FROM sessions s
ORDER BY s.started_at DESC
LIMIT 20;
```

### 查詢：標記 (Token) 使用量統計

```sql
-- 按模型統計總標記數
SELECT model,
       COUNT(*) as session_count,
       SUM(input_tokens) as total_input,
       SUM(output_tokens) as total_output,
       SUM(estimated_cost_usd) as total_cost
FROM sessions
WHERE model IS NOT NULL
GROUP BY model
ORDER BY total_cost DESC;

-- 標記使用量最高的會話
SELECT id, title, model, input_tokens + output_tokens AS total_tokens,
       estimated_cost_usd
FROM sessions
ORDER BY total_tokens DESC
LIMIT 10;
```


## 匯出與清理

```python
# 匯出單個會話及其訊息
data = db.export_session("sess_abc123")

# 將所有會話（包含訊息）匯出為字典列表
all_data = db.export_all(source="cli")

# 刪除舊會話（僅限已結束的會話）
deleted_count = db.prune_sessions(older_than_days=90)
deleted_count = db.prune_sessions(older_than_days=30, source="telegram")

# 清除訊息但保留會話紀錄
db.clear_messages("sess_abc123")

# 刪除會話及其所有訊息
db.delete_session("sess_abc123")
```


## 資料庫位置

預設路徑：`~/.hermes/state.db`

這衍生自 `hermes_constants.get_hermes_home()`，預設解析為 `~/.hermes/`，或環境變數 `HERMES_HOME` 的值。

資料庫檔案、WAL 檔案 (`state.db-wal`) 和共用記憶體檔案 (`state.db-shm`) 都建立在同一個目錄中。
