# 架構參考 (Architecture Reference)

> **另請參閱：** [composition_zh_TW.md](composition_zh_TW.md) · [effects_zh_TW.md](effects_zh_TW.md) · [scenes_zh_TW.md](scenes_zh_TW.md) · [shaders_zh_TW.md](shaders_zh_TW.md) · [inputs_zh_TW.md](inputs_zh_TW.md) · [optimization_zh_TW.md](optimization_zh_TW.md) · [troubleshooting_zh_TW.md](troubleshooting_zh_TW.md)

## 網格系統 (Grid System)

### 解析度預設值 (Resolution Presets)

```python
RESOLUTION_PRESETS = {
    "landscape":  (1920, 1080),  # 16:9 — YouTube, 預設
    "portrait":   (1080, 1920),  # 9:16 — TikTok, Reels, Stories
    "square":     (1080, 1080),  # 1:1  — Instagram 動態
    "ultrawide":  (2560, 1080),  # 21:9 — 電影感比例
    "landscape4k":(3840, 2160),  # 16:9 — 4K
    "portrait4k": (2160, 3840),  # 9:16 — 4K 直向
}

def get_resolution(preset="landscape", custom=None):
    """返回 (VW, VH) 元組。"""
    if custom:
        return custom
    return RESOLUTION_PRESETS.get(preset, RESOLUTION_PRESETS["landscape"])
```

### 多密度網格 (Multi-Density Grids)

預先初始化多個網格大小。在不同章節間切換以增加視覺多樣性。網格維度會根據解析度自動計算：

**橫向 (Landscape, 1920x1080)：**

| 鍵 (Key) | 字體大小 | 網格 (欄 x 列) | 用途 |
|-----|-----------|-------------------|-----|
| xs | 8 | 400x108 | 超密集數據場 |
| sm | 10 | 320x83 | 密集細節、雨滴、星場 |
| md | 16 | 192x56 | 預設平衡、轉場 |
| lg | 20 | 160x45 | 引用語/歌詞（1080p 下清晰可讀） |
| xl | 24 | 137x37 | 短句、大型標題 |
| xxl | 40 | 80x22 | 巨型文字、極簡風格 |

**直向 (Portrait, 1080x1920)：**

| 鍵 (Key) | 字體大小 | 網格 (欄 x 列) | 用途 |
|-----|-----------|-------------------|-----|
| xs | 8 | 225x192 | 超密集、長條數據欄 |
| sm | 10 | 180x148 | 密集細節、垂直雨滴 |
| md | 16 | 112x100 | 預設平衡 |
| lg | 20 | 90x80 | 可讀文字（居中約 30 字/行） |
| xl | 24 | 75x66 | 短句、垂直堆疊 |
| xxl | 40 | 45x39 | 巨型文字、極簡風格 |

**正方形 (Square, 1080x1080)：**

| 鍵 (Key) | 字體大小 | 網格 (欄 x 列) | 用途 |
|-----|-----------|-------------------|-----|
| sm | 10 | 180x83 | 密集細節 |
| md | 16 | 112x56 | 預設平衡 |
| lg | 20 | 90x45 | 可讀文字 |

**直向模式的主要差異：**
- 欄數較少（`lg` 為 90 欄，橫向則為 160 欄） —— 行度必須縮短或進行換行
- 列數多出許多（`lg` 為 80 列，橫向則為 45 列） —— 非常適合垂直堆疊構圖
- 長寬比修正翻轉：`asp = cw / ch` 仍然有效，但視覺重心轉為垂直方向
- 放射狀效果除非經過修正，否則會呈現狹長的橢圓形
- 垂直效果（雨滴、餘燼、火柱）會得到自然增強
- 水平效果（頻譜條、波形）則需要旋轉或壓縮

**直向模式下的文字網格大小**：建議使用 `lg` (20px) 處理 2-3 個詞的短行。最舒適的最大行長約為 25-30 個字元。對於較長的語句，請大膽拆分成多個短行並垂直堆疊 —— 直向模式有充足的垂直空間。`xl` (24px) 適用於單個單詞或極短的短語。

網格維度計算公式：`cols = VW // cell_width`, `rows = VH // cell_height`。

### 字體選擇 (Font Selection)

不要只寫死一種字體。應根據專案的氛圍選擇字體。雖然網格對齊需要等寬字體 (Monospace)，但不同字體各有性格：

| 字體 | 個性 | 平台 |
|------|-------------|----------|
| Menlo | 簡潔、中性、蘋果原生 | macOS |
| Monaco | 復古終端、緊湊 | macOS |
| Courier New | 經典打字機、寬大 | 跨平台 |
| SF Mono | 現代、間距緊密 | macOS |
| Consolas | Windows 原生、清晰 | Windows |
| JetBrains Mono | 工程師風格、支援合字 | 需安裝 |
| Fira Code | 幾何感、現代 | 需安裝 |
| IBM Plex Mono | 專業、權威 | 需安裝 |
| Source Code Pro | Adobe 风格、平衡 | 需安裝 |

**初始化時的字體檢測**：探測可用字體並優雅回退：

```python
import platform

def find_font(preferences):
    """按順序嘗試字體，返回第一個存在的路徑。"""
    for name, path in preferences:
        if os.path.exists(path):
            return path
    raise FileNotFoundError(f"未找到等寬字體。嘗試過：{[p for _,p in preferences]}")

FONT_PREFS_MACOS = [
    ("Menlo", "/System/Library/Fonts/Menlo.ttc"),
    ("Monaco", "/System/Library/Fonts/Monaco.ttf"),
    ("SF Mono", "/System/Library/Fonts/SFNSMono.ttf"),
    ("Courier", "/System/Library/Fonts/Courier.ttc"),
]
FONT_PREFS_LINUX = [
    ("DejaVu Sans Mono", "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"),
    ("Liberation Mono", "/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf"),
    ("Noto Sans Mono", "/usr/share/fonts/truetype/noto/NotoSansMono-Regular.ttf"),
    ("Ubuntu Mono", "/usr/share/fonts/truetype/ubuntu/UbuntuMono-R.ttf"),
]
FONT_PREFS_WINDOWS = [
    ("Consolas", r"C:\Windows\Fonts\consola.ttf"),
    ("Courier New", r"C:\Windows\Fonts\cour.ttf"),
    ("Lucida Console", r"C:\Windows\Fonts\lucon.ttf"),
    ("Cascadia Code", os.path.expandvars(r"%LOCALAPPDATA%\Microsoft\Windows\Fonts\CascadiaCode.ttf")),
    ("Cascadia Mono", os.path.expandvars(r"%LOCALAPPDATA%\Microsoft\Windows\Fonts\CascadiaMono.ttf")),
]

def _get_font_prefs():
    s = platform.system()
    if s == "Darwin":
        return FONT_PREFS_MACOS
    elif s == "Windows":
        return FONT_PREFS_WINDOWS
    return FONT_PREFS_LINUX

FONT_PREFS = _get_font_prefs()
```

**多字體渲染**：為不同圖層使用不同字體（例如：背景用一般等寬字體，疊加文字用粗體變體）。每個 GridLayer 擁有各自的字體實例：

```python
grid_bg = GridLayer(find_font(FONT_PREFS), 16)       # 背景
grid_text = GridLayer(find_font(BOLD_PREFS), 20)      # 可讀文字
```

### 收集所有字元

在初始化網格之前，收集所有需要預先點陣化點陣圖的字元：

```python
all_chars = set()
for pal in [PAL_DEFAULT, PAL_DENSE, PAL_BLOCKS, PAL_RUNE, PAL_KATA,
            PAL_GREEK, PAL_MATH, PAL_DOTS, PAL_BRAILLE, PAL_STARS,
            PAL_HALFFILL, PAL_HATCH, PAL_BINARY, PAL_MUSIC, PAL_BOX,
            PAL_CIRCUIT, PAL_ARROWS, PAL_HERMES]:  # ... 專案中使用的所有調色盤
    all_chars.update(pal)
# 加入任何疊加文字字元
all_chars.update("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,-:;!?/|")
all_chars.discard(" ")  # 空格不需要渲染
```

### GridLayer 初始化

每個網格會預先計算用於向量化效果運算的座標陣列。網格會自動適應任何解析度（橫向、直向、正方形）：

```python
class GridLayer:
    def __init__(self, font_path, font_size, vw=None, vh=None):
        """為任何解析度初始化網格。
        vw, vh：影片像素寬度/高度。預設為全局 VW, VH。"""
        vw = vw or VW; vh = vh or VH
        self.vw = vw; self.vh = vh

        self.font = ImageFont.truetype(font_path, font_size)
        asc, desc = self.font.getmetrics()
        bbox = self.font.getbbox("M")
        self.cw = bbox[2] - bbox[0]  # 字元單元寬度
        self.ch = asc + desc  # 至關重要：不是 textbbox 的高度

        self.cols = vw // self.cw
        self.rows = vh // self.ch
        self.ox = (vw - self.cols * self.cw) // 2  # 置中對齊偏移
        self.oy = (vh - self.rows * self.ch) // 2

        # 長寬比中繼資料
        self.aspect = vw / vh  # >1 = 橫向, <1 = 直向, 1 = 正方形
        self.is_portrait = vw < vh
        self.is_landscape = vw > vh

        # 索引陣列
        self.rr = np.arange(self.rows, dtype=np.float32)[:, None]
        self.cc = np.arange(self.cols, dtype=np.float32)[None, :]

        # 極座標（經過長寬比修正）
        cx, cy = self.cols / 2.0, self.rows / 2.0
        asp = self.cw / self.ch
        self.dx = self.cc - cx
        self.dy = (self.rr - cy) * asp
        self.dist = np.sqrt(self.dx**2 + self.dy**2)
        self.angle = np.arctan2(self.dy, self.dx)

        # 歸一化座標 (0-1 範圍) —— 用於距離衰減
        self.dx_n = (self.cc - cx) / max(self.cols, 1)
        self.dy_n = (self.rr - cy) / max(self.rows, 1) * asp
        self.dist_n = np.sqrt(self.dx_n**2 + self.dy_n**2)

        # 將所有字元預先點陣化為 float32 點陣圖
        self.bm = {}
        for c in all_chars:
            img = Image.new("L", (self.cw, self.ch), 0)
            ImageDraw.Draw(img).text((0, 0), c, fill=255, font=self.font)
            self.bm[c] = np.array(img, dtype=np.float32) / 255.0
```

### 字元渲染迴圈 (Character Render Loop)

這是效能瓶頸。負責將預先點陣化的點陣圖合成到像素畫布上：

```python
def render(self, chars, colors, canvas=None):
    if canvas is None:
        canvas = np.zeros((VH, VW, 3), dtype=np.uint8)
    for row in range(self.rows):
        y = self.oy + row * self.ch
        if y + self.ch > VH: break
        for col in range(self.cols):
            c = chars[row, col]
            if c == " ": continue
            x = self.ox + col * self.cw
            if x + self.cw > VW: break
            a = self.bm[c]  # float32 點陣圖
            canvas[y:y+self.ch, x:x+self.cw] = np.maximum(
                canvas[y:y+self.ch, x:x+self.cw],
                (a[:, :, None] * colors[row, col]).astype(np.uint8))
    return canvas
```

使用 `np.maximum` 進行加法混合（較亮的字元會覆蓋較暗的字元，絕不會變暗）。

### 多層渲染

在同一張畫布上渲染多個網格以增加深度感：

```python
canvas = np.zeros((VH, VW, 3), dtype=np.uint8)
canvas = grid_lg.render(bg_chars, bg_colors, canvas)   # 背景層
canvas = grid_md.render(main_chars, main_colors, canvas)  # 主層
canvas = grid_sm.render(detail_chars, detail_colors, canvas)  # 細節疊加層
```

---

## 字元調色盤 (Character Palettes)

### 設計原則

字元調色盤是 ASCII 影片的主要視覺紋理。它們不僅控制亮度映射，還決定了整體的視覺感受。設計調色盤時應考慮：

- **視覺重量**：字元應根據其填滿的墨水量/像素量進行排序。空格永遠是索引 0。
- **連貫性**：調色盤內的字元應屬於同一視覺家族。
- **密度曲線**：亮度到字元的映射是非線性的。密集的調色盤（字元多）能提供更平滑的漸層；稀疏的調色盤（5-8 個字元）則會產生海報化/圖形化的外觀。
- **渲染相容性**：調色盤中的每個字元都必須存在於所選字體中。在初始化時進行測試並移除缺失的字元。

### 調色盤庫 (Palette Library)

按視覺家族分類。請根據專案需求混合使用 —— 不要所有場景都預設使用 PAL_DEFAULT。

#### 密度/亮度調色盤
```python
PAL_DEFAULT  = " .`'-:;!><=+*^~?/|(){}[]#&$@%"       # 經典 ASCII 藝術
PAL_DENSE    = " .:;+=xX$#@\u2588"                          # 簡單 11 級階梯
PAL_MINIMAL  = " .:-=+#@"                               # 8 級，具圖形感
PAL_BINARY   = " \u2588"                                      # 2 級，極端對比
PAL_GRADIENT = " \u2591\u2592\u2593\u2588"                              # 4 級方塊漸層
```

#### Unicode 方塊元素
```python
PAL_BLOCKS   = " \u2591\u2592\u2593\u2588\u2584\u2580\u2590\u258c"                 # 標準方塊
PAL_BLOCKS_EXT = " \u2596\u2597\u2598\u2599\u259a\u259b\u259c\u259d\u259e\u259f\u2591\u2592\u2593\u2588"  # 象限方塊（更多細節）
PAL_SHADE    = " \u2591\u2592\u2593\u2588\u2587\u2586\u2585\u2584\u2583\u2582\u2581"          # 垂直填充進度
```

#### 符號/主題式
```python
PAL_MATH     = " \u00b7\u2218\u2219\u2022\u00b0\u00b1\u2213\u00d7\u00f7\u2248\u2260\u2261\u2264\u2265\u221e\u222b\u2211\u220f\u221a\u2207\u2202\u2206\u03a9"    # 數學符號
PAL_BOX      = " \u2500\u2502\u250c\u2510\u2514\u2518\u251c\u2524\u252c\u2534\u253c\u2550\u2551\u2554\u2557\u255a\u255d\u2560\u2563\u2566\u2569\u256c"          # 框線繪製
PAL_CIRCUIT  = " .\u00b7\u2500\u2502\u250c\u2510\u2514\u2518\u253c\u25cb\u25cf\u25a1\u25a0\u2206\u2207\u2261"                 # 電路板
PAL_RUNE     = " .\u16a0\u16a2\u16a6\u16b1\u16b7\u16c1\u16c7\u16d2\u16d6\u16da\u16de\u16df"                   # 古代盧恩文字
PAL_ALCHEMIC = " \u2609\u263d\u2640\u2642\u2643\u2644\u2645\u2646\u2647\u2648\u2649\u264a\u264b"            # 行星/鍊金術符號
PAL_ZODIAC   = " \u2648\u2649\u264a\u264b\u264c\u264d\u264e\u264f\u2650\u2651\u2652\u2653"            # 十二星座
PAL_ARROWS   = " \u2190\u2191\u2192\u2193\u2194\u2195\u2196\u2197\u2198\u2199\u21a9\u21aa\u21bb\u27a1"             # 方向箭頭
PAL_MUSIC    = " \u266a\u266b\u266c\u2669\u266d\u266e\u266f\u25cb\u25cf"                       # 音樂記號
```

#### 文字/書寫系統
```python
PAL_KATA     = " \u00b7\uff66\uff67\uff68\uff69\uff6a\uff6b\uff6c\uff6d\uff6e\uff6f\uff70\uff71\uff72\uff73\uff74\uff75\uff76\uff77"          # 半形片假名 (矩陣雨)
PAL_GREEK    = " \u03b1\u03b2\u03b3\u03b4\u03b5\u03b6\u03b7\u03b8\u03b9\u03ba\u03bb\u03bc\u03bd\u03be\u03c0\u03c1\u03c3\u03c4\u03c6\u03c8\u03c9"    # 希臘小寫字母
PAL_CYRILLIC = " \u0430\u0431\u0432\u0433\u0434\u0435\u0436\u0437\u0438\u043a\u043b\u043c\u043d\u043e\u043f\u0440\u0441\u0442\u0443\u0444\u0445\u0446\u0447\u0448"  # 西里爾小寫字母
PAL_ARABIC   = " \u0627\u0628\u062a\u062b\u062c\u062d\u062e\u062f\u0630\u0631\u0632\u0633\u0634\u0635\u0636\u0637"       # 阿拉伯字母（獨立形式）
```

#### 圓點/點狀進度
```python
PAL_DOTS     = " ⋅∘∙●◉◎◆✦★"                   # 圓點大小進度
PAL_BRAILLE  = " ⠁⠂⠃⠄⠅⠆⠇⠈⠉⠊⠋⠌⠍⠎⠏⠐⠑⠒⠓⠔⠕⠖⠗⠘⠙⠚⠛⠜⠝⠞⠟⠿"  # 點字圖案
PAL_STARS    = " ·✧✦✩✨★✶✳✸"               # 星辰進度
PAL_HALFFILL = " ◔◑◕◐◒◓◖◗◙"               # 方向性半填充進度
PAL_HATCH    = " ▣▤▥▦▧▨▩"                     # 陰影線密度階梯
```

#### 專案特定（範例 —— 應為每個專案發明新的）
```python
PAL_HERMES   = " .\u00b7~=\u2248\u221e\u26a1\u263f\u2726\u2605\u2295\u25ca\u25c6\u25b2\u25bc\u25cf\u25a0"   # 神話與科技的融合
PAL_OCEAN    = " ~\u2248\u2248\u2248\u223c\u2307\u2248\u224b\u224c\u2248"                       # 水/波浪字元
PAL_ORGANIC  = " .\u00b0\u2218\u2022\u25e6\u25c9\u2742\u273f\u2741\u2743"                 # 植物/生長風格
PAL_MACHINE  = " _\u2500\u2502\u250c\u2510\u253c\u2261\u25a0\u2588\u2593\u2592\u2591"             # 機械/工業風格
```

### 建立自定義調色盤

為專案設計調色盤時，應從內容的主題出發：

1. **選擇視覺家族**（圓點、方塊、符號、腳本文字）
2. **按視覺重量排序** —— 以目標字體大小渲染每個字元，計算被點亮的像素數，按升序排列
3. **在目標網格大小下測試** —— 某些字元在極小尺寸下會縮成一團
4. **驗證字體相容性** —— 移除字體無法渲染的字元：

```python
def validate_palette(pal, font):
    """移除字體無法渲染的字元。"""
    valid = []
    for c in pal:
        if c == " ":
            valid.append(c)
            continue
        img = Image.new("L", (20, 20), 0)
        ImageDraw.Draw(img).text((0, 0), c, fill=255, font=font)
        if np.array(img).max() > 0:  # 字元確實渲染了內容
            valid.append(c)
    return "".join(valid)
```

### 將數值映射到字元

```python
def val2char(v, mask, pal=PAL_DEFAULT):
    """將 float 陣列 (0-1) 使用調色盤映射到字元陣列。"""
    n = len(pal)
    idx = np.clip((v * n).astype(int), 0, n - 1)
    out = np.full(v.shape, " ", dtype="U1")
    for i, ch in enumerate(pal):
        out[mask & (idx == i)] = ch
    return out
```

**非線性映射** 以實現不同的視覺曲線：

```python
def val2char_gamma(v, mask, pal, gamma=1.0):
    """Gamma 校正後的調色盤映射。gamma<1 變亮，gamma>1 變暗。"""
    v_adj = np.power(np.clip(v, 0, 1), gamma)
    return val2char(v_adj, mask, pal)

def val2char_step(v, mask, pal, thresholds):
    """自定義閥值映射。thresholds = float 斷點列表。"""
    out = np.full(v.shape, pal[0], dtype="U1")
    for i, thr in enumerate(thresholds):
        out[mask & (v > thr)] = pal[min(i + 1, len(pal) - 1)]
    return out
```

---

## 色彩系統 (Color System)

### HSV->RGB (向量化)

所有色彩計算都在 HSV 空間進行，以便直觀控制，並在渲染時進行轉換：

```python
def hsv2rgb(h, s, v):
    """向量化 HSV->RGB。h,s,v 為 numpy 陣列。返回 (R,G,B) uint8 陣列。"""
    h = h % 1.0
    c = v * s; x = c * (1 - np.abs((h*6) % 2 - 1)); m = v - c
    # ... 6 個區段分配邏輯 ...
    return (np.clip((r+m)*255, 0, 255).astype(np.uint8),
            np.clip((g+m)*255, 0, 255).astype(np.uint8),
            np.clip((b+m)*255, 0, 255).astype(np.uint8))
```

### 色彩映射策略

不要只用一種策略。應根據視覺意圖進行選擇：

| 策略 | 色調來源 | 效果 | 適用於 |
|----------|------------|--------|----------|
| 角度映射 | `g.angle / (2*pi)` | 繞中心的彩虹效果 | 放射狀效果、萬花筒 |
| 距離映射 | `g.dist_n * 0.3` | 從中心向外的漸層 | 隧道、深度感 |
| 頻率映射 | `f["cent"] * 0.2` | 隨音色變化的色彩 | 音訊反應式 |
| 數值映射 | `val * 0.15` | 隨亮度變化的色調 | 火焰、熱力圖 |
| 時間循環 | `t * rate` | 隨時間緩慢旋轉色彩 | 環境氛圍、放鬆 |
| 來源取樣 | 影片影格像素顏色 | 保留原始色彩 | 影片轉 ASCII |
| 調色盤索引 | 離散色彩查找 | 扁平圖形風格 | 復古、像素藝術 |
| 色溫 | 暖色與冷色間混合 | 情緒基調 | 情緒導向場景 |
| 互補色 | `hue` 與 `hue + 0.5` | 高對比 | 大膽、戲劇化 |
| 三等分色 | `hue`, `hue + 0.33`, `hue + 0.66` | 鮮豔、平衡 | 迷幻風格 |
| 類比色 | `hue +/- 0.08` | 和諧、細緻 | 優雅、連貫 |
| 單色 | 固定色調，改變 S 與 V | 節制、聚焦 | 黑色電影、極簡 |

### 色彩調色盤 (離散 RGB)

適用於非 HSV 工作流 —— 直接定義 RGB 色彩集合，用於圖形/復古外觀：

```python
# 具名色彩調色盤 —— 用於扁平圖形風格或逐字著色
COLORS_NEON = [(255,0,102), (0,255,153), (102,0,255), (255,255,0), (0,204,255)]
COLORS_PASTEL = [(255,179,186), (255,223,186), (255,255,186), (186,255,201), (186,225,255)]
COLORS_MONO_GREEN = [(0,40,0), (0,80,0), (0,140,0), (0,200,0), (0,255,0)]
COLORS_MONO_AMBER = [(40,20,0), (80,50,0), (140,90,0), (200,140,0), (255,191,0)]
COLORS_CYBERPUNK = [(255,0,60), (0,255,200), (180,0,255), (255,200,0)]
COLORS_VAPORWAVE = [(255,113,206), (1,205,254), (185,103,255), (5,255,161)]
COLORS_EARTH = [(86,58,26), (139,90,43), (189,154,91), (222,193,136), (245,230,193)]
COLORS_ICE = [(200,230,255), (150,200,240), (100,170,230), (60,130,210), (30,80,180)]
COLORS_BLOOD = [(80,0,0), (140,10,10), (200,20,20), (255,50,30), (255,100,80)]
COLORS_FOREST = [(10,30,10), (20,60,15), (30,100,20), (50,150,30), (80,200,50)]

def rgb_palette_map(val, mask, palette):
    """將 float 陣列 (0-1) 映射到離散調色盤中的 RGB 顏色。"""
    n = len(palette)
    idx = np.clip((val * n).astype(int), 0, n - 1)
    R = np.zeros(val.shape, dtype=np.uint8)
    G = np.zeros(val.shape, dtype=np.uint8)
    B = np.zeros(val.shape, dtype=np.uint8)
    for i, (r, g, b) in enumerate(palette):
        m = mask & (idx == i)
        R[m] = r; G[m] = g; B[m] = b
    return R, G, B
```

### OKLAB 色彩空間 (感知均勻)

HSV 的色調在感知上並不均勻：綠色佔據的視覺範圍遠大於藍色。OKLAB / OKLCH 提供了感知均勻的色彩步進 —— 無論起點為何，增加 0.1 的色調值看起來的變化程度是相同的。OKLAB 適用於：
- 漸層內插（避免產生不想要的過渡色）
- 色彩和諧生成（感知平衡的調色盤）
- 隨時間推移的平滑色彩轉換

```python
# --- sRGB <-> 線性 sRGB ---

def srgb_to_linear(c):
    """將 sRGB [0,1] 轉換為線性光空間。c: float32 陣列。"""
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)

def linear_to_srgb(c):
    """將線性光空間轉換回 sRGB [0,1]。"""
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(np.maximum(c, 0), 1/2.4) - 0.055)

# --- 線性 sRGB <-> OKLAB ---

def linear_rgb_to_oklab(r, g, b):
    """線性 sRGB 轉 OKLAB。r,g,b: float32 陣列 [0,1]。
    返回 (L, a, b)，其中 L=[0,1], a,b 约為 [-0.4, 0.4]。"""
    l_ = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m_ = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s_ = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l_c = np.cbrt(l_); m_c = np.cbrt(m_); s_c = np.cbrt(s_)
    L = 0.2104542553 * l_c + 0.7936177850 * m_c - 0.0040720468 * s_c
    a = 1.9779984951 * l_c - 2.4285922050 * m_c + 0.4505937099 * s_c
    b_ = 0.0259040371 * l_c + 0.7827717662 * m_c - 0.8086757660 * s_c
    return L, a, b_

def oklab_to_linear_rgb(L, a, b):
    """OKLAB 轉線性 sRGB。返回 (r, g, b) float32 陣列 [0,1]。"""
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l_c = l_ ** 3; m_c = m_ ** 3; s_c = s_ ** 3
    r = +4.0767416621 * l_c - 3.3077115913 * m_c + 0.2309699292 * s_c
    g = -1.2684380046 * l_c + 2.6097574011 * m_c - 0.3413193965 * s_c
    b_ = -0.0041960863 * l_c - 0.7034186147 * m_c + 1.7076147010 * s_c
    return np.clip(r, 0, 1), np.clip(g, 0, 1), np.clip(b_, 0, 1)

# --- 方便性函式：sRGB uint8 <-> OKLAB ---

def rgb_to_oklab(R, G, B):
    """sRGB uint8 陣列轉 OKLAB。"""
    r = srgb_to_linear(R.astype(np.float32) / 255.0)
    g = srgb_to_linear(G.astype(np.float32) / 255.0)
    b = srgb_to_linear(B.astype(np.float32) / 255.0)
    return linear_rgb_to_oklab(r, g, b)

def oklab_to_rgb(L, a, b):
    """OKLAB 轉 sRGB uint8 陣列。"""
    r, g, b_ = oklab_to_linear_rgb(L, a, b)
    R = np.clip(linear_to_srgb(r) * 255, 0, 255).astype(np.uint8)
    G = np.clip(linear_to_srgb(g) * 255, 0, 255).astype(np.uint8)
    B = np.clip(linear_to_srgb(b_) * 255, 0, 255).astype(np.uint8)
    return R, G, B

# --- OKLCH (OKLAB 的圓柱座標形式) ---

def oklab_to_oklch(L, a, b):
    """OKLAB 轉 OKLCH。返回 (L, C, H)，其中 H 在 [0, 1] 之間（歸一化）。"""
    C = np.sqrt(a**2 + b**2)
    H = (np.arctan2(b, a) / (2 * np.pi)) % 1.0
    return L, C, H

def oklch_to_oklab(L, C, H):
    """OKLCH 轉 OKLAB。H 在 [0, 1] 之間。"""
    angle = H * 2 * np.pi
    a = C * np.cos(angle)
    b = C * np.sin(angle)
    return L, a, b
```

### 漸層內插 (OKLAB vs HSV)

透過 OKLAB 進行色彩內插可以避免 HSV 產生的色調偏移問題：

```python
def lerp_oklab(color_a, color_b, t_array):
    """在兩個 sRGB 色彩間透過 OKLAB 進行內插。
    color_a, color_b：(R, G, B) 元組 0-255
    t_array：float32 陣列 [0,1] —— 每個像素的內插參數。
    返回 (R, G, B) uint8 陣列。"""
    La, aa, ba = rgb_to_oklab(
        np.full_like(t_array, color_a[0], dtype=np.uint8),
        np.full_like(t_array, color_a[1], dtype=np.uint8),
        np.full_like(t_array, color_a[2], dtype=np.uint8))
    Lb, ab, bb = rgb_to_oklab(
        np.full_like(t_array, color_b[0], dtype=np.uint8),
        np.full_like(t_array, color_b[1], dtype=np.uint8),
        np.full_like(t_array, color_b[2], dtype=np.uint8))
    L = La + (Lb - La) * t_array
    a = aa + (ab - aa) * t_array
    b = ba + (bb - ba) * t_array
    return oklab_to_rgb(L, a, b)

def lerp_oklch(color_a, color_b, t_array, short_path=True):
    """透過 OKLCH 內插（保留色度，色彩路徑平滑）。
    short_path：取色輪上的短弧。"""
    La, aa, ba = rgb_to_oklab(
        np.full_like(t_array, color_a[0], dtype=np.uint8),
        np.full_like(t_array, color_a[1], dtype=np.uint8),
        np.full_like(t_array, color_a[2], dtype=np.uint8))
    Lb, ab, bb = rgb_to_oklab(
        np.full_like(t_array, color_b[0], dtype=np.uint8),
        np.full_like(t_array, color_b[1], dtype=np.uint8),
        np.full_like(t_array, color_b[2], dtype=np.uint8))
    L1, C1, H1 = oklab_to_oklch(La, aa, ba)
    L2, C2, H2 = oklab_to_oklch(Lb, ab, bb)
    # 最短色調路徑
    if short_path:
        dh = H2 - H1
        dh = np.where(dh > 0.5, dh - 1.0, np.where(dh < -0.5, dh + 1.0, dh))
        H = (H1 + dh * t_array) % 1.0
    else:
        H = H1 + (H2 - H1) * t_array
    L = L1 + (L2 - L1) * t_array
    C = C1 + (C2 - C1) * t_array
    Lout, aout, bout = oklch_to_oklab(L, C, H)
    return oklab_to_rgb(Lout, aout, bout)
```

### 色彩和諧生成 (Color Harmony Generation)

從種子色彩自動生成和諧的調色盤：

```python
def harmony_complementary(seed_rgb):
    """互補色：種子色 + 相反色調。"""
    L, a, b = rgb_to_oklab(np.array([seed_rgb[0]]), np.array([seed_rgb[1]]), np.array([seed_rgb[2]]))
    _, C, H = oklab_to_oklch(L, a, b)
    return [seed_rgb, _oklch_to_srgb_tuple(L[0], C[0], (H[0] + 0.5) % 1.0)]

def harmony_triadic(seed_rgb):
    """三等分色：種子色 + 兩個 120 度偏移的色調。"""
    L, a, b = rgb_to_oklab(np.array([seed_rgb[0]]), np.array([seed_rgb[1]]), np.array([seed_rgb[2]]))
    _, C, H = oklab_to_oklch(L, a, b)
    return [seed_rgb,
            _oklch_to_srgb_tuple(L[0], C[0], (H[0] + 0.333) % 1.0),
            _oklch_to_srgb_tuple(L[0], C[0], (H[0] + 0.667) % 1.0)]

def harmony_analogous(seed_rgb, spread=0.08, n=5):
    """類比色：圍繞種子色均勻分佈的 N 個色調。"""
    L, a, b = rgb_to_oklab(np.array([seed_rgb[0]]), np.array([seed_rgb[1]]), np.array([seed_rgb[2]]))
    _, C, H = oklab_to_oklch(L, a, b)
    offsets = np.linspace(-spread * (n-1)/2, spread * (n-1)/2, n)
    return [_oklch_to_srgb_tuple(L[0], C[0], (H[0] + off) % 1.0) for off in offsets]

def harmony_split_complementary(seed_rgb, split=0.08):
    """補色分割：種子色 + 補色兩側的兩個色調。"""
    L, a, b = rgb_to_oklab(np.array([seed_rgb[0]]), np.array([seed_rgb[1]]), np.array([seed_rgb[2]]))
    _, C, H = oklab_to_oklch(L, a, b)
    comp = (H[0] + 0.5) % 1.0
    return [seed_rgb,
            _oklch_to_srgb_tuple(L[0], C[0], (comp - split) % 1.0),
            _oklch_to_srgb_tuple(L[0], C[0], (comp + split) % 1.0)]

def harmony_tetradic(seed_rgb):
    """四等分色 (矩形色)：兩對 90 度偏移的互補色。"""
    L, a, b = rgb_to_oklab(np.array([seed_rgb[0]]), np.array([seed_rgb[1]]), np.array([seed_rgb[2]]))
    _, C, H = oklab_to_oklch(L, a, b)
    return [seed_rgb,
            _oklch_to_srgb_tuple(L[0], C[0], (H[0] + 0.25) % 1.0),
            _oklch_to_srgb_tuple(L[0], C[0], (H[0] + 0.5) % 1.0),
            _oklch_to_srgb_tuple(L[0], C[0], (H[0] + 0.75) % 1.0)]

def _oklch_to_srgb_tuple(L, C, H):
    """輔助函式：單一 OKLCH 轉 sRGB (R,G,B) 整數元組。"""
    La = np.array([L]); Ca = np.array([C]); Ha = np.array([H])
    Lo, ao, bo = oklch_to_oklab(La, Ca, Ha)
    R, G, B = oklab_to_rgb(Lo, ao, bo)
    return (int(R[0]), int(G[0]), int(B[0]))
```

### OKLAB 色調場

這是一些生成感知均勻色調變化的 `hf_*` 替代函式：

```python
def hf_oklch_angle(offset=0.0, chroma=0.12, lightness=0.7):
    """OKLCH 色調對應到繞中心的角度。感知均勻的彩虹。
    返回 (R, G, B) uint8 色彩陣列而非 float 色調值。
    注意：請搭配 _render_vf_rgb() 變體使用，而非標準的 _render_vf()。"""
    def fn(g, f, t, S):
        H = (g.angle / (2 * np.pi) + offset + t * 0.05) % 1.0
        L = np.full_like(H, lightness)
        C = np.full_like(H, chroma)
        Lo, ao, bo = oklch_to_oklab(L, C, H)
        R, G, B = oklab_to_rgb(Lo, ao, bo)
        return mkc(R, G, B, g.rows, g.cols)
    return fn
```

### 合成輔助函式

```python
def mkc(R, G, B, rows, cols):
    """將 3 個 uint8 陣列打包成 (rows, cols, 3) 的色彩陣列。"""
    o = np.zeros((rows, cols, 3), dtype=np.uint8)
    o[:,:,0] = R; o[:,:,1] = G; o[:,:,2] = B
    return o

def layer_over(base_ch, base_co, top_ch, top_co):
    """將上層合成到底層。非空格字元會覆蓋底層。"""
    m = top_ch != " "
    base_ch[m] = top_ch[m]; base_co[m] = top_co[m]
    return base_ch, base_co

def layer_blend(base_co, top_co, alpha):
    """將上層色彩與底層進行 Alpha 混合。alpha 為 float 陣列 (0-1) 或純量。"""
    if isinstance(alpha, (int, float)):
        alpha = np.full(base_co.shape[:2], alpha, dtype=np.float32)
    a = alpha[:,:,None]
    return np.clip(base_co * (1 - a) + top_co * a, 0, 255).astype(np.uint8)

def stamp(ch, co, text, row, col, color=(255,255,255)):
    """在特定位置寫入文字字串。"""
    for i, c in enumerate(text):
        cc = col + i
        if 0 <= row < ch.shape[0] and 0 <= cc < ch.shape[1]:
            ch[row, cc] = c; co[row, cc] = color
```

---

## 段落系統 (Section System)

將時間範圍映射到效果函式、著色器配置和網格大小：

```python
SECTIONS = [
    (0.0, "void"), (3.94, "starfield"), (21.0, "matrix"),
    (46.0, "drop"), (130.0, "glitch"), (187.0, "outro"),
]

FX_DISPATCH = {"void": fx_void, "starfield": fx_starfield, ...}
SECTION_FX = {"void": {"vignette": 0.3, "bloom": 170}, ...}
SECTION_GRID = {"void": "md", "starfield": "sm", "drop": "lg", ...}
SECTION_MIRROR = {"drop": "h", "bass_rings": "quad"}

def get_section(t):
    sec = SECTIONS[0][1]
    for ts, name in SECTIONS:
        if t >= ts: sec = name
    return sec
```

---

## 並行編碼 (Parallel Encoding)

將影格分配給 N 個工作進程。每個進程都透過管道將原始 RGB 傳送到自己的 ffmpeg 子進程：

```python
def render_batch(batch_id, frame_start, frame_end, features, seg_path):
    r = Renderer()
    cmd = ["ffmpeg", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24",
           "-s", f"{VW}x{VH}", "-r", str(FPS), "-i", "pipe:0",
           "-c:v", "libx264", "-preset", "fast", "-crf", "18",
           "-pix_fmt", "yuv420p", seg_path]

    # 至關重要：stderr 輸出到檔案，而非管道
    stderr_fh = open(os.path.join(workdir, f"err_{batch_id:02d}.log"), "w")
    pipe = subprocess.Popen(cmd, stdin=subprocess.PIPE,
                            stdout=subprocess.DEVNULL, stderr=stderr_fh)

    for fi in range(frame_start, frame_end):
        t = fi / FPS
        sec = get_section(t)
        f = {k: float(features[k][fi]) for k in features}
        ch, co = FX_DISPATCH[sec](r, f, t)
        canvas = r.render(ch, co)
        canvas = apply_mirror(canvas, sec, f)
        canvas = apply_shaders(canvas, sec, f, t)
        pipe.stdin.write(canvas.tobytes())

    pipe.stdin.close()
    pipe.wait()
    stderr_fh.close()
```

連接各段影片並混入音軌：

```python
# 編寫連接檔案 (concat file)
with open(concat_path, "w") as cf:
    for seg in segments:
        cf.write(f"file '{seg}'\n")

subprocess.run(["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", concat_path,
                "-i", audio_path, "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
                "-shortest", output_path])
```

## 效果函式規範

### v2 協議（當前標準）

每個場景函式：`(r, f, t, S) -> canvas_uint8` —— 其中 `r` = 渲染器, `f` = 特徵字典, `t` = 時間 (float), `S` = 持久化狀態字典

```python
def fx_example(r, f, t, S):
    """場景函式返回完整的像素畫布 (uint8 H,W,3)。
    場景對多網格渲染和像素級合成擁有完整控制權。
    """
    # 在不同網格密度下渲染多個圖層
    canvas_a = _render_vf(r, "md", vf_plasma, hf_angle(0.0), PAL_DENSE, f, t, S)
    canvas_b = _render_vf(r, "sm", vf_vortex, hf_time_cycle(0.1), PAL_RUNE, f, t, S)

    # 像素級混合
    result = blend_canvas(canvas_a, canvas_b, "screen", 0.8)
    return result
```

有關完整場景協議、Renderer 類別、`_render_vf()` 輔助工具及完整場景範例，請參閱 [scenes_zh_TW.md](scenes_zh_TW.md)。

有關混合模式、色調映射、回饋緩衝區和多網格合成，請參閱 [composition_zh_TW.md](composition_zh_TW.md)。

### v1 協議（舊版）

使用單一網格的簡單場景仍可返回 `(chars, colors)` 並交由調用者處理渲染，但所有新程式碼均建議使用 v2 畫布協議。

```python
def fx_simple(r, f, t, S):
    g = r.get_grid("md")
    val = np.sin(g.dist * 0.1 - t * 3) * f.get("bass", 0.3) * 2
    val = np.clip(val, 0, 1); mask = val > 0.03
    ch = val2char(val, mask, PAL_DEFAULT)
    R, G, B = hsv2rgb(np.full_like(val, 0.6), np.full_like(val, 0.7), val)
    co = mkc(R, G, B, g.rows, g.cols)
    return g.render(ch, co)  # 直接返回畫布
```

### 持久化狀態 (Persistent State)

需要在影格間保持狀態的效果（如粒子、雨滴欄）應使用 `S` 字典參數（即 `r.S` —— 雖然是同一個物件，但明確傳遞以增加清晰度）：

```python
def fx_with_state(r, f, t, S):
    if "particles" not in S:
        S["particles"] = initialize_particles()
    update_particles(S["particles"])
    # ...
```

狀態在單個場景/片段的所有影格中持續存在。每個工作進程（及每個場景）都擁有各自獨立的狀態。

### 輔助函式

```python
def hsv2rgb_scalar(h, s, v):
    """單一數值的 HSV 轉 RGB。返回 (R, G, B) 整數元組 0-255。"""
    h = h % 1.0
    c = v * s; x = c * (1 - abs((h * 6) % 2 - 1)); m = v - c
    if h * 6 < 1:   r, g, b = c, x, 0
    elif h * 6 < 2:  r, g, b = x, c, 0
    elif h * 6 < 3:  r, g, b = 0, c, x
    elif h * 6 < 4:  r, g, b = 0, x, c
    elif h * 6 < 5:  r, g, b = x, 0, c
    else:             r, g, b = c, 0, x
    return (int((r+m)*255), int((g+m)*255), int((b+m)*255))

def log(msg):
    """列印帶有時間戳記的日誌訊息。"""
    print(msg, flush=True)
```
