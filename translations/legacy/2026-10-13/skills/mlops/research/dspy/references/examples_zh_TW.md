# DSPy 實務範例 (Real-World Examples)

使用 DSPy 建構生產級系統的實用範例。

## 目錄
- RAG 系統
- 代理人系統 (Agent Systems)
- 分類 (Classification)
- 數據處理 (Data Processing)
- 多階段管道 (Multi-Stage Pipelines)

## RAG 系統 (Retrieval-Augmented Generation)

### 基礎 RAG

```python
import dspy

class BasicRAG(dspy.Module):
    def __init__(self, num_passages=3):
        super().__init__()
        self.retrieve = dspy.Retrieve(k=num_passages)
        self.generate = dspy.ChainOfThought("context, question -> answer")

    def forward(self, question):
        passages = self.retrieve(question).passages
        context = "\n\n".join(passages)
        return self.generate(context=context, question=question)

# 設定檢索器 (以 Chroma 為例)
from dspy.retrieve.chromadb_rm import ChromadbRM

retriever = ChromadbRM(
    collection_name="my_docs",
    persist_directory="./chroma_db",
    k=3
)
dspy.settings.configure(rm=retriever)

# 使用 RAG
rag = BasicRAG()
result = rag(question="什麼是 DSPy？")
print(result.answer)
```

### 優化後的 RAG

```python
from dspy.teleprompt import BootstrapFewShot

# 包含問題-答案配對的訓練數據
trainset = [
    dspy.Example(
        question="什麼是檢索增強生成 (RAG)？",
        answer="RAG 結合了相關文件的檢索與生成..."
    ).with_inputs("question"),
    # ... 更多範例
]

# 定義指標
def answer_correctness(example, pred, trace=None):
    # 檢查答案是否包含關鍵資訊
    return example.answer.lower() in pred.answer.lower()

# 優化 RAG
optimizer = BootstrapFewShot(metric=answer_correctness)
optimized_rag = optimizer.compile(rag, trainset=trainset)

# 優化後的 RAG 在類似問題上表現更好
result = optimized_rag(question="解釋 RAG 系統")
```

### 多跳 RAG (Multi-Hop RAG)

```python
class MultiHopRAG(dspy.Module):
    """跨文件遵循推理鏈的 RAG。"""

    def __init__(self):
        super().__init__()
        self.retrieve = dspy.Retrieve(k=3)
        self.generate_query = dspy.ChainOfThought("question -> search_query")
        self.generate_answer = dspy.ChainOfThought("context, question -> answer")

    def forward(self, question):
        # 第一次檢索
        query1 = self.generate_query(question=question).search_query
        passages1 = self.retrieve(query1).passages

        # 根據第一次結果生成後續查詢
        context1 = "\n".join(passages1)
        query2 = self.generate_query(
            question=f"根據：{context1}\n後續問題：{question}"
        ).search_query

        # 第二次檢索
        passages2 = self.retrieve(query2).passages

        # 組合所有上下文
        all_context = "\n\n".join(passages1 + passages2)

        # 生成最終答案
        return self.generate_answer(context=all_context, question=question)

# 使用多跳 RAG
multi_rag = MultiHopRAG()
result = multi_rag(question="誰寫了啟發電影《銀翼殺手》的那本書？")
# 第一跳：尋找 "銀翼殺手改編自..."
# 第二跳：尋找該書的作者
```

### 具備重排序功能 (Reranking) 的 RAG

```python
class RerankedRAG(dspy.Module):
    """對檢索到的文段進行學習重排序的 RAG。"""

    def __init__(self):
        super().__init__()
        self.retrieve = dspy.Retrieve(k=10)  # 獲取更多候選文段
        self.rerank = dspy.Predict("question, passage -> relevance_score: float")
        self.answer = dspy.ChainOfThought("context, question -> answer")

    def forward(self, question):
        # 檢索候選文段
        passages = self.retrieve(question).passages

        # 對文段進行重排序
        scored_passages = []
        for passage in passages:
            score = float(self.rerank(
                question=question,
                passage=passage
            ).relevance_score)
            scored_passages.append((score, passage))

        # 重排序後取前 3 名
        top_passages = [p for _, p in sorted(scored_passages, reverse=True)[:3]]
        context = "\n\n".join(top_passages)

        # 從重排序後的上下文生成答案
        return self.answer(context=context, question=question)
```

## 代理人系統 (Agent Systems)

### ReAct 代理人

```python
from dspy.predict import ReAct

# 定義工具
def search_wikipedia(query: str) -> str:
    """在維基百科中搜尋資訊。"""
    import wikipedia
    try:
        return wikipedia.summary(query, sentences=3)
    except:
        return "找不到結果"

def calculate(expression: str) -> str:
    """安全地計算數學表達式。"""
    try:
        # 使用安全的 eval
        result = eval(expression, {"__builtins__": {}}, {})
        return str(result)
    except:
        return "無效的表達式"

def search_web(query: str) -> str:
    """搜尋網路。"""
    # 你的網路搜尋實作內容
    return results

# 建立代理人簽名 Signature
class ResearchAgent(dspy.Signature):
    """使用可用工具回答問題。"""
    question = dspy.InputField()
    answer = dspy.OutputField()

# 建立 ReAct 代理人
agent = ReAct(ResearchAgent, tools=[search_wikipedia, calculate, search_web])

# 代理人決定使用哪些工具
result = agent(question="法國人口除以 10 是多少？")
# 代理人運作流程：
# 1. 思考 (Think)："需要法國的人口數據"
# 2. 行動 (Act)：search_wikipedia("France population")
# 3. 思考 (Think)："得到 6700 萬，需要進行除法"
# 4. 行動 (Act)：calculate("67000000 / 10")
# 5. 回傳 (Return)："6,700,000"
```

### 多代理人系統 (Multi-Agent System)

```python
class MultiAgentSystem(dspy.Module):
    """針對不同任務配備專業代理人的系統。"""

    def __init__(self):
        super().__init__()

        # 路由代理人 (Router agent)
        self.router = dspy.Predict("question -> agent_type: str")

        # 專業代理人
        self.research_agent = ReAct(
            ResearchAgent,
            tools=[search_wikipedia, search_web]
        )
        self.math_agent = dspy.ProgramOfThought("problem -> answer")
        self.reasoning_agent = dspy.ChainOfThought("question -> answer")

    def forward(self, question):
        # 路由至合適的代理人
        agent_type = self.router(question=question).agent_type

        if agent_type == "research":
            return self.research_agent(question=question)
        elif agent_type == "math":
            return self.math_agent(problem=question)
        else:
            return self.reasoning_agent(question=question)

# 使用多代理人系統
mas = MultiAgentSystem()
result = mas(question="法國 GDP 的 15% 是多少？")
# 先路由至 research_agent 獲取 GDP，再路由至 math_agent 進行計算
```

## 分類 (Classification)

### 二元分類器 (Binary Classifier)

```python
class SentimentClassifier(dspy.Module):
    def __init__(self):
        super().__init__()
        self.classify = dspy.Predict("text -> sentiment: str")

    def forward(self, text):
        return self.classify(text=text)

# 訓練數據
trainset = [
    dspy.Example(text="我超愛這個！", sentiment="positive").with_inputs("text"),
    dspy.Example(text="糟糕的體驗", sentiment="negative").with_inputs("text"),
    # ... 更多範例
]

# 優化
def accuracy(example, pred, trace=None):
    return example.sentiment == pred.sentiment

optimizer = BootstrapFewShot(metric=accuracy, max_bootstrapped_demos=5)
classifier = SentimentClassifier()
optimized_classifier = optimizer.compile(classifier, trainset=trainset)

# 使用分類器
result = optimized_classifier(text="這個產品太棒了！")
print(result.sentiment)  # "positive"
```

### 多類別分類器 (Multi-Class Classifier)

```python
class TopicClassifier(dspy.Module):
    def __init__(self):
        super().__init__()
        self.classify = dspy.ChainOfThought(
            "text -> category: str, confidence: float"
        )

    def forward(self, text):
        result = self.classify(text=text)
        return dspy.Prediction(
            category=result.category,
            confidence=float(result.confidence)
        )

# 在簽名中定義類別
class TopicSignature(dspy.Signature):
    """將文本分類為以下之一：科技 (technology)、體育 (sports)、政治 (politics)、娛樂 (entertainment)。"""
    text = dspy.InputField()
    category = dspy.OutputField(desc="科技、體育、政治、娛樂之一")
    confidence = dspy.OutputField(desc="0.0 到 1.0")

classifier = dspy.ChainOfThought(TopicSignature)
result = classifier(text="湖人隊贏得了冠軍")
print(result.category)  # "sports"
print(result.confidence)  # 0.95
```

### 分層分類器 (Hierarchical Classifier)

```python
class HierarchicalClassifier(dspy.Module):
    """兩階段分類：先粗分，再細分。"""

    def __init__(self):
        super().__init__()
        self.coarse = dspy.Predict("text -> broad_category: str")
        self.fine_tech = dspy.Predict("text -> tech_subcategory: str")
        self.fine_sports = dspy.Predict("text -> sports_subcategory: str")

    def forward(self, text):
        # 階段 1：大類別
        broad = self.coarse(text=text).broad_category

        # 階段 2：根據大類別進行細分
        if broad == "technology":
            fine = self.fine_tech(text=text).tech_subcategory
        elif broad == "sports":
            fine = self.fine_sports(text=text).sports_subcategory
        else:
            fine = "other"

        return dspy.Prediction(broad_category=broad, fine_category=fine)
```

## 數據處理 (Data Processing)

### 文本摘要

```python
class AdaptiveSummarizer(dspy.Module):
    """將文本摘要至目標長度。"""

    def __init__(self):
        super().__init__()
        self.summarize = dspy.ChainOfThought("text, target_length -> summary")

    def forward(self, text, target_length="3 sentences"):
        return self.summarize(text=text, target_length=target_length)

# 使用摘要器
summarizer = AdaptiveSummarizer()
long_text = "..." # 長篇文章

short_summary = summarizer(long_text, target_length="1 sentence")
medium_summary = summarizer(long_text, target_length="3 sentences")
detailed_summary = summarizer(long_text, target_length="1 paragraph")
```

### 資訊提取 (Information Extraction)

```python
from pydantic import BaseModel, Field

class PersonInfo(BaseModel):
    name: str = Field(description="全名")
    age: int = Field(description="年齡")
    occupation: str = Field(description="職稱")
    location: str = Field(description="城市與國家")

class ExtractPerson(dspy.Signature):
    """從文本中提取人物資訊。"""
    text = dspy.InputField()
    person: PersonInfo = dspy.OutputField()

extractor = dspy.TypedPredictor(ExtractPerson)

text = "Jane Smith 博士，42 歲，是加州帕羅奧圖史丹佛大學的神經科學家。"
result = extractor(text=text)

print(result.person.name)       # "Jane Smith 博士"
print(result.person.age)        # 42
print(result.person.occupation) # "神經科學家"
print(result.person.location)   # "加州帕羅奧圖"
```

### 批次處理 (Batch Processing)

```python
class BatchProcessor(dspy.Module):
    """高效處理大型數據集。"""

    def __init__(self):
        super().__init__()
        self.process = dspy.Predict("text -> processed_text")

    def forward(self, texts):
        # 批次處理以提高效率
        return self.process.batch([{"text": t} for t in texts])

# 處理 1000 份文件
processor = BatchProcessor()
results = processor(texts=large_dataset)

# 結果按順序回傳
for original, result in zip(large_dataset, results):
    print(f"{original} -> {result.processed_text}")
```

## 多階段管道 (Multi-Stage Pipelines)

### 文件處理管道

```python
class DocumentPipeline(dspy.Module):
    """多階段文件處理。"""

    def __init__(self):
        super().__init__()
        self.extract = dspy.Predict("document -> key_points")
        self.classify = dspy.Predict("key_points -> category")
        self.summarize = dspy.ChainOfThought("key_points, category -> summary")
        self.tag = dspy.Predict("summary -> tags")

    def forward(self, document):
        # 階段 1：提取關鍵點
        key_points = self.extract(document=document).key_points

        # 階段 2：分類
        category = self.classify(key_points=key_points).category

        # 階段 3：摘要
        summary = self.summarize(
            key_points=key_points,
            category=category
        ).summary

        # 階段 4：生成標籤
        tags = self.tag(summary=summary).tags

        return dspy.Prediction(
            key_points=key_points,
            category=category,
            summary=summary,
            tags=tags
        )
```

### 品質控制管道 (Quality Control Pipeline)

```python
class QualityControlPipeline(dspy.Module):
    """生成輸出並驗證品質。"""

    def __init__(self):
        super().__init__()
        self.generate = dspy.ChainOfThought("prompt -> output")
        self.verify = dspy.Predict("output -> is_valid: bool, issues: str")
        self.improve = dspy.ChainOfThought("output, issues -> improved_output")

    def forward(self, prompt, max_iterations=3):
        output = self.generate(prompt=prompt).output

        for _ in range(max_iterations):
            # 驗證輸出
            verification = self.verify(output=output)

            if verification.is_valid:
                return dspy.Prediction(output=output, iterations=_ + 1)

            # 根據問題進行改進
            output = self.improve(
                output=output,
                issues=verification.issues
            ).improved_output

        return dspy.Prediction(output=output, iterations=max_iterations)
```

## 生產環境提示 (Production Tips)

### 1. 使用快取提高效能

```python
from functools import lru_cache

class CachedRAG(dspy.Module):
    def __init__(self):
        super().__init__()
        self.retrieve = dspy.Retrieve(k=3)
        self.generate = dspy.ChainOfThought("context, question -> answer")

    @lru_cache(maxsize=1000)
    def forward(self, question):
        passages = self.retrieve(question).passages
        context = "\n".join(passages)
        return self.generate(context=context, question=question).answer
```

### 2. 錯誤處理 (Error Handling)

```python
class RobustModule(dspy.Module):
    def __init__(self):
        super().__init__()
        self.process = dspy.ChainOfThought("input -> output")

    def forward(self, input):
        try:
            result = self.process(input=input)
            return result
        except Exception as e:
            # 記錄錯誤
            print(f"處理 {input} 時出錯：{e}")
            # 回傳備援輸出
            return dspy.Prediction(output="錯誤：無法處理輸入")
```

### 3. 監控 (Monitoring)

```python
class MonitoredModule(dspy.Module):
    def __init__(self):
        super().__init__()
        self.process = dspy.ChainOfThought("input -> output")
        self.call_count = 0
        self.errors = 0

    def forward(self, input):
        self.call_count += 1

        try:
            result = self.process(input=input)
            return result
        except Exception as e:
            self.errors += 1
            raise

    def get_stats(self):
        return {
            "calls": self.call_count,
            "errors": self.errors,
            "error_rate": self.errors / max(self.call_count, 1)
        }
```

### 4. A/B 測試

```python
class ABTestModule(dspy.Module):
    """執行兩個變體並進行比較。"""

    def __init__(self, variant_a, variant_b):
        super().__init__()
        self.variant_a = variant_a
        self.variant_b = variant_b
        self.a_calls = 0
        self.b_calls = 0

    def forward(self, input, variant="a"):
        if variant == "a":
            self.a_calls += 1
            return self.variant_a(input=input)
        else:
            self.b_calls += 1
            return self.variant_b(input=input)

# 比較兩個優化器
baseline = dspy.ChainOfThought("question -> answer")
optimized = BootstrapFewShot(...).compile(baseline, trainset=trainset)

ab_test = ABTestModule(variant_a=baseline, variant_b=optimized)

# 各分配 50% 流量
import random
variant = "a" if random.random() < 0.5 else "b"
result = ab_test(input=question, variant=variant)
```

## 完整範例：客戶服務機器人

```python
import dspy
from dspy.teleprompt import BootstrapFewShot

class CustomerSupportBot(dspy.Module):
    """完整的客戶服務系統。"""

    def __init__(self):
        super().__init__()

        # 分類意圖
        self.classify_intent = dspy.Predict("message -> intent: str")

        # 專業處理程式
        self.technical_handler = dspy.ChainOfThought("message, history -> response")
        self.billing_handler = dspy.ChainOfThought("message, history -> response")
        self.general_handler = dspy.Predict("message, history -> response")

        # 檢索相關文件
        self.retrieve = dspy.Retrieve(k=3)

        # 對話歷史
        self.history = []

    def forward(self, message):
        # 分類意圖
        intent = self.classify_intent(message=message).intent

        # 檢索相關文件
        docs = self.retrieve(message).passages
        context = "\n".join(docs)

        # 將上下文加入歷史
        history_str = "\n".join(self.history)
        full_message = f"上下文：{context}\n\n訊息：{message}"

        # 路由至合適的處理程式
        if intent == "technical":
            response = self.technical_handler(
                message=full_message,
                history=history_str
            ).response
        elif intent == "billing":
            response = self.billing_handler(
                message=full_message,
                history=history_str
            ).response
        else:
            response = self.general_handler(
                message=full_message,
                history=history_str
            ).response

        # 更新歷史
        self.history.append(f"User: {message}")
        self.history.append(f"Bot: {response}")

        return dspy.Prediction(response=response, intent=intent)

# 訓練數據
trainset = [
    dspy.Example(
        message="我的帳戶無法運作",
        intent="technical",
        response="我很樂意提供協助。您看到了什麼錯誤訊息？"
    ).with_inputs("message"),
    # ... 更多範例
]

# 定義指標
def response_quality(example, pred, trace=None):
    # 檢查回應品質
    if len(pred.response) < 20:
        return 0.0
    if example.intent != pred.intent:
        return 0.3
    return 1.0

# 優化
optimizer = BootstrapFewShot(metric=response_quality)
bot = CustomerSupportBot()
optimized_bot = optimizer.compile(bot, trainset=trainset)

# 用於生產環境
optimized_bot.save("models/support_bot_v1.json")

# 之後載入並使用
loaded_bot = CustomerSupportBot()
loaded_bot.load("models/support_bot_v1.json")
response = loaded_bot(message="我無法登入")
```

## 資源

- **官方文件**: https://dspy.ai
- **範例儲存庫**: https://github.com/stanfordnlp/dspy/tree/main/examples
- **Discord**: https://discord.gg/XCGy2WDCQB
