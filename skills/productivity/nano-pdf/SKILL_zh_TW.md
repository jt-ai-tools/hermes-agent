---
name: nano-pdf
description: 使用 nano-pdf CLI 透過自然語言指令編輯 PDF。修改文字、修正錯字、更新標題，並針對特定頁面進行內容變更，無需手動編輯。
version: 1.0.0
author: community
license: MIT
metadata:
  hermes:
    tags: [PDF, Documents, Editing, NLP, Productivity]
    homepage: https://pypi.org/project/nano-pdf/
---

# nano-pdf

使用自然語言指令編輯 PDF。指定頁碼並描述要變更的內容即可。

## 前置作業

```bash
# 使用 uv 安裝 (推薦 — Hermes 已內建)
uv pip install nano-pdf

# 或使用 pip
pip install nano-pdf
```

## 用法

```bash
nano-pdf edit <file.pdf> <頁碼> "<指令>"
```

## 範例

```bash
# 修改第 1 頁的標題
nano-pdf edit deck.pdf 1 "將標題改為 'Q3 Results' 並修正副標題中的錯字"

# 更新特定頁面的日期
nano-pdf edit report.pdf 3 "將日期從 2026 年 1 月更新為 2 月"

# 修正內容
nano-pdf edit contract.pdf 2 "將客戶名稱從 'Acme Corp' 改為 'Acme Industries'"
```

## 備註

- 頁碼可能是從 0 或從 1 開始，取決於版本 — 如果編輯到了錯誤的頁面，請嘗試將頁碼 ±1 後重試
- 編輯後務必驗證輸出的 PDF (使用 `read_file` 檢查檔案大小，或直接開啟)
- 該工具底層使用 LLM — 需要 API 金鑰 (執行 `nano-pdf --help` 查看設定)
- 適用於文字變更；複雜的版面修改可能需要使用其他方法
