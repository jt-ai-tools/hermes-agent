# PyTorch Lightning 回呼 (Callbacks)

## 概覽

回呼 (Callbacks) 可以在不修改 LightningModule 的情況下為訓練過程增添功能。它們用於捕捉 **非核心邏輯**，例如檢查點設置 (Checkpointing)、提前停止 (Early stopping) 和日誌記錄 (Logging)。

## 內建回呼 (Built-In Callbacks)

### 1. ModelCheckpoint

**在訓練期間儲存最佳模型**：

```python
from lightning.pytorch.callbacks import ModelCheckpoint

# 根據驗證損失 (Validation loss) 儲存表現最佳的前 3 個模型
checkpoint = ModelCheckpoint(
    dirpath='checkpoints/',
    filename='model-{epoch:02d}-{val_loss:.2f}',
    monitor='val_loss',
    mode='min',
    save_top_k=3,
    save_last=True,  # 同時儲存最後一輪 (Last epoch) 的模型
    verbose=True
)

trainer = L.Trainer(callbacks=[checkpoint])
trainer.fit(model, train_loader, val_loader)
```

**設定選項**：
```python
checkpoint = ModelCheckpoint(
    monitor='val_acc',        # 要監控的指標
    mode='max',               # 準確率設為 'max'，損失值設為 'min'
    save_top_k=5,             # 保留前 5 名的最佳模型
    save_last=True,           # 另外儲存最後一輪的模型
    every_n_epochs=1,         # 每 N 輪儲存一次
    save_on_train_epoch_end=False,  # 改為在驗證結束時儲存
    filename='best-{epoch}-{val_acc:.3f}',  # 命名規則
    auto_insert_metric_name=False  # 不要自動將指標名稱加入檔名
)
```

**載入檢查點**：
```python
# 載入最佳模型
best_model_path = checkpoint.best_model_path
model = LitModel.load_from_checkpoint(best_model_path)

# 恢復訓練
trainer = L.Trainer(callbacks=[checkpoint])
trainer.fit(model, train_loader, val_loader, ckpt_path='checkpoints/last.ckpt')
```

### 2. EarlyStopping

**當指標停止改善時提前停止訓練**：

```python
from lightning.pytorch.callbacks import EarlyStopping

early_stop = EarlyStopping(
    monitor='val_loss',
    patience=5,               # 等待 5 輪
    mode='min',
    min_delta=0.001,          # 認定為改善的最小變動量
    verbose=True,
    strict=True,              # 如果找不到監控指標則報錯
    check_on_train_epoch_end=False  # 在驗證結束時檢查
)

trainer = L.Trainer(callbacks=[early_stop])
trainer.fit(model, train_loader, val_loader)
# 如果連續 5 輪沒有改善，將自動停止訓練
```

**進階用法**：
```python
early_stop = EarlyStopping(
    monitor='val_loss',
    patience=10,
    min_delta=0.0,
    verbose=True,
    mode='min',
    stopping_threshold=0.1,   # 如果 val_loss < 0.1 則停止
    divergence_threshold=5.0, # 如果 val_loss > 5.0 則停止 (發散)
    check_finite=True         # 如果出現 NaN/Inf 則停止
)
```

### 3. LearningRateMonitor

**記錄學習率 (Learning rate)**：

```python
from lightning.pytorch.callbacks import LearningRateMonitor

lr_monitor = LearningRateMonitor(
    logging_interval='epoch',  # 或 'step' (步數)
    log_momentum=True          # 同時記錄動量 (Momentum)
)

trainer = L.Trainer(callbacks=[lr_monitor])
# 學習率會自動記錄到 TensorBoard/WandB
```

### 4. TQDMProgressBar

**自定義進度條**：

```python
from lightning.pytorch.callbacks import TQDMProgressBar

progress_bar = TQDMProgressBar(
    refresh_rate=10,  # 每 10 個批次 (Batches) 更新一次
    process_position=0
)

trainer = L.Trainer(callbacks=[progress_bar])
```

### 5. GradientAccumulationScheduler

**動態梯度累積**：

```python
from lightning.pytorch.callbacks import GradientAccumulationScheduler

# 隨著訓練進行累積更多梯度
accumulator = GradientAccumulationScheduler(
    scheduling={
        0: 8,   # 第 0-4 輪：累積 8 個批次
        5: 4,   # 第 5-9 輪：累積 4 個批次
        10: 2   # 第 10 輪之後：累積 2 個批次
    }
)

trainer = L.Trainer(callbacks=[accumulator])
```

### 6. StochasticWeightAveraging (SWA)

**對權重取平均以獲得更好的泛化能力**：

```python
from lightning.pytorch.callbacks import StochasticWeightAveraging

swa = StochasticWeightAveraging(
    swa_lrs=1e-2,  # SWA 學習率
    swa_epoch_start=0.8,  # 從訓練進度的 80% 開始
    annealing_epochs=10,  # 退火週期 (Annealing period)
    annealing_strategy='cos'  # 'cos' (餘弦) 或 'linear' (線性)
)

trainer = L.Trainer(callbacks=[swa])
```

## 自定義回呼 (Custom Callbacks)

### 基礎自定義回呼

```python
from lightning.pytorch.callbacks import Callback

class PrintingCallback(Callback):
    def on_train_start(self, trainer, pl_module):
        print("訓練開始！")

    def on_train_end(self, trainer, pl_module):
        print("訓練完成！")

    def on_epoch_end(self, trainer, pl_module):
        print(f"第 {trainer.current_epoch} 輪結束")

# 使用方式
trainer = L.Trainer(callbacks=[PrintingCallback()])
```

### 進階自定義回呼

```python
class MetricsCallback(Callback):
    """每 N 個批次記錄一次自定義指標。"""

    def __init__(self, log_every_n_batches=100):
        self.log_every_n_batches = log_every_n_batches
        self.metrics = []

    def on_train_batch_end(self, trainer, pl_module, outputs, batch, batch_idx):
        if batch_idx % self.log_every_n_batches == 0:
            # 計算自定義指標
            metric = self.compute_metric(outputs)
            self.metrics.append(metric)

            # 記錄到 Lightning
            pl_module.log('custom_metric', metric)

    def compute_metric(self, outputs):
        # 您的自定義邏輯
        return outputs['loss'].item()

    def state_dict(self):
        """將回呼狀態儲存在檢查點中。"""
        return {'metrics': self.metrics}

    def load_state_dict(self, state_dict):
        """從檢查點恢復回呼狀態。"""
        self.metrics = state_dict['metrics']
```

### 梯度監控回呼 (Gradient Monitoring Callback)

```python
class GradientMonitorCallback(Callback):
    """監控梯度範數 (Gradient norms)。"""

    def on_after_backward(self, trainer, pl_module):
        # 計算總梯度範數
        total_norm = 0.0
        for p in pl_module.parameters():
            if p.grad is not None:
                param_norm = p.grad.data.norm(2)
                total_norm += param_norm.item() ** 2
        total_norm = total_norm ** 0.5

        # 記錄
        pl_module.log('grad_norm', total_norm)

        # 如果梯度爆炸則發出警告
        if total_norm > 100:
            print(f"警告：偵測到較大的梯度範數：{total_norm:.2f}")
```

### 模型檢查回呼 (Model Inspection Callback)

```python
class ModelInspectionCallback(Callback):
    """在訓練期間檢查模型的活化值 (Activations)。"""

    def on_train_batch_start(self, trainer, pl_module, batch, batch_idx):
        if batch_idx == 0:  # 每一輪的第一個批次
            # 註冊勾子 (Hooks)
            self.activations = {}

            def get_activation(name):
                def hook(model, input, output):
                    self.activations[name] = output.detach()
                return hook

            # 附加到特定層
            pl_module.model.layer1.register_forward_hook(get_activation('layer1'))
            pl_module.model.layer2.register_forward_hook(get_activation('layer2'))

    def on_train_batch_end(self, trainer, pl_module, outputs, batch, batch_idx):
        if batch_idx == 0:
            # 記錄活化值的統計數據
            for name, activation in self.activations.items():
                mean = activation.mean().item()
                std = activation.std().item()
                pl_module.log(f'{name}_mean', mean)
                pl_module.log(f'{name}_std', std)
```

## 回呼勾子 (Callback Hooks)

**所有可用的勾子**：

```python
class MyCallback(Callback):
    # 設定與清理 (Setup/Teardown)
    def setup(self, trainer, pl_module, stage):
        """在 fit/test/predict 開始時調用。"""
        pass

    def teardown(self, trainer, pl_module, stage):
        """在 fit/test/predict 結束時調用。"""
        pass

    # 訓練階段 (Training)
    def on_train_start(self, trainer, pl_module):
        pass

    def on_train_epoch_start(self, trainer, pl_module):
        pass

    def on_train_batch_start(self, trainer, pl_module, batch, batch_idx):
        pass

    def on_train_batch_end(self, trainer, pl_module, outputs, batch, batch_idx):
        pass

    def on_train_epoch_end(self, trainer, pl_module):
        pass

    def on_train_end(self, trainer, pl_module):
        pass

    # 驗證階段 (Validation)
    def on_validation_start(self, trainer, pl_module):
        pass

    def on_validation_epoch_start(self, trainer, pl_module):
        pass

    def on_validation_batch_start(self, trainer, pl_module, batch, batch_idx, dataloader_idx):
        pass

    def on_validation_batch_end(self, trainer, pl_module, outputs, batch, batch_idx, dataloader_idx):
        pass

    def on_validation_epoch_end(self, trainer, pl_module):
        pass

    def on_validation_end(self, trainer, pl_module):
        pass

    # 測試階段 (Test，結構與驗證相同)
    def on_test_start(self, trainer, pl_module):
        pass
    # ... (test_epoch_start, test_batch_start, 等等)

    # 預測階段 (Predict)
    def on_predict_start(self, trainer, pl_module):
        pass
    # ... (predict_epoch_start, predict_batch_start, 等等)

    # 反向傳播 (Backward)
    def on_before_backward(self, trainer, pl_module, loss):
        pass

    def on_after_backward(self, trainer, pl_module):
        pass

    # 最佳化器 (Optimizer)
    def on_before_optimizer_step(self, trainer, pl_module, optimizer):
        pass

    # 檢查點設置 (Checkpointing)
    def on_save_checkpoint(self, trainer, pl_module, checkpoint):
        """將資料加入檢查點。"""
        pass

    def on_load_checkpoint(self, trainer, pl_module, checkpoint):
        """從檢查點恢復資料。"""
        pass
```

## 組合多個回呼

```python
from lightning.pytorch.callbacks import ModelCheckpoint, EarlyStopping, LearningRateMonitor

# 建立所有回呼
checkpoint = ModelCheckpoint(monitor='val_loss', mode='min', save_top_k=3)
early_stop = EarlyStopping(monitor='val_loss', patience=5)
lr_monitor = LearningRateMonitor(logging_interval='epoch')
custom_callback = MyCustomCallback()

# 全部加入到 Trainer
trainer = L.Trainer(
    callbacks=[checkpoint, early_stop, lr_monitor, custom_callback]
)

trainer.fit(model, train_loader, val_loader)
```

**執行順序**：回呼會依照它們被加入的順序執行。

## 最佳實踐

### 1. 保持回呼的獨立性

**錯誤示範** (依賴於其他回呼)：
```python
class BadCallback(Callback):
    def on_train_end(self, trainer, pl_module):
        # 假設 ModelCheckpoint 存在
        best_path = trainer.checkpoint_callback.best_model_path  # 脆弱的設計！
```

**正確示範** (自包含)：
```python
class GoodCallback(Callback):
    def on_train_end(self, trainer, pl_module):
        # 如果存在，則尋找檢查點回呼
        for callback in trainer.callbacks:
            if isinstance(callback, ModelCheckpoint):
                best_path = callback.best_model_path
                break
```

### 2. 使用狀態字典 (State Dict) 實現持久化

```python
class StatefulCallback(Callback):
    def __init__(self):
        self.counter = 0
        self.history = []

    def on_train_batch_end(self, trainer, pl_module, outputs, batch, batch_idx):
        self.counter += 1
        self.history.append(outputs['loss'].item())

    def state_dict(self):
        """儲存狀態。"""
        return {
            'counter': self.counter,
            'history': self.history
        }

    def load_state_dict(self, state_dict):
        """恢復狀態。"""
        self.counter = state_dict['counter']
        self.history = state_dict['history']
```

### 3. 處理分散式訓練

```python
class DistributedCallback(Callback):
    def on_train_batch_end(self, trainer, pl_module, outputs, batch, batch_idx):
        # 僅在主程序 (Main process) 執行
        if trainer.is_global_zero:
            print("這在分散式訓練中只會印出一次")

        # 在所有程序中執行
        loss = outputs['loss']
        # ... 在每個 GPU 上對損失進行某些處理
```

## 資源連結

- Callback API 指南：https://lightning.ai/docs/pytorch/stable/extensions/callbacks.html
- 內建回呼參考：https://lightning.ai/docs/pytorch/stable/api_references.html#callbacks
- 範例程式碼：https://github.com/Lightning-AI/pytorch-lightning/tree/master/examples/callbacks
