---
name: slime-rl-training
description: 提供使用 slime（一個結合 Megatron 和 SGLang 的框架）進行大型語言模型 (LLM) 強化學習 (RL) 後訓練的指南。適用於訓練 GLM 模型、實作自定義資料生成流程，或在強化學習規模化中需要與 Megatron-LM 緊密整合的場景。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [sglang-router>=0.2.3, ray, torch>=2.0.0, transformers>=4.40.0]
metadata:
  hermes:
    tags: [Reinforcement Learning, Megatron-LM, SGLang, GRPO, Post-Training, GLM]

---

# slime：用於強化學習規模化的 LLM 後訓練框架

slime 是由清華大學 THUDM 團隊開發的 LLM 後訓練 (Post-Training) 框架，為 GLM-4.5、GLM-4.6 和 GLM-4.7 提供技術支援。它將用於訓練的 Megatron-LM 與用於高吞吐量 Rollout 生成的 SGLang 相結合。

## 何時使用 slime

**在以下需求下選擇 slime：**
- 使用 Megatron-LM 原生訓練並搭配 SGLang 進行推論
- 具有靈活資料緩衝區的自定義資料生成流程
- 訓練 GLM、Qwen3、DeepSeek V3 或 Llama 3 模型
- 具有生產環境背書（Z.ai）的開發研究級框架

**在以下情況下考慮替代方案：**
- 需要企業級的穩定性功能 → 使用 **miles**
- 想要更靈活的後端切換能力 → 使用 **verl**
- 需要 PyTorch 原生抽象層 → 使用 **torchforge**

## 核心特點

- **訓練 (Training)**：支援完整並行化（TP, PP, DP, SP）的 Megatron-LM
- **推論生成 (Rollout)**：基於 SGLang 與 Router 的高吞吐量生成
- **資料緩衝區 (Data Buffer)**：靈活的提示詞 (Prompt) 管理與樣本儲存
- **支援模型**：GLM-4.x, Qwen3, DeepSeek V3/R1, Llama 3

## 架構概觀

```
┌─────────────────────────────────────────────────────────┐
│                    資料緩衝區 (Data Buffer)              │
│ - 提示詞初始化與管理                                     │
│ - 自定義資料生成與過濾                                   │
│ - Rollout 樣本儲存                                      │
└─────────────┬───────────────────────────┬───────────────┘
              │                           │
┌─────────────▼───────────┐ ┌─────────────▼───────────────┐
│     訓練 (Megatron-LM)   │ │  推論 (SGLang + Router)      │
│ - Actor 模型訓練         │ │ - 回應生成                   │
│ - Critic (選用)          │ │ - 獎勵/驗證器輸出            │
│ - 同步權重至推論端       │ │ - 支援多輪對話               │
└─────────────────────────┘ └─────────────────────────────┘
```

## 安裝

```bash
# 建議方式：使用 Docker
docker pull slimerl/slime:latest
docker run --rm --gpus all --ipc=host --shm-size=16g \
  -it slimerl/slime:latest /bin/bash

# 在容器內
cd /root/slime && pip install -e . --no-deps
```

### 從原始碼安裝

```bash
git clone https://github.com/THUDM/slime.git
cd slime
pip install -r requirements.txt
pip install -e .
```

## 快速上手：GRPO 訓練

```bash
# 載入模型組態
source scripts/models/qwen3-4B.sh

# 啟動訓練
python train.py \
    --actor-num-nodes 1 \
    --actor-num-gpus-per-node 4 \
    --rollout-num-gpus 4 \
    --advantage-estimator grpo \
    --use-kl-loss --kl-loss-coef 0.001 \
    --rollout-batch-size 32 \
    --n-samples-per-prompt 8 \
    --global-batch-size 256 \
    --num-rollout 3000 \
    --prompt-data /path/to/data.jsonl \
    ${MODEL_ARGS[@]} ${CKPT_ARGS[@]}
```

---

## 工作流程 1：標準 GRPO 訓練

使用此流程來訓練具備群組相對優勢 (group-relative advantages) 的推理模型。

### 前置檢查清單
- [ ] Docker 環境或已安裝 Megatron-LM + SGLang
- [ ] 模型檢查點 (HuggingFace 或 Megatron 格式)
- [ ] JSONL 格式的訓練資料

### 步驟 1：準備資料

```python
# data.jsonl 格式
{"prompt": "What is 2 + 2?", "label": "4"}
{"prompt": "Solve: 3x = 12", "label": "x = 4"}
```

或者使用對話格式：
```python
{
    "prompt": [
        {"role": "system", "content": "你是一位數學老師。"},
        {"role": "user", "content": "15 + 27 等於多少？"}
    ],
    "label": "42"
}
```

### 步驟 2：組態模型

選擇預先定義的模型腳本：

```bash
# 列出可用模型
ls scripts/models/
# glm4-9B.sh, qwen3-4B.sh, qwen3-30B-A3B.sh, deepseek-v3.sh, llama3-8B.sh, ...

# 載入您的模型
source scripts/models/qwen3-4B.sh
```

### 步驟 3：啟動訓練

```bash
python train.py \
    --actor-num-nodes 1 \
    --actor-num-gpus-per-node 8 \
    --rollout-num-gpus 8 \
    --advantage-estimator grpo \
    --use-kl-loss \
    --kl-loss-coef 0.001 \
    --prompt-data /path/to/train.jsonl \
    --input-key prompt \
    --label-key label \
    --apply-chat-template \
    --rollout-batch-size 32 \
    --n-samples-per-prompt 8 \
    --global-batch-size 256 \
    --num-rollout 3000 \
    --save-interval 100 \
    --eval-interval 50 \
    ${MODEL_ARGS[@]}
```

### 步驟 4：監控訓練
- [ ] 檢查 TensorBoard：`tensorboard --logdir outputs/`
- [ ] 驗證獎勵曲線是否呈上升趨勢
- [ ] 監控跨節點的 GPU 使用率

---

## 工作流程 2：非同步訓練

透過重疊推論生成與訓練過程，使用非同步模式獲得更高的吞吐量。

### 何時使用非同步
- 生成時間較長的大型模型
- 同步模式下 GPU 閒置時間過長
- 有足夠記憶體進行緩衝

### 啟動非同步訓練

```bash
python train_async.py \
    --actor-num-nodes 1 \
    --actor-num-gpus-per-node 8 \
    --rollout-num-gpus 8 \
    --advantage-estimator grpo \
    --async-buffer-size 4 \
    --prompt-data /path/to/train.jsonl \
    ${MODEL_ARGS[@]}
```

### 非同步專用參數

```bash
--async-buffer-size 4        # 緩衝的 rollout 數量
--update-weights-interval 2  # 每 N 個 rollout 同步一次權重
```

---

## 工作流程 3：多輪代理對話式訓練

使用此流程訓練具備工具使用或多步推理能力的代理 (Agent)。

### 前置條件
- [ ] 用於多輪對話邏輯的自定義生成函數
- [ ] 工具/環境介面

### 步驟 1：定義自定義生成函數

```python
# custom_generate.py
async def custom_generate(args, samples, evaluation=False):
    """具備工具調用的多輪生成。"""
    for sample in samples:
        conversation = sample.prompt

        for turn in range(args.max_turns):
            # 生成回應
            response = await generate_single(conversation)

            # 檢查是否有工具調用
            tool_call = extract_tool_call(response)
            if tool_call:
                tool_result = execute_tool(tool_call)
                conversation.append({"role": "assistant", "content": response})
                conversation.append({"role": "tool", "content": tool_result})
            else:
                break

        sample.response = response
        sample.reward = compute_reward(sample)

    return samples
```

### 步驟 2：使用自定義函數啟動

```bash
python train.py \
    --custom-generate-function-path custom_generate.py \
    --max-turns 5 \
    --prompt-data /path/to/agent_data.jsonl \
    ${MODEL_ARGS[@]}
```

參考 `examples/search-r1/` 獲取完整的多輪搜尋範例。

---

## 組態參數參考

### 三類參數

slime 使用三種類型的參數：

**1. Megatron 參數**（直接傳遞）：
```bash
--tensor-model-parallel-size 2
--pipeline-model-parallel-size 1
--num-layers 32
--hidden-size 4096
```

**2. SGLang 參數**（以 `--sglang-` 為前綴）：
```bash
--sglang-mem-fraction-static 0.8
--sglang-context-length 8192
--sglang-log-level INFO
```

**3. slime 參數**：
```bash
# 資源分配
--actor-num-nodes 1
--actor-num-gpus-per-node 8
--rollout-num-gpus 8
--colocate  # 在訓練與推論之間共享 GPU

# 資料
--prompt-data /path/to/data.jsonl
--input-key prompt
--label-key label

# 訓練迴圈
--num-rollout 3000
--rollout-batch-size 32
--n-samples-per-prompt 8
--global-batch-size 256

# 演算法
--advantage-estimator grpo  # 或：gspo, ppo, reinforce_plus_plus
--use-kl-loss
--kl-loss-coef 0.001
```

### 關鍵約束條件

```
rollout_batch_size × n_samples_per_prompt = global_batch_size × num_steps_per_rollout
```

例如：32 × 8 = 256 × 1

---

## 資料緩衝系統 (Data Buffer)

slime 的資料緩衝區可實現靈活的資料管理：

### 基礎資料源

```python
class RolloutDataSource:
    def get_samples(self, num_samples):
        """從資料集中獲取提示詞。"""
        return self.dataset.sample(num_samples)

    def add_samples(self, samples):
        """生成後調用（預設不執行任何操作）。"""
        pass
```

### 具備緩衝區的資料源 (Off-Policy)

```python
class RolloutDataSourceWithBuffer(RolloutDataSource):
    def __init__(self):
        self.buffer = []

    def add_samples(self, samples):
        """儲存生成的樣本以備重複使用。"""
        self.buffer.extend(samples)

    def buffer_filter(self, args, buffer, num_samples):
        """自定義選擇邏輯（優先權、分層採樣等）。"""
        return select_best(buffer, num_samples)
```

---

## 常見問題與解決方案

### 問題：SGLang 引擎崩潰

**徵兆**：推論引擎在訓練中途停止

**解決方案**：
```bash
# 啟用容錯機制
--use-fault-tolerance

# 增加記憶體分配
--sglang-mem-fraction-static 0.85

# 減小 batch size
--rollout-batch-size 16
```

### 問題：權重同步逾時

**徵兆**：訓練在推論生成後卡住

**解決方案**：
```bash
# 增加同步間隔
--update-weights-interval 5

# 使用共同部署 (colocate) 模式（無網路傳輸）
--colocate
```

### 問題：訓練期間記憶體不足 (OOM)

**徵兆**：反向傳播期間出現 CUDA OOM

**解決方案**：
```bash
# 啟用梯度檢查點
--recompute-activations

# 減小 micro-batch size
--micro-batch-size 1

# 啟用序列並行 (Sequence Parallelism)
--sequence-parallel
```

### 問題：資料載入緩慢

**徵兆**：GPU 在獲取資料期間閒置

**解決方案**：
```bash
# 增加資料處理 worker 數量
--num-data-workers 4

# 使用串流資料集
--streaming-data
```

---

## 支援的模型

| 模型系列 | 組態腳本 |
|--------------|----------------|
| GLM | GLM-4.5, GLM-4.6, GLM-4.7, GLM-Z1-9B |
| Qwen | Qwen3 (4B, 8B, 30B-A3B), Qwen3-MoE, Qwen2.5 |
| DeepSeek | V3, V3.1, R1 |
| Llama | Llama 3 (8B, 70B) |
| 其他 | Kimi K2, Moonlight-16B |

每個模型在 `scripts/models/` 目錄下都有預設的腳本。

---

## 進階主題

### 共同部署 (Co-location) 模式

在訓練和推論之間共享 GPU 以減少記憶體佔用：

```bash
python train.py \
    --colocate \
    --actor-num-gpus-per-node 8 \
    --sglang-mem-fraction-static 0.4 \
    ${MODEL_ARGS[@]}
```

### 自定義獎勵模型 (Reward Model)

```python
# custom_rm.py
class CustomRewardModel:
    def __init__(self, model_path):
        self.model = load_model(model_path)

    def compute_reward(self, prompts, responses):
        inputs = self.tokenize(prompts, responses)
        scores = self.model(inputs)
        return scores.tolist()
```

```bash
--custom-rm-path custom_rm.py
```

### 多任務評估 (Evaluation Multi-Task)

```bash
--eval-prompt-data aime /path/to/aime.jsonl \
--eval-prompt-data gsm8k /path/to/gsm8k.jsonl \
--n-samples-per-eval-prompt 16
```

---

## 相關資源

- **官方文件**：https://thudm.github.io/slime/
- **GitHub**：https://github.com/THUDM/slime
- **部落格**：https://lmsys.org/blog/2025-07-09-slime/
- **範例**：參考 `examples/` 目錄中的 14 個以上實戰範例
