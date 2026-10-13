# 框架整合指南 (Framework Integrations Guide)

W&B 與熱門機器學習框架整合的完整指南。

## 目錄
- HuggingFace Transformers
- PyTorch Lightning
- Keras/TensorFlow
- Fast.ai
- XGBoost/LightGBM
- PyTorch 原生整合
- 自定義整合

## HuggingFace Transformers

### 自動整合

```python
from transformers import Trainer, TrainingArguments
import wandb

# 初始化 W&B
wandb.init(project="hf-transformers", name="bert-finetuning")

# 搭配 W&B 的訓練參數
training_args = TrainingArguments(
    output_dir="./results",
    report_to="wandb",  # 啟用 W&B 記錄
    run_name="bert-base-finetuning",

    # 訓練參數
    num_train_epochs=3,
    per_device_train_batch_size=16,
    per_device_eval_batch_size=64,
    learning_rate=2e-5,

    # 記錄
    logging_dir="./logs",
    logging_steps=100,
    logging_first_step=True,

    # 評估
    evaluation_strategy="steps",
    eval_steps=500,
    save_steps=500,

    # 其他
    load_best_model_at_end=True,
    metric_for_best_model="eval_accuracy"
)

# Trainer 會自動記錄至 W&B
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=eval_dataset,
    compute_metrics=compute_metrics
)

# 開始訓練（指標會自動記錄）
trainer.train()

# 結束 W&B 運行
wandb.finish()
```

### 自定義記錄

```python
from transformers import Trainer, TrainingArguments
from transformers.integrations import WandbCallback
import wandb

class CustomWandbCallback(WandbCallback):
    def on_evaluate(self, args, state, control, metrics=None, **kwargs):
        super().on_evaluate(args, state, control, metrics, **kwargs)

        # 記錄自定義指標
        wandb.log({
            "custom/eval_score": metrics["eval_accuracy"] * 100,
            "custom/epoch": state.epoch
        })

# 使用自定義回呼函數 (Callback)
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=eval_dataset,
    callbacks=[CustomWandbCallback()]
)
```

### 將模型記錄至註冊表 (Registry)

```python
from transformers import Trainer, TrainingArguments

training_args = TrainingArguments(
    output_dir="./results",
    report_to="wandb",
    load_best_model_at_end=True
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=eval_dataset
)

trainer.train()

# 將最終模型儲存為 artifact
model_artifact = wandb.Artifact(
    'hf-bert-model',
    type='model',
    description='在情緒分析任務上微調的 BERT 模型'
)

# 儲存模型檔案
trainer.save_model("./final_model")
model_artifact.add_dir("./final_model")

# 記錄 artifact
wandb.log_artifact(model_artifact, aliases=['best', 'production'])
wandb.finish()
```

## PyTorch Lightning

### 基礎整合

```python
import pytorch_lightning as pl
from pytorch_lightning.loggers import WandbLogger
import wandb

# 建立 W&B logger
wandb_logger = WandbLogger(
    project="lightning-demo",
    name="resnet50-training",
    log_model=True,  # 將模型檢查點 (Checkpoints) 記錄為 artifacts
    save_code=True   # 將程式碼記錄為 artifact
)

# Lightning 模組
class LitModel(pl.LightningModule):
    def __init__(self, learning_rate=0.001):
        super().__init__()
        self.save_hyperparameters()
        self.model = create_model()

    def training_step(self, batch, batch_idx):
        x, y = batch
        y_hat = self.model(x)
        loss = F.cross_entropy(y_hat, y)

        # 記錄指標（自動傳送至 W&B）
        self.log('train/loss', loss, on_step=True, on_epoch=True)
        self.log('train/accuracy', accuracy(y_hat, y), on_epoch=True)

        return loss

    def validation_step(self, batch, batch_idx):
        x, y = batch
        y_hat = self.model(x)
        loss = F.cross_entropy(y_hat, y)

        self.log('val/loss', loss, on_step=False, on_epoch=True)
        self.log('val/accuracy', accuracy(y_hat, y), on_epoch=True)

        return loss

    def configure_optimizers(self):
        return torch.optim.Adam(self.parameters(), lr=self.hparams.learning_rate)

# 使用 W&B logger 的 Trainer
trainer = pl.Trainer(
    logger=wandb_logger,
    max_epochs=10,
    accelerator="gpu",
    devices=1
)

# 開始訓練（指標會自動記錄）
trainer.fit(model, datamodule=dm)

# 結束 W&B 運行
wandb.finish()
```

### 記錄多媒體

```python
class LitModel(pl.LightningModule):
    def validation_step(self, batch, batch_idx):
        x, y = batch
        y_hat = self.model(x)

        # 記錄影像（僅限第一個批次）
        if batch_idx == 0:
            self.logger.experiment.log({
                "examples": [wandb.Image(img) for img in x[:8]]
            })

        return loss

    def on_validation_epoch_end(self):
        # 記錄混淆矩陣 (Confusion Matrix)
        cm = compute_confusion_matrix(self.all_preds, self.all_targets)

        self.logger.experiment.log({
            "confusion_matrix": wandb.plot.confusion_matrix(
                probs=None,
                y_true=self.all_targets,
                preds=self.all_preds,
                class_names=self.class_names
            )
        })
```

### 超參數掃描 (Hyperparameter Sweeps)

```python
import pytorch_lightning as pl
from pytorch_lightning.loggers import WandbLogger
import wandb

# 定義 sweep
sweep_config = {
    'method': 'bayes',
    'metric': {'name': 'val/accuracy', 'goal': 'maximize'},
    'parameters': {
        'learning_rate': {'min': 1e-5, 'max': 1e-2, 'distribution': 'log_uniform'},
        'batch_size': {'values': [16, 32, 64]},
        'hidden_size': {'values': [128, 256, 512]}
    }
}

sweep_id = wandb.sweep(sweep_config, project="lightning-sweeps")

def train():
    # 初始化 W&B
    run = wandb.init()

    # 獲取超參數
    config = wandb.config

    # 建立 logger
    wandb_logger = WandbLogger()

    # 使用 sweep 參數建立模型
    model = LitModel(
        learning_rate=config.learning_rate,
        hidden_size=config.hidden_size
    )

    # 使用 sweep 批次大小建立數據模組 (DataModule)
    dm = DataModule(batch_size=config.batch_size)

    # 訓練
    trainer = pl.Trainer(logger=wandb_logger, max_epochs=10)
    trainer.fit(model, dm)

# 執行 sweep
wandb.agent(sweep_id, function=train, count=30)
```

## Keras/TensorFlow

### 使用回呼函數 (Callback)

```python
import tensorflow as tf
from wandb.keras import WandbCallback
import wandb

# 初始化 W&B
wandb.init(
    project="keras-demo",
    config={
        "learning_rate": 0.001,
        "epochs": 10,
        "batch_size": 32
    }
)

config = wandb.config

# 構建模型
model = tf.keras.Sequential([
    tf.keras.layers.Dense(128, activation='relu'),
    tf.keras.layers.Dropout(0.2),
    tf.keras.layers.Dense(10, activation='softmax')
])

model.compile(
    optimizer=tf.keras.optimizers.Adam(config.learning_rate),
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

# 使用 W&B 回呼函數進行訓練
history = model.fit(
    x_train, y_train,
    validation_data=(x_val, y_val),
    epochs=config.epochs,
    batch_size=config.batch_size,
    callbacks=[
        WandbCallback(
            log_weights=True,      # 記錄模型權重
            log_gradients=True,    # 記錄梯度
            training_data=(x_train, y_train),
            validation_data=(x_val, y_val),
            labels=class_names
        )
    ]
)

# 將模型儲存為 artifact
model.save('model.h5')
artifact = wandb.Artifact('keras-model', type='model')
artifact.add_file('model.h5')
wandb.log_artifact(artifact)

wandb.finish()
```

### 自定義訓練迴圈

```python
import tensorflow as tf
import wandb

wandb.init(project="tf-custom-loop")

# 模型、優化器、損失函數
model = create_model()
optimizer = tf.keras.optimizers.Adam(1e-3)
loss_fn = tf.keras.losses.SparseCategoricalCrossentropy()

# 指標
train_loss = tf.keras.metrics.Mean(name='train_loss')
train_accuracy = tf.keras.metrics.SparseCategoricalAccuracy(name='train_accuracy')

@tf.function
def train_step(x, y):
    with tf.GradientTape() as tape:
        predictions = model(x, training=True)
        loss = loss_fn(y, predictions)

    gradients = tape.gradient(loss, model.trainable_variables)
    optimizer.apply_gradients(zip(gradients, model.trainable_variables))

    train_loss(loss)
    train_accuracy(y, predictions)

# 訓練迴圈
for epoch in range(EPOCHS):
    train_loss.reset_states()
    train_accuracy.reset_states()

    for step, (x, y) in enumerate(train_dataset):
        train_step(x, y)

        # 每 100 步記錄一次
        if step % 100 == 0:
            wandb.log({
                'train/loss': train_loss.result().numpy(),
                'train/accuracy': train_accuracy.result().numpy(),
                'epoch': epoch,
                'step': step
            })

    # 記錄 Epoch 指標
    wandb.log({
        'epoch/train_loss': train_loss.result().numpy(),
        'epoch/train_accuracy': train_accuracy.result().numpy(),
        'epoch': epoch
    })

wandb.finish()
```

## Fast.ai

### 使用回呼函數 (Callback)

```python
from fastai.vision.all import *
from fastai.callback.wandb import *
import wandb

# 初始化 W&B
wandb.init(project="fastai-demo")

# 建立數據載入器 (Data Loaders)
dls = ImageDataLoaders.from_folder(
    path,
    train='train',
    valid='valid',
    bs=64
)

# 使用 W&B 回呼函數建立 Learner
learn = vision_learner(
    dls,
    resnet34,
    metrics=accuracy,
    cbs=WandbCallback(
        log_preds=True,     # 記錄預測結果
        log_model=True,     # 將模型記錄為 artifact
        log_dataset=True    # 將數據集記錄為 artifact
    )
)

# 開始訓練（指標會自動記錄）
learn.fine_tune(5)

wandb.finish()
```

## XGBoost/LightGBM

### XGBoost

```python
import xgboost as xgb
import wandb

# 初始化 W&B
run = wandb.init(project="xgboost-demo", config={
    "max_depth": 6,
    "learning_rate": 0.1,
    "n_estimators": 100
})

config = wandb.config

# 建立 DMatrix
dtrain = xgb.DMatrix(X_train, label=y_train)
dval = xgb.DMatrix(X_val, label=y_val)

# XGBoost 參數
params = {
    'max_depth': config.max_depth,
    'learning_rate': config.learning_rate,
    'objective': 'binary:logistic',
    'eval_metric': ['logloss', 'auc']
}

# W&B 自定義回呼函數
def wandb_callback(env):
    """將 XGBoost 指標記錄至 W&B。"""
    for metric_name, metric_value in env.evaluation_result_list:
        wandb.log({
            f"{metric_name}": metric_value,
            "iteration": env.iteration
        })

# 使用回呼函數進行訓練
model = xgb.train(
    params,
    dtrain,
    num_boost_round=config.n_estimators,
    evals=[(dtrain, 'train'), (dval, 'val')],
    callbacks=[wandb_callback],
    verbose_eval=10
)

# 儲存模型
model.save_model('xgboost_model.json')
artifact = wandb.Artifact('xgboost-model', type='model')
artifact.add_file('xgboost_model.json')
wandb.log_artifact(artifact)

wandb.finish()
```

### LightGBM

```python
import lightgbm as lgb
import wandb

run = wandb.init(project="lgbm-demo")

# 建立數據集
train_data = lgb.Dataset(X_train, label=y_train)
val_data = lgb.Dataset(X_val, label=y_val, reference=train_data)

# 參數
params = {
    'objective': 'binary',
    'metric': ['binary_logloss', 'auc'],
    'learning_rate': 0.1,
    'num_leaves': 31
}

# 自定義回呼函數
def log_to_wandb(env):
    """將 LightGBM 指標記錄至 W&B。"""
    for entry in env.evaluation_result_list:
        dataset_name, metric_name, metric_value, _ = entry
        wandb.log({
            f"{dataset_name}/{metric_name}": metric_value,
            "iteration": env.iteration
        })

# 開始訓練
model = lgb.train(
    params,
    train_data,
    num_boost_round=100,
    valid_sets=[train_data, val_data],
    valid_names=['train', 'val'],
    callbacks=[log_to_wandb]
)

# 儲存模型
model.save_model('lgbm_model.txt')
artifact = wandb.Artifact('lgbm-model', type='model')
artifact.add_file('lgbm_model.txt')
wandb.log_artifact(artifact)

wandb.finish()
```

## PyTorch 原生整合

### 訓練迴圈整合

```python
import torch
import torch.nn as nn
import torch.optim as optim
import wandb

# 初始化 W&B
wandb.init(project="pytorch-native", config={
    "learning_rate": 0.001,
    "epochs": 10,
    "batch_size": 32
})

config = wandb.config

# 模型、損失函數、優化器
model = create_model()
criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=config.learning_rate)

# 監控模型（記錄梯度與參數）
wandb.watch(model, criterion, log="all", log_freq=100)

# 訓練迴圈
for epoch in range(config.epochs):
    model.train()
    train_loss = 0.0
    correct = 0
    total = 0

    for batch_idx, (data, target) in enumerate(train_loader):
        data, target = data.to(device), target.to(device)

        # 前向傳播
        optimizer.zero_grad()
        output = model(data)
        loss = criterion(output, target)

        # 反向傳播
        loss.backward()
        optimizer.step()

        # 追蹤指標
        train_loss += loss.item()
        _, predicted = output.max(1)
        total += target.size(0)
        correct += predicted.eq(target).sum().item()

        # 每 100 個批次記錄一次
        if batch_idx % 100 == 0:
            wandb.log({
                'train/loss': loss.item(),
                'train/batch_accuracy': 100. * correct / total,
                'epoch': epoch,
                'batch': batch_idx
            })

    # 驗證
    model.eval()
    val_loss = 0.0
    val_correct = 0
    val_total = 0

    with torch.no_grad():
        for data, target in val_loader:
            data, target = data.to(device), target.to(device)
            output = model(data)
            loss = criterion(output, target)

            val_loss += loss.item()
            _, predicted = output.max(1)
            val_total += target.size(0)
            val_correct += predicted.eq(target).sum().item()

    # 記錄 Epoch 指標
    wandb.log({
        'epoch/train_loss': train_loss / len(train_loader),
        'epoch/train_accuracy': 100. * correct / total,
        'epoch/val_loss': val_loss / len(val_loader),
        'epoch/val_accuracy': 100. * val_correct / val_total,
        'epoch': epoch
    })

# 儲存最終模型
torch.save(model.state_dict(), 'model.pth')
artifact = wandb.Artifact('final-model', type='model')
artifact.add_file('model.pth')
wandb.log_artifact(artifact)

wandb.finish()
```

## 自定義整合

### 通用框架整合

```python
import wandb

class WandbIntegration:
    """通用的 W&B 整合封裝器。"""

    def __init__(self, project, config):
        self.run = wandb.init(project=project, config=config)
        self.config = wandb.config
        self.step = 0

    def log_metrics(self, metrics, step=None):
        """記錄訓練指標。"""
        if step is None:
            step = self.step
            self.step += 1

        wandb.log(metrics, step=step)

    def log_images(self, images, caption=""):
        """記錄影像。"""
        wandb.log({
            caption: [wandb.Image(img) for img in images]
        })

    def log_table(self, data, columns):
        """記錄表格數據。"""
        table = wandb.Table(columns=columns, data=data)
        wandb.log({"table": table})

    def save_model(self, model_path, metadata=None):
        """將模型儲存為 artifact。"""
        artifact = wandb.Artifact(
            'model',
            type='model',
            metadata=metadata or {}
        )
        artifact.add_file(model_path)
        self.run.log_artifact(artifact)

    def finish(self):
        """結束 W&B 運行。"""
        wandb.finish()

# 使用方式
wb = WandbIntegration(project="my-project", config={"lr": 0.001})

# 訓練迴圈
for epoch in range(10):
    # 您的訓練程式碼
    loss, accuracy = train_epoch()

    # 記錄指標
    wb.log_metrics({
        'train/loss': loss,
        'train/accuracy': accuracy
    })

# 儲存模型
wb.save_model('model.pth', metadata={'accuracy': 0.95})
wb.finish()
```

## 資源

- **整合指南**：https://docs.wandb.ai/guides/integrations
- **HuggingFace 整合**：https://docs.wandb.ai/guides/integrations/huggingface
- **PyTorch Lightning 整合**：https://docs.wandb.ai/guides/integrations/lightning
- **Keras 整合**：https://docs.wandb.ai/guides/integrations/keras
- **範例集**：https://github.com/wandb/examples
