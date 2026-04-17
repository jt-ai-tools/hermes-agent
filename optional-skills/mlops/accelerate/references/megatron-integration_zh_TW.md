# Megatron 與 Accelerate 的整合

## 概述

Accelerate 支援 Megatron-LM，可用於大規模模型的訓練，支援張量平行 (Tensor Parallelism) 與管線平行 (Pipeline Parallelism)。

**Megatron 的功能**：
- **張量平行 (Tensor Parallelism, TP)**：將各層分割至多個 GPU。
- **管線平行 (Pipeline Parallelism, PP)**：將模型深度分割至多個 GPU。
- **資料平行 (Data Parallelism, DP)**：在 GPU 組之間複製模型。
- **序列平行 (Sequence Parallelism)**：為長上下文分割序列。

## 設定

### 安裝 Megatron-LM

```bash
# 複製 Megatron-LM 儲存庫
git clone https://github.com/NVIDIA/Megatron-LM.git
cd Megatron-LM
pip install -e .

# 安裝 Apex (NVIDIA 優化工具)
git clone https://github.com/NVIDIA/apex
cd apex
pip install -v --disable-pip-version-check --no-cache-dir --no-build-isolation \
  --config-settings "--build-option=--cpp_ext" --config-settings "--build-option=--cuda_ext" ./
```

### Accelerate 配置

```bash
accelerate config
```

**問答過程**：
```
In which compute environment are you running? (您在哪個運算環境中執行？)
> This machine (此機器)

Which type of machine are you using? (您使用哪種類型的機器？)
> Multi-GPU (多 GPU)

How many different machines will you use? (您將使用多少台不同的機器？)
> 1

Do you want to use DeepSpeed/FSDP? (是否要使用 DeepSpeed/FSDP？)
> No (否)

Do you want to use Megatron-LM? (是否要使用 Megatron-LM？)
> Yes (是)

What is the Tensor Parallelism degree? [1-8] (張量平行程度是多少？)
> 2

Do you want to enable Sequence Parallelism? (是否要啟用序列平行？)
> No (否)

What is the Pipeline Parallelism degree? [1-8] (管線平行程度是多少？)
> 2

What is the Data Parallelism degree? [1-8] (資料平行程度是多少？)
> 2

Where to perform activation checkpointing? ['SELECTIVE', 'FULL', 'NONE'] (在哪裡執行活化值檢查點？)
> SELECTIVE (選擇性)

Where to perform activation partitioning? ['SEQUENTIAL', 'UNIFORM'] (在哪裡執行活化值分割？)
> SEQUENTIAL (順序)
```

**產生的配置** (`~/.cache/huggingface/accelerate/default_config.yaml`)：
```yaml
compute_environment: LOCAL_MACHINE
distributed_type: MEGATRON_LM
downcast_bf16: 'no'
machine_rank: 0
main_training_function: main
megatron_lm_config:
  megatron_lm_gradient_clipping: 1.0
  megatron_lm_learning_rate_decay_iters: 320000
  megatron_lm_num_micro_batches: 1
  megatron_lm_pp_degree: 2
  megatron_lm_recompute_activations: true
  megatron_lm_sequence_parallelism: false
  megatron_lm_tp_degree: 2
mixed_precision: bf16
num_machines: 1
num_processes: 8
rdzv_backend: static
same_network: true
tpu_env: []
tpu_use_cluster: false
tpu_use_sudo: false
use_cpu: false
```

## 平行策略

### 張量平行 (Tensor Parallelism, TP)

**將每個 Transformer 層分割至多個 GPU**：

```python
# 將層分割至 2 個 GPU
# GPU 0: 前一半的注意力頭 (attention heads)
# GPU 1: 後一半的注意力頭

# 每個 GPU 計算部分輸出
# 使用 All-reduce 合併結果
```

**TP 程度建議**：
- **TP=1**：無張量平行 (每個層使用單個 GPU)。
- **TP=2**：每個層使用 2 個 GPU (適合 7-13B 模型)。
- **TP=4**：每個層使用 4 個 GPU (適合 20-40B 模型)。
- **TP=8**：每個層使用 8 個 GPU (適合 70B+ 模型)。

**優點**：
- 減少每個 GPU 的記憶體負擔。
- All-reduce 通訊速度快。

**缺點**：
- 需要快速的 GPU 間頻寬 (NVLink)。
- 每一層都有通訊開銷。

### 管線平行 (Pipeline Parallelism, PP)

**將模型深度分割至多個 GPU**：

```python
# 12 層模型，PP=4
# GPU 0: 第 0-2 層
# GPU 1: 第 3-5 層
# GPU 2: 第 6-8 層
# GPU 3: 第 9-11 層
```

**PP 程度建議**：
- **PP=1**：無管線平行。
- **PP=2**：2 個管線階段 (適合 20-40B 模型)。
- **PP=4**：4 個管線階段 (適合 70B+ 模型)。
- **PP=8**：8 個管線階段 (適合 175B+ 模型)。

**優點**：
- 線性減少記憶體使用 (4x PP = 減少 4 倍記憶體)。
- 可跨節點運作 (較慢的互連頻寬亦可)。

**缺點**：
- 管線氣泡 (Pipeline bubbles，即閒置時間)。
- 需要微批次 (micro-batching)。

### 資料平行 (Data Parallelism, DP)

**在 GPU 組之間複製模型**：

```python
# 8 個 GPU, TP=2, PP=2, DP=2
# 第 0 組 (GPU 0-3): 模型完整副本
# 第 1 組 (GPU 4-7): 模型完整副本
```

**DP 程度**：
- `DP = 總 GPU 數 / (TP × PP)`
- 範例：8 個 GPU, TP=2, PP=2 → DP=2

**優點**：
- 增加吞吐量。
- 可擴展批次大小。

### 序列平行 (Sequence Parallelism)

**將長序列分割至多個 GPU** (TP 的延伸)：

```python
# 8K 序列, TP=2, 序列平行=True
# GPU 0: Token 0-4095
# GPU 1: Token 4096-8191
```

**優點**：
- 支援極長序列 (100K+ token)。
- 減少活化值 (activation) 記憶體。

**需求**：
- 必須與 TP > 1 配合使用。
- 使用 RoPE/ALiBi 位置編碼效果最佳。

## Accelerate 程式碼範例

### 基礎設定

```python
from accelerate import Accelerator
from accelerate.utils import MegatronLMPlugin

# 配置 Megatron
megatron_plugin = MegatronLMPlugin(
    tp_degree=2,              # 張量平行程度
    pp_degree=2,              # 管線平行程度
    num_micro_batches=4,      # 管線的微批次數量
    gradient_clipping=1.0,    # 梯度裁剪值
    sequence_parallelism=False,  # 啟用序列平行
    recompute_activations=True,  # 活化值檢查點
    use_distributed_optimizer=True,  # 分散式優化器
    custom_prepare_model_function=None,  # 自定義模型準備
)

# 初始化 accelerator
accelerator = Accelerator(
    mixed_precision='bf16',
    megatron_lm_plugin=megatron_plugin
)

# 準備模型與優化器
model, optimizer, train_dataloader = accelerator.prepare(
    model, optimizer, train_dataloader
)

# 訓練迴圈 (與 DDP 相同！)
for batch in train_dataloader:
    optimizer.zero_grad()
    outputs = model(**batch)
    loss = outputs.loss
    accelerator.backward(loss)
    optimizer.step()
```

### 完整訓練腳本

```python
import torch
from accelerate import Accelerator
from accelerate.utils import MegatronLMPlugin
from transformers import GPT2Config, GPT2LMHeadModel

def main():
    # Megatron 配置
    megatron_plugin = MegatronLMPlugin(
        tp_degree=2,
        pp_degree=2,
        num_micro_batches=4,
        gradient_clipping=1.0,
    )

    accelerator = Accelerator(
        mixed_precision='bf16',
        gradient_accumulation_steps=8,
        megatron_lm_plugin=megatron_plugin
    )

    # 模型
    config = GPT2Config(
        n_layer=24,
        n_head=16,
        n_embd=1024,
    )
    model = GPT2LMHeadModel(config)

    # 優化器
    optimizer = torch.optim.AdamW(model.parameters(), lr=6e-4)

    # 準備
    model, optimizer, train_loader = accelerator.prepare(
        model, optimizer, train_loader
    )

    # 訓練迴圈
    for epoch in range(num_epochs):
        for batch in train_loader:
            with accelerator.accumulate(model):
                outputs = model(**batch)
                loss = outputs.loss
                accelerator.backward(loss)
                optimizer.step()
                optimizer.zero_grad()

        # 儲存檢查點
        accelerator.wait_for_everyone()
        accelerator.save_state(f'checkpoint-epoch-{epoch}')

if __name__ == '__main__':
    main()
```

### 啟動指令

```bash
# 8 個 GPU, TP=2, PP=2, DP=2
accelerate launch --multi_gpu --num_processes 8 train.py

# 多節點 (2 個節點，每個節點 8 個 GPU)
# 節點 0
accelerate launch --multi_gpu --num_processes 16 \
  --num_machines 2 --machine_rank 0 \
  --main_process_ip $MASTER_ADDR \
  --main_process_port 29500 \
  train.py

# 節點 1
accelerate launch --multi_gpu --num_processes 16 \
  --num_machines 2 --machine_rank 1 \
  --main_process_ip $MASTER_ADDR \
  --main_process_port 29500 \
  train.py
```

## 活化值檢查點 (Activation Checkpointing)

**透過重新計算活化值來減少記憶體使用**：

```python
megatron_plugin = MegatronLMPlugin(
    recompute_activations=True,      # 啟用檢查點
    checkpoint_num_layers=1,         # 每 N 層建立一個檢查點
    distribute_checkpointed_activations=True,  # 在 TP 中分散檢查點
    partition_activations=True,      # 在 PP 中分割活化值
    check_for_nan_in_loss_and_grad=True,  # 穩定性檢查
)
```

**策略**：
- `SELECTIVE`：僅對 Transformer 區塊建立檢查點。
- `FULL`：對所有層建立檢查點。
- `NONE`：不建立檢查點。

**記憶體節省**：30-50%，伴隨 10-15% 的速度降低。

## 分散式優化器 (Distributed Optimizer)

**在 DP 秩 (ranks) 之間分片優化器狀態**：

```python
megatron_plugin = MegatronLMPlugin(
    use_distributed_optimizer=True,  # 啟用分片優化器
)
```

**優點**：
- 根據 DP 程度比例減少優化器記憶體。
- 範例：DP=4 → 每個 GPU 的優化器記憶體減少 4 倍。

**相容性**：
- AdamW, Adam, SGD。
- 混合精度訓練。

## 效能微調

### 微批次大小 (Micro-Batch Size)

```python
# 管線平行需要使用微批次
megatron_plugin = MegatronLMPlugin(
    pp_degree=4,
    num_micro_batches=16,  # 每個管線 16 個微批次
)

# 有效批次 = 微批次數量 × 微批次大小 × DP
# 範例：16 × 2 × 4 = 128
```

**建議**：
- 更多的微批次 → 更少的管線氣泡。
- 典型值：4-16 個微批次。

### 序列長度

```python
# 對於長序列，啟用序列平行
megatron_plugin = MegatronLMPlugin(
    tp_degree=4,
    sequence_parallelism=True,  # 必須設定：TP > 1
)

# 支援的序列長度最高可達 TP × 原本限制
# 範例：TP=4，原本限制 8K → 序列平行下可達 32K
```

### GPU 拓撲

**TP 運作需要 NVLink**：
```bash
# 檢查 NVLink 拓撲
nvidia-smi topo -m

# 良好的拓撲 (所有 GPU 之間都有 NVLink)
# GPU0 - GPU1: NV12 (快)
# GPU0 - GPU2: NV12 (快)

# 不良的拓撲 (僅使用 PCIe)
# GPU0 - GPU4: PHB (慢，避免對這些 GPU 進行 TP)
```

**建議**：
- **TP**：位於相同節點內 (使用 NVLink)。
- **PP**：可跨節點 (較慢的互連頻寬亦可)。
- **DP**：任何拓撲皆可。

## 模型大小建議指南

| 模型大小 | GPU 數 | TP | PP | DP | 微批次數量 |
|------------|------|----|----|----|--------------|
| 7B | 8 | 1 | 1 | 8 | 1 |
| 13B | 8 | 2 | 1 | 4 | 1 |
| 20B | 16 | 4 | 1 | 4 | 1 |
| 40B | 32 | 4 | 2 | 4 | 4 |
| 70B | 64 | 8 | 2 | 4 | 8 |
| 175B | 128 | 8 | 4 | 4 | 16 |

**假設條件**：BF16，2K 序列長度，A100 80GB。

## 檢查點 (Checkpointing)

### 儲存檢查點

```python
# 儲存完整的模型狀態
accelerator.save_state('checkpoint-1000')

# Megatron 會為每個秩儲存不同的檔案
# checkpoint-1000/
#   pytorch_model_tp_0_pp_0.bin
#   pytorch_model_tp_0_pp_1.bin
#   pytorch_model_tp_1_pp_0.bin
#   pytorch_model_tp_1_pp_1.bin
#   optimizer_tp_0_pp_0.bin
#   ...
```

### 載入檢查點

```python
# 恢復訓練
accelerator.load_state('checkpoint-1000')

# 自動為每個秩載入正確的分片
```

### 轉換為標準 PyTorch 格式

```bash
# 將 Megatron 檢查點合併為單一檔案
python merge_megatron_checkpoint.py \
  --checkpoint-dir checkpoint-1000 \
  --output pytorch_model.bin
```

## 常見問題

### 問題：使用管線平行時發生 OOM

**解決方法**：增加微批次數量。
```python
megatron_plugin = MegatronLMPlugin(
    pp_degree=4,
    num_micro_batches=16,  # 從 4 增加
)
```

### 問題：訓練速度慢

**檢查 1**：管線氣泡 (PP 過高)。
```python
# 減少 PP，增加 TP
tp_degree=4  # 增加
pp_degree=2  # 減少
```

**檢查 2**：微批次大小太小。
```python
num_micro_batches=8  # 增加
```

### 問題：未偵測到 NVLink

```bash
# 驗證 NVLink
nvidia-smi nvlink -s

# 如果沒有 NVLink，避免 TP > 1
# 改用 PP 或 DP
```

## 資源

- Megatron-LM：https://github.com/NVIDIA/Megatron-LM
- Accelerate Megatron 文件：https://huggingface.co/docs/accelerate/usage_guides/megatron_lm
- 論文："Megatron-LM: Training Multi-Billion Parameter Language Models Using Model Parallelism"
- NVIDIA Apex：https://github.com/NVIDIA/apex
