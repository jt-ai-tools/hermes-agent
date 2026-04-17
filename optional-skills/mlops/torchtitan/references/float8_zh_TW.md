# TorchTitan 中的 Float8 訓練

Float8 訓練可顯著提升模型訓練速度，特別是當 GEMM 足夠大，且 FP8 tensorcore 的加速效果超過動態量化 (dynamic quantization) 的開銷時。

## 硬體需求

- NVIDIA H100 或更新版本的 GPU (具備 FP8 Tensor Cores)
- Blackwell GPU 用於 MXFP8 訓練

## 安裝

```bash
USE_CPP=0 pip install git+https://github.com/pytorch/ao.git
```

## 用法：張量級縮放 (Tensorwise Scaling)

具有張量級動態縮放的標準 Float8 訓練：

```bash
CONFIG_FILE="./torchtitan/models/llama3/train_configs/llama3_8b.toml" ./run_train.sh \
  --model.converters="quantize.linear.float8" \
  --quantize.linear.float8.enable_fsdp_float8_all_gather \
  --quantize.linear.float8.precompute_float8_dynamic_scale_for_fsdp \
  --compile.enable
```

### 關鍵參數

| 參數 | 說明 |
|----------|-------------|
| `--model.converters="quantize.linear.float8"` | 將 `nn.Linear` 替換為 `Float8Linear` |
| `--quantize.linear.float8.enable_fsdp_float8_all_gather` | 以 float8 進行通訊以節省頻寬 |
| `--quantize.linear.float8.precompute_float8_dynamic_scale_for_fsdp` | 對所有 AMAX/scales 使用單一 all-reduce |
| `--compile.enable` | 必要條件 - 用於融合 float8 縮放/轉換核函數 (kernels) |

## 用法：行級縮放 (Rowwise Scaling)

比張量級縮放更高的準確度：

```bash
CONFIG_FILE="./torchtitan/models/llama3/train_configs/llama3_8b.toml" ./run_train.sh \
  --model.converters="quantize.linear.float8" \
  --quantize.linear.float8.recipe_name rowwise \
  --compile.enable
```

## 過濾層 (Filtering Layers)

並非所有層都能從 Float8 中受益。可過濾小型層：

```bash
--quantize.linear.float8.filter_fqns="attention.wk,attention.wv,output"
```

### 自動過濾

自動跳過因太小而無法受益的層：

```bash
--quantize.linear.float8.filter_fqns="auto_filter_small_kn"
```

閾值是根據 H100 微基準測試設定的，即加速效果大於開銷的點。

## TOML 配置

```toml
[model]
converters = ["quantize.linear.float8"]

[quantize.linear.float8]
enable_fsdp_float8_all_gather = true
precompute_float8_dynamic_scale_for_fsdp = true
filter_fqns = ["output", "auto_filter_small_kn"]

[compile]
enable = true
components = ["model", "loss"]
```

## Float8 如何與分散式訓練配合運作

### 單一設備

在前向傳播內部，呼叫 `torch._scaled_mm` 之前，將輸入與權重轉換為 float8：

```python
# Float8 矩陣乘法 (matmul) 需要縮放因子 (scales)
torch._scaled_mm(input_fp8, weight_fp8, scale_a=scale_input, scale_b=scale_weight)
```

### FSDP + Float8

1. 將分片後的高精度權重 (每個秩 1/N) 轉換為 float8。
2. 執行 float8 all-gather (相較於 bf16/fp32 可節省頻寬)。
3. 在各個秩之間通訊 `max(abs)` 以進行縮放計算。
4. 在前向傳播開始時，準備好未分片的 float8 權重。

**淨收益**：取決於世界大小 (world size) 與訊息大小，float8 all-gather + amax 通訊的速度可能優於 bf16/fp32 all-gather。

### TP + Float8

- **輸入**：將分片後的輸入轉換為 float8，並以 float8 進行 all-gather。
- **權重**：針對分片後的權重通訊 `max(abs)`。
- **矩陣乘法**：使用全域縮放因子執行 float8 輸入 (未分片) x float8 權重 (分片)。

## 縮放策略

| 策略 | 狀態 | 說明 |
|----------|--------|-------------|
| 張量級動態 (Tensorwise dynamic) | 穩定 (Stable) | 每個張量使用單一縮放因子 |
| 行級動態 (Rowwise dynamic) | Alpha 版 | 每一行使用一個縮放因子，準確度更高 |

## 效能提升

根據 H100 上的基準測試：

| 配置 | TPS/GPU | 相較於基準 |
|---------------|---------|-------------|
| 僅 FSDP | 5,762 | - |
| FSDP + 編譯 (compile) | 6,667 | +16% |
| FSDP + 編譯 + Float8 | 8,532 | +48% |

## 判斷 Float8 的收益

請查看 [torchao 微基準測試](https://github.com/pytorch/ao/tree/main/torchao/float8#performance)，瞭解不同 M, N, K 大小下 "layer norm => linear => sigmoid" 的前向+反向傳播加速效果。

經驗法則：K, N > 4096 的 GEMM 通常能從 Float8 中受益。

## MXFP8 訓練 (Blackwell)

針對 NVIDIA Blackwell GPU，TorchTitan 支援用於稠密 (dense) 與 MoE 模型的 MXFP8 (微縮放 Float8)。詳情請參閱 [docs/mxfp8_zh_TW.md](https://github.com/pytorch/torchtitan/blob/main/docs/mxfp8.md) (註：此連結指向原始文件，請參閱對應的中文版本)。
