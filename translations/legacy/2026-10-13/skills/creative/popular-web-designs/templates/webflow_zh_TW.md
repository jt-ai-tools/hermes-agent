# 設計系統：Webflow


> **Hermes Agent — 實作筆記**
>
> 原始網站使用專有字體。對於獨立的 HTML 輸出，請使用以下 CDN 替代方案：
> - **主要字體：** `Inter` | **等寬字體：** `系統等寬字體堆疊`
> - **字體堆疊 (CSS)：** `font-family: 'Inter', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;`
> - **等寬字體堆疊 (CSS)：** `font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace;`
> ```html
> <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
> ```
> 使用 `write_file` 建立 HTML，並透過 `generative-widgets` 技能（cloudflared 隧道）提供服務。
> 生成後使用 `browser_vision` 驗證視覺準確性。

## 1. 視覺主題與氛圍

Webflow 的網站是一個視覺豐富、以工具為導向的平台，透過乾淨的白色表面、標誌性的 Webflow 藍 (`#146ef5`) 以及豐富的輔助色調（紫、粉、綠、橘、黃、紅）來傳達「無需程式碼即可設計」的理念。自定義的 WF Visual Sans Variable 字體建立了一個自信、精確的排版系統，展示文字使用字重 600，內文使用字重 500。

**核心特徵：**
- 白色畫布搭配近黑色 (`#080808`) 文字。
- Webflow 藍 (`#146ef5`) 作為主要品牌色與互動顏色。
- WF Visual Sans Variable —— 字重 500–600 的自定義可變字體。
- 豐富的輔助色調：紫色 `#7a3dff`、粉色 `#ed52cb`、綠色 `#00d722`、橘色 `#ff6b00`、黃色 `#ffae13`、紅色 `#ee1d36`。
- 保守的 4px–8px 圓角 —— 銳利而非圓潤。
- 多層陰影堆疊（5 層級聯陰影）。
- 全大寫標籤：10px–15px，字重 500–600，寬字元間距 (0.6px–1.5px)。
- 按鈕懸停時帶有 `translate(6px)` 的位移動畫。

## 2. 調色盤與角色

### 主要顏色 (Primary)
- **近黑色 (Near Black)** (`#080808`)：主要文字顏色。
- **Webflow 藍 (Webflow Blue)** (`#146ef5`)：主要 CTA 和連結顏色。
- **Blue 400** (`#3b89ff`)：較淺的互動藍色。
- **Blue 300** (`#006acc`)：較深的藍色變體。
- **按鈕懸停藍** (`#0055d4`)：按鈕懸停時的顏色。

### 輔助強調色 (Secondary Accents)
- **紫色 (Purple)** (`#7a3dff`)
- **粉色 (Pink)** (`#ed52cb`)
- **綠色 (Green)** (`#00d722`)
- **橘色 (Orange)** (`#ff6b00`)
- **黃色 (Yellow)** (`#ffae13`)
- **紅色 (Red)** (`#ee1d36`)

### 中性色 (Neutral)
- **Gray 800** (`#222222`)：深色次要文字。
- **Gray 700** (`#363636`)：中等文字顏色。
- **Gray 300** (`#ababab`)：弱化文字、佔位文字。
- **Mid Gray** (`#5a5a5a`)：連結文字。
- **邊框灰 (Border Gray)** (`#d8d8d8`)：邊框、分隔線。
- **邊框懸停色 (Border Hover)** (`#898989`)：懸停時的邊框顏色。

### 陰影 (Shadows)
- **5 層級聯 (5-layer cascade)**：由多組 rgba(0,0,0) 組成的陰影堆疊，提供豐富的深度感。

## 3. 排版規則

### 字體：`WF Visual Sans Variable`，備用字體：`Arial`

| 角色 | 大小 | 字重 | 行高 | 字元間距 | 備註 |
|------|------|--------|-------------|----------------|-------|
| 英雄展示文字 | 80px | 600 | 1.04 | -0.8px | |
| 區段標題 | 56px | 600 | 1.04 | 標準 | |
| 副標題 | 32px | 500 | 1.30 | 標準 | |
| 特色標題 | 24px | 500–600 | 1.30 | 標準 | |
| 內文 | 20px | 400–500 | 1.40–1.50 | 標準 | |
| 標準內文 | 16px | 400–500 | 1.60 | -0.16px | |
| 按鈕 | 16px | 500 | 1.60 | -0.16px | |
| 全大寫標籤 | 15px | 500 | 1.30 | 1.5px | uppercase |
| 說明文字 | 14px | 400–500 | 1.40–1.60 | 標準 | |
| 全大寫徽章 | 12.8px | 550 | 1.20 | 標準 | uppercase |
| 全大寫微型文字 | 10px | 500–600 | 1.30 | 1px | uppercase |
| 程式碼：Inconsolata (伴隨等寬字體)

## 4. 元件樣式

### 按鈕 (Buttons)
- 透明按鈕：文字顏色 `#080808`，懸停時 `translate(6px)`。
- 白色圓形：50% 圓角，白色背景。
- 藍色徽章：`#146ef5` 背景，4px 圓角，字重 550。

### 卡片 (Cards)：`1px solid #d8d8d8`，4px–8px 圓角
### 徽章 (Badges)：藍色調背景 (10% 透明度)，4px 圓角

## 5. 版面配置 (Layout)
- 間距：分數比例 (1px, 2.4px, 3.2px, 4px, 5.6px, 6px, 7.2px, 8px, 9.6px, 12px, 16px, 24px)
- 圓角：2px, 4px, 8px, 50% —— 保守、銳利
- 斷點：479px, 768px, 992px

## 6. 深度 (Depth)：5 層級聯陰影系統

## 7. 規範事項 (Do's and Don'ts)
- 應該 (Do)：在 500–600 字重下使用 WF Visual Sans Variable。CTA 使用 Webflow 藍 (#146ef5)。應用 4px 圓角。懸停時使用 translate(6px)。
- 不應該 (Don't)：功能性元件的圓角超過 8px。在主要 CTA 上使用輔助顏色。

## 8. 響應式 (Responsive)：479px, 768px, 992px

## 9. Agent 提示指南
- 文字：近黑色 (`#080808`)
- CTA：Webflow 藍 (`#146ef5`)
- 背景：白色 (`#ffffff`)
- 邊框：`#d8d8d8`
- 輔助色：紫色 `#7a3dff`、粉色 `#ed52cb`、綠色 `#00d722`
