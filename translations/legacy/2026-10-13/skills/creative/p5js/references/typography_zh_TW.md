# 排版 (Typography)

## 載入字體 (Loading Fonts)

### 系統字體

```javascript
textFont('Helvetica');
textFont('Georgia');
textFont('monospace');
```

### 自訂字體 (OTF/TTF/WOFF2)

```javascript
let myFont;

function preload() {
  myFont = loadFont('path/to/font.otf');
  // 需要本地伺服器或啟用了 CORS 的 URL
}

function setup() {
  textFont(myFont);
}
```

### 透過 CSS 使用 Google Fonts

```html
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;700&display=swap" rel="stylesheet">
<script>
function setup() {
  textFont('Inter');
}
</script>
```

Google Fonts 無需 `loadFont()` 即可用於 `text()` 繪製，但無法用於 `textToPoints()`。若要製作粒子文字，您需要使用 OTF/TTF 檔案透過 `loadFont()` 載入。

## 文字渲染 (Text Rendering)

### 基本文字

```javascript
textSize(32);
textAlign(CENTER, CENTER);
text('Hello World', width/2, height/2);
```

### 文字屬性

```javascript
textSize(48);                    // 像素大小
textAlign(LEFT, TOP);            // 水平：LEFT, CENTER, RIGHT
                                 // 垂直：TOP, CENTER, BOTTOM, BASELINE
textLeading(40);                 // 行距（用於多行文字）
textStyle(BOLD);                 // NORMAL, BOLD, ITALIC, BOLDITALIC
textWrap(WORD);                  // WORD 或 CHAR（用於帶有最大寬度的 text()）
```

### 文字度量 (Text Metrics)

```javascript
let w = textWidth('Hello');      // 字串的像素寬度
let a = textAscent();            // 基線以上的寬度
let d = textDescent();           // 基線以下的寬度
let totalH = a + d;              // 完整行高
```

### 文字邊界框 (Text Bounding Box)

```javascript
let bounds = myFont.textBounds('Hello', x, y, size);
// bounds = { x, y, w, h }
// 對於定位、碰撞檢測、背景矩形非常有用
```

### 多行文字

```javascript
// 使用最大寬度 — 自動換行
textWrap(WORD);
text('會在給定寬度內自動換行的長文字', x, y, maxWidth);

// 使用最大寬度和高度 — 裁剪
text('非常長的文字', x, y, maxWidth, maxHeight);
```

## textToPoints() — 以粒子呈現文字

將文字輪廓轉換為點陣列。需要透過 `loadFont()` 載入字體檔案 (OTF/TTF)。

```javascript
let font;
let points;

function preload() {
  font = loadFont('font.otf');  // 必須使用 loadFont，而非 CSS
}

function setup() {
  createCanvas(1200, 600);
  points = font.textToPoints('HELLO', 100, 400, 200, {
    sampleFactor: 0.1,  // 越低點數越多（典型值為 0.1-0.5）
    simplifyThreshold: 0
  });
}

function draw() {
  background(0);
  for (let pt of points) {
    let n = noise(pt.x * 0.01, pt.y * 0.01, frameCount * 0.01);
    fill(255, n * 255);
    noStroke();
    ellipse(pt.x + random(-2, 2), pt.y + random(-2, 2), 3);
  }
}
```

### 粒子文字類別 (Particle Text Class)

```javascript
class TextParticle {
  constructor(target) {
    this.target = createVector(target.x, target.y);
    this.pos = createVector(random(width), random(height));
    this.vel = createVector(0, 0);
    this.acc = createVector(0, 0);
    this.maxSpeed = 10;
    this.maxForce = 0.5;
  }

  arrive() {
    let desired = p5.Vector.sub(this.target, this.pos);
    let d = desired.mag();
    let speed = d < 100 ? map(d, 0, 100, 0, this.maxSpeed) : this.maxSpeed;
    desired.setMag(speed);
    let steer = p5.Vector.sub(desired, this.vel);
    steer.limit(this.maxForce);
    this.acc.add(steer);
  }

  flee(target, radius) {
    let d = this.pos.dist(target);
    if (d < radius) {
      let desired = p5.Vector.sub(this.pos, target);
      desired.setMag(this.maxSpeed);
      let steer = p5.Vector.sub(desired, this.vel);
      steer.limit(this.maxForce * 2);
      this.acc.add(steer);
    }
  }

  update() {
    this.vel.add(this.acc);
    this.vel.limit(this.maxSpeed);
    this.pos.add(this.vel);
    this.acc.mult(0);
  }

  display() {
    fill(255);
    noStroke();
    ellipse(this.pos.x, this.pos.y, 3);
  }
}

// 用法：粒子構成文字，並避開滑鼠
let textParticles = [];
for (let pt of points) {
  textParticles.push(new TextParticle(pt));
}

function draw() {
  background(0);
  for (let p of textParticles) {
    p.arrive();
    p.flee(createVector(mouseX, mouseY), 80);
    p.update();
    p.display();
  }
}
```

## 動態排版 (Kinetic Typography)

### 波浪文字 (Wave Text)

```javascript
function waveText(str, x, y, size, amplitude, frequency) {
  textSize(size);
  textAlign(LEFT, BASELINE);
  let xOff = 0;
  for (let i = 0; i < str.length; i++) {
    let yOff = sin(frameCount * 0.05 + i * frequency) * amplitude;
    text(str[i], x + xOff, y + yOff);
    xOff += textWidth(str[i]);
  }
}
```

### 打字機效果 (Typewriter Effect)

```javascript
class Typewriter {
  constructor(str, x, y, speed = 50) {
    this.str = str;
    this.x = x;
    this.y = y;
    this.speed = speed;  // 每個字元的毫秒數
    this.startTime = millis();
    this.cursor = true;
  }

  display() {
    let elapsed = millis() - this.startTime;
    let chars = min(floor(elapsed / this.speed), this.str.length);
    let visible = this.str.substring(0, chars);

    textAlign(LEFT, TOP);
    text(visible, this.x, this.y);

    // 閃爍光標
    if (chars < this.str.length && floor(millis() / 500) % 2 === 0) {
      let cursorX = this.x + textWidth(visible);
      line(cursorX, this.y, cursorX, this.y + textAscent() + textDescent());
    }
  }

  isDone() { return millis() - this.startTime >= this.str.length * this.speed; }
}
```

### 逐字動畫 (Character-by-Character Animation)

```javascript
function animatedText(str, x, y, size, delay = 50) {
  textSize(size);
  textAlign(LEFT, BASELINE);
  let xOff = 0;

  for (let i = 0; i < str.length; i++) {
    let charStart = i * delay;
    let t = constrain((millis() - charStart) / 500, 0, 1);
    let et = easeOutElastic(t);

    push();
    translate(x + xOff, y);
    scale(et);
    let alpha = t * 255;
    fill(255, alpha);
    text(str[i], 0, 0);
    pop();

    xOff += textWidth(str[i]);
  }
}
```

## 以文字作為遮罩 (Text as Mask)

```javascript
let textBuffer;

function setup() {
  createCanvas(800, 800);
  textBuffer = createGraphics(width, height);
  textBuffer.background(0);
  textBuffer.fill(255);
  textBuffer.textSize(200);
  textBuffer.textAlign(CENTER, CENTER);
  textBuffer.text('MASK', width/2, height/2);
}

function draw() {
  // 繪製內容
  background(0);
  // ... 渲染一些色彩繽紛的內容

  // 應用文字遮罩（僅在文字為白色的地方顯示內容）
  loadPixels();
  textBuffer.loadPixels();
  for (let i = 0; i < pixels.length; i += 4) {
    let maskVal = textBuffer.pixels[i];  // 白色 = 顯示，黑色 = 隱藏
    pixels[i + 3] = maskVal;  // 從遮罩設置 alpha (透明度)
  }
  updatePixels();
}
```

## 回應式文字大小 (Responsive Text Sizing)

```javascript
function responsiveTextSize(baseSize, baseWidth = 1920) {
  return baseSize * (width / baseWidth);
}

// 用法
textSize(responsiveTextSize(48));
text('隨畫布縮放', width/2, height/2);
```
