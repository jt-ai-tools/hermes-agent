---
name: p5js
description: "使用 p5.js 的互動式與生成式視覺藝術生產流程。建立基於瀏覽器的草圖、生成藝術、數據視覺化、互動體驗、3D 場景、音訊反應視覺效果及動態圖形 —— 並可匯出為 HTML、PNG、GIF、MP4 或 SVG。涵蓋：2D/3D 渲染、雜訊與粒子系統、流場、著色器 (GLSL)、像素操作、動態排版、WebGL 場景、音訊分析、滑鼠/鍵盤互動以及無頭高解析度匯出。適用於使用者要求：p5.js 草圖、創意編程、生成藝術、互動式視覺化、畫布動畫、基於瀏覽器的視覺藝術、數據視覺化、著色器效果或任何 p5.js 專案。"
version: 1.0.0
metadata:
  hermes:
    tags: [creative-coding, generative-art, p5js, canvas, interactive, visualization, webgl, shaders, animation]
    related_skills: [ascii-video, manim-video, excalidraw]
---

# p5.js 生產流程 (p5.js Production Pipeline)

## 創意標準

這是渲染於瀏覽器中的視覺藝術。畫布是媒介；演算法是畫筆。

**在編寫任何一行程式碼之前**，請先明確創意概念。這件作品傳達了什麼？是什麼讓觀眾停下捲動的動作？這與一般的教學範例有何不同？使用者的提示詞只是一個起點 —— 請以創意的野心來詮釋它。

**首刷即卓越是不可妥協的。** 輸出結果在首次載入時必須在視覺上極具衝擊力。如果看起來像 p5.js 教學練習、預設配置或「AI 生成的創意編程」，那就是錯誤的。在交付前請重新思考。

**超越參考詞彙。** 參考資料中的雜訊函式、粒子系統、調色盤和著色器效果只是基礎詞彙。對於每個專案，請嘗試組合、分層並發明。目錄就像是顏料盤 —— 而您負責繪製整幅畫。

**保持積極主動的創意。** 如果使用者要求「一個粒子系統」，請提供一個具備突發群聚行為、幽靈般的拖尾餘波、隨調色盤偏移的深度霧氣，以及會呼吸的背景雜訊場的粒子系統。至少包含一個使用者沒有要求但會欣賞的視覺細節。

**密集、層次分明、深思熟慮。** 每一格畫面都應該讓觀看者感到值得。絕不要使用純白的背景。務必使用構圖階層。務必使用有意的色彩。務必包含只有在近距離觀察時才會顯現的微小細節。

**凝聚的美學優於功能數量。** 所有元素必須服務於統一的視覺語言 —— 共用的色溫、一致的線條粗細詞彙、和諧的動作速度。一個包含十個無關效果的草圖，比不上一個包含三個相互呼應效果的作品。

## 模式

| 模式 | 輸入 | 輸出 | 參考資料 |
|------|-------|--------|-----------|
| **生成藝術** | 種子 / 參數 | 程序化視覺組合（靜態或動畫） | `references/visual-effects_zh_TW.md` |
| **數據視覺化** | 資料集 / API | 互動式圖表、圖形、自定義數據顯示 | `references/interaction_zh_TW.md` |
| **互動體驗** | 無（使用者驅動） | 滑鼠/鍵盤/觸控驅動的草圖 | `references/interaction_zh_TW.md` |
| **動畫 / 動態圖形** | 時間軸 / 分鏡 | 定時序列、動態排版、轉場 | `references/animation_zh_TW.md` |
| **3D 場景** | 概念描述 | WebGL 幾何體、燈光、攝影機、材質 | `references/webgl-and-3d_zh_TW.md` |
| **影像處理** | 影像檔案 | 像素操作、濾鏡、馬賽克、點彩畫 | `references/visual-effects_zh_TW.md` § 像素操作 |
| **音訊反應式** | 音訊檔案 / 麥克風 | 聲音驅動的生成視覺效果 | `references/interaction_zh_TW.md` § 音訊輸入 |

## 技術棧 (Stack)

每個專案使用單一且自包含的 HTML 檔案。不需要構建步驟。

| 層級 | 工具 | 用途 |
|-------|------|---------|
| 核心 | p5.js 1.11.3 (CDN) | 畫布渲染、數學、變換、事件處理 |
| 3D | p5.js WebGL 模式 | 3D 幾何體、攝影機、燈光、GLSL 著色器 |
| 音訊 | p5.sound.js (CDN) | FFT 分析、振幅、麥克風輸入、振盪器 |
| 匯出 | 內建 `saveCanvas()` / `saveGif()` / `saveFrames()` | PNG、GIF、影格序列輸出 |
| 捕捉 | CCapture.js (選用) | 確定性影格率影片捕捉 (WebM, GIF) |
| 無頭 | Puppeteer + Node.js (選用) | 自動化高解析度渲染、透過 ffmpeg 輸出 MP4 |
| SVG | p5.js-svg 1.6.0 (選用) | 用於列印的向量輸出 —— 需搭配 p5.js 1.x |
| 自然媒介 | p5.brush (選用) | 水彩、木炭、筆觸 —— 需搭配 p5.js 2.x + WEBGL |
| 紋理 | p5.grain (選用) | 電影膠片顆粒、紋理疊加 |
| 字體 | Google Fonts / `loadFont()` | 透過 OTF/TTF/WOFF2 的自定義排版 |

### 版本說明

**p5.js 1.x** (1.11.3) 是預設版本 —— 穩定、文件齊全，具備最廣泛的程式庫相容性。除非專案需要 2.x 的功能，否則請使用此版本。

**p5.js 2.x** (2.2+) 增加了：取代 `preload()` 的 `async setup()`、OKLCH/OKLAB 色彩模式、`splineVertex()`、著色器 `.modify()` API、可變字體 (Variable fonts)、`textToContours()`、指點事件 (Pointer events)。為 p5.brush 所必需。請參閱 `references/core-api_zh_TW.md` § p5.js 2.0。

## 流程

每個專案都遵循相同的 6 階段路徑：

```
CONCEPT → DESIGN → CODE → PREVIEW → EXPORT → VERIFY
```

1. **CONCEPT (概念)** —— 明確創意願景：氛圍、色彩世界、動作語彙、獨特之處。
2. **DESIGN (設計)** —— 選擇模式、畫布大小、互動模型、色彩系統、匯出格式。將概念對應到技術決策。
3. **CODE (編碼)** —— 撰寫帶有內聯 p5.js 的單一 HTML 檔案。結構：全局變數 → `preload()` → `setup()` → `draw()` → 輔助函式 → 類別 → 事件處理器。
4. **PREVIEW (預覽)** —— 在瀏覽器中開啟，驗證視覺品質。以目標解析度進行測試。檢查效能。
5. **EXPORT (匯出)** —— 捕捉輸出：`saveCanvas()` 輸出 PNG，`saveGif()` 輸出 GIF，`saveFrames()` + ffmpeg 輸出 MP4，Puppeteer 進行無頭批量處理。
6. **VERIFY (驗證)** —— 輸出結果是否符合概念？在預期的顯示尺寸下是否有視覺衝擊力？你會想把它框起來嗎？

## 創意指導

### 美學維度

| 維度 | 選項 | 參考資料 |
|-----------|---------|-----------|
| **色彩系統** | HSB/HSL, RGB, 具名調色盤, 程序化和諧色, 漸層內插 | `references/color-systems_zh_TW.md` |
| **雜訊詞彙** | Perlin 雜訊, Simplex, 分形 (Octaved), 域扭曲, Curl 雜訊 | `references/visual-effects_zh_TW.md` § 雜訊 |
| **粒子系統** | 基於物理, 群聚, 軌道繪製, 吸引子驅動, 流場追隨 | `references/visual-effects_zh_TW.md` § 粒子 |
| **形狀語言** | 幾何原語, 自定義頂點, 貝茲曲線, SVG 路徑 | `references/shapes-and-geometry_zh_TW.md` |
| **動作風格** | 緩動 (Eased), 基於彈簧, 雜訊驅動, 物理模擬, 插值 (Lerped), 階梯式 | `references/animation_zh_TW.md` |
| **排版** | 系統字體, 載入 OTF, `textToPoints()` 粒子文字, 動態排版 | `references/typography_zh_TW.md` |
| **著色器效果** | GLSL 片段/頂點著色器, 濾鏡著色器, 後處理, 回饋迴圈 | `references/webgl-and-3d_zh_TW.md` § 著色器 |
| **構圖** | 網格, 放射狀, 黃金比例, 三分法, 有機散佈, 平鋪 | `references/core-api_zh_TW.md` § 構圖 |
| **互動模型** | 滑鼠跟隨, 點擊生成, 拖曳, 鍵盤狀態, 捲動驅動, 麥克風輸入 | `references/interaction_zh_TW.md` |
| **混合模式** | `BLEND`, `ADD`, `MULTIPLY`, `SCREEN`, `DIFFERENCE`, `EXCLUSION`, `OVERLAY` | `references/color-systems_zh_TW.md` § 混合模式 |
| **分層** | `createGraphics()` 離屏緩衝區, Alpha 合成, 遮罩 | `references/core-api_zh_TW.md` § 離屏緩衝區 |
| **紋理** | Perlin 表面, 點刻 (Stippling), 陰影線 (Hatching), 半色調, 像素排序 | `references/visual-effects_zh_TW.md` § 紋理生成 |

### 每專案變化規則

絕不要使用預設配置。針對每個專案：
- **自定義調色盤** —— 絕不要使用原始的 `fill(255, 0, 0)`。務必使用包含 3-7 種顏色的設計調色盤。
- **自定義線條粗細詞彙** —— 細部強調 (0.5)、中等結構 (1-2)、大膽強調 (3-5)。
- **背景處理** —— 絕不要使用純色的 `background(0)` 或 `background(255)`。務必使用帶紋理、漸層或分層的背景。
- **動作多樣性** —— 不同元素使用不同的速度。主要的為 1x，次要的為 0.3x，環境背景為 0.1x。
- **至少包含一項發明元素** —— 一個自定義的粒子行為、一種新穎的雜訊應用或獨特的互動回應。

### 專案特定發明

針對每個專案，請至少發明以下一項：
- 匹配氛圍的自定義調色盤（而非預設值）
- 新穎的雜訊場組合（例如：Curl 雜訊 + 域扭曲 + 回饋）
- 獨特的粒子行為（自定義作用力、自定義軌跡、自定義生成方式）
- 一種使用者未要求但能提升作品質感的互動機制
- 一種能創造視覺階層感的構圖技術

### 參數設計理念

參數應該從演算法中自然產生，而非來自通用的選單。請問自己：「『這個』系統的哪些屬性應該是可以調校的？」

**好的參數**能展現演算法的個性：
- **數量 (Quantities)** —— 多少粒子、分支、細胞（控制密度）
- **規模 (Scales)** —— 雜訊頻率、元素大小、間距（控制紋理）
- **速率 (Rates)** —— 速度、生長率、衰減（控制能量）
- **閥值 (Thresholds)** —— 行為何時改變？（控制戲劇性）
- **比例 (Ratios)** —— 比例、力量間的平衡（控制和諧感）

**不好的參數**是與演算法無關的通用控制：
- "color1", "color2", "size" —— 在缺乏語境的情況下毫無意義
- 無關效果的切換開關
- 僅改變外觀而非行為的參數

每個參數都應該改變演算法如何「思考」，而不僅僅是它看起來如何。一個改變雜訊倍頻的「亂流 (turbulence)」參數是好的。一個僅改變 `ellipse()` 半徑的「粒子大小」滑桿則顯得膚淺。

## 工作流程

### 步驟 1：創意願景

在撰寫任何程式碼之前，請先明確：

- **情緒 / 氛圍**：觀眾應該感受到什麼？沉思？充滿活力？不安？俏皮？
- **視覺故事**：隨著時間（或互動）會發生什麼？構建？衰減？轉化？震盪？
- **色彩世界**：暖色調還是冷色調？單色？互補色？主導色調是什麼？強調色是什麼？
- **形狀語言**：有機曲線？銳利幾何？圓點？線條？混合型？
- **動作語彙**：緩慢漂移？爆炸式噴發？呼吸式脈動？機械般的精確？
- **是什麼讓「這個」與眾不同**：這個草圖最獨特的一個特點是什麼？

將使用者的提示詞對應到美學選擇。「放鬆的生成式背景」與「故障風格的數據視覺化」所需的一切都截然不同。

### 步驟 2：技術設計

- **模式** —— 以上表格中的 7 種模式之一
- **畫布大小** —— 橫向 1920x1080、直向 1080x1920、正方形 1080x1080，或響應式的 `windowWidth/windowHeight`
- **渲染器** —— `P2D` (預設) 或 `WEBGL` (用於 3D、著色器、高級混合模式)
- **影格率** —— 60fps (互動式)、30fps (環境動畫) 或 `noLoop()` (靜態生成)
- **匯出目標** —— 瀏覽器顯示、PNG 靜態圖、GIF 迴圈、MP4 影片、SVG 向量圖
- **互動模型** —— 被動（無輸入）、滑鼠驅動、鍵盤驅動、音訊反應式、捲動驅動
- **檢視器 UI** —— 對於互動式生成藝術，從 `templates/viewer.html` 開始，它提供了種子導覽、參數滑桿和下載功能。對於簡單的草圖或影片匯出，使用基礎 HTML 即可

### 步驟 3：編寫草圖

對於**互動式生成藝術**（種子探索、參數調校）：從 `templates/viewer.html` 開始。先讀取範本，保留固定區塊（種子導覽、操作按鈕），替換演算法與參數控制。這能為使用者提供種子前/後/隨機/跳轉、帶即時更新的參數滑桿以及 PNG 下載功能 —— 且全部已串接完成。

對於**動畫、影片匯出或簡單草圖**：使用基礎 HTML：

單一 HTML 檔案。結構：

```html
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>專案名稱</title>
  <script>p5.disableFriendlyErrors = true;</script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.11.3/p5.min.js"></script>
  <!-- <script src="https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.11.3/addons/p5.sound.min.js"></script> -->
  <!-- <script src="https://unpkg.com/p5.js-svg@1.6.0"></script> -->  <!-- SVG 匯出 -->
  <!-- <script src="https://cdn.jsdelivr.net/npm/ccapture.js-npmfixed/build/CCapture.all.min.js"></script> -->  <!-- 影片捕捉 -->
  <style>
    html, body { margin: 0; padding: 0; overflow: hidden; }
    canvas { display: block; }
  </style>
</head>
<body>
<script>
// === 配置 (Configuration) ===
const CONFIG = {
  seed: 42,
  // ... 專案特定參數
};

// === 調色盤 (Color Palette) ===
const PALETTE = {
  bg: '#0a0a0f',
  primary: '#e8d5b7',
  // ...
};

// === 全局狀態 ===
let particles = [];

// === 預載 (Preload - 字體、圖片、數據) ===
function preload() {
  // font = loadFont('...');
}

// === 設定 (Setup) ===
function setup() {
  createCanvas(1920, 1080);
  randomSeed(CONFIG.seed);
  noiseSeed(CONFIG.seed);
  colorMode(HSB, 360, 100, 100, 100);
  // 初始化狀態...
}

// === 繪製迴圈 (Draw Loop) ===
function draw() {
  // 渲染影格...
}

// === 輔助函式 ===
// ...

// === 類別 (Classes) ===
class Particle {
  // ...
}

// === 事件處理器 ===
function mousePressed() { /* ... */ }
function keyPressed() { /* ... */ }
function windowResized() { resizeCanvas(windowWidth, windowHeight); }
</script>
</body>
</html>
```

關鍵實作模式：
- **帶種子的隨機性**：務必使用 `randomSeed()` + `noiseSeed()` 以確保可重複性。
- **色彩模式**：使用 `colorMode(HSB, 360, 100, 100, 100)` 以實現直觀的色彩控制。
- **狀態分離**：CONFIG 存放參數，PALETTE 存放顏色，全局變數存放可變狀態。
- **基於類別的實體**：將粒子、代理、形狀封裝為具有 `update()` + `display()` 方法的類別。
- **離屏緩衝區**：使用 `createGraphics()` 進行分層合成、拖尾效果或遮罩。

### 步驟 4：預覽與迭代

- 直接在瀏覽器中開啟 HTML 檔案 —— 基礎草圖無需伺服器。
- 對於從本地檔案 `loadImage()`/`loadFont()`：使用 `scripts/serve.sh` 或 `python3 -m http.server`。
- 使用 Chrome 開發者工具的效能分頁驗證是否穩定在 60fps。
- 以目標匯出解析度進行測試，而不僅僅是視窗大小。
- 調整參數，直到視覺效果符合步驟 1 的概念。

### 步驟 5：匯出

| 格式 | 方法 | 指令 |
|--------|--------|---------|
| **PNG** | 在 `keyPressed()` 中調用 `saveCanvas('output', 'png')` | 按下 's' 鍵儲存 |
| **高解析度 PNG** | Puppeteer 無頭捕捉 | `node scripts/export-frames.js sketch.html --width 3840 --height 2160 --frames 1` |
| **GIF** | `saveGif('output', 5)` —— 捕捉 N 秒 | 按下 'g' 鍵儲存 |
| **影格序列** | `saveFrames('frame', 'png', 10, 30)` —— 30fps 下的 10 秒 | 隨後使用 `ffmpeg -i frame-%04d.png -c:v libx264 output.mp4` |
| **MP4** | Puppeteer 影格捕捉 + ffmpeg | `bash scripts/render.sh sketch.html output.mp4 --duration 30 --fps 30` |
| **SVG** | 搭配 p5.js-svg 使用 `createCanvas(w, h, SVG)` | `save('output.svg')` |

### 步驟 6：品質驗證

- **是否符合願景？** 將輸出結果與創意概念進行比對。如果看起來很一般，回到步驟 1。
- **解析度檢查**：在目標顯示尺寸下是否清晰？有無鋸齒瑕疵？
- **效能檢查**：在瀏覽器中是否維持 60fps？（動畫至少需 30fps）。
- **色彩檢查**：色彩是否和諧？在亮色和深色螢幕上都進行測試。
- **邊緣案例**：畫布邊緣會發生什麼？調整大小時呢？執行 10 分鐘後呢？

## 關鍵實作注意事項

### 效能 —— 首先停用 FES

友善錯誤系統 (Friendly Error System, FES) 會增加高達 10 倍的開銷。在每個生產環境草圖中停用它：

```javascript
p5.disableFriendlyErrors = true;  // 在 setup() 之前

function setup() {
  pixelDensity(1);  // 防止在 Retina 螢幕上產生 2x-4x 的重複繪製
  createCanvas(1920, 1080);
}
```

在密集迴圈（粒子、像素操作）中，使用 `Math.*` 代替 p5 的封裝函式 —— 速度明顯更快：

```javascript
// 在 draw() 或 update() 的密集路徑中：
let a = Math.sin(t);          // 而非 sin(t)
let r = Math.sqrt(dx*dx+dy*dy); // 而非 dist() —— 或者更好：跳過 sqrt，直接比較 magSq
let v = Math.random();        // 而非 random() —— 當不需要種子時
let m = Math.min(a, b);       // 而非 min(a, b)
```

絕不要在 `draw()` 內部使用 `console.log()`。絕不要在 `draw()` 內部操作 DOM。請參閱 `references/troubleshooting_zh_TW.md` § 效能。

### 帶種子的隨機性 —— 務必使用

每個生成式草圖必須是可重複的。相同的種子，同樣的輸出。

```javascript
function setup() {
  randomSeed(CONFIG.seed);
  noiseSeed(CONFIG.seed);
  // 現在所有的 random() 與 noise() 調用都是確定性的
}
```

絕不要將 `Math.random()` 用於生成內容 —— 僅用於對效能要求極高的非視覺程式碼。視覺元素一律使用 `random()`。如果您需要隨機種子：`CONFIG.seed = floor(random(99999))`。

### 生成藝術平台支援 (fxhash / Art Blocks)

對於生成藝術平台，將 p5 的 PRNG 替換為平台的確定性隨機：

```javascript
// fxhash 慣例
const SEED = $fx.hash;              // 每枚鑄造唯一
const rng = $fx.rand;               // 確定性 PRNG
$fx.features({ palette: 'warm', complexity: 'high' });

// 在 setup() 中：
randomSeed(SEED);   // 用於 p5 的 noise()
noiseSeed(SEED);

// 使用 rng() 取代 random() 以實現平台確定性
let x = rng() * width;  // 而非 random(width)
```

請參閱 `references/export-pipeline_zh_TW.md` § 平台匯出。

### 色彩模式 —— 使用 HSB

在生成藝術中，HSB (色調、飽和度、亮度) 比 RGB 容易使用得多：

```javascript
colorMode(HSB, 360, 100, 100, 100);
// 現在：fill(hue, sat, bri, alpha)
// 旋轉色調：fill((baseHue + offset) % 360, 80, 90)
// 降低飽和度：fill(hue, sat * 0.3, bri)
// 調暗：fill(hue, sat, bri * 0.5)
```

絕不要硬編碼原始 RGB 數值。定義一個調色盤物件，並透過程序化方式衍生變化。請參閱 `references/color-systems_zh_TW.md`。

### 雜訊 —— 使用多倍頻，而非原始數值

原始的 `noise(x, y)` 看起來像平滑的團塊。疊加倍頻 (Octaves) 以獲得自然的紋理：

```javascript
function fbm(x, y, octaves = 4) {
  let val = 0, amp = 1, freq = 1, sum = 0;
  for (let i = 0; i < octaves; i++) {
    val += noise(x * freq, y * freq) * amp;
    sum += amp;
    amp *= 0.5;
    freq *= 2;
  }
  return val / sum;
}
```

對於流動的有機形式，使用**域扭曲 (Domain warping)**：將雜訊輸出作為雜訊輸入座標饋送回去。請參閱 `references/visual-effects_zh_TW.md`。

### createGraphics() 用於圖層 —— 這是必須的

扁平的單次渲染看起來很單調。使用離屏緩衝區進行合成：

```javascript
let bgLayer, fgLayer, trailLayer;
function setup() {
  createCanvas(1920, 1080);
  bgLayer = createGraphics(width, height);
  fgLayer = createGraphics(width, height);
  trailLayer = createGraphics(width, height);
}
function draw() {
  renderBackground(bgLayer);
  renderTrails(trailLayer);   // 持久、淡出
  renderForeground(fgLayer);  // 每影格清除
  image(bgLayer, 0, 0);
  image(trailLayer, 0, 0);
  image(fgLayer, 0, 0);
}
```

### 效能 —— 盡可能向量化

p5.js 的繪圖調用代價昂貴。對於成千上萬個粒子：

```javascript
// 慢：個別形狀
for (let p of particles) {
  ellipse(p.x, p.y, p.size);
}

// 快：使用 beginShape() 的單一形狀
beginShape(POINTS);
for (let p of particles) {
  vertex(p.x, p.y);
}
endShape();

// 最快：針對海量數量的像素緩衝區
loadPixels();
for (let p of particles) {
  let idx = 4 * (floor(p.y) * width + floor(p.x));
  pixels[idx] = r; pixels[idx+1] = g; pixels[idx+2] = b; pixels[idx+3] = 255;
}
updatePixels();
```

請參閱 `references/troubleshooting_zh_TW.md` § 效能。

### 實例模式 (Instance Mode) 用於多草圖

全局模式會污染 `window`。對於生產環境，請使用實例模式：

```javascript
const sketch = (p) => {
  p.setup = function() {
    p.createCanvas(800, 800);
  };
  p.draw = function() {
    p.background(0);
    p.ellipse(p.mouseX, p.mouseY, 50);
  };
};
new p5(sketch, 'canvas-container');
```

這是在同一頁面嵌入多個草圖或與框架整合時所必需的。

### WebGL 模式陷阱

- `createCanvas(w, h, WEBGL)` —— 原點在中心，而非左上角。
- Y 軸反轉（在 WEBGL 中正 Y 向上，在 P2D 中向下）。
- `translate(-width/2, -height/2)` 以獲得類似 P2D 的座標。
- 每個變換周圍都要加上 `push()`/`pop()` —— 矩陣堆疊會靜默溢出。
- `texture()` 必須在 `rect()`/`plane()` 之前，而非之後。
- 自定義著色器：`createShader(vert, frag)` —— 請在多種瀏覽器上進行測試。

### 匯出 —— 快捷鍵慣例

每個草圖都應在 `keyPressed()` 中包含以下內容：

```javascript
function keyPressed() {
  if (key === 's' || key === 'S') saveCanvas('output', 'png');
  if (key === 'g' || key === 'G') saveGif('output', 5);
  if (key === 'r' || key === 'R') { randomSeed(millis()); noiseSeed(millis()); }
  if (key === ' ') CONFIG.paused = !CONFIG.paused;
}
```

### 無頭影片匯出 —— 使用 noLoop()

對於透過 Puppeteer 進行的無頭渲染，草圖**必須**在 setup 中使用 `noLoop()`。若不使用，p5 的繪圖迴圈會自由執行，而截圖速度較慢 —— 草圖會跑在前面，導致影格遺漏或重複。

```javascript
function setup() {
  createCanvas(1920, 1080);
  pixelDensity(1);
  noLoop();                    // 捕捉腳本控制影格推進
  window._p5Ready = true;      // 向捕捉腳本發出就緒訊號
}
```

隨附的 `scripts/export-frames.js` 會偵測 `_p5Ready` 並在每次捕捉時調用一次 `redraw()`，以實現精確的 1:1 影格對應。請參閱 `references/export-pipeline_zh_TW.md` § 確定性捕捉。

對於多場景影片，使用「每片段架構」：每個場景一個 HTML，獨立渲染，再用 `ffmpeg -f concat` 拼接。請參閱 `references/export-pipeline_zh_TW.md` § 每片段架構。

### 代理程式工作流

建構 p5.js 草圖時：

1. **編寫 HTML 檔案** —— 單一自包含檔案，所有程式碼內聯。
2. **在瀏覽器中開啟** —— `open sketch.html` (macOS) 或 `xdg-open sketch.html` (Linux)。
3. **本地資源**（字體、圖片）需要伺服器：在專案目錄執行 `python3 -m http.server 8080`，然後開啟 `http://localhost:8080/sketch.html`。
4. **匯出 PNG/GIF** —— 如上所示添加 `keyPressed()` 快捷鍵，告知使用者按下哪個鍵。
5. **無頭匯出** —— 執行 `node scripts/export-frames.js sketch.html --frames 300` 進行自動化影格捕捉（草圖必須使用 `noLoop()` + `_p5Ready`）。
6. **MP4 渲染** —— `bash scripts/render.sh sketch.html output.mp4 --duration 30`。
7. **迭代精進** —— 編輯 HTML 檔案，使用者重新整理瀏覽器即可查看變更。
8. **按需載入參考資料** —— 在實作過程中，使用 `skill_view(name="p5js", file_path="references/...")` 載入特定的參考檔案。

## 效能目標

| 指標 | 目標 |
|--------|--------|
| 影格率 (互動式) | 持續 60fps |
| 影格率 (動畫匯出) | 至少 30fps |
| 粒子數量 (P2D 形狀) | 60fps 下約 5,000-10,000 |
| 粒子數量 (像素緩衝區) | 60fps 下約 50,000-100,000 |
| 畫布解析度 | 最高 3840x2160 (匯出), 1920x1080 (互動式) |
| 檔案大小 (HTML) | < 100KB (不含 CDN 程式庫) |
| 載入時間 | 首影格 < 2 秒 |

## 參考資料

| 檔案 | 內容 |
|------|----------|
| `references/core-api_zh_TW.md` | 畫布設定、座標系統、繪圖迴圈、`push()`/`pop()`、離屏緩衝區、構圖模式、`pixelDensity()`、響應式設計 |
| `references/shapes-and-geometry_zh_TW.md` | 2D 原語、`beginShape()`/`endShape()`、貝茲/Catmull-Rom 曲線、`vertex()` 系統、自定義形狀、`p5.Vector`、有號距離場 (SDF)、SVG 路徑轉換 |
| `references/visual-effects_zh_TW.md` | 雜訊 (Perlin, 分形, 域扭曲, Curl)、流場、粒子系統 (物理, 群聚, 軌跡)、像素操作、紋理生成 (點刻, 陰影線, 半色調)、回饋迴圈、反應擴散 |
| `references/animation_zh_TW.md` | 基於影格的動畫、緩動函式、`lerp()`/`map()`、彈簧物理、狀態機、時間軸序列、基於 `millis()` 的時機控制、轉場模式 |
| `references/typography_zh_TW.md` | `text()`, `loadFont()`, `textToPoints()`, 動態排版, 文字遮罩, 字體度量, 響應式文字大小 |
| `references/color-systems_zh_TW.md` | `colorMode()`, HSB/HSL/RGB, `lerpColor()`, `paletteLerp()`, 程序化調色盤, 色彩和諧, `blendMode()`, 漸層渲染, 精選調色盤庫 |
| `references/webgl-and-3d_zh_TW.md` | WEBGL 渲染器, 3D 原語, 攝影機, 燈光, 材質, 自定義幾何體, GLSL 著色器 (`createShader()`, `createFilterShader()`), 幀緩衝區, 後處理 |
| `references/interaction_zh_TW.md` | 滑鼠事件, 鍵盤狀態, 觸控輸入, DOM 元素, `createSlider()`/`createButton()`, 音訊輸入 (p5.sound FFT/振幅), 捲動驅動動畫, 響應式事件 |
| `references/export-pipeline_zh_TW.md` | `saveCanvas()`, `saveGif()`, `saveFrames()`, 確定性無頭捕捉, ffmpeg 影格轉影片, CCapture.js, SVG 匯出, 每片段架構, 平台匯出 (fxhash), 影片常見陷阱 |
| `references/troubleshooting_zh_TW.md` | 效能分析, 每像素預算, 常見錯誤, 瀏覽器相容性, WebGL 偵錯, 字體載入問題, 像素密度陷阱, 記憶體洩漏, CORS |
| `templates/viewer.html` | 互動式檢視器範本：種子導覽（前/後/隨機/跳轉）、參數滑桿、下載 PNG、響應式畫布。從此範本開始製作可探索的生成藝術。 |

---

## 創意發散（僅在使用者要求實驗性/創意/獨特輸出時使用）

如果使用者要求創意性、實驗性、令人驚訝或非傳統的輸出，請選擇最合適的策略，並在生成程式碼之前先理清步驟。

- **概念融合 (Conceptual Blending)** —— 當使用者命名兩樣東西進行結合或想要混合美學時。
- **SCAMPER** —— 當使用者想要對已知的生成藝術模式進行改動時。
- **遠程關聯 (Distance Association)** —— 當使用者給出單一概念並希望探索時（例如「做一些關於時間的東西」）。

### 概念融合
1. 命名兩個截然不同的視覺系統（例如：粒子物理 + 手寫書法）。
2. 建立對應關係（粒子 = 墨水滴，作用力 = 筆觸壓力，場 = 字母形狀）。
3. 有選擇地融合 —— 保留能產生有趣突發視覺效果的映射。
4. 將融合編寫為一個統一的系統，而非並排的兩個系統。

### SCAMPER 轉化
拿一個已知的生成模式（流場、粒子系統、L-系統、細胞自動機）並有系統地進行轉化：
- **替代 (Substitute)**：用文字字元替換圓形，用漸層替換線條。
- **組合 (Combine)**：合併兩種模式（流場 + Voronoi）。
- **適應 (Adapt)**：將 2D 模式套用到 3D 投影上。
- **修改 (Modify)**：誇張化比例，扭曲座標空間。
- **用途 (Purpose)**：將物理模擬用於排版，將排序演算法用於色彩。
- **消除 (Eliminate)**：移除網格、移除顏色、移除對稱性。
- **反轉 (Reverse)**：反向執行模擬，反轉參數空間。

### 遠程關聯
1. 以使用者的概念為錨點（例如「孤獨」）。
2. 在三個距離層級生成關聯：
   - 近距離（顯而易見）：空房間、單一人物、沉默。
   - 中距離（有趣）：魚群中逆向游動的一條魚、沒有通知的手機、地鐵車廂間的空隙。
   - 遠距離（抽象）：質數、漸近曲線、凌晨三點的顏色。
3. 開發中距離的關聯 —— 它們足夠具體以便視覺化，但又足夠意外而顯得有趣。
