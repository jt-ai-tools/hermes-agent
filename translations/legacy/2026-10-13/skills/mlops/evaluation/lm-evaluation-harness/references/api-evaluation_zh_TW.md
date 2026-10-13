# API 評估

評估 OpenAI、Anthropic 和其他基於 API 的語言模型指南。

## 概述

lm-evaluation-harness 透過統一的 `TemplateAPI` 介面支援評估基於 API 的模型。這允許對以下內容進行基準測試：
- OpenAI 模型（GPT-4、GPT-3.5 等）
- Anthropic 模型（Claude 3、Claude 2 等）
- 本地相容 OpenAI 的 API
- 自定義 API 端點

**為什麼要評估 API 模型**：
- 對閉源模型進行基準測試
- 將 API 模型與開源模型進行比較
- 驗證 API 效能
- 隨時間追蹤模型更新

## 支援的 API 模型

| 提供者 | 模型類型 | 請求類型 | Logprobs |
|----------|------------|---------------|----------|
| OpenAI (completions) | `openai-completions` | 全部 | ✅ 是 |
| OpenAI (chat) | `openai-chat-completions` | 僅 `generate_until` | ❌ 否 |
| Anthropic (completions) | `anthropic-completions` | 全部 | ❌ 否 |
| Anthropic (chat) | `anthropic-chat` | 僅 `generate_until` | ❌ 否 |
| 本地 (相容 OpenAI) | `local-completions` | 取決於伺服器 | 不定 |

**注意**：沒有 logprobs 的模型只能在生成任務上進行評估，不能進行困惑度 (Perplexity) 或對數概似 (Loglikelihood) 任務。

## OpenAI 模型

### 設置

```bash
export OPENAI_API_KEY=sk-...
```

### 補全模型 (Legacy)

**可用模型**：`davinci-002`, `babbage-002`

```bash
lm_eval --model openai-completions \
  --model_args model=davinci-002 \
  --tasks lambada_openai,hellaswag \
  --batch_size auto
```

**支援**：
- `generate_until`: ✅
- `loglikelihood`: ✅
- `loglikelihood_rolling`: ✅

### 對話模型

**可用模型**：`gpt-4`, `gpt-4-turbo`, `gpt-3.5-turbo`

```bash
lm_eval --model openai-chat-completions \
  --model_args model=gpt-4-turbo \
  --tasks mmlu,gsm8k,humaneval \
  --num_fewshot 5 \
  --batch_size auto
```

**支援**：
- `generate_until`: ✅
- `loglikelihood`: ❌ (無 logprobs)
- `loglikelihood_rolling`: ❌

**重要提示**：對話模型不提供 logprobs，因此只能用於生成任務（MMLU、GSM8K、HumanEval），不能用於困惑度任務。

### 配置選項

```bash
lm_eval --model openai-chat-completions \
  --model_args \
    model=gpt-4-turbo,\
    base_url=https://api.openai.com/v1,\
    num_concurrent=5,\
    max_retries=3,\
    timeout=60,\
    batch_size=auto
```

**參數**：
- `model`：模型標識符（必填）
- `base_url`：API 端點（預設：OpenAI）
- `num_concurrent`：並行請求數（預設：5）
- `max_retries`：重試失敗請求次數（預設：3）
- `timeout`：請求超時秒數（預設：60）
- `tokenizer`：要使用的分詞器（預設：匹配模型）
- `tokenizer_backend`：`"tiktoken"` 或 `"huggingface"`

### 成本管理

OpenAI 按 Token 收費。在運行前估算成本：

```python
# 粗略估算
num_samples = 1000
avg_tokens_per_sample = 500  # 輸入 + 輸出
cost_per_1k_tokens = 0.01  # GPT-3.5 Turbo

total_cost = (num_samples * avg_tokens_per_sample / 1000) * cost_per_1k_tokens
print(f"Estimated cost: ${total_cost:.2f}")
```

**省錢技巧**：
- 使用 `--limit N` 進行測試
- 在使用 `gpt-4` 之前先從 `gpt-3.5-turbo` 開始
- 將 `max_gen_toks` 設置為所需的最小值
- 儘可能使用 `num_fewshot=0` 進行零樣本評估

## Anthropic 模型

### 設置

```bash
export ANTHROPIC_API_KEY=sk-ant-...
```

### 補全模型 (Legacy)

```bash
lm_eval --model anthropic-completions \
  --model_args model=claude-2.1 \
  --tasks lambada_openai,hellaswag \
  --batch_size auto
```

### 對話模型（推薦）

**可用模型**：`claude-3-5-sonnet-20241022`, `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`

```bash
lm_eval --model anthropic-chat \
  --model_args model=claude-3-5-sonnet-20241022 \
  --tasks mmlu,gsm8k,humaneval \
  --num_fewshot 5 \
  --batch_size auto
```

**別名**：`anthropic-chat-completions` (與 `anthropic-chat` 相同)

### 配置選項

```bash
lm_eval --model anthropic-chat \
  --model_args \
    model=claude-3-5-sonnet-20241022,\
    base_url=https://api.anthropic.com,\
    num_concurrent=5,\
    max_retries=3,\
    timeout=60
```

### 成本管理

Anthropic 價格（截至 2024 年）：
- Claude 3.5 Sonnet: 每 1M 輸入 $3.00，每 1M 輸出 $15.00
- Claude 3 Opus: 每 1M 輸入 $15.00，每 1M 輸出 $75.00
- Claude 3 Haiku: 每 1M 輸入 $0.25，每 1M 輸出 $1.25

**預算友好策略**：
```bash
# 先在小樣本上測試
lm_eval --model anthropic-chat \
  --model_args model=claude-3-haiku-20240307 \
  --tasks mmlu \
  --limit 100

# 然後在最佳模型上運行完整評估
lm_eval --model anthropic-chat \
  --model_args model=claude-3-5-sonnet-20241022 \
  --tasks mmlu \
  --num_fewshot 5
```

## 本地相容 OpenAI 的 API

許多本地推理伺服器都暴露了相容 OpenAI 的 API (vLLM, Text Generation Inference, llama.cpp, Ollama)。

### vLLM 本地伺服器

**啟動伺服器**：
```bash
vllm serve meta-llama/Llama-2-7b-hf \
  --host 0.0.0.0 \
  --port 8000
```

**評估**：
```bash
lm_eval --model local-completions \
  --model_args \
    model=meta-llama/Llama-2-7b-hf,\
    base_url=http://localhost:8000/v1,\
    num_concurrent=1 \
  --tasks mmlu,gsm8k \
  --batch_size auto
```

### Text Generation Inference (TGI)

**啟動伺服器**：
```bash
docker run --gpus all --shm-size 1g -p 8080:80 \
  ghcr.io/huggingface/text-generation-inference:latest \
  --model-id meta-llama/Llama-2-7b-hf
```

**評估**：
```bash
lm_eval --model local-completions \
  --model_args \
    model=meta-llama/Llama-2-7b-hf,\
    base_url=http://localhost:8080/v1 \
  --tasks hellaswag,arc_challenge
```

### Ollama

**啟動伺服器**：
```bash
ollama serve
ollama pull llama2:7b
```

**評估**：
```bash
lm_eval --model local-completions \
  --model_args \
    model=llama2:7b,\
    base_url=http://localhost:11434/v1 \
  --tasks mmlu
```

### llama.cpp 伺服器

**啟動伺服器**：
```bash
./server -m models/llama-2-7b.gguf --host 0.0.0.0 --port 8080
```

**評估**：
```bash
lm_eval --model local-completions \
  --model_args \
    model=llama2,\
    base_url=http://localhost:8080/v1 \
  --tasks gsm8k
```

## 自定義 API 實現

對於自定義 API 端點，請繼承 `TemplateAPI`：

### 創建 `my_api.py`

```python
from lm_eval.models.api_models import TemplateAPI
import requests

class MyCustomAPI(TemplateAPI):
    """自定義 API 模型。"""

    def __init__(self, base_url, api_key, **kwargs):
        super().__init__(base_url=base_url, **kwargs)
        self.api_key = api_key

    def _create_payload(self, messages, gen_kwargs):
        """創建 API 請求負載。"""
        return {
            "messages": messages,
            "api_key": self.api_key,
            **gen_kwargs
        }

    def parse_generations(self, response):
        """解析生成響應。"""
        return response.json()["choices"][0]["text"]

    def parse_logprobs(self, response):
        """解析 logprobs（如果可用）。"""
        # 如果 API 不提供 logprobs，則返回 None
        logprobs = response.json().get("logprobs")
        if logprobs:
            return logprobs["token_logprobs"]
        return None
```

### 註冊並使用

```python
from lm_eval import evaluator
from my_api import MyCustomAPI

model = MyCustomAPI(
    base_url="https://api.example.com/v1",
    api_key="your-key"
)

results = evaluator.simple_evaluate(
    model=model,
    tasks=["mmlu", "gsm8k"],
    num_fewshot=5,
    batch_size="auto"
)
```

## 比較 API 模型和開源模型

### 並行評估

```bash
# 評估 OpenAI GPT-4
lm_eval --model openai-chat-completions \
  --model_args model=gpt-4-turbo \
  --tasks mmlu,gsm8k,hellaswag \
  --num_fewshot 5 \
  --output_path results/gpt4.json

# 評估開源 Llama 2 70B
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-70b-hf,dtype=bfloat16 \
  --tasks mmlu,gsm8k,hellaswag \
  --num_fewshot 5 \
  --output_path results/llama2-70b.json

# 比較結果
python scripts/compare_results.py \
  results/gpt4.json \
  results/llama2-70b.json
```

### 典型比較

| 模型 | MMLU | GSM8K | HumanEval | 成本 |
|-------|------|-------|-----------|------|
| GPT-4 Turbo | 86.4% | 92.0% | 67.0% | $$$$ |
| Claude 3 Opus | 86.8% | 95.0% | 84.9% | $$$$ |
| GPT-3.5 Turbo | 70.0% | 57.1% | 48.1% | $$ |
| Llama 2 70B | 68.9% | 56.8% | 29.9% | 免費 (自託管) |
| Mixtral 8x7B | 70.6% | 58.4% | 40.2% | 免費 (自託管) |

## 最佳實踐

### 速率限制 (Rate Limiting)

遵守 API 速率限制：
```bash
lm_eval --model openai-chat-completions \
  --model_args \
    model=gpt-4-turbo,\
    num_concurrent=3,\  # 降低並發
    timeout=120 \  # 延長超時
  --tasks mmlu
```

### 可重複性

將溫度 (Temperature) 設置為 0 以獲得確定的結果：
```bash
lm_eval --model openai-chat-completions \
  --model_args model=gpt-4-turbo \
  --tasks mmlu \
  --gen_kwargs temperature=0.0
```

或使用 `seed` 進行採樣：
```bash
lm_eval --model anthropic-chat \
  --model_args model=claude-3-5-sonnet-20241022 \
  --tasks gsm8k \
  --gen_kwargs temperature=0.7,seed=42
```

### 快取 (Caching)

API 模型會自動快取響應以避免重複調用：
```bash
# 第一次運行：進行 API 調用
lm_eval --model openai-chat-completions \
  --model_args model=gpt-4-turbo \
  --tasks mmlu \
  --limit 100

# 第二次運行：使用快取（即時、免費）
lm_eval --model openai-chat-completions \
  --model_args model=gpt-4-turbo \
  --tasks mmlu \
  --limit 100
```

快取位置：`~/.cache/lm_eval/`

### 錯誤處理

API 可能會失敗。使用重試機制：
```bash
lm_eval --model openai-chat-completions \
  --model_args \
    model=gpt-4-turbo,\
    max_retries=5,\
    timeout=120 \
  --tasks mmlu
```

## 故障排除

### "Authentication failed" (身份驗證失敗)

檢查 API 金鑰：
```bash
echo $OPENAI_API_KEY  # 應該顯示 sk-...
echo $ANTHROPIC_API_KEY  # 應該顯示 sk-ant-...
```

### "Rate limit exceeded" (超出速率限制)

減少並發：
```bash
--model_args num_concurrent=1
```

或在請求之間添加延遲。

### "Timeout error" (超時錯誤)

增加超時時間：
```bash
--model_args timeout=180
```

### "Model not found" (找不到模型)

對於本地 API，驗證伺服器是否正在運行：
```bash
curl http://localhost:8000/v1/models
```

### 成本失控

使用 `--limit` 進行測試：
```bash
lm_eval --model openai-chat-completions \
  --model_args model=gpt-4-turbo \
  --tasks mmlu \
  --limit 50  # 僅測試 50 個樣本
```

## 進階功能

### 自定義 Header

```bash
lm_eval --model local-completions \
  --model_args \
    base_url=http://api.example.com/v1,\
    header="Authorization: Bearer token,X-Custom: value"
```

### 禁用 SSL 驗證（僅用於開發）

```bash
lm_eval --model local-completions \
  --model_args \
    base_url=https://localhost:8000/v1,\
    verify_certificate=false
```

### 自定義分詞器

```bash
lm_eval --model openai-chat-completions \
  --model_args \
    model=gpt-4-turbo,\
    tokenizer=gpt2,\
    tokenizer_backend=huggingface
```

## 參考資料

- OpenAI API: https://platform.openai.com/docs/api-reference
- Anthropic API: https://docs.anthropic.com/claude/reference
- TemplateAPI: `lm_eval/models/api_models.py`
- OpenAI models: `lm_eval/models/openai_completions.py`
- Anthropic models: `lm_eval/models/anthropic_llms.py`
