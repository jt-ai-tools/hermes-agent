---
title: 瀏覽器自動化
description: 透過多種提供者控制瀏覽器，包含經由 CDP 的本地 Chrome 或雲端瀏覽器，用於網頁互動、表單填寫、網頁抓取等。
sidebar_label: 瀏覽器
sidebar_position: 5
---

# 瀏覽器自動化

Hermes Agent 包含一套完整的瀏覽器自動化工具集，並提供多種後端選項：

- **Browserbase 雲端模式**：透過 [Browserbase](https://browserbase.com) 使用受控的雲端瀏覽器和反機器人工具。
- **Browser Use 雲端模式**：透過 [Browser Use](https://browser-use.com) 作為替代的雲端瀏覽器提供者。
- **Firecrawl 雲端模式**：透過 [Firecrawl](https://firecrawl.dev) 使用內建抓取功能的雲端瀏覽器。
- **Camofox 本地模式**：透過 [Camofox](https://github.com/jo-inc/camofox-browser) 進行本地反偵測瀏覽（基於 Firefox 的指紋偽裝）。
- **經由 CDP 的本地 Chrome**：使用 `/browser connect` 將瀏覽器工具連接到您自己的 Chrome 實例。
- **本地瀏覽器模式**：透過 `agent-browser` CLI 和本地安裝的 Chromium 執行。

在所有模式下，代理程式都可以導航網站、與頁面元素互動、填寫表單並提取資訊。

## 概覽

頁面以 **無障礙樹 (Accessibility Trees)**（純文字快照）表示，非常適合 LLM 代理程式。互動元素會獲得引用 ID（如 `@e1`、`e2`），代理程式使用這些 ID 進行點擊和輸入。

核心能力：

- **多提供者雲端執行**：支援 Browserbase、Browser Use 或 Firecrawl —— 無需本地瀏覽器。
- **本地 Chrome 整合**：透過 CDP 連接到您正在執行的 Chrome，進行手動輔助瀏覽。
- **內建匿蹤功能**：隨機指紋、驗證碼 (CAPTCHA) 破解、住宅代理 (Browserbase)。
- **工作階段隔離**：每個任務都有獨立的瀏覽器工作階段。
- **自動清理**：閒置的工作階段會在逾時後自動關閉。
- **視覺分析**：螢幕截圖 + AI 分析，用於視覺理解。

## 設定

### Browserbase 雲端模式

要使用 Browserbase 管理的雲端瀏覽器，請加入：

```bash
# 加入至 ~/.hermes/.env
BROWSERBASE_API_KEY=***
BROWSERBASE_PROJECT_ID=您的專案-ID
```

請在 [browserbase.com](https://browserbase.com) 獲取您的憑據。

### Browser Use 雲端模式

要將 Browser Use 作為您的雲端瀏覽器提供者，請加入：

```bash
# 加入至 ~/.hermes/.env
BROWSER_USE_API_KEY=***
```

請在 [browser-use.com](https://browser-use.com) 獲取您的 API 金鑰。Browser Use 透過其 REST API 提供雲端瀏覽器。如果同時設置了 Browserbase 和 Browser Use 的憑據，則以 Browserbase 為優先。

### Firecrawl 雲端模式

要將 Firecrawl 作為您的雲端瀏覽器提供者，請加入：

```bash
# 加入至 ~/.hermes/.env
FIRECRAWL_API_KEY=fc-***
```

請在 [firecrawl.dev](https://firecrawl.dev) 獲取您的 API 金鑰。然後選擇 Firecrawl 作為您的瀏覽器提供者：

```bash
hermes setup tools
# → Browser Automation → Firecrawl
```

選填設定：

```bash
# 自行架設的 Firecrawl 實例 (預設：https://api.firecrawl.dev)
FIRECRAWL_API_URL=http://localhost:3002

# 工作階段存活時間 (TTL)，以秒為單位 (預設：300)
FIRECRAWL_BROWSER_TTL=600
```

### Camofox 本地模式

[Camofox](https://github.com/jo-inc/camofox-browser) 是一個封裝了 Camoufox（一個具有 C++ 指紋偽裝功能的 Firefox 分支）的自行架設 Node.js 伺服器。它提供本地反偵測瀏覽，無需依賴雲端。

```bash
# 安裝並執行
git clone https://github.com/jo-inc/camofox-browser && cd camofox-browser
npm install && npm start   # 首次執行會下載 Camoufox (~300MB)

# 或透過 Docker 執行
docker run -d --network host -e CAMOFOX_PORT=9377 jo-inc/camofox-browser
```

然後在 `~/.hermes/.env` 中設定：

```bash
CAMOFOX_URL=http://localhost:9377
```

或透過 `hermes tools` → Browser Automation → Camofox 進行配置。

當設定了 `CAMOFOX_URL` 時，所有瀏覽器工具都會自動透過 Camofox 路由，而不是 Browserbase 或 agent-browser。

#### 持久化瀏覽器工作階段

預設情況下，每個 Camofox 工作階段都會獲得隨機身份 —— Cookie 和登入資訊在代理程式重啟後不會保留。要啟用持久化瀏覽器工作階段：

```yaml
# 在 ~/.hermes/config.yaml 中
browser:
  camofox:
    managed_persistence: true
```

啟用後，Hermes 會向 Camofox 發送穩定的設定檔範圍 (profile-scoped) 身份。Camofox 伺服器將此身份映射到持久化瀏覽器設定檔目錄，因此 Cookie、登入資訊和 localStorage 在重啟後仍會保留。不同的 Hermes 設定檔將獲得不同的瀏覽器設定檔（設定檔隔離）。

:::note
Camofox 伺服器端也必須配置 `CAMOFOX_PROFILE_DIR`，持久化功能才能運作。
:::

#### VNC 即時查看

當 Camofox 在有介面 (headed) 模式下執行時，它會在健康檢查回應中提供 VNC 連接埠。Hermes 會自動發現此埠，並在導航回應中包含 VNC URL，以便代理程式分享連結供您即時觀看瀏覽器畫面。

### 經由 CDP 的本地 Chrome (`/browser connect`)

除了雲端提供者，您還可以透過 Chrome 開發者工具協定 (CDP) 將 Hermes 瀏覽器工具連接到您正在執行的 Chrome 實例。這在您想即時查看代理程式的操作、與需要您自己的 Cookie/工作階段的頁面互動，或想節省雲端瀏覽器成本時非常有用。

在 CLI 中使用：

```
/browser connect              # 連接到位於 ws://localhost:9222 的 Chrome
/browser connect ws://host:port  # 連接到特定的 CDP 端點
/browser status               # 檢查目前連線狀態
/browser disconnect            # 中斷連線並返回雲端/本地模式
```

如果 Chrome 尚未開啟遠端除錯功能，Hermes 會嘗試以 `--remote-debugging-port=9222` 自動啟動它。

:::tip
手動啟動啟用 CDP 的 Chrome：
```bash
# Linux
google-chrome --remote-debugging-port=9222

# macOS
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --remote-debugging-port=9222
```
:::

透過 CDP 連接時，所有瀏覽器工具（`browser_navigate`、`browser_click` 等）都會在您的實時 Chrome 實例上操作，而不是啟動雲端工作階段。

### 本地瀏覽器模式

如果您 **沒有** 設定任何雲端憑據且未使用 `/browser connect`，Hermes 仍可透過由 `agent-browser` 驅動的本地 Chromium 安裝來使用瀏覽器工具。

### 選填環境變數

```bash
# 住宅代理，用於更好的驗證碼破解 (預設："true")
BROWSERBASE_PROXIES=true

# 使用自訂 Chromium 的進階匿蹤功能 —— 需要 Scale 方案 (預設："false")
BROWSERBASE_ADVANCED_STEALTH=false

# 斷線後的工作階段重連 —— 需要付費方案 (預設："true")
BROWSERBASE_KEEP_ALIVE=true

# 自訂工作階段逾時（以毫秒為單位，預設為專案預設值）
# 範例：600000 (10 分鐘), 1800000 (30 分鐘)
BROWSERBASE_SESSION_TIMEOUT=600000

# 自動清理前的閒置逾時（以秒為單位，預設：120）
BROWSER_INACTIVITY_TIMEOUT=120
```

### 安裝 agent-browser CLI

```bash
npm install -g agent-browser
# 或在儲存庫中本地安裝：
npm install
```

:::info
`browser` 工具集必須包含在您的設定檔 `toolsets` 清單中，或透過 `hermes config set toolsets '["hermes-cli", "browser"]'` 啟用。
:::

## 可用工具

### `browser_navigate`

導航至 URL。必須在呼叫任何其他瀏覽器工具之前呼叫。此操作會初始化 Browserbase 工作階段。

```
導航至 https://github.com/NousResearch
```

:::tip
對於簡單的資訊檢索，建議優先使用 `web_search` 或 `web_extract` —— 它們更快且更便宜。僅在需要與頁面 **互動**（點擊按鈕、填寫表單、處理動態內容）時才使用瀏覽器工具。
:::

### `browser_snapshot`

獲取目前頁面無障礙樹的純文字快照。返回帶有引用 ID（如 `@e1`、`@e2`）的互動元素，供 `browser_click` 和 `browser_type` 使用。

- **`full=false`** (預設值)：僅顯示互動元素的精簡視圖。
- **`full=true`**：完整的頁面內容。

超過 8000 個字元的快照會自動由 LLM 進行摘要。

### `browser_click`

點擊由快照中引用 ID 識別的元素。

```
點擊 @e5 以按下 "Sign In" 按鈕
```

### `browser_type`

在輸入欄位中輸入文字。會先清除該欄位，然後輸入新文字。

```
在搜尋欄位 @e3 中輸入 "hermes agent"
```

### `browser_scroll`

向上或向下捲動頁面以顯示更多內容。

```
向下捲動以查看更多結果
```

### `browser_press`

按下鍵盤按鍵。用於提交表單或導航。

```
按下 Enter 以提交表單
```

支援的按鍵：`Enter`、`Tab`、`Escape`、`ArrowDown`、`ArrowUp` 等。

### `browser_back`

返回瀏覽器歷史記錄中的上一頁。

### `browser_get_images`

列出目前頁面上的所有圖片及其 URL 和替代文字 (alt text)。用於尋找需要分析的圖片。

### `browser_vision`

拍攝螢幕截圖並使用視覺 AI 進行分析。當文字快照無法捕捉重要的視覺資訊時使用此功能 —— 特別適用於驗證碼、複雜佈局或視覺驗證挑戰。

截圖會被持久化儲存，並在 AI 分析的同時返回檔案路徑。在通訊平台（Telegram、Discord、Slack、WhatsApp）上，您可以要求代理程式分享截圖 —— 它將透過 `MEDIA:` 機制以原生圖片附件的形式發送。

```
此頁面上的圖表顯示了什麼？
```

截圖儲存在 `~/.hermes/cache/screenshots/` 中，並在 24 小時後自動清理。

### `browser_console`

獲取目前頁面的瀏覽器主控台輸出（log/warn/error 訊息）和未捕獲的 JavaScript 異常。這對於偵測無障礙樹中未顯示的靜默 JS 錯誤至關重要。

```
檢查瀏覽器主控台是否有任何 JavaScript 錯誤
```

使用 `clear=True` 在讀取後清除主控台，以便隨後的呼叫僅顯示新訊息。

## 實務範例

### 填寫網頁表單

```
使用者：使用我的電子郵件 john@example.com 在 example.com 註冊帳號

代理程式工作流：
1. browser_navigate("https://example.com/signup")
2. browser_snapshot()  → 看到帶有引用 ID 的表單欄位
3. browser_type(ref="@e3", text="john@example.com")
4. browser_type(ref="@e5", text="SecurePass123")
5. browser_click(ref="@e8")  → 點擊 "Create Account"
6. browser_snapshot()  → 確認成功
```

### 研究動態內容

```
使用者：目前 GitHub 上最熱門的儲存庫有哪些？

代理程式工作流：
1. browser_navigate("https://github.com/trending")
2. browser_snapshot(full=true)  → 讀取熱門儲存庫清單
3. 返回格式化的結果
```

## 工作階段錄製

自動將瀏覽器工作階段錄製為 WebM 影片檔案：

```yaml
browser:
  record_sessions: true  # 預設：false
```

啟用後，錄製會在第一次 `browser_navigate` 時自動開始，並在工作階段關閉時儲存至 `~/.hermes/browser_recordings/`。支援本地和雲端 (Browserbase) 模式。超過 72 小時的錄影會自動清理。

## 匿蹤功能 (Stealth Features)

Browserbase 提供自動匿蹤能力：

| 功能 | 預設值 | 備註 |
|---------|---------|-------|
| 基本匿蹤 | 始終開啟 | 隨機指紋、視窗大小隨機化、驗證碼破解 |
| 住宅代理 | 開啟 | 透過住宅 IP 路由以獲得更好的存取權限 |
| 進階匿蹤 | 關閉 | 自訂 Chromium 建構版，需要 Scale 方案 |
| 保持連線 | 開啟 | 網路波動後的工作階段重連 |

:::note
如果您的方案不支援付費功能，Hermes 會自動降級 —— 首先關閉 `keepAlive`，然後是代理 —— 因此在免費方案上瀏覽仍可運作。
:::

## 工作階段管理

- 每個任務透過 Browserbase 獲得一個隔離的瀏覽器工作階段。
- 工作階段在閒置後會自動清理（預設：2 分鐘）。
- 背景執行緒每 30 秒檢查一次過期的工作階段。
- 程序結束時會執行緊急清理，防止產生孤兒工作階段。
- 工作階段透過 Browserbase API 釋放（`REQUEST_RELEASE` 狀態）。

## 限制

- **基於文字的互動** —— 依賴無障礙樹，而非像素座標。
- **快照大小** —— 大型頁面在 8000 個字元時可能會被截斷或由 LLM 摘要。
- **工作階段逾時** —— 雲端工作階段會根據您的提供者方案設定而過期。
- **成本** —— 雲端工作階段會消耗提供者額度；工作階段會在對話結束或閒置後自動清理。請使用 `/browser connect` 進行免費的本地瀏覽。
- **不支援檔案下載** —— 無法從瀏覽器下載檔案。
