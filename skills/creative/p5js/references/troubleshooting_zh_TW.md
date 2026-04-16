# 疑難排解 (Troubleshooting)

## 效能 (Performance)

### 第 0 步 — 停用 FES

「友善錯誤系統」(Friendly Error System, FES) 會增加巨大的額外開銷 — 可能導致速度變慢高達 10 倍。在每個正式發布的專案中都應停用它：

```javascript
// 在任何 p5 程式碼之前
p5.disableFriendlyErrors = true;

// 或使用 p5.min.js 而非 p5.js — FES 在壓縮版中已被移除
```

### 第 1 步 — pixelDensity(1)

Retina/HiDPI 顯示器預設會使用 2x 或 3x 像素密度，這會使像素總數增加 4 到 9 倍：

```javascript
function setup() {
  pixelDensity(1);        // 強制為 1:1 — 務必先執行此操作
  createCanvas(1920, 1080);
}
```

### 在密集迴圈 (Hot Loops) 中使用 Math.*

p5 的 `sin()`、`cos()`、`random()`、`min()`、`max()`、`abs()` 是包裝過的函數，帶有額外開銷。在密集迴圈（每影格執行數千次迭代）中，請使用原生 `Math.*`：

```javascript
// 慢 — 使用 p5 包裝函數
for (let p of particles) {
  let a = sin(p.angle);
  let d = dist(p.x, p.y, mx, my);
}

// 快 — 使用原生 Math
for (let p of particles) {
  let a = Math.sin(p.angle);
  let dx = p.x - mx, dy = p.y - my;
  let dSq = dx * dx + dy * dy;  // 完全跳過 sqrt (平方根) 計算
}
```

在比較距離時使用 `magSq()` 而非 `mag()` — 可避免昂貴的 `sqrt()` 計算。

### 診斷 (Diagnosis)

開啟 Chrome DevTools > Performance 標籤頁 > 在專案執行時進行錄製 (Record)。

常見效能瓶頸：
1. **啟用了 FES** — 每次 p5 函數呼叫都有 10 倍開銷
2. **pixelDensity > 1** — 4 倍像素量，速度慢 4 倍
3. **繪製呼叫 (draw calls) 過多** — 每影格數千個 `ellipse()`、`rect()`
4. **大畫布 + 像素操作** — 在 4K 畫布上執行 `loadPixels()`/`updatePixels()`
5. **未優化的粒子系統** — 檢查所有粒子間的距離 (O(n^2))
6. **記憶體洩漏 (Memory leaks)** — 每影格建立物件且未清理
7. **著色器編譯** — 在 `draw()` 而非 `setup()` 中呼叫 `createShader()`
8. **在 draw() 中執行 console.log()** — 每影格寫入 DOM，摧毀效能
9. **在 draw() 中操作 DOM** — 版面配置抖動 (比畫布操作慢 400-500 倍)

### 解決方案 (Solutions)

**減少繪製呼叫 (Reduce draw calls)：**
```javascript
// 差：10000 個獨立圓圈
for (let p of particles) {
  ellipse(p.x, p.y, p.size);
}

// 好：使用頂點的單一形狀
beginShape(POINTS);
for (let p of particles) {
  vertex(p.x, p.y);
}
endShape();

// 最好：直接像素操作
loadPixels();
for (let p of particles) {
  let idx = 4 * (floor(p.y) * width + floor(p.x));
  pixels[idx] = p.r;
  pixels[idx+1] = p.g;
  pixels[idx+2] = p.b;
  pixels[idx+3] = 255;
}
updatePixels();
```

**用於鄰居查詢的空間雜湊 (Spatial Hashing)：**
```javascript
class SpatialHash {
  constructor(cellSize) {
    this.cellSize = cellSize;
    this.cells = new Map();
  }

  clear() { this.cells.clear(); }

  _key(x, y) {
    return `${floor(x / this.cellSize)},${floor(y / this.cellSize)}`;
  }

  insert(obj) {
    let key = this._key(obj.pos.x, obj.pos.y);
    if (!this.cells.has(key)) this.cells.set(key, []);
    this.cells.get(key).push(obj);
  }

  query(x, y, radius) {
    let results = [];
    let minCX = floor((x - radius) / this.cellSize);
    let maxCX = floor((x + radius) / this.cellSize);
    let minCY = floor((y - radius) / this.cellSize);
    let maxCY = floor((y + radius) / this.cellSize);

    for (let cx = minCX; cx <= maxCX; cx++) {
      for (let cy = minCY; cy <= maxCY; cy++) {
        let key = `${cx},${cy}`;
        let cell = this.cells.get(key);
        if (cell) {
          for (let obj of cell) {
            if (dist(x, y, obj.pos.x, obj.pos.y) <= radius) {
              results.push(obj);
            }
          }
        }
      }
    }
    return results;
  }
}
```

**物件池 (Object Pooling)：**
```javascript
class ParticlePool {
  constructor(maxSize) {
    this.pool = [];
    this.active = [];
    for (let i = 0; i < maxSize; i++) {
      this.pool.push(new Particle(0, 0));
    }
  }

  spawn(x, y) {
    let p = this.pool.pop();
    if (p) {
      p.reset(x, y);
      this.active.push(p);
    }
  }

  update() {
    for (let i = this.active.length - 1; i >= 0; i--) {
      this.active[i].update();
      if (this.active[i].isDead()) {
        this.pool.push(this.active.splice(i, 1)[0]);
      }
    }
  }
}
```

**調節沉重的操作：**
```javascript
// 每 N 影格才更新一次流場 (Flow field)
if (frameCount % 5 === 0) {
  flowField.update(frameCount * 0.001);
}
```

### 影格率目標 (Frame Rate Targets)

| 情境 | 目標 | 可接受 |
|---------|--------|------------|
| 互動式專案 | 60fps | 30fps |
| 環境動畫 | 30fps | 20fps |
| 導出/錄製 | 30fps 渲染 | 任何速度（離線） |
| 行動裝置 | 30fps | 20fps |

### 每像素渲染預算 (Per-Pixel Rendering Budgets)

像素級別的操作（`loadPixels()` 迴圈）是最昂貴的常見模式。預算取決於畫布大小和每像素的計算量。

| 畫布 | 像素數 | 簡單雜訊 (1 次呼叫) | fBM (4 個倍頻) | 領域扭曲 (3 層 fBM) |
|--------|--------|----------------------|----------------|--------------------------|
| 540x540 | 291K | ~5ms | ~20ms | ~80ms |
| 1080x1080 | 1.17M | ~20ms | ~80ms | ~300ms+ |
| 1920x1080 | 2.07M | ~35ms | ~140ms | ~500ms+ |
| 3840x2160 | 8.3M | ~140ms | ~560ms | 會當機 |

**經驗準則：**
- 1080x1080 每像素 1 次 `noise()` 呼叫 = ~20ms/影格 (30fps OK)
- 1080x1080 每像素 4 倍頻 fBM = ~80ms/影格 (邊緣狀態)
- 1080x1080 多層領域扭曲 (Domain warp) = 300ms+ (即時渲染太慢，適合 `noLoop()` 導出)
- **無頭 Chrome (Headless Chrome) 在像素操作上比桌面版慢 2-5 倍**

**解決方案：以較低解析度渲染，填充區塊：**
```javascript
let step = 3;  // 渲染 1/9 的像素，填充 3x3 區塊
loadPixels();
for (let y = 0; y < H; y += step) {
  for (let x = 0; x < W; x += step) {
    let v = expensiveNoise(x, y);
    for (let dy = 0; dy < step && y+dy < H; dy++)
      for (let dx = 0; dx < step && x+dx < W; dx++) {
        let i = 4 * ((y+dy) * W + (x+dx));
        pixels[i] = v; pixels[i+1] = v; pixels[i+2] = v; pixels[i+3] = 255;
      }
  }
}
updatePixels();
```

Step=2 可提速 4 倍。Step=3 可提速 9 倍。在 1080p 下雖可見，但對於影片來說是可以接受的（運動會掩蓋它）。

## 常見錯誤 (Common Mistakes)

### 1. 忘記重設混合模式 (Blend Mode)

```javascript
blendMode(ADD);
image(glowLayer, 0, 0);
// 錯誤：此後的所有內容都會以 ADD 模式混合
blendMode(BLEND);  // 務必重設
```

### 2. 在 draw() 中建立物件

```javascript
// 差：每影格都建立新的字體物件
function draw() {
  let f = loadFont('font.otf');  // 絕不要在 draw() 中載入
}

// 好：在 preload 中載入，在 draw 中使用
let f;
function preload() { f = loadFont('font.otf'); }
```

### 3. 在變換 (Transforms) 中未使用 push()/pop()

```javascript
// 差：變換會不斷累積
translate(100, 0);
rotate(0.1);
ellipse(0, 0, 50);
// 此後的所有內容也會被移動和旋轉

// 好：隔離變換
push();
translate(100, 0);
rotate(0.1);
ellipse(0, 0, 50);
pop();
```

### 4. 使用整數座標以獲得清晰線條

```javascript
// 模糊：次像素渲染 (Sub-pixel rendering)
line(10.5, 20.3, 100.7, 80.2);

// 清晰：整數 + 0.5 適用於 1px 線條
line(10.5, 20.5, 100.5, 80.5);  // 位於像素邊界上
```

### 5. 像素密度混淆

```javascript
// 錯誤：假設像素陣列與畫布尺寸匹配
loadPixels();
let idx = 4 * (y * width + x);  // 如果 pixelDensity > 1 則錯誤

// 正確：考慮像素密度
let d = pixelDensity();
loadPixels();
let idx = 4 * ((y * d) * (width * d) + (x * d));

// 最簡單：在開始時設置 pixelDensity(1)
```

### 6. 顏色模式混淆

```javascript
// 在 HSB 模式下，fill(255) 不是白色
colorMode(HSB, 360, 100, 100);
fill(255);  // 這是色相=255, 飽和度=100, 亮度=100 = 鮮豔的紫色

// HSB 中的白色：
fill(0, 0, 100);  // 任何色相，0 飽和度，100 亮度

// HSB 中的黑色：
fill(0, 0, 0);
```

### 7. WebGL 原點在中心

```javascript
// 在 WEBGL 模式下，(0,0) 是中心，而非左上角
function draw() {
  // 這會繪製在中心，而非角落
  rect(0, 0, 100, 100);

  // 若要實現左上角行為：
  translate(-width/2, -height/2);
  rect(0, 0, 100, 100);  // 現在位於左上角
}
```

### 8. createGraphics 清理

```javascript
// 差：記憶體洩漏 — 緩衝區未釋放
function draw() {
  let temp = createGraphics(width, height);  // 每影格都建立新緩衝區！
  // ...
}

// 好：建立一次，重複使用
let temp;
function setup() {
  temp = createGraphics(width, height);
}
function draw() {
  temp.clear();
  // ... 重複使用 temp
}

// 如果必須建立/銷毀：
temp.remove();  // 明確釋放
```

### 9. noise() 回傳 0-1，而非 -1 到 1

```javascript
let n = noise(x);  // 0.0 到 1.0 (偏向 0.5)

// 若要實現 -1 到 1 的範圍：
let n = noise(x) * 2 - 1;

// 若要實現特定範圍：
let n = map(noise(x), 0, 1, -100, 100);
```

### 10. 在 draw() 中呼叫 saveCanvas() 會每影格存檔

```javascript
// 差：每一影格都儲存一張 PNG
function draw() {
  // ... 渲染 ...
  saveCanvas('output', 'png');  // 不要這樣做
}

// 好：透過鍵盤儲存一次
function keyPressed() {
  if (key === 's') saveCanvas('output', 'png');
}

// 好：渲染靜態作品後儲存一次
function draw() {
  // ... 渲染 ...
  saveCanvas('output', 'png');
  noLoop();  // 儲存後停止執行
}
```

### 11. 在 draw() 中執行 console.log()

```javascript
// 差：每影格都寫入 DOM 主控台 — 巨大開銷
function draw() {
  console.log(particles.length);  // 每秒 60 次 DOM 寫入
}

// 好：定期或有條件地記錄
function draw() {
  if (frameCount % 60 === 0) console.log('FPS:', frameRate().toFixed(1));
}
```

### 12. 在 draw() 中操作 DOM

```javascript
// 差：版面配置抖動 — 比畫布操作慢 400-500 倍
function draw() {
  document.getElementById('counter').innerText = frameCount;
  let el = document.querySelector('.info');  // 每影格進行一次 DOM 查詢
}

// 好：快取 DOM 引用，降低更新頻率
let counterEl;
function setup() { counterEl = document.getElementById('counter'); }
function draw() {
  if (frameCount % 30 === 0) counterEl.innerText = frameCount;
}
```

### 13. 在正式發布時未停用 FES

```javascript
// 差：每次 p5 函數呼叫都有錯誤檢查開銷（慢上 10 倍）
function setup() { createCanvas(800, 800); }

// 好：在任何 p5 程式碼前停用
p5.disableFriendlyErrors = true;
function setup() { createCanvas(800, 800); }

// 同樣很好：使用 p5.min.js (FES 已從壓縮版中移除)
```

## 瀏覽器相容性 (Browser Compatibility)

### Safari 相關問題
- WebGL 著色器精度：務必宣告 `precision mediump float;`
- `AudioContext` 需要使用者手勢觸發 (`userStartAudio()`)
- 某些 `blendMode()` 選項表現不同

### Firefox 相關問題
- `textToPoints()` 可能回傳略有不同的點數
- WebGL 擴充功能可能與 Chrome 不同
- 色彩設定檔 (Color profile) 處理可能導致色偏

### 行動裝置相關問題
- 觸控事件需要 `return false` 以防止捲動
- `devicePixelRatio` 可能是 2x 或 3x — 為了效能請使用 `pixelDensity(1)`
- 建議使用較小的畫布 (720p 或更小)
- 音訊需要明確的使用者手勢才能啟動

## CORS 問題

```javascript
// 從外部 URL 載入圖像/字體需要 CORS 標頭
// 本地檔案需要伺服器：
// python3 -m http.server 8080

// 或使用 CORS 代理伺服器獲取外部資源（不建議用於正式環境）
```

## 記憶體洩漏 (Memory Leaks)

### 症狀
- 影格率隨時間降低
- 瀏覽器分頁記憶體無限增長
- 頁面在幾分鐘後變得無回應

### 常見原因

```javascript
// 1. 無限增長的陣列
let history = [];
function draw() {
  history.push(someData);  // 永遠增長
}
// 修復：限制陣列大小
if (history.length > 1000) history.shift();

// 2. 在 draw() 中建立 p5 物件
function draw() {
  let v = createVector(0, 0);  // 每影格都分配記憶體
}
// 修復：重複使用預先分配的物件

// 3. 未釋放的圖形緩衝區
let layers = [];
function reset() {
  for (let l of layers) l.remove();  // 釋放舊緩衝區
  layers = [];
}

// 4. 事件監聽器累積
function setup() {
  // 差：每次 setup 執行時都添加新的監聽器
  window.addEventListener('resize', handler);
}
// 修復：使用 p5 內建的 windowResized()
```

## 除錯技巧 (Debugging Tips)

### 主控台記錄 (Console Logging)

```javascript
// 僅記錄一次（非每影格）
if (frameCount === 1) {
  console.log('畫布：', width, 'x', height);
  console.log('像素密度：', pixelDensity());
  console.log('渲染器：', drawingContext.constructor.name);
}

// 定期記錄
if (frameCount % 60 === 0) {
  console.log('FPS:', frameRate().toFixed(1));
  console.log('粒子數：', particles.length);
}
```

### 視覺化除錯 (Visual Debugging)

```javascript
// 顯示影格率
function draw() {
  // ... 你的專案內容 ...
  if (CONFIG.debug) {
    fill(255, 0, 0);
    noStroke();
    textSize(14);
    textAlign(LEFT, TOP);
    text('FPS: ' + frameRate().toFixed(1), 10, 10);
    text('粒子：' + particles.length, 10, 28);
    text('影格：' + frameCount, 10, 46);
  }
}

// 使用 'd' 鍵切換除錯顯示
function keyPressed() {
  if (key === 'd') CONFIG.debug = !CONFIG.debug;
}
```

### 隔離問題 (Isolating Issues)

```javascript
// 註釋掉各層以找出變慢的原因
function draw() {
  renderBackground();      // 註釋掉進行測試
  // renderParticles();    // 這可能很慢
  // renderPostEffects();  // 或者這層
}
```
