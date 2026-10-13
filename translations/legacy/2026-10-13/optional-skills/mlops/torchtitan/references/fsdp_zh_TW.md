# TorchTitan 中的 FSDP2

## 為什麼選擇 FSDP2？

FSDP2 是對 PyTorch 完全分片資料平行 (Fully Sharded Data Parallel, FSDP) API 的重寫，移除了 `FlatParameter` 抽象化，以獲得更好的組合性與更簡單的實作方式。

### 相較於 FSDP1 的關鍵改進

- **基於 DTensor 的分片**：分片後的參數是維度 0 上的 `DTensor`，支援簡易的操作，並能實現無需通訊的分片狀態字典 (sharded state dicts)。
- **更好的記憶體管理**：透過避免使用 `recordStream`，實現了確定性且更低的 GPU 記憶體佔用 (減少 7%)。
- **簡化的 API**：參數更少，且不需要封裝類別 (wrapper class)。

### 效能

在 Llama-7B 與 8 個 H100 GPU 的測試中，FSDP2 達到了更高的 MFU，峰值記憶體比 FSDP1 低 7%，且損失曲線 (loss curve) 保持一致。

## API 參考

```python
from torch.distributed._composable.fsdp import fully_shard, MixedPrecisionPolicy, OffloadPolicy

@contract(state_cls=FSDPState)
def fully_shard(
    module: nn.Module,
    *,
    mesh: Optional[DeviceMesh] = None,
    reshard_after_forward: Union[bool, int] = True,
    mp_policy: MixedPrecisionPolicy = MixedPrecisionPolicy(),
    offload_policy: OffloadPolicy = OffloadPolicy(),
) -> nn.Module:
```

## 分片策略 (ZeRO 等效項)

| FSDP2 配置 | FSDP1 等效項 | DeepSpeed |
|---------------------|------------------|-----------|
| 1D mesh + `reshard_after_forward=True` | FULL_SHARD | ZeRO-3 |
| 1D mesh + `reshard_after_forward=False` | SHARD_GRAD_OP | ZeRO-2 |
| 2D mesh + `reshard_after_forward=True` | HYBRID_SHARD | MiCS |
| 1D/2D mesh + `reshard_after_forward=8` (int) | - | ZeRO++ hpZ |

## 中繼設備 (Meta-Device) 初始化

FSDP2 支援在分片「之後」將張量實例化到 GPU：

```python
# 在中繼設備上初始化 (無記憶體佔用)
with torch.device("meta"):
    model = Transformer()

# 套用 FSDP2 分片
for module in model.modules():
    if isinstance(module, TransformerBlock):
        fully_shard(module)
fully_shard(model)

# 參數仍位於中繼設備上
for tensor in itertools.chain(model.parameters(), model.buffers()):
    assert tensor.device == torch.device("meta")

# 在 GPU 上分配分片參數的空間
model.to_empty(device="cuda")

# 初始化權重
model.init_weights()
```

## 狀態字典 (State Dict) 差異

| 操作 | FSDP1 | FSDP2 |
|-----------|-------|-------|
| `model.state_dict()` | 完整狀態字典 | 分片狀態字典 (無需通訊) |
| `optim.state_dict()` | 本地狀態字典 | 分片狀態字典 (無需通訊) |
| `summon_full_params()` | 支援 | 使用 `DTensor` API (如 `full_tensor()`) |
| 梯度裁剪 (Gradient clipping) | `FSDP.clip_grad_norm_()` | `nn.utils.clip_grad_norm_()` |

## 混合精度 (Mixed Precision)

```python
from torch.distributed._composable.fsdp import MixedPrecisionPolicy

mp_policy = MixedPrecisionPolicy(
    param_dtype=torch.bfloat16,
    reduce_dtype=torch.float32,
    output_dtype=torch.bfloat16,
    cast_forward_inputs=True,
)

fully_shard(model, mp_policy=mp_policy)
```

## HSDP (混合分片資料平行 Hybrid Sharded Data Parallel)

用於結合複製 (replication) 與分片的 2D 平行：

```python
from torch.distributed.device_mesh import init_device_mesh

# 在 4 個組別中進行複製，每個組別內在 8 個 GPU 上進行分片
mesh = init_device_mesh("cuda", (4, 8), mesh_dim_names=("replicate", "shard"))

fully_shard(model, mesh=mesh)
```

## TorchTitan 中的配置

```toml
[parallelism]
# FSDP 分片程度 (-1 = 自動，使用所有可用 GPU)
data_parallel_shard_degree = -1

# HSDP 複製程度 (1 = 純 FSDP，>1 = HSDP)
data_parallel_replicate_degree = 1
```

## 從 FSDP1 移除的參數

下列 FSDP1 參數已不再需要：

- `auto_wrap_policy`：直接對模組套用 `fully_shard`。
- `backward_prefetch`：固定使用 BACKWARD_PRE。
- `param_init_fn`：使用中繼設備初始化。
- `device_id`：自動使用 mesh 的設備。
- `sync_module_states`：配合 DTensor 使用時不再需要。
- `limit_all_gathers`：新的記憶體管理機制不再需要此參數。
- `use_orig_params`：始終為 true (不再有 FlatParameter)。
