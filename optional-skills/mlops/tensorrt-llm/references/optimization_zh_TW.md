# TensorRT-LLM 優化指南

使用 TensorRT-LLM 優化大語言模型（LLM）推論的全面指南。

## 量化 (Quantization)

### FP8 量化（推薦用於 H100）

**優點**：
- 推論速度提升 2 倍
- 記憶體占用減少 50%
- 準確度損失極小（Perplexity 下降 <1%）

**用法**：
```python
from tensorrt_llm import LLM

# 自動 FP8 量化
llm = LLM(
    model="meta-llama/Meta-Llama-3-70B",
    dtype="fp8",
    quantization="fp8"
)
```

**效能**（Llama 3-70B 在 8× H100 上）：
- FP16：5,000 tokens/sec
- FP8：**10,000 tokens/sec**（2 倍加速）
- 記憶體：140GB → 70GB

### INT4 量化（最大壓縮）

**優點**：
- 記憶體占用減少 4 倍
- 推論速度提升 3-4 倍
- 在相同硬體上容納更大的模型

**用法**：
```python
# 使用 AWQ 校準的 INT4
llm = LLM(
    model="meta-llama/Meta-Llama-3-405B",
    dtype="int4_awq",
    quantization="awq"
)

# 使用 GPTQ 校準的 INT4
llm = LLM(
    model="meta-llama/Meta-Llama-3-405B",
    dtype="int4_gptq",
    quantization="gptq"
)
```

**權衡**：
- 準確度：Perplexity 增加 1-3%
- 速度：比 FP16 快 3-4 倍
- 使用場景：當記憶體極度受限時

## 飛航中批處理 (In-Flight Batching)

**功能**：在生成過程中動態批處理請求，而不是等待所有序列完成。

**配置**：
```python
# 伺服器配置
trtllm-serve meta-llama/Meta-Llama-3-8B \
    --max_batch_size 256 \           # 最大同時執行的序列數
    --max_num_tokens 4096 \           # 批處理中的總 token 數
    --enable_chunked_context \        # 拆分長提示詞 (Prompt)
    --scheduler_policy max_utilization
```

**效能**：
- 吞吐量：比靜態批處理高 **4-8 倍**
- 延遲：混合工作負載的 P50/P99 更低
- GPU 利用率：80-95% (相比 40-60%)

## 分頁 KV 快取 (Paged KV Cache)

**功能**：像作業系統管理虛擬記憶體（分頁）一樣管理 KV 快取記憶體。

**優點**：
- 吞吐量提高 40-60%
- 無記憶體碎片
- 支援更長的序列

**配置**：
```python
# 自動分頁 KV 快取 (預設)
llm = LLM(
    model="meta-llama/Meta-Llama-3-8B",
    kv_cache_free_gpu_mem_fraction=0.9,  # 使用 90% GPU 記憶體作為快取
    enable_prefix_caching=True            # 快取通用前綴
)
```

## 推測解碼 (Speculative Decoding)

**功能**：使用小型草稿模型（draft model）預測多個 token，並由目標模型並行驗證。

**加速**：對於長文本生成，速度提升 2-3 倍

**用法**：
```python
from tensorrt_llm import LLM

# 目標模型 (Llama 3-70B)
llm = LLM(
    model="meta-llama/Meta-Llama-3-70B",
    speculative_model="meta-llama/Meta-Llama-3-8B",  # 草稿模型
    num_speculative_tokens=5                          # 提前預測的 token 數
)

# 相同的 API，速度提升 2-3 倍
outputs = llm.generate(prompts)
```

**最佳草稿模型組合**：
- 目標：Llama 3-70B → 草稿：Llama 3-8B
- 目標：Qwen2-72B → 草稿：Qwen2-7B
- 建議選擇同系列但小 8-10 倍的模型

## CUDA Graphs

**功能**：透過記錄 GPU 操作來減少核心（kernel）啟動開銷。

**優點**：
- 延遲降低 10-20%
- P99 延遲更穩定
- 對小批處理量更有利

**配置**（預設自動開啟）：
```python
llm = LLM(
    model="meta-llama/Meta-Llama-3-8B",
    enable_cuda_graph=True,  # 預設：True
    cuda_graph_cache_size=2  # 快取 2 個圖變體
)
```

## 分塊上下文 (Chunked Context)

**功能**：將長提示詞拆分為多個塊，以減少記憶體峰值。

**使用場景**：提示詞 >8K token 且 GPU 記憶體有限

**配置**：
```bash
trtllm-serve meta-llama/Meta-Llama-3-8B \
    --max_num_tokens 4096 \
    --enable_chunked_context \
    --max_chunked_prefill_length 2048  # 每次處理 2K token
```

## 重疊調度 (Overlap Scheduling)

**功能**：使計算與記憶體操作重疊執行。

**優點**：
- 吞吐量提高 15-25%
- 更好的 GPU 利用率
- 在 v1.2.0+ 版本中為預設開啟

**無需配置** - 自動啟用。

## 量化方法對比表

| 方法 | 記憶體 | 速度 | 準確度 | 使用場景 |
|--------|--------|-------|----------|----------|
| FP16 | 1× (基準) | 1× | 最佳 | 需要高準確度 |
| FP8 | 0.5× | 2× | -0.5% ppl | **H100 預設** |
| INT4 AWQ | 0.25× | 3-4× | -1.5% ppl | 記憶體極度受限 |
| INT4 GPTQ | 0.25× | 3-4× | -2% ppl | 追求最大速度 |

## 調優流程

1. **從預設值開始**：
   ```python
   llm = LLM(model="meta-llama/Meta-Llama-3-70B")
   ```

2. **啟用 FP8**（若是 H100）：
   ```python
   llm = LLM(model="...", dtype="fp8")
   ```

3. **調優批處理量 (Batch Size)**：
   ```python
   # 增加直到發生 OOM，然後減少 20%
   trtllm-serve ... --max_batch_size 256
   ```

4. **啟用分塊上下文**（若有長提示詞）：
   ```bash
   --enable_chunked_context --max_chunked_prefill_length 2048
   ```

5. **嘗試推測解碼**（若延遲是關鍵）：
   ```python
   llm = LLM(model="...", speculative_model="...")
   ```

## 基準測試 (Benchmarking)

```bash
# 安裝基準測試工具
pip install tensorrt_llm[benchmark]

# 執行基準測試
python benchmarks/python/benchmark.py \
    --model meta-llama/Meta-Llama-3-8B \
    --batch_size 64 \
    --input_len 128 \
    --output_len 256 \
    --dtype fp8
```

**需追蹤的指標**：
- 吞吐量 (Throughput, tokens/sec)
- 延遲 P50/P90/P99 (ms)
- GPU 記憶體使用量 (GB)
- GPU 利用率 (%)

## 常見問題

**OOM (記憶體溢出) 錯誤**：
- 減少 `max_batch_size`
- 減少 `max_num_tokens`
- 啟用 INT4 量化
- 增加 `tensor_parallel_size`

**吞吐量過低**：
- 增加 `max_batch_size`
- 啟用飛航中批處理 (In-flight batching)
- 驗證 CUDA graphs 是否已啟用
- 檢查 GPU 利用率

**延遲過高**：
- 嘗試推測解碼
- 減少 `max_batch_size`（減少排隊等待）
- 使用 FP8 代替 FP16
