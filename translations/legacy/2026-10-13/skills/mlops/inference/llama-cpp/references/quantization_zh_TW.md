# GGUF 量化指南

關於 GGUF 量化格式與模型轉換的完整指南。

## 量化概覽

**GGUF** (GPT-Generated Unified Format) - llama.cpp 模型的標準格式。

### 格式比較

| 格式 | 困惑度 (Perplexity) | 大小 (7B) | 標記數/秒 (Tokens/sec) | 備註 |
|--------|------------|-----------|------------|-------|
| FP16 | 5.9565 (基準) | 13.0 GB | 15 tok/s | 原始品質 |
| Q8_0 | 5.9584 (+0.03%) | 7.0 GB | 25 tok/s | 幾乎無損 |
| **Q6_K** | 5.9642 (+0.13%) | 5.5 GB | 30 tok/s | 最佳品質/大小平衡 |
| **Q5_K_M** | 5.9796 (+0.39%) | 4.8 GB | 35 tok/s | 平衡型 |
| **Q4_K_M** | 6.0565 (+1.68%) | 4.1 GB | 40 tok/s | **推薦使用** |
| Q4_K_S | 6.1125 (+2.62%) | 3.9 GB | 42 tok/s | 更快，但品質較低 |
| Q3_K_M | 6.3184 (+6.07%) | 3.3 GB | 45 tok/s | 僅適用於小型模型 |
| Q2_K | 6.8673 (+15.3%) | 2.7 GB | 50 tok/s | 不推薦使用 |

**建議**：使用 **Q4_K_M** 以獲得品質與速度的最佳平衡。

## 轉換模型

### 從 HuggingFace 轉換為 GGUF

```bash
# 1. 下載 HuggingFace 模型
huggingface-cli download meta-llama/Llama-2-7b-chat-hf \
    --local-dir models/llama-2-7b-chat/

# 2. 轉換為 FP16 GGUF
python convert_hf_to_gguf.py \
    models/llama-2-7b-chat/ \
    --outtype f16 \
    --outfile models/llama-2-7b-chat-f16.gguf

# 3. 量化為 Q4_K_M
./llama-quantize \
    models/llama-2-7b-chat-f16.gguf \
    models/llama-2-7b-chat-Q4_K_M.gguf \
    Q4_K_M
```

### 批次量化

```bash
# 量化為多種格式
for quant in Q4_K_M Q5_K_M Q6_K Q8_0; do
    ./llama-quantize \
        model-f16.gguf \
        model-${quant}.gguf \
        $quant
done
```

## K-量化 (K-Quantization) 方法

**K-quants** 使用混合精度以獲得更好的品質：
- 注意力權重 (Attention weights)：使用較高精度
- 前饋權重 (Feed-forward weights)：使用較低精度

**變體**：
- `_S` (Small)：速度更快，品質較低
- `_M` (Medium)：平衡型 (推薦)
- `_L` (Large)：品質更好，檔案較大

**範例**：`Q4_K_M`
- `Q4`：4-bit 量化
- `K`：混合精度方法
- `M`：中等品質 (Medium quality)

## 品質測試

```bash
# 計算困惑度 (困惑度越低，品質越好)
./llama-perplexity \
    -m model.gguf \
    -f wikitext-2-raw/wiki.test.raw \
    -c 512

# 基準 (FP16)：~5.96
# Q4_K_M：~6.06 (+1.7%)
# Q2_K：~6.87 (+15.3% - 損耗過大)
```

## 使用場景指南

### 一般用途 (聊天機器人、助手)
```
Q4_K_M - 最佳平衡
Q5_K_M - 如果有額外的 RAM
```

### 程式碼生成
```
Q5_K_M 或 Q6_K - 較高精度有助於處理程式碼
```

### 創意寫作
```
Q4_K_M - 品質足夠
Q3_K_M - 用於生成草稿尚可接受
```

### 技術/醫療領域
```
Q6_K 或 Q8_0 - 追求最大準確度
```

### 邊緣設備 (Raspberry Pi)
```
Q2_K 或 Q3_K_S - 符合有限的 RAM 限制
```

## 模型大小縮放 (Model Size Scaling)

### 7B 參數模型

| 格式 | 大小 | 所需 RAM |
|--------|------|------------|
| Q2_K | 2.7 GB | 5 GB |
| Q3_K_M | 3.3 GB | 6 GB |
| Q4_K_M | 4.1 GB | 7 GB |
| Q5_K_M | 4.8 GB | 8 GB |
| Q6_K | 5.5 GB | 9 GB |
| Q8_0 | 7.0 GB | 11 GB |

### 13B 參數模型

| 格式 | 大小 | 所需 RAM |
|--------|------|------------|
| Q2_K | 5.1 GB | 8 GB |
| Q3_K_M | 6.2 GB | 10 GB |
| Q4_K_M | 7.9 GB | 12 GB |
| Q5_K_M | 9.2 GB | 14 GB |
| Q6_K | 10.7 GB | 16 GB |

### 70B 參數模型

| 格式 | 大小 | 所需 RAM |
|--------|------|------------|
| Q2_K | 26 GB | 32 GB |
| Q3_K_M | 32 GB | 40 GB |
| Q4_K_M | 41 GB | 48 GB |
| Q4_K_S | 39 GB | 46 GB |
| Q5_K_M | 48 GB | 56 GB |

**70B 模型建議**：使用 Q3_K_M 或 Q4_K_S 以適配消費級硬體。

## 尋找預先量化的模型

HuggingFace 上的 **TheBloke**：
- https://huggingface.co/TheBloke
- 大多數模型都有提供所有 GGUF 格式
- 無需自行轉換

**範例**：
```bash
# 下載預先量化的 Llama 2-7B
huggingface-cli download \
    TheBloke/Llama-2-7B-Chat-GGUF \
    llama-2-7b-chat.Q4_K_M.gguf \
    --local-dir models/
```

## 重要性矩陣 (Importance Matrices, imatrix)

**作用**：使用校準數據來提升量化品質。

**優點**：
- Q4 量化的困惑度提升 10-20%
- 對於 Q3 及以下等級至關重要

**用法**：
```bash
# 1. 生成重要性矩陣
./llama-imatrix \
    -m model-f16.gguf \
    -f calibration-data.txt \
    -o model.imatrix

# 2. 使用 imatrix 進行量化
./llama-quantize \
    --imatrix model.imatrix \
    model-f16.gguf \
    model-Q4_K_M.gguf \
    Q4_K_M
```

**校準數據 (Calibration data)**：
- 使用特定領域的文本 (例如程式碼模型的程式碼)
- 約 100MB 的代表性文本
- 越高質量的數據 = 越好的量化效果

## 故障排除

**模型輸出胡言亂語**：
- 量化程度過於激進 (Q2_K)
- 嘗試 Q4_K_M 或 Q5_K_M
- 驗證模型轉換是否正確

**記憶體不足 (OOM)**：
- 使用較低級別的量化 (使用 Q4_K_S 而非 Q5_K_M)
- 減少卸載到 GPU 的層數 (`-ngl`)
- 使用較小的上下文 (`-c 2048`)

**推論緩慢**：
- 較高級別的量化需要更多計算資源
- Q8_0 比 Q4_K_M 慢得多
- 權衡速度與品質之間的選擇
