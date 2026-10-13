# Stable Diffusion 故障排除指南

## 安裝問題

### 套件衝突

**錯誤**: `ImportError: cannot import name 'cached_download' from 'huggingface_hub'`

**解決方法**:
```bash
# 更新 huggingface_hub
pip install --upgrade huggingface_hub

# 重新安裝 diffusers
pip install --upgrade diffusers
```

### xFormers 安裝失敗

**錯誤**: `RuntimeError: CUDA error: no kernel image is available for execution`

**解決方法**:
```bash
# 檢查 CUDA 版本
nvcc --version

# 安裝相應的 xformers
pip install xformers --index-url https://download.pytorch.org/whl/cu121  # 適用於 CUDA 12.1

# 或從原始碼構建
pip install -v -U git+https://github.com/facebookresearch/xformers.git@main#egg=xformers
```

### Torch/CUDA 不匹配

**錯誤**: `RuntimeError: CUDA error: CUBLAS_STATUS_NOT_INITIALIZED`

**解決方法**:
```bash
# 檢查版本
python -c "import torch; print(torch.__version__, torch.cuda.is_available())"

# 使用正確的 CUDA 重新安裝 PyTorch
pip uninstall torch torchvision
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
```

## 記憶體問題

### CUDA 記憶體不足 (Out of memory)

**錯誤**: `torch.cuda.OutOfMemoryError: CUDA out of memory`

**解決方案**:

```python
# 方案 1: 啟用 CPU 卸載 (offloading)
pipe.enable_model_cpu_offload()

# 方案 2: 順序 CPU 卸載 (更激進)
pipe.enable_sequential_cpu_offload()

# 方案 3: 注意力分塊 (Attention slicing)
pipe.enable_attention_slicing()

# 方案 4: 大型圖片的 VAE 分塊 (VAE slicing)
pipe.enable_vae_slicing()

# 方案 5: 使用較低精度
pipe = DiffusionPipeline.from_pretrained(
    "model-id",
    torch_dtype=torch.float16  # 或 torch.bfloat16
)

# 方案 6: 減少批次大小
image = pipe(prompt, num_images_per_prompt=1).images[0]

# 方案 7: 生成較小的圖片
image = pipe(prompt, height=512, width=512).images[0]

# 方案 8: 在生成之間清除快取
import gc
torch.cuda.empty_cache()
gc.collect()
```

### 記憶體隨時間增長

**問題**: 每次生成時記憶體使用量都會增加

**解決方法**:
```python
import gc
import torch

def generate_with_cleanup(pipe, prompt, **kwargs):
    try:
        image = pipe(prompt, **kwargs).images[0]
        return image
    finally:
        # 生成後清除快取
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
        gc.collect()
```

### 大型模型載入失敗

**錯誤**: `RuntimeError: Unable to load model weights`

**解決方法**:
```python
# 使用低 CPU 記憶體模式
pipe = DiffusionPipeline.from_pretrained(
    "large-model-id",
    low_cpu_mem_usage=True,
    torch_dtype=torch.float16
)
```

## 生成問題

### 出現黑圖 (Black images)

**問題**: 輸出的圖片完全是黑色的

**解決方案**:
```python
# 方案 1: 停用安全檢查器 (safety checker)
pipe.safety_checker = None

# 方案 2: 檢查 VAE 縮放
# 問題可能出在 VAE 編碼/解碼
latents = latents / pipe.vae.config.scaling_factor  # 解碼前

# 方案 3: 確保資料類型 (dtype) 正確
pipe = pipe.to(dtype=torch.float16)
pipe.vae = pipe.vae.to(dtype=torch.float32)  # VAE 通常需要 fp32

# 方案 4: 檢查引導比例 (guidance scale)
# 過高可能會導致問題
image = pipe(prompt, guidance_scale=7.5).images[0]  # 不要超過 20+
```

### 雜訊或靜態圖片

**問題**: 輸出看起來像隨機雜訊

**解決方案**:
```python
# 方案 1: 增加推論步數
image = pipe(prompt, num_inference_steps=50).images[0]

# 方案 2: 檢查排程器 (scheduler) 配置
pipe.scheduler = pipe.scheduler.from_config(pipe.scheduler.config)

# 方案 3: 驗證模型是否載入正確
print(pipe.unet)  # 應該顯示模型架構
```

### 圖片模糊

**問題**: 輸出圖片品質低下或模糊

**解決方案**:
```python
# 方案 1: 使用更多步數
image = pipe(prompt, num_inference_steps=50).images[0]

# 方案 2: 使用更好的 VAE
from diffusers import AutoencoderKL
vae = AutoencoderKL.from_pretrained("stabilityai/sd-vae-ft-mse")
pipe.vae = vae

# 方案 3: 使用 SDXL 或精煉器 (refiner)
pipe = DiffusionPipeline.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0"
)

# 方案 4: 使用 img2img 進行放大
upscale_pipe = StableDiffusionImg2ImgPipeline.from_pretrained(...)
upscaled = upscale_pipe(
    prompt=prompt,
    image=image.resize((1024, 1024)),
    strength=0.3
).images[0]
```

### 未遵循提示詞 (Prompt)

**問題**: 生成的圖片與提示詞不符

**解決方案**:
```python
# 方案 1: 增加引導比例 (guidance scale)
image = pipe(prompt, guidance_scale=10.0).images[0]

# 方案 2: 使用負面提示 (negative prompts)
image = pipe(
    prompt="A red car",
    negative_prompt="blue, green, yellow, wrong color",
    guidance_scale=7.5
).images[0]

# 方案 3: 使用提示詞權重
# 強調重要詞彙
prompt = "A (red:1.5) car on a street"

# 方案 4: 使用更長、更詳細的提示詞
prompt = """
A bright red sports car, ferrari style, parked on a city street,
photorealistic, high detail, 8k, professional photography
"""
```

### 臉部或手部扭曲

**問題**: 臉部和手部看起來變形了

**解決方案**:
```python
# 方案 1: 使用負面提示
negative_prompt = """
bad hands, bad anatomy, deformed, ugly, blurry,
extra fingers, mutated hands, poorly drawn hands,
poorly drawn face, mutation, deformed face
"""

# 方案 2: 使用臉部專用模型
# ADetailer 或類似的後處理工具

# 方案 3: 使用 ControlNet 固定姿勢
# 載入姿勢估計並引導生成

# 方案 4: 對有問題的區域進行局部重繪 (Inpaint)
mask = create_face_mask(image)
fixed = inpaint_pipe(
    prompt="beautiful detailed face",
    image=image,
    mask_image=mask
).images[0]
```

## 排程器 (Scheduler) 問題

### 排程器不相容

**錯誤**: `ValueError: Scheduler ... is not compatible with pipeline`

**解決方法**:
```python
from diffusers import EulerDiscreteScheduler

# 從配置建立排程器
pipe.scheduler = EulerDiscreteScheduler.from_config(
    pipe.scheduler.config
)

# 檢查相容的排程器
print(pipe.scheduler.compatibles)
```

### 步數錯誤

**問題**: 相同步數下模型生成的品質不同

**解決方法**:
```python
# 顯式重設時間步 (timesteps)
pipe.scheduler.set_timesteps(num_inference_steps)

# 檢查排程器的步數
print(len(pipe.scheduler.timesteps))
```

## LoRA 問題

### LoRA 權重未載入

**錯誤**: `RuntimeError: Error(s) in loading state_dict for UNet2DConditionModel`

**解決方法**:
```python
# 檢查權重檔案格式
# 應該是 .safetensors 或 .bin

# 使用正確的鍵值前綴載入
pipe.load_lora_weights(
    "path/to/lora",
    weight_name="lora.safetensors"
)

# 嘗試載入到特定組件
pipe.unet.load_attn_procs("path/to/lora")
```

### LoRA 對輸出沒有影響

**問題**: 生成的圖片在有無 LoRA 的情況下看起來一樣

**解決方法**:
```python
# 融合 (Fuse) LoRA 權重
pipe.fuse_lora(lora_scale=1.0)

# 或顯式設置權重
pipe.set_adapters(["lora_name"], adapter_weights=[1.0])

# 驗證 LoRA 已載入
print(list(pipe.unet.attn_processors.keys()))
```

### 多個 LoRA 衝突

**問題**: 多個 LoRA 產生偽影 (artifacts)

**解決方法**:
```python
# 使用不同的適配器名稱載入
pipe.load_lora_weights("lora1", adapter_name="style")
pipe.load_lora_weights("lora2", adapter_name="subject")

# 平衡權重
pipe.set_adapters(
    ["style", "subject"],
    adapter_weights=[0.5, 0.5]  # 降低權重
)

# 或在載入前離線合併 LoRA
# 以適當比例離線合併 LoRA
```

## ControlNet 問題

### ControlNet 未起到引導作用

**問題**: ControlNet 對輸出沒有影響

**解決方法**:
```python
# 檢查控制圖片格式
# 應為 RGB，且與生成尺寸匹配
control_image = control_image.resize((512, 512))

# 增加條件比例 (conditioning scale)
image = pipe(
    prompt=prompt,
    image=control_image,
    controlnet_conditioning_scale=1.0,  # 嘗試 0.5-1.5
    num_inference_steps=30
).images[0]

# 驗證 ControlNet 已載入
print(pipe.controlnet)
```

### 控制圖片預處理

**解決方法**:
```python
from controlnet_aux import CannyDetector

# 正確的預處理
canny = CannyDetector()
control_image = canny(input_image)

# 確保格式正確
control_image = control_image.convert("RGB")
control_image = control_image.resize((512, 512))
```

## Hub/下載問題

### 模型下載失敗

**錯誤**: `requests.exceptions.ConnectionError`

**解決方法**:
```bash
# 設置更長的逾時時間
export HF_HUB_DOWNLOAD_TIMEOUT=600

# 如果可用，使用鏡像站
export HF_ENDPOINT=https://hf-mirror.com

# 或手動下載
huggingface-cli download stable-diffusion-v1-5/stable-diffusion-v1-5
```

### 快取問題

**錯誤**: `OSError: Can't load model from cache`

**解決方法**:
```bash
# 清除快取
rm -rf ~/.cache/huggingface/hub

# 或設置不同的快取位置
export HF_HOME=/path/to/cache

# 強制重新下載
pipe = DiffusionPipeline.from_pretrained(
    "model-id",
    force_download=True
)
```

### 受限模型的存取被拒絕

**錯誤**: `401 Client Error: Unauthorized`

**解決方法**:
```bash
# 登入 Hugging Face
huggingface-cli login

# 或使用 Token
pipe = DiffusionPipeline.from_pretrained(
    "model-id",
    token="hf_xxxxx"
)

# 請先在 Hub 網站上接受模型的授權條款
```

## 效能問題

### 生成速度慢

**問題**: 生成耗時過長

**解決方案**:
```python
# 方案 1: 使用更快的排程器
from diffusers import DPMSolverMultistepScheduler
pipe.scheduler = DPMSolverMultistepScheduler.from_config(
    pipe.scheduler.config
)

# 方案 2: 減少步數
image = pipe(prompt, num_inference_steps=20).images[0]

# 方案 3: 使用 LCM
from diffusers import LCMScheduler
pipe.load_lora_weights("latent-consistency/lcm-lora-sdxl")
pipe.scheduler = LCMScheduler.from_config(pipe.scheduler.config)
image = pipe(prompt, num_inference_steps=4, guidance_scale=1.0).images[0]

# 方案 4: 啟用 xFormers
pipe.enable_xformers_memory_efficient_attention()

# 方案 5: 編譯模型
pipe.unet = torch.compile(pipe.unet, mode="reduce-overhead", fullgraph=True)
```

### 首次生成速度慢

**問題**: 第一張圖片耗時明顯較長

**解決方法**:
```python
# 模型預熱 (Warm up)
_ = pipe("warmup", num_inference_steps=1)

# 然後運行實際生成
image = pipe(prompt, num_inference_steps=50).images[0]

# 編譯以加快後續運行
pipe.unet = torch.compile(pipe.unet)
```

## 除錯技巧

### 啟用除錯日誌 (Debug logging)

```python
import logging
logging.basicConfig(level=logging.DEBUG)

# 或針對特定模組
logging.getLogger("diffusers").setLevel(logging.DEBUG)
logging.getLogger("transformers").setLevel(logging.DEBUG)
```

### 檢查模型組件

```python
# 列印流水線組件
print(pipe.components)

# 檢查模型配置
print(pipe.unet.config)
print(pipe.vae.config)
print(pipe.scheduler.config)

# 驗證裝置配置
print(pipe.device)
for name, module in pipe.components.items():
    if hasattr(module, 'device'):
        print(f"{name}: {module.device}")
```

### 驗證輸入

```python
# 檢查圖片尺寸
print(f"Height: {height}, Width: {width}")
assert height % 8 == 0, "Height 必須是 8 的倍數"
assert width % 8 == 0, "Width 必須是 8 的倍數"

# 檢查提示詞 Token 化情況
tokens = pipe.tokenizer(prompt, return_tensors="pt")
print(f"Token count: {tokens.input_ids.shape[1]}")  # SD 最大為 77
```

### 儲存中間結果

```python
def save_latents_callback(pipe, step_index, timestep, callback_kwargs):
    latents = callback_kwargs["latents"]

    # 解碼並儲存中間結果
    with torch.no_grad():
        image = pipe.vae.decode(latents / pipe.vae.config.scaling_factor).sample
    image = (image / 2 + 0.5).clamp(0, 1)
    image = image.cpu().permute(0, 2, 3, 1).numpy()[0]
    Image.fromarray((image * 255).astype("uint8")).save(f"step_{step_index}.png")

    return callback_kwargs

image = pipe(
    prompt,
    callback_on_step_end=save_latents_callback,
    callback_on_step_end_tensor_inputs=["latents"]
).images[0]
```

## 尋求幫助

1. **文件**: https://huggingface.co/docs/diffusers
2. **GitHub Issues**: https://github.com/huggingface/diffusers/issues
3. **Discord**: https://discord.gg/diffusers
4. **論壇**: https://discuss.huggingface.co

### 回報問題

請包含：
- Diffusers 版本: `pip show diffusers`
- PyTorch 版本: `python -c "import torch; print(torch.__version__)"`
- CUDA 版本: `nvcc --version`
- GPU 型號: `nvidia-smi`
- 完整的錯誤回溯 (Traceback)
- 最小可重現程式碼
- 使用的模型名稱/ID
