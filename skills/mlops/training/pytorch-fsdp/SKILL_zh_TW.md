---
name: pytorch-fsdp
description: 關於 PyTorch FSDP 全分片資料平行訓練的專家指導 - 參數分片、混合精度、CPU 卸載、FSDP2
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [torch>=2.0, transformers]
metadata:
  hermes:
    tags: [分散式訓練, PyTorch, FSDP, 資料平行, 分片, 混合精度, CPU 卸載, FSDP2, 大規模訓練]

---

# Pytorch-Fsdp 技能

提供 pytorch-fsdp 開發的全面協助，內容由官方文件生成。

## 何時使用此技能

當發生以下情況時應觸發此技能：
- 使用 pytorch-fsdp 工作時
- 詢問 pytorch-fsdp 功能或 API 時
- 實作 pytorch-fsdp 解決方案時
- 除錯 pytorch-fsdp 程式碼時
- 學習 pytorch-fsdp 最佳實踐時

## 快速參考

### 常見模式

**模式 1：** 通用加入上下文管理器 (Generic Join Context Manager) # 建立於：2025年6月6日 | 最後更新：2025年6月6日。通用加入上下文管理器便於在不均勻輸入上進行分散式訓練。本頁面概述了相關類別的 API：Join、Joinable 和 JoinHook。教學請參閱《使用加入上下文管理器進行不均勻輸入的分散式訓練》。`class torch.distributed.algorithms.Join(joinables, enable=True, throw_on_early_termination=False, **kwargs)`。此類別定義了通用加入上下文管理器，它允許在程序加入後調用自定義 hook。這些 hook 應影子 (shadow) 非加入程序的集合通訊，以防止掛起和報錯，並確保演算法正確性。有關 hook 定義的詳細資訊，請參閱 JoinHook。警告：上下文管理器要求每個參與的 Joinable 在其自身的每次迭代集合通訊之前調用方法 `notify_join_context()`，以確保正確性。警告：上下文管理器要求 JoinHook 物件中的所有 process_group 屬性都相同。如果有多個 JoinHook 物件，則使用第一個物件的設備。程序群組和設備資訊用於檢查未加入的程序，以及在啟用 throw_on_early_termination 時通知程序拋出異常（兩者都使用 all-reduce）。參數：joinables (List[Joinable]) – 參與的 Joinable 列表；其 hook 按給定順序迭代。enable (bool) – 啟用不均勻輸入檢測的標誌；設置為 False 會停用上下文管理器的功能，僅當使用者知道輸入不會不均勻時才應設置（預設值：True）。throw_on_early_termination (bool) – 控制是否在檢測到不均勻輸入時拋出異常的標誌（預設值：False）。範例：... [程式碼略，與原文相同] ... 靜態方法 `notify_join_context(joinable)`：通知加入上下文管理器調用程序尚未加入。然後，如果 throw_on_early_termination=True，則檢查是否檢測到不均勻輸入（即是否已有一個程序加入），如果是則拋出異常。此方法應從 Joinable 物件在其每次迭代集合通訊之前調用。例如，這應在 DistributedDataParallel 的正向傳遞開始時調用。只有傳遞到上下文管理器中的第一個 Joinable 物件會執行此方法中的集合通訊，對於其他物件，此方法是無效的。參數：joinable (Joinable) – 調用此方法的 Joinable 物件。返回：用於 all-reduce 的非同步工作句柄，旨在通知上下文管理器程序尚未加入（如果 joinable 是傳遞到上下文管理器中的第一個）；否則為 None。類別 `torch.distributed.algorithms.Joinable`：這為可加入類別定義了一個抽象基類。可加入類別（繼承自 Joinable）應實作 `join_hook()`（返回 JoinHook 實例），以及分別返回設備和程序群組資訊的 `join_device` 和 `join_process_group`。抽象屬性 `join_device`: 返回執行加入上下文管理器所需集合通訊的設備。抽象方法 `join_hook(**kwargs)`：返回給定 Joinable 的 JoinHook 實例。參數：kwargs (dict) – 包含任何關鍵字參數的字典，用於在運行時修改加入 hook 的行為；所有共享相同加入上下文管理器的 Joinable 實例都會收到相同的 kwargs 值。返回類型：JoinHook。抽象屬性 `join_process_group`: 返回加入上下文管理器本身所需的集合通訊的程序群組。類別 `torch.distributed.algorithms.JoinHook`：這定義了一個加入 hook，它在加入上下文管理器中提供兩個入口點。入口點：主 hook（當存在未加入程序時被重複調用）和後置 hook（當所有程序都加入後被調用一次）。要為通用加入上下文管理器實作加入 hook，請定義一個繼承自 JoinHook 的類別，並根據需要重寫 `main_hook()` 和 `post_hook()`。`main_hook()`：當存在未加入程序時調用此 hook，以影子訓練迭代中的集合通訊。訓練迭代，即一次正向傳遞、反向傳遞和優化器步驟。`post_hook(is_last_joiner)`：所有程序加入後調用 hook。它被傳遞一個額外的布林參數 is_last_joiner，指示該 rank 是否為最後加入的 rank 之一。參數：is_last_joiner (bool) – 如果該 rank 是最後加入的 rank 之一則為 True；否則為 False。

```
Join
```

**模式 2：** 分散式通訊套件 - torch.distributed # 建立於：2017年7月12日 | 最後更新：2025年9月4日。注意：請參閱 PyTorch 分散式概述，以簡要瞭解與分散式訓練相關的所有功能。後端：torch.distributed 支援四個內建後端，各具不同能力。下表顯示了每個後端在 CPU 或 GPU 上可使用的功能。對於 NCCL，GPU 指的是 CUDA GPU，而對於 XCCL 則是 XPU GPU。MPI 僅在構建 PyTorch 的實作支援 CUDA 時才支援 CUDA。後端：gloo, mpi, nccl, xccl。設備：CPU, GPU。功能：send, recv, broadcast, all_reduce, reduce, all_gather, gather, scatter, reduce_scatter, all_to_all, barrier。PyTorch 附帶的後端：PyTorch 分散式套件支援 Linux（穩定）、MacOS（穩定）和 Windows（原型）。預設情況下，Linux 版本中構建並包含了 Gloo 和 NCCL 後端（NCCL 僅在構建 CUDA 時包含）。MPI 是可選後端，僅當您從原始碼構建 PyTorch 時才能包含。（例如，在安裝了 MPI 的主機上構建 PyTorch。）注意：從 PyTorch v1.8 開始，Windows 支援除 NCCL 以外的所有集合通訊後端。如果 `init_process_group()` 的 `init_method` 參數指向一個文件，它必須符合以下架構：本地文件系統 `init_method="file:///d:/tmp/some_file"`，共享文件系統 `init_method="file://////{machine_name}/{share_folder_name}/some_file"`。與 Linux 平台相同，您可以透過設置環境變數 MASTER_ADDR 和 MASTER_PORT 來啟用 TcpStore。應該使用哪個後端？：過去，我們經常被問到：「我應該使用哪個後端？」。經驗法則：對於 CUDA GPU 的分散式訓練，使用 NCCL 後端。對於 XPU GPU 的分散式訓練，使用 XCCL 後端。對於 CPU 的分散式訓練，使用 Gloo 後端。GPU 主機配合 InfiniBand 互連：使用 NCCL，因為它是目前唯一支援 InfiniBand 和 GPUDirect 的後端。GPU 主機配合乙太網路互連：使用 NCCL，因為它目前提供最佳的分散式 GPU 訓練性能。如果遇到 NCCL 的任何問題，請使用 Gloo 作為備選方案。（注意：對於 GPU，Gloo 目前比 NCCL 慢。）CPU 主機配合 InfiniBand 互連：如果您的 InfiniBand 已啟用 IP over IB，請使用 Gloo，否則使用 MPI。我們計劃在未來的版本中為 Gloo 添加 InfiniBand 支援。CPU 主機配合乙太網路互連：使用 Gloo，除非您有特定理由使用 MPI。預設情況下，NCCL 和 Gloo 後端都會嘗試尋找要使用的正確網路接口。如果自動偵測的接口不正確，您可以使用環境變數重寫：`NCCL_SOCKET_IFNAME`, `GLOO_SOCKET_IFNAME`。除錯：如果 NCCL 失敗，您可以設置 `NCCL_DEBUG=INFO` 以列印明確的警告訊息以及基本的 NCCL 初始化資訊。效能調優：NCCL 會根據其拓撲偵測執行自動調優。在某些基於 socket 的系統上，使用者仍可嘗試調整 `NCCL_SOCKET_NTHREADS` 和 `NCCL_NSOCKS_PERTHREAD` 以增加網路頻寬。基礎知識：torch.distributed 套件為跨多個計算節點運行的多程序平行提供支援。`torch.nn.parallel.DistributedDataParallel()` 類別構建在此功能之上，為任何 PyTorch 模型提供同步分散式訓練包裝器。這與 `torch.multiprocessing` 和 `torch.nn.DataParallel()` 提供的平行方式不同，因為它支援多台網路連接的機器，且使用者必須明確地為每個程序啟動主訓練指令碼的單獨副本。

```
torch.distributed
```

**模式 3：** 初始化 # 套件需要在使用任何其他方法之前，透過 `torch.distributed.init_process_group()` 或 `torch.distributed.device_mesh.init_device_mesh()` 函數進行初始化。兩者都會阻塞直到所有程序都加入。警告：初始化不是執行緒安全的。程序群組的建立應從單個執行緒執行，以防止跨 rank 的 UUID 分配不一致，並防止初始化期間可能導致掛起的競爭。`torch.distributed.is_available()`: 如果分散式套件可用則返回 True。`torch.distributed.init_process_group(backend=None, init_method=None, timeout=None, world_size=-1, rank=-1, store=None, group_name='', pg_options=None, device_id=None)`：初始化預設的分散式程序群組。這也將初始化分散式套件。初始化程序群組主要有 2 種方式：明確指定 store、rank 和 world_size；或者指定 `init_method` (一個 URL 字串)，指示在何處/如何發現對等點。參數：backend (str 或 Backend) – 要使用的後端，如 mpi, gloo, nccl, ucc, xccl。從 2.6 開始，如果未提供 backend，c10d 將使用為 `device_id` 指定的設備類型註冊的後端。已知預設註冊為：nccl 用於 cuda，gloo 用於 cpu，xccl 用於 xpu。注意：要啟用 `backend == Backend.MPI`，PyTorch 需要在支援 MPI 的系統上從原始碼構建。注意：對多後端的支援是實驗性的。`torch.distributed.device_mesh.init_device_mesh(device_type, mesh_shape, *, mesh_dim_names=None, backend_override=None)`：基於參數初始化 DeviceMesh。這會建立一個具有 n 維陣列佈局的 DeviceMesh，其中 n 是 `mesh_shape` 的長度。注意：`init_device_mesh` 遵循 SPMD 程式設計模型。確保 `mesh_shape` 在所有 rank 上相同。`torch.distributed.is_initialized()`: 檢查預設程序群組是否已初始化。`torch.distributed.is_torchelastic_launched()`: 檢查此程序是否是由 torch.distributed.elastic 啟動的。`torch.distributed.get_default_backend_for_device(device)`: 返回給定設備的預設後端。目前支援三種初始化方法：TCP 初始化、共享文件系統初始化、環境變數初始化。`TORCH_GLOO_LAZY_INIT` - 按需建立連接，可大幅縮短非 all2all 操作的初始化時間。

```
torch.distributed.init_process_group()
```

**模式 4：** 範例：

```python
>>> from torch.distributed.device_mesh import init_device_mesh
>>>
>>> mesh_1d = init_device_mesh("cuda", mesh_shape=(8,))
>>> mesh_2d = init_device_mesh("cuda", mesh_shape=(2, 8), mesh_dim_names=("dp", "tp"))
```

**模式 5：** 群組 # 預設情況下，集合操作在預設群組（也稱為 world）上運行，並要求所有程序進入分散式函數調用。然而，某些工作負載可以從更細粒度的通訊中受益。這就是分散式群組發揮作用的地方。`new_group()` 函數可用於建立新群組，包含所有程序的任意子集。它返回一個不透明的群組句柄，可作為群組參數傳遞給所有集合操作。`torch.distributed.new_group(ranks=None, timeout=None, backend=None, pg_options=None, use_local_synchronization=False, group_desc=None, device_id=None)`：建立一個新的分散式群組。此函數要求主群組中的所有程序都進入此函數，即使它們不打算成為該群組的成員。此外，所有程序中建立群組的順序應相同。警告：安全併發使用：在使用 NCCL 後端的多個程序群組時，使用者必須確保各 rank 之間集合操作的執行順序在全域是一致的。如果程序內的多個執行緒發起集合操作，則需要明確的同步以確保順序一致。使用 `torch.distributed` 通訊 API 的非同步變體時，會返回一個 work 物件，通訊核心會被放入單獨的 CUDA 流中，從而允許通訊和計算重疊。參數：ranks (list[int]) – 群組成員的 rank 列表。如果為 None，則設置為所有 rank。預設為 None。`torch.distributed.get_group_rank(group, global_rank)`: 將全域 rank 轉換為群組 rank。`torch.distributed.get_global_rank(group, group_rank)`: 將群組 rank 轉換為全域 rank。`torch.distributed.get_process_group_ranks(group)`: 獲取與群組關聯的所有 rank。

```
new_group()
```

**模式 6：** 警告：安全併發使用：在使用 NCCL 後端的多個程序群組時，使用者必須確保各 rank 之間集合操作的執行順序在全域是一致的。如果程序內的多個執行緒發起集合操作，則需要明確的同步以確保順序一致。使用 `torch.distributed` 通訊 API 的非同步變體時，會返回一個 work 物件，通訊核心會被放入單獨的 CUDA 流中，從而允許通訊和計算重疊。一旦在一個程序群組上發起了一個或多個非同步操作，在使用另一個程序群組之前，必須透過調用 `work.wait()` 與其他 cuda 流同步。詳情請參閱《同時使用多個 NCCL 通訊器》。

```
NCCL
```

**模式 7：** 注意：如果您將 DistributedDataParallel 與分散式 RPC 框架結合使用，則應始終使用 `torch.distributed.autograd.backward()` 來計算梯度，並使用 `torch.distributed.optim.DistributedOptimizer` 來優化參數。範例：... [程式碼略] ... 使用 `dist_autograd.context()` 作為 context_id，`dist_autograd.backward(context_id, [loss])`，以及 `dist_optim.step(context_id)`。

```
torch.distributed.autograd.backward()
```

**模式 8：** static_graph (bool) – 當設置為 True 時，DDP 知道訓練圖是靜態的。靜態圖意味著：1) 在整個訓練循環中，已使用和未使用的參數集合不會改變；在這種情況下，使用者是否設置 `find_unused_parameters = True` 無關緊要。2) 訓練圖的方式在整個訓練循環中不會改變（意味著沒有取決於迭代的控制流）。當 `static_graph` 設置為 True 時，DDP 將支援過去無法支援的情況：1) 重入反向 (Reentrant backwards)。2) 多次激活檢查點 (Activation checkpointing)。3) 模型有未使用參數時的激活檢查點。4) 在正向函數之外有模型參數。5) 當有未使用參數時可能提高效能，因為 DDP 不會在每次迭代中搜尋圖以檢測未使用參數。要檢查是否可以設置 `static_graph` 為 True，一種方法是檢查之前模型訓練結束時的 ddp 記錄數據，如果 `ddp_logging_data.get("can_set_static_graph") == True`，則通常也可以設置。範例：... [程式碼略] ...

```
True
```

## 參考文件

此技能在 `references/` 中包含詳細文件：

- **other.md** - 其他文件

當需要詳細資訊時，使用 `view` 讀取特定的參考文件。

## 如何使用此技能

### 針對初學者
從 `getting_started` 或 `tutorials` 參考文件開始，瞭解基礎概念。

### 針對特定功能
使用適當的類別參考文件（api、guides 等）獲取詳細資訊。

### 針對程式碼範例
上方的快速參考章節包含從官方文件提取的常見模式。

## 資源

### references/
從官方來源提取的組織化文件。這些文件包含：
- 詳細解釋
- 帶有語言標註的程式碼範例
- 原始文件的連結
- 快速導航的目錄

### scripts/
在此添加常見自動化任務的輔助指令碼。

### assets/
在此添加模板、樣板或範例專案。

## 備註

- 此技能是從官方文件自動生成的
- 參考文件保留了源文件的結構和範例
- 程式碼範例包含語言偵測以提供更好的語法突顯
- 快速參考模式是從文件中的常見用法範例提取的

## 更新

要使用更新的文件刷新此技能：
1. 使用相同的配置重新執行擷取器
2. 技能將使用最新資訊重建
