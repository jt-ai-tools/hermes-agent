# 互動 (Interaction)

## 滑鼠事件 (Mouse Events)

### 持續狀態 (Continuous State)

```javascript
mouseX, mouseY          // 當前位置（相對於畫布）
pmouseX, pmouseY        // 前一影格位置
mouseIsPressed          // 布林值，滑鼠是否按下
mouseButton             // LEFT, RIGHT, CENTER（按下期間）
movedX, movedY          // 自前一影格起的位移量
winMouseX, winMouseY    // 相對於視窗（而非畫布）
```

### 事件回呼 (Event Callbacks)

```javascript
function mousePressed() {
  // 按下時觸發一次
  // 可透過 mouseButton 得知按下哪個鍵
}

function mouseReleased() {
  // 放開時觸發一次
}

function mouseClicked() {
  // 按下並放開後觸發（在同一元素上）
}

function doubleClicked() {
  // 雙擊時觸發
}

function mouseMoved() {
  // 滑鼠移動時觸發（未按下按鍵）
}

function mouseDragged() {
  // 按住按鍵並移動滑鼠時觸發
}

function mouseWheel(event) {
  // event.delta：正值 = 向下捲動，負值 = 向上捲動
  zoom += event.delta * -0.01;
  return false;  // 防止頁面捲動
}
```

### 滑鼠互動模式

**點擊時生成：**
```javascript
function mousePressed() {
  particles.push(new Particle(mouseX, mouseY));
}
```

**帶彈簧效果的滑鼠跟隨：**
```javascript
let springX, springY;
function setup() {
  springX = new Spring(width/2, width/2);
  springY = new Spring(height/2, height/2);
}
function draw() {
  springX.setTarget(mouseX);
  springY.setTarget(mouseY);
  let x = springX.update();
  let y = springY.update();
  ellipse(x, y, 50);
}
```

**拖曳互動 (Drag interaction)：**
```javascript
let dragging = false;
let dragObj = null;
let offsetX, offsetY;

function mousePressed() {
  for (let obj of objects) {
    if (dist(mouseX, mouseY, obj.x, obj.y) < obj.radius) {
      dragging = true;
      dragObj = obj;
      offsetX = mouseX - obj.x;
      offsetY = mouseY - obj.y;
      break;
    }
  }
}

function mouseDragged() {
  if (dragging && dragObj) {
    dragObj.x = mouseX - offsetX;
    dragObj.y = mouseY - offsetY;
  }
}

function mouseReleased() {
  dragging = false;
  dragObj = null;
}
```

**滑鼠排斥（粒子避開游標）：**
```javascript
function draw() {
  let mousePos = createVector(mouseX, mouseY);
  for (let p of particles) {
    let d = p.pos.dist(mousePos);
    if (d < 150) {
      let repel = p5.Vector.sub(p.pos, mousePos);
      repel.normalize();
      repel.mult(map(d, 0, 150, 5, 0));
      p.applyForce(repel);
    }
  }
}
```

## 鍵盤事件 (Keyboard Events)

### 狀態

```javascript
keyIsPressed         // 布林值，是否有鍵被按下
key                  // 最近一次按下的鍵（字串，如 'a', 'A', ' '）
keyCode              // 數字代碼（LEFT_ARROW, UP_ARROW 等）
```

### 事件回呼 (Event Callbacks)

```javascript
function keyPressed() {
  // 按下時觸發一次
  if (keyCode === LEFT_ARROW) { /* ... */ }
  if (key === 's') saveCanvas('output', 'png');
  if (key === ' ') CONFIG.paused = !CONFIG.paused;
  return false;  // 防止瀏覽器預設行為
}

function keyReleased() {
  // 放開時觸發一次
}

function keyTyped() {
  // 僅針對可列印字元觸發（不含箭頭鍵、Shift 等）
}
```

### 持續按鍵狀態（多鍵同時按下）

```javascript
let keys = {};

function keyPressed() { keys[keyCode] = true; }
function keyReleased() { keys[keyCode] = false; }

function draw() {
  if (keys[LEFT_ARROW]) player.x -= 5;
  if (keys[RIGHT_ARROW]) player.x += 5;
  if (keys[UP_ARROW]) player.y -= 5;
  if (keys[DOWN_ARROW]) player.y += 5;
}
```

### 按鍵常數

```
LEFT_ARROW, RIGHT_ARROW, UP_ARROW, DOWN_ARROW
BACKSPACE, DELETE, ENTER, RETURN, TAB, ESCAPE
SHIFT, CONTROL, OPTION, ALT
```

## 觸控事件 (Touch Events)

```javascript
touches   // 包含 { x, y, id } 的陣列 —— 當前所有觸控點

function touchStarted() {
  // 首次觸控時觸發
  return false;  // 防止預設行為（在行動裝置上停止捲動）
}

function touchMoved() {
  // 觸控拖曳時觸發
  return false;
}

function touchEnded() {
  // 觸控結束時觸發
}
```

### 撥動縮放 (Pinch Zoom)

```javascript
let prevDist = 0;
let zoomLevel = 1;

function touchMoved() {
  if (touches.length === 2) {
    let d = dist(touches[0].x, touches[0].y, touches[1].x, touches[1].y);
    if (prevDist > 0) {
      zoomLevel *= d / prevDist;
    }
    prevDist = d;
  }
  return false;
}

function touchEnded() {
  prevDist = 0;
}
```

## DOM 元素

### 建立控制項

```javascript
function setup() {
  createCanvas(800, 800);

  // 滑桿 (Slider)
  let slider = createSlider(0, 255, 100, 1);  // 最小值, 最大值, 預設值, 步長
  slider.position(10, height + 10);
  slider.input(() => { CONFIG.value = slider.value(); });

  // 按鈕 (Button)
  let btn = createButton('重置 (Reset)');
  btn.position(10, height + 40);
  btn.mousePressed(() => { resetSketch(); });

  // 核取方塊 (Checkbox)
  let check = createCheckbox('顯示網格', false);
  check.position(10, height + 70);
  check.changed(() => { CONFIG.showGrid = check.checked(); });

  // 下拉選單 (Select)
  let sel = createSelect();
  sel.position(10, height + 100);
  sel.option('模式 A');
  sel.option('模式 B');
  sel.changed(() => { CONFIG.mode = sel.value(); });

  // 顏色選擇器 (Color picker)
  let picker = createColorPicker('#ff0000');
  picker.position(10, height + 130);
  picker.input(() => { CONFIG.color = picker.value(); });

  // 文字輸入框 (Text input)
  let inp = createInput('你好');
  inp.position(10, height + 160);
  inp.input(() => { CONFIG.text = inp.value(); });
}
```

### 設定 DOM 元素樣式

```javascript
let slider = createSlider(0, 100, 50);
slider.position(10, 10);
slider.style('width', '200px');
slider.class('my-slider');
slider.parent('controls-div');  // 附加到特定的 DOM 元素
```

## 音訊輸入 (p5.sound)

需要 `p5.sound.min.js` 插件。

```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.11.3/addons/p5.sound.min.js"></script>
```

### 麥克風輸入

```javascript
let mic, fft, amplitude;

function setup() {
  createCanvas(800, 800);
  userStartAudio();  // 必要步驟 —— 需使用者手勢來啟用音訊

  mic = new p5.AudioIn();
  mic.start();

  fft = new p5.FFT(0.8, 256);  // 平滑度, 頻段數 (bins)
  fft.setInput(mic);

  amplitude = new p5.Amplitude();
  amplitude.setInput(mic);
}

function draw() {
  let level = amplitude.getLevel();    // 0.0 到 1.0 (整體音量)
  let spectrum = fft.analyze();         // 包含 256 個頻率值 (0-255) 的陣列
  let waveform = fft.waveform();        // 包含 256 個時域取樣值 (-1 到 1) 的陣列

  // 獲取特定頻段的能量
  let bass = fft.getEnergy('bass');          // 20-140 Hz
  let lowMid = fft.getEnergy('lowMid');      // 140-400 Hz
  let mid = fft.getEnergy('mid');            // 400-2600 Hz
  let highMid = fft.getEnergy('highMid');    // 2600-5200 Hz
  let treble = fft.getEnergy('treble');      // 5200-14000 Hz
  // 每個方法返回 0-255
}
```

### 音訊檔案播放

```javascript
let song, fft;

function preload() {
  song = loadSound('track.mp3');
}

function setup() {
  createCanvas(800, 800);
  fft = new p5.FFT(0.8, 512);
  fft.setInput(song);
}

function mousePressed() {
  if (song.isPlaying()) {
    song.pause();
  } else {
    song.play();
  }
}
```

### 節拍偵測（簡易版）

```javascript
let prevBass = 0;
let beatThreshold = 30;
let beatCooldown = 0;

function detectBeat() {
  let bass = fft.getEnergy('bass');
  let isBeat = bass - prevBass > beatThreshold && beatCooldown <= 0;
  prevBass = bass;
  if (isBeat) beatCooldown = 10;  // 影格數
  beatCooldown--;
  return isBeat;
}
```

## 捲動驅動動畫 (Scroll-Driven Animation)

```javascript
let scrollProgress = 0;

function setup() {
  let canvas = createCanvas(windowWidth, windowHeight);
  canvas.style('position', 'fixed');
  // 讓頁面可捲動
  document.body.style.height = '500vh';
}

window.addEventListener('scroll', () => {
  let maxScroll = document.body.scrollHeight - window.innerHeight;
  scrollProgress = window.scrollY / maxScroll;
});

function draw() {
  background(0);
  // 使用 scrollProgress (0 到 1) 來驅動動畫
  let x = lerp(0, width, scrollProgress);
  ellipse(x, height/2, 50);
}
```

## 響應式事件

```javascript
function windowResized() {
  resizeCanvas(windowWidth, windowHeight);
  // 重新建立緩衝區
  bgLayer = createGraphics(width, height);
  // 重新計算佈局
  recalculateLayout();
}

// 可見性變更（切換分頁）
document.addEventListener('visibilitychange', () => {
  if (document.hidden) {
    noLoop();  // 分頁不可見時暫停
  } else {
    loop();
  }
});
```
