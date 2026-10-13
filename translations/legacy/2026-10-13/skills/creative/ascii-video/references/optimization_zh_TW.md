# 優化參考 (Optimization Reference)

> **另請參閱：** [architecture_zh_TW.md](architecture_zh_TW.md) · [composition_zh_TW.md](composition_zh_TW.md) · [scenes_zh_TW.md](scenes_zh_TW.md) · [shaders_zh_TW.md](shaders_zh_TW.md) · [inputs_zh_TW.md](inputs_zh_TW.md) · [troubleshooting_zh_TW.md](troubleshooting_zh_TW.md)

## 硬體檢測 (Hardware Detection)

在腳本啟動時檢測使用者的硬體，並自動適配渲染參數。絕不要寫死工作進程 (worker) 數量或解析度。

### CPU 與記憶體檢測

```python
import multiprocessing
import platform
import shutil
import os

def detect_hardware():
    """檢測硬體能力並返回渲染配置。"""
    cpu_count = multiprocessing.cpu_count()
    
    # 預留 1-2 個核心給作業系統與 ffmpeg 編碼使用
    if cpu_count >= 16:
        workers = cpu_count - 2
    elif cpu_count >= 8:
        workers = cpu_count - 1
    elif cpu_count >= 4:
        workers = cpu_count - 1
    else:
        workers = max(1, cpu_count)
    
    # 記憶體檢測（平台相關）
    try:
        if platform.system() == "Darwin":
            import subprocess
            mem_bytes = int(subprocess.check_output(["sysctl", "-n", "hw.memsize"]).strip())
        elif platform.system() == "Linux":
            with open("/proc/meminfo") as f:
                for line in f:
                    if line.startswith("MemTotal"):
                        mem_bytes = int(line.split()[1]) * 1024
                        break
        else:
            mem_bytes = 8 * 1024**3  # 未知平台預設為 8GB
    except Exception:
        mem_bytes = 8 * 1024**3

    mem_gb = mem_bytes / (1024**3)
    
    # 每個工作進程約佔用 50-150MB（視網格大小而定）
    # 若記憶體吃緊，則限制工作進程數量
    mem_per_worker_mb = 150
    max_workers_by_mem = int(mem_gb * 1024 * 0.6 / mem_per_worker_mb)  # 使用 60% 的 RAM
    workers = min(workers, max_workers_by_mem)
    
    # 檢查 ffmpeg 可用性與編解碼器支援
    has_ffmpeg = shutil.which("ffmpeg") is not None
    
    return {
        "cpu_count": cpu_count,
        "workers": workers,
        "mem_gb": mem_gb,
        "platform": platform.system(),
        "arch": platform.machine(),
        "has_ffmpeg": has_ffmpeg,
    }
```

### 自適應品質配置文件 (Adaptive Quality Profiles)

根據硬體情況縮放解析度、FPS、CRF 和網格密度：

```python
def quality_profile(hw, target_duration_s, user_preference="auto"):
    """
    返回適配硬體的渲染設定。
    user_preference: "auto", "draft", "preview", "production", "max"
    """
    if user_preference == "draft":
        return {"vw": 960, "vh": 540, "fps": 12, "crf": 28, "workers": min(4, hw["workers"]),
                "grid_scale": 0.5, "shaders": "minimal", "particles_max": 200}
    
    if user_preference == "preview":
        return {"vw": 1280, "vh": 720, "fps": 15, "crf": 25, "workers": hw["workers"],
                "grid_scale": 0.75, "shaders": "standard", "particles_max": 500}
    
    if user_preference == "max":
        return {"vw": 3840, "vh": 2160, "fps": 30, "crf": 15, "workers": hw["workers"],
                "grid_scale": 2.0, "shaders": "full", "particles_max": 3000}
    
    # "production" 或 "auto"
    # 自動檢測：估算渲染時間，若過長則降級
    n_frames = int(target_duration_s * 24)
    est_seconds_per_frame = 0.18  # 1080p 下約 180ms
    est_total_s = n_frames * est_seconds_per_frame / max(1, hw["workers"])
    
    if hw["mem_gb"] < 4 or hw["cpu_count"] <= 2:
        # 低階配置：720p, 15fps
        return {"vw": 1280, "vh": 720, "fps": 15, "crf": 23, "workers": hw["workers"],
                "grid_scale": 0.75, "shaders": "standard", "particles_max": 500}
    
    if est_total_s > 3600:  # 若預計耗時超過一小時
        # 降級至 720p 以加速渲染
        return {"vw": 1280, "vh": 720, "fps": 24, "crf": 20, "workers": hw["workers"],
                "grid_scale": 0.75, "shaders": "standard", "particles_max": 800}
    
    # 標準生產配置：1080p 24fps
    return {"vw": 1920, "vh": 1080, "fps": 24, "crf": 20, "workers": hw["workers"],
            "grid_scale": 1.0, "shaders": "full", "particles_max": 1200}


def apply_quality_profile(profile):
    """根據品質配置文件設定全局變數。"""
    global VW, VH, FPS, N_WORKERS
    VW = profile["vw"]
    VH = profile["vh"]
    FPS = profile["fps"]
    N_WORKERS = profile["workers"]
    # 網格大小隨解析度縮放
    # CRF 傳遞給 ffmpeg 編碼器
    # 著色器集決定啟用的後處理效果
```

### CLI 整合

```python
parser = argparse.ArgumentParser()
parser.add_argument("--quality", choices=["draft", "preview", "production", "max", "auto"],
                    default="auto", help="渲染品質預設值")
parser.add_argument("--aspect", choices=["landscape", "portrait", "square"],
                    default="landscape", help="長寬比預設值")
parser.add_argument("--workers", type=int, default=0, help="覆寫工作進程數量 (0=自動)")
parser.add_argument("--resolution", type=str, default="", help="覆寫解析度，例如 1280x720")
args = parser.parse_args()

hw = detect_hardware()
if args.workers > 0:
    hw["workers"] = args.workers
profile = quality_profile(hw, target_duration, args.quality)

# 應用長寬比預設值（在手動覆寫解析度之前）
ASPECT_PRESETS = {
    "landscape": (1920, 1080),
    "portrait":  (1080, 1920),
    "square":    (1080, 1080),
}
if args.aspect != "landscape" and not args.resolution:
    profile["vw"], profile["vh"] = ASPECT_PRESETS[args.aspect]

if args.resolution:
    w, h = args.resolution.split("x")
    profile["vw"], profile["vh"] = int(w), int(h)
apply_quality_profile(profile)

log(f"硬體：{hw['cpu_count']} 核心, {hw['mem_gb']:.1f}GB RAM, {hw['platform']}")
log(f"渲染：{profile['vw']}x{profile['vh']} @{profile['fps']}fps, "
    f"CRF {profile['crf']}, {profile['workers']} 個工作進程")
```

### 直向模式 (Portrait Mode) 注意事項

直向 (1080x1920) 與橫向 1080p 的像素總數相同，因此效能相當。但構圖模式有所不同：

| 考量點 | 橫向 (Landscape) | 直向 (Portrait) |
|---------|-----------|----------|
| `lg` 下的網格欄數 | 160 | 90 |
| `lg` 下的網格列數 | 45 | 80 |
| 文字行最大字元數 | 置中約 50 字 | 置中約 25-30 字 |
| 垂直雨滴 | 移動路徑短 | 長且具戲劇性的路徑 |
| 水平頻譜 | 全寬顯示 | 需旋轉或壓縮 |
| 放射狀效果 | 自然的圓形 | 瘦長橢圓（長寬比修正可解決） |
| 粒子爆炸 | 寬向擴散 | 高向擴散 |
| 文字堆疊 | 3-4 行較舒適 | 8-10 行較舒適 |
| 引用語佈局 | 2-3 個長行 | 5-6 個短行 |

**直向優化模式：**
- 垂直雨滴/矩陣效果自然獲得增強 —— 擁有更長的下落路徑。
- 火柱可穿過更多的螢幕空間上升。
- 上升的餘燼/粒子擁有更多的垂直跑道。
- 文字可以更密集地垂直堆疊。
- 只要應用長寬比修正（GridLayer 自動處理），放射狀效果即可正常運作。
- 頻譜條可以旋轉 90 度（從底部升起的垂直條）。

**直向文字排版：**
```python
def layout_text_portrait(text, max_chars_per_line=25, grid=None):
    """將文字拆分成適合直向顯示的短行。"""
    words = text.split()
    lines = []; current = ""
    for w in words:
        if len(current) + len(w) + 1 > max_chars_per_line:
            lines.append(current.strip())
            current = w + " "
        else:
            current += w + " "
    if current.strip():
        lines.append(current.strip())
    return lines
```

## 效能預算 (Performance Budget)

目標：每影格 100-200ms（單執行緒 5-10 fps，8 個工作進程 40-80 fps）。

| 組件 | 耗時 | 備註 |
|-----------|------|-------|
| 特徵提取 | 1-5ms | 渲染前為所有影格預先計算 |
| 效果函式 | 2-15ms | 向量化 numpy，避免 Python 迴圈 |
| 字元渲染 | 80-150ms | **瓶頸** —— 逐單元的 Python 迴圈 |
| 著色器流水線 | 5-25ms | 取決於啟用的著色器數量 |
| ffmpeg 編碼 | ~5ms | 透過管道緩衝攤銷耗時 |

## 點陣圖預先點陣化 (Bitmap Pre-Rasterization)

在初始化時點陣化每個字元，而非逐影格處理：

```python
# 初始化時執行一次
for c in all_characters:
    img = Image.new("L", (cell_w, cell_h), 0)
    ImageDraw.Draw(img).text((0, 0), c, fill=255, font=font)
    bitmaps[c] = np.array(img, dtype=np.float32) / 255.0  # 使用 float32 以加速乘法

# 渲染時 —— 快速查表
bitmap = bitmaps[char]
canvas[y:y+ch, x:x+cw] = np.maximum(canvas[y:y+ch, x:x+cw],
                                      (bitmap[:,:,None] * color).astype(np.uint8))
```

從所有調色盤與疊加文字中收集所有字元放入初始化集合。對遺漏的字元使用延遲初始化。

## 預渲染背景紋理 (Pre-Rendered Background Textures)

對於字元不需要逐格改變的背景，可作為 `_render_vf()` 的替代方案。在初始化時預先烘焙一張靜態 ASCII 紋理，隨後每格只需乘以逐單元的色彩場。這是一次矩陣乘法對比數千次點陣圖貼圖 (blit)。

適用時機：背景圖層使用固定字元調色盤，且每格僅有顏色/亮度變化。不適用於字元選擇取決於變動數值場的圖層。

### 初始化：烘焙紋理

```python
# 在 GridLayer.__init__ 中：
self._bg_row_idx = np.clip(
    (np.arange(VH) - self.oy) // self.ch, 0, self.rows - 1
)
self._bg_col_idx = np.clip(
    (np.arange(VW) - self.ox) // self.cw, 0, self.cols - 1
)
self._bg_textures = {}

def make_bg_texture(self, palette):
    """預先渲染一張靜態 ASCII 紋理（灰階 float32）。"""
    if palette not in self._bg_textures:
        texture = np.zeros((VH, VW), dtype=np.float32)
        rng = random.Random(12345)
        ch_list = [c for c in palette if c != " " and c in self.bm]
        if not ch_list:
            ch_list = list(self.bm.keys())[:5]
        for row in range(self.rows):
            y = self.oy + row * self.ch
            if y + self.ch > VH:
                break
            for col in range(self.cols):
                x = self.ox + col * self.cw
                if x + self.cw > VW:
                    break
                bm = self.bm[rng.choice(ch_list)]
                texture[y:y+self.ch, x:x+self.cw] = bm
        self._bg_textures[palette] = texture
    return self._bg_textures[palette]
```

### 渲染：色彩場 x 快取紋理

```python
def render_bg(self, color_field, palette=PAL_CIRCUIT):
    """快速背景：預渲染 ASCII 紋理 * 逐單元色彩場。
    color_field: (rows, cols, 3) uint8. 返回 (VH, VW, 3) uint8。"""
    texture = self.make_bg_texture(palette)
    # 透過預先計算的索引圖將單元色彩擴展至像素座標
    color_px = color_field[
        self._bg_row_idx[:, None], self._bg_col_idx[None, :]
    ].astype(np.float32)
    return (texture[:, :, None] * color_px).astype(np.uint8)
```

### 在場景中的用法

```python
# 從效果場構建逐單元色彩（開銷極低 —— 僅 rows*cols，而非 VH*VW）
hue = ((t * 0.05 + val * 0.2) % 1.0).astype(np.float32)
R, G, B = hsv2rgb(hue, np.full_like(val, 0.5), val)
color_field = mkc(R, G, B, g.rows, g.cols)  # (rows, cols, 3) uint8

# 渲染背景 —— 單次矩陣乘法，無逐單元迴圈
canvas_bg = g.render_bg(color_field, PAL_DENSE)
```

紋理初始化迴圈僅執行一次，並按調色盤快取。每影格成本僅為一次花式索引查表 + 一次廣播乘法 —— 對於密集背景，比 `render()` 中的逐單元點陣圖貼圖迴圈快上好幾個數量級。

## 座標陣列快取 (Coordinate Array Caching)

在初始化時預先計算所有網格相對座標陣列，而非逐影格計算：

```python
# 這些陣列大小為 O(rows*cols)，且在每個效果中都會用到
self.rr = np.arange(rows)[:, None]    # 行索引
self.cc = np.arange(cols)[None, :]    # 欄索引
self.dist = np.sqrt(dx**2 + dy**2)   # 離中心距離
self.angle = np.arctan2(dy, dx)       # 離中心角度
self.dist_n = ...                      # 歸一化距離
```

## 向量化效果模式 (Vectorized Effect Patterns)

### 避免在效果中使用逐單元 Python 迴圈

渲染迴圈（合成點陣圖）無可避免地是逐單元的。但效果函式必須是全向量化的 numpy —— 絕不要在 Python 中迭代行/列。

**錯誤示範 (O(rows*cols) Python 迴圈)：**
```python
for r in range(rows):
    for c in range(cols):
        val[r, c] = math.sin(c * 0.1 + t) * math.cos(r * 0.1 - t)
```

**正確示範 (向量化)：**
```python
val = np.sin(g.cc * 0.1 + t) * np.cos(g.rr * 0.1 - t)
```

### 向量化矩陣雨 (Vectorized Matrix Rain)

傳統的「每欄每軌跡像素」迴圈是僅次於渲染迴圈的第二大瓶頸。請改用 numpy 花式索引：

```python
# 取代巢狀的 Python 欄位與軌跡像素迴圈：
# 一次性為所有活動的軌跡像素構建行索引陣列
all_rows = []
all_cols = []
all_fades = []
for c in range(cols):
    head = int(S["ry"][c])
    trail_len = S["rln"][c]
    for i in range(trail_len):
        row = head - i
        if 0 <= row < rows:
            all_rows.append(row)
            all_cols.append(c)
            all_fades.append(1.0 - i / trail_len)

# 向量化賦值
ar = np.array(all_rows)
ac = np.array(all_cols)
af = np.array(all_fades, dtype=np.float32)
# 使用花式索引批量分配字元與顏色
ch[ar, ac] = ...  # 向量化字元分配
co[ar, ac, 1] = (af * bri * 255).astype(np.uint8)  # 綠色通道
```

### 向量化火柱

相同的模式 —— 累積索引陣列，批量賦值：

```python
fire_val = np.zeros((rows, cols), dtype=np.float32)
for fi in range(n_cols):
    fx_c = int((fi * cols / n_cols + np.sin(t * 2 + fi * 0.7) * 3) % cols)
    height = int(energy * rows * 0.7)
    dy = np.arange(min(height, rows))
    fr = rows - 1 - dy
    frac = dy / max(height, 1)
    # 寬度分佈：底部的火柱更寬
    for dx in range(-1, 2):  # 3 格寬的火柱
        c = fx_c + dx
        if 0 <= c < cols:
            fire_val[fr, c] = np.maximum(fire_val[fr, c],
                                          (1 - frac * 0.6) * (0.5 + rms * 0.5))
# 現在透過一次向量化傳遞將 fire_val 映射到字元與顏色
```

## 文字密集場景下的 PIL 字串渲染

當渲染大量長文字字串（捲動跑馬燈、打字機序列、創意點子流）時，可作為逐單元點陣圖貼圖的替代方案。利用 PIL 原生的 `ImageDraw.text()`，它在一次 C 調用中即可渲染整行字串，而非每字元執行一次 Python 迴圈點陣圖貼圖。

典型收益：一個擁有 56 行跑馬燈的場景僅需 56 次 PIL `text()` 調用，而非約 1 萬次獨立的點陣圖貼圖。

適用時機：場景需要渲染多行可讀的文字字串。不適用於稀疏或空間分散的單個字元（此類情況請使用標準 `render()`）。

```python
from PIL import Image, ImageDraw

def render_text_layer(grid, rows_data, font):
    """透過 PIL 渲染密集文字行，取代逐單元的點陣圖貼圖。

    參數：
        grid: GridLayer 實例 (提供 oy, ch, ox, 字體指標)
        rows_data: (行索引, 文字字串, RGB 元組) 列表 —— 每行一條
        font: PIL ImageFont 實例 (grid.font)

    返回：
        uint8 陣列 (VH, VW, 3) —— 帶有渲染文字的畫布
    """
    img = Image.new("RGB", (VW, VH), (0, 0, 0))
    draw = ImageDraw.Draw(img)
    for row_idx, text, color in rows_data:
        y = grid.oy + row_idx * grid.ch
        if y + grid.ch > VH:
            break
        draw.text((grid.ox, y), text, fill=color, font=font)
    return np.array(img)
```

### 在跑馬燈場景中的用法

```python
# 構建跑馬燈數據（每行文字 + 顏色）
rows_data = []
for row in range(n_tickers):
    text = build_ticker_text(row, t)       # 捲動的子字串
    color = hsv2rgb_scalar(hue, 0.85, bri) # (R, G, B) 元組
    rows_data.append((row, text, color))

# 單次 PIL 傳遞取代數千次點陣圖貼圖
canvas_tickers = render_text_layer(g_md, rows_data, g_md.font)

# 正常與其他圖層混合
result = blend_canvas(canvas_bg, canvas_tickers, "screen", 0.9)
```

這純粹是渲染層級的優化 —— 視覺輸出相同，但繪圖調用次數減少。對於根據數值場個別放置字元的稀疏欄位，仍需使用網格的 `render()` 方法。

## Bloom 優化

**切勿使用 `scipy.ndimage.uniform_filter`** —— 實測耗時 424ms/影格。

請改用 4x 下取樣 + 手動方框模糊 —— 84ms/影格 (快了 5 倍)：

```python
sm = canvas[::4, ::4].astype(np.float32)  # 4x 下取樣
br = np.where(sm > threshold, sm, 0)
for _ in range(3):                          # 3 次手動方框模糊
    p = np.pad(br, ((1,1),(1,1),(0,0)), mode='edge')
    br = (p[:-2,:-2] + p[:-2,1:-1] + p[:-2,2:] +
          p[1:-1,:-2] + p[1:-1,1:-1] + p[1:-1,2:] +
          p[2:,:-2] + p[2:,1:-1] + p[2:,2:]) / 9.0
bl = np.repeat(np.repeat(br, 4, axis=0), 4, axis=1)[:H, :W]
```

## 暈影 (Vignette) 快取

距離場取決於解析度與強度，且不會隨影格改變：

```python
_vig_cache = {}
def sh_vignette(canvas, strength):
    key = (canvas.shape[0], canvas.shape[1], round(strength, 2))
    if k not in _vig_cache:
        Y = np.linspace(-1, 1, H)[:, None]
        X = np.linspace(-1, 1, W)[None, :]
        _vig_cache[key] = np.clip(1.0 - np.sqrt(X**2+Y**2) * strength, 0.15, 1).astype(np.float32)
    return np.clip(canvas * _vig_cache[key][:,:,None], 0, 255).astype(np.uint8)
```

CRT 桶形畸變也採用相同的模式（快取重新映射座標）。

## 電影顆粒 (Film Grain) 優化

在半解析度下生成雜訊，再平鋪擴大：

```python
noise = np.random.randint(-amt, amt+1, (H//2, W//2, 1), dtype=np.int16)
noise = np.repeat(np.repeat(noise, 2, axis=0), 2, axis=1)[:H, :W]
```

2x 的區塊狀顆粒看起來效果與電影顆粒一致，但隨機生成的開銷僅為 1/4。

## 並行渲染 (Parallel Rendering)

### 工作進程架構 (Worker Architecture)

```python
hw = detect_hardware()
N_WORKERS = hw["workers"]

# 分批切割（適用於非片段式架構）
batch_size = (n_frames + N_WORKERS - 1) // N_WORKERS
batches = [(i, i*batch_size, min((i+1)*batch_size, n_frames), features, seg_path) ...]

with multiprocessing.Pool(N_WORKERS) as pool:
    segments = pool.starmap(render_batch, batches)
```

### 逐片段並行（分段影片的首選）

```python
from concurrent.futures import ProcessPoolExecutor, as_completed

with ProcessPoolExecutor(max_workers=N_WORKERS) as pool:
    futures = {pool.submit(render_clip, seg, features, path): seg["id"]
               for seg, path in clip_args}
    for fut in as_completed(futures):
        clip_id = futures[fut]
        try:
            fut.result()
            log(f"  {clip_id} 完成")
        except Exception as e:
            log(f"  {clip_id} 失敗：{e}")
```

### 工作進程隔離

每個工作進程：
- 建立各自的 `Renderer` 實例（包含完整的網格與點陣圖初始化）。
- 開啟各自的 ffmpeg 子進程。
- 擁有獨立的隨機種子 (`random.seed(batch_id * 10000)`)。
- 寫入各自的片段檔案與 stderr 記錄。

### ffmpeg 管道安全

**至關重要**：針對長時間執行的 ffmpeg，切勿使用 `stderr=subprocess.PIPE`。stderr 緩衝區在約 64KB 時就會填滿並導致死鎖：

```python
# 錯誤示範 —— 會導致死鎖
pipe = subprocess.Popen(cmd, stdin=subprocess.PIPE, stderr=subprocess.PIPE)

# 正確示範 —— stderr 輸出到檔案
stderr_fh = open(err_path, "w")
pipe = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=stderr_fh)
# ... 寫入所有影格 ...
pipe.stdin.close()
pipe.wait()
stderr_fh.close()
```

### 拼接 (Concatenation)

```python
with open(concat_file, "w") as cf:
    for seg in segments:
        cf.write(f"file '{seg}'\n")

cmd = ["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", concat_file]
if audio_path:
    cmd += ["-i", audio_path, "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-shortest"]
else:
    cmd += ["-c:v", "copy"]
cmd.append(output_path)
subprocess.run(cmd, capture_output=True, check=True)
```

## 粒子系統效能

根據品質配置文件限制粒子數量：

| 系統 | 低階 (Low) | 標準 (Standard) | 高階 (High) |
|--------|-----|----------|------|
| 爆炸 (Explosion) | 300 | 1000 | 2500 |
| 餘燼 (Embers) | 500 | 1500 | 3000 |
| 星場 (Starfield) | 300 | 800 | 1500 |
| 溶解 (Dissolve) | 200 | 600 | 1200 |

透過截斷列表進行刪減：
```python
MAX_PARTICLES = profile.get("particles_max", 1200)
if len(S["px"]) > MAX_PARTICLES:
    for k in ("px", "py", "vx", "vy", "life", "char"):
        S[k] = S[k][-MAX_PARTICLES:]  # 保留最新的
```

## 記憶體管理

- 特徵陣列：為所有影格預先計算，透過 fork 語義 (COW) 在工作進程間共享。
- 畫布：每個工作進程分配一次，重複使用 (`np.zeros(...)`)。
- 字元陣列：每影格分配一次（開銷低 —— rows*cols 的 U1 字串）。
- 點陣圖快取：每種網格大小約 500KB，每個工作進程初始化一次。

每個工作進程總計記憶體：約 50-150MB。8 個工作進程總計約 400-800MB。

針對低記憶體系統 (< 4GB)，應減少工作進程數量並使用較小的網格。

## 亮度驗證 (Brightness Verification)

渲染後，抽查樣本時間點的亮度：

```python
for t in [2, 30, 60, 120, 180]:
    cmd = ["ffmpeg", "-ss", str(t), "-i", output_path,
           "-frames:v", "1", "-f", "rawvideo", "-pix_fmt", "gray", "-"]
    r = subprocess.run(cmd, capture_output=True)
    arr = np.frombuffer(r.stdout, dtype=np.uint8)
    print(f"t={t}s  平均={arr.mean():.1f}  最大={arr.max()}")
```

目標：安靜章節平均值 > 5，活動章節平均值 > 15。若持續過低，請調高效果中的亮度底限及/或全局增益倍數。

## 渲染時間估算

隨硬體配置縮放。基線：1080p, 24fps, 每影格每進程約 180ms。

| 時長 | 影格數 | 4 進程 | 8 進程 | 16 進程 |
|----------|--------|-----------|-----------|------------|
| 30 秒 | 720 | ~3 分鐘 | ~2 分鐘 | ~1 分鐘 |
| 2 分鐘 | 2,880 | ~13 分鐘 | ~7 分鐘 | ~4 分鐘 |
| 3.5 分鐘 | 5,040 | ~23 分鐘 | ~12 分鐘 | ~6 分鐘 |
| 5 分鐘 | 7,200 | ~33 分鐘 | ~17 分鐘 | ~9 分鐘 |
| 10 分鐘 | 14,400 | ~65 分鐘 | ~33 分鐘 | ~17 分鐘 |

720p 耗時約乘以 0.5；4K 耗時約乘以 4。

更複雜的效果（大量粒子、密集網格、額外的著色器傳遞）會增加約 20-50% 的耗時。

---

## 暫存檔案清理

渲染過程會產生大量中間檔案。應在最終拼接/混流步驟後進行清理。

### 待清理檔案

| 檔案類型 | 來源 | 位置 |
|-----------|--------|----------|
| WAV 提取物 | `ffmpeg -i input.mp3 ... tmp.wav` | `tempfile.mktemp()` 或專案目錄 |
| 片段影片 | `render_clip()` 輸出 | `segments/seg_00.mp4` 等 |
| 拼接列表 | ffmpeg concat demuxer 輸入 | `segments/concat.txt` |
| ffmpeg stderr 日誌 | 重新導向至檔案以便偵錯 | 專案目錄下的 `*.log` |
| 特徵快取 | pickled numpy 陣列 | `*.pkl` 或 `*.npz` |

### 清理函式

```python
import glob
import tempfile
import shutil

def cleanup_render_artifacts(segments_dir="segments", keep_final=True):
    """在成功渲染後移除中間檔案。
    
    請在驗證最終輸出存在且可正常播放後調用。
    
    參數：
        segments_dir: 包含片段影片與拼接列表的目錄
        keep_final: 若為 True，僅刪除中間檔案（保留最終輸出）
    """
    removed = []
    
    # 1. 片段影片
    if os.path.isdir(segments_dir):
        shutil.rmtree(segments_dir)
        removed.append(f"目錄：{segments_dir}")
    
    # 2. 暫存 WAV 檔案
    for wav in glob.glob("*.wav"):
        if wav.startswith("tmp") or wav.startswith("extracted_"):
            os.remove(wav)
            removed.append(wav)
    
    # 3. ffmpeg stderr 日誌
    for log in glob.glob("ffmpeg_*.log"):
        os.remove(log)
        removed.append(log)
    
    # 4. 特徵快取（選用 —— 保留有助於重新渲染）
    # for cache in glob.glob("features_*.npz"):
    #     os.remove(cache)
    #     removed.append(cache)
    
    print(f"已清理 {len(removed)} 個產出物：{removed}")
    return removed
```

### 與渲染流水線整合

在主渲染腳本結尾、最終輸出驗證後調用清理函式：

```python
# 在 main() 結尾
if os.path.exists(output_path) and os.path.getsize(output_path) > 1000:
    cleanup_render_artifacts(segments_dir="segments")
    print(f"完成。輸出檔案：{output_path}")
else:
    print("警告：最終輸出缺失或為空 —— 跳過清理步驟")
```

### 暫存檔案最佳實踐

- 使用 `tempfile.mkdtemp()` 建立片段目錄 —— 避免污染專案目錄。
- 使用 `tempfile.mktemp(suffix=".wav")` 命名 WAV 提取物，使其位於作業系統暫存目錄。
- 為了偵錯，可設定 `KEEP_INTERMEDIATES=1` 環境變數來跳過清理。
- 特徵快取 (`.npz`) 存儲成本低但計算成本高 —— 預設建議保留。
