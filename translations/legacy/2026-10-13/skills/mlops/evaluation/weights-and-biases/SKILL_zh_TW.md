---
name: weights-and-biases
description: 使用自動記錄功能追蹤機器學習實驗、即時視覺化訓練過程、透過 Sweeps 優化超參數，並利用 W&B 管理模型註冊表 — 協作式 MLOps 平台
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [wandb]
metadata:
  hermes:
    tags: [MLOps, Weights And Biases, WandB, Experiment Tracking, Hyperparameter Tuning, Model Registry, Collaboration, Real-Time Visualization, PyTorch, TensorFlow, HuggingFace]

---

# Weights & Biases: 機器學習實驗追蹤與 MLOps

## 何時使用此技能

在需要執行以下操作時使用 Weights & Biases (W&B)：
- **追蹤機器學習實驗**，具備自動指標記錄功能
- 在即時儀表板中**視覺化訓練過程**
- **比較不同超參數與配置下的運行結果 (Runs)**
- 使用自動化 Sweeps **優化超參數**
- 透過版本控制與血緣追蹤**管理模型註冊表 (Model Registry)**
- 在團隊工作區中**協作機器學習專案**
- 透過血緣追蹤**管理 Artifacts**（數據集、模型、程式碼）

**使用者**：200,000+ 機器學習從業者 | **GitHub Stars**：10.5k+ | **整合工具**：100+

## 安裝

```bash
# 安裝 W&B
pip install wandb

# 登入（建立 API 金鑰）
wandb login

# 或透過程式設定 API 金鑰
export WANDB_API_KEY=your_api_key_here
```

## 快速上手

### 基本實驗追蹤

```python
import wandb

# 初始化一次運行 (Run)
run = wandb.init(
    project="my-project",
    config={
        "learning_rate": 0.001,
        "epochs": 10,
        "batch_size": 32,
        "architecture": "ResNet50"
    }
)

# 訓練迴圈
for epoch in range(run.config.epochs):
    # 您的訓練程式碼
    train_loss = train_epoch()
    val_loss = validate()

    # 記錄指標
    wandb.log({
        "epoch": epoch,
        "train/loss": train_loss,
        "val/loss": val_loss,
        "train/accuracy": train_acc,
        "val/accuracy": val_acc
    })

# 結束運行
wandb.finish()
```

### 搭配 PyTorch 使用

```python
import torch
import wandb

# 初始化
wandb.init(project="pytorch-demo", config={
    "lr": 0.001,
    "epochs": 10
})

# 存取配置
config = wandb.config

# 訓練迴圈
for epoch in range(config.epochs):
    for batch_idx, (data, target) in enumerate(train_loader):
        # 前向傳播
        output = model(data)
        loss = criterion(output, target)

        # 反向傳播
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

        # 每 100 個批次記錄一次
        if batch_idx % 100 == 0:
            wandb.log({
                "loss": loss.item(),
                "epoch": epoch,
                "batch": batch_idx
            })

# 儲存模型
torch.save(model.state_dict(), "model.pth")
wandb.save("model.pth")  # 上傳至 W&B

wandb.finish()
```

## 核心概念

### 1. 專案 (Projects) 與 運行 (Runs)

**專案 (Project)**：相關實驗的集合。
**運行 (Run)**：訓練腳本的單次執行。

```python
# 建立/使用專案
run = wandb.init(
    project="image-classification",
    name="resnet50-experiment-1",  # 選填：運行名稱
    tags=["baseline", "resnet"],    # 使用標籤組織
    notes="First baseline run"      # 新增備註
)

# 每次運行都有唯一的 ID
print(f"Run ID: {run.id}")
print(f"Run URL: {run.url}")
```

### 2. 配置追蹤 (Configuration Tracking)

自動追蹤超參數：

```python
config = {
    # 模型架構
    "model": "ResNet50",
    "pretrained": True,

    # 訓練參數
    "learning_rate": 0.001,
    "batch_size": 32,
    "epochs": 50,
    "optimizer": "Adam",

    # 數據參數
    "dataset": "ImageNet",
    "augmentation": "standard"
}

wandb.init(project="my-project", config=config)

# 訓練期間存取配置
lr = wandb.config.learning_rate
batch_size = wandb.config.batch_size
```

### 3. 指標記錄 (Metric Logging)

```python
# 記錄純量 (Scalars)
wandb.log({"loss": 0.5, "accuracy": 0.92})

# 記錄多個指標
wandb.log({
    "train/loss": train_loss,
    "train/accuracy": train_acc,
    "val/loss": val_loss,
    "val/accuracy": val_acc,
    "learning_rate": current_lr,
    "epoch": epoch
})

# 使用自定義 x 軸記錄
wandb.log({"loss": loss}, step=global_step)

# 記錄多媒體（影像、音訊、影片）
wandb.log({"examples": [wandb.Image(img) for img in images]})

# 記錄直方圖 (Histograms)
wandb.log({"gradients": wandb.Histogram(gradients)})

# 記錄表格 (Tables)
table = wandb.Table(columns=["id", "prediction", "ground_truth"])
wandb.log({"predictions": table})
```

### 4. 模型檢查點 (Model Checkpointing)

```python
import torch
import wandb

# 儲存模型檢查點
checkpoint = {
    'epoch': epoch,
    'model_state_dict': model.state_dict(),
    'optimizer_state_dict': optimizer.state_dict(),
    'loss': loss,
}

torch.save(checkpoint, 'checkpoint.pth')

# 上傳至 W&B
wandb.save('checkpoint.pth')

# 或使用 Artifacts（推薦）
artifact = wandb.Artifact('model', type='model')
artifact.add_file('checkpoint.pth')
wandb.log_artifact(artifact)
```

## 超參數掃描 (Hyperparameter Sweeps)

自動搜尋最佳超參數。

### 定義 Sweep 配置

```python
sweep_config = {
    'method': 'bayes',  # 或 'grid', 'random'
    'metric': {
        'name': 'val/accuracy',
        'goal': 'maximize'
    },
    'parameters': {
        'learning_rate': {
            'distribution': 'log_uniform',
            'min': 1e-5,
            'max': 1e-1
        },
        'batch_size': {
            'values': [16, 32, 64, 128]
        },
        'optimizer': {
            'values': ['adam', 'sgd', 'rmsprop']
        },
        'dropout': {
            'distribution': 'uniform',
            'min': 0.1,
            'max': 0.5
        }
    }
}

# 初始化 sweep
sweep_id = wandb.sweep(sweep_config, project="my-project")
```

### 定義訓練函數

```python
def train():
    # 初始化運行
    run = wandb.init()

    # 存取 sweep 參數
    lr = wandb.config.learning_rate
    batch_size = wandb.config.batch_size
    optimizer_name = wandb.config.optimizer

    # 使用 sweep 配置構建模型
    model = build_model(wandb.config)
    optimizer = get_optimizer(optimizer_name, lr)

    # 訓練迴圈
    for epoch in range(NUM_EPOCHS):
        train_loss = train_epoch(model, optimizer, batch_size)
        val_acc = validate(model)

        # 記錄指標
        wandb.log({
            "train/loss": train_loss,
            "val/accuracy": val_acc
        })

# 執行 sweep
wandb.agent(sweep_id, function=train, count=50)  # 執行 50 次試驗
```

### Sweep 策略

```python
# 網格搜尋 (Grid search) - 窮舉法
sweep_config = {
    'method': 'grid',
    'parameters': {
        'lr': {'values': [0.001, 0.01, 0.1]},
        'batch_size': {'values': [16, 32, 64]}
    }
}

# 隨機搜尋 (Random search)
sweep_config = {
    'method': 'random',
    'parameters': {
        'lr': {'distribution': 'uniform', 'min': 0.0001, 'max': 0.1},
        'dropout': {'distribution': 'uniform', 'min': 0.1, 'max': 0.5}
    }
}

# 貝氏優化 (Bayesian optimization)（推薦）
sweep_config = {
    'method': 'bayes',
    'metric': {'name': 'val/loss', 'goal': 'minimize'},
    'parameters': {
        'lr': {'distribution': 'log_uniform', 'min': 1e-5, 'max': 1e-1}
    }
}
```

## Artifacts

追蹤具備血緣關係的數據集、模型與其他檔案。

### 記錄 Artifacts

```python
# 建立 artifact
artifact = wandb.Artifact(
    name='training-dataset',
    type='dataset',
    description='ImageNet 訓練集切分',
    metadata={'size': '1.2M images', 'split': 'train'}
)

# 新增檔案
artifact.add_file('data/train.csv')
artifact.add_dir('data/images/')

# 記錄 artifact
wandb.log_artifact(artifact)
```

### 使用 Artifacts

```python
# 下載並使用 artifact
run = wandb.init(project="my-project")

# 下載 artifact
artifact = run.use_artifact('training-dataset:latest')
artifact_dir = artifact.download()

# 使用數據
data = load_data(f"{artifact_dir}/train.csv")
```

### 模型註冊表 (Model Registry)

```python
# 將模型記錄為 artifact
model_artifact = wandb.Artifact(
    name='resnet50-model',
    type='model',
    metadata={'architecture': 'ResNet50', 'accuracy': 0.95}
)

model_artifact.add_file('model.pth')
wandb.log_artifact(model_artifact, aliases=['best', 'production'])

# 連結至模型註冊表
run.link_artifact(model_artifact, 'model-registry/production-models')
```

## 整合範例

### HuggingFace Transformers

```python
from transformers import Trainer, TrainingArguments
import wandb

# 初始化 W&B
wandb.init(project="hf-transformers")

# 搭配 W&B 的訓練參數
training_args = TrainingArguments(
    output_dir="./results",
    report_to="wandb",  # 啟用 W&B 記錄
    run_name="bert-finetuning",
    logging_steps=100,
    save_steps=500
)

# Trainer 會自動記錄至 W&B
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=eval_dataset
)

trainer.train()
```

### PyTorch Lightning

```python
from pytorch_lightning import Trainer
from pytorch_lightning.loggers import WandbLogger
import wandb

# 建立 W&B logger
wandb_logger = WandbLogger(
    project="lightning-demo",
    log_model=True  # 記錄模型檢查點
)

# 與 Trainer 搭配使用
trainer = Trainer(
    logger=wandb_logger,
    max_epochs=10
)

trainer.fit(model, datamodule=dm)
```

### Keras/TensorFlow

```python
import wandb
from wandb.keras import WandbCallback

# 初始化
wandb.init(project="keras-demo")

# 新增回呼函數 (Callback)
model.fit(
    x_train, y_train,
    validation_data=(x_val, y_val),
    epochs=10,
    callbacks=[WandbCallback()]  # 自動記錄指標
)
```

## 視覺化與分析

### 自定義圖表

```python
# 記錄自定義視覺化內容
import matplotlib.pyplot as plt

fig, ax = plt.subplots()
ax.plot(x, y)
wandb.log({"custom_plot": wandb.Image(fig)})

# 記錄混淆矩陣 (Confusion Matrix)
wandb.log({"conf_mat": wandb.plot.confusion_matrix(
    probs=None,
    y_true=ground_truth,
    preds=predictions,
    class_names=class_names
)})
```

### 報告 (Reports)

在 W&B 使用者介面中建立可分享的報告：
- 結合運行結果、圖表與文字
- 支援 Markdown
- 可嵌入視覺化內容
- 團隊協作

## 最佳實踐

### 1. 使用標籤 (Tags) 與群組 (Groups) 進行組織

```python
wandb.init(
    project="my-project",
    tags=["baseline", "resnet50", "imagenet"],
    group="resnet-experiments",  # 將相關運行歸類
    job_type="train"             # 工作類型
)
```

### 2. 記錄所有相關資訊

```python
# 記錄系統指標
wandb.log({
    "gpu/util": gpu_utilization,
    "gpu/memory": gpu_memory_used,
    "cpu/util": cpu_utilization
})

# 記錄程式碼版本
wandb.log({"git_commit": git_commit_hash})

# 記錄數據切分
wandb.log({
    "data/train_size": len(train_dataset),
    "data/val_size": len(val_dataset)
})
```

### 3. 使用具描述性的名稱

```python
# ✅ 建議：具描述性的運行名稱
wandb.init(
    project="nlp-classification",
    name="bert-base-lr0.001-bs32-epoch10"
)

# ❌ 不建議：過於籠統的名稱
wandb.init(project="nlp", name="run1")
```

### 4. 儲存重要的 Artifacts

```python
# 儲存最終模型
artifact = wandb.Artifact('final-model', type='model')
artifact.add_file('model.pth')
wandb.log_artifact(artifact)

# 儲存預測結果以供分析
predictions_table = wandb.Table(
    columns=["id", "input", "prediction", "ground_truth"],
    data=predictions_data
)
wandb.log({"predictions": predictions_table})
```

### 5. 連線不穩時使用離線模式

```python
import os

# 啟用離線模式
os.environ["WANDB_MODE"] = "offline"

wandb.init(project="my-project")
# ... 您的程式碼 ...

# 稍後再進行同步
# wandb sync <run_directory>
```

## 團隊協作

### 分享運行結果

```python
# 運行結果會自動產生可分享的 URL
run = wandb.init(project="team-project")
print(f"分享此 URL: {run.url}")
```

### 團隊專案

- 在 wandb.ai 建立團隊帳號
- 新增團隊成員
- 設定專案可見度（私有/公開）
- 使用團隊層級的 Artifacts 與模型註冊表

## 定價

- **免費版**：無限量公開專案，100GB 儲存空間
- **學術版**：學生/研究人員免費使用
- **團隊版**：每位使用者每月 $50，私有專案，無限量儲存空間
- **企業版**：自定義定價，提供地端 (on-prem) 選項

## 資源

- **官方文件**：https://docs.wandb.ai
- **GitHub**：https://github.com/wandb/wandb (10.5k+ stars)
- **範例**：https://github.com/wandb/examples
- **社群**：https://wandb.ai/community
- **Discord**：https://wandb.me/discord

## 參閱

- `references/sweeps.md` - 全面的超參數優化指南
- `references/artifacts.md` - 數據與模型版本控制模式
- `references/integrations.md` - 特定框架的範例
