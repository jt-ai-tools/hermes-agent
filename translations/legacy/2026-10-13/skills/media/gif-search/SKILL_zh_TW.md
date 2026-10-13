---
name: gif-search
description: 使用 curl 從 Tenor 搜尋並下載 GIF。除了 curl 和 jq 之外沒有其他依賴。可用於尋找反應 GIF、建立視覺內容以及在聊天中發送 GIF。
version: 1.1.0
author: Hermes Agent
license: MIT
prerequisites:
  env_vars: [TENOR_API_KEY]
  commands: [curl, jq]
metadata:
  hermes:
    tags: [GIF, Media, Search, Tenor, API]
---

# GIF 搜尋 (Tenor API)

直接透過 Tenor API 使用 curl 搜尋並下載 GIF。無需額外工具。

## 設定

在您的環境中設定 Tenor API 金鑰（新增至 `~/.hermes/.env`）：

```bash
TENOR_API_KEY=your_key_here
```

在 https://developers.google.com/tenor/guides/quickstart 獲取免費的 API 金鑰 — Google Cloud Console Tenor API 金鑰是免費的，且具有慷慨的頻率限制。

## 前置作業

- `curl` 和 `jq`（在 macOS/Linux 上均為標準配備）
- `TENOR_API_KEY` 環境變數

## 搜尋 GIF

```bash
# 搜尋並取得 GIF URL
curl -s "https://tenor.googleapis.com/v2/search?q=thumbs+up&limit=5&key=${TENOR_API_KEY}" | jq -r '.results[].media_formats.gif.url'

# 取得較小/預覽版本
curl -s "https://tenor.googleapis.com/v2/search?q=nice+work&limit=3&key=${TENOR_API_KEY}" | jq -r '.results[].media_formats.tinygif.url'
```

## 下載 GIF

```bash
# 搜尋並下載第一個結果
URL=$(curl -s "https://tenor.googleapis.com/v2/search?q=celebration&limit=1&key=${TENOR_API_KEY}" | jq -r '.results[0].media_formats.gif.url')
curl -sL "$URL" -o celebration.gif
```

## 取得完整中繼資料

```bash
curl -s "https://tenor.googleapis.com/v2/search?q=cat&limit=3&key=${TENOR_API_KEY}" | jq '.results[] | {title: .title, url: .media_formats.gif.url, preview: .media_formats.tinygif.url, dimensions: .media_formats.gif.dims}'
```

## API 參數

| 參數 | 說明 |
|-----------|-------------|
| `q` | 搜尋查詢（空格請使用 `+` 進行 URL 編碼） |
| `limit` | 最大結果數（1-50，預設為 20） |
| `key` | API 金鑰（來自 `$TENOR_API_KEY` 環境變數） |
| `media_filter` | 篩選格式：`gif`、`tinygif`、`mp4`、`tinymp4`、`webm` |
| `contentfilter` | 安全篩選：`off`、`low`、`medium`、`high` |
| `locale` | 語言：`en_US`、`es`、`fr` 等 |

## 可用媒體格式

每個結果在 `.media_formats` 下有多種格式：

| 格式 | 使用情境 |
|--------|----------|
| `gif` | 高畫質 GIF |
| `tinygif` | 小尺寸預覽 GIF |
| `mp4` | 影片版本（檔案較小） |
| `tinymp4` | 小尺寸預覽影片 |
| `webm` | WebM 影片 |
| `nanogif` | 極小縮圖 |

## 備註

- 對查詢進行 URL 編碼：空格為 `+`，特殊字元為 `%XX`
- 若要在聊天中發送，`tinygif` URL 的負擔較輕
- GIF URL 可以直接在 markdown 中使用：`![alt](url)`
