# SAELens API 參考

## SAE 類別 (SAE Class)

代表稀疏自動編碼器 (Sparse Autoencoder) 的核心類別。

### 載入預訓練的 SAE

```python
from sae_lens import SAE

# 來自官方發佈版本
sae, cfg_dict, sparsity = SAE.from_pretrained(
    release="gpt2-small-res-jb",
    sae_id="blocks.8.hook_resid_pre",
    device="cuda"
)

# 來自 HuggingFace
sae, cfg_dict, sparsity = SAE.from_pretrained(
    release="username/repo-name",
    sae_id="path/to/sae",
    device="cuda"
)

# 來自本地磁碟
sae = SAE.load_from_disk("/path/to/sae", device="cuda")
```

### SAE 屬性

| 屬性 | 形狀 (Shape) | 描述 |
|-----------|-------|-------------|
| `W_enc` | [d_in, d_sae] | 編碼器權重 (Encoder weights) |
| `W_dec` | [d_sae, d_in] | 解碼器權重 (Decoder weights) |
| `b_enc` | [d_sae] | 編碼器偏置 (Encoder bias) |
| `b_dec` | [d_in] | 解碼器偏置 (Decoder bias) |
| `cfg` | SAEConfig | 配置物件 |

### 核心方法

#### encode()

```python
# 將激發值 (Activations) 編碼為稀疏特徵
features = sae.encode(activations)
# 輸入：[batch, pos, d_in]
# 輸出：[batch, pos, d_sae]
```

#### decode()

```python
# 從特徵重構激發值
reconstructed = sae.decode(features)
# 輸入：[batch, pos, d_sae]
# 輸出：[batch, pos, d_in]
```

#### forward()

```python
# 完整的正向傳播（encode + decode）
reconstructed = sae(activations)
# 返回重構後的激發值
```

#### save_model()

```python
sae.save_model("/path/to/save")
```

---

## SAEConfig

SAE 架構與訓練內容的配置類別。

### 關鍵參數

| 參數 | 類型 | 描述 |
|-----------|------|-------------|
| `d_in` | int | 輸入維度（模型的 d_model） |
| `d_sae` | int | SAE 隱藏層維度 |
| `architecture` | str | "standard", "gated", "jumprelu", "topk" |
| `activation_fn_str` | str | 激發函數 (Activation function) 名稱 |
| `model_name` | str | 來源模型名稱 |
| `hook_name` | str | 模型中的 Hook 點 |
| `normalize_activations` | str | 正規化方法 |
| `dtype` | str | 資料類型 |
| `device` | str | 裝置 |

### 存取配置

```python
print(sae.cfg.d_in)      # 對於 GPT-2 small 為 768
print(sae.cfg.d_sae)     # 例如：24576 (32 倍擴展)
print(sae.cfg.hook_name) # 例如："blocks.8.hook_resid_pre"
```

---

## LanguageModelSAERunnerConfig

訓練 SAE 的全面配置。

### 範例配置

```python
from sae_lens import LanguageModelSAERunnerConfig

cfg = LanguageModelSAERunnerConfig(
    # 模型與 Hook
    model_name="gpt2-small",
    hook_name="blocks.8.hook_resid_pre",
    hook_layer=8,
    d_in=768,

    # SAE 架構
    architecture="standard",  # "standard", "gated", "jumprelu", "topk"
    d_sae=768 * 8,           # 擴展因子 (Expansion factor)
    activation_fn="relu",

    # 訓練超參數
    lr=4e-4,
    l1_coefficient=8e-5,
    lp_norm=1.0,
    lr_scheduler_name="constant",
    lr_warm_up_steps=500,

    # 稀疏性控制 (Sparsity control)
    l1_warm_up_steps=1000,
    use_ghost_grads=True,
    feature_sampling_window=1000,
    dead_feature_window=5000,
    dead_feature_threshold=1e-8,

    # 資料
    dataset_path="monology/pile-uncopyrighted",
    streaming=True,
    context_size=128,

    # 批次大小 (Batch sizes)
    train_batch_size_tokens=4096,
    store_batch_size_prompts=16,
    n_batches_in_buffer=64,

    # 訓練時長
    training_tokens=100_000_000,

    # 紀錄 (Logging)
    log_to_wandb=True,
    wandb_project="sae-training",
    wandb_log_frequency=100,

    # 檢查點 (Checkpointing)
    checkpoint_path="checkpoints",
    n_checkpoints=5,

    # 硬體
    device="cuda",
    dtype="float32",
)
```

### 關鍵參數說明

#### 架構參數

| 參數 | 描述 |
|-----------|-------------|
| `architecture` | SAE 類型："standard", "gated", "jumprelu", "topk" |
| `d_sae` | 隱藏層維度（或使用 `expansion_factor`） |
| `expansion_factor` | d_sae 的替代方案：d_sae = d_in × expansion_factor |
| `activation_fn` | "relu", "topk" 等 |
| `activation_fn_kwargs` | 激發參數字典（例如：topk 的 {"k": 50}） |

#### 稀疏性參數

| 參數 | 描述 |
|-----------|-------------|
| `l1_coefficient` | L1 懲罰權重（越高 = 越稀疏） |
| `l1_warm_up_steps` | L1 懲罰遞增的步數 |
| `use_ghost_grads` | 對死亡特徵 (Dead features) 套用梯度 |
| `dead_feature_threshold` | 判定為「死亡」的激發閾值 |
| `dead_feature_window` | 檢查死亡特徵的步數窗口 |

#### 學習率參數

| 參數 | 描述 |
|-----------|-------------|
| `lr` | 基礎學習率 |
| `lr_scheduler_name` | "constant", "cosineannealing" 等 |
| `lr_warm_up_steps` | 學習率預熱 (Warmup) 步數 |
| `lr_decay_steps` | 學習率衰減步數 |

---

## SAETrainingRunner

執行訓練的主要類別。

### 基礎訓練

```python
from sae_lens import SAETrainingRunner, LanguageModelSAERunnerConfig

cfg = LanguageModelSAERunnerConfig(...)
runner = SAETrainingRunner(cfg)
sae = runner.run()
```

### 存取訓練指標

```python
# 訓練期間，紀錄至 W&B 的指標包含：
# - l0：平均活動特徵數
# - ce_loss_score：交叉熵恢復率 (Cross-entropy recovery)
# - mse_loss：重構損失 (Reconstruction loss)
# - l1_loss：稀疏性損失 (Sparsity loss)
# - dead_features：死亡特徵計數
```

---

## ActivationsStore

管理激發值的收集與批次處理。

### 基礎用法

```python
from sae_lens import ActivationsStore

store = ActivationsStore.from_sae(
    model=model,
    sae=sae,
    store_batch_size_prompts=8,
    train_batch_size_tokens=4096,
    n_batches_in_buffer=32,
    device="cuda",
)

# 獲取一批次激發值的 Token
activations = store.get_batch_tokens()
```

---

## HookedSAETransformer

將 SAE 與 TransformerLens 模型整合。

### 基礎用法

```python
from sae_lens import HookedSAETransformer

# 載入帶有 SAE 的模型
model = HookedSAETransformer.from_pretrained("gpt2-small")
model.add_sae(sae)

# 在迴圈中執行包含 SAE 的運算
output = model.run_with_saes(tokens, saes=[sae])

# 帶有 SAE 激發值的快取
output, cache = model.run_with_cache_with_saes(tokens, saes=[sae])
```

---

## SAE 架構

### 標準 (ReLU + L1)

```python
cfg = LanguageModelSAERunnerConfig(
    architecture="standard",
    activation_fn="relu",
    l1_coefficient=8e-5,
)
```

### Gated (閘控式)

```python
cfg = LanguageModelSAERunnerConfig(
    architecture="gated",
)
```

### TopK

```python
cfg = LanguageModelSAERunnerConfig(
    architecture="topk",
    activation_fn="topk",
    activation_fn_kwargs={"k": 50},  # 正好 50 個活動特徵
)
```

### JumpReLU (當前最先進)

```python
cfg = LanguageModelSAERunnerConfig(
    architecture="jumprelu",
)
```

---

## 工具函數

### 上傳至 HuggingFace

```python
from sae_lens import upload_saes_to_huggingface

upload_saes_to_huggingface(
    saes=[sae],
    repo_id="username/my-saes",
    token="hf_token",
)
```

### Neuronpedia 整合

```python
# 特徵可以在 Neuronpedia 上查看
# URL 格式：neuronpedia.org/{model}/{layer}-{sae_type}/{feature_id}
# 範例：neuronpedia.org/gpt2-small/8-res-jb/1234
```
