# SAELens 教學

## 教學 1：載入並分析預訓練的 SAE

### 目標
載入預訓練的 SAE，並分析哪些特徵會在特定的輸入上啟動。

### 逐步指南

```python
from transformer_lens import HookedTransformer
from sae_lens import SAE
import torch

# 1. 載入模型與 SAE
model = HookedTransformer.from_pretrained("gpt2-small", device="cuda")
sae, cfg_dict, sparsity = SAE.from_pretrained(
    release="gpt2-small-res-jb",
    sae_id="blocks.8.hook_resid_pre",
    device="cuda"
)

print(f"SAE 輸入維度: {sae.cfg.d_in}")
print(f"SAE 隱藏維度: {sae.cfg.d_sae}")
print(f"擴展係數 (Expansion factor): {sae.cfg.d_sae / sae.cfg.d_in:.1f}x")

# 2. 獲取模型激活值
prompt = "The capital of France is Paris"
tokens = model.to_tokens(prompt)
_, cache = model.run_with_cache(tokens)
activations = cache["resid_pre", 8]  # [1, seq_len, 768]

# 3. 編碼為 SAE 特徵
features = sae.encode(activations)  # [1, seq_len, d_sae]

# 4. 分析稀疏性
active_per_token = (features > 0).sum(dim=-1)
print(f"每個 Token 的平均啟動特徵數: {active_per_token.float().mean():.1f}")

# 5. 找出每個 Token 的頂尖特徵
str_tokens = model.to_str_tokens(prompt)
for pos in range(len(str_tokens)):
    top_features = features[0, pos].topk(5)
    print(f"\nToken '{str_tokens[pos]}':")
    for feat_idx, feat_val in zip(top_features.indices, top_features.values):
        print(f"  特徵 {feat_idx.item()}: {feat_val.item():.3f}")

# 6. 檢查重建品質
reconstructed = sae.decode(features)
mse = ((activations - reconstructed) ** 2).mean()
print(f"\n重建 MSE: {mse.item():.6f}")
```

---

## 教學 2：訓練自定義 SAE

### 目標
在 GPT-2 激活值上訓練稀疏自編碼器 (Sparse Autoencoder)。

### 逐步指南

```python
from sae_lens import LanguageModelSAERunnerConfig, SAETrainingRunner

# 1. 配置訓練
cfg = LanguageModelSAERunnerConfig(
    # 模型
    model_name="gpt2-small",
    hook_name="blocks.6.hook_resid_pre",
    hook_layer=6,
    d_in=768,

    # SAE 架構
    architecture="standard",
    d_sae=768 * 8,  # 8 倍擴展
    activation_fn="relu",

    # 訓練
    lr=4e-4,
    l1_coefficient=8e-5,
    l1_warm_up_steps=1000,
    train_batch_size_tokens=4096,
    training_tokens=10_000_000,  # 僅供演示的小規模運算

    # 數據
    dataset_path="monology/pile-uncopyrighted",
    streaming=True,
    context_size=128,

    # 預防死特徵 (Dead feature prevention)
    use_ghost_grads=True,
    dead_feature_window=5000,

    # 日誌
    log_to_wandb=True,
    wandb_project="sae-training-demo",

    # 硬體
    device="cuda",
    dtype="float32",
)

# 2. 訓練
runner = SAETrainingRunner(cfg)
sae = runner.run()

# 3. 保存
sae.save_model("./my_trained_sae")
```

### 超參數微調指南

| 如果你發現... | 試試看... |
|---------------|--------|
| L0 過高 (>200) | 增加 `l1_coefficient` |
| CE 恢復率過低 (<80%) | 減少 `l1_coefficient`，增加 `d_sae` |
| 死特徵過多 (>5%) | 啟用 `use_ghost_grads`，增加 `l1_warm_up_steps` |
| 訓練不穩定 | 降低 `lr`，增加 `lr_warm_up_steps` |

---

## 教學 3：特徵歸因與引導 (Steering)

### 目標
識別哪些 SAE 特徵對特定的預測有貢獻，並利用它們進行引導。

### 逐步指南

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

# 1. 針對特定預測進行特徵歸因
prompt = "The capital of France is"
tokens = model.to_tokens(prompt)
_, cache = model.run_with_cache(tokens)
activations = cache["resid_pre", 8]
features = sae.encode(activations)

# 目標 Token
target_token = model.to_single_token(" Paris")

# 計算特徵對目標 Logit 的貢獻
# 貢獻 = 特徵激活值 * 解碼器權重 * 解嵌入 (unembedding)
W_dec = sae.W_dec  # [d_sae, d_model]
W_U = model.W_U    # [d_model, d_vocab]

# 投影到詞彙表的特徵方向
feature_to_logit = W_dec @ W_U  # [d_sae, d_vocab]

# 每個特徵在最終位置對 "Paris" 的貢獻
feature_acts = features[0, -1]  # [d_sae]
contributions = feature_acts * feature_to_logit[:, target_token]

# 貢獻最高的特徵
top_features = contributions.topk(10)
print("對 'Paris' 貢獻最高的特徵:")
for idx, val in zip(top_features.indices, top_features.values):
    print(f"  特徵 {idx.item()}: {val.item():.3f}")

# 2. 特徵引導 (Feature steering)
def steer_with_feature(feature_idx, strength=5.0):
    """將特徵方向添加到殘差流中。"""
    feature_direction = sae.W_dec[feature_idx]  # [d_model]

    def hook(activation, hook_obj):
        activation[:, -1, :] += strength * feature_direction
        return activation

    output = model.generate(
        tokens,
        max_new_tokens=10,
        fwd_hooks=[("blocks.8.hook_resid_pre", hook)]
    )
    return model.to_string(output[0])

# 嘗試使用最高貢獻特徵進行引導
top_feature_idx = top_features.indices[0].item()
print(f"\n使用特徵 {top_feature_idx} 進行引導:")
print(steer_with_feature(top_feature_idx, strength=10.0))
```

---

## 教學 4：特徵消融 (Ablation)

### 目標
通過消融特徵來測試特徵的因果重要性。

### 逐步指南

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

prompt = "The capital of France is"
tokens = model.to_tokens(prompt)

# 基線預測
baseline_logits = model(tokens)
target_token = model.to_single_token(" Paris")
baseline_prob = torch.softmax(baseline_logits[0, -1], dim=-1)[target_token].item()
print(f"基線 P(Paris): {baseline_prob:.4f}")

# 獲取要消融的特徵
_, cache = model.run_with_cache(tokens)
activations = cache["resid_pre", 8]
features = sae.encode(activations)
top_features = features[0, -1].topk(10).indices

# 逐一消融頂尖特徵
for feat_idx in top_features:
    def ablation_hook(activation, hook, feat_idx=feat_idx):
        # 編碼 → 將特徵歸零 → 解碼
        feats = sae.encode(activation)
        feats[:, :, feat_idx] = 0
        return sae.decode(feats)

    ablated_logits = model.run_with_hooks(
        tokens,
        fwd_hooks=[("blocks.8.hook_resid_pre", ablation_hook)]
    )
    ablated_prob = torch.softmax(ablated_logits[0, -1], dim=-1)[target_token].item()
    change = (ablated_prob - baseline_prob) / baseline_prob * 100
    print(f"消融特徵 {feat_idx.item()}: P(Paris)={ablated_prob:.4f} ({change:+.1f}%)")
```

---

## 教學 5：跨 Prompt 比較特徵

### 目標
找出對於某個概念一致啟動的特徵。

### 逐步指南

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

# 測試關於相同概念的 Prompt
prompts = [
    "The Eiffel Tower is located in",
    "Paris is the capital of",
    "France's largest city is",
    "The Louvre museum is in",
]

# 收集特徵激活值
all_features = []
for prompt in prompts:
    tokens = model.to_tokens(prompt)
    _, cache = model.run_with_cache(tokens)
    activations = cache["resid_pre", 8]
    features = sae.encode(activations)
    # 取各位置的最大激活值
    max_features = features[0].max(dim=0).values
    all_features.append(max_features)

all_features = torch.stack(all_features)  # [n_prompts, d_sae]

# 找出一致啟動的特徵
mean_activation = all_features.mean(dim=0)
min_activation = all_features.min(dim=0).values

# 在所有 Prompt 中都啟動的特徵
consistent_features = (min_activation > 0.5).nonzero().squeeze(-1)
print(f"在所有 Prompt 中都啟動的特徵數: {len(consistent_features)}")

# 頂尖的一致特徵
top_consistent = mean_activation[consistent_features].topk(min(10, len(consistent_features)))
print("\n頂尖一致特徵 (可能與 'France/Paris' 相關):")
for idx, val in zip(top_consistent.indices, top_consistent.values):
    feat_idx = consistent_features[idx].item()
    print(f"  特徵 {feat_idx}: 平均激活值 {val.item():.3f}")
```

---

## 外部資源

### 官方教學 (英文)
- [基礎載入與分析 (Basic Loading & Analysis)](https://github.com/jbloomAus/SAELens/blob/main/tutorials/basic_loading_and_analysing.ipynb)
- [訓練 SAE (Training SAEs)](https://github.com/jbloomAus/SAELens/blob/main/tutorials/training_a_sparse_autoencoder.ipynb)
- [帶特徵的 Logits Lens (Logits Lens with Features)](https://github.com/jbloomAus/SAELens/blob/main/tutorials/logits_lens_with_features.ipynb)

### ARENA 課程
完整的 SAE 課程：https://www.lesswrong.com/posts/LnHowHgmrMbWtpkxx/intro-to-superposition-and-sparse-autoencoders-colab

### 關鍵論文 (英文)
- [邁向單一語義性 (Towards Monosemanticity)](https://transformer-circuits.pub/2023/monosemantic-features) - Anthropic (2023)
- [擴展單一語義性 (Scaling Monosemanticity)](https://transformer-circuits.pub/2024/scaling-monosemanticity/) - Anthropic (2024)
- [稀疏自編碼器發現可解釋特徵 (Sparse Autoencoders Find Interpretable Features)](https://arxiv.org/abs/2309.08600) - ICLR 2024
