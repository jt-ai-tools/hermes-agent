# 後端配置指南

有關使用不同模型後端配置 Outlines 的完整指南。

## 目錄
- 本地模型 (Transformers, llama.cpp, vLLM)
- API 模型 (OpenAI)
- 效能比較
- 配置範例
- 生產部署

## Transformers (Hugging Face)

### 基本設定

```python
import outlines

# 從 Hugging Face 載入模型
model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")

# 搭配產生器使用
generator = outlines.generate.json(model, YourModel)
result = generator("你的提示詞")
```

### GPU 配置

```python
# 使用 CUDA GPU
model = outlines.models.transformers(
    "microsoft/Phi-3-mini-4k-instruct",
    device="cuda"
)

# 使用特定 GPU
model = outlines.models.transformers(
    "microsoft/Phi-3-mini-4k-instruct",
    device="cuda:0"  # GPU 0
)

# 使用 CPU
model = outlines.models.transformers(
    "microsoft/Phi-3-mini-4k-instruct",
    device="cpu"
)

# 使用 Apple Silicon MPS
model = outlines.models.transformers(
    "microsoft/Phi-3-mini-4k-instruct",
    device="mps"
)
```

### 進階配置

```python
# 使用 FP16 以加快推理速度
model = outlines.models.transformers(
    "microsoft/Phi-3-mini-4k-instruct",
    device="cuda",
    model_kwargs={
        "torch_dtype": "float16"
    }
)

# 8-bit 量化 (減少記憶體佔用)
model = outlines.models.transformers(
    "microsoft/Phi-3-mini-4k-instruct",
    device="cuda",
    model_kwargs={
        "load_in_8bit": True,
        "device_map": "auto"
    }
)

# 4-bit 量化 (更進一步減少記憶體佔用)
model = outlines.models.transformers(
    "meta-llama/Llama-3.1-70B-Instruct",
    device="cuda",
    model_kwargs={
        "load_in_4bit": True,
        "device_map": "auto",
        "bnb_4bit_compute_dtype": "float16"
    }
)

# 多 GPU
model = outlines.models.transformers(
    "meta-llama/Llama-3.1-70B-Instruct",
    device="cuda",
    model_kwargs={
        "device_map": "auto",  # 自動分配 GPU
        "max_memory": {0: "40GB", 1: "40GB"}  # 每個 GPU 的限制
    }
)
```

### 熱門模型

```python
# Phi-4 (Microsoft)
model = outlines.models.transformers("microsoft/Phi-4-mini-instruct")
model = outlines.models.transformers("microsoft/Phi-3-medium-4k-instruct")

# Llama 3.1 (Meta)
model = outlines.models.transformers("meta-llama/Llama-3.1-8B-Instruct")
model = outlines.models.transformers("meta-llama/Llama-3.1-70B-Instruct")
model = outlines.models.transformers("meta-llama/Llama-3.1-405B-Instruct")

# Mistral (Mistral AI)
model = outlines.models.transformers("mistralai/Mistral-7B-Instruct-v0.3")
model = outlines.models.transformers("mistralai/Mixtral-8x7B-Instruct-v0.1")
model = outlines.models.transformers("mistralai/Mixtral-8x22B-Instruct-v0.1")

# Qwen (Alibaba)
model = outlines.models.transformers("Qwen/Qwen2.5-7B-Instruct")
model = outlines.models.transformers("Qwen/Qwen2.5-14B-Instruct")
model = outlines.models.transformers("Qwen/Qwen2.5-72B-Instruct")

# Gemma (Google)
model = outlines.models.transformers("google/gemma-2-9b-it")
model = outlines.models.transformers("google/gemma-2-27b-it")

# Llava (視覺模型)
model = outlines.models.transformers("llava-hf/llava-v1.6-mistral-7b-hf")
```

### 自定義模型載入

```python
from transformers import AutoTokenizer, AutoModelForCausalLM
import outlines

# 手動載入模型
tokenizer = AutoTokenizer.from_pretrained("your-model")
model_hf = AutoModelForCausalLM.from_pretrained(
    "your-model",
    device_map="auto",
    torch_dtype="float16"
)

# 搭配 Outlines 使用
model = outlines.models.transformers(
    model=model_hf,
    tokenizer=tokenizer
)
```

## llama.cpp

### 基本設定

```python
import outlines

# 載入 GGUF 模型
model = outlines.models.llamacpp(
    "./models/llama-3.1-8b-instruct.Q4_K_M.gguf",
    n_ctx=4096  # 上下文視窗
)

# 搭配產生器使用
generator = outlines.generate.json(model, YourModel)
```

### GPU 配置

```python
# 僅使用 CPU
model = outlines.models.llamacpp(
    "./models/model.gguf",
    n_ctx=4096,
    n_threads=8  # 使用 8 個 CPU 執行緒
)

# GPU 卸載 (部分)
model = outlines.models.llamacpp(
    "./models/model.gguf",
    n_ctx=4096,
    n_gpu_layers=35,  # 將 35 層卸載到 GPU
    n_threads=4       # 剩餘層使用 CPU 執行緒
)

# 全 GPU 卸載
model = outlines.models.llamacpp(
    "./models/model.gguf",
    n_ctx=8192,
    n_gpu_layers=-1  # 所有層都在 GPU 上
)
```

### 進階配置

```python
model = outlines.models.llamacpp(
    "./models/llama-3.1-8b.Q4_K_M.gguf",
    n_ctx=8192,          # 上下文視窗 (tokens)
    n_gpu_layers=35,     # GPU 層數
    n_threads=8,         # CPU 執行緒數
    n_batch=512,         # 提示詞處理的批次大小
    use_mmap=True,       # 記憶體映射模型檔案 (載入更快速)
    use_mlock=False,     # 在 RAM 中鎖定模型 (防止交換到虛擬記憶體)
    seed=42,             # 用於重現性的隨機種子
    verbose=False        # 隱藏詳細輸出
)
```

### 量化格式

```python
# Q4_K_M (4-bit，大多數情況下的推薦選擇)
# - 大小：7B 模型約 4.5GB
# - 品質：好
# - 速度：快
model = outlines.models.llamacpp("./models/model.Q4_K_M.gguf")

# Q5_K_M (5-bit，更好的品質)
# - 大小：7B 模型約 5.5GB
# - 品質：非常好
# - 速度：比 Q4 稍慢
model = outlines.models.llamacpp("./models/model.Q5_K_M.gguf")

# Q6_K (6-bit，高品質)
# - 大小：7B 模型約 6.5GB
# - 品質：優異
# - 速度：比 Q5 慢
model = outlines.models.llamacpp("./models/model.Q6_K.gguf")

# Q8_0 (8-bit，接近原始品質)
# - 大小：7B 模型約 8GB
# - 品質：接近 FP16
# - 速度：比 Q6 慢
model = outlines.models.llamacpp("./models/model.Q8_0.gguf")

# F16 (16-bit 浮點數，原始品質)
# - 大小：7B 模型約 14GB
# - 品質：原始
# - 速度：最慢
model = outlines.models.llamacpp("./models/model.F16.gguf")
```

### 熱門 GGUF 模型

```python
# Llama 3.1
model = outlines.models.llamacpp("llama-3.1-8b-instruct.Q4_K_M.gguf")
model = outlines.models.llamacpp("llama-3.1-70b-instruct.Q4_K_M.gguf")

# Mistral
model = outlines.models.llamacpp("mistral-7b-instruct-v0.3.Q4_K_M.gguf")

# Phi-4
model = outlines.models.llamacpp("phi-4-mini-instruct.Q4_K_M.gguf")

# Qwen
model = outlines.models.llamacpp("qwen2.5-7b-instruct.Q4_K_M.gguf")
```

### Apple Silicon 優化

```python
# 針對 M1/M2/M3 Mac 進行優化
model = outlines.models.llamacpp(
    "./models/llama-3.1-8b.Q4_K_M.gguf",
    n_ctx=4096,
    n_gpu_layers=-1,  # 使用 Metal GPU 加速
    use_mmap=True,    # 高效記憶體映射
    n_threads=8       # 使用效能核心
)
```

## vLLM (生產環境)

### 基本設定

```python
import outlines

# 使用 vLLM 載入模型
model = outlines.models.vllm("meta-llama/Llama-3.1-8B-Instruct")

# 搭配產生器使用
generator = outlines.generate.json(model, YourModel)
```

### 單個 GPU

```python
model = outlines.models.vllm(
    "meta-llama/Llama-3.1-8B-Instruct",
    gpu_memory_utilization=0.9,  # 使用 90% 的 GPU 記憶體
    max_model_len=4096          # 最大序列長度
)
```

### 多個 GPU

```python
# 張量並行 (將模型拆分到多個 GPU)
model = outlines.models.vllm(
    "meta-llama/Llama-3.1-70B-Instruct",
    tensor_parallel_size=4,  # 使用 4 個 GPU
    gpu_memory_utilization=0.9
)

# 流水線並行 (較少見，用於極大型模型)
model = outlines.models.vllm(
    "meta-llama/Llama-3.1-405B-Instruct",
    pipeline_parallel_size=8,  # 8 個 GPU 的流水線
    tensor_parallel_size=4     # 4 個 GPU 的張量拆分
    # 總計：32 個 GPU
)
```

### 量化

```python
# AWQ 量化 (4-bit)
model = outlines.models.vllm(
    "meta-llama/Llama-3.1-8B-Instruct",
    quantization="awq",
    dtype="float16"
)

# GPTQ 量化 (4-bit)
model = outlines.models.vllm(
    "meta-llama/Llama-3.1-8B-Instruct",
    quantization="gptq"
)

# SqueezeLLM 量化
model = outlines.models.vllm(
    "meta-llama/Llama-3.1-8B-Instruct",
    quantization="squeezellm"
)
```

### 進階配置

```python
model = outlines.models.vllm(
    "meta-llama/Llama-3.1-8B-Instruct",
    tensor_parallel_size=1,
    gpu_memory_utilization=0.9,
    max_model_len=8192,
    max_num_seqs=256,           # 最大同時處理序列數
    max_num_batched_tokens=8192, # 每個批次的最大 token 數
    dtype="float16",
    trust_remote_code=True,
    enforce_eager=False,        # 使用 CUDA graphs (更快速)
    swap_space=4                # CPU 交換空間 (GB)
)
```

### 批次處理

```python
# vLLM 針對高吞吐量的批次處理進行了優化
model = outlines.models.vllm(
    "meta-llama/Llama-3.1-8B-Instruct",
    max_num_seqs=128  # 並行處理 128 個序列
)

generator = outlines.generate.json(model, YourModel)

# 高效處理多個提示詞
prompts = ["prompt1", "prompt2", ..., "prompt100"]
results = [generator(p) for p in prompts]
# vLLM 會自動進行批次化與優化
```

## OpenAI (有限支援)

### 基本設定

```python
import outlines

# 基本 OpenAI 支援
model = outlines.models.openai("gpt-4o-mini", api_key="your-api-key")

# 搭配產生器使用
generator = outlines.generate.json(model, YourModel)
result = generator("你的提示詞")
```

### 配置

```python
model = outlines.models.openai(
    "gpt-4o-mini",
    api_key="your-api-key",  # 或設定 OPENAI_API_KEY 環境變數
    max_tokens=2048,
    temperature=0.7
)
```

### 可用模型

```python
# GPT-4o (最新)
model = outlines.models.openai("gpt-4o")

# GPT-4o Mini (成本效益高)
model = outlines.models.openai("gpt-4o-mini")

# GPT-4 Turbo
model = outlines.models.openai("gpt-4-turbo")

# GPT-3.5 Turbo
model = outlines.models.openai("gpt-3.5-turbo")
```

**注意**：與本地模型相比，OpenAI 的支援較為有限。某些進階功能可能無法運作。

## 後端比較

### 功能矩陣

| 功能 | Transformers | llama.cpp | vLLM | OpenAI |
|---------|-------------|-----------|------|--------|
| 結構化產生 | ✅ 完整 | ✅ 完整 | ✅ 完整 | ⚠️ 有限 |
| FSM 優化 | ✅ 是 | ✅ 是 | ✅ 是 | ❌ 否 |
| GPU 支援 | ✅ 是 | ✅ 是 | ✅ 是 | N/A |
| 多 GPU | ✅ 是 | ✅ 是 | ✅ 是 | N/A |
| 量化 | ✅ 是 | ✅ 是 | ✅ 是 | N/A |
| 高吞吐量 | ⚠️ 中等 | ⚠️ 中等 | ✅ 優異 | ⚠️ 受 API 限制 |
| 設定難度 | 容易 | 中等 | 中等 | 容易 |
| 成本 | 硬體 | 硬體 | 硬體 | API 使用費 |

### 效能特性

**Transformers:**
- **延遲**: 50-200ms (單個請求，GPU)
- **吞吐量**: 10-50 tokens/sec (取決於硬體)
- **記憶體**: 每 1B 參數約 2-4GB (FP16)
- **最佳適用場景**: 開發、小規模部署、靈活性

**llama.cpp:**
- **延遲**: 30-150ms (單個請求)
- **吞吐量**: 20-150 tokens/sec (取決於量化)
- **記憶體**: 每 1B 參數約 0.5-2GB (Q4-Q8)
- **最佳適用場景**: CPU 推理、Apple Silicon、邊緣部署、低記憶體環境

**vLLM:**
- **延遲**: 30-100ms (單個請求)
- **吞吐量**: 100-1000+ tokens/sec (批次處理)
- **記憶體**: 每 1B 參數約 2-4GB (FP16)
- **最佳適用場景**: 生產環境、高吞吐量、批次處理、服務化

**OpenAI:**
- **延遲**: 200-500ms (API 呼叫)
- **吞吐量**: 受 API 速率限制
- **記憶體**: N/A (雲端服務)
- **最佳適用場景**: 快速原型設計、無基礎設施需求

### 記憶體需求

**7B 模型:**
- FP16: ~14GB
- 8-bit: ~7GB
- 4-bit: ~4GB
- Q4_K_M (GGUF): ~4.5GB

**13B 模型:**
- FP16: ~26GB
- 8-bit: ~13GB
- 4-bit: ~7GB
- Q4_K_M (GGUF): ~8GB

**70B 模型:**
- FP16: ~140GB (多 GPU)
- 8-bit: ~70GB (多 GPU)
- 4-bit: ~35GB (單張 A100/H100)
- Q4_K_M (GGUF): ~40GB

## 效能調優

### Transformers 優化

```python
# 使用 FP16
model = outlines.models.transformers(
    "meta-llama/Llama-3.1-8B-Instruct",
    device="cuda",
    model_kwargs={"torch_dtype": "float16"}
)

# 使用 flash attention (快 2-4 倍)
model = outlines.models.transformers(
    "meta-llama/Llama-3.1-8B-Instruct",
    device="cuda",
    model_kwargs={
        "torch_dtype": "float16",
        "use_flash_attention_2": True
    }
)

# 使用 8-bit 量化 (減少 2 倍記憶體)
model = outlines.models.transformers(
    "meta-llama/Llama-3.1-8B-Instruct",
    device="cuda",
    model_kwargs={
        "load_in_8bit": True,
        "device_map": "auto"
    }
)
```

### llama.cpp 優化

```python
# 最大化 GPU 使用
model = outlines.models.llamacpp(
    "./models/model.Q4_K_M.gguf",
    n_gpu_layers=-1,  # 所有層都在 GPU 上
    n_ctx=8192,
    n_batch=512       # 較大的批次 = 更快
)

# 針對 CPU 優化 (Apple Silicon)
model = outlines.models.llamacpp(
    "./models/model.Q4_K_M.gguf",
    n_ctx=4096,
    n_threads=8,      # 使用所有效能核心
    use_mmap=True
)
```

### vLLM 優化

```python
# 高吞吐量
model = outlines.models.vllm(
    "meta-llama/Llama-3.1-8B-Instruct",
    gpu_memory_utilization=0.95,  # 使用 95% 的 GPU
    max_num_seqs=256,             # 高同時處理數
    enforce_eager=False           # 使用 CUDA graphs
)

# 多 GPU
model = outlines.models.vllm(
    "meta-llama/Llama-3.1-70B-Instruct",
    tensor_parallel_size=4,  # 4 個 GPU
    gpu_memory_utilization=0.9
)
```

## 生產部署

### 搭配 vLLM 的 Docker

```dockerfile
FROM vllm/vllm-openai:latest

# 安裝 outlines
RUN pip install outlines

# 複製你的程式碼
COPY app.py /app/

# 執行
CMD ["python", "/app/app.py"]
```

### 環境變數

```bash
# Transformers 快取
export HF_HOME="/path/to/cache"
export TRANSFORMERS_CACHE="/path/to/cache"

# GPU 選擇
export CUDA_VISIBLE_DEVICES=0,1,2,3

# OpenAI API 金鑰
export OPENAI_API_KEY="sk-..."

# 停用 tokenizers 的平行化警告
export TOKENIZERS_PARALLELISM=false
```

### 模型服務化

```python
# 使用 vLLM 的簡單 HTTP 伺服器
import outlines
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

# 在啟動時載入一次模型
model = outlines.models.vllm("meta-llama/Llama-3.1-8B-Instruct")

class User(BaseModel):
    name: str
    age: int
    email: str

generator = outlines.generate.json(model, User)

@app.post("/extract")
def extract(text: str):
    result = generator(f"從中提取使用者：{text}")
    return result.model_dump()
```

## 資源

- **Transformers**: https://huggingface.co/docs/transformers
- **llama.cpp**: https://github.com/ggerganov/llama.cpp
- **vLLM**: https://docs.vllm.ai
- **Outlines**: https://github.com/outlines-dev/outlines
