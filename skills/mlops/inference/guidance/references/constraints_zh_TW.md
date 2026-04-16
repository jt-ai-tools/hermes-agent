# 全面受限模式指南 (Comprehensive Constraint Patterns)

關於 Guidance 中的正規表示式約束、基於文法的生成以及 Token 修復的指南。

## 目錄
- 正規表示式約束
- 基於文法的生成
- Token 修復
- 選擇約束
- 複雜模式
- 效能優化

## 正規表示式約束 (Regex Constraints)

### 基本模式

#### 數值約束

```python
from guidance import models, gen

lm = models.Anthropic("claude-sonnet-4-5-20250929")

# 整數 (正數)
lm += "Age: " + gen("age", regex=r"[0-9]+")

# 整數 (包含負數)
lm += "Temperature: " + gen("temp", regex=r"-?[0-9]+")

# 浮點數 (正數)
lm += "Price: $" + gen("price", regex=r"[0-9]+\.[0-9]{2}")

# 浮點數 (包含負數和選填小數)
lm += "Value: " + gen("value", regex=r"-?[0-9]+(\.[0-9]+)?")

# 百分比 (0-100)
lm += "Progress: " + gen("progress", regex=r"(100|[0-9]{1,2})")

# 範圍 (1-5 顆星)
lm += "Rating: " + gen("rating", regex=r"[1-5]") + " stars"
```

#### 文字約束

```python
# 僅限英文字母
lm += "Name: " + gen("name", regex=r"[A-Za-z]+")

# 英文字母與空格
lm += "Full Name: " + gen("full_name", regex=r"[A-Za-z ]+")

# 英數字 (Alphanumeric)
lm += "Username: " + gen("username", regex=r"[A-Za-z0-9_]+")

# 首字母大寫單字
lm += "Title: " + gen("title", regex=r"[A-Z][a-z]+( [A-Z][a-z]+)*")

# 僅限小寫
lm += "Code: " + gen("code", regex=r"[a-z0-9-]+")

# 特定長度
lm += "ID: " + gen("id", regex=r"[A-Z]{3}-[0-9]{6}")  # 例如："ABC-123456"
```

#### 日期與時間約束

```python
# 日期 (YYYY-MM-DD)
lm += "Date: " + gen("date", regex=r"\d{4}-\d{2}-\d{2}")

# 日期 (MM/DD/YYYY)
lm += "Date: " + gen("date_us", regex=r"\d{2}/\d{2}/\d{4}")

# 時間 (HH:MM)
lm += "Time: " + gen("time", regex=r"\d{2}:\d{2}")

# 時間 (HH:MM:SS)
lm += "Time: " + gen("time_full", regex=r"\d{2}:\d{2}:\d{2}")

# ISO 8601 日期時間
lm += "Timestamp: " + gen(
    "timestamp",
    regex=r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z"
)

# 年份 (YYYY)
lm += "Year: " + gen("year", regex=r"(19|20)\d{2}")

# 月份名稱
lm += "Month: " + gen(
    "month",
    regex=r"(January|February|March|April|May|June|July|August|September|October|November|December)"
)
```

#### 聯絡資訊

```python
# 電子郵件
lm += "Email: " + gen(
    "email",
    regex=r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
)

# 電話 (美國格式)
lm += "Phone: " + gen("phone", regex=r"\d{3}-\d{3}-\d{4}")

# 電話 (國際格式)
lm += "Phone: " + gen("phone_intl", regex=r"\+[0-9]{1,3}-[0-9]{1,14}")

# 郵遞區號 (美國)
lm += "ZIP: " + gen("zip", regex=r"\d{5}(-\d{4})?")

# 郵遞區號 (加拿大)
lm += "Postal: " + gen("postal", regex=r"[A-Z]\d[A-Z] \d[A-Z]\d")

# URL
lm += "URL: " + gen(
    "url",
    regex=r"https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/[a-zA-Z0-9._~:/?#\[\]@!$&'()*+,;=-]*)?"
)
```

### 進階模式

#### JSON 欄位約束

```python
from guidance import models, gen

lm = models.Anthropic("claude-sonnet-4-5-20250929")

# 字串欄位（含引號）
lm += '"name": ' + gen("name", regex=r'"[A-Za-z ]+"')

# 數值欄位（無引號）
lm += '"age": ' + gen("age", regex=r"[0-9]+")

# 布林值欄位
lm += '"active": ' + gen("active", regex=r"(true|false)")

# Null 欄位
lm += '"optional": ' + gen("optional", regex=r"(null|[0-9]+)")

# 字串陣列
lm += '"tags": [' + gen(
    "tags",
    regex=r'"[a-z]+"(, "[a-z]+")*'
) + ']'

# 完整的 JSON 物件
lm += """{
    "name": """ + gen("name", regex=r'"[A-Za-z ]+"') + """,
    "age": """ + gen("age", regex=r"[0-9]+") + """,
    "email": """ + gen(
        "email",
        regex=r'"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"'
    ) + """
}"""
```

#### 程式碼模式

```python
# Python 變數名稱
lm += "Variable: " + gen("var", regex=r"[a-z_][a-z0-9_]*")

# Python 函式名稱
lm += "Function: " + gen("func", regex=r"[a-z_][a-z0-9_]*")

# 十六進位顏色代碼
lm += "Color: #" + gen("color", regex=r"[0-9A-Fa-f]{6}")

# UUID
lm += "UUID: " + gen(
    "uuid",
    regex=r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
)

# Git 提交雜湊 (短版)
lm += "Commit: " + gen("commit", regex=r"[0-9a-f]{7}")

# 語義化版本 (Semantic version)
lm += "Version: " + gen("version", regex=r"[0-9]+\.[0-9]+\.[0-9]+")

# IP 位址 (IPv4)
lm += "IP: " + gen(
    "ip",
    regex=r"((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
)
```

#### 領域特定模式 (Domain-Specific Patterns)

```python
# 信用卡號碼
lm += "Card: " + gen("card", regex=r"\d{4}-\d{4}-\d{4}-\d{4}")

# 社會安全號碼 (美國 SSN)
lm += "SSN: " + gen("ssn", regex=r"\d{3}-\d{2}-\d{4}")

# ISBN-13
lm += "ISBN: " + gen("isbn", regex=r"978-\d{1,5}-\d{1,7}-\d{1,7}-\d")

# 車牌號碼 (美國)
lm += "Plate: " + gen("plate", regex=r"[A-Z]{3}-\d{4}")

# 貨幣金額
lm += "Amount: $" + gen("amount", regex=r"[0-9]{1,3}(,[0-9]{3})*\.[0-9]{2}")

# 帶小數點的百分比
lm += "Rate: " + gen("rate", regex=r"[0-9]+\.[0-9]{1,2}%")
```

## 基於文法的生成 (Grammar-Based Generation)

### JSON 文法

```python
from guidance import models, gen, guidance

@guidance
def json_object(lm):
    """生成有效的 JSON 物件。"""
    lm += "{\n"

    # 姓名欄位 (必填)
    lm += '    "name": ' + gen("name", regex=r'"[A-Za-z ]+"') + ",\n"

    # 年齡欄位 (必填)
    lm += '    "age": ' + gen("age", regex=r"[0-9]+") + ",\n"

    # 電子郵件欄位 (必填)
    lm += '    "email": ' + gen(
        "email",
        regex=r'"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"'
    ) + ",\n"

    # 啟用狀態欄位 (必填，布林值)
    lm += '    "active": ' + gen("active", regex=r"(true|false)") + "\n"

    lm += "}"
    return lm

lm = models.Anthropic("claude-sonnet-4-5-20250929")
lm = json_object(lm)
print(lm)  # 保證為有效的 JSON
```

### 巢狀 JSON 文法 (Nested JSON Grammar)

```python
@guidance
def nested_json(lm):
    """生成巢狀 JSON 結構。"""
    lm += "{\n"

    # User 物件
    lm += '    "user": {\n'
    lm += '        "name": ' + gen("name", regex=r'"[A-Za-z ]+"') + ",\n"
    lm += '        "age": ' + gen("age", regex=r"[0-9]+") + "\n"
    lm += "    },\n"

    # Address 物件
    lm += '    "address": {\n'
    lm += '        "street": ' + gen("street", regex=r'"[A-Za-z0-9 ]+"') + ",\n"
    lm += '        "city": ' + gen("city", regex=r'"[A-Za-z ]+"') + ",\n"
    lm += '        "zip": ' + gen("zip", regex=r'"\d{5}"') + "\n"
    lm += "    }\n"

    lm += "}"
    return lm
```

### 陣列文法 (Array Grammar)

```python
@guidance
def json_array(lm, count=3):
    """生成具有固定數量的 JSON 陣列。"""
    lm += "[\n"

    for i in range(count):
        lm += "    {\n"
        lm += '        "id": ' + gen(f"id_{i}", regex=r"[0-9]+") + ",\n"
        lm += '        "name": ' + gen(f"name_{i}", regex=r'"[A-Za-z ]+"') + "\n"
        lm += "    }"
        if i < count - 1:
            lm += ","
        lm += "\n"

    lm += "]"
    return lm
```

### XML 文法

```python
@guidance
def xml_document(lm):
    """生成有效的 XML 文件。"""
    lm += '<?xml version="1.0"?>\n'
    lm += "<person>\n"

    # 姓名元素
    lm += "    <name>" + gen("name", regex=r"[A-Za-z ]+") + "</name>\n"

    # 年齡元素
    lm += "    <age>" + gen("age", regex=r"[0-9]+") + "</age>\n"

    # 電子郵件元素
    lm += "    <email>" + gen(
        "email",
        regex=r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
    ) + "</email>\n"

    lm += "</person>"
    return lm
```

### CSV 文法

```python
@guidance
def csv_row(lm):
    """生成 CSV 行。"""
    lm += gen("name", regex=r"[A-Za-z ]+") + ","
    lm += gen("age", regex=r"[0-9]+") + ","
    lm += gen("email", regex=r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}")
    return lm

@guidance
def csv_document(lm, rows=5):
    """生成完整的 CSV。"""
    # 標頭 (Header)
    lm += "Name,Age,Email\n"

    # 資料行 (Rows)
    for i in range(rows):
        lm = csv_row(lm)
        if i < rows - 1:
            lm += "\n"

    return lm
```

## Token 修復 (Token Healing)

### Token 修復的運作原理

**問題：** Token 化會產生不自然的邊界。

```python
# 無 Token 修復的範例
prompt = "The capital of France is "
# Token 化結果：["The", " capital", " of", " France", " is", " "]
# 模型看到的最後一個 Token：" "
# 第一個生成的 Token 可能包含前導空格：" Paris"
# 結果："The capital of France is  Paris" (出現雙空格)
```

**解決方案：** Guidance 會回退並重新生成最後一個 Token。

```python
from guidance import models, gen

lm = models.Anthropic("claude-sonnet-4-5-20250929")

# Token 修復預設為啟用
lm += "The capital of France is " + gen("capital", max_tokens=5)

# 處理流程：
# 1. 回退到 " is " 之前的 Token
# 2. 同時重新生成 " is" + "capital"
# 3. 結果："The capital of France is Paris" (正確)
```

### Token 修復範例

#### 自然續寫

```python
# 未使用 Token 修復前
lm += "The function name is get" + gen("rest")
# 可能生成："The function name is get User" (User 前有空格)

# 使用 Token 修復後
lm += "The function name is get" + gen("rest")
# 生成："The function name is getUser" (正確的駝峰式命名法)
```

#### 程式碼生成

```python
# 函式名稱補全
lm += "def calculate_" + gen("rest", stop="(")
# Token 修復確保平滑連接："calculate_total"

# 變數名稱補全
lm += "my_" + gen("var_name", regex=r"[a-z_]+")
# Token 修復確保："my_variable_name" (而非 "my_ variable_name")
```

#### 領域特定術語

```python
# 醫學術語
lm += "The patient has hyper" + gen("condition")
# Token 修復有助於生成："hypertension" (而非 "hyper tension")

# 技術術語
lm += "Using micro" + gen("tech")
# Token 修復有助於生成："microservices" (而非 "micro services")
```

### 停用 Token 修復

```python
# 如有需要，可以停用 Token 修復 (極少見)
lm += gen("text", token_healing=False)
```

## 選擇約束 (Selection Constraints)

### 基本選擇

```python
from guidance import models, select

lm = models.Anthropic("claude-sonnet-4-5-20250929")

# 簡單選擇
lm += "Status: " + select(["active", "inactive", "pending"], name="status")

# 布林值選擇
lm += "Approved: " + select(["Yes", "No"], name="approved")

# 多選一
lm += "Answer: " + select(
    ["A) Paris", "B) London", "C) Berlin", "D) Madrid"],
    name="answer"
)
```

### 條件選擇 (Conditional Selection)

```python
from guidance import models, select, gen, guidance

@guidance
def conditional_fields(lm):
    """根據類型條件化生成欄位。"""
    lm += "Type: " + select(["person", "company"], name="type")

    if lm["type"] == "person":
        lm += "\nName: " + gen("name", regex=r"[A-Za-z ]+")
        lm += "\nAge: " + gen("age", regex=r"[0-9]+")
    else:
        lm += "\nCompany Name: " + gen("company", regex=r"[A-Za-z ]+")
        lm += "\nEmployees: " + gen("employees", regex=r"[0-9]+")

    return lm
```

### 重複選擇

```python
@guidance
def multiple_selections(lm):
    """選擇多個項目。"""
    lm += "Select 3 colors:\n"

    colors = ["red", "blue", "green", "yellow", "purple"]

    for i in range(3):
        lm += f"{i+1}. " + select(colors, name=f"color_{i}") + "\n"

    return lm
```

## 複雜模式

### 模式 1：結構化表單

```python
@guidance
def user_form(lm):
    """生成結構化使用者表單。"""
    lm += "=== User Registration ===\n\n"

    # 姓名 (僅限英文字母)
    lm += "Full Name: " + gen("name", regex=r"[A-Za-z ]+", stop="\n") + "\n"

    # 年齡 (數值)
    lm += "Age: " + gen("age", regex=r"[0-9]+", max_tokens=3) + "\n"

    # 電子郵件 (經驗證格式)
    lm += "Email: " + gen(
        "email",
        regex=r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
        stop="\n"
    ) + "\n"

    # 電話 (美國格式)
    lm += "Phone: " + gen("phone", regex=r"\d{3}-\d{3}-\d{4}") + "\n"

    # 帳戶類型 (選擇)
    lm += "Account Type: " + select(
        ["Standard", "Premium", "Enterprise"],
        name="account_type"
    ) + "\n"

    # 啟用狀態 (布林值)
    lm += "Active: " + select(["Yes", "No"], name="active") + "\n"

    return lm
```

### 模式 2：多實體提取 (Multi-Entity Extraction)

```python
@guidance
def extract_entities(lm, text):
    """使用約束提取多個實體。"""
    lm += f"Text: {text}\n\n"

    # 人物姓名 (僅限字母)
    lm += "Person: " + gen("person", regex=r"[A-Za-z ]+", stop="\n") + "\n"

    # 組織 (英數字與空格)
    lm += "Organization: " + gen(
        "organization",
        regex=r"[A-Za-z0-9 ]+",
        stop="\n"
    ) + "\n"

    # 日期 (YYYY-MM-DD 格式)
    lm += "Date: " + gen("date", regex=r"\d{4}-\d{2}-\d{2}") + "\n"

    # 地點 (字母與空格)
    lm += "Location: " + gen("location", regex=r"[A-Za-z ]+", stop="\n") + "\n"

    # 金額 (貨幣)
    lm += "Amount: $" + gen("amount", regex=r"[0-9,]+\.[0-9]{2}") + "\n"

    return lm
```

### 模式 3：程式碼生成

```python
@guidance
def generate_python_function(lm):
    """使用約束生成 Python 函式。"""
    # 函式名稱 (有效的 Python 識別碼)
    lm += "def " + gen("func_name", regex=r"[a-z_][a-z0-9_]*") + "("

    # 參數名稱
    lm += gen("param", regex=r"[a-z_][a-z0-9_]*") + "):\n"

    # 文件字串 (Docstring)
    lm += '    """' + gen("docstring", stop='"""', max_tokens=50) + '"""\n'

    # 函式主體 (受限於有效的 Python)
    lm += "    return " + gen("return_value", stop="\n") + "\n"

    return lm
```

### 模式 4：階層式數據

```python
@guidance
def org_chart(lm):
    """生成組織圖。"""
    lm += "Company: " + gen("company", regex=r"[A-Za-z ]+") + "\n\n"

    # CEO
    lm += "CEO: " + gen("ceo", regex=r"[A-Za-z ]+") + "\n"

    # 部門 (Departments)
    for dept in ["Engineering", "Sales", "Marketing"]:
        lm += f"\n{dept} Department:\n"
        lm += "  Head: " + gen(f"{dept.lower()}_head", regex=r"[A-Za-z ]+") + "\n"
        lm += "  Size: " + gen(f"{dept.lower()}_size", regex=r"[0-9]+") + " employees\n"

    return lm
```

## 效能優化

### 最佳實務

#### 1. 使用特定的模式

```python
# ✅ 建議：特定的模式
lm += gen("age", regex=r"[0-9]{1,3}")  # 快速

# ❌ 不建議：過於寬泛的模式
lm += gen("age", regex=r"[0-9]+")  # 較慢
```

#### 2. 限制最大 Token 數 (Max Tokens)

```python
# ✅ 建議：合理的限制
lm += gen("name", max_tokens=30)

# ❌ 不建議：無限制
lm += gen("name")  # 可能會無限生成
```

#### 3. 使用停止序列 (stop sequences)

```python
# ✅ 建議：在換行處停止
lm += gen("line", stop="\n")

# ❌ 不建議：依賴 max_tokens
lm += gen("line", max_tokens=100)
```

#### 4. 快取已編譯的文法

```python
# 文法在第一次使用後會自動快取
# 無需手動快取
@guidance
def reusable_pattern(lm):
    """此文法編譯一次後即被快取。"""
    lm += gen("email", regex=r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}")
    return lm

# 第一次呼叫：編譯文法
lm = reusable_pattern(lm)

# 後續呼叫：使用快取的文法 (快速)
lm = reusable_pattern(lm)
```

#### 5. 避免重疊的約束

```python
# ✅ 建議：清晰的約束
lm += gen("age", regex=r"[0-9]+", max_tokens=3)

# ❌ 不建議：衝突的約束
lm += gen("age", regex=r"[0-9]{2}", max_tokens=10)  # max_tokens 是多餘的
```

### 效能基準測試

**正規表示式 vs 自由生成：**
- 簡單正規表示式 (數字)：約比自由生成慢 1.2 倍
- 複雜正規表示式 (電子郵件)：約比自由生成慢 1.5 倍
- 基於文法：約比自由生成慢 2 倍

**但：**
- 100% 有效輸出（對比自由生成 + 驗證約 70% 的有效率）
- 無需重試迴圈
- 對於結構化輸出，整體端到端速度更快

**優化提示：**
- 僅對關鍵欄位使用正規表示式
- 對於小型固定集合使用 `select()` (最快)
- 儘可能使用 `stop` 序列 (比 max_tokens 更快)
- 通過重複使用函式來快取已編譯的文法

## 相關資源

- **Token 修復論文**：https://arxiv.org/abs/2306.17648
- **Guidance 官方文件**：https://guidance.readthedocs.io
- **GitHub**：https://github.com/guidance-ai/guidance
