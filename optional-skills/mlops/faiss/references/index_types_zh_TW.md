# FAISS 索引類型指南

選擇與使用 FAISS 索引類型的完整指南。

## 索引選取指南

| 資料集大小 | 索引類型 | 訓練 | 精確度 | 速度 |
|--------------|------------|----------|----------|-------|
| < 1 萬 | Flat | 否 | 100% | 慢 |
| 1 萬 - 100 萬 | IVF | 是 | 95-99% | 快 |
| 100 萬 - 1,000 萬 | HNSW | 否 | 99% | 最快 |
| > 1,000 萬 | IVF+PQ | 是 | 90-95% | 快且低記憶體 |

## Flat 索引（精確搜尋）

### IndexFlatL2 - L2 (歐幾里得) 距離

```python
import faiss
import numpy as np

d = 128  # 維度
index = faiss.IndexFlatL2(d)

# 加入向量
vectors = np.random.random((1000, d)).astype('float32')
index.add(vectors)

# 搜尋
k = 5
query = np.random.random((1, d)).astype('float32')
distances, indices = index.search(query, k)
```

**適用情境：**
- 資料集 < 10,000 個向量
- 需要 100% 精確度
- 作為基準測試 (Baseline)

### IndexFlatIP - 內積 (Cosine 相似度)

```python
# 對於 Cosine 相似度，請先將向量正規化
import faiss

d = 128
index = faiss.IndexFlatIP(d)

# 正規化向量（Cosine 相似度必須執行）
faiss.normalize_L2(vectors)
index.add(vectors)

# 搜尋
faiss.normalize_L2(query)
distances, indices = index.search(query, k)
```

**適用情境：**
- 需要 Cosine 相似度
- 推薦系統
- 文字嵌入 (Text embeddings)

## IVF 索引（倒排檔案）

### IndexIVFFlat - 基於分群的搜尋

```python
# 建立量化器
quantizer = faiss.IndexFlatL2(d)

# 建立具有 100 個分群的 IVF 索引
nlist = 100  # 分群數量
index = faiss.IndexIVFFlat(quantizer, d, nlist)

# 對資料進行訓練（必須執行！）
index.train(vectors)

# 加入向量
index.add(vectors)

# 搜尋 (nprobe = 要搜尋的分群數)
index.nprobe = 10  # 搜尋最近的 10 個分群
distances, indices = index.search(query, k)
```

**參數：**
- `nlist`：分群數量（建議為 √N 到 4√N）
- `nprobe`：要搜尋的分群數（1 到 nlist，越高越精確）

**適用情境：**
- 資料集 1 萬 - 100 萬個向量
- 需要快速的近似搜尋
- 可以接受訓練所需的時間

### 微調 nprobe

```python
# 測試不同的 nprobe 值
for nprobe in [1, 5, 10, 20, 50]:
    index.nprobe = nprobe
    distances, indices = index.search(query, k)
    # 衡量召回率 (Recall) 與速度之間的權衡
```

**準則：**
- `nprobe=1`：最快，召回率約 50%
- `nprobe=10`：良好的平衡，召回率約 95%
- `nprobe=nlist`：精確搜尋（與 Flat 相同）

## HNSW 索引（基於圖形）

### IndexHNSWFlat - 階層式可導航小世界 (Hierarchical NSW)

```python
# HNSW 索引
M = 32  # 每層的連接數 (16-64)
index = faiss.IndexHNSWFlat(d, M)

# 選配：設置 ef_construction（建置期間參數）
index.hnsw.efConstruction = 40  # 越高 = 品質越好，建置越慢

# 加入向量（不需要訓練！）
index.add(vectors)

# 搜尋
index.hnsw.efSearch = 16  # 搜尋期間參數
distances, indices = index.search(query, k)
```

**參數：**
- `M`：每層的連接數（16-64，預設為 32）
- `efConstruction`：建置品質（40-200，越高越好）
- `efSearch`：搜尋品質（16-512，越高越精確）

**適用情境：**
- 需要最高品質的近似搜尋
- 可以負擔較高的記憶體使用量（更多連接）
- 資料集 100 萬 - 1,000 萬個向量

## PQ 索引（乘積量化）

### IndexPQ - 高記憶體效率

```python
# PQ 可將記憶體減少 16-32 倍
m = 8   # 子量化器數量（必須可整除 d）
nbits = 8  # 每個子量化器的位元數

index = faiss.IndexPQ(d, m, nbits)

# 訓練（必須執行！）
index.train(vectors)

# 加入向量
index.add(vectors)

# 搜尋
distances, indices = index.search(query, k)
```

**參數：**
- `m`：子量化器（d 必須能被 m 整除）
- `nbits`：每個代碼的位元數（8 或 16）

**記憶體節省：**
- 原始：d × 4 位元組 (float32)
- PQ：m 位元組
- 壓縮率：4d/m

**適用情境：**
- 記憶體有限
- 大型資料集（> 1,000 萬個向量）
- 可接受約 90-95% 的精確度

### IndexIVFPQ - IVF + PQ 組合

```python
# 最適合極大型資料集
nlist = 4096
m = 8
nbits = 8

quantizer = faiss.IndexFlatL2(d)
index = faiss.IndexIVFPQ(quantizer, d, nlist, m, nbits)

# 訓練
index.train(vectors)
index.add(vectors)

# 搜尋
index.nprobe = 32
distances, indices = index.search(query, k)
```

**適用情境：**
- 資料集 > 1,000 萬個向量
- 需要快速搜尋與低記憶體消耗
- 可接受 90-95% 的精確度

## GPU 索引

### 單一 GPU

```python
import faiss

# 建立 CPU 索引
index_cpu = faiss.IndexFlatL2(d)

# 移至 GPU
res = faiss.StandardGpuResources()  # GPU 資源
index_gpu = faiss.index_cpu_to_gpu(res, 0, index_cpu)  # GPU 0

# 正常使用
index_gpu.add(vectors)
distances, indices = index_gpu.search(query, k)
```

### 多 GPU

```python
# 使用所有可用的 GPU
index_gpu = faiss.index_cpu_to_all_gpus(index_cpu)

# 或指定特定的 GPU
gpus = [0, 1, 2, 3]  # 使用 GPU 0-3
index_gpu = faiss.index_cpu_to_gpus_list(index_cpu, gpus)
```

**加速效果：**
- 單一 GPU：比 CPU 快 10-50 倍
- 多 GPU：近乎線性擴展

## 索引工廠 (Index Factory)

```python
# 使用字串描述符輕鬆建立索引
index = faiss.index_factory(d, "IVF100,Flat")
index = faiss.index_factory(d, "HNSW32")
index = faiss.index_factory(d, "IVF4096,PQ8")

# 訓練與使用
index.train(vectors)
index.add(vectors)
```

**常見描述符：**
- `"Flat"`：精確搜尋
- `"IVF100,Flat"`：具有 100 個分群的 IVF
- `"HNSW32"`：M=32 的 HNSW
- `"IVF4096,PQ8"`：IVF + PQ 壓縮

## 效能比較

### 搜尋速度 (100 萬個向量，k=10)

| 索引 | 建置時間 | 搜尋時間 | 記憶體 | 召回率 |
|-------|------------|-------------|--------|--------|
| Flat | 0s | 50ms | 512 MB | 100% |
| IVF100 | 5s | 2ms | 512 MB | 95% |
| HNSW32 | 60s | 1ms | 1GB | 99% |
| IVF4096+PQ8 | 30s | 3ms | 32 MB | 90% |

*使用 CPU (16 核心)，128 維向量*

## 最佳實踐

1. **從 Flat 開始** - 作為比較的基準
2. **中型資料集使用 IVF** - 良好的平衡
3. **高品質需求使用 HNSW** - 如果記憶體允許
4. **大型資料集加入 PQ 以節省記憶體**
5. **向量數 > 10 萬建議使用 GPU** - 加速 10-50 倍
6. **微調 nprobe/efSearch** - 權衡速度與精確度
7. **在具代表性的資料上訓練** - 獲得更好的分群效果
8. **儲存訓練好的索引** - 避免重複訓練

## 資源

- **Wiki**：https://github.com/facebookresearch/faiss/wiki
- **論文**：https://arxiv.org/abs/1702.08734
