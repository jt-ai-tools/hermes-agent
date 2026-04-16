---
sidebar_position: 14
title: "企業微信 (WeCom)"
description: "透過 AI 機器人 WebSocket 閘道器將 Hermes 代理程式連線至企業微信"
---

# 企業微信 (WeCom)

將 Hermes 連線至 [企業微信 (WeCom)](https://work.weixin.qq.com/)，這是騰訊的企業通訊平台。此轉接器使用企業微信的 AI 機器人 WebSocket 閘道器進行即時雙向通訊 —— 無需公開端點或 Webhook。

## 前置條件

- 一個企業微信組織帳號。
- 在企業微信管理後台建立的 AI 機器人。
- 來自機器人憑證頁面的機器人 ID (Bot ID) 和金鑰 (Secret)。
- Python 套件：`aiohttp` 和 `httpx`。

## 設定

### 1. 建立 AI 機器人

1. 登入 [企業微信管理後台](https://work.weixin.qq.com/wework_admin/frame)。
2. 導覽至 **應用管理** → **建立應用** → **AI 機器人**。
3. 設定機器人名稱和描述。
4. 從憑證頁面複製 **機器人 ID (Bot ID)** 和 **金鑰 (Secret)**。

### 2. 設定 Hermes

執行互動式設定：

```bash
hermes gateway setup
```

選擇 **WeCom** 並輸入您的機器人 ID 和金鑰。

或者在 `~/.hermes/.env` 中設定環境變數：

```bash
WECOM_BOT_ID=your-bot-id
WECOM_SECRET=your-secret

# 選填：限制存取
WECOM_ALLOWED_USERS=user_id_1,user_id_2

# 選填：用於排程任務/通知的主頻道
WECOM_HOME_CHANNEL=chat_id
```

### 3. 啟動閘道器 (Gateway)

```bash
hermes gateway
```

## 功能

- **WebSocket 傳輸** —— 持久連線，無需公開端點。
- **私訊與群組傳訊** —— 可設定存取策略。
- **針對個別群組的傳送者允許列表** —— 精細控制誰可以在每個群組中進行互動。
- **媒體支援** —— 圖片、檔案、語音、影片的下載與上傳。
- **AES 加密媒體** —— 對入站附件進行自動解密。
- **引用上下文** —— 保留回覆執行緒。
- **Markdown 渲染** —— 豐富文字回應。
- **回覆模式串流** —— 將回應與入站訊息上下文關聯。
- **自動重新連線** —— 連線中斷時採用指數退避 (Exponential Backoff)。

## 設定選項

在 `config.yaml` 的 `platforms.wecom.extra` 下設定：

| 鍵名 | 預設值 | 說明 |
|-----|---------|-------------|
| `bot_id` | — | 企業微信 AI 機器人 ID (必要) |
| `secret` | — | 企業微信 AI 機器人金鑰 (必要) |
| `websocket_url` | `wss://openws.work.weixin.qq.com` | WebSocket 閘道器 URL |
| `dm_policy` | `open` | 私訊存取策略：`open`, `allowlist`, `disabled`, `pairing` |
| `group_policy` | `open` | 群組存取策略：`open`, `allowlist`, `disabled` |
| `allow_from` | `[]` | 允許私訊的使用者 ID (當 dm_policy=allowlist 時) |
| `group_allow_from` | `[]` | 允許的群組 ID (當 group_policy=allowlist 時) |
| `groups` | `{}` | 針對個別群組的設定 (參見下文) |

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
WECOM_DM_POLICY=allowlist
```

### 群組策略 (Group Policy)

控制機器人在哪些群組中進行回應：

| 值 | 行為 |
|-------|----------|
| `open` | 機器人在所有群組中回應 (預設) |
| `allowlist` | 機器人僅在 `group_allow_from` 列表中的群組 ID 回應 |
| `disabled` | 忽略所有群組訊息 |

```bash
WECOM_GROUP_POLICY=allowlist
```

### 個別群組的傳送者允許列表

為了進行精細控制，您可以限制特定群組內允許與機器人互動的使用者。這在 `config.yaml` 中設定：

```yaml
platforms:
  wecom:
    enabled: true
    extra:
      bot_id: "your-bot-id"
      secret: "your-secret"
      group_policy: "allowlist"
      group_allow_from:
        - "group_id_1"
        - "group_id_2"
      groups:
        group_id_1:
          allow_from:
            - "user_alice"
            - "user_bob"
        group_id_2:
          allow_from:
            - "user_charlie"
        "*":
          allow_from:
            - "user_admin"
```

**運作原理：**

1. `group_policy` 和 `group_allow_from` 控制項決定是否允許該群組。
2. 如果群組通過了頂層檢查，`groups.<group_id>.allow_from` 列表（如果存在）會進一步限制該群組內哪些傳送者可以與機器人互動。
3. 萬用字元 `"*"` 群組項目作為未明確列出群組的預設設定。
4. 允許列表項目支援 `*` 萬用字元以允許所有使用者，且項目不區分大小寫。
5. 項目可以選擇使用 `wecom:user:` 或 `wecom:group:` 前綴格式 —— 前綴會被自動移除。

如果未針對群組設定 `allow_from`，則該群組中的所有使用者均被允許（前提是群組本身通過了頂層策略檢查）。

## 媒體支援

### 入站 (接收)

轉接器接收來自使用者的媒體附件並將其快取在本地供代理程式處理：

| 類型 | 如何處理 |
|------|-----------------|
| **圖片** | 下載並快取在本地。支援基於 URL 和 base64 編碼的圖片。 |
| **檔案** | 下載並快取。保留原始訊息中的檔案名稱。 |
| **語音** | 如果可用，將提取語音訊息文字轉錄。 |
| **混合訊息** | 解析企業微信混合類型訊息（文字 + 圖片）並提取所有組件。 |

**引用訊息：** 也會提取被引用（回覆）訊息中的媒體，以便代理程式了解使用者正在回覆的內容背景。

### AES 加密媒體解密

企業微信使用 AES-256-CBC 加密某些入站媒體附件。轉接器會自動處理：

- 當入站媒體項目包含 `aeskey` 欄位時，轉接器下載加密位元組並使用具有 PKCS#7 填充的 AES-256-CBC 進行解密。
- AES 金鑰是 `aeskey` 欄位的 base64 解碼值（必須精確為 32 位元組）。
- IV 衍生自金鑰的前 16 個位元組。
- 這需要 `cryptography` Python 套件 (`pip install cryptography`)。

無需任何設定 —— 當收到加密媒體時，解密會透明地發生。

### 出站 (傳送)

| 方法 | 傳送內容 | 大小限制 |
|--------|--------------|------------|
| `send` | Markdown 文字訊息 | 4000 字元 |
| `send_image` / `send_image_file` | 原生圖片訊息 | 10 MB |
| `send_document` | 檔案附件 | 20 MB |
| `send_voice` | 語音訊息 (原生語音僅限 AMR 格式) | 2 MB |
| `send_video` | 影片訊息 | 10 MB |

**分塊上傳：** 檔案透過三步驟協定（初始化 → 分塊 → 完成）以 512 KB 分塊上傳。轉接器會自動處理。

**自動降級：** 當媒體超過原生類型的大小限制但低於絕對 20 MB 檔案限制時，會自動改為以一般檔案附件形式傳送：

- 圖片 > 10 MB → 作為檔案傳送
- 影片 > 10 MB → 作為檔案傳送
- 語音 > 2 MB → 作為檔案傳送
- 非 AMR 音訊 → 作為檔案傳送（企業微信僅針對原生語音支援 AMR）

超過絕對 20 MB 限制的檔案將被拒絕，並向聊天中傳送提示訊息。

## 回覆模式串流回應 (Reply-Mode Stream)

當機器人透過企業微信回呼收到訊息時，轉接器會記住入站請求 ID。如果在請求上下文仍然有效時傳送回應，轉接器會使用企業微信的回覆模式 (`aibot_respond_msg`) 配合串流技術，將回應直接與入站訊息關聯。這在企業微信用戶端中提供了更自然的對話體驗。

如果入站請求上下文已過期或不可用，轉接器會回退到透過 `aibot_send_msg` 主動傳送訊息。

回覆模式也適用於媒體：上傳的媒體可以作為對原始訊息的回覆傳送。

## 連線與重新連線

轉接器維持與企業微信閘道器 (`wss://openws.work.weixin.qq.com`) 的持久 WebSocket 連線。

### 連線生命週期

1. **連線 (Connect)：** 開啟 WebSocket 連線並傳送包含 bot_id 和 secret 的 `aibot_subscribe` 身分驗證訊框。
2. **心跳 (Heartbeat)：** 每 30 秒傳送應用層級的 ping 訊框以維持連線。
3. **監聽 (Listen)：** 持續讀取入站訊框並分派訊息回呼。

### 重新連線行為

當連線遺失時，轉接器會使用指數退避進行重新連線：

| 嘗試次數 | 延遲時間 |
|---------|-------|
| 第 1 次重試 | 2 秒 |
| 第 2 次重試 | 5 秒 |
| 第 3 次重試 | 10 秒 |
| 第 4 次重試 | 30 秒 |
| 第 5 次及以後 | 60 秒 |

每次成功連線後，退避計數器都會重設為零。連線中斷時，所有待處理的請求都會失敗，以防止呼叫者無限期掛起。

### 去重 (Deduplication)

入站訊息使用訊息 ID 進行去重，視窗時間為 5 分鐘，最大快取為 1000 個項目。這可以防止在重新連線或網路波動期間重複處理訊息。

## 所有環境變數

| 變數 | 必要 | 預設值 | 說明 |
|----------|----------|---------|-------------|
| `WECOM_BOT_ID` | ✅ | — | 企業微信 AI 機器人 ID |
| `WECOM_SECRET` | ✅ | — | 企業微信 AI 機器人金鑰 |
| `WECOM_ALLOWED_USERS` | — | _(空)_ | 用於閘道器層級允許列表的逗號分隔使用者 ID |
| `WECOM_HOME_CHANNEL` | — | — | 用於排程任務/通知輸出的聊天 ID |
| `WECOM_WEBSOCKET_URL` | — | `wss://openws.work.weixin.qq.com` | WebSocket 閘道器 URL |
| `WECOM_DM_POLICY` | — | `open` | 私訊存取策略 |
| `WECOM_GROUP_POLICY` | — | `open` | 群組存取策略 |

## 疑難排解

| 問題 | 解決方法 |
|---------|-----|
| `WECOM_BOT_ID and WECOM_SECRET are required` | 設定這兩個環境變數或在設定精靈中進行設定 |
| `WeCom startup failed: aiohttp not installed` | 安裝 aiohttp：`pip install aiohttp` |
| `WeCom startup failed: httpx not installed` | 安裝 httpx：`pip install httpx` |
| `invalid secret (errcode=40013)` | 驗證金鑰是否與您的機器人憑證匹配 |
| `Timed out waiting for subscribe acknowledgement` | 檢查與 `openws.work.weixin.qq.com` 的網路連線 |
| 機器人未在群組中回應 | 檢查 `group_policy` 設定並確保群組 ID 在 `group_allow_from` 中 |
| 機器人忽略群組中的特定使用者 | 檢查 `groups` 設定區段中的個別群組 `allow_from` 列表 |
| 媒體解密失敗 | 安裝 `cryptography`：`pip install cryptography` |
| `cryptography is required for WeCom media decryption` | 入站媒體已加密。安裝：`pip install cryptography` |
| 語音訊息以檔案形式傳送 | 企業微信的原生語音僅支援 AMR 格式。其他格式會自動降級為檔案。 |
| `File too large` 錯誤 | 企業微信對所有檔案上傳有 20 MB 的絕對限制。請壓縮或分割檔案。 |
| 圖片以檔案形式傳送 | 超過 10 MB 的圖片超過了原生圖片限制，會自動降級為檔案附件。 |
| `Timeout sending message to WeCom` | WebSocket 可能已斷開。檢查日誌中的重新連線訊息。 |
| `WeCom websocket closed during authentication` | 網路問題或憑證錯誤。請驗證 bot_id 和 secret。 |
