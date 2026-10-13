---
sidebar_position: 11
title: "飛書 (Feishu) / Lark"
description: "將 Hermes Agent 設定為飛書或 Lark 機器人"
---

# 飛書 (Feishu) / Lark 設定

Hermes Agent 可作為功能齊全的機器人與飛書 (Feishu) 和 Lark 整合。連線後，您可以在私訊或群組對話中與代理聊天、在主對話中接收 Cron 任務結果，並透過正常的網關流程傳送文字、圖片、音訊和檔案附件。

此整合支援兩種連線模式：

- `websocket` — 推薦；由 Hermes 發起外連，您不需要公開的 Webhook 端點。
- `webhook` — 當您希望飛書/Lark 透過 HTTP 將事件推送到您的網關時使用。

## Hermes 的行為

| 情境 | 行為 |
|---------|----------|
| 私訊 | Hermes 會回應每條訊息。 |
| 群組對話 | Hermes 僅在群組中被 @mention（標記）時才會回應。 |
| 共用群組對話 | 預設情況下，共用對話中的每個使用者擁有隔離的對話階段 (Session) 歷史。 |

這種共用對話行為由 `config.yaml` 控制：

```yaml
group_sessions_per_user: true
```

僅當您明確希望每個群組對話共用一個對話時，才將其設定為 `false`。

## 步驟 1：建立飛書 (Feishu) / Lark 應用程式

### 推薦：掃碼建立（單一指令）

```bash
hermes gateway setup
```

選擇 **Feishu / Lark** 並使用您的飛書或 Lark 行動 App 掃描 QR code。Hermes 將自動建立一個具有正確權限的機器人應用程式，並儲存憑據。

### 替代方案：手動設定

如果掃碼建立不可用，精靈會回退到手動輸入：

1. 開啟飛書或 Lark 開發者後台：
   - 飛書：[https://open.feishu.cn/](https://open.feishu.cn/)
   - Lark：[https://open.larksuite.com/](https://open.larksuite.com/)
2. 建立一個新應用程式。
3. 在**憑據與基礎資訊**中，複製 **App ID** 和 **App Secret**。
4. 為應用程式啟用**機器人**能力。
5. 執行 `hermes gateway setup`，選擇 **Feishu / Lark**，並在提示時輸入憑據。

:::warning
請保持 App Secret 的私密性。擁有它的人可以冒充您的應用程式。
:::

## 步驟 2：選擇連線模式

### 推薦：WebSocket 模式

當 Hermes 運行在您的筆記型電腦、工作站或私有伺服器上時，請使用 WebSocket 模式。不需要公開的 URL。官方的 Lark SDK 會開啟並維持一個持久的外連 WebSocket 連線，並具有自動重新連線功能。

```bash
FEISHU_CONNECTION_MODE=websocket
```

**要求：** 必須安裝 `websockets` Python 套件。SDK 會在內部處理連線生命週期、心跳跳動和自動重新連線。

**運作原理：** 適配器在背景執行緒中運行 Lark SDK 的 WebSocket 用戶端。傳入的事件（訊息、回應、卡片動作）會被派發到主非同步迴圈 (asyncio loop)。斷開連線時，SDK 會嘗試自動重新連線。

### 選填：Webhook 模式

僅當您已將 Hermes 運行在可存取的 HTTP 端點後方時，才使用 Webhook 模式。

```bash
FEISHU_CONNECTION_MODE=webhook
```

在 Webhook 模式下，Hermes 會啟動一個 HTTP 伺服器（透過 `aiohttp`）並在以下位址提供飛書端點：

```text
/feishu/webhook
```

**要求：** 必須安裝 `aiohttp` Python 套件。

您可以自定義 Webhook 伺服器的繫結位址和路徑：

```bash
FEISHU_WEBHOOK_HOST=127.0.0.1   # 預設值：127.0.0.1
FEISHU_WEBHOOK_PORT=8765         # 預設值：8765
FEISHU_WEBHOOK_PATH=/feishu/webhook  # 預設值：/feishu/webhook
```

當飛書傳送 URL 驗證挑戰 (`type: url_verification`) 時，Webhook 會自動回應，以便您在飛書開發者後台中完成訂閱設定。

## 步驟 3：設定 Hermes

### 選項 A：互動式設定

```bash
hermes gateway setup
```

選擇 **Feishu / Lark** 並填寫提示內容。

### 選項 B：手動設定

將以下內容新增到 `~/.hermes/.env`：

```bash
FEISHU_APP_ID=cli_xxx
FEISHU_APP_SECRET=secret_xxx
FEISHU_DOMAIN=feishu
FEISHU_CONNECTION_MODE=websocket

# 選填，但強烈建議設定
FEISHU_ALLOWED_USERS=ou_xxx,ou_yyy
FEISHU_HOME_CHANNEL=oc_xxx
```

`FEISHU_DOMAIN` 接受：

- `feishu` 代表飛書中國版
- `lark` 代表 Lark 國際版

## 步驟 4：啟動網關

```bash
hermes gateway
```

然後從飛書/Lark 傳送訊息給機器人以確認連線已建立。

## 主對話 (Home Chat)

在飛書/Lark 對話中使用 `/set-home` 指令，將其標記為主頻道，用於接收 Cron 任務結果和跨平台通知。

您也可以預先設定：

```bash
FEISHU_HOME_CHANNEL=oc_xxx
```

## 安全性

### 使用者允許清單

對於生產環境，請設定飛書 Open ID 的允許清單：

```bash
FEISHU_ALLOWED_USERS=ou_xxx,ou_yyy
```

如果允許清單為空，任何能接觸到機器人的人都可能可以使用它。在群組對話中，會在處理訊息前檢查寄件者的 open_id 是否在允許清單中。

### Webhook 加密金鑰

在 Webhook 模式下運行時，請設定加密金鑰以啟用傳入 Webhook 負載的簽章驗證：

```bash
FEISHU_ENCRYPT_KEY=your-encrypt-key
```

此金鑰可以在飛書應用設定的**事件訂閱**區段找到。設定後，適配器會使用簽章演算法驗證每個 Webhook 請求：

```
SHA256(timestamp + nonce + encrypt_key + body)
```

計算出的雜湊值會與 `x-lark-signature` 標頭進行計時安全比較。簽章無效或缺失的請求將被拒絕，並傳回 HTTP 401。

:::tip
在 WebSocket 模式下，簽章驗證由 SDK 本身處理，因此 `FEISHU_ENCRYPT_KEY` 是選填的。在 Webhook 模式下，強烈建議在生產環境中設定。
:::

### 驗證權杖 (Verification Token)

這是另一層身份驗證，會檢查 Webhook 負載內部的 `token` 欄位：

```bash
FEISHU_VERIFICATION_TOKEN=your-verification-token
```

此權杖也可以在飛書應用程式的**事件訂閱**區段找到。設定後，每個傳入的 Webhook 負載在其 `header` 物件中必須包含匹配的 `token`。不匹配的權杖將被拒絕，並傳回 HTTP 401。

`FEISHU_ENCRYPT_KEY` 和 `FEISHU_VERIFICATION_TOKEN` 可以同時使用，以實現縱深防禦。

## 群組訊息政策

`FEISHU_GROUP_POLICY` 環境變數控制 Hermes 是否以及如何回應群組對話：

```bash
FEISHU_GROUP_POLICY=allowlist   # 預設值
```

| 數值 | 行為 |
|-------|----------|
| `open` | Hermes 回應任何人在任何群組中的 @mention。 |
| `allowlist` | Hermes 僅回應 `FEISHU_ALLOWED_USERS` 列表中使用者的 @mention。 |
| `disabled` | Hermes 完全忽略所有群組訊息。 |

在所有模式下，必須在群組中明確地 @mention 機器人（或 @所有人）才會處理訊息。私訊則不受此門檻限制。

### 用於 @Mention 過濾的機器人身份

為了在群組中進行精確的 @mention 檢測，適配器需要知道機器人的身份。可以明確提供：

```bash
FEISHU_BOT_OPEN_ID=ou_xxx
FEISHU_BOT_USER_ID=xxx
FEISHU_BOT_NAME=MyBot
```

如果皆未設定，適配器將在啟動時嘗試透過 Application Info API 自動獲取機器人名稱。為此，請授予 `admin:app.info:readonly` 或 `application:application:self_manage` 權限範圍。

## 互動式卡片動作 (Interactive Card Actions)

當使用者點擊機器人傳送的互動式卡片按鈕或與之互動時，適配器會將這些路由為合成的 `/card` 指令事件：

- 按鈕點擊變為：`/card button {"key": "value", ...}`
- 來自卡片定義的動作 `value` 負載會以 JSON 形式包含在內。
- 卡片動作會在 15 分鐘的視窗內進行去重，以防止重複處理。

卡片動作事件以 `MessageType.COMMAND` 分派，因此它們會流經正常的指令處理流程。

這也是**指令核准**運作的方式 — 當代理需要執行危險指令時，它會傳送一張帶有「核准一次 / 此對話 / 始終 / 拒絕」按鈕的互動式卡片。使用者點擊按鈕後，卡片動作回調會將核准決定傳回給代理。

### 必要的飛書應用程式設定

互動式卡片需要在飛書開發者後台進行**三個**設定步驟。漏掉任何一個都會導致使用者點擊卡片按鈕時出現錯誤 **200340**。

1. **訂閱卡片動作事件：**
   在**事件訂閱**中，將 `card.action.trigger` 新增到您的訂閱事件中。

2. **啟用互動式卡片能力：**
   在**應用能力 > 機器人**中，確保**互動式卡片**開關已啟用。這告訴飛書您的應用程式可以接收卡片動作回調。

3. **設定卡片請求 URL（僅限 Webhook 模式）：**
   在**應用能力 > 機器人 > 訊息卡片請求 URL**中，將 URL 設定為與您的事件 Webhook 相同的端點（例如 `https://your-server:8765/feishu/webhook`）。在 WebSocket 模式下，這由 SDK 自動處理。

:::warning
如果不完成這三個步驟，飛書雖然可以成功*傳送*互動式卡片（傳送僅需要 `im:message:send` 權限），但點擊任何按鈕都會傳回錯誤 200340。卡片看起來正常 — 只有在使用者與其互動時才會出現錯誤。
:::

## 媒體支援

### 入站（接收）

適配器從使用者接收並快取以下媒體類型：

| 類型 | 副檔名 | 處理方式 |
|------|-----------|-------------------|
| **圖片** | .jpg, .jpeg, .png, .gif, .webp, .bmp | 透過飛書 API 下載並在本地快取 |
| **音訊** | .ogg, .mp3, .wav, .m4a, .aac, .flac, .opus, .webm | 下載並快取；小型文字檔案會自動提取 |
| **影片** | .mp4, .mov, .avi, .mkv, .webm, .m4v, .3gp | 下載並快取為文件 |
| **檔案** | .pdf, .doc, .docx, .xls, .xlsx, .ppt, .pptx 等 | 下載並快取為文件 |

來自富文本（post）訊息的媒體（包括行內圖片和檔案附件）也會被提取並快取。

對於小型文字文件 (.txt, .md)，檔案內容會自動注入到訊息文字中，代理無需工具即可直接閱讀。

### 出站（傳送）

| 方法 | 傳送內容 |
|--------|--------------|
| `send` | 文字或富文本訊息（根據 Markdown 內容自動檢測） |
| `send_image` / `send_image_file` | 上傳圖片到飛書，然後作為原生圖片氣泡傳送（可選標題） |
| `send_document` | 上傳檔案到飛書 API，然後作為檔案附件傳送 |
| `send_voice` | 將音訊檔案作為飛書檔案附件傳送 |
| `send_video` | 上傳影片並作為原生媒體訊息傳送 |
| `send_animation` | GIF 會降級為檔案附件（飛書沒有原生的 GIF 氣泡） |

檔案上傳路由根據副檔名自動決定：

- `.ogg`, `.opus` → 以 `opus` 音訊上傳
- `.mp4`, `.mov`, `.avi`, `.m4v` → 以 `mp4` 媒體上傳
- `.pdf`, `.doc(x)`, `.xls(x)`, `.ppt(x)` → 以其相應的文件類型上傳
- 其他內容 → 以通用串流檔案 (generic stream file) 上傳

## Markdown 渲染與富文本 (Post) 回退

當傳出的文字包含 Markdown 格式（標題、加粗、列表、程式碼區塊、連結等）時，適配器會自動將其作為飛書 **富文本 (post)** 訊息傳送，並帶有嵌入的 `md` 標籤，而不是純文字。這使得飛書用戶端可以實現豐富的渲染效果。

如果飛書 API 拒絕了 post 負載（例如由於不支援的 Markdown 構造），適配器會自動回退，清除 Markdown 語法並以純文字形式傳送。這種兩階段回退確保訊息始終能送達。

未檢測到 Markdown 的純文字訊息將以簡單的 `text` 訊息類型傳送。

## 確認 (ACK) 表情符號回應

當適配器收到傳入訊息時，它會立即新增一個 ✅ (OK) 表情符號回應，以示意訊息已收到並正在處理。這在代理完成回應前提供了視覺回饋。

此回應是持久的 — 在回應傳送後它仍會保留在訊息上，作為接收標記。

使用者對機器人訊息的回應也會被追蹤。如果使用者在機器人傳送的訊息上新增或移除表情符號回應，它會被路由為合成的文字事件（`reaction:added:EMOJI_TYPE` 或 `reaction:removed:EMOJI_TYPE`），以便代理對回饋做出回應。

## 突發流量保護與批次處理

適配器包含針對快速訊息爆發的去彈跳 (debouncing) 功能，以避免代理負擔過重：

### 文字批次處理

當使用者快速連續傳送多條文字訊息時，它們會在分派前合併為單個事件：

| 設定 | 環境變數 | 預設值 |
|---------|---------|---------|
| 靜默期 | `HERMES_FEISHU_TEXT_BATCH_DELAY_SECONDS` | 0.6s |
| 每個批次最大訊息數 | `HERMES_FEISHU_TEXT_BATCH_MAX_MESSAGES` | 8 |
| 每個批次最大字元數 | `HERMES_FEISHU_TEXT_BATCH_MAX_CHARS` | 4000 |

### 媒體批次處理

快速連續傳送的多個媒體附件（例如拖入多張圖片）會合併為單個事件：

| 設定 | 環境變數 | 預設值 |
|---------|---------|---------|
| 靜默期 | `HERMES_FEISHU_MEDIA_BATCH_DELAY_SECONDS` | 0.8s |

### 每個對話的序列化

同一對話內的訊息會序列化（一次一個）處理，以維持對話連貫性。每個對話都有自己的鎖，因此不同對話中的訊息會並行處理。

## 速率限制（Webhook 模式）

在 Webhook 模式下，適配器強制執行每個 IP 的速率限制以防止濫用：

- **視窗：** 60 秒滑動視窗
- **限制：** 每個 (app_id, path, IP) 三元組在每個視窗內限制 120 個請求
- **追蹤上限：** 最多追蹤 4096 個唯一鍵（防止記憶體無限增長）

超過限制的請求將收到 HTTP 429 (Too Many Requests)。

### Webhook 異常追蹤

適配器追蹤每個 IP 位址的連續錯誤回應。如果同一 IP 在 6 小時視窗內出現 25 次連續錯誤，將記錄警告。這有助於檢測設定錯誤的用戶端或探測嘗試。

額外的 Webhook 保護：
- **內文大小限制：** 最大 1 MB
- **內文讀取逾時：** 30 秒
- **強制 Content-Type：** 僅接受 `application/json`

## WebSocket 微調

使用 `websocket` 模式時，您可以自定義重新連線和 Ping 行為：

```yaml
platforms:
  feishu:
    extra:
      ws_reconnect_interval: 120   # 重新連線嘗試間隔秒數（預設值：120）
      ws_ping_interval: 30         # WebSocket Ping 間隔秒數（選填；未設定時使用 SDK 預設值）
```

| 設定 | 設定鍵 | 預設值 | 描述 |
|---------|-----------|---------|-------------|
| 重新連線間隔 | `ws_reconnect_interval` | 120s | 兩次重新連線嘗試之間的等待時間 |
| Ping 間隔 | `ws_ping_interval` | _(SDK 預設)_ | WebSocket 保持連線 (keepalive) 的 Ping 頻率 |

## 每個群組的存取控制

除了全域的 `FEISHU_GROUP_POLICY` 外，您還可以在 config.yaml 中使用 `group_rules` 為每個群組對話設定細粒度的規則：

```yaml
platforms:
  feishu:
    extra:
      default_group_policy: "open"     # 未在 group_rules 中的群組預設政策
      admins:                          # 可管理機器人設定的使用者
        - "ou_admin_open_id"
      group_rules:
        "oc_group_chat_id_1":
          policy: "allowlist"          # open | allowlist | blacklist | admin_only | disabled
          allowlist:
            - "ou_user_open_id_1"
            - "ou_user_open_id_2"
        "oc_group_chat_id_2":
          policy: "admin_only"
        "oc_group_chat_id_3":
          policy: "blacklist"
          blacklist:
            - "ou_blocked_user"
```

| 政策 | 描述 |
|--------|-------------|
| `open` | 群組中的任何人都可以使用機器人 |
| `allowlist` | 僅群組 `allowlist` 中的使用者可以使用機器人 |
| `blacklist` | 除了群組 `blacklist` 中的使用者外，所有人都可以使用機器人 |
| `admin_only` | 僅全域 `admins` 列表中的使用者可以在此群組中使用機器人 |
| `disabled` | 機器人忽略此群組中的所有訊息 |

未在 `group_rules` 中列出的群組將回退到 `default_group_policy`（預設為 `FEISHU_GROUP_POLICY` 的值）。

## 去重 (Deduplication)

傳入訊息使用訊息 ID 進行去重，生存時間 (TTL) 為 24 小時。去重狀態會跨重啟持久化到 `~/.hermes/feishu_seen_message_ids.json`。

| 設定 | 環境變數 | 預設值 |
|---------|---------|---------|
| 快取大小 | `HERMES_FEISHU_DEDUP_CACHE_SIZE` | 2048 個條目 |

## 所有環境變數

| 變數 | 必填 | 預設值 | 描述 |
|----------|----------|---------|-------------|
| `FEISHU_APP_ID` | ✅ | — | 飛書/Lark App ID |
| `FEISHU_APP_SECRET` | ✅ | — | 飛書/Lark App Secret |
| `FEISHU_DOMAIN` | — | `feishu` | `feishu` (中國) 或 `lark` (國際) |
| `FEISHU_CONNECTION_MODE` | — | `websocket` | `websocket` 或 `webhook` |
| `FEISHU_ALLOWED_USERS` | — | _(空)_ | 以逗號分隔的使用者 open_id 允許清單 |
| `FEISHU_HOME_CHANNEL` | — | — | 用於 Cron/通知輸出的對話 ID |
| `FEISHU_ENCRYPT_KEY` | — | _(空)_ | 用於 Webhook 簽章驗證的加密金鑰 |
| `FEISHU_VERIFICATION_TOKEN` | — | _(空)_ | 用於 Webhook 負載驗證的權杖 |
| `FEISHU_GROUP_POLICY` | — | `allowlist` | 群組訊息政策：`open`, `allowlist`, `disabled` |
| `FEISHU_BOT_OPEN_ID` | — | _(空)_ | 機器人的 open_id（用於 @mention 檢測） |
| `FEISHU_BOT_USER_ID` | — | _(空)_ | 機器人的 user_id（用於 @mention 檢測） |
| `FEISHU_BOT_NAME` | — | _(空)_ | 機器人的顯示名稱（用於 @mention 檢測） |
| `FEISHU_WEBHOOK_HOST` | — | `127.0.0.1` | Webhook 伺服器繫結位址 |
| `FEISHU_WEBHOOK_PORT` | — | `8765` | Webhook 伺服器連接埠 |
| `FEISHU_WEBHOOK_PATH` | — | `/feishu/webhook` | Webhook 端點路徑 |
| `HERMES_FEISHU_DEDUP_CACHE_SIZE` | — | `2048` | 要追蹤的最大去重訊息 ID 數量 |
| `HERMES_FEISHU_TEXT_BATCH_DELAY_SECONDS` | — | `0.6` | 文字突發去彈跳靜默期 |
| `HERMES_FEISHU_TEXT_BATCH_MAX_MESSAGES` | — | `8` | 每個文字批次合併的最大訊息數 |
| `HERMES_FEISHU_TEXT_BATCH_MAX_CHARS` | — | `4000` | 每個文字批次合併的最大字元數 |
| `HERMES_FEISHU_MEDIA_BATCH_DELAY_SECONDS` | — | `0.8` | 媒體突發去彈跳靜默期 |

WebSocket 和每個群組的 ACL 設定透過 `config.yaml` 的 `platforms.feishu.extra` 進行配置。

## 疑難排解

| 問題 | 修復 |
|---------|-----|
| `lark-oapi not installed` | 安裝 SDK：`pip install lark-oapi` |
| `websockets not installed; websocket mode unavailable` | 安裝 websockets：`pip install websockets` |
| `aiohttp not installed; webhook mode unavailable` | 安裝 aiohttp：`pip install aiohttp` |
| `FEISHU_APP_ID or FEISHU_APP_SECRET not set` | 設定兩個環境變數或透過 `hermes gateway setup` 設定 |
| 「另一個本地 Hermes 網關已在使用此 Feishu app_id」 | 一個 app_id 同時只能由一個 Hermes 實例使用。請先停止另一個網關。 |
| 機器人在群組中不回應 | 確保已 @mention 機器人，檢查 `FEISHU_GROUP_POLICY`，若政策為 `allowlist` 則驗證寄件者是否在 `FEISHU_ALLOWED_USERS` 中 |
| `Webhook rejected: invalid verification token` | 確保 `FEISHU_VERIFICATION_TOKEN` 與飛書應用程式「事件訂閱」設定中的權杖一致 |
| `Webhook rejected: invalid signature` | 確保 `FEISHU_ENCRYPT_KEY` 與飛書應用設定中的加密金鑰一致 |
| 富文本訊息顯示為純文字 | 飛書 API 拒絕了 post 負載；這是正常的回退行為。請檢查日誌以獲取詳細資訊。 |
| 機器人未收到圖片/檔案 | 授予飛書應用程式 `im:message` 和 `im:resource` 權限範圍 |
| 機器人身份未自動偵測 | 授予 `admin:app.info:readonly` 權限範圍，或手動設定 `FEISHU_BOT_OPEN_ID` / `FEISHU_BOT_NAME` |
| 點擊核准按鈕時出現錯誤 200340 | 在飛書開發者後台啟用**互動式卡片**能力並設定**訊息卡片請求 URL**。見上方的[必要的飛書應用程式設定](#必要的飛書應用程式設定)。 |
| `Webhook rate limit exceeded` | 來自同一 IP 每分鐘超過 120 個請求。這通常是設定錯誤或迴圈導致的。 |

## 工具集 (Toolset)

飛書 (Feishu) / Lark 使用 `hermes-feishu` 平台預設集，其中包含與 Telegram 及其他基於網關的通訊平台相同的核心工具。
