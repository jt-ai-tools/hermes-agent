# Excalidraw 深色模式圖表 (Excalidraw Dark Mode Diagrams)

要建立深色主題的圖表，請將一個巨大的深色背景矩形作為陣列中的**第一個元素**。確保它足夠大以覆蓋任何視圖：

```json
{
  "type": "rectangle", "id": "darkbg",
  "x": -4000, "y": -3000, "width": 10000, "height": 7500,
  "backgroundColor": "#1e1e2e", "fillStyle": "solid",
  "strokeColor": "transparent", "strokeWidth": 0
}
```

接著，針對深色背景上的元素使用下方的調色盤。

## 文字顏色（在深色背景上）

| 顏色 | 十六進位 (Hex) | 用途 |
|-------|-----|-----|
| 白色 (White) | `#e5e5e5` | 主要文字、標題 |
| 柔和色 (Muted) | `#a0a0a0` | 次要文字、註釋 |
| 禁忌 | `#555` 或更深 | 在深色背景上完全不可見！ |

## 形狀填充（在深色背景上）

| 顏色 | 十六進位 (Hex) | 適用於 |
|-------|-----|----------|
| 深藍色 | `#1e3a5f` | 主要節點 |
| 深綠色 | `#1a4d2e` | 成功、輸出 |
| 深紫色 | `#2d1b69` | 處理中、特殊項目 |
| 深橘色 | `#5c3d1a` | 警告、待處理 |
| 深紅色 | `#5c1a1a` | 錯誤、關鍵 |
| 深青色 | `#1a4d4d` | 儲存、數據 |

## 線條與箭頭顏色（在深色背景上）

使用主調色盤中的標準「主要色彩」即可 —— 它們在深色背景上已經足夠明亮：
- 藍色 `#4a9eed`、琥珀色 `#f59e0b`、綠色 `#22c55e`、紅色 `#ef4444`、紫色 `#8b5cf6`

若需使用不明顯的形狀邊框，請使用 `#555555`。

## 範例：深色模式下帶標籤的矩形

使用容器綁定（**請勿**使用無效的 `"label"` 屬性）。在深色背景上，將文字的 `strokeColor` 設定為 `"#e5e5e5"` 以確保可見：

```json
[
  {
    "type": "rectangle", "id": "r1",
    "x": 100, "y": 100, "width": 200, "height": 80,
    "backgroundColor": "#1e3a5f", "fillStyle": "solid",
    "strokeColor": "#4a9eed", "strokeWidth": 2,
    "roundness": { "type": 3 },
    "boundElements": [{ "id": "t_r1", "type": "text" }]
  },
  {
    "type": "text", "id": "t_r1",
    "x": 105, "y": 120, "width": 190, "height": 25,
    "text": "深色節點", "fontSize": 20, "fontFamily": 1,
    "strokeColor": "#e5e5e5",
    "textAlign": "center", "verticalAlign": "middle",
    "containerId": "r1", "originalText": "深色節點", "autoResize": true
  }
]
```

注意：對於深色背景上的獨立文字元素，請務必明確設定 `"strokeColor": "#e5e5e5"`。預設的 `#1e1e1e` 在深色背景下是看不見的。
