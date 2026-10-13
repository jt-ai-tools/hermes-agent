# 分散式評估 (Distributed Evaluation)

本指南介紹如何使用資料並行 (Data Parallelism)、張量並行 (Tensor Parallelism) 與管線並行 (Pipeline Parallelism) 在多個 GPU 上執行評估。

## 概觀 (Overview)

分散式評估透過以下方式加速基準測試 (Benchmarking)：
- **資料並行 (Data Parallelism)**：將評估樣本分散到多個 GPU（每個 GPU 都有完整的模型副本）。
- **張量並行 (Tensor Parallelism)**：將模型權重分散到多個 GPU（適用於大型模型）。
- **管線並行 (Pipeline Parallelism)**：將模型層級分散到多個 GPU（適用於極大型模型）。

**適用時機**：
- 資料並行：模型可放入單一 GPU，但希望加快評估速度。
- 張量/管線並行：模型太大，無法放入單一 GPU。

## HuggingFace 模型 (`hf`)

### 資料並行 (Data Parallelism)（推薦）

每個 GPU 載入一份完整的模型副本，並處理一部分的評估數據。

**單一節點 (8 顆 GPU)**：
```bash
accelerate launch --multi_gpu --num_processes 8 \
  -m lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf,dtype=bfloat16 \
  --tasks mmlu,gsm8k,hellaswag \
  --batch_size 16
```

**加速效果**：接近線性（8 顆 GPU ≈ 快 8 倍）。

**記憶體**：每個 GPU 都需要完整的模型（7B 模型 ≈ 14GB × 8 = 總計 112GB）。

### 張量並行 (Tensor Parallelism)（模型分片）

針對無法放入單一 GPU 的模型，將模型權重分散到多個 GPU。

**不使用 accelerate 啟動器**：
```bash
lm_eval --model hf \
  --model_args \
    pretrained=meta-llama/Llama-2-70b-hf,\
    parallelize=True,\
    dtype=bfloat16 \
  --tasks mmlu,gsm8k \
  --batch_size 8
```

**使用 8 顆 GPU**：70B 模型 (140GB) / 8 = 每個 GPU 17.5GB ✅

**進階分片 (Advanced sharding)**：
```bash
lm_eval --model hf \
  --model_args \
    pretrained=meta-llama/Llama-2-70b-hf,\
    parallelize=True,\
    device_map_option=auto,\
    max_memory_per_gpu=40GB,\
    max_cpu_memory=100GB,\
    dtype=bfloat16 \
  --tasks mmlu
```

**選項**：
- `device_map_option`：`"auto"`（預設）、`"balanced"`、`"balanced_low_0"`。
- `max_memory_per_gpu`：每個 GPU 的最大記憶體（例如 `"40GB"`）。
- `max_cpu_memory`：用於卸載 (offloading) 的最大 CPU 記憶體。
- `offload_folder`：磁碟卸載目錄。

### 結合資料並行與張量並行

針對極大型模型，同時使用這兩種方法。

**範例：在 16 顆 GPU 上運行 70B 模型（2 份副本，每份使用 8 顆 GPU）**：
```bash
accelerate launch --multi_gpu --num_processes 2 \
  -m lm_eval --model hf \
  --model_args \
    pretrained=meta-llama/Llama-2-70b-hf,\
    parallelize=True,\
    dtype=bfloat16 \
  --tasks mmlu \
  --batch_size 8
```

**結果**：資料並行帶來 2 倍加速，且透過張量並行容納 70B 模型。

### 使用 `accelerate config` 進行配置

建立 `~/.cache/huggingface/accelerate/default_config.yaml`：
```yaml
compute_environment: LOCAL_MACHINE
distributed_type: MULTI_GPU
num_machines: 1
num_processes: 8
gpu_ids: all
mixed_precision: bf16
```

**然後執行**：
```bash
accelerate launch -m lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks mmlu
```

## vLLM 模型 (`vllm`)

vLLM 提供高度優化的分散式推論 (Inference)。

### 張量並行 (Tensor Parallelism)

**單一節點 (4 顆 GPU)**：
```bash
lm_eval --model vllm \
  --model_args \
    pretrained=meta-llama/Llama-2-70b-hf,\
    tensor_parallel_size=4,\
    dtype=auto,\
    gpu_memory_utilization=0.9 \
  --tasks mmlu,gsm8k \
  --batch_size auto
```

**記憶體**：70B 模型分散在 4 顆 GPU 上 = 每個 GPU 約 35GB。

### 資料並行 (Data Parallelism)

**多個模型副本**：
```bash
lm_eval --model vllm \
  --model_args \
    pretrained=meta-llama/Llama-2-7b-hf,\
    data_parallel_size=4,\
    dtype=auto,\
    gpu_memory_utilization=0.8 \
  --tasks hellaswag,arc_challenge \
  --batch_size auto
```

**結果**：4 個模型副本 = 4 倍吞吐量 (Throughput)。

### 結合張量並行與資料並行

**範例：8 顆 GPU = 4 TP × 2 DP**：
```bash
lm_eval --model vllm \
  --model_args \
    pretrained=meta-llama/Llama-2-70b-hf,\
    tensor_parallel_size=4,\
    data_parallel_size=2,\
    dtype=auto,\
    gpu_memory_utilization=0.85 \
  --tasks mmlu \
  --batch_size auto
```

**結果**：容納 70B 模型 (TP=4)，並獲得 2 倍加速 (DP=2)。

### 多節點 vLLM (Multi-Node vLLM)

vLLM 原生不支援多節點。請使用 Ray：

```bash
# 啟動 Ray 叢集
ray start --head --port=6379

# 執行評估
lm_eval --model vllm \
  --model_args \
    pretrained=meta-llama/Llama-2-70b-hf,\
    tensor_parallel_size=8,\
    dtype=auto \
  --tasks mmlu
```

## NVIDIA NeMo 模型 (`nemo_lm`)

### 資料複製 (Data Replication)

**在 8 顆 GPU 上運行 8 個副本**：
```bash
torchrun --nproc-per-node=8 --no-python \
  lm_eval --model nemo_lm \
  --model_args \
    path=/path/to/model.nemo,\
    devices=8 \
  --tasks hellaswag,arc_challenge \
  --batch_size 32
```

**加速效果**：接近線性（快 8 倍）。

### 張量並行 (Tensor Parallelism)

**4 向張量並行**：
```bash
torchrun --nproc-per-node=4 --no-python \
  lm_eval --model nemo_lm \
  --model_args \
    path=/path/to/70b_model.nemo,\
    devices=4,\
    tensor_model_parallel_size=4 \
  --tasks mmlu,gsm8k \
  --batch_size 16
```

### 管線並行 (Pipeline Parallelism)

**在 4 顆 GPU 上使用 2 TP × 2 PP**：
```bash
torchrun --nproc-per-node=4 --no-python \
  lm_eval --model nemo_lm \
  --model_args \
    path=/path/to/model.nemo,\
    devices=4,\
    tensor_model_parallel_size=2,\
    pipeline_model_parallel_size=2 \
  --tasks mmlu \
  --batch_size 8
```

**限制**：`devices = TP × PP`。

### 多節點 NeMo (Multi-Node NeMo)

目前 lm-evaluation-harness 尚未支援。

## SGLang 模型 (`sglang`)

### 張量並行 (Tensor Parallelism)

```bash
lm_eval --model sglang \
  --model_args \
    pretrained=meta-llama/Llama-2-70b-hf,\
    tp_size=4,\
    dtype=auto \
  --tasks gsm8k \
  --batch_size auto
```

### 資料並行 (Data Parallelism)（不建議使用）

**注意**：SGLang 正逐步淘汰資料並行，請改用張量並行。

```bash
lm_eval --model sglang \
  --model_args \
    pretrained=meta-llama/Llama-2-7b-hf,\
    dp_size=4,\
    dtype=auto \
  --tasks mmlu
```

## 效能比較 (Performance Comparison)

### 70B 模型評估 (MMLU, 5-shot)

| 方法 | GPU 數量 | 時間 | 每個 GPU 記憶體 | 備註 |
|------|------|------|------------|-------|
| HF (無並行) | 1 | 8 小時 | 140GB (OOM) | 無法容納 |
| HF (TP=8) | 8 | 2 小時 | 17.5GB | 較慢，可容納 |
| HF (DP=8) | 8 | 1 小時 | 140GB (OOM) | 無法容納 |
| vLLM (TP=4) | 4 | 30 分鐘 | 35GB | 快速！ |
| vLLM (TP=4, DP=2) | 8 | 15 分鐘 | 35GB | 最快 |

### 7B 模型評估 (多個任務)

| 方法 | GPU 數量 | 時間 | 加速倍數 |
|------|------|------|---------|
| HF (單一) | 1 | 4 小時 | 1× |
| HF (DP=4) | 4 | 1 小時 | 4× |
| HF (DP=8) | 8 | 30 分鐘 | 8× |
| vLLM (DP=8) | 8 | 15 分鐘 | 16× |

**結論**：在推論方面，vLLM 明顯比 HuggingFace 快。

## 選擇並行策略 (Choosing Parallelism Strategy)

### 決策樹 (Decision Tree)

```
模型是否可放入單一 GPU？
├─ 是：使用資料並行 (Data Parallelism)
│   ├─ HF: accelerate launch --multi_gpu --num_processes N
│   └─ vLLM: data_parallel_size=N (最快)
│
└─ 否：使用張量/管線並行 (Tensor/Pipeline Parallelism)
    ├─ 模型 < 70B:
    │   └─ vLLM: tensor_parallel_size=4
    ├─ 模型 70-175B:
    │   ├─ vLLM: tensor_parallel_size=8
    │   └─ 或 HF: parallelize=True
    └─ 模型 > 175B:
        └─ 請聯繫框架作者
```

### 記憶體估算 (Memory Estimation)

**經驗法則**：
```
記憶體 (GB) = 參數 (B) × 精度 (bytes) × 1.2 (額外開銷)
```

**範例**：
- 7B FP16：7 × 2 × 1.2 = 16.8GB ✅ 適用 A100 40GB
- 13B FP16：13 × 2 × 1.2 = 31.2GB ✅ 適用 A100 40GB
- 70B FP16：70 × 2 × 1.2 = 168GB ❌ 需要 TP=4 或 TP=8
- 70B BF16：70 × 2 × 1.2 = 168GB（與 FP16 相同）

**使用張量並行**：
```
每個 GPU 的記憶體 = 總記憶體 / TP
```

- 70B 在 4 顆 GPU 上：168GB / 4 = 每個 GPU 42GB ✅
- 70B 在 8 顆 GPU 上：168GB / 8 = 每個 GPU 21GB ✅

## 多節點評估 (Multi-Node Evaluation)

### 使用 SLURM 的 HuggingFace

**提交任務**：
```bash
#!/bin/bash
#SBATCH --nodes=4
#SBATCH --gpus-per-node=8
#SBATCH --ntasks-per-node=1

srun accelerate launch --multi_gpu \
  --num_processes $((SLURM_NNODES * 8)) \
  -m lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks mmlu,gsm8k,hellaswag \
  --batch_size 16
```

**提交**：
```bash
sbatch eval_job.sh
```

### 手動多節點設定

**在每個節點上執行**：
```bash
accelerate launch \
  --multi_gpu \
  --num_machines 4 \
  --num_processes 32 \
  --main_process_ip $MASTER_IP \
  --main_process_port 29500 \
  --machine_rank $NODE_RANK \
  -m lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks mmlu
```

**環境變數**：
- `MASTER_IP`：Rank 0 節點的 IP。
- `NODE_RANK`：每個節點分別為 0, 1, 2, 3。

## 最佳實踐 (Best Practices)

### 1. 從小規模開始

先在小樣本上進行測試：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-70b-hf,parallelize=True \
  --tasks mmlu \
  --limit 100  # 僅測試 100 個樣本
```

### 2. 監控 GPU 使用情況

```bash
# 終端機 1：執行評估
lm_eval --model hf ...

# 終端機 2：監控
watch -n 1 nvidia-smi
```

觀察重點：
- GPU 利用率 (utilization) > 90%。
- 記憶體使用穩定。
- 所有 GPU 均處於活動狀態。

### 3. 優化批次大小 (Batch Size)

```bash
# 自動設定批次大小（推薦）
--batch_size auto

# 或手動調整
--batch_size 16  # 從此處開始
--batch_size 32  # 如果記憶體允許則增加
```

### 4. 使用混合精度 (Mixed Precision)

```bash
--model_args dtype=bfloat16  # 更快，記憶體佔用更少
```

### 5. 檢查通訊狀況

對於資料並行，請檢查網路頻寬：
```bash
# 應該會看到 InfiniBand 或高速網路
nvidia-smi topo -m
```

## 疑難排解 (Troubleshooting)

### 「CUDA out of memory」(記憶體不足)

**解決方案**：
1. 增加張量並行度：
   ```bash
   --model_args tensor_parallel_size=8  # 原本為 4
   ```

2. 減少批次大小：
   ```bash
   --batch_size 4  # 原本為 16
   ```

3. 降低精度：
   ```bash
   --model_args dtype=int8  # 量化 (Quantization)
   ```

### 「NCCL error」或程式掛起 (Hanging)

**檢查項目**：
1. 所有 GPU 是否可見：`nvidia-smi`。
2. 是否已安裝 NCCL：`python -c "import torch; print(torch.cuda.nccl.version())"`。
3. 節點間的網路連線性。

**修正方法**：
```bash
export NCCL_DEBUG=INFO  # 啟用除錯日誌
export NCCL_IB_DISABLE=0  # 如果可用則使用 InfiniBand
```

### 評估速度過慢

**可能原因**：
1. **資料載入瓶頸**：預處理資料集。
2. **GPU 利用率低**：增加批次大小。
3. **通訊開銷大**：降低並行度。

**效能分析 (Profile)**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks mmlu \
  --limit 100 \
  --log_samples  # 檢查時間戳記
```

### GPU 負載不平衡

**現象**：GPU 0 使用率為 100%，其餘為 50%。

**解決方案**：使用 `device_map_option=balanced`：
```bash
--model_args parallelize=True,device_map_option=balanced
```

## 範例配置 (Example Configurations)

### 小型模型 (7B) - 快速評估

```bash
# 8 顆 A100，資料並行
accelerate launch --multi_gpu --num_processes 8 \
  -m lm_eval --model hf \
  --model_args \
    pretrained=meta-llama/Llama-2-7b-hf,\
    dtype=bfloat16 \
  --tasks mmlu,gsm8k,hellaswag,arc_challenge \
  --num_fewshot 5 \
  --batch_size 32

# 時間：約 30 分鐘
```

### 大型模型 (70B) - vLLM

```bash
# 8 顆 H100，張量並行
lm_eval --model vllm \
  --model_args \
    pretrained=meta-llama/Llama-2-70b-hf,\
    tensor_parallel_size=8,\
    dtype=auto,\
    gpu_memory_utilization=0.9 \
  --tasks mmlu,gsm8k,humaneval \
  --num_fewshot 5 \
  --batch_size auto

# 時間：約 1 小時
```

### 極大型模型 (175B+)

**需要特殊設定 - 請聯繫框架維護者**

## 參考資料 (References)

- HuggingFace Accelerate: https://huggingface.co/docs/accelerate/
- vLLM 文件: https://docs.vllm.ai/
- NeMo 文件: https://docs.nvidia.com/nemo-framework/
- lm-eval 分散式指南: `docs/model_guide.md`
