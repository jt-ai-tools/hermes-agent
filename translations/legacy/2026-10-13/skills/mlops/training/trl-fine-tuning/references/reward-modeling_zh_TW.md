# 獎勵建模 (Reward Modeling)

使用 TRL 為 RLHF 流程訓練獎勵模型的指南。

## 概觀

獎勵模型根據人類偏好為補全內容評分。用於：
- PPO 訓練 (強化學習回饋)
- GRPO 線上強化學習 (Online RL)
- 補全內容排序 (Completion ranking)

## 基礎訓練

```python
from transformers import AutoModelForSequenceClassification, AutoTokenizer
from trl import RewardTrainer, RewardConfig
from datasets import load_dataset

# 載入模型 (num_labels=1 表示單一獎勵分數)
model = AutoModelForSequenceClassification.from_pretrained(
    "Qwen/Qwen2.5-0.5B-Instruct",
    num_labels=1
)
tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen2.5-0.5B-Instruct")

# 載入偏好資料集 (已選/已拒樣本對)
dataset = load_dataset("trl-lib/ultrafeedback_binarized", split="train")

# 配置
config = RewardConfig(
    output_dir="Qwen2.5-Reward",
    per_device_train_batch_size=2,
    num_train_epochs=1,
    learning_rate=1e-5
)

# 訓練
trainer = RewardTrainer(
    model=model,
    args=config,
    processing_class=tokenizer,
    train_dataset=dataset
)
trainer.train()
```

## 資料集格式

必要欄位：
```json
{
  "prompt": "問題或指令",
  "chosen": "較佳的回應",
  "rejected": "較差的回應"
}
```

## Bradley-Terry 損失 (Bradley-Terry Loss)

預設損失函數：
```
loss = -log(sigmoid(reward_chosen - reward_rejected))
```

學習如何讓 已選 (chosen) 的評分 > 已拒 (rejected) 的評分。

## 使用獎勵模型

### 推論 (Inference)

```python
from transformers import pipeline

# 載入訓練好的獎勵模型
reward_pipe = pipeline("text-classification", model="Qwen2.5-Reward")

# 為補全內容評分
texts = ["Good answer", "Bad answer"]
scores = reward_pipe(texts)
print(scores)  # 分數越高 = 越好
```

### 在 PPO 中使用

```python
from trl import PPOTrainer, PPOConfig

config = PPOConfig(
    reward_model_path="Qwen2.5-Reward"  # 使用訓練好的獎勵模型
)

trainer = PPOTrainer(
    model=policy_model,
    config=config,
    # 獎勵模型將自動載入
)
```

## 超參數

| 模型大小 | 學習率 (Learning Rate) | 批次大小 (Batch Size) | Epochs |
|------------|---------------|------------|--------|
| <1B | 2e-5 | 4-8 | 1-2 |
| 1-7B | 1e-5 | 2-4 | 1 |
| 7-13B | 5e-6 | 1-2 | 1 |

## 評估

檢查獎勵分離度 (Reward separation)：
```python
# 已選 (chosen) 的評分應高於已拒 (rejected)
chosen_rewards = model(**chosen_inputs).logits
rejected_rewards = model(**rejected_inputs).logits

accuracy = (chosen_rewards > rejected_rewards).float().mean()
print(f"準確度：{accuracy:.2%}")  # 目標：>80%
```

## 參考資料

- InstructGPT 論文：https://arxiv.org/abs/2203.02155
- TRL 文件：https://huggingface.co/docs/trl/reward_trainer
