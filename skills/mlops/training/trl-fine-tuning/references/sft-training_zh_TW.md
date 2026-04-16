# 有監督微調 (SFT) 訓練指南

使用 TRL 進行有監督微調 (Supervised Fine-Tuning, SFT) 的完整指南，適用於指令微調 (Instruction Tuning) 與特定任務微調。

## 概觀

SFT 在輸入-輸出樣本對上訓練模型，以最小化交叉熵損失 (Cross-Entropy Loss)。用於：
- 指令遵循 (Instruction following)
- 特定任務微調
- 聊天機器人訓練
- 領域自適應 (Domain adaptation)

## 資料集格式

### 格式 1：提示-補全 (Prompt-Completion)

```json
[
  {
    "prompt": "What is the capital of France?",
    "completion": "The capital of France is Paris."
  }
]
```

### 格式 2：對話式 (ChatML)

```json
[
  {
    "messages": [
      {"role": "user", "content": "What is Python?"},
      {"role": "assistant", "content": "Python is a programming language."}
    ]
  }
]
```

### 格式 3：純文字 (Text-only)

```json
[
  {"text": "User: Hello\nAssistant: Hi! How can I help?"}
]
```

## 基礎訓練

```python
from trl import SFTTrainer, SFTConfig
from transformers import AutoModelForCausalLM, AutoTokenizer
from datasets import load_dataset

# 載入模型
model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen2.5-0.5B")
tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen2.5-0.5B")

# 載入資料集
dataset = load_dataset("trl-lib/Capybara", split="train")

# 配置
config = SFTConfig(
    output_dir="Qwen2.5-SFT",
    per_device_train_batch_size=4,
    num_train_epochs=1,
    learning_rate=2e-5,
    save_strategy="epoch"
)

# 訓練
trainer = SFTTrainer(
    model=model,
    args=config,
    train_dataset=dataset,
    tokenizer=tokenizer
)
trainer.train()
```

## 聊天範本 (Chat Templates)

自動套用聊天範本：

```python
trainer = SFTTrainer(
    model=model,
    args=config,
    train_dataset=dataset,  # 訊息 (Messages) 格式
    tokenizer=tokenizer
    # 聊天範本將自動套用
)
```

或手動套用：
```python
def format_chat(example):
    messages = example["messages"]
    text = tokenizer.apply_chat_template(messages, tokenize=False)
    return {"text": text}

dataset = dataset.map(format_chat)
```

## 封裝 (Packing) 以提升效率

將多個序列封裝進同一個樣本中，以最大化 GPU 利用率：

```python
config = SFTConfig(
    packing=True,  # 啟用封裝 (Packing)
    max_seq_length=2048,
    dataset_text_field="text"
)
```

**優點**：訓練速度提升 2-3 倍
**權衡**：批次化 (Batching) 邏輯略微複雜

## 多 GPU 訓練

```bash
accelerate launch --num_processes 4 train_sft.py
```

或透過配置執行：
```python
config = SFTConfig(
    output_dir="model-sft",
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    num_train_epochs=1
)
```

## LoRA 微調

```python
from peft import LoraConfig

lora_config = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules="all-linear",
    lora_dropout=0.05,
    task_type="CAUSAL_LM"
)

trainer = SFTTrainer(
    model=model,
    args=config,
    train_dataset=dataset,
    peft_config=lora_config  # 加入 LoRA
)
```

## 超參數

| 模型大小 | 學習率 (Learning Rate) | 批次大小 (Batch Size) | Epochs |
|------------|---------------|------------|--------|
| <1B | 5e-5 | 8-16 | 1-3 |
| 1-7B | 2e-5 | 4-8 | 1-2 |
| 7-13B | 1e-5 | 2-4 | 1 |
| 13B+ | 5e-6 | 1-2 | 1 |

## 參考資料

- TRL 文件：https://huggingface.co/docs/trl/sft_trainer
- 範例：https://github.com/huggingface/trl/tree/main/examples/scripts
