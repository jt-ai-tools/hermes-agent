# 視覺效果 (Visual Effects)

## 雜訊 (Noise)

### Perlin 雜訊基礎

```javascript
noiseSeed(42);
noiseDetail(4, 0.5);  // 倍頻 (octaves), 衰減 (falloff)

// 1D 雜訊 — 平滑的起伏
let y = noise(x * 0.01);  // 回傳 0.0 到 1.0

// 2D 雜訊 — 地形 / 紋理
let v = noise(x * 0.005, y * 0.005);

// 3D 雜訊 — 動態 2D 場 (z = 時間)
let v = noise(x * 0.005, y * 0.005, frameCount * 0.005);
```

縮放因子 (0.005 等) 至關重要：
- `0.001` — 非常平滑，特徵巨大
- `0.005` — 平滑，特徵中等
- `0.01` — 標準的生成藝術縮放比例
- `0.05` — 細節豐富，特徵微小
- `0.1` — 接近隨機，具顆粒感

### 分形布朗運動 (Fractal Brownian Motion, fBM)

疊加雜訊倍頻以獲得自然的紋理。每個倍頻都會在更小的尺度上增加細節。

```javascript
function fbm(x, y, octaves = 6, lacunarity = 2.0, gain = 0.5) {
  let value = 0;
  let amplitude = 1.0;
  let frequency = 1.0;
  let maxValue = 0;
  for (let i = 0; i < octaves; i++) {
    value += noise(x * frequency, y * frequency) * amplitude;
    maxValue += amplitude;
    amplitude *= gain;
    frequency *= lacunarity;
  }
  return value / maxValue;
}
```

### 領域扭曲 (Domain Warping)

將雜訊輸出作為輸入座標重新帶入，以產生流動的有機扭曲效果。

```javascript
function domainWarp(x, y, scale, strength, time) {
  // 第一層扭曲
  let qx = fbm(x + 0.0, y + 0.0);
  let qy = fbm(x + 5.2, y + 1.3);

  // 第二層扭曲（帶入前一層結果）
  let rx = fbm(x + strength * qx + 1.7, y + strength * qy + 9.2, 4, 2, 0.5);
  let ry = fbm(x + strength * qx + 8.3, y + strength * qy + 2.8, 4, 2, 0.5);

  return fbm(x + strength * rx + time, y + strength * ry + time);
}
```

### 旋度雜訊 (Curl Noise)

無散度的雜訊場。遵循旋度雜訊的粒子永遠不會聚集或分散 — 它們以平滑且漩渦狀的模式流動。

```javascript
function curlNoise(x, y, scale, time) {
  let eps = 0.001;
  // 透過有限差分求偏導數
  let dndx = (noise(x * scale + eps, y * scale, time) -
              noise(x * scale - eps, y * scale, time)) / (2 * eps);
  let dndy = (noise(x * scale, y * scale + eps, time) -
              noise(x * scale, y * scale - eps, time)) / (2 * eps);
  // 旋度 = 與梯度垂直
  return createVector(dndy, -dndx);
}
```

## 流場 (Flow Fields)

引導粒子運動的向量網格。這是生成藝術的基礎技術。

```javascript
class FlowField {
  constructor(resolution, noiseScale) {
    this.resolution = resolution;
    this.cols = ceil(width / resolution);
    this.rows = ceil(height / resolution);
    this.field = new Array(this.cols * this.rows);
    this.noiseScale = noiseScale;
  }

  update(time) {
    for (let i = 0; i < this.cols; i++) {
      for (let j = 0; j < this.rows; j++) {
        let angle = noise(i * this.noiseScale, j * this.noiseScale, time) * TWO_PI * 2;
        this.field[i + j * this.cols] = p5.Vector.fromAngle(angle);
      }
    }
  }

  lookup(x, y) {
    let col = constrain(floor(x / this.resolution), 0, this.cols - 1);
    let row = constrain(floor(y / this.resolution), 0, this.rows - 1);
    return this.field[col + row * this.cols].copy();
  }
}
```

### 流場粒子

```javascript
class FlowParticle {
  constructor(x, y) {
    this.pos = createVector(x, y);
    this.vel = createVector(0, 0);
    this.acc = createVector(0, 0);
    this.prev = this.pos.copy();
    this.maxSpeed = 2;
    this.life = 1.0;
  }

  follow(field) {
    let force = field.lookup(this.pos.x, this.pos.y);
    force.mult(0.5);  // 力量強度
    this.acc.add(force);
  }

  update() {
    this.prev = this.pos.copy();
    this.vel.add(this.acc);
    this.vel.limit(this.maxSpeed);
    this.pos.add(this.vel);
    this.acc.mult(0);
    this.life -= 0.001;
  }

  edges() {
    if (this.pos.x > width) this.pos.x = 0;
    if (this.pos.x < 0) this.pos.x = width;
    if (this.pos.y > height) this.pos.y = 0;
    if (this.pos.y < 0) this.pos.y = height;
    this.prev = this.pos.copy();  // 防止出現跨越螢幕的連線
  }

  display(buffer) {
    buffer.stroke(255, this.life * 30);
    buffer.strokeWeight(0.5);
    buffer.line(this.prev.x, this.prev.y, this.pos.x, this.pos.y);
  }
}
```

## 粒子系統 (Particle Systems)

### 基礎物理粒子

```javascript
class Particle {
  constructor(x, y) {
    this.pos = createVector(x, y);
    this.vel = p5.Vector.random2D().mult(random(1, 3));
    this.acc = createVector(0, 0);
    this.life = 255;
    this.decay = random(1, 5);
    this.size = random(3, 8);
  }

  applyForce(f) { this.acc.add(f); }

  update() {
    this.vel.add(this.acc);
    this.pos.add(this.vel);
    this.acc.mult(0);
    this.life -= this.decay;
  }

  display() {
    noStroke();
    fill(255, this.life);
    ellipse(this.pos.x, this.pos.y, this.size);
  }

  isDead() { return this.life <= 0; }
}
```

### 吸引子驅動粒子 (Attractor-Driven Particles)

```javascript
class Attractor {
  constructor(x, y, strength) {
    this.pos = createVector(x, y);
    this.strength = strength;
  }

  attract(particle) {
    let force = p5.Vector.sub(this.pos, particle.pos);
    let d = constrain(force.mag(), 5, 200);
    force.normalize();
    force.mult(this.strength / (d * d));
    particle.applyForce(force);
  }
}
```

### 類鳥群群聚 (Boid Flocking)

```javascript
class Boid {
  constructor(x, y) {
    this.pos = createVector(x, y);
    this.vel = p5.Vector.random2D().mult(random(2, 4));
    this.acc = createVector(0, 0);
    this.maxForce = 0.2;
    this.maxSpeed = 4;
    this.perceptionRadius = 50;
  }

  flock(boids) {
    let alignment = createVector(0, 0);  // 隊列
    let cohesion = createVector(0, 0);   // 凝聚
    let separation = createVector(0, 0); // 分離
    let total = 0;

    for (let other of boids) {
      let d = this.pos.dist(other.pos);
      if (other !== this && d < this.perceptionRadius) {
        alignment.add(other.vel);
        cohesion.add(other.pos);
        let diff = p5.Vector.sub(this.pos, other.pos);
        diff.div(d * d);
        separation.add(diff);
        total++;
      }
    }
    if (total > 0) {
      alignment.div(total).setMag(this.maxSpeed).sub(this.vel).limit(this.maxForce);
      cohesion.div(total).sub(this.pos).setMag(this.maxSpeed).sub(this.vel).limit(this.maxForce);
      separation.div(total).setMag(this.maxSpeed).sub(this.vel).limit(this.maxForce);
    }

    this.acc.add(alignment.mult(1.0));
    this.acc.add(cohesion.mult(1.0));
    this.acc.add(separation.mult(1.5));
  }

  update() {
    this.vel.add(this.acc);
    this.vel.limit(this.maxSpeed);
    this.pos.add(this.vel);
    this.acc.mult(0);
  }
}
```

## 像素操作 (Pixel Manipulation)

### 讀取與寫入像素

```javascript
loadPixels();
for (let y = 0; y < height; y++) {
  for (let x = 0; x < width; x++) {
    let idx = 4 * (y * width + x);
    let r = pixels[idx];
    let g = pixels[idx + 1];
    let b = pixels[idx + 2];
    let a = pixels[idx + 3];

    // 修改
    pixels[idx] = 255 - r;       // 反轉紅色
    pixels[idx + 1] = 255 - g;   // 反轉綠色
    pixels[idx + 2] = 255 - b;   // 反轉藍色
  }
}
updatePixels();
```

### 像素級雜訊紋理

```javascript
loadPixels();
for (let i = 0; i < pixels.length; i += 4) {
  let x = (i / 4) % width;
  let y = floor((i / 4) / width);
  let n = noise(x * 0.01, y * 0.01, frameCount * 0.02);
  let c = n * 255;
  pixels[i] = c;
  pixels[i + 1] = c;
  pixels[i + 2] = c;
  pixels[i + 3] = 255;
}
updatePixels();
```

### 內建濾鏡 (Built-in Filters)

```javascript
filter(BLUR, 3);        // 高斯模糊 (半徑)
filter(THRESHOLD, 0.5); // 黑白閾值
filter(INVERT);          // 顏色反轉
filter(POSTERIZE, 4);    // 減少顏色階層（色調分離）
filter(GRAY);            // 去飽和度（灰階）
filter(ERODE);           // 侵蝕亮部區域
filter(DILATE);          // 擴張亮部區域
filter(OPAQUE);          // 移除透明度
```

## 紋理生成 (Texture Generation)

### 點描法 (Stippling / Pointillism)

```javascript
function stipple(buffer, density, minSize, maxSize) {
  buffer.loadPixels();
  for (let i = 0; i < density; i++) {
    let x = floor(random(width));
    let y = floor(random(height));
    let idx = 4 * (y * width + x);
    let brightness = (buffer.pixels[idx] + buffer.pixels[idx+1] + buffer.pixels[idx+2]) / 3;
    let size = map(brightness, 0, 255, maxSize, minSize);
    if (random() < map(brightness, 0, 255, 0.8, 0.1)) {
      noStroke();
      fill(buffer.pixels[idx], buffer.pixels[idx+1], buffer.pixels[idx+2]);
      ellipse(x, y, size);
    }
  }
}
```

### 半色調 (Halftone)

```javascript
function halftone(sourceBuffer, dotSpacing, maxDotSize) {
  sourceBuffer.loadPixels();
  background(255);
  fill(0);
  noStroke();
  for (let y = 0; y < height; y += dotSpacing) {
    for (let x = 0; x < width; x += dotSpacing) {
      let idx = 4 * (y * width + x);
      let brightness = (sourceBuffer.pixels[idx] + sourceBuffer.pixels[idx+1] + sourceBuffer.pixels[idx+2]) / 3;
      let dotSize = map(brightness, 0, 255, maxDotSize, 0);
      ellipse(x + dotSpacing/2, y + dotSpacing/2, dotSize);
    }
  }
}
```

### 交叉影線 (Cross-Hatching)

```javascript
function crossHatch(x, y, w, h, value, spacing) {
  // value: 0 (暗) 到 1 (亮)
  let numLayers = floor(map(value, 0, 1, 4, 0));
  let angles = [PI/4, -PI/4, 0, PI/2];

  for (let layer = 0; layer < numLayers; layer++) {
    push();
    translate(x + w/2, y + h/2);
    rotate(angles[layer]);
    let s = spacing + layer * 2;
    for (let i = -max(w, h); i < max(w, h); i += s) {
      line(i, -max(w, h), i, max(w, h));
    }
    pop();
  }
}
```

## 反饋迴圈 (Feedback Loops)

### 影格反饋（回聲 / 殘影） (Frame Feedback)

```javascript
let feedback;

function setup() {
  createCanvas(800, 800);
  feedback = createGraphics(width, height);
}

function draw() {
  // 複製當前的反饋圖層，並稍微縮放與旋轉
  let temp = feedback.get();

  feedback.push();
  feedback.translate(width/2, height/2);
  feedback.scale(1.005);  // 緩慢縮放
  feedback.rotate(0.002); // 緩慢旋轉
  feedback.translate(-width/2, -height/2);
  feedback.tint(255, 245);  // 輕微淡出
  feedback.image(temp, 0, 0);
  feedback.pop();

  // 將新內容繪製到反饋圖層
  feedback.noStroke();
  feedback.fill(255);
  feedback.ellipse(mouseX, mouseY, 20);

  // 顯示
  image(feedback, 0, 0);
}
```

### 綻光 / 發光（後製處理） (Bloom / Glow)

將場景降取樣至較小的緩衝區，對其進行模糊處理，然後以加法模式疊加。這會在明亮區域周圍產生柔和的光暈。這是生成藝術中標準的綻光技術。

```javascript
let scene, bloomBuf;

function setup() {
  createCanvas(1080, 1080);
  scene = createGraphics(width, height);
  bloomBuf = createGraphics(width, height);
}

function draw() {
  // 1. 將場景渲染至離屏緩衝區 (Offscreen buffer)
  scene.background(0);
  scene.fill(255, 200, 100);
  scene.noStroke();
  // ... 在場景中繪製明亮元素 ...

  // 2. 建立綻光：降取樣 → 模糊 → 升取樣
  bloomBuf.clear();
  bloomBuf.image(scene, 0, 0, width / 4, height / 4);  // 4 倍降取樣
  bloomBuf.filter(BLUR, 6);  // 模糊縮小版圖層

  // 3. 合成：場景 + 加法綻光
  background(0);
  image(scene, 0, 0);           // 基礎層
  blendMode(ADD);               // 加法 = 發光
  tint(255, 80);                // 控制綻光強度 (0-255)
  image(bloomBuf, 0, 0, width, height);  // 升取樣回原始大小
  noTint();
  blendMode(BLEND);             // 務必重設混合模式
}
```

**調整參數：**
- 降取樣比例（預設 1/4，1/8 更柔和，1/2 更紮實）
- 模糊半徑（典型值 4-8，越高光暈越寬）
- Tint alpha (40-120，控制發光強度)
- 每 N 影格更新一次綻光以節省效能：`if (frameCount % 2 === 0) { ... }`

**常見錯誤：** 在 ADD 通道後忘記執行 `blendMode(BLEND)` — 之後繪製的所有內容都會變成加法混合。

### 殘影緩衝區亮度 (Trail Buffer Brightness)

透過 `createGraphics()` + 半透明淡出矩形實現殘影累積是粒子軌跡的標準技術，但 **殘影往往比預期的要暗**。淡出矩形的 alpha 值每影格都會以乘法形式複合。

```javascript
// 淡出矩形的 alpha 值控制殘影長度與亮度：
trailBuf.fill(0, 0, 0, alpha);
trailBuf.rect(0, 0, width, height);

// alpha=5  → 殘影極長，且非常暗（內容在約 35 影格內淡出至 50%）
// alpha=10 → 殘影長，較暗
// alpha=20 → 殘影中等，清晰可見
// alpha=40 → 殘影短，較亮
// alpha=80 → 殘影極短，清晰俐落
```

**陷阱：** 您為了長殘影設定了 alpha=5，但 alpha=30 的粒子筆觸卻不見了，因為它們在累積足夠密度前就已淡出。解決方法：
- **提高筆觸 alpha** 至 80-150（而非直覺的 20-40）
- **降低淡出 alpha**，但接受較短的殘影
- **對筆觸使用加法混合 (ADD)**：明亮的粒子會累積，暗的則保持黑暗

```javascript
// 錯誤：低淡出 + 低筆觸 = 內容消失
trailBuf.fill(0, 0, 0, 5);     // 長殘影
trailBuf.rect(0, 0, W, H);
trailBuf.stroke(255, 30);       // 太暗而無法累積
trailBuf.line(px, py, x, y);

// 正確：低淡出 + 高筆觸 = 可見的長殘影
trailBuf.fill(0, 0, 0, 5);
trailBuf.rect(0, 0, W, H);
trailBuf.stroke(255, 100);      // 足夠明亮，能在淡出中持久存在
trailBuf.line(px, py, x, y);
```

### 反應-擴散 (Reaction-Diffusion) (Gray-Scott)

```javascript
class ReactionDiffusion {
  constructor(w, h) {
    this.w = w;
    this.h = h;
    this.a = new Float32Array(w * h).fill(1);
    this.b = new Float32Array(w * h).fill(0);
    this.nextA = new Float32Array(w * h);
    this.nextB = new Float32Array(w * h);
    this.dA = 1.0;
    this.dB = 0.5;
    this.feed = 0.055;
    this.kill = 0.062;
  }

  seed(cx, cy, r) {
    for (let y = cy - r; y < cy + r; y++) {
      for (let x = cx - r; x < cx + r; x++) {
        if (dist(x, y, cx, cy) < r) {
          let idx = y * this.w + x;
          this.b[idx] = 1;
        }
      }
    }
  }

  step() {
    for (let y = 1; y < this.h - 1; y++) {
      for (let x = 1; x < this.w - 1; x++) {
        let idx = y * this.w + x;
        let a = this.a[idx], b = this.b[idx];
        let lapA = this.laplacian(this.a, x, y);
        let lapB = this.laplacian(this.b, x, y);
        let abb = a * b * b;
        this.nextA[idx] = constrain(a + this.dA * lapA - abb + this.feed * (1 - a), 0, 1);
        this.nextB[idx] = constrain(b + this.dB * lapB + abb - (this.kill + this.feed) * b, 0, 1);
      }
    }
    [this.a, this.nextA] = [this.nextA, this.a];
    [this.b, this.nextB] = [this.nextB, this.b];
  }

  laplacian(arr, x, y) {
    let w = this.w;
    return arr[(y-1)*w+x] + arr[(y+1)*w+x] + arr[y*w+(x-1)] + arr[y*w+(x+1)]
           - 4 * arr[y*w+x];
  }
}
```

## 像素排序 (Pixel Sorting)

```javascript
function pixelSort(buffer, threshold, direction = 'horizontal') {
  buffer.loadPixels();
  let px = buffer.pixels;

  if (direction === 'horizontal') {
    for (let y = 0; y < height; y++) {
      let spans = findSpans(px, y, width, threshold, true);
      for (let span of spans) {
        sortSpan(px, span.start, span.end, y, true);
      }
    }
  }
  buffer.updatePixels();
}

function findSpans(px, row, w, threshold, horizontal) {
  let spans = [];
  let start = -1;
  for (let i = 0; i < w; i++) {
    let idx = horizontal ? 4 * (row * w + i) : 4 * (i * w + row);
    let brightness = (px[idx] + px[idx+1] + px[idx+2]) / 3;
    if (brightness > threshold && start === -1) {
      start = i;
    } else if (brightness <= threshold && start !== -1) {
      spans.push({ start, end: i });
      start = -1;
    }
  }
  if (start !== -1) spans.push({ start, end: w });
  return spans;
}
```

## 進階生成技術 (Advanced Generative Techniques)

### L-系統 (Lindenmayer Systems)

基於文法 (Grammar) 的遞迴生長技術，用於樹木、植物、分形。

```javascript
class LSystem {
  constructor(axiom, rules) {
    this.axiom = axiom;
    this.rules = rules;  // 例如 { 'F': 'F[+F]F[-F]F' }
    this.sentence = axiom;
  }

  generate(iterations) {
    for (let i = 0; i < iterations; i++) {
      let next = '';
      for (let ch of this.sentence) {
        next += this.rules[ch] || ch;
      }
      this.sentence = next;
    }
  }

  draw(len, angle) {
    for (let ch of this.sentence) {
      switch (ch) {
        case 'F': line(0, 0, 0, -len); translate(0, -len); break;
        case '+': rotate(angle); break;
        case '-': rotate(-angle); break;
        case '[': push(); break;
        case ']': pop(); break;
      }
    }
  }
}

// 用法：分形植物
let lsys = new LSystem('X', {
  'X': 'F+[[X]-X]-F[-FX]+X',
  'F': 'FF'
});
lsys.generate(5);
translate(width/2, height);
lsys.draw(4, radians(25));
```

### 圓形填充 (Circle Packing)

用互不重疊且大小各異的圓形填充空間。

```javascript
class PackedCircle {
  constructor(x, y, r) {
    this.x = x; this.y = y; this.r = r;
    this.growing = true;
  }

  grow() { if (this.growing) this.r += 0.5; }

  overlaps(other) {
    let d = dist(this.x, this.y, other.x, other.y);
    return d < this.r + other.r + 2;  // +2 為間隔
  }

  atEdge() {
    return this.x - this.r < 0 || this.x + this.r > width ||
           this.y - this.r < 0 || this.y + this.r > height;
  }
}

let circles = [];

function packStep() {
  // 嘗試放置新圓圈
  for (let attempts = 0; attempts < 100; attempts++) {
    let x = random(width), y = random(height);
    let valid = true;
    for (let c of circles) {
      if (dist(x, y, c.x, c.y) < c.r + 2) { valid = false; break; }
    }
    if (valid) { circles.push(new PackedCircle(x, y, 1)); break; }
  }

  // 讓既有圓圈生長
  for (let c of circles) {
    if (!c.growing) continue;
    c.grow();
    if (c.atEdge()) { c.growing = false; continue; }
    for (let other of circles) {
      if (c !== other && c.overlaps(other)) { c.growing = false; break; }
    }
  }
}
```

### Voronoi 圖 (Fortune 演算法近似實現)

```javascript
// 簡單的暴力破解 Voronoi（適用於點數較少的情況）
function drawVoronoi(points, colors) {
  loadPixels();
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      let minDist = Infinity;
      let closest = 0;
      for (let i = 0; i < points.length; i++) {
        let d = (x - points[i].x) ** 2 + (y - points[i].y) ** 2;  // magSq (量值平方)
        if (d < minDist) { minDist = d; closest = i; }
      }
      let idx = 4 * (y * width + x);
      let c = colors[closest % colors.length];
      pixels[idx] = red(c);
      pixels[idx+1] = green(c);
      pixels[idx+2] = blue(c);
      pixels[idx+3] = 255;
    }
  }
  updatePixels();
}
```

### 分形樹 (Fractal Trees)

```javascript
function fractalTree(x, y, len, angle, depth, branchAngle) {
  if (depth <= 0 || len < 2) return;

  let x2 = x + Math.cos(angle) * len;
  let y2 = y + Math.sin(angle) * len;

  strokeWeight(map(depth, 0, 10, 0.5, 4));
  line(x, y, x2, y2);

  let shrink = 0.67 + noise(x * 0.01, y * 0.01) * 0.15;
  fractalTree(x2, y2, len * shrink, angle - branchAngle, depth - 1, branchAngle);
  fractalTree(x2, y2, len * shrink, angle + branchAngle, depth - 1, branchAngle);
}

// 用法
fractalTree(width/2, height, 120, -HALF_PI, 10, PI/6);
```

### 奇異吸引子 (Strange Attractors)

```javascript
// Clifford 吸引子
function cliffordAttractor(a, b, c, d, iterations) {
  let x = 0, y = 0;
  beginShape(POINTS);
  for (let i = 0; i < iterations; i++) {
    let nx = Math.sin(a * y) + c * Math.cos(a * x);
    let ny = Math.sin(b * x) + d * Math.cos(b * y);
    x = nx; y = ny;
    let px = map(x, -3, 3, 0, width);
    let py = map(y, -3, 3, 0, height);
    vertex(px, py);
  }
  endShape();
}

// De Jong 吸引子
function deJongAttractor(a, b, c, d, iterations) {
  let x = 0, y = 0;
  beginShape(POINTS);
  for (let i = 0; i < iterations; i++) {
    let nx = Math.sin(a * y) - Math.cos(b * x);
    let ny = Math.sin(c * x) - Math.cos(d * y);
    x = nx; y = ny;
    let px = map(x, -2.5, 2.5, 0, width);
    let py = map(y, -2.5, 2.5, 0, height);
    vertex(px, py);
  }
  endShape();
}
```

### 泊松盤取樣 (Poisson Disk Sampling)

均勻且看起來自然的分布 — 比純隨機更適合放置元素。

```javascript
function poissonDiskSampling(r, k = 30) {
  let cellSize = r / Math.sqrt(2);
  let cols = Math.ceil(width / cellSize);
  let rows = Math.ceil(height / cellSize);
  let grid = new Array(cols * rows).fill(-1);
  let points = [];
  let active = [];

  function gridIndex(x, y) {
    return Math.floor(x / cellSize) + Math.floor(y / cellSize) * cols;
  }

  // 種子
  let p0 = createVector(random(width), random(height));
  points.push(p0);
  active.push(p0);
  grid[gridIndex(p0.x, p0.y)] = 0;

  while (active.length > 0) {
    let idx = Math.floor(Math.random() * active.length);
    let pos = active[idx];
    let found = false;

    for (let n = 0; n < k; n++) {
      let angle = Math.random() * TWO_PI;
      let mag = r + Math.random() * r;
      let sample = createVector(pos.x + Math.cos(angle) * mag, pos.y + Math.sin(angle) * mag);

      if (sample.x < 0 || sample.x >= width || sample.y < 0 || sample.y >= height) continue;

      let col = Math.floor(sample.x / cellSize);
      let row = Math.floor(sample.y / cellSize);
      let ok = true;

      for (let dy = -2; dy <= 2; dy++) {
        for (let dx = -2; dx <= 2; dx++) {
          let nc = col + dx, nr = row + dy;
          if (nc >= 0 && nc < cols && nr >= 0 && nr < rows) {
            let gi = nc + nr * cols;
            if (grid[gi] !== -1 && points[grid[gi]].dist(sample) < r) { ok = false; }
          }
        }
      }

      if (ok) {
        points.push(sample);
        active.push(sample);
        grid[gridIndex(sample.x, sample.y)] = points.length - 1;
        found = true;
        break;
      }
    }
    if (!found) active.splice(idx, 1);
  }
  return points;
}
```

## 附加函式庫 (Addon Libraries)

### p5.brush — 自然介質 (Natural Media)

手繪、有機的美學效果。包含水彩、木炭、筆、麥克筆等。需要 **p5.js 2.x + WEBGL**。

```html
<script src="https://cdn.jsdelivr.net/npm/p5.brush@latest/dist/p5.brush.js"></script>
```

```javascript
function setup() {
  createCanvas(1200, 1200, WEBGL);
  brush.scaleBrushes(3);  // 對於正確的尺寸至關重要
  translate(-width/2, -height/2);  // WEBGL 的原點在中心
  brush.pick('2B');  // 鉛筆刷
  brush.stroke(50, 50, 50);
  brush.strokeWeight(2);
  brush.line(100, 100, 500, 500);
  brush.pick('watercolor');
  brush.fill('#4a90d9', 150);
  brush.circle(400, 400, 200);
}
```

內建筆刷：`2B`, `HB`, `2H`, `cpencil`, `pen`, `rotring`, `spray`, `marker`, `charcoal`, `hatch_brush`。
內建向量場：`hand`, `curved`, `zigzag`, `waves`, `seabed`, `spiral`, `columns`。

### p5.grain — 電影顆粒與紋理 (Film Grain & Texture)

```html
<script src="https://cdn.jsdelivr.net/npm/p5.grain@0.7.0/p5.grain.min.js"></script>
```

```javascript
function draw() {
  // ... 渲染場景 ...
  applyMonochromaticGrain(42);   // 均勻顆粒
  // 或：applyChromaticGrain(42); // 各通道隨機化
}
```

### CCapture.js — 確定性影片錄製 (Deterministic Video Capture)

無論實際渲染速度如何，皆以固定的影格率記錄畫布。對於複雜的生成藝術至關重要。

```html
<script src="https://cdn.jsdelivr.net/npm/ccapture.js-npmfixed/build/CCapture.all.min.js"></script>
```

```javascript
let capturer;

function setup() {
  createCanvas(1920, 1080);
  capturer = new CCapture({
    format: 'webm',
    framerate: 60,
    quality: 99,
    // timeLimit: 10,    // N 秒後自動停止
    // motionBlurFrames: 4  // 超取樣動態模糊 (Supersampled motion blur)
  });
}

function startRecording() {
  capturer.start();
}

function draw() {
  // ... 渲染影格 ...
  if (capturer) capturer.capture(document.querySelector('canvas'));
}

function stopRecording() {
  capturer.stop();
  capturer.save();  // 觸發下載
}
```
