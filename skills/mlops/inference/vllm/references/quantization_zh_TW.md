# 量化指南 (Quantization Guide)

## 目錄
- 量化方法比較
- AWQ 設定與使用
- GPTQ 設定與使用
- FP8 量化 (H100)
- 模型準備
- 準確度與壓縮率的折衷

## 量化方法比較

| 方法 | 壓縮率 | 準確度損失 | 速度 | 最適合 |
|--------|-------------|---------------|-------|----------|
| **AWQ** | 4-bit (75%) | <1% | 快 | 70B 模型、生產環境 |
| **GPTQ** | 4-bit (75%) | 1-2% | 快 | 廣泛的模型支援 |
| **FP8** | 8-bit (50%) | <0.5% | 最快 | 僅限 H100 GPU |
| **SqueezeLLM** | 3-4 bit (75-80%) | 2-3% | 中 | 極致壓縮 |

**建議**：
- **生產環境**：針對 70B 模型使用 AWQ
- **H100 GPU**：使用 FP8 以獲得最佳速度
- **最大相容性**：使用 GPTQ
- **極致壓縮**：使用 SqueezeLLM

## AWQ 設定與使用

**AWQ** (Activation-aware Weight Quantization) 在 4-bit 下可達到最佳準確度。

**步驟 1：尋找預先量化的模型**

在 HuggingFace 搜尋 AWQ 模型：
```bash
# 範例：TheBloke/Llama-2-70B-AWQ
# 範例：TheBloke/Mixtral-8x7B-Instruct-v0.1-AWQ
```

**步驟 2：使用 AWQ 啟動**

```bash
vllm serve TheBloke/Llama-2-70B-AWQ \
  --quantization awq \
  --tensor-parallel-size 1 \
  --gpu-memory-utilization 0.95
```

**節省記憶體**：
```
Llama 2 70B fp16: 需要 140GB VRAM (需 4x A100)
Llama 2 70B AWQ: 35GB VRAM (1x A100 40GB)
= 記憶體佔用減少 4 倍
```

**步驟 3：驗證效能**

測試輸出是否符合預期：
```python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8000/v1", api_key="EMPTY")

# 測試複雜推理
response = client.chat.completions.create(
    model="TheBloke/Llama-2-70B-AWQ",
    messages=[{"role": "user", "content": "Explain quantum entanglement"}]
)

print(response.choices[0].message.content)
# 驗證品質是否符合您的需求
```

**自行量化模型** (需要 80GB+ VRAM 的 GPU)：

```python
from awq import AutoAWQForCausalLM
from transformers import AutoTokenizer

model_path = "meta-llama/Llama-2-70b-hf"
quant_path = "llama-2-70b-awq"

# 載入模型
model = AutoAWQForCausalLM.from_pretrained(model_path)
tokenizer = AutoTokenizer.from_pretrained(model_path)

# 量化
quant_config = {"zero_point": True, "q_group_size": 128, "w_bit": 4}
model.quantize(tokenizer, quant_config=quant_config)

# 儲存
model.save_quantized(quant_path)
tokenizer.save_pretrained(quant_path)
```

## GPTQ 設定與使用

**GPTQ** 擁有最廣泛的模型支援與良好的壓縮效果。

**步驟 1：尋找 GPTQ 模型**

```bash
# 範例：TheBloke/Llama-2-13B-GPTQ
# 範例：TheBloke/CodeLlama-34B-GPTQ
```

**步驟 2：使用 GPTQ 啟動**

```bash
vllm serve TheBloke/Llama-2-13B-GPTQ \
  --quantization gptq \
  --dtype float16
```

**GPTQ 配置選項**：
```bash
# 若有需要，指定 GPTQ 參數
vllm serve MODEL \
  --quantization gptq \
  --gptq-act-order \  # 啟動順序 (Activation ordering)
  --dtype float16
```

**自行量化模型**：

```python
from auto_gptq import AutoGPTQForCausalLM, BaseQuantizeConfig
from transformers import AutoTokenizer

model_name = "meta-llama/Llama-2-13b-hf"
quantized_name = "llama-2-13b-gptq"

# 載入模型
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoGPTQForCausalLM.from_pretrained(model_name, quantize_config)

# 準備校準資料 (Calibration data)
calib_data = [...]  # 範例文字列表

# 量化
quantize_config = BaseQuantizeConfig(
    bits=4,
    group_size=128,
    desc_act=True
)
model.quantize(calib_data)

# 儲存
model.save_quantized(quantized_name)
```

## FP8 量化 (H100)

**FP8** (8-bit floating point) 在 H100 GPU 上提供最快速度，且準確度損失極小。

**需求**：
- H100 或 H800 GPU
- CUDA 12.3+ (建議 12.8)
- Hopper 架構支援

**步驟 1：啟用 FP8**

```bash
vllm serve meta-llama/Llama-3-70B-Instruct \
  --quantization fp8 \
  --tensor-parallel-size 2
```

**H100 上的效能提升**：
```
fp16: 180 tokens/sec
FP8: 320 tokens/sec
= 1.8 倍加速
```

**步驟 2：驗證準確度**

FP8 的準確度下降通常 <0.5%：
```python
# 執行評估套件
# 針對您的任務比較 FP8 與 FP16
# 驗證準確度是否可接受
```

**動態 FP8 量化** (無需預先量化模型)：

```bash
# vLLM 會在執行時自動量化
vllm serve MODEL --quantization fp8
# 無需準備模型
```

## 模型準備

**預先量化的模型 (最簡單)**：

1. 在 HuggingFace 搜尋：`[model name] AWQ` 或 `[model name] GPTQ`
2. 下載或直接使用：`TheBloke/[Model]-AWQ`
3. 使用適當的 `--quantization` 標記啟動

**自行量化模型**：

**AWQ**：
```bash
# 安裝 AutoAWQ
pip install autoawq

# 執行量化腳本
python quantize_awq.py --model MODEL --output OUTPUT
```

**GPTQ**：
```bash
# 安裝 AutoGPTQ
pip install auto-gptq

# 執行量化腳本
python quantize_gptq.py --model MODEL --output OUTPUT
```

**校準資料 (Calibration data)**：
- 使用 128-512 個來自目標領域的多樣化範例
- 應具備生產環境輸入的代表性
- 校準品質愈高 = 準確度愈好

## 準確度與壓縮率的折衷

**實驗結果** (Llama 2 70B 於 MMLU 基準測試)：

| 量化方式 | 準確度 | 記憶體 | 速度 | 可用於生產環境 |
|--------------|----------|--------|-------|------------------|
| FP16 (基準) | 100% | 140GB | 1.0x | ✅ (若記憶體足夠) |
| FP8 | 99.5% | 70GB | 1.8x | ✅ (僅限 H100) |
| AWQ 4-bit | 99.0% | 35GB | 1.5x | ✅ (最適合 70B) |
| GPTQ 4-bit | 98.5% | 35GB | 1.5x | ✅ (相容性佳) |
| SqueezeLLM 3-bit | 96.0% | 26GB | 1.3x | ⚠️ (需檢查準確度) |

**何時該使用哪種方式**：

**不進行量化 (FP16)**：
- GPU 記憶體充足
- 需要絕對最佳的準確度
- 模型小於 13B 參數

**FP8**：
- 使用 H100/H800 GPU
- 需要最快速度且準確度損失極小
- 生產環境部署

**AWQ 4-bit**：
- 需要在 40GB GPU 中裝載 70B 模型
- 生產環境部署
- 可接受 <1% 的準確度損失

**GPTQ 4-bit**：
- 需要廣泛的模型支援
- 非 H100 環境 (若在 H100 則建議使用 FP8)
- 可接受 1-2% 的準確度損失

**測試策略**：

1. **基準線 (Baseline)**：在您的評估集上測量 FP16 的準確度
2. **量化**：建立量化版本
3. **評估**：在相同任務上比較量化版本與基準線
4. **決策**：若準確度下降低於門檻 (通常為 1-2%) 則採用

**評估範例**：
```python
from evaluate import load_evaluation_suite

# 在 FP16 基準線上執行
baseline_score = evaluate(model_fp16, eval_suite)

# 在量化版本上執行
quant_score = evaluate(model_awq, eval_suite)

# 比較
degradation = (baseline_score - quant_score) / baseline_score * 100
print(f"準確度下降：{degradation:.2f}%")

# 決策
if degradation < 1.0:
    print("✅ 量化結果可用於生產環境")
else:
    print("⚠️ 請檢視準確度損失")
```
