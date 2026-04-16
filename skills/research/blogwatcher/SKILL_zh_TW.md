---
name: blogwatcher
description: 使用 blogwatcher-cli 工具監測部落格和 RSS/Atom feed 的更新。添加部落格、掃描新文章、追蹤閱讀狀態並按類別過濾。
version: 2.0.0
author: JulienTant (fork of Hyaxia/blogwatcher)
license: MIT
metadata:
  hermes:
    tags: [RSS, 部落格, Feed-Reader, 監測]
    homepage: https://github.com/JulienTant/blogwatcher-cli
prerequisites:
  commands: [blogwatcher-cli]
---

# Blogwatcher

使用 `blogwatcher-cli` 工具追蹤部落格和 RSS/Atom feed 的更新。支持自動 feed 發現、HTML 抓取備案、OPML 匯入以及已讀/未讀文章管理。

## 安裝

請選擇以下其中一種方法：

- **Go:** `go install github.com/JulienTant/blogwatcher-cli/cmd/blogwatcher-cli@latest`
- **Docker:** `docker run --rm -v blogwatcher-cli:/data ghcr.io/julientant/blogwatcher-cli`
- **Binary (Linux amd64):** `curl -sL https://github.com/JulienTant/blogwatcher-cli/releases/latest/download/blogwatcher-cli_linux_amd64.tar.gz | tar xz -C /usr/local/bin blogwatcher-cli`
- **Binary (Linux arm64):** `curl -sL https://github.com/JulienTant/blogwatcher-cli/releases/latest/download/blogwatcher-cli_linux_arm64.tar.gz | tar xz -C /usr/local/bin blogwatcher-cli`
- **Binary (macOS Apple Silicon):** `curl -sL https://github.com/JulienTant/blogwatcher-cli/releases/latest/download/blogwatcher-cli_darwin_arm64.tar.gz | tar xz -C /usr/local/bin blogwatcher-cli`
- **Binary (macOS Intel):** `curl -sL https://github.com/JulienTant/blogwatcher-cli/releases/latest/download/blogwatcher-cli_darwin_amd64.tar.gz | tar xz -C /usr/local/bin blogwatcher-cli`

所有版本：https://github.com/JulienTant/blogwatcher-cli/releases

### 使用持久化存儲的 Docker

預設情況下，數據庫位於 `~/.blogwatcher-cli/blogwatcher-cli.db`。在 Docker 中，這會在容器重啟時丟失。請使用 `BLOGWATCHER_DB` 或掛載磁碟卷 (volume mount) 來持久化存儲：

```bash
# 具名磁碟卷 (最簡單的方法)
docker run --rm -v blogwatcher-cli:/data -e BLOGWATCHER_DB=/data/blogwatcher-cli.db ghcr.io/julientant/blogwatcher-cli scan

# 主機綁定掛載 (Host bind mount)
docker run --rm -v /path/on/host:/data -e BLOGWATCHER_DB=/data/blogwatcher-cli.db ghcr.io/julientant/blogwatcher-cli scan
```

### 從原始 blogwatcher 遷移

如果是從 `Hyaxia/blogwatcher` 升級，請移動您的數據庫：

```bash
mv ~/.blogwatcher/blogwatcher.db ~/.blogwatcher-cli/blogwatcher-cli.db
```

執行檔名稱已從 `blogwatcher` 更改為 `blogwatcher-cli`。

## 常用指令

### 管理部落格

- 添加部落格：`blogwatcher-cli add "My Blog" https://example.com`
- 使用明確的 feed 添加：`blogwatcher-cli add "My Blog" https://example.com --feed-url https://example.com/feed.xml`
- 使用 HTML 抓取添加：`blogwatcher-cli add "My Blog" https://example.com --scrape-selector "article h2 a"`
- 列出追蹤中的部落格：`blogwatcher-cli blogs`
- 移除部落格：`blogwatcher-cli remove "My Blog" --yes`
- 從 OPML 匯入：`blogwatcher-cli import subscriptions.opml`

### 掃描與閱讀

- 掃描所有部落格：`blogwatcher-cli scan`
- 掃描單一部落格：`blogwatcher-cli scan "My Blog"`
- 列出未讀文章：`blogwatcher-cli articles`
- 列出所有文章：`blogwatcher-cli articles --all`
- 按部落格過濾：`blogwatcher-cli articles --blog "My Blog"`
- 按類別過濾：`blogwatcher-cli articles --category "Engineering"`
- 將文章標記為已讀：`blogwatcher-cli read 1`
- 將文章標記為未讀：`blogwatcher-cli unread 1`
- 全部標記為已讀：`blogwatcher-cli read-all`
- 將特定部落格的所有文章標記為已讀：`blogwatcher-cli read-all --blog "My Blog" --yes`

## 環境變數

所有旗標 (flags) 都可以透過帶有 `BLOGWATCHER_` 前綴的環境變數進行設置：

| 變數 | 描述 |
|---|---|
| `BLOGWATCHER_DB` | SQLite 數據庫文件路徑 |
| `BLOGWATCHER_WORKERS` | 同步掃描工作線程數量 (預設：8) |
| `BLOGWATCHER_SILENT` | 掃描時僅輸出 "scan done" |
| `BLOGWATCHER_YES` | 跳過確認提示 |
| `BLOGWATCHER_CATEGORY` | 文章按類別過濾的預設值 |

## 輸出範例

```
$ blogwatcher-cli blogs
Tracked blogs (1):

  xkcd
    URL: https://xkcd.com
    Feed: https://xkcd.com/atom.xml
    Last scanned: 2026-04-03 10:30
```

```
$ blogwatcher-cli scan
Scanning 1 blog(s)...

  xkcd
    Source: RSS | Found: 4 | New: 4

Found 4 new article(s) total!
```

```
$ blogwatcher-cli articles
Unread articles (2):

  [1] [new] Barrel - Part 13
       Blog: xkcd
       URL: https://xkcd.com/3095/
       Published: 2026-04-02
       Categories: Comics, Science

  [2] [new] Volcano Fact
       Blog: xkcd
       URL: https://xkcd.com/3094/
       Published: 2026-04-01
       Categories: Comics
```

## 注意事項

- 當未提供 `--feed-url` 時，會從部落格首頁自動發現 RSS/Atom feed。
- 如果 RSS 失敗且配置了 `--scrape-selector`，則會退而使用 HTML 抓取。
- RSS/Atom feed 中的類別會被儲存，並可用於文章過濾。
- 可從 Feedly, Inoreader, NewsBlur 等匯出的 OPML 文件中批量匯入部落格。
- 數據庫預設儲存在 `~/.blogwatcher-cli/blogwatcher-cli.db` (可使用 `--db` 或 `BLOGWATCHER_DB` 覆蓋)。
- 使用 `blogwatcher-cli <command> --help` 查看所有旗標和選項。
