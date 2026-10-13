# HuggingFace Transformers 整合

## 目錄
- 在 Transformers 中啟用 Flash Attention
- 支援的模型架構
- 設定範例
- 效能比較
- 針對特定模型問題的疑難排解

## 在 Transformers 中啟用 Flash Attention

HuggingFace Transformers (v4.36+) 已原生支援 Flash Attention 2。

**針對任何支援的模型進行簡單啟用**：
```python
from transformers import AutoModel

model = AutoModel.from_pretrained(
    "meta-llama/Llama-2-7b-hf",
    attn_implementation="flash_attention_2",
    torch_dtype=torch.float16,
    device_map="auto"
)
```

**安裝需求**：
```bash
pip install transformers>=4.36
pip install flash-attn --no-build-isolation
```

## 支援的模型架構

截至 Transformers 4.40：

**完全支援**：
- Llama / Llama 2 / Llama 3
- Mistral / Mixtral
- Falcon
- GPT-NeoX
- Phi / Phi-2 / Phi-3
- Qwen / Qwen2
- Gemma
- Starcoder2
- GPT-J
- OPT
- BLOOM

**部分支援**（Encoder-Decoder）：
- BART
- T5 / Flan-T5
- Whisper

**檢查支援情況**：
```python
from transformers import AutoConfig

config = AutoConfig.from_pretrained("model-name")
print(config._attn_implementation_internal)
# 如果支援，將顯示 'flash_attention_2'
```

## 設定範例

### 使用 Flash Attention 的 Llama 2

```python
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

model_id = "meta-llama/Llama-2-7b-hf"

model = AutoModelForCausalLM.from_pretrained(
    model_id,
    attn_implementation="flash_attention_2",
    torch_dtype=torch.float16,
    device_map="auto"
)

tokenizer = AutoTokenizer.from_pretrained(model_id)

# 生成
inputs = tokenizer("Once upon a time", return_tensors="pt").to("cuda")
outputs = model.generate(**inputs, max_length=100)
print(tokenizer.decode(outputs[0]))
```

### 針對長上下文使用 Flash Attention 的 Mistral

```python
from transformers import AutoModelForCausalLM
import torch

model = AutoModelForCausalLM.from_pretrained(
    "mistralai/Mistral-7B-v0.1",
    attn_implementation="flash_attention_2",
    torch_dtype=torch.bfloat16,  # 較適合長上下文
    device_map="auto",
    max_position_embeddings=32768  # 擴展上下文
)

# 處理長文件 (32K tokens)
long_text = "..." * 10000
inputs = tokenizer(long_text, return_tensors="pt", truncation=False).to("cuda")
outputs = model.generate(**inputs, max_new_tokens=512)
```

### 使用 Flash Attention 進行微調 (Fine-tuning)

```python
from transformers import Trainer, TrainingArguments
from transformers import AutoModelForCausalLM

model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-7b-hf",
    attn_implementation="flash_attention_2",
    torch_dtype=torch.float16
)

training_args = TrainingArguments(
    output_dir="./results",
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    num_train_epochs=3,
    fp16=True,  # 必須與模型資料類型 (dtype) 相符
    optim="adamw_torch_fused"  # 快速優化器
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset
)

trainer.train()
```

### 多 GPU 訓練

```python
from transformers import AutoModelForCausalLM
import torch

# 使用 Flash Attention 進行模型平行處理 (Model parallelism)
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-13b-hf",
    attn_implementation="flash_attention_2",
    torch_dtype=torch.float16,
    device_map="auto",  # 自動多 GPU 配置
    max_memory={0: "20GB", 1: "20GB"}  # 限制每個 GPU 的記憶體
)
```

## 效能比較

### 記憶體使用量 (Llama 2 7B, batch=1)

| 序列長度 (Sequence Length) | 標準 Attention | Flash Attention 2 | 減少量 |
|-----------------|-------------------|-------------------|-----------|
| 512 | 1.2 GB | 0.9 GB | 25% |
| 2048 | 3.8 GB | 1.4 GB | 63% |
| 8192 | 14.2 GB | 3.2 GB | 77% |
| 32768 | OOM (>24GB) | 10.8 GB | 成功執行！ |

### 速度 (tokens/sec, A100 80GB)

| 模型 | 標準 | Flash Attn 2 | 加速倍數 |
|-------|----------|--------------|---------|
| Llama 2 7B (seq=2048) | 42 | 118 | 2.8x |
| Llama 2 13B (seq=4096) | 18 | 52 | 2.9x |
| Llama 2 70B (seq=2048) | 4 | 11 | 2.75x |

### 訓練吞吐量 (samples/sec)

| 模型 | 批次大小 (Batch Size) | 標準 | Flash Attn 2 | 加速倍數 |
|-------|------------|----------|--------------|---------|
| Llama 2 7B | 4 | 1.2 | 3.1 | 2.6x |
| Llama 2 7B | 8 | 2.1 | 5.8 | 2.8x |
| Llama 2 13B | 2 | 0.6 | 1.7 | 2.8x |

## 針對特定模型問題的疑難排解

### 問題：模型不支援 Flash Attention

請檢查上方的支援清單。如果不支援，請使用 PyTorch SDPA 作為替代方案：

```python
model = AutoModelForCausalLM.from_pretrained(
    "model-name",
    attn_implementation="sdpa",  # PyTorch 原生 (速度仍然較快)
    torch_dtype=torch.float16
)
```

### 問題：載入期間 CUDA 記憶體不足 (OOM)

減少記憶體佔用空間：

```python
model = AutoModelForCausalLM.from_pretrained(
    "model-name",
    attn_implementation="flash_attention_2",
    torch_dtype=torch.float16,
    device_map="auto",
    max_memory={0: "18GB"},  # 為 KV 快取保留記憶體
    low_cpu_mem_usage=True
)
```

### 問題：推論速度低於預期

確保資料類型 (dtype) 相符：

```python
# 模型和輸入都必須是 float16/bfloat16
model = model.to(torch.float16)
inputs = tokenizer(..., return_tensors="pt").to("cuda")
inputs = {k: v.to(torch.float16) if v.dtype == torch.float32 else v
          for k, v in inputs.items()}
```

### 問題：輸出結果與標準 Attention 不同

Flash Attention 在數值上是等效的，但使用了不同的計算順序。微小的差異 (<1e-3) 是正常的：

```python
# 比較輸出
model_standard = AutoModelForCausalLM.from_pretrained("model-name", torch_dtype=torch.float16)
model_flash = AutoModelForCausalLM.from_pretrained(
    "model-name",
    attn_implementation="flash_attention_2",
    torch_dtype=torch.float16
)

inputs = tokenizer("Test", return_tensors="pt").to("cuda")

with torch.no_grad():
    out_standard = model_standard(**inputs).logits
    out_flash = model_flash(**inputs).logits

diff = (out_standard - out_flash).abs().max()
print(f"Max diff: {diff:.6f}")  # 應在 ~1e-3 到 1e-4 之間
```

### 問題：模型載入期間出現 ImportError

請安裝 flash-attn：
```bash
pip install flash-attn --no-build-isolation
```

或者停用 Flash Attention：
```python
model = AutoModelForCausalLM.from_pretrained(
    "model-name",
    attn_implementation="eager",  # 標準 PyTorch
    torch_dtype=torch.float16
)
```

## 最佳實踐

1. **始終在 Flash Attention 中使用 float16/bfloat16** (而非 float32)
2. **設置 device_map="auto"** 以進行自動記憶體管理
3. **針對長上下文使用 bfloat16** (具有更好的數值穩定性)
4. **啟用梯度檢查點 (Gradient Checkpointing)** 以進行大型模型訓練
5. **監控記憶體**，使用 `torch.cuda.max_memory_allocated()`

**整合所有最佳實踐的範例**：
```python
from transformers import AutoModelForCausalLM, TrainingArguments

model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-7b-hf",
    attn_implementation="flash_attention_2",
    torch_dtype=torch.bfloat16,  # 較適合訓練
    device_map="auto",
    low_cpu_mem_usage=True
)

# 針對記憶體啟用梯度檢查點
model.gradient_checkpointing_enable()

# 使用優化選項進行訓練
training_args = TrainingArguments(
    output_dir="./results",
    per_device_train_batch_size=8,
    gradient_accumulation_steps=2,
    bf16=True,  # 與模型資料類型相符
    optim="adamw_torch_fused",
    gradient_checkpointing=True
)
```
