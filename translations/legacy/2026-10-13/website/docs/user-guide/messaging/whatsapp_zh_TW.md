---
sidebar_position: 5
title: "WhatsApp"
description: "透過內建的 Baileys 橋接器將 Hermes 代理程式設定為 WhatsApp 機器人"
---

# WhatsApp 設定

Hermes 透過基於 **Baileys** 的內建橋接器連線至 WhatsApp。其運作方式是模擬 WhatsApp 網頁版 (Web) 工作階段 —— **並非**透過官方的 WhatsApp Business API。不需要 Meta 開發者帳號或商業驗證。

:::warning 非官方 API —— 停權風險
WhatsApp **不**官方支援 Business API 以外的第三方機器人。使用第三方橋接器存在帳號受限的小風險。為了降低風險：
- 為機器人使用 **專屬電話號碼**（不要使用您的個人號碼）
- **不要傳送大量/垃圾訊息** —— 保持對話式使用
- **不要主動**向未曾傳送訊息給您的人傳送自動化出站訊息
:::

:::warning WhatsApp 網頁版協定更新
WhatsApp 會定期更新其網頁版協定，這可能會暫時破壞與第三方橋接器的相容性。發生這種情況時，Hermes 會更新橋接器依賴項。如果機器人在 WhatsApp 更新後停止運作，請獲取最新的 Hermes 版本並重新配對。
:::

## 兩種模式

| 模式 | 運作方式 | 適用對象 |
|------|-------------|----------|
| **獨立機器人號碼** (推薦) | 為機器人配置一個專屬電話號碼。人們直接向該號碼傳送訊息。 | 乾淨的使用者體驗、多使用者、較低的停權風險 |
| **個人自聊 (Self-chat)** | 使用您自己的 WhatsApp。您向自己傳送訊息與代理程式交談。 | 快速設定、單一使用者、測試 |

---

## 前置條件

- **Node.js v18+** 和 **npm** —— WhatsApp 橋接器作為 Node.js 程序執行
- **裝有 WhatsApp 的手機**（用於掃描二維碼）

與舊的基於瀏覽器驅動的橋接器不同，目前的 Baileys 橋接器**不需要**本地 Chromium 或 Puppeteer 依賴項。

---

## 步驟 1：執行設定精靈

```bash
hermes whatsapp
```

設定精靈將會：

1. 詢問您想要哪種模式（**機器人**或**自聊**）
2. 如果需要，安裝橋接器依賴項
3. 在您的終端機中顯示一個 **二維碼 (QR Code)**
4. 等待您掃描它

**掃描二維碼：**

1. 在手機上開啟 WhatsApp
2. 前往 **設定 → 已連結裝置**
3. 點擊 **連結裝置**
4. 將相機對準終端機上的二維碼

配對成功後，設定精靈會確認連線並結束。您的工作階段會自動儲存。

:::tip
如果二維碼看起來亂碼，請確保您的終端機寬度至少為 60 欄並支援 Unicode。您也可以嘗試不同的終端機模擬器。
:::

---

## 步驟 2：取得第二個電話號碼（機器人模式）

對於機器人模式，您需要一個尚未在 WhatsApp 註冊的電話號碼。三種選擇：

| 選項 | 費用 | 說明 |
|--------|------|-------|
| **Google Voice** | 免費 | 僅限美國。在 [voice.google.com](https://voice.google.com) 取得號碼。透過 Google Voice 應用程式接收 SMS 驗證 WhatsApp。 |
| **預付卡 (Prepaid SIM)** | $5–15 一次性 | 任何電信商。啟動並驗證 WhatsApp 後，SIM 卡即可存放。號碼必須保持有效（每 90 天撥打一次電話）。 |
| **VoIP 服務** | 免費–$5/月 | TextNow、TextFree 或類似服務。部分 VoIP 號碼會被 WhatsApp 封鎖 —— 如果第一個不行，請多嘗試幾個。 |

取得號碼後：

1. 在手機上安裝 WhatsApp（或使用支援雙卡的 WhatsApp Business 應用程式）
2. 使用新號碼註冊 WhatsApp
3. 執行 `hermes whatsapp` 並使用該 WhatsApp 帳號掃描二維碼

---

## 步驟 3：設定 Hermes

在您的 `~/.hermes/.env` 檔案中加入以下內容：

```bash
# 必要
WHATSAPP_ENABLED=true
WHATSAPP_MODE=bot                          # "bot" 或 "self-chat"

# 存取控制 —— 選擇以下其中一個選項：
WHATSAPP_ALLOWED_USERS=15551234567         # 逗號分隔的電話號碼（含國家代碼，不含 +）
# WHATSAPP_ALLOWED_USERS=*                 # 或使用 * 允許所有人
# WHATSAPP_ALLOW_ALL_USERS=true            # 或設定此標記（效果與 * 相同）
```

:::tip 允許所有人的簡寫
設定 `WHATSAPP_ALLOWED_USERS=*` 允許**所有**傳送者（等同於 `WHATSAPP_ALLOW_ALL_USERS=true`）。這與 [Signal 群組允許列表](/docs/reference/environment-variables) 一致。若要改用配對流程，請移除這兩個變數並依賴 [私訊配對系統](/docs/user-guide/security#dm-pairing-system)。
:::

在 `~/.hermes/config.yaml` 中的選填行為設定：

```yaml
unauthorized_dm_behavior: pair

whatsapp:
  unauthorized_dm_behavior: ignore
```

- `unauthorized_dm_behavior: pair` 是全域預設值。未知的私訊傳送者會收到配對碼。
- `whatsapp.unauthorized_dm_behavior: ignore` 讓 WhatsApp 對未經授權的私訊保持靜默，對於私人號碼這通常是更好的選擇。

然後啟動閘道器：

```bash
hermes gateway              # 前台執行
hermes gateway install      # 作為使用者服務安裝
sudo hermes gateway install --system   # 僅限 Linux：開機啟動的系統服務
```

閘道器會使用儲存的工作階段自動啟動 WhatsApp 橋接器。

---

## 工作階段持久化 (Session Persistence)

Baileys 橋接器將其工作階段儲存在 `~/.hermes/platforms/whatsapp/session`。這意味著：

- **工作階段在重啟後依然存在** —— 您不需要每次都重新掃描二維碼
- 工作階段資料包含加密金鑰和裝置憑證
- **不要分享或提交此工作階段目錄** —— 它授予對 WhatsApp 帳號的完整存取權

---

## 重新配對

如果工作階段失效（手機重設、WhatsApp 更新、手動取消連結），您會在閘道器日誌中看到連線錯誤。修復方法：

```bash
hermes whatsapp
```

這會產生一個新的二維碼。再次掃描，工作階段就會重新建立。閘道器會透過重新連線邏輯自動處理**暫時性**中斷（網路波動、手機短暫離線）。

---

## 語音訊息

Hermes 在 WhatsApp 上支援語音：

- **入站：** 語音訊息 (`.ogg` opus) 會使用設定的 STT 供應商自動轉錄：本地 `faster-whisper`、Groq Whisper (`GROQ_API_KEY`) 或 OpenAI Whisper (`VOICE_TOOLS_OPENAI_KEY`)。
- **出站：** TTS 回應以 MP3 音訊檔案附件形式傳送。
- 預設情況下，代理程式回應會帶有前綴 "⚕ **Hermes Agent**"。您可以在 `config.yaml` 中自訂或停用此功能：

```yaml
# ~/.hermes/config.yaml
whatsapp:
  reply_prefix: ""                          # 空字串可停用標頭
  # reply_prefix: "🤖 *我的機器人*\n──────\n"  # 自訂前綴（支援 \n 換行）
```

---

## 訊息格式與遞送

WhatsApp 支援**串流（漸進式）回應** —— 機器人會在 AI 產生文字時即時編輯其訊息，就像 Discord 和 Telegram 一樣。在內部，WhatsApp 被歸類為具有 TIER_MEDIUM 遞送能力的平台。

### 分塊 (Chunking)

長回應會自動拆分為多條訊息，每塊 **4,096 個字元**（WhatsApp 的實際顯示限制）。您不需要設定任何內容 —— 閘道器會處理拆分並依序傳送。

### WhatsApp 相容的 Markdown

AI 回應中的標準 Markdown 會自動轉換為 WhatsApp 的原生格式：

| Markdown | WhatsApp | 渲染結果 |
|----------|----------|------------|
| `**bold**` | `*bold*` | **粗體** |
| `~~strikethrough~~` | `~strikethrough~` | ~~刪除線~~ |
| `# Heading` | `*Heading*` | 粗體文字（無原生標題） |
| `[link text](url)` | `link text (url)` | 行內 URL |

程式碼區塊和行內程式碼保持原樣，因為 WhatsApp 原生支援三反引號格式。

### 工具進度

當代理程式呼叫工具（網頁搜尋、檔案操作等）時，WhatsApp 會顯示即時進度指示器，顯示正在執行哪個工具。此功能預設啟用 —— 無需設定。

---

## 疑難排解

| 問題 | 解決方法 |
|---------|----------|
| **二維碼無法掃描** | 確保終端機寬度足夠（60 欄以上）。嘗試不同的終端機。確保您是從正確的 WhatsApp 帳號（機器人號碼，而非個人號碼）掃描。 |
| **二維碼過期** | 二維碼約每 20 秒重新整理一次。如果逾時，請重啟 `hermes whatsapp`。 |
| **工作階段無法持久化** | 檢查 `~/.hermes/platforms/whatsapp/session` 是否存在且可寫入。如果是容器化部署，請將其掛載為持久磁碟卷。 |
| **非預期地登出** | WhatsApp 在長時間不活動後會取消連結裝置。請保持手機開機並連線至網路，如有需要請使用 `hermes whatsapp` 重新配對。 |
| **橋接器崩潰或重新連線迴圈** | 重啟閘道器，更新 Hermes，如果工作階段因 WhatsApp 協定變更而失效，請重新配對。 |
| **WhatsApp 更新後機器人停止運作** | 更新 Hermes 以取得最新的橋接器版本，然後重新配對。 |
| **macOS："Node.js not installed" 但 node 在終端機可運作** | launchd 服務不會繼承您的 shell PATH。執行 `hermes gateway install` 將您目前的 PATH 重新快照到 plist 中，然後執行 `hermes gateway start`。詳情請參閱 [閘道器服務文件](./index.md#macos-launchd)。 |
| **未接收到訊息** | 驗證 `WHATSAPP_ALLOWED_USERS` 包含傳送者的號碼（含國家代碼，不含 `+` 或空格），或將其設定為 `*` 允許所有人。在 `.env` 中設定 `WHATSAPP_DEBUG=true` 並重啟閘道器，在 `bridge.log` 中查看原始訊息事件。 |
| **機器人用配對碼回覆陌生人** | 如果您希望靜默忽略未經授權的私訊，請在 `~/.hermes/config.yaml` 中設定 `whatsapp.unauthorized_dm_behavior: ignore`。 |

---

## 安全性 {#security}

:::warning
在正式上線前請先 **設定存取控制**。在 `WHATSAPP_ALLOWED_USERS` 中設定特定電話號碼（包含國家代碼，不含 `+`），使用 `*` 允許所有人，或設定 `WHATSAPP_ALLOW_ALL_USERS=true`。如果未設定任何一項，閘道器將作為安全措施 **拒絕所有入站訊息**。
:::

預設情況下，未經授權的私訊仍會收到配對碼回覆。如果您希望私人 WhatsApp 號碼對陌生人完全保持靜默，請設定：

```yaml
whatsapp:
  unauthorized_dm_behavior: ignore
```

- `~/.hermes/platforms/whatsapp/session` 目錄包含完整的工作階段憑證 —— 請像保護密碼一樣保護它。
- 設定檔案權限：`chmod 700 ~/.hermes/platforms/whatsapp/session`。
- 為機器人使用 **專屬電話號碼**，以將風險與您的個人帳號隔離。
- 如果懷疑遭受入侵，請從 WhatsApp → 設定 → 已連結裝置中取消連結。
- 日誌中的電話號碼會被部分遮蓋，但請審核您的日誌保留原則。
