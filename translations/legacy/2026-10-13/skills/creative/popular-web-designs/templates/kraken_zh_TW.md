# 設計系統：Kraken


> **Hermes Agent — 實作筆記**
>
> 原始網站使用專有字體。對於獨立的 HTML 輸出，請使用以下 CDN 替代方案：
> - **主要字體：** `Inter` | **等寬字體：** `系統等寬字體組合`
> - **字體組合 (CSS)：** `font-family: 'Inter', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;`
> - **等寬字體組合 (CSS)：** `font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace;`
> ```html
> <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
> ```
> 使用 `write_file` 建立 HTML，並透過 `generative-widgets` 技能（cloudflared tunnel）提供服務。
> 生成後使用 `browser_vision` 驗證視覺準確性。

## 1. 視覺主題與氛圍

Kraken 的網站是一個潔淨、值得信賴的加密貨幣交易所，使用紫色作為其主導性的品牌色彩。設計運行在白色背景上，Kraken Purple (`#7132f5`, `#5741d8`, `#5b1ecf`) 創造出一種獨特的、專業的加密貨幣識別。專有的 Kraken-Brand 字體以粗體 (700) 字重和負字距處理展示標題，而 Kraken-Product (後備字體為 IBM Plex Sans) 則作為 UI 的主力字體。

**關鍵特徵：**
- Kraken Purple (`#7132f5`) 作為主要品牌色，帶有較深色的變體 (`#5741d8`, `#5b1ecf`)。
- Kraken-Brand (展示用) + Kraken-Product (UI 用) 雙字體系統。
- 近乎黑色 (`#101114`) 的文字，搭配冷色調的藍灰色中性色階。
- 12px 圓角半徑按鈕（具圓角但不呈藥丸形）。
- 極其細微的陰影 (`rgba(0,0,0,0.03) 0px 4px 24px`)——耳語級。
- 綠色強調色 (`#149e61`) 用於正面/成功狀態。

## 2. 色彩配置與角色

### 主要色彩
- **Kraken Purple** (`#7132f5`)：主要行動呼籲 (CTA)、品牌強調色、連結。
- **深紫色 (Purple Dark)** (`#5741d8`)：按鈕邊框、外框型變體。
- **濃紫色 (Purple Deep)** (`#5b1ecf`)：最深層的紫色。
- **淡紫色 (Purple Subtle)** (`rgba(133,91,251,0.16)`)：16% 不透明度的紫色——細微的按鈕背景。
- **近乎黑** (`#101114`)：主要文字。

### 中性色彩
- **冷灰** (`#686b82`)：主要中性色，24% 不透明度的邊框。
- **銀藍** (`#9497a9`)：次要文字、淡化元素。
- **純白** (`#ffffff`)：主要表面。
- **邊框灰** (`#dedee5`)：分隔線邊框。

### 語義化色彩
- **綠色** (`#149e61`)：16% 不透明度的成功/正面狀態，用於徽章背景。
- **深綠色** (`#026b3f`)：徽章文字。

## 3. 字體排印規則

### 字體系列
- **展示 (Display)**：`Kraken-Brand`，後備字體：`IBM Plex Sans, Helvetica, Arial`
- **UI / 本文**：`Kraken-Product`，後備字體：`Helvetica Neue, Helvetica, Arial`

### 層級

| 角色 | 字體 | 大小 | 字重 | 行高 | 字距 |
|------|------|------|--------|-------------|----------------|
| 英雄展示 (Hero) | Kraken-Brand | 48px | 700 | 1.17 | -1px |
| 區塊標題 | Kraken-Brand | 36px | 700 | 1.22 | -0.5px |
| 副標題 | Kraken-Brand | 28px | 700 | 1.29 | -0.5px |
| 特色名稱 | Kraken-Product | 22px | 600 | 1.20 | normal |
| 本文 | Kraken-Product | 16px | 400 | 1.38 | normal |
| 中量本文 | Kraken-Product | 16px | 500 | 1.38 | normal |
| 按鈕 | Kraken-Product | 16px | 500–600 | 1.38 | normal |
| 圖說 (Caption) | Kraken-Product | 14px | 400–700 | 1.43–1.71 | normal |
| 小號字體 | Kraken-Product | 12px | 400–500 | 1.33 | normal |
| 微型字體 | Kraken-Product | 7px | 500 | 1.00 | uppercase |

## 4. 組件樣式

### 按鈕

**主要紫色**
- 背景：`#7132f5`
- 文字：`#ffffff`
- 內距：13px 16px
- 圓角半徑：12px

**紫色外框型**
- 背景：`#ffffff`
- 文字：`#5741d8`
- 邊框：`1px solid #5741d8`
- 圓角半徑：12px

**紫色細微 (Subtle)**
- 背景：`rgba(133,91,251,0.16)`
- 文字：`#7132f5`
- 內距：8px
- 圓角半徑：12px

**白色按鈕**
- 背景：`#ffffff`
- 文字：`#101114`
- 圓角半徑：10px
- 陰影：`rgba(0,0,0,0.03) 0px 4px 24px`

**次要灰色**
- 背景：`rgba(148,151,169,0.08)`
- 文字：`#101114`
- 圓角半徑：12px

### 徽章 (Badges)
- 成功：`rgba(20,158,97,0.16)` 背景，`#026b3f` 文字，6px 圓角。
- 中性：`rgba(104,107,130,0.12)` 背景，`#484b5e` 文字，8px 圓角。

## 5. 版面配置原則

### 間距：1px, 2px, 3px, 4px, 5px, 6px, 8px, 10px, 12px, 13px, 15px, 16px, 20px, 24px, 25px
### 圓角半徑：3px, 6px, 8px, 10px, 12px, 16px, 9999px, 50%

## 6. 深度與高度
- 細微：`rgba(0,0,0,0.03) 0px 4px 24px`
- 微型：`rgba(16,24,40,0.04) 0px 1px 4px`

## 7. 該做與不該做

### 該做 (Do)
- 將 Kraken Purple (#7132f5) 用於行動呼籲 (CTA) 和連結。
- 在所有按鈕上應用 12px 的圓角半徑。
- 標題使用 Kraken-Brand，本文使用 Kraken-Product。

### 不該做 (Don't)
- 不要使用藥丸形按鈕——12px 是按鈕的最大半徑。
- 不要使用定義色階之外的其他紫色。

## 8. 響應式行為
斷點：375px, 425px, 640px, 768px, 1024px, 1280px, 1536px

## 9. 代理提示指南 (Agent Prompt Guide)

### 快速色彩參考
- 品牌色：Kraken Purple (`#7132f5`)
- 深色變體：`#5741d8`
- 文字：近乎黑 (`#101114`)
- 次要文字：`#9497a9`
- 背景：純白 (`#ffffff`)

### 組件提示範例
- 「建立英雄區塊：白色背景。Kraken-Brand 48px 字重 700，字距 -1px。紫色 CTA (#7132f5, 12px 圓角, 內距 13px 16px)。」
