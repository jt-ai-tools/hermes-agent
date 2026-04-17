# Qdrant 進階使用指南

## 分散式部署

### 叢集設置

Qdrant 使用 Raft 共識演算法進行分散式協調。

```yaml
# 3 節點叢集的 docker-compose.yml
version: '3.8'
services:
  qdrant-node-1:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
      - "6334:6334"
      - "6335:6335"
    volumes:
      - ./node1_storage:/qdrant/storage
    environment:
      - QDRANT__CLUSTER__ENABLED=true
      - QDRANT__CLUSTER__P2P__PORT=6335
      - QDRANT__SERVICE__HTTP_PORT=6333
      - QDRANT__SERVICE__GRPC_PORT=6334

  qdrant-node-2:
    image: qdrant/qdrant:latest
    ports:
      - "6343:6333"
      - "6344:6334"
      - "6345:6335"
    volumes:
      - ./node2_storage:/qdrant/storage
    environment:
      - QDRANT__CLUSTER__ENABLED=true
      - QDRANT__CLUSTER__P2P__PORT=6335
      - QDRANT__CLUSTER__BOOTSTRAP=http://qdrant-node-1:6335
    depends_on:
      - qdrant-node-1

  qdrant-node-3:
    image: qdrant/qdrant:latest
    ports:
      - "6353:6333"
      - "6354:6334"
      - "6355:6335"
    volumes:
      - ./node3_storage:/qdrant/storage
    environment:
      - QDRANT__CLUSTER__ENABLED=true
      - QDRANT__CLUSTER__P2P__PORT=6335
      - QDRANT__CLUSTER__BOOTSTRAP=http://qdrant-node-1:6335
    depends_on:
      - qdrant-node-1
```

### 分片 (Sharding) 配置

```python
from qdrant_client import QdrantClient
from qdrant_client.models import VectorParams, Distance, ShardingMethod

client = QdrantClient(host="localhost", port=6333)

# 建立分片集合
client.create_collection(
    collection_name="large_collection",
    vectors_config=VectorParams(size=384, distance=Distance.COSINE),
    shard_number=6,  # 分片數量
    replication_factor=2,  # 每個分片的副本數
    write_consistency_factor=1  # 寫入所需的確認數
)

# 檢查叢集狀態
cluster_info = client.get_cluster_info()
print(f"端點 (Peers): {cluster_info.peers}")
print(f"Raft 狀態: {cluster_info.raft_info}")
```

### 複製與一致性

```python
from qdrant_client.models import WriteOrdering

# 強一致性寫入
client.upsert(
    collection_name="critical_data",
    points=points,
    ordering=WriteOrdering.STRONG  # 等待所有副本
)

# 最終一致性（較快）
client.upsert(
    collection_name="logs",
    points=points,
    ordering=WriteOrdering.WEAK  # 在主要節點確認後返回
)

# 從特定分片讀取
results = client.search(
    collection_name="documents",
    query_vector=query,
    consistency="majority"  # 從多數副本讀取
)
```

## 混合搜尋 (Hybrid Search)

### 稠密 (Dense) + 稀疏 (Sparse) 向量

結合語義（稠密）和關鍵字（稀疏）搜尋：

```python
from qdrant_client.models import (
    VectorParams, SparseVectorParams, SparseIndexParams,
    Distance, PointStruct, SparseVector, Prefetch, Query
)

# 建立混合搜尋集合
client.create_collection(
    collection_name="hybrid",
    vectors_config={
        "dense": VectorParams(size=384, distance=Distance.COSINE)
    },
    sparse_vectors_config={
        "sparse": SparseVectorParams(
            index=SparseIndexParams(on_disk=False)
        )
    }
)

# 插入包含兩種向量類型的資料
def encode_sparse(text: str) -> SparseVector:
    """簡單的類 BM25 稀疏編碼"""
    from collections import Counter
    tokens = text.lower().split()
    counts = Counter(tokens)
    # 將詞彙映射到索引（在實際生產中請使用詞彙表）
    indices = [hash(t) % 30000 for t in counts.keys()]
    values = list(counts.values())
    return SparseVector(indices=indices, values=values)

client.upsert(
    collection_name="hybrid",
    points=[
        PointStruct(
            id=1,
            vector={
                "dense": dense_encoder.encode("Python programming").tolist(),
                "sparse": encode_sparse("Python programming language code")
            },
            payload={"text": "Python programming language code"}
        )
    ]
)

# 使用互惠排名融合 (Reciprocal Rank Fusion, RRF) 進行混合搜尋
from qdrant_client.models import FusionQuery

results = client.query_points(
    collection_name="hybrid",
    prefetch=[
        Prefetch(query=dense_query, using="dense", limit=20),
        Prefetch(query=sparse_query, using="sparse", limit=20)
    ],
    query=FusionQuery(fusion="rrf"),  # 合併結果
    limit=10
)
```

### 多階段搜尋

```python
from qdrant_client.models import Prefetch, Query

# 兩階段檢索：先粗略後精細
results = client.query_points(
    collection_name="documents",
    prefetch=[
        Prefetch(
            query=query_vector,
            limit=100,  # 第一階段廣泛搜尋
            params={"quantization": {"rescore": False}}  # 快速且約略
        )
    ],
    query=Query(nearest=query_vector),
    limit=10,
    params={"quantization": {"rescore": True}}  # 精確重排 (reranking)
)
```

## 推薦系統

### 項目對項目 (Item-to-Item) 推薦

```python
# 尋找相似項目
recommendations = client.recommend(
    collection_name="products",
    positive=[1, 2, 3],  # 使用者喜歡的 ID
    negative=[4],         # 使用者不喜歡的 ID
    limit=10
)

# 配合篩選器
recommendations = client.recommend(
    collection_name="products",
    positive=[1, 2],
    query_filter={
        "must": [
            {"key": "category", "match": {"value": "electronics"}},
            {"key": "in_stock", "match": {"value": True}}
        ]
    },
    limit=10
)
```

### 從另一個集合查找

```python
from qdrant_client.models import RecommendStrategy, LookupLocation

# 使用來自另一個集合的向量進行推薦
results = client.recommend(
    collection_name="products",
    positive=[
        LookupLocation(
            collection_name="user_history",
            id="user_123"
        )
    ],
    strategy=RecommendStrategy.AVERAGE_VECTOR,
    limit=10
)
```

## 進階篩選

### 巢狀酬載篩選 (Nested Payload Filtering)

```python
from qdrant_client.models import Filter, FieldCondition, MatchValue, NestedCondition

# 針對巢狀物件進行篩選
results = client.search(
    collection_name="documents",
    query_vector=query,
    query_filter=Filter(
        must=[
            NestedCondition(
                key="metadata",
                filter=Filter(
                    must=[
                        FieldCondition(
                            key="author.name",
                            match=MatchValue(value="John")
                        )
                    ]
                )
            )
        ]
    ),
    limit=10
)
```

### 地理位置篩選 (Geo Filtering)

```python
from qdrant_client.models import FieldCondition, GeoRadius, GeoPoint

# 尋找半徑範圍內的資料
results = client.search(
    collection_name="locations",
    query_vector=query,
    query_filter=Filter(
        must=[
            FieldCondition(
                key="location",
                geo_radius=GeoRadius(
                    center=GeoPoint(lat=40.7128, lon=-74.0060),
                    radius=5000  # 公尺
                )
            )
        ]
    ),
    limit=10
)

# 地理邊界框 (Geo Bounding Box)
from qdrant_client.models import GeoBoundingBox

results = client.search(
    collection_name="locations",
    query_vector=query,
    query_filter=Filter(
        must=[
            FieldCondition(
                key="location",
                geo_bounding_box=GeoBoundingBox(
                    top_left=GeoPoint(lat=40.8, lon=-74.1),
                    bottom_right=GeoPoint(lat=40.6, lon=-73.9)
                )
            )
        ]
    ),
    limit=10
)
```

### 全文搜尋 (Full-Text Search)

```python
from qdrant_client.models import TextIndexParams, TokenizerType

# 建立文字索引
client.create_payload_index(
    collection_name="documents",
    field_name="content",
    field_schema=TextIndexParams(
        type="text",
        tokenizer=TokenizerType.WORD,
        min_token_len=2,
        max_token_len=15,
        lowercase=True
    )
)

# 全文篩選
from qdrant_client.models import MatchText

results = client.search(
    collection_name="documents",
    query_vector=query,
    query_filter=Filter(
        must=[
            FieldCondition(
                key="content",
                match=MatchText(text="machine learning")
            )
        ]
    ),
    limit=10
)
```

## 量化策略 (Quantization Strategies)

### 標量量化 (Scalar Quantization, INT8)

```python
from qdrant_client.models import ScalarQuantization, ScalarQuantizationConfig, ScalarType

# 約 4 倍記憶體縮減，精確度損失極小
client.create_collection(
    collection_name="scalar_quantized",
    vectors_config=VectorParams(size=384, distance=Distance.COSINE),
    quantization_config=ScalarQuantization(
        scalar=ScalarQuantizationConfig(
            type=ScalarType.INT8,
            quantile=0.99,       # 修剪極端值
            always_ram=True     # 將量化後的向量保留在 RAM 中
        )
    )
)
```

### 乘積量化 (Product Quantization)

```python
from qdrant_client.models import ProductQuantization, ProductQuantizationConfig, CompressionRatio

# 約 16 倍記憶體縮減，會有一些精確度損失
client.create_collection(
    collection_name="product_quantized",
    vectors_config=VectorParams(size=384, distance=Distance.COSINE),
    quantization_config=ProductQuantization(
        product=ProductQuantizationConfig(
            compression=CompressionRatio.X16,
            always_ram=True
        )
    )
)
```

### 二進制量化 (Binary Quantization)

```python
from qdrant_client.models import BinaryQuantization, BinaryQuantizationConfig

# 約 32 倍記憶體縮減，需要過度採樣 (oversampling)
client.create_collection(
    collection_name="binary_quantized",
    vectors_config=VectorParams(size=384, distance=Distance.COSINE),
    quantization_config=BinaryQuantization(
        binary=BinaryQuantizationConfig(always_ram=True)
    )
)

# 使用過度採樣進行搜尋
results = client.search(
    collection_name="binary_quantized",
    query_vector=query,
    search_params={
        "quantization": {
            "rescore": True,
            "oversampling": 2.0  # 檢索 2 倍的候選項目後重新評分
        }
    },
    limit=10
)
```

## 快照與備份

### 建立快照

```python
# 建立集合快照
snapshot_info = client.create_snapshot(collection_name="documents")
print(f"快照：{snapshot_info.name}")

# 列出快照
snapshots = client.list_snapshots(collection_name="documents")
for s in snapshots:
    print(f"{s.name}: {s.size} bytes")

# 完整存儲快照
full_snapshot = client.create_full_snapshot()
```

### 從快照恢復

```python
# 下載快照
client.download_snapshot(
    collection_name="documents",
    snapshot_name="documents-2024-01-01.snapshot",
    target_path="./backup/"
)

# 恢復（透過 REST API）
import requests

response = requests.put(
    "http://localhost:6333/collections/documents/snapshots/recover",
    json={"location": "file:///backup/documents-2024-01-01.snapshot"}
)
```

## 集合別名 (Collection Aliases)

```python
# 建立別名
client.update_collection_aliases(
    change_aliases_operations=[
        {"create_alias": {"alias_name": "production", "collection_name": "documents_v2"}}
    ]
)

# 藍綠部署 (Blue-green deployment)
# 1. 建立包含更新的新集合
client.create_collection(collection_name="documents_v3", ...)

# 2. 填充新集合
client.upsert(collection_name="documents_v3", points=new_points)

# 3. 原子性切換
client.update_collection_aliases(
    change_aliases_operations=[
        {"delete_alias": {"alias_name": "production"}},
        {"create_alias": {"alias_name": "production", "collection_name": "documents_v3"}}
    ]
)

# 透過別名搜尋
results = client.search(collection_name="production", query_vector=query, limit=10)
```

## 捲動與疊代 (Scroll and Iteration)

### 捲動瀏覽所有點

```python
# 分頁疊代
offset = None
all_points = []

while True:
    results, offset = client.scroll(
        collection_name="documents",
        limit=100,
        offset=offset,
        with_payload=True,
        with_vectors=False
    )
    all_points.extend(results)

    if offset is None:
        break

print(f"總點數：{len(all_points)}")
```

### 帶篩選器的捲動

```python
# 帶篩選器的捲動
results, _ = client.scroll(
    collection_name="documents",
    scroll_filter=Filter(
        must=[
            FieldCondition(key="status", match=MatchValue(value="active"))
        ]
    ),
    limit=1000
)
```

## 非同步用戶端 (Async Client)

```python
import asyncio
from qdrant_client import AsyncQdrantClient

async def main():
    client = AsyncQdrantClient(host="localhost", port=6333)

    # 非同步操作
    await client.create_collection(
        collection_name="async_docs",
        vectors_config=VectorParams(size=384, distance=Distance.COSINE)
    )

    await client.upsert(
        collection_name="async_docs",
        points=points
    )

    results = await client.search(
        collection_name="async_docs",
        query_vector=query,
        limit=10
    )

    return results

results = asyncio.run(main())
```

## gRPC 用戶端

```python
from qdrant_client import QdrantClient

# 優先使用 gRPC 以獲得更好的效能
client = QdrantClient(
    host="localhost",
    port=6333,
    grpc_port=6334,
    prefer_grpc=True  # 可用時使用 gRPC
)

# 僅限 gRPC 的用戶端
from qdrant_client import QdrantClient

client = QdrantClient(
    host="localhost",
    grpc_port=6334,
    prefer_grpc=True,
    https=False
)
```

## 多租戶 (Multitenancy)

### 基於酬載的隔離

```python
# 單一集合，依租戶篩選
client.upsert(
    collection_name="multi_tenant",
    points=[
        PointStruct(
            id=1,
            vector=embedding,
            payload={"tenant_id": "tenant_a", "text": "..."}
        )
    ]
)

# 在租戶內搜尋
results = client.search(
    collection_name="multi_tenant",
    query_vector=query,
    query_filter=Filter(
        must=[FieldCondition(key="tenant_id", match=MatchValue(value="tenant_a"))]
    ),
    limit=10
)
```

### 每個租戶一個集合

```python
# 建立租戶集合
def create_tenant_collection(tenant_id: str):
    client.create_collection(
        collection_name=f"tenant_{tenant_id}",
        vectors_config=VectorParams(size=384, distance=Distance.COSINE)
    )

# 搜尋租戶集合
def search_tenant(tenant_id: str, query_vector: list, limit: int = 10):
    return client.search(
        collection_name=f"tenant_{tenant_id}",
        query_vector=query_vector,
        limit=limit
    )
```

## 效能監控

### 集合統計數據

```python
# 集合資訊
info = client.get_collection("documents")
print(f"點數：{info.points_count}")
print(f"已索引向量數：{info.indexed_vectors_count}")
print(f"分段數：{len(info.segments)}")
print(f"狀態：{info.status}")

# 詳細的分段資訊
for i, segment in enumerate(info.segments):
    print(f"分段 {i}: {segment}")
```

### 遙測 (Telemetry)

```python
# 獲取遙測資料
telemetry = client.get_telemetry()
print(f"集合：{telemetry.collections}")
print(f"操作：{telemetry.operations}")
```
