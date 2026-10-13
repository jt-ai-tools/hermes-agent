---
sidebar_position: 2
title: "配置"
description: "配置 Hermes Agent — config.yaml、提供商、模型、API 金鑰等"
---

# 配置

所有設定都儲存在 `~/.hermes/` 目錄中，方便存取。

## 目錄結構

```text
~/.hermes/
├── config.yaml     # 設定 (模型、終端機、TTS、壓縮等)
├── .env            # API 金鑰與祕密
├── auth.json       # OAuth 提供商憑證 (Nous Portal 等)
├── SOUL.md         # 主要 Agent 身分 (系統提示詞中的第 1 個插槽)
├── memories/       # 持久記憶 (MEMORY.md, USER.md)
├── skills/         # Agent 建立的技能 (透過 skill_manage 工具管理)
├── cron/           # 排程工作
├── sessions/       # 閘道會話 (Gateway sessions)
└── logs/           # 日誌 (errors.log, gateway.log — 祕密會自動遮蔽)
```

## 管理配置

```bash
hermes config              # 查看目前配置
hermes config edit         # 在編輯器中開啟 config.yaml
hermes config set KEY VAL  # 設定特定值
hermes config check        # 檢查是否有遺漏的選項 (更新後使用)
hermes config migrate      # 以互動方式增加遺漏的選項

# 範例：
hermes config set model anthropic/claude-opus-4
hermes config set terminal.backend docker
hermes config set OPENROUTER_API_KEY sk-or-...  # 儲存至 .env
```

:::tip
`hermes config set` 指令會自動將值引導至正確的檔案 — API 金鑰儲存至 `.env`，其他所有內容儲存至 `config.yaml`。
:::

## 配置優先順序

設定按以下順序解析 (優先順序最高者排在最前)：

1. **CLI 引數** — 例如 `hermes chat --model anthropic/claude-sonnet-4` (單次調用覆寫)
2. **`~/.hermes/config.yaml`** — 所有非祕密設定的主要配置檔案
3. **`~/.hermes/.env`** — 環境變數的回退；祕密 (API 金鑰、Token、密碼) **必填**
4. **內建預設值** — 未進行任何設定時使用的硬編碼安全預設值

:::info 經驗準則
祕密 (API 金鑰、機器人 Token、密碼) 請放在 `.env`。其他所有內容 (模型、終端機後端、壓縮設定、記憶限制、工具集) 請放在 `config.yaml`。當兩者皆有設定時，對於非祕密設定，以 `config.yaml` 為準。
:::

## 環境變數替換

您可以在 `config.yaml` 中使用 `${VAR_NAME}` 語法引用環境變數：

```yaml
auxiliary:
  vision:
    api_key: ${GOOGLE_API_KEY}
    base_url: ${CUSTOM_VISION_URL}

delegation:
  api_key: ${DELEGATION_KEY}
```

單一值中可包含多個引用：`url: "${HOST}:${PORT}"`。如果引用的變數未設定，預留位置將保持原樣 (`${UNDEFINED_VAR}` 保持不變)。僅支援 `${VAR}` 語法 — 不會展開單純的 `$VAR`。

有關 AI 提供商設定 (OpenRouter、Anthropic、Copilot、自訂端點、自我託管 LLM、回退模型等)，請參閱 [AI 提供商](/docs/integrations/providers)。

## 終端機後端配置

Hermes 支援六種終端機後端。每種後端決定 Agent 的 Shell 指令實際執行位置 — 您的本地機器、Docker 容器、透過 SSH 連接的遠端伺服器、Modal 雲端沙盒、Daytona 工作區或 Singularity/Apptainer 容器。

```yaml
terminal:
  backend: local    # local | docker | ssh | modal | daytona | singularity
  cwd: "."          # 工作目錄 ("." = 本地目前的目錄，容器則為 "/root")
  timeout: 180      # 每個指令的逾時時間 (秒)
  env_passthrough: []  # 要轉發至沙盒執行的環境變數名稱 (terminal + execute_code)
  singularity_image: "docker://nikolaik/python-nodejs:python3.11-nodejs20"  # Singularity 後端的容器映像檔
  modal_image: "nikolaik/python-nodejs:python3.11-nodejs20"                 # Modal 後端的容器映像檔
  daytona_image: "nikolaik/python-nodejs:python3.11-nodejs20"               # Daytona 後端的容器映像檔
```

對於 Modal 和 Daytona 等雲端沙盒，`container_persistent: true` 表示 Hermes 會嘗試在重建沙盒時保留檔案系統狀態。這並不保證相同的活動沙盒、PID 空間或背景程序稍後仍會執行。

### 後端概覽

| 後端 | 指令執行位置 | 隔離性 | 最佳用途 |
|---------|-------------------|-----------|----------|
| **local** | 直接在您的機器上 | 無 | 開發、個人使用 |
| **docker** | Docker 容器內 | 完全 (命名空間、能力刪減) | 安全沙盒、CI/CD |
| **ssh** | 透過 SSH 的遠端伺服器 | 網路邊界 | 遠端開發、強大硬體 |
| **modal** | Modal 雲端沙盒 | 完全 (雲端 VM) | 臨時雲端運算、評估 |
| **daytona** | Daytona 工作區 | 完全 (雲端容器) | 託管雲端開發環境 |
| **singularity** | Singularity/Apptainer 容器 | 命名空間 (--containall) | HPC 叢集、共享機器 |

### 本地 (Local) 後端

這是預設值。指令直接在您的機器上執行，無隔離。不需要特殊設定。

```yaml
terminal:
  backend: local
```

:::warning
Agent 擁有與您的使用者帳號相同的檔案系統存取權限。請使用 `hermes tools` 停用您不想要的工具，或切換到 Docker 進行沙盒隔離。
:::

### Docker 後端

在經過安全強化的 Docker 容器內執行指令 (刪除所有能力、禁止權限提升、PID 限制)。

```yaml
terminal:
  backend: docker
  docker_image: "nikolaik/python-nodejs:python3.11-nodejs20"
  docker_mount_cwd_to_workspace: false  # 將啟動目錄掛載至 /workspace
  docker_forward_env:              # 要轉發至容器內的環境變數
    - "GITHUB_TOKEN"
  docker_volumes:                  # 主機目錄掛載
    - "/home/user/projects:/workspace/projects"
    - "/home/user/data:/data:ro"   # :ro 表示唯讀

  # 資源限制
  container_cpu: 1                 # CPU 核心 (0 = 無限制)
  container_memory: 5120           # MB (0 = 無限制)
  container_disk: 51200            # MB (在 XFS+pquota 上需要 overlay2)
  container_persistent: true       # 跨會話保留 /workspace 與 /root
```

**需求：** 已安裝並執行 Docker Desktop 或 Docker Engine。Hermes 會探測 `$PATH` 以及常見的 macOS 安裝位置 (`/usr/local/bin/docker`, `/opt/homebrew/bin/docker`, Docker Desktop 應用程式套件)。

**容器生命週期：** 每個會話都會啟動一個長效型容器 (`docker run -d ... sleep 2h`)。指令透過帶有登入 Shell 的 `docker exec` 執行。清理時，容器會被停止並移除。

**安全強化：**
- `--cap-drop ALL`，僅加回 `DAC_OVERRIDE`、`CHOWN`、`FOWNER`
- `--security-opt no-new-privileges`
- `--pids-limit 256`
- 限制大小的 tmpfs 用於 `/tmp` (512MB)、`/var/tmp` (256MB)、`/run` (64MB)

**憑證轉發：** `docker_forward_env` 中列出的環境變數會先從您的 Shell 環境解析，接著從 `~/.hermes/.env` 解析。技能也可以宣告 `required_environment_variables`，這些變數會自動合併。

### SSH 後端

透過 SSH 在遠端伺服器上執行指令。使用 ControlMaster 進行連線複用 (5 分鐘閒置保持連線)。預設啟用持久型 Shell (Persistent shell) — 狀態 (目前目錄、環境變數) 可跨指令保留。

```yaml
terminal:
  backend: ssh
  persistent_shell: true           # 保持長效型 bash 會話 (預設：true)
```

**必要的環境變數：**

```bash
TERMINAL_SSH_HOST=my-server.example.com
TERMINAL_SSH_USER=ubuntu
```

**選填：**

| 變數 | 預設值 | 描述 |
|----------|---------|-------------|
| `TERMINAL_SSH_PORT` | `22` | SSH 埠號 |
| `TERMINAL_SSH_KEY` | (系統預設值) | SSH 私鑰路徑 |
| `TERMINAL_SSH_PERSISTENT` | `true` | 啟用持久型 Shell |

**運作方式：** 在初始化時以 `BatchMode=yes` 與 `StrictHostKeyChecking=accept-new` 進行連線。持久型 Shell 在遠端主機上保持單一 `bash -l` 程序運作，透過暫存檔進行通訊。需要 `stdin_data` 或 `sudo` 的指令會自動回退到單次 (one-shot) 模式。

### Modal 後端

在 [Modal](https://modal.com) 雲端沙盒中執行指令。每個任務都會獲得一個具有可配置 CPU、記憶體與磁碟的隔離 VM。檔案系統可跨會話快照/還原。

```yaml
terminal:
  backend: modal
  container_cpu: 1                 # CPU 核心
  container_memory: 5120           # MB (5GB)
  container_disk: 51200            # MB (50GB)
  container_persistent: true       # 快照/還原檔案系統
```

**需求：** 需設定 `MODAL_TOKEN_ID` + `MODAL_TOKEN_SECRET` 環境變數，或有 `~/.modal.toml` 配置檔。

**持久性：** 啟用時，沙盒檔案系統會在清理時拍攝快照，並在下一次會話時還原。快照記錄在 `~/.hermes/modal_snapshots.json` 中。這會保留檔案系統狀態，但不會保留活動程序、PID 空間或背景工作。

**憑證檔案：** 會自動從 `~/.hermes/` 掛載 (OAuth Token 等)，並在每個指令執行前同步。

### Daytona 後端

在 [Daytona](https://daytona.io) 託管工作區中執行指令。支援停止/恢復以實現持久性。

```yaml
terminal:
  backend: daytona
  container_cpu: 1                 # CPU 核心
  container_memory: 5120           # MB → 轉換為 GiB
  container_disk: 10240            # MB → 轉換為 GiB (最大 10 GiB)
  container_persistent: true       # 停止/恢復而非刪除
```

**需求：** `DAYTONA_API_KEY` 環境變數。

**持久性：** 啟用時，沙盒在清理時會停止 (不刪除)，並在下次會話時恢復。沙盒名稱遵循 `hermes-{task_id}` 模式。

**磁碟限制：** Daytona 強制執行最大 10 GiB 的限制。超過此值的請求將被限制並發出警告。

### Singularity/Apptainer 後端

在 [Singularity/Apptainer](https://apptainer.org) 容器中執行指令。專為無法使用 Docker 的 HPC 叢集與共享機器設計。

```yaml
terminal:
  backend: singularity
  singularity_image: "docker://nikolaik/python-nodejs:python3.11-nodejs20"
  container_cpu: 1                 # CPU 核心
  container_memory: 5120           # MB
  container_persistent: true       # 可寫層 (Writable overlay) 可跨會話保留
```

**需求：** `$PATH` 中需有 `apptainer` 或 `singularity` 執行檔。

**映像檔處理：** Docker URL (`docker://...`) 會自動轉換為 SIF 檔案並快取。現有的 `.sif` 檔案可直接使用。

**暫存目錄 (Scratch directory)：** 依序解析：`TERMINAL_SCRATCH_DIR` → `TERMINAL_SANDBOX_DIR/singularity` → `/scratch/$USER/hermes-agent` (HPC 慣例) → `~/.hermes/sandboxes/singularity`。

**隔離性：** 使用 `--containall --no-home` 進行完全的命名空間隔離，而不掛載主機的首頁目錄。

### 常見終端機後端問題

如果終端機指令立即失敗，或終端機工具被回報為停用：

- **Local** — 無特殊需求。開始使用時最安全的預設值。
- **Docker** — 執行 `docker version` 檢查 Docker 是否運作正常。若失敗，請修復 Docker 或執行 `hermes config set terminal.backend local`。
- **SSH** — 必須設定 `TERMINAL_SSH_HOST` 與 `TERMINAL_SSH_USER`。若遺漏其中任何一個，Hermes 會記錄明確的錯誤。
- **Modal** — 需要 `MODAL_TOKEN_ID` 環境變數或 `~/.modal.toml`。執行 `hermes doctor` 檢查。
- **Daytona** — 需要 `DAYTONA_API_KEY`。Daytona SDK 會處理伺服器 URL 配置。
- **Singularity** — `$PATH` 中需要 `apptainer` 或 `singularity`。常見於 HPC 叢集。

如有疑慮，請將 `terminal.backend` 設回 `local` 並驗證指令是否能在該處執行。

### Docker 磁碟區掛載 (Volume Mounts)

使用 Docker 後端時，`docker_volumes` 可讓您與容器共享主機目錄。每個項目使用標準 Docker `-v` 語法：`主機路徑:容器路徑[:選項]`。

```yaml
terminal:
  backend: docker
  docker_volumes:
    - "/home/user/projects:/workspace/projects"   # 讀寫 (預設)
    - "/home/user/datasets:/data:ro"              # 唯讀
    - "/home/user/outputs:/outputs"               # Agent 寫入，您讀取
```

這在以下情況很有用：
- **向 Agent 提供檔案** (資料集、配置、參考程式碼)
- **從 Agent 接收檔案** (產生的程式碼、報告、匯出資料)
- **共享工作區** (您與 Agent 存取相同的檔案)

也可以透過環境變數設定：`TERMINAL_DOCKER_VOLUMES='["/host:/container"]'` (JSON 陣列)。

### Docker 憑證轉發

預設情況下，Docker 終端機會話不會繼承任意主機憑證。如果您需要在容器內使用特定 Token，請將其加入 `terminal.docker_forward_env`。

```yaml
terminal:
  backend: docker
  docker_forward_env:
    - "GITHUB_TOKEN"
    - "NPM_TOKEN"
```

Hermes 會先從目前的 Shell 解析列出的每個變數，如果已透過 `hermes config set` 儲存，則回退到 `~/.hermes/.env`。

:::warning
`docker_forward_env` 中列出的任何內容都會對容器內執行的指令可見。請僅轉發您願意暴露給終端機會話的憑證。
:::

### 選填：將啟動目錄掛載至 `/workspace`

Docker 沙盒預設保持隔離。除非您明確選擇加入，否則 Hermes **不會** 將您目前的主機工作目錄傳入容器。

在 `config.yaml` 中啟用：

```yaml
terminal:
  backend: docker
  docker_mount_cwd_to_workspace: true
```

啟用時：
- 如果您從 `~/projects/my-app` 啟動 Hermes，該主機目錄會繫結掛載 (bind-mounted) 至 `/workspace`
- Docker 後端會在 `/workspace` 中啟動
- 檔案工具與終端機指令都會看到相同的掛載專案

停用時，除非您透過 `docker_volumes` 明確掛載內容，否則 `/workspace` 將由沙盒擁有。

安全性權衡：
- `false` 保留沙盒邊界
- `true` 讓沙盒能直接存取您啟動 Hermes 的目錄

請僅在您有意讓容器處理主機上的活動檔案時才使用此選項。

### 持久型 Shell (Persistent Shell)

預設情況下，每個終端機指令都在其自己的子程序中執行 — 工作目錄、環境變數與 Shell 變數會在指令之間重設。啟用 **持久型 Shell** 時，會保持單一長效型 bash 程序在 `execute()` 調用之間運作，以便狀態能在指令之間保留。

這對於 **SSH 後端** 最有用，它還能消除每個指令的連線開銷。對於 SSH，持久型 Shell 是**預設啟用**的，而對於本地後端則是停用的。

```yaml
terminal:
  persistent_shell: true   # 預設值 — 為 SSH 啟用持久型 Shell
```

若要停用：

```bash
hermes config set terminal.persistent_shell false
```

**跨指令保留的內容：**
- 工作目錄 (`cd /tmp` 對下個指令有效)
- 匯出的環境變數 (`export FOO=bar`)
- Shell 變數 (`MY_VAR=hello`)

**優先順序：**

| 層級 | 變數 | 預設值 |
|-------|----------|---------|
| 配置 | `terminal.persistent_shell` | `true` |
| SSH 覆寫 | `TERMINAL_SSH_PERSISTENT` | 隨配置 |
| 本地覆寫 | `TERMINAL_LOCAL_PERSISTENT` | `false` |

各後端環境變數擁有最高優先權。如果您也想在本地後端使用持久型 Shell：

```bash
export TERMINAL_LOCAL_PERSISTENT=true
```

:::note
需要 `stdin_data` 或 sudo 的指令會自動回退到單次模式，因為持久型 Shell 的標準輸入已由 IPC 協定佔用。
:::

有關各後端的詳細資訊，請參閱 [程式碼執行](features/code-execution.md) 與 [README 的終端機部分](features/tools.md)。

## 技能設定

技能可以透過其 SKILL.md 前言 (frontmatter) 宣告其配置設定。這些是非祕密值 (路徑、偏好設定、領域設定)，儲存在 `config.yaml` 的 `skills.config` 命名空間下。

```yaml
skills:
  config:
    wiki:
      path: ~/wiki          # 由 llm-wiki 技能使用
```

**技能設定運作方式：**

- `hermes config migrate` 會掃描所有啟用的技能，找出未配置的設定，並詢問您是否要進行設定
- `hermes config show` 會在「技能設定 (Skill Settings)」下顯示所有技能設定及其所屬的技能
- 載入技能時，解析後的配置值會自動注入技能上下文

**手動設定值：**

```bash
hermes config set skills.config.wiki.path ~/my-research-wiki
```

有關在您自己的技能中宣告配置設定的詳細資訊，請參閱 [建立技能 — 配置設定 (config.yaml)](/docs/developer-guide/creating-skills#config-settings-configyaml)。

## 記憶配置

```yaml
memory:
  memory_enabled: true
  user_profile_enabled: true
  memory_char_limit: 2200   # 約 800 tokens
  user_char_limit: 1375     # 約 500 tokens
```

## 檔案讀取安全

控制單次 `read_file` 調用能回傳的內容上限。超過限制的讀取會被拒絕，並提示錯誤，要求 Agent 使用 `offset` 與 `limit` 來讀取較小的範圍。這可防止單次讀取壓縮過的 JS 套件或大型資料檔案而灌爆上下文視窗。

```yaml
file_read_max_chars: 100000  # 預設值 — 約 25-35K tokens
```

如果您使用的模型具有大型上下文視窗且經常讀取大型檔案，請調高此值。對於小上下文模型，請調低此值以保持讀取效率：

```yaml
# 大型上下文模型 (200K+)
file_read_max_chars: 200000

# 小型本地模型 (16K 上下文)
file_read_max_chars: 30000
```

Agent 也會自動對檔案讀取進行去重 — 如果讀取相同的檔案區域且檔案未變更，則會回傳輕量級存根 (stub)，而不是重新發送內容。這在上下文壓縮時會重設，以便 Agent 在內容被摘要掉後能重新讀取檔案。

## Git Worktree 隔離

為在同一個儲存庫上平行執行多個 Agent 啟用隔離的 git worktree：

```yaml
worktree: true    # 始終建立 worktree (等同於 hermes -w)
# worktree: false # 預設值 — 僅在傳遞 -w 標記時建立
```

啟用時，每個 CLI 會話都會在 `.worktrees/` 下建立一個帶有自己分支的全新 worktree。Agent 可以編輯檔案、提交、推送並建立 PR，而不會互相干擾。乾淨的 worktree 在退出時會被移除；髒的 (有變動) 則會保留供手動復原。

您也可以透過儲存庫根目錄下的 `.worktreeinclude` 列出要複製到 worktree 中的 gitignored 檔案：

```
# .worktreeinclude
.env
.venv/
node_modules/
```

## 上下文壓縮 (Context Compression)

Hermes 會自動壓縮長對話，以保持在模型的上下文視窗內。壓縮摘要器是一個獨立的 LLM 調用 — 您可以將其指向任何提供商或端點。

所有壓縮設定都位於 `config.yaml` 中 (無環境變數)。

### 完整參考

```yaml
compression:
  enabled: true                                     # 開啟/關閉壓縮
  threshold: 0.50                                   # 在上下文限制的此百分比進行壓縮
  target_ratio: 0.20                                # 作為近期結尾保留的閾值比例
  protect_last_n: 20                                # 保留不壓縮的近期訊息最小數量

# 摘要模型/提供商在 auxiliary 下配置：
auxiliary:
  compression:
    model: "google/gemini-3-flash-preview"          # 用於摘要的模型
    provider: "auto"                                # 提供商："auto", "openrouter", "nous", "codex", "main" 等
    base_url: null                                  # 自訂 OpenAI 相容端點 (覆寫提供商)
```

:::info 舊版配置遷移
舊版配置中的 `compression.summary_model`、`compression.summary_provider` 與 `compression.summary_base_url` 會在第一次載入時自動遷移至 `auxiliary.compression.*` (配置版本 17)。無需手動操作。
:::

### 常見設定

**預設 (自動偵測) — 無需配置：**
```yaml
compression:
  enabled: true
  threshold: 0.50
```
使用第一個可用的提供商 (OpenRouter → Nous → Codex) 以及 Gemini Flash。

**強制指定提供商** (基於 OAuth 或 API 金鑰)：
```yaml
auxiliary:
  compression:
    provider: nous
    model: gemini-3-flash
```
適用於任何提供商：`nous`、`openrouter`、`codex`、`anthropic`、`main` 等。

**自訂端點** (自我託管、Ollama、zai、DeepSeek 等)：
```yaml
auxiliary:
  compression:
    model: glm-4.7
    base_url: https://api.z.ai/api/coding/paas/v4
```
指向自訂的 OpenAI 相容端點。使用 `OPENAI_API_KEY` 進行驗證。

### 三個旋鈕如何互動

| `auxiliary.compression.provider` | `auxiliary.compression.base_url` | 結果 |
|---------------------|---------------------|--------|
| `auto` (預設) | 未設定 | 自動偵測最佳可用提供商 |
| `nous` / `openrouter` / 等 | 未設定 | 強制使用該提供商，使用其身分驗證 |
| 任何值 | 已設定 | 直接使用自訂端點 (忽略提供商) |

:::warning 摘要模型上下文長度需求
摘要模型的上下文視窗**必須**至少與您的主 Agent 模型一樣大。壓縮器會將對話的中間大部分發送給摘要模型 — 如果該模型的上下文視窗小於主模型，摘要調用將因上下文長度錯誤而失敗。發生這種情況時，中間的輪次會**被直接丟棄而不進行摘要**，從而導致對話上下文在無聲無息中流失。如果您覆寫了模型，請務必確認其上下文長度等於或大於您的主模型。
:::

## 上下文引擎 (Context Engine)

上下文引擎控制當接近模型的 Token 限制時如何管理對話。內建的 `compressor` 引擎使用有損摘要 (請參閱 [上下文壓縮與快取](/docs/developer-guide/context-compression-and-caching))。外掛引擎可以將其替換為其他策略。

```yaml
context:
  engine: "compressor"    # 預設值 — 內建的有損摘要
```

若要使用外掛引擎 (例如用於無損上下文管理的 LCM)：

```yaml
context:
  engine: "lcm"          # 必須與外掛名稱匹配
```

外掛引擎**絕不會自動啟用** — 您必須明確將 `context.engine` 設為外掛名稱。可透過 `hermes plugins` → 提供商外掛 (Provider Plugins) → 上下文引擎 (Context Engine) 來瀏覽並選取可用的引擎。

請參閱 [記憶提供商](/docs/user-guide/features/memory-providers)，瞭解記憶外掛類似的單選系統。

## 迭代配額壓力 (Iteration Budget Pressure)

當 Agent 正在處理包含許多工具調用的複雜任務時，可能會消耗掉其迭代配額 (預設：90 輪) 而未意識到配額不足。配額壓力會在模型接近限制時自動警告它：

| 閾值 | 等級 | 模型看到的內容 |
|-----------|-------|---------------------|
| **70%** | 注意 | `[BUDGET: 63/90. 27 iterations left. Start consolidating.]` |
| **90%** | 警告 | `[BUDGET WARNING: 81/90. Only 9 left. Respond NOW.]` |

警告會注入最後一個工具結果的 JSON (作為 `_budget_warning` 欄位)，而不是作為獨立訊息 — 這能保留提示詞快取，且不會破壞對話結構。

```yaml
agent:
  max_turns: 90                # 每個對話輪次的最大迭代次數 (預設：90)
```

配額壓力預設為啟用。Agent 會自然地在工具結果中看到警告，鼓勵其整合工作並在配額耗盡前給出回覆。

當迭代配額完全耗盡時，CLI 會向使用者顯示通知：`⚠ Iteration budget reached (90/90) — response may be incomplete`。如果配額在活動期間耗盡，Agent 會在停止前產生已完成內容的摘要。

### 串流逾時

LLM 串流連線有兩個逾時層。兩者都會針對本地提供商 (localhost, 區域網路 IP) 自動調整 — 對於大多數設定無需配置。

| 逾時項目 | 預設值 | 本地提供商 | 環境變數 |
|---------|---------|----------------|---------|
| Socket 讀取逾時 | 120s | 自動調升至 1800s | `HERMES_STREAM_READ_TIMEOUT` |
| 陳舊串流偵測 | 180s | 自動停用 | `HERMES_STREAM_STALE_TIMEOUT` |
| API 調用 (非串流) | 1800s | 不變 | `HERMES_API_TIMEOUT` |

**Socket 讀取逾時**控制 httpx 等待提供商發送下一塊數據的時間。本地 LLM 在產生第一個 Token 之前，可能需要幾分鐘來預填 (prefill) 大型上下文，因此當偵測到本地端點時，Hermes 會將此值調升至 30 分鐘。如果您明確設定了 `HERMES_STREAM_READ_TIMEOUT`，則無論端點偵測結果如何，都會使用該值。

**陳舊串流偵測**會關閉那些接收到 SSE keep-alive ping 但無實際內容的連線。對於本地提供商，此功能會完全停用，因為它們在預填期間不會發送 keep-alive ping。

## 上下文壓力警告

與迭代配額壓力分開，上下文壓力會追蹤對話與**壓縮閾值**的接近程度 — 即觸發上下文壓縮以摘要舊訊息的時間點。這有助於您和 Agent 瞭解對話何時變長。

| 進度 | 等級 | 發生的狀況 |
|----------|-------|-------------|
| 接近閾值 **≥ 60%** | 資訊 | CLI 顯示青色進度條；閘道發送資訊通知 |
| 接近閾值 **≥ 85%** | 警告 | CLI 顯示粗體黃色條；閘道警告即將進行壓縮 |

在 CLI 中，上下文壓力會顯示在工具輸出流的進度條中：

```
  ◐ context ████████████░░░░░░░░ 62% to compaction  48k threshold (50%) · approaching compaction
```

在通訊平台上，會發送純文字通知：

```
◐ Context: ████████████░░░░░░░░ 62% to compaction (threshold: 50% of window).
```

如果停用了自動壓縮，警告則會告知您上下文可能會被截斷。

上下文壓力是自動的 — 無需配置。它純粹作為面向使用者的通知觸發，不會修改訊息流或向模型的上下文中注入任何內容。

## 憑證池策略 (Credential Pool Strategies)

當您針對同一個提供商擁有複數個 API 金鑰或 OAuth Token 時，請配置輪詢策略：

```yaml
credential_pool_strategies:
  openrouter: round_robin    # 均勻地循環使用金鑰
  anthropic: least_used      # 始終選取使用次數最少的金鑰
```

選項：`fill_first` (預設)、`round_robin`、`least_used`、`random`。請參閱 [憑證池](/docs/user-guide/features/credential-pools) 取得完整文件。

## 輔助模型 (Auxiliary Models)

Hermes 使用輕量級的「輔助」模型來處理側邊任務，例如圖片分析、網頁摘要以及瀏覽器螢幕截圖分析。預設情況下，這些任務會透過自動偵測使用 **Gemini Flash** — 您無需配置任何內容。

### 通用的配置模式

Hermes 中的每個模型插槽 — 輔助任務、壓縮、回退 — 都使用相同的三個旋鈕：

| 鍵 | 作用 | 預設值 |
|-----|-------------|---------|
| `provider` | 用於身分驗證與路由的提供商 | `"auto"` |
| `model` | 要求的模型 | 提供商的預設值 |
| `base_url` | 自訂 OpenAI 相容端點 (覆寫提供商) | 未設定 |

設定 `base_url` 時，Hermes 會忽略提供商並直接調用該端點 (使用 `api_key` 或 `OPENAI_API_KEY` 進行驗證)。僅設定 `provider` 時，Hermes 會使用該提供商內建的身分驗證與基礎 URL。

輔助任務的可用提供商包括：`auto`、`openrouter`、`nous`、`codex`、`copilot`、`anthropic`、`main`、`zai`、`kimi-coding`、`kimi-coding-cn`、`arcee`、`minimax`，以及在 [提供商註冊表](/docs/reference/environment-variables) 中註冊的任何提供商，或您 `custom_providers` 清單中的任何命名自訂提供商 (例如 `provider: "beans"`)。

:::warning `"main"` 僅供輔助任務使用
`"main"` 提供商選項表示「使用我的主 Agent 使用的任何提供商」 — 這僅在 `auxiliary:`、`compression:` 與 `fallback_model:` 配置中有效。這**不是**頂層 `model.provider` 設定的有效值。如果您使用自訂的 OpenAI 相容端點，請在 `model:` 區段中設定 `provider: custom`。有關所有主模型提供商選項，請參閱 [AI 提供商](/docs/integrations/providers)。
:::

### 輔助配置完整參考

```yaml
auxiliary:
  # 圖片分析 (vision_analyze 工具 + 瀏覽器螢幕截圖)
  vision:
    provider: "auto"           # "auto", "openrouter", "nous", "codex", "main" 等
    model: ""                  # 例如 "openai/gpt-4o", "google/gemini-2.5-flash"
    base_url: ""               # 自訂 OpenAI 相容端點 (覆寫提供商)
    api_key: ""                # base_url 的 API 金鑰 (回退至 OPENAI_API_KEY)
    timeout: 120               # 秒 — LLM API 調用逾時；Vision 負載需要寬裕的逾時
    download_timeout: 30       # 秒 — 圖片 HTTP 下載；慢速連線請調高

  # 網頁摘要 + 瀏覽器頁面文字擷取
  web_extract:
    provider: "auto"
    model: ""                  # 例如 "google/gemini-2.5-flash"
    base_url: ""
    api_key: ""
    timeout: 360               # 秒 (6分鐘) — 每次嘗試的 LLM 摘要逾時

  # 危險指令批准分類器
  approval:
    provider: "auto"
    model: ""
    base_url: ""
    api_key: ""
    timeout: 30                # 秒

  # 上下文壓縮逾時 (與 compression.* 配置分開)
  compression:
    timeout: 120               # 秒 — 壓縮會摘要長對話，需要較多時間

  # 會話搜尋 — 摘要過去的會話匹配項
  session_search:
    provider: "auto"
    model: ""
    base_url: ""
    api_key: ""
    timeout: 30

  # 技能中心 — 技能匹配與搜尋
  skills_hub:
    provider: "auto"
    model: ""
    base_url: ""
    api_key: ""
    timeout: 30

  # MCP 工具調度
  mcp:
    provider: "auto"
    model: ""
    base_url: ""
    api_key: ""
    timeout: 30

  # 記憶體刷新 — 為持久記憶摘要對話
  flush_memories:
    provider: "auto"
    model: ""
    base_url: ""
    api_key: ""
    timeout: 30
```

:::tip
每個輔助任務都有可配置的 `timeout` (以秒為單位)。預設值：Vision 120s、web_extract 360s、approval 30s、compression 120s。如果您在輔助任務中使用緩慢的本地模型，請調高這些值。Vision 還有獨立的 `download_timeout` (預設 30s) 用於圖片 HTTP 下載 — 針對慢速連線或自我託管圖片伺服器，請調高此值。
:::

:::info
上下文壓縮有自己的 `compression:` 區塊用於設定閾值，以及 `auxiliary.compression:` 區塊用於模型/提供商設定 — 請參閱上方的 [上下文壓縮](#context-compression)。回退模型使用 `fallback_model:` 區塊 — 請參閱 [回退模型](/docs/integrations/providers#fallback-model)。這三者都遵循相同的 provider/model/base_url 模式。
:::

### 變更 Vision 模型

若要使用 GPT-4o 而非 Gemini Flash 進行圖片分析：

```yaml
auxiliary:
  vision:
    model: "openai/gpt-4o"
```

或者透過環境變數 (在 `~/.hermes/.env` 中)：

```bash
AUXILIARY_VISION_MODEL=openai/gpt-4o
```

### 提供商選項

這些選項適用於**輔助任務配置** (`auxiliary:`、`compression:`、`fallback_model:`)，而非您的主 `model.provider` 設定。

| 提供商 | 描述 | 需求 |
|----------|-------------|-------------|
| `"auto"` | 最佳可用 (預設)。Vision 會依序嘗試 OpenRouter → Nous → Codex。 | — |
| `"openrouter"` | 強制 OpenRouter — 路由至任何模型 (Gemini, GPT-4o, Claude 等) | `OPENROUTER_API_KEY` |
| `"nous"` | 強制 Nous Portal | `hermes auth` |
| `"codex"` | 強制 Codex OAuth (ChatGPT 帳號)。支援 Vision (gpt-5.3-codex)。 | `hermes model` → Codex |
| `"main"` | 使用您目前使用的主端點。這可以來自 `OPENAI_BASE_URL` + `OPENAI_API_KEY` 或經由 `hermes model` / `config.yaml` 儲存的自訂端點。支援 OpenAI、本地模型或任何 OpenAI 相容 API。**僅限輔助任務 — 對於 `model.provider` 無效。** | 自訂端點憑證 + 基礎 URL |

### 常見設定

**直接使用自訂端點** (比輔助任務中的 `provider: "main"` 更明確)：
```yaml
auxiliary:
  vision:
    base_url: "http://localhost:1234/v1"
    api_key: "local-key"
    model: "qwen2.5-vl"
```

`base_url` 的優先順序高於 `provider`，因此這是將輔助任務路由至特定端點最明確的方式。對於直接覆寫端點，Hermes 會使用配置的 `api_key` 或回退至 `OPENAI_API_KEY`；它不會為該自訂端點重複使用 `OPENROUTER_API_KEY`。

**使用 OpenAI API 金鑰進行 Vision：**
```yaml
# 在 ~/.hermes/.env 中：
# OPENAI_BASE_URL=https://api.openai.com/v1
# OPENAI_API_KEY=sk-...

auxiliary:
  vision:
    provider: "main"
    model: "gpt-4o"       # 或使用較便宜的 "gpt-4o-mini"
```

**使用 OpenRouter 進行 Vision** (路由至任何模型)：
```yaml
auxiliary:
  vision:
    provider: "openrouter"
    model: "openai/gpt-4o"      # 或 "google/gemini-2.5-flash" 等
```

**使用 Codex OAuth** (ChatGPT Pro/Plus 帳號 — 無需 API 金鑰)：
```yaml
auxiliary:
  vision:
    provider: "codex"     # 使用您的 ChatGPT OAuth Token
    # 模型預設為 gpt-5.3-codex (支援 Vision)
```

**使用本地/自我託管模型：**
```yaml
auxiliary:
  vision:
    provider: "main"      # 使用您目前作用中的自訂端點
    model: "my-local-model"
```

`provider: "main"` 使用 Hermes 在一般對話中使用的提供商 — 無論是命名的自訂提供商 (例如 `beans`)、像 `openrouter` 這樣的內建提供商，還是舊版的 `OPENAI_BASE_URL` 端點。

:::tip
如果您使用 Codex OAuth 作為主要模型提供商，Vision 會自動運作 — 無需額外配置。Codex 已包含在 Vision 的自動偵測鏈中。
:::

:::warning
**Vision 需要多模態模型。** 如果您設定了 `provider: "main"`，請確保您的端點支援多模態/Vision — 否則圖片分析將失敗。
:::

### 環境變數 (舊版)

輔助模型也可以透過環境變數配置。然而，`config.yaml` 是首選方法 — 它更易於管理並支援所有選項，包括 `base_url` 與 `api_key`。

| 設定項目 | 環境變數 |
|---------|---------------------|
| Vision 提供商 | `AUXILIARY_VISION_PROVIDER` |
| Vision 模型 | `AUXILIARY_VISION_MODEL` |
| Vision 端點 | `AUXILIARY_VISION_BASE_URL` |
| Vision API 金鑰 | `AUXILIARY_VISION_API_KEY` |
| 網頁擷取提供商 | `AUXILIARY_WEB_EXTRACT_PROVIDER` |
| 網頁擷取模型 | `AUXILIARY_WEB_EXTRACT_MODEL` |
| 網頁擷取端點 | `AUXILIARY_WEB_EXTRACT_BASE_URL` |
| 網頁擷取 API 金鑰 | `AUXILIARY_WEB_EXTRACT_API_KEY` |

壓縮與回退模型設定僅限 config.yaml 使用。

:::tip
執行 `hermes config` 查看您目前的輔助模型設定。覆寫值僅在與預設值不同時才會顯示。
:::

## 推理力度 (Reasoning Effort)

控制模型在回應前進行「思考」的程度：

```yaml
agent:
  reasoning_effort: ""   # 空白 = medium (預設)。選項：none, minimal, low, medium, high, xhigh (最大)
```

未設定時 (預設)，推理力度預設為 "medium" — 這是一個平衡的水平，適用於大多數任務。設定值會覆寫此項 — 較高的推理力度可在複雜任務中獲得更好的結果，代價是更多的 Token 與延遲。

您也可以在執行階段使用 `/reasoning` 指令變更推理力度：

```
/reasoning           # 顯示目前力度等級與顯示狀態
/reasoning high      # 將推理力度設為 high
/reasoning none      # 停用推理
/reasoning show      # 在每個回應上方顯示模型思考過程
/reasoning hide      # 隱藏模型思考過程
```

## 工具使用強制執行 (Tool-Use Enforcement)

某些模型偶爾會將預期的動作以文字描述，而非進行工具調用 (「我會執行測試...」而非實際調用終端機)。工具使用強制執行會注入系統提示詞引導，將模型導回實際調用工具的路徑。

```yaml
agent:
  tool_use_enforcement: "auto"   # "auto" | true | false | ["模型子字串", ...]
```

| 值 | 行為 |
|-------|----------|
| `"auto"` (預設) | 對符合以下條件的模型啟用：`gpt`, `codex`, `gemini`, `gemma`, `grok`。對所有其他模型停用 (Claude, DeepSeek, Qwen 等)。 |
| `true` | 始終啟用，不論模型。如果您注意到目前模型在描述動作而非執行動作時很有用。 |
| `false` | 始終停用，不論模型。 |
| `["gpt", "codex", "qwen", "llama"]` | 僅當模型名稱包含列出的任一子字串時啟用 (不分大小寫)。 |

### 注入的內容

啟用時，系統提示詞可能會增加三層引導：

1. **通用工具使用強制執行** (所有匹配的模型) — 指示模型立即進行工具調用而非描述意圖，持續工作直到任務完成，且絕不在對話輪次結束時承諾未來的動作。

2. **OpenAI 執行紀律** (僅限 GPT 與 Codex 模型) — 針對 GPT 特有的失敗模式增加引導：根據部分結果放棄工作、略過必備的查找、產生幻覺而非使用工具，以及在未驗證前宣告「完成」。

3. **Google 運作指引** (僅限 Gemini 與 Gemma 模型) — 簡潔性、絕對路徑、平行工具調用以及編輯前驗證模式。

這些對使用者是透明的，僅影響系統提示詞。已經能可靠使用工具的模型 (如 Claude) 不需要此引導，這也是為何 `"auto"` 將其排除的原因。

### 何時開啟

如果您使用的模型不在預設的自動清單中，且注意到它頻繁描述它「會」做什麼而非實際去做，請設定 `tool_use_enforcement: true` 或將模型子字串加入清單：

```yaml
agent:
  tool_use_enforcement: ["gpt", "codex", "gemini", "grok", "my-custom-model"]
```

## TTS 配置

```yaml
tts:
  provider: "edge"              # "edge" | "elevenlabs" | "openai" | "minimax" | "mistral" | "neutts"
  speed: 1.0                    # 全域速度倍率 (所有提供商的回退值)
  edge:
    voice: "en-US-AriaNeural"   # 322 種語音，74 種語言
    speed: 1.0                  # 速度倍率 (轉換為速率百分比，例如 1.5 → +50%)
  elevenlabs:
    voice_id: "pNInz6obpgDQGcFmaJgB"
    model_id: "eleven_multilingual_v2"
  openai:
    model: "gpt-4o-mini-tts"
    voice: "alloy"              # alloy, echo, fable, onyx, nova, shimmer
    speed: 1.0                  # 速度倍率 (由 API 限制在 0.25–4.0 之間)
    base_url: "https://api.openai.com/v1"  # OpenAI 相容 TTS 端點的覆寫
  minimax:
    speed: 1.0                  # 語音速度倍率
    # base_url: ""              # 選填：OpenAI 相容 TTS 端點的覆寫
  neutts:
    ref_audio: ''
    ref_text: ''
    model: neuphonic/neutts-air-q4-gguf
    device: cpu
```

這控制了 `text_to_speech` 工具以及語音模式 (`/voice tts` 在 CLI 或訊息閘道中) 的語音回覆。

**速度回退階層：** 提供商特定速度 (例如 `tts.edge.speed`) → 全域 `tts.speed` → `1.0` 預設值。設定全域 `tts.speed` 以統一套用速度至所有提供商，或針對每個提供商進行微調覆寫。

## 顯示設定 (Display Settings)

```yaml
display:
  tool_progress: all      # off | new | all | verbose
  tool_progress_command: false  # 在訊息閘道中啟用 /verbose 斜線指令
  tool_progress_overrides: {}  # 各平台覆寫 (見下文)
  interim_assistant_messages: true  # 閘道：將對話輪次中自然的 Assistant 更新作為獨立訊息發送
  skin: default           # 內建或自訂 CLI 外觀 (Skin) (見 user-guide/features/skins)
  personality: "kawaii"  # 舊版裝飾性欄位，仍會出現在某些摘要中
  compact: false          # 緊湊輸出模式 (較少空白)
  resume_display: full    # full (恢復時顯示先前訊息) | minimal (僅顯示一行)
  bell_on_complete: false # 當 Agent 完成時鳴響終端機鈴聲 (適合耗時長任務)
  show_reasoning: false   # 在每個回應上方顯示模型推理/思考過程 (以 /reasoning show|hide 切換)
  streaming: false        # 在 Token 到達時將其串流至終端機 (即時輸出)
  show_cost: false        # 在 CLI 狀態列中顯示預估費用 ($)
  tool_preview_length: 0  # 工具調用預覽的最大字元數 (0 = 無限制，顯示完整路徑/指令)
```

| 模式 | 您看到的內容 |
|------|-------------|
| `off` | 靜默 — 僅顯示最終回應 |
| `new` | 僅在工具變更時顯示工具指示器 |
| `all` | 顯示每個工具調用與簡短預覽 (預設) |
| `verbose` | 完整的參數、結果與偵錯日誌 |

在 CLI 中，使用 `/verbose` 循環切換這些模式。要在通訊平台 (Telegram、Discord、Slack 等) 使用 `/verbose`，請在 `display` 區段設定 `tool_progress_command: true`。指令會循環切換模式並儲存至配置。

### 各平台進度覆寫

不同的平台有不同的詳細程度需求。例如，Signal 無法編輯訊息，因此每個進度更新都會變成獨立訊息 — 雜訊過多。使用 `tool_progress_overrides` 來設定各平台的模式：

```yaml
display:
  tool_progress: all          # 全域預設值
  tool_progress_overrides:
    signal: 'off'             # 在 Signal 上靜默進度
    telegram: verbose         # 在 Telegram 上顯示詳細進度
    slack: 'off'              # 在共享的 Slack 工作區中保持安靜
```

未設定覆寫的平台會回退到全域 `tool_progress` 值。有效的平台鍵：`telegram`、`discord`、`slack`、`signal`、`whatsapp`、`matrix`、`mattermost`、`email`、`sms`、`homeassistant`、`dingtalk`、`feishu`、`wecom`、`weixin`、`bluebubbles`、`qqbot`。

`interim_assistant_messages` 僅限閘道使用。啟用時，Hermes 會將已完成的對話輪次中 Assistant 更新作為獨立的聊天訊息發送。這獨立於 `tool_progress` 且不需要閘道串流。

## 隱私 (Privacy)

```yaml
privacy:
  redact_pii: false  # 從 LLM 上下文中移除 PII (僅限閘道)
```

當 `redact_pii` 為 `true` 時，閘道會在將系統提示詞發送給 LLM 前，於支援的平台上移除個人識別資訊 (PII)：

| 欄位 | 處理方式 |
|-------|-----------|
| 電話號碼 (WhatsApp/Signal 的使用者 ID) | 雜湊 (Hash) 為 `user_<12-char-sha256>` |
| 使用者 ID | 雜湊為 `user_<12-char-sha256>` |
| 聊天 ID | 數字部分雜湊，保留平台前置詞 (`telegram:<hash>`) |
| 家庭頻道 ID | 數字部分雜湊 |
| 使用者名稱 / 顯示名稱 | **不受影響** (由使用者選擇，公開可見) |

**平台支援：** 移除功能適用於 WhatsApp、Signal 與 Telegram。Discord 與 Slack 不包含在內，因為它們的標記系統 (`<@user_id>`) 需要在 LLM 上下文中使用真實 ID。

雜湊是確定性的 — 相同的使用者始終對應到相同的雜湊值，因此模型仍可在群組聊天中區分不同的使用者。路由與交付在內部仍使用原始值。

## 語音轉文字 (STT)

```yaml
stt:
  provider: "local"            # "local" | "groq" | "openai" | "mistral"
  local:
    model: "base"              # tiny, base, small, medium, large-v3
  openai:
    model: "whisper-1"         # whisper-1 | gpt-4o-mini-transcribe | gpt-4o-transcribe
  # model: "whisper-1"         # 仍支援的舊版回退鍵
```

提供商行為：

- `local` 使用在您的機器上執行的 `faster-whisper`。請透過 `pip install faster-whisper` 另外安裝。
- `groq` 使用 Groq 的 Whisper 相容端點，讀取 `GROQ_API_KEY`。
- `openai` 使用 OpenAI 語音 API，讀取 `VOICE_TOOLS_OPENAI_KEY`。

如果請求的提供商不可用，Hermes 會依此順序自動回退：`local` → `groq` → `openai`。

Groq 與 OpenAI 的模型覆寫由環境變數驅動：

```bash
STT_GROQ_MODEL=whisper-large-v3-turbo
STT_OPENAI_MODEL=whisper-1
GROQ_BASE_URL=https://api.groq.com/openai/v1
STT_OPENAI_BASE_URL=https://api.openai.com/v1
```

## 語音模式 (CLI)

```yaml
voice:
  record_key: "ctrl+b"         # CLI 內部的隨按即說 (PTT) 按鍵
  max_recording_seconds: 120    # 長錄音的強制停止時間
  auto_tts: false               # 在 /voice on 時自動啟用語音回覆
  silence_threshold: 200        # 語音偵測的 RMS 閾值
  silence_duration: 3.0         # 自動停止前的靜默秒數
```

在 CLI 中使用 `/voice on` 啟用麥克風模式，使用 `record_key` 開始/停止錄音，並使用 `/voice tts` 切換語音回覆。請參閱 [語音模式](/docs/user-guide/features/voice-mode) 瞭解端對端設定與平台特定行為。

## 串流 (Streaming)

在 Token 到達時將其串流至終端機或通訊平台，而不是等待完整回應。

### CLI 串流

```yaml
display:
  streaming: true         # 即時將 Token 串流至終端機
  show_reasoning: true    # 同時串流推理/思考 Token (選填)
```

啟用時，回應會以 Token 為單位顯示在串流方塊中。工具調用仍會靜默擷取。如果提供商不支援串流，系統會自動回退至一般顯示方式。

### 閘道串流 (Telegram, Discord, Slack)

```yaml
streaming:
  enabled: true           # 啟用漸進式訊息編輯
  transport: edit         # "edit" (漸進式訊息編輯) 或 "off"
  edit_interval: 0.3      # 訊息編輯之間的秒數
  buffer_threshold: 40    # 強制排清編輯內容前的字元數
  cursor: " ▉"            # 串流期間顯示的游標
```

啟用時，機器人會在收到第一個 Token 時發送訊息，接著隨著更多 Token 到達而漸進式地編輯該訊息。不支援訊息編輯的平台 (Signal, Email, Home Assistant) 會在第一次嘗試時自動偵測 — 串流會在該會話中優雅地停用，而不會產生訊息洪水。

對於不使用漸進式 Token 編輯的獨立對話輪次中 Assistant 更新，請設定 `display.interim_assistant_messages: true`。

**溢位處理：** 如果串流文字超過平台的訊息長度限制 (約 4096 字元)，目前的訊息會被定稿，並自動開始一則新訊息。

:::note
串流功能預設停用。請在 `~/.hermes/config.yaml` 中啟用以體驗串流 UX。
:::

## 群組聊天會話隔離

控制共享聊天是為每個房間保留一個對話，還是為每個參與者保留一個對話：

```yaml
group_sessions_per_user: true  # true = 群組/頻道內的使用者隔離，false = 每個聊天一個共享會話
```

- `true` 是預設且建議的設定。在 Discord 頻道、Telegram 群組、Slack 頻道及類似的共享環境中，當平台提供使用者 ID 時，每個發送者都會獲得自己的會話。
- `false` 會回復到舊有的共享房間行為。如果您明確希望 Hermes 將頻道視為一個協作對話，這會很有用，但這也意味著使用者會共享上下文、Token 費用與中斷狀態。
- 私訊 (Direct messages) 不受影響。Hermes 仍會像往常一樣以聊天/私訊 ID 為鍵。
- 不論哪種設定，貼文串 (Threads) 都會與其父頻道隔離；設為 `true` 時，貼文串內的每個參與者也會獲得自己的會話。

有關行為詳情與範例，請參閱 [會話](/docs/user-guide/sessions) 與 [Discord 指南](/docs/user-guide/messaging/discord)。

## 未授權私訊 (DM) 行為

控制 Hermes 在收到未知使用者的私訊時如何處理：

```yaml
unauthorized_dm_behavior: pair

whatsapp:
  unauthorized_dm_behavior: ignore
```

- `pair` 是預設值。Hermes 會拒絕存取，但在私訊中回覆一個單次配對代碼。
- `ignore` 會靜默丟棄未授權的私訊。
- 平台區段會覆寫全域預設值，因此您可以廣泛啟用配對功能，同時讓單一平台保持安靜。

## 快速指令 (Quick Commands)

定義自訂指令，無需調用 LLM 即可執行 Shell 指令 — 零 Token 使用，立即執行。在通訊平台 (Telegram, Discord 等) 上特別有用，可用於快速伺服器檢查或公用程式指令碼。

```yaml
quick_commands:
  status:
    type: exec
    command: systemctl status hermes-agent
  disk:
    type: exec
    command: df -h /
  update:
    type: exec
    command: cd ~/.hermes/hermes-agent && git pull && pip install -e .
  gpu:
    type: exec
    command: nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total --format=csv,noheader
```

用法：在 CLI 或任何通訊平台中輸入 `/status`、`/disk`、`/update` 或 `/gpu`。指令會直接在主機本地執行並回傳輸出 — 無 LLM 調用，不消耗 Token。

- **30 秒逾時** — 執行時間過長的指令會被終止並顯示錯誤訊息
- **優先順序** — 快速指令會在技能指令前檢查，因此您可以覆寫技能名稱
- **自動補全** — 快速指令在分派時解析，不會顯示在內建的斜線指令自動補全表中
- **類型** — 僅支援 `exec` (執行 Shell 指令)；其他類型會顯示錯誤
- **隨處可用** — CLI, Telegram, Discord, Slack, WhatsApp, Signal, Email, Home Assistant

## 人類延遲 (Human Delay)

在通訊平台中模擬人類般的反應節奏：

```yaml
human_delay:
  mode: "off"                  # off | natural | custom
  min_ms: 800                  # 最小延遲 (custom 模式)
  max_ms: 2500                 # 最大延遲 (custom 模式)
```

## 程式碼執行

配置受沙盒保護的 Python 程式碼執行工具：

```yaml
code_execution:
  timeout: 300                 # 最大執行時間 (秒)
  max_tool_calls: 50           # 程式碼執行內的最大工具調用次數
```

## 網頁搜尋後端

`web_search`、`web_extract` 與 `web_crawl` 工具支援四種後端提供商。請在 `config.yaml` 或透過 `hermes tools` 配置後端：

```yaml
web:
  backend: firecrawl    # firecrawl | parallel | tavily | exa
```

| 後端 | 環境變數 | 搜尋 (Search) | 擷取 (Extract) | 爬取 (Crawl) |
|---------|---------|--------|---------|-------|
| **Firecrawl** (預設) | `FIRECRAWL_API_KEY` | ✔ | ✔ | ✔ |
| **Parallel** | `PARALLEL_API_KEY` | ✔ | ✔ | — |
| **Tavily** | `TAVILY_API_KEY` | ✔ | ✔ | ✔ |
| **Exa** | `EXA_API_KEY` | ✔ | ✔ | — |

**後端選取：** 如果未設定 `web.backend`，後端會根據可用的 API 金鑰自動偵測。如果僅設定了 `EXA_API_KEY`，則使用 Exa。如果僅設定了 `TAVILY_API_KEY`，則使用 Tavily。如果僅設定了 `PARALLEL_API_KEY`，則使用 Parallel。否則 Firecrawl 為預設值。

**自我託管 Firecrawl：** 設定 `FIRECRAWL_API_URL` 指向您自己的執行個體。當設定自訂 URL 時，API 金鑰變為選填 (在伺服器上設定 `USE_DB_AUTHENTICATION=false` 以停用驗證)。

**Parallel 搜尋模式：** 設定 `PARALLEL_SEARCH_MODE` 控制搜尋行為 — `fast`、`one-shot` 或 `agentic` (預設：`agentic`)。

## 瀏覽器 (Browser)

配置瀏覽器自動化行為：

```yaml
browser:
  inactivity_timeout: 120        # 自動關閉閒置會話前的秒數
  command_timeout: 30             # 瀏覽器指令 (截圖、導覽等) 的逾時秒數
  record_sessions: false         # 自動將瀏覽器會話錄製為 WebM 影片至 ~/.hermes/browser_recordings/
  camofox:
    managed_persistence: false   # 為 true 時，Camofox 會話會跨重啟保留 Cookie/登入狀態
```

瀏覽器工具集支援多個提供商。詳情請參閱 [瀏覽器功能頁面](/docs/user-guide/features/browser) 以瞭解 Browserbase、Browser Use 與本地 Chrome CDP 設定。

## 時區 (Timezone)

以 IANA 時區字串覆寫伺服器本地時區。影響日誌中的時間戳記、cron 排程與系統提示詞的時間注入。

```yaml
timezone: "America/New_York"   # IANA 時區 (預設："" = 伺服器本地時間)
```

支援的值：任何 IANA 時區識別碼 (例如 `America/New_York`、`Europe/London`、`Asia/Kolkata`、`UTC`)。留空或省略則使用伺服器本地時間。

## Discord

為訊息閘道配置 Discord 特定行為：

```yaml
discord:
  require_mention: true          # 在伺服器頻道中需要 @標記 才回應
  free_response_channels: ""     # 機器人無需 @標記 即可回應的頻道 ID (以逗號分隔)
  auto_thread: true              # 在頻道內 @標記 時自動建立貼文串 (Thread)
```

- `require_mention` — 設為 `true` (預設) 時，機器人僅在伺服器頻道中被 `@BotName` 標記時才回應。私訊始終無需標記即可運作。
- `free_response_channels` — 頻道 ID 清單，機器人會回應其中的每一則訊息而無需標記。
- `auto_thread` — 設為 `true` (預設) 時，頻道內的標記會自動為對話建立貼文串，保持頻道整潔 (類似 Slack 的貼文串功能)。

## 安全性 (Security)

執行前安全性掃描與祕密遮蔽：

```yaml
security:
  redact_secrets: true           # 遮蔽工具輸出與日誌中的 API 金鑰模式
  tirith_enabled: true           # 為終端機指令啟用 Tirith 安全性掃描
  tirith_path: "tirith"          # tirith 執行檔路徑 (預設：$PATH 中的 "tirith")
  tirith_timeout: 5              # 等待 tirith 掃描的秒數
  tirith_fail_open: true         # 若 tirith 不可用，允許執行指令
  website_blocklist:             # 見下方的網頁封鎖清單區段
    enabled: false
    domains: []
    shared_files: []
```

- `redact_secrets` — 自動偵測並遮蔽工具輸出中看起來像 API 金鑰、Token 與密碼的模式，避免其進入對話上下文與日誌。
- `tirith_enabled` — 設為 `true` 時，終端機指令在執行前會由 [Tirith](https://github.com/StackGuardian/tirith) 掃描，以偵測潛在的危險操作。
- `tirith_path` — tirith 執行檔路徑。如果 tirith 安裝在非標準位置，請設定此項。
- `tirith_timeout` — 等待 tirith 掃描的最大秒數。如果掃描逾時，指令會繼續執行。
- `tirith_fail_open` — 設為 `true` (預設) 時，若 tirith 不可用或失敗，允許指令執行。設為 `false` 則在 tirith 無法驗證時封鎖指令。

## 網頁封鎖清單 (Website Blocklist)

封鎖 Agent 的網頁與瀏覽器工具存取特定網域：

```yaml
security:
  website_blocklist:
    enabled: false               # 啟用 URL 封鎖 (預設：false)
    domains:                     # 封鎖的網域模式清單
      - "*.internal.company.com"
      - "admin.example.com"
      - "*.local"
    shared_files:                # 從外部檔案載入額外規則
      - "/etc/hermes/blocked-sites.txt"
```

啟用時，任何與封鎖網域模式匹配的 URL 都會在網頁或瀏覽器工具執行前被拒絕。這適用於 `web_search`、`web_extract`、`browser_navigate` 以及任何存取 URL 的工具。

網域規則支援：
- 精確網域：`admin.example.com`
- 萬用字元子網域：`*.internal.company.com` (封鎖所有子網域)
- TLD 萬用字元：`*.local`

共享檔案每行包含一個網域規則 (空白行與 `#` 註釋會被忽略)。遺漏或無法讀取的檔案會記錄警告，但不會停用其他網頁工具。

此策略會快取 30 秒，因此配置變更無需重啟即可快速生效。

## 智慧批准 (Smart Approvals)

控制 Hermes 如何處理潛在危險指令：

```yaml
approvals:
  mode: manual   # manual | smart | off
```

| 模式 | 行為 |
|------|----------|
| `manual` (預設) | 在執行任何被標記的指令前詢問使用者。在 CLI 中顯示互動式批准對話方塊。在訊息閘道中，將待處理的批准請求排入佇列。 |
| `smart` | 使用輔助 LLM 評估被標記的指令是否真的危險。低風險指令會自動批准並具有會話級別的持久性。真正危險的指令會呈報給使用者。 |
| `off` | 跳過所有批准檢查。等同於 `HERMES_YOLO_MODE=true`。**請謹慎使用。** |

智慧模式對於減少批准疲勞特別有用 — 它讓 Agent 在安全操作上能更自主地工作，同時仍能攔截真正具有破壞性的指令。

:::warning
設定 `approvals.mode: off` 會停用終端機指令的所有安全檢查。僅在受信任的沙盒環境中使用。
:::

## 檢查點 (Checkpoints)

在具破壞性的檔案操作前自動拍攝檔案系統快照。詳情請參閱 [檢查點與復原](/docs/user-guide/checkpoints-and-rollback)。

```yaml
checkpoints:
  enabled: true                  # 啟用自動檢查點 (也可使用：hermes --checkpoints)
  max_snapshots: 50              # 每個目錄保留的最大檢查點數量
```


## 委派 (Delegation)

為 delegate 工具配置子 Agent (Subagent) 行為：

```yaml
delegation:
  # model: "google/gemini-3-flash-preview"  # 覆寫模型 (空白 = 繼承父代)
  # provider: "openrouter"                  # 覆寫提供商 (空白 = 繼承父代)
  # base_url: "http://localhost:1234/v1"    # 直接 OpenAI 相容端點 (優先順序高於提供商)
  # api_key: "local-key"                    # base_url 的 API 金鑰 (回退至 OPENAI_API_KEY)
```

**子 Agent 提供商：模型覆寫：** 預設情況下，子 Agent 繼承父 Agent 的提供商與模型。設定 `delegation.provider` 與 `delegation.model` 將子 Agent 路由至不同的提供商：模型組合 — 例如，當您的主要 Agent 執行昂貴的推理模型時，為範圍狹窄的子任務使用便宜/快速的模型。

**直接端點覆寫：** 如果您想要明確的自訂端點路徑，請設定 `delegation.base_url`、`delegation.api_key` 與 `delegation.model`。這會將子 Agent 直接發送至該 OpenAI 相容端點，且優先順序高於 `delegation.provider`。如果省略 `delegation.api_key`，Hermes 僅會回退到 `OPENAI_API_KEY`。

委派提供商使用與 CLI/閘道啟動相同的憑證解析方式。支援所有配置的提供商：`openrouter`、`nous`、`copilot`、`zai`、`kimi-coding`、`minimax`、`minimax-cn`。設定提供商時，系統會自動解析正確的基礎 URL、API 金鑰與 API 模式 — 無需手動接線。

**優先順序：** 配置中的 `delegation.base_url` → 配置中的 `delegation.provider` → 父提供商 (繼承)。配置中的 `delegation.model` → 父模型 (繼承)。僅設定 `model` 而不設定 `provider` 只會變更模型名稱，同時保留父代的憑證 (對於在同一個提供商如 OpenRouter 內切換模型很有用)。

## 釐清 (Clarify)

配置釐清提示行為：

```yaml
clarify:
  timeout: 120                 # 等待使用者釐清回應的秒數
```

## 上下文檔案 (SOUL.md, AGENTS.md)

Hermes 使用兩種不同的上下文範圍：

| 檔案 | 用途 | 範圍 |
|------|---------|-------|
| `SOUL.md` | **主要 Agent 身分** — 定義 Agent 是誰 (系統提示詞中的第 1 個插槽) | `~/.hermes/SOUL.md` 或 `$HERMES_HOME/SOUL.md` |
| `.hermes.md` / `HERMES.md` | 專案特定指令 (最高優先權) | 向上搜尋至 git 根目錄 |
| `AGENTS.md` | 專案特定指令、編碼規範 | 遞迴目錄搜尋 |
| `CLAUDE.md` | Claude Code 上下文檔案 (也會偵測) | 僅限工作目錄 |
| `.cursorrules` | Cursor IDE 規則 (也會偵測) | 僅限工作目錄 |
| `.cursor/rules/*.mdc` | Cursor 規則檔案 (也會偵測) | 僅限工作目錄 |

- **SOUL.md** 是 Agent 的主要身分。它佔據系統提示詞中的第 1 個插槽，完全取代內建的預設身分。編輯它以完全自訂 Agent 的身分。
- 如果遺漏 SOUL.md、內容空白或無法載入，Hermes 會回退至內建的預設身分。
- **專案上下文檔案使用優先順序系統** — 僅會載入「一種」類型 (第一個匹配項勝出)：`.hermes.md` → `AGENTS.md` → `CLAUDE.md` → `.cursorrules`。SOUL.md 始終獨立載入。
- **AGENTS.md** 是階層式的：如果子目錄也有 AGENTS.md，則會合併所有內容。
- 如果 `SOUL.md` 不存在，Hermes 會自動產生預設的檔案。
- 所有載入的上下文檔案限制在 20,000 字元，並會進行智慧截斷。

另請參閱：
- [個性與 SOUL.md](/docs/user-guide/features/personality)
- [上下文檔案](/docs/user-guide/features/context-files)

## 工作目錄

| 情境 | 預設值 |
|---------|---------|
| **CLI (`hermes`)** | 執行指令時所在的目前目錄 |
| **訊息閘道** | 首頁目錄 `~` (可以 `MESSAGING_CWD` 覆寫) |
| **Docker / Singularity / Modal / SSH** | 容器或遠端機器內的使用者首頁目錄 |

覆寫工作目錄：
```bash
# 在 ~/.hermes/.env 或 ~/.hermes/config.yaml 中：
MESSAGING_CWD=/home/myuser/projects    # 閘道會話
TERMINAL_CWD=/workspace                # 所有終端機會話
```
