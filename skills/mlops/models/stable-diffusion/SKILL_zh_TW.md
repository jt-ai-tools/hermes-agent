---
name: stable-diffusion-image-generation
description: 透過 HuggingFace Diffusers 使用 Stable Diffusion 模型進行頂尖的文字轉圖片生成。適用於從文字提示生成圖片、執行圖片轉圖片翻譯、局部重繪 (inpainting) 或構建自定義擴散流水線 (diffusion pipelines)。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [diffusers>=0.30.0, transformers>=4.41.0, accelerate>=0.31.0, torch>=2.0.0]
metadata:
  hermes:
    tags: [Image Generation, Stable Diffusion, Diffusers, Text-to-Image, Multimodal, Computer Vision]

---

# Stable Diffusion 圖片生成

使用 HuggingFace Diffusers 函式庫進行 Stable Diffusion 圖片生成的全面指南。

## 何時使用 Stable Diffusion

**使用 Stable Diffusion 的場景：**
- 從文字描述生成圖片
- 執行圖片轉圖片 (image-to-image) 翻譯（風格轉移、增強）
- 局部重繪 (Inpainting)（填充遮罩區域）
- 向外繪製 (Outpainting)（將圖片擴展至邊界之外）
- 建立現有圖片的變體
- 構建自定義圖片生成工作流

**核心功能：**
- **文字轉圖片 (Text-to-Image)**：從自然語言提示生成圖片
- **圖片轉圖片 (Image-to-Image)**：在文字引導下轉換現有圖片
- **局部重繪 (Inpainting)**：使用上下文感知內容填充遮罩區域
- **ControlNet**：增加空間條件約束（邊緣、姿勢、深度）
- **LoRA 支持**：高效的微調與風格適配
- **多模型支持**：SD 1.5, SDXL, SD 3.0, Flux

**替代方案**：
- **DALL-E 3**: 適用於不需要 GPU 的 API 型生成
- **Midjourney**: 適用於藝術化、風格化的輸出
- **Imagen**: 適用於 Google Cloud 整合
- **Leonardo.ai**: 適用於基於網頁的創意工作流

## 快速開始

### 安裝

```bash
pip install diffusers transformers accelerate torch
pip install xformers  # 選配：記憶體高效的注意力機制 (memory-efficient attention)
```

### 基礎文字轉圖片

```python
from diffusers import DiffusionPipeline
import torch

# 載入流水線 (pipeline)（自動偵測模型類型）
pipe = DiffusionPipeline.from_pretrained(
    "stable-diffusion-v1-5/stable-diffusion-v1-5",
    torch_dtype=torch.float16
)
pipe.to("cuda")

# 生成圖片
image = pipe(
    "A serene mountain landscape at sunset, highly detailed",
    num_inference_steps=50,
    guidance_scale=7.5
).images[0]

image.save("output.png")
```

### 使用 SDXL (更高品質)

```python
from diffusers import AutoPipelineForText2Image
import torch

pipe = AutoPipelineForText2Image.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0",
    torch_dtype=torch.float16,
    variant="fp16"
)
pipe.to("cuda")

# 啟用記憶體優化
pipe.enable_model_cpu_offload()

image = pipe(
    prompt="A futuristic city with flying cars, cinematic lighting",
    height=1024,
    width=1024,
    num_inference_steps=30
).images[0]
```

## 架構概覽

### 三大支柱設計

Diffusers 圍繞三個核心組件構建：

```
Pipeline (流水線 - 編排)
├── Model (模型 - 神經網路)
│   ├── UNet / Transformer (雜訊預測)
│   ├── VAE (潛在空間編碼/解碼)
│   └── Text Encoder (文字編碼器 - CLIP/T5)
└── Scheduler (排程器 - 去噪演算法)
```

### 流水線推論流程

```
文字提示 → 文字編碼器 → 文字嵌入 (Text Embeddings)
                                    ↓
隨機雜訊 → [去噪迴圈 (Denoising Loop)] ← 排程器
                      ↓
               預測雜訊
                      ↓
              VAE 解碼器 → 最終圖片
```

## 核心概念

### 流水線 (Pipelines)

流水線編排完整的工作流：

| 流水線 | 用途 |
|----------|---------|
| `StableDiffusionPipeline` | 文字轉圖片 (SD 1.x/2.x) |
| `StableDiffusionXLPipeline` | 文字轉圖片 (SDXL) |
| `StableDiffusion3Pipeline` | 文字轉圖片 (SD 3.0) |
| `FluxPipeline` | 文字轉圖片 (Flux 模型) |
| `StableDiffusionImg2ImgPipeline` | 圖片轉圖片 |
| `StableDiffusionInpaintPipeline` | 局部重繪 |

### 排程器 (Schedulers)

排程器控制去噪過程：

| 排程器 | 步數 | 品質 | 使用場景 |
|-----------|-------|---------|----------|
| `EulerDiscreteScheduler` | 20-50 | 好 | 預設選擇 |
| `EulerAncestralDiscreteScheduler` | 20-50 | 好 | 更多變體 |
| `DPMSolverMultistepScheduler` | 15-25 | 優異 | 快速且高品質 |
| `DDIMScheduler` | 50-100 | 好 | 確定性輸出 |
| `LCMScheduler` | 4-8 | 好 | 極速 |
| `UniPCMultistepScheduler` | 15-25 | 優異 | 快速收斂 |

### 更換排程器

```python
from diffusers import DPMSolverMultistepScheduler

# 更換以獲得更快的生成速度
pipe.scheduler = DPMSolverMultistepScheduler.from_config(
    pipe.scheduler.config
)

# 現在可以使用較少的步數進行生成
image = pipe(prompt, num_inference_steps=20).images[0]
```

## 生成參數

### 關鍵參數

| 參數 | 預設值 | 描述 |
|-----------|---------|-------------|
| `prompt` | 必填 | 所需圖片的文字描述 |
| `negative_prompt` | 無 | 圖片中要避免出現的內容 |
| `num_inference_steps` | 50 | 去噪步數（越多 = 品質越好） |
| `guidance_scale` | 7.5 | 提示詞遵從度（通常為 7-12） |
| `height`, `width` | 512/1024 | 輸出尺寸（8 的倍數） |
| `generator` | 無 | 用於可重現生成的 Torch 生成器 |
| `num_images_per_prompt` | 1 | 批次大小 |

### 可重現的生成

```python
import torch

generator = torch.Generator(device="cuda").manual_seed(42)

image = pipe(
    prompt="A cat wearing a top hat",
    generator=generator,
    num_inference_steps=50
).images[0]
```

### 負面提示 (Negative prompts)

```python
image = pipe(
    prompt="Professional photo of a dog in a garden",
    negative_prompt="blurry, low quality, distorted, ugly, bad anatomy",
    guidance_scale=7.5
).images[0]
```

## 圖片轉圖片 (Image-to-image)

在文字引導下轉換現有圖片：

```python
from diffusers import AutoPipelineForImage2Image
from PIL import Image

pipe = AutoPipelineForImage2Image.from_pretrained(
    "stable-diffusion-v1-5/stable-diffusion-v1-5",
    torch_dtype=torch.float16
).to("cuda")

init_image = Image.open("input.jpg").resize((512, 512))

image = pipe(
    prompt="A watercolor painting of the scene",
    image=init_image,
    strength=0.75,  # 轉換強度 (0-1)
    num_inference_steps=50
).images[0]
```

## 局部重繪 (Inpainting)

填充遮罩區域：

```python
from diffusers import AutoPipelineForInpainting
from PIL import Image

pipe = AutoPipelineForInpainting.from_pretrained(
    "runwayml/stable-diffusion-inpainting",
    torch_dtype=torch.float16
).to("cuda")

image = Image.open("photo.jpg")
mask = Image.open("mask.png")  # 白色 = 重繪區域

result = pipe(
    prompt="A red car parked on the street",
    image=image,
    mask_image=mask,
    num_inference_steps=50
).images[0]
```

## ControlNet

增加空間條件以實現精確控制：

```python
from diffusers import StableDiffusionControlNetPipeline, ControlNetModel
import torch

# 載入用於邊緣條件的 ControlNet
controlnet = ControlNetModel.from_pretrained(
    "lllyasviel/control_v11p_sd15_canny",
    torch_dtype=torch.float16
)

pipe = StableDiffusionControlNetPipeline.from_pretrained(
    "stable-diffusion-v1-5/stable-diffusion-v1-5",
    controlnet=controlnet,
    torch_dtype=torch.float16
).to("cuda")

# 使用 Canny 邊緣圖作為控制
control_image = get_canny_image(input_image)

image = pipe(
    prompt="A beautiful house in the style of Van Gogh",
    image=control_image,
    num_inference_steps=30
).images[0]
```

### 可用的 ControlNet

| ControlNet | 輸入類型 | 使用場景 |
|------------|------------|----------|
| `canny` | 邊緣圖 | 保留結構 |
| `openpose` | 姿勢骨架 | 人體姿勢 |
| `depth` | 深度圖 | 3D 感知生成 |
| `normal` | 法線圖 | 表面細節 |
| `mlsd` | 線段 | 建築線條 |
| `scribble` | 粗糙草稿 | 草稿轉圖片 |

## LoRA 適配器

載入微調過的風格適配器：

```python
from diffusers import DiffusionPipeline

pipe = DiffusionPipeline.from_pretrained(
    "stable-diffusion-v1-5/stable-diffusion-v1-5",
    torch_dtype=torch.float16
).to("cuda")

# 載入 LoRA 權重
pipe.load_lora_weights("path/to/lora", weight_name="style.safetensors")

# 使用 LoRA 風格生成
image = pipe("A portrait in the trained style").images[0]

# 調整 LoRA 強度
pipe.fuse_lora(lora_scale=0.8)

# 卸載 LoRA
pipe.unload_lora_weights()
```

### 多個 LoRA

```python
# 載入多個 LoRA
pipe.load_lora_weights("lora1", adapter_name="style")
pipe.load_lora_weights("lora2", adapter_name="character")

# 為每個適配器設置權重
pipe.set_adapters(["style", "character"], adapter_weights=[0.7, 0.5])

image = pipe("A portrait").images[0]
```

## 記憶體優化

### 啟用 CPU 卸載 (Offloading)

```python
# 模型 CPU 卸載 - 不使用時將模型移至 CPU
pipe.enable_model_cpu_offload()

# 順序 CPU 卸載 - 更激進，但速度較慢
pipe.enable_sequential_cpu_offload()
```

### 注意力分塊 (Attention slicing)

```python
# 通過分塊計算注意力來減少記憶體使用
pipe.enable_attention_slicing()

# 或指定區塊大小
pipe.enable_attention_slicing("max")
```

### xFormers 記憶體高效注意力

```python
# 需要 xformers 套件
pipe.enable_xformers_memory_efficient_attention()
```

### 大型圖片的 VAE 分塊

```python
# 對於大型圖片，採用平鋪方式解碼潛在變數
pipe.enable_vae_slicing()
pipe.enable_vae_tiling()
```

## 模型變體

### 載入不同精度

```python
# FP16 (建議用於 GPU)
pipe = DiffusionPipeline.from_pretrained(
    "model-id",
    torch_dtype=torch.float16,
    variant="fp16"
)

# BF16 (更好的精度，需要 Ampere 或更新架構的 GPU)
pipe = DiffusionPipeline.from_pretrained(
    "model-id",
    torch_dtype=torch.bfloat16
)
```

### 載入特定組件

```python
from diffusers import UNet2DConditionModel, AutoencoderKL

# 載入自定義 VAE
vae = AutoencoderKL.from_pretrained("stabilityai/sd-vae-ft-mse")

# 在流水線中使用
pipe = DiffusionPipeline.from_pretrained(
    "stable-diffusion-v1-5/stable-diffusion-v1-5",
    vae=vae,
    torch_dtype=torch.float16
)
```

## 批次生成

高效生成多張圖片：

```python
# 多個提示詞
prompts = [
    "A cat playing piano",
    "A dog reading a book",
    "A bird painting a picture"
]

images = pipe(prompts, num_inference_steps=30).images

# 每個提示詞生成多張圖片
images = pipe(
    "A beautiful sunset",
    num_images_per_prompt=4,
    num_inference_steps=30
).images
```

## 常見工作流

### 工作流 1：高品質生成

```python
from diffusers import StableDiffusionXLPipeline, DPMSolverMultistepScheduler
import torch

# 1. 載入帶優化的 SDXL
pipe = StableDiffusionXLPipeline.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0",
    torch_dtype=torch.float16,
    variant="fp16"
)
pipe.to("cuda")
pipe.scheduler = DPMSolverMultistepScheduler.from_config(pipe.scheduler.config)
pipe.enable_model_cpu_offload()

# 2. 使用品質設定進行生成
image = pipe(
    prompt="A majestic lion in the savanna, golden hour lighting, 8k, detailed fur",
    negative_prompt="blurry, low quality, cartoon, anime, sketch",
    num_inference_steps=30,
    guidance_scale=7.5,
    height=1024,
    width=1024
).images[0]
```

### 工作流 2：快速原型開發

```python
from diffusers import AutoPipelineForText2Image, LCMScheduler
import torch

# 使用 LCM 進行 4-8 步生成
pipe = AutoPipelineForText2Image.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0",
    torch_dtype=torch.float16
).to("cuda")

# 載入 LCM LoRA 以實現快速生成
pipe.load_lora_weights("latent-consistency/lcm-lora-sdxl")
pipe.scheduler = LCMScheduler.from_config(pipe.scheduler.config)
pipe.fuse_lora()

# 在約 1 秒內生成
image = pipe(
    "A beautiful landscape",
    num_inference_steps=4,
    guidance_scale=1.0
).images[0]
```

## 常見問題

**CUDA 記憶體不足 (Out of memory)：**
```python
# 啟用記憶體優化
pipe.enable_model_cpu_offload()
pipe.enable_attention_slicing()
pipe.enable_vae_slicing()

# 或使用較低精度
pipe = DiffusionPipeline.from_pretrained(model_id, torch_dtype=torch.float16)
```

**黑圖或純雜訊圖片：**
```python
# 檢查 VAE 配置
# 如果需要，繞過安全檢查器 (safety checker)
pipe.safety_checker = None

# 確保資料類型 (dtype) 的一致性
pipe = pipe.to(dtype=torch.float16)
```

**生成速度慢：**
```python
# 使用更快的排程器
from diffusers import DPMSolverMultistepScheduler
pipe.scheduler = DPMSolverMultistepScheduler.from_config(pipe.scheduler.config)

# 減少步數
image = pipe(prompt, num_inference_steps=20).images[0]
```

## 參考資料

- **[進階用法](references/advanced-usage_zh_TW.md)** - 自定義流水線、微調、佈署
- **[故障排除](references/troubleshooting_zh_TW.md)** - 常見問題與解決方案

## 資源

- **文件**: https://huggingface.co/docs/diffusers
- **儲存庫**: https://github.com/huggingface/diffusers
- **模型中心 (Model Hub)**: https://huggingface.co/models?library=diffusers
- **Discord**: https://discord.gg/diffusers
