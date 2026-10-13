# Accelerate 自定義插件 (Custom Plugins)

## 概述

Accelerate 允許建立 **自定義插件**，以將分散式訓練策略擴展到內建選項（DDP、FSDP、DeepSpeed）之外。

## 插件架構

### 基礎插件結構

```python
from accelerate.utils import DistributedDataParallelKwargs
from dataclasses import dataclass

@dataclass
class CustomPlugin:
    """自定義訓練插件。"""

    # 插件配置
    param1: int = 1
    param2: str = "default"

    def __post_init__(self):
        # 驗證邏輯
        if self.param1 < 1:
            raise ValueError("param1 必須 >= 1")
```

### 使用自定義插件

```python
from accelerate import Accelerator

# 建立插件
custom_plugin = CustomPlugin(param1=4, param2="value")

# 傳遞給 Accelerator
accelerator = Accelerator(
    custom_plugin=custom_plugin  # 僅為範例，非真實參數
)
```

## 內建插件範例

### 1. GradScalerKwargs (FP16 配置)

```python
from accelerate.utils import GradScalerKwargs

# 為 FP16 配置梯度縮放器 (gradient scaler)
scaler_kwargs = GradScalerKwargs(
    init_scale=2.**16,        # 初始損失縮放 (loss scale)
    growth_factor=2.0,        # 縮放增長率
    backoff_factor=0.5,       # 縮放回退率 (backoff rate)
    growth_interval=2000,     # 兩次縮放增加之間的步數
    enabled=True              # 啟用縮放器
)

accelerator = Accelerator(
    mixed_precision='fp16',
    kwargs_handlers=[scaler_kwargs]  # 作為 kwargs 處理器傳遞
)
```

**使用情境**：微調 FP16 梯度縮放行為。

### 2. DistributedDataParallelKwargs

```python
from accelerate.utils import DistributedDataParallelKwargs

# 配置 DDP 行為
ddp_kwargs = DistributedDataParallelKwargs(
    bucket_cap_mb=25,                 # 梯度分桶大小
    find_unused_parameters=False,     # 尋找未使用的參數 (較慢)
    check_reduction=False,            # 檢查梯度歸約 (reduction)
    gradient_as_bucket_view=True,     # 記憶體優化
    static_graph=False                # 靜態計算圖
)

accelerator = Accelerator(
    kwargs_handlers=[ddp_kwargs]
)
```

**使用情境**：針對特定模型優化 DDP 效能。

### 3. FP8RecipeKwargs (H100 FP8)

```python
from accelerate.utils import FP8RecipeKwargs

# 配置 FP8 訓練 (H100)
fp8_recipe = FP8RecipeKwargs(
    backend="te",              # TransformerEngine 後端
    margin=0,                  # 縮放邊距 (margin)
    interval=1,                # 縮放間隔
    fp8_format="HYBRID",       # E4M3 + E5M2 混合格式
    amax_history_len=1024,     # AMAX 歷史長度
    amax_compute_algo="max"    # AMAX 計算演算法
)

accelerator = Accelerator(
    mixed_precision='fp8',
    kwargs_handlers=[fp8_recipe]
)
```

**使用情境**：在 H100 GPU 上進行極速訓練。

## 自定義 DeepSpeed 配置

### 具有 CPU 卸載 (Offload) 的 ZeRO-3

```python
from accelerate import Accelerator
from accelerate.utils import DeepSpeedPlugin

# 自定義 DeepSpeed 配置
ds_plugin = DeepSpeedPlugin(
    zero_stage=3,                     # ZeRO-3
    offload_optimizer_device="cpu",   # 將優化器卸載至 CPU
    offload_param_device="cpu",       # 將參數卸載至 CPU
    zero3_init_flag=True,             # ZeRO-3 初始化
    zero3_save_16bit_model=True,      # 儲存 FP16 權重
)

accelerator = Accelerator(
    deepspeed_plugin=ds_plugin,
    mixed_precision='bf16'
)
```

### 具有 NVMe 卸載的 ZeRO-2

```python
ds_plugin = DeepSpeedPlugin(
    zero_stage=2,
    offload_optimizer_device="nvme",  # 卸載至 NVMe
    offload_param_device="nvme",
    nvme_path="/local_nvme",          # NVMe 掛載路徑
)
```

### 自定義 JSON 配置

```python
import json

# 載入自定義 DeepSpeed 配置
with open('deepspeed_config.json', 'r') as f:
    ds_config = json.load(f)

ds_plugin = DeepSpeedPlugin(hf_ds_config=ds_config)

accelerator = Accelerator(deepspeed_plugin=ds_plugin)
```

**配置範例** (`deepspeed_config.json`):
```json
{
  "train_batch_size": "auto",
  "train_micro_batch_size_per_gpu": "auto",
  "gradient_accumulation_steps": "auto",
  "gradient_clipping": 1.0,
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
    "sub_group_size": 1e9,
    "reduce_bucket_size": 5e8,
    "stage3_prefetch_bucket_size": 5e8,
    "stage3_param_persistence_threshold": 1e6,
    "stage3_max_live_parameters": 1e9,
    "stage3_max_reuse_distance": 1e9,
    "stage3_gather_16bit_weights_on_model_save": true
  },
  "bf16": {
    "enabled": true
  },
  "steps_per_print": 100,
  "wall_clock_breakdown": false
}
```

## 自定義 FSDP 配置

### 具有自定義自動封裝策略 (Auto-Wrap Policy) 的 FSDP

```python
from accelerate.utils import FullyShardedDataParallelPlugin
from torch.distributed.fsdp import BackwardPrefetch, ShardingStrategy
from torch.distributed.fsdp.wrap import size_based_auto_wrap_policy
import functools

# 自定義封裝策略 (基於大小)
wrap_policy = functools.partial(
    size_based_auto_wrap_policy,
    min_num_params=1e6  # 封裝具有 1M+ 參數的層
)

fsdp_plugin = FullyShardedDataParallelPlugin(
    sharding_strategy=ShardingStrategy.FULL_SHARD,  # 相當於 ZeRO-3
    backward_prefetch=BackwardPrefetch.BACKWARD_PRE,  # 預取策略
    mixed_precision_policy=None,  # 使用 Accelerator 的混合精度
    auto_wrap_policy=wrap_policy,  # 自定義封裝
    cpu_offload=False,
    ignored_modules=None,  # 不進行封裝的模組
    state_dict_type="FULL_STATE_DICT",  # 儲存格式
    optim_state_dict_config=None,
    limit_all_gathers=False,
    use_orig_params=True,  # 使用原始參數形狀
)

accelerator = Accelerator(
    fsdp_plugin=fsdp_plugin,
    mixed_precision='bf16'
)
```

### 具有 Transformer 自動封裝的 FSDP

```python
from torch.distributed.fsdp.wrap import transformer_auto_wrap_policy
from transformers.models.gpt2.modeling_gpt2 import GPT2Block

# 在 Transformer 區塊層級進行封裝
wrap_policy = functools.partial(
    transformer_auto_wrap_policy,
    transformer_layer_cls={GPT2Block}  # 封裝 GPT2Block 層
)

fsdp_plugin = FullyShardedDataParallelPlugin(
    auto_wrap_policy=wrap_policy
)
```

## 建立自定義訓練策略

### 範例：自定義梯度累積 (Gradient Accumulation)

```python
from accelerate import Accelerator

class CustomGradientAccumulation:
    def __init__(self, steps=4, adaptive=False):
        self.steps = steps
        self.adaptive = adaptive
        self.current_step = 0

    def should_sync(self, loss):
        """決定是否同步梯度。"""
        self.current_step += 1

        # 自適應：在高損失時同步
        if self.adaptive and loss > threshold:
            self.current_step = 0
            return True

        # 常規：每 N 步同步一次
        if self.current_step >= self.steps:
            self.current_step = 0
            return True

        return False

# 用法
custom_accum = CustomGradientAccumulation(steps=8, adaptive=True)
accelerator = Accelerator()

for batch in dataloader:
    outputs = model(**batch)
    loss = outputs.loss

    # 縮放損失
    loss = loss / custom_accum.steps
    accelerator.backward(loss)

    # 條件同步
    if custom_accum.should_sync(loss.item()):
        optimizer.step()
        optimizer.zero_grad()
```

### 範例：自定義混合精度

```python
import torch

class CustomMixedPrecision:
    """具動態損失縮放的自定義混合精度。"""

    def __init__(self, init_scale=2**16, scale_window=2000):
        self.scaler = torch.cuda.amp.GradScaler(
            init_scale=init_scale,
            growth_interval=scale_window
        )
        self.scale_history = []

    def scale_loss(self, loss):
        """為反向傳播縮放損失。"""
        return self.scaler.scale(loss)

    def unscale_and_clip(self, optimizer, max_norm=1.0):
        """取消梯度縮放並進行裁剪。"""
        self.scaler.unscale_(optimizer)
        torch.nn.utils.clip_grad_norm_(
            optimizer.param_groups[0]['params'],
            max_norm
        )

    def step(self, optimizer):
        """具縮放器更新的優化器步驟。"""
        scale_before = self.scaler.get_scale()
        self.scaler.step(optimizer)
        self.scaler.update()
        scale_after = self.scaler.get_scale()

        # 追蹤縮放變更
        if scale_before != scale_after:
            self.scale_history.append(scale_after)

# 用法
custom_mp = CustomMixedPrecision()

for batch in dataloader:
    with torch.cuda.amp.autocast(dtype=torch.float16):
        loss = model(**batch).loss

    scaled_loss = custom_mp.scale_loss(loss)
    scaled_loss.backward()

    custom_mp.unscale_and_clip(optimizer, max_norm=1.0)
    custom_mp.step(optimizer)
    optimizer.zero_grad()
```

## 進階：自定義分散式後端

### 自定義 AllReduce 策略

```python
import torch.distributed as dist

class CustomAllReduce:
    """具壓縮功能的自定義 All-Reduce。"""

    def __init__(self, compression_ratio=0.1):
        self.compression_ratio = compression_ratio

    def compress_gradients(self, tensor):
        """Top-k 梯度壓縮。"""
        k = int(tensor.numel() * self.compression_ratio)
        values, indices = torch.topk(tensor.abs().view(-1), k)
        return values, indices

    def all_reduce_compressed(self, tensor):
        """具梯度壓縮的 All-Reduce。"""
        # 壓縮
        values, indices = self.compress_gradients(tensor)

        # All-reduce 壓縮後的梯度
        dist.all_reduce(values, op=dist.ReduceOp.SUM)

        # 解壓縮
        tensor_compressed = torch.zeros_like(tensor).view(-1)
        tensor_compressed[indices] = values / dist.get_world_size()

        return tensor_compressed.view_as(tensor)

# 在訓練迴圈中的用法
custom_ar = CustomAllReduce(compression_ratio=0.1)

for batch in dataloader:
    loss = model(**batch).loss
    loss.backward()

    # 自定義 all-reduce
    for param in model.parameters():
        if param.grad is not None:
            param.grad.data = custom_ar.all_reduce_compressed(param.grad.data)

    optimizer.step()
    optimizer.zero_grad()
```

## 插件最佳實踐

### 1. 在 `__post_init__` 中進行驗證

```python
@dataclass
class CustomPlugin:
    learning_rate: float = 1e-3
    warmup_steps: int = 1000

    def __post_init__(self):
        # 驗證參數
        if self.learning_rate <= 0:
            raise ValueError("learning_rate 必須為正數")
        if self.warmup_steps < 0:
            raise ValueError("warmup_steps 必須為非負數")

        # 計算衍生值
        self.min_lr = self.learning_rate * 0.1
```

### 2. 相容性檢查

```python
@dataclass
class CustomPlugin:
    feature_enabled: bool = True

    def is_compatible(self, accelerator):
        """檢查插件是否與 accelerator 配置相容。"""
        if self.feature_enabled and accelerator.mixed_precision == 'fp8':
            raise ValueError("自定義插件與 FP8 不相容")
        return True
```

### 3. 狀態管理

```python
@dataclass
class CustomPlugin:
    counter: int = 0
    history: list = None

    def __post_init__(self):
        if self.history is None:
            self.history = []

    def update_state(self, value):
        """在訓練期間更新插件狀態。"""
        self.counter += 1
        self.history.append(value)
```

## 資源

- Accelerate 插件：https://huggingface.co/docs/accelerate/package_reference/kwargs
- DeepSpeed 配置：https://www.deepspeed.ai/docs/config-json/
- FSDP 指南：https://pytorch.org/docs/stable/fsdp.html
- 自定義訓練迴圈：https://huggingface.co/docs/accelerate/usage_guides/training_tpu
