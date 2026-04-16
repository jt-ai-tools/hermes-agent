---
name: gguf-quantization
description: 用於高效 CPU/GPU 推論的 GGUF 格式與 llama.cpp 量化。適用於在消費級硬體、Apple Silicon 上部署模型，或是在不需要 GPU 的情況下，需要 2-8 bit 靈活量化時使用。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [llama-cpp-python>=0.2.0]
metadata:
  hermes:
    tags: [GGUF, 量化, llama.cpp, CPU 推論, Apple Silicon, 模型壓縮, 優化]

---

# GGUF - llama.cpp 的量化格式

GGUF (GPT-Generated Unified Format) 是 llama.cpp 的標準檔案格式，具備靈活的量化選項，能在 CPU、Apple Silicon 和 GPU 上實現高效推論。

## 何時使用 GGUF

**在以下情況下使用 GGUF：**
- 在消費級硬體 (筆記型電腦、桌上型電腦) 上部署
- 在具備 Metal 加速的 Apple Silicon (M1/M2/M3) 上執行
- 需要 CPU 推論而無 GPU 需求
- 想要靈活的量化選項 (Q2_K 到 Q8_0)
- 使用本地 AI 工具 (LM Studio, Ollama, text-generation-webui)

**主要優勢：**
- **通用硬體支援**：支援 CPU、Apple Silicon、NVIDIA、AMD
- **無需 Python 執行環境**：純 C/C++ 推論
- **靈活量化**：支援 2-8 bit 以及多種方法 (K-quants)
- **生態系統支援**：LM Studio、Ollama、koboldcpp 等工具皆有支援
- **imatrix**：重要性矩陣 (Importance matrix) 可提升低位元量化的品質

**改用其他替代方案的情況：**
- **AWQ/GPTQ**：在 NVIDIA GPU 上透過校準獲得最大準確度
- **HQQ**：針對 HuggingFace 提供快速且無需校準的量化
- **bitsandbytes**：與 transformers 函式庫簡單整合
- **TensorRT-LLM**：追求極速的 NVIDIA 生產環境部署

## 快速入門

### 安裝

```bash
# 複製 llama.cpp 儲存庫
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp

# 編譯 (CPU)
make

# 使用 CUDA 編譯 (NVIDIA)
make GGML_CUDA=1

# 使用 Metal 編譯 (Apple Silicon)
make GGML_METAL=1

# 安裝 Python 綁定 (選用)
pip install llama-cpp-python
```

### 將模型轉換為 GGUF

```bash
# 安裝依賴項
pip install -r requirements.txt

# 將 HuggingFace 模型轉換為 GGUF (FP16)
python convert_hf_to_gguf.py ./path/to/model --outfile model-f16.gguf

# 或指定輸出類型
python convert_hf_to_gguf.py ./path/to/model \
    --outfile model-f16.gguf \
    --outtype f16
```

### 量化模型

```bash
# 基礎量化為 Q4_K_M
./llama-quantize model-f16.gguf model-q4_k_m.gguf Q4_K_M

# 使用重要性矩陣進行量化 (品質更好)
./llama-imatrix -m model-f16.gguf -f calibration.txt -o model.imatrix
./llama-quantize --imatrix model.imatrix model-f16.gguf model-q4_k_m.gguf Q4_K_M
```

### 執行推論

```bash
# CLI 推論
./llama-cli -m model-q4_k_m.gguf -p "你好，你好嗎？"

# 互動模式
./llama-cli -m model-q4_k_m.gguf --interactive

# 使用 GPU 卸載 (Offload)
./llama-cli -m model-q4_k_m.gguf -ngl 35 -p "你好！"
```

## 量化類型

### K-quant 方法 (推薦)

| 類型 | 位元 (Bits) | 大小 (7B) | 品質 | 使用場景 |
|------|------|-----------|---------|----------|
| Q2_K | 2.5 | ~2.8 GB | 低 | 極致壓縮 |
| Q3_K_S | 3.0 | ~3.0 GB | 低-中 | 記憶體受限 |
| Q3_K_M | 3.3 | ~3.3 GB | 中 | 平衡型 |
| Q4_K_S | 4.0 | ~3.8 GB | 中-高 | 良好平衡 |
| Q4_K_M | 4.5 | ~4.1 GB | 高 | **推薦預設值** |
| Q5_K_S | 5.0 | ~4.6 GB | 高 | 品質導向 |
| Q5_K_M | 5.5 | ~4.8 GB | 非常高 | 高品質 |
| Q6_K | 6.0 | ~5.5 GB | 極佳 | 接近原始品質 |
| Q8_0 | 8.0 | ~7.2 GB | 最佳 | 最高品質 |

### 舊版 (Legacy) 方法

| 類型 | 說明 |
|------|-------------|
| Q4_0 | 4-bit, 基礎款 |
| Q4_1 | 4-bit 帶增量 |
| Q5_0 | 5-bit, 基礎款 |
| Q5_1 | 5-bit 帶增量 |

**建議**：使用 K-quant 方法 (Q4_K_M, Q5_K_M) 以獲得最佳的品質/大小比例。

## 轉換工作流程

### 工作流程 1：HuggingFace 轉 GGUF

```bash
# 1. 下載模型
huggingface-cli download meta-llama/Llama-3.1-8B --local-dir ./llama-3.1-8b

# 2. 轉換為 GGUF (FP16)
python convert_hf_to_gguf.py ./llama-3.1-8b \
    --outfile llama-3.1-8b-f16.gguf \
    --outtype f16

# 3. 量化
./llama-quantize llama-3.1-8b-f16.gguf llama-3.1-8b-q4_k_m.gguf Q4_K_M

# 4. 測試
./llama-cli -m llama-3.1-8b-q4_k_m.gguf -p "你好！" -n 50
```

### 工作流程 2：使用重要性矩陣 (更好品質)

```bash
# 1. 轉換為 GGUF
python convert_hf_to_gguf.py ./model --outfile model-f16.gguf

# 2. 建立校準文本 (多樣化的樣本)
cat > calibration.txt << 'EOF'
The quick brown fox jumps over the lazy dog.
Machine learning is a subset of artificial intelligence.
Python is a popular programming language.
# 新增更多樣化的文本樣本...
EOF

# 3. 生成重要性矩陣
./llama-imatrix -m model-f16.gguf \
    -f calibration.txt \
    --chunk 512 \
    -o model.imatrix \
    -ngl 35  # 如果可用，指定 GPU 層數
```

### 工作流程 3：多種格式量化

```bash
#!/bin/bash
MODEL="llama-3.1-8b-f16.gguf"
IMATRIX="llama-3.1-8b.imatrix"

# 生成一次 imatrix
./llama-imatrix -m $MODEL -f wiki.txt -o $IMATRIX -ngl 35

# 建立多種量化格式
for QUANT in Q4_K_M Q5_K_M Q6_K Q8_0; do
    OUTPUT="llama-3.1-8b-${QUANT,,}.gguf"
    ./llama-quantize --imatrix $IMATRIX $MODEL $OUTPUT $QUANT
    echo "已建立：$OUTPUT ($(du -h $OUTPUT | cut -f1))"
done
```

## Python 用法

### llama-cpp-python

```python
from llama_cpp import Llama

# 載入模型
llm = Llama(
    model_path="./model-q4_k_m.gguf",
    n_ctx=4096,          # 上下文視窗 (Context window)
    n_gpu_layers=35,     # GPU 卸載 (0 表示僅 CPU)
    n_threads=8          # CPU 執行緒
)

# 生成
output = llm(
    "什麼是機器學習？",
    max_tokens=256,
    temperature=0.7,
    stop=["</s>", "\n\n"]
)
print(output["choices"][0]["text"])
```

### 對話補全 (Chat completion)

```python
from llama_cpp import Llama

llm = Llama(
    model_path="./model-q4_k_m.gguf",
    n_ctx=4096,
    n_gpu_layers=35,
    chat_format="llama-3"  # 或使用 "chatml", "mistral" 等格式
)

messages = [
    {"role": "system", "content": "你是一個樂於助人的助手。"},
    {"role": "user", "content": "什麼是 Python？"}
]

response = llm.create_chat_completion(
    messages=messages,
    max_tokens=256,
    temperature=0.7
)
print(response["choices"][0]["message"]["content"])
```

### 串流輸出 (Streaming)

```python
from llama_cpp import Llama

llm = Llama(model_path="./model-q4_k_m.gguf", n_gpu_layers=35)

# 串流標記 (Tokens)
for chunk in llm(
    "解釋量子運算：",
    max_tokens=256,
    stream=True
):
    print(chunk["choices"][0]["text"], end="", flush=True)
```

## 伺服器模式

### 啟動 OpenAI 相容伺服器

```bash
# 啟動伺服器
./llama-server -m model-q4_k_m.gguf \
    --host 0.0.0.0 \
    --port 8080 \
    -ngl 35 \
    -c 4096

# 或使用 Python 綁定
python -m llama_cpp.server \
    --model model-q4_k_m.gguf \
    --n_gpu_layers 35 \
    --host 0.0.0.0 \
    --port 8080
```

### 使用 OpenAI 用戶端

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="無需金鑰"
)

response = client.chat.completions.create(
    model="local-model",
    messages=[{"role": "user", "content": "你好！"}],
    max_tokens=256
)
print(response.choices[0].message.content)
```

## 硬體優化

### Apple Silicon (Metal)

```bash
# 使用 Metal 編譯
make clean && make GGML_METAL=1

# 使用 Metal 加速執行
./llama-cli -m model.gguf -ngl 99 -p "你好"

# Python 使用 Metal
llm = Llama(
    model_path="model.gguf",
    n_gpu_layers=99,     # 卸載所有層
    n_threads=1          # Metal 會處理並行運算
)
```

### NVIDIA CUDA

```bash
# 使用 CUDA 編譯
make clean && make GGML_CUDA=1

# 使用 CUDA 執行
./llama-cli -m model.gguf -ngl 35 -p "你好"

# 指定 GPU
CUDA_VISIBLE_DEVICES=0 ./llama-cli -m model.gguf -ngl 35
```

### CPU 優化

```bash
# 使用 AVX2/AVX512 編譯
make clean && make

# 使用最佳執行緒數執行
./llama-cli -m model.gguf -t 8 -p "你好"

# Python CPU 配置
llm = Llama(
    model_path="model.gguf",
    n_gpu_layers=0,      # 僅 CPU
    n_threads=8,         # 與實體核心數相符
    n_batch=512          # 提示處理的批次大小
)
```

## 工具整合

### Ollama

```bash
# 建立 Modelfile
cat > Modelfile << 'EOF'
FROM ./model-q4_k_m.gguf
TEMPLATE """{{ .System }}
{{ .Prompt }}"""
PARAMETER temperature 0.7
PARAMETER num_ctx 4096
EOF

# 建立 Ollama 模型
ollama create mymodel -f Modelfile

# 執行
ollama run mymodel "你好！"
```

### LM Studio

1. 將 GGUF 檔案放置於 `~/.cache/lm-studio/models/`
2. 開啟 LM Studio 並選擇該模型
3. 配置上下文長度與 GPU 卸載層數
4. 開始推論

### text-generation-webui

```bash
# 放置於 models 資料夾
cp model-q4_k_m.gguf text-generation-webui/models/

# 使用 llama.cpp 加載器啟動
python server.py --model model-q4_k_m.gguf --loader llama.cpp --n-gpu-layers 35
```

## 最佳實踐

1. **使用 K-quants**：Q4_K_M 提供最佳的品質與大小平衡。
2. **使用 imatrix**：對於 Q4 及其以下等級，請務必使用重要性矩陣。
3. **GPU 卸載**：盡可能將更多層卸載到 VRAM 中。
4. **上下文長度**：從 4096 開始，視需要增加。
5. **執行緒計數**：應與實體 CPU 核心數相符，而非邏輯核心數。
6. **批次大小**：增加 n_batch 可加快提示處理速度。

## 常見問題

**模型加載緩慢：**
```bash
# 使用 mmap 進行快速加載
./llama-cli -m model.gguf --mmap
```

**記憶體不足 (OOM)：**
```bash
# 減少 GPU 卸載層數
./llama-cli -m model.gguf -ngl 20  # 從 35 減少

# 或使用較低位元的量化
./llama-quantize model-f16.gguf model-q3_k_m.gguf Q3_K_M
```

**低位元量化品質不佳：**
```bash
# 對於 Q4 及其以下等級，請務必使用 imatrix
./llama-imatrix -m model-f16.gguf -f calibration.txt -o model.imatrix
./llama-quantize --imatrix model.imatrix model-f16.gguf model-q4_k_m.gguf Q4_K_M
```

## 參考資料

- **[進階用法](references/advanced-usage_zh_TW.md)** - 批次處理、投機解碼 (Speculative decoding)、自定義編譯
- **[故障排除](references/troubleshooting.md)** - 常見問題、除錯、基準測試

## 資源

- **儲存庫**：https://github.com/ggml-org/llama.cpp
- **Python 綁定**：https://github.com/abetlen/llama-cpp-python
- **預量化模型**：https://huggingface.co/TheBloke
- **GGUF 轉換器**：https://huggingface.co/spaces/ggml-org/gguf-my-repo
- **授權協議**：MIT
