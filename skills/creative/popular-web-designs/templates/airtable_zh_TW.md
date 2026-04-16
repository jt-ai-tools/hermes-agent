# 設計系統：Airtable

> **Hermes Agent — 實作筆記**
>
> 原始網站使用專有字體。對於自給自足的 HTML 輸出，請使用以下 CDN 替代方案：
> - **主要：** `Inter` | **等寬：** `system monospace stack`
> - **字體堆疊 (CSS)：** `font-family: 'Inter', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;`
> - **等寬字體堆疊 (CSS)：** `font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace;`
> ```html
> <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
> ```
> 使用 `write_file` 建立 HTML，透過 `generative-widgets` 技能（cloudflared 隧道）提供服務。
> 生成後使用 `browser_vision` 驗證視覺準確性。

## 1. 視覺主題與氛圍

Airtable 的網站是一個簡潔、對企業友好的平台，透過純白畫布搭配深海軍藍文字 (`#181d26`) 以及 Airtable Blue (`#1b61c9`) 作為主要的互動點綴色，傳遞出「精緻的簡約 (sophisticated simplicity)」感。Haas 字體系列（包含顯示與內文變體）建立了一個瑞士精確度的排版系統，並在各處使用正字距 (positive letter-spacing)。

**關鍵特徵：**
- 純白畫布搭配深海軍藍文字 (`#181d26`)
- Airtable Blue (`#1b61c9`) 作為主要 CTA 和連結顏色
- Haas + Haas Groot Disp 雙字體系統
- 內文使用正字距 (0.08px–0.28px)
- 按鈕為 12px 半徑，卡片為 16px–32px
- 多層藍色調陰影：`rgba(45,127,249,0.28) 0px 1px 3px`
- 語意化主題標記：使用 `--theme_*` CSS 變數命名

## 2. 調色盤與角色

### 主要 (Primary)
- **Deep Navy** (`#181d26`): 主要文字
- **Airtable Blue** (`#1b61c9`): CTA 按鈕, 連結
- **White** (`#ffffff`): 主要表面
- **Spotlight** (`rgba(249,252,255,0.97)`): `--theme_button-text-spotlight`

### 語意 (Semantic)
- **Success Green** (`#006400`): `--theme_success-text`
- **Weak Text** (`rgba(4,14,32,0.69)`): `--theme_text-weak`
- **Secondary Active** (`rgba(7,12,20,0.82)`): `--theme_button-text-secondary-active`

### 中性 (Neutral)
- **Dark Gray** (`#333333`): 次要文字
- **Mid Blue** (`#254fad`): 連結/點綴藍的變體
- **Border** (`#e0e2e6`): 卡片邊框
- **Light Surface** (`#f8fafc`): 細微表面

### 陰影 (Shadows)
- **Blue-tinted** (藍色調): `rgba(0,0,0,0.32) 0px 0px 1px, rgba(0,0,0,0.08) 0px 0px 2px, rgba(45,127,249,0.28) 0px 1px 3px, rgba(0,0,0,0.06) 0px 0px 0px 0.5px inset`
- **Soft** (柔和): `rgba(15,48,106,0.05) 0px 0px 20px`

## 3. 字體排版規則

### 字體系列 (Font Families)
- **主要 (Primary)**: `Haas`, 備用字體: `-apple-system, system-ui, Segoe UI, Roboto`
- **顯示 (Display)**: `Haas Groot Disp`, 備用字體: `Haas`

### 層級 (Hierarchy)

| 角色 (Role) | 字體 | 大小 | 字重 | 行高 | 字距 |
|------|------|------|--------|-------------|----------------|
| 顯示 Hero (Display Hero) | Haas | 48px | 400 | 1.15 | normal |
| 顯示 粗體 (Display Bold) | Haas Groot Disp | 48px | 900 | 1.50 | normal |
| 區段標題 (Section Heading) | Haas | 40px | 400 | 1.25 | normal |
| 子標題 (Sub-heading) | Haas | 32px | 400–500 | 1.15–1.25 | normal |
| 卡片標題 (Card Title) | Haas | 24px | 400 | 1.20–1.30 | 0.12px |
| 特色 (Feature) | Haas | 20px | 400 | 1.25–1.50 | 0.1px |
| 內文 (Body) | Haas | 18px | 400 | 1.35 | 0.18px |
| 內文 Medium | Haas | 16px | 500 | 1.30 | 0.08–0.16px |
| 按鈕 (Button) | Haas | 16px | 500 | 1.25–1.30 | 0.08px |
| 標題 (Caption) | Haas | 14px | 400–500 | 1.25–1.35 | 0.07–0.28px |

## 4. 元件樣式

### 按鈕 (Buttons)
- **主要藍色 (Primary Blue)**: `#1b61c9`, 白色文字, 16px 24px 內邊距, 12px 半徑
- **白色 (White)**: 白色背景, `#181d26` 文字, 12px 半徑, 1px 白色邊框
- **Cookie 同意 (Cookie Consent)**: `#1b61c9` 背景, 2px 半徑 (銳利)

### 卡片 (Cards): `1px solid #e0e2e6`, 16px–24px 半徑
### 輸入框 (Inputs): 標準 Haas 樣式

## 5. 佈局 (Layout)
- 間距 (Spacing): 1–48px (以 8px 為基準)
- 半徑 (Radius): 2px (小型), 12px (按鈕), 16px (卡片), 24px (區段), 32px (大型), 50% (圓形)

## 6. 深度 (Depth)
- 藍色調多層陰影系統
- 柔和環境陰影: `rgba(15,48,106,0.05) 0px 0px 20px`

## 7. 該做與不該做的事 (Do's and Don'ts)
### 該做 (Do): CTA 使用 Airtable Blue，Haas 字體搭配正字距，按鈕使用 12px 半徑
### 不該做 (Don't): 漏掉正字距，使用沉重的陰影

## 8. 響應式行為
斷點 (Breakpoints): 425–1664px (23 個斷點)

## 9. 代理（Agent）提示指南
- 文字: Deep Navy (`#181d26`)
- CTA: Airtable Blue (`#1b61c9`)
- 背景: 白色 (`#ffffff`)
- 邊框: `#e0e2e6`
