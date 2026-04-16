# 色彩系統 (Color Systems)

## 色彩模式 (Color Modes)

### HSB（推薦用於生成式藝術）

```javascript
colorMode(HSB, 360, 100, 100, 100);
// 色相 (Hue)：0-360（色輪位置）
// 飽和度 (Saturation)：0-100（從灰色到鮮豔）
// 亮度 (Brightness)：0-100（從黑色到全亮）
// 透明度 (Alpha)：0-100

fill(200, 80, 90);        // 藍色，鮮豔，明亮
fill(200, 80, 90, 50);    // 50% 透明
```

HSB 的優點：
- 旋轉色相：`(baseHue + offset) % 360`
- 降低飽和度：減少 S
- 變暗：減少 B
- 單色變化：固定 H，改變 S 和 B
- 互補色：`(hue + 180) % 360`
- 相似色：`hue +/- 30`

### HSL

```javascript
colorMode(HSL, 360, 100, 100, 100);
// 亮度 (Lightness) 50 = 純色，0 = 黑色，100 = 白色
// 對於淺色 (Tints, L > 50) 和深色 (Shades, L < 50) 更直觀
```

### RGB

```javascript
colorMode(RGB, 255, 255, 255, 255);  // 預設
// 直接控制通道，對於程序化色盤較不直觀
```

## 色彩物件 (Color Objects)

```javascript
let c = color(200, 80, 90);    // 建立色彩物件
fill(c);

// 提取分量
let h = hue(c);
let s = saturation(c);
let b = brightness(c);
let r = red(c);
let g = green(c);
let bl = blue(c);
let a = alpha(c);

// 十六進制顏色隨處可用
fill('#e8d5b7');
fill('#e8d5b7cc');  // 包含透明度

// 透過 setter 修改
c.setAlpha(128);
c.setRed(200);
```

## 色彩插值 (Color Interpolation)

### lerpColor

```javascript
let c1 = color(0, 80, 100);    // 紅色
let c2 = color(200, 80, 100);  // 藍色
let mixed = lerpColor(c1, c2, 0.5);  // 中點混合
// 在目前的 colorMode 下運作
```

### paletteLerp (p5.js 1.11+)

一次在多種顏色之間進行插值。

```javascript
let colors = [
  color('#2E0854'),
  color('#850E35'),
  color('#EE6C4D'),
  color('#F5E663')
];
let c = paletteLerp(colors, t);  // t = 0..1，在所有顏色間插值
```

### 手動多停點漸層

```javascript
function multiLerp(colors, t) {
  t = constrain(t, 0, 1);
  let segment = t * (colors.length - 1);
  let idx = floor(segment);
  let frac = segment - idx;
  idx = min(idx, colors.length - 2);
  return lerpColor(colors[idx], colors[idx + 1], frac);
}
```

## 漸層渲染 (Gradient Rendering)

### 線性漸層

```javascript
function linearGradient(x1, y1, x2, y2, c1, c2) {
  let steps = dist(x1, y1, x2, y2);
  for (let i = 0; i <= steps; i++) {
    let t = i / steps;
    let c = lerpColor(c1, c2, t);
    stroke(c);
    let x = lerp(x1, x2, t);
    let y = lerp(y1, y2, t);
    // 在每個點繪製垂直線
    let dx = -(y2 - y1) / steps * 1000;
    let dy = (x2 - x1) / steps * 1000;
    line(x - dx, y - dy, x + dx, y + dy);
  }
}
```

### 放射狀漸層

```javascript
function radialGradient(cx, cy, r, innerColor, outerColor) {
  noStroke();
  for (let i = r; i > 0; i--) {
    let t = 1 - i / r;
    fill(lerpColor(innerColor, outerColor, t));
    ellipse(cx, cy, i * 2);
  }
}
```

### 基於雜訊的漸層

```javascript
function noiseGradient(colors, noiseScale, time) {
  loadPixels();
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      let n = noise(x * noiseScale, y * noiseScale, time);
      let c = multiLerp(colors, n);
      let idx = 4 * (y * width + x);
      pixels[idx] = red(c);
      pixels[idx+1] = green(c);
      pixels[idx+2] = blue(c);
      pixels[idx+3] = 255;
    }
  }
  updatePixels();
}
```

## 程序化色盤生成 (Procedural Palette Generation)

### 互補色 (Complementary)

```javascript
function complementary(baseHue) {
  return [baseHue, (baseHue + 180) % 360];
}
```

### 相似色 (Analogous)

```javascript
function analogous(baseHue, spread = 30) {
  return [
    (baseHue - spread + 360) % 360,
    baseHue,
    (baseHue + spread) % 360
  ];
}
```

### 三等分配色 (Triadic)

```javascript
function triadic(baseHue) {
  return [baseHue, (baseHue + 120) % 360, (baseHue + 240) % 360];
}
```

### 分裂互補色 (Split Complementary)

```javascript
function splitComplementary(baseHue) {
  return [baseHue, (baseHue + 150) % 360, (baseHue + 210) % 360];
}
```

### 矩形配色 (Tetradic / Rectangle)

```javascript
function tetradic(baseHue) {
  return [baseHue, (baseHue + 60) % 360, (baseHue + 180) % 360, (baseHue + 240) % 360];
}
```

### 單色變化 (Monochromatic Variations)

```javascript
function monoVariations(hue, count = 5) {
  let colors = [];
  for (let i = 0; i < count; i++) {
    let s = map(i, 0, count - 1, 20, 90);
    let b = map(i, 0, count - 1, 95, 40);
    colors.push(color(hue, s, b));
  }
  return colors;
}
```

## 精選色盤庫 (Curated Palette Library)

### 暖色調色盤

```javascript
const SUNSET = ['#2E0854', '#850E35', '#EE6C4D', '#F5E663'];
const EMBER  = ['#1a0000', '#4a0000', '#8b2500', '#cd5c00', '#ffd700'];
const PEACH  = ['#fff5eb', '#ffdab9', '#ff9a76', '#ff6b6b', '#c94c4c'];
const COPPER = ['#1c1108', '#3d2b1f', '#7b4b2a', '#b87333', '#daa06d'];
```

### 冷色調色盤

```javascript
const OCEAN   = ['#0a0e27', '#1a1b4b', '#2a4a7f', '#3d7cb8', '#87ceeb'];
const ARCTIC  = ['#0d1b2a', '#1b263b', '#415a77', '#778da9', '#e0e1dd'];
const FOREST  = ['#0b1a0b', '#1a3a1a', '#2d5a2d', '#4a8c4a', '#90c990'];
const DEEP_SEA = ['#000814', '#001d3d', '#003566', '#006d77', '#83c5be'];
```

### 中性色調色盤

```javascript
const GRAPHITE = ['#1a1a1a', '#333333', '#555555', '#888888', '#cccccc'];
const CREAM    = ['#f4f0e8', '#e8dcc8', '#c9b99a', '#a89070', '#7a6450'];
const SLATE    = ['#1e293b', '#334155', '#475569', '#64748b', '#94a3b8'];
```

### 鮮豔色調色盤

```javascript
const NEON     = ['#ff00ff', '#00ffff', '#ff0080', '#80ff00', '#0080ff'];
const RAINBOW  = ['#ff0000', '#ff8000', '#ffff00', '#00ff00', '#0000ff', '#8000ff'];
const VAPOR    = ['#ff71ce', '#01cdfe', '#05ffa1', '#b967ff', '#fffb96'];
const CYBER    = ['#0f0f0f', '#00ff41', '#ff0090', '#00d4ff', '#ffd000'];
```

### 大地色調

```javascript
const TERRA    = ['#2c1810', '#5c3a2a', '#8b6b4a', '#c4a672', '#e8d5b7'];
const MOSS     = ['#1a1f16', '#3d4a2e', '#6b7c4f', '#9aab7a', '#c8d4a9'];
const CLAY     = ['#3b2f2f', '#6b4c4c', '#9e7676', '#c9a0a0', '#e8caca'];
```

## 混合模式 (Blend Modes)

```javascript
blendMode(BLEND);       // 預設 — alpha 合成
blendMode(ADD);         // 相加 — 明亮的發光效果
blendMode(MULTIPLY);    // 變暗 — 陰影、紋理疊加
blendMode(SCREEN);      // 變亮 — 柔和光暈
blendMode(OVERLAY);     // 對比增強 — 強調高光/陰影
blendMode(DIFFERENCE);  // 色彩相減 — 迷幻效果
blendMode(EXCLUSION);   // 較柔和的差異
blendMode(REPLACE);     // 覆寫（無 alpha 混合）
blendMode(REMOVE);      // 減去 alpha
blendMode(LIGHTEST);    // 保留較亮的像素
blendMode(DARKEST);     // 保留較暗的像素
blendMode(BURN);        // 變暗 + 增加飽和度
blendMode(DODGE);       // 變亮 + 增加飽和度
blendMode(SOFT_LIGHT);  // 微妙疊加
blendMode(HARD_LIGHT);  // 強力疊加

// 使用後請務必重設
blendMode(BLEND);
```

### 混合模式配方

| 效果 (Effect) | 模式 (Mode) | 使用案例 (Use case) |
|--------|------|----------|
| 相加發光 (Additive glow) | `ADD` | 光束、火、粒子 |
| 陰影疊加 (Shadow overlay) | `MULTIPLY` | 紋理、暈影 |
| 柔光混合 (Soft light mix) | `SCREEN` | 霧、煙、逆光 |
| 高對比 (High contrast) | `OVERLAY` | 戲劇化的合成 |
| 色彩負片 (Color negative) | `DIFFERENCE` | 故障藝術、迷幻效果 |
| 圖層合成 (Layer compositing) | `BLEND` | 標準 alpha 圖層疊加 |

## 背景技巧 (Background Techniques)

### 紋理背景

```javascript
function texturedBackground(baseColor, noiseScale, noiseAmount) {
  loadPixels();
  let r = red(baseColor), g = green(baseColor), b = blue(baseColor);
  for (let i = 0; i < pixels.length; i += 4) {
    let x = (i / 4) % width;
    let y = floor((i / 4) / width);
    let n = (noise(x * noiseScale, y * noiseScale) - 0.5) * noiseAmount;
    pixels[i] = constrain(r + n, 0, 255);
    pixels[i+1] = constrain(g + n, 0, 255);
    pixels[i+2] = constrain(b + n, 0, 255);
    pixels[i+3] = 255;
  }
  updatePixels();
}
```

### 暈影 (Vignette)

```javascript
function vignette(strength = 0.5, radius = 0.7) {
  loadPixels();
  let cx = width / 2, cy = height / 2;
  let maxDist = dist(0, 0, cx, cy);
  for (let i = 0; i < pixels.length; i += 4) {
    let x = (i / 4) % width;
    let y = floor((i / 4) / width);
    let d = dist(x, y, cx, cy) / maxDist;
    let factor = 1.0 - smoothstep(constrain((d - radius) / (1 - radius), 0, 1)) * strength;
    pixels[i] *= factor;
    pixels[i+1] *= factor;
    pixels[i+2] *= factor;
  }
  updatePixels();
}

function smoothstep(t) { return t * t * (3 - 2 * t); }
```

### 電影膠卷顆粒 (Film Grain)

```javascript
function filmGrain(amount = 30) {
  loadPixels();
  for (let i = 0; i < pixels.length; i += 4) {
    let grain = random(-amount, amount);
    pixels[i] = constrain(pixels[i] + grain, 0, 255);
    pixels[i+1] = constrain(pixels[i+1] + grain, 0, 255);
    pixels[i+2] = constrain(pixels[i+2] + grain, 0, 255);
  }
  updatePixels();
}
```
