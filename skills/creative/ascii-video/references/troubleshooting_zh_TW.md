# 疑難排解參考 (Troubleshooting Reference)

> **另請參閱：** [composition_zh_TW.md](composition_zh_TW.md) · [architecture_zh_TW.md](architecture_zh_TW.md) · [shaders_zh_TW.md](shaders_zh_TW.md) · [scenes_zh_TW.md](scenes_zh_TW.md) · [optimization_zh_TW.md](optimization_zh_TW.md)

## 快速診斷

| 徵兆 | 可能原因 | 修復方法 |
|---------|-------------|-----|
| 輸出全黑 | tonemap gamma 過高或無效果渲染 | 將 gamma 調低至 0.5，檢查 scene_fn 是否返回非零畫布 |
| 畫面過亮/泛白 | 使用線性亮度倍數而非 tonemap | 將 `canvas * N` 替換為 `tonemap(canvas, gamma=0.75)` |
| ffmpeg 渲染中途掛起 | stderr=subprocess.PIPE 導致死鎖 | 將 stderr 重新導向至檔案 |
| "read-only" 陣列錯誤 | broadcast_to 視圖未進行 .copy() | 在 broadcast_to 後加上 `.copy()` |
| PicklingError | SCENES 表中包含 Lambda 或閉包 | 在模組級別定義所有 fx_* 函式 |
| 輸出中出現隨機黑洞 | 字體缺失 Unicode 字形 | 在初始化時驗證調色盤 |
| 影音不同步 | 影格時機累計誤差 | 使用整數影格計數器，每影格重新計算 t |
| 單色扁平輸出 | 色調場 (Hue field) 形狀不匹配 | 確保 hsv2rgb 前 h,s,v 陣列均為 (rows,cols) |
| 繁忙背景下文字難讀 | 文字與背景對比度不足 | 使用 `apply_text_backdrop()` ([composition_zh_TW.md](composition_zh_TW.md)) + `reverse_vignette` 著色器 ([shaders_zh_TW.md](shaders_zh_TW.md)) |
| 文字亂碼/鏡像 | 萬花筒或鏡像著色器套用於文字場景 | **絕不要將 kaleidoscope, mirror_h/v/quad/diag 套用於包含可讀文字的場景** —— 徑向折疊會破壞可讀性。僅將這些效果套用於背景層或無文字場景 |

以下是在 ASCII 影片開發過程中常見的錯誤、陷阱及平台特定問題。

## NumPy 廣播 (Broadcasting)

### `broadcast_to().copy()` 陷阱

色調場生成器通常返回廣播視圖陣列 —— 它們的形狀為 `(1, cols)` 或 `(rows, 1)`，numpy 將其廣播至 `(rows, cols)`。這些視圖是**唯讀的**。若下游程式碼嘗試原地修改它們（例如 `h %= 1.0`），numpy 會拋出：

```
ValueError: output array is read-only
```

**修復方法**：在 `broadcast_to()` 後一律加上 `.copy()`：

```python
h = np.broadcast_to(h, (g.rows, g.cols)).copy()
```

這在 `_render_vf()` 中尤為重要，因為色調陣列會流向 `hsv2rgb()`。

### `+=` vs `+` 陷阱

當運算元形狀不完全匹配時，廣播在原地運算子下也會失敗：

```python
# 失敗：如果結果是 (rows,1) 而運算元是 (rows, cols)
val += np.sin(g.cc * 0.02 + t * 0.3) * 0.5

# 成功：建立一個新陣列
val = val + np.sin(g.cc * 0.02 + t * 0.3) * 0.5
```

`vf_plasma()` 函式曾有此錯誤。混合不同形狀的陣列時，請使用 `+` 取代 `+=`。

### `hsv2rgb()` 中的形狀不匹配

`hsv2rgb(h, s, v)` 要求三個陣列形狀完全一致。如果 `h` 是 `(1, cols)` 而 `s` 是 `(rows, cols)`，函式會崩潰或產生錯誤輸出。

**修復方法**：確保在調用前，所有輸入都已廣播並複製到 `(rows, cols)`。

---

## 混合模式陷阱

### Overlay (疊加) 壓制深色輸入

當 `a < 0.5` 時，`overlay(a, b) = 2*a*b`。兩個 0.12 的數值會產生 `2 * 0.12 * 0.12 = 0.03`。結果比任何一個輸入都暗。

**影響**：如果兩個圖層都很暗（ASCII 藝術通常如此），overlay 會產生近乎全黑的輸出。

**修復方法**：對於深色素材，請使用 `screen` (濾色)。Screen 始終會變亮：`1 - (1-a)*(1-b)`。

### Colordodge (加亮) 除以零

`colordodge(a, b) = a / (1 - b)`。當 `b = 1.0`（純白像素）時，會發生除以零的情況。

**修復方法**：加入極小值 (epsilon)：`a / (1 - b + 1e-6)`。`BLEND_MODES` 的實作應包含此項。

### Colorburn (加深) 除以零

`colorburn(a, b) = 1 - (1-a) / b`。當 `b = 0`（純黑像素）時，會發生除以零的情況。

**修復方法**：加入極小值：`1 - (1-a) / (b + 1e-6)`。

### Multiply (相乘) 始終變暗

`multiply(a, b) = a * b`。由於兩個運算元都在 [0,1] 範圍，結果始終 <= min(a,b)。絕不要將 multiply 作為回饋混合模式 —— 影格會在幾格內變黑。

**修復方法**：對回饋使用 `screen`，或使用低不透明度的 `add`。

---

## 多進程 (Multiprocessing)

### Pickling 限制

`ProcessPoolExecutor` 透過 pickle 序列化函式參數。這限制了你能傳遞給工作進程的內容：

| 支援 Pickling | 不支援 Pickling |
|-----------|---------------|
| 模組級函式 (`def fx_foo():`) | Lambda 運算式 (`lambda x: x + 1`) |
| 字典、列表、numpy 陣列 | 閉包 (函式內部定義的函式) |
| 類別實例 (具備 `__reduce__`) | 實例方法 |
| 字串、數字 | 檔案控制代碼、socket |

**影響**：SCENES 表中引用的所有場景函式必須使用 `def` 定義在模組級別。若使用 lambda 或閉包，會報錯：

```
_pickle.PicklingError: Can't pickle <function <lambda> at 0x...>
```

**修復方法**：在模組最上層定義所有場景函式。在 `_render_vf()` 內部作為 val_fn/hue_fn 使用的 lambda 是沒問題的，因為它們是在工作進程內部執行的 —— 它們不會被跨進程邊界序列化。

### macOS spawn vs Linux fork

在 macOS 上，`multiprocessing` 預設使用 `spawn`（完全序列化）。在 Linux 上，預設使用 `fork`（寫入時複製）。這意味著：

- **macOS**：特徵陣列會為每個工作進程序列化一份（30 秒影片約 57KB，但隨時長增加）。每個工作進程都會重新匯入整個模組。
- **Linux**：特徵陣列透過 COW 共享。工作進程繼承父進程的記憶體。

**影響**：在 macOS 上，模組級程式碼（如 `detect_hardware()`）會在每個工作進程中執行。若其有副作用（如子進程調用），則會執行 N+1 次。

### 每進程狀態隔離

每個工作進程都會建立各自的：
- `Renderer` 實例（帶有全新的網格快取）
- `FeedbackBuffer`（回饋效果不跨越場景邊界）
- 隨機種子 (`random.seed(hash(seg_id) + 42)`)

這意味著：
- 粒子狀態不會在場景間延續（符合預期）
- 回饋軌跡在場景切換時重置（符合預期）
- `np.random` 狀態**不**受 `random.seed()` 影響 —— 它們使用不同的 RNG

**確定性雜訊的修復方法**：明確使用 `np.random.RandomState(seed)`：

```python
rng = np.random.RandomState(hash(seg_id) + 42)
noise = rng.random((rows, cols))
```

---

## 亮度問題

### Tonemap 後場景依然昏暗

若 tonemap 後場景仍暗，請檢查：

1. **Gamma 過高**：對於包含破壞性後處理的場景，調低 gamma (0.5-0.6)。
2. **著色器摧毀亮度**：著色器鏈中的 Solarize, posterize 或對比度調整可能會抵消 tonemap 的效果。將破壞性著色器移到鏈條前端，或增加 gamma 進行補償。
3. **回饋使用了 multiply**：Multiply 回饋會讓每一影格變暗。切換至 screen 或 add。
4. **場景中的 Overlay 混合**：若場景函式對深色圖層使用 `blend_canvas(..., "overlay", ...)`，請切換至 screen。

### 診斷：測試影格亮度

```bash
python reel.py --test-frame 10.0
# 輸出：Mean brightness: 44.3, max: 255
```

若平均值 < 20，該場景需要調整。常見修復方法：
- 調低 SCENES 條目中的 gamma。
- 將內部混合模式從 overlay/multiply 改為 screen/add。
- 增加數值場倍數（例如 `vf_plasma(...) * 1.5`）。
- 檢查著色器鏈是否包含激進的 solarize 或 threshold。

### v1 亮度模式（已棄用）

舊模式使用線性倍數：

```python
# 舊版 —— 請勿使用
canvas = np.clip(canvas.astype(np.float32) * 2.0, 0, 255).astype(np.uint8)
```

失敗原因：
- 深色場景（平均值 8）：`8 * 2.0 = 16` —— 依然很暗。
- 明亮場景（平均值 130）：`130 * 2.0 = 255` —— 剪裁，丟失細節。

請改用 `tonemap()`。參見 `composition_zh_TW.md` § 自適應色調映射。

---

## ffmpeg 問題

### 管道死鎖 (Pipe Deadlock)

生產環境中排名第一的 bug。若你使用 `stderr=subprocess.PIPE`：

```python
# 死鎖 —— stderr 緩衝區在 64KB 時填滿，阻塞 ffmpeg，進而阻塞你的寫入
pipe = subprocess.Popen(cmd, stdin=subprocess.PIPE, stderr=subprocess.PIPE)
```

**修復方法**：一律將 stderr 重新導向至檔案：

```python
stderr_fh = open(err_path, "w")
pipe = subprocess.Popen(cmd, stdin=subprocess.PIPE,
                        stdout=subprocess.DEVNULL, stderr=stderr_fh)
```

### 影格數不匹配

若寫入管道的影格數與 ffmpeg 預期的（基於 `-r` 和時長）不符，輸出可能會：
- 結尾遺漏影格。
- 時長不正確。
- 影音不同步。

**修復方法**：明確計算影格數：`n_frames = int(duration * FPS)`。在未驗證總數匹配前，不要直接使用 `range(int(start*FPS), int(end*FPS))`。

### Concat 失敗並提示 "unsafe file name"

```
[concat @ ...] Unsafe file name
```

**修復方法**：務必使用 `-safe 0`：
```python
["ffmpeg", "-f", "concat", "-safe", "0", "-i", concat_path, ...]
```

---

## 字體問題

### 單元高度 (macOS Pillow)

在某些 macOS Pillow 版本上，`textbbox()` 和 `getbbox()` 返回的高度不正確。請使用 `getmetrics()`：

```python
ascent, descent = font.getmetrics()
cell_height = ascent + descent  # 正確
# 切勿使用：font.getbbox("M")[3]  # 在某些版本上是錯的
```

### 缺失 Unicode 字形

並非所有字體都能渲染所有 Unicode 字元。若調色盤字元不在字體中，該字形會渲染為空白或豆腐塊 (tofu)，在輸出中表現為黑洞。

**修復方法**：在初始化時進行驗證：

```python
all_chars = set()
for pal in [PAL_DEFAULT, PAL_DENSE, PAL_RUNE, ...]:
    all_chars.update(pal)

valid_chars = set()
for c in all_chars:
    if c == " ":
        valid_chars.add(c)
        continue
    img = Image.new("L", (20, 20), 0)
    ImageDraw.Draw(img).text((0, 0), c, fill=255, font=font)
    if np.array(img).max() > 0:
        valid_chars.add(c)
    else:
        log(f"警告：字體缺失字元 '{c}' (U+{ord(c):04X})")
```

### 各平台字體路徑

| 平台 | 常見路徑 |
|----------|-------------|
| macOS | `/System/Library/Fonts/Menlo.ttc`, `/System/Library/Fonts/Monaco.ttf` |
| Linux | `/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf` |
| Windows | `C:\Windows\Fonts\consola.ttf` (Consolas) |

務必探測多個路徑並提供優雅的回退方案。參見 `architecture_zh_TW.md` § 字體選擇。

---

## 效能

### 慢速著色器 (Slow Shaders)

某些著色器使用 Python 迴圈，在 1080p 下速度極慢：

| 著色器 | 問題 | 修復方法 |
|--------|-------|-----|
| `wave_distort` | 逐行 Python 迴圈 | 使用向量化的花式索引 |
| `halftone` | 三層巢狀迴圈 | 使用區塊縮減 (block reduction) 進行向量化 |
| `matrix rain` | 逐欄逐軌跡迴圈 | 累積索引陣列，進行批量賦值 |

### 渲染時間縮放

若渲染耗時遠超預期：
1. 檢查網格數量 —— 每增加一個網格，每影格初始化約增加 100-150ms。
2. 檢查粒子數量 —— 根據品質等級限制數量。
3. 檢查著色器數量 —— 每個著色器增加 2-25ms。
4. 檢查效果中是否無意中使用了 Python 迴圈（應僅限 numpy）。

---

## 常見錯誤

### 誤用 `r.S` 或 `S` 參數

v2 版場景協議將 `S` (狀態字典) 作為明確參數傳遞。但 `S` 其實就是 `r.S` —— 它們是同一個物件。兩者皆可運作：

```python
def fx_scene(r, f, t, S):
    S["counter"] = S.get("counter", 0) + 1   # 透過參數 (推薦)
    r.S["counter"] = r.S.get("counter", 0) + 1  # 透過 renderer (亦可運作)
```

為了清晰起見，建議使用 `S` 參數。明確的參數能一眼看出該函式具有持久化狀態。

### 忘記處理空特徵值

若音訊靜音，音訊特徵預設為 0.0。請使用 `.get()` 並給予合理的預設值：

```python
energy = f.get("bass", 0.3)  # 預設為 0.3 而非 0
```

若預設為 0，效果在靜音期間會變空。

### 寫入新檔案而非編輯現有狀態

粒子系統中的常見 bug：每影格都建立新陣列，而非更新持久化狀態。

```python
# 錯誤示範 —— 粒子每格都會重置
S["px"] = []
for _ in range(100):
    S["px"].append(random.random())

# 正確示範 —— 僅初始化一次，每影格更新
if "px" not in S:
    S["px"] = []
# ... 根據節拍發射新粒子
# ... 更新現有粒子
```

### 未對數值場進行剪裁 (Clipping)

數值場應在 [0, 1] 範圍內。若超出此範圍，`val2char()` 會產生索引錯誤：

```python
# 錯誤示範 —— vf_plasma() * 1.5 可能超過 1.0
val = vf_plasma(g, f, t, S) * 1.5

# 正確示範 —— 縮放後進行剪裁
val = np.clip(vf_plasma(g, f, t, S) * 1.5, 0, 1)
```

`_render_vf()` 輔助工具會自動處理剪裁，但若你是在構建自定義場景，請務必手動剪裁。

## 亮度最佳實踐

- 密集的動畫背景 —— 絕不要留白（全黑），務必填滿網格。
- 暈影 (Vignette) 最小值夾取至 0.15 (而非 0.12)。
- Bloom 閥值設為 130 (而非 170)，讓更多像素參與發光。
- 對深色 ASCII 圖層使用 `screen` 混合模式 (而非 `overlay`) —— overlay 會讓深色值平方化：`2 * 0.12 * 0.12 = 0.03`。
- FeedbackBuffer 衰減 (decay) 最小值設為 0.5 —— 低於此值回饋消失太快，肉眼難辨。
- 數值場底限：`vf * 0.8 + 0.05` 確保沒有單元是完全歸零的。
- 各場景覆寫 Gamma：預設 0.75, solarize 0.55, posterize 0.50, 明亮場景 0.85。
- 儘早測試影格：在投入完整渲染前，先渲染關鍵時間點的單個影格。

**完整渲染前的快速檢查清單：**
1. 渲染 3 個測試影格（開頭、中間、結尾）。
2. 檢查 tonemap 後的 `canvas.mean() > 8`。
3. 檢查沒有任何場景在視覺上是純黑的。
4. 驗證各段落的變化（每個場景有不同的背景/調色盤/色彩）。
5. 確認著色器鏈包含 bloom (閥值 130)。
6. 確認暈影強度 ≤ 0.25。
