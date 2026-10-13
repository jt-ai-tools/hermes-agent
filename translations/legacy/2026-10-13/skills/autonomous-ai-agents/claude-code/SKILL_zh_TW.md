---
name: claude-code
description: 將編碼任務委派給 Claude Code (Anthropic 的 CLI 代理)。可用於構建功能、重構、PR 審查和迭代式編碼。需要安裝 claude CLI。
version: 2.2.0
author: Hermes Agent + Teknium
license: MIT
metadata:
  hermes:
    tags: [Coding-Agent, Claude, Anthropic, Code-Review, Refactoring, PTY, Automation]
    related_skills: [codex, hermes-agent, opencode]
---

# Claude Code — Hermes 編排指南

透過 Hermes 終端將編碼任務委派給 [Claude Code](https://code.claude.com/docs/en/cli-reference) (Anthropic 的自主編碼代理 CLI)。Claude Code v2.x 可以自主讀取文件、編寫程式碼、運行 shell 命令、生成子代理並管理 git 工作流。

## 前置條件

- **安裝：** `npm install -g @anthropic-ai/claude-code`
- **身份驗證 (Auth)：** 運行一次 `claude` 進行登錄 (Pro/Max 使用瀏覽器 OAuth，或設置 `ANTHROPIC_API_KEY`)
- **控制台身份驗證：** `claude auth login --console` 用於 API 金鑰計費
- **SSO 身份驗證：** `claude auth login --sso` 用於企業版
- **檢查狀態：** `claude auth status` (JSON) 或 `claude auth status --text` (人機可讀)
- **健康檢查：** `claude doctor` — 檢查自動更新程序和安裝健康狀況
- **版本檢查：** `claude --version` (需要 v2.x+)
- **更新：** `claude update` 或 `claude upgrade`

## 兩種編排模式

Hermes 以兩種根本不同的方式與 Claude Code 交互。請根據任務選擇。

### 模式 1：列印模式 (`-p`) — 非交互式 (推薦用於大多數任務)

列印模式運行單次任務，返回結果並退出。不需要 PTY。沒有交互式提示。這是最簡潔的集成路徑。

```
terminal(command="claude -p 'Add error handling to all API calls in src/' --allowedTools 'Read,Edit' --max-turns 10", workdir="/path/to/project", timeout=120)
```

**何時使用列印模式：**
- 單次編碼任務 (修復 bug、添加功能、重構)
- CI/CD 自動化和腳本編寫
- 使用 `--json-schema` 進行結構化數據提取
- 管道輸入處理 (`cat file | claude -p "analyze this"`)
- 任何不需要多輪對話的任務

**列印模式會跳過所有交互式對話** —— 沒有工作區信任提示，沒有權限確認。這使其成為自動化的理想選擇。

### 模式 2：透過 tmux 進行交互式 PTY — 多輪會話

交互式模式為您提供了一個完整的對話式 REPL，您可以在其中發送後續提示、使用斜槓命令 (slash commands) 並實時觀察 Claude 的工作。**需要使用 tmux 編排。**

```
# 啟動一個 tmux 會話
terminal(command="tmux new-session -d -s claude-work -x 140 -y 40")

# 在其中啟動 Claude Code
terminal(command="tmux send-keys -t claude-work 'cd /path/to/project && claude' Enter")

# 等待啟動，然後發送您的任務
# (在歡迎畫面出現後約 3-5 秒)
terminal(command="sleep 5 && tmux send-keys -t claude-work 'Refactor the auth module to use JWT tokens' Enter")

# 透過捕捉窗格監控進度
terminal(command="sleep 15 && tmux capture-pane -t claude-work -p -S -50")

# 發送後續任務
terminal(command="tmux send-keys -t claude-work 'Now add unit tests for the new JWT code' Enter")

# 完成後退出
terminal(command="tmux send-keys -t claude-work '/exit' Enter")
```

**何時使用交互式模式：**
- 多輪迭代工作 (重構 → 審查 → 修復 → 測試循環)
- 需要人機協作決策的任務
- 探索性編碼對話
- 當您需要使用 Claude 的斜槓命令時 (`/compact`, `/review`, `/model`)

## PTY 對話處理 (對交互式模式至關重要)

Claude Code 在首次啟動時最多會呈現兩個確認對話框。您必須透過 tmux send-keys 處理這些對話框：

### 對話框 1：工作區信任 (首次訪問目錄)
```
❯ 1. Yes, I trust this folder    ← 預設值 (只需按 Enter)
  2. No, exit
```
**處理：** `tmux send-keys -t <session> Enter` — 預設選擇即正確。

### 對話框 2：繞過權限警告 (僅在使用 --dangerously-skip-permissions 時)
```
❯ 1. No, exit                    ← 預設值 (錯誤選擇！)
  2. Yes, I accept
```
**處理：** 必須先向**下**導航，然後按 Enter：
```
tmux send-keys -t <session> Down && sleep 0.3 && tmux send-keys -t <session> Enter
```

### 穩健的對話處理模式
```
# 使用權限繞過啟動
terminal(command="tmux send-keys -t claude-work 'claude --dangerously-skip-permissions \"your task\"' Enter")

# 處理信任對話框 (按 Enter 選擇預設的 "Yes")
terminal(command="sleep 4 && tmux send-keys -t claude-work Enter")

# 處理權限對話框 (先按 Down 再按 Enter 以選擇 "Yes, I accept")
terminal(command="sleep 3 && tmux send-keys -t claude-work Down && sleep 0.3 && tmux send-keys -t claude-work Enter")

# 現在等待 Claude 運作
terminal(command="sleep 15 && tmux capture-pane -t claude-work -p -S -60")
```

**注意：** 對於一個目錄首次接受信任後，信任對話框將不再出現。只有當您每次使用 `--dangerously-skip-permissions` 時，權限對話框才會重複出現。

## CLI 子命令

| 子命令 | 用途 |
|------------|---------|
| `claude` | 啟動交互式 REPL |
| `claude "query"` | 使用初始提示詞啟動 REPL |
| `claude -p "query"` | 列印模式 (非交互式，完成後退出) |
| `cat file \| claude -p "query"` | 將內容管道傳輸為 stdin 上下文 |
| `claude -c` | 繼續此目錄中最近的對話 |
| `claude -r "id"` | 透過 ID 或名稱恢復特定會話 |
| `claude auth login` | 登錄 (添加 `--console` 用於 API 計費，`--sso` 用於企業版) |
| `claude auth status` | 檢查登錄狀態 (返回 JSON；`--text` 為人機可讀) |
| `claude mcp add <name> -- <cmd>` | 添加一個 MCP 伺服器 |
| `claude mcp list` | 列出已配置的 MCP 伺服器 |
| `claude mcp remove <name>` | 移除一個 MCP 伺服器 |
| `claude agents` | 列出已配置的代理 |
| `claude doctor` | 對安裝和自動更新程序運行健康檢查 |
| `claude update` / `claude upgrade` | 將 Claude Code 更新至最新版本 |
| `claude remote-control` | 啟動伺服器以從 claude.ai 或移動應用程式控制 Claude |
| `claude install [target]` | 安裝原生構建版本 (stable、latest 或特定版本) |
| `claude setup-token` | 設置長期授權權杖 (需要訂閱) |
| `claude plugin` / `claude plugins` | 管理 Claude Code 插件 |
| `claude auto-mode` | 檢查自動模式分類器配置 |

## 列印模式深入解析

### 結構化 JSON 輸出
```
terminal(command="claude -p 'Analyze auth.py for security issues' --output-format json --max-turns 5", workdir="/project", timeout=120)
```

返回一個 JSON 物件，包含：
```json
{
  "type": "result",
  "subtype": "success",
  "result": "分析文本...",
  "session_id": "75e2167f-...",
  "num_turns": 3,
  "total_cost_usd": 0.0787,
  "duration_ms": 10276,
  "stop_reason": "end_turn",
  "terminal_reason": "completed",
  "usage": { "input_tokens": 5, "output_tokens": 603, ... },
  "modelUsage": { "claude-sonnet-4-6": { "costUSD": 0.078, "contextWindow": 200000 } }
}
```

**關鍵欄位：** `session_id` 用於恢復，`num_turns` 用於代理循環計數，`total_cost_usd` 用於支出追踪，`subtype` 用於成功/錯誤檢測 (`success`, `error_max_turns`, `error_budget`)。

### 串流 JSON 輸出
如需實時權杖 (token) 串流，請使用 `stream-json` 配合 `--verbose`：
```
terminal(command="claude -p 'Write a summary' --output-format stream-json --verbose --include-partial-messages", timeout=60)
```

返回以換行符分隔的 JSON 事件。使用 jq 過濾實時文本：
```
claude -p "Explain X" --output-format stream-json --verbose --include-partial-messages | \
  jq -rj 'select(.type == "stream_event" and .event.delta.type? == "text_delta") | .event.delta.text'
```

串流事件包括 `system/api_retry`，帶有 `attempt`, `max_retries` 和 `error` 欄位 (例如 `rate_limit`, `billing_error`)。

### 雙向串流
用於實時輸入和輸出串流：
```
claude -p "task" --input-format stream-json --output-format stream-json --replay-user-messages
```
`--replay-user-messages` 在 stdout 上重新發送使用者訊息以供確認。

### 管道輸入
```
# 傳輸文件進行分析
terminal(command="cat src/auth.py | claude -p 'Review this code for bugs' --max-turns 1", timeout=60)

# 傳輸多個文件
terminal(command="cat src/*.py | claude -p 'Find all TODO comments' --max-turns 1", timeout=60)

# 傳輸命令輸出
terminal(command="git diff HEAD~3 | claude -p 'Summarize these changes' --max-turns 1", timeout=60)
```

### 用於結構化提取的 JSON Schema
```
terminal(command="claude -p 'List all functions in src/' --output-format json --json-schema '{\"type\":\"object\",\"properties\":{\"functions\":{\"type\":\"array\",\"items\":{\"type\":\"string\"}}},\"required\":[\"functions\"]}' --max-turns 5", workdir="/project", timeout=90)
```

從 JSON 結果中解析 `structured_output`。Claude 在返回之前會根據 schema 驗證輸出。

### 會話恢復
```
# 開始任務
terminal(command="claude -p 'Start refactoring the database layer' --output-format json --max-turns 10 > /tmp/session.json", workdir="/project", timeout=180)

# 使用會話 ID 恢復
terminal(command="claude -p 'Continue and add connection pooling' --resume $(cat /tmp/session.json | python3 -c 'import json,sys; print(json.load(sys.stdin)[\"session_id\"])') --max-turns 5", workdir="/project", timeout=120)

# 或恢復同一目錄中最近的會話
terminal(command="claude -p 'What did you do last time?' --continue --max-turns 1", workdir="/project", timeout=30)

# 分岔會話 (新 ID，保留歷史記錄)
terminal(command="claude -p 'Try a different approach' --resume <id> --fork-session --max-turns 10", workdir="/project", timeout=120)
```

### 用於 CI/腳本的裸模式 (Bare Mode)
```
terminal(command="claude --bare -p 'Run all tests and report failures' --allowedTools 'Read,Bash' --max-turns 10", workdir="/project", timeout=180)
```

`--bare` 跳過鉤子 (hooks)、插件、MCP 發現和 CLAUDE.md 加載。啟動速度最快。需要 `ANTHROPIC_API_KEY` (跳過 OAuth)。

要在裸模式下選擇性地加載上下文：
| 加載項目 | 標籤 |
|---------|------|
| 系統提示詞補充 | `--append-system-prompt "text"` 或 `--append-system-prompt-file path` |
| 設置 | `--settings <file-or-json>` |
| MCP 伺服器 | `--mcp-config <file-or-json>` |
| 自定義代理 | `--agents '<json>'` |

### 過載時的後備模型
```
terminal(command="claude -p 'task' --fallback-model haiku --max-turns 5", timeout=90)
```
當預設模型過載時自動後備到指定的模型 (僅限列印模式)。

## 完整 CLI 標籤參考

### 會話與環境
| 標籤 | 效果 |
|------|--------|
| `-p, --print` | 非交互式單次模式 (完成後退出) |
| `-c, --continue` | 恢復當前目錄中最近的對話 |
| `-r, --resume <id>` | 恢復由 ID 或名稱指定的特定會話 (若無 ID 則啟動交互式選擇器) |
| `--fork-session` | 恢復時，創建新的會話 ID 而非重用原 ID |
| `--session-id <uuid>` | 為對話使用特定的 UUID |
| `--no-session-persistence` | 不將會話保存到磁碟 (僅限列印模式) |
| `--add-dir <paths...>` | 授予 Claude 訪問額外工作目錄的權限 |
| `-w, --worktree [name]` | 在位於 `.claude/worktrees/<name>` 的隔離 git 工作樹中運行 |
| `--tmux` | 為工作樹創建 tmux 會話 (需要 `--worktree`) |
| `--ide` | 啟動時自動連接到有效的 IDE |
| `--chrome` / `--no-chrome` | 啟用/禁用用於 Web 測試的 Chrome 瀏覽器集成 |
| `--from-pr [number]` | 恢復與特定 GitHub PR 關聯的會話 |
| `--file <specs...>` | 啟動時下載的文件資源 (格式: `file_id:relative_path`) |

### 模型與效能
| 標籤 | 效果 |
|------|--------|
| `--model <alias>` | 模型選擇：`sonnet`, `opus`, `haiku`, 或完整名稱如 `claude-sonnet-4-6` |
| `--effort <level>` | 推理深度：`low`, `medium`, `high`, `max`, `auto` |
| `--max-turns <n>` | 限制代理循環次數 (僅限列印模式；防止失控) |
| `--max-budget-usd <n>` | 限制 API 支出金額 (美金) (僅限列印模式) |
| `--fallback-model <model>` | 當預設模型過載時自動後備 (僅限列印模式) |
| `--betas <betas...>` | 在 API 請求中包含的 Beta 標頭 (僅限 API 金鑰使用者) |

### 權限與安全
| 標籤 | 效果 |
|------|--------|
| `--dangerously-skip-permissions` | 自動批准所有工具使用 (文件寫入、bash、網絡等) |
| `--allow-dangerously-skip-permissions` | 啟用跳過作為一個*選項*，但不預設啟用 |
| `--permission-mode <mode>` | `default`, `acceptEdits`, `plan`, `auto`, `dontAsk`, `bypassPermissions` |
| `--allowedTools <tools...>` | 白名單特定工具 (以逗號或空格分隔) |
| `--disallowedTools <tools...>` | 黑名單特定工具 |
| `--tools <tools...>` | 覆蓋內置工具集 (`""` = 無, `"default"` = 全部, 或工具名稱) |

### 輸出與輸入格式
| 標籤 | 效果 |
|------|--------|
| `--output-format <fmt>` | `text` (預設), `json` (單個結果物件), `stream-json` (以換行符分隔) |
| `--input-format <fmt>` | `text` (預設) 或 `stream-json` (實時串流輸入) |
| `--json-schema <schema>` | 強制符合 schema 的結構化 JSON 輸出 |
| `--verbose` | 完整的逐輪輸出 |
| `--include-partial-messages` | 在部分訊息到達時即包含它們 (stream-json + print) |
| `--replay-user-messages` | 在 stdout 上重新發送使用者訊息 (stream-json 雙向) |

### 系統提示詞與上下文
| 標籤 | 效果 |
|------|--------|
| `--append-system-prompt <text>` | **追加**到預設系統提示詞 (保留內置功能) |
| `--append-system-prompt-file <path>` | 將文件內容**追加**到預設系統提示詞 |
| `--system-prompt <text>` | **替換**整個系統提示詞 (通常應使用 --append) |
| `--system-prompt-file <path>` | 使用文件內容**替換**系統提示詞 |
| `--bare` | 跳過鉤子、插件、MCP 發現、CLAUDE.md、OAuth (啟動速度最快) |
| `--agents '<json>'` | 以 JSON 形式動態定義自定義子代理 |
| `--mcp-config <path>` | 從 JSON 文件加載 MCP 伺服器 (可重複) |
| `--strict-mcp-config` | 僅使用來自 `--mcp-config` 的 MCP 伺服器，忽略所有其他 MCP 配置 |
| `--settings <file-or-json>` | 從 JSON 文件或內聯 JSON 加載額外設置 |
| `--setting-sources <sources>` | 以逗號分隔的加載來源：`user`, `project`, `local` |
| `--plugin-dir <paths...>` | 僅在此會話中從目錄加載插件 |
| `--disable-slash-commands` | 禁用所有技能/斜槓命令 |

### 調試
| 標籤 | 效果 |
|------|--------|
| `-d, --debug [filter]` | 啟用帶有可選分類過濾器的調試日誌 (例如 `"api,hooks"`, `"!1p,!file"`) |
| `--debug-file <path>` | 將調試日誌寫入文件 (隱式啟用調試模式) |

### 代理團隊
| 標籤 | 效果 |
|------|--------|
| `--teammate-mode <mode>` | 代理團隊如何顯示：`auto`, `in-process`, 或 `tmux` |
| `--brief` | 啟用 `SendUserMessage` 工具用於代理與使用者間的通信 |

### --allowedTools / --disallowedTools 的工具名稱語法
```
Read                    # 所有文件讀取
Edit                    # 文件編輯 (現有文件)
Write                   # 文件創建 (新文件)
Bash                    # 所有 shell 命令
Bash(git *)             # 僅限 git 命令
Bash(git commit *)      # 僅限 git commit 命令
Bash(npm run lint:*)    # 使用通配符進行模式匹配
WebSearch               # 網頁搜索能力
WebFetch                # 網頁內容抓取
mcp__<server>__<tool>   # 特定 MCP 工具
```

## 設置與配置

### 設置層次結構 (由高到低)
1. **CLI 標籤** — 覆蓋所有其他設置
2. **本地專案：** `.claude/settings.local.json` (個人設置，gitignored)
3. **專案：** `.claude/settings.json` (共享設置，git 追踪)
4. **使用者：** `~/.claude/settings.json` (全域設置)

### 設置中的權限
```json
{
  "permissions": {
    "allow": ["Bash(npm run lint:*)", "WebSearch", "Read"],
    "ask": ["Write(*.ts)", "Bash(git push*)"],
    "deny": ["Read(.env)", "Bash(rm -rf *)"]
  }
}
```

### 記憶文件 (CLAUDE.md) 層次結構
1. **全域：** `~/.claude/CLAUDE.md` — 適用於所有專案
2. **專案：** `./CLAUDE.md` — 專案特定上下文 (git 追踪)
3. **本地：** `.claude/CLAUDE.local.md` — 個人專案覆蓋 (gitignored)

在交互模式下使用 `#` 前綴可快速添加到記憶：`# Always use 2-space indentation`。

## 交互式會話：斜槓命令 (Slash Commands)

### 會話與上下文
| 命令 | 用途 |
|---------|---------|
| `/help` | 顯示所有命令 (包括自定義和 MCP 命令) |
| `/compact [focus]` | 壓縮上下文以節省權杖；CLAUDE.md 在壓縮後仍保留。例如 `/compact focus on auth logic` |
| `/clear` | 清除對話歷史以重新開始 |
| `/context` | 將上下文使用情況顯示為帶有優化建議的彩色網格 |
| `/cost` | 查看權杖使用情況，包含逐個模型和快取命中細節 |
| `/resume` | 切換到或恢復不同的會話 |
| `/rewind` | 恢復到對話或程式碼中的前一個檢查點 |
| `/btw <question>` | 提一個旁支問題，且不增加上下文成本 |
| `/status` | 顯示版本、連接性和會話資訊 |
| `/todos` | 列出從對話中追踪的待辦事項 |
| `/exit` 或 `Ctrl+D` | 結束會話 |

### 開發與審查
| 命令 | 用途 |
|---------|---------|
| `/review` | 請求對當前更改進行程式碼審查 |
| `/security-review` | 對當前更改進行安全性分析 |
| `/plan [description]` | 進入計畫模式 (Plan mode) 並自動啟動任務規劃 |
| `/loop [interval]` | 在會話中安排循環任務 |
| `/batch` | 為大型平行更改自動創建工作樹 (5-30 個工作樹) |

### 配置與工具
| 命令 | 用途 |
|---------|---------|
| `/model [model]` | 在會話中切換模型 (使用方向鍵調整推理強度) |
| `/effort [level]` | 設置推理強度：`low`, `medium`, `high`, `max`, 或 `auto` |
| `/init` | 為專案記憶創建 CLAUDE.md 文件 |
| `/memory` | 打開 CLAUDE.md 進行編輯 |
| `/config` | 打開交互式設置配置 |
| `/permissions` | 查看/更新工具權限 |
| `/agents` | 管理專門的子代理 |
| `/mcp` | 用於管理 MCP 伺服器的交互式 UI |
| `/add-dir` | 添加額外的工作目錄 (對 monorepos 很有用) |
| `/usage` | 顯示計畫限制和速率限制 (rate limit) 狀態 |
| `/voice` | 啟用一鍵通 (push-to-talk) 語音模式 (支援 20 種語言；按住空格錄音，放開即發送) |
| `/release-notes` | 用於版本發布說明的交互式選擇器 |

### 自定義斜槓命令
創建 `.claude/commands/<name>.md` (專案共享) 或 `~/.claude/commands/<name>.md` (個人)：

```markdown
# .claude/commands/deploy.md
運行部署管道：
1. 運行所有測試
2. 構建 Docker 鏡像
3. 推送到註冊表
4. 更新 $ARGUMENTS 環境 (預設：staging)
```

使用方式：`/deploy production` — `$ARGUMENTS` 將被替換為使用者的輸入。

### 技能 (Skill，自然語言調用)
與斜槓命令 (需手動調用) 不同，`.claude/skills/` 中的技能是 Markdown 指南，當任務匹配時，Claude 會透過自然語言自動調用：

```markdown
# .claude/skills/database-migration.md
當被要求創建或修改數據庫遷移時：
1. 使用 Alembic 生成遷移
2. 始終創建回滾函數
3. 針對本地數據庫副本測試遷移
```

## 交互式會話：鍵盤快捷鍵

### 一般控制
| 按鍵 | 動作 |
|-----|--------|
| `Ctrl+C` | 取消當前輸入或生成 |
| `Ctrl+D` | 退出會話 |
| `Ctrl+R` | 反向搜索命令歷史記錄 |
| `Ctrl+B` | 將正在運行的任務轉入後台 |
| `Ctrl+V` | 將圖片貼上到對話中 |
| `Ctrl+O` | 轉錄模式 — 查看 Claude 的思考過程 |
| `Ctrl+G` 或 `Ctrl+X Ctrl+E` | 在外部編輯器中打開提示詞 |
| `Esc Esc` | 倒回對話或程式碼狀態 / 總結 |

### 模式切換
| 按鍵 | 動作 |
|-----|--------|
| `Shift+Tab` | 循環切換權限模式 (Normal → Auto-Accept → Plan) |
| `Alt+P` | 切換模型 |
| `Alt+T` | 切換思考模式 |
| `Alt+O` | 切換快速模式 (Fast Mode) |

### 多行輸入
| 按鍵 | 動作 |
|-----|--------|
| `\` + `Enter` | 快速換行 |
| `Shift+Enter` | 換行 (替代方案) |
| `Ctrl+J` | 換行 (替代方案) |

### 輸入前綴
| 前綴 | 動作 |
|--------|--------|
| `!` | 直接執行 bash，繞過 AI (例如 `!npm test`)。單獨使用 `!` 可切換 shell 模式。 |
| `@` | 帶自動補全地引用文件/目錄 (例如 `@./src/api/`) |
| `#` | 快速添加到 CLAUDE.md 記憶 (例如 `# Use 2-space indentation`) |
| `/` | 斜槓命令 |

### 專業技巧："ultrathink"
在提示詞中使用關鍵字 "ultrathink"，可在特定一輪對話中使用最大推理強度。無論當前的 `/effort` 設置為何，這都會觸發最深層的思考模式。

## PR 審查模式

### 快速審查 (列印模式)
```
terminal(command="cd /path/to/repo && git diff main...feature-branch | claude -p 'Review this diff for bugs, security issues, and style problems. Be thorough.' --max-turns 1", timeout=60)
```

### 深度審查 (交互式 + 工作樹)
```
terminal(command="tmux new-session -d -s review -x 140 -y 40")
terminal(command="tmux send-keys -t review 'cd /path/to/repo && claude -w pr-review' Enter")
terminal(command="sleep 5 && tmux send-keys -t review Enter")  # 信任對話框
terminal(command="sleep 2 && tmux send-keys -t review 'Review all changes vs main. Check for bugs, security issues, race conditions, and missing tests.' Enter")
terminal(command="sleep 30 && tmux capture-pane -t review -p -S -60")
```

### 根據編號進行 PR 審查
```
terminal(command="claude -p 'Review this PR thoroughly' --from-pr 42 --max-turns 10", workdir="/path/to/repo", timeout=120)
```

### 帶 tmux 的 Claude 工作樹
```
terminal(command="claude -w feature-x --tmux", workdir="/path/to/repo")
```
在 `.claude/worktrees/feature-x` 創建一個隔離的 git 工作樹，並為其創建一個 tmux 會話。在可用時使用 iTerm2 原生分欄；對於傳統 tmux，請添加 `--tmux=classic`。

## 平行 Claude 實例

同時運行多個獨立的 Claude 任務：

```
# 任務 1：修復後端
terminal(command="tmux new-session -d -s task1 -x 140 -y 40 && tmux send-keys -t task1 'cd ~/project && claude -p \"Fix the auth bug in src/auth.py\" --allowedTools \"Read,Edit\" --max-turns 10' Enter")

# 任務 2：編寫測試
terminal(command="tmux new-session -d -s task2 -x 140 -y 40 && tmux send-keys -t task2 'cd ~/project && claude -p \"Write integration tests for the API endpoints\" --allowedTools \"Read,Write,Bash\" --max-turns 15' Enter")

# 任務 3：更新文件
terminal(command="tmux new-session -d -s task3 -x 140 -y 40 && tmux send-keys -t task3 'cd ~/project && claude -p \"Update README.md with the new API endpoints\" --allowedTools \"Read,Edit\" --max-turns 5' Enter")

# 監控所有任務
terminal(command="sleep 30 && for s in task1 task2 task3; do echo '=== '$s' ==='; tmux capture-pane -t $s -p -S -5 2>/dev/null; done")
```

## CLAUDE.md — 專案上下文文件

Claude Code 會從專案根目錄自動加載 `CLAUDE.md`。使用它來保留專案上下文：

```markdown
# Project: My API

## Architecture
- FastAPI backend with SQLAlchemy ORM
- PostgreSQL database, Redis cache
- pytest for testing with 90% coverage target

## Key Commands
- `make test` — run full test suite
- `make lint` — ruff + mypy
- `make dev` — start dev server on :8000

## Code Standards
- Type hints on all public functions
- Docstrings in Google style
- 2-space indentation for YAML, 4-space for Python
- No wildcard imports
```

**請具體化。** 不要使用 "編寫高品質程式碼"，而應使用 "JS 使用 2 空格縮排" 或 "測試文件以 `.test.ts` 結尾"。具體的指令可減少修正次數。

### 規則目錄 (模組化 CLAUDE.md)
對於規則較多的專案，請使用規則目錄而非單個龐大的 CLAUDE.md：
- **專案規則：** `.claude/rules/*.md` — 團隊共享，git 追踪
- **使用者規則：** `~/.claude/rules/*.md` — 個人全域設置

規則目錄中的每個 `.md` 文件都會作為額外上下文加載。這比把所有內容塞進一個 CLAUDE.md 更整潔。

### 自動記憶 (Auto-Memory)
Claude 會將學到的專案上下文自動存儲在 `~/.claude/projects/<project>/memory/`。
- **限制：** 每個專案 25KB 或 200 行
- 這與 CLAUDE.md 是分開的 —— 它是 Claude 跨會話累積的關於專案的自用筆記

## 自定義子代理 (Custom Subagents)

在 `.claude/agents/` (專案)、`~/.claude/agents/` (個人) 中定義專門的代理，或透過 `--agents` CLI 標籤 (會話) 定義：

### 代理位置優先級
1. `.claude/agents/` — 專案層級，團隊共享
2. `--agents` CLI 標籤 — 會話特定，動態
3. `~/.claude/agents/` — 使用者層級，個人

### 創建一個代理
```markdown
# .claude/agents/security-reviewer.md
---
name: security-reviewer
description: 專注於安全的程式碼審查
model: opus
tools: [Read, Bash]
---
你是一位資深安全工程師。審查程式碼中的：
- 注入漏洞 (SQL, XSS, 命令注入)
- 身份驗證/授權缺陷
- 程式碼中的機密資訊
- 不安全的反序列化
```

調用方式：`@security-reviewer review the auth module`

### 透過 CLI 動態定義代理
```
terminal(command="claude --agents '{\"reviewer\": {\"description\": \"Reviews code\", \"prompt\": \"You are a code reviewer focused on performance\"}}' -p 'Use @reviewer to check auth.py'", timeout=120)
```

Claude 可以編排多個代理："使用 @db-expert 優化查詢，然後由 @security 審計這些更改。"

## 鉤子 (Hooks) — 事件自動化

在 `.claude/settings.json` (專案) 或 `~/.claude/settings.json` (全域) 中配置：

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write(*.py)",
      "hooks": [{"type": "command", "command": "ruff check --fix $CLAUDE_FILE_PATHS"}]
    }],
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{"type": "command", "command": "if echo \"$CLAUDE_TOOL_INPUT\" | grep -q 'rm -rf'; then echo 'Blocked!' && exit 2; fi"}]
    }],
    "Stop": [{
      "hooks": [{"type": "command", "command": "echo 'Claude finished a response' >> /tmp/claude-activity.log"}]
    }]
  }
}
```

### 所有 8 種鉤子類型
| 鉤子 | 觸發時機 | 常見用途 |
|------|--------------|------------|
| `UserPromptSubmit` | 在 Claude 處理使用者提示詞之前 | 輸入驗證、記錄日誌 |
| `PreToolUse` | 在工具執行之前 | 安全閘道、阻止危險命令 (exit 2 = 阻止) |
| `PostToolUse` | 在工具完成後 | 自動格式化程式碼、運行 linter |
| `Notification` | 當有權限請求或等待輸入時 | 桌面通知、警報 |
| `Stop` | 當 Claude 完成回應時 | 完成日誌記錄、狀態更新 |
| `SubagentStop` | 當子代理完成時 | 代理編排 |
| `PreCompact` | 在上下文記憶被清除前 | 備份會話轉錄文本 |
| `SessionStart` | 當會話開始時 | 加載開發上下文 (例如 `git status`) |

### 鉤子環境變數
| 變數 | 內容 |
|----------|---------|
| `CLAUDE_PROJECT_DIR` | 當前專案路徑 |
| `CLAUDE_FILE_PATHS` | 正在修改的文件 |
| `CLAUDE_TOOL_INPUT` | 作為 JSON 的工具參數 |

### 安全鉤子範例
```json
{
  "PreToolUse": [{
    "matcher": "Bash",
    "hooks": [{"type": "command", "command": "if echo \"$CLAUDE_TOOL_INPUT\" | grep -qE 'rm -rf|git push.*--force|:(){ :|:& };:'; then echo 'Dangerous command blocked!' && exit 2; fi"}]
  }]
}
```

## MCP 集成

為資料庫、API 和服務添加外部工具伺服器：

```
# GitHub 集成
terminal(command="claude mcp add -s user github -- npx @modelcontextprotocol/server-github", timeout=30)

# PostgreSQL 查詢
terminal(command="claude mcp add -s local postgres -- npx @anthropic-ai/server-postgres --connection-string postgresql://localhost/mydb", timeout=30)

# 用於網頁測試的 Puppeteer
terminal(command="claude mcp add puppeteer -- npx @anthropic-ai/server-puppeteer", timeout=30)
```

### MCP 範圍 (Scopes)
| 標籤 | 範圍 | 存儲位置 |
|------|-------|---------|
| `-s user` | 全域 (所有專案) | `~/.claude.json` |
| `-s local` | 當前專案 (個人) | `.claude/settings.local.json` (gitignored) |
| `-s project` | 當前專案 (團隊共享) | `.claude/settings.json` (git 追踪) |

### 列印/CI 模式中的 MCP
```
terminal(command="claude --bare -p 'Query database' --mcp-config mcp-servers.json --strict-mcp-config", timeout=60)
```
`--strict-mcp-config` 忽略除了 `--mcp-config` 指定的以外的所有 MCP 伺服器。

在對話中引用 MCP 資源：`@github:issue://123`

### MCP 限制與調優
- **工具描述：** 每個伺服器的工具描述和伺服器指令上限為 2KB
- **結果大小：** 預設有限制；使用 `maxResultSizeChars` 註解可允許大型輸出高達 **50 萬**個字元
- **輸出權杖：** `export MAX_MCP_OUTPUT_TOKENS=50000` — 限制來自 MCP 伺服器的輸出以防止上下文溢出
- **傳輸協議：** `stdio` (本地程序), `http` (遠程), `sse` (伺服器發送事件)

## 監控交互式會話

### 讀取 TUI 狀態
```
# 定期捕捉以檢查 Claude 是否仍在工作或正在等待輸入
terminal(command="tmux capture-pane -t dev -p -S -10")
```

查找以下指標：
- 底部出現 `❯` = 正在等待您的輸入 (Claude 已完成或正在提問)
- `●` 行 = Claude 正在活躍地使用工具 (讀取、寫入、運行命令)
- `⏵⏵ bypass permissions on` = 狀態列顯示權限模式
- `◐ medium · /effort` = 狀態列中當前的推理強度
- `ctrl+o to expand` = 工具輸出被截斷 (可以交互式展開)

### 上下文視窗健康度
在交互模式下使用 `/context` 查看上下文使用情況的彩色網格。關鍵閾值：
- **< 70%** — 正常運行，全精度
- **70-85%** — 精度開始下降，考慮使用 `/compact`
- **> 85%** — 幻覺風險顯著增加，請使用 `/compact` 或 `/clear`

## 環境變數

| 變數 | 效果 |
|----------|--------|
| `ANTHROPIC_API_KEY` | 用於身份驗證的 API 金鑰 (OAuth 的替代方案) |
| `CLAUDE_CODE_EFFORT_LEVEL` | 預設推理強度：`low`, `medium`, `high`, `max`, 或 `auto` |
| `MAX_THINKING_TOKENS` | 限制思考權杖數量 (設置為 `0` 以完全禁用思考) |
| `MAX_MCP_OUTPUT_TOKENS` | 限制來自 MCP 伺服器的輸出 (預設值不一；例如設置為 `50000`) |
| `CLAUDE_CODE_NO_FLICKER=1` | 啟用替代畫面渲染以消除終端閃爍 |
| `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` | 從子程序中清除憑據以確保安全 |

## 成本與效能建議

1. **在列印模式下使用 `--max-turns`** 以防止無限循環。大多數任務建議從 5-10 開始。
2. **使用 `--max-budget-usd`** 限制成本。注意：系統提示詞快取創建至少需要約 0.05 美金。
3. **對於簡單任務使用 `--effort low`** (更快速、更便宜)。對於複雜推理使用 `high` 或 `max`。
4. **對於 CI/腳本使用 `--bare`** 以跳過插件/鉤子發現的開銷。
5. **使用 `--allowedTools`** 將權限限制在僅需範圍內 (例如審查時僅需 `Read`)。
6. **當上下文變大時**，在交互式會話中使用 `/compact`。
7. **當您僅需分析已知內容時**，直接傳輸輸入而非讓 Claude 讀取文件。
8. **簡單任務使用 `--model haiku`** (更便宜)，複雜的多步工作使用 `--model opus`。
9. **列印模式下使用 `--fallback-model haiku`** 以優雅地處理模型過載。
10. **為不同任務啟動新會話** — 會話可持續 5 小時；全新的上下文更有效率。
11. **在 CI 中使用 `--no-session-persistence`** 以避免在磁碟上累積保存的會話。

## 常見陷阱與注意事項

1. **交互模式需要 tmux** — Claude Code 是一個完整的 TUI 應用程式。在 Hermes 終端中僅使用 `pty=true` 雖然可行，但 tmux 為您提供了用於監控的 `capture-pane` 和用於輸入的 `send-keys`，這對於編排至關重要。
2. **`--dangerously-skip-permissions` 對話框預設為 "No, exit"** — 您必須發送 Down 然後按 Enter 才能接受。列印模式 (`-p`) 則會完全跳過此過程。
3. **`--max-budget-usd` 的最小值約為 0.05 美金** — 僅系統提示詞快取創建就需此成本。設置更低將立即報錯。
4. **`--max-turns` 僅限列印模式** — 在交互式會話中會被忽略。
5. **Claude 可能會使用 `python` 而非 `python3`** — 在沒有 `python` 軟連結的系統上，Claude 的 bash 命令在第一次嘗試時會失敗，但它會自我修正。
6. **會話恢復需要相同目錄** — `--continue` 會查找當前工作目錄最近的會話。
7. **`--json-schema` 需要足夠的 `--max-turns`** — Claude 在生成結構化輸出前必須先讀取文件，這需要多輪對話。
8. **信任對話框每個目錄僅出現一次** — 僅限首次，之後會被快取。
9. **後台 tmux 會話會持續存在** — 完成後務必使用 `tmux kill-session -t <name>` 清理。
10. **斜槓命令 (如 `/commit`) 僅在交互模式下有效** — 在 `-p` 模式下，請改用自然語言描述任務。
11. **`--bare` 會跳過 OAuth** — 需要 `ANTHROPIC_API_KEY` 環境變數或設置中的 `apiKeyHelper`。
12. **上下文退化是真實存在的** — 當上下文視窗使用率超過 70% 時，AI 輸出質量會明顯下降。請使用 `/context` 監控並主動 `/compact`。

## 給 Hermes 代理的規則

1. **對於單個任務，優先使用列印模式 (`-p`)** — 更簡潔、無需對話處理、結構化輸出。
2. **對於多輪交互式工作，使用 tmux** — 這是編排 TUI 的唯一可靠方式。
3. **始終設置 `workdir`** — 讓 Claude 專注於正確的專案目錄。
4. **在列印模式下設置 `--max-turns`** — 防止無限循環和成本失控。
5. **監控 tmux 會話** — 使用 `tmux capture-pane -t <session> -p -S -50` 檢查進度。
6. **尋找 `❯` 提示符** — 表示 Claude 正在等待輸入 (已完成或正在提問)。
7. **清理 tmux 會話** — 完成後將其殺死以避免資源洩漏。
8. **向使用者報告結果** — 完成後，總結 Claude 的工作內容及變動。
9. **不要殺死緩慢的會話** — Claude 可能正在進行多步工作；請改為檢查進度。
10. **使用 `--allowedTools`** — 將功能限制在任務實際需要的範圍內。
