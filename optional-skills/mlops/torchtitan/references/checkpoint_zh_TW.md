# TorchTitan 中的檢查點 (Checkpointing)

TorchTitan 使用 PyTorch 分散式檢查點 (Distributed Checkpoint, DCP) 來實現具備容錯能力且可互操作的檢查點機制。

## 基礎配置

```toml
[checkpoint]
enable = true
folder = "checkpoint"
interval = 500
```

## 僅儲存模型 (更小的檢查點)

排除優化器狀態與訓練中繼資料 (metadata)：

```toml
[checkpoint]
enable = true
last_save_model_only = true
export_dtype = "bfloat16"  # 選用：以較低精度匯出
```

## 載入時排除特定鍵 (Keys)

用於修改設定時的部分檢查點載入：

```toml
[checkpoint]
enable = true
exclude_from_loading = ["data_loader", "lr_scheduler"]
```

CLI 等效用法：
```bash
--checkpoint.exclude_from_loading data_loader,lr_scheduler
```

## 建立種子檢查點 (Seed Checkpoints)

管線平行 (Pipeline Parallelism) 需要此項以確保初始化的一致性：

```bash
NGPU=1 CONFIG_FILE=<配置路徑> ./run_train.sh \
  --checkpoint.enable \
  --checkpoint.create_seed_checkpoint \
  --parallelism.data_parallel_replicate_degree 1 \
  --parallelism.data_parallel_shard_degree 1 \
  --parallelism.tensor_parallel_degree 1 \
  --parallelism.pipeline_parallel_degree 1 \
  --parallelism.context_parallel_degree 1 \
  --parallelism.expert_parallel_degree 1
```

這會在單一 CPU 上進行初始化，以確保在任何 GPU 數量下都能實現可重現的初始化。

## 非同步檢查點 (Async Checkpointing)

透過非同步寫入減少檢查點開銷：

```toml
[checkpoint]
enable = true
async_mode = "async"  # 選項："disabled", "async", "async_with_pinned_mem"
```

## HuggingFace 轉換

### 在訓練期間

直接以 HuggingFace 格式儲存：

```toml
[checkpoint]
last_save_in_hf = true
last_save_model_only = true
```

從 HuggingFace 載入：

```toml
[checkpoint]
initial_load_in_hf = true

[model]
hf_assets_path = "./path/to/hf/checkpoint"
```

### 離線轉換

在不執行訓練的情況下進行轉換：

```bash
# HuggingFace -> TorchTitan
python ./scripts/checkpoint_conversion/convert_from_hf.py \
  <來源目錄> <輸出目錄> \
  --model_name llama3 \
  --model_flavor 8B

# TorchTitan -> HuggingFace
python ./scripts/checkpoint_conversion/convert_to_hf.py \
  <來源目錄> <輸出目錄> \
  --hf_assets_path ./assets/hf/Llama3.1-8B \
  --model_name llama3 \
  --model_flavor 8B
```

### 範例

```bash
python ./scripts/convert_from_hf.py \
  ~/.cache/huggingface/hub/models--meta-llama--Meta-Llama-3-8B/snapshots/8cde5ca8380496c9a6cc7ef3a8b46a0372a1d920/ \
  ./initial_load_path/ \
  --model_name llama3 \
  --model_flavor 8B
```

## 轉換為單一 .pt 檔案

將 DCP 分片檢查點轉換為單一 PyTorch 檔案：

```bash
python -m torch.distributed.checkpoint.format_utils \
  dcp_to_torch \
  torchtitan/outputs/checkpoint/step-1000 \
  checkpoint.pt
```

## 檢查點結構

DCP 會儲存分片後的檢查點，這些檢查點可以針對不同的平行配置進行重新分片：

```
checkpoint/
├── step-500/
│   ├── .metadata
│   ├── __0_0.distcp
│   ├── __0_1.distcp
│   └── ...
└── step-1000/
    └── ...
```

## 恢復訓練 (Resume Training)

訓練會自動從配置目錄中的最新檢查點恢復。若要從特定步數恢復：

```toml
[checkpoint]
load_step = 500  # 從第 500 步恢復
```

## 與 TorchTune 的互通性

設定 `last_save_model_only = true` 所儲存的檢查點可以直接載入到 [torchtune](https://github.com/pytorch/torchtune) 進行微調。

## 完整配置範例

```toml
[checkpoint]
enable = true
folder = "checkpoint"
interval = 500
load_step = -1  # -1 = 最新，或指定步數
last_save_model_only = true
export_dtype = "bfloat16"
async_mode = "async"
exclude_from_loading = []
last_save_in_hf = false
initial_load_in_hf = false
create_seed_checkpoint = false
```

## 最佳實踐

1. **大型模型**：使用 `async_mode = "async"`，讓檢查點儲存與訓練重疊進行。
2. **微調匯出**：啟用 `last_save_model_only` 與 `export_dtype = "bfloat16"` 以獲得更小的檔案。
3. **管線平行**：務必先建立種子檢查點。
4. **除錯 (Debugging)**：開發期間頻繁儲存檢查點，生產環境則減少頻率。
5. **HF 互通性**：針對離線轉換使用轉換腳本，針對訓練流程則使用直接儲存/載入。
