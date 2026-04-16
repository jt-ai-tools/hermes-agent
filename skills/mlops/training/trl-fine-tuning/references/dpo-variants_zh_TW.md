# DPO 變體

TRL 中直接偏好優化 (Direct Preference Optimization, DPO) 損失函數變體的完整指南。

## 概觀

DPO 使用偏好資料 (已選/已拒樣本對) 來優化模型。TRL 針對不同場景支援了 10 多種損失函數變體。

## 損失函數類型

### 1. Sigmoid (標準 DPO)

**公式**：`-log(sigmoid(β * logits))`

**何時使用**：預設選擇，通用的偏好對齊

**配置**：
```python
DPOConfig(
    loss_type="sigmoid",
    beta=0.1,  # KL 懲罰
    per_device_train_batch_size=64,
    learning_rate=1e-6
)
```

### 2. IPO (恆等策略優化, Identity Policy Optimization)

**公式**：`(logits - 1/(2β))²`

**何時使用**：具備更好的理論基礎，減少過擬合 (Overfitting)

**配置**：
```python
DPOConfig(
    loss_type="ipo",
    beta=0.1,
    per_device_train_batch_size=90,
    learning_rate=1e-2
)
```

### 3. Hinge (SLiC)

**公式**：`ReLU(1 - β * logits)`

**何時使用**：基於邊界 (Margin) 的目標

**配置**：
```python
DPOConfig(
    loss_type="hinge",
    beta=0.1,
    per_device_train_batch_size=512,
    learning_rate=1e-4
)
```

### 4. 強健性 DPO (Robust DPO)

**公式**：搭配標籤平滑 (Label Smoothing) 的 Sigmoid，用於提升雜訊強健性

**何時使用**：含有雜訊的偏好標籤 (Noisy preference labels)

**配置**：
```python
DPOConfig(
    loss_type="robust",
    beta=0.01,
    label_smoothing=0.1,  # 雜訊機率
    per_device_train_batch_size=16,
    learning_rate=1e-3,
    max_prompt_length=128,
    max_length=512
)
```

### 5. BCO Pair (二元分類)

**公式**：訓練二元分類器 (已選=1, 已拒=0)

**何時使用**：成對偏好資料 (Pairwise preference data)

**配置**：
```python
DPOConfig(
    loss_type="bco_pair",
    beta=0.01,
    per_device_train_batch_size=128,
    learning_rate=5e-7,
    max_prompt_length=1536,
    max_completion_length=512
)
```

### 6. SPPO Hard

**公式**：將已選推向 0.5，已拒推向 -0.5

**何時使用**：納許均衡 (Nash equilibrium)、稀疏資料

**配置**：
```python
DPOConfig(
    loss_type="sppo_hard",
    beta=0.1
)
```

### 7. DiscoPOP

**公式**：對數比例調變損失 (Log-Ratio Modulated Loss)

**何時使用**：自動化損失函數發現

**配置**：
```python
DPOConfig(
    loss_type="discopop",
    beta=0.05,
    discopop_tau=0.05,
    per_device_train_batch_size=64,
    learning_rate=5e-7
)
```

### 8. APO Zero

**公式**：增加已選的可能性，減少已拒的可能性

**何時使用**：模型表現差於勝出輸出 (Winning outputs) 時

**配置**：
```python
DPOConfig(
    loss_type="apo_zero",
    beta=0.1,
    per_device_train_batch_size=64,
    learning_rate=2e-7,
    max_prompt_length=512,
    max_completion_length=512
)
```

### 9. APO Down

**公式**：兩者皆減少，但強調對已拒輸出的減少

**何時使用**：模型表現優於勝出輸出 (Winning outputs) 時

**配置**：
```python
DPOConfig(
    loss_type="apo_down",
    beta=0.1,
    # 超參數與 apo_zero 相同
)
```

### 10. AOT 與 AOT Pair

**公式**：透過隨機優勢 (Stochastic Dominance) 進行分佈對齊

**何時使用**：
- `aot_pair`：成對偏好資料
- `aot`：非成對資料

**配置**：
```python
DPOConfig(
    loss_type="aot_pair",  # 或 "aot"
    beta=0.1,
    label_smoothing=0.0
)
```

## 多損失函數訓練 (Multi-Loss Training)

結合多種損失函數：

```python
DPOConfig(
    loss_type=["sigmoid", "ipo"],
    loss_weights=[0.7, 0.3],  # 加權組合
    beta=0.1
)
```

## 關鍵參數

### Beta (β)

控制對參考模型 (Reference Model) 的偏離程度：
- **較高** (0.5)：較保守，保持與參考模型接近
- **較低** (0.01)：較激進的對齊
- **預設值**：0.1

### 標籤平滑 (Label Smoothing)

用於強健性 DPO：
- **0.0**：不使用平滑 (預設值)
- **0.1-0.3**：中度的雜訊強健性
- **0.5**：最高雜訊容忍度

### 最大長度 (Max Lengths)

- `max_prompt_length`：128-1536
- `max_completion_length`：128-512
- `max_length`：總序列長度 (1024-2048)

## 比較表

| 損失函數 | 速度 | 穩定性 | 最適合 |
|------|-------|-----------|----------|
| Sigmoid | 快 | 良好 | **通用情境** |
| IPO | 快 | 更好 | 解決過擬合問題 |
| Hinge | 快 | 良好 | 邊界目標 |
| Robust | 快 | 最佳 | 含有雜訊的資料 |
| BCO | 中 | 良好 | 二元分類 |
| DiscoPOP | 快 | 良好 | 新架構 |
| APO | 快 | 良好 | 模型品質匹配 |

## 參考資料

- DPO 論文：https://arxiv.org/abs/2305.18290
- IPO 論文：https://arxiv.org/abs/2310.12036
- TRL 文件：https://huggingface.co/docs/trl/dpo_trainer
