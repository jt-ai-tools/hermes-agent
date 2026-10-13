# 資料集 (Datasets)

關於 SimPO 訓練所需偏好資料集的完整指南。

## 資料集格式

### 必要欄位

偏好資料集必須包含：
```json
{
  "prompt": "使用者的問題或指令",
  "chosen": "更好/偏好的回答",
  "rejected": "較差/被拒絕的回答"
}
```

**替代欄位名稱** (會被自動偵測)：
- `prompt` → `question`, `instruction`, `input`
- `chosen` → `response_chosen`, `winner`, `preferred`
- `rejected` → `response_rejected`, `loser`

### 範例項目

```json
{
  "prompt": "用簡單的術語解釋量子計算。",
  "chosen": "量子計算使用量子位元 (qubits)，這些位元可以透過疊加 (superposition) 同時存在於多個狀態。這使得量子電腦能夠同時處理多種可能性，使其在加密和最佳化等特定任務上潛在比傳統電腦快得多。",
  "rejected": "就像普通的計算，但是是量子的。"
}
```

## 熱門資料集

### 1. UltraFeedback (推薦)

**HuggingFaceH4/ultrafeedback_binarized**：
- **大小**：6 萬個偏好對 (Preference pairs)
- **質量**：高 (GPT-4 註釋)
- **領域**：通用指令遵循
- **格式**：乾淨、即插即用

**設定範例**：
```yaml
dataset_mixer:
  HuggingFaceH4/ultrafeedback_binarized: 1.0
dataset_splits:
  - train_prefs
  - test_prefs
```

### 2. Argilla UltraFeedback (清理版)

**argilla/ultrafeedback-binarized-preferences-cleaned**：
- **大小**：5 萬個偏好對 (經過篩選)
- **質量**：極高 (去重、清理過)
- **領域**：通用
- **格式**：乾淨

**設定範例**：
```yaml
dataset_mixer:
  argilla/ultrafeedback-binarized-preferences-cleaned: 1.0
```

### 3. Distilabel Math

**argilla/distilabel-math-preference-dpo**：
- **大小**：3 萬個偏好對
- **質量**：高 (GSM8K, MATH)
- **領域**：數學推理
- **格式**：數學特定

**設定範例**：
```yaml
dataset_mixer:
  argilla/distilabel-math-preference-dpo: 1.0
```

### 4. HelpSteer

**nvidia/HelpSteer**：
- **大小**：3.8 萬個樣本
- **質量**：高 (人類評分)
- **領域**：幫助性對齊 (Helpfulness alignment)
- **格式**：多屬性評分

**設定範例**：
```yaml
dataset_mixer:
  nvidia/HelpSteer: 1.0
```

### 5. Anthropic HH-RLHF

**Anthropic/hh-rlhf**：
- **大小**：16.1 萬個樣本
- **質量**：高 (人類偏好)
- **領域**：無害 + 有幫助
- **格式**：對話式

**設定範例**：
```yaml
dataset_mixer:
  Anthropic/hh-rlhf: 1.0
```

## 資料集混合 (Dataset Mixing)

### 多個資料集

**均等混合**：
```yaml
dataset_mixer:
  HuggingFaceH4/ultrafeedback_binarized: 0.5
  Anthropic/hh-rlhf: 0.5
```

**加權混合**：
```yaml
dataset_mixer:
  HuggingFaceH4/ultrafeedback_binarized: 0.7
  argilla/distilabel-math-preference-dpo: 0.2
  nvidia/HelpSteer: 0.1
```

**特定領域強調**：
```yaml
# 80% 通用 + 20% 數學
dataset_mixer:
  HuggingFaceH4/ultrafeedback_binarized: 0.8
  argilla/distilabel-math-preference-dpo: 0.2
```

## 資料質量

### 質量指標

**良好的偏好資料**：
- ✅ 選中 (chosen) 與拒絕 (rejected) 之間有明顯的質量差異
- ✅ 提示詞 (prompts) 具有多樣性
- ✅ 極少的雜訊/註釋錯誤
- ✅ 適當的難度水平

**劣質的偏好資料**：
- ❌ 模糊不清的偏好
- ❌ 重複的提示詞
- ❌ 註釋雜訊
- ❌ 太簡單或太難的提示詞

### 質量篩選

**按長度差異篩選**：
```python
def filter_by_length(example):
    chosen_len = len(example['chosen'].split())
    rejected_len = len(example['rejected'].split())
    # 如果選中的回答明顯較短則拒絕 (可能是低質量回答)
    return chosen_len >= rejected_len * 0.5

dataset = dataset.filter(filter_by_length)
```

**按多樣性篩選**：
```python
seen_prompts = set()

def filter_duplicates(example):
    prompt = example['prompt']
    if prompt in seen_prompts:
        return False
    seen_prompts.add(prompt)
    return True

dataset = dataset.filter(filter_duplicates)
```

## 自定義資料集建立

### 格式 1：JSON Lines (JSONL)

**檔案內容** (`preferences.jsonl`)：
```jsonl
{"prompt": "什麼是 Python?", "chosen": "Python 是一種高階程式語言...", "rejected": "它是一種蛇。"}
{"prompt": "解釋 AI。", "chosen": "AI 指的是能夠...的系統", "rejected": "它是會思考的電腦。"}
```

**載入方式**：
```yaml
dataset_mixer:
  json:
    data_files: preferences.jsonl
```

### 格式 2：HuggingFace 資料集

**從字典建立**：
```python
from datasets import Dataset

data = {
    "prompt": ["什麼是 Python?", "解釋 AI。"],
    "chosen": ["Python 是...", "AI 指的是..."],
    "rejected": ["它是一種蛇。", "它是電腦..."]
}

dataset = Dataset.from_dict(data)
dataset.push_to_hub("username/my-preferences")
```

**在設定中使用**：
```yaml
dataset_mixer:
  username/my-preferences: 1.0
```

### 格式 3：ChatML

**用於對話式資料**：
```json
{
  "prompt": [
    {"role": "user", "content": "量子計算是什麼？"}
  ],
  "chosen": [
    {"role": "assistant", "content": "量子計算使用量子位元..."}
  ],
  "rejected": [
    {"role": "assistant", "content": "它就像普通的計算，但是是量子的。"}
  ]
}
```

**套用聊天範本**：
```yaml
dataset_text_field: null  # 將會套用聊天範本
```

## 合成資料生成 (Synthetic Data Generation)

### 使用 GPT-4

**提示詞範本**：
```
給定以下問題：
{prompt}

生成兩個回答：
1. 高質量、詳細的回答 (chosen)
2. 低質量、簡短的回答 (rejected)

以 JSON 格式輸出，包含 "chosen" 和 "rejected" 欄位。
```

**範例程式碼**：
```python
import openai

def generate_pair(prompt):
    response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[{
            "role": "user",
            "content": f"給定：{prompt}\n\n以 JSON 格式生成 chosen/rejected 對。"
        }]
    )
    return json.loads(response.choices[0].message.content)

# 生成資料集
prompts = load_prompts()
dataset = [generate_pair(p) for p in prompts]
```

### 使用本地模型

**搭配 vLLM**：
```python
from vllm import LLM

llm = LLM(model="meta-llama/Meta-Llama-3-70B-Instruct")

def generate_variations(prompt):
    # 生成多個完成結果
    outputs = llm.generate(
        [prompt] * 4,
        sampling_params={
            "temperature": 0.8,
            "top_p": 0.9,
            "max_tokens": 512
        }
    )

    # 選擇最好和最差的
    chosen = max(outputs, key=lambda x: len(x.outputs[0].text))
    rejected = min(outputs, key=lambda x: len(x.outputs[0].text))

    return {
        "prompt": prompt,
        "chosen": chosen.outputs[0].text,
        "rejected": rejected.outputs[0].text
    }
```

## 資料預處理 (Data Preprocessing)

### 截斷 (Truncation)

**限制序列長度**：
```yaml
max_prompt_length: 512
max_completion_length: 512
max_length: 1024  # 總計
```

**實作方式**：
```python
def truncate_example(example):
    tokenizer.truncation_side = "left"  # 對提示詞進行左截斷
    prompt_tokens = tokenizer(
        example['prompt'],
        max_length=512,
        truncation=True
    )

    tokenizer.truncation_side = "right"  # 對回答進行右截斷
    chosen_tokens = tokenizer(
        example['chosen'],
        max_length=512,
        truncation=True
    )

    return {
        "prompt": tokenizer.decode(prompt_tokens['input_ids']),
        "chosen": tokenizer.decode(chosen_tokens['input_ids'])
    }

dataset = dataset.map(truncate_example)
```

### 去重 (Deduplication)

**移除完全重複的項目**：
```python
dataset = dataset.unique('prompt')
```

**移除近似重複的項目** (使用 MinHash)：
```python
from datasketch import MinHash, MinHashLSH

def deduplicate_lsh(dataset, threshold=0.8):
    lsh = MinHashLSH(threshold=threshold, num_perm=128)
    seen = []

    for i, example in enumerate(dataset):
        m = MinHash(num_perm=128)
        for word in example['prompt'].split():
            m.update(word.encode('utf8'))

        if not lsh.query(m):
            lsh.insert(i, m)
            seen.append(example)

    return Dataset.from_list(seen)

dataset = deduplicate_lsh(dataset)
```

## 資料增強 (Data Augmentation)

### 改寫提示詞 (Paraphrasing Prompts)

```python
def paraphrase_prompt(example):
    # 使用改寫模型
    paraphrased = paraphrase_model(example['prompt'])

    return [
        example,  # 原始項目
        {
            "prompt": paraphrased,
            "chosen": example['chosen'],
            "rejected": example['rejected']
        }
    ]

dataset = dataset.map(paraphrase_prompt, batched=False, remove_columns=[])
```

### 難度平衡

**混合簡單/中等/困難的項目**：
```python
def categorize_difficulty(example):
    prompt_len = len(example['prompt'].split())
    if prompt_len < 20:
        return "easy"
    elif prompt_len < 50:
        return "medium"
    else:
        return "hard"

dataset = dataset.map(lambda x: {"difficulty": categorize_difficulty(x)})

# 抽樣平衡資料集
easy = dataset.filter(lambda x: x['difficulty'] == 'easy').shuffle().select(range(1000))
medium = dataset.filter(lambda x: x['difficulty'] == 'medium').shuffle().select(range(1000))
hard = dataset.filter(lambda x: x['difficulty'] == 'hard').shuffle().select(range(1000))

balanced = concatenate_datasets([easy, medium, hard]).shuffle()
```

## 資料集統計

### 計算統計數據

```python
def compute_stats(dataset):
    prompt_lens = [len(x['prompt'].split()) for x in dataset]
    chosen_lens = [len(x['chosen'].split()) for x in dataset]
    rejected_lens = [len(x['rejected'].split()) for x in dataset]

    print(f"資料集大小: {len(dataset)}")
    print(f"平均提示詞長度: {np.mean(prompt_lens):.1f} 字")
    print(f"平均選中回答長度: {np.mean(chosen_lens):.1f} 字")
    print(f"平均拒絕回答長度: {np.mean(rejected_lens):.1f} 字")
    print(f"選中 > 拒絕 的比例: {sum(c > r for c, r in zip(chosen_lens, rejected_lens)) / len(dataset):.1%}")

compute_stats(dataset)
```

**預期輸出**：
```
資料集大小: 50000
平均提示詞長度: 45.2 字
平均選中回答長度: 180.5 字
平均拒絕回答長度: 120.3 字
選中 > 拒絕 的比例: 85.2%
```

## 最佳實踐

### 1. 質量重於數量

- **首選**：1 萬個高質量的偏好對
- **而非**：10 萬個充滿雜訊的偏好對

### 2. 清晰的偏好訊號

- 選中的回答應該明顯更好
- 避免細微的差異
- 移除模稜兩可的項目

### 3. 領域匹配

- 確保資料集領域與目標使用場景匹配
- 混合不同資料集以獲得更廣的覆蓋範圍
- 包含經過安全過濾的資料

### 4. 訓練前驗證

```python
# 隨機抽取 10 個範例
samples = dataset.shuffle().select(range(10))

for ex in samples:
    print(f"提示詞: {ex['prompt']}")
    print(f"選中回答: {ex['chosen'][:100]}...")
    print(f"拒絕回答: {ex['rejected'][:100]}...")
    print(f"偏好是否清晰: {'✓' if len(ex['chosen']) > len(ex['rejected']) else '?'}")
    print()
```

## 參考資料

- HuggingFace Datasets: https://huggingface.co/datasets
- Alignment Handbook: https://github.com/huggingface/alignment-handbook
- UltraFeedback: https://huggingface.co/datasets/HuggingFaceH4/ultrafeedback_binarized
