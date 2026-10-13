---
name: instructor
description: 使用 Pydantic 驗證從 LLM 回應中擷取結構化資料，自動重試失敗的擷取，解析具備類型安全性的複雜 JSON，並使用 Instructor 串流傳輸部分結果 —— 經實戰測試的結構化輸出庫。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [instructor, pydantic, openai, anthropic]
metadata:
  hermes:
    tags: [提示工程, Instructor, 結構化輸出, Pydantic, 資料擷取, JSON 解析, 類型安全性, 驗證, 串流, OpenAI, Anthropic]

---

# Instructor：結構化 LLM 輸出

## 何時使用此技能

當您需要執行以下操作時，請使用 Instructor：
- 穩定地從 LLM 回應中**擷取結構化資料**
- 自動根據 Pydantic 模式**驗證輸出**
- 透過自動錯誤處理**重試失敗的擷取**
- 解析具備類型安全性與驗證功能的**複雜 JSON**
- 為即時處理**串流傳輸部分結果**
- 透過一致的 API **支援多個 LLM 供應商**

**GitHub 星星數**：15,000+ | **經實戰測試**：100,000+ 位開發者

## 安裝

```bash
# 基礎安裝
pip install instructor

# 針對特定供應商
pip install "instructor[anthropic]"  # Anthropic Claude
pip install "instructor[openai]"     # OpenAI
pip install "instructor[all]"        # 所有供應商
```

## 快速入門

### 基本範例：擷取使用者資料

```python
import instructor
from pydantic import BaseModel
from anthropic import Anthropic

# 定義輸出結構
class User(BaseModel):
    name: str
    age: int
    email: str

# 建立 instructor 用戶端
client = instructor.from_anthropic(Anthropic())

# 擷取結構化資料
user = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": "John Doe is 30 years old. His email is john@example.com"
    }],
    response_model=User
)

print(user.name)   # "John Doe"
print(user.age)    # 30
print(user.email)  # "john@example.com"
```

### 使用 OpenAI

```python
from openai import OpenAI

client = instructor.from_openai(OpenAI())

user = client.chat.completions.create(
    model="gpt-4o-mini",
    response_model=User,
    messages=[{"role": "user", "content": "Extract: Alice, 25, alice@email.com"}]
)
```

## 核心概念

### 1. 回應模型 (Pydantic)

回應模型定義了 LLM 輸出的結構和驗證規則。

#### 基礎模型

```python
from pydantic import BaseModel, Field

class Article(BaseModel):
    title: str = Field(description="文章標題")
    author: str = Field(description="作者姓名")
    word_count: int = Field(description="字數", gt=0)
    tags: list[str] = Field(description="相關標籤列表")

article = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": "Analyze this article: [article text]"
    }],
    response_model=Article
)
```

**優點：**
- 具備 Python 類型提示的類型安全性
- 自動驗證 (word_count > 0)
- 透過 Field 描述實現自我文件化
- IDE 自動補全支援

#### 巢狀模型

```python
class Address(BaseModel):
    street: str
    city: str
    country: str

class Person(BaseModel):
    name: str
    age: int
    address: Address  # 巢狀模型

person = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": "John lives at 123 Main St, Boston, USA"
    }],
    response_model=Person
)

print(person.address.city)  # "Boston"
```

#### 選填欄位

```python
from typing import Optional

class Product(BaseModel):
    name: str
    price: float
    discount: Optional[float] = None  # 選填
    description: str = Field(default="No description")  # 預設值

# LLM 不需要提供 discount 或 description
```

#### 用於限制的列舉 (Enums)

```python
from enum import Enum

class Sentiment(str, Enum):
    POSITIVE = "positive"
    NEGATIVE = "negative"
    NEUTRAL = "neutral"

class Review(BaseModel):
    text: str
    sentiment: Sentiment  # 僅允許這 3 個值

review = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": "This product is amazing!"
    }],
    response_model=Review
)

print(review.sentiment)  # Sentiment.POSITIVE
```

### 2. 驗證

Pydantic 會自動驗證 LLM 輸出。如果驗證失敗，Instructor 會重試。

#### 內建驗證器

```python
from pydantic import Field, EmailStr, HttpUrl

class Contact(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    age: int = Field(ge=0, le=120)  # 0 <= age <= 120
    email: EmailStr  # 驗證電子郵件格式
    website: HttpUrl  # 驗證 URL 格式

# 如果 LLM 提供無效資料，Instructor 會自動重試
```

#### 自訂驗證器

```python
from pydantic import field_validator

class Event(BaseModel):
    name: str
    date: str
    attendees: int

    @field_validator('date')
    def validate_date(cls, v):
        """確保日期格式為 YYYY-MM-DD。"""
        import re
        if not re.match(r'\d{4}-\d{2}-\d{2}', v):
            raise ValueError('Date must be YYYY-MM-DD format')
        return v

    @field_validator('attendees')
    def validate_attendees(cls, v):
        """確保參加人數為正數。"""
        if v < 1:
            raise ValueError('Must have at least 1 attendee')
        return v
```

#### 模型級別驗證

```python
from pydantic import model_validator

class DateRange(BaseModel):
    start_date: str
    end_date: str

    @model_validator(mode='after')
    def check_dates(self):
        """確保 end_date 在 start_date 之後。"""
        from datetime import datetime
        start = datetime.strptime(self.start_date, '%Y-%m-%d')
        end = datetime.strptime(self.end_date, '%Y-%m-%d')

        if end < start:
            raise ValueError('end_date must be after start_date')
        return self
```

### 3. 自動重試

當驗證失敗時，Instructor 會自動重試，並向 LLM 提供錯誤回饋。

```python
# 如果驗證失敗，最多重試 3 次
user = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": "Extract user from: John, age unknown"
    }],
    response_model=User,
    max_retries=3  # 預設為 3
)

# 如果無法擷取年齡，Instructor 會告訴 LLM：
# "Validation error: age - field required"
# LLM 會嘗試進行更好的擷取
```

**工作原理：**
1. LLM 產生輸出
2. Pydantic 進行驗證
3. 若無效：將錯誤訊息傳回給 LLM
4. LLM 根據錯誤回饋再次嘗試
5. 重複執行直到達到最大重試次數

### 4. 串流傳輸

串流傳輸部分結果以進行即時處理。

#### 串流傳輸部分物件

```python
from instructor import Partial

class Story(BaseModel):
    title: str
    content: str
    tags: list[str]

# 在 LLM 產生時串流傳輸部分更新
for partial_story in client.messages.create_partial(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": "Write a short sci-fi story"
    }],
    response_model=Story
):
    print(f"Title: {partial_story.title}")
    print(f"Content so far: {partial_story.content[:100]}...")
    # 即時更新 UI
```

#### 串流傳輸可迭代物件

```python
class Task(BaseModel):
    title: str
    priority: str

# 在列表項目產生時進行串流傳輸
tasks = client.messages.create_iterable(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": "Generate 10 project tasks"
    }],
    response_model=Task
)

for task in tasks:
    print(f"- {task.title} ({task.priority})")
    # 在每個任務到達時進行處理
```

## 供應商配置

### Anthropic Claude

```python
import instructor
from anthropic import Anthropic

client = instructor.from_anthropic(
    Anthropic(api_key="your-api-key")
)

# 與 Claude 模型搭配使用
response = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[...],
    response_model=YourModel
)
```

### OpenAI

```python
from openai import OpenAI

client = instructor.from_openai(
    OpenAI(api_key="your-api-key")
)

response = client.chat.completions.create(
    model="gpt-4o-mini",
    response_model=YourModel,
    messages=[...]
)
```

### 本地模型 (Ollama)

```python
from openai import OpenAI

# 指向本地 Ollama 伺服器
client = instructor.from_openai(
    OpenAI(
        base_url="http://localhost:11434/v1",
        api_key="ollama"  # 必要但會被忽略
    ),
    mode=instructor.Mode.JSON
)

response = client.chat.completions.create(
    model="llama3.1",
    response_model=YourModel,
    messages=[...]
)
```

## 常見模式

### 模式 1：從文本中擷取資料

```python
class CompanyInfo(BaseModel):
    name: str
    founded_year: int
    industry: str
    employees: int
    headquarters: str

text = """
Tesla, Inc. was founded in 2003. It operates in the automotive and energy
industry with approximately 140,000 employees. The company is headquartered
in Austin, Texas.
"""

company = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": f"Extract company information from: {text}"
    }],
    response_model=CompanyInfo
)
```

### 模式 2：分類

```python
class Category(str, Enum):
    TECHNOLOGY = "technology"
    FINANCE = "finance"
    HEALTHCARE = "healthcare"
    EDUCATION = "education"
    OTHER = "other"

class ArticleClassification(BaseModel):
    category: Category
    confidence: float = Field(ge=0.0, le=1.0)
    keywords: list[str]

classification = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": "Classify this article: [article text]"
    }],
    response_model=ArticleClassification
)
```

### 模式 3：多實體擷取

```python
class Person(BaseModel):
    name: str
    role: str

class Organization(BaseModel):
    name: str
    industry: str

class Entities(BaseModel):
    people: list[Person]
    organizations: list[Organization]
    locations: list[str]

text = "Tim Cook, CEO of Apple, announced at the event in Cupertino..."

entities = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": f"Extract all entities from: {text}"
    }],
    response_model=Entities
)

for person in entities.people:
    print(f"{person.name} - {person.role}")
```

### 模式 4：結構化分析

```python
class SentimentAnalysis(BaseModel):
    overall_sentiment: Sentiment
    positive_aspects: list[str]
    negative_aspects: list[str]
    suggestions: list[str]
    score: float = Field(ge=-1.0, le=1.0)

review = "The product works well but setup was confusing..."

analysis = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": f"Analyze this review: {review}"
    }],
    response_model=SentimentAnalysis
)
```

### 模式 5：批次處理

```python
def extract_person(text: str) -> Person:
    return client.messages.create(
        model="claude-sonnet-4-5-20250929",
        max_tokens=1024,
        messages=[{
            "role": "user",
            "content": f"Extract person from: {text}"
        }],
        response_model=Person
    )

texts = [
    "John Doe is a 30-year-old engineer",
    "Jane Smith, 25, works in marketing",
    "Bob Johnson, age 40, software developer"
]

people = [extract_person(text) for text in texts]
```

## 進階功能

### 聯集類型 (Union Types)

```python
from typing import Union

class TextContent(BaseModel):
    type: str = "text"
    content: str

class ImageContent(BaseModel):
    type: str = "image"
    url: HttpUrl
    caption: str

class Post(BaseModel):
    title: str
    content: Union[TextContent, ImageContent]  # 任一類型

# LLM 根據內容選擇合適的類型
```

### 動態模型

```python
from pydantic import create_model

# 在執行期建立模型
DynamicUser = create_model(
    'User',
    name=(str, ...),
    age=(int, Field(ge=0)),
    email=(EmailStr, ...)
)

user = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[...],
    response_model=DynamicUser
)
```

### 自訂模式 (Modes)

```python
# 適用於沒有原生結構化輸出功能的供應商
client = instructor.from_anthropic(
    Anthropic(),
    mode=instructor.Mode.JSON  # JSON 模式
)

# 可用模式：
# - Mode.ANTHROPIC_TOOLS (Claude 推薦使用)
# - Mode.JSON (備用方案)
# - Mode.TOOLS (OpenAI 工具)
```

### 上下文管理

```python
# 單次使用的用戶端
with instructor.from_anthropic(Anthropic()) as client:
    result = client.messages.create(
        model="claude-sonnet-4-5-20250929",
        max_tokens=1024,
        messages=[...],
        response_model=YourModel
    )
    # 用戶端自動關閉
```

## 錯誤處理

### 處理驗證錯誤

```python
from pydantic import ValidationError

try:
    user = client.messages.create(
        model="claude-sonnet-4-5-20250929",
        max_tokens=1024,
        messages=[...],
        response_model=User,
        max_retries=3
    )
except ValidationError as e:
    print(f"Failed after retries: {e}")
    # 優雅地處理錯誤

except Exception as e:
    print(f"API error: {e}")
```

### 自訂錯誤訊息

```python
class ValidatedUser(BaseModel):
    name: str = Field(description="全名，2-100 個字元")
    age: int = Field(description="年齡介於 0 到 120 之間", ge=0, le=120)
    email: EmailStr = Field(description="有效的電子郵件地址")

    class Config:
        # 自訂錯誤訊息
        json_schema_extra = {
            "examples": [
                {
                    "name": "John Doe",
                    "age": 30,
                    "email": "john@example.com"
                }
            ]
        }
```

## 最佳實踐

### 1. 清晰的欄位描述

```python
# ❌ 不良：模糊不清
class Product(BaseModel):
    name: str
    price: float

# ✅ 良好：具備描述性
class Product(BaseModel):
    name: str = Field(description="文本中的產品名稱")
    price: float = Field(description="以美金計價的價格，不含貨幣符號")
```

### 2. 使用合適的驗證

```python
# ✅ 良好：限制值
class Rating(BaseModel):
    score: int = Field(ge=1, le=5, description="1 到 5 星評分")
    review: str = Field(min_length=10, description="評論文本，至少 10 個字元")
```

### 3. 在提示詞中提供範例

```python
messages = [{
    "role": "user",
    "content": """Extract person info from: "John, 30, engineer"

Example format:
{
  "name": "John Doe",
  "age": 30,
  "occupation": "engineer"
}"""
}]
```

### 4. 針對固定類別使用列舉 (Enums)

```python
# ✅ 良好：Enum 確保值有效
class Status(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"

class Application(BaseModel):
    status: Status  # LLM 必須從 enum 中選擇
```

### 5. 優雅地處理缺失資料

```python
class PartialData(BaseModel):
    required_field: str
    optional_field: Optional[str] = None
    default_field: str = "default_value"

# LLM 僅需要提供 required_field
```

## 替代方案比較

| 功能 | Instructor | 手動 JSON | LangChain | DSPy |
|---------|------------|-------------|-----------|------|
| 類型安全性 | ✅ 是 | ❌ 否 | ⚠️ 部分 | ✅ 是 |
| 自動驗證 | ✅ 是 | ❌ 否 | ❌ 否 | ⚠️ 有限 |
| 自動重試 | ✅ 是 | ❌ 否 | ❌ 否 | ✅ 是 |
| 串流傳輸 | ✅ 是 | ❌ 否 | ✅ 是 | ❌ 否 |
| 多供應商 | ✅ 是 | ⚠️ 手動 | ✅ 是 | ✅ 是 |
| 學習曲線 | 低 | 低 | 中 | 高 |

**為何選擇 Instructor：**
- 需要結構化、經驗證的輸出
- 想要類型安全性與 IDE 支援
- 需要自動重試功能
- 正在建立資料擷取系統

**為何選擇替代方案：**
- DSPy：需要提示詞優化
- LangChain：正在建立複雜的鏈結
- 手動：簡單、一次性的擷取

## 資源

- **文件**：https://python.useinstructor.com
- **GitHub**：https://github.com/jxnl/instructor (15k+ 星)
- **食譜 (Cookbook)**：https://python.useinstructor.com/examples
- **Discord**：提供社群支援

## 另請參閱

- `references/validation.md` - 進階驗證模式
- `references/providers.md` - 特定供應商配置
- `references/examples.md` - 真實世界使用案例
