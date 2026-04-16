---
name: google-workspace
description: 為 Hermes 提供 Gmail、日曆 (Calendar)、雲端硬碟 (Drive)、聯絡人 (Contacts)、試算表 (Sheets) 和文件 (Docs) 的整合功能。使用 Hermes 管理的 OAuth2 設定，在可用時優先使用 Google Workspace CLI (`gws`) 以獲得更廣泛的 API 支援，否則將回退至 Python 客戶端函式庫。
version: 1.0.0
author: Nous Research
license: MIT
metadata:
  hermes:
    tags: [Google, Gmail, Calendar, Drive, Sheets, Docs, Contacts, Email, OAuth]
    homepage: https://github.com/NousResearch/hermes-agent
    related_skills: [himalaya]
---

# Google Workspace

Gmail、日曆 (Calendar)、雲端硬碟 (Drive)、聯絡人 (Contacts)、試算表 (Sheets) 和文件 (Docs) — 透過 Hermes 管理的 OAuth 和輕量級 CLI 封裝。安裝 `gws` 後，此技能會將其作為執行後端，以提供更廣泛的 Google Workspace 覆蓋範圍；否則將回退到隨附的 Python 客戶端實作。

## 參考資料

- `references/gmail-search-syntax_zh_TW.md` — Gmail 搜尋運算子 (is:unread, from:, newer_than: 等)

## 指令碼

- `scripts/setup.py` — OAuth2 設定 (執行一次以進行授權)
- `scripts/google_api.py` — 相容性封裝 CLI。在可用時優先使用 `gws` 進行操作，同時保留 Hermes 現有的 JSON 輸出合約。

## 首次設定

設定過程完全是非互動式的 — 你可以逐步引導，以便在 CLI、Telegram、Discord 或任何平台上運作。

首先定義一個縮寫：

```bash
GSETUP="python ~/.hermes/skills/productivity/google-workspace/scripts/setup.py"
```

### 步驟 0：檢查是否已設定

```bash
$GSETUP --check
```

如果顯示 `AUTHENTICATED`，請跳至「用法」— 設定已完成。

### 步驟 1：分類 — 詢問使用者需求

在開始 OAuth 設定之前，請詢問使用者兩個問題：

**問題 1：「你需要哪些 Google 服務？僅電子郵件，還是也需要日曆/雲端硬碟/試算表/文件？」**

- **僅電子郵件** → 他們完全不需要此技能。請改用 `himalaya` 技能 — 它配合 Gmail 應用程式密碼 (App Password) 即可運作 (設定 → 安全性 → 應用程式密碼)，只需 2 分鐘即可完成設定。不需要 Google Cloud 專案。載入 himalaya 技能並遵循其設定說明。

- **電子郵件 + 日曆** → 繼續使用此技能，但在授權期間使用 `--services email,calendar`，以便同意畫面僅要求其真正需要的權限範圍 (scopes)。

- **僅日曆/雲端硬碟/試算表/文件** → 繼續使用此技能，並使用較窄的 `--services` 集合，例如 `calendar,drive,sheets,docs`。

- **完整 Workspace 存取權** → 繼續使用此技能，並使用預設的 `all` 服務集合。

**問題 2：「你的 Google 帳號是否使用了進階保護 (登入時需要硬體安全金鑰)？如果你不確定，那可能沒有 — 這是你需要明確註冊的功能。」**

- **否 / 不確定** → 正常設定。請繼續執行下方步驟。
- **是** → 他們的 Workspace 管理員必須先將 OAuth 客戶端 ID (client ID) 新增到組織的允許應用程式清單中，步驟 4 才能正常運作。請事先告知他們。

### 步驟 2：建立 OAuth 認證 (一次性，約 5 分鐘)

告訴使用者：

> 你需要一個 Google Cloud OAuth 客戶端。這是一次性設定：
>
> 1. 建立或選擇一個專案：
>    https://console.cloud.google.com/projectselector2/home/dashboard
> 2. 從 API 程式庫啟用必要的 API：
>    https://console.cloud.google.com/apis/library
>    啟用：Gmail API, Google Calendar API, Google Drive API,
>    Google Sheets API, Google Docs API, People API
> 3. 在此處建立 OAuth 客戶端：
>    https://console.cloud.google.com/apis/credentials
>    憑證 → 建立憑證 → OAuth 2.0 客戶端 ID
> 4. 應用程式類型：選擇「桌面應用程式 (Desktop app)」→ 建立
> 5. 如果應用程式仍處於「測試」階段，請在此處將使用者的 Google 帳號新增為測試使用者：
>    https://console.cloud.google.com/auth/audience
>    受眾 → 測試使用者 → 新增使用者
> 6. 下載 JSON 檔案並告訴我檔案路徑
>
> 重要 Hermes CLI 說明：如果檔案路徑以 `/` 開頭，請「不要」在 CLI 中僅發送純路徑作為獨立訊息，因為它可能會被誤認為斜線指令。請將其放在句子中發送，例如：
> `JSON 檔案路徑為：/home/user/Downloads/client_secret_....json`

一旦他們提供路徑：

```bash
$GSETUP --client-secret /path/to/client_secret.json
```

如果他們貼上原始的客戶端 ID / 客戶端密鑰值而非檔案路徑，請自行為其撰寫一個有效的桌面 OAuth JSON 檔案，將其儲存在明確的位置 (例如 `~/Downloads/hermes-google-client-secret.json`)，然後針對該檔案執行 `--client-secret`。

### 步驟 3：獲取授權 URL

使用步驟 1 中選擇的服務集合。範例：

```bash
$GSETUP --auth-url --services email,calendar --format json
$GSETUP --auth-url --services calendar,drive,sheets,docs --format json
$GSETUP --auth-url --services all --format json
```

這會傳回包含 `auth_url` 欄位的 JSON，並將確切的 URL 儲存到 `~/.hermes/google_oauth_last_url.txt`。

此步驟的代理規則：
- 擷取 `auth_url` 欄位，並將該確切 URL 以單行方式發送給使用者。
- 告知使用者瀏覽器在核准後可能會在 `http://localhost:1` 發生失敗，這是正常的。
- 告知他們從瀏覽器網址列複製「整個」重新導向後的 URL。
- 如果使用者遇到 `Error 403: access_denied`，請直接引導他們前往 `https://console.cloud.google.com/auth/audience` 將自己新增為測試使用者。

### 步驟 4：交換代碼

使用者將貼回類似 `http://localhost:1/?code=4/0A...&scope=...` 的 URL 或僅貼上代碼字串。兩者皆可。`--auth-url` 步驟會在本地暫存待處理的 OAuth 工作階段，以便 `--auth-code` 稍後完成 PKCE 交換，即使在無頭 (headless) 系統上也是如此：

```bash
$GSETUP --auth-code "使用者貼上的網址或代碼" --format json
```

如果 `--auth-code` 因為代碼過期、已被使用或來自舊的瀏覽器分頁而失敗，它現在會傳回一個新的 `fresh_auth_url`。在這種情況下，請立即將新 URL 發送給使用者，並讓他們僅使用最新的瀏覽器重新導向重試。

### 步驟 5：驗證

```bash
$GSETUP --check
```

應該顯示 `AUTHENTICATED`。設定完成 — 從現在起權杖 (token) 會自動刷新。

### 備註

- 權杖儲存在 `~/.hermes/google_token.json` 並會自動刷新。
- 待處理的 OAuth 工作階段狀態/驗證器會暫存在 `~/.hermes/google_oauth_pending.json` 直到交換完成。
- 如果安裝了 `gws`，`google_api.py` 會將其指向同一個 `~/.hermes/google_token.json` 憑證檔案。使用者不需要執行單獨的 `gws auth login` 流程。
- 若要撤銷：`$GSETUP --revoke`

## 用法

所有指令都透過 API 指令碼執行。將 `GAPI` 設定為縮寫：

```bash
GAPI="python ~/.hermes/skills/productivity/google-workspace/scripts/google_api.py"
```

### Gmail

```bash
# 搜尋 (傳回包含 id, from, subject, date, snippet 的 JSON 陣列)
$GAPI gmail search "is:unread" --max 10
$GAPI gmail search "from:boss@company.com newer_than:1d"
$GAPI gmail search "has:attachment filename:pdf newer_than:7d"

# 讀取完整訊息 (傳回包含本文文字的 JSON)
$GAPI gmail get MESSAGE_ID

# 發送
$GAPI gmail send --to user@example.com --subject "Hello" --body "Message text"
$GAPI gmail send --to user@example.com --subject "Report" --body "<h1>Q4</h1><p>Details...</p>" --html
$GAPI gmail send --to user@example.com --subject "Hello" --from '"Research Agent" <user@example.com>' --body "Message text"

# 回覆 (自動建立討論串並設定 In-Reply-To)
$GAPI gmail reply MESSAGE_ID --body "Thanks, that works for me."
$GAPI gmail reply MESSAGE_ID --from '"Support Bot" <user@example.com>' --body "Thanks"

# 標籤
$GAPI gmail labels
$GAPI gmail modify MESSAGE_ID --add-labels LABEL_ID
$GAPI gmail modify MESSAGE_ID --remove-labels UNREAD
```

### 日曆 (Calendar)

```bash
# 列出活動 (預設為接下來 7 天)
$GAPI calendar list
$GAPI calendar list --start 2026-03-01T00:00:00Z --end 2026-03-07T23:59:59Z

# 建立活動 (需包含時區的 ISO 8601 格式)
$GAPI calendar create --summary "Team Standup" --start 2026-03-01T10:00:00-06:00 --end 2026-03-01T10:30:00-06:00
$GAPI calendar create --summary "Lunch" --start 2026-03-01T12:00:00Z --end 2026-03-01T13:00:00Z --location "Cafe"
$GAPI calendar create --summary "Review" --start 2026-03-01T14:00:00Z --end 2026-03-01T15:00:00Z --attendees "alice@co.com,bob@co.com"

# 刪除活動
$GAPI calendar delete EVENT_ID
```

### 雲端硬碟 (Drive)

```bash
$GAPI drive search "quarterly report" --max 10
$GAPI drive search "mimeType='application/pdf'" --raw-query --max 5
```

### 聯絡人 (Contacts)

```bash
$GAPI contacts list --max 20
```

### 試算表 (Sheets)

```bash
# 讀取
$GAPI sheets get SHEET_ID "Sheet1!A1:D10"

# 寫入
$GAPI sheets update SHEET_ID "Sheet1!A1:B2" --values '[["Name","Score"],["Alice","95"]]'

# 附加列
$GAPI sheets append SHEET_ID "Sheet1!A:C" --values '[["new","row","data"]]'
```

### 文件 (Docs)

```bash
$GAPI docs get DOC_ID
```

## 輸出格式

所有指令均傳回 JSON。可使用 `jq` 解析或直接讀取。關鍵欄位：

- **Gmail 搜尋**: `[{id, threadId, from, to, subject, date, snippet, labels}]`
- **Gmail 獲取**: `{id, threadId, from, to, subject, date, labels, body}`
- **Gmail 發送/回覆**: `{status: "sent", id, threadId}`
- **日曆列出**: `[{id, summary, start, end, location, description, htmlLink}]`
- **日曆建立**: `{status: "created", id, summary, htmlLink}`
- **雲端硬碟搜尋**: `[{id, name, mimeType, modifiedTime, webViewLink}]`
- **聯絡人列出**: `[{name, emails: [...], phones: [...]}]`
- **試算表獲取**: `[[cell, cell, ...], ...]`

## 規則

1. **未經使用者確認前，絕不發送電子郵件或建立/刪除活動。** 顯示草稿內容並徵求許可。
2. **首次使用前檢查授權** — 執行 `setup.py --check`。如果失敗，引導使用者完成設定。
3. **複雜查詢請參考 Gmail 搜尋語法參考資料** — 使用 `skill_view("google-workspace", file_path="references/gmail-search-syntax_zh_TW.md")` 載入。
4. **日曆時間必須包含時區** — 務必使用帶有偏移量的 ISO 8601 (例如 `2026-03-01T10:00:00-06:00`)執或 UTC (`Z`)。
5. **尊重速率限制** — 避免快速連續的 API 呼叫。儘可能進行批次讀取。

## 疑難排解

| 問題 | 修正方法 |
|---------|-----|
| `NOT_AUTHENTICATED` | 執行上述設定步驟 2-5 |
| `REFRESH_FAILED` | 權杖已撤銷或過期 — 重新執行步驟 3-5 |
| `HttpError 403: Insufficient Permission` | 缺少 API 權限範圍 — `$GSETUP --revoke` 後重新執行步驟 3-5 |
| `HttpError 403: Access Not Configured` | API 未啟用 — 使用者需在 Google Cloud Console 中啟用它 |
| `ModuleNotFoundError` | 執行 `$GSETUP --install-deps` |
| 進階保護封鎖授權 | Workspace 管理員必須將 OAuth 客戶端 ID 列入許可清單 |

## 撤銷存取權

```bash
$GSETUP --revoke
```
