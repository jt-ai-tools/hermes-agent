---
name: docker-management
description: 管理 Docker 容器、映像檔、磁碟卷、網路以及 Compose 堆疊 — 包含生命週期操作、除錯、清理和 Dockerfile 最佳化。
version: 1.0.0
author: sprmn24
license: MIT
metadata:
  hermes:
    tags: [docker, 容器, devops, 基礎設施, compose, 映像檔, 磁碟卷, 網路, 除錯]
    category: devops
    requires_toolsets: [terminal]
---

# Docker 管理

使用標準的 Docker CLI 命令管理 Docker 容器、映像檔、磁碟卷、網路和 Compose 堆疊。除了 Docker 本身之外，不需要額外的依賴項。

## 何時使用

- 執行、停止、重啟、移除或檢查容器
- 建置、拉取、推送、標記或清理 Docker 映像檔
- 使用 Docker Compose (多服務堆疊)
- 管理磁碟卷 (volumes) 或網路 (networks)
- 為崩潰的容器除錯或分析日誌
- 檢查 Docker 磁碟使用量或釋放空間
- 審查或最佳化 Dockerfile

## 先決條件

- 已安裝並執行 Docker Engine
- 使用者已加入 `docker` 群組 (或使用 `sudo`)
- Docker Compose v2 (現代 Docker 安裝中已包含)

快速檢查：

```bash
docker --version && docker compose version
```

## 快速參考

| 任務 | 命令 |
|------|---------|
| 執行容器 (背景) | `docker run -d --name 名稱 映像檔` |
| 停止 + 移除 | `docker stop 名稱 && docker rm 名稱` |
| 查看日誌 (追蹤) | `docker logs --tail 50 -f 名稱` |
| 進入容器 Shell | `docker exec -it 名稱 /bin/sh` |
| 列出所有容器 | `docker ps -a` |
| 建置映像檔 | `docker build -t 標籤 .` |
| Compose 啟動 | `docker compose up -d` |
| Compose 停止 | `docker compose down` |
| 磁碟使用量 | `docker system df` |
| 清理懸空資源 | `docker image prune && docker container prune` |

## 程序

### 1. 識別領域

確定該請求屬於哪個領域：

- **容器生命週期** → run, stop, start, restart, rm, pause/unpause
- **容器互動** → exec, cp, logs, inspect, stats
- **映像檔管理** → build, pull, push, tag, rmi, save/load
- **Docker Compose** → up, down, ps, logs, exec, build, config
- **磁碟卷與網路** → create, inspect, rm, prune, connect
- **疑難排解** → 日誌分析、結束代碼、資源問題

### 2. 容器操作

**執行新容器：**

```bash
# 具有連接埠映射的後台服務
docker run -d --name web -p 8080:80 nginx

# 帶有環境變數
docker run -d -e POSTGRES_PASSWORD=secret -e POSTGRES_DB=mydb --name db postgres:16

# 具有持久性資料 (具名磁碟卷)
docker run -d -v pgdata:/var/lib/postgresql/data --name db postgres:16

# 用於開發 (掛載原始碼)
docker run -d -v $(pwd)/src:/app/src -p 3000:3000 --name dev my-app

# 互動式除錯 (結束後自動移除)
docker run -it --rm ubuntu:22.04 /bin/bash

# 具有資源限制和重啟政策
docker run -d --memory=512m --cpus=1.5 --restart=unless-stopped --name app my-app
```

關鍵旗標：`-d` 後台執行, `-it` 互動+tty, `--rm` 自動移除, `-p` 連接埠 (主機:容器), `-e` 環境變數, `-v` 磁碟卷, `--name` 名稱, `--restart` 重啟政策。

**管理執行中的容器：**

```bash
docker ps                        # 執行中的容器
docker ps -a                     # 所有容器 (包含已停止的)
docker stop 名稱                 # 優雅停止
docker start 名稱                # 啟動已停止的容器
docker restart 名稱              # 停止 + 啟動
docker rm 名稱                   # 移除已停止的容器
docker rm -f 名稱                # 強制移除執行中的容器
docker container prune           # 移除所有已停止的容器
```

**與容器互動：**

```bash
docker exec -it 名稱 /bin/sh          # Shell 存取 (如果可用，請使用 /bin/bash)
docker exec 名稱 env                   # 查看環境變數
docker exec -u root 名稱 apt update    # 以特定使用者身分執行
docker logs --tail 100 -f 名稱         # 追蹤最後 100 行
docker logs --since 2h 名稱            # 最後 2 小時的日誌
docker cp 名稱:/path/file ./local      # 從容器複製檔案
docker cp ./file 名稱:/path/           # 複製檔案到容器
docker inspect 名稱                    # 完整的容器細節 (JSON)
docker stats --no-stream               # 資源使用快照
docker top 名稱                        # 執行中的程序
```

### 3. 映像檔管理

```bash
# 建置
docker build -t my-app:latest .
docker build -t my-app:prod -f Dockerfile.prod .
docker build --no-cache -t my-app .              # 全新重建
DOCKER_BUILDKIT=1 docker build -t my-app .       # 使用 BuildKit 加速

# 拉取與推送
docker pull node:20-alpine
docker login ghcr.io
docker tag my-app:latest registry/my-app:v1.0
docker push registry/my-app:v1.0

# 檢查
docker images                          # 列出本地映像檔
docker history 映像檔                   # 查看層級 (layers)
docker inspect 映像檔                   # 完整細節

# 清理
docker image prune                     # 移除懸空 (未標記) 的映像檔
docker image prune -a                  # 移除所有未使用的映像檔 (請小心！)
docker image prune -a --filter "until=168h"   # 7 天前未使用的映像檔
```

### 4. Docker Compose

```bash
# 啟動/停止
docker compose up -d                   # 後台啟動所有服務
docker compose up -d --build           # 啟動前重新建置映像檔
docker compose down                    # 停止並移除容器
docker compose down -v                 # 同時移除磁碟卷 (會銷毀資料)

# 監控
docker compose ps                      # 列出服務
docker compose logs -f api             # 追蹤特定服務的日誌
docker compose logs --tail 50          # 所有服務的最後 50 行

# 互動
docker compose exec api /bin/sh        # 進入執行中服務的 Shell
docker compose run --rm api npm test   # 執行一次性命令 (新容器)
docker compose restart api             # 重啟特定服務

# 驗證
docker compose config                  # 驗證並查看解析後的設定
```

**最簡 compose.yml 範例：**

```yaml
services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/mydb
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: mydb
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  pgdata:
```

### 5. 磁碟卷與網路

```bash
# 磁碟卷
docker volume ls                       # 列出磁碟卷
docker volume create mydata            # 建立具名磁碟卷
docker volume inspect mydata           # 細節 (掛載點等)
docker volume rm mydata                # 移除 (使用中會失敗)
docker volume prune                    # 移除未使用的磁碟卷

# 網路
docker network ls                      # 列出網路
docker network create mynet            # 建立橋接網路
docker network inspect mynet           # 細節 (連接的容器)
docker network connect mynet 名稱      # 將容器連接到網路
docker network disconnect mynet 名稱   # 將容器從網路斷開
docker network rm mynet                # 移除網路
docker network prune                   # 移除未使用的網路
```

### 6. 磁碟使用量與清理

清理前請務必先進行診斷：

```bash
# 檢查空間使用情況
docker system df                       # 摘要
docker system df -v                    # 詳細分析

# 有針對性的清理 (安全)
docker container prune                 # 已停止的容器
docker image prune                     # 懸空的映像檔
docker volume prune                    # 未使用的磁碟卷
docker network prune                   # 未使用的網路

# 激進的清理 (請先與使用者確認！)
docker system prune                    # 容器 + 映像檔 + 網路
docker system prune -a                 # 同時包含未使用的映像檔
docker system prune -a --volumes       # 所有內容 — 包含具名磁碟卷
```

**警告：** 切勿在未與使用者確認的情況下執行 `docker system prune -a --volumes`。這會移除包含潛在重要資料的具名磁碟卷。

## 注意事項 (Pitfalls)

| 問題 | 原因 | 修正方法 |
|---------|-------|-----|
| 容器立即結束 | 主程序已完成或崩潰 | 檢查 `docker logs 名稱`，嘗試 `docker run -it --entrypoint /bin/sh 映像檔` |
| "port is already allocated" | 其他程序正在使用該連接埠 | `docker ps` 或 `lsof -i :連接埠` 來找出它 |
| "no space left on device" | Docker 磁碟已滿 | `docker system df` 後進行有針對性的清理 |
| 無法連接到容器 | 應用程式在容器內綁定到 127.0.0.1 | 應用程式必須綁定到 `0.0.0.0`，檢查 `-p` 映射 |
| 磁碟卷權限被拒絕 | 主機與容器的 UID/GID 不匹配 | 使用 `--user $(id -u):$(id -g)` 或修正權限 |
| Compose 服務無法互相訪問 | 網路或服務名稱錯誤 | 服務使用服務名稱作為主機名稱，檢查 `docker compose config` |
| 建置快取失效 | Dockerfile 層級順序錯誤 | 將很少變動的層級放在前面 (依賴項放在原始碼之前) |
| 映像檔太大 | 未使用多階段建置，沒有 .dockerignore | 使用多階段建置 (multi-stage builds)，加入 `.dockerignore` |

## 驗證

在任何 Docker 操作之後，驗證結果：

- **容器是否啟動？** → `docker ps` (檢查狀態是否為 "Up")
- **日誌是否正常？** → `docker logs --tail 20 名稱` (無錯誤)
- **連接埠是否可存取？** → `curl -s http://localhost:PORT` 或 `docker port 名稱`
- **映像檔是否已建置？** → `docker images | grep 標籤`
- **Compose 堆疊是否健康？** → `docker compose ps` (所有服務為 "running" 或 "healthy")
- **空間是否已釋放？** → `docker system df` (比較前後差異)

## Dockerfile 最佳化技巧

在審查或建立 Dockerfile 時，請建議以下改進：

1. **多階段建置 (Multi-stage builds)** — 分離建置環境與執行環境以縮小最終映像檔體積。
2. **層級順序 (Layer ordering)** — 將依賴項放在原始碼之前，使程式碼變更不會導致快取層級失效。
3. **合併 RUN 命令** — 減少層級數量，縮小映像檔體積。
4. **使用 .dockerignore** — 排除 `node_modules`, `.git`, `__pycache__` 等。
5. **指定基礎映像檔版本** — 使用 `node:20-alpine` 而非 `node:latest`。
6. **以非 root 身分執行** — 基於安全考慮，加入 `USER` 指令。
7. **使用 slim/alpine 基礎映像檔** — 使用 `python:3.12-slim` 而非 `python:3.12`。
