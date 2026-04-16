---
name: grpo-rl-training
description: 使用 TRL 進行 GRPO/RL 微調的專家指南，用於推理和特定任務的模型訓練
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [transformers>=4.47.0, trl>=0.14.0, datasets>=3.2.0, peft>=0.14.0, torch]
metadata:
  hermes:
    tags: [後訓練, 強化學習, GRPO, TRL, RLHF, 獎勵建模, 推理, DPO, PPO, 結構化輸出]

---

# 使用 TRL 進行 GRPO/RL 訓練

使用 Transformer 強化學習 (TRL) 函式庫實作群體相對策略最佳化 (Group Relative Policy Optimization, GRPO) 的專家級指南。本技能提供了經過實戰測試的模式、關鍵見解以及用於自定義獎勵函數微調語言模型的生產級工作流程。

## 何時使用此技能

當您需要執行以下操作時，請使用 GRPO 訓練：
- **強制執行特定的輸出格式**（例如：XML 標籤、JSON、結構化推理）
- **教導可驗證的任務**，並具有客觀的正確性指標（數學、程式碼、事實查核）
- **提高推理能力**，透過獎勵思維鏈 (Chain-of-Thought) 模式
- **使模型與特定領域的行為對齊**，而無需標記的偏好數據
- **同時優化多個目標**（格式 + 正確性 + 風格）

**請勿將 GRPO 用於：**
- 簡單的監督式微調任務（請改用 SFT）
- 沒有明確獎勵信號的任務
- 當您已經擁有高品質的偏好對數據時（請改用 DPO/PPO）

---

## 核心概念

### 1. GRPO 演算法基礎

**關鍵機制：**
- 為每個提示詞 (Prompt) 生成 **多個補全 (Completions)**（群體大小：4-16）
- 使用獎勵函數比較群體內的補全
- 更新策略以偏好相對於群體而言獲得較高獎勵的回覆

**與 PPO 的關鍵區別：**
- 不需要單獨的獎勵模型
- 樣本效率更高（從群體內比較中學習）
- 實作和除錯更簡單

**數學直覺：**
```
對於每個提示詞 p：
  1. 生成 N 個補全：{c₁, c₂, ..., cₙ}
  2. 計算獎勵：{r₁, r₂, ..., rₙ}
  3. 學習增加同一個群體中高獎勵補全的機率，
     並降低低獎勵補全的機率。
```

### 2. 獎勵函數設計哲學

**黃金法則：**
1. **組合多個獎勵函數** - 每個處理一個面向（格式、正確性、風格）
2. **適當調整獎勵權重** - 權重越高 = 信號越強
3. **使用增量獎勵** - 對於部分符合要求的情況給予部分分數
4. **獨立測試獎勵** - 孤立地對每個獎勵函數進行除錯

**獎勵函數類型：**

| 類型 | 使用案例 | 範例權重 |
|------|----------|----------------|
| **正確性** | 可驗證任務（數學、程式碼） | 2.0 (最高) |
| **格式** | 強制執行嚴格結構 | 0.5-1.0 |
| **長度** | 鼓勵冗長或簡潔 | 0.1-0.5 |
| **風格** | 懲罰不想要的模式 | -0.5 到 0.5 |

---

## 實作工作流程

### 步驟 1：資料集準備

**關鍵要求：**
- 聊天格式的提示詞（包含 'role' 和 'content' 的字典列表）
- 包含系統提示詞以設定期望
- 對於可驗證任務，將標準答案 (Ground Truth) 作為額外欄位包含在內

**範例結構：**
```python
from datasets import load_dataset, Dataset

SYSTEM_PROMPT = """
請依照下列格式回覆：
<reasoning>
[您的逐步思考過程]
</reasoning>
<answer>
[最終答案]
</answer>
"""

def prepare_dataset(raw_data):
    """
    將原始數據轉換為 GRPO 相容格式。

    傳回：包含以下欄位的 Dataset：
    - 'prompt': 包含 role/content 的 List[Dict]（系統 + 使用者訊息）
    - 'answer': 字串（標準答案，選填但建議提供）
    """
    return raw_data.map(lambda x: {
        'prompt': [
            {'role': 'system', 'content': SYSTEM_PROMPT},
            {'role': 'user', 'content': x['question']}
        ],
        'answer': extract_answer(x['raw_answer'])
    })
```

**專家技巧：**
- 對於複雜格式，在系統提示詞中使用單樣本 (One-shot) 或少樣本 (Few-shot) 範例
- 保持提示詞簡潔（max_prompt_length：256-512 tokens）
- 在訓練前驗證數據品質（垃圾進，垃圾出）

### 步驟 2：獎勵函數實作

**範例模板結構：**
```python
def reward_function_name(
    prompts,        # List[List[Dict]]: 原始提示詞
    completions,    # List[List[Dict]]: 模型生成的內容
    answer=None,    # 選填：資料集中的標準答案
    **kwargs        # 額外的資料集欄位
) -> list[float]:
    """
    評估補全內容並傳回獎勵值。

    傳回：浮點數列表（每個補全一個值）
    """
    # 提取補全文本
    responses = [comp[0]['content'] for comp in completions]

    # 計算獎勵
    rewards = []
    for response in responses:
        score = compute_score(response)
        rewards.append(score)

    return rewards
```

**範例 1：正確性獎勵（數學/程式碼）**
```python
def correctness_reward(prompts, completions, answer, **kwargs):
    """對正確答案給予高分。"""
    responses = [comp[0]['content'] for comp in completions]
    extracted = [extract_final_answer(r) for r in responses]
    return [2.0 if ans == gt else 0.0
            for ans, gt in zip(extracted, answer)]
```

**範例 2：格式獎勵（結構化輸出）**
```python
import re

def format_reward(completions, **kwargs):
    """獎勵類 XML 的結構化格式。"""
    pattern = r'<reasoning>.*?</reasoning>\s*<answer>.*?</answer>'
    responses = [comp[0]['content'] for comp in completions]
    return [1.0 if re.search(pattern, r, re.DOTALL) else 0.0
            for r in responses]
```

**範例 3：增量格式獎勵（部分分數）**
```python
def incremental_format_reward(completions, **kwargs):
    """對於符合格式要求的部分給予部分分數。"""
    responses = [comp[0]['content'] for comp in completions]
    rewards = []

    for r in responses:
        score = 0.0
        if '<reasoning>' in r:
            score += 0.25
        if '</reasoning>' in r:
            score += 0.25
        if '<answer>' in r:
            score += 0.25
        if '</answer>' in r:
            score += 0.25
        # 懲罰關閉標籤後的額外文字
        if r.count('</answer>') == 1:
            extra_text = r.split('</answer>')[-1].strip()
            score -= len(extra_text) * 0.001
        rewards.append(score)

    return rewards
```

**關鍵見解：**
組合 3-5 個獎勵函數以進行穩健的訓練。順序的重要性低於信號的多樣性。

### 步驟 3：訓練組態

**針對小顯存優化的組態 (Small GPU)**
```python
from trl import GRPOConfig

training_args = GRPOConfig(
    output_dir="outputs/grpo-model",

    # 學習率
    learning_rate=5e-6,          # 較低 = 較穩定
    adam_beta1=0.9,
    adam_beta2=0.99,
    weight_decay=0.1,
    warmup_ratio=0.1,
    lr_scheduler_type='cosine',

    # 批次設定
    per_device_train_batch_size=1,
    gradient_accumulation_steps=4,  # 有效批次 = 4

    # GRPO 相關
    num_generations=8,            # 建議群體大小：8-16
    max_prompt_length=256,
    max_completion_length=512,

    # 訓練時長
    num_train_epochs=1,
    max_steps=None,               # 或設定固定步數（例如：500）

    # 優化
    bf16=True,                    # 在 A100/H100 上更快
    optim="adamw_8bit",          # 節省顯存的優化器
    max_grad_norm=0.1,

    # 日誌
    logging_steps=1,
    save_steps=100,
    report_to="wandb",            # 或 "none" 以禁用日誌
)
```

**高效能組態 (Large GPU)**
```python
training_args = GRPOConfig(
    output_dir="outputs/grpo-model",
    learning_rate=1e-5,
    per_device_train_batch_size=4,
    gradient_accumulation_steps=2,
    num_generations=16,           # 更大的群體 = 更好的信號
    max_prompt_length=512,
    max_completion_length=1024,
    num_train_epochs=1,
    bf16=True,
    use_vllm=True,                # 使用 vLLM 加速生成
    logging_steps=10,
)
```

**關鍵超參數：**

| 參數 | 影響 | 調校建議 |
|-----------|--------|---------------|
| `num_generations` | 用於比較的群體大小 | 從 8 開始，如果顯存允許則增加到 16 |
| `learning_rate` | 收斂速度/穩定性 | 5e-6 (安全), 1e-5 (更快, 風險較高) |
| `max_completion_length` | 輸出冗長度 | 根據您的任務調整（推理建議 512，簡答建議 256） |
| `gradient_accumulation_steps` | 有效批次大小 | 如果顯存受限則增加此值 |

### 步驟 4：模型設置與訓練

**標準設置 (Transformers)**
```python
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import LoraConfig
from trl import GRPOTrainer

# 載入模型
model_name = "Qwen/Qwen2.5-1.5B-Instruct"
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    torch_dtype=torch.bfloat16,
    attn_implementation="flash_attention_2",  # 快 2-3 倍
    device_map="auto"
)

tokenizer = AutoTokenizer.from_pretrained(model_name)
tokenizer.pad_token = tokenizer.eos_token

# 選填：LoRA 用於參數高效微調
peft_config = LoraConfig(
    r=16,                         # Rank (越高 = 容量越大)
    lora_alpha=32,               # 縮放因子 (通常為 2*r)
    target_modules=[
        "q_proj", "k_proj", "v_proj", "o_proj",
        "gate_proj", "up_proj", "down_proj"
    ],
    task_type="CAUSAL_LM",
    lora_dropout=0.05,
)

# 初始化訓練器
trainer = GRPOTrainer(
    model=model,
    processing_class=tokenizer,
    reward_funcs=[
        incremental_format_reward,
        format_reward,
        correctness_reward,
    ],
    args=training_args,
    train_dataset=dataset,
    peft_config=peft_config,      # 全參數微調請移除此項
)

# 訓練
trainer.train()

# 儲存
trainer.save_model("final_model")
```

**Unsloth 設置 (快 2-3 倍)**
```python
from unsloth import FastLanguageModel

model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="google/gemma-3-1b-it",
    max_seq_length=1024,
    load_in_4bit=True,
    fast_inference=True,
    max_lora_rank=32,
)

model = FastLanguageModel.get_peft_model(
    model,
    r=32,
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                    "gate_proj", "up_proj", "down_proj"],
    lora_alpha=32,
    use_gradient_checkpointing="unsloth",
)

# 其餘部分與標準設置相同
trainer = GRPOTrainer(model=model, ...)
trainer.train()
```

---

## 關鍵訓練見解

### 1. 損失值 (Loss) 行為（預期模式）
- **Loss 從接近 0 開始並在訓練期間增加**
- 這是正常的 - Loss 衡量的是與初始策略的 KL 散度
- 模型正在學習（偏離原始行為以優化獎勵）
- 請監控獎勵指標而非 Loss 來判斷進度

### 2. 獎勵追蹤
需要觀察的關鍵指標：
- `reward`：所有補全的平均值
- `reward_std`：群體內的多樣性（應保持 > 0）
- `kl`：與參考模型的 KL 散度（應適度增長）

**健康的訓練模式：**
```
步數 (Step)   獎勵 (Reward)    獎勵標準差 (Reward_Std)   KL 散度
100           0.5              0.3                      0.02
200           0.8              0.25                     0.05
300           1.2              0.2                      0.08  ← 良好的進展
400           1.5              0.15                     0.12
```

**警告信號：**
- 獎勵標準差 (Reward std) → 0（模型塌陷為單一回覆）
- KL 散度爆炸 (> 0.5)（偏離過多，請降低學習率）
- 獎勵停滯（獎勵函數過於苛刻或模型容量不足）

### 3. 常見陷阱與解決方案

| 問題 | 症狀 | 解決方案 |
|---------|---------|----------|
| **模式塌陷 (Mode collapse)** | 所有補全完全相同 | 增加 `num_generations`，增加多樣性懲罰 |
| **沒有學習進展** | 獎勵值持平 | 檢查獎勵函數邏輯，提高學習率 |
| **顯存不足 (OOM)** | 超過 GPU 記憶體 | 減少 `num_generations`，啟用梯度檢查點 (gradient checkpointing) |
| **訓練緩慢** | < 1 it/s | 啟用 `use_vllm=True`，使用 Unsloth，減少序列長度 |
| **忽略格式** | 模型不遵循結構 | 增加格式獎勵權重，添加增量獎勵 |

---

## 進階模式

### 1. 多階段訓練
對於複雜任務，分階段訓練：

```python
# 第一階段：格式合規性 (epochs=1)
trainer_stage1 = GRPOTrainer(
    model=model,
    reward_funcs=[incremental_format_reward, format_reward],
    ...
)
trainer_stage1.train()

# 第二階段：正確性 (epochs=1)
trainer_stage2 = GRPOTrainer(
    model=model,
    reward_funcs=[format_reward, correctness_reward],
    ...
)
trainer_stage2.train()
```

### 2. 自適應獎勵縮放
```python
class AdaptiveReward:
    def __init__(self, base_reward_func, initial_weight=1.0):
        self.func = base_reward_func
        self.weight = initial_weight

    def __call__(self, *args, **kwargs):
        rewards = self.func(*args, **kwargs)
        return [r * self.weight for r in rewards]

    def adjust_weight(self, success_rate):
        """如果模型表現不佳則增加權重，表現良好則減少權重。"""
        if success_rate < 0.3:
            self.weight *= 1.2
        elif success_rate > 0.8:
            self.weight *= 0.9
```

### 3. 自定義資料集整合
```python
def load_custom_knowledge_base(csv_path):
    """範例：學校通訊平台文件。"""
    import pandas as pd
    df = pd.read_csv(csv_path)

    dataset = Dataset.from_pandas(df).map(lambda x: {
        'prompt': [
            {'role': 'system', 'content': CUSTOM_SYSTEM_PROMPT},
            {'role': 'user', 'content': x['question']}
        ],
        'answer': x['expert_answer']
    })
    return dataset
```

---

## 部署與推論

### 儲存並合併 LoRA
```python
# 將 LoRA 適配器合併到基礎模型中
if hasattr(trainer.model, 'merge_and_unload'):
    merged_model = trainer.model.merge_and_unload()
    merged_model.save_pretrained("production_model")
    tokenizer.save_pretrained("production_model")
```

### 推論範例
```python
from transformers import pipeline

generator = pipeline(
    "text-generation",
    model="production_model",
    tokenizer=tokenizer
)

result = generator(
    [
        {'role': 'system', 'content': SYSTEM_PROMPT},
        {'role': 'user', 'content': "請問 15 + 27 等於多少？"}
    ],
    max_new_tokens=256,
    do_sample=True,
    temperature=0.7,
    top_p=0.9
)
print(result[0]['generated_text'])
```

---

## 最佳實踐檢核表

**訓練前：**
- [ ] 驗證資料集格式（提示詞應為 List[Dict]）
- [ ] 在樣本數據上測試獎勵函數
- [ ] 根據數據計算預期的 max_prompt_length
- [ ] 根據顯存選擇合適的 num_generations
- [ ] 設置日誌記錄（推薦使用 wandb）

**訓練期間：**
- [ ] 監控獎勵進度（應增加）
- [ ] 檢查獎勵標準差 reward_std（應保持 > 0.1）
- [ ] 留意 OOM 錯誤（如有需要請減少批次大小）
- [ ] 每 50-100 步抽樣觀察生成結果
- [ ] 在預留集上驗證格式合規性

**訓練後：**
- [ ] 如果使用 PEFT，合併 LoRA 權重
- [ ] 在多樣化的提示詞上進行測試
- [ ] 與基準模型進行比較
- [ ] 記錄獎勵權重和超參數
- [ ] 儲存可重現性組態

---

## 疑難排解指南

### 除錯工作流程
1. **孤立獎勵函數** - 獨立測試每一個
2. **檢查數據分佈** - 確保提示詞的多樣性
3. **降低複雜度** - 從單一獎勵開始，逐漸增加
4. **監控生成結果** - 每 N 步列印樣本
5. **驗證提取邏輯** - 確保答案解析正常運作

### 快速修復
```python
# 除錯獎勵函數
def debug_reward(completions, **kwargs):
    responses = [comp[0]['content'] for comp in completions]
    for i, r in enumerate(responses[:2]):  # 列印前 2 個
        print(f"回覆 {i}: {r[:200]}...")
    return [1.0] * len(responses)  # 假獎勵

# 不進行訓練直接測試
trainer = GRPOTrainer(..., reward_funcs=[debug_reward])
trainer.generate_completions(dataset[:1])  # 僅生成而不更新模型
```

---

## 參考資料與資源

**官方文件：**
- TRL GRPO Trainer: https://huggingface.co/docs/trl/grpo_trainer
- DeepSeek R1 論文: https://arxiv.org/abs/2501.12948
- Unsloth 文件: https://docs.unsloth.ai/

**範例儲存庫：**
- Open R1 實作: https://github.com/huggingface/open-r1
- TRL 範例: https://github.com/huggingface/trl/tree/main/examples

**推薦閱讀：**
- 代理指令的漸進式揭露模式 (Progressive Disclosure Pattern)
- 強化學習中的獎勵塑造 (Reward shaping, Ng et al.)
- LoRA 論文 (Hu et al., 2021)

---

## Agent 使用說明

當載入此技能時：

1. 在實作 GRPO 訓練前**閱讀整份文件**
2. **從最簡單的獎勵函數開始**（例如：基於長度）以驗證設置
3. **使用 `templates/` 目錄中的模板**作為起點
4. **參考 `examples/` 中的範例**進行特定任務的實作
5. **按順序遵循工作流程**（不要跳過步驟）
6. **增量除錯** - 一次添加一個獎勵函數

**關鍵提醒：**
- 始終使用多個獎勵函數（3-5 個最佳）
- 監控獎勵指標，而非 Loss
- 在訓練前測試獎勵函數
- 從小規模開始 (num_generations=4)，逐漸擴大
- 頻繁儲存檢查點 (Checkpoints)（每 100 步一次）

本技能專為**專家級實作**設計。初學者在嘗試 GRPO 之前，應先從監督式微調 (SFT) 開始。
