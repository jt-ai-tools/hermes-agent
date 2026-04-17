# slime API 參考

## 架構概覽

slime 採用三模組架構，由 Ray 進行編排：

```
┌─────────────────────────────────────────────────────────┐
│                    數據緩衝區 (Data Buffer)             │
│ - Prompt 初始化與管理                                   │
│ - 自定義數據生成與過濾                                 │
│ - Rollout 樣本存儲                                      │
└─────────────┬───────────────────────────┬───────────────┘
              │                           │
┌─────────────▼───────────┐ ┌─────────────▼───────────────┐
│ 訓練 (Megatron-LM)      │ │ Rollout (SGLang + Router)   │
│ - Actor 模型訓練        │ │ - 回應生成                  │
│ - Critic (選填)         │ │ - 獎勵/驗證器輸出           │
│ - 權重同步至 Rollout    │ │ - 多輪支援                  │
└─────────────────────────┘ └─────────────────────────────┘
```

## 核心數據結構

### Sample 物件

`Sample` 物件是定義在 `slime/utils/types.py` 中的核心數據結構：

```python
from slime.utils.types import Sample

@dataclass
class Sample:
    # 核心欄位
    group_index: Optional[int]              # 用於批處理的群組索引
    index: Optional[int]                    # 樣本索引
    prompt: str | list[dict] = ""           # 輸入 Prompt 或對話歷史
    tokens: list[int] = field(default_factory=list)  # Token ID 列表
    response: str = ""                      # 生成的回應
    response_length: int = 0                # 回應的 Token 長度
    label: Optional[str] = None             # 真實標籤 (Ground truth)
    reward: Optional[float | dict] = None   # RL 獎勵信號
    loss_mask: Optional[list[int]] = None   # 1=計算 Loss, 0=遮蔽
    status: Status = Status.PENDING         # 樣本狀態
    metadata: dict = field(default_factory=dict)  # 自定義數據

    # 多模態支援
    multimodal_inputs: Optional[Any] = None       # 原始多模態數據 (圖像、影片)
    multimodal_train_inputs: Optional[Any] = None # 處理後的多模態數據 (pixel_values)

    # Rollout 追蹤
    weight_versions: list[str] = field(default_factory=list)
    rollout_log_probs: Optional[list[float]] = None    # 來自 SGLang 的 Log probs
    rollout_routed_experts: Optional[list[list[int]]] = None  # 專家路由 (MoE)

    # 控制欄位
    remove_sample: bool = False
    generate_function_path: Optional[str] = None
    train_metadata: Optional[dict] = None
    non_generation_time: float = 0.0

    # 推測解碼 (Speculative decoding) 資訊 (巢狀數據類別)
    @dataclass
    class SpecInfo:
        spec_accept_token_num: int = 0
        spec_draft_token_num: int = 0
        spec_verify_ct: int = 0
        completion_token_num: int = 0
```

### Status 列舉 (Enum)

```python
class Status(Enum):
    PENDING = "pending"           # 尚未處理
    COMPLETED = "completed"       # 生成成功
    TRUNCATED = "truncated"       # 達到最大長度
    ABORTED = "aborted"           # 生成中斷
    FAILED = "failed"             # 生成失敗
```

## 配置系統

slime 使用三類命令行參數：

### 1. Megatron 參數

直接支援所有 Megatron-LM 參數：

```bash
--tensor-model-parallel-size 2
--pipeline-model-parallel-size 1
--num-layers 32
--hidden-size 4096
--num-attention-heads 32
--seq-length 4096
--micro-batch-size 1
--global-batch-size 256
```

### 2. SGLang 參數

SGLang 參數以 `--sglang-` 為前綴：

```bash
--sglang-mem-fraction-static 0.8   # 用於 KV 快取的 GPU 顯存比例
--sglang-context-length 8192       # 最大上下文長度
--sglang-log-level INFO            # 日誌詳細程度
--sglang-tp-size 2                 # 張量並行 (Tensor parallelism)
--sglang-disable-cuda-graph        # 停用 CUDA graphs
```

### 3. slime 專屬參數

定義在 `slime/utils/arguments.py`：

```bash
# 資源分配
--actor-num-nodes 1                # 訓練節點數
--actor-num-gpus-per-node 8        # 每個訓練節點的 GPU 數
--rollout-num-gpus 8               # Rollout 總 GPU 數
--rollout-num-gpus-per-engine 2    # 每個 SGLang 引擎的 GPU 數
--colocate                         # 訓練/推理共享 GPU

# 數據配置
--prompt-data /path/to/data.jsonl  # 訓練數據路徑
--input-key prompt                 # JSON 中 Prompt 的 Key
--label-key label                  # JSON 中標籤的 Key
--apply-chat-template              # 應用對話模板

# 訓練循環
--num-rollout 3000                 # 總 Rollout 迭代次數
--rollout-batch-size 32            # 每次 Rollout 的 Prompt 數量
--n-samples-per-prompt 8           # 每個 Prompt 生成的回應數
--global-batch-size 256            # 訓練 Batch Size
--num-steps-per-rollout 1          # 每次 Rollout 的訓練步數

# RL 演算法
--advantage-estimator grpo         # grpo, gspo, ppo, reinforce_plus_plus
--use-kl-loss                      # 啟用 KL 損失
--kl-loss-coef 0.001               # KL 係數
--calculate-per-token-loss         # Token 等級的損失計算

# 離線策略 (Off-Policy) 選項
--use-tis                          # 截斷重要性採樣 (Truncated Importance Sampling)
--tis-threshold 0.9                # TIS 閾值
--true-on-policy-mode              # 強制在線策略 (On-policy) 訓練
```

## 數據緩衝系統

### RolloutDataSource (基類)

```python
from slime.data import RolloutDataSource

class RolloutDataSource:
    def __init__(self, dataset, args):
        self.dataset = dataset
        self.args = args

    def get_samples(self, num_samples: int) -> list[Sample]:
        """從數據集中獲取 Prompt。"""
        return [Sample(prompt=p) for p in self.dataset.sample(num_samples)]

    def add_samples(self, samples: list[Sample]) -> None:
        """生成後調用 (預設為空操作)。"""
        pass
```

### 帶緩衝區的數據源 (用於離線策略)

```python
from slime.data import RolloutDataSourceWithBuffer

class RolloutDataSourceWithBuffer(RolloutDataSource):
    def __init__(self, dataset, args):
        super().__init__(dataset, args)
        self.buffer = []

    def add_samples(self, samples: list[Sample]) -> None:
        """存儲生成的樣本以便重複使用。"""
        self.buffer.extend(samples)

    def buffer_filter(self, args, buffer, num_samples) -> list[Sample]:
        """自定義選擇邏輯。"""
        # 範例：基於 Reward 的優先級採樣
        sorted_buffer = sorted(buffer, key=lambda s: s.reward, reverse=True)
        return sorted_buffer[:num_samples]
```

## 自定義函數

### 自定義生成函數 (Custom Generate Function)

適用於多輪對話或工具調用場景：

```python
# custom_generate.py
from slime.data import Sample

async def custom_generate(args, samples: list[Sample], evaluation: bool = False) -> list[Sample]:
    """
    用於多輪互動的自定義生成函數。

    參數：
        args: 訓練參數
        samples: 包含 Prompt 的 Sample 物件列表
        evaluation: 是否為評估運行

    返回：
        包含回應和 Reward 的 Sample 物件列表
    """
    for sample in samples:
        conversation = sample.prompt if isinstance(sample.prompt, list) else [
            {"role": "user", "content": sample.prompt}
        ]

        for turn in range(args.max_turns):
            # 生成回應
            response = await generate_single(conversation)

            # 檢查是否有工具調用
            tool_call = extract_tool_call(response)
            if tool_call:
                # 執行工具
                tool_result = await execute_tool(tool_call)
                conversation.append({"role": "assistant", "content": response})
                conversation.append({"role": "tool", "content": tool_result})
            else:
                # 最終回應
                sample.response = response
                break

        # 計算獎勵
        sample.reward = compute_reward(sample)

        # 設置 Loss Mask (模型生成的 Token 為 1，工具回應為 0)
        sample.loss_mask = build_loss_mask(sample)

    return samples
```

用法：
```bash
python train.py \
    --custom-generate-function-path custom_generate.py \
    --max-turns 5
```

### 自定義獎勵函數 (Custom Reward Function)

```python
# custom_rm.py
from slime.data import Sample

async def reward_func(args, sample: Sample, **kwargs) -> float:
    """
    計算單個樣本的獎勵。

    參數：
        args: 訓練參數
        sample: 包含回應的 Sample 物件

    返回：
        獎勵分數 (float)
    """
    response = sample.response
    ground_truth = sample.label or sample.metadata.get("answer", "")

    # 範例：精確匹配獎勵
    if response.strip() == ground_truth.strip():
        return 1.0
    return 0.0

# 用於批處理 (效率更高)
async def batched_custom_rm(args, samples: list[Sample]) -> list[float]:
    """批處理獎勵計算。"""
    rewards = []
    for sample in samples:
        reward = await reward_func(args, sample)
        rewards.append(reward)
    return rewards
```

用法：
```bash
python train.py \
    --custom-rm-path custom_rm.py \
    --group-rm  # 啟用批處理
```

## 模型配置

### 預配置的模型腳本

位於 `scripts/models/`：

```bash
# 列出可用模型
ls scripts/models/
# glm4-9B.sh, qwen3-4B.sh, qwen3-30B-A3B.sh, deepseek-v3.sh, llama3-8B.sh

# 引用模型配置
source scripts/models/qwen3-4B.sh
# 這會設置 MODEL_ARGS 和 CKPT_ARGS 陣列
```

### 模型腳本範例

```bash
# scripts/models/qwen3-4B.sh
export MODEL_ARGS=(
    --num-layers 36
    --hidden-size 2560
    --num-attention-heads 20
    --num-query-groups 4
    --ffn-hidden-size 6912
    --max-position-embeddings 32768
    --rotary-percent 1.0
    --rotary-base 1000000
    --swiglu
    --untie-embeddings-and-output-weights
    --no-position-embedding
    --normalization RMSNorm
    --tokenizer-type HuggingFaceTokenizer
    --bf16
)

export CKPT_ARGS=(
    --hf-checkpoint /path/to/qwen3-4b-hf
    --initial-megatron-checkpoint /path/to/megatron/ckpt
)
```

## 非同步訓練

### 啟用非同步模式

```bash
python train_async.py \
    --actor-num-gpus-per-node 8 \
    --rollout-num-gpus 8 \
    --async-buffer-size 4 \
    --update-weights-interval 2 \
    ${MODEL_ARGS[@]}
```

### 非同步專用參數

```bash
--async-buffer-size 4            # 緩衝的 Rollout 數量
--update-weights-interval 2      # 每 N 次 Rollout 同步一次權重
```

**注意**：同地協作模式 (`--colocate`) 不支援非同步訓練。

## 評估 (Evaluation)

### 多任務評估

```bash
--eval-prompt-data aime /path/to/aime.jsonl \
--eval-prompt-data gsm8k /path/to/gsm8k.jsonl \
--n-samples-per-eval-prompt 16 \
--eval-interval 50
```

### 評估配置

```bash
--eval-interval 50               # 每 N 次 Rollout 進行一次評估
--n-samples-per-eval-prompt 16   # 評估時的採樣數
--eval-temperature 0.0           # 評估時使用貪婪解碼 (Greedy decoding)
```

## 支援的模型

| 模型家族 | 配置 |
|--------------|----------------|
| GLM | GLM-4.5, GLM-4.6, GLM-4.7, GLM-Z1-9B |
| Qwen | Qwen3 (4B, 8B, 30B-A3B), Qwen3-MoE, Qwen2.5 |
| DeepSeek | V3, V3.1, R1 |
| Llama | Llama 3 (8B, 70B) |
| 其他 | Kimi K2, Moonlight-16B |

## 資源

- 文件: https://thudm.github.io/slime/
- GitHub: https://github.com/THUDM/slime
- 部落格: https://lmsys.org/blog/2025-07-09-slime/
- 範例：`examples/` 目錄 (包含 14 個以上的實作範例)
