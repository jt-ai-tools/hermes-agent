# 著色器流水線與可組合效果 (Shader Pipeline & Composable Effects)

這是在字元渲染之後、編碼之前，應用於像素畫布 (`numpy uint8 陣列，形狀為 (H,W,3)`) 的後處理效果。本文件亦涵蓋了**像素級混合模式**、**回饋緩衝區 (Feedback buffers)** 以及 **ShaderChain** 合成器。

> **另請參閱：** [composition_zh_TW.md](composition_zh_TW.md) (混合模式, 色調映射) · [effects_zh_TW.md](effects_zh_TW.md) · [scenes_zh_TW.md](scenes_zh_TW.md) · [architecture_zh_TW.md](architecture_zh_TW.md) · [optimization_zh_TW.md](optimization_zh_TW.md) · [troubleshooting_zh_TW.md](troubleshooting_zh_TW.md)
>
> **混合模式：** 有關 20 種像素混合模式與 `blend_canvas()`，請參閱 `composition_zh_TW.md`。所有的混合操作均使用 `blend_canvas(base, top, mode, opacity)`。

## 設計理念

著色器流水線能將原始的 ASCII 渲染結果轉化為電影質感的輸出。系統設計的核心在於**可組合性** —— 每個著色器、混合模式和回饋變換都是獨立的構建塊。透過組合這少數的原語，可以創造出無限的視覺變化。

根據氛圍選擇合適的著色器：
- **復古終端機**：CRT + 掃描線 + 顆粒感 + 綠色/琥珀色調
- **簡潔現代**：僅使用輕微的 Bloom + 細微暈影 (Vignette)
- **故障藝術 (Glitch art)**：強烈色差 + 故障條帶 + 色彩晃動 + 像素排序
- **電影感**：Bloom + 暈影 + 顆粒感 + 調色
- **夢幻**：強烈 Bloom + 柔焦 + 色彩晃動 + 低對比
- **粗獷/工業**：高對比 + 顆粒感 + 掃描線 + 無 Bloom
- **迷幻**：色彩晃動 + 色差 + 萬花筒鏡像 + 高飽和度 + 帶有色調偏移的回饋
- **數據損壞**：像素排序 + 數據彎曲 + 區塊故障 + 海報化
- **遞迴/無限**：帶有縮放的回饋緩衝區 + Screen 混合 + 色調偏移

---

## 像素級混合模式 (Pixel-Level Blend Modes)

為了確保精確度，所有模式都在 float32 [0,1] 的畫布上運作。請使用 `blend_canvas(base, top, mode, opacity)`，它會自動處理 uint8 與 float 之間的轉換。

### 可用模式

```python
BLEND_MODES = {
    "normal":       lambda a, b: b,
    "add":          lambda a, b: np.clip(a + b, 0, 1),
    "subtract":     lambda a, b: np.clip(a - b, 0, 1),
    "multiply":     lambda a, b: a * b,
    "screen":       lambda a, b: 1 - (1-a)*(1-b),
    "overlay":      # a<0.5 為 2*a*b, 否則為 1-2*(1-a)*(1-b)
    "softlight":    lambda a, b: (1-2*b)*a*a + 2*b*a,
    "hardlight":    # 類似 overlay 但以 b 為基準
    "difference":   lambda a, b: abs(a - b),
    "exclusion":    lambda a, b: a + b - 2*a*b,
    "colordodge":   lambda a, b: a / (1-b),
    "colorburn":    lambda a, b: 1 - (1-a)/b,
    "linearlight":  lambda a, b: a + 2*b - 1,
    "vividlight":   # b<0.5 為加深, b>=0.5 為加亮
    "pin_light":    # b<0.5 為 min(a,2b), b>=0.5 為 max(a,2b-1)
    "hard_mix":     lambda a, b: 1 if a+b>=1 else 0,
    "lighten":      lambda a, b: max(a, b),
    "darken":       lambda a, b: min(a, b),
    "grain_extract": lambda a, b: a - b + 0.5,
    "grain_merge":  lambda a, b: a + b - 0.5,
}
```

### 用法

```python
def blend_canvas(base, top, mode="normal", opacity=1.0):
    """使用指定的混合模式與不透明度混合兩張 uint8 畫布 (H,W,3)。"""
    af = base.astype(np.float32) / 255.0
    bf = top.astype(np.float32) / 255.0
    result = BLEND_MODES[mode](af, bf)
    if opacity < 1.0:
        result = af * (1-opacity) + result * opacity
    return np.clip(result * 255, 0, 255).astype(np.uint8)

# 多圖層合成
result = blend_canvas(base, layer_a, "screen", 0.7)
result = blend_canvas(result, layer_b, "difference", 0.5)
result = blend_canvas(result, layer_c, "multiply", 0.3)
```

### 創意組合

- **回饋 + Difference** = 迷幻的色彩演化（每影格與前一格進行 XOR 運算）
- **Screen + Screen** = 加法發光效果的疊加
- **Multiply** 應用於兩個不同的效果 = 僅在兩者皆亮處顯示內容（交集）
- **Exclusion** 應用於兩個圖層 = 在兩者差異處產生互補色圖案
- **Color dodge/burn** = 在重疊區域產生極端的對比度增強
- **Hard mix** = 在相交處將一切簡化為純黑/白/飽和色

---

## 回饋緩衝區 (Feedback Buffer)

遞迴的時間效果：將第 N-1 格影格連同衰減及選用的空間變換饋送回第 N 格影格。用於產生軌跡、迴聲、抹除、縮放隧道、旋轉回饋以及彩虹軌跡。

```python
class FeedbackBuffer:
    def __init__(self):
        self.buf = None  # 前一格影格 (float32, 0-1)
    
    def apply(self, canvas, decay=0.85, blend="screen", opacity=0.5,
              transform=None, transform_amt=0.02, hue_shift=0.0):
        """將當前影格與衰減/變換後的前一格影格混合。
        
        參數：
            canvas: 當前影格 (uint8 H,W,3)
            decay: 舊影格淡出的速度 (0=即時, 1=永久保留)
            blend: 混合回饋的混合模式
            opacity: 回饋混合的強度
            transform: None, "zoom", "shrink", "rotate_cw", "rotate_ccw",
                       "shift_up", "shift_down", "mirror_h"
            transform_amt: 每影格空間變換的強度
            hue_shift: 每影格旋轉回饋緩衝區的色調 (0-1)
        """
```

### 回饋預設值 (Feedback Presets)

```python
# 無限縮放隧道
fb_cfg = {"decay": 0.8, "blend": "screen", "opacity": 0.4,
          "transform": "zoom", "transform_amt": 0.015}

# 彩虹軌跡 (迷幻風格)
fb_cfg = {"decay": 0.7, "blend": "screen", "opacity": 0.3,
          "transform": "zoom", "transform_amt": 0.01, "hue_shift": 0.02}

# 幽靈迴聲 (恐怖風格)
fb_cfg = {"decay": 0.9, "blend": "add", "opacity": 0.15,
          "transform": "shift_up", "transform_amt": 0.01}

# 萬花筒遞迴
fb_cfg = {"decay": 0.75, "blend": "screen", "opacity": 0.35,
          "transform": "rotate_cw", "transform_amt": 0.005, "hue_shift": 0.01}

# 色彩演化 (抽象風格)
fb_cfg = {"decay": 0.8, "blend": "difference", "opacity": 0.4, "hue_shift": 0.03}

# 疊加深度 (Multiplied depth)
fb_cfg = {"decay": 0.65, "blend": "multiply", "opacity": 0.3, "transform": "mirror_h"}

# 上升熱浪
fb_cfg = {"decay": 0.5, "blend": "add", "opacity": 0.2,
          "transform": "shift_up", "transform_amt": 0.02}
```

---

## ShaderChain

可組合的著色器流水線。使用具名著色器及參數構建鏈條。順序很重要 —— 著色器會依序套用於畫布。

```python
class ShaderChain:
    """可組合的著色器流水線。
    
    用法：
        chain = ShaderChain()
        chain.add("bloom", thr=120)
        chain.add("chromatic", amt=5)
        chain.add("kaleidoscope", folds=6)
        chain.add("vignette", s=0.2)
        chain.add("grain", amt=12)
        canvas = chain.apply(canvas, f=features, t=time)
    """
    def __init__(self):
        self.steps = []

    def add(self, shader_name, **kwargs):
        self.steps.append((shader_name, kwargs))
        return self  # 支援鏈式調用

    def apply(self, canvas, f=None, t=0):
        if f is None: f = {}
        for name, kwargs in self.steps:
            canvas = _apply_shader_step(canvas, name, kwargs, f, t)
        return canvas
```

### `_apply_shader_step()` —— 完整分發函式

將著色器名稱路由至具體實作。某些著色器具備**音訊反應式縮放** —— 分發函式會讀取 `f["bdecay"]` 和 `f["rms"]` 來隨節拍調變參數。

```python
def _apply_shader_step(canvas, name, kwargs, f, t):
    """依名稱與參數分發單個著色器。
    
    參數：
        canvas: uint8 (H,W,3) 像素陣列
        name: 著色器鍵值字串 (例如 "bloom", "chromatic")
        kwargs: 著色器參數字典
        f: 音訊特徵字典 (鍵：bdecay, rms, sub 等)
        t: 當前時間 (float, 秒)
    返回：
        canvas: uint8 (H,W,3) — 處理後的畫布
    """
    bd = f.get("bdecay", 0)    # 節拍衰減 (0-1, 節拍處數值高)
    rms = f.get("rms", 0.3)   # 音訊能量 (0-1)

    # --- 幾何 (Geometry) ---
    if name == "crt":
        return sh_crt(canvas, kwargs.get("strength", 0.05))
    elif name == "pixelate":
        return sh_pixelate(canvas, kwargs.get("block", 4))
    elif name == "wave_distort":
        return sh_wave_distort(canvas, t,
            kwargs.get("freq", 0.02), kwargs.get("amp", 8), kwargs.get("axis", "x"))
    elif name == "kaleidoscope":
        return sh_kaleidoscope(canvas.copy(), kwargs.get("folds", 6))
    elif name == "mirror_h":
        return sh_mirror_h(canvas.copy())
    elif name == "mirror_v":
        return sh_mirror_v(canvas.copy())
    elif name == "mirror_quad":
        return sh_mirror_quad(canvas.copy())
    elif name == "mirror_diag":
        return sh_mirror_diag(canvas.copy())

    # --- 通道 (Channel) ---
    elif name == "chromatic":
        base = kwargs.get("amt", 3)
        return sh_chromatic(canvas, max(1, int(base * (0.4 + bd * 0.8))))
    elif name == "channel_shift":
        return sh_channel_shift(canvas,
            kwargs.get("r", (0,0)), kwargs.get("g", (0,0)), kwargs.get("b", (0,0)))
    elif name == "channel_swap":
        return sh_channel_swap(canvas, kwargs.get("order", (2,1,0)))
    elif name == "rgb_split_radial":
        return sh_rgb_split_radial(canvas, kwargs.get("strength", 5))

    # --- 色彩 (Color) ---
    elif name == "invert":
        return sh_invert(canvas)
    elif name == "posterize":
        return sh_posterize(canvas, kwargs.get("levels", 4))
    elif name == "threshold":
        return sh_threshold(canvas, kwargs.get("thr", 128))
    elif name == "solarize":
        return sh_solarize(canvas, kwargs.get("threshold", 128))
    elif name == "hue_rotate":
        return sh_hue_rotate(canvas, kwargs.get("amount", 0.1))
    elif name == "saturation":
        return sh_saturation(canvas, kwargs.get("factor", 1.5))
    elif name == "color_grade":
        return sh_color_grade(canvas, kwargs.get("tint", (1,1,1)))
    elif name == "color_wobble":
        return sh_color_wobble(canvas, t, kwargs.get("amt", 0.3) * (0.5 + rms * 0.8))
    elif name == "color_ramp":
        return sh_color_ramp(canvas, kwargs.get("ramp", [(0,0,0),(255,255,255)]))

    # --- 發光 / 模糊 (Glow / Blur) ---
    elif name == "bloom":
        return sh_bloom(canvas, kwargs.get("thr", 130))
    elif name == "edge_glow":
        return sh_edge_glow(canvas, kwargs.get("hue", 0.5))
    elif name == "soft_focus":
        return sh_soft_focus(canvas, kwargs.get("strength", 0.3))
    elif name == "radial_blur":
        return sh_radial_blur(canvas, kwargs.get("strength", 0.03))

    # --- 雜訊 (Noise) ---
    elif name == "grain":
        return sh_grain(canvas, int(kwargs.get("amt", 10) * (0.5 + rms * 0.8)))
    elif name == "static":
        return sh_static_noise(canvas, kwargs.get("density", 0.05), kwargs.get("color", True))

    # --- 線條 / 圖案 (Lines / Patterns) ---
    elif name == "scanlines":
        return sh_scanlines(canvas, kwargs.get("intensity", 0.08), kwargs.get("spacing", 3))
    elif name == "halftone":
        return sh_halftone(canvas, kwargs.get("dot_size", 6))

    # --- 調階 (Tone) ---
    elif name == "vignette":
        return sh_vignette(canvas, kwargs.get("s", 0.22))
    elif name == "contrast":
        return sh_contrast(canvas, kwargs.get("factor", 1.3))
    elif name == "gamma":
        return sh_gamma(canvas, kwargs.get("gamma", 1.5))
    elif name == "levels":
        return sh_levels(canvas,
            kwargs.get("black", 0), kwargs.get("white", 255), kwargs.get("midtone", 1.0))
    elif name == "brightness":
        return sh_brightness(canvas, kwargs.get("factor", 1.5))

    # --- 故障 / 數據 (Glitch / Data) ---
    elif name == "glitch_bands":
        return sh_glitch_bands(canvas, f)
    elif name == "block_glitch":
        return sh_block_glitch(canvas, kwargs.get("n_blocks", 8), kwargs.get("max_size", 40))
    elif name == "pixel_sort":
        return sh_pixel_sort(canvas, kwargs.get("threshold", 100), kwargs.get("direction", "h"))
    elif name == "data_bend":
        return sh_data_bend(canvas, kwargs.get("offset", 1000), kwargs.get("chunk", 500))

    else:
        return canvas  # 未知著色器 — 直接通過
```

### 音訊反應式著色器

有三種著色器會根據音訊特徵縮放其參數：

| 著色器 | 反應特徵 | 效果 |
|--------|------------|--------|
| `chromatic` | `bdecay` | `amt * (0.4 + bdecay * 0.8)` — 色差隨節拍跳動 |
| `color_wobble` | `rms` | `amt * (0.5 + rms * 0.8)` — 晃動強度隨能量變化 |
| `grain` | `rms` | `amt * (0.5 + rms * 0.8)` — 響亮處顆粒感更粗糙 |
| `glitch_bands` | `bdecay`, `sub` | 條帶數量與位移量隨節拍能量縮放 |

若要使任何著色器具備節拍反應，請在分發函式中對其參數進行縮放：`base_val * (low + bd * range)`。

---

## 完整著色器目錄 (Full Shader Catalog)

### 幾何著色器 (Geometry Shaders)

| 著色器 | 關鍵參數 | 描述 |
|--------|-----------|-------------|
| `crt` | `strength=0.05` | CRT 桶形畸變 (快取 remap) |
| `pixelate` | `block=4` | 降低有效解析度 |
| `wave_distort` | `freq, amp, axis` | 正弦曲線式行/列位移 |
| `kaleidoscope` | `folds=6` | 透過極座標重新映射實現徑向對稱 |
| `mirror_h` | — | 水平鏡像 |
| `mirror_v` | — | 垂直鏡像 |
| `mirror_quad` | — | 四分鏡像 |
| `mirror_diag` | — | 對角線鏡像 |

### 通道操作 (Channel Manipulation)

| 著色器 | 關鍵參數 | 描述 |
|--------|-----------|-------------|
| `chromatic` | `amt=3` | R/B 通道水平偏移 (節拍反應式) |
| `channel_shift` | `r=(sx,sy), g, b` | 各通道獨立的 x,y 偏移 |
| `channel_swap` | `order=(2,1,0)` | 重排 RGB 通道 (BGR, GRB 等) |
| `rgb_split_radial` | `strength=5` | 自中心向外的放射狀色差 |

### 色彩操作 (Color Manipulation)

| 著色器 | 關鍵參數 | 描述 |
|--------|-----------|-------------|
| `invert` | — | 反轉所有色彩 |
| `posterize` | `levels=4` | 將色深降低至 N 個層級 |
| `threshold` | `thr=128` | 二進位黑白化 |
| `solarize` | `threshold=128` | 反轉高於閥值的像素 |
| `hue_rotate` | `amount=0.1` | 旋轉所有色調 (0-1) |
| `saturation` | `factor=1.5` | 縮放飽和度 (>1=增加, <1=降低) |
| `color_grade` | `tint=(r,g,b)` | 各通道乘數 |
| `color_wobble` | `amt=0.3` | 隨時間變化的各通道正弦調變 |
| `color_ramp` | `ramp=[(R,G,B),...]` | 將亮度映射至自定義色彩漸層 |

### 發光 / 模糊 (Glow / Blur)

| 著色器 | 關鍵參數 | 描述 |
|--------|-----------|-------------|
| `bloom` | `thr=130` | 亮部發光 (4x 下取樣 + 方框模糊) |
| `edge_glow` | `hue=0.5` | 偵測邊緣並加上彩色疊加 |
| `soft_focus` | `strength=0.3` | 與模糊版本進行混合 |
| `radial_blur` | `strength=0.03` | 自中心向外的縮放模糊 |

### 雜訊 / 顆粒 (Noise / Grain)

| 著色器 | 關鍵參數 | 描述 |
|--------|-----------|-------------|
| `grain` | `amt=10` | 2x 下取樣電影顆粒 (節拍反應式) |
| `static` | `density=0.05, color=True` | 隨機像素雜訊 (電視靜電) |

### 線條 / 圖案 (Lines / Patterns)

| 著色器 | 關鍵參數 | 描述 |
|--------|-----------|-------------|
| `scanlines` | `intensity=0.08, spacing=3` | 調暗每隔 N 行的像素 |
| `halftone` | `dot_size=6` | 疊加半色調圓點圖案 |

### 調階 (Tone)

| 著色器 | 關鍵參數 | 描述 |
|--------|-----------|-------------|
| `vignette` | `s=0.22` | 邊緣調暗 (快取距離場) |
| `contrast` | `factor=1.3` | 以 128 為中心調整對比度 |
| `gamma` | `gamma=1.5` | Gamma 校正 (>1=中間調變亮) |
| `levels` | `black, white, midtone` | 色階調整 (類似 Photoshop) |
| `brightness` | `factor=1.5` | 全局亮度乘數 |

### 故障 / 數據 (Glitch / Data)

| 著色器 | 關鍵參數 | 描述 |
|--------|-----------|-------------|
| `glitch_bands` | (使用 `f`) | 節拍反應式水平行位移 |
| `block_glitch` | `n_blocks=8, max_size=40` | 隨機矩形區塊位移 |
| `pixel_sort` | `threshold=100, direction="h"` | 在連續亮部按亮度排序像素 |
| `data_bend` | `offset, chunk` | 原始位元組位移 (Datamoshing 瑕疵) |

---

## 著色器實作 (Shader Implementations)

每個著色器函式接收一個畫布 (`uint8 H,W,3`) 並返回相同形狀的畫布。命名慣例為 `sh_<名稱>`。建立座標重新映射表的幾何著色器應**快取**該表，因為它僅取決於解析度與參數，與影格內容無關。

### 輔助函式 (Helpers)

處理色調/飽和度的著色器需要向量化的 HSV 轉換：

```python
def rgb2hsv(r, g, b):
    """向量化 RGB (0-255 uint8) -> HSV (float32 0-1)。"""
    rf = r.astype(np.float32) / 255.0
    gf = g.astype(np.float32) / 255.0
    bf = b.astype(np.float32) / 255.0
    cmax = np.maximum(np.maximum(rf, gf), bf)
    cmin = np.minimum(np.minimum(rf, gf), bf)
    delta = cmax - cmin + 1e-10
    h = np.zeros_like(rf)
    m = cmax == rf; h[m] = ((gf[m] - bf[m]) / delta[m]) % 6
    m = cmax == gf; h[m] = (bf[m] - rf[m]) / delta[m] + 2
    m = cmax == bf; h[m] = (rf[m] - gf[m]) / delta[m] + 4
    h = h / 6.0 % 1.0
    s = np.where(cmax > 0, delta / (cmax + 1e-10), 0)
    return h, s, cmax

def hsv2rgb(h, s, v):
    """向量化 HSV->RGB。h,s,v 為 numpy float32 陣列。"""
    h = h % 1.0
    c = v * s; x = c * (1 - np.abs((h * 6) % 2 - 1)); m = v - c
    r = np.zeros_like(h); g = np.zeros_like(h); b = np.zeros_like(h)
    mask = h < 1/6;            r[mask]=c[mask]; g[mask]=x[mask]
    mask = (h>=1/6)&(h<2/6);   r[mask]=x[mask]; g[mask]=c[mask]
    mask = (h>=2/6)&(h<3/6);   g[mask]=c[mask]; b[mask]=x[mask]
    mask = (h>=3/6)&(h<4/6);   g[mask]=x[mask]; b[mask]=c[mask]
    mask = (h>=4/6)&(h<5/6);   r[mask]=x[mask]; b[mask]=c[mask]
    mask = h >= 5/6;            r[mask]=c[mask]; b[mask]=x[mask]
    R = np.clip((r+m)*255, 0, 255).astype(np.uint8)
    G = np.clip((g+m)*255, 0, 255).astype(np.uint8)
    B = np.clip((b+m)*255, 0, 255).astype(np.uint8)
    return R, G, B

def mkc(R, G, B, rows, cols):
    """將 R,G,B uint8 陣列堆疊為 (rows,cols,3) 畫布。"""
    o = np.zeros((rows, cols, 3), dtype=np.uint8)
    o[:,:,0] = R; o[:,:,1] = G; o[:,:,2] = B
    return o
```

---

### 幾何著色器 (Geometry Shaders)

#### CRT 桶形畸變
快取座標重新映射 —— 每一格影格都不會改變：
```python
_crt_cache = {}
def sh_crt(c, strength=0.05):
    k = (c.shape[0], c.shape[1], round(strength, 3))
    if k not in _crt_cache:
        h, w = c.shape[:2]; cy, cx = h/2, w/2
        Y = np.arange(h, dtype=np.float32)[:, None]
        X = np.arange(w, dtype=np.float32)[None, :]
        ny = (Y - cy) / cy; nx = (X - cx) / cx
        r2 = nx**2 + ny**2
        factor = 1 + strength * r2
        sx = np.clip((nx * factor * cx + cx), 0, w-1).astype(np.int32)
        sy = np.clip((ny * factor * cy + cy), 0, h-1).astype(np.int32)
        _crt_cache[k] = (sy, sx)
    sy, sx = _crt_cache[k]
    return c[sy, sx]
```

#### 像素化 (Pixelate)
```python
def sh_pixelate(c, block=4):
    """降低有效解析度。"""
    sm = c[::block, ::block]
    return np.repeat(np.repeat(sm, block, axis=0), block, axis=1)[:c.shape[0], :c.shape[1]]
```

#### 波浪扭曲 (Wave Distort)
```python
def sh_wave_distort(c, t, freq=0.02, amp=8, axis="x"):
    """正弦曲線式行/列位移。使用時間 t 進行動畫處理。"""
    h, w = c.shape[:2]
    out = c.copy()
    if axis == "x":
        for y in range(h):
            shift = int(amp * math.sin(y * freq + t * 3))
            out[y] = np.roll(c[y], shift, axis=0)
    else:
        for x in range(w):
            shift = int(amp * math.sin(x * freq + t * 3))
            out[:, x] = np.roll(c[:, x], shift, axis=0)
    return out
```

#### 位移貼圖 (Displacement Map)
```python
def sh_displacement_map(c, dx_map, dy_map, strength=10):
    """使用 float32 位移貼圖 (與 c 同尺寸) 位移像素。
    dx_map/dy_map: 正值表示向右/下偏移。"""
    h, w = c.shape[:2]
    Y = np.arange(h)[:, None]; X = np.arange(w)[None, :]
    ny = np.clip((Y + (dy_map * strength).astype(int)), 0, h-1)
    nx = np.clip((X + (dx_map * strength).astype(int)), 0, w-1)
    return c[ny, nx]
```

#### 萬花筒 (Kaleidoscope)
```python
def sh_kaleidoscope(c, folds=6):
    """透過極座標重新映射實現徑向對稱。"""
    h, w = c.shape[:2]; cy, cx = h//2, w//2
    Y = np.arange(h, dtype=np.float32)[:, None] - cy
    X = np.arange(w, dtype=np.float32)[None, :] - cx
    angle = np.arctan2(Y, X)
    dist = np.sqrt(X**2 + Y**2)
    wedge = 2 * np.pi / folds
    folded_angle = np.abs((angle % wedge) - wedge/2)
    ny = np.clip((cy + dist * np.sin(folded_angle)).astype(int), 0, h-1)
    nx = np.clip((cx + dist * np.cos(folded_angle)).astype(int), 0, w-1)
    return c[ny, nx]
```

#### 鏡像變體
```python
def sh_mirror_h(c):
    """水平鏡像 —— 左半部反射到右半部。"""
    w = c.shape[1]; c[:, w//2:] = c[:, :w//2][:, ::-1]; return c

def sh_mirror_v(c):
    """垂直鏡像 —— 上半部反射到下半部。"""
    h = c.shape[0]; c[h//2:, :] = c[:h//2, :][::-1, :]; return c

def sh_mirror_quad(c):
    """四分鏡像 —— 左上角象限反射到四個方位。"""
    h, w = c.shape[:2]; hh, hw = h//2, w//2
    tl = c[:hh, :hw].copy()
    c[:hh, hw:hw+tl.shape[1]] = tl[:, ::-1]
    c[hh:hh+tl.shape[0], :hw] = tl[::-1, :]
    c[hh:hh+tl.shape[0], hw:hw+tl.shape[1]] = tl[::-1, ::-1]
    return c

def sh_mirror_diag(c):
    """對角線鏡像 —— 左上三角形反射。"""
    h, w = c.shape[:2]
    for y in range(h):
        x_cut = int(w * y / h)
        if x_cut > 0 and x_cut < w:
            c[y, x_cut:] = c[y, :x_cut+1][::-1][:w-x_cut]
    return c
```

> **注意：** 鏡像著色器會原地 (in-place) 修改畫布。分發函式會傳遞 `canvas.copy()` 以避免破壞原始內容。

---

### 通道操作著色器 (Channel Manipulation Shaders)

#### 色差 (Chromatic Aberration)
```python
def sh_chromatic(c, amt=3):
    """R/B 通道水平偏移。在分發函式中具備節拍反應 (amt 隨 bdecay 縮放)。"""
    if amt < 1: return c
    a = int(amt)
    o = c.copy()
    o[:, a:, 0] = c[:, :-a, 0]   # 紅色向右偏移
    o[:, :-a, 2] = c[:, a:, 2]   # 藍色向左偏移
    return o
```

#### 通道偏移 (Channel Shift)
```python
def sh_channel_shift(c, r_shift=(0,0), g_shift=(0,0), b_shift=(0,0)):
    """各通道獨立的 x,y 偏移。"""
    o = c.copy()
    for ch_i, (sx, sy) in enumerate([r_shift, g_shift, b_shift]):
        if sx != 0: o[:,:,ch_i] = np.roll(c[:,:,ch_i], sx, axis=1)
        if sy != 0: o[:,:,ch_i] = np.roll(o[:,:,ch_i], sy, axis=0)
    return o
```

#### 通道交換 (Channel Swap)
```python
def sh_channel_swap(c, order=(2,1,0)):
    """重排 RGB 通道。(2,1,0)=BGR, (1,0,2)=GRB 等。"""
    return c[:, :, list(order)]
```

#### RGB 徑向分離 (RGB Split Radial)
```python
def sh_rgb_split_radial(c, strength=5):
    """自中心向外的色差 —— 越往邊緣越強。"""
    h, w = c.shape[:2]; cy, cx = h//2, w//2
    Y = np.arange(h, dtype=np.float32)[:, None]
    X = np.arange(w, dtype=np.float32)[None, :]
    dist = np.sqrt((Y-cy)**2 + (X-cx)**2)
    max_dist = np.sqrt(cy**2 + cx**2)
    factor = dist / max_dist * strength
    dy = ((Y-cy) / (dist+1) * factor).astype(int)
    dx = ((X-cx) / (dist+1) * factor).astype(int)
    out = c.copy()
    ry = np.clip(Y.astype(int)+dy, 0, h-1); rx = np.clip(X.astype(int)+dx, 0, w-1)
    out[:,:,0] = c[ry, rx, 0]  # 紅色向外偏移
    by = np.clip(Y.astype(int)-dy, 0, h-1); bx = np.clip(X.astype(int)-dx, 0, w-1)
    out[:,:,2] = c[by, bx, 2]  # 藍色向內偏移
    return out
```

---

### 色彩操作著色器 (Color Manipulation Shaders)

#### 反相 (Invert)
```python
def sh_invert(c):
    return 255 - c
```

#### 海報化 (Posterize)
```python
def sh_posterize(c, levels=4):
    """降低每個通道的色彩深度至 N 個層級。"""
    step = 256.0 / levels
    return (np.floor(c.astype(np.float32) / step) * step).astype(np.uint8)
```

#### 閥值 (Threshold)
```python
def sh_threshold(c, thr=128):
    """依閥值進行二進位黑白化。"""
    gray = c.astype(np.float32).mean(axis=2)
    out = np.zeros_like(c); out[gray > thr] = 255
    return out
```

#### 曝光過度 (Solarize)
```python
def sh_solarize(c, threshold=128):
    """反轉高於閥值的像素 —— 經典的暗房效果。"""
    o = c.copy(); mask = c > threshold; o[mask] = 255 - c[mask]
    return o
```

#### 色調旋轉 (Hue Rotate)
```python
def sh_hue_rotate(c, amount=0.1):
    """旋轉所有色調 (0-1)。"""
    h, s, v = rgb2hsv(c[:,:,0], c[:,:,1], c[:,:,2])
    h = (h + amount) % 1.0
    R, G, B = hsv2rgb(h, s, v)
    return mkc(R, G, B, c.shape[0], c.shape[1])
```

#### 飽和度 (Saturation)
```python
def sh_saturation(c, factor=1.5):
    """調整飽和度。>1=更鮮豔, <1=更平淡。"""
    h, s, v = rgb2hsv(c[:,:,0], c[:,:,1], c[:,:,2])
    s = np.clip(s * factor, 0, 1)
    R, G, B = hsv2rgb(h, s, v)
    return mkc(R, G, B, c.shape[0], c.shape[1])
```

#### 調色 (Color Grade)
```python
def sh_color_grade(c, tint):
    """各通道乘數。tint=(r_mul, g_mul, b_mul)。"""
    o = c.astype(np.float32)
    o[:,:,0] *= tint[0]; o[:,:,1] *= tint[1]; o[:,:,2] *= tint[2]
    return np.clip(o, 0, 255).astype(np.uint8)
```

#### 色彩晃動 (Color Wobble)
```python
def sh_color_wobble(c, t, amt=0.3):
    """隨時間變化的各通道正弦調變。在分發函式中具備音訊反應 (amt 隨 rms 縮放)。"""
    o = c.astype(np.float32)
    o[:,:,0] *= 1.0 + amt * math.sin(t * 5.0)
    o[:,:,1] *= 1.0 + amt * math.sin(t * 5.0 + 2.09)
    o[:,:,2] *= 1.0 + amt * math.sin(t * 5.0 + 4.19)
    return np.clip(o, 0, 255).astype(np.uint8)
```

#### 色彩映射 (Color Ramp)
```python
def sh_color_ramp(c, ramp_colors):
    """將亮度映射至自定義色彩漸層。
    ramp_colors = (R,G,B) 元組列表，從暗到亮均勻分佈。"""
    gray = c.astype(np.float32).mean(axis=2) / 255.0
    n = len(ramp_colors)
    idx = np.clip(gray * (n-1), 0, n-1.001)
    lo = np.floor(idx).astype(int); hi = np.minimum(lo+1, n-1)
    frac = idx - lo
    ramp = np.array(ramp_colors, dtype=np.float32)
    out = ramp[lo] * (1-frac[:,:,None]) + ramp[hi] * frac[:,:,None]
    return np.clip(out, 0, 255).astype(np.uint8)
```

---

### 發光 / 模糊著色器 (Glow / Blur Shaders)

#### Bloom
```python
def sh_bloom(c, thr=130):
    """亮部發光：4x 下取樣、設定閥值、3 次方框模糊，最後進行濾色 (screen) 混合。"""
    sm = c[::4, ::4].astype(np.float32)
    br = np.where(sm > thr, sm, 0)
    for _ in range(3):
        p = np.pad(br, ((1,1),(1,1),(0,0)), mode="edge")
        br = (p[:-2,:-2]+p[:-2,1:-1]+p[:-2,2:]+p[1:-1,:-2]+p[1:-1,1:-1]+
              p[1:-1,2:]+p[2:,:-2]+p[2:,1:-1]+p[2:,2:]) / 9.0
    bl = np.repeat(np.repeat(br, 4, axis=0), 4, axis=1)[:c.shape[0], :c.shape[1]]
    return np.clip(c.astype(np.float32) + bl * 0.5, 0, 255).astype(np.uint8)
```

#### 邊緣發光 (Edge Glow)
```python
def sh_edge_glow(c, hue=0.5):
    """透過梯度偵測邊緣，並疊加彩色層。"""
    gray = c.astype(np.float32).mean(axis=2)
    gx = np.abs(gray[:, 2:] - gray[:, :-2])
    gy = np.abs(gray[2:, :] - gray[:-2, :])
    ex = np.zeros_like(gray); ey = np.zeros_like(gray)
    ex[:, 1:-1] = gx; ey[1:-1, :] = gy
    edge = np.clip((ex + ey) / 255 * 2, 0, 1)
    R, G, B = hsv2rgb(np.full_like(edge, hue), np.full_like(edge, 0.8), edge * 0.5)
    out = c.astype(np.int16).copy()
    out[:,:,0] = np.clip(out[:,:,0] + R.astype(np.int16), 0, 255)
    out[:,:,1] = np.clip(out[:,:,1] + G.astype(np.int16), 0, 255)
    out[:,:,2] = np.clip(out[:,:,2] + B.astype(np.int16), 0, 255)
    return out.astype(np.uint8)
```

#### 柔焦 (Soft Focus)
```python
def sh_soft_focus(c, strength=0.3):
    """將原始影像與 2x 下取樣的方框模糊版本混合。"""
    sm = c[::2, ::2].astype(np.float32)
    p = np.pad(sm, ((1,1),(1,1),(0,0)), mode="edge")
    bl = (p[:-2,:-2]+p[:-2,1:-1]+p[:-2,2:]+p[1:-1,:-2]+p[1:-1,1:-1]+
          p[1:-1,2:]+p[2:,:-2]+p[2:,1:-1]+p[2:,2:]) / 9.0
    bl = np.repeat(np.repeat(bl, 2, axis=0), 2, axis=1)[:c.shape[0], :c.shape[1]]
    return np.clip(c * (1-strength) + bl * strength, 0, 255).astype(np.uint8)
```

#### 徑向模糊 (Radial Blur)
```python
def sh_radial_blur(c, strength=0.03, center=None):
    """自中心向外的縮放模糊 —— 放射狀動態模糊。"""
    h, w = c.shape[:2]
    cy, cx = center if center else (h//2, w//2)
    Y = np.arange(h, dtype=np.float32)[:, None]
    X = np.arange(w, dtype=np.float32)[None, :]
    out = c.astype(np.float32)
    for s in [strength, strength*2]:
        dy = (Y - cy) * s; dx = (X - cx) * s
        sy = np.clip((Y + dy).astype(int), 0, h-1)
        sx = np.clip((X + dx).astype(int), 0, w-1)
        out += c[sy, sx].astype(np.float32)
    return np.clip(out / 3, 0, 255).astype(np.uint8)
```

---

### 雜訊 / 顆粒著色器 (Noise / Grain Shaders)

#### 電影顆粒 (Film Grain)
```python
def sh_grain(c, amt=10):
    """2x 下取樣的電影顆粒。在分發函式中具備音訊反應 (amt 隨 rms 縮放)。"""
    noise = np.random.randint(-amt, amt+1, (c.shape[0]//2, c.shape[1]//2, 1), dtype=np.int16)
    noise = np.repeat(np.repeat(noise, 2, axis=0), 2, axis=1)[:c.shape[0], :c.shape[1]]
    return np.clip(c.astype(np.int16) + noise, 0, 255).astype(np.uint8)
```

#### 靜電雜訊 (Static Noise)
```python
def sh_static_noise(c, density=0.05, color=True):
    """疊加隨機像素雜訊 (電視靜電)。"""
    mask = np.random.random((c.shape[0]//2, c.shape[1]//2)) < density
    mask = np.repeat(np.repeat(mask, 2, axis=0), 2, axis=1)[:c.shape[0], :c.shape[1]]
    out = c.copy()
    if color:
        noise = np.random.randint(0, 256, (c.shape[0], c.shape[1], 3), dtype=np.uint8)
    else:
        v = np.random.randint(0, 256, (c.shape[0], c.shape[1]), dtype=np.uint8)
        noise = np.stack([v, v, v], axis=2)
    out[mask] = noise[mask]
    return out
```

---

### 線條 / 圖案著色器 (Lines / Pattern Shaders)

#### 掃描線 (Scanlines)
```python
def sh_scanlines(c, intensity=0.08, spacing=3):
    """調暗每隔 N 行的像素。"""
    m = np.ones(c.shape[0], dtype=np.float32)
    m[::spacing] = 1.0 - intensity
    return np.clip(c * m[:, None, None], 0, 255).astype(np.uint8)
```

#### 半色調 (Halftone)
```python
def sh_halftone(c, dot_size=6):
    """疊加半色調圓點圖案 —— 圓點大小取決於局部亮度。"""
    h, w = c.shape[:2]
    gray = c.astype(np.float32).mean(axis=2) / 255.0
    out = np.zeros_like(c)
    for y in range(0, h, dot_size):
        for x in range(0, w, dot_size):
            block = gray[y:y+dot_size, x:x+dot_size]
            if block.size == 0: continue
            radius = block.mean() * dot_size * 0.5
            cy_b, cx_b = dot_size//2, dot_size//2
            for dy in range(min(dot_size, h-y)):
                for dx in range(min(dot_size, w-x)):
                    if math.sqrt((dy-cy_b)**2 + (dx-cx_b)**2) < radius:
                        out[y+dy, x+dx] = c[y+dy, x+dx]
    return out
```

> **效能提示：** 由於使用了 Python 迴圈，半色調運算速度較慢。適用於小解析度或單張測試影格。對於生產環境，請考慮使用預計算距離遮罩的向量化版本。

---

### 調階著色器 (Tone Shaders)

#### 暈影 (Vignette)
```python
_vig_cache = {}
def sh_vignette(c, s=0.22):
    """使用快取距離場調暗邊緣。"""
    k = (c.shape[0], c.shape[1], round(s, 2))
    if k not in _vig_cache:
        h, w = c.shape[:2]
        Y = np.linspace(-1, 1, h)[:, None]; X = np.linspace(-1, 1, w)[None, :]
        _vig_cache[k] = np.clip(1.0 - np.sqrt(X**2 + Y**2) * s, 0.15, 1).astype(np.float32)
    return np.clip(c * _vig_cache[k][:,:,None], 0, 255).astype(np.uint8)
```

#### 反向暈影 (Reverse Vignette)

反向暈影：調暗**中心**並保持邊緣明亮。當文字置中於繁忙背景時非常有用 —— 它能創造出自然的黑暗區域以提高可讀性，而不需要硬生生的背景框。

可與 `apply_text_backdrop()` (參見 composition_zh_TW.md) 結合使用，以實現逐影格的字形感應調暗。

```python
_rvignette_cache = {}

def sh_reverse_vignette(c, strength=0.5):
    """中心調暗，邊緣調亮。已快取。"""
    k = ('rv', c.shape[0], c.shape[1], round(strength, 2))
    if k not in _rvignette_cache:
        h, w = c.shape[:2]
        Y = np.linspace(-1, 1, h)[:, None]
        X = np.linspace(-1, 1, w)[None, :]
        d = np.sqrt(X**2 + Y**2)
        # 反轉：邊緣亮，中心暗
        mask = np.clip(1.0 - (1.0 - d * 0.7) * strength, 0.2, 1.0)
        _rvignette_cache[k] = mask[:, :, np.newaxis].astype(np.float32)
    return np.clip(c.astype(np.float32) * _rvignette_cache[k], 0, 255).astype(np.uint8)
```

| 參數 | 預設值 | 效果 |
|-------|---------|--------|
| `strength` | 0.5 | 0 = 無效果, 1.0 = 中心近乎全黑 |

加入 ShaderChain 分發：
```python
elif name == "reverse_vignette":
    return sh_reverse_vignette(canvas, kwargs.get("strength", 0.5))
```

#### 對比度 (Contrast)
```python
def sh_contrast(c, factor=1.3):
    """以 128 為中心調整對比度。"""
    return np.clip((c.astype(np.float32) - 128) * factor + 128, 0, 255).astype(np.uint8)
```

#### Gamma
```python
def sh_gamma(c, gamma=1.5):
    """Gamma 校正。>1=中間調變亮, <1=中間調變暗。"""
    return np.clip(((c.astype(np.float32)/255.0) ** (1.0/gamma)) * 255, 0, 255).astype(np.uint8)
```

#### 色階 (Levels)
```python
def sh_levels(c, black=0, white=255, midtone=1.0):
    """色階調整 (類似 Photoshop)。重新映射黑白場，並應用中間調 Gamma。"""
    o = (c.astype(np.float32) - black) / max(1, white - black)
    o = np.clip(o, 0, 1) ** (1.0 / midtone)
    return (o * 255).astype(np.uint8)
```

#### 亮度 (Brightness)
```python
def sh_brightness(c, factor=1.5):
    """全局亮度乘數。建議優先使用 tonemap() 進行場景級亮度控制。"""
    return np.clip(c.astype(np.float32) * factor, 0, 255).astype(np.uint8)
```

---

### 故障 / 數據著色器 (Glitch / Data Shaders)

#### 故障條帶 (Glitch Bands)
```python
def sh_glitch_bands(c, f):
    """節拍反應式水平行位移。f 為音訊特徵字典。
    使用 f["bdecay"] 控制強度，f["sub"] 控制條帶高度。"""
    n = int(3 + f.get("bdecay", 0) * 10)
    out = c.copy()
    for _ in range(n):
        y = random.randint(0, c.shape[0]-1)
        h = random.randint(1, max(2, int(4 + f.get("sub", 0.3) * 12)))
        shift = int((random.random()-0.5) * f.get("bdecay", 0) * 60)
        if shift != 0 and y+h < c.shape[0]:
            out[y:y+h] = np.roll(out[y:y+h], shift, axis=1)
    return out
```

#### 區塊故障 (Block Glitch)
```python
def sh_block_glitch(c, n_blocks=8, max_size=40):
    """隨機矩形區塊位移 —— 將區塊複製到隨機位置。"""
    out = c.copy(); h, w = c.shape[:2]
    for _ in range(n_blocks):
        bw = random.randint(10, max_size); bh = random.randint(5, max_size//2)
        sx = random.randint(0, w-bw-1); sy = random.randint(0, h-bh-1)
        dx = random.randint(0, w-bw-1); dy = random.randint(0, h-bh-1)
        out[dy:dy+bh, dx:dx+bw] = c[sy:sy+bh, sx:sx+bw]
    return out
```

#### 像素排序 (Pixel Sort)
```python
def sh_pixel_sort(c, threshold=100, direction="h"):
    """在連續的亮部區域按亮度對像素進行排序。"""
    gray = c.astype(np.float32).mean(axis=2)
    out = c.copy()
    if direction == "h":
        for y in range(0, c.shape[0], 3):  # 每 3 行處理一次以求速度
            row_bright = gray[y]
            mask = row_bright > threshold
            regions = np.diff(np.concatenate([[0], mask.astype(int), [0]]))
            starts = np.where(regions == 1)[0]
            ends = np.where(regions == -1)[0]
            for s, e in zip(starts, ends):
                if e - s > 2:
                    indices = np.argsort(gray[y, s:e])
                    out[y, s:e] = c[y, s:e][indices]
    else:
        for x in range(0, c.shape[1], 3):
            col_bright = gray[:, x]
            mask = col_bright > threshold
            regions = np.diff(np.concatenate([[0], mask.astype(int), [0]]))
            starts = np.where(regions == 1)[0]
            ends = np.where(regions == -1)[0]
            for s, e in zip(starts, ends):
                if e - s > 2:
                    indices = np.argsort(gray[s:e, x])
                    out[s:e, x] = c[s:e, x][indices]
    return out
```

#### 數據彎曲 (Data Bend)
```python
def sh_data_bend(c, offset=1000, chunk=500):
    """將原始像素位元組視為數據，將一個區塊複製到另一個偏移位置 —— 產生 Datamoshing 瑕疵效果。"""
    flat = c.flatten().copy()
    n = len(flat)
    src = offset % n; dst = (offset + chunk*3) % n
    length = min(chunk, n-src, n-dst)
    if length > 0:
        flat[dst:dst+length] = flat[src:src+length]
    return flat.reshape(c.shape)
```

---

## 調色預設 (Tint Presets)

```python
TINT_WARM      = (1.15, 1.0, 0.85)   # 黃金暖色
TINT_COOL      = (0.85, 0.95, 1.15)  # 酷藍冷色
TINT_MATRIX    = (0.7, 1.2, 0.7)     # 綠色終端
TINT_AMBER     = (1.2, 0.9, 0.6)     # 琥珀色螢幕
TINT_SEPIA     = (1.2, 1.05, 0.8)    # 老電影感
TINT_NEON_PINK = (1.3, 0.7, 1.1)     # 網路龐克粉
TINT_ICE       = (0.8, 1.0, 1.3)     # 冰凍感
TINT_BLOOD     = (1.4, 0.7, 0.7)     # 恐怖紅色
TINT_FOREST    = (0.8, 1.15, 0.75)   # 自然綠色
TINT_VOID      = (0.85, 0.85, 1.1)   # 深空感
TINT_SUNSET    = (1.3, 0.85, 0.7)    # 橘色黃昏
```

---

## 過場 (Transitions)

> **注意：** 這些過場在字元級別的 `(chars, colors)` 陣列上運作 (v1 介面)。在 v2 中，場景間的過場通常由節拍邊界處的硬切處理 (參見 `scenes_zh_TW.md`)，或者將兩個場景渲染到畫布上，並使用 `blend_canvas()` 搭配隨時間變化的不透明度。下方的字元級過場在場景內效果中仍然很有用。

### 交叉淡化 (Crossfade)
```python
def tr_crossfade(ch_a, co_a, ch_b, co_b, blend):
    co = (co_a.astype(np.float32) * (1-blend) + co_b.astype(np.float32) * blend).astype(np.uint8)
    mask = np.random.random(ch_a.shape) < blend
    ch = ch_a.copy(); ch[mask] = ch_b[mask]
    return ch, co
```

### v2 畫布級交叉淡化
```python
def tr_canvas_crossfade(canvas_a, canvas_b, blend):
    """兩張畫布間平滑的像素級交叉淡化。"""
    return np.clip(canvas_a * (1-blend) + canvas_b * blend, 0, 255).astype(np.uint8)
```

### 擦除 (Wipe，具方向性)
```python
def tr_wipe(ch_a, co_a, ch_b, co_b, blend, direction="left"):
    """方向：left, right, up, down, radial, diagonal"""
    rows, cols = ch_a.shape
    if direction == "radial":
        cx, cy = cols/2, rows/2
        rr = np.arange(rows)[:, None]; cc = np.arange(cols)[None, :]
        d = np.sqrt((cc-cx)**2 + (rr-cy)**2)
        mask = d < blend * np.sqrt(cx**2 + cy**2)
        ch = ch_a.copy(); co = co_a.copy()
        ch[mask] = ch_b[mask]; co[mask] = co_b[mask]
    return ch, co
```

### 故障剪輯 (Glitch Cut)
```python
def tr_glitch_cut(ch_a, co_a, ch_b, co_b, blend):
    if blend < 0.5: ch, co = ch_a.copy(), co_a.copy()
    else: ch, co = ch_b.copy(), co_b.copy()
    if 0.3 < blend < 0.7:
        intensity = 1.0 - abs(blend - 0.5) * 4
        for _ in range(int(intensity * 20)):
            y = random.randint(0, ch.shape[0]-1)
            shift = int((random.random()-0.5) * 40 * intensity)
            if shift: ch[y] = np.roll(ch[y], shift); co[y] = np.roll(co[y], shift, axis=0)
    return ch, co
```

---

## 輸出格式 (Output Formats)

### MP4 (預設)
```python
cmd = ["ffmpeg", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24",
       "-s", f"{W}x{H}", "-r", str(fps), "-i", "pipe:0",
       "-c:v", "libx264", "-preset", "fast", "-crf", str(crf),
       "-pix_fmt", "yuv420p", output_path]
```

### GIF
```python
cmd = ["ffmpeg", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24",
       "-s", f"{W}x{H}", "-r", str(fps), "-i", "pipe:0",
       "-vf", f"fps={fps},scale={W}:{H}:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse",
       "-loop", "0", output_gif]
```

### PNG 序列 (PNG Sequence)

用於精確到影格的剪輯、在外部工具 (After Effects, Nuke) 中合成或無損存檔：

```python
import os

def output_png_sequence(frames, output_dir, W, H, fps, prefix="frame"):
    """將影格寫入為編號的 PNG 檔案。frames 為 uint8 (H,W,3) 陣列的可迭代物件。"""
    os.makedirs(output_dir, exist_ok=True)
    
    # 方法 1：直接透過 PIL 寫入 (不依賴 ffmpeg)
    from PIL import Image
    for i, frame in enumerate(frames):
        img = Image.fromarray(frame)
        img.save(os.path.join(output_dir, f"{prefix}_{i:06d}.png"))
    
    # 方法 2：ffmpeg 管道 (處理大型序列速度較快)
    cmd = ["ffmpeg", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24",
           "-s", f"{W}x{H}", "-r", str(fps), "-i", "pipe:0",
           os.path.join(output_dir, f"{prefix}_%06d.png")]
```

將 PNG 序列重新組合成影片：
```bash
ffmpeg -framerate 24 -i frame_%06d.png -c:v libx264 -crf 18 -pix_fmt yuv420p output.mp4
```

### Alpha 通道 / 透明背景 (RGBA)

用於將 ASCII 藝術合成到其他影片或圖像之上。使用 RGBA 畫布 (4 通道) 取代 RGB (3 通道)：

```python
def create_rgba_canvas(H, W):
    """透明畫布 —— alpha 通道初始為 0 (完全透明)。"""
    return np.zeros((H, W, 4), dtype=np.uint8)

def render_char_rgba(canvas, row, col, char_img, color_rgb, alpha=255):
    """帶 alpha 渲染字元。char_img 為 PIL 字形遮罩 (灰階)。
    Alpha 來自字形遮罩 —— 背景保持透明。"""
    r, g, b = color_rgb
    y0, x0 = row * cell_h, col * cell_w
    mask = np.array(char_img)  # 灰階 0-255
    canvas[y0:y0+cell_h, x0:x0+cell_w, 0] = np.maximum(canvas[y0:y0+cell_h, x0:x0+cell_w, 0], (mask * r / 255).astype(np.uint8))
    canvas[y0:y0+cell_h, x0:x0+cell_w, 1] = np.maximum(canvas[y0:y0+cell_h, x0:x0+cell_w, 1], (mask * g / 255).astype(np.uint8))
    canvas[y0:y0+cell_h, x0:x0+cell_w, 2] = np.maximum(canvas[y0:y0+cell_h, x0:x0+cell_w, 2], (mask * b / 255).astype(np.uint8))
    canvas[y0:y0+cell_h, x0:x0+cell_w, 3] = np.maximum(canvas[y0:y0+cell_h, x0:x0+cell_w, 3], mask)

def blend_onto_background(rgba_canvas, bg_rgb):
    """將 RGBA 畫布合成到純色或圖像背景上。"""
    alpha = rgba_canvas[:, :, 3:4].astype(np.float32) / 255.0
    fg = rgba_canvas[:, :, :3].astype(np.float32)
    bg = bg_rgb.astype(np.float32)
    result = fg * alpha + bg * (1.0 - alpha)
    return result.astype(np.uint8)
```

透過 ffmpeg 輸出 RGBA (ProRes 4444 用於剪輯, WebM VP9 用於網頁)：
```bash
# ProRes 4444 — 保留 alpha，剪輯軟體支援度高
ffmpeg -y -f rawvideo -pix_fmt rgba -s {W}x{H} -r {fps} -i pipe:0 \
    -c:v prores_ks -profile:v 4444 -pix_fmt yuva444p10le output.mov

# WebM VP9 — 支援網頁/瀏覽器合成的 alpha
ffmpeg -y -f rawvideo -pix_fmt rgba -s {W}x{H} -r {fps} -i pipe:0 \
    -c:v libvpx-vp9 -pix_fmt yuva420p -crf 30 -b:v 0 output.webm

# 帶 alpha 的 PNG 序列 (無損)
ffmpeg -y -f rawvideo -pix_fmt rgba -s {W}x{H} -r {fps} -i pipe:0 \
    frame_%06d.png
```

**關鍵限制**：對 `(H,W,3)` 陣列操作的著色器需要適配 RGBA。可以僅對 RGB 通道應用著色器並保留 alpha，或者撰寫支援 RGBA 的版本：

```python
def apply_shader_rgba(canvas_rgba, shader_fn, **kwargs):
    """將 RGB 著色器套用於 RGBA 畫布的色彩通道。"""
    rgb = canvas_rgba[:, :, :3]
    alpha = canvas_rgba[:, :, 3:4]
    rgb_out = shader_fn(rgb, **kwargs)
    return np.concatenate([rgb_out, alpha], axis=2)
```

---

## 即時終端渲染 (Real-Time Terminal Rendering)

使用 ANSI 轉義碼在終端機中進行即時 ASCII 顯示。適用於開發期間的場景預覽、現場表演以及參數的互動式調校。

### ANSI 色彩轉義碼

```python
def rgb_to_ansi(r, g, b):
    """24 位元真彩色 ANSI 轉義 (大多數現代終端機均支援)。"""
    return f"\033[38;2;{r};{g};{b}m"

ANSI_RESET = "\033[0m"
ANSI_CLEAR = "\033[2J\033[H"  # 清除螢幕 + 游標歸位
ANSI_HIDE_CURSOR = "\033[?25l"
ANSI_SHOW_CURSOR = "\033[?25h"
```

### 影格轉 ANSI 轉換

```python
def frame_to_ansi(chars, colors):
    """將字元與顏色陣列轉換為單一 ANSI 字串以供終端輸出。
    
    參數：
        chars: (rows, cols) 單字元陣列
        colors: (rows, cols, 3) uint8 RGB 陣列
    返回：
        str: 可供 sys.stdout.write() 使用的 ANSI 編碼影格
    """
    rows, cols = chars.shape
    lines = []
    for r in range(rows):
        parts = []
        prev_color = None
        for c in range(cols):
            rgb = tuple(colors[r, c])
            ch = chars[r, c]
            if ch == " " or rgb == (0, 0, 0):
                parts.append(" ")
            else:
                if rgb != prev_color:
                    parts.append(rgb_to_ansi(*rgb))
                    prev_color = rgb
                parts.append(ch)
        parts.append(ANSI_RESET)
        lines.append("".join(parts))
    return "\n".join(lines)
```

### 優化：增量更新 (Delta Updates)

僅重繪自上一格影格以來發生變化的字元。消除了對靜態區域冗餘的終端寫入：

```python
def frame_to_ansi_delta(chars, colors, prev_chars, prev_colors):
    """僅對發生變化的網格單元發送 ANSI 轉義碼。"""
    rows, cols = chars.shape
    parts = []
    for r in range(rows):
        for c in range(cols):
            if (chars[r, c] != prev_chars[r, c] or
                not np.array_equal(colors[r, c], prev_colors[r, c])):
                parts.append(f"\033[{r+1};{c+1}H")  # 移動游標
                rgb = tuple(colors[r, c])
                parts.append(rgb_to_ansi(*rgb))
                parts.append(chars[r, c])
    return "".join(parts)
```

### 即時渲染迴圈

```python
import sys
import time

def render_live(scene_fn, r, fps=24, duration=None):
    """在終端機中即時渲染場景函式。
    
    參數：
        scene_fn: v2 場景函式 (r, f, t, S) -> canvas
                  或者填充網格的 v1 風格函式
        r: Renderer 實例
        fps: 目標影格率
        duration: 執行秒數 (None = 執行到 Ctrl+C 為止)
    """
    frame_time = 1.0 / fps
    S = {}
    f = {}  # 合成特徵或連結至即時音訊
    
    sys.stdout.write(ANSI_HIDE_CURSOR + ANSI_CLEAR)
    sys.stdout.flush()
    
    t0 = time.monotonic()
    frame_count = 0
    try:
        while True:
            t = time.monotonic() - t0
            if duration and t > duration:
                break
            
            # 從時間合成特徵 (或透過 pyaudio 連結即時音訊)
            f = synthesize_features(t)
            
            # 渲染場景 —— 對於終端模式，使用小網格
            g = r.get_grid("sm")
            # 選項 A：v2 場景 → 從畫布提取字元/顏色 (逆向渲染)
            # 選項 B：直接調用效果函式以獲得字元/顏色
            canvas = scene_fn(r, f, t, S)
            
            # 針對終端顯示，直接渲染字元 + 顏色
            # (跳過像素畫布 —— 終端機使用的是字元單元)
            chars, colors = scene_to_terminal(scene_fn, r, f, t, S, g)
            
            frame_str = ANSI_CLEAR + frame_to_ansi(chars, colors)
            sys.stdout.write(frame_str)
            sys.stdout.flush()
            
            # 影格時機控制
            elapsed = time.monotonic() - t0 - (frame_count * frame_time)
            sleep_time = frame_time - elapsed
            if sleep_time > 0:
                time.sleep(sleep_time)
            frame_count += 1
    except KeyboardInterrupt:
        pass
    finally:
        sys.stdout.write(ANSI_SHOW_CURSOR + ANSI_RESET + "\n")
        sys.stdout.flush()

def scene_to_terminal(scene_fn, r, f, t, S, g):
    """執行效果函式並返回供終端顯示的 (字元, 顏色)。
    在終端模式下，跳過像素畫布，直接處理字元陣列。"""
    # 返回 (chars, colors) 的效果可以直接運作
    # 對於基於 vf 的效果，將數值場 + 色調場渲染為字元/顏色：
    val = vf_plasma(g, f, t, S)
    hue = hf_time_cycle(0.08)(g, t)
    mask = val > 0.03
    chars = val2char(val, mask, PAL_DENSE)
    R, G, B = hsv2rgb(hue, np.full_like(val, 0.8), val)
    colors = mkc(R, G, B, g.rows, g.cols)
    return chars, colors
```

### 基於 Curses 的渲染 (更穩健)

適用於具備調整大小處理與輸入功能的完整終端機 UI：

```python
import curses

def render_curses(scene_fn, r, fps=24):
    """具備調整大小處理與按鍵輸入的 Curses 即時渲染器。"""
    
    def _main(stdscr):
        curses.start_color()
        curses.use_default_colors()
        curses.curs_set(0)  # 隱藏游標
        stdscr.nodelay(True)  # 非阻塞輸入
        
        # 初始化色彩對 (Curses 支援 256 色)
        # 將 RGB 映射到最接近的 Curses 色彩對
        color_cache = {}
        next_pair = [1]
        
        def get_color_pair(r, g, b):
            key = (r >> 4, g >> 4, b >> 4)  # 量化以減少色彩對數量
            if key not in color_cache:
                if next_pair[0] < curses.COLOR_PAIRS - 1:
                    ci = 16 + (r // 51) * 36 + (g // 51) * 6 + (b // 51)  # 6x6x6 色彩立方體
                    curses.init_pair(next_pair[0], ci, -1)
                    color_cache[key] = next_pair[0]
                    next_pair[0] += 1
                else:
                    return 0
            return curses.color_pair(color_cache[key])
        
        S = {}
        f = {}
        frame_time = 1.0 / fps
        t0 = time.monotonic()
        
        while True:
            t = time.monotonic() - t0
            f = synthesize_features(t)
            
            # 適配終端尺寸的網格
            max_y, max_x = stdscr.getmaxyx()
            g = r.get_grid_for_size(max_x, max_y)  # 動態網格尺寸
            
            chars, colors = scene_to_terminal(scene_fn, r, f, t, S, g)
            rows, cols = chars.shape
            
            for row in range(min(rows, max_y - 1)):
                for col in range(min(cols, max_x - 1)):
                    ch = chars[row, col]
                    rgb = tuple(colors[row, col])
                    try:
                        stdscr.addch(row, col, ch, get_color_pair(*rgb))
                    except curses.error:
                        pass  # 忽略超出終端邊界的寫入
            
            stdscr.refresh()
            
            # 處理輸入
            key = stdscr.getch()
            if key == ord('q'):
                break
            
            time.sleep(max(0, frame_time - (time.monotonic() - t0 - t)))
    
    curses.wrapper(_main)
```

### 終端渲染限制

| 限制項 | 數值 | 備註 |
|-----------|-------|-------|
| 實際最大網格 | ~200x60 | 取決於終端視窗大小 |
| 色彩支援 | 24 位元 (現代), 256 (回退), 16 (最低) | 檢查 `$COLORTERM` 以確認真彩色支援 |
| 影格率上限 | ~30 fps | 終端機 I/O 是瓶頸所在 |
| 增量更新 (Delta) | 快 2-5 倍 | 僅在每格影格變化率 <30% 時值得使用 |
| SSH 延遲 | 嚴重打擊效能 | 即時顯示僅限本地終端機 |

**檢測色彩支援：**
```python
import os
def get_terminal_color_depth():
    ct = os.environ.get("COLORTERM", "")
    if ct in ("truecolor", "24bit"):
        return 24
    term = os.environ.get("TERM", "")
    if "256color" in term:
        return 8  # 256 色
    return 4  # 16 色基礎 ANSI
```
