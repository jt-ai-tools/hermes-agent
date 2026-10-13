# 伺服器部署指南

生產環境下部署具備 OpenAI 相容 API 的 llama.cpp 伺服器。

## 伺服器模式

### llama-server

```bash
# 基本伺服器
./llama-server \
    -m models/llama-2-7b-chat.Q4_K_M.gguf \
    --host 0.0.0.0 \
    --port 8080 \
    -c 4096  # 上下文大小 (Context size)

# 使用 GPU 加速
./llama-server \
    -m models/llama-2-70b.Q4_K_M.gguf \
    -ngl 40  # 將 40 層卸載到 GPU
```

## OpenAI 相容 API

### 對話補全 (Chat completions)
```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-2",
    "messages": [
      {"role": "system", "content": "你是一個樂於助人的助手"},
      {"role": "user", "content": "你好"}
    ],
    "temperature": 0.7,
    "max_tokens": 100
  }'
```

### 串流 (Streaming)
```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-2",
    "messages": [{"role": "user", "content": "數到 10"}],
    "stream": true
  }'
```

## Docker 部署

**Dockerfile**：
```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y git build-essential
RUN git clone https://github.com/ggerganov/llama.cpp
WORKDIR /llama.cpp
RUN make LLAMA_CUDA=1
COPY models/ /models/
EXPOSE 8080
CMD ["./llama-server", "-m", "/models/model.gguf", "--host", "0.0.0.0", "--port", "8080"]
```

**執行**：
```bash
docker run --gpus all -p 8080:8080 llama-cpp:latest
```

## 監控 (Monitoring)

```bash
# 伺服器指標 (Metrics) 端點
curl http://localhost:8080/metrics

# 健康檢查
curl http://localhost:8080/health
```

**指標 (Metrics)**：
- requests_total (總請求數)
- tokens_generated (生成的總標記數)
- prompt_tokens (提示標記數)
- completion_tokens (補全標記數)
- kv_cache_tokens (KV 快取標記數)

## 負載平衡 (Load Balancing)

**NGINX 範例**：
```nginx
upstream llama_cpp {
    server llama1:8080;
    server llama2:8080;
}

server {
    location / {
        proxy_pass http://llama_cpp;
        proxy_read_timeout 300s;
    }
}
```

## 效能調優 (Performance Tuning)

**平行請求 (Parallel requests)**：
```bash
./llama-server \
    -m model.gguf \
    -np 4  # 4 個平行插槽 (parallel slots)
```

**連續批次處理 (Continuous batching)**：
```bash
./llama-server \
    -m model.gguf \
    --cont-batching  # 啟用連續批次處理
```

**上下文快取 (Context caching)**：
```bash
./llama-server \
    -m model.gguf \
    --cache-prompt  # 快取已處理過的提示
```
