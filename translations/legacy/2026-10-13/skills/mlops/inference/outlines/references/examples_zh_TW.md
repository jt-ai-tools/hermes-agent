# 生產環境就緒範例

在生產系統中使用 Outlines 進行結構化生成的實際案例。

## 目錄
- 資料提取
- 分類系統
- 表單處理
- 多實體提取
- 程式碼生成
- 批次處理
- 生產環境模式

## 資料提取

### 基本資訊提取

```python
from pydantic import BaseModel, Field
import outlines

class PersonInfo(BaseModel):
    name: str = Field(description="全名")
    age: int = Field(ge=0, le=120)
    occupation: str
    email: str = Field(pattern=r"^[\w\.-]+@[\w\.-]+\.\w+$")
    location: str

model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
generator = outlines.generate.json(model, PersonInfo)

text = """
Sarah Johnson 博士是一位 42 歲的 MIT 研究科學家。
可以透過 sarah.j@mit.edu 聯絡她，她目前住在馬薩諸塞州劍橋市。
"""

prompt = f"從中提取人物資訊：\n{text}\n\n人物："
person = generator(prompt)

print(f"姓名: {person.name}")
print(f"年齡: {person.age}")
print(f"職業: {person.occupation}")
print(f"電子郵件: {person.email}")
print(f"地點: {person.location}")
```

### 公司資訊

```python
class CompanyInfo(BaseModel):
    name: str
    founded_year: int = Field(ge=1800, le=2025)
    industry: str
    headquarters: str
    employees: int = Field(gt=0)
    revenue: Optional[str] = None

model = outlines.models.transformers("meta-llama/Llama-3.1-8B-Instruct")
generator = outlines.generate.json(model, CompanyInfo)

text = """
Tesla, Inc. 成立於 2003 年，主要從事汽車和能源產業。
公司總部位於德克薩斯州奧斯汀，全球約有 14 萬名員工。
"""

company = generator(f"提取公司資訊：\n{text}\n\n公司：")

print(f"公司: {company.name}")
print(f"成立年份: {company.founded_year}")
print(f"產業: {company.industry}")
print(f"總部: {company.headquarters}")
print(f"員工數: {company.employees:,}")
```

### 產品規格

```python
class ProductSpec(BaseModel):
    name: str
    brand: str
    price: float = Field(gt=0)
    dimensions: str
    weight: str
    features: list[str]
    rating: Optional[float] = Field(None, ge=0, le=5)

generator = outlines.generate.json(model, ProductSpec)

text = """
Apple iPhone 15 Pro 售價為 999 美元。尺寸為 146.6 x 70.6 x 8.25 毫米，
重量為 187 克。主要功能包括 A17 Pro 晶片、鈦金屬設計、動作按鈕和 USB-C 埠。
平均客戶評分為 4.5 顆星。
"""

product = generator(f"提取產品規格：\n{text}\n\n產品：")

print(f"產品: {product.brand} {product.name}")
print(f"價格: ${product.price}")
print(f"功能: {', '.join(product.features)}")
```

## 分類系統

### 情緒分析

```python
from typing import Literal
from enum import Enum

class Sentiment(str, Enum):
    VERY_POSITIVE = "very_positive"
    POSITIVE = "positive"
    NEUTRAL = "neutral"
    NEGATIVE = "negative"
    VERY_NEGATIVE = "very_negative"

class SentimentAnalysis(BaseModel):
    text: str
    sentiment: Sentiment
    confidence: float = Field(ge=0.0, le=1.0)
    aspects: list[str]  # 提及了哪些方面
    reasoning: str

model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
generator = outlines.generate.json(model, SentimentAnalysis)

review = """
這款產品完全超出了我的預期！製造品質非常出色，客戶服務也非常有幫助。
我唯一的微小抱怨是包裝可以做得更好。
"""

result = generator(f"分析情緒：\n{review}\n\n分析：")

print(f"情緒: {result.sentiment.value}")
print(f"信心度: {result.confidence:.2%}")
print(f"提及方面: {', '.join(result.aspects)}")
print(f"推論過程: {result.reasoning}")
```

### 內容分類

```python
class Category(str, Enum):
    TECHNOLOGY = "technology"
    BUSINESS = "business"
    SCIENCE = "science"
    POLITICS = "politics"
    ENTERTAINMENT = "entertainment"
    SPORTS = "sports"
    HEALTH = "health"

class ArticleClassification(BaseModel):
    primary_category: Category
    secondary_categories: list[Category]
    keywords: list[str] = Field(min_items=3, max_items=10)
    target_audience: Literal["general", "expert", "beginner"]
    reading_level: Literal["elementary", "intermediate", "advanced"]

generator = outlines.generate.json(model, ArticleClassification)

article = """
Apple 發佈了 iOS 18，宣佈其 AI 能力取得了突破性進展。新功能利用機器學習
顯著提高了電池壽命和整體設備效能。產業分析師預測這將鞏固 Apple 在
競爭激烈的智慧型手機市場中的地位。
"""

classification = generator(f"分類文章：\n{article}\n\n分類：")

print(f"主分類: {classification.primary_category.value}")
print(f"次分類: {[c.value for c in classification.secondary_categories]}")
print(f"關鍵字: {classification.keywords}")
print(f"目標受眾: {classification.target_audience}")
```

### 意圖辨識

```python
class Intent(str, Enum):
    QUESTION = "question"
    COMPLAINT = "complaint"
    REQUEST = "request"
    FEEDBACK = "feedback"
    CANCEL = "cancel"
    UPGRADE = "upgrade"

class UserMessage(BaseModel):
    original_message: str
    intent: Intent
    urgency: Literal["low", "medium", "high", "critical"]
    department: Literal["support", "sales", "billing", "technical"]
    sentiment: Literal["positive", "neutral", "negative"]
    action_required: bool
    summary: str

generator = outlines.generate.json(model, UserMessage)

message = """
我這個月的訂閱費被扣了兩次！這已經是第三次發生這種事了。我需要有人立即處理並
退還多扣的費用。對這項服務感到非常失望。
"""

result = generator(f"分析訊息：\n{message}\n\n分析：")

print(f"意圖: {result.intent.value}")
print(f"緊急程度: {result.urgency}")
print(f"轉接部門: {result.department}")
print(f"需要後續行動: {result.action_required}")
print(f"摘要: {result.summary}")
```

## 表單處理

### 工作申請

```python
class Education(BaseModel):
    degree: str
    field: str
    institution: str
    year: int

class Experience(BaseModel):
    title: str
    company: str
    duration: str
    responsibilities: list[str]

class JobApplication(BaseModel):
    full_name: str
    email: str
    phone: str
    education: list[Education]
    experience: list[Experience]
    skills: list[str]
    availability: str

model = outlines.models.transformers("meta-llama/Llama-3.1-8B-Instruct")
generator = outlines.generate.json(model, JobApplication)

resume_text = """
John Smith
Email: john.smith@email.com | 電話: 555-0123

學歷
- 電腦科學學士, MIT, 2018
- 人工智慧碩士, 史丹佛大學, 2020

工作經驗
軟體工程師, Google (2020-2023)
- 開發用於搜尋排名的 ML 管線
- 領導 5 名工程師的團隊
- 將搜尋品質提升了 15%

技能：Python, Machine Learning, TensorFlow, 系統設計

到職時間：立即
"""

application = generator(f"提取工作申請：\n{resume_text}\n\n申請表：")

print(f"申請人: {application.full_name}")
print(f"電子郵件: {application.email}")
print(f"學歷: {len(application.education)} 個學位")
for edu in application.education:
    print(f"  - {edu.institution} {edu.field} {edu.degree} ({edu.year})")
print(f"經驗: {len(application.experience)} 個職位")
```

### 發票處理

```python
class InvoiceItem(BaseModel):
    description: str
    quantity: int = Field(gt=0)
    unit_price: float = Field(gt=0)
    total: float = Field(gt=0)

class Invoice(BaseModel):
    invoice_number: str
    date: str = Field(pattern=r"\d{4}-\d{2}-\d{2}")
    vendor: str
    customer: str
    items: list[InvoiceItem]
    subtotal: float = Field(gt=0)
    tax: float = Field(ge=0)
    total: float = Field(gt=0)

generator = outlines.generate.json(model, Invoice)

invoice_text = """
發票編號 #INV-2024-001
日期：2024-01-15

來自：Acme Corp
寄至：Smith & Co

項目：
- 零件 A: 10 個 @ $50.00 = $500.00
- 零件 B: 5 個 @ $75.00 = $375.00
- 服務費: 1 項 @ $100.00 = $100.00

小計：$975.00
稅金 (8%): $78.00
總計：$1,053.00
"""

invoice = generator(f"提取發票資訊：\n{invoice_text}\n\n發票：")

print(f"發票編號: {invoice.invoice_number}")
print(f"來自: {invoice.vendor} → 寄至: {invoice.customer}")
print(f"項目數量: {len(invoice.items)}")
for item in invoice.items:
    print(f"  - {item.description}: {item.quantity} × ${item.unit_price} = ${item.total}")
print(f"總額: ${invoice.total}")
```

### 問卷回覆

```python
class SurveyResponse(BaseModel):
    respondent_id: str
    completion_date: str
    satisfaction: Literal[1, 2, 3, 4, 5]
    would_recommend: bool
    favorite_features: list[str]
    improvement_areas: list[str]
    additional_comments: Optional[str] = None

generator = outlines.generate.json(model, SurveyResponse)

survey_text = """
問卷 ID: RESP-12345
完成日期：2024-01-20

您對我們產品的滿意度如何？ 4 分 (滿分 5 分)

您會推薦給朋友嗎？ 是

您最喜歡哪些功能？
- 效能快
- 易於使用
- 出色的客戶支援

我們還有哪些可以改進的地方？
- 更好的文件
- 更多整合選項

其他回饋：整體來說是很棒的產品，請繼續保持！
"""

response = generator(f"提取問卷回覆：\n{survey_text}\n\n回覆：")

print(f"受訪者: {response.respondent_id}")
print(f"滿意度: {response.satisfaction}/5")
print(f"推薦意願: {response.would_recommend}")
print(f"最愛功能: {response.favorite_features}")
print(f"改進領域: {response.improvement_areas}")
```

## 多實體提取

### 新聞文章實體

```python
class Person(BaseModel):
    name: str
    role: Optional[str] = None
    affiliation: Optional[str] = None

class Organization(BaseModel):
    name: str
    type: Optional[str] = None

class Location(BaseModel):
    name: str
    type: Literal["city", "state", "country", "region"]

class Event(BaseModel):
    name: str
    date: Optional[str] = None
    location: Optional[str] = None

class ArticleEntities(BaseModel):
    people: list[Person]
    organizations: list[Organization]
    locations: list[Location]
    events: list[Event]
    dates: list[str]

model = outlines.models.transformers("meta-llama/Llama-3.1-8B-Instruct")
generator = outlines.generate.json(model, ArticleEntities)

article = """
Apple 執行長 Tim Cook 於 2024 年 9 月 15 日在華盛頓州雷德蒙德的 Microsoft 總部
會見了 Microsoft 執行長 Satya Nadella，討論潛在的合作機會。兩家公司的高層
均出席了會議，並將重點放在 AI 整合策略。Apple 的 Cupertino 辦公室將於
2024 年 10 月 20 日主辦後續會議。
"""

entities = generator(f"提取所有實體：\n{article}\n\n實體：")

print("人物：")
for person in entities.people:
    print(f"  - {person.name} ({person.role}) @ {person.affiliation}")

print("\n組織：")
for org in entities.organizations:
    print(f"  - {org.name} ({org.type})")

print("\n地點：")
for loc in entities.locations:
    print(f"  - {loc.name} ({loc.type})")

print("\n事件：")
for event in entities.events:
    print(f"  - {event.name} 於 {event.date}")
```

### 文件元資料

```python
class Author(BaseModel):
    name: str
    email: Optional[str] = None
    affiliation: Optional[str] = None

class Reference(BaseModel):
    title: str
    authors: list[str]
    year: int
    source: str

class DocumentMetadata(BaseModel):
    title: str
    authors: list[Author]
    abstract: str
    keywords: list[str]
    publication_date: str
    journal: str
    doi: Optional[str] = None
    references: list[Reference]

generator = outlines.generate.json(model, DocumentMetadata)

paper = """
標題：神經機器翻譯的進展

作者：
- Jane Smith 博士 (jane@university.edu), MIT
- John Doe 教授 (jdoe@stanford.edu), 史丹佛大學

摘要：本文介紹了使用 Transformer 架構進行神經機器翻譯的新方法。我們證明了在多個
語言對中，翻譯品質都有顯著提升。

關鍵字：神經網路, 機器翻譯, Transformers, NLP

發表於：Journal of AI Research, 2024-03-15
DOI: 10.1234/jair.2024.001

引用文獻：
1. "Attention Is All You Need" by Vaswani et al., 2017, NeurIPS
2. "BERT: Pre-training of Deep Bidirectional Transformers" by Devlin et al., 2019, NAACL
"""

metadata = generator(f"提取文件元資料：\n{paper}\n\n元資料：")

print(f"標題: {metadata.title}")
print(f"作者: {', '.join(a.name for a in metadata.authors)}")
print(f"關鍵字: {', '.join(metadata.keywords)}")
print(f"引用文獻數量: {len(metadata.references)}")
```

## 程式碼生成

### Python 函式生成

```python
class Parameter(BaseModel):
    name: str = Field(pattern=r"^[a-z_][a-z0-9_]*$")
    type_hint: str
    default: Optional[str] = None

class PythonFunction(BaseModel):
    function_name: str = Field(pattern=r"^[a-z_][a-z0-9_]*$")
    parameters: list[Parameter]
    return_type: str
    docstring: str
    body: list[str]  # 程式碼行

model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
generator = outlines.generate.json(model, PythonFunction)

spec = "建立一個計算數字階乘的函式"

func = generator(f"生成 Python 函式：\n{spec}\n\n函式：")

print(f"def {func.function_name}(", end="")
print(", ".join(f"{p.name}: {p.type_hint}" for p in func.parameters), end="")
print(f") -> {func.return_type}:")
print(f'    """{func.docstring}"""')
for line in func.body:
    print(f"    {line}")
```

### SQL 查詢生成

```python
class SQLQuery(BaseModel):
    query_type: Literal["SELECT", "INSERT", "UPDATE", "DELETE"]
    select_columns: Optional[list[str]] = None
    from_tables: list[str]
    joins: Optional[list[str]] = None
    where_conditions: Optional[list[str]] = None
    group_by: Optional[list[str]] = None
    order_by: Optional[list[str]] = None
    limit: Optional[int] = None

generator = outlines.generate.json(model, SQLQuery)

request = "取得過去 30 天內有消費的前 10 名使用者，按總支出排序"

sql = generator(f"生成 SQL 查詢：\n{request}\n\n查詢：")

print(f"查詢類型: {sql.query_type}")
print(f"SELECT {', '.join(sql.select_columns)}")
print(f"FROM {', '.join(sql.from_tables)}")
if sql.joins:
    for join in sql.joins:
        print(f"  {join}")
if sql.where_conditions:
    print(f"WHERE {' AND '.join(sql.where_conditions)}")
if sql.order_by:
    print(f"ORDER BY {', '.join(sql.order_by)}")
if sql.limit:
    print(f"LIMIT {sql.limit}")
```

### API 端點規格

```python
class Parameter(BaseModel):
    name: str
    type: str
    required: bool
    description: str

class APIEndpoint(BaseModel):
    method: Literal["GET", "POST", "PUT", "DELETE", "PATCH"]
    path: str
    description: str
    parameters: list[Parameter]
    request_body: Optional[dict] = None
    response_schema: dict
    status_codes: dict[int, str]

generator = outlines.generate.json(model, APIEndpoint)

spec = "建立使用者端點"

endpoint = generator(f"生成 API 端點：\n{spec}\n\n端點：")

print(f"{endpoint.method} {endpoint.path}")
print(f"說明: {endpoint.description}")
print("\n參數：")
for param in endpoint.parameters:
    req = "必填" if param.required else "選填"
    print(f"  - {param.name} ({param.type}, {req}): {param.description}")
```

## 批次處理

### 並行提取

```python
def batch_extract(texts: list[str], schema: type[BaseModel], model_name: str):
    """從多段文本中提取結構化資料。"""
    model = outlines.models.transformers(model_name)
    generator = outlines.generate.json(model, schema)

    results = []
    for i, text in enumerate(texts):
        print(f"正在處理 {i+1}/{len(texts)}...", end="\r")
        result = generator(f"提取：\n{text}\n\n資料：")
        results.append(result)

    return results

class Product(BaseModel):
    name: str
    price: float
    category: str

texts = [
    "iPhone 15 Pro 在電子產品類別中售價為 999 美元",
    "慢跑鞋在運動類別中售價為 89.99 美元",
    "咖啡機在居家廚房類別中標價為 49.99 美元"
]

products = batch_extract(texts, Product, "microsoft/Phi-3-mini-4k-instruct")

for product in products:
    print(f"{product.name}: ${product.price} ({product.category})")
```

### CSV 處理

```python
import csv

def process_csv(csv_file: str, schema: type[BaseModel]):
    """處理 CSV 檔案並提取結構化資料。"""
    model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
    generator = outlines.generate.json(model, schema)

    results = []
    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            text = " | ".join(f"{k}: {v}" for k, v in row.items())
            result = generator(f"提取：\n{text}\n\n資料：")
            results.append(result)

    return results

class Customer(BaseModel):
    name: str
    email: str
    tier: Literal["basic", "premium", "enterprise"]
    mrr: float

# customers = process_csv("customers.csv", Customer)
```

## 生產環境模式

### 錯誤處理

```python
from pydantic import ValidationError

def safe_extract(text: str, schema: type[BaseModel], retries: int = 3):
    """具有錯誤處理與重試機制的提取。"""
    model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
    generator = outlines.generate.json(model, schema)

    for attempt in range(retries):
        try:
            result = generator(f"提取：\n{text}\n\n資料：")
            return result
        except ValidationError as e:
            print(f"嘗試 {attempt + 1} 失敗：{e}")
            if attempt == retries - 1:
                raise
        except Exception as e:
            print(f"發生非預期錯誤：{e}")
            if attempt == retries - 1:
                raise

    return None
```

### 快取

```python
from functools import lru_cache
import hashlib

@lru_cache(maxsize=1000)
def cached_extract(text_hash: str, schema_name: str):
    """快取提取結果。"""
    # 此處應呼叫實際的提取邏輯
    pass

def extract_with_cache(text: str, schema: type[BaseModel]):
    """具備快取功能的提取。"""
    text_hash = hashlib.md5(text.encode()).hexdigest()
    schema_name = schema.__name__

    cached_result = cached_extract(text_hash, schema_name)
    if cached_result:
        return cached_result

    # 執行實際提取
    model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
    generator = outlines.generate.json(model, schema)
    result = generator(f"提取：\n{text}\n\n資料：")

    return result
```

### 監控

```python
import time
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def monitored_extract(text: str, schema: type[BaseModel]):
    """具備監控與日誌記錄功能的提取。"""
    start_time = time.time()

    try:
        model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
        generator = outlines.generate.json(model, schema)

        result = generator(f"提取：\n{text}\n\n資料：")

        elapsed = time.time() - start_time
        logger.info(f"提取成功，耗時 {elapsed:.2f} 秒")
        logger.info(f"輸入長度：{len(text)} 字元")

        return result

    except Exception as e:
        elapsed = time.time() - start_time
        logger.error(f"提取失敗，耗時 {elapsed:.2f} 秒：{e}")
        raise
```

### 速率限制

```python
import time
from threading import Lock

class RateLimiter:
    def __init__(self, max_requests: int, time_window: int):
        self.max_requests = max_requests
        self.time_window = time_window
        self.requests = []
        self.lock = Lock()

    def wait_if_needed(self):
        with self.lock:
            now = time.time()
            # 移除舊請求
            self.requests = [r for r in self.requests if now - r < self.time_window]

            if len(self.requests) >= self.max_requests:
                sleep_time = self.time_window - (now - self.requests[0])
                time.sleep(sleep_time)
                self.requests = []

            self.requests.append(now)

def rate_limited_extract(texts: list[str], schema: type[BaseModel]):
    """具備速率限制功能的提取。"""
    limiter = RateLimiter(max_requests=10, time_window=60)  # 每分鐘 10 次請求
    model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct")
    generator = outlines.generate.json(model, schema)

    results = []
    for text in texts:
        limiter.wait_if_needed()
        result = generator(f"提取：\n{text}\n\n資料：")
        results.append(result)

    return results
```

## 資源

- **Outlines 文件**: https://outlines-dev.github.io/outlines
- **Pydantic 文件**: https://docs.pydantic.dev
- **GitHub 範例**: https://github.com/outlines-dev/outlines/tree/main/examples
