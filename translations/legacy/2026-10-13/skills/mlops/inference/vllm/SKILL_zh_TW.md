---
name: serving-llms-vllm
description: 使用 vLLM 的 PagedAttention 和連續批次處理 (Continuous batching) 技術，提供高吞吐量的 LLMs 服務。適用於部署生產環境的 LLM APIs、最佳化推論延遲與吞吐量，或在 GPU 記憶體受限的情況下提供模型服務。支援 OpenAI 相容的端點 (Endpoints)、量化 (GPTQ/AWQ/FP8) 以及張量並行 (Tensor parallelism)。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [vllm, torch, transformers]
metadata:
  hermes:
    tags: [vLLM, Inference Serving, PagedAttention, Continuous Batching, High Throughput, Production, OpenAI API, Quantization, Tensor Parallelism]

---

# vLLM - 高效能 LLM 服務 (Serving)

## 快速入門 (Quick start)

vLLM 透過 PagedAttention (基於區塊的 KV 快取) 和連續批次處理 (Continuous batching，混合 prefill/decode 請求)，實現比標準 Transformers 高出 24 倍的吞吐量。

**安裝**:
```bash
pip install vllm
```

**基礎離線推論**:
```python
from vllm import LLM, SamplingParams

llm = LLM(model="meta-llama/Llama-3-8B-Instruct")
sampling = SamplingParams(temperature=0.7, max_tokens=256)

outputs = llm.generate(["Explain quantum computing"], sampling)
print(outputs[0].outputs[0].text)
```

**OpenAI 相容伺服器**:
```bash
vllm serve meta-llama/Llama-3-8B-Instruct

# 使用 OpenAI SDK 查詢
python -c "
from openai import OpenAI
client = OpenAI(base_url='http://localhost:8000/v1', api_key='EMPTY')
print(client.chat.completions.create(
    model='meta-llama/Llama-3-8B-Instruct',
    messages=[{'role': 'user', 'content': 'Hello!'}]
).choices[0].message.content)
"
```

## 常見工作流 (Common workflows)

### 工作流 1：生產環境 API 部署

複製此檢核表並追蹤進度：

```
部署進度：
- [ ] 步驟 1：配置伺服器設定
- [ ] 步驟 2：使用限流測試
- [ ] 步驟 3：啟用監控
- [ ] 步驟 4：部署到生產環境
- [ ] 步驟 5：驗證效能指標 (Metrics)
```

**步驟 1：配置伺服器設定**

根據您的模型大小選擇配置：

```bash
# 針對單一 GPU 上的 7B-13B 模型
vllm serve meta-llama/Llama-3-8B-Instruct \
  --gpu-memory-utilization 0.9 \
  --max-model-len 8192 \
  --port 8000

# 針對具備張量並行 (Tensor parallelism) 的 30B-70B 模型
vllm serve meta-llama/Llama-2-70b-hf \
  --tensor-parallel-size 4 \
  --gpu-memory-utilization 0.9 \
  --quantization awq \
  --port 8000

# 用於具備快取和指標監控的生產環境
vllm serve meta-llama/Llama-3-8B-Instruct \
  --gpu-memory-utilization 0.9 \
  --enable-prefix-caching \
  --enable-metrics \
  --metrics-port 9090 \
  --port 8000 \
  --host 0.0.0.0
```

**步驟 2：使用限流測試**

在進入生產環境前執行壓力測試：

```bash
# 安裝壓力測試工具
pip install locust

# 建立包含範例請求的 test_load.py
# 執行：locust -f test_load.py --host http://localhost:8000
```

驗證 TTFT (Time to first token) < 500ms 且吞吐量 > 100 req/sec。

**步驟 3：啟用監控**

vLLM 在 9090 連接埠公開 Prometheus 指標：

```bash
curl http://localhost:9090/metrics | grep vllm
```

關鍵監控指標：
- `vllm:time_to_first_token_seconds` - 延遲 (Latency)
- `vllm:num_requests_running` - 執行中的請求數
- `vllm:gpu_cache_usage_perc` - KV 快取使用率

**步驟 4：部署到生產環境**

使用 Docker 進行一致性部署：

```bash
# 在 Docker 中執行 vLLM
docker run --gpus all -p 8000:8000 \
  vllm/vllm-openai:latest \
  --model meta-llama/Llama-3-8B-Instruct \
  --gpu-memory-utilization 0.9 \
  --enable-prefix-caching
```

**步驟 5：驗證效能指標**

檢查部署是否達到目標：
- TTFT < 500ms (針對短提示詞)
- 吞吐量 > 目標 req/sec
- GPU 使用率 > 80%
- 日誌中無 OOM 錯誤

### 工作流 2：離線批次推論 (Offline batch inference)

用於在沒有伺服器開銷的情況下處理大型資料集。

複製此檢核表：

```
批次處理：
- [ ] 步驟 1：準備輸入資料
- [ ] 步驟 2：配置 LLM 引擎
- [ ] 步驟 3：執行批次推論
- [ ] 步驟 4：處理結果
```

**步驟 1：準備輸入資料**

```python
# 從檔案載入提示詞
prompts = []
with open("prompts.txt") as f:
    prompts = [line.strip() for line in f]

print(f"Loaded {len(prompts)} prompts")
```

**步驟 2：配置 LLM 引擎**

```python
from vllm import LLM, SamplingParams

llm = LLM(
    model="meta-llama/Llama-3-8B-Instruct",
    tensor_parallel_size=2,  # 使用 2 個 GPU
    gpu_memory_utilization=0.9,
    max_model_len=4096
)

sampling = SamplingParams(
    temperature=0.7,
    top_p=0.95,
    max_tokens=512,
    stop=["</s>", "\n\n"]
)
```

**步驟 3：執行批次推論**

vLLM 會自動批次處理請求以提高效率：

```python
# 在一次呼叫中處理所有提示詞
outputs = llm.generate(prompts, sampling)

# vLLM 在內部處理批次
# 無需手動分塊提示詞
```

**步驟 4：處理結果**

```python
# 提取生成的文字
results = []
for output in outputs:
    prompt = output.prompt
    generated = output.outputs[0].text
    results.append({
        "prompt": prompt,
        "generated": generated,
        "tokens": len(output.outputs[0].token_ids)
    })

# 儲存到檔案
import json
with open("results.jsonl", "w") as f:
    for result in results:
        f.write(json.dumps(result) + "\n")

print(f"Processed {len(results)} prompts")
```

### 工作流 3：量化模型服務 (Quantized model serving)

在有限的 GPU 記憶體中裝載大型模型。

```
量化設定：
- [ ] 步驟 1：選擇量化方法
- [ ] 步驟 2：尋找或建立量化模型
- [ ] 步驟 3：使用量化標記啟動
- [ ] 步驟 4：驗證準確性
```

**步驟 1：選擇量化方法**

- **AWQ**: 最適合 70B 模型，準確性損失極小
- **GPTQ**: 模型支援廣泛，壓縮效果好
- **FP8**: 在 H100 GPU 上速度最快

**步驟 2：尋找或建立量化模型**

使用 HuggingFace 上預先量化的模型：

```bash
# 搜尋 AWQ 模型
# 範例：TheBloke/Llama-2-70B-AWQ
```

**步驟 3：使用量化標記啟動**

```bash
# 使用預先量化的模型
vllm serve TheBloke/Llama-2-70B-AWQ \
  --quantization awq \
  --tensor-parallel-size 1 \
  --gpu-memory-utilization 0.95

# 結果：70B 模型僅需約 40GB VRAM
```

**步驟 4：驗證準確性**

測試輸出是否符合預期品質：

```python
# 比較量化與非量化模型的過後回應
# 驗證特定任務的效能是否保持不變
```

## 何時使用以及替代方案

**在以下情況使用 vLLM：**
- 部署生產環境 LLM APIs (100+ req/sec)
- 提供 OpenAI 相容的端點 (Endpoints)
- GPU 記憶體有限但需要大型模型
- 多使用者應用程式 (聊天機器人、助手)
- 需要低延遲與高吞吐量

**改用替代方案：**
- **llama.cpp**: CPU/邊緣推論、單一使用者
- **HuggingFace transformers**: 研究、原型設計、一次性生成
- **TensorRT-LLM**: 僅限 NVIDIA，需要絕對極致的效能
- **Text-Generation-Inference**: 已在 HuggingFace 生態系統中

## 常見問題 (Common issues)

**問題：模型載入期間發生記憶體不足 (OOM)**

減少記憶體使用量：
```bash
vllm serve MODEL \
  --gpu-memory-utilization 0.7 \
  --max-model-len 4096
```

或使用量化：
```bash
vllm serve MODEL --quantization awq
```

**問題：首字生成緩慢 (TTFT > 1 秒)**

為重複的提示詞啟用前綴快取 (Prefix caching)：
```bash
vllm serve MODEL --enable-prefix-caching
```

針對長提示詞，啟用分塊預填 (Chunked prefill)：
```bash
vllm serve MODEL --enable-chunked-prefill
```

**問題：找不到模型錯誤 (Model not found error)**

針對自定義模型使用 `--trust-remote-code`：
```bash
vllm serve MODEL --trust-remote-code
```

**問題：吞吐量低 (<50 req/sec)**

增加並發序列數：
```bash
vllm serve MODEL --max-num-seqs 512
```

使用 `nvidia-smi` 檢查 GPU 使用率 - 應 >80%。

**問題：推論速度慢於預期**

驗證張量並行 (Tensor parallelism) 使用 2 的冪次個 GPU：
```bash
vllm serve MODEL --tensor-parallel-size 4  # 而非 3
```

啟用投機解碼 (Speculative decoding) 以加快生成速度：
```bash
vllm serve MODEL --speculative-model DRAFT_MODEL
```

## 進階主題 (Advanced topics)

**伺服器部署模式**：參閱 [references/server-deployment_zh_TW.md](references/server-deployment_zh_TW.md) 以瞭解 Docker、Kubernetes 和負載平衡配置。

**效能最佳化**：參閱 [references/optimization_zh_TW.md](references/optimization_zh_TW.md) 以瞭解 PagedAttention 調優、連續批次處理細節和基準測試結果。

**量化指南**：參閱 [references/quantization_zh_TW.md](references/quantization_zh_TW.md) 以瞭解 AWQ/GPTQ/FP8 設定、模型準備和準確性比較。

**疑難排解**：參閱 [references/troubleshooting_zh_TW.md](references/troubleshooting_zh_TW.md) 以瞭解詳細的錯誤訊息、除錯步驟和效能診斷。

## 硬體需求 (Hardware requirements)

- **小型模型 (7B-13B)**: 1x A10 (24GB) 或 A100 (40GB)
- **中型模型 (30B-40B)**: 2x A100 (40GB) 使用張量並行 (Tensor parallelism)
- **大型模型 (70B+)**: 4x A100 (40GB) 或 2x A100 (80GB)，使用 AWQ/GPTQ

支援的平台：NVIDIA (主要)、AMD ROCm、Intel GPU、TPU

## 資源 (Resources)

- 官方文件：https://docs.vllm.ai
- GitHub: https://github.com/vllm-project/vllm
- 論文: "Efficient Memory Management for Large Language Model Serving with PagedAttention" (SOSP 2023)
- 社群: https://discuss.vllm.ai
