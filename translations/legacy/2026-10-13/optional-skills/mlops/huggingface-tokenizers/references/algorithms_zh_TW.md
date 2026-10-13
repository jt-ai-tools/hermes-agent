# Tokenization 演算法深入解析

關於 BPE、WordPiece 和 Unigram 演算法的完整說明。

## 位元組對編碼 (Byte-Pair Encoding, BPE)

### 演算法概覽

BPE 會迭代地合併語料庫 (Corpus) 中出現頻率最高的 Token 對。

**訓練過程**：
1. 以所有字元初始化詞彙表 (Vocabulary)
2. 計算所有相鄰 Token 對的出現頻率
3. 將頻率最高的對合併為新的 Token
4. 將新 Token 加入詞彙表
5. 使用新 Token 更新語料庫
6. 重複此過程，直到達到指定的詞彙表大小

### 逐步範例

**語料庫**：
```
low: 5
lower: 2
newest: 6
widest: 3
```

**第 1 次迭代**：
```
計算 Token 對：
'e' + 's': 9 (newest: 6, widest: 3)  ← 頻率最高
'l' + 'o': 7
'o' + 'w': 7
...

合併：'e' + 's' → 'es'

更新後的語料庫：
low: 5
lower: 2
newest: 6 → newes|t: 6
widest: 3 → wides|t: 3

詞彙表：[a-z] + ['es']
```

**第 2 次迭代**：
```
計算 Token 對：
'es' + 't': 9  ← 頻率最高
'l' + 'o': 7
...

合併：'es' + 't' → 'est'

更新後的語料庫：
low: 5
lower: 2
newest: 6 → new|est: 6
widest: 3 → wid|est: 3

詞彙表：[a-z] + ['es', 'est']
```

**持續進行直到達到目標詞彙表大小...**

### 使用訓練好的 BPE 進行 Tokenization

給定詞彙表：`['l', 'o', 'w', 'e', 'r', 'n', 's', 't', 'i', 'd', 'es', 'est', 'lo', 'low', 'ne', 'new', 'newest', 'wi', 'wid', 'widest']`

對 "lowest" 進行 Tokenization：
```
步驟 1：拆解成字元
['l', 'o', 'w', 'e', 's', 't']

步驟 2：按照訓練時學習到的順序套用合併規則
- 合併 'l' + 'o' → 'lo' (如果學習過此規則)
- 合併 'lo' + 'w' → 'low' (如果學習過)
- 合併 'e' + 's' → 'es' (已學習)
- 合併 'es' + 't' → 'est' (已學習)

最終結果：['low', 'est']
```

### 實作方式

```python
from tokenizers import Tokenizer
from tokenizers.models import BPE
from tokenizers.trainers import BpeTrainer
from tokenizers.pre_tokenizers import Whitespace

# 初始化
tokenizer = Tokenizer(BPE(unk_token="[UNK]"))
tokenizer.pre_tokenizer = Whitespace()

# 設定訓練器
trainer = BpeTrainer(
    vocab_size=1000,
    min_frequency=2,
    special_tokens=["[UNK]", "[CLS]", "[SEP]", "[PAD]", "[MASK]"]
)

# 訓練
corpus = [
    "這是一個用於 BPE 訓練的範例語料庫。",
    "BPE 從訓練資料中學習子詞 (Subword) 單元。",
    # ... 更多句子
]

tokenizer.train_from_iterator(corpus, trainer=trainer)

# 使用
output = tokenizer.encode("This is tokenization")
print(output.tokens)  # ['This', 'is', 'token', 'ization']
```

### 位元組層級 (Byte-level) BPE (GPT-2 變體)

**問題**：標準 BPE 的字元覆蓋範圍有限 (256+ Unicode 字元)

**解決方案**：在位元組層級 (Byte level，256 個位元組) 上運作

```python
from tokenizers.pre_tokenizers import ByteLevel
from tokenizers.decoders import ByteLevel as ByteLevelDecoder

tokenizer = Tokenizer(BPE())

# 位元組層級的預分詞 (Pre-tokenization)
tokenizer.pre_tokenizer = ByteLevel()
tokenizer.decoder = ByteLevelDecoder()

# 這可以處理所有可能的字元，包括表情符號 (Emoji)
text = "Hello 🌍 世界"
tokens = tokenizer.encode(text).tokens
```

**優點**：
- 可處理任何 Unicode 字元 (256 位元組覆蓋範圍)
- 不會產生未知 (Unknown) Token (最糟情況下會拆解成位元組)
- 被 GPT-2, GPT-3, BART 所採用

**權衡**：
- 壓縮率略差 (位元組 vs 字元)
- 非 ASCII 文本會產生更多 Token

### BPE 變體

**SentencePiece BPE**：
- 語言無關 (無需預分詞)
- 將輸入視為原始位元組串流
- 被 T5, ALBERT, XLNet 所採用

**魯棒 (Robust) BPE**：
- 訓練期間使用 Dropout (隨機跳過合併規則)
- 在推論 (Inference) 時具有更強韌的 Tokenization 表現
- 減少對訓練資料的過擬合 (Overfitting)

## WordPiece

### 演算法概覽

WordPiece 與 BPE 類似，但使用不同的合併選擇標準。

**訓練過程**：
1. 以所有字元初始化詞彙表
2. 計算所有 Token 對的頻率
3. 為每一對評分：`score = freq(pair) / (freq(first) × freq(second))`
4. 合併評分最高的對
5. 重複此過程，直到達到指定的詞彙表大小

### 為什麼使用不同的評分方式？

**BPE**：合併頻率最高的對
- 如果 "aa" 出現 100 次 → 高優先權
- 即使 'a' 單獨出現 1000 次也一樣

**WordPiece**：合併語意相關的對
- 如果 "aa" 出現 100 次，但 'a' 單獨出現 1000 次 → 分數較低 (100 / (1000 × 1000))
- 如果 "th" 出現 50 次，'t' 出現 60 次，'h' 出現 55 次 → 分數較高 (50 / (60 × 55))
- 優先合併那些共同出現次數超過預期的對

### 逐步範例

**語料庫**：
```
low: 5
lower: 2
newest: 6
widest: 3
```

**第 1 次迭代**：
```
計算頻率：
'e': 11 (lower: 2, newest: 6, widest: 3)
's': 9
't': 9
...

計算 Token 對：
'e' + 's': 9 (newest: 6, widest: 3)
'es' + 't': 9 (newest: 6, widest: 3)
...

計算分數：
score('e' + 's') = 9 / (11 × 9) = 0.091
score('es' + 't') = 9 / (9 × 9) = 0.111  ← 分數最高
score('l' + 'o') = 7 / (7 × 9) = 0.111   ← 並列最高

選擇：'es' + 't' → 'est' (若分數相同則可能選擇 'lo')
```

**關鍵差異**：WordPiece 優先考慮稀有的組合而非僅僅是頻率最高的組合。

### 使用 WordPiece 進行 Tokenization

給定詞彙表：`['##e', '##s', '##t', 'l', 'o', 'w', 'new', 'est', 'low']`

對 "lowest" 進行 Tokenization：
```
步驟 1：尋找最長匹配前綴
'lowest' → 'low' (匹配)

步驟 2：尋找剩餘部分的最長匹配
'est' → 'est' (匹配)

最終結果：['low', 'est']
```

**如果找不到匹配項**：
```
對 "unknownword" 進行 Tokenization：
'unknownword' → 無匹配
'unknown' → 無匹配
'unkn' → 無匹配
'un' → 無匹配
'u' → 無匹配
→ [UNK]
```

### 實作方式

```python
from tokenizers import Tokenizer
from tokenizers.models import WordPiece
from tokenizers.trainers import WordPieceTrainer
from tokenizers.normalizers import BertNormalizer
from tokenizers.pre_tokenizers import BertPreTokenizer

# 初始化 BERT 風格的 Tokenizer
tokenizer = Tokenizer(WordPiece(unk_token="[UNK]"))

# 正規化 (Normalization，轉小寫、去除變音符號)
tokenizer.normalizer = BertNormalizer(lowercase=True)

# 預分詞 (空格 + 標點符號)
tokenizer.pre_tokenizer = BertPreTokenizer()

# 設定訓練器
trainer = WordPieceTrainer(
    vocab_size=30522,  # BERT 的詞彙表大小
    min_frequency=2,
    special_tokens=["[UNK]", "[CLS]", "[SEP]", "[PAD]", "[MASK]"],
    continuing_subword_prefix="##"  # BERT 使用 ## 作為接續子詞的前綴
)

# 訓練
tokenizer.train_from_iterator(corpus, trainer=trainer)

# 使用
output = tokenizer.encode("Tokenization works great!")
print(output.tokens)  # ['token', '##ization', 'works', 'great', '!']
```

### 子詞前綴

**BERT 使用 `##` 前綴**：
```
"unbelievable" → ['un', '##believ', '##able']
```

**為什麼？**
- 表示該 Token 是一個接續部分
- 方便重建原始單字：移除 ## 後直接串接
- 幫助模型區分單字邊界

### WordPiece 的優點

**語意合併**：
- 優先考慮具有意義的組合
- "qu" 分數很高 (通常一起出現)
- "qx" 分數很低 (罕見組合)

**對形態學 (Morphology) 較友善**：
- 能捕捉詞綴：un-, -ing, -ed
- 保留單字詞幹 (Word stems)

**權衡**：
- 訓練速度比 BPE 慢
- 佔用更多記憶體 (儲存詞彙表而非合併規則)
- 原始實作非開源 (HuggingFace 提供了重新實作版本)

## Unigram

### 演算法概覽

Unigram 的運作方式是反向的：從大型詞彙表開始，逐步移除 Token。

**訓練過程**：
1. 以大型詞彙表初始化 (所有子字串)
2. 估計每個 Token 的機率 (基於頻率)
3. 針對每個 Token，計算若將其移除會增加多少損失 (Loss)
4. 移除 10-20% 對損失影響最小的 Token
5. 重新估計機率
6. 重複此過程，直到達到目標詞彙表大小

### 機率性 Tokenization (Probabilistic Tokenization)

**Unigram 假設**：每個 Token 都是獨立的。

給定帶有機率的詞彙表：
```
P('low') = 0.02
P('l') = 0.01
P('o') = 0.015
P('w') = 0.01
P('est') = 0.03
P('e') = 0.02
P('s') = 0.015
P('t') = 0.015
```

對 "lowest" 進行 Tokenization：
```
選項 1：['low', 'est']
機率 = P('low') × P('est') = 0.02 × 0.03 = 0.0006

選項 2：['l', 'o', 'w', 'est']
機率 = 0.01 × 0.015 × 0.01 × 0.03 = 0.000000045

選項 3：['low', 'e', 's', 't']
機率 = 0.02 × 0.02 × 0.015 × 0.015 = 0.0000009

選擇選項 1 (機率最高)
```

### Viterbi 演算法

尋找最佳 Tokenization 的成本很高 (可能性呈指數級增長)。

**Viterbi 演算法** (動態規劃)：
```python
def tokenize_viterbi(word, vocab, probs):
    n = len(word)
    # dp[i] = 對於 word[:i] 的 (最佳機率, 最佳 Token 列表)
    dp = [{} for _ in range(n + 1)]
    dp[0] = (0.0, [])  # 對數機率 (Log probability)

    for i in range(1, n + 1):
        best_prob = float('-inf')
        best_tokens = []

        # 嘗試所有可能的最後一個 Token
        for j in range(i):
            token = word[j:i]
            if token in vocab:
                prob = dp[j][0] + log(probs[token])
                if prob > best_prob:
                    best_prob = prob
                    best_tokens = dp[j][1] + [token]

        dp[i] = (best_prob, best_tokens)

    return dp[n][1]
```

**時間複雜度**：O(n² × 詞彙表大小)，優於暴力的 O(2^n)。

### 實作方式

```python
from tokenizers import Tokenizer
from tokenizers.models import Unigram
from tokenizers.trainers import UnigramTrainer

# 初始化
tokenizer = Tokenizer(Unigram())

# 設定訓練器
trainer = UnigramTrainer(
    vocab_size=8000,
    special_tokens=["<unk>", "<s>", "</s>"],
    unk_token="<unk>",
    max_piece_length=16,      # Token 最大長度
    n_sub_iterations=2,       # EM 迭代次數
    shrinking_factor=0.75     # 每次迭代移除 25%
)

# 訓練
tokenizer.train_from_iterator(corpus, trainer=trainer)

# 使用
output = tokenizer.encode("Tokenization with Unigram")
print(output.tokens)  # ['▁Token', 'ization', '▁with', '▁Un', 'igram']
```

### Unigram 的優點

**機率性**：
- 存在多種有效的 Tokenization 結果
- 可以對不同的 Tokenization 結果進行抽樣 (用於資料增強)

**子詞正則化 (Subword Regularization)**：
```python
# 對同一個單字抽樣不同的 Tokenization
for _ in range(3):
    tokens = tokenizer.encode("tokenization", is_pretokenized=False).tokens
    print(tokens)

# 輸出 (每次可能不同)：
# ['token', 'ization']
# ['tok', 'en', 'ization']
# ['token', 'iz', 'ation']
```

**語言無關**：
- 不需要明確的單字邊界
- 適用於 CJK 語言 (中、日、韓文)
- 將輸入視為字元串流

**權衡**：
- 訓練速度較慢 (EM 演算法)
- 超參數較多
- 模型較大 (需要儲存機率值)

## 演算法比較

### 訓練速度

| 演算法 | 小型 (10MB) | 中型 (100MB) | 大型 (1GB) |
|------------|--------------|----------------|-------------|
| BPE        | 10-15 秒     | 1-2 分鐘       | 10-20 分鐘  |
| WordPiece  | 15-20 秒     | 2-3 分鐘       | 15-30 分鐘  |
| Unigram    | 20-30 秒     | 3-5 分鐘       | 30-60 分鐘  |

**測試環境**：16 核心 CPU, 3 萬詞彙量。

### Tokenization 品質

以英文維基百科進行測試 (困惑度 Perplexity 測量)：

| 演算法 | 詞彙表大小 | 每個單字的 Token 數 | 未知率 (Unknown Rate) |
|------------|------------|-------------|--------------|
| BPE        | 30k        | 1.3         | 0.5%         |
| WordPiece  | 30k        | 1.2         | 1.2%         |
| Unigram    | 8k         | 1.5         | 0.3%         |

**關鍵觀察**：
- WordPiece：壓縮率稍好
- BPE：未知率較低
- Unigram：詞彙量最小，但覆蓋範圍廣

### 壓縮比

每個 Token 的字元數 (越高代表壓縮效果越好)：

| 語言 | BPE (30k) | WordPiece (30k) | Unigram (8k) |
|----------|-----------|-----------------|--------------|
| 英文     | 4.2       | 4.5             | 3.8          |
| 中文     | 2.1       | 2.3             | 2.5          |
| 阿拉伯文 | 3.5       | 3.8             | 3.2          |

**各語言最佳選擇**：
- 英文：WordPiece
- 中文：Unigram (語言無關特性)
- 阿拉伯文：WordPiece

### 使用建議

**BPE** - 最佳適用於：
- 英文語言模型
- 程式碼 (對符號處理良好)
- 需要快速訓練時
- **採用模型**：GPT-2, GPT-3, RoBERTa, BART

**WordPiece** - 最佳適用於：
- 遮蔽語言模型 (Masked Language Modeling，BERT 風格)
- 形態變化豐富的語言
- 語意理解任務
- **採用模型**：BERT, DistilBERT, ELECTRA

**Unigram** - 最佳適用於：
- 多語言模型
- 缺乏明確單字邊界的語言 (CJK)
- 透過子詞正則化進行資料增強
- **採用模型**：T5, ALBERT, XLNet (透過 SentencePiece)

## 進階主題

### 處理罕見單字

**BPE 方法**：
```
"antidisestablishmentarianism"
→ ['anti', 'dis', 'establish', 'ment', 'arian', 'ism']
```

**WordPiece 方法**：
```
"antidisestablishmentarianism"
→ ['anti', '##dis', '##establish', '##ment', '##arian', '##ism']
```

**Unigram 方法**：
```
"antidisestablishmentarianism"
→ ['▁anti', 'dis', 'establish', 'ment', 'arian', 'ism']
```

### 處理數字

**挑戰**：無限的數字組合。

**BPE 解決方案**：位元組層級 (可處理任何數字序列)。
```python
tokenizer = Tokenizer(BPE())
tokenizer.pre_tokenizer = ByteLevel()

# 可處理任何數字
"123456789" → 位元組層級的 Token
```

**WordPiece 解決方案**：數字預分詞。
```python
from tokenizers.pre_tokenizers import Digits

# 將數字逐一拆分或分組
tokenizer.pre_tokenizer = Digits(individual_digits=True)

"123" → ['1', '2', '3']
```

**Unigram 解決方案**：學習常見的數字模式。
```python
# 在訓練期間學習模式
"2023" → ['202', '3'] 或 ['20', '23']
```

### 處理大小寫敏感性

**全小寫 (BERT)**：
```python
from tokenizers.normalizers import Lowercase

tokenizer.normalizer = Lowercase()

"Hello WORLD" → "hello world" → ['hello', 'world']
```

**保留大小寫 (GPT-2)**：
```python
# 不進行大小寫正規化
tokenizer.normalizer = None

"Hello WORLD" → ['Hello', 'WORLD']
```

**區分大小寫的 Token (RoBERTa)**：
```python
# 為不同大小寫學習獨立的 Token
詞彙表：['Hello', 'hello', 'HELLO', 'world', 'WORLD']
```

### 處理表情符號與特殊字元

**位元組層級 (GPT-2)**：
```python
tokenizer.pre_tokenizer = ByteLevel()

"Hello 🌍 👋" → 位元組層級表示法 (始終有效)
```

**Unicode 正規化**：
```python
from tokenizers.normalizers import NFKC

tokenizer.normalizer = NFKC()

"é" (組合形式) ↔ "é" (分解形式) → 統一正規化為單一形式
```

## 常見問題排除

### 問題：子詞拆分過於破碎

**現象**：
```
"running" → ['r', 'u', 'n', 'n', 'i', 'n', 'g']  (過於細碎)
```

**解決方案**：
1. 增加詞彙表大小
2. 增加訓練時間 (更多合併迭代次數)
3. 降低 `min_frequency` 門檻

### 問題：過多未知 (Unknown) Token

**現象**：
```
5% 的 Token 為 [UNK]
```

**解決方案**：
1. 增加詞彙表大小
2. 使用位元組層級的 BPE (不會產生 UNK)
3. 確認訓練語料庫具有代表性

### 問題：Tokenization 結果不一致

**現象**：
```
"running" → ['run', 'ning']
"runner" → ['r', 'u', 'n', 'n', 'e', 'r']
```

**解決方案**：
1. 檢查正規化的一致性
2. 確保預分詞是確定性的 (Deterministic)
3. 使用 Unigram 進行機率性變異

## 最佳實踐

1. **演算法應與模型架構匹配**：
   - BERT 風格 → WordPiece
   - GPT 風格 → BPE
   - T5 風格 → Unigram

2. **多語言場景建議使用位元組層級**：
   - 可處理任何 Unicode
   - 不會產生未知 Token

3. **在具有代表性的資料上進行測試**：
   - 測量壓縮比
   - 檢查未知 Token 比例
   - 檢視 Tokenization 範例

4. **對 Tokenizer 進行版本控制**：
   - 與模型一同儲存
   - 紀錄特殊 Token
   - 追蹤詞彙表的變動
