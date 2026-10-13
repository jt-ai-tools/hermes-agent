# Accelerate 效能調優

## 效能分析 (Profiling)

### 基礎分析

```python
from accelerate import Accelerator
import time

accelerator = Accelerator()

# 熱身 (Warmup)
for _ in range(10):
    batch = next(iter(dataloader))
    outputs = model(**batch)
    loss = outputs.loss
    accelerator.backward(loss)
    optimizer.step()
    optimizer.zero_grad()

# 分析訓練迴圈
start = time.time()
total_batches = 100

for i, batch in enumerate(dataloader):
    if i >= total_batches:
        break

    outputs = model(**batch)
    loss = outputs.loss
    accelerator.backward(loss)
    optimizer.step()
    optimizer.zero_grad()

accelerator.wait_for_everyone()  # 同步所有程序
elapsed = time.time() - start

# 指標
batches_per_sec = total_batches / elapsed
samples_per_sec = (total_batches * batch_size * accelerator.num_processes) / elapsed

print(f"吞吐量 (Throughput): {samples_per_sec:.2f} samples/sec")
print(f"每秒批次數 (Batches/sec): {batches_per_sec:.2f}")
```

### PyTorch Profiler 整合

```python
from torch.profiler import profile, ProfilerActivity

with profile(
    activities=[ProfilerActivity.CPU, ProfilerActivity.CUDA],
    record_shapes=True,
    profile_memory=True,
    with_stack=True
) as prof:
    for i, batch in enumerate(dataloader):
        if i >= 10:  # 分析前 10 個批次
            break

        outputs = model(**batch)
        loss = outputs.loss
        accelerator.backward(loss)
        optimizer.step()
        optimizer.zero_grad()

# 列印分析結果
print(prof.key_averages().table(
    sort_by="cuda_time_total", row_limit=20
))

# 匯出至 Chrome tracing
prof.export_chrome_trace("trace.json")
# 在 chrome://tracing 查看
```

## 記憶體優化

### 1. 梯度累積 (Gradient Accumulation)

**問題**：批次大小過大導致 OOM (記憶體不足)

**解決方法**：在多個微批次 (micro-batches) 中累積梯度

```python
accelerator = Accelerator(gradient_accumulation_steps=8)

# 有效批次 = 批次大小 × 累積步數 × GPU 數量
# 範例：4 × 8 × 8 = 256

for batch in dataloader:
    with accelerator.accumulate(model):  # 處理累積邏輯
        outputs = model(**batch)
        loss = outputs.loss
        accelerator.backward(loss)
        optimizer.step()
        optimizer.zero_grad()
```

**記憶體節省**：活化值 (activation) 記憶體減少 8 倍 (使用 8 個累積步數時)

### 2. 梯度檢查點 (Gradient Checkpointing)

**在模型中啟用**：

```python
from transformers import AutoModelForCausalLM

model = AutoModelForCausalLM.from_pretrained(
    "gpt2",
    use_cache=False  # 使用梯度檢查點時必須設為 False
)

# 啟用檢查點
model.gradient_checkpointing_enable()

# 使用 Accelerate 準備
model = accelerator.prepare(model)
```

**記憶體節省**：30-50%，伴隨 10-15% 的速度降低

### 3. 混合精度 (Mixed Precision)

**BF16 (A100/H100)**：
```python
accelerator = Accelerator(mixed_precision='bf16')

# 自動混合精度
for batch in dataloader:
    outputs = model(**batch)  # 前向傳播使用 BF16
    loss = outputs.loss
    accelerator.backward(loss)  # 反向傳播使用 FP32
    optimizer.step()
```

**FP16 (V100, 舊款 GPU)**：
```python
from accelerate.utils import GradScalerKwargs

scaler_kwargs = GradScalerKwargs(
    init_scale=2.**16,
    growth_interval=2000
)

accelerator = Accelerator(
    mixed_precision='fp16',
    kwargs_handlers=[scaler_kwargs]
)
```

**記憶體節省**：相較於 FP32 節省 50%

### 4. CPU 卸載 (Offloading) (DeepSpeed)

```python
from accelerate.utils import DeepSpeedPlugin

ds_plugin = DeepSpeedPlugin(
    zero_stage=3,
    offload_optimizer_device="cpu",  # 將優化器卸載至 CPU
    offload_param_device="cpu",      # 將參數卸載至 CPU
)

accelerator = Accelerator(
    deepspeed_plugin=ds_plugin,
    mixed_precision='bf16'
)
```

**記憶體節省**：優化器狀態節省 10-20 倍，參數節省 5-10 倍

**權衡**：由於 CPU-GPU 傳輸，速度慢 20-30%

### 5. Flash Attention

```python
# 安裝 flash-attn
# pip install flash-attn

from transformers import AutoModelForCausalLM

model = AutoModelForCausalLM.from_pretrained(
    "gpt2",
    attn_implementation="flash_attention_2"  # 啟用 Flash Attention 2
)

model = accelerator.prepare(model)
```

**記憶體節省**：注意力機制節省 50%，速度快 2 倍

**需求**：A100/H100，序列長度必須是 128 的倍數

## 通訊優化

### 1. 梯度分桶 (Gradient Bucketing) (DDP)

```python
from accelerate.utils import DistributedDataParallelKwargs

ddp_kwargs = DistributedDataParallelKwargs(
    bucket_cap_mb=25,  # 梯度歸約 (reduction) 的桶大小
    gradient_as_bucket_view=True,  # 減少記憶體複製
    static_graph=False  # 如果模型不會改變則設為 True
)

accelerator = Accelerator(kwargs_handlers=[ddp_kwargs])
```

**建議的桶大小**：
- 小型模型 (<1B): 25 MB
- 中型模型 (1-10B): 50-100 MB
- 大型模型 (>10B): 100-200 MB

### 2. 尋找未使用的參數 (Find Unused Parameters)

```python
# 僅在模型有未使用參數時啟用 (速度較慢！)
ddp_kwargs = DistributedDataParallelKwargs(
    find_unused_parameters=True
)
```

**使用情境**：具有條件分支的模型 (例如：專家混合模型 Mixture of Experts)

**代價**：速度慢 10-20%

### 3. NCCL 微調

```bash
# 在啟動前設定環境變數
export NCCL_DEBUG=INFO           # 除錯資訊
export NCCL_IB_DISABLE=0         # 啟用 InfiniBand
export NCCL_SOCKET_IFNAME=eth0   # 網路介面
export NCCL_P2P_LEVEL=NVL        # 使用 NVLink

accelerate launch train.py
```

**NCCL_P2P_LEVEL 選項**：
- `NVL`: NVLink (最快，節點內)
- `PIX`: PCIe (快，節點內)
- `PHB`: PCIe 主機橋接 (慢，跨節點)

## 資料載入優化

### 1. DataLoader 工作程序 (Workers)

```python
from torch.utils.data import DataLoader

train_loader = DataLoader(
    dataset,
    batch_size=32,
    num_workers=4,      # 平行資料載入
    pin_memory=True,    # 鎖定記憶體以加快 GPU 傳輸
    prefetch_factor=2,  # 每個工作程序預取批次數
    persistent_workers=True  # 在 epoch 之間保持工作程序存活
)

train_loader = accelerator.prepare(train_loader)
```

**建議**：
- `num_workers`: 每個 GPU 2-4 個 (8 GPU → 16-32 個工作程序)
- `pin_memory`: GPU 訓練時務必設為 True
- `prefetch_factor`: 2-4 (資料載入慢時可設更高)

### 2. 資料預處理

```python
from datasets import load_dataset

# 不良做法：在訓練期間進行預處理 (慢)
dataset = load_dataset("openwebtext")

for batch in dataset:
    tokens = tokenizer(batch['text'])  # 慢！
    ...

# 良好做法：預處理一次並儲存
dataset = load_dataset("openwebtext")
tokenized = dataset.map(
    lambda x: tokenizer(x['text']),
    batched=True,
    num_proc=8,  # 平行預處理
    remove_columns=['text']
)
tokenized.save_to_disk("preprocessed_data")

# 載入預處理後的資料
dataset = load_from_disk("preprocessed_data")
```

### 3. 更快的分詞速度

```python
import os

# 啟用基於 Rust 的分詞器 (快 10 倍)
os.environ["TOKENIZERS_PARALLELISM"] = "true"

from transformers import AutoTokenizer

tokenizer = AutoTokenizer.from_pretrained(
    "gpt2",
    use_fast=True  # 使用快速 Rust 分詞器
)
```

## 編譯 (PyTorch 2.0+)

### 編譯模型

```python
import torch

# 編譯模型以加快執行速度
model = torch.compile(
    model,
    mode="reduce-overhead",  # 選項：default, reduce-overhead, max-autotune
    fullgraph=False,         # 編譯整個圖 (較嚴格)
    dynamic=True             # 支援動態形狀 (dynamic shapes)
)

model = accelerator.prepare(model)
```

**加速**：10-50%，取決於模型

**編譯模式**：
- `default`: 平衡 (適用於大多數情況)
- `reduce-overhead`: 最小開銷 (適用於小批次)
- `max-autotune`: 最大效能 (編譯慢，適用於生產環境)

### 編譯最佳實踐

```python
# 不良做法：在 prepare 之後編譯 (無效)
model = accelerator.prepare(model)
model = torch.compile(model)  # 錯誤！

# 良好做法：在 prepare 之前編譯
model = torch.compile(model)
model = accelerator.prepare(model)

# 訓練迴圈
for batch in dataloader:
    # 第一個迭代：慢 (進行編譯)
    # 後續迭代：快 (已編譯)
    outputs = model(**batch)
    ...
```

## 基準測試 (Benchmarking) 不同策略

### 腳本範本

```python
import time
import torch
from accelerate import Accelerator

def benchmark_strategy(strategy_name, accelerator_kwargs):
    """測試特定訓練策略。"""
    accelerator = Accelerator(**accelerator_kwargs)

    # 設定
    model = create_model()
    optimizer = torch.optim.AdamW(model.parameters(), lr=1e-4)
    dataloader = create_dataloader()

    model, optimizer, dataloader = accelerator.prepare(
        model, optimizer, dataloader
    )

    # 熱身
    for i, batch in enumerate(dataloader):
        if i >= 10:
            break
        outputs = model(**batch)
        loss = outputs.loss
        accelerator.backward(loss)
        optimizer.step()
        optimizer.zero_grad()

    # 基準測試
    accelerator.wait_for_everyone()
    torch.cuda.synchronize()
    start = time.time()

    num_batches = 100
    for i, batch in enumerate(dataloader):
        if i >= num_batches:
            break

        outputs = model(**batch)
        loss = outputs.loss
        accelerator.backward(loss)
        optimizer.step()
        optimizer.zero_grad()

    accelerator.wait_for_everyone()
    torch.cuda.synchronize()
    elapsed = time.time() - start

    # 指標
    throughput = (num_batches * batch_size * accelerator.num_processes) / elapsed
    memory_used = torch.cuda.max_memory_allocated() / 1e9  # GB

    if accelerator.is_main_process:
        print(f"\n{strategy_name}:")
        print(f"  吞吐量: {throughput:.2f} samples/sec")
        print(f"  記憶體: {memory_used:.2f} GB")
        print(f"  時間: {elapsed:.2f} sec")

    torch.cuda.reset_peak_memory_stats()

# 測試不同策略
strategies = [
    ("DDP + FP32", {}),
    ("DDP + BF16", {"mixed_precision": "bf16"}),
    ("DDP + BF16 + GradAccum", {"mixed_precision": "bf16", "gradient_accumulation_steps": 4}),
    ("FSDP", {"fsdp_plugin": fsdp_plugin}),
    ("DeepSpeed ZeRO-2", {"deepspeed_plugin": ds_plugin_stage2}),
    ("DeepSpeed ZeRO-3", {"deepspeed_plugin": ds_plugin_stage3}),
]

for name, kwargs in strategies:
    benchmark_strategy(name, kwargs)
```

## 效能檢查清單

**訓練前**：
- [ ] 使用 BF16/FP16 混合精度
- [ ] 啟用梯度檢查點 (如果發生 OOM)
- [ ] 設定合適的 `num_workers` (每個 GPU 2-4 個)
- [ ] 啟用 `pin_memory=True`
- [ ] 預處理資料一次，而非在訓練期間進行
- [ ] 使用 `torch.compile` 編譯模型 (PyTorch 2.0+)

**針對大型模型**：
- [ ] 使用 FSDP 或 DeepSpeed ZeRO-3
- [ ] 啟用 CPU 卸載 (如果仍發生 OOM)
- [ ] 使用 Flash Attention
- [ ] 增加梯度累積步數

**針對多節點**：
- [ ] 檢查網路拓撲 (InfiniBand > Ethernet)
- [ ] 微調 NCCL 設定
- [ ] 對 DDP 使用更大的桶大小
- [ ] 驗證張量平行 (Tensor Parallelism) 是否使用 NVLink

**效能分析**：
- [ ] 分析前 10-100 個批次
- [ ] 檢查 GPU 使用率 (`nvidia-smi dmon`)
- [ ] 檢查資料載入時間 (應少於單次迭代時間的 5%)
- [ ] 識別通訊瓶頸

## 常見效能問題

### 問題：GPU 使用率低 (<80%)

**原因 1**：資料載入瓶頸
```python
# 解決方法：增加工作程序和預取數量
num_workers=8
prefetch_factor=4
```

**原因 2**：批次大小太小
```python
# 解決方法：增加批次大小或使用梯度累積
batch_size=32  # 增加
gradient_accumulation_steps=4  # 或累積
```

### 問題：記憶體使用率高

**解決方法 1**：梯度檢查點
```python
model.gradient_checkpointing_enable()
```

**解決方法 2**：減小批次大小，增加累積步數
```python
batch_size=8  # 從 32 減小
gradient_accumulation_steps=16  # 保持有效批次大小
```

**解決方法 3**：使用 FSDP 或 DeepSpeed ZeRO-3
```python
accelerator = Accelerator(fsdp_plugin=fsdp_plugin)
```

### 問題：多 GPU 訓練緩慢

**原因**：通訊瓶頸

**檢查 1**：梯度桶大小
```python
ddp_kwargs = DistributedDataParallelKwargs(bucket_cap_mb=100)
```

**檢查 2**：NCCL 設定
```bash
export NCCL_DEBUG=INFO
# 檢查是否有 "Using NVLS" (良好) 或 "Using PHB" (不良)
```

**檢查 3**：網路頻寬
```bash
# 測試 GPU 間頻寬
nvidia-smi nvlink -s
```

## 資源

- Accelerate 效能：https://huggingface.co/docs/accelerate/usage_guides/performance
- PyTorch Profiler：https://pytorch.org/tutorials/recipes/recipes/profiler_recipe.html
- NCCL 微調：https://docs.nvidia.com/deeplearning/nccl/user-guide/docs/env.html
- Flash Attention：https://github.com/Dao-AILab/flash-attention
