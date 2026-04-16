# AudioCraft 疑難排解指南

## 安裝問題

### 匯入錯誤

**錯誤**：`ModuleNotFoundError: No module named 'audiocraft'`

**解決方案**：
```bash
# 從 PyPI 安裝
pip install audiocraft

# 或從 GitHub 安裝
pip install git+https://github.com/facebookresearch/audiocraft.git

# 驗證安裝
python -c "from audiocraft.models import MusicGen; print('OK')"
```

### 找不到 FFmpeg

**錯誤**：`RuntimeError: ffmpeg not found`

**解決方案**：
```bash
# Ubuntu/Debian
sudo apt-get install ffmpeg

# macOS
brew install ffmpeg

# Windows (使用 conda)
conda install -c conda-forge ffmpeg

# 驗證
ffmpeg -version
```

### PyTorch CUDA 不匹配

**錯誤**：`RuntimeError: CUDA error: no kernel image is available`

**解決方案**：
```bash
# 檢查 CUDA 版本
nvcc --version
python -c "import torch; print(torch.version.cuda)"

# 安裝相符的 PyTorch
pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu121

# 對於 CUDA 11.8
pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu118
```

### xformers 問題

**錯誤**：與 `ImportError: xformers` 相關的錯誤

**解決方案**：
```bash
# 安裝 xformers 以提高記憶體效率
pip install xformers

# 或停用 xformers
export AUDIOCRAFT_USE_XFORMERS=0

# 在 Python 中
import os
os.environ["AUDIOCRAFT_USE_XFORMERS"] = "0"
from audiocraft.models import MusicGen
```

## 模型載入問題

### 載入時記憶體不足

**錯誤**：模型載入期間發生 `torch.cuda.OutOfMemoryError`

**解決方案**：
```python
# 使用較小的模型
model = MusicGen.get_pretrained('facebook/musicgen-small')

# 先強制載入到 CPU
import torch
device = "cpu"
model = MusicGen.get_pretrained('facebook/musicgen-small', device=device)
model = model.to("cuda")

# 使用 HuggingFace 並搭配 device_map
from transformers import MusicgenForConditionalGeneration
model = MusicgenForConditionalGeneration.from_pretrained(
    "facebook/musicgen-small",
    device_map="auto"
)
```

### 下載失敗

**錯誤**：連線錯誤或下載不完整

**解決方案**：
```python
# 設定快取目錄
import os
os.environ["AUDIOCRAFT_CACHE_DIR"] = "/path/to/cache"

# 或對於 HuggingFace
os.environ["HF_HOME"] = "/path/to/hf_cache"

# 恢復下載
from huggingface_hub import snapshot_download
snapshot_download("facebook/musicgen-small", resume_download=True)

# 使用本地檔案
model = MusicGen.get_pretrained('/local/path/to/model')
```

### 錯誤的模型類型

**錯誤**：為任務載入了錯誤的模型

**解決方案**：
```python
# 用於文字轉音樂：使用 MusicGen
from audiocraft.models import MusicGen
model = MusicGen.get_pretrained('facebook/musicgen-medium')

# 用於文字轉聲音：使用 AudioGen
from audiocraft.models import AudioGen
model = AudioGen.get_pretrained('facebook/audiogen-medium')

# 用於旋律條件化：使用 melody 變體
model = MusicGen.get_pretrained('facebook/musicgen-melody')

# 用於立體聲：使用 stereo 變體
model = MusicGen.get_pretrained('facebook/musicgen-stereo-medium')
```

## 生成問題

### 輸出為空或無聲

**問題**：生成的音訊是無聲的或非常小聲

**解決方案**：
```python
import torch

# 檢查輸出
wav = model.generate(["upbeat music"])
print(f"形狀: {wav.shape}")
print(f"最大振幅: {wav.abs().max().item()}")
print(f"平均振幅: {wav.abs().mean().item()}")

# 如果太小聲，請進行標準化
def normalize_audio(audio, target_db=-14.0):
    rms = torch.sqrt(torch.mean(audio ** 2))
    target_rms = 10 ** (target_db / 20)
    gain = target_rms / (rms + 1e-8)
    return audio * gain

wav_normalized = normalize_audio(wav)
```

### 輸出品質不佳

**問題**：生成的音樂聽起來很差或有雜音

**解決方案**：
```python
# 使用較大的模型
model = MusicGen.get_pretrained('facebook/musicgen-large')

# 調整生成參數
model.set_generation_params(
    duration=15,
    top_k=250,          # 增加以提高多樣性
    temperature=0.8,    # 降低以使輸出更聚焦
    cfg_coef=4.0        # 增加以提高文字符合度
)

# 使用更好的提示詞
# 差的："music"
# 好的："upbeat electronic dance music with synthesizers and punchy drums"

# 嘗試 MultiBand Diffusion
from audiocraft.models import MultiBandDiffusion
mbd = MultiBandDiffusion.get_mbd_musicgen()
tokens = model.generate_tokens(["prompt"])
wav = mbd.tokens_to_wav(tokens)
```

### 生成內容過短

**問題**：音訊比預期的短

**解決方案**：
```python
# 檢查時長設定
model.set_generation_params(duration=30)  # 在 generate 之前設定

# 在生成中驗證
print(f"時長設定: {model.generation_params}")

# 檢查輸出形狀
wav = model.generate(["prompt"])
actual_duration = wav.shape[-1] / 32000
print(f"實際時長: {actual_duration}秒")

# 注意：最大時長通常為 30 秒
```

### 旋律條件化失敗

**錯誤**：旋律條件化生成出現問題

**解決方案**：
```python
import torchaudio
from audiocraft.models import MusicGen

# 載入旋律模型 (而非基礎模型)
model = MusicGen.get_pretrained('facebook/musicgen-melody')

# 載入並準備旋律
melody, sr = torchaudio.load("melody.wav")

# 若有需要，重採樣至模型採樣率
if sr != 32000:
    resampler = torchaudio.transforms.Resample(sr, 32000)
    melody = resampler(melody)

# 確保形狀正確 [batch, channels, samples]
if melody.dim() == 1:
    melody = melody.unsqueeze(0).unsqueeze(0)
elif melody.dim() == 2:
    melody = melody.unsqueeze(0)

# 將立體聲轉換為單聲道
if melody.shape[1] > 1:
    melody = melody.mean(dim=1, keepdim=True)

# 使用旋律生成
model.set_generation_params(duration=min(melody.shape[-1] / 32000, 30))
wav = model.generate_with_chroma(["piano cover"], melody, 32000)
```

## 記憶體問題

### CUDA 記憶體不足 (OOM)

**錯誤**：`torch.cuda.OutOfMemoryError: CUDA out of memory`

**解決方案**：
```python
import torch

# 生成前清除快取
torch.cuda.empty_cache()

# 使用較小的模型
model = MusicGen.get_pretrained('facebook/musicgen-small')

# 減少時長
model.set_generation_params(duration=10)  # 而非 30

# 一次生成一個提示詞
for prompt in prompts:
    wav = model.generate([prompt])
    save_audio(wav)
    torch.cuda.empty_cache()

# 對於非常大型的生成，使用 CPU
model = MusicGen.get_pretrained('facebook/musicgen-small', device="cpu")
```

### 批次處理期間記憶體洩漏

**問題**：記憶體隨著時間增長

**解決方案**：
```python
import gc
import torch

def generate_with_cleanup(model, prompts):
    results = []

    for prompt in prompts:
        with torch.no_grad():
            wav = model.generate([prompt])
            results.append(wav.cpu())

        # 清理
        del wav
        gc.collect()
        torch.cuda.empty_cache()

    return results

# 使用 context manager
with torch.inference_mode():
    wav = model.generate(["prompt"])
```

## 音訊格式問題

### 錯誤的採樣率

**問題**：音訊播放速度錯誤

**解決方案**：
```python
import torchaudio

# MusicGen 輸出為 32kHz
sample_rate = 32000

# AudioGen 輸出為 16kHz
sample_rate = 16000

# 儲存時務必使用正確的速率
torchaudio.save("output.wav", wav[0].cpu(), sample_rate=sample_rate)

# 若有需要請重採樣
resampler = torchaudio.transforms.Resample(32000, 44100)
wav_resampled = resampler(wav)
```

### 立體聲/單聲道不匹配

**問題**：通道數量錯誤

**解決方案**：
```python
# 檢查模型類型
print(f"音訊通道: {wav.shape}")
# 單聲道: [batch, 1, samples]
# 立體聲: [batch, 2, samples]

# 將單聲道轉換為立體聲
if wav.shape[1] == 1:
    wav_stereo = wav.repeat(1, 2, 1)

# 將立體聲轉換為單聲道
if wav.shape[1] == 2:
    wav_mono = wav.mean(dim=1, keepdim=True)

# 對於立體聲輸出，請使用立體聲模型
model = MusicGen.get_pretrained('facebook/musicgen-stereo-medium')
```

### 削波 (Clipping) 和失真

**問題**：音訊有削波或失真

**解決方案**：
```python
import torch

# 檢查削波
max_val = wav.abs().max().item()
print(f"最大振幅: {max_val}")

# 標準化以防止削波
if max_val > 1.0:
    wav = wav / max_val

# 套用軟削波 (Soft clipping)
def soft_clip(x, threshold=0.9):
    return torch.tanh(x / threshold) * threshold

wav_clipped = soft_clip(wav)

# 生成期間降低溫度 (temperature)
model.set_generation_params(temperature=0.7)  # 更受控
```

## HuggingFace Transformers 問題

### 處理器 (Processor) 錯誤

**錯誤**：MusicgenProcessor 出現問題

**解決方案**：
```python
from transformers import AutoProcessor, MusicgenForConditionalGeneration

# 載入相符的處理器和模型
processor = AutoProcessor.from_pretrained("facebook/musicgen-small")
model = MusicgenForConditionalGeneration.from_pretrained("facebook/musicgen-small")

# 確保輸入位於相同的裝置上
inputs = processor(
    text=["prompt"],
    padding=True,
    return_tensors="pt"
).to("cuda")

# 檢查處理器配置
print(processor.tokenizer)
print(processor.feature_extractor)
```

### 生成參數錯誤

**錯誤**：無效的生成參數

**解決方案**：
```python
# HuggingFace 使用不同的參數名稱
audio_values = model.generate(
    **inputs,
    do_sample=True,           # 啟用採樣
    guidance_scale=3.0,       # CFG (並非 cfg_coef)
    max_new_tokens=256,       # 標記限制 (並非時長)
    temperature=1.0
)

# 從時長計算標記數
# 每秒約 50 個標記
duration_seconds = 10
max_tokens = duration_seconds * 50
audio_values = model.generate(**inputs, max_new_tokens=max_tokens)
```

## 效能問題

### 生成緩慢

**問題**：生成花費太多時間

**解決方案**：
```python
# 使用較小的模型
model = MusicGen.get_pretrained('facebook/musicgen-small')

# 減少時長
model.set_generation_params(duration=10)

# 使用 GPU
model.to("cuda")

# 若硬體支援，啟用 Flash Attention
# (需要相容的硬體)

# 批次處理多個提示詞
prompts = ["prompt1", "prompt2", "prompt3"]
wav = model.generate(prompts)  # 單一批次比迴圈快

# 使用編譯 (PyTorch 2.0+)
model.lm = torch.compile(model.lm)
```

### 回退到 CPU

**問題**：生成在 CPU 而非 GPU 上執行

**解決方案**：
```python
import torch

# 檢查 CUDA 可用性
print(f"CUDA 可用: {torch.cuda.is_available()}")
print(f"CUDA 裝置: {torch.cuda.get_device_name(0)}")

# 明確移動到 GPU
model = MusicGen.get_pretrained('facebook/musicgen-small')
model.to("cuda")

# 驗證模型裝置
print(f"模型裝置: {next(model.lm.parameters()).device}")
```

## 常見錯誤訊息

| 錯誤 | 原因 | 解決方案 |
|-------|-------|----------|
| `CUDA out of memory` | 模型太大 | 使用較小模型、縮短生成時長 |
| `ffmpeg not found` | 未安裝 FFmpeg | 安裝 FFmpeg |
| `No module named 'audiocraft'` | 未安裝 | `pip install audiocraft` |
| `RuntimeError: Expected 3D tensor` | 輸入形狀錯誤 | 檢查張量維度 |
| `KeyError: 'melody'` | 模型類型不符 | 使用 musicgen-melody 模型 |
| `Sample rate mismatch` | 音訊格式錯誤 | 重採樣至模型速率 |

## 尋求協助

1. **GitHub Issues**: https://github.com/facebookresearch/audiocraft/issues
2. **HuggingFace 論壇**: https://discuss.huggingface.co
3. **論文**: https://arxiv.org/abs/2306.05284

### 回報問題

請包含：
- Python 版本
- PyTorch 版本
- CUDA 版本
- AudioCraft 版本：`pip show audiocraft`
- 完整的錯誤回溯 (Traceback)
- 最小可重現程式碼
- 硬體資訊 (GPU 型號, VRAM)
