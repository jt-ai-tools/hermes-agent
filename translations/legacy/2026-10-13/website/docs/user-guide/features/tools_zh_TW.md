---
sidebar_position: 1
title: "工具與工具集 (Tools & Toolsets)"
description: "Hermes Agent 工具概覽 — 可用工具、工具集運作方式以及終端後端"
---

# 工具與工具集 (Tools & Toolsets)

工具 (Tools) 是擴展代理程式功能的函式。它們被組織成邏輯上的**工具集 (toolsets)**，可以根據不同的平台啟用或停用。

## 可用工具

Hermes 隨附了一個廣泛的內建工具註冊表，涵蓋網頁搜尋、瀏覽器自動化、終端執行、檔案編輯、記憶體、委託、強化學習 (RL) 訓練、訊息傳遞、Home Assistant 等。

:::note
**Honcho 跨會話記憶** 是以記憶體提供者外掛程式的形式提供 (`plugins/memory/honcho/`)，而非內建工具集。請參閱 [外掛程式](./plugins.md) 以瞭解安裝方式。
:::

高階分類：

| 分類 | 範例 | 描述 |
|----------|----------|-------------|
| **網頁 (Web)** | `web_search`, `web_extract` | 搜尋網頁並擷取頁面內容。 |
| **終端與檔案 (Terminal & Files)** | `terminal`, `process`, `read_file`, `patch` | 執行指令並操作檔案。 |
| **瀏覽器 (Browser)** | `browser_navigate`, `browser_snapshot`, `browser_vision` | 具備文本與視覺支援的互動式瀏覽器自動化。 |
| **媒體 (Media)** | `vision_analyze`, `image_generate`, `text_to_speech` | 多模態分析與生成。 |
| **代理程式協調** | `todo`, `clarify`, `execute_code`, `delegate_task` | 計劃、釐清、程式碼執行以及子代理程式委託。 |
| **記憶與回想** | `memory`, `session_search` | 持久化記憶與會話搜尋。 |
| **自動化與傳遞** | `cronjob`, `send_message` | 具備建立/列出/更新/暫停/恢復/執行/移除等動作的排程任務，以及外傳訊息傳遞。 |
| **整合 (Integrations)** | `ha_*`, MCP 伺服器工具, `rl_*` | Home Assistant、MCP、RL 訓練及其他整合功能。 |

關於由程式碼生成的權威註冊表，請參閱 [內建工具參考](/docs/reference/tools-reference) 和 [工具集參考](/docs/reference/toolsets-reference)。

## 使用工具集

```bash
# 使用特定的工具集
hermes chat --toolsets "web,terminal"

# 查看所有可用工具
hermes tools

# 為特定平台設定工具（互動式）
hermes tools
```

常見的工具集包括 `web`、`terminal`、`file`、`browser`、`vision`、`image_gen`、`moa`、`skills`、`tts`、`todo`、`memory`、`session_search`、`cronjob`、`code_execution`、`delegation`、`clarify`、`homeassistant` 和 `rl`。

請參閱 [工具集參考](/docs/reference/toolsets-reference) 以獲取完整清單，包括 `hermes-cli`、`hermes-telegram` 等平台預設集，以及如 `mcp-<server>` 的動態 MCP 工具集。

## 終端後端 (Terminal Backends)

終端工具可以在不同的環境中執行指令：

| 後端 | 描述 | 使用場景 |
|---------|-------------|----------|
| `local` | 在您的機器上執行（預設） | 開發、受信任的任務 |
| `docker` | 隔離的容器 | 安全性、可重現性 |
| `ssh` | 遠端伺服器 | 沙盒化，讓代理程式遠離其自身程式碼 |
| `singularity` | HPC 容器 | 叢集運算、無 root 權限 |
| `modal` | 雲端執行 | 無伺服器 (Serverless)、橫向擴充 |
| `daytona` | 雲端沙盒工作空間 | 持久化的遠端開發環境 |

### 設定

```yaml
# 在 ~/.hermes/config.yaml 中
terminal:
  backend: local    # 或：docker, ssh, singularity, modal, daytona
  cwd: "."          # 工作目錄
  timeout: 180      # 指令逾時時間（秒）
```

### Docker 後端

```yaml
terminal:
  backend: docker
  docker_image: python:3.11-slim
```

### SSH 後端

為了安全性而推薦 — 代理程式無法修改其自身的程式碼：

```yaml
terminal:
  backend: ssh
```
```bash
# 在 ~/.hermes/.env 中設定憑證
TERMINAL_SSH_HOST=my-server.example.com
TERMINAL_SSH_USER=myuser
TERMINAL_SSH_KEY=~/.ssh/id_rsa
```

### Singularity/Apptainer

```bash
# 為平行工作者預先建構 SIF
apptainer build ~/python.sif docker://python:3.11-slim

# 設定
hermes config set terminal.backend singularity
hermes config set terminal.singularity_image ~/python.sif
```

### Modal (無伺服器雲端)

```bash
uv pip install modal
modal setup
hermes config set terminal.backend modal
```

### 容器資源

為所有容器後端設定 CPU、記憶體、磁碟和持久化：

```yaml
terminal:
  backend: docker  # 或 singularity, modal, daytona
  container_cpu: 1              # CPU 核心數（預設：1）
  container_memory: 5120        # 記憶體大小 MB（預設：5GB）
  container_disk: 51200         # 磁碟大小 MB（預設：50GB）
  container_persistent: true    # 跨會話持久化檔案系統（預設：true）
```

當 `container_persistent: true` 時，安裝的套件、檔案和設定將在不同會話之間保留。

### 容器安全性

所有容器後端都具備安全性強化：

- 唯讀根檔案系統 (Docker)
- 捨棄所有 Linux Capabilities
- 禁止權限提升
- PID 限制 (256 個程序)
- 完整的命名空間 (namespace) 隔離
- 透過磁碟卷 (volumes) 實現持久化工作空間，而非可寫入的根層

Docker 可以選擇透過 `terminal.docker_forward_env` 接收明確的環境變數白名單，但轉發的變數對容器內的指令是可見的，應視為在該會話中已公開。

## 背景程序管理 (Background Process Management)

啟動並管理背景程序：

```python
terminal(command="pytest -v tests/", background=true)
# 回傳：{"session_id": "proc_abc123", "pid": 12345}

# 接著使用處理程序工具進行管理：
process(action="list")       # 顯示所有正在運行的程序
process(action="poll", session_id="proc_abc123")   # 檢查狀態
process(action="wait", session_id="proc_abc123")   # 阻塞直到完成
process(action="log", session_id="proc_abc123")    # 完整輸出
process(action="kill", session_id="proc_abc123")   # 終止
process(action="write", session_id="proc_abc123", data="y")  # 傳送輸入
```

PTY 模式 (`pty=true`) 可啟用互動式 CLI 工具，如 Codex 和 Claude Code。

## Sudo 支援

如果指令需要 sudo，系統會提示您輸入密碼（會為該會話快取）。或者在 `~/.hermes/.env` 中設定 `SUDO_PASSWORD`。

:::warning
在通訊平台上，如果 sudo 失敗，輸出將包含一項提示，建議將 `SUDO_PASSWORD` 新增至 `~/.hermes/.env` 中。
:::
