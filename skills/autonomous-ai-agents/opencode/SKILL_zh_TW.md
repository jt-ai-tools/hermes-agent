---
name: opencode
description: 將編碼任務委派給 OpenCode CLI 代理，用於功能實現、重構、PR 審查和長時間運行的自主會話。需要安裝並驗證 OpenCode CLI。
version: 1.2.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [Coding-Agent, OpenCode, Autonomous, Refactoring, Code-Review]
    related_skills: [claude-code, codex, hermes-agent]
---

# OpenCode CLI

使用 [OpenCode](https://opencode.ai) 作為由 Hermes 終端/進程工具編排的自主編碼工人。OpenCode 是一個提供商無關的開源 AI 編碼代理，具有 TUI 和 CLI。

## 何時使用

- 使用者明確要求使用 OpenCode
- 您希望使用外部編碼代理來實現/重構/審查程式碼
- 您需要帶有進度檢查的長時間運行編碼會話
- 您希望在隔離的工作目錄/工作樹中平行執行任務

## 前置條件

- 已安裝 OpenCode：`npm i -g opencode-ai@latest` 或 `brew install anomalyco/tap/opencode`
- 已配置身份驗證 (Auth)：`opencode auth login` 或設置提供商環境變數 (OPENROUTER_API_KEY 等)
- 驗證：`opencode auth list` 應顯示至少一個提供商
- 用於程式碼任務的 Git 倉庫 (推薦)
- 交互式 TUI 會話使用 `pty=true`

## 二進制文件解析 (重要)

Shell 環境可能會解析出不同的 OpenCode 二進制文件。如果您的終端與 Hermes 之間的行為不一致，請檢查：

```
terminal(command="which -a opencode")
terminal(command="opencode --version")
```

如果需要，請指定明確的二進制路徑：

```
terminal(command="$HOME/.opencode/bin/opencode run '...'", workdir="~/project", pty=true)
```

## 單次任務

對於有界、非交互式的任務，使用 `opencode run`：

```
terminal(command="opencode run 'Add retry logic to API calls and update tests'", workdir="~/project")
```

使用 `-f` 附加上下文文件：

```
terminal(command="opencode run 'Review this config for security issues' -f config.yaml -f .env.example", workdir="~/project")
```

使用 `--thinking` 顯示模型思考過程：

```
terminal(command="opencode run 'Debug why tests fail in CI' --thinking", workdir="~/project")
```

強制使用特定模型：

```
terminal(command="opencode run 'Refactor auth module' --model openrouter/anthropic/claude-sonnet-4", workdir="~/project")
```

## 交互式會話 (後台運行)

對於需要多次交換的迭代工作，在後台啟動 TUI：

```
terminal(command="opencode", workdir="~/project", background=true, pty=true)
# 返回 session_id

# 發送提示詞
process(action="submit", session_id="<id>", data="Implement OAuth refresh flow and add tests")

# 監控進度
process(action="poll", session_id="<id>")
process(action="log", session_id="<id>")

# 發送後續輸入
process(action="submit", session_id="<id>", data="Now add error handling for token expiry")

# 清爽退出 —— Ctrl+C
process(action="write", session_id="<id>", data="\x03")
# 或直接終止進程
process(action="kill", session_id="<id>")
```

**重要提示：** 不要使用 `/exit` —— 它不是有效的 OpenCode 命令，而是會打開代理選擇器對話框。請使用 Ctrl+C (`\x03`) 或 `process(action="kill")` 退出。

### TUI 快捷鍵

| 按鍵 | 動作 |
|-----|--------|
| `Enter` | 提交訊息 (如有需要請按兩次) |
| `Tab` | 在代理之間切換 (build/plan) |
| `Ctrl+P` | 打開命令面板 |
| `Ctrl+X L` | 切換會話 |
| `Ctrl+X M` | 切換模型 |
| `Ctrl+X N` | 新會話 |
| `Ctrl+X E` | 打開編輯器 |
| `Ctrl+C` | 退出 OpenCode |

### 恢復會話

退出後，OpenCode 會列印會話 ID。恢復方式如下：

```
terminal(command="opencode -c", workdir="~/project", background=true, pty=true)  # 繼續上次會話
terminal(command="opencode -s ses_abc123", workdir="~/project", background=true, pty=true)  # 特定會話
```

## 常見標籤

| 標籤 | 用法 |
|------|-----|
| `run 'prompt'` | 單次執行並退出 |
| `--continue` / `-c` | 繼續上次的 OpenCode 會話 |
| `--session <id>` / `-s` | 繼續特定會話 |
| `--agent <name>` | 選擇 OpenCode 代理 (build 或 plan) |
| `--model provider/model` | 強制指定模型 |
| `--format json` | 機器可讀的輸出/事件 |
| `--file <path>` / `-f` | 在訊息中附加文件 |
| `--thinking` | 顯示模型思考塊 |
| `--variant <level>` | 推理強度 (high, max, minimal) |
| `--title <name>` | 為會話命名 |
| `--attach <url>` | 連接到正在運行的 OpenCode 伺服器 |

## 程序步驟

1. 驗證工具就緒情況：
   - `terminal(command="opencode --version")`
   - `terminal(command="opencode auth list")`
2. 對於有界任務，使用 `opencode run '...'` (不需要 pty)。
3. 對於迭代任務，使用 `background=true, pty=true` 啟動 `opencode`。
4. 使用 `process(action="poll"|"log")` 監控長時間任務。
5. 如果 OpenCode 請求輸入，透過 `process(action="submit", ...)` 回應。
6. 使用 `process(action="write", data="\x03")` 或 `process(action="kill")` 退出。
7. 向使用者總結文件更改、測試結果和後續步驟。

## PR 審查工作流

OpenCode 有內置的 PR 命令：

```
terminal(command="opencode pr 42", workdir="~/project", pty=true)
```

或在臨時克隆的環境中進行隔離審查：

```
terminal(command="REVIEW=$(mktemp -d) && git clone https://github.com/user/repo.git $REVIEW && cd $REVIEW && opencode run 'Review this PR vs main. Report bugs, security risks, test gaps, and style issues.' -f $(git diff origin/main --name-only | head -20 | tr '\n' ' ')", pty=true)
```

## 平行工作模式

使用獨立的工作目錄/工作樹以避免衝突：

```
terminal(command="opencode run 'Fix issue #101 and commit'", workdir="/tmp/issue-101", background=true, pty=true)
terminal(command="opencode run 'Add parser regression tests and commit'", workdir="/tmp/issue-102", background=true, pty=true)
process(action="list")
```

## 會話與成本管理

列出過去的會話：

```
terminal(command="opencode session list")
```

檢查權杖使用情況和成本：

```
terminal(command="opencode stats")
terminal(command="opencode stats --days 7 --models anthropic/claude-sonnet-4")
```

## 陷阱

- 交互式 `opencode` (TUI) 會話需要 `pty=true`。`opencode run` 命令不需要 pty。
- `/exit` 不是有效的命令 —— 它會打開代理選擇器。請使用 Ctrl+C 退出 TUI。
- PATH 不匹配可能會選錯 OpenCode 二進制文件/模型配置。
- 如果 OpenCode 看起來卡住了，請在終止前檢查日誌：
  - `process(action="log", session_id="<id>")`
- 避免在平行 OpenCode 會話中共享同一個工作目錄。
- 在 TUI 中可能需要按兩次 Enter 才能提交 (一次完成文本，一次發送)。

## 驗證

冒煙測試：

```
terminal(command="opencode run 'Respond with exactly: OPENCODE_SMOKE_OK'")
```

成功標準：
- 輸出包含 `OPENCODE_SMOKE_OK`
- 命令退出且無提供商/模型錯誤
- 對於程式碼任務：預期文件已更改且測試通過

## 規則

1. 單次自動化任務優先使用 `opencode run` —— 它更簡單且不需要 pty。
2. 僅在需要迭代時使用交互式後台模式。
3. 始終將 OpenCode 會話限定在單個倉庫/工作目錄中。
4. 對於長任務，從 `process` 日誌中提供進度更新。
5. 報告具體成果 (更改的文件、測試、剩餘風險)。
6. 使用 Ctrl+C 或 kill 退出交互式會話，切勿使用 `/exit`。
