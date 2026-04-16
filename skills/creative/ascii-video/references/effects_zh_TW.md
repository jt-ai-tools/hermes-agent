# 效果目錄 (Effect Catalog)

這是一些產生視覺圖案的效果構建塊。在 v2 版本中，這些構建塊被用於**場景函式內部**，而場景函式會直接返回一個像素畫布。下方的構建塊在網格座標陣列上運作，並產生 `(chars, colors)` 或數值/色調場，場景函式再透過 `_render_vf()` 將其渲染到畫布上。

> **另請參閱：** [architecture_zh_TW.md](architecture_zh_TW.md) · [composition_zh_TW.md](composition_zh_TW.md) · [scenes_zh_TW.md](scenes_zh_TW.md) · [shaders_zh_TW.md](shaders_zh_TW.md) · [troubleshooting_zh_TW.md](troubleshooting_zh_TW.md)

## 設計理念

效果是創意的核心。不要在每個專案中照抄這些程式碼 —— 應將它們視為**構建塊**，並進行**組合、修改和發明**新的效果。每個專案都應該有獨特的感受。

核心原則：
- **疊加多個效果**，而非使用單一的大型函式
- **參數化一切** —— 色調、速度、密度、振幅都應作為參數
- **特徵反應** —— 音訊/影片特徵應調變每個效果中至少 2-3 個參數
- **章節變化** —— 絕不要在整段影片中始終使用相同的效果配置
- **發明專案特定效果** —— 下方的目錄只是基礎詞彙，而非固定的集合

---

## 背景填充 (Background Fills)

每個效果都應從背景開始。絕不要留下純黑的底色。

### 動畫正弦場 (Animated Sine Field，通用型)
```python
def bg_sinefield(g, f, t, hue=0.6, bri=0.5, pal=PAL_DEFAULT,
                 freq=(0.13, 0.17, 0.07, 0.09), speed=(0.5, -0.4, -0.3, 0.2)):
    """分層正弦場。調整 freq/speed 元組以獲得不同的紋理。"""
    v1 = np.sin(g.cc*freq[0] + t*speed[0]) * np.sin(g.rr*freq[1] - t*speed[1]) * 0.5 + 0.5
    v2 = np.sin(g.cc*freq[2] - t*speed[2] + g.rr*freq[3]) * 0.4 + 0.5
    v3 = np.sin(g.dist_n*5 + t*0.2) * 0.3 + 0.4
    v4 = np.cos(g.angle*3 - t*0.6) * 0.15 + 0.5
    val = np.clip((v1*0.3 + v2*0.25 + v3*0.25 + v4*0.2) * bri * (0.6 + f["rms"]*0.6), 0.06, 1)
    mask = val > 0.03
    ch = val2char(val, mask, pal)
    h = np.full_like(val, hue) + f.get("cent", 0.5)*0.1 + val*0.08
    R, G, B = hsv2rgb(h, np.clip(0.35+f.get("flat",0.4)*0.4, 0, 1) * np.ones_like(val), val)
    return ch, mkc(R, G, B, g.rows, g.cols)
```

### 影片源背景
```python
def bg_video(g, frame_rgb, pal=PAL_DEFAULT, brightness=0.5):
    small = np.array(Image.fromarray(frame_rgb).resize((g.cols, g.rows)))
    lum = np.mean(small, axis=2) / 255.0 * brightness
    mask = lum > 0.02
    ch = val2char(lum, mask, pal)
    co = np.clip(small * np.clip(lum[:,:,None]*1.5+0.3, 0.3, 1), 0, 255).astype(np.uint8)
    return ch, co
```

### 雜訊 / 靜電場 (Noise / Static Field)
```python
def bg_noise(g, f, t, pal=PAL_BLOCKS, density=0.3, hue_drift=0.02):
    val = np.random.random((g.rows, g.cols)).astype(np.float32) * density * (0.5 + f["rms"]*0.5)
    val = np.clip(val, 0, 1); mask = val > 0.02
    ch = val2char(val, mask, pal)
    R, G, B = hsv2rgb(np.full_like(val, t*hue_drift % 1), np.full_like(val, 0.3), val)
    return ch, mkc(R, G, B, g.rows, g.cols)
```

### 類 Perlin 平滑雜訊
```python
def bg_smooth_noise(g, f, t, hue=0.5, bri=0.5, pal=PAL_DOTS, octaves=3):
    """Perlin 雜訊的分層正弦逼近。低成本、平滑且具備有機感。"""
    val = np.zeros((g.rows, g.cols), dtype=np.float32)
    for i in range(octaves):
        freq = 0.05 * (2 ** i)
        amp = 0.5 / (i + 1)
        phase = t * (0.3 + i * 0.2)
        val += np.sin(g.cc * freq + phase) * np.cos(g.rr * freq * 0.7 - phase * 0.5) * amp
    val = np.clip(val * 0.5 + 0.5, 0, 1) * bri
    mask = val > 0.03
    ch = val2char(val, mask, pal)
    h = np.full_like(val, hue) + val * 0.1
    R, G, B = hsv2rgb(h, np.full_like(val, 0.5), val)
    return ch, mkc(R, G, B, g.rows, g.cols)
```

### 細胞 / Voronoi 逼近
```python
def bg_cellular(g, f, t, n_centers=12, hue=0.5, bri=0.6, pal=PAL_BLOCKS):
    """使用與 N 個移動中心點中最近點的距離來模擬 Voronoi 細胞。"""
    rng = np.random.RandomState(42)  # 確定性中心
    cx = (rng.rand(n_centers) * g.cols).astype(np.float32)
    cy = (rng.rand(n_centers) * g.rows).astype(np.float32)
    # 動畫化中心點
    cx_t = cx + np.sin(t * 0.5 + np.arange(n_centers) * 0.7) * 5
    cy_t = cy + np.cos(t * 0.4 + np.arange(n_centers) * 0.9) * 3
    # 到任何中心點的最短距離
    min_d = np.full((g.rows, g.cols), 999.0, dtype=np.float32)
    for i in range(n_centers):
        d = np.sqrt((g.cc - cx_t[i])**2 + (g.rr - cy_t[i])**2)
        min_d = np.minimum(min_d, d)
    val = np.clip(1.0 - min_d / (g.cols * 0.3), 0, 1) * bri
    # 細胞邊緣（兩個中心點距離近乎相等的地方）
    # ... 可使用次近點技巧來突出邊緣
    mask = val > 0.03
    ch = val2char(val, mask, pal)
    R, G, B = hsv2rgb(np.full_like(val, hue) + min_d * 0.005, np.full_like(val, 0.5), val)
    return ch, mkc(R, G, B, g.rows, g.cols)
```

---

> **注意：** v1 版本的 `eff_rings`, `eff_rays`, `eff_spiral`, `eff_glow`, `eff_tunnel`, `eff_vortex`, `eff_freq_waves`, `eff_interference`, `eff_aurora` 和 `eff_ripple` 函式已被下方的 `vf_*` 數值場生成器取代（透過 `_render_vf()` 使用）。`vf_*` 版本整合了多網格合成流水線，是所有新場景的首選。

---

## 粒子系統 (Particle Systems)

### 通用模式
所有粒子系統都透過 `S` 字典參數使用持久化狀態：
```python
# S 是持久化狀態字典 (與 r.S 相同，明確傳遞)
if "px" not in S:
    S["px"]=[]; S["py"]=[]; S["vx"]=[]; S["vy"]=[]; S["life"]=[]; S["char"]=[]

# 發射新粒子 (依節拍、持續發射或觸發發射)
# 更新：位置 += 速度，應用作用力，衰減生命值
# 繪製：映射到網格，根據生命值設定字元/顏色
# 清理：移除死掉的粒子，限制總數
```

### 粒子字元集

不要硬編碼粒子字元。應根據專案/氛圍選擇：

```python
# 能量 / 爆炸
PART_ENERGY  = list("*+#@\u26a1\u2726\u2605\u2588\u2593")
PART_SPARK   = list("\u00b7\u2022\u25cf\u2605\u2736*+")
# 有機 / 自然
PART_LEAF    = list("\u2740\u2741\u2742\u2743\u273f\u2618\u2022")
PART_SNOW    = list("\u2744\u2745\u2746\u00b7\u2022*\u25cb")
PART_RAIN    = list("|\u2502\u2503\u2551/\\")
PART_BUBBLE  = list("\u25cb\u25ce\u25c9\u25cf\u2218\u2219\u00b0")
# 數據 / 科技
PART_DATA    = list("01{}[]<>|/\\")
PART_HEX     = list("0123456789ABCDEF")
PART_BINARY  = list("01")
# 神祕學
PART_RUNE    = list("\u16a0\u16a2\u16a6\u16b1\u16b7\u16c1\u16c7\u16d2\u16d6\u16da\u16de\u16df\u2726\u2605")
PART_ZODIAC  = list("\u2648\u2649\u264a\u264b\u264c\u264d\u264e\u264f\u2650\u2651\u2652\u2653")
# 極簡
PART_DOT     = list("\u00b7\u2022\u25cf")
PART_DASH    = list("-=~\u2500\u2550")
```

### 爆炸 (節拍觸發)
```python
def emit_explosion(S, f, center_r, center_c, char_set=PART_ENERGY, count_base=80):
    if f.get("beat", 0) > 0:
        for _ in range(int(count_base + f["rms"]*150)):
            ang = random.uniform(0, 2*math.pi)
            sp = random.uniform(1, 9) * (0.5 + f.get("sub_r", 0.3)*2)
            S["px"].append(float(center_c))
            S["py"].append(float(center_r))
            S["vx"].append(math.cos(ang)*sp*2.5)
            S["vy"].append(math.sin(ang)*sp)
            S["life"].append(1.0)
            S["char"].append(random.choice(char_set))
# 更新：重力作用於 vy += 0.03, life -= 0.015
# 顏色：life * 255 決定亮度，色調淡出由調用者控制
```

### 上升餘燼 (Rising Embers)
```python
# 發射：sy = rows-1, vy = -random.uniform(1,5), vx = random.uniform(-1.5,1.5)
# 更新：vx += 隨機抖動 * 0.3, life -= 0.01
# 限制在 ~1500 個粒子以內
```

### 溶解雲 (Dissolving Cloud)
```python
# 初始化：N=600 個粒子散佈在螢幕上
# 更新：緩慢向上漂移，漸進式淡出
# life -= 0.002 * (1 + 經過時間 * 0.05)  # 加速淡出
```

### 星場 (3D 投影)
```python
# N 顆恆星，(sx, sy, sz) 為歸一化座標
# 移動：sz -= 速度 (恆星靠近攝影機)
# 投影：px = cx + sx/sz * cx, py = cy + sy/sz * cy
# 重置通過攝影機的恆星 (sz <= 0.01)
# 亮度 = (1 - sz)，在明亮的恆星後方繪製拖尾
```

### 軌道 (圓形/橢圓運動)
```python
def emit_orbit(S, n=20, radius=15, speed=1.0, char_set=PART_DOT):
    """粒子繞中心點旋轉。"""
    for i in range(n):
        angle = i * 2 * math.pi / n
        S["px"].append(0.0); S["py"].append(0.0)  # 將由角度計算
        S["vx"].append(angle)  # 將角度存為 "vx" 用於軌道
        S["vy"].append(radius + random.uniform(-2, 2))  # 存儲半徑
        S["life"].append(1.0)
        S["char"].append(random.choice(char_set))
# 更新：angle += speed * dt, px = cx + radius * cos(angle), py = cy + radius * sin(angle)
```

### 重力井
```python
# 粒子被吸引向一個或多個重力點
# 更新：計算指向每個重力井的力向量，作為加速度應用
# 到達重力井中心的粒子在邊緣重新生成
```

### 群聚 (Flocking / Boids)

從三個簡單規則產生的突發群體行為：分離 (separation)、對齊 (alignment)、凝聚 (cohesion)。

```python
def update_boids(S, g, f, n_boids=200, perception=8.0, max_speed=2.0,
                 sep_weight=1.5, ali_weight=1.0, coh_weight=1.0,
                 char_set=None):
    """Boids 群聚模擬。粒子會自我組織成有機群體。

    perception: 每個 boid 的可見範圍 (網格單元數)
    sep_weight: 分離 (避免擁擠) 的強度
    ali_weight: 對齊 (與鄰居速度一致) 的強度
    coh_weight: 凝聚 (朝群體中心移動) 的強度
    """
    if char_set is None:
        char_set = list("·•●◦∘⬤")
    if "boid_x" not in S:
        rng = np.random.RandomState(42)
        S["boid_x"] = rng.uniform(0, g.cols, n_boids).astype(np.float32)
        S["boid_y"] = rng.uniform(0, g.rows, n_boids).astype(np.float32)
        S["boid_vx"] = (rng.random(n_boids).astype(np.float32) - 0.5) * max_speed
        S["boid_vy"] = (rng.random(n_boids).astype(np.float32) - 0.5) * max_speed
        S["boid_ch"] = [random.choice(char_set) for _ in range(n_boids)]

    bx = S["boid_x"]; by = S["boid_y"]
    bvx = S["boid_vx"]; bvy = S["boid_vy"]
    n = len(bx)

    # 為每個 boid 計算轉向力
    ax = np.zeros(n, dtype=np.float32)
    ay = np.zeros(n, dtype=np.float32)

    # 空間雜湊，用於高效查找鄰居
    cell_size = perception
    cells = {}
    for i in range(n):
        cx_i = int(bx[i] / cell_size)
        cy_i = int(by[i] / cell_size)
        key = (cx_i, cy_i)
        if key not in cells:
            cells[key] = []
        cells[key].append(i)

    for i in range(n):
        cx_i = int(bx[i] / cell_size)
        cy_i = int(by[i] / cell_size)
        sep_x, sep_y = 0.0, 0.0
        ali_x, ali_y = 0.0, 0.0
        coh_x, coh_y = 0.0, 0.0
        count = 0

        # 檢查相鄰單元格
        for dcx in range(-1, 2):
            for dcy in range(-1, 2):
                for j in cells.get((cx_i + dcx, cy_i + dcy), []):
                    if j == i:
                        continue
                    dx = bx[j] - bx[i]
                    dy = by[j] - by[i]
                    dist = np.sqrt(dx * dx + dy * dy)
                    if dist < perception and dist > 0.01:
                        count += 1
                        # 分離：遠離過近的鄰居
                        if dist < perception * 0.4:
                            sep_x -= dx / (dist * dist)
                            sep_y -= dy / (dist * dist)
                        # 對齊：匹配速度
                        ali_x += bvx[j]
                        ali_y += bvy[j]
                        # 凝聚：朝群體中心轉向
                        coh_x += bx[j]
                        coh_y += by[j]

        if count > 0:
            # 歸一化與加權
            ax[i] += sep_x * sep_weight
            ay[i] += sep_y * sep_weight
            ax[i] += (ali_x / count - bvx[i]) * ali_weight * 0.1
            ay[i] += (ali_y / count - bvy[i]) * ali_weight * 0.1
            ax[i] += (coh_x / count - bx[i]) * coh_weight * 0.01
            ay[i] += (coh_y / count - by[i]) * coh_weight * 0.01

    # 音訊反應：低音將 boids 從中心向外推
    if f.get("bass", 0) > 0.5:
        cx_g, cy_g = g.cols / 2, g.rows / 2
        dx = bx - cx_g; dy = by - cy_g
        dist = np.sqrt(dx**2 + dy**2) + 1
        ax += (dx / dist) * f["bass"] * 2
        ay += (dy / dist) * f["bass"] * 2

    # 更新速度與位置
    bvx += ax; bvy += ay
    # 限制速度
    speed = np.sqrt(bvx**2 + bvy**2) + 1e-10
    over = speed > max_speed
    bvx[over] *= max_speed / speed[over]
    bvy[over] *= max_speed / speed[over]
    bx += bvx; by += bvy

    # 邊緣環繞
    bx %= g.cols; by %= g.rows

    S["boid_x"] = bx; S["boid_y"] = by
    S["boid_vx"] = bvx; S["boid_vy"] = bvy

    # 繪製
    ch = np.full((g.rows, g.cols), " ", dtype="U1")
    co = np.zeros((g.rows, g.cols, 3), dtype=np.uint8)
    for i in range(n):
        r, c = int(by[i]) % g.rows, int(bx[i]) % g.cols
        ch[r, c] = S["boid_ch"][i]
        spd = min(1.0, speed[i] / max_speed)
        R, G, B = hsv2rgb_scalar(spd * 0.3, 0.8, 0.5 + spd * 0.5)
        co[r, c] = (R, G, B)
    return ch, co
```

### 流場粒子 (Flow Field Particles)

跟隨數值場梯度的粒子。任何 `vf_*` 函式都可以變成運送粒子的「河流」：

```python
def update_flow_particles(S, g, f, flow_field, n=500, speed=1.0,
                          life_drain=0.005, emit_rate=10,
                          char_set=None):
    """跟隨數值場梯度導向的粒子。

    flow_field: float32 (rows, cols) — 粒子跟隨的場。
                粒子從低值流向高值 (上坡) 或沿梯度方向移動。
    """
    if char_set is None:
        char_set = list("·•∘◦°⋅")
    if "fp_x" not in S:
        S["fp_x"] = []; S["fp_y"] = []; S["fp_vx"] = []; S["fp_vy"] = []
        S["fp_life"] = []; S["fp_ch"] = []

    # 在隨機位置發射新粒子
    for _ in range(emit_rate):
        if len(S["fp_x"]) < n:
            S["fp_x"].append(random.uniform(0, g.cols - 1))
            S["fp_y"].append(random.uniform(0, g.rows - 1))
            S["fp_vx"].append(0.0); S["fp_vy"].append(0.0)
            S["fp_life"].append(1.0)
            S["fp_ch"].append(random.choice(char_set))

    # 計算流場梯度 (中心差分)
    pad = np.pad(flow_field, 1, mode="wrap")
    grad_x = (pad[1:-1, 2:] - pad[1:-1, :-2]) * 0.5
    grad_y = (pad[2:, 1:-1] - pad[:-2, 1:-1]) * 0.5

    # 更新粒子
    i = 0
    while i < len(S["fp_x"]):
        px, py = S["fp_x"][i], S["fp_y"][i]
        # 在粒子位置取樣梯度
        gc = int(px) % g.cols; gr = int(py) % g.rows
        gx = grad_x[gr, gc]; gy = grad_y[gr, gc]
        # 向梯度方向導向速度
        S["fp_vx"][i] = S["fp_vx"][i] * 0.9 + gx * speed * 10
        S["fp_vy"][i] = S["fp_vy"][i] * 0.9 + gy * speed * 10
        S["fp_x"][i] += S["fp_vx"][i]
        S["fp_y"][i] += S["fp_vy"][i]
        S["fp_life"][i] -= life_drain

        if S["fp_life"][i] <= 0:
            for k in ("fp_x", "fp_y", "fp_vx", "fp_vy", "fp_life", "fp_ch"):
                S[k].pop(i)
        else:
            i += 1

    # 繪製
    ch = np.full((g.rows, g.cols), " ", dtype="U1")
    co = np.zeros((g.rows, g.cols, 3), dtype=np.uint8)
    for i in range(len(S["fp_x"])):
        r = int(S["fp_y"][i]) % g.rows
        c = int(S["fp_x"][i]) % g.cols
        ch[r, c] = S["fp_ch"][i]
        v = S["fp_life"][i]
        co[r, c] = (int(v * 200), int(v * 180), int(v * 255))
    return ch, co
```

### 粒子軌跡 (Particle Trails)

在當前位置與前一位置之間繪製淡出的線條：

```python
def draw_particle_trails(S, g, trail_key="trails", max_trail=8, fade=0.7):
    """為任何粒子系統添加軌跡。在更新位置後調用。
    將之前的位存儲在 S[trail_key] 中並繪製淡出的線條。

    期望 S 具有 'px', 'py' 列表 (標準粒子鍵)。
    max_trail: 記憶的前一個位置數量
    fade: 每一步軌跡的亮度乘數 (0.7 = 每向後一步亮度變為 70%)
    """
    if trail_key not in S:
        S[trail_key] = []

    # 存儲當前位置
    current = list(zip(
        [int(y) for y in S.get("py", [])],
        [int(x) for x in S.get("px", [])]
    ))
    S[trail_key].append(current)
    if len(S[trail_key]) > max_trail:
        S[trail_key] = S[trail_key][-max_trail:]

    # 將軌跡繪製到字元/顏色陣列
    ch = np.full((g.rows, g.cols), " ", dtype="U1")
    co = np.zeros((g.rows, g.cols, 3), dtype=np.uint8)
    trail_chars = list("·∘◦°⋅.,'`")

    for age, positions in enumerate(reversed(S[trail_key])):
        bri = fade ** age
        if bri < 0.05:
            break
        ci = min(age, len(trail_chars) - 1)
        for r, c in positions:
            if 0 <= r < g.rows and 0 <= c < g.cols and ch[r, c] == " ":
                ch[r, c] = trail_chars[ci]
                v = int(bri * 180)
                co[r, c] = (v, v, int(v * 0.8))
    return ch, co
```

---

## 雨滴 / 矩陣效果 (Rain / Matrix Effects)

### 欄位雨滴 (向量化)
```python
def eff_matrix_rain(g, f, t, S, hue=0.33, bri=0.6, pal=PAL_KATA,
                    speed_base=0.5, speed_beat=3.0):
    """向量化矩陣雨。S 字典持久化各欄位置。"""
    if "ry" not in S or len(S["ry"]) != g.cols:
        S["ry"] = np.random.uniform(-g.rows, g.rows, g.cols).astype(np.float32)
        S["rsp"] = np.random.uniform(0.3, 2.0, g.cols).astype(np.float32)
        S["rln"] = np.random.randint(8, 40, g.cols)
        S["rch"] = np.random.randint(0, len(pal), (g.rows, g.cols))  # 預先分配字元

    speed_mult = speed_base + f.get("bass", 0.3)*speed_beat + f.get("sub_r", 0.3)*3
    if f.get("beat", 0) > 0: speed_mult *= 2.5
    S["ry"] += S["rsp"] * speed_mult

    # 重置掉出底部的欄位
    rst = (S["ry"] - S["rln"]) > g.rows
    S["ry"][rst] = np.random.uniform(-25, -2, rst.sum())

    # 使用花式索引進行向量化繪製
    ch = np.full((g.rows, g.cols), " ", dtype="U1")
    co = np.zeros((g.rows, g.cols, 3), dtype=np.uint8)
    heads = S["ry"].astype(int)
    for c in range(g.cols):
        head = heads[c]
        trail_len = S["rln"][c]
        for i in range(trail_len):
            row = head - i
            if 0 <= row < g.rows:
                fade = 1.0 - i / trail_len
                ci = S["rch"][row, c] % len(pal)
                ch[row, c] = pal[ci]
                v = fade * bri * 255
                if i == 0:  # 頭部呈現亮白色系
                    co[row, c] = (int(v*0.9), int(min(255, v*1.1)), int(v*0.9))
                else:
                    R, G, B = hsv2rgb_single(hue, 0.7, fade * bri)
                    co[row, c] = (R, G, B)
    return ch, co, S
```

---

## 故障 / 數據效果 (Glitch / Data Effects)

### 水平條帶位移
```python
def eff_glitch_displace(ch, co, f, intensity=1.0):
    n_bands = int(8 + f.get("flux", 0.3)*25 + f.get("bdecay", 0)*15) * intensity
    for _ in range(int(n_bands)):
        y = random.randint(0, ch.shape[0]-1)
        h = random.randint(1, int(3 + f.get("sub", 0.3)*8))
        shift = int((random.random()-0.5) * f.get("rms", 0.3)*40 + f.get("bdecay", 0)*20*(random.random()-0.5))
        if shift != 0:
            for row in range(h):
                rr = y + row
                if 0 <= rr < ch.shape[0]:
                    ch[rr] = np.roll(ch[rr], shift)
                    co[rr] = np.roll(co[rr], shift, axis=0)
    return ch, co
```

### 區塊損壞 (Block Corruption)
```python
def eff_block_corrupt(ch, co, f, char_pool=None, count_base=20):
    if char_pool is None:
        char_pool = list(PAL_BLOCKS[4:] + PAL_KATA[2:8])
    for _ in range(int(count_base + f.get("flux", 0.3)*60 + f.get("bdecay", 0)*40)):
        bx = random.randint(0, max(1, ch.shape[1]-6))
        by = random.randint(0, max(1, ch.shape[0]-4))
        bw, bh = random.randint(2,6), random.randint(1,4)
        block_char = random.choice(char_pool)
        # 填充帶有隨機顏色的單一字元矩形
        for r in range(bh):
            for c in range(bw):
                rr, cc = by+r, bx+c
                if 0 <= rr < ch.shape[0] and 0 <= cc < ch.shape[1]:
                    ch[rr, cc] = block_char
                    co[rr, cc] = (random.randint(100,255), random.randint(0,100), random.randint(0,80))
    return ch, co
```

### 掃描條 (垂直)
```python
def eff_scanbars(ch, co, f, t, n_base=4, chars="|\u2551|!1l"):
    for bi in range(int(n_base + f.get("himid_r", 0.3)*12)):
        sx = int((t*50*(1+bi*0.3) + bi*37) % ch.shape[1])
        for rr in range(ch.shape[0]):
            if random.random() < 0.7:
                ch[rr, sx] = random.choice(chars)
    return ch, co
```

### 錯誤訊息
```python
# 為每個專案參數化錯誤詞彙：
ERRORS_TECH = ["SEGFAULT","0xDEADBEEF","BUFFER_OVERRUN","PANIC!","NULL_PTR",
               "CORRUPT","SIGSEGV","ERR_OVERFLOW","STACK_SMASH","BAD_ALLOC"]
ERRORS_COSMIC = ["VOID_BREACH","ENTROPY_MAX","SINGULARITY","DIMENSION_FAULT",
                 "REALITY_ERR","TIME_PARADOX","DARK_MATTER_LEAK","QUANTUM_DECOHERE"]
ERRORS_ORGANIC = ["CELL_DIVISION_ERR","DNA_MISMATCH","MUTATION_OVERFLOW",
                  "NEURAL_DEADLOCK","SYNAPSE_TIMEOUT","MEMBRANE_BREACH"]
```

### 十六進位數據流
```python
hex_str = "".join(random.choice("0123456789ABCDEF") for _ in range(random.randint(8,20)))
stamp(ch, co, hex_str, rand_row, rand_col, (0, 160, 80))
```

---

## 頻譜 / 視覺化 (Spectrum / Visualization)

### 鏡像頻譜條
```python
def eff_spectrum(g, f, t, n_bars=64, pal=PAL_BLOCKS, mirror=True):
    bar_w = max(1, g.cols // n_bars); mid = g.rows // 2
    band_vals = np.array([f.get("sub",0.3), f.get("bass",0.3), f.get("lomid",0.3),
                          f.get("mid",0.3), f.get("himid",0.3), f.get("hi",0.3)])
    ch = np.full((g.rows, g.cols), " ", dtype="U1")
    co = np.zeros((g.rows, g.cols, 3), dtype=np.uint8)
    for b in range(n_bars):
        frac = b / n_bars
        fi = frac * 5; lo_i = int(fi); hi_i = min(lo_i+1, 5)
        bval = min(1, (band_vals[lo_i]*(1-fi%1) + band_vals[hi_i]*(fi%1)) * 1.8)
        height = int(bval * (g.rows//2 - 2))
        for dy in range(height):
            hue = (f.get("cent",0.5)*0.3 + frac*0.3 + dy/max(height,1)*0.15) % 1.0
            ci = pal[min(int(dy/max(height,1)*len(pal)*0.7+len(pal)*0.2), len(pal)-1)]
            for dc in range(bar_w - (1 if bar_w > 2 else 0)):
                cc = b*bar_w + dc
                if 0 <= cc < g.cols:
                    rows_to_draw = [mid - dy, mid + dy] if mirror else [g.rows - 1 - dy]
                    for row in rows_to_draw:
                        if 0 <= row < g.rows:
                            ch[row, cc] = ci
                            co[row, cc] = hsv_to_rgb_single(hue, 0.85, 0.5+dy/max(height,1)*0.5)
    return ch, co
```

### 波形圖
```python
def eff_waveform(g, f, t, row_offset=-5, hue=0.1):
    ch = np.full((g.rows, g.cols), " ", dtype="U1")
    co = np.zeros((g.rows, g.cols, 3), dtype=np.uint8)
    for c in range(g.cols):
        wv = (math.sin(c*0.15+t*5)*f.get("bass",0.3)*0.5
            + math.sin(c*0.3+t*8)*f.get("mid",0.3)*0.3
            + math.sin(c*0.6+t*12)*f.get("hi",0.3)*0.15)
        wr = g.rows + row_offset + int(wv * 4)
        if 0 <= wr < g.rows:
            ch[wr, c] = "~"
            v = int(120 + f.get("rms",0.3)*135)
            co[wr, c] = [v, int(v*0.7), int(v*0.4)]
    return ch, co
```

---

## 火焰 / 岩漿

### 火柱
```python
def eff_fire(g, f, t, n_base=20, hue_base=0.02, hue_range=0.12, pal=PAL_BLOCKS):
    n_cols = int(n_base + f.get("bass",0.3)*30 + f.get("sub_r",0.3)*20)
    ch = np.full((g.rows, g.cols), " ", dtype="U1")
    co = np.zeros((g.rows, g.cols, 3), dtype=np.uint8)
    for fi in range(n_cols):
        fx_c = int((fi*g.cols/n_cols + np.sin(t*2+fi*0.7)*3) % g.cols)
        height = int((f.get("bass",0.3)*0.4 + f.get("sub_r",0.3)*0.3 + f.get("rms",0.3)*0.3) * g.rows * 0.7)
        for dy in range(min(height, g.rows)):
            fr = g.rows - 1 - dy
            frac = dy / max(height, 1)
            bri = max(0.1, (1 - frac*0.6) * (0.5 + f.get("rms",0.3)*0.5))
            hue = hue_base + frac * hue_range
            ci = "\u2588" if frac<0.2 else ("\u2593" if frac<0.4 else ("\u2592" if frac<0.6 else "\u2591"))
            ch[fr, fx_c] = ci
            R, G, B = hsv2rgb_single(hue, 0.9, bri)
            co[fr, fx_c] = (R, G, B)
    return ch, co
```

### 冰霜 / 冷火 (結構相同，色調範圍不同)
```python
# hue_base=0.55, hue_range=0.15 -- 藍色到青色
# 強度較低，移動較慢
```

---

## 文字疊加 (Text Overlays)

### 捲動跑馬燈
```python
def eff_ticker(ch, co, t, text, row, speed=15, color=(80, 100, 140)):
    off = int(t * speed) % max(len(text), 1)
    doubled = text + "   " + text
    stamp(ch, co, doubled[off:off+ch.shape[1]], row, 0, color)
```

### 節拍觸發單詞
```python
def eff_beat_words(ch, co, f, words, row_center=None, color=(255,240,220)):
    if f.get("beat", 0) > 0:
        w = random.choice(words)
        r = (row_center or ch.shape[0]//2) + random.randint(-5,5)
        stamp(ch, co, w, r, (ch.shape[1]-len(w))//2, color)
```

### 漸變訊息序列
```python
def eff_fading_messages(ch, co, t, elapsed, messages, period=4.0, color_base=(220,220,220)):
    msg_idx = int(elapsed / period) % len(messages)
    phase = elapsed % period
    fade = max(0, min(1.0, phase) * min(1.0, period - phase))
    if fade > 0.05:
        v = fade
        msg = messages[msg_idx]
        cr, cg, cb = [int(c * v) for c in color_base]
        stamp(ch, co, msg, ch.shape[0]//2, (ch.shape[1]-len(msg))//2, (cr, cg, cb))
```

---

## 畫面震動 (Screen Shake)
在節拍上平移整個字元/顏色陣列：
```python
def eff_shake(ch, co, f, x_amp=6, y_amp=3):
    shake_x = int(f.get("sub",0.3)*x_amp*(random.random()-0.5)*2 + f.get("bdecay",0)*4*(random.random()-0.5)*2)
    shake_y = int(f.get("bass",0.3)*y_amp*(random.random()-0.5)*2)
    if abs(shake_x) > 0:
        ch = np.roll(ch, shake_x, axis=1)
        co = np.roll(co, shake_x, axis=1)
    if abs(shake_y) > 0:
        ch = np.roll(ch, shake_y, axis=0)
        co = np.roll(co, shake_y, axis=0)
    return ch, co
```

---

## 可組合效果系統 (Composable Effect System)

真正的創意能量來自於**合成**。共分為三個層次：

### 第一層：字元級分層

將多個效果堆疊為 `(chars, colors)` 圖層：

```python
class LayerStack(EffectNode):
    """由下而上渲染效果，並進行字元級合成。"""
    def add(self, effect, alpha=1.0):
        """alpha < 1.0 = 機率性覆蓋 (稀疏疊加)。"""
        self.layers.append((effect, alpha))

# 用法：
stack = LayerStack()
stack.add(bg_effect)           # 底層 —— 填滿螢幕
stack.add(main_effect)         # 疊加在上方 (空格 = 透明)
stack.add(particle_effect)     # 疊加在最上方的稀疏層
ch, co = stack.render(g, f, t, S)
```

### 第二層：像素級混合

在渲染到畫布後，使用類似 Photoshop 的模式進行混合：

```python
class PixelBlendStack:
    """將畫布堆疊並使用混合模式進行複雜合成。"""
    def add(self, canvas, mode="normal", opacity=1.0)
    def composite(self) -> canvas

# 用法：
pbs = PixelBlendStack()
pbs.add(canvas_a)                        # 底層
pbs.add(canvas_b, "screen", 0.7)        # 加法發光
pbs.add(canvas_c, "difference", 0.5)    # 迷幻干涉
result = pbs.composite()
```

### 第三層：時間回饋 (Temporal Feedback)

將前一格影格饋送回當前影格以實現遞迴效果：

```python
fb = FeedbackBuffer()
for each frame:
    canvas = render_current()
    canvas = fb.apply(canvas, decay=0.8, blend="screen",
                      transform="zoom", transform_amt=0.015, hue_shift=0.02)
```

### 效果節點 —— 統一介面

在 v2 協議中，效果節點被用於場景函式**內部**。場景函式本身返回一個畫布。效果節點產生中間的 `(chars, colors)`，然後透過網格的 `.render()` 方法或 `_render_vf()` 渲染到畫布上。

```python
class EffectNode:
    def render(self, g, f, t, S) -> (chars, colors)

# 具體實作：
class ValueFieldEffect(EffectNode):
    """封裝一個數值場函式 + 色調場函式 + 調色盤。"""
    def __init__(self, val_fn, hue_fn, pal=PAL_DEFAULT, sat=0.7)

class LambdaEffect(EffectNode):
    """封裝任何 (g,f,t,S) -> (ch,co) 函式。"""
    def __init__(self, fn)

class ConditionalEffect(EffectNode):
    """根據音訊特徵切換效果。"""
    def __init__(self, condition, if_true, if_false=None)
```

### 數值場生成器 (原子構建塊)

這些生成器會產生 [0,1] 範圍內的 float32 陣列 `(rows, cols)`。它們是原始的視覺圖案。所有生成器的簽章均為 `(g, f, t, S, **params) -> float32 陣列`。

#### 三角函式場 (基於正弦/餘弦)

```python
def vf_sinefield(g, f, t, S, bri=0.5,
                 freq=(0.13, 0.17, 0.07, 0.09), speed=(0.5, -0.4, -0.3, 0.2)):
    """分層正弦場。通用背景/紋理。"""
    v1 = np.sin(g.cc*freq[0] + t*speed[0]) * np.sin(g.rr*freq[1] - t*speed[1]) * 0.5 + 0.5
    v2 = np.sin(g.cc*freq[2] - t*speed[2] + g.rr*freq[3]) * 0.4 + 0.5
    v3 = np.sin(g.dist_n*5 + t*0.2) * 0.3 + 0.4
    return np.clip((v1*0.35 + v2*0.35 + v3*0.3) * bri * (0.6 + f.get("rms",0.3)*0.6), 0, 1)

def vf_smooth_noise(g, f, t, S, octaves=3, bri=0.5):
    """Perlin 雜訊的多倍頻正弦逼近。"""
    val = np.zeros((g.rows, g.cols), dtype=np.float32)
    for i in range(octaves):
        freq = 0.05 * (2 ** i); amp = 0.5 / (i + 1)
        phase = t * (0.3 + i * 0.2)
        val = val + np.sin(g.cc*freq + phase) * np.cos(g.rr*freq*0.7 - phase*0.5) * amp
    return np.clip(val * 0.5 + 0.5, 0, 1) * bri

def vf_rings(g, f, t, S, n_base=6, spacing_base=4):
    """同心圓環，由低音驅動數量和晃動。"""
    n = int(n_base + f.get("sub_r",0.3)*25 + f.get("bass",0.3)*10)
    sp = spacing_base + f.get("bass_r",0.3)*7 + f.get("rms",0.3)*3
    val = np.zeros((g.rows, g.cols), dtype=np.float32)
    for ri in range(n):
        rad = (ri+1)*sp + f.get("bdecay",0)*15
        wobble = f.get("mid_r",0.3)*5*np.sin(g.angle*3+t*4)
        rd = np.abs(g.dist - rad - wobble)
        th = 1 + f.get("sub",0.3)*3
        val = np.maximum(val, np.clip((1 - rd/th) * (0.4 + f.get("bass",0.3)*0.8), 0, 1))
    return val

def vf_spiral(g, f, t, S, n_arms=3, tightness=2.5):
    """對數螺旋臂。"""
    val = np.zeros((g.rows, g.cols), dtype=np.float32)
    for ai in range(n_arms):
        offset = ai * 2*np.pi / n_arms
        log_r = np.log(g.dist + 1) * tightness
        arm_phase = g.angle + offset - log_r + t * 0.8
        arm_val = np.clip(np.cos(arm_phase * n_arms) * 0.6 + 0.2, 0, 1)
        arm_val *= (0.4 + f.get("rms",0.3)*0.6) * np.clip(1 - g.dist_n*0.5, 0.2, 1)
        val = np.maximum(val, arm_val)
    return val

def vf_tunnel(g, f, t, S, speed=3.0, complexity=6):
    """隧道深度效果 —— 無限縮放感。"""
    tunnel_d = 1.0 / (g.dist_n + 0.1)
    v1 = np.sin(tunnel_d*2 - t*speed) * 0.45 + 0.55
    v2 = np.sin(g.angle*complexity + tunnel_d*1.5 - t*2) * 0.35 + 0.55
    return np.clip(v1*0.5 + v2*0.5, 0, 1)

def vf_vortex(g, f, t, S, twist=3.0):
    """扭曲的放射狀圖案 —— 距離調變角度。"""
    twisted = g.angle + g.dist_n * twist * np.sin(t * 0.5)
    val = np.sin(twisted * 4 - t * 2) * 0.5 + 0.5
    return np.clip(val * (0.5 + f.get("bass",0.3)*0.8), 0, 1)

def vf_interference(g, f, t, S, n_waves=6):
    """產生莫列波紋的重疊正弦波。"""
    drivers = ["mid_r", "himid_r", "bass_r", "lomid_r", "hi_r", "sub_r"]
    vals = np.zeros((g.rows, g.cols), dtype=np.float32)
    for i in range(min(n_waves, len(drivers))):
        angle = i * np.pi / n_waves
        freq = 0.06 + i * 0.03; sp = 0.5 + i * 0.3
        proj = g.cc * np.cos(angle) + g.rr * np.sin(angle)
        vals = vals + np.sin(proj*freq + t*sp) * f.get(drivers[i], 0.3) * 2.5
    return np.clip(vals * 0.12 + 0.45, 0.1, 1)

def vf_aurora(g, f, t, S, n_bands=3):
    """水平極光帶。"""
    val = np.zeros((g.rows, g.cols), dtype=np.float32)
    for i in range(n_bands):
        fr = 0.08 + i*0.04; fc = 0.012 + i*0.008
        sr = 0.7 + i*0.3; sc = 0.18 + i*0.12
        val = val + np.sin(g.rr*fr + t*sr) * np.sin(g.cc*fc + t*sc) * (0.6/n_bands)
    return np.clip(val * (f.get("lomid_r",0.3)*3 + 0.2), 0, 0.7)

def vf_ripple(g, f, t, S, sources=None, freq=0.3, damping=0.02):
    """來自點源的同心波紋。"""
    if sources is None: sources = [(0.5, 0.5)]
    val = np.zeros((g.rows, g.cols), dtype=np.float32)
    for ry, rx in sources:
        dy = g.rr - g.rows*ry; dx = g.cc - g.cols*rx
        d = np.sqrt(dy**2 + dx**2)
        val = val + np.sin(d*freq - t*4) * np.exp(-d*damping) * 0.5
    return np.clip(val + 0.5, 0, 1)

def vf_plasma(g, f, t, S):
    """經典電漿：不同方向與速度的正弦波總和。"""
    v = np.sin(g.cc * 0.03 + t * 0.7) * 0.5
    v = v + np.sin(g.rr * 0.04 - t * 0.5) * 0.4
    v = v + np.sin((g.cc * 0.02 + g.rr * 0.03) + t * 0.3) * 0.3
    v = v + np.sin(g.dist_n * 4 - t * 0.8) * 0.3
    return np.clip(v * 0.5 + 0.5, 0, 1)

def vf_diamond(g, f, t, S, freq=0.15):
    """菱形 / 棋盤格圖案。"""
    val = np.abs(np.sin(g.cc * freq + t * 0.5)) * np.abs(np.sin(g.rr * freq * 1.2 - t * 0.3))
    return np.clip(val * (0.6 + f.get("rms",0.3)*0.8), 0, 1)

def vf_noise_static(g, f, t, S, density=0.4):
    """隨機靜電雜訊 —— 每格都不同。非確定性。"""
    return np.random.random((g.rows, g.cols)).astype(np.float32) * density * (0.5 + f.get("rms",0.3)*0.5)
```

#### 雜訊型場 (Noise-Based Fields，有機且非週期性)

這些生成器產生的紋理與三角函式場有本質上的不同 —— 它們是有機的、不重複的，且沒有明顯的軸向對齊。它們是高階生成藝術的基石。

```python
def _hash2d(ix, iy):
    """用於梯度雜訊的整數座標雜湊。返回 [0,1] 範圍內的 float32。"""
    # 透過大質數混合實現的高品質雜湊
    n = ix * 374761393 + iy * 668265263
    n = (n ^ (n >> 13)) * 1274126177
    return ((n ^ (n >> 16)) & 0x7fffffff).astype(np.float32) / 0x7fffffff

def _smoothstep(t):
    """Hermite 緩動：3t^2 - 2t^3。在 [0,1] 區間平滑內插。"""
    t = np.clip(t, 0, 1)
    return t * t * (3 - 2 * t)

def _smootherstep(t):
    """Perlin 改進版緩動：6t^5 - 15t^4 + 10t^3。C2 連續。"""
    t = np.clip(t, 0, 1)
    return t * t * t * (t * (t * 6 - 15) + 10)

def _value_noise_2d(x, y):
    """在任意浮點座標處的 2D 數值雜訊。返回 [0,1] 範圍內的 float32。
    x, y: 形狀相同的 float32 陣列。"""
    ix = np.floor(x).astype(np.int64)
    iy = np.floor(y).astype(np.int64)
    fx = _smootherstep(x - ix)
    fy = _smootherstep(y - iy)
    # 4 個角落的雜湊值
    n00 = _hash2d(ix, iy)
    n10 = _hash2d(ix + 1, iy)
    n01 = _hash2d(ix, iy + 1)
    n11 = _hash2d(ix + 1, iy + 1)
    # 雙線性內插
    nx0 = n00 * (1 - fx) + n10 * fx
    nx1 = n01 * (1 - fx) + n11 * fx
    return nx0 * (1 - fy) + nx1 * fy

def vf_noise(g, f, t, S, freq=0.08, speed=0.3, bri=0.7):
    """數值雜訊。平滑、有機，無軸向對齊瑕疵。
    freq: 空間頻率 (越高則細節越精細)。
    speed: 時間滾動速率。"""
    x = g.cc * freq + t * speed
    y = g.rr * freq * 0.8 - t * speed * 0.4
    return np.clip(_value_noise_2d(x, y) * bri, 0, 1)

def vf_fbm(g, f, t, S, octaves=5, freq=0.06, lacunarity=2.0, gain=0.5,
           speed=0.2, bri=0.8):
    """分形布朗運動 (Fractal Brownian Motion) —— 具有倍頻/增益控制的倍頻雜訊。
    用於雲朵、地形、煙霧、有機紋理的標準構建塊。

    octaves: 雜訊層數 (越多則細節越精細，開銷也越大)
    freq: 基礎空間頻率
    lacunarity: 每一倍頻的頻率乘數 (標準為 2.0)
    gain: 每一倍頻的振幅乘數 (標準為 0.5, <0.5 則更平滑)
    speed: 時間演化速率
    """
    val = np.zeros((g.rows, g.cols), dtype=np.float32)
    amplitude = 1.0
    f_x = freq
    f_y = freq * 0.85  # 輕微的各向異性可避免網格瑕疵
    for i in range(octaves):
        phase = t * speed * (1 + i * 0.3)
        x = g.cc * f_x + phase + i * 17.3  # 每倍頻的偏移量
        y = g.rr * f_y - phase * 0.6 + i * 31.7
        val = val + _value_noise_2d(x, y) * amplitude
        amplitude *= gain
        f_x *= lacunarity
        f_y *= lacunarity
    # 歸一化至 [0,1]
    max_amp = (1 - gain ** octaves) / (1 - gain) if gain != 1 else octaves
    return np.clip(val / max_amp * bri * (0.6 + f.get("rms", 0.3) * 0.6), 0, 1)

def vf_domain_warp(g, f, t, S, base_fn=None, warp_fn=None,
                   warp_strength=15.0, freq=0.06, speed=0.2):
    """域扭曲 (Domain warping) —— 將一個雜訊場的輸出作為座標偏移量饋送給另一個雜訊場。
    產生流動、融化的有機畸變效果。高階生成藝術的招牌技術 (Inigo Quilez)。

    base_fn: 要扭曲的基礎數值場 (預設為 fbm)
    warp_fn: 用於位移的數值場 (預設為不同頻率的雜訊)
    warp_strength: 位移多少個網格單元 (越高則扭曲越劇烈)
    """
    # 扭曲場：x 與 y 方向的位移
    wx = _value_noise_2d(g.cc * freq * 1.3 + t * speed, g.rr * freq + 7.1)
    wy = _value_noise_2d(g.cc * freq + t * speed * 0.7 + 3.2, g.rr * freq * 1.1 - 11.8)
    # 將扭曲中心點設在 0 (雜訊返回 [0,1]，偏移至 [-0.5, 0.5])
    wx = (wx - 0.5) * warp_strength * (0.5 + f.get("rms", 0.3) * 1.0)
    wy = (wy - 0.5) * warp_strength * (0.5 + f.get("bass", 0.3) * 0.8)
    # 在扭曲後的座標處取樣基礎場
    warped_cc = g.cc + wx
    warped_rr = g.rr + wy
    if base_fn is not None:
        # 建立一個帶有扭曲座標的臨時網格類物件
        # 簡化作法：使用修改後的座標評估 base_fn
        val = _value_noise_2d(warped_cc * freq * 0.8 + t * speed * 0.5,
                              warped_rr * freq * 0.7 - t * speed * 0.3)
    else:
        # 預設：在扭曲座標處評估 fbm
        val = np.zeros((g.rows, g.cols), dtype=np.float32)
        amp = 1.0
        fx, fy = freq * 0.8, freq * 0.7
        for i in range(4):
            val = val + _value_noise_2d(warped_cc * fx + t * speed * 0.5 + i * 13.7,
                                        warped_rr * fy - t * speed * 0.3 + i * 27.3) * amp
            amp *= 0.5; fx *= 2.0; fy *= 2.0
        val = val / 1.875  # 歸一化 4 倍頻之和
    return np.clip(val * 0.8, 0, 1)

def vf_voronoi(g, f, t, S, n_cells=20, speed=0.3, edge_width=1.5,
               mode="distance", seed=42):
    """Voronoi 圖作為數值場。使用最近/次近距離的正確實作，用於細胞內部與邊緣。

    mode: "distance" (中心亮，邊緣暗),
          "edge" (細胞邊界亮),
          "cell_id" (每個細胞單一顏色 —— 搭配離散調色盤使用)
    edge_width: 邊緣高光的粗細 (用於 "edge" 模式)
    """
    rng = np.random.RandomState(seed)
    # 動畫化細胞中心
    cx = rng.rand(n_cells).astype(np.float32) * g.cols
    cy = rng.rand(n_cells).astype(np.float32) * g.rows
    vx = (rng.rand(n_cells).astype(np.float32) - 0.5) * speed * 10
    vy = (rng.rand(n_cells).astype(np.float32) - 0.5) * speed * 10
    cx_t = (cx + vx * np.sin(t * 0.5 + np.arange(n_cells) * 0.8)) % g.cols
    cy_t = (cy + vy * np.cos(t * 0.4 + np.arange(n_cells) * 1.1)) % g.rows

    # 計算最近與次近距離
    d1 = np.full((g.rows, g.cols), 1e9, dtype=np.float32)
    d2 = np.full((g.rows, g.cols), 1e9, dtype=np.float32)
    id1 = np.zeros((g.rows, g.cols), dtype=np.int32)
    for i in range(n_cells):
        d = np.sqrt((g.cc - cx_t[i]) ** 2 + (g.rr - cy_t[i]) ** 2)
        mask = d < d1
        d2 = np.where(mask, d1, np.minimum(d2, d))
        id1 = np.where(mask, i, id1)
        d1 = np.minimum(d1, d)

    if mode == "edge":
        # 邊緣：d2 - d1 很小的地方
        edge_val = np.clip(1.0 - (d2 - d1) / edge_width, 0, 1)
        return edge_val * (0.5 + f.get("rms", 0.3) * 0.8)
    elif mode == "cell_id":
        # 每個細胞固定的數值
        return (id1.astype(np.float32) / n_cells) % 1.0
    else:
        # 距離：中心附近亮，邊緣暗
        max_d = g.cols * 0.15
        return np.clip(1.0 - d1 / max_d, 0, 1) * (0.5 + f.get("rms", 0.3) * 0.7)
```

#### 模擬型場 (Simulation-Based Fields，突發性且具備演化感)

這些生成器使用持久化狀態 `S` 來逐影格演化圖案。它們能產生無狀態數學公式無法達到的複雜度。

```python
def vf_reaction_diffusion(g, f, t, S, feed=0.055, kill=0.062,
                          da=1.0, db=0.5, dt=1.0, steps_per_frame=8,
                          init_mode="spots"):
    """Gray-Scott 反應擴散模型。根據 feed/kill 參數產生珊瑚、豹斑、
    有絲分裂、蠕蟲狀及迷宮圖案。

    化學物質 A 與 B 的互動：
        A + 2B → 3B  (自動催化)
        B → P        (衰減)
        feed: A 補充速率, kill: B 衰減速率
    不同的 feed/kill 比例會產生截然不同的圖案。

    預設組合 (feed, kill)：
        斑點 (Spots/dots):       (0.055, 0.062)
        蠕蟲 (Worms/stripes):    (0.046, 0.063)
        珊瑚 (Coral/branching):  (0.037, 0.060)
        有絲分裂 (Mitosis/splitting): (0.028, 0.062)
        迷宮 (Labyrinth/maze):   (0.029, 0.057)
        空洞 (Holes/negative):   (0.039, 0.058)
        混亂 (Chaos/unstable):   (0.026, 0.051)

    steps_per_frame: 每格影片影格執行的模擬步數 (越多則演化越快)
    """
    key = "rd_" + str(id(g))  # 每個網格唯一
    if key + "_a" not in S:
        # 初始化化學場
        A = np.ones((g.rows, g.cols), dtype=np.float32)
        B = np.zeros((g.rows, g.cols), dtype=np.float32)
        if init_mode == "spots":
            # 隨機種子斑點
            rng = np.random.RandomState(42)
            for _ in range(max(3, g.rows * g.cols // 200)):
                r, c = rng.randint(2, g.rows - 2), rng.randint(2, g.cols - 2)
                B[r - 1:r + 2, c - 1:c + 2] = 1.0
        elif init_mode == "center":
            cr, cc = g.rows // 2, g.cols // 2
            B[cr - 3:cr + 3, cc - 3:cc + 3] = 1.0
        elif init_mode == "ring":
            mask = (g.dist_n > 0.2) & (g.dist_n < 0.3)
            B[mask] = 1.0
        S[key + "_a"] = A
        S[key + "_b"] = B

    A = S[key + "_a"]
    B = S[key + "_b"]

    # 音訊調變：feed/kill 隨音訊輕微偏移
    f_mod = feed + f.get("bass", 0.3) * 0.003
    k_mod = kill + f.get("hi_r", 0.3) * 0.002

    for _ in range(steps_per_frame):
        # 透過 3x3 卷積核計算拉普拉斯算子
        # [0.05, 0.2, 0.05]
        # [0.2, -1.0, 0.2]
        # [0.05, 0.2, 0.05]
        pA = np.pad(A, 1, mode="wrap")
        pB = np.pad(B, 1, mode="wrap")
        lapA = (pA[:-2, 1:-1] + pA[2:, 1:-1] + pA[1:-1, :-2] + pA[1:-1, 2:]) * 0.2 \
             + (pA[:-2, :-2] + pA[:-2, 2:] + pA[2:, :-2] + pA[2:, 2:]) * 0.05 \
             - A * 1.0
        lapB = (pB[:-2, 1:-1] + pB[2:, 1:-1] + pB[1:-1, :-2] + pB[1:-1, 2:]) * 0.2 \
             + (pB[:-2, :-2] + pB[:-2, 2:] + pB[2:, :-2] + pB[2:, 2:]) * 0.05 \
             - B * 1.0
        ABB = A * B * B
        A = A + (da * lapA - ABB + f_mod * (1 - A)) * dt
        B = B + (db * lapB + ABB - (f_mod + k_mod) * B) * dt
        A = np.clip(A, 0, 1)
        B = np.clip(B, 0, 1)

    S[key + "_a"] = A
    S[key + "_b"] = B
    # 輸出化學物質 B 作為數值 (可見的圖案)
    return np.clip(B * 2.0, 0, 1)

def vf_game_of_life(g, f, t, S, rule="life", birth=None, survive=None,
                    steps_per_frame=1, density=0.3, fade=0.92, seed=42):
    """具有類比淡出軌跡的生命遊戲 (Cellular Automaton)。
    網格細胞依據鄰居數量規則出生/死亡。死掉的細胞逐漸變暗而非直接變黑，從而產生幽靈軌跡。

    規則預設：
        "life":      B3/S23 (康威生命遊戲)
        "coral":    B3/S45678 (緩慢的晶體生長)
        "maze":     B3/S12345 (填充形成迷宮)
        "anneal":   B4678/S35678 (平滑的團塊)
        "day_night": B3678/S34678 (平衡的生長/衰減)
    或直接指定 birth/survive 集合：birth={3}, survive={2,3}

    fade: 死掉細胞變暗的速度 (0.9 = 長軌跡, 0.5 = 短軌跡)
    """
    presets = {
        "life":      ({3}, {2, 3}),
        "coral":     ({3}, {4, 5, 6, 7, 8}),
        "maze":      ({3}, {1, 2, 3, 4, 5}),
        "anneal":    ({4, 6, 7, 8}, {3, 5, 6, 7, 8}),
        "day_night": ({3, 6, 7, 8}, {3, 4, 6, 7, 8}),
    }
    if birth is None or survive is None:
        birth, survive = presets.get(rule, presets["life"])

    key = "gol_" + str(id(g))
    if key + "_grid" not in S:
        rng = np.random.RandomState(seed)
        S[key + "_grid"] = (rng.random((g.rows, g.cols)) < density).astype(np.float32)
        S[key + "_display"] = S[key + "_grid"].copy()

    grid = S[key + "_grid"]
    display = S[key + "_display"]

    # 節拍可注入隨機雜訊
    if f.get("beat", 0) > 0.5:
        inject = np.random.random((g.rows, g.cols)) < 0.02
        grid = np.clip(grid + inject.astype(np.float32), 0, 1)

    for _ in range(steps_per_frame):
        # 計算鄰居數量 (環繞佈局)
        padded = np.pad(grid > 0.5, 1, mode="wrap").astype(np.int8)
        neighbors = (padded[:-2, :-2] + padded[:-2, 1:-1] + padded[:-2, 2:] +
                     padded[1:-1, :-2] +                     padded[1:-1, 2:] +
                     padded[2:, :-2]  + padded[2:, 1:-1]  + padded[2:, 2:])
        alive = grid > 0.5
        new_alive = np.zeros_like(grid, dtype=bool)
        for b in birth:
            new_alive |= (~alive) & (neighbors == b)
        for s in survive:
            new_alive |= alive & (neighbors == s)
        grid = new_alive.astype(np.float32)

    # 類比顯示：活細胞 = 1.0, 死細胞淡出
    display = np.where(grid > 0.5, 1.0, display * fade)
    S[key + "_grid"] = grid
    S[key + "_display"] = display
    return np.clip(display, 0, 1)

def vf_strange_attractor(g, f, t, S, attractor="clifford",
                         n_points=50000, warmup=500, bri=0.8, seed=42,
                         params=None):
    """投影到 2D 密度場的奇異吸引子。
    將 N 個點透過吸引子方程迭代，映射到網格並產生密度圖。呈現優雅且不重複的曲線。

    吸引子預設：
        "clifford":  sin(a*y) + c*cos(a*x), sin(b*x) + d*cos(b*y)
        "de_jong":   sin(a*y) - cos(b*x), sin(c*x) - cos(d*y)
        "bedhead":   sin(x*y/b) + cos(a*x - y), x*sin(a*y) + cos(b*x - y)

    params: (a, b, c, d) float 元組 — 每個吸引子有不同的視覺最佳點。
            若為 None, 則使用隨時間變化的預設值以實現動畫化。
    """
    key = "attr_" + attractor
    if params is None:
        # 隨時間緩慢變形的參數
        a = -1.4 + np.sin(t * 0.05) * 0.3
        b = 1.6 + np.cos(t * 0.07) * 0.2
        c = 1.0 + np.sin(t * 0.03 + 1) * 0.3
        d = 0.7 + np.cos(t * 0.04 + 2) * 0.2
    else:
        a, b, c, d = params

    # 迭代吸引子
    rng = np.random.RandomState(seed)
    x = rng.uniform(-0.1, 0.1, n_points).astype(np.float64)
    y = rng.uniform(-0.1, 0.1, n_points).astype(np.float64)

    # 暖身迭代 (達到吸引子狀態)
    for _ in range(warmup):
        if attractor == "clifford":
            xn = np.sin(a * y) + c * np.cos(a * x)
            yn = np.sin(b * x) + d * np.cos(b * y)
        elif attractor == "de_jong":
            xn = np.sin(a * y) - np.cos(b * x)
            yn = np.sin(c * x) - np.cos(d * y)
        elif attractor == "bedhead":
            xn = np.sin(x * y / b) + np.cos(a * x - y)
            yn = x * np.sin(a * y) + np.cos(b * x - y)
        else:
            xn = np.sin(a * y) + c * np.cos(a * x)
            yn = np.sin(b * x) + d * np.cos(b * y)
        x, y = xn, yn

    # 映射到網格
    # 尋找邊界
    margin = 0.1
    x_min, x_max = x.min() - margin, x.max() + margin
    y_min, y_max = y.min() - margin, y.max() + margin

    # 映射座標
    gx = ((x - x_min) / (x_max - x_min) * (g.cols - 1)).astype(np.int32)
    gy = ((y - y_min) / (y_max - y_min) * (g.rows - 1)).astype(np.int32)
    valid = (gx >= 0) & (gx < g.cols) & (gy >= 0) & (gy < g.rows)
    gx, gy = gx[valid], gy[valid]

    # 累積密度
    density = np.zeros((g.rows, g.cols), dtype=np.float32)
    np.add.at(density, (gy, gx), 1.0)

    # 對數縮放密度以增加可見度 (大多數網格點只有少數命中)
    density = np.log1p(density)
    mx = density.max()
    if mx > 0:
        density = density / mx
    return np.clip(density * bri * (0.5 + f.get("rms", 0.3) * 0.8), 0, 1)
```

#### SDF 型場 (幾何精確度)

符號距離場 (Signed Distance Fields) 能產生數學上精確的形狀。與正弦場（有機、模糊）不同，SDF 能產生硬挺的幾何邊界，且邊緣柔軟度可控。結合域扭曲，它們可以創造出「融化的幾何體」效果。

所有的 SDF 原語都返回一個**有符號距離**（內部為負，外部為正）。使用 `sdf_render()` 將其轉換為數值場。

```python
def sdf_render(dist, edge_width=1.5, invert=False):
    """將有符號距離轉換為數值場 [0,1]。
    edge_width: 控制邊界的抗鋸齒 / 柔軟度。
    invert: True = 形狀內部亮, False = 外部亮。"""
    val = 1.0 - np.clip(dist / edge_width, 0, 1) if not invert else np.clip(dist / edge_width, 0, 1)
    return np.clip(val, 0, 1)

def sdf_glow(dist, falloff=0.05):
    """將 SDF 渲染為發光輪廓 —— 邊界處最亮，向兩側淡出。"""
    return np.clip(np.exp(-np.abs(dist) * falloff), 0, 1)

# --- 原語 (Primitives) ---

def sdf_circle(g, cx_frac=0.5, cy_frac=0.5, radius=0.3):
    """圓形 SDF。cx/cy/radius 為歸一化 [0,1] 座標。"""
    dx = (g.cc / g.cols - cx_frac) * (g.cols / g.rows)  # 長寬比修正
    dy = g.rr / g.rows - cy_frac
    return np.sqrt(dx**2 + dy**2) - radius

def sdf_box(g, cx_frac=0.5, cy_frac=0.5, w=0.3, h=0.2, round_r=0.0):
    """圓角矩形 SDF。"""
    dx = np.abs(g.cc / g.cols - cx_frac) * (g.cols / g.rows) - w + round_r
    dy = np.abs(g.rr / g.rows - cy_frac) - h + round_r
    outside = np.sqrt(np.maximum(dx, 0)**2 + np.maximum(dy, 0)**2)
    inside = np.minimum(np.maximum(dx, dy), 0)
    return outside + inside - round_r

def sdf_ring(g, cx_frac=0.5, cy_frac=0.5, radius=0.3, thickness=0.03):
    """圓環 (Annulus) SDF。"""
    d = sdf_circle(g, cx_frac, cy_frac, radius)
    return np.abs(d) - thickness

def sdf_line(g, x0=0.2, y0=0.5, x1=0.8, y1=0.5, thickness=0.01):
    """兩點間線段的 SDF (歸一化座標)。"""
    ax = g.cc / g.cols * (g.cols / g.rows) - x0 * (g.cols / g.rows)
    ay = g.rr / g.rows - y0
    bx = (x1 - x0) * (g.cols / g.rows)
    by = y1 - y0
    h = np.clip((ax * bx + ay * by) / (bx * bx + by * by + 1e-10), 0, 1)
    dx = ax - bx * h
    dy = ay - by * h
    return np.sqrt(dx**2 + dy**2) - thickness

def sdf_triangle(g, cx=0.5, cy=0.5, size=0.25):
    """置中於 (cx, cy) 的等邊三角形 SDF。"""
    px = (g.cc / g.cols - cx) * (g.cols / g.rows) / size
    py = (g.rr / g.rows - cy) / size
    # 等邊三角形數學公式
    k = np.sqrt(3.0)
    px = np.abs(px) - 1.0
    py = py + 1.0 / k
    cond = px + k * py > 0
    px2 = np.where(cond, (px - k * py) / 2.0, px)
    py2 = np.where(cond, (-k * px - py) / 2.0, py)
    px2 = np.clip(px2, -2.0, 0.0)
    return -np.sqrt(px2**2 + py2**2) * np.sign(py2) * size

def sdf_star(g, cx=0.5, cy=0.5, n_points=5, outer_r=0.25, inner_r=0.12):
    """星形多邊形 SDF — n 角星。"""
    px = (g.cc / g.cols - cx) * (g.cols / g.rows)
    py = g.rr / g.rows - cy
    angle = np.arctan2(py, px)
    dist = np.sqrt(px**2 + py**2)
    # 用於星形對稱的模角
    wedge = 2 * np.pi / n_points
    a = np.abs((angle % wedge) - wedge / 2)
    # 在內外半徑間插值
    r_at_angle = inner_r + (outer_r - inner_r) * np.clip(np.cos(a * n_points) * 0.5 + 0.5, 0, 1)
    return dist - r_at_angle

def sdf_heart(g, cx=0.5, cy=0.45, size=0.25):
    """心形 SDF。"""
    px = (g.cc / g.cols - cx) * (g.cols / g.rows) / size
    py = -(g.rr / g.rows - cy) / size + 0.3  # 翻轉 y 並偏移
    px = np.abs(px)
    cond = (px + py) > 1.0
    d1 = np.sqrt((px - 0.25)**2 + (py - 0.75)**2) - np.sqrt(2.0) / 4.0
    d2 = np.sqrt((px + py - 1.0)**2) / np.sqrt(2.0)
    return np.where(cond, d1, d2) * size

# --- 組合器 (Combinators) ---

def sdf_union(d1, d2):
    """布林聯集 (OR) — 形狀存在於任一 SDF 的內部。"""
    return np.minimum(d1, d2)

def sdf_intersect(d1, d2):
    """布林交集 (AND) — 形狀存在於兩個 SDF 重疊處。"""
    return np.maximum(d1, d2)

def sdf_subtract(d1, d2):
    """布林差集 — d1 減去 d2。"""
    return np.maximum(d1, -d2)

def sdf_smooth_union(d1, d2, k=0.1):
    """平滑最小值 (多項式) — 混合形狀並帶有圓角連接。
    k: 平滑半徑。越高則圓角越明顯。"""
    h = np.clip(0.5 + 0.5 * (d2 - d1) / k, 0, 1)
    return d2 * (1 - h) + d1 * h - k * h * (1 - h)

def sdf_smooth_subtract(d1, d2, k=0.1):
    """平滑差集 — d1 減去 d2 並帶有圓角邊緣。"""
    return sdf_smooth_union(d1, -d2, k)

def sdf_repeat(g, sdf_fn, spacing_x=0.25, spacing_y=0.25, **sdf_kwargs):
    """無限平鋪一個 SDF 原語。spacing 為歸一化座標。"""
    # 模數座標
    mod_cc = (g.cc / g.cols) % spacing_x - spacing_x / 2
    mod_rr = (g.rr / g.rows) % spacing_y - spacing_y / 2
    # 建立一個帶有修改後座標的臨時網格類物件
    class ModGrid:
        pass
    mg = ModGrid()
    mg.cc = mod_cc * g.cols; mg.rr = mod_rr * g.rows
    mg.cols = g.cols; mg.rows = g.rows
    return sdf_fn(mg, **sdf_kwargs)

# --- 將 SDF 作為數值場 ---

def vf_sdf(g, f, t, S, sdf_fn=sdf_circle, edge_width=1.5, glow=False,
           glow_falloff=0.03, animate=True, **sdf_kwargs):
    """將任何 SDF 原語封裝為標準的 vf_* 數值場。
    若 animate=True，則對形狀應用緩慢的旋轉與呼吸效果。"""
    if animate:
        sdf_kwargs.setdefault("cx_frac", 0.5)
        sdf_kwargs.setdefault("cy_frac", 0.5)
    d = sdf_fn(g, **sdf_kwargs)
    if glow:
        return sdf_glow(d, glow_falloff) * (0.5 + f.get("rms", 0.3) * 0.8)
    return sdf_render(d, edge_width) * (0.5 + f.get("rms", 0.3) * 0.8)
```

### 色調場生成器 (色彩映射)

這些生成器產生 [0,1] 範圍內的 float32 色調陣列。可獨立與任何數值場組合。每個生成器都是一個工廠函式，返回簽章為 `(g, f, t, S) -> float32 陣列` 的閉包。也可以是固定的 float 數值以代表單一色調。

```python
def hf_fixed(hue):
    """處處皆為單一色調。"""
    def fn(g, f, t, S):
        return np.full((g.rows, g.cols), hue, dtype=np.float32)
    return fn

def hf_angle(offset=0.0):
    """色調映射至中心角度 —— 彩虹輪。"""
    def fn(g, f, t, S):
        return (g.angle / (2 * np.pi) + offset + t * 0.05) % 1.0
    return fn

def hf_distance(base=0.5, scale=0.02):
    """色調映射至中心距離。"""
    def fn(g, f, t, S):
        return (base + g.dist * scale + t * 0.03) % 1.0
    return fn

def hf_time_cycle(speed=0.1):
    """色調隨時間均勻循環。"""
    def fn(g, f, t, S):
        return np.full((g.rows, g.cols), (t * speed) % 1.0, dtype=np.float32)
    return fn

def hf_audio_cent():
    """色調追隨頻譜質心 —— 隨音色變化的色彩。"""
    def fn(g, f, t, S):
        return np.full((g.rows, g.cols), f.get("cent", 0.5) * 0.3, dtype=np.float32)
    return fn

def hf_gradient_h(start=0.0, end=1.0):
    """由左至右的色調漸層。"""
    def fn(g, f, t, S):
        h = np.broadcast_to(
            start + (g.cc / g.cols) * (end - start),
            (g.rows, g.cols)
        ).copy()  # .copy() 至關重要 — 參見 troubleshooting.md
        return h % 1.0
    return fn

def hf_gradient_v(start=0.0, end=1.0):
    """由上至下的色調漸層。"""
    def fn(g, f, t, S):
        h = np.broadcast_to(
            start + (g.rr / g.rows) * (end - start),
            (g.rows, g.cols)
        ).copy()
        return h % 1.0
    return fn

def hf_plasma(speed=0.3):
    """電漿風格的色調場 —— 有機色彩變化。"""
    def fn(g, f, t, S):
        return (np.sin(g.cc*0.02 + t*speed)*0.5 + np.sin(g.rr*0.015 + t*speed*0.7)*0.5) % 1.0
    return fn
```

---

## 座標變換 (Coordinate Transforms)

在效果評估**之前**應用的 UV 空間變換。透過變換數值場所看到的網格座標，任何 `vf_*` 函式都可以被旋轉、縮放、平鋪或扭曲。

### 變換輔助函式

```python
def uv_rotate(g, angle):
    """圍繞網格中心旋轉 UV 座標。
    返回 (rotated_cc, rotated_rr) 陣列 — 用於替代 g.cc, g.rr。"""
    cx, cy = g.cols / 2.0, g.rows / 2.0
    cos_a, sin_a = np.cos(angle), np.sin(angle)
    dx = g.cc - cx
    dy = g.rr - cy
    return cx + dx * cos_a - dy * sin_a, cy + dx * sin_a + dy * cos_a

def uv_scale(g, sx=1.0, sy=1.0, cx_frac=0.5, cy_frac=0.5):
    """圍繞中心點縮放 UV 座標。
    sx, sy > 1 = 放大 (重複次數減少), < 1 = 縮小 (重複次數增加)。"""
    cx = g.cols * cx_frac; cy = g.rows * cy_frac
    return cx + (g.cc - cx) / sx, cy + (g.rr - cy) / sy

def uv_skew(g, kx=0.0, ky=0.0):
    """傾斜 UV 座標。kx 為水平剪切，ky 為垂直剪切。"""
    return g.cc + g.rr * kx, g.rr + g.cc * ky

def uv_tile(g, nx=3.0, ny=3.0, mirror=False):
    """平鋪 UV 座標。nx, ny 為重複次數。
    mirror=True: 交替平鋪進行翻轉 (無縫拼接)。"""
    u = (g.cc / g.cols * nx) % 1.0
    v = (g.rr / g.rows * ny) % 1.0
    if mirror:
        flip_u = ((g.cc / g.cols * nx).astype(int) % 2) == 1
        flip_v = ((g.rr / g.rows * ny).astype(int) % 2) == 1
        u = np.where(flip_u, 1.0 - u, u)
        v = np.where(flip_v, 1.0 - v, v)
    return u * g.cols, v * g.rows

def uv_polar(g):
    """將笛卡爾座標轉換為極座標 UV。返回 (以 angle 為 cc, 以 dist 為 rr)。
    用於將任何線性效果變為放射狀。"""
    # 角度環繞 [0, cols), 距離環繞 [0, rows)
    return g.angle / (2 * np.pi) * g.cols, g.dist_n * g.rows

def uv_cartesian_from_polar(g):
    """將以極座標定址的效果轉回笛卡爾座標。
    將 g.cc 視為角度，g.rr 視為半徑。"""
    angle = g.cc / g.cols * 2 * np.pi
    radius = g.rr / g.rows
    cx, cy = g.cols / 2.0, g.rows / 2.0
    return cx + radius * np.cos(angle) * cx, cy + radius * np.sin(angle) * cy

def uv_twist(g, amount=2.0):
    """扭曲 (Twist)：旋轉量隨距離增加。產生螺旋畸變。"""
    twist_angle = g.dist_n * amount
    return uv_rotate_raw(g.cc, g.rr, g.cols / 2, g.rows / 2, twist_angle)

def uv_rotate_raw(cc, rr, cx, cy, angle):
    """對任意座標陣列執行原始旋轉。"""
    cos_a, sin_a = np.cos(angle), np.sin(angle)
    dx = cc - cx; dy = rr - cy
    return cx + dx * cos_a - dy * sin_a, cy + dx * sin_a + dy * cos_a

def uv_fisheye(g, strength=1.5):
    """對 UV 座標應用魚眼 / 桶形畸變。"""
    cx, cy = g.cols / 2.0, g.rows / 2.0
    dx = (g.cc - cx) / cx
    dy = (g.rr - cy) / cy
    r = np.sqrt(dx**2 + dy**2)
    r_distort = np.power(r, strength)
    scale = np.where(r > 0, r_distort / (r + 1e-10), 1.0)
    return cx + dx * scale * cx, cy + dy * scale * cy

def uv_wave(g, t, freq=0.1, amp=3.0, axis="x"):
    """正弦曲線座標位移。使 UV 空間產生晃動感。"""
    if axis == "x":
        return g.cc + np.sin(g.rr * freq + t * 3) * amp, g.rr
    else:
        return g.cc, g.rr + np.sin(g.cc * freq + t * 3) * amp

def uv_mobius(g, a=1.0, b=0.0, c=0.0, d=1.0):
    """莫比烏斯變換 (共形映射)：f(z) = (az + b) / (cz + d)。
    在複數平面上運作。產生數學上精確且視覺衝擊強烈的反演與圓形變換。"""
    cx, cy = g.cols / 2.0, g.rows / 2.0
    # 將網格映射到複數平面 [-1, 1]
    zr = (g.cc - cx) / cx
    zi = (g.rr - cy) / cy
    # 複數除法：(a*z + b) / (c*z + d)
    num_r = a * zr - 0 * zi + b  # 實數參數下 a,b,c,d 的虛部為 0
    num_i = a * zi + 0 * zr + 0
    den_r = c * zr - 0 * zi + d
    den_i = c * zi + 0 * zr + 0
    denom = den_r**2 + den_i**2 + 1e-10
    wr = (num_r * den_r + num_i * den_i) / denom
    wi = (num_i * den_r - num_r * den_i) / denom
    return cx + wr * cx, cy + wi * cy
```

### 對數值場使用變換

變換會修改數值場所看到的座標。將變換封裝在 `vf_*` 調用周圍：

```python
# 將電漿場旋轉 45 度
def vf_rotated_plasma(g, f, t, S):
    rc, rr = uv_rotate(g, np.pi / 4 + t * 0.1)
    class TG:  # 變換後的網格 (transformed grid)
        pass
    tg = TG(); tg.cc = rc; tg.rr = rr
    tg.rows = g.rows; tg.cols = g.cols
    tg.dist_n = g.dist_n; tg.angle = g.angle; tg.dist = g.dist
    return vf_plasma(tg, f, t, S)

# 以 3x3 鏡像平鋪渦流
def vf_tiled_vortex(g, f, t, S):
    tc, tr = uv_tile(g, 3, 3, mirror=True)
    class TG:
        pass
    tg = TG(); tg.cc = tc; tg.rr = tr
    tg.rows = g.rows; tg.cols = g.cols
    tg.dist = np.sqrt((tc - g.cols/2)**2 + (tr - g.rows/2)**2)
    tg.dist_n = tg.dist / (tg.dist.max() + 1e-10)
    tg.angle = np.arctan2(tr - g.rows/2, tc - g.cols/2)
    return vf_vortex(tg, f, t, S)

# 輔助函式：從座標陣列建立變換後的網格
def make_tgrid(g, new_cc, new_rr):
    """構建一個帶有變換座標的網格類物件。
    保留行/列數以維持尺寸，重新計算極座標。"""
    class TG:
        pass
    tg = TG()
    tg.cc = new_cc; tg.rr = new_rr
    tg.rows = g.rows; tg.cols = g.cols
    cx, cy = g.cols / 2.0, g.rows / 2.0
    dx = new_cc - cx; dy = new_rr - cy
    tg.dist = np.sqrt(dx**2 + dy**2)
    tg.dist_n = tg.dist / (max(cx, cy) + 1e-10)
    tg.angle = np.arctan2(dy, dx)
    tg.dx = dx; tg.dy = dy
    tg.dx_n = dx / max(g.cols, 1)
    tg.dy_n = dy / max(g.rows, 1)
    return tg
```

---

## 時間連貫性 (Temporal Coherence)

用於隨時間推移進行平滑且有意圖的參數演化的工具。這取代了預設的靜態參數或原始的音訊反應模式。

### 緩動函式 (Easing Functions)

標準動畫緩動曲線。所有函式均接收 [0,1] 的 `t` 並返回 [0,1]：

```python
def ease_linear(t): return t
def ease_in_quad(t): return t * t
def ease_out_quad(t): return t * (2 - t)
def ease_in_out_quad(t): return np.where(t < 0.5, 2*t*t, -1 + (4-2*t)*t)
def ease_in_cubic(t): return t**3
def ease_out_cubic(t): return (t - 1)**3 + 1
def ease_in_out_cubic(t):
    return np.where(t < 0.5, 4*t**3, 1 - (-2*t + 2)**3 / 2)
def ease_in_expo(t): return np.where(t == 0, 0, 2**(10*(t-1)))
def ease_out_expo(t): return np.where(t == 1, 1, 1 - 2**(-10*t))
def ease_elastic(t):
    """彈性緩出 —— 超出目標後回彈。"""
    return np.where(t == 0, 0, np.where(t == 1, 1,
        2**(-10*t) * np.sin((t*10 - 0.75) * (2*np.pi) / 3) + 1))
def ease_bounce(t):
    """跳躍緩出 —— 在結尾處跳動。"""
    t = np.asarray(t, dtype=np.float64)
    result = np.empty_like(t)
    m1 = t < 1/2.75
    m2 = (~m1) & (t < 2/2.75)
    m3 = (~m1) & (~m2) & (t < 2.5/2.75)
    m4 = ~(m1 | m2 | m3)
    result[m1] = 7.5625 * t[m1]**2
    t2 = t[m2] - 1.5/2.75;   result[m2] = 7.5625 * t2**2 + 0.75
    t3 = t[m3] - 2.25/2.75;  result[m3] = 7.5625 * t3**2 + 0.9375
    t4 = t[m4] - 2.625/2.75; result[m4] = 7.5625 * t4**2 + 0.984375
    return result
```

### 關鍵格插值 (Keyframe Interpolation)

定義特定時間點的參數值。在它們之間進行帶緩動的插值：

```python
def keyframe(t, points, ease_fn=ease_in_out_cubic, loop=False):
    """在關鍵格數值間進行插值。

    參數：
        t: 當前時間 (float, 秒)
        points: (時間, 數值) 元組列表，按時間排序
        ease_fn: 用於插值的緩動函式
        loop: 若為 True，則在最後一格後循環

    返回：
        時間 t 處的插值
    """
    if not points:
        return 0.0
    if loop:
        period = points[-1][0] - points[0][0]
        if period > 0:
            t = points[0][0] + (t - points[0][0]) % period

    # 範圍限制
    if t <= points[0][0]:
        return points[0][1]
    if t >= points[-1][0]:
        return points[-1][1]

    # 尋找前後關鍵格
    for i in range(len(points) - 1):
        t0, v0 = points[i]
        t1, v1 = points[i + 1]
        if t0 <= t <= t1:
            progress = (t - t0) / (t1 - t0)
            eased = ease_fn(progress)
            return v0 + (v1 - v0) * eased

    return points[-1][1]

def keyframe_array(t, points, ease_fn=ease_in_out_cubic):
    """支援 numpy 陣列作為數值的關鍵格插值。"""
    if t <= points[0][0]: return points[0][1].copy()
    if t >= points[-1][0]: return points[-1][1].copy()
    for i in range(len(points) - 1):
        t0, v0 = points[i]
        t1, v1 = points[i + 1]
        if t0 <= t <= t1:
            progress = ease_fn((t - t0) / (t1 - t0))
            return v0 * (1 - progress) + v1 * progress
    return points[-1][1].copy()
```

### 數值場變形 (Value Field Morphing)

在兩個不同的數值場之間平滑過渡：

```python
def vf_morph(g, f, t, S, vf_a, vf_b, t_start, t_end,
             ease_fn=ease_in_out_cubic):
    """在時間範圍內於兩個數值場之間變形。

    用法：
        val = vf_morph(g, f, t, S,
            lambda g,f,t,S: vf_plasma(g,f,t,S),
            lambda g,f,t,S: vf_vortex(g,f,t,S, twist=5),
            t_start=10.0, t_end=15.0)
    """
    if t <= t_start:
        return vf_a(g, f, t, S)
    if t >= t_end:
        return vf_b(g, f, t, S)
    progress = ease_fn((t - t_start) / (t_end - t_start))
    a = vf_a(g, f, t, S)
    b = vf_b(g, f, t, S)
    return a * (1 - progress) + b * progress

def vf_sequence(g, f, t, S, fields, durations, crossfade=1.0,
                ease_fn=ease_in_out_cubic):
    """循環播放一系列數值場，並帶有交叉淡化。

    fields: vf_* 可調用物件列表
    durations: 每場持續時間 (秒) 的 float 列表
    crossfade: 相鄰場之間重疊的秒數
    """
    total = sum(durations)
    t_local = t % total  # 循環
    elapsed = 0
    for i, dur in enumerate(durations):
        if t_local < elapsed + dur:
            # 當前場
            base = fields[i](g, f, t, S)
            # 檢查是否在交叉淡化區域
            time_in = t_local - elapsed
            time_left = dur - time_in
            if time_in < crossfade and i > 0:
                # 從上一場淡入
                prev = fields[(i - 1) % len(fields)](g, f, t, S)
                blend = ease_fn(time_in / crossfade)
                return prev * (1 - blend) + base * blend
            if time_left < crossfade and i < len(fields) - 1:
                # 向下一場淡出
                nxt = fields[(i + 1) % len(fields)](g, f, t, S)
                blend = ease_fn(1 - time_left / crossfade)
                return base * (1 - blend) + nxt * blend
            return base
        elapsed += dur
    return fields[-1](g, f, t, S)
```

### 時間雜訊 (Temporal Noise)

在 `(x, y, t)` 處取樣的 3D 雜訊 — 圖案在時間上平滑演化，沒有逐影格的不連續性：

```python
def vf_temporal_noise(g, f, t, S, freq=0.06, t_freq=0.3, octaves=4,
                      bri=0.8):
    """在時間上平滑演化的雜訊場。透過結合兩個 2D 雜訊查表與時間插值來實現 3D 雜訊。

    與滾動雜訊 (產生定向運動) 的 vf_fbm 不同，此函式使圖案在原地變形 ——
    網格單元變亮或變暗，而場本身不朝任何方向移動。"""
    # 在時間座標的 floor/ceil 處取樣兩個雜訊
    t_scaled = t * t_freq
    t_lo = np.floor(t_scaled)
    t_frac = _smootherstep(np.full((g.rows, g.cols), t_scaled - t_lo, dtype=np.float32))

    val_lo = np.zeros((g.rows, g.cols), dtype=np.float32)
    val_hi = np.zeros((g.rows, g.cols), dtype=np.float32)
    amp = 1.0; fx = freq
    for i in range(octaves):
        val_lo = val_lo + _value_noise_2d(
            g.cc * fx + t_lo * 7.3 + i * 13, g.rr * fx + t_lo * 3.1 + i * 29) * amp
        val_hi = val_hi + _value_noise_2d(
            g.cc * fx + (t_lo + 1) * 7.3 + i * 13, g.rr * fx + (t_lo + 1) * 3.1 + i * 29) * amp
        amp *= 0.5; fx *= 2.0
    max_amp = (1 - 0.5 ** octaves) / 0.5
    val = (val_lo * (1 - t_frac) + val_hi * t_frac) / max_amp
    return np.clip(val * bri * (0.6 + f.get("rms", 0.3) * 0.6), 0, 1)
```

---

### 組合數值場

透過數學運算混合數值場可以產生爆炸式的組合效果：

```python
# 相乘 = 交集 (僅在兩者皆亮處顯示亮度)
combined = vf_plasma(g,f,t,S) * vf_vortex(g,f,t,S)

# 相加 = 聯集 (顯示兩者，在 1.0 處剪裁)
combined = np.clip(vf_rings(g,f,t,S) + vf_spiral(g,f,t,S), 0, 1)

# 干涉 = 拍頻圖案 (顯示類 XOR 圖案)
combined = np.abs(vf_plasma(g,f,t,S) - vf_tunnel(g,f,t,S))

# 調變 = 一個效果塑造另一個效果
combined = vf_rings(g,f,t,S) * (0.3 + 0.7 * vf_plasma(g,f,t,S))

# 取最大值 = 顯示兩個效果中最亮的部分
combined = np.maximum(vf_spiral(g,f,t,S), vf_aurora(g,f,t,S))
```

### 完整場景範例 (v2 — 返回畫布)

v2 版場景函式在內部合成效果並返回像素畫布：

```python
def scene_complex(r, f, t, S):
    """v2 場景函式：返回畫布 (uint8 H,W,3)。
    r = 渲染器, f = 音訊特徵, t = 時間, S = 持久化狀態字典。"""
    g = r.grids["md"]
    rows, cols = g.rows, g.cols
    
    # 1. 數值場合成
    plasma = vf_plasma(g, f, t, S)
    vortex = vf_vortex(g, f, t, S, twist=4.0)
    combined = np.clip(plasma * 0.6 + vortex * 0.5 + plasma * vortex * 0.4, 0, 1)
    
    # 2. 來自色調場的色彩
    h = (hf_angle(0.3)(g,f,t,S) * 0.5 + hf_time_cycle(0.08)(g,f,t,S) * 0.5) % 1.0
    
    # 3. 透過 _render_vf 輔助工具渲染到畫布
    canvas = _render_vf(g, combined, h, sat=0.75, pal=PAL_DENSE)
    
    # 4. 選用：混合第二個圖層
    overlay = _render_vf(r.grids["sm"], vf_rings(r.grids["sm"],f,t,S),
                         hf_fixed(0.6)(r.grids["sm"],f,t,S), pal=PAL_BLOCK)
    canvas = blend_canvas(canvas, overlay, "screen", 0.4)
    
    return canvas
    
# 在 render_clip() 迴圈中 (由框架處理)：
# canvas = scene_fn(r, f, t, S)
# canvas = tonemap(canvas, gamma=scene_gamma)
# canvas = feedback.apply(canvas, ...)
# canvas = shader_chain.apply(canvas, f=f, t=t)
# pipe.stdin.write(canvas.tobytes())
```

為每個章節變換**數值場合成**、**色調場**、**調色盤**、**混合模式**、**回饋配置**及**著色器鏈**，以實現最大的視覺多樣性。憑藉 12 種數值場 × 8 種色調場 × 14 種調色盤 × 20 種混合模式 × 7 種回饋變換 × 38 種著色器，組合方式實際上是無限的。

---

## 組合效果 —— 創意指南

上方的目錄只是詞彙。以下是如何將它們組合成看起來「有意為之」的作品。

### 分層以增加深度
每個場景應至少具備兩個不同網格密度的圖層：
- **背景** (sm 或 xs)：密集、微暗的紋理，防止出現純黑背景。使用低亮度 (bri=0.15-0.25) 的 fBM、平滑雜訊或域扭曲。
- **內容** (md)：主要的視覺元素 — 圓環、Voronoi、螺旋、隧道。全亮度顯示。
- **強調** (lg 或 xl)：稀疏的高光層 — 粒子、文字模板、發光脈衝。使用 Screen 模式疊加在最上方。

### 有趣的效果組合
| 組合對 | 混合模式 | 為何有效 |
|------|-------|-------------|
| fBM + Voronoi 邊緣 | `screen` | 有機內容填充細胞，邊緣增加結構感 |
| 域扭曲 + 電漿 | `difference` | 迷幻的有機干涉效果 |
| 隧道 + 渦流 | `screen` | 深度透視加上旋轉能量 |
| 螺旋 + 干涉 | `exclusion` | 來自不同空間頻率的莫列波紋圖案 |
| 反應擴散 + 火焰 | `add` | 活性的有機底層加上動態前景 |
| SDF 幾何 + 域扭曲 | `screen` | 潔淨的形狀浮動在有機紋理中 |

### 將效果作為遮罩
任何數值場都可以透過 `mask_from_vf()` 作為另一個效果的空間遮罩：
- 使用 Voronoi 細胞遮蔽火焰 (火焰僅在細胞內可見)
- 使用 fBM 遮蔽單色圖層 (有機色彩雲)
- 使用 SDF 形狀遮蔽反應擴散場
- 使用動畫光圈/擦除來揭示另一個效果

### 發明新效果
為每個專案發明至少一個不在目錄中的效果：
- **使用數學組合兩個 vf_* 函式**：`np.clip(vf_fbm(...) * vf_rings(...), 0, 1)`
- **評估前應用座標變換**：`vf_plasma(twisted_grid, ...)`
- **使用一個場來調變另一個場的參數**：`vf_spiral(..., tightness=2 + vf_fbm(...) * 5)`
- **堆疊時間偏移**：渲染 `t` 和 `t - 0.5` 時的同一個場，使用 difference 混合以實現運動軌跡
- **透過 SDF 邊界鏡像一個數值場**，以產生萬花筒般的幾何圖案
