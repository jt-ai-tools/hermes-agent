---
name: evaluating-llms-harness
description: 在 60 多個學術基準測試（如 MMLU、HumanEval、GSM8K、TruthfulQA、HellaSwag）中評估大型語言模型 (LLM)。用於基準測試模型品質、比較模型、報告學術結果或追蹤訓練進度。這是 EleutherAI、HuggingFace 和主要實驗室使用的業界標準。支援 HuggingFace、vLLM 和 API。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [lm-eval, transformers, vllm]
metadata:
  hermes:
    tags: [Evaluation, LM Evaluation Harness, Benchmarking, MMLU, HumanEval, GSM8K, EleutherAI, Model Quality, Academic Benchmarks, Industry Standard, 評估, 基準測試]

---

# lm-evaluation-harness - LLM 基準測試

## 快速上手

lm-evaluation-harness 使用標準化的提示詞和指標，在 60 多個學術基準測試中評估 LLM。

**安裝**：
```bash
pip install lm-eval
```

**評估任何 HuggingFace 模型**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks mmlu,gsm8k,hellaswag \
  --device cuda:0 \
  --batch_size 8
```

**查看可用任務**：
```bash
lm_eval --tasks list
```

## 常見工作流

### 工作流 1：標準基準測試評估

在核心基準測試（MMLU、GSM8K、HumanEval）上評估模型。

複製此檢查清單：

```
基準測試評估：
- [ ] 步驟 1：選擇基準測試套件
- [ ] 步驟 2：配置模型
- [ ] 步驟 3：運行評估
- [ ] 步驟 4：分析結果
```

**步驟 1：選擇基準測試套件**

**核心推理基準測試**：
- **MMLU** (Massive Multitask Language Understanding) - 57 個學科，多選題
- **GSM8K** - 小學數學應用題
- **HellaSwag** - 常識推理
- **TruthfulQA** - 真實性和事實性
- **ARC** (AI2 Reasoning Challenge) - 科學問題

**代碼基準測試**：
- **HumanEval** - Python 代碼生成（164 個問題）
- **MBPP** (Mostly Basic Python Problems) - Python 編程

**標準套件**（建議用於模型發布）：
```bash
--tasks mmlu,gsm8k,hellaswag,truthfulqa,arc_challenge
```

**步驟 2：配置模型**

**HuggingFace 模型**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf,dtype=bfloat16 \
  --tasks mmlu \
  --device cuda:0 \
  --batch_size auto  # 自動檢測最佳批次大小
```

**量化模型 (4-bit/8-bit)**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf,load_in_4bit=True \
  --tasks mmlu \
  --device cuda:0
```

**自定義檢查點 (Checkpoint)**：
```bash
lm_eval --model hf \
  --model_args pretrained=/path/to/my-model,tokenizer=/path/to/tokenizer \
  --tasks mmlu \
  --device cuda:0
```

**步驟 3：運行評估**

```bash
# 完整 MMLU 評估（57 個學科）
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks mmlu \
  --num_fewshot 5 \  # 5-shot 評估（標準）
  --batch_size 8 \
  --output_path results/ \
  --log_samples  # 保存個別預測結果
```

**步驟 4：分析結果**

結果保存在 `results/llama2-7b-eval.json`：

```json
{
  "results": {
    "mmlu": {
      "acc": 0.459,
      "acc_stderr": 0.004
    },
    "gsm8k": {
      "exact_match": 0.142,
      "exact_match_stderr": 0.006
    },
    "hellaswag": {
      "acc_norm": 0.765,
      "acc_norm_stderr": 0.004
    }
  },
  "config": {
    "model": "hf",
    "model_args": "pretrained=meta-llama/Llama-2-7b-hf",
    "num_fewshot": 5
  }
}
```

### 工作流 2：追蹤訓練進度

在訓練期間評估檢查點。

```
訓練進度追蹤：
- [ ] 步驟 1：設置定期評估
- [ ] 步驟 2：選擇快速基準測試
- [ ] 步驟 3：自動化評估
- [ ] 步驟 4：繪製學習曲線
```

**步驟 1：設置定期評估**

每 N 個訓練步數評估一次：

```bash
#!/bin/bash
# eval_checkpoint.sh

CHECKPOINT_DIR=$1
STEP=$2

lm_eval --model hf \
  --model_args pretrained=$CHECKPOINT_DIR/checkpoint-$STEP \
  --tasks gsm8k,hellaswag \
  --num_fewshot 0 \  # 為了速度使用 0-shot
  --batch_size 16 \
  --output_path results/step-$STEP.json
```

**步驟 2：選擇快速基準測試**

適用於頻繁評估的快速基準測試：
- **HellaSwag**：在 1 個 GPU 上約 10 分鐘
- **GSM8K**：約 5 分鐘
- **PIQA**：約 2 分鐘

避免用於頻繁評估（太慢）：
- **MMLU**：約 2 小時（57 個學科）
- **HumanEval**：需要執行代碼

**步驟 3：自動化評估**

與訓練腳本整合：

```python
# 在訓練迴圈中
if step % eval_interval == 0:
    model.save_pretrained(f"checkpoints/step-{step}")

    # 執行評估
    os.system(f"./eval_checkpoint.sh checkpoints step-{step}")
```

或使用 PyTorch Lightning 回調 (Callbacks)：

```python
from pytorch_lightning import Callback

class EvalHarnessCallback(Callback):
    def on_validation_epoch_end(self, trainer, pl_module):
        step = trainer.global_step
        checkpoint_path = f"checkpoints/step-{step}"

        # 保存檢查點
        trainer.save_checkpoint(checkpoint_path)

        # 執行 lm-eval
        os.system(f"lm_eval --model hf --model_args pretrained={checkpoint_path} ...")
```

**步驟 4：繪製學習曲線**

```python
import json
import matplotlib.pyplot as plt

# 加載所有結果
steps = []
mmlu_scores = []

for file in sorted(glob.glob("results/step-*.json")):
    with open(file) as f:
        data = json.load(f)
        step = int(file.split("-")[1].split(".")[0])
        steps.append(step)
        mmlu_scores.append(data["results"]["mmlu"]["acc"])

# 繪圖
plt.plot(steps, mmlu_scores)
plt.xlabel("Training Step")
plt.ylabel("MMLU Accuracy")
plt.title("Training Progress")
plt.savefig("training_curve.png")
```

### 工作流 3：比較多個模型

用於模型比較的基準測試套件。

```
模型比較：
- [ ] 步驟 1：定義模型列表
- [ ] 步驟 2：執行評估
- [ ] 步驟 3：生成比較表
```

**步驟 1：定義模型列表**

```bash
# models.txt
meta-llama/Llama-2-7b-hf
meta-llama/Llama-2-13b-hf
mistralai/Mistral-7B-v0.1
microsoft/phi-2
```

**步驟 2：執行評估**

```bash
#!/bin/bash
# eval_all_models.sh

TASKS="mmlu,gsm8k,hellaswag,truthfulqa"

while read model; do
    echo "Evaluating $model"

    # 提取模型名稱用於輸出文件
    model_name=$(echo $model | sed 's/\//-/g')

    lm_eval --model hf \
      --model_args pretrained=$model,dtype=bfloat16 \
      --tasks $TASKS \
      --num_fewshot 5 \
      --batch_size auto \
      --output_path results/$model_name.json

done < models.txt
```

**步驟 3：生成比較表**

```python
import json
import pandas as pd

models = [
    "meta-llama-Llama-2-7b-hf",
    "meta-llama-Llama-2-13b-hf",
    "mistralai-Mistral-7B-v0.1",
    "microsoft-phi-2"
]

tasks = ["mmlu", "gsm8k", "hellaswag", "truthfulqa"]

results = []
for model in models:
    with open(f"results/{model}.json") as f:
        data = json.load(f)
        row = {"Model": model.replace("-", "/")}
        for task in tasks:
            # 獲取每個任務的主要指標
            metrics = data["results"][task]
            if "acc" in metrics:
                row[task.upper()] = f"{metrics['acc']:.3f}"
            elif "exact_match" in metrics:
                row[task.upper()] = f"{metrics['exact_match']:.3f}"
        results.append(row)

df = pd.DataFrame(results)
print(df.to_markdown(index=False))
```

輸出：
```
| Model                  | MMLU  | GSM8K | HELLASWAG | TRUTHFULQA |
|------------------------|-------|-------|-----------|------------|
| meta-llama/Llama-2-7b  | 0.459 | 0.142 | 0.765     | 0.391      |
| meta-llama/Llama-2-13b | 0.549 | 0.287 | 0.801     | 0.430      |
| mistralai/Mistral-7B   | 0.626 | 0.395 | 0.812     | 0.428      |
| microsoft/phi-2        | 0.560 | 0.613 | 0.682     | 0.447      |
```

### 工作流 4：使用 vLLM 評估（更快的推理）

使用 vLLM 後端，評估速度提高 5-10 倍。

```
vLLM 評估：
- [ ] 步驟 1：安裝 vLLM
- [ ] 步驟 2：配置 vLLM 後端
- [ ] 步驟 3：執行評估
```

**步驟 1：安裝 vLLM**

```bash
pip install vllm
```

**步驟 2：配置 vLLM 後端**

```bash
lm_eval --model vllm \
  --model_args pretrained=meta-llama/Llama-2-7b-hf,tensor_parallel_size=1,dtype=auto,gpu_memory_utilization=0.8 \
  --tasks mmlu \
  --batch_size auto
```

**步驟 3：執行評估**

vLLM 比標準 HuggingFace 快 5-10 倍：

```bash
# 標準 HF：在 7B 模型上評估 MMLU 約需 2 小時
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks mmlu \
  --batch_size 8

# vLLM：在 7B 模型上評估 MMLU 約需 15-20 分鐘
lm_eval --model vllm \
  --model_args pretrained=meta-llama/Llama-2-7b-hf,tensor_parallel_size=2 \
  --tasks mmlu \
  --batch_size auto
```

## 何時使用 vs 替代方案

**在以下情況使用 lm-evaluation-harness：**
- 為學術論文進行模型基準測試
- 在標準任務上比較模型品質
- 追蹤訓練進度
- 報告標準化指標（每個人都使用相同的提示詞）
- 需要可重複的評估

**改用替代方案：**
- **HELM** (Stanford)：更廣泛的評估（公平性、效率、校準）
- **AlpacaEval**：使用 LLM 評判的模型指令遵循評估
- **MT-Bench**：對話式多輪評估
- **自定義腳本**：領域特定評估

## 常見問題

**問題：評估太慢**

使用 vLLM 後端：
```bash
lm_eval --model vllm \
  --model_args pretrained=model-name,tensor_parallel_size=2
```

或減少 few-shot 範例：
```bash
--num_fewshot 0  # 而不是 5
```

或評估 MMLU 的子集：
```bash
--tasks mmlu_stem  # 僅 STEM 學科
```

**問題：記憶體不足 (OOM)**

減小批次大小：
```bash
--batch_size 1  # 或 --batch_size auto
```

使用量化：
```bash
--model_args pretrained=model-name,load_in_8bit=True
```

啟用 CPU 卸載 (Offloading)：
```bash
--model_args pretrained=model-name,device_map=auto,offload_folder=offload
```

**問題：結果與報告的不符**

檢查 few-shot 計數：
```bash
--num_fewshot 5  # 大多數論文使用 5-shot
```

檢查確切的任務名稱：
```bash
--tasks mmlu  # 不是 mmlu_direct 或 mmlu_fewshot
```

驗證模型和分詞器 (Tokenizer) 是否匹配：
```bash
--model_args pretrained=model-name,tokenizer=same-model-name
```

**問題：HumanEval 沒有執行代碼**

安裝執行依賴項：
```bash
pip install human-eval
```

啟用代碼執行：
```bash
lm_eval --model hf \
  --model_args pretrained=model-name \
  --tasks humaneval \
  --allow_code_execution  # HumanEval 所需
```

## 進階主題

**基準測試說明**：請參閱 [references/benchmark-guide.md](references/benchmark-guide_zh_TW.md) 以獲取所有 60 多個任務的詳細說明、測量內容和解讀方式。

**自定義任務**：請參閱 [references/custom-tasks.md](references/custom-tasks_zh_TW.md) 以了解如何創建領域特定的評估任務。

**API 評估**：請參閱 [references/api-evaluation.md](references/api-evaluation_zh_TW.md) 以了解如何評估 OpenAI、Anthropic 和其他 API 模型。

**多 GPU 策略**：請參閱 [references/distributed-eval.md](references/distributed-eval.md) 以獲取數據並行和張量並行評估。

## 硬體要求

- **GPU**：NVIDIA (CUDA 11.8+)，可在 CPU 上運行（非常慢）
- **VRAM**：
  - 7B 模型：16GB (bf16) 或 8GB (8-bit)
  - 13B 模型：28GB (bf16) 或 14GB (8-bit)
  - 70B 模型：需要多 GPU 或量化
- **時間**（7B 模型，單個 A100）：
  - HellaSwag：10 分鐘
  - GSM8K：5 分鐘
  - MMLU (完整)：2 小時
  - HumanEval：20 分鐘

## 資源

- GitHub: https://github.com/EleutherAI/lm-evaluation-harness
- 文檔: https://github.com/EleutherAI/lm-evaluation-harness/tree/main/docs
- 任務庫：60 多個任務，包括 MMLU、GSM8K、HumanEval、TruthfulQA、HellaSwag、ARC、WinoGrande 等。
- 排行榜: https://huggingface.co/spaces/HuggingFaceH4/open_llm_leaderboard (使用此套件)
