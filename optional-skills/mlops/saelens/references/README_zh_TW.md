# SAELens 參考文件

本目錄包含 SAELens 的完整參考資料。

## 內容

- [api.md](api.md) - SAE、TrainingSAE 及配置類別的完整 API 參考
- [tutorials_zh_TW.md](tutorials_zh_TW.md) - 訓練與分析 SAE 的逐步教學
- [papers.md](papers.md) - 稀疏自編碼器 (Sparse Autoencoders) 的關鍵研究論文

## 快速連結

- **GitHub 儲存庫**: https://github.com/jbloomAus/SAELens
- **Neuronpedia**: https://neuronpedia.org (瀏覽預訓練的 SAE 特徵)
- **HuggingFace SAEs**: 搜尋標籤 `saelens`

## 安裝

```bash
pip install sae-lens
```

系統需求：Python 3.10+、transformer-lens>=2.0.0

## 基本用法

```python
from transformer_lens import HookedTransformer
from sae_lens import SAE

# 載入模型與 SAE
model = HookedTransformer.from_pretrained("gpt2-small", device="cuda")
sae, cfg_dict, sparsity = SAE.from_pretrained(
    release="gpt2-small-res-jb",
    sae_id="blocks.8.hook_resid_pre",
    device="cuda"
)

# 將激活值編碼為稀疏特徵
tokens = model.to_tokens("Hello world")
_, cache = model.run_with_cache(tokens)
activations = cache["resid_pre", 8]

features = sae.encode(activations)  # 稀疏特徵激活值
reconstructed = sae.decode(features)  # 重建的激活值
```

## 核心概念

### 稀疏自編碼器 (Sparse Autoencoders)
SAE 將稠密的神经激活值分解為稀疏且可解釋的特徵：
- **編碼器 (Encoder)**：將 d_model 映射到 d_sae（通常為 4-16 倍擴展）
- **ReLU/TopK**：強制執行稀疏性
- **解碼器 (Decoder)**：重建原始激活值

### 訓練損失 (Training Loss)
`損失 = MSE(原始, 重建) + L1_係數 × L1(特徵)`

### 關鍵指標
- **L0**：平均啟動特徵數（目標：50-200）
- **CE 損失分數 (CE Loss Score)**：與原始模型相比恢復的交叉熵（目標：80-95%）
- **死特徵 (Dead Features)**：從未啟動的特徵（目標：<5%）

## 可用的預訓練 SAE

| 發行版本 (Release) | 模型 | 說明 |
|---------|-------|-------------|
| `gpt2-small-res-jb` | GPT-2 Small | 殘差流 (Residual stream) SAEs |
| `gemma-2b-res` | Gemma 2B | 殘差流 (Residual stream) SAEs |
| 其他 | 搜尋 HuggingFace | 社群訓練的 SAEs |
