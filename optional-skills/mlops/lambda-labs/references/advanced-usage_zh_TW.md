# Lambda Labs 進階使用指南

## 多節點分散式訓練

### 跨節點的 PyTorch DDP

```python
# train_multi_node.py
import os
import torch
import torch.distributed as dist
from torch.nn.parallel import DistributedDataParallel as DDP

def setup_distributed():
    # 由啟動器設置的環境變數
    rank = int(os.environ["RANK"])
    world_size = int(os.environ["WORLD_SIZE"])
    local_rank = int(os.environ["LOCAL_RANK"])

    dist.init_process_group(
        backend="nccl",
        rank=rank,
        world_size=world_size
    )

    torch.cuda.set_device(local_rank)
    return rank, world_size, local_rank

def main():
    rank, world_size, local_rank = setup_distributed()

    model = MyModel().cuda(local_rank)
    model = DDP(model, device_ids=[local_rank])

    # 梯度同步的訓練迴圈
    for epoch in range(num_epochs):
        train_one_epoch(model, dataloader)

        # 僅在 rank 0 上儲存檢查點
        if rank == 0:
            torch.save(model.module.state_dict(), f"checkpoint_{epoch}.pt")

    dist.destroy_process_group()

if __name__ == "__main__":
    main()
```

### 在多個執行體上啟動

```bash
# 在節點 0（主節點）上
export MASTER_ADDR=<NODE0_PRIVATE_IP>
export MASTER_PORT=29500

torchrun \
    --nnodes=2 \
    --nproc_per_node=8 \
    --node_rank=0 \
    --master_addr=$MASTER_ADDR \
    --master_port=$MASTER_PORT \
    train_multi_node.py

# 在節點 1 上
export MASTER_ADDR=<NODE0_PRIVATE_IP>
export MASTER_PORT=29500

torchrun \
    --nnodes=2 \
    --nproc_per_node=8 \
    --node_rank=1 \
    --master_addr=$MASTER_ADDR \
    --master_port=$MASTER_PORT \
    train_multi_node.py
```

### 針對大型模型的 FSDP

```python
from torch.distributed.fsdp import FullyShardedDataParallel as FSDP
from torch.distributed.fsdp.wrap import transformer_auto_wrap_policy
from transformers.models.llama.modeling_llama import LlamaDecoderLayer

# Transformer 模型的包裝策略 (Wrap policy)
auto_wrap_policy = functools.partial(
    transformer_auto_wrap_policy,
    transformer_layer_cls={LlamaDecoderLayer}
)

model = FSDP(
    model,
    auto_wrap_policy=auto_wrap_policy,
    mixed_precision=MixedPrecision(
        param_dtype=torch.bfloat16,
        reduce_dtype=torch.bfloat16,
        buffer_dtype=torch.bfloat16,
    ),
    device_id=local_rank,
)
```

### DeepSpeed ZeRO

```python
# ds_config.json
{
    "train_batch_size": 64,
    "gradient_accumulation_steps": 4,
    "fp16": {"enabled": true},
    "zero_optimization": {
        "stage": 3,
        "offload_optimizer": {"device": "cpu"},
        "offload_param": {"device": "cpu"}
    }
}
```

```bash
# 使用 DeepSpeed 啟動
deepspeed --num_nodes=2 \
    --num_gpus=8 \
    --hostfile=hostfile.txt \
    train.py --deepspeed ds_config.json
```

### 多節點的 Hostfile

```bash
# hostfile.txt
node0_ip slots=8
node1_ip slots=8
```

## API 自動化

### 自動啟動訓練任務

```python
import os
import time
import lambda_cloud_client
from lambda_cloud_client.models import LaunchInstanceRequest

class LambdaJobManager:
    def __init__(self, api_key: str):
        self.config = lambda_cloud_client.Configuration(
            host="https://cloud.lambdalabs.com/api/v1",
            access_token=api_key
        )

    def find_available_gpu(self, gpu_types: list[str], regions: list[str] = None):
        """尋找跨區域第一個可用的 GPU 類型。"""
        with lambda_cloud_client.ApiClient(self.config) as client:
            api = lambda_cloud_client.DefaultApi(client)
            types = api.instance_types()

            for gpu_type in gpu_types:
                if gpu_type in types.data:
                    info = types.data[gpu_type]
                    for region in info.regions_with_capacity_available:
                        if regions is None or region.name in regions:
                            return gpu_type, region.name

        return None, None

    def launch_and_wait(self, instance_type: str, region: str,
                        ssh_key: str, filesystem: str = None,
                        timeout: int = 900) -> dict:
        """啟動執行體並等待其就緒。"""
        with lambda_cloud_client.ApiClient(self.config) as client:
            api = lambda_cloud_client.DefaultApi(client)

            request = LaunchInstanceRequest(
                region_name=region,
                instance_type_name=instance_type,
                ssh_key_names=[ssh_key],
                file_system_names=[filesystem] if filesystem else [],
            )

            response = api.launch_instance(request)
            instance_id = response.data.instance_ids[0]

            # 輪詢直到就緒
            start = time.time()
            while time.time() - start < timeout:
                instance = api.get_instance(instance_id)
                if instance.data.status == "active":
                    return {
                        "id": instance_id,
                        "ip": instance.data.ip,
                        "status": "active"
                    }
                time.sleep(30)

            raise TimeoutError(f"執行體 {instance_id} 在 {timeout} 秒後仍未就緒")

    def terminate(self, instance_ids: list[str]):
        """終止執行體。"""
        from lambda_cloud_client.models import TerminateInstanceRequest

        with lambda_cloud_client.ApiClient(self.config) as client:
            api = lambda_cloud_client.DefaultApi(client)
            request = TerminateInstanceRequest(instance_ids=instance_ids)
            api.terminate_instance(request)


# 使用範例
manager = LambdaJobManager(os.environ["LAMBDA_API_KEY"])

# 尋找可用的 H100 或 A100
gpu_type, region = manager.find_available_gpu(
    ["gpu_8x_h100_sxm5", "gpu_8x_a100_80gb_sxm4"],
    regions=["us-west-1", "us-east-1"]
)

if gpu_type:
    instance = manager.launch_and_wait(
        gpu_type, region,
        ssh_key="my-key",
        filesystem="training-data"
    )
    print(f"就緒：ssh ubuntu@{instance['ip']}")
```

### 批次任務提交

```python
import subprocess
import paramiko

def run_remote_job(ip: str, ssh_key_path: str, commands: list[str]):
    """在遠端執行體上執行命令。"""
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(ip, username="ubuntu", key_filename=ssh_key_path)

    for cmd in commands:
        stdin, stdout, stderr = client.exec_command(cmd)
        print(stdout.read().decode())
        if stderr.read():
            print(f"錯誤：{stderr.read().decode()}")

    client.close()

# 提交訓練任務
commands = [
    "cd /lambda/nfs/storage/project",
    "git pull",
    "pip install -r requirements.txt",
    "nohup torchrun --nproc_per_node=8 train.py > train.log 2>&1 &"
]

run_remote_job(instance["ip"], "~/.ssh/lambda_key", commands)
```

### 監控訓練進度

```python
def monitor_job(ip: str, ssh_key_path: str, log_file: str = "train.log"):
    """從遠端執行體串流訓練紀錄。"""
    import time

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(ip, username="ubuntu", key_filename=ssh_key_path)

    # 追蹤 (Tail) 紀錄檔
    stdin, stdout, stderr = client.exec_command(f"tail -f {log_file}")

    try:
        for line in stdout:
            print(line.strip())
    except KeyboardInterrupt:
        pass
    finally:
        client.close()
```

## 1-Click Cluster 工作流程

### Slurm 任務提交

```bash
#!/bin/bash
#SBATCH --job-name=llm-training
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=8
#SBATCH --gpus-per-node=8
#SBATCH --time=24:00:00
#SBATCH --output=logs/%j.out
#SBATCH --error=logs/%j.err

# 設置分散式環境
export MASTER_ADDR=$(scontrol show hostnames $SLURM_JOB_NODELIST | head -n 1)
export MASTER_PORT=29500

# 啟動訓練
srun torchrun \
    --nnodes=$SLURM_NNODES \
    --nproc_per_node=$SLURM_GPUS_PER_NODE \
    --rdzv_backend=c10d \
    --rdzv_endpoint=$MASTER_ADDR:$MASTER_PORT \
    train.py \
    --config config.yaml
```

### 互動式叢集工作階段 (Session)

```bash
# 申請互動式工作階段
srun --nodes=1 --ntasks=1 --gpus=8 --time=4:00:00 --pty bash

# 現在處於擁有 8 個 GPU 的運算節點
nvidia-smi
python train.py
```

### 監控叢集任務

```bash
# 查看任務佇列
squeue

# 查看任務詳情
scontrol show job <JOB_ID>

# 取消任務
scancel <JOB_ID>

# 查看節點狀態
sinfo

# 查看整個叢集的 GPU 使用情況
srun --nodes=4 nvidia-smi --query-gpu=name,utilization.gpu --format=csv
```

## 進階檔案系統使用

### 資料暫存 (Data staging) 工作流程

```bash
# 將資料從 S3 同步到檔案系統（一次性）
aws s3 sync s3://my-bucket/dataset /lambda/nfs/storage/datasets/

# 或使用 rclone
rclone sync s3:my-bucket/dataset /lambda/nfs/storage/datasets/
```

### 跨執行體共享檔案系統

```python
# 執行體 1：寫入檢查點
checkpoint_path = "/lambda/nfs/shared/checkpoints/model_step_1000.pt"
torch.save(model.state_dict(), checkpoint_path)

# 執行體 2：讀取檢查點
model.load_state_dict(torch.load(checkpoint_path))
```

### 檔案系統最佳實踐

```bash
# 為機器學習工作流程組織目錄
/lambda/nfs/storage/
├── datasets/
│   ├── raw/           # 原始資料
│   └── processed/     # 預處理後的資料
├── models/
│   ├── pretrained/    # 基礎模型
│   └── fine-tuned/    # 您訓練好的模型
├── checkpoints/
│   └── experiment_1/  # 每個實驗的檢查點
├── logs/
│   └── tensorboard/   # 訓練紀錄
└── outputs/
    └── inference/     # 推論結果
```

## 環境管理

### 自定義 Python 環境

```bash
# 不要修改系統 Python，請建立 venv
python -m venv ~/myenv
source ~/myenv/bin/activate

# 安裝套件
pip install torch transformers accelerate

# 複製到檔案系統以便重複使用
cp -r ~/myenv /lambda/nfs/storage/envs/myenv
```

### Conda 環境

```bash
# 安裝 miniconda（如果不存在）
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p ~/miniconda3

# 建立環境
~/miniconda3/bin/conda create -n ml python=3.10 pytorch pytorch-cuda=12.1 -c pytorch -c nvidia -y

# 啟動
source ~/miniconda3/bin/activate ml
```

### Docker 容器

```bash
# 拉取並執行 NVIDIA 容器
docker run --gpus all -it --rm \
    -v /lambda/nfs/storage:/data \
    nvcr.io/nvidia/pytorch:24.01-py3

# 在容器中執行訓練
docker run --gpus all -d \
    -v /lambda/nfs/storage:/data \
    -v $(pwd):/workspace \
    nvcr.io/nvidia/pytorch:24.01-py3 \
    python /workspace/train.py
```

## 監控與觀測性 (Observability)

### GPU 監控

```bash
# 即時 GPU 統計數據
watch -n 1 nvidia-smi

# 隨時間變化的 GPU 利用率
nvidia-smi dmon -s u -d 1

# 詳細的 GPU 資訊
nvidia-smi -q
```

### 系統監控

```bash
# CPU 和記憶體
htop

# 磁碟 I/O
iostat -x 1

# 網路
iftop

# 所有資源
glances
```

### TensorBoard 整合

```bash
# 啟動 TensorBoard
tensorboard --logdir /lambda/nfs/storage/logs --port 6006 --bind_all

# 從本地機器建立 SSH 隧道
ssh -L 6006:localhost:6006 ubuntu@<IP>

# 透過 http://localhost:6006 存取
```

### Weights & Biases 整合

```python
import wandb

# 使用 API 金鑰登入
wandb.login(key=os.environ["WANDB_API_KEY"])

# 開始運行 (Run)
wandb.init(
    project="lambda-training",
    config={"learning_rate": 1e-4, "epochs": 100}
)

# 紀錄指標
wandb.log({"loss": loss, "accuracy": acc})

# 將構件 (Artifacts) 儲存至檔案系統 + W&B
wandb.save("/lambda/nfs/storage/checkpoints/best_model.pt")
```

## 成本優化策略

### 針對中斷恢復的檢查點機制

```python
import os

def save_checkpoint(model, optimizer, epoch, loss, path):
    torch.save({
        'epoch': epoch,
        'model_state_dict': model.state_dict(),
        'optimizer_state_dict': optimizer.state_dict(),
        'loss': loss,
    }, path)

def load_checkpoint(path, model, optimizer):
    if os.path.exists(path):
        checkpoint = torch.load(path)
        model.load_state_dict(checkpoint['model_state_dict'])
        optimizer.load_state_dict(checkpoint['optimizer_state_dict'])
        return checkpoint['epoch'], checkpoint['loss']
    return 0, float('inf')

# 每隔 N 步儲存到檔案系統
checkpoint_path = "/lambda/nfs/storage/checkpoints/latest.pt"
if step % 1000 == 0:
    save_checkpoint(model, optimizer, epoch, loss, checkpoint_path)
```

### 依工作負載選取執行體

```python
def recommend_instance(model_params: int, batch_size: int, task: str) -> str:
    """根據工作負載推薦 Lambda 執行體。"""

    if task == "inference":
        if model_params < 7e9:
            return "gpu_1x_a10"  # $0.75/hr
        elif model_params < 13e9:
            return "gpu_1x_a6000"  # $0.80/hr
        else:
            return "gpu_1x_h100_pcie"  # $2.49/hr

    elif task == "fine-tuning":
        if model_params < 7e9:
            return "gpu_1x_a100"  # $1.29/hr
        elif model_params < 13e9:
            return "gpu_4x_a100"  # $5.16/hr
        else:
            return "gpu_8x_h100_sxm5"  # $23.92/hr

    elif task == "pretraining":
        return "gpu_8x_h100_sxm5"  # 最高效能

    return "gpu_1x_a100"  # 預設
```

### 自動終止閒置執行體

```python
import time
from datetime import datetime, timedelta

def auto_terminate_idle(api_key: str, idle_threshold_hours: float = 2):
    """終止閒置太久的執行體。"""
    manager = LambdaJobManager(api_key)

    with lambda_cloud_client.ApiClient(manager.config) as client:
        api = lambda_cloud_client.DefaultApi(client)
        instances = api.list_instances()

        for instance in instances.data:
            # 檢查執行體是否在無活動的情況下運行
            # （您需要另外追蹤此資訊）
            launch_time = instance.launched_at
            if datetime.now() - launch_time > timedelta(hours=idle_threshold_hours):
                print(f"正在終止閒置執行體：{instance.id}")
                manager.terminate([instance.id])
```

## 安全最佳實踐

### SSH 金鑰輪換 (Rotation)

```bash
# 生成新的金鑰對
ssh-keygen -t ed25519 -f ~/.ssh/lambda_key_new -C "lambda-$(date +%Y%m)"

# 透過 Lambda 控制台或 API 加入新金鑰
# 更新正在執行的執行體上的 authorized_keys
ssh ubuntu@<IP> "echo '$(cat ~/.ssh/lambda_key_new.pub)' >> ~/.ssh/authorized_keys"

# 測試新金鑰
ssh -i ~/.ssh/lambda_key_new ubuntu@<IP>

# 從 Lambda 控制台移除舊金鑰
```

### 防火牆配置

```bash
# Lambda 控制台：僅開放必要的連接埠
# 建議：
# - 22 (SSH) - 始終需要
# - 6006 (TensorBoard) - 如果使用
# - 8888 (Jupyter) - 如果使用
# - 29500 (PyTorch distributed) - 僅限多節點
```

### 機密資訊管理

```bash
# 不要在程式碼中硬編碼 API 金鑰
# 使用環境變數
export HF_TOKEN="hf_..."
export WANDB_API_KEY="..."

# 或使用 .env 檔案（加入 .gitignore）
source .env

# 在執行體上，存儲於 ~/.bashrc
echo 'export HF_TOKEN="..."' >> ~/.bashrc
```
