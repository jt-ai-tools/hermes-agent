---
name: guidance
description: 使用正規表示式和文法控制 LLM 輸出，保證生成有效的 JSON/XML/程式碼，強制執行結構化格式，並使用 Guidance (Microsoft Research 的受限生成框架) 構建多步驟工作流。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [guidance, transformers]
metadata:
  hermes:
    tags: [提示工程, Guidance, 受限生成, 結構化輸出, JSON 驗證, 文法, Microsoft Research, 格式強制執行, 多步驟工作流]

---

# Guidance: 受限 LLM 生成 (Constrained LLM Generation)

## 何時使用此技能

當您需要執行以下操作時，請使用 Guidance：
- 使用正規表示式或文法**控制 LLM 輸出語法**
- **保證生成有效的 JSON/XML/程式碼**
- 與傳統提示方法相比，**降低延遲**
- **強制執行結構化格式**（日期、電子郵件、ID 等）
- 使用 Python 式控制流**構建多步驟工作流**
- 通過文法約束**防止無效輸出**

**GitHub 星星數**：18,000+ | **來源**：Microsoft Research

## 安裝

```bash
# 基礎安裝
pip install guidance

# 安裝特定後端
pip install guidance[transformers]  # Hugging Face 模型
pip install guidance[llama_cpp]     # llama.cpp 模型
```

## 快速入門

### 基本範例：結構化生成

```python
from guidance import models, gen

# 載入模型 (支援 OpenAI, Transformers, llama.cpp)
lm = models.OpenAI("gpt-4")

# 使用約束進行生成
result = lm + "The capital of France is " + gen("capital", max_tokens=5)

print(result["capital"])  # "Paris"
```

### 使用 Anthropic Claude

```python
from guidance import models, gen, system, user, assistant

# 配置 Claude
lm = models.Anthropic("claude-sonnet-4-5-20250929")

# 使用聊天格式的上下文管理器
with system():
    lm += "You are a helpful assistant."

with user():
    lm += "What is the capital of France?"

with assistant():
    lm += gen(max_tokens=20)
```

## 核心概念

### 1. 上下文管理器 (Context Managers)

Guidance 使用 Python 式的上下文管理器進行對話式互動。

```python
from guidance import system, user, assistant, gen

lm = models.Anthropic("claude-sonnet-4-5-20250929")

# 系統訊息 (System message)
with system():
    lm += "You are a JSON generation expert."

# 使用者訊息 (User message)
with user():
    lm += "Generate a person object with name and age."

# 助理回應 (Assistant response)
with assistant():
    lm += gen("response", max_tokens=100)

print(lm["response"])
```

**優點：**
- 自然的聊天流程
- 清晰的角色分離
- 易於閱讀和維護

### 2. 受限生成 (Constrained Generation)

Guidance 使用正規表示式或文法確保輸出符合指定的模式。

#### 正規表示式約束 (Regex Constraints)

```python
from guidance import models, gen

lm = models.Anthropic("claude-sonnet-4-5-20250929")

# 約束為有效的電子郵件格式
lm += "Email: " + gen("email", regex=r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}")

# 約束為日期格式 (YYYY-MM-DD)
lm += "Date: " + gen("date", regex=r"\d{4}-\d{2}-\d{2}")

# 約束為電話號碼格式
lm += "Phone: " + gen("phone", regex=r"\d{3}-\d{3}-\d{4}")

print(lm["email"])  # 保證為有效的電子郵件
print(lm["date"])   # 保證為 YYYY-MM-DD 格式
```

**運作原理：**
- 正規表示式在 Token 層級轉換為文法
- 在生成過程中過濾掉無效的 Token
- 模型只能產生匹配的輸出

#### 選擇約束 (Selection Constraints)

```python
from guidance import models, gen, select

lm = models.Anthropic("claude-sonnet-4-5-20250929")

# 約束為特定選項
lm += "Sentiment: " + select(["positive", "negative", "neutral"], name="sentiment")

# 多選一
lm += "Best answer: " + select(
    ["A) Paris", "B) London", "C) Berlin", "D) Madrid"],
    name="answer"
)

print(lm["sentiment"])  # positive, negative, 或 neutral 其中之一
print(lm["answer"])     # A, B, C, 或 D 其中之一
```

### 3. Token 修復 (Token Healing)

Guidance 會自動「修復」提示詞 (Prompt) 與生成內容之間的 Token 邊界。

**問題：** Token 化會產生不自然的邊界。

```python
# 無 Token 修復時
prompt = "The capital of France is "
# 最後一個 Token: " is "
# 第一個生成的 Token 可能是 " Par" (帶有前導空格)
# 結果: "The capital of France is  Paris" (出現雙空格！)
```

**解決方案：** Guidance 會回退一個 Token 並重新生成。

```python
from guidance import models, gen

lm = models.Anthropic("claude-sonnet-4-5-20250929")

# Token 修復預設為啟用
lm += "The capital of France is " + gen("capital", max_tokens=5)
# 結果: "The capital of France is Paris" (正確的空格)
```

**優點：**
- 自然的文字邊界
- 不會出現尷尬的空格問題
- 更好的模型表現（模型看到自然的 Token 序列）

### 4. 基於文法的生成 (Grammar-Based Generation)

使用上下文無關文法 (CFG) 定義複雜的結構。

```python
from guidance import models, gen

lm = models.Anthropic("claude-sonnet-4-5-20250929")

# JSON 文法 (簡化版)
json_grammar = """
{
    "name": <gen name regex="[A-Za-z ]+" max_tokens=20>,
    "age": <gen age regex="[0-9]+" max_tokens=3>,
    "email": <gen email regex="[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}" max_tokens=50>
}
"""

# 生成有效的 JSON
lm += gen("person", grammar=json_grammar)

print(lm["person"])  # 保證為有效的 JSON 結構
```

**使用場景：**
- 複雜的結構化輸出
- 巢狀數據結構
- 程式語言語法
- 特定領域語言 (DSL)

### 5. Guidance 函式

使用 `@guidance` 裝飾器建立可重複使用的生成模式。

```python
from guidance import guidance, gen, models

@guidance
def generate_person(lm):
    """生成包含姓名和年齡的人物資訊。"""
    lm += "Name: " + gen("name", max_tokens=20, stop="\n")
    lm += "\nAge: " + gen("age", regex=r"[0-9]+", max_tokens=3)
    return lm

# 使用該函式
lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = generate_person(lm)

print(lm["name"])
print(lm["age"])
```

**有狀態函式 (Stateful Functions)：**

```python
@guidance(stateless=False)
def react_agent(lm, question, tools, max_rounds=5):
    """具備工具使用能力的 ReAct 代理人。"""
    lm += f"Question: {question}\n\n"

    for i in range(max_rounds):
        # 思考 (Thought)
        lm += f"Thought {i+1}: " + gen("thought", stop="\n")

        # 行動 (Action)
        lm += "\nAction: " + select(list(tools.keys()), name="action")

        # 執行工具
        tool_result = tools[lm["action"]]()
        lm += f"\nObservation: {tool_result}\n\n"

        # 檢查是否完成
        lm += "Done? " + select(["Yes", "No"], name="done")
        if lm["done"] == "Yes":
            break

    # 最終回答
    lm += "\nFinal Answer: " + gen("answer", max_tokens=100)
    return lm
```

## 後端配置

### Anthropic Claude

```python
from guidance import models

lm = models.Anthropic(
    model="claude-sonnet-4-5-20250929",
    api_key="your-api-key"  # 或設定 ANTHROPIC_API_KEY 環境變數
)
```

### OpenAI

```python
lm = models.OpenAI(
    model="gpt-4o-mini",
    api_key="your-api-key"  # 或設定 OPENAI_API_KEY 環境變數
)
```

### 本地模型 (Transformers)

```python
from guidance.models import Transformers

lm = Transformers(
    "microsoft/Phi-4-mini-instruct",
    device="cuda"  # 或 "cpu"
)
```

### 本地模型 (llama.cpp)

```python
from guidance.models import LlamaCpp

lm = LlamaCpp(
    model_path="/path/to/model.gguf",
    n_ctx=4096,
    n_gpu_layers=35
)
```

## 常見模式

### 模式 1：JSON 生成

```python
from guidance import models, gen, system, user, assistant

lm = models.Anthropic("claude-sonnet-4-5-20250929")

with system():
    lm += "You generate valid JSON."

with user():
    lm += "Generate a user profile with name, age, and email."

with assistant():
    lm += """{
    "name": """ + gen("name", regex=r'"[A-Za-z ]+"', max_tokens=30) + """,
    "age": """ + gen("age", regex=r"[0-9]+", max_tokens=3) + """,
    "email": """ + gen("email", regex=r'"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"', max_tokens=50) + """
}"""

print(lm)  # 保證為有效的 JSON
```

### 模式 2：分類

```python
from guidance import models, gen, select

lm = models.Anthropic("claude-sonnet-4-5-20250929")

text = "This product is amazing! I love it."

lm += f"Text: {text}\n"
lm += "Sentiment: " + select(["positive", "negative", "neutral"], name="sentiment")
lm += "\nConfidence: " + gen("confidence", regex=r"[0-9]+", max_tokens=3) + "%"

print(f"Sentiment: {lm['sentiment']}")
print(f"Confidence: {lm['confidence']}%")
```

### 模式 3：多步驟推理

```python
from guidance import models, gen, guidance

@guidance
def chain_of_thought(lm, question):
    """生成包含逐步推理的回答。"""
    lm += f"Question: {question}\n\n"

    # 生成多個推理步驟
    for i in range(3):
        lm += f"Step {i+1}: " + gen(f"step_{i+1}", stop="\n", max_tokens=100) + "\n"

    # 最終回答
    lm += "\nTherefore, the answer is: " + gen("answer", max_tokens=50)

    return lm

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = chain_of_thought(lm, "What is 15% of 200?")

print(lm["answer"])
```

### 模式 4：ReAct 代理人

```python
from guidance import models, gen, select, guidance

@guidance(stateless=False)
def react_agent(lm, question):
    """具備工具使用能力的 ReAct 代理人。"""
    tools = {
        "calculator": lambda expr: eval(expr),
        "search": lambda query: f"Search results for: {query}",
    }

    lm += f"Question: {question}\n\n"

    for round in range(5):
        # 思考 (Thought)
        lm += f"Thought: " + gen("thought", stop="\n") + "\n"

        # 選擇行動
        lm += "Action: " + select(["calculator", "search", "answer"], name="action")

        if lm["action"] == "answer":
            lm += "\nFinal Answer: " + gen("answer", max_tokens=100)
            break

        # 行動輸入
        lm += "\nAction Input: " + gen("action_input", stop="\n") + "\n"

        # 執行工具
        if lm["action"] in tools:
            result = tools[lm["action"]](lm["action_input"])
            lm += f"Observation: {result}\n\n"

    return lm

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = react_agent(lm, "What is 25 * 4 + 10?")
print(lm["answer"])
```

### 模式 5：數據提取

```python
from guidance import models, gen, guidance

@guidance
def extract_entities(lm, text):
    """從文字中提取結構化實體。"""
    lm += f"Text: {text}\n\n"

    # 提取人物
    lm += "Person: " + gen("person", stop="\n", max_tokens=30) + "\n"

    # 提取組織
    lm += "Organization: " + gen("organization", stop="\n", max_tokens=30) + "\n"

    # 提取日期
    lm += "Date: " + gen("date", regex=r"\d{4}-\d{2}-\d{2}", max_tokens=10) + "\n"

    # 提取地點
    lm += "Location: " + gen("location", stop="\n", max_tokens=30) + "\n"

    return lm

text = "Tim Cook announced at Apple Park on 2024-09-15 in Cupertino."

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = extract_entities(lm, text)

print(f"Person: {lm['person']}")
print(f"Organization: {lm['organization']}")
print(f"Date: {lm['date']}")
print(f"Location: {lm['location']}")
```

## 最佳實務

### 1. 使用正規表示式進行格式驗證

```python
# ✅ 建議：正規表示式確保格式有效
lm += "Email: " + gen("email", regex=r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}")

# ❌ 不建議：自由生成可能會產生無效的電子郵件
lm += "Email: " + gen("email", max_tokens=50)
```

### 2. 對於固定類別使用 select()

```python
# ✅ 建議：保證為有效的類別
lm += "Status: " + select(["pending", "approved", "rejected"], name="status")

# ❌ 不建議：可能會產生拼字錯誤或無效值
lm += "Status: " + gen("status", max_tokens=20)
```

### 3. 利用 Token 修復

```python
# Token 修復預設為啟用
# 不需要特殊操作 - 只要自然地串接即可
lm += "The capital is " + gen("capital")  # 自動修復
```

### 4. 使用停止序列 (stop sequences)

```python
# ✅ 建議：在換行處停止以獲得單行輸出
lm += "Name: " + gen("name", stop="\n")

# ❌ 不建議：可能會生成多行內容
lm += "Name: " + gen("name", max_tokens=50)
```

### 5. 建立可重複使用的函式

```python
# ✅ 建議：可重複使用的模式
@guidance
def generate_person(lm):
    lm += "Name: " + gen("name", stop="\n")
    lm += "\nAge: " + gen("age", regex=r"[0-9]+")
    return lm

# 多次使用
lm = generate_person(lm)
lm += "\n\n"
lm = generate_person(lm)
```

### 6. 平衡約束

```python
# ✅ 建議：合理的約束
lm += gen("name", regex=r"[A-Za-z ]+", max_tokens=30)

# ❌ 太嚴苛：可能會失敗或速度非常慢
lm += gen("name", regex=r"^(John|Jane)$", max_tokens=10)
```

## 與替代方案的比較

| 功能 | Guidance | Instructor | Outlines | LMQL |
|---------|----------|------------|----------|------|
| 正規表示式約束 | ✅ 是 | ❌ 否 | ✅ 是 | ✅ 是 |
| 文法支援 | ✅ CFG | ❌ 否 | ✅ CFG | ✅ CFG |
| Pydantic 驗證 | ❌ 否 | ✅ 是 | ✅ 是 | ❌ 否 |
| Token 修復 | ✅ 是 | ❌ 否 | ✅ 是 | ❌ 否 |
| 本地模型 | ✅ 是 | ⚠️ 有限 | ✅ 是 | ✅ 是 |
| API 模型 | ✅ 是 | ✅ 是 | ⚠️ 有限 | ✅ 是 |
| Python 語法 | ✅ 是 | ✅ 是 | ✅ 是 | ❌ 類 SQL |
| 學習曲線 | 低 | 低 | 中 | 高 |

**何時選擇 Guidance：**
- 需要正規表示式/文法約束
- 需要 Token 修復
- 使用控制流構建複雜的工作流
- 使用本地模型 (Transformers, llama.cpp)
- 偏好 Python 語法

**何時選擇替代方案：**
- Instructor：需要具備自動重試功能的 Pydantic 驗證
- Outlines：需要 JSON Schema 驗證
- LMQL：偏好宣告式查詢語法

## 效能特性

**降低延遲：**
- 對於受限輸出，比傳統提示方法快 30-50%
- Token 修復減少了不必要的重新生成
- 文法約束防止生成無效的 Token

**記憶體使用：**
- 與無約束生成相比，開銷極小
- 文法編譯在第一次使用後會被快取
- 推論時進行高效的 Token 過濾

**Token 效率：**
- 防止在無效輸出上浪費 Token
- 無需重試迴圈
- 直接生成有效的輸出

## 相關資源

- **官方文件**：https://guidance.readthedocs.io
- **GitHub**：https://github.com/guidance-ai/guidance (18k+ stars)
- **Notebooks**：https://github.com/guidance-ai/guidance/tree/main/notebooks
- **Discord**：提供社群支援

## 延伸閱讀

- `references/constraints.md` - 全面的正規表示式和文法模式
- `references/backends.md` - 特定後端的配置
- `references/examples.md` - 生產就緒的範例
