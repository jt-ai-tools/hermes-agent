# JSON 生成全攻略

有關使用 Outlines 搭配 Pydantic 模型與 JSON schema 進行 JSON 生成的完整指南。

## 目錄
- Pydantic 模型
- JSON Schema 支援
- 進階模式
- 巢狀結構
- 複雜類型
- 驗證
- 效能優化

## Pydantic 模型

### 基本模型

```python
from pydantic import BaseModel
import outlines

class User(BaseModel):
    name: str
    age: int
    email: str

model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
generator = outlines.generate.json(model, User)

user = generator("生成使用者：Alice, 25, alice@example.com")
print(user.name)   # "Alice"
print(user.age)    # 25
print(user.email)  # "alice@example.com"
```

### 欄位約束

```python
from pydantic import BaseModel, Field

class Product(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    price: float = Field(gt=0, description="以美金計價的價格")
    discount: float = Field(ge=0, le=100, description="折扣百分比")
    quantity: int = Field(ge=0, description="可用庫存數量")
    sku: str = Field(pattern=r"^[A-Z]{3}-\d{6}$")

model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
generator = outlines.generate.json(model, Product)

product = generator("生成產品：iPhone 15, $999")
# 所有欄位均保證符合約束條件
```

**可用約束：**
- `min_length`, `max_length`: 字串長度
- `gt`, `ge`, `lt`, `le`: 數值比較 (大於、大於等於、小於、小於等於)
- `multiple_of`: 數值必須是該值的倍數
- `pattern`: 字串的正則表達式 (Regex) 模式
- `min_items`, `max_items`: 列表長度

### 選填欄位

```python
from typing import Optional

class Article(BaseModel):
    title: str  # 必填
    author: Optional[str] = None  # 選填
    published_date: Optional[str] = None  # 選填
    tags: list[str] = []  # 預設為空列表
    view_count: int = 0  # 預設值

generator = outlines.generate.json(model, Article)

# 即使缺少選填欄位也能生成
article = generator("標題：AI 簡介")
print(article.author)  # None (未提供)
print(article.tags)    # [] (預設值)
```

### 預設值

```python
class Config(BaseModel):
    debug: bool = False
    max_retries: int = 3
    timeout: float = 30.0
    log_level: str = "INFO"

# 未指定時，產生器會使用預設值
generator = outlines.generate.json(model, Config)
config = generator("生成啟用了 debug 的配置")
print(config.debug)  # True (來自提示詞)
print(config.timeout)  # 30.0 (預設值)
```

## 列舉與字面值

### 列舉欄位

```python
from enum import Enum

class Status(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    CANCELLED = "cancelled"

class Application(BaseModel):
    applicant_name: str
    status: Status  # 必須是列舉值之一
    submitted_date: str

generator = outlines.generate.json(model, Application)
app = generator("為 John Doe 生成申請表")

print(app.status)  # Status.PENDING (或列舉值之一)
print(type(app.status))  # <enum 'Status'>
```

### 字面類型

```python
from typing import Literal

class Task(BaseModel):
    title: str
    priority: Literal["low", "medium", "high", "critical"]
    status: Literal["todo", "in_progress", "done"]
    assigned_to: str

generator = outlines.generate.json(model, Task)
task = generator("建立高優先權任務：修復錯誤")

print(task.priority)  # 必為："low", "medium", "high", "critical" 之一
```

### 多選欄位

```python
class Survey(BaseModel):
    question: str
    answer: Literal["strongly_disagree", "disagree", "neutral", "agree", "strongly_agree"]
    confidence: Literal["low", "medium", "high"]

generator = outlines.generate.json(model, Survey)
survey = generator("評分：'我喜歡使用這款產品'")
```

## 巢狀結構

### 巢狀模型

```python
class Address(BaseModel):
    street: str
    city: str
    state: str
    zip_code: str
    country: str = "USA"

class Person(BaseModel):
    name: str
    age: int
    email: str
    address: Address  # 巢狀模型

model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
generator = outlines.generate.json(model, Person)

prompt = """
提取人物：
姓名: Alice Johnson
年齡: 28
電子郵件: alice@example.com
地址: 123 Main St, Boston, MA, 02101
"""

person = generator(prompt)
print(person.name)  # "Alice Johnson"
print(person.address.city)  # "Boston"
print(person.address.state)  # "MA"
```

### 深度巢狀

```python
class Coordinates(BaseModel):
    latitude: float
    longitude: float

class Location(BaseModel):
    name: str
    coordinates: Coordinates

class Event(BaseModel):
    title: str
    date: str
    location: Location

generator = outlines.generate.json(model, Event)
event = generator("生成活動：舊金山技術大會")

print(event.title)  # "Tech Conference"
print(event.location.name)  # "San Francisco"
print(event.location.coordinates.latitude)  # 37.7749
```

### 巢狀模型列表

```python
class Item(BaseModel):
    name: str
    quantity: int
    price: float

class Order(BaseModel):
    order_id: str
    customer: str
    items: list[Item]  # 巢狀模型列表
    total: float

generator = outlines.generate.json(model, Order)

prompt = """
為 John 生成訂單：
- 2x Widget (每個 $10)
- 3x Gadget (每個 $15)
訂單 ID: ORD-001
"""

order = generator(prompt)
print(f"訂單 ID: {order.order_id}")
for item in order.items:
    print(f"- {item.quantity}x {item.name} @ ${item.price}")
print(f"總計: ${order.total}")
```

## 複雜類型

### 聯合類型 (Union Types)

```python
from typing import Union

class TextContent(BaseModel):
    type: Literal["text"]
    content: str

class ImageContent(BaseModel):
    type: Literal["image"]
    url: str
    caption: str

class Post(BaseModel):
    title: str
    content: Union[TextContent, ImageContent]  # 兩種類型擇一

generator = outlines.generate.json(model, Post)

# 可以生成文字或圖片內容
post = generator("生成帶有圖片的部落格文章")
if post.content.type == "text":
    print(post.content.content)
elif post.content.type == "image":
    print(post.content.url)
```

### 列表與陣列

```python
class Article(BaseModel):
    title: str
    authors: list[str]  # 字串列表
    tags: list[str]
    sections: list[dict[str, str]]  # 字典列表
    related_ids: list[int]

generator = outlines.generate.json(model, Article)
article = generator("生成關於 AI 的文章")

print(article.authors)  # ["Alice", "Bob"]
print(article.tags)  # ["AI", "Machine Learning", "Technology"]
```

### 字典 (Dictionaries)

```python
class Metadata(BaseModel):
    title: str
    properties: dict[str, str]  # 字串鍵與字串值
    counts: dict[str, int]  # 字串鍵，整數值
    settings: dict[str, Union[str, int, bool]]  # 混合值類型

generator = outlines.generate.json(model, Metadata)
meta = generator("生成元資料")

print(meta.properties)  # {"author": "Alice", "version": "1.0"}
print(meta.counts)  # {"views": 1000, "likes": 50}
```

### Any 類型 (請謹慎使用)

```python
from typing import Any

class FlexibleData(BaseModel):
    name: str
    structured_field: str
    flexible_field: Any  # 可以是任何內容

# 注意：Any 會降低類型安全性，僅在必要時使用
generator = outlines.generate.json(model, FlexibleData)
```

## JSON Schema 支援

### 直接使用 Schema

```python
import outlines

model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")

# 定義 JSON schema
schema = {
    "type": "object",
    "properties": {
        "name": {"type": "string"},
        "age": {"type": "integer", "minimum": 0, "maximum": 120},
        "email": {"type": "string", "format": "email"}
    },
    "required": ["name", "age", "email"]
}

# 從 schema 生成
generator = outlines.generate.json(model, schema)
result = generator("生成人物：Alice, 25, alice@example.com")

print(result)  # 符合 schema 的有效 JSON
```

### 從 Pydantic 取得 Schema

```python
class User(BaseModel):
    name: str
    age: int
    email: str

# 從 Pydantic 模型取得 JSON schema
schema = User.model_json_schema()
print(schema)
# {
#   "type": "object",
#   "properties": {
#     "name": {"type": "string"},
#     "age": {"type": "integer"},
#     "email": {"type": "string"}
#   },
#   "required": ["name", "age", "email"]
# }

# 兩種方法等效：
generator1 = outlines.generate.json(model, User)
generator2 = outlines.generate.json(model, schema)
```

## 進階模式

### 條件欄位

```python
class Order(BaseModel):
    order_type: Literal["standard", "express"]
    delivery_date: str
    express_fee: Optional[float] = None  # 僅適用於快遞訂單

generator = outlines.generate.json(model, Order)

# 快遞訂單
order1 = generator("建立明天的快遞訂單")
print(order1.express_fee)  # 25.0

# 標準訂單
order2 = generator("建立標準訂單")
print(order2.express_fee)  # None
```

### 遞迴模型

```python
from typing import Optional, List

class TreeNode(BaseModel):
    value: str
    children: Optional[List['TreeNode']] = None

# 啟用前向引用
TreeNode.model_rebuild()

generator = outlines.generate.json(model, TreeNode)
tree = generator("生成帶有子目錄的檔案樹")

print(tree.value)  # "root"
print(tree.children[0].value)  # "subdir1"
```

### 具備驗證功能的模型

```python
from pydantic import field_validator

class DateRange(BaseModel):
    start_date: str
    end_date: str

    @field_validator('end_date')
    def end_after_start(cls, v, info):
        """確保結束日期在開始日期之後。"""
        if 'start_date' in info.data:
            from datetime import datetime
            start = datetime.strptime(info.data['start_date'], '%Y-%m-%d')
            end = datetime.strptime(v, '%Y-%m-%d')
            if end < start:
                raise ValueError('end_date 必須在 start_date 之後')
        return v

generator = outlines.generate.json(model, DateRange)
# 驗證發生在生成之後
```

## 多個物件

### 生成物件列表

```python
class Person(BaseModel):
    name: str
    age: int

class Team(BaseModel):
    team_name: str
    members: list[Person]

generator = outlines.generate.json(model, Team)

team = generator("生成一個有 5 名成員的工程團隊")
print(f"團隊名稱: {team.team_name}")
for member in team.members:
    print(f"- {member.name}, {member.age}")
```

### 批次生成

```python
def generate_batch(prompts: list[str], schema: type[BaseModel]):
    """為多個提示詞生成結構化輸出。"""
    model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
    generator = outlines.generate.json(model, schema)

    results = []
    for prompt in prompts:
        result = generator(prompt)
        results.append(result)

    return results

class Product(BaseModel):
    name: str
    price: float

prompts = [
    "產品：iPhone 15, $999",
    "產品：MacBook Pro, $2499",
    "產品：AirPods, $179"
]

products = generate_batch(prompts, Product)
for product in products:
    print(f"{product.name}: ${product.price}")
```

## 效能優化

### 快取產生器 (Caching Generators)

```python
from functools import lru_cache

@lru_cache(maxsize=10)
def get_generator(model_name: str, schema_hash: int):
    """快取產生器以供重複使用。"""
    model = outlines.models.transformers(model_name)
    return outlines.generate.json(model, schema)

# 第一次呼叫：建立產生器
gen1 = get_generator("microsoft/Phi-3-mini-4k-instruct", hash(User))

# 第二次呼叫：回傳快取的產生器 (速度快！)
gen2 = get_generator("microsoft/Phi-3-mini-4k-instruct", hash(User))
```

### 批次處理

```python
# 高效處理多個項目
model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
generator = outlines.generate.json(model, User)

texts = ["使用者：Alice, 25", "使用者：Bob, 30", "使用者：Carol, 35"]

# 重複使用產生器 (模型保持載入狀態)
users = [generator(text) for text in texts]
```

### 最小化 Schema 複雜度

```python
# ✅ 建議：簡單且扁平的結構 (速度較快)
class SimplePerson(BaseModel):
    name: str
    age: int
    city: str

# ⚠️ 較慢：深度巢狀
class ComplexPerson(BaseModel):
    personal_info: PersonalInfo
    address: Address
    employment: Employment
    # ... 多層巢狀
```

## 錯誤處理

### 處理缺失欄位

```python
from pydantic import ValidationError

class User(BaseModel):
    name: str
    age: int
    email: str

try:
    user = generator("生成使用者")  # 可能未包含所有欄位
except ValidationError as e:
    print(f"驗證錯誤：{e}")
    # 進行適當處理
```

### 使用選填欄位作為備案

```python
class RobustUser(BaseModel):
    name: str  # 必填
    age: Optional[int] = None  # 選填
    email: Optional[str] = None  # 選填

# 即使資料不完整，也更有可能成功生成
user = generator("生成使用者：Alice")
print(user.name)  # "Alice"
print(user.age)  # None (未提供)
```

## 最佳實踐

### 1. 使用精確的類型

```python
# ✅ 建議：使用精確類型
class Product(BaseModel):
    name: str
    price: float  # 而非 Any 或 str
    quantity: int  # 而非 str
    in_stock: bool  # 而非 int

# ❌ 避免：使用泛用類型
class Product(BaseModel):
    name: Any
    price: str  # 應為 float
    quantity: str  # 應為 int
```

### 2. 加入欄位說明 (Descriptions)

```python
# ✅ 建議：加入清晰說明
class Article(BaseModel):
    title: str = Field(description="文章標題，10-100 字元")
    content: str = Field(description="段落形式的文章主要內容")
    tags: list[str] = Field(description="相關主題標籤列表")

# 說明有助於模型理解預期的輸出
```

### 3. 使用約束條件

```python
# ✅ 建議：加入約束條件
class Age(BaseModel):
    value: int = Field(ge=0, le=120, description="以年為單位的年齡")

# ❌ 避免：不加約束
class Age(BaseModel):
    value: int  # 可能會出現負數或大於 120 的值
```

### 4. 優先使用列舉而非字串

```python
# ✅ 建議：對固定選項使用列舉 (Enum)
class Priority(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"

class Task(BaseModel):
    priority: Priority  # 保證有效

# ❌ 避免：自由形式字串
class Task(BaseModel):
    priority: str  # 可能會出現 "urgent", "ASAP", "!!" 等
```

### 5. 測試你的模型

```python
# 測試模型是否如預期運作
def test_product_model():
    product = Product(
        name="測試產品",
        price=19.99,
        quantity=10,
        in_stock=True
    )
    assert product.price == 19.99
    assert isinstance(product, Product)

# 在投入生產前執行測試
```

## 資源

- **Pydantic 文件**: https://docs.pydantic.dev
- **JSON Schema**: https://json-schema.org
- **Outlines GitHub**: https://github.com/outlines-dev/outlines
