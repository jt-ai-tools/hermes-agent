# 設計系統：HashiCorp


> **Hermes Agent — 實作筆記**
>
> 原始網站使用專有字體。對於獨立的 HTML 輸出，請使用以下 CDN 替代方案：
> - **主要字體：** `Inter` | **等寬字體：** `JetBrains Mono`
> - **字體組合 (CSS)：** `font-family: 'Inter', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;`
> - **等寬字體組合 (CSS)：** `font-family: 'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace;`
> ```html
> <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
> ```
> 使用 `write_file` 建立 HTML，並透過 `generative-widgets` 技能（cloudflared tunnel）提供服務。
> 生成後使用 `browser_vision` 驗證視覺準確性。

## 1. 視覺主題與氛圍

HashiCorp 的網站讓「企業級基礎架構」變得具象化——這是一個既要傳達雲端基礎架構管理的複雜性，又要保持親和感的設計系統。視覺語言分為兩種模式：資訊區塊使用簡潔的純白淺色模式，而英雄區塊 (Hero) 和產品展示則使用戲劇性的深色模式 (`#15181e`, `#0d0e12`)，營造出一種日/夜雙重性，呼應了開發者「在光亮中構建，在黑暗中部署」的工作流程。

字體排印的核心是客製化的品牌字體 (HashiCorp Sans)，它帶有十足的份量感。標題使用 600–700 的字重，並搭配緊湊的行高 (1.17–1.19)，創造出密集、具權威性的文字塊，傳達出企業級的自信。82px 字重 600 並開啟 OpenType `"kern"` 特性的英雄標題不只是裝飾——它是「基礎架構級」的字體排印。

HashiCorp 的獨特之處在於其多產品色彩系統。產品組合中的每個產品都有自己的品牌色彩——Terraform 紫色 (`#7b42bc`)、Vault 黃色 (`#ffcf25`)、Waypoint 青色 (`#14c6cb`)、Vagrant 藍色 (`#1868f2`)——這些顏色透過 CSS 自定義屬性系統 (`--mds-color-*`) 作為強調標記 (tokens) 出現在各處。這創造了一種「系統中的系統」：母品牌是黑白底色搭配藍色強調，而每個子產品則注入了自己的色彩識別。

組件系統使用 `mds` (Markdown Design System) 前綴，代表一種系統化的、標記驅動 (token-driven) 的方法，其中色彩、間距和狀態都透過 CSS 變數管理。陰影處理極其細微——使用 `rgba(97, 104, 117, 0.05)` 的雙層微陰影，幾乎不可見，但提供了足夠的深度來將互動表面與背景區分開來。

**關鍵特徵：**
- 雙重模式：簡潔的白色區塊 + 戲劇性的深色 (`#15181e`) 英雄/產品區域
- 客製化 HashiCorp Sans 字體，具備 600–700 字重和 `"kern"` 特性
- 透過 `--mds-color-*` CSS 自定義屬性實現的多產品色彩系統
- 產品品牌色彩：Terraform 紫、Vault 黃、Waypoint 青、Vagrant 藍
- 大寫且調整過字距的說明文字 (13px, 字重 600, 1.3px 字距)
- 微陰影：不透明度 0.05 的雙層陰影——以細語而非吶喊傳達深度
- 具備語義化變數名稱的標記驅動 `mds` 組件系統
- 緊湊的圓角半徑：2px–8px，沒有藥丸形或圓形元素
- 次要文字使用系統預設字體組合 (System-ui fallback stack)

## 2. 色彩配置與角色

### 品牌主要色彩
- **黑色** (`#000000`)：主要品牌色彩，淺色表面上的文字，`--mds-color-hcp-brand`
- **深炭灰** (`#15181e`)：深色模式背景、英雄區塊
- **近乎黑** (`#0d0e12`)：最深層的深色模式表面，深色背景上的表單輸入框

### 中性色階
- **淺灰** (`#f1f2f3`)：淺色背景、細微表面
- **中灰** (`#d5d7db`)：邊框、深色背景上的按鈕文字
- **冷灰** (`#b2b6bd`)：邊框裝飾（不透明度 0.1–0.4）
- **深灰** (`#656a76`)：輔助文字、次要標籤，`--mds-form-helper-text-color`
- **炭灰** (`#3b3d45`)：淺色背景上的次要文字、按鈕邊框
- **近乎白** (`#efeff1`)：深色表面上的主要文字

### 產品品牌色彩
- **Terraform 紫色** (`#7b42bc`)：`--mds-color-terraform-button-background`
- **Vault 黃色** (`#ffcf25`)：`--mds-color-vault-button-background`
- **Waypoint 青色** (`#14c6cb`)：`--mds-color-waypoint-button-background-focus`
- **Waypoint 青色 (懸停)** (`#12b6bb`)：`--mds-color-waypoint-button-background-hover`
- **Vagrant 藍色** (`#1868f2`)：`--mds-color-vagrant-brand`
- **紫色強調** (`#911ced`)：`--mds-color-palette-purple-300`
- **已訪問紫色** (`#a737ff`)：`--mds-color-foreground-action-visited`

### 語義化色彩
- **行動藍 (Action Blue)** (`#1060ff`)：深色背景上的主要行動連結
- **連結藍 (Link Blue)** (`#2264d6`)：淺色背景上的主要連結
- **亮藍** (`#2b89ff`)：活動連結、懸停強調
- **琥珀色** (`#bb5a00`)：`--mds-color-palette-amber-200`，警告狀態
- **淺琥珀色** (`#fbeabf`)：`--mds-color-palette-amber-100`，警告背景
- **Vault 淡黃色** (`#fff9cf`)：`--mds-color-vault-radar-gradient-faint-stop`
- **橘色** (`#a9722e`)：`--mds-color-unified-core-orange-6`
- **紅色** (`#731e25`)：`--mds-color-unified-core-red-7`，錯誤狀態
- **海軍藍** (`#101a59`)：`--mds-color-unified-core-blue-7`

### 陰影
- **微陰影** (`rgba(97, 104, 117, 0.05) 0px 1px 1px, rgba(97, 104, 117, 0.05) 0px 2px 2px`)：預設卡片/按鈕提升高度
- **焦點輪廓 (Focus Outline)**：`3px solid var(--mds-color-focus-action-external)` —— 系統化的焦點環

## 3. 字體排印規則

### 字體系列
- **品牌主字體**：`__hashicorpSans_96f0ca` (HashiCorp Sans)，後備字體：`__hashicorpSans_Fallback_96f0ca`
- **系統 UI**：`system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, Helvetica, Arial`

### 層級

| 角色 | 字體 | 大小 | 字重 | 行高 | 字距 | 備註 |
|------|------|------|--------|-------------|----------------|-------|
| 英雄展示 (Hero) | HashiCorp Sans | 82px (5.13rem) | 600 | 1.17 (緊湊) | normal | 開啟 `"kern"` |
| 區塊標題 | HashiCorp Sans | 52px (3.25rem) | 600 | 1.19 (緊湊) | normal | 開啟 `"kern"` |
| 特色標題 | HashiCorp Sans | 42px (2.63rem) | 700 | 1.19 (緊湊) | -0.42px | 負字距 |
| 副標題 | HashiCorp Sans | 34px (2.13rem) | 600–700 | 1.18 (緊湊) | normal | 特色區塊 |
| 卡片標題 | HashiCorp Sans | 26px (1.63rem) | 700 | 1.19 (緊湊) | normal | 卡片與面板標題 |
| 小型標題 | HashiCorp Sans | 19px (1.19rem) | 700 | 1.21 (緊湊) | normal | 緊湊標題 |
| 強調本文 | HashiCorp Sans | 17px (1.06rem) | 600–700 | 1.18–1.35 | normal | 粗體內文 |
| 大號本文 | system-ui | 20px (1.25rem) | 400–600 | 1.50 | normal | 英雄區塊描述 |
| 本文 | system-ui | 16px (1.00rem) | 400–500 | 1.63–1.69 (寬鬆) | normal | 標準內文 |
| 導覽連結 | system-ui | 15px (0.94rem) | 500 | 1.60 (寬鬆) | normal | 導覽項目 |
| 小號本文 | system-ui | 14px (0.88rem) | 400–500 | 1.29–1.71 | normal | 次要內容 |
| 圖說 (Caption) | system-ui | 13px (0.81rem) | 400–500 | 1.23–1.69 | normal | 元數據、頁尾連結 |
| 大寫標籤 | HashiCorp Sans | 13px (0.81rem) | 600 | 1.69 (寬鬆) | 1.3px | `text-transform: uppercase` |

### 原則
- **品牌/系統分流**：標題和品牌關鍵文字使用 HashiCorp Sans；內文、導覽和功能性文字使用 system-ui。品牌字體帶動份量感，system-ui 承載內容訊息。
- **始終開啟 Kern**：所有 HashiCorp Sans 文字都啟用了 OpenType `"kern"`——字母間距調整是不可妥協的。
- **緊湊標題**：每個標題都使用 1.17–1.21 的行高，創造出密集的、堆疊的文字塊，感覺就像基礎設施一樣——堅實且具負重力。
- **寬鬆內文**：內文使用 1.50–1.69 的行高（相當慷慨），在密集的標題下創造出舒適的閱讀節奏。
- **大寫標籤作為路徑指引**：13px 大寫搭配 1.3px 字距，作為系統化的類別/區塊標記——始終使用 HashiCorp Sans 字重 600。

## 4. 組件樣式

### 按鈕

**主要深色**
- 背景：`#15181e`
- 文字：`#d5d7db`
- 內距：9px 9px 9px 15px（不對稱，左側內距較多）
- 圓角：5px
- 邊框：`1px solid rgba(178, 182, 189, 0.4)`
- 陰影：`rgba(97, 104, 117, 0.05) 0px 1px 1px, rgba(97, 104, 117, 0.05) 0px 2px 2px`
- 焦點：`3px solid var(--mds-color-focus-action-external)`
- 懸停：使用 `--mds-color-surface-interactive` 標記

**次要白色**
- 背景：`#ffffff`
- 文字：`#3b3d45`
- 內距：8px 12px
- 圓角：4px
- 懸停：`--mds-color-surface-interactive` + 低高度陰影提升
- 焦點：`3px solid transparent` 輪廓
- 簡潔、極簡外觀

**產品色彩按鈕**
- Terraform：背景 `#7b42bc`
- Vault：背景 `#ffcf25`（深色文字）
- Waypoint：背景 `#14c6cb`，懸停 `#12b6bb`
- 每個產品按鈕遵循相同的結構模式，但使用其品牌色彩。

### 徽章 / 藥丸 (Pills)
- 背景：`#42225b`（深紫色）
- 文字：`#efeff1`
- 內距：3px 7px
- 圓角：5px
- 邊框：`1px solid rgb(180, 87, 255)`
- 字體：16px

### 輸入框

**文字輸入 (深色模式)**
- 背景：`#0d0e12`
- 文字：`#efeff1`
- 邊框：`1px solid rgb(97, 104, 117)`
- 內距：11px
- 圓角：5px
- 焦點：`3px solid var(--mds-color-focus-action-external)` 輪廓

**核取方塊 (Checkbox)**
- 背景：`#0d0e12`
- 邊框：`1px solid rgb(97, 104, 117)`
- 圓角：3px

### 連結
- **淺色背景上的行動藍**：`#2264d6`，懸停 → blue-600 變數，懸停時加底線。
- **深色背景上的行動藍**：`#1060ff` 或 `#2b89ff`，懸停時加底線。
- **深色背景上的白色**：`#ffffff`，透明底線 → 懸停時變為可見底線。
- **淺色背景上的中性色**：`#3b3d45`，透明底線 → 懸停時變為可見底線。
- **深色背景上的淺色**：`#efeff1`，類似的懸停模式。
- 所有連結皆使用 `var(--wpl-blue-600)` 作為懸停顏色。

### 卡片與容器
- 淺色模式：白色背景、微陰影提升高度。
- 深色模式：`#15181e` 或更深的表面。
- 圓角：卡片和容器為 8px。
- 帶有漸層邊框或強調照明的產品展示卡。

### 導覽
- 乾淨的水平導覽，帶有大選單 (mega-menu) 下拉列表。
- HashiCorp 標誌左對齊。
- 連結使用 system-ui 15px 字重 500。
- 產品類別依據生命週期管理群組組織。
- 頁首包含「開始使用」和「聯絡我們」的 CTA。
- 英雄區塊使用深色模式變體。

## 5. 版面配置原則

### 間距系統
- 基準單位：8px
- 比例：2px, 3px, 4px, 6px, 7px, 8px, 9px, 11px, 12px, 16px, 20px, 24px, 32px, 40px, 48px

### 網格與容器
- 最大內容寬度：~1150px (xl 斷點)
- 全寬深色英雄區塊，內容包含在容器內。
- 卡片網格：2–3 欄版面。
- 桌面尺寸具備慷慨的水平內距。

### 斷點 (Breakpoints)
| 名稱 | 寬度 | 關鍵變化 |
|------|-------|-------------|
| 超小手機 | <375px | 緊湊單欄 |
| 行動裝置 | 375–480px | 標準手機尺寸 |
| 小平板 | 480–600px | 微幅調整 |
| 平板 | 600–768px | 開始出現 2 欄網格 |
| 小螢幕電腦 | 768–992px | 顯示完整導覽 |
| 桌上型電腦 | 992–1120px | 標準版面 |
| 大螢幕電腦 | 1120–1440px | 最大寬度內容 |
| 超寬螢幕 | >1440px | 居中，慷慨的邊距 |

### 留白哲學
- **企業級呼吸空間**：區塊間慷慨的垂直間距 (48px–80px+) 傳達了穩定感與嚴肅感。
- **密集標題，寬鬆內文**：緊湊行高的標題位於寬鬆內文上方，在每個區塊頂部營造出視覺「重量感」。
- **深色作為畫布**：深色英雄區塊使用額外的垂直內距，讓 3D 插圖和漸層能有呼吸空間。

### 圓角比例
- 極小 (2px)：連結、小型行內元素
- 細微 (3px)：核取方塊、小型輸入框
- 標準 (4px)：次要按鈕
- 舒適 (5px)：主要按鈕、徽章、輸入框
- 卡片 (8px)：卡片、容器、圖像

## 6. 深度與高度

| 層級 | 處理方式 | 用途 |
|-------|-----------|-----|
| Level 0 (平面) | 無陰影 | 預設表面、文字塊 |
| Level 1 (耳語) | `rgba(97, 104, 117, 0.05) 0px 1px 1px, rgba(97, 104, 117, 0.05) 0px 2px 2px` | 卡片、按鈕、互動表面 |
| Level 2 (焦點) | `3px solid var(--mds-color-focus-action-external)` 輪廓 | 焦點環 —— 顏色與情境匹配 |

**陰影哲學**：HashiCorp 使用了現代網頁設計中堪稱最細微的陰影系統。5% 不透明度的雙層陰影幾乎不可見——它們的存在不是為了創造視覺深度，而是為了發出「可互動」的訊號。如果你能明顯看到陰影，那就太強了。這種節制傳達了「穩定」的企業價值——沒有什麼是漂浮的，也沒有什麼是不確定的。

## 7. 該做與不該做

### 該做 (Do)
- 標題和品牌文字使用 HashiCorp Sans，內文和 UI 文字使用 system-ui。
- 在所有 HashiCorp Sans 文字上開啟 `"kern"`。
- 產品品牌色彩「僅」用於其對應的產品（Terraform = 紫色，Vault = 黃色等）。
- 區塊標記使用 13px、字重 600 且字距為 1.3px 的大寫標籤。
- 陰影保持在「耳語」級別（0.05 不透明度雙層陰影）。
- 使用 `--mds-color-*` 標記系統確保顏色應用的一致性。
- 維持緊湊標題/寬鬆內文的節奏（1.17–1.21 對比 1.50–1.69 的行高）。
- 為了無障礙設計，使用 `3px solid` 的焦點輪廓。

### 不該做 (Don't)
- 不要將產品品牌色彩用於產品情境之外（例如在 Vault 內容上使用 Terraform 紫色）。
- 陰影不透明度不要超過 0.1 —— 耳語級別是刻意的設定。
- 不要使用藥丸形按鈕（>8px 圓角）——銳利、極小的圓角是結構性的特徵。
- 不要省略標題上的 `"kern"` 特性 —— 該字體需要它。
- 不要將 HashiCorp Sans 用於小號內文 —— 它是為 17px 以上的標題設計的。
- 不要在同一個組件中混用產品顏色 —— 每個產品擁有一種顏色。
- 不要使用純黑 (`#000000`) 作為深色背景 —— 使用 `#15181e` 或 `#0d0e12`。
- 不要忘記按鈕的不對稱內距 —— 9px 9px 9px 15px 是刻意的設計。

## 8. 響應式行為

### 斷點 (Breakpoints)
| 名稱 | 寬度 | 關鍵變化 |
|------|-------|-------------|
| 行動裝置 | <768px | 單欄、漢堡選單、堆疊的 CTA |
| 平板 | 768–992px | 2 欄網格、導覽開始展開 |
| 桌上型電腦 | 992–1150px | 完整版面、大選單導覽 |
| 大型螢幕 | >1150px | 最大寬度居中，慷慨的邊距 |

### 折疊策略
- 英雄區塊標題：82px → 52px → 42px。
- 導覽：大選單 (mega-menu) → 漢堡選單。
- 產品卡片：3 欄 → 2 欄 → 堆疊。
- 深色區塊維持全寬但壓縮內距。
- 按鈕：在行動裝置上從行內變為全寬堆疊。

## 9. 代理提示指南 (Agent Prompt Guide)

### 快速色彩參考
- 淺色背景：`#ffffff`, `#f1f2f3`
- 深色背景：`#15181e`, `#0d0e12`
- 淺色文字：`#000000`, `#3b3d45`
- 深色文字：`#efeff1`, `#d5d7db`
- 連結：`#2264d6` (淺色), `#1060ff` (深色), `#2b89ff` (活動)
- 輔助文字：`#656a76`
- 邊框：`rgba(178, 182, 189, 0.4)`, `rgb(97, 104, 117)`
- 焦點：`3px solid` 符合產品情境的顏色

### 組件提示範例
- 「在深色背景 (#15181e) 上建立英雄區塊。標題為 82px HashiCorp Sans 字重 600，行高 1.17，開啟 kern，白色文字。副標題為 20px system-ui 字重 400，行高 1.50，文字顏色為 #d5d7db。兩個按鈕：主要深色 (#15181e, 5px 圓角, 內距 9px 15px) 和次要白色 (#ffffff, 4px 圓角, 內距 8px 12px)。」
- 「設計產品卡片：白色背景、8px 圓角、rgba(97,104,117,0.05) 雙層陰影。標題 26px HashiCorp Sans 字重 700，內文 16px system-ui 字重 400，行高 1.63。」
- 「建立大寫區塊標籤：13px HashiCorp Sans 字重 600，行高 1.69，字距 1.3px，text-transform uppercase，顏色為 #656a76。」
- 「建立特定產品的 CTA 按鈕：Terraform → #7b42bc 背景，Vault → #ffcf25 搭配深色文字，Waypoint → #14c6cb。所有按鈕：5px 圓角, 字重 500, 16px system-ui。」
- 「設計深色表單：#0d0e12 輸入框背景, #efeff1 文字, 1px solid rgb(97,104,117) 邊框, 5px 圓角, 11px 內距。焦點：3px solid 強調色輪廓。」

### 反覆運算指南
1. 始終從模式決定開始：淺色 (白色) 用於資訊性，深色 (#15181e) 用於英雄/產品。
2. HashiCorp Sans 僅用於標題 (17px+)，其他所有內容使用 system-ui。
3. 陰影保持在耳語級別 (0.05 不透明度) —— 如果太明顯，請降低。
4. 產品色彩是神聖的 —— 每個產品精確擁有一種顏色。
5. 焦點環始終是 3px solid，顏色與產品情境匹配。
6. 大寫標籤是系統化的路徑指引模式 —— 13px, 600, 1.3px 字距。
