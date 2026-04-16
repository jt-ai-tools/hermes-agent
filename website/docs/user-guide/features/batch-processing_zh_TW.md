---
sidebar_position: 12
title: "批次處理"
description: "大規模生成代理軌跡 (Trajectories) —— 平行處理、檢查點與工具集分佈"
---

# 批次處理

批次處理讓您可以平行地針對數百或數千個提示詞執行 Hermes 代理程式，並生成結構化的軌跡 (Trajectory) 資料。這主要用於 **訓練資料生成** —— 產出帶有工具使用統計資料的 ShareGPT 格式軌跡，可用於微調 (Fine-tuning) 或評估。

## 概覽

批次執行器 (`batch_runner.py`) 處理 JSONL 格式的提示詞資料集，在具備工具存取權限的完整代理程式工作階段中執行每個提示詞。每個提示詞都有其獨立的隔離環境。輸出結果為結構化的軌跡資料，包含完整的對話歷史、工具呼叫統計以及推理覆蓋率指標。

## 快速入門

```bash
# 基本批次執行
python batch_runner.py \
    --dataset_file=data/prompts.jsonl \
    --batch_size=10 \
    --run_name=my_first_run \
    --model=anthropic/claude-sonnet-4.6 \
    --num_workers=4

# 恢復中斷的執行
python batch_runner.py \
    --dataset_file=data/prompts.jsonl \
    --batch_size=10 \
    --run_name=my_first_run \
    --resume

# 列出可用的工具集分佈
python batch_runner.py --list_distributions
```

## 資料集格式

輸入資料集是一個 JSONL 檔案（每行一個 JSON 物件）。每個條目必須包含 `prompt` 欄位：

```jsonl
{"prompt": "寫一個 Python 函數來尋找最長的迴文子字串"}
{"prompt": "使用 Flask 建立一個用於使用者驗證的 REST API 端點"}
{"prompt": "除錯此錯誤：TypeError: cannot unpack non-iterable NoneType object"}
```

條目可以選擇性包含：
- `image` 或 `docker_image`：用於此提示詞沙盒的容器映像檔（支援 Docker、Modal 和 Singularity 後端）
- `cwd`：該任務終端機工作階段的工作目錄覆蓋設定

## 配置選項

| 參數 | 預設值 | 描述 |
|-----------|---------|-------------|
| `--dataset_file` | (必填) | JSONL 資料集路徑 |
| `--batch_size` | (必填) | 每個批次的提示詞數量 |
| `--run_name` | (必填) | 此執行的名稱（用於輸出目錄和檢查點） |
| `--distribution` | `"default"` | 用於取樣的工具集分佈 |
| `--model` | `claude-sonnet-4.6` | 要使用的模型 |
| `--base_url` | `https://openrouter.ai/api/v1` | API 基礎 URL |
| `--api_key` | (環境變數) | 模型的 API 金鑰 |
| `--max_turns` | `10` | 每個提示詞的最大工具呼叫迭代次數 |
| `--num_workers` | `4` | 平行工作程序數量 |
| `--resume` | `false` | 從檢查點恢復 |
| `--verbose` | `false` | 啟用詳細日誌 |
| `--max_samples` | 全部 | 僅處理資料集的前 N 個樣本 |
| `--max_tokens` | 模型預設值 | 每個模型回應的最大 Token 數 |

### 提供者路由 (OpenRouter)

| 參數 | 描述 |
|-----------|-------------|
| `--providers_allowed` | 以逗號分隔的允許提供者（例如 `"anthropic,openai"`） |
| `--providers_ignored` | 以逗號分隔的忽略提供者（例如 `"together,deepinfra"`） |
| `--providers_order` | 以逗號分隔的偏好提供者順序 |
| `--provider_sort` | 按 `"price"` (價格)、`"throughput"` (吞吐量) 或 `"latency"` (延遲) 排序 |

### 推理控制 (Reasoning Control)

| 參數 | 描述 |
|-----------|-------------|
| `--reasoning_effort` | 努力程度：`none` (無)、`minimal` (極小)、`low` (低)、`medium` (中)、`high` (高)、`xhigh` (極高) |
| `--reasoning_disabled` | 完全禁用推理/思考 Token |

### 進階選項

| 參數 | 描述 |
|-----------|-------------|
| `--ephemeral_system_prompt` | 執行期間使用的系統提示詞，但 **不會** 儲存到軌跡中 |
| `--log_prefix_chars` | 日誌預覽中顯示的字元數（預設：100） |
| `--prefill_messages_file` | 用於 few-shot 引導的預填訊息 JSON 檔案路徑 |

## 工具集分佈 (Toolset Distributions)

每個提示詞都會從 **分佈** 中隨機取樣一組工具集。這確保了訓練資料涵蓋多樣化的工具組合。使用 `--list_distributions` 查看所有可用的分佈。

在目前的實作中，分佈為 **每個獨立的工具集** 分配機率。取樣器會獨立決定每個工具集是否啟用，並保證至少有一個工具集是啟用的。這與手動編寫的預設組合表不同。

## 輸出格式

所有輸出都存放在 `data/<run_name>/`：

```text
data/my_run/
├── trajectories.jsonl    # 合併後的最終輸出（合併所有批次）
├── batch_0.jsonl         # 各別批次的結果
├── batch_1.jsonl
├── ...
├── checkpoint.json       # 恢復檢查點
└── statistics.json       # 彙總的工具使用統計
```

### 軌跡格式 (Trajectory Format)

`trajectories.jsonl` 中的每一行都是一個 JSON 物件：

```json
{
  "prompt_index": 42,
  "conversations": [
    {"from": "human", "value": "寫一個函數..."},
    {"from": "gpt", "value": "我將建立該函數...",
     "tool_calls": [...]},
    {"from": "tool", "value": "..."},
    {"from": "gpt", "value": "這是完成後的函數..."}
  ],
  "metadata": {
    "batch_num": 2,
    "timestamp": "2026-01-15T10:30:00",
    "model": "anthropic/claude-sonnet-4.6"
  },
  "completed": true,
  "partial": false,
  "api_calls": 3,
  "toolsets_used": ["terminal", "file"],
  "tool_stats": {
    "terminal": {"count": 2, "success": 2, "failure": 0},
    "read_file": {"count": 1, "success": 1, "failure": 0}
  },
  "tool_error_counts": {
    "terminal": 0,
    "read_file": 0
  }
}
```

`conversations` 欄位使用類似 ShareGPT 的格式，包含 `from` 和 `value` 欄位。工具統計資料經過標準化，包含所有可能的工具（預設值為零），以確保與 HuggingFace 資料集的結構一致。

## 檢查點機制 (Checkpointing)

批次執行器具有強大的檢查點機制以實現容錯：

- **檢查點檔案**：在每個批次完成後儲存，記錄已完成的提示詞索引。
- **基於內容的恢復**：使用 `--resume` 時，執行器會掃描現有的批次檔案，並透過提示詞的 **實際文字內容**（而不僅僅是索引）匹配已完成的提示詞，即使資料集順序發生變化也能正確恢復。
- **失敗的提示詞**：僅將成功完成的提示詞標記為已完成 —— 失敗的提示詞將在恢復執行時重試。
- **批次合併**：完成後，所有批次檔案（包括來自先前執行的檔案）都會合併到單個 `trajectories.jsonl` 中。

### 恢復 (Resume) 的運作方式

1. 掃描所有 `batch_*.jsonl` 檔案，尋找已完成的提示詞（透過內容匹配）。
2. 過濾資料集，排除已完成的提示詞。
3. 對剩餘提示詞重新分批。
4. 僅處理剩餘提示詞。
5. 將所有批次檔案（舊的 + 新的）合併到最終輸出中。

## 品質過濾 (Quality Filtering)

批次執行器會自動套用品質過濾：

- **無推理過濾**：捨棄所有助理輪次中皆不含推理內容（無 `<REASONING_SCRATCHPAD>` 或原生思考 Token）的樣本。
- **損壞條目過濾**：在最終合併期間，過濾掉具有幻覺工具名稱（不在有效工具清單中）的條目。
- **推理統計**：追蹤整個執行過程中帶有/不帶有推理輪次的百分比。

## 統計資料

完成後，執行器會列印詳盡的統計資料：

- **工具使用情況**：每個工具的呼叫次數、成功/失敗率。
- **推理覆蓋率**：包含推理的助理輪次百分比。
- **捨棄樣本數**：因缺乏推理而被過濾掉的樣本數量。
- **持續時間**：總處理時間。

統計資料也會儲存至 `statistics.json` 以供程式化分析。

## 使用案例

### 訓練資料生成

為微調生成多樣化的工具使用軌跡：

```bash
python batch_runner.py \
    --dataset_file=data/coding_prompts.jsonl \
    --batch_size=20 \
    --run_name=coding_v1 \
    --model=anthropic/claude-sonnet-4.6 \
    --num_workers=8 \
    --distribution=default \
    --max_turns=15
```

### 模型評估

評估模型在標準化提示詞中對工具的使用能力：

```bash
python batch_runner.py \
    --dataset_file=data/eval_suite.jsonl \
    --batch_size=10 \
    --run_name=eval_gpt4 \
    --model=openai/gpt-4o \
    --num_workers=4 \
    --max_turns=10
```

### 每個提示詞獨立的容器映像檔

對於需要特定環境的基準測試，每個提示詞可以指定自己的容器映像檔：

```jsonl
{"prompt": "安裝 numpy 並計算 3x3 矩陣的特徵值", "image": "python:3.11-slim"}
{"prompt": "編譯並執行此 Rust 程式", "image": "rust:1.75"}
{"prompt": "設置 Node.js Express 伺服器", "image": "node:20-alpine", "cwd": "/app"}
```

批次執行器在執行每個提示詞之前會驗證 Docker 映像檔是否可存取。
