# 設計系統：Coinbase

> **Hermes Agent — 實作筆記**
>
> 原始網站使用專有字體。為了產生自包含的 HTML 輸出，請使用以下 CDN 替代方案：
> - **主要字體：** `DM Sans` | **等寬字體：** `系統等寬字體堆疊`
> - **字體堆疊 (CSS)：** `font-family: 'DM Sans', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;`
> - **等寬字體堆疊 (CSS)：** `font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace;`
> ```html
> <link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,100..1000;1,9..40,100..1000&display=swap" rel="stylesheet">
> ```
> 使用 `write_file` 建立 HTML，並透過 `generative-widgets` 技術（cloudflared 隧道）提供服務。
> 產生後使用 `browser_vision` 驗證視覺準確性。

## 1. 視覺主題與氛圍

Coinbase 的網站是一個乾淨、值得信賴的加密貨幣平台，透過藍白二元調色盤傳達金融可靠性。設計使用 Coinbase 藍 (`#0052ff`) —— 一種深沉、飽和的藍色 —— 作為白色和近黑色表面上唯一的品牌強調色。其專有字型系列包括用於 Hero 標題的 CoinbaseDisplay、用於 UI 文字的 CoinbaseSans、用於內文閱讀的 CoinbaseText 以及用於圖示的 CoinbaseIcons —— 這是一個全方位的四字型系統。

按鈕系統為藥丸狀的行動呼籲 (CTA) 採用獨特的 56px 圓角，懸停時會轉換為較淺的藍色 (`#578bfa`)。設計在白色內容段落與深色 (`#0a0b0d`, `#282b31`) 功能段落之間交替，營造出專業、金融等級的介面。

**核心特徵：**
- 以 Coinbase 藍 (`#0052ff`) 作為唯一的品牌強調色
- 四字型專有系列：Display, Sans, Text, Icons
- 56px 圓角的藥丸狀按鈕，帶有藍色懸停轉換效果
- 近黑色 (`#0a0b0d`) 深色段落 + 白色淺色段落
- 顯示標題使用 1.00 行高 —— 極其緊湊
- 帶有藍色調的冷灰色次要表面 (`#eef0f3`)
- 部分按鈕標籤使用 `text-transform: lowercase` (全小寫) —— 較為少見

## 2. 色彩配置與角色

### 主要色彩 (Primary)
- **Coinbase 藍** (`#0052ff`)：主要品牌色、連結、CTA 邊框
- **純白色** (`#ffffff`)：主要淺色表面
- **近黑色** (`#0a0b0d`)：文字、深色段落背景
- **冷灰表面色** (`#e8f0f3`)：次要按鈕背景

### 互動色彩 (Interactive)
- **懸停藍** (`#578bfa`)：按鈕懸停背景
- **連結藍** (`#0667d0`)：次要連結顏色
- **弱化藍** (`#5b616e`)：20% 透明度的邊框顏色

### 表面色彩 (Surface)
- **深色卡片** (`#282b31`)：深色按鈕/卡片背景
- **淺色表面** (`rgba(247,247,247,0.88)`)：細微表面

## 3. 字體排版規則

### 字型系列
- **顯示字型 (Display)**：`CoinbaseDisplay` —— Hero 標題
- **UI / 無襯線字型 (Sans)**：`CoinbaseSans` —— 按鈕、標題、導航
- **內文字型 (Body)**：`CoinbaseText` —— 閱讀文字
- **圖示字型 (Icons)**：`CoinbaseIcons` —— 圖示字體

### 層級結構 (Hierarchy)

| 角色 | 字體 | 大小 | 字重 | 行高 | 備註 |
|------|------|------|--------|-------------|-------|
| Hero 顯示 | CoinbaseDisplay | 80px | 400 | 1.00 (緊湊) | 最大影響力 |
| 次要顯示 | CoinbaseDisplay | 64px | 400 | 1.00 | 次級 Hero |
| 三級顯示 | CoinbaseDisplay | 52px | 400 | 1.00 | 第三層級 |
| 段落標題 | CoinbaseSans | 36px | 400 | 1.11 (緊湊) | 功能段落 |
| 卡片標題 | CoinbaseSans | 32px | 400 | 1.13 | 卡片標題 |
| 功能標題 | CoinbaseSans | 18px | 600 | 1.33 | 功能強調 |
| 粗體內文 | CoinbaseSans | 16px | 700 | 1.50 | 強調內文 |
| 半粗體內文 | CoinbaseSans | 16px | 600 | 1.25 | 按鈕、導航 |
| 內文 | CoinbaseText | 18px | 400 | 1.56 | 標準閱讀 |
| 小型內文 | CoinbaseText | 16px | 400 | 1.50 | 次要閱讀 |
| 按鈕 | CoinbaseSans | 16px | 600 | 1.20 | +0.16px 字距 |
| 圖說 | CoinbaseSans | 14px | 600–700 | 1.50 | 元數據 |
| 小型文字 | CoinbaseSans | 13px | 600 | 1.23 | 標籤 |

## 4. 元件樣式 (Component Stylings)

### 按鈕 (Buttons)

**主要藥丸狀按鈕 (56px 圓角)**
- 背景：`#eef0f3` 或 `#282b31`
- 圓角：56px
- 邊框：與背景匹配的 `1px solid`
- 懸停 (Hover)：`#578bfa` (淺藍色)
- 焦點 (Focus)：`2px solid black` 外框

**全藥丸狀按鈕 (100000px 圓角)**
- 用於極大化的藥丸形狀

**藍色邊框按鈕**
- 邊框：`1px solid #0052ff`
- 背景：透明

### 卡片與容器 (Cards & Containers)
- 圓角：8px–40px 範圍
- 邊框：`1px solid rgba(91,97,110,0.2)`

## 5. 佈局原則 (Layout Principles)

### 間距系統
- 基礎：8px
- 比例：1px, 3px, 4px, 5px, 6px, 8px, 10px, 12px, 15px, 16px, 20px, 24px, 25px, 32px, 48px

### 圓角半徑比例 (Border Radius Scale)
- 小型 (4px–8px)：文章連結、小卡片
- 標準 (12px–16px)：卡片、選單
- 大型 (24px–32px)：功能容器
- 特大 (40px)：大按鈕/容器
- 藥丸狀 (56px)：主要 CTA
- 全圓角 (100000px)：極大化藥丸狀

## 6. 深度與層次 (Depth & Elevation)

極簡的陰影系統 —— 深度主要來自深/淺段落之間的色彩對比。

## 7. 規範事項 (Do's and Don'ts)

### 建議 (Do)
- 為主要互動元素使用 Coinbase 藍 (#0052ff)
- 所有 CTA 按鈕均應用 56px 圓角
- 僅將 CoinbaseDisplay 用於 Hero 標題
- 交替使用深色 (#0a0b0d) 和白色段落

### 避免 (Don't)
- 不要將藍色用於裝飾 —— 它僅具備功能性
- 不要在 CTA 上使用銳利邊角 —— 圓角最小需為 56px

## 8. 響應式行為 (Responsive Behavior)

斷點 (Breakpoints)：400px, 576px, 640px, 768px, 896px, 1280px, 1440px, 1600px

## 9. Agent 提示指南 (Agent Prompt Guide)

### 快速色彩參考
- 品牌色：Coinbase 藍 (`#0052ff`)
- 背景色：白色 (`#ffffff`)
- 深色表面：`#0a0b0d`
- 次要表面：`#eef0f3`
- 懸停色：`#578bfa`
- 文字色：`#0a0b0d`

### 元件提示範例
- 「建立 Hero 段落：白色背景。CoinbaseDisplay 80px，行高 1.00。藥丸狀 CTA (#eef0f3, 56px 圓角)。懸停：#578bfa。」
- 「構建深色段落：#0a0b0d 背景。CoinbaseDisplay 64px 白色文字。藍色強調連結 (#0052ff)。」
