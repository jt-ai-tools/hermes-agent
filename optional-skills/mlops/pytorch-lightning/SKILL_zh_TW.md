---
name: pytorch-lightning
description: 高階 PyTorch 框架，具備 Trainer 類別、自動分佈式訓練 (DDP/FSDP/DeepSpeed)、回呼 (callbacks) 系統，並將樣板程式碼降至最低。同一套程式碼可從筆電擴展至超級電腦。當您想要擁有內建最佳實踐且乾淨的訓練迴圈時，請使用此框架。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [lightning, torch, transformers]
metadata:
  hermes:
    tags: [PyTorch Lightning, 訓練框架, 分佈式訓練, DDP, FSDP, DeepSpeed, 高階 API, 回呼, 最佳實踐, 可擴展]

---

# PyTorch Lightning - 高階訓練框架

## 快速入門

PyTorch Lightning 組織 PyTorch 程式碼以消除樣板程式碼，同時保持靈活性。

**安裝**:
```bash
pip install lightning
```

**將 PyTorch 轉換為 Lightning** (3 個步驟):

```python
import lightning as L
import torch
from torch import nn
from torch.utils.data import DataLoader, Dataset

# 步驟 1: 定義 LightningModule (組織您的 PyTorch 程式碼)
class LitModel(L.LightningModule):
    def __init__(self, hidden_size=128):
        super().__init__()
        self.model = nn.Sequential(
            nn.Linear(28 * 28, hidden_size),
            nn.ReLU(),
            nn.Linear(hidden_size, 10)
        )

    def training_step(self, batch, batch_idx):
        x, y = batch
        y_hat = self.model(x)
        loss = nn.functional.cross_entropy(y_hat, y)
        self.log('train_loss', loss)  # 自動記錄到 TensorBoard
        return loss

    def configure_optimizers(self):
        return torch.optim.Adam(self.parameters(), lr=1e-3)

# 步驟 2: 建立資料
train_loader = DataLoader(train_dataset, batch_size=32)

# 步驟 3: 使用 Trainer 進行訓練 (處理其餘所有事情！)
trainer = L.Trainer(max_epochs=10, accelerator='gpu', devices=2)
model = LitModel()
trainer.fit(model, train_loader)
```

**就這樣！** Trainer 處理：
- GPU/TPU/CPU 切換
- 分佈式訓練 (DDP, FSDP, DeepSpeed)
- 混合精度 (FP16, BF16)
- 梯度累加 (Gradient accumulation)
- 檢查點 (Checkpointing)
- 日誌記錄 (Logging)
- 進度條

## 常見工作流程

### 工作流程 1：從 PyTorch 到 Lightning

**原始 PyTorch 程式碼**:
```python
model = MyModel()
optimizer = torch.optim.Adam(model.parameters())
model.to('cuda')

for epoch in range(max_epochs):
    for batch in train_loader:
        batch = batch.to('cuda')
        optimizer.zero_grad()
        loss = model(batch)
        loss.backward()
        optimizer.step()
```

**Lightning 版本**:
```python
class LitModel(L.LightningModule):
    def __init__(self):
        super().__init__()
        self.model = MyModel()

    def training_step(self, batch, batch_idx):
        loss = self.model(batch)  # 不需要 .to('cuda')！
        return loss

    def configure_optimizers(self):
        return torch.optim.Adam(self.parameters())

# 訓練
trainer = L.Trainer(max_epochs=10, accelerator='gpu')
trainer.fit(LitModel(), train_loader)
```

**優點**: 40+ 行 → 15 行，無需管理裝置，自動分佈式。

### 工作流程 2：驗證與測試

```python
class LitModel(L.LightningModule):
    def __init__(self):
        super().__init__()
        self.model = MyModel()

    def training_step(self, batch, batch_idx):
        x, y = batch
        y_hat = self.model(x)
        loss = nn.functional.cross_entropy(y_hat, y)
        self.log('train_loss', loss)
        return loss

    def validation_step(self, batch, batch_idx):
        x, y = batch
        y_hat = self.model(x)
        val_loss = nn.functional.cross_entropy(y_hat, y)
        acc = (y_hat.argmax(dim=1) == y).float().mean()
        self.log('val_loss', val_loss)
        self.log('val_acc', acc)

    def test_step(self, batch, batch_idx):
        x, y = batch
        y_hat = self.model(x)
        test_loss = nn.functional.cross_entropy(y_hat, y)
        self.log('test_loss', test_loss)

    def configure_optimizers(self):
        return torch.optim.Adam(self.parameters(), lr=1e-3)

# 帶驗證的訓練
trainer = L.Trainer(max_epochs=10)
trainer.fit(model, train_loader, val_loader)

# 測試
trainer.test(model, test_loader)
```

**自動化功能**:
- 預設每個 epoch 執行一次驗證
- 指標記錄到 TensorBoard
- 根據 val_loss 自動保存最佳模型檢查點

### 工作流程 3：分佈式訓練 (DDP)

```python
# 程式碼與單 GPU 相同！
model = LitModel()

# 使用 DDP 在 8 個 GPU 上訓練 (自動！)
trainer = L.Trainer(
    accelerator='gpu',
    devices=8,
    strategy='ddp'  # 或 'fsdp', 'deepspeed'
)

trainer.fit(model, train_loader)
```

**啟動**:
```bash
# 單一指令，Lightning 處理其餘部分
python train.py
```

**無需更改**:
- 自動資料分佈
- 梯度同步
- 多節點支援 (只需設定 `num_nodes=2`)

### 工作流程 4：用於監控的回呼 (Callbacks)

```python
from lightning.pytorch.callbacks import ModelCheckpoint, EarlyStopping, LearningRateMonitor

# 建立回呼
checkpoint = ModelCheckpoint(
    monitor='val_loss',
    mode='min',
    save_top_k=3,
    filename='model-{epoch:02d}-{val_loss:.2f}'
)

early_stop = EarlyStopping(
    monitor='val_loss',
    patience=5,
    mode='min'
)

lr_monitor = LearningRateMonitor(logging_interval='epoch')

# 新增至 Trainer
trainer = L.Trainer(
    max_epochs=100,
    callbacks=[checkpoint, early_stop, lr_monitor]
)

trainer.fit(model, train_loader, val_loader)
```

**結果**:
- 自動保存前 3 名的最佳模型
- 如果 5 個 epoch 沒有改善則提早停止
- 將學習率記錄到 TensorBoard

### 工作流程 5：學習率排程 (Learning rate scheduling)

```python
class LitModel(L.LightningModule):
    # ... (training_step 等)

    def configure_optimizers(self):
        optimizer = torch.optim.Adam(self.parameters(), lr=1e-3)

        # 餘弦退火 (Cosine annealing)
        scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
            optimizer,
            T_max=100,
            eta_min=1e-5
        )

        return {
            'optimizer': optimizer,
            'lr_scheduler': {
                'scheduler': scheduler,
                'interval': 'epoch',  # 每個 epoch 更新
                'frequency': 1
            }
        }

# 學習率自動記錄！
trainer = L.Trainer(max_epochs=100)
trainer.fit(model, train_loader)
```

## 何時使用 vs 替代方案

**在以下情況使用 PyTorch Lightning**:
- 想要乾淨、有組織的程式碼
- 需要生產就緒的訓練迴圈
- 在單 GPU、多 GPU、TPU 之間切換
- 想要內建的回呼和日誌記錄
- 團隊協作 (標準化結構)

**主要優勢**:
- **有組織**: 將研究程式碼與工程程式碼分離
- **自動化**: 1 行即可使用 DDP, FSDP, DeepSpeed
- **回呼**: 模組化訓練擴展
- **可重現**: 較少的樣板程式碼 = 較少的錯誤
- **經過測試**: 每月 100 萬+ 下載量，經得起實戰考驗

**改用替代方案**:
- **Accelerate**: 對現有程式碼更改最少，更具靈活性
- **Ray Train**: 多節點編排、超參數調優
- **Raw PyTorch**: 最大限度的控制，用於學習目的
- **Keras**: TensorFlow 生態系統

## 常見問題

**問題：損失值沒有下降**

檢查資料和模型設定：
```python
# 新增至 training_step
def training_step(self, batch, batch_idx):
    if batch_idx == 0:
        print(f"Batch shape: {batch[0].shape}")
        print(f"Labels: {batch[1]}")
    loss = ...
    return loss
```

**問題：記憶體溢出 (OOM)**

減少批次大小或使用梯度累加：
```python
trainer = L.Trainer(
    accumulate_grad_batches=4,  # 有效批次 = batch_size × 4
    precision='bf16'  # 或 'fp16', 減少 50% 記憶體使用
)
```

**問題：驗證未執行**

確保您傳入了 val_loader：
```python
# 錯誤
trainer.fit(model, train_loader)

# 正確
trainer.fit(model, train_loader, val_loader)
```

**問題：DDP 意外啟動多個進程**

Lightning 會自動偵測 GPU。請明確設定裝置：
```python
# 先在 CPU 上測試
trainer = L.Trainer(accelerator='cpu', devices=1)

# 然後在 GPU 上測試
trainer = L.Trainer(accelerator='gpu', devices=1)
```

## 進階主題

**回呼 (Callbacks)**: 參閱 [references/callbacks.md](references/callbacks.md) 以了解 EarlyStopping、ModelCheckpoint、自訂回呼和回呼掛鉤 (hooks)。

**分佈式策略**: 參閱 [references/distributed.md](references/distributed.md) 以了解 DDP、FSDP、DeepSpeed ZeRO 整合、多節點設定。

**超參數調優**: 參閱 [references/hyperparameter-tuning.md](references/hyperparameter-tuning.md) 以了解與 Optuna、Ray Tune 和 WandB sweeps 的整合。

## 硬體需求

- **CPU**: 支援 (適合除錯)
- **單 GPU**: 支援
- **多 GPU**: DDP (預設), FSDP, 或 DeepSpeed
- **多節點**: DDP, FSDP, DeepSpeed
- **TPU**: 支援 (8 核心)
- **Apple MPS**: 支援

**精度選項**:
- FP32 (預設)
- FP16 (V100, 較舊的 GPU)
- BF16 (A100/H100, 推薦)
- FP8 (H100)

## 資源

- 文件: https://lightning.ai/docs/pytorch/stable/
- GitHub: https://github.com/Lightning-AI/pytorch-lightning ⭐ 29,000+
- 版本: 2.5.5+
- 範例: https://github.com/Lightning-AI/pytorch-lightning/tree/master/examples
- Discord: https://discord.gg/lightning-ai
- 使用者: Kaggle 獲勝者、研究實驗室、生產團隊
