---
sidebar_position: 7
title: "Docker"
description: "在 Docker 中執行 Hermes Agent，以及將 Docker 作為終端機後端"
---

# Hermes Agent — Docker

Docker 與 Hermes Agent 的交集主要有兩種截然不同的方式：

1. **在 Docker 中執行 Hermes** — Agent 本身在容器內執行 (本頁面的主要重點)
2. **將 Docker 作為終端機後端** — Agent 在您的主機上執行，但在 Docker 沙盒內執行指令 (請參閱 [配置 → terminal.backend](./configuration.md))

本頁面涵蓋選項 1。容器將所有使用者資料 (配置、API 金鑰、會話、技能、記憶) 儲存在從主機掛載至 `/opt/data` 的單一目錄中。映像檔 (Image) 本身是無狀態的，可以透過拉取新版本來升級，而不會遺失任何配置。

## 快速入門

如果您是第一次執行 Hermes Agent，請在主機上建立資料目錄並以互動方式啟動容器，以執行設定精靈：

```sh
mkdir -p ~/.hermes
docker run -it --rm \
  -v ~/.hermes:/opt/data \
  nousresearch/hermes-agent setup
```

這會帶您進入設定精靈，引導您輸入 API 金鑰並將其寫入 `~/.hermes/.env`。您只需要做這一次。強烈建議在此時為閘道 (Gateway) 設定一個可配合使用的聊天系統。

## 以閘道模式執行

配置完成後，即可將容器作為持久的閘道 (Telegram, Discord, Slack, WhatsApp 等) 在背景執行：

```sh
docker run -d \
  --name hermes \
  --restart unless-stopped \
  -v ~/.hermes:/opt/data \
  -p 8642:8642 \
  nousresearch/hermes-agent gateway run
```

連接埠 8642 會暴露閘道的 [OpenAI 相容 API 伺服器](./api-server.md) 與健康檢查端點。如果您僅使用聊天平台 (Telegram, Discord 等)，此項為選填；但如果您想要儀表板 (Dashboard) 或外部工具能連線至閘道，則此項為必填。

在面向網際網路的機器上開啟任何連接埠都存在安全性風險。除非您了解相關風險，否則不應執行此操作。

## 執行儀表板 (Dashboard)

內建的網頁儀表板可以作為獨立容器與閘道併行執行。

若要將儀表板作為獨立容器執行，請將其指向閘道的健康檢查端點，以便它能跨容器偵測閘道狀態：

```sh
docker run -d \
  --name hermes-dashboard \
  --restart unless-stopped \
  -v ~/.hermes:/opt/data \
  -p 9119:9119 \
  -e GATEWAY_HEALTH_URL=http://$HOST_IP:8642 \
  nousresearch/hermes-agent dashboard
```

請將 `$HOST_IP` 替換為執行閘道容器的機器 IP 位址 (例如 `192.168.1.100`)，或者如果兩個容器共用同一個網路，則使用 Docker 網路主機名稱 (請參閱下方的 [Compose 範例](#docker-compose-範例))。

| 環境變數 | 描述 | 預設值 |
|---------------------|-------------|---------|
| `GATEWAY_HEALTH_URL` | 閘道 API 伺服器的基礎 URL，例如 `http://gateway:8642` | *(未設定 — 僅限本地 PID 檢查)* |
| `GATEWAY_HEALTH_TIMEOUT` | 健康檢查探測逾時秒數 | `3` |

若未設定 `GATEWAY_HEALTH_URL`，儀表板會回退至本地程序偵測 — 僅當閘道在同一個容器或同一個主機上執行時才有效。

## 以互動方式執行 (CLI 聊天)

若要針對現有的資料目錄開啟互動式聊天會話：

```sh
docker run -it --rm \
  -v ~/.hermes:/opt/data \
  nousresearch/hermes-agent
```

## 持久性磁碟區 (Persistent Volumes)

`/opt/data` 磁碟區是所有 Hermes 狀態的唯一真實來源。它映射到您主機的 `~/.hermes/` 目錄，並包含：

| 路徑 | 內容 |
|------|----------|
| `.env` | API 金鑰與祕密 |
| `config.yaml` | 所有 Hermes 配置 |
| `SOUL.md` | Agent 個性/身分 |
| `sessions/` | 對話歷史記錄 |
| `memories/` | 持久記憶儲存庫 |
| `skills/` | 已安裝技能 |
| `cron/` | 排程工作定義 |
| `hooks/` | 事件掛鉤 (Hooks) |
| `logs/` | 執行期日誌 |
| `skins/` | 自訂 CLI 外觀 (Skins) |

:::warning
絕不要針對同一個資料目錄同時執行兩個 Hermes **閘道**容器 — 會話檔案與記憶儲存庫並非設計用於同時寫入存取。在閘道旁執行儀表板容器是安全的，因為儀表板僅讀取資料。
:::

## 環境變數轉發

API 金鑰會從容器內的 `/opt/data/.env` 讀取。您也可以直接傳遞環境變數：

```sh
docker run -it --rm \
  -v ~/.hermes:/opt/data \
  -e ANTHROPIC_API_KEY="sk-ant-..." \
  -e OPENAI_API_KEY="sk-..." \
  nousresearch/hermes-agent
```

直接使用 `-e` 標記會覆寫 `.env` 中的值。這對於 CI/CD 或您不想將金鑰存在磁碟上的祕密管理器 (Secrets-manager) 整合非常有用。

## Docker Compose 範例

對於同時部署閘道與儀表板的持久性部署，使用 `docker-compose.yaml` 會很方便：

```yaml
services:
  hermes:
    image: nousresearch/hermes-agent:latest
    container_name: hermes
    restart: unless-stopped
    command: gateway run
    ports:
      - "8642:8642"
    volumes:
      - ~/.hermes:/opt/data
    networks:
      - hermes-net
    # 取消註釋以轉發特定環境變數，而非使用 .env 檔案：
    # environment:
    #   - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
    #   - OPENAI_API_KEY=${OPENAI_API_KEY}
    #   - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: "2.0"

  dashboard:
    image: nousresearch/hermes-agent:latest
    container_name: hermes-dashboard
    restart: unless-stopped
    command: dashboard --host 0.0.0.0
    ports:
      - "9119:9119"
    volumes:
      - ~/.hermes:/opt/data
    environment:
      - GATEWAY_HEALTH_URL=http://hermes:8642
    networks:
      - hermes-net
    depends_on:
      - hermes
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: "0.5"

networks:
  hermes-net:
    driver: bridge
```

使用 `docker compose up -d` 啟動，並使用 `docker compose logs -f` 查看日誌。

## 資源限制

Hermes 容器需要適度的資源。建議的最小值如下：

| 資源 | 最小值 | 建議值 |
|----------|---------|-------------|
| 記憶體 | 1 GB | 2–4 GB |
| CPU | 1 核心 | 2 核心 |
| 磁碟 (資料磁碟區) | 500 MB | 2+ GB (隨會話/技能增加而成長) |

瀏覽器自動化 (Playwright/Chromium) 是最消耗記憶體的功能。如果您不需要瀏覽器工具，1 GB 就足夠了。若要使用瀏覽器工具，請至少分配 2 GB。

在 Docker 中設定限制：

```sh
docker run -d \
  --name hermes \
  --restart unless-stopped \
  --memory=4g --cpus=2 \
  -v ~/.hermes:/opt/data \
  nousresearch/hermes-agent gateway run
```

## Dockerfile 的作用

官方映像檔基於 `debian:13.4`，並包含：

- Python 3 以及所有 Hermes 依賴項 (`pip install -e ".[all]"`)
- Node.js + npm (用於瀏覽器自動化與 WhatsApp 橋接)
- 帶有 Chromium 的 Playwright (`npx playwright install --with-deps chromium`)
- 作為系統公用程式的 ripgrep 與 ffmpeg
- WhatsApp 橋接器 (`scripts/whatsapp-bridge/`)

進入點指令碼 (`docker/entrypoint.sh`) 在第一次執行時會引導資料磁碟區：
- 建立目錄結構 (`sessions/`, `memories/`, `skills/` 等)
- 如果不存在 `.env`，則複製 `.env.example` → `.env`
- 如果遺漏預設的 `config.yaml`，則進行複製
- 如果遺漏預設的 `SOUL.md`，則進行複製
- 使用基於資訊清單 (Manifest) 的方法同步隨附技能 (保留使用者編輯內容)
- 接著以您傳遞的任何引數執行 `hermes`

## 升級

拉取最新映像檔並重新建立容器。您的資料目錄將不受影響。

```sh
docker pull nousresearch/hermes-agent:latest
docker rm -f hermes
docker run -d \
  --name hermes \
  --restart unless-stopped \
  -v ~/.hermes:/opt/data \
  nousresearch/hermes-agent gateway run
```

或者使用 Docker Compose：

```sh
docker compose pull
docker compose up -d
```

## 技能與憑證檔案

將 Docker 作為執行環境時 (非上述方法，而是當 Agent 在 Docker 沙盒內執行指令時)，Hermes 會自動將技能目錄 (`~/.hermes/skills/`) 以及技能宣告的任何憑證檔案以唯讀磁碟區的形式繫結掛載到容器中。這意味著技能指令碼、範本與參考資料在沙盒內皆可使用，無需手動配置。

SSH 與 Modal 後端也會進行相同的同步 — 在每個指令執行前，透過 rsync 或 Modal 掛載 API 上傳技能與憑證檔案。

## 疑難排解

### 容器立即退出

檢查日誌：`docker logs hermes`。常見原因：
- 遺漏或無效的 `.env` 檔案 — 請先以互動方式執行以完成設定
- 如果執行時暴露了連接埠，可能是連接埠衝突

### 「權限被拒絕 (Permission denied)」錯誤

容器預設以 root 使用者執行。如果您主機上的 `~/.hermes/` 是由非 root 使用者建立的，權限應該可以運作。如果您遇到錯誤，請確保資料目錄是可寫入的：

```sh
chmod -R 755 ~/.hermes
```

### 瀏覽器工具無法運作

Playwright 需要共享記憶體。請在 Docker 執行指令中加入 `--shm-size=1g`：

```sh
docker run -d \
  --name hermes \
  --shm-size=1g \
  -v ~/.hermes:/opt/data \
  nousresearch/hermes-agent gateway run
```

### 網路問題後閘道未重新連線

`--restart unless-stopped` 標記可處理大多數暫時性失敗。如果閘道卡住，請重啟容器：

```sh
docker restart hermes
```

### 檢查容器狀態

```sh
docker logs --tail 50 hermes          # 最近的日誌
docker run -it --rm nousresearch/hermes-agent:latest version     # 驗證版本
docker stats hermes                    # 資源使用情況
```
