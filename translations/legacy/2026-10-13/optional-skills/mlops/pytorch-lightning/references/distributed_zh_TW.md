# PyTorch Lightning 分散式訓練 (Distributed Training)

## 分散式策略 (Distributed Strategies)

Lightning 僅需修改單一參數即可支援多種分散式策略。

### 1. DDP (DistributedDataParallel)

**多 GPU 的預設策略**：

```python
# 在所有可用的 GPU 上自動執行 DDP
trainer = L.Trainer(accelerator='gpu', devices=4, strategy='ddp')

# 或自動偵測
trainer = L.Trainer(accelerator='gpu', devices='auto')
```

**DDP 運作方式**：
- 在每個 GPU 上複製模型
- 每個 GPU 處理不同的批次 (Batch)
- 梯度 (Gradients) 在 GPU 之間進行全歸約 (All-reduce)
- 同步模型權重

**啟動方式**：
```bash
# Lightning 會自動處理處理序 (Process) 的衍生 (Spawning)
python train.py
```

**DDP 設定**：
```python
from lightning.pytorch.strategies import DDPStrategy

strategy = DDPStrategy(
    find_unused_parameters=False,  # 如果模型有未使用的參數，請設為 True
    gradient_as_bucket_view=True,  # 記憶體最佳化
    static_graph=False,  # 如果計算圖 (Graph) 不會改變，請設為 True
)

trainer = L.Trainer(strategy=strategy)
```

### 2. FSDP (Fully Sharded Data Parallel)

**適用於大型模型 (7B+ 參數)**：

```python
from lightning.pytorch.strategies import FSDPStrategy

strategy = FSDPStrategy(
    sharding_strategy="FULL_SHARD",  # 相當於 ZeRO-3
    activation_checkpointing=None,   # 或指定層類型
    cpu_offload=False,               # 是否將權重卸載 (Offload) 到 CPU 以節省記憶體
)

trainer = L.Trainer(
    accelerator='gpu',
    devices=8,
    strategy=strategy,
    precision='bf16'  # 推薦與 FSDP 一起使用
)

trainer.fit(model, train_loader)
```

**FSDP 分片策略 (Sharding Strategies)**：
```python
# FULL_SHARD (最節省記憶體，相當於 ZeRO-3)
strategy = FSDPStrategy(sharding_strategy="FULL_SHARD")

# SHARD_GRAD_OP (記憶體效率次之，相當於 ZeRO-2)
strategy = FSDPStrategy(sharding_strategy="SHARD_GRAD_OP")

# NO_SHARD (不進行分片，類似於 DDP)
strategy = FSDPStrategy(sharding_strategy="NO_SHARD")
```

**自動封裝策略 (Auto-wrap policy)** (封裝 Transformer 區塊)：
```python
from torch.distributed.fsdp.wrap import transformer_auto_wrap_policy
from transformers.models.gpt2.modeling_gpt2 import GPT2Block
import functools

auto_wrap_policy = functools.partial(
    transformer_auto_wrap_policy,
    transformer_layer_cls={GPT2Block}
)

strategy = FSDPStrategy(
    auto_wrap_policy=auto_wrap_policy,
    activation_checkpointing_policy={GPT2Block}  # 對這些區塊進行檢查點設置 (Checkpointing)
)
```

### 3. DeepSpeed

**適用於極大型模型 (70B+ 參數)**：

```python
from lightning.pytorch.strategies import DeepSpeedStrategy

# DeepSpeed ZeRO-3 並將權重卸載到 CPU
strategy = DeepSpeedStrategy(
    stage=3,                       # ZeRO-3
    offload_optimizer=True,        # 將最佳化器狀態卸載到 CPU
    offload_parameters=True,       # 將參數卸載到 CPU
    cpu_checkpointing=True,        # 在 CPU 上進行檢查點設置
)

trainer = L.Trainer(
    accelerator='gpu',
    devices=8,
    strategy=strategy,
    precision='bf16'
)

trainer.fit(model, train_loader)
```

**DeepSpeed 設定檔**：
```json
{
  "train_batch_size": "auto",
  "train_micro_batch_size_per_gpu": "auto",
  "gradient_accumulation_steps": "auto",
  "zero_optimization": {
    "stage": 3,
    "offload_optimizer": {
      "device": "cpu",
      "pin_memory": true
    },
    "offload_param": {
      "device": "cpu",
      "pin_memory": true
    },
    "overlap_comm": true,
    "contiguous_gradients": true,
    "reduce_bucket_size": 5e8,
    "stage3_prefetch_bucket_size": 5e8,
    "stage3_param_persistence_threshold": 1e6
  },
  "bf16": {
    "enabled": true
  }
}
```

**使用設定檔**：
```python
strategy = DeepSpeedStrategy(config='deepspeed_config.json')
trainer = L.Trainer(strategy=strategy)
```

### 4. DDP Spawn

**Windows 相容的 DDP**：

```python
# 當 DDP 無法運作時使用 (例如 Windows 或 Jupyter)
trainer = L.Trainer(
    accelerator='gpu',
    devices=2,
    strategy='ddp_spawn'  # 衍生新的處理序
)
```

**注意**：由於處理序衍生的開銷，速度比 DDP 慢。

## 多節點訓練 (Multi-Node Training)

### 設定多節點叢集 (Cluster)

**節點 0 (主節點 Master)**：
```bash
export MASTER_ADDR=192.168.1.100
export MASTER_PORT=12355
export WORLD_SIZE=16  # 2 個節點 × 8 個 GPU
export NODE_RANK=0

python train.py
```

**節點 1 (工作節點 Worker)**：
```bash
export MASTER_ADDR=192.168.1.100
export MASTER_PORT=12355
export WORLD_SIZE=16
export NODE_RANK=1

python train.py
```

**訓練指令碼**：
```python
trainer = L.Trainer(
    accelerator='gpu',
    devices=8,              # 每個節點的 GPU 數量
    num_nodes=2,            # 總節點數
    strategy='ddp'
)

trainer.fit(model, train_loader)
```

### SLURM 整合

**SLURM 作業腳本 (Job script)**：
```bash
#!/bin/bash
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=8
#SBATCH --gres=gpu:8
#SBATCH --time=24:00:00

# Lightning 會自動偵測 SLURM 環境
srun python train.py
```

**訓練指令碼** (無需更改)：
```python
# Lightning 會自動讀取 SLURM 環境變數
trainer = L.Trainer(
    accelerator='gpu',
    devices=8,
    num_nodes=4,  # 來自 SBATCH --nodes
    strategy='ddp'
)
```

### Kubernetes (KubeFlow)

**訓練指令碼**：
```python
import os

# Lightning 會自動偵測 Kubernetes
trainer = L.Trainer(
    accelerator='gpu',
    devices=int(os.getenv('WORLD_SIZE', 1)),
    strategy='ddp'
)
```

## 混合精度訓練 (Mixed Precision Training)

### BF16 (A100/H100)

```python
trainer = L.Trainer(
    precision='bf16',  # 或 'bf16-mixed'
    accelerator='gpu'
)
```

**優點**：
- 不需要梯度縮放器 (Gradient scaler)
- 動態範圍與 FP32 相同
- 速度提升 2 倍，記憶體佔用減少 50%

### FP16 (V100 或舊款 GPU)

```python
trainer = L.Trainer(
    precision='16-mixed',  # 或簡寫為 '16'
    accelerator='gpu'
)
```

**自動梯度縮放**由 Lightning 處理。

### FP8 (H100)

```python
# 需要安裝 transformer_engine
# pip install transformer-engine[pytorch]

trainer = L.Trainer(
    precision='transformer-engine',
    accelerator='gpu'
)
```

**優點**：在 H100 上比 BF16 快 2 倍。

## 梯度累積 (Gradient Accumulation)

**模擬更大的批次大小**：

```python
trainer = L.Trainer(
    accumulate_grad_batches=4,  # 累積 4 個批次
    precision='bf16'
)

# 有效批次 = 批次大小 × 梯度累積步數 × GPU 數量
# 例如：32 × 4 × 8 = 1024
```

**動態累積**：
```python
# 在訓練初期累積更多批次
trainer = L.Trainer(
    accumulate_grad_batches={
        0: 8,   # 第 0-4 輪 (Epochs)：累積 8 個
        5: 4,   # 第 5-9 輪：累積 4 個
        10: 2   # 第 10 輪之後：累積 2 個
    }
)
```

## 分散式環境中的檢查點 (Checkpointing)

### 儲存檢查點

```python
from lightning.pytorch.callbacks import ModelCheckpoint

# 預設僅由 Rank 0 (主程序) 進行儲存
checkpoint = ModelCheckpoint(
    dirpath='checkpoints/',
    filename='model-{epoch:02d}',
    save_top_k=3
)

trainer = L.Trainer(callbacks=[checkpoint], strategy='ddp')
trainer.fit(model, train_loader)
```

**手動儲存**：
```python
class MyModel(L.LightningModule):
    def training_step(self, batch, batch_idx):
        # 訓練中...
        loss = ...

        # 每 1000 步儲存一次 (僅限 Rank 0)
        if batch_idx % 1000 == 0 and self.trainer.is_global_zero:
            self.trainer.save_checkpoint(f'checkpoint_step_{batch_idx}.ckpt')

        return loss
```

### 載入檢查點

```python
# 恢復訓練
trainer = L.Trainer(strategy='ddp')
trainer.fit(model, train_loader, ckpt_path='checkpoints/last.ckpt')

# 載入用於推論 (Inference)
model = MyModel.load_from_checkpoint('checkpoints/best.ckpt')
model.eval()
```

## 策略比較

| 策略 | 記憶體效率 | 速度 | 使用場景 |
|----------|------------------|-------|----------|
| DDP | 低 | 快 | 小型模型 (<7B), 單節點 |
| FSDP | 高 | 中 | 大型模型 (7-70B) |
| DeepSpeed ZeRO-2 | 中 | 快 | 中型模型 (1-13B) |
| DeepSpeed ZeRO-3 | 極高 | 較慢 | 極大型模型 (70B+) |
| DDP Spawn | 低 | 慢 | Windows, 除錯 |

## 最佳實踐

### 1. 選擇正確的策略

```python
# 模型大小指引
if model_params < 1e9:  # <1B
    strategy = 'ddp'
elif model_params < 7e9:  # 1-7B
    strategy = 'ddp' 或 DeepSpeedStrategy(stage=2)
elif model_params < 70e9:  # 7-70B
    strategy = FSDPStrategy(sharding_strategy="FULL_SHARD")
else:  # 70B+
    strategy = DeepSpeedStrategy(stage=3, offload_optimizer=True)

trainer = L.Trainer(strategy=strategy)
```

### 2. 避免同步問題

```python
class MyModel(L.LightningModule):
    def training_step(self, batch, batch_idx):
        # 錯誤做法：這會在所有 GPU 上獨立執行
        if batch_idx % 100 == 0:
            self.log_something()  # 在 8 個 GPU 上會被記錄 8 次！

        # 正確做法：使用 is_global_zero
        if batch_idx % 100 == 0 and self.trainer.is_global_zero:
            self.log_something()  # 僅記錄一次

        loss = ...
        return loss
```

### 3. 高效的資料載入

```python
from torch.utils.data import DataLoader, DistributedSampler

# Lightning 會自動處理 DistributedSampler
train_loader = DataLoader(
    dataset,
    batch_size=32,
    num_workers=4,  # 每個 GPU 使用 4 個工作程序 (Workers)
    pin_memory=True,
    persistent_workers=True
)

# Lightning 會在 DDP 中自動使用 DistributedSampler 封裝資料
trainer.fit(model, train_loader)
```

### 4. 減少通訊開銷

```python
from lightning.pytorch.strategies import DDPStrategy

strategy = DDPStrategy(
    gradient_as_bucket_view=True,  # 減少記憶體複製
    static_graph=True,  # 如果模型架構不變 (速度較快)
)

trainer = L.Trainer(strategy=strategy)
```

## 常見問題

### 問題：NCCL 逾時 (Timeout)

**現象**：訓練卡住並顯示 `NCCL timeout` 錯誤。

**解決方案 1**：增加逾時時間
```bash
export NCCL_TIMEOUT=3600  # 1 小時
python train.py
```

**解決方案 2**：檢查網路
```bash
# 測試節點間的通訊
nvidia-smi nvlink -s

# 確認所有節點都可以互相 ping 通
ping <node-2-ip>
```

### 問題：使用 FSDP 時發生記憶體不足 (OOM)

**解決方案**：啟用 CPU 卸載 (Offload)
```python
strategy = FSDPStrategy(
    sharding_strategy="FULL_SHARD",
    cpu_offload=True  # 卸載到 CPU
)
```

### 問題：使用 DDP 時結果不一致

**原因**：每個 GPU 的隨機數種子 (Random seeds) 不同。

**解決方案**：在 LightningModule 中設置種子
```python
class MyModel(L.LightningModule):
    def __init__(self):
        super().__init__()
        L.seed_everything(42, workers=True)  # 在所有程序中設置相同種子
```

### 問題：DeepSpeed 設定錯誤

**解決方案**：使用 Lightning 的自動設定
```python
strategy = DeepSpeedStrategy(
    stage=3,
    # 不要指定設定檔，讓 Lightning 自動生成
)
```

## 資源連結

- 分散式策略：https://lightning.ai/docs/pytorch/stable/accelerators/gpu_intermediate.html
- FSDP 指南：https://lightning.ai/docs/pytorch/stable/advanced/model_parallel/fsdp.html
- DeepSpeed 指南：https://lightning.ai/docs/pytorch/stable/advanced/model_parallel/deepspeed.html
- 多節點訓練：https://lightning.ai/docs/pytorch/stable/clouds/cluster.html
