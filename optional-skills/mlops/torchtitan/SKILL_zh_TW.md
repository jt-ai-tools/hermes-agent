---
name: distributed-llm-pretraining-torchtitan
description: 使用 torchtitan 提供 PyTorch 原生的分佈式 LLM 預訓練，具備 4D 並行技術 (FSDP2, TP, PP, CP)。適用於大規模預訓練 Llama 3.1、DeepSeek V3 或自訂模型，支援 8 到 512+ 個 GPU，並結合 Float8、torch.compile 與分佈式檢查點 (distributed checkpointing)。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [torch>=2.6.0, torchtitan>=0.2.0, torchao>=0.5.0]
metadata:
  hermes:
    tags: [模型架構, 分佈式訓練, TorchTitan, FSDP2, 張量並行, 管道並行, 上下文並行, Float8, Llama, 預訓練]

---

# TorchTitan - PyTorch 原生分佈式 LLM 預訓練

## 快速入門

TorchTitan 是 PyTorch 官方的大規模 LLM 預訓練平台，具備可組合的 4D 並行技術 (FSDP2, TP, PP, CP)，在 H100 GPU 上比基準測試提速超過 65%。

**安裝**:
```bash
# 從 PyPI 安裝 (穩定版)
pip install torchtitan

# 從原始碼安裝 (最新功能，需要 PyTorch nightly 版)
git clone https://github.com/pytorch/torchtitan
cd torchtitan
pip install -r requirements.txt
```

**下載分詞器 (Tokenizer)**:
```bash
# 從 https://huggingface.co/settings/tokens 取得 HF token
python scripts/download_hf_assets.py --repo_id meta-llama/Llama-3.1-8B --assets tokenizer --hf_token=...
```

**在 8 個 GPU 上開始訓練**:
```bash
CONFIG_FILE="./torchtitan/models/llama3/train_configs/llama3_8b.toml" ./run_train.sh
```

## 常見工作流程

### 工作流程 1：在單一節點預訓練 Llama 3.1 8B

複製此檢查清單：

```
單節點預訓練：
- [ ] 步驟 1：下載分詞器
- [ ] 步驟 2：配置訓練
- [ ] 步驟 3：啟動訓練
- [ ] 步驟 4：監控與檢查點
```

**步驟 1：下載分詞器**

```bash
python scripts/download_hf_assets.py \
  --repo_id meta-llama/Llama-3.1-8B \
  --assets tokenizer \
  --hf_token=YOUR_HF_TOKEN
```

**步驟 2：配置訓練**

編輯或建立 TOML 配置文件：

```toml
# llama3_8b_custom.toml
[job]
dump_folder = "./outputs"
description = "Llama 3.1 8B 訓練"

[model]
name = "llama3"
flavor = "8B"
hf_assets_path = "./assets/hf/Llama-3.1-8B"

[optimizer]
name = "AdamW"
lr = 3e-4

[lr_scheduler]
warmup_steps = 200

[training]
local_batch_size = 2
seq_len = 8192
max_norm = 1.0
steps = 1000
dataset = "c4"

[parallelism]
data_parallel_shard_degree = -1  # 將所有 GPU 用於 FSDP

[activation_checkpoint]
mode = "selective"
selective_ac_option = "op"

[checkpoint]
enable = true
folder = "checkpoint"
interval = 500
```

**步驟 3：啟動訓練**

```bash
# 在單一節點使用 8 個 GPU
CONFIG_FILE="./llama3_8b_custom.toml" ./run_train.sh

# 或明確使用 torchrun 啟動
torchrun --nproc_per_node=8 \
  -m torchtitan.train \
  --job.config_file ./llama3_8b_custom.toml
```

**步驟 4：監控與檢查點**

TensorBoard 日誌儲存在 `./outputs/tb/`：
```bash
tensorboard --logdir ./outputs/tb
```

### 工作流程 2：使用 SLURM 進行多節點訓練

```
多節點訓練：
- [ ] 步驟 1：配置大規模並行技術
- [ ] 步驟 2：設定 SLURM 腳本
- [ ] 步驟 3：提交作業
- [ ] 步驟 4：從檢查點恢復
```

**步驟 1：配置大規模並行技術**

對於在 256 個 GPU (32 個節點) 上訓練 70B 模型：
```toml
[parallelism]
data_parallel_shard_degree = 32  # 跨 32 個 rank 使用 FSDP
tensor_parallel_degree = 8        # 節點內使用 TP (張量並行)
pipeline_parallel_degree = 1      # 70B 模型不使用 PP (管道並行)
context_parallel_degree = 1       # 針對長序列可增加此數值
```

**步驟 2：設定 SLURM 腳本**

```bash
#!/bin/bash
#SBATCH --job-name=llama70b
#SBATCH --nodes=32
#SBATCH --ntasks-per-node=8
#SBATCH --gpus-per-node=8

srun torchrun \
  --nnodes=32 \
  --nproc_per_node=8 \
  --rdzv_backend=c10d \
  --rdzv_endpoint=$MASTER_ADDR:$MASTER_PORT \
  -m torchtitan.train \
  --job.config_file ./llama3_70b.toml
```

**步驟 3：提交作業**

```bash
sbatch multinode_trainer.slurm
```

**步驟 4：從檢查點恢復**

如果配置資料夾中存在檢查點，訓練會自動恢復。

### 工作流程 3：啟用 H100 的 Float8 訓練

Float8 在 H100 GPU 上可提供 30-50% 的提速。

```
Float8 訓練：
- [ ] 步驟 1：安裝 torchao
- [ ] 步驟 2：配置 Float8
- [ ] 步驟 3：結合編譯啟動
```

**步驟 1：安裝 torchao**

```bash
USE_CPP=0 pip install git+https://github.com/pytorch/ao.git
```

**步驟 2：配置 Float8**

在您的 TOML 配置中新增：
```toml
[model]
converters = ["quantize.linear.float8"]

[quantize.linear.float8]
enable_fsdp_float8_all_gather = true
precompute_float8_dynamic_scale_for_fsdp = true
filter_fqns = ["output"]  # 排除輸出層
```

**步驟 3：結合編譯 (Compile) 啟動**

```bash
CONFIG_FILE="./llama3_8b.toml" ./run_train.sh \
  --model.converters="quantize.linear.float8" \
  --quantize.linear.float8.enable_fsdp_float8_all_gather \
  --compile.enable
```

### 工作流程 4：針對 405B 模型的 4D 並行

```
4D 並行 (FSDP + TP + PP + CP)：
- [ ] 步驟 1：建立種子檢查點 (Seed checkpoint)
- [ ] 步驟 2：配置 4D 並行
- [ ] 步驟 3：在 512 個 GPU 上啟動
```

**步驟 1：建立種子檢查點**

為了確保各個 PP 階段間的初始化一致性，這是必要的：
```bash
NGPU=1 CONFIG_FILE=./llama3_405b.toml ./run_train.sh \
  --checkpoint.enable \
  --checkpoint.create_seed_checkpoint \
  --parallelism.data_parallel_shard_degree 1 \
  --parallelism.tensor_parallel_degree 1 \
  --parallelism.pipeline_parallel_degree 1
```

**步驟 2：配置 4D 並行**

```toml
[parallelism]
data_parallel_shard_degree = 8   # FSDP
tensor_parallel_degree = 8       # 節點內使用 TP
pipeline_parallel_degree = 8     # 跨節點使用 PP
context_parallel_degree = 1      # 針對長序列使用 CP

[training]
local_batch_size = 32
seq_len = 8192
```

**步驟 3：在 512 個 GPU 上啟動**

```bash
# 64 個節點 x 8 個 GPU = 512 個 GPU
srun torchrun --nnodes=64 --nproc_per_node=8 \
  -m torchtitan.train \
  --job.config_file ./llama3_405b.toml
```

## 何時使用 vs 替代方案

**在以下情況使用 TorchTitan：**
- 從頭開始預訓練 LLM (從 8B 到 405B+)
- 需要沒有第三方依賴的 PyTorch 原生解決方案
- 需要可組合的 4D 並行技術 (FSDP2, TP, PP, CP)
- 在具備 Float8 支援的 H100 上進行訓練
- 想要與 torchtune/HuggingFace 互通的檢查點

**改用替代方案：**
- **Megatron-LM**：針對僅限 NVIDIA 部署環境追求極限效能
- **DeepSpeed**：更廣泛的 ZeRO 優化生態系統與推理支援
- **Axolotl/TRL**：進行微調 (Fine-tuning) 而非預訓練
- **LitGPT**：用於教育目的或較小規模的訓練

## 常見問題

**問題：大型模型發生記憶體溢出 (OOM)**

啟用激活檢查點 (activation checkpointing) 並減少批次大小：
```toml
[activation_checkpoint]
mode = "full"  # 而非 "selective"

[training]
local_batch_size = 1
```

或使用梯度累加：
```toml
[training]
local_batch_size = 1
global_batch_size = 32  # 累加梯度
```

**問題：TP 因非同步集合通訊 (async collectives) 導致高記憶體使用**

設定環境變數：
```bash
export TORCH_NCCL_AVOID_RECORD_STREAMS=1
```

**問題：Float8 訓練沒有變快**

Float8 僅對大型矩陣乘法 (GEMM) 有益。請過濾掉小型層：
```toml
[quantize.linear.float8]
filter_fqns = ["attention.wk", "attention.wv", "output", "auto_filter_small_kn"]
```

**問題：更改並行度後檢查點載入失敗**

使用 DCP 的重新分片 (resharding) 功能：
```bash
# 將分片檢查點轉換為單一檔案
python -m torch.distributed.checkpoint.format_utils \
  dcp_to_torch checkpoint/step-1000 checkpoint.pt
```

**問題：管道並行 (PP) 初始化**

請先建立種子檢查點 (請參閱工作流程 4 的步驟 1)。

## 支援的模型

| 模型 | 大小 | 狀態 |
|-------|-------|--------|
| Llama 3.1 | 8B, 70B, 405B | 生產級 |
| Llama 4 | 各種大小 | 實驗性 |
| DeepSeek V3 | 16B, 236B, 671B (MoE) | 實驗性 |
| GPT-OSS | 20B, 120B (MoE) | 實驗性 |
| Qwen 3 | 各種大小 | 實驗性 |
| Flux | 擴散模型 | 實驗性 |

## 效能基準測試 (H100)

| 模型 | GPU 數量 | 並行技術 | TPS/GPU | 採用技術 |
|-------|------|-------------|---------|------------|
| Llama 8B | 8 | FSDP | 5,762 | 基準 (Baseline) |
| Llama 8B | 8 | FSDP+compile+FP8 | 8,532 | +48% |
| Llama 70B | 256 | FSDP+TP+AsyncTP | 876 | 2D 並行 |
| Llama 405B | 512 | FSDP+TP+PP | 128 | 3D 並行 |

## 進階主題

**FSDP2 配置**：參閱 [references/fsdp.md](references/fsdp.md) 以了解 FSDP2 與 FSDP1 的詳細比較以及 ZeRO 等效功能。

**Float8 訓練**：參閱 [references/float8.md](references/float8.md) 以了解張量對稱 (tensorwise) 與列對稱 (rowwise) 縮放配方。

**檢查點 (Checkpointing)**：參閱 [references/checkpoint.md](references/checkpoint.md) 以了解 HuggingFace 轉換與非同步檢查點。

**新增自訂模型**：參閱 [references/custom-models.md](references/custom-models.md) 以了解 TrainSpec 協定。

## 資源

- GitHub: https://github.com/pytorch/torchtitan
- 論文: https://arxiv.org/abs/2410.06511
- ICLR 2025: https://iclr.cc/virtual/2025/poster/29620
- PyTorch 論壇: https://discuss.pytorch.org/c/distributed/torchtitan/44
