---
name: codex
description: 將編碼任務委派給 OpenAI Codex CLI 代理。可用於功能開發、重構、PR 審查和批量修復問題。需要安裝 codex CLI 及具備 git 倉庫。
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [Coding-Agent, Codex, OpenAI, Code-Review, Refactoring]
    related_skills: [claude-code, hermes-agent]
---

# Codex CLI

透過 Hermes 終端將編碼任務委派給 [Codex](https://github.com/openai/codex)。Codex 是 OpenAI 的自主編碼代理 CLI。

## 前置條件

- 已安裝 Codex：`npm install -g @openai/codex`
- 已配置 OpenAI API 金鑰
- **必須在 git 倉庫內運行** —— Codex 拒絕在倉庫外運行
- 在終端調用中使用 `pty=true` —— Codex 是一個交互式終端應用程序

## 單次任務

```
terminal(command="codex exec 'Add dark mode toggle to settings'", workdir="~/project", pty=true)
```

對於臨時工作 (Codex 需要 git 倉庫)：
```
terminal(command="cd $(mktemp -d) && git init && codex exec 'Build a snake game in Python'", pty=true)
```

## 後台模式 (長時間任務)

```
# 以 PTY 在後台啟動
terminal(command="codex exec --full-auto 'Refactor the auth module'", workdir="~/project", background=true, pty=true)
# 返回 session_id

# 監控進度
process(action="poll", session_id="<id>")
process(action="log", session_id="<id>")

# 如果 Codex 提問，發送輸入
process(action="submit", session_id="<id>", data="yes")

# 如果需要，終止進程
process(action="kill", session_id="<id>")
```

## 關鍵標籤

| 標籤 | 效果 |
|------|--------|
| `exec "prompt"` | 單次執行，完成後退出 |
| `--full-auto` | 在沙盒中運行，但自動批准工作區中的文件更改 |
| `--yolo` | 無沙盒，無需批准 (最快但也最危險) |

## PR 審查

將其克隆到臨時目錄以進行安全審查：

```
terminal(command="REVIEW=$(mktemp -d) && git clone https://github.com/user/repo.git $REVIEW && cd $REVIEW && gh pr checkout 42 && codex review --base origin/main", pty=true)
```

## 使用工作樹平行修復問題

```
# 創建工作樹
terminal(command="git worktree add -b fix/issue-78 /tmp/issue-78 main", workdir="~/project")
terminal(command="git worktree add -b fix/issue-99 /tmp/issue-99 main", workdir="~/project")

# 在每個工作樹中啟動 Codex
terminal(command="codex --yolo exec 'Fix issue #78: <description>. Commit when done.'", workdir="/tmp/issue-78", background=true, pty=true)
terminal(command="codex --yolo exec 'Fix issue #99: <description>. Commit when done.'", workdir="/tmp/issue-99", background=true, pty=true)

# 監控
process(action="list")

# 完成後，推送到遠端並創建 PR
terminal(command="cd /tmp/issue-78 && git push -u origin fix/issue-78")
terminal(command="gh pr create --repo user/repo --head fix/issue-78 --title 'fix: ...' --body '...'")

# 清理
terminal(command="git worktree remove /tmp/issue-78", workdir="~/project")
```

## 批量 PR 審查

```
# 獲取所有 PR 引用 (refs)
terminal(command="git fetch origin '+refs/pull/*/head:refs/remotes/origin/pr/*'", workdir="~/project")

# 平行審查多個 PR
terminal(command="codex exec 'Review PR #86. git diff origin/main...origin/pr/86'", workdir="~/project", background=true, pty=true)
terminal(command="codex exec 'Review PR #87. git diff origin/main...origin/pr/87'", workdir="~/project", background=true, pty=true)

# 發布結果
terminal(command="gh pr comment 86 --body '<review>'", workdir="~/project")
```

## 規則

1. **務必使用 `pty=true`** —— Codex 是一個交互式終端應用程序，如果沒有 PTY 會掛起
2. **需要 Git 倉庫** —— Codex 無法在 git 目錄外運行。對於臨時工作，請使用 `mktemp -d && git init`
3. **單次任務使用 `exec`** —— `codex exec "prompt"` 運行後會正常退出
4. **構建時使用 `--full-auto`** —— 會自動批准沙盒內的更改
5. **長時間任務使用後台模式** —— 使用 `background=true` 並透過 `process` 工具監控
6. **不要干預** —— 透過 `poll`/`log` 監控，對長時間運行的任務保持耐心
7. **可以平行運行** —— 可以同時運行多個 Codex 進程進行批量工作
