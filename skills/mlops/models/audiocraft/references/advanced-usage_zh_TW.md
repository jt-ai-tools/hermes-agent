# AudioCraft 進階使用指南

## 微調 (Fine-tuning) MusicGen

### 自定義資料集準備

```python
import os
import json
from pathlib import Path
import torchaudio

def prepare_dataset(audio_dir, output_dir, metadata_file):
    """
    準備用於 MusicGen 微調的資料集。

    目錄結構：
    output_dir/
    ├── audio/
    │   ├── 0001.wav
    │   ├── 0002.wav
    │   └── ...
    └── metadata.json
    """
    output_dir = Path(output_dir)
    audio_output = output_dir / "audio"
    audio_output.mkdir(parents=True, exist_ok=True)

    # 載入元數據 (格式: {"path": "...", "description": "..."})
    with open(metadata_file) as f:
        metadata = json.load(f)

    processed = []

    for idx, item in enumerate(metadata):
        audio_path = Path(audio_dir) / item["path"]

        # 載入並重採樣至 32kHz
        wav, sr = torchaudio.load(str(audio_path))
        if sr != 32000:
            resampler = torchaudio.transforms.Resample(sr, 32000)
            wav = resampler(wav)

        # 若為立體聲則轉換為單聲道
        if wav.shape[0] > 1:
            wav = wav.mean(dim=0, keepdim=True)

        # 儲存處理後的音訊
        output_path = audio_output / f"{idx:04d}.wav"
        torchaudio.save(str(output_path), wav, sample_rate=32000)

        processed.append({
            "path": str(output_path.relative_to(output_dir)),
            "description": item["description"],
            "duration": wav.shape[1] / 32000
        })

    # 儲存處理後的元數據
    with open(output_dir / "metadata.json", "w") as f:
        json.dump(processed, f, indent=2)

    print(f"已處理 {len(processed)} 個樣本")
    return processed
```

### 使用 dora 進行微調

```bash
# AudioCraft 使用 dora 進行實驗管理
# 安裝 dora
pip install dora-search

# 複製 AudioCraft
git clone https://github.com/facebookresearch/audiocraft.git
cd audiocraft

# 建立微調配置
cat > config/solver/musicgen/finetune.yaml << 'EOF'
defaults:
  - musicgen/musicgen_base
  - /model: lm/musicgen_lm
  - /conditioner: cond_base

solver: musicgen
autocast: true
autocast_dtype: float16

optim:
  epochs: 100
  batch_size: 4
  lr: 1e-4
  ema: 0.999
  optimizer: adamw

dataset:
  batch_size: 4
  num_workers: 4
  train:
    - dset: your_dataset
      root: /path/to/dataset
  valid:
    - dset: your_dataset
      root: /path/to/dataset

checkpoint:
  save_every: 10
  keep_every_states: null
EOF

# 執行微調
dora run solver=musicgen/finetune
```

### LoRA 微調

```python
from peft import LoraConfig, get_peft_model
from audiocraft.models import MusicGen
import torch

# 載入基礎模型
model = MusicGen.get_pretrained('facebook/musicgen-small')

# 獲取語言模型組件
lm = model.lm

# 配置 LoRA
lora_config = LoraConfig(
    r=8,
    lora_alpha=16,
    target_modules=["q_proj", "v_proj", "k_proj", "out_proj"],
    lora_dropout=0.05,
    bias="none"
)

# 應用 LoRA
lm = get_peft_model(lm, lora_config)
lm.print_trainable_parameters()
```

## 多 GPU 訓練

### DataParallel

```python
import torch
import torch.nn as nn
from audiocraft.models import MusicGen

model = MusicGen.get_pretrained('facebook/musicgen-small')

# 使用 DataParallel 包裝語言模型
if torch.cuda.device_count() > 1:
    model.lm = nn.DataParallel(model.lm)

model.to("cuda")
```

### DistributedDataParallel

```python
import torch.distributed as dist
from torch.nn.parallel import DistributedDataParallel as DDP

def setup(rank, world_size):
    dist.init_process_group("nccl", rank=rank, world_size=world_size)
    torch.cuda.set_device(rank)

def train(rank, world_size):
    setup(rank, world_size)

    model = MusicGen.get_pretrained('facebook/musicgen-small')
    model.lm = model.lm.to(rank)
    model.lm = DDP(model.lm, device_ids=[rank])

    # 訓練迴圈
    # ...

    dist.destroy_process_group()
```

## 自定義條件化 (Custom Conditioning)

### 新增條件化器 (Conditioners)

```python
from audiocraft.modules.conditioners import BaseConditioner
import torch

class CustomConditioner(BaseConditioner):
    """用於額外控制訊號的自定義條件化器。"""

    def __init__(self, dim, output_dim):
        super().__init__(dim, output_dim)
        self.embed = torch.nn.Linear(dim, output_dim)

    def forward(self, x):
        return self.embed(x)

    def tokenize(self, x):
        # 將條件輸入標記化
        return x

# 與 MusicGen 一起使用
from audiocraft.models.builders import get_lm_model

# 修改模型配置以包含自定義條件化器
# 這需要編輯模型配置檔案
```

### 旋律條件化內部原理

```python
from audiocraft.models import MusicGen
from audiocraft.modules.codebooks_patterns import DelayedPatternProvider
import torch

model = MusicGen.get_pretrained('facebook/musicgen-melody')

# 存取色度特徵 (Chroma) 提取器
chroma_extractor = model.lm.condition_provider.conditioners.get('chroma')

# 手動色度特徵提取
def extract_chroma(audio, sr):
    """從音訊中提取色度特徵。"""
    import librosa

    # 計算色度
    chroma = librosa.feature.chroma_cqt(y=audio.numpy(), sr=sr)

    return torch.from_numpy(chroma).float()

# 使用提取的色度進行條件化
chroma = extract_chroma(melody_audio, sample_rate)
```

## EnCodec 深入解析

### 自定義壓縮設定

```python
from audiocraft.models import CompressionModel
import torch

# 載入 EnCodec
encodec = CompressionModel.get_pretrained('facebook/encodec_32khz')

# 存取編解碼器參數
print(f"採樣率: {encodec.sample_rate}")
print(f"通道數: {encodec.channels}")
print(f"基數 (Cardinality): {encodec.cardinality}")  # 代碼簿大小
print(f"代碼簿數量: {encodec.num_codebooks}")
print(f"幀率 (Frame rate): {encodec.frame_rate}")

# 設定特定頻寬進行編碼
# 較低頻寬 = 壓縮率較高，品質較低
encodec.set_target_bandwidth(6.0)  # 6 kbps

audio = torch.randn(1, 1, 32000)  # 1 秒
encoded = encodec.encode(audio)
decoded = encodec.decode(encoded[0])
```

### 串流編碼 (Streaming encoding)

```python
import torch
from audiocraft.models import CompressionModel

encodec = CompressionModel.get_pretrained('facebook/encodec_32khz')

def encode_streaming(audio_stream, chunk_size=32000):
    """以串流方式編碼音訊。"""
    all_codes = []

    for chunk in audio_stream:
        # 確保 chunk 形狀正確
        if chunk.dim() == 1:
            chunk = chunk.unsqueeze(0).unsqueeze(0)

        with torch.no_grad():
            codes = encodec.encode(chunk)[0]
            all_codes.append(codes)

    return torch.cat(all_codes, dim=-1)

def decode_streaming(codes_stream, output_stream):
    """以串流方式解碼代碼。"""
    for codes in codes_stream:
        with torch.no_grad():
            audio = encodec.decode(codes)
            output_stream.write(audio.cpu().numpy())
```

## 多頻段擴散 (MultiBand Diffusion)

### 使用 MBD 增強品質

```python
from audiocraft.models import MusicGen, MultiBandDiffusion

# 載入 MusicGen
model = MusicGen.get_pretrained('facebook/musicgen-medium')

# 載入 MultiBand Diffusion
mbd = MultiBandDiffusion.get_mbd_musicgen()

model.set_generation_params(duration=10)

# 使用標準解碼器生成
descriptions = ["epic orchestral music"]
wav_standard = model.generate(descriptions)

# 生成標記並使用 MBD 解碼器
with torch.no_grad():
    # 獲取標記
    gen_tokens = model.generate_tokens(descriptions)

    # 使用 MBD 解碼
    wav_mbd = mbd.tokens_to_wav(gen_tokens)

# 比較品質
print(f"標準解碼形狀: {wav_standard.shape}")
print(f"MBD 解碼形狀: {wav_mbd.shape}")
```

## API 伺服器部署

### FastAPI 伺服器

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import torch
import torchaudio
from audiocraft.models import MusicGen
import io
import base64

app = FastAPI()

# 啟動時載入模型
model = None

@app.on_event("startup")
async def load_model():
    global model
    model = MusicGen.get_pretrained('facebook/musicgen-small')
    model.set_generation_params(duration=10)

class GenerateRequest(BaseModel):
    prompt: str
    duration: float = 10.0
    temperature: float = 1.0
    cfg_coef: float = 3.0

class GenerateResponse(BaseModel):
    audio_base64: str
    sample_rate: int
    duration: float

@app.post("/generate", response_model=GenerateResponse)
async def generate(request: GenerateRequest):
    if model is None:
        raise HTTPException(status_code=500, detail="模型未載入")

    try:
        model.set_generation_params(
            duration=min(request.duration, 30),
            temperature=request.temperature,
            cfg_coef=request.cfg_coef
        )

        with torch.no_grad():
            wav = model.generate([request.prompt])

        # 轉換為位元組
        buffer = io.BytesIO()
        torchaudio.save(buffer, wav[0].cpu(), sample_rate=32000, format="wav")
        buffer.seek(0)

        audio_base64 = base64.b64encode(buffer.read()).decode()

        return GenerateResponse(
            audio_base64=audio_base64,
            sample_rate=32000,
            duration=wav.shape[-1] / 32000
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    return {"status": "ok", "model_loaded": model is not None}

# 執行: uvicorn server:app --host 0.0.0.0 --port 8000
```

### 批次處理服務

```python
import asyncio
from concurrent.futures import ThreadPoolExecutor
import torch
from audiocraft.models import MusicGen

class MusicGenService:
    def __init__(self, model_name='facebook/musicgen-small', max_workers=2):
        self.model = MusicGen.get_pretrained(model_name)
        self.executor = ThreadPoolExecutor(max_workers=max_workers)
        self.lock = asyncio.Lock()

    async def generate_async(self, prompt, duration=10):
        """使用執行緒池進行非同步生成。"""
        loop = asyncio.get_event_loop()

        def _generate():
            with torch.no_grad():
                self.model.set_generation_params(duration=duration)
                return self.model.generate([prompt])

        # 在執行緒池中執行
        wav = await loop.run_in_executor(self.executor, _generate)
        return wav[0].cpu()

    async def generate_batch_async(self, prompts, duration=10):
        """同時處理多個提示。"""
        tasks = [self.generate_async(p, duration) for p in prompts]
        return await asyncio.gather(*tasks)

# 使用範例
service = MusicGenService()

async def main():
    prompts = ["jazz piano", "rock guitar", "electronic beats"]
    results = await service.generate_batch_async(prompts)
    return results
```

## 整合模式

### LangChain 工具

```python
from langchain.tools import BaseTool
import torch
import torchaudio
from audiocraft.models import MusicGen
import tempfile

class MusicGeneratorTool(BaseTool):
    name = "music_generator"
    description = "從文字描述生成音樂。輸入應為關於音樂風格、情緒和樂器的詳細描述。"

    def __init__(self):
        super().__init__()
        self.model = MusicGen.get_pretrained('facebook/musicgen-small')
        self.model.set_generation_params(duration=15)

    def _run(self, description: str) -> str:
        with torch.no_grad():
            wav = self.model.generate([description])

        # 儲存至暫存檔
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
            torchaudio.save(f.name, wav[0].cpu(), sample_rate=32000)
            return f"產生的音樂已儲存至: {f.name}"

    async def _arun(self, description: str) -> str:
        return self._run(description)
```

### 具備進階控制項的 Gradio

```python
import gradio as gr
import torch
import torchaudio
from audiocraft.models import MusicGen

models = {}

def load_model(model_size):
    if model_size not in models:
        model_name = f"facebook/musicgen-{model_size}"
        models[model_size] = MusicGen.get_pretrained(model_name)
    return models[model_size]

def generate(prompt, duration, temperature, cfg_coef, top_k, model_size):
    model = load_model(model_size)

    model.set_generation_params(
        duration=duration,
        temperature=temperature,
        cfg_coef=cfg_coef,
        top_k=top_k
    )

    with torch.no_grad():
        wav = model.generate([prompt])

    # 儲存
    path = "output.wav"
    torchaudio.save(path, wav[0].cpu(), sample_rate=32000)
    return path

demo = gr.Interface(
    fn=generate,
    inputs=[
        gr.Textbox(label="提示詞 (Prompt)", lines=3),
        gr.Slider(1, 30, value=10, label="時長 (秒)"),
        gr.Slider(0.1, 2.0, value=1.0, label="溫度 (Temperature)"),
        gr.Slider(0.5, 10.0, value=3.0, label="CFG 係數"),
        gr.Slider(50, 500, value=250, step=50, label="Top-K"),
        gr.Dropdown(["small", "medium", "large"], value="small", label="模型大小")
    ],
    outputs=gr.Audio(label="生成的音樂"),
    title="MusicGen 進階版",
    allow_flagging="never"
)

demo.launch(share=True)
```

## 音訊處理流水線

### 後處理鏈 (Post-processing chain)

```python
import torch
import torchaudio
import torchaudio.transforms as T
import numpy as np

class AudioPostProcessor:
    def __init__(self, sample_rate=32000):
        self.sample_rate = sample_rate

    def normalize(self, audio, target_db=-14.0):
        """將音訊標準化至目標響度。"""
        rms = torch.sqrt(torch.mean(audio ** 2))
        target_rms = 10 ** (target_db / 20)
        gain = target_rms / (rms + 1e-8)
        return audio * gain

    def fade_in_out(self, audio, fade_duration=0.1):
        """套用淡入/淡出。"""
        fade_samples = int(fade_duration * self.sample_rate)

        # 建立淡化曲線
        fade_in = torch.linspace(0, 1, fade_samples)
        fade_out = torch.linspace(1, 0, fade_samples)

        # 套用淡化
        audio[..., :fade_samples] *= fade_in
        audio[..., -fade_samples:] *= fade_out

        return audio

    def apply_reverb(self, audio, decay=0.5):
        """套用簡單的混響 (Reverb) 效果。"""
        impulse = torch.zeros(int(self.sample_rate * 0.5))
        impulse[0] = 1.0
        impulse[int(self.sample_rate * 0.1)] = decay * 0.5
        impulse[int(self.sample_rate * 0.2)] = decay * 0.25

        # 卷積處理
        audio = torch.nn.functional.conv1d(
            audio.unsqueeze(0),
            impulse.unsqueeze(0).unsqueeze(0),
            padding=len(impulse) // 2
        ).squeeze(0)

        return audio

    def process(self, audio):
        """完整的處理流水線。"""
        audio = self.normalize(audio)
        audio = self.fade_in_out(audio)
        return audio

# 與 MusicGen 一起使用
from audiocraft.models import MusicGen

model = MusicGen.get_pretrained('facebook/musicgen-small')
model.set_generation_params(duration=10)

wav = model.generate(["chill ambient music"])
processor = AudioPostProcessor()
wav_processed = processor.process(wav[0].cpu())

torchaudio.save("processed.wav", wav_processed, sample_rate=32000)
```

## 評估

### 音訊品質指標

```python
import torch
from audiocraft.metrics import CLAPTextConsistencyMetric
from audiocraft.data.audio import audio_read

def evaluate_generation(audio_path, text_prompt):
    """評估生成的音訊品質。"""
    # 載入音訊
    wav, sr = audio_read(audio_path)

    # CLAP 一致性 (文字-音訊對齊度)
    clap_metric = CLAPTextConsistencyMetric()
    clap_score = clap_metric.compute(wav, [text_prompt])

    return {
        "clap_score": clap_score,
        "duration": wav.shape[-1] / sr
    }

# 批次評估
def evaluate_batch(generations):
    """評估多個生成結果。"""
    results = []
    for gen in generations:
        result = evaluate_generation(gen["path"], gen["prompt"])
        result["prompt"] = gen["prompt"]
        results.append(result)

    # 彙整
    avg_clap = sum(r["clap_score"] for r in results) / len(results)
    return {
        "individual": results,
        "average_clap": avg_clap
    }
```

## 模型比較

### MusicGen 變體基準測試

| 模型 | CLAP 分數 | 生成時間 (10秒) | VRAM |
|-------|------------|----------------------|------|
| musicgen-small | 0.35 | ~5秒 | 2GB |
| musicgen-medium | 0.42 | ~15秒 | 4GB |
| musicgen-large | 0.48 | ~30秒 | 8GB |
| musicgen-melody | 0.45 | ~15秒 | 4GB |
| musicgen-stereo-medium | 0.41 | ~18秒 | 5GB |

### 提示工程 (Prompt engineering) 技巧

```python
# 好的提示詞 - 具體且描述詳盡
good_prompts = [
    "upbeat electronic dance music with synthesizer leads and punchy drums at 128 bpm",
    "melancholic piano ballad with strings, slow tempo, emotional and cinematic",
    "funky disco groove with slap bass, brass section, and rhythmic guitar"
]

# 壞的提示詞 - 太過模糊
bad_prompts = [
    "nice music",
    "song",
    "good beat"
]

# 結構: [情緒/氣氛] [類型] 搭配 [樂器] 於 [節奏/風格]
```
