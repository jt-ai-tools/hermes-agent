---
sidebar_position: 9
title: "Matrix"
description: "將 Hermes Agent 設定為 Matrix 機器人"
---

# Matrix 設定

Hermes Agent 與開放且聯邦化的通訊協定 Matrix 整合。Matrix 讓您可以運行自己的家庭伺服器 (homeserver) 或使用 matrix.org 等公開伺服器 — 無論哪種方式，您都能保有對通訊內容的控制權。機器人透過 `mautrix` Python SDK 連線，透過 Hermes Agent 流程（包括工具使用、記憶和推理）處理訊息，並即時回應。它支援文字、檔案附件、圖片、音訊、影片以及選填的端對端加密 (E2EE)。

Hermes 適用於任何 Matrix 家庭伺服器 — Synapse、Conduit、Dendrite 或 matrix.org。

在設定之前，這裡是大多數人想知道的部分：Hermes 連線後的行為。

## Hermes 的行為

| 情境 | 行為 |
|---------|----------|
| **私訊 (DMs)** | Hermes 會回應每條訊息。無需 `@mention`（標記）。每條私訊都有自己的對話階段 (Session)。設定 `MATRIX_DM_MENTION_THREADS=true` 可以在私訊中標記機器人時啟動一個討論串。 |
| **聊天室 (Rooms)** | 預設情況下，Hermes 需要被 `@mention` 才會回應。設定 `MATRIX_REQUIRE_MENTION=false` 或將聊天室 ID 新增至 `MATRIX_FREE_RESPONSE_ROOMS` 可將其設為自由回應聊天室。聊天室邀請會被自動接受。 |
| **討論串 (Threads)** | Hermes 支援 Matrix 討論串 (MSC3440)。如果您在討論串中回覆，Hermes 會使討論串上下文與主聊天室時間軸保持隔離。機器人已參與的討論串不需要再次標記。 |
| **自動建立討論串** | 預設情況下，Hermes 會在聊天室中為其回應的每條訊息自動建立一個討論串。這能使對話保持隔離。設定 `MATRIX_AUTO_THREAD=false` 可停用此功能。 |
| **多人共用的聊天室** | 預設情況下，Hermes 會在聊天室內隔離每個使用者的對話歷史。在同一個聊天室中對話的兩個人不會共用同一個紀錄，除非您明確停用該功能。 |

:::tip
機器人會在受邀時自動加入聊天室。只需將機器人的 Matrix 使用者邀請至任何聊天室，它就會加入並開始回應。
:::

### Matrix 中的對話模型

預設情況下：

- 每條私訊都有自己的對話階段
- 每個討論串都有自己的對話階段命名空間
- 共用聊天室中的每個使用者在該聊天室內都有自己的對話階段

這由 `config.yaml` 控制：

```yaml
group_sessions_per_user: true
```

僅當您明確希望整個聊天室共用一個對話時，才將其設定為 `false`：

```yaml
group_sessions_per_user: false
```

共用對話對於協作聊天室很有用，但也意味著：

- 使用者共用上下文增長和代幣 (Token) 成本
- 一個人長時間的工具密集型任務可能會使其他人的上下文膨脹
- 一個人正在進行的執行可能會中斷聊天室中另一個人的後續動作

### 標記與討論串設定

您可以透過環境變數或 `config.yaml` 設定標記與自動建立討論串的行為：

```yaml
matrix:
  require_mention: true           # 在聊天室中要求 @mention（預設值：true）
  free_response_rooms:            # 無需標記即可回應的聊天室
    - "!abc123:matrix.org"
  auto_thread: true               # 為回應自動建立討論串（預設值：true）
  dm_mention_threads: false       # 在私訊中被標記時建立討論串（預設值：false）
```

或者透過環境變數：

```bash
MATRIX_REQUIRE_MENTION=true
MATRIX_FREE_RESPONSE_ROOMS=!abc123:matrix.org,!def456:matrix.org
MATRIX_AUTO_THREAD=true
MATRIX_DM_MENTION_THREADS=false
```

:::note
如果您是從沒有 `MATRIX_REQUIRE_MENTION` 的版本升級，機器人之前會回應聊天室中的所有訊息。若要保留該行為，請設定 `MATRIX_REQUIRE_MENTION=false`。
:::

本指南將引導您完成整個設定過程 — 從建立機器人帳號到傳送您的第一條訊息。

## 步驟 1：建立機器人帳號

您需要一個機器人的 Matrix 使用者帳號。有幾種方式：

### 選項 A：在您的家庭伺服器上註冊（推薦）

如果您運行自己的家庭伺服器 (Synapse, Conduit, Dendrite)：

1. 使用管理員 API 或註冊工具建立一個新使用者：

```bash
# Synapse 範例
register_new_matrix_user -c /etc/synapse/homeserver.yaml http://localhost:8008
```

2. 選擇一個使用者名稱如 `hermes` — 完整的使用者 ID 將是 `@hermes:your-server.org`。

### 選項 B：使用 matrix.org 或其他公開家庭伺服器

1. 前往 [Element Web](https://app.element.io) 並建立一個新帳號。
2. 為您的機器人選一個使用者名稱（例如 `hermes-bot`）。

### 選項 C：使用您自己的帳號

您也可以將 Hermes 作為您自己的使用者來運行。這意味著機器人會以您的名義發文 — 對於個人助理很有用。

## 步驟 2：獲取存取權杖 (Access Token)

Hermes 需要存取權杖才能向家庭伺服器進行身分驗證。您有兩個選擇：

### 選項 A：存取權杖（推薦）

獲取權杖最可靠的方法：

**透過 Element：**
1. 使用機器人帳號登入 [Element](https://app.element.io)。
2. 前往 **Settings** → **Help & About**。
3. 向下捲動並展開 **Advanced** — 存取權杖會顯示在那裡。
4. **立即複製它。**

**透過 API：**

```bash
curl -X POST https://your-server/_matrix/client/v3/login \
  -H "Content-Type: application/json" \
  -d '{
    "type": "m.login.password",
    "user": "@hermes:your-server.org",
    "password": "your-password"
  }'
```

回應會包含一個 `access_token` 欄位 — 複製它。

:::warning[請妥善保管您的存取權杖]
存取權杖擁有對機器人 Matrix 帳號的完全存取權。切勿公開分享或將其提交到 Git。如果洩漏，請透過登出該使用者的所有對話階段來撤銷它。
:::

### 選項 B：密碼登入

除了提供存取權杖外，您也可以提供 Hermes 機器人的使用者 ID 和密碼。Hermes 會在啟動時自動登入。這比較簡單，但意味著密碼會儲存在您的 `.env` 檔案中。

```bash
MATRIX_USER_ID=@hermes:your-server.org
MATRIX_PASSWORD=your-password
```

## 步驟 3：尋找您的 Matrix 使用者 ID

Hermes Agent 使用您的 Matrix 使用者 ID 來控制誰可以與機器人互動。Matrix 使用者 ID 遵循 `@username:server` 格式。

尋找您 ID 的方法：

1. 開啟 [Element](https://app.element.io)（或您偏好的 Matrix 用戶端）。
2. 點擊您的頭像 → **Settings**。
3. 您的使用者 ID 顯示在個人資料頂部（例如 `@alice:matrix.org`）。

:::tip
Matrix 使用者 ID 始終以 `@` 開頭，並包含一個 `:`，後接伺服器名稱。例如：`@alice:matrix.org`、`@bob:your-server.com`。
:::

## 步驟 4：設定 Hermes Agent

### 選項 A：互動式設定（推薦）

執行引導式設定指令：

```bash
hermes gateway setup
```

出現提示時選擇 **Matrix**，然後根據要求提供您的家庭伺服器 URL、存取權杖（或使用者 ID + 密碼）以及允許的使用者 ID。

### 選項 B：手動設定

將以下內容新增到您的 `~/.hermes/.env` 檔案中：

**使用存取權杖：**

```bash
# 必要
MATRIX_HOMESERVER=https://matrix.example.org
MATRIX_ACCESS_TOKEN=***

# 選填：使用者 ID（若省略則從權杖自動偵測）
# MATRIX_USER_ID=@hermes:matrix.example.org

# 安全性：限制誰可以與機器人互動
MATRIX_ALLOWED_USERS=@alice:matrix.example.org

# 多個允許的使用者（以逗號分隔）
# MATRIX_ALLOWED_USERS=@alice:matrix.example.org,@bob:matrix.example.org
```

**使用密碼登入：**

```bash
# 必要
MATRIX_HOMESERVER=https://matrix.example.org
MATRIX_USER_ID=@hermes:matrix.example.org
MATRIX_PASSWORD=***

# 安全性
MATRIX_ALLOWED_USERS=@alice:matrix.example.org
```

`~/.hermes/config.yaml` 中的選填行為設定：

```yaml
group_sessions_per_user: true
```

- `group_sessions_per_user: true` 可保持共用聊天室中每個參與者的上下文隔離。

### 啟動網關

設定完成後，啟動 Matrix 網關：

```bash
hermes gateway
```

機器人應該會在幾秒鐘內連線到您的家庭伺服器並開始同步。傳送一條訊息給它 — 可以是私訊，也可以是在它已加入的聊天室中 — 進行測試。

:::tip
您可以讓 `hermes gateway` 在背景運行，或將其作為 systemd 服務運行以實現持久操作。詳情請參閱部署文件。
:::

## 端對端加密 (E2EE)

Hermes 支援 Matrix 端對端加密，因此您可以在加密聊天室中與您的機器人聊天。

### 需求

E2EE 需要帶有加密擴充功能的 `mautrix` 函式庫以及 `libolm` C 函式庫：

```bash
# 安裝具備 E2EE 支援的 mautrix
pip install 'mautrix[encryption]'

# 或使用 hermes 擴充功能安裝
pip install 'hermes-agent[matrix]'
```

您還需要在系統上安裝 `libolm`：

```bash
# Debian/Ubuntu
sudo apt install libolm-dev

# macOS
brew install libolm

# Fedora
sudo dnf install libolm-devel
```

### 啟用 E2EE

在您的 `~/.hermes/.env` 中新增：

```bash
MATRIX_ENCRYPTION=true
```

啟用 E2EE 後，Hermes 會：

- 將加密金鑰儲存在 `~/.hermes/platforms/matrix/store/`（舊版安裝位於 `~/.hermes/matrix/store/`）
- 在首次連線時上傳裝置金鑰
- 自動解密傳入訊息並加密傳出訊息
- 在受邀時自動加入加密聊天室

### 交叉簽名驗證 (Cross-Signing Verification)（推薦）

如果您的 Matrix 帳號啟用了交叉簽名（Element 中的預設設定），請設定復原金鑰，以便機器人在啟動時可以自我簽名其裝置。如果不設定此項，其他 Matrix 用戶端可能會在裝置金鑰輪換後拒絕與機器人共用加密對話階段。

```bash
MATRIX_RECOVERY_KEY=EsT... 您的復原金鑰在此
```

**在哪裡找到它：** 在 Element 中，前往 **Settings** → **Security & Privacy** → **Encryption** → 您的復原金鑰（也稱為「安全金鑰」）。這是您首次設定交叉簽名時被要求儲存的金鑰。

在每次啟動時，如果設定了 `MATRIX_RECOVERY_KEY`，Hermes 會從家庭伺服器的安全秘密儲存空間匯入交叉簽名金鑰，並對當前裝置進行簽名。這是等冪的，永久啟用是安全的。

:::warning
如果您刪除 `~/.hermes/platforms/matrix/store/` 目錄，機器人將丟失其加密金鑰。您需要在 Matrix 用戶端中再次驗證該裝置。如果您想保留加密對話階段，請備份此目錄。
:::

:::info
如果未安裝 `mautrix[encryption]` 或缺少 `libolm`，機器人將自動回退到純文字（未加密）用戶端。您會在日誌中看到警告。
:::

## 主聊天室 (Home Room)

您可以指定一個「主聊天室」，機器人會在該聊天室傳送主動訊息（如 Cron 任務輸出、提醒和通知）。有兩種設定方法：

### 使用斜線指令

在機器人所在的任何 Matrix 聊天室中輸入 `/sethome`。該聊天室即成為主聊天室。

### 手動設定

在您的 `~/.hermes/.env` 中新增：

```bash
MATRIX_HOME_ROOM=!abc123def456:matrix.example.org
```

:::tip
尋找聊天室 ID 的方法：在 Element 中，前往該聊天室 → **Settings** → **Advanced** → 顯示在那裡的 **Internal room ID**（以 `!` 開頭）。
:::

## 疑難排解

### 機器人未回應訊息

**原因**：機器人尚未加入聊天室，或者 `MATRIX_ALLOWED_USERS` 未包含您的使用者 ID。

**修復**：邀請機器人加入聊天室 — 它會在受邀時自動加入。驗證您的使用者 ID 是否在 `MATRIX_ALLOWED_USERS` 中（使用完整的 `@user:server` 格式）。重啟網關。

### 啟動時「驗證失敗 (Failed to authenticate)」 / 「whoami failed」

**原因**：存取權杖或家庭伺服器 URL 錯誤。

**修復**：驗證 `MATRIX_HOMESERVER` 指向您的家庭伺服器（包含 `https://`，結尾無斜槓）。檢查 `MATRIX_ACCESS_TOKEN` 是否有效 — 使用 curl 測試：

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://your-server/_matrix/client/v3/account/whoami
```

如果這傳回您的使用者資訊，則權杖有效。如果傳回錯誤，請產生新權杖。

### 「mautrix 未安裝」錯誤

**原因**：未安裝 `mautrix` Python 套件。

**修復**：安裝它：

```bash
pip install 'mautrix[encryption]'
```

或使用 Hermes 擴充功能：

```bash
pip install 'hermes-agent[matrix]'
```

### 加密錯誤 / 「could not decrypt event」

**原因**：缺少加密金鑰、未安裝 `libolm` 或機器人裝置未被信任。

**修復**：
1. 驗證系統上已安裝 `libolm`（見上方的 E2EE 區段）。
2. 確保 `.env` 中設定了 `MATRIX_ENCRYPTION=true`。
3. 在您的 Matrix 用戶端 (Element) 中，前往機器人的個人資料 -> Sessions -> 驗證/信任機器人的裝置。
4. 如果機器人剛加入加密聊天室，它只能解密加入*之後*傳送的訊息。之前的訊息無法存取。

### 從具有 E2EE 的舊版本升級

如果您之前在 `MATRIX_ENCRYPTION=true` 的情況下使用 Hermes，並正在升級到使用新的基於 SQLite 的加密儲存空間的版本，則機器人的加密身分已更改。您的 Matrix 用戶端 (Element) 可能會快取舊的裝置金鑰，並拒絕與機器人共用加密對話階段。

**症狀**：機器人已連線且日誌中顯示「E2EE enabled」，但所有訊息都顯示「could not decrypt event」且機器人從不回應。

**解決方案**（一次性遷移）：

1. **產生新的存取權杖**以獲得新的裝置 ID。最簡單的方法：

   ```bash
   curl -X POST https://your-server/_matrix/client/v3/login \
     -H "Content-Type: application/json" \
     -d '{
       "type": "m.login.password",
       "identifier": {"type": "m.id.user", "user": "@hermes:your-server.org"},
       "password": "***",
       "initial_device_display_name": "Hermes Agent"
     }'
   ```

   複製新的 `access_token` 並更新 `~/.hermes/.env` 中的 `MATRIX_ACCESS_TOKEN`。

2. **刪除舊的加密狀態**：

   ```bash
   rm -f ~/.hermes/platforms/matrix/store/crypto.db
   rm -f ~/.hermes/platforms/matrix/store/crypto_store.*
   ```

3. **設定您的復原金鑰**（如果您使用交叉簽名 — 大多數 Element 使用者都有使用）。在 `~/.hermes/.env` 中新增：

   ```bash
   MATRIX_RECOVERY_KEY=EsT... 您的復原金鑰在此
   ```

   這讓機器人在啟動時可以使用交叉簽名金鑰自我簽名，因此 Element 會立即信任新裝置。

4. **強制您的 Matrix 用戶端輪換加密對話階段**。在 Element 中，開啟與機器人的私訊聊天室並輸入 `/discardsession`。這會強制 Element 建立新的加密對話階段並與機器人的新裝置共用。

5. **重啟網關**：

   ```bash
   hermes gateway run
   ```

   如果設定了 `MATRIX_RECOVERY_KEY`，您應該會在日誌中看到 `Matrix: cross-signing verified via recovery key`。

6. **傳送一條新訊息**。機器人應該可以解密並正常回應。

:::note
遷移後，升級*之前*傳送的訊息無法解密 — 舊的加密金鑰已消失。這僅影響過渡期；新訊息將正常運作。
:::

:::tip
**新安裝不受影響。** 僅當您之前使用 Hermes 舊版本已設定好 E2EE 且正在升級時才需要此遷移。
:::

## 代理模式 (Proxy Mode)（macOS 上的 E2EE）

Matrix E2EE 需要 `libolm`，它在 macOS ARM64 (Apple Silicon) 上無法編譯。`hermes-agent[matrix]` 擴充功能僅限於 Linux。如果您在 macOS 上，代理模式讓您可以在 Linux VM 的 Docker 容器中運行 E2EE，而實際的代理則原生運行在 macOS 上，並具備對本地檔案、記憶和技能的完全存取權。

### 運作原理

```
macOS (主機):
  └─ hermes gateway
       ├─ api_server adapter ← 監聽 0.0.0.0:8642
       ├─ AIAgent ← 單一事實來源
       ├─ 對話階段、記憶、技能
       └─ 本地檔案存取 (Obsidian, 專案等)

Linux VM (Docker):
  └─ hermes gateway (代理模式)
       ├─ Matrix adapter ← E2EE 解密/加密
       └─ HTTP 轉發 → macOS:8642/v1/chat/completions
           (無 LLM API 權杖, 無代理, 無推理)
```

Docker 容器僅處理 Matrix 協定 + E2EE。當訊息到達時，它會解密並透過標準 HTTP 請求將文字轉發到主機。主機運行代理、呼叫工具、產生回應並串流回傳。容器加密並將回應傳送至 Matrix。所有對話階段都是統一的 — CLI、Matrix、Telegram 和任何其他平台共用相同的記憶和對話歷史。

### 步驟 1：設定主機 (macOS)

啟用 API 伺服器，以便主機接受來自 Docker 容器的傳入請求。

在 `~/.hermes/.env` 中新增：

```bash
API_SERVER_ENABLED=true
API_SERVER_KEY=您的秘密金鑰在此
API_SERVER_HOST=0.0.0.0
```

- `API_SERVER_HOST=0.0.0.0` 繫結到所有介面，以便 Docker 容器可以存取它。
- `API_SERVER_KEY` 是非迴圈 (non-loopback) 繫結所必需的。請選取一個強大的隨機字串。
- API 伺服器預設運行在連接埠 8642。

啟動網關：

```bash
hermes gateway
```

### 步驟 2：設定 Docker 容器 (Linux VM)

容器需要 Matrix 憑據和代理 URL。它**不需要** LLM API 權杖。

**`docker-compose.yml`：**

```yaml
services:
  hermes-matrix:
    build: .
    environment:
      # Matrix 憑據
      MATRIX_HOMESERVER: "https://matrix.example.org"
      MATRIX_ACCESS_TOKEN: "syt_..."
      MATRIX_ALLOWED_USERS: "@you:matrix.example.org"
      MATRIX_ENCRYPTION: "true"
      MATRIX_DEVICE_ID: "HERMES_BOT"

      # 代理模式 — 轉發到主機代理
      GATEWAY_PROXY_URL: "http://192.168.1.100:8642"
      GATEWAY_PROXY_KEY: "您的秘密金鑰在此"
    volumes:
      - ./matrix-store:/root/.hermes/platforms/matrix/store
```

**`Dockerfile`：**

```dockerfile
FROM python:3.11-slim

RUN apt-get update && apt-get install -y libolm-dev && rm -rf /var/lib/apt/lists/*
RUN pip install 'hermes-agent[matrix]'

CMD ["hermes", "gateway"]
```

### 步驟 3：啟動兩者

1. 首先啟動主機網關：
   ```bash
   hermes gateway
   ```

2. 啟動 Docker 容器：
   ```bash
   docker compose up -d
   ```

3. 在加密的 Matrix 聊天室中傳送訊息。容器會解密訊息、轉發到主機，並將回應串流回傳。

### 設定參考資料

代理模式是在 **容器端**（輕量網關）設定的：

| 設定 | 描述 |
|---------|-------------|
| `GATEWAY_PROXY_URL` | 遠端 Hermes API 伺服器的 URL (例如 `http://192.168.1.100:8642`) |
| `GATEWAY_PROXY_KEY` | 用於身分驗證的 Bearer 權杖（必須與主機上的 `API_SERVER_KEY` 匹配） |

主機端需要：

| 設定 | 描述 |
|---------|-------------|
| `API_SERVER_ENABLED` | 設定為 `true` |
| `API_SERVER_KEY` | Bearer 權杖（與容器共用） |
| `API_SERVER_HOST` | 設定為 `0.0.0.0` 以開放網路存取 |
| `API_SERVER_PORT` | 連接埠號碼（預設值：`8642`） |

### 適用於任何平台

代理模式不限於 Matrix。任何平台適配器都可以使用它 — 在任何網關實例上設定 `GATEWAY_PROXY_URL`，它就會轉發到遠端代理而不是在本地運行。這對於平台適配器需要在與代理不同的環境中運行的任何部署都很有用。

:::tip
對話階段連續性透過 `X-Hermes-Session-Id` 標頭維持。主機的 API 伺服器透過此 ID 追蹤對話。
:::

### 同步問題 / 機器人落後

**原因**：長時間運行的工具執行可能會延遲同步迴圈，或者家庭伺服器速度慢。

**修復**：同步迴圈會在出錯時每 5 秒自動重試一次。檢查 Hermes 日誌中與同步相關的警告。如果機器人持續落後，請確保您的家庭伺服器有足夠的資源。

### 機器人離線

**原因**：Hermes 網關未運行，或連線失敗。

**修復**：檢查 `hermes gateway` 是否正在運行。查看終端輸出以獲取錯誤訊息。

### 「使用者未獲授權」 / 機器人忽略您

**原因**：您的使用者 ID 不在 `MATRIX_ALLOWED_USERS` 中。

**修復**：在 `~/.hermes/.env` 中將您的使用者 ID 新增至 `MATRIX_ALLOWED_USERS` 並重啟網關。請使用完整的 `@user:server` 格式。

## 安全性

:::warning
務必設定 `MATRIX_ALLOWED_USERS` 以限制誰可以與機器人互動。如果未設定，作為一項安全措施，網關預設會拒絕所有使用者。僅新增您信任的人的使用者 ID — 授權使用者擁有存取代理能力的完全權限，包括工具使用和系統存取。
:::

有關保護 Hermes Agent 部署的更多資訊，請參閱 [安全性指南](../security.md)。

## 附註

- **任何家庭伺服器**：支援 Synapse、Conduit、Dendrite、matrix.org 或任何符合規範的 Matrix 家庭伺服器。
- **聯邦化**：如果您在聯邦化的家庭伺服器上，機器人可以與來自其他伺服器的使用者通訊 — 只需將他們完整的 `@user:server` ID 新增至 `MATRIX_ALLOWED_USERS`。
- **自動加入**：機器人會自動接受聊天室邀請並加入。加入後立即開始回應。
- **媒體支援**：Hermes 可以傳送和接收圖片、音訊、影片和檔案附件。
- **原生語音訊息 (MSC3245)**：Matrix 適配器會自動將傳出的語音訊息標記為 `org.matrix.msc3245.voice` 旗標。這意味著 TTS 回應和語音音訊在 Element 和其他支援 MSC3245 的用戶端中將呈現為**原生語音氣泡**，而非一般的音訊檔案附件。帶有 MSC3245 旗標的傳入語音訊息也會被正確識別並路由至語音轉文字轉錄。此功能是自動執行的，無需設定。
