# PEFT 疑難排解指南

## 安裝問題

### bitsandbytes CUDA 錯誤

**錯誤訊息**：`CUDA Setup failed despite GPU being available`

**解決方案**：
```bash
# 檢查 CUDA 版本
nvcc --version

# 安裝對應的 bitsandbytes
pip uninstall bitsandbytes
pip install bitsandbytes --no-cache-dir

# 或針對特定 CUDA 版本從原始碼編譯
git clone https://github.com/TimDettmers/bitsandbytes.git
cd bitsandbytes
CUDA_VERSION=118 make cuda11x  # 依據您的 CUDA 版本進行調整
pip install .
```

### Triton 匯入錯誤

**錯誤訊息**：`ModuleNotFoundError: No module named 'triton'`

**解決方案**：
```bash
# 安裝 triton (僅限 Linux)
pip install triton

# Windows：不支援 Triton，請使用 CUDA 後端
# 設定環境變數以停用 triton
export CUDA_VISIBLE_DEVICES=0
```

### PEFT 版本衝突

**錯誤訊息**：`AttributeError: 'LoraConfig' object has no attribute 'use_dora'`

**解決方案**：
```bash
# 升級至最新版本的 PEFT
pip install peft>=0.13.0 --upgrade

# 檢查版本
python -c "import peft; print(peft.__version__)"
```

## 訓練問題

### CUDA 記憶體不足 (OOM)

**錯誤訊息**：`torch.cuda.OutOfMemoryError: CUDA out of memory`

**解決方案**：

1. **啟用梯度檢查點 (Gradient Checkpointing)**：
```python
from peft import prepare_model_for_kbit_training
model = prepare_model_for_kbit_training(model, use_gradient_checkpointing=True)
```

2. **減小批次大小 (Batch Size)**：
```python
TrainingArguments(
    per_device_train_batch_size=1,
    gradient_accumulation_steps=16  # 增加累積步數以維持有效的 Batch Size
)
```

3. **使用 QLoRA**：
```python
from transformers import BitsAndBytesConfig

bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_use_double_quant=True
)
model = AutoModelForCausalLM.from_pretrained(model_name, quantization_config=bnb_config)
```

4. **降低 LoRA 秩 (Rank)**：
```python
LoraConfig(r=8)  # 取代原本的 r=16 或更高
```

5. **減少目標模組 (Target Modules)**：
```python
target_modules=["q_proj", "v_proj"]  # 取代 all-linear
```

### 損失值 (Loss) 未下降

**問題描述**：訓練 Loss 停滯不前或不降反升。

**解決方案**：

1. **檢查學習率 (Learning Rate)**：
```python
# 從較低的值開始嘗試
TrainingArguments(learning_rate=1e-4)  # 而非 2e-4 或更高
```

2. **驗證適配器是否處於活動狀態**：
```python
model.print_trainable_parameters()
# 應顯示 >0 的可訓練參數

# 檢查適配器是否已套用
print(model.peft_config)
```

3. **檢查資料格式化情況**：
```python
# 驗證分詞 (Tokenization) 結果
sample = dataset[0]
decoded = tokenizer.decode(sample["input_ids"])
print(decoded)  # 內容應看起來正確
```

4. **增加秩 (Rank)**：
```python
LoraConfig(r=32, lora_alpha=64)  # 增加模型容量
```

### 損失值為 NaN (NaN Loss)

**錯誤訊息**：`Loss is NaN`

**解決方案**：
```python
# 使用 bf16 而非 fp16
TrainingArguments(bf16=True, fp16=False)

# 或啟用損失縮放 (Loss Scaling)
TrainingArguments(fp16=True, fp16_full_eval=True)

# 降低學習率
TrainingArguments(learning_rate=5e-5)

# 檢查資料是否有問題
for batch in dataloader:
    if torch.isnan(batch["input_ids"].float()).any():
        print("輸入中存在 NaN！")
```

### 適配器未進行訓練

**問題描述**：`trainable params: 0` 或模型未更新。

**解決方案**：
```python
# 驗證 LoRA 是否已套用於正確的模組
for name, module in model.named_modules():
    if "lora" in name.lower():
        print(f"找到 LoRA：{name}")

# 檢查 target_modules 是否匹配模型架構
from peft.utils import TRANSFORMERS_MODELS_TO_LORA_TARGET_MODULES_MAPPING
print(TRANSFORMERS_MODELS_TO_LORA_TARGET_MODULES_MAPPING.get(model.config.model_type))

# 確保模型處於訓練模式
model.train()

# 檢查 requires_grad 狀態
for name, param in model.named_parameters():
    if param.requires_grad:
        print(f"可訓練：{name}")
```

## 載入問題

### 適配器載入失敗

**錯誤訊息**：`ValueError: Can't find adapter weights`

**解決方案**：
```python
# 檢查適配器檔案是否存在
import os
print(os.listdir("./adapter-path"))
# 應包含：adapter_config.json, adapter_model.safetensors

# 以正確的結構載入
from peft import PeftModel, PeftConfig

# 檢查配置
config = PeftConfig.from_pretrained("./adapter-path")
print(config)

# 務必先載入基礎模型
base_model = AutoModelForCausalLM.from_pretrained(config.base_model_name_or_path)
model = PeftModel.from_pretrained(base_model, "./adapter-path")
```

### 基礎模型不匹配

**錯誤訊息**：`RuntimeError: size mismatch`

**解決方案**：
```python
# 確保基礎模型與適配器匹配
from peft import PeftConfig

config = PeftConfig.from_pretrained("./adapter-path")
print(f"基礎模型：{config.base_model_name_or_path}")

# 載入完全相同的基礎模型
base_model = AutoModelForCausalLM.from_pretrained(config.base_model_name_or_path)
```

### Safetensors 與 PyTorch 格式問題

**錯誤訊息**：`ValueError: We couldn't connect to 'https://huggingface.co'`

**解決方案**：
```python
# 強制從本地載入
model = PeftModel.from_pretrained(
    base_model,
    "./adapter-path",
    local_files_only=True
)

# 或指定儲存格式
model.save_pretrained("./adapter", safe_serialization=True)  # 使用 safetensors
model.save_pretrained("./adapter", safe_serialization=False)  # 使用 pytorch
```

## 推論問題

### 生成速度緩慢

**問題描述**：推論速度遠慢於預期。

**解決方案**：

1. **為部署合併適配器**：
```python
merged_model = model.merge_and_unload()
# 合併後在推論時將不具備適配器開銷
```

2. **使用優化過的推論引擎**：
```python
from vllm import LLM
llm = LLM(model="./merged-model", dtype="half")
```

3. **啟用 Flash Attention**：
```python
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    attn_implementation="flash_attention_2"
)
```

### 輸出品質問題

**問題描述**：微調後的模型產生較差的輸出。

**解決方案**：

1. **測試不使用適配器的評估結果**：
```python
with model.disable_adapter():
    base_output = model.generate(**inputs)
# 與適配器輸出進行比較
```

2. **評估時降低溫度 (Temperature)**：
```python
model.generate(**inputs, temperature=0.1, do_sample=False)
```

3. **使用更多資料重新訓練**：
```python
# 增加訓練樣本
# 使用更高品質的資料
# 增加訓練 Epoch 數
```

### 適配器啟用錯誤

**問題描述**：模型使用了錯誤的適配器或未開啟任何適配器。

**解決方案**：
```python
# 檢查目前活動中的適配器
print(model.active_adapters)

# 明確設定適配器
model.set_adapter("your-adapter-name")

# 列出所有可用的適配器
print(model.peft_config.keys())
```

## QLoRA 特定問題

### 量化錯誤

**錯誤訊息**：`RuntimeError: mat1 and mat2 shapes cannot be multiplied`

**解決方案**：
```python
# 確保計算資料類型 (Compute Dtype) 匹配
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_compute_dtype=torch.bfloat16,  # 匹配模型資料類型
    bnb_4bit_quant_type="nf4"
)

# 使用正確的資料類型載入
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    quantization_config=bnb_config,
    torch_dtype=torch.bfloat16
)
```

### QLoRA 記憶體不足 (OOM)

**錯誤訊息**：即使使用了 4-bit 量化仍然出現 OOM。

**解決方案**：
```python
# 啟用雙重量化 (Double Quantization)
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_use_double_quant=True  # 進一步減少記憶體使用量
)

# 使用卸載 (Offloading) 技術
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    quantization_config=bnb_config,
    device_map="auto",
    max_memory={0: "20GB", "cpu": "100GB"}
)
```

### QLoRA 合併失敗

**錯誤訊息**：`RuntimeError: expected scalar type BFloat16 but found Float`

**解決方案**：
```python
# 合併前先進行反量化 (Dequantize)
from peft import PeftModel

# 以較高精度載入基礎模型以進行合併
base_model = AutoModelForCausalLM.from_pretrained(
    base_model_name,
    torch_dtype=torch.float16,  # 不進行量化
    device_map="auto"
)

# 載入適配器
model = PeftModel.from_pretrained(base_model, "./qlora-adapter")

# 進行合併
merged = model.merge_and_unload()
```

## 多適配器 (Multi-Adapter) 問題

### 適配器衝突

**錯誤訊息**：`ValueError: Adapter with name 'default' already exists`

**解決方案**：
```python
# 使用唯一的名稱
model.load_adapter("./adapter1", adapter_name="task1")
model.load_adapter("./adapter2", adapter_name="task2")

# 或刪除現有的適配器
model.delete_adapter("default")
```

### 混合精度適配器

**錯誤訊息**：適配器使用了不同的資料類型進行訓練。

**解決方案**：
```python
# 轉換適配器精度
model = PeftModel.from_pretrained(base_model, "./adapter")
model = model.to(torch.bfloat16)

# 或以特定資料類型載入
model = PeftModel.from_pretrained(
    base_model,
    "./adapter",
    torch_dtype=torch.bfloat16
)
```

## 效能優化

### 記憶體分析 (Memory Profiling)

```python
import torch

def print_memory():
    if torch.cuda.is_available():
        allocated = torch.cuda.memory_allocated() / 1e9
        reserved = torch.cuda.memory_reserved() / 1e9
        print(f"Allocated: {allocated:.2f}GB, Reserved: {reserved:.2f}GB")

# 訓練期間進行分析
print_memory()  # 訓練前
model.train()
loss = model(**batch).loss
loss.backward()
print_memory()  # 訓練後
```

### 速度分析 (Speed Profiling)

```python
import time
import torch

def benchmark_generation(model, tokenizer, prompt, n_runs=5):
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)

    # 暖身 (Warmup)
    model.generate(**inputs, max_new_tokens=10)
    torch.cuda.synchronize()

    # 基準測試 (Benchmark)
    times = []
    for _ in range(n_runs):
        start = time.perf_counter()
        outputs = model.generate(**inputs, max_new_tokens=100)
        torch.cuda.synchronize()
        times.append(time.perf_counter() - start)

    tokens = outputs.shape[1] - inputs.input_ids.shape[1]
    avg_time = sum(times) / len(times)
    print(f"速度：{tokens/avg_time:.2f} tokens/sec")

# 比較適配器與合併後模型的效能
benchmark_generation(adapter_model, tokenizer, "Hello")
benchmark_generation(merged_model, tokenizer, "Hello")
```

## 獲取協助

1. **查看 PEFT GitHub Issues**：https://github.com/huggingface/peft/issues
2. **HuggingFace 論壇**：https://discuss.huggingface.co/
3. **PEFT 文件**：https://huggingface.co/docs/peft

### 除錯資訊範本

報告問題時，請附上以下資訊：

```python
# 系統資訊
import peft
import transformers
import torch

print(f"PEFT: {peft.__version__}")
print(f"Transformers: {transformers.__version__}")
print(f"PyTorch: {torch.__version__}")
print(f"CUDA: {torch.version.cuda}")
print(f"GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'N/A'}")

# 配置資訊
print(model.peft_config)
model.print_trainable_parameters()
```
