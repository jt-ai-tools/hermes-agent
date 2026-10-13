---
name: duckduckgo-search
description: 透過 DuckDuckGo 進行免費網頁搜尋 — 包含文字、新聞、圖片、影片。無需 API 金鑰。安裝後偏好使用 `ddgs` CLI；僅在驗證當前執行環境可用後，才使用 Python DDGS 函式庫。
version: 1.3.0
author: gamedevCloudy
license: MIT
metadata:
  hermes:
    tags: [search, duckduckgo, web-search, free, fallback]
    related_skills: [arxiv]
    fallback_for_toolsets: [web]
---

# DuckDuckGo 搜尋 (DuckDuckGo Search)

使用 DuckDuckGo 進行免費網頁搜尋。**無需 API 金鑰。**

當 `web_search` 不可用或不適用時（例如未設定 `FIRECRAWL_API_KEY` 時），偏好使用此技能。也可以在特別需要 DuckDuckGo 結果時作為獨立的搜尋路徑使用。

## 檢測流程

在選擇方法前，請先檢查實際可用內容：

```bash
# 檢查 CLI 是否可用
command -v ddgs >/dev/null && echo "DDGS_CLI=installed" || echo "DDGS_CLI=missing"
```

決策樹：
1. 如果已安裝 `ddgs` CLI，偏好使用 `terminal` + `ddgs`。
2. 如果缺少 `ddgs` CLI，不要假設 `execute_code` 可以匯入 `ddgs`。
3. 如果使用者特別需要 DuckDuckGo 搜尋，請先在相關環境中安裝 `ddgs`。
4. 否則，請退而使用內建的 web/browser 工具。

重要執行備註：
- Terminal 和 `execute_code` 是分開的執行環境。
- 在 Shell 中安裝成功並不保證 `execute_code` 可以匯入 `ddgs`。
- 絕不要假設 `execute_code` 沙箱中預裝了第三方 Python 套件。

## 安裝

僅在特別需要 DuckDuckGo 搜尋且執行環境尚未提供時安裝 `ddgs`。

```bash
# Python 套件 + CLI 入口
pip install ddgs

# 驗證 CLI
ddgs --help
```

如果工作流依賴 Python 匯入，請在執行 `from ddgs import DDGS` 之前，驗證該執行環境是否可以匯入 `ddgs`。

## 方法 1：CLI 搜尋 (偏好)

當 `ddgs` 指令存在時，透過 `terminal` 使用。這是偏好的路徑，因為它避免了假設 `execute_code` 沙箱已安裝 `ddgs` Python 套件。

```bash
# 文字搜尋
ddgs text -k "python async programming" -m 5

# 新聞搜尋
ddgs news -k "artificial intelligence" -m 5

# 圖片搜尋
ddgs images -k "landscape photography" -m 10

# 影片搜尋
ddgs videos -k "python tutorial" -m 5

# 搭配地區過濾
ddgs text -k "best restaurants" -m 5 -r us-en

# 僅限近期結果 (d=日, w=週, m=月, y=年)
ddgs text -k "latest AI news" -m 5 -t w

# JSON 輸出以利解析
ddgs text -k "fastapi tutorial" -m 5 -o json
```

### CLI 旗標

| 旗標 | 說明 | 範例 |
|------|-------------|---------|
| `-k` | 關鍵字 (查詢詞) — **必要** | `-k "search terms"` |
| `-m` | 最大結果數 | `-m 5` |
| `-r` | 地區 | `-r us-en` |
| `-t` | 時間限制 | `-t w` (週) |
| `-s` | 安全搜尋 | `-s off` |
| `-o` | 輸出格式 | `-o json` |

## 方法 2：Python API (僅在驗證後使用)

僅在驗證 `ddgs` 已安裝後，才在 `execute_code` 或其他 Python 執行環境中使用 `DDGS` 類別。不要假設 `execute_code` 預設包含第三方套件。

安全用詞：
- 「如果需要，請在安裝或驗證套件後，搭配 `ddgs` 使用 `execute_code`」

避免說：
- 「`execute_code` 包含 `ddgs`」
- 「DuckDuckGo 搜尋在 `execute_code` 中預設可用」

**重要：** `max_results` 必須一律作為**關鍵字引數 (Keyword argument)** 傳入 — 在所有方法中使用位置引數都會拋出錯誤。

### 文字搜尋

最適用於：一般研究、公司資訊、文件查詢。

```python
from ddgs import DDGS

with DDGS() as ddgs:
    for r in ddgs.text("python async programming", max_results=5):
        print(r["title"])
        print(r["href"])
        print(r.get("body", "")[:200])
        print()
```

回傳欄位：`title`, `href`, `body`

### 新聞搜尋

最適用於：時事、即時新聞、最新更新。

```python
from ddgs import DDGS

with DDGS() as ddgs:
    for r in ddgs.news("AI regulation 2026", max_results=5):
        print(r["date"], "-", r["title"])
        print(r.get("source", ""), "|", r["url"])
        print(r.get("body", "")[:200])
        print()
```

回傳欄位：`date`, `title`, `body`, `url`, `image`, `source`

### 圖片搜尋

最適用於：視覺參考、產品圖片、圖表。

```python
from ddgs import DDGS

with DDGS() as ddgs:
    for r in ddgs.images("semiconductor chip", max_results=5):
        print(r["title"])
        print(r["image"])
        print(r.get("thumbnail", ""))
        print(r.get("source", ""))
        print()
```

回傳欄位：`title`, `image`, `thumbnail`, `url`, `height`, `width`, `source`

### 影片搜尋

最適用於：教學、演示、說明影片。

```python
from ddgs import DDGS

with DDGS() as ddgs:
    for r in ddgs.videos("FastAPI tutorial", max_results=5):
        print(r["title"])
        print(r.get("content", ""))
        print(r.get("duration", ""))
        print(r.get("provider", ""))
        print(r.get("published", ""))
        print()
```

回傳欄位：`title`, `content`, `description`, `duration`, `provider`, `published`, `statistics`, `uploader`

### 快速參考

| 方法 | 使用時機 | 關鍵欄位 |
|--------|----------|------------|
| `text()` | 一般研究、公司資訊 | title, href, body |
| `news()` | 時事、更新 | date, title, source, body, url |
| `images()` | 視覺、圖表 | title, image, thumbnail, url |
| `videos()` | 教學、演示 | title, content, duration, provider |

## 工作流：搜尋後擷取

DuckDuckGo 會回傳標題、URL 和片段 (Snippets) — 而非完整的頁面內容。要獲取完整的頁面內容，請先搜尋，然後使用 `web_extract`、瀏覽器工具或 curl 擷取最相關的 URL。

CLI 範例：

```bash
ddgs text -k "fastapi deployment guide" -m 3 -o json
```

Python 範例（僅在驗證 `ddgs` 已安裝於該環境後）：

```python
from ddgs import DDGS

with DDGS() as ddgs:
    results = list(ddgs.text("fastapi deployment guide", max_results=3))
    for r in results:
        print(r["title"], "->", r["href"])
```

然後使用 `web_extract` 或其他內容檢索工具擷取最佳 URL。

## 限制

- **速率限制 (Rate limiting)**：DuckDuckGo 可能在大量快速請求後進行節流。如有需要，請在搜尋之間加入短暫延遲。
- **無內容擷取**：`ddgs` 回傳的是片段，而非完整頁面內容。請使用 `web_extract`、瀏覽器工具或 curl 獲取完整文章/頁面。
- **結果品質**：通常不錯，但可配置性不如 Firecrawl 搜尋。
- **可用性**：DuckDuckGo 可能會封鎖來自某些雲端 IP 的請求。如果搜尋回傳空結果，請嘗試不同的關鍵字或等待幾秒鐘。
- **欄位變動性**：回傳欄位可能會因結果或 `ddgs` 版本而異。請對選用欄位使用 `.get()` 以避免 `KeyError`。
- **執行環境分離**：在 Terminal 中安裝 `ddgs` 成功，並不自動代表 `execute_code` 可以匯入它。

## 故障排除

| 問題 | 可能原因 | 處理方法 |
|---------|--------------|------------|
| `ddgs: command not found` | CLI 未在 Shell 環境中安裝 | 安裝 `ddgs`，或改用內建的 web/browser 工具 |
| `ModuleNotFoundError: No module named 'ddgs'` | Python 執行環境未安裝該套件 | 在準備好該環境前，不要在該處使用 Python DDGS |
| 搜尋未回傳任何結果 | 暫時性速率限制或查詢詞不佳 | 等待幾秒後重試，或調整查詢詞 |
| CLI 可用但 `execute_code` 匯入失敗 | Terminal 和 `execute_code` 是不同的執行環境 | 繼續使用 CLI，或單獨準備 Python 執行環境 |

## 注意事項

- **`max_results` 僅限關鍵字引數**：`ddgs.text("query", 5)` 會拋出錯誤。請使用 `ddgs.text("query", max_results=5)`。
- **不要假設 CLI 存在**：使用前請先檢查 `command -v ddgs`。
- **不要假設 `execute_code` 可以匯入 `ddgs`**：除非單獨準備過該環境，否則 `from ddgs import DDGS` 可能會因 `ModuleNotFoundError` 而失敗。
- **套件名稱**：套件名稱為 `ddgs`（先前為 `duckduckgo-search`）。請透過 `pip install ddgs` 安裝。
- **不要混淆 `-k` 和 `-m`** (CLI)：`-k` 用於關鍵字，`-m` 用於最大結果數。
- **空結果**：如果 `ddgs` 未回傳任何結果，可能是受到速率限制。請等待幾秒後重試。

## 已驗證版本

已根據 `ddgs==9.11.2` 語義驗證範例。技能指南現在將 CLI 可用性和 Python 匯入可用性視為獨立事項，以便記錄的工作流符合實際執行行為。
