# 多 GPU 部署指南

跨多個 GPU 和節點擴展 TensorRT-LLM 的全面指南。

## 並行化策略

### 張量並行 (Tensor Parallelism, TP)

**功能**：將模型的每一層水平拆分到多個 GPU 上。

**使用場景**：
- 模型總大小符合總 GPU 記憶體，但單個 GPU 放不下
- 需要低延遲（單次前向傳遞）
- GPU 位於同一節點內（需要 NVLink 以獲得最佳效能）

**範例**（在 4× A100 上部署 Llama 3-70B）：
```python
from tensorrt_llm import LLM

llm = LLM(
    model="meta-llama/Meta-Llama-3-70B",
    tensor_parallel_size=4,  # 拆分到 4 個 GPU
    dtype="fp16"
)

# 模型自動分片到各個 GPU
# 單次前向傳遞，延遲低
```

**效能**：
- 延遲：與單個 GPU 幾乎相同
- 吞吐量：高 4 倍（使用 4 個 GPU）
- 通訊量：高（每一層都需要同步激活值）

### 流水線並行 (Pipeline Parallelism, PP)

**功能**：將模型的層按順序（垂直）拆分到不同的 GPU。

**使用場景**：
- 超大型模型 (175B+)
- 可以容忍較高的延遲
- GPU 分佈在多個節點上

**範例**（在 8× H100 上部署 Llama 3-405B）：
```python
llm = LLM(
    model="meta-llama/Meta-Llama-3-405B",
    tensor_parallel_size=4,   # 節點內 TP=4
    pipeline_parallel_size=2, # 跨節點 PP=2
    dtype="fp8"
)

# 總計：8 個 GPU (4×2)
# 第 0-40 層：節點 1 (4 個 GPU 採用 TP)
# 第 41-80 層：節點 2 (4 個 GPU 採用 TP)
```

**效能**：
- 延遲：較高（需依序通過流水線）
- 吞吐量：透過微批處理（micro-batching）可獲得高吞吐量
- 通訊量：低於 TP

### 專家並行 (Expert Parallelism, EP)

**功能**：將混合專家模型 (MoE) 的專家分佈到各個 GPU。

**使用場景**：混合專家模型（如 Mixtral, DeepSeek-V2）

**範例**（在 8× A100 上部署 Mixtral-8x22B）：
```python
llm = LLM(
    model="mistralai/Mixtral-8x22B",
    tensor_parallel_size=4,
    expert_parallel_size=2,  # 將 8 個專家分佈到 2 個組
    dtype="fp8"
)
```

## 配置範例

### 小型模型 (7-13B) - 單 GPU

```python
# 在 1× A100 80GB 上部署 Llama 3-8B
llm = LLM(
    model="meta-llama/Meta-Llama-3-8B",
    dtype="fp16"  # 若是 H100 則可選 fp8
)
```

**資源需求**：
- GPU：1× A100 80GB
- 記憶體：~16GB 模型 + 30GB KV 快取
- 吞吐量：3,000-5,000 tokens/sec

### 中型模型 (70B) - 同一節點多 GPU

```python
# 在 4× A100 80GB (NVLink) 上部署 Llama 3-70B
llm = LLM(
    model="meta-llama/Meta-Llama-3-70B",
    tensor_parallel_size=4,
    dtype="fp8"  # 70GB → 每個 GPU 35GB
)
```

**資源需求**：
- GPU：4× A100 80GB 且具備 NVLink
- 記憶體：每個 GPU 約 35GB (FP8)
- 吞吐量：10,000-15,000 tokens/sec
- 延遲：每個 token 15-20ms

### 大型模型 (405B) - 多節點

```python
# 在 2 個節點 × 8 張 H100 = 16 張 GPU 上部署 Llama 3-405B
llm = LLM(
    model="meta-llama/Meta-Llama-3-405B",
    tensor_parallel_size=8,    # 每個節點內採用 TP
    pipeline_parallel_size=2,  # 跨 2 個節點採用 PP
    dtype="fp8"
)
```

**資源需求**：
- GPU：2 個節點 × 8 張 H100 80GB
- 記憶體：每個 GPU 約 25GB (FP8)
- 吞吐量：20,000-30,000 tokens/sec
- 網路：強烈建議使用 InfiniBand

## 伺服器部署

### 單節點多 GPU

```bash
# 在 4 張 GPU 上部署 Llama 3-70B (自動 TP)
trtllm-serve meta-llama/Meta-Llama-3-70B \
    --tp_size 4 \
    --max_batch_size 256 \
    --dtype fp8

# 監聽埠位 http://localhost:8000
```

### 搭配 Ray 進行多節點部署

```bash
# 節點 1 (主節點 Head node)
ray start --head --port=6379

# 節點 2 (工作節點 Worker)
ray start --address='node1:6379'

# 跨叢集部署
trtllm-serve meta-llama/Meta-Llama-3-405B \
    --tp_size 8 \
    --pp_size 2 \
    --num_workers 2 \  # 2 個節點
    --dtype fp8
```

### Kubernetes 部署

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tensorrt-llm-llama3-70b
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: trtllm
        image: nvidia/tensorrt_llm:latest
        command:
          - trtllm-serve
          - meta-llama/Meta-Llama-3-70B
          - --tp_size=4
          - --max_batch_size=256
        resources:
          limits:
            nvidia.com/gpu: 4  # 請求 4 張 GPU
```

## 並行化決策樹

```
模型大小 < 20GB?
├─ 是：單 GPU (不使用並行化)
└─ 否：模型大小 < 80GB?
    ├─ 是：TP=2 或 TP=4 (同一節點)
    └─ 否：模型大小 < 320GB?
        ├─ 是：TP=4 或 TP=8 (同一節點，必須有 NVLink)
        └─ 否：TP=8 + PP=2 (多節點)
```

## 通訊優化

### NVLink vs PCIe

**NVLink** (DGX A100, HGX H100)：
- 頻寬：600 GB/s (A100), 900 GB/s (H100)
- 非常適合 TP（高通訊量需求）
- **建議用於所有多 GPU 設定**

**PCIe**：
- 頻寬：64 GB/s (PCIe 4.0 x16)
- 比 NVLink 慢 10 倍
- 應避免使用 TP，改用 PP

### 用於多節點的 InfiniBand

**HDR InfiniBand** (200 Gb/s)：
- 多節點 TP 或 PP 的必要條件
- 延遲：<1μs
- **對於 405B+ 模型至關重要**

## 監控多 GPU 狀態

```python
# 監控 GPU 利用率
nvidia-smi dmon -s u

# 監控記憶體
nvidia-smi dmon -s m

# 監控 NVLink 利用率
nvidia-smi nvlink --status

# TensorRT-LLM 內建指標
curl http://localhost:8000/metrics
```

**關鍵指標**：
- GPU 利用率：目標設為 80-95%
- 記憶體使用量：各 GPU 應保持平衡
- NVLink 流量：TP 時流量高，PP 時流量低
- 吞吐量：所有 GPU 的總和 tokens/sec

## 常見問題

### GPU 記憶體不平衡

**現象**：GPU 0 佔用 90% 記憶體，GPU 3 僅佔用 40%

**解決方案**：
- 驗證 TP/PP 配置
- 檢查模型分片（應為均等拆分）
- 重啟伺服器以重置狀態

### NVLink 利用率低

**現象**：在使用 TP=4 時，NVLink 頻寬 <100 GB/s

**解決方案**：
- 驗證 NVLink 拓撲：`nvidia-smi topo -m`
- 檢查是否回退（fallback）到 PCIe
- 確保 GPU 位於同一個 NVSwitch 上

### 多 GPU 環境下的 OOM (記憶體溢出)

**解決方案**：
- 增加 TP 大小（使用更多 GPU）
- 減少批處理量 (Batch Size)
- 啟用 FP8 量化
- 使用流水線並行 (Pipeline Parallelism)

## 效能擴展性

### TP 擴展性 (Llama 3-70B, FP8)

| GPU 數 | TP 大小 | 吞吐量 | 延遲 | 效率 |
|------|---------|------------|---------|------------|
| 1 | 1 | OOM | - | - |
| 2 | 2 | 6,000 tok/s | 18ms | 85% |
| 4 | 4 | 11,000 tok/s | 16ms | 78% |
| 8 | 8 | 18,000 tok/s | 15ms | 64% |

**註**：由於通訊開銷，隨著 GPU 數量增加，效率會有所下降。

### PP 擴展性 (Llama 3-405B, FP8)

| 節點數 | TP | PP | 總 GPU 數 | 吞吐量 |
|-------|----|----|------------|------------|
| 1 | 8 | 1 | 8 | OOM |
| 2 | 8 | 2 | 16 | 25,000 tok/s |
| 4 | 8 | 4 | 32 | 45,000 tok/s |

## 最佳實踐

1. **儘可能優先選擇 TP 而非 PP**（延遲較低）
2. **所有 TP 部署均應使用 NVLink**
3. **多節點部署必須使用 InfiniBand**
4. **從能容納模型記憶體的小型 TP 開始**
5. **監控 GPU 平衡** —— 所有 GPU 應具備相似的利用率
6. **在正式上線前進行基準測試**
7. **在 H100 上使用 FP8** 以獲得 2 倍加速
        