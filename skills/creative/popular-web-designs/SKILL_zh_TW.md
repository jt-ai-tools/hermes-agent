---
name: popular-web-designs
description: >
  從真實網站中提取的 54 套生產等級設計系統。載入範本即可生成符合 Stripe、Linear、Vercel、Notion、Airbnb 等網站視覺識別的 HTML/CSS。每個範本均包含色彩、字體、組件、佈局規則及即用型 CSS 數值。
version: 1.0.0
author: Hermes Agent + Teknium (設計系統源自 VoltAgent/awesome-design-md)
license: MIT
tags: [design, css, html, ui, web-development, design-systems, templates]
triggers:
  - 建立一個看起來像 ... 的頁面
  - 讓它看起來像 stripe
  - 像 linear 一樣設計
  - vercel 風格
  - 建立一個 UI
  - 網頁設計
  - 登陸頁面 (landing page)
  - 儀表板設計
  - 網站樣式仿照 ...
---

# 熱門網頁設計 (Popular Web Designs)

54 套真實世界的設計系統，可在生成 HTML/CSS 時直接使用。每個範本都捕捉了網站完整的視覺語言：調色盤、字體階層、組件樣式、間距系統、陰影、響應式行為，以及帶有精確 CSS 數值的實用代理提示詞。

## 如何使用

1. 從下方的目錄中挑選一個設計。
2. 載入它：`skill_view(name="popular-web-designs", file_path="templates/<site>_zh_TW.md")`
3. 在生成 HTML 時使用其中的設計標記 (design tokens) 和組件規範。
4. 搭配 `generative-widgets` 技能，透過 cloudflared 隧道呈現結果。

每個範本頂部都包含 **Hermes 實作說明** 區塊，提供：
- CDN 替代字體與 Google Fonts `<link>` 標籤（可直接貼上）。
- 主要字體與等寬字體的 CSS font-family 堆疊。
- 提醒使用 `write_file` 建立 HTML 並使用 `browser_vision` 進行驗證。

## HTML 生成模式

```html
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>頁面標題</title>
  <!-- 貼上來自範本 Hermes 說明區塊的 Google Fonts <link> -->
  <link href="https://fonts.googleapis.com/css2?family=..." rel="stylesheet">
  <style>
    /* 將範本的調色盤套用為 CSS 自定義屬性 */
    :root {
      --color-bg: #ffffff;
      --color-text: #171717;
      --color-accent: #533afd;
      /* ... 更多來自範本第 2 節內容 */
    }
    /* 套用來自範本第 3 節的字體設定 */
    body {
      font-family: 'Inter', system-ui, sans-serif;
      color: var(--color-text);
      background: var(--color-bg);
    }
    /* 套用來自範本第 4 節的組件樣式 */
    /* 套用來自範本第 5 節的佈局 */
    /* 套用來自範本第 6 節的陰影 */
  </style>
</head>
<body>
  <!-- 使用範本中的組件規範進行構建 -->
</body>
</html>
```

使用 `write_file` 寫入檔案，透過 `generative-widgets` 工作流（cloudflared 隧道）啟動服務，並使用 `browser_vision` 驗證結果以確認視覺精確度。

## 字體替換參考

大多數網站使用無法透過 CDN 獲取的專有字體。每個範本都映射到一個能保留原設計特徵的 Google Fonts 替代字體。常見映射如下：

| 專有字體 | CDN 替代字體 | 特徵 |
|---|---|---|
| Geist / Geist Sans | Geist (Google Fonts) | 幾何感、緊湊的字距 |
| Geist Mono | Geist Mono (Google Fonts) | 簡潔等寬、支援合字 |
| sohne-var (Stripe) | Source Sans 3 | 輕盈優雅 |
| Berkeley Mono | JetBrains Mono | 技術感等寬 |
| Airbnb Cereal VF | DM Sans | 圓潤、友好的幾何感 |
| Circular (Spotify) | DM Sans | 幾何感、溫潤 |
| figmaSans | Inter | 簡潔的人文主義風格 |
| Pin Sans (Pinterest) | DM Sans | 友好、圓潤 |
| NVIDIA-EMEA | Inter (或 Arial 系統字) | 工業感、簡潔 |
| CoinbaseDisplay/Sans | DM Sans | 幾何感、具信任感 |
| UberMove | DM Sans | 粗壯、緊湊 |
| HashiCorp Sans | Inter | 企業感、中性 |
| waldenburgNormal (Sanity) | Space Grotesk | 幾何感、略微壓縮 |
| IBM Plex Sans/Mono | IBM Plex Sans/Mono | 可在 Google Fonts 獲取 |
| Rubik (Sentry) | Rubik | 可在 Google Fonts 獲取 |

當範本的 CDN 字體與原始字體匹配（如 Inter, IBM Plex, Rubik, Geist）時，不會有替換損失。當使用替代字體（如用 DM Sans 替換 Circular，用 Source Sans 3 替換 sohne-var）時，請嚴格遵循範本的字重、大小和字距 (letter-spacing) 數值 —— 這些比特定的字體外觀更能承載視覺識別。

## 設計目錄

### AI 與機器學習 (AI & Machine Learning)

| 範本 | 網站 | 風格 |
|---|---|---|
| `claude_zh_TW.md` | Anthropic Claude | 溫暖的赤陶色強調，簡潔的社論佈局 |
| `cohere_zh_TW.md` | Cohere | 鮮豔的漸層，數據豐富的儀表板美學 |
| `elevenlabs_zh_TW.md` | ElevenLabs | 深色電影感 UI，音訊波形美學 |
| `minimax_zh_TW.md` | Minimax | 帶有霓虹強調的大膽深色介面 |
| `mistral.ai_zh_TW.md` | Mistral AI | 法式工藝極簡主義，紫色調 |
| `ollama_zh_TW.md` | Ollama | 終端優先，單色簡約 |
| `opencode.ai_zh_TW.md` | OpenCode AI | 開發者導向深色主題，全等寬字體 |
| `replicate_zh_TW.md` | Replicate | 潔白畫布，代碼優先 |
| `runwayml_zh_TW.md` | RunwayML | 電影感深色 UI，媒體豐富佈局 |
| `together.ai_zh_TW.md` | Together AI | 技術感，藍圖式設計 |
| `voltagent_zh_TW.md` | VoltAgent | 純黑畫布，翡翠綠強調，終端原生感 |
| `x.ai_zh_TW.md` | xAI | 冷峻單色，未來主義極簡，全等寬字體 |

### 開發者工具與平台 (Developer Tools & Platforms)

| 範本 | 網站 | 風格 |
|---|---|---|
| `cursor_zh_TW.md` | Cursor | 流暢深色介面，漸層強調 |
| `expo_zh_TW.md` | Expo | 深色主題，緊湊字距，代碼中心 |
| `linear.app_zh_TW.md` | Linear | 極簡深色模式，精確，紫色強調 |
| `lovable_zh_TW.md` | Lovable | 俏皮漸層，友好的開發者美學 |
| `mintlify_zh_TW.md` | Mintlify | 簡潔，綠色強調，閱讀優化 |
| `posthog_zh_TW.md` | PostHog | 俏皮品牌形象，開發者友好的深色 UI |
| `raycast_zh_TW.md` | Raycast | 流暢深色邊框，鮮豔漸層強調 |
| `resend_zh_TW.md` | Resend | 極簡深色主題，等寬字體強調 |
| `sentry_zh_TW.md` | Sentry | 深色儀表板，數據密集，粉紫色強調 |
| `supabase_zh_TW.md` | Supabase | 深翡翠綠主題，代碼優先開發者工具 |
| `superhuman_zh_TW.md` | Superhuman | 高級深色 UI，鍵盤優先，紫色光暈 |
| `vercel_zh_TW.md` | Vercel | 黑白精確感，Geist 字體系統 |
| `warp_zh_TW.md` | Warp | 類 IDE 深色介面，區塊式指令 UI |
| `zapier_zh_TW.md` | Zapier | 溫暖橘色，友好的插畫驅動型 |

### 基礎設施與雲端 (Infrastructure & Cloud)

| 範本 | 網站 | 風格 |
|---|---|---|
| `clickhouse_zh_TW.md` | ClickHouse | 黃色強調，技術文件風格 |
| `composio_zh_TW.md` | Composio | 現代深色，帶有彩色整合圖示 |
| `hashicorp_zh_TW.md` | HashiCorp | 企業級簡潔，黑白配色 |
| `mongodb_zh_TW.md` | MongoDB | 綠葉品牌形象，專注於開發者文件 |
| `sanity_zh_TW.md` | Sanity | 紅色強調，內容優先社論佈局 |
| `stripe_zh_TW.md` | Stripe | 招牌紫色漸層，300 字重優雅感 |

### 設計與生產力 (Design & Productivity)

| 範本 | 網站 | 風格 |
|---|---|---|
| `airtable_zh_TW.md` | Airtable | 多彩、友好、結構化數據美學 |
| `cal_zh_TW.md` | Cal.com | 簡潔中性 UI，開發者導向的簡約感 |
| `clay_zh_TW.md` | Clay | 有機形狀，柔和漸層，藝術指導式佈局 |
| `figma_zh_TW.md` | Figma | 鮮豔多色，俏皮且專業 |
| `framer_zh_TW.md` | Framer | 大膽黑藍配色，動效優先，設計領先 |
| `intercom_zh_TW.md` | Intercom | 友好的藍色調，對話式 UI 模式 |
| `miro_zh_TW.md` | Miro | 明亮黃色強調，無限畫布美學 |
| `notion_zh_TW.md` | Notion | 溫暖極簡主義，襯線體標題，柔和表面 |
| `pinterest_zh_TW.md` | Pinterest | 紅色強調，瀑布流網格，圖片優先佈局 |
| `webflow_zh_TW.md` | Webflow | 藍色強調，精緻的行銷網站美學 |

### 金融科技與加密貨幣 (Fintech & Crypto)

| 範本 | 網站 | 風格 |
|---|---|---|
| `coinbase_zh_TW.md` | Coinbase | 簡潔藍色識別，專注信任，機構感 |
| `kraken_zh_TW.md` | Kraken | 紫色強調深色 UI，數據密集儀表板 |
| `revolut_zh_TW.md` | Revolut | 流暢深色介面，漸層卡片，金融精確感 |
| `wise_zh_TW.md` | Wise | 明亮綠色強調，友好且清晰 |

### 企業與消費級 (Enterprise & Consumer)

| 範本 | 網站 | 風格 |
|---|---|---|
| `airbnb_zh_TW.md` | Airbnb | 溫暖珊瑚色強調，攝影驅動，圓潤 UI |
| `apple_zh_TW.md` | Apple | 高級感留白，SF Pro 字體，電影感影像 |
| `bmw_zh_TW.md` | BMW | 深色高級表面，精確工程美學 |
| `ibm_zh_TW.md` | IBM | Carbon 設計系統，結構化藍色調 |
| `nvidia_zh_TW.md` | NVIDIA | 綠黑能量感，技術實力美學 |
| `spacex_zh_TW.md` | SpaceX | 冷峻黑白，全版影像，未來感 |
| `spotify_zh_TW.md` | Spotify | 深色底鮮豔綠色，大膽字體，專輯封面驅動 |
| `uber_zh_TW.md` | Uber | 大膽黑白配色，緊湊字體，都市能量感 |

## 挑選設計

根據內容匹配設計：

- **開發者工具 / 儀表板**：Linear, Vercel, Supabase, Raycast, Sentry
- **文件 / 內容網站**：Mintlify, Notion, Sanity, MongoDB
- **行銷 / 登陸頁面**：Stripe, Framer, Apple, SpaceX
- **深色模式 UI**：Linear, Cursor, ElevenLabs, Warp, Superhuman
- **淺色 / 簡潔 UI**：Vercel, Stripe, Notion, Cal.com, Replicate
- **俏皮 / 友好**：PostHog, Figma, Lovable, Zapier, Miro
- **高級 / 奢華**：Apple, BMW, Stripe, Superhuman, Revolut
- **數據密集 / 儀表板**：Sentry, Kraken, Cohere, ClickHouse
- **等寬字體 / 終端美學**：Ollama, OpenCode, x.ai, VoltAgent
