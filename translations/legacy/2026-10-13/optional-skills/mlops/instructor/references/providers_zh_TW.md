# 模型提供商設定 (Provider Configuration)

關於如何將 Instructor 與不同的大型語言模型 (LLM) 提供商搭配使用的指南。

## Anthropic Claude

```python
import instructor
from anthropic import Anthropic

# 基本設定
client = instructor.from_anthropic(Anthropic())

# 包含 API 金鑰
client = instructor.from_anthropic(
    Anthropic(api_key="your-api-key")
)

# 推薦模式
client = instructor.from_anthropic(
    Anthropic(),
    mode=instructor.Mode.ANTHROPIC_TOOLS
)

# 使用方式
result = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{"role": "user", "content": "..."}],
    response_model=YourModel
)
```

## OpenAI

```python
from openai import OpenAI

client = instructor.from_openai(OpenAI())

result = client.chat.completions.create(
    model="gpt-4o-mini",
    response_model=YourModel,
    messages=[{"role": "user", "content": "..."}]
)
```

## 本地模型 (Ollama)

```python
client = instructor.from_openai(
    OpenAI(
        base_url="http://localhost:11434/v1",
        api_key="ollama"
    ),
    mode=instructor.Mode.JSON
)

result = client.chat.completions.create(
    model="llama3.1",
    response_model=YourModel,
    messages=[...]
)
```

## 模式 (Modes)

- `Mode.ANTHROPIC_TOOLS`：推薦給 Claude 使用。
- `Mode.TOOLS`：OpenAI 的函數調用 (Function calling)。
- `Mode.JSON`：當提供商不支援時的後備方案 (Fallback)。
