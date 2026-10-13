# 全面超參數掃描 (Sweeps) 指南

使用 W&B Sweeps 進行超參數優化 (Hyperparameter Optimization) 的完整指南。

## 目錄
- Sweep 配置
- 搜尋策略
- 參數分佈
- 早期終止 (Early Termination)
- 並行執行
- 進階模式
- 實作範例

## Sweep 配置

### 基礎 Sweep 配置

```python
sweep_config = {
    'method': 'bayes',  # 搜尋策略
    'metric': {
        'name': 'val/accuracy',
        'goal': 'maximize'  # 或 'minimize'
    },
    'parameters': {
        'learning_rate': {
            'distribution': 'log_uniform',
            'min': 1e-5,
            'max': 1e-1
        },
        'batch_size': {
            'values': [16, 32, 64, 128]
        }
    }
}

# 初始化 sweep
sweep_id = wandb.sweep(sweep_config, project="my-project")
```

### 完整配置範例

```python
sweep_config = {
    # 必填：搜尋方法
    'method': 'bayes',

    # 必填：優化指標
    'metric': {
        'name': 'val/f1_score',
        'goal': 'maximize'
    },

    # 必填：要搜尋的參數
    'parameters': {
        # 連續參數 (Continuous parameter)
        'learning_rate': {
            'distribution': 'log_uniform',
            'min': 1e-5,
            'max': 1e-1
        },

        # 離散值 (Discrete values)
        'batch_size': {
            'values': [16, 32, 64, 128]
        },

        # 類別型參數 (Categorical)
        'optimizer': {
            'values': ['adam', 'sgd', 'rmsprop', 'adamw']
        },

        # 均勻分佈 (Uniform distribution)
        'dropout': {
            'distribution': 'uniform',
            'min': 0.1,
            'max': 0.5
        },

        # 整數範圍 (Integer range)
        'num_layers': {
            'distribution': 'int_uniform',
            'min': 2,
            'max': 10
        },

        # 固定值（每次運行皆相同）
        'epochs': {
            'value': 50
        }
    },

    # 選填：早期終止 (Early termination)
    'early_terminate': {
        'type': 'hyperband',
        'min_iter': 5,
        's': 2,
        'eta': 3,
        'max_iter': 27
    }
}
```

## 搜尋策略

### 1. 網格搜尋 (Grid Search)

窮舉所有組合進行搜尋。

```python
sweep_config = {
    'method': 'grid',
    'parameters': {
        'learning_rate': {
            'values': [0.001, 0.01, 0.1]
        },
        'batch_size': {
            'values': [16, 32, 64]
        },
        'optimizer': {
            'values': ['adam', 'sgd']
        }
    }
}

# 總運行次數：3 × 3 × 2 = 18 次
```

**優點：**
- 搜尋全面
- 結果可重現
- 無隨機性

**缺點：**
- 運行次數隨參數增加呈指數級增長
- 對於連續參數效率低下
- 超過 3-4 個參數時難以擴充

**適用時機：**
- 參數較少 (< 4)
- 均為離散值
- 需要完整涵蓋所有組合

### 2. 隨機搜尋 (Random Search)

隨機採樣參數組合。

```python
sweep_config = {
    'method': 'random',
    'parameters': {
        'learning_rate': {
            'distribution': 'log_uniform',
            'min': 1e-5,
            'max': 1e-1
        },
        'batch_size': {
            'values': [16, 32, 64, 128, 256]
        },
        'dropout': {
            'distribution': 'uniform',
            'min': 0.0,
            'max': 0.5
        },
        'num_layers': {
            'distribution': 'int_uniform',
            'min': 2,
            'max': 8
        }
    }
}

# 執行 100 次隨機試驗 (Trials)
wandb.agent(sweep_id, function=train, count=100)
```

**優點：**
- 可擴充至多個參數
- 可無限期執行
- 通常能快速找到不錯的解決方案

**缺點：**
- 無法從先前的運行中學習
- 可能會錯過最佳區域
- 結果隨隨機種子而異

**適用時機：**
- 參數較多 (> 4)
- 快速探索
- 預算有限

### 3. 貝氏優化 (Bayesian Optimization)（推薦）

從先前的試驗中學習，以採樣更有潛力的區域。

```python
sweep_config = {
    'method': 'bayes',
    'metric': {
        'name': 'val/loss',
        'goal': 'minimize'
    },
    'parameters': {
        'learning_rate': {
            'distribution': 'log_uniform',
            'min': 1e-5,
            'max': 1e-1
        },
        'weight_decay': {
            'distribution': 'log_uniform',
            'min': 1e-6,
            'max': 1e-2
        },
        'dropout': {
            'distribution': 'uniform',
            'min': 0.1,
            'max': 0.5
        },
        'num_layers': {
            'values': [2, 3, 4, 5, 6]
        }
    }
}
```

**優點：**
- 樣本效率最高 (Most sample-efficient)
- 可從過去的試驗中學習
- 專注於有潛力的區域

**缺點：**
- 初始階段為隨機探索
- 可能陷入局部最優解 (Local optima)
- 每次迭代速度較慢

**適用時機：**
- 訓練運行成本高昂
- 需要最佳效能
- 運算預算有限

## 參數分佈

### 連續分佈 (Continuous Distributions)

```python
# 對數均勻 (Log-uniform)：適用於學習率、正規化
'learning_rate': {
    'distribution': 'log_uniform',
    'min': 1e-6,
    'max': 1e-1
}

# 均勻分佈 (Uniform)：適用於 Dropout、動量 (Momentum)
'dropout': {
    'distribution': 'uniform',
    'min': 0.0,
    'max': 0.5
}

# 常態分佈 (Normal distribution)
'parameter': {
    'distribution': 'normal',
    'mu': 0.5,
    'sigma': 0.1
}

# 對數常態分佈 (Log-normal distribution)
'parameter': {
    'distribution': 'log_normal',
    'mu': 0.0,
    'sigma': 1.0
}
```

### 離散分佈 (Discrete Distributions)

```python
# 固定值
'batch_size': {
    'values': [16, 32, 64, 128, 256]
}

# 整數均勻分佈
'num_layers': {
    'distribution': 'int_uniform',
    'min': 2,
    'max': 10
}

# 量化均勻分佈 (Quantized uniform)（設定步長）
'layer_size': {
    'distribution': 'q_uniform',
    'min': 32,
    'max': 512,
    'q': 32  # 步長為 32：32, 64, 96, 128...
}

# 量化對數均勻分佈
'hidden_size': {
    'distribution': 'q_log_uniform',
    'min': 32,
    'max': 1024,
    'q': 32
}
```

### 類別型參數 (Categorical Parameters)

```python
# 優化器 (Optimizers)
'optimizer': {
    'values': ['adam', 'sgd', 'rmsprop', 'adamw']
}

# 模型架構
'model': {
    'values': ['resnet18', 'resnet34', 'resnet50', 'efficientnet_b0']
}

# 激活函數 (Activation functions)
'activation': {
    'values': ['relu', 'gelu', 'silu', 'leaky_relu']
}
```

## 早期終止 (Early Termination)

提前停止表現不佳的運行以節省運算資源。

### Hyperband

```python
sweep_config = {
    'method': 'bayes',
    'metric': {'name': 'val/accuracy', 'goal': 'maximize'},
    'parameters': {...},

    # Hyperband 早期終止
    'early_terminate': {
        'type': 'hyperband',
        'min_iter': 3,      # 終止前的最小迭代次數
        's': 2,             # Bracket 數量
        'eta': 3,           # 下採樣率 (Downsampling rate)
        'max_iter': 27      # 最大迭代次數
    }
}
```

**運作方式：**
- 在各個層級 (Brackets) 執行試驗
- 每輪保留表現前 1/eta 的運行
- 提前淘汰表現後端的運行

### 自定義終止

```python
def train():
    run = wandb.init()

    for epoch in range(MAX_EPOCHS):
        loss = train_epoch()
        val_acc = validate()

        wandb.log({'val/accuracy': val_acc, 'epoch': epoch})

        # 自定義早期停止
        if epoch > 5 and val_acc < 0.5:
            print("早期停止：表現不佳")
            break

        if epoch > 10 and val_acc > best_acc - 0.01:
            print("早期停止：無明顯改善")
            break
```

## 訓練函數

### 基礎範本

```python
def train():
    # 初始化 W&B 運行
    run = wandb.init()

    # 獲取超參數
    config = wandb.config

    # 使用配置構建模型
    model = build_model(
        hidden_size=config.hidden_size,
        num_layers=config.num_layers,
        dropout=config.dropout
    )

    # 建立優化器
    optimizer = create_optimizer(
        model.parameters(),
        name=config.optimizer,
        lr=config.learning_rate,
        weight_decay=config.weight_decay
    )

    # 訓練迴圈
    for epoch in range(config.epochs):
        # 訓練
        train_loss, train_acc = train_epoch(
            model, optimizer, train_loader, config.batch_size
        )

        # 驗證
        val_loss, val_acc = validate(model, val_loader)

        # 記錄指標
        wandb.log({
            'train/loss': train_loss,
            'train/accuracy': train_acc,
            'val/loss': val_loss,
            'val/accuracy': val_acc,
            'epoch': epoch
        })

    # 記錄最終模型
    torch.save(model.state_dict(), 'model.pth')
    wandb.save('model.pth')

    # 結束運行
    wandb.finish()
```

### 搭配 PyTorch 使用

```python
import torch
import torch.nn as nn
from torch.utils.data import DataLoader
import wandb

def train():
    run = wandb.init()
    config = wandb.config

    # 數據
    train_loader = DataLoader(
        train_dataset,
        batch_size=config.batch_size,
        shuffle=True
    )

    # 模型
    model = ResNet(
        num_classes=config.num_classes,
        dropout=config.dropout
    ).to(device)

    # 優化器
    if config.optimizer == 'adam':
        optimizer = torch.optim.Adam(
            model.parameters(),
            lr=config.learning_rate,
            weight_decay=config.weight_decay
        )
    elif config.optimizer == 'sgd':
        optimizer = torch.optim.SGD(
            model.parameters(),
            lr=config.learning_rate,
            momentum=config.momentum,
            weight_decay=config.weight_decay
        )

    # 調度器 (Scheduler)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
        optimizer, T_max=config.epochs
    )

    # 訓練
    for epoch in range(config.epochs):
        model.train()
        train_loss = 0.0

        for data, target in train_loader:
            data, target = data.to(device), target.to(device)

            optimizer.zero_grad()
            output = model(data)
            loss = nn.CrossEntropyLoss()(output, target)
            loss.backward()
            optimizer.step()

            train_loss += loss.item()

        # 驗證
        model.eval()
        val_loss, val_acc = validate(model, val_loader)

        # 更新調度器步長
        scheduler.step()

        # 記錄
        wandb.log({
            'train/loss': train_loss / len(train_loader),
            'val/loss': val_loss,
            'val/accuracy': val_acc,
            'learning_rate': scheduler.get_last_lr()[0],
            'epoch': epoch
        })
```

## 並行執行 (Parallel Execution)

### 多個代理程式 (Agents)

並行執行多個 sweep 代理程式以加快搜尋速度。

```python
# 初始化 sweep 一次
sweep_id = wandb.sweep(sweep_config, project="my-project")

# 並行執行多個代理程式
# 代理程式 1 (終端機 1)
wandb.agent(sweep_id, function=train, count=20)

# 代理程式 2 (終端機 2)
wandb.agent(sweep_id, function=train, count=20)

# 代理程式 3 (終端機 3)
wandb.agent(sweep_id, function=train, count=20)

# 總計：透過 3 個代理程式執行 60 次運行
```

### 多 GPU 執行

```python
import os

def train():
    # 獲取可用的 GPU
    gpu_id = os.environ.get('CUDA_VISIBLE_DEVICES', '0')

    run = wandb.init()
    config = wandb.config

    # 在特定 GPU 上進行訓練
    device = torch.device(f'cuda:{gpu_id}')
    model = model.to(device)

    # ... 其餘訓練代碼 ...

# 在不同 GPU 上執行代理程式
# 終端機 1
# CUDA_VISIBLE_DEVICES=0 wandb agent sweep_id

# 終端機 2
# CUDA_VISIBLE_DEVICES=1 wandb agent sweep_id

# 終端機 3
# CUDA_VISIBLE_DEVICES=2 wandb agent sweep_id
```

## 進階模式

### 嵌套參數 (Nested Parameters)

```python
sweep_config = {
    'method': 'bayes',
    'metric': {'name': 'val/accuracy', 'goal': 'maximize'},
    'parameters': {
        'model': {
            'parameters': {
                'type': {
                    'values': ['resnet', 'efficientnet']
                },
                'size': {
                    'values': ['small', 'medium', 'large']
                }
            }
        },
        'optimizer': {
            'parameters': {
                'type': {
                    'values': ['adam', 'sgd']
                },
                'lr': {
                    'distribution': 'log_uniform',
                    'min': 1e-5,
                    'max': 1e-1
                }
            }
        }
    }
}

# 存取嵌套配置
def train():
    run = wandb.init()
    model_type = wandb.config.model.type
    model_size = wandb.config.model.size
    opt_type = wandb.config.optimizer.type
    lr = wandb.config.optimizer.lr
```

### 條件參數 (Conditional Parameters)

```python
sweep_config = {
    'method': 'bayes',
    'parameters': {
        'optimizer': {
            'values': ['adam', 'sgd']
        },
        'learning_rate': {
            'distribution': 'log_uniform',
            'min': 1e-5,
            'max': 1e-1
        },
        # 僅當 optimizer == 'sgd' 時使用
        'momentum': {
            'distribution': 'uniform',
            'min': 0.5,
            'max': 0.99
        }
    }
}

def train():
    run = wandb.init()
    config = wandb.config

    if config.optimizer == 'adam':
        optimizer = torch.optim.Adam(
            model.parameters(),
            lr=config.learning_rate
        )
    elif config.optimizer == 'sgd':
        optimizer = torch.optim.SGD(
            model.parameters(),
            lr=config.learning_rate,
            momentum=config.momentum  # 條件參數
        )
```

## 實作範例

### 影像分類 (Image Classification)

```python
sweep_config = {
    'method': 'bayes',
    'metric': {
        'name': 'val/top1_accuracy',
        'goal': 'maximize'
    },
    'parameters': {
        # 模型
        'architecture': {
            'values': ['resnet50', 'resnet101', 'efficientnet_b0', 'efficientnet_b3']
        },
        'pretrained': {
            'values': [True, False]
        },

        # 訓練
        'learning_rate': {
            'distribution': 'log_uniform',
            'min': 1e-5,
            'max': 1e-2
        },
        'batch_size': {
            'values': [16, 32, 64, 128]
        },
        'optimizer': {
            'values': ['adam', 'sgd', 'adamw']
        },
        'weight_decay': {
            'distribution': 'log_uniform',
            'min': 1e-6,
            'max': 1e-2
        },

        # 正規化 (Regularization)
        'dropout': {
            'distribution': 'uniform',
            'min': 0.0,
            'max': 0.5
        },
        'label_smoothing': {
            'distribution': 'uniform',
            'min': 0.0,
            'max': 0.2
        },

        # 數據增強 (Data augmentation)
        'mixup_alpha': {
            'distribution': 'uniform',
            'min': 0.0,
            'max': 1.0
        },
        'cutmix_alpha': {
            'distribution': 'uniform',
            'min': 0.0,
            'max': 1.0
        }
    },
    'early_terminate': {
        'type': 'hyperband',
        'min_iter': 5
    }
}
```

### 自然語言處理 (NLP) 微調

```python
sweep_config = {
    'method': 'bayes',
    'metric': {'name': 'eval/f1', 'goal': 'maximize'},
    'parameters': {
        # 模型
        'model_name': {
            'values': ['bert-base-uncased', 'roberta-base', 'distilbert-base-uncased']
        },

        # 訓練
        'learning_rate': {
            'distribution': 'log_uniform',
            'min': 1e-6,
            'max': 1e-4
        },
        'per_device_train_batch_size': {
            'values': [8, 16, 32]
        },
        'num_train_epochs': {
            'values': [3, 4, 5]
        },
        'warmup_ratio': {
            'distribution': 'uniform',
            'min': 0.0,
            'max': 0.1
        },
        'weight_decay': {
            'distribution': 'log_uniform',
            'min': 1e-4,
            'max': 1e-1
        },

        # 優化器 (Optimizer)
        'adam_beta1': {
            'distribution': 'uniform',
            'min': 0.8,
            'max': 0.95
        },
        'adam_beta2': {
            'distribution': 'uniform',
            'min': 0.95,
            'max': 0.999
        }
    }
}
```

## 最佳實踐

### 1. 從小規模開始

```python
# 初始探索：隨機搜尋，20 次運行
sweep_config_v1 = {
    'method': 'random',
    'parameters': {...}
}
wandb.agent(sweep_id_v1, train, count=20)

# 精細搜尋：貝氏優化，縮小範圍
sweep_config_v2 = {
    'method': 'bayes',
    'parameters': {
        'learning_rate': {
            'min': 5e-5,  # 從 1e-6 至 1e-4 縮小至此範圍
            'max': 1e-4
        }
    }
}
```

### 2. 使用對數標度 (Log Scales)

```python
# ✅ 建議：學習率使用對數標度
'learning_rate': {
    'distribution': 'log_uniform',
    'min': 1e-6,
    'max': 1e-2
}

# ❌ 不建議：使用線性標度
'learning_rate': {
    'distribution': 'uniform',
    'min': 0.000001,
    'max': 0.01
}
```

### 3. 設定合理的範圍

```python
# 根據先前知識設定範圍
'learning_rate': {'min': 1e-5, 'max': 1e-3},  # Adam 的典型範圍
'batch_size': {'values': [16, 32, 64]},       # GPU 記憶體限制
'dropout': {'min': 0.1, 'max': 0.5}           # 過高會損害訓練效果
```

### 4. 監控資源使用情況

```python
def train():
    run = wandb.init()

    # 記錄系統指標
    wandb.log({
        'system/gpu_memory_allocated': torch.cuda.memory_allocated(),
        'system/gpu_memory_reserved': torch.cuda.memory_reserved()
    })
```

### 5. 儲存最佳模型

```python
def train():
    run = wandb.init()
    best_acc = 0.0

    for epoch in range(config.epochs):
        val_acc = validate(model)

        if val_acc > best_acc:
            best_acc = val_acc
            # 儲存最佳檢查點
            torch.save(model.state_dict(), 'best_model.pth')
            wandb.save('best_model.pth')
```

## 資源

- **Sweeps 官方文件**：https://docs.wandb.ai/guides/sweeps
- **配置參考**：https://docs.wandb.ai/guides/sweeps/configuration
- **範例集**：https://github.com/wandb/examples/tree/master/examples/wandb-sweeps
