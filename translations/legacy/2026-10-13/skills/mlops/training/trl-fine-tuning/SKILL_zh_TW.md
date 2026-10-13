---
name: fine-tuning-with-trl
description: 使用 TRL 透過強化學習微調 LLM —— 包含用於指令微調的 SFT、用於偏好對齊的 DPO、用於獎勵優化的 PPO/GRPO 以及獎勵模型訓練。當需要 RLHF、使模型與偏好對齊或根據人類回饋進行訓練時使用。可與 HuggingFace Transformers 配合使用。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [trl, transformers, datasets, peft, accelerate, torch]
metadata:
  hermes:
    tags: [訓練後處理, TRL, 強化學習, 微調, SFT, DPO, PPO, GRPO, RLHF, 偏好對齊, HuggingFace]

---

# TRL - Transformer 強化學習 (Transformer Reinforcement Learning)

## 快速上手

TRL 提供多種訓練後 (Post-training) 方法，用於將語言模型與人類偏好對齊。

**安裝**：
```bash
pip install trl transformers datasets peft accelerate
```

**有監督微調 (SFT)** (指令微調)：
```python
from trl import SFTTrainer

trainer = SFTTrainer(
    model="Qwen/Qwen2.5-0.5B",
    train_dataset=dataset,  # 提示-補全 (Prompt-completion) 樣本對
)
trainer.train()
```

**DPO** (與偏好對齊)：
```python
from trl import DPOTrainer, DPOConfig

config = DPOConfig(output_dir="model-dpo", beta=0.1)
trainer = DPOTrainer(
    model=model,
    args=config,
    train_dataset=preference_dataset,  # 已選/已拒 (Chosen/Rejected) 樣本對
    processing_class=tokenizer
)
trainer.train()
```

## 常見工作流程

### 工作流程 1：完整的 RLHF 流程 (SFT → 獎勵模型 → PPO)

從基礎模型到人類對齊模型的完整流程。

複製此檢查清單：

```
RLHF 訓練：
- [ ] 步驟 1：有監督微調 (SFT)
- [ ] 步驟 2：訓練獎勵模型 (Reward Model)
- [ ] 步驟 3：PPO 強化學習
- [ ] 步驟 4：評估對齊後的模型
```

**步驟 1：有監督微調 (SFT)**

在指令遵循資料上訓練基礎模型：

```python
from transformers import AutoModelForCausalLM, AutoTokenizer
from trl import SFTTrainer, SFTConfig
from datasets import load_dataset

# 載入模型
model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen2.5-0.5B")
tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen2.5-0.5B")

# 載入指令資料集
dataset = load_dataset("trl-lib/Capybara", split="train")

# 配置訓練
training_args = SFTConfig(
    output_dir="Qwen2.5-0.5B-SFT",
    per_device_train_batch_size=4,
    num_train_epochs=1,
    learning_rate=2e-5,
    logging_steps=10,
    save_strategy="epoch"
)

# 訓練
trainer = SFTTrainer(
    model=model,
    args=training_args,
    train_dataset=dataset,
    tokenizer=tokenizer
)
trainer.train()
trainer.save_model()
```

**步驟 2：訓練獎勵模型 (Reward Model)**

訓練模型以預測人類偏好：

```python
from transformers import AutoModelForSequenceClassification
from trl import RewardTrainer, RewardConfig

# 載入 SFT 模型作為基礎
model = AutoModelForSequenceClassification.from_pretrained(
    "Qwen2.5-0.5B-SFT",
    num_labels=1  # 單一獎勵分數
)
tokenizer = AutoTokenizer.from_pretrained("Qwen2.5-0.5B-SFT")

# 載入偏好資料 (已選/已拒樣本對)
dataset = load_dataset("trl-lib/ultrafeedback_binarized", split="train")

# 配置訓練
training_args = RewardConfig(
    output_dir="Qwen2.5-0.5B-Reward",
    per_device_train_batch_size=2,
    num_train_epochs=1,
    learning_rate=1e-5
)

# 訓練獎勵模型
trainer = RewardTrainer(
    model=model,
    args=training_args,
    processing_class=tokenizer,
    train_dataset=dataset
)
trainer.train()
trainer.save_model()
```

**步驟 3：PPO 強化學習**

使用獎勵模型優化策略 (Policy)：

```bash
python -m trl.scripts.ppo \
    --model_name_or_path Qwen2.5-0.5B-SFT \
    --reward_model_path Qwen2.5-0.5B-Reward \
    --dataset_name trl-internal-testing/descriptiveness-sentiment-trl-style \
    --output_dir Qwen2.5-0.5B-PPO \
    --learning_rate 3e-6 \
    --per_device_train_batch_size 64 \
    --total_episodes 10000
```

**步驟 4：評估**

```python
from transformers import pipeline

# 載入對齊後的模型
generator = pipeline("text-generation", model="Qwen2.5-0.5B-PPO")

# 測試
prompt = "Explain quantum computing to a 10-year-old"
output = generator(prompt, max_length=200)[0]["generated_text"]
print(output)
```

### 工作流程 2：使用 DPO 進行簡單的偏好對齊

無需獎勵模型即可將模型與偏好對齊。

複製此檢查清單：

```
DPO 訓練：
- [ ] 步驟 1：準備偏好資料集
- [ ] 步驟 2：配置 DPO
- [ ] 步驟 3：使用 DPOTrainer 進行訓練
- [ ] 步驟 4：評估對齊情況
```

**步驟 1：準備偏好資料集**

資料集格式：
```json
{
  "prompt": "What is the capital of France?",
  "chosen": "The capital of France is Paris.",
  "rejected": "I don't know."
}
```

載入資料集：
```python
from datasets import load_dataset

dataset = load_dataset("trl-lib/ultrafeedback_binarized", split="train")
# 或載入您自己的資料集
# dataset = load_dataset("json", data_files="preferences.json")
```

**步驟 2：配置 DPO**

```python
from trl import DPOConfig

config = DPOConfig(
    output_dir="Qwen2.5-0.5B-DPO",
    per_device_train_batch_size=4,
    num_train_epochs=1,
    learning_rate=5e-7,
    beta=0.1,  # KL 懲罰強度
    max_prompt_length=512,
    max_length=1024,
    logging_steps=10
)
```

**步驟 3：使用 DPOTrainer 進行訓練**

```python
from transformers import AutoModelForCausalLM, AutoTokenizer
from trl import DPOTrainer

model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen2.5-0.5B-Instruct")
tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen2.5-0.5B-Instruct")

trainer = DPOTrainer(
    model=model,
    args=config,
    train_dataset=dataset,
    processing_class=tokenizer
)

trainer.train()
trainer.save_model()
```

**CLI 替代方案**：
```bash
trl dpo \
    --model_name_or_path Qwen/Qwen2.5-0.5B-Instruct \
    --dataset_name argilla/Capybara-Preferences \
    --output_dir Qwen2.5-0.5B-DPO \
    --per_device_train_batch_size 4 \
    --learning_rate 5e-7 \
    --beta 0.1
```

### 工作流程 3：使用 GRPO 進行記憶體高效的線上強化學習

使用極低記憶體進行強化學習訓練。

複製此檢查清單：

```
GRPO 訓練：
- [ ] 步驟 1：定義獎勵函數 (Reward Function)
- [ ] 步驟 2：配置 GRPO
- [ ] 步驟 3：使用 GRPOTrainer 進行訓練
```

**步驟 1：定義獎勵函數**

```python
def reward_function(completions, **kwargs):
    """
    計算補全內容的獎勵分數。

    參數：
        completions: 生成文字列表

    回傳：
        獎勵分數列表 (浮點數)
    """
    rewards = []
    for completion in completions:
        # 範例：根據長度和不重複詞彙給予獎勵
        score = len(completion.split())  # 鼓勵較長的回應
        score += len(set(completion.lower().split()))  # 鼓勵使用不重複詞彙
        rewards.append(score)
    return rewards
```

或使用獎勵模型：
```python
from transformers import pipeline

reward_model = pipeline("text-classification", model="reward-model-path")

def reward_from_model(completions, prompts, **kwargs):
    # 組合 提示 + 補全
    full_texts = [p + c for p, c in zip(prompts, completions)]
    # 獲取獎勵分數
    results = reward_model(full_texts)
    return [r["score"] for r in results]
```

**步驟 2：配置 GRPO**

```python
from trl import GRPOConfig

config = GRPOConfig(
    output_dir="Qwen2-GRPO",
    per_device_train_batch_size=4,
    num_train_epochs=1,
    learning_rate=1e-5,
    num_generations=4,  # 每個提示生成 4 個補全內容
    max_new_tokens=128
)
```

**步驟 3：使用 GRPOTrainer 進行訓練**

```python
from datasets import load_dataset
from trl import GRPOTrainer

# 載入僅包含提示的資料集
dataset = load_dataset("trl-lib/tldr", split="train")

trainer = GRPOTrainer(
    model="Qwen/Qwen2-0.5B-Instruct",
    reward_funcs=reward_function,  # 您的獎勵函數
    args=config,
    train_dataset=dataset
)

trainer.train()
```

**CLI**：
```bash
trl grpo \
    --model_name_or_path Qwen/Qwen2-0.5B-Instruct \
    --dataset_name trl-lib/tldr \
    --output_dir Qwen2-GRPO \
    --num_generations 4
```

## 何時使用與替代方案

**在以下情況使用 TRL：**
- 需要使模型與人類偏好對齊
- 擁有偏好資料 (已選/已拒樣本對)
- 希望使用強化學習 (PPO, GRPO)
- 需要進行獎勵模型訓練
- 執行 RLHF (完整流程)

**方法選擇**：
- **SFT**：擁有提示-補全樣本對，希望進行基礎指令微調
- **DPO**：擁有偏好資料，希望進行簡單對齊 (無需獎勵模型)
- **PPO**：擁有獎勵模型，需要對強化學習進行最大程度的控制
- **GRPO**：記憶體受限，希望進行線上強化學習 (Online RL)
- **獎勵模型**：建置 RLHF 流程，需要為生成內容評分

**改用以下替代方案：**
- **HuggingFace Trainer**：不含強化學習的基礎微調
- **Axolotl**：基於 YAML 的訓練配置
- **LitGPT**：教學性質、極簡的微調工具
- **Unsloth**：快速的 LoRA 訓練

## 常見問題

**問題：DPO 訓練期間 OOM (記憶體不足)**

減小批次大小與序列長度：
```python
config = DPOConfig(
    per_device_train_batch_size=1,  # 從 4 減小
    max_length=512,  # 從 1024 減小
    gradient_accumulation_steps=8  # 維持有效的 Batch Size
)
```

或啟用梯度檢查點：
```python
model.gradient_checkpointing_enable()
```

**問題：對齊品質不佳**

調整 beta 參數：
```python
# 較高的 beta = 較保守 (與參考模型保持較近距離)
config = DPOConfig(beta=0.5)  # 預設為 0.1

# 較低的 beta = 較激進的對齊
config = DPOConfig(beta=0.01)
```

**問題：獎勵模型未在學習**

檢查損失類型與學習率：
```python
config = RewardConfig(
    learning_rate=1e-5,  # 嘗試不同的學習率
    num_train_epochs=3  # 訓練更久
)
```

確保偏好資料集有明確的優劣之分：
```python
# 驗證資料集
print(dataset[0])
# 應有明確的 已選 (chosen) > 已拒 (rejected)
```

**問題：PPO 訓練不穩定**

調整 KL 係數：
```python
config = PPOConfig(
    kl_coef=0.1,  # 從 0.05 增加
    cliprange=0.1  # 從 0.2 減小
)
```

## 進階主題

**SFT 訓練指南**：請參閱 [references/sft-training_zh_TW.md](references/sft-training_zh_TW.md) 了解資料集格式、聊天範本 (Chat Template)、封裝 (Packing) 策略以及多 GPU 訓練。

**DPO 變體**：請參閱 [references/dpo-variants_zh_TW.md](references/dpo-variants_zh_TW.md) 了解 IPO、cDPO、RPO 以及其他 DPO 損失函數與建議的超參數。

**獎勵建模 (Reward Modeling)**：請參閱 [references/reward-modeling_zh_TW.md](references/reward-modeling_zh_TW.md) 了解結果獎勵 vs 過程獎勵、Bradley-Terry 損失以及獎勵模型評估。

**線上強化學習方法**：請參閱 [references/online-rl_zh_TW.md](references/online-rl_zh_TW.md) 了解 PPO、GRPO、RLOO 以及 OnlineDPO 的詳細配置。

## 硬體需求

- **GPU**：NVIDIA (需要 CUDA)
- **VRAM**：取決於模型與方法
  - SFT 7B：16GB (使用 LoRA)
  - DPO 7B：24GB (需儲存參考模型)
  - PPO 7B：40GB (策略模型 + 獎勵模型)
  - GRPO 7B：24GB (記憶體效率較高)
- **多 GPU**：支援透過 `accelerate` 執行
- **混合精度**：推薦使用 BF16 (A100/H100)

**記憶體優化**：
- 對所有方法使用 LoRA/QLoRA
- 啟用梯度檢查點
- 使用較小的批次大小搭配梯度累積

## 資源

- 文件：https://huggingface.co/docs/trl/
- GitHub：https://github.com/huggingface/trl
- 論文：
  - "Training language models to follow instructions with human feedback" (InstructGPT, 2022)
  - "Direct Preference Optimization: Your Language Model is Secretly a Reward Model" (DPO, 2023)
  - "Group Relative Policy Optimization" (GRPO, 2024)
- 範例：https://github.com/huggingface/trl/tree/main/examples/scripts
