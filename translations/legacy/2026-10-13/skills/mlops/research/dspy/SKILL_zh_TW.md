---
name: dspy
description: 使用宣告式程式設計建構複雜的 AI 系統，自動優化提示詞（Prompts），並使用 DSPy（史丹佛大學 NLP 實驗室開發的系統化 LM 程式設計框架）建立模組化 RAG 系統與代理人（Agents）。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [dspy, openai, anthropic]
metadata:
  hermes:
    tags: [Prompt Engineering, DSPy, Declarative Programming, RAG, Agents, Prompt Optimization, LM Programming, Stanford NLP, Automatic Optimization, Modular AI]

---

# DSPy：宣告式語言模型程式設計 (Declarative Language Model Programming)

## 何時使用此技能

當你需要執行以下操作時，請使用 DSPy：
- **建構複雜的 AI 系統**，包含多個組件和工作流
- **以宣告方式對 LM 進行程式設計**，而非手動進行提示詞工程（Prompt Engineering）
- **利用數據驅動方法自動優化提示詞**
- **建立具備可維護性與可移植性的模組化 AI 管道（Pipelines）**
- **使用優化器（Optimizers）系統性地改進模型輸出**
- **建構更具可靠性的 RAG 系統、代理人（Agents）或分類器**

**GitHub Stars**: 22,000+ | **開發者**: 史丹佛大學 NLP 實驗室 (Stanford NLP)

## 安裝

```bash
# 穩定版本
pip install dspy

# 最新開發版本
pip install git+https://github.com/stanfordnlp/dspy.git

# 安裝特定 LM 供應商支援
pip install dspy[openai]        # OpenAI
pip install dspy[anthropic]     # Anthropic Claude
pip install dspy[all]           # 所有供應商
```

## 快速入門

### 基礎範例：問答系統 (Question Answering)

```python
import dspy

# 設定你的語言模型
lm = dspy.Claude(model="claude-sonnet-4-5-20250929")
dspy.settings.configure(lm=lm)

# 定義簽名 Signature (輸入 → 輸出)
class QA(dspy.Signature):
    """以簡短的事實性答案回答問題。"""
    question = dspy.InputField()
    answer = dspy.OutputField(desc="通常在 1 到 5 個詞之間")

# 建立模組
qa = dspy.Predict(QA)

# 使用模組
response = qa(question="法國的首都是哪裡？")
print(response.answer)  # "巴黎" (Paris)
```

### 思維鏈推理 (Chain of Thought Reasoning)

```python
import dspy

lm = dspy.Claude(model="claude-sonnet-4-5-20250929")
dspy.settings.configure(lm=lm)

# 使用 ChainOfThought 獲得更好的推理效果
class MathProblem(dspy.Signature):
    """解決數學應用題。"""
    problem = dspy.InputField()
    answer = dspy.OutputField(desc="數值答案")

# ChainOfThought 會自動生成推理步驟
cot = dspy.ChainOfThought(MathProblem)

response = cot(problem="如果約翰有 5 個蘋果並給了瑪麗 2 個，他還剩幾個？")
print(response.rationale)  # 顯示推理步驟
print(response.answer)     # "3"
```

## 核心概念

### 1. 簽名 (Signatures)

簽名定義了 AI 任務的結構（輸入 → 輸出）：

```python
# 行內簽名 (Inline signature，簡單用法)
qa = dspy.Predict("question -> answer")

# 類別簽名 (Class signature，詳細用法)
class Summarize(dspy.Signature):
    """將文本摘要為關鍵點。"""
    text = dspy.InputField()
    summary = dspy.OutputField(desc="項目符號，3-5 個項目")

summarizer = dspy.ChainOfThought(Summarize)
```

**使用時機：**
- **Inline**: 快速原型設計、簡單任務
- **Class**: 複雜任務、類型提示、更好的文件化

### 2. 模組 (Modules)

模組是將輸入轉換為輸出的可重複使用組件：

#### dspy.Predict
基礎預測模組：

```python
predictor = dspy.Predict("context, question -> answer")
result = predictor(context="巴黎是法國的首都",
                   question="首都在哪裡？")
```

#### dspy.ChainOfThought
在回答之前生成推理步驟：

```python
cot = dspy.ChainOfThought("question -> answer")
result = cot(question="為什麼天空是藍色的？")
print(result.rationale)  # 推理步驟
print(result.answer)     # 最終答案
```

#### dspy.ReAct
結合工具的代理人式（Agent-like）推理：

```python
from dspy.predict import ReAct

class SearchQA(dspy.Signature):
    """使用搜尋回答問題。"""
    question = dspy.InputField()
    answer = dspy.OutputField()

def search_tool(query: str) -> str:
    """搜尋維基百科。"""
    # 你的搜尋實作內容
    return results

react = ReAct(SearchQA, tools=[search_tool])
result = react(question="Python 是何時建立的？")
```

#### dspy.ProgramOfThought
生成並執行程式碼進行推理：

```python
pot = dspy.ProgramOfThought("question -> answer")
result = pot(question="240 的 15% 是多少？")
# 生成：answer = 240 * 0.15
```

### 3. 優化器 (Optimizers)

優化器使用訓練數據自動改進你的模組：

#### BootstrapFewShot
從範例中學習：

```python
from dspy.teleprompt import BootstrapFewShot

# 訓練數據
trainset = [
    dspy.Example(question="2+2 等於多少？", answer="4").with_inputs("question"),
    dspy.Example(question="3+5 等於多少？", answer="8").with_inputs("question"),
]

# 定義指標
def validate_answer(example, pred, trace=None):
    return example.answer == pred.answer

# 優化
optimizer = BootstrapFewShot(metric=validate_answer, max_bootstrapped_demos=3)
optimized_qa = optimizer.compile(qa, trainset=trainset)

# 現在 optimized_qa 的表現更好了！
```

#### MIPRO (Most Important Prompt Optimization)
迭代地改進提示詞：

```python
from dspy.teleprompt import MIPRO

optimizer = MIPRO(
    metric=validate_answer,
    num_candidates=10,
    init_temperature=1.0
)

optimized_cot = optimizer.compile(
    cot,
    trainset=trainset,
    num_trials=100
)
```

#### BootstrapFinetune
建立用於模型微調（Fine-tuning）的數據集：

```python
from dspy.teleprompt import BootstrapFinetune

optimizer = BootstrapFinetune(metric=validate_answer)
optimized_module = optimizer.compile(qa, trainset=trainset)

# 匯出用於微調的訓練數據
```

### 4. 建構複雜系統

#### 多階段管道 (Multi-Stage Pipeline)

```python
import dspy

class MultiHopQA(dspy.Module):
    def __init__(self):
        super().__init__()
        self.retrieve = dspy.Retrieve(k=3)
        self.generate_query = dspy.ChainOfThought("question -> search_query")
        self.generate_answer = dspy.ChainOfThought("context, question -> answer")

    def forward(self, question):
        # 階段 1：生成搜尋查詢
        search_query = self.generate_query(question=question).search_query

        # 階段 2：檢索上下文
        passages = self.retrieve(search_query).passages
        context = "\n".join(passages)

        # 階段 3：生成答案
        answer = self.generate_answer(context=context, question=question).answer
        return dspy.Prediction(answer=answer, context=context)

# 使用管道
qa_system = MultiHopQA()
result = qa_system(question="誰寫了啟發電影《銀翼殺手》的那本書？")
```

#### 具備優化功能的 RAG 系統

```python
import dspy
from dspy.retrieve.chromadb_rm import ChromadbRM

# 設定檢索器 (Retriever)
retriever = ChromadbRM(
    collection_name="documents",
    persist_directory="./chroma_db"
)

class RAG(dspy.Module):
    def __init__(self, num_passages=3):
        super().__init__()
        self.retrieve = dspy.Retrieve(k=num_passages)
        self.generate = dspy.ChainOfThought("context, question -> answer")

    def forward(self, question):
        context = self.retrieve(question).passages
        return self.generate(context=context, question=question)

# 建立並優化
rag = RAG()

# 使用訓練數據進行優化
from dspy.teleprompt import BootstrapFewShot

optimizer = BootstrapFewShot(metric=validate_answer)
optimized_rag = optimizer.compile(rag, trainset=trainset)
```

## LM 供應商設定

### Anthropic Claude

```python
import dspy

lm = dspy.Claude(
    model="claude-sonnet-4-5-20250929",
    api_key="your-api-key",  # 或設定 ANTHROPIC_API_KEY 環境變數
    max_tokens=1000,
    temperature=0.7
)
dspy.settings.configure(lm=lm)
```

### OpenAI

```python
lm = dspy.OpenAI(
    model="gpt-4",
    api_key="your-api-key",
    max_tokens=1000
)
dspy.settings.configure(lm=lm)
```

### 本地模型 (Ollama)

```python
lm = dspy.OllamaLocal(
    model="llama3.1",
    base_url="http://localhost:11434"
)
dspy.settings.configure(lm=lm)
```

### 多模型使用

```python
# 不同的任務使用不同的模型
cheap_lm = dspy.OpenAI(model="gpt-3.5-turbo")
strong_lm = dspy.Claude(model="claude-sonnet-4-5-20250929")

# 使用便宜的模型進行檢索，強大的模型進行推理
with dspy.settings.context(lm=cheap_lm):
    context = retriever(question)

with dspy.settings.context(lm=strong_lm):
    answer = generator(context=context, question=question)
```

## 常見模式

### 模式 1：結構化輸出

```python
from pydantic import BaseModel, Field

class PersonInfo(BaseModel):
    name: str = Field(description="全名")
    age: int = Field(description="年齡")
    occupation: str = Field(description="目前職業")

class ExtractPerson(dspy.Signature):
    """從文本中提取人物資訊。"""
    text = dspy.InputField()
    person: PersonInfo = dspy.OutputField()

extractor = dspy.TypedPredictor(ExtractPerson)
result = extractor(text="John Doe 是一位 35 歲的軟體工程師。")
print(result.person.name)  # "John Doe"
print(result.person.age)   # 35
```

### 模式 2：斷言驅動優化 (Assertion-Driven Optimization)

```python
import dspy
from dspy.primitives.assertions import assert_transform_module, backtrack_handler

class MathQA(dspy.Module):
    def __init__(self):
        super().__init__()
        self.solve = dspy.ChainOfThought("problem -> solution: float")

    def forward(self, problem):
        solution = self.solve(problem=problem).solution

        # 斷言答案必須為數值
        dspy.Assert(
            isinstance(float(solution), float),
            "答案必須是一個數字",
            backtrack=backtrack_handler
        )

        return dspy.Prediction(solution=solution)
```

### 模式 3：自我一致性 (Self-Consistency)

```python
import dspy
from collections import Counter

class ConsistentQA(dspy.Module):
    def __init__(self, num_samples=5):
        super().__init__()
        self.qa = dspy.ChainOfThought("question -> answer")
        self.num_samples = num_samples

    def forward(self, question):
        # 生成多個答案
        answers = []
        for _ in range(self.num_samples):
            result = self.qa(question=question)
            answers.append(result.answer)

        # 回傳最常見的答案
        most_common = Counter(answers).most_common(1)[0][0]
        return dspy.Prediction(answer=most_common)
```

### 模式 4：具備重排序功能 (Reranking) 的檢索

```python
class RerankedRAG(dspy.Module):
    def __init__(self):
        super().__init__()
        self.retrieve = dspy.Retrieve(k=10)
        self.rerank = dspy.Predict("question, passage -> relevance_score: float")
        self.answer = dspy.ChainOfThought("context, question -> answer")

    def forward(self, question):
        # 檢索候選文段
        passages = self.retrieve(question).passages

        # 對文段進行重排序
        scored = []
        for passage in passages:
            score = float(self.rerank(question=question, passage=passage).relevance_score)
            scored.append((score, passage))

        # 選取前 3 名
        top_passages = [p for _, p in sorted(scored, reverse=True)[:3]]
        context = "\n\n".join(top_passages)

        # 生成答案
        return self.answer(context=context, question=question)
```

## 評估與指標 (Evaluation and Metrics)

### 自定義指標

```python
def exact_match(example, pred, trace=None):
    """完全匹配指標。"""
    return example.answer.lower() == pred.answer.lower()

def f1_score(example, pred, trace=None):
    """文本重疊的 F1 分數。"""
    pred_tokens = set(pred.answer.lower().split())
    gold_tokens = set(example.answer.lower().split())

    if not pred_tokens:
        return 0.0

    precision = len(pred_tokens & gold_tokens) / len(pred_tokens)
    recall = len(pred_tokens & gold_tokens) / len(gold_tokens)

    if precision + recall == 0:
        return 0.0

    return 2 * (precision * recall) / (precision + recall)
```

### 評估

```python
from dspy.evaluate import Evaluate

# 建立評估器
evaluator = Evaluate(
    devset=testset,
    metric=exact_match,
    num_threads=4,
    display_progress=True
)

# 評估模型
score = evaluator(qa_system)
print(f"準確率: {score}")

# 比較優化前與優化後
score_before = evaluator(qa)
score_after = evaluator(optimized_qa)
print(f"改進幅度: {score_after - score_before:.2%}")
```

## 最佳實踐

### 1. 從簡單開始，逐步迭代

```python
# 從 Predict 開始
qa = dspy.Predict("question -> answer")

# 如果需要推理，加入 ChainOfThought
qa = dspy.ChainOfThought("question -> answer")

# 當你有數據時，加入優化
optimized_qa = optimizer.compile(qa, trainset=data)
```

### 2. 使用具描述性的簽名 (Signatures)

```python
# ❌ 不佳：模糊不清
class Task(dspy.Signature):
    input = dspy.InputField()
    output = dspy.OutputField()

# ✅ 良好：具描述性
class SummarizeArticle(dspy.Signature):
    """將新聞文章摘要為 3-5 個關鍵點。"""
    article = dspy.InputField(desc="完整的文章文本")
    summary = dspy.OutputField(desc="項目符號，3-5 個項目")
```

### 3. 使用具代表性的數據進行優化

```python
# 建立多樣化的訓練範例
trainset = [
    dspy.Example(question="事實型", answer="...").with_inputs("question"),
    dspy.Example(question="推理型", answer="...").with_inputs("question"),
    dspy.Example(question="計算型", answer="...").with_inputs("question"),
]

# 將驗證集用於指標
def metric(example, pred, trace=None):
    return example.answer in pred.answer
```

### 4. 儲存與載入優化後的模型

```python
# 儲存
optimized_qa.save("models/qa_v1.json")

# 載入
loaded_qa = dspy.ChainOfThought("question -> answer")
loaded_qa.load("models/qa_v1.json")
```

### 5. 監控與除錯

```python
# 啟用追蹤 (Tracing)
dspy.settings.configure(lm=lm, trace=[])

# 執行預測
result = qa(question="...")

# 檢查追蹤紀錄
for call in dspy.settings.trace:
    print(f"提示詞 (Prompt): {call['prompt']}")
    print(f"回應 (Response): {call['response']}")
```

## 與其他方法的比較

| 功能 | 手動提示 (Manual Prompting) | LangChain | DSPy |
|---------|-----------------|-----------|------|
| 提示詞工程 | 手動 | 手動 | 自動 |
| 優化 | 試錯法 (Trial & error) | 無 | 數據驅動 |
| 模組化 | 低 | 中 | 高 |
| 類型安全 | 否 | 有限 | 是 (透過 Signatures) |
| 可移植性 | 低 | 中 | 高 |
| 學習曲線 | 低 | 中 | 中-高 |

**何時選擇 DSPy：**
- 你擁有訓練數據或可以生成數據
- 你需要系統性地改進提示詞
- 你正在建構複雜的多階段系統
- 你希望在不同的 LM 之間進行優化

**何時選擇替代方案：**
- 快速原型開發（手動提示詞）
- 使用現有工具的簡單鏈結（LangChain）
- 需要自定義優化邏輯

## 資源

- **官方文件**: https://dspy.ai
- **GitHub**: https://github.com/stanfordnlp/dspy (22k+ stars)
- **Discord**: https://discord.gg/XCGy2WDCQB
- **Twitter**: @DSPyOSS
- **論文**: "DSPy: Compiling Declarative Language Model Calls into Self-Improving Pipelines"

## 延伸閱讀

- `references/modules_zh_TW.md` - 詳細模組指南 (Predict, ChainOfThought, ReAct, ProgramOfThought)
- `references/optimizers_zh_TW.md` - 優化演算法 (BootstrapFewShot, MIPRO, BootstrapFinetune)
- `references/examples_zh_TW.md` - 實務範例 (RAG, agents, classifiers)
