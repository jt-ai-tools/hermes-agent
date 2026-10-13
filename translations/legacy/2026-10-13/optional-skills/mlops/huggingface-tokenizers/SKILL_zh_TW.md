---
name: huggingface-tokenizers
description: 針對研究與生產環境優化的快速分詞器 (Tokenizers)。基於 Rust 的實作可在 20 秒內完成 1GB 文本的分詞。支援 BPE、WordPiece 和 Unigram 演算法。可訓練自訂詞表、追蹤對齊資訊、處理填充與截斷。與 transformers 無縫整合。當您需要高效能分詞或訓練自訂分詞器時使用。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [tokenizers, transformers, datasets]
metadata:
  hermes:
    tags: [分詞, Tokenization, HuggingFace, BPE, WordPiece, Unigram, 快速分詞, Rust, 自訂分詞器, 對齊追蹤, 生產環境]

---

# HuggingFace Tokenizers - 用於 NLP 的快速分詞

快速、生產就緒的分詞器，具備 Rust 的效能與 Python 的易用性。

## 何時使用 HuggingFace Tokenizers

**在以下情況使用 HuggingFace Tokenizers：**
- 需要極快的分詞速度 (每 GB 文本少於 20 秒)
- 從頭開始訓練自訂分詞器
- 需要對齊追蹤 (Token → 原始文本位置)
- 建立生產級 NLP 管道
- 需要高效處理大型語料庫

**效能**：
- **速度**：在 CPU 上分詞 1GB 少於 20 秒
- **實作**：Rust 核心搭配 Python/Node.js 綁定
- **效率**：比純 Python 實作快 10-100 倍

**改用替代方案**：
- **SentencePiece**：語言無關，由 T5/ALBERT 使用
- **tiktoken**：OpenAI 用於 GPT 模型的 BPE 分詞器
- **transformers AutoTokenizer**：僅用於載入預訓練模型 (內部使用此庫)

## 快速入門

### 安裝

```bash
# 安裝 tokenizers
pip install tokenizers

# 包含 transformers 整合
pip install tokenizers transformers
```

### 載入預訓練分詞器

```python
from tokenizers import Tokenizer

# 從 HuggingFace Hub 載入
tokenizer = Tokenizer.from_pretrained("bert-base-uncased")

# 編碼文本
output = tokenizer.encode("Hello, how are you?")
print(output.tokens)  # ['hello', ',', 'how', 'are', 'you', '?']
print(output.ids)     # [7592, 1010, 2129, 2024, 2017, 1029]

# 解碼回文本
text = tokenizer.decode(output.ids)
print(text)  # "hello, how are you?"
```

### 訓練自訂 BPE 分詞器

```python
from tokenizers import Tokenizer
from tokenizers.models import BPE
from tokenizers.trainers import BpeTrainer
from tokenizers.pre_tokenizers import Whitespace

# 使用 BPE 模型初始化分詞器
tokenizer = Tokenizer(BPE(unk_token="[UNK]"))
tokenizer.pre_tokenizer = Whitespace()

# 配置訓練器
trainer = BpeTrainer(
    vocab_size=30000,
    special_tokens=["[UNK]", "[CLS]", "[SEP]", "[PAD]", "[MASK]"],
    min_frequency=2
)

# 在檔案上進行訓練
files = ["train.txt", "validation.txt"]
tokenizer.train(files, trainer)

# 儲存
tokenizer.save("my-tokenizer.json")
```

**訓練時間**：100MB 語料庫約 1-2 分鐘，1GB 約 10-20 分鐘

### 帶填充 (Padding) 的批次編碼

```python
# 啟用填充
tokenizer.enable_padding(pad_id=3, pad_token="[PAD]")

# 批次編碼
texts = ["Hello world", "This is a longer sentence"]
encodings = tokenizer.encode_batch(texts)

for encoding in encodings:
    print(encoding.ids)
# [101, 7592, 2088, 102, 3, 3, 3]
# [101, 2023, 2003, 1037, 2936, 6251, 102]
```

## 分詞演算法

### BPE (Byte-Pair Encoding, 位元組對編碼)

**工作原理**：
1. 從字元級詞彙表開始
2. 找出最頻繁出現的字元對
3. 合併為新的 Token，加入詞彙表
4. 重複直到達到詞彙表大小

**使用者**：GPT-2, GPT-3, RoBERTa, BART, DeBERTa

```python
from tokenizers import Tokenizer
from tokenizers.models import BPE
from tokenizers.trainers import BpeTrainer
from tokenizers.pre_tokenizers import ByteLevel

tokenizer = Tokenizer(BPE(unk_token="<|endoftext|>"))
tokenizer.pre_tokenizer = ByteLevel()

trainer = BpeTrainer(
    vocab_size=50257,
    special_tokens=["<|endoftext|>"],
    min_frequency=2
)

tokenizer.train(files=["data.txt"], trainer=trainer)
```

**優點**：
- 良好處理未登錄詞 (OOV) (分解為子詞)
- 靈活的詞彙表大小
- 適用於形態豐富的語言

**權衡**：
- 分詞結果取決於合併順序
- 可能會以非預期方式拆分常見單詞

### WordPiece

**工作原理**：
1. 從字元詞彙表開始
2. 計算合併對分數：`frequency(pair) / (frequency(first) × frequency(second))`
3. 合併分數最高的一對
4. 重複直到達到詞彙表大小

**使用者**：BERT, DistilBERT, MobileBERT

```python
from tokenizers import Tokenizer
from tokenizers.models import WordPiece
from tokenizers.trainers import WordPieceTrainer
from tokenizers.pre_tokenizers import Whitespace
from tokenizers.normalizers import BertNormalizer

tokenizer = Tokenizer(WordPiece(unk_token="[UNK]"))
tokenizer.normalizer = BertNormalizer(lowercase=True)
tokenizer.pre_tokenizer = Whitespace()

trainer = WordPieceTrainer(
    vocab_size=30522,
    special_tokens=["[UNK]", "[CLS]", "[SEP]", "[PAD]", "[MASK]"],
    continuing_subword_prefix="##"
)

tokenizer.train(files=["corpus.txt"], trainer=trainer)
```

**優點**：
- 優先合併有意義的內容 (高分 = 語義相關)
- 在 BERT 中成功應用 (達到最先進的結果)

**權衡**：
- 如果沒有子詞匹配，未知詞會變成 `[UNK]`
- 儲存詞彙表而非合併規則 (檔案較大)

### Unigram

**工作原理**：
1. 從大型詞彙表 (所有子字串) 開始
2. 計算當前詞彙表對語料庫的損失 (loss)
3. 移除對損失影響最小的 Token
4. 重複直到達到詞彙表大小

**使用者**：ALBERT, T5, mBART, XLNet (透過 SentencePiece)

```python
from tokenizers import Tokenizer
from tokenizers.models import Unigram
from tokenizers.trainers import UnigramTrainer

tokenizer = Tokenizer(Unigram())

trainer = UnigramTrainer(
    vocab_size=8000,
    special_tokens=["<unk>", "<s>", "</s>"],
    unk_token="<unk>"
)

tokenizer.train(files=["data.txt"], trainer=trainer)
```

**優點**：
- 機率性 (尋找最可能的 Tokenization)
- 適用於沒有單詞邊界的語言
- 處理多樣的語言上下文

**權衡**：
- 訓練計算成本高
- 有更多超參數需要調優

## 分詞管道 (Pipeline)

完整管道：**正規化 (Normalization) → 預分詞 (Pre-tokenization) → 模型 → 後處理 (Post-processing)**

### 正規化 (Normalization)

清理並標準化文本：

```python
from tokenizers.normalizers import NFD, StripAccents, Lowercase, Sequence

tokenizer.normalizer = Sequence([
    NFD(),           # Unicode 正規化 (分解)
    Lowercase(),     # 轉換為小寫
    StripAccents()   # 移除變音符號
])

# 輸入: "Héllo WORLD"
# 正規化後: "hello world"
```

**常用正規化器**：
- `NFD`, `NFC`, `NFKD`, `NFKC` - Unicode 正規化形式
- `Lowercase()` - 轉換為小寫
- `StripAccents()` - 移除變音符號 (é → e)
- `Strip()` - 移除空白
- `Replace(pattern, content)` - 正則表達式替換

### 預分詞 (Pre-tokenization)

將文本拆分為類似單詞的單元：

```python
from tokenizers.pre_tokenizers import Whitespace, Punctuation, Sequence, ByteLevel

# 在空白和標點符號處拆分
tokenizer.pre_tokenizer = Sequence([
    Whitespace(),
    Punctuation()
])

# 輸入: "Hello, world!"
# 預分詞後: ["Hello", ",", "world", "!"]
```

**常用預分詞器**：
- `Whitespace()` - 在空格、定位符、換行符處拆分
- `ByteLevel()` - GPT-2 風格的位元組級拆分
- `Punctuation()` - 分離標點符號
- `Digits(individual_digits=True)` - 單獨拆分數字
- `Metaspace()` - 將空格替換為 ▁ (SentencePiece 風格)

### 後處理 (Post-processing)

為模型輸入新增特殊 Token：

```python
from tokenizers.processors import TemplateProcessing

# BERT 風格: [CLS] sentence [SEP]
tokenizer.post_processor = TemplateProcessing(
    single="[CLS] $A [SEP]",
    pair="[CLS] $A [SEP] $B [SEP]",
    special_tokens=[
        ("[CLS]", 1),
        ("[SEP]", 2),
    ],
)
```

**常見模式**：
```python
# GPT-2: sentence <|endoftext|>
TemplateProcessing(
    single="$A <|endoftext|>",
    special_tokens=[("<|endoftext|>", 50256)]
)

# RoBERTa: <s> sentence </s>
TemplateProcessing(
    single="<s> $A </s>",
    pair="<s> $A </s> </s> $B </s>",
    special_tokens=[("<s>", 0), ("</s>", 2)]
)
```

## 對齊追蹤 (Alignment tracking)

追蹤 Token 在原始文本中的位置：

```python
output = tokenizer.encode("Hello, world!")

# 獲取 Token 偏移量
for token, offset in zip(output.tokens, output.offsets):
    start, end = offset
    print(f"{token:10} → [{start:2}, {end:2}): {text[start:end]!r}")

# 輸出:
# hello      → [ 0,  5): 'Hello'
# ,          → [ 5,  6): ','
# world      → [ 7, 12): 'world'
# !          → [12, 13): '!'
```

**使用案例**：
- 命名實體識別 (將預測結果映射回文本)
- 問答系統 (擷取答案片段)
- Token 分類 (將標籤與原始位置對齊)

## 與 transformers 整合

### 使用 AutoTokenizer 載入

```python
from transformers import AutoTokenizer

# AutoTokenizer 會自動使用快速分詞器 (Fast Tokenizers)
tokenizer = AutoTokenizer.from_pretrained("bert-base-uncased")

# 檢查是否使用快速分詞器
print(tokenizer.is_fast)  # True

# 存取底層的 tokenizers.Tokenizer
fast_tokenizer = tokenizer.backend_tokenizer
print(type(fast_tokenizer))  # <class 'tokenizers.Tokenizer'>
```

### 將自訂分詞器轉換為 transformers

```python
from tokenizers import Tokenizer
from transformers import PreTrainedTokenizerFast

# 訓練自訂分詞器
tokenizer = Tokenizer(BPE())
# ... 訓練分詞器 ...
tokenizer.save("my-tokenizer.json")

# 為 transformers 進行封裝
transformers_tokenizer = PreTrainedTokenizerFast(
    tokenizer_file="my-tokenizer.json",
    unk_token="[UNK]",
    pad_token="[PAD]",
    cls_token="[CLS]",
    sep_token="[SEP]",
    mask_token="[MASK]"
)

# 像使用任何 transformers 分詞器一樣使用它
outputs = transformers_tokenizer(
    "Hello world",
    padding=True,
    truncation=True,
    max_length=512,
    return_tensors="pt"
)
```

## 常見模式

### 從迭代器訓練 (大型資料集)

```python
from datasets import load_dataset

# 載入資料集
dataset = load_dataset("wikitext", "wikitext-103-raw-v1", split="train")

# 建立批次迭代器
def batch_iterator(batch_size=1000):
    for i in range(0, len(dataset), batch_size):
        yield dataset[i:i + batch_size]["text"]

# 訓練分詞器
tokenizer.train_from_iterator(
    batch_iterator(),
    trainer=trainer,
    length=len(dataset)  # 用於進度條
)
```

**效能**：在 10-20 分鐘內處理 1GB

### 啟用截斷與填充

```python
# 啟用截斷
tokenizer.enable_truncation(max_length=512)

# 啟用填充
tokenizer.enable_padding(
    pad_id=tokenizer.token_to_id("[PAD]"),
    pad_token="[PAD]",
    length=512  # 固定長度，或為 None 以使用批次最大長度
)

# 同時使用兩者進行編碼
output = tokenizer.encode("This is a long sentence that will be truncated...")
print(len(output.ids))  # 512
```

### 多進程處理

```python
from tokenizers import Tokenizer
from multiprocessing import Pool

# 載入分詞器
tokenizer = Tokenizer.from_file("tokenizer.json")

def encode_batch(texts):
    return tokenizer.encode_batch(texts)

# 並行處理大型語料庫
with Pool(8) as pool:
    # 將語料庫拆分為區塊
    chunk_size = 1000
    chunks = [corpus[i:i+chunk_size] for i in range(0, len(corpus), chunk_size)]

    # 並行編碼
    results = pool.map(encode_batch, chunks)
```

**加速**：使用 8 核心可提速 5-8 倍

## 效能基準測試

### 訓練速度

| 語料庫大小 | BPE (30k 詞表) | WordPiece (30k) | Unigram (8k) |
|-------------|-----------------|-----------------|--------------|
| 10 MB       | 15 秒          | 18 秒          | 25 秒       |
| 100 MB      | 1.5 分鐘       | 2 分鐘         | 4 分鐘       |
| 1 GB        | 15 分鐘        | 20 分鐘        | 40 分鐘      |

**硬體**：16 核心 CPU，在英文維基百科上測試

### 分詞速度

| 實作方式 | 1 GB 語料庫 | 吞吐量 |
|----------------|-------------|---------------|
| 純 Python    | ~20 分鐘    | ~50 MB/分    |
| HF Tokenizers  | ~15 秒      | ~4 GB/分     |
| **加速倍數**    | **80倍**     | **80倍**       |

**測試**：英文文本，平均句子長度 20 個單詞

### 記憶體使用

| 任務 | 記憶體 |
|-------------------------|---------|
| 載入分詞器 | ~10 MB  |
| 訓練 BPE (30k 詞表) | ~200 MB |
| 編碼 100 萬個句子 | ~500 MB |

## 支援的模型

可透過 `from_pretrained()` 取得預訓練分詞器：

**BERT 系列**：
- `bert-base-uncased`, `bert-large-cased`
- `distilbert-base-uncased`
- `roberta-base`, `roberta-large`

**GPT 系列**：
- `gpt2`, `gpt2-medium`, `gpt2-large`
- `distilgpt2`

**T5 系列**：
- `t5-small`, `t5-base`, `t5-large`
- `google/flan-t5-xxl`

**其他**：
- `facebook/bart-base`, `facebook/mbart-large-cc25`
- `albert-base-v2`, `albert-xlarge-v2`
- `xlm-roberta-base`, `xlm-roberta-large`

瀏覽所有模型：https://huggingface.co/models?library=tokenizers

## 參考資料

- **[訓練指南](references/training.md)** - 訓練自訂分詞器、配置訓練器、處理大型資料集
- **[演算法深入探討](references/algorithms.md)** - 詳細解釋 BPE、WordPiece、Unigram
- **[管道組件](references/pipeline.md)** - 正規化器、預分詞器、後處理器、解碼器
- **[Transformers 整合](references/integration.md)** - AutoTokenizer, PreTrainedTokenizerFast, 特殊 Token

## 資源

- **文件**：https://huggingface.co/docs/tokenizers
- **GitHub**：https://github.com/huggingface/tokenizers ⭐ 9,000+
- **版本**：0.20.0+
- **課程**：https://huggingface.co/learn/nlp-course/chapter6/1
- **論文**：BPE (Sennrich et al., 2016), WordPiece (Schuster & Nakajima, 2012)
