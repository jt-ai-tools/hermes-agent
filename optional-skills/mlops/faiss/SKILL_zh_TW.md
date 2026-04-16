---
name: faiss
description: Facebook 開發的用於稠密向量高效相似度搜尋與聚類的庫。支援數十億個向量、GPU 加速以及多種索引類型 (Flat, IVF, HNSW)。適用於快速 k-NN 搜尋、大規模向量檢索，或當您需要純粹的相似度搜尋而不需要元資料時使用。最適合高效能應用程式。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [faiss-cpu, faiss-gpu, numpy]
metadata:
  hermes:
    tags: [RAG, FAISS, 相似度搜尋, 向量搜尋, Facebook AI, GPU 加速, 十億級規模, K-NN, HNSW, 高效能, 大規模]

---

# FAISS - 高效相似度搜尋

Facebook AI 開發的用於十億級規模向量相似度搜尋的庫。

## 何時使用 FAISS

**在以下情況使用 FAISS：**
- 需要在大型向量資料集 (數百萬/數十億級) 上進行快速相似度搜尋
- 需要 GPU 加速
- 純粹的向量相似度 (不需要元資料過濾)
- 高吞吐量、低延遲至關重要
- 嵌入 (Embeddings) 的離線/批次處理

**指標**：
- **GitHub 星星數超過 31,700**
- 由 Meta/Facebook AI Research 開發
- **可處理數十億個向量**
- 使用 **C++** 編寫，並提供 Python 綁定

**改用替代方案**：
- **Chroma/Pinecone**：需要元資料過濾
- **Weaviate**：需要完整的資料庫功能
- **Annoy**：更簡單，功能較少

## 快速入門

### 安裝

```bash
# 僅 CPU
pip install faiss-cpu

# 具備 GPU 支援
pip install faiss-gpu
```

### 基本用法

```python
import faiss
import numpy as np

# 建立樣本資料 (1000 個向量，128 維度)
d = 128
nb = 1000
vectors = np.random.random((nb, d)).astype('float32')

# 建立索引
index = faiss.IndexFlatL2(d)  # 使用 L2 距離
index.add(vectors)             # 新增向量

# 搜尋
k = 5  # 尋找 5 個最近鄰
query = np.random.random((1, d)).astype('float32')
distances, indices = index.search(query, k)

print(f"Nearest neighbors: {indices}")
print(f"Distances: {distances}")
```

## 索引類型

### 1. Flat (精確搜尋)

```python
# L2 (歐幾里得) 距離
index = faiss.IndexFlatL2(d)

# 內積 (如果經過歸一化，則為餘弦相似度)
index = faiss.IndexFlatIP(d)

# 速度最慢，但最精確
```

### 2. IVF (Inverted File) - 快速近似搜尋

```python
# 建立量化器
quantizer = faiss.IndexFlatL2(d)

# 具備 100 個聚類中心 (clusters) 的 IVF 索引
nlist = 100
index = faiss.IndexIVFFlat(quantizer, d, nlist)

# 在資料上進行訓練
index.train(vectors)

# 新增向量
index.add(vectors)

# 搜尋 (nprobe = 要搜尋的聚類數量)
index.nprobe = 10
distances, indices = index.search(query, k)
```

### 3. HNSW (Hierarchical NSW) - 最佳品質與速度平衡

```python
# HNSW 索引
M = 32  # 每層的連接數
index = faiss.IndexHNSWFlat(d, M)

# 無需訓練
index.add(vectors)

# 搜尋
distances, indices = index.search(query, k)
```

### 4. 產品量化 (Product Quantization) - 記憶體效率高

```python
# PQ 可減少 16-32 倍的記憶體佔用
m = 8   # 子量化器數量
nbits = 8
index = faiss.IndexPQ(d, m, nbits)

# 訓練並新增
index.train(vectors)
index.add(vectors)
```

## 儲存與載入

```python
# 儲存索引
faiss.write_index(index, "large.index")

# 載入索引
index = faiss.read_index("large.index")

# 繼續使用
distances, indices = index.search(query, k)
```

## GPU 加速

```python
# 單 GPU
res = faiss.StandardGpuResources()
index_cpu = faiss.IndexFlatL2(d)
index_gpu = faiss.index_cpu_to_gpu(res, 0, index_cpu)  # 使用 GPU 0

# 多 GPU
index_gpu = faiss.index_cpu_to_all_gpus(index_cpu)

# 比 CPU 快 10-100 倍
```

## LangChain 整合

```python
from langchain_community.vectorstores import FAISS
from langchain_openai import OpenAIEmbeddings

# 建立 FAISS 向量儲存
vectorstore = FAISS.from_documents(docs, OpenAIEmbeddings())

# 儲存
vectorstore.save_local("faiss_index")

# 載入
vectorstore = FAISS.load_local(
    "faiss_index",
    OpenAIEmbeddings(),
    allow_dangerous_deserialization=True
)

# 搜尋
results = vectorstore.similarity_search("query", k=5)
```

## LlamaIndex 整合

```python
from llama_index.vector_stores.faiss import FaissVectorStore
import faiss

# 建立 FAISS 索引
d = 1536
faiss_index = faiss.IndexFlatL2(d)

vector_store = FaissVectorStore(faiss_index=faiss_index)
```

## 最佳實踐

1. **選擇正確的索引類型** - <10K 使用 Flat, 10K-1M 使用 IVF, 追求品質則使用 HNSW
2. **為餘弦相似度進行歸一化** - 使用 IndexFlatIP 並配合歸一化後的向量
3. **針對大型資料集使用 GPU** - 速度快 10-100 倍
4. **儲存已訓練好的索引** - 訓練過程非常耗時
5. **調優 nprobe/ef_search** - 平衡速度與精確度
6. **監控記憶體** - 針對大型資料集使用 PQ
7. **批次查詢** - 獲得更好的 GPU 利用率

## 效能

| 索引類型 | 構建時間 | 搜尋時間 | 記憶體佔用 | 精確度 |
|------------|------------|-------------|--------|----------|
| Flat | 快 | 慢 | 高 | 100% |
| IVF | 中 | 快 | 中 | 95-99% |
| HNSW | 慢 | 最快 | 高 | 99% |
| PQ | 中 | 快 | 低 | 90-95% |

## 資源

- **GitHub**: https://github.com/facebookresearch/faiss ⭐ 31,700+
- **Wiki**: https://github.com/facebookresearch/faiss/wiki
- **授權**: MIT
