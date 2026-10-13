# Transformers 整合

將 HuggingFace Tokenizers 與 Transformers 函式庫搭配使用的完整指南。

## AutoTokenizer

載入分詞器最簡單的方法。

### 載入預訓練分詞器

```python
from transformers import AutoTokenizer

# 從 HuggingFace Hub 載入
tokenizer = AutoTokenizer.from_pretrained("bert-base-uncased")

# 檢查是否使用快速分詞器 (基於 Rust)
print(tokenizer.is_fast)  # True

# 存取底層 tokenizers.Tokenizer
if tokenizer.is_fast:
    fast_tokenizer = tokenizer.backend_tokenizer
    print(type(fast_tokenizer))  # <class 'tokenizers.Tokenizer'>
```

### 快速 vs 慢速分詞器

| 特性                     | 快速 (Rust)    | 慢速 (Python) |
|--------------------------|----------------|---------------|
| 速度                     | 快 5-10 倍     | 基準 (Baseline)|
| 對齊追蹤 (Alignment tracking)| ✅ 完整支援     | ❌ 限制        |
| 批次處理                 | ✅ 已優化       | ⚠️ 較慢        |
| 偏移映射 (Offset mapping) | ✅ 是           | ❌ 否          |
| 安裝                     | `tokenizers`   | 內建          |

**只要可用，請務必使用快速分詞器。**

### 檢查可用分詞器

```python
from transformers import TOKENIZER_MAPPING

# 列出所有快速分詞器
for config_class, (slow, fast) in TOKENIZER_MAPPING.items():
    if fast is not None:
        print(f"{config_class.__name__}: {fast.__name__}")
```

## PreTrainedTokenizerFast

為 Transformers 封裝自定義分詞器。

### 轉換自定義分詞器

```python
from tokenizers import Tokenizer
from tokenizers.models import BPE
from tokenizers.trainers import BpeTrainer
from transformers import PreTrainedTokenizerFast

# 訓練自定義分詞器
tokenizer = Tokenizer(BPE())
trainer = BpeTrainer(
    vocab_size=30000,
    special_tokens=["[UNK]", "[CLS]", "[SEP]", "[PAD]", "[MASK]"]
)
tokenizer.train(files=["corpus.txt"], trainer=trainer)

# 儲存分詞器
tokenizer.save("my-tokenizer.json")

# 為 Transformers 封裝
transformers_tokenizer = PreTrainedTokenizerFast(
    tokenizer_file="my-tokenizer.json",
    unk_token="[UNK]",
    sep_token="[SEP]",
    pad_token="[PAD]",
    cls_token="[CLS]",
    mask_token="[MASK]"
)

# 以 Transformers 格式儲存
transformers_tokenizer.save_pretrained("my-tokenizer")
```

**結果**：目錄包含 `tokenizer.json` + `tokenizer_config.json` + `special_tokens_map.json`

### 像使用任何 Transformers 分詞器一樣使用

```python
# 載入
from transformers import AutoTokenizer
tokenizer = AutoTokenizer.from_pretrained("my-tokenizer")

# 使用所有 Transformers 功能進行編碼
outputs = tokenizer(
    "Hello world",
    padding="max_length",
    truncation=True,
    max_length=128,
    return_tensors="pt"
)

print(outputs.keys())
# dict_keys(['input_ids', 'token_type_ids', 'attention_mask'])
```

## 特殊標記 (Special tokens)

### 預設特殊標記

| 模型系列      | CLS/BOS | SEP/EOS       | PAD     | UNK     | MASK    |
|--------------|---------|---------------|---------|---------|---------|
| BERT         | [CLS]   | [SEP]         | [PAD]   | [UNK]   | [MASK]  |
| GPT-2        | -       | <\|endoftext\|> | <\|endoftext\|> | <\|endoftext\|> | -       |
| RoBERTa      | <s>     | </s>          | <pad>   | <unk>   | <mask>  |
| T5           | -       | </s>          | <pad>   | <unk>   | -       |

### 新增特殊標記

```python
# 新增新的特殊標記
special_tokens_dict = {
    "additional_special_tokens": ["<|image|>", "<|video|>", "<|audio|>"]
}

num_added_tokens = tokenizer.add_special_tokens(special_tokens_dict)
print(f"已新增 {num_added_tokens} 個標記")

# 調整模型嵌入 (Embeddings) 大小
model.resize_token_embeddings(len(tokenizer))

# 使用新標記
text = "這是一張圖片： <|image|>"
tokens = tokenizer.encode(text)
```

### 新增常規標記

```python
# 新增特定領域標記
new_tokens = ["COVID-19", "mRNA", "vaccine"]
num_added = tokenizer.add_tokens(new_tokens)

# 這些不是特殊標記 (必要時可以分割)
tokenizer.add_tokens(new_tokens, special_tokens=False)

# 這些是特殊標記 (永不分割)
tokenizer.add_tokens(new_tokens, special_tokens=True)
```

## 編碼與解碼

### 基本編碼

```python
# 單句
text = "Hello, how are you?"
encoded = tokenizer(text)

print(encoded)
# {'input_ids': [101, 7592, 1010, 2129, 2024, 2017, 1029, 102],
#  'token_type_ids': [0, 0, 0, 0, 0, 0, 0, 0],
#  'attention_mask': [1, 1, 1, 1, 1, 1, 1, 1]}
```

### 批次編碼

```python
# 多句
texts = ["Hello world", "How are you?", "I am fine"]
encoded = tokenizer(texts, padding=True, truncation=True, max_length=10)

print(encoded['input_ids'])
# [[101, 7592, 2088, 102, 0, 0, 0, 0, 0, 0],
#  [101, 2129, 2024, 2017, 1029, 102, 0, 0, 0, 0],
#  [101, 1045, 2572, 2986, 102, 0, 0, 0, 0, 0]]
```

### 回傳張量 (Tensors)

```python
# 回傳 PyTorch 張量
outputs = tokenizer("Hello world", return_tensors="pt")
print(outputs['input_ids'].shape)  # torch.Size([1, 5])

# 回傳 TensorFlow 張量
outputs = tokenizer("Hello world", return_tensors="tf")

# 回傳 NumPy 陣列
outputs = tokenizer("Hello world", return_tensors="np")

# 回傳列表 (預設)
outputs = tokenizer("Hello world", return_tensors=None)
```

### 解碼

```python
# 解碼標記 ID
ids = [101, 7592, 2088, 102]
text = tokenizer.decode(ids)
print(text)  # "[CLS] hello world [SEP]"

# 跳過特殊標記
text = tokenizer.decode(ids, skip_special_tokens=True)
print(text)  # "hello world"

# 批次解碼
batch_ids = [[101, 7592, 102], [101, 2088, 102]]
texts = tokenizer.batch_decode(batch_ids, skip_special_tokens=True)
print(texts)  # ["hello", "world"]
```

## 填充 (Padding) 與截斷 (Truncation)

### 填充策略

```python
# 填充至批次中最長長度
tokenizer(texts, padding="longest")

# 填充至模型最大長度
tokenizer(texts, padding="max_length", max_length=128)

# 不填充
tokenizer(texts, padding=False)

# 填充至特定值的倍數 (用於高效計算)
tokenizer(texts, padding="max_length", max_length=128, pad_to_multiple_of=8)
# 結果：長度將為 128 (已經是 8 的倍數)
```

### 截斷策略

```python
# 截斷至最大長度
tokenizer(text, truncation=True, max_length=10)

# 僅截斷第一個序列 (用於成對序列)
tokenizer(text1, text2, truncation="only_first", max_length=20)

# 僅截斷第二個序列
tokenizer(text1, text2, truncation="only_second", max_length=20)

# 從最長的開始截斷 (成對序列的預設值)
tokenizer(text1, text2, truncation="longest_first", max_length=20)

# 不截斷 (如果太長則報錯)
tokenizer(text, truncation=False)
```

### 長文件的步長 (Stride)

```python
# 對於長度大於 max_length 的文件
text = "Very long document " * 1000

# 使用重疊編碼
encodings = tokenizer(
    text,
    max_length=512,
    stride=128,          # 區塊之間的重疊標記數
    truncation=True,
    return_overflowing_tokens=True,
    return_offsets_mapping=True
)

# 獲取所有區塊
num_chunks = len(encodings['input_ids'])
print(f"分割成 {num_chunks} 個區塊")

# 每個區塊重疊 stride 個標記
for i, chunk in enumerate(encodings['input_ids']):
    print(f"區塊 {i}: {len(chunk)} 個標記")
```

**使用情境**：長文件問答 (QA)、滑動窗口推理 (Sliding window inference)

## 對齊與偏移 (Alignment and offsets)

### 偏移映射 (Offset mapping)

```python
# 獲取每個標記的字元偏移量
encoded = tokenizer("Hello, world!", return_offsets_mapping=True)

for token, (start, end) in zip(
    encoded.tokens(),
    encoded['offset_mapping'][0]
):
    print(f"{token:10s} → [{start:2d}, {end:2d})")

# 輸出：
# [CLS]      → [ 0,  0)
# Hello      → [ 0,  5)
# ,          → [ 5,  6)
# world      → [ 7, 12)
# !          → [12, 13)
# [SEP]      → [ 0,  0)
```

### 詞 ID (Word IDs)

```python
# 獲取每個標記的詞索引
encoded = tokenizer("Hello world", return_offsets_mapping=True)
word_ids = encoded.word_ids()

print(word_ids)
# [None, 0, 1, None]
# None = 特殊標記, 0 = 第一個詞, 1 = 第二個詞
```

**使用情境**：標記分類 (NER, POS 標記)

### 字元到標記映射

```python
text = "Machine learning is awesome"
encoded = tokenizer(text, return_offsets_mapping=True)

# 尋找特定字元位置的標記
char_pos = 8  # "learning" 中的 "l"
token_idx = encoded.char_to_token(char_pos)

print(f"字元 {char_pos} 在標記 {token_idx} 中： {encoded.tokens()[token_idx]}")
# 字元 8 在標記 2 中： learning
```

**使用情境**：問答任務 (將答案字元跨度映射到標記)

### 序列對

```python
# 編碼句子對
encoded = tokenizer("Question here", "Answer here", return_offsets_mapping=True)

# 獲取序列 ID (識別每個標記屬於哪個序列)
sequence_ids = encoded.sequence_ids()
print(sequence_ids)
# [None, 0, 0, 0, None, 1, 1, 1, None]
# None = 特殊標記, 0 = 問題, 1 = 回答
```

## 模型整合

### 搭配 Transformers 模型使用

```python
from transformers import AutoModel, AutoTokenizer
import torch

# 載入模型與分詞器
model = AutoModel.from_pretrained("bert-base-uncased")
tokenizer = AutoTokenizer.from_pretrained("bert-base-uncased")

# 分詞
text = "Hello world"
inputs = tokenizer(text, return_tensors="pt")

# 前向傳播
with torch.no_grad():
    outputs = model(**inputs)

# 獲取嵌入
last_hidden_state = outputs.last_hidden_state
print(last_hidden_state.shape)  # [1, seq_len, hidden_size]
```

### 自定義模型搭配自定義分詞器

```python
from transformers import BertConfig, BertModel

# 訓練自定義分詞器
from tokenizers import Tokenizer, models, trainers
tokenizer = Tokenizer(models.BPE())
trainer = trainers.BpeTrainer(vocab_size=30000)
tokenizer.train(files=["data.txt"], trainer=trainer)

# 為 Transformers 封裝
from transformers import PreTrainedTokenizerFast
fast_tokenizer = PreTrainedTokenizerFast(
    tokenizer_object=tokenizer,
    unk_token="[UNK]",
    pad_token="[PAD]"
)

# 建立具有自定義詞表大小的模型
config = BertConfig(vocab_size=30000)
model = BertModel(config)

# 搭配使用
inputs = fast_tokenizer("Hello world", return_tensors="pt")
outputs = model(**inputs)
```

### 同時儲存與載入

```python
# 儲存兩者
model.save_pretrained("my-model")
tokenizer.save_pretrained("my-model")

# 目錄結構：
# my-model/
#   ├── config.json
#   ├── pytorch_model.bin
#   ├── tokenizer.json
#   ├── tokenizer_config.json
#   └── special_tokens_map.json

# 載入兩者
from transformers import AutoModel, AutoTokenizer

model = AutoModel.from_pretrained("my-model")
tokenizer = AutoTokenizer.from_pretrained("my-model")
```

## 進階功能

### 多模態分詞 (Multimodal tokenization)

```python
from transformers import AutoTokenizer

# LLaVA 風格 (圖片 + 文字)
tokenizer = AutoTokenizer.from_pretrained("llava-hf/llava-1.5-7b-hf")

# 新增圖片佔位標記
tokenizer.add_special_tokens({"additional_special_tokens": ["<image>"]})

# 在提示語中使用
text = "Describe this image: <image>"
inputs = tokenizer(text, return_tensors="pt")
```

### 範本格式化 (Template formatting)

```python
# 對話範本
messages = [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Hello!"},
    {"role": "assistant", "content": "Hi! How can I help?"},
    {"role": "user", "content": "What's the weather?"}
]

# 套用對話範本 (如果分詞器有提供)
if hasattr(tokenizer, "apply_chat_template"):
    text = tokenizer.apply_chat_template(messages, tokenize=False)
    inputs = tokenizer(text, return_tensors="pt")
```

### 自定義範本

```python
from transformers import PreTrainedTokenizerFast

tokenizer = PreTrainedTokenizerFast(tokenizer_file="tokenizer.json")

# 定義對話範本
tokenizer.chat_template = """
{%- for message in messages %}
    {%- if message['role'] == 'system' %}
        System: {{ message['content'] }}\\n
    {%- elif message['role'] == 'user' %}
        User: {{ message['content'] }}\\n
    {%- elif message['role'] == 'assistant' %}
        Assistant: {{ message['content'] }}\\n
    {%- endif %}
{%- endfor %}
Assistant:
"""

# 使用範本
text = tokenizer.apply_chat_template(messages, tokenize=False)
```

## 效能優化

### 批次處理

```python
# 高效處理大型資料集
from datasets import load_dataset

dataset = load_dataset("imdb", split="train[:1000]")

# 批次分詞
def tokenize_function(examples):
    return tokenizer(
        examples["text"],
        padding="max_length",
        truncation=True,
        max_length=512
    )

# 在資料集上進行映射 (批次處理)
tokenized_dataset = dataset.map(
    tokenize_function,
    batched=True,
    batch_size=1000,
    num_proc=4  # 平行處理
)
```

### 快取 (Caching)

```python
# 為重複分詞啟用快取
tokenizer = AutoTokenizer.from_pretrained(
    "bert-base-uncased",
    use_fast=True,
    cache_dir="./cache"  # 快取分詞器檔案
)

# 使用快取進行分詞
from functools import lru_cache

@lru_cache(maxsize=10000)
def cached_tokenize(text):
    return tuple(tokenizer.encode(text))

# 對於重複輸入會重用快取結果
```

### 記憶體效率

```python
# 對於極大型資料集，使用串流 (Streaming)
from datasets import load_dataset

dataset = load_dataset("pile", split="train", streaming=True)

def process_batch(batch):
    # 分詞
    tokens = tokenizer(batch["text"], truncation=True, max_length=512)

    # 處理標記...

    return tokens

# 分塊處理 (節省記憶體)
for batch in dataset.batch(batch_size=1000):
    processed = process_batch(batch)
```

## 疑難排解

### 問題：分詞器不是快速版本 (not fast)

**症狀**：
```python
tokenizer.is_fast  # False
```

**解決方法**：安裝 tokenizers 函式庫
```bash
pip install tokenizers
```

### 問題：特殊標記無效

**症狀**：特殊標記被分割成子詞

**解決方法**：新增為特殊標記，而非一般標記
```python
# 錯誤
tokenizer.add_tokens(["<|image|>"])

# 正確
tokenizer.add_special_tokens({"additional_special_tokens": ["<|image|>"]})
```

### 問題：無法使用偏移映射 (Offset mapping)

**症狀**：
```python
tokenizer("text", return_offsets_mapping=True)
# 錯誤：不支援 return_offsets_mapping
```

**解決方法**：使用快速分詞器
```python
from transformers import AutoTokenizer

# 載入快速版本
tokenizer = AutoTokenizer.from_pretrained("bert-base-uncased", use_fast=True)
```

### 問題：填充不一致

**症狀**：部分序列有填充，部分沒有

**解決方法**：明確指定填充策略
```python
# 明確填充
tokenizer(
    texts,
    padding="max_length",  # 或 "longest"
    max_length=128
)
```

## 最佳實踐

1. **務必使用快速分詞器**：
   - 快 5-10 倍
   - 完整的對齊追蹤
   - 更好的批次處理

2. **將分詞器與模型一同儲存**：
   - 確保可重現性
   - 防止版本不匹配

3. **對資料集使用批次處理**：
   - 使用 `.map(batched=True)` 進行分詞
   - 設定 `num_proc` 進行平行處理

4. **為重複輸入啟用快取**：
   - 推理時使用 `lru_cache`
   - 使用 `cache_dir` 快取分詞器檔案

5. **正確處理特殊標記**：
   - 對永不分割的標記使用 `add_special_tokens()`
   - 新增標記後調整嵌入大小

6. **測試下游任務的對齊**：
   - 驗證 `offset_mapping` 是否正確
   - 在範例上測試 `char_to_token()`

7. **版本控制分詞器配置**：
   - 儲存 `tokenizer_config.json`
   - 記錄自定義範本
   - 追蹤詞表變更
