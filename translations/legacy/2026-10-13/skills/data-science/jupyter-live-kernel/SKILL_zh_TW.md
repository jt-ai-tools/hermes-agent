---
name: jupyter-live-kernel
description: >
  使用 live Jupyter kernel 透過 hamelnb 進行具狀態、迭代的 Python 執行。
  當任務涉及探索、迭代或檢查中間結果（如資料科學、機器學習實驗、API 探索或
  逐步建構複雜程式碼）時，載入此技能。使用終端機針對 live Jupyter kernel 
  執行 CLI 命令。無需新工具。
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [jupyter, notebook, repl, data-science, exploration, iterative]
    category: data-science
---

# Jupyter Live Kernel (hamelnb)

透過 live Jupyter kernel 提供**具狀態的 Python REPL**。變數在各次執行之間會持續存在。
當您需要逐步建構狀態、探索 API、檢查 DataFrame 或迭代複雜程式碼時，請使用此技能而非 `execute_code`。

## 何時使用此技能與其他工具

| 工具 | 使用時機 |
|------|----------|
| **此技能** | 迭代探索、跨步驟保存狀態、資料科學、機器學習、「讓我試試這個並檢查」 |
| `execute_code` | 需要存取 hermes 工具（網頁搜尋、檔案操作）的一次性腳本。無狀態。 |
| `terminal` | Shell 命令、建構、安裝、git、程序管理 |

**經驗法則：** 如果您希望使用 Jupyter 筆記本來處理該任務，請使用此技能。

## 先決條件

1. 必須安裝 **uv**（檢查方式：`which uv`）
2. 必須安裝 **JupyterLab**：`uv tool install jupyterlab`
3. 必須正在執行 Jupyter 伺服器（請參閱下方的設定）

## 設定

hamelnb 腳本位置：
```
SCRIPT="$HOME/.agent-skills/hamelnb/skills/jupyter-live-kernel/scripts/jupyter_live_kernel.py"
```

如果尚未複製 (clone)：
```
git clone https://github.com/hamelsmu/hamelnb.git ~/.agent-skills/hamelnb
```

### 啟動 JupyterLab

檢查伺服器是否已在執行：
```
uv run "$SCRIPT" servers
```

如果未找到伺服器，請啟動一個：
```
jupyter-lab --no-browser --port=8888 --notebook-dir=$HOME/notebooks \
  --IdentityProvider.token='' --ServerApp.password='' > /tmp/jupyter.log 2>&1 &
sleep 3
```

注意：為方便本地代理存取，已停用 Token/密碼。伺服器以 headless 模式執行。

### 建立用於 REPL 的筆記本

如果您只需要 REPL（無現有筆記本），請建立一個極簡的筆記本檔案：
```
mkdir -p ~/notebooks
```
編寫一個包含一個空程式碼單元格的極簡 .ipynb JSON 檔案，然後透過 Jupyter REST API 啟動 kernel 會話：
```
curl -s -X POST http://127.0.0.1:8888/api/sessions \
  -H "Content-Type: application/json" \
  -d '{"path":"scratch.ipynb","type":"notebook","name":"scratch.ipynb","kernel":{"name":"python3"}}'
```

## 核心工作流

所有命令皆返回結構化 JSON。務必使用 `--compact` 以節省 Token。

### 1. 發現伺服器與筆記本

```
uv run "$SCRIPT" servers --compact
uv run "$SCRIPT" notebooks --compact
```

### 2. 執行程式碼（主要操作）

```
uv run "$SCRIPT" execute --path <notebook.ipynb> --code '<python code>' --compact
```

狀態在各次 execute 呼叫之間持續存在。變數、導入、物件皆會保留。

多行程式碼可使用 $'...' 引號：
```
uv run "$SCRIPT" execute --path scratch.ipynb --code $'import os\nfiles = os.listdir(".")\nprint(f"Found {len(files)} files")' --compact
```

### 3. 檢查即時變數

```
uv run "$SCRIPT" variables --path <notebook.ipynb> list --compact
uv run "$SCRIPT" variables --path <notebook.ipynb> preview --name <varname> --compact
```

### 4. 編輯筆記本單元格

```
# 查看目前單元格
uv run "$SCRIPT" contents --path <notebook.ipynb> --compact

# 插入新單元格
uv run "$SCRIPT" edit --path <notebook.ipynb> insert \
  --at-index <N> --cell-type code --source '<code>' --compact

# 替換單元格原始碼（使用來自 contents 輸出的 cell-id）
uv run "$SCRIPT" edit --path <notebook.ipynb> replace-source \
  --cell-id <id> --source '<new code>' --compact

# 刪除單元格
uv run "$SCRIPT" edit --path <notebook.ipynb> delete --cell-id <id> --compact
```

### 5. 驗證（重啟並全部執行）

僅當使用者要求全新驗證或您需要確認筆記本能從頭到尾執行時使用：

```
uv run "$SCRIPT" restart-run-all --path <notebook.ipynb> --save-outputs --compact
```

## 實務經驗提示

1. **伺服器啟動後的第一次執行可能會逾時** — kernel 需要一點時間初始化。如果遇到逾時，請重試即可。

2. **Kernel Python 即為 JupyterLab 的 Python** — 套件必須安裝在該環境中。如果您需要額外套件，請先將其安裝至 JupyterLab 工具環境中。

3. **--compact 旗標能顯著節省 Token** — 請務必使用。若不使用，JSON 輸出可能會非常冗長。

4. **若純粹作為 REPL 使用**，請建立一個 scratch.ipynb 且無需理會單元格編輯，只需重複使用 `execute` 即可。

5. **參數順序很重要** — 子命令旗標（如 `--path`）應置於子子命令之前。例如：`variables --path nb.ipynb list` 而非 `variables list --path nb.ipynb`。

6. **如果會話尚未存在**，您需要透過 REST API 啟動一個（參閱設定章節）。若無 live kernel 會話，工具將無法執行。

7. **錯誤以帶有 traceback 的 JSON 格式返回** — 閱讀 `ename` 和 `evalue` 欄位以了解錯誤原因。

8. **偶爾會出現 websocket 逾時** — 某些操作在第一次嘗試時可能會逾時，特別是在 kernel 重啟後。在呈報問題前請先重試一次。

## 逾時預設值

該腳本每次執行的預設逾時為 30 秒。對於長時間運行的操作，請傳遞 `--timeout 120`。在初始設定或大量運算時，請使用寬裕的逾時設定（60 秒以上）。
