---
name: outlines
description: 在生成過程中保證有效的 JSON/XML/程式碼結構，使用 Pydantic 模型進行型別安全輸出，支援本地模型 (Transformers, vLLM)，並使用 Outlines (dottxt.ai 的結構化生成庫) 最大化推論速度。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [outlines, transformers, vllm, pydantic]
metadata:
  hermes:
    tags: [提示工程, Outlines, 結構化生成, JSON Schema, Pydantic, 本地模型, 基於文法的生成, vLLM, Transformers, 型別安全]

---

# Outlines: 結構化文字生成 (Structured Text Generation)

## 何時使用此技能

當您需要執行以下操作時，請使用 Outlines：
- 在生成過程中**保證有效的 JSON/XML/程式碼**結構
- **使用 Pydantic 模型**進行型別安全輸出
- **支援本地模型** (Transformers, llama.cpp, vLLM)
- 通過零開銷 (Zero-overhead) 的結構化生成**最大化推論速度**
- 自動**根據 JSON Schema 生成內容**
- 在文法層級**控制 Token 採樣**

**GitHub 星星數**：8,000+ | **來源**：dottxt.ai (原 .txt)

## 安裝

```bash
# 基礎安裝
pip install outlines

# 安裝特定後端
pip install outlines transformers  # Hugging Face 模型
pip install outlines llama-cpp-python  # llama.cpp
pip install outlines vllm  # 用於高吞吐量的 vLLM
```

## 快速入門

### 基本範例：分類

```python
import outlines
from typing import Literal

# 載入模型
model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")

# 使用型別約束進行生成
prompt = "Sentiment of 'This product is amazing!': "
generator = outlines.generate.choice(model, ["positive", "negative", "neutral"])
sentiment = generator(prompt)

print(sentiment)  # "positive" (保證為選項之一)
```

### 使用 Pydantic 模型

```python
from pydantic import BaseModel
import outlines

class User(BaseModel):
    name: str
    age: int
    email: str

model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")

# 生成結構化輸出
prompt = "Extract user: John Doe, 30 years old, john@example.com"
generator = outlines.generate.json(model, User)
user = generator(prompt)

print(user.name)   # "John Doe"
print(user.age)    # 30
print(user.email)  # "john@example.com"
```

## 核心概念

### 1. 受限 Token 採樣 (Constrained Token Sampling)

Outlines 使用有限狀態機 (FSM) 在 Logit 層級約束 Token 的生成。

**運作原理：**
1. 將 Schema (JSON/Pydantic/正規表示式) 轉換為上下文無關文法 (CFG)
2. 將 CFG 轉換為有限狀態機 (FSM)
3. 在生成過程中的每一步過濾掉無效的 Token
4. 當僅存在一個有效 Token 時進行快速前進 (Fast-forward)

**優點：**
- **零開銷 (Zero-overhead)**：過濾發生在 Token 層級
- **速度提升**：在確定性路徑上快速跳過
- **保證有效性**：不可能產生無效的輸出

```python
import outlines

# Pydantic 模型 -> JSON Schema -> CFG -> FSM
class Person(BaseModel):
    name: str
    age: int

model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")

# 幕後操作：
# 1. Person -> JSON Schema
# 2. JSON Schema -> CFG
# 3. CFG -> FSM
# 4. FSM 在生成期間過濾 Token

generator = outlines.generate.json(model, Person)
result = generator("Generate person: Alice, 25")
```

### 2. 結構化生成器 (Structured Generators)

Outlines 為不同的輸出類型提供專門的生成器。

#### 選擇生成器 (Choice Generator)

```python
# 多選一
generator = outlines.generate.choice(
    model,
    ["positive", "negative", "neutral"]
)

sentiment = generator("Review: This is great!")
# 結果：三個選項之一
```

#### JSON 生成器

```python
from pydantic import BaseModel

class Product(BaseModel):
    name: str
    price: float
    in_stock: bool

# 生成符合 Schema 的有效 JSON
generator = outlines.generate.json(model, Product)
product = generator("Extract: iPhone 15, $999, available")

# 保證為有效的 Product 實例
print(type(product))  # <class '__main__.Product'>
```

#### 正規表示式生成器 (Regex Generator)

```python
# 生成符合正規表示式的文字
generator = outlines.generate.regex(
    model,
    r"[0-9]{3}-[0-9]{3}-[0-9]{4}"  # 電話號碼模式
)

phone = generator("Generate phone number:")
# 結果："555-123-4567" (保證符合模式)
```

#### 整數/浮點數生成器

```python
# 生成特定數值型別
int_generator = outlines.generate.integer(model)
age = int_generator("Person's age:")  # 保證為整數

float_generator = outlines.generate.float(model)
price = float_generator("Product price:")  # 保證為浮點數
```

### 3. 模型後端 (Model Backends)

Outlines 支援多個本地與基於 API 的後端。

#### Transformers (Hugging Face)

```python
import outlines

# 從 Hugging Face 載入
model = outlines.models.transformers(
    "microsoft/Phi-3-mini-4k-instruct",
    device="cuda"  # 或 "cpu"
)

# 搭配任何生成器使用
generator = outlines.generate.json(model, YourModel)
```

#### llama.cpp

```python
# 載入 GGUF 模型
model = outlines.models.llamacpp(
    "./models/llama-3.1-8b-instruct.Q4_K_M.gguf",
    n_gpu_layers=35
)

generator = outlines.generate.json(model, YourModel)
```

#### vLLM (高吞吐量)

```python
# 用於生產部署
model = outlines.models.vllm(
    "meta-llama/Llama-3.1-8B-Instruct",
    tensor_parallel_size=2  # 多 GPU 並行
)

generator = outlines.generate.json(model, YourModel)
```

#### OpenAI (有限支援)

```python
# 基礎 OpenAI 支援
model = outlines.models.openai(
    "gpt-4o-mini",
    api_key="your-api-key"
)

# 注意：某些功能在 API 模型中受限
generator = outlines.generate.json(model, YourModel)
```

### 4. Pydantic 整合

Outlines 具備原生的 Pydantic 支援，可自動進行 Schema 轉換。

#### 基礎模型

```python
from pydantic import BaseModel, Field

class Article(BaseModel):
    title: str = Field(description="Article title")
    author: str = Field(description="Author name")
    word_count: int = Field(description="Number of words", gt=0)
    tags: list[str] = Field(description="List of tags")

model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
generator = outlines.generate.json(model, Article)

article = generator("Generate article about AI")
print(article.title)
print(article.word_count)  # 保證 > 0
```

#### 巢狀模型 (Nested Models)

```python
class Address(BaseModel):
    street: str
    city: str
    country: str

class Person(BaseModel):
    name: str
    age: int
    address: Address  # 巢狀模型

generator = outlines.generate.json(model, Person)
person = generator("Generate person in New York")

print(person.address.city)  # "New York"
```

#### 列舉 (Enums) 與字面量 (Literals)

```python
from enum import Enum
from typing import Literal

class Status(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"

class Application(BaseModel):
    applicant: str
    status: Status  # 必須是列舉值之一
    priority: Literal["low", "medium", "high"]  # 必須是字面量之一

generator = outlines.generate.json(model, Application)
app = generator("Generate application")

print(app.status)  # Status.PENDING (或 APPROVED/REJECTED)
```

## 常見模式

### 模式 1：資料提取

```python
from pydantic import BaseModel
import outlines

class CompanyInfo(BaseModel):
    name: str
    founded_year: int
    industry: str
    employees: int

model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
generator = outlines.generate.json(model, CompanyInfo)

text = """
Apple Inc. was founded in 1976 in the technology industry.
The company employs approximately 164,000 people worldwide.
"""

prompt = f"Extract company information:\n{text}\n\nCompany:"
company = generator(prompt)

print(f"Name: {company.name}")
print(f"Founded: {company.founded_year}")
print(f"Industry: {company.industry}")
print(f"Employees: {company.employees}")
```

### 模式 2：分類

```python
from typing import Literal
import outlines

model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")

# 二元分類
generator = outlines.generate.choice(model, ["spam", "not_spam"])
result = generator("Email: Buy now! 50% off!")

# 多類別分類
categories = ["technology", "business", "sports", "entertainment"]
category_gen = outlines.generate.choice(model, categories)
category = category_gen("Article: Apple announces new iPhone...")

# 帶有置信度 (Confidence) 的分類
class Classification(BaseModel):
    label: Literal["positive", "negative", "neutral"]
    confidence: float

classifier = outlines.generate.json(model, Classification)
result = classifier("Review: This product is okay, nothing special")
```

### 模式 3：結構化表單

```python
class UserProfile(BaseModel):
    full_name: str
    age: int
    email: str
    phone: str
    country: str
    interests: list[str]

model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
generator = outlines.generate.json(model, UserProfile)

prompt = """
Extract user profile from:
Name: Alice Johnson
Age: 28
Email: alice@example.com
Phone: 555-0123
Country: USA
Interests: hiking, photography, cooking
"""

profile = generator(prompt)
print(profile.full_name)
print(profile.interests)  # ["hiking", "photography", "cooking"]
```

### 模式 4：多實體提取 (Multi-Entity Extraction)

```python
class Entity(BaseModel):
    name: str
    type: Literal["PERSON", "ORGANIZATION", "LOCATION"]

class DocumentEntities(BaseModel):
    entities: list[Entity]

model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
generator = outlines.generate.json(model, DocumentEntities)

text = "Tim Cook met with Satya Nadella at Microsoft headquarters in Redmond."
prompt = f"Extract entities from: {text}"

result = generator(prompt)
for entity in result.entities:
    print(f"{entity.name} ({entity.type})")
```

### 模式 5：程式碼生成

```python
class PythonFunction(BaseModel):
    function_name: str
    parameters: list[str]
    docstring: str
    body: str

model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
generator = outlines.generate.json(model, PythonFunction)

prompt = "Generate a Python function to calculate factorial"
func = generator(prompt)

print(f"def {func.function_name}({', '.join(func.parameters)}):")
print(f'    """{func.docstring}"""')
print(f"    {func.body}")
```

### 模式 6：批次處理 (Batch Processing)

```python
def batch_extract(texts: list[str], schema: type[BaseModel]):
    """從多段文字中提取結構化數據。"""
    model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
    generator = outlines.generate.json(model, schema)

    results = []
    for text in texts:
        result = generator(f"Extract from: {text}")
        results.append(result)

    return results

class Person(BaseModel):
    name: str
    age: int

texts = [
    "John is 30 years old",
    "Alice is 25 years old",
    "Bob is 40 years old"
]

people = batch_extract(texts, Person)
for person in people:
    print(f"{person.name}: {person.age}")
```

## 後端配置

### Transformers

```python
import outlines

# 基礎用法
model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")

# GPU 配置
model = outlines.models.transformers(
    "microsoft/Phi-3-mini-4k-instruct",
    device="cuda",
    model_kwargs={"torch_dtype": "float16"}
)

# 熱門模型
model = outlines.models.transformers("meta-llama/Llama-3.1-8B-Instruct")
model = outlines.models.transformers("mistralai/Mistral-7B-Instruct-v0.3")
model = outlines.models.transformers("Qwen/Qwen2.5-7B-Instruct")
```

### llama.cpp

```python
# 載入 GGUF 模型
model = outlines.models.llamacpp(
    "./models/llama-3.1-8b.Q4_K_M.gguf",
    n_ctx=4096,         # 上下文視窗
    n_gpu_layers=35,    # GPU 層數
    n_threads=8         # CPU 執行緒數
)

# 完全 GPU 卸載
model = outlines.models.llamacpp(
    "./models/model.gguf",
    n_gpu_layers=-1  # 所有層均在 GPU 上
)
```

### vLLM (生產環境)

```python
# 單 GPU
model = outlines.models.vllm("meta-llama/Llama-3.1-8B-Instruct")

# 多 GPU 並行
model = outlines.models.vllm(
    "meta-llama/Llama-3.1-70B-Instruct",
    tensor_parallel_size=4  # 4 顆 GPU
)

# 搭配量化
model = outlines.models.vllm(
    "meta-llama/Llama-3.1-8B-Instruct",
    quantization="awq"  # 或 "gptq"
)
```

## 最佳實務

### 1. 使用明確的型別

```python
# ✅ 建議：使用明確的型別
class Product(BaseModel):
    name: str
    price: float  # 而非 str
    quantity: int  # 而非 str
    in_stock: bool  # 而非 str

# ❌ 不建議：全部使用字串
class Product(BaseModel):
    name: str
    price: str  # 應為 float
    quantity: str  # 應為 int
```

### 2. 新增約束 (Constraints)

```python
from pydantic import Field

# ✅ 建議：帶有約束條件
class User(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    age: int = Field(ge=0, le=120)
    email: str = Field(pattern=r"^[\w\.-]+@[\w\.-]+\.\w+$")

# ❌ 不建議：無約束條件
class User(BaseModel):
    name: str
    age: int
    email: str
```

### 3. 對於類別使用列舉 (Enums)

```python
# ✅ 建議：針對固定集合使用列舉
class Priority(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"

class Task(BaseModel):
    title: str
    priority: Priority

# ❌ 不建議：使用自由格式的字串
class Task(BaseModel):
    title: str
    priority: str  # 可能會是任何內容
```

### 4. 在提示詞中提供上下文

```python
# ✅ 建議：清晰的上下文
prompt = """
Extract product information from the following text.
Text: iPhone 15 Pro costs $999 and is currently in stock.
Product:
"""

# ❌ 不建議：極簡的上下文
prompt = "iPhone 15 Pro costs $999 and is currently in stock."
```

### 5. 處理選填欄位 (Optional Fields)

```python
from typing import Optional

# ✅ 建議：針對不完整的數據使用選填欄位
class Article(BaseModel):
    title: str  # 必填
    author: Optional[str] = None  # 選填
    date: Optional[str] = None  # 選填
    tags: list[str] = []  # 預設為空列表

# 即使遺失作者或日期資訊也能成功生成
```

## 與替代方案的比較

| 功能 | Outlines | Instructor | Guidance | LMQL |
|---------|----------|------------|----------|------|
| Pydantic 支援 | ✅ 原生 | ✅ 原生 | ❌ 否 | ❌ 否 |
| JSON Schema | ✅ 是 | ✅ 是 | ⚠️ 有限 | ✅ 是 |
| 正規表示式約束 | ✅ 是 | ❌ 否 | ✅ 是 | ✅ 是 |
| 本地模型 | ✅ 完整 | ⚠️ 有限 | ✅ 完整 | ✅ 完整 |
| API 模型 | ⚠️ 有限 | ✅ 完整 | ✅ 完整 | ✅ 完整 |
| 零開銷 | ✅ 是 | ❌ 否 | ⚠️ 部分 | ✅ 是 |
| 自動重試 | ❌ 否 | ✅ 是 | ❌ 否 | ❌ 否 |
| 學習曲線 | 低 | 低 | 低 | 高 |

**何時選擇 Outlines：**
- 使用本地模型 (Transformers, llama.cpp, vLLM)
- 需要極致的推論速度
- 想要 Pydantic 模型支援
- 需要零開銷的結構化生成
- 控制 Token 採樣過程

**何時選擇替代方案：**
- Instructor：需要具備自動重試功能的 API 模型
- Guidance：需要 Token 修復和複雜的工作流
- LMQL：偏好宣告式查詢語法

## 效能特性

**速度：**
- **零開銷**：結構化生成速度與無約束生成一樣快
- **快速前進優化**：跳過確定性 Token
- 比生成後再驗證的方法**快 1.2-2 倍**

**記憶體：**
- 每個 Schema 編譯一次 FSM (已快取)
- 運行時開銷極小
- 搭配 vLLM 處理高吞吐量非常高效

**準確度：**
- **100% 有效輸出** (由 FSM 保證)
- 無需重試迴圈
- 確定性 Token 過濾

## 相關資源

- **官方文件**：https://outlines-dev.github.io/outlines
- **GitHub**：https://github.com/outlines-dev/outlines (8k+ stars)
- **Discord**：https://discord.gg/R9DSu34mGd
- **部落格**：https://blog.dottxt.co

## 延伸閱讀

- `references/json_generation.md` - 全面的 JSON 與 Pydantic 模式
- `references/backends.md` - 特定後端的配置
- `references/examples.md` - 生產就緒的範例
