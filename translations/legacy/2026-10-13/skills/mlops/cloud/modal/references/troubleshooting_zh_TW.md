# Modal 故障排除指南

## 安裝問題

### 身分驗證失敗

**錯誤**: `modal setup` 未完成或權杖 (token) 無效

**解決方案**:
```bash
# 重新驗證
modal token new

# 檢查目前的權杖
modal config show

# 透過環境變數設定權杖
export MODAL_TOKEN_ID=ak-...
export MODAL_TOKEN_SECRET=as-...
```

### 套件安裝問題

**錯誤**: `pip install modal` 失敗

**解決方案**:
```bash
# 升級 pip
pip install --upgrade pip

# 使用特定 Python 版本安裝
python3.11 -m pip install modal

# 從 wheel 安裝
pip install modal --prefer-binary
```

## 容器映像問題 (Container Image Issues)

### 映像建置失敗

**錯誤**: `ImageBuilderError: Failed to build image`

**解決方案**:
```python
# 固定套件版本以避免衝突
image = modal.Image.debian_slim().pip_install(
    "torch==2.1.0",
    "transformers==4.36.0",  # 固定版本
    "accelerate==0.25.0"
)

# 使用相容的 CUDA 版本
image = modal.Image.from_registry(
    "nvidia/cuda:12.1.0-cudnn8-runtime-ubuntu22.04",  # 符合 PyTorch CUDA 版本
    add_python="3.11"
)
```

### 相依性衝突

**錯誤**: `ERROR: Cannot install package due to conflicting dependencies`

**解決方案**:
```python
# 分層安裝相依套件
base = modal.Image.debian_slim().pip_install("torch")
ml = base.pip_install("transformers")  # 在 torch 之後安裝

# 使用 uv 以獲得更好的解析效果
image = modal.Image.debian_slim().uv_pip_install(
    "torch", "transformers"
)
```

### 大型映像建置逾時

**錯誤**: 映像建置超過時間限制

**解決方案**:
```python
# 分拆成多層（更好的快取效果）
base = modal.Image.debian_slim().pip_install("torch")  # 已快取
ml = base.pip_install("transformers", "datasets")      # 已快取
app = ml.copy_local_dir("./src", "/app")               # 程式碼變更時重新建構

# 在建置期間下載模型，而非執行期間
image = modal.Image.debian_slim().pip_install("transformers").run_commands(
    "python -c 'from transformers import AutoModel; AutoModel.from_pretrained(\"bert-base\")'"
)
```

## GPU 問題

### GPU 不可用

**錯誤**: `RuntimeError: CUDA not available`

**解決方案**:
```python
# 確保已指定 GPU
@app.function(gpu="T4")  # 必須指定 GPU
def my_function():
    import torch
    assert torch.cuda.is_available()

# 檢查映像中的 CUDA 相容性
image = modal.Image.from_registry(
    "nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04",
    add_python="3.11"
).pip_install(
    "torch",
    index_url="https://download.pytorch.org/whl/cu121"  # 符合 CUDA 版本
)
```

### GPU 記憶體不足 (OOM)

**錯誤**: `torch.cuda.OutOfMemoryError: CUDA out of memory`

**解決方案**:
```python
# 使用較大的 GPU
@app.function(gpu="A100-80GB")  # 更多 VRAM
def train():
    pass

# 啟用記憶體優化
@app.function(gpu="A100")
def memory_optimized():
    import torch
    torch.backends.cuda.enable_flash_sdp(True)

    # 啟用梯度檢查點 (gradient checkpointing)
    model.gradient_checkpointing_enable()

    # 混合精度 (Mixed precision)
    with torch.autocast(device_type="cuda", dtype=torch.float16):
        outputs = model(**inputs)
```

### 配置了錯誤的 GPU

**錯誤**: 獲得了與請求不同的 GPU

**解決方案**:
```python
# 使用嚴格的 GPU 選擇
@app.function(gpu="H100!")  # H100! 防止自動升級至 H200

# 指定確切的記憶體變體
@app.function(gpu="A100-80GB")  # 不僅僅是 "A100"

# 在執行期間檢查 GPU
@app.function(gpu="A100")
def check_gpu():
    import subprocess
    result = subprocess.run(["nvidia-smi"], capture_output=True, text=True)
    print(result.stdout)
```

## 冷啟動問題 (Cold Start Issues)

### 冷啟動緩慢

**問題**: 第一個請求花費太長時間

**解決方案**:
```python
# 保持容器熱啟動
@app.function(
    container_idle_timeout=600,  # 保持熱啟動 10 分鐘
    keep_warm=1                  # 始終保持 1 個容器就緒
)
def low_latency():
    pass

# 在容器啟動期間載入模型
@app.cls(gpu="A100")
class Model:
    @modal.enter()
    def load(self):
        # 這在容器啟動時執行一次，而非按每個請求執行
        self.model = load_heavy_model()

# 在磁碟區中快取模型
volume = modal.Volume.from_name("models", create_if_missing=True)

@app.function(volumes={"/cache": volume})
def cached_model():
    if os.path.exists("/cache/model"):
        model = load_from_disk("/cache/model")
    else:
        model = download_model()
        save_to_disk(model, "/cache/model")
        volume.commit()
```

### 容器不斷重啟

**問題**: 容器頻繁被終止並重啟

**解決方案**:
```python
# 增加記憶體
@app.function(memory=32768)  # 32GB RAM
def memory_heavy():
    pass

# 增加逾時時間
@app.function(timeout=3600)  # 1 小時
def long_running():
    pass

# 優雅地處理信號 (signals)
import signal

def handler(signum, frame):
    cleanup()
    exit(0)

signal.signal(signal.SIGTERM, handler)
```

## 磁碟區問題 (Volume Issues)

### 磁碟區變更未持久化

**錯誤**: 寫入磁碟區的資料消失了

**解決方案**:
```python
volume = modal.Volume.from_name("my-volume", create_if_missing=True)

@app.function(volumes={"/data": volume})
def write_data():
    with open("/data/file.txt", "w") as f:
        f.write("data")

    # 關鍵：提交變更！
    volume.commit()
```

### 磁碟區讀取顯示過時資料

**錯誤**: 從磁碟區讀取到舊資料

**解決方案**:
```python
@app.function(volumes={"/data": volume})
def read_data():
    # 重新載入以取得最新版本
    volume.reload()

    with open("/data/file.txt", "r") as f:
        return f.read()
```

### 磁碟區掛載失敗

**錯誤**: `VolumeError: Failed to mount volume`

**解決方案**:
```python
# 確保磁碟區存在
volume = modal.Volume.from_name("my-volume", create_if_missing=True)

# 使用絕對路徑
@app.function(volumes={"/data": volume})  # 不是 "./data"
def my_function():
    pass

# 在儀表板中檢查磁碟區
# modal volume list
```

## Web 端點問題

### 端點回傳 502

**錯誤**: 閘道逾時 (Gateway timeout) 或錯誤的閘道 (Bad gateway)

**解決方案**:
```python
# 增加逾時時間
@app.function(timeout=300)  # 5 分鐘
@modal.web_endpoint()
def slow_endpoint():
    pass

# 為長時間操作回傳串流回應
from fastapi.responses import StreamingResponse

@app.function()
@modal.asgi_app()
def streaming_app():
    async def generate():
        for i in range(100):
            yield f"data: {i}\n\n"
            await process_chunk(i)
    return StreamingResponse(generate(), media_type="text/event-stream")
```

### 端點無法存取

**錯誤**: 404 或無法連線至端點

**解決方案**:
```bash
# 檢查部署狀態
modal app list

# 重新部署
modal deploy my_app.py

# 檢查日誌
modal app logs my-app
```

### CORS 錯誤

**錯誤**: 跨來源請求被阻擋

**解決方案**:
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

web_app = FastAPI()
web_app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.function()
@modal.asgi_app()
def cors_enabled():
    return web_app
```

## 秘密金鑰 (Secret) 問題

### 找不到秘密金鑰

**錯誤**: `SecretNotFound: Secret 'my-secret' not found`

**解決方案**:
```bash
# 透過 CLI 建立 secret
modal secret create my-secret KEY=value

# 列出所有 secret
modal secret list

# 檢查 secret 名稱是否完全相符
```

### 無法存取秘密金鑰的值

**錯誤**: 環境變數為空

**解決方案**:
```python
# 確保已附加 secret
@app.function(secrets=[modal.Secret.from_name("my-secret")])
def use_secret():
    import os
    value = os.environ.get("KEY")  # 使用 get() 來處理缺失的情況
    if not value:
        raise ValueError("KEY not set in secret")
```

## 排程問題

### 排程作業未執行

**錯誤**: Cron 作業未執行

**解決方案**:
```python
# 驗證 cron 語法
@app.function(schedule=modal.Cron("0 0 * * *"))  # 每天午夜 UTC
def daily_job():
    pass

# 檢查時區 (Modal 使用 UTC)
# "0 8 * * *" = 8am UTC，而非當地時間

# 確保應用程式已部署
# modal deploy my_app.py
```

### 作業執行多次

**問題**: 排程作業執行次數超過預期

**解決方案**:
```python
# 實作冪等性 (Idempotency)
@app.function(schedule=modal.Cron("0 * * * *"))
def hourly_job():
    job_id = get_current_hour_id()
    if already_processed(job_id):
        return
    process()
    mark_processed(job_id)
```

## 偵錯提示

### 啟用偵錯日誌

```python
import logging
logging.basicConfig(level=logging.DEBUG)

@app.function()
def debug_function():
    logging.debug("Debug message")
    logging.info("Info message")
```

### 查看容器日誌

```bash
# 串流日誌
modal app logs my-app

# 查看特定函式
modal app logs my-app --function my_function

# 查看歷史日誌
modal app logs my-app --since 1h
```

### 本地測試

```python
# 在沒有 Modal 的情況下本地執行函式
if __name__ == "__main__":
    result = my_function.local()  # 在您的機器上執行
    print(result)
```

### 檢查容器

```python
@app.function(gpu="T4")
def debug_environment():
    import subprocess
    import sys

    # 系統資訊
    print(f"Python: {sys.version}")
    print(subprocess.run(["nvidia-smi"], capture_output=True, text=True).stdout)
    print(subprocess.run(["pip", "list"], capture_output=True, text=True).stdout)

    # CUDA 資訊
    import torch
    print(f"CUDA available: {torch.cuda.is_available()}")
    print(f"CUDA version: {torch.version.cuda}")
    print(f"GPU: {torch.cuda.get_device_name(0)}")
```

## 常見錯誤訊息

| 錯誤 | 原因 | 解決方案 |
|-------|-------|----------|
| `FunctionTimeoutError` | 函式超過逾時時間 | 增加 `timeout` 參數 |
| `ContainerMemoryExceeded` | OOM 終止 | 增加 `memory` 參數 |
| `ImageBuilderError` | 建置失敗 | 檢查相依性，固定版本 |
| `ResourceExhausted` | 無可用 GPU | 使用 GPU 備援，稍後再試 |
| `AuthenticationError` | 權杖無效 | 執行 `modal token new` |
| `VolumeNotFound` | 磁碟區不存在 | 使用 `create_if_missing=True` |
| `SecretNotFound` | 秘密金鑰不存在 | 透過 CLI 建立 secret |

## 獲得幫助

1. **官方文件**: https://modal.com/docs
2. **範例**: https://github.com/modal-labs/modal-examples
3. **Discord**: https://discord.gg/modal
4. **狀態頁面**: https://status.modal.com

### 回報問題

請包含：
- Modal 用戶端版本：`modal --version`
- Python 版本：`python --version`
- 完整的錯誤回溯 (Traceback)
- 最小可重現程式碼
- 如果相關，請提供 GPU 類型
