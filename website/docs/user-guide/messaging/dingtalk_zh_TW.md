---
sidebar_position: 10
title: "釘釘 (DingTalk)"
description: "將 Hermes Agent 設定為釘釘機器人"
---

# 釘釘 (DingTalk) 設定

Hermes Agent 可作為聊天機器人整合到釘釘 (DingTalk) 中，讓您透過私訊或群組對話與您的 AI 助理聊天。機器人透過釘釘的「串流模式 (Stream Mode)」連線 — 這是一種長連接的 WebSocket 連線，不需要公開的 URL 或 Webhook 伺服器 — 並透過釘釘的對話 Webhook API 使用 Markdown 格式回覆訊息。

在設定之前，這裡是大多數人想知道的部分：Hermes 進入您的釘釘工作區後的行為。

## Hermes 的行為

| 情境 | 行為 |
|---------|----------|
| **私訊 (1:1 對話)** | Hermes 會回應每條訊息。無需 `@mention`（標記）。每條私訊都有自己的對話階段 (Session)。 |
| **群組對話** | 當您 `@mention` 它時，Hermes 就會回應。如果沒有標記，Hermes 會忽略該訊息。 |
| **多人共用的群組** | 預設情況下，Hermes 在群組內會隔離每個使用者的對話歷史。在同一個群組中對話的兩個人不會共用同一個紀錄，除非您明確停用該功能。 |

### 釘釘中的對話模型

預設情況下：

- 每條私訊都有自己的對話階段
- 共用群組對話中的每個使用者在該群組內都有自己的對話階段

這由 `config.yaml` 控制：

```yaml
group_sessions_per_user: true
```

僅當您明確希望整個群組共用一個對話時，才將其設定為 `false`：

```yaml
group_sessions_per_user: false
```

本指南將引導您完成整個設定過程 — 從建立釘釘機器人到傳送第一條訊息。

## 前提條件

安裝必要的 Python 套件：

```bash
pip install dingtalk-stream httpx
```

- `dingtalk-stream` — 釘釘官方提供的串流模式 SDK（基於 WebSocket 的即時訊息）
- `httpx` — 用於透過對話 Webhook 傳送回覆的非同步 HTTP 用戶端

## 步驟 1：建立釘釘應用程式

1. 前往 [釘釘開放平台 (DingTalk Developer Console)](https://open-dev.dingtalk.com/)。
2. 使用您的釘釘管理員帳號登入。
3. 點擊 **應用開發** → **企業內部開發** → **釘釘應用** → **建立應用**。
4. 填寫：
   - **應用名稱 (App Name)**: 例如 `Hermes Agent`
   - **應用描述 (Description)**: 選填
5. 建立後，前往 **憑據與基礎資訊** 找到您的 **Client ID** (AppKey) 和 **Client Secret** (AppSecret)。複製這兩者。

:::warning[憑據僅顯示一次]
Client Secret 僅在您建立應用程式時顯示一次。如果您遺失了它，則需要重新產生。切勿公開分享這些憑據或將其提交到 Git。
:::

## 步驟 2：啟用機器人功能

1. 在應用程式設定頁面中，前往 **添加能力** → **機器人**。
2. 啟用機器人功能。
3. 在 **消息接收模式** 下，選擇 **串流模式 (Stream Mode)**（推薦 — 不需要公開 URL）。

:::tip
推薦使用串流模式。它使用從您的機器發起的長連接 WebSocket 連線，因此您不需要公開 IP、網域名稱或 Webhook 端點。這在 NAT、防火牆後方以及本地機器上都能運作。
:::

## 步驟 3：尋找您的釘釘使用者 ID

Hermes Agent 使用您的釘釘使用者 ID (User ID) 來控制誰可以與機器人互動。釘釘使用者 ID 是由組織管理員設定的英數字串。

尋找您 ID 的方法：

1. 詢問您的釘釘組織管理員 — 使用者 ID 在釘釘管理後台的 **通訊錄** → **成員** 下設定。
2. 或者，機器人會記錄每條傳入訊息的 `sender_id`。啟動網關，向機器人傳送一條訊息，然後檢查日誌以獲取您的 ID。

## 步驟 4：設定 Hermes Agent

### 選項 A：互動式設定（推薦）

執行引導式設定指令：

```bash
hermes gateway setup
```

出現提示時選擇 **DingTalk**，然後根據要求貼上您的 Client ID、Client Secret 和允許的使用者 ID。

### 選項 B：手動設定

將以下內容新增到您的 `~/.hermes/.env` 檔案中：

```bash
# 必要
DINGTALK_CLIENT_ID=your-app-key
DINGTALK_CLIENT_SECRET=your-app-secret

# 安全性：限制誰可以與機器人互動
DINGTALK_ALLOWED_USERS=user-id-1

# 多個允許的使用者（以逗號分隔）
# DINGTALK_ALLOWED_USERS=user-id-1,user-id-2
```

`~/.hermes/config.yaml` 中的選填行為設定：

```yaml
group_sessions_per_user: true
```

- `group_sessions_per_user: true` 可保持共用群組對話中每個參與者的上下文隔離。

### 啟動網關

設定完成後，啟動釘釘網關：

```bash
hermes gateway
```

機器人應該會在幾秒鐘內連線到釘釘的串流模式。傳送一條訊息給它 — 可以是私訊，也可以是在已加入的群組中 — 進行測試。

:::tip
您可以讓 `hermes gateway` 在背景運行，或將其作為 systemd 服務運行以實現持久操作。詳情請參閱部署文件。
:::

## 疑難排解

### 機器人未回應訊息

**原因**：機器人功能未啟用，或者 `DINGTALK_ALLOWED_USERS` 未包含您的使用者 ID。

**修復**：驗證應用程式設定中已啟用機器人功能，且已選擇串流模式。檢查您的使用者 ID 是否在 `DINGTALK_ALLOWED_USERS` 中。重啟網關。

### 「dingtalk-stream 未安裝」錯誤

**原因**：未安裝 `dingtalk-stream` Python 套件。

**修復**：安裝它：

```bash
pip install dingtalk-stream httpx
```

### 「需要 DINGTALK_CLIENT_ID 和 DINGTALK_CLIENT_SECRET」

**原因**：環境或 `.env` 檔案中未設定憑據。

**修復**：驗證 `~/.hermes/.env` 中已正確設定 `DINGTALK_CLIENT_ID` 和 `DINGTALK_CLIENT_SECRET`。Client ID 是您的 AppKey，Client Secret 是釘釘開放平台中的 AppSecret。

### 串流斷開 / 重新連線迴圈

**原因**：網路不穩定、釘釘平台維護或憑據問題。

**修復**：適配器會以指數退避 (exponential backoff) 自動重新連線（2秒 → 5秒 → 10秒 → 30秒 → 60秒）。檢查您的憑據是否有效，以及您的應用程式是否未被停用。驗證您的網路允許外出的 WebSocket 連線。

### 機器人離線

**原因**：Hermes 網關未運行，或連線失敗。

**修復**：檢查 `hermes gateway` 是否正在運行。查看終端輸出以獲取錯誤訊息。常見問題：憑據錯誤、應用程式被停用、未安裝 `dingtalk-stream` 或 `httpx`。

### 「沒有可用的 session_webhook」

**原因**：機器人嘗試回覆但沒有對話 Webhook URL。這通常發生在 Webhook 過期，或是在接收訊息與傳送回覆之間機器人重啟的情況下。

**修復**：向機器人傳送一條新訊息 — 每條傳入訊息都會提供一個新的對話 Webhook 用於回覆。這是釘釘的正常限制；機器人只能回覆最近收到的訊息。

## 安全性

:::warning
務必設定 `DINGTALK_ALLOWED_USERS` 以限制誰可以與機器人互動。如果未設定，作為一項安全措施，網關預設會拒絕所有使用者。僅新增您信任的人的使用者 ID — 授權使用者擁有存取代理能力的完全權限，包括工具使用和系統存取。
:::

有關保護 Hermes Agent 部署的更多資訊，請參閱 [安全性指南](../security.md)。

## 附註

- **串流模式 (Stream Mode)**：不需要公開 URL、網域名稱或 Webhook 伺服器。連線是從您的機器透過 WebSocket 發起的，因此可以在 NAT 和防火牆後運作。
- **Markdown 回覆**：回覆採用釘釘的 Markdown 格式，以實現富文本顯示。
- **訊息去重**：適配器會在 5 分鐘的視窗內對訊息進行去重，以防止重複處理同一條訊息。
- **自動重新連線**：如果串流連線中斷，適配器會以指數退避自動重新連線。
- **訊息長度限制**：每條訊息的回覆上限為 20,000 個字元。較長的回覆將被截斷。
