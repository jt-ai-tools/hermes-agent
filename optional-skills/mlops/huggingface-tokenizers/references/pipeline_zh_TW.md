# 分詞管線元件 (Tokenization Pipeline Components)

正規化器 (Normalizers)、前分詞器 (Pre-tokenizers)、模型 (Models)、後處理器 (Post-processors) 與解碼器 (Decoders) 的完整指南。

## 管線概覽 (Pipeline overview)

**完整分詞管線**：
```
原始文字
  ↓
正規化 (Normalization，包含清理、小寫化)
  ↓
前分詞 (Pre-tokenization，將文字分割成詞)
  ↓
模型 (Model，套用 BPE/WordPiece/Unigram)
  ↓
後處理 (Post-processing，添加特殊 token)
  ↓
Token ID
```

**解碼過程則相反**：
```
Token ID
  ↓
解碼器 (Decoder，處理特殊編碼)
  ↓
原始文字
```

## 正規化器 (Normalizers)

清理並標準化輸入文字。

### 常見正規化器

**小寫化 (Lowercase)**：
```python
from tokenizers.normalizers import Lowercase

tokenizer.normalizer = Lowercase()

# 輸入："Hello WORLD"
# 輸出："hello world"
```

**Unicode 正規化**：
```python
from tokenizers.normalizers import NFD, NFC, NFKD, NFKC

# NFD：規範分解 (Canonical decomposition)
tokenizer.normalizer = NFD()
# "é" → "e" + "́" (分開的字元)

# NFC：規範組合 (Canonical composition，預設)
tokenizer.normalizer = NFC()
# "e" + "́" → "é" (組合後的字元)

# NFKD：相容分解 (Compatibility decomposition)
tokenizer.normalizer = NFKD()
# "ﬁ" → "f" + "i"

# NFKC：相容組合 (Compatibility composition)
tokenizer.normalizer = NFKC()
# 最強力的正規化方式
```

**移除重音符號 (Strip accents)**：
```python
from tokenizers.normalizers import StripAccents

tokenizer.normalizer = StripAccents()

# 輸入："café"
# 輸出："cafe"
```

**空白字元處理 (Whitespace handling)**：
```python
from tokenizers.normalizers import Strip, StripAccents

# 移除前後空白
tokenizer.normalizer = Strip()

# 輸入："  hello  "
# 輸出："hello"
```

**替換模式 (Replace patterns)**：
```python
from tokenizers.normalizers import Replace

# 將換行符號替換為空格
tokenizer.normalizer = Replace("\\n", " ")

# 輸入："hello\\nworld"
# 輸出："hello world"
```

### 組合正規化器

```python
from tokenizers.normalizers import Sequence, NFD, Lowercase, StripAccents

# BERT 風格的正規化
tokenizer.normalizer = Sequence([
    NFD(),           # Unicode 分解
    Lowercase(),     # 轉為小寫
    StripAccents()   # 移除重音
])

# 輸入："Café au Lait"
# NFD 後："Café au Lait" (e + ́)
# 小寫化後："café au lait"
# 移除重音後："cafe au lait"
```

### 使用案例範例

**不區分大小寫的模型 (BERT)**：
```python
from tokenizers.normalizers import BertNormalizer

# 一站式 BERT 正規化
tokenizer.normalizer = BertNormalizer(
    clean_text=True,        # 移除控制字元
    handle_chinese_chars=True,  # 在中文周圍添加空格
    strip_accents=True,     # 移除重音
    lowercase=True          # 小寫化
)
```

**區分大小寫的模型 (GPT-2)**：
```python
# 最低限度的正規化
tokenizer.normalizer = NFC()  # 僅進行 Unicode 正規化
```

**多語言模型 (mBERT)**：
```python
# 保留書寫系統，標準化形式
tokenizer.normalizer = NFKC()
```

## 前分詞器 (Pre-tokenizers)

在分詞之前將文字分割成類似詞的單位。

### 空白分割 (Whitespace splitting)

```python
from tokenizers.pre_tokenizers import Whitespace

tokenizer.pre_tokenizer = Whitespace()

# 輸入："Hello world! How are you?"
# 輸出：[("Hello", (0, 5)), ("world!", (6, 12)), ("How", (13, 16)), ("are", (17, 20)), ("you?", (21, 25))]
```

### 標點符號隔離 (Punctuation isolation)

```python
from tokenizers.pre_tokenizers import Punctuation

tokenizer.pre_tokenizer = Punctuation()

# 輸入："Hello, world!"
# 輸出：[("Hello", ...), (",", ...), ("world", ...), ("!", ...)]
```

### 位元組層級 (Byte-level，GPT-2)

```python
from tokenizers.pre_tokenizers import ByteLevel

tokenizer.pre_tokenizer = ByteLevel(add_prefix_space=True)

# 輸入："Hello world"
# 輸出：帶有 Ġ 前綴表示空格的位元組層級 token
# [("ĠHello", ...), ("Ġworld", ...)]
```

**關鍵特性**：處理所有 Unicode 字元（256 個位元組組合）。

### Metaspace (SentencePiece)

```python
from tokenizers.pre_tokenizers import Metaspace

tokenizer.pre_tokenizer = Metaspace(replacement="▁", add_prefix_space=True)

# 輸入："Hello world"
# 輸出：[("▁Hello", ...), ("▁world", ...)]
```

**使用者**：T5、ALBERT (透過 SentencePiece)。

### 數字分割 (Digits splitting)

```python
from tokenizers.pre_tokenizers import Digits

# 個別分割數字
tokenizer.pre_tokenizer = Digits(individual_digits=True)

# 輸入："Room 123"
# 輸出：[("Room", ...), ("1", ...), ("2", ...), ("3", ...)]

# 將數字保持在一起
tokenizer.pre_tokenizer = Digits(individual_digits=False)

# 輸入："Room 123"
# 輸出：[("Room", ...), ("123", ...)]
```

### BERT 前分詞器

```python
from tokenizers.pre_tokenizers import BertPreTokenizer

tokenizer.pre_tokenizer = BertPreTokenizer()

# 根據空白與標點符號分割，並保留中日韓文字 (CJK)
# 輸入："Hello, 世界!"
# 輸出：[("Hello", ...), (",", ...), ("世", ...), ("界", ...), ("!", ...)]
```

### 組合前分詞器

```python
from tokenizers.pre_tokenizers import Sequence, Whitespace, Punctuation

tokenizer.pre_tokenizer = Sequence([
    Whitespace(),     # 先根據空白分割
    Punctuation()     # 再隔離標點符號
])

# 輸入："Hello, world!"
# 空白分割後：[("Hello,", ...), ("world!", ...)]
# 標點符號隔離後：[("Hello", ...), (",", ...), ("world", ...), ("!", ...)]
```

### 前分詞器比較

| 前分詞器 | 使用案例 | 範例 |
|-------------------|---------------------------------|--------------------------------------------|
| Whitespace        | 簡單英文 | "Hello world" → ["Hello", "world"] |
| Punctuation       | 隔離符號 | "world!" → ["world", "!"] |
| ByteLevel         | 多語言、表情符號 | "🌍" → 位元組 token |
| Metaspace         | SentencePiece 風格 | "Hello" → ["▁Hello"] |
| BertPreTokenizer  | BERT 風格 (支援 CJK) | "世界" → ["世", "界"] |
| Digits            | 處理數字 | "123" → ["1", "2", "3"] 或 ["123"] |

## 模型 (Models)

核心分詞演算法。

### BPE 模型

```python
from tokenizers.models import BPE

model = BPE(
    vocab=None,           # 或提供預先建立的詞彙表 (vocab)
    merges=None,          # 或提供合併規則 (merges)
    unk_token="[UNK]",    # 未知 token
    continuing_subword_prefix="",
    end_of_word_suffix="",
    fuse_unk=False        # 保持未知 token 分離
)

tokenizer = Tokenizer(model)
```

**參數**：
- `vocab`：token → id 的字典
- `merges`：合併規則清單，例如 `["a b", "ab c"]`
- `unk_token`：未知單字的 token
- `continuing_subword_prefix`：子詞 (subword) 的前綴（GPT-2 為空）
- `end_of_word_suffix`：最後一個子詞的後綴（GPT-2 為空）

### WordPiece 模型

```python
from tokenizers.models import WordPiece

model = WordPiece(
    vocab=None,
    unk_token="[UNK]",
    max_input_chars_per_word=100,  # 單字最大長度
    continuing_subword_prefix="##"  # BERT 風格前綴
)

tokenizer = Tokenizer(model)
```

**關鍵差異**：對後續子詞使用 `##` 前綴。

### Unigram 模型

```python
from tokenizers.models import Unigram

model = Unigram(
    vocab=None,  # (token, score) 元組清單
    unk_id=0,    # 未知 token 的 ID
    byte_fallback=False  # 若無匹配則回退到位元組
)

tokenizer = Tokenizer(model)
```

**機率式**：選擇機率最高的分詞方式。

### WordLevel 模型

```python
from tokenizers.models import WordLevel

# 簡單的單字對應 ID 映射（無子詞）
model = WordLevel(
    vocab=None,
    unk_token="[UNK]"
)

tokenizer = Tokenizer(model)
```

**警告**：需要龐大的詞彙表（每個單字一個 token）。

## 後處理器 (Post-processors)

添加特殊 token 並格式化輸出。

### 範本處理 (Template processing)

**BERT 風格** (`[CLS] sentence [SEP]`)：
```python
from tokenizers.processors import TemplateProcessing

tokenizer.post_processor = TemplateProcessing(
    single="[CLS] $A [SEP]",
    pair="[CLS] $A [SEP] $B [SEP]",
    special_tokens=[
        ("[CLS]", 101),
        ("[SEP]", 102),
    ],
)

# 單一句子
output = tokenizer.encode("Hello world")
# [101, ..., 102]  ([CLS] hello world [SEP])

# 句子對
output = tokenizer.encode("Hello", "world")
# [101, ..., 102, ..., 102]  ([CLS] hello [SEP] world [SEP])
```

**GPT-2 風格** (`sentence <|endoftext|>`)：
```python
tokenizer.post_processor = TemplateProcessing(
    single="$A <|endoftext|>",
    special_tokens=[
        ("<|endoftext|>", 50256),
    ],
)
```

**RoBERTa 風格** (`<s> sentence </s>`)：
```python
tokenizer.post_processor = TemplateProcessing(
    single="<s> $A </s>",
    pair="<s> $A </s> </s> $B </s>",
    special_tokens=[
        ("<s>", 0),
        ("</s>", 2),
    ],
)
```

**T5 風格**（無特殊 token）：
```python
# T5 不透過後處理器添加特殊 token
tokenizer.post_processor = None
```

### RobertaProcessing

```python
from tokenizers.processors import RobertaProcessing

tokenizer.post_processor = RobertaProcessing(
    sep=("</s>", 2),
    cls=("<s>", 0),
    add_prefix_space=True,  # 在第一個 token 前添加空格
    trim_offsets=True       # 從偏移量 (offsets) 中修剪前導空格
)
```

### ByteLevelProcessing

```python
from tokenizers.processors import ByteLevel as ByteLevelProcessing

tokenizer.post_processor = ByteLevelProcessing(
    trim_offsets=True  # 從偏移量中移除 Ġ
)
```

## 解碼器 (Decoders)

將 Token ID 轉回文字。

### ByteLevel 解碼器

```python
from tokenizers.decoders import ByteLevel

tokenizer.decoder = ByteLevel()

# 處理位元組層級 token
# ["ĠHello", "Ġworld"] → "Hello world"
```

### WordPiece 解碼器

```python
from tokenizers.decoders import WordPiece

tokenizer.decoder = WordPiece(prefix="##")

# 移除 ## 前綴並連接
# ["token", "##ization"] → "tokenization"
```

### Metaspace 解碼器

```python
from tokenizers.decoders import Metaspace

tokenizer.decoder = Metaspace(replacement="▁", add_prefix_space=True)

# 將 ▁ 轉回空格
# ["▁Hello", "▁world"] → "Hello world"
```

### BPEDecoder

```python
from tokenizers.decoders import BPEDecoder

tokenizer.decoder = BPEDecoder(suffix="</w>")

# 移除後綴並連接
# ["token", "ization</w>"] → "tokenization"
```

### 序列解碼器 (Sequence decoder)

```python
from tokenizers.decoders import Sequence, ByteLevel, Strip

tokenizer.decoder = Sequence([
    ByteLevel(),      # 先進行位元組層級解碼
    Strip(' ', 1, 1)  # 修剪前後空格
])
```

## 完整管線範例

### BERT 分詞器

```python
from tokenizers import Tokenizer
from tokenizers.models import WordPiece
from tokenizers.normalizers import BertNormalizer
from tokenizers.pre_tokenizers import BertPreTokenizer
from tokenizers.processors import TemplateProcessing
from tokenizers.decoders import WordPiece as WordPieceDecoder

# 模型
tokenizer = Tokenizer(WordPiece(unk_token="[UNK]"))

# 正規化
tokenizer.normalizer = BertNormalizer(lowercase=True)

# 前分詞
tokenizer.pre_tokenizer = BertPreTokenizer()

# 後處理
tokenizer.post_processor = TemplateProcessing(
    single="[CLS] $A [SEP]",
    pair="[CLS] $A [SEP] $B [SEP]",
    special_tokens=[("[CLS]", 101), ("[SEP]", 102)],
)

# 解碼器
tokenizer.decoder = WordPieceDecoder(prefix="##")

# 啟用填充 (Padding)
tokenizer.enable_padding(pad_id=0, pad_token="[PAD]")

# 啟用截斷 (Truncation)
tokenizer.enable_truncation(max_length=512)
```

### GPT-2 分詞器

```python
from tokenizers import Tokenizer
from tokenizers.models import BPE
from tokenizers.normalizers import NFC
from tokenizers.pre_tokenizers import ByteLevel
from tokenizers.decoders import ByteLevel as ByteLevelDecoder
from tokenizers.processors import TemplateProcessing

# 模型
tokenizer = Tokenizer(BPE())

# 正規化 (最低限度)
tokenizer.normalizer = NFC()

# 位元組層級前分詞
tokenizer.pre_tokenizer = ByteLevel(add_prefix_space=False)

# 後處理
tokenizer.post_processor = TemplateProcessing(
    single="$A <|endoftext|>",
    special_tokens=[("<|endoftext|>", 50256)],
)

# 位元組層級解碼器
tokenizer.decoder = ByteLevelDecoder()
```

### T5 分詞器 (SentencePiece 風格)

```python
from tokenizers import Tokenizer
from tokenizers.models import Unigram
from tokenizers.normalizers import NFKC
from tokenizers.pre_tokenizers import Metaspace
from tokenizers.decoders import Metaspace as MetaspaceDecoder

# 模型
tokenizer = Tokenizer(Unigram())

# 正規化
tokenizer.normalizer = NFKC()

# Metaspace 前分詞
tokenizer.pre_tokenizer = Metaspace(replacement="▁", add_prefix_space=True)

# 無後處理 (T5 不添加 CLS/SEP)
tokenizer.post_processor = None

# Metaspace 解碼器
tokenizer.decoder = MetaspaceDecoder(replacement="▁", add_prefix_space=True)
```

## 對齊追蹤 (Alignment tracking)

追蹤 token 在原始文字中的位置。

### 基本對齊

```python
text = "Hello, world!"
output = tokenizer.encode(text)

for token, (start, end) in zip(output.tokens, output.offsets):
    print(f"{token:10s} → [{start:2d}, {end:2d}): {text[start:end]!r}")

# 輸出：
# [CLS]      → [ 0,  0): ''
# hello      → [ 0,  5): 'Hello'
# ,          → [ 5,  6): ','
# world      → [ 7, 12): 'world'
# !          → [12, 13): '!'
# [SEP]      → [ 0,  0): ''
```

### 詞層級對齊

```python
# 獲取 word_ids (每個 token 屬於哪個單字)
encoding = tokenizer.encode("Hello world")
word_ids = encoding.word_ids

print(word_ids)
# [None, 0, 0, 1, None]
# None = 特殊 token, 0 = 第一個單字, 1 = 第二個單字
```

**使用案例**：Token 分類 (如命名實體識別，NER)
```python
# 將預測結果對齊到單字
predictions = ["O", "B-PER", "I-PER", "O", "O"]
word_predictions = {}

for token_idx, word_idx in enumerate(encoding.word_ids):
    if word_idx is not None and word_idx not in word_predictions:
        word_predictions[word_idx] = predictions[token_idx]

print(word_predictions)
# {0: "B-PER", 1: "O"}  # 第一個單字是 PERSON，第二個是 OTHER
```

### 跨度對齊 (Span alignment)

```python
# 為字元跨度尋找 token 跨度
text = "Machine learning is awesome"
char_start, char_end = 8, 16  # "learning"

encoding = tokenizer.encode(text)

# 尋找 token 跨度
token_start = encoding.char_to_token(char_start)
token_end = encoding.char_to_token(char_end - 1) + 1

print(f"Tokens {token_start}:{token_end} = {encoding.tokens[token_start:token_end]}")
# Tokens 2:3 = ['learning']
```

**使用案例**：問答任務 (提取答案跨度)

## 自定義元件

### 自定義正規化器

```python
from tokenizers import NormalizedString, Normalizer

class CustomNormalizer:
    def normalize(self, normalized: NormalizedString):
        # 自定義正規化邏輯
        normalized.lowercase()
        normalized.replace("  ", " ")  # 替換雙空格

# 使用自定義正規化器
tokenizer.normalizer = CustomNormalizer()
```

### 自定義前分詞器

```python
from tokenizers import PreTokenizedString

class CustomPreTokenizer:
    def pre_tokenize(self, pretok: PreTokenizedString):
        # 自定義前分詞邏輯
        pretok.split(lambda i, char: char.isspace())

tokenizer.pre_tokenizer = CustomPreTokenizer()
```

## 疑難排解

### 問題：偏移量 (Offsets) 錯位

**徵狀**：偏移量與原始文字不匹配
```python
text = "  hello"  # 前導空格
offsets = [(0, 5)]  # 預期為 "  hel"
```

**解決方案**：檢查正規化是否修剪了空格
```python
# 保留偏移量
tokenizer.normalizer = Sequence([
    Strip(),  # 這會改變偏移量！
])

# 改在後處理器中使用 trim_offsets
tokenizer.post_processor = ByteLevelProcessing(trim_offsets=True)
```

### 問題：未添加特殊 token

**徵狀**：輸出中沒有 [CLS] 或 [SEP]

**解決方案**：檢查後處理器是否已設定
```python
tokenizer.post_processor = TemplateProcessing(
    single="[CLS] $A [SEP]",
    special_tokens=[("[CLS]", 101), ("[SEP]", 102)],
)
```

### 問題：解碼不正確

**徵狀**：解碼後的文字含有 ## 或 ▁

**解決方案**：設定正確的解碼器
```python
# WordPiece 專用
tokenizer.decoder = WordPieceDecoder(prefix="##")

# SentencePiece 專用
tokenizer.decoder = MetaspaceDecoder(replacement="▁")
```

## 最佳實務

1. **使管線與模型架構匹配**：
   - BERT → BertNormalizer + BertPreTokenizer + WordPiece
   - GPT-2 → NFC + ByteLevel + BPE
   - T5 → NFKC + Metaspace + Unigram

2. **在樣本輸入上測試管線**：
   - 檢查正規化是否過度正規化
   - 驗證前分詞分割是否正確
   - 確保解碼能還原文字

3. **為下游任務保留對齊資訊**：
   - 使用 `trim_offsets` 而非在正規化器中修剪
   - 在樣本跨度上測試 `char_to_token()`

4. **記錄您的管線**：
   - 儲存完整的分詞器組態
   - 記錄特殊 token
   - 標註任何自定義元件
