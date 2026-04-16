# 設計系統：BMW

> **Hermes Agent — 實作筆記**
>
> 原始網站使用專有字體。對於自給自足的 HTML 輸出，請使用以下 CDN 替代方案：
> - **主要：** `DM Sans` | **等寬：** `system monospace stack`
> - **字體堆疊 (CSS)：** `font-family: 'DM Sans', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;`
> - **等寬字體堆疊 (CSS)：** `font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace;`
> ```html
> <link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,100..1000;1,9..40,100..1000&display=swap" rel="stylesheet">
> ```
> 使用 `write_file` 建立 HTML，透過 `generative-widgets` 技能（cloudflared 隧道）提供服務。
> 生成後使用 `browser_vision` 驗證視覺準確性。

## 1. 視覺主題與氛圍

BMW 的網站將汽車工程視覺化 —— 這是一個傳達精準、性能和德國工業自信的設計系統。頁面在深色的 Hero 區段（以全版汽車攝影為特色）與乾淨的白色內容區域之間交替，營造出一種電影般的節奏，讓人聯想到豪華汽車展廳中車輛在黑暗背景下被照亮的場景。BMW CI2020 設計語言（他們的企業識別更新）定義了每個元素。

排版建立在 BMWTypeNextLatin 之上 —— 這是具有兩個變體的專有字體：BMWTypeNextLatin Light (字重 300) 用於巨大的全大寫顯示標題，以及 BMWTypeNextLatin Regular 用於內文和 UI 文字。字重 300 的 60px 全大寫標題是具代表性的排版姿態 —— 輕量化的字體低聲細語著權威，而非大聲叫喊。備用字體堆疊包括 Helvetica 和日文字體 (Hiragino, Meiryo)，反映了 BMW 的全球佈局。

BMW 的獨特之處在於其由 CSS 變數驅動的主題系統。具備情境感知能力的變數 (`--site-context-highlight-color: #1c69d4`, `--site-context-focus-color: #0653b6`, `--site-context-metainfo-color: #757575`) 表明這是一個專為多品牌、多情境部署而設計的系統，顏色可以在全球範圍內更換。藍色點綴色 (`#1c69d4`) 是 BMW 的標誌性藍色 —— 節制地用於互動元素和聚焦狀態，絕不用作裝飾。系統中偵測不到任何邊框半徑 (border-radius) —— BMW 的設計是稜角分明、銳利邊角且毫不妥協的幾何形狀。

**關鍵特徵：**
- BMWTypeNextLatin Light (字重 300) 全大寫用於顯示標題 —— 低聲細語的權威
- BMW Blue (`#1c69d4`) 作為單一點綴色 —— 僅用於互動元素
- 偵測不到邊框半徑 —— 稜角分明、銳利邊角的工業幾何感
- 深色 Hero 攝影 + 白色內容區段 —— 展廳燈光節奏
- CSS 變數驅動的主題化：使用 `--site-context-*` 標記提供品牌靈活性
- 導覽強調使用字重 900 —— 與 300 的顯示標題形成極端對比
- 整個系統採用緊湊的行高 (1.15–1.30) —— 壓縮、高效、德國工程感
- 全版汽車攝影作為主要的視覺內容

## 2. 調色盤與角色

### 主要品牌 (Primary Brand)
- **Pure White** (`#ffffff`): `--site-context-theme-color`, 主要表面, 卡片背景
- **BMW Blue** (`#1c69d4`): `--site-context-highlight-color`, 主要互動點綴
- **BMW Focus Blue** (`#0653b6`): `--site-context-focus-color`, 鍵盤聚焦與啟用狀態

### 中性色階 (Neutral Scale)
- **Near Black** (`#262626`): 淺色表面上的主要文字, 深色連結文字
- **Meta Gray** (`#757575`): `--site-context-metainfo-color`, 次要文字, 元數據 (metadata)
- **Silver** (`#bbbbbb`): 三級文字, 弱化連結, 頁尾元素

### 互動狀態 (Interactive States)
- 所有連結在懸停時變為白色 (`#ffffff`) —— 暗示主要是深色表面的導覽
- 文字連結在懸停時不顯示底線 (`underline: none`) —— 乾淨的互動

### 陰影 (Shadows)
- 極簡陰影系統 —— 透過攝影以及深/淺色區段對比建立深度

## 3. 字體排版規則

### 字體系列 (Font Families)
- **顯示 Light (Display Light)**: `BMWTypeNextLatin Light`, 備用字體: `Helvetica, Arial, Hiragino Kaku Gothic ProN, Hiragino Sans, Meiryo`
- **內文 / UI (Body / UI)**: `BMWTypeNextLatin`, 相同的備用字體堆疊

### 層級 (Hierarchy)

| 角色 (Role) | 字體 | 大小 | 字重 | 行高 | 備註 |
|------|------|------|--------|-------------|-------|
| 顯示 Hero (Display Hero) | BMWTypeNextLatin Light | 60px (3.75rem) | 300 | 1.30 (tight) | `text-transform: uppercase` |
| 區段標題 (Section Heading) | BMWTypeNextLatin | 32px (2.00rem) | 400 | 1.30 (tight) | 主要區段標題 |
| 導覽強調 (Nav Emphasis) | BMWTypeNextLatin | 18px (1.13rem) | 900 | 1.30 (tight) | 導覽粗體項目 |
| 內文 (Body) | BMWTypeNextLatin | 16px (1.00rem) | 400 | 1.15 (tight) | 標準內文文字 |
| 粗體按鈕 (Button Bold) | BMWTypeNextLatin | 16px (1.00rem) | 700 | 1.20–2.88 | CTA 按鈕 |
| 按鈕 (Button) | BMWTypeNextLatin | 16px (1.00rem) | 400 | 1.15 (tight) | 標準按鈕 |

### 原則
- **輕量化顯示標題，沉重導覽列**：Hero 標題使用字重 300 營造出低調的優雅；導覽列使用字重 900 則營造出鮮明的權威感。這種極端的字重對比 (300 vs 900) 是標誌性的排版張力。
- **普遍的全大寫顯示**：60px 的 Hero 標題總是全大寫 —— 創造出一種宏偉的、建築般的品質。
- **一切都很緊湊**：整個系統的行高介於 1.15 到 1.30 之間。沒有多餘空間 —— 每一行都是壓縮、高效、德國工程設計。
- **單一字體系列**：BMWTypeNextLatin 處理從 60px 顯示標題到 16px 內文的一切 —— 透過同一字體在不同字重下的應用達成統一。

## 4. 元件樣式

### 按鈕 (Buttons)
- 文字：16px BMWTypeNextLatin, 主要為字重 700，次要為 400
- 行高：1.15–2.88 (大幅度變化暗示是透過內邊距 padding 驅動尺寸)
- 邊框：深色表面上的白色底邊框 (`1px solid #ffffff`)
- 無邊框半徑 —— 銳利的矩形按鈕

### 卡片與容器 (Cards & Containers)
- 無邊框半徑 —— 所有容器都是銳利邊角的矩形
- 淺色區段使用白色背景
- Hero/特色區段使用深色背景
- 大多數元素沒有可見邊框

### 導覽 (Navigation)
- 主要導覽連結使用 BMWTypeNextLatin 18px 字重 900
- 深色標題列上的白色文字
- BMW 標誌 54x54px
- 懸停：保持白色，無文字裝飾 (text-decoration: none)
- 標題列中的「首頁」文字連結

### 圖片處理 (Image Treatment)
- 全版汽車攝影
- 深色電影感燈光
- 滿版 Hero 圖片
- 汽車攝影作為主要的視覺內容

## 5. 佈局原則 (Layout Principles)

### 間距系統 (Spacing System)
- 基礎單位：8px
- 級別：1px, 5px, 8px, 10px, 12px, 15px, 16px, 20px, 24px, 30px, 32px, 40px, 45px, 56px, 60px

### 網格與容器 (Grid & Container)
- 全寬 Hero 攝影
- 內容區段居中
- 頁尾：多欄連結網格

### 留白哲學 (Whitespace Philosophy)
- **展廳節奏**：帶有充足內邊距的深色 Hero 區段營造出一種漫步在展廳中的感覺，每輛車都在其專屬空間內被聚光燈照亮。
- **壓縮內容**：內文文字區域使用緊湊的行高和簡潔的間距 —— 資訊密集且無浪費。

### 邊框半徑級別 (Border Radius Scale)
- **未偵測到**。BMW 僅使用銳利邊角 —— 每個元素都是精確的矩形。這是分析過的所有設計系統中稜角最分明的。

## 6. 深度與提升 (Depth & Elevation)

| 級別 | 處理方式 | 用途 |
|-------|-----------|-----|
| 攝影 (Level 0) | 全版深色意象 | Hero 背景 |
| 平面 (Level 1) | 白色表面, 無陰影 | 內容區段 |
| 聚焦 (無障礙) | BMW Focus Blue (`#0653b6`) | 聚焦狀態 |

**陰影哲學**：BMW 幾乎不使用陰影。深度完全是透過深色攝影區段與白色內容區段之間的對比創造的 —— 汽車燈光完成了提升感的工作。

## 7. 該做與不該做的事 (Do's and Don'ts)

### 該做 (Do)
- 所有顯示標題皆使用 BMWTypeNextLatin Light (300) 全大寫
- 保持「所有」角均為銳利 (0px 半徑) —— 稜角幾何是不容談判的
- 僅在互動元素使用 BMW Blue (`#1c69d4`) —— 絕不作裝飾用途
- 導覽強調應用字重 900 —— 極端的字重對比是有意為之的
- Hero 區段使用全版汽車攝影
- 整個系統保持緊湊的行高 (1.15–1.30)
- 使用 `--site-context-*` CSS 變數進行主題化

### 不該做 (Don't)
- 不要使用圓角 —— 零半徑是 BMW 的識別
- 不要將 BMW Blue 用於背景或大型表面 —— 它僅作為點綴
- 不要使用中等字重 (500–600) —— 系統使用 300, 400, 700, 900 極端字重
- 不要添加裝飾性元素 —— 由攝影和排版承擔一切
- 不要使用寬鬆的行高 —— BMW 的文字總是壓縮的
- 不要調亮深色 Hero 區段 —— 與白色的對比「就是」設計所在

## 8. 響應式行為

### 斷點 (Breakpoints)
| 名稱 | 寬度 | 關鍵變化 |
|------|-------|-------------|
| 小型行動裝置 (Mobile Small) | <375px | 最低支援寬度 |
| 行動裝置 (Mobile) | 375–480px | 單欄 |
| 大型行動裝置 (Mobile Large) | 480–640px | 細微調整 |
| 小型平板 (Tablet Small) | 640–768px | 開始 2 欄佈局 |
| 平板 (Tablet) | 768–920px | 標準平板 |
| 小型桌機 (Desktop Small) | 920–1024px | 開始桌機佈局 |
| 桌機 (Desktop) | 1024–1280px | 標準桌機 |
| 大型桌機 (Large Desktop) | 1280–1440px | 擴展佈局 |
| 超寬螢幕 (Ultra-wide) | 1440–1600px | 最大佈局 |

### 收合策略 (Collapsing Strategy)
- Hero 標題：60px → 縮小，保持全大寫
- 導覽列：水平 → 漢堡選單
- 攝影：在各種尺寸下保持全版寬度
- 內容區段：垂直堆疊
- 頁尾：多欄 → 堆疊

## 9. 代理（Agent）提示指南

### 快速顏色參考
- 背景：純白色 (`#ffffff`)
- 文字：近乎黑色 (`#262626`)
- 次要文字：Meta Gray (`#757575`)
- 點綴：BMW Blue (`#1c69d4`)
- 聚焦：BMW Focus Blue (`#0653b6`)
- 弱化：Silver (`#bbbbbb`)

### 元件提示範例
- 「建立一個 hero：全寬深色汽車攝影背景。標題為 60px BMWTypeNextLatin Light weight 300, 全大寫, 行高 1.30, 白色文字。各處均無邊框半徑。」
- 「設計導覽列：深色背景。導覽連結使用 BMWTypeNextLatin 18px weight 900, 白色文字。BMW 標誌 54x54。銳利矩形佈局。」
- 「建立一個按鈕：16px BMWTypeNextLatin weight 700, 行高 1.20。銳利邊角 (0px 半徑)。深色表面上有白色底邊框。」
- 「建立內容區段：白色背景。標題為 32px weight 400, 行高 1.30, #262626。內文為 16px weight 400, 行高 1.15。」

### 迭代指南
1. 零邊框半徑 —— 每個角都是銳利的，沒有例外
2. 字重極端：300 (顯示標題), 400 (內文), 700 (按鈕), 900 (導覽列)
3. BMW Blue 僅用於互動 —— 絕不作為背景或裝飾
4. 攝影承載情感 —— UI 是純粹的精準
5. 各處均採用緊湊行高 —— 範圍在 1.15 到 1.30
