# 伺服器部署模式 (Server Deployment Patterns)

## 目錄
- Docker 部署
- Kubernetes 部署
- 使用 Nginx 進行負載平衡
- 多節點分散式服務
- 生產環境配置範例
- 健康檢查與監控

## Docker 部署

**基礎 Dockerfile**：
```dockerfile
FROM nvidia/cuda:12.1.0-devel-ubuntu22.04

RUN apt-get update && apt-get install -y python3-pip
RUN pip install vllm

EXPOSE 8000

CMD ["vllm", "serve", "meta-llama/Llama-3-8B-Instruct", \
     "--host", "0.0.0.0", "--port", "8000", \
     "--gpu-memory-utilization", "0.9"]
```

**建構與執行**：
```bash
docker build -t vllm-server .
docker run --gpus all -p 8000:8000 vllm-server
```

**Docker Compose** (含指標監控)：
```yaml
version: '3.8'
services:
  vllm:
    image: vllm/vllm-openai:latest
    command: >
      --model meta-llama/Llama-3-8B-Instruct
      --gpu-memory-utilization 0.9
      --enable-metrics
      --metrics-port 9090
    ports:
      - "8000:8000"
      - "9090:9090"
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

## Kubernetes 部署

**部署清單 (Deployment manifest)**：
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vllm-server
spec:
  replicas: 2
  selector:
    matchLabels:
      app: vllm
  template:
    metadata:
      labels:
        app: vllm
    spec:
      containers:
      - name: vllm
        image: vllm/vllm-openai:latest
        args:
          - "--model=meta-llama/Llama-3-8B-Instruct"
          - "--gpu-memory-utilization=0.9"
          - "--enable-prefix-caching"
        resources:
          limits:
            nvidia.com/gpu: 1
        ports:
        - containerPort: 8000
          name: http
        - containerPort: 9090
          name: metrics
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 60
          periodSeconds: 30
---
apiVersion: v1
kind: Service
metadata:
  name: vllm-service
spec:
  selector:
    app: vllm
  ports:
  - port: 8000
    targetPort: 8000
    name: http
  - port: 9090
    targetPort: 9090
    name: metrics
  type: LoadBalancer
```

## 使用 Nginx 進行負載平衡

**Nginx 配置**：
```nginx
upstream vllm_backend {
    least_conn;  # 路由至負載最輕的伺服器
    server localhost:8001;
    server localhost:8002;
    server localhost:8003;
}

server {
    listen 80;

    location / {
        proxy_pass http://vllm_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;

        # 長時間推論的超時設定
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # 指標監控端點
    location /metrics {
        proxy_pass http://localhost:9090/metrics;
    }
}
```

**啟動多個 vLLM 實例**：
```bash
# 終端機 1
vllm serve MODEL --port 8001 --tensor-parallel-size 1

# 終端機 2
vllm serve MODEL --port 8002 --tensor-parallel-size 1

# 終端機 3
vllm serve MODEL --port 8003 --tensor-parallel-size 1

# 啟動 Nginx
nginx -c /path/to/nginx.conf
```

## 多節點分散式服務

針對單一節點無法裝載的大型模型：

**節點 1** (Master)：
```bash
export MASTER_ADDR=192.168.1.10
export MASTER_PORT=29500
export RANK=0
export WORLD_SIZE=2

vllm serve meta-llama/Llama-2-70b-hf \
  --tensor-parallel-size 8 \
  --pipeline-parallel-size 2
```

**節點 2** (Worker)：
```bash
export MASTER_ADDR=192.168.1.10
export MASTER_PORT=29500
export RANK=1
export WORLD_SIZE=2

vllm serve meta-llama/Llama-2-70b-hf \
  --tensor-parallel-size 8 \
  --pipeline-parallel-size 2
```

## 生產環境配置範例

**高吞吐量** (批次密集型工作負載)：
```bash
vllm serve MODEL \
  --max-num-seqs 512 \
  --gpu-memory-utilization 0.95 \
  --enable-prefix-caching \
  --trust-remote-code
```

**低延遲** (互動式工作負載)：
```bash
vllm serve MODEL \
  --max-num-seqs 64 \
  --gpu-memory-utilization 0.85 \
  --enable-chunked-prefill
```

**記憶體受限** (在 40GB GPU 執行 70B 模型)：
```bash
vllm serve TheBloke/Llama-2-70B-AWQ \
  --quantization awq \
  --tensor-parallel-size 1 \
  --gpu-memory-utilization 0.95 \
  --max-model-len 4096
```

## 健康檢查與監控

**健康檢查端點**：
```bash
curl http://localhost:8000/health
# 回傳：{"status": "ok"}
```

**就緒檢查 (Readiness check)** (等待模型載入完成)：
```bash
#!/bin/bash
until curl -f http://localhost:8000/health; do
    echo "正在等待 vLLM 就緒..."
    sleep 5
done
echo "vLLM 已就緒！"
```

**Prometheus 抓取設定**：
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'vllm'
    static_configs:
      - targets: ['localhost:9090']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

**Grafana 儀表板** (關鍵指標)：
- 每秒請求數 (RPS)：`rate(vllm_request_success_total[5m])`
- TTFT p50：`histogram_quantile(0.5, vllm_time_to_first_token_seconds_bucket)`
- TTFT p99：`histogram_quantile(0.99, vllm_time_to_first_token_seconds_bucket)`
- GPU 快取使用率：`vllm_gpu_cache_usage_perc`
- 執行中請求數：`vllm_num_requests_running`
