# 設計系統：Intercom


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

Intercom 的網站是一個溫暖且自信的客戶服務平台，透過潔淨、具編輯感的設計語言傳達「AI 優先服務台」的理念。頁面運行在溫暖的米白色 (`#faf9f6`) 畫布上，搭配偏黑色 (`#111111`) 的文字，營造出親切、雜誌般的閱讀體驗。招牌的 Fin Orange (`#ff5600`)——以 Intercom 的 AI 代理人命名——在溫暖的中性色調中作為唯一的鮮豔強調色。

字體排印使用 Saans——一種客製化的幾何無襯線體，具有強烈的負字距（80px 時為 -2.4px，24px 時為 -0.48px），且在所有標題尺寸下皆維持一致的 1.00 行高。這創造了極致壓縮、看板般的標題，感覺精準且經過工程設計。Serrif 則是襯線體的配套，用於具編輯感的時刻，而 SaansMono 則處理程式碼和大寫的技術標籤。MediumLL 和 LLMedium 則出現在特定的 UI 情境中，共同構成了一個豐富的五字體生態系統。

Intercom 的獨特之處在於其顯著銳利的幾何形狀——按鈕上 4px 的圓角半徑創造出近乎矩形的互動元素，給人一種工業且精準的感覺，與溫暖的表面色彩形成對比。按鈕懸停狀態使用 `scale(1.1)` 擴張，創造出一種物理性的「增長」互動。邊框系統使用溫暖的燕麥色調 (`#dedbd6`)，並基於 oklab 的不透明度數值進行精緻的色彩管理。

**關鍵特徵：**
- 溫暖的米白色畫布 (`#faf9f6`) 搭配燕麥色調邊框 (`#dedbd6`)。
- Saans 字體，具備極致的負字距（80px 時為 -2.4px）和 1.00 行高。
- Fin Orange (`#ff5600`) 作為唯一的品牌強調色。
- 銳利的 4px 圓角半徑——近乎矩形的按鈕和元素。
- 懸停時 scale(1.1)，點擊活動時 scale(0.85)——物理性的按鈕互動。
- SaansMono 大寫標籤，具備寬字距 (0.6px–1.2px)。
- 豐富的多色報告色盤（藍、綠、紅、粉、萊姆、橘）。
- 使用 oklab 色彩值進行精緻的不透明度管理。

## 2. 色彩配置與角色

### 主要色彩
- **偏黑 (Off Black)** (`#111111`)：`--color-off-black`，主要文字、按鈕背景。
- **純白** (`#ffffff`)：`--wsc-color-content-primary`，主要表面。
- **暖奶油色 (Warm Cream)** (`#faf9f6`)：按鈕背景、卡片表面。
- **Fin Orange** (`#ff5600`)：`--color-fin`，主要品牌強調色。
- **報告橘 (Report Orange)** (`#fe4c02`)：`--color-report-orange`，數據視覺化。

### 報告色盤 (Report Palette)
- **報告藍** (`#65b5ff`)：`--color-report-blue`。
- **報告綠** (`#0bdf50`)：`--color-report-green`。
- **報告紅** (`#c41c1c`)：`--color-report-red`。
- **報告粉** (`#ff2067`)：`--color-report-pink`。
- **報告萊姆** (`#b3e01c`)：`--color-report-lime-300`。
- **綠色** (`#00da00`)：`--color-green`。
- **深藍** (`#0007cb`)：深藍色強調色。

### 中性色階 (暖色)
- **Black 80** (`#313130`)：`--wsc-color-black-80`，深色中性色。
- **Black 60** (`#626260`)：`--wsc-color-black-60`，中度中性色。
- **Black 50** (`#7b7b78`)：`--wsc-color-black-50`，柔和文字。
- **三級內容色** (`#9c9fa5`)：`--wsc-color-content-tertiary`。
- **燕麥色邊框 (Oat Border)** (`#dedbd6`)：溫暖的邊框顏色。
- **暖沙色 (Warm Sand)** (`#d3cec6`)：淺暖中性色。

## 3. 字體排印規則

### 字體系列
- **主要字體**：`Saans`，後備字體：`Saans Fallback, ui-sans-serif, system-ui`
- **襯線字體**：`Serrif`，後備字體：`Serrif Fallback, ui-serif, Georgia`
- **等寬字體**：`SaansMono`，後備字體：`SaansMono Fallback, ui-monospace`
- **UI 字體**：`MediumLL` / `LLMedium`，後備字體：`system-ui, -apple-system`

### 層級

| 角色 | 字體 | 大小 | 字重 | 行高 | 字距 |
|------|------|------|--------|-------------|----------------|
| 英雄展示 (Hero) | Saans | 80px | 400 | 1.00 (緊湊) | -2.4px |
| 區塊標題 | Saans | 54px | 400 | 1.00 | -1.6px |
| 副標題 | Saans | 40px | 400 | 1.00 | -1.2px |
| 卡片標題 | Saans | 32px | 400 | 1.00 | -0.96px |
| 特色標題 | Saans | 24px | 400 | 1.00 | -0.48px |
| 強調本文 | Saans | 20px | 400 | 0.95 | -0.2px |
| 導覽 / UI | Saans | 18px | 400 | 1.00 | normal |
| 本文 | Saans | 16px | 400 | 1.50 | normal |
| 輕內文 | Saans | 14px | 300 | 1.40 | normal |
| 按鈕 | Saans | 16px / 14px | 400 | 1.50 / 1.43 | normal |
| 粗體按鈕 | LLMedium | 16px | 700 | 1.20 | 0.16px |
| 襯線內文 | Serrif | 16px | 300 | 1.40 | -0.16px |
| 等寬標籤 | SaansMono | 12px | 400–500 | 1.00–1.30 | 0.6px–1.2px 大寫 |

## 4. 組件樣式

### 按鈕

**主要深色**
- 背景：`#111111`
- 文字：`#ffffff`
- 內距：0px 14px
- 圓角半徑：4px
- 懸停：白色背景、深色文字、scale(1.1)
- 活動：綠色背景 (`#2c6415`)、scale(0.85)

**外框型 (Outlined)**
- 背景：透明
- 文字：`#111111`
- 邊框：`1px solid #111111`
- 圓角半徑：4px
- 相同的縮放懸停/活動行為

**暖色卡片按鈕**
- 背景：`#faf9f6`
- 文字：`#111111`
- 內距：16px
- 邊框：`1px solid oklab(... / 0.1)`

### 卡片與容器
- 背景：`#faf9f6`（暖奶油色）
- 邊框：`1px solid #dedbd6`（暖燕麥色）
- 圓角半徑：8px
- 無明顯陰影

### 導覽
- 連結使用 Saans 18px。
- 白底偏黑色文字。
- 小型 4px–6px 圓角按鈕。
- AI 功能使用 Fin Orange 強調。

## 5. 版面配置原則

### 間距：8px, 10px, 12px, 14px, 16px, 20px, 24px, 32px, 40px, 48px, 60px, 64px, 80px, 96px
### 圓角半徑：4px (按鈕), 6px (導覽項目), 8px (卡片、容器)

## 6. 深度與高度
極少的陰影。透過溫暖的邊框顏色和表面色調來呈現深度。

## 7. 該做與不該做

### 該做 (Do)
- 在所有標題上使用 1.00 行高和負字距的 Saans。
- 在按鈕上應用 4px 圓角半徑——銳利的幾何形狀是識別特徵。
- 僅將 Fin Orange (#ff5600) 用於 AI 或品牌強調。
- 在按鈕上應用 scale(1.1) 懸停效果。
- 使用溫暖的中性色 (#faf9f6, #dedbd6)。

### 不該做 (Don't)
- 不要讓按鈕圓角超過 4px。
- 不要將 Fin Orange 用於裝飾目的。
- 不要使用冷灰色邊框——始終使用暖燕麥色調。
- 不要省略標題上的負字距。

## 8. 響應式行為
斷點：425px, 530px, 600px, 640px, 768px, 896px

## 9. 代理提示指南 (Agent Prompt Guide)

### 快速色彩參考
- 文字：偏黑 (`#111111`)
- 背景：暖奶油色 (`#faf9f6`)
- 強調：Fin Orange (`#ff5600`)
- 邊框：燕麥色 (`#dedbd6`)
- 柔和色：`#7b7b78`

### 組件提示範例
- 「建立英雄區塊：暖奶油色 (#faf9f6) 背景。Saans 80px 字重 400，行高 1.00，字距 -2.4px，顏色 #111111。深色按鈕 (#111111, 4px 圓角)。懸停時：scale(1.1)，白色背景。」
