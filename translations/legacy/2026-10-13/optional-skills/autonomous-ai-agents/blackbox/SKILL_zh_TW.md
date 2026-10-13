---
name: blackbox
description: 將程式設計任務委派給 Blackbox AI CLI 代理人。這是一個多模型代理人，內建評審功能，可讓任務在多個 LLM 上執行並挑選最佳結果。需要 blackbox CLI 和 Blackbox AI API 金鑰。
version: 1.0.0
author: Hermes Agent (Nous Research)
license: MIT
metadata:
  hermes:
    tags: [程式設計代理人, Blackbox, 多代理人, 評審, 多模型]
    related_skills: [claude-code, codex, hermes-agent]
---

# Blackbox CLI

透過 Hermes 終端機將程式設計任務委派給 [Blackbox AI](https://www.blackbox.ai/)。Blackbox 是一個多模型程式設計代理人 CLI，它將任務分發給多個 LLM (Claude, Codex, Gemini, Blackbox Pro)，並使用評審 (judge) 來選擇最佳實作。

該 CLI 是[開源的](https://github.com/blackboxaicode/cli) (GPL-3.0, TypeScript, 分叉自 Gemini CLI)，支援互動式工作階段、非互動式一次性任務、檢查點、MCP 和視覺模型切換。

## 先決條件

- 已安裝 Node.js 20+
- 已安裝 Blackbox CLI：`npm install -g @blackboxai/cli`
- 或從原始碼安裝：
  ```
  git clone https://github.com/blackboxaicode/cli.git
  cd cli && npm install && npm install -g .
  ```
- 從 [app.blackbox.ai/dashboard](https://app.blackbox.ai/dashboard) 獲取 API 金鑰
- 已設定：執行 `blackbox configure` 並輸入您的 API 金鑰
- 在終端機呼叫中使用 `pty=true` — Blackbox CLI 是一個互動式終端機應用程式

## 一次性任務 (One-Shot)

```
terminal(command="blackbox --prompt '為 Express API 加入帶有重刷權杖 (refresh tokens) 的 JWT 驗證'", workdir="/path/to/project", pty=true)
```

快速臨時作業：
```
terminal(command="cd $(mktemp -d) && git init && blackbox --prompt '使用 SQLite 建置一個待辦事項 REST API'", pty=true)
```

## 背景模式 (長時間任務)

對於需要幾分鐘才能完成的任務，請使用背景模式，以便監控進度：

```
# 以 PTY 在背景啟動
terminal(command="blackbox --prompt '將驗證模組重構為使用 OAuth 2.0'", workdir="~/project", background=true, pty=true)
# 返回 session_id

# 監控進度
process(action="poll", session_id="<id>")
process(action="log", session_id="<id>")

# 如果 Blackbox 提出問題，則提交輸入
process(action="submit", session_id="<id>", data="yes")

# 必要時刪除
process(action="kill", session_id="<id>")
```

## 檢查點與恢復 (Checkpoints & Resume)

Blackbox CLI 內建檢查點支援，可用於暫停和恢復任務：

```
# 任務完成後，Blackbox 會顯示檢查點標籤
# 使用後續任務恢復：
terminal(command="blackbox --resume-checkpoint 'task-abc123-2026-03-06' --prompt '現在為端點加入速率限制'", workdir="~/project", pty=true)
```

## 工作階段命令

在互動式工作階段期間，使用以下命令：

| 命令 | 效果 |
|---------|--------|
| `/compress` | 縮減對話歷史以節省權杖 |
| `/clear` | 清除歷史並重新開始 |
| `/stats` | 查看當前的權杖使用情況 |
| `Ctrl+C` | 取消當前操作 |

## PR 審查 (PR Reviews)

複製到臨時目錄以避免修改工作樹：

```
terminal(command="REVIEW=$(mktemp -d) && git clone https://github.com/user/repo.git $REVIEW && cd $REVIEW && gh pr checkout 42 && blackbox --prompt '根據 main 審查此 PR。檢查是否存在 Bug、安全性問題和程式碼品質。'", pty=true)
```

## 平行作業

針對獨立任務啟動多個 Blackbox 實例：

```
terminal(command="blackbox --prompt '修復登入 Bug'", workdir="/tmp/issue-1", background=true, pty=true)
terminal(command="blackbox --prompt '為驗證加入單元測試'", workdir="/tmp/issue-2", background=true, pty=true)

# 監控所有任務
process(action="list")
```

## 多模型模式

Blackbox 的獨特功能是透過多個模型執行同一項任務並對結果進行評審。透過 `blackbox configure` 設定要使用的模型 — 選擇多個供應商以啟用主席/評審 (Chairman/judge) 工作流程，CLI 會在此流程中評估來自不同模型的輸出並挑選最佳的一個。

## 關鍵旗標

| 旗標 | 效果 |
|------|--------|
| `--prompt "任務"` | 非互動式一次性執行 |
| `--resume-checkpoint "標籤"` | 從儲存的檢查點恢復 |
| `--yolo` | 自動核准所有操作和模型切換 |
| `blackbox session` | 啟動互動式聊天工作階段 |
| `blackbox configure` | 變更設定、供應商、模型 |
| `blackbox info` | 顯示系統資訊 |

## 視覺支援 (Vision Support)

Blackbox 會自動偵測輸入中的圖片並可切換至多模態分析。VLM 模式：
- `"once"` — 僅針對當前查詢切換模型
- `"session"` — 針對整個工作階段切換
- `"persist"` — 保持當前模型 (不切換)

## 權杖限制

透過 `.blackboxcli/settings.json` 控制權杖使用：
```json
{
  "sessionTokenLimit": 32000
}
```

## 規則

1. **務必使用 `pty=true`** — Blackbox CLI 是一個互動式終端機應用程式，若無 PTY 則會掛起。
2. **使用 `workdir`** — 讓代理人專注於正確的目錄。
3. **長時間任務使用背景模式** — 使用 `background=true` 並透過 `process` 工具監控。
4. **不要干預** — 透過 `poll`/`log` 監控，不要因為工作階段慢就將其刪除。
5. **報告結果** — 完成後，檢查變更內容並為使用者總結。
6. **點數成本** — Blackbox 使用點數制度；多模型模式消耗點數較快。
7. **檢查先決條件** — 在嘗試委派前驗證是否已安裝 `blackbox` CLI。
