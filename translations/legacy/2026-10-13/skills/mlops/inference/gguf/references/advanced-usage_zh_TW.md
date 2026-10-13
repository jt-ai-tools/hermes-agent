# GGUF 進階使用指南

## 投機解碼 (Speculative Decoding)

### 草稿模型 (Draft Model) 方法

```bash
# 使用較小的模型作為草稿模型以加快生成速度
./llama-speculative \
    -m large-model-q4_k_m.gguf \
    -md draft-model-q4_k_m.gguf \
    -p "寫一個關於 AI 的故事" \
    -n 500 \
    --draft 8  # 在驗證前生成的草稿標記 (tokens) 數
```

### 自我投機解碼 (Self-Speculative Decoding)

```bash
# 使用相同模型但使用不同的上下文進行投機
./llama-cli -m model-q4_k_m.gguf \
    --lookup-cache-static lookup.bin \
    --lookup-cache-dynamic lookup-dynamic.bin \
    -p "Hello world"
```

## 批次推論 (Batched Inference)

### 處理多個提示 (Prompts)

```python
from llama_cpp import Llama

llm = Llama(
    model_path="model-q4_k_m.gguf",
    n_ctx=4096,
    n_gpu_layers=35,
    n_batch=512  # 較大的批次大小，用於平行處理
)

prompts = [
    "什麼是 Python？",
    "解釋機器學習。",
    "描述類神經網路。"
]

# 批次處理 (每個提示獲得獨立的上下文)
for prompt in prompts:
    output = llm(prompt, max_tokens=100)
    print(f"問題: {prompt}")
    print(f"回答: {output['choices'][0]['text']}\n")
```

### 伺服器批次處理

```bash
# 啟動具備批次處理功能的伺服器
./llama-server -m model-q4_k_m.gguf \
    --host 0.0.0.0 \
    --port 8080 \
    -ngl 35 \
    -c 4096 \
    --parallel 4        # 同時處理的請求數
    --cont-batching     # 連續批次處理 (Continuous batching)
```

## 自定義模型轉換

### 轉換時修改詞彙表 (Vocabulary)

```python
# custom_convert.py
import sys
sys.path.insert(0, './llama.cpp')

from convert_hf_to_gguf import main
from gguf import GGUFWriter

# 使用修改後的詞彙表進行自定義轉換
def convert_with_custom_vocab(model_path, output_path):
    # 載入並修改 tokenizer
    from transformers import AutoTokenizer
    tokenizer = AutoTokenizer.from_pretrained(model_path)

    # 視需要新增特殊標記 (special tokens)
    special_tokens = {"additional_special_tokens": ["<|custom|>"]}
    tokenizer.add_special_tokens(special_tokens)
    tokenizer.save_pretrained(model_path)

    # 然後執行標準轉換
    main([model_path, "--outfile", output_path])
```

### 轉換特定架構

```bash
# 針對 Mistral 風格模型
python convert_hf_to_gguf.py ./mistral-model \
    --outfile mistral-f16.gguf \
    --outtype f16

# 針對 Qwen 模型
python convert_hf_to_gguf.py ./qwen-model \
    --outfile qwen-f16.gguf \
    --outtype f16

# 針對 Phi 模型
python convert_hf_to_gguf.py ./phi-model \
    --outfile phi-f16.gguf \
    --outtype f16
```

## 進階量化

### 混合量化 (Mixed Quantization)

```bash
# 對不同的層類型進行不同程度的量化
./llama-quantize model-f16.gguf model-mixed.gguf Q4_K_M \
    --allow-requantize \
    --leave-output-tensor
```

### 包含標記嵌入 (Token Embeddings) 的量化

```bash
# 讓嵌入層保持較高精度
./llama-quantize model-f16.gguf model-q4.gguf Q4_K_M \
    --token-embedding-type f16
```

### IQ 量化 (重要性感知量化, Importance-aware)

```bash
# 使用重要性矩陣進行極低位元量化
./llama-quantize --imatrix model.imatrix \
    model-f16.gguf model-iq2_xxs.gguf IQ2_XXS

# 可用的 IQ 類型：IQ2_XXS, IQ2_XS, IQ2_S, IQ3_XXS, IQ3_XS, IQ3_S, IQ4_XS
```

## 記憶體優化

### 記憶體映射 (Memory Mapping)

```python
from llama_cpp import Llama

# 針對大型模型使用記憶體映射
llm = Llama(
    model_path="model-q4_k_m.gguf",
    use_mmap=True,       # 對模型進行記憶體映射
    use_mlock=False,     # 不要鎖定在 RAM 中
    n_gpu_layers=35
)
```

### 部分 GPU 卸載 (Offload)

```python
# 根據 VRAM 計算可卸載的層數
import subprocess

def get_free_vram_gb():
    result = subprocess.run(
        ['nvidia-smi', '--query-gpu=memory.free', '--format=csv,nounits,noheader'],
        capture_output=True, text=True
    )
    return int(result.stdout.strip()) / 1024

# 根據 VRAM 估算層數 (粗估：7B Q4 模型每層約 0.5GB)
free_vram = get_free_vram_gb()
layers_to_offload = int(free_vram / 0.5)

llm = Llama(
    model_path="model-q4_k_m.gguf",
    n_gpu_layers=min(layers_to_offload, 35)  # 上限為總層數
)
```

### KV 快取 (KV Cache) 優化

```python
from llama_cpp import Llama

# 針對長上下文優化 KV 快取
llm = Llama(
    model_path="model-q4_k_m.gguf",
    n_ctx=8192,          # 大上下文
    n_gpu_layers=35,
    type_k=1,            # K 快取使用 Q8_0 (1)
    type_v=1,            # V 快取使用 Q8_0 (1)
    # 或使用 Q4_0 (2) 以獲得更高壓縮率
)
```

## 上下文管理 (Context Management)

### 上下文偏移 (Context Shifting)

```python
from llama_cpp import Llama

llm = Llama(
    model_path="model-q4_k_m.gguf",
    n_ctx=4096,
    n_gpu_layers=35
)

# 透過上下文偏移處理長對話
conversation = []
max_history = 10

def chat(user_message):
    conversation.append({"role": "user", "content": user_message})

    # 僅保留最近的歷史記錄
    if len(conversation) > max_history * 2:
        conversation = conversation[-max_history * 2:]

    response = llm.create_chat_completion(
        messages=conversation,
        max_tokens=256
    )

    assistant_message = response["choices"][0]["message"]["content"]
    conversation.append({"role": "assistant", "content": assistant_message})
    return assistant_message
```

### 儲存與載入狀態 (State)

```bash
# 將狀態儲存到檔案
./llama-cli -m model.gguf \
    -p "從前從前" \
    --save-session session.bin \
    -n 100

# 載入並繼續執行
./llama-cli -m model.gguf \
    --load-session session.bin \
    -p " 然後他們過著" \
    -n 100
```

## 文法受限生成 (Grammar Constrained Generation)

### JSON 輸出

```python
from llama_cpp import Llama, LlamaGrammar

# 定義 JSON 文法
json_grammar = LlamaGrammar.from_string('''
root ::= object
object ::= "{" ws pair ("," ws pair)* "}" ws
pair ::= string ":" ws value
value ::= string | number | object | array | "true" | "false" | "null"
array ::= "[" ws value ("," ws value)* "]" ws
string ::= "\\"" [^"\\\\]* "\\""
number ::= [0-9]+
ws ::= [ \\t\\n]*
''')

llm = Llama(model_path="model-q4_k_m.gguf", n_gpu_layers=35)

output = llm(
    "輸出一個包含名稱和年齡的 JSON 物件：",
    grammar=json_grammar,
    max_tokens=100
)
print(output["choices"][0]["text"])
```

### 自定義文法

```python
# 針對特定格式的文法
answer_grammar = LlamaGrammar.from_string('''
root ::= "回答: " letter "\\n" "解釋: " explanation
letter ::= [A-D]
explanation ::= [a-zA-Z0-9 .,!?]+
''')

output = llm(
    "問題: 2+2 是多少？ A) 3 B) 4 C) 5 D) 6",
    grammar=answer_grammar,
    max_tokens=100
)
```

## LoRA 整合

### 載入 LoRA 適配器 (Adapter)

```bash
# 在執行時套用 LoRA
./llama-cli -m base-model-q4_k_m.gguf \
    --lora lora-adapter.gguf \
    --lora-scale 1.0 \
    -p "你好！"
```

### 多個 LoRA 適配器

```bash
# 堆疊多個適配器
./llama-cli -m base-model.gguf \
    --lora adapter1.gguf --lora-scale 0.5 \
    --lora adapter2.gguf --lora-scale 0.5 \
    -p "你好！"
```

### Python 使用 LoRA

```python
from llama_cpp import Llama

llm = Llama(
    model_path="base-model-q4_k_m.gguf",
    lora_path="lora-adapter.gguf",
    lora_scale=1.0,
    n_gpu_layers=35
)
```

## 嵌入層 (Embedding) 生成

### 提取嵌入向量

```python
from llama_cpp import Llama

llm = Llama(
    model_path="model-q4_k_m.gguf",
    embedding=True,      # 啟用嵌入模式
    n_gpu_layers=35
)

# 取得嵌入向量
embeddings = llm.embed("這是一個測試句子。")
print(f"嵌入向量維度: {len(embeddings)}")
```

### 批次嵌入 (Batch Embeddings)

```python
texts = [
    "機器學習非常迷人。",
    "深度學習使用類神經網路。",
    "Python 是一種程式語言。"
]

embeddings = [llm.embed(text) for text in texts]

# 計算相似度
import numpy as np

def cosine_similarity(a, b):
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

sim = cosine_similarity(embeddings[0], embeddings[1])
print(f"相似度: {sim:.4f}")
```

## 效能調優 (Performance Tuning)

### 基準測試 (Benchmark) 腳本

```python
import time
from llama_cpp import Llama

def benchmark(model_path, prompt, n_tokens=100, n_runs=5):
    llm = Llama(
        model_path=model_path,
        n_gpu_layers=35,
        n_ctx=2048,
        verbose=False
    )

    # 預熱 (Warmup)
    llm(prompt, max_tokens=10)

    # 基準測試
    times = []
    for _ in range(n_runs):
        start = time.time()
        output = llm(prompt, max_tokens=n_tokens)
        elapsed = time.time() - start
        times.append(elapsed)

    avg_time = sum(times) / len(times)
    tokens_per_sec = n_tokens / avg_time

    print(f"模型: {model_path}")
    print(f"平均時間: {avg_time:.2f}s")
    print(f"每秒標記數 (Tokens/sec): {tokens_per_sec:.1f}")

    return tokens_per_sec

# 比較不同量化格式
for quant in ["q4_k_m", "q5_k_m", "q8_0"]:
    benchmark(f"model-{quant}.gguf", "解釋量子運算：", 100)
```

### 最佳配置尋找工具

```python
def find_optimal_config(model_path, target_vram_gb=8):
    """尋找目標 VRAM 下最佳的 n_gpu_layers 與 n_batch 設定。"""
    from llama_cpp import Llama
    import gc

    best_config = None
    best_speed = 0

    for n_gpu_layers in range(0, 50, 5):
        for n_batch in [128, 256, 512, 1024]:
            try:
                gc.collect()
                llm = Llama(
                    model_path=model_path,
                    n_gpu_layers=n_gpu_layers,
                    n_batch=n_batch,
                    n_ctx=2048,
                    verbose=False
                )

                # 快速基準測試
                start = time.time()
                llm("Hello", max_tokens=50)
                speed = 50 / (time.time() - start)

                if speed > best_speed:
                    best_speed = speed
                    best_config = {
                        "n_gpu_layers": n_gpu_layers,
                        "n_batch": n_batch,
                        "speed": speed
                    }

                del llm
                gc.collect()

            except Exception as e:
                print(f"在層數={n_gpu_layers}, 批次大小={n_batch} 時發生 OOM")
                break

    return best_config
```

## 多 GPU 設置

### 跨 GPU 分配

```bash
# 將模型拆分到多個 GPU 上
./llama-cli -m large-model.gguf \
    --tensor-split 0.5,0.5 \
    -ngl 60 \
    -p "你好！"
```

### Python 多 GPU 用法

```python
import os
os.environ["CUDA_VISIBLE_DEVICES"] = "0,1"

from llama_cpp import Llama

llm = Llama(
    model_path="large-model-q4_k_m.gguf",
    n_gpu_layers=60,
    tensor_split=[0.5, 0.5]  # 平均分配到 2 個 GPU 上
)
```

## 自定義編譯 (Custom Builds)

### 帶有完整優化的編譯

```bash
# 清除舊編譯並帶入所有 CPU 優化
make clean
LLAMA_OPENBLAS=1 LLAMA_BLAS_VENDOR=OpenBLAS make -j

# 使用 CUDA 與 cuBLAS
make clean
GGML_CUDA=1 LLAMA_CUBLAS=1 make -j

# 使用特定 CUDA 架構
GGML_CUDA=1 CUDA_DOCKER_ARCH=sm_86 make -j
```

### CMake 編譯

```bash
mkdir build && cd build
cmake .. -DGGML_CUDA=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release -j
```
