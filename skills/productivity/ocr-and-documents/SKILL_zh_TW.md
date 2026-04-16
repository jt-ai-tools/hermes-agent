---
name: ocr-and-documents
description: 從 PDF 和掃描文件中提取文字。遠端 URL 請使用 web_extract，本地文字型 PDF 請使用 pymupdf，OCR/掃描文件請使用 marker-pdf。DOCX 請使用 python-docx，PPTX 請參考 powerpoint 技能。
version: 2.3.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [PDF, 文件, 研究, Arxiv, 文字提取, OCR]
    related_skills: [powerpoint]
---

# PDF & 文件提取

對於 DOCX：使用 `python-docx`（解析實際文件結構，遠優於 OCR）。
對於 PPTX：請參閱 `powerpoint` 技能（使用 `python-pptx` 並提供完整的投影片/備忘稿支援）。
本技能涵蓋 **PDF 和掃描文件**。

## 第 1 步：是否有遠端 URL？

如果文件有 URL，**務必優先嘗試 `web_extract`**：

```
web_extract(urls=["https://arxiv.org/pdf/2402.03300"])
web_extract(urls=["https://example.com/report.pdf"])
```

這會透過 Firecrawl 處理 PDF 轉 Markdown 的轉換，無需本地依賴。

僅在以下情況使用本地提取：檔案在本地、web_extract 失敗，或需要批次處理。

## 第 2 步：選擇本地提取器

| 功能 | pymupdf (~25MB) | marker-pdf (~3-5GB) |
|---------|-----------------|---------------------|
| **文字型 PDF** | ✅ | ✅ |
| **掃描 PDF (OCR)** | ❌ | ✅ (支援 90 多種語言) |
| **表格** | ✅ (基本) | ✅ (高準確度) |
| **方程式 / LaTeX** | ❌ | ✅ |
| **程式碼區塊** | ❌ | ✅ |
| **表單** | ❌ | ✅ |
| **頁首/頁尾移除** | ❌ | ✅ |
| **閱讀順序偵測** | ❌ | ✅ |
| **圖片提取** | ✅ (嵌入式) | ✅ (帶有上下文) |
| **圖片 → 文字 (OCR)** | ❌ | ✅ |
| **EPUB** | ✅ | ✅ |
| **Markdown 輸出** | ✅ (透過 pymupdf4llm) | ✅ (原生，品質更高) |
| **安裝大小** | ~25MB | ~3-5GB (PyTorch + 模型) |
| **速度** | 即時 | 約 1-14 秒/頁 (CPU)，約 0.2 秒/頁 (GPU) |

**決策**：除非需要 OCR、方程式、表單或複雜的佈局分析，否則請使用 pymupdf。

如果使用者需要 marker 的功能但系統缺乏約 5GB 的可用磁碟空間：
> "此文件需要 OCR/進階提取 (marker-pdf)，這需要約 5GB 的 PyTorch 和模型空間。您的系統目前剩餘 [X]GB。選項：釋放空間、提供 URL 以便我使用 web_extract，或者我可以嘗試使用 pymupdf，它適用於文字型 PDF，但不適用於掃描文件或方程式。"

---

## pymupdf (輕量級)

```bash
pip install pymupdf pymupdf4llm
```

**透過輔助腳本**：
```bash
python scripts/extract_pymupdf.py document.pdf              # 純文字
python scripts/extract_pymupdf.py document.pdf --markdown    # Markdown
python scripts/extract_pymupdf.py document.pdf --tables      # 表格
python scripts/extract_pymupdf.py document.pdf --images out/ # 提取圖片
python scripts/extract_pymupdf.py document.pdf --metadata    # 標題、作者、頁數
python scripts/extract_pymupdf.py document.pdf --pages 0-4   # 特定頁面
```

**內嵌使用**：
```bash
python3 -c "
import pymupdf
doc = pymupdf.open('document.pdf')
for page in doc:
    print(page.get_text())
"
```

---

## marker-pdf (高品質 OCR)

```bash
# 先檢查磁碟空間
python scripts/extract_marker.py --check

pip install marker-pdf
```

**透過輔助腳本**：
```bash
python scripts/extract_marker.py document.pdf                # Markdown
python scripts/extract_marker.py document.pdf --json         # 包含詮釋資料的 JSON
python scripts/extract_marker.py document.pdf --output_dir out/  # 儲存圖片
python scripts/extract_marker.py scanned.pdf                 # 掃描 PDF (OCR)
python scripts/extract_marker.py document.pdf --use_llm      # 透過 LLM 提升準確度
```

**CLI** (隨 marker-pdf 安裝)：
```bash
marker_single document.pdf --output_dir ./output
marker /path/to/folder --workers 4    # 批次處理
```

---

## Arxiv 論文

```
# 僅摘要 (快速)
web_extract(urls=["https://arxiv.org/abs/2402.03300"])

# 完整論文
web_extract(urls=["https://arxiv.org/pdf/2402.03300"])

# 搜尋
web_search(query="arxiv GRPO reinforcement learning 2026")
```

## 分割、合併與搜尋

pymupdf 原生支援這些功能 — 請使用 `execute_code` 或內嵌 Python：

```python
# 分割：將第 1-5 頁提取到新的 PDF
import pymupdf
doc = pymupdf.open("report.pdf")
new = pymupdf.open()
for i in range(5):
    new.insert_pdf(doc, from_page=i, to_page=i)
new.save("pages_1-5.pdf")
```

```python
# 合併多個 PDF
import pymupdf
result = pymupdf.open()
for path in ["a.pdf", "b.pdf", "c.pdf"]:
    result.insert_pdf(pymupdf.open(path))
result.save("merged.pdf")
```

```python
# 在所有頁面中搜尋文字
import pymupdf
doc = pymupdf.open("report.pdf")
for i, page in enumerate(doc):
    results = page.search_for("revenue")
    if results:
        print(f"Page {i+1}: {len(results)} match(es)")
        print(page.get_text("text"))
```

不需要額外的依賴項 — pymupdf 在一個套件中涵蓋了分割、合併、搜尋和文字提取。

---

## 注意事項

- 對於 URL，`web_extract` 始終是首選
- pymupdf 是安全的預設選擇 — 即時、無模型、隨處可用
- marker-pdf 用於 OCR、掃描文件、方程式、複雜佈局 — 僅在需要時安裝
- 兩個輔助腳本都接受 `--help` 以獲取完整用法
- marker-pdf 在第一次使用時會下載約 2.5GB 的模型到 `~/.cache/huggingface/`
- 對於 Word 文件：`pip install python-docx`（優於 OCR — 解析實際結構）
- 對於 PowerPoint：請參閱 `powerpoint` 技能（使用 python-pptx）
