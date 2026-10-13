# 機器學習與人工智慧 (ML/AI) 會議 LaTeX 模板

此目錄包含各大機器學習與人工智慧會議的官方 LaTeX 模板。

---

## 將 LaTeX 編譯為 PDF

### 選項 1: 使用 VS Code 配合 LaTeX Workshop（推薦）

**設定：**
1. 安裝 [TeX Live](https://www.tug.org/texlive/)（推薦完整安裝版）
   - macOS: `brew install --cask mactex`
   - Ubuntu: `sudo apt install texlive-full`
   - Windows: 從 [tug.org/texlive](https://www.tug.org/texlive/) 下載

2. 安裝 VS Code 擴充功能：James Yu 的 **LaTeX Workshop**
   - 開啟 VS Code → 擴充功能 (Cmd/Ctrl+Shift+X) → 搜尋 "LaTeX Workshop" → 安裝

**使用方法：**
- 在 VS Code 中開啟任何 `.tex` 檔案
- 儲存檔案 (Cmd/Ctrl+S) → 自動編譯為 PDF
- 點擊綠色播放按鈕或使用 `Cmd/Ctrl+Alt+B` 進行建置 (Build)
- 查看 PDF：點擊 "View LaTeX PDF" 圖示或使用 `Cmd/Ctrl+Alt+V`
- 並排查看：使用 `Cmd/Ctrl+Alt+V` 然後拖曳標籤頁

**設定**（添加到 VS Code 的 `settings.json`）：
```json
{
  "latex-workshop.latex.autoBuild.run": "onSave",
  "latex-workshop.view.pdf.viewer": "tab",
  "latex-workshop.latex.recipes": [
    {
      "name": "pdflatex → bibtex → pdflatex × 2",
      "tools": ["pdflatex", "bibtex", "pdflatex", "pdflatex"]
    }
  ]
}
```

### 選項 2: 命令列 (Command Line)

```bash
# 基礎編譯
pdflatex main.tex

# 包含參考文獻（完整工作流）
pdflatex main.tex
bibtex main
pdflatex main.tex
pdflatex main.tex

# 使用 latexmk（自動處理依賴關係）
latexmk -pdf main.tex

# 持續編譯（監測檔案更改）
latexmk -pdf -pvc main.tex
```

### 選項 3: Overleaf (線上)

1. 前往 [overleaf.com](https://www.overleaf.com)
2. New Project（新專案）→ Upload Project（上傳專案）→ 將模板資料夾作為 ZIP 上傳
3. 線上編輯，即時預覽 PDF
4. 無需在地安裝

### 選項 4: 其他 IDE

| IDE | 擴充功能/插件 | 備註 |
|-----|------------------|-------|
| **Cursor** | LaTeX Workshop | 與 VS Code 相同 |
| **Sublime Text** | LaTeXTools | 受歡迎且維護良好 |
| **Vim/Neovim** | VimTeX | 功能強大，鍵盤驅動 |
| **Emacs** | AUCTeX | 全面的 LaTeX 環境 |
| **TeXstudio** | 內建 | 專用的 LaTeX IDE |
| **Texmaker** | 內建 | 跨平台 LaTeX 編輯器 |

### 編譯疑難排解

**"File not found" 錯誤：**
```bash
# 確保您位於模板目錄中
cd templates/icml2026
pdflatex example_paper.tex
```

**參考文獻未出現：**
```bash
# 在第一次 pdflatex 後執行 bibtex
pdflatex main.tex
bibtex main        # 使用 main.aux 尋找引用
pdflatex main.tex  # 納入參考文獻
pdflatex main.tex  # 解析引用
```

**缺少套件：**
```bash
# TeX Live 套件管理器
tlmgr install <package-name>

# 或者安裝完整版 (full distribution) 以避免此問題
```

---

## 現有模板

| 會議 | 目錄 | 年份 | 來源 |
|------------|-----------|------|--------|
| ICML | `icml2026/` | 2026 | [Official ICML](https://icml.cc/Conferences/2026/AuthorInstructions) |
| ICLR | `iclr2026/` | 2026 | [Official GitHub](https://github.com/ICLR/Master-Template) |
| NeurIPS | `neurips2025/` | 2025 | 社群模板 |
| ACL | `acl/` | 2025+ | [Official ACL](https://github.com/acl-org/acl-style-files) |
| AAAI | `aaai2026/` | 2026 | [AAAI Author Kit](https://aaai.org/authorkit26/) |
| COLM | `colm2025/` | 2025 | [Official COLM](https://github.com/COLM-org/Template) |

## 使用方法

### ICML 2026

```latex
\documentclass{article}
\usepackage{icml2026}  % 用於投稿
% \usepackage[accepted]{icml2026}  % 用於最終版 (camera-ready)

\begin{document}
% 您的論文內容
\end{document}
```

關鍵檔案：
- `icml2026.sty` - 樣式檔案
- `icml2026.bst` - 參考文獻樣式
- `example_paper.tex` - 範例文件

### ICLR 2026

```latex
\documentclass{article}
\usepackage[submission]{iclr2026_conference}  % 用於投稿
% \usepackage[final]{iclr2026_conference}  % 用於最終版 (camera-ready)

\begin{document}
% 您的論文內容
\end{document}
```

關鍵檔案：
- `iclr2026_conference.sty` - 樣式檔案
- `iclr2026_conference.bst` - 參考文獻樣式
- `iclr2026_conference.tex` - 範例文件

### ACL 場地 (ACL, EMNLP, NAACL)

```latex
\documentclass[11pt]{article}
\usepackage[review]{acl}  % 用於審閱
% \usepackage{acl}  % 用於最終版 (camera-ready)

\begin{document}
% 您的論文內容
\end{document}
```

關鍵檔案：
- `acl.sty` - 樣式檔案
- `acl_natbib.bst` - 參考文獻樣式
- `acl_latex.tex` - 範例文件

### AAAI 2026

```latex
\documentclass[letterpaper]{article}
\usepackage[submission]{aaai2026}  % 用於投稿
% \usepackage{aaai2026}  % 用於最終版 (camera-ready)

\begin{document}
% 您的論文內容
\end{document}
```

關鍵檔案：
- `aaai2026.sty` - 樣式檔案
- `aaai2026.bst` - 參考文獻樣式

### COLM 2025

```latex
\documentclass{article}
\usepackage[submission]{colm2025_conference}  % 用於投稿
% \usepackage[final]{colm2025_conference}  % 用於最終版 (camera-ready)

\begin{document}
% 您的論文內容
\end{document}
```

關鍵檔案：
- `colm2025_conference.sty` - 樣式檔案
- `colm2025_conference.bst` - 參考文獻樣式

## 頁數限制摘要

| 會議 | 投稿 | 最終版 (Camera-Ready) | 備註 |
|------------|-----------|--------------|-------|
| ICML 2026 | 8 頁 | 9 頁 | +參考文獻/附錄不限 |
| ICLR 2026 | 9 頁 | 10 頁 | +參考文獻/附錄不限 |
| NeurIPS 2025 | 9 頁 | 9 頁 | +核查表 (checklist) 不計入限制 |
| ACL 2025 | 8 頁 (長) | 視情況而定 | +參考文獻/附錄不限 |
| AAAI 2026 | 7 頁 | 8 頁 | +參考文獻/附錄不限 |
| COLM 2025 | 9 頁 | 10 頁 | +參考文獻/附錄不限 |

## 常見問題

### 編譯錯誤

1. **缺少套件**：安裝完整版 TeX 發行版（TeX Live Full 或 MikTeX）
2. **參考文獻錯誤**：使用提供的 `.bst` 檔案搭配 `\bibliographystyle{}`
3. **字體警告**：安裝 `cm-super` 或使用 `\usepackage{lmodern}`

### 匿名化

為了投稿，請確保：
- `\author{}` 中沒有作者姓名
- 沒有致謝章節
- 沒有補助案編號
- 使用匿名倉庫 (anonymous repositories)
- 以第三人稱引用自己的工作

### 常用 LaTeX 套件

```latex
% 推薦套件（請檢查與會場樣式的相容性）
\usepackage{amsmath,amsthm,amssymb}  % 數學公式
\usepackage{graphicx}                 % 圖表
\usepackage{booktabs}                 % 表格
\usepackage{hyperref}                 % 連結
\usepackage{algorithm,algorithmic}    % 演算法
\usepackage{natbib}                   % 引用
```

## 更新模板

模板每年更新一次。每次投稿前請檢查官方來源：

- ICML: https://icml.cc/
- ICLR: https://iclr.cc/
- NeurIPS: https://neurips.cc/
- ACL: https://github.com/acl-org/acl-style-files
- AAAI: https://aaai.org/
- COLM: https://colmweb.org/
