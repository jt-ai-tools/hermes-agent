# CLIP 應用指南

CLIP 的實際應用與使用案例。

## 零樣本 (Zero-shot) 影像分類

```python
import torch
import clip
from PIL import Image

model, preprocess = clip.load("ViT-B/32")

# 定義類別
categories = [
    "a photo of a dog",
    "a photo of a cat",
    "a photo of a bird",
    "a photo of a car",
    "a photo of a person"
]

# 準備影像
image = preprocess(Image.open("photo.jpg")).unsqueeze(0)
text = clip.tokenize(categories)

# 分類
with torch.no_grad():
    image_features = model.encode_image(image)
    text_features = model.encode_text(text)

    logits_per_image, _ = model(image, text)
    probs = logits_per_image.softmax(dim=-1).cpu().numpy()

# 列印結果
for category, prob in zip(categories, probs[0]):
    print(f"{category}: {prob:.2%}")
```

## 語義影像搜尋

```python
# 索引影像
image_database = []
image_paths = ["img1.jpg", "img2.jpg", "img3.jpg"]

for img_path in image_paths:
    image = preprocess(Image.open(img_path)).unsqueeze(0)
    with torch.no_grad():
        features = model.encode_image(image)
        features /= features.norm(dim=-1, keepdim=True)
    image_database.append((img_path, features))

# 使用文字搜尋
query = "a sunset over mountains"
text_input = clip.tokenize([query])

with torch.no_grad():
    text_features = model.encode_text(text_input)
    text_features /= text_features.norm(dim=-1, keepdim=True)

# 尋找匹配項
similarities = []
for img_path, img_features in image_database:
    similarity = (text_features @ img_features.T).item()
    similarities.append((img_path, similarity))

# 依相似度排序
similarities.sort(key=lambda x: x[1], reverse=True)
for img_path, score in similarities[:3]:
    print(f"{img_path}: {score:.3f}")
```

## 內容審核

```python
# 定義安全類別
categories = [
    "safe for work content",
    "not safe for work content",
    "violent or graphic content",
    "hate speech or offensive content",
    "spam or misleading content"
]

text = clip.tokenize(categories)

# 檢查影像
with torch.no_grad():
    logits, _ = model(image, text)
    probs = logits.softmax(dim=-1)

# 獲取分類結果
max_idx = probs.argmax().item()
confidence = probs[0, max_idx].item()

if confidence > 0.7:
    print(f"分類結果為: {categories[max_idx]} ({confidence:.2%})")
else:
    print(f"分類結果不確定 (信心度: {confidence:.2%})")
```

## 影像轉文字檢索

```python
# 文字資料庫
captions = [
    "A beautiful sunset over the ocean",
    "A cute dog playing in the park",
    "A modern city skyline at night",
    "A delicious pizza with toppings"
]

# 編碼標題 (Captions)
caption_features = []
for caption in captions:
    text = clip.tokenize([caption])
    with torch.no_grad():
        features = model.encode_text(text)
        features /= features.norm(dim=-1, keepdim=True)
    caption_features.append(features)

caption_features = torch.cat(caption_features)

# 為影像尋找匹配的標題
with torch.no_grad():
    image_features = model.encode_image(image)
    image_features /= image_features.norm(dim=-1, keepdim=True)

similarities = (image_features @ caption_features.T).squeeze(0)
top_k = similarities.topk(3)

for idx, score in zip(top_k.indices, top_k.values):
    print(f"{captions[idx]}: {score:.3f}")
```

## 視覺問答

```python
# 建立 是/否 問題
image = preprocess(Image.open("photo.jpg")).unsqueeze(0)

questions = [
    "a photo showing people",
    "a photo showing animals",
    "a photo taken indoors",
    "a photo taken outdoors",
    "a photo taken during daytime",
    "a photo taken at night"
]

text = clip.tokenize(questions)

with torch.no_grad():
    logits, _ = model(image, text)
    probs = logits.softmax(dim=-1)

# 回答問題
for question, prob in zip(questions, probs[0]):
    answer = "是" if prob > 0.5 else "否"
    print(f"{question}: {answer} ({prob:.2%})")
```

## 影像去重 (Deduplication)

```python
# 偵測重複或相似影像
def compute_similarity(img1_path, img2_path):
    img1 = preprocess(Image.open(img1_path)).unsqueeze(0)
    img2 = preprocess(Image.open(img2_path)).unsqueeze(0)

    with torch.no_grad():
        feat1 = model.encode_image(img1)
        feat2 = model.encode_image(img2)

        feat1 /= feat1.norm(dim=-1, keepdim=True)
        feat2 /= feat2.norm(dim=-1, keepdim=True)

        similarity = (feat1 @ feat2.T).item()

    return similarity

# 檢查重複項
threshold = 0.95
image_pairs = [("img1.jpg", "img2.jpg"), ("img1.jpg", "img3.jpg")]

for img1, img2 in image_pairs:
    sim = compute_similarity(img1, img2)
    if sim > threshold:
        print(f"{img1} 與 {img2} 為重複影像 (相似度: {sim:.3f})")
```

## 最佳實踐

1. **使用具描述性的標籤** - "a photo of X" 的表現優於單獨的 "X"
2. **標準化嵌入** - 餘弦相似度必須進行標準化
3. **批次處理** - 同時處理多張影像/文字
4. **快取嵌入** - 避免高昂的重新計算成本
5. **設定適當的閾值** - 在驗證資料上進行測試
6. **使用 GPU** - 比 CPU 快 10-50 倍
7. **考慮模型大小** - ViT-B/32 是良好的預設選擇，ViT-L/14 提供最佳品質

## 資源

- **論文**: https://arxiv.org/abs/2103.00020
- **GitHub**: https://github.com/openai/CLIP
- **Colab**: https://colab.research.google.com/github/openai/clip/
