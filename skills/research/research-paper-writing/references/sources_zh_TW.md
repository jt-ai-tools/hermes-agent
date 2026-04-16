# 參考文獻庫

本文件列出了用於構建此技能的所有權威來源，並依主題分類。

---

## 來源與貢獻

此技能中的寫作理念、引用驗證工作流和研討會參考材料最初是由 **[Orchestra Research](https://github.com/orchestra-research)** 編寫的 `ml-paper-writing` 技能（2026 年 1 月），借鑒了 Neel Nanda 的部落格文章和下面列出的其他研究人員指南。該技能由 teknium 集成到 hermes-agent 中（2026 年 1 月），隨後由 SHL0MS 擴展為目前的 `research-paper-writing` 管線（2026 年 4 月，PR #4654），增加了實驗設計、執行監控、迭代改進和提交階段，同時保留了原始的寫作理念和參考文件。

---

## 寫作理念與指南

### 主要來源（必讀）

| 來源 | 作者 | URL | 關鍵貢獻 |
|--------|--------|-----|------------------|
| **Highly Opinionated Advice on How to Write ML Papers** | Neel Nanda | [Alignment Forum](https://www.alignmentforum.org/posts/eJGptPbbFPZGLpjsp/highly-opinionated-advice-on-how-to-write-ml-papers) | 敘事框架、「什麼/為什麼/所以呢 (What/Why/So What)」、時間分配 |
| **How to Write ML Papers** | Sebastian Farquhar (DeepMind) | [部落格](https://sebastianfarquhar.com/on-research/2024/11/04/how_to_write_ml_papers/) | 五句摘要公式、結構模板 |
| **A Survival Guide to a PhD** | Andrej Karpathy | [部落格](http://karpathy.github.io/2016/09/07/phd/) | 論文結構配方、貢獻架構 |
| **Heuristics for Scientific Writing** | Zachary Lipton (CMU) | [部落格](https://www.approximatelycorrect.com/2018/01/29/heuristics-technical-scientific-writing-machine-learning-perspective/) | 用詞選擇、章節平衡、強化詞警告 |
| **Advice for Authors** | Jacob Steinhardt (UC Berkeley) | [部落格](https://jsteinhardt.stat.berkeley.edu/blog/advice-for-authors) | 精確優於簡潔、一致的術語 |
| **Easy Paper Writing Tips** | Ethan Perez (Anthropic) | [部落格](https://ethanperez.net/easy-paper-writing-tips/) | 微觀技巧、縮寫展開、清晰度訣竅 |

### 基礎科學寫作

| 來源 | 作者 | URL | 關鍵貢獻 |
|--------|--------|-----|------------------|
| **The Science of Scientific Writing** | Gopen & Swan | [PDF](https://cseweb.ucsd.edu/~swanson/papers/science-of-writing.pdf) | 主題/強調位置、舊資訊先於新資訊、七大原則 |
| **Summary of Science of Scientific Writing** | Lawrence Crowl | [摘要](https://www.crowl.org/Lawrence/writing/GopenSwan90.html) | Gopen & Swan 的濃縮版本 |

### 補充資源

| 來源 | URL | 關鍵貢獻 |
|--------|-----|------------------|
| How To Write A Research Paper In ML | [部落格](https://grigorisg9gr.github.io/machine%20learning/research%20paper/how-to-write-a-research-paper-in-machine-learning/) | 實際操作演練、LaTeX 技巧 |
| A Recipe for Training Neural Networks | [Karpathy 部落格](http://karpathy.github.io/2019/04/25/recipe/) | 可轉化為論文結構的除錯方法論 |
| ICML Paper Writing Best Practices | [ICML](https://icml.cc/Conferences/2022/BestPractices) | 官方會場指南 |
| Bill Freeman's Writing Slides | [MIT](https://billf.mit.edu/sites/default/files/documents/cvprPapers.pdf) | 論文結構的視覺指南 |

---

## 官方研討會指南

### NeurIPS

| 文件 | URL | 用途 |
|----------|-----|---------|
| 論文檢查清單指南 | [NeurIPS](https://neurips.cc/public/guides/PaperChecklist) | 16 項強制性檢查清單 |
| 2025 年審稿人指南 | [NeurIPS](https://neurips.cc/Conferences/2025/ReviewerGuidelines) | 評估標準、評分 |
| 樣式檔案 | [NeurIPS](https://neurips.cc/Conferences/2025/PaperInformation/StyleFiles) | LaTeX 模板 |

### ICML

| 文件 | URL | 用途 |
|----------|-----|---------|
| 論文指南 | [ICML](https://icml.cc/Conferences/2024/PaperGuidelines) | 投稿要求 |
| 2025 年審稿人說明 | [ICML](https://icml.cc/Conferences/2025/ReviewerInstructions) | 評閱表、評估 |
| 樣式與作者說明 | [ICML](https://icml.cc/Conferences/2022/StyleAuthorInstructions) | 格式規範 |

### ICLR

| 文件 | URL | 用途 |
|----------|-----|---------|
| 2026 年作者指南 | [ICLR](https://iclr.cc/Conferences/2026/AuthorGuide) | 投稿要求、LLM 揭露 |
| 2025 年審稿人指南 | [ICLR](https://iclr.cc/Conferences/2025/ReviewerGuide) | 評閱流程、評估 |

### ACL/EMNLP

| 文件 | URL | 用途 |
|----------|-----|---------|
| ACL 樣式檔案 | [GitHub](https://github.com/acl-org/acl-style-files) | LaTeX 模板 |
| ACL 滾動式評閱 | [ARR](https://aclrollingreview.org/) | 投稿流程 |

### AAAI

| 文件 | URL | 用途 |
|----------|-----|---------|
| 2026 年作者套件 | [AAAI](https://aaai.org/authorkit26/) | 模板與指南 |

### COLM

| 文件 | URL | 用途 |
|----------|-----|---------|
| 模板 | [GitHub](https://github.com/COLM-org/Template) | LaTeX 模板 |

---

## 引用 API 與工具

### API

| API | 文件 | 適用於 |
|-----|---------------|----------|
| **Semantic Scholar** | [文件](https://api.semanticscholar.org/api-docs/) | ML/AI 論文、引用圖譜 |
| **CrossRef** | [文件](https://www.crossref.org/documentation/retrieve-metadata/rest-api/) | DOI 查詢、BibTeX 獲取 |
| **arXiv** | [文件](https://info.arxiv.org/help/api/basics.html) | 預印本、PDF 存取 |
| **OpenAlex** | [文件](https://docs.openalex.org/) | 開源替代方案、批量存取 |

### Python 函式庫

| 函式庫 | 安裝 | 用途 |
|---------|---------|---------|
| `semanticscholar` | `pip install semanticscholar` | Semantic Scholar 包裝器 |
| `arxiv` | `pip install arxiv` | arXiv 搜尋與下載 |
| `habanero` | `pip install habanero` | CrossRef 客戶端 |

### 引用驗證

| 工具 | URL | 用途 |
|------|-----|---------|
| Citely | [citely.ai](https://citely.ai/citation-checker) | 批量驗證 |
| ReciteWorks | [reciteworks.com](https://reciteworks.com/) | 內文引用檢查 |

---

## 視覺化與格式設定

### 圖表製作

| 工具 | URL | 用途 |
|------|-----|---------|
| PlotNeuralNet | [GitHub](https://github.com/HarisIqbal88/PlotNeuralNet) | TikZ 神經網路圖 |
| SciencePlots | [GitHub](https://github.com/garrettj403/SciencePlots) | 論文等級的 matplotlib |
| Okabe-Ito Palette | [參考](https://jfly.uni-koeln.de/color/) | 色盲友善色彩 |

### LaTeX 資源

| 資源 | URL | 用途 |
|----------|-----|---------|
| Overleaf 模板 | [Overleaf](https://www.overleaf.com/latex/templates) | 線上 LaTeX 編輯器 |
| BibLaTeX 指南 | [CTAN](https://ctan.org/pkg/biblatex) | 現代化引用管理 |

---

## AI 寫作與幻覺研究

| 來源 | URL | 關鍵發現 |
|--------|-----|-------------|
| 引用中的 AI 幻覺 | [Enago](https://www.enago.com/academy/ai-hallucinations-research-citations/) | ~40% 的錯誤率 |
| AI 寫作中的幻覺 | [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC10726751/) | 引用錯誤的類型 |
| NeurIPS 2025 AI 報告 | [ByteIota](https://byteiota.com/neurips-2025-100-ai-hallucinations-slip-through-review/) | 100+ 個幻覺引用逃過審查 |

---

## 依主題分類的快速參考

### 敘事與結構
→ 從這裡開始：Neel Nanda, Sebastian Farquhar, Andrej Karpathy

### 句子層級的清晰度
→ 從這裡開始：Gopen & Swan, Ethan Perez, Zachary Lipton

### 用詞選擇與風格
→ 從這裡開始：Zachary Lipton, Jacob Steinhardt

### 研討會特定要求
→ 從這裡開始：官方會場指南 (NeurIPS, ICML, ICLR, ACL)

### 引用管理
→ 從這裡開始：Semantic Scholar API, CrossRef, citation-workflow.md

### 審稿人期望
→ 從這裡開始：會場審稿人指南, reviewer-guidelines.md

### 人工評估
→ 從這裡開始：human-evaluation.md, Prolific/MTurk 文件

### 非實證論文（理論、綜述、基準測試、立場）
→ 從這裡開始：paper-types.md

---

## 人工評估與標註

| 來源 | URL | 關鍵貢獻 |
|--------|-----|------------------|
| **Datasheets for Datasets** | Gebru et al., 2021 ([arXiv](https://arxiv.org/abs/1803.09010)) | 結構化資料集文件框架 |
| **Model Cards for Model Reporting** | Mitchell et al., 2019 ([arXiv](https://arxiv.org/abs/1810.03993)) | 結構化模型文件框架 |
| **Crowdsourcing and Human Computation** | [綜述](https://arxiv.org/abs/2202.06516) | 群眾外包標註的最佳實踐 |
| **Krippendorff's Alpha** | [維基百科](https://en.wikipedia.org/wiki/Krippendorff%27s_alpha) | 評分者間信度指標參考 |
| **Prolific** | [prolific.co](https://www.prolific.co/) | 推薦用於研究的群眾外包平台 |

## 倫理與更廣泛的影響

| 來源 | URL | 關鍵貢獻 |
|--------|-----|------------------|
| **ML CO2 Impact** | [mlco2.github.io](https://mlco2.github.io/impact/) | 計算運算的碳足跡計數器 |
| **NeurIPS Broader Impact Guide** | [NeurIPS](https://neurips.cc/public/guides/PaperChecklist) | 關於影響聲明的官方指南 |
| **ACL Ethics Policy** | [ACL](https://www.aclweb.org/portal/content/acl-code-ethics) | NLP 研究的倫理要求 |
