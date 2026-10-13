---
sidebar_position: 9
sidebar_label: "上下文引用"
title: "上下文引用"
description: "行內 @ 語法，可直接在訊息中附加檔案、資料夾、git diff 和 URL"
---

# 上下文引用 (Context References)

輸入 `@` 後接引用標記，即可直接將內容注入訊息中。Hermes 會在行內展開引用內容，並將內容附加在訊息下方的 `--- Attached Context ---` 區塊中。

## 支援的引用標記

| 語法 | 描述 |
|--------|-------------|
| `@file:path/to/file.py` | 注入檔案內容 |
| `@file:path/to/file.py:10-25` | 注入特定行號範圍（從 1 開始計數，包含首尾） |
| `@folder:path/to/dir` | 注入目錄樹列表與檔案詮釋資料 (metadata) |
| `@diff` | 注入 `git diff`（未暫存的工作區變更） |
| `@staged` | 注入 `git diff --staged`（已暫存的變更） |
| `@git:5` | 注入最近 N 筆提交及其補丁 (patches)（最多 10 筆） |
| `@url:https://example.com` | 擷取並注入網頁內容 |

## 使用範例

```text
Review @file:src/main.py and suggest improvements
（審閱 @file:src/main.py 並建議改進方案）

What changed? @diff
（有哪些變更？ @diff）

Compare @file:old_config.yaml and @file:new_config.yaml
（比較 @file:old_config.yaml 與 @file:new_config.yaml）

What's in @folder:src/components?
（@folder:src/components 裡面有什麼？）

Summarize this article @url:https://arxiv.org/abs/2301.00001
（摘要這篇文章 @url:https://arxiv.org/abs/2301.00001）
```

單則訊息中可以使用多個引用標記：

```text
Check @file:main.py, and also @file:test.py.
```

引用值後方的標點符號（`,`、`.`、`;`、`!`、`?`）會自動被剔除。

## CLI Tab 補齊 (Tab Completion)

在互動式 CLI 中，輸入 `@` 會觸發自動補齊：

- `@` 顯示所有引用類型（`@diff`、`@staged`、`@file:`、`@folder:`、`@git:`、`@url:`）
- `@file:` 與 `@folder:` 會觸發檔案系統路徑補齊，並顯示檔案大小資訊
- 輸入 `@` 後接著部分文字，會顯示目前目錄中相符的檔案與資料夾

## 行號範圍

`@file:` 引用支援行號範圍，以便精確注入內容：

```text
@file:src/main.py:42        # 單行第 42 行
@file:src/main.py:10-25     # 第 10 行到第 25 行（包含首尾）
```

行號從 1 開始計數。無效的範圍會被自動忽略（改為回傳完整檔案）。

## 大小限制

上下文引用設有限制，以防止模型上下文視窗 (context window) 過載：

| 門檻 | 數值 | 行為 |
|-----------|-------|----------|
| 軟限制 (Soft limit) | 上下文長度的 25% | 附加警告訊息，但繼續展開內容 |
| 硬限制 (Hard limit) | 上下文長度的 50% | 拒絕展開，原訊息保持不變回傳 |
| 資料夾項目 | 最多 200 個檔案 | 超出的項目將以 `- ...` 取代 |
| Git 提交 | 最多 10 筆 | `@git:N` 會被限制在 [1, 10] 範圍內 |

## 安全性

### 敏感路徑阻擋

以下路徑一律禁止透過 `@file:` 引用，以防止憑證外洩：

- SSH 金鑰與設定：`~/.ssh/id_rsa`、`~/.ssh/id_ed25519`、`~/.ssh/authorized_keys`、`~/.ssh/config`
- Shell 設定檔：`~/.bashrc`、`~/.zshrc`、`~/.profile`、`~/.bash_profile`、`~/.zprofile`
- 憑證檔案：`~/.netrc`、`~/.pgpass`、`~/.npmrc`、`~/.pypirc`
- Hermes 環境變數：`$HERMES_HOME/.env`

以下目錄被完全封鎖（包含其內任何檔案）：
- `~/.ssh/`、`~/.aws/`、`~/.gnupg/`、`~/.kube/`、`$HERMES_HOME/skills/.hub/`

### 路徑遍歷防護 (Path Traversal Protection)

所有路徑皆相對於工作目錄解析。解析結果位於允許的專案根目錄之外的引用將被拒絕。

### 二進位檔案偵測

透過 MIME 類型和空字節 (null-byte) 掃描來偵測二進位檔案。已知的文字副檔名（`.py`、`.md`、`.json`、`.yaml`、`.toml`、`.js`、`.ts` 等）會跳過基於 MIME 的偵測。二進位檔案會被拒絕並顯示警告。

## 平台可用性

上下文引用主要是 **CLI 功能**。它們在互動式 CLI 中運作，當輸入 `@` 會觸發 Tab 補齊，且引用內容會在訊息發送給代理之前完成展開。

在 **即時通訊平台**（Telegram、Discord 等）中，閘道器 (gateway) 不會展開 `@` 語法 — 訊息會原樣傳遞。不過代理本身仍可透過 `read_file`、`search_files` 和 `web_extract` 等工具來引用檔案。

## 與內容壓縮 (Context Compression) 的互動

當對話內容被壓縮時，展開後的引用內容會包含在壓縮摘要中。這意味著：

- 透過 `@file:` 注入的大量檔案內容會計入上下文使用量
- 如果對話隨後被壓縮，檔案內容會被摘要化（而非逐字保留）
- 對於非常大的檔案，請考慮使用行號範圍（如 `@file:main.py:100-200`）僅注入相關章節

## 常見模式

```text
# 程式碼審閱工作流
Review @diff and check for security issues

# 帶著上下文進行偵錯
This test is failing. Here's the test @file:tests/test_auth.py
and the implementation @file:src/auth.py:50-80

# 專案探索
What does this project do? @folder:src @file:README.md

# 研究
Compare the approaches in @url:https://arxiv.org/abs/2301.00001
and @url:https://arxiv.org/abs/2301.00002
```

## 錯誤處理

無效的引用會產生行內警告，而非導致失敗：

| 狀況 | 行為 |
|-----------|----------|
| 找不到檔案 | 警告："file not found" |
| 二進位檔案 | 警告："binary files are not supported" |
| 找不到資料夾 | 警告："folder not found" |
| Git 指令失敗 | 顯示 git stderr 警告 |
| URL 未傳回內容 | 警告："no content extracted" |
| 敏感路徑 | 警告："path is a sensitive credential file" |
| 路徑位於工作區外 | 警告："path is outside the allowed workspace" |
