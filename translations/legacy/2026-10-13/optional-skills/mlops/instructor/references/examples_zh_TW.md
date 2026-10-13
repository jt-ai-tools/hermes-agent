# 實際應用範例 (Real-World Examples)

使用 Instructor 進行結構化資料擷取 (Structured Data Extraction) 的實用範例。

## 資料擷取 (Data Extraction)

```python
class CompanyInfo(BaseModel):
    name: str
    founded: int
    industry: str
    employees: int

text = "Apple 成立於 1976 年，屬於科技產業，擁有 164,000 名員工。"

company = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{"role": "user", "content": f"擷取資訊：{text}"}],
    response_model=CompanyInfo
)
```

## 分類 (Classification)

```python
class Sentiment(str, Enum):
    POSITIVE = "positive"  # 正面
    NEGATIVE = "negative"  # 負面
    NEUTRAL = "neutral"    # 中立

class Review(BaseModel):
    sentiment: Sentiment
    confidence: float = Field(ge=0.0, le=1.0)

review = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{"role": "user", "content": "這個產品太棒了！"}],
    response_model=Review
)
```

## 多實體擷取 (Multi-Entity Extraction)

```python
class Person(BaseModel):
    name: str
    role: str

class Entities(BaseModel):
    people: list[Person]
    organizations: list[str]
    locations: list[str]

entities = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Apple 執行長 Tim Cook 在庫比蒂諾 (Cupertino) 發表了演說..."}],
    response_model=Entities
)
```

## 結構化分析 (Structured Analysis)

```python
class Analysis(BaseModel):
    summary: str
    key_points: list[str]
    sentiment: Sentiment
    actionable_items: list[str]

analysis = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{"role": "user", "content": "分析以下內容：[長文本]"}],
    response_model=Analysis
)
```

## 批次處理 (Batch Processing)

```python
texts = ["文本 1", "文本 2", "文本 3"]
results = [
    client.messages.create(
        model="claude-sonnet-4-5-20250929",
        max_tokens=1024,
        messages=[{"role": "user", "content": text}],
        response_model=YourModel
    )
    for text in texts
]
```

## 串流處理 (Streaming)

```python
for partial in client.messages.create_partial(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{"role": "user", "content": "生成報告..."}],
    response_model=Report
):
    print(f"進度：{partial.title}")
    # 即時更新 UI
```
