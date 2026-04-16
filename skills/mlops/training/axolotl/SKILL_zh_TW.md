---
name: axolotl
description: 使用 Axolotl 微調 LLM 的專家指導 - YAML 配置、100 多種模型、LoRA/QLoRA、DPO/KTO/ORPO/GRPO、多模態支援
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [axolotl, torch, transformers, datasets, peft, accelerate, deepspeed]
metadata:
  hermes:
    tags: [微調, Axolotl, LLM, LoRA, QLoRA, DPO, KTO, ORPO, GRPO, YAML, HuggingFace, DeepSpeed, 多模態]

---

# Axolotl 技能

提供 axolotl 開發的全面協助，內容由官方文件生成。

## 何時使用此技能

當發生以下情況時應觸發此技能：
- 使用 axolotl 工作時
- 詢問 axolotl 功能或 API 時
- 實作 axolotl 解決方案時
- 除錯 axolotl 程式碼時
- 學習 axolotl 最佳實踐時

## 快速參考

### 常見模式

**模式 1：** 驗證您的訓練任務是否存在可接受的資料傳輸速度，執行 NCCL 測試可以幫助定位瓶頸，例如：

```bash
./build/all_reduce_perf -b 8 -e 128M -f 2 -g 3
```

**模式 2：** 在 Axolotl yaml 中配置模型使用 FSDP。例如：

```yaml
fsdp_version: 2
fsdp_config:
  offload_params: true
  state_dict_type: FULL_STATE_DICT
  auto_wrap_policy: TRANSFORMER_BASED_WRAP
  transformer_layer_cls_to_wrap: LlamaDecoderLayer
  reshard_after_forward: true
```

**模式 3：** context_parallel_size 應為 GPU 總數的約數。例如：

```yaml
context_parallel_size: 4
```

**模式 4：** 例如：
- 使用 8 個 GPU 且無序列平行：每步處理 8 個不同批次
- 使用 8 個 GPU 且 context_parallel_size=4：每步僅處理 2 個不同批次（每個批次拆分到 4 個 GPU 上）
- 如果您的每 GPU micro_batch_size 為 2，全域批次大小將從 16 減少到 4

```yaml
context_parallel_size: 4
```

**模式 5：** 在配置中設置 `save_compressed: true` 可以啟用以壓縮格式儲存模型，這會：
- 減少約 40% 的磁碟空間佔用
- 保持與 vLLM 的相容性以實現加速推理
- 保持與 llmcompressor 的相容性以進行進一步優化（例如：量化）

```yaml
save_compressed: true
```

**模式 6：** 注意
不必將您的整合放在 integrations 資料夾中。它可以放在任何位置，只要它安裝在 Python 環境的套件中即可。參考範例：https://github.com/axolotl-ai-cloud/diff-transformer

```
integrations
```

**模式 7：** 處理單個範例和批次資料。
- 單個範例：sample[‘input_ids’] 是一個 list[int]
- 批次資料：sample[‘input_ids’] 是一個 list[list[int]]

```python
utils.trainer.drop_long_seq(sample, sequence_len=2048, min_sequence_len=2)
```

### 範例程式碼模式

**範例 1** (python):
```python
cli.cloud.modal_.ModalCloud(config, app=None)
```

**範例 2** (python):
```python
cli.cloud.modal_.run_cmd(cmd, run_folder, volumes=None)
```

**範例 3** (python):
```python
core.trainers.base.AxolotlTrainer(
    *_args,
    bench_data_collator=None,
    eval_data_collator=None,
    dataset_tags=None,
    **kwargs,
)
```

**範例 4** (python):
```python
core.trainers.base.AxolotlTrainer.log(logs, start_time=None)
```

**範例 5** (python):
```python
prompt_strategies.input_output.RawInputOutputPrompter()
```

## 參考文件

此技能在 `references/` 中包含詳細文件：

- **api.md** - API 文件
- **dataset-formats.md** - 資料集格式文件
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
