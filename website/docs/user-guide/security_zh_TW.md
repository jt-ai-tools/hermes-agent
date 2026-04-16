---
sidebar_position: 8
title: "安全性"
description: "安全性模型、危險指令批准、使用者授權、容器隔離以及生產環境部署最佳實踐"
---

# 安全性

Hermes Agent 採用深度防禦 (Defense-in-depth) 安全性模型設計。本頁面涵蓋了每一個安全性邊界 — 從指令批准、容器隔離到通訊平台上的使用者授權。

## 概覽

安全性模型包含七個層級：

1. **使用者授權** — 誰可以與 Agent 對話 (允許清單、私訊配對)
2. **危險指令批准** — 對於具破壞性的操作進行人工介入核可
3. **容器隔離** — 使用經過安全強化的 Docker/Singularity/Modal 沙盒設定
4. **MCP 憑證過濾** — 為 MCP 子程序提供環境變數隔離
5. **上下文檔案掃描** — 偵測專案檔案中的提示詞注入 (Prompt injection)
6. **跨會話隔離** — 會話之間無法存取彼此的資料或狀態；cron 工作儲存路徑經過強化以防禦路徑走訪 (Path traversal) 攻擊
7. **輸入過濾** — 終端機工具後端的工作目錄參數會針對允許清單進行驗證，以防止 Shell 注入 (Shell injection)

## 危險指令批准 (Dangerous Command Approval)

在執行任何指令之前，Hermes 會針對一份精選的危險模式清單進行檢查。如果發現匹配項，使用者必須明確核可該指令。

### 批准模式

批准系統支援三種模式，可透過 `~/.hermes/config.yaml` 中的 `approvals.mode` 進行配置：

```yaml
approvals:
  mode: manual    # manual | smart | off
  timeout: 60     # 等待使用者回應的秒數 (預設：60)
```

| 模式 | 行為 |
|------|----------|
| **manual** (預設) | 執行危險指令時，始終提示使用者進行批准 |
| **smart** | 使用輔助 LLM 評估風險。低風險指令 (例如 `python -c "print('hello')"`) 會自動批准。真正危險的指令會自動拒絕。不確定的情況則轉為人工提示。 |
| **off** | 停用所有批准檢查 — 等同於使用 `--yolo` 執行。所有指令無需提示即可執行。 |

:::warning
將 `approvals.mode` 設為 `off` 會停用所有安全提示。請僅在受信任的環境 (CI/CD、容器等) 中使用。
:::

### YOLO 模式

YOLO 模式會為目前會話跳過**所有**危險指令批准提示。可以透過三種方式啟動：

1. **CLI 標記**：以 `hermes --yolo` 或 `hermes chat --yolo` 開始會話
2. **斜線指令**：在會話期間輸入 `/yolo` 以切換開啟/關閉
3. **環境變數**：設定 `HERMES_YOLO_MODE=1`

`/yolo` 指令是一個**切換開關** — 每次使用都會切換模式：

```
> /yolo
  ⚡ YOLO 模式已開啟 — 所有指令將自動批准。請謹慎使用。

> /yolo
  ⚠ YOLO 模式已關閉 — 危險指令將需要手動批准。
```

YOLO 模式在 CLI 與閘道會話中皆可用。在內部，它會設定 `HERMES_YOLO_MODE` 環境變數，並在每次指令執行前進行檢查。

:::danger
YOLO 模式會停用會話中**所有**危險指令的安全檢查。請僅在您完全信任產生的指令時使用 (例如，在拋棄式環境中執行經過充分測試的自動化指令碼)。
:::

### 批准逾時

當出現危險指令提示時，使用者有可配置的時間進行回應。如果未在逾時內給出回應，指令預設會被**拒絕** (失敗關閉，Fail-closed)。

在 `~/.hermes/config.yaml` 中配置逾時時間：

```yaml
approvals:
  timeout: 60  # 秒 (預設：60)
```

### 觸發批准的因素

以下模式會觸發批准提示 (定義於 `tools/approval.py`)：

| 模式 | 描述 |
|---------|-------------|
| `rm -r` / `rm --recursive` | 遞迴刪除 |
| `rm ... /` | 在根路徑刪除 |
| `chmod 777/666` / `o+w` / `a+w` | 全域/其他使用者可寫入權限 |
| 具不安全權限的 `chmod --recursive` | 遞迴全域/其他使用者可寫入 (完整標記) |
| `chown -R root` / `chown --recursive root` | 遞迴 chown 至 root |
| `mkfs` | 格式化檔案系統 |
| `dd if=` | 磁碟複製 |
| `> /dev/sd` | 寫入區塊裝置 |
| `DROP TABLE/DATABASE` | SQL DROP 指令 |
| `DELETE FROM` (無 WHERE) | 無 WHERE 條件的 SQL DELETE |
| `TRUNCATE TABLE` | SQL TRUNCATE 指令 |
| `> /etc/` | 覆寫系統配置 |
| `systemctl stop/disable/mask` | 停止/停用系統服務 |
| `kill -9 -1` | 終止所有程序 |
| `pkill -9` | 強制終止程序 |
| Fork bomb 模式 | 分叉炸彈 (Fork bombs) |
| `bash -c` / `sh -c` / `zsh -c` / `ksh -c` | 透過 `-c` 標記執行 Shell 指令 (包括合併標記如 `-lc`) |
| `python -e` / `perl -e` / `ruby -e` / `node -c` | 透過 `-e`/`-c` 標記執行指令碼 |
| `curl ... \| sh` / `wget ... \| sh` | 將遠端內容透過管道傳送至 Shell |
| `bash <(curl ...)` / `sh <(wget ...)` | 透過程序替換執行遠端指令碼 |
| `tee` 到 `/etc/`, `~/.ssh/`, `~/.hermes/.env` | 透過 tee 覆寫敏感檔案 |
| `>` / `>>` 到 `/etc/`, `~/.ssh/`, `~/.hermes/.env` | 透過重導向覆寫敏感檔案 |
| `xargs rm` | 結合 xargs 與 rm |
| `find -exec rm` / `find -delete` | 結合 find 與破壞性動作 |
| `cp`/`mv`/`install` 到 `/etc/` | 複製/移動檔案至系統配置目錄 |
| `sed -i` / `sed --in-place` 於 `/etc/` | 原地編輯系統配置 |
| `pkill`/`killall` hermes/gateway | 防止自我終止 |
| 帶有 `&`/`disown`/`nohup`/`setsid` 的 `gateway run` | 防止在服務管理員外啟動閘道 |

:::info
**容器繞過**：當使用 `docker`、`singularity`、`modal` 或 `daytona` 後端執行時，會**跳過**危險指令檢查，因為容器本身就是安全性邊界。容器內的破壞性指令不會損害主機。
:::

### 批准流程 (CLI)

在互動式 CLI 中，危險指令會顯示行內批准提示：

```
  ⚠️  危險指令：遞迴刪除
      rm -rf /tmp/old-project

      [o]單次  |  [s]會話  |  [a]一律  |  [d]拒絕

      選擇 [o/s/a/D]:
```

四個選項：

- **once (單次)** — 允許此次單次執行
- **session (會話)** — 在此會話的其餘部分允許此模式
- **always (一律)** — 加入永久允許清單 (儲存至 `config.yaml`)
- **deny (拒絕)** (預設) — 封鎖該指令

### 批准流程 (閘道/通訊軟體)

在通訊平台上，Agent 會將危險指令詳情發送到聊天室並等待使用者回覆：

- 回覆 **yes**、**y**、**approve**、**ok** 或 **go** 以批准
- 回覆 **no**、**n**、**deny** 或 **cancel** 以拒絕

執行閘道時，會自動設定 `HERMES_EXEC_ASK=1` 環境變數。

### 永久允許清單

以「一律 (always)」批准的指令會儲存至 `~/.hermes/config.yaml`：

```yaml
# 永久允許的危險指令模式
command_allowlist:
  - rm
  - systemctl
```

這些模式會在啟動時載入，並在未來的所有會話中靜默批准。

:::tip
使用 `hermes config edit` 檢視或移除永久允許清單中的模式。
:::

## 使用者授權 (閘道)

執行訊息閘道時，Hermes 透過分層授權系統控制誰可以與機器人互動。

### 授權檢查順序

`_is_user_authorized()` 方法依此順序檢查：

1. **各平台全開標記** (例如 `DISCORD_ALLOW_ALL_USERS=true`)
2. **私訊配對核可清單** (透過配對碼核可的使用者)
3. **平台特定允許清單** (例如 `TELEGRAM_ALLOWED_USERS=12345,67890`)
4. **全域允許清單** (`GATEWAY_ALLOWED_USERS=12345,67890`)
5. **全域全開標記** (`GATEWAY_ALLOW_ALL_USERS=true`)
6. **預設：拒絕**

### 平台允許清單

在 `~/.hermes/.env` 中設定以逗號分隔的使用者 ID：

```bash
# 平台特定允許清單
TELEGRAM_ALLOWED_USERS=123456789,987654321
DISCORD_ALLOWED_USERS=111222333444555666
WHATSAPP_ALLOWED_USERS=15551234567
SLACK_ALLOWED_USERS=U01ABC123

# 跨平台允許清單 (適用於所有平台)
GATEWAY_ALLOWED_USERS=123456789

# 各平台全開 (請謹慎使用)
DISCORD_ALLOW_ALL_USERS=true

# 全域全開 (請極度謹慎使用)
GATEWAY_ALLOW_ALL_USERS=true
```

:::warning
如果**未配置任何允許清單**且未設定 `GATEWAY_ALLOW_ALL_USERS`，**所有使用者都將被拒絕**。閘道會在啟動時記錄警告：

```
未配置使用者允許清單。所有未授權的使用者都將被拒絕。
請在 ~/.hermes/.env 中設定 GATEWAY_ALLOW_ALL_USERS=true 以開放存取，
或配置平台允許清單 (例如 TELEGRAM_ALLOWED_USERS=您的ID)。
```
:::

### 私訊配對系統 (DM Pairing System)

為了提供更靈活的授權，Hermes 包含一個基於代碼的配對系統。無需事先要求使用者 ID，未知使用者會收到一個單次配對碼，機器人擁有者可透過 CLI 進行批准。

**運作方式：**

1. 未知使用者向機器人發送私訊
2. 機器人回覆一個 8 字元的配對碼
3. 機器人擁有者在 CLI 執行 `hermes pairing approve <platform> <code>`
4. 該使用者即在該平台上獲得永久授權

在 `~/.hermes/config.yaml` 中控制如何處理未授權的私訊：

```yaml
unauthorized_dm_behavior: pair

whatsapp:
  unauthorized_dm_behavior: ignore
```

- `pair` 是預設值。未授權的私訊會收到配對碼回覆。
- `ignore` 會靜默丟棄未授權的私訊。
- 平台區段會覆寫全域預設值，因此您可以讓 Telegram 保持配對功能，同時讓 WhatsApp 保持靜默。

**安全性功能** (基於 OWASP + NIST SP 800-63-4 指引)：

| 功能 | 詳情 |
|---------|---------|
| 代碼格式 | 8 字元，取自 32 字元無歧義字母表 (無 0/O/1/I) |
| 隨機性 | 加密級別 (`secrets.choice()`) |
| 代碼 TTL | 1 小時過期 |
| 速率限制 | 每個使用者每 10 分鐘 1 次請求 |
| 待處理限制 | 每個平台最多 3 個待處理代碼 |
| 鎖定 | 5 次失敗的批准嘗試 → 1 小時鎖定 |
| 檔案安全性 | 對所有配對資料檔案執行 `chmod 0600` |
| 日誌紀錄 | 代碼絕不會記錄到標準輸出 |

**配對 CLI 指令：**

```bash
# 列出待處理與已核可的使用者
hermes pairing list

# 批准配對碼
hermes pairing approve telegram ABC12DEF

# 撤銷使用者存取權
hermes pairing revoke telegram 123456789

# 清除所有待處理代碼
hermes pairing clear-pending
```

**儲存位置：** 配對資料儲存在 `~/.hermes/pairing/` 中，包含各平台的 JSON 檔案：
- `{platform}-pending.json` — 待處理的配對請求
- `{platform}-approved.json` — 已核可的使用者
- `_rate_limits.json` — 速率限制與鎖定追蹤

## 容器隔離

使用 `docker` 終端機後端時，Hermes 會對每個容器套用嚴格的安全強化。

### Docker 安全性標記

每個容器都以這些標記執行 (定義於 `tools/environments/docker.py`)：

```python
_SECURITY_ARGS = [
    "--cap-drop", "ALL",                          # 刪除所有 Linux 能力
    "--cap-add", "DAC_OVERRIDE",                  # Root 可以寫入繫結掛載目錄
    "--cap-add", "CHOWN",                         # 套件管理員需要檔案擁有權
    "--cap-add", "FOWNER",                        # 套件管理員需要檔案擁有權
    "--security-opt", "no-new-privileges",         # 封鎖權限提升
    "--pids-limit", "256",                         # 限制程序數量
    "--tmpfs", "/tmp:rw,nosuid,size=512m",         # 限制大小的 /tmp
    "--tmpfs", "/var/tmp:rw,noexec,nosuid,size=256m",  # 不可執行的 /var/tmp
    "--tmpfs", "/run:rw,noexec,nosuid,size=64m",   # 不可執行的 /run
]
```

### 資源限制

容器資源可在 `~/.hermes/config.yaml` 中配置：

```yaml
terminal:
  backend: docker
  docker_image: "nikolaik/python-nodejs:python3.11-nodejs20"
  docker_forward_env: []  # 僅限明確的允許清單；留空以保持祕密不進入容器
  container_cpu: 1        # CPU 核心
  container_memory: 5120  # MB (預設 5GB)
  container_disk: 51200   # MB (預設 50GB，需要 XFS 上的 overlay2)
  container_persistent: true  # 跨會話保留檔案系統
```

### 檔案系統持久性

- **持久模式** (`container_persistent: true`)：將 `/workspace` 與 `/root` 從 `~/.hermes/sandboxes/docker/<task_id>/` 繫結掛載
- **臨時模式** (`container_persistent: false`)：為工作區使用 tmpfs — 清理時所有內容都會遺失

:::tip
對於生產環境的閘道部署，請使用 `docker`、`modal` 或 `daytona` 後端，將 Agent 指令與您的主機系統隔離。這可以完全消除對危險指令批准的需求。
:::

:::warning
如果您將名稱加入 `terminal.docker_forward_env`，這些變數會被刻意注入到容器中供終端機指令使用。這對於 `GITHUB_TOKEN` 等任務特定憑證很有用，但也意味著在容器中執行的程式碼可以讀取並外洩這些資訊。
:::

## 終端機後端安全性比較

| 後端 | 隔離性 | 危險指令檢查 | 最佳用途 |
|---------|-----------|-------------------|----------|
| **local** | 無 — 直接在主機執行 | ✅ 是 | 開發、受信任的使用者 |
| **ssh** | 遠端機器 | ✅ 是 | 在獨立伺服器上執行 |
| **docker** | 容器 | ❌ 跳過 (容器即邊界) | 生產環境閘道 |
| **singularity** | 容器 | ❌ 跳過 | HPC 環境 |
| **modal** | 雲端沙盒 | ❌ 跳過 | 可擴展的雲端隔離 |
| **daytona** | 雲端沙盒 | ❌ 跳過 | 持久雲端工作區 |

## 環境變數轉發 (Passthrough) {#environment-variable-passthrough}

`execute_code` 與 `terminal` 都會從子程序中移除敏感的環境變數，以防止 LLM 產生的程式碼外洩憑證。然而，宣告 `required_environment_variables` 的技能確實需要存取這些變數。

### 運作方式

有兩種機制允許特定變數通過沙盒過濾器：

**1. 技能範圍轉發 (自動)**

當技能被載入 (透過 `skill_view` 或 `/skill` 指令) 且宣告了 `required_environment_variables` 時，環境中實際設定的任何變數都會自動註冊為轉發。遺漏的變數 (仍處於需要設定的狀態) 則**不**會註冊。

```yaml
# 在技能的 SKILL.md 前言中
required_environment_variables:
  - name: TENOR_API_KEY
    prompt: Tenor API 金鑰
    help: 從 https://developers.google.com/tenor 取得金鑰
```

載入此技能後，`TENOR_API_KEY` 就會通過 `execute_code`、`terminal` (本地) **以及遠端後端 (Docker, Modal)** — 無需手動配置。

:::info Docker 與 Modal
在 v0.5.1 之前，Docker 的 `forward_env` 是與技能轉發獨立的系統。它們現在已合併 — 技能宣告的環境變數會自動轉發到 Docker 容器與 Modal 沙盒中，無需手動加入 `docker_forward_env`。
:::

**2. 基於配置的轉發 (手動)**

對於未由任何技能宣告的環境變數，請將其加入 `config.yaml` 中的 `terminal.env_passthrough`：

```yaml
terminal:
  env_passthrough:
    - MY_CUSTOM_KEY
    - ANOTHER_TOKEN
```

### 憑證檔案轉發 (OAuth Token 等) {#credential-file-passthrough}

某些技能在沙盒中需要**檔案** (而不僅是環境變數) — 例如，Google Workspace 將 OAuth Token 儲存為作用中 Profile 的 `HERMES_HOME` 下的 `google_token.json`。技能在前言中宣告這些：

```yaml
required_credential_files:
  - path: google_token.json
    description: Google OAuth2 token (由設定指令碼建立)
  - path: google_client_secret.json
    description: Google OAuth2 使用端祕密
```

載入時，Hermes 會檢查這些檔案是否存在於作用中 Profile 的 `HERMES_HOME` 中，並將其註冊為掛載對象：

- **Docker**：唯讀繫結掛載 (`-v host:container:ro`)
- **Modal**：在沙盒建立時掛載 + 每個指令執行前同步 (處理會話中的 OAuth 設定)
- **Local**：無需動作 (檔案已可存取)

您也可以在 `config.yaml` 中手動列出憑證檔案：

```yaml
terminal:
  credential_files:
    - google_token.json
    - my_custom_oauth_token.json
```

路徑相對於 `~/.hermes/`。檔案會掛載到容器內的 `/root/.hermes/`。

### 每個沙盒過濾的內容

| 沙盒 | 預設過濾器 | 轉發 (Passthrough) 覆寫 |
|---------|---------------|---------------------|
| **execute_code** | 封鎖名稱中包含 `KEY`、`TOKEN`、`SECRET`、`PASSWORD`、`CREDENTIAL`、`PASSWD`、`AUTH` 的變數；僅允許具安全前置詞的變數通過 | ✅ 轉發變數會繞過這兩項檢查 |
| **terminal** (本地) | 封鎖明確的 Hermes 基礎建設變數 (提供商金鑰、閘道 Token、工具 API 金鑰) | ✅ 轉發變數會繞過封鎖清單 |
| **terminal** (Docker) | 預設不繼承主機環境變數 | ✅ 轉發變數 + `docker_forward_env` 透過 `-e` 轉發 |
| **terminal** (Modal) | 預設無主機環境/檔案 | ✅ 憑證檔案已掛載；環境變數透過同步轉發 |
| **MCP** | 封鎖除安全系統變數與明確配置的 `env` 以外的一切 | ❌ 不受轉發影響 (請改用 MCP `env` 配置) |

### 安全性考量

- 轉發僅影響您或您的技能明確宣告的變數 — 對於任意 LLM 產生的程式碼，預設的安全性立場不變
- 憑證檔案是以**唯讀**方式掛載到 Docker 容器中
- Skills Guard 會在安裝前掃描技能內容，尋找可疑的環境變數存取模式
- 遺漏/未設定的變數絕不會被註冊 (您無法流失不存在的東西)
- Hermes 基礎建設祕密 (提供商 API 金鑰、閘道 Token) 絕不應加入 `env_passthrough` — 它們有專屬的機制

## MCP 憑證處理

MCP (模型上下文協定) 伺服器子程序會收到**過濾後的環境**，以防止意外流失憑證。

### 安全環境變數

僅這些變數會從主機傳遞至 MCP stdio 子程序：

```
PATH, HOME, USER, LANG, LC_ALL, TERM, SHELL, TMPDIR
```

加上任何 `XDG_*` 變數。所有其他環境變數 (API 金鑰、Token、祕密) 都會被**移除**。

在 MCP 伺服器的 `env` 配置中明確定義的變數會被傳遞：

```yaml
mcp_servers:
  github:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: "ghp_..."  # 僅此變數會被傳遞
```

### 憑證遮蔽 (Redaction)

來自 MCP 工具的錯誤訊息會在回傳給 LLM 前進行過濾。以下模式會被替換為 `[REDACTED]`：

- GitHub PATs (`ghp_...`)
- OpenAI 風格的金鑰 (`sk-...`)
- Bearer token
- `token=`、`key=`、`API_KEY=`、`password=`、`secret=` 等參數

### 網頁存取原則

您可以限制 Agent 透過其網頁與瀏覽器工具存取的網站。這對於防止 Agent 存取內部服務、管理面板或其他敏感 URL 很有用。

```yaml
# 於 ~/.hermes/config.yaml 中
security:
  website_blocklist:
    enabled: true
    domains:
      - "*.internal.company.com"
      - "admin.example.com"
    shared_files:
      - "/etc/hermes/blocked-sites.txt"
```

當請求被封鎖的 URL 時，工具會回傳錯誤，說明該網域因政策而被封鎖。此封鎖清單在 `web_search`、`web_extract`、`browser_navigate` 及所有具 URL 存取能力的工具中皆生效。

詳情請參閱配置指南中的 [網頁封鎖清單](/docs/user-guide/configuration#website-blocklist)。

### SSRF 防護

所有具 URL 存取能力的工具 (網頁搜尋、網頁擷取、Vision、瀏覽器) 在抓取 URL 前都會進行驗證，以防止伺服器端請求偽造 (SSRF) 攻擊。封鎖的位址包括：

- **私有網路** (RFC 1918)：`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`
- **本地迴圈 (Loopback)**：`127.0.0.0/8`, `::1`
- **連結本地 (Link-local)**：`169.254.0.0/16` (包括位於 `169.254.169.254` 的雲端詮釋資料)
- **CGNAT / 共享位址空間** (RFC 6598)：`100.64.0.0/10` (Tailscale, WireGuard VPN)
- **雲端詮釋資料主機名稱**：`metadata.google.internal`, `metadata.goog`
- **保留、群播及未指定位址**

SSRF 防護始終處於啟動狀態且無法停用。DNS 失敗會被視為封鎖 (失敗關閉)。重導向鏈會在每一跳 (Hop) 重新驗證，以防止透過重導向繞過。

### Tirith 執行前安全性掃描

Hermes 整合了 [tirith](https://github.com/sheeki03/tirith)，用於在執行前對指令進行內容級別的掃描。Tirith 可偵測僅靠模式匹配會遺漏的威脅：

- 同形異義 (Homograph) URL 偽造攻擊 (國際化網域攻擊)
- 管道傳送至直譯器模式 (`curl | bash`, `wget | sh`)
- 終端機注入攻擊

Tirith 會在第一次使用時自動從 GitHub releases 安裝，並進行 SHA-256 校驗和驗證 (若 cosign 可用，還會進行 cosign 出處驗證)。

```yaml
# 於 ~/.hermes/config.yaml 中
security:
  tirith_enabled: true       # 啟用/停用 tirith 掃描 (預設：true)
  tirith_path: "tirith"      # tirith 執行檔路徑 (預設：PATH 查找)
  tirith_timeout: 5          # 子程序逾時秒數
  tirith_fail_open: true     # 若 tirith 不可用，允許執行 (預設：true)
```

當 `tirith_fail_open` 為 `true` (預設) 時，若未安裝 tirith 或掃描逾時，指令會繼續執行。在高度安全的環境中，請將其設為 `false`，以便在 tirith 無法驗證時封鎖指令。

Tirith 的判定會整合到批准流程中：安全指令會直接通過，而可疑與被封鎖的指令則會觸發使用者批准，並顯示完整的 tirith 發現結果 (嚴重性、標題、描述、更安全的替代方案)。使用者可以批准或拒絕 — 在無人看管的場景中，預設選擇為拒絕以保持安全。

### 上下文檔案注入防護

上下文檔案 (AGENTS.md, .cursorrules, SOUL.md) 在加入系統提示詞前會進行提示詞注入掃描。掃描器檢查：

- 忽略/無視先前指令的指示
- 帶有可疑關鍵字的隱藏 HTML 註釋
- 企圖讀取祕密 (`.env`, `credentials`, `.netrc`)
- 透過 `curl` 進行憑證外洩
- 不可見的 Unicode 字元 (零寬度空格、雙向覆寫)

被封鎖的檔案會顯示警告：

```
[BLOCKED: AGENTS.md contained potential prompt injection (prompt_injection). Content not loaded.]
```

## 生產環境部署最佳實踐

### 閘道部署檢查清單

1. **設定明確的允許清單** — 在生產環境中絕不要使用 `GATEWAY_ALLOW_ALL_USERS=true`
2. **使用容器後端** — 在 config.yaml 中設定 `terminal.backend: docker`
3. **限制資源上限** — 設定適當的 CPU、記憶體與磁碟限制
4. **安全地儲存祕密** — 將 API 金鑰放在 `~/.hermes/.env` 並設定正確的檔案權限
5. **啟用私訊配對** — 盡可能使用配對碼而非硬編碼使用者 ID
6. **審核指令允許清單** — 定期審查 config.yaml 中的 `command_allowlist`
7. **設定 `MESSAGING_CWD`** — 不要讓 Agent 在敏感目錄中運作
8. **以非 root 使用者執行** — 絕不要以 root 權限執行閘道
9. **監控日誌** — 檢查 `~/.hermes/logs/` 中的未經授權存取嘗試
10. **保持更新** — 定期執行 `hermes update` 以取得安全性修正程式

### 保護 API 金鑰

```bash
# 為 .env 檔案設定正確權限
chmod 600 ~/.hermes/.env

# 為不同的服務保留獨立的金鑰
# 絕不要將 .env 檔案提交至版本控制系統
```

### 網路隔離

為了達到最大安全性，請在獨立的機器或 VM 上執行閘道：

```yaml
terminal:
  backend: ssh
  ssh_host: "agent-worker.local"
  ssh_user: "hermes"
  ssh_key: "~/.ssh/hermes_agent_key"
```

這能讓閘道的訊息連線與 Agent 的指令執行保持隔離。
