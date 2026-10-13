---
name: audiocraft-audio-generation
description: 用於音訊生成的 PyTorch 函式庫，包含文字轉音樂 (MusicGen) 和文字轉聲音 (AudioGen)。當您需要從文字描述生成音樂、建立音效或執行旋律條件化的音樂生成時使用。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [audiocraft, torch>=2.0.0, transformers>=4.30.0]
metadata:
  hermes:
    tags: [多模態, 音訊生成, 文字轉音樂, 文字轉音訊, MusicGen]

---

# AudioCraft：音訊生成

使用 Meta 的 AudioCraft 進行文字轉音樂和文字轉音訊生成的綜合指南，包含 MusicGen、AudioGen 和 EnCodec。

## 何時使用 AudioCraft

**在以下情況使用 AudioCraft：**
- 需要從文字描述生成音樂
- 建立音效和環境音訊
- 構建音樂生成應用程式
- 需要旋律條件化的音樂生成
- 需要立體聲音訊輸出
- 需要帶有風格轉移的可控音樂生成

**核心功能：**
- **MusicGen**：具備旋律條件化的文字轉音樂生成
- **AudioGen**：文字轉音效生成
- **EnCodec**：高保真神經音訊編解碼器
- **多種模型大小**：從 Small (300M) 到 Large (3.3B)
- **立體聲支援**：完整的立體聲音訊生成
- **風格條件化**：MusicGen-Style 支援基於參考內容的生成

**請考慮使用替代方案：**
- **Stable Audio**：用於較長的商業音樂生成
- **Bark**：用於帶有音樂/音效的文字轉語音
- **Riffusion**：用於基於頻譜圖的音樂生成
- **OpenAI Jukebox**：用於生成帶有歌詞的原始音訊

## 快速入門

### 安裝

```bash
# 從 PyPI 安裝
pip install audiocraft

# 從 GitHub 安裝 (最新版本)
pip install git+https://github.com/facebookresearch/audiocraft.git

# 或使用 HuggingFace Transformers
pip install transformers torch torchaudio
```

### 基礎文字轉音樂 (AudioCraft)

```python
import torchaudio
from audiocraft.models import MusicGen

# 載入模型
model = MusicGen.get_pretrained('facebook/musicgen-small')

# 設定生成參數
model.set_generation_params(
    duration=8,  # 秒數
    top_k=250,
    temperature=1.0
)

# 從文字生成
descriptions = ["happy upbeat electronic dance music with synths"]
wav = model.generate(descriptions)

# 儲存音訊
torchaudio.save("output.wav", wav[0].cpu(), sample_rate=32000)
```

### 使用 HuggingFace Transformers

```python
from transformers import AutoProcessor, MusicgenForConditionalGeneration
import scipy

# 載入模型和處理器
processor = AutoProcessor.from_pretrained("facebook/musicgen-small")
model = MusicgenForConditionalGeneration.from_pretrained("facebook/musicgen-small")
model.to("cuda")

# 生成音樂
inputs = processor(
    text=["80s pop track with bassy drums and synth"],
    padding=True,
    return_tensors="pt"
).to("cuda")

audio_values = model.generate(
    **inputs,
    do_sample=True,
    guidance_scale=3,
    max_new_tokens=256
)

# 儲存
sampling_rate = model.config.audio_encoder.sampling_rate
scipy.io.wavfile.write("output.wav", rate=sampling_rate, data=audio_values[0, 0].cpu().numpy())
```

### 使用 AudioGen 進行文字轉聲音

```python
from audiocraft.models import AudioGen

# 載入 AudioGen
model = AudioGen.get_pretrained('facebook/audiogen-medium')

model.set_generation_params(duration=5)

# 生成音效
descriptions = ["dog barking in a park with birds chirping"]
wav = model.generate(descriptions)

torchaudio.save("sound.wav", wav[0].cpu(), sample_rate=16000)
```

## 核心概念

### 架構概覽

```
AudioCraft 架構：
┌──────────────────────────────────────────────────────────────┐
│                    文字編碼器 (Text Encoder, T5)              │
│                         │                                     │
│                    文字嵌入 (Text Embeddings)                  │
└────────────────────────┬─────────────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────────┐
│             Transformer 解碼器 (LM)                           │
│     以自回歸方式生成音訊標記 (Audio Tokens)                    │
│     使用高效的標記交錯模式                                     │
└────────────────────────┬─────────────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────────┐
│                EnCodec 音訊解碼器                             │
│        將標記轉換回音訊波形                                   │
└──────────────────────────────────────────────────────────────┘
```

### 模型變體

| 模型 | 大小 | 描述 | 使用場景 |
|-------|------|-------------|----------|
| `musicgen-small` | 300M | 文字轉音樂 | 快速生成 |
| `musicgen-medium` | 1.5B | 文字轉音樂 | 平衡效能 |
| `musicgen-large` | 3.3B | 文字轉音樂 | 最佳品質 |
| `musicgen-melody` | 1.5B | 文字 + 旋律 | 旋律條件化 |
| `musicgen-melody-large` | 3.3B | 文字 + 旋律 | 最佳旋律品質 |
| `musicgen-stereo-*` | 變動 | 立體聲輸出 | 立體聲生成 |
| `musicgen-style` | 1.5B | 風格轉移 | 基於參考內容 |
| `audiogen-medium` | 1.5B | 文字轉聲音 | 音效生成 |

### 生成參數

| 參數 | 預設值 | 描述 |
|-----------|---------|-------------|
| `duration` | 8.0 | 長度（秒，1-120） |
| `top_k` | 250 | Top-k 採樣 |
| `top_p` | 0.0 | 核採樣 (Nucleus sampling, 0 = 停用) |
| `temperature` | 1.0 | 採樣溫度 (Temperature) |
| `cfg_coef` | 3.0 | 無分類器引導 (Classifier-free guidance) |

## MusicGen 用法

### 文字轉音樂生成

```python
from audiocraft.models import MusicGen
import torchaudio

model = MusicGen.get_pretrained('facebook/musicgen-medium')

# 配置生成
model.set_generation_params(
    duration=30,          # 最高 30 秒
    top_k=250,            # 採樣多樣性
    top_p=0.0,            # 0 = 僅使用 top_k
    temperature=1.0,      # 創造力（越高越多元）
    cfg_coef=3.0          # 文字符合度（越高越嚴格）
)

# 生成多個範例
descriptions = [
    "epic orchestral soundtrack with strings and brass",
    "chill lo-fi hip hop beat with jazzy piano",
    "energetic rock song with electric guitar"
]

# 生成 (回傳 [batch, channels, samples])
wav = model.generate(descriptions)

# 儲存各個結果
for i, audio in enumerate(wav):
    torchaudio.save(f"music_{i}.wav", audio.cpu(), sample_rate=32000)
```

### 旋律條件化生成

```python
from audiocraft.models import MusicGen
import torchaudio

# 載入旋律模型
model = MusicGen.get_pretrained('facebook/musicgen-melody')
model.set_generation_params(duration=30)

# 載入旋律音訊
melody, sr = torchaudio.load("melody.wav")

# 使用旋律條件化生成
descriptions = ["acoustic guitar folk song"]
wav = model.generate_with_chroma(descriptions, melody, sr)

torchaudio.save("melody_conditioned.wav", wav[0].cpu(), sample_rate=32000)
```

### 立體聲生成

```python
from audiocraft.models import MusicGen

# 載入立體聲模型
model = MusicGen.get_pretrained('facebook/musicgen-stereo-medium')
model.set_generation_params(duration=15)

descriptions = ["ambient electronic music with wide stereo panning"]
wav = model.generate(descriptions)

# wav 形狀：立體聲為 [batch, 2, samples]
print(f"Stereo shape: {wav.shape}")  # [1, 2, 480000]
torchaudio.save("stereo.wav", wav[0].cpu(), sample_rate=32000)
```

### 音訊延續 (Audio Continuation)

```python
from transformers import AutoProcessor, MusicgenForConditionalGeneration

processor = AutoProcessor.from_pretrained("facebook/musicgen-medium")
model = MusicgenForConditionalGeneration.from_pretrained("facebook/musicgen-medium")

# 載入要續接的音訊
import torchaudio
audio, sr = torchaudio.load("intro.wav")

# 處理文字與音訊
inputs = processor(
    audio=audio.squeeze().numpy(),
    sampling_rate=sr,
    text=["continue with a epic chorus"],
    padding=True,
    return_tensors="pt"
)

# 生成續接內容
audio_values = model.generate(**inputs, do_sample=True, guidance_scale=3, max_new_tokens=512)
```

## MusicGen-Style 用法

### 風格條件化生成

```python
from audiocraft.models import MusicGen

# 載入風格模型
model = MusicGen.get_pretrained('facebook/musicgen-style')

# 配置風格生成
model.set_generation_params(
    duration=30,
    cfg_coef=3.0,
    cfg_coef_beta=5.0  # 風格影響力
)

# 配置風格條件化參數
model.set_style_conditioner_params(
    eval_q=3,          # RVQ 量化器 (1-6)
    excerpt_length=3.0  # 風格摘錄長度
)

# 載入風格參考
style_audio, sr = torchaudio.load("reference_style.wav")

# 使用文字 + 風格生成
descriptions = ["upbeat dance track"]
wav = model.generate_with_style(descriptions, style_audio, sr)
```

### 僅限風格生成 (無文字)

```python
# 生成符合風格但不使用文字提示
model.set_generation_params(
    duration=30,
    cfg_coef=3.0,
    cfg_coef_beta=None  # 停用僅風格的雙重 CFG
)

wav = model.generate_with_style([None], style_audio, sr)
```

## AudioGen 用法

### 音效生成

```python
from audiocraft.models import AudioGen
import torchaudio

model = AudioGen.get_pretrained('facebook/audiogen-medium')
model.set_generation_params(duration=10)

# 生成各種聲音
descriptions = [
    "thunderstorm with heavy rain and lightning",
    "busy city traffic with car horns",
    "ocean waves crashing on rocks",
    "crackling campfire in forest"
]

wav = model.generate(descriptions)

for i, audio in enumerate(wav):
    torchaudio.save(f"sound_{i}.wav", audio.cpu(), sample_rate=16000)
```

## EnCodec 用法

### 音訊壓縮

```python
from audiocraft.models import CompressionModel
import torch
import torchaudio

# 載入 EnCodec
model = CompressionModel.get_pretrained('facebook/encodec_32khz')

# 載入音訊
wav, sr = torchaudio.load("audio.wav")

# 確保採樣率正確
if sr != 32000:
    resampler = torchaudio.transforms.Resample(sr, 32000)
    wav = resampler(wav)

# 編碼為標記
with torch.no_grad():
    encoded = model.encode(wav.unsqueeze(0))
    codes = encoded[0]  # 音訊代碼

# 解碼回音訊
with torch.no_grad():
    decoded = model.decode(codes)

torchaudio.save("reconstructed.wav", decoded[0].cpu(), sample_rate=32000)
```

## 常見工作流

### 工作流 1：音樂生成流水線

```python
import torch
import torchaudio
from audiocraft.models import MusicGen

class MusicGenerator:
    def __init__(self, model_name="facebook/musicgen-medium"):
        self.model = MusicGen.get_pretrained(model_name)
        self.sample_rate = 32000

    def generate(self, prompt, duration=30, temperature=1.0, cfg=3.0):
        self.model.set_generation_params(
            duration=duration,
            top_k=250,
            temperature=temperature,
            cfg_coef=cfg
        )

        with torch.no_grad():
            wav = self.model.generate([prompt])

        return wav[0].cpu()

    def generate_batch(self, prompts, duration=30):
        self.model.set_generation_params(duration=duration)

        with torch.no_grad():
            wav = self.model.generate(prompts)

        return wav.cpu()

    def save(self, audio, path):
        torchaudio.save(path, audio, sample_rate=self.sample_rate)

# 使用範例
generator = MusicGenerator()
audio = generator.generate(
    "epic cinematic orchestral music",
    duration=30,
    temperature=1.0
)
generator.save(audio, "epic_music.wav")
```

### 工作流 2：音效設計批次處理

```python
import json
from pathlib import Path
from audiocraft.models import AudioGen
import torchaudio

def batch_generate_sounds(sound_specs, output_dir):
    """
    從規格生成多個聲音。

    Args:
        sound_specs: 包含 {"name": str, "description": str, "duration": float} 的清單
        output_dir: 輸出目錄路徑
    """
    model = AudioGen.get_pretrained('facebook/audiogen-medium')
    output_dir = Path(output_dir)
    output_dir.mkdir(exist_ok=True)

    results = []

    for spec in sound_specs:
        model.set_generation_params(duration=spec.get("duration", 5))

        wav = model.generate([spec["description"]])

        output_path = output_dir / f"{spec['name']}.wav"
        torchaudio.save(str(output_path), wav[0].cpu(), sample_rate=16000)

        results.append({
            "name": spec["name"],
            "path": str(output_path),
            "description": spec["description"]
        })

    return results

# 使用範例
sounds = [
    {"name": "explosion", "description": "massive explosion with debris", "duration": 3},
    {"name": "footsteps", "description": "footsteps on wooden floor", "duration": 5},
    {"name": "door", "description": "wooden door creaking and closing", "duration": 2}
]

results = batch_generate_sounds(sounds, "sound_effects/")
```

### 工作流 3：Gradio 展示

```python
import gradio as gr
import torch
import torchaudio
from audiocraft.models import MusicGen

model = MusicGen.get_pretrained('facebook/musicgen-small')

def generate_music(prompt, duration, temperature, cfg_coef):
    model.set_generation_params(
        duration=duration,
        temperature=temperature,
        cfg_coef=cfg_coef
    )

    with torch.no_grad():
        wav = model.generate([prompt])

    # 儲存至暫存檔
    path = "temp_output.wav"
    torchaudio.save(path, wav[0].cpu(), sample_rate=32000)
    return path

demo = gr.Interface(
    fn=generate_music,
    inputs=[
        gr.Textbox(label="音樂描述", placeholder="upbeat electronic dance music"),
        gr.Slider(1, 30, value=8, label="長度 (秒)"),
        gr.Slider(0.5, 2.0, value=1.0, label="溫度 (Temperature)"),
        gr.Slider(1.0, 10.0, value=3.0, label="CFG 係數")
    ],
    outputs=gr.Audio(label="生成的音樂"),
    title="MusicGen 展示"
)

demo.launch()
```

## 效能最佳化

### 記憶體最佳化

```python
# 使用較小的模型
model = MusicGen.get_pretrained('facebook/musicgen-small')

# 在生成之間清除快取
torch.cuda.empty_cache()

# 生成較短的長度
model.set_generation_params(duration=10)  # 而非 30

# 使用半精度 (Half precision)
model = model.half()
```

### 批次處理效率

```python
# 一次處理多個提示 (效率更高)
descriptions = ["prompt1", "prompt2", "prompt3", "prompt4"]
wav = model.generate(descriptions)  # 單一批次

# 而非
for desc in descriptions:
    wav = model.generate([desc])  # 多個批次 (較慢)
```

### GPU 記憶體需求

| 模型 | FP32 VRAM | FP16 VRAM |
|-------|-----------|-----------|
| musicgen-small | ~4GB | ~2GB |
| musicgen-medium | ~8GB | ~4GB |
| musicgen-large | ~16GB | ~8GB |

## 常見問題

| 問題 | 解決方案 |
|-------|----------|
| CUDA OOM (記憶體不足) | 使用較小模型、縮短生成時間 |
| 品質不佳 | 增加 cfg_coef、改善提示詞 |
| 生成時間太短 | 檢查最高時長設定 |
| 音訊偽影 (Artifacts) | 嘗試不同的溫度 (temperature) |
| 立體聲無效 | 使用立體聲模型變體 |

## 參考資料

- **[進階用法](references/advanced-usage_zh_TW.md)** - 訓練、微調與部署
- **[疑難排解](references/troubleshooting_zh_TW.md)** - 常見問題與解決方案

## 資源

- **GitHub**: https://github.com/facebookresearch/audiocraft
- **論文 (MusicGen)**: https://arxiv.org/abs/2306.05284
- **論文 (AudioGen)**: https://arxiv.org/abs/2209.15352
- **HuggingFace**: https://huggingface.co/facebook/musicgen-small
- **展示 (Demo)**: https://huggingface.co/spaces/facebook/MusicGen
