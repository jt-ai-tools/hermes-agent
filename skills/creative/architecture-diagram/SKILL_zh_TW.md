---
name: architecture-diagram
description: 生成專業的深色主題系統架構圖，作為獨立的 HTML/SVG 檔案。輸出內容自包含，無需外部依賴。基於 Cocoon AI 的 architecture-diagram-generator (MIT)。
version: 1.0.0
author: Cocoon AI (hello@cocoon-ai.com), 由 Hermes Agent 移植
license: MIT
dependencies: []
metadata:
  hermes:
    tags: [architecture, diagrams, SVG, HTML, visualization, infrastructure, cloud]
    related_skills: [excalidraw]
---

# 架構圖技能 (Architecture Diagram Skill)

生成專業、深色主題的技術架構圖，作為包含內嵌 SVG 圖形的獨立 HTML 檔案。無需外部工具、無需 API 金鑰、無需渲染庫 —— 只需編寫 HTML 檔案並在瀏覽器中開啟即可。

基於 [Cocoon AI 的 architecture-diagram-generator](https://github.com/Cocoon-AI/architecture-diagram-generator) (MIT)。

## 工作流程

1. 使用者描述其系統架構（組件、連接、技術）
2. 按照下方的設計系統生成 HTML 檔案
3. 使用 `write_file` 儲存為 `.html` 檔案（例如 `~/architecture-diagram.html`）
4. 使用者在任何瀏覽器中開啟 —— 可離線工作，無依賴

### 輸出位置

將圖表儲存到使用者指定的路徑，或預設為當前工作目錄：
```
./[project-name]-architecture.html
```

### 預覽

儲存後，建議使用者開啟它：
```bash
# macOS
open ./my-architecture.html
# Linux
xdg-open ./my-architecture.html
```

## 設計系統與視覺語言

### 調色盤（語義映射）

使用特定的 `rgba` 填充和十六進位邊框來分類組件：

| 組件類型 | 填充 (rgba) | 邊框 (Hex) |
| :--- | :--- | :--- |
| **前端 (Frontend)** | `rgba(8, 51, 68, 0.4)` | `#22d3ee` (cyan-400) |
| **後端 (Backend)** | `rgba(6, 78, 59, 0.4)` | `#34d399` (emerald-400) |
| **資料庫 (Database)** | `rgba(76, 29, 149, 0.4)` | `#a78bfa` (violet-400) |
| **AWS/雲端 (AWS/Cloud)** | `rgba(120, 53, 15, 0.3)` | `#fbbf24` (amber-400) |
| **安全 (Security)** | `rgba(136, 19, 55, 0.4)` | `#fb7185` (rose-400) |
| **訊息匯流排 (Message Bus)** | `rgba(251, 146, 60, 0.3)` | `#fb923c` (orange-400) |
| **外部 (External)** | `rgba(30, 41, 59, 0.5)` | `#94a3b8` (slate-400) |

### 字體與背景
- **字體：** JetBrains Mono (Monospace)，從 Google Fonts 載入
- **大小：** 12px（名稱）、9px（子標籤）、8px（註釋）、7px（微小標籤）
- **背景：** Slate-950 (`#020617`)，帶有細微的 40px 網格圖案

```svg
<!-- 背景網格圖案 -->
<pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
  <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#1e293b" stroke-width="0.5"/>
</pattern>
```

## 技術實作細節

### 組件渲染
組件是帶有 1.5px 邊框的圓角矩形 (`rx="6"`)。為了防止箭頭透過半透明填充顯示出來，請使用**雙矩形遮罩技術**：
1. 繪製一個不透明的背景矩形 (`#0f172a`)
2. 在頂部繪製半透明的樣式矩形

### 連接規則
- **Z-軸順序：** 在 SVG 的早期（網格之後）繪製箭頭，以便它們在組件框後面渲染
- **箭頭：** 透過 SVG markers 定義
- **安全流：** 使用玫瑰色 (`#fb7185`) 的虛線
- **邊界：**
  - *安全群組 (Security Groups):* 虛線 (`4,4`)，玫瑰色
  - *區域 (Regions):* 大虛線 (`8,4`)，琥珀色，`rx="12"`

### 間距與佈局邏輯
- **標準高度：** 60px（服務）；80-120px（大型組件）
- **垂直間距：** 組件之間至少 40px
- **訊息匯流排：** 必須放置在服務之間的*間隙中*，不能與它們重疊
- **圖例放置：** **至關重要。** 必須放置在所有邊界框之外。計算所有邊界的最低 Y 座標，並將圖例放置在距離其下方至少 20px 的位置。

## 文件結構

生成的 HTML 檔案遵循四部分佈局：
1. **頁首：** 標題（帶有脈動點指示器）和副標題
2. **主 SVG：** 包含在圓角邊框卡片內的圖表
3. **摘要卡片：** 圖表下方由三張卡片組成的網格，用於顯示高階細節
4. **頁尾：** 極簡的中繼資料

### 資訊卡片模式
```html
<div class="card">
  <div class="card-header">
    <div class="card-dot cyan"></div>
    <h3>標題</h3>
  </div>
  <ul>
    <li>• 項目一</li>
    <li>• 項目二</li>
  </ul>
</div>
```

## 輸出要求
- **單一檔案：** 一個自包含的 `.html` 檔案
- **無外部依賴：** 所有 CSS 和 SVG 必須內聯（Google Fonts 除外）
- **無 JavaScript：** 使用純 CSS 處理任何動畫（如脈動點）
- **相容性：** 必須在任何現代網頁瀏覽器中正確渲染

## 範本參考

載入完整的 HTML 範本以獲取精確的結構、CSS 和 SVG 組件範例：

```
skill_view(name="architecture-diagram", file_path="templates/template.html")
```

該範本包含每種組件類型（前端、後端、資料庫、雲端、安全）、箭頭樣式（標準、虛線、曲線）、安全群組、區域邊界和圖例的運作範例 —— 在生成圖表時請將其作為您的結構參考。
