---
sidebar_position: 15
title: "微信 (Weixin/WeChat)"
description: "透過 iLink 機器人 API 將 Hermes 代理程式連線至個人微信帳號"
---

# 微信 (Weixin/WeChat)

將 Hermes 連線至 [微信 (WeChat)](https://weixin.qq.com/)，這是騰訊的個人通訊平台。此轉接器針對個人微信帳號使用騰訊的 **iLink 機器人 API** —— 這與企業微信 (WeCom) 不同。訊息透過長輪詢 (Long-polling) 遞送，因此不需要公開端點或 Webhook。

:::info
此轉接器適用於**個人微信帳號** (微信)。如果您需要企業/公司微信，請參閱 [企業微信 (WeCom) 轉接器](./wecom.md)。
:::

## 前置條件

- 一個個人微信帳號。
- Python 套件：`aiohttp` 和 `cryptography`。
- `qrcode` 套件是選填的（用於設定期間在終端機渲染二維碼）。

安裝必要的依賴項：

```bash
pip install aiohttp cryptography
# 選填：用於在終端機顯示二維碼
pip install qrcode
```

## 設定

### 1. 執行設定精靈

連線微信帳號最簡單的方法是透過互動式設定：

```bash
hermes gateway setup
```

提示時選擇 **Weixin**。設定精靈將會：

1. 向 iLink 機器人 API 請求一個二維碼 (QR Code)。
2. 在您的終端機中顯示二維碼（或提供一個 URL）。
3. 等待您使用微信行動應用程式掃描二維碼。
4. 提示您在手機上確認登入。
5. 自動將帳號憑證儲存至 `~/.hermes/weixin/accounts/`。

確認後，您將看到如下訊息：

```
微信連接成功，account_id=your-account-id
```

精靈會儲存 `account_id`、`token` 和 `base_url`，因此您不需要手動設定它們。

### 2. 設定環境變數

初始二維碼登入後，請至少在 `~/.hermes/.env` 中設定帳號 ID：

```bash
WEIXIN_ACCOUNT_ID=your-account-id

# 選填：覆蓋權杖 (通常從二維碼登入自動儲存)
# WEIXIN_TOKEN=your-bot-token

# 選填：限制存取
WEIXIN_DM_POLICY=open
WEIXIN_ALLOWED_USERS=user_id_1,user_id_2

# 選填：恢復舊版多行分割行為
# WEIXIN_SPLIT_MULTILINE_MESSAGES=true

# 選填：用於排程任務/通知的主頻道
WEIXIN_HOME_CHANNEL=chat_id
WEIXIN_HOME_CHANNEL_NAME=Home
```

### 3. 啟動閘道器 (Gateway)

```bash
hermes gateway
```

轉接器將恢復儲存的憑證，連線至 iLink API，並開始長輪詢訊息。

## 功能

- **長輪詢傳輸** —— 不需要公開端點、Webhook 或 WebSocket。
- **二維碼登入** —— 透過 `hermes gateway setup` 進行掃描連線設定。
- **私訊與群組傳訊** —— 可設定存取策略。
- **媒體支援** —— 圖片、影片、檔案和語音訊息。
- **AES-128-ECB 加密 CDN** —— 所有媒體傳輸均進行自動加解密。
- **上下文權杖持久化** —— 支援跨重啟的磁碟備份回覆連續性。
- **Markdown 格式化** —— 標題、表格和程式碼區塊會針對微信的可讀性重新格式化。
- **智慧訊息分塊** —— 在限制範圍內的訊息保持單個對話泡泡；只有超長內容會在邏輯邊界處拆分。
- **輸入狀態指示器** —— 在代理程式處理時，在微信客戶端顯示「正在輸入...」狀態。
- **SSRF 防護** —— 在下載前驗證出站媒體 URL。
- **訊息去重** —— 5 分鐘滑動視窗防止重複處理。
- **自動重試與退避** —— 從暫時性的 API 錯誤中恢復。

## 設定選項

在 `config.yaml` 的 `platforms.weixin.extra` 下設定：

| 鍵名 | 預設值 | 說明 |
|-----|---------|-------------|
| `account_id` | — | iLink 機器人帳號 ID (必要) |
| `token` | — | iLink 機器人權杖 (必要，從二維碼登入自動儲存) |
| `base_url` | `https://ilinkai.weixin.qq.com` | iLink API 基礎 URL |
| `cdn_base_url` | `https://novac2c.cdn.weixin.qq.com/c2c` | 用於媒體傳輸的 CDN 基礎 URL |
| `dm_policy` | `open` | 私訊存取策略：`open`, `allowlist`, `disabled`, `pairing` |
| `group_policy` | `disabled` | 群組存取策略：`open`, `allowlist`, `disabled` |
| `allow_from` | `[]` | 允許私訊的使用者 ID (當 dm_policy=allowlist 時) |
| `group_allow_from` | `[]` | 允許的群組 ID (當 group_policy=allowlist 時) |
| `split_multiline_messages` | `false` | 為 `true` 時，將多行回覆拆分為多條聊天訊息（舊版行為）。為 `false` 時，除非超過長度限制，否則保持多行回覆為一條訊息。 |

## 存取策略

### 私訊策略 (DM Policy)

控制誰可以向機器人傳送私訊：

| 值 | 行為 |
|-------|----------|
| `open` | 任何人都可以向機器人傳送私訊 (預設) |
| `allowlist` | 僅限 `allow_from` 中的使用者 ID 可以傳送私訊 |
| `disabled` | 忽略所有私訊 |
| `pairing` | 配對模式 (用於初始設定) |

```bash
WEIXIN_DM_POLICY=allowlist
WEIXIN_ALLOWED_USERS=user_id_1,user_id_2
```

### 群組策略 (Group Policy)

控制機器人在哪些群組中進行回應：

| 值 | 行為 |
|-------|----------|
| `open` | 機器人在所有群組中回應 |
| `allowlist` | 機器人僅在 `group_allow_from` 列表中的群組 ID 回應 |
| `disabled` | 忽略所有群組訊息 (預設) |

```bash
WEIXIN_GROUP_POLICY=allowlist
WEIXIN_GROUP_ALLOWED_USERS=group_id_1,group_id_2
```

:::note
微信的預設群組策略為 `disabled`（與企業微信預設為 `open` 不同）。這是故意的，因為個人微信帳號可能會加入很多群組。
:::

## 媒體支援

### 入站 (接收)

轉接器接收來自使用者的媒體附件，從微信 CDN 下載、解密，並將其快取在本地供代理程式處理：

| 類型 | 如何處理 |
|------|-----------------| 
| **圖片** | 下載、AES 解密並快取為 JPEG。 |
| **影片** | 下載、AES 解密並快取為 MP4。 |
| **檔案** | 下載、AES 解密並快取。保留原始檔案名稱。 |
| **語音** | 如果有文字轉錄，則提取為文字。否則下載音訊（SILK 格式）並快取。 |

**引用訊息：** 也會提取被引用（回覆）訊息中的媒體，以便代理程式了解使用者正在回覆的內容背景。

### AES-128-ECB 加密 CDN

微信媒體檔案透過加密的 CDN 進行傳輸。轉接器會透明地處理：

- **入站：** 使用 `encrypted_query_param` URL 從 CDN 下載加密媒體，然後使用訊息有效負載中提供的個別檔案金鑰進行 AES-128-ECB 解密。
- **出站：** 檔案在本地使用隨機 AES-128-ECB 金鑰進行加密，上傳到 CDN，並將加密參考包含在出站訊息中。
- AES 金鑰為 16 位元組（128 位元）。金鑰可能以原始 base64 或十六進位編碼形式送達 —— 轉接器支援這兩種格式。
- 這需要 `cryptography` Python 套件。

無需任何設定 —— 加密和解密會自動發生。

### 出站 (傳送)

| 方法 | 傳送內容 |
|--------|--------------|
| `send` | 具有 Markdown 格式化的文字訊息 | 
| `send_image` / `send_image_file` | 原生圖片訊息（透過 CDN 上傳） |
| `send_document` | 檔案附件（透過 CDN 上傳） |
| `send_video` | 影片訊息（透過 CDN 上傳） |

所有出站媒體都經過加密的 CDN 上傳流程：

1. 產生隨機 AES-128 金鑰。
2. 使用 AES-128-ECB + PKCS#7 填充加密檔案。
3. 向 iLink API 請求上傳 URL (`getuploadurl`)。
4. 將密文上傳到 CDN。
5. 傳送包含加密媒體參考的訊息。

## 上下文權杖持久化 (Context Token Persistence)

iLink 機器人 API 要求針對給定的對象，每個出站訊息都要回傳一個 `context_token`。轉接器維護一個基於磁碟的上下文權杖儲存：

- 權杖按 帳號+對象 儲存至 `~/.hermes/weixin/accounts/<account_id>.context-tokens.json`。
- 啟動時，恢復先前儲存的權杖。
- 每個入站訊息都會更新該傳送者的儲存權杖。
- 出站訊息自動包含最新的上下文權杖。

這確保了即使在閘道器重啟後回覆也能保持連續性。

## Markdown 格式化

微信個人聊天原生不支援渲染完整的 Markdown。轉接器重新格式化內容以獲得更好的可讀性：

- **標題** (`# Title`) → 轉換為 `【Title】`（第 1 級）或 `**Title**`（第 2 級以上）。
- **表格** → 重新格式化為標記的鍵值列表（例如 `- 欄位: 值`）。
- **程式碼區塊** → 保持原樣（微信能適當地渲染這些）。
- **過多的空行** → 摺疊為雙換行。

## 訊息分塊 (Message Chunking)

只要訊息符合平台限制，就會作為單條聊天訊息遞送。只有超長的內容才會拆分遞送：

- 最大訊息長度：**4000 字元**。
- 低於限制的訊息即使包含多個段落或換行也會保持完整。
- 超長訊息在邏輯邊界處拆分（段落、空行、程式碼區塊）。
- 程式碼區塊盡可能保持完整（除非區塊本身超過限制，否則絕不在中間拆分）。
- 超長的個別區塊會回退到基礎轉接器的截斷邏輯。
- 0.3 秒的塊間延遲可防止傳送多個塊時被微信速率限制攔截。

## 輸入狀態指示器

轉接器在微信客戶端中顯示輸入狀態：

1. 當訊息到達時，轉接器透過 `getconfig` API 獲取一個 `typing_ticket`。
2. 輸入狀態票據每位使用者快取 10 分鐘。
3. `send_typing` 傳送開始輸入訊號；`stop_typing` 傳送停止輸入訊號。
4. 閘道器在代理程式處理訊息期間自動觸發輸入狀態指示器。

## 長輪詢連線 (Long-Poll)

轉接器使用 HTTP 長輪詢（而非 WebSocket）接收訊息：

### 運作原理

1. **連線 (Connect)：** 驗證憑證並開始輪詢迴圈。
2. **輪詢 (Poll)：** 呼叫 `getupdates` 並設置 35 秒逾時；伺服器會保持請求直到訊息到達或逾時。
3. **分派 (Dispatch)：** 入站訊息透過 `asyncio.create_task` 並行分派。
4. **同步緩衝區：** 持久的同步游標 (`get_updates_buf`) 會儲存到磁碟，以便轉接器在重啟後從正確位置恢復。

### 重試行為

發生 API 錯誤時，轉接器使用簡單的重試策略：

| 狀況 | 行為 |
|-----------|----------|
| 暫時性錯誤 (第 1–2 次) | 2 秒後重試 |
| 重複錯誤 (3 次以上) | 退避 30 秒，然後重設計數器 |
| 階段過期 (`errcode=-14`) | 暫停 10 分鐘（可能需要重新登入） |
| 逾時 | 立即重新輪詢（正常的長輪詢行為） |

### 去重 (Deduplication)

入站訊息使用訊息 ID 進行去重，滑動視窗為 5 分鐘。這可以防止在網路波動或重疊的輪詢回應期間重複處理。

### 權杖鎖 (Token Lock)

一次只能有一個微信閘道器實例使用給定的權杖。轉接器在啟動時獲取限定範圍鎖，並在關機時釋放。如果另一個閘道器已在使用相同的權杖，啟動將失敗並顯示提示訊息。

## 所有環境變數

| 變數 | 必要 | 預設值 | 說明 |
|----------|----------|---------|-------------|
| `WEIXIN_ACCOUNT_ID` | ✅ | — | iLink 機器人帳號 ID (來自二維碼登入) |
| `WEIXIN_TOKEN` | ✅ | — | iLink 機器人權杖 (從二維碼登入自動儲存) |
| `WEIXIN_BASE_URL` | — | `https://ilinkai.weixin.qq.com` | iLink API 基礎 URL |
| `WEIXIN_CDN_BASE_URL` | — | `https://novac2c.cdn.weixin.qq.com/c2c` | 用於媒體傳輸的 CDN 基礎 URL |
| `WEIXIN_DM_POLICY` | — | `open` | 私訊存取策略：`open`, `allowlist`, `disabled`, `pairing` |
| `WEIXIN_GROUP_POLICY` | — | `disabled` | 群組存取策略：`open`, `allowlist`, `disabled` |
| `WEIXIN_ALLOWED_USERS` | — | _(空)_ | 用於私訊允許列表的逗號分隔使用者 ID |
| `WEIXIN_GROUP_ALLOWED_USERS` | — | _(空)_ | 用於群組允許列表的逗號分隔群組 ID |
| `WEIXIN_HOME_CHANNEL` | — | — | 用於排程任務/通知輸出的聊天 ID |
| `WEIXIN_HOME_CHANNEL_NAME` | — | `Home` | 主頻道的顯示名稱 |
| `WEIXIN_ALLOW_ALL_USERS` | — | — | 允許所有使用者的閘道器層級標記（由設定精靈使用） |

## 疑難排解

| 問題 | 解決方法 |
|---------|-----|
| `Weixin startup failed: aiohttp and cryptography are required` | 安裝兩者：`pip install aiohttp cryptography` |
| `Weixin startup failed: WEIXIN_TOKEN is required` | 執行 `hermes gateway setup` 完成二維碼登入，或手動設定 `WEIXIN_TOKEN` |
| `Weixin startup failed: WEIXIN_ACCOUNT_ID is required` | 在您的 `.env` 中設定 `WEIXIN_ACCOUNT_ID` 或執行 `hermes gateway setup` |
| `Another local Hermes gateway is already using this Weixin token` | 先停止另一個閘道器實例 —— 每個權杖僅允許一個輪詢器 |
| 階段過期 (`errcode=-14`) | 您的登入階段已過期。重新執行 `hermes gateway setup` 以掃描新的二維碼 |
| 設定期間二維碼過期 | 二維碼最多自動重整 3 次。如果持續過期，請檢查您的網路連線 |
| 機器人未回應私訊 | 檢查 `WEIXIN_DM_POLICY` —— 如果設定為 `allowlist`，傳送者必須在 `WEIXIN_ALLOWED_USERS` 中 |
| 機器人忽略群組訊息 | 群組策略預設為 `disabled`。請將 `WEIXIN_GROUP_POLICY` 設定為 `open` 或 `allowlist` |
| 媒體下載/上傳失敗 | 確保已安裝 `cryptography`。檢查對 `novac2c.cdn.weixin.qq.com` 的網路存取 |
| `Blocked unsafe URL (SSRF protection)` | 出站媒體 URL 指向私有/內部地址。僅允許公開 URL |
| 語音訊息顯示為文字 | 如果微信提供了轉錄，轉接器會使用該文字。這是預期行為 |
| 訊息出現重複 | 轉接器按訊息 ID 去重。如果您看到重複訊息，請檢查是否有多個閘道器實例在執行 |
| `iLink POST ... HTTP 4xx/5xx` | 來自 iLink 服務的 API 錯誤。檢查您的權杖有效性和網路連線 |
| 終端機二維碼未渲染 | 安裝 `qrcode`：`pip install qrcode`。或者，開啟二維碼上方列印的 URL |
