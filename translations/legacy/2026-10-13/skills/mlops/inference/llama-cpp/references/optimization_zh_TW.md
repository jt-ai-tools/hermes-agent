# 效能優化指南

極大化 llama.cpp 的推論速度與效率。

## CPU 優化

### 執行緒調優 (Thread tuning)
```bash
# 設定執行緒數量 (預設為實體核心數)
./llama-cli -m model.gguf -t 8

# 以 AMD Ryzen 9 7950X (16 核心, 32 執行緒) 為例
-t 16  # 最佳實踐：使用實體核心數

# 避免超執行緒 (Hyperthreading，對矩陣運算而言較慢)
```

### BLAS 加速
```bash
# OpenBLAS (更快的矩陣運算)
make LLAMA_OPENBLAS=1

# BLAS 可提供 2-3 倍的速度提升
```

## GPU 卸載 (Offloading)

### 模型層卸載
```bash
# 將 35 層卸載到 GPU (混合模式)
./llama-cli -m model.gguf -ngl 35

# 卸載所有層
./llama-cli -m model.gguf -ngl 999

# 尋找最佳值：
# 從 -ngl 999 開始
# 如果發生記憶體不足 (OOM)，每次減少 5，直到能運作為止
```

### 記憶體使用量
```bash
# 檢查 VRAM 使用情況
nvidia-smi dmon

# 視需要減少上下文大小 (Context size)
./llama-cli -m model.gguf -c 2048  # 使用 2K 上下文而非 4K
```

## 批次處理 (Batch Processing)

```bash
# 增加批次大小以提升吞吐量
./llama-cli -m model.gguf -b 512  # 預設：512

# 實體批次 (GPU)
--ubatch 128  # 一次處理 128 個標記 (tokens)
```

## 上下文管理 (Context Management)

```bash
# 預設上下文 (512 標記)
-c 512

# 更長的上下文 (較慢，佔用更多記憶體)
-c 4096

# 超長上下文 (如果模型支援)
-c 32768
```

## 基準測試 (Benchmarks)

### CPU 效能 (Llama 2-7B Q4_K_M)

| 設定 | 速度 | 備註 |
|-------|-------|-------|
| Apple M3 Max | 50 tok/s | Metal 加速 |
| AMD 7950X (16c) | 35 tok/s | OpenBLAS |
| Intel i9-13900K | 30 tok/s | AVX2 |

### GPU 卸載 (RTX 4090)

| GPU 卸載層數 | 速度 | VRAM |
|------------|-------|------|
| 0 (僅 CPU) | 30 tok/s | 0 GB |
| 20 (混合模式) | 80 tok/s | 8 GB |
| 35 (全部卸載) | 120 tok/s | 12 GB |
