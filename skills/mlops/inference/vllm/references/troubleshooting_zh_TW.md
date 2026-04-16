# 疑難排解指南 (Troubleshooting Guide)

## 目錄
- 記憶體不足 (OOM) 錯誤
- 效能問題
- 模型載入錯誤
- 網路與連線問題
- 量化相關問題
- 分散式服務問題
- 除錯工具與指令

## 記憶體不足 (OOM) 錯誤

### 徵狀：在模型載入期間出現 `torch.cuda.OutOfMemoryError`

**原因**：模型 + KV 快取超過了可用的 VRAM

**解決方案 (依序嘗試)**：

1. **降低 GPU 記憶體使用率 (GPU memory utilization)**：
```bash
vllm serve MODEL --gpu-memory-utilization 0.7  # 嘗試 0.7, 0.75, 0.8
```

2. **減少最大序列長度**：
```bash
vllm serve MODEL --max-model-len 4096  # 而非 8192
```

3. **啟用量化 (Quantization)**：
```bash
vllm serve MODEL --quantization awq  # 記憶體佔用減少 4 倍
```

4. **使用張量並行 (Tensor parallelism)** (多個 GPU)：
```bash
vllm serve MODEL --tensor-parallel-size 2  # 分散到 2 個 GPU
```

5. **減少最大並發序列數**：
```bash
vllm serve MODEL --max-num-seqs 128  # 預設為 256
```

### 徵狀：在推論期間 (而非載入期間) 出現 OOM

**原因**：KV 快取在生成過程中填滿

**解決方案**：

```bash
# 減少 KV 快取分配
vllm serve MODEL --gpu-memory-utilization 0.85

# 減少批次大小 (Batch size)
vllm serve MODEL --max-num-seqs 64

# 減少每個請求的最大 tokens 數
# 在用戶端請求中設定：max_tokens=512
```

### 徵狀：使用量化模型時出現 OOM

**原因**：量化額外開銷或配置錯誤

**解決方案**：
```bash
# 確保量化標記與模型相符
vllm serve TheBloke/Llama-2-70B-AWQ --quantization awq  # 必須指定

# 嘗試不同的資料類型 (dtype)
vllm serve MODEL --quantization awq --dtype float16
```

## 效能問題 (Performance issues)

### 徵狀：吞吐量低 (預期 >100 req/sec，實際 <50)

**診斷步驟**：

1. **檢查 GPU 使用率**：
```bash
watch -n 1 nvidia-smi
# GPU 使用率應 >80%
```

若低於 80%，請增加並發請求數：
```bash
vllm serve MODEL --max-num-seqs 512  # 從 256 調升
```

2. **檢查是否受限於記憶體**：
```bash
# 若記憶體達到 100% 但 GPU 使用率 <80%，請縮短序列長度
vllm serve MODEL --max-model-len 4096
```

3. **啟用最佳化功能**：
```bash
vllm serve MODEL \
  --enable-prefix-caching \
  --enable-chunked-prefill \
  --max-num-seqs 512
```

4. **檢查張量並行 (Tensor parallelism) 設定**：
```bash
# 必須使用 2 的冪次個 GPU
vllm serve MODEL --tensor-parallel-size 4  # 而非 3 或 5
```

### 徵狀：首字生成延遲高 (TTFT >1 秒)

**原因與解決方案**：

**提示詞過長**：
```bash
vllm serve MODEL --enable-chunked-prefill
```

**未啟用前綴快取 (Prefix caching)**：
```bash
vllm serve MODEL --enable-prefix-caching  # 針對重複提示詞
```

**並發請求過多**：
```bash
vllm serve MODEL --max-num-seqs 64  # 減少以優先降低延遲
```

**模型對於單一 GPU 而言過大**：
```bash
vllm serve MODEL --tensor-parallel-size 2  # 並行化 prefill 過程
```

### 徵狀：Token 生成速度慢 (tokens/sec 低)

**診斷**：
```bash
# 檢查模型大小是否正確
vllm serve MODEL  # 應在日誌中看到模型大小

# 檢查投機解碼 (Speculative decoding)
vllm serve MODEL --speculative-model DRAFT_MODEL
```

**針對 H100 GPU**，請啟用 FP8：
```bash
vllm serve MODEL --quantization fp8
```

## 模型載入錯誤 (Model loading errors)

### 徵狀：`OSError: MODEL not found`

**原因**：

1. **模型名稱拼字錯誤**：
```bash
# 在 HuggingFace 上檢查確切名稱
vllm serve meta-llama/Llama-3-8B-Instruct  # 注意大小寫
```

2. **私有或需授權的模型**：
```bash
# 先登入 HuggingFace
huggingface-cli login
# 再執行 vLLM
vllm serve meta-llama/Llama-3-70B-Instruct
```

3. **自定義模型需要信任標記**：
```bash
vllm serve MODEL --trust-remote-code
```

### 徵狀：`ValueError: Tokenizer not found`

**解決方案**：
```bash
# 先手動下載模型
python -c "from transformers import AutoTokenizer; AutoTokenizer.from_pretrained('MODEL')"

# 再啟動 vLLM
vllm serve MODEL
```

### 徵狀：`ImportError: No module named 'flash_attn'`

**解決方案**：
```bash
# 安裝 flash attention
pip install flash-attn --no-build-isolation

# 或停用 flash attention
vllm serve MODEL --disable-flash-attn
```

## 網路與連線問題

### 徵狀：查詢伺服器時出現 `Connection refused`

**診斷**：

1. **檢查伺服器是否正在執行**：
```bash
curl http://localhost:8000/health
```

2. **檢查連接埠綁定 (Port binding)**：
```bash
# 綁定到所有介面以允許遠端存取
vllm serve MODEL --host 0.0.0.0 --port 8000

# 檢查連接埠是否已被佔用
lsof -i :8000
```

3. **檢查防火牆**：
```bash
# 允許透過防火牆存取連接埠
sudo ufw allow 8000
```

### 徵狀：透過網路回應時間緩慢

**解決方案**：

1. **增加超時設定**：
```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="EMPTY",
    timeout=300.0  # 5 分鐘超時
)
```

2. **檢查網路延遲**：
```bash
ping SERVER_IP  # 區域網路應 <10ms
```

3. **使用連線池 (Connection pooling)**：
```python
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

session = requests.Session()
retries = Retry(total=3, backoff_factor=1)
session.mount('http://', HTTPAdapter(max_retries=retries))
```

## 量化相關問題

### 徵狀：`RuntimeError: Quantization format not supported`

**解決方案**：
```bash
# 確保量化方法正確
vllm serve MODEL --quantization awq  # 針對 AWQ 模型
vllm serve MODEL --quantization gptq  # 針對 GPTQ 模型

# 檢查模型卡 (Model card) 以確認量化類型
```

### 徵狀：量化後輸出品質不佳

**診斷**：

1. **驗證模型是否已正確量化**：
```bash
# 檢查模型 config.json 中的 quantization_config
cat ~/.cache/huggingface/hub/models--MODEL/config.json
```

2. **嘗試不同的量化方法**：
```bash
# 若 AWQ 品質有問題，嘗試 FP8 (僅限 H100)
vllm serve MODEL --quantization fp8

# 或使用較不激進的量化
vllm serve MODEL  # 不進行量化
```

3. **增加溫度 (Temperature) 以提高多樣性**：
```python
sampling_params = SamplingParams(temperature=0.8, top_p=0.95)
```

## 分散式服務問題

### 徵狀：`RuntimeError: Distributed init failed`

**診斷**：

1. **檢查環境變數**：
```bash
# 在所有節點上
echo $MASTER_ADDR  # 應相同
echo $MASTER_PORT  # 應相同
echo $RANK  # 每個節點應唯一 (0, 1, 2, ...)
echo $WORLD_SIZE  # 應相同 (總節點數)
```

2. **檢查網路連通性**：
```bash
# 從節點 1 到節點 2
ping NODE2_IP
nc -zv NODE2_IP 29500  # 檢查連接埠是否可連通
```

3. **檢查 NCCL 設定**：
```bash
export NCCL_DEBUG=INFO
export NCCL_SOCKET_IFNAME=eth0  # 或您的網路介面名稱
vllm serve MODEL --tensor-parallel-size 8
```

### 徵狀：`NCCL error: unhandled cuda error`

**解決方案**：

```bash
# 設定 NCCL 使用正確的網路介面
export NCCL_SOCKET_IFNAME=eth0  # 替換為您的介面名稱

# 增加超時設定
export NCCL_TIMEOUT=1800  # 30 分鐘

# 為了除錯，強制停用 P2P
export NCCL_P2P_DISABLE=1
```

## 除錯工具與指令

### 啟用除錯日誌 (Debug logging)

```bash
export VLLM_LOGGING_LEVEL=DEBUG
vllm serve MODEL
```

### 監控 GPU 使用率

```bash
# 即時 GPU 監控
watch -n 1 nvidia-smi

# 記憶體細節
nvidia-smi --query-gpu=memory.used,memory.free --format=csv -l 1
```

### 效能分析 (Profiling)

```bash
# 內建基準測試
vllm bench throughput \
  --model MODEL \
  --input-tokens 128 \
  --output-tokens 256 \
  --num-prompts 100

vllm bench latency \
  --model MODEL \
  --input-tokens 128 \
  --output-tokens 256 \
  --batch-size 8
```

### 檢查指標 (Metrics)

```bash
# Prometheus 指標
curl http://localhost:9090/metrics

# 過濾特定指標
curl http://localhost:9090/metrics | grep vllm_time_to_first_token

# 建議監控的關鍵指標：
# - vllm_time_to_first_token_seconds
# - vllm_time_per_output_token_seconds
# - vllm_num_requests_running
# - vllm_gpu_cache_usage_perc
# - vllm_request_success_total
```

### 測試伺服器健康狀況

```bash
# 健康檢查
curl http://localhost:8000/health

# 模型資訊
curl http://localhost:8000/v1/models

# 測試補全 (Completion)
curl http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MODEL",
    "prompt": "Hello",
    "max_tokens": 10
  }'
```

### 常見環境變數

```bash
# CUDA 設定
export CUDA_VISIBLE_DEVICES=0,1,2,3  # 限制使用的 GPU

# vLLM 設定
export VLLM_LOGGING_LEVEL=DEBUG
export VLLM_TRACE_FUNCTION=1  # 函數效能分析
export VLLM_USE_V1=1  # 使用 v1.0 引擎 (速度更快)

# NCCL 設定 (分散式)
export NCCL_DEBUG=INFO
export NCCL_SOCKET_IFNAME=eth0
export NCCL_IB_DISABLE=0  # 啟用 InfiniBand
```

### 收集錯誤報告的診斷資訊

```bash
# 系統資訊
nvidia-smi
python --version
pip show vllm

# vLLM 版本與配置
vllm --version
python -c "import vllm; print(vllm.__version__)"

# 執行並紀錄除錯日誌
export VLLM_LOGGING_LEVEL=DEBUG
vllm serve MODEL 2>&1 | tee vllm_debug.log

# 在錯誤報告中包含：
# - vllm_debug.log
# - nvidia-smi 輸出結果
# - 完整使用的指令
# - 預期行為與實際行為的差異
```
