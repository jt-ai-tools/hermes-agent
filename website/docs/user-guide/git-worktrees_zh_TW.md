---
sidebar_position: 3
sidebar_label: "Git 工作樹 (Git Worktrees)"
title: "Git 工作樹 (Git Worktrees)"
description: "使用 Git 工作樹與隔離的檢出，在同一個儲存庫上安全地執行多個 Hermes 代理程式"
---

# Git 工作樹 (Git Worktrees)

Hermes Agent 經常被用於大型且長期的專案儲存庫。當你想要執行以下操作時：

- 在同一個專案上**並行執行多個代理程式**，或
- 保持實驗性的重構與主分支隔離，

Git **工作樹 (Worktrees)** 是為每個代理程式提供獨立檢出最安全的方法，而無需複製整個儲存庫。

本頁面將展示如何將工作樹與 Hermes 結合使用，使每個對話會話都擁有一個乾淨、隔離的工作目錄。

## 為什麼要在 Hermes 中使用工作樹？

Hermes 將**當前工作目錄**視為專案根目錄：

- CLI：你執行 `hermes` 或 `hermes chat` 的目錄
- 通訊網關：由 `MESSAGING_CWD` 設定的目錄

如果你在**同一個檢出目錄**中執行多個代理程式，它們的變更可能會互相干擾：

- 一個代理程式可能會刪除或重寫另一個代理程式正在使用的檔案。
- 很難釐清哪些變更屬於哪一個實驗。

透過工作樹，每個代理程式都能獲得：

- 自己的**分支與工作目錄**
- 自己的**檢查點管理員 (Checkpoint Manager) 歷史紀錄**，用於執行 `/rollback`

另請參閱：[檢查點與 /rollback](./checkpoints-and-rollback.md)。

## 快速入門：建立工作樹

在你的主儲存庫 (包含 `.git/` 的目錄) 中，為一個功能分支建立新的工作樹：

```bash
# 從主儲存庫根目錄開始
cd /path/to/your/repo

# 建立新分支，並在 ../repo-feature 中建立工作樹
git worktree add ../repo-feature feature/hermes-experiment
```

這會建立：

- 一個新目錄：`../repo-feature`
- 一個檢出至該目錄的新分支：`feature/hermes-experiment`

現在你可以進入新的工作樹目錄並在那裡執行 Hermes：

```bash
cd ../repo-feature

# 在工作樹中啟動 Hermes
hermes
```

Hermes 將會：

- 將 `../repo-feature` 視為專案根目錄。
- 使用該目錄進行上下文檔案讀取、程式碼編輯與工具執行。
- 使用**獨立的檢查點歷史紀錄**來執行侷限於此工作樹的 `/rollback`。

## 並行執行多個代理程式

你可以建立多個工作樹，每個工作樹都有自己的分支：

```bash
cd /path/to/your/repo

git worktree add ../repo-experiment-a feature/hermes-a
git worktree add ../repo-experiment-b feature/hermes-b
```

在不同的終端機視窗中：

```bash
# 終端機 1
cd ../repo-experiment-a
hermes

# 終端機 2
cd ../repo-experiment-b
hermes
```

每個 Hermes 進程：

- 在各自的分支上工作 (`feature/hermes-a` 對比 `feature/hermes-b`)。
- 將檢查點寫入不同的陰影儲存庫雜湊值下 (根據工作樹路徑生成)。
- 可以獨立使用 `/rollback` 而不影響其他進程。

這在以下情況特別有用：

- 執行批次重構。
- 對同一項任務嘗試不同的方法。
- 針對同一個上游儲存庫同時使用 CLI 與網關對話。

## 安全地清理工作樹

當你完成實驗後：

1. 決定保留或捨棄這些工作。
2. 若要保留：
   - 像往常一樣將分支合併回主分支。
3. 移除工作樹：

```bash
cd /path/to/your/repo

# 移除工作樹目錄及其引用
git worktree remove ../repo-feature
```

注意：

- 除非使用強制參數，否則 `git worktree remove` 會拒絕移除包含未提交變更的工作樹。
- 移除工作樹**不會**自動刪除分支；你可以使用正常的 `git branch` 指令來刪除或保留分支。
- 儲存在 `~/.hermes/checkpoints/` 下的 Hermes 檢查點資料在移除工作樹時不會自動清除，但通常這些資料佔用的空間非常小。

## 最佳實踐

- **每個 Hermes 實驗使用一個工作樹**
  - 為每項重大的變更建立專屬的分支/工作樹。
  - 這能保持差異 (Diff) 焦點明確，並使 PR (拉取請求) 體積小且易於審閱。
- **依實驗內容命名分支**
  - 例如：`feature/hermes-checkpoints-docs`、`feature/hermes-refactor-tests`。
- **頻繁提交**
  - 使用 Git 提交 (Commit) 來標記高層級的里程碑。
  - 使用[檢查點與 /rollback](./checkpoints-and-rollback.md) 作為兩次提交之間工具導向編輯的安全網。
- **使用工作樹時避免在裸儲存庫根目錄執行 Hermes**
  - 優先使用工作樹目錄，讓每個代理程式都有明確的作用域。

## 使用 `hermes -w` (自動工作樹模式)

Hermes 具備內建的 `-w` 旗標，可**自動建立一個臨時的 Git 工作樹**及其分支。你不需要手動設定工作樹 —— 只需進入你的儲存庫並執行：

```bash
cd /path/to/your/repo
hermes -w
```

Hermes 將會：

- 在你的儲存庫內部的 `.worktrees/` 下建立一個臨時工作樹。
- 檢出一個隔離的分支 (例如 `hermes/hermes-<hash>`)。
- 在該工作樹中執行完整的 CLI 對話。

這是獲得工作樹隔離最簡單的方法。你也可以將其與單一查詢結合使用：

```bash
hermes -w -q "Fix issue #123"
```

若要並行執行多個代理程式，只需開啟多個終端機並在每個終端機中執行 `hermes -w` —— 每次調用都會自動獲得獨立的工作樹與分支。

## 總結

- 使用 **Git 工作樹** 為每個 Hermes 對話提供乾淨且隔離的檢出環境。
- 使用 **分支 (Branches)** 來記錄實驗的高層級歷史。
- 使用 **檢查點 (Checkpoints) 與 `/rollback`** 來修復每個工作樹內部的編輯錯誤。

這種組合為你提供了：

- 強力的保證：不同的代理程式與實驗不會互相干擾。
- 快速的迭代週期：輕鬆從錯誤的編輯中恢復。
- 乾淨且易於審閱的拉取請求 (PR)。
