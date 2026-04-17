# LLaVA 訓練指南

LLaVA 模型訓練與微調 (Fine-tuning) 指南。

## 訓練階段

### 階段 1：特徵對齊（預訓練）

**目的**：將視覺編碼器 (Vision Encoder) 與語言模型對齊

**資料**：55.8 萬對影像-標題對 (CC3M 子集)

```bash
# 下載預訓練好的投射器 (Projector) 或從頭開始訓練
bash scripts/v1_5/pretrain.sh
```

**配置：**
- 基礎模型：Vicuna-7B 或 LLaMA-2-7B
- 視覺編碼器：CLIP ViT-L/14
- 訓練時間：在 8 張 A100 上約 20 小時

### 階段 2：視覺指令微調 (Visual Instruction Tuning)

**目的**：教導模型遵循視覺指令

**資料**：15 萬筆由 GPT 生成的多模態指令資料

```bash
# 使用指令資料進行微調
bash scripts/v1_5/finetune.sh
```

**配置：**
- 疊代次數 (Epochs)：1
- 批次大小 (Batch size)：128（分布在 8 張 GPU 上）
- 學習率 (Learning rate)：2e-5
- 訓練時間：在 8 張 A100 上約 24 小時

## 資料格式

### 指令資料格式

```json
[
    {
        "id": "001",
        "image": "path/to/image.jpg",
        "conversations": [
            {
                "from": "human",
                "value": "<image>\n這張圖片裡有什麼？"
            },
            {
                "from": "gpt",
                "value": "這張圖片顯示一隻狗在公園裡玩耍。"
            },
            {
                "from": "human",
                "value": "這隻狗是什麼品種？"
            },
            {
                "from": "gpt",
                "value": "看起來像是黃金獵犬。"
            }
        ]
    }
]
```

## 在自定義資料上進行微調

### 準備您的資料

```python
import json

# 建立指令資料
data = []
for image_path, qa_pairs in your_dataset:
    conversations = []
    for q, a in qa_pairs:
        conversations.append({"from": "human", "value": f"<image>\n{q}"})
        conversations.append({"from": "gpt", "value": a})

    data.append({
        "id": str(len(data)),
        "image": image_path,
        "conversations": conversations
    })

# 儲存
with open("custom_data.json", "w") as f:
    json.dump(data, f, indent=2)
```

### 微調腳本

```bash
#!/bin/bash

# 設置路徑
DATA_PATH="custom_data.json"
IMAGE_FOLDER="path/to/images"
MODEL_PATH="liuhaotian/llava-v1.5-7b"
OUTPUT_DIR="./checkpoints/llava-custom"

# 微調
deepspeed llava/train/train_mem.py \
    --deepspeed ./scripts/zero2.json \
    --model_name_or_path $MODEL_PATH \
    --version v1 \
    --data_path $DATA_PATH \
    --image_folder $IMAGE_FOLDER \
    --vision_tower openai/clip-vit-large-patch14-336 \
    --mm_projector_type mlp2x_gelu \
    --mm_vision_select_layer -2 \
    --mm_use_im_start_end False \
    --mm_use_im_patch_token False \
    --image_aspect_ratio pad \
    --group_by_modality_length True \
    --bf16 True \
    --output_dir $OUTPUT_DIR \
    --num_train_epochs 1 \
    --per_device_train_batch_size 16 \
    --per_device_eval_batch_size 4 \
    --gradient_accumulation_steps 1 \
    --evaluation_strategy "no" \
    --save_strategy "steps" \
    --save_steps 50000 \
    --save_total_limit 1 \
    --learning_rate 2e-5 \
    --weight_decay 0. \
    --warmup_ratio 0.03 \
    --lr_scheduler_type "cosine" \
    --logging_steps 1 \
    --tf32 True \
    --model_max_length 2048 \
    --gradient_checkpointing True \
    --dataloader_num_workers 4 \
    --lazy_preprocess True \
    --report_to wandb
```

## LoRA 微調（節省記憶體）

```python
from peft import LoraConfig, get_peft_model

# LoRA 配置
lora_config = LoraConfig(
    r=8,  # LoRA 秩 (Rank)
    lora_alpha=16,
    target_modules=["q_proj", "v_proj"],
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM"
)

# 套用 LoRA
model = get_peft_model(base_model, lora_config)

# 使用顯著減少的記憶體進行訓練
```

## 硬體需求

### 全量微調 (Full fine-tuning)

- **7B 模型**：8 張 A100 (40GB)
- **13B 模型**：8 張 A100 (80GB)
- **訓練時間**：20-48 小時

### LoRA 微調

- **7B 模型**：1 張 A100 (40GB)
- **13B 模型**：2 張 A100 (40GB)
- **訓練時間**：10-24 小時

## 最佳實踐

1. **從預訓練模型開始** - 不要從頭開始訓練
2. **使用 LoRA 以提升效率** - 減少 10 倍記憶體需求
3. **質重於量** - 1,000 筆高品質資料優於 10,000 筆低品質資料
4. **多輪對話** - 比單次問答更具吸引力
5. **多樣化的圖片** - 涵蓋不同的情境
6. **清晰的指令** - 具體的問題能獲得更好的回答
7. **監控損失函數 (Loss)** - 應該平滑地下降
8. **儲存檢查點** - 訓練可能會失敗
9. **定期測試** - 在保留集 (Held-out set) 上進行驗證
10. **使用 DeepSpeed** - 進行多 GPU 訓練

## 資源

- **訓練腳本**：https://github.com/haotian-liu/LLaVA/tree/main/scripts
- **資料格式**：https://github.com/haotian-liu/LLaVA/blob/main/docs/Data.md
- **論文**：https://arxiv.org/abs/2304.08485
