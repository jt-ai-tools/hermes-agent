# 場景系統與創意合成 (Scene System & Creative Composition)

> **另請參閱：** [architecture_zh_TW.md](architecture_zh_TW.md) · [composition_zh_TW.md](composition_zh_TW.md) · [effects_zh_TW.md](effects_zh_TW.md) · [shaders_zh_TW.md](shaders_zh_TW.md)

## 場景設計理念

場景是說故事的單位，而非單純的效果展示。每個場景都需要：
- 一個**概念 (Concept)** —— 視覺上正在發生什麼？不是「電漿 + 圓環」，而是「從虛無中湧現」或「結晶化」。
- 一個**弧線 (Arc)** —— 在場景持續時間內如何變化？構建、衰減、轉化還是揭示？
- 一個**角色 (Role)** —— 它如何服務於整段影片的敘事？是開場的張力、能量的高峰，還是結尾的解決？

下方的設計模式提供了合成技術。場景範例則展示了這些模式在不同複雜程度下的實際應用。協議章節則涵蓋了技術規範。

優秀的場景設計應從概念出發，然後選擇服務於該概念的效果與參數。設計模式章節說明了*如何*有意識地進行圖層合成。範例章節提供了涵蓋各個複雜等級的完整場景程式碼。協議章節則定義了所有場景必須遵循的技術契約。

---

## 場景設計模式 (Scene Design Patterns)

用於構建具備「意圖感」而非隨機感的場景的高階模式。這些模式使用現有的構建塊（數值場、混合模式、著色器、回饋），但以構圖意圖來組織它們。

## 圖層階層 (Layer Hierarchy)

每個場景都應具有角色鮮明的視覺圖層：

| 圖層 | 網格 (Grid) | 亮度 | 用途 |
|-------|------|-----------|---------|
| **背景 (Background)** | xs 或 sm (密集) | 0.1–0.25 | 氛圍、紋理。絕不與主體內容競爭。 |
| **內容 (Content)** | md (均衡) | 0.4–0.8 | 主要視覺思想。承載場景的核心概念。 |
| **強調 (Accent)** | lg 或 sm (稀疏) | 0.5–1.0 (覆蓋率低) | 高光、點綴、稀疏的亮点。 |

背景設定情緒，內容層是場景的*重點*，強調層則在不喧賓奪主的前提下增加視覺趣味。

```python
def fx_example(r, f, t, S):
    local = t
    progress = min(local / 5.0, 1.0)

    g_bg = r.get_grid("sm")
    g_main = r.get_grid("md")
    g_accent = r.get_grid("lg")

    # --- 背景：微暗的氛圍 ---
    bg_val = vf_smooth_noise(g_bg, f, t * 0.3, S, octaves=2, bri=0.15)
    # ... 將背景渲染到畫布

    # --- 內容：主要視覺思想 ---
    content_val = vf_spiral(g_main, f, t, S, n_arms=n_arms, tightness=tightness)
    # ... 在畫布上方渲染內容

    # --- 強調：稀疏的高光 ---
    accent_val = vf_noise_static(g_accent, f, t, S, density=0.05)
    # ... 在最上方渲染強調層

    return canvas
```

## 方向性參數弧 (Directional Parameter Arcs)

在場景持續期間，參數應該有其「去向」—— 而非僅僅用 `sin(t * N)` 進行漫無目的的震盪。

**錯誤示範：** `twist = 3.0 + 2.0 * math.sin(t * 0.6)` —— 來回擺動，感覺漫無目的。

**正確示範：** `twist = 2.0 + progress * 5.0` —— 從溫和開始，以劇烈結束。場景具備「構建感」。

使用 `progress = min(local / duration, 1.0)` (場景內從 0→1) 來驅動方向性變化：

| 模式 | 公式 | 感受 |
|---------|---------|------|
| 線性遞增 (Linear ramp) | `progress * range` | 穩定積累 |
| 緩出 (Ease-out) | `1 - (1 - progress) ** 2` | 快速開頭，平緩收尾 |
| 緩入 (Ease-in) | `progress ** 2` | 緩慢開始，逐漸加速 |
| 階梯揭示 (Step reveal) | `np.clip((progress - 0.5) / 0.25, 0, 1)` | 50% 前無內容，隨後淡入 |
| 構建 + 平台 | `min(1.0, progress * 1.5)` | 在 67% 處達到頂峰並保持 |

震盪適用於*次要*參數（飽和度閃爍、色調漂移）。但場景的*定義性*參數應該具備明確的方向。

### 方向性弧範例

| 場景概念 | 參數 | 弧線 (Arc) |
|--------------|-----------|-----|
| 湧現 (Emergence) | 圓環半徑 | 0 → 最大值 (緩出) |
| 破碎 (Shatter) | Voronoi 細胞數量 | 8 → 38 (線性) |
| 下降 (Descent) | 隧道速度 | 2.0 → 10.0 (線性) |
| 曼陀羅 (Mandala) | 形狀複雜度 | 圓環 → +多邊形 → +星形 → +玫瑰線 (階梯揭示) |
| 漸強 (Crescendo) | 圖層數量 | 1 → 7 (交錯進入) |
| 熵 (Entropy) | 幾何體可見度 | 1.0 → 0.0 (被吞噬) |

## 場景概念 (Scene Concepts)

每個場景都應圍繞著一個*視覺想法*構建，而非效果名稱。

**錯誤示範：** "fx_plasma_cascade" —— 以效果命名，缺乏概念。
**正確示範：** "fx_emergence" —— 一個亮點擴張成一片區域。名稱告訴你*發生了什麼*。

優秀的場景概念具備：
1. 一個**視覺隱喻**（湧現、下降、碰撞、熵）
2. 一個**方向性弧線**（事物從 A 變到 B，而非震盪）
3. **有動機的圖層選擇**（每個圖層服務於概念）
4. **有動機的回饋效果**（變換方向與隱喻匹配）

| 概念 | 隱喻 | 回饋變換 | 原因 |
|---------|----------|-------------------|-----|
| 湧現 | 誕生、擴張 | zoom-out (縮小) | 過去的影格向外擴散 |
| 下降 | 墜落、加速 | zoom-in (放大) | 過去的影格奔向中心 |
| 煉獄 | 上升的火焰 | shift-up (上移) | 過去的影格隨火焰升騰 |
| 熵 | 衰減、溶解 | 無 | 乾淨、無持久感 —— 事物消失 |
| 漸強 | 積累 | zoom + hue_shift | 一切事物都在疊加與偏移 |

## 合成技術 (Compositional Techniques)

### 雙系統反向旋轉 (Counter-Rotating Dual Systems)

兩個朝相反方向旋轉的相同效果實例，會產生視覺干涉：

```python
# 主螺旋 (順時針)
s1_val = vf_spiral(g_main, f, t * 1.5, S, n_arms=n_arms_1, tightness=tightness_1)

# 反向螺旋 (透過負時間實現逆時針)
s2_val = vf_spiral(g_accent, f, -t * 1.2, S, n_arms=n_arms_2, tightness=tightness_2)

# Screen 混合在交叉點產生明亮的干涉效果
canvas = blend_canvas(canvas_with_s1, c2, "screen", 0.7)
```

適用於螺旋、渦流、圓環。反向旋轉會產生不斷變化的干涉圖案。

### 波浪碰撞 (Wave Collision)

兩個波前從相反方向匯聚，在碰撞點相遇：

```python
collision_phase = abs(progress - 0.5) * 2  # 1→0→1 (0 表示碰撞時)

# 波浪 A 從左側靠近
offset_a = (1 - progress) * g.cols * 0.4
wave_a = np.sin((g.cc + offset_a) * 0.08 + t * 2) * 0.5 + 0.5

# 波浪 B 從右側靠近
offset_b = -(1 - progress) * g.cols * 0.4
wave_b = np.sin((g.cc + offset_b) * 0.08 - t * 2) * 0.5 + 0.5

# 干涉效果在碰撞處達到頂峰
combined = wave_a * 0.5 + wave_b * 0.5 + np.abs(wave_a - wave_b) * (1 - collision_phase) * 0.5
```

### 漸進式碎片化 (Progressive Fragmentation)

Voronoi 細胞數量隨時間增加 —— 產生視覺上的粉碎感：

```python
n_pts = int(8 + progress * 30)  # 8 個細胞 → 38 個細胞
# 預先生成足夠的點，再根據 n_pts 進行切片
px = base_x[:n_pts] + np.sin(t * 0.3 + np.arange(n_pts) * 0.7) * (3 + progress * 3)
```

邊緣發光的寬度也可以隨進度增加，以強調裂痕。

### 熵 / 吞噬 (Entropy / Consumption)

整潔的幾何圖案被有機過程所佔據：

```python
# 幾何體逐漸淡出
geo_val = clean_pattern * max(0.05, 1.0 - progress * 0.9)

# 有機過程逐漸生長
rd_val = vf_reaction_diffusion(g, f, t, S) * min(1.0, progress * 1.5)

# 先渲染幾何體，再疊加有機圖層 —— 有機圖層會「吞噬」幾何體
```

### 交錯圖層進入（漸強，Crescendo）

圖層逐一進入，構建出排山倒海的密度：

```python
def layer_strength(enter_t, ramp=1.5):
    """在 enter_t 前為 0.0，隨後在 ramp 秒內斜坡上升至 1.0。"""
    return max(0.0, min(1.0, (local - enter_t) / ramp))

# 圖層 1：始終存在
s1 = layer_strength(0.0)
# 圖層 2：在 2 秒時進入
s2 = layer_strength(2.0)
# 圖層 3：在 4 秒時進入
s3 = layer_strength(4.0)
# ... 以此類推

# 每一層使用不同的效果、網格、調色盤與混合模式
# 圖層間使用 Screen 混合以實現亮度的累積
```

對於一個 15 秒的漸強，每 2 秒進入一個新圖層（共 7 層）效果很好。使用不同的混合模式（大多數用 screen，能量強處用 add，最後的大爆發用 colordodge）。

## 場景排序 (Scene Ordering)

對於多場景的集錦或影片：
- **變換相鄰場景的情緒** —— 不要把兩個平靜的場景放在一起。
- **隨機化順序**，而非按類型分組 —— 避免產生「效果演示」的機械感。
- **以最強大的場景結尾** —— 漸強的高潮或有明確交代的作品。
- **以能量感開場** —— 在前 2 秒內抓住觀眾注意力。

---

## 場景協議 (Scene Protocol)

場景是最高級別的創意單位。每個場景都是一個帶有時間限制的片段，擁有獨立的效果函式、著色器鏈、回饋配置以及色調映射 Gamma 值。

### 場景協議 (v2)

### 函式簽章 (Function Signature)

```python
def fx_scene_name(r, f, t, S) -> canvas:
    """
    參數：
        r: Renderer 實例 —— 透過 r.get_grid("sm") 存取多個網格
        f: 音訊/影片特徵字典，所有數值均歸一化為 [0, 1]
        t: 以秒為單位的時間 —— 場景局部時間 (場景開始時為 0.0)
        S: 持久化狀態字典 (用於粒子、雨滴欄等)

    返回：
        canvas: numpy uint8 陣列，形狀為 (VH, VW, 3) —— 完整的像素影格
    """
```

**局部時間慣例：** 場景函式接收的 `t` 在場景的第一影格總是從 0.0 開始，不論該場景在時間軸上的位置。渲染迴圈在調用函式前會先減去場景的開始時間：

```python
# 在 render_clip 中：
t_local = fi / FPS - scene_start
canvas = fx_fn(r, feat, t_local, S)
```

這使得場景可以在不修改程式碼的情況下重新排序。計算場景進度如下：

```python
progress = min(t / scene_duration, 1.0)  # 場景內 0→1
```

這取代了 v1 版場景返回 `(chars, colors)` 元組的協議。v2 協議賦予場景在內部完整控制多網格渲染與像素級合成的能力。

### Renderer 類別

```python
class Renderer:
    def __init__(self):
        self.grids = {}   # 延遲初始化的網格快取
        self.g = None      # 「活動」網格 (用於向後相容)
        self.S = {}        # 持久化狀態字典

    def get_grid(self, key):
        """根據大小鍵值獲取或建立 GridLayer。"""
        if key not in self.grids:
            sizes = {"xs": 8, "sm": 10, "md": 16, "lg": 20, "xl": 24, "xxl": 40}
            self.grids[key] = GridLayer(FONT_PATH, sizes[key])
        return self.grids[key]

    def set_grid(self, key):
        """設定活動網格 (舊版)。多網格場景建議使用 get_grid()。"""
        self.g = self.get_grid(key)
        return self.g
```

**與 v1 的關鍵差異**：場景調用 `r.get_grid("sm")`, `r.get_grid("lg")` 等來存取多個網格。每個網格都是延遲初始化並被快取的。`set_grid()` 方法對於單一網格場景仍然有效。

### 最簡場景 (單網格)

```python
def fx_simple_rings(r, f, t, S):
    """單網格場景：帶有距離映射色調的圓環。"""
    canvas = _render_vf(r, "md",
        lambda g, f, t, S: vf_rings(g, f, t, S, n_base=8, spacing_base=3),
        hf_distance(0.3, 0.02), PAL_STARS, f, t, S, sat=0.85)
    return canvas
```

### 標準場景 (雙網格 + 混合)

```python
def fx_tunnel_ripple(r, f, t, S):
    """雙網格場景：隧道深度與波紋進行 Exclusion 混合。"""
    canvas_a = _render_vf(r, "md",
        lambda g, f, t, S: vf_tunnel(g, f, t, S, speed=5.0, complexity=10) * 1.3,
        hf_distance(0.55, 0.02), PAL_GREEK, f, t, S, sat=0.7)

    canvas_b = _render_vf(r, "sm",
        lambda g, f, t, S: vf_ripple(g, f, t, S,
            sources=[(0.3,0.3), (0.7,0.7), (0.5,0.2)], freq=0.5, damping=0.012) * 1.4,
        hf_angle(0.1), PAL_STARS, f, t, S, sat=0.8)

    return blend_canvas(canvas_a, canvas_b, "exclusion", 0.8)
```

### 複雜場景 (三網格 + 條件式 + 自定義渲染)

```python
def fx_rings_explosion(r, f, t, S):
    """包含粒子與條件式萬花筒的三網格場景。"""
    # 圖層 1：圓環
    canvas_a = _render_vf(r, "sm",
        lambda g, f, t, S: vf_rings(g, f, t, S, n_base=10, spacing_base=2) * 1.4,
        lambda g, f, t, S: (g.angle / (2*np.pi) + t * 0.15) % 1.0,
        PAL_STARS, f, t, S, sat=0.9)

    # 圖層 2：另一個網格上的渦流
    canvas_b = _render_vf(r, "md",
        lambda g, f, t, S: vf_vortex(g, f, t, S, twist=6.0) * 1.2,
        hf_time_cycle(0.15), PAL_BLOCKS, f, t, S, sat=0.8)

    result = blend_canvas(canvas_b, canvas_a, "screen", 0.7)

    # 圖層 3：粒子 (自定義渲染，非 _render_vf)
    g = r.get_grid("sm")
    if "px" not in S:
        S["px"], S["py"], S["vx"], S["vy"], S["life"], S["pch"] = (
            [], [], [], [], [], [])
    if f.get("beat", 0) > 0.5:
        chars = list("\u2605\u2736\u2733\u2738\u2726\u2728*+")
        for _ in range(int(80 + f.get("rms", 0.3) * 120)):
            ang = random.uniform(0, 2 * math.pi)
            sp = random.uniform(1, 10) * (0.5 + f.get("sub_r", 0.3) * 2)
            S["px"].append(float(g.cols // 2))
            S["py"].append(float(g.rows // 2))
            S["vx"].append(math.cos(ang) * sp * 2.5)
            S["vy"].append(math.sin(ang) * sp)
            S["life"].append(1.0)
            S["pch"].append(random.choice(chars))

    # 更新 + 繪製粒子
    ch_p = np.full((g.rows, g.cols), " ", dtype="U1")
    co_p = np.zeros((g.rows, g.cols, 3), dtype=np.uint8)
    i = 0
    while i < len(S["px"]):
        S["px"][i] += S["vx"][i]; S["py"][i] += S["vy"][i]
        S["vy"][i] += 0.03; S["life"][i] -= 0.02
        if S["life"][i] <= 0:
            for k in ("px","py","vx","vy","life","pch"): S[k].pop(i)
        else:
            pr, pc = int(S["py"][i]), int(S["px"][i])
            if 0 <= pr < g.rows and 0 <= pc < g.cols:
                ch_p[pr, pc] = S["pch"][i]
                co_p[pr, pc] = hsv2rgb_scalar(
                    0.08 + (1-S["life"][i])*0.15, 0.95, S["life"][i])
            i += 1

    canvas_p = g.render(ch_p, co_p)
    result = blend_canvas(result, canvas_p, "add", 0.8)

    # 強節拍時應用條件式萬花筒
    if f.get("bdecay", 0) > 0.4:
        result = sh_kaleidoscope(result.copy(), folds=6)

    return result
```

### 包含自定義字元渲染的場景 (矩陣雨)

當你需要超出 `_render_vf()` 所能提供的逐單元控制時：

```python
def fx_matrix_layered(r, f, t, S):
    """矩陣雨與隧道混合 —— 雙網格，Screen 混合。"""
    # 圖層 1：矩陣雨 (自定義逐欄渲染)
    g = r.get_grid("md")
    rows, cols = g.rows, g.cols
    pal = PAL_KATA

    if "ry" not in S or len(S["ry"]) != cols:
        S["ry"] = np.random.uniform(-rows, rows, cols).astype(np.float32)
        S["rsp"] = np.random.uniform(0.3, 2.0, cols).astype(np.float32)
        S["rln"] = np.random.randint(8, 35, cols)
        S["rch"] = np.random.randint(1, len(pal), (rows, cols))

    speed = 0.6 + f.get("bass", 0.3) * 3
    if f.get("beat", 0) > 0.5: speed *= 2.5
    S["ry"] += S["rsp"] * speed

    ch = np.full((rows, cols), " ", dtype="U1")
    co = np.zeros((rows, cols, 3), dtype=np.uint8)
    heads = S["ry"].astype(int)
    for c in range(cols):
        head = heads[c]
        for i in range(S["rln"][c]):
            row = head - i
            if 0 <= row < rows:
                fade = 1.0 - i / S["rln"][c]
                ch[row, c] = pal[S["rch"][row, c] % len(pal)]
                if i == 0:
                    v = int(min(255, fade * 300))
                    co[row, c] = (int(v*0.9), v, int(v*0.9))
                else:
                    v = int(fade * 240)
                    co[row, c] = (int(v*0.1), v, int(v*0.4))
    canvas_a = g.render(ch, co)

    # 圖層 2：sm 網格上的隧道，增加深度紋理
    canvas_b = _render_vf(r, "sm",
        lambda g, f, t, S: vf_tunnel(g, f, t, S, speed=5.0, complexity=10),
        hf_distance(0.3, 0.02), PAL_BLOCKS, f, t, S, sat=0.6)

    return blend_canvas(canvas_a, canvas_b, "screen", 0.5)
```

---

## 場景表 (Scene Table)

場景表定義了時間軸：在哪個時間點播放哪個場景，以及其配置。

### 結構

```python
SCENES = [
    {
        "start": 0.0,           # 開始時間 (秒)
        "end": 3.96,            # 結束時間 (秒)
        "name": "starfield",    # 識別碼 (用於片段檔案命名)
        "grid": "sm",           # 預設網格 (用於 render_clip 設定)
        "fx": fx_starfield,     # 場景函式引用 (必須在模組級別)
        "gamma": 0.75,          # 覆寫色調映射 Gamma (預設 0.75)
        "shaders": [            # 著色器鏈 (在 tonemap + 回饋後套用)
            ("bloom", {"thr": 120}),
            ("vignette", {"s": 0.2}),
            ("grain", {"amt": 8}),
        ],
        "feedback": None,       # 回饋緩衝區配置 (None = 停用)
        # "feedback": {"decay": 0.8, "blend": "screen", "opacity": 0.3,
        #              "transform": "zoom", "transform_amt": 0.02, "hue_shift": 0.02},
    },
    {
        "start": 3.96,
        "end": 6.58,
        "name": "matrix_layered",
        "grid": "md",
        "fx": fx_matrix_layered,
        "shaders": [
            ("crt", {"strength": 0.05}),
            ("scanlines", {"intensity": 0.12}),
            ("color_grade", {"tint": (0.7, 1.2, 0.7)}),
            ("bloom", {"thr": 100}),
        ],
        "feedback": {"decay": 0.5, "blend": "add", "opacity": 0.2},
    },
    # ... 更多場景 ...
]
```

### 節拍同步場景剪輯

從音訊分析中提取剪輯點：

```python
# 獲取節拍時間戳記
beats = [fi / FPS for fi in range(N_FRAMES) if features["beat"][fi] > 0.5]

# 將節拍分組成樂句邊界 (每 4-8 個節拍)
cuts = [0.0]
for i in range(0, len(beats), 4):  # 每 4 個節拍剪一刀
    cuts.append(beats[i])
cuts.append(DURATION)

# 或者是利用音樂結構：靜音間隙、能量變化
energy = features["rms"]
# 尋找能量顯著下降的時間戳記 -> 自然的停頓點
```

### `render_clip()` —— 渲染迴圈

此函式將單個場景渲染為片段檔案：

```python
def render_clip(seg, features, clip_path):
    r = Renderer()
    r.set_grid(seg["grid"])
    S = r.S
    random.seed(hash(seg["id"]) + 42)  # 每個場景確定性的隨機種子

    # 從配置構建著色器鏈
    chain = ShaderChain()
    for shader_name, kwargs in seg.get("shaders", []):
        chain.add(shader_name, **kwargs)

    # 設定回饋緩衝區
    fb = None
    fb_cfg = seg.get("feedback", None)
    if fb_cfg:
        fb = FeedbackBuffer()

    fx_fn = seg["fx"]

    # 開啟 ffmpeg 管道
    cmd = ["ffmpeg", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24",
           "-s", f"{VW}x{VH}", "-r", str(FPS), "-i", "pipe:0",
           "-c:v", "libx264", "-preset", "fast", "-crf", "20",
           "-pix_fmt", "yuv420p", clip_path]
    stderr_fh = open(clip_path.replace(".mp4", ".log"), "w")
    pipe = subprocess.Popen(cmd, stdin=subprocess.PIPE,
                            stdout=subprocess.DEVNULL, stderr=stderr_fh)

    for fi in range(seg["frame_start"], seg["frame_end"]):
        t = fi / FPS
        feat = {k: float(features[k][fi]) for k in features}

        # 1. 場景渲染畫布
        canvas = fx_fn(r, feat, t, S)

        # 2. Tonemap 歸一化亮度
        canvas = tonemap(canvas, gamma=seg.get("gamma", 0.75))

        # 3. 回饋加入時間遞迴效果
        if fb and fb_cfg:
            canvas = fb.apply(canvas, **{k: fb_cfg[k] for k in fb_cfg})

        # 4. 著色器鏈加入後處理
        canvas = chain.apply(canvas, f=feat, t=t)

        pipe.stdin.write(canvas.tobytes())

    pipe.stdin.close(); pipe.wait(); stderr_fh.close()
```

### 從場景表構建區段 (Segments)

```python
segments = []
for i, scene in enumerate(SCENES):
    segments.append({
        "id": f"s{i:02d}_{scene['name']}",
        "name": scene["name"],
        "grid": scene["grid"],
        "fx": scene["fx"],
        "shaders": scene.get("shaders", []),
        "feedback": scene.get("feedback", None),
        "gamma": scene.get("gamma", 0.75),
        "frame_start": int(scene["start"] * FPS),
        "frame_end": int(scene["end"] * FPS),
    })
```

### 並行渲染

場景是分發到進程池的獨立單元：

```python
from concurrent.futures import ProcessPoolExecutor, as_completed

with ProcessPoolExecutor(max_workers=N_WORKERS) as pool:
    futures = {
        pool.submit(render_clip, seg, features, clip_path): seg["id"]
        for seg, clip_path in zip(segments, clip_paths)
    }
    for fut in as_completed(futures):
        try:
            fut.result()
        except Exception as e:
            log(f"ERROR {futures[fut]}: {e}")
```

**Pickle 序列化限制**：`ProcessPoolExecutor` 透過 pickle 序列化參數。模組級別的函式可以被 pickle，但 lambda 運算式與閉包則不行。所有的 `fx_*` 場景函式必須定義在模組級別，而非閉包或類別方法。

### 測試影格模式 (Test-Frame Mode)

渲染特定時間戳記的單個影格，以便在不進行完整渲染的情況下驗證視覺效果：

```python
if args.test_frame >= 0:
    fi = min(int(args.test_frame * FPS), N_FRAMES - 1)
    t = fi / FPS
    feat = {k: float(features[k][fi]) for k in features}
    scene = next(sc for sc in reversed(SCENES) if t >= sc["start"])
    r = Renderer()
    r.set_grid(scene["grid"])
    canvas = scene["fx"](r, feat, t, r.S)
    canvas = tonemap(canvas, gamma=scene.get("gamma", 0.75))
    chain = ShaderChain()
    for sn, kw in scene.get("shaders", []):
        chain.add(sn, **kw)
    canvas = chain.apply(canvas, f=feat, t=t)
    Image.fromarray(canvas).save(f"test_{args.test_frame:.1f}s.png")
    print(f"平均亮度：{canvas.astype(float).mean():.1f}")
```

CLI 用法：`python reel.py --test-frame 10.0`

---

## 場景設計檢查清單

針對每個場景：

1. **選擇 2-3 個網格大小** —— 不同比例產生干涉效果。
2. **為每層選擇不同的數值場** —— 不要讓每個網格都用同樣的效果。
3. **為每層選擇不同的色調場** —— 或者至少不同的色調偏移。
4. **為每層選擇不同的調色盤** —— 混搭 PAL_RUNE 與 PAL_BLOCKS 產生的視覺效果與混搭 PAL_RUNE 與 PAL_DENSE 截然不同。
5. **選擇匹配能量的混合模式** —— 亮部用 screen，迷幻感用 difference，細緻處用 exclusion。
6. **在節拍上加入條件式效果** —— 萬花筒、鏡像、故障。
7. **配置回饋效果**，實現拖尾/遞迴外觀 —— 或者設為 None 以獲得乾淨剪接。
8. **設定 Gamma 值**，若使用了破壞性著色器 (solarize, posterize)。
9. 在完整渲染前，使用 **--test-frame** 抽查場景中點影格的視覺效果。

---

## 場景範例 (Scene Examples)

提供可直接複製使用的場景函式，難度由簡到繁。每個範例都是完整的 v2 版場景函式，並返回像素畫布。有關場景協議請參考上方章節，混合模式與 tonemap 詳見 `composition_zh_TW.md`。

---

### 最簡級 —— 單網格、單效果

### 呼吸電漿 (Breathing Plasma)

單網格、單數值場、單色調場。最簡單的場景形式。

```python
def fx_breathing_plasma(r, f, t, S):
    """隨時間循環色調的電漿場。音訊調變亮度。"""
    canvas = _render_vf(r, "md",
        lambda g, f, t, S: vf_plasma(g, f, t, S) * 1.3,
        hf_time_cycle(0.08), PAL_DENSE, f, t, S, sat=0.8)
    return canvas
```

### 反應擴散珊瑚 (Reaction-Diffusion Coral)

單網格、基於模擬的場。隨時間有機地演化。

```python
def fx_coral(r, f, t, S):
    """Gray-Scott 反應擴散 —— 珊瑚分支圖案。
    演化緩慢且有機。最適合環境/放鬆章節。"""
    canvas = _render_vf(r, "sm",
        lambda g, f, t, S: vf_reaction_diffusion(g, f, t, S,
            feed=0.037, kill=0.060, steps_per_frame=6, init_mode="center"),
        hf_distance(0.55, 0.015), PAL_DOTS, f, t, S, sat=0.7)
    return canvas
```

### SDF 幾何體

來自 SDF 的幾何形狀。整潔、精確且具圖形感。

```python
def fx_sdf_rings(r, f, t, S):
    """具備平滑脈動感的同心 SDF 圓環。"""
    def val_fn(g, f, t, S):
        d1 = sdf_ring(g, radius=0.15 + f.get("bass", 0.3) * 0.05, thickness=0.015)
        d2 = sdf_ring(g, radius=0.25 + f.get("mid", 0.3) * 0.05, thickness=0.012)
        d3 = sdf_ring(g, radius=0.35 + f.get("hi", 0.3) * 0.04, thickness=0.010)
        combined = sdf_smooth_union(sdf_smooth_union(d1, d2, 0.05), d3, 0.05)
        return sdf_glow(combined, falloff=0.08) * (0.5 + f.get("rms", 0.3) * 0.8)
    canvas = _render_vf(r, "md", val_fn, hf_angle(0.0), PAL_STARS, f, t, S, sat=0.85)
    return canvas
```

---

### 標準級 —— 雙網格 + 混合

### 貫穿雜訊的隧道 (Tunnel Through Noise)

兩個不同密度的網格，進行 Screen 混合。精細的雜訊紋理會從粗大的隧道字元縫隙中透出。

```python
def fx_tunnel_noise(r, f, t, S):
    """md 網格上的隧道深度 + sm 網格上的 fBM 雜訊，Screen 混合。"""
    canvas_a = _render_vf(r, "md",
        lambda g, f, t, S: vf_tunnel(g, f, t, S, speed=4.0, complexity=8) * 1.2,
        hf_distance(0.5, 0.02), PAL_BLOCKS, f, t, S, sat=0.7)

    canvas_b = _render_vf(r, "sm",
        lambda g, f, t, S: vf_fbm(g, f, t, S, octaves=4, freq=0.05, speed=0.15) * 1.3,
        hf_time_cycle(0.06), PAL_RUNE, f, t, S, sat=0.6)

    return blend_canvas(canvas_a, canvas_b, "screen", 0.7)
```

### Voronoi 細胞 + 螺旋疊加

Voronoi 細胞邊緣疊加螺旋臂圖案。

```python
def fx_voronoi_spiral(r, f, t, S):
    """md 網格上的 Voronoi 邊緣偵測 + lg 網格上的對數螺旋。"""
    canvas_a = _render_vf(r, "md",
        lambda g, f, t, S: vf_voronoi(g, f, t, S,
            n_cells=15, mode="edge", edge_width=2.0, speed=0.4),
        hf_angle(0.2), PAL_CIRCUIT, f, t, S, sat=0.75)

    canvas_b = _render_vf(r, "lg",
        lambda g, f, t, S: vf_spiral(g, f, t, S, n_arms=4, tightness=3.0) * 1.2,
        hf_distance(0.1, 0.03), PAL_BLOCKS, f, t, S, sat=0.9)

    return blend_canvas(canvas_a, canvas_b, "exclusion", 0.6)
```

### 域扭曲 fBM (Domain-Warped fBM)

同一份 fBM 的兩個圖層，其中一層應用域扭曲，進行 Difference 混合以獲得迷幻的有機紋理。

```python
def fx_organic_warp(r, f, t, S):
    """原生 fBM vs 域扭曲 fBM，Difference 混合。"""
    canvas_a = _render_vf(r, "sm",
        lambda g, f, t, S: vf_fbm(g, f, t, S, octaves=5, freq=0.04, speed=0.1),
        hf_plasma(0.2), PAL_DENSE, f, t, S, sat=0.6)

    canvas_b = _render_vf(r, "md",
        lambda g, f, t, S: vf_domain_warp(g, f, t, S,
            warp_strength=20.0, freq=0.05, speed=0.15),
        hf_time_cycle(0.05), PAL_BRAILLE, f, t, S, sat=0.7)

    return blend_canvas(canvas_a, canvas_b, "difference", 0.7)
```

---

### 複雜級 —— 三網格 + 條件式 + 回饋

### 迷幻大教堂 (Psychedelic Cathedral)

包含節拍觸發萬花筒與回饋縮放隧道的三網格合成。視覺複雜度最高的模式。

```python
def fx_cathedral(r, f, t, S):
    """三層大教堂：干涉圖案 + 圓環 + 雜訊，隨節拍觸發萬花筒，
    以及回饋縮放隧道。"""
    # 圖層 1：sm 網格上的干涉圖案
    canvas_a = _render_vf(r, "sm",
        lambda g, f, t, S: vf_interference(g, f, t, S, n_waves=7) * 1.3,
        hf_angle(0.0), PAL_MATH, f, t, S, sat=0.8)

    # 圖層 2：md 網格上的脈動圓環
    canvas_b = _render_vf(r, "md",
        lambda g, f, t, S: vf_rings(g, f, t, S, n_base=10, spacing_base=3) * 1.4,
        hf_distance(0.3, 0.02), PAL_STARS, f, t, S, sat=0.9)

    # 圖層 3：lg 網格上的時間雜訊 (緩慢變形)
    canvas_c = _render_vf(r, "lg",
        lambda g, f, t, S: vf_temporal_noise(g, f, t, S,
            freq=0.04, t_freq=0.2, octaves=3),
        hf_time_cycle(0.12), PAL_BLOCKS, f, t, S, sat=0.7)

    # 混合：A 濾色 (screen) B，然後與 C 進行 Difference 混合
    result = blend_canvas(canvas_a, canvas_b, "screen", 0.8)
    result = blend_canvas(result, canvas_c, "difference", 0.5)

    # 隨節拍觸發的萬花筒
    if f.get("bdecay", 0) > 0.3:
        folds = 6 if f.get("sub_r", 0.3) > 0.4 else 8
        result = sh_kaleidoscope(result.copy(), folds=folds)

    return result

# 包含回饋效果的場景表條目：
# {"start": 30.0, "end": 50.0, "name": "cathedral", "fx": fx_cathedral,
#  "gamma": 0.65, "shaders": [("bloom", {"thr": 110}), ("chromatic", {"amt": 4}),
#                              ("vignette", {"s": 0.2}), ("grain", {"amt": 8})],
#  "feedback": {"decay": 0.75, "blend": "screen", "opacity": 0.35,
#               "transform": "zoom", "transform_amt": 0.012, "hue_shift": 0.015}}
```

### 帶有吸引子疊加的遮罩反應擴散 (Masked Reaction-Diffusion)

反應擴散效果僅透過動畫化光圈遮罩可見，底層為奇異吸引子密度場。

```python
def fx_masked_life(r, f, t, S):
    """吸引子底層 + 透過光圈遮罩可見的反應擴散 + 粒子。"""
    g_sm = r.get_grid("sm")
    g_md = r.get_grid("md")

    # 圖層 1：奇異吸引子密度場 (背景)
    canvas_bg = _render_vf(r, "sm",
        lambda g, f, t, S: vf_strange_attractor(g, f, t, S,
            attractor="clifford", n_points=30000),
        hf_time_cycle(0.04), PAL_DOTS, f, t, S, sat=0.5)

    # 圖層 2：反應擴散 (前景，將被遮蔽)
    canvas_rd = _render_vf(r, "md",
        lambda g, f, t, S: vf_reaction_diffusion(g, f, t, S,
            feed=0.046, kill=0.063, steps_per_frame=4, init_mode="ring"),
        hf_angle(0.15), PAL_HALFFILL, f, t, S, sat=0.85)

    # 動畫化光圈遮罩 —— 在場景前 5 秒開啟
    scene_start = S.get("_scene_start", t)
    if "_scene_start" not in S:
        S["_scene_start"] = t
    mask = mask_iris(g_md, t, scene_start, scene_start + 5.0,
                     max_radius=0.6)
    canvas_rd = apply_mask_canvas(canvas_rd, mask, bg_canvas=canvas_bg)

    # 圖層 3：跟隨 R-D 梯度的流場粒子
    rd_field = vf_reaction_diffusion(g_sm, f, t, S,
        feed=0.046, kill=0.063, steps_per_frame=0)  # 僅讀取而不演化步數
    ch_p, co_p = update_flow_particles(S, g_sm, f, rd_field,
        n=300, speed=0.8, char_set=list("·•◦∘°"))
    canvas_p = g_sm.render(ch_p, co_p)

    result = blend_canvas(canvas_rd, canvas_p, "add", 0.7)
    return result
```

### 帶有平滑關鍵格的場序列變形

展示時間連貫性：透過關鍵格參數在多個效果之間平滑變形。

```python
def fx_morphing_journey(r, f, t, S):
    """在 20 秒內變形 4 個數值場，並帶有平滑過渡。
    參數（扭曲量、臂數）亦透過關鍵格控制。"""
    # 關鍵格控制的扭曲參數
    twist = keyframe(t, [(0, 1.0), (5, 5.0), (10, 2.0), (15, 8.0), (20, 1.0)],
                     ease_fn=ease_in_out_cubic, loop=True)

    # 具有 2 秒交叉淡化時間的數值場序列
    fields = [
        lambda g, f, t, S: vf_plasma(g, f, t, S),
        lambda g, f, t, S: vf_vortex(g, f, t, S, twist=twist),
        lambda g, f, t, S: vf_fbm(g, f, t, S, octaves=5, freq=0.04),
        lambda g, f, t, S: vf_domain_warp(g, f, t, S, warp_strength=15),
    ]
    durations = [5.0, 5.0, 5.0, 5.0]

    val_fn = lambda g, f, t, S: vf_sequence(g, f, t, S, fields, durations,
                                             crossfade=2.0)

    # 配合緩慢旋轉的色調進行渲染
    canvas = _render_vf(r, "md", val_fn, hf_time_cycle(0.06),
                        PAL_DENSE, f, t, S, sat=0.8)

    # 第二層：相同序列在更小網格上的平鋪版本
    tiled_fn = lambda g, f, t, S: vf_sequence(
        make_tgrid(g, *uv_tile(g, 3, 3, mirror=True)),
        f, t, S, fields, durations, crossfade=2.0)
    canvas_b = _render_vf(r, "sm", tiled_fn, hf_angle(0.1),
                          PAL_RUNE, f, t, S, sat=0.6)

    return blend_canvas(canvas, canvas_b, "screen", 0.5)
```

---

### 特殊級 —— 獨特狀態模式

### 帶有幽靈軌跡的生命遊戲 (Game of Life)

具備類比淡出軌跡的細胞自動機。隨節拍注入隨機細胞。

```python
def fx_life(r, f, t, S):
    """康威生命遊戲，帶有淡出的幽靈軌跡。
    節拍事件會注入隨機的活細胞進行干擾。"""
    canvas = _render_vf(r, "sm",
        lambda g, f, t, S: vf_game_of_life(g, f, t, S,
            rule="life", steps_per_frame=1, fade=0.92, density=0.25),
        hf_fixed(0.33), PAL_BLOCKS, f, t, S, sat=0.8)

    # 疊加：lg 網格上的珊瑚自動機，增加塊狀質感
    canvas_b = _render_vf(r, "lg",
        lambda g, f, t, S: vf_game_of_life(g, f, t, S,
            rule="coral", steps_per_frame=1, fade=0.85, density=0.15, seed=99),
        hf_time_cycle(0.1), PAL_HATCH, f, t, S, sat=0.6)

    return blend_canvas(canvas, canvas_b, "screen", 0.5)
```

### Voronoi 背景上的 Boids 群聚

在細胞背景上產生突發的群體運動。

```python
def fx_boid_swarm(r, f, t, S):
    """動畫化 Voronoi 細胞上的群聚 Boids。"""
    # 背景：Voronoi 細胞
    canvas_bg = _render_vf(r, "md",
        lambda g, f, t, S: vf_voronoi(g, f, t, S,
            n_cells=20, mode="distance", speed=0.2),
        hf_distance(0.4, 0.02), PAL_CIRCUIT, f, t, S, sat=0.5)

    # 前景：Boids
    g = r.get_grid("md")
    ch_b, co_b = update_boids(S, g, f, n_boids=150, perception=6.0,
                              max_speed=1.5, char_set=list("▸▹►▻→⟶"))
    canvas_boids = g.render(ch_b, co_b)

    # Boids 的軌跡
    # (Boids 位置存儲在 S["boid_x"], S["boid_y"])
    S["px"] = list(S.get("boid_x", []))
    S["py"] = list(S.get("boid_y", []))
    ch_t, co_t = draw_particle_trails(S, g, max_trail=6, fade=0.6)
    canvas_trails = g.render(ch_t, co_t)

    result = blend_canvas(canvas_bg, canvas_trails, "add", 0.3)
    result = blend_canvas(result, canvas_boids, "add", 0.9)
    return result
```

### 透過 SDF 文字模板升騰的火焰 (Fire Rising)

火焰效果僅在文字字體形狀內可見。

```python
def fx_fire_text(r, f, t, S):
    """透過文字模板可見的火柱。文字作為觀察窗口。"""
    g = r.get_grid("lg")

    # 全螢幕火焰 (將被遮蔽)
    canvas_fire = _render_vf(r, "sm",
        lambda g, f, t, S: np.clip(
            vf_fbm(g, f, t, S, octaves=4, freq=0.08, speed=0.8) *
            (1.0 - g.rr / g.rows) *  # 越往頂部越淡
            (0.6 + f.get("bass", 0.3) * 0.8), 0, 1),
        hf_fixed(0.05), PAL_BLOCKS, f, t, S, sat=0.9)  # 火焰色調

    # 背景：深色域扭曲
    canvas_bg = _render_vf(r, "md",
        lambda g, f, t, S: vf_domain_warp(g, f, t, S,
            warp_strength=8, freq=0.03, speed=0.05) * 0.3,
        hf_fixed(0.6), PAL_DENSE, f, t, S, sat=0.4)

    # 文字模板遮罩
    mask = mask_text(g, "FIRE", row_frac=0.45)
    # 垂直擴展以實現多行覆蓋
    for offset in range(-2, 3):
        shifted = mask_text(g, "FIRE", row_frac=0.45 + offset / g.rows)
        mask = mask_union(mask, shifted)

    canvas_masked = apply_mask_canvas(canvas_fire, mask, bg_canvas=canvas_bg)
    return canvas_masked
```

### 直向模式：垂直雨滴 + 引用語 (Portrait Rain)

針對 9:16 解析度優化。利用垂直空間展示長長的雨滴軌跡與堆疊文字。

```python
def fx_portrait_rain_quote(r, f, t, S):
    """直向優化：矩陣雨（長垂直軌跡）與堆疊引用語。
    專為 1080x1920 (9:16) 設計。"""
    g = r.get_grid("md")  # 直向模式下約為 112x100

    # 矩陣雨 —— 長軌跡充分利用直向模式的多餘行數
    ch, co, S = eff_matrix_rain(g, f, t, S,
        hue=0.33, bri=0.6, pal=PAL_KATA, speed_base=0.4, speed_beat=2.5)
    canvas_rain = g.render(ch, co)

    # 底層隧道深度，增加紋理
    canvas_tunnel = _render_vf(r, "sm",
        lambda g, f, t, S: vf_tunnel(g, f, t, S, speed=3.0, complexity=6) * 0.8,
        hf_fixed(0.33), PAL_BLOCKS, f, t, S, sat=0.5)

    result = blend_canvas(canvas_tunnel, canvas_rain, "screen", 0.8)

    # 引用語文字 —— 直向佈局：多行短語
    g_text = r.get_grid("lg")  # 直向模式下約為 90x80
    quote_lines = layout_text_portrait(
        "程式碼即藝術，藝術即程式碼 (The code is the art and the art is the code)",
        max_chars_per_line=20)
    # 垂直置中
    block_start = (g_text.rows - len(quote_lines)) // 2
    ch_t = np.full((g_text.rows, g_text.cols), " ", dtype="U1")
    co_t = np.zeros((g_text.rows, g_text.cols, 3), dtype=np.uint8)
    total_chars = sum(len(l) for l in quote_lines)
    progress = min(1.0, (t - S.get("_scene_start", t)) / 3.0)
    if "_scene_start" not in S: S["_scene_start"] = t
    render_typewriter(ch_t, co_t, quote_lines, block_start, g_text.cols,
                      progress, total_chars, (200, 255, 220), t)
    canvas_text = g_text.render(ch_t, co_t)

    result = blend_canvas(result, canvas_text, "add", 0.9)
    return result
```

---

### 場景表範例 (Scene Table Template)

將場景連結成一段完整影片：

```python
SCENES = [
    {"start": 0.0,  "end": 5.0,  "name": "coral",
     "fx": fx_coral, "grid": "sm", "gamma": 0.70,
     "shaders": [("bloom", {"thr": 110}), ("vignette", {"s": 0.2})],
     "feedback": {"decay": 0.8, "blend": "screen", "opacity": 0.3,
                  "transform": "zoom", "transform_amt": 0.01}},

    {"start": 5.0,  "end": 15.0, "name": "tunnel_noise",
     "fx": fx_tunnel_noise, "grid": "md", "gamma": 0.75,
     "shaders": [("chromatic", {"amt": 3}), ("bloom", {"thr": 120}),
                 ("scanlines", {"intensity": 0.06}), ("grain", {"amt": 8})],
     "feedback": None},

    {"start": 15.0, "end": 35.0, "name": "cathedral",
     "fx": fx_cathedral, "grid": "sm", "gamma": 0.65,
     "shaders": [("bloom", {"thr": 100}), ("chromatic", {"amt": 5}),
                 ("color_wobble", {"amt": 0.2}), ("vignette", {"s": 0.18})],
     "feedback": {"decay": 0.75, "blend": "screen", "opacity": 0.35,
                  "transform": "zoom", "transform_amt": 0.012, "hue_shift": 0.015}},

    {"start": 35.0, "end": 50.0, "name": "morphing",
     "fx": fx_morphing_journey, "grid": "md", "gamma": 0.70,
     "shaders": [("bloom", {"thr": 110}), ("grain", {"amt": 6})],
     "feedback": {"decay": 0.7, "blend": "screen", "opacity": 0.25,
                  "transform": "rotate_cw", "transform_amt": 0.003}},
]
```
