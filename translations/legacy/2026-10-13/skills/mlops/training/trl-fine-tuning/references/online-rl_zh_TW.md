# 線上強化學習 (Online RL) 方法

包含 PPO、GRPO、RLOO 與 OnlineDPO 的線上強化學習指南。

## 概觀

線上強化學習 (Online RL) 在訓練過程中生成補全內容，並根據獎勵分數進行優化。

## PPO (近端策略優化, Proximal Policy Optimization)

用於 LLM 對齊的經典強化學習演算法。

### 基礎用法

```bash
python -m trl.scripts.ppo \
    --model_name_or_path Qwen/Qwen2.5-0.5B-Instruct \
    --reward_model_path reward-model \
    --dataset_name trl-internal-testing/descriptiveness-sentiment-trl-style \
    --output_dir model-ppo \
    --learning_rate 3e-6 \
    --per_device_train_batch_size 64 \
    --total_episodes 10000 \
    --num_ppo_epochs 4 \
    --kl_coef 0.05
```

### 關鍵參數

- `kl_coef`：KL 懲罰 (通常為 0.05-0.2)
- `num_ppo_epochs`：每個批次 (Batch) 的訓練 Epoch 數 (通常為 2-4)
- `cliprange`：PPO 裁剪範圍 (通常為 0.1-0.3)
- `vf_coef`：價值函數 (Value Function) 係數 (預設為 0.1)

## GRPO (群體相對策略優化, Group Relative Policy Optimization)

記憶體高效的線上強化學習。

### 基礎用法

```python
from trl import GRPOTrainer, GRPOConfig
from datasets import load_dataset

# 定義獎勵函數
def reward_func(completions, **kwargs):
    return [len(set(c.split())) for c in completions]

config = GRPOConfig(
    output_dir="model-grpo",
    num_generations=4,  # 每個提示生成的補全內容數量
    max_new_tokens=128
)

trainer = GRPOTrainer(
    model="Qwen/Qwen2-0.5B-Instruct",
    reward_funcs=reward_func,
    args=config,
    train_dataset=load_dataset("trl-lib/tldr", split="train")
)
trainer.train()
```

### 關鍵參數

- `num_generations`：生成 2-8 個補全內容
- `max_new_tokens`：生成 64-256 個 Token
- 學習率 (Learning rate)：通常為 1e-5 到 1e-4

## 記憶體使用量比較

| 方法 | 記憶體 (7B 模型) | 速度 | 使用案例 |
|--------|-------------|-------|----------|
| PPO | 40GB | 中 | 需要最大程度的控制 |
| GRPO | 24GB | 快 | **記憶體受限的環境** |
| OnlineDPO | 28GB | 快 | 無需獎勵模型的情境 |

## 參考資料

- PPO 論文：https://arxiv.org/abs/1707.06347
- GRPO 論文：https://arxiv.org/abs/2402.03300
- TRL 文件：https://huggingface.co/docs/trl/
