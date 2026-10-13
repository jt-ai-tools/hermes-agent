# 去重 (Deduplication) 指南

精確去重、模糊去重與語義去重的完整指南。

## 精確去重 (Exact deduplication)

移除內容完全相同的檔案。

```python
from nemo_curator.modules import ExactDuplicates

# 精確去重
exact_dedup = ExactDuplicates(
    id_field="id",
    text_field="text",
    hash_method="md5"  # 或 "sha256"
)

deduped = exact_dedup(dataset)
```

**效能**：GPU 處理速度比 CPU 快約 16 倍。

## 模糊去重 (Fuzzy deduplication)

使用 MinHash + LSH 移除內容相近的檔案。

```python
from nemo_curator.modules import FuzzyDuplicates

fuzzy_dedup = FuzzyDuplicates(
    id_field="id",
    text_field="text",
    num_hashes=260,        # MinHash 排列組合 (越多越精確)
    num_buckets=20,        # LSH 桶數 (越多速度越快，但召回率較低)
    hash_method="md5",
    jaccard_threshold=0.8  # 相似度閾值
)

deduped = fuzzy_dedup(dataset)
```

**參數**：
- `num_hashes`：128-512 (預設 260)
- `num_buckets`：10-50 (預設 20)
- `jaccard_threshold`：0.7-0.9 (預設 0.8)

**效能**：在 8TB 資料集上速度快 16 倍 (從 120 小時縮短至 7.5 小時)。

## 語義去重 (Semantic deduplication)

使用嵌入 (Embeddings) 移除語義相似的檔案。

```python
from nemo_curator.modules import SemanticDuplicates

semantic_dedup = SemanticDuplicates(
    id_field="id",
    text_field="text",
    embedding_model="sentence-transformers/all-MiniLM-L6-v2",
    embedding_batch_size=256,
    threshold=0.85,  # 餘弦相似度 (Cosine similarity) 閾值
    device="cuda"
)

deduped = semantic_dedup(dataset)
```

**模型**：
- `all-MiniLM-L6-v2`：速度快，384 維。
- `all-mpnet-base-v2`：品質更好，768 維。
- 支援自定義模型。

## 比較

| 方法 | 速度 | 召回率 (Recall) | 使用情境 |
|--------|-------|--------|----------|
| 精確 | 最快 | 100% | 僅針對完全相符的內容 |
| 模糊 | 快 | ~95% | 近似重複 (建議使用) |
| 語義 | 慢 | ~90% | 換句話說、改寫內容 |

## 最佳實踐

1. **先進行精確去重** - 移除明顯的重複內容。
2. **對大型資料集使用模糊去重** - 速度與品質的最佳平衡。
3. **對高價值資料使用語義去重** - 成本高昂但最徹底。
4. **必須使用 GPU 加速** - 可提升 10-16 倍速度。
