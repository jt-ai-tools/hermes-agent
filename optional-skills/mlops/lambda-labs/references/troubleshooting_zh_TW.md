# Lambda Labs 疑難排解指南

## 執行體 (Instance) 啟動問題

### 無可用執行體

**錯誤**："No capacity available"（無可用容量）或未列出執行體類型

**解決方案**：
```bash
# 透過 API 檢查可用性
curl -u $LAMBDA_API_KEY: \
  https://cloud.lambdalabs.com/api/v1/instance-types | jq '.data | to_entries[] | select(.value.regions_with_capacity_available | length > 0) | .key'

# 嘗試不同的區域
# 美國區域：us-west-1, us-east-1, us-south-1
# 國際區域：eu-west-1, asia-northeast-1 等

# 嘗試替代的 GPU 類型
# H100 不可用？嘗試 A100
# A100 不可用？嘗試 A10 或 A6000
```

### 執行體卡在啟動中

**問題**：執行體顯示 "booting"（開機中）超過 20 分鐘

**解決方案**：
```bash
# 單 GPU：應在 3-5 分鐘內就緒
# 多 GPU (8x)：可能需要 10-15 分鐘

# 如果卡住更久：
# 1. 終止 (Terminate) 該執行體
# 2. 嘗試不同的區域
# 3. 嘗試不同的執行體類型
# 4. 如果問題持續，請聯絡 Lambda 支援團隊
```

### API 身份驗證失敗

**錯誤**：`401 Unauthorized` 或 `403 Forbidden`

**解決方案**：
```bash
# 驗證 API 金鑰格式（應以特定前綴開頭）
echo $LAMBDA_API_KEY

# 測試 API 金鑰
curl -u $LAMBDA_API_KEY: \
  https://cloud.lambdalabs.com/api/v1/instance-types

# 如果需要，從 Lambda 控制台生成新的 API 金鑰
# Settings > API keys > Generate
```

### 達到配額限制 (Quota limits)

**錯誤**："Instance limit reached"（已達執行體限制）或 "Quota exceeded"（超出配額）

**解決方案**：
- 在控制台中檢查目前正在執行的執行體
- 終止不使用的執行體
- 聯絡 Lambda 支援團隊申請增加配額
- 針對大規模需求，請使用 1-Click Clusters

## SSH 連線問題

### 連線被拒絕

**錯誤**：`ssh: connect to host <IP> port 22: Connection refused`

**解決方案**：
```bash
# 等待執行體完全初始化
# 單 GPU：3-5 分鐘
# 多 GPU：10-15 分鐘

# 在控制台中檢查執行體狀態（應為 "active"）

# 驗證正確的 IP 位址
curl -u $LAMBDA_API_KEY: \
  https://cloud.lambdalabs.com/api/v1/instances | jq '.data[].ip'
```

### 權限被拒絕 (Permission denied)

**錯誤**：`Permission denied (publickey)`

**解決方案**：
```bash
# 驗證 SSH 金鑰是否匹配
ssh -v -i ~/.ssh/lambda_key ubuntu@<IP>

# 檢查金鑰權限
chmod 600 ~/.ssh/lambda_key
chmod 644 ~/.ssh/lambda_key.pub

# 驗證在啟動前已將金鑰加入 Lambda 控制台
# 金鑰必須在啟動執行體之前加入

# 檢查執行體上的 authorized_keys（如果您有其他進入方式）
cat ~/.ssh/authorized_keys
```

### 主機金鑰驗證失敗

**錯誤**：`WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`

**解決方案**：
```bash
# 當 IP 被不同的執行體重複使用時會發生此情況
# 移除舊的金鑰
ssh-keygen -R <IP>

# 然後重新連線
ssh ubuntu@<IP>
```

### SSH 連線超時

**錯誤**：`ssh: connect to host <IP> port 22: Operation timed out`

**解決方案**：
```bash
# 檢查執行體是否處於 "active" 狀態

# 驗證防火牆是否允許 SSH (port 22)
# Lambda 控制台 > Firewall

# 檢查您的本地網路是否允許出站 SSH

# 嘗試從不同的網路/VPN 連線
```

## GPU 問題

### 未偵測到 GPU

**錯誤**：`nvidia-smi: command not found` 或未顯示 GPU

**解決方案**：
```bash
# 重啟執行體
sudo reboot

# 重新安裝 NVIDIA 驅動程式（如果需要）
wget -nv -O- https://lambdalabs.com/install-lambda-stack.sh | sh -
sudo reboot

# 檢查驅動程式狀態
nvidia-smi
lsmod | grep nvidia
```

### CUDA 記憶體不足 (Out of Memory)

**錯誤**：`torch.cuda.OutOfMemoryError: CUDA out of memory`

**解決方案**：
```python
# 檢查 GPU 記憶體
import torch
print(torch.cuda.get_device_properties(0).total_memory / 1e9, "GB")

# 清除快取
torch.cuda.empty_cache()

# 減少批次大小 (Batch size)
batch_size = batch_size // 2

# 啟用梯度檢查點 (Gradient checkpointing)
model.gradient_checkpointing_enable()

# 使用混合精度 (Mixed precision)
from torch.cuda.amp import autocast
with autocast():
    outputs = model(**inputs)

# 使用更大的 GPU 執行體
# A100-40GB → A100-80GB → H100
```

### CUDA 版本不匹配

**錯誤**：`CUDA driver version is insufficient for CUDA runtime version`

**解決方案**：
```bash
# 檢查版本
nvidia-smi  # 顯示驅動程式 CUDA 版本
nvcc --version  # 顯示工具箱版本

# Lambda Stack 應具有相容的版本
# 如果不匹配，請重新安裝 Lambda Stack
wget -nv -O- https://lambdalabs.com/install-lambda-stack.sh | sh -
sudo reboot

# 或者安裝特定版本的 PyTorch
pip install torch==2.1.0+cu121 -f https://download.pytorch.org/whl/torch_stable.html
```

### 多 GPU 無法運作

**錯誤**：僅使用了一個 GPU

**解決方案**：
```python
# 檢查所有 GPU 是否可見
import torch
print(f"可用的 GPU 數量：{torch.cuda.device_count()}")

# 驗證 CUDA_VISIBLE_DEVICES 未被限制性地設置
import os
print(os.environ.get("CUDA_VISIBLE_DEVICES", "not set"))

# 使用 DataParallel 或 DistributedDataParallel
model = torch.nn.DataParallel(model)
# 或
model = torch.nn.parallel.DistributedDataParallel(model)
```

## 檔案系統問題

### 檔案系統未掛載

**錯誤**：`/lambda/nfs/<name>` 不存在

**解決方案**：
```bash
# 檔案系統必須在啟動時附加
# 無法附加到正在執行的執行體

# 驗證在啟動期間已選取檔案系統

# 檢查掛載點
df -h | grep lambda

# 如果缺失，請終止並重新啟動含檔案系統的執行體
```

### 檔案系統效能緩慢

**問題**：讀取/寫入檔案系統的速度很慢

**解決方案**：
```bash
# 使用本地 SSD 存儲臨時/中間檔案
# /home/ubuntu 擁有快速的 NVMe 存儲

# 將頻繁存取的資料複製到本地存儲
cp -r /lambda/nfs/storage/dataset /home/ubuntu/dataset

# 僅將檔案系統用於檢查點 (Checkpoints) 和最終輸出

# 檢查網路頻寬
iperf3 -c <filesystem_server>
```

### 終止後資料遺失

**問題**：執行體終止後檔案消失

**解決方案**：
```bash
# 根磁碟區 (/home/ubuntu) 是 臨時性的 (EPHEMERAL)
# 該處的資料在終止時會遺失

# 請務必使用檔案系統來存儲持久性資料
/lambda/nfs/<filesystem_name>/

# 在終止前同步重要的本地檔案
rsync -av /home/ubuntu/outputs/ /lambda/nfs/storage/outputs/
```

### 檔案系統已滿

**錯誤**：`No space left on device`

**解決方案**：
```bash
# 檢查檔案系統使用情況
df -h /lambda/nfs/storage

# 尋找大型檔案
du -sh /lambda/nfs/storage/* | sort -h

# 清理舊的檢查點
find /lambda/nfs/storage/checkpoints -mtime +7 -delete

# 在 Lambda 控制台增加檔案系統大小
# （可能需要提出支援申請）
```

## 網路問題

### 連接埠無法存取

**錯誤**：無法連線至服務 (TensorBoard, Jupyter 等)

**解決方案**：
```bash
# Lambda 預設：僅開放 port 22
# 在 Lambda 控制台配置防火牆

# 或者使用 SSH 隧道 (SSH tunneling)（推薦）
ssh -L 6006:localhost:6006 ubuntu@<IP>
# 透過 http://localhost:6006 存取

# 針對 Jupyter
ssh -L 8888:localhost:8888 ubuntu@<IP>
```

### 資料下載緩慢

**問題**：下載資料集的速度很慢

**解決方案**：
```bash
# 檢查可用頻寬
speedtest-cli

# 使用多執行緒下載
aria2c -x 16 <URL>

# 針對 HuggingFace 模型
export HF_HUB_ENABLE_HF_TRANSFER=1
pip install hf_transfer

# 針對 S3，使用並行傳輸
aws s3 sync s3://bucket/data /local/data --quiet
```

### 節點間通訊失敗

**錯誤**：分散式訓練無法在節點間連線

**解決方案**：
```bash
# 驗證節點是否在同一區域（必要條件）

# 檢查私有 IP 是否可以通訊
ping <other_node_private_ip>

# 驗證 NCCL 設置
export NCCL_DEBUG=INFO
export NCCL_IB_DISABLE=0  # 如果可用，啟用 InfiniBand

# 驗證防火牆是否允許分散式連接埠
# 需要：29500 (PyTorch) 或配置的 MASTER_PORT
```

## 軟體問題

### 套件安裝失敗

**錯誤**：`pip install` 錯誤

**解決方案**：
```bash
# 使用虛擬環境（不要修改系統 Python）
python -m venv ~/myenv
source ~/myenv/bin/activate
pip install <package>

# 針對 CUDA 套件，請匹配 CUDA 版本
pip install torch --index-url https://download.pytorch.org/whl/cu121

# 如果 pip 快取損壞，請清除它
pip cache purge
```

### Python 版本問題

**錯誤**：套件需要不同的 Python 版本

**解決方案**：
```bash
# 安裝替代的 Python（不要取代系統 Python）
sudo apt install python3.11 python3.11-venv python3.11-dev

# 使用特定的 Python 建立 venv
python3.11 -m venv ~/py311env
source ~/py311env/bin/activate
```

### ImportError 或 ModuleNotFoundError

**錯誤**：儘管已安裝，但找不到模組

**解決方案**：
```bash
# 驗證 Python 環境是否正確
which python
pip list | grep <module>

# 確保虛擬環境已啟動
source ~/myenv/bin/activate

# 在正確的環境中重新安裝
pip uninstall <package>
pip install <package>
```

## 訓練問題

### 訓練掛起 (Hangs)

**問題**：訓練停止進度，無輸出

**解決方案**：
```bash
# 檢查 GPU 利用率
watch -n 1 nvidia-smi

# 如果 GPU 為 0%，可能是資料載入瓶頸
# 增加 DataLoader 中的 num_workers

# 檢查分散式訓練中的死鎖
export NCCL_DEBUG=INFO

# 加入超時設置
dist.init_process_group(..., timeout=timedelta(minutes=30))
```

### 檢查點 (Checkpoint) 損壞

**錯誤**：`RuntimeError: storage has wrong size` 或類似錯誤

**解決方案**：
```python
# 使用安全儲存模式
checkpoint_path = "/lambda/nfs/storage/checkpoint.pt"
temp_path = checkpoint_path + ".tmp"

# 先儲存到臨時路徑
torch.save(state_dict, temp_path)
# 然後進行原子重命名
os.rename(temp_path, checkpoint_path)

# 針對載入損壞的檢查點
try:
    state = torch.load(checkpoint_path)
except:
    # 回退到上一個檢查點
    state = torch.load(checkpoint_path + ".backup")
```

### 記憶體洩漏 (Memory leak)

**問題**：記憶體使用量隨時間增長

**解決方案**：
```python
# 定期清除 CUDA 快取
torch.cuda.empty_cache()

# 紀錄時分離 (Detach) 張量
loss_value = loss.detach().cpu().item()

# 避免無意中累積梯度
optimizer.zero_grad(set_to_none=True)

# 正確使用梯度累積 (Gradient accumulation)
if (step + 1) % accumulation_steps == 0:
    optimizer.step()
    optimizer.zero_grad()
```

## 帳單問題

### 意外扣款

**問題**：帳單高於預期

**解決方案**：
```bash
# 檢查是否有忘記關閉的執行體
curl -u $LAMBDA_API_KEY: \
  https://cloud.lambdalabs.com/api/v1/instances | jq '.data[].id'

# 終止所有執行體
# Lambda 控制台 > Instances > Terminate all

# Lambda 按分鐘計費
# 已停止的執行體不收費（但沒有「停止」功能 - 只能終止）
```

### 執行體意外終止

**問題**：執行體在未手動終止的情況下消失

**可能原因**：
- 付款問題（信用卡被拒）
- 帳號停權
- 執行體健康檢查失敗

**解決方案**：
- 檢查電子郵件中的 Lambda 通知
- 在控制台中驗證付款方式
- 聯絡 Lambda 支援團隊
- 務必將檢查點存儲至檔案系統

## 常見錯誤訊息

| 錯誤 | 原因 | 解決方案 |
|-------|-------|----------|
| `No capacity available` | 區域/GPU 已售罄 | 嘗試不同區域或 GPU 類型 |
| `Permission denied (publickey)` | SSH 金鑰不匹配 | 重新加入金鑰，檢查權限 |
| `CUDA out of memory` | 模型太大 | 減少批次大小，使用更大的 GPU |
| `No space left on device` | 磁碟已滿 | 清理空間或使用檔案系統 |
| `Connection refused` | 執行體未就緒 | 等待 3-15 分鐘開機時間 |
| `Module not found` | Python 環境錯誤 | 啟動正確的虛擬環境 |

## 尋求協助

1. **說明文件**：https://docs.lambda.ai
2. **支援中心**：https://support.lambdalabs.com
3. **電子郵件**：support@lambdalabs.com
4. **狀態頁面**：檢查 Lambda status 頁面以瞭解服務中斷情況

### 應包含的資訊

聯絡支援團隊時，請提供：
- 執行體 ID (Instance ID)
- 區域 (Region)
- 執行體類型 (Instance type)
- 錯誤訊息（完整的 Traceback）
- 重現步驟
- 發生時間
