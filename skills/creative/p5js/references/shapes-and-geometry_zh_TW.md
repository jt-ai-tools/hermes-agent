# 形狀與幾何 (Shapes and Geometry)

## 2D 原型 (2D Primitives)

```javascript
point(x, y);                 // 點
line(x1, y1, x2, y2);        // 線
rect(x, y, w, h);            // 矩形，預設為角落模式 (corner mode)
rect(x, y, w, h, r);         // 圓角矩形
rect(x, y, w, h, tl, tr, br, bl);  // 每個角落個別設定半徑
square(x, y, size);          // 正方形
ellipse(x, y, w, h);         // 橢圓
circle(x, y, d);             // 圓形（d 為直徑，非半徑）
triangle(x1, y1, x2, y2, x3, y3);  // 三角形
quad(x1, y1, x2, y2, x3, y3, x4, y4);  // 四邊形
arc(x, y, w, h, start, stop, mode);  // 弧形，模式：OPEN, CHORD, PIE
```

### 繪製模式 (Drawing Modes)

```javascript
rectMode(CENTER);   // x, y 為中心點（預設為 CORNER）
rectMode(CORNERS);  // x1, y1 到 x2, y2 為對角座標
ellipseMode(CORNER); // x, y 為左上角
ellipseMode(CENTER); // 預設值 —— x, y 為中心點
```

## 筆劃與填充 (Stroke and Fill)

```javascript
fill(r, g, b, a);    // 或 fill(gray), fill('#hex'), HSB 模式下為 fill(h, s, b)
noFill();            // 無填充
stroke(r, g, b, a);  // 筆劃顏色
noStroke();          // 無筆劃
strokeWeight(2);     // 筆劃粗細
strokeCap(ROUND);     // 筆劃末端樣式：ROUND (圓), SQUARE (平), PROJECT (延伸)
strokeJoin(ROUND);    // 筆劃轉角樣式：ROUND (圓), MITER (尖), BEVEL (斜)
```

## 使用頂點建立自定義形狀 (Custom Shapes with Vertices)

### 基礎頂點形狀

```javascript
beginShape();
  vertex(100, 100);
  vertex(200, 50);
  vertex(300, 100);
  vertex(250, 200);
  vertex(150, 200);
endShape(CLOSE);  // CLOSE 會將最後一個頂點連接回第一個頂點
```

### 形狀模式

```javascript
beginShape();          // 預設：連接所有頂點的多邊形
beginShape(POINTS);    // 個別的點
beginShape(LINES);     // 每兩個頂點組成一條線
beginShape(TRIANGLES); // 每三個頂點組成一個三角形
beginShape(TRIANGLE_FAN);
beginShape(TRIANGLE_STRIP);
beginShape(QUADS);     // 每四個頂點組成一個四邊形
beginShape(QUAD_STRIP);
```

### 輪廓 (Contours) —— 在形狀中打孔

```javascript
beginShape();
  // 外部形狀
  vertex(100, 100);
  vertex(300, 100);
  vertex(300, 300);
  vertex(100, 300);
  // 內部孔洞
  beginContour();
    vertex(150, 150);
    vertex(150, 250);
    vertex(250, 250);
    vertex(250, 150);
  endContour();
endShape(CLOSE);
```

## 貝茲曲線 (Bezier Curves)

### 三次貝茲 (Cubic Bezier)

```javascript
bezier(x1, y1, cx1, cy1, cx2, cy2, x2, y2);
// x1, y1 = 起點
// cx1, cy1 = 第一控制點
// cx2, cy2 = 第二控制點
// x2, y2 = 終點
```

### 自定義形狀中的貝茲

```javascript
beginShape();
  vertex(100, 200);
  bezierVertex(150, 50, 250, 50, 300, 200);
  // 控制點 1, 控制點 2, 終點
endShape();
```

### 二次貝茲 (Quadratic Bezier)

```javascript
beginShape();
  vertex(100, 200);
  quadraticVertex(200, 50, 300, 200);
  // 單一控制點 + 終點
endShape();
```

### 沿貝茲曲線插值

```javascript
let x = bezierPoint(x1, cx1, cx2, x2, t);  // t = 0..1
let y = bezierPoint(y1, cy1, cy2, y2, t);
let tx = bezierTangent(x1, cx1, cx2, x2, t); // 切線
```

## Catmull-Rom 樣條 (Catmull-Rom Splines)

```javascript
curve(cpx1, cpy1, x1, y1, x2, y2, cpx2, cpy2);
// cpx1, cpy1 = 起點前的控制點
// x1, y1 = 起點（可見）
// x2, y2 = 終點（可見）
// cpx2, cpy2 = 終點後的控制點

curveVertex(x, y);  // 在 beginShape() 中使用 —— 通過所有點的平滑曲線
curveTightness(0);  // 0 = Catmull-Rom, 1 = 直線, -1 = 鬆散
```

### 通過多點的平滑曲線

```javascript
let points = [/* {x, y} 的陣列 */];
beginShape();
  curveVertex(points[0].x, points[0].y); // 重複第一個點作為切線參考
  for (let p of points) {
    curveVertex(p.x, p.y);
  }
  curveVertex(points[points.length-1].x, points[points.length-1].y); // 重複最後一個點
endShape();
```

## p5.Vector

對於物理、粒子系統及幾何運算至關重要。

```javascript
let v = createVector(x, y);

// 算術運算（原地修改）
v.add(other);        // 向量加法
v.sub(other);        // 向量減法
v.mult(scalar);      // 縮放（乘法）
v.div(scalar);       // 縮放（除法）
v.normalize();       // 單位向量（長度為 1）
v.limit(max);        // 限制最大長度
v.setMag(len);       // 設定精確長度

// 查詢（非破壞性）
v.mag();             // 長度（模）
v.magSq();           // 長度平方（較快，無需開根號）
v.heading();         // 以弧度表示的角度
v.dist(other);       // 到另一個向量的距離
v.dot(other);        // 點積 (Inner product)
v.cross(other);      // 叉積 (Cross product，僅限 3D)
v.angleBetween(other); // 向量夾角

// 靜態方法（返回新向量）
p5.Vector.add(a, b);      // a + b → 新向量
p5.Vector.sub(a, b);      // a - b → 新向量
p5.Vector.fromAngle(a);   // 給定角度的單位向量
p5.Vector.random2D();     // 隨機單位向量
p5.Vector.lerp(a, b, t);  // 線性插值

// 複製
let copy = v.copy();
```

## 有號距離場 (Signed Distance Fields - 2D)

SDF 會返回一個點到形狀最近邊緣的距離。內部為負，外部為正。適用於平滑形狀、發光效果及布林運算。

```javascript
// 圓形 SDF
function sdCircle(px, py, cx, cy, r) {
  return dist(px, py, cx, cy) - r;
}

// 矩形 SDF
function sdBox(px, py, cx, cy, hw, hh) {
  let dx = abs(px - cx) - hw;
  let dy = abs(py - cy) - hh;
  return sqrt(max(dx, 0) ** 2 + max(dy, 0) ** 2) + min(max(dx, dy), 0);
}

// 線段 SDF
function sdSegment(px, py, ax, ay, bx, by) {
  let pa = createVector(px - ax, py - ay);
  let ba = createVector(bx - ax, by - ay);
  let t = constrain(pa.dot(ba) / ba.dot(ba), 0, 1);
  let closest = p5.Vector.add(createVector(ax, ay), p5.Vector.mult(ba, t));
  return dist(px, py, closest.x, closest.y);
}

// 平滑布林聯集 (Smooth boolean union)
function opSmoothUnion(d1, d2, k) {
  let h = constrain(0.5 + 0.5 * (d2 - d1) / k, 0, 1);
  return lerp(d2, d1, h) - k * h * (1 - h);
}

// 將 SDF 渲染為發光效果
let d = sdCircle(x, y, width/2, height/2, 200);
let glow = exp(-abs(d) * 0.02);  // 指數衰減
fill(glow * 255);
```

## 實用的幾何模式

### 正多邊形 (Regular Polygon)

```javascript
function regularPolygon(cx, cy, r, sides) {
  beginShape();
  for (let i = 0; i < sides; i++) {
    let a = TWO_PI * i / sides - HALF_PI;
    vertex(cx + cos(a) * r, cy + sin(a) * r);
  }
  endShape(CLOSE);
}
```

### 星形 (Star Shape)

```javascript
function star(cx, cy, r1, r2, npoints) {
  beginShape();
  let angle = TWO_PI / npoints;
  let halfAngle = angle / 2;
  for (let a = -HALF_PI; a < TWO_PI - HALF_PI; a += angle) {
    vertex(cx + cos(a) * r2, cy + sin(a) * r2);
    vertex(cx + cos(a + halfAngle) * r1, cy + sin(a + halfAngle) * r1);
  }
  endShape(CLOSE);
}
```

### 圓角線段 (膠囊形, Capsule)

```javascript
function capsule(x1, y1, x2, y2, weight) {
  strokeWeight(weight);
  strokeCap(ROUND);
  line(x1, y1, x2, y2);
}
```

### 軟體 / 變形蟲 (Soft Body / Blob)

```javascript
function blob(cx, cy, baseR, noiseScale, noiseOffset, detail = 64) {
  beginShape();
  for (let i = 0; i < detail; i++) {
    let a = TWO_PI * i / detail;
    let r = baseR + noise(cos(a) * noiseScale + noiseOffset,
                          sin(a) * noiseScale + noiseOffset) * baseR * 0.4;
    vertex(cx + cos(a) * r, cy + sin(a) * r);
  }
  endShape(CLOSE);
}
```

## 剪裁與遮罩 (Clipping and Masking)

```javascript
// 剪裁形狀 —— 隨後繪製的所有內容都會被此形狀遮蔽
beginClip();
  circle(width/2, height/2, 400);
endClip();
// 僅在圓形內部的內容會被顯示
image(myImage, 0, 0);

// 或者使用函式形式
clip(() => {
  circle(width/2, height/2, 400);
});

// 橡皮擦模式 —— 挖洞
erase();
  circle(mouseX, mouseY, 100);  // 此區域變為透明
noErase();
```
