---
name: llava
description: 大型語言與視覺助手 (Large Language and Vision Assistant)。支援視覺指令微調 (visual instruction tuning) 與基於影像的對話。結合了 CLIP 視覺編碼器與 Vicuna/LLaMA 語言模型。支援多輪影像對話、視覺問答 (VQA) 與指令遵循。適用於視覺語言聊天機器人或影像理解任務。最適合用於對話式影像分析。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [transformers, torch, pillow]
metadata:
  hermes:
    tags: [LLaVA, 視覺語言, 多模態, 視覺問答, 影像對話, CLIP, Vicuna, 對話式 AI, 指令微調, VQA]

---

# LLaVA - 大型語言與視覺助手

用於對話式影像理解的開源視覺語言模型。

## 何時使用 LLaVA

**在以下情況使用：**
- 建構視覺語言聊天機器人
- 視覺問答 (Visual Question Answering, VQA)
- 影像描述與標註 (Captioning)
- 多輪影像對話
- 視覺指令遵循
- 包含影像的文件理解

**指標**：
- **GitHub 星星數超過 23,000**
- 具備達到 GPT-4V 等級的能力 (以此為目標)
- Apache 2.0 授權
- 提供多種模型大小 (7B-34B 參數)

**改用替代方案**：
- **GPT-4V**：最高品質，基於 API
- **CLIP**：簡單的零樣本 (zero-shot) 分類
- **BLIP-2**：僅用於影像標註時效果更好
- **Flamingo**：研究性質，非開源

## 快速入門

### 安裝

```bash
# 複製儲存庫
git clone https://github.com/haotian-liu/LLaVA
cd LLaVA

# 安裝
pip install -e .
```

### 基本用法

```python
from llava.model.builder import load_pretrained_model
from llava.mm_utils import get_model_name_from_path, process_images, tokenizer_image_token
from llava.constants import IMAGE_TOKEN_INDEX, DEFAULT_IMAGE_TOKEN
from llava.conversation import conv_templates
from PIL import Image
import torch

# 載入模型
model_path = "liuhaotian/llava-v1.5-7b"
tokenizer, model, image_processor, context_len = load_pretrained_model(
    model_path=model_path,
    model_base=None,
    model_name=get_model_name_from_path(model_path)
)

# 載入影像
image = Image.open("image.jpg")
image_tensor = process_images([image], image_processor, model.config)
image_tensor = image_tensor.to(model.device, dtype=torch.float16)

# 建立對話
conv = conv_templates["llava_v1"].copy()
conv.append_message(conv.roles[0], DEFAULT_IMAGE_TOKEN + "\nWhat is in this image?")
conv.append_message(conv.roles[1], None)
prompt = conv.get_prompt()

# 產生回應
input_ids = tokenizer_image_token(prompt, tokenizer, IMAGE_TOKEN_INDEX, return_tensors='pt').unsqueeze(0).to(model.device)

with torch.inference_mode():
    output_ids = model.generate(
        input_ids,
        images=image_tensor,
        do_sample=True,
        temperature=0.2,
        max_new_tokens=512
    )

response = tokenizer.decode(output_ids[0], skip_special_tokens=True).strip()
print(response)
```

## 可用模型

| 模型 | 參數數量 | 顯示記憶體 (VRAM) | 品質 |
|-------|------------|------|---------|
| LLaVA-v1.5-7B | 7B | ~14 GB | 良好 |
| LLaVA-v1.5-13B | 13B | ~28 GB | 較好 |
| LLaVA-v1.6-34B | 34B | ~70 GB | 最佳 |

```python
# 載入不同模型
model_7b = "liuhaotian/llava-v1.5-7b"
model_13b = "liuhaotian/llava-v1.5-13b"
model_34b = "liuhaotian/llava-v1.6-34b"

# 使用 4-bit 量化以降低 VRAM 需求
load_4bit = True  # 減少約 4 倍的 VRAM 佔用
```

## CLI 用法

```bash
# 單張影像查詢
python -m llava.serve.cli \
    --model-path liuhaotian/llava-v1.5-7b \
    --image-file image.jpg \
    --query "What is in this image?"

# 多輪對話
python -m llava.serve.cli \
    --model-path liuhaotian/llava-v1.5-7b \
    --image-file image.jpg
# 接著可以互動式輸入問題
```

## Web UI (Gradio)

```bash
# 啟動 Gradio 介面
python -m llava.serve.gradio_web_server \
    --model-path liuhaotian/llava-v1.5-7b \
    --load-4bit  # 選填：減少 VRAM 需求

# 透過 http://localhost:7860 存取
```

## 多輪對話

```python
# 初始化對話
conv = conv_templates["llava_v1"].copy()

# 第 1 輪
conv.append_message(conv.roles[0], DEFAULT_IMAGE_TOKEN + "\nWhat is in this image?")
conv.append_message(conv.roles[1], None)
response1 = generate(conv, model, image)  # "A dog playing in a park"

# 第 2 輪
conv.messages[-1][1] = response1  # 新增先前的回應
conv.append_message(conv.roles[0], "What breed is the dog?")
conv.append_message(conv.roles[1], None)
response2 = generate(conv, model, image)  # "Golden Retriever"

# 第 3 輪
conv.messages[-1][1] = response2
conv.append_message(conv.roles[0], "What time of day is it?")
conv.append_message(conv.roles[1], None)
response3 = generate(conv, model, image)
```

## 常見任務

### 影像標註 (Image captioning)

```python
question = "Describe this image in detail."
response = ask(model, image, question)
```

### 視覺問答 (VQA)

```python
question = "How many people are in the image?"
response = ask(model, image, question)
```

### 物件偵測 (文本形式)

```python
question = "List all the objects you can see in this image."
response = ask(model, image, question)
```

### 場景理解

```python
question = "What is happening in this scene?"
response = ask(model, image, question)
```

### 文件理解

```python
question = "What is the main topic of this document?"
response = ask(model, document_image, question)
```

## 訓練自訂模型

```bash
# 階段 1：特徵對齊 (使用 558K 個影像-標註對)
bash scripts/v1_5/pretrain.sh

# 階段 2：視覺指令微調 (使用 150K 個指令資料)
bash scripts/v1_5/finetune.sh
```

## 量化 (減少 VRAM 需求)

```python
# 4-bit 量化
tokenizer, model, image_processor, context_len = load_pretrained_model(
    model_path="liuhaotian/llava-v1.5-13b",
    model_base=None,
    model_name=get_model_name_from_path("liuhaotian/llava-v1.5-13b"),
    load_4bit=True  # 減少約 4 倍 VRAM 佔用
)

# 8-bit 量化
load_8bit=True  # 減少約 2 倍 VRAM 佔用
```

## 最佳實踐

1. **從 7B 模型開始** - 品質良好且 VRAM 需求在可控範圍內
2. **使用 4-bit 量化** - 顯著減少 VRAM 需求
3. **需要 GPU** - CPU 推理速度極慢
4. **明確的提示詞** - 具體的問題能獲得更好的答案
5. **多輪對話** - 維持對話上下文
6. **溫度 (Temperature) 0.2-0.7** - 平衡創造力與一致性
7. **max_new_tokens 512-1024** - 獲得詳細的回應
8. **批次處理** - 循序處理多張影像

## 效能

| 模型 | VRAM (FP16) | VRAM (4-bit) | 速度 (tokens/s) |
|-------|-------------|--------------|------------------|
| 7B | ~14 GB | ~4 GB | ~20 |
| 13B | ~28 GB | ~8 GB | ~12 |
| 34B | ~70 GB | ~18 GB | ~5 |

*於 A100 GPU 測試*

## 基準測試 (Benchmarks)

LLaVA 在以下測試中獲得極具競爭力的分數：
- **VQAv2**: 78.5%
- **GQA**: 62.0%
- **MM-Vet**: 35.4%
- **MMBench**: 64.3%

## 限制

1. **幻覺 (Hallucinations)** - 可能會描述影像中不存在的事物
2. **空間推理** - 在處理精確位置時較為吃力
3. **小型文本** - 難以閱讀細小的字體
4. **物件計數** - 針對大量物件計數時不夠精確
5. **VRAM 需求** - 需要強大的 GPU
6. **推理速度** - 比 CLIP 慢

## 與框架整合

### LangChain

```python
from langchain.llms.base import LLM

class LLaVALLM(LLM):
    def _call(self, prompt, stop=None):
        # 自訂 LLaVA 推理邏輯
        return response

llm = LLaVALLM()
```

### Gradio 應用程式

```python
import gradio as gr

def chat(image, text, history):
    response = ask_llava(model, image, text)
    return response

demo = gr.ChatInterface(
    chat,
    additional_inputs=[gr.Image(type="pil")],
    title="LLaVA Chat"
)
demo.launch()
```

## 資源

- **GitHub**: https://github.com/haotian-liu/LLaVA ⭐ 23,000+
- **論文**: https://arxiv.org/abs/2304.08485
- **展示 (Demo)**: https://llava.hliu.cc
- **模型**: https://huggingface.co/liuhaotian
- **授權**: Apache 2.0
