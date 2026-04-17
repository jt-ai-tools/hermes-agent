# Pinecone 部署指南

Pinecone 的生產環境部署模式。

## 無伺服器 (Serverless) vs 基於 Pod (Pod-based)

### 無伺服器 (推薦)

```python
from pinecone import Pinecone, ServerlessSpec

pc = Pinecone(api_key="your-key")

# 建立無伺服器索引
pc.create_index(
    name="my-index",
    dimension=1536,
    metric="cosine",
    spec=ServerlessSpec(
        cloud="aws",  # 或 "gcp", "azure"
        region="us-east-1"
    )
)
```

**優點：**
- 自動擴展 (Auto-scaling)
- 按使用量計費
- 無需管理基礎設施
- 適用於變動負載，成本效益高

**適用時機：**
- 流量不穩定
- 成本優化至關重要
- 不需要極其一致的延遲 (Latency)

### 基於 Pod

```python
from pinecone import PodSpec

pc.create_index(
    name="my-index",
    dimension=1536,
    metric="cosine",
    spec=PodSpec(
        environment="us-east1-gcp",
        pod_type="p1.x1",  # 或 p1.x2, p1.x4, p1.x8
        pods=2,  # Pod 數量
        replicas=2  # 高可用性 (High availability)
    )
)
```

**優點：**
- 效能一致
- 延遲可預測
- 吞吐量 (Throughput) 較高
- 專屬資源

**適用時機：**
- 生產環境工作負載
- 需要穩定的 p95 延遲
- 需要高吞吐量

## 混合搜尋 (Hybrid search)

### 稠密向量 (Dense) + 稀疏向量 (Sparse)

```python
# 同時使用稠密與稀疏向量進行 Upsert
index.upsert(vectors=[
    {
        "id": "doc1",
        "values": [0.1, 0.2, ...],  # 稠密向量 (語義)
        "sparse_values": {
            "indices": [10, 45, 123],  # Token IDs
            "values": [0.5, 0.3, 0.8]   # TF-IDF/BM25 分數
        },
        "metadata": {"text": "..."}
    }
])

# 混合查詢
results = index.query(
    vector=[0.1, 0.2, ...],  # 稠密查詢
    sparse_vector={
        "indices": [10, 45],
        "values": [0.5, 0.3]
    },
    top_k=10,
    alpha=0.5  # 0=僅稀疏, 1=僅稠密, 0.5=平衡
)
```

**優點：**
- 兼具兩者優點
- 語義 + 關鍵字匹配
- 召回率 (Recall) 比單一方式更好

## 用於多租戶的命名空間 (Namespaces)

```python
# 按使用者/租戶隔離數據
index.upsert(
    vectors=[{"id": "doc1", "values": [...]}],
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

**使用案例：**
- 多租戶 SaaS
- 使用者專屬數據隔離
- A/B 測試 (生產/測試命名空間)

## 元數據過濾 (Metadata filtering)

### 精確匹配

```python
results = index.query(
    vector=[...],
    filter={"category": "tutorial"},
    top_k=5
)
```

### 範圍查詢

```python
results = index.query(
    vector=[...],
    filter={"price": {"$gte": 100, "$lte": 500}},
    top_k=5
)
```

### 複雜過濾

```python
results = index.query(
    vector=[...],
    filter={
        "$and": [
            {"category": {"$in": ["tutorial", "guide"]}},
            {"difficulty": {"$lte": 3}},
            {"published": {"$gte": "2024-01-01"}}
        ]
    },
    top_k=5
)
```

## 最佳實踐

1. **開發階段使用無伺服器** - 具成本效益
2. **生產環境切換至 Pod** - 效能一致
3. **實施命名空間** - 實現多租戶
4. **有策略地添加元數據** - 啟用過濾功能
5. **使用混合搜尋** - 提升品質
6. **批次 Upsert** - 每批約 100-200 個向量
7. **監控使用量** - 查看 Pinecone 儀表板
8. **設置警報** - 使用量/成本閾值
9. **定期備份** - 匯出重要數據
10. **測試過濾器** - 驗證效能

## 資源

- **文件**: https://docs.pinecone.io
- **控制台**: https://app.pinecone.io
