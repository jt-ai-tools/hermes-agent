# Segment Anything 疑難排解指南

## 安裝問題

### CUDA 無法使用

**錯誤訊息**：`RuntimeError: CUDA not available`

**解決方案**：
```python
# 檢查 CUDA 是否可用
import torch
print(torch.cuda.is_available())
print(torch.version.cuda)

# 安裝支援 CUDA 的 PyTorch
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121

# 如果 CUDA 可用但 SAM 未使用 GPU
sam = sam_model_registry["vit_h"](checkpoint="sam_vit_h_4b8939.pth")
sam.to("cuda")  # 明確移動至 GPU
```

### 匯入錯誤 (Import errors)

**錯誤訊息**：`ModuleNotFoundError: No module named 'segment_anything'`

**解決方案**：
```bash
# 從 GitHub 安裝
pip install git+https://github.com/facebookresearch/segment-anything.git

# 或者複製儲存庫後安裝
git clone https://github.com/facebookresearch/segment-anything.git
cd segment-anything
pip install -e .

# 驗證安裝
python -c "from segment_anything import sam_model_registry; print('OK')"
```

### 缺少相依套件

**錯誤訊息**：`ModuleNotFoundError: No module named 'cv2'` 或類似訊息

**解決方案**：
```bash
# 安裝所有選配的相依套件
pip install opencv-python pycocotools matplotlib onnxruntime onnx

# 若在 Windows 上安裝 pycocotools
pip install pycocotools-windows
```

## 模型載入問題

### 找不到權重檔 (Checkpoint not found)

**錯誤訊息**：`FileNotFoundError: checkpoint file not found`

**解決方案**：
```bash
# 下載正確的權重檔 (Checkpoint)
wget https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth

# 驗證檔案完整性
md5sum sam_vit_h_4b8939.pth
# 預期結果：a7bf3b02f3ebf1267aba913ff637d9a2

# 使用絕對路徑
sam = sam_model_registry["vit_h"](checkpoint="/full/path/to/sam_vit_h_4b8939.pth")
```

### 模型類型不匹配

**錯誤訊息**：`KeyError: 'unexpected key in state_dict'`

**解決方案**：
```python
# 確保模型類型與權重檔相符
# vit_h 權重檔 → vit_h 模型
sam = sam_model_registry["vit_h"](checkpoint="sam_vit_h_4b8939.pth")

# vit_l 權重檔 → vit_l 模型
sam = sam_model_registry["vit_l"](checkpoint="sam_vit_l_0b3195.pth")

# vit_b 權重檔 → vit_b 模型
sam = sam_model_registry["vit_b"](checkpoint="sam_vit_b_01ec64.pth")
```

### 載入時記憶體不足

**錯誤訊息**：載入模型時出現 `CUDA out of memory`

**解決方案**：
```python
# 使用較小的模型
sam = sam_model_registry["vit_b"](checkpoint="sam_vit_b_01ec64.pth")

# 先載入至 CPU，再移動至 GPU
sam = sam_model_registry["vit_h"](checkpoint="sam_vit_h_4b8939.pth")
sam.to("cpu")
torch.cuda.empty_cache()
sam.to("cuda")

# 使用半精度 (Half precision)
sam = sam_model_registry["vit_h"](checkpoint="sam_vit_h_4b8939.pth")
sam = sam.half()
sam.to("cuda")
```

## 推論問題

### 圖像格式錯誤

**錯誤訊息**：`ValueError: expected input to have 3 channels`

**解決方案**：
```python
import cv2

# 確保為 RGB 格式
image = cv2.imread("image.jpg")
image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)  # BGR 轉 RGB

# 將灰階圖轉換為 RGB
if len(image.shape) == 2:
    image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)

# 處理 RGBA
if image.shape[2] == 4:
    image = image[:, :, :3]  # 捨棄 Alpha 通道
```

### 座標錯誤

**錯誤訊息**：`IndexError: index out of bounds` 或遮罩位置不正確

**解決方案**：
```python
# 確保座標為 (x, y) 而非 (row, col)
# x = 欄索引 (Column index)，y = 列索引 (Row index)
point = np.array([[x, y]])  # 正確

# 驗證座標是否在圖像範圍內
h, w = image.shape[:2]
assert 0 <= x < w and 0 <= y < h, "點位超出圖像範圍"

# 對於邊界框 (Bounding boxes)：[x1, y1, x2, y2]
box = np.array([x1, y1, x2, y2])
assert x1 < x2 and y1 < y2, "無效的邊界框座標"
```

### 遮罩為空或不正確

**問題描述**：生成的遮罩與預期的物件不符

**解決方案**：
```python
# 嘗試多個提示點 (Prompts)
input_points = np.array([[x1, y1], [x2, y2]])
input_labels = np.array([1, 1])  # 多個前景點

# 加入背景點
input_points = np.array([[obj_x, obj_y], [bg_x, bg_y]])
input_labels = np.array([1, 0])  # 1=前景，0=背景

# 對於大型物件使用邊界框提示
box = np.array([x1, y1, x2, y2])
masks, scores, _ = predictor.predict(box=box, multimask_output=False)

# 合併邊界框與提示點
masks, scores, _ = predictor.predict(
    point_coords=np.array([[center_x, center_y]]),
    point_labels=np.array([1]),
    box=np.array([x1, y1, x2, y2]),
    multimask_output=True
)

# 檢查分數並選擇最佳結果
print(f"Scores: {scores}")
best_mask = masks[np.argmax(scores)]
```

### 推論速度過慢

**問題描述**：預測耗時過長

**解決方案**：
```python
# 使用較小的模型
sam = sam_model_registry["vit_b"](checkpoint="sam_vit_b_01ec64.pth")

# 重用圖像嵌入 (Image embeddings)
predictor.set_image(image)  # 僅計算一次
for point in points:
    masks, _, _ = predictor.predict(...)  # 速度快，重用嵌入結果

# 減少自動生成時的採樣點
mask_generator = SamAutomaticMaskGenerator(
    model=sam,
    points_per_side=16,  # 預設為 32
)

# 使用 ONNX 進行佈署
# 匯出指令：python scripts/export_onnx_model.py --return-single-mask
```

## 自動生成遮罩問題

### 遮罩數量過多

**問題描述**：生成了數千個重疊的遮罩

**解決方案**：
```python
mask_generator = SamAutomaticMaskGenerator(
    model=sam,
    points_per_side=16,          # 從 32 減少
    pred_iou_thresh=0.92,        # 從 0.88 提高
    stability_score_thresh=0.98,  # 從 0.95 提高
    box_nms_thresh=0.5,          # 使用更激進的 NMS (非極大值抑制)
    min_mask_region_area=500,    # 移除過小的遮罩
)
```

### 遮罩數量過少

**問題描述**：自動生成時漏掉某些物件

**解決方案**：
```python
mask_generator = SamAutomaticMaskGenerator(
    model=sam,
    points_per_side=64,          # 提高取樣密度
    pred_iou_thresh=0.80,        # 降低門檻
    stability_score_thresh=0.85,  # 降低門檻
    crop_n_layers=2,             # 加入多尺度裁剪 (Multi-scale)
    min_mask_region_area=0,      # 保留所有遮罩
)
```

### 漏掉微小物件

**問題描述**：自動生成時漏掉微小的物件

**解決方案**：
```python
# 使用裁剪層 (Crop layers) 進行多尺度檢測
mask_generator = SamAutomaticMaskGenerator(
    model=sam,
    crop_n_layers=2,
    crop_n_points_downscale_factor=1,  # 不減少裁剪區域中的採樣點
    min_mask_region_area=10,  # 設定極小的最小值
)

# 或者處理圖像區塊 (Patches)
def segment_with_patches(image, patch_size=512, overlap=64):
    h, w = image.shape[:2]
    all_masks = []

    for y in range(0, h, patch_size - overlap):
        for x in range(0, w, patch_size - overlap):
            patch = image[y:y+patch_size, x:x+patch_size]
            masks = mask_generator.generate(patch)

            # 將遮罩偏移回原始座標
            for m in masks:
                m['bbox'][0] += x
                m['bbox'][1] += y
                # 同樣需要偏移分割遮罩

            all_masks.extend(masks)

    return all_masks
```

## 記憶體問題

### CUDA 記憶體不足

**錯誤訊息**：`torch.cuda.OutOfMemoryError: CUDA out of memory`

**解決方案**：
```python
# 使用較小的模型
sam = sam_model_registry["vit_b"](checkpoint="sam_vit_b_01ec64.pth")

# 在處理每張圖像之間清空快取
torch.cuda.empty_cache()

# 循序處理圖像，而非批次處理
for image in images:
    predictor.set_image(image)
    masks, _, _ = predictor.predict(...)
    torch.cuda.empty_cache()

# 縮小圖像尺寸
max_size = 1024
h, w = image.shape[:2]
if max(h, w) > max_size:
    scale = max_size / max(h, w)
    image = cv2.resize(image, (int(w*scale), int(h*scale)))

# 對於大型批次處理使用 CPU
sam.to("cpu")
```

### 系統記憶體 (RAM) 不足

**問題描述**：系統 RAM 耗盡

**解決方案**：
```python
# 一次僅處理一張圖像
for img_path in image_paths:
    image = cv2.imread(img_path)
    masks = process_image(image)
    save_results(masks)
    del image, masks
    gc.collect()

# 使用生成器 (Generators) 替代列表 (Lists)
def generate_masks_lazy(image_paths):
    for path in image_paths:
        image = cv2.imread(path)
        masks = mask_generator.generate(image)
        yield path, masks
```

## ONNX 匯出問題

### 匯出失敗

**錯誤訊息**：各種匯出錯誤

**解決方案**：
```bash
# 安裝正確的 ONNX 版本
pip install onnx==1.14.0 onnxruntime==1.15.0

# 使用正確的 opset 版本
python scripts/export_onnx_model.py \
    --checkpoint sam_vit_h_4b8939.pth \
    --model-type vit_h \
    --output sam.onnx \
    --opset 17
```

### ONNX 執行階段錯誤

**錯誤訊息**：推論時出現 `ONNXRuntimeError`

**解決方案**：
```python
import onnxruntime

# 檢查可用的提供者 (Providers)
print(onnxruntime.get_available_providers())

# 如果 GPU 失敗，則使用 CPU 提供者
session = onnxruntime.InferenceSession(
    "sam.onnx",
    providers=['CPUExecutionProvider']
)

# 驗證輸入形狀 (Input shapes)
for input in session.get_inputs():
    print(f"{input.name}: {input.shape}")
```

## HuggingFace 整合問題

### 處理器 (Processor) 錯誤

**錯誤訊息**：SamProcessor 相關問題

**解決方案**：
```python
from transformers import SamModel, SamProcessor

# 使用相匹配的處理器與模型
model = SamModel.from_pretrained("facebook/sam-vit-huge")
processor = SamProcessor.from_pretrained("facebook/sam-vit-huge")

# 確保輸入格式正確
input_points = [[[x, y]]]  # 批次維度需使用巢狀列表
inputs = processor(image, input_points=input_points, return_tensors="pt")

# 正確進行後處理
masks = processor.image_processor.post_process_masks(
    outputs.pred_masks.cpu(),
    inputs["original_sizes"].cpu(),
    inputs["reshaped_input_sizes"].cpu()
)
```

## 品質問題

### 遮罩邊緣呈鋸齒狀

**問題描述**：遮罩邊緣粗糙且有像素感

**解決方案**：
```python
import cv2
from scipy import ndimage

def smooth_mask(mask, sigma=2):
    """平滑遮罩邊緣。"""
    # 高斯模糊
    smooth = ndimage.gaussian_filter(mask.astype(float), sigma=sigma)
    return smooth > 0.5

def refine_edges(mask, kernel_size=5):
    """使用形態學操作優化遮罩邊緣。"""
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (kernel_size, kernel_size))
    # 閉運算填補小縫隙
    closed = cv2.morphologyEx(mask.astype(np.uint8), cv2.MORPH_CLOSE, kernel)
    # 開運算移除雜訊
    opened = cv2.morphologyEx(closed, cv2.MORPH_OPEN, kernel)
    return opened.astype(bool)
```

### 分割不完整

**問題描述**：遮罩未覆蓋整個物件

**解決方案**：
```python
# 加入多個提示點
input_points = np.array([
    [obj_center_x, obj_center_y],
    [obj_left_x, obj_center_y],
    [obj_right_x, obj_center_y],
    [obj_center_x, obj_top_y],
    [obj_center_x, obj_bottom_y]
])
input_labels = np.array([1, 1, 1, 1, 1])

# 使用邊界框
masks, _, _ = predictor.predict(
    box=np.array([x1, y1, x2, y2]),
    multimask_output=False
)

# 疊代優化 (Iterative refinement)
mask_input = None
for point in points:
    masks, scores, logits = predictor.predict(
        point_coords=point.reshape(1, 2),
        point_labels=np.array([1]),
        mask_input=mask_input,
        multimask_output=False
    )
    mask_input = logits
```

## 常見錯誤訊息

| 錯誤訊息 | 原因 | 解決方案 |
|-------|-------|----------|
| `CUDA out of memory` | GPU 記憶體已滿 | 使用較小模型，清空快取 |
| `expected 3 channels` | 圖像格式錯誤 | 轉換為 RGB |
| `index out of bounds` | 無效座標 | 檢查提示點/邊界框範圍 |
| `checkpoint not found` | 路徑不正確 | 使用絕對路徑 |
| `unexpected key` | 模型與權重不匹配 | 檢查模型類型 |
| `invalid box coordinates` | x1 > x2 或 y1 > y2 | 修正邊界框格式 |

## 尋求協助

1. **GitHub Issues**: https://github.com/facebookresearch/segment-anything/issues
2. **HuggingFace 論壇**: https://discuss.huggingface.co
3. **論文**: https://arxiv.org/abs/2304.02643

### 回報問題時

請提供：
- Python 版本
- PyTorch 版本：`python -c "import torch; print(torch.__version__)"`
- CUDA 版本：`python -c "import torch; print(torch.version.cuda)"`
- SAM 模型類型 (vit_b/l/h)
- 完整的錯誤追蹤 (Traceback)
- 最小可重複執行的程式碼 (Minimal reproducible code)
