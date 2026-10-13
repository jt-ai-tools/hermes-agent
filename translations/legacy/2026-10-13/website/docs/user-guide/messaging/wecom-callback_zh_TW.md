---
sidebar_position: 15
---

# 企業微信回呼 (WeCom Callback - 自建應用程式)

將 Hermes 連線至企業微信 (WeCom) 作為自建應用程式，使用回呼 (Callback)/Webhook 模式。

:::info 企業微信機器人 vs 企業微信回呼
Hermes 支援兩種企業微信整合模式：
- **[企業微信機器人 (WeCom Bot)](wecom.md)** —— 機器人模式，透過 WebSocket 連線。設定較簡單，可在群組聊天中使用。
- **企業微信回呼 (WeCom Callback)**（本頁面）—— 自建應用程式，接收加密的 XML 回呼。在使用者企業微信側邊欄顯示為一級應用程式。支援多企業路由。
:::

## 運作原理

1. 您在企業微信管理後台註冊一個自建應用程式。
2. 企業微信將加密的 XML 推送到您的 HTTP 回呼端點。
3. Hermes 解密訊息，並將其排入代理程式的隊列中。
4. 立即確認收到訊息（靜默 —— 使用者端不會顯示任何內容）。
5. 代理程式處理請求（通常需要 3–30 分鐘）。
6. 回覆透過企業微信的 `message/send` API 主動傳送。

## 前置條件

- 具有管理員存取權限的企業微信帳號。
- `aiohttp` 和 `httpx` Python 套件（已包含在預設安裝中）。
- 用於回呼 URL 的公開存取伺服器（或像 ngrok 的隧道）。

## 設定

### 1. 在企業微信中建立自建應用程式

1. 前往 [企業微信管理後台](https://work.weixin.qq.com/) → **應用管理** → **建立應用**。
2. 記下您的 **企業 ID (Corp ID)**（顯示在管理後台頂部）。
3. 在應用程式設定中，建立一個 **企業金鑰 (Corp Secret)**。
4. 從應用程式的概覽頁面記下 **應用程式 ID (Agent ID)**。
5. 在 **接收訊息** 下，設定回呼 URL：
   - URL: `http://您的公開_IP:8645/wecom/callback`
   - Token: 產生隨機權杖（企業微信會提供一個）。
   - EncodingAESKey: 產生金鑰（企業微信會提供一個）。

### 2. 設定環境變數

在您的 `.env` 檔案中加入：

```bash
WECOM_CALLBACK_CORP_ID=your-corp-id
WECOM_CALLBACK_CORP_SECRET=your-corp-secret
WECOM_CALLBACK_AGENT_ID=1000002
WECOM_CALLBACK_TOKEN=your-callback-token
WECOM_CALLBACK_ENCODING_AES_KEY=your-43-char-aes-key

# 選填
WECOM_CALLBACK_HOST=0.0.0.0
WECOM_CALLBACK_PORT=8645
WECOM_CALLBACK_ALLOWED_USERS=user1,user2
```

### 3. 啟動閘道器 (Gateway)

```bash
hermes gateway start
```

回呼轉接器會在設定的連接埠上啟動一個 HTTP 伺服器。企業微信將透過 GET 請求驗證回呼 URL，然後開始透過 POST 傳送訊息。

## 設定參考

在 `config.yaml` 的 `platforms.wecom_callback.extra` 下設定，或使用環境變數：

| 設定項目 | 預設值 | 說明 |
|---------|---------|-------------|
| `corp_id` | — | 企業微信企業 ID (必要) |
| `corp_secret` | — | 自建應用程式的企業金鑰 (必要) |
| `agent_id` | — | 自建應用程式的應用程式 ID (必要) |
| `token` | — | 回呼驗證權杖 (必要) |
| `encoding_aes_key` | — | 用於回呼加密的 43 字元 AES 金鑰 (必要) |
| `host` | `0.0.0.0` | HTTP 回呼伺服器的繫結位址 |
| `port` | `8645` | HTTP 回呼伺服器的連接埠 |
| `path` | `/wecom/callback` | 回呼端點的 URL 路徑 |

## 多應用路由

對於執行多個自建應用程式的企業（例如跨不同部門或子公司），請在 `config.yaml` 中設定 `apps` 列表：

```yaml
platforms:
  wecom_callback:
    enabled: true
    extra:
      host: "0.0.0.0"
      port: 8645
      apps:
        - name: "dept-a"
          corp_id: "ww_corp_a"
          corp_secret: "secret-a"
          agent_id: "1000002"
          token: "token-a"
          encoding_aes_key: "key-a-43-chars..."
        - name: "dept-b"
          corp_id: "ww_corp_b"
          corp_secret: "secret-b"
          agent_id: "1000003"
          token: "token-b"
          encoding_aes_key: "key-b-43-chars..."
```

使用者受 `corp_id:user_id` 限定範圍以防止跨企業衝突。當使用者傳送訊息時，轉接器會記錄他們屬於哪個應用程式（企業），並透過正確應用程式的存取權杖（Access Token）路由回覆。

## 存取控制

限制哪些使用者可以與應用程式互動：

```bash
# 僅允許特定使用者
WECOM_CALLBACK_ALLOWED_USERS=zhangsan,lisi,wangwu

# 或允許所有使用者
WECOM_CALLBACK_ALLOW_ALL_USERS=true
```

## 端點 (Endpoints)

轉接器公開以下端點：

| 方法 | 路徑 | 用途 |
|--------|------|---------|
| GET | `/wecom/callback` | URL 驗證握手（企業微信在設定期間傳送此請求） |
| POST | `/wecom/callback` | 加密訊息回呼（企業微信在此傳送使用者訊息） |
| GET | `/health` | 健康檢查 —— 返回 `{"status": "ok"}` |

## 加密

所有回呼有效負載均使用 EncodingAESKey 進行 AES-CBC 加密。轉接器負責處理：

- **入站**：解密 XML 有效負載，驗證 SHA1 簽章
- **出站**：透過主動 API 傳送回覆（非加密回呼回應）

加解密實作與騰訊官方的 WXBizMsgCrypt SDK 相容。

## 限制

- **不支援串流** —— 回覆在代理程式完成後以完整訊息形式送達。
- **無輸入狀態指示器** —— 回呼模式不支援顯示「正在輸入...」。
- **僅限文字** —— 目前僅支援文字訊息輸入；圖片/檔案/語音輸入尚未實作。代理程式透過企業微信平台提示（圖片、文件、影片、語音）了解出站媒體功能。
- **回應延遲** —— 代理程式階段需要 3–30 分鐘；使用者在處理完成後會看到回覆。
