---
name: nemo-curator
description: 用於 LLM 訓練的 GPU 加速資料策劃 (Data Curation)。支援文本/影像/影片/音訊。具備模糊去重 (fuzzy deduplication，快 16 倍)、品質過濾 (30+ 種啟發式方法)、語義去重、PII 脫敏、NSFW 偵測。透過 RAPIDS 在多個 GPU 間進行擴展。用於準備高品質訓練資料集、清理網頁資料或大型語料庫去重。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [nemo-curator, cudf, dask, rapids]
metadata:
  hermes:
    tags: [資料處理, NeMo Curator, 資料策劃, GPU 加速, 去重, 品質過濾, NVIDIA, RAPIDS, PII 脫敏, 多模態, LLM 訓練資料]

---

# NeMo Curator - GPU 加速資料策劃

NVIDIA 的工具包，用於為 LLM 準備高品質的訓練資料。

## 何時使用 NeMo Curator

**在以下情況使用 NeMo Curator：**
- 從網頁抓取內容 (Common Crawl) 準備 LLM 訓練資料
- 需要快速去重 (比 CPU 快 16 倍)
- 策劃多模態資料集 (文本、影像、影片、音訊)
- 過濾低品質或有害內容
- 在 GPU 叢集上擴展資料處理規模

**效能**：
- **模糊去重快 16 倍** (8TB RedPajama v2)
- **總持有成本 (TCO) 降低 40%** (與 CPU 替代方案相比)
- 在 GPU 節點間具備**近乎線性的擴展性**

**改用替代方案**：
- **datatrove**：基於 CPU 的開源資料處理工具
- **dolma**：Allen AI 的資料工具包
- **Ray Data**：通用機器學習資料處理 (不專注於資料策劃)

## 快速入門

### 安裝

```bash
# 文本策劃 (CUDA 12)
uv pip install "nemo-curator[text_cuda12]"

# 所有模態
uv pip install "nemo-curator[all_cuda12]"

# 僅 CPU (較慢)
uv pip install "nemo-curator[cpu]"
```

### 基礎文本策劃管道 (Pipeline)

```python
from nemo_curator import ScoreFilter, Modify
from nemo_curator.datasets import DocumentDataset
import pandas as pd

# 載入資料
df = pd.DataFrame({"text": ["Good document", "Bad doc", "Excellent text"]})
dataset = DocumentDataset(df)

# 品質過濾
def quality_score(doc):
    return len(doc["text"].split()) > 5  # 過濾掉短文檔

filtered = ScoreFilter(quality_score)(dataset)

# 去重
from nemo_curator.modules import ExactDuplicates
deduped = ExactDuplicates()(filtered)

# 儲存
deduped.to_parquet("curated_data/")
```

## 資料策劃管道

### 階段 1：品質過濾

```python
from nemo_curator.filters import (
    WordCountFilter,
    RepeatedLinesFilter,
    UrlRatioFilter,
    NonAlphaNumericFilter
)

# 應用 30+ 種啟發式過濾器
from nemo_curator import ScoreFilter

# 字數過濾器
dataset = dataset.filter(WordCountFilter(min_words=50, max_words=100000))

# 移除重複內容
dataset = dataset.filter(RepeatedLinesFilter(max_repeated_line_fraction=0.3))

# URL 比例過濾器
dataset = dataset.filter(UrlRatioFilter(max_url_ratio=0.2))
```

### 階段 2：去重 (Deduplication)

**精確去重**：
```python
from nemo_curator.modules import ExactDuplicates

# 移除完全相同的重複項
deduped = ExactDuplicates(id_field="id", text_field="text")(dataset)
```

**模糊去重** (在 GPU 上快 16 倍)：
```python
from nemo_curator.modules import FuzzyDuplicates

# MinHash + LSH 去重
fuzzy_dedup = FuzzyDuplicates(
    id_field="id",
    text_field="text",
    num_hashes=260,      # MinHash 參數
    num_buckets=20,
    hash_method="md5"
)

deduped = fuzzy_dedup(dataset)
```

**語義去重**：
```python
from nemo_curator.modules import SemanticDuplicates

# 基於嵌入 (Embedding) 的去重
semantic_dedup = SemanticDuplicates(
    id_field="id",
    text_field="text",
    embedding_model="sentence-transformers/all-MiniLM-L6-v2",
    threshold=0.8  # 餘弦相似度閾值
)

deduped = semantic_dedup(dataset)
```

### 階段 3：PII 脫敏 (個人隱私資訊脫敏)

```python
from nemo_curator.modules import Modify
from nemo_curator.modifiers import PIIRedactor

# 脫敏個人身份識別資訊
pii_redactor = PIIRedactor(
    supported_entities=["EMAIL_ADDRESS", "PHONE_NUMBER", "PERSON", "LOCATION"],
    anonymize_action="replace"  # 或 "redact"
)

redacted = Modify(pii_redactor)(dataset)
```

### 階段 4：分類器過濾

```python
from nemo_curator.classifiers import QualityClassifier

# 品質分類
quality_clf = QualityClassifier(
    model_path="nvidia/quality-classifier-deberta",
    batch_size=256,
    device="cuda"
)

# 過濾低品質文件
high_quality = dataset.filter(lambda doc: quality_clf(doc["text"]) > 0.5)
```

## GPU 加速

### GPU vs CPU 效能

| 操作 | CPU (16 核心) | GPU (A100) | 加速倍數 |
|-----------|----------------|------------|---------|
| 模糊去重 (8TB) | 120 小時 | 7.5 小時 | 16倍 |
| 精確去重 (1TB) | 8 小時 | 0.5 小時 | 16倍 |
| 品質過濾 | 2 小時 | 0.2 小時 | 10倍 |

### 多 GPU 擴展

```python
from nemo_curator import get_client
import dask_cuda

# 初始化 GPU 叢集
client = get_client(cluster_type="gpu", n_workers=8)

# 使用 8 個 GPU 進行處理
deduped = FuzzyDuplicates(...)(dataset)
```

## 多模態策劃

### 影像策劃

```python
from nemo_curator.image import (
    AestheticFilter,
    NSFWFilter,
    CLIPEmbedder
)

# 審美評分
aesthetic_filter = AestheticFilter(threshold=5.0)
filtered_images = aesthetic_filter(image_dataset)

# NSFW 偵測
nsfw_filter = NSFWFilter(threshold=0.9)
safe_images = nsfw_filter(filtered_images)

# 產生 CLIP 嵌入
clip_embedder = CLIPEmbedder(model="openai/clip-vit-base-patch32")
image_embeddings = clip_embedder(safe_images)
```

### 影片策劃

```python
from nemo_curator.video import (
    SceneDetector,
    ClipExtractor,
    InternVideo2Embedder
)

# 偵測場景
scene_detector = SceneDetector(threshold=27.0)
scenes = scene_detector(video_dataset)

# 擷取片段
clip_extractor = ClipExtractor(min_duration=2.0, max_duration=10.0)
clips = clip_extractor(scenes)

# 產生嵌入
video_embedder = InternVideo2Embedder()
video_embeddings = video_embedder(clips)
```

### 音訊策劃

```python
from nemo_curator.audio import (
    ASRInference,
    WERFilter,
    DurationFilter
)

# ASR 轉錄
asr = ASRInference(model="nvidia/stt_en_fastconformer_hybrid_large_pc")
transcribed = asr(audio_dataset)

# 依 WER (字錯率) 過濾
wer_filter = WERFilter(max_wer=0.3)
high_quality_audio = wer_filter(transcribed)

# 時長過濾
duration_filter = DurationFilter(min_duration=1.0, max_duration=30.0)
filtered_audio = duration_filter(high_quality_audio)
```

## 常見模式

### 網頁抓取策劃 (Common Crawl)

```python
from nemo_curator import ScoreFilter, Modify
from nemo_curator.filters import *
from nemo_curator.modules import *
from nemo_curator.datasets import DocumentDataset

# 載入 Common Crawl 資料
dataset = DocumentDataset.read_parquet("common_crawl/*.parquet")

# 管道
pipeline = [
    # 1. 品質過濾
    WordCountFilter(min_words=100, max_words=50000),
    RepeatedLinesFilter(max_repeated_line_fraction=0.2),
    SymbolToWordRatioFilter(max_symbol_to_word_ratio=0.3),
    UrlRatioFilter(max_url_ratio=0.3),

    # 2. 語言過濾
    LanguageIdentificationFilter(target_languages=["en"]),

    # 3. 去重
    ExactDuplicates(id_field="id", text_field="text"),
    FuzzyDuplicates(id_field="id", text_field="text", num_hashes=260),

    # 4. PII 脫敏
    PIIRedactor(),

    # 5. NSFW 過濾
    NSFWClassifier(threshold=0.8)
]

# 執行
for stage in pipeline:
    dataset = stage(dataset)

# 儲存
dataset.to_parquet("curated_common_crawl/")
```

### 分佈式處理

```python
from nemo_curator import get_client
from dask_cuda import LocalCUDACluster

# 多 GPU 叢集
cluster = LocalCUDACluster(n_workers=8)
client = get_client(cluster=cluster)

# 處理大型資料集
dataset = DocumentDataset.read_parquet("s3://large_dataset/*.parquet")
deduped = FuzzyDuplicates(...)(dataset)

# 清理
client.close()
cluster.close()
```

## 效能基準測試

### 模糊去重 (8TB RedPajama v2)

- **CPU (256 核心)**：120 小時
- **GPU (8× A100)**：7.5 小時
- **加速倍數**：16倍

### 精確去重 (1TB)

- **CPU (64 核心)**：8 小時
- **GPU (4× A100)**：0.5 小時
- **加速倍數**：16倍

### 品質過濾 (100GB)

- **CPU (32 核心)**：2 小時
- **GPU (2× A100)**：0.2 小時
- **加速倍數**：10倍

## 成本比較

**基於 CPU 的策劃** (AWS c5.18xlarge × 10)：
- 成本：$3.60/小時 × 10 = $36/小時
- 處理 8TB 所需時間：120 小時
- **總計**：$4,320

**基於 GPU 的策劃** (AWS p4d.24xlarge × 2)：
- 成本：$32.77/小時 × 2 = $65.54/小時
- 處理 8TB 所需時間：7.5 小時
- **總計**：$491.55

**省下金額**：成本降低 89% (節省了 $3,828)

## 支援的資料格式

- **輸入**：Parquet, JSONL, CSV
- **輸出**：Parquet (推薦), JSONL
- **WebDataset**：用於多模態的 TAR 封存檔

## 使用案例

**生產環境部署**：
- NVIDIA 使用 NeMo Curator 準備 Nemotron-4 訓練資料
- 已策劃的開源資料集：RedPajama v2, The Pile

## 參考資料

- **[過濾指南](references/filtering.md)** - 30+ 種品質過濾器、啟發式方法
- **[去重指南](references/deduplication.md)** - 精確、模糊、語義去重方法

## 資源

- **GitHub**: https://github.com/NVIDIA/NeMo-Curator ⭐ 500+
- **文件**: https://docs.nvidia.com/nemo-framework/user-guide/latest/datacuration/
- **版本**: 0.4.0+
- **授權**: Apache 2.0
