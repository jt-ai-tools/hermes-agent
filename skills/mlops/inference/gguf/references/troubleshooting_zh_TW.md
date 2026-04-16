# GGUF 疑難排解指南

## 安裝問題

### 建置失敗

**錯誤**：`make: *** No targets specified and no makefile found`

**修復**：
```bash
# 確保您位於 llama.cpp 目錄中
cd llama.cpp
make
```

**錯誤**：`fatal error: cuda_runtime.h: No such file or directory`

**修復**：
```bash
# 安裝 CUDA 工具包
# Ubuntu
sudo apt install nvidia-cuda-toolkit

# 或設定 CUDA 路徑
export CUDA_PATH=/usr/local/cuda
export PATH=$CUDA_PATH/bin:$PATH
make GGML_CUDA=1
```

### Python 綁定問題

**錯誤**：`ERROR: Failed building wheel for llama-cpp-python`

**修復**：
```bash
# 安裝建置依賴項
pip install cmake scikit-build-core

# 啟用 CUDA 支援
CMAKE_ARGS="-DGGML_CUDA=on" pip install llama-cpp-python --force-reinstall --no-cache-dir

# 針對 Metal (macOS)
CMAKE_ARGS="-DGGML_METAL=on" pip install llama-cpp-python --force-reinstall --no-cache-dir
```

**錯誤**：`ImportError: libcudart.so.XX: cannot open shared object file`

**修復**：
```bash
# 將 CUDA 函式庫新增至路徑
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# 或重新安裝正確的 CUDA 版本
pip uninstall llama-cpp-python
CUDACXX=/usr/local/cuda/bin/nvcc CMAKE_ARGS="-DGGML_CUDA=on" pip install llama-cpp-python
```

## 轉換問題

### 模型不受支援

**錯誤**：`KeyError: 'model.embed_tokens.weight'`

**修復**：
```bash
# 檢查模型架構
python -c "from transformers import AutoConfig; print(AutoConfig.from_pretrained('./model').architectures)"

# 使用合適的轉換腳本
# 對於大多數模型：
python convert_hf_to_gguf.py ./model --outfile model.gguf

# 對於舊型模型，檢查是否需要遺留腳本 (legacy script)
```

### 詞彙表不匹配

**錯誤**：`RuntimeError: Vocabulary size mismatch`

**修復**：
```python
# 確保分詞器與模型相符
from transformers import AutoTokenizer, AutoModelForCausalLM

tokenizer = AutoTokenizer.from_pretrained("./model")
model = AutoModelForCausalLM.from_pretrained("./model")

print(f"Tokenizer vocab size: {len(tokenizer)}")
print(f"Model vocab size: {model.config.vocab_size}")

# 如果不匹配，在轉換前調整嵌入大小
model.resize_token_embeddings(len(tokenizer))
model.save_pretrained("./model-fixed")
```

### 轉換時記憶體不足

**錯誤**：轉換期間出現 `torch.cuda.OutOfMemoryError`

**修復**：
```bash
# 使用 CPU 進行轉換
CUDA_VISIBLE_DEVICES="" python convert_hf_to_gguf.py ./model --outfile model.gguf

# 或使用低記憶體模式
python convert_hf_to_gguf.py ./model --outfile model.gguf --outtype f16
```

## 量化問題

### 輸出檔案大小錯誤

**問題**：量化後的檔案大於預期

**檢查**：
```bash
# 驗證量化類型
./llama-cli -m model.gguf --verbose

# 7B 模型的預期大小：
# Q4_K_M: ~4.1 GB
# Q5_K_M: ~4.8 GB
# Q8_0: ~7.2 GB
# F16: ~13.5 GB
```

### 量化當機

**錯誤**：量化期間出現 `Segmentation fault`

**修復**：
```bash
# 增加堆疊大小
ulimit -s unlimited

# 或使用較少的執行緒
./llama-quantize -t 4 model-f16.gguf model-q4.gguf Q4_K_M
```

### 量化後品質低劣

**問題**：模型在量化後輸出亂碼

**解決方案**：

1. **使用重要性矩陣 (Importance Matrix)**：
```bash
# 使用良好的校準數據生成 imatrix
./llama-imatrix -m model-f16.gguf \
    -f wiki_sample.txt \
    --chunk 512 \
    -o model.imatrix

# 使用 imatrix 進行量化
./llama-quantize --imatrix model.imatrix \
    model-f16.gguf model-q4_k_m.gguf Q4_K_M
```

2. **嘗試更高的精度**：
```bash
# 使用 Q5_K_M 或 Q6_K 代替 Q4
./llama-quantize model-f16.gguf model-q5_k_m.gguf Q5_K_M
```

3. **檢查原始模型**：
```bash
# 先測試 FP16 版本
./llama-cli -m model-f16.gguf -p "Hello, how are you?" -n 50
```

## 推論問題

### 生成速度慢

**問題**：生成速度慢於預期

**解決方案**：

1. **啟用 GPU 卸載 (GPU offload)**：
```bash
./llama-cli -m model.gguf -ngl 35 -p "Hello"
```

2. **優化批次大小 (Batch size)**：
```python
llm = Llama(
    model_path="model_path",
    n_batch=512,        # 增加以加快 Prompt 處理速度
    n_gpu_layers=35
)
```

3. **使用合適的執行緒數**：
```bash
# 與實體核心相匹配，而非邏輯核心
./llama-cli -m model.gguf -t 8 -p "Hello"
```

4. **啟用 Flash Attention** (如果支援)：
```bash
./llama-cli -m model.gguf -ngl 35 --flash-attn -p "Hello"
```

### 記憶體不足 (OOM)

**錯誤**：`CUDA out of memory` 或系統凍結

**解決方案**：

1. **減少 GPU 層數**：
```python
# 從低數值開始逐步增加
llm = Llama(model_path="model.gguf", n_gpu_layers=10)
```

2. **使用更小的量化位元**：
```bash
./llama-quantize model-f16.gguf model-q3_k_m.gguf Q3_K_M
```

3. **縮減上下文長度**：
```python
llm = Llama(
    model_path="model.gguf",
    n_ctx=2048,  # 從 4096 縮減
    n_gpu_layers=35
)
```

4. **量化 KV 快取 (KV cache)**：
```python
llm = Llama(
    model_path="model.gguf",
    type_k=2,    # K 快取使用 Q4_0
    type_v=2,    # V 快取使用 Q4_0
    n_gpu_layers=35
)
```

### 輸出垃圾內容

**問題**：模型輸出隨機字元或無意義內容

**診斷**：
```python
# 檢查模型載入情況
llm = Llama(model_path="model.gguf", verbose=True)

# 使用簡單的 Prompt 測試
output = llm("1+1=", max_tokens=5, temperature=0)
print(output)
```

**解決方案**：

1. **檢查模型完整性**：
```bash
# 驗證 GGUF 檔案
./llama-cli -m model.gguf --verbose 2>&1 | head -50
```

2. **使用正確的聊天格式**：
```python
llm = Llama(
    model_path="model.gguf",
    chat_format="llama-3"  # 與您的模型匹配：chatml, mistral 等。
)
```

3. **檢查溫度 (Temperature)**：
```python
# 使用較低的溫度以獲得確定性的輸出
output = llm("Hello", max_tokens=50, temperature=0.1)
```

### Token 問題

**錯誤**：`RuntimeError: unknown token` 或編碼錯誤

**修復**：
```python
# 確保使用 UTF-8 編碼
prompt = "Hello, world!".encode('utf-8').decode('utf-8')
output = llm(prompt, max_tokens=50)
```

## 伺服器問題

### 連線被拒絕

**錯誤**：存取伺服器時出現 `Connection refused`

**修復**：
```bash
# 綁定到所有介面
./llama-server -m model.gguf --host 0.0.0.0 --port 8080

# 檢查連接埠是否被佔用
lsof -i :8080
```

### 伺服器在高負載下當機

**問題**：伺服器在處理多個並發請求時當機

**解決方案**：

1. **限制並行性**：
```bash
./llama-server -m model.gguf \
    --parallel 2 \
    -c 4096 \
    --cont-batching
```

2. **增加請求逾時**：
```bash
./llama-server -m model.gguf --timeout 300
```

3. **監控記憶體**：
```bash
watch -n 1 nvidia-smi  # 針對 GPU
watch -n 1 free -h     # 針對 RAM
```

### API 相容性問題

**問題**：OpenAI 用戶端無法與伺服器配合使用

**修復**：
```python
from openai import OpenAI

# 使用正確的 Base URL 格式
client = OpenAI(
    base_url="http://localhost:8080/v1",  # 包含 /v1
    api_key="not-needed"
)

# 使用正確的模型名稱
response = client.chat.completions.create(
    model="local",  # 或實際的模型名稱
    messages=[{"role": "user", "content": "Hello"}]
)
```

## Apple Silicon 問題

### Metal 無法運作

**問題**：未啟用 Metal 加速

**檢查**：
```bash
# 驗證 Metal 支援
./llama-cli -m model.gguf --verbose 2>&1 | grep -i metal
```

**修復**：
```bash
# 使用 Metal 重新建置
make clean
make GGML_METAL=1

# Python 綁定
CMAKE_ARGS="-DGGML_METAL=on" pip install llama-cpp-python --force-reinstall
```

### M1/M2 上的記憶體使用量不正確

**問題**：模型使用了過多的統一記憶體 (Unified Memory)

**修復**：
```python
# 為 Metal 卸載所有層
llm = Llama(
    model_path="model.gguf",
    n_gpu_layers=99,    # 卸載所有內容
    n_threads=1         # Metal 會處理並行化
)
```

## 偵錯

### 啟用詳細輸出

```bash
# CLI 詳細模式
./llama-cli -m model.gguf --verbose -p "Hello" -n 50

# Python 詳細模式
llm = Llama(model_path="model.gguf", verbose=True)
```

### 檢查模型元數據 (Metadata)

```bash
# 查看 GGUF 元數據
./llama-cli -m model.gguf --verbose 2>&1 | head -100
```

### 驗證 GGUF 檔案

```python
import struct

def validate_gguf(filepath):
    with open(filepath, 'rb') as f:
        magic = f.read(4)
        if magic != b'GGUF':
            print(f"無效的 magic: {magic}")
            return False

        version = struct.unpack('<I', f.read(4))[0]
        print(f"GGUF 版本: {version}")

        tensor_count = struct.unpack('<Q', f.read(8))[0]
        metadata_count = struct.unpack('<Q', f.read(8))[0]
        print(f"張量數: {tensor_count}, 元數據數: {metadata_count}")

        return True

validate_gguf("model.gguf")
```

## 取得幫助

1. **GitHub Issues**: https://github.com/ggml-org/llama.cpp/issues
2. **Discussions**: https://github.com/ggml-org/llama.cpp/discussions
3. **Reddit**: r/LocalLLaMA

### 回報問題

請包含：
- llama.cpp 版本/提交雜湊 (commit hash)
- 使用的建置指令
- 模型名稱和量化方式
- 完整的錯誤訊息/堆疊追蹤 (stack trace)
- 硬體：CPU/GPU 型號, RAM, VRAM
- 作業系統版本
- 最小重現步驟
