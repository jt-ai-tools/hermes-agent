# 設計系統：Wise


> **Hermes Agent — 實作備註**
>
> 原始網站使用專有字體。為了產生獨立的 HTML 輸出，請使用以下 CDN 替代方案：
> - **主要字體：** `Inter` | **等寬字體：** `系統等寬字體堆疊 (system monospace stack)`
> - **字體堆疊 (CSS)：** `font-family: 'Inter', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;`
> - **等寬字體堆疊 (CSS)：** `font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace;`
> ```html
> <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
> ```
> 使用 `write_file` 建立 HTML，並透過 `generative-widgets` 技能（cloudflared 隧道）提供服務。
> 產生後使用 `browser_vision` 驗證視覺準確性。

## 1. 視覺主題與氛圍

Wise 的網站是一個大膽、充滿自信的金融科技平台，透過巨大的排版和獨特的萊姆綠點綴，傳達出「無國界資金」的理念。設計在溫暖的米白色畫布上運行，搭配近乎黑色的文字 (`#0e0f0c`) 和標誌性的 Wise Green (`#9fe870`) —— 一種清新、明亮的萊姆色，感覺充滿活力且樂觀，不同於傳統銀行企業化的藍色調。

排版使用 Wise Sans —— 一種專有字體，在展示標題中以極端的字重 900 (black) 使用，行高非常緊湊，僅為 0.85，並啟用 OpenType `"calt"`（上下文替換）。在 126px 的大小下，文字密度高到感覺像是一個抗議標語 —— 大膽、緊急且不容忽視。Inter 作為本文細節字體，預設以字重 600 來強調，營造出一致且自信的聲音。

Wise 的與眾不同之處在於其綠、白、黑相間的材質調色盤。萊姆綠 (`#9fe870`) 出現在按鈕上，搭配深綠色文字 (`#163300`)，創造出受自然啟發、感覺清新的行動呼籲 (CTA)。懸停狀態使用 `scale(1.05)` 擴張而非顏色變化 —— 按鈕在互動時物理性地增大。圓角系統對按鈕使用 9999px（膠囊型），對卡片使用 30px–40px，陰影系統極簡 —— 僅使用 `rgba(14,15,12,0.12) 0px 0px 0px 1px` 的環形陰影。

**核心特徵：**
- Wise Sans 字重 900，行高 0.85 —— 看板規模的大膽標題
- 萊姆綠 (`#9fe870`) 點綴搭配深綠色文字 (`#163300`) —— 受自然啟發的金融科技
- Inter 本文預設字重 600 —— 自信而非輕盈
- 近乎黑色 (`#0e0f0c`) 的主色調，帶有溫暖的綠色底蘊
- Scale(1.05) 懸停動畫 —— 按鈕在物理上增大
- 所有文字均啟用 OpenType `"calt"`
- 膠囊型按鈕 (9999px) 和大型圓角卡片 (30px–40px)
- 具備全面狀態管理的語義化顏色系統

## 2. 調色盤與角色

### 品牌主色
- **近黑色 (Near Black)** (`#0e0f0c`): 主要文字，深色區塊的背景
- **Wise 綠 (Wise Green)** (`#9fe870`): 主要 CTA 按鈕，品牌點綴色
- **深綠色 (Dark Green)** (`#163300`): 綠色背景上的按鈕文字，深綠色點綴
- **淺薄荷色 (Light Mint)** (`#e2f6d5`): 柔和的綠色表面，標籤背景
- **粉綠色 (Pastel Green)** (`#cdffad`): `--color-interactive-contrast-hover`，懸停點綴色

### 語義色
- **正向綠 (Positive Green)** (`#054d28`): `--color-sentiment-positive-primary`，成功狀態
- **危險紅 (Danger Red)** (`#d03238`): `--color-interactive-negative-hover`，錯誤/破壞性動作
- **警告黃 (Warning Yellow)** (`#ffd11a`): `--color-sentiment-warning-hover`，警告
- **背景青色 (Background Cyan)** (`rgba(56,200,255,0.10)`): `--color-background-accent`，資訊提示色
- **亮橘色 (Bright Orange)** (`#ffc091`): `--color-bright-orange`，溫暖的點綴色

### 中性色
- **溫暖深色 (Warm Dark)** (`#454745`): 次要文字，邊框
- **灰色 (Gray)** (`#868685`): 弱化文字，第三階顏色
- **淺色表面 (Light Surface)** (`#e8ebe6`): 細微帶綠調的淺色表面

## 3. 排版規則

### 字體系列
- **展示 (Display)**: `Wise Sans`, 備用: `Inter` —— 所有文字皆啟用 OpenType `"calt"`
- **本文 / UI (Body / UI)**: `Inter`, 備用: `Helvetica, Arial`

### 層級

| 角色 | 字體 | 大小 | 字重 | 行高 | 字距 | 備註 |
|------|------|------|--------|-------------|----------------|-------|
| 巨型展示 (Display Mega) | Wise Sans | 126px (7.88rem) | 900 | 0.85 (極緊湊) | 正常 | `"calt"` |
| 主視圖展示 (Display Hero) | Wise Sans | 96px (6.00rem) | 900 | 0.85 | 正常 | `"calt"` |
| 區塊標題 | Wise Sans | 64px (4.00rem) | 900 | 0.85 | 正常 | `"calt"` |
| 副標題 | Wise Sans | 40px (2.50rem) | 900 | 0.85 | 正常 | `"calt"` |
| 替代標題 | Inter | 78px (4.88rem) | 600 | 1.10 (緊湊) | -2.34px | `"calt"` |
| 卡片標題 | Inter | 26px (1.62rem) | 600 | 1.23 (緊湊) | -0.39px | `"calt"` |
| 特色標題 | Inter | 22px (1.38rem) | 600 | 1.25 (緊湊) | -0.396px | `"calt"` |
| 本文 | Inter | 18px (1.13rem) | 400 | 1.44 | 0.18px | `"calt"` |
| 本文中粗體 | Inter | 18px (1.13rem) | 600 | 1.44 | -0.108px | `"calt"` |
| 按鈕 | Inter | 18px–22px | 600 | 1.00–1.44 | -0.108px | `"calt"` |
| 註解 (Caption) | Inter | 14px (0.88rem) | 400–600 | 1.50–1.86 | -0.084px 至 -0.108px | `"calt"` |
| 小字 | Inter | 12px (0.75rem) | 400–600 | 1.00–2.17 | -0.084px 至 -0.108px | `"calt"` |

### 原則
- **字重 900 作為品牌識別**：Wise Sans Black (900) 專門用於展示標題 —— 這是任何已分析系統中字重最重的。它創造出的文字感覺像是蓋印、壓製出來的，具有物理感。
- **0.85 行高**：這是分析過最緊湊的展示行高。字母在垂直方向上重疊，創造出密集的、看板般的文字塊。
- **隨處可見的 "calt"**：在「所有」文字上啟用上下文替換 (Contextual alternates) —— 包括 Wise Sans 和 Inter。
- **本文預設字重 600**：Inter Semibold 是標準的閱讀字重 —— 充滿自信，而非輕飄飄。

## 4. 元件樣式

### 按鈕

**主要綠色膠囊 (Primary Green Pill)**
- 背景色：`#9fe870` (Wise Green)
- 文字顏色：`#163300` (Dark Green)
- 內距 (Padding)：5px 16px
- 圓角 (Radius)：9999px
- 懸停 (Hover)：scale(1.05) —— 按鈕物理性增大
- 點擊 (Active)：scale(0.95) —— 按鈕壓縮
- 聚焦 (Focus)：內縮環 (inset ring) + 輪廓線 (outline)

**次要微調膠囊 (Secondary Subtle Pill)**
- 背景色：`rgba(22, 51, 0, 0.08)` (8% 不透明度的深綠色)
- 文字顏色：`#0e0f0c`
- 內距 (Padding)：8px 12px 8px 16px
- 圓角 (Radius)：9999px
- 相同的縮放懸停/點擊行為

### 卡片與容器
- 圓角 (Radius)：16px (小), 30px (中), 40px (大卡片/表格)
- 邊框 (Border)：`1px solid rgba(14,15,12,0.12)` 或 `1px solid #9fe870` (綠色點綴)
- 陰影 (Shadow)：`rgba(14,15,12,0.12) 0px 0px 0px 1px` (環形陰影)

### 導覽列
- 帶綠色調的導覽懸停效果：`rgba(211,242,192,0.4)`
- 搭配 Wise 字標的簡潔頁首
- 靠右對齊的膠囊型 CTA

## 5. 版面原則

### 間距系統
- 基礎單位：8px
- 比例：1px, 2px, 3px, 4px, 5px, 8px, 10px, 11px, 12px, 16px, 18px, 19px, 20px, 22px, 24px

### 圓角比例 (Border Radius Scale)
- 極小 (2px)：連結、輸入框
- 標準 (10px)：組合框、輸入框
- 卡片 (16px)：小卡片、按鈕、單選框
- 中型 (20px)：連結、中型卡片
- 大型 (30px)：特色卡片
- 區塊 (40px)：表格、大型卡片
- 巨型 (1000px)：展示元素
- 膠囊型 (9999px)：所有按鈕、圖片
- 圓形 (50%)：圖示、標籤

## 6. 深度與層次

| 層級 | 處理方式 | 用途 |
|-------|-----------|-----|
| 平面 (Level 0) | 無陰影 | 預設 |
| 環形 (Level 1) | `rgba(14,15,12,0.12) 0px 0px 0px 1px` | 卡片邊框 |
| 內縮 (Level 2) | `rgb(134,134,133) 0px 0px 0px 1px inset` | 輸入框聚焦 |

**陰影哲學**：Wise 使用極簡的陰影 —— 僅限環形陰影。深度來自於鮮豔的綠色點綴在對比鮮明的中性畫布上。

## 7. 準則 (Do's and Don'ts)

### 建議 (Do)
- 在展示標題使用 Wise Sans 字重 900 —— 極端的大膽文字「就是」品牌本身
- 在 Wise Sans 展示標題應用 0.85 的行高 —— 極度緊湊是刻意為之
- 在主要 CTA 使用萊姆綠 (#9fe870) 並搭配深綠色 (#163300) 文字
- 在按鈕上應用 scale(1.05) 懸停和 scale(0.95) 點擊效果
- 在所有文字上啟用 "calt"
- 使用 Inter 字重 600 作為本文預設

### 避免 (Don't)
- 不要對 Wise Sans 使用輕盈的字重 —— 僅使用 900
- 不要放寬展示標題的 0.85 行高 —— 密集感就是識別度
- 不要將 Wise 綠作為大面積表面的背景 —— 它僅用於按鈕和點綴
- 不要跳過按鈕上的縮放動畫
- 不要使用傳統陰影 —— 僅使用環形陰影

## 8. 響應式行為

### 斷點 (Breakpoints)
| 名稱 | 寬度 | 關鍵變化 |
|------|-------|-------------|
| 行動裝置 | <576px | 單欄佈局 |
| 平板 | 576–992px | 雙欄佈局 |
| 桌上型電腦 | 992–1440px | 完整佈局 |
| 大型螢幕 | >1440px | 擴充佈局 |

## 9. Agent 提示詞指南

### 快速顏色參考
- 文字：近黑色 (`#0e0f0c`)
- 背景：白色 (`#ffffff` / 米白色)
- 點綴色：Wise 綠 (`#9fe870`)
- 按鈕文字：深綠色 (`#163300`)
- 次要色：灰色 (`#868685`)

### 元件提示詞範例
- "建立主視圖 (hero)：白色背景。標題使用 96px Wise Sans 字重 900，行高 0.85，啟用 'calt'，文字顏色 #0e0f0c。綠色膠囊型 CTA (#9fe870, 圓角 9999px, 內距 5px 16px, 文字顏色 #163300)。懸停效果：scale(1.05)。"
- "構建卡片：圓角 30px，1px 實線邊框 rgba(14,15,12,0.12)。標題使用 22px Inter 字重 600，本文使用 18px 字重 400。"

### 迭代指南
1. Wise Sans 900 搭配 0.85 行高 —— 極端字重「就是」品牌
2. 萊姆綠僅用於按鈕 —— 綠色背景上使用深綠色文字
3. 所有互動元素均有縮放動畫 (1.05 懸停, 0.95 點擊)
4. 所有內容皆啟用 "calt" —— 上下文替換是必須的
5. 本文使用 Inter 600 —— 充滿自信的閱讀字重
