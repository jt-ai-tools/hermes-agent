# AAAI 2026 統一 LaTeX 模板使用說明 / AAAI 2026 Unified LaTeX Template Guide

> **📝 重要說明 / Important Notice**: 本倉庫借助 Cursor 在 AAAI 2026 官方模板基礎上改進得到。如果遇到不滿足或有衝突的情況，請積極提 issues。
> 
> **📝 Important Notice**: This repository is improved based on the official AAAI 2026 template with the assistance of Cursor. If you encounter any issues or conflicts, please actively submit issues.

[繁體中文](#繁體中文版本) | [English](#english-version)

---

## 🌐 線上查看 / Online Access

**📖 線上閱讀和測試模板**: [https://cn.overleaf.com/read/wyhcnvcrtpyt#cd4a07](https://cn.overleaf.com/read/wyhcnvcrtpyt#cd4a07)

**📖 Online View and Test Template**: [https://cn.overleaf.com/read/wyhcnvcrtpyt#cd4a07](https://cn.overleaf.com/read/wyhcnvcrtpyt#cd4a07)

💡 **提示 / Tips**: 
- 繁體中文：您可以透過上述連結在 Overleaf 中直接查看、編輯和編譯模板，無需在地安裝 LaTeX 環境
- English: You can view, edit, and compile the template directly in Overleaf using the link above, without needing a local LaTeX installation

---

## 繁體中文版本

### 概述 ✅

我已經將 AAAI 2026 的兩個版本（匿名投稿版本和 camera-ready 版本）**完整合併**成一個統一的模板檔案 `aaai2026-unified-template.tex`。

該模板包含了原始兩個模板的**所有完整內容**（共 886 行，比原始文件更全面），包括：
- 所有格式化說明和要求
- 完整的範例程式碼和表格
- 圖片處理指南
- 參考文獻格式要求
- 所有章節和附錄內容
- 版本特定的 Acknowledgments 部分

### 主要差異分析

透過比較原始的兩個模板，我發現主要差異在於：

#### 1. 套件的載入方式
- **匿名版本**: `\usepackage[submission]{aaai2026}`
- **Camera-ready 版本**: `\usepackage{aaai2026}`

#### 2. 標題差異
- **匿名版本**: "AAAI Press Anonymous Submission Instructions for Authors Using LaTeX"
- **Camera-ready 版本**: "AAAI Press Formatting Instructions for Authors Using LaTeX --- A Guide"

#### 3. Links 環境的處理
- **匿名版本**: Links 環境被註解掉，防止洩漏作者身份
- **Camera-ready 版本**: Links 環境正常顯示

#### 4. 內容部分差異
- **匿名版本**: 包含 "Preparing an Anonymous Submission" 部分的特殊說明
- **Camera-ready 版本**: 包含完整的格式說明和版權資訊

### 依賴檔案檢查結果

✅ **已驗證並複製到主目錄的檔案**：

- `aaai2026.sty` - AAAI 2026 樣式檔案（兩個版本完全相同）
- `aaai2026.bst` - 參考文獻樣式檔案（兩個版本完全相同）
- `aaai2026.bib` - 範例參考文獻檔案
- `figure1.pdf` 和 `figure2.pdf` - 範例圖片檔案

所有這些檔案在兩個版本中都是相同的，因此統一模板可以正常運作。

### 如何使用統一模板

#### 切換到匿名投稿版本
在模板檔案第 11 行，**取消註解**這一行：
```latex
\def\aaaianonymous{true}
```

#### 切換到 Camera-ready 版本
在模板檔案第 11 行，**註解掉**或**刪除**這一行：
```latex
% \def\aaaianonymous{true}
```

### 一鍵切換的核心機制

統一模板使用了 LaTeX 的條件編譯功能：

```latex
% 條件套件載入
\ifdefined\aaaianonymous
    \usepackage[submission]{aaai2026}  % 匿名版本
\else
    \usepackage{aaai2026}              % Camera-ready 版本
\fi

% 條件標題設置
\ifdefined\aaaianonymous
    \title{AAAI Press Anonymous Submission\\Instructions for Authors Using \LaTeX{}}
\else
    \title{AAAI Press Formatting Instructions \\for Authors Using \LaTeX{} --- A Guide}
\fi

% 條件內容顯示
\ifdefined\aaaianonymous
    % 匿名版本特有內容
\else
    % Camera-ready 版本特有內容
\fi
```

### 檔案清單

主目錄現在包含以下檔案：

- `aaai2026-unified-template.tex` - 統一主論文模板檔案
- `aaai2026-unified-supp.tex` - 統一補充材料模板檔案
- `aaai2026.sty` - AAAI 2026 LaTeX 樣式檔案
- `aaai2026.bst` - 參考文獻樣式檔案  
- `aaai2026.bib` - 範例參考文獻檔案
- `figure1.pdf` - 範例圖片 1
- `figure2.pdf` - 範例圖片 2
- `README.md` - 本說明文件

### 補充材料模板 (Supplementary Material Template)

#### 概述
`aaai2026-unified-supp.tex` 是專門為 AAAI 2026 補充材料設計的統一模板，與主論文模板使用相同的版本切換機制。

#### 主要功能
- **版本切換**: 透過修改一行程式碼在匿名投稿和 camera-ready 版本間切換
- **補充內容支援**: 支援額外的實驗、推導、數據、圖表、演算法等
- **格式一致性**: 與主論文模板保持完全一致的格式要求
- **程式碼範例**: 包含演算法、程式碼列表等補充材料的範例

#### 使用方法
與主論文模板相同，只需修改第 11 行：
```latex
% 匿名投稿版本
\def\aaaianonymous{true}

% Camera-ready 版本  
% \def\aaaianonymous{true}
```

#### 補充材料內容建議
- 額外的實驗結果和消融研究 (ablation studies)
- 詳細的數學推導和證明
- 更多的圖表和視覺化
- 演算法偽程式碼和實作細節
- 資料集描述和預處理步驟
- 超參數設置和實驗配置
- 失敗案例分析
- 計算複雜度分析

### 使用檢查清單 (Usage Checklist)

#### 📋 投稿前檢查清單 (Pre-Submission Checklist)

**版本設置**:
- [ ] 已設置 `\def\aaaianonymous{true}` (匿名投稿)
- [ ] 已註解掉所有可能暴露身份的資訊
- [ ] 已匿名化參考文獻（移除作者姓名）

**內容完整性**:
- [ ] 標題、摘要、關鍵字已填寫
- [ ] 所有章節內容完整
- [ ] 圖表編號連續且正確
- [ ] 參考文獻格式正確
- [ ] 補充材料（如有）已準備

**格式檢查**:
- [ ] 頁面邊距符合要求
- [ ] 字體和字級正確
- [ ] 行間距符合標準
- [ ] 圖表位置和大小合適
- [ ] 數學公式格式正確

**技術檢查**:
- [ ] LaTeX 編譯無錯誤
- [ ] 參考文獻正確生成
- [ ] PDF 輸出正常
- [ ] 檔案大小在限制範圍內

#### 📋 錄用後檢查清單 (Post-Acceptance Checklist)

**版本切換**:
- [ ] 已註解掉 `\def\aaaianonymous{true}` (camera-ready)
- [ ] 已添加完整的作者資訊
- [ ] 已添加所有作者單位資訊
- [ ] 已恢復所有被註解的內容

**內容更新**:
- [ ] 已根據審稿意見修改內容
- [ ] 已更新所有圖表和實驗
- [ ] 已完善補充材料
- [ ] 已檢查所有連結和引用

**最終檢查**:
- [ ] 最終 PDF 品質檢查
- [ ] 所有檔案已備份
- [ ] 符合會議最終提交要求
- [ ] 補充材料已單獨提交（如需要）

#### 📋 補充材料檢查清單 (Supplementary Material Checklist)

**內容組織**:
- [ ] 補充材料與主論文內容對應
- [ ] 章節結構清晰合理
- [ ] 圖表編號與主論文不衝突
- [ ] 參考文獻格式一致

**技術細節**:
- [ ] 演算法偽程式碼清晰完整
- [ ] 實驗設置詳細說明
- [ ] 資料預處理步驟明確
- [ ] 超參數配置完整

**格式要求**:
- [ ] 使用統一的 supp 模板
- [ ] 頁面設置與主論文一致
- [ ] 字體和格式符合要求
- [ ] 檔案大小在限制範圍內

### 實際使用建議

1. **投稿階段**: 
   - 取消註解 `\def\aaaianonymous{true}` 
   - 確保不包含任何可能暴露身份的資訊
   - 檢查參考文獻是否已匿名化

2. **錄用後準備 final 版本**:
   - 註解掉或刪除 `\def\aaaianonymous{true}` 這一行
   - 添加完整的作者資訊和 affiliations
   - 取消註解 links 環境（如果需要）

3. **編譯測試**:
   - 分別在兩種模式下編譯，確保都能正常運作
   - 檢查輸出的 PDF 是否符合要求
   - 驗證參考文獻格式是否正確

4. **依賴檔案確認**:
   - 確保所有依賴檔案都在同一目錄下
   - 如果移動模板檔案，記得同時移動依賴檔案

### 重要注意事項

⚠️ **關於 Bibliography Style**:
- `aaai2026.sty` 檔案已經自動設置了 `\bibliographystyle{aaai2026}`
- **不要**在文件中再次添加 `\bibliographystyle{aaai2026}` 指令
- 否則會出現 "`Illegal, another \bibstyle command`" 錯誤
- 只需要使用 `\bibliography{aaai2026}` 指令即可

### 編譯指令範例

```bash
# 編譯 LaTeX 文件
pdflatex aaai2026-unified-template.tex
bibtex aaai2026-unified-template
pdflatex aaai2026-unified-template.tex
pdflatex aaai2026-unified-template.tex
```

### 常見問題解決

#### 1. "Illegal, another \bibstyle command" 錯誤
**原因**: 重複設置了 bibliography style  
**解決方案**: 刪除文件中的 `\bibliographystyle{aaai2026}` 指令，`aaai2026.sty` 會自動處理

#### 2. 參考文獻格式不正確
**原因**: 可能缺少 natbib 套件或者 BibTeX 檔案問題  
**解決方案**: 確保按照標準的 LaTeX 編譯流程：pdflatex → bibtex → pdflatex → pdflatex

---

## English Version

### Overview ✅

I have **completely merged** the two AAAI 2026 versions (anonymous submission and camera-ready) into a single unified template file `aaai2026-unified-template.tex`.

This template contains **all complete content** from both original templates (886 lines total, more comprehensive than the original files), including:
- All formatting instructions and requirements
- Complete example codes and tables
- Image processing guidelines
- Reference formatting requirements
- All sections and appendix content
- Version-specific Acknowledgments sections

### Key Differences Analysis

By comparing the two original templates, the main differences are:

#### 1. Package Loading Method
- **Anonymous version**: `\usepackage[submission]{aaai2026}`
- **Camera-ready version**: `\usepackage{aaai2026}`

#### 2. Title Differences
- **Anonymous version**: "AAAI Press Anonymous Submission Instructions for Authors Using LaTeX"
- **Camera-ready version**: "AAAI Press Formatting Instructions for Authors Using LaTeX --- A Guide"

#### 3. Links Environment Handling
- **Anonymous version**: Links environment commented out to prevent identity disclosure
- **Camera-ready version**: Links environment displayed normally

#### 4. Content Section Differences
- **Anonymous version**: Contains special instructions in "Preparing an Anonymous Submission" section
- **Camera-ready version**: Contains complete formatting instructions and copyright information

### Dependency Files Verification

✅ **Files verified and copied to main directory**:

- `aaai2026.sty` - AAAI 2026 style file (identical in both versions)
- `aaai2026.bst` - Bibliography style file (identical in both versions)
- `aaai2026.bib` - Sample bibliography file
- `figure1.pdf` and `figure2.pdf` - Sample image files

All these files are identical in both versions, so the unified template works properly.

### How to Use the Unified Template

#### Switch to Anonymous Submission Version
On line 11 of the template file, **uncomment** this line:
```latex
\def\aaaianonymous{true}
```

#### Switch to Camera-ready Version
On line 11 of the template file, **comment out** or **delete** this line:
```latex
% \def\aaaianonymous{true}
```

### Core Mechanism of One-Click Switching

The unified template uses LaTeX conditional compilation:

```latex
% Conditional package loading
\ifdefined\aaaianonymous
    \usepackage[submission]{aaai2026}  % Anonymous version
\else
    \usepackage{aaai2026}              % Camera-ready version
\fi

% Conditional title setting
\ifdefined\aaaianonymous
    \title{AAAI Press Anonymous Submission\\Instructions for Authors Using \LaTeX{}}
\else
    \title{AAAI Press Formatting Instructions \\for Authors Using \LaTeX{} --- A Guide}
\fi

% Conditional content display
\ifdefined\aaaianonymous
    % Anonymous version specific content
\else
    % Camera-ready version specific content
\fi
```

### File List

The main directory now contains the following files:

- `aaai2026-unified-template.tex` - Unified main paper template file
- `aaai2026-unified-supp.tex` - Unified supplementary material template file
- `aaai2026.sty` - AAAI 2026 LaTeX style file
- `aaai2026.bst` - Bibliography style file
- `aaai2026.bib` - Sample bibliography file
- `figure1.pdf` - Sample image 1
- `figure2.pdf` - Sample image 2
- `README.md` - This documentation

### Supplementary Material Template

#### Overview
`aaai2026-unified-supp.tex` is a unified template specifically designed for AAAI 2026 supplementary materials, using the same version switching mechanism as the main paper template.

#### Key Features
- **Version Switching**: Switch between anonymous submission and camera-ready versions by modifying one line of code
- **Supplementary Content Support**: Supports additional experiments, derivations, data, figures, algorithms, etc.
- **Format Consistency**: Maintains complete format consistency with the main paper template
- **Code Examples**: Includes examples for algorithms, code listings, and other supplementary materials

#### Usage
Same as the main paper template, just modify line 11:
```latex
% Anonymous submission version
\def\aaaianonymous{true}

% Camera-ready version
% \def\aaaianonymous{true}
```

#### Supplementary Material Content Suggestions
- Additional experimental results and ablation studies
- Detailed mathematical derivations and proofs
- More figures and visualizations
- Algorithm pseudocode and implementation details
- Dataset descriptions and preprocessing steps
- Hyperparameter settings and experimental configurations
- Failure case analysis
- Computational complexity analysis

### Usage Checklist

#### 📋 Pre-Submission Checklist

**Version Setup**:
- [ ] Set `\def\aaaianonymous{true}` (anonymous submission)
- [ ] Commented out all information that could reveal identity
- [ ] Anonymized references (removed author names)

**Content Completeness**:
- [ ] Title, abstract, and keywords filled
- [ ] All sections complete
- [ ] Figure and table numbers consecutive and correct
- [ ] Reference format correct
- [ ] Supplementary materials prepared (if any)

**Format Check**:
- [ ] Page margins meet requirements
- [ ] Font and font size correct
- [ ] Line spacing meets standards
- [ ] Figure and table positions and sizes appropriate
- [ ] Mathematical formula format correct

**Technical Check**:
- [ ] LaTeX compilation error-free
- [ ] References generated correctly
- [ ] PDF output normal
- [ ] File size within limits

#### 📋 Post-Acceptance Checklist

**Version Switch**:
- [ ] Commented out `\def\aaaianonymous{true}` (camera-ready)
- [ ] Added complete author information
- [ ] Added all author affiliation information
- [ ] Restored all commented content

**Content Updates**:
- [ ] Modified content according to reviewer comments
- [ ] Updated all figures and experiments
- [ ] Completed supplementary materials
- [ ] Checked all links and citations

**Final Check**:
- [ ] Final PDF quality check
- [ ] All files backed up
- [ ] Meets conference final submission requirements
- [ ] Supplementary materials submitted separately (if needed)

#### 📋 Supplementary Material Checklist

**Content Organization**:
- [ ] Supplementary materials correspond to main paper content
- [ ] Chapter structure clear and reasonable
- [ ] Figure and table numbers don't conflict with main paper
- [ ] Reference format consistent

**Technical Details**:
- [ ] Algorithm pseudocode clear and complete
- [ ] Experimental setup explained in detail
- [ ] Data preprocessing steps clear
- [ ] Hyperparameter configuration complete

**Format Requirements**:
- [ ] Using unified supp template
- [ ] Page settings consistent with main paper
- [ ] Font and format meet requirements
- [ ] File size within limits

### Practical Usage Recommendations

1. **Submission Stage**: 
   - Uncomment `\def\aaaianonymous{true}` 
   - Ensure no information that could reveal identity is included
   - Check that references are anonymized

2. **Preparing final version after acceptance**:
   - Comment out or delete the `\def\aaaianonymous{true}` line
   - Add complete author information and affiliations
   - Uncomment links environment (if needed)

3. **Compilation Testing**:
   - Compile in both modes to ensure proper functionality
   - Check if the output PDF meets requirements
   - Verify reference formatting is correct

4. **Dependency File Confirmation**:
   - Ensure all dependency files are in the same directory
   - Remember to move dependency files when moving the template file

### Important Notes

⚠️ **About Bibliography Style**:
- The `aaai2026.sty` file automatically sets `\bibliographystyle{aaai2026}`
- **Do NOT** add `\bibliographystyle{aaai2026}` command again in your document
- Otherwise you'll get "`Illegal, another \bibstyle command`" error
- Just use the `\bibliography{aaai2026}` command

### Compilation Commands Example

```bash
# Compile LaTeX document
pdflatex aaai2026-unified-template.tex
bibtex aaai2026-unified-template
pdflatex aaai2026-unified-template.tex
pdflatex aaai2026-unified-template.tex
```

### Common Issues and Solutions

#### 1. "Illegal, another \bibstyle command" Error
**Cause**: Duplicate bibliography style setting  
**Solution**: Remove the `\bibliographystyle{aaai2026}` command from your document, `aaai2026.sty` handles it automatically

#### 2. Incorrect Reference Format
**Cause**: Missing natbib package or BibTeX file issues  
**Solution**: Follow the standard LaTeX compilation process: pdflatex → bibtex → pdflatex → pdflatex

---

## 版本資訊 / Version Information

- **模板版本 / Template Version**: AAAI 2026 Unified (Main + Supplementary)
- **建立日期 / Created**: 2024年12月
- **支援格式 / Supported Formats**: Anonymous Submission & Camera-Ready
- **模板類型 / Template Types**: Main Paper Template & Supplementary Material Template
- **相容性 / Compatibility**: LaTeX 2020+ / TeXLive 2024+

---

🎉 **現在您只需要修改一行程式碼就可以在兩個版本之間切換，同時所有必要的依賴檔案都已經準備就緒！**  
🎉 **Now you only need to modify one line of code to switch between the two versions, with all necessary dependency files ready to use!**
