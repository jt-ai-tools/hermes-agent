---
sidebar_position: 8
title: "Mattermost"
description: "將 Hermes Agent 設定為 Mattermost 機器人"
---

# Mattermost 設定

Hermes Agent 可作為機器人與 Mattermost 整合，讓您透過私訊或團隊頻道與您的 AI 助理聊天。Mattermost 是一個自行代管、開源的 Slack 替代方案 — 您可以在自己的基礎架構上運行它，保有對數據的完全控制。機器人透過 Mattermost 的 REST API (v4) 和 WebSocket 連線以獲取即時事件，透過 Hermes Agent 流程（包括工具使用、記憶和推理）處理訊息，並即時回應。它支援文字、檔案附件、圖片和斜線指令。

不需要額外的 Mattermost 函式庫 — 適配器使用 `aiohttp`，這已經是 Hermes 的依賴項。

在設定之前，這裡是大多數人想知道的部分：Hermes 進入您的 Mattermost 實例後的行為。

## Hermes 的行為

| 情境 | 行為 |
|---------|----------|
| **私訊 (DMs)** | Hermes 會回應每條訊息。無需 `@mention`（標記）。每條私訊都有自己的對話階段 (Session)。 |
| **公開/私有頻道** | 當您 `@mention` 它時，Hermes 就會回應。如果沒有標記，Hermes 會忽略該訊息。 |
| **討論串 (Threads)** | 如果 `MATTERMOST_REPLY_MODE=thread`，Hermes 會在您訊息下方的討論串中回覆。討論串上下文與父頻道保持隔離。 |
| **多人共用的頻道** | 預設情況下，Hermes 會在頻道內隔離每個使用者的對話歷史。在同一個頻道中對話的兩個人不會共用同一個紀錄，除非您明確停用該功能。 |

:::tip
如果您希望 Hermes 以討論串形式回覆（巢狀顯示在原始訊息下方），請設定 `MATTERMOST_REPLY_MODE=thread`。預設值為 `off`，會在頻道中傳送一般訊息。
:::

### Mattermost 中的對話模型

預設情況下：

- 每條私訊都有自己的對話階段
- 每個討論串都有自己的對話階段命名空間
- 共用頻道中的每個使用者在該頻道內都有自己的對話階段

這由 `config.yaml` 控制：

```yaml
group_sessions_per_user: true
```

僅當您明確希望整個頻道共用一個對話時，才將其設定為 `false`：

```yaml
group_sessions_per_user: false
```

共用對話對於協作頻道很有用，但也意味著：

- 使用者共用上下文增長和代幣 (Token) 成本
- 一個人長時間的工具密集型任務可能會使其他人的上下文膨脹
- 一個人正在進行的執行可能會中斷頻道中另一個人的後續動作

本指南將引導您完成整個設定過程 — 從在 Mattermost 上建立機器人到傳送您的第一條訊息。

## 步驟 1：啟用機器人帳號

在建立機器人之前，必須先在您的 Mattermost 伺服器上啟用機器人帳號功能。

1. 以**系統管理員 (System Admin)** 身分登入 Mattermost。
2. 前往 **系統主控台 (System Console)** → **整合 (Integrations)** → **機器人帳號 (Bot Accounts)**。
3. 將 **啟用機器人帳號建立 (Enable Bot Account Creation)** 設定為 **true**。
4. 點擊 **儲存 (Save)**。

:::info
如果您沒有系統管理員權限，請請您的 Mattermost 管理員啟用機器人帳號並為您建立一個。
:::

## 步驟 2：建立機器人帳號

1. 在 Mattermost 中，點擊 **☰** 選單（左上角）→ **整合 (Integrations)** → **機器人帳號 (Bot Accounts)**。
2. 點擊 **新增機器人帳號 (Add Bot Account)**。
3. 填寫詳細資料：
   - **使用者名稱 (Username)**：例如 `hermes`
   - **顯示名稱 (Display Name)**：例如 `Hermes Agent`
   - **描述 (Description)**：選填
   - **角色 (Role)**：`成員 (Member)` 即可
4. 點擊 **建立機器人帳號 (Create Bot Account)**。
5. Mattermost 將顯示 **機器人權杖 (Bot Token)**。**請立即複製它。**

:::warning[權杖僅顯示一次]
機器人權杖僅在您建立帳號時顯示一次。如果您遺失了它，則需要從機器人帳號設定中重新產生。切勿公開分享您的權杖或將其提交到 Git — 擁有此權杖的人可以完全控制該機器人。
:::

將權杖儲存在安全的地方（例如密碼管理員）。您在步驟 5 中會需要它。

:::tip
您也可以使用**個人存取權杖 (Personal Access Token)** 代替機器人帳號。前往 **個人資料 (Profile)** → **安全性 (Security)** → **個人存取權杖 (Personal Access Tokens)** → **建立權杖 (Create Token)**。如果您希望 Hermes 以您自己的使用者身份發文，這會很有用。
:::

## 步驟 3：將機器人加入頻道

機器人需要成為頻道成員才能在該頻道回應：

1. 開啟您希望機器人加入的頻道。
2. 點擊頻道名稱 → **新增成員 (Add Members)**。
3. 搜尋您的機器人使用者名稱（例如 `hermes`）並加入。

對於私訊，只需開啟與機器人的對話 — 它即可立即回應。

## 步驟 4：尋找您的 Mattermost 使用者 ID

Hermes Agent 使用您的 Mattermost 使用者 ID 來控制誰可以與機器人互動。尋找方法如下：

1. 點擊您的**頭像**（左上角）→ **個人資料 (Profile)**。
2. 使用者 ID 會顯示在個人資料對話框中 — 點擊即可複製。

您的使用者 ID 是一個 26 位元的英數字串，例如 `3uo8dkh1p7g1mfk49ear5fzs5c`。

:::warning
使用者 ID **不等於**您的使用者名稱。使用者名稱是 `@` 之後顯示的內容（例如 `@alice`）。使用者 ID 是 Mattermost 內部使用的長字串識別碼。
:::

**替代方案**：您也可以透過 API 獲取使用者 ID：

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://您的-mattermost-伺服器/api/v4/users/me | jq .id
```

:::tip
獲取**頻道 ID** 的方法：點擊頻道名稱 → **檢視資訊 (View Info)**。頻道 ID 會顯示在資訊面板中。如果您想手動設定主頻道，會需要此 ID。
:::

## 步驟 4：設定 Hermes Agent

### 選項 A：互動式設定（推薦）

執行引導式設定指令：

```bash
hermes gateway setup
```

出現提示時選擇 **Mattermost**，然後貼上您的伺服器 URL、機器人權杖和使用者 ID。

### 選項 B：手動設定

將以下內容新增到您的 `~/.hermes/.env` 檔案中：

```bash
# 必要
MATTERMOST_URL=https://mm.example.com
MATTERMOST_TOKEN=***
MATTERMOST_ALLOWED_USERS=3uo8dkh1p7g1mfk49ear5fzs5c

# 多個允許的使用者（以逗號分隔）
# MATTERMOST_ALLOWED_USERS=3uo8dkh1p7g1mfk49ear5fzs5c,8fk2jd9s0a7bncm1xqw4tp6r3e

# 選填：回覆模式（thread 或 off，預設值：off）
# MATTERMOST_REPLY_MODE=thread

# 選填：無需 @mention 即可回應（預設值：true = 需要標記）
# MATTERMOST_REQUIRE_MENTION=false

# 選填：機器人無需標記即可回應的頻道（以逗號分隔的頻道 ID）
# MATTERMOST_FREE_RESPONSE_CHANNELS=channel_id_1,channel_id_2
```

`~/.hermes/config.yaml` 中的選填行為設定：

```yaml
group_sessions_per_user: true
```

- `group_sessions_per_user: true` 可保持共用頻道和討論串中每個參與者的上下文隔離。

### 啟動網關

設定完成後，啟動 Mattermost 網關：

```bash
hermes gateway
```

機器人應該會在幾秒鐘內連線到您的 Mattermost 伺服器。傳送一條訊息給它 — 可以是私訊，也可以是在已加入的頻道中 — 進行測試。

:::tip
您可以讓 `hermes gateway` 在背景運行，或將其作為 systemd 服務運行以實現持久操作。詳情請參閱部署文件。
:::

## 主頻道 (Home Channel)

您可以指定一個「主頻道」，機器人會在該頻道傳送主動訊息（如 Cron 任務輸出、提醒和通知）。有兩種設定方法：

### 使用斜線指令

在機器人所在的任何 Mattermost 頻道中輸入 `/sethome`。該頻道即成為主頻道。

### 手動設定

在您的 `~/.hermes/.env` 中新增：

```bash
MATTERMOST_HOME_CHANNEL=abc123def456ghi789jkl012mn
```

將 ID 替換為實際的頻道 ID（點擊頻道名稱 → 檢視資訊 → 複製 ID）。

## 回覆模式

`MATTERMOST_REPLY_MODE` 設定控制 Hermes 如何發布回應：

| 模式 | 行為 |
|------|----------|
| `off` (預設) | Hermes 在頻道中發布一般訊息，就像普通使用者一樣。 |
| `thread` | Hermes 在您原始訊息下方的討論串中回覆。當有大量往返對話時，可以保持頻道整潔。 |

在您的 `~/.hermes/.env` 中設定：

```bash
MATTERMOST_REPLY_MODE=thread
```

## 標記行為

預設情況下，機器人僅在頻道中被 `@mentioned` 時才會回應。您可以更改此設定：

| 變數 | 預設值 | 描述 |
|----------|---------|-------------|
| `MATTERMOST_REQUIRE_MENTION` | `true` | 設為 `false` 以回應頻道中的所有訊息（私訊始終有效）。 |
| `MATTERMOST_FREE_RESPONSE_CHANNELS` | _(無)_ | 以逗號分隔的頻道 ID。在這些頻道中，即使 require_mention 為 true，機器人也無需標記即可回應。 |

要在 Mattermost 中尋找頻道 ID：開啟頻道，點擊標題中的頻道名稱，並在 URL 或頻道詳細資料中尋找 ID。

當機器人被 `@mentioned` 時，在處理之前會自動從訊息中清除該標記。

## 疑難排解

### 機器人未回應訊息

**原因**：機器人不是該頻道的成員，或者 `MATTERMOST_ALLOWED_USERS` 未包含您的使用者 ID。

**修復**：將機器人加入頻道（頻道名稱 → 新增成員 → 搜尋機器人）。驗證您的使用者 ID 是否在 `MATTERMOST_ALLOWED_USERS` 中。重啟網關。

### 403 Forbidden 錯誤

**原因**：機器人權杖無效，或者機器人沒有在該頻道發文的權限。

**修復**：檢查 `.env` 檔案中的 `MATTERMOST_TOKEN` 是否正確。確保機器人帳號未被停用。驗證機器人已被加入頻道。如果使用個人存取權杖，請確保您的帳號具有所需權限。

### WebSocket 斷開連線 / 重新連線迴圈

**原因**：網路不穩定、Mattermost 伺服器重啟或防火牆/代理伺服器的 WebSocket 連線問題。

**修復**：適配器會以指數退避 (2s → 60s) 自動重新連線。檢查伺服器的 WebSocket 設定 — 反向代理（Nginx, Apache）需要設定 WebSocket 升級標頭。驗證沒有防火牆阻擋 Mattermost 伺服器上的 WebSocket 連線。

對於 Nginx，請確保您的設定包含：

```nginx
location /api/v4/websocket {
    proxy_pass http://mattermost-backend;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_read_timeout 600s;
}
```

### 啟動時「身分驗證失敗」

**原因**：權杖或伺服器 URL 錯誤。

**修復**：驗證 `MATTERMOST_URL` 指向您的伺服器（包含 `https://`，結尾無斜槓）。檢查權杖是否有效 — 使用 curl 測試：

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://您的-伺服器/api/v4/users/me
```

### 機器人離線

**原因**：Hermes 網關未運行，或連線失敗。

**修復**：檢查 `hermes gateway` 是否正在運行。查看終端輸出。常見問題：URL 錯誤、權杖過期、伺服器無法連線。

### 「使用者未獲授權」 / 機器人忽略您

**原因**：您的使用者 ID 不在 `MATTERMOST_ALLOWED_USERS` 中。

**修復**：在 `~/.hermes/.env` 中新增您的使用者 ID。請記住：使用者 ID 是一個 26 位元的英數字串，不是您的 `@username`。

## 個別頻道提示詞

為特定的 Mattermost 頻道分配臨時系統提示詞。該提示詞會在每次執行時注入 — 永遠不會持久化到歷史紀錄中 — 因此更改會立即生效。

```yaml
mattermost:
  channel_prompts:
    "channel_id_abc123": |
      你是一位研究助理。專注於學術來源、引用和簡潔的總結。
    "channel_id_def456": |
      程式碼審查模式。對邊緣情況和效能影響保持精確。
```

鍵值為 Mattermost 頻道 ID。匹配頻道中的所有訊息都將被注入該提示詞作為臨時系統指令。

## 安全性

:::warning
務必設定 `MATTERMOST_ALLOWED_USERS` 以限制誰可以與機器人互動。如果未設定，作為一項安全措施，網關預設會拒絕所有使用者。僅新增您信任的人的使用者 ID — 授權使用者擁有存取代理能力的完全權限，包括工具使用和系統存取。
:::

有關保護 Hermes Agent 部署的更多資訊，請參閱 [安全性指南](../security.md)。

## 附註

- **對自行代管友善**：支援任何自行代管的 Mattermost 實例。不需要 Mattermost Cloud 帳號或訂閱。
- **無額外依賴**：適配器使用 `aiohttp` 處理 HTTP 和 WebSocket，這已包含在 Hermes Agent 中。
- **支援 Team Edition**：同時支援 Mattermost Team Edition（免費版）和 Enterprise Edition。
