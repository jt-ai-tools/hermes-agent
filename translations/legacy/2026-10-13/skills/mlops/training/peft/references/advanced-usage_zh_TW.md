# PEFT 進階用法指南

## 進階 LoRA 變體

### DoRA (權重分解低秩自適應)

DoRA 將權重分解為量值 (Magnitude) 與方向 (Direction) 組件，通常能獲得比標準 LoRA 更好的結果：

```python
from peft import LoraConfig

dora_config = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules=["q_proj", "v_proj", "k_proj", "o_proj"],
    use_dora=True,  # 啟用 DoRA
    task_type="CAUSAL_LM"
)

model = get_peft_model(model, dora_config)
```

**何時使用 DoRA**：
- 在指令遵循任務上表現持續優於 LoRA
- 由於量值向量，記憶體開銷略高 (~10%)
- 最適合對品質要求極高的微調

### AdaLoRA (自適應秩)

根據重要性自動調整每層的秩 (Rank)：

```python
from peft import AdaLoraConfig

adalora_config = AdaLoraConfig(
    init_r=64,              # 初始秩
    target_r=16,            # 目標平均秩
    tinit=200,              # 暖身 (Warmup) 步數
    tfinal=1000,            # 最終剪枝步數
    deltaT=10,              # 秩更新頻率
    beta1=0.85,
    beta2=0.85,
    orth_reg_weight=0.5,    # 正交性正則化
    target_modules=["q_proj", "v_proj"],
    task_type="CAUSAL_LM"
)
```

**優點**：
- 為重要的層分配更多的秩
- 能在保持品質的同時減少總參數數量
- 適合用於探索最佳的秩分配

### LoRA+ (非對稱學習率)

為 A 矩陣與 B 矩陣設定不同的學習率：

```python
from peft import LoraConfig

# LoRA+ 為 B 矩陣使用較高的學習率 (LR)
lora_plus_config = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules="all-linear",
    use_rslora=True,  # 秩穩定化 LoRA (相關技術)
)

# 手動實作 LoRA+
from torch.optim import AdamW

# 參數分組
lora_A_params = [p for n, p in model.named_parameters() if "lora_A" in n]
lora_B_params = [p for n, p in model.named_parameters() if "lora_B" in n]

optimizer = AdamW([
    {"params": lora_A_params, "lr": 1e-4},
    {"params": lora_B_params, "lr": 1e-3},  # B 矩陣的 LR 高出 10 倍
])
```

### rsLoRA (秩穩定化 LoRA)

縮放 LoRA 輸出以穩定不同秩下的訓練：

```python
lora_config = LoraConfig(
    r=64,
    lora_alpha=64,
    use_rslora=True,  # 啟用秩穩定化縮放
    target_modules="all-linear"
)
```

**何時使用**：
- 嘗試不同秩的值時
- 有助於在不同秩值之間保持一致的行為
- 建議在 r > 32 時使用

## LoftQ (量化感知 LoRA 微調)

初始化 LoRA 權重以補償量化誤差：

```python
from peft import LoftQConfig, LoraConfig, get_peft_model
from transformers import AutoModelForCausalLM, BitsAndBytesConfig

# LoftQ 配置
loftq_config = LoftQConfig(
    loftq_bits=4,              # 量化位元數
    loftq_iter=5,              # 交替優化迭代次數
)

# 使用 LoftQ 初始化的 LoRA 配置
lora_config = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules="all-linear",
    init_lora_weights="loftq",
    loftq_config=loftq_config,
    task_type="CAUSAL_LM"
)

# 載入量化模型
bnb_config = BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_quant_type="nf4")
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-3.1-8B",
    quantization_config=bnb_config
)

model = get_peft_model(model, lora_config)
```

**相較於標準 QLoRA 的優點**：
- 量化後的初始品質更好
- 收斂速度更快
- 在基準測試上的最終準確度提高約 1-2%

## 自訂模組目標設定 (Targeting)

### 目標特定層

```python
# 僅針對第一個與最後一個 Transformer 層
lora_config = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules=["model.layers.0.self_attn.q_proj",
                    "model.layers.0.self_attn.v_proj",
                    "model.layers.31.self_attn.q_proj",
                    "model.layers.31.self_attn.v_proj"],
    layers_to_transform=[0, 31]  # 替代方法
)
```

### 層模式比擬 (Pattern Matching)

```python
# 僅針對第 0-10 層
lora_config = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules="all-linear",
    layers_to_transform=list(range(11)),  # 第 0-10 層
    layers_pattern="model.layers"
)
```

### 排除特定層

```python
lora_config = LoraConfig(
    r=16,
    target_modules="all-linear",
    modules_to_save=["lm_head"],  # 完整訓練這些模組 (不使用 LoRA)
)
```

## 嵌入層 (Embedding) 與 LM Head 訓練

### 使用 LoRA 訓練嵌入層

```python
from peft import LoraConfig

# 包含嵌入層
lora_config = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules=["q_proj", "v_proj", "embed_tokens"],  # 包含嵌入層
    modules_to_save=["lm_head"],  # 完整訓練 lm_head
)
```

### 使用 LoRA 擴展詞彙表

```python
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import get_peft_model, LoraConfig

# 新增 Token
tokenizer = AutoTokenizer.from_pretrained("meta-llama/Llama-3.1-8B")
new_tokens = ["<custom_token_1>", "<custom_token_2>"]
tokenizer.add_tokens(new_tokens)

# 調整模型嵌入層大小
model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-3.1-8B")
model.resize_token_embeddings(len(tokenizer))

# 配置 LoRA 以訓練新的嵌入層
lora_config = LoraConfig(
    r=16,
    target_modules="all-linear",
    modules_to_save=["embed_tokens", "lm_head"],  # 完整訓練這些模組
)

model = get_peft_model(model, lora_config)
```

## 多適配器模式 (Multi-Adapter Patterns)

### 適配器組合 (Composition)

```python
from peft import PeftModel

# 載入具有多個適配器的模型
model = AutoPeftModelForCausalLM.from_pretrained("./base-adapter")
model.load_adapter("./style-adapter", adapter_name="style")
model.load_adapter("./task-adapter", adapter_name="task")

# 組合適配器 (加權總和)
model.add_weighted_adapter(
    adapters=["style", "task"],
    weights=[0.7, 0.3],
    adapter_name="combined",
    combination_type="linear"  # 或 "cat", "svd"
)

model.set_adapter("combined")
```

### 適配器堆疊 (Stacking)

```python
# 堆疊適配器 (依序套用)
model.add_weighted_adapter(
    adapters=["base", "domain", "task"],
    weights=[1.0, 1.0, 1.0],
    adapter_name="stacked",
    combination_type="cat"  # 串接適配器輸出
)
```

### 動態適配器切換

```python
import torch

class MultiAdapterModel:
    def __init__(self, base_model_path, adapter_paths):
        self.model = AutoPeftModelForCausalLM.from_pretrained(adapter_paths[0])
        for name, path in adapter_paths[1:].items():
            self.model.load_adapter(path, adapter_name=name)

    def generate(self, prompt, adapter_name="default"):
        self.model.set_adapter(adapter_name)
        return self.model.generate(**self.tokenize(prompt))

    def generate_ensemble(self, prompt, adapters, weights):
        """使用加權適配器集成 (Ensemble) 進行生成"""
        outputs = []
        for adapter, weight in zip(adapters, weights):
            self.model.set_adapter(adapter)
            logits = self.model(**self.tokenize(prompt)).logits
            outputs.append(weight * logits)
        return torch.stack(outputs).sum(dim=0)
```

## 記憶體優化

### 使用 LoRA 進行梯度檢查點 (Gradient Checkpointing)

```python
from peft import prepare_model_for_kbit_training

# 啟用梯度檢查點
model = prepare_model_for_kbit_training(
    model,
    use_gradient_checkpointing=True,
    gradient_checkpointing_kwargs={"use_reentrant": False}
)
```

### 訓練時的 CPU 卸載 (Offloading)

```python
from accelerate import Accelerator

accelerator = Accelerator(
    mixed_precision="bf16",
    gradient_accumulation_steps=8,
    cpu_offload=True  # 將優化器狀態卸載至 CPU
)

model, optimizer, dataloader = accelerator.prepare(model, optimizer, dataloader)
```

### 使用 LoRA 進行記憶體高效注意力機制 (Attention)

```python
from transformers import AutoModelForCausalLM

# 將 Flash Attention 2 與 LoRA 結合
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-3.1-8B",
    attn_implementation="flash_attention_2",
    torch_dtype=torch.bfloat16
)

# 套用 LoRA
model = get_peft_model(model, lora_config)
```

## 推論優化

### 為部署進行合併

```python
# 將適配器權重合併至基礎模型
merged_model = model.merge_and_unload()

# 為推論量化合併後的模型
from transformers import BitsAndBytesConfig

bnb_config = BitsAndBytesConfig(load_in_4bit=True)
quantized_model = AutoModelForCausalLM.from_pretrained(
    "./merged-model",
    quantization_config=bnb_config
)
```

### 匯出至不同格式

```python
# 匯出至 GGUF (llama.cpp)
# 先合併，再轉換
merged_model.save_pretrained("./merged-model")

# 使用 llama.cpp 轉換器
# python convert-hf-to-gguf.py ./merged-model --outfile model.gguf

# 匯出至 ONNX
from optimum.onnxruntime import ORTModelForCausalLM

ort_model = ORTModelForCausalLM.from_pretrained(
    "./merged-model",
    export=True
)
ort_model.save_pretrained("./onnx-model")
```

### 批次適配器推論 (Batch Adapter Inference)

```python
from vllm import LLM
from vllm.lora.request import LoRARequest

# 初始化並啟用 LoRA 支援
llm = LLM(
    model="meta-llama/Llama-3.1-8B",
    enable_lora=True,
    max_lora_rank=64,
    max_loras=4  # 最大同時並行適配器數量
)

# 使用不同適配器進行批次推論
requests = [
    ("prompt1", LoRARequest("adapter1", 1, "./adapter1")),
    ("prompt2", LoRARequest("adapter2", 2, "./adapter2")),
    ("prompt3", LoRARequest("adapter1", 1, "./adapter1")),
]

outputs = llm.generate(
    [r[0] for r in requests],
    lora_request=[r[1] for r in requests]
)
```

## 訓練配方 (Recipes)

### 指令微調配方

```python
lora_config = LoraConfig(
    r=16,
    lora_alpha=32,
    lora_dropout=0.05,
    target_modules="all-linear",
    bias="none",
    task_type="CAUSAL_LM"
)

training_args = TrainingArguments(
    output_dir="./output",
    num_train_epochs=3,
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    learning_rate=2e-4,
    lr_scheduler_type="cosine",
    warmup_ratio=0.03,
    bf16=True,
    logging_steps=10,
    save_strategy="steps",
    save_steps=100,
    eval_strategy="steps",
    eval_steps=100,
)
```

### 程式碼生成配方

```python
lora_config = LoraConfig(
    r=32,              # 程式碼任務使用較高的秩
    lora_alpha=64,
    lora_dropout=0.1,
    target_modules=["q_proj", "v_proj", "k_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
    bias="none",
    task_type="CAUSAL_LM"
)

training_args = TrainingArguments(
    learning_rate=1e-4,        # 程式碼任務使用較低的學習率
    num_train_epochs=2,
    max_seq_length=2048,       # 較長的序列長度
)
```

### 對話/聊天 (Chat) 配方

```python
from trl import SFTTrainer

lora_config = LoraConfig(
    r=16,
    lora_alpha=16,  # 聊天任務通常 alpha = r
    lora_dropout=0.05,
    target_modules="all-linear"
)

# 使用聊天範本 (Chat Template)
def format_chat(example):
    messages = [
        {"role": "user", "content": example["instruction"]},
        {"role": "assistant", "content": example["response"]}
    ]
    return tokenizer.apply_chat_template(messages, tokenize=False)

trainer = SFTTrainer(
    model=model,
    peft_config=lora_config,
    train_dataset=dataset.map(format_chat),
    max_seq_length=1024,
)
```

## 除錯與驗證

### 驗證適配器套用情況

```python
# 檢查哪些模組具有 LoRA
for name, module in model.named_modules():
    if hasattr(module, "lora_A"):
        print(f"LoRA 已套用於: {name}")

# 列印詳細配置
print(model.peft_config)

# 檢查適配器狀態
print(f"活動適配器: {model.active_adapters}")
print(f"可訓練參數總數: {sum(p.numel() for p in model.parameters() if p.requires_grad)}")
```

### 與基礎模型比較

```python
# 使用適配器生成
model.set_adapter("default")
adapter_output = model.generate(**inputs)

# 停用適配器生成
with model.disable_adapter():
    base_output = model.generate(**inputs)

print(f"適配器輸出: {tokenizer.decode(adapter_output[0])}")
print(f"基礎模型輸出: {tokenizer.decode(base_output[0])}")
```

### 監控訓練指標

```python
from transformers import TrainerCallback

class LoRACallback(TrainerCallback):
    def on_log(self, args, state, control, logs=None, **kwargs):
        if "loss" in logs:
            # 記錄適配器特定指標
            model = kwargs["model"]
            lora_params = sum(p.numel() for n, p in model.named_parameters()
                            if "lora" in n and p.requires_grad)
            print(f"步數 {state.global_step}: loss={logs['loss']:.4f}, lora_params={lora_params}")
```
