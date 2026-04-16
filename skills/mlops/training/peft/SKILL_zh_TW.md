---
name: peft-fine-tuning
description: 使用 LoRA、QLoRA 和 25+ 種方法對 LLM 進行參數高效微調。適用於在 GPU 記憶體有限的情況下微調大型模型 (7B-70B)、需要以極小的準確度損失訓練 <1% 的參數，或用於多適配器服務。HuggingFace 的官方函式庫，已與 transformers 生態系統整合。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [peft>=0.13.0, transformers>=4.45.0, torch>=2.0.0, bitsandbytes>=0.43.0]
metadata:
  hermes:
    tags: [微調, PEFT, LoRA, QLoRA, 參數高效, 適配器, 低秩, 記憶體優化, 多適配器]

---

# PEFT (參數高效微調)

透過 LoRA、QLoRA 和 25+ 種適配器方法，僅訓練 <1% 的參數即可微調 LLM。

## 何時使用 PEFT

**在以下情況使用 PEFT/LoRA：**
- 在消費級 GPU (RTX 4090, A100) 上微調 7B-70B 模型
- 需要訓練 <1% 的參數 (適配器約 6MB，而完整模型為 14GB)
- 希望使用多個特定任務的適配器進行快速迭代
- 從一個基礎模型部署多個微調變體

**在以下情況使用 QLoRA (PEFT + 量化)：**
- 在單張 24GB GPU 上微調 70B 模型
- 記憶體是主要限制因素
- 可以接受相較於全量微調約 ~5% 的品質折衷

**在以下情況改用全量微調 (Full Fine-Tuning)：**
- 訓練小模型 (<1B 參數)
- 需要最高品質且具備充足算力預算
- 顯著的領域遷移 (Domain Shift) 需要更新所有權重

## 快速上手

### 安裝

```bash
# 基礎安裝
pip install peft

# 包含量化支援 (推薦)
pip install peft bitsandbytes

# 完整堆疊
pip install peft transformers accelerate bitsandbytes datasets
```

### LoRA 微調 (標準)

```python
from transformers import AutoModelForCausalLM, AutoTokenizer, TrainingArguments, Trainer
from peft import get_peft_model, LoraConfig, TaskType
from datasets import load_dataset

# 載入基礎模型
model_name = "meta-llama/Llama-3.1-8B"
model = AutoModelForCausalLM.from_pretrained(model_name, torch_dtype="auto", device_map="auto")
tokenizer = AutoTokenizer.from_pretrained(model_name)
tokenizer.pad_token = tokenizer.eos_token

# LoRA 配置
lora_config = LoraConfig(
    task_type=TaskType.CAUSAL_LM,
    r=16,                          # 秩 (Rank，通常為 8-64，越高容量越大)
    lora_alpha=32,                 # 縮放因子 (通常為 2*r)
    lora_dropout=0.05,             # 用於正則化的 Dropout
    target_modules=["q_proj", "v_proj", "k_proj", "o_proj"],  # 注意力層
    bias="none"                    # 不訓練偏置 (Bias)
)

# 套用 LoRA
model = get_peft_model(model, lora_config)
model.print_trainable_parameters()
# 輸出：trainable params: 13,631,488 || all params: 8,043,307,008 || trainable%: 0.17%

# 準備資料集
dataset = load_dataset("databricks/databricks-dolly-15k", split="train")

def tokenize(example):
    text = f"### Instruction:\n{example['instruction']}\n\n### Response:\n{example['response']}"
    return tokenizer(text, truncation=True, max_length=512, padding="max_length")

tokenized = dataset.map(tokenize, remove_columns=dataset.column_names)

# 訓練
training_args = TrainingArguments(
    output_dir="./lora-llama",
    num_train_epochs=3,
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    learning_rate=2e-4,
    fp16=True,
    logging_steps=10,
    save_strategy="epoch"
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=tokenized,
    data_collator=lambda data: {"input_ids": torch.stack([f["input_ids"] for f in data]),
                                 "attention_mask": torch.stack([f["attention_mask"] for f in data]),
                                 "labels": torch.stack([f["input_ids"] for f in data])}
)

trainer.train()

# 僅儲存適配器 (6MB vs 16GB)
model.save_pretrained("./lora-llama-adapter")
```

### QLoRA 微調 (記憶體高效)

```python
from transformers import AutoModelForCausalLM, BitsAndBytesConfig
from peft import get_peft_model, LoraConfig, prepare_model_for_kbit_training

# 4-bit 量化配置
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",           # NormalFloat4 (最適合 LLM)
    bnb_4bit_compute_dtype="bfloat16",   # 以 bf16 進行計算
    bnb_4bit_use_double_quant=True       # 嵌套量化 (Nested quantization)
)

# 載入量化模型
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-3.1-70B",
    quantization_config=bnb_config,
    device_map="auto"
)

# 訓練準備 (啟用梯度檢查點)
model = prepare_model_for_kbit_training(model)

# QLoRA 的 LoRA 配置
lora_config = LoraConfig(
    r=64,                              # 70B 模型使用較高的秩
    lora_alpha=128,
    lora_dropout=0.1,
    target_modules=["q_proj", "v_proj", "k_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
    bias="none",
    task_type="CAUSAL_LM"
)

model = get_peft_model(model, lora_config)
# 70B 模型現在可以放入單張 24GB GPU！
```

## LoRA 參數選擇

### 秩 (Rank, r) - 容量 vs 效率

| 秩 (Rank) | 可訓練參數 | 記憶體 | 品質 | 使用案例 |
|------|-----------------|--------|---------|----------|
| 4 | ~3M | 極低 | 較低 | 簡單任務、原型設計 |
| **8** | ~7M | 低 | 良好 | **推薦的起點** |
| **16** | ~14M | 中 | 更好 | **通用微調** |
| 32 | ~27M | 較高 | 高 | 複雜任務 |
| 64 | ~54M | 高 | 最高 | 領域自適應、70B 模型 |

### Alpha (lora_alpha) - 縮放因子

```python
# 經驗法則：alpha = 2 * rank
LoraConfig(r=16, lora_alpha=32)  # 標準
LoraConfig(r=16, lora_alpha=16)  # 保守 (降低學習率效果)
LoraConfig(r=16, lora_alpha=64)  # 激進 (提高學習率效果)
```

### 依架構選擇目標模組 (Target Modules)

```python
# Llama / Mistral / Qwen
target_modules = ["q_proj", "v_proj", "k_proj", "o_proj", "gate_proj", "up_proj", "down_proj"]

# GPT-2 / GPT-Neo
target_modules = ["c_attn", "c_proj", "c_fc"]

# Falcon
target_modules = ["query_key_value", "dense", "dense_h_to_4h", "dense_4h_to_h"]

# BLOOM
target_modules = ["query_key_value", "dense", "dense_h_to_4h", "dense_4h_to_h"]

# 自動偵測所有線性層
target_modules = "all-linear"  # PEFT 0.6.0+
```

## 載入與合併適配器

### 載入訓練好的適配器

```python
from peft import PeftModel, AutoPeftModelForCausalLM
from transformers import AutoModelForCausalLM

# 選項 1：使用 PeftModel 載入
base_model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-3.1-8B")
model = PeftModel.from_pretrained(base_model, "./lora-llama-adapter")

# 選項 2：直接載入 (推薦)
model = AutoPeftModelForCausalLM.from_pretrained(
    "./lora-llama-adapter",
    device_map="auto"
)
```

### 將適配器合併至基礎模型

```python
# 為部署進行合併 (消除適配器開銷)
merged_model = model.merge_and_unload()

# 儲存合併後的模型
merged_model.save_pretrained("./llama-merged")
tokenizer.save_pretrained("./llama-merged")

# 推送至 Hub
merged_model.push_to_hub("username/llama-finetuned")
```

### 多適配器服務 (Multi-adapter serving)

```python
from peft import PeftModel

# 載入基礎模型與第一個適配器
model = AutoPeftModelForCausalLM.from_pretrained("./adapter-task1")

# 載入額外的適配器
model.load_adapter("./adapter-task2", adapter_name="task2")
model.load_adapter("./adapter-task3", adapter_name="task3")

# 在運行時切換適配器
model.set_adapter("task1")  # 使用 task1 適配器
output1 = model.generate(**inputs)

model.set_adapter("task2")  # 切換至 task2
output2 = model.generate(**inputs)

# 停用適配器 (使用基礎模型)
with model.disable_adapter():
    base_output = model.generate(**inputs)
```

## PEFT 方法比較

| 方法 | 可訓練 % | 記憶體 | 速度 | 最適合 |
|--------|------------|--------|-------|----------|
| **LoRA** | 0.1-1% | 低 | 快 | 通用微調 |
| **QLoRA** | 0.1-1% | 極低 | 中 | 記憶體受限 |
| AdaLoRA | 0.1-1% | 低 | 中 | 自動秩選擇 |
| IA3 | 0.01% | 極低 | 最快 | 少樣本自適應 |
| Prefix Tuning | 0.1% | 低 | 中 | 生成控制 |
| Prompt Tuning | 0.001% | 極低 | 快 | 簡單任務自適應 |
| P-Tuning v2 | 0.1% | 低 | 中 | NLU 任務 |

### IA3 (極小參數)

```python
from peft import IA3Config

ia3_config = IA3Config(
    target_modules=["q_proj", "v_proj", "k_proj", "down_proj"],
    feedforward_modules=["down_proj"]
)
model = get_peft_model(model, ia3_config)
# 僅訓練 0.01% 的參數！
```

### Prefix Tuning

```python
from peft import PrefixTuningConfig

prefix_config = PrefixTuningConfig(
    task_type="CAUSAL_LM",
    num_virtual_tokens=20,      # 前置 Token
    prefix_projection=True       # 使用 MLP 投影
)
model = get_peft_model(model, prefix_config)
```

## 整合模式

### 與 TRL 配合 (SFTTrainer)

```python
from trl import SFTTrainer, SFTConfig
from peft import LoraConfig

lora_config = LoraConfig(r=16, lora_alpha=32, target_modules="all-linear")

trainer = SFTTrainer(
    model=model,
    args=SFTConfig(output_dir="./output", max_seq_length=512),
    train_dataset=dataset,
    peft_config=lora_config,  # 直接傳遞 LoRA 配置
)
trainer.train()
```

### 與 Axolotl 配合 (YAML 配置)

```yaml
# axolotl config.yaml
adapter: lora
lora_r: 16
lora_alpha: 32
lora_dropout: 0.05
lora_target_modules:
  - q_proj
  - v_proj
  - k_proj
  - o_proj
lora_target_linear: true  # 目標設定為所有線性層
```

### 與 vLLM 配合 (推論)

```python
from vllm import LLM
from vllm.lora.request import LoRARequest

# 載入支援 LoRA 的基礎模型
llm = LLM(model="meta-llama/Llama-3.1-8B", enable_lora=True)

# 使用適配器進行服務
outputs = llm.generate(
    prompts,
    lora_request=LoRARequest("adapter1", 1, "./lora-adapter")
)
```

## 效能基準測試

### 記憶體使用量 (Llama 3.1 8B)

| 方法 | GPU 記憶體 | 可訓練參數 |
|--------|-----------|------------------|
| 全量微調 | 60+ GB | 8B (100%) |
| LoRA r=16 | 18 GB | 14M (0.17%) |
| QLoRA r=16 | 6 GB | 14M (0.17%) |
| IA3 | 16 GB | 800K (0.01%) |

### 訓練速度 (A100 80GB)

| 方法 | Tokens/sec | 相較全量微調 |
|--------|-----------|------------|
| 全量微調 | 2,500 | 1x |
| LoRA | 3,200 | 1.3x |
| QLoRA | 2,100 | 0.84x |

### 品質 (MMLU 基準測試)

| 模型 | 全量微調 | LoRA | QLoRA |
|-------|---------|------|-------|
| Llama 2-7B | 45.3 | 44.8 | 44.1 |
| Llama 2-13B | 54.8 | 54.2 | 53.5 |

## 常見問題

### 訓練期間 CUDA 記憶體不足 (OOM)

```python
# 解決方案 1：啟用梯度檢查點
model.gradient_checkpointing_enable()

# 解決方案 2：減小 Batch Size + 增加累積步數
TrainingArguments(
    per_device_train_batch_size=1,
    gradient_accumulation_steps=16
)

# 解決方案 3：使用 QLoRA
from transformers import BitsAndBytesConfig
bnb_config = BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_quant_type="nf4")
```

### 適配器未生效

```python
# 驗證適配器是否處於活動狀態
print(model.active_adapters)  # 應顯示適配器名稱

# 檢查可訓練參數
model.print_trainable_parameters()

# 確保模型處於訓練模式
model.train()
```

### 品質下降

```python
# 增加秩 (Rank)
LoraConfig(r=32, lora_alpha=64)

# 目標更多模組
target_modules = "all-linear"

# 使用更多訓練資料與 Epoch
TrainingArguments(num_train_epochs=5)

# 降低學習率
TrainingArguments(learning_rate=1e-4)
```

## 最佳實踐

1. **從 r=8-16 開始**，若品質不足再增加
2. **以 alpha = 2 * rank** 作為起點
3. **目標注意力層 + MLP 層** 以獲得最佳品質/效率比
4. **啟用梯度檢查點** 以節省記憶體
5. **頻繁儲存適配器** (檔案小，易於回滾)
6. **在合併前於留出資料 (Held-out data) 上進行評估**
7. **在消費級硬體上對 70B+ 模型使用 QLoRA**

## 參考資料

- **[進階用法](references/advanced-usage_zh_TW.md)** - DoRA、LoftQ、秩穩定化、自訂模組
- **[疑難排解](references/troubleshooting_zh_TW.md)** - 常見錯誤、除錯、優化

## 資源

- **GitHub**: https://github.com/huggingface/peft
- **文件**: https://huggingface.co/docs/peft
- **LoRA 論文**: arXiv:2106.09685
- **QLoRA 論文**: arXiv:2305.14314
- **模型**: https://huggingface.co/models?library=peft
