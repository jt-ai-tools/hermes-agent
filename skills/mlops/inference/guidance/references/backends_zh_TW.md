# 後端配置指南 (Backend Configuration Guide)

關於如何為 Guidance 配置不同 LLM 後端的完整指南。

## 目錄
- 基於 API 的模型 (Anthropic, OpenAI)
- 本地模型 (Transformers, llama.cpp)
- 後端比較
- 效能調優
- 進階配置

## 基於 API 的模型

### Anthropic Claude

#### 基礎設定

```python
from guidance import models

# 使用環境變數
lm = models.Anthropic("claude-sonnet-4-5-20250929")
# 從環境變數讀取 ANTHROPIC_API_KEY

# 明確指定 API 金鑰
lm = models.Anthropic(
    model="claude-sonnet-4-5-20250929",
    api_key="您的 API 金鑰"
)
```

#### 可用模型

```python
# Claude 3.5 Sonnet (最新，推薦)
lm = models.Anthropic("claude-sonnet-4-5-20250929")

# Claude 3.7 Sonnet (快速，具成本效益)
lm = models.Anthropic("claude-sonnet-3.7-20250219")

# Claude 3 Opus (最強大)
lm = models.Anthropic("claude-3-opus-20240229")

# Claude 3.5 Haiku (最快，最便宜)
lm = models.Anthropic("claude-3-5-haiku-20241022")
```

#### 配置選項

```python
lm = models.Anthropic(
    model="claude-sonnet-4-5-20250929",
    api_key="您的 API 金鑰",
    max_tokens=4096,           # 最大生成 Token 數
    temperature=0.7,            # 採樣溫度 (0-1)
    top_p=0.9,                  # 核採樣 (Nucleus sampling)
    timeout=30,                 # 請求逾時 (秒)
    max_retries=3              # 失敗請求重試次數
)
```

#### 使用上下文管理器

```python
from guidance import models, system, user, assistant, gen

lm = models.Anthropic("claude-sonnet-4-5-20250929")

with system():
    lm += "You are a helpful assistant."

with user():
    lm += "What is the capital of France?"

with assistant():
    lm += gen(max_tokens=50)

print(lm)
```

### OpenAI

#### 基礎設定

```python
from guidance import models

# 使用環境變數
lm = models.OpenAI("gpt-4o")
# 從環境變數讀取 OPENAI_API_KEY

# 明確指定 API 金鑰
lm = models.OpenAI(
    model="gpt-4o",
    api_key="您的 API 金鑰"
)
```

#### 可用模型

```python
# GPT-4o (最新，多模態)
lm = models.OpenAI("gpt-4o")

# GPT-4o Mini (快速，具成本效益)
lm = models.OpenAI("gpt-4o-mini")

# GPT-4 Turbo
lm = models.OpenAI("gpt-4-turbo")

# GPT-3.5 Turbo (最便宜)
lm = models.OpenAI("gpt-3.5-turbo")
```

#### 配置選項

```python
lm = models.OpenAI(
    model="gpt-4o-mini",
    api_key="您的 API 金鑰",
    max_tokens=2048,
    temperature=0.7,
    top_p=1.0,
    frequency_penalty=0.0,
    presence_penalty=0.0,
    timeout=30
)
```

#### 聊天格式 (Chat Format)

```python
from guidance import models, gen

lm = models.OpenAI("gpt-4o-mini")

# OpenAI 使用聊天格式
lm += [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "What is 2+2?"}
]

# 生成回應
lm += gen(max_tokens=50)
```

### Azure OpenAI

```python
from guidance import models

lm = models.AzureOpenAI(
    model="gpt-4o",
    azure_endpoint="https://your-resource.openai.azure.com/",
    api_key="您的 Azure API 金鑰",
    api_version="2024-02-15-preview",
    deployment_name="您的部署名稱"
)
```

## 本地模型

### Transformers (Hugging Face)

#### 基礎設定

```python
from guidance.models import Transformers

# 從 Hugging Face 載入模型
lm = Transformers("microsoft/Phi-4-mini-instruct")
```

#### GPU 配置

```python
# 使用 GPU
lm = Transformers(
    "microsoft/Phi-4-mini-instruct",
    device="cuda"
)

# 使用特定 GPU
lm = Transformers(
    "microsoft/Phi-4-mini-instruct",
    device="cuda:0"  # GPU 0
)

# 使用 CPU
lm = Transformers(
    "microsoft/Phi-4-mini-instruct",
    device="cpu"
)
```

#### 進階配置

```python
lm = Transformers(
    "microsoft/Phi-4-mini-instruct",
    device="cuda",
    torch_dtype="float16",      # 使用 FP16 (更快速，佔用更少記憶體)
    load_in_8bit=True,          # 8 位元量化
    max_memory={0: "20GB"},     # GPU 記憶體限制
    offload_folder="./offload"  # 必要時卸載至磁碟
)
```

#### 熱門模型

```python
# Phi-4 (Microsoft)
lm = Transformers("microsoft/Phi-4-mini-instruct")
lm = Transformers("microsoft/Phi-3-medium-4k-instruct")

# Llama 3 (Meta)
lm = Transformers("meta-llama/Llama-3.1-8B-Instruct")
lm = Transformers("meta-llama/Llama-3.1-70B-Instruct")

# Mistral (Mistral AI)
lm = Transformers("mistralai/Mistral-7B-Instruct-v0.3")
lm = Transformers("mistralai/Mixtral-8x7B-Instruct-v0.1")

# Qwen (Alibaba)
lm = Transformers("Qwen/Qwen2.5-7B-Instruct")

# Gemma (Google)
lm = Transformers("google/gemma-2-9b-it")
```

#### 生成配置

```python
lm = Transformers(
    "microsoft/Phi-4-mini-instruct",
    device="cuda"
)

# 配置生成參數
from guidance import gen

result = lm + gen(
    max_tokens=100,
    temperature=0.7,
    top_p=0.9,
    top_k=50,
    repetition_penalty=1.1
)
```

### llama.cpp

#### 基礎設定

```python
from guidance.models import LlamaCpp

# 載入 GGUF 模型
lm = LlamaCpp(
    model_path="/路徑/至/模型.gguf",
    n_ctx=4096  # 上下文視窗
)
```

#### GPU 配置

```python
# 使用 GPU 加速
lm = LlamaCpp(
    model_path="/路徑/至/模型.gguf",
    n_ctx=4096,
    n_gpu_layers=35,  # 將 35 層卸載至 GPU
    n_threads=8       # 剩餘層使用的 CPU 執行緒數
)

# 完全 GPU 卸載
lm = LlamaCpp(
    model_path="/路徑/至/模型.gguf",
    n_ctx=4096,
    n_gpu_layers=-1  # 卸載所有層
)
```

#### 進階配置

```python
lm = LlamaCpp(
    model_path="/路徑/至/llama-3.1-8b-instruct.Q4_K_M.gguf",
    n_ctx=8192,          # 上下文視窗 (Tokens)
    n_gpu_layers=35,     # GPU 層數
    n_threads=8,         # CPU 執行緒數
    n_batch=512,         # Prompt 處理的批次大小
    use_mmap=True,       # 記憶體映射模型檔案 (Memory-map)
    use_mlock=False,     # 將模型鎖定在 RAM 中
    seed=42,             # 隨機種子
    verbose=False        # 隱藏詳細輸出
)
```

#### 量化模型

```python
# Q4_K_M (4 位元，大多數情況推薦)
lm = LlamaCpp("/路徑/至/模型.Q4_K_M.gguf")

# Q5_K_M (5 位元，品質較好)
lm = LlamaCpp("/路徑/至/模型.Q5_K_M.gguf")

# Q8_0 (8 位元，高品質)
lm = LlamaCpp("/路徑/至/模型.Q8_0.gguf")

# F16 (16 位元浮點數，最高品質)
lm = LlamaCpp("/路徑/至/模型.F16.gguf")
```

#### 熱門 GGUF 模型

```python
# Llama 3.1
lm = LlamaCpp("llama-3.1-8b-instruct.Q4_K_M.gguf")

# Mistral
lm = LlamaCpp("mistral-7b-instruct-v0.3.Q4_K_M.gguf")

# Phi-4
lm = LlamaCpp("phi-4-mini-instruct.Q4_K_M.gguf")
```

## 後端比較

### 功能矩陣 (Feature Matrix)

| 功能 | Anthropic | OpenAI | Transformers | llama.cpp |
|---------|-----------|--------|--------------|-----------|
| 受限生成 | ✅ 完整 | ✅ 完整 | ✅ 完整 | ✅ 完整 |
| Token 修復 | ✅ 是 | ✅ 是 | ✅ 是 | ✅ 是 |
| 串流輸出 | ✅ 是 | ✅ 是 | ✅ 是 | ✅ 是 |
| GPU 支援 | N/A | N/A | ✅ 是 | ✅ 是 |
| 量化支援 | N/A | N/A | ✅ 是 | ✅ 是 |
| 成本 | $$$ | $$$ | 免費 | 免費 |
| 延遲 | 低 | 低 | 中 | 低 |
| 設定難度 | 容易 | 容易 | 中 | 中 |

### 效能特性

**Anthropic Claude：**
- **延遲**：200-500ms (API 呼叫)
- **吞吐量**：受 API 速率限制 (Rate limits) 約束
- **成本**：每 1M 輸入 Token 約 $3-15 美元
- **最適合**：生產系統、高品質輸出

**OpenAI：**
- **延遲**：200-400ms (API 呼叫)
- **吞吐量**：受 API 速率限制約束
- **成本**：每 1M 輸入 Token 約 $0.15-30 美元
- **最適合**：對成本敏感的生產環境、gpt-4o-mini

**Transformers：**
- **延遲**：50-200ms (本地推論)
- **吞吐量**：取決於 GPU (10-100 Tokens/秒)
- **成本**：僅硬體成本
- **最適合**：對隱私敏感、高流量、實驗研究

**llama.cpp：**
- **延遲**：30-150ms (本地推論)
- **吞吐量**：取決於硬體 (20-150 Tokens/秒)
- **成本**：僅硬體成本
- **最適合**：邊緣部署、Apple Silicon、CPU 推論

### 記憶體需求

**Transformers (FP16)：**
- 7B 模型：約 14GB GPU VRAM
- 13B 模型：約 26GB GPU VRAM
- 70B 模型：約 140GB GPU VRAM (需多 GPU)

**llama.cpp (Q4_K_M)：**
- 7B 模型：約 4.5GB RAM
- 13B 模型：約 8GB RAM
- 70B 模型：約 40GB RAM

**優化提示：**
- 使用量化模型 (Q4_K_M) 以降低記憶體需求
- 使用 GPU 卸載 (Offloading) 以加快推論速度
- 對於較小的模型 (<7B) 可使用 CPU 推論

## 效能調優

### API 模型 (Anthropic, OpenAI)

#### 降低延遲

```python
from guidance import models, gen

lm = models.Anthropic("claude-sonnet-4-5-20250929")

# 使用較小的 max_tokens (回應更快)
lm += gen(max_tokens=100)  # 而非 1000

# 使用串流輸出 (減少感知延遲)
for chunk in lm.stream(gen(max_tokens=500)):
    print(chunk, end="", flush=True)
```

#### 降低成本

```python
# 使用較便宜的模型
lm = models.Anthropic("claude-3-5-haiku-20241022")  # 對比 Sonnet
lm = models.OpenAI("gpt-4o-mini")  # 對比 gpt-4o

# 縮減上下文大小
# - 保持提示詞簡潔
# - 避免使用大量的 Few-shot 範例
# - 使用 max_tokens 限制
```

### 本地模型 (Transformers, llama.cpp)

#### 優化 GPU 使用

```python
from guidance.models import Transformers

# 使用 FP16 可獲得 2 倍速提升
lm = Transformers(
    "meta-llama/Llama-3.1-8B-Instruct",
    device="cuda",
    torch_dtype="float16"
)

# 使用 8 位元量化可減少 4 倍記憶體佔用
lm = Transformers(
    "meta-llama/Llama-3.1-8B-Instruct",
    device="cuda",
    load_in_8bit=True
)

# 使用 Flash Attention (需要安裝 flash-attn 套件)
lm = Transformers(
    "meta-llama/Llama-3.1-8B-Instruct",
    device="cuda",
    use_flash_attention_2=True
)
```

#### 優化 llama.cpp

```python
from guidance.models import LlamaCpp

# 最大化 GPU 層數
lm = LlamaCpp(
    model_path="/路徑/至/模型.Q4_K_M.gguf",
    n_gpu_layers=-1  # 所有層都放在 GPU 上
)

# 優化批次大小
lm = LlamaCpp(
    model_path="/路徑/至/模型.Q4_K_M.gguf",
    n_batch=512,     # 較大的批次 = 更快的 Prompt 處理速度
    n_gpu_layers=-1
)

# 使用 Metal (Apple Silicon)
lm = LlamaCpp(
    model_path="/路徑/至/模型.Q4_K_M.gguf",
    n_gpu_layers=-1,  # 使用 Metal GPU 加速
    use_mmap=True
)
```

#### 批次處理 (Batch Processing)

```python
# 高效處理多個請求
requests = [
    "What is 2+2?",
    "What is the capital of France?",
    "What is photosynthesis?"
]

# 不推薦：序列處理
for req in requests:
    lm = Transformers("microsoft/Phi-4-mini-instruct")
    lm += req + gen(max_tokens=50)

# 推薦：重複使用已載入的模型
lm = Transformers("microsoft/Phi-4-mini-instruct")
for req in requests:
    lm += req + gen(max_tokens=50)
```

## 進階配置

### 自定義模型配置

```python
from transformers import AutoTokenizer, AutoModelForCausalLM
from guidance.models import Transformers

# 載入自定義模型
tokenizer = AutoTokenizer.from_pretrained("您的模型名稱")
model = AutoModelForCausalLM.from_pretrained(
    "您的模型名稱",
    device_map="auto",
    torch_dtype="float16"
)

# 在 Guidance 中使用
lm = Transformers(model=model, tokenizer=tokenizer)
```

### 環境變數

```bash
# API 金鑰
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."

# Transformers 快取
export HF_HOME="/路徑/至/快取"
export TRANSFORMERS_CACHE="/路徑/至/快取"

# GPU 選擇
export CUDA_VISIBLE_DEVICES=0,1  # 使用 GPU 0 和 1
```

### 偵錯 (Debugging)

```python
# 啟用詳細日誌
import logging
logging.basicConfig(level=logging.DEBUG)

# 檢查後端資訊
lm = models.Anthropic("claude-sonnet-4-5-20250929")
print(f"Model: {lm.model_name}")
print(f"Backend: {lm.backend}")

# 檢查 GPU 使用情況 (Transformers)
lm = Transformers("microsoft/Phi-4-mini-instruct", device="cuda")
print(f"Device: {lm.device}")
print(f"Memory allocated: {torch.cuda.memory_allocated() / 1e9:.2f} GB")
```

## 相關資源

- **Anthropic 文件**：https://docs.anthropic.com
- **OpenAI 文件**：https://platform.openai.com/docs
- **Hugging Face 模型庫**：https://huggingface.co/models
- **llama.cpp**：https://github.com/ggerganov/llama.cpp
- **GGUF 模型庫**：https://huggingface.co/models?library=gguf
