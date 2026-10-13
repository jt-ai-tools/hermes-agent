# Stable Diffusion 進階用法指南

## 自定義流水線 (Custom Pipelines)

### 從組件構建

```python
from diffusers import (
    UNet2DConditionModel,
    AutoencoderKL,
    DDPMScheduler,
    StableDiffusionPipeline
)
from transformers import CLIPTextModel, CLIPTokenizer
import torch

# 單獨載入組件
unet = UNet2DConditionModel.from_pretrained(
    "stable-diffusion-v1-5/stable-diffusion-v1-5",
    subfolder="unet"
)
vae = AutoencoderKL.from_pretrained(
    "stable-diffusion-v1-5/stable-diffusion-v1-5",
    subfolder="vae"
)
text_encoder = CLIPTextModel.from_pretrained(
    "stable-diffusion-v1-5/stable-diffusion-v1-5",
    subfolder="text_encoder"
)
tokenizer = CLIPTokenizer.from_pretrained(
    "stable-diffusion-v1-5/stable-diffusion-v1-5",
    subfolder="tokenizer"
)
scheduler = DDPMScheduler.from_pretrained(
    "stable-diffusion-v1-5/stable-diffusion-v1-5",
    subfolder="scheduler"
)

# 組裝流水線
pipe = StableDiffusionPipeline(
    unet=unet,
    vae=vae,
    text_encoder=text_encoder,
    tokenizer=tokenizer,
    scheduler=scheduler,
    safety_checker=None,
    feature_extractor=None,
    requires_safety_checker=False
)
```

### 自定義去噪迴圈 (Custom denoising loop)

```python
from diffusers import DDIMScheduler, AutoencoderKL, UNet2DConditionModel
from transformers import CLIPTextModel, CLIPTokenizer
import torch

def custom_generate(
    prompt: str,
    num_steps: int = 50,
    guidance_scale: float = 7.5,
    height: int = 512,
    width: int = 512
):
    # 載入組件
    tokenizer = CLIPTokenizer.from_pretrained("openai/clip-vit-large-patch14")
    text_encoder = CLIPTextModel.from_pretrained("openai/clip-vit-large-patch14")
    unet = UNet2DConditionModel.from_pretrained("sd-model", subfolder="unet")
    vae = AutoencoderKL.from_pretrained("sd-model", subfolder="vae")
    scheduler = DDIMScheduler.from_pretrained("sd-model", subfolder="scheduler")

    device = "cuda"
    text_encoder.to(device)
    unet.to(device)
    vae.to(device)

    # 編碼提示詞
    text_input = tokenizer(
        prompt,
        padding="max_length",
        max_length=77,
        truncation=True,
        return_tensors="pt"
    )
    text_embeddings = text_encoder(text_input.input_ids.to(device))[0]

    # 無條件嵌入，用於無分類器引導 (classifier-free guidance)
    uncond_input = tokenizer(
        "",
        padding="max_length",
        max_length=77,
        return_tensors="pt"
    )
    uncond_embeddings = text_encoder(uncond_input.input_ids.to(device))[0]

    # 連接以進行批次處理
    text_embeddings = torch.cat([uncond_embeddings, text_embeddings])

    # 初始化潛在變數 (latents)
    latents = torch.randn(
        (1, 4, height // 8, width // 8),
        device=device
    )
    latents = latents * scheduler.init_noise_sigma

    # 去噪迴圈
    scheduler.set_timesteps(num_steps)
    for t in scheduler.timesteps:
        latent_model_input = torch.cat([latents] * 2)
        latent_model_input = scheduler.scale_model_input(latent_model_input, t)

        # 預測雜訊
        with torch.no_grad():
            noise_pred = unet(
                latent_model_input,
                t,
                encoder_hidden_states=text_embeddings
            ).sample

        # 無分類器引導
        noise_pred_uncond, noise_pred_cond = noise_pred.chunk(2)
        noise_pred = noise_pred_uncond + guidance_scale * (
            noise_pred_cond - noise_pred_uncond
        )

        # 更新潛在變數
        latents = scheduler.step(noise_pred, t, latents).prev_sample

    # 解碼潛在變數
    latents = latents / vae.config.scaling_factor
    with torch.no_grad():
        image = vae.decode(latents).sample

    # 轉換為 PIL
    image = (image / 2 + 0.5).clamp(0, 1)
    image = image.cpu().permute(0, 2, 3, 1).numpy()
    image = (image * 255).round().astype("uint8")[0]

    return Image.fromarray(image)
```

## IP-Adapter

將圖片提示詞與文字結合使用：

```python
from diffusers import StableDiffusionPipeline
from diffusers.utils import load_image
import torch

pipe = StableDiffusionPipeline.from_pretrained(
    "stable-diffusion-v1-5/stable-diffusion-v1-5",
    torch_dtype=torch.float16
).to("cuda")

# 載入 IP-Adapter
pipe.load_ip_adapter(
    "h94/IP-Adapter",
    subfolder="models",
    weight_name="ip-adapter_sd15.bin"
)

# 設置 IP-Adapter 權重
pipe.set_ip_adapter_scale(0.6)

# 載入參考圖片
ip_image = load_image("reference_style.jpg")

# 使用圖片 + 文字提示生成
image = pipe(
    prompt="A portrait in a garden",
    ip_adapter_image=ip_image,
    num_inference_steps=50
).images[0]
```

### 多張 IP-Adapter 圖片

```python
# 使用多張參考圖片
pipe.set_ip_adapter_scale([0.5, 0.7])

images = [
    load_image("style_reference.jpg"),
    load_image("composition_reference.jpg")
]

result = pipe(
    prompt="A landscape painting",
    ip_adapter_image=images,
    num_inference_steps=50
).images[0]
```

## SDXL 精煉器 (Refiner)

兩階段生成以獲得更高品質：

```python
from diffusers import StableDiffusionXLPipeline, StableDiffusionXLImg2ImgPipeline
import torch

# 載入基礎模型 (base model)
base = StableDiffusionXLPipeline.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0",
    torch_dtype=torch.float16,
    variant="fp16"
).to("cuda")

# 載入精煉器 (refiner)
refiner = StableDiffusionXLImg2ImgPipeline.from_pretrained(
    "stabilityai/stable-diffusion-xl-refiner-1.0",
    torch_dtype=torch.float16,
    variant="fp16"
).to("cuda")

# 使用基礎模型生成（部分去噪）
image = base(
    prompt="A majestic eagle soaring over mountains",
    num_inference_steps=40,
    denoising_end=0.8,
    output_type="latent"
).images

# 使用精煉器進行精煉
refined = refiner(
    prompt="A majestic eagle soaring over mountains",
    image=image,
    num_inference_steps=40,
    denoising_start=0.8
).images[0]
```

## T2I-Adapter

比 ControlNet 更輕量化的條件約束：

```python
from diffusers import StableDiffusionXLAdapterPipeline, T2IAdapter
import torch

# 載入適配器
adapter = T2IAdapter.from_pretrained(
    "TencentARC/t2i-adapter-canny-sdxl-1.0",
    torch_dtype=torch.float16
)

pipe = StableDiffusionXLAdapterPipeline.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0",
    adapter=adapter,
    torch_dtype=torch.float16
).to("cuda")

# 獲取 Canny 邊緣
canny_image = get_canny_image(input_image)

image = pipe(
    prompt="A colorful anime character",
    image=canny_image,
    num_inference_steps=30,
    adapter_conditioning_scale=0.8
).images[0]
```

## 使用 DreamBooth 進行微調

在自定義主題上進行訓練：

```python
from diffusers import StableDiffusionPipeline, DDPMScheduler
from diffusers.optimization import get_scheduler
import torch
from torch.utils.data import Dataset, DataLoader
from PIL import Image
import os

class DreamBoothDataset(Dataset):
    def __init__(self, instance_images_path, instance_prompt, tokenizer, size=512):
        self.instance_images_path = instance_images_path
        self.instance_prompt = instance_prompt
        self.tokenizer = tokenizer
        self.size = size

        self.instance_images = [
            os.path.join(instance_images_path, f)
            for f in os.listdir(instance_images_path)
            if f.endswith(('.png', '.jpg', '.jpeg'))
        ]

    def __len__(self):
        return len(self.instance_images)

    def __getitem__(self, idx):
        image = Image.open(self.instance_images[idx]).convert("RGB")
        image = image.resize((self.size, self.size))
        image = torch.tensor(np.array(image)).permute(2, 0, 1) / 127.5 - 1.0

        tokens = self.tokenizer(
            self.instance_prompt,
            padding="max_length",
            max_length=77,
            truncation=True,
            return_tensors="pt"
        )

        return {"image": image, "input_ids": tokens.input_ids.squeeze()}

def train_dreambooth(
    pretrained_model: str,
    instance_data_dir: str,
    instance_prompt: str,
    output_dir: str,
    learning_rate: float = 5e-6,
    max_train_steps: int = 800,
    train_batch_size: int = 1
):
    # 載入流水線
    pipe = StableDiffusionPipeline.from_pretrained(pretrained_model)

    unet = pipe.unet
    vae = pipe.vae
    text_encoder = pipe.text_encoder
    tokenizer = pipe.tokenizer
    noise_scheduler = DDPMScheduler.from_pretrained(pretrained_model, subfolder="scheduler")

    # 凍結 VAE 和文字編碼器
    vae.requires_grad_(False)
    text_encoder.requires_grad_(False)

    # 建立資料集
    dataset = DreamBoothDataset(
        instance_data_dir, instance_prompt, tokenizer
    )
    dataloader = DataLoader(dataset, batch_size=train_batch_size, shuffle=True)

    # 設置優化器
    optimizer = torch.optim.AdamW(unet.parameters(), lr=learning_rate)
    lr_scheduler = get_scheduler(
        "constant",
        optimizer=optimizer,
        num_warmup_steps=0,
        num_training_steps=max_train_steps
    )

    # 訓練迴圈
    unet.train()
    device = "cuda"
    unet.to(device)
    vae.to(device)
    text_encoder.to(device)

    global_step = 0
    for epoch in range(max_train_steps // len(dataloader) + 1):
        for batch in dataloader:
            if global_step >= max_train_steps:
                break

            # 將圖片編碼為潛在變數
            latents = vae.encode(batch["image"].to(device)).latent_dist.sample()
            latents = latents * vae.config.scaling_factor

            # 採樣雜訊
            noise = torch.randn_like(latents)
            timesteps = torch.randint(0, noise_scheduler.num_train_timesteps, (latents.shape[0],))
            timesteps = timesteps.to(device)

            # 添加雜訊
            noisy_latents = noise_scheduler.add_noise(latents, noise, timesteps)

            # 獲取文字嵌入
            encoder_hidden_states = text_encoder(batch["input_ids"].to(device))[0]

            # 預測雜訊
            noise_pred = unet(noisy_latents, timesteps, encoder_hidden_states).sample

            # 計算損失
            loss = torch.nn.functional.mse_loss(noise_pred, noise)

            # 反向傳播
            loss.backward()
            optimizer.step()
            lr_scheduler.step()
            optimizer.zero_grad()

            global_step += 1

            if global_step % 100 == 0:
                print(f"Step {global_step}, Loss: {loss.item():.4f}")

    # 儲存模型
    pipe.unet = unet
    pipe.save_pretrained(output_dir)
```

## LoRA 訓練

使用低秩適配 (Low-Rank Adaptation) 進行高效微調：

```python
from peft import LoraConfig, get_peft_model
from diffusers import StableDiffusionPipeline
import torch

def train_lora(
    base_model: str,
    train_dataset,
    output_dir: str,
    lora_rank: int = 4,
    learning_rate: float = 1e-4,
    max_train_steps: int = 1000
):
    pipe = StableDiffusionPipeline.from_pretrained(base_model)
    unet = pipe.unet

    # 配置 LoRA
    lora_config = LoraConfig(
        r=lora_rank,
        lora_alpha=lora_rank,
        target_modules=["to_q", "to_v", "to_k", "to_out.0"],
        lora_dropout=0.1
    )

    # 將 LoRA 應用於 UNet
    unet = get_peft_model(unet, lora_config)
    unet.print_trainable_parameters()  # 顯示約 0.1% 的可訓練參數

    # 訓練（與 DreamBooth 類似，但僅更新 LoRA 參數）
    optimizer = torch.optim.AdamW(
        unet.parameters(),
        lr=learning_rate
    )

    # ... 訓練迴圈 ...

    # 僅儲存 LoRA 權重
    unet.save_pretrained(output_dir)
```

## 文字倒置 (Textual Inversion)

通過嵌入學習新概念：

```python
from diffusers import StableDiffusionPipeline
import torch

# 載入並包含文字倒置
pipe = StableDiffusionPipeline.from_pretrained(
    "stable-diffusion-v1-5/stable-diffusion-v1-5",
    torch_dtype=torch.float16
).to("cuda")

# 載入學到的嵌入
pipe.load_textual_inversion(
    "sd-concepts-library/cat-toy",
    token="<cat-toy>"
)

# 在提示詞中使用
image = pipe("A photo of <cat-toy> on a beach").images[0]
```

## 量化 (Quantization)

通過量化減少記憶體消耗：

```python
from diffusers import BitsAndBytesConfig, StableDiffusionXLPipeline
import torch

# 8-bit 量化
quantization_config = BitsAndBytesConfig(load_in_8bit=True)

pipe = StableDiffusionXLPipeline.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0",
    quantization_config=quantization_config,
    torch_dtype=torch.float16
)
```

### NF4 量化 (4-bit)

```python
quantization_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.float16
)

pipe = StableDiffusionXLPipeline.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0",
    quantization_config=quantization_config
)
```

## 生產環境佈署

### FastAPI 伺服器

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from diffusers import DiffusionPipeline
import torch
import base64
from io import BytesIO

app = FastAPI()

# 啟動時載入模型
pipe = DiffusionPipeline.from_pretrained(
    "stable-diffusion-v1-5/stable-diffusion-v1-5",
    torch_dtype=torch.float16
).to("cuda")
pipe.enable_model_cpu_offload()

class GenerationRequest(BaseModel):
    prompt: str
    negative_prompt: str = ""
    num_inference_steps: int = 30
    guidance_scale: float = 7.5
    width: int = 512
    height: int = 512
    seed: int = None

class GenerationResponse(BaseModel):
    image_base64: str
    seed: int

@app.post("/generate", response_model=GenerationResponse)
async def generate(request: GenerationRequest):
    try:
        generator = None
        seed = request.seed or torch.randint(0, 2**32, (1,)).item()
        generator = torch.Generator("cuda").manual_seed(seed)

        image = pipe(
            prompt=request.prompt,
            negative_prompt=request.negative_prompt,
            num_inference_steps=request.num_inference_steps,
            guidance_scale=request.guidance_scale,
            width=request.width,
            height=request.height,
            generator=generator
        ).images[0]

        # 轉換為 base64
        buffer = BytesIO()
        image.save(buffer, format="PNG")
        image_base64 = base64.b64encode(buffer.getvalue()).decode()

        return GenerationResponse(image_base64=image_base64, seed=seed)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    return {"status": "healthy"}
```

### Docker 佈署

```dockerfile
FROM nvidia/cuda:12.1-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y python3 python3-pip

WORKDIR /app

COPY requirements.txt .
RUN pip3 install -r requirements.txt

COPY . .

# 預先下載模型
RUN python3 -c "from diffusers import DiffusionPipeline; DiffusionPipeline.from_pretrained('stable-diffusion-v1-5/stable-diffusion-v1-5')"

EXPOSE 8000
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Kubernetes 佈署

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stable-diffusion
spec:
  replicas: 2
  selector:
    matchLabels:
      app: stable-diffusion
  template:
    metadata:
      labels:
        app: stable-diffusion
    spec:
      containers:
      - name: sd
        image: your-registry/stable-diffusion:latest
        ports:
        - containerPort: 8000
        resources:
          limits:
            nvidia.com/gpu: 1
            memory: "16Gi"
          requests:
            nvidia.com/gpu: 1
            memory: "8Gi"
        env:
        - name: TRANSFORMERS_CACHE
          value: "/cache/huggingface"
        volumeMounts:
        - name: model-cache
          mountPath: /cache
      volumes:
      - name: model-cache
        persistentVolumeClaim:
          claimName: model-cache-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: stable-diffusion
spec:
  selector:
    app: stable-diffusion
  ports:
  - port: 80
    targetPort: 8000
  type: LoadBalancer
```

## 回調系統 (Callback System)

監控並修改生成過程：

```python
from diffusers import StableDiffusionPipeline
from diffusers.callbacks import PipelineCallback
import torch

class ProgressCallback(PipelineCallback):
    def __init__(self):
        self.progress = []

    def callback_fn(self, pipe, step_index, timestep, callback_kwargs):
        self.progress.append({
            "step": step_index,
            "timestep": timestep.item()
        })

        # 可選：修改潛在變數
        latents = callback_kwargs["latents"]

        return callback_kwargs

# 使用回調
callback = ProgressCallback()

image = pipe(
    prompt="A sunset",
    callback_on_step_end=callback.callback_fn,
    callback_on_step_end_tensor_inputs=["latents"]
).images[0]

print(f"Generation completed in {len(callback.progress)} steps")
```

### 提早停止 (Early stopping)

```python
def early_stop_callback(pipe, step_index, timestep, callback_kwargs):
    # 20 步後停止
    if step_index >= 20:
        pipe._interrupt = True
    return callback_kwargs

image = pipe(
    prompt="A landscape",
    num_inference_steps=50,
    callback_on_step_end=early_stop_callback
).images[0]
```

## 多 GPU 推論

### 自動裝置映射 (Device map auto)

```python
from diffusers import StableDiffusionXLPipeline

pipe = StableDiffusionXLPipeline.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0",
    device_map="auto",  # 自動在多個 GPU 間分配
    torch_dtype=torch.float16
)
```

### 手動分配

```python
from accelerate import infer_auto_device_map, dispatch_model

# 建立裝置映射
device_map = infer_auto_device_map(
    pipe.unet,
    max_memory={0: "10GiB", 1: "10GiB"}
)

# 分配模型
pipe.unet = dispatch_model(pipe.unet, device_map=device_map)
```
