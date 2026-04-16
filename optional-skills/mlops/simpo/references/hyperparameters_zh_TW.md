# 超參數

關於 SimPO 超參數選擇與微調的完整指南。

## 概覽

SimPO 中的關鍵超參數：
1. **學習率 (Learning Rate)** - 最為關鍵
2. **Beta (β)** - 獎勵縮放
3. **Gamma-Beta 比例 (γ/β)** - 目標邊際 (Target margin)
4. **SFT 權重** - 正則化強度

## 學習率 (Learning Rate)

### 推薦範圍

**依模型大小劃分**：
| 模型大小 | 學習率 | 備註 |
|------------|---------------|-------|
| 1B-3B | 5e-7 到 1e-6 | 較高範圍是安全的 |
| 7B-8B | 3e-7 到 5e-7 | **標準** |
| 13B-30B | 1e-7 到 3e-7 | 較低以維持穩定性 |
| 70B+ | 5e-8 到 1e-7 | 非常保守 |

**依任務類型劃分**：
| 任務 | 學習率 | 原因 |
|------|---------------|--------|
| 一般對話 | 5e-7 | 標準 |
| 程式碼生成 | 3e-7 | **精確推理** |
| 數學推理 | 3e-7 | **謹慎最佳化** |
| 創意寫作 | 1e-6 | 較激進也沒問題 |

### 為什麼學習率很重要

**太高** (對於 7B 模型 > 1e-6)：
- 損失 (Loss) 發散
- 災難性遺忘
- 訓練不穩定

**太低** (對於 7B 模型 < 1e-7)：
- 收斂非常緩慢
- 可能無法及時完成
- 訓練不足

**最佳** (對於 7B 模型在 3e-7 到 5e-7 之間)：
- 穩定收斂
- 良好的最終效能
- 高效訓練

### 設定範例

**Mistral 7B (一般)**：
```yaml
learning_rate: 5e-7
num_train_epochs: 1
warmup_ratio: 0.1
lr_scheduler_type: cosine
```

**Llama 3 8B (推理)**：
```yaml
learning_rate: 3e-7
num_train_epochs: 1
warmup_ratio: 0.1
lr_scheduler_type: cosine
```

**Gemma 2 9B (創意)**：
```yaml
learning_rate: 1e-6
num_train_epochs: 1
warmup_ratio: 0.1
lr_scheduler_type: linear
```

## Beta (β)

### 推薦值

**範圍**：2.0 到 10.0 (遠高於 DPO 的 0.01-0.1)

**依偏好強度劃分**：
| Beta | 偏好強度 | 使用場景 |
|------|-------------------|----------|
| 1.0-2.0 | 弱 | 微妙的偏好 |
| 2.0-5.0 | **標準** | 一般對齊 |
| 5.0-10.0 | 強 | 明顯的偏好 |

**預設值**：2.0 到 2.5

### 為什麼 Beta 很重要

**低 beta** (< 2.0)：
- 弱獎勵訊號
- 偏好學習緩慢
- 可能欠擬合 (Underfit)

**高 beta** (> 10.0)：
- 非常強的獎勵訊號
- 有過擬合 (Overfitting) 的風險
- 可能忽略弱偏好

**最佳** (2.0-5.0)：
- 平衡的獎勵縮放
- 穩定訓練
- 良好的泛化能力

### 與 Gamma 的互動

**Beta 與 Gamma 結合使用**：
```
獎勵空間中的目標邊際 = gamma
Logit 空間中的目標邊際 = gamma / beta
```

**範例**：
```yaml
beta: 2.0
gamma_beta_ratio: 0.5
# 有效 gamma = 2.0 * 0.5 = 1.0
```

### 設定範例

**弱偏好**：
```yaml
beta: 2.0
gamma_beta_ratio: 0.3  # 較小的邊際
```

**標準**：
```yaml
beta: 2.5
gamma_beta_ratio: 0.5  # 預設值
```

**強偏好**：
```yaml
beta: 5.0
gamma_beta_ratio: 0.7  # 較大的邊際
```

## Gamma-Beta 比例 (γ/β)

### 推薦值

**範圍**：0.0 到 1.0

**依情境劃分**：
| 比例 | 邊際 | 使用場景 |
|-------|--------|----------|
| 0.0-0.3 | 小 | 弱偏好資料 |
| 0.4-0.6 | **標準** | 一般用途 |
| 0.7-1.0 | 大 | 非常清晰的偏好 |

**預設值**：0.5

### 為什麼 Gamma 很重要

**低 gamma** (< 0.3)：
- 較小的目標邊際
- 較不激進的對齊
- 較為保守

**高 gamma** (> 0.7)：
- 較大的目標邊際
- 較強的對齊
- 較為激進

**最佳** (0.4-0.6)：
- 平衡的邊際
- 穩定訓練
- 良好的對齊效果

### 數學意義

**在損失函數中**：
```python
logits = pi_logratios - gamma_beta_ratio
loss = -log(sigmoid(beta * logits))
```

**解讀**：
- gamma_beta_ratio 會移動決策邊界 (Decision boundary)
- 較高的比例 = 需要較大的對數機率差
- 控制偏好必須有多「清晰」

### 設定範例

**有雜訊的偏好**：
```yaml
gamma_beta_ratio: 0.3  # 較小的邊際，較寬容
```

**標準**：
```yaml
gamma_beta_ratio: 0.5  # 預設值
```

**高質量偏好**：
```yaml
gamma_beta_ratio: 0.8  # 較大的邊際，較嚴格
```

## SFT 權重

### 推薦值

**範圍**：0.0 到 1.0

**依模型類型劃分**：
| 模型類型 | SFT 權重 | 原因 |
|------------|-----------|--------|
| 基礎模型 (Base) | 0.0 | 無先前能力 |
| **指令模型 (Instruct)** | 0.05-0.1 | 保留指令遵循能力 |
| 對話模型 (Chat) | 0.1-0.2 | 保留對話技巧 |

**預設值**：0.0 (無 SFT 正則化)

### 為什麼 SFT 權重很重要

**零 SFT** (0.0)：
- 純粹的偏好最佳化
- 可能遺忘原有能力
- 基礎模型的標準做法

**低 SFT** (0.05-0.1)：
- 平衡的方法
- **推薦用於指令模型**
- 略微保留能力

**高 SFT** (> 0.2)：
- 強力的能力保留
- 較弱的偏好對齊
- 可能減少對齊收益

### 權衡 (Trade-off)

```
總損失 (Total Loss) = SimPO 損失 + (sft_weight * SFT 損失)
```

**範例**：
```yaml
sft_weight: 0.1
# 90% 偏好最佳化 + 10% 能力保留
```

### 設定範例

**基礎模型 (無 SFT)**：
```yaml
model_name_or_path: mistralai/Mistral-7B-v0.1
sft_weight: 0.0
```

**指令模型 (輕微 SFT)**：
```yaml
model_name_or_path: meta-llama/Meta-Llama-3-8B-Instruct
sft_weight: 0.1
```

**對話模型 (適度 SFT)**：
```yaml
model_name_or_path: HuggingFaceH4/zephyr-7b-beta
sft_weight: 0.2
```

## 模型大小特定的建議

### 7B 模型 (Mistral, Llama 3)

**標準設定**：
```yaml
learning_rate: 5e-7
beta: 2.0
gamma_beta_ratio: 0.5
sft_weight: 0.0  # 如果是指令模型則為 0.1
num_train_epochs: 1
per_device_train_batch_size: 2
gradient_accumulation_steps: 4
```

### 8B-13B 模型

**標準設定**：
```yaml
learning_rate: 3e-7
beta: 2.5
gamma_beta_ratio: 0.5
sft_weight: 0.1  # 如果是指令模型
num_train_epochs: 1
per_device_train_batch_size: 1
gradient_accumulation_steps: 8
```

### 70B 模型

**標準設定**：
```yaml
learning_rate: 1e-7
beta: 2.0
gamma_beta_ratio: 0.5
sft_weight: 0.05
num_train_epochs: 1
per_device_train_batch_size: 1
gradient_accumulation_steps: 16
```

## 批次大小 (Batch Size) 與梯度累積 (Gradient Accumulation)

### 有效批次大小 (Effective Batch Size)

```
有效批次大小 = 每裝置批次大小 * GPU 數量 * 梯度累積步數
```

**推薦的有效批次大小**：
- 7B: 128-256
- 13B: 64-128
- 70B: 32-64

### 設定範例

**單 GPU (A100 40GB)**：
```yaml
per_device_train_batch_size: 1
gradient_accumulation_steps: 128  # 有效批次 = 128
```

**4 GPUs (A100 40GB)**：
```yaml
per_device_train_batch_size: 2
gradient_accumulation_steps: 16  # 有效批次 = 2*4*16 = 128
```

**8 GPUs (A100 80GB)**：
```yaml
per_device_train_batch_size: 2
gradient_accumulation_steps: 8  # 有效批次 = 2*8*8 = 128
```

## 損失類型 (Loss Type)

### Sigmoid vs Hinge

**Sigmoid** (預設，推薦)：
```yaml
loss_type: sigmoid
label_smoothing: 0.0
```

**Hinge** (實驗性)：
```yaml
loss_type: hinge
# Hinge 不使用標籤平滑 (Label smoothing)
```

**何時使用 Hinge**：
- 基於邊際的任務
- SVM 風格的最佳化
- 實驗目的

**一般而言**：建議堅持使用 Sigmoid。

## 微調指南

### 步驟 1：從預設值開始

```yaml
learning_rate: 5e-7  # 對於 7B
beta: 2.0
gamma_beta_ratio: 0.5
sft_weight: 0.0  # 如果是指令模型則為 0.1
loss_type: sigmoid
```

### 步驟 2：監控訓練

**每 100 步檢查一次**：
- 損失曲線 (應平滑下降)
- 獎勵邊際 (應增加)
- 選中/拒絕的對數機率 (應分離)

### 步驟 3：如有需要進行調整

**如果損失發散**：
```yaml
learning_rate: 3e-7  # 從 5e-7 降低
beta: 1.0           # 從 2.0 降低
```

**如果損失過早進入平台期 (Plateaus)**：
```yaml
learning_rate: 1e-6  # 從 5e-7 增加
beta: 5.0           # 從 2.0 增加
```

**如果模型遺忘原有能力**：
```yaml
sft_weight: 0.2  # 從 0.0 增加
```

## 完整範例設定

### Mistral 7B 基礎模型 (標準)

```yaml
model_name_or_path: mistralai/Mistral-7B-v0.1
dataset_mixer:
  HuggingFaceH4/ultrafeedback_binarized: 1.0

learning_rate: 5e-7
beta: 2.0
gamma_beta_ratio: 0.5
loss_type: sigmoid
sft_weight: 0.0

num_train_epochs: 1
per_device_train_batch_size: 2
gradient_accumulation_steps: 4
warmup_ratio: 0.1
lr_scheduler_type: cosine

bf16: true
gradient_checkpointing: true
```

### Llama 3 8B 指令模型 (推理)

```yaml
model_name_or_path: meta-llama/Meta-Llama-3-8B-Instruct
dataset_mixer:
  argilla/distilabel-math-preference-dpo: 1.0

learning_rate: 3e-7
beta: 5.0
gamma_beta_ratio: 0.7
loss_type: sigmoid
sft_weight: 0.1

num_train_epochs: 1
per_device_train_batch_size: 1
gradient_accumulation_steps: 16
warmup_ratio: 0.1
lr_scheduler_type: cosine
```

## 參考資料

- SimPO 論文：https://arxiv.org/abs/2405.14734
- Alignment Handbook：https://github.com/huggingface/alignment-handbook
