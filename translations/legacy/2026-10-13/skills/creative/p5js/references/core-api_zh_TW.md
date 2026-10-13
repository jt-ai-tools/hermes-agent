# 核心 API 參考 (Core API Reference)

## 畫布設定 (Canvas Setup)

### createCanvas()

```javascript
// 2D（預設渲染器）
createCanvas(1920, 1080);

// WebGL（3D、著色器）
createCanvas(1920, 1080, WEBGL);

// 響應式
createCanvas(windowWidth, windowHeight);
```

### 像素密度 (Pixel Density)

高 DPI 顯示器預設以 2 倍渲染。這會使記憶體使用量翻倍，並使效能減半。

```javascript
// 強制 1 倍以確保導出一致性與效能
pixelDensity(1);

// 符合顯示器（預設）— 在 Retina 螢幕上很清晰但開銷較大
pixelDensity(displayDensity());

// 務必在 createCanvas() 之前呼叫
function setup() {
  pixelDensity(1);        // 第一步
  createCanvas(1920, 1080); // 第二步
}
```

進行導出時，請務必使用 `pixelDensity(1)` 並設定精確的目標解析度。切勿依賴裝置縮放來產生最終輸出。

### 響應式調整大小

```javascript
function windowResized() {
  resizeCanvas(windowWidth, windowHeight);
  // 以新尺寸重新建立離屏緩衝區 (Offscreen buffers)
  bgLayer = createGraphics(width, height);
  // 重新初始化任何與尺寸相關的狀態
}
```

## 座標系統 (Coordinate System)

### P2D（預設）
- 原點：左上角 (0, 0)
- X 向右遞增
- Y 向下遞增
- 角度：預設為弧度 (radians)，使用 `angleMode(DEGREES)` 切換

### WEBGL
- 原點：畫布中心
- X 向右遞增，Y 向上遞增，Z 向觀察者遞增
- 若要在 WEBGL 中獲得類似 P2D 的座標：`translate(-width/2, -height/2)`

## Draw 迴圈 (Draw Loop)

```javascript
function preload() {
  // 在 setup 之前載入資源 — 字體、圖片、JSON、CSV
  // 在所有載入完成前會阻塞執行
  font = loadFont('font.otf');
  img = loadImage('texture.png');
  data = loadJSON('data.json');
}

function setup() {
  // 執行一次。建立畫布，初始化狀態。
  createCanvas(1920, 1080);
  colorMode(HSB, 360, 100, 100, 100);
  randomSeed(CONFIG.seed);
  noiseSeed(CONFIG.seed);
}

function draw() {
  // 每一影格執行一次（預設 60fps）。
  // 在 setup() 中設定 frameRate(30) 來更改。
  // 對靜態作品呼叫 noLoop()（僅渲染一次）。
}
```

### 影格控制

```javascript
frameRate(30);           // 設定目標 FPS
noLoop();                // 停止 draw 迴圈（靜態作品）
loop();                  // 重啟 draw 迴圈
redraw();                // 呼叫一次 draw()（手動重新整理）
frameCount              // 自啟動以來的影格數（整數）
deltaTime               // 自上一影格以來的毫秒數（浮點數）
millis()                // 自程式啟動以來的毫秒數
```

## 變換堆疊 (Transform Stack)

所有的變換都是累加的。使用 `push()`/`pop()` 來隔離。

```javascript
push();
  translate(width / 2, height / 2);
  rotate(angle);
  scale(1.5);
  // 在變換後的位置繪製內容
  ellipse(0, 0, 100, 100);
pop();
// 回到原始座標系統
```

### 變換函數

| 函數 (Function) | 效果 (Effect) |
|----------|--------|
| `translate(x, y)` | 移動原點 |
| `rotate(angle)` | 繞原點旋轉（弧度） |
| `scale(s)` / `scale(sx, sy)` | 從原點縮放 |
| `shearX(angle)` | 傾斜 X 軸 |
| `shearY(angle)` | 傾斜 Y 軸 |
| `applyMatrix(a, b, c, d, e, f)` | 任意 2D 仿射變換 |
| `resetMatrix()` | 清除所有變換 |

### 合成模式：繞中心旋轉

```javascript
push();
  translate(cx, cy);       // 將原點移至中心
  rotate(angle);           // 繞該中心旋轉
  translate(-cx, -cy);     // 將原點移回
  // 在原始座標繪製，但繞 (cx, cy) 旋轉
  rect(cx - 50, cy - 50, 100, 100);
pop();
```

## 離屏緩衝區 (Offscreen Buffers) (createGraphics)

離屏緩衝區是獨立的畫布，您可以對其進行繪圖並合成。這對於以下用途至關重要：
- **分層合成** — 背景、中景、前景
- **持久痕跡** — 繪製到緩衝區，使用半透明矩形淡化，永不清除
- **遮罩** — 將遮罩繪製到緩衝區，使用 `image()` 或像素操作應用
- **後處理** — 將場景渲染到緩衝區，應用效果，繪製到主畫布

```javascript
let layer;

function setup() {
  createCanvas(1920, 1080);
  layer = createGraphics(width, height);
}

function draw() {
  // 繪製到離屏緩衝區
  layer.background(0, 10);  // 半透明清除 = 痕跡
  layer.fill(255);
  layer.ellipse(mouseX, mouseY, 20);

  // 合成至主畫布
  image(layer, 0, 0);
}
```

### 痕跡效果模式

```javascript
let trailBuffer;

function setup() {
  createCanvas(1920, 1080);
  trailBuffer = createGraphics(width, height);
  trailBuffer.background(0);
}

function draw() {
  // 淡化前一影格（較低的 alpha 值 = 較長的痕跡）
  trailBuffer.noStroke();
  trailBuffer.fill(0, 0, 0, 15);  // RGBA — 15/255 透明度
  trailBuffer.rect(0, 0, width, height);

  // 繪製新內容
  trailBuffer.fill(255);
  trailBuffer.ellipse(mouseX, mouseY, 10);

  // 顯示
  image(trailBuffer, 0, 0);
}
```

### 多層合成

```javascript
let bgLayer, contentLayer, fxLayer;

function setup() {
  createCanvas(1920, 1080);
  bgLayer = createGraphics(width, height);
  contentLayer = createGraphics(width, height);
  fxLayer = createGraphics(width, height);
}

function draw() {
  // 背景 — 繪製一次或緩慢演變
  renderBackground(bgLayer);

  // 內容 — 主要視覺元素
  contentLayer.clear();
  renderContent(contentLayer);

  // 特效 (FX) — 疊加、暈影、顆粒
  fxLayer.clear();
  renderEffects(fxLayer);

  // 使用混合模式合成
  image(bgLayer, 0, 0);
  blendMode(ADD);
  image(contentLayer, 0, 0);
  blendMode(MULTIPLY);
  image(fxLayer, 0, 0);
  blendMode(BLEND);  // 重設
}
```

## 合成模式 (Composition Patterns)

### 網格佈局

```javascript
let cols = 10, rows = 10;
let cellW = width / cols;
let cellH = height / rows;
for (let i = 0; i < cols; i++) {
  for (let j = 0; j < rows; j++) {
    let cx = cellW * (i + 0.5);
    let cy = cellH * (j + 0.5);
    // 在單元格大小 (cellW, cellH) 內的 (cx, cy) 處繪製元素
  }
}
```

### 放射狀佈局

```javascript
let n = 12;
for (let i = 0; i < n; i++) {
  let angle = TWO_PI * i / n;
  let r = 300;
  let x = width/2 + cos(angle) * r;
  let y = height/2 + sin(angle) * r;
  // 在 (x, y) 處繪製元素
}
```

### 黃金比例螺旋

```javascript
let phi = (1 + sqrt(5)) / 2;
let n = 500;
for (let i = 0; i < n; i++) {
  let angle = i * TWO_PI / (phi * phi);
  let r = sqrt(i) * 10;
  let x = width/2 + cos(angle) * r;
  let y = height/2 + sin(angle) * r;
  let size = map(i, 0, n, 8, 2);
  ellipse(x, y, size);
}
```

### 考量邊距的合成

```javascript
const MARGIN = 80;  // 距邊緣的像素
const drawW = width - 2 * MARGIN;
const drawH = height - 2 * MARGIN;

// 將標準化的 [0,1] 座標映射到可繪製區域
function mapX(t) { return MARGIN + t * drawW; }
function mapY(t) { return MARGIN + t * drawH; }
```

## 隨機與雜訊 (Random and Noise)

### 具種子值的隨機 (Seeded Random)

```javascript
randomSeed(42);
let x = random(100);        // 種子值為 42 時總是得到相同的值
let y = random(-1, 1);      // 範圍
let item = random(myArray);  // 隨機元素
```

### 高斯隨機 (Gaussian Random)

```javascript
let x = randomGaussian(0, 1);  // 平均值=0, 標準差=1
// 用於產生自然的視覺分佈
```

### Perlin 雜訊

```javascript
noiseSeed(42);
noiseDetail(4, 0.5);  // 4 個八度 (octaves)，0.5 衰減

let v = noise(x * 0.01, y * 0.01);  // 傳回 0.0 到 1.0
// 縮放因子 (0.01) 控制特徵大小 — 越小越平滑
```

## 數學工具 (Math Utilities)

| 函數 (Function) | 說明 (Description) |
|----------|-------------|
| `map(v, lo1, hi1, lo2, hi2)` | 在範圍之間重新映射值 |
| `constrain(v, lo, hi)` | 限制在範圍內 |
| `lerp(a, b, t)` | 線性插值 |
| `norm(v, lo, hi)` | 標準化至 0-1 |
| `dist(x1, y1, x2, y2)` | 歐幾里得距離 |
| `mag(x, y)` | 向量長度 (Magnitude) |
| `abs()`, `ceil()`, `floor()`, `round()` | 標準數學函數 |
| `sq(n)`, `sqrt(n)`, `pow(b, e)` | 乘方與開方 |
| `sin()`, `cos()`, `tan()`, `atan2()` | 三角函數（弧度） |
| `degrees(r)`, `radians(d)` | 角度轉換 |
| `fract(n)` | 小數部分 |

## p5.js 2.0 變更

p5.js 2.0（2025 年 4 月發布，目前版本：2.2）引入了重大變更。p5.js 編輯器在 2026 年 8 月之前預設使用 1.x。僅在需要其功能時才使用 2.x。

### async setup() 取代 preload()

```javascript
// p5.js 1.x
let img;
function preload() { img = loadImage('cat.jpg'); }
function setup() { createCanvas(800, 800); }

// p5.js 2.x
let img;
async function setup() {
  createCanvas(800, 800);
  img = await loadImage('cat.jpg');
}
```

### 新色彩模式

```javascript
colorMode(OKLCH);  // 感官均勻 — 漸層效果更好
// L: 0-1 (亮度), C: 0-0.4 (彩度), H: 0-360 (色相)
fill(0.7, 0.15, 200);  // 中等明亮且飽和的藍色

colorMode(OKLAB);  // 感官均勻，無色相角
colorMode(HWB);    // 色相-白度-黑度 (Hue-Whiteness-Blackness)
```

### splineVertex() 取代 curveVertex()

不再需要重複首末控制點：

```javascript
// p5.js 1.x — 必須重複首末點
beginShape();
curveVertex(pts[0].x, pts[0].y);  // 重複
for (let p of pts) curveVertex(p.x, p.y);
curveVertex(pts[pts.length-1].x, pts[pts.length-1].y);  // 重複
endShape();

// p5.js 2.x — 乾淨簡潔
beginShape();
for (let p of pts) splineVertex(p.x, p.y);
endShape();
```

### 著色器 (Shader) .modify() API

修改內建著色器，而無需編寫完整的 GLSL：

```javascript
let myShader = baseMaterialShader().modify({
  vertexDeclarations: 'uniform float uTime;',
  'vec4 getWorldPosition': `(vec4 pos) {
    pos.y += sin(pos.x * 0.1 + uTime) * 20.0;
    return pos;
  }`
});
```

### 可變字體 (Variable Fonts)

```javascript
textWeight(700);  // 動態調整權重，無需載入多個檔案
```

### textToContours() 與 textToModel()

```javascript
let contours = font.textToContours('HELLO', 0, 0, 200);
// 傳回輪廓陣列（封閉路徑）

let geo = font.textToModel('HELLO', 0, 0, 200);
// 為 3D 擠出文字傳回 p5.Geometry
```

### p5.js 2.x 的 CDN

```html
<script src="https://cdn.jsdelivr.net/npm/p5@2/lib/p5.min.js"></script>
```
