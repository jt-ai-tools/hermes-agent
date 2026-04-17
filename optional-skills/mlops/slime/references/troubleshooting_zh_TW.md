# slime 疑難排解指南

## 常見問題與解決方案

### SGLang 相關問題

#### 問題：SGLang 引擎崩潰

**症狀**：推理引擎在訓練過程中停止運作，出現連接錯誤。

**解決方案**：

1. **啟用容錯機制**：
```bash
--use-fault-tolerance
```

2. **增加記憶體分配**：
```bash
--sglang-mem-fraction-static 0.85  # 從 0.8 增加
```

3. **減少 Batch Size**：
```bash
--rollout-batch-size 16  # 從 32 減少
```

4. **停用 CUDA Graphs** (僅用於除錯)：
```bash
--sglang-disable-cuda-graph
```

#### 問題：SGLang 路由器負載不均

**症狀**：部分 SGLang 引擎過載，而其他引擎處於閒置狀態。

**解決方案**：

1. **調整路由策略**：
```bash
--sglang-router-strategy round_robin
```

2. **增加引擎數量**：
```bash
--rollout-num-gpus-per-engine 1  # 更多引擎，每個引擎分配較少 GPU
```

### 權重同步 (Weight Synchronization) 問題

#### 問題：權重同步逾時

**症狀**：Rollout 後訓練掛起，出現逾時錯誤。

**解決方案**：

1. **增加同步間隔** (非同步模式)：
```bash
--update-weights-interval 5  # 從 2 增加
```

2. **使用同地協作 (Colocated) 模式** (消除網絡傳輸)：
```bash
--colocate
```

3. **檢查網絡頻寬**：
```bash
# 驗證是否啟用了 InfiniBand
ibstat
```

#### 問題：多節點環境下的權重同步失敗

**症狀**：節點無法接收更新後的權重。

**解決方案**：

1. **設置 NCCL 環境變數**：
```bash
export NCCL_DEBUG=INFO
export NCCL_SOCKET_IFNAME=eth0
export NCCL_IB_DISABLE=0
```

2. **增加逾時時間**：
```bash
export NCCL_TIMEOUT=1800
```

### 記憶體相關問題

#### 問題：訓練過程中發生 OOM (顯存溢出)

**症狀**：反向傳播 (Backward pass) 時發生 CUDA OOM。

**解決方案**：

1. **啟用梯度檢查點 (Gradient Checkpointing)**：
```bash
--recompute-activations
```

2. **減少 Micro-batch Size**：
```bash
--micro-batch-size 1
```

3. **啟用序列並行 (Sequence Parallelism)**：
```bash
--sequence-parallel
```

4. **減少 Global Batch Size**：
```bash
--global-batch-size 128  # 從 256 減少
```

#### 問題：同地協作 (Colocated) 模式下的 OOM

**症狀**：當訓練和推理在相同 GPU 上運行時發生 OOM。

**解決方案**：

1. **減少 SGLang 記憶體佔用**：
```bash
--sglang-mem-fraction-static 0.4  # 從 0.8 減少
```

2. **啟用 Offloading (卸載)**：
```bash
--offload-optimizer-states
```

3. **使用較短的序列長度**：
```bash
--seq-length 2048  # 從 4096 減少
```

### 數據載入問題

#### 問題：數據載入緩慢

**症狀**：獲取數據時 GPU 閒置，GPU 利用率低。

**解決方案**：

1. **增加數據工作進程 (Data Workers)**：
```bash
--num-data-workers 4
```

2. **使用串流數據集**：
```bash
--streaming-data
```

3. **預先 Tokenize 數據**：
```python
# 離線預處理數據
from transformers import AutoTokenizer
tokenizer = AutoTokenizer.from_pretrained("model_path")
# 保存 Tokenize 後的數據
```

#### 問題：數據格式錯誤

**症狀**：KeyError、欄位缺失、解析失敗。

**解決方案**：

1. **驗證數據格式**：
```python
import json
with open("data.jsonl") as f:
    for line in f:
        data = json.loads(line)
        assert "prompt" in data, "缺失 prompt 欄位"
        assert "label" in data, "缺失 label 欄位"
```

2. **檢查 Key 名稱**：
```bash
--input-key prompt  # 必須與您的數據匹配
--label-key label   # 必須與您的數據匹配
```

### 訓練穩定性問題

#### 問題：損失函數 (Loss) 爆炸 / NaN

**症狀**：Loss 變為 NaN 或爆炸式增長。

**解決方案**：

1. **降低學習率 (Learning Rate)**：
```bash
--lr 1e-6  # 從 5e-6 減少
```

2. **啟用梯度裁剪 (Gradient Clipping)**：
```bash
--clip-grad 1.0
```

3. **檢查數據問題**：
```python
# 驗證沒有空的 prompt 或 response
for sample in dataset:
    assert len(sample["prompt"]) > 0
```

4. **使用 BF16 代替 FP16**：
```bash
--bf16  # 數值更穩定
```

#### 問題：獎勵 (Reward) 崩潰

**症狀**：Reward 降至零，模型輸出胡言亂語。

**解決方案**：

1. **增加 KL 懲罰 (KL Penalty)**：
```bash
--kl-loss-coef 0.01  # 從 0.001 增加
```

2. **減少每個 Prompt 的樣本數**：
```bash
--n-samples-per-prompt 4  # 從 8 減少
```

3. **驗證獎勵函數 (Reward Function)**：
```python
# 獨立測試獎勵函數
from custom_rm import reward_func
sample = Sample(prompt="test", response="test response")
reward = reward_func(args, sample)
print(f"Reward: {reward}")  # 應該是一個合理的數值
```

### 非同步 (Async) 訓練問題

#### 問題：同地協作模式不支援非同步訓練

**症狀**：使用 `train_async.py` 搭配 `--colocate` 時報錯。

**解決方案**：同地協作模式不支援非同步訓練。請使用獨立的 GPU：
```bash
# 移除 --colocate 標籤
python train_async.py \
    --actor-num-gpus-per-node 4 \
    --rollout-num-gpus 4 \
    # 不要添加 --colocate
```

#### 問題：非同步模式下的權重過時

**症狀**：策略分歧，行為不一致。

**解決方案**：

1. **減少非同步緩衝區大小**：
```bash
--async-buffer-size 2  # 從 4 減少
```

2. **增加權重更新頻率**：
```bash
--update-weights-interval 1  # 每次 rollout 都進行同步
```

### 多輪 (Multi-Turn) 訓練問題

#### 問題：工具回應 (Tool Responses) 被納入 Loss 計算

**症狀**：模型學會逐字輸出工具回應。

**解決方案**：在自定義生成函數中正確設置 Loss Mask：
```python
def build_loss_mask(sample):
    """建立排除工具回應的 Loss Mask。"""
    mask = []
    for i, token in enumerate(sample.tokens):
        if is_tool_response(token, sample.metadata):
            mask.append(0)  # 不計算 Loss
        else:
            mask.append(1)  # 計算 Loss
    return mask
```

#### 問題：多輪對話上下文過長

**症狀**：多輪對話中發生 OOM 或截斷。

**解決方案**：

1. **限制對話歷史**：
```python
# 在自定義生成函數中
conversation = sample.prompt[-10:]  # 僅保留最後 10 輪
```

2. **增加上下文長度**：
```bash
--sglang-context-length 16384
```

### 檢查點 (Checkpoint) 問題

#### 問題：檢查點載入失敗

**症狀**：無法載入保存的檢查點。

**解決方案**：

1. **驗證檢查點路徑**：
```bash
ls -la /path/to/checkpoint/
```

2. **檢查並行度是否匹配**：
```bash
# 檢查點是用 TP=2 保存的，載入時也必須使用 TP=2
--tensor-model-parallel-size 2
```

3. **將 HuggingFace 轉換為 Megatron** (如有需要)：
```bash
python tools/convert_hf_to_megatron.py \
    --hf_model_path /path/to/hf/model \
    --save_path /path/to/megatron/checkpoint
```

### 除錯技巧

#### 啟用詳細日誌

```bash
--log-level DEBUG
export SLIME_DEBUG=1
```

#### 檢查 GPU 利用率

```bash
watch -n 1 nvidia-smi
```

#### 監控訓練過程

```bash
tensorboard --logdir outputs/
```

#### 獨立測試自定義函數

```python
# 測試獎勵函數
import asyncio
from custom_rm import reward_func

async def test():
    sample = Sample(prompt="test", response="test", label="expected")
    reward = await reward_func(args, sample)
    print(f"Reward: {reward}")

asyncio.run(test())
```

## 約束條件 (Constraint) 參考

請記住以下關鍵約束：

```
rollout_batch_size × n_samples_per_prompt = global_batch_size × num_steps_per_rollout
```

範例：`32 × 8 = 256 × 1`

## 資源

- GitHub Issues: https://github.com/THUDM/slime/issues
- 文件: https://thudm.github.io/slime/
- 範例：`examples/` 目錄
