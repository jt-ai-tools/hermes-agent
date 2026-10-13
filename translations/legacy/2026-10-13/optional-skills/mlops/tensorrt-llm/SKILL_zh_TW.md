---
name: tensorrt-llm
description: 使用 NVIDIA TensorRT 優化 LLM 推論，實現最大吞吐量和最低延遲。適用於 NVIDIA GPU (A100/H100) 的生產部署、需要比 PyTorch 快 10-100 倍的推論速度，或服務於量化 (FP8/INT4)、動態批次處理 (In-flight batching) 和多 GPU 擴展的模型。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [tensorrt-llm, torch]
metadata:
  hermes:
    tags: [Inference Serving, TensorRT-LLM, NVIDIA, Inference Optimization, High Throughput, Low Latency, Production, FP8, INT4, In-Flight Batching, Multi-GPU]

---

# TensorRT-LLM

NVIDIA 的開源庫，用於優化 LLM 推論，在 NVIDIA GPU 上實現最先進的性能。

## 何時使用 TensorRT-LLM

**在以下情況使用 TensorRT-LLM：**
- 部署在 NVIDIA GPU 上 (A100, H100, GB200)
- 需要最大吞吐量（Llama 3 在某些配置下可達 24,000+ tokens/sec）
- 實時應用需要低延遲
- 使用量化模型 (FP8, INT4, FP4)
- 跨多個 GPU 或節點擴展

**在以下情況改用 vLLM：**
- 需要更簡單的設置和 Python 優先的 API
- 需要 PagedAttention 但不想進行 TensorRT 編譯
- 在 AMD GPU 或非 NVIDIA 硬體上運行

**在以下情況改用 llama.cpp：**
- 部署在 CPU 或 Apple Silicon 上
- 需要在沒有 NVIDIA GPU 的邊緣設備部署
- 偏好更簡單的 GGUF 量化格式

## 快速開始

### 安裝

```bash
# Docker (推薦)
docker pull nvidia/tensorrt_llm:latest

# pip 安裝
pip install tensorrt_llm==1.2.0rc3

# 需要 CUDA 13.0.0, TensorRT 10.13.2, Python 3.10-3.12
```

### 基礎推論

```python
from tensorrt_llm import LLM, SamplingParams

# 初始化模型
llm = LLM(model="meta-llama/Meta-Llama-3-8B")

# 配置採樣
sampling_params = SamplingParams(
    max_tokens=100,
    temperature=0.7,
    top_p=0.9
)

# 生成
prompts = ["Explain quantum computing"]
outputs = llm.generate(prompts, sampling_params)

for output in outputs:
    print(output.text)
```

### 使用 trtllm-serve 提供服務

```bash
# 啟動伺服器（自動模型下載與編譯）
trtllm-serve meta-llama/Meta-Llama-3-8B \
    --tp_size 4 \              # 張量並行 (4 個 GPU)
    --max_batch_size 256 \
    --max_num_tokens 4096

# 客戶端請求
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Meta-Llama-3-8B",
    "messages": [{"role": "user", "content": "Hello!"}],
    "temperature": 0.7,
    "max_tokens": 100
  }'
```

## 核心特性

### 性能優化
- **動態批次處理 (In-flight batching)**：在生成過程中進行動態批次處理
- **Paged KV 快取**：高效的記憶體管理
- **Flash Attention**：優化的注意力機制內核
- **量化**：支援 FP8, INT4, FP4，實現 2-4 倍的推論加速
- **CUDA 圖形 (Graphs)**：減少內核啟動開銷

### 並行化
- **張量並行 (Tensor parallelism, TP)**：將模型切分到多個 GPU
- **流水線並行 (Pipeline parallelism, PP)**：層級分佈
- **專家並行 (Expert parallelism)**：適用於混合專家 (MoE) 模型
- **多節點**：擴展至單機之外

### 進階功能
- **投機解碼 (Speculative decoding)**：使用草稿模型加速生成
- **LoRA 服務**：高效的多適配器 (multi-adapter) 部署
- **分離式服務 (Disaggregated serving)**：將 prefill 和 generation 階段分開

## 常見模式

### 量化模型 (FP8)

```python
from tensorrt_llm import LLM

# 載入 FP8 量化模型（快 2 倍，節省 50% 記憶體）
llm = LLM(
    model="meta-llama/Meta-Llama-3-70B",
    dtype="fp8",
    max_num_tokens=8192
)

# 推論方式與之前相同
outputs = llm.generate(["Summarize this article..."])
```

### 多 GPU 部署

```python
# 跨 8 個 GPU 的張量並行
llm = LLM(
    model="meta-llama/Meta-Llama-3-405B",
    tensor_parallel_size=8,
    dtype="fp8"
)
```

### 批次推論

```python
# 高效處理 100 個提示
prompts = [f"Question {i}: ..." for i in range(100)]

outputs = llm.generate(
    prompts,
    sampling_params=SamplingParams(max_tokens=200)
)

# 自動動態批次處理以實現最大吞吐量
```

## 性能基準

**Meta Llama 3-8B** (H100 GPU):
- 吞吐量：24,000 tokens/sec
- 延遲：每 token 約 10ms
- 對比 PyTorch：**快 100 倍**

**Llama 3-70B** (8× A100 80GB):
- FP8 量化：比 FP16 快 2 倍
- 記憶體：使用 FP8 減少 50%

## 支援模型

- **LLaMA 系列**：Llama 2, Llama 3, CodeLlama
- **GPT 系列**：GPT-2, GPT-J, GPT-NeoX
- **通義千問 (Qwen)**：Qwen, Qwen2, QwQ
- **DeepSeek**：DeepSeek-V2, DeepSeek-V3
- **Mixtral**：Mixtral-8x7B, Mixtral-8x22B
- **視覺模型**：LLaVA, Phi-3-vision
- **100+ 模型** 已在 HuggingFace 上架

## 參考資料

- **[優化指南](references/optimization.md)** - 量化、批次處理、KV 快取調優
- **[多 GPU 設置](references/multi-gpu.md)** - 張量/流水線並行、多節點
- **[服務指南](references/serving.md)** - 生產部署、監控、自動擴展

## 相關資源

- **文件**：https://nvidia.github.io/TensorRT-LLM/
- **GitHub**：https://github.com/NVIDIA/TensorRT-LLM
- **模型**：https://huggingface.co/models?library=tensorrt_llm
