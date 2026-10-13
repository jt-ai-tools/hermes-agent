# 進階驗證模式 (Advanced Validation Patterns)

關於如何在 Instructor 中使用 Pydantic 進行資料驗證的完整指南。

## 目錄
- 內建驗證器 (Built-in Validators)
- 自定義欄位驗證器 (Custom Field Validators)
- 模型層級驗證 (Model-Level Validation)
- 複雜驗證模式
- 錯誤處理

## 內建驗證器 (Built-in Validators)

### 數值約束 (Numeric Constraints)

```python
from pydantic import BaseModel, Field

class Product(BaseModel):
    price: float = Field(gt=0, description="價格必須為正數")
    discount: float = Field(ge=0, le=100, description="折扣範圍為 0-100%")
    quantity: int = Field(ge=1, description="至少需有 1 個項目")
    rating: float = Field(ge=0.0, le=5.0, description="評分範圍為 0-5 顆星")

# 如果 LLM 提供無效的數值，系統會自動帶著錯誤回饋進行重試 (Retry)
```

**可用的約束條件：**
- `gt`：大於 (Greater than)
- `ge`：大於或等於 (Greater than or equal)
- `lt`：小於 (Less than)
- `le`：小於或等於 (Less than or equal)
- `multiple_of`：必須是該數字的倍數

### 字串約束 (String Constraints)

```python
class User(BaseModel):
    username: str = Field(
        min_length=3,
        max_length=20,
        pattern=r'^[a-zA-Z0-9_]+$',
        description="3-20 個英數字元"
    )
    bio: str = Field(max_length=500, description="自傳最多 500 個字元")
    status: str = Field(pattern=r'^(active|inactive|pending)$')

# pattern 會根據正規表達式 (Regex) 進行驗證
```

### 電子郵件與 URL 驗證

```python
from pydantic import EmailStr, HttpUrl, AnyUrl

class Contact(BaseModel):
    email: EmailStr  # 驗證電子郵件格式
    website: HttpUrl  # 驗證 HTTP/HTTPS URL
    portfolio: AnyUrl  # 任何有效的 URL 協議

contact = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": "擷取資訊：john@example.com, https://example.com"
    }],
    response_model=Contact
)
```

### 日期與時間驗證

```python
from datetime import date, datetime
from pydantic import Field, field_validator

class Event(BaseModel):
    event_date: date  # 驗證日期格式
    created_at: datetime  # 驗證日期時間格式
    year: int = Field(ge=1900, le=2100)

    @field_validator('event_date')
    def future_date(cls, v):
        """確保活動日期是在未來。"""
        if v < date.today():
            raise ValueError('活動日期必須是在未來')
        return v
```

### 列表與字典驗證 (List and Dict Validation)

```python
class Document(BaseModel):
    tags: list[str] = Field(min_length=1, max_length=10)
    keywords: list[str] = Field(min_length=3, description="至少 3 個關鍵字")
    metadata: dict[str, str] = Field(description="字串鍵值對 (Key-value pairs)")

    @field_validator('tags')
    def unique_tags(cls, v):
        """確保標籤是唯一的。"""
        if len(v) != len(set(v)):
            raise ValueError('標籤必須是唯一的')
        return v
```

## 自定義欄位驗證器 (Custom Field Validators)

### 基礎欄位驗證器

```python
from pydantic import field_validator

class Person(BaseModel):
    name: str
    age: int

    @field_validator('name')
    def name_must_not_be_empty(cls, v):
        """驗證名稱不為空，且不全是空白字元。"""
        if not v or not v.strip():
            raise ValueError('名稱不能為空')
        return v.strip()

    @field_validator('age')
    def age_must_be_reasonable(cls, v):
        """驗證年齡介於 0 到 120 歲之間。"""
        if v < 0 or v > 120:
            raise ValueError('年齡必須介於 0 到 120 之間')
        return v
```

### 使用欄位資訊的驗證器

```python
from pydantic import ValidationInfo

class Article(BaseModel):
    title: str
    content: str

    @field_validator('content')
    def content_length(cls, v, info: ValidationInfo):
        """驗證內容長度至少為標題長度的兩倍。"""
        if 'title' in info.data:
            title_len = len(info.data['title'])
            if len(v) < title_len * 2:
                raise ValueError('內容長度應至少為標題長度的兩倍')
        return v
```

### 多欄位驗證

```python
class TimeRange(BaseModel):
    start_time: str
    end_time: str

    @field_validator('start_time', 'end_time')
    def valid_time_format(cls, v):
        """驗證兩個時間欄位皆符合 HH:MM 格式。"""
        import re
        if not re.match(r'^\d{2}:\d{2}$', v):
            raise ValueError('時間格式必須為 HH:MM')
        return v
```

### 轉換與驗證 (Transform and Validate)

```python
class URL(BaseModel):
    url: str

    @field_validator('url')
    def normalize_url(cls, v):
        """如果缺少協定頭，則加上 https://。"""
        if not v.startswith(('http://', 'https://')):
            v = f'https://{v}'
        return v
```

## 模型層級驗證 (Model-Level Validation)

### 跨欄位驗證 (Cross-Field Validation)

```python
from pydantic import model_validator

class DateRange(BaseModel):
    start_date: str
    end_date: str

    @model_validator(mode='after')
    def check_dates(self):
        """確保結束日期在開始日期之後。"""
        from datetime import datetime
        start = datetime.strptime(self.start_date, '%Y-%m-%d')
        end = datetime.strptime(self.end_date, '%Y-%m-%d')

        if end < start:
            raise ValueError('結束日期必須在開始日期之後')
        return self

class PriceRange(BaseModel):
    min_price: float
    max_price: float

    @model_validator(mode='after')
    def check_price_range(self):
        """確保最大價格高於最小價格。"""
        if self.max_price <= self.min_price:
            raise ValueError('最大價格必須大於最小價格')
        return self
```

### 條件式驗證 (Conditional Validation)

```python
class Order(BaseModel):
    order_type: str  # "standard" (標準) 或 "express" (快速)
    delivery_date: str
    delivery_time: Optional[str] = None

    @model_validator(mode='after')
    def check_delivery_time(self):
        """快速訂單需要提供送貨時間。"""
        if self.order_type == "express" and not self.delivery_time:
            raise ValueError('快速訂單必須提供送貨時間 (delivery_time)')
        return self
```

### 複雜業務邏輯

```python
class Discount(BaseModel):
    code: str
    percentage: float = Field(ge=0, le=100)
    min_purchase: float = Field(ge=0)
    max_discount: float = Field(ge=0)

    @model_validator(mode='after')
    def validate_discount(self):
        """確保折扣邏輯合理。"""
        # 最大折扣金額不應超過最低消費額的折扣比例
        theoretical_max = (self.percentage / 100) * self.min_purchase
        if self.max_discount > theoretical_max:
            self.max_discount = theoretical_max
        return self
```

## 複雜驗證模式

### 巢狀模型驗證 (Nested Model Validation)

```python
class Address(BaseModel):
    street: str
    city: str
    country: str
    postal_code: str

    @field_validator('postal_code')
    def validate_postal_code(cls, v, info: ValidationInfo):
        """根據國家驗證郵遞區號格式。"""
        if 'country' in info.data:
            country = info.data['country']
            if country == "USA":
                import re
                if not re.match(r'^\d{5}(-\d{4})?$', v):
                    raise ValueError('無效的美國郵遞區號')
            elif country == "Canada":
                if not re.match(r'^[A-Z]\d[A-Z] \d[A-Z]\d$', v):
                    raise ValueError('無效的加拿大郵遞區號')
        return v

class Person(BaseModel):
    name: str
    address: Address

# 巢狀驗證會自動執行
```

### 模型列表 (List of Models)

```python
class Task(BaseModel):
    title: str = Field(min_length=1)
    priority: int = Field(ge=1, le=5)

class Project(BaseModel):
    name: str
    tasks: list[Task] = Field(min_length=1, description="至少需有一個任務")

    @field_validator('tasks')
    def at_least_one_high_priority(cls, v):
        """確保至少有一個任務的優先級 >= 4。"""
        if not any(task.priority >= 4 for task in v):
            raise ValueError('專案至少需要一個高優先級任務')
        return v
```

### 聯合類型驗證 (Union Type Validation)

```python
from typing import Union

class TextBlock(BaseModel):
    type: str = "text"
    content: str = Field(min_length=1)

class ImageBlock(BaseModel):
    type: str = "image"
    url: HttpUrl
    alt_text: str

class Page(BaseModel):
    title: str
    blocks: list[Union[TextBlock, ImageBlock]]

    @field_validator('blocks')
    def validate_block_types(cls, v):
        """確保第一個區塊是文字區塊。"""
        if v and not isinstance(v[0], TextBlock):
            raise ValueError('第一個區塊必須是文字')
        return v
```

### 相依欄位 (Dependent Fields)

```python
class Subscription(BaseModel):
    plan: str  # "free" (免費), "pro" (專業), "enterprise" (企業)
    max_users: int
    features: list[str]

    @model_validator(mode='after')
    def validate_plan_limits(self):
        """實施特定方案的限制。"""
        limits = {
            "free": {"max_users": 1, "required_features": ["basic"]},
            "pro": {"max_users": 10, "required_features": ["basic", "advanced"]},
            "enterprise": {"max_users": 999, "required_features": ["basic", "advanced", "premium"]}
        }

        if self.plan in limits:
            limit = limits[self.plan]

            if self.max_users > limit["max_users"]:
                raise ValueError(f'{self.plan} 方案限制為最多 {limit["max_users"]} 名使用者')

            for feature in limit["required_features"]:
                if feature not in self.features:
                    raise ValueError(f'{self.plan} 方案需要包含 {feature} 功能')

        return self
```

## 錯誤處理

### 優雅降級 (Graceful Degradation)

```python
class OptionalExtraction(BaseModel):
    # 必要欄位
    title: str

    # 選擇性欄位，附帶預設值
    author: Optional[str] = None
    date: Optional[str] = None
    tags: list[str] = Field(default_factory=list)

# 即使 LLM 無法擷取所有內容，擷取過程仍能成功
```

### 部分驗證 (Partial Validation)

```python
from pydantic import ValidationError

def extract_with_fallback(text: str):
    """嘗試完整擷取，若失敗則退而求其次進行部分擷取。"""
    try:
        # 嘗試完整擷取
        return client.messages.create(
            model="claude-sonnet-4-5-20250929",
            max_tokens=1024,
            messages=[{"role": "user", "content": text}],
            response_model=FullModel
        )
    except ValidationError:
        # 退而求其次使用部分模型
        return client.messages.create(
            model="claude-sonnet-4-5-20250929",
            max_tokens=1024,
            messages=[{"role": "user", "content": text}],
            response_model=PartialModel
        )
```

### 驗證錯誤檢查 (Validation Error Inspection)

```python
from pydantic import ValidationError

try:
    result = client.messages.create(
        model="claude-sonnet-4-5-20250929",
        max_tokens=1024,
        messages=[...],
        response_model=MyModel,
        max_retries=3
    )
except ValidationError as e:
    # 檢查特定的錯誤
    for error in e.errors():
        field = error['loc'][0]
        message = error['msg']
        print(f"欄位 '{field}' 驗證失敗：{message}")

        # 針對特定欄位進行處理
        if field == 'email':
            # 處理電子郵件驗證失敗的情況
            pass
```

### 自定義錯誤訊息

```python
class DetailedModel(BaseModel):
    name: str = Field(
        min_length=2,
        max_length=100,
        description="名稱介於 2-100 個字元"
    )
    age: int = Field(
        ge=0,
        le=120,
        description="年齡介於 0 到 120 歲"
    )

    @field_validator('name')
    def validate_name(cls, v):
        """提供更有幫助的錯誤訊息。"""
        if not v.strip():
            raise ValueError(
                '名稱不能為空。'
                '請從文本中提供一個有效的名稱。'
            )
        return v

# 當驗證失敗時，LLM 會看到這些有幫助的訊息
```

## 驗證最佳實踐

### 1. 明確具體

```python
# ❌ 不良示範：模糊的驗證
class Item(BaseModel):
    name: str

# ✅ 優良示範：明確的約束
class Item(BaseModel):
    name: str = Field(
        min_length=1,
        max_length=200,
        description="項目名稱，長度為 1-200 個字元"
    )
```

### 2. 提供上下文 (Context)

```python
# ✅ 優良示範：解釋驗證失敗的原因
@field_validator('price')
def validate_price(cls, v):
    if v <= 0:
        raise ValueError(
            '價格必須為正數。'
            '請從文本中擷取數字價格，且不含貨幣符號。'
        )
    return v
```

### 3. 使用枚舉 (Enums) 固定選項

```python
# ❌ 不良示範：使用字串驗證
status: str

@field_validator('status')
def validate_status(cls, v):
    if v not in ['active', 'inactive', 'pending']:
        raise ValueError('無效的狀態')
    return v

# ✅ 優良示範：使用枚舉 (Enum)
class Status(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    PENDING = "pending"

status: Status  # 自動執行驗證
```

### 4. 平衡嚴格程度

```python
# 太過嚴格：可能導致不必要的失敗
class StrictModel(BaseModel):
    date: str = Field(pattern=r'^\d{4}-\d{2}-\d{2}$')
    # 如果 LLM 使用 "2024-1-5" 而非 "2024-01-05" 則會驗證失敗

# 更好的做法：在驗證器中進行正規化 (Normalize)
class FlexibleModel(BaseModel):
    date: str

    @field_validator('date')
    def normalize_date(cls, v):
        from datetime import datetime
        # 解析彈性的日期格式
        for fmt in ['%Y-%m-%d', '%Y/%m/%d', '%m/%d/%Y']:
            try:
                dt = datetime.strptime(v, fmt)
                return dt.strftime('%Y-%m-%d')  # 統一格式化
            except ValueError:
                continue
        raise ValueError('無效的日期格式')
```

### 5. 測試驗證邏輯

```python
# 測試您的驗證器在極端情況下的表現
def test_validation():
    # 應成功的情況
    valid = MyModel(field="valid_value")

    # 應失敗的情況
    try:
        invalid = MyModel(field="invalid")
        assert False, "理應拋出 ValidationError"
    except ValidationError:
        pass  # 符合預期

# 在投入生產環境之前先執行測試
```

## 進階技巧

### 條件式必要欄位 (Conditional Required Fields)

```python
from typing import Optional

class ConditionalModel(BaseModel):
    type: str
    detail_a: Optional[str] = None
    detail_b: Optional[str] = None

    @model_validator(mode='after')
    def check_required_details(self):
        """根據類型要求不同的欄位。"""
        if self.type == "type_a" and not self.detail_a:
            raise ValueError('type_a 方案需要提供 detail_a')
        if self.type == "type_b" and not self.detail_b:
            raise ValueError('type_b 方案需要提供 detail_b')
        return self
```

### 使用外部資料進行驗證

```python
class Product(BaseModel):
    sku: str
    name: str

    @field_validator('sku')
    def validate_sku(cls, v):
        """檢查 SKU 是否存在於資料庫中。"""
        # 查詢資料庫或 API
        if not database.sku_exists(v):
            raise ValueError(f'目錄中找不到 SKU {v}')
        return v
```

### 漸進式驗證 (Progressive Validation)

```python
# 從較寬鬆的驗證開始
class Stage1(BaseModel):
    data: str  # 任何字串

# 然後進行嚴格驗證
class Stage2(BaseModel):
    data: str = Field(pattern=r'^[A-Z]{3}-\d{6}$')

# 使用 Stage1 進行初始擷取
# 使用 Stage2 進行最終驗證
```

## 資源連結

- **Pydantic 文件**：https://docs.pydantic.dev/latest/concepts/validators/
- **Instructor 範例**：https://python.useinstructor.com/examples
