# DSPy 優化器 (Optimizers / Teleprompters)

DSPy 優化演算法的完整指南，用於改進提示詞 (Prompts) 與模型權重。

## 什麼是優化器？

DSPy 優化器（稱為 "teleprompters"）透過以下方式自動改進你的模組：
- 從訓練數據中**合成少樣本範例 (Few-shot examples)**
- 透過搜尋**提出更好的指令 (Instructions)**
- **微調模型權重**（選填）

**核心概念**：與其手動調整提示詞，不如定義一個指標 (Metric)，讓 DSPy 進行優化。

## 優化器選擇指南

| 優化器 | 適用於 | 速度 | 品質 | 所需數據量 |
|-----------|----------|-------|---------|-------------|
| BootstrapFewShot | 通用目的 | 快 | 佳 | 10-50 個範例 |
| MIPRO | 指令微調 | 中 | 極佳 | 50-200 個範例 |
| BootstrapFinetune | 模型微調 | 慢 | 極佳 | 100+ 個範例 |
| COPRO | 提示詞優化 | 中 | 佳 | 20-100 個範例 |
| KNNFewShot | 快速建立基準 | 極快 | 普通 | 10+ 個範例 |

## 核心優化器

### BootstrapFewShot

**最受歡迎的優化器** - 從訓練數據生成少樣本演示 (Few-shot demonstrations)。

**運作原理：**
1. 獲取你的訓練範例。
2. 使用你的模組生成預測。
3. 選取高品質的預測（根據指標）。
4. 將這些預測作為未來提示詞中的少樣本範例。

**參數：**
- `metric`: 對預測進行評分的函數（必填）
- `max_bootstrapped_demos`: 生成演示的最大數量（預設為 4）
- `max_labeled_demos`: 使用已標記範例的最大數量（預設為 16）
- `max_rounds`: 優化迭代次數（預設為 1）
- `metric_threshold`: 接受的最低分數（選填）

```python
import dspy
from dspy.teleprompt import BootstrapFewShot

# 定義指標
def validate_answer(example, pred, trace=None):
    """如果預測與標準答案匹配，回傳 True。"""
    return example.answer.lower() == pred.answer.lower()

# 訓練數據
trainset = [
    dspy.Example(question="2+2 等於多少？", answer="4").with_inputs("question"),
    dspy.Example(question="3+5 等於多少？", answer="8").with_inputs("question"),
    dspy.Example(question="10-3 等於多少？", answer="7").with_inputs("question"),
]

# 建立模組
qa = dspy.ChainOfThought("question -> answer")

# 優化
optimizer = BootstrapFewShot(
    metric=validate_answer,
    max_bootstrapped_demos=3,
    max_rounds=2
)

optimized_qa = optimizer.compile(qa, trainset=trainset)

# 現在 optimized_qa 已經學會了少樣本範例！
result = optimized_qa(question="5+7 等於多少？")
```

**最佳實踐：**
- 從 10-50 個訓練範例開始。
- 使用涵蓋邊緣案例 (Edge cases) 的多樣化範例。
- 對於大多數任務，設定 `max_bootstrapped_demos=3-5`。
- 增加 `max_rounds=2-3` 以獲得更好的品質。

**使用時機：**
- 第一個嘗試的優化器。
- 你有 10 個以上的已標記範例。
- 希望快速獲得改進。
- 通用任務。

### MIPRO (Most Important Prompt Optimization)

**頂尖優化器 (State-of-the-art optimizer)** - 迭代搜尋更好的指令。

**運作原理：**
1. 生成候選指令。
2. 在驗證集上測試每個候選指令。
3. 選擇表現最好的指令。
4. 迭代以進一步優化。

**參數：**
- `metric`: 評估指標（必填）
- `num_candidates`: 每次迭代嘗試的指令數量（預設為 10）
- `init_temperature`: 取樣溫度（預設為 1.0）
- `verbose`: 顯示進度（預設為 False）

```python
from dspy.teleprompt import MIPRO

# 定義更精細的指標
def answer_quality(example, pred, trace=None):
    """將答案品質評分為 0-1。"""
    if example.answer.lower() in pred.answer.lower():
        return 1.0
    # 相似答案給予部分分數
    return 0.5 if len(set(example.answer.split()) & set(pred.answer.split())) > 0 else 0.0

# 較大的訓練集（MIPRO 受益於更多數據）
trainset = [...]  # 50-200 個範例
valset = [...]    # 20-50 個範例

# 建立模組
qa = dspy.ChainOfThought("question -> answer")

# 使用 MIPRO 進行優化
optimizer = MIPRO(
    metric=answer_quality,
    num_candidates=10,
    init_temperature=1.0,
    verbose=True
)

optimized_qa = optimizer.compile(
    student=qa,
    trainset=trainset,
    valset=valset,  # MIPRO 使用獨立的驗證集
    num_trials=100   # 試驗次數越多 = 品質越好
)
```

**最佳實踐：**
- 使用 50-200 個訓練範例。
- 獨立的驗證集 (20-50 個範例)。
- 執行 100-200 次試驗以獲得最佳結果。
- 通常耗時 10-30 分鐘。

**使用時機：**
- 你有 50 個以上的已標記範例。
- 追求頂尖效能。
- 願意等待優化過程。
- 複雜的推理任務。

### BootstrapFinetune

**微調模型權重** - 建立用於微調的訓練數據集。

**運作原理：**
1. 生成合成訓練數據。
2. 以微調格式匯出數據。
3. 你獨立進行模型微調。
4. 將微調後的模型載入回系統。

**參數：**
- `metric`: 評估指標（必填）
- `max_bootstrapped_demos`: 生成演示的數量（預設為 4）
- `max_rounds`: 數據生成輪數（預設為 1）

```python
from dspy.teleprompt import BootstrapFinetune

# 訓練數據
trainset = [...]  # 建議 100 個以上範例

# 定義指標
def validate(example, pred, trace=None):
    return example.answer == pred.answer

# 建立模組
qa = dspy.ChainOfThought("question -> answer")

# 生成微調數據
optimizer = BootstrapFinetune(metric=validate)
optimized_qa = optimizer.compile(qa, trainset=trainset)

# 將訓練數據匯出至檔案
# 接著使用你的 LM 供應商 API 進行微調

# 微調後，載入你的模型：
finetuned_lm = dspy.OpenAI(model="ft:gpt-3.5-turbo:your-model-id")
dspy.settings.configure(lm=finetuned_lm)
```

**最佳實踐：**
- 使用 100 個以上訓練範例。
- 在保留的測試集上進行驗證。
- 監控是否存在過擬合 (Overfitting)。
- 先與基於提示詞 (Prompt) 的方法進行比較。

**使用時機：**
- 你有 100 個以上範例。
- 延遲 (Latency) 至關重要（微調後的模型更快）。
- 任務範圍窄且定義明確。
- 提示詞優化不足以滿足需求。

### COPRO (Coordinate Prompt Optimization)

**透過無梯度搜尋 (Gradient-free search) 優化提示詞。**

**運作原理：**
1. 生成提示詞變體。
2. 評估每個變體。
3. 選擇最佳提示詞。
4. 迭代優化。

```python
from dspy.teleprompt import COPRO

# 訓練數據
trainset = [...]

# 定義指標
def metric(example, pred, trace=None):
    return example.answer == pred.answer

# 建立模組
qa = dspy.ChainOfThought("question -> answer")

# 使用 COPRO 優化
optimizer = COPRO(
    metric=metric,
    breadth=10,  # 每次迭代的候選數量
    depth=3      # 優化輪數
)

optimized_qa = optimizer.compile(qa, trainset=trainset)
```

**使用時機：**
- 想要進行提示詞優化。
- 有 20-100 個範例。
- MIPRO 速度太慢。

### KNNFewShot

**簡單的 K-最近鄰演算法 (K-nearest neighbors)** - 為每個查詢選擇相似範例。

**運作原理：**
1. 將所有訓練範例嵌入 (Embeds) 向量空間。
2. 對於每個查詢，尋找 K 個最相似的範例。
3. 將這些範例作為少樣本演示。

```python
from dspy.teleprompt import KNNFewShot

trainset = [...]

# 不需要指標 - 僅選擇相似範例
optimizer = KNNFewShot(k=3)
optimized_qa = optimizer.compile(qa, trainset=trainset)

# 對於每個查詢，從訓練集中選取 3 個最相似的範例
```

**使用時機：**
- 快速建立基準。
- 具有多樣化的訓練範例。
- 相似性是提供幫助的良好指標。

## 編寫指標 (Metrics)

指標是為預測結果評分的函數，對於優化至關重要。

### 二元指標 (Binary Metrics)

```python
def exact_match(example, pred, trace=None):
    """如果預測內容與標準答案完全匹配，回傳 True。"""
    return example.answer == pred.answer

def contains_answer(example, pred, trace=None):
    """如果預測內容包含標準答案，回傳 True。"""
    return example.answer.lower() in pred.answer.lower()
```

### 連續指標 (Continuous Metrics)

```python
def f1_score(example, pred, trace=None):
    """預測內容與標準答案之間的 F1 分數。"""
    pred_tokens = set(pred.answer.lower().split())
    gold_tokens = set(example.answer.lower().split())

    if not pred_tokens:
        return 0.0

    precision = len(pred_tokens & gold_tokens) / len(pred_tokens)
    recall = len(pred_tokens & gold_tokens) / len(gold_tokens)

    if precision + recall == 0:
        return 0.0

    return 2 * (precision * recall) / (precision + recall)

def semantic_similarity(example, pred, trace=None):
    """預測內容與標準答案之間的嵌入相似度 (Embedding similarity)。"""
    from sentence_transformers import SentenceTransformer
    model = SentenceTransformer('all-MiniLM-L6-v2')

    emb1 = model.encode(example.answer)
    emb2 = model.encode(pred.answer)

    similarity = cosine_similarity(emb1, emb2)
    return similarity
```

### 多因素指標 (Multi-Factor Metrics)

```python
def comprehensive_metric(example, pred, trace=None):
    """結合多個因素。"""
    score = 0.0

    # 正確性 (50%)
    if example.answer.lower() in pred.answer.lower():
        score += 0.5

    # 簡潔性 (25%)
    if len(pred.answer.split()) <= 20:
        score += 0.25

    # 引用 (25%)
    if "來源：" in pred.answer.lower():
        score += 0.25

    return score
```

### 使用 Trace 進行除錯

```python
def metric_with_trace(example, pred, trace=None):
    """使用 trace 進行除錯的指標。"""
    is_correct = example.answer == pred.answer

    if trace is not None and not is_correct:
        # 記錄失敗案例以供分析
        print(f"失敗問題：{example.question}")
        print(f"預期答案：{example.answer}")
        print(f"實際得到：{pred.answer}")

    return is_correct
```

## 評估最佳實踐

### 訓練/驗證/測試集切分 (Train/Val/Test Split)

```python
# 切分數據
trainset = data[:100]   # 70%
valset = data[100:120]  # 15%
testset = data[120:]    # 15%

# 在訓練集上優化
optimized = optimizer.compile(module, trainset=trainset)

# 優化過程中進行驗證（適用於 MIPRO）
optimized = optimizer.compile(module, trainset=trainset, valset=valset)

# 在測試集上評估
from dspy.evaluate import Evaluate
evaluator = Evaluate(devset=testset, metric=metric)
score = evaluator(optimized)
```

### 交叉驗證 (Cross-Validation)

```python
from sklearn.model_selection import KFold

kfold = KFold(n_splits=5)
scores = []

for train_idx, val_idx in kfold.split(data):
    trainset = [data[i] for i in train_idx]
    valset = [data[i] for i in val_idx]

    optimized = optimizer.compile(module, trainset=trainset)
    score = evaluator(optimized, devset=valset)
    scores.append(score)

print(f"平均分數：{sum(scores) / len(scores):.2f}")
```

### 比較優化器

```python
results = {}

for opt_name, optimizer in [
    ("baseline", None),
    ("fewshot", BootstrapFewShot(metric=metric)),
    ("mipro", MIPRO(metric=metric)),
]:
    if optimizer is None:
        module_opt = module
    else:
        module_opt = optimizer.compile(module, trainset=trainset)

    score = evaluator(module_opt, devset=testset)
    results[opt_name] = score

print(results)
# {'baseline': 0.65, 'fewshot': 0.78, 'mipro': 0.85}
```

## 進階模式

### 自定義優化器

```python
from dspy.teleprompt import Teleprompter

class CustomOptimizer(Teleprompter):
    def __init__(self, metric):
        self.metric = metric

    def compile(self, student, trainset, **kwargs):
        # 你的優化邏輯
        # 回傳優化後的學生模組
        return student
```

### 多階段優化 (Multi-Stage Optimization)

```python
# 第一階段：Bootstrap 少樣本範例
stage1 = BootstrapFewShot(metric=metric, max_bootstrapped_demos=3)
optimized1 = stage1.compile(module, trainset=trainset)

# 第二階段：指令微調
stage2 = MIPRO(metric=metric, num_candidates=10)
optimized2 = stage2.compile(optimized1, trainset=trainset, valset=valset)

# 最終優化模組
final_module = optimized2
```

### 集成優化 (Ensemble Optimization)

```python
class EnsembleModule(dspy.Module):
    def __init__(self, modules):
        super().__init__()
        self.modules = modules

    def forward(self, question):
        predictions = [m(question=question).answer for m in self.modules]
        # 投票或取平均
        return dspy.Prediction(answer=max(set(predictions), key=predictions.count))

# 優化多個模組
opt1 = BootstrapFewShot(metric=metric).compile(module, trainset=trainset)
opt2 = MIPRO(metric=metric).compile(module, trainset=trainset)
opt3 = COPRO(metric=metric).compile(module, trainset=trainset)

# 進行集成
ensemble = EnsembleModule([opt1, opt2, opt3])
```

## 優化工作流程

### 1. 從基準 (Baseline) 開始

```python
# 不進行優化
baseline = dspy.ChainOfThought("question -> answer")
baseline_score = evaluator(baseline, devset=testset)
print(f"基準分數：{baseline_score}")
```

### 2. 嘗試 BootstrapFewShot

```python
# 快速優化
fewshot = BootstrapFewShot(metric=metric, max_bootstrapped_demos=3)
optimized = fewshot.compile(baseline, trainset=trainset)
fewshot_score = evaluator(optimized, devset=testset)
print(f"少樣本優化分數：{fewshot_score} (+{fewshot_score - baseline_score:.2f})")
```

### 3. 如果有更多數據，嘗試 MIPRO

```python
# 頂尖優化
mipro = MIPRO(metric=metric, num_candidates=10)
optimized_mipro = mipro.compile(baseline, trainset=trainset, valset=valset)
mipro_score = evaluator(optimized_mipro, devset=testset)
print(f"MIPRO 優化分數：{mipro_score} (+{mipro_score - baseline_score:.2f})")
```

### 4. 儲存最佳模型

```python
if mipro_score > fewshot_score:
    optimized_mipro.save("models/best_model.json")
else:
    optimized.save("models/best_model.json")
```

## 常見陷阱

### 1. 對訓練數據過擬合 (Overfitting)

```python
# ❌ 不佳：演示數量過多
optimizer = BootstrapFewShot(max_bootstrapped_demos=20)  # 會導致過擬合！

# ✅ 良好：演示數量適中
optimizer = BootstrapFewShot(max_bootstrapped_demos=3-5)
```

### 2. 指標不匹配任務需求

```python
# ❌ 不佳：對細膩任務使用過於嚴格的二元指標
def bad_metric(example, pred, trace=None):
    return example.answer == pred.answer  # 太過嚴格！

# ✅ 良好：具備層次的指標
def good_metric(example, pred, trace=None):
    return f1_score(example.answer, pred.answer)  # 允許部分分數
```

### 3. 訓練數據不足

```python
# ❌ 不佳：數據太少
trainset = data[:5]  # 不足夠！

# ✅ 良好：數據充足
trainset = data[:50]  # 較佳
```

### 4. 缺乏驗證集

```python
# ❌ 不佳：在測試集上進行優化
optimizer.compile(module, trainset=testset)  # 這是作弊！

# ✅ 良好：正確的切分
optimizer.compile(module, trainset=trainset, valset=valset)
evaluator(optimized, devset=testset)
```

## 效能提示 (Performance Tips)

1. **從簡單開始**：優先嘗試 BootstrapFewShot。
2. **使用具代表性的數據**：涵蓋各種邊緣案例。
3. **監控過擬合**：在保留的驗證集上進行驗證。
4. **迭代指標**：根據失敗案例進行精煉。
5. **儲存檢查點 (Checkpoints)**：避免遺失進度。
6. **與基準對比**：衡量改進幅度。
7. **測試多個優化器**：尋找最適合的一個。

## 資源

- **論文**: "DSPy: Compiling Declarative Language Model Calls into Self-Improving Pipelines"
- **GitHub**: https://github.com/stanfordnlp/dspy
- **Discord**: https://discord.gg/XCGy2WDCQB
