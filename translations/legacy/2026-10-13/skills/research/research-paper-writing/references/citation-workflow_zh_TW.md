# 引用管理與預防幻覺 (Citation Management & Hallucination Prevention)

本參考文件提供了一個完整的流程，用於透過程式化方式管理引用，預防 AI 生成的引用幻覺，並保持乾淨的參考書目 (bibliographies)。

---

## 目錄

- [為何引用驗證很重要](#why-citation-verification-matters)
- [引用 API 概述](#citation-apis-overview)
- [經驗證的引用流程](#verified-citation-workflow)
- [Python 實作](#python-implementation)
- [BibTeX 管理](#bibtex-management)
- [常見引用格式](#common-citation-formats)
- [疑難排解](#troubleshooting)

---

## 為何引用驗證很重要

### 幻覺問題 (The Hallucination Problem)

研究記錄了 AI 生成的引用中存在的重大問題：
- AI 生成的引用中有 **約 40% 的錯誤率** (Enago Academy 研究)
- NeurIPS 2025 發現有 **100+ 幻覺出來的引用** 通過了審查
- 常見的錯誤包括：
  - 使用真實作者姓名捏造論文標題
  - 錯誤的出版場合或年份
  - 帶有看似合理元資料的不存在的論文
  - 不正確的 DOIs 或 arXiv IDs

### 後果

- 在某些會議會被直接拒稿 (Desk rejection)
- 失去審查員的信任
- 如果已發表可能面臨撤稿
- 浪費時間追查不存在的文獻

### 解決方案

**絕不從記憶中生成引用—永遠透過程式化方式驗證。**

---

## 引用 API 概述

### 主要 APIs

| API | 涵蓋範圍 | 速率限制 | 最適合 |
|-----|----------|-------------|----------|
| **Semantic Scholar** | 2.14 億篇論文 | 1 RPS (免費金鑰) | ML/AI 論文、引用圖 (citation graphs) |
| **CrossRef** | 1.4 億+ DOIs | 帶有 mailto 的禮貌池 (Polite pool) | DOI 查詢、BibTeX 獲取 |
| **arXiv** | 預印本 (Preprints) | 3 秒延遲 | ML 預印本、PDF 存取 |
| **OpenAlex** | 2.4 億+ 作品 | 10 萬/天，10 RPS | MAG 的開放替代方案 |

### API 選擇指南

```
需要 ML 論文搜尋？ → Semantic Scholar
有 DOI，需要 BibTeX？ → CrossRef 內容協商 (content negotiation)
正在找預印本？ → arXiv API
需要開放資料、大量存取？ → OpenAlex
```

### 沒有官方的 Google Scholar API

Google Scholar 沒有官方的 API。網頁爬蟲違反服務條款 (ToS)。只有當 Semantic Scholar 的覆蓋範圍不足時，才使用 SerpApi（每月 $75-275）。

---

## 經驗證的引用流程

### 5 步流程

```
1. 搜尋 (SEARCH) → 使用特定關鍵字查詢 Semantic Scholar
     ↓
2. 驗證 (VERIFY) → 確認論文存在於 2 個以上的來源
     ↓
3. 獲取 (RETRIEVE) → 透過 DOI 內容協商獲取 BibTeX
     ↓
4. 確效 (VALIDATE) → 確認該聲明確實出現在來源中
     ↓
5. 新增 (ADD) → 將驗證過的條目加入 .bib 檔案中
```

### 步驟 1: 搜尋

使用 Semantic Scholar 尋找 ML/AI 論文：

```python
from semanticscholar import SemanticScholar

sch = SemanticScholar()
results = sch.search_paper("transformer attention mechanism", limit=10)

for paper in results:
    print(f"Title: {paper.title}")
    print(f"Year: {paper.year}")
    print(f"DOI: {paper.externalIds.get('DOI', 'N/A')}")
    print(f"arXiv: {paper.externalIds.get('ArXiv', 'N/A')}")
    print(f"Citation count: {paper.citationCount}")
    print("---")
```

### 步驟 2: 驗證存在性

確認論文存在於至少兩個來源：

```python
import requests

def verify_paper(doi=None, arxiv_id=None, title=None):
    """驗證論文是否存在於多個來源中。"""
    sources_found = []

    # 檢查 Semantic Scholar
    sch = SemanticScholar()
    if doi:
        paper = sch.get_paper(f"DOI:{doi}")
        if paper:
            sources_found.append("Semantic Scholar")

    # 檢查 CrossRef (透過 DOI)
    if doi:
        resp = requests.get(f"https://api.crossref.org/works/{doi}")
        if resp.status_code == 200:
            sources_found.append("CrossRef")

    # 檢查 arXiv
    if arxiv_id:
        resp = requests.get(
            f"http://export.arxiv.org/api/query?id_list={arxiv_id}"
        )
        if "<entry>" in resp.text:
            sources_found.append("arXiv")

    return len(sources_found) >= 2, sources_found
```

### 步驟 3: 獲取 BibTeX

使用 DOI 內容協商以保證準確性：

```python
import requests

def doi_to_bibtex(doi: str) -> str:
    """透過 CrossRef 內容協商從 DOI 獲取經驗證的 BibTeX。"""
    response = requests.get(
        f"https://doi.org/{doi}",
        headers={"Accept": "application/x-bibtex"},
        allow_redirects=True
    )
    response.raise_for_status()
    return response.text

# 範例："Attention Is All You Need"
bibtex = doi_to_bibtex("10.48550/arXiv.1706.03762")
print(bibtex)
```

### 步驟 4: 確效聲明 (Validate Claims)

在引用論文支持特定聲明之前，請驗證該聲明是否存在：

```python
def get_paper_abstract(doi):
    """獲取摘要以驗證聲明。"""
    sch = SemanticScholar()
    paper = sch.get_paper(f"DOI:{doi}")
    return paper.abstract if paper else None

# 驗證聲明出現在摘要中
abstract = get_paper_abstract("10.48550/arXiv.1706.03762")
claim = "attention mechanism"
if claim.lower() in abstract.lower():
    print("聲明出現在論文中")
```

### 步驟 5: 新增至參考書目

將驗證過的條目新增至您的 .bib 檔案中，並使用一致的鍵 (key) 格式：

```python
def generate_citation_key(bibtex: str) -> str:
    """生成一致的引用鍵：author_year_firstword。"""
    import re

    # 提取作者
    author_match = re.search(r'author\s*=\s*\{([^}]+)\}', bibtex, re.I)
    if author_match:
        first_author = author_match.group(1).split(',')[0].split()[-1]
    else:
        first_author = "unknown"

    # 提取年份
    year_match = re.search(r'year\s*=\s*\{?(\d{4})\}?', bibtex, re.I)
    year = year_match.group(1) if year_match else "0000"

    # 提取標題第一個字
    title_match = re.search(r'title\s*=\s*\{([^}]+)\}', bibtex, re.I)
    if title_match:
        first_word = title_match.group(1).split()[0].lower()
        first_word = re.sub(r'[^a-z]', '', first_word)
    else:
        first_word = "paper"

    return f"{first_author.lower()}_{year}_{first_word}"
```

---

## Python 實作

### 完整的 Citation Manager 類別

{% raw %}
```python
"""
Citation Manager - 針對 ML 論文的經驗證引用流程。
"""

import requests
import time
from typing import Optional, List, Dict, Tuple
from dataclasses import dataclass

try:
    from semanticscholar import SemanticScholar
except ImportError:
    print("安裝: pip install semanticscholar")
    SemanticScholar = None

@dataclass
class Paper:
    title: str
    authors: List[str]
    year: int
    doi: Optional[str]
    arxiv_id: Optional[str]
    venue: Optional[str]
    citation_count: int
    abstract: Optional[str]

class CitationManager:
    """管理並驗證引用。"""

    def __init__(self, api_key: Optional[str] = None):
        self.sch = SemanticScholar(api_key=api_key) if SemanticScholar else None
        self.verified_papers: Dict[str, Paper] = {}

    def search(self, query: str, limit: int = 10) -> List[Paper]:
        """使用 Semantic Scholar 搜尋論文。"""
        if not self.sch:
            raise RuntimeError("無法使用 Semantic Scholar")

        results = self.sch.search_paper(query, limit=limit)
        papers = []

        for r in results:
            paper = Paper(
                title=r.title,
                authors=[a.name for a in (r.authors or [])],
                year=r.year or 0,
                doi=r.externalIds.get('DOI') if r.externalIds else None,
                arxiv_id=r.externalIds.get('ArXiv') if r.externalIds else None,
                venue=r.venue,
                citation_count=r.citationCount or 0,
                abstract=r.abstract
            )
            papers.append(paper)

        return papers

    def verify(self, paper: Paper) -> Tuple[bool, List[str]]:
        """驗證論文是否存在於多個來源中。"""
        sources = []

        # 透過搜尋已經在 Semantic Scholar 中找到
        sources.append("Semantic Scholar")

        # 若有 DOI 則檢查 CrossRef
        if paper.doi:
            try:
                resp = requests.get(
                    f"https://api.crossref.org/works/{paper.doi}",
                    timeout=10
                )
                if resp.status_code == 200:
                    sources.append("CrossRef")
            except Exception:
                pass

        # 若有 ID 則檢查 arXiv
        if paper.arxiv_id:
            try:
                resp = requests.get(
                    f"http://export.arxiv.org/api/query?id_list={paper.arxiv_id}",
                    timeout=10
                )
                if "<entry>" in resp.text and "<title>" in resp.text:
                    sources.append("arXiv")
            except Exception:
                pass

        return len(sources) >= 2, sources

    def get_bibtex(self, paper: Paper) -> Optional[str]:
        """獲取經驗證論文的 BibTeX。"""
        if paper.doi:
            try:
                resp = requests.get(
                    f"https://doi.org/{paper.doi}",
                    headers={"Accept": "application/x-bibtex"},
                    timeout=10,
                    allow_redirects=True
                )
                if resp.status_code == 200:
                    return resp.text
            except Exception:
                pass

        # 備案：從論文資料生成
        return self._generate_bibtex(paper)

    def _generate_bibtex(self, paper: Paper) -> str:
        """從論文元資料生成 BibTeX。"""
        # 生成引用鍵
        first_author = paper.authors[0].split()[-1] if paper.authors else "unknown"
        first_word = paper.title.split()[0].lower().replace(',', '').replace(':', '')
        key = f"{first_author.lower()}_{paper.year}_{first_word}"

        # 格式化作者
        authors = " and ".join(paper.authors) if paper.authors else "Unknown"

        bibtex = f"""@article{{{key},
  title = {{{paper.title}}},
  author = {{{authors}}},
  year = {{{paper.year}}},
  {'doi = {' + paper.doi + '},' if paper.doi else ''}
  {'eprint = {' + paper.arxiv_id + '},' if paper.arxiv_id else ''}
  {'journal = {' + paper.venue + '},' if paper.venue else ''}
}}"""
        return bibtex

    def cite(self, query: str) -> Optional[str]:
        """完整流程：搜尋、驗證、回傳 BibTeX。"""
        # 搜尋
        papers = self.search(query, limit=5)
        if not papers:
            return None

        # 取最高排名結果
        paper = papers[0]

        # 驗證
        verified, sources = self.verify(paper)
        if not verified:
            print(f"警告：只能在 {sources} 中驗證")

        # 獲取 BibTeX
        bibtex = self.get_bibtex(paper)

        # 快取
        if bibtex:
            self.verified_papers[paper.title] = paper

        return bibtex


# 使用範例
if __name__ == "__main__":
    cm = CitationManager()

    # 搜尋並引用
    bibtex = cm.cite("attention is all you need transformer")
    if bibtex:
        print(bibtex)
```
{% endraw %}

### 快速函數

```python
def quick_cite(query: str) -> str:
    """單行引用。"""
    cm = CitationManager()
    return cm.cite(query)

def batch_cite(queries: List[str], output_file: str = "references.bib"):
    """引用多篇論文並儲存至檔案。"""
    cm = CitationManager()
    bibtex_entries = []

    for query in queries:
        print(f"處理中: {query}")
        bibtex = cm.cite(query)
        if bibtex:
            bibtex_entries.append(bibtex)
        time.sleep(1)  # 速率限制

    with open(output_file, 'w') as f:
        f.write("\n\n".join(bibtex_entries))

    print(f"已儲存 {len(bibtex_entries)} 個引用至 {output_file}")
```

---

## BibTeX 管理

### BibTeX vs BibLaTeX

| 功能 | BibTeX | BibLaTeX |
|---------|--------|----------|
| Unicode 支援 | 有限 | 完整 |
| 條目類型 | 標準 | 擴充 (@online, @dataset) |
| 客製化 | 有限 | 高度靈活 |
| 後端 (Backend) | bibtex | Biber (建議) |

**建議**：對於會議提交，請使用 natbib 搭配 BibTeX — 所有主要會議模板 (NeurIPS, ICML, ICLR, ACL, AAAI, COLM) 都內建了 natbib 和 `.bst` 檔案。對於期刊或您可以控制模板的個人專案，BibLaTeX 搭配 Biber 是一個選擇。

### LaTeX 設定

```latex
% 在導言區 (preamble) 中
\usepackage[
    backend=biber,
    style=numeric,
    sorting=none
]{biblatex}
\addbibresource{references.bib}

% 在文件中
\cite{vaswani_2017_attention}

% 在最後
\printbibliography
```

### 引用指令

```latex
\cite{key}      % 數字：[1]
\citep{key}     % 括號：(Author, 2020)
\citet{key}     % 文字：Author (2020)
\citeauthor{key} % 僅作者姓名
\citeyear{key}  % 僅年份
```

### 一致的引用鍵

使用格式：`author_year_firstword`

```
vaswani_2017_attention
devlin_2019_bert
brown_2020_language
```

---

## 常見引用格式

### 會議論文 (Conference Paper)

```bibtex
@inproceedings{vaswani_2017_attention,
  title = {Attention Is All You Need},
  author = {Vaswani, Ashish and Shazeer, Noam and Parmar, Niki and
            Uszkoreit, Jakob and Jones, Llion and Gomez, Aidan N and
            Kaiser, Lukasz and Polosukhin, Illia},
  booktitle = {Advances in Neural Information Processing Systems},
  volume = {30},
  year = {2017},
  publisher = {Curran Associates, Inc.}
}
```

### 期刊文章 (Journal Article)

```bibtex
@article{hochreiter_1997_long,
  title = {Long Short-Term Memory},
  author = {Hochreiter, Sepp and Schmidhuber, J{\"u}rgen},
  journal = {Neural Computation},
  volume = {9},
  number = {8},
  pages = {1735--1780},
  year = {1997},
  publisher = {MIT Press}
}
```

### arXiv 預印本 (arXiv Preprint)

```bibtex
@misc{brown_2020_language,
  title = {Language Models are Few-Shot Learners},
  author = {Brown, Tom and Mann, Benjamin and Ryder, Nick and others},
  year = {2020},
  eprint = {2005.14165},
  archiveprefix = {arXiv},
  primaryclass = {cs.CL}
}
```

---

## 疑難排解

### 常見問題

**問題：Semantic Scholar 未返回任何結果**
- 嘗試更具體的關鍵字
- 檢查作者姓名的拼寫
- 使用引號以進行精確片語搜尋

**問題：DOI 無法解析為 BibTeX**
- DOI 可能已註冊但未連結到 CrossRef
- 如果有，請改試 arXiv ID
- 從元資料中手動生成 BibTeX

**問題：速率限制錯誤 (Rate limiting errors)**
- 在請求之間添加延遲 (1-3 秒)
- 如果有 API 金鑰，請使用它
- 快取結果以避免重複查詢

**問題：BibTeX 中的編碼問題**
- 使用適當的 LaTeX 跳脫字元：`{\"u}` 代表 ü
- 確保檔案為 UTF-8 編碼
- 使用 BibLaTeX 搭配 Biber 以獲得更好的 Unicode 支援

### 驗證檢查表

在添加引用之前：

- [ ] 論文在至少 2 個來源中被找到
- [ ] 已驗證 DOI 或 arXiv ID
- [ ] 已獲取 BibTeX（非從記憶中生成）
- [ ] 條目類型正確（@inproceedings vs @article）
- [ ] 作者姓名完整且格式正確
- [ ] 已驗證年份和場合
- [ ] 引用鍵遵循一致的格式

---

## 額外資源

**APIs:**
- Semantic Scholar: https://api.semanticscholar.org/api-docs/
- CrossRef: https://www.crossref.org/documentation/retrieve-metadata/rest-api/
- arXiv: https://info.arxiv.org/help/api/basics.html
- OpenAlex: https://docs.openalex.org/

**Python 函式庫:**
- `semanticscholar`: https://pypi.org/project/semanticscholar/
- `arxiv`: https://pypi.org/project/arxiv/
- `habanero` (CrossRef): https://github.com/sckott/habanero

**驗證工具:**
- Citely: https://citely.ai/citation-checker
- ReciteWorks: https://reciteworks.com/
