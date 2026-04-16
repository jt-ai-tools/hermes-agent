# 合成與亮度參考 (Composition & Brightness Reference)

可組合系統是視覺複雜性的核心。它在三個層次上運作：像素級混合模式、多網格合成以及自適應亮度管理。本文件涵蓋了這三個部分，以及用於空間控制的遮罩/模板系統。

> **另請參閱：** [architecture_zh_TW.md](architecture_zh_TW.md) · [effects_zh_TW.md](effects_zh_TW.md) · [scenes_zh_TW.md](scenes_zh_TW.md) · [shaders_zh_TW.md](shaders_zh_TW.md) · [troubleshooting_zh_TW.md](troubleshooting_zh_TW.md)

## 像素級混合模式 (Pixel-Level Blend Modes)

### `blend_canvas()` 函式

所有混合操作都在完整的像素畫布 (`uint8 H,W,3`) 上執行。內部會轉換為 float32 [0,1] 以確保精確度，進行混合，按不透明度進行線性插值 (lerp)，最後轉換回原格式。

```python
def blend_canvas(base, top, mode="normal", opacity=1.0):
    af = base.astype(np.float32) / 255.0
    bf = top.astype(np.float32) / 255.0
    fn = BLEND_MODES.get(mode, BLEND_MODES["normal"])
    result = fn(af, bf)
    if opacity < 1.0:
        result = af * (1 - opacity) + result * opacity
    return np.clip(result * 255, 0, 255).astype(np.uint8)
```

### 20 種混合模式

```python
BLEND_MODES = {
    # 基礎算術
    "normal":       lambda a, b: b,
    "add":          lambda a, b: np.clip(a + b, 0, 1),
    "subtract":     lambda a, b: np.clip(a - b, 0, 1),
    "multiply":     lambda a, b: a * b,
    "screen":       lambda a, b: 1 - (1 - a) * (1 - b),

    # 對比度
    "overlay":      lambda a, b: np.where(a < 0.5, 2*a*b, 1 - 2*(1-a)*(1-b)),
    "softlight":    lambda a, b: (1 - 2*b)*a*a + 2*b*a,
    "hardlight":    lambda a, b: np.where(b < 0.5, 2*a*b, 1 - 2*(1-a)*(1-b)),

    # 差異
    "difference":   lambda a, b: np.abs(a - b),
    "exclusion":    lambda a, b: a + b - 2*a*b,

    # 加亮 / 加深
    "colordodge":   lambda a, b: np.clip(a / (1 - b + 1e-6), 0, 1),
    "colorburn":    lambda a, b: np.clip(1 - (1 - a) / (b + 1e-6), 0, 1),

    # 亮光
    "linearlight":  lambda a, b: np.clip(a + 2*b - 1, 0, 1),
    "vividlight":   lambda a, b: np.where(b < 0.5,
                        np.clip(1 - (1-a)/(2*b + 1e-6), 0, 1),
                        np.clip(a / (2*(1-b) + 1e-6), 0, 1)),
    "pin_light":    lambda a, b: np.where(b < 0.5,
                        np.minimum(a, 2*b), np.maximum(a, 2*b - 1)),
    "hard_mix":     lambda a, b: np.where(a + b >= 1.0, 1.0, 0.0),

    # 比較
    "lighten":      lambda a, b: np.maximum(a, b),
    "darken":       lambda a, b: np.minimum(a, b),

    # 顆粒
    "grain_extract": lambda a, b: np.clip(a - b + 0.5, 0, 1),
    "grain_merge":  lambda a, b: np.clip(a + b - 0.5, 0, 1),
}
```

### 混合模式選擇指南

**變亮的模式**（對深色輸入安全）：
- `screen` —— 始終變亮。兩個 50% 灰色的圖層濾色後變為 75%。這是最穩妥的混合首選。
- `add` —— 簡單相加，在白色處剪裁。適用於閃光、發光效果及粒子疊加。
- `colordodge` —— 在重疊區域極度變亮。可能會導致曝光過度。建議使用低不透明度 (0.3-0.5)。
- `linearlight` —— 強勢變亮。類似 add 但帶有偏移。

**變暗的模式**（避免用於深色輸入）：
- `multiply` —— 調暗所有內容。僅在兩個圖層都已經很亮時使用。
- `overlay` —— 當底層 < 0.5 時變暗，當底層 > 0.5 時變亮。會壓制深色輸入：`2 * 0.12 * 0.12 = 0.03`。對於深色素材，請改用 `screen`。
- `colorburn` —— 在重疊區域極度變暗。

**增加對比度的模式**：
- `softlight` —— 柔和的對比。適用於細微的紋理疊加。
- `hardlight` —— 強烈的對比。類似 overlay 但以頂層為基準。
- `vividlight` —— 非常強勢的對比。請謹慎使用。

**產生特殊色彩效果的模式**：
- `difference` —— 產生類似 XOR 的圖案。兩個完全相同的圖層相減後變黑；偏移的圖層會產生狂野的色彩。非常適合迷幻風格。
- `exclusion` —— difference 的較柔和版本。產生互補色圖案。
- `hard_mix` —— 在相交處將影像海報化為純黑/白或飽和色。

**紋理混合模式**：
- `grain_extract` / `grain_merge` —— 從一個圖層提取紋理並應用到另一個圖層。

### 多圖層鏈結 (Multi-Layer Chaining)

```python
# 模式：渲染圖層 -> 依序混合
canvas_a = _render_vf(r, "md", vf_plasma, hf_angle(0.0), PAL_DENSE, f, t, S)
canvas_b = _render_vf(r, "sm", vf_vortex, hf_time_cycle(0.1), PAL_RUNE, f, t, S)
canvas_c = _render_vf(r, "lg", vf_rings, hf_distance(), PAL_BLOCKS, f, t, S)

result = blend_canvas(canvas_a, canvas_b, "screen", 0.8)
result = blend_canvas(result, canvas_c, "difference", 0.6)
```

順序很重要：`screen(A, B)` 是可交換的，但 `difference(screen(A,B), C)` 不同於 `difference(A, screen(B,C))`。

### 線性光混合模式 (Linear-Light Blend Modes)

標準的 `blend_canvas()` 在 sRGB 空間運作 —— 也就是原始的位元組數值。這在大多數情況下都沒問題，但 sRGB 在感知上是非線性的：在 sRGB 中混合會使中間調變暗並產生輕微的色調偏移。為了獲得物理上精確的混合（符合光的真實疊加方式），請先轉換為線性光空間。

使用 `architecture_zh_TW.md` § OKLAB 色彩系統中的 `srgb_to_linear()` / `linear_to_srgb()`。

```python
def blend_canvas_linear(base, top, mode="normal", opacity=1.0):
    """在線性光空間進行混合，以獲得物理上精確的結果。
    
    API 與 blend_canvas() 相同，但在混合前先將 sRGB 轉為線性，
    混合後再轉回 sRGB。由於 Gamma 轉換，計算開銷較大（約 2 倍），
    但在加法混合、濾色 (screen) 及任何對亮度敏感的模式下，能產生正確的結果。
    """
    af = srgb_to_linear(base.astype(np.float32) / 255.0)
    bf = srgb_to_linear(top.astype(np.float32) / 255.0)
    fn = BLEND_MODES.get(mode, BLEND_MODES["normal"])
    result = fn(af, bf)
    if opacity < 1.0:
        result = af * (1 - opacity) + result * opacity
    result = linear_to_srgb(np.clip(result, 0, 1))
    return np.clip(result * 255, 0, 255).astype(np.uint8)
```

**何時使用 `blend_canvas_linear()` 與 `blend_canvas()`：**

| 場景 | 使用建議 | 理由 |
|----------|-----|-----|
| 兩個明亮圖層的 Screen 混合 | `linear` | sRGB screen 會使高光部分過亮 |
| 用於發光/Bloom 效果的 Add 模式 | `linear` | 加法混光符合線性物理原則 |
| 低不透明度的文字疊加混合 | `srgb` | 感知混合對於文字來說看起來更自然 |
| 用於陰影/變暗的 Multiply | `srgb` | 變暗操作在兩者間差異極小 |
| 顏色精確度要求極高的工作 | `linear` | 避免中間調產生 sRGB 色調偏移 |
| 對效能要求極高的內層迴圈 | `srgb` | 快約 2 倍，對於大多數 ASCII 藝術已足夠 |

**多圖層批次版本**（一次轉換，多次混合，最後轉回）：

```python
def blend_many_linear(layers, modes, opacities):
    """在線性光空間中混合一疊圖層。
    
    參數：
        layers: uint8 (H,W,3) 畫布列表
        modes: 混合模式字串列表 (長度 = 圖層數 - 1)
        opacities: float 列表 (長度 = 圖層數 - 1)
    返回：
        uint8 (H,W,3) 畫布
    """
    # 一次性全部轉為線性
    linear = [srgb_to_linear(l.astype(np.float32) / 255.0) for l in layers]
    result = linear[0]
    for i in range(1, len(linear)):
        fn = BLEND_MODES.get(modes[i-1], BLEND_MODES["normal"])
        blended = fn(result, linear[i])
        op = opacities[i-1]
        if op < 1.0:
            blended = result * (1 - op) + blended * op
        result = np.clip(blended, 0, 1)
    result = linear_to_srgb(result)
    return np.clip(result * 255, 0, 255).astype(np.uint8)
```

---

## 多網格合成 (Multi-Grid Composition)

這是核心的視覺技術。在不同的網格密度（字元大小）下渲染同一個概念場景，會產生自然的紋理干涉，因為不同比例的字元會在不同的空間頻率上重疊。

### 為何有效

- `sm` 網格（10pt 字體）：320x83 字元。細節精緻，紋理密集。
- `md` 網格 (16pt)：192x56 字元。中等密度。
- `lg` 網格 (20pt)：160x45 字元。字元粗獷、有塊狀感。

當您在 `sm` 上渲染電漿場並在 `lg` 上渲染渦流，然後進行 Screen 混合時，精細的電漿紋理會從粗大的渦流字元縫隙中透出來。結果比任何單一圖層都具有更高的視覺複雜度。

### `_render_vf()` 輔助函式

這是主力函式。它接收數值場 + 色調場 + 調色盤 + 網格，渲染成完整的像素畫布：

```python
def _render_vf(r, grid_key, val_fn, hue_fn, pal, f, t, S, sat=0.8, threshold=0.03):
    """透過指定的網格將數值場 + 色調場渲染到像素畫布。

    參數：
        r: Renderer 實例 (具有 .get_grid())
        grid_key: "xs", "sm", "md", "lg", "xl", "xxl"
        val_fn: (g, f, t, S) -> float32 [0,1] 陣列 (rows, cols)
        hue_fn: 可調用物件 (g, f, t, S) -> float32 色調陣列, 或 float 純量
        pal: 字元調色盤字串
        f: 特徵字典
        t: 以秒為單位的時間
        S: 持久化狀態字典
        sat: HSV 飽和度 (0-1)
        threshold: 渲染的最小數值（低於此值 = 空格）

    返回：
        uint8 陣列 (VH, VW, 3) — 完整像素畫布
    """
    g = r.get_grid(grid_key)
    val = np.clip(val_fn(g, f, t, S), 0, 1)
    mask = val > threshold
    ch = val2char(val, mask, pal)

    # 色調：可以是可調用物件或固定的 float
    if callable(hue_fn):
        h = hue_fn(g, f, t, S) % 1.0
    else:
        h = np.full((g.rows, g.cols), float(hue_fn), dtype=np.float32)

    # 至關重要：廣播到完整形狀並複製 (參見疑難排解)
    h = np.broadcast_to(h, (g.rows, g.cols)).copy()

    R, G, B = hsv2rgb(h, np.full_like(val, sat), val)
    co = mkc(R, G, B, g.rows, g.cols)
    return g.render(ch, co)
```

### 網格組合策略

| 組合 | 效果 | 適用於 |
|-------------|--------|----------|
| `sm` + `lg` | 精細細節與粗大塊狀感之間的最大對比 | 大膽、具圖形感的風格 |
| `sm` + `md` | 類似比例下的細微紋理分層 | 有機、流動的風格 |
| `md` + `lg` + `xs` | 三種比例的干涉，最大化複雜度 | 迷幻、密集風格 |
| `sm` + `sm`（不同效果） | 相同比例，僅產生圖案干涉 | 莫列波紋、干涉圖案 |

### 完整多網格場景範例

```python
def fx_psychedelic(r, f, t, S):
    """帶有節拍反應式萬花筒的三層多網格場景。"""
    # 圖層 A：中網格上的電漿場，配上彩虹色調
    canvas_a = _render_vf(r, "md",
        lambda g, f, t, S: vf_plasma(g, f, t, S) * 1.3,
        hf_angle(0.0), PAL_DENSE, f, t, S, sat=0.8)

    # 圖層 B：小網格上的渦流，配上循環色調
    canvas_b = _render_vf(r, "sm",
        lambda g, f, t, S: vf_vortex(g, f, t, S, twist=5.0) * 1.2,
        hf_time_cycle(0.1), PAL_RUNE, f, t, S, sat=0.7)

    # 圖層 C：大網格上的圓環，配上距離色調
    canvas_c = _render_vf(r, "lg",
        lambda g, f, t, S: vf_rings(g, f, t, S, n_base=8, spacing_base=3) * 1.4,
        hf_distance(0.3, 0.02), PAL_BLOCKS, f, t, S, sat=0.9)

    # 混合：A 與 B 進行 Screen 混合，然後再與 C 進行 Difference 混合
    result = blend_canvas(canvas_a, canvas_b, "screen", 0.8)
    result = blend_canvas(result, canvas_c, "difference", 0.6)

    # 節拍觸發的萬花筒
    if f.get("bdecay", 0) > 0.3:
        result = sh_kaleidoscope(result.copy(), folds=6)

    return result
```

---

## 自適應色調映射 (Adaptive Tone Mapping)

### 亮度問題

ASCII 字元是黑底上的微小亮點。任何影格中的大多數像素都是背景色（黑色）。這意味著：
- 平均影格亮度天生較低（通常在 255 分之 5 到 30 之間）
- 不同的效果組合會產生劇烈波動的亮度水平
- 螺旋場景平均亮度可能有 50，而火焰場景平均亮度只有 9
- 線性倍數增益（如 `canvas * 2.0`）要嘛讓深色場景依然很暗，要嘛讓明亮場景過曝

### `tonemap()` 函式

使用自適應的每影格歸一化 + Gamma 校正取代線性亮度倍數：

```python
def tonemap(canvas, target_mean=90, gamma=0.75, black_point=2, white_point=253):
    """自適應色調映射：進行歸一化 + Gamma 校正，確保影格既不全黑也不泛白。

    1. 在 4x 下取樣上計算第 1 和第 99.5 個百分位數（數值減少 16 倍，
       精度損失可忽略不計，在 1080p+ 下有顯著加速）
    2. 將該範圍拉伸至 [0, 1]
    3. 應用 Gamma 曲線（< 1 提升陰影，> 1 壓暗）
    4. 縮放到 [black_point, white_point] 區間
    """
    f = canvas.astype(np.float32)
    sub = f[::4, ::4]  # 4x 下取樣：1080p 下約 39 萬個值，原為 620 萬個
    lo = np.percentile(sub, 1)
    hi = np.percentile(sub, 99.5)
    if hi - lo < 10:
        hi = max(hi, lo + 10)  # 近乎純色影格的回退機制
    f = np.clip((f - lo) / (hi - lo), 0.0, 1.0)
    np.power(f, gamma, out=f)          # 原地計算：避免記憶體分配
    np.multiply(f, (white_point - black_point), out=f)
    np.add(f, black_point, out=f)
    return np.clip(f, 0, 255).astype(np.uint8)
```

### 為何使用 Gamma 而非線性

線性倍數 `* 2.0`：
```
輸入 10  -> 輸出 20   (依然很暗)
輸入 100 -> 輸出 200  (尚可)
輸入 200 -> 輸出 255  (剪裁，細節丟失)
```

歸一化後的 Gamma 0.75：
```
輸入 0.04 -> 輸出 0.08 (從看不見變為可見)
輸入 0.39 -> 輸出 0.50 (中度提升)
輸入 0.78 -> 輸出 0.84 (輕微提升，無剪裁)
```

Gamma < 1 會壓縮高光並擴展陰影。這正是我們需要的：讓黑暗的 ASCII 內容變得可見，同時又不讓明亮部分過曝。

### 流水線順序

`render_clip()` 中的流水線順序如下：

```
scene_fn(r, f, t, S)  ->  畫布 (canvas)
         |
    tonemap(canvas, gamma=scene_gamma)
         |
    FeedbackBuffer.apply(canvas, ...)
         |
    ShaderChain.apply(canvas, f=f, t=t)
         |
    ffmpeg 管道
```

Tonemap 在回饋緩衝區和著色器之前執行。這意味著：
- 回饋緩衝區在歸一化數據上運行（不論場景亮度如何，行為都保持一致）
- 曝光過度 (solarize)、海報化 (posterize)、對比度等著色器在正確範圍的數據上運作
- 著色器鏈中不再需要 brightness 著色器（已由 tonemap 處理）

### 各場景 Gamma 調節

預設 Gamma 為 0.75。應用了破壞性後處理的場景需要更強力的提升，因為破壞發生在 tonemap 之後：

| 場景類型 | 推薦 Gamma | 理由 |
|------------|-------------------|-----|
| 標準效果 | 0.75 | 預設值，適用於大多數場景 |
| 曝光過度後處理 | 0.50-0.60 | 此模式會反轉亮像素，降低整體亮度 |
| 海報化後處理 | 0.50-0.55 | 此模式會量化數值，常將中間調壓為黑色 |
| 強力 Difference 混合 | 0.60-0.70 | 此模式會產生許多趨近零的像素 |
| 天生較亮的場景 | 0.85-1.0 | 不要過度提升自然明亮的場景 |

在場景表中配置：

```python
SCENES = [
    {"start": 9.17, "end": 11.25, "name": "fire", "gamma": 0.55,
     "fx": fx_fire, "shaders": [("solarize", {"threshold": 200}), ...]},
    {"start": 25.96, "end": 27.29, "name": "diamond", "gamma": 0.5,
     "fx": fx_diamond, "shaders": [("bloom", {"thr": 90}), ...]},
]
```

### 亮度驗證

渲染後，抽查影格亮度：

```python
# 在測試影格模式下
canvas = scene["fx"](r, feat, t, r.S)
canvas = tonemap(canvas, gamma=scene.get("gamma", 0.75))
chain = ShaderChain()
for sn, kw in scene.get("shaders", []):
    chain.add(sn, **kw)
canvas = chain.apply(canvas, f=feat, t=t)
print(f"平均亮度：{canvas.astype(float).mean():.1f}, 最大值：{canvas.max()}")
```

Tonemap + 著色器後的目標範圍：
- 安靜/環境場景：平均 30-60
- 活動場景：平均 40-100
- 高潮/頂峰場景：平均 60-150
- 如果平均 < 20：Gamma 太高，或某個著色器摧毀了亮度
- 如果平均 > 180：Gamma 太低，或 add 模式疊加過多

---

## 回饋緩衝區 (FeedbackBuffer) 空間變換

回饋緩衝區儲存前一格影格，並帶有衰減地混合到當前格。在混合前對緩衝區應用空間變換，可以在回饋軌跡中創造出運動的錯覺。

### 實作

```python
class FeedbackBuffer:
    def __init__(self):
        self.buf = None

    def apply(self, canvas, decay=0.85, blend="screen", opacity=0.5,
              transform=None, transform_amt=0.02, hue_shift=0.0):
        if self.buf is None:
            self.buf = canvas.astype(np.float32) / 255.0
            return canvas

        # 舊緩衝區衰減
        self.buf *= decay

        # 空間變換
        if transform:
            self.buf = self._transform(self.buf, transform, transform_amt)

        # 回饋色調偏移，用於彩虹軌跡
        if hue_shift > 0:
            self.buf = self._hue_shift(self.buf, hue_shift)

        # 將回饋混合到當前影格
        result = blend_canvas(canvas,
                              np.clip(self.buf * 255, 0, 255).astype(np.uint8),
                              blend, opacity)

        # 用當前結果更新緩衝區
        self.buf = result.astype(np.float32) / 255.0
        return result

    def _transform(self, buf, transform, amt):
        h, w = buf.shape[:2]
        if transform == "zoom":
            # 放大：從內部取樣（產生擴張的隧道感）
            m = int(h * amt); n = int(w * amt)
            if m > 0 and n > 0:
                cropped = buf[m:-m or None, n:-n or None]
                # 調整回全尺寸（使用最近鄰插值以求速度）
                buf = np.array(Image.fromarray(
                    np.clip(cropped * 255, 0, 255).astype(np.uint8)
                ).resize((w, h), Image.NEAREST)).astype(np.float32) / 255.0
        elif transform == "shrink":
            # 縮小：填充邊緣，縮小中心
            m = int(h * amt); n = int(w * amt)
            small = np.array(Image.fromarray(
                np.clip(buf * 255, 0, 255).astype(np.uint8)
            ).resize((w - 2*n, h - 2*m), Image.NEAREST))
            new = np.zeros((h, w, 3), dtype=np.uint8)
            new[m:m+small.shape[0], n:n+small.shape[1]] = small
            buf = new.astype(np.float32) / 255.0
        elif transform == "rotate_cw":
            # 透過仿射變換進行輕微順時針旋轉
            angle = amt * 10  # amt=0.005 -> 每格 0.05 度
            cy, cx = h / 2, w / 2
            Y = np.arange(h, dtype=np.float32)[:, None]
            X = np.arange(w, dtype=np.float32)[None, :]
            cos_a, sin_a = np.cos(angle), np.sin(angle)
            sx = (X - cx) * cos_a + (Y - cy) * sin_a + cx
            sy = -(X - cx) * sin_a + (Y - cy) * cos_a + cy
            sx = np.clip(sx.astype(int), 0, w - 1)
            sy = np.clip(sy.astype(int), 0, h - 1)
            buf = buf[sy, sx]
        elif transform == "rotate_ccw":
            angle = -amt * 10
            cy, cx = h / 2, w / 2
            Y = np.arange(h, dtype=np.float32)[:, None]
            X = np.arange(w, dtype=np.float32)[None, :]
            cos_a, sin_a = np.cos(angle), np.sin(angle)
            sx = (X - cx) * cos_a + (Y - cy) * sin_a + cx
            sy = -(X - cx) * sin_a + (Y - cy) * cos_a + cy
            sx = np.clip(sx.astype(int), 0, w - 1)
            sy = np.clip(sy.astype(int), 0, h - 1)
            buf = buf[sy, sx]
        elif transform == "shift_up":
            pixels = max(1, int(h * amt))
            buf = np.roll(buf, -pixels, axis=0)
            buf[-pixels:] = 0  # 底部填黑
        elif transform == "shift_down":
            pixels = max(1, int(h * amt))
            buf = np.roll(buf, pixels, axis=0)
            buf[:pixels] = 0
        elif transform == "mirror_h":
            buf = buf[:, ::-1]
        return buf

    def _hue_shift(self, buf, amount):
        """旋轉回饋緩衝區的色調。在 float32 [0,1] 上執行。"""
        rgb = np.clip(buf * 255, 0, 255).astype(np.uint8)
        hsv = np.zeros_like(buf)
        # 簡單近似的 RGB->HSV->shift->RGB 轉換
        r, g, b = buf[:,:,0], buf[:,:,1], buf[:,:,2]
        mx = np.maximum(np.maximum(r, g), b)
        mn = np.minimum(np.minimum(r, g), b)
        delta = mx - mn + 1e-10
        # 色調 (Hue)
        h = np.where(mx == r, ((g - b) / delta) % 6,
            np.where(mx == g, (b - r) / delta + 2, (r - g) / delta + 4))
        h = (h / 6 + amount) % 1.0
        # 使用偏移後的色調重建 (簡化版)
        s = delta / (mx + 1e-10)
        v = mx
        c = v * s; x = c * (1 - np.abs((h * 6) % 2 - 1)); m = v - c
        ro = np.zeros_like(h); go = np.zeros_like(h); bo = np.zeros_like(h)
        for lo, hi, rv, gv, bv in [(0,1,c,x,0),(1,2,x,c,0),(2,3,0,c,x),
                                     (3,4,0,x,c),(4,5,x,0,c),(5,6,c,0,x)]:
            mask = ((h*6) >= lo) & ((h*6) < hi)
            ro[mask] = rv[mask] if not isinstance(rv, (int,float)) else rv
            go[mask] = gv[mask] if not isinstance(gv, (int,float)) else gv
            bo[mask] = bv[mask] if not isinstance(bv, (int,float)) else bv
        return np.stack([ro+m, go+m, bo+m], axis=2)
```

### 回饋預設值 (Feedback Presets)

| 預設值 | 配置 | 視覺效果 |
|--------|--------|---------------|
| 無限縮放隧道 | `decay=0.8, blend="screen", transform="zoom", transform_amt=0.015` | 擴張的環狀圖案 |
| 彩虹軌跡 | `decay=0.7, blend="screen", transform="zoom", transform_amt=0.01, hue_shift=0.02` | 迷幻的色彩拖尾 |
| 幽靈迴聲 | `decay=0.9, blend="add", opacity=0.15, transform="shift_up", transform_amt=0.01` | 微弱的向上抹除感 |
| 萬花筒遞迴 | `decay=0.75, blend="screen", transform="rotate_cw", transform_amt=0.005, hue_shift=0.01` | 旋轉的曼陀羅回饋 |
| 色彩演化 | `decay=0.8, blend="difference", opacity=0.4, hue_shift=0.03` | 影格間色彩的 XOR 運算 |
| 上升熱浪 | `decay=0.5, blend="add", opacity=0.2, transform="shift_up", transform_amt=0.02` | 熱氣昇騰的抖動感 |

---

## 遮罩 / 模板系統 (Masking / Stencil System)

遮罩是 [0, 1] 範圍內的 float32 陣列 `(rows, cols)` 或 `(VH, VW)`。它們控制效果的可見區域：1.0 = 完全可見，0.0 = 完全隱藏。使用遮罩來建立主體/背景關係、焦點以及特定形狀的揭示效果。

### 形狀遮罩 (Shape Masks)

```python
def mask_circle(g, cx_frac=0.5, cy_frac=0.5, radius=0.3, feather=0.05):
    """置中於 (cx_frac, cy_frac) 歸一化座標的圓形遮罩。
    feather：羽化邊緣寬度 (0 = 硬切)。"""
    asp = g.cw / g.ch if hasattr(g, 'cw') else 1.0
    dx = (g.cc / g.cols - cx_frac)
    dy = (g.rr / g.rows - cy_frac) * asp
    d = np.sqrt(dx**2 + dy**2)
    if feather > 0:
        return np.clip(1.0 - (d - radius) / feather, 0, 1)
    return (d <= radius).astype(np.float32)

def mask_rect(g, x0=0.2, y0=0.2, x1=0.8, y1=0.8, feather=0.03):
    """矩形遮罩。座標為 [0,1] 歸一化值。"""
    dx = np.maximum(x0 - g.cc / g.cols, g.cc / g.cols - x1)
    dy = np.maximum(y0 - g.rr / g.rows, g.rr / g.rows - y1)
    d = np.maximum(dx, dy)
    if feather > 0:
        return np.clip(1.0 - d / feather, 0, 1)
    return (d <= 0).astype(np.float32)

def mask_ring(g, cx_frac=0.5, cy_frac=0.5, inner_r=0.15, outer_r=0.35,
              feather=0.03):
    """圓環遮罩。"""
    inner = mask_circle(g, cx_frac, cy_frac, inner_r, feather)
    outer = mask_circle(g, cx_frac, cy_frac, outer_r, feather)
    return outer - inner

def mask_gradient_h(g, start=0.0, end=1.0):
    """由左至右的漸層遮罩。"""
    return np.clip((g.cc / g.cols - start) / (end - start + 1e-10), 0, 1).astype(np.float32)

def mask_gradient_v(g, start=0.0, end=1.0):
    """由上至下的漸層遮罩。"""
    return np.clip((g.rr / g.rows - start) / (end - start + 1e-10), 0, 1).astype(np.float32)

def mask_gradient_radial(g, cx_frac=0.5, cy_frac=0.5, inner=0.0, outer=0.5):
    """徑向漸層遮罩 —— 中心亮，邊緣暗。"""
    d = np.sqrt((g.cc / g.cols - cx_frac)**2 + (g.rr / g.rows - cy_frac)**2)
    return np.clip(1.0 - (d - inner) / (outer - inner + 1e-10), 0, 1)
```

### 將數值場作為遮罩

使用任何 `vf_*` 函式的輸出作為空間遮罩：

```python
def mask_from_vf(vf_result, threshold=0.5, feather=0.1):
    """透過設定閥值將數值場轉為遮罩。
    feather：閥值周圍的羽化寬度。"""
    if feather > 0:
        return np.clip((vf_result - threshold + feather) / (2 * feather), 0, 1)
    return (vf_result > threshold).astype(np.float32)

def mask_select(mask, vf_a, vf_b):
    """空間選擇：在遮罩為 1 處顯示 vf_a，在 0 處顯示 vf_b。
    mask：float32 [0,1] 陣列。中間值會產生混合效果。"""
    return vf_a * mask + vf_b * (1 - mask)
```

### 文字模板 (Text Stencil)

將文字渲染為遮罩。效果僅透過字母形狀顯示：

```python
def mask_text(grid, text, row_frac=0.5, font=None, font_size=None):
    """在網格解析度下將文字字串渲染為 float32 [0,1] 遮罩。
    字元部分 = 1.0, 背景 = 0.0。

    row_frac：網格高度的垂直比例位置。
    font：PIL ImageFont (若為 None 則預設使用網格字體)。
    font_size：覆蓋文字大小 (用於更大的模板文字)。
    """
    from PIL import Image, ImageDraw, ImageFont

    f = font or grid.font
    if font_size and font != grid.font:
        f = ImageFont.truetype(font.path, font_size)

    # 先在像素解析度下渲染文字為圖像，再降採樣至網格解析度
    img = Image.new("L", (grid.cols * grid.cw, grid.ch), 0)
    draw = ImageDraw.Draw(img)
    bbox = draw.textbbox((0, 0), text, font=f)
    tw = bbox[2] - bbox[0]
    x = (grid.cols * grid.cw - tw) // 2
    draw.text((x, 0), text, fill=255, font=f)
    row_mask = np.array(img, dtype=np.float32) / 255.0

    # 放置到完整的網格遮罩中
    mask = np.zeros((grid.rows, grid.cols), dtype=np.float32)
    target_row = int(grid.rows * row_frac)
    # 將渲染的文字降採樣至網格單元
    for c in range(grid.cols):
        px = c * grid.cw
        if px + grid.cw <= row_mask.shape[1]:
            cell = row_mask[:, px:px + grid.cw]
            if cell.mean() > 0.1:
                mask[target_row, c] = cell.mean()
    return mask

def mask_text_block(grid, lines, start_row_frac=0.3, font=None):
    """多行文字模板。返回完整網格遮罩。"""
    mask = np.zeros((grid.rows, grid.cols), dtype=np.float32)
    for i, line in enumerate(lines):
        row_frac = start_row_frac + i / grid.rows
        line_mask = mask_text(grid, line, row_frac, font)
        mask = np.maximum(mask, line_mask)
    return mask
```

### 動畫遮罩 (Animated Masks)

隨時間變化的遮罩，用於揭示、擦除及變形效果：

```python
def mask_iris(g, t, t_start, t_end, cx_frac=0.5, cy_frac=0.5,
              max_radius=0.7, ease_fn=None):
    """光圈開/關：半徑從 0 增長到 max_radius 的圓形。
    ease_fn：緩動函式 (預設為 effects.md 中的 ease_in_out_cubic)。"""
    if ease_fn is None:
        ease_fn = lambda x: x * x * (3 - 2 * x)  # smoothstep 回退
    progress = np.clip((t - t_start) / (t_end - t_start), 0, 1)
    radius = ease_fn(progress) * max_radius
    return mask_circle(g, cx_frac, cy_frac, radius, feather=0.03)

def mask_wipe_h(g, t, t_start, t_end, direction="right"):
    """水平擦除揭示。"""
    progress = np.clip((t - t_start) / (t_end - t_start), 0, 1)
    if direction == "left":
        progress = 1 - progress
    return mask_gradient_h(g, start=progress - 0.05, end=progress + 0.05)

def mask_wipe_v(g, t, t_start, t_end, direction="down"):
    """垂直擦除揭示。"""
    progress = np.clip((t - t_start) / (t_end - t_start), 0, 1)
    if direction == "up":
        progress = 1 - progress
    return mask_gradient_v(g, start=progress - 0.05, end=progress + 0.05)

def mask_dissolve(g, t, t_start, t_end, seed=42):
    """隨機像素溶解 —— 雜訊閥值從 0 掃描到 1。"""
    progress = np.clip((t - t_start) / (t_end - t_start), 0, 1)
    rng = np.random.RandomState(seed)
    noise = rng.random((g.rows, g.cols)).astype(np.float32)
    return (noise < progress).astype(np.float32)
```

### 遮罩布林運算

```python
def mask_union(a, b):
    """聯集 (OR) —— 兩遮罩任一有效處皆可見。"""
    return np.maximum(a, b)

def mask_intersect(a, b):
    """交集 (AND) —— 僅在兩遮罩皆有效處可見。"""
    return np.minimum(a, b)

def mask_subtract(a, b):
    """差集 (A - B) —— A 有效但 B 無效處可見。"""
    return np.clip(a - b, 0, 1)

def mask_invert(m):
    """反相 (NOT) —— 翻轉遮罩。"""
    return 1.0 - m
```

### 將遮罩應用於畫布

```python
def apply_mask_canvas(canvas, mask, bg_canvas=None):
    """將網格解析度遮罩應用於像素畫布。
    透過最近鄰插值將遮罩從 (rows, cols) 擴展至 (VH, VW)。

    canvas: uint8 (VH, VW, 3)
    mask: float32 (rows, cols) [0,1]
    bg_canvas: 遮罩為 0 處顯示的內容。None = 黑色。
    """
    # 擴展遮罩至像素解析度
    mask_px = np.repeat(np.repeat(mask, canvas.shape[0] // mask.shape[0] + 1, axis=0),
                        canvas.shape[1] // mask.shape[1] + 1, axis=1)
    mask_px = mask_px[:canvas.shape[0], :canvas.shape[1]]

    if bg_canvas is not None:
        return np.clip(canvas * mask_px[:, :, None] +
                       bg_canvas * (1 - mask_px[:, :, None]), 0, 255).astype(np.uint8)
    return np.clip(canvas * mask_px[:, :, None], 0, 255).astype(np.uint8)

def apply_mask_vf(vf_a, vf_b, mask):
    """在數值場層級應用遮罩 —— 空間性混合兩個數值場。
    所有陣列均為 (rows, cols) float32。"""
    return vf_a * mask + vf_b * (1 - mask)
```

---

## PixelBlendStack

用於多圖層合成的高階封裝類別：

```python
class PixelBlendStack:
    def __init__(self):
        self.layers = []

    def add(self, canvas, mode="normal", opacity=1.0):
        self.layers.append((canvas, mode, opacity))
        return self

    def composite(self):
        if not self.layers:
            return np.zeros((VH, VW, 3), dtype=np.uint8)
        result = self.layers[0][0]
        for canvas, mode, opacity in self.layers[1:]:
            result = blend_canvas(result, canvas, mode, opacity)
        return result
```

## 文字底色 (可讀性遮罩)

當在繁忙的多網格 ASCII 背景上放置可讀文字時，文字會與背景混合而變得難以辨認。**請務必在文字區域下方套用深色底色。**

技術細節：計算所有文字字形的邊界框，建立一個覆蓋該區域（包含補白）的高斯模糊深色遮罩，在渲染文字前先將背景乘以 `(1 - mask * darkness)`。

```python
from scipy.ndimage import gaussian_filter

def apply_text_backdrop(canvas, glyphs, padding=80, darkness=0.75):
    """為了提高可讀性，調暗文字後方的背景。
    
    應在渲染背景後、渲染文字前調用。
    
    參數：
        canvas: (VH, VW, 3) uint8 背景
        glyphs: 包含 {"x": float, "y": float, ...} 的字形位置列表
        padding: 文字邊界框周圍的像素補白
        darkness: 0.0 = 不調暗, 1.0 = 全黑
    返回：
        調暗後的畫布 (uint8)
    """
    if not glyphs:
        return canvas
    xs = [g['x'] for g in glyphs]
    ys = [g['y'] for g in glyphs]
    x0 = max(0, int(min(xs)) - padding)
    y0 = max(0, int(min(ys)) - padding)
    x1 = min(VW, int(max(xs)) + padding + 50)   # 額外考量字元寬度
    y1 = min(VH, int(max(ys)) + padding + 60)   # 額外考量字元高度
    
    # 帶有高斯模糊的柔和深色遮罩，以實現羽化邊緣
    mask = np.zeros((VH, VW), dtype=np.float32)
    mask[y0:y1, x0:x1] = 1.0
    mask = gaussian_filter(mask, sigma=padding * 0.6)
    
    factor = 1.0 - mask * darkness
    return (canvas.astype(np.float32) * factor[:, :, np.newaxis]).astype(np.uint8)
```

### 在渲染流程中的用法

插入背景渲染與文字渲染之間：

```python
# 1. 渲染背景 (多網格 ASCII 效果)
bg = render_background(cfg, t)

# 2. 調暗文字區域後方
bg = apply_text_backdrop(bg, frame_glyphs, padding=80, darkness=0.75)

# 3. 在上方渲染文字 (現在在深色底色上清晰可讀)
bg = text_renderer.render(bg, frame_glyphs, color=(255, 255, 255))
```

對於文字始終置中的場景，可結合 **反向暈影 (reverse vignette)**（參見 shaders.md）—— 反向暈影提供持久的中心黑暗區，而 backdrop 則處理逐影格的字形位置。

## 外部佈局 Oracle (Oracle) 模式

對於文字密集且需要根據障礙物（形狀、圖示、其他文字）動態重排的影片，請使用外部佈局引擎預先計算字形位置，並透過 JSON 饋送給 Python 渲染器。

### 架構

```
佈局引擎 (瀏覽器/Node.js)  →  layouts.json  →  Python ASCII 渲染器
         ↑                                                    ↑
   計算逐影格的                                     讀取字形位置，
   字形 (x,y) 位置                                  透過完整的效果流程
   及避障重排                                       渲染為 ASCII 字元
```

### JSON 交換格式

```json
{
  "meta": {
    "canvas_width": 1080, "canvas_height": 1080,
    "fps": 24, "total_frames": 1248,
    "fonts": {
      "body": {"charW": 12.04, "charH": 24, "fontSize": 20},
      "hero": {"charW": 24.08, "charH": 48, "fontSize": 40}
    }
  },
  "scenes": [
    {
      "id": "scene_name",
      "start_frame": 0, "end_frame": 96,
      "frames": {
        "0": {
          "glyphs": [
            {"char": "H", "x": 287.1, "y": 400.0, "alpha": 1.0},
            {"char": "e", "x": 311.2, "y": 400.0, "alpha": 1.0}
          ],
          "obstacles": [
            {"type": "circle", "cx": 540, "cy": 540, "r": 80},
            {"type": "rect", "x": 300, "y": 500, "w": 120, "h": 80}
          ]
        }
      }
    }
  ]
}
```

### 適用時機

- 文字需圍繞移動物體動態重排
- 逐字動畫（揭示、散射、物理效果）
- 需要精確測量的多樣排版
- 任何 Python Pillow 文字佈局不足以應付的情況

### 「不」適用時機

- 靜態置中文字（直接使用 PIL `draw.text()` 即可）
- 僅有淡入/淡出而無空間動畫的文字
- 簡單的打字機效果（在 Python 中使用字元計數器處理即可）

### 執行佈局 Oracle

使用 Playwright 在無頭瀏覽器中執行佈局引擎：

```javascript
// extract.mjs
import { chromium } from 'playwright';
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
await page.goto(`file://${oraclePath}`);
await page.waitForFunction(() => window.__ORACLE_DONE__ === true, null, { timeout: 60000 });
const result = await page.evaluate(() => window.__ORACLE_RESULT__);
writeFileSync('layouts.json', JSON.stringify(result));
await browser.close();
```

### 在 Python 中使用

```python
# 在渲染器中，將像素位置映射到畫布：
for glyph in frame_data['glyphs']:
    char, px, py = glyph['char'], glyph['x'], glyph['y']
    alpha = glyph.get('alpha', 1.0)
    # 使用 PIL draw.text() 在精確的像素位置渲染
    draw.text((px, py), char, fill=(int(255*alpha),)*3, font=font)
```

JSON 中的障礙物也可以渲染為發光的 ASCII 形狀（圓形、矩形），以視覺化重排區域。
