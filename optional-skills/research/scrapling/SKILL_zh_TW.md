---
name: scrapling
description: 使用 Scrapling 進行網頁爬取 - 包含 HTTP 擷取、隱身瀏覽器自動化、Cloudflare 繞過，以及透過 CLI 和 Python 進行蜘蛛爬行。
version: 1.0.0
author: FEUAZUR
license: MIT
metadata:
  hermes:
    tags: [網頁爬取, 瀏覽器, Cloudflare, 隱身, 爬行, 蜘蛛]
    related_skills: [duckduckgo-search, domain-intel]
    homepage: https://github.com/D4Vinci/Scrapling
prerequisites:
  commands: [scrapling, python]
---

# Scrapling

[Scrapling](https://github.com/D4Vinci/Scrapling) 是一個具備反機器人繞過、隱身瀏覽器自動化和蜘蛛框架的網頁爬取框架。它提供三種擷取策略（HTTP、動態 JS、隱身/Cloudflare）和完整的 CLI。

**此技能僅用於教育和研究目的。** 使用者必須遵守當地/國際數據爬取法律並尊重網站服務條款 (ToS)。

## 何時使用

- 爬取靜態 HTML 頁面（比瀏覽器工具更快）
- 爬取需要真實瀏覽器的 JS 渲染頁面
- 繞過 Cloudflare Turnstile 或機器人檢測
- 使用蜘蛛爬行多個頁面
- 當內建的 `web_extract` 工具無法回傳你需要的數據時

## 安裝

```bash
pip install "scrapling[all]"
scrapling install
```

最小化安裝（僅 HTTP，無瀏覽器）：
```bash
pip install scrapling
```

僅包含瀏覽器自動化：
```bash
pip install "scrapling[fetchers]"
scrapling install
```

## 快速參考

| 方法 | 類別 (Class) | 使用時機 |
|----------|-------|----------|
| HTTP | `Fetcher` / `FetcherSession` | 靜態頁面、API、快速批量請求 |
| 動態 | `DynamicFetcher` / `DynamicSession` | JS 渲染內容、單頁應用 (SPA) |
| 隱身 | `StealthyFetcher` / `StealthySession` | Cloudflare、受反機器人保護的網站 |
| 蜘蛛 | `Spider` | 追蹤連結的多頁面爬行 |

## CLI 用法

### 擷取靜態頁面

```bash
scrapling extract get 'https://example.com' output.md
```

使用 CSS 選擇器和瀏覽器偽裝：

```bash
scrapling extract get 'https://example.com' output.md \
  --css-selector '.content' \
  --impersonate 'chrome'
```

### 擷取 JS 渲染頁面

```bash
scrapling extract fetch 'https://example.com' output.md \
  --css-selector '.dynamic-content' \
  --disable-resources \
  --network-idle
```

### 擷取受 Cloudflare 保護的頁面

```bash
scrapling extract stealthy-fetch 'https://protected-site.com' output.html \
  --solve-cloudflare \
  --block-webrtc \
  --hide-canvas
```

### POST 請求

```bash
scrapling extract post 'https://example.com/api' output.json \
  --json '{"query": "search term"}'
```

### 輸出格式

輸出格式由副檔名決定：
- `.html` -- 原始 HTML
- `.md` -- 轉換為 Markdown
- `.txt` -- 純文字
- `.json` / `.jsonl` -- JSON

## Python: HTTP 爬取

### 單次請求

```python
from scrapling.fetchers import Fetcher

page = Fetcher.get('https://quotes.toscrape.com/')
quotes = page.css('.quote .text::text').getall()
for q in quotes:
    print(q)
```

### 工作階段 (Session，持久化 Cookie)

```python
from scrapling.fetchers import FetcherSession

with FetcherSession(impersonate='chrome') as session:
    page = session.get('https://example.com/', stealthy_headers=True)
    links = page.css('a::attr(href)').getall()
    for link in links[:5]:
        sub = session.get(link)
        print(sub.css('h1::text').get())
```

### POST / PUT / DELETE

```python
page = Fetcher.post('https://api.example.com/data', json={"key": "value"})
page = Fetcher.put('https://api.example.com/item/1', data={"name": "updated"})
page = Fetcher.delete('https://api.example.com/item/1')
```

### 使用代理 (Proxy)

```python
page = Fetcher.get('https://example.com', proxy='http://user:pass@proxy:8080')
```

## Python: 動態頁面 (JS 渲染)

用於需要執行 JavaScript 的頁面（SPA、延遲加載內容）：

```python
from scrapling.fetchers import DynamicFetcher

page = DynamicFetcher.fetch('https://example.com', headless=True)
data = page.css('.js-loaded-content::text').getall()
```

### 等待特定元素

```python
page = DynamicFetcher.fetch(
    'https://example.com',
    wait_selector=('.results', 'visible'),
    network_idle=True,
)
```

### 停用資源以加速

封鎖字體、圖片、媒體、樣式表（約快 25%）：

```python
from scrapling.fetchers import DynamicSession

with DynamicSession(headless=True, disable_resources=True, network_idle=True) as session:
    page = session.fetch('https://example.com')
    items = page.css('.item::text').getall()
```

### 自定義頁面自動化

```python
from playwright.sync_api import Page
from scrapling.fetchers import DynamicFetcher

def scroll_and_click(page: Page):
    page.mouse.wheel(0, 3000)
    page.wait_for_timeout(1000)
    page.click('button.load-more')
    page.wait_for_selector('.extra-results')

page = DynamicFetcher.fetch('https://example.com', page_action=scroll_and_click)
results = page.css('.extra-results .item::text').getall()
```

## Python: 隱身模式 (繞過反機器人)

用於受 Cloudflare 保護或具有強大指紋識別的網站：

```python
from scrapling.fetchers import StealthyFetcher

page = StealthyFetcher.fetch(
    'https://protected-site.com',
    headless=True,
    solve_cloudflare=True,
    block_webrtc=True,
    hide_canvas=True,
)
content = page.css('.protected-content::text').getall()
```

### 隱身工作階段 (Stealth Session)

```python
from scrapling.fetchers import StealthySession

with StealthySession(headless=True, solve_cloudflare=True) as session:
    page1 = session.fetch('https://protected-site.com/page1')
    page2 = session.fetch('https://protected-site.com/page2')
```

## 元素選取

所有擷取器都會回傳一個具備以下方法的 `Selector` 物件：

### CSS 選擇器

```python
page.css('h1::text').get()              # 第一個 h1 文字
page.css('a::attr(href)').getall()      # 所有連結 href
page.css('.quote .text::text').getall() # 巢狀選取
```

### XPath

```python
page.xpath('//div[@class="content"]/text()').getall()
page.xpath('//a/@href').getall()
```

### 尋找方法

```python
page.find_all('div', class_='quote')       # 透過標籤 + 屬性
page.find_by_text('Read more', tag='a')    # 透過文字內容
page.find_by_regex(r'\$\d+\.\d{2}')       # 透過正規表達式
```

### 相似元素

尋找結構相似的元素（適用於產品列表等）：

```python
first_product = page.css('.product')[0]
all_similar = first_product.find_similar()
```

### 導覽

```python
el = page.css('.target')[0]
el.parent                # 父元素
el.children              # 子元素
el.next_sibling          # 下一個同級元素
el.prev_sibling          # 上一個同級元素
```

## Python: 蜘蛛框架 (Spider Framework)

追蹤連結的多頁面爬行：

```python
from scrapling.spiders import Spider, Request, Response

class QuotesSpider(Spider):
    name = "quotes"
    start_urls = ["https://quotes.toscrape.com/"]
    concurrent_requests = 10
    download_delay = 1

    async def parse(self, response: Response):
        for quote in response.css('.quote'):
            yield {
                "text": quote.css('.text::text').get(),
                "author": quote.css('.author::text').get(),
                "tags": quote.css('.tag::text').getall(),
            }

        next_page = response.css('.next a::attr(href)').get()
        if next_page:
            yield response.follow(next_page)

result = QuotesSpider().start()
print(f"Scraped {len(result.items)} quotes")
result.items.to_json("quotes.json")
```

### 多工作階段蜘蛛 (Multi-Session Spider)

將請求路由到不同的擷取器類型：

```python
from scrapling.fetchers import FetcherSession, AsyncStealthySession

class SmartSpider(Spider):
    name = "smart"
    start_urls = ["https://example.com/"]

    def configure_sessions(self, manager):
        manager.add("fast", FetcherSession(impersonate="chrome"))
        manager.add("stealth", AsyncStealthySession(headless=True), lazy=True)

    async def parse(self, response: Response):
        for link in response.css('a::attr(href)').getall():
            if "protected" in link:
                yield Request(link, sid="stealth")
            else:
                yield Request(link, sid="fast", callback=self.parse)
```

### 暫停/恢復爬行

```python
spider = QuotesSpider(crawldir="./crawl_checkpoint")
spider.start()  # Ctrl+C 暫停，重新執行即可從檢查點恢復
```

## 注意事項

- **需要安裝瀏覽器**：在 pip install 之後執行 `scrapling install` -- 否則 `DynamicFetcher` 和 `StealthyFetcher` 將會失敗
- **逾時**：DynamicFetcher/StealthyFetcher 的逾時單位是**毫秒** (預設 30000)，Fetcher 的逾時單位是**秒**
- **Cloudflare 繞過**：`solve_cloudflare=True` 會增加 5-15 秒的擷取時間 -- 僅在需要時啟用
- **資源消耗**：StealthyFetcher 執行真實的瀏覽器 -- 請限制同時使用量
- **法律**：在爬取前務必檢查 robots.txt 和網站 ToS。此函式庫僅用於教育和研究目的
- **Python 版本**：需要 Python 3.10+
