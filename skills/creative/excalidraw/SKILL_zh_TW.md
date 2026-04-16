---
name: excalidraw
description: 使用 Excalidraw JSON 格式建立手繪風格圖表。生成用於架構圖、流程圖、時序圖、概念圖等的 .excalidraw 檔案。檔案可在 excalidraw.com 開啟或上傳生成共享連結。
version: 1.0.0
author: Hermes Agent
license: MIT
dependencies: []
metadata:
  hermes:
    tags: [Excalidraw, Diagrams, Flowcharts, Architecture, Visualization, JSON]
    related_skills: []

---

# Excalidraw 圖表技能 (Excalidraw Diagram Skill)

透過編寫標準的 Excalidraw 元素 JSON 並儲存為 `.excalidraw` 檔案來建立圖表。這些檔案可以直接拖放到 [excalidraw.com](https://excalidraw.com) 進行檢視和編輯。無需帳號、無需 API 金鑰、無需渲染庫 —— 僅需 JSON。

## 工作流程

1. **載入此技能**（您已經載入）
2. **編寫元素 JSON** —— 一個 Excalidraw 元素物件的陣列
3. **儲存檔案** —— 使用 `write_file` 建立一個 `.excalidraw` 檔案
4. **選用上傳功能** —— 透過 `terminal` 執行 `scripts/upload.py` 以獲取共享連結

### 儲存圖表

將您的元素陣列封裝在標準的 `.excalidraw` 外殼中，並使用 `write_file` 儲存：

```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "hermes-agent",
  "elements": [ ...您的元素陣列在此... ],
  "appState": {
    "viewBackgroundColor": "#ffffff"
  }
}
```

儲存到任何路徑，例如 `~/diagrams/my_diagram.excalidraw`。

### 上傳獲取共享連結

透過終端機執行上傳腳本（位於此技能的 `scripts/` 目錄中）：

```bash
python skills/diagramming/excalidraw/scripts/upload.py ~/diagrams/my_diagram.excalidraw
```

這會將圖表上傳到 excalidraw.com（無需帳號）並印出共享 URL。需要安裝 `cryptography` pip 套件 (`pip install cryptography`)。

---

## 元素格式參考 (Element Format Reference)

### 必要欄位（所有元素）
`type`, `id` (唯一的字串), `x`, `y`, `width`, `height`

### 預設值（可跳過 —— 它們會自動套用）
- `strokeColor`: `"#1e1e1e"`
- `backgroundColor`: `"transparent"`
- `fillStyle`: `"solid"`
- `strokeWidth`: `2`
- `roughness`: `1` (手繪風格)
- `opacity`: `100`

畫布背景預設為白色。

### 元素類型

**矩形 (Rectangle)**:
```json
{ "type": "rectangle", "id": "r1", "x": 100, "y": 100, "width": 200, "height": 100 }
```
- `roundness: { "type": 3 }` 用於圓角
- `backgroundColor: "#a5d8ff"`, `fillStyle: "solid"` 用於填充顏色

**橢圓 (Ellipse)**:
```json
{ "type": "ellipse", "id": "e1", "x": 100, "y": 100, "width": 150, "height": 150 }
```

**菱形 (Diamond)**:
```json
{ "type": "diamond", "id": "d1", "x": 100, "y": 100, "width": 150, "height": 150 }
```

**帶標籤的形狀 (容器綁定)** —— 建立一個綁定到形狀的文字元素：

> **警告：** 請勿在形狀上使用 `"label": { "text": "..." }`。這不是有效的
> Excalidraw 屬性，會被靜默忽略，導致形狀內沒有文字。您必須
> 使用下方的容器綁定方法。

形狀需要 `boundElements` 列出該文字，而文字需要 `containerId` 指回該形狀：
```json
{ "type": "rectangle", "id": "r1", "x": 100, "y": 100, "width": 200, "height": 80,
  "roundness": { "type": 3 }, "backgroundColor": "#a5d8ff", "fillStyle": "solid",
  "boundElements": [{ "id": "t_r1", "type": "text" }] },
{ "type": "text", "id": "t_r1", "x": 105, "y": 110, "width": 190, "height": 25,
  "text": "Hello", "fontSize": 20, "fontFamily": 1, "strokeColor": "#1e1e1e",
  "textAlign": "center", "verticalAlign": "middle",
  "containerId": "r1", "originalText": "Hello", "autoResize": true }
```
- 適用於矩形、橢圓、菱形
- 當設定 `containerId` 時，文字會由 Excalidraw 自動居中
- 文字的 `x`/`y`/`width`/`height` 是近似值 —— Excalidraw 在載入時會重新計算
- `originalText` 應與 `text` 內容一致
- 務必包含 `fontFamily: 1` (Virgil/手繪字體)

**帶標籤的箭頭** —— 採用相同的容器綁定方法：
```json
{ "type": "arrow", "id": "a1", "x": 300, "y": 150, "width": 200, "height": 0,
  "points": [[0,0],[200,0]], "endArrowhead": "arrow",
  "boundElements": [{ "id": "t_a1", "type": "text" }] },
{ "type": "text", "id": "t_a1", "x": 370, "y": 130, "width": 60, "height": 20,
  "text": "連接", "fontSize": 16, "fontFamily": 1, "strokeColor": "#1e1e1e",
  "textAlign": "center", "verticalAlign": "middle",
  "containerId": "a1", "originalText": "連接", "autoResize": true }
```

**獨立文字**（僅用於標題和註釋 —— 無容器）：
```json
{ "type": "text", "id": "t1", "x": 150, "y": 138, "text": "Hello", "fontSize": 20,
  "fontFamily": 1, "strokeColor": "#1e1e1e", "originalText": "Hello", "autoResize": true }
```
- `x` 是左邊緣。若要在位置 `cx` 居中：`x = cx - (文字長度 * fontSize * 0.5) / 2`
- 請勿依賴 `textAlign` 或 `width` 進行定位

**箭頭 (Arrow)**:
```json
{ "type": "arrow", "id": "a1", "x": 300, "y": 150, "width": 200, "height": 0,
  "points": [[0,0],[200,0]], "endArrowhead": "arrow" }
```
- `points`: 相對於元素 `x`, `y` 的 `[dx, dy]` 偏移量
- `endArrowhead`: `null` | `"arrow"` | `"bar"` | `"dot"` | `"triangle"`
- `strokeStyle`: `"solid"` (預設) | `"dashed"` (虛線) | `"dotted"` (點線)

### 箭頭綁定（將箭頭連接到形狀）

```json
{
  "type": "arrow", "id": "a1", "x": 300, "y": 150, "width": 150, "height": 0,
  "points": [[0,0],[150,0]], "endArrowhead": "arrow",
  "startBinding": { "elementId": "r1", "fixedPoint": [1, 0.5] },
  "endBinding": { "elementId": "r2", "fixedPoint": [0, 0.5] }
}
```

`fixedPoint` 座標：`top=[0.5,0]`, `bottom=[0.5,1]`, `left=[0,0.5]`, `right=[1,0.5]`

### 繪製順序 (z-order)
- 陣列順序即為 z-order（越前方的元素越底層，越後方的元素越頂層）
- 建議依序輸出：背景區域 → 形狀 → 該形狀的綁定文字 → 指向它的箭頭 → 下一個形狀
- **錯誤做法**：先輸出所有矩形，再輸出所有文字，最後輸出所有箭頭
- **正確做法**：背景區域 → 形狀1 → 形狀1的文字 → 箭頭1 → 箭頭標籤文字 → 形狀2 → 形狀2的文字 → ...
- 務必將綁定文字元素緊接在其容器形狀之後

### 尺寸指南

**字體大小 (Font sizes):**
- 正文、標籤、描述：最小 `fontSize`: **16**
- 標題與標頭：最小 `fontSize`: **20**
- 僅用於次要註釋：最小 `fontSize`: **14**（謹慎使用）
- 絕不要使用低於 14 的 `fontSize`

**元素尺寸:**
- 帶標籤的矩形/橢圓：最小形狀尺寸 120x60
- 元素間至少保留 20-30px 的間隙
- 寧可使用少量較大的元素，也不要使用大量細小的元素

### 調色盤 (Color Palette)

完整的顏色表請參閱 [references/colors_zh_TW.md](references/colors_zh_TW.md)。快速參考：

| 用途 | 填充顏色 | 十六進位 (Hex) |
|-----|-----------|-----|
| 主要 / 輸入 | 淺藍色 | `#a5d8ff` |
| 成功 / 輸出 | 淺綠色 | `#b2f2bb` |
| 警告 / 外部 | 淺橘色 | `#ffd8a8` |
| 處理中 / 特殊 | 淺紫色 | `#d0bfff` |
| 錯誤 / 關鍵 | 淺紅色 | `#ffc9c9` |
| 備註 / 決策 | 淺黃色 | `#fff3bf` |
| 儲存 / 數據 | 淺青色 | `#c3fae8` |

### 提示 (Tips)
- 在整個圖表中保持一致的調色盤風格
- **文字對比度至關重要** —— 絕不要在白色背景上使用淺灰色。在白底上的最小文字顏色深度：`#757575`
- 請勿在文字中使用表情符號 (emoji) —— 它們無法在 Excalidraw 的手繪字體中正常渲染
- 關於深色模式圖表，請參閱 [references/dark-mode_zh_TW.md](references/dark-mode_zh_TW.md)
- 關於更多大型範例，請參閱 [references/examples_zh_TW.md](references/examples_zh_TW.md)
