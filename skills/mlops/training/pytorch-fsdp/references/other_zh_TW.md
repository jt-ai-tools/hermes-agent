# Pytorch-Fsdp - 其他 (Other)

**頁數：** 15

---

## 分散式資料平行 (Distributed Data Parallel)#
... (已翻譯章節：範例、內部設計、實作) ...

## PyTorch 文件#
... (已翻譯章節：穩定/不穩定 API 說明) ...

## 通用加入上下文管理器 (Generic Join Context Manager)#
... (已翻譯章節：Join, Joinable, JoinHook API 說明) ...

## 實驗性物件導向分散式 API#
... (已翻譯章節：ProcessGroup, allgather, allreduce 等原語說明) ...

## torch.distributed.fsdp.fully_shard (FSDP2)#
PyTorch FSDP2 (fully_shard) 提供了一種全分片資料平行實作，針對高性能 eager 模式，並使用逐參數分片以提高易用性。

---

## 分散式通訊套件 - torch.distributed#
... (已翻譯章節：後端選擇、初始化、TCP/文件系統/環境變數初始化) ...

## DistributedDataParallel (DDP)#
在模組級別實作分散式資料平行，透過同步各個模型副本的梯度來提供資料平行。

## 分散式優化器 (Distributed Optimizers)#
揭露了 DistributedOptimizer 和 ZeroRedundancyOptimizer。ZeRO 優化器可在 rank 之間分片優化器狀態以減少記憶體佔用。

## 管道平行 (Pipeline Parallelism)#
將模型執行劃分為多個階段，允許不同部分在不同設備上並行處理微批次。

## 張量平行 (Tensor Parallelism)#
基於 DTensor 構建，提供列式 (Colwise)、行式 (Rowwise) 和序列 (Sequence) 平行風格。

---

## DDP 通訊 Hook (DDP Communication Hooks)#
DDP 通訊 Hook 是一個通用介面，用於控制如何跨工作程序通訊梯度。支援內建 Hook 如：
- `allreduce_hook`：基本的 allreduce。
- `fp16_compress_hook` / `bf16_compress_hook`：梯度壓縮。
- `powerSGD_hook`：使用 PowerSGD 演算法的高級梯度壓縮。

## 分散式檢查點 (Distributed Checkpoint) - torch.distributed.checkpoint#
分散式檢查點 (DCP) 支援從多個 rank 並行加載和儲存模型。它處理加載時的重新分片，支援從不同叢集拓撲加載。
- `save_state_dict`：儲存分散式模型。
- `load_state_dict`：加載分散式模型。
- 支援非同步儲存 (`async_save`)。

## 分散式張量 (Distributed Tensor) - torch.distributed.tensor#
PyTorch DTensor 提供張量分片原語，透明處理分散式邏輯。
- `DeviceMesh`：描述設備拓撲。
- `Placement`：Shard（分片）、Replicate（複製）、Partial（部分和）。
- `distribute_tensor` / `from_local`：建立分散式張量。

## FullyShardedDataParallel (FSDP1)#
FSDP1 是將模型參數跨資料平行工作程序進行分片的包裝器，靈感來自 ZeRO Stage 3。
- 支援參數分片、梯度分片和優化器狀態分片。
- 提供 CPU 卸載 (CPU Offloading) 和混合精度 (Mixed Precision) 支援。

## Torch Distributed Elastic#
使分散式 PyTorch 具備容錯性和彈性。
