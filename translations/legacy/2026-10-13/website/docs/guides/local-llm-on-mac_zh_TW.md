---
sidebar_position: 2
title: "在 Mac 上執行本地 LLM"
description: "使用 llama.cpp 或 MLX 在 macOS 上設置相容於 OpenAI 的本地 LLM 伺服器，包含模型選擇、記憶體優化以及在 Apple Silicon 上的真實基準測試"
---

# 在 Mac 上執行本地 LLM

本指南將引導你如何在 macOS 上執行具備相容於 OpenAI API 的本地 LLM 伺服器。你將獲得完整的隱私保護、零 API 成本，以及在 Apple Silicon 上令人驚豔的效能。

我們涵蓋了兩種後端：

| 後端 | 安裝方式 | 優勢 | 格式 |
|---------|---------|---------|--------|
| **llama.cpp** | `brew install llama.cpp` | 首字生成延遲 (TTFT) 最快，具備用於低記憶體需求的量化 KV 快取 | GGUF |
| **omlx** | [omlx.ai](https://omlx.ai) | 令牌 (Token) 生成速度最快，原生 Metal 優化 | MLX (safetensors) |

兩者都提供相容於 OpenAI 的 `/v1/chat/completions` 端點。Hermes 可以與其中任何一個搭配使用 —— 只需將其指向 `http://localhost:8080` 或 `http://localhost:8000`。

:::info 僅限 Apple Silicon
本指南針對配備 Apple Silicon（M1 及更高版本）的 Mac。Intel Mac 雖然可以使用 llama.cpp，但沒有 GPU 加速 —— 預計效能會顯著降低。
:::

---

## 選擇模型

對於初學者，我們推薦使用 **Qwen3.5-9B** —— 這是一個強大的推理模型，透過量化可以舒適地運行在 8GB+ 的統一記憶體 (Unified memory) 中。

| 變體 | 磁碟佔用 | 所需 RAM (128K 上下文) | 後端 |
|---------|-------------|---------------------------|---------|
| Qwen3.5-9B-Q4_K_M (GGUF) | 5.3 GB | ~10 GB (含量化 KV 快取) | llama.cpp |
| Qwen3.5-9B-mlx-lm-mxfp4 (MLX) | ~5 GB | ~12 GB | omlx |

**記憶體估算法則：** 模型大小 + KV 快取。一個 9B Q4 模型大約 5 GB。在 128K 上下文下，使用 Q4 量化的 KV 快取會增加約 4-5 GB。若使用預設的 (f16) KV 快取，則會激增至 ~16 GB。llama.cpp 中的量化 KV 快取參數是記憶體受限系統的關鍵技巧。

對於更大的模型（27B、35B），你將需要 32 GB+ 的統一記憶體。9B 模型是 8-16 GB 機器最理想的選擇。

---

## 選項 A：llama.cpp

llama.cpp 是最通用的本地 LLM 執行環境。在 macOS 上，它開箱即用地使用 Metal 進行 GPU 加速。

### 安裝

```bash
brew install llama.cpp
```

這將讓你在全域環境中使用 `llama-server` 指令。

### 下載模型

你需要 GGUF 格式的模型。最簡單的來源是透過 `huggingface-cli` 從 Hugging Face 取得：

```bash
brew install huggingface-cli
```

然後下載：

```bash
huggingface-cli download unsloth/Qwen3.5-9B-GGUF Qwen3.5-9B-Q4_K_M.gguf --local-dir ~/models
```

:::tip 受限模型 (Gated models)
Hugging Face 上的某些模型需要驗證。如果你遇到 401 或 404 錯誤，請先執行 `huggingface-cli login`。
:::

### 啟動伺服器

```bash
llama-server -m ~/models/Qwen3.5-9B-Q4_K_M.gguf \
  -ngl 99 \
  -c 131072 \
  -np 1 \
  -fa on \
  --cache-type-k q4_0 \
  --cache-type-v q4_0 \
  --host 0.0.0.0
```

以下是每個參數的作用：

| 參數 | 用途 |
|------|---------|
| `-ngl 99` | 將所有層卸載至 GPU (Metal)。使用較大的數字以確保沒有任何層留在 CPU 上。 |
| `-c 131072` | 上下文視窗大小 (128K 令牌)。如果記憶體不足，請降低此值。 |
| `-np 1` | 平行插槽 (Parallel slots) 數量。單人使用請保持為 1 —— 多個插槽會瓜分你的記憶體預算。 |
| `-fa on` | Flash attention。減少記憶體使用並加速長上下文推理。 |
| `--cache-type-k q4_0` | 將 Key 快取量化為 4-bit。**這是節省記憶體的關鍵。** |
| `--cache-type-v q4_0` | 將 Value 快取量化為 4-bit。配合上述參數，相較於 f16，可減少約 75% 的 KV 快取記憶體佔用。 |
| `--host 0.0.0.0` | 監聽所有介面。如果你不需要網路存取，請使用 `127.0.0.1`。 |

當你看到以下訊息時，表示伺服器已準備就緒：

```
main: server is listening on http://0.0.0.0:8080
srv  update_slots: all slots are idle
```

### 針對記憶體受限系統的優化

`--cache-type-k q4_0 --cache-type-v q4_0` 參數是記憶體有限系統中最重要的優化。以下是 128K 上下文下的影響：

| KV 快取類型 | KV 快取記憶體 (128K ctx, 9B 模型) |
|---------------|--------------------------------------|
| f16 (預設) | ~16 GB |
| q8_0 | ~8 GB |
| **q4_0** | **~4 GB** |

在 8 GB 的 Mac 上，請使用 `q4_0` KV 快取，並將上下文減少至 `-c 32768` (32K)。在 16 GB 上，你可以舒適地執行 128K 上下文。在 32 GB+ 上，你可以執行更大的模型或多個平行插槽。

如果你仍然遇到記憶體不足的問題，請先降低上下文大小 (`-c`)，然後嘗試更低階的量化（例如使用 Q3_K_M 而非 Q4_K_M）。

### 測試

```bash
curl -s http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen3.5-9B-Q4_K_M.gguf",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 50
  }' | jq .choices[0].message.content
```

### 獲取模型名稱

如果你忘記了模型名稱，可以查詢 models 端點：

```bash
curl -s http://localhost:8080/v1/models | jq '.data[].id'
```

---

## 選項 B：透過 omlx 使用 MLX

[omlx](https://omlx.ai) 是一個 macOS 原生應用程式，用於管理和提供 MLX 模型服務。MLX 是 Apple 專屬的機器學習框架，專為 Apple Silicon 的統一記憶體架構而優化。

### 安裝

從 [omlx.ai](https://omlx.ai) 下載並安裝。它提供了一個用於模型管理的圖形介面和內建伺服器。

### 下載模型

使用 omlx 應用程式瀏覽並下載模型。搜尋 `Qwen3.5-9B-mlx-lm-mxfp4` 並下載。模型儲存在本地（通常在 `~/.omlx/models/`）。

### 啟動伺服器

omlx 預設在 `http://127.0.0.1:8000` 提供服務。從應用程式介面啟動服務，或使用 CLI（如果有）。

### 測試

```bash
curl -s http://127.0.0.1:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen3.5-9B-mlx-lm-mxfp4",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 50
  }' | jq .choices[0].message.content
```

### 列出可用模型

omlx 可以同時提供多個模型服務：

```bash
curl -s http://127.0.0.1:8000/v1/models | jq '.data[].id'
```

---

## 基準測試：llama.cpp vs MLX

兩個後端均在同一台機器（Apple M5 Max, 128 GB 統一記憶體）上測試，執行相同的模型 (Qwen3.5-9B) 並採用相當的量化水平（GGUF 為 Q4_K_M，MLX 為 mxfp4）。使用五個不同的提示詞，各執行三次，後端依序測試以避免資源競爭。

### 結果

| 指標 | llama.cpp (Q4_K_M) | MLX (mxfp4) | 勝出者 |
|--------|-------------------|-------------|--------|
| **TTFT (平均)** | **67 ms** | 289 ms | llama.cpp (快 4.3 倍) |
| **TTFT (p50)** | **66 ms** | 286 ms | llama.cpp (快 4.3 倍) |
| **生成速度 (平均)** | 70 tok/s | **96 tok/s** | MLX (快 37%) |
| **生成速度 (p50)** | 70 tok/s | **96 tok/s** | MLX (快 37%) |
| **總耗時 (512 令牌)** | 7.3s | **5.5s** | MLX (快 25%) |

### 這代表什麼

- **llama.cpp** 在提示詞處理方面表現卓越 —— 其 flash attention + 量化 KV 快取管線讓你在約 66ms 內獲得第一個令牌。如果你正在構建強調即時回應的互動式應用程式（聊天機器人、自動完成），這是一個顯著的優勢。

- **MLX** 在開始後生成令牌的速度快約 37%。對於批次任務、長篇內容生成或任何總體完成時間比初始延遲更重要的任務，MLX 能更快完成。

- 兩個後端都 **極其穩定** —— 多次執行的變異極小。你可以信賴這些數據。

### 你該選擇哪一個？

| 使用案例 | 推薦建議 |
|----------|---------------|
| 互動式聊天、低延遲工具 | llama.cpp |
| 長篇內容生成、批次處理 | MLX (omlx) |
| 記憶體受限 (8-16 GB) | llama.cpp (量化 KV 快取無可匹敵) |
| 同時提供多個模型服務 | omlx (內建多模型支援) |
| 最大相容性 (亦支援 Linux) | llama.cpp |

---

## 連接至 Hermes

當你的本地伺服器啟動後：

```bash
hermes model
```

選擇 **Custom endpoint** 並按照提示操作。它會要求輸入 Base URL 和模型名稱 —— 請使用你所設置的後端對應值。

---

## 逾時設置

Hermes 會自動偵測本地端點 (localhost, LAN IP) 並放寬其串流逾時限制。大多數情況下無需配置。

如果你仍然遇到逾時錯誤（例如在慢速硬體上處理極大的上下文），你可以手動覆寫串流讀取逾時：

```bash
# 在你的 .env 檔案中 —— 將預設的 120s 提高到 30 分鐘
HERMES_STREAM_READ_TIMEOUT=1800
```

| 逾時項目 | 預設值 | 本地自動調整 | 環境變數覆寫 |
|---------|---------|----------------------|------------------|
| 串流讀取 (通訊端層級) | 120s | 提高至 1800s | `HERMES_STREAM_READ_TIMEOUT` |
| 停滯串流偵測 | 180s | 完全停用 | `HERMES_STREAM_STALE_TIMEOUT` |
| API 呼叫 (非串流) | 1800s | 無需更改 | `HERMES_API_TIMEOUT` |

串流讀取逾時是最可能引起問題的一項 —— 它是接收下一個數據塊的通訊端層級截止期限。在處理巨大上下文的 Prefill 階段，本地模型可能會在處理提示詞時數分鐘不產生任何輸出。自動偵測功能會透明地處理這種情況。
