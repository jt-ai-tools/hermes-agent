---
name: qmd
description: 使用 qmd 在本地搜尋個人知識庫、筆記、文件和會議記錄 — 結合 BM25、向量搜尋和 LLM 重排 (Reranking) 的混合檢索引擎。支援 CLI 和 MCP 整合。
version: 1.0.0
author: Hermes Agent + Teknium
license: MIT
platforms: [macos, linux]
metadata:
  hermes:
    tags: [Search, Knowledge-Base, RAG, Notes, MCP, Local-AI]
    related_skills: [obsidian, native-mcp, arxiv]
---

# QMD — Query Markup Documents

用於個人知識庫的本地、裝置端搜尋引擎。索引 Markdown 筆記、會議記錄、文件和任何文字檔案，然後提供結合關鍵字匹配、語義理解和 LLM 重排的混合搜尋 — 全部在本地執行，無需雲端依賴。

由 [Tobi Lütke](https://github.com/tobi/qmd) 建立。採 MIT 授權。

## 何時使用

- 使用者要求搜尋他們的筆記、文件、知識庫或會議記錄
- 使用者想要在大量的 Markdown/文字檔案中尋找內容
- 使用者想要語義搜尋（「尋找關於 X 概念的筆記」）而不僅僅是關鍵字 grep
- 使用者已經設定好 qmd 集合 (Collections) 並想要查詢它們
- 使用者要求建立本地知識庫或文件搜尋系統
- 關鍵字：「搜尋我的筆記」、「在我的文件中尋找」、「知識庫」、「qmd」

## 前提條件

### Node.js >= 22 (必要)

```bash
# 檢查版本
node --version  # 必須 >= 22

# macOS — 透過 Homebrew 安裝或升級
brew install node@22

# Linux — 使用 NodeSource 或 nvm
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
# 或使用 nvm：
nvm install 22 && nvm use 22
```

### 支援擴充功能載入的 SQLite (僅限 macOS)

macOS 系統內建的 SQLite 缺乏擴充功能載入支援。請透過 Homebrew 安裝：

```bash
brew install sqlite
```

### 安裝 qmd

```bash
npm install -g @tobilu/qmd
# 或使用 Bun：
bun install -g @tobilu/qmd
```

首次執行會自動下載 3 個本地 GGUF 模型（總計約 2GB）：

| 模型 | 用途 | 大小 |
|-------|---------|------|
| embeddinggemma-300M-Q8_0 | 向量嵌入 (Vector embeddings) | ~300MB |
| qwen3-reranker-0.6b-q8_0 | 結果重排 | ~640MB |
| qmd-query-expansion-1.7B | 查詢擴展 | ~1.1GB |

### 驗證安裝

```bash
qmd --version
qmd status
```

## 快速參考

| 指令 | 用途 | 速度 |
|---------|-------------|-------|
| `qmd search "query"` | BM25 關鍵字搜尋（不使用模型） | ~0.2s |
| `qmd vsearch "query"` | 語義向量搜尋（使用 1 個模型） | ~3s |
| `qmd query "query"` | 混合搜尋 + 重排（使用全部 3 個模型） | 熱啟動 ~2-3s，冷啟動 ~19s |
| `qmd get <docid>` | 獲取完整文件內容 | 即時 |
| `qmd multi-get "glob"` | 獲取多個檔案 | 即時 |
| `qmd collection add <path> --name <n>` | 將目錄新增為集合 | 即時 |
| `qmd context add <path> "description"` | 新增背景元數據以提高檢索率 | 即時 |
| `qmd embed` | 生成/更新向量嵌入 | 視情況而定 |
| `qmd status` | 顯示索引健康狀態和集合資訊 | 即時 |
| `qmd mcp` | 啟動 MCP 伺服器 (stdio) | 持續執行 |
| `qmd mcp --http --daemon` | 啟動 MCP 伺服器 (HTTP, 模型保持熱啟動) | 持續執行 |

## 設定工作流

### 1. 新增集合 (Add Collections)

將 qmd 指向包含你文件的目錄：

```bash
# 新增筆記目錄
qmd collection add ~/notes --name notes

# 新增專案文件
qmd collection add ~/projects/myproject/docs --name project-docs

# 新增會議記錄
qmd collection add ~/meetings --name meetings

# 列出所有集合
qmd collection list
```

### 2. 新增背景描述 (Add Context Descriptions)

背景元數據有助於搜尋引擎了解每個集合包含的內容。這能顯著提高檢索品質：

```bash
qmd context add qmd://notes "個人筆記、想法和日記"
qmd context add qmd://project-docs "主專案的技術文件"
qmd context add qmd://meetings "團隊同步會議的會議記錄和行動清單"
```

### 3. 生成嵌入 (Generate Embeddings)

```bash
qmd embed
```

這會處理所有集合中的所有文件並生成向量嵌入。在新增新文件或集合後請重新執行。

### 4. 驗證

```bash
qmd status   # 顯示索引健康狀態、集合統計數據和模型資訊
```

## 搜尋模式

### 快速關鍵字搜尋 (BM25)

最適用於：精確術語、程式碼標識符、名稱、已知短語。
不載入模型 — 結果近乎即時。

```bash
qmd search "authentication middleware"
qmd search "handleError async"
```

### 語義向量搜尋 (Semantic Vector Search)

最適用於：自然語言問題、概念性查詢。
會載入嵌入模型（首次查詢約 3s）。

```bash
qmd vsearch "how does the rate limiter handle burst traffic"
qmd vsearch "ideas for improving onboarding flow"
```

### 帶有重排的混合搜尋 (最高品質)

最適用於：品質至上的重要查詢。
使用全部 3 個模型 — 查詢擴展、並行 BM25+向量搜尋、重排。

```bash
qmd query "what decisions were made about the database migration"
```

### 結構化多模式查詢

在單次查詢中結合不同的搜尋類型以提高精確度：

```bash
# BM25 用於精確術語 + 向量用於概念
qmd query $'lex: rate limiter\nvec: how does throttling work under load'

# 使用查詢擴展
qmd query $'expand: database migration plan\nlex: "schema change"'
```

### 查詢語法 (lex/BM25 模式)

| 語法 | 效果 | 範例 |
|--------|--------|---------|
| `term` | 前綴匹配 | `perf` 匹配 "performance" |
| `"phrase"` | 精確短語 | `"rate limiter"` |
| `-term` | 排除術語 | `performance -sports` |

### HyDE (假設性文件嵌入，Hypothetical Document Embeddings)

對於複雜主題，寫下你預期的答案外觀：

```bash
qmd query $'hyde: The migration plan involves three phases. First, we add the new columns without dropping the old ones. Then we backfill data. Finally we cut over and remove legacy columns.'
```

### 限制集合範圍

```bash
qmd search "query" --collection notes
qmd query "query" --collection project-docs
```

### 輸出格式

```bash
qmd search "query" --json        # JSON 輸出 (最適合解析)
qmd search "query" --limit 5     # 限制結果數量
qmd get "#abc123"                # 透過文件 ID 獲取
qmd get "path/to/file.md"       # 透過檔案路徑獲取
qmd get "file.md:50" -l 100     # 獲取特定行號範圍
qmd multi-get "journals/*.md" --json  # 透過 glob 批量獲取
```

## MCP 整合 (建議使用)

qmd 提供一個 MCP 伺服器，透過原生的 MCP 客戶端直接為 Hermes Agent 提供搜尋工具。這是偏好的整合方式 — 設定完成後，Agent 會自動獲得 qmd 工具，無需載入此技能。

### 選項 A：Stdio 模式 (簡單)

新增到 `~/.hermes/config.yaml`：

```yaml
mcp_servers:
  qmd:
    command: "qmd"
    args: ["mcp"]
    timeout: 30
    connect_timeout: 45
```

這會註冊工具：`mcp_qmd_search`、`mcp_qmd_vsearch`、`mcp_qmd_deep_search`、`mcp_qmd_get`、`mcp_qmd_status`。

**權衡：** 模型在首次搜尋呼叫時載入（冷啟動約 19s），之後在該工作階段中保持熱啟動。適合偶爾使用。

### 選項 B：HTTP 守護進程 (Daemon) 模式 (快速，建議重度使用)

單獨啟動 qmd 守護進程 — 它會將模型保持在記憶體中：

```bash
# 啟動守護進程 (Agent 重啟後仍會持續)
qmd mcp --http --daemon

# 預設在 http://localhost:8181 執行
```

然後設定 Hermes Agent 透過 HTTP 連線：

```yaml
mcp_servers:
  qmd:
    url: "http://localhost:8181/mcp"
    timeout: 30
```

**權衡：** 執行時佔用約 2GB RAM，但每次查詢都很快（約 2-3s）。最適合頻繁搜尋的使用者。

### 保持守護進程執行

#### macOS (launchd)

```bash
cat > ~/Library/LaunchAgents/com.qmd.daemon.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.qmd.daemon</string>
  <key>ProgramArguments</key>
  <array>
    <string>qmd</string>
    <string>mcp</string>
    <string>--http</string>
    <string>--daemon</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>/tmp/qmd-daemon.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/qmd-daemon.log</string>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.qmd.daemon.plist
```

#### Linux (systemd 使用者服務)

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/qmd-daemon.service << 'EOF'
[Unit]
Description=QMD MCP Daemon
After=network.target

[Service]
ExecStart=qmd mcp --http --daemon
Restart=on-failure
RestartSec=10
Environment=PATH=/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now qmd-daemon
systemctl --user status qmd-daemon
```

### MCP 工具參考

連線後，可使用以下 `mcp_qmd_*` 工具：

| MCP 工具 | 對應指令 | 說明 |
|----------|---------|-------------|
| `mcp_qmd_search` | `qmd search` | BM25 關鍵字搜尋 |
| `mcp_qmd_vsearch` | `qmd vsearch` | 語義向量搜尋 |
| `mcp_qmd_deep_search` | `qmd query` | 混合搜尋 + 重排 |
| `mcp_qmd_get` | `qmd get` | 透過 ID 或路徑獲取文件 |
| `mcp_qmd_status` | `qmd status` | 索引健康狀態和統計數據 |

MCP 工具接受結構化的 JSON 查詢以進行多模式搜尋：

```json
{
  "searches": [
    {"type": "lex", "query": "authentication middleware"},
    {"type": "vec", "query": "how user login is verified"}
  ],
  "collections": ["project-docs"],
  "limit": 10
}
```

## CLI 用法 (不使用 MCP)

若未設定 MCP，請直接透過終端機使用 qmd：

```
terminal(command="qmd query 'what was decided about the API redesign' --json", timeout=30)
```

對於設定和管理任務，請務必使用終端機：

```
terminal(command="qmd collection add ~/Documents/notes --name notes")
terminal(command="qmd context add qmd://notes '個人研究筆記與想法'")
terminal(command="qmd embed")
terminal(command="qmd status")
```

## 搜尋管線運作原理

了解內部原理有助於選擇正確的搜尋模式：

1. **查詢擴展 (Query Expansion)** — 一個微調過的 1.7B 模型會生成 2 個備選查詢。原始查詢在融合中獲得 2 倍權重。
2. **並行檢索 (Parallel Retrieval)** — BM25 (SQLite FTS5) 和向量搜尋在所有查詢變體中同時執行。
3. **RRF 融合 (RRF Fusion)** — 倒數排名融合 (Reciprocal Rank Fusion, k=60) 合併結果。首位加成：第 1 名獲得 +0.05，第 2-3 名獲得 +0.02。
4. **LLM 重排 (LLM Reranking)** — qwen3-reranker 對前 30 個候選結果評分 (0.0-1.0)。
5. **位置感知混合 (Position-Aware Blending)** — 排名 1-3：75% 檢索 / 25% 重排。排名 4-10：60/40。排名 11+：40/60（長尾部分更信任重排器）。

**智慧分塊 (Smart Chunking)：** 文件在自然中斷點（標題、程式碼塊、空行）處分割，目標約為 900 個 Token 並有 15% 重疊。程式碼塊絕不會在中間被分割。

## 最佳實務

1. **務必新增背景描述** — `qmd context add` 能顯著提高檢索準確度。描述每個集合包含的內容。
2. **新增文件後重新嵌入** — 當新檔案新增到集合中時，必須重新執行 `qmd embed`。
3. **快速搜尋使用 `qmd search`** — 當你需要快速關鍵字查詢（程式碼標識符、精確名稱）時，BM25 是即時的且不需要模型。
4. **高品質搜尋使用 `qmd query`** — 當問題具有概念性或使用者需要最佳結果時，使用混合搜尋。
5. **偏好 MCP 整合** — 設定完成後，Agent 擁有原生工具，無需每次載入此技能。
6. **守護進程模式適合頻繁使用者** — 如果使用者定期搜尋其知識庫，建議設定 HTTP 守護進程。
7. **結構化搜尋中的第一個查詢獲得 2x 權重** — 結合 lex 和 vec 時，將最重要/最確定的查詢放在首位。

## 故障排除

### 「首次執行時模型正在下載」
這是正常的 — qmd 在首次使用時會自動下載約 2GB 的 GGUF 模型。這是一次性操作。

### 冷啟動延遲 (~19s)
這發生在模型未載入到記憶體時。解決方案：
- 使用 HTTP 守護進程模式 (`qmd mcp --http --daemon`) 保持熱啟動
- 在不需要模型時使用 `qmd search` (僅 BM25)
- MCP stdio 模式在首次搜尋時載入模型，並在該工作階段保持熱啟動

### macOS：「無法載入擴充功能」 (unable to load extension)
安裝 Homebrew SQLite：`brew install sqlite`
然後確保它在 PATH 中優先於系統 SQLite。

### 「未找到集合」 (No collections found)
執行 `qmd collection add <path> --name <name>` 新增目錄，然後執行 `qmd embed` 進行索引。

### 嵌入模型覆蓋 (CJK/多語言)
對於非英語內容，請設定 `QMD_EMBED_MODEL` 環境變數：
```bash
export QMD_EMBED_MODEL="your-multilingual-model"
```

## 數據存儲

- **索引與向量：** `~/.cache/qmd/index.sqlite`
- **模型：** 首次執行時自動下載到本地快取
- **無雲端依賴** — 所有內容都在本地執行

## 參考資料

- [GitHub: tobi/qmd](https://github.com/tobi/qmd)
- [QMD 更新日誌 (Changelog)](https://github.com/tobi/qmd/blob/main/CHANGELOG.md)
