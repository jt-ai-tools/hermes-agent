# 使用 PyTorch Lightning 進行超參數微調 (Hyperparameter Tuning)

## 與微調框架整合

Lightning 與熱門的超參數微調函式庫無縫整合。

### 1. Ray Tune 整合

**安裝方式**：
```bash
pip install ray[tune]
pip install lightning
```

**基本 Ray Tune 範例**：

```python
import lightning as L
from ray import tune
from ray.tune.integration.pytorch_lightning import TuneReportCallback

class LitModel(L.LightningModule):
    def __init__(self, lr, batch_size):
        super().__init__()
        self.lr = lr
        self.batch_size = batch_size
        self.model = nn.Sequential(nn.Linear(10, 128), nn.ReLU(), nn.Linear(128, 1))

    def training_step(self, batch, batch_idx):
        loss = self.model(batch).mean()
        self.log('train_loss', loss)
        return loss

    def validation_step(self, batch, batch_idx):
        val_loss = self.model(batch).mean()
        self.log('val_loss', val_loss)

    def configure_optimizers(self):
        return torch.optim.Adam(self.parameters(), lr=self.lr)

def train_fn(config):
    """Ray Tune 的訓練函數。"""
    model = LitModel(lr=config["lr"], batch_size=config["batch_size"])

    # 加入回呼 (Callback) 以向 Tune 回報指標
    trainer = L.Trainer(
        max_epochs=10,
        callbacks=[TuneReportCallback({"loss": "val_loss"}, on="validation_end")]
    )

    trainer.fit(model, train_loader, val_loader)

# 定義搜尋空間 (Search space)
config = {
    "lr": tune.loguniform(1e-5, 1e-1),
    "batch_size": tune.choice([16, 32, 64, 128])
}

# 執行超參數搜尋
analysis = tune.run(
    train_fn,
    config=config,
    num_samples=20,  # 進行 20 次試驗 (Trials)
    resources_per_trial={"gpu": 1}
)

# 取得最佳超參數
best_config = analysis.get_best_config(metric="loss", mode="min")
print(f"最佳設定：{best_config}")
```

**進階用法：基於群體的訓練 (Population-Based Training, PBT)**：

```python
from ray.tune.schedulers import PopulationBasedTraining

# PBT 調度器
scheduler = PopulationBasedTraining(
    time_attr='training_iteration',
    metric='val_loss',
    mode='min',
    perturbation_interval=5,  # 每 5 輪擾動一次
    hyperparam_mutations={
        "lr": tune.loguniform(1e-5, 1e-1),
        "batch_size": [16, 32, 64, 128]
    }
)

analysis = tune.run(
    train_fn,
    config=config,
    num_samples=8,  # 群體大小
    scheduler=scheduler,
    resources_per_trial={"gpu": 1}
)
```

### 2. Optuna 整合

**安裝方式**：
```bash
pip install optuna
pip install optuna-integration
```

**Optuna 範例**：

```python
import optuna
from optuna.integration import PyTorchLightningPruningCallback

def objective(trial):
    # 建議超參數
    lr = trial.suggest_loguniform('lr', 1e-5, 1e-1)
    batch_size = trial.suggest_categorical('batch_size', [16, 32, 64, 128])
    n_layers = trial.suggest_int('n_layers', 1, 3)
    hidden_size = trial.suggest_int('hidden_size', 64, 512, step=64)

    # 建立模型
    model = LitModel(lr=lr, n_layers=n_layers, hidden_size=hidden_size)

    # 剪枝回呼 (Pruning callback，提早停止表現不佳的試驗)
    pruning_callback = PyTorchLightningPruningCallback(trial, monitor="val_loss")

    trainer = L.Trainer(
        max_epochs=20,
        callbacks=[pruning_callback],
        enable_progress_bar=False,
        logger=False
    )

    trainer.fit(model, train_loader, val_loader)

    return trainer.callback_metrics["val_loss"].item()

# 建立研究 (Study)
study = optuna.create_study(
    direction='minimize',
    pruner=optuna.pruners.MedianPruner()  # 提早剪除表現不佳的試驗
)

# 開始最佳化
study.optimize(objective, n_trials=50, timeout=3600)

# 最佳參數
print(f"最佳試驗：{study.best_trial.params}")
print(f"最佳數值：{study.best_value}")

# 視覺化
optuna.visualization.plot_optimization_history(study).show()
optuna.visualization.plot_param_importances(study).show()
```

**Optuna 搭配分散式訓練**：

```python
import optuna

# 用於分散式最佳化的共享資料庫
storage = optuna.storages.RDBStorage(
    url='postgresql://user:pass@localhost/optuna'
)

study = optuna.create_study(
    study_name='distributed_study',
    storage=storage,
    load_if_exists=True,
    direction='minimize'
)

# 在多台機器上執行
study.optimize(objective, n_trials=50)
```

### 3. Weights & Biases (WandB) Sweeps

**安裝方式**：
```bash
pip install wandb
```

**WandB Sweep 設定檔** (`sweep.yaml`)：
```yaml
program: train.py
method: bayes
metric:
  name: val_loss
  goal: minimize
parameters:
  lr:
    distribution: log_uniform_values
    min: 0.00001
    max: 0.1
  batch_size:
    values: [16, 32, 64, 128]
  optimizer:
    values: ['adam', 'sgd', 'adamw']
  dropout:
    distribution: uniform
    min: 0.0
    max: 0.5
```

**訓練指令碼** (`train.py`)：
```python
import wandb
import lightning as L
from lightning.pytorch.loggers import WandbLogger

def train():
    # 初始化 wandb
    wandb.init()
    config = wandb.config

    # 使用 sweep 參數建立模型
    model = LitModel(
        lr=config.lr,
        batch_size=config.batch_size,
        optimizer=config.optimizer,
        dropout=config.dropout
    )

    # WandB 日誌記錄器
    wandb_logger = WandbLogger(project='hyperparameter-sweep')

    trainer = L.Trainer(
        max_epochs=20,
        logger=wandb_logger
    )

    trainer.fit(model, train_loader, val_loader)

if __name__ == '__main__':
    train()
```

**啟動 Sweep**：
```bash
# 初始化 sweep
wandb sweep sweep.yaml
# 輸出：wandb: Created sweep with ID: abc123

# 執行代理程序 (可在多台機器上執行)
wandb agent your-entity/your-project/abc123
```

### 4. Hyperopt 整合

**安裝方式**：
```bash
pip install hyperopt
```

**Hyperopt 範例**：

```python
from hyperopt import hp, fmin, tpe, Trials

def objective(params):
    model = LitModel(
        lr=params['lr'],
        batch_size=int(params['batch_size']),
        hidden_size=int(params['hidden_size'])
    )

    trainer = L.Trainer(
        max_epochs=10,
        enable_progress_bar=False,
        logger=False
    )

    trainer.fit(model, train_loader, val_loader)

    # 回傳損失 (最小化)
    return trainer.callback_metrics["val_loss"].item()

# 定義搜尋空間
space = {
    'lr': hp.loguniform('lr', np.log(1e-5), np.log(1e-1)),
    'batch_size': hp.quniform('batch_size', 16, 128, 16),
    'hidden_size': hp.quniform('hidden_size', 64, 512, 64)
}

# 開始最佳化
trials = Trials()
best = fmin(
    fn=objective,
    space=space,
    algo=tpe.suggest,  # 樹狀結構 Parzen 估計器 (Tree-structured Parzen Estimator)
    max_evals=50,
    trials=trials
)

print(f"最佳超參數：{best}")
```

## Lightning 內建微調工具

### 自動學習率尋找器 (Auto Learning Rate Finder)

```python
class LitModel(L.LightningModule):
    def __init__(self, lr=1e-3):
        super().__init__()
        self.lr = lr
        self.model = nn.Linear(10, 1)

    def configure_optimizers(self):
        return torch.optim.Adam(self.parameters(), lr=self.lr)

    def training_step(self, batch, batch_idx):
        loss = self.model(batch).mean()
        return loss

# 尋找最佳學習率
model = LitModel()
trainer = L.Trainer(auto_lr_find=True)

# 這會在訓練前執行學習率尋找器
trainer.tune(model, train_loader)

# 或手動執行
from lightning.pytorch.tuner import Tuner
tuner = Tuner(trainer)
lr_finder = tuner.lr_find(model, train_loader)

# 繪製結果
fig = lr_finder.plot(suggest=True)
fig.show()

# 取得建議的學習率
suggested_lr = lr_finder.suggestion()
print(f"建議學習率：{suggested_lr}")

# 更新模型
model.lr = suggested_lr

# 使用最佳學習率進行訓練
trainer.fit(model, train_loader)
```

### 自動批次大小尋找器 (Auto Batch Size Finder)

```python
class LitModel(L.LightningModule):
    def __init__(self, batch_size=32):
        super().__init__()
        self.batch_size = batch_size
        self.model = nn.Linear(10, 1)

    def train_dataloader(self):
        return DataLoader(dataset, batch_size=self.batch_size)

model = LitModel()
trainer = L.Trainer(auto_scale_batch_size='binsearch')

# 尋找最佳批次大小
trainer.tune(model)

print(f"最佳批次大小：{model.batch_size}")

# 使用最佳批次大小進行訓練
trainer.fit(model, train_loader)
```

## 進階微調策略

### 1. 多保真度最佳化 (Multi-Fidelity Optimization，連續減半法)

```python
from ray.tune.schedulers import ASHAScheduler

# ASHA：非同步連續減半演算法 (Asynchronous Successive Halving Algorithm)
scheduler = ASHAScheduler(
    max_t=100,  # 最大輪數
    grace_period=10,  # 停止前的最小輪數
    reduction_factor=2  # 每輪資源減半
)

analysis = tune.run(
    train_fn,
    config=config,
    num_samples=64,
    scheduler=scheduler,
    resources_per_trial={"gpu": 1}
)
```

**運作方式**：
- 開始 64 個試驗
- 10 輪後，停止表現最後 50% 的試驗 (剩下 32 個)
- 20 輪後，停止表現最後 50% 的試驗 (剩下 16 個)
- 40 輪後，停止表現最後 50% 的試驗 (剩下 8 個)
- 80 輪後，停止表現最後 50% 的試驗 (剩下 4 個)
- 讓剩下的 4 個試驗執行到結束 (100 輪)

### 2. 貝氏最佳化 (Bayesian Optimization)

```python
from ray.tune.search.bayesopt import BayesOptSearch

search = BayesOptSearch(
    metric="val_loss",
    mode="min"
)

analysis = tune.run(
    train_fn,
    config=config,
    num_samples=50,
    search_alg=search,
    resources_per_trial={"gpu": 1}
)
```

### 3. 網格搜尋 (Grid Search)

```python
from ray import tune

# 窮舉網格搜尋
config = {
    "lr": tune.grid_search([1e-5, 1e-4, 1e-3, 1e-2]),
    "batch_size": tune.grid_search([16, 32, 64, 128]),
    "optimizer": tune.grid_search(['adam', 'sgd', 'adamw'])
}

# 總試驗次數：4 × 4 × 3 = 48
analysis = tune.run(train_fn, config=config)
```

### 4. 隨機搜尋 (Random Search)

```python
config = {
    "lr": tune.loguniform(1e-5, 1e-1),
    "batch_size": tune.choice([16, 32, 64, 128]),
    "dropout": tune.uniform(0.0, 0.5),
    "hidden_size": tune.randint(64, 512)
}

# 隨機抽樣
analysis = tune.run(
    train_fn,
    config=config,
    num_samples=100  # 進行 100 次隨機抽樣
)
```

## 最佳實踐

### 1. 從簡單開始

```python
# 第一階段：粗略搜尋 (速度快)
coarse_config = {
    "lr": tune.loguniform(1e-5, 1e-1),
    "batch_size": tune.choice([32, 64])
}
coarse_analysis = tune.run(train_fn, config=coarse_config, num_samples=10, max_epochs=5)

# 第二階段：在最佳結果附近進行微調 (速度慢)
best_lr = coarse_analysis.best_config["lr"]
fine_config = {
    "lr": tune.uniform(best_lr * 0.5, best_lr * 2),
    "batch_size": tune.choice([16, 32, 64, 128])
}
fine_analysis = tune.run(train_fn, config=fine_config, num_samples=20, max_epochs=20)
```

### 2. 使用檢查點設置 (Checkpointing)

```python
def train_fn(config, checkpoint_dir=None):
    model = LitModel(lr=config["lr"])

    trainer = L.Trainer(
        max_epochs=100,
        callbacks=[
            TuneReportCheckpointCallback(
                metrics={"loss": "val_loss"},
                filename="checkpoint",
                on="validation_end"
            )
        ]
    )

    # 如果存在檢查點，則從中恢復
    ckpt_path = None
    if checkpoint_dir:
        ckpt_path = os.path.join(checkpoint_dir, "checkpoint")

    trainer.fit(model, train_loader, val_loader, ckpt_path=ckpt_path)
```

### 3. 監控資源使用狀況

```python
import GPUtil

def train_fn(config):
    # 訓練前
    GPUs = GPUtil.getGPUs()
    print(f"訓練前 GPU 記憶體使用：{GPUs[0].memoryUsed} MB")

    # 訓練
    model = LitModel(lr=config["lr"], batch_size=config["batch_size"])
    trainer.fit(model, train_loader)

    # 訓練後
    GPUs = GPUtil.getGPUs()
    print(f"訓練後 GPU 記憶體使用：{GPUs[0].memoryUsed} MB")
```

## 常見問題

### 問題：試驗執行時發生記憶體不足 (OOM)

**解決方案**：減少同時執行的試驗次數或批次大小。
```python
analysis = tune.run(
    train_fn,
    config=config,
    resources_per_trial={"gpu": 0.5},  # 每個 GPU 執行 2 個試驗
    max_concurrent_trials=2  # 限制同時執行的試驗次數
)
```

### 問題：超參數搜尋速度過慢

**解決方案**：使用具備提前停止功能的調度器。
```python
from ray.tune.schedulers import ASHAScheduler

scheduler = ASHAScheduler(
    max_t=100,
    grace_period=5,  # 在 5 輪後停止表現不佳的試驗
    reduction_factor=3
)
```

### 問題：無法重現最佳試驗的結果

**解決方案**：在訓練函數中固定隨機數種子。
```python
def train_fn(config):
    L.seed_everything(42, workers=True)
    # 剩餘的訓練程式碼...
```

## 資源連結

- Ray Tune + Lightning 指南：https://docs.ray.io/en/latest/tune/examples/tune-pytorch-lightning.html
- Optuna 文件：https://optuna.readthedocs.io/
- WandB Sweeps 指南：https://docs.wandb.ai/guides/sweeps
- Lightning Tuner 介紹：https://lightning.ai/docs/pytorch/stable/tuning.html
