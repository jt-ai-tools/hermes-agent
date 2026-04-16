---
name: simpo-training
description: 用於 LLM 對齊的簡單偏好優化 (Simple Preference Optimization)。DPO 的無參考模型替代方案，性能更佳（在 AlpacaEval 2.0 上提升了 6.4 分）。無需參考模型，比 DPO 更高效。當需要比 DPO/PPO 更簡單、更快速的訓練時，用於偏好對齊。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [torch, transformers, datasets, trl, accelerate]
metadata:
  hermes:
    tags: [Post-Training, SimPO, Preference Optimization, Alignment, DPO Alternative, Reference-Free, LLM Alignment, Efficient Training]

---

# SimPO - 簡單偏好優化

## 快速開始

SimPO 是一種無參考模型 (Reference-free) 的偏好優化方法，其表現優於 DPO，且無需參考模型。

**安裝**：
```bash
# 建立環境
conda create -n simpo python=3.10 && conda activate simpo

# 安裝 PyTorch 2.2.2
# 請訪問：https://pytorch.org/get-started/locally/

# 安裝 alignment-handbook
git clone https://github.com/huggingface/alignment-handbook.git
cd alignment-handbook
python -m pip install .

# 安裝 Flash Attention 2
python -m pip install flash-attn --no-build-isolation
```

**訓練** (Mistral 7B)：
```bash
ACCELERATE_LOG_LEVEL=info accelerate launch \
  --config_file accelerate_configs/deepspeed_zero3.yaml \
  scripts/run_simpo.py \
  training_configs/mistral-7b-base-simpo.yaml
```

## 常見工作流

### 工作流 1：從基礎模型訓練 (Mistral 7B)

**配置** (`mistral-7b-base-simpo.yaml`)：
```yaml
# 模型
model_name_or_path: mistralai/Mistral-7B-v0.1
torch_dtype: bfloat16

# 資料集
dataset_mixer:
  HuggingFaceH4/ultrafeedback_binarized: 1.0
dataset_splits:
  - train_prefs
  - test_prefs

# SimPO 超參數
beta: 2.0                  # 獎勵縮放 (2.0-10.0)
gamma_beta_ratio: 0.5       # 目標邊際 (Target margin) (0-1)
loss_type: sigmoid          # sigmoid 或 hinge
sft_weight: 0.0             # 可選的 SFT 正則化

# 訓練
learning_rate: 5e-7         # 關鍵：3e-7 到 1e-6
num_train_epochs: 1
per_device_train_batch_size: 1
gradient_accumulation_steps: 8

# 輸出
output_dir: ./outputs/mistral-7b-simpo
```

**啟動訓練**：
```bash
accelerate launch --config_file accelerate_configs/deepspeed_zero3.yaml \
  scripts/run_simpo.py training_configs/mistral-7b-base-simpo.yaml
```

### 工作流 2：微調指令模型 (Llama 3 8B)

**配置** (`llama3-8b-instruct-simpo.yaml`)：
```yaml
model_name_or_path: meta-llama/Meta-Llama-3-8B-Instruct

dataset_mixer:
  argilla/ultrafeedback-binarized-preferences-cleaned: 1.0

beta: 2.5
gamma_beta_ratio: 0.5
learning_rate: 5e-7
sft_weight: 0.1             # 加入 SFT 損失以保留能力

num_train_epochs: 1
per_device_train_batch_size: 2
gradient_accumulation_steps: 4
output_dir: ./outputs/llama3-8b-simpo
```

**啟動**：
```bash
accelerate launch --config_file accelerate_configs/deepspeed_zero3.yaml \
  scripts/run_simpo.py training_configs/llama3-8b-instruct-simpo.yaml
```

### 工作流 3：推理密集型任務（較低學習率）

**針對數學/程式碼任務**：
```yaml
model_name_or_path: deepseek-ai/deepseek-math-7b-base

dataset_mixer:
  argilla/distilabel-math-preference-dpo: 1.0

beta: 5.0                   # 較高值以獲得更強訊號
gamma_beta_ratio: 0.7       # 較大邊際
learning_rate: 3e-7         # 推理任務使用較低學習率
sft_weight: 0.0

num_train_epochs: 1
per_device_train_batch_size: 1
gradient_accumulation_steps: 16
```

## 何時使用 vs 替代方案

**在以下情況使用 SimPO**：
- 想要比 DPO 更簡單的訓練（無需參考模型）。
- 擁有偏好數據（選擇/拒絕配對）。
- 需要比 DPO 更好的性能。
- 計算資源有限。
- 單節點訓練已足夠。

**演算法選擇**：
- **SimPO**：最簡單，性能最佳，無需參考模型。
- **DPO**：需要參考模型基準，較為保守。
- **PPO**：最大化控制，需要獎勵模型，設置複雜。
- **GRPO**：記憶體效率高的強化學習 (RL)，無需 Critic。

**在以下情況改用替代方案**：
- **OpenRLHF**：多節點分佈式訓練，PPO/GRPO。
- **TRL**：需要在單一框架中使用多種方法。
- **DPO**：既有的基準比較。

## 常見問題

**問題：損失發散 (Loss divergence)**

降低學習率：
```yaml
learning_rate: 3e-7  # 從 5e-7 調低
```

降低 beta：
```yaml
beta: 1.0  # 從 2.0 調低
```

**問題：模型遺忘能力**

加入 SFT 正則化：
```yaml
sft_weight: 0.1  # 加入 SFT 損失組成部分
```

**問題：偏好分離效果差**

增加 beta 和邊際：
```yaml
beta: 5.0            # 從 2.0 調高
gamma_beta_ratio: 0.8  # 從 0.5 調高
```

**問題：訓練期間 OOM (記憶體不足)**

縮小批次大小：
```yaml
per_device_train_batch_size: 1
gradient_accumulation_steps: 16  # 維持有效批次大小
```

啟用梯度檢查點 (Gradient checkpointing)：
```yaml
gradient_checkpointing: true
```

## 進階主題

**損失函數**：參見 [references/loss-functions.md](references/loss-functions.md) 以了解 sigmoid vs hinge 損失、數學公式以及各自的適用情境。

**超參數調優**：參見 [references/hyperparameters.md](references/hyperparameters.md) 以獲取 beta、gamma、學習率選擇指南，以及針對模型大小的建議。

**資料集準備**：參見 [references/datasets.md](references/datasets.md) 以了解偏好數據格式、品質過濾和自定義資料集建立。

## 硬體要求

- **GPU**：推薦使用 NVIDIA A100/H100。
- **VRAM (顯示記憶體)**：
  - 7B 模型：1× A100 40GB (DeepSpeed ZeRO-3)
  - 8B 模型：2× A100 40GB
  - 70B 模型：8× A100 80GB
- **單節點**：DeepSpeed ZeRO-3 已足夠。
- **混合精度**：推薦使用 BF16。

**記憶體優化**：
- DeepSpeed ZeRO-3 (預設配置)
- 梯度檢查點
- Flash Attention 2

## 相關資源

- 論文：https://arxiv.org/abs/2405.14734 (NeurIPS 2024)
- GitHub：https://github.com/princeton-nlp/SimPO
- 模型：https://huggingface.co/princeton-nlp
- Alignment Handbook：https://github.com/huggingface/alignment-handbook
