---
name: segment-anything-model
description: 具備零樣本 (Zero-shot) 遷移能力的影像分割基礎模型。當您需要使用點、框或遮罩作為提示來分割影像中的任何物件，或自動生成影像中所有物件的遮罩時使用。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [segment-anything, transformers>=4.30.0, torch>=1.7.0]
metadata:
  hermes:
    tags: [多模態, 影像分割, 電腦視覺, SAM, 零樣本]

---

# Segment Anything Model (SAM)

使用 Meta AI 的 Segment Anything Model 進行零樣本影像分割的綜合指南。

## 何時使用 SAM

**在以下情況使用 SAM：**
- 需要在無需特定任務訓練的情況下分割影像中的任何物件
- 構建具備點/框提示功能的互動式標註工具
- 為其他視覺模型生成訓練資料
- 需要將模型零樣本遷移到新的影像領域
- 構建物件偵測/分割流水線
- 處理醫療、衛星或特定領域的影像

**核心功能：**
- **零樣本分割**：適用於任何影像領域，無需微調
- **彈性的提示**：支援點、邊界框或先前的遮罩 (Mask)
- **自動分割**：自動生成所有物件的遮罩
- **高品質**：在來自 1100 萬張影像的 11 億個遮罩上進行訓練
- **多種模型大小**：ViT-B (最快)、ViT-L、ViT-H (最精確)
- **ONNX 匯出**：可在瀏覽器和邊緣裝置上部署

**請考慮使用替代方案：**
- **YOLO/Detectron2**：用於帶有類別的即時物件偵測
- **Mask2Former**：用於帶有類別的語義/全景分割
- **GroundingDINO + SAM**：用於文字提示的分割
- **SAM 2**：用於影片分割任務

## 快速入門

### 安裝

```bash
# 從 GitHub 安裝
pip install git+https://github.com/facebookresearch/segment-anything.git

# 選用依賴項
pip install opencv-python pycocotools matplotlib

# 或使用 HuggingFace transformers
pip install transformers
```

### 下載權重檔 (Checkpoints)

```bash
# ViT-H (最大，最精確) - 2.4GB
wget https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth

# ViT-L (中型) - 1.2GB
wget https://dl.fbaipublicfiles.com/segment_anything/sam_vit_l_0b3195.pth

# ViT-B (最小，最快) - 375MB
wget https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth
```

### 使用 SamPredictor 的基礎用法

```python
import numpy as np
from segment_anything import sam_model_registry, SamPredictor

# 載入模型
sam = sam_model_registry["vit_h"](checkpoint="sam_vit_h_4b8939.pth")
sam.to(device="cuda")

# 建立預測器
predictor = SamPredictor(sam)

# 設定影像 (僅需計算一次嵌入)
image = cv2.imread("image.jpg")
image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
predictor.set_image(image)

# 使用點提示進行預測
input_point = np.array([[500, 375]])  # (x, y) 座標
input_label = np.array([1])  # 1 = 前景, 0 = 背景

masks, scores, logits = predictor.predict(
    point_coords=input_point,
    point_labels=input_label,
    multimask_output=True  # 回傳 3 種遮罩選項
)

# 選擇得分最高的遮罩
best_mask = masks[np.argmax(scores)]
```

### 使用 HuggingFace Transformers

```python
import torch
from PIL import Image
from transformers import SamModel, SamProcessor

# 載入模型和處理器
model = SamModel.from_pretrained("facebook/sam-vit-huge")
processor = SamProcessor.from_pretrained("facebook/sam-vit-huge")
model.to("cuda")

# 處理帶有點提示的影像
image = Image.open("image.jpg")
input_points = [[[450, 600]]]  # 點的批次

inputs = processor(image, input_points=input_points, return_tensors="pt")
inputs = {k: v.to("cuda") for k, v in inputs.items()}

# 生成遮罩
with torch.no_grad():
    outputs = model(**inputs)

# 將遮罩後處理回原始大小
masks = processor.image_processor.post_process_masks(
    outputs.pred_masks.cpu(),
    inputs["original_sizes"].cpu(),
    inputs["reshaped_input_sizes"].cpu()
)
```

## 核心概念

### 模型架構

```
SAM 架構：
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  影像編碼器      │────▶│  提示編碼器      │────▶│  遮罩解碼器      │
│     (ViT)       │     │  (點/框)         │     │  (Transformer)  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │                       │
   影像嵌入 (Embeddings)  提示嵌入                 遮罩 + IoU 預測
   (僅需計算一次)         (針對每個提示)
```

### 模型變體

| 模型 | 權重檔標記 | 大小 | 速度 | 精確度 |
|-------|------------|------|-------|----------|
| ViT-H | `vit_h` | 2.4 GB | 最慢 | 最佳 |
| ViT-L | `vit_l` | 1.2 GB | 中等 | 好 |
| ViT-B | `vit_b` | 375 MB | 最快 | 好 |

### 提示類型

| 提示 | 描述 | 使用場景 |
|--------|-------------|----------|
| 點 (前景) | 點選物件 | 單一物件選擇 |
| 點 (背景) | 點選物件外 | 排除區域 |
| 邊界框 | 在物件周圍畫矩形 | 較大型物件 |
| 先前的遮罩 | 低解析度遮罩輸入 | 反覆修正 |

## 互動式分割

### 點提示 (Point prompts)

```python
# 單一前景點
input_point = np.array([[500, 375]])
input_label = np.array([1])

masks, scores, logits = predictor.predict(
    point_coords=input_point,
    point_labels=input_label,
    multimask_output=True
)

# 多個點 (前景 + 背景)
input_points = np.array([[500, 375], [600, 400], [450, 300]])
input_labels = np.array([1, 1, 0])  # 2 個前景, 1 個背景

masks, scores, logits = predictor.predict(
    point_coords=input_points,
    point_labels=input_labels,
    multimask_output=False  # 當提示明確時回傳單一遮罩
)
```

### 框提示 (Box prompts)

```python
# 邊界框 [x1, y1, x2, y2]
input_box = np.array([425, 600, 700, 875])

masks, scores, logits = predictor.predict(
    box=input_box,
    multimask_output=False
)
```

### 組合提示

```python
# 框 + 點以進行精確控制
masks, scores, logits = predictor.predict(
    point_coords=np.array([[500, 375]]),
    point_labels=np.array([1]),
    box=np.array([400, 300, 700, 600]),
    multimask_output=False
)
```

### 反覆修正 (Iterative refinement)

```python
# 初始預測
masks, scores, logits = predictor.predict(
    point_coords=np.array([[500, 375]]),
    point_labels=np.array([1]),
    multimask_output=True
)

# 使用先前的遮罩新增額外點進行修正
masks, scores, logits = predictor.predict(
    point_coords=np.array([[500, 375], [550, 400]]),
    point_labels=np.array([1, 0]),  # 新增背景點
    mask_input=logits[np.argmax(scores)][None, :, :],  # 使用最佳遮罩
    multimask_output=False
)
```

## 自動遮罩生成

### 基礎自動分割

```python
from segment_anything import SamAutomaticMaskGenerator

# 建立生成器
mask_generator = SamAutomaticMaskGenerator(sam)

# 生成所有遮罩
masks = mask_generator.generate(image)

# 每個遮罩包含：
# - segmentation: 二進位遮罩
# - bbox: [x, y, w, h]
# - area: 像素數量
# - predicted_iou: 品質得分
# - stability_score: 穩健性得分
# - point_coords: 生成點
```

### 自定義生成

```python
mask_generator = SamAutomaticMaskGenerator(
    model=sam,
    points_per_side=32,          # 網格密度 (越多 = 遮罩越多)
    pred_iou_thresh=0.88,        # 品質閾值
    stability_score_thresh=0.95,  # 穩定性閾值
    crop_n_layers=1,             # 多尺度裁剪
    crop_n_points_downscale_factor=2,
    min_mask_region_area=100,    # 移除微小遮罩
)

masks = mask_generator.generate(image)
```

### 篩選遮罩

```python
# 依面積排序 (最大優先)
masks = sorted(masks, key=lambda x: x['area'], reverse=True)

# 依預測 IoU 篩選
high_quality = [m for m in masks if m['predicted_iou'] > 0.9]

# 依穩定性得分篩選
stable_masks = [m for m in masks if m['stability_score'] > 0.95]
```

## 批次推論

### 多張影像

```python
# 高效處理多張影像
images = [cv2.imread(f"image_{i}.jpg") for i in range(10)]

all_masks = []
for image in images:
    predictor.set_image(image)
    masks, _, _ = predictor.predict(
        point_coords=np.array([[500, 375]]),
        point_labels=np.array([1]),
        multimask_output=True
    )
    all_masks.append(masks)
```

### 每張影像多個提示

```python
# 高效處理多個提示 (僅需一次影像編碼)
predictor.set_image(image)

# 點提示的批次
points = [
    np.array([[100, 100]]),
    np.array([[200, 200]]),
    np.array([[300, 300]])
]

all_masks = []
for point in points:
    masks, scores, _ = predictor.predict(
        point_coords=point,
        point_labels=np.array([1]),
        multimask_output=True
    )
    all_masks.append(masks[np.argmax(scores)])
```

## ONNX 部署

### 匯出模型

```bash
python scripts/export_onnx_model.py \
    --checkpoint sam_vit_h_4b8939.pth \
    --model-type vit_h \
    --output sam_onnx.onnx \
    --return-single-mask
```

### 使用 ONNX 模型

```python
import onnxruntime

# 載入 ONNX 模型
ort_session = onnxruntime.InferenceSession("sam_onnx.onnx")

# 執行推論 (影像嵌入需另外計算)
masks = ort_session.run(
    None,
    {
        "image_embeddings": image_embeddings,
        "point_coords": point_coords,
        "point_labels": point_labels,
        "mask_input": np.zeros((1, 1, 256, 256), dtype=np.float32),
        "has_mask_input": np.array([0], dtype=np.float32),
        "orig_im_size": np.array([h, w], dtype=np.float32)
    }
)
```

## 常見工作流

### 工作流 1：標註工具

```python
import cv2

# 載入模型
predictor = SamPredictor(sam)
predictor.set_image(image)

def on_click(event, x, y, flags, param):
    if event == cv2.EVENT_LBUTTONDOWN:
        # 前景點
        masks, scores, _ = predictor.predict(
            point_coords=np.array([[x, y]]),
            point_labels=np.array([1]),
            multimask_output=True
        )
        # 顯示最佳遮罩
        display_mask(masks[np.argmax(scores)])
```

### 工作流 2：物件提取

```python
def extract_object(image, point):
    """提取點選位置的物件並使用透明背景。"""
    predictor.set_image(image)

    masks, scores, _ = predictor.predict(
        point_coords=np.array([point]),
        point_labels=np.array([1]),
        multimask_output=True
    )

    best_mask = masks[np.argmax(scores)]

    # 建立 RGBA 輸出
    rgba = np.zeros((image.shape[0], image.shape[1], 4), dtype=np.uint8)
    rgba[:, :, :3] = image
    rgba[:, :, 3] = best_mask * 255

    return rgba
```

### 工作流 3：醫療影像分割

```python
# 處理醫療影像 (從灰階轉為 RGB)
medical_image = cv2.imread("scan.png", cv2.IMREAD_GRAYSCALE)
rgb_image = cv2.cvtColor(medical_image, cv2.COLOR_GRAY2RGB)

predictor.set_image(rgb_image)

# 分割感興趣區域 (ROI)
masks, scores, _ = predictor.predict(
    box=np.array([x1, y1, x2, y2]),  # ROI 邊界框
    multimask_output=True
)
```

## 輸出格式

### 遮罩資料結構

```python
# SamAutomaticMaskGenerator 輸出
{
    "segmentation": np.ndarray,  # H×W 二進位遮罩
    "bbox": [x, y, w, h],        # 邊界框
    "area": int,                 # 像素數量
    "predicted_iou": float,      # 0-1 品質得分
    "stability_score": float,    # 0-1 穩健性得分
    "crop_box": [x, y, w, h],    # 生成裁剪區域
    "point_coords": [[x, y]],    # 輸入點
}
```

### COCO RLE 格式

```python
from pycocotools import mask as mask_utils

# 將遮罩編碼為 RLE
rle = mask_utils.encode(np.asfortranarray(mask.astype(np.uint8)))
rle["counts"] = rle["counts"].decode("utf-8")

# 將 RLE 解碼為遮罩
decoded_mask = mask_utils.decode(rle)
```

## 效能最佳化

### GPU 記憶體

```python
# 對於有限的 VRAM，使用較小的模型
sam = sam_model_registry["vit_b"](checkpoint="sam_vit_b_01ec64.pth")

# 批次處理影像
# 在大型批次之間清除 CUDA 快取
torch.cuda.empty_cache()
```

### 速度最佳化

```python
# 使用半精度 (Half precision)
sam = sam.half()

# 減少自動生成的點數
mask_generator = SamAutomaticMaskGenerator(
    model=sam,
    points_per_side=16,  # 預設為 32
)

# 部署時使用 ONNX
# 搭配 --return-single-mask 匯出以加速推論
```

## 常見問題

| 問題 | 解決方案 |
|-------|----------|
| 記憶體不足 | 使用 ViT-B 模型，縮小影像尺寸 |
| 推論緩慢 | 使用 ViT-B，減少 points_per_side |
| 遮罩品質不佳 | 嘗試不同的提示，組合使用框與點 |
| 邊緣偽影 | 使用 stability_score 進行篩選 |
| 遺漏小物件 | 增加 points_per_side |

## 參考資料

- **[進階用法](references/advanced-usage_zh_TW.md)** - 批次處理、微調與整合
- **[疑難排解](references/troubleshooting_zh_TW.md)** - 常見問題與解決方案

## 資源

- **GitHub**: https://github.com/facebookresearch/segment-anything
- **論文**: https://arxiv.org/abs/2304.02643
- **展示 (Demo)**: https://segment-anything.com
- **SAM 2 (影片)**: https://github.com/facebookresearch/segment-anything-2
- **HuggingFace**: https://huggingface.co/facebook/sam-vit-huge
