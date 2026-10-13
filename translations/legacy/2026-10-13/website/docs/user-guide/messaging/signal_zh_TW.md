---
sidebar_position: 6
title: "Signal"
description: "透過 signal-cli 守護程序將 Hermes Agent 設定為 Signal 機器人"
---

# Signal 設定

Hermes 透過以 HTTP 模式執行的 [signal-cli](https://github.com/AsamK/signal-cli) 守護程序 (daemon) 連接到 Signal。適配器透過 SSE (Server-Sent Events) 即時串流訊息，並透過 JSON-RPC 發送回應。

Signal 是最注重隱私的主流通訊軟體 —— 預設端到端加密、開源協定、極少量的元數據 (metadata) 收集。這使其成為處理安全性敏感工作流的理想選擇。

:::info 無須新增 Python 依賴項目
Signal 適配器使用 `httpx`（這已經是 Hermes 的核心依賴項）進行所有通訊。不需要額外的 Python 套件，您只需要在外部安裝好 signal-cli。
:::

---

## 前置作業

- **signal-cli** — 基於 Java 的 Signal 客戶端 ([GitHub](https://github.com/AsamK/signal-cli))
- **Java 17+** 執行環境 — signal-cli 執行所需
- **一個電話號碼** 並已安裝 Signal（用於將其連結為次要裝置）

### 安裝 signal-cli

```bash
# macOS
brew install signal-cli

# Linux (下載最新發佈版本)
VERSION=$(curl -Ls -o /dev/null -w %{url_effective} \
  https://github.com/AsamK/signal-cli/releases/latest | sed 's/^.*\/v//')
curl -L -O "https://github.com/AsamK/signal-cli/releases/download/v${VERSION}/signal-cli-${VERSION}.tar.gz"
sudo tar xf "signal-cli-${VERSION}.tar.gz" -C /opt
sudo ln -sf "/opt/signal-cli-${VERSION}/bin/signal-cli" /usr/local/bin/
```

:::caution
signal-cli **不在** apt 或 snap 套件庫中。上述 Linux 安裝指令是直接從 [GitHub releases](https://github.com/AsamK/signal-cli/releases) 下載。
:::

---

## 步驟 1：連結您的 Signal 帳戶

Signal-cli 以 **已連結裝置 (linked device)** 的方式運作 —— 就像 WhatsApp Web，但對象是 Signal。您的手機仍會是主要裝置。

```bash
# 產生連結網址 (會顯示 QR code 或連結)
signal-cli link -n "HermesAgent"
```

1. 開啟手機上的 **Signal**
2. 前往 **設定 → 已連結的裝置**
3. 點擊 **連結新裝置**
4. 掃描 QR code 或輸入該連結網址

---

## 步驟 2：啟動 signal-cli 守護程序

```bash
# 將 +1234567890 替換為您的 Signal 電話號碼 (E.164 格式)
signal-cli --account +1234567890 daemon --http 127.0.0.1:8080
```

:::tip
請讓此程序在背景執行。您可以使用 `systemd`、`tmux`、`screen` 或將其作為服務執行。
:::

驗證是否正在執行：

```bash
curl http://127.0.0.1:8080/api/v1/check
# 應該回傳：{"versions":{"signal-cli":...}}
```

---

## 步驟 3：設定 Hermes

最簡單的方法：

```bash
hermes gateway setup
```

從平台選單中選擇 **Signal**。設定精靈將會：

1. 檢查是否已安裝 signal-cli
2. 提示輸入 HTTP 網址（預設：`http://127.0.0.1:8080`）
3. 測試與守護程序的連通性
4. 詢問您的帳戶電話號碼
5. 設定允許的使用者和存取政策

### 手動設定

在 `~/.hermes/.env` 中加入：

```bash
# 必填
SIGNAL_HTTP_URL=http://127.0.0.1:8080
SIGNAL_ACCOUNT=+1234567890

# 安全性 (推薦)
SIGNAL_ALLOWED_USERS=+1234567890,+0987654321    # 以逗號分隔的 E.164 號碼或 UUID

# 選填
SIGNAL_GROUP_ALLOWED_USERS=groupId1,groupId2     # 啟用群組 (省略則停用，設為 * 則允許所有)
SIGNAL_HOME_CHANNEL=+1234567890                  # 排程任務的預設傳送目標
```

然後啟動閘道：

```bash
hermes gateway              # 前景執行
hermes gateway install      # 安裝為使用者服務
sudo hermes gateway install --system   # 僅限 Linux：開機啟動的系統服務
```

---

## 存取控制

### 私訊 (DM) 存取

私訊存取遵循所有其他 Hermes 平台的相同模式：

1. **已設定 `SIGNAL_ALLOWED_USERS`** → 僅限清單中的使用者可發送訊息
2. **未設定白名單** → 未知使用者將收到私訊配對代碼 (透過 `hermes pairing approve signal CODE` 批准)
3. **`SIGNAL_ALLOW_ALL_USERS=true`** → 任何人皆可發送訊息 (請謹慎使用)

### 群組存取

群組存取由 `SIGNAL_GROUP_ALLOWED_USERS` 環境變數控制：

| 設定 | 行為 |
|---------------|----------|
| 未設定 (預設) | 忽略所有群組訊息。機器人僅回應私訊。 |
| 設定群組 ID | 僅監控清單中的群組 (例如 `groupId1,groupId2`)。 |
| 設為 `*` | 機器人會回應其所在的任何群組。 |

---

## 功能

### 附件

適配器支援雙向發送和接收媒體檔案。

**傳入** (使用者 → 代理程式)：

- **圖片** — PNG、JPEG、GIF、WebP (透過 magic bytes 自動偵測)
- **音訊** — MP3、OGG、WAV、M4A (若已設定 Whisper，語音訊息將被轉錄)
- **文件** — PDF、ZIP 及其他檔案類型

**傳出** (代理程式 → 使用者)：

代理程式可以透過回應中的 `MEDIA:` 標籤發送媒體檔案。支援以下傳送方式：

- **圖片** — `send_image_file` 以原生 Signal 附件發送 PNG、JPEG、GIF、WebP
- **語音** — `send_voice` 發送音訊檔案 (OGG, MP3, WAV, M4A, AAC) 作為附件
- **影片** — `send_video` 發送 MP4 影片檔案
- **文件** — `send_document` 發送任何檔案類型 (PDF, ZIP 等)

所有傳出的媒體檔案都透過 Signal 的標準附件 API 進行。與某些平台不同，Signal 在協定層級上不區分語音訊息和檔案附件。

附件大小限制：**100 MB** (雙向)。

### 打字中提示

機器人在處理訊息時會發送打字中提示，每 8 秒重新整理一次。

### 電話號碼遮蔽 (Redaction)

所有電話號碼在日誌中都會自動遮蔽：
- `+15551234567` → `+155****4567`
- 這適用於 Hermes 閘道日誌以及全域遮蔽系統

### 給自己的筆記 (單一號碼設定)

如果您在自己的電話號碼上將 signal-cli 執行為 **已連結的次要裝置** (而非獨立的機器人號碼)，您可以透過 Signal 的「給自己的筆記 (Note to Self)」功能與 Hermes 互動。

只需從手機發送訊息給自己 —— signal-cli 會接收該訊息，Hermes 則會在同一個對話中回應。

**運作方式：**
- 「給自己的筆記」訊息會以 `syncMessage.sentMessage` 封包到達
- 適配器會偵測訊息是否發送至機器人自己的帳戶，並將其作為一般傳入訊息處理
- 回音保護 (Echo-back protection，透過發送時間戳記追蹤) 可防止無限迴圈 —— 機器人自己的回覆會被自動過濾掉

**無需額外設定。** 只要 `SIGNAL_ACCOUNT` 與您的電話號碼相符，此功能就會自動運作。

### 狀態監控

適配器會監控 SSE 連線，並在以下情況自動重新連線：
- 連線中斷 (採用指數退避機制：2s → 60s)
- 120 秒內未偵測到任何活動 (會 ping signal-cli 進行驗證)

---

## 疑難排解

| 問題 | 解決方案 |
|---------|----------|
| **設定時顯示 "Cannot reach signal-cli"** | 確保 signal-cli 守護程序正在執行：`signal-cli --account +您的號碼 daemon --http 127.0.0.1:8080` |
| **未接收到訊息** | 檢查 `SIGNAL_ALLOWED_USERS` 是否包含發送者的 E.164 格式號碼 (含 `+` 前綴) |
| **"signal-cli not found on PATH"** | 安裝 signal-cli 並確保其在您的 PATH 中，或使用 Docker |
| **連線不斷中斷** | 檢查 signal-cli 日誌中的錯誤。確保已安裝 Java 17+。 |
| **群組訊息被忽略** | 將 `SIGNAL_GROUP_ALLOWED_USERS` 設定為特定的群組 ID，或設為 `*` 以允許所有群組。 |
| **機器人不回應任何人** | 設定 `SIGNAL_ALLOWED_USERS`、使用私訊配對，或如果您想要更廣泛的存取權，請透過閘道政策明確允許所有使用者。 |
| **重複訊息** | 確保只有一個 signal-cli 實例正在接聽您的電話號碼 |

---

## 安全性

:::warning
**務必設定存取控制。** 機器人預設具有終端機存取權。若未設定 `SIGNAL_ALLOWED_USERS` 或私訊配對，閘道會基於安全考量拒絕所有傳入訊息。
:::

- 電話號碼在所有日誌輸出中都會被遮蔽
- 使用私訊配對或明確的白名單來安全地引導新使用者
- 除非確實需要群組支援，否則請保持群組停用，或僅將您信任的群組加入白名單
- Signal 的端到端加密可保護傳輸中的訊息內容
- `~/.local/share/signal-cli/` 中的 signal-cli 工作階段資料包含帳戶憑證 —— 請像保護密碼一樣保護它

---

## 環境變數參考

| 變數 | 必填 | 預設值 | 描述 |
|----------|----------|---------|-------------|
| `SIGNAL_HTTP_URL` | 是 | — | signal-cli HTTP 端點 |
| `SIGNAL_ACCOUNT` | 是 | — | 機器人電話號碼 (E.164 格式) |
| `SIGNAL_ALLOWED_USERS` | 否 | — | 以逗號分隔的電話號碼/UUID 清單 |
| `SIGNAL_GROUP_ALLOWED_USERS` | 否 | — | 要監控的群組 ID，或設為 `*` 代表全部 (省略則停用群組) |
| `SIGNAL_ALLOW_ALL_USERS` | 否 | `false` | 允許任何使用者互動 (跳過白名單) |
| `SIGNAL_HOME_CHANNEL` | 否 | — | 排程任務的預設傳送目標 |
