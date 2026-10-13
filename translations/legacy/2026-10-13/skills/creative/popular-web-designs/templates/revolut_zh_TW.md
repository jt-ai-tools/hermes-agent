# 設計系統：Revolut


> **Hermes Agent — 實作筆記**
>
> 原始網站使用專有字體。對於自包含的 HTML 輸出，請使用以下 CDN 替代方案：
> - **主要字體：** `Inter` | **等寬字體：** `系統等寬字體組合`
> - **字體組合 (CSS)：** `font-family: 'Inter', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;`
> - **等寬字體組合 (CSS)：** `font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace;`
> ```html
> <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
> ```
> 使用 `write_file` 建立 HTML，透過 `generative-widgets` 技能（cloudflared 隧道）提供服務。
> 生成後使用 `browser_vision` 驗證視覺準確性。

## 1. 視覺主題與氛圍

Revolut 的網站是金融科技（fintech）自信的結晶 —— 一種透過巨大的排版、充裕的留白和嚴謹的中性色調來傳達「您的資金由專業人士打理」的設計系統。視覺語言建立在 Aeonik Pro 之上，這是一種幾何無襯線體（geometric grotesque），在 136px、字重 500 且帶有激進的負字距（-2.72px）下，營造出廣告看板規模的標題。這不是低調的品牌設計，而是體育場規模的金融科技。

色彩系統建立在全面的 `--rui-*` (Revolut UI) Token 架構之上，為每個狀態進行語義化命名：危險 (`#e23b4a`)、警告 (`#ec7e00`)、藍綠色 (`#00a87e`)、藍色 (`#494fdf`)、深粉色 (`#e61e49`) 等。但行銷頁面本身卻異常克制 —— 近黑色 (`#191c1f`) 和純白色 (`#ffffff`) 佔據主導地位，彩色的語義化 Token 則保留給產品介面，而非行銷頁面。

Revolut 的特色在於其「全藥丸型（pill-everything）」按鈕系統。每個按鈕都使用 9999px 的圓角 —— 主要深色 (`#191c1f`)、次要淺色 (`#f4f4f4`)、外框型（透明 + 2px 實線）以及深色背景上的幽靈按鈕 (`rgba(244,244,244,0.1) + 2px 實線`)。內距非常充裕（14px 32px–34px），營造出大而自信的觸控目標。結合不同字重的 Inter 正文和正字距（0.16px–0.24px），結果便是一個既感高端又易於使用的設計 —— 現代時代的銀行業。

**關鍵特徵：**
- 136px 字重 500 的 Aeonik Pro 展示字體 —— 廣告看板規模的金融科技標題
- 近黑色 (`#191c1f`) + 白色二元色調，搭配全面的 `--rui-*` 語義化 Token
- 通用的藥丸型按鈕（9999px 圓角），搭配充裕的內距（14px 32px）
- 正文使用 Inter，並帶有正字距（0.16px–0.24px）
- 豐富的語義化色彩系統：藍、藍綠、粉、黃、綠、棕、危險、警告
- 未偵測到陰影 —— 僅透過色彩對比營造深度
- 展示標題行高緊湊 (1.00)，正文行高寬鬆 (1.50–1.56)

## 2. 色彩調色盤與角色

### 主要色彩
- **Revolut Dark** (`#191c1f`): 主要深色表面、按鈕背景、近黑色文字
- **純白色** (`#ffffff`): `--rui-color-action-label`，主要淺色表面
- **淺色表面** (`#f4f4f4`): 次要按鈕背景、微妙的表面色

### 品牌 / 互動
- **Revolut Blue** (`#494fdf`): `--rui-color-blue`，主要品牌藍
- **Action Blue** (`#4f55f1`): `--rui-color-action-photo-header-text`，頁首強調色
- **藍色文字** (`#376cd5`): `--website-color-blue-text`，連結藍

### 語義色彩
- **危險紅** (`#e23b4a`): `--rui-color-danger`，錯誤/破壞性操作
- **深粉色** (`#e61e49`): `--rui-color-deep-pink`，關鍵強調色
- **警告橘** (`#ec7e00`): `--rui-color-warning`，警告狀態
- **黃色** (`#b09000`): `--rui-color-yellow`，注意力
- **藍綠色** (`#00a87e`): `--rui-color-teal`，成功/正面
- **淺綠色** (`#428619`): `--rui-color-light-green`，次要成功色
- **綠色文字** (`#006400`): `--website-color-green-text`，綠色文字
- **淺藍色** (`#007bc2`): `--rui-color-light-blue`，資訊性
- **棕色** (`#936d62`): `--rui-color-brown`，暖性中性強調色
- **紅色文字** (`#8b0000`): `--website-color-red-text`，深紅文字

### 中性色階
- **中石板色 (Mid Slate)** (`#505a63`): 次要文字
- **酷灰色 (Cool Gray)** (`#8d969e`): 柔和文字、三級文字
- **灰色調** (`#c9c9cd`): `--rui-color-grey-tone-20`，框線/分隔線

## 3. 字體排版規則

### 字體族系
- **展示字體 (Display)**: `Aeonik Pro` —— 幾何無襯線體，未偵測到備用字體
- **正文 / UI**: `Inter` —— 標準系統無襯線體
- **備用字體**: 特定按鈕情境下使用 `Arial`

### 層級結構

| 角色 | 字體 | 大小 | 字重 | 行高 | 字距 (Letter Spacing) | 備註 |
|------|------|------|--------|-------------|----------------|-------|
| 超大展示字 (Display Mega) | Aeonik Pro | 136px (8.50rem) | 500 | 1.00 (緊湊) | -2.72px | 體育場規模主視覺 |
| 主視覺標題 (Display Hero) | Aeonik Pro | 80px (5.00rem) | 500 | 1.00 (緊湊) | -0.8px | 主要主視覺 |
| 區塊標題 | Aeonik Pro | 48px (3.00rem) | 500 | 1.21 (緊湊) | -0.48px | 特色區塊 |
| 副標題 | Aeonik Pro | 40px (2.50rem) | 500 | 1.20 (緊湊) | -0.4px | 子區塊 |
| 卡片標題 | Aeonik Pro | 32px (2.00rem) | 500 | 1.19 (緊湊) | -0.32px | 卡片標題 |
| 特色標題 | Aeonik Pro | 24px (1.50rem) | 400 | 1.33 | 正常 | 輕量標題 |
| 導覽 / UI | Aeonik Pro | 20px (1.25rem) | 500 | 1.40 | 正常 | 導覽、按鈕 |
| 大正文 | Inter | 18px (1.13rem) | 400 | 1.56 | -0.09px | 介紹文字 |
| 正文 | Inter | 16px (1.00rem) | 400 | 1.50 | 0.24px | 標準閱讀 |
| 半粗體正文 | Inter | 16px (1.00rem) | 600 | 1.50 | 0.16px | 強調正文 |
| 粗體連結正文 | Inter | 16px (1.00rem) | 700 | 1.50 | 0.24px | 粗體連結 |

### 原則
- **字重 500 作為展示預設**: Aeonik Pro 在所有標題中皆使用 Medium (500) —— 不使用粗體。這透過尺寸和字距而非粗細來建立權威感。
- **廣告看板字距**: 136px 下的 -2.72px 極其壓縮 —— 文字旨在讓人一目了然，類似機場標示。
- **正文正字距**: Inter 使用 +0.16px 至 +0.24px，營造出空靈且間距良好的閱讀文字，與壓縮的標題形成對比。

## 4. 元件樣式

### 按鈕

**主要深色藥丸按鈕**
- 背景：`#191c1f`
- 文字：`#ffffff`
- 內距：14px 32px
- 圓角：9999px (全藥丸)
- 懸停 (Hover)：透明度 0.85
- 聚焦 (Focus)：`0 0 0 0.125rem` 環狀

**次要淺色藥丸按鈕**
- 背景：`#f4f4f4`
- 文字：`#000000`
- 內距：14px 34px
- 圓角：9999px
- 懸停 (Hover)：透明度 0.85

**外框型藥丸按鈕**
- 背景：透明
- 文字：`#191c1f`
- 框線：`2px solid #191c1f`
- 內距：14px 32px
- 圓角：9999px

**深色背景上的幽靈按鈕**
- 背景：`rgba(244, 244, 244, 0.1)`
- 文字：`#f4f4f4`
- 框線：`2px solid #f4f4f4`
- 內距：14px 32px
- 圓角：9999px

### 卡片與容器
- 圓角：12px (小), 20px (卡片)
- 無陰影 —— 透過色彩對比實現扁平化表面
- 深淺色區塊交替

### 導覽
- Aeonik Pro 20px 字重 500
- 簡潔的頁首，漢堡選單切換器為 12px 圓角
- 藥丸型 CTA 右對齊

## 5. 版面原則

### 間距系統
- 基礎單位：8px
- 級距：4px, 6px, 8px, 14px, 16px, 20px, 24px, 32px, 40px, 48px, 80px, 88px, 120px
- 大型區塊間距：80px–120px

### 圓角半徑級距
- 標準 (12px)：導覽、小型按鈕
- 卡片 (20px)：特色卡片
- 藥丸型 (9999px)：所有按鈕

## 6. 深度與層次

| 層級 | 處理方式 | 用途 |
|-------|-----------|-----|
| 扁平 (Level 0) | 無陰影 | 萬物 —— Revolut 使用零陰影 |
| 聚焦 | `0 0 0 0.125rem` 環狀 | 無障礙聚焦 |

**陰影哲學**：Revolut 使用「零」陰影。深度完全來自深淺色區塊的對比以及元素之間充裕的留白。

## 7. 規範與禁止 (Do's and Don'ts)

### 規範
- 所有展示標題皆使用 Aeonik Pro 字重 500
- 所有按鈕皆套用 9999px 圓角 —— 藥丸形狀是通用的
- 使用充裕的按鈕內距 (14px 32px)
- 行銷表面保持近黑色 + 白色的調色盤
- 在 Inter 正文上套用正字距

### 禁止
- 不要使用陰影 —— Revolut 的設計本質就是扁平化
- 不要對 Aeonik Pro 標題使用粗體 (700) —— 預設字重為 500
- 不要使用小型按鈕 —— 充裕的內距是刻意設計的
- 不要將語義化色彩套用於行銷表面 —— 它們是為產品介面準備的

## 8. 回應式行為

### 斷點 (Breakpoints)
| 名稱 | 寬度 | 關鍵變化 |
|------|-------|-------------|
| 小型行動裝置 | <400px | 緊湊，單欄佈局 |
| 行動裝置 | 400–720px | 標準行動裝置 |
| 平板 | 720–1024px | 雙欄佈局 |
| 桌上型電腦 | 1024–1280px | 標準桌上型電腦 |
| 大型螢幕 | 1280–1920px | 完整佈局 |

## 9. Agent 提示詞指南

### 快速色彩參考
- 深色：Revolut Dark (`#191c1f`)
- 淺色：白色 (`#ffffff`)
- 表面色：淺色 (`#f4f4f4`)
- 藍色：Revolut Blue (`#494fdf`)
- 危險：紅色 (`#e23b4a`)
- 成功：藍綠色 (`#00a87e`)

### 元件提示詞範例
- "Create a hero: white background. Headline at 136px Aeonik Pro weight 500, line-height 1.00, letter-spacing -2.72px, #191c1f text. Dark pill CTA (#191c1f, 9999px, 14px 32px). Outlined pill secondary (transparent, 2px solid #191c1f)."
- "Build a pill button: #191c1f background, white text, 9999px radius, 14px 32px padding, 20px Aeonik Pro weight 500. Hover: opacity 0.85."

### 迭代指南
1. 標題使用 Aeonik Pro 500 —— 絕不使用粗體
2. 所有按鈕皆為藥丸型 (9999px) 並帶有充裕內距
3. 零陰影 —— 扁平化是 Revolut 的身份象徵
4. 行銷面使用近黑色 + 白色，產品面使用語義色彩
