# Qdrant 疑難排解指南

## 安裝問題

### Docker 問題

**錯誤**：`Cannot connect to Docker daemon`

**修正**：
```bash
# 啟動 Docker 守護進程
sudo systemctl start docker

# 或者在 Mac/Windows 上使用 Docker Desktop
open -a Docker
```

**錯誤**：`Port 6333 already in use`

**修正**：
```bash
# 尋找使用該連接埠的程序
lsof -i :6333

# 終止程序或使用不同的連接埠
docker run -p 6334:6333 qdrant/qdrant
```

### Python 用戶端問題

**錯誤**：`ModuleNotFoundError: No module named 'qdrant_client'`

**修正**：
```bash
pip install qdrant-client

# 指定特定版本
pip install qdrant-client>=1.12.0
```

**錯誤**：`grpc._channel._InactiveRpcError`

**修正**：
```bash
# 安裝含 gRPC 支援的版本
pip install 'qdrant-client[grpc]'

# 或者停用 gRPC
client = QdrantClient(host="localhost", port=6333, prefer_grpc=False)
```

## 連線問題

### 無法連線至伺服器

**錯誤**：`ConnectionRefusedError: [Errno 111] Connection refused`

**解決方案**：

1. **檢查伺服器是否正在執行**：
```bash
docker ps | grep qdrant
curl http://localhost:6333/healthz
```

2. **驗證連接埠綁定**：
```bash
# 檢查監聽中的連接埠
netstat -tlnp | grep 6333

# Docker 連接埠映射
docker port <container_id>
```

3. **使用正確的主機位址**：
```python
# Linux 上的 Docker
client = QdrantClient(host="localhost", port=6333)

# Mac/Windows 上有網路問題的 Docker
client = QdrantClient(host="127.0.0.1", port=6333)

# 在 Docker 網路內部
client = QdrantClient(host="qdrant", port=6333)
```

### 超時錯誤

**錯誤**：`TimeoutError: Connection timed out`

**修正**：
```python
# 增加超時時間
client = QdrantClient(
    host="localhost",
    port=6333,
    timeout=60  # 秒
)

# 針對大型操作
client.upsert(
    collection_name="documents",
    points=large_batch,
    wait=False  # 不等待索引完成
)
```

### SSL/TLS 錯誤

**錯誤**：`ssl.SSLCertVerificationError`

**修正**：
```python
# Qdrant Cloud
client = QdrantClient(
    url="https://cluster.cloud.qdrant.io",
    api_key="your-api-key"
)

# 自簽署憑證
client = QdrantClient(
    host="localhost",
    port=6333,
    https=True,
    verify=False  # 停用驗證（不建議用於正式環境）
)
```

## 集合 (Collection) 問題

### 集合已存在

**錯誤**：`ValueError: Collection 'documents' already exists`

**修正**：
```python
# 建立前先檢查
collections = client.get_collections().collections
names = [c.name for c in collections]

if "documents" not in names:
    client.create_collection(...)

# 或者重新建立
client.recreate_collection(
    collection_name="documents",
    vectors_config=VectorParams(size=384, distance=Distance.COSINE)
)
```

### 找不到集合

**錯誤**：`NotFoundException: Collection 'docs' not found`

**修正**：
```python
# 列出可用的集合
collections = client.get_collections()
print([c.name for c in collections.collections])

# 檢查精確名稱（區分大小寫）
try:
    info = client.get_collection("documents")
except Exception as e:
    print(f"找不到集合：{e}")
```

### 向量維度不匹配

**錯誤**：`ValueError: Vector dimension mismatch. Expected 384, got 768`

**修正**：
```python
# 檢查集合配置
info = client.get_collection("documents")
print(f"預期維度：{info.config.params.vectors.size}")

# 以正確的維度重新建立
client.recreate_collection(
    collection_name="documents",
    vectors_config=VectorParams(size=768, distance=Distance.COSINE)  # 匹配您的嵌入模型
)
```

## 搜尋問題

### 搜尋結果為空

**問題**：搜尋返回空結果。

**解決方案**：

1. **驗證資料是否存在**：
```python
info = client.get_collection("documents")
print(f"點數 (Points)：{info.points_count}")

# 使用 scroll 檢查資料
points, _ = client.scroll(
    collection_name="documents",
    limit=10,
    with_payload=True
)
print(points)
```

2. **檢查向量格式**：
```python
# 必須是浮點數列表
query_vector = embedding.tolist()  # 將 numpy 轉換為列表

# 檢查維度
print(f"查詢維度：{len(query_vector)}")
```

3. **驗證篩選條件**：
```python
# 先測試不含篩選器的搜尋
results = client.search(
    collection_name="documents",
    query_vector=query,
    limit=10
    # 不含篩選器
)

# 然後逐步加入篩選器
```

### 搜尋效能緩慢

**問題**：搜尋耗時太長。

**解決方案**：

1. **建立酬載 (Payload) 索引**：
```python
# 為篩選器中使用的欄位建立索引
client.create_payload_index(
    collection_name="documents",
    field_name="category",
    field_schema="keyword"
)
```

2. **啟用量化 (Quantization)**：
```python
client.update_collection(
    collection_name="documents",
    quantization_config=ScalarQuantization(
        scalar=ScalarQuantizationConfig(type=ScalarType.INT8)
    )
)
```

3. **微調 HNSW 參數**：
```python
# 更快的搜尋（精確度較低）
client.update_collection(
    collection_name="documents",
    hnsw_config=HnswConfigDiff(ef_construct=64, m=8)
)

# 使用 ef 搜尋參數
results = client.search(
    collection_name="documents",
    query_vector=query,
    search_params={"hnsw_ef": 64},  # 越低越快
    limit=10
)
```

4. **使用 gRPC**：
```python
client = QdrantClient(
    host="localhost",
    port=6333,
    grpc_port=6334,
    prefer_grpc=True
)
```

### 結果不一致

**問題**：相同的查詢返回不同的結果。

**解決方案**：

1. **等待索引完成**：
```python
client.upsert(
    collection_name="documents",
    points=points,
    wait=True  # 等待索引更新
)
```

2. **檢查副本一致性 (Replication Consistency)**：
```python
# 強一致性讀取
results = client.search(
    collection_name="documents",
    query_vector=query,
    consistency="all"  # 從所有副本讀取
)
```

## 更新 (Upsert) 問題

### 批次更新失敗

**錯誤**：`PayloadError: Payload too large`

**修正**：
```python
# 分割成較小的批次
def batch_upsert(client, collection, points, batch_size=100):
    for i in range(0, len(points), batch_size):
        batch = points[i:i + batch_size]
        client.upsert(
            collection_name=collection,
            points=batch,
            wait=True
        )

batch_upsert(client, "documents", large_points_list)
```

### 無效的點 ID (Point ID)

**錯誤**：`ValueError: Invalid point ID`

**修正**：
```python
# 有效的 ID 類型：整數或 UUID 字串
from uuid import uuid4

# 整數 ID
PointStruct(id=123, vector=vec, payload={})

# UUID 字串
PointStruct(id=str(uuid4()), vector=vec, payload={})

# 無效
PointStruct(id="custom-string-123", ...)  # 請使用 UUID 格式
```

### 酬載 (Payload) 驗證錯誤

**錯誤**：`ValidationError: Invalid payload`

**修正**：
```python
# 確保酬載可進行 JSON 序列化
import json

payload = {
    "title": "Document",
    "count": 42,
    "tags": ["a", "b"],
    "nested": {"key": "value"}
}

# 更新前進行驗證
json.dumps(payload)  # 不應引發異常

# 避免使用無法序列化的類型
# 無效：datetime、numpy 陣列、自定義物件
payload = {
    "timestamp": datetime.now().isoformat(),  # 轉換為字串
    "vector": embedding.tolist()  # 將 numpy 轉換為列表
}
```

## 記憶體問題

### 記憶體不足 (Out of Memory)

**錯誤**：`MemoryError` 或容器被終止

**解決方案**：

1. **啟用磁碟存儲**：
```python
client.create_collection(
    collection_name="large_collection",
    vectors_config=VectorParams(size=384, distance=Distance.COSINE),
    on_disk_payload=True,  # 在磁碟上存儲酬載
    hnsw_config=HnswConfigDiff(on_disk=True)  # 在磁碟上存儲 HNSW
)
```

2. **使用量化**：
```python
# 減少 4 倍記憶體使用
client.update_collection(
    collection_name="large_collection",
    quantization_config=ScalarQuantization(
        scalar=ScalarQuantizationConfig(
            type=ScalarType.INT8,
            always_ram=False  # 保留在磁碟上
        )
    )
)
```

3. **增加 Docker 記憶體**：
```bash
docker run -m 8g -p 6333:6333 qdrant/qdrant
```

4. **配置 Qdrant 存儲**：
```yaml
# config.yaml
storage:
  performance:
    max_search_threads: 2
  optimizers:
    memmap_threshold_kb: 20000
```

### 索引期間的高記憶體使用量

**修正**：
```python
# 為大量載入增加索引閾值
client.update_collection(
    collection_name="documents",
    optimizer_config={
        "indexing_threshold": 50000  # 延遲索引
    }
)

# 批次插入
client.upsert(collection_name="documents", points=all_points, wait=False)

# 然後進行優化
client.update_collection(
    collection_name="documents",
    optimizer_config={
        "indexing_threshold": 10000  # 恢復正常索引
    }
)
```

## 叢集問題

### 節點未加入叢集

**問題**：新節點無法加入叢集。

**修正**：
```bash
# 檢查網路連線性
docker exec qdrant-node-2 ping qdrant-node-1

# 驗證引導 (Bootstrap) URL
docker logs qdrant-node-2 | grep bootstrap

# 檢查 Raft 狀態
curl http://localhost:6333/cluster
```

### 腦裂 (Split Brain)

**問題**：叢集狀態不一致。

**修正**：
```bash
# 強制 Leader 選舉
curl -X POST http://localhost:6333/cluster/recover

# 或者重啟少數節點
docker restart qdrant-node-2 qdrant-node-3
```

### 複製延遲 (Replication Lag)

**問題**：副本落後。

**修正**：
```python
# 檢查集合狀態
info = client.get_collection("documents")
print(f"狀態：{info.status}")

# 為關鍵寫入使用強一致性
client.upsert(
    collection_name="documents",
    points=points,
    ordering=WriteOrdering.STRONG
)
```

## 效能微調

### 基準測試 (Benchmark) 配置

```python
import time
import numpy as np

def benchmark_search(client, collection, n_queries=100, dimension=384):
    # 生成隨機查詢
    queries = [np.random.rand(dimension).tolist() for _ in range(n_queries)]

    # 預熱
    for q in queries[:10]:
        client.search(collection_name=collection, query_vector=q, limit=10)

    # 基準測試
    start = time.perf_counter()
    for q in queries:
        client.search(collection_name=collection, query_vector=q, limit=10)
    elapsed = time.perf_counter() - start

    print(f"QPS: {n_queries / elapsed:.2f}")
    print(f"延遲：{elapsed / n_queries * 1000:.2f}ms")

benchmark_search(client, "documents")
```

### 最佳 HNSW 參數

```python
# 高召回率（較慢）
client.create_collection(
    collection_name="high_recall",
    vectors_config=VectorParams(size=384, distance=Distance.COSINE),
    hnsw_config=HnswConfigDiff(
        m=32,              # 更多連接
        ef_construct=200   # 更高的建置品質
    )
)

# 高速度（較低召回率）
client.create_collection(
    collection_name="high_speed",
    vectors_config=VectorParams(size=384, distance=Distance.COSINE),
    hnsw_config=HnswConfigDiff(
        m=8,               # 較少連接
        ef_construct=64    # 較低的建置品質
    )
)

# 平衡型
client.create_collection(
    collection_name="balanced",
    vectors_config=VectorParams(size=384, distance=Distance.COSINE),
    hnsw_config=HnswConfigDiff(
        m=16,              # 預設
        ef_construct=100   # 預設
    )
)
```

## 除錯技巧

### 啟用詳細紀錄 (Verbose Logging)

```python
import logging

logging.basicConfig(level=logging.DEBUG)
logging.getLogger("qdrant_client").setLevel(logging.DEBUG)
```

### 檢查伺服器紀錄

```bash
# Docker 紀錄
docker logs -f qdrant

# 包含時間戳記
docker logs --timestamps qdrant

# 最後 100 行
docker logs --tail 100 qdrant
```

### 檢查集合狀態

```python
# 集合資訊
info = client.get_collection("documents")
print(f"狀態：{info.status}")
print(f"點數：{info.points_count}")
print(f"分段 (Segments)：{len(info.segments)}")
print(f"配置：{info.config}")

# 範例點
points, _ = client.scroll(
    collection_name="documents",
    limit=5,
    with_payload=True,
    with_vectors=True
)
for p in points:
    print(f"ID: {p.id}, 酬載：{p.payload}")
```

### 測試連線

```python
def test_connection(host="localhost", port=6333):
    try:
        client = QdrantClient(host=host, port=port, timeout=5)
        collections = client.get_collections()
        print(f"已連線！集合數量：{len(collections.collections)}")
        return True
    except Exception as e:
        print(f"連線失敗：{e}")
        return False

test_connection()
```

## 尋求協助

1. **說明文件**：https://qdrant.tech/documentation/
2. **GitHub Issues**：https://github.com/qdrant/qdrant/issues
3. **Discord**：https://discord.gg/qdrant
4. **Stack Overflow**：請標記 `qdrant`

### 回報問題

請包含：
- Qdrant 版本：`curl http://localhost:6333/`
- Python 用戶端版本：`pip show qdrant-client`
- 完整的錯誤回溯 (Traceback)
- 最小可重現程式碼
- 集合配置
