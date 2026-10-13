---
name: arxiv
description: 使用免費的 REST API 從 arXiv 搜索和檢索學術論文。無需 API key。可按關鍵字、作者、類別或 ID 進行搜索。結合 web_extract 或 ocr-and-documents 技能來閱讀完整的論文內容。
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [研究, Arxiv, 論文, 學術, 科學, API]
    related_skills: [ocr-and-documents]
---

# arXiv 研究

透過免費的 REST API 從 arXiv 搜索和檢索學術論文。無需 API key，無依賴項 —— 僅需使用 curl。

## 快速參考

| 操作 | 指令 |
|--------|---------|
| 搜索論文 | `curl "https://export.arxiv.org/api/query?search_query=all:QUERY&max_results=5"` |
| 獲取特定論文 | `curl "https://export.arxiv.org/api/query?id_list=2402.03300"` |
| 閱讀摘要 (網頁) | `web_extract(urls=["https://arxiv.org/abs/2402.03300"])` |
| 閱讀全文 (PDF) | `web_extract(urls=["https://arxiv.org/pdf/2402.03300"])` |

## 搜索論文

API 返回 Atom XML。使用 `grep`/`sed` 解析或透過 `python3` 導出乾淨的輸出。

### 基本搜索

```bash
curl -s "https://export.arxiv.org/api/query?search_query=all:GRPO+reinforcement+learning&max_results=5"
```

### 乾淨的輸出 (將 XML 解析為可讀格式)

```bash
curl -s "https://export.arxiv.org/api/query?search_query=all:GRPO+reinforcement+learning&max_results=5&sortBy=submittedDate&sortOrder=descending" | python3 -c "
import sys, xml.etree.ElementTree as ET
ns = {'a': 'http://www.w3.org/2005/Atom'}
root = ET.parse(sys.stdin).getroot()
for i, entry in enumerate(root.findall('a:entry', ns)):
    title = entry.find('a:title', ns).text.strip().replace('\n', ' ')
    arxiv_id = entry.find('a:id', ns).text.strip().split('/abs/')[-1]
    published = entry.find('a:published', ns).text[:10]
    authors = ', '.join(a.find('a:name', ns).text for a in entry.findall('a:author', ns))
    summary = entry.find('a:summary', ns).text.strip()[:200]
    cats = ', '.join(c.get('term') for c in entry.findall('a:category', ns))
    print(f'{i+1}. [{arxiv_id}] {title}')
    print(f'   Authors: {authors}')
    print(f'   Published: {published} | Categories: {cats}')
    print(f'   Abstract: {summary}...')
    print(f'   PDF: https://arxiv.org/pdf/{arxiv_id}')
    print()
"
```

## 搜索查詢語法

| 前綴 | 搜索內容 | 範例 |
|--------|----------|---------|
| `all:` | 所有欄位 | `all:transformer+attention` |
| `ti:` | 標題 | `ti:large+language+models` |
| `au:` | 作者 | `au:vaswani` |
| `abs:` | 摘要 | `abs:reinforcement+learning` |
| `cat:` | 類別 | `cat:cs.AI` |
| `co:` | 評論 | `co:accepted+NeurIPS` |

### 布林運算元

```
# AND (使用 + 時的預設值)
search_query=all:transformer+attention

# OR
search_query=all:GPT+OR+all:BERT

# AND NOT
search_query=all:language+model+ANDNOT+all:vision

# 精確字句
search_query=ti:"chain+of+thought"

# 組合使用
search_query=au:hinton+AND+cat:cs.LG
```

## 排序與分頁

| 參數 | 選項 |
|-----------|---------|
| `sortBy` | `relevance`, `lastUpdatedDate`, `submittedDate` |
| `sortOrder` | `ascending`, `descending` |
| `start` | 結果偏移量 (從 0 開始) |
| `max_results` | 結果數量 (預設 10, 最大 30000) |

```bash
# cs.AI 類別中最新的 10 篇論文
curl -s "https://export.arxiv.org/api/query?search_query=cat:cs.AI&sortBy=submittedDate&sortOrder=descending&max_results=10"
```

## 獲取特定論文

```bash
# 透過 arXiv ID
curl -s "https://export.arxiv.org/api/query?id_list=2402.03300"

# 多篇論文
curl -s "https://export.arxiv.org/api/query?id_list=2402.03300,2401.12345,2403.00001"
```

## BibTeX 生成

獲取論文的中繼資料後，生成 BibTeX 條目：

{% raw %}
```bash
curl -s "https://export.arxiv.org/api/query?id_list=1706.03762" | python3 -c "
import sys, xml.etree.ElementTree as ET
ns = {'a': 'http://www.w3.org/2005/Atom', 'arxiv': 'http://arxiv.org/schemas/atom'}
root = ET.parse(sys.stdin).getroot()
entry = root.find('a:entry', ns)
if entry is None: sys.exit('Paper not found')
title = entry.find('a:title', ns).text.strip().replace('\n', ' ')
authors = ' and '.join(a.find('a:name', ns).text for a in entry.findall('a:author', ns))
year = entry.find('a:published', ns).text[:4]
raw_id = entry.find('a:id', ns).text.strip().split('/abs/')[-1]
cat = entry.find('arxiv:primary_category', ns)
primary = cat.get('term') if cat is not None else 'cs.LG'
last_name = entry.find('a:author', ns).find('a:name', ns).text.split()[-1]
print(f'@article{{{last_name}{year}_{raw_id.replace(\".\", \"\")},')
print(f'  title     = {{{title}}},')
print(f'  author    = {{{authors}}},')
print(f'  year      = {{{year}}},')
print(f'  eprint    = {{{raw_id}}},')
print(f'  archivePrefix = {{arXiv}},')
print(f'  primaryClass  = {{{primary}}},')
print(f'  url       = {{https://arxiv.org/abs/{raw_id}}}')
print('}')
"
```
{% endraw %}

## 閱讀論文內容

找到論文後，可以進行閱讀：

```
# 摘要頁面 (快速，包含中繼資料 + 摘要)
web_extract(urls=["https://arxiv.org/abs/2402.03300"])

# 全文 (透過 Firecrawl 將 PDF 轉換為 markdown)
web_extract(urls=["https://arxiv.org/pdf/2402.03300"])
```

關於本地 PDF 處理，請參閱 `ocr-and-documents` 技能。

## 常見類別

| 類別 | 領域 |
|----------|-------|
| `cs.AI` | 人工智慧 (Artificial Intelligence) |
| `cs.CL` | 計算與語言 (NLP) |
| `cs.CV` | 電腦視覺 (Computer Vision) |
| `cs.LG` | 機器學習 (Machine Learning) |
| `cs.CR` | 密碼學與安全 (Cryptography and Security) |
| `stat.ML` | 機器學習 (統計學) |
| `math.OC` | 最佳化與控制 (Optimization and Control) |
| `physics.comp-ph` | 計算物理 (Computational Physics) |

完整清單：https://arxiv.org/category_taxonomy

## 輔助腳本

`scripts/search_arxiv.py` 腳本可處理 XML 解析並提供乾淨的輸出：

```bash
python scripts/search_arxiv.py "GRPO reinforcement learning"
python scripts/search_arxiv.py "transformer attention" --max 10 --sort date
python scripts/search_arxiv.py --author "Yann LeCun" --max 5
python scripts/search_arxiv.py --category cs.AI --sort date
python scripts/search_arxiv.py --id 2402.03300
python scripts/search_arxiv.py --id 2402.03300,2401.12345
```

無依賴項 —— 僅使用 Python 標準庫。

---

## Semantic Scholar (引用、相關論文、作者個人資料)

arXiv 不提供引用數據或推薦。請使用 **Semantic Scholar API** —— 免費，基本使用無需 key (1 req/sec)，返回 JSON。

### 獲取論文詳情 + 引用

```bash
# 透過 arXiv ID
curl -s "https://api.semanticscholar.org/graph/v1/paper/arXiv:2402.03300?fields=title,authors,citationCount,referenceCount,influentialCitationCount,year,abstract" | python3 -m json.tool

# 透過 Semantic Scholar 論文 ID 或 DOI
curl -s "https://api.semanticscholar.org/graph/v1/paper/DOI:10.1234/example?fields=title,citationCount"
```

### 獲取論文的引用 (誰引用了它)

```bash
curl -s "https://api.semanticscholar.org/graph/v1/paper/arXiv:2402.03300/citations?fields=title,authors,year,citationCount&limit=10" | python3 -m json.tool
```

### 獲取論文中的參考文獻 (它引用了什麼)

```bash
curl -s "https://api.semanticscholar.org/graph/v1/paper/arXiv:2402.03300/references?fields=title,authors,year,citationCount&limit=10" | python3 -m json.tool
```

### 搜索論文 (arXiv 搜索的替代方案，返回 JSON)

```bash
curl -s "https://api.semanticscholar.org/graph/v1/paper/search?query=GRPO+reinforcement+learning&limit=5&fields=title,authors,year,citationCount,externalIds" | python3 -m json.tool
```

### 獲取論文推薦

```bash
curl -s -X POST "https://api.semanticscholar.org/recommendations/v1/papers/" \
  -H "Content-Type: application/json" \
  -d '{"positivePaperIds": ["arXiv:2402.03300"], "negativePaperIds": []}' | python3 -m json.tool
```

### 作者個人資料

```bash
curl -s "https://api.semanticscholar.org/graph/v1/author/search?query=Yann+LeCun&fields=name,hIndex,citationCount,paperCount" | python3 -m json.tool
```

### 有用的 Semantic Scholar 欄位

`title`, `authors`, `year`, `abstract`, `citationCount`, `referenceCount`, `influentialCitationCount`, `isOpenAccess`, `openAccessPdf`, `fieldsOfStudy`, `publicationVenue`, `externalIds` (包含 arXiv ID, DOI 等)

---

## 完整研究工作流

1. **探索**: `python scripts/search_arxiv.py "您的主題" --sort date --max 10`
2. **評估影響力**: `curl -s "https://api.semanticscholar.org/graph/v1/paper/arXiv:ID?fields=citationCount,influentialCitationCount"`
3. **閱讀摘要**: `web_extract(urls=["https://arxiv.org/abs/ID"])`
4. **閱讀全文**: `web_extract(urls=["https://arxiv.org/pdf/ID"])`
5. **尋找相關研究**: `curl -s "https://api.semanticscholar.org/graph/v1/paper/arXiv:ID/references?fields=title,citationCount&limit=20"`
6. **獲取推薦**: 向 Semantic Scholar 推薦端點發送 POST 請求
7. **追蹤作者**: `curl -s "https://api.semanticscholar.org/graph/v1/author/search?query=NAME"`

## 速率限制

| API | 速率 | 驗證 |
|-----|------|------|
| arXiv | 約每 3 秒 1 次請求 | 無需驗證 |
| Semantic Scholar | 每秒 1 次請求 | 無 (使用 API key 可達 100/sec) |

## 注意事項

- arXiv 返回 Atom XML —— 使用輔助腳本或解析程式碼片段來獲得乾淨的輸出
- Semantic Scholar 返回 JSON —— 透過 `python3 -m json.tool` 導出以提高可讀性
- arXiv IDs: 舊格式 (`hep-th/0601001`) vs 新格式 (`2402.03300`)
- PDF: `https://arxiv.org/pdf/{id}` —— 摘要: `https://arxiv.org/abs/{id}`
- HTML (可用時): `https://arxiv.org/html/{id}`
- 關於本地 PDF 處理，請參閱 `ocr-and-documents` 技能

## ID 版本控制

- `arxiv.org/abs/1706.03762` 總是解析為 **最新** 版本
- `arxiv.org/abs/1706.03762v1` 指向 **特定** 的不可變版本
- 生成引用時，請保留您實際閱讀的版本後綴，以防止引用偏移 (之後的版本可能會大幅更改內容)
- API 的 `<id>` 欄位返回帶有版本的 URL (例如 `http://arxiv.org/abs/1706.03762v7`)

## 撤回的論文

論文在提交後可能會被撤回。當這種情況發生時：
- `<summary>` 欄位會包含撤回通知 (尋找 "withdrawn" 或 "retracted")
- 中繼資料欄位可能不完整
- 在將結果視為有效論文之前，請務必檢查摘要
