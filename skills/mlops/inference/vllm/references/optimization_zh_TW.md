# 效能最佳化 (Performance Optimization)

## 目錄
- PagedAttention 解析
- 連續批次處理 (Continuous batching) 機制
- 前綴快取 (Prefix caching) 策略
- 投機解碼 (Speculative decoding) 設定
- 基準測試 (Benchmark) 結果與比較
- 效能調優指南

## PagedAttention 解析

**傳統 Attention 的問題**：
- KV 快取儲存在連續記憶體中
- 由於碎片化問題，浪費約 50% 的 GPU 記憶體
- 無法針對變動的序列長度進行動態重新分配

**PagedAttention 解決方案**：
- 將 KV 快取劃分為固定大小的區塊 (類似作業系統的虛擬記憶體)
- 從空閒區塊隊列進行動態分配
- 在不同序列間共享區塊 (用於前綴快取)

**節省記憶體範例**：
```
傳統方式：70B 模型需要 160GB KV 快取 → 在 8x A100 上發生 OOM
PagedAttention：70B 模型需要 80GB KV 快取 → 可裝載於 4x A100
```

**配置**：
```bash
# 區塊大小 (預設：16 tokens)
vllm serve MODEL --block-size 16

# GPU 區塊數量 (自動計算)
# 由 --gpu-memory-utilization 控制
vllm serve MODEL --gpu-memory-utilization 0.9
```

## 連續批次處理 (Continuous batching) 機制

**傳統批次處理 (Traditional batching)**：
- 等待批次中的所有序列完成
- 在等待最長序列時 GPU 處於閒置狀態
- GPU 使用率低 (~40-60%)

**連續批次處理 (Continuous batching)**：
- 當有空位時立即加入新請求
- 在同一個批次中混合 prefill (新請求) 和 decode (進行中)
- GPU 使用率高 (>90%)

**吞吐量提升**：
```
傳統批次處理：50 req/sec @ 50% GPU 使用率
連續批次處理：200 req/sec @ 90% GPU 使用率
= 4 倍的吞吐量提升
```

**調優參數**：
```bash
# 最大並發序列數 (愈高 = 批次處理能力愈強)
vllm serve MODEL --max-num-seqs 256

# Prefill/decode 排程 (預設自動平衡)
# 無需手動調優
```

## 前綴快取 (Prefix caching) 策略

針對常見的提示詞前綴，重複使用已計算的 KV 快取。

**使用情境**：
- 跨請求重複使用的系統提示詞 (System prompts)
- 每個提示詞中都包含的 Few-shot 範例
- 具有重疊區塊的 RAG 上下文

**節省效能範例**：
```
提示詞：[系統提示詞：500 tokens] + [使用者請求：100 tokens]

不使用快取：每次請求計算 600 tokens
使用快取：計算一次 500 tokens，之後每次請求計算 100 tokens
= TTFT 加快 83%
```

**啟用前綴快取**：
```bash
vllm serve MODEL --enable-prefix-caching
```

**自動前綴偵測**：
- vLLM 會自動偵測常見前綴
- 無需更改程式碼
- 支援 OpenAI 相容 API

**監控快取命中率 (Cache hit rate)**：
```bash
curl http://localhost:9090/metrics | grep cache_hit
# vllm_cache_hit_rate: 0.75  (75% 命中率)
```

## 投機解碼 (Speculative decoding) 設定

使用較小的「草稿」(Draft) 模型來預測 token，再由較大的模型進行驗證。

**速度提升**：
```
標準模式：每次前向傳播生成 1 個 token
投機解碼：每次前向傳播生成 3-5 個 tokens
= 生成速度提升 2-3 倍
```

**運作原理**：
1. 草稿模型預測 K 個 tokens (速度快)
2. 目標模型並行驗證所有 K 個 tokens (一次傳播)
3. 接受已驗證的 tokens，從第一個被拒絕的地方重新開始

**使用獨立草稿模型設定**：
```bash
vllm serve meta-llama/Llama-3-70B-Instruct \
  --speculative-model TinyLlama/TinyLlama-1.1B-Chat-v1.0 \
  --num-speculative-tokens 5
```

**使用 n-gram 草稿設定** (無需額外模型)：
```bash
vllm serve MODEL \
  --speculative-method ngram \
  --num-speculative-tokens 3
```

**何時使用**：
- 輸出長度 > 100 tokens
- 草稿模型比目標模型小 5-10 倍
- 可接受 2-3% 的準確度折衷

## 基準測試 (Benchmark) 結果

**vLLM vs HuggingFace Transformers** (Llama 3 8B, A100):
```
指標                    | HF Transformers | vLLM   | 提升幅度
------------------------|-----------------|--------|------------
吞吐量 (req/sec)        | 12              | 280    | 23x
TTFT (ms)              | 850             | 120    | 7x
Tokens/sec             | 45              | 2,100  | 47x
GPU 記憶體 (GB)         | 28              | 16     | 節省 1.75x
```

**vLLM vs TensorRT-LLM** (Llama 2 70B, 4x A100):
```
指標                    | TensorRT-LLM | vLLM   | 備註
------------------------|--------------|--------|------------------
吞吐量 (req/sec)        | 320          | 285    | TRT 快 12%
部署複雜度              | 高           | 低      | vLLM 容易許多
僅限 NVIDIA            | 是           | 否      | vLLM 支援多平台
量化支援                | FP8, INT8    | AWQ/GPTQ/FP8 | vLLM 選項更多
```

## 效能調優指南

**步驟 1：測量基準線 (Baseline)**

```bash
# 安裝基準測試工具
pip install locust

# 執行基準測試
vllm bench throughput \
  --model MODEL \
  --input-tokens 128 \
  --output-tokens 256 \
  --num-prompts 1000

# 記錄：吞吐量、TTFT、tokens/sec
```

**步驟 2：調優記憶體使用率 (Memory utilization)**

```bash
# 嘗試不同數值：0.7, 0.85, 0.9, 0.95
vllm serve MODEL --gpu-memory-utilization 0.9
```

數值愈高 = 批次處理容量愈大 = 吞吐量愈高，但有 OOM 風險。

**步驟 3：調優並發數 (Concurrency)**

```bash
# 嘗試數值：128, 256, 512, 1024
vllm serve MODEL --max-num-seqs 256
```

數值愈高 = 更多批次處理機會，但可能會增加延遲。

**步驟 4：啟用最佳化功能**

```bash
vllm serve MODEL \
  --enable-prefix-caching \     # 用於重複提示詞
  --enable-chunked-prefill \    # 用於長提示詞
  --gpu-memory-utilization 0.9 \
  --max-num-seqs 512
```

**步驟 5：重新測試並比較**

目標提升幅度：
- 吞吐量: +30-100%
- TTFT: -20-50%
- GPU 使用率: >85%

**常見效能問題**：

**吞吐量低 (<50 req/sec)**：
- 增加 `--max-num-seqs`
- 啟用 `--enable-prefix-caching`
- 檢查 GPU 使用率 (應 >80%)

**TTFT 高 (>1 秒)**：
- 啟用 `--enable-chunked-prefill`
- 若可能，減少 `--max-model-len`
- 檢查模型對於 GPU 是否過大

**OOM 錯誤**：
- 將 `--gpu-memory-utilization` 降至 0.7
- 減少 `--max-model-len`
- 使用量化 (`--quantization awq`)
