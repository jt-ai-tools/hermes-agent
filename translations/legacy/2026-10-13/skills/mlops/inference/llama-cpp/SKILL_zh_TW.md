---
name: llama-cpp
description: 在 CPU、Apple Silicon 和消費級 GPU（無需 NVIDIA 硬體）上執行 LLM 推論。適用於邊緣部署、M1/M2/M3 Mac、AMD/Intel GPU 或無法使用 CUDA 的情況。支援 GGUF 量化（1.5-8 bit），可減少記憶體佔用，且在 CPU 上的速度比 PyTorch 快 4-10 倍。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [llama-cpp-python]
metadata:
  hermes:
    tags: [推論服務, Llama.cpp, CPU 推論, Apple Silicon, 邊緣部署, GGUF, 量化, 非 NVIDIA, AMD GPU, Intel GPU, 嵌入式]

---

# llama.cpp

純 C/C++ 的 LLM 推論，依賴極少，針對 CPU 和非 NVIDIA 硬體進行了優化。

## 何時使用 llama.cpp

**在以下情況下使用 llama.cpp：**
- 在僅有 CPU 的機器上執行
- 部署在 Apple Silicon (M1/M2/M3/M4) 上
- 使用 AMD 或 Intel GPU (無 CUDA)
- 邊緣部署 (Raspberry Pi, 嵌入式系統)
- 需要簡單的部署，無需 Docker/Python

**在以下情況下改用 TensorRT-LLM：**
- 擁有 NVIDIA GPU (A100/H100)
- 需要最大吞吐量 (100K+ tok/s)
- 在具備 CUDA 的資料中心執行

**在以下情況下改用 vLLM：**
- 擁有 NVIDIA GPU
- 需要 Python 優先的 API
- 想要 PagedAttention

## 快速入門

### 安裝

```bash
# macOS/Linux
brew install llama.cpp

# 或從源碼編譯
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
make

# 使用 Metal (Apple Silicon)
make LLAMA_METAL=1

# 使用 CUDA (NVIDIA)
make LLAMA_CUDA=1

# 使用 ROCm (AMD)
make LLAMA_HIP=1
```

### 下載模型

```bash
# 從 HuggingFace 下載 (GGUF 格式)
huggingface-cli download \
    TheBloke/Llama-2-7B-Chat-GGUF \
    llama-2-7b-chat.Q4_K_M.gguf \
    --local-dir models/

# 或從 HuggingFace 轉換
python convert_hf_to_gguf.py models/llama-2-7b-chat/
```

### 執行推論

```bash
# 簡單對話
./llama-cli \
    -m models/llama-2-7b-chat.Q4_K_M.gguf \
    -p "解釋量子運算" \
    -n 256  # 最大標記數 (Max tokens)

# 互動式對話
./llama-cli \
    -m models/llama-2-7b-chat.Q4_K_M.gguf \
    --interactive
```

### 伺服器模式

```bash
# 啟動與 OpenAI 相容的伺服器
./llama-server \
    -m models/llama-2-7b-chat.Q4_K_M.gguf \
    --host 0.0.0.0 \
    --port 8080 \
    -ngl 32  # 將 32 層卸載到 GPU
```

### 用戶端請求

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-2-7b-chat",
    "messages": [{"role": "user", "content": "你好！"}],
    "temperature": 0.7,
    "max_tokens": 100
  }'
```

## 量化格式

### GGUF 格式概覽

| 格式 | 位元 (Bits) | 大小 (7B) | 速度 | 品質 | 使用場景 |
|--------|------|-----------|-------|---------|----------|
| **Q4_K_M** | 4.5 | 4.1 GB | 快 | 良好 | **推薦預設值** |
| Q4_K_S | 4.3 | 3.9 GB | 更快 | 較低 | 速度至上 |
| Q5_K_M | 5.5 | 4.8 GB | 中等 | 更好 | 品質至上 |
| Q6_K | 6.5 | 5.5 GB | 較慢 | 最佳 | 最高品質 |
| Q8_0 | 8.0 | 7.0 GB | 慢 | 極佳 | 極小損耗 |
| Q2_K | 2.5 | 2.7 GB | 最快 | 差 | 僅供測試 |

### 選擇量化方式

```bash
# 一般用途 (平衡)
Q4_K_M  # 4-bit, 中等品質

# 最大速度 (損耗較多)
Q2_K 或 Q3_K_M

# 最高品質 (較慢)
Q6_K 或 Q8_0

# 超大型模型 (70B, 405B)
Q3_K_M 或 Q4_K_S  # 使用較低位元以符合記憶體限制
```

## 硬體加速

### Apple Silicon (Metal)

```bash
# 使用 Metal 編譯
make LLAMA_METAL=1

# 使用 GPU 加速執行 (自動)
./llama-cli -m model.gguf -ngl 999  # 卸載所有層

# 效能：M3 Max 40-60 tokens/sec (Llama 2-7B Q4_K_M)
```

### NVIDIA GPU (CUDA)

```bash
# 使用 CUDA 編譯
make LLAMA_CUDA=1

# 將層卸載到 GPU
./llama-cli -m model.gguf -ngl 35  # 卸載 35/40 層

# 大型模型的 CPU+GPU 混合模式
./llama-cli -m llama-70b.Q4_K_M.gguf -ngl 20  # GPU：20 層，CPU：其餘
```

### AMD GPU (ROCm)

```bash
# 使用 ROCm 編譯
make LLAMA_HIP=1

# 使用 AMD GPU 執行
./llama-cli -m model.gguf -ngl 999
```

## 常見模式

### 批次處理

```bash
# 處理來自檔案的多個提示
cat prompts.txt | ./llama-cli \
    -m model.gguf \
    --batch-size 512 \
    -n 100
```

### 受限生成 (Constrained generation)

```bash
# 使用文法生成 JSON 輸出
./llama-cli \
    -m model.gguf \
    -p "產生一個人物資料： " \
    --grammar-file grammars/json.gbnf

# 僅輸出有效的 JSON
```

### 上下文大小 (Context size)

```bash
# 增加上下文 (預設為 512)
./llama-cli \
    -m model.gguf \
    -c 4096  # 4K 上下文視窗

# 超長上下文 (如果模型支援)
./llama-cli -m model.gguf -c 32768  # 32K 上下文
```

## 效能基準測試

### CPU 效能 (Llama 2-7B Q4_K_M)

| CPU | 執行緒 (Threads) | 速度 | 成本 |
|-----|---------|-------|------|
| Apple M3 Max | 16 | 50 tok/s | $0 (本地) |
| AMD Ryzen 9 7950X | 32 | 35 tok/s | $0.50/小時 |
| Intel i9-13900K | 32 | 30 tok/s | $0.40/小時 |
| AWS c7i.16xlarge | 64 | 40 tok/s | $2.88/小時 |

### GPU 加速 (Llama 2-7B Q4_K_M)

| GPU | 速度 | vs CPU | 成本 |
|-----|-------|--------|------|
| NVIDIA RTX 4090 | 120 tok/s | 3-4× | $0 (本地) |
| NVIDIA A10 | 80 tok/s | 2-3× | $1.00/小時 |
| AMD MI250 | 70 tok/s | 2× | $2.00/小時 |
| Apple M3 Max (Metal) | 50 tok/s | ~相同 | $0 (本地) |

## 支援的模型

**LLaMA 系列**:
- Llama 2 (7B, 13B, 70B)
- Llama 3 (8B, 70B, 405B)
- Code Llama

**Mistral 系列**:
- Mistral 7B
- Mixtral 8x7B, 8x22B

**其他**:
- Falcon, BLOOM, GPT-J
- Phi-3, Gemma, Qwen
- LLaVA (視覺), Whisper (音訊)

**尋找模型**: https://huggingface.co/models?library=gguf

## 參考資料

- **[量化指南](references/quantization_zh_TW.md)** - GGUF 格式、轉換、品質比較
- **[伺服器部署](references/server_zh_TW.md)** - API 端點、Docker、監控
- **[優化](references/optimization_zh_TW.md)** - 效能調優、CPU+GPU 混合模式

## 資源

- **GitHub**: https://github.com/ggerganov/llama.cpp
- **模型**: https://huggingface.co/models?library=gguf
- **Discord**: https://discord.gg/llama-cpp
