# Segment Anything 高階使用指南

## SAM 2 (影片分割)

### 概述

SAM 2 將 SAM 擴展到影片分割，並採用串流記憶體架構：

```bash
pip install git+https://github.com/facebookresearch/segment-anything-2.git
```

### 影片分割

```python
from sam2.build_sam import build_sam2_video_predictor

predictor = build_sam2_video_predictor("sam2_hiera_l.yaml", "sam2_hiera_large.pt")

# 使用影片初始化
predictor.init_state(video_path="video.mp4")

# 在第一影格添加提示
predictor.add_new_points(
    frame_idx=0,
    obj_id=1,
    points=[[100, 200]],
    labels=[1]
)

# 在影片中進行傳播
for frame_idx, masks in predictor.propagate_in_video():
    # masks 包含所有追蹤物件的分割結果
    process_frame(frame_idx, masks)
```

### SAM 2 vs SAM 比較

| 特性 | SAM | SAM 2 |
|---------|-----|-------|
| 輸入 | 僅限圖像 | 圖像 + 影片 |
| 架構 | ViT + 解碼器 | Hiera + 記憶體 |
| 記憶體 | 每張圖像獨立 | 串流記憶體庫 |
| 追蹤 | 否 | 是，跨影格追蹤 |
| 模型 | ViT-B/L/H | Hiera-T/S/B+/L |

## Grounded SAM (文字提示分割)

### 設定

```bash
pip install groundingdino-py
pip install git+https://github.com/facebookresearch/segment-anything.git
```

### 文字轉遮罩管線 (Text-to-mask pipeline)

```python
from groundingdino.util.inference import load_model, predict
from segment_anything import sam_model_registry, SamPredictor
import cv2

# 載入 Grounding DINO
grounding_model = load_model("groundingdino_swint_ogc.pth", "GroundingDINO_SwinT_OGC.py")

# 載入 SAM
sam = sam_model_registry["vit_h"](checkpoint="sam_vit_h_4b8939.pth")
predictor = SamPredictor(sam)

def text_to_mask(image, text_prompt, box_threshold=0.3, text_threshold=0.25):
    """根據文字描述生成遮罩。"""
    # 從文字獲取邊界框
    boxes, logits, phrases = predict(
        model=grounding_model,
        image=image,
        caption=text_prompt,
        box_threshold=box_threshold,
        text_threshold=text_threshold
    )

    # 使用 SAM 生成遮罩
    predictor.set_image(image)

    masks = []
    for box in boxes:
        # 將標準化後的框轉換為像素座標
        h, w = image.shape[:2]
        box_pixels = box * np.array([w, h, w, h])

        mask, score, _ = predictor.predict(
            box=box_pixels,
            multimask_output=False
        )
        masks.append(mask[0])

    return masks, boxes, phrases

# 使用範例
image = cv2.imread("image.jpg")
image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

masks, boxes, phrases = text_to_mask(image, "person . dog . car")
```

## 批次處理 (Batched Processing)

### 高效的多圖處理

```python
import torch
from segment_anything import SamPredictor, sam_model_registry

class BatchedSAM:
    def __init__(self, checkpoint, model_type="vit_h", device="cuda"):
        self.sam = sam_model_registry[model_type](checkpoint=checkpoint)
        self.sam.to(device)
        self.predictor = SamPredictor(self.sam)
        self.device = device

    def process_batch(self, images, prompts):
        """處理多張圖像及其對應的提示。"""
        results = []

        for image, prompt in zip(images, prompts):
            self.predictor.set_image(image)

            if "point" in prompt:
                masks, scores, _ = self.predictor.predict(
                    point_coords=prompt["point"],
                    point_labels=prompt["label"],
                    multimask_output=True
                )
            elif "box" in prompt:
                masks, scores, _ = self.predictor.predict(
                    box=prompt["box"],
                    multimask_output=False
                )

            results.append({
                "masks": masks,
                "scores": scores,
                "best_mask": masks[np.argmax(scores)]
            })

        return results

# 使用範例
batch_sam = BatchedSAM("sam_vit_h_4b8939.pth")

images = [cv2.imread(f"image_{i}.jpg") for i in range(10)]
prompts = [{"point": np.array([[100, 100]]), "label": np.array([1])} for _ in range(10)]

results = batch_sam.process_batch(images, prompts)
```

### 平行自動生成遮罩

```python
from concurrent.futures import ThreadPoolExecutor
from segment_anything import SamAutomaticMaskGenerator

def generate_masks_parallel(images, num_workers=4):
    """平行生成多張圖像的遮罩。"""
    # 注意：每個工作執行緒需要自己的模型實例
    def worker_init():
        sam = sam_model_registry["vit_b"](checkpoint="sam_vit_b_01ec64.pth")
        return SamAutomaticMaskGenerator(sam)

    generators = [worker_init() for _ in range(num_workers)]

    def process_image(args):
        idx, image = args
        generator = generators[idx % num_workers]
        return generator.generate(image)

    with ThreadPoolExecutor(max_workers=num_workers) as executor:
        results = list(executor.map(process_image, enumerate(images)))

    return results
```

## 自定義整合 (Custom Integration)

### FastAPI 服務

```python
from fastapi import FastAPI, File, UploadFile
from pydantic import BaseModel
import numpy as np
import cv2
import io

app = FastAPI()

# 僅載入一次模型
sam = sam_model_registry["vit_h"](checkpoint="sam_vit_h_4b8939.pth")
sam.to("cuda")
predictor = SamPredictor(sam)

class PointPrompt(BaseModel):
    x: int
    y: int
    label: int = 1

@app.post("/segment/point")
async def segment_with_point(
    file: UploadFile = File(...),
    points: list[PointPrompt] = []
):
    # 讀取圖像
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    # 設定圖像
    predictor.set_image(image)

    # 準備提示
    point_coords = np.array([[p.x, p.y] for p in points])
    point_labels = np.array([p.label for p in points])

    # 生成遮罩
    masks, scores, _ = predictor.predict(
        point_coords=point_coords,
        point_labels=point_labels,
        multimask_output=True
    )

    best_idx = np.argmax(scores)

    return {
        "mask": masks[best_idx].tolist(),
        "score": float(scores[best_idx]),
        "all_scores": scores.tolist()
    }

@app.post("/segment/auto")
async def segment_automatic(file: UploadFile = File(...)):
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    mask_generator = SamAutomaticMaskGenerator(sam)
    masks = mask_generator.generate(image)

    return {
        "num_masks": len(masks),
        "masks": [
            {
                "bbox": m["bbox"],
                "area": m["area"],
                "predicted_iou": m["predicted_iou"],
                "stability_score": m["stability_score"]
            }
            for m in masks
        ]
    }
```

### Gradio 介面

```python
import gradio as gr
import numpy as np

# 載入模型
sam = sam_model_registry["vit_h"](checkpoint="sam_vit_h_4b8939.pth")
predictor = SamPredictor(sam)

def segment_image(image, evt: gr.SelectData):
    """分割點擊位置的物件。"""
    predictor.set_image(image)

    point = np.array([[evt.index[0], evt.index[1]]])
    label = np.array([1])

    masks, scores, _ = predictor.predict(
        point_coords=point,
        point_labels=label,
        multimask_output=True
    )

    best_mask = masks[np.argmax(scores)]

    # 在圖像上疊加遮罩
    overlay = image.copy()
    overlay[best_mask] = overlay[best_mask] * 0.5 + np.array([255, 0, 0]) * 0.5

    return overlay

with gr.Blocks() as demo:
    gr.Markdown("# SAM 互動式分割")
    gr.Markdown("點擊圖像中的物件進行分割")

    with gr.Row():
        input_image = gr.Image(label="輸入圖像", interactive=True)
        output_image = gr.Image(label="分割後的圖像")

    input_image.select(segment_image, inputs=[input_image], outputs=[output_image])

demo.launch()
```

## 微調 SAM (Fine-Tuning SAM)

### LoRA 微調 (實驗性)

```python
from peft import LoraConfig, get_peft_model
from transformers import SamModel

# 載入模型
model = SamModel.from_pretrained("facebook/sam-vit-base")

# 配置 LoRA
lora_config = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules=["qkv"],  # 注意力層
    lora_dropout=0.1,
    bias="none",
)

# 套用 LoRA
model = get_peft_model(model, lora_config)

# 訓練迴圈 (簡化版)
optimizer = torch.optim.AdamW(model.parameters(), lr=1e-4)

for batch in dataloader:
    outputs = model(
        pixel_values=batch["pixel_values"],
        input_points=batch["input_points"],
        input_labels=batch["input_labels"]
    )

    # 自定義損失函數 (例如：與 Ground Truth 的 IoU 損失)
    loss = compute_loss(outputs.pred_masks, batch["gt_masks"])
    loss.backward()
    optimizer.step()
    optimizer.zero_grad()
```

### MedSAM (醫學影像)

```python
# MedSAM 是針對醫學影像微調過的 SAM
# https://github.com/bowang-lab/MedSAM

from segment_anything import sam_model_registry, SamPredictor
import torch

# 載入 MedSAM 權重
medsam = sam_model_registry["vit_b"](checkpoint="medsam_vit_b.pth")
medsam.to("cuda")

predictor = SamPredictor(medsam)

# 處理醫學影像
# 如果需要，將灰階圖像轉換為 RGB
medical_image = cv2.imread("ct_scan.png", cv2.IMREAD_GRAYSCALE)
rgb_image = np.stack([medical_image] * 3, axis=-1)

predictor.set_image(rgb_image)

# 使用邊界框提示進行分割 (醫學影像中常用)
masks, scores, _ = predictor.predict(
    box=np.array([x1, y1, x2, y2]),
    multimask_output=False
)
```

## 進階遮罩處理 (Advanced Mask Processing)

### 遮罩細化 (Mask refinement)

```python
import cv2
from scipy import ndimage

def refine_mask(mask, kernel_size=5, iterations=2):
    """使用形態學操作細化遮罩。"""
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (kernel_size, kernel_size))

    # 閉運算 (Close) 填補小孔
    closed = cv2.morphologyEx(mask.astype(np.uint8), cv2.MORPH_CLOSE, kernel, iterations=iterations)

    # 開運算 (Open) 移除雜訊
    opened = cv2.morphologyEx(closed, cv2.MORPH_OPEN, kernel, iterations=iterations)

    return opened.astype(bool)

def fill_holes(mask):
    """填補遮罩中的空洞。"""
    filled = ndimage.binary_fill_holes(mask)
    return filled

def remove_small_regions(mask, min_area=100):
    """移除微小的不連續區域。"""
    labeled, num_features = ndimage.label(mask)
    sizes = ndimage.sum(mask, labeled, range(1, num_features + 1))

    # 僅保留大於 min_area 的區域
    mask_clean = np.zeros_like(mask)
    for i, size in enumerate(sizes, 1):
        if size >= min_area:
            mask_clean[labeled == i] = True

    return mask_clean
```

### 遮罩轉多邊形 (Mask to polygon conversion)

```python
import cv2

def mask_to_polygons(mask, epsilon_factor=0.01):
    """將二進位遮罩轉換為多邊形座標。"""
    contours, _ = cv2.findContours(
        mask.astype(np.uint8),
        cv2.RETR_EXTERNAL,
        cv2.CHAIN_APPROX_SIMPLE
    )

    polygons = []
    for contour in contours:
        epsilon = epsilon_factor * cv2.arcLength(contour, True)
        approx = cv2.approxPolyDP(contour, epsilon, True)
        polygon = approx.squeeze().tolist()
        if len(polygon) >= 3:  # 有效的多邊形
            polygons.append(polygon)

    return polygons

def polygons_to_mask(polygons, height, width):
    """將多邊形轉回二進位遮罩。"""
    mask = np.zeros((height, width), dtype=np.uint8)
    for polygon in polygons:
        pts = np.array(polygon, dtype=np.int32)
        cv2.fillPoly(mask, [pts], 1)
    return mask.astype(bool)
```

### 多尺度分割 (Multi-scale segmentation)

```python
def multiscale_segment(image, predictor, point, scales=[0.5, 1.0, 2.0]):
    """在多個尺度下生成遮罩並合併。"""
    h, w = image.shape[:2]
    masks_all = []

    for scale in scales:
        # 調整圖像大小
        new_h, new_w = int(h * scale), int(w * scale)
        scaled_image = cv2.resize(image, (new_w, new_h))
        scaled_point = (point * scale).astype(int)

        # 進行分割
        predictor.set_image(scaled_image)
        masks, scores, _ = predictor.predict(
            point_coords=scaled_point.reshape(1, 2),
            point_labels=np.array([1]),
            multimask_output=True
        )

        # 將遮罩調整回原始大小
        best_mask = masks[np.argmax(scores)]
        original_mask = cv2.resize(best_mask.astype(np.uint8), (w, h)) > 0.5

        masks_all.append(original_mask)

    # 合併遮罩 (多數決)
    combined = np.stack(masks_all, axis=0)
    final_mask = np.sum(combined, axis=0) >= len(scales) // 2 + 1

    return final_mask
```

## 效能優化 (Performance Optimization)

### TensorRT 加速

```python
import tensorrt as trt
import pycuda.driver as cuda
import pycuda.autoinit

def export_to_tensorrt(onnx_path, engine_path, fp16=True):
    """將 ONNX 模型轉換為 TensorRT 引擎。"""
    logger = trt.Logger(trt.Logger.WARNING)
    builder = trt.Builder(logger)
    network = builder.create_network(1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH))
    parser = trt.OnnxParser(network, logger)

    with open(onnx_path, 'rb') as f:
        if not parser.parse(f.read()):
            for error in range(parser.num_errors):
                print(parser.get_error(error))
            return None

    config = builder.create_builder_config()
    config.max_workspace_size = 1 << 30  # 1GB

    if fp16:
        config.set_flag(trt.BuilderFlag.FP16)

    engine = builder.build_engine(network, config)

    with open(engine_path, 'wb') as f:
        f.write(engine.serialize())

    return engine
```

### 記憶體高效推論 (Memory-efficient inference)

```python
class MemoryEfficientSAM:
    def __init__(self, checkpoint, model_type="vit_b"):
        self.sam = sam_model_registry[model_type](checkpoint=checkpoint)
        self.sam.eval()
        self.predictor = None

    def __enter__(self):
        self.sam.to("cuda")
        self.predictor = SamPredictor(self.sam)
        return self

    def __exit__(self, *args):
        self.sam.to("cpu")
        torch.cuda.empty_cache()

    def segment(self, image, points, labels):
        self.predictor.set_image(image)
        masks, scores, _ = self.predictor.predict(
            point_coords=points,
            point_labels=labels,
            multimask_output=True
        )
        return masks, scores

# 使用上下文管理器 (Context Manager) 自動清理
with MemoryEfficientSAM("sam_vit_b_01ec64.pth") as sam:
    masks, scores = sam.segment(image, points, labels)
# CUDA 記憶體會自動釋放
```

## 資料集生成 (Dataset Generation)

### 建立分割資料集

```python
import json

def generate_dataset(images_dir, output_dir, mask_generator):
    """從圖像生成分割資料集。"""
    annotations = []

    for img_path in Path(images_dir).glob("*.jpg"):
        image = cv2.imread(str(img_path))
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        # 生成遮罩
        masks = mask_generator.generate(image)

        # 篩選高品質遮罩
        good_masks = [m for m in masks if m["predicted_iou"] > 0.9]

        # 儲存標註資訊
        for i, mask_data in enumerate(good_masks):
            annotation = {
                "image_id": img_path.stem,
                "mask_id": i,
                "bbox": mask_data["bbox"],
                "area": mask_data["area"],
                "segmentation": mask_to_rle(mask_data["segmentation"]),
                "predicted_iou": mask_data["predicted_iou"],
                "stability_score": mask_data["stability_score"]
            }
            annotations.append(annotation)

    # 儲存資料集
    with open(output_dir / "annotations.json", "w") as f:
        json.dump(annotations, f)

    return annotations
```
