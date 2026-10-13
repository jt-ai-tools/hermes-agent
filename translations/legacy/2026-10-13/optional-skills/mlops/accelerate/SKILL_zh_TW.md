---
name: huggingface-accelerate
description: 最簡單的分佈式訓練 API。只需 4 行程式碼即可為任何 PyTorch 腳本新增分佈式支援。統一支援 DeepSpeed/FSDP/Megatron/DDP 的 API。自動裝置配置、混合精度 (FP16/BF16/FP8)。互動式配置，單一啟動指令。HuggingFace 生態系統標準。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [accelerate, torch, transformers]
metadata:
  hermes:
    tags: [分佈式訓練, HuggingFace, Accelerate, DeepSpeed, FSDP, 混合精度, PyTorch, DDP, 統一 API, 簡單]

---

# HuggingFace Accelerate - 統一的分佈式訓練

## 快速入門

Accelerate 將分佈式訓練簡化為 4 行程式碼。

**安裝**:
```bash
pip install accelerate
```

**轉換 PyTorch 腳本** (4 行):
```python
import torch
+ from accelerate import Accelerator

+ accelerator = Accelerator()

  model = torch.nn.Transformer()
  optimizer = torch.optim.Adam(model.parameters())
  dataloader = torch.utils.data.DataLoader(dataset)

+ model, optimizer, dataloader = accelerator.prepare(model, optimizer, dataloader)

  for batch in dataloader:
      optimizer.zero_grad()
      loss = model(batch)
-     loss.backward()
+     accelerator.backward(loss)
      optimizer.step()
```

**執行** (單一指令):
```bash
accelerate launch train.py
```

## 常見工作流程

### 工作流程 1：從單 GPU 到多 GPU

**原始腳本**:
```python
# train.py
import torch

model = torch.nn.Linear(10, 2).to('cuda')
optimizer = torch.optim.Adam(model.parameters())
dataloader = torch.utils.data.DataLoader(dataset, batch_size=32)

for epoch in range(10):
    for batch in dataloader:
        batch = batch.to('cuda')
        optimizer.zero_grad()
        loss = model(batch).mean()
        loss.backward()
        optimizer.step()
```

**使用 Accelerate** (新增 4 行):
```python
# train.py
import torch
from accelerate import Accelerator  # +1

accelerator = Accelerator()  # +2

model = torch.nn.Linear(10, 2)
optimizer = torch.optim.Adam(model.parameters())
dataloader = torch.utils.data.DataLoader(dataset, batch_size=32)

model, optimizer, dataloader = accelerator.prepare(model, optimizer, dataloader)  # +3

for epoch in range(10):
    for batch in dataloader:
        # 不需要 .to('cuda') - 自動處理！
        optimizer.zero_grad()
        loss = model(batch).mean()
        accelerator.backward(loss)  # +4
        optimizer.step()
```

**配置** (互動式):
```bash
accelerate config
```

**問題**:
- 哪種機器？ (單部/多部 GPU/TPU/CPU)
- 幾部機器？ (1)
- 混合精度？ (no/fp16/bf16/fp8)
- DeepSpeed? (no/yes)

**啟動** (適用於任何設定):
```bash
# 單 GPU
accelerate launch train.py

# 多 GPU (8 個 GPU)
accelerate launch --multi_gpu --num_processes 8 train.py

# 多節點
accelerate launch --multi_gpu --num_processes 16 \
  --num_machines 2 --machine_rank 0 \
  --main_process_ip $MASTER_ADDR \
  train.py
```

### 工作流程 2：混合精度訓練

**啟用 FP16/BF16**:
```python
from accelerate import Accelerator

# FP16 (包含梯度縮放)
accelerator = Accelerator(mixed_precision='fp16')

# BF16 (無縮放，更穩定)
accelerator = Accelerator(mixed_precision='bf16')

# FP8 (H100+)
accelerator = Accelerator(mixed_precision='fp8')

model, optimizer, dataloader = accelerator.prepare(model, optimizer, dataloader)

# 其餘一切都是自動的！
for batch in dataloader:
    with accelerator.autocast():  # 選填，會自動執行
        loss = model(batch)
    accelerator.backward(loss)
```

### 工作流程 3：DeepSpeed ZeRO 整合

**啟用 DeepSpeed ZeRO-2**:
```python
from accelerate import Accelerator

accelerator = Accelerator(
    mixed_precision='bf16',
    deepspeed_plugin={
        "zero_stage": 2,  # ZeRO-2
        "offload_optimizer": False,
        "gradient_accumulation_steps": 4
    }
)

# 程式碼與之前相同！
model, optimizer, dataloader = accelerator.prepare(model, optimizer, dataloader)
```

**或透過配置**:
```bash
accelerate config
# 選擇: DeepSpeed → ZeRO-2
```

**deepspeed_config.json**:
```json
{
    "fp16": {"enabled": false},
    "bf16": {"enabled": true},
    "zero_optimization": {
        "stage": 2,
        "offload_optimizer": {"device": "cpu"},
        "allgather_bucket_size": 5e8,
        "reduce_bucket_size": 5e8
    }
}
```

**啟動**:
```bash
accelerate launch --config_file deepspeed_config.json train.py
```

### 工作流程 4：FSDP (Fully Sharded Data Parallel)

**啟用 FSDP**:
```python
from accelerate import Accelerator, FullyShardedDataParallelPlugin

fsdp_plugin = FullyShardedDataParallelPlugin(
    sharding_strategy="FULL_SHARD",  # ZeRO-3 等效
    auto_wrap_policy="TRANSFORMER_AUTO_WRAP",
    cpu_offload=False
)

accelerator = Accelerator(
    mixed_precision='bf16',
    fsdp_plugin=fsdp_plugin
)

model, optimizer, dataloader = accelerator.prepare(model, optimizer, dataloader)
```

**或透過配置**:
```bash
accelerate config
# 選擇: FSDP → Full Shard → No CPU Offload
```

### 工作流程 5：梯度累加 (Gradient accumulation)

**累加梯度**:
```python
from accelerate import Accelerator

accelerator = Accelerator(gradient_accumulation_steps=4)

model, optimizer, dataloader = accelerator.prepare(model, optimizer, dataloader)

for batch in dataloader:
    with accelerator.accumulate(model):  # 處理累加
        optimizer.zero_grad()
        loss = model(batch)
        accelerator.backward(loss)
        optimizer.step()
```

**有效批次大小**: `batch_size * num_gpus * gradient_accumulation_steps`

## 何時使用 vs 替代方案

**在以下情況使用 Accelerate**:
- 想要最簡單的分佈式訓練
- 任何硬體都只需要單一腳本
- 使用 HuggingFace 生態系統
- 想要靈活性 (DDP/DeepSpeed/FSDP/Megatron)
- 需要快速原型設計

**主要優勢**:
- **4 行程式碼**: 最小化程式碼更改
- **統一的 API**: DDP, DeepSpeed, FSDP, Megatron 共用同一套程式碼
- **自動化**: 自動處理裝置配置、混合精度、分片 (sharding)
- **互動式配置**: 無需手動設定啟動器
- **單一啟動方式**: 隨處皆可執行

**改用替代方案**:
- **PyTorch Lightning**: 需要回呼 (callbacks)、高階抽象
- **Ray Train**: 多節點編排、超參數調優
- **DeepSpeed**: 直接 API 控制、進階功能
- **Raw DDP**: 最大限度的控制、最小化抽象

## 常見問題

**問題：錯誤的裝置配置**

不要手動移動到裝置：
```python
# 錯誤
batch = batch.to('cuda')

# 正確
# Accelerate 在 prepare() 之後會自動處理
```

**問題：梯度累加未運作**

請使用上下文管理器 (context manager)：
```python
# 正確
with accelerator.accumulate(model):
    optimizer.zero_grad()
    accelerator.backward(loss)
    optimizer.step()
```

**問題：分佈式環境中的檢查點 (Checkpointing)**

使用 accelerator 方法：
```python
# 僅在主進程上儲存
if accelerator.is_main_process:
    accelerator.save_state('checkpoint/')

# 在所有進程上載入
accelerator.load_state('checkpoint/')
```

**問題：FSDP 結果不同**

確保隨機種子相同：
```python
from accelerate.utils import set_seed
set_seed(42)
```

## 進階主題

**Megatron 整合**: 參閱 [references/megatron-integration.md](references/megatron-integration.md) 以了解張量並行 (tensor parallelism)、管道並行 (pipeline parallelism) 和序列並行 (sequence parallelism) 的設定。

**自訂外掛程式**: 參閱 [references/custom-plugins.md](references/custom-plugins.md) 以了解如何建立自訂分佈式外掛程式與進階配置。

**效能調優**: 參閱 [references/performance.md](references/performance.md) 以了解分析 (profiling)、記憶體優化與最佳實踐。

## 硬體需求

- **CPU**: 支援 (速度慢)
- **單 GPU**: 支援
- **多 GPU**: DDP (預設), DeepSpeed, 或 FSDP
- **多節點**: DDP, DeepSpeed, FSDP, Megatron
- **TPU**: 支援
- **Apple MPS**: 支援

**啟動器需求**:
- **DDP**: `torch.distributed.run` (內建)
- **DeepSpeed**: `deepspeed` (pip install deepspeed)
- **FSDP**: PyTorch 1.12+ (內建)
- **Megatron**: 自訂設定

## 資源

- 文件: https://huggingface.co/docs/accelerate
- GitHub: https://github.com/huggingface/accelerate
- 版本: 1.11.0+
- 教學: "Accelerate your scripts"
- 範例: https://github.com/huggingface/accelerate/tree/main/examples
- 使用者: HuggingFace Transformers, TRL, PEFT, 所有 HF 庫
