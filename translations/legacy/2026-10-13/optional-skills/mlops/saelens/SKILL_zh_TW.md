---
name: sparse-autoencoder-training
description: 提供使用 SAELens 訓練和分析稀疏自編碼器 (SAEs) 的指南，將神經網路激發值分解為具可解釋性的特徵。在發現可解釋特徵、分析疊加 (superposition) 或研究語言模型中的單一語義表示時使用。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [sae-lens>=6.0.0, transformer-lens>=2.0.0, torch>=2.0.0]
metadata:
  hermes:
    tags: [Sparse Autoencoders, SAE, Mechanistic Interpretability, Feature Discovery, Superposition]

---

# SAELens：用於機械解釋性的稀疏自編碼器

SAELens 是用於訓練和分析稀疏自編碼器 (Sparse Autoencoders, SAEs) 的主要函式庫 —— 這是一項將多語義 (polysemantic) 神經網路激發值分解為稀疏且可解釋特徵的技術。該技術基於 Anthropic 在單一語義性 (monosemanticity) 方面的突破性研究。

**GitHub**: [jbloomAus/SAELens](https://github.com/jbloomAus/SAELens) (1,100+ stars)

## 問題所在：多語義性與疊加

神經網路中的單個神經元通常是 **多語義的 (polysemantic)** —— 它們會在多個語義截然不同的上下文中被激發。這是因為模型使用 **疊加 (superposition)** 來表示比神經元數量更多的特徵，這使得解釋變得困難。

**SAEs 為此提供了解決方案**：透過將稠密的激發值分解為稀疏且單一語義的特徵 —— 通常對於任何給定輸入，只有極少數特徵會被激發，且每個特徵都對應一個可解釋的概念。

## 何時使用 SAELens

**當您需要執行以下操作時，請使用 SAELens：**
- 在模型激發值中發現可解釋的特徵
- 瞭解模型學習到了哪些概念
- 研究疊加與特徵幾何
- 執行基於特徵的轉向 (steering) 或消融 (ablation)
- 分析與安全相關的特徵（欺騙、偏見、有害內容）

**在以下情況下，請考慮替代方案：**
- 您僅需要基礎激發分析 → 直接使用 **TransformerLens**
- 您想要執行因果干預實驗 → 使用 **pyvene** 或 **TransformerLens**
- 您需要生產級轉向 → 考慮直接進行激發工程 (activation engineering)

## 安裝

```bash
pip install sae-lens
```

需求：Python 3.10+, transformer-lens>=2.0.0

## 核心概念

### SAE 學習內容

SAE 經由訓練，透過稀疏瓶頸重構模型激發值：

```
輸入激發值 → 編碼器 → 稀疏特徵 → 解碼器 → 重構激發值
    (d_model)   ↓   (d_sae >> d_model)  ↓      (d_model)
              稀疏性                  重構
              懲罰                    損失
```

**損失函數**：`MSE(原始, 重構) + L1_係數 × L1(特徵)`

### 關鍵驗證（Anthropic 研究）

在《邁向單一語義性》(Towards Monosemanticity) 研究中，人工評估員發現 **70% 的 SAE 特徵確實具有可解釋性**。發現的特徵包括：
- DNA 序列、法律術語、HTTP 請求
- 希伯來語文本、營養聲明、程式碼語法
- 情感、命名實體、語法結構

## 工作流程 1：載入並分析預訓練 SAE

### 步驟詳解

```python
from transformer_lens import HookedTransformer
from sae_lens import SAE

# 1. 載入模型和預訓練 SAE
model = HookedTransformer.from_pretrained("gpt2-small", device="cuda")
sae, cfg_dict, sparsity = SAE.from_pretrained(
    release="gpt2-small-res-jb",
    sae_id="blocks.8.hook_resid_pre",
    device="cuda"
)

# 2. 取得模型激發值
tokens = model.to_tokens("The capital of France is Paris")
_, cache = model.run_with_cache(tokens)
activations = cache["resid_pre", 8]  # [batch, pos, d_model]

# 3. 編碼為 SAE 特徵
sae_features = sae.encode(activations)  # [batch, pos, d_sae]
print(f"激發特徵數量: {(sae_features > 0).sum()}")

# 4. 尋找每個位置的前幾名特徵
for pos in range(tokens.shape[1]):
    top_features = sae_features[0, pos].topk(5)
    token = model.to_str_tokens(tokens[0, pos:pos+1])[0]
    print(f"Token '{token}': features {top_features.indices.tolist()}")

# 5. 重構激發值
reconstructed = sae.decode(sae_features)
reconstruction_error = (activations - reconstructed).norm()
```

### 可用的預訓練 SAE

| 發佈版本 | 模型 | 層數 |
|---------|-------|--------|
| `gpt2-small-res-jb` | GPT-2 Small | 多個殘差流 (residual streams) |
| `gemma-2b-res` | Gemma 2B | 殘差流 |
| HuggingFace 上的各種版本 | 搜尋標籤 `saelens` | 各種 |

### 檢查清單
- [ ] 使用 TransformerLens 載入模型
- [ ] 載入目標層對應的 SAE
- [ ] 將激發值編碼為稀疏特徵
- [ ] 辨識每個 token 激發程度最高的特徵
- [ ] 驗證重構品質

## 工作流程 2：訓練自定義 SAE

### 步驟詳解

```python
from sae_lens import SAE, LanguageModelSAERunnerConfig, SAETrainingRunner

# 1. 設定訓練參數
cfg = LanguageModelSAERunnerConfig(
    # 模型
    model_name="gpt2-small",
    hook_name="blocks.8.hook_resid_pre",
    hook_layer=8,
    d_in=768,  # 模型維度

    # SAE 架構
    architecture="standard",  # 或 "gated", "topk"
    d_sae=768 * 8,  # 擴展因子為 8
    activation_fn="relu",

    # 訓練
    lr=4e-4,
    l1_coefficient=8e-5,  # 稀疏性懲罰
    l1_warm_up_steps=1000,
    train_batch_size_tokens=4096,
    training_tokens=100_000_000,

    # 資料
    dataset_path="monology/pile-uncopyrighted",
    context_size=128,

    # 日誌
    log_to_wandb=True,
    wandb_project="sae-training",

    # 檢查點
    checkpoint_path="checkpoints",
    n_checkpoints=5,
)

# 2. 開始訓練
trainer = SAETrainingRunner(cfg)
sae = trainer.run()

# 3. 評估
print(f"L0 (平均激發特徵數): {trainer.metrics['l0']}")
print(f"CE Loss 恢復率: {trainer.metrics['ce_loss_score']}")
```

### 關鍵超參數

| 參數 | 典型值 | 影響 |
|-----------|---------------|--------|
| `d_sae` | 4-16× d_model | 特徵更多，容量更高 |
| `l1_coefficient` | 5e-5 到 1e-4 | 越高越稀疏，準確度越低 |
| `lr` | 1e-4 到 1e-3 | 標準優化器學習率 |
| `l1_warm_up_steps` | 500-2000 | 防止特徵過早死亡 |

## 評估指標

| 指標 | 目標值 | 意義 |
|--------|--------|---------|
| **L0** | 50-200 | 每個 token 的平均激發特徵數 |
| **CE Loss 分數** | 80-95% | 相對於原始模型的交叉熵恢復率 |
| **死亡特徵 (Dead Features)** | <5% | 從未被激發的特徵 |
| **解釋方差 (Explained Variance)** | >90% | 重構品質 |

### 檢查清單
- [ ] 選擇目標層和掛鉤點 (hook point)
- [ ] 設定擴展因子 (d_sae = 4-16× d_model)
- [ ] 調整 L1 係數以達到理想的稀疏度
- [ ] 啟用 L1 預熱以防止特徵死亡
- [ ] 訓練期間監控指標 (W&B)
- [ ] 驗證 L0 和 CE 損失恢復率
- [ ] 檢查死亡特徵比例

## 工作流程 3：特徵分析與轉向 (Steering)

### 分析單個特徵

```python
from transformer_lens import HookedTransformer
from sae_lens import SAE
import torch

model = HookedTransformer.from_pretrained("gpt2-small", device="cuda")
sae, _, _ = SAE.from_pretrained(
    release="gpt2-small-res-jb",
    sae_id="blocks.8.hook_resid_pre",
    device="cuda"
)

# 尋找是什麼激發了特定特徵
feature_idx = 1234
test_texts = [
    "The scientist conducted an experiment",
    "I love chocolate cake",
    "The code compiles successfully",
    "Paris is beautiful in spring",
]

for text in test_texts:
    tokens = model.to_tokens(text)
    _, cache = model.run_with_cache(tokens)
    features = sae.encode(cache["resid_pre", 8])
    activation = features[0, :, feature_idx].max().item()
    print(f"{activation:.3f}: {text}")
```

### 特徵轉向 (Feature Steering)

```python
def steer_with_feature(model, sae, prompt, feature_idx, strength=5.0):
    """將 SAE 特徵方向加入殘差流。"""
    tokens = model.to_tokens(prompt)

    # 從解碼器取得特徵方向
    feature_direction = sae.W_dec[feature_idx]  # [d_model]

    def steering_hook(activation, hook):
        # 在所有位置加入按比例縮放的特徵方向
        activation += strength * feature_direction
        return activation

    # 進行帶轉向的生成
    output = model.generate(
        tokens,
        max_new_tokens=50,
        fwd_hooks=[("blocks.8.hook_resid_pre", steering_hook)]
    )
    return model.to_string(output[0])
```

### 特徵歸因 (Feature Attribution)

```python
# 哪些特徵對特定輸出影響最大？
tokens = model.to_tokens("The capital of France is")
_, cache = model.run_with_cache(tokens)

# 取得最後位置的特徵
features = sae.encode(cache["resid_pre", 8])[0, -1]  # [d_sae]

# 取得每個特徵的 logit 歸因
# 特徵貢獻 = 特徵激發值 × 解碼器權重 × 反嵌入 (unembedding)
W_dec = sae.W_dec  # [d_sae, d_model]
W_U = model.W_U    # [d_model, vocab]

# 對 " Paris" token 的貢獻
paris_token = model.to_single_token(" Paris")
feature_contributions = features * (W_dec @ W_U[:, paris_token])

top_features = feature_contributions.topk(10)
print("'Paris' 預測的前幾名特徵：")
for idx, val in zip(top_features.indices, top_features.values):
    print(f"  特徵 {idx.item()}: {val.item():.3f}")
```

## 常見問題與解決方案

### 問題：死亡特徵 (Dead features) 比例過高
```python
# 錯誤：沒有預熱，特徵過早死亡
cfg = LanguageModelSAERunnerConfig(
    l1_coefficient=1e-4,
    l1_warm_up_steps=0,  # 糟糕！
)

# 正確：為 L1 懲罰設定預熱
cfg = LanguageModelSAERunnerConfig(
    l1_coefficient=8e-5,
    l1_warm_up_steps=1000,  # 逐漸增加
    use_ghost_grads=True,   # 復活死亡特徵
)
```

### 問題：重構效果差（CE 恢復率低）
```python
# 降低稀疏性懲罰
cfg = LanguageModelSAERunnerConfig(
    l1_coefficient=5e-5,  # 越低重構越好
    d_sae=768 * 16,       # 增加容量
)
```

### 問題：特徵不可解釋
```python
# 增加稀疏性（提高 L1）
cfg = LanguageModelSAERunnerConfig(
    l1_coefficient=1e-4,  # 越高越稀疏，越可解釋
)
# 或使用 TopK 架構
cfg = LanguageModelSAERunnerConfig(
    architecture="topk",
    activation_fn_kwargs={"k": 50},  # 恰好 50 個激發特徵
)
```

### 問題：訓練期間出現記憶體錯誤 (OOM)
```python
cfg = LanguageModelSAERunnerConfig(
    train_batch_size_tokens=2048,  # 減小 batch size
    store_batch_size_prompts=4,    # 減少緩衝區中的 prompt 數量
    n_batches_in_buffer=8,         # 減小激發值緩衝區
)
```

## 與 Neuronpedia 整合

在 [neuronpedia.org](https://neuronpedia.org) 瀏覽預訓練的 SAE 特徵：

```python
# 特徵按 SAE ID 編入索引
# 範例：gpt2-small 第 8 層特徵 1234
# → neuronpedia.org/gpt2-small/8-res-jb/1234
```

## 關鍵類別參考

| 類別 | 用途 |
|-------|---------|
| `SAE` | 稀疏自編碼器模型 |
| `LanguageModelSAERunnerConfig` | 訓練組態 |
| `SAETrainingRunner` | 訓練迴圈管理器 |
| `ActivationsStore` | 激發值收集與批次處理 |
| `HookedSAETransformer` | TransformerLens + SAE 整合 |

## 參考文件

有關詳細的 API 文件、教學和高級用法，請參閱 `references/` 資料夾：

| 檔案 | 內容 |
|------|----------|
| [references/README.md](references/README.md) | 概觀與快速入門指南 |
| [references/api.md](references/api.md) | SAE、TrainingSAE、組態的完整 API 參考 |
| [references/tutorials.md](references/tutorials.md) | 訓練、分析、轉向的逐步教學 |

## 外部資源

### 教學
- [基礎載入與分析](https://github.com/jbloomAus/SAELens/blob/main/tutorials/basic_loading_and_analysing.ipynb)
- [訓練稀疏自編碼器](https://github.com/jbloomAus/SAELens/blob/main/tutorials/training_a_sparse_autoencoder.ipynb)
- [ARENA SAE 課程](https://www.lesswrong.com/posts/LnHowHgmrMbWtpkxx/intro-to-superposition-and-sparse-autoencoders-colab)

### 論文
- [Towards Monosemanticity](https://transformer-circuits.pub/2023/monosemantic-features) - Anthropic (2023)
- [Scaling Monosemanticity](https://transformer-circuits.pub/2024/scaling-monosemanticity/) - Anthropic (2024)
- [Sparse Autoencoders Find Highly Interpretable Features](https://arxiv.org/abs/2309.08600) - Cunningham et al. (ICLR 2024)

### 官方文件
- [SAELens 文件](https://jbloomaus.github.io/SAELens/)
- [Neuronpedia](https://neuronpedia.org) - 特徵瀏覽器

## SAE 架構

| 架構 | 描述 | 使用場景 |
|--------------|-------------|----------|
| **Standard** | ReLU + L1 懲罰 | 通用目的 |
| **Gated** | 學習到的門控機制 | 更好的稀疏性控制 |
| **TopK** | 恰好 K 個激發特徵 | 一致的稀疏性 |

```python
# TopK SAE (恰好 50 個特徵激發)
cfg = LanguageModelSAERunnerConfig(
    architecture="topk",
    activation_fn="topk",
    activation_fn_kwargs={"k": 50},
)
```
