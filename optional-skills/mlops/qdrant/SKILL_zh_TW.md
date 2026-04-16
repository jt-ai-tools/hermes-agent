---
name: qdrant-vector-search
description: 用於 RAG 和語義搜尋的高效能向量相似度搜尋引擎。在建構需要快速最近鄰搜尋、具備過濾功能的混合搜尋或具備 Rust 效能的可擴展向量儲存生產級 RAG 系統時使用。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [qdrant-client>=1.12.0]
metadata:
  hermes:
    tags: [RAG, 向量搜尋, Qdrant, 語義搜尋, 嵌入, 相似度搜尋, HNSW, 生產環境, 分佈式]

---

# Qdrant - 向量相似度搜尋引擎

使用 Rust 編寫的高效能向量資料庫，適用於生產級 RAG 和語義搜尋。

## 何時使用 Qdrant

**在以下情況使用 Qdrant：**
- 建構需要低延遲的生產級 RAG 系統
- 需要混合搜尋 (向量 + 元資料過濾)
- 需要透過分片 (sharding)/複製 (replication) 進行水平擴展
- 想要完全控制資料的在地部署 (on-premise)
- 每個記錄需要多個向量儲存 (稠密 + 稀疏)
- 建構即時推薦系統

**關鍵功能：**
- **Rust 驅動**：記憶體安全、高效能
- **豐富的過濾功能**：在搜尋過程中依任何 Payload 欄位進行過濾
- **多種向量支援**：支援單一資料點的多個稠密、稀疏向量
- **量化 (Quantization)**：標量、乘積、二進制量化以提高記憶體效率
- **分佈式**：Raft 共識、分片、複製
- **REST + gRPC**：兩種 API 皆具備完整的特性對等

**改用替代方案：**
- **Chroma**：更簡單的設定，適用於嵌入式案例
- **FAISS**：極致的原生速度，適用於研究/批次處理
- **Pinecone**：偏好完全託管、零維運的方案
- **Weaviate**：偏好 GraphQL、具備內建向量化器

## 快速入門

### 安裝

```bash
# Python 用戶端
pip install qdrant-client

# Docker (推薦開發時使用)
docker run -p 6333:6333 -p 6334:6334 qdrant/qdrant

# 具備持久化儲存的 Docker
docker run -p 6333:6333 -p 6334:6334 \
    -v $(pwd)/qdrant_storage:/qdrant/storage \
    qdrant/qdrant
```

### 基本用法

```python
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct

# 連接至 Qdrant
client = QdrantClient(host="localhost", port=6333)

# 建立集合 (Collection)
client.create_collection(
    collection_name="documents",
    vectors_config=VectorParams(size=384, distance=Distance.COSINE)
)

# 插入帶有 Payload 的向量
client.upsert(
    collection_name="documents",
    points=[
        PointStruct(
            id=1,
            vector=[0.1, 0.2, ...],  # 384 維向量
            payload={"title": "Doc 1", "category": "tech"}
        ),
        PointStruct(
            id=2,
            vector=[0.3, 0.4, ...],
            payload={"title": "Doc 2", "category": "science"}
        )
    ]
)

# 帶過濾條件的搜尋
results = client.search(
    collection_name="documents",
    query_vector=[0.15, 0.25, ...],
    query_filter={
        "must": [{"key": "category", "match": {"value": "tech"}}]
    },
    limit=10
)

for point in results:
    print(f"ID: {point.id}, Score: {point.score}, Payload: {point.payload}")
```

## 核心概念

### Points - 基礎資料單位

```python
from qdrant_client.models import PointStruct

# Point = ID + 向量 + Payload
point = PointStruct(
    id=123,                              # 整數或 UUID 字串
    vector=[0.1, 0.2, 0.3, ...],        # 稠密向量
    payload={                            # 任意 JSON 元資料
        "title": "文件標題",
        "category": "tech",
        "timestamp": 1699900000,
        "tags": ["python", "ml"]
    }
)

# 批次 Upsert (推薦)
client.upsert(
    collection_name="documents",
    points=[point1, point2, point3],
    wait=True  # 等待索引完成
)
```

### Collections - 向量容器

```python
from qdrant_client.models import VectorParams, Distance, HnswConfigDiff

# 建立具備 HNSW 配置的集合
client.create_collection(
    collection_name="documents",
    vectors_config=VectorParams(
        size=384,                        # 向量維度
        distance=Distance.COSINE         # COSINE, EUCLID, DOT, MANHATTAN
    ),
    hnsw_config=HnswConfigDiff(
        m=16,                            # 每個節點的連接數 (預設 16)
        ef_construct=100,                # 構建時的精準度 (預設 100)
        full_scan_threshold=10000        # 低於此值則切換為暴力搜尋
    ),
    on_disk_payload=True                 # 將 Payload 儲存於硬碟
)

# 取得集合資訊
info = client.get_collection("documents")
print(f"Points: {info.points_count}, Vectors: {info.vectors_count}")
```

### 距離度量 (Distance metrics)

| 度量指標 | 使用案例 | 範圍 |
|--------|----------|-------|
| `COSINE` | 文本嵌入、歸一化向量 | 0 到 2 |
| `EUCLID` | 空間資料、影像特徵 | 0 到 ∞ |
| `DOT` | 推薦系統、未歸一化向量 | -∞ 到 ∞ |
| `MANHATTAN` | 稀疏特徵、離散資料 | 0 到 ∞ |

## 搜尋操作

### 基礎搜尋

```python
# 簡單的最近鄰搜尋
results = client.search(
    collection_name="documents",
    query_vector=[0.1, 0.2, ...],
    limit=10,
    with_payload=True,
    with_vectors=False  # 不傳回向量 (速度較快)
)
```

### 過濾搜尋

```python
from qdrant_client.models import Filter, FieldCondition, MatchValue, Range

# 複雜的過濾條件
results = client.search(
    collection_name="documents",
    query_vector=query_embedding,
    query_filter=Filter(
        must=[
            FieldCondition(key="category", match=MatchValue(value="tech")),
            FieldCondition(key="timestamp", range=Range(gte=1699000000))
        ],
        must_not=[
            FieldCondition(key="status", match=MatchValue(value="archived"))
        ]
    ),
    limit=10
)

# 簡寫過濾語法
results = client.search(
    collection_name="documents",
    query_vector=query_embedding,
    query_filter={
        "must": [
            {"key": "category", "match": {"value": "tech"}},
            {"key": "price", "range": {"gte": 10, "lte": 100}}
        ]
    },
    limit=10
)
```

### 批次搜尋

```python
from qdrant_client.models import SearchRequest

# 在單一請求中包含多個查詢
results = client.search_batch(
    collection_name="documents",
    requests=[
        SearchRequest(vector=[0.1, ...], limit=5),
        SearchRequest(vector=[0.2, ...], limit=5, filter={"must": [...]}),
        SearchRequest(vector=[0.3, ...], limit=10)
    ]
)
```

## RAG 整合

### 搭配 sentence-transformers

```python
from sentence_transformers import SentenceTransformer
from qdrant_client import QdrantClient
from qdrant_client.models import VectorParams, Distance, PointStruct

# 初始化
encoder = SentenceTransformer("all-MiniLM-L6-v2")
client = QdrantClient(host="localhost", port=6333)

# 建立集合
client.create_collection(
    collection_name="knowledge_base",
    vectors_config=VectorParams(size=384, distance=Distance.COSINE)
)

# 為文件建立索引
documents = [
    {"id": 1, "text": "Python is a programming language", "source": "wiki"},
    {"id": 2, "text": "Machine learning uses algorithms", "source": "textbook"},
]

points = [
    PointStruct(
        id=doc["id"],
        vector=encoder.encode(doc["text"]).tolist(),
        payload={"text": doc["text"], "source": doc["source"]}
    )
    for doc in documents
]
client.upsert(collection_name="knowledge_base", points=points)

# RAG 檢索
def retrieve(query: str, top_k: int = 5) -> list[dict]:
    query_vector = encoder.encode(query).tolist()
    results = client.search(
        collection_name="knowledge_base",
        query_vector=query_vector,
        limit=top_k
    )
    return [{"text": r.payload["text"], "score": r.score} for r in results]

# 在 RAG 管道中使用
context = retrieve("What is Python?")
prompt = f"Context: {context}\n\nQuestion: What is Python?"
```

### 搭配 LangChain

```python
from langchain_community.vectorstores import Qdrant
from langchain_community.embeddings import HuggingFaceEmbeddings

embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
vectorstore = Qdrant.from_documents(documents, embeddings, url="http://localhost:6333", collection_name="docs")
retriever = vectorstore.as_retriever(search_kwargs={"k": 5})
```

### 搭配 LlamaIndex

```python
from llama_index.vector_stores.qdrant import QdrantVectorStore
from llama_index.core import VectorStoreIndex, StorageContext

vector_store = QdrantVectorStore(client=client, collection_name="llama_docs")
storage_context = StorageContext.from_defaults(vector_store=vector_store)
index = VectorStoreIndex.from_documents(documents, storage_context=storage_context)
query_engine = index.as_query_engine()
```

## 多向量支援

### 具名向量 (不同嵌入模型)

```python
from qdrant_client.models import VectorParams, Distance

# 包含多種向量類型的集合
client.create_collection(
    collection_name="hybrid_search",
    vectors_config={
        "dense": VectorParams(size=384, distance=Distance.COSINE),
        "sparse": VectorParams(size=30000, distance=Distance.DOT)
    }
)

# 插入具名向量
client.upsert(
    collection_name="hybrid_search",
    points=[
        PointStruct(
            id=1,
            vector={
                "dense": dense_embedding,
                "sparse": sparse_embedding
            },
            payload={"text": "document text"}
        )
    ]
)

# 搜尋特定向量
results = client.search(
    collection_name="hybrid_search",
    query_vector=("dense", query_dense),  # 指定搜尋哪個向量
    limit=10
)
```

### 稀疏向量 (BM25, SPLADE)

```python
from qdrant_client.models import SparseVectorParams, SparseIndexParams, SparseVector

# 包含稀疏向量的集合
client.create_collection(
    collection_name="sparse_search",
    vectors_config={},
    sparse_vectors_config={"text": SparseVectorParams(index=SparseIndexParams(on_disk=False))}
)

# 插入稀疏向量
client.upsert(
    collection_name="sparse_search",
    points=[PointStruct(id=1, vector={"text": SparseVector(indices=[1, 5, 100], values=[0.5, 0.8, 0.2])}, payload={"text": "document"})]
)
```

## 量化 (記憶體優化)

```python
from qdrant_client.models import ScalarQuantization, ScalarQuantizationConfig, ScalarType

# 標量量化 (記憶體佔用減少 4 倍)
client.create_collection(
    collection_name="quantized",
    vectors_config=VectorParams(size=384, distance=Distance.COSINE),
    quantization_config=ScalarQuantization(
        scalar=ScalarQuantizationConfig(
            type=ScalarType.INT8,
            quantile=0.99,        # 裁切離群值
            always_ram=True      # 將量化資料保留於 RAM
        )
    )
)

# 帶有重校分 (Rescoring) 的搜尋
results = client.search(
    collection_name="quantized",
    query_vector=query,
    search_params={"quantization": {"rescore": True}},  # 對頂部結果重新計算原始分數
    limit=10
)
```

## Payload 索引

```python
from qdrant_client.models import PayloadSchemaType

# 建立 Payload 索引以加快過濾速度
client.create_payload_index(
    collection_name="documents",
    field_name="category",
    field_schema=PayloadSchemaType.KEYWORD
)

client.create_payload_index(
    collection_name="documents",
    field_name="timestamp",
    field_schema=PayloadSchemaType.INTEGER
)

# 索引類型：KEYWORD, INTEGER, FLOAT, GEO, TEXT (全文檢索), BOOL
```

## 生產環境部署

### Qdrant Cloud

```python
from qdrant_client import QdrantClient

# 連接至 Qdrant Cloud
client = QdrantClient(
    url="https://your-cluster.cloud.qdrant.io",
    api_key="your-api-key"
)
```

### 效能調優

```python
# 為搜尋速度優化 (提高檢回率)
client.update_collection(
    collection_name="documents",
    hnsw_config=HnswConfigDiff(ef_construct=200, m=32)
)

# 為索引速度優化 (大批次載入)
client.update_collection(
    collection_name="documents",
    optimizer_config={"indexing_threshold": 20000}
)
```

## 最佳實踐

1. **批次操作** - 為了效率請使用批次 Upsert/搜尋
2. **Payload 索引** - 針對用於過濾的欄位建立索引
3. **量化** - 針對大型集合 (>100 萬個向量) 啟用法
4. **分片** - 針對超過 1000 萬個向量的集合使用
5. **硬碟儲存** - 針對大型 Payload 啟用 `on_disk_payload`
6. **連接池** - 重複使用用戶端實例

## 常見問題

**使用過濾器時搜尋緩慢：**
```python
# 針對過濾欄位建立 Payload 索引
client.create_payload_index(
    collection_name="docs",
    field_name="category",
    field_schema=PayloadSchemaType.KEYWORD
)
```

**記憶體溢出 (OOM)：**
```python
# 啟用量化和硬碟儲存
client.create_collection(
    collection_name="large_collection",
    vectors_config=VectorParams(size=384, distance=Distance.COSINE),
    quantization_config=ScalarQuantization(...),
    on_disk_payload=True
)
```

**連線問題：**
```python
# 使用逾時與重試機制
client = QdrantClient(
    host="localhost",
    port=6333,
    timeout=30,
    prefer_grpc=True  # 使用 gRPC 以獲得更好效能
)
```

## 參考資料

- **[進階用法](references/advanced-usage.md)** - 分佈式模式、混合搜尋、推薦系統
- **[故障排除](references/troubleshooting.md)** - 常見問題、除錯、效能調優

## 資源

- **GitHub**: https://github.com/qdrant/qdrant (22k+ 星)
- **文件**: https://qdrant.tech/documentation/
- **Python 用戶端**: https://github.com/qdrant/qdrant-client
- **Cloud**: https://cloud.qdrant.io
- **版本**: 1.12.0+
- **授權**: Apache 2.0
