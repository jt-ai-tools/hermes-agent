# 自定義任務

在 lm-evaluation-harness 中創建領域特定評估任務的完整指南。

## 概述

自定義任務允許您在自己的數據集和指標上評估模型。任務是使用 YAML 配置文件定義的，對於複雜邏輯可以選用 Python 工具。

**為什麼要創建自定義任務**：
- 在私有/領域特定數據上進行評估
- 測試現有基準測試未涵蓋的特定能力
- 為內部模型創建評估流水線 (Pipeline)
- 復現研究實驗

## 快速上手

### 最小化自定義任務

創建 `my_tasks/simple_qa.yaml`：

```yaml
task: simple_qa
dataset_path: data/simple_qa.jsonl
output_type: generate_until
doc_to_text: "Question: {{question}}\nAnswer:"
doc_to_target: "{{answer}}"
metric_list:
  - metric: exact_match
    aggregation: mean
    higher_is_better: true
```

**運行它**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks simple_qa \
  --include_path my_tasks/
```

## 任務配置參考

### 基本欄位

```yaml
# 任務標識
task: my_custom_task           # 唯一的任務名稱（必填）
task_alias: "My Task"          # 顯示名稱
tag:                           # 分組標籤
  - custom
  - domain_specific

# 數據集配置
dataset_path: data/my_data.jsonl  # HuggingFace 數據集或本地路徑
dataset_name: default             # 子集名稱（如果適用）
training_split: train
validation_split: validation
test_split: test

# 評估配置
output_type: generate_until    # 或 loglikelihood, multiple_choice
num_fewshot: 5                 # few-shot 範例數量
batch_size: auto               # 批次大小

# 提示詞模板 (Jinja2)
doc_to_text: "Question: {{question}}"
doc_to_target: "{{answer}}"

# 指標
metric_list:
  - metric: exact_match
    aggregation: mean
    higher_is_better: true

# 元數據
metadata:
  version: 1.0
```

### 輸出類型

**`generate_until`**：自由格式生成
```yaml
output_type: generate_until
generation_kwargs:
  max_gen_toks: 256
  until:
    - "\n"
    - "."
  temperature: 0.0
```

**`loglikelihood`**：計算目標的對數概似
```yaml
output_type: loglikelihood
# 用於困惑度 (Perplexity)、分類
```

**`multiple_choice`**：從選項中選擇
```yaml
output_type: multiple_choice
doc_to_choice: "{{choices}}"  # 選項列表
```

## 數據格式

### 本地 JSONL 文件

`data/my_data.jsonl`：
```json
{"question": "What is 2+2?", "answer": "4"}
{"question": "Capital of France?", "answer": "Paris"}
```

**任務配置**：
```yaml
dataset_path: data/my_data.jsonl
dataset_kwargs:
  data_files:
    test: data/my_data.jsonl
```

### HuggingFace 數據集

```yaml
dataset_path: squad
dataset_name: plain_text
test_split: validation
```

### CSV 文件

`data/my_data.csv`：
```csv
question,answer,category
What is 2+2?,4,math
Capital of France?,Paris,geography
```

**任務配置**：
```yaml
dataset_path: data/my_data.csv
dataset_kwargs:
  data_files:
    test: data/my_data.csv
```

## 提示詞工程 (Prompt Engineering)

### 簡單模板

```yaml
doc_to_text: "Question: {{question}}\nAnswer:"
doc_to_target: "{{answer}}"
```

### 條件邏輯

```yaml
doc_to_text: |
  {% if context %}
  Context: {{context}}
  {% endif %}
  Question: {{question}}
  Answer:
```

### 多選題

```yaml
doc_to_text: |
  Question: {{question}}
  A. {{choices[0]}}
  B. {{choices[1]}}
  C. {{choices[2]}}
  D. {{choices[3]}}
  Answer:

doc_to_target: "{{ 'ABCD'[answer_idx] }}"
doc_to_choice: ["A", "B", "C", "D"]
```

### Few-Shot 格式化

```yaml
fewshot_delimiter: "\n\n"        # 範例之間的間隔
target_delimiter: " "            # 問題與回答之間的間隔
doc_to_text: "Q: {{question}}"
doc_to_target: "A: {{answer}}"
```

## 自定義 Python 函數

對於複雜邏輯，請在 `utils.py` 中使用 Python 函數。

### 創建 `my_tasks/utils.py`

```python
def process_docs(dataset):
    """預處理文件。"""
    def _process(doc):
        # 自定義預處理
        doc["question"] = doc["question"].strip().lower()
        return doc

    return dataset.map(_process)

def doc_to_text(doc):
    """自定義提示詞格式化。"""
    context = doc.get("context", "")
    question = doc["question"]

    if context:
        return f"Context: {context}\nQuestion: {question}\nAnswer:"
    return f"Question: {question}\nAnswer:"

def doc_to_target(doc):
    """自定義目標提取。"""
    return doc["answer"].strip().lower()

def aggregate_scores(items):
    """自定義指標聚合。"""
    correct = sum(1 for item in items if item == 1.0)
    total = len(items)
    return correct / total if total > 0 else 0.0
```

### 在任務配置中使用

```yaml
task: my_custom_task
dataset_path: data/my_data.jsonl

# 使用 Python 函數
process_docs: !function utils.process_docs
doc_to_text: !function utils.doc_to_text
doc_to_target: !function utils.doc_to_target

metric_list:
  - metric: exact_match
    aggregation: !function utils.aggregate_scores
    higher_is_better: true
```

## 實際案例

### 案例 1：領域問答任務

**目標**：評估醫學問答表現。

`medical_qa/medical_qa.yaml`：
```yaml
task: medical_qa
dataset_path: data/medical_qa.jsonl
output_type: generate_until
num_fewshot: 3

doc_to_text: |
  Medical Question: {{question}}
  Context: {{context}}
  Answer (be concise):

doc_to_target: "{{answer}}"

generation_kwargs:
  max_gen_toks: 100
  until:
    - "\n\n"
  temperature: 0.0

metric_list:
  - metric: exact_match
    aggregation: mean
    higher_is_better: true
  - metric: !function utils.medical_f1
    aggregation: mean
    higher_is_better: true

filter_list:
  - name: lowercase
    filter:
      - function: lowercase
      - function: remove_whitespace

metadata:
  version: 1.0
  domain: medical
```

### 案例 2：代碼評估

`code_eval/python_challenges.yaml`：
```yaml
task: python_challenges
dataset_path: data/python_problems.jsonl
output_type: generate_until
num_fewshot: 0

doc_to_text: |
  Write a Python function to solve:
  {{problem_statement}}

  Function signature:
  {{function_signature}}

doc_to_target: "{{canonical_solution}}"

generation_kwargs:
  max_gen_toks: 512
  until:
    - "\n\nclass"
    - "\n\ndef"
  temperature: 0.2

metric_list:
  - metric: !function utils.execute_code
    aggregation: mean
    higher_is_better: true

process_results: !function utils.process_code_results

metadata:
  version: 1.0
```

## 進階功能

### 輸出過濾 (Output Filtering)

```yaml
filter_list:
  - name: extract_answer
    filter:
      - function: regex
        regex_pattern: "Answer: (.*)"
        group: 1
      - function: lowercase
      - function: strip_whitespace
```

### 多重指標

```yaml
metric_list:
  - metric: exact_match
    aggregation: mean
    higher_is_better: true
  - metric: f1
    aggregation: mean
    higher_is_better: true
  - metric: bleu
    aggregation: mean
    higher_is_better: true
```

### 任務組 (Task Groups)

創建 `my_tasks/_default.yaml`：
```yaml
group: my_eval_suite
task:
  - simple_qa
  - medical_qa
  - python_challenges
```

**運行整個套件**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks my_eval_suite \
  --include_path my_tasks/
```

## 測試您的任務

### 驗證配置

```bash
# 測試任務加載
lm_eval --tasks my_custom_task --include_path my_tasks/ --limit 0

# 在 5 個樣本上運行
lm_eval --model hf \
  --model_args pretrained=gpt2 \
  --tasks my_custom_task \
  --include_path my_tasks/ \
  --limit 5
```

### 偵錯模式 (Debug Mode)

```bash
lm_eval --model hf \
  --model_args pretrained=gpt2 \
  --tasks my_custom_task \
  --include_path my_tasks/ \
  --limit 1 \
  --log_samples  # 保存輸入/輸出樣本
```

## 最佳實踐

1. **從簡單開始**：先測試最小配置
2. **對任務進行版本管理**：使用 `metadata.version`
3. **記錄您的指標**：在註釋中解釋自定義指標
4. **使用多個模型測試**：確保穩健性
5. **在已知範例上驗證**：包含健全性檢查 (Sanity Checks)
6. **謹慎使用過濾器**：可能會隱藏錯誤
7. **處理邊緣情況**：空字符串、缺失欄位

## 常見模式

### 分類任務

```yaml
output_type: loglikelihood
doc_to_text: "Text: {{text}}\nLabel:"
doc_to_target: " {{label}}"  # 空格前綴很重要！
metric_list:
  - metric: acc
    aggregation: mean
```

### 困惑度評估 (Perplexity)

```yaml
output_type: loglikelihood_rolling
doc_to_text: "{{text}}"
metric_list:
  - metric: perplexity
    aggregation: perplexity
```

## 故障排除

**"Task not found" (找不到任務)**：檢查 `--include_path` 和任務名稱

**結果為空**：驗證 `doc_to_text` 和 `doc_to_target` 模板

**指標錯誤**：確保指標名稱正確（例如 exact_match，而不是 exact-match）

**過濾器問題**：使用 `--log_samples` 測試過濾器

**找不到 Python 函數**：檢查 `!function module.function_name` 語法

## 參考資料

- 任務系統：EleutherAI/lm-evaluation-harness 文檔
- 範例任務：`lm_eval/tasks/` 目錄
- TaskConfig: `lm_eval/api/task.py`
