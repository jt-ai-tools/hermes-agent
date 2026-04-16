# Modal 進階用法指南

## 多 GPU 訓練 (Multi-GPU Training)

### 單節點多 GPU (Single-node multi-GPU)

```python
import modal

app = modal.App("multi-gpu-training")
image = modal.Image.debian_slim().pip_install("torch", "transformers", "accelerate")

@app.function(gpu="H100:4", image=image, timeout=7200)
def train_multi_gpu():
    from accelerate import Accelerator

    accelerator = Accelerator()
    model, optimizer, dataloader = accelerator.prepare(model, optimizer, dataloader)

    for batch in dataloader:
        outputs = model(**batch)
        loss = outputs.loss
        accelerator.backward(loss)
        optimizer.step()
```

### DeepSpeed 整合

```python
image = modal.Image.debian_slim().pip_install(
    "torch", "transformers", "deepspeed", "accelerate"
)

@app.function(gpu="A100:8", image=image, timeout=14400)
def deepspeed_train(config: dict):
    from transformers import Trainer, TrainingArguments

    args = TrainingArguments(
        output_dir="/outputs",
        deepspeed="ds_config.json",
        fp16=True,
        per_device_train_batch_size=4,
        gradient_accumulation_steps=4
    )

    trainer = Trainer(model=model, args=args, train_dataset=dataset)
    trainer.train()
```

### 多 GPU 考量因素

對於會重新執行 Python 入口點 (entrypoint) 的框架（例如 PyTorch Lightning），請使用：
- `ddp_spawn` 或 `ddp_notebook` 策略
- 將訓練作為子程序 (subprocess) 執行以避免問題

```python
@app.function(gpu="H100:4")
def train_with_subprocess():
    import subprocess
    subprocess.run(["python", "-m", "torch.distributed.launch", "train.py"])
```

## 進階容器配置

### 快取的平行多階段構建 (Multi-stage builds for caching)

```python
# 階段 1: 基礎相依套件 (已快取)
base_image = modal.Image.debian_slim().pip_install("torch", "numpy", "scipy")

# 階段 2: ML 函式庫 (單獨快取)
ml_image = base_image.pip_install("transformers", "datasets", "accelerate")

# 階段 3: 自定義程式碼 (變更時重新建構)
final_image = ml_image.copy_local_dir("./src", "/app/src")
```

### 自定義 Dockerfiles

```python
image = modal.Image.from_dockerfile("./Dockerfile")
```

### 從 Git 安裝

```python
image = modal.Image.debian_slim().pip_install(
    "git+https://github.com/huggingface/transformers.git@main"
)
```

### 使用 uv 進行更快速的安裝

```python
image = modal.Image.debian_slim().uv_pip_install(
    "torch", "transformers", "accelerate"
)
```

## 進階類別模式 (Advanced Class Patterns)

### 生命週期掛鉤 (Lifecycle hooks)

```python
@app.cls(gpu="A10G")
class InferenceService:
    @modal.enter()
    def startup(self):
        """容器啟動時呼叫一次"""
        self.model = load_model()
        self.tokenizer = load_tokenizer()

    @modal.exit()
    def shutdown(self):
        """容器關閉時呼叫"""
        cleanup_resources()

    @modal.method()
    def predict(self, text: str):
        return self.model(self.tokenizer(text))
```

### 並行請求處理 (Concurrent request handling)

```python
@app.cls(
    gpu="A100",
    allow_concurrent_inputs=20,  # 每個容器處理 20 個請求
    container_idle_timeout=300
)
class BatchInference:
    @modal.enter()
    def load(self):
        self.model = load_model()

    @modal.method()
    def predict(self, inputs: list):
        return self.model.batch_predict(inputs)
```

### 輸入並行 vs 批次處理

- **輸入並行 (Input concurrency)**: 同時處理多個請求 (async I/O)
- **動態批次處理 (Dynamic batching)**: 累積請求並一起處理 (提升 GPU 效率)

```python
# 輸入並行 - 適合 I/O 密集型
@app.function(allow_concurrent_inputs=10)
async def fetch_data(url: str):
    async with aiohttp.ClientSession() as session:
        return await session.get(url)

# 動態批次處理 - 適合 GPU 推論
@app.function()
@modal.batched(max_batch_size=32, wait_ms=100)
async def batch_embed(texts: list[str]) -> list[list[float]]:
    return model.encode(texts)
```

## 進階磁碟區 (Advanced Volumes)

### 磁碟區操作

```python
volume = modal.Volume.from_name("my-volume", create_if_missing=True)

@app.function(volumes={"/data": volume})
def volume_operations():
    import os

    # 寫入資料
    with open("/data/output.txt", "w") as f:
        f.write("Results")

    # 提交變更 (持久化到磁碟區)
    volume.commit()

    # 從遠端重新載入 (取得最新版本)
    volume.reload()
```

### 函式間共享磁碟區

```python
shared_volume = modal.Volume.from_name("shared-data", create_if_missing=True)

@app.function(volumes={"/shared": shared_volume})
def writer():
    with open("/shared/data.txt", "w") as f:
        f.write("Hello from writer")
    shared_volume.commit()

@app.function(volumes={"/shared": shared_volume})
def reader():
    shared_volume.reload()  # 取得最新版本
    with open("/shared/data.txt", "r") as f:
        return f.read()
```

### 雲端儲存貯體掛載 (Cloud bucket mounts)

```python
# 掛載 S3 儲存貯體
bucket = modal.CloudBucketMount(
    bucket_name="my-bucket",
    secret=modal.Secret.from_name("aws-credentials")
)

@app.function(volumes={"/s3": bucket})
def process_s3_data():
    # 像本地檔案系統一樣存取 S3 檔案
    data = open("/s3/data.parquet").read()
```

## 函式組合 (Function Composition)

### 串聯函式 (Chaining functions)

```python
@app.function()
def preprocess(data):
    return cleaned_data

@app.function(gpu="T4")
def inference(data):
    return predictions

@app.function()
def postprocess(predictions):
    return formatted_results

@app.function()
def pipeline(raw_data):
    cleaned = preprocess.remote(raw_data)
    predictions = inference.remote(cleaned)
    results = postprocess.remote(predictions)
    return results
```

### 並行扇出 (Parallel fan-out)

```python
@app.function()
def process_item(item):
    return expensive_computation(item)

@app.function()
def parallel_pipeline(items):
    # 扇出：並行處理所有項目
    results = list(process_item.map(items))
    return results
```

### 用於多個引數的 Starmap

```python
@app.function()
def process(x, y, z):
    return x + y + z

@app.function()
def orchestrate():
    args = [(1, 2, 3), (4, 5, 6), (7, 8, 9)]
    results = list(process.starmap(args))
    return results
```

## 進階 Web 端點

### WebSocket 支援

```python
from fastapi import FastAPI, WebSocket

app = modal.App("websocket-app")
web_app = FastAPI()

@web_app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    while True:
        data = await websocket.receive_text()
        await websocket.send_text(f"Processed: {data}")

@app.function()
@modal.asgi_app()
def ws_app():
    return web_app
```

### 串流回應 (Streaming responses)

```python
from fastapi.responses import StreamingResponse

@app.function(gpu="A100")
def generate_stream(prompt: str):
    for token in model.generate_stream(prompt):
        yield token

@web_app.get("/stream")
async def stream_response(prompt: str):
    return StreamingResponse(
        generate_stream.remote_gen(prompt),
        media_type="text/event-stream"
    )
```

### 身分驗證 (Authentication)

```python
from fastapi import Depends, HTTPException, Header

async def verify_token(authorization: str = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401)
    token = authorization.split(" ")[1]
    if not verify_jwt(token):
        raise HTTPException(status_code=403)
    return token

@web_app.post("/predict")
async def predict(data: dict, token: str = Depends(verify_token)):
    return model.predict(data)
```

## 成本優化

### 適當調整 GPU 大小 (Right-sizing GPUs)

```python
# 用於推論：較小的 GPU 通常足夠
@app.function(gpu="L40S")  # 48GB，推論的最佳性價比
def inference():
    pass

# 用於訓練：較大的 GPU 以獲得吞吐量
@app.function(gpu="A100-80GB")
def training():
    pass
```

### 針對可用性的 GPU 備援 (GPU fallbacks)

```python
@app.function(gpu=["H100", "A100", "L40S"])  # 依序嘗試
def flexible_compute():
    pass
```

### 縮減至零 (Scale to zero)

```python
# 預設行為：閒置時縮減至零
@app.function(gpu="A100")
def on_demand():
    pass

# 保持容器熱啟動以降低延遲（成本較高）
@app.function(gpu="A100", keep_warm=1)
def always_ready():
    pass
```

### 批次處理以提高效率

```python
# 批次處理以減少冷啟動
@app.function(gpu="A100")
def batch_process(items: list):
    return [process(item) for item in items]

# 優於個別呼叫
results = batch_process.remote(all_items)
```

## 監控與可觀察性 (Monitoring and Observability)

### 結構化日誌 (Structured logging)

```python
import json
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.function()
def structured_logging(request_id: str, data: dict):
    logger.info(json.dumps({
        "event": "inference_start",
        "request_id": request_id,
        "input_size": len(data)
    }))

    result = process(data)

    logger.info(json.dumps({
        "event": "inference_complete",
        "request_id": request_id,
        "output_size": len(result)
    }))

    return result
```

### 自定義指標 (Custom metrics)

```python
@app.function(gpu="A100")
def monitored_inference(inputs):
    import time

    start = time.time()
    results = model.predict(inputs)
    latency = time.time() - start

    # 記錄指標 (可見於 Modal 儀表板)
    print(f"METRIC latency={latency:.3f}s batch_size={len(inputs)}")

    return results
```

## 生產環境部署

### 環境隔離 (Environment separation)

```python
import os

env = os.environ.get("MODAL_ENV", "dev")
app = modal.App(f"my-service-{env}")

# 特定環境配置
if env == "prod":
    gpu_config = "A100"
    timeout = 3600
else:
    gpu_config = "T4"
    timeout = 300
```

### 零停機部署 (Zero-downtime deployments)

Modal 自動處理零停機部署：
1. 建置並啟動新容器
2. 流量逐漸轉移至新版本
3. 舊容器消耗完現有請求
4. 舊容器被終止

### 健康檢查 (Health checks)

```python
@app.function()
@modal.web_endpoint()
def health():
    return {
        "status": "healthy",
        "model_loaded": hasattr(Model, "_model"),
        "gpu_available": torch.cuda.is_available()
    }
```

## 沙箱 (Sandboxes)

### 互動式執行環境

```python
@app.function()
def run_sandbox():
    sandbox = modal.Sandbox.create(
        app=app,
        image=image,
        gpu="T4"
    )

    # 在沙箱中執行程式碼
    result = sandbox.exec("python", "-c", "print('Hello from sandbox')")

    sandbox.terminate()
    return result
```

## 呼叫已部署的函式

### 從外部程式碼

```python
# 從任何 Python 腳本呼叫已部署的函式
import modal

f = modal.Function.lookup("my-app", "my_function")
result = f.remote(arg1, arg2)
```

### REST API 呼叫

```bash
# 透過 HTTPS 存取已部署的端點
curl -X POST https://your-workspace--my-app-predict.modal.run \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello world"}'
```
