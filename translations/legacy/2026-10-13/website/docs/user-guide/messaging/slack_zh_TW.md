---
sidebar_position: 4
title: "Slack"
description: "使用通訊端模式將 Hermes Agent 設定為 Slack 機器人"
---

# Slack 設定

使用通訊端模式 (Socket Mode) 將 Hermes Agent 作為機器人連接到 Slack。通訊端模式使用 WebSocket 而非公開的 HTTP 端點，因此您的 Hermes 實例不需要公開存取權 —— 它可以運作在防火牆後、您的筆記型電腦或私有伺服器上。

:::warning 經典版 Slack 應用程式已廢棄
經典版 Slack 應用程式（使用 RTM API）已於 **2025 年 3 月完全廢棄**。Hermes 使用現代化的 Bolt SDK 搭配通訊端模式。如果您有舊的經典版應用程式，則必須按照以下步驟建立一個新的應用程式。
:::

## 概述

| 組件 | 數值 |
|-----------|-------|
| **函式庫** | 適用於 Python 的 `slack-bolt` / `slack_sdk` (通訊端模式) |
| **連線方式** | WebSocket — 不需要公開網址 |
| **所需驗證權杖** | 機器人權杖 (`xoxb-`) + 應用程式層級權杖 (`xapp-`) |
| **使用者識別** | Slack 成員識別碼 (例如 `U01ABC2DEF3`) |

---

## 步驟 1：建立 Slack 應用程式

1. 前往 [https://api.slack.com/apps](https://api.slack.com/apps)
2. 點擊 **Create New App**
3. 選擇 **From scratch**
4. 輸入應用程式名稱（例如 "Hermes Agent"）並選擇您的工作區
5. 點擊 **Create App**

您將進入應用程式的 **Basic Information** 頁面。

---

## 步驟 2：設定機器人權杖範圍 (Scopes)

在側邊欄中導覽至 **Features → OAuth & Permissions**。向下捲動到 **Scopes → Bot Token Scopes** 並新增以下範圍：

| 範圍 (Scope) | 用途 |
|-------|---------|
| `chat:write` | 以機器人身份發送訊息 |
| `app_mentions:read` | 偵測在頻道中被 @標註 的時刻 |
| `channels:history` | 讀取機器人所在公開頻道的訊息 |
| `channels:read` | 列出並獲取公開頻道的資訊 |
| `groups:history` | 讀取機器人受邀加入之私有頻道的訊息 |
| `im:history` | 讀取私訊歷史記錄 |
| `im:read` | 查看基本的私訊資訊 |
| `im:write` | 開啟並管理私訊 |
| `users:read` | 查詢使用者資訊 |
| `files:read` | 讀取並下載附件，包括語音訊息/音訊 |
| `files:write` | 上傳檔案（圖片、音訊、文件） |

:::caution 缺失範圍 = 功能缺失
若沒有 `channels:history` 和 `groups:history`，機器人**將無法接收頻道中的訊息** —— 它將只能在私訊中運作。這些是最常被遺漏的範圍。
:::

**選填範圍：**

| 範圍 (Scope) | 用途 |
|-------|---------|
| `groups:read` | 列出並獲取私有頻道的資訊 |

---

## 步驟 3：啟用通訊端模式 (Socket Mode)

通訊端模式讓機器人透過 WebSocket 連線，而不需要公開網址。

1. 在側邊欄中，前往 **Settings → Socket Mode**
2. 將 **Enable Socket Mode** 切換為 ON
3. 系統會提示您建立一個 **App-Level Token (應用程式層級權杖)**：
   - 將其命名為 `hermes-socket` 之類的名稱（名稱不拘）
   - 新增 **`connections:write`** 範圍
   - 點擊 **Generate**
4. **複製權杖** —— 它以 `xapp-` 開頭。這就是您的 `SLACK_APP_TOKEN`

:::tip
您隨時可以在 **Settings → Basic Information → App-Level Tokens** 下找到或重新產生應用程式層級權杖。
:::

---

## 步驟 4：訂閱事件 (Event Subscriptions)

此步驟至關重要 —— 它控制機器人能看到哪些訊息。

1. 在側邊欄中，前往 **Features → Event Subscriptions**
2. 將 **Enable Events** 切換為 ON
3. 展開 **Subscribe to bot events** 並新增：

| 事件 | 必填？ | 用途 |
|-------|-----------|---------|
| `message.im` | **是** | 機器人接收私訊 |
| `message.channels` | **是** | 機器人接收其所在**公開**頻道的訊息 |
| `message.groups` | **推薦** | 機器人接收其受邀加入之**私有**頻道的訊息 |
| `app_mention` | **是** | 防止機器人被 @標註 時 Bolt SDK 發生錯誤 |

4. 點擊頁面底部的 **Save Changes**

:::danger 遺漏事件訂閱是設定中最常見的問題
如果機器人在私訊中正常運作，但在**頻道中無反應**，您幾乎可以肯定忘記新增了 `message.channels`（公開頻道）及/或 `message.groups`（私有頻道）。若沒有這些事件，Slack 根本不會將頻道訊息傳送給機器人。
:::

---

## 步驟 5：啟用訊息標籤頁 (Messages Tab)

此步驟啟用了對機器人的私訊功能。若未啟用，使用者嘗試私訊機器人時會看到 **"Sending messages to this app has been turned off"**（已關閉向此應用程式發送訊息的功能）。

1. 在側邊欄中，前往 **Features → App Home**
2. 向下捲動至 **Show Tabs**
3. 將 **Messages Tab** 切換為 ON
4. 勾選 **"Allow users to send Slash commands and messages from the messages tab"**（允許使用者從訊息標籤頁發送斜線指令和訊息）

:::danger 若不執行此步驟，私訊將被完全阻斷
即使設定了正確的範圍和事件訂閱，除非啟用了訊息標籤頁，否則 Slack 不會允許使用者向機器人發送私訊。這是 Slack 平台的規範，而非 Hermes 的設定問題。
:::

---

## 步驟 6：安裝應用程式至工作區

1. 在側邊欄中，前往 **Settings → Install App**
2. 點擊 **Install to Workspace**
3. 檢查權限並點擊 **Allow**
4. 授權後，您將看到以 `xoxb-` 開頭的 **Bot User OAuth Token**
5. **複製此權杖** —— 這就是您的 `SLACK_BOT_TOKEN`

:::tip
如果您稍後更改了範圍或事件訂閱，則**必須重新安裝應用程式**才能使更改生效。Install App 頁面會顯示橫幅提示您執行此操作。
:::

---

## 步驟 7：尋找白名單的使用者 ID

Hermes 使用 Slack **成員識別碼 (Member ID)**（而非使用者名稱或顯示名稱）來設定白名單。

尋找成員識別碼的方法：

1. 在 Slack 中，點擊使用者的名稱或頭像
2. 點擊 **View full profile** (查看完整個人檔案)
3. 點擊 **⋮** (更多) 按鈕
4. 選擇 **Copy member ID** (複製成員識別碼)

成員識別碼看起來像 `U01ABC2DEF3`。您至少需要自己的成員識別碼。

---

## 步驟 8：設定 Hermes

將以下內容加入您的 `~/.hermes/.env` 檔案中：

```bash
# 必填
SLACK_BOT_TOKEN=xoxb-your-bot-token-here
SLACK_APP_TOKEN=xapp-your-app-token-here
SLACK_ALLOWED_USERS=U01ABC2DEF3              # 以逗號分隔的成員識別碼

# 選填
SLACK_HOME_CHANNEL=C01234567890              # 用於排程任務/預定訊息的預設頻道
SLACK_HOME_CHANNEL_NAME=general              # 主頻道的易讀名稱 (選填)
```

或者執行互動式設定：

```bash
hermes gateway setup    # 提示時選擇 Slack
```

然後啟動閘道：

```bash
hermes gateway              # 前景執行
hermes gateway install      # 安裝為使用者服務
sudo hermes gateway install --system   # 僅限 Linux：開機啟動的系統服務
```

---

## 步驟 9：邀請機器人進入頻道

啟動閘道後，您需要將**機器人邀請進**任何您希望它回應的頻道：

```
/invite @Hermes Agent
```

機器人**不會**自動加入頻道。您必須個別邀請它進入每個頻道。

---

## 機器人如何回應

了解 Hermes 在不同情境下的行為：

| 情境 | 行為 |
|---------|----------|
| **私訊 (DM)** | 機器人會回應每一則訊息 —— 不需要 @標註 |
| **頻道** | 機器人**僅在被 @標註 時回應**（例如 `@Hermes Agent 現在幾點？`）。在頻道中，Hermes 會在附加於該訊息的討論串 (thread) 中回覆。 |
| **討論串** | 如果您在現有的討論串中 @標註 Hermes，它會在同一個討論串中回覆。一旦機器人在某個討論串中建立了活躍對話，**該討論串後續的回覆就不再需要 @標註** —— 機器人會自然地跟進對話。 |

:::tip
在頻道中，請務必使用 @標註 機器人來開始對話。一旦機器人在討論串中開始活動，您就可以在該討論串中直接回覆而無需標註它。在討論串之外，沒有 @標註 的訊息會被忽略，以防止在繁忙的頻道中造成干擾。
:::

---

## 設定選項

除了步驟 8 中要求的環境變數外，您還可以透過 `~/.hermes/config.yaml` 自訂 Slack 機器人的行為。

### 討論串與回覆行為

```yaml
platforms:
  slack:
    # 控制多部分回應如何組成討論串
    # "off"   — 永不將回覆與原始訊息組成討論串
    # "first" — 第一個區塊與使用者訊息組成討論串 (預設)
    # "all"   — 所有區塊都與使用者訊息組成討論串
    reply_to_mode: "first"

    extra:
      # 是否在討論串中回覆 (預設: true)。
      # 設為 false 時，頻道訊息將直接在頻道中回覆而非討論串。
      # 現有討論串內的訊息仍會在討論串內回覆。
      reply_in_thread: true

      # 同時將討論串回覆發佈到主頻道
      # (Slack 的 "Also send to channel" 功能)。
      # 僅第一個回覆的第一個區塊會被廣播。
      reply_broadcast: false
```

| 鍵名 | 預設值 | 描述 |
|-----|---------|-------------|
| `platforms.slack.reply_to_mode` | `"first"` | 多部分訊息的討論串模式：`"off"`、`"first"` 或 `"all"` |
| `platforms.slack.extra.reply_in_thread` | `true` | 為 `false` 時，頻道訊息將直接回覆而非組成討論串。現有討論串內的訊息不受影響。 |
| `platforms.slack.extra.reply_broadcast` | `false` | 為 `true` 時，討論串回覆也會發佈到主頻道。僅廣播第一個區塊。 |

### 工作階段隔離

```yaml
# 全域設定 — 適用於 Slack 及所有其他平台
group_sessions_per_user: true
```

設為 `true`（預設值）時，共享頻道中的每個使用者都擁有自己獨立的對話工作階段。兩個人在 `#general` 頻道與 Hermes 交談時，將擁有各自的歷史記錄和上下文。

如果您希望使用協作模式，讓整個頻道共享同一個對話工作階段，請將其設為 `false`。請注意，這意味著使用者將共同承擔上下文增長和權杖成本，且任何一位使用者的 `/reset` 都會清除所有人的工作階段。

### 標註與觸發行為

```yaml
slack:
  # 在頻道中是否需要 @標註 (這是預設行為；
  # Slack 適配器無論如何都會在頻道中強制執行 @標註 限制，
  # 但您可以明確設定此項以保持與其他平台的一致性)
  require_mention: true

  # 觸發機器人的自訂標註模式
  # (除了預設的 @標註 偵測外)
  mention_patterns:
    - "hey hermes"
    - "hermes,"

  # 附加在每則傳出訊息前的文字
  reply_prefix: ""
```

:::info
與 Discord 和 Telegram 不同，Slack 沒有對等的 `free_response_channels` 功能。Slack 適配器要求使用 `@標註` 來開始頻道中的對話。然而，一旦機器人在討論串中建立了活躍對話，後續的討論串回覆就不再需要標註。在私訊中，機器人始終會在不需標註的情況下回應。
:::

### 未授權使用者的處理

```yaml
slack:
  # 當未授權使用者 (不在 SLACK_ALLOWED_USERS 中) 私訊機器人時的行為
  # "pair"   — 提示他們輸入配對代碼 (預設)
  # "ignore" — 靜默忽略訊息
  unauthorized_dm_behavior: "pair"
```

您也可以為所有平台進行全域設定：

```yaml
unauthorized_dm_behavior: "pair"
```

`slack:` 下的平台特定設定優先於全域設定。

### 語音轉文字

```yaml
# 全域設定 — 啟用/停用傳入語音訊息的自動轉錄
stt_enabled: true
```

設為 `true`（預設值）時，傳入的音訊訊息在由代理程式處理前，會自動使用設定的 STT 提供者進行轉錄。

### 完整範例

```yaml
# 全域閘道設定
group_sessions_per_user: true
unauthorized_dm_behavior: "pair"
stt_enabled: true

# Slack 特定設定
slack:
  require_mention: true
  unauthorized_dm_behavior: "pair"

# 平台配置
platforms:
  slack:
    reply_to_mode: "first"
    extra:
      reply_in_thread: true
      reply_broadcast: false
```

---

## 主頻道

將 `SLACK_HOME_CHANNEL` 設定為一個頻道 ID，Hermes 將在那裡發送排程訊息、cron 任務結果以及其他主動通知。尋找頻道 ID 的方法：

1. 在 Slack 中右鍵點擊頻道名稱
2. 點擊 **View channel details**
3. 向下捲動到底部 —— 頻道 ID (Channel ID) 會顯示在那裡

```bash
SLACK_HOME_CHANNEL=C01234567890
```

請確保已將機器人**邀請進該頻道** (`/invite @Hermes Agent`)。

---

## 多工作區支援

Hermes 可以使用單個閘道實例同時連接到**多個 Slack 工作區**。每個工作區都使用其專屬的機器人使用者 ID 獨立進行驗證。

### 設定方式

在 `SLACK_BOT_TOKEN` 中提供多個以**逗號分隔**的機器人權杖：

```bash
# 多個機器人權杖 — 每個工作區一個
SLACK_BOT_TOKEN=xoxb-workspace1-token,xoxb-workspace2-token,xoxb-workspace3-token

# 通訊端模式仍僅使用單個應用程式層級權杖
SLACK_APP_TOKEN=xapp-your-app-token
```

或者在 `~/.hermes/config.yaml` 中設定：

```yaml
platforms:
  slack:
    token: "xoxb-workspace1-token,xoxb-workspace2-token"
```

### OAuth 權杖檔案

除了環境變數或設定檔中的權杖外，Hermes 還會從以下路徑的 **OAuth 權杖檔案**載入權杖：

```
~/.hermes/slack_tokens.json
```

此檔案是一個 JSON 物件，將團隊 ID 映射到權杖條目：

```json
{
  "T01ABC2DEF3": {
    "token": "xoxb-workspace-token-here",
    "team_name": "My Workspace"
  }
}
```

此檔案中的權杖會與透過 `SLACK_BOT_TOKEN` 指定的權杖合併。重複的權杖會被自動去重。

### 運作原理

- 列表中的**第一個權杖**為主要權杖，用於通訊端模式連線 (AsyncApp)。
- 啟動時會透過 `auth.test` 驗證每個權杖。閘道會將每個 `team_id` 映射到其專屬的 `WebClient` 和 `bot_user_id`。
- 當訊息到達時，Hermes 會使用正確的工作區專屬客戶端進行回應。
- 主要 `bot_user_id`（來自第一個權杖）用於向後相容那些預期單一機器人身份的功能。

---

## 語音訊息

Hermes 在 Slack 上支援語音功能：

- **傳入：** 語音/音訊訊息會自動使用設定的 STT 提供者進行轉錄：本地 `faster-whisper`、Groq Whisper (`GROQ_API_KEY`) 或 OpenAI Whisper (`VOICE_TOOLS_OPENAI_KEY`)。
- **傳出：** TTS 回應會作為音訊檔案附件發送。

---

## 針對個別頻道的提示 (Prompts)

為特定的 Slack 頻道分配臨時的系統提示。提示會在每一回合執行時注入 —— 永不持久化到對話歷史中 —— 因此更改會立即生效。

```yaml
slack:
  channel_prompts:
    "C01RESEARCH": |
      你是一位研究助理。請專注於學術來源、
      引用以及簡潔的綜合分析。
    "C02ENGINEERING": |
      程式碼審查模式。請對邊界情況及
      效能影響保持精確。
```

鍵名為 Slack 頻道 ID（可透過頻道詳情 → "About" → 捲動到底部找到）。符合頻道的所有訊息都將獲得注入的臨時系統提示。

## 疑難排解

| 問題 | 解決方案 |
|---------|----------|
| 機器人不回應私訊 | 驗證 `message.im` 是否在事件訂閱中，且應用程式已重新安裝 |
| 機器人在私訊中正常但在頻道中無反應 | **最常見的問題。** 將 `message.channels` 和 `message.groups` 加入事件訂閱，重新安裝應用程式，並使用 `/invite @Hermes Agent` 邀請機器人進入頻道 |
| 機器人不回應頻道中的 @標註 | 1) 檢查是否訂閱了 `message.channels` 事件。2) 機器人必須被邀請進頻道。3) 確保已新增 `channels:history` 範圍。4) 更改範圍/事件後必須重新安裝應用程式 |
| 機器人忽略私有頻道中的訊息 | 同時新增 `message.groups` 事件訂閱與 `groups:history` 範圍，然後重新安裝應用程式並 `/invite` 機器人 |
| 私訊中顯示 "Sending messages to this app has been turned off" | 在 App Home 設定中啟用 **Messages Tab**（參見步驟 5） |
| 出現 "not_authed" 或 "invalid_auth" 錯誤 | 重新產生您的機器人權杖和應用程式權杖，並更新 `.env` |
| 機器人有回應但無法在頻道中發文 | 使用 `/invite @Hermes Agent` 邀請機器人進入頻道 |
| 出現 "missing_scope" 錯誤 | 在 OAuth & Permissions 中新增所需的範圍，然後**重新安裝**應用程式 |
| 通訊端頻繁斷線 | 檢查您的網路；Bolt 會自動重新連線，但連線不穩會導致延遲 |
| 更改了範圍/事件但無變化 | 更改任何範圍或事件訂閱後，**必須重新安裝**應用程式到您的工作區 |

### 快速檢查清單

如果機器人在頻道中無法運作，請確認以下**所有**項目：

1. ✅ 已訂閱 `message.channels` 事件（針對公開頻道）
2. ✅ 已訂閱 `message.groups` 事件（針對私有頻道）
3. ✅ 已訂閱 `app_mention` 事件
4. ✅ 已新增 `channels:history` 範圍（針對公開頻道）
5. ✅ 已新增 `groups:history` 範圍（針對私有頻道）
6. ✅ 新增範圍/事件後已**重新安裝**應用程式
7. ✅ 已將機器人**邀請**進頻道 (`/invite @Hermes Agent`)
8. ✅ 您在訊息中確實使用了 **@標註** 機器人

---

## 安全性

:::warning
**請務必設定 `SLACK_ALLOWED_USERS`** 並填入已授權使用者的成員識別碼。若未進行此設定，閘道預設會**拒絕所有訊息**以確保安全。切勿分享您的機器人權杖 —— 請將其視為密碼保護。
:::

- 權杖應儲存在 `~/.hermes/.env` 中（檔案權限設為 `600`）
- 定期透過 Slack 應用程式設定更換權杖
- 審核誰有權存取您的 Hermes 設定目錄
- 通訊端模式意味著不暴露公開端點 —— 減少了一個攻擊面
