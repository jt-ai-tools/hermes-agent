# 品質過濾 (Quality Filtering) 指南

NeMo Curator 提供 30 多種品質過濾器的完整指南。

## 基於文本的過濾器

### 字數 (Word count)

```python
from nemo_curator.filters import WordCountFilter

# 根據字數過濾
dataset = dataset.filter(WordCountFilter(min_words=50, max_words=100000))
```

### 重複內容

```python
from nemo_curator.filters import RepeatedLinesFilter

# 移除重複行比例超過 30% 的文件
dataset = dataset.filter(RepeatedLinesFilter(max_repeated_line_fraction=0.3))
```

### 符號比例

```python
from nemo_curator.filters import SymbolToWordRatioFilter

# 移除符號過多的文件
dataset = dataset.filter(SymbolToWordRatioFilter(max_symbol_to_word_ratio=0.3))
```

### URL 比例

```python
from nemo_curator.filters import UrlRatioFilter

# 移除包含大量 URL 的文件
dataset = dataset.filter(UrlRatioFilter(max_url_ratio=0.2))
```

## 語言過濾

```python
from nemo_curator.filters import LanguageIdentificationFilter

# 僅保留英文文件
dataset = dataset.filter(LanguageIdentificationFilter(target_languages=["en"]))

# 多種語言
dataset = dataset.filter(LanguageIdentificationFilter(target_languages=["en", "es", "fr"]))
```

## 基於分類器的過濾

### 品質分類器 (Quality classifier)

```python
from nemo_curator.classifiers import QualityClassifier

quality_clf = QualityClassifier(
    model_path="nvidia/quality-classifier-deberta",
    batch_size=256,
    device="cuda"
)

# 過濾低品質內容 (閾值 > 0.5 = 高品質)
dataset = dataset.filter(lambda doc: quality_clf(doc["text"]) > 0.5)
```

### NSFW 分類器

```python
from nemo_curator.classifiers import NSFWClassifier

nsfw_clf = NSFWClassifier(threshold=0.9, device="cuda")

# 移除 NSFW (不當內容)
dataset = dataset.filter(lambda doc: nsfw_clf(doc["text"]) < 0.9)
```

## 啟發式過濾器 (Heuristic filters)

30 多種過濾器的完整清單：
- WordCountFilter (字數過濾器)
- RepeatedLinesFilter (重複行過濾器)
- UrlRatioFilter (URL 比例過濾器)
- SymbolToWordRatioFilter (符號單詞比過濾器)
- NonAlphaNumericFilter (非字母數字過濾器)
- BulletsFilter (項目符號過濾器)
- WhiteSpaceFilter (空白過濾器)
- ParenthesesFilter (括號過濾器)
- LongWordFilter (長單詞過濾器)
- 以及其他 20 多種...

## 最佳實踐

1. **優先套用低成本過濾器** - 在使用 GPU 分類器之前先進行字數過濾。
2. **在樣本上微調閾值** - 在正式執行前，先在 1 萬份文件上進行測試。
3. **謹慎使用 GPU 分類器** - 雖然有效但成本較高。
4. **高效鏈接過濾器** - 依據成本排序 (低成本 → 高成本)。
