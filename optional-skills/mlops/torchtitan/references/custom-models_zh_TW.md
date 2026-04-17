# 在 TorchTitan 中新增自定義模型

本指南說明如何按照既定模式在 TorchTitan 中新增模型。

## 目錄結構

```
torchtitan/models/your_model/
├── model/
│   ├── __init__.py
│   ├── args.py          # 模型參數
│   ├── model.py         # 模型定義
│   └── state_dict_adapter.py  # HF 轉換 (選用)
├── infra/
│   ├── __init__.py
│   ├── parallelize.py   # 套用 TP、FSDP、編譯
│   └── pipeline.py      # 套用 PP (選用)
├── train_configs/
│   ├── debug_model.toml
│   └── your_model_XB.toml
├── __init__.py          # TrainSpec 註冊
└── README.md
```

## 步驟 1：定義模型參數

繼承自 `BaseModelArgs`：

```python
# model/args.py
from torchtitan.protocols.model import BaseModelArgs
from dataclasses import dataclass

@dataclass
class YourModelArgs(BaseModelArgs):
    dim: int = 4096
    n_layers: int = 32
    n_heads: int = 32
    vocab_size: int = 128256

    def get_nparams_and_flops(self, seq_len: int) -> tuple[int, int]:
        """回傳 (參數數量, 每個標記的 FLOPs) 以進行吞吐量計算。"""
        nparams = self.vocab_size * self.dim + ...  # 計算參數
        flops = 6 * nparams  # 近似值：前向 + 反向傳播約為 6 * 參數數量
        return nparams, flops

    def update_from_config(self, job_config) -> "YourModelArgs":
        """從訓練配置更新參數。"""
        # 必要時從 job_config 覆寫特定參數
        return self
```

## 步驟 2：定義模型

繼承自 `ModelProtocol`：

```python
# model/model.py
import torch.nn as nn
from torchtitan.protocols.model import ModelProtocol
from .args import YourModelArgs

class YourModel(ModelProtocol):
    def __init__(self, args: YourModelArgs):
        super().__init__()
        self.args = args
        self.tok_embeddings = nn.Embedding(args.vocab_size, args.dim)
        self.layers = nn.ModuleDict({
            str(i): TransformerBlock(args) for i in range(args.n_layers)
        })
        self.norm = RMSNorm(args.dim)
        self.output = nn.Linear(args.dim, args.vocab_size, bias=False)

    def forward(self, tokens: torch.Tensor) -> torch.Tensor:
        h = self.tok_embeddings(tokens)
        for layer in self.layers.values():
            h = layer(h)
        h = self.norm(h)
        return self.output(h)

    def init_weights(self):
        """遞迴初始化權重。"""
        for module in self.modules():
            if hasattr(module, 'init_weights') and module is not self:
                module.init_weights()
            elif isinstance(module, nn.Linear):
                nn.init.normal_(module.weight, std=0.02)
```

**重要指南**：
- 編寫單一設備的模型程式碼 (平行處理在外部套用)。
- 對各層使用 `nn.ModuleDict` (在 PP 刪除層時可保留 FQN)。
- 讓輸入/輸出層成為選用項目，以確保 PP 相容性。
- 遞迴定義 `init_weights()`。

## 步驟 3：平行化函式

```python
# infra/parallelize.py
from torch.distributed._composable.fsdp import fully_shard
from torch.distributed.tensor.parallel import parallelize_module

def parallelize_your_model(
    model: YourModel,
    world_mesh: DeviceMesh,
    parallel_dims: ParallelDims,
    job_config: JobConfig,
):
    # 依此順序套用：TP -> AC -> 編譯 -> FSDP

    # 1. 張量平行 (Tensor Parallelism)
    if parallel_dims.tp_enabled:
        apply_tp(model, world_mesh["tp"], job_config)

    # 2. 活化值檢查點 (Activation Checkpointing)
    if job_config.activation_checkpoint.mode == "full":
        apply_ac(model, job_config)

    # 3. torch.compile (編譯)
    if job_config.compile.enable:
        model = torch.compile(model)

    # 4. FSDP
    if parallel_dims.dp_enabled:
        apply_fsdp(model, world_mesh["dp"], job_config)

    return model
```

## 步驟 4：建立 TrainSpec

```python
# __init__.py
from torchtitan.protocols.train_spec import TrainSpec, register_train_spec
from .model.model import YourModel
from .model.args import YourModelArgs
from .infra.parallelize import parallelize_your_model

MODEL_CONFIGS = {
    "8B": YourModelArgs(dim=4096, n_layers=32, n_heads=32),
    "70B": YourModelArgs(dim=8192, n_layers=80, n_heads=64),
}

def get_train_spec(flavor: str) -> TrainSpec:
    return TrainSpec(
        model_cls=YourModel,
        model_args=MODEL_CONFIGS[flavor],
        parallelize_fn=parallelize_your_model,
        pipeline_fn=None,  # 或者是針對 PP 的 your_pipeline_fn
        build_optimizer_fn=build_optimizer,  # 重用現有函式
        build_lr_scheduler_fn=build_lr_scheduler,  # 重用現有函式
        build_dataloader_fn=build_dataloader,  # 重用現有函式
        build_tokenizer_fn=build_tokenizer,  # 重用現有函式
        build_loss_fn=build_loss,  # 重用現有函式
        state_dict_adapter=None,  # 或者是 YourStateDictAdapter
    )

# 註冊以便 train.py 尋找
register_train_spec("your_model", get_train_spec)
```

## 步驟 5：狀態字典配接器 (State Dict Adapter) (選用)

用於 HuggingFace 檢查點轉換：

```python
# model/state_dict_adapter.py
from torchtitan.protocols.state_dict_adapter import BaseStateDictAdapter

class YourStateDictAdapter(BaseStateDictAdapter):
    def to_hf(self, state_dict: dict) -> dict:
        """將 TorchTitan 狀態字典轉換為 HF 格式。"""
        hf_state_dict = {}
        for key, value in state_dict.items():
            hf_key = self._convert_key_to_hf(key)
            hf_state_dict[hf_key] = value
        return hf_state_dict

    def from_hf(self, state_dict: dict) -> dict:
        """將 HF 狀態字典轉換為 TorchTitan 格式。"""
        tt_state_dict = {}
        for key, value in state_dict.items():
            tt_key = self._convert_key_from_hf(key)
            tt_state_dict[tt_key] = value
        return tt_state_dict
```

## 步驟 6：訓練配置 (Training Config)

```toml
# train_configs/your_model_8b.toml
[job]
dump_folder = "./outputs"
description = "Your Model 8B 訓練"

[model]
name = "your_model"
flavor = "8B"

[optimizer]
name = "AdamW"
lr = 3e-4

[training]
local_batch_size = 2
seq_len = 8192
steps = 1000
dataset = "c4"

[parallelism]
data_parallel_shard_degree = -1
tensor_parallel_degree = 1
```

## 步驟 7：註冊模型

新增至 `torchtitan/models/__init__.py`：

```python
from .your_model import get_train_spec as get_your_model_train_spec

MODEL_REGISTRY["your_model"] = get_your_model_train_spec
```

## 測試

### 數值測試 (Numerics Test)

將輸出與 HuggingFace 實作進行比較：

```python
def test_numerics():
    # 將相同的檢查點載入到兩個實作中
    tt_model = YourModel(args).load_checkpoint(...)
    hf_model = HFYourModel.from_pretrained(...)

    # 比較輸出
    input_ids = torch.randint(0, vocab_size, (1, 128))
    tt_output = tt_model(input_ids)
    hf_output = hf_model(input_ids).logits

    torch.testing.assert_close(tt_output, hf_output, atol=1e-4, rtol=1e-4)
```

### 損失收斂 (Loss Convergence)

將損失曲線與已驗證的基準進行比較 (請參閱 `docs/converging_zh_TW.md`)。

### 效能基準測試 (Performance Benchmark)

將基準配置新增至 `benchmarks/` 目錄。

## 指導原則

1. **可讀性優於彈性**：不要過度抽象化。
2. **最小化模型變動**：平行處理是在外部套用的。
3. **精簡、最小化的程式碼庫**：盡可能重用現有組件。
4. **單一設備語義**：模型程式碼應能在單一 GPU 上運作。
