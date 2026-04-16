---
name: codebase-inspection
description: 使用 pygount 檢查並分析程式碼庫，以統計程式碼行數 (LOC)、語言細目以及程式碼與註釋的比例。當被要求檢查程式碼行數、儲存庫大小、語言組成或程式碼庫統計數據時使用。
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [LOC, Code Analysis, pygount, Codebase, Metrics, Repository]
    related_skills: [github-repo-management]
prerequisites:
  commands: [pygount]
---

# 使用 pygount 進行程式碼庫檢查

使用 `pygount` 分析儲存庫的程式碼行數、語言細目、檔案計數以及程式碼與註釋的比例。

## 何時使用

- 使用者要求統計 LOC (程式碼行數)
- 使用者想要了解儲存庫的語言細目
- 使用者詢問關於程式碼庫大小或組成
- 使用者想要程式碼與註釋的比例
- 一般性的 「這個儲存庫有多大」 的問題

## 準備工作

```bash
pip install --break-system-packages pygount 2>/dev/null || pip install pygount
```

## 1. 基本摘要 (最常用)

獲取完整的語言細目，包括檔案數量、程式碼行數和註釋行數：

```bash
cd /path/to/repo
pygount --format=summary \
  --folders-to-skip=".git,node_modules,venv,.venv,__pycache__,.cache,dist,build,.next,.tox,.eggs,*.egg-info" \
  .
```

**重要提示：** 務必使用 `--folders-to-skip` 來排除依賴項目或構建目錄，否則 pygount 會掃描它們，導致耗時極長甚至當機。

## 2. 常見排除資料夾

根據專案類型進行調整：

```bash
# Python 專案
--folders-to-skip=".git,venv,.venv,__pycache__,.cache,dist,build,.tox,.eggs,.mypy_cache"

# JavaScript/TypeScript 專案
--folders-to-skip=".git,node_modules,dist,build,.next,.cache,.turbo,coverage"

# 通用排除項
--folders-to-skip=".git,node_modules,venv,.venv,__pycache__,.cache,dist,build,.next,.tox,vendor,third_party"
```

## 3. 依特定語言過濾

```bash
# 僅統計 Python 檔案
pygount --suffix=py --format=summary .

# 僅統計 Python 和 YAML
pygount --suffix=py,yaml,yml --format=summary .
```

## 4. 詳細的逐個檔案輸出

```bash
# 預設格式顯示每個檔案的細目
pygount --folders-to-skip=".git,node_modules,venv" .

# 按程式碼行數排序 (透過 sort 導流)
pygount --folders-to-skip=".git,node_modules,venv" . | sort -t$'\t' -k1 -nr | head -20
```

## 5. 輸出格式

```bash
# 摘要表格 (預設建議)
pygount --format=summary .

# 供程式使用的 JSON 輸出
pygount --format=json .

# 管道友善格式：語言, 檔案數, 程式碼, 文件, 空行, 字串
pygount --format=summary . 2>/dev/null
```

## 6. 結果解讀

摘要表格的欄位說明：
- **Language** — 偵測到的程式語言
- **Files** — 該語言的檔案數量
- **Code** — 實際程式碼行數 (可執行/宣告式)
- **Comment** — 註釋或文件的行數
- **%** — 佔總數的百分比

特殊的偽語言 (pseudo-languages)：
- `__empty__` — 空檔案
- `__binary__` — 二進位檔案 (圖片、已編譯檔案等)
- `__generated__` — 自動生成的檔案 (透過啟發式偵測)
- `__duplicate__` — 內容完全相同的檔案
- `__unknown__` — 無法識別的檔案類型

## 注意事項

1. **務必排除 .git, node_modules, venv** — 如果沒有使用 `--folders-to-skip`，pygount 會掃描所有內容，在大型依賴樹上可能需要數分鐘或導致當機。
2. **Markdown 顯示為 0 行程式碼** — pygount 將所有 Markdown 內容歸類為註釋而非程式碼。這是預期行為。
3. **JSON 檔案顯示程式碼行數較低** — pygount 對於 JSON 行數的統計較為保守。若要獲得精確的 JSON 行數，請直接使用 `wc -l`。
4. **大型 Monorepos** — 對於非常大的儲存庫，建議使用 `--suffix` 針對特定語言進行統計，而不是掃描所有內容。
