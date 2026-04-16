# WebGL 與 3D

## WebGL 模式設定

```javascript
function setup() {
  createCanvas(1920, 1080, WEBGL);
  // 原點在中心 (CENTER)，而非左上角
  // Y 軸向上 (與 2D 模式相反)
  // Z 軸指向觀看者
}
```

### 座標轉換 (將 WEBGL 轉換為類 P2D)

```javascript
function draw() {
  translate(-width/2, -height/2);  // 將原點移至左上角
  // 現在座標運作方式與 P2D 相同
}
```

## 3D 基本幾何體

```javascript
box(w, h, d);             // 長方體
sphere(radius, detailX, detailY);
cylinder(radius, height, detailX, detailY);
cone(radius, height, detailX, detailY);
torus(radius, tubeRadius, detailX, detailY);
plane(width, height);     // 平面矩形
ellipsoid(rx, ry, rz);    // 橢球體 (拉伸的球體)
```

### 3D 轉換

```javascript
push();
  translate(x, y, z);
  rotateX(angleX);
  rotateY(angleY);
  rotateZ(angleZ);
  scale(s);
  box(100);
pop();
```

## 攝影機 (Camera)

### 預設攝影機

```javascript
camera(
  eyeX, eyeY, eyeZ,       // 攝影機位置
  centerX, centerY, centerZ, // 注視目標
  upX, upY, upZ             // 向上方向
);

// 預設值：camera(0, 0, (height/2)/tan(PI/6), 0, 0, 0, 0, 1, 0)
```

### 軌道控制 (Orbit Control)

```javascript
function draw() {
  orbitControl();  // 滑鼠拖曳旋轉，滾輪縮放
  box(200);
}
```

### 建立攝影機 (createCamera)

```javascript
let cam;

function setup() {
  createCanvas(800, 800, WEBGL);
  cam = createCamera();
  cam.setPosition(300, -200, 500);
  cam.lookAt(0, 0, 0);
}

// 攝影機方法
cam.setPosition(x, y, z);
cam.lookAt(x, y, z);
cam.move(dx, dy, dz);      // 相對於攝影機方向
cam.pan(angle);              // 水平旋轉 (左右搖擺)
cam.tilt(angle);             // 垂直旋轉 (上下俯仰)
cam.roll(angle);             // Z 軸旋轉 (側傾)
cam.slerp(otherCam, t);     // 攝影機間的平滑插值 (Slerp)
```

### 透視與正交投影 (Perspective and Orthographic)

```javascript
// 透視投影 (預設)
perspective(fov, aspect, near, far);
// fov：視場角，以弧度表示 (預設為 PI/3)
// aspect：寬高比 (width/height)
// near/far：近/遠裁剪平面

// 正交投影 (無深度透視感)
ortho(-width/2, width/2, -height/2, height/2, 0, 2000);
```

## 光照 (Lighting)

```javascript
// 環境光 (均勻，無方向)
ambientLight(50, 50, 50);     // 暗淡的補光

// 定向光 (平行光，如陽光)
directionalLight(255, 255, 255, 0, -1, 0);  // 顏色 + 方向

// 點光源 (從特定位置向外放射)
pointLight(255, 200, 150, 200, -300, 400);   // 顏色 + 位置

// 聚光燈 (從位置指向目標的錐形光)
spotLight(255, 255, 255,       // 顏色
          0, -300, 300,         // 位置
          0, 1, -1,             // 方向
          PI / 4, 5);           // 角度，集中度

// 基於影像的光照 (IBL)
imageLight(myHDRI);

// 無光照 (平面著色)
noLights();

// 快速預設光照
lights();
```

### 三點光照設定 (Three-Point Lighting)

```javascript
function setupLighting() {
  ambientLight(30, 30, 40);                    // 暗藍色補光

  // 主光 (主要光源，暖色)
  directionalLight(255, 240, 220, -1, -1, -1);

  // 補光 (較柔和、冷色，位於另一側)
  directionalLight(80, 100, 140, 1, -0.5, -1);

  // 輪廓光 (位於主體後方，用於定義輪廓)
  pointLight(200, 200, 255, 0, -200, -400);
}
```

## 材質 (Materials)

```javascript
// 法線材質 (偵錯用 — 顏色取自表面法線)
normalMaterial();

// 環境材質 (僅對環境光有反應)
ambientMaterial(200, 100, 100);

// 自發光材質 (自行發光，無陰影)
emissiveMaterial(255, 0, 100);

// 鏡面材質 (發亮的反射)
specularMaterial(255);
shininess(50);                // 1-200 (越高則高光越集中)
metalness(100);               // 0-200 (金屬反射)

// fill 亦可使用 (對光照無反應)
fill(255, 0, 0);
```

### 紋理 (Texture)

```javascript
let img;
function preload() { img = loadImage('texture.jpg'); }

function draw() {
  texture(img);
  textureMode(NORMAL);  // UV 座標範圍 0-1
  // textureMode(IMAGE); // 以像素為單位的 UV 座標
  textureWrap(REPEAT);  // 或 CLAMP, MIRROR
  box(200);
}
```

## 自定義幾何體

### 建立幾何體 (buildGeometry)

```javascript
let myShape;

function setup() {
  createCanvas(800, 800, WEBGL);
  myShape = buildGeometry(() => {
    for (let i = 0; i < 50; i++) {
      push();
      translate(random(-200, 200), random(-200, 200), random(-200, 200));
      sphere(10);
      pop();
    }
  });
}

function draw() {
  model(myShape);  // 高效渲染已建立的幾何體
}
```

### 開始/結束幾何體 (beginGeometry / endGeometry)

```javascript
beginGeometry();
  // 在此繪製形狀
  box(50);
  translate(100, 0, 0);
  sphere(30);
let geo = endGeometry();

model(geo);  // 重複使用
```

### 手動幾何體 (p5.Geometry)

```javascript
let geo = new p5.Geometry(detailX, detailY, function() {
  for (let i = 0; i <= detailX; i++) {
    for (let j = 0; j <= detailY; j++) {
      let u = i / detailX;
      let v = j / detailY;
      let x = cos(u * TWO_PI) * (100 + 30 * cos(v * TWO_PI));
      let y = sin(u * TWO_PI) * (100 + 30 * cos(v * TWO_PI));
      let z = 30 * sin(v * TWO_PI);
      this.vertices.push(createVector(x, y, z));
      this.uvs.push(u, v);
    }
  }
  this.computeFaces();
  this.computeNormals();
});
```

## GLSL 著色器 (Shaders)

### 建立著色器 (頂點 + 片段)

```javascript
let myShader;

function setup() {
  createCanvas(800, 800, WEBGL);

  let vert = `
    precision mediump float;
    attribute vec3 aPosition;
    attribute vec2 aTexCoord;
    varying vec2 vTexCoord;
    uniform mat4 uModelViewMatrix;
    uniform mat4 uProjectionMatrix;
    void main() {
      vTexCoord = aTexCoord;
      vec4 pos = uProjectionMatrix * uModelViewMatrix * vec4(aPosition, 1.0);
      gl_Position = pos;
    }
  `;

  let frag = `
    precision mediump float;
    varying vec2 vTexCoord;
    uniform float uTime;
    uniform vec2 uResolution;

    void main() {
      vec2 uv = vTexCoord;
      vec3 col = 0.5 + 0.5 * cos(uTime + uv.xyx + vec3(0, 2, 4));
      gl_FragColor = vec4(col, 1.0);
    }
  `;

  myShader = createShader(vert, frag);
}

function draw() {
  shader(myShader);
  myShader.setUniform('uTime', millis() / 1000.0);
  myShader.setUniform('uResolution', [width, height]);
  rect(0, 0, width, height);
  resetShader();
}
```

### 建立濾鏡著色器 (後處理)

較簡單 — 僅需要片段著色器。會自動將畫布作為紋理。

```javascript
let blurShader;

function setup() {
  createCanvas(800, 800, WEBGL);

  blurShader = createFilterShader(`
    precision mediump float;
    varying vec2 vTexCoord;
    uniform sampler2D tex0;
    uniform vec2 texelSize;

    void main() {
      vec4 sum = vec4(0.0);
      for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
          sum += texture2D(tex0, vTexCoord + vec2(float(x), float(y)) * texelSize);
        }
      }
      gl_FragColor = sum / 25.0;
    }
  `);
}

function draw() {
  // 正常繪製場景
  background(0);
  fill(255, 0, 0);
  sphere(100);

  // 應用後處理濾鏡
  filter(blurShader);
}
```

### 常用的著色器 Uniforms

```javascript
myShader.setUniform('uTime', millis() / 1000.0);
myShader.setUniform('uResolution', [width, height]);
myShader.setUniform('uMouse', [mouseX / width, mouseY / height]);
myShader.setUniform('uTexture', myGraphics);  // 將 p5.Graphics 作為紋理傳遞
myShader.setUniform('uValue', 0.5);           // 浮點數
myShader.setUniform('uColor', [1.0, 0.0, 0.5, 1.0]); // 四維向量
```

### 著色器範例 (Shader Recipes)

**色散效果 (Chromatic Aberration)：**
```glsl
vec4 r = texture2D(tex0, vTexCoord + vec2(0.005, 0.0));
vec4 g = texture2D(tex0, vTexCoord);
vec4 b = texture2D(tex0, vTexCoord - vec2(0.005, 0.0));
gl_FragColor = vec4(r.r, g.g, b.b, 1.0);
```

**暈影 (Vignette)：**
```glsl
float d = distance(vTexCoord, vec2(0.5));
float v = smoothstep(0.7, 0.4, d);
gl_FragColor = texture2D(tex0, vTexCoord) * v;
```

**掃描線 (Scanlines)：**
```glsl
float scanline = sin(vTexCoord.y * uResolution.y * 3.14159) * 0.04;
vec4 col = texture2D(tex0, vTexCoord);
gl_FragColor = col - scanline;
```

## 影格緩衝區 (Framebuffers)

```javascript
let fbo;

function setup() {
  createCanvas(800, 800, WEBGL);
  fbo = createFramebuffer();
}

function draw() {
  // 渲染至影格緩衝區
  fbo.begin();
  clear();
  rotateY(frameCount * 0.01);
  box(200);
  fbo.end();

  // 將影格緩衝區作為紋理使用
  texture(fbo.color);
  plane(width, height);
}
```

### 多階段渲染 (Multi-Pass Rendering)

```javascript
let sceneBuffer, blurBuffer;

function setup() {
  createCanvas(800, 800, WEBGL);
  sceneBuffer = createFramebuffer();
  blurBuffer = createFramebuffer();
}

function draw() {
  // 階段 1：渲染場景
  sceneBuffer.begin();
  clear();
  lights();
  rotateY(frameCount * 0.01);
  box(200);
  sceneBuffer.end();

  // 階段 2：模糊處理
  blurBuffer.begin();
  shader(blurShader);
  blurShader.setUniform('uTexture', sceneBuffer.color);
  rect(0, 0, width, height);
  resetShader();
  blurBuffer.end();

  // 最終：合成
  texture(blurBuffer.color);
  plane(width, height);
}
```
