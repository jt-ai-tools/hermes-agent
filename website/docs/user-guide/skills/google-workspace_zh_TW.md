---
sidebar_position: 2
sidebar_label: "Google Workspace"
title: "Google Workspace — Gmail、日曆、雲端硬碟、試算表與文件"
description: "透過 OAuth2 驗證的 Google API 發送電子郵件、管理日曆活動、搜尋雲端硬碟、讀寫試算表以及存取文件"
---

# Google Workspace 技能 (Google Workspace Skill)

為 Hermes 提供 Gmail、日曆 (Calendar)、雲端硬碟 (Drive)、聯絡人 (Contacts)、試算表 (Sheets) 與文件 (Docs) 的整合功能。使用 OAuth2 並具備自動權杖 (Token) 刷新機制。優先使用 [Google Workspace CLI (`gws`)](https://github.com/nicholasgasior/gws) (若可用) 以獲得更廣泛的覆蓋範圍，否則會回退到 Google 的 Python 用戶端函式庫。

**技能路徑：** `skills/productivity/google-workspace/`

## 設定

設定流程完全由代理程式驅動 —— 只需要求 Hermes 設定 Google Workspace，它會引導你完成每個步驟。流程如下：

1. **建立 Google Cloud 專案** 並啟用所需的 API (Gmail, Calendar, Drive, Sheets, Docs, People)
2. **建立 OAuth 2.0 憑證** (桌面應用程式類型) 並下載用戶端秘密 (Client Secret) JSON 檔案
3. **授權** —— Hermes 會生成一個驗證 URL，你在瀏覽器中核准後，將重新導向 URL 貼回
4. **完成** —— 從此之後權杖會自動刷新

:::tip 僅需電子郵件的使用者
如果你只需要電子郵件功能 (不需要日曆/雲端硬碟/試算表)，請改用 **himalaya** 技能 —— 它只需 Gmail 應用程式密碼即可運作，設定僅需 2 分鐘。不需要建立 Google Cloud 專案。
:::

## Gmail

### 搜尋

```bash
$GAPI gmail search "is:unread" --max 10
$GAPI gmail search "from:boss@company.com newer_than:1d"
$GAPI gmail search "has:attachment filename:pdf newer_than:7d"
```

回傳包含每則訊息之 `id`、`from`、`subject`、`date`、`snippet` (片段) 與 `labels` (標籤) 的 JSON。

### 讀取

```bash
$GAPI gmail get MESSAGE_ID
```

回傳完整的郵件內文文字 (優先選擇純文字，若無則回退至 HTML)。

### 發送

```bash
# 基本發送
$GAPI gmail send --to user@example.com --subject "Hello" --body "Message text"

# HTML 郵件
$GAPI gmail send --to user@example.com --subject "Report" \
  --body "<h1>Q4 Results</h1><p>Details here</p>" --html

# 自訂寄件者標頭 (顯示名稱 + 電子郵件)
$GAPI gmail send --to user@example.com --subject "Hello" \
  --from '"Research Agent" <user@example.com>' --body "Message text"

# 包含副本 (CC)
$GAPI gmail send --to user@example.com --cc "team@example.com" \
  --subject "Update" --body "FYI"
```

### 自訂寄件者標頭

`--from` 旗標允許你自訂外發郵件的寄件者顯示名稱。當多個代理程式共用同一個 Gmail 帳戶，但你希望收件者看到不同的名稱時，這項功能非常有用：

```bash
# 代理程式 1
$GAPI gmail send --to client@co.com --subject "Research Summary" \
  --from '"Research Agent" <shared@company.com>' --body "..."

# 代理程式 2  
$GAPI gmail send --to client@co.com --subject "Code Review" \
  --from '"Code Assistant" <shared@company.com>' --body "..."
```

**運作方式：** `--from` 的值會被設定為 MIME 訊息中的 RFC 5322 `From` 標頭。Gmail 允許在你自己的驗證電子郵件地址上自訂顯示名稱，無需任何額外配置。收件者會看到自訂的顯示名稱 (例如 "Research Agent")，而電子郵件地址保持不變。

**重要提示：** 如果你在 `--from` 中使用*不同的電子郵件地址* (非已驗證的帳戶)，Gmail 要求該地址必須在 Gmail 設定 → 帳戶與匯入 → 選擇寄件地址中配置為 [Send As 別名](https://support.google.com/mail/answer/22370)。

`--from` 旗標同樣適用於 `send` 與 `reply`：

```bash
$GAPI gmail reply MESSAGE_ID \
  --from '"Support Bot" <shared@company.com>' --body "We're on it"
```

### 回覆

```bash
$GAPI gmail reply MESSAGE_ID --body "Thanks, that works for me."
```

自動將回覆加入對話串 (設定 `In-Reply-To` 與 `References` 標頭)，並使用原始訊息的對話串 ID (Thread ID)。

### 標籤

```bash
# 列出所有標籤
$GAPI gmail labels

# 新增/移除標籤
$GAPI gmail modify MESSAGE_ID --add-labels LABEL_ID
$GAPI gmail modify MESSAGE_ID --remove-labels UNREAD
```

## 日曆 (Calendar)

```bash
# 列出活動 (預設為未來 7 天)
$GAPI calendar list
$GAPI calendar list --start 2026-03-01T00:00:00Z --end 2026-03-07T23:59:59Z

# 建立活動 (必須指定時區)
$GAPI calendar create --summary "Team Standup" \
  --start 2026-03-01T10:00:00-07:00 --end 2026-03-01T10:30:00-07:00

# 包含地點與與會者
$GAPI calendar create --summary "Lunch" \
  --start 2026-03-01T12:00:00Z --end 2026-03-01T13:00:00Z \
  --location "Cafe" --attendees "alice@co.com,bob@co.com"

# 刪除活動
$GAPI calendar delete EVENT_ID
```

:::warning
日曆時間**必須**包含時區偏移 (例如 `-07:00`) 或使用 UTC (`Z`)。不含時區的時間字串 (如 `2026-03-01T10:00:00`) 會產生歧義，並將被視為 UTC 處理。
:::

## 雲端硬碟 (Drive)

```bash
$GAPI drive search "quarterly report" --max 10
$GAPI drive search "mimeType='application/pdf'" --raw-query --max 5
```

## 試算表 (Sheets)

```bash
# 讀取一個範圍
$GAPI sheets get SHEET_ID "Sheet1!A1:D10"

# 寫入一個範圍
$GAPI sheets update SHEET_ID "Sheet1!A1:B2" --values '[["Name","Score"],["Alice","95"]]'

# 附加列
$GAPI sheets append SHEET_ID "Sheet1!A:C" --values '[["new","row","data"]]'
```

## 文件 (Docs)

```bash
$GAPI docs get DOC_ID
```

回傳文件標題與完整的文字內容。

## 聯絡人 (Contacts)

```bash
$GAPI contacts list --max 20
```

## 輸出格式

所有指令均回傳 JSON。各項服務的關鍵欄位如下：

| 指令 | 欄位 |
|---------|--------|
| `gmail search` | `id`, `threadId`, `from`, `to`, `subject`, `date`, `snippet`, `labels` |
| `gmail get` | `id`, `threadId`, `from`, `to`, `subject`, `date`, `labels`, `body` |
| `gmail send/reply` | `status`, `id`, `threadId` |
| `calendar list` | `id`, `summary`, `start`, `end`, `location`, `description`, `htmlLink` |
| `calendar create` | `status`, `id`, `summary`, `htmlLink` |
| `drive search` | `id`, `name`, `mimeType`, `modifiedTime`, `webViewLink` |
| `contacts list` | `name`, `emails`, `phones` |
| `sheets get` | 儲存格數值的二維陣列 |

## 疑難排解

| 問題 | 解決方法 |
|---------|-----|
| `NOT_AUTHENTICATED` | 執行設定 (要求 Hermes 設定 Google Workspace) |
| `REFRESH_FAILED` | 權杖已撤銷 —— 重新執行授權步驟 |
| `HttpError 403: Insufficient Permission` | 缺少範圍 (Scope) —— 撤銷並使用正確的服務重新授權 |
| `HttpError 403: Access Not Configured` | API 未在 Google Cloud Console 中啟用 |
| `ModuleNotFoundError` | 執行帶有 `--install-deps` 參數的設定腳本 |
