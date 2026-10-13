# 損失函數 (Loss Functions)

關於 SimPO 損失函數與數學公式的完整指南。

## 概覽

SimPO 支援兩種損失類型：
- **Sigmoid** (預設) - 平滑且可微分的損失
- **Hinge** - 基於邊際的稀疏損失 (Sparse loss)

兩者皆為「無參考模型」(Reference-free) 的形式，亦即不需要額外的參考模型。

## SimPO 損失公式

### 核心計算

**步驟 1：對數機率比 (Log probability ratio)**：
```
pi_logratios = log P_θ(y_chosen|x) - log P_θ(y_rejected|x)
```

**步驟 2：套用目標邊際 (Target margin)**：
```
logits = pi_logratios - γ/β
```
其中：
- γ/β = `gamma_beta_ratio` (目標邊際值)

**步驟 3：計算損失** (取決於損失類型)

### Sigmoid 損失 (預設)

**公式**：
```
L = -log σ(β * logits) * (1 - ε) - log σ(-β * logits) * ε
```

其中：
- β = `beta` (獎勵縮放)
- σ = Sigmoid 函數
- ε = `label_smoothing` (預設為 0.0)

**實作方式**：
```python
losses = (
    -F.logsigmoid(self.beta * logits) * (1 - self.label_smoothing)
    - F.logsigmoid(-self.beta * logits) * self.label_smoothing
)
```

**特性**：
- 平滑且連續的梯度
- 具有機率解釋性
- 大多數任務的標準選擇
- 在較大的 beta 值下運作良好

### Hinge 損失

**公式**：
```
L = max(0, 1 - β * logits)
```

**實作方式**：
```python
losses = torch.relu(1 - self.beta * logits)
```

**特性**：
- 非平滑 (在 logits = 1/β 處有轉折點)
- 基於邊際 (SVM 風格)
- 可能導致更稀疏的解
- 較少被使用

## 與 DPO 的比較

### DPO 損失 (需要參考模型)

**公式**：
```
L_DPO = -E[log σ(β * log(π_θ(y_w|x)/π_ref(y_w|x)) - β * log(π_θ(y_l|x)/π_ref(y_l|x)))]
```

**關鍵特點**：
- 需要參考模型 π_ref
- 透過參考模型的對數機率進行正規化
- 較為保守 (模型會保持接近參考模型)

### SimPO 損失 (無參考模型)

**公式**：
```
L_SimPO = -log σ(β * (log π_θ(y_w|x) - log π_θ(y_l|x) - γ/β))
```

**關鍵特點**：
- 不需要參考模型
- 直接偏好最佳化
- 目標邊際 γ/β 控制偏好強度
- 更有效率 (更少的模型前向傳播次數)

**視覺化比較**：
```
DPO:    [策略模型] - [參考模型] → 損失
SimPO:  [策略模型]               → 損失
```

## 平均對數機率獎勵 (Average Log Probability Reward)

### 計算方式

**逐對稱 (Per-token) 對數機率**：
```python
# 取得每個 token 的對數機率
per_token_logps = log_softmax(logits).gather(dim=-1, index=labels)

# 建立遮罩以忽略填充 (Padding)
loss_mask = (labels != label_pad_token_id)
```

**平均對數機率** (如果 `average_log_prob=True`)：
```python
avg_logp = (per_token_logps * loss_mask).sum(-1) / loss_mask.sum(-1)
```

**總和對數機率** (如果 `average_log_prob=False`)：
```python
sum_logp = (per_token_logps * loss_mask).sum(-1)
```

**為什麼要取平均？**
- 針對序列長度進行正規化
- 防止對較短或較長的回答產生偏見
- SimPO 中的標準做法

### 獎勵指標 (Reward Metrics)

**選中獎勵 (Chosen reward)**：
```python
chosen_rewards = beta * policy_chosen_logps.detach()
```

**拒絕獎勵 (Rejected reward)**：
```python
rejected_rewards = beta * policy_rejected_logps.detach()
```

**獎勵邊際 (Reward margin)**：
```python
reward_margin = chosen_rewards.mean() - rejected_rewards.mean()
```

## 標籤平滑 (Label Smoothing)

### 包含平滑項的公式

**Sigmoid 損失**：
```
L = -log σ(β * logits) * (1 - ε) - log σ(-β * logits) * ε
```

**效果**：
- ε = 0.0：不進行平滑 (預設)
- ε = 0.1：10% 平滑 (軟標籤)
- ε = 0.5：最大程度平滑

**何時使用**：
- 有雜訊的偏好標籤
- 不確定的偏好
- 防止模型過度自信

**設定範例**：
```yaml
label_smoothing: 0.1  # 10% 標籤平滑
```

## SFT 正則化 (SFT Regularization)

### 組合損失

**包含 SFT 元件**：
```
L_total = L_SimPO + λ * L_SFT
```

其中：
- L_SFT = 針對選中回答的交叉熵損失 (Cross-entropy loss)
- λ = `sft_weight` (0.0 到 1.0)

**實作方式**：
```python
if self.sft_weight > 0:
    sft_loss = -policy_chosen_logps
    total_loss = simpo_loss + self.sft_weight * sft_loss
```

**何時使用**：
- 保留模型原有能力
- 防止災難性遺忘
- 微調指令模型

**權衡 (Trade-off)**：
- 較高的 sft_weight：保留能力較多，但對齊效果較弱
- 較低的 sft_weight：對齊效果較強，但可能遺忘原有能力

**設定範例**：
```yaml
sft_weight: 0.1  # 10% SFT 正則化
```

## 損失類型選擇

### Sigmoid vs Hinge

| 面向 | Sigmoid | Hinge |
|--------|---------|-------|
| 平滑度 | 平滑 | 非平滑 |
| 梯度 | 連續 | 在邊際處不連續 |
| 稀疏性 | 稠密解 | 稀疏解 |
| 解釋性 | 機率論 | 幾何邊際 |
| 使用場景 | **通用** | 基於邊際的任務 |
| 推薦建議 | **預設選擇** | 實驗性質 |

**設定範例**：
```yaml
# Sigmoid (預設)
loss_type: sigmoid

# Hinge (替代方案)
loss_type: hinge
```

## 數學性質

### 梯度分析

**Sigmoid 損失梯度**：
```
∂L/∂logits = -β * σ(-β * logits) * (1 - ε) + β * σ(β * logits) * ε
```

**Hinge 損失梯度**：
```
∂L/∂logits = -β   如果 logits < 1/β
             0     否則
```

**啟示**：
- Sigmoid：始終提供梯度訊號
- Hinge：當滿足邊際條件時無梯度

### 收斂行為

**Sigmoid**：
- 漸近地接近零損失
- 即使在邊際較大時仍持續最佳化
- 訓練曲線較為平滑

**Hinge**：
- 在達到邊際時損失即為零
- 一旦滿足邊際條件即停止最佳化
- 可能會出現訓練平台期 (Training plateaus)

## 完整損失計算範例

### 範例 1：基本 SimPO (Sigmoid)

**設定**：
```yaml
beta: 2.0
gamma_beta_ratio: 0.5
loss_type: sigmoid
label_smoothing: 0.0
sft_weight: 0.0
```

**損失計算**：
```python
# 步驟 1：計算對數機率
chosen_logps = avg_log_prob(policy(chosen))    # 例如：-1.2
rejected_logps = avg_log_prob(policy(rejected)) # 例如：-2.5

# 步驟 2：計算對數比值與邊際
pi_logratios = -1.2 - (-2.5) = 1.3
logits = 1.3 - 0.5 = 0.8

# 步驟 3：Sigmoid 損失
loss = -log(sigmoid(2.0 * 0.8))
     = -log(sigmoid(1.6))
     = -log(0.832)
     = 0.184
```

### 範例 2：包含 SFT 的 SimPO

**設定**：
```yaml
beta: 2.5
gamma_beta_ratio: 0.5
loss_type: sigmoid
sft_weight: 0.1
```

**損失計算**：
```python
# SimPO 損失 (如上所述)
simpo_loss = 0.184

# SFT 損失
sft_loss = -chosen_logps = -(-1.2) = 1.2

# 總損失
total_loss = simpo_loss + 0.1 * sft_loss
           = 0.184 + 0.12
           = 0.304
```

## 除錯 (Debugging)

### 檢查獎勵邊際

**邊際較低 (< 0.5)**：
- 模型未學習到偏好
- 嘗試增加 beta 或 gamma_beta_ratio

**邊際較高 (> 5.0)**：
- 可能發生過擬合 (Overfitting)
- 嘗試降低 beta 或學習率

**監控方式**：
```python
reward_margin = chosen_rewards.mean() - rejected_rewards.mean()
print(f"獎勵邊際: {reward_margin:.2f}")
```

### 檢查對數機率

**典型數值**：
- 選中 (Chosen)：-1.0 到 -2.0 (越高越好)
- 拒絕 (Rejected)：-2.0 到 -4.0 (越低越差)

**警訊**：
- 兩者數值都極低 (< -10)：模型未在學習
- 兩者數值都極高 (> 0)：數值不穩定

## 參考資料

- SimPO 論文：https://arxiv.org/abs/2405.14734
- DPO 論文：https://arxiv.org/abs/2305.18290
- 實作程式碼：https://github.com/princeton-nlp/SimPO
