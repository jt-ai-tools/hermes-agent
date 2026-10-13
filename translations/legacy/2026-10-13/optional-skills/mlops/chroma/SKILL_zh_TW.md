---
name: chroma
description: 用於 AI 應用程式的開源嵌入 (Embedding) 資料庫。儲存嵌入與元數據、執行向量與全文檢索、依元數據過濾。簡單的 4 函式 API。可從筆記本擴展至生產集群。適用於語意搜尋、RAG 應用程式或文件檢索。最適合本地開發和開源專案。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [chromadb, sentence-transformers]
metadata:
  hermes:
    tags: [RAG, Chroma, Vector Database, Embeddings, Semantic Search, Open Source, Self-Hosted, Document Retrieval, Metadata Filtering]

---

# Chroma - 開源嵌入資料庫

專為構建具備記憶能力的 LLM 應用程式而生的 AI 原生資料庫。

## 何時使用 Chroma

**在以下情況使用 Chroma：**
- 構建 RAG (檢索增強生成) 應用程式
- 需要本地/自代管的向量資料庫
- 偏好開源解決方案 (Apache 2.0)
- 在筆記本中進行原型設計
- 對文件執行語意搜尋
- 儲存帶有元數據 (Metadata) 的嵌入

**數據指標**：
- **24,300+ GitHub 星星**
- **1,900+ Fork 次數**
- **v1.3.3** (穩定版，每週更新)
- **Apache 2.0 授權**

**在以下情況改用替代方案**：
- **Pinecone**：託管雲端、自動擴展
- **FAISS**：純相似度搜尋，無元數據
- **Weaviate**：生產級機器學習原生資料庫
- **Qdrant**：高性能、基於 Rust

## 快速開始

### 安裝

```bash
# Python
pip install chromadb

# JavaScript/TypeScript
npm install chromadb @chroma-core/default-embed
```

### 基礎用法 (Python)

```python
import chromadb

# 建立客戶端
client = chromadb.Client()

# 建立集合 (Collection)
collection = client.create_collection(name="my_collection")

# 新增文件
collection.add(
    documents=["這是文件 1", "這是文件 2"],
    metadatas=[{"source": "doc1"}, {"source": "doc2"}],
    ids=["id1", "id2"]
)

# 查詢
results = collection.query(
    query_texts=["關於某個主題的文件"],
    n_results=2
)

print(results)
```

## 核心操作

### 1. 建立集合

```python
# 簡單集合
collection = client.create_collection("my_docs")

# 使用自定義嵌入函式
from chromadb.utils import embedding_functions

openai_ef = embedding_functions.OpenAIEmbeddingFunction(
    api_key="your-key",
    model_name="text-embedding-3-small"
)

collection = client.create_collection(
    name="my_docs",
    embedding_function=openai_ef
)

# 獲取現有集合
collection = client.get_collection("my_docs")

# 刪除集合
client.delete_collection("my_docs")
```

### 2. 新增文件

```python
# 新增並自動生成 ID
collection.add(
    documents=["文件 1", "文件 2", "文件 3"],
    metadatas=[
        {"source": "web", "category": "tutorial"},
        {"source": "pdf", "page": 5},
        {"source": "api", "timestamp": "2025-01-01"}
    ],
    ids=["id1", "id2", "id3"]
)

# 使用自定義嵌入向量新增
collection.add(
    embeddings=[[0.1, 0.2, ...], [0.3, 0.4, ...]],
    documents=["文件 1", "文件 2"],
    ids=["id1", "id2"]
)
```

### 3. 查詢（相似度搜尋）

```python
# 基礎查詢
results = collection.query(
    query_texts=["機器學習教學"],
    n_results=5
)

# 帶過濾條件的查詢
results = collection.query(
    query_texts=["Python 程式設計"],
    n_results=3,
    where={"source": "web"}
)

# 帶元數據過濾條件的查詢
results = collection.query(
    query_texts=["進階主題"],
    where={
        "$and": [
            {"category": "tutorial"},
            {"difficulty": {"$gte": 3}}
        ]
    }
)

# 存取結果
print(results["documents"])      # 匹配的文件列表
print(results["metadatas"])      # 每個文件的元數據
print(results["distances"])      # 相似度分數
print(results["ids"])            # 文件 ID
```

### 4. 獲取文件

```python
# 透過 ID 獲取
docs = collection.get(
    ids=["id1", "id2"]
)

# 帶過濾條件獲取
docs = collection.get(
    where={"category": "tutorial"},
    limit=10
)

# 獲取所有文件
docs = collection.get()
```

### 5. 更新文件

```python
# 更新文件內容
collection.update(
    ids=["id1"],
    documents=["更新後的內容"],
    metadatas=[{"source": "updated"}]
)
```

### 6. 刪除文件

```python
# 透過 ID 刪除
collection.delete(ids=["id1", "id2"])

# 透過過濾條件刪除
collection.delete(
    where={"source": "outdated"}
)
```

## 持久化儲存

```python
# 持久化至磁碟
client = chromadb.PersistentClient(path="./chroma_db")

collection = client.create_collection("my_docs")
collection.add(documents=["文件 1"], ids=["id1"])

# 數據會自動持久化
# 之後可使用相同路徑重新載入
client = chromadb.PersistentClient(path="./chroma_db")
collection = client.get_collection("my_docs")
```

## 嵌入函式 (Embedding Functions)

### 預設 (Sentence Transformers)

```python
# 預設使用 sentence-transformers
collection = client.create_collection("my_docs")
# 預設模型：all-MiniLM-L6-v2
```

### OpenAI

```python
from chromadb.utils import embedding_functions

openai_ef = embedding_functions.OpenAIEmbeddingFunction(
    api_key="your-key",
    model_name="text-embedding-3-small"
)

collection = client.create_collection(
    name="openai_docs",
    embedding_function=openai_ef
)
```

### HuggingFace

```python
huggingface_ef = embedding_functions.HuggingFaceEmbeddingFunction(
    api_key="your-key",
    model_name="sentence-transformers/all-mpnet-base-v2"
)

collection = client.create_collection(
    name="hf_docs",
    embedding_function=huggingface_ef
)
```

### 自定義嵌入函式

```python
from chromadb import Documents, EmbeddingFunction, Embeddings

class MyEmbeddingFunction(EmbeddingFunction):
    def __call__(self, input: Documents) -> Embeddings:
        # 您的嵌入邏輯
        return embeddings

my_ef = MyEmbeddingFunction()
collection = client.create_collection(
    name="custom_docs",
    embedding_function=my_ef
)
```

## 元數據過濾 (Metadata Filtering)

```python
# 精確匹配
results = collection.query(
    query_texts=["查詢內容"],
    where={"category": "tutorial"}
)

# 比較運算子
results = collection.query(
    query_texts=["查詢內容"],
    where={"page": {"$gt": 10}}  # $gt, $gte, $lt, $lte, $ne
)

# 邏輯運算子
results = collection.query(
    query_texts=["查詢內容"],
    where={
        "$and": [
            {"category": "tutorial"},
            {"difficulty": {"$lte": 3}}
        ]
    }  # 亦支援：$or
)

# 包含
results = collection.query(
    query_texts=["查詢內容"],
    where={"tags": {"$in": ["python", "ml"]}}
)
```

## LangChain 整合

```python
from langchain_chroma import Chroma
from langchain_openai import OpenAIEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter

# 切分文件
text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000)
docs = text_splitter.split_documents(documents)

# 建立 Chroma 向量儲存
vectorstore = Chroma.from_documents(
    documents=docs,
    embedding=OpenAIEmbeddings(),
    persist_directory="./chroma_db"
)

# 查詢
results = vectorstore.similarity_search("機器學習", k=3)

# 作為檢索器
retriever = vectorstore.as_retriever(search_kwargs={"k": 5})
```

## LlamaIndex 整合

```python
from llama_index.vector_stores.chroma import ChromaVectorStore
from llama_index.core import VectorStoreIndex, StorageContext
import chromadb

# 初始化 Chroma
db = chromadb.PersistentClient(path="./chroma_db")
collection = db.get_or_create_collection("my_collection")

# 建立向量儲存
vector_store = ChromaVectorStore(chroma_collection=collection)
storage_context = StorageContext.from_defaults(vector_store=vector_store)

# 建立索引
index = VectorStoreIndex.from_documents(
    documents,
    storage_context=storage_context
)

# 查詢
query_engine = index.as_query_engine()
response = query_engine.query("什麼是機器學習？")
```

## 伺服器模式

```python
# 執行 Chroma 伺服器
# 終端機：chroma run --path ./chroma_db --port 8000

# 連接至伺服器
import chromadb
from chromadb.config import Settings

client = chromadb.HttpClient(
    host="localhost",
    port=8000,
    settings=Settings(anonymized_telemetry=False)
)

# 像往常一樣使用
collection = client.get_or_create_collection("my_docs")
```

## 最佳實踐

1. **使用持久化客戶端** - 避免重啟時遺失數據。
2. **新增元數據** - 啟用過濾與追蹤。
3. **批次操作** - 一次新增多份文件。
4. **選擇合適的嵌入模型** - 平衡速度與品質。
5. **使用過濾器** - 縮小搜尋空間。
6. **唯一 ID** - 避免 ID 衝突。
7. **定期備份** - 複製 `chroma_db` 目錄。
8. **監控集合大小** - 視需求擴展。
9. **測試嵌入函式** - 確保品質。
10. **生產環境使用伺服器模式** - 支援多用戶且更穩定。

## 性能表現

| 操作 | 延遲 | 備註 |
|-----------|---------|-------|
| 新增 100 份文件 | ~1-3s | 包含嵌入計算 |
| 查詢 (前 10 名) | ~50-200ms | 取決於集合大小 |
| 元數據過濾 | ~10-50ms | 配合適當索引時速度極快 |

## 相關資源

- **GitHub**：https://github.com/chroma-core/chroma ⭐ 24,300+
- **文件**：https://docs.trychroma.com
- **Discord**：https://discord.gg/MMeYNTmh3x
- **版本**：1.3.3+
- **授權**：Apache 2.0
