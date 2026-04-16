---
sidebar_position: 3
title: "Discord"
description: "將 Hermes Agent 設定為 Discord 機器人"
---

# Discord 設定

Hermes Agent 可作為機器人整合到 Discord 中，讓您透過私訊或伺服器頻道與您的 AI 助理聊天。機器人會接收您的訊息，透過 Hermes Agent 流程（包括工具使用、記憶和推理）進行處理，並即時回應。它支援文字、語音訊息、檔案附件和斜線指令 (Slash Commands)。

在設定之前，這裡是大多數人想知道的部分：Hermes 進入您的伺服器後的行為。

## Hermes 的行為

| 情境 | 行為 |
|---------|----------|
| **私訊 (DMs)** | Hermes 會回應每條訊息。無需 `@mention`（標記）。每條私訊都有自己的對話階段 (Session)。 |
| **伺服器頻道** | 預設情況下，Hermes 僅在您 `@mention` 它時才會回應。如果您在頻道中發言而未標記它，Hermes 會忽略該訊息。 |
| **自由回應頻道** | 您可以使用 `DISCORD_FREE_RESPONSE_CHANNELS` 讓特定頻道無需標記，或使用 `DISCORD_REQUIRE_MENTION=false` 全域停用標記限制。 |
| **討論串 (Threads)** | Hermes 會在同一個討論串中回覆。除非該討論串或其父頻道被設定為自由回應，否則標記規則仍然適用。討論串的對話歷史與父頻道保持隔離。 |
| **多人共用的頻道** | 預設情況下，為了安全和清晰，Hermes 會在頻道內隔離每個使用者的對話歷史。在同一個頻道中對話的兩個人不會共用同一個紀錄，除非您明確停用該功能。 |
| **標記其他使用者的訊息** | 當 `DISCORD_IGNORE_NO_MENTION` 為 `true`（預設值）時，如果訊息 `@mention` 了其他使用者但**沒有**標記機器人，Hermes 會保持沉默。這可以防止機器人介入指向他人的對話。如果您希望機器人回應所有訊息（無論標記了誰），請將其設定為 `false`。這僅適用於伺服器頻道，不適用於私訊。 |

:::tip
如果您想要一個一般的機器人說明頻道，讓使用者無需每次都標記 Hermes 即可對話，請將該頻道新增到 `DISCORD_FREE_RESPONSE_CHANNELS`。
:::

### Discord 網關模型

Discord 上的 Hermes 不是無狀態回覆的 Webhook。它透過完整的訊息網關運行，這意味著每條傳入訊息都會經過：

1. 授權 (`DISCORD_ALLOWED_USERS`)
2. 標記 / 自由回應檢查
3. 對話階段查詢
4. 對話紀錄載入
5. 正常的 Hermes 代理執行，包括工具、記憶和斜線指令
6. 回應傳回 Discord

這很重要，因為在繁忙的伺服器中，行為取決於 Discord 路由和 Hermes 對話政策。

### Discord 中的對話模型

預設情況下：

- 每條私訊都有自己的對話階段
- 每個伺服器討論串都有自己的對話階段命名空間
- 共用頻道中的每個使用者在該頻道內都有自己的對話階段

因此，如果 Alice 和 Bob 都在 `#research` 中與 Hermes 交談，儘管他們使用的是同一個可見的 Discord 頻道，Hermes 預設仍會將其視為個別對話。

這由 `config.yaml` 控制：

```yaml
group_sessions_per_user: true
```

僅當您明確希望整個聊天室共用一個對話時，才將其設定為 `false`：

```yaml
group_sessions_per_user: false
```

共用對話對於協作室很有用，但也意味著：

- 使用者共用上下文增長和代幣 (Token) 成本
- 一個人長時間的工具密集型任務可能會使其他人的上下文膨脹
- 一個人正在進行的執行可能會中斷聊天室中另一個人的後續動作

### 中斷與並行性

Hermes 透過對話階段鍵 (Session Key) 追蹤正在運行的代理。

使用預設的 `group_sessions_per_user: true`：

- Alice 中斷她自己正在進行的請求僅會影響該頻道中 Alice 的對話階段
- Bob 可以繼續在同一個頻道中交談，而不會繼承 Alice 的歷史紀錄或中斷 Alice 的執行

使用 `group_sessions_per_user: false`：

- 整個聊天室在該頻道/討論串中共用一個代理執行位置
- 來自不同人的後續訊息可能會互相中斷或排隊等待

本指南將引導您完成整個設定過程 — 從在 Discord 開發者入口網站上建立機器人到傳送您的第一條訊息。

## 步驟 1：建立 Discord 應用程式

1. 前往 [Discord 開發者入口網站 (Discord Developer Portal)](https://discord.com/developers/applications) 並使用您的 Discord 帳號登入。
2. 點擊右上角的 **New Application**。
3. 為您的應用程式輸入一個名稱（例如 "Hermes Agent"）並接受開發者服務條款。
4. 點擊 **Create**。

您將進入 **General Information** 頁面。記下 **Application ID** — 您稍後需要它來建立邀請連結。

## 步驟 2：建立機器人

1. 在左側邊欄點擊 **Bot**。
2. Discord 會自動為您的應用程式建立一個機器人使用者。您會看到機器人的使用者名稱，您可以自定義它。
3. 在 **Authorization Flow** 下：
   - 將 **Public Bot** 設定為 **ON** — 需要使用 Discord 提供的邀請連結（推薦）。這允許 Installation 標籤產生預設的授權 URL。
   - 將 **Require OAuth2 Code Grant** 保持為 **OFF**。

:::tip
您可以在此頁面為您的機器人設定自定義頭像和橫幅。這是使用者在 Discord 中看到的樣子。
:::

:::info[私有機器人替代方案]
如果您偏好保持機器人為私有（Public Bot = OFF），您**必須**在步驟 5 中使用**手動 URL** 方法，而不是使用 Installation 標籤。Discord 提供的連結要求啟用 Public Bot。
:::

## 步驟 3：啟用特權網關意圖 (Privileged Gateway Intents)

這是整個設定中最關鍵的一步。如果沒有啟用正確的意圖，您的機器人雖然可以連線到 Discord，但將**無法讀取訊息內容**。

在 **Bot** 頁面上，向下捲動到 **Privileged Gateway Intents**。您會看到三個切換開關：

| 意圖 | 用途 | 是否必要？ |
|--------|---------|-----------| 
| **Presence Intent** | 查看使用者線上/離線狀態 | 選填 |
| **Server Members Intent** | 存取成員清單、解析使用者名稱 | **必要** |
| **Message Content Intent** | 讀取訊息的文字內容 | **必要** |

將 **Server Members Intent** 和 **Message Content Intent** 都切換為 **ON**。

- 如果沒有 **Message Content Intent**，您的機器人會收到訊息事件，但訊息文字是空的 — 機器人完全看不到您輸入的內容。
- 如果沒有 **Server Members Intent**，機器人無法為授權使用者清單解析使用者名稱，且可能無法識別是誰在傳訊息給它。

:::warning[這是 Discord 機器人無法運作的首要原因]
如果您的機器人在線但從不回應訊息，幾乎可以肯定是因為停用了 **Message Content Intent**。請回到 [開發者入口網站](https://discord.com/developers/applications)，選擇您的應用程式 → Bot → Privileged Gateway Intents，並確保 **Message Content Intent** 已開啟。點擊 **Save Changes**。
:::

**關於伺服器數量：**
- 如果您的機器人在**少於 100 個伺服器**中，您可以自由切換意圖。
- 如果您的機器人在 **100 個或更多伺服器**中，Discord 要求您提交驗證申請才能使用特權意圖。對於個人使用，這不是問題。

點擊頁面底部的 **Save Changes**。

## 步驟 4：獲取機器人權杖 (Bot Token)

機器人權杖是 Hermes Agent 用來登入機器人的憑據。仍在 **Bot** 頁面：

1. 在 **Token** 區段下，點擊 **Reset Token**。
2. 如果您的 Discord 帳號啟用了雙重驗證 (2FA)，請輸入您的 2FA 代碼。
3. Discord 將顯示您的新權杖。**請立即複製它。**

:::warning[權杖僅顯示一次]
權杖僅顯示一次。如果您遺失了它，則需要重設並產生一個新權杖。切勿公開分享您的權杖或將其提交到 Git — 擁有此權杖的人可以完全控制您的機器人。
:::

將權杖儲存在安全的地方（例如密碼管理員）。您在步驟 8 中會需要它。

## 步驟 5：產生邀請連結 (Invite URL)

您需要一個 OAuth2 URL 來邀請機器人到您的伺服器。有兩種方法：

### 選項 A：使用 Installation 標籤（推薦）

:::note[需要 Public Bot]
此方法要求在步驟 2 中將 **Public Bot** 設定為 **ON**。如果您將 Public Bot 設定為 OFF，請改用下方的「手動產生 URL」方法。
:::

1. 在左側邊欄點擊 **Installation**。
2. 在 **Installation Contexts** 下，啟用 **Guild Install**。
3. 對於 **Install Link**，選擇 **Discord Provided Link**。
4. 在 Guild Install 的 **Default Install Settings** 下：
   - **Scopes**: 選擇 `bot` 和 `applications.commands`
   - **Permissions**: 選擇下方列出的權限。

### 選項 B：手動產生 URL

您可以使用此格式直接構建邀請連結：

```
https://discord.com/oauth2/authorize?client_id=YOUR_APP_ID&scope=bot+applications.commands&permissions=274878286912
```

將 `YOUR_APP_ID` 替換為步驟 1 中的 Application ID。

### 必要權限

這些是您的機器人需要的最低權限：

- **View Channels** — 查看它有權存取的頻道
- **Send Messages** — 回應您的訊息
- **Embed Links** — 格式化豐富的回應
- **Attach Files** — 傳送圖片、音訊和檔案輸出
- **Read Message History** — 保持對話上下文

### 推薦的額外權限

- **Send Messages in Threads** — 在討論串對話中回覆
- **Add Reactions** — 對訊息新增回應以示確認

### 權限整數 (Permission Integers)

| 級別 | 權限整數 | 包含內容 |
|-------|-------------------|-----------------|
| 最低限度 | `117760` | View Channels, Send Messages, Read Message History, Attach Files |
| 推薦 | `274878286912` | 以上所有加上 Embed Links, Send Messages in Threads, Add Reactions |

## 步驟 6：邀請至您的伺服器

1. 在瀏覽器中開啟邀請連結（來自 Installation 標籤或您手動構建的 URL）。
2. 在 **Add to Server** 下拉選單中，選擇您的伺服器。
3. 點擊 **Continue**，然後點擊 **Authorize**。
4. 如果出現提示，請完成 CAPTCHA 驗證。

:::info
您需要 Discord 伺服器上的 **Manage Server**（管理伺服器）權限才能邀請機器人。如果您在下拉選單中沒看到您的伺服器，請請伺服器管理員代為使用邀請連結。
:::

授權後，機器人將出現在您的伺服器成員清單中（在您啟動 Hermes 網關之前，它會顯示為離線）。

## 步驟 7：尋找您的 Discord 使用者 ID

Hermes Agent 使用您的 Discord 使用者 ID 來控制誰可以與機器人互動。尋找方法如下：

1. 開啟 Discord（桌面或網頁版）。
2. 前往 **Settings** → **Advanced** → 將 **Developer Mode** 切換為 **ON**。
3. 關閉設定。
4. 右鍵點擊您自己的使用者名稱（在訊息、成員清單或您的個人資料中）→ **Copy User ID**。

您的使用者 ID 是一長串數字，例如 `284102345871466496`。

:::tip
開發者模式還允許您以同樣的方式複製**頻道 ID** 和**伺服器 ID** — 右鍵點擊頻道或伺服器名稱，然後選擇「複製 ID」。如果您想手動設定主頻道，您會需要頻道 ID。
:::

## 步驟 8：設定 Hermes Agent

### 選項 A：互動式設定（推薦）

執行引導式設定指令：

```bash
hermes gateway setup
```

出現提示時選擇 **Discord**，然後貼上您的機器人權杖和使用者 ID。

### 選項 B：手動設定

將以下內容新增到您的 `~/.hermes/.env` 檔案中：

```bash
# 必要
DISCORD_BOT_TOKEN=your-bot-token
DISCORD_ALLOWED_USERS=284102345871466496

# 多個允許的使用者（以逗號分隔）
# DISCORD_ALLOWED_USERS=284102345871466496,198765432109876543
```

然後啟動網關：

```bash
hermes gateway
```

機器人應該會在幾秒鐘內在 Discord 中上線。傳送一條訊息給它 — 可以是私訊，也可以是在它能看見的頻道中 — 進行測試。

:::tip
您可以讓 `hermes gateway` 在背景運行，或將其作為 systemd 服務運行以實現持久操作。詳情請參閱部署文件。
:::

## 設定參考資料

Discord 的行為透過兩個檔案控制：**`~/.hermes/.env`** 用於憑據和環境級別的切換，而 **`~/.hermes/config.yaml`** 用於結構化設定。當兩者都設定時，環境變數始終優先於 config.yaml 的值。

### 環境變數 (`.env`)

| 變數 | 必填 | 預設值 | 描述 |
|----------|----------|---------|-------------|
| `DISCORD_BOT_TOKEN` | **是** | — | 來自 [Discord 開發者入口網站](https://discord.com/developers/applications) 的機器人權杖。 |
| `DISCORD_ALLOWED_USERS` | **是** | — | 以逗號分隔的 Discord 使用者 ID，允許與機器人互動。若未設定，網關會拒絕所有使用者。 |
| `DISCORD_HOME_CHANNEL` | 否 | — | 機器人傳送主動訊息（Cron 輸出、提醒、通知）的頻道 ID。 |
| `DISCORD_HOME_CHANNEL_NAME` | 否 | `"Home"` | 在日誌和狀態輸出中顯示的主頻道名稱。 |
| `DISCORD_REQUIRE_MENTION` | 否 | `true` | 為 `true` 時，機器人僅在伺服器頻道中被 `@mention` 時回應。設為 `false` 則回應所有頻道中的所有訊息。 |
| `DISCORD_FREE_RESPONSE_CHANNELS` | 否 | — | 以逗號分隔的頻道 ID。在這些頻道中，即使 `DISCORD_REQUIRE_MENTION` 為 `true`，機器人也無需標記即可回應。 |
| `DISCORD_IGNORE_NO_MENTION` | 否 | `true` | 為 `true` 時，若訊息標記了其他使用者但**未**標記機器人，機器人會保持沉默。防止機器人介入指向他人的對話。僅適用於伺服器頻道。 |
| `DISCORD_AUTO_THREAD` | 否 | `true` | 為 `true` 時，文字頻道中的每個標記都會自動建立新討論串，使對話保持隔離。討論串或私訊內的訊息不受影響。 |
| `DISCORD_ALLOW_BOTS` | 否 | `"none"` | 控制如何處理來自其他機器人的訊息。`"none"` — 忽略；`"mentions"` — 僅接受標記 Hermes 的；`"all"` — 接受所有。 |
| `DISCORD_REACTIONS` | 否 | `true` | 為 `true` 時，機器人在處理期間會新增表情符號回應（開始時 👀，成功時 ✅，錯誤時 ❌）。 |
| `DISCORD_IGNORED_CHANNELS` | 否 | — | 以逗號分隔的頻道 ID。即使被標記，機器人也**絕不**回應。此設定優先級最高。 |
| `DISCORD_NO_THREAD_CHANNELS` | 否 | — | 以逗號分隔的頻道 ID。在這些頻道中，機器人直接在頻道中回覆而不建立討論串。僅在 `DISCORD_AUTO_THREAD` 為 `true` 時有效。 |
| `DISCORD_REPLY_TO_MODE` | 否 | `"first"` | 控制回覆引用行為：`"off"` — 不引用；`"first"` — 僅引用第一個訊息區塊（預設）；`"all"` — 引用每個區塊。 |

### 設定檔 (`config.yaml`)

`~/.hermes/config.yaml` 中的 `discord` 區段映射了上述環境變數。Config.yaml 的設定作為預設值使用 — 如果已設定相應的環境變數，則以環境變數為準。

```yaml
# Discord 特定設定
discord:
  require_mention: true           # 伺服器頻道要求 @mention
  free_response_channels: ""      # 逗號分隔頻道 ID（或 YAML 列表）
  auto_thread: true               # 標記時自動建立討論串
  reactions: true                 # 處理時新增表情符號回應
  ignored_channels: []            # 機器人絕不回應的頻道 ID
  no_thread_channels: []          # 機器人直接回覆而不建立討論串的頻道 ID
  channel_prompts: {}             # 每個頻道的臨時系統提示詞

# 對話階段隔離（適用於所有網關平台，不限 Discord）
group_sessions_per_user: true     # 在共用頻道中隔離每個使用者的對話階段
```

#### `discord.require_mention`

**類型：** boolean — **預設值：** `true`

啟用時，機器人僅在伺服器頻道中被直接 `@mentioned` 時回應。私訊始終會收到回應。

#### `discord.free_response_channels`

**類型：** string 或 list — **預設值：** `""`

機器人無需標記即可回應所有訊息的頻道 ID。接受逗號分隔字串或 YAML 列表：

```yaml
# 字串格式
discord:
  free_response_channels: "1234567890,9876543210"

# 列表格式
discord:
  free_response_channels:
    - 1234567890
    - 9876543210
```

如果討論串的父頻道在此列表中，則該討論串也無需標記。

#### `discord.auto_thread`

**類型：** boolean — **預設值：** `true`

啟用時，一般文字頻道中的每個 `@mention` 都會自動建立一個新的對話討論串。這能保持主頻道整潔，並使每個對話擁有獨立的對話階段歷史。一旦討論串建立，該討論串內的後續訊息無需標記 — 機器人知道它已參與其中。

在現有討論串或私訊中傳送的訊息不受此設定影響。

#### `discord.reactions`

**類型：** boolean — **預設值：** `true`

控制機器人是否新增表情符號回應作為視覺回饋：
- 👀 在機器人開始處理訊息時新增
- ✅ 在回應成功送達時新增
- ❌ 在處理期間發生錯誤時新增

如果您覺得回應會干擾或是機器人的角色沒有 **Add Reactions** 權限，請停用此項。

#### `discord.ignored_channels`

**類型：** string 或 list — **預設值：** `[]`

機器人**絕不**回應的頻道 ID，即使被標記也不例外。此設定具有最高優先級。

```yaml
# 字串格式
discord:
  ignored_channels: "1234567890,9876543210"

# 列表格式
discord:
  ignored_channels:
    - 1234567890
    - 9876543210
```

如果討論串的父頻道在此列表中，則該討論串中的訊息也會被忽略。

#### `discord.no_thread_channels`

**類型：** string 或 list — **預設值：** `[]`

機器人直接在頻道中回應而不自動建立討論串的頻道 ID。這僅在 `auto_thread` 為 `true` 時有效。

```yaml
discord:
  no_thread_channels:
    - 1234567890  # 機器人在此處直接行內回覆
```

適用於專門用於機器人互動且討論串會造成干擾的頻道。

#### `discord.channel_prompts`

**類型：** mapping — **預設值：** `{}`

為每個頻道或討論串注入臨時系統提示詞。這些提示詞會在每次執行時注入，但不會持久化到歷史紀錄中。

```yaml
discord:
  channel_prompts:
    "1234567890": |
      此頻道用於研究任務。偏好深入比較、引用和簡潔總結。
    "9876543210": |
      此論壇用於治療式支援。請展現溫暖、穩重且不加評判的態度。
```

行為：
- 優先匹配精確的討論串/頻道 ID。
- 如果是討論串或論壇貼文且無精確匹配，則回退到父頻道/論壇 ID。

#### `group_sessions_per_user`

**類型：** boolean — **預設值：** `true`

這是一個全域網關設定（非 Discord 專屬），控制共用頻道中的使用者是否擁有隔離的對話歷史。

為 `true` 時：Alice 和 Bob 在 `#research` 中分別與 Hermes 進行獨立對話。為 `false` 時：整個頻道共用同一個紀錄和一個代理執行位置。

詳見上方的 [對話模型](#discord-中的對話模型) 區段。

#### `display.tool_progress`

**類型：** string — **預設值：** `"all"` — **可選值：** `off`, `new`, `all`, `verbose`

控制機器人是否在處理時傳送進度訊息（例如「正在讀取檔案...」、「正在執行終端指令...」）。

```yaml
display:
  tool_progress: "all"    # off | new | all | verbose
```

- `off` — 無進度訊息
- `new` — 僅顯示每次執行的第一個工具呼叫
- `all` — 顯示所有工具呼叫（在網關訊息中會截斷至 40 個字元）
- `verbose` — 顯示完整的工具呼叫細節

#### `display.tool_progress_command`

**類型：** boolean — **預設值：** `false`

啟用時，在網關中提供 `/verbose` 斜線指令，允許您循環切換進度模式。

```yaml
display:
  tool_progress_command: true
```

## 互動式模型選擇器

在 Discord 頻道中輸入不帶參數的 `/model` 可開啟下拉式模型選擇器：

1. **供應商選擇** — 顯示可用供應商的下拉選單。
2. **模型選擇** — 根據所選供應商顯示模型的下拉選單。

選擇器在 120 秒後逾時。僅授權使用者可以操作。如果您知道模型名稱，可直接輸入 `/model <名稱>`。

## 技能的原生斜線指令

Hermes 會自動將安裝的技能註冊為 **Discord 原生應用程式指令**。

- 每個技能都成為一個 Discord 斜線指令（例如 `/code-review`, `/ascii-art`）。
- 技能接受選填的 `args` 字串參數。
- Discord 對每個機器人的應用程式指令限制為 100 個。
- 技能在啟動時與內建指令（如 `/model`, `/reset`, `/background`）一同註冊。

無需額外設定 — 透過 `hermes skills install` 安裝的任何技能都會在下次重啟網關時自動註冊。

## 主頻道 (Home Channel)

您可以指定一個「主頻道」，機器人會在該頻道傳送主動訊息（如 Cron 任務輸出、提醒和通知）。有兩種設定方法：

### 使用斜線指令

在機器人所在的任何 Discord 頻道中輸入 `/sethome`。該頻道即成為主頻道。

### 手動設定

在您的 `~/.hermes/.env` 中新增：

```bash
DISCORD_HOME_CHANNEL=123456789012345678
DISCORD_HOME_CHANNEL_NAME="#bot-updates"
```

## 語音訊息

Hermes Agent 支援 Discord 語音訊息：

- **傳入的語音訊息**：會使用設定的 STT 供應商自動轉錄：本地 `faster-whisper` (無需權杖)、Groq Whisper (`GROQ_API_KEY`) 或 OpenAI Whisper (`VOICE_TOOLS_OPENAI_KEY`)。
- **文字轉語音 (TTS)**：使用 `/voice tts` 讓機器人隨文字回覆一同傳送語音音訊。
- **Discord 語音頻道**：Hermes 也可以加入語音頻道，聆聽使用者發言並在頻道中回應。

詳情請參閱：
- [語音模式 (Voice Mode)](/docs/user-guide/features/voice-mode)
- [在 Hermes 中使用語音模式](/docs/guides/use-voice-mode-with-hermes)

## 疑難排解

### 機器人在线但不回應訊息

**原因**：未啟用訊息內容意圖 (Message Content Intent)。

**修復**：前往 [開發者入口網站](https://discord.com/developers/applications) → 您的應用程式 → Bot → Privileged Gateway Intents → 啟用 **Message Content Intent** → 儲存變更。重啟網關。

### 啟動時出現 "Disallowed Intents" 錯誤

**原因**：程式請求了開發者入口網站中未啟用的意圖。

**修復**：在 Bot 設定中啟用所有三個特權意圖（Presence, Server Members, Message Content），然後重啟。

### 機器人看不見特定頻道的訊息

**原因**：機器人的角色沒有檢視該頻道的權限。

**修復**：在 Discord 中前往頻道設定 → 權限 → 新增機器人的角色，並啟用 **View Channel** 和 **Read Message History**。

### 403 Forbidden 錯誤

**原因**：機器人缺少必要權限。

**修復**：使用步驟 5 的 URL 重新邀請機器人並賦予正確權限，或在伺服器設定 → 角色中手動調整。

### 機器人離線

**原因**：Hermes 網關未運行，或權杖錯誤。

**修復**：檢查 `hermes gateway` 是否正在運行。驗證 `.env` 中的 `DISCORD_BOT_TOKEN`。

### 「使用者未獲授權」/ 機器人忽略您

**原因**：您的使用者 ID 不在 `DISCORD_ALLOWED_USERS` 中。

**修復**：在 `~/.hermes/.env` 中新增您的使用者 ID 並重啟網關。

### 同一頻道的人意外共用了歷史紀錄

**原因**：停用了 `group_sessions_per_user`。

**修復**：在 `~/.hermes/config.yaml` 中設定並重啟網關：

```yaml
group_sessions_per_user: true
```

## 安全性

:::warning
務必設定 `DISCORD_ALLOWED_USERS` 以限制誰可以與機器人互動。如果未設定，作為一項安全措施，網關預設會拒絕所有使用者。僅新增您信任的人的使用者 ID — 授權使用者擁有存取代理能力的完全權限，包括工具使用和系統存取。
:::

有關保護 Hermes Agent 部署的更多資訊，請參閱 [安全性指南](../security.md)。
