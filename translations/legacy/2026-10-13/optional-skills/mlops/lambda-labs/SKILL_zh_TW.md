---
name: lambda-labs-gpu-cloud
description: 用於機器學習訓練和推理的預留與按需 GPU 雲端實例。當您需要具備簡單 SSH 存取、持久化檔案系統或用於大規模訓練的高效能多節點叢集的專用 GPU 實例時使用。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [lambda-cloud-client>=1.0.0]
metadata:
  hermes:
    tags: [基礎架構, GPU 雲端, 訓練, 推理, Lambda Labs]

---

# Lambda Labs GPU Cloud

在 Lambda Labs GPU 雲端上執行機器學習工作負載的完整指南，包含按需 (on-demand) 實例與 1-Click 叢集。

## 何時使用 Lambda Labs

**在以下情況使用 Lambda Labs：**
- 需要具備完整 SSH 存取權限的專用 GPU 實例
- 執行長時間的訓練任務 (數小時至數天)
- 想要簡單的計費方式，且無流量流出 (egress) 費用
- 需要在不同階段間保留資料的持久化儲存
- 需要高效能的多節點叢集 (16-512 個 GPU)
- 想要預裝機器學習軟體棧 (Lambda Stack，包含 PyTorch, CUDA, NCCL)

**關鍵功能：**
- **多樣的 GPU 選擇**：B200, H100, GH200, A100, A10, A6000, V100
- **Lambda Stack**：預裝 PyTorch, TensorFlow, CUDA, cuDNN, NCCL
- **持久化檔案系統**：在實例重啟後仍可保留資料
- **1-Click 叢集**：具備 InfiniBand 的 16-512 個 GPU Slurm 叢集
- **簡單計費**：按分鐘計費，無流出費用
- **全球區域**：全球 12 個以上區域

**改用替代方案：**
- **Modal**：適用於無伺服器 (serverless)、自動擴展的工作負載
- **SkyPilot**：適用於多雲編排與成本優化
- **RunPod**：適用於更便宜的競價 (spot) 實例與無伺服器端點
- **Vast.ai**：價格最低的 GPU 租用市場

## 快速入門

### 帳號設定

1. 在 https://lambda.ai 建立帳號
2. 新增付款方式
3. 從儀表板產生 API 金鑰
4. 新增 SSH 金鑰 (在啟動實例前為必要步驟)

### 透過控制台啟動

1. 前往 https://cloud.lambda.ai/instances
2. 點擊 "Launch instance"
3. 選擇 GPU 類型與區域
4. 選擇 SSH 金鑰
5. (選填) 掛載檔案系統
6. 啟動並等待 3-15 分鐘

### 透過 SSH 連接

```bash
# 從控制台取得實例 IP
ssh ubuntu@<INSTANCE-IP>

# 或指定金鑰檔案
ssh -i ~/.ssh/lambda_key ubuntu@<INSTANCE-IP>
```

## GPU 實例

### 可用 GPU

| GPU | 顯示記憶體 | 價格/GPU/小時 | 最適合於 |
|-----|------|--------------|----------|
| B200 SXM6 | 180 GB | $4.99 | 最大模型、最快訓練 |
| H100 SXM | 80 GB | $2.99-3.29 | 大型模型訓練 |
| H100 PCIe | 80 GB | $2.49 | 具備成本效益的 H100 |
| GH200 | 96 GB | $1.49 | 單 GPU 大型模型 |
| A100 80GB | 80 GB | $1.79 | 生產級訓練 |
| A100 40GB | 40 GB | $1.29 | 標準訓練 |
| A10 | 24 GB | $0.75 | 推理、微調 |
| A6000 | 48 GB | $0.80 | 良好的顯示記憶體/價格比 |
| V100 | 16 GB | $0.55 | 低預算訓練 |

### 實例配置

```
8x GPU: 最適合分佈式訓練 (DDP, FSDP)
4x GPU: 大型模型、多 GPU 訓練
2x GPU: 中等工作負載
1x GPU: 微調、推理、開發
```

### 啟動時間

- 單 GPU：3-5 分鐘
- 多 GPU：10-15 分鐘

## Lambda Stack

所有實例均預裝了 Lambda Stack：

```bash
# 包含的軟體
- Ubuntu 22.04 LTS
- NVIDIA 驅動程式 (最新版)
- CUDA 12.x
- cuDNN 8.x
- NCCL (用於多 GPU)
- PyTorch (最新版)
- TensorFlow (最新版)
- JAX
- JupyterLab
```

### 驗證安裝

```bash
# 檢查 GPU
nvidia-smi

# 檢查 PyTorch
python -c "import torch; print(torch.cuda.is_available())"

# 檢查 CUDA 版本
nvcc --version
```

## Python API

### 安裝

```bash
pip install lambda-cloud-client
```

### 驗證身份

```python
import os
import lambda_cloud_client

# 使用 API 金鑰配置
configuration = lambda_cloud_client.Configuration(
    host="https://cloud.lambdalabs.com/api/v1",
    access_token=os.environ["LAMBDA_API_KEY"]
)
```

### 列出可用實例

```python
with lambda_cloud_client.ApiClient(configuration) as api_client:
    api = lambda_cloud_client.DefaultApi(api_client)

    # 取得可用實例類型
    types = api.instance_types()
    for name, info in types.data.items():
        print(f"{name}: {info.instance_type.description}")
```

### 啟動實例

```python
from lambda_cloud_client.models import LaunchInstanceRequest

request = LaunchInstanceRequest(
    region_name="us-west-1",
    instance_type_name="gpu_1x_h100_sxm5",
    ssh_key_names=["my-ssh-key"],
    file_system_names=["my-filesystem"],  # 選填
    name="training-job"
)

response = api.launch_instance(request)
instance_id = response.data.instance_ids[0]
print(f"Launched: {instance_id}")
```

### 列出正在執行的實例

```python
instances = api.list_instances()
for instance in instances.data:
    print(f"{instance.name}: {instance.ip} ({instance.status})")
```

### 關閉實例

```python
from lambda_cloud_client.models import TerminateInstanceRequest

request = TerminateInstanceRequest(
    instance_ids=[instance_id]
)
api.terminate_instance(request)
```

### SSH 金鑰管理

```python
from lambda_cloud_client.models import AddSshKeyRequest

# 新增 SSH 金鑰
request = AddSshKeyRequest(
    name="my-key",
    public_key="ssh-rsa AAAA..."
)
api.add_ssh_key(request)

# 列出金鑰
keys = api.list_ssh_keys()

# 刪除金鑰
api.delete_ssh_key(key_id)
```

## 透過 curl 使用 CLI

### 列出實例類型

```bash
curl -u $LAMBDA_API_KEY: \
  https://cloud.lambdalabs.com/api/v1/instance-types | jq
```

### 啟動實例

```bash
curl -u $LAMBDA_API_KEY: \
  -X POST https://cloud.lambdalabs.com/api/v1/instance-operations/launch \
  -H "Content-Type: application/json" \
  -d '{
    "region_name": "us-west-1",
    "instance_type_name": "gpu_1x_h100_sxm5",
    "ssh_key_names": ["my-key"]
  }' | jq
```

### 關閉實例

```bash
curl -u $LAMBDA_API_KEY: \
  -X POST https://cloud.lambdalabs.com/api/v1/instance-operations/terminate \
  -H "Content-Type: application/json" \
  -d '{"instance_ids": ["<INSTANCE-ID>"]}' | jq
```

## 持久化儲存

### 檔案系統

檔案系統會在實例重啟後保留資料：

```bash
# 掛載位置
/lambda/nfs/<FILESYSTEM_NAME>

# 範例：儲存檢查點
python train.py --checkpoint-dir /lambda/nfs/my-storage/checkpoints
```

### 建立檔案系統

1. 前往 Lambda 控制台的 Storage 頁面
2. 點擊 "Create filesystem"
3. 選擇區域 (必須與實例區域相符)
4. 命名並建立

### 掛載至實例

檔案系統必須在實例啟動時掛載：
- 透過控制台：啟動時選擇檔案系統
- 透過 API：在啟動請求中包含 `file_system_names`

### 最佳實踐

```bash
# 儲存在檔案系統中 (持久化)
/lambda/nfs/storage/
  ├── datasets/
  ├── checkpoints/
  ├── models/
  └── outputs/

# 本地 SSD (較快，但屬臨時性質)
/home/ubuntu/
  └── working/  # 暫存檔案
```

## SSH 配置

### 新增 SSH 金鑰

```bash
# 在本地產生金鑰
ssh-keygen -t ed25519 -f ~/.ssh/lambda_key

# 將公鑰新增至 Lambda 控制台
# 或透過 API 新增
```

### 多個金鑰

```bash
# 在實例上新增更多金鑰
echo 'ssh-rsa AAAA...' >> ~/.ssh/authorized_keys
```

### 從 GitHub 匯入

```bash
# 在實例上
ssh-import-id gh:username
```

### SSH 隧道 (Tunneling)

```bash
# 轉發 Jupyter
ssh -L 8888:localhost:8888 ubuntu@<IP>

# 轉發 TensorBoard
ssh -L 6006:localhost:6006 ubuntu@<IP>

# 同時轉發多個連接埠
ssh -L 8888:localhost:8888 -L 6006:localhost:6006 ubuntu@<IP>
```

## JupyterLab

### 從控制台啟動

1. 前往 Instances 頁面
2. 點擊 Cloud IDE 欄位中的 "Launch"
3. JupyterLab 會在瀏覽器中開啟

### 手動存取

```bash
# 在實例上啟動
jupyter lab --ip=0.0.0.0 --port=8888

# 從本地機器使用隧道存取
ssh -L 8888:localhost:8888 ubuntu@<IP>
# 開啟 http://localhost:8888
```

## 訓練工作流程

### 單 GPU 訓練

```bash
# SSH 連接至實例
ssh ubuntu@<IP>

# 複製儲存庫
git clone https://github.com/user/project
cd project

# 安裝依賴項
pip install -r requirements.txt

# 開始訓練
python train.py --epochs 100 --checkpoint-dir /lambda/nfs/storage/checkpoints
```

### 多 GPU 訓練 (單一節點)

```python
# train_ddp.py
import torch
import torch.distributed as dist
from torch.nn.parallel import DistributedDataParallel as DDP

def main():
    dist.init_process_group("nccl")
    rank = dist.get_rank()
    device = rank % torch.cuda.device_count()

    model = MyModel().to(device)
    model = DDP(model, device_ids=[device])

    # 訓練迴圈...

if __name__ == "__main__":
    main()
```

```bash
# 使用 torchrun 啟動 (8 個 GPU)
torchrun --nproc_per_node=8 train_ddp.py
```

### 儲存檢查點至檔案系統

```python
import os

checkpoint_dir = "/lambda/nfs/my-storage/checkpoints"
os.makedirs(checkpoint_dir, exist_ok=True)

# 儲存檢查點
torch.save({
    'epoch': epoch,
    'model_state_dict': model.state_dict(),
    'optimizer_state_dict': optimizer.state_dict(),
    'loss': loss,
}, f"{checkpoint_dir}/checkpoint_{epoch}.pt")
```

## 1-Click 叢集

### 概覽

具備以下特點的高效能 Slurm 叢集：
- 16-512 個 NVIDIA H100 或 B200 GPU
- NVIDIA Quantum-2 400 Gb/s InfiniBand
- GPUDirect RDMA 頻寬達 3200 Gb/s
- 預裝分佈式機器學習軟體棧

### 包含的軟體

- Ubuntu 22.04 LTS + Lambda Stack
- NCCL, Open MPI
- 具備 DDP 和 FSDP 的 PyTorch
- TensorFlow
- OFED 驅動程式

### 儲存

- 每部計算節點具備 24 TB NVMe (臨時性)
- Lambda 檔案系統用於持久化資料

### 多節點訓練

```bash
# 在 Slurm 叢集上
srun --nodes=4 --ntasks-per-node=8 --gpus-per-node=8 \
  torchrun --nnodes=4 --nproc_per_node=8 \
  --rdzv_backend=c10d --rdzv_endpoint=$MASTER_ADDR:29500 \
  train.py
```

## 網路

### 頻寬

- 實例間 (同一區域)：最高達 200 Gbps
- 網際網路流出：最高 20 Gbps

### 防火牆

- 預設：僅開啟連接埠 22 (SSH)
- 在 Lambda 控制台中配置其他連接埠
- 預設允許 ICMP 流量

### 私有 IP

```bash
# 尋找私有 IP
ip addr show | grep 'inet '
```

## 常見工作流程

### 工作流程 1：微調 LLM

```bash
# 1. 啟動具備檔案系統的 8x H100 實例

# 2. 透過 SSH 連接並設定
ssh ubuntu@<IP>
pip install transformers accelerate peft

# 3. 下載模型至檔案系統
python -c "
from transformers import AutoModelForCausalLM
model = AutoModelForCausalLM.from_pretrained('meta-llama/Llama-2-7b-hf')
model.save_pretrained('/lambda/nfs/storage/models/llama-2-7b')
"

# 4. 進行微調，並將檢查點儲存至檔案系統
accelerate launch --num_processes 8 train.py \
  --model_path /lambda/nfs/storage/models/llama-2-7b \
  --output_dir /lambda/nfs/storage/outputs \
  --checkpoint_dir /lambda/nfs/storage/checkpoints
```

### 工作流程 2：批次推理 (Batch inference)

```bash
# 1. 啟動 A10 實例 (對推理具備成本效益)

# 2. 執行推理
python inference.py \
  --model /lambda/nfs/storage/models/fine-tuned \
  --input /lambda/nfs/storage/data/inputs.jsonl \
  --output /lambda/nfs/storage/data/outputs.jsonl
```

## 成本優化

### 選擇正確的 GPU

| 任務 | 推薦的 GPU |
|------|-----------------|
| LLM 微調 (7B) | A100 40GB |
| LLM 微調 (70B) | 8x H100 |
| 推理 | A10, A6000 |
| 開發 | V100, A10 |
| 最大限度效能 | B200 |

### 降低成本

1. **使用檔案系統**：避免重複下載資料
2. **頻繁儲存檢查點**：恢復中斷的訓練
3. **規模適中**：不要配置過剩的 GPU
4. **關閉閒置實例**：系統不會自動停止，請手動關閉

### 監控使用情況

- 儀表板顯示即時的 GPU 利用率
- 提供可用於程式化監控的 API

## 常見問題

| 問題 | 解決方案 |
|-------|----------|
| 實例無法啟動 | 檢查區域可用性，嘗試不同的 GPU |
| SSH 連線被拒絕 | 等待實例初始化 (3-15 分鐘) |
| 關閉後資料遺失 | 使用持久化檔案系統 |
| 資料傳輸緩慢 | 使用同一區域的檔案系統 |
| 偵測不到 GPU | 重啟實例，檢查驅動程式 |

## 參考資料

- **[進階用法](references/advanced-usage.md)** - 多節點訓練、API 自動化
- **[故障排除](references/troubleshooting.md)** - 常見問題與解決方案

## 資源

- **文件**：https://docs.lambda.ai
- **控制台**：https://cloud.lambda.ai
- **定價**：https://lambda.ai/instances
- **支援**：https://support.lambdalabs.com
- **部落格**：https://lambda.ai/blog
