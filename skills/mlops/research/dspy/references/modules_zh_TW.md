# DSPy 模組 (Modules)

DSPy 內建語言模型程式設計模組的完整指南。

## 模組基礎

DSPy 模組是受 PyTorch 的 NN 模組啟發的可組合建構塊：
- 具有可學習的參數（提示詞、少樣本範例 Few-shot examples）
- 可以使用 Python 控制流進行組合
- 通用化以處理任何簽名 (Signature)
- 可使用 DSPy 優化器進行優化

### 基礎模組模式

```python
import dspy

class CustomModule(dspy.Module):
    def __init__(self):
        super().__init__()
        # 初始化子模組
        self.predictor = dspy.Predict("input -> output")

    def forward(self, input):
        # 模組邏輯
        result = self.predictor(input=input)
        return result
```

## 核心模組

### dspy.Predict

**基礎預測模組** - 執行不含推理步驟的 LM 呼叫。

```python
# 行內簽名 (Inline signature)
qa = dspy.Predict("question -> answer")
result = qa(question="2+2 等於多少？")

# 類別簽名 (Class signature)
class QA(dspy.Signature):
    """簡明地回答問題。"""
    question = dspy.InputField()
    answer = dspy.OutputField(desc="簡短的事實性答案")

qa = dspy.Predict(QA)
result = qa(question="法國的首都是哪裡？")
print(result.answer)  # "巴黎" (Paris)
```

**使用時機：**
- 簡單、直接的預測
- 不需要推理步驟
- 需要快速回應

### dspy.ChainOfThought

**逐步推理 (Step-by-step reasoning)** - 在回答之前生成理由（Rationale）。

**參數：**
- `signature`: 任務簽名
- `rationale_field`: 自定義推理欄位（選填）
- `rationale_field_type`: 推理欄位的類型（預設為 `str`）

```python
# 基本用法
cot = dspy.ChainOfThought("question -> answer")
result = cot(question="如果我有 5 個蘋果並分掉 2 個，還剩幾個？")
print(result.rationale)  # "讓我們一步步思考..."
print(result.answer)     # "3"

# 自定義推理欄位
cot = dspy.ChainOfThought(
    signature="problem -> solution",
    rationale_field=dspy.OutputField(
        prefix="推理：讓我們逐步拆解問題以"
    )
)
```

**使用時機：**
- 複雜的推理任務
- 數學應用題
- 邏輯演繹
- 品質高於速度的需求

**效能：**
- 比 Predict 慢約 2 倍
- 在推理任務上的準確度顯著提升

### dspy.ProgramOfThought

**基於程式碼的推理** - 生成並執行 Python 程式碼。

```python
pot = dspy.ProgramOfThought("question -> answer")

result = pot(question="240 的 15% 是多少？")
# 內部生成：answer = 240 * 0.15
# 執行程式碼並回傳結果
print(result.answer)  # 36.0

result = pot(question="如果火車以時速 60 英里行駛 2.5 小時，它行駛了多遠？")
# 生成：distance = 60 * 2.5
print(result.answer)  # 150.0
```

**使用時機：**
- 算術計算
- 符號數學
- 數據轉換
- 確定性計算 (Deterministic computations)

**優點：**
- 比基於文本的數學運算更可靠
- 處理複雜計算
- 透明化（顯示生成的程式碼）

### dspy.ReAct

**推理 + 行動 (Reasoning + Acting)** - 迭代使用工具的代理人。

```python
from dspy.predict import ReAct

# 定義工具
def search_wikipedia(query: str) -> str:
    """在維基百科中搜尋資訊。"""
    # 你的搜尋實作內容
    return search_results

def calculate(expression: str) -> float:
    """計算數學表達式。"""
    return eval(expression)

# 建立 ReAct 代理人
class ResearchQA(dspy.Signature):
    """使用可用工具回答問題。"""
    question = dspy.InputField()
    answer = dspy.OutputField()

react = ReAct(ResearchQA, tools=[search_wikipedia, calculate])

# 代理人決定使用哪些工具
result = react(question="愛因斯坦發表狹義相對論時幾歲？")
# 內部運作：
# 1. 思考 (Think)："需要出生年份和發表年份"
# 2. 行動 (Act)：search_wikipedia("Albert Einstein")
# 3. 行動 (Act)：search_wikipedia("Special relativity 1905")
# 4. 行動 (Act)：calculate("1905 - 1879")
# 5. 回傳 (Return)："26 歲"
```

**使用時機：**
- 多階段研究任務
- 使用工具的代理人
- 複雜的資訊檢索
- 需要多次 API 呼叫的任務

**最佳實踐：**
- 保持工具描述清晰且具體
- 限制工具數量在 5-7 個（過多會導致混淆）
- 在 docstrings 中提供工具使用範例

### dspy.MultiChainComparison

**生成多個輸出並進行比較** - 自我一致性 (Self-consistency) 模式。

```python
mcc = dspy.MultiChainComparison("question -> answer", M=5)

result = mcc(question="法國的首都是哪裡？")
# 生成 5 個候選答案
# 比較並選擇最一致的一個
print(result.answer)  # "巴黎" (Paris)
print(result.candidates)  # 所有 5 個生成的答案
```

**參數：**
- `M`: 要生成的候選答案數量（預設為 5）
- `temperature`: 取樣溫度，用於增加多樣性

**使用時機：**
- 高風險決策
- 模糊不清的問題
- 單一答案可能不可靠時

**權衡：**
- 慢 M 倍（M 個平行呼叫）
- 在模糊任務上具備更高準確度

### dspy.majority

**對多個預測結果進行多數投票。**

```python
from dspy.primitives import majority

# 生成多個預測
predictor = dspy.Predict("question -> answer")
predictions = [predictor(question="2+2 等於多少？") for _ in range(5)]

# 進行多數投票
answer = majority([p.answer for p in predictions])
print(answer)  # "4"
```

**使用時機：**
- 組合多個模型輸出
- 減少預測的變異性
- 集成學習 (Ensemble approaches)

## 進階模組

### dspy.TypedPredictor

**配合 Pydantic 模型進行結構化輸出。**

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

print(result.person.name)       # "John Doe"
print(result.person.age)        # 35
print(result.person.occupation) # "軟體工程師"
```

**優點：**
- 類型安全
- 自動驗證
- JSON Schema 生成
- IDE 自動補全

### dspy.Retry

**具備驗證功能的自動重試。**

```python
from dspy.primitives import Retry

def validate_number(example, pred, trace=None):
    """驗證輸出是否為數字。"""
    try:
        float(pred.answer)
        return True
    except ValueError:
        return False

# 如果驗證失敗，最多重試 3 次
qa = Retry(
    dspy.ChainOfThought("question -> answer"),
    validate=validate_number,
    max_retries=3
)

result = qa(question="80 的 15% 是多少？")
# 如果第一次嘗試回傳非數值內容，會自動重試
```

### dspy.Assert

**斷言驅動優化 (Assertion-driven optimization)。**

```python
import dspy
from dspy.primitives.assertions import assert_transform_module, backtrack_handler

class ValidatedQA(dspy.Module):
    def __init__(self):
        super().__init__()
        self.qa = dspy.ChainOfThought("question -> answer: float")

    def forward(self, question):
        answer = self.qa(question=question).answer

        # 斷言答案必須為數值
        dspy.Assert(
            isinstance(float(answer), float),
            "答案必須是一個數字",
            backtrack=backtrack_handler
        )

        return dspy.Prediction(answer=answer)
```

**優點：**
- 在優化過程中捕捉錯誤
- 引導 LM 產生有效的輸出
- 優於事後過濾 (Post-hoc filtering)

## 模組組合 (Module Composition)

### 循序管道 (Sequential Pipeline)

```python
class Pipeline(dspy.Module):
    def __init__(self):
        super().__init__()
        self.stage1 = dspy.Predict("input -> intermediate")
        self.stage2 = dspy.ChainOfThought("intermediate -> output")

    def forward(self, input):
        intermediate = self.stage1(input=input).intermediate
        output = self.stage2(intermediate=intermediate).output
        return dspy.Prediction(output=output)
```

### 條件邏輯 (Conditional Logic)

```python
class ConditionalModule(dspy.Module):
    def __init__(self):
        super().__init__()
        self.router = dspy.Predict("question -> category: str")
        self.simple_qa = dspy.Predict("question -> answer")
        self.complex_qa = dspy.ChainOfThought("question -> answer")

    def forward(self, question):
        category = self.router(question=question).category

        if category == "simple":
            return self.simple_qa(question=question)
        else:
            return self.complex_qa(question=question)
```

### 平行執行 (Parallel Execution)

```python
class ParallelModule(dspy.Module):
    def __init__(self):
        super().__init__()
        self.approach1 = dspy.ChainOfThought("question -> answer")
        self.approach2 = dspy.ProgramOfThought("question -> answer")

    def forward(self, question):
        # 執行兩種方法
        answer1 = self.approach1(question=question).answer
        answer2 = self.approach2(question=question).answer

        # 比較或組合結果
        if answer1 == answer2:
            return dspy.Prediction(answer=answer1, confidence="高")
        else:
            return dspy.Prediction(answer=answer1, confidence="低")
```

## 批次處理 (Batch Processing)

所有模組皆支援批次處理以提高效率：

```python
cot = dspy.ChainOfThought("question -> answer")

questions = [
    "2+2 等於多少？",
    "3+3 等於多少？",
    "4+4 等於多少？"
]

# 一次處理所有問題
results = cot.batch([{"question": q} for q in questions])

for result in results:
    print(result.answer)
```

## 儲存與載入

```python
# 儲存模組
qa = dspy.ChainOfThought("question -> answer")
qa.save("models/qa_v1.json")

# 載入模組
loaded_qa = dspy.ChainOfThought("question -> answer")
loaded_qa.load("models/qa_v1.json")
```

**儲存的內容：**
- 少樣本範例 (Few-shot examples)
- 提示詞指令
- 模組組態 (Configuration)

**不儲存的內容：**
- 模型權重（DSPy 預設不進行微調）
- LM 供應商設定

## 模組選擇指南

| 任務 | 模組 | 原因 |
|------|--------|--------|
| 簡單分類 | Predict | 快速、直接 |
| 數學應用題 | ProgramOfThought | 計算結果可靠 |
| 邏輯推理 | ChainOfThought | 具備步驟效果更好 |
| 多階段研究 | ReAct | 可使用工具 |
| 高風險決策 | MultiChainComparison | 具備自我一致性 |
| 結構化提取 | TypedPredictor | 類型安全 |
| 模糊不清的問題 | MultiChainComparison | 具備多重觀點 |

## 效能提示 (Performance Tips)

1. **從 Predict 開始**，僅在需要時加入推理
2. **使用批次處理** 處理多個輸入
3. **快取預測結果** 以應對重複查詢
4. **使用 `track_usage=True` 剖析 Token 使用量**
5. **在原型開發完成後使用 Teleprompters 進行優化**

## 常見模式

### 模式：檢索 + 生成 (RAG)

```python
class RAG(dspy.Module):
    def __init__(self, k=3):
        super().__init__()
        self.retrieve = dspy.Retrieve(k=k)
        self.generate = dspy.ChainOfThought("context, question -> answer")

    def forward(self, question):
        context = self.retrieve(question).passages
        return self.generate(context=context, question=question)
```

### 模式：驗證迴圈 (Verification Loop)

```python
class VerifiedQA(dspy.Module):
    def __init__(self):
        super().__init__()
        self.answer = dspy.ChainOfThought("question -> answer")
        self.verify = dspy.Predict("question, answer -> is_correct: bool")

    def forward(self, question, max_attempts=3):
        for _ in range(max_attempts):
            answer = self.answer(question=question).answer
            is_correct = self.verify(question=question, answer=answer).is_correct

            if is_correct:
                return dspy.Prediction(answer=answer)

        return dspy.Prediction(answer="無法驗證答案")
```

### 模式：多輪對話 (Multi-Turn Dialog)

```python
class DialogAgent(dspy.Module):
    def __init__(self):
        super().__init__()
        self.respond = dspy.Predict("history, user_message -> assistant_message")
        self.history = []

    def forward(self, user_message):
        history_str = "\n".join(self.history)
        response = self.respond(history=history_str, user_message=user_message)

        self.history.append(f"User: {user_message}")
        self.history.append(f"Assistant: {response.assistant_message}")

        return response
```
