---
name: modal-serverless-gpu
description: 用於執行 ML 工作負載的無伺服器 GPU 雲端平台。當您需要隨選 GPU 存取而無需管理基礎設施、將 ML 模型部署為 API 或執行具有自動擴展功能的批次作業時使用。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [modal>=0.64.0]
metadata:
  hermes:
    tags: [Infrastructure, Serverless, GPU, Cloud, Deployment, Modal]

---

# Modal Serverless GPU

在 Modal 的無伺服器 GPU 雲端平台上執行 ML 工作負載的全面指南。

## 何時使用 Modal

**在以下情況下使用 Modal：**
- 執行 GPU 密集型 ML 工作負載而無需管理基礎設施
- 將 ML 模型部署為具備自動擴展功能的 API
- 執行批次處理作業（訓練、推論、資料處理）
- 需要按秒計費的 GPU 價格，且無閒置成本
- 快速建立 ML 應用程式原型
- 執行排程作業（類似 cron 的工作負載）

**關鍵特性：**
- **Serverless GPUs**: 隨選提供 T4, L4, A10G, L40S, A100, H100, H200, B200
- **Python-native**: 在 Python 程式碼中定義基礎設施，無需 YAML
- **Auto-scaling**: 縮減至零，即時擴展至 100+ 個 GPU
- **次秒級冷啟動**: 基於 Rust 的基礎設施，可快速啟動容器
- **Container caching**: 快取映像層以進行快速迭代
- **Web endpoints**: 將函式部署為 REST API，支援零停機更新

**改用替代方案：**
- **RunPod**: 用於具有持久狀態且執行時間較長的 pod
- **Lambda Labs**: 用於預留 GPU 執行個體
- **SkyPilot**: 用於多雲編排和成本優化
- **Kubernetes**: 用於複雜的多服務架構

## 快速開始

### 安裝

```bash
pip install modal
modal setup  # 開啟瀏覽器進行驗證
```

### Hello World with GPU

```python
import modal

app = modal.App("hello-gpu")

@app.function(gpu="T4")
def gpu_info():
    import subprocess
    return subprocess.run(["nvidia-smi"], capture_output=True, text=True).stdout

@app.local_entrypoint()
def main():
    print(gpu_info.remote())
```

執行：`modal run hello_gpu.py`

### 基本推論端點 (inference endpoint)

```python
import modal

app = modal.App("text-generation")
image = modal.Image.debian_slim().pip_install("transformers", "torch", "accelerate")

@app.cls(gpu="A10G", image=image)
class TextGenerator:
    @modal.enter()
    def load_model(self):
        from transformers import pipeline
        self.pipe = pipeline("text-generation", model="gpt2", device=0)

    @modal.method()
    def generate(self, prompt: str) -> str:
        return self.pipe(prompt, max_length=100)[0]["generated_text"]

@app.local_entrypoint()
def main():
    print(TextGenerator().generate.remote("Hello, world"))
```

## 核心概念

### 關鍵組件

| 組件 | 用途 |
|-----------|---------|
| `App` | 函式與資源的容器 |
| `Function` | 具有運算規格的無伺服器函式 |
| `Cls` | 具有生命週期掛鉤 (lifecycle hooks) 的類別架構函式 |
| `Image` | 容器映像定義 |
| `Volume` | 用於模型/資料的持久化儲存 |
| `Secret` | 安全憑證儲存 |

### 執行模式

| 指令 | 描述 |
|---------|-------------|
| `modal run script.py` | 執行並退出 |
| `modal serve script.py` | 具有即時重載功能的開發模式 |
| `modal deploy script.py` | 持久化雲端部署 |

## GPU 配置

### 可用的 GPU

| GPU | VRAM | 最適合 |
|-----|------|----------|
| `T4` | 16GB | 預算有限的推論、小型模型 |
| `L4` | 24GB | 推論, Ada Lovelace 架構 |
| `A10G` | 24GB | 訓練/推論，比 T4 快 3.3 倍 |
| `L40S` | 48GB | 推薦用於推論（最佳性價比） |
| `A100-40GB` | 40GB | 大型模型訓練 |
| `A100-80GB` | 80GB | 極大型模型 |
| `H100` | 80GB | 最快，FP8 + Transformer Engine |
| `H200` | 141GB | 從 H100 自動升級, 4.8TB/s 頻寬 |
| `B200` | 最新 | Blackwell 架構 |

### GPU 規格模式

```python
# 單一 GPU
@app.function(gpu="A100")

# 特定記憶體變體
@app.function(gpu="A100-80GB")

# 多個 GPU (最多 8 個)
@app.function(gpu="H100:4")

# 具有備援的 GPU
@app.function(gpu=["H100", "A100", "L40S"])

# 任何可用的 GPU
@app.function(gpu="any")
```

## 容器映像 (Container images)

```python
# 使用 pip 的基本映像
image = modal.Image.debian_slim(python_version="3.11").pip_install(
    "torch==2.1.0", "transformers==4.36.0", "accelerate"
)

# 來自 CUDA 基礎
image = modal.Image.from_registry(
    "nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04",
    add_python="3.11"
).pip_install("torch", "transformers")

# 包含系統套件
image = modal.Image.debian_slim().apt_install("git", "ffmpeg").pip_install("whisper")
```

## 持久化儲存

```python
volume = modal.Volume.from_name("model-cache", create_if_missing=True)

@app.function(gpu="A10G", volumes={"/models": volume})
def load_model():
    import os
    model_path = "/models/llama-7b"
    if not os.path.exists(model_path):
        model = download_model()
        model.save_pretrained(model_path)
        volume.commit()  # 持久化變更
    return load_from_path(model_path)
```

## Web 端點 (Web endpoints)

### FastAPI 端點裝飾器

```python
@app.function()
@modal.fastapi_endpoint(method="POST")
def predict(text: str) -> dict:
    return {"result": model.predict(text)}
```

### 完整 ASGI 應用程式

```python
from fastapi import FastAPI
web_app = FastAPI()

@web_app.post("/predict")
async def predict(text: str):
    return {"result": await model.predict.remote.aio(text)}

@app.function()
@modal.asgi_app()
def fastapi_app():
    return web_app
```

### Web 端點類型

| 裝飾器 | 使用案例 |
|-----------|----------|
| `@modal.fastapi_endpoint()` | 簡單函式 → API |
| `@modal.asgi_app()` | 完整的 FastAPI/Starlette 應用程式 |
| `@modal.wsgi_app()` | Django/Flask 應用程式 |
| `@modal.web_server(port)` | 任意 HTTP 伺服器 |

## 動態批次處理 (Dynamic batching)

```python
@app.function()
@modal.batched(max_batch_size=32, wait_ms=100)
async def batch_predict(inputs: list[str]) -> list[dict]:
    # 輸入會自動進行批次處理
    return model.batch_predict(inputs)
```

## 秘密金鑰管理 (Secrets management)

```bash
# 建立 secret
modal secret create huggingface HF_TOKEN=hf_xxx
```

```python
@app.function(secrets=[modal.Secret.from_name("huggingface")])
def download_model():
    import os
    token = os.environ["HF_TOKEN"]
```

## 排程 (Scheduling)

```python
@app.function(schedule=modal.Cron("0 0 * * *"))  # 每天午夜
def daily_job():
    pass

@app.function(schedule=modal.Period(hours=1))
def hourly_job():
    pass
```

## 效能優化

### 冷啟動緩解

```python
@app.function(
    container_idle_timeout=300,  # 保持熱啟動狀態 5 分鐘
    allow_concurrent_inputs=10,  # 處理並行請求
)
def inference():
    pass
```

### 模型載入最佳實踐

```python
@app.cls(gpu="A100")
class Model:
    @modal.enter()  # 在容器啟動時執行一次
    def load(self):
        self.model = load_model()  # 在熱機期間載入

    @modal.method()
    def predict(self, x):
        return self.model(x)
```

## 並行處理

```python
@app.function()
def process_item(item):
    return expensive_computation(item)

@app.function()
def run_parallel():
    items = list(range(1000))
    # 分散到並行容器
    results = list(process_item.map(items))
    return results
```

## 常見配置

```python
@app.function(
    gpu="A100",
    memory=32768,              # 32GB RAM
    cpu=4,                     # 4 個 CPU 核心
    timeout=3600,              # 最長 1 小時
    container_idle_timeout=120,# 保持熱啟動狀態 2 分鐘
    retries=3,                 # 失敗後重試
    concurrency_limit=10,      # 最大並行容器數
)
def my_function():
    pass
```

## 偵錯 (Debugging)

```python
# 本地測試
if __name__ == "__main__":
    result = my_function.local()

# 查看日誌
# modal app logs my-app
```

## 常見問題

| 問題 | 解決方案 |
|-------|----------|
| 冷啟動延遲 | 增加 `container_idle_timeout`，使用 `@modal.enter()` |
| GPU 記憶體不足 (OOM) | 使用較大的 GPU (`A100-80GB`)，啟用梯度檢查點 (gradient checkpointing) |
| 映像編譯失敗 | 固定相依套件版本，檢查 CUDA 相容性 |
| 逾時錯誤 | 增加 `timeout`，加入檢查點 (checkpointing) |

## 參考資料

- **[進階用法](references/advanced-usage_zh_TW.md)** - 多 GPU、分散式訓練、成本優化
- **[故障排除](references/troubleshooting_zh_TW.md)** - 常見問題與解決方案

## 資源

- **官方文件**: https://modal.com/docs
- **範例**: https://github.com/modal-labs/modal-examples
- **定價**: https://modal.com/pricing
- **Discord**: https://discord.gg/modal
