# Axolotl - API 參考

**頁數：** 150

---

## cli.cloud.modal_

**URL:** https://docs.axolotl.ai/docs/api/cli.cloud.modal_.html

**內容：**
- cli.cloud.modal_
- 類別 (Classes)
  - ModalCloud
- 函數 (Functions)
  - run_cmd

從 CLI 支援 Modal Cloud

Modal Cloud 實作。

在資料夾中執行命令，在執行前重新載入 Modal Volume，並在成功時提交 (commit)。

**範例：**

範例 1 (python):
```python
cli.cloud.modal_.ModalCloud(config, app=None)
```

範例 2 (python):
```python
cli.cloud.modal_.run_cmd(cmd, run_folder, volumes=None)
```

---

## core.trainers.base

**URL:** https://docs.axolotl.ai/docs/api/core.trainers.base.html

**內容：**
- core.trainers.base
- 類別 (Classes)
  - AxolotlTrainer
    - 方法 (Methods)
      - log
        - 參數 (Parameters)
      - push_to_hub
      - store_metrics
        - 參數 (Parameters)

自定義訓練器模組

為 axolotl 輔助程式擴展基礎 Trainer

記錄監控訓練的各種物件的日誌，包括儲存的指標。

覆寫 push_to_hub 方法，以便在將模型推送到 Hub 時強制新增標籤。詳情請參閱 ~transformers.Trainer.push_to_hub。

按指定的縮減類型儲存指標。

**範例：**

範例 1 (python):
```python
core.trainers.base.AxolotlTrainer(
    *_args,
    bench_data_collator=None,
    eval_data_collator=None,
    dataset_tags=None,
    **kwargs,
)
```

範例 2 (python):
```python
core.trainers.base.AxolotlTrainer.log(logs, start_time=None)
```

範例 3 (python):
```python
core.trainers.base.AxolotlTrainer.push_to_hub(*args, **kwargs)
```

範例 4 (python):
```python
core.trainers.base.AxolotlTrainer.store_metrics(
    metrics,
    train_eval='train',
    reduction='mean',
)
```

---

## prompt_strategies.input_output

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.input_output.html

**內容：**
- prompt_strategies.input_output
- 類別 (Classes)
  - RawInputOutputPrompter
  - RawInputOutputStrategy

prompt_strategies.input_output

用於純輸入/輸出提示對的模組

原始輸入/輸出數據的提示器 (prompter)

用於輸入/輸出對的提示策略類別

**範例：**

範例 1 (python):
```python
prompt_strategies.input_output.RawInputOutputPrompter()
```

範例 2 (python):
```python
prompt_strategies.input_output.RawInputOutputStrategy(
    *args,
    eos_token=None,
    **kwargs,
)
```

---

## prompt_strategies.completion

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.completion.html

**內容：**
- prompt_strategies.completion
- 類別 (Classes)
  - CompletionPromptTokenizingStrategy
  - CompletionPrompter

prompt_strategies.completion

基礎補全文本

用於補全 (Completion) 提示的標記化策略。

用於補全的提示器

**範例：**

範例 1 (python):
```python
prompt_strategies.completion.CompletionPromptTokenizingStrategy(
    *args,
    max_length=None,
    **kwargs,
)
```

範例 2 (python):
```python
prompt_strategies.completion.CompletionPrompter()
```

---

## utils.collators.core

**URL:** https://docs.axolotl.ai/docs/api/utils.collators.core.html

**內容：**
- utils.collators.core

基礎共用整理器 (collator) 常數

---

## monkeypatch.data.batch_dataset_fetcher

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.data.batch_dataset_fetcher.html

**內容：**
- monkeypatch.data.batch_dataset_fetcher
- 函數 (Functions)
  - apply_multipack_dataloader_patch
  - patch_fetchers
  - patched_worker_loop
  - remove_multipack_dataloader_patch

monkeypatch.data.batch_dataset_fetcher

用於資料集獲取器處理打包索引批次的 Monkey patches。

此補丁允許 DataLoader 正確處理包含多個打包序列箱 (bins) 的批次。

對 PyTorch 的 DataLoader 組件應用補丁。

確保在工作進程中應用補丁的工作迴圈。

移除 monkeypatch 並恢復原始 PyTorch DataLoader 行為。

**範例：**

範例 1 (python):
```python
monkeypatch.data.batch_dataset_fetcher.apply_multipack_dataloader_patch()
```

範例 2 (python):
```python
monkeypatch.data.batch_dataset_fetcher.patch_fetchers()
```

範例 3 (python):
```python
monkeypatch.data.batch_dataset_fetcher.patched_worker_loop(*args, **kwargs)
```

範例 4 (python):
```python
monkeypatch.data.batch_dataset_fetcher.remove_multipack_dataloader_patch()
```

---

## core.datasets.chat

**URL:** https://docs.axolotl.ai/docs/api/core.datasets.chat.html

**內容：**
- core.datasets.chat
- 類別 (Classes)
  - TokenizedChatDataset

已標記化聊天資料集

**範例：**

範例 1 (python):
```python
core.datasets.chat.TokenizedChatDataset(
    data,
    model_transform,
    *args,
    message_transform=None,
    formatter=None,
    process_count=None,
    keep_in_memory=False,
    **kwargs,
)
```

---

## utils.freeze

**URL:** https://docs.axolotl.ai/docs/api/utils.freeze.html

**內容：**
- utils.freeze
- 類別 (Classes)
  - LayerNamePattern
    - 方法 (Methods)
      - match
- 函數 (Functions)
  - freeze_layers_except

按名稱凍結/取消凍結參數的模組

代表層名稱的正則表示式模式，可能包含參數索引範圍。

檢查給定的層名稱是否與正則表示式模式匹配。

參數：- name (str): 要檢查的層名稱。

回傳：- bool: 如果層名稱與模式匹配則為 True，否則為 False。

凍結給定模型的所有層，除了與給定正則表示式模式匹配的層。模式中的句點被視為字面意義上的點，而不是通配符。

參數：- model (nn.Module): 要修改的 PyTorch 模型。- regex_patterns (list of str): 要保持非凍結狀態的層名稱匹配正則表示式列表。請注意，您不能在模式中使用點作為通配符，因為它保留用於分隔層名稱。此外，要匹配整個層名稱，模式應以「^」開頭並以「\(」結尾，否則它將匹配層名稱的任何部分。範圍模式部分是選填的，且它不會被編譯為正則表示式模式，這意味著如果您想匹配整個層名稱，必須在範圍模式之前加上「\)」。例如：[“^model.embed_tokens.weight\([:32000]", "layers.2[0-9]+.block_sparse_moe.gate.[a-z]+\)”]

回傳：無；模型將原地 (in place) 被修改。

**範例：**

範例 1 (python):
```python
utils.freeze.LayerNamePattern(pattern)
```

範例 2 (python):
```python
utils.freeze.LayerNamePattern.match(name)
```

範例 3 (python):
```python
utils.freeze.freeze_layers_except(model, regex_patterns)
```

---

## monkeypatch.unsloth_

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.unsloth_.html

**內容：**
- monkeypatch.unsloth_

使用 unsloth 優化進行補丁的模組

---

## utils.schemas.datasets

**URL:** https://docs.axolotl.ai/docs/api/utils.schemas.datasets.html

**內容：**
- utils.schemas.datasets
- 類別 (Classes)
  - DPODataset
  - KTODataset
  - PretrainingDataset
  - SFTDataset
    - 方法 (Methods)
      - handle_legacy_message_fields
  - StepwiseSupervisedDataset
  - UserDefinedDPOType

utils.schemas.datasets

用於資料集相關配置的 Pydantic 模型

DPO 配置子集

KTO 配置子集

預訓練資料集配置子集

SFT 配置子集

處理舊版訊息欄位映射與新屬性映射系統之間的向後相容性。

分步監督式資料集配置子集

使用者定義的 DPO 類型

使用者定義的 KTO 類型

使用者定義提示類型的結構

**範例：**

範例 1 (python):
```python
utils.schemas.datasets.DPODataset()
```

範例 2 (python):
```python
utils.schemas.datasets.KTODataset()
```

範例 3 (python):
```python
utils.schemas.datasets.PretrainingDataset()
```

範例 4 (python):
```python
utils.schemas.datasets.SFTDataset()
```

---

## core.chat.format.llama3x

**URL:** https://docs.axolotl.ai/docs/api/core.chat.format.llama3x.html

**內容：**
- core.chat.format.llama3x

core.chat.format.llama3x

用於 MessageContents 的 Llama 3.x 聊天格式化函數

---

## datasets

**URL:** https://docs.axolotl.ai/docs/api/datasets.html

**內容：**
- datasets
- 類別 (Classes)
  - TokenizedPromptDataset
    - 參數 (Parameters)

包含資料集功能的模組。

我們希望這能作為已載入現有資料集的包裝器 (wrapper)。讓我們使用中介軟體 (middlewares) 的概念來包裝每個資料集。稍後我們將使用整理器來填補資料集。

從文本檔案串流回傳已標記化提示的資料集。

**範例：**

範例 1 (python):
```python
datasets.TokenizedPromptDataset(
    prompt_tokenizer,
    dataset,
    process_count=None,
    keep_in_memory=False,
    **kwargs,
)
```

---

## prompt_strategies.bradley_terry.llama3

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.bradley_terry.llama3.html

**內容：**
- prompt_strategies.bradley_terry.llama3
- 函數 (Functions)
  - icr

prompt_strategies.bradley_terry.llama3

用於包含 system, input, chosen, rejected 的資料集的 chatml 轉換，以匹配 llama3 聊天模板

用於包含 system, input, chosen, rejected 的資料集的 chatml 轉換，例如：https://huggingface.co/datasets/argilla/distilabel-intel-orca-dpo-pairs

**範例：**

範例 1 (python):
```python
prompt_strategies.bradley_terry.llama3.icr(cfg, **kwargs)
```

---

## common.datasets

**URL:** https://docs.axolotl.ai/docs/api/common.datasets.html

**內容：**
- common.datasets
- 類別 (Classes)
  - TrainDatasetMeta
- 函數 (Functions)
  - load_datasets
    - 參數 (Parameters)
    - 回傳 (Returns)
  - load_preference_datasets
    - 參數 (Parameters)
    - 回傳 (Returns)

資料集載入公用程式。

具有訓練和驗證資料集及其元數據欄位的 Dataclass。

載入一個或多個訓練或評估資料集，呼叫 axolotl.utils.data.prepare_datasets。可選地記錄除錯資訊。

載入一個或多個訓練或評估資料集，用於使用成對偏好數據的 RL 訓練，呼叫 axolotl.utils.data.rl.prepare_preference_datasets。可選地記錄除錯資訊。

從資料集中隨機取樣 num_samples 個樣本（有放回）。

**範例：**

範例 1 (python):
```python
common.datasets.TrainDatasetMeta(
    train_dataset,
    eval_dataset=None,
    total_num_steps=None,
)
```

範例 2 (python):
```python
common.datasets.load_datasets(cfg, cli_args=None, debug=False)
```

範例 3 (python):
```python
common.datasets.load_preference_datasets(cfg, cli_args=None)
```

範例 4 (python):
```python
common.datasets.sample_dataset(dataset, num_samples)
```

---

## cli.train

**URL:** https://docs.axolotl.ai/docs/api/cli.train.html

**內容：**
- cli.train
- 函數 (Functions)
  - do_cli
    - 參數 (Parameters)
  - do_train
    - 參數 (Parameters)

用於在模型上執行訓練的 CLI。

解析 axolotl 配置、CLI 參數，並呼叫 do_train。

透過首先載入 axolotl 配置中指定的資料集，然後呼叫 axolotl.train.train 來訓練 transformers 模型。訓練完成後還會執行插件管理器的 post_train_unload。

**範例：**

範例 1 (python):
```python
cli.train.do_cli(config=Path('examples/'), **kwargs)
```

範例 2 (python):
```python
cli.train.do_train(cfg, cli_args)
```

---

## cli.utils.fetch

**URL:** https://docs.axolotl.ai/docs/api/cli.utils.fetch.html

**內容：**
- cli.utils.fetch
- 函數 (Functions)
  - fetch_from_github
    - 參數 (Parameters)

用於 axolotl fetch CLI 命令的公用程式。

從 GitHub 儲存庫中的特定目錄同步檔案。僅下載本地不存在或已更改的檔案。

**範例：**

範例 1 (python):
```python
cli.utils.fetch.fetch_from_github(dir_prefix, dest_dir=None, max_workers=5)
```

---

## utils.tokenization

**URL:** https://docs.axolotl.ai/docs/api/utils.tokenization.html

**內容：**
- utils.tokenization
- 函數 (Functions)
  - color_token_for_rl_debug
  - process_tokens_for_rl_debug

用於標記化公用程式的模組

根據類型為標記著色的輔助函數。

處理並為標記著色的輔助函數。

**範例：**

範例 1 (python):
```python
utils.tokenization.color_token_for_rl_debug(
    decoded_token,
    encoded_token,
    color,
    text_only,
)
```

範例 2 (python):
```python
utils.tokenization.process_tokens_for_rl_debug(
    tokens,
    color,
    tokenizer,
    text_only,
)
```

---

## core.trainers.grpo.sampler

**URL:** https://docs.axolotl.ai/docs/api/core.trainers.grpo.sampler.html

**內容：**
- core.trainers.grpo.sampler
- 類別 (Classes)
  - SequenceParallelRepeatRandomSampler
    - 參數 (Parameters)
    - 方法 (Methods)
      - set_epoch
        - 參數 (Parameters)

core.trainers.grpo.sampler

重複隨機取樣器（類似於 https://github.com/huggingface/trl/blob/main/trl/trainer/grpo_trainer.py 中的實作），增加了序列平行功能；即在同一個序列平行組中的各個 rank 之間複製數據。

用於具有序列平行的 GRPO 訓練的取樣器。

此取樣器確保：- 同一序列平行 (SP) 組中的各個 rank 接收相同的數據。- 每個索引被重複多次以取樣不同的補全。- 整個批次被重複以便在多次更新中重用。- 數據正確分佈在各個 SP 組中。

在下表中，數值代表資料集索引。每個 SP 組有 context_parallel_size = 2 個 GPU 共同處理相同的數據。有 2 個 SP 組 (SP0 和 SP1)，world_size = 4 個 GPU。

grad_accum=2 ▲ ▲ 0 0 [0 0 0 1 1 1] [2 2 2 3 3 3] <- SP 組接收不同的數據 ▼ | 0 1 [0 0 0 1 1 1] [2 2 2 3 3 3] <- 每個 SP 組 GPU 接收相同的數據 | | 1 2 [0 0 0 1 1 1] [2 2 2 3 3 3] <- 在迭代中重複相同的索引 num_iterations=2 ▼ 1 3 [0 0 0 1 1 1] [2 2 2 3 3 3] <- 使用梯度累積時

為此取樣器設定 epoch。

**範例：**

範例 1 (python):
```python
core.trainers.grpo.sampler.SequenceParallelRepeatRandomSampler(
    dataset,
    mini_repeat_count,
    world_size,
    rank,
    batch_size=1,
    repeat_count=1,
    context_parallel_size=1,
    shuffle=True,
    seed=0,
    drop_last=False,
)
```

範例 2 (unknown):
```unknown
序列平行組 (Sequence Parallel Groups)
                                |       SP0        |       SP1        |
                                |  GPU 0  |  GPU 1 |  GPU 2  |  GPU 3 |
            global_step  step    <---> mini_repeat_count=3
                                    <----------> 每個 SP 組 batch_size=2
```

範例 3 (unknown):
```unknown
2       4         [4 4 4  5 5 5]     [6 6 6  7 7 7]   <- 新批次的數據索引
                 2       5         [4 4 4  5 5 5]     [6 6 6  7 7 7]
                                    ...
```

範例 4 (python):
```python
core.trainers.grpo.sampler.SequenceParallelRepeatRandomSampler.set_epoch(epoch)
```

---

## evaluate

**URL:** https://docs.axolotl.ai/docs/api/evaluate.html

**內容：**
- evaluate
- 函數 (Functions)
  - evaluate
    - 參數 (Parameters)
    - 回傳 (Returns)
  - evaluate_dataset
    - 參數 (Parameters)
    - 回傳 (Returns)

評估模型的模組。

在訓練和驗證資料集上評估模型。

評估單個資料集的輔助函數。

**範例：**

範例 1 (python):
```python
evaluate.evaluate(cfg, dataset_meta)
```

範例 2 (python):
```python
evaluate.evaluate_dataset(trainer, dataset, dataset_type, flash_optimum=False)
```

---

## utils.optimizers.adopt

**URL:** https://docs.axolotl.ai/docs/api/utils.optimizers.adopt.html

**內容：**
- utils.optimizers.adopt
- 函數 (Functions)
  - adopt

utils.optimizers.adopt

複製自 https://github.com/iShohei220/adopt

ADOPT: Modified Adam Can Converge with Any β2 with the Optimal Rate (2024) Taniguchi, Shohei and Harada, Keno and Minegishi, Gouki and Oshima, Yuta and Jeong, Seong Cheol and Nagahara, Go and Iiyama, Tomoshi and Suzuki, Masahiro and Iwasawa, Yusuke and Matsuo, Yutaka

執行 ADOPT 演算法計算的函數式 API。

**範例：**

範例 1 (python):
```python
utils.optimizers.adopt.adopt(
    params,
    grads,
    exp_avgs,
    exp_avg_sqs,
    state_steps,
    foreach=None,
    capturable=False,
    differentiable=False,
    fused=None,
    grad_scale=None,
    found_inf=None,
    has_complex=False,
    *,
    beta1,
    beta2,
    lr,
    clip_lambda,
    weight_decay,
    decouple,
    eps,
    maximize,
)
```

---

## prompt_tokenizers

**URL:** https://docs.axolotl.ai/docs/api/prompt_tokenizers.html

**內容：**
- prompt_tokenizers
- 類別 (Classes)
  - AlpacaMultipleChoicePromptTokenizingStrategy
  - AlpacaPromptTokenizingStrategy
  - AlpacaReflectionPTStrategy
  - DatasetWrappingStrategy
  - GPTeacherPromptTokenizingStrategy
  - InstructionPromptTokenizingStrategy
  - InvalidDataException
  - JeopardyPromptTokenizingStrategy

包含 PromptTokenizingStrategy 和 Prompter 類別的模組

用於 Alpaca 多選提示的標記化策略。

用於 Alpaca 提示的標記化策略。

用於 Alpaca Reflection 提示的標記化策略。

用於聊天訊息包裝資料集的抽象類別

用於 GPTeacher 提示的標記化策略。

用於指令式提示的標記化策略。

當數據無效時拋出的異常

用於 Jeopardy 提示的標記化策略。

用於 NomicGPT4All 提示的標記化策略。

用於 OpenAssistant 提示的標記化策略。

標記化策略的抽象類別

用於 Reflection 提示的標記化策略。

用於 SummarizeTLDR 提示的標記化策略。

解析已標記化的提示，並將已標記化的 input_ids, attention_mask 和 labels 附加到結果中

回傳標記化提示函數的預設值

**範例：**

範例 1 (python):
```python
prompt_tokenizers.AlpacaMultipleChoicePromptTokenizingStrategy(
    prompter,
    tokenizer,
    train_on_inputs=False,
    sequence_len=2048,
)
```

範例 2 (python):
```python
prompt_tokenizers.AlpacaPromptTokenizingStrategy(
    prompter,
    tokenizer,
    train_on_inputs=False,
    sequence_len=2048,
)
```

範例 3 (python):
```python
prompt_tokenizers.AlpacaReflectionPTStrategy(
    prompter,
    tokenizer,
    train_on_inputs=False,
    sequence_len=2048,
)
```

範例 4 (python):
```python
prompt_tokenizers.DatasetWrappingStrategy()
```

---

## cli.art

**URL:** https://docs.axolotl.ai/docs/api/cli.art.html

**內容：**
- cli.art
- 函數 (Functions)
  - print_axolotl_text_art

Axolotl ASCII 標誌公用程式。

列印 axolotl ASCII 藝術。

**範例：**

範例 1 (python):
```python
cli.art.print_axolotl_text_art()
```

---

## utils.callbacks.perplexity

**URL:** https://docs.axolotl.ai/docs/api/utils.callbacks.perplexity.html

**內容：**
- utils.callbacks.perplexity
- 類別 (Classes)
  - Perplexity
    - 方法 (Methods)
      - compute

utils.callbacks.perplexity

將困惑度 (perplexity) 作為評估指標計算的回呼 (callback)。

計算 https://huggingface.co/docs/transformers/en/perplexity 中定義的困惑度。這是一個自定義變體，不會重新標記輸入或重新載入模型。

在序列的固定長度滑動視窗中計算困惑度。

**範例：**

範例 1 (python):
```python
utils.callbacks.perplexity.Perplexity(tokenizer, max_seq_len, stride=512)
```

範例 2 (python):
```python
utils.callbacks.perplexity.Perplexity.compute(model, references=None)
```

---

## cli.utils.train

**URL:** https://docs.axolotl.ai/docs/api/cli.utils.train.html

**內容：**
- cli.utils.train
- 函數 (Functions)
  - build_command
    - 參數 (Parameters)
    - 回傳 (Returns)
  - generate_config_files
    - 參數 (Parameters)
  - launch_training

用於 axolotl train CLI 命令的公用程式。

從基礎命令和選項構建命令列表。

產生要處理的配置文件列表。產生一個元組，包含配置文件名稱和指示這是否為配置組（即 sweep）的布林值。

使用給定配置執行訓練。

**範例：**

範例 1 (python):
```python
cli.utils.train.build_command(base_cmd, options)
```

範例 2 (python):
```python
cli.utils.train.generate_config_files(config, sweep)
```

範例 3 (python):
```python
cli.utils.train.launch_training(
    cfg_file,
    launcher,
    cloud,
    kwargs,
    launcher_args=None,
    use_exec=False,
)
```

---

## cli.vllm_serve

**URL:** https://docs.axolotl.ai/docs/api/cli.vllm_serve.html

**內容：**
- cli.vllm_serve
- 類別 (Classes)
  - AxolotlScriptArguments
- 函數 (Functions)
  - do_vllm_serve
    - 回傳 (Returns)

啟動用於在線 RL 的 vllm 伺服器的 CLI

VLLM 伺服器的附加參數

啟動用於提供在線 RL 使用的 LLM 模型的 VLLM 伺服器

參數 :param cfg: 解析後的 YAML 配置字典 :param cli_args: VllmServeCliArgs 類型的附加命令列參數字典

**範例：**

範例 1 (python):
```python
cli.vllm_serve.AxolotlScriptArguments(
    reasoning_parser='',
    enable_reasoning=None,
)
```

範例 2 (python):
```python
cli.vllm_serve.do_vllm_serve(config, cli_args)
```

---

## convert

**URL:** https://docs.axolotl.ai/docs/api/convert.html

**內容：**
- convert
- 類別 (Classes)
  - FileReader
  - FileWriter
  - JsonParser
  - JsonToJsonlConverter
  - JsonlSerializer
  - StdoutWriter

包含 File Reader, File Writer, Json Parser 和 Jsonl Serializer 類別的模組

讀取檔案並將其內容作為字串回傳

將字串寫入檔案

將字串解析為 JSON 並回傳結果

將 JSON 檔案轉換為 JSONL

將 JSON 物件列表序列化為 JSONL 字串

將字串寫入標準輸出 (stdout)

**範例：**

範例 1 (python):
```python
convert.FileReader()
```

範例 2 (python):
```python
convert.FileWriter(file_path)
```

範例 3 (python):
```python
convert.JsonParser()
```

範例 4 (python):
```python
convert.JsonToJsonlConverter(
    file_reader,
    file_writer,
    json_parser,
    jsonl_serializer,
)
```

---

## monkeypatch.utils

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.utils.html

**內容：**
- monkeypatch.utils
- 函數 (Functions)
  - get_cu_seqlens
  - get_cu_seqlens_from_pos_ids
  - mask_2d_to_4d

monkeypatches 的共用公用程式

使用 attn mask 為 flash attention 產生累積序列長度遮罩 (cumulative sequence length mask)

使用 pos ids 為 flash attention 產生累積序列長度遮罩

將 attention_mask 從 [bsz, seq_len] 擴展為 [bsz, 1, tgt_seq_len, src_seq_len]。此擴展處理打包序列，使序列在相互關注時共用相同的注意力遮罩整數值。此擴展將遮罩轉換為下三角形式以防止未來窺視。

**範例：**

範例 1 (python):
```python
monkeypatch.utils.get_cu_seqlens(attn_mask)
```

範例 2 (python):
```python
monkeypatch.utils.get_cu_seqlens_from_pos_ids(position_ids)
```

範例 3 (python):
```python
monkeypatch.utils.mask_2d_to_4d(mask, dtype, tgt_len=None)
```

---

## prompt_strategies.pygmalion

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.pygmalion.html

**內容：**
- prompt_strategies.pygmalion
- 類別 (Classes)
  - PygmalionPromptTokenizingStrategy
  - PygmalionPrompter

prompt_strategies.pygmalion

包含 PygmalionPromptTokenizingStrategy 和 PygmalionPrompter 類別的模組

Pygmalion 的標記化策略。

Pygmalion 的提示器。

**範例：**

範例 1 (python):
```python
prompt_strategies.pygmalion.PygmalionPromptTokenizingStrategy(
    prompter,
    tokenizer,
    *args,
    **kwargs,
)
```

範例 2 (python):
```python
prompt_strategies.pygmalion.PygmalionPrompter(*args, **kwargs)
```

---

## utils.callbacks.mlflow_

**URL:** https://docs.axolotl.ai/docs/api/utils.callbacks.mlflow_.html

**內容：**
- utils.callbacks.mlflow_
- 類別 (Classes)
  - SaveAxolotlConfigtoMlflowCallback

utils.callbacks.mlflow_

用於訓練器回呼的 MLFlow 模組

將 axolotl 配置儲存到 mlflow 的回呼

**範例：**

範例 1 (python):
```python
utils.callbacks.mlflow_.SaveAxolotlConfigtoMlflowCallback(axolotl_config_path)
```

---

## loaders.adapter

**URL:** https://docs.axolotl.ai/docs/api/loaders.adapter.html

**內容：**
- loaders.adapter
- 函數 (Functions)
  - setup_quantized_meta_for_peft
  - setup_quantized_peft_meta_for_training

適配器載入功能，包括 LoRA / QLoRA 及相關公用程式

將 quant_state.to 替換為虛假函數，以防止 PEFT 將 quant_state 移動到 meta 設備

將虛假 quant_state.to 方法替換回原始函數以允許訓練繼續

**範例：**

範例 1 (python):
```python
loaders.adapter.setup_quantized_meta_for_peft(model)
```

範例 2 (python):
```python
loaders.adapter.setup_quantized_peft_meta_for_training(model)
```

---

## cli.cloud.base

**URL:** https://docs.axolotl.ai/docs/api/cli.cloud.base.html

**內容：**
- cli.cloud.base
- 類別 (Classes)
  - Cloud

來自 cli 的雲端平台基礎類別

雲端平台的抽象基礎類別。

**範例：**

範例 1 (python):
```python
cli.cloud.base.Cloud()
```

---

## monkeypatch.llama_attn_hijack_flash

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.llama_attn_hijack_flash.html

**內容：**
- monkeypatch.llama_attn_hijack_flash
- 函數 (Functions)
  - flashattn_forward_with_s2attn

monkeypatch.llama_attn_hijack_flash

用於 llama 模型的 Flash attention monkey patch

輸入形狀：Batch x Time x Channel

來源：https://github.com/dvlab-research/LongLoRA/blob/main/llama_attn_replace.py

attention_mask: [bsz, q_len]

如果提供 cu_seqlens 將被忽略，如果提供 max_seqlen 將被忽略

**範例：**

範例 1 (python):
```python
monkeypatch.llama_attn_hijack_flash.flashattn_forward_with_s2attn(
    self,
    hidden_states,
    attention_mask=None,
    position_ids=None,
    past_key_value=None,
    output_attentions=False,
    use_cache=False,
    padding_mask=None,
    cu_seqlens=None,
    max_seqlen=None,
)
```

---

## monkeypatch.llama_patch_multipack

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.llama_patch_multipack.html

**內容：**
- monkeypatch.llama_patch_multipack

monkeypatch.llama_patch_multipack

已修補的 LlamaAttention，使用 torch.nn.functional.scaled_dot_product_attention

---

## cli.inference

**URL:** https://docs.axolotl.ai/docs/api/cli.inference.html

**內容：**
- cli.inference
- 函數 (Functions)
  - do_cli
    - 參數 (Parameters)
  - do_inference
    - 參數 (Parameters)
  - do_inference_gradio
    - 參數 (Parameters)
  - get_multi_line_input
    - 回傳 (Returns)

用於在訓練好的模型上執行推理的 CLI。

解析 axolotl 配置、CLI 參數，並呼叫 do_inference 或 do_inference_gradio。

在命令列迴圈中執行推理。接受使用者輸入，（選填）應用聊天模板，並使用 axolotl 配置中指定的模型根據預設產生配置產生補全。

在 Gradio 介面中執行推理。接受使用者輸入，（選填）應用聊天模板，並使用 axolotl 配置中指定的模型根據預設產生配置產生補全。

從終端機獲取多行輸入。

**範例：**

範例 1 (python):
```python
cli.inference.do_cli(config=Path('examples/'), gradio=False, **kwargs)
```

範例 2 (python):
```python
cli.inference.do_inference(cfg, cli_args)
```

範例 3 (python):
```python
cli.inference.do_inference_gradio(cfg, cli_args)
```

範例 4 (python):
```python
cli.inference.get_multi_line_input()
```

---

## loaders.tokenizer

**URL:** https://docs.axolotl.ai/docs/api/loaders.tokenizer.html

**內容：**
- loaders.tokenizer
- 函數 (Functions)
  - load_tokenizer
  - modify_tokenizer_files
    - 參數 (Parameters)
    - 回傳 (Returns)

標記器載入功能及相關公用程式

根據提供的配置載入並配置標記器。

修改標記器檔案以替換 added_tokens 字串，儲存到輸出目錄，並回傳修改後標記器的路徑。

這僅適用於新增到標記器的保留標記，不適用於已成為詞表一部分的標記。

參考：https://github.com/huggingface/transformers/issues/27974#issuecomment-1854188941

**範例：**

範例 1 (python):
```python
loaders.tokenizer.load_tokenizer(cfg)
```

範例 2 (python):
```python
loaders.tokenizer.modify_tokenizer_files(
    tokenizer_path,
    token_mappings,
    output_dir,
)
```

---

## cli.utils.sweeps

**URL:** https://docs.axolotl.ai/docs/api/cli.utils.sweeps.html

**內容：**
- cli.utils.sweeps
- 函數 (Functions)
  - generate_sweep_configs
    - 參數 (Parameters)
    - 回傳 (Returns)
    - 範例

用於處理 axolotl train CLI 命令中配置掃描 (sweeps) 的公用程式

透過對基礎配置應用掃描來遞迴產生所有可能的配置。

sweeps_config = { ‘learning_rate’: [0.1, 0.01], ’_’: [ {‘load_in_8bit’: True, ‘adapter’: ‘lora’}, {‘load_in_4bit’: True, ‘adapter’: ‘qlora’} ] }

**範例：**

範例 1 (python):
```python
cli.utils.sweeps.generate_sweep_configs(base_config, sweeps_config)
```

---

## prompt_strategies.dpo.chatml

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.dpo.chatml.html

**內容：**
- prompt_strategies.dpo.chatml
- 函數 (Functions)
  - argilla_chat
  - icr
  - intel
  - ultra

prompt_strategies.dpo.chatml

用於 chatml 的 DPO 策略

用於 argilla/dpo-mix-7k 對話

用於包含 system, input, chosen, rejected 的資料集的 chatml 轉換，例如：https://huggingface.co/datasets/argilla/distilabel-intel-orca-dpo-pairs

用於 Intel Orca DPO 對

用於 ultrafeedback binarized 對話

**範例：**

範例 1 (python):
```python
prompt_strategies.dpo.chatml.argilla_chat(cfg, **kwargs)
```

範例 2 (python):
```python
prompt_strategies.dpo.chatml.icr(cfg, **kwargs)
```

範例 3 (python):
```python
prompt_strategies.dpo.chatml.intel(cfg, **kwargs)
```

範例 4 (python):
```python
prompt_strategies.dpo.chatml.ultra(cfg, **kwargs)
```

---

## cli.quantize

**URL:** https://docs.axolotl.ai/docs/api/cli.quantize.html

**內容：**
- cli.quantize
- 函數 (Functions)
  - do_quantize
    - 參數 (Parameters)

使用 torchao 對模型進行訓練後量化的 CLI

量化模型的權重

**範例：**

範例 1 (python):
```python
cli.quantize.do_quantize(config, cli_args)
```

---

## utils.dict

**URL:** https://docs.axolotl.ai/docs/api/utils.dict.html

**內容：**
- utils.dict
- 類別 (Classes)
  - DictDefault
- 函數 (Functions)
  - remove_none_values

包含 DictDefault 類別的模組

對於缺失的鍵回傳 None 而非回傳空 Dict 的字典。

從類字典物件或列表中移除 null。這些值可能由於資料集載入導致模式合併而出現。參見 https://github.com/axolotl-ai-cloud/axolotl/pull/2909

**範例：**

範例 1 (python):
```python
utils.dict.DictDefault()
```

範例 2 (python):
```python
utils.dict.remove_none_values(obj)
```

---

## API 參考 (API Reference)

**URL:** https://docs.axolotl.ai/docs/api/

**內容：**
- API 參考
- 核心 (Core)
- CLI
- 訓練器 (Trainers)
- 模型載入 (Model Loading)
- 混合類別 (Mixins)
- 上下文管理器 (Context Managers)
- 提示策略 (Prompt Strategies)
- 核心程式 (Kernels)
- Monkey Patches

訓練的核心功能

命令列介面

訓練實作

載入和補丁模型、標記器等的功能。

用於增強訓練器的混合類別

用於更改訓練器行為的上下文管理器

提示格式化策略

低階效能優化

用於模型優化的執行階段補丁

用於 Axolotl 配置的 Pydantic 數據模型

第三方整合和擴展

常用公用程式和共用功能

自定義模型實作

數據處理公用程式

---

## monkeypatch.lora_kernels

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.lora_kernels.html

**內容：**
- monkeypatch.lora_kernels
- 類別 (Classes)
  - FakeMLP
- 函數 (Functions)
  - apply_lora_kernel_patches
    - 參數 (Parameters)
    - 回傳 (Returns)
    - 拋出 (Raises)
    - 注意 (Note)
  - get_attention_cls_from_config

monkeypatch.lora_kernels

用於補丁自定義 LoRA Triton 核心和 torch.autograd 函數的模組。

用於 triton 補丁的預留位置 MLP

對 PEFT 模型應用優化的 Triton 核心補丁。

使用優化的 MLP 和 attention 計算實作對 PEFT 模型進行補丁。優化包括用於激活函數的自定義 Triton 核心和用於 LoRA 計算的專用 autograd 函數。

優化需要不含 dropout 和 bias 項的 LoRA 適配器。如果未滿足這些條件，函數將跳過補丁。

透過檢查模型配置獲取適當的注意力類別。使用動態匯入以支援遵循標準 transformers 命名規範的任何模型架構。

獲取模型的層。處理純文本和多模態模型。

不含優化的輸出投影原始實作。

不含優化的 QKV 投影原始實作。

給定 axolotl 配置，此方法使用優化的 LoRA 實作對推斷出的注意力類別正向傳遞進行補丁。

它修改注意力類別以使用優化的 QKV 和輸出投影。原始實作被保留，並可在需要時恢復。

**範例：**

範例 1 (python):
```python
monkeypatch.lora_kernels.FakeMLP(gate_proj, up_proj, down_proj)
```

範例 2 (python):
```python
monkeypatch.lora_kernels.apply_lora_kernel_patches(model, cfg)
```

範例 3 (python):
```python
monkeypatch.lora_kernels.get_attention_cls_from_config(cfg)
```

範例 4 (python):
```python
monkeypatch.lora_kernels.get_layers(model)
```

---

## monkeypatch.stablelm_attn_hijack_flash

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.stablelm_attn_hijack_flash.html

**內容：**
- monkeypatch.stablelm_attn_hijack_flash
- 函數 (Functions)
  - repeat_kv
  - rotate_half

monkeypatch.stablelm_attn_hijack_flash

PyTorch StableLM Epoch 模型。

這等同於 torch.repeat_interleave(x, dim=1, repeats=n_rep)。隱藏狀態從 (batch, num_key_value_heads, seqlen, head_dim) 變為 (batch, num_attention_heads, seqlen, head_dim)

旋轉輸入的一半隱藏維度。

**範例：**

範例 1 (python):
```python
monkeypatch.stablelm_attn_hijack_flash.repeat_kv(hidden_states, n_rep)
```

範例 2 (python):
```python
monkeypatch.stablelm_attn_hijack_flash.rotate_half(x)
```

---

## core.trainers.mixins.rng_state_loader

**URL:** https://docs.axolotl.ai/docs/api/core.trainers.mixins.rng_state_loader.html

**內容：**
- core.trainers.mixins.rng_state_loader
- 類別 (Classes)
  - RngLoaderMixin

core.trainers.mixins.rng_state_loader

從 checkpoint 恢復時錯誤的臨時修復/覆寫

參見 https://github.com/huggingface/transformers/pull/37162

TODO: 當上游新增 PR 到發布版本時移除

用於方法覆寫以從 checkpoint 載入 RNG 狀態的混合類別

**範例：**

範例 1 (python):
```python
core.trainers.mixins.rng_state_loader.RngLoaderMixin()
```

---

## core.trainers.utils

**URL:** https://docs.axolotl.ai/docs/api/core.trainers.utils.html

**內容：**
- core.trainers.utils

Axolotl 訓練器的公用程式

---

## core.training_args

**URL:** https://docs.axolotl.ai/docs/api/core.training_args.html

**內容：**
- core.training_args
- 類別 (Classes)
  - AxolotlCPOConfig
  - AxolotlKTOConfig
  - AxolotlORPOConfig
  - AxolotlPRMConfig
  - AxolotlRewardConfig
  - AxolotlTrainingArguments

額外的 axolotl 特定訓練參數

用於 CPO 訓練的 CPO 配置

用於 KTO 訓練的 KTO 配置

用於 ORPO 訓練的 ORPO 配置

用於 PRM 訓練的 PRM 配置

用於 Reward 訓練的 Reward 配置

Causal 訓練器的訓練參數

由於 HF TrainingArguments 未設定 output_dir 的預設值，因此此程式碼是重複的，不能作為混合類別使用。

**範例：**

範例 1 (python):
```python
core.training_args.AxolotlCPOConfig(simpo_gamma=None)
```

範例 2 (python):
```python
core.training_args.AxolotlKTOConfig()
```

範例 3 (python):
```python
core.training_args.AxolotlORPOConfig()
```

範例 4 (python):
```python
core.training_args.AxolotlPRMConfig()
```

---

## monkeypatch.btlm_attn_hijack_flash

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.btlm_attn_hijack_flash.html

**內容：**
- monkeypatch.btlm_attn_hijack_flash

monkeypatch.btlm_attn_hijack_flash

用於 cerebras btlm 模型的 Flash attention monkey patch

---

## prompt_strategies.dpo.passthrough

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.dpo.passthrough.html

**內容：**
- prompt_strategies.dpo.passthrough

prompt_strategies.dpo.passthrough

DPO 提示策略透傳/零處理策略

---

## kernels.swiglu

**URL:** https://docs.axolotl.ai/docs/api/kernels.swiglu.html

**內容：**
- kernels.swiglu
- 函數 (Functions)
  - swiglu_backward
    - 參數 (Parameters)
    - 回傳 (Returns)
  - swiglu_forward
    - 參數 (Parameters)
    - 回傳 (Returns)

用於 SwiGLU Triton 核心定義的模組。

參見「GLU Variants Improve Transformer」(https://arxiv.org/abs/2002.05202)。

感謝 unsloth (https://unsloth.ai/) 對此實作的啟發。

使用原地 (in-place) 操作的 SwiGLU 後向傳遞。

SwiGLU 正向傳遞。計算 SwiGLU 激活：x * sigmoid(x) * up，其中 x 是 gate 張量。

**範例：**

範例 1 (python):
```python
kernels.swiglu.swiglu_backward(grad_output, gate, up)
```

範例 2 (python):
```python
kernels.swiglu.swiglu_forward(gate, up)
```

---

## core.trainers.grpo.trainer

**URL:** https://docs.axolotl.ai/docs/api/core.trainers.grpo.trainer.html

**內容：**
- core.trainers.grpo.trainer
- 類別 (Classes)
  - AxolotlGRPOSequenceParallelTrainer
    - 方法 (Methods)
      - get_train_dataloader
  - AxolotlGRPOTrainer

core.trainers.grpo.trainer

Axolotl GRPO 訓練器（包含及不包含序列平行處理）

擴展基礎 GRPOTrainer 以進行序列平行處理

獲取訓練用的資料載入器 (dataloader)

為 axolotl 輔助程式擴展基礎 GRPOTrainer

**範例：**

範例 1 (python):
```python
core.trainers.grpo.trainer.AxolotlGRPOSequenceParallelTrainer(
    model,
    reward_funcs,
    args=None,
    train_dataset=None,
    eval_dataset=None,
    processing_class=None,
    reward_processing_classes=None,
    callbacks=None,
    optimizers=(None, None),
    peft_config=None,
    optimizer_cls_and_kwargs=None,
)
```

範例 2 (python):
```python
core.trainers.grpo.trainer.AxolotlGRPOSequenceParallelTrainer.get_train_dataloader(
)
```

範例 3 (python):
```python
core.trainers.grpo.trainer.AxolotlGRPOTrainer(*args, **kwargs)
```

---

## prompt_strategies.user_defined

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.user_defined.html

**內容：**
- prompt_strategies.user_defined
- 類別 (Classes)
  - UserDefinedDatasetConfig
  - UserDefinedPromptTokenizationStrategy

prompt_strategies.user_defined

使用 YML 配置中的配置的使用者定義提示

代表使用者定義資料集類型的 dataclass 配置

用於使用者定義提示的提示標記化策略

**範例：**

範例 1 (python):
```python
prompt_strategies.user_defined.UserDefinedDatasetConfig(
    system_prompt='',
    field_system='system',
    field_instruction='instruction',
    field_input='input',
    field_output='output',
    format='{instruction} {input} ',
    no_input_format='{instruction} ',
    system_format='{system}',
)
```

範例 2 (python):
```python
prompt_strategies.user_defined.UserDefinedPromptTokenizationStrategy(
    prompter,
    tokenizer,
    train_on_inputs=False,
    sequence_len=2048,
)
```

---

## utils.schemas.training

**URL:** https://docs.axolotl.ai/docs/api/utils.schemas.training.html

**內容：**
- utils.schemas.training
- 類別 (Classes)
  - HyperparametersConfig
  - JaggedLRConfig
  - LrGroup

用於訓練超參數的 Pydantic 模型

訓練超參數配置子集

JaggedLR 配置子集，可用於 ReLoRA 訓練

自定義學習率組配置

**範例：**

範例 1 (python):
```python
utils.schemas.training.HyperparametersConfig()
```

範例 2 (python):
```python
utils.schemas.training.JaggedLRConfig()
```

Example 3 (python):
```python
utils.schemas.training.LrGroup()
```

---

## utils.quantization

**URL:** https://docs.axolotl.ai/docs/api/utils.quantization.html

**內容：**
- utils.quantization
- 函數 (Functions)
  - convert_qat_model
  - get_quantization_config
    - 參數 (Parameters)
    - 回傳 (Returns)
    - 拋出 (Raises)
  - prepare_model_for_qat
    - 參數 (Parameters)
    - 拋出 (Raises)

量化公用程式，包括使用 torchao 的 QAT 和 PTQ。

此函數將具有虛假量化層的 QAT 模型轉換回原始模型。

此函數用於構建訓練後量化 (post-training quantization) 配置。

此函數用於準備 QAT 模型，方法是將模型的線性層替換為虛假量化線性層，並可選地將嵌入權重替換為虛假量化嵌入權重。

此函數用於量化模型。

**範例：**

範例 1 (python):
```python
utils.quantization.convert_qat_model(model, quantize_embedding=False)
```

範例 2 (python):
```python
utils.quantization.get_quantization_config(
    weight_dtype,
    activation_dtype=None,
    group_size=None,
)
```

範例 3 (python):
```python
utils.quantization.prepare_model_for_qat(
    model,
    weight_dtype,
    group_size=None,
    activation_dtype=None,
    quantize_embedding=False,
)
```

範例 4 (python):
```python
utils.quantization.quantize_model(
    model,
    weight_dtype,
    group_size=None,
    activation_dtype=None,
    quantize_embedding=None,
)
```

---

## logging_config

**URL:** https://docs.axolotl.ai/docs/api/logging_config.html

**內容：**
- logging_config
- 類別 (Classes)
  - AxolotlLogger
  - AxolotlOrWarnErrorFilter
  - ColorfulFormatter
- 函數 (Functions)
  - configure_logging

Axolotl 的通用日誌紀錄模組。

對非 axolotl 紀錄器應用過濾的日誌紀錄器。

允許任何 WARNING 或更高等級（除非被 LOG_LEVEL 覆寫）。允許 axolotl.* 為 INFO 或更高等級（除非被 AXOLOTL_LOG_LEVEL 覆寫）。捨棄所有其他記錄（即預設捨棄非 axolotl.INFO, DEBUG 等）。

按日誌類型為日誌訊息新增著色的格式化程式

使用預設日誌紀錄進行配置

**範例：**

範例 1 (python):
```python
logging_config.AxolotlLogger(name, level=logging.NOTSET)
```

範例 2 (python):
```python
logging_config.AxolotlOrWarnErrorFilter(**kwargs)
```

範例 3 (python):
```python
logging_config.ColorfulFormatter()
```

範例 4 (python):
```python
logging_config.configure_logging()
```

---

## prompt_strategies.stepwise_supervised

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.stepwise_supervised.html

**內容：**
- prompt_strategies.stepwise_supervised
- 類別 (Classes)
  - StepwiseSupervisedPromptTokenizingStrategy

prompt_strategies.stepwise_supervised

用於逐步資料集的模組，通常包括提示和推理軌跡，以及（選填）用於獎勵建模的每步或每提示軌跡標籤。

用於監督式逐步資料集的標記化策略，通常用於 COT 推理。這些資料集應包含以下列：- prompt：提示文本 - completions：n 個補全步驟的列表 - labels：指示每一步「正確性」的 n 個標籤列表

**範例：**

範例 1 (python):
```python
prompt_strategies.stepwise_supervised.StepwiseSupervisedPromptTokenizingStrategy(
    tokenizer,
    sequence_len=2048,
    step_separator='\n',
    max_completion_length=None,
    train_on_last_step_only=False,
)
```

---

## utils.schemas.model

**URL:** https://docs.axolotl.ai/docs/api/utils.schemas.model.html

**內容：**
- utils.schemas.model
- 類別 (Classes)
  - ModelInputConfig
  - ModelOutputConfig
  - SpecialTokensConfig

用於模型輸入/輸出等配置的 Pydantic 模型

模型配置子集

模型儲存配置子集

特殊標記配置子集

**範例：**

範例 1 (python):
```python
utils.schemas.model.ModelInputConfig()
```

範例 2 (python):
```python
utils.schemas.model.ModelOutputConfig()
```

範例 3 (python):
```python
utils.schemas.model.SpecialTokensConfig()
```

---

## utils.schemas.enums

**URL:** https://docs.axolotl.ai/docs/api/utils.schemas.enums.html

**內容：**
- utils.schemas.enums
- 類別 (Classes)
  - ChatTemplate
  - CustomSupportedOptimizers
  - RLType
  - RingAttnFunc

Axolotl 輸入配置的列舉

聊天模板配置子集

自定義支援的優化器

RL 訓練器類型配置子集

支援的 ring-flash-attn 實作列舉類別

**範例：**

範例 1 (python):
```python
utils.schemas.enums.ChatTemplate()
```

範例 2 (python):
```python
utils.schemas.enums.CustomSupportedOptimizers()
```

範例 3 (python):
```python
utils.schemas.enums.RLType()
```

範例 4 (python):
```python
utils.schemas.enums.RingAttnFunc()
```

---

## core.trainers.trl

**URL:** https://docs.axolotl.ai/docs/api/core.trainers.trl.html

**內容：**
- core.trainers.trl
- 類別 (Classes)
  - AxolotlCPOTrainer
  - AxolotlKTOTrainer
  - AxolotlORPOTrainer
  - AxolotlPRMTrainer
  - AxolotlRewardTrainer

用於 TRL RL 訓練器的模組

為 axolotl 輔助程式擴展基礎 CPOTrainer

為 axolotl 輔助程式擴展基礎 KTOTrainer

為 axolotl 輔助程式擴展基礎 ORPOTrainer

為 axolotl 輔助程式擴展基礎 trl.PRMTrainer

為 axolotl 輔助程式擴展基礎 RewardTrainer

**範例：**

範例 1 (python):
```python
core.trainers.trl.AxolotlCPOTrainer(*args, **kwargs)
```

範例 2 (python):
```python
core.trainers.trl.AxolotlKTOTrainer(*args, **kwargs)
```

範例 3 (python):
```python
core.trainers.trl.AxolotlORPOTrainer(*args, **kwargs)
```

範例 4 (python):
```python
core.trainers.trl.AxolotlPRMTrainer(*args, **kwargs)
```

---

## utils.schedulers

**URL:** https://docs.axolotl.ai/docs/api/utils.schedulers.html

**內容：**
- utils.schedulers
- 類別 (Classes)
  - InterpolatingLogScheduler
  - JaggedLRRestartScheduler
  - RexLR
    - 參數 (Parameters)
- 函數 (Functions)
  - get_cosine_schedule_with_min_lr
    - 建立一個學習率排程，其具有
  - get_cosine_schedule_with_quadratic_warmup

用於自定義 LRScheduler 類別的模組

以對數方式插值學習率的排程器

包裝另一個排程器以應用每個 LoRA 重啟的學習率熱身。

Reflected Exponential (REX) 學習率排程器。

建立一個排程，其學習率按照餘弦函數的值從優化器中設定的初始學習率下降到 0，在此之前有一個熱身期，熱身期內學習率在 0 和優化器設定的初始學習率之間線性增加。

具有適當排程的 torch.optim.lr_scheduler.LambdaLR。

Continual Pre-Training of Large Language Models: How to (re)warm your model? (https://arxiv.org/pdf/2308.04014.pdf) 的實作。建立一個排程，其學習率按照餘弦函數的值從優化器中設定的初始學習率下降到 min_lr_ratio，直到 num_training_steps * constant_lr_ratio，之後回傳 min_rate 的常數值，在此之前有一個熱身期，熱身期內學習率在 0 和優化器設定的初始學習率之間線性增加。

具有適當排程的 torch.optim.lr_scheduler.LambdaLR。

**範例：**

範例 1 (python):
```python
utils.schedulers.InterpolatingLogScheduler(
    optimizer,
    num_steps,
    min_lr,
    max_lr,
    last_epoch=-1,
)
```

範例 2 (python):
```python
utils.schedulers.JaggedLRRestartScheduler(
    optimizer,
    inner_schedule,
    jagged_restart_steps,
    jagged_restart_warmup_steps,
    jagged_restart_anneal_steps=1,
    min_lr_scale=0.001,
)
```

範例 3 (python):
```python
utils.schedulers.RexLR(
    optimizer,
    max_lr,
    min_lr,
    total_steps=0,
    num_warmup_steps=0,
    last_step=0,
)
```

範例 4 (python):
```python
utils.schedulers.get_cosine_schedule_with_min_lr(
    optimizer,
    num_warmup_steps,
    num_training_steps,
    min_lr_ratio=0.0,
)
```

---

## cli.merge_lora

**URL:** https://docs.axolotl.ai/docs/api/cli.merge_lora.html

**內容：**
- cli.merge_lora
- 函數 (Functions)
  - do_cli
    - 參數 (Parameters)
    - 拋出 (Raises)
  - do_merge_lora
    - 參數 (Parameters)

將訓練好的 LoRA 合併到基礎模型的 CLI。

解析 axolotl 配置、CLI 參數，並呼叫 do_merge_lora。請注意，為了讓 LoRA 合併邏輯按預期運作，各種配置值將被覆寫（load_in_8bit=False, load_in4bit=False, flash_attention=False 等）。

對 axolotl 配置中給定的模型連同 LoRA 適配器呼叫 transformers 的 merge_and_unload，將它們結合成單個基礎模型。

**範例：**

範例 1 (python):
```python
cli.merge_lora.do_cli(config=Path('examples/'), **kwargs)
```

範例 2 (python):
```python
cli.merge_lora.do_merge_lora(cfg)
```

---

## prompt_strategies.alpaca_w_system

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.alpaca_w_system.html

**內容：**
- prompt_strategies.alpaca_w_system
- 類別 (Classes)
  - InstructionWSystemPromptTokenizingStrategy
  - OpenOrcaPromptTokenizingStrategy
  - OpenOrcaSystemDataPrompter
  - SystemDataPrompter

prompt_strategies.alpaca_w_system

帶有系統提示的 alpaca 指令資料集的提示策略載入器

用於指令式提示的標記化策略。

用於 OpenOrca 資料集的標記化策略

使用來自資料集的系統提示的 Alpaca 風格提示器，帶有 OpenOrca 提示

使用來自資料集的系統提示的 Alpaca 風格提示器

**範例：**

範例 1 (python):
```python
prompt_strategies.alpaca_w_system.InstructionWSystemPromptTokenizingStrategy(
    prompter,
    tokenizer,
    train_on_inputs=False,
    sequence_len=2048,
)
```

範例 2 (python):
```python
prompt_strategies.alpaca_w_system.OpenOrcaPromptTokenizingStrategy(
    prompter,
    tokenizer,
    train_on_inputs=False,
    sequence_len=2048,
)
```

範例 3 (python):
```python
prompt_strategies.alpaca_w_system.OpenOrcaSystemDataPrompter(
    prompt_style=PromptStyle.INSTRUCT.value,
)
```

範例 4 (python):
```python
prompt_strategies.alpaca_w_system.SystemDataPrompter(
    prompt_style=PromptStyle.INSTRUCT.value,
)
```

---

## loaders.patch_manager

**URL:** https://docs.axolotl.ai/docs/api/loaders.patch_manager.html

**內容：**
- loaders.patch_manager
- 類別 (Classes)
  - PatchManager
    - 屬性 (Attributes)
    - 方法 (Methods)
      - apply_post_model_load_patches
      - apply_post_plugin_pre_model_load_patches
      - apply_pre_model_load_patches

loaders.patch_manager

用於補充 axolotl.loaders.ModelLoader 的補丁管理器類別實作。

為各種修復和優化應用模型載入前和載入後的補丁。

在模型載入過程中管理補丁的應用。

應用需要模型實例的補丁。

根據配置應用插件後、模型載入前的補丁。

根據配置應用模型載入前的補丁。

**範例：**

範例 1 (python):
```python
loaders.patch_manager.PatchManager(cfg, model_config, inference=False)
```

範例 2 (python):
```python
loaders.patch_manager.PatchManager.apply_post_model_load_patches(model)
```

範例 3 (python):
```python
loaders.patch_manager.PatchManager.apply_post_plugin_pre_model_load_patches()
```

範例 4 (python):
```python
loaders.patch_manager.PatchManager.apply_pre_model_load_patches()
```

---

## utils.schemas.peft

**URL:** https://docs.axolotl.ai/docs/api/utils.schemas.peft.html

**內容：**
- utils.schemas.peft
- 類別 (Classes)
  - LoftQConfig
  - LoraConfig
  - PeftConfig
  - ReLoRAConfig

用於 PEFT 相關配置的 Pydantic 模型

LoftQ 配置子集

Peft / LoRA 配置子集

peftq 配置子集

ReLoRA 配置子集

**範例：**

範例 1 (python):
```python
utils.schemas.peft.LoftQConfig()
```

範例 2 (python):
```python
utils.schemas.peft.LoraConfig()
```

範例 3 (python):
```python
utils.schemas.peft.PeftConfig()
```

範例 4 (python):
```python
utils.schemas.peft.ReLoRAConfig()
```

---

## common.const

**URL:** https://docs.axolotl.ai/docs/api/common.const.html

**內容：**
- common.const

各種共用常數

---

## prompt_strategies.kto.user_defined

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.kto.user_defined.html

**內容：**
- prompt_strategies.kto.user_defined

prompt_strategies.kto.user_defined

使用者定義的 KTO 策略

---

## prompt_strategies.base

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.base.html

**內容：**
- prompt_strategies.base

prompt_strategies.base

基礎資料集轉換策略模組

---

## cli.delinearize_llama4

**URL:** https://docs.axolotl.ai/docs/api/cli.delinearize_llama4.html

**內容：**
- cli.delinearize_llama4
- 函數 (Functions)
  - do_cli
    - 參數 (Parameters)

cli.delinearize_llama4

用於反線性化量化/線性化 Llama-4 模型的 CLI 工具。

將已補丁的 HF 格式 Llama4 模型（具有分離的投影）轉換回原始 HF 格式（具有融合的投影）。

**範例：**

範例 1 (python):
```python
cli.delinearize_llama4.do_cli(model, output)
```

---

## integrations.base

**URL:** https://docs.axolotl.ai/docs/api/integrations.base.html

**內容：**
- integrations.base
- 類別 (Classes)
  - BaseOptimizerFactory
    - 方法 (Methods)
      - get_decay_parameter_names
  - BasePlugin
    - 注意 (Note)
    - 方法 (Methods)
      - add_callbacks_post_trainer
        - 參數 (Parameters)

所有插件的基礎類別。

插件是一段可重用、模組化且自包含的程式碼，用於擴展 Axolotl 的功能。插件可用於整合第三方模型、修改訓練過程或新增功能。

要建立新插件，您需要繼承 BasePlugin 類別並實作所需的方法。

建立自定義優化器的工廠基礎類別

獲取將應用權重衰減的所有參數名稱。

此函數以兩種方式過濾參數：1. 按層類型（ALL_LAYERNORM_LAYERS 中指定的層實例）2. 按參數名稱模式（包含「bias」或「norm」變體）

所有插件的基礎類別。定義插件介面。

插件是一段可重用、模組化且自包含的程式碼，用於擴展 Axolotl 的功能。插件可用於整合第三方模型、修改訓練過程或新增功能。

要建立新插件，您需要繼承 BasePlugin 類別並實作所需的方法。

插件方法包括：- register(cfg)：使用給定配置註冊插件。- load_datasets(cfg)：載入並預處理訓練資料集。- pre_model_load(cfg)：在載入模型前執行操作。- post_model_build(cfg, model)：在載入模型後、套用 LoRA 適配器前執行操作。- pre_lora_load(cfg, model)：在載入 LoRA 權重前執行操作。- post_lora_load(cfg, model)：在載入 LoRA 權重後執行操作。- post_model_load(cfg, model)：在載入模型後（包含任何適配器）執行操作。- post_trainer_create(cfg, trainer)：在建立訓練器後執行操作。- create_optimizer(cfg, trainer)：建立並回傳訓練用優化器。- create_lr_scheduler(cfg, trainer, optimizer, num_training_steps)：建立並回傳學習率排程器。- add_callbacks_pre_trainer(cfg, model)：在訓練前向訓練器新增回呼。- add_callbacks_post_trainer(cfg, trainer)：在建立訓練器後向其新增回呼。

在建立訓練器後向其新增回呼。這對於需要訪問模型或訓練器的回呼很有用。

在建立訓練器前設定回呼。

建立並回傳學習率排程器。

建立並回傳訓練用優化器。

回傳整理器 (collator) 的自定義類別。

回傳插件輸入參數的 Pydantic 模型。

回傳訓練器的自定義類別。

回傳要在 TrainingArgs 上設定的自定義訓練參數。

回傳插件訓練參數的 dataclass 模型。

載入並預處理訓練資料集。

在載入 LoRA 權重後執行操作。

在構建/載入模型後、套用任何適配器前執行操作。

在載入模型後執行操作。

在訓練完成後執行操作。

在訓練完成且模型卸載後執行操作。

在建立訓練器後執行操作。

在載入 LoRA 權重前執行操作。

在載入模型前執行操作。

使用給定的配置（作為未解析的字典）註冊插件。

PluginManager 類別負責載入和管理插件。它應該是一個單例 (singleton)，以便從程式碼庫的任何地方訪問。

關鍵方法包括：- get_instance()：獲取 PluginManager 單例實例的靜態方法。- register(plugin_name: str)：按名稱註冊新插件。- pre_model_load(cfg)：呼叫所有已註冊插件的 pre_model_load 方法。

呼叫所有已註冊插件的 add_callbacks_post_trainer 方法。

呼叫所有已註冊插件的 add_callbacks_pre_trainer 方法。

呼叫所有已註冊插件的 create_lr_scheduler 方法並回傳第一個非 None 的排程器。

呼叫所有已註冊插件的 create_optimizer 方法並回傳第一個非 None 的優化器。

呼叫所有已註冊插件的 get_collator_cls_and_kwargs 方法並回傳第一個非 None 的整理器類別。

參數：cfg (dict)：插件配置。is_eval (bool)：是否為評估切分。

回傳：object：整理器類別，如果未找到則為 None。

回傳所有已註冊插件輸入參數的 Pydantic 類別列表。

回傳 PluginManager 的單例實例。如果實例不存在則建立一個。

呼叫所有已註冊插件的 get_trainer_cls 方法並回傳第一個非 None 的訓練器類別。

呼叫所有已註冊插件的 get_training_args 方法並回傳組合後的訓練參數。

參數：cfg (dict)：插件配置。

回傳：object：訓練參數

回傳所有已註冊插件訓練參數混合類別的 dataclass 列表

回傳：list[str]：dataclass 列表

呼叫每個已註冊插件的 load_datasets 方法。

呼叫所有已註冊插件的 post_lora_load 方法。

在模型構建/載入後、套用任何適配器前，呼叫所有已註冊插件的 post_model_build 方法。

在模型載入後（包含任何適配器），呼叫所有已註冊插件的 post_model_load 方法。

呼叫所有已註冊插件的 post_train 方法。

呼叫所有已註冊插件的 post_train_unload 方法。

呼叫所有已註冊插件的 post_trainer_create 方法。

呼叫所有已註冊插件的 pre_lora_load 方法。

呼叫所有已註冊插件的 pre_model_load 方法。

按名稱註冊新插件。

根據給定的插件名稱載入插件。

插件名稱格式應為「module_name.class_name」。此函數將插件名稱分割為模組和類別，匯入模組，從模組獲取類別，並建立該類別的實例。

**範例：**

範例 1 (python):
```python
integrations.base.BaseOptimizerFactory()
```

範例 2 (python):
```python
integrations.base.BaseOptimizerFactory.get_decay_parameter_names(model)
```

範例 3 (python):
```python
integrations.base.BasePlugin()
```

範例 4 (python):
```python
integrations.base.BasePlugin.add_callbacks_post_trainer(cfg, trainer)
```

---

## prompt_strategies.chat_template

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.chat_template.html

**內容：**
- prompt_strategies.chat_template
- 類別 (Classes)
  - ChatTemplatePrompter
    - 方法 (Methods)
      - build_prompt
        - 參數 (Parameters)
  - ChatTemplateStrategy
    - 方法 (Methods)
      - find_first_eot_token
      - find_turn

prompt_strategies.chat_template

HF Chat Templates 提示策略

HF 聊天模板提示器

從對話構建提示。

用於指令式提示的標記化策略。

從 start_idx 開始，在 input_ids 中尋找第一個 EOT 標記。

定位對話中指定輪次的開始和結束索引。

可以處理單個提示或一批提示的公開方法。

用於聊天模板的 Mistral 提示器。

用於聊天模板的 Mistral 策略。

從 start_idx 開始，在 input_ids 中尋找第一個 EOT 標記。

根據配置載入聊天模板策略。

**範例：**

範例 1 (python):
```python
prompt_strategies.chat_template.ChatTemplatePrompter(
    tokenizer,
    chat_template,
    processor=None,
    max_length=2048,
    message_property_mappings=None,
    message_field_training=None,
    message_field_training_detail=None,
    field_messages='messages',
    field_system='system',
    field_tools='tools',
    field_thinking='reasoning_content',
    roles=None,
    template_thinking_key='reasoning_content',
    chat_template_kwargs=None,
    drop_system_message=False,
)
```

範例 2 (python):
```python
prompt_strategies.chat_template.ChatTemplatePrompter.build_prompt(
    conversation,
    add_generation_prompt=False,
    images=None,
    tools=None,
)
```

範例 3 (python):
```python
prompt_strategies.chat_template.ChatTemplateStrategy(
    prompter,
    tokenizer,
    train_on_inputs,
    sequence_len,
    roles_to_train=None,
    train_on_eos=None,
    train_on_eot=None,
    eot_tokens=None,
    split_thinking=False,
)
```

範例 4 (python):
```python
prompt_strategies.chat_template.ChatTemplateStrategy.find_first_eot_token(
    input_ids,
    start_idx,
)
```

---

## kernels.quantize

**URL:** https://docs.axolotl.ai/docs/api/kernels.quantize.html

**內容：**
- kernels.quantize
- 函數 (Functions)
  - dequantize
    - 參數 (Parameters)
    - 回傳 (Returns)
    - 拋出 (Raises)
    - 注意 (Note)

bitsandbytes 整合的反量化公用程式。

使用 bitsandbytes CUDA 核心進行快速 NF4 反量化。

使用 bitsandbytes 優化的 CUDA 實作對 NF4 格式的權重執行高效反量化。支援舊版列表和新版 QuantState 格式。

在較新版本的 bitsandbytes (>0.43.3) 中，使用 CUDA 串流以獲得更好效能。

**範例：**

範例 1 (python):
```python
kernels.quantize.dequantize(W, quant_state=None, out=None)
```

---

## integrations.spectrum.args

**URL:** https://docs.axolotl.ai/docs/api/integrations.spectrum.args.html

**內容：**
- integrations.spectrum.args
- 類別 (Classes)
  - SpectrumArgs

integrations.spectrum.args

處理 Spectrum 輸入參數的模組。

Spectrum 的輸入參數。

**範例：**

範例 1 (python):
```python
integrations.spectrum.args.SpectrumArgs()
```

---

## prompt_strategies.alpaca_chat

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.alpaca_chat.html

**內容：**
- prompt_strategies.alpaca_chat
- 類別 (Classes)
  - AlpacaChatPrompter
  - AlpacaConcisePrompter
  - AlpacaQAPromptTokenizingStrategy
  - CamelAIPromptTokenizingStrategy
  - NoSystemPrompter

prompt_strategies.alpaca_chat

Alpaca 提示策略類別模組

Alpaca 聊天提示器，擴展系統提示以獲取聊天指令回應

Alpaca 提示器，擴展系統提示以請求簡潔的聊天指令回應

AlpacaQA 的標記化策略

CamelAI 資料集的標記化策略

不含系統提示的空提示器

**範例：**

範例 1 (python):
```python
prompt_strategies.alpaca_chat.AlpacaChatPrompter()
```

範例 2 (python):
```python
prompt_strategies.alpaca_chat.AlpacaConcisePrompter(
    prompt_style=PromptStyle.INSTRUCT.value,
)
```

範例 3 (python):
```python
prompt_strategies.alpaca_chat.AlpacaQAPromptTokenizingStrategy(
    prompter,
    tokenizer,
    train_on_inputs=False,
    sequence_len=2048,
)
```

範例 4 (python):
```python
prompt_strategies.alpaca_chat.CamelAIPromptTokenizingStrategy(
    prompter,
    tokenizer,
    train_on_inputs=False,
    sequence_len=2048,
)
```

---

## utils.collators.core

(內容重複，略過)

---

## utils.collators.mamba

**URL:** https://docs.axolotl.ai/docs/api/utils.collators.mamba.html

**內容：**
- utils.collators.mamba
- 類別 (Classes)
  - MambaDataCollator

utils.collators.mamba

狀態空間模型 (Mamba) 的整理器

**範例：**

範例 1 (python):
```python
utils.collators.mamba.MambaDataCollator(tokenizer)
```

---

## prompt_strategies.messages.chat

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.messages.chat.html

**內容：**
- prompt_strategies.messages.chat
- 類別 (Classes)
  - ChatMessageDatasetWrappingStrategy

prompt_strategies.messages.chat

用於新內部訊息表示的聊天資料集包裝策略

用於新內部訊息表示的聊天資料集包裝策略

**範例：**

範例 1 (python):
```python
prompt_strategies.messages.chat.ChatMessageDatasetWrappingStrategy(
    processor,
    message_transform=None,
    formatter=None,
    **kwargs,
)
```

---

## train

**URL:** https://docs.axolotl.ai/docs/api/train.html

**內容：**
- train
- 函數 (Functions)
  - create_model_card
    - 參數 (Parameters)
  - execute_training
    - 參數 (Parameters)
  - handle_untrained_tokens_fix
    - 參數 (Parameters)
  - save_initial_configs
    - 參數 (Parameters)

準備並在資料集上訓練模型。也可以從模型進行推理或合併 lora

如果需要，為訓練好的模型建立模型卡 (model card)。

使用適當的 SDP 核心配置執行訓練過程。

如果配置了，對未訓練標記應用修復。

訓練前儲存初始配置。

根據配置和訓練設定儲存訓練好的模型。

根據配置載入標記器、處理器（用於多模態模型）和模型。

載入模型、標記器、訓練器等。封裝完整訓練器設定的輔助函數。

設定 Axolotl 徽章，並將 Axolotl 配置新增到模型卡（如果可用）。

如果需要，為 RL 訓練設定參考模型。

設定用於優雅終止的訊號處理器。

在給定資料集上訓練模型。

**範例：**

範例 1 (python):
```python
train.create_model_card(cfg, trainer)
```

範例 2 (python):
```python
train.execute_training(cfg, trainer, resume_from_checkpoint)
```

範例 3 (python):
```python
train.handle_untrained_tokens_fix(
    cfg,
    model,
    tokenizer,
    train_dataset,
    safe_serialization,
)
```

範例 4 (python):
```python
train.save_initial_configs(cfg, tokenizer, model, peft_config, processor)
```

---

## cli.utils.load

**URL:** https://docs.axolotl.ai/docs/api/cli.utils.load.html

**內容：**
- cli.utils.load
- 函數 (Functions)
  - load_model_and_tokenizer
    - 參數 (Parameters)
    - 回傳 (Returns)

用於模型、標記器等載入的公用程式。

載入給定 axolotl 配置中指定的模型、標記器和處理器的輔助函數。

**範例：**

範例 1 (python):
```python
cli.utils.load.load_model_and_tokenizer(cfg, inference=False)
```

---

## loaders.model

**URL:** https://docs.axolotl.ai/docs/api/loaders.model.html

**內容：**
- loaders.model
- 類別 (Classes)
  - ModelLoader
    - 載入過程包括
    - 屬性 (Attributes)
    - 方法 (Methods)
      - load
        - 回傳 (Returns)

模型載入器類別實作，用於載入、配置和補丁各種模型。

在模型載入期間管理模型配置、初始化和補丁的應用。

此類別編排了從配置到最終準備的載入模型的整個過程。它處理設備映射、量化、注意力機制、適配器整合和各種優化。

使用所有配置和補丁載入並準備模型。

**範例：**

範例 1 (python):
```python
loaders.model.ModelLoader(
    cfg,
    tokenizer,
    *,
    inference=False,
    reference_model=False,
    **kwargs,
)
```

範例 2 (python):
```python
loaders.model.ModelLoader.load()
```

---

## utils.distributed

**URL:** https://docs.axolotl.ai/docs/api/utils.distributed.html

**內容：**
- utils.distributed
- 函數 (Functions)
  - barrier
  - cleanup_distributed
  - compute_and_broadcast
  - gather_from_all_ranks
  - gather_scalar_from_all_ranks
  - is_distributed
  - is_main_process
    - 回傳 (Returns)

分佈式功能公用程式。

充當屏障 (barrier) 以等待所有進程。這可確保所有進程在繼續執行前都到達屏障。

如果 torch distributed 已初始化，則銷毀進程組。在訓練早期終止或訓練成功完成時呼叫。

僅在指定的 rank（預設為 0）上使用函數 'fn' 計算一個值。然後將該值廣播 (broadcast) 到所有其他 rank。

參數：- fn (callable)：計算值的函數。這不應有任何副作用。- rank (int, 選填)：計算值的 rank。預設為 0。

回傳：- 計算後的值（int 或 float）。

在所有 rank 上執行可呼叫物件 'fn'，並在指定的 rank 上收集結果。

參數：- fn (callable)：計算值的函數。這不應有任何副作用。- rank (int, 選填)：收集值的 rank。預設為 0。- world_size (int, 選填)：目前分佈式設定中的總進程數。

回傳：- 如果在收集 rank 上，則為來自所有 rank 的計算值列表，否則為 None。

在所有 rank 上執行可呼叫物件 'fn'，並在指定的 rank 上收集結果。

參數：- fn (callable)：計算值的函數。這不應有任何副作用。- rank (int, 選填)：收集值的 rank。預設為 0。- world_size (int, 選填)：目前分佈式設定中的總進程數。

回傳：- 如果在收集 rank 上，則為來自所有 rank 的計算值列表，否則為 None。

檢查分佈式訓練是否已初始化。

檢查目前進程是否為主進程 (main process)。如果不是分佈式模式，始終回傳 True。

當分佈式狀態未初始化時，我們使用較簡單的邏輯：僅在本地第 0 個 rank 上記錄日誌。

在所有 rank 上執行可呼叫物件 'fn1'，收集結果，使用 'fn2' 縮減 (reduce) 它們，然後將縮減後的結果廣播到所有 rank。

參數：- fn1 (callable)：在每個 rank 上計算值的函數。- fn2 (callable)：接收值列表並回傳單個值的縮減函數。- world_size (int, 選填)：目前分佈式設定中的總進程數。

回傳：- 縮減並廣播後的值。

執行包裝的上下文，使 rank 0 先於其他 rank 執行

**範例：**

範例 1 (python):
```python
utils.distributed.barrier()
```

範例 2 (python):
```python
utils.distributed.cleanup_distributed()
```

範例 3 (python):
```python
utils.distributed.compute_and_broadcast(fn)
```

範例 4 (python):
```python
utils.distributed.gather_from_all_ranks(fn, world_size=1)
```

---

## cli.config

**URL:** https://docs.axolotl.ai/docs/api/cli.config.html

**內容：**
- cli.config
- 函數 (Functions)
  - check_remote_config
    - 參數 (Parameters)
    - 回傳 (Returns)
    - 拋出 (Raises)
  - choose_config
    - 參數 (Parameters)
    - 回傳 (Returns)
    - 拋出 (Raises)

配置載入和處理。

首先，判斷傳入的配置是否為有效的 HTTPS URL。然後，嘗試請求它並解析其內容，首先作為 JSON，然後作為 YAML（優先選用 YAML）。最後，解析後的內容被寫入本地檔案並回傳其路徑。

用於選擇 axolotl 配置 YAML 檔案的輔助方法（僅考慮以 .yml 或 .yaml 結尾的檔案）。如果傳入路徑中存在多個配置文件，系統將提示使用者選擇一個。

載入儲存在 config 中的 axolotl 配置，對其進行驗證，並執行各種設定。

為給定配置註冊插件。

**範例：**

範例 1 (python):
```python
cli.config.check_remote_config(config)
```

範例 2 (python):
```python
cli.config.choose_config(path)
```

範例 3 (python):
```python
cli.config.load_cfg(config=Path('examples/'), **kwargs)
```

範例 4 (python):
```python
cli.config.prepare_plugins(cfg)
```

---

## cli.checks

**URL:** https://docs.axolotl.ai/docs/api/cli.checks.html

**內容：**
- cli.checks
- 函數 (Functions)
  - check_accelerate_default_config
  - check_user_token
    - 回傳 (Returns)
    - 拋出 (Raises)

Axolotl CLI 的各項檢查。

如果未找到 accelerate 配置文件，則記錄警告級別日誌。

檢查 HF 使用者資訊。如果 HF_HUB_OFFLINE=1 則跳過檢查。

**範例：**

範例 1 (python):
```python
cli.checks.check_accelerate_default_config()
```

範例 2 (python):
```python
cli.checks.check_user_token()
```

---

## prompt_strategies.llama2_chat

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.llama2_chat.html

**內容：**
- prompt_strategies.llama2_chat
- 類別 (Classes)
  - LLama2ChatTokenizingStrategy
  - Llama2ChatConversation
    - 方法 (Methods)
      - append_message
      - get_prompt
  - Llama2ChatPrompter

prompt_strategies.llama2_chat

用於微調 Llama2 聊天模型的提示策略，另請參閱 https://github.com/facebookresearch/llama/blob/6c7fe276574e78057f917549435a2554000a876d/llama/generation.py#L213 獲取參考實作。

此實作基於 Vicuna PR 和 fastchat 儲存庫，另請參閱：https://github.com/lm-sys/FastChat/blob/cdd7730686cb1bf9ae2b768ee171bdf7d1ff04f3/fastchat/conversation.py#L847

在 config.yml 中使用資料集類型： 「llama2_chat」 以使用此提示風格。

例如在 config.yml 中：

資料集本身應如下所示：

存放在 jsonl 檔案中。第一條訊息應來自人類 (human)，第二條來自 gpt。對於自定義系統訊息，第一個「from」可以是「system」（隨後是交替的「human」和「gpt」輪次）。

重要：如果您不確定自己在做什麼，請勿在 config.yml 中使用「special_tokens:」！

Llama2 提示的標記化策略。改編自 https://github.com/lm-sys/FastChat/blob/main/fastchat/train/train.py

管理提示模板並保留所有對話歷史記錄的類別。複製自 https://github.com/lm-sys/FastChat/blob/main/fastchat/conversation.py

附加新訊息。

獲取產生用的提示。

為 Llama2 模型產生提示的提示器。

**範例：**

範例 1 (unknown):
```unknown
datasets:
  - path: llama_finetune_train.jsonl
    type: llama2_chat
```

範例 2 (unknown):
```unknown
{'conversations':[{"from": "human", "value": "Who are you?"}, {"from": "gpt", "value": "I am Vicuna"},...]}
```

範例 3 (python):
```python
prompt_strategies.llama2_chat.LLama2ChatTokenizingStrategy(*args, **kwargs)
```

範例 4 (python):
```python
prompt_strategies.llama2_chat.Llama2ChatConversation(
    name='llama2',
    system="[INST] <<SYS>>\nYou are a helpful, respectful and honest assistant. Always answer as helpfully as possible, while being safe. Your answers should not include any harmful, unethical, racist, sexist, toxic, dangerous, or illegal content. Please ensure that your responses are socially unbiased and positive in nature.\n\nIf a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct. If you don't know the answer to a question, please don't share false information.\n<</SYS>>\n\n",
    roles=('[INST]', '[/INST]'),
    messages=list(),
    offset=0,
)
```

---

## cli.utils

**URL:** https://docs.axolotl.ai/docs/api/cli.utils.html

**內容：**
- cli.utils

axolotl.cli.utils 模組的初始化。

---

## cli.utils.args

**URL:** https://docs.axolotl.ai/docs/api/cli.utils.args.html

**內容：**
- cli.utils.args
- 函數 (Functions)
  - add_options_from_config
    - 參數 (Parameters)
    - 回傳 (Returns)
  - add_options_from_dataclass
    - 參數 (Parameters)
    - 回傳 (Returns)
  - filter_none_kwargs
    - 參數 (Parameters)

用於 axolotl CLI 參數的公用程式。

從 Pydantic 模型的欄位建立 Click 選項。

從 dataclass 的欄位建立 Click 選項。

包裝函數以移除值為 None 的關鍵字參數 (kwargs)。

**範例：**

範例 1 (python):
```python
cli.utils.args.add_options_from_config(config_class)
```

範例 2 (python):
```python
cli.utils.args.add_options_from_dataclass(config_class)
```

範例 3 (python):
```python
cli.utils.args.filter_none_kwargs(func)
```

---

## integrations.grokfast.optimizer

**URL:** https://docs.axolotl.ai/docs/api/integrations.grokfast.optimizer.html

**內容：**
- integrations.grokfast.optimizer

integrations.grokfast.optimizer

---

## core.builders.causal

**URL:** https://docs.axolotl.ai/docs/api/core.builders.causal.html

**內容：**
- core.builders.causal
- 類別 (Classes)
  - HFCausalTrainerBuilder

因果訓練器構建器 (Causal trainers builder)

使用 TRL 為因果模型和獎勵建模構建 HuggingFace 訓練參數/訓練器。

**範例：**

範例 1 (python):
```python
core.builders.causal.HFCausalTrainerBuilder(
    cfg,
    model,
    tokenizer,
    processor=None,
)
```

---

## prompt_strategies.dpo.user_defined

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.dpo.user_defined.html

**內容：**
- prompt_strategies.dpo.user_defined

prompt_strategies.dpo.user_defined

使用者定義的 DPO 策略

---

## cli.evaluate

**URL:** https://docs.axolotl.ai/docs/api/cli.evaluate.html

**內容：**
- cli.evaluate
- 函數 (Functions)
  - do_cli
    - 參數 (Parameters)
  - do_evaluate
    - 參數 (Parameters)

用於在模型上執行評估的 CLI。

解析 axolotl 配置、CLI 參數，並呼叫 do_evaluate。

透過首先載入 axolotl 配置中指定的資料集，然後呼叫 axolotl.evaluate.evaluate 來評估 transformers 模型，後者計算給定資料集的評估指標並將其寫入磁碟。

**範例：**

範例 1 (python):
```python
cli.evaluate.do_cli(config=Path('examples/'), **kwargs)
```

範例 2 (python):
```python
cli.evaluate.do_evaluate(cfg, cli_args)
```

---

## utils.schemas.utils

**URL:** https://docs.axolotl.ai/docs/api/utils.schemas.utils.html

**內容：**
- utils.schemas.utils
- 函數 (Functions)
  - handle_legacy_message_fields_logic
    - 參數 (Parameters)
    - 回傳 (Returns)
    - 拋出 (Raises)

用於 Axolotl Pydantic 模型的公用程式

處理舊版訊息欄位映射與新屬性映射系統之間的向後相容性。

以前，配置僅支援透過專用配置選項映射「role」和「content」欄位：- message_field_role：映射到 role 欄位 - message_field_content：映射到 content 欄位

新系統使用 message_property_mappings 以支援任意欄位映射：message_property_mappings: role: source_role_field content: source_content_field additional_field: source_field

**範例：**

範例 1 (python):
```python
utils.schemas.utils.handle_legacy_message_fields_logic(data)
```

---

## prompt_strategies.alpaca_instruct

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.alpaca_instruct.html

**內容：**
- prompt_strategies.alpaca_instruct

prompt_strategies.alpaca_instruct

載入 AlpacaInstructPromptTokenizingStrategy 類別的模組

---

## utils.callbacks.lisa

**URL:** https://docs.axolotl.ai/docs/api/utils.callbacks.lisa.html

**內容：**
- utils.callbacks.lisa

改編自 https://github.com/OptimalScale/LMFlow/pull/701 用於 HF transformers 和 Axolotl Arxiv: https://arxiv.org/abs/2403.17919 授權：Apache 2.0

---

## models.mamba.modeling_mamba

**URL:** https://docs.axolotl.ai/docs/api/models.mamba.modeling_mamba.html

**內容：**
- models.mamba.modeling_mamba

models.mamba.modeling_mamba

---

## prompt_strategies.metharme

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.metharme.html

**內容：**
- prompt_strategies.metharme
- 類別 (Classes)
  - MetharmePromptTokenizingStrategy
  - MetharmePrompter

prompt_strategies.metharme

包含 MetharmenPromptTokenizingStrategy 和 MetharmePrompter 類別的模組

Metharme 模型的標記化策略

Metharme 模型的提示器。

**範例：**

範例 1 (python):
```python
prompt_strategies.metharme.MetharmePromptTokenizingStrategy(
    prompter,
    tokenizer,
    train_on_inputs=False,
    sequence_len=2048,
)
```

範例 2 (python):
```python
prompt_strategies.metharme.MetharmePrompter(*args, **kwargs)
```

---

## core.trainers.mamba

**URL:** https://docs.axolotl.ai/docs/api/core.trainers.mamba.html

**內容：**
- core.trainers.mamba
- 類別 (Classes)
  - AxolotlMambaTrainer

用於 mamba 訓練器的模組

處理損失計算的 Mamba 特定訓練器

**範例：**

範例 1 (python):
```python
core.trainers.mamba.AxolotlMambaTrainer(
    *_args,
    bench_data_collator=None,
    eval_data_collator=None,
    dataset_tags=None,
    **kwargs,
)
```

---

## utils.ctx_managers.sequence_parallel

**URL:** https://docs.axolotl.ai/docs/api/utils.ctx_managers.sequence_parallel.html

**內容：**
- utils.ctx_managers.sequence_parallel
- 類別 (Classes)
  - AllGatherWithGrad
    - 方法 (Methods)
      - backward
        - 參數 (Parameters)
        - 回傳 (Returns)
      - forward
        - 參數 (Parameters)
        - 回傳 (Returns)

utils.ctx_managers.sequence_parallel

用於 Axolotl 訓練器序列平行管理器和公用程式的模組

用於 all-gather 以保留梯度的自定義 autograd 函數。

all-gather 操作的後向傳遞。

從完整梯度張量中提取對應於此 rank 原始輸入的梯度切片。

具有序列維度的數據 all-gather 的正向傳遞。

用於序列平行操作的上下文管理器。

此類別提供一個上下文，將在使用 pre-forward 掛鉤的模型正向傳遞期間自動應用序列平行，並使用 post-forward 掛鉤從序列平行組中收集輸出。

對批次應用序列平行切片。

針對整數 logits_to_keep 實作了特殊處理，這表示在產生期間僅保留序列中的最後 N 個標記。

**範例：**

範例 1 (python):
```python
utils.ctx_managers.sequence_parallel.AllGatherWithGrad()
```

範例 2 (python):
```python
utils.ctx_managers.sequence_parallel.AllGatherWithGrad.backward(
    ctx,
    grad_output,
)
```

範例 3 (python):
```python
utils.ctx_managers.sequence_parallel.AllGatherWithGrad.forward(
    ctx,
    input_tensor,
    group,
)
```

範例 4 (python):
```python
utils.ctx_managers.sequence_parallel.SequenceParallelContextManager(
    models,
    context_parallel_size,
    gradient_accumulation_steps,
    ring_attn_func,
    heads_k_stride,
    gather_outputs,
    device_mesh=None,
)
```

---

## utils.callbacks.qat

**URL:** https://docs.axolotl.ai/docs/api/utils.callbacks.qat.html

**內容：**
- utils.callbacks.qat
- 類別 (Classes)
  - QATCallback
- 函數 (Functions)
  - toggle_fake_quant
    - 參數 (Parameters)

HF Causal Trainer 的 QAT 回呼

切換模型虛假量化的回呼。

切換模型中任何虛假量化線性層或嵌入層的虛假量化。

**範例：**

範例 1 (python):
```python
utils.callbacks.qat.QATCallback(cfg)
```

範例 2 (python):
```python
utils.callbacks.qat.toggle_fake_quant(mod, enable)
```

---

## prompt_strategies.dpo.zephyr

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.dpo.zephyr.html

**內容：**
- prompt_strategies.dpo.zephyr

prompt_strategies.dpo.zephyr

Zephyr 的 DPO 策略

---

## kernels.utils

**URL:** https://docs.axolotl.ai/docs/api/kernels.utils.html

**內容：**
- kernels.utils

axolotl.kernels 子模組的公用程式。

---

## monkeypatch.multipack

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.multipack.html

**內容：**
- monkeypatch.multipack

monkeypatch.multipack

用於樣本打包 v2 的 multipack 補丁

---

## cli.main

**URL:** https://docs.axolotl.ai/docs/api/cli.main.html

**內容：**
- cli.main
- 函數 (Functions)
  - cli
  - evaluate
    - 參數 (Parameters)
  - fetch
    - 參數 (Parameters)
  - inference
    - 參數 (Parameters)
  - merge_lora

各種 axolotl 命令的 Click CLI 定義。

Axolotl CLI - 訓練和微調大型語言模型

獲取範例配置或其他資源。

可用目錄：- examples：範例配置文件 - deepspeed_configs：DeepSpeed 配置文件

使用訓練好的模型執行推理。

將訓練好的 LoRA 適配器合併到基礎模型中。

合併分片的 FSDP 模型權重。

在訓練前預處理資料集。

訓練或微調模型。

**範例：**

範例 1 (python):
```python
cli.main.cli()
```

範例 2 (python):
```python
cli.main.evaluate(ctx, config, launcher, **kwargs)
```

範例 3 (python):
```python
cli.main.fetch(directory, dest)
```

範例 4 (python):
```python
cli.main.inference(ctx, config, launcher, gradio, **kwargs)
```

---

## core.trainers.mixins.optimizer

**URL:** https://docs.axolotl.ai/docs/api/core.trainers.mixins.optimizer.html

**內容：**
- core.trainers.mixins.optimizer
- 類別 (Classes)
  - OptimizerInitMixin
  - OptimizerMixin

core.trainers.mixins.optimizer

用於 Axolotl 訓練器優化器混合類別的模組

為那些在建構子中不接受 optimizer_cls_and_kwargs 作為關鍵字參數的訓練器（主要是 TRL）處理通用優化器初始化邏輯的混合類別。

用於構建自定義優化器共用處理的混合類別

**範例：**

範例 1 (python):
```python
core.trainers.mixins.optimizer.OptimizerInitMixin(*args, **kwargs)
```

範例 2 (python):
```python
core.trainers.mixins.optimizer.OptimizerMixin()
```

---

## integrations.kd.trainer

**URL:** https://docs.axolotl.ai/docs/api/integrations.kd.trainer.html

**內容：**
- integrations.kd.trainer
- 類別 (Classes)
  - AxolotlKDTrainer
    - 方法 (Methods)
      - compute_loss

integrations.kd.trainer

用於知識蒸餾 (Knowledge Distillation, KD) 的自定義訓練器子類別

訓練器計算損失的方式。預設情況下，所有模型在第一個元素中回傳損失。

子類別化並覆寫以實現自定義行為。

**範例：**

範例 1 (python):
```python
integrations.kd.trainer.AxolotlKDTrainer(*args, **kwargs)
```

範例 2 (python):
```python
integrations.kd.trainer.AxolotlKDTrainer.compute_loss(
    model,
    inputs,
    return_outputs=False,
    num_items_in_batch=None,
)
```

---

## integrations.lm_eval.args

**URL:** https://docs.axolotl.ai/docs/api/integrations.lm_eval.args.html

**內容：**
- integrations.lm_eval.args
- 類別 (Classes)
  - LMEvalArgs

integrations.lm_eval.args

處理 lm eval harness 輸入參數的模組。

lm eval harness 的輸入參數

**範例：**

範例 1 (python):
```python
integrations.lm_eval.args.LMEvalArgs()
```

---

## integrations.cut_cross_entropy.args

**URL:** https://docs.axolotl.ai/docs/api/integrations.cut_cross_entropy.args.html

**內容：**
- integrations.cut_cross_entropy.args
- 類別 (Classes)
  - CutCrossEntropyArgs

integrations.cut_cross_entropy.args

處理 Cut Cross Entropy 輸入參數的模組。

Cut Cross Entropy 的輸入參數。

**範例：**

範例 1 (python):
```python
integrations.cut_cross_entropy.args.CutCrossEntropyArgs()
```

---

## monkeypatch.mistral_attn_hijack_flash

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.mistral_attn_hijack_flash.html

**內容：**
- monkeypatch.mistral_attn_hijack_flash

monkeypatch.mistral_attn_hijack_flash

用於 mistral 模型的 Flash attention monkey patch

---

## loaders.constants

**URL:** https://docs.axolotl.ai/docs/api/loaders.constants.html

**內容：**
- loaders.constants

axolotl.loaders 模組的共用常數

---

## utils.bench

**URL:** https://docs.axolotl.ai/docs/api/utils.bench.html

**內容：**
- utils.bench
- 函數 (Functions)
  - check_cuda_device

基準測試和測量公用程式

包裝一個函數，如果 cuda 不可用或設備為 auto，則回傳預設值而非執行包裝的函數 :param default_value: :return:

**範例：**

範例 1 (python):
```python
utils.bench.check_cuda_device(default_value)
```

---

## utils.trainer

**URL:** https://docs.axolotl.ai/docs/api/utils.trainer.html

**內容：**
- utils.trainer
- 函數 (Functions)
  - add_pose_position_ids
  - add_position_ids
  - drop_long_seq
  - setup_trainer
    - 參數 (Parameters)
    - 回傳 (Returns)

包含 Trainer 類別及相關函數的模組

使用 PoSE 技術透過隨機跳過上下文中的位置來擴展上下文長度。我們只想在 split_on_token_ids 列表中的標記前跳過。我們應嘗試隨機分配跳過，但最終的 position_ids 不需要是完整的 context_len。上下文中可能有多個輪次，因此我們希望確保考慮到每個樣本中剩餘的最大可能跳過次數。

處理單個範例和批次數據。- 單個範例：sample[‘input_ids’] 是 list[int] - 批次數據：sample[‘input_ids’] 是 list[list[int]]

捨棄序列長度太長 (> sequence_len) 或太短 (< min_sequence_len) 的樣本。

適用於單個範例 (list[int]) 或批次 (list[list[int]])。

用於實例化和構建（因果或 RLHF）訓練器的輔助方法。

**範例：**

範例 1 (python):
```python
utils.trainer.add_pose_position_ids(
    sample,
    max_context_len=32768,
    split_on_token_ids=None,
    chunks=2,
)
```

範例 2 (python):
```python
utils.trainer.add_position_ids(sample)
```

範例 3 (python):
```python
utils.trainer.drop_long_seq(sample, sequence_len=2048, min_sequence_len=2)
```

範例 4 (python):
```python
utils.trainer.setup_trainer(
    cfg,
    train_dataset,
    eval_dataset,
    model,
    tokenizer,
    processor,
    total_num_steps,
    model_ref=None,
    peft_config=None,
)
```

---

## utils.schemas.config

**URL:** https://docs.axolotl.ai/docs/api/utils.schemas.config.html

**內容：**
- utils.schemas.config
- 類別 (Classes)
  - AxolotlConfigWCapabilities
  - AxolotlInputConfig

包含用於配置的 Pydantic 模型的模組。

用於驗證 GPU 能力與配置選項的包裝器

所有配置選項的包裝器。

**範例：**

範例 1 (python):
```python
utils.schemas.config.AxolotlConfigWCapabilities()
```

範例 2 (python):
```python
utils.schemas.config.AxolotlInputConfig()
```

---

## cli.args

**URL:** https://docs.axolotl.ai/docs/api/cli.args.html

**內容：**
- cli.args
- 類別 (Classes)
  - EvaluateCliArgs
  - InferenceCliArgs
  - PreprocessCliArgs
  - QuantizeCliArgs
  - TrainerCliArgs
  - VllmServeCliArgs

用於 axolotl CLI 命令參數的模組。

包含 axolotl evaluate 命令 CLI 參數的 Dataclass。

包含 axolotl inference 命令 CLI 參數的 Dataclass。

包含 axolotl preprocess 命令 CLI 參數的 Dataclass。

包含 axolotl quantize 命令 CLI 參數的 Dataclass。

包含 axolotl train 命令 CLI 參數的 Dataclass。

包含 axolotl vllm-serve 命令 CLI 參數的 Dataclass。

**範例：**

範例 1 (python):
```python
cli.args.EvaluateCliArgs(
    debug=False,
    debug_text_only=False,
    debug_num_examples=0,
)
```

範例 2 (python):
```python
cli.args.InferenceCliArgs(prompter=None)
```

範例 3 (python):
```python
cli.args.PreprocessCliArgs(
    debug=False,
    debug_text_only=False,
    debug_num_examples=1,
    prompter=None,
    download=True,
    iterable=False,
)
```

範例 4 (python):
```python
cli.args.QuantizeCliArgs(
    base_model=None,
    weight_dtype=None,
    activation_dtype=None,
    quantize_embedding=None,
    group_size=None,
    output_dir=None,
    hub_model_id=None,
)
```

---

## common.architectures

**URL:** https://docs.axolotl.ai/docs/api/common.architectures.html

**內容：**
- common.architectures

架構相關的通用常數

---

## cli.merge_sharded_fsdp_weights

**URL:** https://docs.axolotl.ai/docs/api/cli.merge_sharded_fsdp_weights.html

**內容：**
- cli.merge_sharded_fsdp_weights
- 類別 (Classes)
  - BFloat16CastPlanner
- 函數 (Functions)
  - do_cli
    - 參數 (Parameters)
  - merge_fsdp_weights
    - 參數 (Parameters)
    - 拋出 (Raises)

cli.merge_sharded_fsdp_weights

將分片的 FSDP 模型 checkpoint 合併為單個組合 checkpoint 的 CLI。

在載入過程中即時將張量轉換為 bfloat16 的自定義規劃器。

解析 axolotl 配置、CLI 參數，並呼叫 merge_fsdp_weights。

將分片的 FSDP 模型 checkpoint 中的權重合併為單個組合 checkpoint。如果模型使用了 SHARDED_STATE_DICT 則應使用此項。如果開啟 safe_serialization 權重將儲存為 {output_path}/model.safetensors，否則儲存為 pytorch_model.bin。

注意：這是一個 CPU 密集型進程。

**範例：**

範例 1 (python):
```python
cli.merge_sharded_fsdp_weights.BFloat16CastPlanner()
```

範例 2 (python):
```python
cli.merge_sharded_fsdp_weights.do_cli(config=Path('examples/'), **kwargs)
```

範例 3 (python):
```python
cli.merge_sharded_fsdp_weights.merge_fsdp_weights(
    checkpoint_dir,
    output_path,
    safe_serialization=False,
    remove_checkpoint_dir=False,
)
```

---

## utils.data.streaming

**URL:** https://docs.axolotl.ai/docs/api/utils.data.streaming.html

**內容：**
- utils.data.streaming

針對串流資料集的特定數據處理。

---

## core.chat.format.chatml

**URL:** https://docs.axolotl.ai/docs/api/core.chat.format.chatml.html

**內容：**
- core.chat.format.chatml

core.chat.format.chatml

用於 MessageContents 的 ChatML 轉換函數

---

## prompt_strategies.kto.chatml

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.kto.chatml.html

**內容：**
- prompt_strategies.kto.chatml
- 函數 (Functions)
  - argilla_chat
  - intel
  - ultra

prompt_strategies.kto.chatml

用於 chatml 的 KTO 策略

用於 argilla/kto-mix-15k 對話

用於 Intel Orca KTO，例如：argilla/distilabel-intel-orca-kto

用於 ultrafeedback binarized 對話，例如：argilla/ultrafeedback-binarized-preferences-cleaned-kto

**範例：**

範例 1 (python):
```python
prompt_strategies.kto.chatml.argilla_chat(cfg, **kwargs)
```

範例 2 (python):
```python
prompt_strategies.kto.chatml.intel(cfg, **kwargs)
```

範例 3 (python):
```python
prompt_strategies.kto.chatml.ultra(cfg, **kwargs)
```

---

## utils.schemas.trl

**URL:** https://docs.axolotl.ai/docs/api/utils.schemas.trl.html

**內容：**
- utils.schemas.trl
- 類別 (Classes)
  - TRLConfig

用於 TRL 訓練器配置的 Pydantic 模型

**範例：**

範例 1 (python):
```python
utils.schemas.trl.TRLConfig()
```

---

## monkeypatch.llama_attn_hijack_xformers

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.llama_attn_hijack_xformers.html

**內容：**
- monkeypatch.llama_attn_hijack_xformers

monkeypatch.llama_attn_hijack_xformers

直接從 https://raw.githubusercontent.com/oobabooga/text-generation-webui/main/modules/llama_attn_hijack.py 複製程式碼並做了一些調整

---

## kernels.geglu

**URL:** https://docs.axolotl.ai/docs/api/kernels.geglu.html

**內容：**
- kernels.geglu
- 函數 (Functions)
  - geglu_backward
    - 參數 (Parameters)
    - 回傳 (Returns)
    - 注意 (Note)
  - geglu_forward
    - 參數 (Parameters)
    - 回傳 (Returns)

用於 GEGLU Triton 核心定義的模組。

參見「GLU Variants Improve Transformer」(https://arxiv.org/abs/2002.05202)。

感謝 unsloth (https://unsloth.ai/) 對此實作的啟發。

使用原地操作的 GEGLU 後向傳遞。

此函數原地修改其輸入張量以儲存結果。

**範例：**

範例 1 (python):
```python
kernels.geglu.geglu_backward(grad_output, gate, up)
```

範例 2 (python):
```python
kernels.geglu.geglu_forward(gate, up)
```

---

## utils.callbacks.profiler

**URL:** https://docs.axolotl.ai/docs/api/utils.callbacks.profiler.html

**內容：**
- utils.callbacks.profiler
- 類別 (Classes)
  - PytorchProfilerCallback

utils.callbacks.profiler

用於建立 pytorch 效能分析快照的 HF Trainer 回呼

PyTorch Profiler 回呼，用於在指定步驟建立 GPU 記憶體使用快照。

**範例：**

範例 1 (python):
```python
utils.callbacks.profiler.PytorchProfilerCallback(
    steps_to_profile=5,
    profiler_steps_start=0,
)
```

---

## kernels.lora

**URL:** https://docs.axolotl.ai/docs/api/kernels.lora.html

**內容：**
- kernels.lora
- 類別 (Classes)
  - LoRA_MLP
    - 方法 (Methods)
      - backward
        - 參數 (Parameters)
        - 回傳 (Returns)
      - forward
        - 參數 (Parameters)
        - 回傳 (Returns)

用於 Low-Rank Adaptation (LoRA) Triton 核心定義的模組。

參見「LoRA: Low-Rank Adaptation of Large Language Models」(https://arxiv.org/abs/2106.09685)。

感謝 unsloth (https://unsloth.ai/) 對此實作的啟發。

優化的 LoRA MLP 實作。

為 LoRA MLP 執行後向傳遞計算。

LoRA MLP 的正向傳遞。

優化的輸出投影 LoRA 實作。

為 LoRA 輸出投影計算梯度的後向傳遞。

帶有 LoRA 的輸出投影正向傳遞。

優化的 LoRA QKV 實作，支援量化。

實作了帶有 LoRA 的 query, key, value 投影的高效計算，支援量化和記憶體優化。

為 LoRA QKV 計算梯度的後向傳遞。

使用 LoRA 計算 Q, K, V 投影的正向傳遞。

對帶有 GEGLU 激活的 MLP 層套用 LoRA。

對帶有 SwiGLU 激活的 MLP 層套用 LoRA。

對輸出投影層套用 LoRA。

套用 LoRA 以計算 Query, Key, Value 投影。

從投影模組獲取 LoRA 參數。

高效的融合矩陣乘法 (matmul) + LoRA 計算。

**範例：**

範例 1 (python):
```python
kernels.lora.LoRA_MLP()
```

範例 2 (python):
```python
kernels.lora.LoRA_MLP.backward(ctx, grad_output)
```

範例 3 (python):
```python
kernels.lora.LoRA_MLP.forward(
    ctx,
    X,
    gate_weight,
    gate_bias,
    gate_quant,
    gate_A,
    gate_B,
    gate_scale,
    up_weight,
    up_bias,
    up_quant,
    up_A,
    up_B,
    up_scale,
    down_weight,
    down_bias,
    down_quant,
    down_A,
    down_B,
    down_scale,
    activation_fn,
    activation_fn_backward,
    inplace=True,
)
```

範例 4 (python):
```python
kernels.lora.LoRA_O()
```

---

## monkeypatch.trainer_fsdp_optim

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.trainer_fsdp_optim.html

**內容：**
- monkeypatch.trainer_fsdp_optim
- 函數 (Functions)
  - patch_training_loop_for_fsdp

monkeypatch.trainer_fsdp_optim

修正 trainer 4.47.0 中 FSDP 優化器儲存的問題

用於修復帶有優化器儲存的 FSDP 訓練迴圈的 monkeypatch

**範例：**

範例 1 (python):
```python
monkeypatch.trainer_fsdp_optim.patch_training_loop_for_fsdp()
```

---

## utils.schemas.multimodal

**URL:** https://docs.axolotl.ai/docs/api/utils.schemas.multimodal.html

**內容：**
- utils.schemas.multimodal
- 類別 (Classes)
  - MultiModalConfig
    - 方法 (Methods)
      - convert_image_resize_algorithm

utils.schemas.multimodal

用於多模態相關配置的 Pydantic 模型

多模態配置子集

將圖像調整大小演算法轉換為 PIL.Image.Resampling 列舉。

**範例：**

範例 1 (python):
```python
utils.schemas.multimodal.MultiModalConfig()
```

範例 2 (python):
```python
utils.schemas.multimodal.MultiModalConfig.convert_image_resize_algorithm(
    image_resize_algorithm,
)
```

---

## prompt_strategies.dpo.llama3

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.dpo.llama3.html

**內容：**
- prompt_strategies.dpo.llama3
- 函數 (Functions)
  - argilla_chat
  - icr
  - intel
  - ultra

prompt_strategies.dpo.llama3

用於 llama-3 聊天模板的 DPO 策略

用於 argilla/dpo-mix-7k 對話

用於包含 system, input, chosen, rejected 的資料集的 chatml 轉換，例如：https://huggingface.co/datasets/argilla/distilabel-intel-orca-dpo-pairs

用於 Intel Orca DPO 對

用於 ultrafeedback binarized 對話

**範例：**

範例 1 (python):
```python
prompt_strategies.dpo.llama3.argilla_chat(cfg, **kwargs)
```

範例 2 (python):
```python
prompt_strategies.dpo.llama3.icr(cfg, **kwargs)
```

範例 3 (python):
```python
prompt_strategies.dpo.llama3.intel(cfg, **kwargs)
```

範例 4 (python):
```python
prompt_strategies.dpo.llama3.ultra(cfg, **kwargs)
```

---

## core.chat.format.shared

**URL:** https://docs.axolotl.ai/docs/api/core.chat.format.shared.html

**內容：**
- core.chat.format.shared

core.chat.format.shared

格式轉換的共用函數

---

## monkeypatch.llama_expand_mask

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.llama_expand_mask.html

**內容：**
- monkeypatch.llama_expand_mask

monkeypatch.llama_expand_mask

根據 https://arxiv.org/pdf/2107.02027.pdf 第 3.2.2 節擴展二進制注意力遮罩

---

## core.chat.messages

**URL:** https://docs.axolotl.ai/docs/api/core.chat.messages.html

**內容：**
- core.chat.messages
- 類別 (Classes)
  - ChatFormattedChats
  - Chats
  - MessageContentTypes
  - MessageContents
  - MessageRoles
  - Messages
  - PreferenceChats
  - SpecialToken

聊天訊息的內部訊息表示

帶有格式化程式和可選輸入訓練的聊天格式化對話

聊天對話的頂層資料結構

文本、圖像、音訊、工具呼叫和工具回應的訊息內容類型

帶有類型、值、元數據、權重、換行符和內容結尾的訊息內容

系統、使用者、助理和工具的訊息角色

帶有角色、內容、元數據、權重和聊天格式化的訊息

聊天的偏好數據表示

字串起始和字串結束的特殊標記

帶有描述、函數和參數的工具

帶有名稱、參數和選填 ID 的工具呼叫內容

帶有名稱和參數的工具呼叫函數

帶有名稱、內容和選填 ID 的工具回應內容

**範例：**

範例 1 (python):
```python
core.chat.messages.ChatFormattedChats()
```

範例 2 (python):
```python
core.chat.messages.Chats()
```

範例 3 (python):
```python
core.chat.messages.MessageContentTypes()
```

範例 4 (python):
```python
core.chat.messages.MessageContents()
```

---

## core.datasets.transforms.chat_builder

**URL:** https://docs.axolotl.ai/docs/api/core.datasets.transforms.chat_builder.html

**內容：**
- core.datasets.transforms.chat_builder
- 函數 (Functions)
  - chat_message_transform_builder
    - 參數 (Parameters)
    - 回傳 (Returns)

core.datasets.transforms.chat_builder

此模組包含一個構建轉換的函數，該轉換接收資料集中的一列並將其轉換為聊天 (Chat) 物件。

構建一個接收資料集中一列並將其轉換為聊天物件的轉換

**範例：**

範例 1 (python):
```python
core.datasets.transforms.chat_builder.chat_message_transform_builder(
    train_on_inputs=False,
    conversations_field='messages',
    message_field_role=None,
    message_field_content=None,
    message_field_training=None,
)
```

---

## utils.chat_templates

**URL:** https://docs.axolotl.ai/docs/api/utils.chat_templates.html

**內容：**
- utils.chat_templates

此模組提供根據使用者選擇選取聊天模板的功能。這些模板用於格式化對話中的訊息。

---

## core.trainers.dpo.trainer

**URL:** https://docs.axolotl.ai/docs/api/core.trainers.dpo.trainer.html

**內容：**
- core.trainers.dpo.trainer
- 類別 (Classes)
  - AxolotlDPOTrainer
    - 方法 (Methods)
      - push_to_hub

core.trainers.dpo.trainer

Axolotl 的 DPO 訓練器

為 axolotl 輔助程式擴展基礎 DPOTrainer。

覆寫 push_to_hub 方法，以便在將模型推送到 Hub 時強制新增標籤。詳情請參閱 ~transformers.Trainer.push_to_hub。

**範例：**

範例 1 (python):
```python
core.trainers.dpo.trainer.AxolotlDPOTrainer(*args, dataset_tags=None, **kwargs)
```

範例 2 (python):
```python
core.trainers.dpo.trainer.AxolotlDPOTrainer.push_to_hub(*args, **kwargs)
```

---

## monkeypatch.gradient_checkpointing.offload_disk

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.gradient_checkpointing.offload_disk.html

**內容：**
- monkeypatch.gradient_checkpointing.offload_disk
- 類別 (Classes)
  - Disco
    - 方法 (Methods)
      - backward
      - forward
      - get_instance
  - DiskOffloadManager
    - 方法 (Methods)
      - cleanup

monkeypatch.gradient_checkpointing.offload_disk

DISCO - 基於磁碟的儲存與優化預取檢查點 (DIsk-based Storage and Checkpointing with Optimized prefetching)

Disco：具有優化預取的進階磁碟型梯度檢查點。

從磁碟載入激活函數並進行預取的後向傳遞

異步將激活函數卸載到磁碟的正向傳遞

獲取或建立卸載管理器

管理卸載的張量並在單獨的執行緒中處理預取。包含防止競爭條件的同步機制。

清理所有臨時檔案並停止預取執行緒，並進行適當的同步

清理特定張量檔案，在其使用後

從磁碟或預取快取載入張量，並進行適當的同步

異步將張量儲存到磁碟並回傳檔案路徑，具有執行緒安全操作

觸發後續 N 個張量的預取，並進行適當的同步

等待張量儲存到磁碟

**範例：**

範例 1 (python):
```python
monkeypatch.gradient_checkpointing.offload_disk.Disco()
```

範例 2 (python):
```python
monkeypatch.gradient_checkpointing.offload_disk.Disco.backward(
    ctx,
    *grad_outputs,
)
```

範例 3 (python):
```python
monkeypatch.gradient_checkpointing.offload_disk.Disco.forward(
    ctx,
    forward_function,
    hidden_states,
    *args,
    prefetch_size=1,
    prefetch_to_gpu=True,
    save_workers=4,
)
```

範例 4 (python):
```python
monkeypatch.gradient_checkpointing.offload_disk.Disco.get_instance(
    prefetch_size=1,
    prefetch_to_gpu=True,
    save_workers=4,
)
```

---

## utils.samplers.multipack

**URL:** https://docs.axolotl.ai/docs/api/utils.samplers.multipack.html

**內容：**
- utils.samplers.multipack
- 類別 (Classes)
  - MultipackBatchSampler
    - 方法 (Methods)
      - efficiency
      - gather_efficiency
        - 回傳 (Returns)
      - gather_len_batches
      - generate_batches
        - 參數 (Parameters)

utils.samplers.multipack

Multipack 批次取樣器 - 一種高效的批次取樣器，用於將變長序列打包到固定容量的批次中，以優化記憶體使用和訓練吞吐量。

用於變長序列高效打包的批次取樣器類別

此取樣器將序列打包到固定容量的箱子（批次）中，透過減少填補來最大化 GPU 記憶體利用率和訓練吞吐量。

它支援平行打包（使用 FFD 演算法）和順序打包（保留原始序列順序）。

計算打包效率（使用的標記數與總標記槽位數的比例）。越高越好 - 1.0 表示完美打包且無空間浪費。

在所有分佈式 rank 之間收集並同步打包效率估計值。

在所有分佈式 rank 之間收集並同步批次計數。回傳任何 rank 上可用的最小批次數。

產生用於訓練的打包批次。

設定 epoch 編號，用於跨 epoch 的可重複打亂

保留範例順序的順序分配器。

首次適應遞減 (First-fit-decreasing) 箱子打包演算法檢查。

檢查具有給定長度的序列是否能裝入指定數量的箱子。

使用首次適應遞減演算法將一組序列打包到箱子中。

使用平行處理將序列打包到箱子中。

回傳：箱子列表，每個箱子包含分配給它的序列索引。

**範例：**

範例 1 (python):
```python
utils.samplers.multipack.MultipackBatchSampler(
    sampler,
    batch_size,
    batch_max_len,
    lengths,
    packing_efficiency_estimate=1.0,
    drop_last=True,
    num_count_samples=4,
    sequential=False,
    group_size=100000,
    bin_size=200,
    num_processes=None,
    safe_mode=True,
    mp_start_method='fork',
    **kwargs,
)
```

範例 2 (python):
```python
utils.samplers.multipack.MultipackBatchSampler.efficiency()
```

範例 3 (python):
```python
utils.samplers.multipack.MultipackBatchSampler.gather_efficiency()
```

範例 4 (python):
```python
utils.samplers.multipack.MultipackBatchSampler.gather_len_batches(num)
```

---

## core.trainers.mixins.scheduler

**URL:** https://docs.axolotl.ai/docs/api/core.trainers.mixins.scheduler.html

**內容：**
- core.trainers.mixins.scheduler
- 類別 (Classes)
  - SchedulerMixin
    - 方法 (Methods)
      - create_scheduler
        - 參數 (Parameters)

core.trainers.mixins.scheduler

用於 Axolotl 訓練器排程器混合類別的模組

用於 CausalTrainer 中排程器設定的混合類別。

設定排程器。訓練器的優化器必須在呼叫此方法前已設定好，或作為參數傳入。

**範例：**

範例 1 (python):
```python
core.trainers.mixins.scheduler.SchedulerMixin()
```

範例 2 (python):
```python
core.trainers.mixins.scheduler.SchedulerMixin.create_scheduler(
    num_training_steps,
    optimizer=None,
)
```

---

## utils.collators.batching

**URL:** https://docs.axolotl.ai/docs/api/utils.collators.batching.html

**內容：**
- utils.collators.batching
- 類別 (Classes)
  - BatchSamplerDataCollatorForSeq2Seq
  - DataCollatorForSeq2Seq
    - 參數 (Parameters)
  - PretrainingBatchSamplerDataCollatorForSeq2Seq
  - V2BatchSamplerDataCollatorForSeq2Seq

utils.collators.batching

用於 Axolotl 填補標籤和打包序列 position_ids 的數據整理器

專用於使用 BatchSampler 的 multipack 整理器

將動態填補接收到的輸入，以及標籤和 position_ids 的數據整理器

專用於使用 BatchSampler 的 multipack 整理器

專用於使用 BatchSampler 的 multipack 整理器

**範例：**

範例 1 (python):
```python
utils.collators.batching.BatchSamplerDataCollatorForSeq2Seq(
    tokenizer,
    model=None,
    padding=True,
    max_length=None,
    pad_to_multiple_of=None,
    label_pad_token_id=-100,
    position_pad_token_id=0,
    return_tensors='pt',
)
```

範例 2 (python):
```python
utils.collators.batching.DataCollatorForSeq2Seq(
    tokenizer,
    model=None,
    padding=True,
    max_length=None,
    pad_to_multiple_of=None,
    label_pad_token_id=-100,
    position_pad_token_id=0,
    return_tensors='pt',
)
```

範例 3 (python):
```python
utils.collators.batching.PretrainingBatchSamplerDataCollatorForSeq2Seq(
    *args,
    multipack_attn=True,
    **kwargs,
)
```

範例 4 (python):
```python
utils.collators.batching.V2BatchSamplerDataCollatorForSeq2Seq(
    tokenizer,
    model=None,
    padding=True,
    max_length=None,
    pad_to_multiple_of=None,
    label_pad_token_id=-100,
    position_pad_token_id=0,
    return_tensors='pt',
    squash_position_ids=False,
)
```

---

## prompt_strategies.orcamini

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.orcamini.html

**內容：**
- prompt_strategies.orcamini
- 類別 (Classes)
  - OrcaMiniPrompter

prompt_strategies.orcamini

用於微調 Orca Mini (v2) 模型的提示策略，另請參閱 https://huggingface.co/psmathur/orca_mini_v2_7b 獲取更多資訊

在 config.yml 中使用資料集類型： orcamini 以使用此提示風格。

與 alpaca_w_system.open_orca 資料集類型相比，此類型使用「### System:」指定系統提示。

如果不做進一步調整，則不適合/未經多輪對話測試。

針對 Orca Mini (v2) 資料集調整後的提示器

**範例：**

範例 1 (python):
```python
prompt_strategies.orcamini.OrcaMiniPrompter(
    prompt_style=PromptStyle.INSTRUCT.value,
)
```

---

## prompt_strategies.dpo.chat_template

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.dpo.chat_template.html

**內容：**
- prompt_strategies.dpo.chat_template
- 函數 (Functions)
  - argilla_chat
    - 參數 (Parameters)
    - 回傳 (Returns)
    - 資料集格式 (Dataset format)

prompt_strategies.dpo.chat_template

使用標記器聊天模板的 DPO 提示策略。

用於 argilla 風格資料集的 DPO 聊天模板策略。

用於 argilla 風格資料集，其中 chosen/rejected 包含完整對話而非單個回應訊息。從 chosen 欄位提取對話歷史紀錄，並使用配置的聊天模板格式化 chosen/rejected 回應。

{ “chosen”: [ {“role”: “user”, “content”: “…”}, {“role”: “assistant”, “content”: “…”} ], “rejected”: [ {“role”: “user”, “content”: “…”}, {“role”: “assistant”, “content”: “…”} ] }

**範例：**

範例 1 (python):
```python
prompt_strategies.dpo.chat_template.argilla_chat(cfg, dataset_idx=0, **kwargs)
```

---

## monkeypatch.relora

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.relora.html

**內容：**
- monkeypatch.relora
- 類別 (Classes)
  - ReLoRACallback

實作了來自 https://arxiv.org/abs/2307.05695 的 ReLoRA 訓練程序，不包括初始的全量微調。

將 LoRA 權重合併到基礎模型並儲存全量權重 checkpoint 的回呼

**範例：**

範例 1 (python):
```python
monkeypatch.relora.ReLoRACallback(cfg)
```

---

## monkeypatch.transformers_fa_utils

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.transformers_fa_utils.html

**內容：**
- monkeypatch.transformers_fa_utils
- 函數 (Functions)
  - fixed_fa_peft_integration_check
    - 參數 (Parameters)

monkeypatch.transformers_fa_utils

參見 https://github.com/huggingface/transformers/pull/35834

為了訓練穩定性，PEFT 通常將層正規化 (layer norms) 轉換為 float32，因此輸入隱藏狀態會被靜默轉換為 float32。因此，我們需要將它們轉換回 float16 / bfloat16 以確保一切如期運作。這可能會降低訓練和推理速度，因此建議不要轉換 LayerNorms！

**範例：**

範例 1 (python):
```python
monkeypatch.transformers_fa_utils.fixed_fa_peft_integration_check(
    query,
    key,
    value,
    target_dtype=None,
    preferred_dtype=None,
)
```

---

## utils.collators.mm_chat

**URL:** https://docs.axolotl.ai/docs/api/utils.collators.mm_chat.html

**內容：**
- utils.collators.mm_chat
- 類別 (Classes)
  - MultiModalChatDataCollator

utils.collators.mm_chat

用於多模態聊天訊息和打包的整理器

多模態聊天訊息的整理器

**範例：**

範例 1 (python):
```python
utils.collators.mm_chat.MultiModalChatDataCollator(
    tokenizer,
    processing_strategy,
    packing=False,
    return_tensors='pt',
    padding=True,
    pad_to_multiple_of=None,
)
```

---

## utils.lora

**URL:** https://docs.axolotl.ai/docs/api/utils.lora.html

**內容：**
- utils.lora
- 函數 (Functions)
  - get_lora_merged_state_dict
    - 參數 (Parameters)
    - 回傳 (Returns)

獲取合併後 LoRA 模型狀態字典的模組

建立並回傳一個狀態字典 (state_dict)，其中已將 LoRA 增量合併到基礎模型的權重中，而不修改模型本身。

**範例：**

範例 1 (python):
```python
utils.lora.get_lora_merged_state_dict(model)
```

---

## utils.model_shard_quant

**URL:** https://docs.axolotl.ai/docs/api/utils.model_shard_quant.html

**內容：**
- utils.model_shard_quant
- 函數 (Functions)
  - load_and_quantize

utils.model_shard_quant

處理在 CPU/meta 設備上為 FSDP 載入模型的模組

將值張量載入到模組的子模組中，可選地跳過 skip_names 並轉換為特定資料類型 (dtype)。

在設備上量化 Params4bit，然後如果 to_cpu=True 則放置於 「cpu」，如果 to_meta=True 則放置於 「meta」。

**範例：**

範例 1 (python):
```python
utils.model_shard_quant.load_and_quantize(
    module,
    name,
    value,
    device=None,
    dtype=None,
    skip_names=None,
    to_cpu=False,
    to_meta=False,
    verbose=False,
    quant_method='bnb',
)
```

---

## monkeypatch.gradient_checkpointing.offload_cpu

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.gradient_checkpointing.offload_cpu.html

**內容：**
- monkeypatch.gradient_checkpointing.offload_cpu
- 類別 (Classes)
  - CPU_Offloaded_Gradient_Checkpointer

monkeypatch.gradient_checkpointing.offload_cpu

CPU 卸載檢查點 (CPU offloaded checkpointing)

透過智慧地卸載到 RAM 來節省 VRAM。對效能影響微乎其微，因為我們透過非阻塞呼叫來屏蔽移動。

**範例：**

範例 1 (python):
```python
monkeypatch.gradient_checkpointing.offload_cpu.CPU_Offloaded_Gradient_Checkpointer(
)
```

---

## core.builders.base

**URL:** https://docs.axolotl.ai/docs/api/core.builders.base.html

**內容：**
- core.builders.base
- 類別 (Classes)
  - TrainerBuilderBase
    - 方法 (Methods)
      - get_post_trainer_create_callbacks

訓練器構建器的基礎類別

訓練器構建器的基礎類別。

在建立訓練器後新增的回呼，通常是因為這些回呼需要訪問訓練器

**範例：**

範例 1 (python):
```python
core.builders.base.TrainerBuilderBase(cfg, model, tokenizer, processor=None)
```

範例 2 (python):
```python
core.builders.base.TrainerBuilderBase.get_post_trainer_create_callbacks(trainer)
```

---

## core.builders.rl

**URL:** https://docs.axolotl.ai/docs/api/core.builders.rl.html

**內容：**
- core.builders.rl
- 類別 (Classes)
  - HFRLTrainerBuilder

RLHF 訓練器構建器

基於 TRL 的 RLHF 訓練器（如 DPO）的訓練器工廠類別

**範例：**

範例 1 (python):
```python
core.builders.rl.HFRLTrainerBuilder(cfg, model, tokenizer, processor=None)
```

---

## utils.schemas.integrations

**URL:** https://docs.axolotl.ai/docs/api/utils.schemas.integrations.html

**內容：**
- utils.schemas.integrations
- 類別 (Classes)
  - CometConfig
  - GradioConfig
  - LISAConfig
  - MLFlowConfig
  - OpenTelemetryConfig
  - RayConfig
  - WandbConfig

用於 Axolotl 整合的 Pydantic 模型

Comet 配置子集

Gradio 配置子集

LISA 配置子集

MLFlow 配置子集

OpenTelemetry 配置子集

Ray 啟動器配置子集

Wandb 配置子集

**範例：**

範例 1 (python):
```python
utils.schemas.integrations.CometConfig()
```

範例 2 (python):
```python
utils.schemas.integrations.GradioConfig()
```

範例 3 (python):
```python
utils.schemas.integrations.LISAConfig()
```

範例 4 (python):
```python
utils.schemas.integrations.MLFlowConfig()
```

---

## utils.data.sft

**URL:** https://docs.axolotl.ai/docs/api/utils.data.sft.html

**內容：**
- utils.data.sft
- 函數 (Functions)
  - prepare_datasets
    - 參數 (Parameters)
    - 回傳 (Returns)

針對 SFT 的數據處理。

根據配置準備訓練和評估資料集。

**範例：**

範例 1 (python):
```python
utils.data.sft.prepare_datasets(cfg, tokenizer, processor=None)
```

---

## integrations.liger.args

**URL:** https://docs.axolotl.ai/docs/api/integrations.liger.args.html

**內容：**
- integrations.liger.args
- 類別 (Classes)
  - LigerArgs

integrations.liger.args

處理 LIGER 輸入參數的模組。

LIGER 的輸入參數。

**範例：**

範例 1 (python):
```python
integrations.liger.args.LigerArgs()
```

---

## monkeypatch.mixtral

**URL:** https://docs.axolotl.ai/docs/api/monkeypatch.mixtral.html

**內容：**
- monkeypatch.mixtral

支援 mixtral 多重打包的補丁

---

## cli.preprocess

**URL:** https://docs.axolotl.ai/docs/api/cli.preprocess.html

**內容：**
- cli.preprocess
- 函數 (Functions)
  - do_cli
    - 參數 (Parameters)
  - do_preprocess
    - 參數 (Parameters)

執行資料集預處理的 CLI。

解析 axolotl 配置、CLI 參數，並呼叫 do_preprocess。

預處理 axolotl 配置中指定的資料集。

**範例：**

範例 1 (python):
```python
cli.preprocess.do_cli(config=Path('examples/'), **kwargs)
```

範例 2 (python):
```python
cli.preprocess.do_preprocess(cfg, cli_args)
```

---

## prompt_strategies.kto.llama3

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.kto.llama3.html

**內容：**
- prompt_strategies.kto.llama3
- 函數 (Functions)
  - argilla_chat
  - intel
  - ultra

prompt_strategies.kto.llama3

用於 llama-3 聊天模板的 KTO 策略

用於 argilla/kto-mix-15k 對話

用於 Intel Orca KTO，例如：argilla/distilabel-intel-orca-kto

用於 ultrafeedback binarized 對話，例如：argilla/ultrafeedback-binarized-preferences-cleaned-kto

**範例：**

範例 1 (python):
```python
prompt_strategies.kto.llama3.argilla_chat(cfg, **kwargs)
```

範例 2 (python):
```python
prompt_strategies.kto.llama3.intel(cfg, **kwargs)
```

範例 3 (python):
```python
prompt_strategies.kto.llama3.ultra(cfg, **kwargs)
```

---

## prompt_strategies.orpo.chat_template

**URL:** https://docs.axolotl.ai/docs/api/prompt_strategies.orpo.chat_template.html

**內容：**
- prompt_strategies.orpo.chat_template
- 類別 (Classes)
  - Message
  - MessageList
  - ORPODatasetParsingStrategy
    - 方法 (Methods)
      - get_chosen_conversation_thread
      - get_prompt
      - get_rejected_conversation_thread
  - ORPOPrompter

prompt_strategies.orpo.chat_template

用於 ORPO 的 chatml 提示標記化策略

將 chosen rejected 資料集解析為訊息列表的策略

資料集結構映射

映射數據以提取直到最後一輪的所有內容

資料集結構映射

用於 ORPO 的單輪提示器

rejected_input_ids input_ids rejected_attention_mask attention_mask rejected_labels labels

用於包含 system, input, chosen, rejected 的資料集的 chatml 轉換

**範例：**

範例 1 (python):
```python
prompt_strategies.orpo.chat_template.Message()
```

範例 2 (python):
```python
prompt_strategies.orpo.chat_template.MessageList()
```

範例 3 (python):
```python
prompt_strategies.orpo.chat_template.ORPODatasetParsingStrategy()
```

範例 4 (python):
```python
prompt_strategies.orpo.chat_template.ORPODatasetParsingStrategy.get_chosen_conversation_thread(
    prompt,
)
```

---

## loaders.processor

**URL:** https://docs.axolotl.ai/docs/api/loaders.processor.html

**內容：**
- loaders.processor

多模態模型的處理器載入功能

---

## utils.callbacks.comet_

**URL:** https://docs.axolotl.ai/docs/api/utils.callbacks.comet_.html

**內容：**
- utils.callbacks.comet_
- 類別 (Classes)
  - SaveAxolotlConfigtoCometCallback

utils.callbacks.comet_

用於訓練器回呼的 Comet 模組

將 axolotl 配置儲存到 comet 的回呼

**範例：**

範例 1 (python):
```python
utils.callbacks.comet_.SaveAxolotlConfigtoCometCallback(axolotl_config_path)
```

---
