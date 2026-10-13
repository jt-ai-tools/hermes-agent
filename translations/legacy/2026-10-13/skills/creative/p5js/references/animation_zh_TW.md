# 動畫 (Animation)

## 以影格為基礎的動畫 (Frame-Based Animation)

### Draw 迴圈

```javascript
function draw() {
  // 預設每秒呼叫約 60 次
  // frameCount — 整數，從 1 開始
  // deltaTime — 自上一影格以來的毫秒數（用於不受影格率影響的運動）
  // millis() — 自程式啟動以來的毫秒數
}
```

### 以時間為基礎 vs 以影格為基礎

```javascript
// 以影格為基礎（速度隨影格率變化）
x += speed;

// 以時間為基礎（無論影格率如何，速度保持一致）
x += speed * (deltaTime / 16.67);  // 標準化至 60fps
```

### 標準化時間

```javascript
// 在 N 秒內從 0 進展到 1
let duration = 5000;  // 5 秒（以毫秒計）
let t = constrain(millis() / duration, 0, 1);

// 循環進度 (0 → 1 → 0 → 1...)
let period = 3000;  // 3 秒循環
let t = (millis() % period) / period;

// 乒乓效果 (0 → 1 → 0 → 1...)
let raw = (millis() % (period * 2)) / period;
let t = raw <= 1 ? raw : 2 - raw;
```

## 緩動函數 (Easing Functions)

### 內建 Lerp

```javascript
// 線性插值 — 平滑但顯得機械化
let x = lerp(startX, endX, t);

// 用於非 0-1 範圍的映射
let y = map(t, 0, 1, startY, endY);
```

### 常見緩動曲線

```javascript
// 緩入 (Ease in)（慢速開始）
function easeInQuad(t) { return t * t; }
function easeInCubic(t) { return t * t * t; }
function easeInExpo(t) { return t === 0 ? 0 : pow(2, 10 * (t - 1)); }

// 緩出 (Ease out)（慢速結束）
function easeOutQuad(t) { return 1 - (1 - t) * (1 - t); }
function easeOutCubic(t) { return 1 - pow(1 - t, 3); }
function easeOutExpo(t) { return t === 1 ? 1 : 1 - pow(2, -10 * t); }

// 緩入緩出 (Ease in-out)（兩端皆慢）
function easeInOutCubic(t) {
  return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
}
function easeInOutQuint(t) {
  return t < 0.5 ? 16 * t * t * t * t * t : 1 - pow(-2 * t + 2, 5) / 2;
}

// 彈性 (Elastic)（彈簧過衝）
function easeOutElastic(t) {
  if (t === 0 || t === 1) return t;
  return pow(2, -10 * t) * sin((t * 10 - 0.75) * (2 * PI / 3)) + 1;
}

// 彈跳 (Bounce)
function easeOutBounce(t) {
  if (t < 1/2.75) return 7.5625 * t * t;
  else if (t < 2/2.75) { t -= 1.5/2.75; return 7.5625 * t * t + 0.75; }
  else if (t < 2.5/2.75) { t -= 2.25/2.75; return 7.5625 * t * t + 0.9375; }
  else { t -= 2.625/2.75; return 7.5625 * t * t + 0.984375; }
}

// 平滑階梯 (Smooth step) (Hermite 插值 — 優質的預設選擇)
function smoothstep(t) { return t * t * (3 - 2 * t); }

// 更平滑階梯 (Smoother step) (Ken Perlin)
function smootherstep(t) { return t * t * t * (t * (t * 6 - 15) + 10); }
```

### 應用緩動

```javascript
// 在 duration 毫秒內，從 startVal 動畫過渡到 endVal
function easedValue(startVal, endVal, startTime, duration, easeFn) {
  let t = constrain((millis() - startTime) / duration, 0, 1);
  return lerp(startVal, endVal, easeFn(t));
}

// 用法
let x = easedValue(100, 700, animStartTime, 2000, easeOutCubic);
```

## 彈簧物理 (Spring Physics)

比緩動更自然 — 會對力做出反應、產生過衝並最終穩定下來。

```javascript
class Spring {
  constructor(value, target, stiffness = 0.1, damping = 0.7) {
    this.value = value;
    this.target = target;
    this.velocity = 0;
    this.stiffness = stiffness;
    this.damping = damping;
  }

  update() {
    let force = (this.target - this.value) * this.stiffness;
    this.velocity += force;
    this.velocity *= this.damping;
    this.value += this.velocity;
    return this.value;
  }

  setTarget(t) { this.target = t; }
  isSettled(threshold = 0.01) {
    return abs(this.velocity) < threshold && abs(this.value - this.target) < threshold;
  }
}

// 用法
let springX = new Spring(0, 0, 0.08, 0.85);
function draw() {
  springX.setTarget(mouseX);
  let x = springX.update();
  ellipse(x, height/2, 50);
}
```

### 2D 彈簧

```javascript
class Spring2D {
  constructor(x, y) {
    this.pos = createVector(x, y);
    this.target = createVector(x, y);
    this.vel = createVector(0, 0);
    this.stiffness = 0.08;
    this.damping = 0.85;
  }

  update() {
    let force = p5.Vector.sub(this.target, this.pos).mult(this.stiffness);
    this.vel.add(force).mult(this.damping);
    this.pos.add(this.vel);
    return this.pos;
  }
}
```

## 狀態機 (State Machines)

用於複雜的多階段動畫。

```javascript
const STATES = { IDLE: 0, ENTER: 1, ACTIVE: 2, EXIT: 3 };
let state = STATES.IDLE;
let stateStart = 0;

function setState(newState) {
  state = newState;
  stateStart = millis();
}

function stateTime() {
  return millis() - stateStart;
}

function draw() {
  switch (state) {
    case STATES.IDLE:
      // 等待中...
      break;
    case STATES.ENTER:
      let t = constrain(stateTime() / 1000, 0, 1);
      let alpha = easeOutCubic(t) * 255;
      // 淡入...
      if (t >= 1) setState(STATES.ACTIVE);
      break;
    case STATES.ACTIVE:
      // 主要動畫...
      break;
    case STATES.EXIT:
      let t2 = constrain(stateTime() / 500, 0, 1);
      // 淡出...
      if (t2 >= 1) setState(STATES.IDLE);
      break;
  }
}
```

## 時間軸排序 (Timeline Sequencing)

用於定時的多場景動畫（動態圖形、標題序列）。

```javascript
class Timeline {
  constructor() {
    this.events = [];
  }

  at(timeMs, duration, fn) {
    this.events.push({ start: timeMs, end: timeMs + duration, fn });
    return this;
  }

  update() {
    let now = millis();
    for (let e of this.events) {
      if (now >= e.start && now < e.end) {
        let t = (now - e.start) / (e.end - e.start);
        e.fn(t);
      }
    }
  }
}

// 用法
let timeline = new Timeline();
timeline
  .at(0, 2000, (t) => {
    // 場景 1：標題淡入 (0-2s)
    let alpha = easeOutCubic(t) * 255;
    fill(255, alpha);
    textSize(48);
    text("Hello", width/2, height/2);
  })
  .at(2000, 1000, (t) => {
    // 場景 2：標題淡出 (2-3s)
    let alpha = (1 - easeInCubic(t)) * 255;
    fill(255, alpha);
    textSize(48);
    text("Hello", width/2, height/2);
  })
  .at(3000, 5000, (t) => {
    // 場景 3：主要內容 (3-8s)
    renderMainContent(t);
  });

function draw() {
  background(0);
  timeline.update();
}
```

## 雜訊驅動的運動 (Noise-Driven Motion)

比確定性動畫更具機體感。

```javascript
// 平滑遊走的座標
let x = map(noise(frameCount * 0.005, 0), 0, 1, 0, width);
let y = map(noise(0, frameCount * 0.005), 0, 1, 0, height);

// 雜訊驅動的旋轉
let angle = noise(frameCount * 0.01) * TWO_PI;

// 雜訊驅動的縮放（呼吸效果）
let s = map(noise(frameCount * 0.02), 0, 1, 0.8, 1.2);

// 雜訊驅動的顏色偏移
let hue = map(noise(frameCount * 0.003), 0, 1, 0, 360);
```

## 轉換模式 (Transition Patterns)

### 淡入 / 淡出 (Fade In/Out)

```javascript
function fadeIn(t) { return constrain(t, 0, 1); }
function fadeOut(t) { return constrain(1 - t, 0, 1); }
```

### 滑動 (Slide)

```javascript
function slideIn(t, direction = 'left') {
  let et = easeOutCubic(t);
  switch (direction) {
    case 'left': return lerp(-width, 0, et);
    case 'right': return lerp(width, 0, et);
    case 'up': return lerp(-height, 0, et);
    case 'down': return lerp(height, 0, et);
  }
}
```

### 縮放揭露 (Scale Reveal)

```javascript
function scaleReveal(t) {
  let et = easeOutElastic(constrain(t, 0, 1));
  push();
  translate(width/2, height/2);
  scale(et);
  translate(-width/2, -height/2);
  // 繪製內容...
  pop();
}
```

### 交錯進入 (Staggered Entry)

```javascript
// N 個元素接連出現
let staggerDelay = 100;  // 每個之間的毫秒間隔
for (let i = 0; i < elements.length; i++) {
  let itemStart = baseTime + i * staggerDelay;
  let t = constrain((millis() - itemStart) / 500, 0, 1);
  let alpha = easeOutCubic(t) * 255;
  let yOffset = lerp(30, 0, easeOutCubic(t));
  // 使用 alpha 和 yOffset 繪製元素
}
```

## 記錄確定性動畫 (Recording Deterministic Animations)

為了完美的影格導出，請使用影格數而非 millis()：

```javascript
const TOTAL_FRAMES = 300;  // 10 秒，30fps
const FPS = 30;

function draw() {
  let t = frameCount / TOTAL_FRAMES;  // 在整個時長內從 0 到 1
  if (t > 1) { noLoop(); return; }

  // 所有動畫時間皆使用 t — 具確定性
  renderFrame(t);

  // 導出
  if (CONFIG.recording) {
    saveCanvas('frame-' + nf(frameCount, 4), 'png');
  }
}
```

## 場景淡入淡出包絡線 (Scene Fade Envelopes)（影片）

多場景影片中的每個場景都需要淡入和淡出。視覺差異顯著的生成式場景之間的硬切會顯得突兀。

```javascript
const SCENE_FRAMES = 150;  // 5 秒，30fps
const FADE = 15;           // 半秒淡入淡出

function draw() {
  let lf = frameCount - 1;  // 從 0 開始的局部影格
  let t = lf / SCENE_FRAMES; // 0..1 標準化進度

  // 淡入淡出包絡線：開始時遞增，結束時遞減
  let fade = 1;
  if (lf < FADE) fade = lf / FADE;
  if (lf > SCENE_FRAMES - FADE) fade = (SCENE_FRAMES - lf) / FADE;
  fade = fade * fade * (3 - 2 * fade);  // 使用 smoothstep 以獲得自然感

  // 將淡入淡出應用於所有視覺輸出
  // 選項 1：將 alpha 值乘以 fade
  fill(r, g, b, alpha * fade);

  // 選項 2：對整個合成圖像進行著色
  tint(255, fade * 255);
  image(sceneBuffer, 0, 0);
  noTint();

  // 選項 3：乘以像素亮度（用於像素級場景）
  pixels[i] = r * fade;
}
```

## 將靜態演算法動畫化 (Animating Static Algorithms)

某些生成式演算法會產生單一靜態結果（如吸引子、圓形填充、Voronoi）。在影片中，靜態內容看起來像被凍結或損壞了。添加運動的技巧如下：

### 漸進式揭露

從中心向外擴展遮罩，以揭露預先計算的結果：

```javascript
let revealRadius = easeOutCubic(min(t * 1.5, 1)) * (width * 0.8);
// 在渲染迴圈中，跳過距離中心超過 revealRadius 的像素
let dx = x - width/2, dy = y - height/2;
if (sqrt(dx*dx + dy*dy) > revealRadius) continue;
// 柔和邊緣：
let edgeFade = constrain((revealRadius - dist) / 40, 0, 1);
```

### 參數掃描

緩慢改變參數以展示演算法的演變：

```javascript
// 參數漂移的吸引子
let a = -1.7 + sin(t * 0.5) * 0.2;  // 在基準值附近擺動
let b = 1.3 + cos(t * 0.3) * 0.15;
```

### 緩慢鏡鏡運動

對最終圖像應用微妙的縮放或旋轉：

```javascript
push();
translate(width/2, height/2);
scale(1 + t * 0.05);       // 在場景時長內緩慢縮放 5%
rotate(t * 0.1);            // 輕微旋轉
translate(-width/2, -height/2);
image(precomputedResult, 0, 0);
pop();
```

### 疊加動態元素

在靜態內容頂部添加粒子、紋理或微妙的雜訊：

```javascript
// 靜態背景
image(staticResult, 0, 0);
// 動態疊加
for (let p of ambientParticles) {
  p.update();
  p.display();  // 緩慢移動的亮點能增添活力
}
```
