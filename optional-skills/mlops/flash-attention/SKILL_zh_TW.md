---
name: optimizing-attention-flash
description: 使用 Flash Attention 優化 Transformer 注意力機制，可實現 2-4 倍的加速並降低 10-20 倍的記憶體消耗。適用於訓練或運行長序列（>512 tokens）的 Transformer、遇到 GPU 注意力機制記憶體不足問題，或需要更快推論速度的場景。支援 PyTorch 原生 SDPA、flash-attn 函式庫、H100 FP8 以及滑動窗口注意力。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [flash-attn, torch, transformers]
metadata:
  hermes:
    tags: [Optimization, Flash Attention, Attention Optimization, Memory Efficiency, Speed Optimization, Long Context, PyTorch, SDPA, H100, FP8, Transformers]

---

# Flash Attention - 高速且記憶體高效的注意力機制

## 快速入門

Flash Attention 透過 IO 感知的碎塊化（tiling）和重計算（recomputation），為 Transformer 注意力機制提供 2-4 倍的加速和 10-20 倍的記憶體消耗降低。

**PyTorch 原生（最簡單，PyTorch 2.2+ 以上版本）**：
```python
import torch
import torch.nn.functional as F

q = torch.randn(2, 8, 512, 64, device='cuda', dtype=torch.float16)  # [batch, heads, seq, dim]
k = torch.randn(2, 8, 512, 64, device='cuda', dtype=torch.float16)
v = torch.randn(2, 8, 512, 64, device='cuda', dtype=torch.float16)

# 若可用，會自動使用 Flash Attention
out = F.scaled_dot_product_attention(q, k, v)
```

**flash-attn 函式庫（功能更全）**：
```bash
pip install flash-attn --no-build-isolation
```

```python
from flash_attn import flash_attn_func

# q, k, v 的形狀：[batch, seqlen, nheads, headdim]
out = flash_attn_func(q, k, v, dropout_p=0.0, causal=True)
```

## 常見工作流程

### 工作流程 1：在現有的 PyTorch 模型中啟用

參考此檢查清單：

```
Flash Attention 整合步驟：
- [ ] 步驟 1：檢查 PyTorch 版本 (≥2.2)
- [ ] 步驟 2：啟用 Flash Attention 後端
- [ ] 步驟 3：透過效能分析驗證加速效果
- [ ] 步驟 4：測試準確度是否與基準線一致
```

**步驟 1：檢查 PyTorch 版本**

```bash
python -c "import torch; print(torch.__version__)"
# 應大於或等於 2.2.0
```

若版本較舊，請升級：
```bash
pip install --upgrade torch
```

**步驟 2：啟用 Flash Attention 後端**

替換標準注意力機制：
```python
# 修改前 (標準注意力機制)
attn_weights = torch.softmax(q @ k.transpose(-2, -1) / math.sqrt(d_k), dim=-1)
out = attn_weights @ v

# 修改後 (Flash Attention)
import torch.nn.functional as F
out = F.scaled_dot_product_attention(q, k, v, attn_mask=mask)
```

強制使用 Flash Attention 後端：
```python
with torch.backends.cuda.sdp_kernel(
    enable_flash=True,
    enable_math=False,
    enable_mem_efficient=False
):
    out = F.scaled_dot_product_attention(q, k, v)
```

**步驟 3：透過效能分析驗證加速效果**

```python
import torch.utils.benchmark as benchmark

def test_attention(use_flash):
    q, k, v = [torch.randn(2, 8, 2048, 64, device='cuda', dtype=torch.float16) for _ in range(3)]

    if use_flash:
        with torch.backends.cuda.sdp_kernel(enable_flash=True):
            return F.scaled_dot_product_attention(q, k, v)
    else:
        attn = (q @ k.transpose(-2, -1) / 8.0).softmax(dim=-1)
        return attn @ v

# 基準測試 (Benchmark)
t_flash = benchmark.Timer(stmt='test_attention(True)', globals=globals())
t_standard = benchmark.Timer(stmt='test_attention(False)', globals=globals())

print(f"Flash 加速版: {t_flash.timeit(100).mean:.3f}s")
print(f"標準版: {t_standard.timeit(100).mean:.3f}s")
```

預期結果：對於長度大於 512 tokens 的序列，可獲得 2-4 倍的加速。

**步驟 4：測試準確度是否與基準線一致**

```python
# 比較輸出結果
q, k, v = [torch.randn(1, 8, 512, 64, device='cuda', dtype=torch.float16) for _ in range(3)]

# Flash Attention
out_flash = F.scaled_dot_product_attention(q, k, v)

# 標準注意力機制
attn_weights = torch.softmax(q @ k.transpose(-2, -1) / 8.0, dim=-1)
out_standard = attn_weights @ v

# 檢查差異
diff = (out_flash - out_standard).abs().max()
print(f"最大差異值: {diff:.6f}")
# 對於 float16，差異應小於 1e-3
```

### 工作流程 2：使用 flash-attn 函式庫以獲得進階功能

適用於多查詢注意力（MQA）、滑動窗口注意力或 H100 FP8。

參考此檢查清單：

```
flash-attn 函式庫設定：
- [ ] 步驟 1：安裝 flash-attn 函式庫
- [ ] 步驟 2：修改注意力機制程式碼
- [ ] 步驟 3：啟用進階功能
- [ ] 步驟 4：測試效能基準
```

**步驟 1：安裝 flash-attn 函式庫**

```bash
# NVIDIA GPUs (CUDA 12.0+)
pip install flash-attn --no-build-isolation

# 驗證安裝
python -c "from flash_attn import flash_attn_func; print('Success')"
```

**步驟 2：修改注意力機制程式碼**

```python
from flash_attn import flash_attn_func

# 輸入形狀：[batch_size, seq_len, num_heads, head_dim]
# 如果原始形狀是 [batch, heads, seq, dim]，則需進行轉置
q = q.transpose(1, 2)  # [batch, seq, heads, dim]
k = k.transpose(1, 2)
v = v.transpose(1, 2)

out = flash_attn_func(
    q, k, v,
    dropout_p=0.1,
    causal=True,  # 用於自迴歸模型
    window_size=(-1, -1),  # 不使用滑動窗口
    softmax_scale=None  # 自動縮放
)

out = out.transpose(1, 2)  # 轉回 [batch, heads, seq, dim]
```

**步驟 3：啟用進階功能**

多查詢注意力 (Multi-query attention, MQA)（多個 head 共享 K/V）：
```python
from flash_attn import flash_attn_func

# q: [batch, seq, num_q_heads, dim]
# k, v: [batch, seq, num_kv_heads, dim]  # 較少的 KV heads
out = flash_attn_func(q, k, v)  # 會自動處理 MQA
```

滑動窗口注意力 (Sliding window attention)（局部注意力）：
```python
# 僅關注前後各 256 個 tokens 的窗口
out = flash_attn_func(
    q, k, v,
    window_size=(256, 256),  # (左, 右) 窗口大小
    causal=True
)
```

**步驟 4：測試效能基準**

```python
import torch
from flash_attn import flash_attn_func
import time

q, k, v = [torch.randn(4, 4096, 32, 64, device='cuda', dtype=torch.float16) for _ in range(3)]

# 預熱 (Warmup)
for _ in range(10):
    _ = flash_attn_func(q, k, v)

# 基準測試
torch.cuda.synchronize()
start = time.time()
for _ in range(100):
    out = flash_attn_func(q, k, v)
    torch.cuda.synchronize()
end = time.time()

print(f"每次迭代耗時: {(end-start)/100*1000:.2f}ms")
print(f"已分配記憶體: {torch.cuda.max_memory_allocated()/1e9:.2f}GB")
```

### 工作流程 3：H100 FP8 優化 (FlashAttention-3)

用於 H100 GPU 上的極致效能。

```
FP8 設定步驟：
- [ ] 步驟 1：確認具備 H100 GPU
- [ ] 步驟 2：安裝支援 FP8 的 flash-attn
- [ ] 步驟 3：將輸入轉換為 FP8
- [ ] 步驟 4：執行 FP8 注意力機制
```

**步驟 1：確認具備 H100 GPU**

```bash
nvidia-smi --query-gpu=name --format=csv
# 應顯示 "H100" 或 "H800"
```

**步驟 2：安裝支援 FP8 的 flash-attn**

```bash
pip install flash-attn --no-build-isolation
# H100 已包含 FP8 支援
```

**步驟 3：將輸入轉換為 FP8**

```python
import torch

q = torch.randn(2, 4096, 32, 64, device='cuda', dtype=torch.float16)
k = torch.randn(2, 4096, 32, 64, device='cuda', dtype=torch.float16)
v = torch.randn(2, 4096, 32, 64, device='cuda', dtype=torch.float16)

# 轉換為 float8_e4m3 (FP8)
q_fp8 = q.to(torch.float8_e4m3fn)
k_fp8 = k.to(torch.float8_e4m3fn)
v_fp8 = v.to(torch.float8_e4m3fn)
```

**步驟 4：執行 FP8 注意力機制**

```python
from flash_attn import flash_attn_func

# FlashAttention-3 在 H100 上會自動使用 FP8 kernel
out = flash_attn_func(q_fp8, k_fp8, v_fp8)
# 結果：約 1.2 PFLOPS，比 FP16 快 1.5-2 倍
```

## 何時使用 vs 替代方案

**使用 Flash Attention 的場景：**
- 訓練序列長度 >512 tokens 的 Transformer 模型
- 對長上下文（>2K tokens）進行推論
- GPU 記憶體受限（標準注意力機制會導致 OOM）
- 需要在不損失精確度的情況下加速 2-4 倍
- 使用 PyTorch 2.2+ 以上版本或可安裝 flash-attn 函式庫

**使用替代方案的場景：**
- **標準注意力機制**：序列長度 <256 tokens（不值得負擔額外開銷）
- **xFormers**：需要更多注意力變體（而不僅僅是速度）
- **記憶體高效注意力 (Memory-efficient attention)**：CPU 推論（Flash Attention 僅限 GPU）

## 常見問題

**問題：ImportError: cannot import flash_attn**

安裝時請加上 no-build-isolation 標記：
```bash
pip install flash-attn --no-build-isolation
```

或先安裝 CUDA toolkit：
```bash
conda install cuda -c nvidia
pip install flash-attn --no-build-isolation
```

**問題：速度比預期慢（沒有加速效果）**

Flash Attention 的收益隨序列長度增加而增加：
- <512 tokens：加速效果極微（10-20%）
- 512-2K tokens：加速 2-3 倍
- >2K tokens：加速 3-4 倍

請檢查序列長度是否足夠。

**問題：RuntimeError: CUDA error**

確認 GPU 是否支援 Flash Attention：
```python
import torch
print(torch.cuda.get_device_capability())
# 應大於或等於 (7, 5)，即 Turing 架構及以上
```

Flash Attention 需求：
- Ampere (A100, A10)：✅ 完全支援
- Turing (T4)：✅ 支援
- Volta (V100)：❌ 不支援

**問題：精確度下降**

檢查數據類型 (dtype) 是否為 float16 或 bfloat16（而非 float32）：
```python
q = q.to(torch.float16)  # 或 torch.bfloat16
```

Flash Attention 使用 float16/bfloat16 以換取速度。不支援 float32。

## 進階主題

**與 HuggingFace Transformers 整合**：請參閱 [references/transformers-integration.md](references/transformers-integration.md) 以瞭解如何在 BERT、GPT、Llama 模型中啟用 Flash Attention。

**效能基準測試**：請參閱 [references/benchmarks.md](references/benchmarks.md) 以瞭解不同 GPU 和序列長度下的詳細速度與記憶體比較。

**演算法細節**：請參閱 [references/algorithm.md](references/algorithm.md) 以瞭解碎塊化策略、重計算和 IO 複雜度分析。

**進階功能**：請參閱 [references/advanced-features.md](references/advanced-features.md) 以瞭解旋轉位置嵌入（Rotary embeddings）、ALiBi、分頁 KV 快取和自定義注意力遮罩。

## 硬體需求

- **GPU**：NVIDIA Ampere 系列以上（A100, A10, A30）或 AMD MI200 系列以上
- **VRAM**：與標準注意力機制相同（Flash Attention 不會增加記憶體需求）
- **CUDA**：12.0+（最低 11.8）
- **PyTorch**：原生支援需 2.2+ 以上版本

**不支援**：V100 (Volta)、CPU 推論

## 相關資源

- 論文："FlashAttention: Fast and Memory-Efficient Exact Attention with IO-Awareness" (NeurIPS 2022)
- 論文："FlashAttention-2: Faster Attention with Better Parallelism and Work Partitioning" (ICLR 2024)
- 部落格：https://tridao.me/blog/2024/flash3/
- GitHub：https://github.com/Dao-AILab/flash-attention
- PyTorch 文件：https://pytorch.org/docs/stable/generated/torch.nn.functional.scaled_dot_product_attention.html
