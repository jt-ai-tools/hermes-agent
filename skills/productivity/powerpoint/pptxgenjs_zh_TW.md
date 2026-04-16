# PptxGenJS 教程

## 設定與基本結構

```javascript
const pptxgen = require("pptxgenjs");

let pres = new pptxgen();
pres.layout = 'LAYOUT_16x9';  // 或 'LAYOUT_16x10', 'LAYOUT_4x3', 'LAYOUT_WIDE'
pres.author = '你的名字';
pres.title = '簡報標題';

let slide = pres.addSlide();
slide.addText("Hello World!", { x: 0.5, y: 0.5, fontSize: 36, color: "363636" });

pres.writeFile({ fileName: "Presentation.pptx" });
```

## 版面配置尺寸

投影片尺寸（座標單位為英吋）：
- `LAYOUT_16x9`: 10" × 5.625" (預設)
- `LAYOUT_16x10`: 10" × 6.25"
- `LAYOUT_4x3`: 10" × 7.5"
- `LAYOUT_WIDE`: 13.3" × 7.5"

---

## 文字與格式

```javascript
// 基本文字
slide.addText("簡單文字", {
  x: 1, y: 1, w: 8, h: 2, fontSize: 24, fontFace: "Arial",
  color: "363636", bold: true, align: "center", valign: "middle"
});

// 字元間距 (使用 charSpacing，不要用 letterSpacing，後者會被靜默忽略)
slide.addText("加寬間距文字", { x: 1, y: 1, w: 8, h: 1, charSpacing: 6 });

// 富文本陣列 (Rich text arrays)
slide.addText([
  { text: "粗體 ", options: { bold: true } },
  { text: "斜體 ", options: { italic: true } }
], { x: 1, y: 3, w: 8, h: 1 });

// 多行文字 (需設定 breakLine: true)
slide.addText([
  { text: "第一行", options: { breakLine: true } },
  { text: "第二行", options: { breakLine: true } },
  { text: "第三行" }  // 最後一項不需要 breakLine
], { x: 0.5, y: 0.5, w: 8, h: 2 });

// 文字方塊邊距 (內部填補 Padding)
slide.addText("標題", {
  x: 0.5, y: 0.3, w: 9, h: 0.6,
  margin: 0  // 當文字需要與形狀或圖示精確對齊時，請將 margin 設為 0
});
```

**提示：** 文字方塊預設有內部邊距。當你需要文字與位於相同 x 座標的形狀、線條或圖示精確對齊時，請設定 `margin: 0`。

---

## 列表與項目符號

```javascript
// ✅ 正確：多個項目符號
slide.addText([
  { text: "第一項", options: { bullet: true, breakLine: true } },
  { text: "第二項", options: { bullet: true, breakLine: true } },
  { text: "第三項", options: { bullet: true } }
], { x: 0.5, y: 0.5, w: 8, h: 3 });

// ❌ 錯誤：絕對不要使用 Unicode 項目符號
slide.addText("• 第一項", { ... });  // 會導致出現重複的項目符號

// 子項目與編號列表
{ text: "子項目", options: { bullet: true, indentLevel: 1 } }
{ text: "第一點", options: { bullet: { type: "number" }, breakLine: true } }
```

---

## 形狀

```javascript
slide.addShape(pres.shapes.RECTANGLE, {
  x: 0.5, y: 0.8, w: 1.5, h: 3.0,
  fill: { color: "FF0000" }, line: { color: "000000", width: 2 }
});

slide.addShape(pres.shapes.OVAL, { x: 4, y: 1, w: 2, h: 2, fill: { color: "0000FF" } });

slide.addShape(pres.shapes.LINE, {
  x: 1, y: 3, w: 5, h: 0, line: { color: "FF0000", width: 3, dashType: "dash" }
});

// 具備透明度
slide.addShape(pres.shapes.RECTANGLE, {
  x: 1, y: 1, w: 3, h: 2,
  fill: { color: "0088CC", transparency: 50 }
});

// 圓角矩形 (rectRadius 僅適用於 ROUNDED_RECTANGLE，不適用於 RECTANGLE)
// ⚠️ 不要與矩形強調疊加層配合使用 — 它們無法覆蓋圓角。請改用 RECTANGLE。
slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
  x: 1, y: 1, w: 3, h: 2,
  fill: { color: "FFFFFF" }, rectRadius: 0.1
});

// 具備陰影
slide.addShape(pres.shapes.RECTANGLE, {
  x: 1, y: 1, w: 3, h: 2,
  fill: { color: "FFFFFF" },
  shadow: { type: "outer", color: "000000", blur: 6, offset: 2, angle: 135, opacity: 0.15 }
});
```

陰影選項：

| 屬性 | 類型 | 範圍 | 備註 |
|----------|------|-------|-------|
| `type` | 字串 | `"outer"`, `"inner"` | |
| `color` | 字串 | 6 位十六進位 (例如 `"000000"`) | 不加 `#` 前綴，不要用 8 位十六進位 — 請見常見陷阱 |
| `blur` | 數字 | 0-100 pt | |
| `offset` | 數字 | 0-200 pt | **必須為非負值** — 負值會損壞檔案 |
| `angle` | 數字 | 0-359 度 | 陰影投射方向 (135 = 右下，270 = 向上) |
| `opacity` | 數字 | 0.0-1.0 | 用於透明度，絕不要編碼在顏色字串中 |

若要向上投射陰影（例如在頁尾欄上），請使用 `angle: 270` 搭配正偏移量 — **不要** 使用負偏移量。

**注意**：原生不支援漸層填滿 (Gradient fills)。請改用漸層圖片作為背景。

---

## 圖片

### 圖片來源

```javascript
// 從檔案路徑
slide.addImage({ path: "images/chart.png", x: 1, y: 1, w: 5, h: 3 });

// 從 URL
slide.addImage({ path: "https://example.com/image.jpg", x: 1, y: 1, w: 5, h: 3 });

// 從 base64 (速度較快，不需檔案 I/O)
slide.addImage({ data: "image/png;base64,iVBORw0KGgo...", x: 1, y: 1, w: 5, h: 3 });
```

### 圖片選項

```javascript
slide.addImage({
  path: "image.png",
  x: 1, y: 1, w: 5, h: 3,
  rotate: 45,              // 0-359 度
  rounding: true,          // 圓形裁切
  transparency: 50,        // 0-100
  flipH: true,             // 水平翻轉
  flipV: false,            // 垂直翻轉
  altText: "描述文字",      // 無障礙存取
  hyperlink: { url: "https://example.com" }
});
```

### 圖片縮放模式

```javascript
// Contain - 符合範圍，保留比例
{ sizing: { type: 'contain', w: 4, h: 3 } }

// Cover - 填滿區域，保留比例 (可能被裁切)
{ sizing: { type: 'cover', w: 4, h: 3 } }

// Crop - 裁切特定部分
{ sizing: { type: 'crop', x: 0.5, y: 0.5, w: 2, h: 2 } }
```

### 計算尺寸 (保留長寬比)

```javascript
const origWidth = 1978, origHeight = 923, maxHeight = 3.0;
const calcWidth = maxHeight * (origWidth / origHeight);
const centerX = (10 - calcWidth) / 2;

slide.addImage({ path: "image.png", x: centerX, y: 1.2, w: calcWidth, h: maxHeight });
```

### 支援格式

- **標準格式**: PNG, JPG, GIF (動畫 GIF 可在 Microsoft 365 中運作)
- **SVG**: 可在現代版本的 PowerPoint/Microsoft 365 中運作

---

## 圖示

使用 `react-icons` 生成 SVG 圖示，然後光柵化 (rasterize) 為 PNG 以獲得最佳相容性。

### 設定

```javascript
const React = require("react");
const ReactDOMServer = require("react-dom/server");
const sharp = require("sharp");
const { FaCheckCircle, FaChartLine } = require("react-icons/fa");

function renderIconSvg(IconComponent, color = "#000000", size = 256) {
  return ReactDOMServer.renderToStaticMarkup(
    React.createElement(IconComponent, { color, size: String(size) })
  );
}

async function iconToBase64Png(IconComponent, color, size = 256) {
  const svg = renderIconSvg(IconComponent, color, size);
  const pngBuffer = await sharp(Buffer.from(svg)).png().toBuffer();
  return "image/png;base64," + pngBuffer.toString("base64");
}
```

### 將圖示新增至投影片

```javascript
const iconData = await iconToBase64Png(FaCheckCircle, "#4472C4", 256);

slide.addImage({
  data: iconData,
  x: 1, y: 1, w: 0.5, h: 0.5  // 尺寸單位為英吋
});
```

**注意**：請使用 256 或更高的尺寸以獲得清晰的圖示。`size` 參數控制的是光柵化的解析度，而非投影片上的顯示尺寸（後者由 `w` 和 `h` 設定）。

### 圖示庫

安裝：`npm install -g react-icons react react-dom sharp`

`react-icons` 中的熱門圖示集：
- `react-icons/fa` - Font Awesome
- `react-icons/md` - Material Design
- `react-icons/hi` - Heroicons
- `react-icons/bi` - Bootstrap Icons

---

## 投影片背景

```javascript
// 純色
slide.background = { color: "F1F1F1" };

// 具備透明度的顏色
slide.background = { color: "FF3399", transparency: 50 };

// 來自 URL 的圖片
slide.background = { path: "https://example.com/bg.jpg" };

// 來自 base64 的圖片
slide.background = { data: "image/png;base64,iVBORw0KGgo..." };
```

---

## 表格

```javascript
slide.addTable([
  ["標題 1", "標題 2"],
  ["儲存格 1", "儲存格 2"]
], {
  x: 1, y: 1, w: 8, h: 2,
  border: { pt: 1, color: "999999" }, fill: { color: "F1F1F1" }
});

// 具備合併儲存格的進階用法
let tableData = [
  [{ text: "標題", options: { fill: { color: "6699CC" }, color: "FFFFFF", bold: true } }, "儲存格"],
  [{ text: "合併儲存格", options: { colspan: 2 } }]
];
slide.addTable(tableData, { x: 1, y: 3.5, w: 8, colW: [4, 4] });
```

---

## 圖表

```javascript
// 長條圖
slide.addChart(pres.charts.BAR, [{
  name: "Sales", labels: ["Q1", "Q2", "Q3", "Q4"], values: [4500, 5500, 6200, 7100]
}], {
  x: 0.5, y: 0.6, w: 6, h: 3, barDir: 'col',
  showTitle: true, title: '季度營收'
});

// 折線圖
slide.addChart(pres.charts.LINE, [{
  name: "Temp", labels: ["Jan", "Feb", "Mar"], values: [32, 35, 42]
}], { x: 0.5, y: 4, w: 6, h: 3, lineSize: 3, lineSmooth: true });

// 圓形圖
slide.addChart(pres.charts.PIE, [{
  name: "Share", labels: ["A", "B", "Other"], values: [35, 45, 20]
}], { x: 7, y: 1, w: 5, h: 4, showPercent: true });
```

### 製作更精美的圖表

預設圖表看起來較為過時。套用以下選項以獲得現代且簡潔的外觀：

```javascript
slide.addChart(pres.charts.BAR, chartData, {
  x: 0.5, y: 1, w: 9, h: 4, barDir: "col",

  // 自定義顏色 (匹配你的簡報調色盤)
  chartColors: ["0D9488", "14B8A6", "5EEAD4"],

  // 簡潔的背景
  chartArea: { fill: { color: "FFFFFF" }, roundedCorners: true },

  // 柔和的軸標籤顏色
  catAxisLabelColor: "64748B",
  valAxisLabelColor: "64748B",

  // 微細的格線 (僅數值軸)
  valGridLine: { color: "E2E8F0", size: 0.5 },
  catGridLine: { style: "none" },

  // 長條圖上的數據標籤
  showValue: true,
  dataLabelPosition: "outEnd",
  dataLabelColor: "1E293B",

  // 單一系列時隱藏圖例
  showLegend: false,
});
```

**關鍵樣式選項：**
- `chartColors: [...]` - 系列/區段的十六進位顏色
- `chartArea: { fill, border, roundedCorners }` - 圖表背景
- `catGridLine/valGridLine: { color, style, size }` - 格線 (`style: "none"` 可隱藏)
- `lineSmooth: true` - 平滑曲線（折線圖）
- `legendPos: "r"` - 圖例位置: "b", "t", "l", "r", "tr"

---

## 投影片母片

```javascript
pres.defineSlideMaster({
  title: 'TITLE_SLIDE', background: { color: '283A5E' },
  objects: [{
    placeholder: { options: { name: 'title', type: 'title', x: 1, y: 2, w: 8, h: 2 } }
  }]
});

let titleSlide = pres.addSlide({ masterName: "TITLE_SLIDE" });
titleSlide.addText("我的標題", { placeholder: "title" });
```

---

## 常見陷阱

⚠️ 這些問題會導致檔案損壞、視覺錯誤或輸出異常。請務必避免。

1. **十六進位顏色絕對不要使用 "#"** - 會導致檔案損壞
   ```javascript
   color: "FF0000"      // ✅ 正確
   color: "#FF0000"     // ❌ 錯誤
   ```

2. **絕對不要在十六進位顏色字串中編碼不透明度 (Opacity)** - 8 位元顏色（例如 `"00000020"`）會損壞檔案。請改用 `opacity` 屬性。
   ```javascript
   shadow: { type: "outer", blur: 6, offset: 2, color: "00000020" }          // ❌ 會損壞檔案
   shadow: { type: "outer", blur: 6, offset: 2, color: "000000", opacity: 0.12 }  // ✅ 正確
   ```

3. **使用 `bullet: true`** - 絕對不要使用 Unicode 符號如 "•"（會產生重複項目符號）

4. **陣列項目之間使用 `breakLine: true`** - 否則文字會連在一起

5. **避免在項目符號中使用 `lineSpacing`** - 這會產生過大的間隙；請改用 `paraSpaceAfter`

6. **每份簡報都需要一個新的實體** - 不要重複使用 `pptxgen()` 物件

7. **絕對不要在多次呼叫中重用選項物件 (Option objects)** - PptxGenJS 會原地修改物件（例如將陰影值轉換為 EMU）。在多次呼叫中共享同一個物件會損壞後續的形狀。
   ```javascript
   const shadow = { type: "outer", blur: 6, offset: 2, color: "000000", opacity: 0.15 };
   slide.addShape(pres.shapes.RECTANGLE, { shadow, ... });  // ❌ 第二次呼叫會得到已轉換的值
   slide.addShape(pres.shapes.RECTANGLE, { shadow, ... });

   const makeShadow = () => ({ type: "outer", blur: 6, offset: 2, color: "000000", opacity: 0.15 });
   slide.addShape(pres.shapes.RECTANGLE, { shadow: makeShadow(), ... });  // ✅ 每次呼叫提供新物件
   slide.addShape(pres.shapes.RECTANGLE, { shadow: makeShadow(), ... });
   ```

8. **不要將 `ROUNDED_RECTANGLE` 與強調邊框搭配使用** - 矩形疊加條無法覆蓋圓角。請改用 `RECTANGLE`。
   ```javascript
   // ❌ 錯誤：強調條無法完全覆蓋圓角
   slide.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 1, y: 1, w: 3, h: 1.5, fill: { color: "FFFFFF" } });
   slide.addShape(pres.shapes.RECTANGLE, { x: 1, y: 1, w: 0.08, h: 1.5, fill: { color: "0891B2" } });

   // ✅ 正確：使用 RECTANGLE 獲得整齊的對齊效果
   slide.addShape(pres.shapes.RECTANGLE, { x: 1, y: 1, w: 3, h: 1.5, fill: { color: "FFFFFF" } });
   slide.addShape(pres.shapes.RECTANGLE, { x: 1, y: 1, w: 0.08, h: 1.5, fill: { color: "0891B2" } });
   ```

---

## 快速參考

- **形狀**: RECTANGLE, OVAL, LINE, ROUNDED_RECTANGLE
- **圖表**: BAR, LINE, PIE, DOUGHNUT, SCATTER, BUBBLE, RADAR
- **版面配置**: LAYOUT_16x9 (10"×5.625"), LAYOUT_16x10, LAYOUT_4x3, LAYOUT_WIDE
- **對齊**: "left", "center", "right"
- **圖表數據標籤**: "outEnd", "inEnd", "center"
