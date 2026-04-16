# 生產就緒範例 (Production-Ready Examples)

使用 Guidance 進行結構化生成、代理人 (Agents) 和工作流的實戰範例。

## 目錄
- JSON 生成
- 資料提取
- 分類系統
- 代理人系統
- 多步驟工作流
- 程式碼生成
- 實作技巧

## JSON 生成

### 基礎 JSON

```python
from guidance import models, gen, guidance

@guidance
def generate_user(lm):
    """生成有效的使用者 JSON。"""
    lm += "{\n"
    lm += '  "name": ' + gen("name", regex=r'"[A-Za-z ]+"') + ",\n"
    lm += '  "age": ' + gen("age", regex=r"[0-9]+") + ",\n"
    lm += '  "email": ' + gen(
        "email",
        regex=r'"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"'
    ) + "\n"
    lm += "}"
    return lm

# 使用方式
lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm += "Generate a user profile:\n"
lm = generate_user(lm)

print(lm)
# 輸出：保證生成有效的 JSON
```

### 巢狀 JSON

```python
@guidance
def generate_order(lm):
    """生成巢狀的訂單 JSON。"""
    lm += "{\n"

    # 客戶資訊
    lm += '  "customer": {\n'
    lm += '    "name": ' + gen("customer_name", regex=r'"[A-Za-z ]+"') + ",\n"
    lm += '    "email": ' + gen(
        "customer_email",
        regex=r'"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"'
    ) + "\n"
    lm += "  },\n"

    # 訂單詳情
    lm += '  "order": {\n'
    lm += '    "id": ' + gen("order_id", regex=r'"ORD-[0-9]{6}"') + ",\n"
    lm += '    "date": ' + gen("order_date", regex=r'"\d{4}-\d{2}-\d{2}"') + ",\n"
    lm += '    "total": ' + gen("order_total", regex=r"[0-9]+\.[0-9]{2}") + "\n"
    lm += "  },\n"

    # 狀態
    lm += '  "status": ' + gen(
        "status",
        regex=r'"(pending|processing|shipped|delivered)"'
    ) + "\n"

    lm += "}"
    return lm

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = generate_order(lm)
```

### JSON 陣列

```python
@guidance
def generate_user_list(lm, count=3):
    """生成使用者 JSON 陣列。"""
    lm += "[\n"

    for i in range(count):
        lm += "  {\n"
        lm += '    "id": ' + gen(f"id_{i}", regex=r"[0-9]+") + ",\n"
        lm += '    "name": ' + gen(f"name_{i}", regex=r'"[A-Za-z ]+"') + ",\n"
        lm += '    "active": ' + gen(f"active_{i}", regex=r"(true|false)") + "\n"
        lm += "  }"
        if i < count - 1:
            lm += ","
        lm += "\n"

    lm += "]"
    return lm

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = generate_user_list(lm, count=5)
```

### 動態 JSON Schema

```python
import json
from guidance import models, gen, guidance

@guidance
def json_from_schema(lm, schema):
    """生成符合 Schema 的 JSON。"""
    lm += "{\n"

    fields = list(schema["properties"].items())
    for i, (field_name, field_schema) in enumerate(fields):
        lm += f'  "{field_name}": '

        # 處理不同類型
        if field_schema["type"] == "string":
            if "pattern" in field_schema:
                lm += gen(field_name, regex=f'"{field_schema["pattern"]}"')
            else:
                lm += gen(field_name, regex=r'"[^"]+"')
        elif field_schema["type"] == "number":
            lm += gen(field_name, regex=r"[0-9]+(\.[0-9]+)?")
        elif field_schema["type"] == "integer":
            lm += gen(field_name, regex=r"[0-9]+")
        elif field_schema["type"] == "boolean":
            lm += gen(field_name, regex=r"(true|false)")

        if i < len(fields) - 1:
            lm += ","
        lm += "\n"

    lm += "}"
    return lm

# 定義 Schema
schema = {
    "type": "object",
    "properties": {
        "name": {"type": "string"},
        "age": {"type": "integer"},
        "score": {"type": "number"},
        "active": {"type": "boolean"}
    }
}

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = json_from_schema(lm, schema)
```

## 資料提取 (Data Extraction)

### 從文字中提取

```python
from guidance import models, gen, guidance, system, user, assistant

@guidance
def extract_person_info(lm, text):
    """從文字中提取結構化資訊。"""
    lm += f"Text: {text}\n\n"

    with assistant():
        lm += "Name: " + gen("name", regex=r"[A-Za-z ]+", stop="\n") + "\n"
        lm += "Age: " + gen("age", regex=r"[0-9]+", max_tokens=3) + "\n"
        lm += "Occupation: " + gen("occupation", regex=r"[A-Za-z ]+", stop="\n") + "\n"
        lm += "Email: " + gen(
            "email",
            regex=r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
            stop="\n"
        ) + "\n"

    return lm

text = "John Smith is a 35-year-old software engineer. Contact: john@example.com"

lm = models.Anthropic("claude-sonnet-4-5-20250929")

with system():
    lm += "You extract structured information from text."

with user():
    lm = extract_person_info(lm, text)

print(f"Name: {lm['name']}")
print(f"Age: {lm['age']}")
print(f"Occupation: {lm['occupation']}")
print(f"Email: {lm['email']}")
```

### 多實體提取 (Multi-Entity Extraction)

```python
@guidance
def extract_entities(lm, text):
    """提取多種實體類型。"""
    lm += f"Analyze: {text}\n\n"

    # 人物實體
    lm += "People:\n"
    for i in range(3):  # 最多提取 3 人
        lm += f"- " + gen(f"person_{i}", regex=r"[A-Za-z ]+", stop="\n") + "\n"

    # 組織實體
    lm += "\nOrganizations:\n"
    for i in range(2):  # 最多提取 2 個組織
        lm += f"- " + gen(f"org_{i}", regex=r"[A-Za-z0-9 ]+", stop="\n") + "\n"

    # 日期
    lm += "\nDates:\n"
    for i in range(2):  # 最多提取 2 個日期
        lm += f"- " + gen(f"date_{i}", regex=r"\d{4}-\d{2}-\d{2}", stop="\n") + "\n"

    # 地點
    lm += "\nLocations:\n"
    for i in range(2):  # 最多提取 2 個地點
        lm += f"- " + gen(f"location_{i}", regex=r"[A-Za-z ]+", stop="\n") + "\n"

    return lm

text = """
Tim Cook and Satya Nadella met at Microsoft headquarters in Redmond on 2024-09-15
to discuss the collaboration between Apple and Microsoft. The meeting continued
in Cupertino on 2024-09-20.
"""

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = extract_entities(lm, text)
```

### 批次提取 (Batch Extraction)

```python
@guidance
def batch_extract(lm, texts):
    """從多段文字中提取。"""
    lm += "Batch Extraction Results:\n\n"

    for i, text in enumerate(texts):
        lm += f"=== Item {i+1} ===\n"
        lm += f"Text: {text}\n"
        lm += "Name: " + gen(f"name_{i}", regex=r"[A-Za-z ]+", stop="\n") + "\n"
        lm += "Sentiment: " + gen(
            f"sentiment_{i}",
            regex=r"(positive|negative|neutral)",
            stop="\n"
        ) + "\n\n"

    return lm

texts = [
    "Alice is happy with the product",
    "Bob is disappointed with the service",
    "Carol has no strong feelings either way"
]

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = batch_extract(lm, texts)
```

## 分類系統 (Classification Systems)

### 情感分析 (Sentiment Analysis)

```python
from guidance import models, select, gen

lm = models.Anthropic("claude-sonnet-4-5-20250929")

text = "This product is absolutely amazing! Best purchase ever."

lm += f"Text: {text}\n\n"
lm += "Sentiment: " + select(
    ["positive", "negative", "neutral"],
    name="sentiment"
)
lm += "\nConfidence: " + gen("confidence", regex=r"[0-9]{1,3}") + "%\n"
lm += "Reasoning: " + gen("reasoning", stop="\n", max_tokens=50)

print(f"Sentiment: {lm['sentiment']}")
print(f"Confidence: {lm['confidence']}%")
print(f"Reasoning: {lm['reasoning']}")
```

### 多標籤分類 (Multi-Label Classification)

```python
@guidance
def classify_article(lm, text):
    """使用多個標籤對文章進行分類。"""
    lm += f"Article: {text}\n\n"

    # 主要類別
    lm += "Primary Category: " + select(
        ["Technology", "Business", "Science", "Politics", "Entertainment"],
        name="primary_category"
    ) + "\n"

    # 次要類別 (最多 3 個)
    lm += "\nSecondary Categories:\n"
    categories = ["Technology", "Business", "Science", "Politics", "Entertainment"]
    for i in range(3):
        lm += f"{i+1}. " + select(categories, name=f"secondary_{i}") + "\n"

    # 標籤
    lm += "\nTags: " + gen("tags", stop="\n", max_tokens=50) + "\n"

    # 目標受眾
    lm += "Target Audience: " + select(
        ["General", "Expert", "Beginner"],
        name="audience"
    )

    return lm

article = """
Apple announced new AI features in iOS 18, leveraging machine learning to improve
battery life and performance. The company's stock rose 5% following the announcement.
"""

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = classify_article(lm, article)
```

### 意圖分類 (Intent Classification)

```python
@guidance
def classify_intent(lm, message):
    """分類使用者意圖。"""
    lm += f"User Message: {message}\n\n"

    # 意圖
    lm += "Intent: " + select(
        ["question", "complaint", "request", "feedback", "other"],
        name="intent"
    ) + "\n"

    # 緊急程度
    lm += "Urgency: " + select(
        ["low", "medium", "high", "critical"],
        name="urgency"
    ) + "\n"

    # 部門
    lm += "Route To: " + select(
        ["support", "sales", "billing", "technical"],
        name="department"
    ) + "\n"

    # 情感
    lm += "Sentiment: " + select(
        ["positive", "neutral", "negative"],
        name="sentiment"
    )

    return lm

message = "My account was charged twice for the same order. Need help ASAP!"

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = classify_intent(lm, message)

print(f"Intent: {lm['intent']}")
print(f"Urgency: {lm['urgency']}")
print(f"Department: {lm['department']}")
```

## 代理人系統 (Agent Systems)

### ReAct 代理人

```python
from guidance import models, gen, select, guidance

@guidance(stateless=False)
def react_agent(lm, question, tools, max_rounds=5):
    """具備工具使用能力的 ReAct 代理人。"""
    lm += f"Question: {question}\n\n"

    for round in range(max_rounds):
        # 思考 (Thought)
        lm += f"Thought {round+1}: " + gen("thought", stop="\n", max_tokens=100) + "\n"

        # 選擇行動
        lm += "Action: " + select(
            list(tools.keys()) + ["answer"],
            name="action"
        )

        if lm["action"] == "answer":
            lm += "\n\nFinal Answer: " + gen("answer", max_tokens=200)
            break

        # 行動輸入
        lm += "\nAction Input: " + gen("action_input", stop="\n", max_tokens=100) + "\n"

        # 執行工具
        if lm["action"] in tools:
            try:
                result = tools[lm["action"]](lm["action_input"])
                lm += f"Observation: {result}\n\n"
            except Exception as e:
                lm += f"Observation: Error - {str(e)}\n\n"

    return lm

# 定義工具
tools = {
    "calculator": lambda expr: eval(expr),
    "search": lambda query: f"Search results for '{query}': [Mock results]",
    "weather": lambda city: f"Weather in {city}: Sunny, 72°F"
}

# 使用代理人
lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = react_agent(lm, "What is (25 * 4) + 10?", tools)

print(lm["answer"])
```

### 多代理人系統 (Multi-Agent System)

```python
@guidance
def coordinator_agent(lm, task):
    """協調員，負責將任務分配給專員。"""
    lm += f"Task: {task}\n\n"

    # 決定使用哪位專員
    lm += "Specialist: " + select(
        ["researcher", "writer", "coder", "analyst"],
        name="specialist"
    ) + "\n"

    lm += "Reasoning: " + gen("reasoning", stop="\n", max_tokens=100) + "\n"

    return lm

@guidance
def researcher_agent(lm, query):
    """研究專員。"""
    lm += f"Research Query: {query}\n\n"
    lm += "Findings:\n"
    for i in range(3):
        lm += f"{i+1}. " + gen(f"finding_{i}", stop="\n", max_tokens=100) + "\n"
    return lm

@guidance
def writer_agent(lm, topic):
    """寫作專員。"""
    lm += f"Topic: {topic}\n\n"
    lm += "Title: " + gen("title", stop="\n", max_tokens=50) + "\n"
    lm += "Content:\n" + gen("content", max_tokens=500)
    return lm

# 協調工作流
task = "Write an article about AI safety"

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = coordinator_agent(lm, task)

specialist = lm["specialist"]
if specialist == "researcher":
    lm = researcher_agent(lm, task)
elif specialist == "writer":
    lm = writer_agent(lm, task)
```

### 具備驗證功能的工具使用

```python
@guidance(stateless=False)
def validated_tool_agent(lm, question):
    """具備經過驗證的工具呼叫能力的代理人。"""
    tools = {
        "add": lambda a, b: float(a) + float(b),
        "multiply": lambda a, b: float(a) * float(b),
        "divide": lambda a, b: float(a) / float(b) if float(b) != 0 else "Error: Division by zero"
    }

    lm += f"Question: {question}\n\n"

    for i in range(5):
        # 選擇工具
        lm += "Tool: " + select(list(tools.keys()) + ["done"], name="tool")

        if lm["tool"] == "done":
            lm += "\nAnswer: " + gen("answer", max_tokens=100)
            break

        # 獲取經過驗證的數值參數
        lm += "\nArg1: " + gen("arg1", regex=r"-?[0-9]+(\.[0-9]+)?") + "\n"
        lm += "Arg2: " + gen("arg2", regex=r"-?[0-9]+(\.[0-9]+)?") + "\n"

        # 執行
        result = tools[lm["tool"]](lm["arg1"], lm["arg2"])
        lm += f"Result: {result}\n\n"

    return lm

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = validated_tool_agent(lm, "What is (10 + 5) * 3?")
```

## 多步驟工作流 (Multi-Step Workflows)

### 思維鏈 (Chain of Thought, CoT)

```python
@guidance
def chain_of_thought(lm, question):
    """使用思維鏈進行多步驟推理。"""
    lm += f"Question: {question}\n\n"

    # 生成推理步驟
    lm += "Let me think step by step:\n\n"
    for i in range(4):
        lm += f"Step {i+1}: " + gen(f"step_{i+1}", stop="\n", max_tokens=100) + "\n"

    # 最終回答
    lm += "\nTherefore, the answer is: " + gen("answer", stop="\n", max_tokens=50)

    return lm

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = chain_of_thought(lm, "If a train travels 60 mph for 2.5 hours, how far does it go?")

print(lm["answer"])
```

### 自我一致性 (Self-Consistency)

```python
@guidance
def self_consistency(lm, question, num_samples=3):
    """生成多個推理路徑並進行聚合。"""
    lm += f"Question: {question}\n\n"

    answers = []
    for i in range(num_samples):
        lm += f"=== Attempt {i+1} ===\n"
        lm += "Reasoning: " + gen(f"reasoning_{i}", stop="\n", max_tokens=100) + "\n"
        lm += "Answer: " + gen(f"answer_{i}", stop="\n", max_tokens=50) + "\n\n"
        answers.append(lm[f"answer_{i}"])

    # 聚合 (簡單的多數決)
    from collections import Counter
    most_common = Counter(answers).most_common(1)[0][0]

    lm += f"Final Answer (by majority): {most_common}\n"
    return lm

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = self_consistency(lm, "What is 15% of 200?")
```

### 規劃與執行 (Planning and Execution)

```python
@guidance
def plan_and_execute(lm, goal):
    """先規劃任務，然後執行。"""
    lm += f"Goal: {goal}\n\n"

    # 規劃階段
    lm += "Plan:\n"
    num_steps = 4
    for i in range(num_steps):
        lm += f"{i+1}. " + gen(f"plan_step_{i}", stop="\n", max_tokens=100) + "\n"

    # 執行階段
    lm += "\nExecution:\n\n"
    for i in range(num_steps):
        lm += f"Step {i+1}: {lm[f'plan_step_{i}']}\n"
        lm += "Status: " + select(["completed", "in-progress", "blocked"], name=f"status_{i}") + "\n"
        lm += "Result: " + gen(f"result_{i}", stop="\n", max_tokens=150) + "\n\n"

    # 總結
    lm += "Summary: " + gen("summary", max_tokens=200)

    return lm

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = plan_and_execute(lm, "Build a REST API for a blog platform")
```

## 程式碼生成 (Code Generation)

### Python 函式

```python
@guidance
def generate_python_function(lm, description):
    """從描述生成 Python 函式。"""
    lm += f"Description: {description}\n\n"

    # 函式簽署 (Function signature)
    lm += "def " + gen("func_name", regex=r"[a-z_][a-z0-9_]*") + "("
    lm += gen("params", regex=r"[a-z_][a-z0-9_]*(, [a-z_][a-z0-9_]*)*") + "):\n"

    # 文件字串 (Docstring)
    lm += '    """' + gen("docstring", stop='"""', max_tokens=100) + '"""\n'

    # 函式主體
    lm += "    " + gen("body", stop="\n", max_tokens=200) + "\n"

    return lm

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = generate_python_function(lm, "Check if a number is prime")

print(lm)
```

### SQL 查詢

```python
@guidance
def generate_sql(lm, description):
    """從描述生成 SQL 查詢。"""
    lm += f"Description: {description}\n\n"
    lm += "SQL Query:\n"

    # SELECT 子句
    lm += "SELECT " + gen("select_clause", stop=" FROM", max_tokens=100)

    # FROM 子句
    lm += " FROM " + gen("from_clause", stop=" WHERE", max_tokens=50)

    # WHERE 子句 (選填)
    lm += " WHERE " + gen("where_clause", stop=";", max_tokens=100) + ";"

    return lm

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = generate_sql(lm, "Get all users who signed up in the last 30 days")
```

### API 端點 (API Endpoint)

```python
@guidance
def generate_api_endpoint(lm, description):
    """生成 REST API 端點。"""
    lm += f"Description: {description}\n\n"

    # HTTP 方法
    lm += "Method: " + select(["GET", "POST", "PUT", "DELETE"], name="method") + "\n"

    # 路徑 (Path)
    lm += "Path: /" + gen("path", regex=r"[a-z0-9/-]+", stop="\n") + "\n"

    # 請求主體 (如果是 POST/PUT)
    if lm["method"] in ["POST", "PUT"]:
        lm += "\nRequest Body:\n"
        lm += "{\n"
        lm += '  "field1": ' + gen("field1", regex=r'"[a-z_]+"') + ",\n"
        lm += '  "field2": ' + gen("field2", regex=r'"[a-z_]+"') + "\n"
        lm += "}\n"

    # 回應
    lm += "\nResponse (200 OK):\n"
    lm += "{\n"
    lm += '  "status": "success",\n'
    lm += '  "data": ' + gen("response_data", max_tokens=100) + "\n"
    lm += "}\n"

    return lm

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = generate_api_endpoint(lm, "Create a new blog post")
```

## 實作技巧 (Production Tips)

### 錯誤處理

```python
@guidance
def safe_extraction(lm, text):
    """具備備援機制 (Fallback) 的提取。"""
    try:
        lm += f"Text: {text}\n"
        lm += "Name: " + gen("name", regex=r"[A-Za-z ]+", stop="\n", max_tokens=30)
        return lm
    except Exception as e:
        # 發生錯誤時回退至較寬鬆的提取方式
        lm += f"Text: {text}\n"
        lm += "Name: " + gen("name", stop="\n", max_tokens=30)
        return lm
```

### 快取 (Caching)

```python
from functools import lru_cache

@lru_cache(maxsize=100)
def cached_generation(text):
    """快取 LLM 生成結果。"""
    lm = models.Anthropic("claude-sonnet-4-5-20250929")
    lm += f"Analyze: {text}\n"
    lm += "Sentiment: " + select(["positive", "negative", "neutral"], name="sentiment")
    return lm["sentiment"]

# 第一次呼叫：向 LLM 發出請求
result1 = cached_generation("This is great!")

# 第二次呼叫：傳回快取的結果
result2 = cached_generation("This is great!")  # 瞬間完成！
```

### 監控 (Monitoring)

```python
import time

@guidance
def monitored_generation(lm, text):
    """追蹤生成指標。"""
    start_time = time.time()

    lm += f"Text: {text}\n"
    lm += "Analysis: " + gen("analysis", max_tokens=100)

    elapsed = time.time() - start_time

    # 記錄指標
    print(f"Generation time: {elapsed:.2f}s")
    print(f"Output length: {len(lm['analysis'])} chars")

    return lm
```

### 批次處理 (Batch Processing)

```python
def batch_process(texts, batch_size=10):
    """分批次處理文字。"""
    lm = models.Anthropic("claude-sonnet-4-5-20250929")
    results = []

    for i in range(0, len(texts), batch_size):
        batch = texts[i:i+batch_size]

        for text in batch:
            lm += f"Text: {text}\n"
            lm += "Sentiment: " + select(
                ["positive", "negative", "neutral"],
                name=f"sentiment_{i}"
            ) + "\n\n"

        results.extend([lm[f"sentiment_{i}"] for i in range(len(batch))])

    return results
```

## 相關資源

- **Guidance Notebooks**：https://github.com/guidance-ai/guidance/tree/main/notebooks
- **Guidance 官方文件**：https://guidance.readthedocs.io
- **社群範例**：https://github.com/guidance-ai/guidance/discussions
