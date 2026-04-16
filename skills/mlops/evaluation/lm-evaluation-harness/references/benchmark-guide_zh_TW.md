# 基準測試指南

lm-evaluation-harness 中所有 60 多個評估任務的完整指南，包括它們的測量內容以及如何解讀結果。

## 概述

lm-evaluation-harness 包含 60 多個基準測試，涵蓋了：
- 語言理解 (MMLU, GLUE)
- 數學推理 (GSM8K, MATH)
- 代碼生成 (HumanEval, MBPP)
- 指令遵循 (IFEval, AlpacaEval)
- 長文本理解 (LongBench)
- 多語言能力 (AfroBench, NorEval)
- 推理 (BBH, ARC)
- 真實性 (TruthfulQA)

**列出所有任務**：
```bash
lm_eval --tasks list
```

## 主要基準測試

### MMLU (Massive Multitask Language Understanding)

**測量內容**：涵蓋 57 個學科（STEM、人文、社會科學、法律）的廣泛知識。

**任務變體**：
- `mmlu`：原始 57 個學科的基準測試
- `mmlu_pro`：更具挑戰性的版本，專注於推理問題
- `mmlu_prox`：多語言擴展版

**格式**：多選題（4 個選項）

**範例**：
```
問題：法國的首都是哪裡？
A. 柏林
B. 巴黎
C. 倫敦
D. 馬德里
答案：B
```

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks mmlu \
  --num_fewshot 5
```

**解讀**：
- 隨機：25%（機率）
- GPT-3 (175B): 43.9%
- GPT-4: 86.4%
- 人類專家：約 90%

**適用於**：評估一般知識和領域專業知識。

### GSM8K (Grade School Math 8K)

**測量內容**：小學程度應用題的數學推理能力。

**任務變體**：
- `gsm8k`：基礎任務
- `gsm8k_cot`：使用思維鏈 (Chain-of-thought) 提示
- `gsm_plus`：帶有擾動的對抗性變體

**格式**：自由格式生成，提取數值答案

**範例**：
```
問題：一位麵包師做了 200 個餅乾。他在早上賣掉了其中的 3/5，下午賣掉了剩餘部分的 1/4。他還剩多少個餅乾？
答案：60
```

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks gsm8k \
  --num_fewshot 5
```

**解讀**：
- 隨機：約 0%
- GPT-3 (175B): 17.0%
- GPT-4: 92.0%
- Llama 2 70B: 56.8%

**適用於**：測試多步推理和算術能力。

### HumanEval

**測量內容**：根據 Docstrings 生成 Python 代碼（功能正確性）。

**任務變體**：
- `humaneval`：標準基準測試
- `humaneval_instruct`：用於指令微調模型

**格式**：代碼生成，基於執行的評估

**範例**：
```python
def has_close_elements(numbers: List[float], threshold: float) -> bool:
    """ 檢查給定的數字列表中，是否有任何兩個數字彼此之間的距離小於給定的閾值。
    >>> has_close_elements([1.0, 2.0, 3.0], 0.5)
    False
    >>> has_close_elements([1.0, 2.8, 3.0, 4.0, 5.0, 2.0], 0.3)
    True
    """
```

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=codellama/CodeLlama-7b-hf \
  --tasks humaneval \
  --batch_size 1
```

**解讀**：
- 隨機：0%
- GPT-3 (175B): 0%
- Codex: 28.8%
- GPT-4: 67.0%
- Code Llama 34B: 53.7%

**適用於**：評估代碼生成能力。

### BBH (BIG-Bench Hard)

**測量內容**：23 個具有挑戰性的推理任務，模型此前未能超過人類水平。

**類別**：
- 邏輯推理
- 數學應用題
- 社會理解
- 演算法推理

**格式**：多選題和自由格式

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks bbh \
  --num_fewshot 3
```

**解讀**：
- 隨機：約 25%
- GPT-3 (175B): 33.9%
- PaLM 540B: 58.3%
- GPT-4: 86.7%

**適用於**：測試進階推理能力。

### IFEval (Instruction-Following Evaluation)

**測量內容**：遵循特定、可驗證指令的能力。

**指令類型**：
- 格式限制（例如，「用 3 句話回答」）
- 長度限制（例如，「至少使用 100 個單詞」）
- 內容限制（例如，「包含『香蕉』這個詞」）
- 結構限制（例如，「使用列點」）

**格式**：帶有規則驗證的自由格式生成

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-chat-hf \
  --tasks ifeval \
  --batch_size auto
```

**解讀**：
- 測量：指令遵循程度（而非品質）
- GPT-4: 86% 指令遵循
- Claude 2: 84%

**適用於**：評估對話/指令模型。

### GLUE (General Language Understanding Evaluation)

**測量內容**：涵蓋 9 個任務的自然語言理解能力。

**任務**：
- `cola`：語法接受度
- `sst2`：情感分析
- `mrpc`：改寫檢測
- `qqp`：問題對
- `stsb`：語義相似度
- `mnli`：自然語言推理
- `qnli`：問答推理
- `rte`：文本蘊含識別
- `wnli`：Winograd 模式

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=bert-base-uncased \
  --tasks glue \
  --num_fewshot 0
```

**解讀**：
- BERT Base: 78.3 (GLUE 分數)
- RoBERTa Large: 88.5
- 人類基準：87.1

**適用於**：僅編碼器 (Encoder-only) 模型、微調基準。

### LongBench

**測量內容**：長文本理解能力（4K-32K Tokens）。

**涵蓋 21 個任務，包括**：
- 單文件問答
- 多文件問答
- 摘要
- Few-shot 學習
- 代碼補全
- 合成任務

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks longbench \
  --batch_size 1
```

**解讀**：
- 測試上下文利用能力
- 許多模型在超過 4K Tokens 後表現掙扎
- GPT-4 Turbo: 54.3%

**適用於**：評估長文本模型。

## 其他基準測試

### TruthfulQA

**測量內容**：模型說實話與生成聽起來合理的謊言的傾向。

**格式**：帶有 4-5 個選項的多選題

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks truthfulqa_mc2 \
  --batch_size auto
```

**解讀**：
- 較大的模型通常得分較低（謊言更有說服力）
- GPT-3: 58.8%
- GPT-4: 59.0%
- 人類：約 94%

### ARC (AI2 Reasoning Challenge)

**測量內容**：小學科學問題。

**變體**：
- `arc_easy`：較簡單的問題
- `arc_challenge`：需要推理的較難問題

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks arc_challenge \
  --num_fewshot 25
```

**解讀**：
- ARC-Easy：大多數模型 >80%
- ARC-Challenge 隨機：25%
- GPT-4: 96.3%

### HellaSwag

**測量內容**：關於日常情境的常識推理。

**格式**：選擇最合理的續寫

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks hellaswag \
  --num_fewshot 10
```

**解讀**：
- 隨機：25%
- GPT-3: 78.9%
- Llama 2 70B: 85.3%

### WinoGrande

**測量內容**：透過代名詞解析測試常識推理。

**範例**：
```
獎盃放不進咖啡色手提箱，因為 _ 太大了。
A. 獎盃
B. 手提箱
```

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks winogrande \
  --num_fewshot 5
```

### PIQA

**測量內容**：物理常識推理。

**範例**：「要清潔鍵盤，請使用壓縮空氣或……」

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks piqa
```

## 多語言基準測試

### AfroBench

**測量內容**：在 64 種非洲語言中的表現。

**15 個任務**：自然語言理解 (NLU)、文本生成、知識、問答、數學推理

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks afrobench
```

### NorEval

**測量內容**：挪威語理解（9 個任務類別）。

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=NbAiLab/nb-gpt-j-6B \
  --tasks noreval
```

## 領域特定基準測試

### MATH

**測量內容**：高中數學競賽題。

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks math \
  --num_fewshot 4
```

**解讀**：
- 極具挑戰性
- GPT-4: 42.5%
- Minerva 540B: 33.6%

### MBPP (Mostly Basic Python Problems)

**測量內容**：根據自然語言描述進行 Python 編程。

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=codellama/CodeLlama-7b-hf \
  --tasks mbpp \
  --batch_size 1
```

### DROP

**測量內容**：需要離散推理的閱讀理解能力。

**命令**：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks drop
```

## 基準測試選擇指南

### 針對通用模型

運行此套件：
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf \
  --tasks mmlu,gsm8k,hellaswag,arc_challenge,truthfulqa_mc2 \
  --num_fewshot 5
```

### 針對代碼模型

```bash
lm_eval --model hf \
  --model_args pretrained=codellama/CodeLlama-7b-hf \
  --tasks humaneval,mbpp \
  --batch_size 1
```

### 針對對話/指令模型

```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-chat-hf \
  --tasks ifeval,mmlu,gsm8k_cot \
  --batch_size auto
```

### 針對長文本模型

```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-3.1-8B \
  --tasks longbench \
  --batch_size 1
```

## 解讀結果

### 理解指標

**準確率 (Accuracy)**：正確答案的百分比（最常見）

**精確匹配 (Exact Match, EM)**：要求字符串完全一致（嚴格）

**F1 分數 (F1 Score)**：平衡精確率和召回率

**BLEU/ROUGE**：文本生成相似度

**Pass@k**：生成 k 個樣本時通過的百分比

### 典型分數範圍

| 模型大小 | MMLU | GSM8K | HumanEval | HellaSwag |
|------------|------|-------|-----------|-----------|
| 7B | 40-50% | 10-20% | 5-15% | 70-80% |
| 13B | 45-55% | 20-35% | 15-25% | 75-82% |
| 70B | 60-70% | 50-65% | 35-50% | 82-87% |
| GPT-4 | 86% | 92% | 67% | 95% |

### 危險訊號 (Red Flags)

- **所有任務均處於隨機機率水準**：模型未正確訓練
- **生成任務得分精確為 0%**：可能是格式/解析問題
- **不同運行之間存在巨大差異**：檢查種子 (Seed)/採樣設置
- **所有任務都優於 GPT-4**：可能存在數據污染

### 最佳實踐

1. **務必報告 Few-shot 設置**：0-shot, 5-shot 等。
2. **運行多個種子**：報告平均值 ± 標準差
3. **檢查數據污染**：在訓練數據中搜索基準測試範例
4. **與已發布的基準進行比較**：驗證您的設置
5. **報告所有超參數**：模型、批次大小、最大 Tokens、溫度

## 參考資料

- 任務列表：`lm_eval --tasks list`
- 任務 README：`lm_eval/tasks/README.md`
- 論文：請參閱個別基準測試的論文
