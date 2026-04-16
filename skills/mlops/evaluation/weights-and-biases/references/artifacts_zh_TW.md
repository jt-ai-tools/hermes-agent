# Artifacts 與模型註冊表 (Model Registry) 指南

使用 W&B Artifacts 進行數據版本控制與模型管理的完整指南。

## 目錄
- 什麼是 Artifacts
- 建立 Artifacts
- 使用 Artifacts
- 模型註冊表 (Model Registry)
- 版本控制與血緣 (Lineage)
- 最佳實踐

## 什麼是 Artifacts

Artifacts 是具備版本控制的數據集、模型或檔案，並會伴隨血緣 (Lineage) 追蹤。

**核心特性：**
- 自動版本控制 (v0, v1, v2...)
- 血緣追蹤（追蹤哪些運行結果產生或使用了該 Artifacts）
- 高效儲存（去重複，Deduplication）
- 團隊協作（全團隊皆可存取）
- 別名 (Aliases)（latest, best, production）

**常見使用案例：**
- 數據集版本控制
- 模型檢查點 (Checkpoints)
- 預處理後的數據
- 評估結果
- 配置檔案

## 建立 Artifacts

### 基礎數據集 Artifact

```python
import wandb

run = wandb.init(project="my-project")

# 建立 artifact
dataset = wandb.Artifact(
    name='training-data',
    type='dataset',
    description='包含數據增強的 ImageNet 訓練集切分',
    metadata={
        'size': '1.2M images',
        'format': 'JPEG',
        'resolution': '224x224'
    }
)

# 新增檔案
dataset.add_file('data/train.csv')        # 單一檔案
dataset.add_dir('data/images')            # 整個目錄
dataset.add_reference('s3://bucket/data') # 雲端引用 (Cloud reference)

# 記錄 artifact
run.log_artifact(dataset)
wandb.finish()
```

### 模型 Artifact

```python
import torch
import wandb

run = wandb.init(project="my-project")

# 訓練模型
model = train_model()

# 儲存模型
torch.save(model.state_dict(), 'model.pth')

# 建立模型 artifact
model_artifact = wandb.Artifact(
    name='resnet50-classifier',
    type='model',
    description='在 ImageNet 上訓練的 ResNet50',
    metadata={
        'architecture': 'ResNet50',
        'accuracy': 0.95,
        'loss': 0.15,
        'epochs': 50,
        'framework': 'PyTorch'
    }
)

# 新增模型檔案
model_artifact.add_file('model.pth')

# 新增配置
model_artifact.add_file('config.yaml')

# 使用別名記錄
run.log_artifact(model_artifact, aliases=['latest', 'best'])

wandb.finish()
```

### 預處理數據 Artifact

```python
import pandas as pd
import wandb

run = wandb.init(project="nlp-project")

# 預處理數據
df = pd.read_csv('raw_data.csv')
df_processed = preprocess(df)
df_processed.to_csv('processed_data.csv', index=False)

# 建立 artifact
processed_data = wandb.Artifact(
    name='processed-text-data',
    type='dataset',
    metadata={
        'rows': len(df_processed),
        'columns': list(df_processed.columns),
        'preprocessing_steps': ['lowercase', 'remove_stopwords', 'tokenize']
    }
)

processed_data.add_file('processed_data.csv')

# 記錄 artifact
run.log_artifact(processed_data)
```

## 使用 Artifacts

### 下載並使用

```python
import wandb

run = wandb.init(project="my-project")

# 下載 artifact
artifact = run.use_artifact('training-data:latest')
artifact_dir = artifact.download()

# 使用檔案
import pandas as pd
df = pd.read_csv(f'{artifact_dir}/train.csv')

# 使用 artifact 數據進行訓練
model = train_model(df)
```

### 使用特定版本

```python
# 使用特定版本
artifact_v2 = run.use_artifact('training-data:v2')

# 使用別名
artifact_best = run.use_artifact('model:best')
artifact_prod = run.use_artifact('model:production')

# 使用其他專案的內容
artifact = run.use_artifact('team/other-project/model:latest')
```

### 檢查 Artifact 中繼數據 (Metadata)

```python
artifact = run.use_artifact('training-data:latest')

# 存取中繼數據
print(artifact.metadata)
print(f"大小：{artifact.metadata['size']}")

# 存取版本資訊
print(f"版本：{artifact.version}")
print(f"建立時間：{artifact.created_at}")
print(f"摘要 (Digest)：{artifact.digest}")
```

## 模型註冊表 (Model Registry)

將模型連結至中央註冊表，以便進行治理與部署。

### 建立模型註冊表

```python
# 在 W&B 使用者介面中：
# 1. 點擊 "Registry" 分頁
# 2. 建立新的註冊表："production-models"
# 3. 定義階段 (Stages)：development, staging, production
```

### 將模型連結至註冊表

```python
import wandb

run = wandb.init(project="training")

# 建立模型 artifact
model_artifact = wandb.Artifact(
    name='sentiment-classifier',
    type='model',
    metadata={'accuracy': 0.94, 'f1': 0.92}
)

model_artifact.add_file('model.pth')

# 記錄 artifact
run.log_artifact(model_artifact)

# 連結至註冊表
run.link_artifact(
    model_artifact,
    'model-registry/production-models',
    aliases=['staging']  # 部署至預發布 (Staging) 階段
)

wandb.finish()
```

### 在註冊表中晉升模型 (Promote)

```python
# 從註冊表獲取模型
api = wandb.Api()
artifact = api.artifact('model-registry/production-models/sentiment-classifier:staging')

# 晉升至生產 (Production) 階段
artifact.link('model-registry/production-models', aliases=['production'])

# 從生產階段降級 (Demote)
artifact.aliases = ['archived']
artifact.save()
```

### 從註冊表使用模型

```python
import wandb

run = wandb.init()

# 下載生產環境模型
model_artifact = run.use_artifact(
    'model-registry/production-models/sentiment-classifier:production'
)

model_dir = model_artifact.download()

# 載入並使用
import torch
model = torch.load(f'{model_dir}/model.pth')
model.eval()
```

## 版本控制與血緣 (Lineage)

### 自動版本控制

```python
# 第一次記錄：建立 v0
run1 = wandb.init(project="my-project")
dataset_v0 = wandb.Artifact('my-dataset', type='dataset')
dataset_v0.add_file('data_v1.csv')
run1.log_artifact(dataset_v0)

# 第二次記錄（使用相同名稱）：建立 v1
run2 = wandb.init(project="my-project")
dataset_v1 = wandb.Artifact('my-dataset', type='dataset')
dataset_v1.add_file('data_v2.csv')  # 內容不同
run2.log_artifact(dataset_v1)

# 第三次記錄（與 v1 內容相同）：引用 v1（不產生新版本）
run3 = wandb.init(project="my-project")
dataset_v1_again = wandb.Artifact('my-dataset', type='dataset')
dataset_v1_again.add_file('data_v2.csv')  # 與 v1 內容相同
run3.log_artifact(dataset_v1_again)  # 仍然是 v1，不會建立 v2
```

### 追蹤血緣 (Track Lineage)

```python
# 訓練運行
run = wandb.init(project="my-project")

# 使用數據集（輸入）
dataset = run.use_artifact('training-data:v3')
data = load_data(dataset.download())

# 訓練模型
model = train(data)

# 儲存模型（輸出）
model_artifact = wandb.Artifact('trained-model', type='model')
torch.save(model.state_dict(), 'model.pth')
model_artifact.add_file('model.pth')
run.log_artifact(model_artifact)

# 血緣會被自動追蹤：
# training-data:v3 --> [run] --> trained-model:v0
```

### 查看血緣圖表

```python
# 在 W&B 使用者介面中：
# Artifacts → 選擇 artifact → Lineage 分頁
# 顯示資訊：
# - 哪些運行產生了此 artifact
# - 哪些運行使用了此 artifact
# - 父層/子層 artifact
```

## Artifact 類型

### 數據集 Artifacts

```python
# 原始數據
raw_data = wandb.Artifact('raw-data', type='dataset')
raw_data.add_dir('raw/')

# 處理後的數據
processed_data = wandb.Artifact('processed-data', type='dataset')
processed_data.add_dir('processed/')

# 訓練/驗證/測試集切分
train_split = wandb.Artifact('train-split', type='dataset')
train_split.add_file('train.csv')

val_split = wandb.Artifact('val-split', type='dataset')
val_split.add_file('val.csv')
```

### 模型 Artifacts

```python
# 訓練期間的檢查點
checkpoint = wandb.Artifact('checkpoint-epoch-10', type='model')
checkpoint.add_file('checkpoint_epoch_10.pth')

# 最終模型
final_model = wandb.Artifact('final-model', type='model')
final_model.add_file('model.pth')
final_model.add_file('tokenizer.json')

# 量化後的模型
quantized = wandb.Artifact('quantized-model', type='model')
quantized.add_file('model_int8.onnx')
```

### 結果 Artifacts

```python
# 預測結果
predictions = wandb.Artifact('test-predictions', type='predictions')
predictions.add_file('predictions.csv')

# 評估指標
eval_results = wandb.Artifact('evaluation', type='evaluation')
eval_results.add_file('metrics.json')
eval_results.add_file('confusion_matrix.png')
```

## 進階模式

### 增量 Artifacts (Incremental Artifacts)

無需重新上傳即可逐步新增檔案。

```python
run = wandb.init(project="my-project")

# 建立 artifact
dataset = wandb.Artifact('incremental-dataset', type='dataset')

# 逐步新增檔案
for i in range(100):
    filename = f'batch_{i}.csv'
    process_batch(i, filename)
    dataset.add_file(filename)

    # 記錄進度
    if (i + 1) % 10 == 0:
        print(f"已新增 {i + 1}/100 個批次")

# 記錄完整的 artifact
run.log_artifact(dataset)
```

### Artifact 表格 (Artifact Tables)

使用 W&B Tables 追蹤結構化數據。

```python
import wandb

run = wandb.init(project="my-project")

# 建立表格
table = wandb.Table(columns=["id", "image", "label", "prediction"])

for idx, (img, label, pred) in enumerate(zip(images, labels, predictions)):
    table.add_data(
        idx,
        wandb.Image(img),
        label,
        pred
    )

# 記錄為 artifact
artifact = wandb.Artifact('predictions-table', type='predictions')
artifact.add(table, "predictions")
run.log_artifact(artifact)
```

### Artifact 引用 (Artifact References)

引用外部數據而不進行複製。

```python
# S3 引用
dataset = wandb.Artifact('s3-dataset', type='dataset')
dataset.add_reference('s3://my-bucket/data/', name='train')
dataset.add_reference('s3://my-bucket/labels/', name='labels')

# GCS 引用
dataset.add_reference('gs://my-bucket/data/')

# HTTP 引用
dataset.add_reference('https://example.com/data.zip')

# 本地檔案系統引用（用於共享儲存）
dataset.add_reference('file:///mnt/shared/data')
```

## 協作模式

### 團隊數據集共享

```python
# 數據工程師建立數據集
run = wandb.init(project="data-eng", entity="my-team")
dataset = wandb.Artifact('shared-dataset', type='dataset')
dataset.add_dir('data/')
run.log_artifact(dataset, aliases=['latest', 'production'])

# 機器學習工程師使用數據集
run = wandb.init(project="ml-training", entity="my-team")
dataset = run.use_artifact('my-team/data-eng/shared-dataset:production')
data = load_data(dataset.download())
```

### 模型交接 (Model Handoff)

```python
# 訓練團隊
train_run = wandb.init(project="model-training", entity="ml-team")
model = train_model()
model_artifact = wandb.Artifact('nlp-model', type='model')
model_artifact.add_file('model.pth')
train_run.log_artifact(model_artifact)
train_run.link_artifact(model_artifact, 'model-registry/nlp-models', aliases=['candidate'])

# 評估團隊
eval_run = wandb.init(project="model-eval", entity="ml-team")
model_artifact = eval_run.use_artifact('model-registry/nlp-models/nlp-model:candidate')
metrics = evaluate_model(model_artifact)

if metrics['f1'] > 0.9:
    # 晉升至生產環境
    model_artifact.link('model-registry/nlp-models', aliases=['production'])
```

## 最佳實踐

### 1. 使用具描述性的名稱

```python
# ✅ 建議：具描述性的名稱
wandb.Artifact('imagenet-train-augmented-v2', type='dataset')
wandb.Artifact('bert-base-sentiment-finetuned', type='model')

# ❌ 不建議：過於籠統的名稱
wandb.Artifact('dataset1', type='dataset')
wandb.Artifact('model', type='model')
```

### 2. 提供完整的中繼數據 (Metadata)

```python
model_artifact = wandb.Artifact(
    'production-model',
    type='model',
    description='用於產品分類的 ResNet50 分類器',
    metadata={
        # 模型資訊
        'architecture': 'ResNet50',
        'framework': 'PyTorch 2.0',
        'pretrained': True,

        # 效能
        'accuracy': 0.95,
        'f1_score': 0.93,
        'inference_time_ms': 15,

        # 訓練資訊
        'epochs': 50,
        'dataset': 'imagenet',
        'num_samples': 1200000,

        # 業務情境
        'use_case': '電子商務產品分類',
        'owner': 'ml-team@company.com',
        'approved_by': 'data-science-lead'
    }
)
```

### 3. 使用別名標示部署階段

```python
# 開發階段
run.log_artifact(model, aliases=['dev', 'latest'])

# 預發布階段
run.log_artifact(model, aliases=['staging'])

# 生產階段
run.log_artifact(model, aliases=['production', 'v1.2.0'])

# 封存舊版本
old_artifact = api.artifact('model:production')
old_artifact.aliases = ['archived-v1.1.0']
old_artifact.save()
```

### 4. 追蹤數據血緣 (Track Data Lineage)

```python
def create_training_pipeline():
    run = wandb.init(project="pipeline")

    # 1. 載入原始數據
    raw_data = run.use_artifact('raw-data:latest')

    # 2. 進行預處理
    processed = preprocess(raw_data)
    processed_artifact = wandb.Artifact('processed-data', type='dataset')
    processed_artifact.add_file('processed.csv')
    run.log_artifact(processed_artifact)

    # 3. 訓練模型
    model = train(processed)
    model_artifact = wandb.Artifact('trained-model', type='model')
    model_artifact.add_file('model.pth')
    run.log_artifact(model_artifact)

    # 血緣關係：raw-data → processed-data → trained-model
```

### 5. 高效儲存

```python
# ✅ 建議：引用大型檔案
large_dataset = wandb.Artifact('large-dataset', type='dataset')
large_dataset.add_reference('s3://bucket/huge-file.tar.gz')

# ❌ 不建議：直接上傳大型檔案
# large_dataset.add_file('huge-file.tar.gz')  # 請避免這樣做

# ✅ 建議：僅上傳中繼數據
metadata_artifact = wandb.Artifact('dataset-metadata', type='dataset')
metadata_artifact.add_file('metadata.json')  # 小檔案
```

## 資源

- **Artifacts 官方文件**：https://docs.wandb.ai/guides/artifacts
- **模型註冊表 (Model Registry)**：https://docs.wandb.ai/guides/model-registry
- **最佳實踐**：https://wandb.ai/site/articles/versioning-data-and-models-in-ml
