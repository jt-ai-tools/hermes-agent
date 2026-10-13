---
sidebar_position: 1
title: "Telegram"
description: "將 Hermes Agent 設定為 Telegram 機器人"
---

# Telegram 設定

Hermes Agent 可以作為一個功能齊全的對話機器人與 Telegram 整合。連線後，您可以在任何裝置上與代理程式聊天、傳送會自動轉錄的語音備忘錄、接收排程任務結果，並在群組聊天中使用代理程式。此整合基於 [python-telegram-bot](https://python-telegram-bot.org/) 建構，支援文字、語音、圖片和檔案附件。

## 步驟 1：透過 BotFather 建立機器人

每個 Telegram 機器人都需要一個由 [@BotFather](https://t.me/BotFather)（Telegram 官方機器人管理工具）發放的 API 權杖 (Token)。

1. 開啟 Telegram 並搜尋 **@BotFather**，或造訪 [t.me/BotFather](https://t.me/BotFather)
2. 傳送 `/newbot`
3. 選擇一個**顯示名稱** (例如 "Hermes Agent") —— 這可以是任何名稱
4. 選擇一個**使用者名稱** —— 這必須是唯一的且以 `bot` 結尾 (例如 `my_hermes_bot`)
5. BotFather 會回覆您的 **API 權杖**。看起來像這樣：

```
123456789:ABCdefGHIjklMNOpqrSTUvwxYZ
```

:::warning
請務必保密您的機器人權杖。任何擁有此權杖的人都可以控制您的機器人。如果外洩，請立即透過 BotFather 中的 `/revoke` 撤銷它。
:::

## 步驟 2：自訂您的機器人 (選填)

這些 BotFather 指令可以提升使用者體驗。傳送訊息給 @BotFather 並使用：

| 指令 | 用途 |
|---------|---------|
| `/setdescription` | 在使用者開始聊天前顯示的「此機器人可以做什麼？」文字 |
| `/setabouttext` | 顯示在機器人個人檔案頁面上的簡短文字 |
| `/setuserpic` | 為您的機器人上傳頭像 |
| `/setcommands` | 定義指令選單（對話框中的 `/` 按鈕） |
| `/setprivacy` | 控制機器人是否能看到所有群組訊息（參見步驟 3） |

:::tip
對於 `/setcommands`，一組實用的初始設定如下：

```
help - 顯示說明資訊
new - 開始新的對話
sethome - 將此聊天設定為主頻道
```
:::

## 步驟 3：隱私模式 (對群組至關重要)

Telegram 機器人有一個**預設啟用**的**隱私模式 (Privacy Mode)**。這是群組中使用機器人時最常見的困惑來源。

**當隱私模式開啟時**，您的機器人只能看到：
- 以 `/` 指令開頭的訊息
- 直接回覆機器人自己訊息的回覆
- 系統訊息（成員加入/離開、置頂訊息等）
- 機器人擔任管理員的頻道訊息

**當隱私模式關閉時**，機器人會接收群組中的每一則訊息。

### 如何關閉隱私模式

1. 傳送訊息給 **@BotFather**
2. 傳送 `/mybots`
3. 選擇您的機器人
4. 前往 **Bot Settings → Group Privacy → Turn off**

:::warning
變更隱私設定後，**您必須將機器人從所有群組中移除並重新加入**。Telegram 會在機器人加入群組時快取其隱私狀態，除非重新加入，否則不會更新。
:::

:::tip
除了關閉隱私模式外的另一個選擇是：將機器人提升為**群組管理員**。管理員權限的機器人無論隱私設定為何，一律會接收所有訊息，這樣就不需要切換全域隱私模式。
:::

## 步驟 4：尋找您的使用者 ID

Hermes Agent 使用數字形式的 Telegram 使用者 ID 來控制存取權。您的使用者 ID **不是**您的使用者名稱 —— 它是一個像 `123456789` 的數字。

**方法 1 (推薦)：** 傳送訊息給 [@userinfobot](https://t.me/userinfobot) —— 它會立即回覆您的使用者 ID。

**方法 2：** 傳送訊息給 [@get_id_bot](https://t.me/get_id_bot) —— 另一個可靠的選擇。

請記下這個數字，下一個步驟會用到。

## 步驟 5：設定 Hermes

### 選項 A：互動式設定 (推薦)

```bash
hermes gateway setup
```

提示時選擇 **Telegram**。設定精靈會詢問您的機器人權杖和允許的使用者 ID，然後自動為您完成設定。

### 選項 B：手動設定

在 `~/.hermes/.env` 中加入以下內容：

```bash
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrSTUvwxYZ
TELEGRAM_ALLOWED_USERS=123456789    # 若有多個使用者請以逗號分隔
```

### 啟動閘道

```bash
hermes gateway
```

機器人應該會在幾秒鐘內上線。在 Telegram 上傳送訊息給它以進行驗證。

## Webhook 模式

預設情況下，Hermes 使用**長輪詢 (Long Polling)** 連接到 Telegram —— 閘道會主動向 Telegram 伺服器發送請求以獲取新更新。這對於本地部署和常開型部署運作良好。

對於**雲端部署** (Fly.io, Railway, Render 等)，**Webhook 模式**更具成本效益。這些平台可以在接收到傳入 HTTP 流量時自動喚醒暫停的機器，但無法處理主動連線。由於輪詢是主動向外的，因此輪詢模式下的機器人永遠無法休眠。Webhook 模式則反轉了方向 —— Telegram 將更新推送到您機器人的 HTTPS 網址，從而實現「閒置即休眠」的部署。

| | 輪詢 (預設) | Webhook |
|---|---|---|
| 方向 | 閘道 → Telegram (向外) | Telegram → 閘道 (向內) |
| 適用場景 | 本地、常開伺服器 | 具備自動喚醒功能的雲端平台 |
| 設定 | 無需額外設定 | 需設定 `TELEGRAM_WEBHOOK_URL` |
| 閒置成本 | 機器必須保持執行 | 訊息之間機器可以休眠 |

### 設定方式

在 `~/.hermes/.env` 中加入以下內容：

```bash
TELEGRAM_WEBHOOK_URL=https://my-app.fly.dev/telegram
# TELEGRAM_WEBHOOK_PORT=8443        # 選填，預設為 8443
# TELEGRAM_WEBHOOK_SECRET=mysecret  # 選填，推薦設定
```

| 變數 | 必填 | 描述 |
|----------|----------|-------------|
| `TELEGRAM_WEBHOOK_URL` | 是 | Telegram 發送更新的公開 HTTPS 網址。網址路徑會自動提取 (例如從上述範例提取 `/telegram`)。 |
| `TELEGRAM_WEBHOOK_PORT` | 否 | Webhook 伺服器監聽的本地埠號 (預設為 `8443`)。 |
| `TELEGRAM_WEBHOOK_SECRET` | 否 | 用於驗證更新確實來自 Telegram 的秘密權杖。**強烈建議**在正式環境部署中使用。 |

設定 `TELEGRAM_WEBHOOK_URL` 後，閘道會啟動 HTTP Webhook 伺服器而非使用輪詢。若未設定，則使用輪詢模式 —— 行為與先前版本一致。

### 雲端部署範例 (Fly.io)

1. 將環境變數加入您的 Fly.io 應用程式秘密 (secrets)：

```bash
fly secrets set TELEGRAM_WEBHOOK_URL=https://my-app.fly.dev/telegram
fly secrets set TELEGRAM_WEBHOOK_SECRET=$(openssl rand -hex 32)
```

2. 在您的 `fly.toml` 中開放 Webhook 埠號：

```toml
[[services]]
  internal_port = 8443
  protocol = "tcp"

  [[services.ports]]
    handlers = ["tls", "http"]
    port = 443
```

3. 部署：

```bash
fly deploy
```

閘道日誌應顯示：`[telegram] Connected to Telegram (webhook mode)`。

## 主頻道

在任何 Telegram 聊天（私訊或群組）中使用 `/sethome` 指令，將其指定為**主頻道**。排程任務 (cron jobs) 會將結果傳送到此頻道。

您也可以在 `~/.hermes/.env` 中手動設定：

```bash
TELEGRAM_HOME_CHANNEL=-1001234567890
TELEGRAM_HOME_CHANNEL_NAME="我的筆記"
```

:::tip
群組聊天 ID 是負數 (例如 `-1001234567890`)。您的個人私訊 (DM) 聊天 ID 則與您的使用者 ID 相同。
:::

## 語音訊息

### 傳入語音 (語音轉文字)

您在 Telegram 上傳送的語音訊息會自動由 Hermes 設定的 STT 提供者進行轉錄，並以文字形式注入對話中。

- `local` 在執行 Hermes 的機器上使用 `faster-whisper` —— 不需要 API 金鑰
- `groq` 使用 Groq Whisper，需要 `GROQ_API_KEY`
- `openai` 使用 OpenAI Whisper，需要 `VOICE_TOOLS_OPENAI_KEY`

### 傳出語音 (文字轉語音)

當代理程式透過 TTS 產生音訊時，它會以原生 Telegram **語音泡泡 (voice bubbles)** 的形式傳送 —— 即那種圓形、可直接播放的形式。

- **OpenAI 和 ElevenLabs** 原生產生 Opus 格式 —— 不需要額外設定
- **Edge TTS** (預設的免費提供者) 輸出 MP3 格式，需要 **ffmpeg** 才能轉換為 Opus：

```bash
# Ubuntu/Debian
sudo apt install ffmpeg

# macOS
brew install ffmpeg
```

若沒有 ffmpeg，Edge TTS 音訊將作為一般音訊檔案傳送 (仍可播放，但使用長方形播放器而非語音泡泡)。

請在 `config.yaml` 的 `tts.provider` 鍵值下設定 TTS 提供者。

## 群組聊天使用

Hermes Agent 在 Telegram 群組聊天中運作時有以下注意事項：

- **隱私模式**決定了機器人能看到哪些訊息 (參見[步驟 3](#步驟-3隱私模式對群組至關重要))
- `TELEGRAM_ALLOWED_USERS` 仍然有效 —— 即使在群組中，也只有授權使用者能觸發機器人
- 您可以透過設定 `telegram.require_mention: true` 防止機器人回應一般的群組閒聊
- 當 `telegram.require_mention: true` 時，符合以下條件的群組訊息才會被接受：
  - 斜線指令 (slash commands)
  - 回覆機器人的訊息
  - `@機器人使用者名稱` 的標註
  - 符合您在 `telegram.mention_patterns` 中設定的正則表達式喚醒詞
- 如果未設定或設為 false，Hermes 會保持之前的開放群組行為，回應其能看到的所有一般群組訊息

### 群組觸發範例設定

將此內容加入您的 `~/.hermes/config.yaml`：

```yaml
telegram:
  require_mention: true
  mention_patterns:
    - "^\\s*chompy\\b"
```

此範例除了平常的直接觸發外，也允許以 `chompy` 開頭的訊息觸發機器人，即使沒有使用 `@標註`。

### 關於 `mention_patterns` 的說明

- 模式使用 Python 正則表達式 (regular expressions)
- 匹配不區分大小寫
- 模式會針對文字訊息和媒體說明 (captions) 進行檢查
- 無效的正則表達式模式會在閘道日誌中顯示警告而非導致機器人當機
- 如果您希望模式僅在訊息開頭匹配，請使用 `^` 錨點

## 私聊主題 (Bot API 9.4)

Telegram Bot API 9.4 (2026 年 2 月) 引入了**私聊主題 (Private Chat Topics)** —— 機器人可以直接在 1 對 1 私訊 (DM) 中建立論壇風格的主題討論串，不需要超級群組。這讓您可以在現有的 Hermes 私訊對話中執行多個獨立的工作空間。

### 使用案例

如果您同時進行多個長期的專案，主題可以保持各自的上下文獨立：

- **"Website" 主題** —— 處理您的正式網頁服務
- **"Research" 主題** —— 進行文獻回顧和論文探索
- **"General" 主題** —— 處理雜項任務和快速提問

每個主題都擁有自己對話工作階段、歷史記錄和上下文 —— 與其他主題完全隔離。

### 設定方式

在 `~/.hermes/config.yaml` 的 `platforms.telegram.extra.dm_topics` 下新增主題：

```yaml
platforms:
  telegram:
    extra:
      dm_topics:
      - chat_id: 123456789        # 您的 Telegram 使用者 ID
        topics:
        - name: General
          icon_color: 7322096
        - name: Website
          icon_color: 9367192
        - name: Research
          icon_color: 16766590
          skill: arxiv              # 在此主題中自動載入技能
```

**欄位說明：**

| 欄位 | 必填 | 描述 |
|-------|----------|-------------|
| `name` | 是 | 主題顯示名稱 |
| `icon_color` | 否 | Telegram 圖示顏色代碼 (整數) |
| `icon_custom_emoji_id` | 否 | 主題圖示的自訂表情符號 ID |
| `skill` | 否 | 在此主題的新工作階段中自動載入的技能 |
| `thread_id` | 否 | 主題建立後自動填入 —— 請勿手動設定 |

### 運作原理

1. 閘道啟動時，Hermes 會為每個尚未有 `thread_id` 的主題呼叫 `createForumTopic`
2. `thread_id` 會自動儲存回 `config.yaml` —— 之後重啟將跳過此 API 呼叫
3. 每個主題都映射到一個獨立的工作階段金鑰：`agent:main:telegram:dm:{chat_id}:{thread_id}`
4. 每個主題中的訊息都擁有自己的對話歷史、記憶清除和上下文視窗

### 技能綁定

具有 `skill` 欄位的主題在該主題啟動新工作階段時會自動載入該技能。這與在對話開始時輸入 `/skill-name` 的效果完全相同 —— 技能內容會注入到第一則訊息中，後續訊息在對話歷史中都能看到它。

例如，設定了 `skill: arxiv` 的主題在工作階段重置（由於閒置逾時、每日重置或手動 `/reset`）後，都會預先載入 arxiv 技能。

:::tip
在設定之外建立的主題（例如透過手動呼叫 Telegram API）會在 `forum_topic_created` 系統訊息到達時自動被發現。您也可以在閘道執行時將主題加入設定 —— 它們會在下一次快取失效時被讀取。
:::

## 群組論壇主題技能綁定

啟用了**主題模式**的超級群組（也稱為「論壇主題」）已經具備按主題隔離的工作階段 —— 每個 `thread_id` 映射到自己的對話。但您可能希望在訊息進入特定群組主題時**自動載入技能**，就像私聊主題的技能綁定一樣。

### 使用案例

一個擁有不同工作串論壇主題的團隊超級群組：

- **Engineering** 主題 → 自動載入 `software-development` 技能
- **Research** 主題 → 自動載入 `arxiv` 技能
- **General** 主題 → 不載入技能，通用助手

### 設定方式

在 `~/.hermes/config.yaml` 的 `platforms.telegram.extra.group_topics` 下新增主題綁定：

```yaml
platforms:
  telegram:
    extra:
      group_topics:
      - chat_id: -1001234567890       # 超級群組 ID
        topics:
        - name: Engineering
          thread_id: 5
          skill: software-development
        - name: Research
          thread_id: 12
          skill: arxiv
        - name: General
          thread_id: 1
          # 不載入技能 —— 通用用途
```

**欄位說明：**

| 欄位 | 必填 | 描述 |
|-------|----------|-------------|
| `chat_id` | 是 | 超級群組的數字 ID（以 `-100` 開頭的負數） |
| `name` | 否 | 主題的易讀標籤（僅供參考） |
| `thread_id` | 是 | Telegram 論壇主題 ID —— 可在 `t.me/c/<group_id>/<thread_id>` 連結中看到 |
| `skill` | 否 | 在此主題的新工作階段中自動載入的技能 |

### 運作原理

1. 當訊息進入已映射的群組主題時，Hermes 會在 `group_topics` 設定中尋找對應的 `chat_id` 和 `thread_id`
2. 如果匹配的項目具有 `skill` 欄位，該技能會為該工作階段自動載入 —— 與私聊主題綁定一致
3. 未設定 `skill` 鍵的主題僅進行工作階段隔離（既有行為，保持不變）
4. 未映射的 `thread_id` 或 `chat_id` 會被靜默忽略 —— 不會報錯，也不載入技能

### 與私聊主題的差異

| | 私聊主題 | 群組主題 |
|---|---|---|
| 設定鍵名 | `extra.dm_topics` | `extra.group_topics` |
| 主題建立 | 若缺 `thread_id`，Hermes 會透過 API 建立 | 管理員在 Telegram 介面中建立 |
| `thread_id` | 建立後自動填入 | 必須手動設定 |
| `icon_color` / `icon_custom_emoji_id` | 支援 | 不適用 (由管理員控制外觀) |
| 技能綁定 | ✓ | ✓ |
| 工作階段隔離 | ✓ | ✓ (論壇主題已內建) |

:::tip
要尋找主題的 `thread_id`，請在 Telegram 網頁版或電腦版開啟主題，觀察網址：`https://t.me/c/1234567890/5` —— 最後一個數字 (`5`) 即為 `thread_id`。超級群組的 `chat_id` 是群組 ID 加上 `-100` 前綴 (例如群組 `1234567890` 變成 `-1001234567890`)。
:::

## 近期 Bot API 功能

- **Bot API 9.4 (2026 年 2 月)：** 私聊主題 —— 機器人可以透過 `createForumTopic` 在 1 對 1 私訊對話中建立論壇主題。參見上方的[私聊主題](#私聊主題-bot-api-94)。
- **隱私權政策：** Telegram 現在要求機器人具備隱私權政策。請透過 BotFather 的 `/setprivacy_policy` 設定，否則 Telegram 可能會自動產生一個佔位符。如果您的機器人是對外公開的，這點尤為重要。
- **訊息串流：** Bot API 9.x 加入了對長回應串流的支援，這可以改善使用者對於較長代理程式回覆的延遲感。

## 互動式模型選擇器

當您在 Telegram 對話中傳送不帶參數的 `/model` 指令時，Hermes 會顯示一個互動式內嵌鍵盤用於切換模型：

1. **提供者選擇** —— 顯示各個可用提供者及其模型數量的按鈕 (例如 "OpenAI (15)", "✓ Anthropic (12)" 表示目前提供者)。
2. **模型選擇** —— 分頁的模型列表，具備**上一頁**/**下一頁**導覽、回傳提供者的**返回**按鈕以及**取消**。

目前使用的模型和提供者會顯示在頂端。所有導覽動作都是透過原地編輯同一則訊息完成的 (不會造成聊天畫面混亂)。

:::tip
如果您知道確切的模型名稱，可以直接輸入 `/model <名稱>` 跳過選擇器。您也可以輸入 `/model <名稱> --global` 以便在不同工作階段間保持此變更。
:::

## Webhook 模式

預設情況下，Telegram 適配器透過**長輪詢 (Long Polling)** 連接 —— 閘道發起向外連線至 Telegram 伺服器。這在任何地方都能運作，但會保持一個持久的連線。

**Webhook 模式** 是一種替代方案，Telegram 會透過 HTTPS 將更新推送到您的伺服器。這對於 **Serverless 和雲端部署** (Fly.io, Railway 等) 非常理想，因為傳入的 HTTP 可以喚醒暫停的機器。

### 設定方式

設定 `TELEGRAM_WEBHOOK_URL` 環境變數以啟用 Webhook 模式：

```bash
# 必填 — 您的公開 HTTPS 端點
TELEGRAM_WEBHOOK_URL=https://app.fly.dev/telegram

# 選填 — 本地監聽埠號 (預設為 8443)
TELEGRAM_WEBHOOK_PORT=8443

# 選填 — 用於更新驗證的秘密權杖 (若未設定則自動產生)
TELEGRAM_WEBHOOK_SECRET=my-secret-token
```

或者在 `~/.hermes/config.yaml` 中設定：

```yaml
telegram:
  webhook_mode: true
```

設定 `TELEGRAM_WEBHOOK_URL` 後，閘道會啟動一個監聽在 `0.0.0.0:<埠號>` 的 HTTP 伺服器，並向 Telegram 註冊此 Webhook 網址。網址路徑會從該網址中提取 (預設為 `/telegram`)。

:::warning
Telegram 要求 Webhook 端點必須具備**有效的 TLS 憑證**。自簽署憑證將被拒絕。請使用反向代理 (nginx, Caddy) 或提供 TLS 終止的平台 (Fly.io, Railway, Cloudflare Tunnel)。
:::

## DNS-over-HTTPS 備援 IP

在某些受限制的網路中，`api.telegram.org` 可能會解析到無法連線的 IP。Telegram 適配器包含一個**備援 IP (Fallback IP)** 機制，它能透明地嘗試連線替代 IP，同時保留正確的 TLS 主機名稱和 SNI。

### 運作原理

1. 如果設定了 `TELEGRAM_FALLBACK_IPS`，則直接使用這些 IP。
2. 否則，適配器會自動透過 DNS-over-HTTPS (DoH) 查詢 **Google DNS** 和 **Cloudflare DNS**，以尋找 `api.telegram.org` 的替代 IP。
3. 如果 DoH 回傳的 IP 與系統 DNS 結果不同，這些 IP 將被用作備援。
4. 如果 DoH 也被封鎖，則會使用硬編碼的種子 IP (`149.154.167.220`) 作為最後手段。
5. 一旦備援 IP 連線成功，它會變得「有黏性 (sticky)」 —— 後續請求將直接使用它，而不必先嘗試主路徑。

### 設定方式

```bash
# 明確的備援 IP (以逗號分隔)
TELEGRAM_FALLBACK_IPS=149.154.167.220,149.154.167.221
```

或者在 `~/.hermes/config.yaml` 中設定：

```yaml
platforms:
  telegram:
    extra:
      fallback_ips:
        - "149.154.167.220"
```

:::tip
通常您不需要手動設定此項。透過 DoH 的自動發現機制可以處理大多數受限網路情境。只有在您的網路中 DoH 也被封鎖時，才需要 `TELEGRAM_FALLBACK_IPS` 環境變數。
:::

## 代理伺服器支援

如果您的網路需要透過 HTTP 代理伺服器才能存取網際網路 (常見於企業環境)，Telegram 適配器會自動讀取標準的代理環境變數，並透過該代理路由所有連線。

### 支援的變數

適配器按順序檢查這些環境變數，使用第一個設定的變數：

1. `HTTPS_PROXY`
2. `HTTP_PROXY`
3. `ALL_PROXY`
4. `https_proxy` / `http_proxy` / `all_proxy` (小寫變體)

### 設定方式

在啟動閘道前設定環境變數：

```bash
export HTTPS_PROXY=http://proxy.example.com:8080
hermes gateway
```

或者加入到 `~/.hermes/.env`：

```bash
HTTPS_PROXY=http://proxy.example.com:8080
```

代理伺服器設定適用於主傳輸層和所有備援 IP 傳輸層。不需要額外的 Hermes 設定 —— 只要環境變數存在，就會自動使用。

:::note
此說明涵蓋了 Hermes 用於 Telegram 連線的自訂備援傳輸層。其他地方使用的標準 `httpx` 客戶端本身已經支援代理環境變數。
:::

## 訊息回應 (Reactions)

機器人可以對訊息新增表情符號回應，作為處理進度的視覺回饋：

- 👀 當機器人開始處理您的訊息時
- ✅ 當回應成功送達時
- ❌ 如果處理過程中發生錯誤

回應功能**預設為停用**。請在 `config.yaml` 中啟用：

```yaml
telegram:
  reactions: true
```

或者透過環境變數啟用：

```bash
TELEGRAM_REACTIONS=true
```

:::note
與 Discord 不同 (其回應是累加的)，Telegram 的 Bot API 在單次呼叫中會替換所有的機器人回應。從 👀 到 ✅/❌ 的轉變是原子性的 —— 您不會同時看到兩者。
:::

:::tip
如果機器人在群組中沒有新增回應的權限，回應呼叫將會靜默失敗，訊息處理則會正常繼續。
:::

## 針對個別頻道的提示 (Prompts)

為特定的 Telegram 群組或論壇主題分配臨時的系統提示。提示會在每一回合執行時注入 —— 永不持久化到對話歷史中 —— 因此更改會立即生效。

```yaml
telegram:
  channel_prompts:
    "-1001234567890": |
      你是一位研究助理。請專注於學術來源、
      引用以及簡潔的綜合分析。
    "42":  |
      此主題用於提供創意寫作回饋。請保持
      溫暖且具建設性。
```

鍵名為聊天 ID（群組/超級群組）或論壇主題 ID。對於論壇群組，主題層級的提示會優先於群組層級的提示：

- 群組 `-1001234567890` 內主題 `42` 的訊息 → 使用主題 `42` 的提示
- 主題 `99` (無明確條目) 的訊息 → 備援至群組 `-1001234567890` 的提示
- 未在清單中的群組訊息 → 不套用頻道提示

數字形式的 YAML 鍵名會自動正規化為字串。

## 疑難排解

| 問題 | 解決方案 |
|---------|----------|
| 機器人完全沒有回應 | 驗證 `TELEGRAM_BOT_TOKEN` 是否正確。檢查 `hermes gateway` 日誌是否有錯誤。 |
| 機器人回覆 "unauthorized" | 您的使用者 ID 不在 `TELEGRAM_ALLOWED_USERS` 中。請使用 @userinfobot 再次確認。 |
| 機器人忽略群組訊息 | 隱私模式可能已開啟。請關閉它 (步驟 3) 或將機器人設為群組管理員。**記住，變更隱私設定後必須重新加入機器人。** |
| 語音訊息未轉錄 | 驗證 STT 是否可用：安裝 `faster-whisper` 進行本地轉錄，或在 `~/.hermes/.env` 中設定 `GROQ_API_KEY` / `VOICE_TOOLS_OPENAI_KEY`。 |
| 語音回覆是檔案而非泡泡 | 請安裝 `ffmpeg` (Edge TTS 轉換 Opus 所需)。 |
| 機器人權杖被撤銷/無效 | 透過 BotFather 使用 `/revoke` 然後 `/newbot` 或 `/token` 產生新權杖。更新您的 `.env` 檔案。 |
| Webhook 未接收到更新 | 驗證 `TELEGRAM_WEBHOOK_URL` 是否可從外網存取 (使用 `curl` 測試)。確保您的平台/反向代理將來自該網址埠號的傳入 HTTPS 流量路由到由 `TELEGRAM_WEBHOOK_PORT` 設定的本地監聽埠號 (兩者不需要相同)。確保 SSL/TLS 已啟用 —— Telegram 僅向 HTTPS 網址發送訊息。檢查防火牆規則。 |

## 執行授權 (Exec Approval)

當代理程式嘗試執行潛在危險的指令時，它會在對話中徵求您的授權：

> ⚠️ 此指令具備潛在危險 (遞迴刪除)。請回覆 "yes" 以批准。

回覆 "yes"/"y" 表示批准，回覆 "no"/"n" 表示拒絕。

## 安全性

:::warning
務必設定 `TELEGRAM_ALLOWED_USERS` 以限制誰可以與您的機器人互動。若未設定，閘道預設會拒絕所有使用者以確保安全。
:::

切勿公開分享您的機器人權杖。如果外洩，請立即透過 BotFather 的 `/revoke` 指令撤銷它。

如需更多詳細資訊，請參閱[安全性說明文件](/user-guide/security)。您也可以使用[私訊配對 (DM pairing)](/user-guide/messaging#dm-pairing-alternative-to-allowlists) 實現更動態的使用者授權方式。
