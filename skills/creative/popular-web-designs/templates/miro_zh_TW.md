# 設計系統：Miro


> **Hermes Agent — 實作筆記**
>
> 原始網站使用專有字體。為了生成自包含的 HTML 輸出，請使用以下 CDN 替代方案：
> - **主要字體：** `Inter` | **等寬字體：** `system monospace stack`
> - **字體棧 (CSS)：** `font-family: 'Inter', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;`
> - **等寬字體棧 (CSS)：** `font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace;`
> ```html
> <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
> ```
> 使用 `write_file` 建立 HTML，透過 `generative-widgets` 技能（cloudflared 隧道）提供服務。
> 生成後使用 `browser_vision` 驗證視覺準確性。

## 1. 視覺主題與氛圍

Miro 的網站是一個乾淨、以協作工具為核心的平台，透過大量的留白、粉彩色調的點綴色以及大膽的幾何字體來傳達「視覺化思考」。設計主要使用白色畫布搭配近乎黑色的文字 (`#1c1c1e`)，以及獨特的粉彩色調——珊瑚色、玫瑰色、藍綠色、橘色、黃色、苔蘚綠——每一種顏色都代表不同的協作情境。

排版方面，主要顯示字體使用 Roobert PRO Medium，並開啟 OpenType 字元變體 (`"blwf", "cv03", "cv04", "cv09", "cv11"`)，在 56px 大小時使用負字距 (-1.68px)。內文則由 Noto Sans 處理，並配有其特定的樣式集 (`"liga" 0, "ss01", "ss04", "ss05"`)。整個設計是使用 Framer 構建的，賦予其流暢的動畫和現代的組件模式。

**關鍵特性：**
- 白色畫布搭配近黑 (`#1c1c1e`) 文字
- 帶有多個 OpenType 字元變體的 Roobert PRO Medium
- 粉彩點綴色調：珊瑚色、玫瑰色、藍綠色、橘色、黃色、苔蘚綠（淺色與深色成對）
- Blue 450 (`#5b76fe`) 作為主要互動顏色
- 成功綠 (`#00b473`) 用於正面狀態
- 寬大的邊框圓角：範圍從 8px 到 50px
- 使用 Framer 構建，具備流暢的動態效果
- 環狀陰影邊框：`rgb(224,226,232) 0px 0px 0px 1px`

## 2. 調色盤與角色

### 主要顏色
- **近黑 (Near Black)** (`#1c1c1e`)：主要文字
- **白色 (White)** (`#ffffff`)：`--tw-color-white`，主要表面
- **藍色 450 (Blue 450)** (`#5b76fe`)：`--tw-color-blue-450`，主要互動色
- **操作按下 (Actionable Pressed)** (`#2a41b6`)：`--tw-color-actionable-pressed`

### 粉彩點綴色（淺/深成對）
- **珊瑚色 (Coral)**：淺色 `#ffc6c6` / 深色 `#600000`
- **玫瑰色 (Rose)**：淺色 `#ffd8f4` / 深色 (隱含)
- **藍綠色 (Teal)**：淺色 `#c3faf5` / 深色 `#187574`
- **橘色 (Orange)**：淺色 `#ffe6cd`
- **黃色 (Yellow)**：深色 `#746019`
- **苔蘚綠 (Moss)**：深色 `#187574`
- **粉紅色 (Pink)** (`#fde0f0`)：柔軟粉紅表面
- **紅色 (Red)** (`#fbd4d4`)：淺紅表面
- **深紅 (Dark Red)** (`#e3c5c5`)：柔和紅

### 語意化顏色
- **成功 (Success)** (`#00b473`)：`--tw-color-success-accent`

### 中性色
- **石板灰 (Slate)** (`#555a6a`)：次要文字
- **輸入框佔位文字 (Input Placeholder)** (`#a5a8b5`)：`--tw-color-input-placeholder`
- **邊框 (Border)** (`#c7cad5`)：按鈕邊框
- **環狀 (Ring)** (`rgb(224,226,232)`)：作為邊框的陰影

## 3. 排版規則

### 字體系列
- **顯示字體 (Display)**：`Roobert PRO Medium`，備用：佔位符 — `"blwf", "cv03", "cv04", "cv09", "cv11"`
- **顯示字體變體**：`Roobert PRO SemiBold`, `Roobert PRO SemiBold Italic`, `Roobert PRO`
- **內文字體 (Body)**：`Noto Sans` — `"liga" 0, "ss01", "ss04", "ss05"`

### 層級結構

| 角色 | 字體 | 大小 | 字重 | 行高 | 字距 |
|------|------|------|--------|-------------|----------------|
| Hero 顯示 | Roobert PRO Medium | 56px | 400 | 1.15 | -1.68px |
| 段落標題 | Roobert PRO Medium | 48px | 400 | 1.15 | -1.44px |
| 卡片標題 | Roobert PRO Medium | 24px | 400 | 1.15 | -0.72px |
| 副標題 | Noto Sans | 22px | 400 | 1.35 | -0.44px |
| 特色文字 | Roobert PRO Medium | 18px | 600 | 1.35 | 正常 |
| 內文 | Noto Sans | 18px | 400 | 1.45 | 正常 |
| 標準內文 | Noto Sans | 16px | 400–600 | 1.50 | -0.16px |
| 按鈕 | Roobert PRO Medium | 17.5px | 700 | 1.29 | 0.175px |
| 圖說 (Caption) | Roobert PRO Medium | 14px | 400 | 1.71 | 正常 |
| 小字 | Roobert PRO Medium | 12px | 400 | 1.15 | -0.36px |
| 微型大寫 | Roobert PRO | 10.5px | 400 | 0.90 | 大寫 |

## 4. 組件樣式

### 按鈕 (Buttons)
- 描邊型：透明背景，`1px solid #c7cad5`，8px 圓角，7px 12px 內距
- 白色圓形：50% 圓角，白色背景帶陰影
- 藍色主要按鈕（從互動色隱含）

### 卡片 (Cards)：12px–24px 圓角，粉彩背景
### 輸入框 (Inputs)：白色背景，`1px solid #e9eaef`，8px 圓角，16px 內距

## 5. 佈局原則
- 間距 (Spacing)：1–24px 基礎比例
- 圓角 (Radius)：8px (按鈕)，10px–12px (卡片)，20px–24px (面板)，40px–50px (大型容器)
- 環狀陰影：`rgb(224,226,232) 0px 0px 0px 1px`

## 6. 深度與層次
極簡風格 — 環狀陰影 + 粉彩表面對比

## 7. 規範 (Do's and Don'ts)
### 建議 (Do)
- 在特色區塊使用粉彩淺/深成對色彩
- 套用帶有 OpenType 字元變體的 Roobert PRO
- 對互動元素使用 Blue 450 (#5b76fe)
### 避免 (Don't)
- 不要使用沈重的陰影
- 每個區塊不要混合超過 2 種粉彩點綴色

## 8. 響應式行為
斷點 (Breakpoints)：425px, 576px, 768px, 896px, 1024px, 1200px, 1280px, 1366px, 1700px, 1920px

## 9. Agent 提示詞指南
### 快速顏色參考
- 文字：近黑 (`#1c1c1e`)
- 背景：白色 (`#ffffff`)
- 互動：Blue 450 (`#5b76fe`)
- 成功：`#00b473`
- 邊框：`#c7cad5`
### 組件提示詞範例
- "建立 Hero 區塊：白色背景。Roobert PRO Medium 56px, line-height 1.15, letter-spacing -1.68px。藍色 CTA (#5b76fe)。描邊型次要按鈕 (1px solid #c7cad5, 8px radius)。"
