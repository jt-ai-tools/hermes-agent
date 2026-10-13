# OBLITERATUS 分析模組 — 參考指南

OBLITERATUS 包含 28 個分析模組，用於對 LLM 的拒絕行為進行機械解釋性 (mechanistic interpretability) 分析。這些模組有助於在執行 abliteration 之前，了解拒絕行為是如何以及在何處被編碼的。

---

## 核心分析 (優先執行)

### 1. 對齊烙印偵測 (`alignment_imprint.py`)
識別模型是透過 DPO、RLHF、CAI 還是 SFT 進行訓練的。這將決定哪種提取策略效果最佳。

### 2. 概念錐幾何 (`concept_geometry.py`)
判斷拒絕行為是單一線性方向還是多面體錐 (由多個機制組成的集合)。單一方向的模型對 `basic` 方法反應良好；多面體模型則需要 `advanced` 或 `surgical` 方法。

### 3. 拒絕行為 Logit Lens (`logit_lens.py`)
透過將中間層的表示解碼到 token 空間，識別模型是在哪一層「決定」拒絕。

### 4. 銜尾蛇 (Ouroboros) 偵測 (`anti_ouroboros.py`)
識別模型是否在切除拒絕行為後嘗試進行「自我修復」。報告會提供風險評分 (0-1)，高分代表需要額外的細化處理 (refinement passes)。

### 5. 因果追蹤 (`causal_tracing.py`)
使用激活補丁 (activation patching) 來識別哪些組件 (層、頭、MLP) 對拒絕行為具有因果必要性。

---

## 幾何分析

### 6. 跨層對齊 (`cross_layer.py`)
測量不同層之間的拒絕方向對齊程度。高度對齊意味著拒絕訊號是一致的；低對齊則表示存在特定於層的機制。

### 7. 殘差流分解 (`residual_stream.py`)
將殘差流分解為注意力機制與 MLP 的貢獻，以了解哪種類型的組件對拒絕行為貢獻較大。

### 8. 黎曼流形幾何 (`riemannian_manifold.py`)
分析拒絕方向附近權重流形的曲率與幾何。這有助於判斷可以在不損害流形結構的情況下，施加多強強度的投影。

### 9. 白化 SVD (`whitened_svd.py`)
協方差歸一化的 SVD 提取，將防護欄訊號從自然激活變異中分離出來。對於激活變異較大的模型，這比標準 SVD 更精確。

### 10. 概念錐幾何 (擴展版)
繪製拒絕行為的完整多面體結構，包括錐角、面數和交集模式。

---

## 探測與分類

### 11. 激活探測 (`activation_probing.py`)
切除後的驗證 — 在 abliteration 後探測殘留的拒絕概念，以確保完全移除。

### 12. 探測分類器 (`probing_classifiers.py`)
訓練線性分類器來偵測激活值中的拒絕行為。用於操作前 (驗證拒絕行為存在) 與操作後 (驗證行為已消失)。

### 13. 激活補丁 (`activation_patching.py`)
交換干預 — 在「拒絕」與「配合」的執行路徑之間交換激活值，以識別因果組件。

### 14. Tuned Lens (`tuned_lens.py`)
Logit Lens 的訓練版本，透過為每一層學習仿射變換，提供更準確的逐層解碼。

### 15. 多 Token 位置分析 (`multi_token_position.py`)
分析多個 token 位置的拒絕訊號，而不僅僅是最後一個 token。對於將拒絕行為分佈在整個序列中的模型來說非常重要。

---

## Abliteration 與操作

### 16. 基於 SAE 的 Abliteration (`sae_abliteration.py`)
使用稀疏自動編碼器 (SAE) 特徵來識別並移除特定的拒絕特徵。比基於方向的方法更精準。

### 17. 引導向量 (`steering_vectors.py`)
建立並應用推理時的引導向量，用於可逆的拒絕行為修改。包含 `SteeringVectorFactory` 與 `SteeringHookManager`。

### 18. LEACE 概念擦除 (`leace.py`)
LEACE (Linear Erasure via Closed-form Estimation) — 數學上的最佳線性概念移除。可作為分析模組或方向提取方法使用。

### 19. 稀疏手術 (`sparse_surgery.py`)
針對個別神經元與權重矩陣項目的高精度權重修改，而非針對整個方向。

### 20. 條件式 Abliteration (`conditional_abliteration.py`)
有針對性的移除，僅影響特定的拒絕類別，同時保留其他類別 (例如：移除關於武器的拒絕行為，但保留關於兒少性虐待 (CSAM) 的拒絕行為)。

---

## 遷移與魯棒性

### 21. 跨模型遷移 (`cross_model_transfer.py`)
測試從一個模型提取的拒絕方向是否可以遷移到另一個架構。衡量防護欄方向的通用性。

### 22. 防禦魯棒性 (`defense_robustness.py`)
評估 abliteration 在面對各種防禦機制與重新對齊嘗試時的魯棒性。

### 23. 光譜認證 (`spectral_certification.py`)
透過對投影進行光譜分析，提供關於拒絕行為移除完整性的數學邊界。

### 24. Wasserstein 最佳提取 (`wasserstein_optimal.py`)
使用最佳運輸理論進行更精確的方向提取，以最小化分佈偏移。

### 25. Wasserstein 遷移 (`wasserstein_transfer.py`)
使用 Wasserstein 距離在模型之間進行分佈遷移，用於跨架構的拒絕方向映射。

---

## 進階 / 研究

### 26. 貝氏核投影 (`bayesian_kernel_projection.py`)
機率性特徵映射，用於估算拒絕方向識別的不確定性。

### 27. 跨模型通用性指數
衡量防護欄方向是否能在不同的模型架構與訓練體系中通用。

### 28. 視覺化 (`visualization.py`)
適用於所有分析模組的繪圖與圖表工具。生成熱圖、方向圖與逐層分析圖表。

---

## 執行分析

### 透過 CLI
```bash
# 從 YAML 配置執行分析
obliteratus run analysis-study.yaml --preset quick

# 可用的研究預設設定：
# quick     — 快速完整性檢查 (2-3 個模組)
# full      — 所有核心 + 幾何分析
# jailbreak — 拒絕電路定位
# knowledge — 知識保留分析
# robustness — 壓力測試 / 防禦評估
```

### 透過 YAML 配置
完整的範例請參閱 `templates/analysis-study.yaml` 範本。
載入命令：`skill_view(name="obliteratus", file_path="templates/analysis-study.yaml")`
