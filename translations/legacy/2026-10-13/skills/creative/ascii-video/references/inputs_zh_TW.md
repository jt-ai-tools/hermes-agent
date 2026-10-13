# 輸入源 (Input Sources)

> **另請參閱：** [architecture_zh_TW.md](architecture_zh_TW.md) · [effects_zh_TW.md](effects_zh_TW.md) · [scenes_zh_TW.md](scenes_zh_TW.md) · [shaders_zh_TW.md](shaders_zh_TW.md) · [optimization_zh_TW.md](optimization_zh_TW.md) · [troubleshooting_zh_TW.md](troubleshooting_zh_TW.md)

## 音訊分析 (Audio Analysis)

### 載入音訊

```python
tmp = tempfile.mktemp(suffix=".wav")
subprocess.run(["ffmpeg", "-y", "-i", input_path, "-ac", "1", "-ar", "22050",
                "-sample_fmt", "s16", tmp], capture_output=True, check=True)
with wave.open(tmp) as wf:
    sr = wf.getframerate()
    raw = wf.readframes(wf.getnframes())
samples = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
```

### 逐影格 FFT

```python
hop = sr // fps          # 每影格樣本數
win = hop * 2            # 分析窗口（2 倍 hop 以實現重疊）
window = np.hanning(win)
freqs = rfftfreq(win, 1.0 / sr)

bands = {
    "sub":   (freqs >= 20)  & (freqs < 80),
    "bass":  (freqs >= 80)  & (freqs < 250),
    "lomid": (freqs >= 250) & (freqs < 500),
    "mid":   (freqs >= 500) & (freqs < 2000),
    "himid": (freqs >= 2000)& (freqs < 6000),
    "hi":    (freqs >= 6000),
}
```

針對每一影格：提取區塊、應用窗口、執行 FFT、計算各頻段能量。

### 特徵集 (Feature Set)

| 特徵 | 公式 | 控制項 |
|---------|---------|----------|
| `rms` | `sqrt(mean(chunk²))` | 整體音量/能量 |
| `sub`..`hi` | `sqrt(mean(band_magnitudes²))` | 各頻段能量 |
| `centroid` | `sum(freq*mag) / sum(mag)` | 亮度/音色 |
| `flatness` | `geomean(mag) / mean(mag)` | 雜訊 vs 音調 |
| `flux` | `sum(max(0, mag - prev_mag))` | 瞬態強度 (Transient strength) |
| `sub_r`..`hi_r` | `band / sum(all_bands)` | 頻譜形狀（獨立於音量） |
| `cent_d` | `abs(gradient(centroid))` | 音色變化率 |
| `beat` | Flux 峰值偵測 | 二進位節拍起始 |
| `bdecay` | 節拍後的指數衰減 | 平滑的節拍脈衝 (0→1→0) |

**頻段比例 (Band ratios) 至關重要** —— 它們將頻譜形狀與音量解耦。這樣一來，無論是在安靜的低音區段還是響亮的低音區段，系統都能識別為「低音豐富」，而非僅僅是「響亮」或「安靜」。

### 平滑處理 (Smoothing)

使用 EMA (指數移動平均) 避免視覺上的抖動：

```python
def ema(arr, alpha):
    out = np.empty_like(arr); out[0] = arr[0]
    for i in range(1, len(arr)):
        out[i] = alpha * arr[i] + (1 - alpha) * out[i-1]
    return out

# 慢速移動特徵 (alpha=0.12)：centroid, flatness, band ratios, cent_d
# 快速移動特徵 (alpha=0.3)：rms, flux, raw bands
```

### 節拍偵測 (Beat Detection)

```python
flux_smooth = np.convolve(flux, np.ones(5)/5, mode="same")
peaks, _ = signal.find_peaks(flux_smooth, height=0.15, distance=fps//5, prominence=0.05)

beat = np.zeros(n_frames)
bdecay = np.zeros(n_frames, dtype=np.float32)
for p in peaks:
    beat[p] = 1.0
    for d in range(fps // 2):
        if p + d < n_frames:
            bdecay[p + d] = max(bdecay[p + d], math.exp(-d * 2.5 / (fps // 2)))
```

`bdecay` 提供每拍平滑的 0→1→0 脈衝，衰減時間約 0.5 秒。可用於觸發閃爍、故障或鏡像效果。

### 歸一化 (Normalization)

計算完所有影格後，將每個特徵歸一化至 0-1 範圍：

```python
for k in features:
    a = features[k]
    lo, hi = a.min(), a.max()
    features[k] = (a - lo) / (hi - lo + 1e-10)
```

## 影片取樣 (Video Sampling)

### 影格提取

```python
# 方法 1：ffmpeg 管道（記憶體效率高）
cmd = ["ffmpeg", "-i", input_video, "-f", "rawvideo", "-pix_fmt", "rgb24",
       "-s", f"{target_w}x{target_h}", "-r", str(fps), "-"]
pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
frame_size = target_w * target_h * 3
for fi in range(n_frames):
    raw = pipe.stdout.read(frame_size)
    if len(raw) < frame_size: break
    frame = np.frombuffer(raw, dtype=np.uint8).reshape(target_h, target_w, 3)
    # 處理影格...

# 方法 2：OpenCV (如果可用)
cap = cv2.VideoCapture(input_video)
```

### 亮度對應字元映射 (Luminance-to-Character Mapping)

根據亮度將影片像素轉換為 ASCII 字元：

```python
def frame_to_ascii(frame_rgb, grid, pal=PAL_DEFAULT):
    """將影片影格轉換為字元與顏色陣列。"""
    rows, cols = grid.rows, grid.cols
    # 調整影格大小以符合網格尺寸
    small = np.array(Image.fromarray(frame_rgb).resize((cols, rows), Image.LANCZOS))
    # 計算亮度
    lum = (0.299 * small[:,:,0] + 0.587 * small[:,:,1] + 0.114 * small[:,:,2]) / 255.0
    # 映射到字元
    chars = val2char(lum, lum > 0.02, pal)
    # 顏色：使用源像素色彩，並隨亮度縮放以確保可見度
    colors = np.clip(small * np.clip(lum[:,:,None] * 1.5 + 0.3, 0.3, 1), 0, 255).astype(np.uint8)
    return chars, colors
```

### 邊緣加權字元映射 (Edge-Weighted Character Mapping)

使用邊緣偵測在輪廓區域展現更多細節：

```python
def frame_to_ascii_edges(frame_rgb, grid, pal=PAL_DEFAULT, edge_pal=PAL_BOX):
    gray = np.mean(frame_rgb, axis=2)
    small_gray = resize(gray, (grid.rows, grid.cols))
    lum = small_gray / 255.0

    # Sobel 邊緣偵測
    gx = np.abs(small_gray[:, 2:] - small_gray[:, :-2])
    gy = np.abs(small_gray[2:, :] - small_gray[:-2, :])
    edge = np.zeros_like(small_gray)
    edge[:, 1:-1] += gx; edge[1:-1, :] += gy
    edge = np.clip(edge / edge.max(), 0, 1)

    # 邊緣區域使用框線字元，平坦區域使用亮度字元
    is_edge = edge > 0.15
    chars = val2char(lum, lum > 0.02, pal)
    edge_chars = val2char(edge, is_edge, edge_pal)
    chars[is_edge] = edge_chars[is_edge]

    return chars, colors
```

### 運動偵測 (Motion Detection)

偵測影格間的像素變化，以實現運動反應效果：

```python
prev_frame = None
def compute_motion(frame):
    global prev_frame
    if prev_frame is None:
        prev_frame = frame.astype(np.float32)
        return np.zeros(frame.shape[:2])
    diff = np.abs(frame.astype(np.float32) - prev_frame).mean(axis=2)
    prev_frame = frame.astype(np.float32) * 0.7 + prev_frame * 0.3  # 平滑化處理
    return np.clip(diff / 30.0, 0, 1)  # 歸一化的運動地圖
```

利用運動地圖來驅動粒子發射、故障強度或字元密度。

### 影片特徵提取

類似音訊特徵，提取逐影格影片特徵來驅動效果：

```python
def analyze_video_frame(frame_rgb):
    gray = np.mean(frame_rgb, axis=2)
    return {
        "brightness": gray.mean() / 255.0,
        "contrast": gray.std() / 128.0,
        "edge_density": compute_edge_density(gray),
        "motion": compute_motion(frame_rgb).mean(),
        "dominant_hue": compute_dominant_hue(frame_rgb),
        "color_variance": compute_color_variance(frame_rgb),
    }
```

## 影像序列 (Image Sequence)

### 靜態影像轉 ASCII

與單個影片影格的轉換方式相同。對於動畫序列：

```python
import glob
frames = sorted(glob.glob("frames/*.png"))
for fi, path in enumerate(frames):
    img = np.array(Image.open(path).resize((VW, VH)))
    chars, colors = frame_to_ascii(img, grid, pal)
```

### 影像作為紋理源

將影像作為背景紋理，由效果進行調變：

```python
def load_texture(path, grid):
    img = np.array(Image.open(path).resize((grid.cols, grid.rows)))
    lum = np.mean(img, axis=2) / 255.0
    return lum, img  # 亮度用於字元映射，RGB 用於顏色
```

## 文字 / 歌詞 (Text / Lyrics)

### SRT 解析

```python
import re
def parse_srt(path):
    """返回 [(開始秒數, 結束秒數, 內容), ...]"""
    entries = []
    with open(path) as f:
        content = f.read()
    blocks = content.strip().split("\n\n")
    for block in blocks:
        lines = block.strip().split("\n")
        if len(lines) >= 3:
            times = lines[1]
            m = re.match(r"(\d+):(\d+):(\d+),(\d+) --> (\d+):(\d+):(\d+),(\d+)", times)
            if m:
                g = [int(x) for x in m.groups()]
                start = g[0]*3600 + g[1]*60 + g[2] + g[3]/1000
                end = g[4]*3600 + g[5]*60 + g[6] + g[7]/1000
                text = " ".join(lines[2:])
                entries.append((start, end, text))
    return entries
```

### 歌詞顯示模式

- **打字機 (Typewriter)**：字元隨時間從左到右逐一出現。
- **淡入 (Fade-in)**：整行文字從暗變亮。
- **閃現 (Flash)**：隨節拍瞬間出現，隨後淡出。
- **散射 (Scatter)**：字元從隨機位置開始，最後匯聚到目標位置。
- **波浪 (Wave)**：文字沿著正弦波路徑排列。

```python
def lyrics_typewriter(ch, co, text, row, col, t, t_start, t_end, color):
    """在指定時間內逐步揭示字元。"""
    progress = np.clip((t - t_start) / (t_end - t_start), 0, 1)
    n_visible = int(len(text) * progress)
    stamp(ch, co, text[:n_visible], row, col, color)
```

## 生成式（無輸入源，Generative）

對於純生成式的 ASCII 藝術，「特徵」字典是由時間合成的：

```python
def synthetic_features(t, bpm=120):
    """僅根據時間生成類音訊特徵。"""
    beat_period = 60.0 / bpm
    beat_phase = (t % beat_period) / beat_period
    return {
        "rms": 0.5 + 0.3 * math.sin(t * 0.5),
        "bass": 0.5 + 0.4 * math.sin(t * 2 * math.pi / beat_period),
        "sub": 0.3 + 0.3 * math.sin(t * 0.8),
        "mid": 0.4 + 0.3 * math.sin(t * 1.3),
        "hi": 0.3 + 0.2 * math.sin(t * 2.1),
        "cent": 0.5 + 0.2 * math.sin(t * 0.3),
        "flat": 0.4,
        "flux": 0.3 + 0.2 * math.sin(t * 3),
        "beat": 1.0 if beat_phase < 0.05 else 0.0,
        "bdecay": max(0, 1.0 - beat_phase * 4),
        # 比例
        "sub_r": 0.2, "bass_r": 0.25, "lomid_r": 0.15,
        "mid_r": 0.2, "himid_r": 0.12, "hi_r": 0.08,
        "cent_d": 0.1,
    }
```

## TTS 整合

針對旁白影片（證言、引用、故事敘述），為每個片段生成語音音訊，並與背景音樂混合。

### ElevenLabs 語音生成

```python
import requests, time, os

def generate_tts(text, voice_id, api_key, output_path, model="eleven_multilingual_v2"):
    """透過 ElevenLabs API 生成 TTS 音訊。將回應串流存儲至磁碟。"""
    # 如果已生成則跳過（支援冪等重新執行）
    if os.path.exists(output_path) and os.path.getsize(output_path) > 1000:
        return

    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
    headers = {"xi-api-key": api_key, "Content-Type": "application/json"}
    data = {
        "text": text,
        "model_id": model,
        "voice_settings": {
            "stability": 0.65,
            "similarity_boost": 0.80,
            "style": 0.15,
            "use_speaker_boost": True,
        },
    }
    resp = requests.post(url, json=data, headers=headers, stream=True)
    resp.raise_for_status()
    with open(output_path, "wb") as f:
        for chunk in resp.iter_content(chunk_size=4096):
            f.write(chunk)
    time.sleep(0.3)  # 速率限制：避免批量生成時觸發 429 錯誤
```

語音設定注意事項：
- `stability` (穩定性) 0.65 提供自然的變化且不偏移。較低值 (0.3-0.5) 語氣更豐富，較高值 (0.7-0.9) 則較平淡，適合旁白。
- `similarity_boost` (相似度增強) 0.80 能緊貼語音配置文件。較低值則聲音較通用。
- `style` (風格) 0.15 加入細微的風格變化。簡單的閱讀建議保持在低值 (0-0.2)。
- `use_speaker_boost` (語音增強) 設為 True 可提高清晰度，但會略微增加處理時間。

### 語音庫 (Voice Pool)

ElevenLabs 提供約 20 種內建語音。建議在不同引用語間交替使用多種語音以增加多樣性。參考語音庫：

```python
VOICE_POOL = [
    ("JBFqnCBsd6RMkjVDRZzb", "George"),
    ("nPczCjzI2devNBz1zQrb", "Brian"),
    ("pqHfZKP75CvOlQylNhV4", "Bill"),
    ("CwhRBWXzGAHq8TQ4Fs17", "Roger"),
    ("cjVigY5qzO86Huf0OWal", "Eric"),
    ("onwK4e9ZLuTAKqWW03F9", "Daniel"),
    ("IKne3meq5aSn9XLyUdCD", "Charlie"),
    ("iP95p4xoKVk53GoZ742B", "Chris"),
    ("bIHbv24MWmeRgasZH58o", "Will"),
    ("TX3LPaxmHKxFdv7VOQHJ", "Liam"),
    ("SAz9YHcvj6GT2YYXdXww", "River"),
    ("EXAVITQu4vr4xnSDxMaL", "Sarah"),
    ("Xb7hH8MSUJpSbSDYk0k2", "Alice"),
    ("pFZP5JQG7iQjIQuC4Bku", "Lily"),
    ("XrExE9yKIg1WjnnlVkGX", "Matilda"),
    ("FGY2WhTYpPnrIDTdsKH5", "Laura"),
    ("SOYHLrjzK2X1ezoPC6cr", "Harry"),
    ("hpp4J3VqNfWAUOO0d1Us", "Bella"),
    ("N2lVS1w4EtoT3dr4eOWO", "Callum"),
    ("cgSgspJ2msm6clMCkdW9", "Jessica"),
    ("pNInz6obpgDQGcFmaJgB", "Adam"),
]
```

### 語音分配

進行確定性的洗牌，確保重新執行時語音對應關係保持不變：

```python
import random as _rng

def assign_voices(n_quotes, voice_pool, seed=42):
    """為每條引用分配不同的語音，必要時循環使用。"""
    r = _rng.Random(seed)
    ids = [v[0] for v in voice_pool]
    r.shuffle(ids)
    return [ids[i % len(ids)] for i in range(n_quotes)]
```

### 讀音控制 (Pronunciation Control)

TTS 文本必須與顯示文字分開。顯示文字包含用於視覺排版的換行符；TTS 文本則是平坦的句子，並帶有語音修正。

常見修正：
- 品牌名稱：標註語音拼寫（例如 "Nous" 寫成 "Noose"，"nginx" 寫成 "engine-x"）。
- 縮寫：展開讀法（例如 "API" 寫成 "A P I"，"CLI" 寫成 "C L I"）。
- 技術術語：添加語音提示。
- 控制節奏的標點：句號產生長停頓，逗號產生短停頓。

```python
# 顯示文字：透過換行控制視覺排版
QUOTES = [
    ("It can do far more than the Claws,\nand you don't need to buy a Mac Mini.\nNous Research has a winner here.", "Brian Roemmele"),
]

# TTS 文本：平坦，並針對語音進行了修正
QUOTES_TTS = [
    "It can do far more than the Claws, and you don't need to buy a Mac Mini. Noose Research has a winner here.",
]
# 保持兩個陣列同步 —— 使用相同的索引
```

### 音訊流水線

1. 生成個別的 TTS 片段（每條引用一個 MP3，若已存在則跳過）。
2. 將每個片段轉為 WAV (單聲道, 22050 Hz)，以便測量時長與拼接。
3. 計算時機：片頭補白 + 語音 + 間隙 + 片尾補白 = 目標總長。
4. 拼接成單個 TTS 音軌，並補上靜音。
5. 與背景音樂混合。

```python
def build_tts_track(tts_clips, target_duration, intro_pad=5.0, outro_pad=4.0):
    """拼接 TTS 片段，並根據計算出的間隙補齊至目標時長。

    返回：
        timing: (開始時間, 結束時間, 引用索引) 元組列表
    """
    sr = 22050

    # 轉為 WAV 以便精確測量時長與樣本級拼接
    durations = []
    for clip in tts_clips:
        wav = clip.replace(".mp3", ".wav")
        subprocess.run(
            ["ffmpeg", "-y", "-i", clip, "-ac", "1", "-ar", str(sr),
             "-sample_fmt", "s16", wav],
            capture_output=True, check=True)
        result = subprocess.run(
            ["ffprobe", "-v", "error", "-show_entries", "format=duration",
             "-of", "csv=p=0", wav],
            capture_output=True, text=True)
        durations.append(float(result.stdout.strip()))

    # 計算填補目標時長所需的間隙
    total_speech = sum(durations)
    n_gaps = len(tts_clips) - 1
    remaining = target_duration - total_speech - intro_pad - outro_pad
    gap = max(1.0, remaining / max(1, n_gaps))

    # 構建時機並拼接樣本
    timing = []
    t = intro_pad
    all_audio = [np.zeros(int(sr * intro_pad), dtype=np.int16)]

    for i, dur in enumerate(durations):
        wav = tts_clips[i].replace(".mp3", ".wav")
        with wave.open(wav) as wf:
            samples = np.frombuffer(wf.readframes(wf.getnframes()), dtype=np.int16)
        timing.append((t, t + dur, i))
        all_audio.append(samples)
        t += dur
        if i < len(tts_clips) - 1:
            all_audio.append(np.zeros(int(sr * gap), dtype=np.int16))
            t += gap

    all_audio.append(np.zeros(int(sr * outro_pad), dtype=np.int16))

    # 填充或裁切至精確的 target_duration
    full = np.concatenate(all_audio)
    target_samples = int(sr * target_duration)
    if len(full) < target_samples:
        full = np.pad(full, (0, target_samples - len(full)))
    else:
        full = full[:target_samples]

    # 寫入拼接後的 TTS 音軌
    with wave.open("tts_full.wav", "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(full.tobytes())

    return timing
```

### 音訊混合 (Audio Mixing)

將 TTS (置中) 與背景音樂 (寬立體聲, 低音量) 混合。濾鏡鏈如下：
1. TTS 單聲道複製到雙通道（置中）。
2. 背景音樂進行響度歸一化，音量降至 15%，並使用 `extrastereo` 拓寬立體聲。
3. 兩者混合，結尾處加上淡出過渡以求平滑。

```python
def mix_audio(tts_path, bgm_path, output_path, bgm_volume=0.15):
    """將 TTS 置中，背景音樂 panned 為寬立體聲混合。"""
    filter_complex = (
        # TTS: 單聲道 -> 立體聲置中
        "[0:a]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=mono,"
        "pan=stereo|c0=c0|c1=c0[tts];"
        # 背景音樂：歸一化、降音量、拓寬立體聲
        f"[1:a]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,"
        f"loudnorm=I=-16:TP=-1.5:LRA=11,"
        f"volume={bgm_volume},"
        f"extrastereo=m=2.5[bgm];"
        # 混合，並在結尾平滑淡出
        "[tts][bgm]amix=inputs=2:duration=longest:dropout_transition=3,"
        "aformat=sample_fmts=s16:sample_rates=44100:channel_layouts=stereo[out]"
    )
    cmd = [
        "ffmpeg", "-y",
        "-i", tts_path,
        "-i", bgm_path,
        "-filter_complex", filter_complex,
        "-map", "[out]", output_path,
    ]
    subprocess.run(cmd, capture_output=True, check=True)
```

### 逐條引用的視覺風格 (Per-Quote Visual Style)

為每條引用語輪流切換視覺預設值以增加豐富度。每個預設值定義了背景效果、配色方案與文字顏色：

```python
QUOTE_STYLES = [
    {"hue": 0.08, "accent": 0.7, "bg": "spiral",       "text_rgb": (255, 220, 140)},  # 暖金
    {"hue": 0.55, "accent": 0.6, "bg": "rings",         "text_rgb": (180, 220, 255)},  # 酷藍
    {"hue": 0.75, "accent": 0.7, "bg": "wave",          "text_rgb": (220, 180, 255)},  # 紫色
    {"hue": 0.35, "accent": 0.6, "bg": "matrix",        "text_rgb": (140, 255, 180)},  # 綠色
    {"hue": 0.95, "accent": 0.8, "bg": "fire",          "text_rgb": (255, 180, 160)},  # 紅/珊瑚色
    {"hue": 0.12, "accent": 0.5, "bg": "interference",  "text_rgb": (255, 240, 200)},  # 琥珀
    {"hue": 0.60, "accent": 0.7, "bg": "tunnel",        "text_rgb": (160, 210, 255)},  # 青色
    {"hue": 0.45, "accent": 0.6, "bg": "aurora",        "text_rgb": (180, 255, 220)},  # 鴨綠
]

style = QUOTE_STYLES[quote_index % len(QUOTE_STYLES)]
```

這能保證相鄰的兩條引用不會有重複的外觀，即使不使用隨機性。

### 打字機文字渲染 (Typewriter Text Rendering)

字元逐個出現，並與語音進度同步。新出現的字元更亮，創造出「剛剛打出」的高光效果：

```python
def render_typewriter(ch, co, lines, block_start, cols, progress, total_chars, text_rgb, t):
    """將打字機文字疊加到字元/顏色網格。
    progress: 0.0 (全隱藏) 到 1.0 (全顯示)。"""
    chars_visible = int(total_chars * min(1.0, progress * 1.2))  # 輕微過度以增加俐落感
    tr, tg, tb = text_rgb
    char_count = 0
    for li, line in enumerate(lines):
        row = block_start + li
        col = (cols - len(line)) // 2
        for ci, c in enumerate(line):
            if char_count < chars_visible:
                age = chars_visible - char_count
                bri_factor = min(1.0, 0.5 + 0.5 / (1 + age * 0.015))  # 越新越亮
                hue_shift = math.sin(char_count * 0.3 + t * 2) * 0.05
                stamp(ch, co, c, row, col + ci,
                      (int(min(255, tr * bri_factor * (1.0 + hue_shift))),
                       int(min(255, tg * bri_factor)),
                       int(min(255, tb * bri_factor * (1.0 - hue_shift)))))
            char_count += 1

    # 在插入點閃爍游標
    if progress < 1.0 and int(t * 3) % 2 == 0:
        cc = 0
        for li, line in enumerate(lines):
            for ci, c in enumerate(line):
                if cc == chars_visible:
                    stamp(ch, co, "\u258c", block_start + li,
                          (cols - len(line)) // 2 + ci, (255, 220, 100))
                    return
                cc += 1
```

### 混合音軌上的特徵分析

對最終混合音軌執行標準音訊分析（FFT、節拍偵測），使視覺效果能同時對 TTS 與音樂做出反應：

```python
# 分析 mixed_final.wav (而非單獨的軌跡)
features = analyze_audio("mixed_final.wav", fps=24)
```

視覺效果將隨著音樂節奏與說話能量同步脈動。

---

## 影音同步驗證 (Audio-Video Sync Verification)

渲染後，驗證視覺節拍標記是否與實際音訊節拍對齊。漂移可能來自影格時機誤差、ffmpeg 拼接邊界以及 `fi / fps` 的進位。

### 節拍時間戳記提取

```python
def extract_beat_timestamps(features, fps, threshold=0.5):
    """提取節拍特徵超過閥值的時間戳記。"""
    beat = features["beat"]
    timestamps = []
    for fi in range(len(beat)):
        if beat[fi] > threshold:
            timestamps.append(fi / fps)
    return timestamps

def extract_visual_beat_timestamps(video_path, fps, brightness_jump=30):
    """透過連續影格間的亮度跳變偵測視覺節拍。"""
    import subprocess
    cmd = ["ffmpeg", "-i", video_path, "-f", "rawvideo", "-pix_fmt", "gray", "-"]
    proc = subprocess.run(cmd, capture_output=True)
    frames = np.frombuffer(proc.stdout, dtype=np.uint8)
    # 從位元組總數推斷影格尺寸
    n_pixels = len(frames)
    # 透過影片中繼資料進行自動偵測更為穩健：
    probe = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0",
         "-show_entries", "stream=width,height",
         "-of", "csv=p=0", video_path],
        capture_output=True, text=True)
    w, h = map(int, probe.stdout.strip().split(","))
    ppf = w * h  # 每影格像素數
    n_frames = n_pixels // ppf
    frames = frames[:n_frames * ppf].reshape(n_frames, ppf)
    means = frames.mean(axis=1)
    
    timestamps = []
    for i in range(1, len(means)):
        if means[i] - means[i-1] > brightness_jump:
            timestamps.append(i / fps)
    return timestamps
```

### 同步報告 (Sync Report)

```python
def sync_report(audio_beats, visual_beats, tolerance_ms=50):
    """比較音訊節拍與視覺節拍時間戳記。
    
    參數：
        audio_beats: 音訊分析得到的時間戳記列表 (秒)
        visual_beats: 影片亮度分析得到的時間戳記列表 (秒)
        tolerance_ms: 最大可接受的毫秒偏移量
    
    返回：
        包含匹配/未匹配/漂移統計資訊的字典
    """
    tolerance = tolerance_ms / 1000.0
    matched = []
    unmatched_audio = []
    unmatched_visual = list(visual_beats)
    
    for at in audio_beats:
        best_match = None
        best_delta = float("inf")
        for vt in unmatched_visual:
            delta = abs(at - vt)
            if delta < best_delta:
                best_delta = delta
                best_match = vt
        if best_match is not None and best_delta < tolerance:
            matched.append({"audio": at, "visual": best_match, "drift_ms": best_delta * 1000})
            unmatched_visual.remove(best_match)
        else:
            unmatched_audio.append(at)
    
    drifts = [m["drift_ms"] for m in matched]
    return {
        "matched": len(matched),
        "unmatched_audio": len(unmatched_audio),
        "unmatched_visual": len(unmatched_visual),
        "total_audio_beats": len(audio_beats),
        "total_visual_beats": len(visual_beats),
        "mean_drift_ms": np.mean(drifts) if drifts else 0,
        "max_drift_ms": np.max(drifts) if drifts else 0,
        "p95_drift_ms": np.percentile(drifts, 95) if len(drifts) > 1 else 0,
    }

# 用法：
audio_beats = extract_beat_timestamps(features, fps=24)
visual_beats = extract_visual_beat_timestamps("output.mp4", fps=24)
report = sync_report(audio_beats, visual_beats)
print(f"匹配項: {report['matched']}/{report['total_audio_beats']} 拍")
print(f"平均漂移: {report['mean_drift_ms']:.1f}ms, 最大漂移: {report['max_drift_ms']:.1f}ms")
# 目標：平均漂移 < 20ms, 最大漂移 < 42ms (24fps 下的一格時長)
```

### 常見同步問題

| 徵兆 | 原因 | 修復方法 |
|---------|-------|-----|
| 視覺節拍持續落後 | ffmpeg 拼接時在邊界添加了影格 | 使用 `-vsync cfr` 標記；將片段補齊至精確影格數 |
| 漂移隨時間增加 | `t = fi / fps` 的浮點數累計誤差 | 使用整數影格計數器，每影格重新計算 `t` |
| 隨機漏掉節拍 | 節拍閥值過高 / 特徵平滑過度 | 調低閥值；降低節拍特徵的 EMA alpha 值 |
| 節拍落在錯誤的影格 | 影格索引偏差 (Off-by-one) | 驗證：影格 0 對應 t=0, 影格 1 對應 t=1/fps |
