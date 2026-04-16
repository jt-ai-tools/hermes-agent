---
name: clip
description: OpenAI 連接視覺與語言的模型。支援零樣本 (Zero-shot) 影像分類、影像文字匹配及跨模態檢索。在 4 億對影像文字對上進行訓練。可用於影像搜尋、內容審核或無需微調的視覺語言任務。最適合通用型影像理解。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [transformers, torch, pillow]
metadata:
  hermes:
    tags: [多模態, CLIP, 視覺語言, 零樣本, 影像分類, OpenAI, 影像搜尋, 跨模態檢索, 內容審核]

---

# CLIP - 對比式語言影像預訓練 (Contrastive Language-Image Pre-Training)

OpenAI 出品的模型，能透過自然語言理解影像。

## 何時使用 CLIP

**在以下情況使用：**
- 零樣本 (Zero-shot) 影像分類（無需訓練資料）
- 影像文字相似度/匹配
- 語義影像搜尋
- 內容審核（偵測 NSFW、暴力）
- 視覺問答
- 跨模態檢索（影像→文字，文字→影像）

**指標**：
- **25,300+ GitHub 星星**
- 在 4 億對影像文字對上進行訓練
- 在 ImageNet 上的表現與 ResNet-50 相當（零樣本）
- MIT 授權

**請考慮使用替代方案**：
- **BLIP-2**：更佳的標題生成 (Captioning)
- **LLaVA**：視覺語言對話
- **Segment Anything**：影像分割

## 快速入門

### 安裝

```bash
pip install git+https://github.com/openai/CLIP.git
pip install torch torchvision ftfy regex tqdm
```

### 零樣本分類

```python
import torch
import clip
from PIL import Image

# 載入模型
device = "cuda" if torch.cuda.is_available() else "cpu"
model, preprocess = clip.load("ViT-B/32", device=device)

# 載入影像
image = preprocess(Image.open("photo.jpg")).unsqueeze(0).to(device)

# 定義可能的標籤
text = clip.tokenize(["a dog", "a cat", "a bird", "a car"]).to(device)

# 計算相似度
with torch.no_grad():
    image_features = model.encode_image(image)
    text_features = model.encode_text(text)

    # 餘弦相似度 (Cosine similarity)
    logits_per_image, logits_per_text = model(image, text)
    probs = logits_per_image.softmax(dim=-1).cpu().numpy()

# 列印結果
labels = ["a dog", "a cat", "a bird", "a car"]
for label, prob in zip(labels, probs[0]):
    print(f"{label}: {prob:.2%}")
```

## 可用模型

```python
# 模型 (依大小排序)
models = [
    "RN50",           # ResNet-50
    "RN101",          # ResNet-101
    "ViT-B/32",       # Vision Transformer (建議使用)
    "ViT-B/16",       # 品質更好，速度較慢
    "ViT-L/14",       # 品質最佳，速度最慢
]

model, preprocess = clip.load("ViT-B/32")
```

| 模型 | 參數數量 | 速度 | 品質 |
|-------|------------|-------|---------|
| RN50 | 102M | 快 | 好 |
| ViT-B/32 | 151M | 中 | 更好 |
| ViT-L/14 | 428M | 慢 | 最佳 |

## 影像文字相似度

```python
# 計算嵌入 (Embeddings)
image_features = model.encode_image(image)
text_features = model.encode_text(text)

# 標準化 (Normalize)
image_features /= image_features.norm(dim=-1, keepdim=True)
text_features /= text_features.norm(dim=-1, keepdim=True)

# 餘弦相似度
similarity = (image_features @ text_features.T).item()
print(f"相似度: {similarity:.4f}")
```

## 語義影像搜尋

```python
# 索引影像
image_paths = ["img1.jpg", "img2.jpg", "img3.jpg"]
image_embeddings = []

for img_path in image_paths:
    image = preprocess(Image.open(img_path)).unsqueeze(0).to(device)
    with torch.no_grad():
        embedding = model.encode_image(image)
        embedding /= embedding.norm(dim=-1, keepdim=True)
    image_embeddings.append(embedding)

image_embeddings = torch.cat(image_embeddings)

# 使用文字查詢進行搜尋
query = "a sunset over the ocean"
text_input = clip.tokenize([query]).to(device)
with torch.no_grad():
    text_embedding = model.encode_text(text_input)
    text_embedding /= text_embedding.norm(dim=-1, keepdim=True)

# 尋找最相似的影像
similarities = (text_embedding @ image_embeddings.T).squeeze(0)
top_k = similarities.topk(3)

for idx, score in zip(top_k.indices, top_k.values):
    print(f"{image_paths[idx]}: {score:.3f}")
```

## 內容審核

```python
# 定義類別
categories = [
    "safe for work",
    "not safe for work",
    "violent content",
    "graphic content"
]

text = clip.tokenize(categories).to(device)

# 檢查影像
with torch.no_grad():
    logits_per_image, _ = model(image, text)
    probs = logits_per_image.softmax(dim=-1)

# 獲取分類結果
max_idx = probs.argmax().item()
max_prob = probs[0, max_idx].item()

print(f"類別: {categories[max_idx]} ({max_prob:.2%})")
```

## 批次處理

```python
# 處理多張影像
images = [preprocess(Image.open(f"img{i}.jpg")) for i in range(10)]
images = torch.stack(images).to(device)

with torch.no_grad():
    image_features = model.encode_image(images)
    image_features /= image_features.norm(dim=-1, keepdim=True)

# 批次處理文字
texts = ["a dog", "a cat", "a bird"]
text_tokens = clip.tokenize(texts).to(device)

with torch.no_grad():
    text_features = model.encode_text(text_tokens)
    text_features /= text_features.norm(dim=-1, keepdim=True)

# 相似度矩陣 (10 張影像 × 3 段文字)
similarities = image_features @ text_features.T
print(similarities.shape)  # (10, 3)
```

## 與向量資料庫整合

```python
# 將 CLIP 嵌入儲存在 Chroma/FAISS 中
import chromadb

client = chromadb.Client()
collection = client.create_collection("image_embeddings")

# 新增影像嵌入
for img_path, embedding in zip(image_paths, image_embeddings):
    collection.add(
        embeddings=[embedding.cpu().numpy().tolist()],
        metadatas=[{"path": img_path}],
        ids=[img_path]
    )

# 使用文字查詢
query = "a sunset"
text_embedding = model.encode_text(clip.tokenize([query]))
results = collection.query(
    query_embeddings=[text_embedding.cpu().numpy().tolist()],
    n_results=5
)
```

## 最佳實踐

1. **多數情況下使用 ViT-B/32** - 良好的平衡
2. **標準化嵌入** - 餘弦相似度必需步驟
3. **批次處理** - 效率更高
4. **快取嵌入** - 重新計算成本高昂
5. **使用具描述性的標籤** - 零樣本效能更佳
6. **建議使用 GPU** - 速度快 10-50 倍
7. **預處理影像** - 使用提供的 preprocess 函式

## 效能

| 操作 | CPU | GPU (V100) |
|-----------|-----|------------|
| 影像編碼 | ~200ms | ~20ms |
| 文字編碼 | ~50ms | ~5ms |
| 相似度計算 | <1ms | <1ms |

## 限制

1. **不適用於精細任務** - 最適合大範圍類別
2. **需要具描述性的文字** - 模糊的標籤表現較差
3. **對網路資料存在偏見** - 可能存在資料集偏見
4. **不支援邊界框 (Bounding boxes)** - 僅限整張影像
5. **空間理解能力有限** - 位置/計數能力較弱

## 資源

- **GitHub**: https://github.com/openai/CLIP ⭐ 25,300+
- **論文**: https://arxiv.org/abs/2103.00020
- **Colab**: https://colab.research.google.com/github/openai/clip/
- **授權**: MIT
