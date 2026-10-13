# 設計系統：Airbnb

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

Airbnb 的網站是一個溫暖、以攝影為主的市集，感覺就像翻閱一本旅遊雜誌，每一頁都在邀請你預訂。設計建立在純白色 (`#ffffff`) 的基礎上，並以標誌性的 Rausch Red (`#ff385c`) —— 以 Airbnb 的第一個街道地址命名 —— 作為唯一的品牌點綴色。結果是一個乾淨、通風的畫布，其中房源攝影、類別圖示和紅色的 CTA 按鈕是唯一的色彩來源。

排版使用 Airbnb Cereal VF —— 這是一種自定義的可變字體，溫暖且平易近人，帶有圓潤的末端，呼應了品牌「四海一家 (belong anywhere)」的理念。該字體在緊湊的字重範圍內運作：500 (medium) 用於大多數 UI，600 (semibold) 用於強調，700 (bold) 用於主要標題。標題上輕微的負字距 (-0.18px 到 -0.44px) 營造出一種舒適、親密的閱讀體驗，而不是科技公司那種壓縮的效率感。

Airbnb 的獨特之處在於其基於調色盤的標記系統 (`--palette-*`) 和多層陰影處理。主要的卡片陰影使用三層堆疊 (`rgba(0,0,0,0.02) 0px 0px 0px 1px, rgba(0,0,0,0.04) 0px 2px 6px, rgba(0,0,0,0.1) 0px 4px 8px`)，營造出細微、溫暖的提升感。結合大方的邊框半徑 (8px–32px)、圓形導覽控制項 (50%) 和帶有水平滾動的類別藥丸列，介面感覺具有觸感且誘人 —— 旨在瀏覽而非命令。

**關鍵特徵：**
- 純白畫布，以 Rausch Red (`#ff385c`) 作為唯一的品牌點綴
- Airbnb Cereal VF —— 帶有溫暖圓潤末端的自定義可變字體
- 基於調色盤的標記系統 (`--palette-*`) 用於系統化顏色管理
- 三層卡片陰影：邊框環 + 柔和模糊 + 強力模糊
- 大方的邊框半徑：8px 按鈕、14px 徽章、20px 卡片、32px 大型元素
- 圓形導覽控制項 (50% 半徑)
- 攝影優先的房源卡片 —— 圖片是英雄內容
- 近乎黑色的文字 (`#222222`) —— 溫暖而非冷冰冰
- Luxe Purple (`#460479`) 和 Plus Magenta (`#92174d`) 用於高級層級

## 2. 調色盤與角色

### 主要品牌 (Primary Brand)
- **Rausch Red** (`#ff385c`): `--palette-bg-primary-core`, 主要 CTA, 品牌點綴, 啟用狀態 (active states)
- **Deep Rausch** (`#e00b41`): `--palette-bg-tertiary-core`, 品牌紅的按下/深色變體
- **Error Red** (`#c13515`): `--palette-text-primary-error`, 淺色背景上的錯誤文字
- **Error Dark** (`#b32505`): `--palette-text-secondary-error-hover`, 錯誤懸停 (error hover)

### 高級層級 (Premium Tiers)
- **Luxe Purple** (`#460479`): `--palette-bg-primary-luxe`, Airbnb Luxe 層級品牌
- **Plus Magenta** (`#92174d`): `--palette-bg-primary-plus`, Airbnb Plus 層級品牌

### 文字層級 (Text Scale)
- **Near Black** (`#222222`): `--palette-text-primary`, 主要文字 —— 溫暖而非冷冰冰
- **Focused Gray** (`#3f3f3f`): `--palette-text-focused`, 聚焦狀態文字
- **Secondary Gray** (`#6a6a6a`): 次要文字, 描述
- **Disabled** (`rgba(0,0,0,0.24)`): `--palette-text-material-disabled`, 停用狀態
- **Link Disabled** (`#929292`): `--palette-text-link-disabled`, 停用連結

### 互動要素 (Interactive)
- **Legal Blue** (`#428bff`): `--palette-text-legal`, 法律連結, 資訊性內容
- **Border Gray** (`#c1c1c1`): 卡片和分隔線的邊框顏色
- **Light Surface** (`#f2f2f2`): 圓形導覽按鈕, 次要表面

### 表面與陰影 (Surface & Shadows)
- **Pure White** (`#ffffff`): 頁面背景, 卡片表面
- **Card Shadow** (`rgba(0,0,0,0.02) 0px 0px 0px 1px, rgba(0,0,0,0.04) 0px 2px 6px, rgba(0,0,0,0.1) 0px 4px 8px`): 三層溫暖提升
- **Hover Shadow** (`rgba(0,0,0,0.08) 0px 4px 12px`): 按鈕懸停提升

## 3. 字體排版規則

### 字體系列 (Font Family)
- **主要 (Primary)**: `Airbnb Cereal VF`, 備用字體: `Circular, -apple-system, system-ui, Roboto, Helvetica Neue`
- **OpenType 特性**: 在特定的標題 (caption) 元素上使用 `"salt"` (風格變體 stylistic alternates)

### 層級 (Hierarchy)

| 角色 (Role) | 字體 | 大小 | 字重 | 行高 | 字距 | 備註 |
|------|------|------|--------|-------------|----------------|-------|
| 區段標題 (Section Heading) | Airbnb Cereal VF | 28px (1.75rem) | 700 | 1.43 | normal | 主要標題 |
| 卡片標題 (Card Heading) | Airbnb Cereal VF | 22px (1.38rem) | 600 | 1.18 (tight) | -0.44px | 類別/卡片標題 |
| 卡片標題 Medium | Airbnb Cereal VF | 22px (1.38rem) | 500 | 1.18 (tight) | -0.44px | 較輕的變體 |
| 子標題 (Sub-heading) | Airbnb Cereal VF | 21px (1.31rem) | 700 | 1.43 | normal | 粗體子標題 |
| 特色標題 (Feature Title) | Airbnb Cereal VF | 20px (1.25rem) | 600 | 1.20 (tight) | -0.18px | 特色標題 |
| UI Medium | Airbnb Cereal VF | 16px (1.00rem) | 500 | 1.25 (tight) | normal | 導覽, 強調文字 |
| UI Semibold | Airbnb Cereal VF | 16px (1.00rem) | 600 | 1.25 (tight) | normal | 強力強調 |
| 按鈕 (Button) | Airbnb Cereal VF | 16px (1.00rem) | 500 | 1.25 (tight) | normal | 按鈕標籤 |
| 內文 / 連結 (Body / Link) | Airbnb Cereal VF | 14px (0.88rem) | 400 | 1.43 | normal | 標準內文 |
| 內文 Medium | Airbnb Cereal VF | 14px (0.88rem) | 500 | 1.29 (tight) | normal | 中等內文 |
| Caption Salt | Airbnb Cereal VF | 14px (0.88rem) | 600 | 1.43 | normal | `"salt"` 特性 |
| 小字 (Small) | Airbnb Cereal VF | 13px (0.81rem) | 400 | 1.23 (tight) | normal | 描述 |
| 標籤 (Tag) | Airbnb Cereal VF | 12px (0.75rem) | 400–700 | 1.33 | normal | 標籤, 價格 |
| 徽章 (Badge) | Airbnb Cereal VF | 11px (0.69rem) | 600 | 1.18 (tight) | normal | `"salt"` 特性 |
| 微型大寫 (Micro Uppercase) | Airbnb Cereal VF | 8px (0.50rem) | 700 | 1.25 (tight) | 0.32px | `text-transform: uppercase` |

### 原則
- **溫暖的字重範圍**：500–700 佔據主導地位。標題不使用 300 或 400 字重 —— Airbnb 的字體總是至少為 medium 字重，營造出一種溫暖、自信的語調。
- **標題的負字距**：顯示標題上使用 -0.18px 到 -0.44px 的字距，營造出親密、舒適的標題，而非冷冰冰、被壓縮的標題。
- **"salt" OpenType 特性**：在特定 UI 元素（徽章、標題）上的風格變體創造了細微的字元變化，增加了視覺趣味。
- **可變字體精準度**：Cereal VF 實現了連續的字重插值，儘管設計系統使用 500、600 和 700 等離散點。

## 4. 元件樣式

### 按鈕 (Buttons)

**主要深色 (Primary Dark)**
- 背景：`#222222` (近乎黑色，而非純黑)
- 文字：`#ffffff`
- 內邊距 (Padding)：0px 24px
- 半徑 (Radius)：8px
- 懸停 (Hover)：透過 `var(--accent-bg-error)` 過渡到錯誤色/品牌點綴色
- 聚焦 (Focus)：`0 0 0 2px var(--palette-grey1000)` 環 + scale(0.92)

**圓形導覽 (Circular Nav)**
- 背景：`#f2f2f2`
- 文字：`#222222`
- 半徑：50% (圓形)
- 懸停：陰影 `rgba(0,0,0,0.08) 0px 4px 12px` + translateX(50%)
- 啟用 (Active)：4px 白色邊框環 + 聚焦陰影
- 聚焦：scale(0.92) 縮小動畫

### 卡片與容器 (Cards & Containers)
- 背景：`#ffffff`
- 半徑：14px (徽章), 20px (卡片/按鈕), 32px (大型)
- 陰影：`rgba(0,0,0,0.02) 0px 0px 0px 1px, rgba(0,0,0,0.04) 0px 2px 6px, rgba(0,0,0,0.1) 0px 4px 8px` (三層)
- 房源卡片：頂部為滿版攝影，下方為詳情
- 輪播控制項：圓形 50% 按鈕

### 輸入框 (Inputs)
- 搜尋：`#222222` 文字
- 聚焦：`var(--palette-bg-primary-error)` 背景淡色 + `0 0 0 2px` 環
- 半徑：視上下文而定（搜尋列使用藥丸狀圓角）

### 導覽 (Navigation)
- 白色置頂標題，搜尋列居中
- Airbnb 標誌 (Rausch Red) 向左對齊
- 類別篩選藥丸：搜尋列下方的水平滾動列
- 用於輪播導覽的圓形導覽控制項
- 「成為房東」文字連結，頭像/選單向右對齊

### 圖片處理 (Image Treatment)
- 房源攝影佔據卡片頂部，具有充足的高度
- 帶有點狀指示器的圖片輪播
- 圖片上方的愛心/願望清單圖示疊加
- 包含在內的圖片具有 8px–14px 半徑

## 5. 佈局原則

### 間距系統 (Spacing System)
- 基礎單位：8px
- 級別：2px, 3px, 4px, 6px, 8px, 10px, 11px, 12px, 15px, 16px, 22px, 24px, 32px

### 網格與容器 (Grid & Container)
- 帶有置中搜尋列的滿版標題
- 類別藥丸列：水平滾動列
- 房源網格：響應式多欄（桌機上為 3–5 欄）
- 帶有連結欄位的滿版頁尾

### 留白哲學 (Whitespace Philosophy)
- **旅遊雜誌間距**：區段之間充足的垂直內邊距營造出一種悠閒的瀏覽節奏 —— 你應該慢慢捲動，就像翻閱雜誌一樣。
- **攝影密度**：房源卡片排列相對緊湊，但每張圖片都大到足以讓人沉浸其中。
- **搜尋列顯著性**：搜尋列在標題中獲得最大的垂直空間 —— 尋找目的地是首要行動。

### 邊框半徑級別 (Border Radius Scale)
- 細微 (4px): 小型連結
- 標準 (8px): 按鈕, 頁籤, 搜尋元素
- 徽章 (14px): 狀態徽章, 標籤
- 卡片 (20px): 特色卡片, 大型按鈕
- 大型 (32px): 大型容器, hero 元素
- 圓形 (50%): 導覽控制項, 頭像, 圖示

## 6. 深度與提升 (Depth & Elevation)

| 級別 | 處理方式 | 用途 |
|-------|-----------|-----|
| 平面 (Level 0) | 無陰影 | 頁面背景, 文字塊 |
| 卡片 (Level 1) | `rgba(0,0,0,0.02) 0px 0px 0px 1px, rgba(0,0,0,0.04) 0px 2px 6px, rgba(0,0,0,0.1) 0px 4px 8px` | 房源卡片, 搜尋列 |
| 懸停 (Level 2) | `rgba(0,0,0,0.08) 0px 4px 12px` | 按鈕懸停, 互動提升 |
| 啟用聚焦 (Level 3) | `rgb(255,255,255) 0px 0px 0px 4px` + 聚焦環 | 啟用/聚焦元素 |

**陰影哲學**：Airbnb 的三層陰影系統營造出一種溫暖、自然的提升感。第 1 層 (`0px 0px 0px 1px`，透明度 0.02) 是極細微的邊框。第 2 層 (`0px 2px 6px`，0.04) 提供柔和的環境陰影。第 3 層 (`0px 4px 8px`，0.1) 增加了主要的提升感。這種漸進的方法創造出的陰影感覺像自然光，而非 CSS 效果。

## 7. 該做與不該做的事 (Do's and Don'ts)

### 該做 (Do)
- 文字使用 `#222222` (溫暖的近乎黑色) —— 絕不使用純黑色 `#000000`
- 僅在主要 CTA 和品牌時刻應用 Rausch Red (`#ff385c`) —— 它是唯一的點綴
- 在 500–700 字重下使用 Airbnb Cereal VF —— 溫暖的字重範圍是有意為之的
- 為所有提升的表面應用三層卡片陰影
- 使用大方的邊框半徑：按鈕 8px、卡片 20px、控制項 50%
- 將攝影作為主要的視覺內容 —— 房源以圖片為先
- 在標題上應用負字距 (-0.18px 到 -0.44px) 以增加親密感
- 為輪播/導覽控制項使用圓形 (50%) 按鈕

### 不該做 (Don't)
- 文字不要使用純黑色 (`#000000`) —— 始終使用 `#222222` (溫暖)
- 背景或大型表面不要應用 Rausch Red —— 它僅作為點綴
- 標題不要使用細字重 (300, 400) —— 最少 500
- 不要使用沉重的陰影 (主要層級透明度 > 0.1) —— 保持其溫暖且漸進
- 卡片不要使用銳利的邊角 (0–4px) —— 大方的圓角 (20px+) 是核心
- 除了 Rausch/Luxe/Plus 系統外，不要引入額外的品牌顏色
- 不要覆蓋調色盤標記系統 —— 一致地使用 `--palette-*` 變數

## 8. 響應式行為

### 斷點 (Breakpoints)
| 名稱 | 寬度 | 關鍵變化 |
|------|-------|-------------|
| 行動裝置 小型 (Mobile Small) | <375px | 單欄, 緊湊搜尋 |
| 行動裝置 (Mobile) | 375–550px | 標準行動房源網格 |
| 平板 小型 (Tablet Small) | 550–744px | 2 欄房源 |
| 平板 (Tablet) | 744–950px | 搜尋列展開 |
| 桌機 小型 (Desktop Small) | 950–1128px | 3 欄房源 |
| 桌機 (Desktop) | 1128–1440px | 4 欄網格, 完整標題 |
| 大型桌機 (Large Desktop) | 1440–1920px | 5 欄網格 |
| 超寬螢幕 (Ultra-wide) | >1920px | 最大網格寬度 |

*注意：Airbnb 具有 61 個偵測到的斷點 —— 這是觀察到最細緻的響應式系統之一，反映了他們對各種可能螢幕尺寸佈局的執著。*

### 觸控目標 (Touch Targets)
- 圓形導覽按鈕：適當的 50% 半徑尺寸
- 房源卡片：行動裝置上的全卡片點擊目標
- 搜尋列：專為拇指互動設計的顯著尺寸
- 類別藥丸：帶有充足內邊距的水平滾動列

### 收合策略 (Collapsing Strategy)
- 房源網格：5 → 4 → 3 → 2 → 1 欄
- 搜尋：展開的長條 → 緊湊長條 → 疊加層
- 類別藥丸：所有尺寸下均為水平滾動
- 導覽：完整標題 → 行動裝置簡化版
- 地圖：側邊面板 → 疊加層/切換開關

### 圖片行為 (Image Behavior)
- 房源照片：行動裝置上可滑動的輪播
- 保持寬高比的響應式圖片尺寸
- 愛心疊加層在各種尺寸下位置一致
- 圖片品質根據視窗調整

## 9. 代理（Agent）提示指南

### 快速顏色參考
- 背景：純白色 (`#ffffff`)
- 文字：近乎黑色 (`#222222`)
- 品牌點綴：Rausch Red (`#ff385c`)
- 次要文字：`#6a6a6a`
- 停用狀態：`rgba(0,0,0,0.24)`
- 卡片邊框：`rgba(0,0,0,0.02) 0px 0px 0px 1px`
- 卡片陰影：完整三層堆疊
- 按鈕表面：`#f2f2f2`

### 元件提示範例
- 「建立一個房源卡片：白色背景，20px 半徑。三層陰影：rgba(0,0,0,0.02) 0px 0px 0px 1px, rgba(0,0,0,0.04) 0px 2px 6px, rgba(0,0,0,0.1) 0px 4px 8px。頂部為照片區域（16:10 比例），下方為詳情：16px Airbnb Cereal VF weight 600 標題，14px weight 400 描述顏色為 #6a6a6a。」
- 「設計搜尋列：白色背景，全卡片陰影，容器 32px 半徑。搜尋文字為 14px Cereal VF weight 400。紅色搜尋按鈕 (#ff385c, 50% 半徑, 白色圖示)。」
- 「建立類別藥丸列：水平滾動列。每個藥丸：14px Cereal VF weight 600, #222222 文字，啟用時有底邊框。圓形的前進/後退箭頭 (#f2f2f2 背景, 50% 半徑)。」
- 「建立一個 CTA 按鈕：#222222 背景，白色文字，8px 半徑，16px Cereal VF weight 500，0px 24px 內邊距。懸停時變為品牌紅色點綴。」
- 「設計一個愛心/願望清單按鈕：透明背景，50% 半徑，帶有深色陰影輪廓的白色愛心圖示。」

### 迭代指南
1. 從白色開始 —— 攝影提供了所有的色彩
2. Rausch Red (#ff385c) 是唯一的點綴 —— 僅節制地用於 CTA
3. 文字使用近乎黑色 (#222222) —— 溫暖感很重要
4. 三層陰影創造自然、溫暖的提升感 —— 始終使用所有三層
5. 大方的半徑：按鈕 8px、卡片 20px、控制項 50%
6. Cereal VF 使用 500–700 字重 —— 任何標題都不使用細字重
7. 攝影是英雄 —— 每個房源卡片都是圖片優先
