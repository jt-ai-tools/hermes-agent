---
name: pinecone
description: 用於生產級 AI 應用的託管式向量資料庫。完全託管、自動擴展，支援混合搜尋（稠密 + 稀疏）、元資料過濾和命名空間。具備低延遲（p95 < 100ms）。適用於生產級 RAG、推薦系統或大規模語義搜尋。是無伺服器、託管式基礎設施的最佳選擇。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [pinecone-client]
metadata:
  hermes:
    tags: [RAG, Pinecone, Vector Database, Managed Service, Serverless, Hybrid Search, Production, Auto-Scaling, Low Latency, Recommendations]

---

# Pinecone - 託管式向量資料庫

專為生產級 AI 應用設計的向量資料庫。

## 何時使用 Pinecone

**適用場景：**
- 需要託管式、無伺服器 (serverless) 的向量資料庫
- 生產級 RAG 應用
- 需要自動擴展能力
- 對低延遲有嚴格要求（<100ms）
- 不想自行管理基礎設施
- 需要混合搜尋（混合稠密與稀疏向量）

**效能指標：**
- 完全託管的 SaaS 服務
- 可自動擴展至數十億個向量
- **p95 延遲 < 100ms**
- 99.9% 運作時間 SLA

**可考慮的替代方案：**
- **Chroma**：可自行託管的開源方案
- **FAISS**：適用於離線、純相似度搜尋
- **Weaviate**：功能更豐富的自行託管方案

## 快速入門

### 安裝

```bash
pip install pinecone-client
```

### 基礎用法

```python
from pinecone import Pinecone, ServerlessSpec

# 初始化
pc = Pinecone(api_key="your-api-key")

# 建立索引 (Index)
pc.create_index(
    name="my-index",
    dimension=1536,  # 必須與嵌入模型維度匹配
    metric="cosine",  # 可選 "euclidean", "dotproduct"
    spec=ServerlessSpec(cloud="aws", region="us-east-1")
)

# 連接至索引
index = pc.Index("my-index")

# 更新或插入 (Upsert) 向量
index.upsert(vectors=[
    {"id": "vec1", "values": [0.1, 0.2, ...], "metadata": {"category": "A"}},
    {"id": "vec2", "values": [0.3, 0.4, ...], "metadata": {"category": "B"}}
])

# 查詢
results = index.query(
    vector=[0.1, 0.2, ...],
    top_k=5,
    include_metadata=True
)

print(results["matches"])
```

## 核心操作

### 建立索引

```python
# 無伺服器 (Serverless，建議使用)
pc.create_index(
    name="my-index",
    dimension=1536,
    metric="cosine",
    spec=ServerlessSpec(
        cloud="aws",         # 或 "gcp", "azure"
        region="us-east-1"
    )
)

# 基於 Pod (用於追求一致效能)
from pinecone import PodSpec

pc.create_index(
    name="my-index",
    dimension=1536,
    metric="cosine",
    spec=PodSpec(
        environment="us-east1-gcp",
        pod_type="p1.x1"
    )
)
```

### 更新/插入 (Upsert) 向量

```python
# 單次更新/插入
index.upsert(vectors=[
    {
        "id": "doc1",
        "values": [0.1, 0.2, ...],  # 1536 維
        "metadata": {
            "text": "文件內容",
            "category": "tutorial",
            "timestamp": "2025-01-01"
        }
    }
])

# 批次更新/插入 (建議使用)
vectors = [
    {"id": f"vec{i}", "values": embedding, "metadata": metadata}
    for i, (embedding, metadata) in enumerate(zip(embeddings, metadatas))
]

index.upsert(vectors=vectors, batch_size=100)
```

### 查詢向量

```python
# 基礎查詢
results = index.query(
    vector=[0.1, 0.2, ...],
    top_k=10,
    include_metadata=True,
    include_values=False
)

# 帶有元資料過濾 (Metadata filtering)
results = index.query(
    vector=[0.1, 0.2, ...],
    top_k=5,
    filter={"category": {"$eq": "tutorial"}}
)

# 命名空間 (Namespace) 查詢
results = index.query(
    vector=[0.1, 0.2, ...],
    top_k=5,
    namespace="production"
)

# 存取結果
for match in results["matches"]:
    print(f"ID: {match['id']}")
    print(f"Score: {match['score']}")
    print(f"Metadata: {match['metadata']}")
```

### 元資料過濾 (Metadata filtering)

```python
# 精確匹配
filter = {"category": "tutorial"}

# 比較運算
filter = {"price": {"$gte": 100}}  # 支援 $gt, $gte, $lt, $lte, $ne

# 邏輯運算子
filter = {
    "$and": [
        {"category": "tutorial"},
        {"difficulty": {"$lte": 3}}
    ]
}  # 亦支援 $or

# In 運算子
filter = {"tags": {"$in": ["python", "ml"]}}
```

## 命名空間 (Namespaces)

```python
# 透過命名空間分割資料
index.upsert(
    vectors=[{"id": "vec1", "values": [...]}],
    namespace="user-123"
)

# 查詢特定命名空間
results = index.query(
    vector=[...],
    namespace="user-123",
    top_k=5
)

# 列出命名空間
stats = index.describe_index_stats()
print(stats['namespaces'])
```

## 混合搜尋 (Hybrid search，稠密 + 稀疏)

```python
# 使用稀疏向量更新/插入
index.upsert(vectors=[
    {
        "id": "doc1",
        "values": [0.1, 0.2, ...],  # 稠密向量
        "sparse_values": {
            "indices": [10, 45, 123],  # Token IDs
            "values": [0.5, 0.3, 0.8]   # TF-IDF 分數
        },
        "metadata": {"text": "..."}
    }
])

# 混合查詢
results = index.query(
    vector=[0.1, 0.2, ...],
    sparse_vector={
        "indices": [10, 45],
        "values": [0.5, 0.3]
    },
    top_k=5,
    alpha=0.5  # 0=純稀疏, 1=純稠密, 0.5=混合
)
```

## LangChain 整合

```python
from langchain_pinecone import PineconeVectorStore
from langchain_openai import OpenAIEmbeddings

# 建立向量儲存
vectorstore = PineconeVectorStore.from_documents(
    documents=docs,
    embedding=OpenAIEmbeddings(),
    index_name="my-index"
)

# 查詢
results = vectorstore.similarity_search("query", k=5)

# 帶元資料過濾
results = vectorstore.similarity_search(
    "query",
    k=5,
    filter={"category": "tutorial"}
)

# 作為檢索器 (Retriever)
retriever = vectorstore.as_retriever(search_kwargs={"k": 10})
```

## LlamaIndex 整合

```python
from llama_index.vector_stores.pinecone import PineconeVectorStore

# 連接 Pinecone
pc = Pinecone(api_key="your-key")
pinecone_index = pc.Index("my-index")

# 建立向量儲存
vector_store = PineconeVectorStore(pinecone_index=pinecone_index)

# 在 LlamaIndex 中使用
from llama_index.core import StorageContext, VectorStoreIndex

storage_context = StorageContext.from_defaults(vector_store=vector_store)
index = VectorStoreIndex.from_documents(documents, storage_context=storage_context)
```

## 索引管理

```python
# 列出所有索引
indexes = pc.list_indexes()

# 描述索引詳情
index_info = pc.describe_index("my-index")
print(index_info)

# 獲取索引統計資訊
stats = index.describe_index_stats()
print(f"向量總數: {stats['total_vector_count']}")
print(f"命名空間: {stats['namespaces']}")

# 刪除索引
pc.delete_index("my-index")
```

## 刪除向量

```python
# 依 ID 刪除
index.delete(ids=["vec1", "vec2"])

# 依過濾條件刪除
index.delete(filter={"category": "old"})

# 刪除命名空間中的所有向量
index.delete(delete_all=True, namespace="test")

# 刪除索引中的所有向量
index.delete(delete_all=True)
```

## 最佳實踐

1. **優先使用 Serverless** —— 可自動擴展且更具成本效益
2. **批次更新/插入** —— 效率更高（建議每批 100-200 個）
3. **添加元資料** —— 以便進行過濾
4. **使用命名空間** —— 根據使用者或租戶隔離資料
5. **監控使用情況** —— 查看 Pinecone 控制面板
6. **優化過濾條件** —— 為經常過濾的欄位建立索引
7. **使用免費層測試** —— 支援 1 個索引，10 萬個向量免費
8. **使用混合搜尋** —— 獲取更好的搜尋品質
9. **設定合適的維度** —— 必須與嵌入模型匹配
10. **定期備份** —— 匯出重要資料

## 效能

| 操作 | 延遲 | 備註 |
|-----------|---------|-------|
| 更新/插入 | ~50-100ms | 每次批次處理 |
| 查詢 (p50) | ~50ms | 取決於索引大小 |
| 查詢 (p95) | ~100ms | SLA 目標值 |
| 元資料過濾 | ~+10-20ms | 額外開銷 |

## 價格 (截至 2025 年)

**Serverless 模式：**
- 每百萬讀取單元 (Read Units)：$0.096
- 每百萬寫入單元 (Write Units)：$0.06
- 每 GB 儲存費用/月：$0.06

**免費層 (Free Tier)：**
- 1 個無伺服器索引
- 10 萬個向量 (1536 維)
- 非常適合原型開發

## 相關資源

- **官方網站**：https://www.pinecone.io
- **文件**：https://docs.pinecone.io
- **控制台**：https://app.pinecone.io
- **定價詳細資訊**：https://www.pinecone.io/pricing
