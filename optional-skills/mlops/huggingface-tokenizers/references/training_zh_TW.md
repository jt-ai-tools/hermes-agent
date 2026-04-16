# 訓練自定義分詞器 (Training Custom Tokenizers)

從零開始訓練分詞器的完整指南。

## 訓練流程 (Training workflow)

### 步驟 1：選擇分詞演算法

**決策樹**：
- **GPT 風格模型** → BPE
- **BERT 風格模型** → WordPiece
- **多語言 / 無單字邊界** → Unigram

### 步驟 2：準備訓練資料

```python
# 選項 1：來自檔案
files = ["train.txt", "validation.txt"]

# 選項 2：來自 Python 清單
texts = [
    "This is the first sentence.",
    "This is the second sentence.",
    # ... 更多文字
]

# 選項 3：來自資料集疊代器 (Dataset iterator)
from datasets import load_dataset

dataset = load_dataset("wikitext", "wikitext-103-raw-v1", split="train")

def batch_iterator(batch_size=1000):
    for i in range(0, len(dataset), batch_size):
        yield dataset[i:i + batch_size]["text"]
```

### 步驟 3：初始化分詞器

**BPE 範例**：
```python
from tokenizers import Tokenizer
from tokenizers.models import BPE
from tokenizers.trainers import BpeTrainer
from tokenizers.pre_tokenizers import ByteLevel
from tokenizers.decoders import ByteLevel as ByteLevelDecoder

tokenizer = Tokenizer(BPE())
tokenizer.pre_tokenizer = ByteLevel()
tokenizer.decoder = ByteLevelDecoder()

trainer = BpeTrainer(
    vocab_size=50000,
    min_frequency=2,
    special_tokens=["<|endoftext|>", "<|padding|>"],
    show_progress=True
)
```

**WordPiece 範例**：
```python
from tokenizers.models import WordPiece
from tokenizers.trainers import WordPieceTrainer
from tokenizers.normalizers import BertNormalizer
from tokenizers.pre_tokenizers import BertPreTokenizer

tokenizer = Tokenizer(WordPiece(unk_token="[UNK]"))
tokenizer.normalizer = BertNormalizer(lowercase=True)
tokenizer.pre_tokenizer = BertPreTokenizer()

trainer = WordPieceTrainer(
    vocab_size=30522,
    min_frequency=2,
    special_tokens=["[UNK]", "[CLS]", "[SEP]", "[PAD]", "[MASK]"],
    continuing_subword_prefix="##",
    show_progress=True
)
```

**Unigram 範例**：
```python
from tokenizers.models import Unigram
from tokenizers.trainers import UnigramTrainer

tokenizer = Tokenizer(Unigram())

trainer = UnigramTrainer(
    vocab_size=8000,
    special_tokens=["<unk>", "<s>", "</s>", "<pad>"],
    unk_token="<unk>",
    show_progress=True
)
```

### 步驟 4：訓練

```python
# 從檔案訓練
tokenizer.train(files=files, trainer=trainer)

# 從疊代器訓練（推薦用於大型資料集）
tokenizer.train_from_iterator(
    batch_iterator(),
    trainer=trainer,
    length=len(dataset)  # 選填，用於顯示進度條
)
```

**訓練時間**（在 16 核 CPU 上訓練 3 萬詞彙量）：
- 10 MB：15-30 秒
- 100 MB：1-3 分鐘
- 1 GB：15-30 分鐘
- 10 GB：2-4 小時

### 步驟 5：添加後處理 (Post-processing)

```python
from tokenizers.processors import TemplateProcessing

# BERT 風格
tokenizer.post_processor = TemplateProcessing(
    single="[CLS] $A [SEP]",
    pair="[CLS] $A [SEP] $B [SEP]",
    special_tokens=[
        ("[CLS]", tokenizer.token_to_id("[CLS]")),
        ("[SEP]", tokenizer.token_to_id("[SEP]")),
    ],
)

# GPT-2 風格
tokenizer.post_processor = TemplateProcessing(
    single="$A <|endoftext|>",
    special_tokens=[
        ("<|endoftext|>", tokenizer.token_to_id("<|endoftext|>")),
    ],
)
```

### 步驟 6：儲存

```python
# 儲存為 JSON
tokenizer.save("my-tokenizer.json")

# 儲存至目錄（用於 transformers）
tokenizer.save("my-tokenizer-dir/tokenizer.json")

# 轉換為 transformers 格式
from transformers import PreTrainedTokenizerFast

transformers_tokenizer = PreTrainedTokenizerFast(
    tokenizer_object=tokenizer,
    unk_token="[UNK]",
    pad_token="[PAD]",
    cls_token="[CLS]",
    sep_token="[SEP]",
    mask_token="[MASK]"
)

transformers_tokenizer.save_pretrained("my-tokenizer-dir")
```

## 訓練器組態 (Trainer configuration)

### BpeTrainer 參數

```python
from tokenizers.trainers import BpeTrainer

trainer = BpeTrainer(
    vocab_size=30000,              # 目標詞彙量
    min_frequency=2,               # 合併規則的最小頻率
    special_tokens=["[UNK]"],      # 特殊 token (優先添加)
    limit_alphabet=1000,           # 限制初始字母表大小
    initial_alphabet=[],           # 預定義的初始字元
    show_progress=True,            # 顯示進度條
    continuing_subword_prefix="",  # 後續子詞的前綴
    end_of_word_suffix=""          # 單字結尾的後綴
)
```

**參數調優**：
- **vocab_size**：英文建議從 3 萬開始，多語言建議 5 萬。
- **min_frequency**：大型語料庫建議 2-5，小型語料庫建議 1。
- **limit_alphabet**：非英語（如中日韓文字 CJK）建議調低。

### WordPieceTrainer 參數

```python
from tokenizers.trainers import WordPieceTrainer

trainer = WordPieceTrainer(
    vocab_size=30522,              # BERT 使用 30,522
    min_frequency=2,
    special_tokens=["[UNK]", "[CLS]", "[SEP]", "[PAD]", "[MASK]"],
    limit_alphabet=1000,
    continuing_subword_prefix="##", # BERT 風格前綴
    show_progress=True
)
```

### UnigramTrainer 參數

```python
from tokenizers.trainers import UnigramTrainer

trainer = UnigramTrainer(
    vocab_size=8000,               # 通常比 BPE/WordPiece 小
    special_tokens=["<unk>", "<s>", "</s>"],
    unk_token="<unk>",
    max_piece_length=16,           # 最大 token 長度
    n_sub_iterations=2,            # EM 演算法疊代次數
    shrinking_factor=0.75,         # 詞彙縮減速率
    show_progress=True
)
```

## 從大型資料集訓練

### 記憶體節省訓練 (Memory-efficient training)

```python
from datasets import load_dataset
from tokenizers import Tokenizer
from tokenizers.models import BPE
from tokenizers.trainers import BpeTrainer

# 載入資料集
dataset = load_dataset("wikipedia", "20220301.en", split="train", streaming=True)

# 建立批次疊代器 (yields batches)
def batch_iterator(batch_size=1000):
    batch = []
    for sample in dataset:
        batch.append(sample["text"])
        if len(batch) >= batch_size:
            yield batch
            batch = []
    if batch:
        yield batch

# 初始化分詞器
tokenizer = Tokenizer(BPE())
trainer = BpeTrainer(vocab_size=50000, special_tokens=["<|endoftext|>"])

# 訓練（記憶體節省 - 透過串流讀取資料）
tokenizer.train_from_iterator(
    batch_iterator(),
    trainer=trainer
)
```

**記憶體使用量**：約 200 MB（相較於載入完整資料集的 10+ GB）。

### 多檔案訓練 (Multi-file training)

```python
import glob

# 尋找所有訓練檔案
files = glob.glob("data/train/*.txt")
print(f"正在對 {len(files)} 個檔案進行訓練")

# 對所有檔案進行訓練
tokenizer.train(files=files, trainer=trainer)
```

### 平行訓練 (多處理平行化)

```python
from multiprocessing import Pool, cpu_count
import os

def train_shard(shard_files):
    """在檔案分片上訓練分詞器。"""
    tokenizer = Tokenizer(BPE())
    trainer = BpeTrainer(vocab_size=50000)
    tokenizer.train(files=shard_files, trainer=trainer)
    return tokenizer.get_vocab()

# 將檔案分割成分片
num_shards = cpu_count()
file_shards = [files[i::num_shards] for i in range(num_shards)]

# 平行訓練分片
with Pool(num_shards) as pool:
    vocab_shards = pool.map(train_shard, file_shards)

# 合併詞彙表（需要自定義邏輯）
# 這是簡化範例 - 實際實作需智慧地合併
final_vocab = {}
for vocab in vocab_shards:
    final_vocab.update(vocab)
```

## 特定領域的分詞器

### 程式碼分詞器 (Code tokenizer)

```python
from tokenizers import Tokenizer
from tokenizers.models import BPE
from tokenizers.trainers import BpeTrainer
from tokenizers.pre_tokenizers import ByteLevel
from tokenizers.normalizers import Sequence, NFC

# 程式碼最佳化組態
tokenizer = Tokenizer(BPE())

# 最低限度正規化（保留大小寫、空格）
tokenizer.normalizer = NFC()  # 僅進行 Unicode 正規化

# 位元組層級前分詞（處理所有字元）
tokenizer.pre_tokenizer = ByteLevel()

# 在程式碼語料庫上訓練
trainer = BpeTrainer(
    vocab_size=50000,
    special_tokens=["<|endoftext|>", "<|pad|>"],
    min_frequency=2
)

tokenizer.train(files=["code_corpus.txt"], trainer=trainer)
```

### 醫療 / 科學分詞器

```python
# 保留大小寫與特殊字元
from tokenizers.normalizers import NFKC
from tokenizers.pre_tokenizers import Whitespace, Punctuation, Sequence

tokenizer = Tokenizer(BPE())

# 最低限度正規化
tokenizer.normalizer = NFKC()

# 保留醫療術語
tokenizer.pre_tokenizer = Sequence([
    Whitespace(),
    Punctuation(behavior="isolated")  # 保持標點符號分離
])

trainer = BpeTrainer(
    vocab_size=50000,
    special_tokens=["[UNK]", "[CLS]", "[SEP]"],
    min_frequency=3  # 為罕見醫療術語設定較高閾值
)

tokenizer.train(files=["pubmed_corpus.txt"], trainer=trainer)
```

### 多語言分詞器

```python
# 處理多種書寫系統
from tokenizers.normalizers import NFKC, Lowercase, Sequence

tokenizer = Tokenizer(BPE())

# 正規化但不小寫化（保留書寫系統差異）
tokenizer.normalizer = NFKC()

# 位元組層級可處理所有 Unicode
from tokenizers.pre_tokenizers import ByteLevel
tokenizer.pre_tokenizer = ByteLevel()

trainer = BpeTrainer(
    vocab_size=100000,  # 為多種語言設定更大的詞彙量
    special_tokens=["<unk>", "<s>", "</s>"],
    limit_alphabet=None  # 不限限制（處理所有書寫系統）
)

# 在多語言語料庫上訓練
tokenizer.train(files=["multilingual_corpus.txt"], trainer=trainer)
```

## 詞彙表大小 (Vocab size) 選擇

### 各項任務指南

| 任務 | 推薦詞彙量 | 原理 |
|-----------------------|------------------------|-----------|
| 英語（單一語言） | 30,000 - 50,000 | 覆蓋率平衡 |
| 多語言 | 50,000 - 250,000 | 語言越多 = 需要更多 token |
| 程式碼 | 30,000 - 50,000 | 與英語相似 |
| 特定領域 | 10,000 - 30,000 | 較小且專注的詞彙量 |
| 字元層級任務 | 1,000 - 5,000 | 僅字元 + 子詞 |

### 詞彙量大小的影響

**小詞彙量 (10k)**：
- 優點：訓練更快、模型更小、記憶體需求更低。
- 缺點：每個句子產生的 token 更多，詞彙表外 (OOV) 處理較差。

**中詞彙量 (30k-50k)**：
- 優點：平衡良好，標準選擇。
- 缺點：無（推薦作為預設）。

**大詞彙量 (100k+)**：
- 優點：每個句子產生的 token 較少，OOV 處理更佳。
- 缺點：訓練更慢，嵌入表 (Embedding table) 更大。

### 經驗測試

```python
# 用不同的詞彙量訓練多個分詞器
vocab_sizes = [10000, 30000, 50000, 100000]

for vocab_size in vocab_sizes:
    tokenizer = Tokenizer(BPE())
    trainer = BpeTrainer(vocab_size=vocab_size)
    tokenizer.train(files=["sample.txt"], trainer=trainer)

    # 在測試集上評估
    test_text = "Test sentence for evaluation..."
    tokens = tokenizer.encode(test_text).ids

    print(f"Vocab: {vocab_size:6d} | Tokens: {len(tokens):3d} | Avg: {len(test_text)/len(tokens):.2f} chars/token")

# 範例輸出：
# Vocab:  10000 | Tokens:  12 | Avg: 2.33 chars/token
# Vocab:  30000 | Tokens:   8 | Avg: 3.50 chars/token
# Vocab:  50000 | Tokens:   7 | Avg: 4.00 chars/token
# Vocab: 100000 | Tokens:   6 | Avg: 4.67 chars/token
```

## 測試分詞器品質

### 覆蓋率測試 (Coverage test)

```python
# 在保留資料 (held-out data) 上測試
test_corpus = load_dataset("wikitext", "wikitext-103-raw-v1", split="test")

total_tokens = 0
unk_tokens = 0
unk_id = tokenizer.token_to_id("[UNK]")

for text in test_corpus["text"]:
    if text.strip():
        encoding = tokenizer.encode(text)
        total_tokens += len(encoding.ids)
        unk_tokens += encoding.ids.count(unk_id)

unk_rate = unk_tokens / total_tokens
print(f"未知 token 比率: {unk_rate:.2%}")

# 品質良好：<1% 未知 token
# 可接受：1-5%
# 品質欠佳：>5%
```

### 壓縮測試 (Compression test)

```python
# 測量分詞效率
import numpy as np

token_lengths = []

for text in test_corpus["text"][:1000]:
    if text.strip():
        encoding = tokenizer.encode(text)
        chars_per_token = len(text) / len(encoding.ids)
        token_lengths.append(chars_per_token)

avg_chars_per_token = np.mean(token_lengths)
print(f"平均每個 token 的字元數: {avg_chars_per_token:.2f}")

# 良好：4-6 字元/token (英語)
# 可接受：3-4 字元/token
# 品質欠佳：<3 字元/token (壓縮不足)
```

### 語義測試 (Semantic test)

```python
# 手動檢查常見單字 / 片語的分詞情況
test_phrases = [
    "tokenization",
    "machine learning",
    "artificial intelligence",
    "preprocessing",
    "hello world"
]

for phrase in test_phrases:
    tokens = tokenizer.encode(phrase).tokens
    print(f"{phrase:25s} → {tokens}")

# 良好的分詞結果：
# tokenization              → ['token', 'ization']
# machine learning          → ['machine', 'learning']
# artificial intelligence   → ['artificial', 'intelligence']
```

## 疑難排解

### 問題：訓練太慢

**解決方案**：
1. 減小詞彙量。
2. 提高 `min_frequency`。
3. 使用 `limit_alphabet` 減少初始字母表。
4. 先在子集上進行訓練。

```python
# 快速訓練組態
trainer = BpeTrainer(
    vocab_size=20000,      # 較小詞彙量
    min_frequency=5,       # 較高閾值
    limit_alphabet=500,    # 限制字母表
    show_progress=True
)
```

### 問題：未知 token 比率過高

**解決方案**：
1. 增加詞彙量。
2. 降低 `min_frequency`。
3. 檢查正規化（可能過於強力）。

```python
# 提高覆蓋率的組態
trainer = BpeTrainer(
    vocab_size=50000,      # 更大詞彙量
    min_frequency=1,       # 較低閾值
)
```

### 問題：分詞品質欠佳

**解決方案**：
1. 驗證正規化是否符合您的使用案例。
2. 檢查前分詞是否正確分割。
3. 確保訓練資料具備代表性。
4. 嘗試不同的演算法 (BPE vs WordPiece vs Unigram)。

```python
# 調試分詞管線
text = "Sample text to debug"

# 檢查正規化
normalized = tokenizer.normalizer.normalize_str(text)
print(f"正規化後：{normalized}")

# 檢查前分詞
pre_tokens = tokenizer.pre_tokenizer.pre_tokenize_str(text)
print(f"前分詞結果：{pre_tokens}")

# 檢查最終分詞
tokens = tokenizer.encode(text).tokens
print(f"Token 結果：{tokens}")
```

## 最佳實務

1. **使用具代表性的訓練資料** - 匹配您的目標領域。
2. **從標準組態開始** - 如 BERT WordPiece 或 GPT-2 BPE。
3. **在保留資料上測試** - 測量未知 token 比率。
4. **疊代詞彙量大小** - 測試 3 萬、5 萬、10 萬。
5. **將分詞器與模型一起儲存** - 確保可重現性。
6. **為分詞器建立版本** - 追蹤變更以便重現。
7. **記錄特殊 token** - 這對模型訓練至關重要。
