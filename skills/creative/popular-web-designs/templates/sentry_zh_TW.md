# 設計系統：Sentry


> **Hermes Agent — 實作筆記**
>
> 原始網站使用專有字體。對於自包含的 HTML 輸出，請使用以下 CDN 替代方案：
> - **主要字體：** `Rubik` | **等寬字體：** `JetBrains Mono`
> - **字體組合 (CSS)：** `font-family: 'Rubik', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;`
> - **等寬字體組合 (CSS)：** `font-family: 'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace;`
> ```html
> <link href="https://fonts.googleapis.com/css2?family=Rubik:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
> ```
> 使用 `write_file` 建立 HTML，透過 `generative-widgets` 技能（cloudflared 隧道）提供服務。
> 生成後使用 `browser_vision` 驗證視覺準確性。

## 1. 視覺主題與氛圍

Sentry 的網站是一個以「深色模式優先」的開發者工具介面，使用程式碼編輯器和終端機視窗的語言。整個美學根植於深紫色背景 (`#1f1633`, `#150f23`)，喚起 Sentry 為之而生的深夜除錯（debugging）場景。在這種如墨水般的畫布上，一組精心挑選的紫色、粉色和獨特的萊姆綠強調色 (`#c2ef4e`) 創造出一個既具技術感又充滿活力的視覺系統。

字體配對是刻意為之的："Dammit Sans" 以主視覺規模（88px，字重 700）作為展示字體出現，具備與 Sentry 幽默大膽的品牌語氣（「Code breaks. Fix it faster.」）相稱的個性與態度。而 Rubik 則作為通用的 UI 字體，處理所有功能性文字 —— 標題、正文、按鈕、圖說和導覽。Monaco 則提供了程式碼片段和技術內容的等寬字體層，完成了開發者工具的三位一體。

Sentry 的獨特之處在於其對「深色 IDE」美學的擁抱，卻不顯得冷漠或單調。暖紫色調取代了開發者工具中常見的冷灰色，大膽的插圖元素（3D 角色、彩色的產品截圖）點綴在深色畫布上。按鈕系統使用標誌性的柔和紫色 (`#79628c`) 搭配內陰影，營造出一種觸感，幾乎具有物理品質 —— 按鈕感覺像是可以被按入表面。

**關鍵特徵：**
- 深紫黑色背景 (`#1f1633`, `#150f23`) —— 絕不使用純黑色
- 暖紫色強調光譜：從深色 (`#362d59`)、中間色 (`#79628c`, `#6a5fc1`) 到活力色 (`#422082`)
- 萊姆綠 (`#c2ef4e`) 用於高能見度的 CTA 和亮點
- 粉色/珊瑚色強調色 (`#ffb287`, `#fa7faa`) 用于聚焦狀態和次要亮點
- "Dammit Sans" 展示字體在主視覺規模下展現品牌個性
- Rubik 作為主要 UI 字體，搭配大寫且具備字距的標籤
- Monaco 等寬字體用於程式碼元素
- 按鈕上的內陰影營造出觸覺深度
- 使用 `blur(18px) saturate(180%)` 實現毛玻璃效果

## 2. 色彩調色盤與角色

### 主要品牌色
- **深紫色 (Deep Purple)** (`#1f1633`): 主要背景色，品牌的定義性色彩
- **暗紫色 (Darker Purple)** (`#150f23`): 更深的區塊、頁尾、次要背景
- **框線紫 (Border Purple)** (`#362d59`): 框線、分隔線、微妙的結構線

### 強調色彩
- **Sentry Purple** (`#6a5fc1`): 主要互動色 —— 連結、懸停狀態、聚焦環
- **柔和紫 (Muted Purple)** (`#79628c`): 按鈕背景、次要互動元素
- **深紫羅蘭 (Deep Violet)** (`#422082`): 下拉選單、活動狀態、高強調表面
- **萊姆綠 (Lime Green)** (`#c2ef4e`): 高能見度強調色、特殊連結、徽章亮點
- **珊瑚色 (Coral)** (`#ffb287`): 聚焦狀態背景、暖性強調色
- **粉紅色 (Pink)** (`#fa7faa`): 聚焦輪廓、裝飾性強調色

### 文字色彩
- **純白色** (`#ffffff`): 深色背景上的主要文字
- **淺灰色** (`#e5e7eb`): 次要文字、柔和內容
- **程式碼黃** (`#dcdcaa`): 語法高亮 (Syntax Highlighting)、程式碼 Token

### 表面與疊加層
- **玻璃白 (Glass White)** (`rgba(255, 255, 255, 0.18)`): 毛玻璃按鈕背景
- **玻璃深色 (Glass Dark)** (`rgba(54, 22, 107, 0.14)`): 玻璃元素上的懸停疊加層
- **輸入框白 (Input White)** (`#ffffff`): 表單輸入框背景（淺色語境）
- **輸入框框線** (`#cfcfdb`): 表單欄位框線

### 陰影
- **周圍光暈 (Ambient Glow)** (`rgba(22, 15, 36, 0.9) 0px 4px 4px 9px`): 深紫色環境陰影
- **按鈕懸停** (`rgba(0, 0, 0, 0.18) 0px 0.5rem 1.5rem`): 提升的懸停狀態
- **卡片陰影** (`rgba(0, 0, 0, 0.1) 0px 10px 15px -3px`): 標準卡片層次
- **按鈕內陰影** (`rgba(0, 0, 0, 0.1) 0px 1px 3px 0px inset`): 觸控按壓效果

## 3. 字體排版規則

### 字體族系
- **展示字體 (Display)**: `Dammit Sans` —— 用於主視覺標題的品牌個性字體
- **主要 UI 字體**: `Rubik`，備用字體：`-apple-system, system-ui, Segoe UI, Helvetica, Arial`
- **等寬字體**: `Monaco`，備用字體：`Menlo, Ubuntu Mono`

### 層級結構

| 角色 | 字體 | 大小 | 字重 | 行高 | 字距 (Letter Spacing) | 備註 |
|------|------|------|--------|-------------|----------------|-------|
| 主視覺展示 (Display Hero) | Dammit Sans | 88px (5.50rem) | 700 | 1.20 (緊湊) | 正常 | 最大衝擊力，品牌語調 |
| 次要展示 | Dammit Sans | 60px (3.75rem) | 500 | 1.10 (緊湊) | 正常 | 次要主視覺文字 |
| 區塊標題 | Rubik | 30px (1.88rem) | 400 | 1.20 (緊湊) | 正常 | 主要區塊標題 |
| 副標題 | Rubik | 27px (1.69rem) | 500 | 1.25 (緊湊) | 正常 | 特色功能區塊標題 |
| 卡片標題 | Rubik | 24px (1.50rem) | 500 | 1.25 (緊湊) | 正常 | 卡片與區塊標題 |
| 特色標題 | Rubik | 20px (1.25rem) | 600 | 1.25 (緊湊) | 正常 | 強調的特色名稱 |
| 正文 | Rubik | 16px (1.00rem) | 400 | 1.50 | 正常 | 標準正文文字 |
| 強調正文 | Rubik | 16px (1.00rem) | 500–600 | 1.50 | 正常 | 粗體正文、導覽項目 |
| 導覽標籤 | Rubik | 15px (0.94rem) | 500 | 1.40 | 正常 | 導覽連結 |
| 大寫標籤 | Rubik | 15px (0.94rem) | 500 | 1.25 (緊湊) | 正常 | `text-transform: uppercase` |
| 按鈕文字 | Rubik | 14px (0.88rem) | 500–700 | 1.14–1.29 (緊湊) | 0.2px | `text-transform: uppercase` |
| 圖說 | Rubik | 14px (0.88rem) | 500–700 | 1.00–1.43 | 0.2px | 通常為大寫 |
| 小型圖說 | Rubik | 12px (0.75rem) | 600 | 2.00 (寬鬆) | 正常 | 微妙的註解 |
| 微型標籤 | Rubik | 10px (0.63rem) | 600 | 1.80 (寬鬆) | 0.25px | `text-transform: uppercase` |
| 程式碼 | Monaco | 16px (1.00rem) | 400–700 | 1.50 | 正常 | 程式碼區塊、技術文字 |

### 原則
- **雙重性格**：Dammit Sans 在展示規模下帶來不羈的品牌個性；Rubik 則為所有功能性內容提供簡潔的專業感。
- **大寫作為系統**：按鈕、圖說、標籤和微型文字皆使用 `text-transform: uppercase` 並帶有細微字距 (0.2px–0.25px)，在整個系統中創造出一致的「技術標籤」模式。
- **字重分層**：Rubik 使用 400 (正文)、500 (強調/導覽)、600 (標題/粗體)、700 (按鈕/CTA) —— 一套簡潔的四級字重系統。
- **緊湊標題，寬鬆正文**：所有標題使用 1.10–1.25 行高；正文使用 1.50；小型圖說則擴展至 2.00 以確保在微小尺寸下的可讀性。

## 4. 元件樣式

### 按鈕

**主要柔和紫按鈕**
- 背景：`#79628c` (rgb(121, 98, 140))
- 文字：`#ffffff`，大寫，14px，字重 500–700，字距 0.2px
- 框線：`1px solid #584674`
- 圓角：13px
- 陰影：`rgba(0, 0, 0, 0.1) 0px 1px 3px 0px inset` (觸覺內陰影)
- 懸停 (Hover)：提升的陰影 `rgba(0, 0, 0, 0.18) 0px 0.5rem 1.5rem`

**玻璃白按鈕**
- 背景：`rgba(255, 255, 255, 0.18)` (毛玻璃)
- 文字：`#ffffff`
- 內距：8px
- 圓角：12px (左對齊變體：`12px 0px 0px 12px`)
- 陰影：`rgba(0, 0, 0, 0.08) 0px 2px 8px`
- 懸停背景：`rgba(54, 22, 107, 0.14)`
- 用途：深色表面上的次要操作

**純白實心按鈕**
- 背景：`#ffffff`
- 文字：`#1f1633`
- 內距：12px 16px
- 圓角：8px
- 懸停 (Hover)：背景轉為 `#6a5fc1`，文字轉為白色
- 聚焦 (Focus)：背景 `#ffb287` (珊瑚色)，輪廓 `rgb(106, 95, 193) solid 0.125rem`
- 用途：深色背景上的高能見度 CTA

**深紫羅蘭 (選擇/下拉選單)**
- 背景：`#422082`
- 文字：`#ffffff`
- 內距：8px 16px
- 圓角：8px

### 輸入框

**文字輸入框**
- 背景：`#ffffff`
- 文字：`#1f1633`
- 框線：`1px solid #cfcfdb`
- 內距：8px 12px
- 圓角：6px
- 聚焦 (Focus)：框線顏色保持 `#cfcfdb`，陰影 `rgba(0, 0, 0, 0.15) 0px 2px 10px inset`

### 連結
- **深色背景上的預設**：`#ffffff`，底線裝飾
- **懸停 (Hover)**：顏色轉向 `#6a5fc1` (Sentry Purple)
- **紫色連結**：預設 `#6a5fc1`，懸停顯示底線
- **萊姆綠強調連結**：預設 `#c2ef4e`，懸停轉為 `#6a5fc1`
- **深色情境連結**：`#362d59`，懸停轉為 `#ffffff`

### 卡片與容器
- 背景：半透明或深紫色表面
- 圓角：8px–12px
- 陰影：`rgba(0, 0, 0, 0.1) 0px 10px 15px -3px`
- 背景濾鏡 (Backdrop filter)：`blur(18px) saturate(180%)` 用於玻璃效果

### 導覽
- 主視覺內容上方的深色透明頁首
- 導覽連結使用 Rubik 15px 字重 500
- 白色文字，懸停轉為 Sentry Purple (`#6a5fc1`)
- 類別使用大寫標籤並帶有 0.2px 字距
- 行動端：漢堡選單，全寬展開

## 5. 版面原則

### 間距系統
- 基礎單位：8px
- 級距：1px, 2px, 4px, 5px, 6px, 8px, 12px, 16px, 24px, 32px, 40px, 44px, 45px, 47px

### 網格與容器
- 最大內容寬度：1152px (XL 斷點)
- 回應式內距：2rem (行動端) → 4rem (平板及以上)
- 內容在容器內置中
- 全寬深色區塊，內部內容受容器限制

### 斷點 (Breakpoints)
| 名稱 | 寬度 | 關鍵變化 |
|------|-------|-------------|
| 行動裝置 | < 576px | 單欄佈局，堆疊版面 |
| 小型平板 | 576–640px | 微小的寬度調整 |
| 平板端 | 640–768px | 開始出現雙欄 |
| 小型桌機 | 768–992px | 顯示完整導覽 |
| 桌上型電腦 | 992–1152px | 標準佈局 |
| 大型桌機 | 1152–1440px | 最大寬度內容 |

### 留白哲學
- **深色喘息空間**：區塊之間慷慨的垂直間距 (64px–80px+) 讓深色背景發揮視覺休息的作用。
- **內容島嶼**：特色功能區塊是在深紫色海洋中漂浮的自包含方塊，每個方塊都有自己的內部間距節奏。
- **非對稱內距**：按鈕使用非對稱內距模式 (12px 16px, 8px 12px)，感覺自然而非僵化。

### 圓角半徑級距
- 極小 (6px)：表單輸入框、小型互動元素
- 標準 (8px)：按鈕、卡片、容器
- 舒適 (10px–12px)：較大型容器、玻璃面板
- 圓潤 (13px)：主要柔和型按鈕
- 藥丸型 (18px)：影像容器、徽章

## 6. 深度與層次

| 層級 | 處理方式 | 用途 |
|-------|-----------|-----|
| 凹陷 (Level -1) | 內陰影 `rgba(0, 0, 0, 0.1) 0px 1px 3px inset` | 主要按鈕 (觸控按壓感) |
| 扁平 (Level 0) | 無陰影 | 預設表面、深色背景 |
| 表面 (Level 1) | `rgba(0, 0, 0, 0.08) 0px 2px 8px` | 玻璃按鈕、細微卡片 |
| 提升 (Level 2) | `rgba(0, 0, 0, 0.1) 0px 10px 15px -3px` | 卡片、漂浮面板 |
| 突出 (Level 3) | `rgba(0, 0, 0, 0.18) 0px 0.5rem 1.5rem` | 懸停狀態、彈窗 |
| 環境 (Level 4) | `rgba(22, 15, 36, 0.9) 0px 4px 4px 9px` | 主視覺周圍的深紫色環境光暈 |

**陰影哲學**：Sentry 使用獨特的內陰影組合（按鈕感覺被按「入」表面）和周圍光暈（內容從深色背景輻射而出）。深紫色環境陰影 (`rgba(22, 15, 36, 0.9)`) 是其標誌 —— 它創造出一種「生物發光」的品質，內容似乎發出自己帶有紫色的光芒。

## 7. 規範與禁止 (Do's and Don'ts)

### 規範
- 使用深紫色背景 (`#1f1633`, `#150f23`) —— 絕不使用純黑色 (`#000000`)
- 在主要按鈕上套用內陰影以實現觸控按壓效果
- 僅在主視覺/展示標題使用 Dammit Sans —— 其他所有內容使用 Rubik
- 在按鈕和標籤上套用 `text-transform: uppercase` 並搭配 `letter-spacing: 0.2px`
- 謹慎使用萊姆綠強調色 (`#c2ef4e`) 以獲得最大衝擊力
- 對分層表面採用毛玻璃效果 (`blur(18px) saturate(180%)`)
- 保持暖紫色陰影色調 —— 陰影應感覺帶有紫色，而非中性灰色
- 使用 Rubik 的四級字重系統：400 (正文)、500 (導覽/強調)、600 (標題)、700 (CTA)

### 禁止
- 背景不要使用純黑色 (`#000000`) —— 始終使用暖紫黑色
- 不要將 Dammit Sans 套用於正文或 UI 元素 —— 它僅限展示用途
- 框線不要使用標準灰色 (`#666`, `#999`) —— 使用帶有紫色調的灰色 (`#362d59`, `#584674`)
- 按鈕不要捨棄大寫處理 —— 這是全系統的模式
- 不要使用銳角 (0px 圓角) —— 所有互動元素至少為 6px
- 不要在同一個元件中混合使用萊姆綠強調色與珊瑚/粉色強調色
- 主要按鈕不要使用扁平（非內陰影）陰影 —— 觸感品質是其核心標誌
- 大寫文字不要忘記字距 —— 至少 0.2px

## 8. 回應式行為

### 斷點 (Breakpoints)
| 名稱 | 寬度 | 關鍵變化 |
|------|-------|-------------|
| 行動裝置 | <576px | 單欄佈局，漢堡導覽，堆疊 CTA |
| 平板端 | 576–768px | 開始出現雙欄特色功能網格 |
| 小型桌機 | 768–992px | 完整導覽，並排佈局 |
| 桌上型電腦 | 992–1152px | 最大寬度容器，完整佈局 |
| 大型螢幕 | >1152px | 保持內容最大寬度，充裕的邊距 |

### 收合策略
- 主視覺文字：88px Dammit Sans → 60px → 行動端縮放
- 導覽：水平 → 帶有側滑出的漢堡選單
- 特色區塊：並排 → 堆疊卡片
- 按鈕：行內 → 行動端全寬堆疊
- 容器內距：4rem → 2rem

## 9. Agent 提示詞指南

### 快速色彩參考
- 背景：`#1f1633` (主要), `#150f23` (更深)
- 文字：`#ffffff` (主要), `#e5e7eb` (次要)
- 互動色：`#6a5fc1` (連結/懸停), `#79628c` (按鈕)
- 強調色：`#c2ef4e` (萊姆亮點), `#ffb287` (珊瑚聚焦)
- 框線：`#362d59` (深色), `#cfcfdb` (淺色情境)

### 元件提示詞範例
- "Create a hero section on deep purple background (#1f1633). Headline at 88px Dammit Sans weight 700, line-height 1.20, white text. Sub-text at 16px Rubik weight 400, line-height 1.50. White solid CTA button (8px radius, 12px 16px padding), hover transitions to #6a5fc1."
- "Design a navigation bar: transparent over dark background. Rubik 15px weight 500, white text. Uppercase category labels with 0.2px letter-spacing. Hover color #6a5fc1."
- "Build a primary button: background #79628c, border 1px solid #584674, inset shadow rgba(0,0,0,0.1) 0px 1px 3px, white uppercase text at 14px Rubik weight 700, letter-spacing 0.2px, radius 13px. Hover: shadow rgba(0,0,0,0.18) 0px 0.5rem 1.5rem."
- "Create a glass card panel: background rgba(255,255,255,0.18), backdrop-filter blur(18px) saturate(180%), radius 12px. White text content inside."
- "Design a feature section: #150f23 background, 24px Rubik weight 500 heading, 16px Rubik weight 400 body text. 14px uppercase lime-green (#c2ef4e) label above heading."

### 迭代指南
1. 始終從深紫色背景開始 —— 色彩調色盤是為深色模式而建的
2. 按鈕使用內陰影，主視覺區塊使用環境紫色光暈
3. 大寫 + 字距是標籤、按鈕和圖說的系統化模式
4. 萊姆綠 (#c2ef4e) 是「亮點」顏色 —— 每個區塊最多使用一次
5. 重疊面板使用毛玻璃，主要表面使用實心紫色
6. Rubik 處理 90% 的排版 —— Dammit Sans 僅用於主視覺
