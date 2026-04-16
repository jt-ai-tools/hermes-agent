# 正式環境服務指南

在正式環境（Production）部署 TensorRT-LLM 的全面指南。

## 伺服器模式

### trtllm-serve (推薦)

**特性**：
- 相容 OpenAI 的 API
- 自動下載與編譯模型
- 內建負載平衡
- Prometheus 指標監控
- 健康檢查

**基本用法**：
```bash
trtllm-serve meta-llama/Meta-Llama-3-8B \
    --tp_size 1 \
    --max_batch_size 256 \
    --port 8000
```

**進階配置**：
```bash
trtllm-serve meta-llama/Meta-Llama-3-70B \
    --tp_size 4 \
    --dtype fp8 \
    --max_batch_size 256 \
    --max_num_tokens 4096 \
    --enable_chunked_context \
    --scheduler_policy max_utilization \
    --port 8000 \
    --api_key $API_KEY  # 選用身份驗證
```

### Python LLM API (用於嵌入式整合)

```python
from tensorrt_llm import LLM

class LLMService:
    def __init__(self):
        self.llm = LLM(
            model="meta-llama/Meta-Llama-3-8B",
            dtype="fp8"
        )

    def generate(self, prompt, max_tokens=100):
        from tensorrt_llm import SamplingParams

        params = SamplingParams(
            max_tokens=max_tokens,
            temperature=0.7
        )
        outputs = self.llm.generate([prompt], params)
        return outputs[0].text

# 可用於 FastAPI, Flask 等框架
from fastapi import FastAPI
app = FastAPI()
service = LLMService()

@app.post("/generate")
def generate(prompt: str):
    return {"response": service.generate(prompt)}
```

## OpenAI 相容 API

### 聊天補全 (Chat Completions)

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Meta-Llama-3-8B",
    "messages": [
      {"role": "system", "content": "你是一個得力的助手。"},
      {"role": "user", "content": "請解釋量子運算"}
    ],
    "temperature": 0.7,
    "max_tokens": 500,
    "stream": false
  }'
```

**回應範例**：
```json
{
  "id": "chat-abc123",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "meta-llama/Meta-Llama-3-8B",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "量子運算是一種..."
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 25,
    "completion_tokens": 150,
    "total_tokens": 175
  }
}
```

### 串流 (Streaming)

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Meta-Llama-3-8B",
    "messages": [{"role": "user", "content": "從 1 數到 10"}],
    "stream": true
  }'
```

**回應範例** (SSE 串流)：
```
data: {"choices":[{"delta":{"content":"1"}}]}

data: {"choices":[{"delta":{"content":", 2"}}]}

data: {"choices":[{"delta":{"content":", 3"}}]}

data: [DONE]
```

### 文字補全 (Completions)

```bash
curl -X POST http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Meta-Llama-3-8B",
    "prompt": "法國的首都是",
    "max_tokens": 10,
    "temperature": 0.0
  }'
```

## 監控

### Prometheus 指標

**啟用指標監控**：
```bash
trtllm-serve meta-llama/Meta-Llama-3-8B \
    --enable_metrics \
    --metrics_port 9090
```

**關鍵指標**：
```bash
# 抓取指標
curl http://localhost:9090/metrics

# 重要指標：
# - trtllm_request_success_total - 成功的請求總數
# - trtllm_request_latency_seconds - 請求延遲直方圖
# - trtllm_tokens_generated_total - 生成的 token 總數
# - trtllm_active_requests - 當前活動中的請求
# - trtllm_queue_size - 隊列中等待的請求
# - trtllm_gpu_memory_usage_bytes - GPU 記憶體使用量
# - trtllm_kv_cache_usage_ratio - KV 快取利用率
```

### 健康檢查

```bash
# 就緒檢查 (Readiness probe)
curl http://localhost:8000/health/ready

# 存活檢查 (Liveness probe)
curl http://localhost:8000/health/live

# 模型資訊
curl http://localhost:8000/v1/models
```

**Kubernetes Probes 配置**：
```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8000
  initialDelaySeconds: 60
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8000
  initialDelaySeconds: 30
  periodSeconds: 5
```

## 正式部署

### Docker 部署

**Dockerfile 範例**：
```dockerfile
FROM nvidia/tensorrt_llm:latest

# 複製自定義配置
COPY config.yaml /app/config.yaml

# 公開埠位
EXPOSE 8000 9090

# 啟動伺服器
CMD ["trtllm-serve", "meta-llama/Meta-Llama-3-8B", \
     "--tp_size", "4", \
     "--dtype", "fp8", \
     "--max_batch_size", "256", \
     "--enable_metrics", \
     "--metrics_port", "9090"]
```

**執行容器**：
```bash
docker run --gpus all -p 8000:8000 -p 9090:9090 \
    tensorrt-llm:latest
```

### Kubernetes 部署

**完整 Deployment 範例**：
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tensorrt-llm
spec:
  replicas: 2  # 多個副本以實現高可用性 (HA)
  selector:
    matchLabels:
      app: tensorrt-llm
  template:
    metadata:
      labels:
        app: tensorrt-llm
    spec:
      containers:
      - name: trtllm
        image: nvidia/tensorrt_llm:latest
        command:
          - trtllm-serve
          - meta-llama/Meta-Llama-3-70B
          - --tp_size=4
          - --dtype=fp8
          - --max_batch_size=256
          - --enable_metrics
        ports:
        - containerPort: 8000
          name: http
        - containerPort: 9090
          name: metrics
        resources:
          limits:
            nvidia.com/gpu: 4
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8000
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: tensorrt-llm
spec:
  selector:
    app: tensorrt-llm
  ports:
  - name: http
    port: 80
    targetPort: 8000
  - name: metrics
    port: 9090
    targetPort: 9090
  type: LoadBalancer
```

### 負載平衡 (Load Balancing)

**NGINX 配置範例**：
```nginx
upstream tensorrt_llm {
    least_conn;  # 路由到負擔最輕的伺服器
    server trtllm-1:8000 max_fails=3 fail_timeout=30s;
    server trtllm-2:8000 max_fails=3 fail_timeout=30s;
    server trtllm-3:8000 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    location / {
        proxy_pass http://tensorrt_llm;
        proxy_read_timeout 300s;  # 針對緩慢生成的長超時設定
        proxy_connect_timeout 10s;
    }
}
```

## 自動擴展 (Autoscaling)

### 水平 Pod 自動擴展器 (HPA)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: tensorrt-llm-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: tensorrt-llm
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Pods
    pods:
      metric:
        name: trtllm_active_requests
      target:
        type: AverageValue
        averageValue: "50"  # 當平均超過 50 個活動請求時進行擴展
```

### 自定義指標

```yaml
# 根據隊列大小進行擴展
- type: Pods
  pods:
    metric:
      name: trtllm_queue_size
    target:
      type: AverageValue
      averageValue: "10"
```

## 成本優化

### GPU 選擇

**A100 80GB** ($3-4/小時)：
- 適用於：搭載 FP8 的 70B 模型
- 吞吐量：10,000-15,000 tok/s (TP=4)
- 每 100 萬 token 的成本：$0.20-0.30 美元

**H100 80GB** ($6-8/小時)：
- 適用於：搭載 FP8 的 70B 模型、405B 模型
- 吞吐量：20,000-30,000 tok/s (TP=4)
- 每 100 萬 token 的成本：$0.15-0.25 美元 (快 2 倍 = 成本更低)

**L4** ($0.50-1/小時)：
- 適用於：7-8B 模型
- 吞吐量：1,000-2,000 tok/s
- 每 100 萬 token 的成本：$0.25-0.50 美元

### 批處理量 (Batch Size) 調優

**對成本的影響**：
- 批處理量 1：1,000 tok/s → 每 100 萬 token $3 美元
- 批處理量 64：5,000 tok/s → 每 500 萬 token $3 美元 (即 $0.60/M token)
- 透過批處理可實現 **5 倍的成本降低**

**建議**：目標批處理量設為 32-128 以獲得最佳成本效益。

## 安全性

### API 身份驗證

```bash
# 生成 API 金鑰
export API_KEY=$(openssl rand -hex 32)

# 使用身份驗證啟動伺服器
trtllm-serve meta-llama/Meta-Llama-3-8B \
    --api_key $API_KEY

# 用戶端請求
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "...", "messages": [...]}'
```

### 網路策略 (Network Policies)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: tensorrt-llm-policy
spec:
  podSelector:
    matchLabels:
      app: tensorrt-llm
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api-gateway  # 僅允許來自網關的流量
    ports:
    - protocol: TCP
      port: 8000
```

## 故障排除

### 延遲過高

**診斷**：
```bash
# 檢查隊列大小
curl http://localhost:9090/metrics | grep queue_size

# 檢查活動請求
curl http://localhost:9090/metrics | grep active_requests
```

**解決方案**：
- 水平擴充（增加副本數）
- 增加批處理量（若 GPU 利用率尚低）
- 啟用分塊上下文（針對長提示詞）
- 使用 FP8 量化

### OOM (記憶體溢出) 當機

**解決方案**：
- 減少 `max_batch_size`
- 減少 `max_num_tokens`
- 啟用 FP8 或 INT4 量化
- 增加 `tensor_parallel_size`

### 超時錯誤

**NGINX 配置調整**：
```nginx
proxy_read_timeout 600s;  # 針對極長生成時間設為 10 分鐘
proxy_send_timeout 600s;
```

## 最佳實踐

1. **在 H100 上使用 FP8**：可獲得 2 倍加速並降低 50% 成本。
2. **監控指標**：建立 Prometheus + Grafana 圖表。
3. **設定就緒檢查**：防止將流量路由到不健康的 Pod。
4. **使用負載平衡**：將負載分佈到多個副本。
5. **調優批處理量**：在延遲與吞吐量之間取得平衡。
6. **啟用串流**：為聊天應用程式提供更好的使用者體驗。
7. **建立自動擴充**：應對流量高峰。
8. **使用持久化磁碟 (Persistent Volumes)**：快取編譯後的模型。
9. **實作重試機制**：處理瞬時故障。
10. **監控成本**：追蹤每個 token 的成本。
