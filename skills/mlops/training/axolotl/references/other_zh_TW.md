# Axolotl - 其他 (Other)

**頁數：** 26

---

## 混合精度訓練 (Mixed Precision Training)

**URL:** https://docs.axolotl.ai/docs/mixed_precision.html

**內容：**
- 混合精度訓練
- 1 FP16 混合精度
  - 1.1 概覽
  - 1.2 配置
  - 1.3 FP16 考量事項
- 2 BF16 混合精度
  - 2.1 概覽
  - 2.2 配置
- 3 FP8 混合精度
  - 3.1 什麼是 FP8？

混合精度訓練使用較低精度的資料類型來減少記憶體使用量並提高訓練速度，同時保持模型品質。Axolotl 支援多種混合精度格式：

FP16 是傳統的半精度格式，受舊型 GPU 支援，但數值穩定性可能不如 BF16。

BF16 (Brain Float 16) 提供比 FP16 更好的數值穩定性，是現代 GPU 推薦的混合精度格式。它提供與 FP32 相同的動態範圍，但僅使用一半的記憶體。

FP8 支援目前處於實驗階段，需要相容的硬體（H100, H200）以及帶有 TorchAO 的最新 PyTorch 版本。

FP8 (8-bit floating point) 與 FP16/BF16 相比可以顯著節省時間，同時保持訓練穩定性。Axolotl 的實作使用了 PyTorch 的 TorchAO 函式庫，並採用「tensorwise」縮放策略。

新增至您的 YAML 配置：

torch.compile 對於 FP8 效能至關重要

FP8 訓練需要 torch_compile: true 才能看到顯著的速度提升。如果沒有編譯，FP8 實際上可能比 FP16/BF16 更慢且使用更多記憶體。

對於 FSDP (Fully Sharded Data Parallel) 訓練：

務必驗證您的混合精度設定：

請參閱 examples/llama-3/3b-fp8-fsdp2.yaml 以獲取優化的範例配置。對於相對較小（3B 參數）的模型，啟用 FP8 混合精度 + FP8 all-gather 訓練，其每秒迭代次數比 BF16 快約 10%。

有關多 GPU 訓練的更多資訊，請參閱我們的「多 GPU 指南」。

**範例：**

範例 1 (yaml):
```yaml
# 自動 BF16 偵測 (推薦)
bf16: auto

# 或明確啟用
bf16: true

# 用於 BF16 評估
bf16: full  # 相當於 HF trainer 中的 bf16_full_eval
```

範例 2 (yaml):
```yaml
# 啟用 FP8 混合精度
fp8: true

# 選填：為 FSDP all-gather 操作啟用 FP8
fp8_enable_fsdp_float8_all_gather: true

# 啟用 torch.compile (對於 FP8 加速幾乎是必要的)
torch_compile: true
```

範例 3 (yaml):
```yaml
fp8: true
fp8_enable_fsdp_float8_all_gather: true

torch_compile: true

# FSDP 配置
fsdp_version: 2
fsdp_config:
  offload_params: false
  cpu_ram_efficient_loading: true
  auto_wrap_policy: TRANSFORMER_BASED_WRAP
  transformer_layer_cls_to_wrap: LlamaDecoderLayer
  state_dict_type: FULL_STATE_DICT
  reshard_after_forward: true
```

---

## 常見問題 (FAQ)

**URL:** https://docs.axolotl.ai/docs/faq.html

**內容：**
- FAQ
  - 一般問題
  - 聊天模板 (Chat templates)

問：訓練器 (trainer) 停止了，且好幾分鐘沒有進展。

答：通常是 GPU 彼此通訊的問題。請參閱 NCCL 文件。

答：這通常發生在系統 RAM 用盡時。

問：使用 deepspeed 時出現 exitcode: -7。

答：嘗試使用 pip install -U deepspeed 升級 deepspeed。

問：AttributeError: ‘DummyOptim’ object has no attribute ‘step’。

問：在 deepspeed 中使用單個 GPU 時出現 ModuleNotFoundError: No module named ‘mpi4py’。

答：您可能在單個 GPU 上使用了 deepspeed。請移除 YAML 檔案中的 deepspeed: 區塊或移除 --deepspeed CLI 旗標。

問：程式碼卡在儲存預處理後的資料集。

答：這通常是 GPU 的問題。可以透過設定環境變數 CUDA_VISIBLE_DEVICES=0 來解決。如果您使用的是 runpod，這通常是 pod 的問題。重新啟動一個新 pod 應該可以解決。

問：在合併適配器 (merge adapters) 或載入適配器時，checkpoint 和模型的 torch.Size 出現不匹配錯誤。

答：這很可能是由於詞表大小 (vocab size) 不匹配。預設情況下，如果標記器 (tokenizer) 的標記多於模型，Axolotl 會擴展模型的嵌入 (embeddings)。請使用 axolotl merge-lora 命令來合併適配器，而不是使用您自己的腳本。

另一方面，如果模型的標記多於標記器，除非在配置中設定了 shrink_embeddings: true，否則 Axolotl 不會縮減模型的嵌入。

問：如何透過自定義 Python 腳本呼叫 Axolotl？

答：由於 Axolotl 只是 Python 程式，請參閱 src/axolotl/cli/main.py 以瞭解每個命令是如何被呼叫的。

問：如何知道 fsdp_transformer_layer_cls_to_wrap 應該使用什麼值？

答：這是要用 FSDP 包裝的 transformer 層類別名稱。例如，對於 LlamaForCausalLM，該值為 LlamaDecoderLayer。要為特定模型找到此值，請檢查模型的 PreTrainedModel 定義，並在 transformers 函式庫中的 modeling_<model_name>.py 檔案中查找 _no_split_modules 變數。

問：ValueError: Asking to pad but the tokenizer does not have a padding token. Please select a token to use as pad_token。

答：這是因為標記器沒有填補 (padding) 標記。請透過以下方式為標記器新增填補標記：

問：使用 preprocess CLI 時出現 IterableDataset 錯誤或 KeyError: 'input_ids'。

答：這是因為您可能分別在使用了 pretraining_dataset: 或 skip_prepare_dataset: true 的情況下使用了 preprocess CLI。請直接使用 axolotl train CLI，因為這些資料集是按需準備的。

問：vLLM 無法與 Axolotl 一起運作。

答：我們目前推薦使用 torch 2.6.0 與 vLLM 搭配。請確保您使用的是正確版本。對於 Docker，請使用 main-py3.11-cu124-2.6.0 標籤。

問：在 CUDA 12.4 上出現 FA2 2.8.0 未定義符號 (undefined symbol) 的執行階段錯誤。

答：在 CUDA 12.4 上 FA2 2.8.0 的 wheel 似乎有問題。請嘗試使用 CUDA 12.6 或降級至 FA2 2.7.4。請參閱上游問題：https://github.com/Dao-AILab/flash-attention/issues/1717。

問：我們可以混合使用文本和文本+圖像資料集來進行 VLM 訓練嗎？

答：是的，對於較新的 VLM 架構是可以的。無法運作的是 LLaVA / Pixtral 架構。如果您發現某個架構無法運作，請告訴我們！

問：為什麼 memory/max_* 與 nvidia-smi 顯示的不同？

答：我們使用 torch API 來檢索此資訊。您可以參閱 https://docs.pytorch.org/docs/stable/notes/cuda.html#cuda-memory-management 獲取更多資訊。

問：jinja2.exceptions.UndefinedError: 'dict object' has no attribute 'content' / 'role' / ____。

答：這意味著在構建 chat_template 提示時，所述屬性的屬性映射不存在。例如，如果沒有屬性 'content'，請檢查您是否已在 message_property_mappings 下為 content 新增了正確的映射。

問：為輪次 (turn) ___ 產生了空模板。

答：該輪次的內容為空。

問：無法為輪次 __ 找到內容的起始/結束邊界。

答：無法偵測到特定輪次的起始/結束。請確保您已根據 chat_template 設定了 eos_token。否則，這可能是一個未使用各輪次適當邊界的 chat_template（如 system）。在極少數情況下，請確保您的內容不是 [[dummy_message]]。請務必讓我們知道這類情況。

問：輪次 ___ 的內容結束邊界在起始邊界之前。

答：這是一個不應發生的極端情況。如果發生，請建立一個 Issue。

問：輪次 ___ 的內容結束邊界與起始邊界相同。這很可能是一個空輪次。

答：這很可能是一個空輪次。

問：EOS 標記被錯誤地屏蔽或未被屏蔽 / 在聊天模板中找不到 EOS 標記 __。

答：可能有兩個原因：

問：「chat_template choice is tokenizer_default but tokenizer’s chat_template is null. Please add a chat_template in tokenizer config」。

答：這是因為標記器沒有聊天模板。請在標記器配置中新增聊天模板。詳情請參閱 chat_template。

問：EOT 標記被錯誤地屏蔽或未被屏蔽 / 在聊天模板中找不到 EOT 標記 __。

答：可能有兩個原因：

問：EOT 標記編碼失敗。請檢查標記是否有效且可以被編碼。

答：標記器或 unicode 編碼可能存在一些問題。請提交 Issue 並附上導致問題的 EOT 標記和標記器範例。

問：EOT 標記 __ 被編碼為多個標記。

答：這是因為 EOT 標記被編碼為多個標記，這可能會導致意外行為。請將其新增至 tokens: 下，或（推薦）透過 added_tokens_overrides: 覆寫未使用的 added_tokens。

問：train_on_eos 與 train_on_eot 之間存在衝突。eos_token 位於 eot_tokens 中，且 train_on_eos != train_on_eot。

答：這是因為 EOS 標記位於 eot_tokens: 中，而 train_on_eos: 與 train_on_eot: 之間不匹配。這將導致其中一個覆寫另一個。請確保 train_on_eos: 和 train_on_eot: 相同，或從 eot_tokens: 中移除 EOS 標記。

問：如果未提供 eot_tokens: 會發生什麼事？

答：如果未提供 eot_tokens:，預設行為與以前相同。用於分隔輪次的 EOS 標記會根據該輪次是否可訓練而被屏蔽/取消屏蔽。

在內部，eot_tokens: tokenizer.eos_token 且 train_on_eot: train_on_eos（預設為 turn）。這種過度有助於釐清 EOT/EOS 標記的命名和行為。

問：資料處理錯誤：CAS 服務錯誤。

答：嘗試透過 export HF_HUB_DISABLE_XET=1 停用 XET。

問：torch._inductor.exc.LoweringException: NoValidChoicesError: No choices to select...。

答：根據 torch 的版本，您可能需要在 YAML 中包含以下內容：

問：ValueError("Backward pass should have cleared tracker of all tensors")。

答：這可能是由於在 CUDA 串流中使用現代 OffloadActivations 上下文管理器時出現的極端情況。如果您遇到此錯誤，在 YAML 中使用 offload_activations: legacy 的簡單實作可能會成功。

問：將 tool_calls 參數解析為 JSON 時發生錯誤。

答：將字串參數解析為字典時發生錯誤。請檢查您的資料集和錯誤訊息以獲取更多詳細資訊。

**範例：**

範例 1 (yaml):
```yaml
special_tokens:
  # 字串。如果不確定，設定為與 `eos_token` 相同。
  pad_token: "..."
```

範例 2 (yaml):
```yaml
flex_attn_compile_kwargs:
  dynamic: false
  mode: max-autotune-no-cudagraphs
```

---

## 安裝 (Installation)

**URL:** https://docs.axolotl.ai/docs/installation.html

**內容：**
- 安裝
- 1 需求
- 2 安裝方法
  - 2.1 PyPI 安裝 (推薦)
  - 2.2 uv 安裝
  - 2.3 最新/開發版本編譯 (Edge/Development Build)
  - 2.4 Docker
- 3 雲端環境
  - 3.1 雲端 GPU 提供商
  - 3.2 Google Colab

本指南涵蓋了為您的環境安裝和設定 Axolotl 的所有方法。

在您的本地環境安裝 Axolotl 之前，請確保已安裝 Pytorch。

請按照以下指南進行操作：https://pytorch.org/get-started/locally/

對於 Blackwell GPU，請使用 Pytorch 2.7.0 和 CUDA 12.8。

我們使用 --no-build-isolation 來偵測已安裝的 PyTorch 版本（如果已安裝），以免衝突，並確保我們設定了特定於 PyTorch 版本或其他已安裝共同相依項的正確相依版本。

uv 是一個快速、可靠的 Python 套件安裝程式和解析器，使用 Rust 構建。它提供比 pip 顯著的效能提升，並提供更好的相依性解析，使其成為複雜環境的絕佳選擇。

如果尚未安裝，請安裝 uv。

選擇要與 PyTorch 搭配使用的 CUDA 版本；例如 cu124, cu126, cu128，然後建立 venv 並啟用。

安裝 PyTorch - 推薦使用 PyTorch 2.6.0。

從 PyPi 安裝 Axolotl。

獲取發布版本之間的最新功能：

使用 Docker 進行開發：

對於 Blackwell GPU，請使用 axolotlai/axolotl:main-py3.11-cu128-2.7.0 或雲端變體 axolotlai/axolotl-cloud:main-py3.11-cu128-2.7.0。

有關各種 Docker 映像檔的更多資訊，請參閱 Docker 文件。

對於支援 Docker 的提供商：

有關 Mac 特定問題，請參閱第 6 節。

我們推薦使用 WSL2 (Windows Subsystem for Linux) 或 Docker。

安裝 PyTorch: https://pytorch.org/get-started/locally/

(選填) 登入 Hugging Face：

如果您遇到安裝問題，請參閱我們的 FAQ 和除錯指南。

**範例：**

範例 1 (bash):
```bash
pip3 install -U packaging setuptools wheel ninja
pip3 install --no-build-isolation axolotl[flash-attn,deepspeed]
```

範例 2 (bash):
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env
```

範例 3 (bash):
```bash
export UV_TORCH_BACKEND=cu126
uv venv --no-project --relocatable
source .venv/bin/activate
```

範例 4 (bash):
```bash
uv pip install packaging setuptools wheel
uv pip install torch==2.6.0
uv pip install awscli pydantic
```

---

## 資料集預處理 (Dataset Preprocessing)

**URL:** https://docs.axolotl.ai/docs/dataset_preprocessing.html

**內容：**
- 資料集預處理
- 概覽
  - 預處理的好處是什麼？
  - 有哪些極端情況？

資料集預處理是 Axolotl 根據您配置的每個資料集以及資料集格式和提示策略來執行以下操作的步驟：

資料集的處理可以透過以下兩種方式之一進行：

在進行互動式訓練或參數掃描 (sweeps) 時（例如，您經常重啟訓練器），處理資料集通常會慢得令人沮喪。預處理會根據相依訓練參數的雜湊值 (hash) 來快取已標記化/格式化的資料集，以便在可能的情況下智慧地從其快取中讀取。

快取的路徑由 dataset_prepared_path: 控制，在範例 YAML 中通常留空，因為這可以提供更穩健的解決方案，防止意外重複使用舊的快取數據。

如果 dataset_prepared_path: 留空，在訓練時，處理後的資料集將快取在 ./last_run_prepared/ 的預設路徑中，但會忽略該處已有的任何快取。透過明確設定 dataset_prepared_path: ./last_run_prepared，訓練器將使用快取中的任何預處理數據。

假設您正在撰寫自定義提示策略或使用使用者定義的提示模板。由於訓練器無法輕易偵測到這些更改，我們無法更改預處理資料集的計算雜湊值。

如果您設定了 dataset_prepared_path: ... 並更改了提示模板邏輯，它可能不會獲取您所做的更改，而您將在舊的提示上進行訓練。

---

## 推理與合併 (Inference and Merging)

**URL:** https://docs.axolotl.ai/docs/inference.html

**內容：**
- 推理與合併
- 1 快速開始
  - 1.1 基礎推理
- 2 進階用法
  - 2.1 Gradio 介面
  - 2.2 基於檔案的提示 (Prompts)
  - 2.3 記憶體優化
- 3 合併 LoRA 權重
  - 3.1 合併時的記憶體管理
- 4 標記化 (Tokenization)

本指南涵蓋如何將訓練好的模型用於推理，包括模型載入、互動式測試、合併適配器以及常見的疑難排解步驟。

在推理/合併時使用與訓練相同的配置。

啟動互動式網頁介面：

處理來自文本檔案的提示：

對於大型模型或記憶體有限的情況：

將 LoRA 適配器與基礎模型合併：

訓練和推理之間的標記化不匹配是問題的常見來源。

透過在模型輸入前解碼標記來驗證推理標記化。

比較訓練和推理之間的標記 ID。

在您的 YAML 中配置特殊標記：

更多詳細資訊，請參閱我們的除錯指南。

**範例：**

範例 1 (bash):
```bash
axolotl inference your_config.yml --lora-model-dir="./lora-output-dir"
```

範例 2 (bash):
```bash
axolotl inference your_config.yml --base-model="./completed-model"
```

範例 3 (bash):
```bash
axolotl inference your_config.yml --gradio
```

範例 4 (bash):
```bash
cat /tmp/prompt.txt | axolotl inference your_config.yml \
  --base-model="./completed-model" --prompter=None
```

---

## 多模態 / 視覺語言模型 (MultiModal / Vision Language Models) (BETA)

**URL:** https://docs.axolotl.ai/docs/multimodal.html

**內容：**
- 多模態 / 視覺語言模型 (BETA)
- 支援的模型
- 用法
  - Mllama
  - Llama4
  - Pixtral
  - Llava-1.5
  - Mistral-Small-3.1
  - Magistral-Small-2509
  - Voxtral

多模態支援有限，尚未達到完整的功能對等。

以下是您微調多模態模型時需要使用的超參數。

請參閱 examples 資料夾以獲取完整配置。

我們的一些 chat_templates 已擴展以支援更廣泛的資料集類型。這不應影響任何現有配置。

截至目前，我們不會根據 sequence_len 進行截斷或捨棄樣本，因為每個架構都有處理非文本標記的不同方式。我們正在尋求這方面的協助。

請確保透過 pip install 'mistral-common[opencv]==1.8.5' 安裝視覺函式庫。

請確保透過 pip install 'mistral-common[opencv]==1.8.5' 安裝視覺函式庫。

請確保透過 pip3 install librosa==0.11.0 'mistral_common[audio]==1.8.3' 安裝音訊函式庫。

Gemma3-1B 模型是純文本模型，因此請按一般文本模型進行訓練。

對於多模態 4B/12B/27B 模型，請使用以下配置：

模型的初始損失 (loss) 和梯度範數 (grad norm) 會非常高。我們懷疑這是由於視覺層中的 Conv 造成的。

請確保透過 pip3 install timm==1.0.17 安裝 timm。

請確保透過 pip3 install num2words==0.5.14 安裝 num2words。

請透過 pip3 uninstall -y causal-conv1d 解除安裝 causal-conv1d。

對於多模態資料集，我們採用一種類似於 OpenAI 訊息格式的擴展 chat_template 格式。

為了向下相容：

對於圖像載入，您可以在內容中使用以下鍵值以及 "type": "image"：

對於音訊載入，您可以在內容中使用以下鍵值以及 "type": "audio"：

您可能需要透過 pip3 install librosa==0.11.0 安裝 librosa。

目前尚未經過充分測試。我們歡迎貢獻者！

對於影片載入，您可以在內容中使用以下鍵值以及 "type": "video"：

以下是多模態資料集的範例：

PIL 無法使用 requests 檢索該 URL 的檔案。請檢查是否有拼字錯誤。另一個可能的原因是請求被伺服器封鎖。

**範例：**

範例 1 (yaml):
```yaml
processor_type: AutoProcessor

skip_prepare_dataset: true
remove_unused_columns: false  # 保留列，因為訓練期間處理圖像嵌入需要它們
sample_packing: false  # 多模態尚未支援

chat_template:  # 如果有指定，請參閱下一節

# 範例資料集
datasets:
  - path: HuggingFaceH4/llava-instruct-mix-vsft
    type: chat_template
    split: train[:1%]

# (選填) 如果執行 LoRA，僅微調語言模型，
# 讓視覺模型和視覺塔保持凍結
# load_in_8bit: true
adapter: lora
lora_target_modules: 'model.language_model.layers.[\d]+.(mlp|cross_attn|self_attn).(up|down|gate|q|k|v|o)_proj'

# (選填) 如果您想將圖像調整為設定的大小
image_size: 512
image_resize_algorithm: bilinear
```

範例 2 (yaml):
```yaml
base_model: meta-llama/Llama-3.2-11B-Vision-Instruct

chat_template: llama3_2_vision
```

範例 3 (yaml):
```yaml
base_model: meta-llama/Llama-4-Scout-17B-16E-Instruct

chat_template: llama4
```

範例 4 (yaml):
```yaml
base_model: mistralai/Pixtral-12B-2409

chat_template: pixtral
```

---

## 獎勵建模 (Reward Modelling)

**URL:** https://docs.axolotl.ai/docs/reward_modelling.html

**內容：**
- 獎勵建模
  - 概覽
  - (結果) 獎勵模型 (Outcome Reward Models)
  - 過程獎勵模型 (PRM)

獎勵建模是一種訓練模型以預測給定輸入的獎勵或價值的技術。這在強化學習情境中特別有用，模型需要評估其動作或預測的品質。我們支援 trl 支援的獎勵建模技術。

結果獎勵模型是使用包含使用者與模型之間整個互動（例如，而非按輪次或按步驟）的偏好標註數據進行訓練的。為了提高訓練穩定性，您可以使用 center_rewards_coefficient 參數來鼓勵均值為零的獎勵輸出（參見 TRL 文件）。

Bradley-Terry 聊天模板預期以下格式的單輪對話：

查看我們的 PRM 部落格。

過程獎勵模型是使用包含一系列互動中每個步驟的偏好標註數據進行訓練的。通常，PRM 訓練用於為推理軌跡的每個步驟提供獎勵訊號，並用於下游強化學習。

有關資料集格式的更多詳細資訊，請參閱 stepwise_supervised。

**範例：**

範例 1 (yaml):
```yaml
base_model: google/gemma-2-2b
model_type: AutoModelForSequenceClassification
num_labels: 1
tokenizer_type: AutoTokenizer

reward_model: true
chat_template: gemma
datasets:
  - path: argilla/distilabel-intel-orca-dpo-pairs
    type: bradley_terry.chat_template

val_set_size: 0.1
eval_steps: 100
```

範例 2 (json):
```json
{
    "system": "...", // 選填
    "input": "...",
    "chosen": "...",
    "rejected": "..."
}
```

範例 3 (yaml):
```yaml
base_model: Qwen/Qwen2.5-3B
model_type: AutoModelForTokenClassification
num_labels: 2

process_reward_model: true
datasets:
  - path: trl-lib/math_shepherd
    type: stepwise_supervised
    split: train

val_set_size: 0.1
eval_steps: 100
```

---

## RLHF (Beta)

**URL:** https://docs.axolotl.ai/docs/rlhf.html

**內容：**
- RLHF (Beta)
- 概覽
- 在 Axolotl 使用 RLHF
  - DPO
    - chatml.argilla
    - chatml.argilla_chat
    - chatml.icr
    - chatml.intel
    - chatml.prompt_pairs
    - chatml.ultra

來自人類回饋的強化學習 (RLHF) 是一種根據人類回饋數據優化語言模型的方法。各種方法包括但不限於：

這是一個 BETA 功能，許多功能尚未完全實作。鼓勵您開啟新的 PR 以改進整合和功能。

我們依賴 TRL 函式庫實作各種 RL 訓練方法，並將其包裝在 Axolotl 中公開。每種方法都有其支援的資料集載入方式和提示格式。

您可以進入 src/axolotl/prompt_strategies/{method}（其中 {method} 是我們支援的方法之一）來查看每種方法支援的內容。type: 可以從 {method}.{function_name} 獲取。

DPO 支援以下資料集格式的類型：

對於自定義行為，

輸入格式是一個簡單的 JSON 輸入，帶有基於上述配置的可自定義欄位。

由於 IPO 只是具有不同損失函數的 DPO，DPO 支援的所有資料集格式也支援 IPO。

論文：https://arxiv.org/abs/2403.07691

ORPO 支援以下資料集格式的類型：

KTO 支援以下資料集格式的類型：

對於自定義行為，

輸入格式是一個簡單的 JSON 輸入，帶有基於上述配置的可自定義欄位。

查看我們的 GRPO 食譜 (cookbook)。

在最新的 GRPO 實作中，vLLM 被用來顯著加速訓練期間的軌跡產生。在此範例中，我們使用 4 個 GPU - 2 個用於訓練，2 個用於 vLLM：

確保您在安裝 Axolotl 時已將 vLLM 作為額外組件安裝，例如 pip install axolotl[vllm]。

您的 vLLM 實例現在將嘗試啟動，是時候利用剩餘的兩個 GPU 開始訓練了。在另一個終端機中執行：

由於 TRL 與 vLLM 的實作方式，vLLM 實例必須使用最後 N 個 GPU 而非前 N 個 GPU。這就是為什麼在上面的範例中，我們為 vLLM 實例使用 CUDA_VISIBLE_DEVICES=2,3。

GRPO 使用自定義獎勵函數和轉換。請在本地準備好它們。

例如，載入 OpenAI 的 GSM8K 並為完成結果使用隨機獎勵：

要查看自定義獎勵函數的其他範例，請參閱 TRL GRPO 文件。

要查看所有配置，請參閱 TRLConfig。

DAPO 論文以及隨後的 Dr. GRPO 論文為 GRPO 提出了另一種損失函數，以補償較長回應的懲罰。

更多資訊請參閱 GRPO 文件。

SimPO 使用 CPOTrainer，但具有替代損失函數。

此方法使用與 DPO 相同的資料集格式。

TRL 支援為依賴參考模型的 RL 訓練範式自動取消包裝 (auto-unwrapping) PEFT 模型。這顯著減少了記憶體壓力，因為不需要載入額外的參考模型，並且可以透過停用 PEFT 適配器來獲取參考模型對數機率。此功能預設啟用。要關閉它，請傳遞以下配置：

**範例：**

範例 1 (yaml):
```yaml
rl: dpo
datasets:
  - path: Intel/orca_dpo_pairs
    split: train
    type: chatml.intel
  - path: argilla/ultrafeedback-binarized-preferences
    split: train
    type: chatml
```

範例 2 (json):
```json
{
    "system": "...", // 選填
    "instruction": "...",
    "chosen_response": "...",
    "rejected_response": "..."
}
```

範例 3 (json):
```json
{
    "chosen": [
        {"role": "user", "content": "..."},
        {"role": "assistant", "content": "..."}
    ],
    "rejected": [
        {"role": "user", "content": "..."},
        {"role": "assistant", "content": "..."}
    ]
}
```

範例 4 (json):
```json
{
    "system": "...", // 選填
    "input": "...",
    "chosen": "...",
    "rejected": "..."
}
```

---

## LoRA 優化 (LoRA Optimizations)

**URL:** https://docs.axolotl.ai/docs/lora_optims.html

**內容：**
- LoRA 優化
- 用法
- 需求
- 實作細節
  - 自定義 autograd 函數
  - Triton 核心 (kernels)
  - 整合
- 未來工作

受 Unsloth 啟發，我們為 LoRA 和 QLoRA 微調實作了兩項優化，支援單 GPU 和多 GPU（包括 DDP、DeepSpeed 和 FSDP2 設定）訓練。這些包括 (1) SwiGLU 和 GEGLU 激活函數 Triton 核心，以及 (2) LoRA MLP 和 attention 自定義 autograd 函數。我們的目標是利用算子融合 (operator fusion) 和張量重用，以提高這些計算的前向和後向傳遞速度並減少記憶體使用量。

我們目前支援多種常見的模型架構，包括（但不限於）：

我們支援的模型集目前受到我們的 attention 補丁策略的限制，該策略假設（並替換）query / key / value 和輸出投影的特定程式碼區塊：

其中 apply_qkv 和 apply_o 定義在 axolotl.kernels.lora 模組中。

我們歡迎測試其他模型架構以及提交 PR 以擴展我們的補丁邏輯，使其相容於更多架構。

查看我們的 LoRA 優化部落格。

這些優化可以在您的 Axolotl 配置 YAML 檔案中啟用。lora_mlp_kernel 選項啟用優化的 MLP 路徑，而 lora_qkv_kernel 和 lora_o_kernel 分別啟用融合的 query-key-value 投影和優化的輸出投影。

目前，RLHF 訓練不支援 LoRA 核心，僅支援 SFT。

預先存在 LoRA 適配器且使用 Dropout 或具有 bias 項的模型可能需要重新微調而不使用這些功能。

LoRA MLP autograd 函數優化了整個 MLP 計算路徑。它將 LoRA 和基礎權重計算融合在一起，並為整個 MLP 區塊提供單一、高效的後向傳遞。

對於 attention 組件，透過處理 query, key, value 投影的函數以及處理輸出投影的函數提供了類似的優化。它們旨在透過一些 monkey-patching 邏輯與現有的 transformers attention 實作配合運作。

使用 Triton 核心實作了兩種激活函數（SwiGLU 和 GeGLU），以提高速度和記憶體效能。這些核心處理前向和後向傳遞。

自定義 autograd 函數和 Triton 核心旨在協同運作。autograd 函數管理高等級的計算流和梯度追蹤，同時呼叫 Triton 核心進行激活函數計算。在後向傳遞期間，核心計算激活輸出和所需的梯度，autograd 函數隨後使用這些梯度來計算整個計算路徑的最終梯度。

**範例：**

範例 1 (python):
```python
ORIGINAL_QKV_CODE = """
    query_states = self.q_proj(hidden_states).view(hidden_shape).transpose(1, 2)
    key_states = self.k_proj(hidden_states).view(hidden_shape).transpose(1, 2)
    value_states = self.v_proj(hidden_states).view(hidden_shape).transpose(1, 2)
""".lstrip(
    "\n"
)

ORIGINAL_O_CODE = """
    attn_output = self.o_proj(attn_output)
""".lstrip(
    "\n"
)
```

範例 2 (python):
```python
PATCHED_QKV_CODE = """
    query_states, key_states, value_states = self.apply_qkv(hidden_states)
    query_states = query_states.view(hidden_shape).transpose(1, 2)
    key_states = key_states.view(hidden_shape).transpose(1, 2)
    value_states = value_states.view(hidden_shape).transpose(1, 2)
""".lstrip(
    "\n"
)

PATCHED_O_CODE = """
    attn_output = self.apply_o(attn_output)
""".lstrip(
    "\n"
)
```

範例 3 (yaml):
```yaml
lora_mlp_kernel: true
lora_qkv_kernel: true
lora_o_kernel: true
```

---

## 使用 torchao 進行量化 (Quantization with torchao)

**URL:** https://docs.axolotl.ai/docs/quantize.html

**內容：**
- 使用 torchao 進行量化
- 在 Axolotl 中配置量化

量化是一種降低模型記憶體佔用空間的技術，可能會以犧牲準確性或模型效能為代價。我們支援使用 torchao 函式庫對您的模型進行量化。支援訓練後量化 (PTQ) 和量化感知訓練 (QAT)。

我們目前不支援 GGUF/GPTQ, EXL2 等量化技術。

量化是使用配置文件中的 quantization 鍵來配置的。

量化完成後，您的量化模型將儲存在 {output_dir}/quantized 目錄中。

您也可以使用 quantize 命令對已使用 QAT 訓練的模型進行量化 - 您可以透過使用訓練模型時使用的現有 QAT 配置文件來執行此操作：

這可確保使用與訓練模型時相同的量化配置來對模型進行量化。

如果您配置了使用 hub_model_id 推送到 hub，您的模型 hub 名稱將附加量化架構，例如 axolotl-ai-cloud/qat-nvfp4-llama3B 將變為 axolotl-ai-cloud/qat-nvfp4-llama3B-nvfp4w。

**範例：**

範例 1 (yaml):
```yaml
base_model: # 要量化的模型路徑。
quantization:
  activation_dtype: # Optional[str] = "int8"。用於激活量化的虛假量化佈局。有效選項為 "int4", "int8", "float8"
  weight_dtype: # Optional[str] = "int8"。用於權重量化的虛假量化佈局。有效選項為 "int4", "fp8" 和 "nvfp4"。
  group_size: # Optional[int] = 32。每個組中用於逐組虛假量化的元素數量。
  quantize_embedding: # Optional[bool] = False。是否對嵌入層進行量化。

output_dir:  # 輸出目錄路徑。
```

範例 2 (yaml):
```yaml
# qat.yml
qat:
  activation_dtype: int8
  weight_dtype: int4
  group_size: 256

output_dir: # 訓練期間使用的輸出目錄路徑，最終 checkpoint 已儲存在此處。
```

範例 3 (bash):
```bash
axolotl quantize qat.yml
```

---

## NCCL

**URL:** https://docs.axolotl.ai/docs/nccl.html

**內容：**
- NCCL

NVIDIA NCCL 是一個促進和優化多 GPU 通訊操作（如 broadcast, all-gather, reduce, all-reduce 等）的函式庫。廣義上，NCCL 配置高度依賴環境，並透過多個環境變數進行配置。一個常見的 NCCL 相關問題是長時間執行的操作逾時，導致訓練過程中止：

通常，此逾時會在 30 分鐘（預設設定）後發生，並伴隨低於平均水平的功耗，以及在報錯前接近 100% 的 GPU 利用率。如果可以使用的話，Nvidia 推薦停用 PCI 存取控制服務 (ACS) 作為可能的解決方案。

在不增加逾時的情況下，強制透過 NVLink 進行跨 GPU 通訊可能會有幫助。要驗證您的配置是否利用了 NVLink，請執行以下命令：

要強制 NCCL 使用 NVLink，只需在環境中設定：

如果您環境中沒有 NVLink，下表中有其他 NCCL_P2P_LEVEL 選項：

要驗證您的訓練任務是否存在可接受的資料傳輸速度，執行 NCCL 測試 (NCCL Tests) 可以幫助精確定位瓶頸，例如：

在除錯 NCCL 通訊逾時時，在 PyTorch 和 NCCL 中啟動額外的日誌紀錄會很有用：

最後，如果您認為訓練任務需要更多時間，可以透過在 Axolotl 配置中設定 ddp_timeout 值將逾時增加到 30 分鐘以上。有關此值的說明，請參閱 PyTorch init_process_group 文件。

**範例：**

範例 1 (unknown):
```unknown
Watchdog caught collective operation timeout: WorkNCCL(SeqNum=42, OpType=ALLGATHER, Timeout(ms)=1800000) ran for 1806948 milliseconds before timing out.
```

範例 2 (bash):
```bash
nvidia-smi nvlink --status
```

範例 3 (bash):
```bash
export NCCL_P2P_LEVEL=NVL
```

範例 4 (bash):
```bash
./build/all_reduce_perf -b 8 -e 128M -f 2 -g 3
```

---

## 多節點 (Multi Node)

**URL:** https://docs.axolotl.ai/docs/multi-node.html

**內容：**
- 多節點
- Accelerate
- Raytrain
- Torchrun
  - 選項 1：具有啟動參數的新 Axolotl CLI（推薦）
  - 選項 2：直接使用 torchrun（舊版）

以下是在 Axolotl 中進行多節點訓練的三種方法。

每台機器都需要一份 Axolotl 副本，我們建議使用相同的 commit 以確保相容性。

您還需要在每台機器上為模型準備相同的配置文件。

確保主機器 (main machine) 可以被其他機器存取。

您需要為 accelerate 建立配置，可以使用 accelerate config 並按照指示操作，或者可以使用下面的預設配置之一：

~/.cache/huggingface/accelerate/default_config.yaml

在 Axolotl yaml 中配置模型使用 FSDP。例如：

現在您只需像平時在每台機器上啟動 accelerate 一樣啟動即可，一旦您在每台機器上啟動了 accelerate，進程就會開始。

請參閱此處的 ray train 文件。

如果您使用 Infiniband，我們推薦使用 torchrun 以利用完整頻寬。

設定以下環境變數（根據您的系統更改 buffersize/socketname）：

在每個節點上執行以下命令：

請確保替換預留位置變數：

推薦使用新的 CLI 方式（選項 1），因為它提供一致的參數處理，並與其他 Axolotl CLI 功能無縫協作。

有關可用配置的更多資訊可以在此處的 Pytorch 文件中找到。

**範例：**

範例 1 (yaml):
```yaml
compute_environment: LOCAL_MACHINE
debug: false
distributed_type: FSDP
downcast_bf16: 'no'
machine_rank: 0 # 主機器設定為 0，其他機器依次遞增
main_process_ip: 10.0.0.4 # 設定為主機器的 IP
main_process_port: 5000
main_training_function: main
mixed_precision: bf16
num_machines: 2 # 更改為機器數量
num_processes: 4 # 這是 GPU 總數，（例如：如果您有 2 台機器，每台 4 個 GPU，請填入 8）
rdzv_backend: static
same_network: true
tpu_env: []
tpu_use_cluster: false
tpu_use_sudo: false
use_cpu: false
```

範例 2 (yaml):
```yaml
fsdp_version: 2
fsdp_config:
  offload_params: true
  state_dict_type: FULL_STATE_DICT
  auto_wrap_policy: TRANSFORMER_BASED_WRAP
  transformer_layer_cls_to_wrap: LlamaDecoderLayer
  reshard_after_forward: true
```

範例 3 (bash):
```bash
export NCCL_IB_DISABLE=0
export NCCL_SOCKET_IFNAME="eth0,en,eth,em,bond"
export NCCL_BUFFSIZE=2097152
```

範例 4 (bash):
```bash
axolotl train config.yaml --launcher torchrun -- --nnodes $num_nodes --nproc_per_node $gpu_per_node --rdzv_id $rdzv_id --rdzv_backend c10d --rdzv_endpoint "$head_node_ip:$head_node_port"
```

---

## 資料集載入 (Dataset Loading)

**URL:** https://docs.axolotl.ai/docs/dataset_loading.html

**內容：**
- 資料集載入
- 概覽
- 載入資料集
  - 本地資料集
    - 檔案
    - 目錄
      - 載入整個目錄
      - 載入目錄中的特定檔案
  - HuggingFace Hub
    - 上傳的資料夾

根據資料集儲存方式（檔案副檔名）和儲存位置，可以透過多種不同方式載入資料集。

我們使用 datasets 函式庫來載入資料集，並結合使用 load_dataset 和 load_from_disk。

您可能會在 load_dataset 和配置文件的 datasets 章節之間發現相似命名的配置。

不要被這裡的選項數量嚇到。其中很多是選填的。事實上，最常用的配置是 path，有時還有 data_files。

這與 datasets.load_dataset 的 API 相匹配，因此如果您熟悉它，會感到非常親切。

有關 HuggingFace 載入不同資料集類型的指南，請參閱此處。

有關配置的完整細節，請參閱 config-reference.qmd。

您可以透過在 datasets 下新增多個項目來在配置文件中設定多個資料集。

要載入 JSON 檔案，您可以這樣做：

這會轉換為以下配置：

在上面的範例中，可以看到我們只需將 path 指向檔案或目錄，並配合 ds_type 來載入資料集。

這適用於 CSV, JSON, Parquet 和 Arrow 檔案。

如果 path 指向檔案且未指定 ds_type，我們將自動從檔案副檔名推斷資料集類型，因此您可以根據需要省略 ds_type。

如果您要載入目錄，可以將 path 指向該目錄。

然後，您有兩個選擇：

您不需要任何額外配置。

我們將嘗試按以下順序載入： - 使用 datasets.save_to_disk 儲存的資料集 - 載入整個檔案目錄（例如 parquet/arrow 檔案）

提供 data_files 列表以載入。

您載入資料集的方法取決於資料集的建立方式，是直接上傳了資料夾還是推送了 HuggingFace 資料集。

如果您使用私有資料集，則需要在配置文件的根級別啟用 hf_use_auth_token 旗標。

這意味著資料集是上傳到 Hub 的單個或多個檔案。

這意味著資料集被建立為 HuggingFace 資料集，並透過 datasets.push_to_hub 推送到 Hub。

根據資料集的不同，可能還需要其他一些配置，如 name, split, revision, trust_remote_code 等。

透過 load_dataset 下的 storage_options 配置，您可以從遠端檔案系統載入資料集，如 S3, GCS, Azure 和 OCI。

這目前處於實驗階段。如果您遇到任何問題，請告訴我們！

各提供商之間的唯一區別是您需要在路徑前加上各自的協定。

對於目錄，我們透過 load_from_disk 載入。

在路徑前加上 s3://。

認證資訊按以下順序獲取：

我們假設您已設定認證資訊，而非使用匿名存取。如果您想使用匿名存取，請告訴我們！我們可能需要為此開啟一個配置選項。

其他可以設定的環境變數可以在 boto3 文件中找到。

在路徑前加上 gs:// 或 gcs://。

認證資訊按以下順序載入：

在路徑前加上 adl://。

確保您設定了以下環境變數：

在路徑前加上 abfs:// 或 az://。

確保您設定了以下環境變數：

其他可以設定的環境變數可以在 adlfs 文件中找到。

在路徑前加上 oci://。

它會嘗試按以下順序讀取：

其他環境變數：

請參閱 ocifs 文件。

路徑應以 https:// 開頭。

這必須是公開可存取的。

現在您已瞭解如何載入資料集，可以進一步學習如何將特定的資料集格式載入到目標輸出格式中，詳見資料集格式文件。

**範例：**

範例 1 (yaml):
```yaml
datasets:
  - path:
    name:
    data_files:
    split:
    revision:
    trust_remote_code:
```

範例 2 (yaml):
```yaml
datasets:
  - path: /path/to/your/dataset
  - path: /path/to/your/other/dataset
```

範例 3 (python):
```python
from datasets import load_dataset

dataset = load_dataset("json", data_files="data.json")
```

範例 4 (yaml):
```yaml
datasets:
  - path: data.json
    ds_type: json
```

---

## 多 GPU (Multi-GPU)

**URL:** https://docs.axolotl.ai/docs/multi-gpu.html

**內容：**
- 多 GPU
- 1 概覽
- 2 DeepSpeed
  - 2.1 配置
  - 2.2 用法
  - 2.3 ZeRO 階段 (Stages)
- 3 Fully Sharded Data Parallel (FSDP)
  - 3.1 從 FSDP1 遷移到 FSDP2
    - 3.1.1 配置映射
  - 3.2 FSDP1 (已棄用)

本指南涵蓋使用 Axolotl 進行多 GPU 設定的進階訓練配置。

Axolotl 支援多種多 GPU 訓練方法：

新增至您的 YAML 配置：

我們為以下項目提供預設配置：

選擇卸載到記憶體最少、同時仍能裝入 VRAM 以獲得最佳效能的配置。

從 Stage 1 -> Stage 2 -> Stage 3。

推薦新使用者使用 FSDP2。FSDP1 已棄用，並將在 Axolotl 的未來版本中移除。

要將您的配置從 FSDP1 遷移到 FSDP2，您必須使用 fsdp_version 根級配置欄位來指定 FSDP 版本，並按照下面的配置欄位映射來更新欄位名稱。

更多細節請參閱 torchtitan 儲存庫中的遷移指南。在 Axolotl 中，如果您之前使用以下 FSDP1 配置：

您可以遷移到以下 FSDP2 配置：

使用 fsdp 來配置 FSDP 已被棄用，將在 Axolotl 的未來版本中移除。請改用上述的 fsdp_config。

我們透過 ring-flash-attention 專案支援序列平行 (sequence parallelism, SP)。這允許將序列拆分到多個 GPU 上，這在單個序列在模型訓練期間導致 OOM 錯誤的情況下非常有用。

詳見我們的專門指南。

有關將 FSDP 與 QLoRA 結合使用的資訊，請參閱我們的專門指南。

詳見文件以獲取更多資訊。

有關 NCCL 相關問題，請參閱我們的 NCCL 疑難排解指南。

有關更詳細的疑難排解，請參閱我們的除錯指南。

**範例：**

範例 1 (yaml):
```yaml
deepspeed: deepspeed_configs/zero1.json
```

範例 2 (bash):
```bash
# 獲取 deepspeed 配置（如果尚未存在）
axolotl fetch deepspeed_configs

# 透過配置傳遞參數
axolotl train config.yml

# 透過 cli 傳遞參數
axolotl train config.yml --deepspeed deepspeed_configs/zero1.json
```

範例 3 (yaml):
```yaml
fsdp_version: 1
fsdp_config:
  fsdp_offload_params: false
  fsdp_cpu_ram_efficient_loading: true
  fsdp_auto_wrap_policy: TRANSFORMER_BASED_WRAP
  fsdp_transformer_layer_cls_to_wrap: Qwen3DecoderLayer
  fsdp_state_dict_type: FULL_STATE_DICT
  fsdp_sharding_strategy: FULL_SHARD
```

範例 4 (yaml):
```yaml
fsdp_version: 2
fsdp_config:
  offload_params: false
  cpu_ram_efficient_loading: true
  auto_wrap_policy: TRANSFORMER_BASED_WRAP
  transformer_layer_cls_to_wrap: Qwen3DecoderLayer
  state_dict_type: FULL_STATE_DICT
  reshard_after_forward: true
```

---

## Ray Train

**URL:** https://docs.axolotl.ai/docs/ray-integration.html

**內容：**
- Ray Train
- Ray 叢集設定
- 健全性檢查 (Sanity check)
- 使用 Ray Train 配置訓練
- 啟動訓練

Axolotl 支援使用 Ray 作為 accelerate 的替代方案來編排訓練。這對於多節點訓練特別有用，因為您只需在單個節點中設定程式碼和相依項，並像使用單個節點一樣啟動訓練。

透過 --use-ray CLI 旗標，Axolotl 將使用 Ray Train 的 TorchTrainer 來執行訓練。

使用 Ray Train 整合的前題是在您想要的節點上設定 Ray 叢集。有關如何開始使用 Ray 叢集的詳細指南，請查看此處的 Ray 官方文件。

每個 Ray 叢集都有一個頭節點 (head node) 和一組工作節點 (worker nodes)。頭節點就像任何其他工作節點一樣，但它還執行與排程和編排相關的某些特殊進程。支援 Ray 的腳本在頭節點上執行，並根據它們請求的資源（CPU、GPU 數量等），將被排程在工作節點上執行某些任務。有關 Ray 叢集背後關鍵概念的更多資訊，可以參考此文件。

要對 Ray 叢集是否正確設定進行健全性檢查，請在頭節點上執行以下命令：

輸出應包含 Ray 叢集的摘要 - 叢集中所有節點的列表、叢集中的 CPU 和 GPU 數量等。例如，如果您有一個包含 1 個僅 CPU 的頭節點和 2 個 4xL40S 工作節點的叢集，輸出可能如下所示：

您也應該能在 Ray 儀表板上看到相同內容。

您可以在 configs/llama-3/lora-1b-ray.yaml 找到範例配置。

這裡要注意的關鍵參數是：

您只需在頭節點上執行以下命令：

這將在頭節點上啟動訓練，且 Ray Train 會自動將工作節點排程在適當的頭節點或工作節點上執行。

您也可以在 Ray 儀表板上監控訓練進度。

回到具有 1 個頭節點和 2 個 4xL40S 工作節點的 Ray 叢集範例，假設您想使用全部 8 個 GPU。您只需設定 ray_num_workers: 8 並執行前面的命令。「叢集 (Cluster)」分頁將顯示以下內容：

**範例：**

範例 1 (unknown):
```unknown
Node status
---------------------------------------------------------------
Active:
 1 head
Idle:
 2 4xL40S:48CPU-384GB
Pending:
 (no pending nodes)
Recent failures:
 (no failures)

Resources
---------------------------------------------------------------
Usage:
 0.0/96.0 CPU
 0.0/8.0 GPU
 0B/800.00GiB memory
 0B/229.57GiB object_store_memory

Demands:
 (no resource demands)
```

範例 2 (yaml):
```yaml
use_ray: true
ray_num_workers: 4
# 選填
resources_per_worker:
    GPU: 1
```

範例 3 (yaml):
```yaml
resources_per_worker:
    accelerator_type:L40S: 0.001
```

範例 4 (bash):
```bash
axolotl train examples/llama-3/lora-1b-ray.yml --use-ray
```

---

## 序列平行 (Sequence Parallelism)

**URL:** https://docs.axolotl.ai/docs/sequence_parallelism.html

**內容：**
- 序列平行
- 何時使用序列平行
- 配置
- 實作細節
- 需求
- 限制
- 範例
- 序列平行的樣本打包 (Sample Packing)
- 對批次大小 (Batch Size) 的影響

序列平行是一種將序列拆分到多個 GPU 上的技術，讓您可以使用單個 GPU 無法容納的極長序列進行訓練。每個 GPU 處理序列的不同部分，結果透過環狀通訊模式 (ring communication pattern) 進行聚合。

在以下情況使用序列平行：

要啟用序列平行，請將以下內容新增至您的配置文件：

context_parallel_size 應為 GPU 總數的一個因數。例如：

啟用序列平行時：

要使用序列平行，您需要：

這將使用 8K 上下文長度訓練 Llama 3 8B 模型，每個序列被拆分為 2 個長度為 4096 的子序列，分佈在 2 個 GPU 上。

序列平行與 Axolotl 的樣本打包功能相容。同時使用這兩項功能時：

使用序列平行時，您的有效全局批次大小 (global batch size) 會除以 context_parallel_size。這是因為：

例如： - 使用 8 個 GPU 且不使用序列平行：每步處理 8 個不同的批次 - 使用 8 個 GPU 且 context_parallel_size=4：每步僅處理 2 個不同的批次（每個批次拆分到 4 個 GPU 上） - 如果您每個 GPU 的 micro_batch_size 為 2，則全局批次大小從 16 減少到 4。

**範例：**

範例 1 (yaml):
```yaml
# 設定為可用 GPU 數量的因數 (> 1)
context_parallel_size: 4  # 將序列拆分到 4 個 GPU 上
# 選填；在 key 維度上跨越步長。較大的值使用更多記憶體，但應能加快訓練速度。
heads_k_stride: 1
# 選填；"varlen_llama3" 或 "batch_ring" 之一。
# 當 `sample_packing: true` 時，預設為 "varlen_llama3"，否則預設為 "batch_ring"。
ring_attn_func:
```

範例 2 (yaml):
```yaml
base_model: meta-llama/Llama-3-8B-Instruct
sequence_len: 8192

...

context_parallel_size: 4  # 將每個序列拆分為 4 個部分，每個 GPU 一個部分
# 選填；在 key 維度上跨越步長。較大的值使用更多記憶體，但應能加快訓練速度。
heads_k_stride: 1
# 選填；"varlen_llama3" 或 "batch_ring" 之一。
# 當 `sample_packing: true` 時，預設為 "varlen_llama3"，否則預設為 "batch_ring"。
ring_attn_func:

...
```

---

## 量化感知訓練 (Quantization Aware Training, QAT)

**URL:** https://docs.axolotl.ai/docs/qat.html

**內容：**
- 量化感知訓練 (QAT)
- 概覽
- 在 Axolotl 中配置 QAT

量化感知訓練 (QAT) 是一種提高量化模型準確性的技術，在訓練期間對模型權重（以及選填的激活函數）應用「虛假」量化。這種虛假量化允許模型調整量化引入的噪聲，因此當模型最終被量化時，準確性損失會降至最低。我們使用 torchao 中實作的量化技術為 Axolotl 提供 QAT 和訓練後量化 (PTQ) 支援。

我們建議查看 torchtune 函式庫中優秀的 QAT 教學，以及 torchao 函式庫中的 QAT 文件以獲取更多細節。

要在 Axolotl 中啟用 QAT，請將以下內容新增至您的配置文件：

我們支援以下量化架構：

訓練完成後，您必須使用與訓練模型時相同的量化配置對模型進行量化。您可以使用 quantize 命令執行此操作。

**範例：**

範例 1 (yaml):
```yaml
qat:
  activation_dtype: # Optional[str] = "int8"。用於激活量化的虛假量化佈局。有效選項為 "int4", "int8", "float8"
  weight_dtype: # Optional[str] = "int8"。用於權重量化的虛假量化佈局。有效選項為 "int4", "fp8" 和 "nvfp4"。
  group_size: # Optional[int] = 32。每個組中用於逐組虛假量化的元素數量。
  fake_quant_after_n_steps: # Optional[int] = None。在多少步之後應用虛假量化。
```

---

## FSDP + QLoRA

**URL:** https://docs.axolotl.ai/docs/fsdp_qlora.html

**內容：**
- FSDP + QLoRA
- 背景
- 用法
- 為 FSDP2 啟用 Swap
- 範例配置
- 參考資料
- 腳註

將 FSDP 與 QLoRA 結合使用對於在消費級 GPU 上微調較大的（70b+ 參數）LLM 至關重要。例如，您可以使用 FSDP + QLoRA 在兩個 24GB GPU 上訓練 70b 模型。

下面我們將介紹如何在 Axolotl 中使用此功能。

要為 FSDP 啟用 QLoRA，您需要執行以下步驟：

![提示] 除閱讀這些指示外，另請參閱範例配置文件。

如果即使在 FSDP 的 CPU 卸載後可用記憶體仍然不足，您可以透過在 FSDP 配置中將 cpu_offload_pin_memory: false 與 offload_params: true 同時設定來啟用 swap 記憶體的使用。

這會停用記憶體鎖定 (memory pinning)，允許 FSDP 使用磁碟 swap 空間作為備援。停用記憶體鎖定本身會產生效能開銷，實際使用 swap 會增加更多開銷，但它可能實現在資源受限系統上訓練否則會導致 OOM 錯誤的大型模型。

examples/llama-2/qlora-fsdp.yml 包含如何在 Axolotl 中啟用 QLoRA + FSDP 的範例。

這是由 Answer.AI 團隊的工作啟用的。↩︎

---

## 自定義整合 (Custom Integrations)

**URL:** https://docs.axolotl.ai/docs/custom_integrations.html

**內容：**
- 自定義整合
- Cut Cross Entropy
  - 需求
  - 安裝
  - 用法
  - 支援的模型
  - 引用
- DenseMixer
- Axolotl 的擴散語言模型 (Diffusion LM) 訓練插件
  - 概覽

Axolotl 透過整合新增自定義功能。它們位於 src/axolotl/integrations 目錄中。

要啟用它們，請查看各自的文件。

Cut Cross Entropy (CCE) 透過優化損失計算期間的交叉熵操作來減少 VRAM 使用量。

參見 https://github.com/apple/ml-cross-entropy

如果您尚未安裝，請執行以下命令安裝 cut_cross_entropy[transformers]。

請參閱此處的參考資料。

只需將以下內容新增至您的 Axolotl YAML 配置：

請參閱此處的參考資料。

此插件在 Axolotl 中實作了受 LLaDA (Large Language Diffusion Models) 啟發的擴散語言模型訓練方法。

LLaDA 是一種基於擴散的語言模型訓練方法，使用： - 訓練期間的隨機標記屏蔽 (random token masking) 取代下一標記預測 - 雙向注意力 (bidirectional attention) 允許模型關注完整上下文 - 基於屏蔽機率的關鍵性權重 (importance weighting) 以實現穩定訓練

這種方法可以產生更強健的語言模型，對雙向上下文有更好的理解。

此插件已包含在 Axolotl 中。參見我們的安裝文件。

使用範例配置進行訓練 (Llama‑3.2 1B)： - 預訓練：axolotl train examples/llama-3/diffusion-3.2-1b-pretrain.yaml - SFT：axolotl train examples/llama-3/diffusion-3.2-1b-sft.yaml

您也可以修改現有配置以啟用/自定義擴散訓練。

將以下內容新增至您的 Axolotl 配置：

並且，配置巢狀的 diffusion 區塊（顯示為預設值）：

任何支援 4D 注意力遮罩的模型都應該可以開箱即用。如果不行，請建立 Issue 或開啟 PR！

在訓練期間，標記會隨機被屏蔽： - 從 [0, 1] 中均勻取樣時間步長 t - 計算屏蔽機率：p = (1 - eps) * t + eps - 以機率 p 隨機屏蔽標記

損失僅在被屏蔽的標記上計算，並帶有（選填的）關鍵性權重：

當 diffusion.generate_samples: true 時，插件會在訓練期間產生樣本：

樣本會記錄到控制台和 wandb（如果已啟用）。

擴散推理已整合到標準 Axolotl CLI 中。使用您訓練時相同的配置並執行：

選填，傳遞 --gradio 以使用簡單的網頁介面。

互動式控制（在提示前加上命令）： - :complete N → 補完模式，附加 N 個新的被屏蔽標記（預設 64） - :mask R → 隨機屏蔽模式，目標屏蔽比例 R 介於 [0.0, 1.0]

該插件增加了（或修改了）多項指標以追蹤擴散訓練：

請參閱此處的參考資料。

參見 https://github.com/ironjr/grokfast

請參閱此處的參考資料。

範例資料集可以在此找到：axolotl-ai-co/evolkit-logprobs-pipeline-75k-v2-sample

請參閱此處的參考資料。

使用 Neural Magic 的 LLMCompressor 在 Axolotl 中微調稀疏化模型 (sparsified models)。

此整合實現了在 Axolotl 訓練框架內微調使用 LLMCompressor 稀疏化的模型。透過將 LLMCompressor 的模型壓縮能力與 Axolotl 的分佈式訓練管道結合，使用者可以大規模地高效微調稀疏模型。

它使用 Axolotl 的插件系統掛鉤到微調流程中，同時在整個訓練過程中保持稀疏性。

Axolotl 帶有 llmcompressor 額外組件：

需要 llmcompressor >= 0.5.1

這將安裝使用該整合微調稀疏化模型所需的所有相依項。

要使用此整合啟用稀疏微調，請在您的 Axolotl 配置中包含該插件：

此插件本身不執行剪枝 (pruning) 或稀疏化 - 它是用於微調已經過稀疏化的模型。

預先稀疏化的 checkpoint 可以是： - 使用 LLMCompressor 產生 - 從 Neural Magic 的 Hugging Face 頁面下載 - 您自己建立的任何具有相容稀疏模式的自定義 LLM

要瞭解更多關於編寫和自定義 LLMCompressor 配方 (recipes) 的資訊，請參考官方文件：https://github.com/vllm-project/llm-compressor/blob/main/README.md

在配置中設定 save_compressed: true 可啟用以壓縮格式儲存模型，這將： - 減少約 40% 的磁碟空間佔用 - 保持與 vLLM 的相容性以實現加速推理 - 保持與 llmcompressor 的相容性以進一步優化（例如：量化）

處理稀疏模型時強烈建議開啟此選項，以最大化模型壓縮的好處。

請參閱 examples/llama-3/sparse-finetuning.yaml 以獲取完整範例。

微調您的稀疏模型後，您可以利用 vLLM 進行高效推理。您也可以在推理前使用 LLMCompressor 對微調後的稀疏模型應用額外的量化，以獲得更大的效能收益。

有關 vLLM 能力和進階配置選項的更多細節，請參閱 vLLM 官方文件。

有關可用稀疏和量化方案、微調配方和用法範例的詳細資訊，請訪問 LLMCompressor 官方儲存庫：

https://github.com/vllm-project/llm-compressor

請參閱此處的參考資料。

使用流行的 lm-evaluation-harness 函式庫在模型上執行評估。

參見 https://github.com/EleutherAI/lm-evaluation-harness

請參閱此處的參考資料。

Liger Kernel 為 LLM 訓練提供高效的 Triton 核心，提供：

參見 https://github.com/linkedin/Liger-Kernel

請參閱此處的參考資料。

由 Eric Hartford, Lucas Atkins, Fernando Fernandes, David Golchinfar 建立。

此插件包含基於信噪比 (Signal-to-Noise Ratio, SNR) 凍結模型底層部分模組的程式碼。

參見 https://github.com/cognitivecomputations/spectrum

Spectrum 是一個用於掃描和評估大型語言模型層級信噪比 (SNR) 的工具。透過識別 SNR 最高的前 n% 層，您可以優化訓練效率。

請參閱此處的參考資料。

插件可用於透過掛鉤 (hooks) 自定義訓練管道的行為。關於可能的掛鉤，請參閱 axolotl.integrations.BasePlugin。

要新增整合，請按照以下步驟操作：

參見 src/axolotl/integrations/cut_cross_entropy 以獲取最簡整合範例。

如果您無法載入您的整合，請確保您正在以可編輯模式執行 pip 安裝。

並在配置文件中正確拼寫整合名稱。

並不一定要將您的整合放在 integrations 資料夾中。它可以放在任何位置，只要它安裝在您的 Python 環境中的套件中即可。

參見此儲存庫以獲取範例：https://github.com/axolotl-ai-cloud/diff-transformer

**範例：**

範例 1 (bash):
```bash
python scripts/cutcrossentropy_install.py | sh
```

範例 2 (bash):
```bash
pip3 uninstall -y cut-cross-entropy && pip3 install "cut-cross-entropy[transformers] @ git+https://github.com/axolotl-ai-cloud/ml-cross-entropy.git@8a1a0ec"
```

範例 3 (yaml):
```yaml
plugins:
  - axolotl.integrations.cut_cross_entropy.CutCrossEntropyPlugin
```

範例 4 (unknown):
```unknown
@article{wijmans2024cut,
  author       = {Erik Wijmans and
                  Brody Huval and
                  Alexander Hertzberg and
                  Vladlen Koltun and
                  Philipp Kr\"ahenb\"uhl},
  title        = {Cut Your Losses in Large-Vocabulary Language Models},
  journal      = {arXiv},
  year         = {2024},
  url          = {https://arxiv.org/abs/2411.09009},
}
```

---

## 配置參考 (Config Reference)

**URL:** https://docs.axolotl.ai/docs/config-reference.html

**內容：**
- 配置參考

**範例：**

範例 1 (yaml):
```yaml
# 允許從 cli 覆寫 yml 配置
strict: bool | None = False
# 從特定的 checkpoint 目錄恢復
resume_from_checkpoint: str | None
# 如果未設定 resume_from_checkpoint，且您只想從上次中斷的地方開始。
# 在不同模型之間切換時，請小心開啟此項。
auto_resume_from_checkpoints: bool | None
# 當新增新標記時，將模型嵌入調整為 32 的倍數。據報導
# 這可以在某些模型上提高訓練速度。
resize_token_embeddings_to_32x: bool | None
mean_resizing_embeddings: bool | None = False

# 是否將嵌入縮減為 len(tokenizer)。預設情況下，我們不會縮減。
shrink_embeddings: bool | None
# 使用 PEFT 時不要將嵌入向上轉型為 float32。對於低 VRAM 的 GPU 很有用
embeddings_skip_upcast: bool | None
# 隨機重新初始化模型權重，而不是載入預訓練權重
reinit_weights: bool | None

# 用於訓練的自定義訓練器類別模組
trainer_cls: str | None

# 使用 RL 訓練：'dpo', 'ipo', 'kto', 'simpo', 'orpo', 'grpo'
rl: RLType | None

trl: TRLConfig | None
  # 對於 TRLConfig：
  # RL 訓練的 Beta 參數。與 `rl_beta` 相同。
  beta: float | None
  # RL 訓練完成後的最大長度。
  max_completion_length: int | None

  # 是否為 RL 訓練使用 VLLM。
  use_vllm: bool = False
  # 使用的 VLLM 模式，'server' 或 'colocate' 之一
  vllm_mode: Literal['server', 'colocate'] | None
  # 要連線的 vLLM 伺服器主機。
  vllm_server_host: str | None = 0.0.0.0
  # 要連線的 vLLM 伺服器通訊埠。
  vllm_server_port: int | None = 8000
  # 等待 vLLM 伺服器回應的總逾時（以秒為單位）。
  vllm_server_timeout: int | None
  # 用於 vLLM 引導式解碼 (guided decoding) 的正規表示式。
  vllm_guided_decoding_regex: str | None

  # 要載入的獎勵函數列表。路徑必須可以從目前目錄匯入。
  reward_funcs: list[str] | None
  # 獎勵函數的獎勵權重列表。
  reward_weights: list[float] | None
  # 要取樣的產生次數。
  num_generations: int | None
  # 是否記錄完成結果 (completions)。
  log_completions: bool | None = False
  # 當 log_completions 為 True 時要列印的完成結果數量。
  num_completions_to_print: int | None
  # 控制關鍵性採樣比例是在 `'token'` 還是 `'sequence'` 層級計算。
  # 對於 GSPO，使用 `sequence`，預設為 None，對應原始 GRPO 論文。
  importance_sampling_level: Literal['sequence', 'token'] | None

  # 是否同步參考模型。
  sync_ref_model: bool | None = False
  # 參考模型的 Mixup alpha。
  ref_model_mixup_alpha: float | None = 0.9
  # 參考模型的同步步數。
  ref_model_sync_steps: int | None = 64
  # 是否按標準差縮放獎勵。
  scale_rewards: bool = True

  # GRPO 策略的取樣溫度 (temperature)。
  temperature: float | None
  # 產生策略的 Top-p 取樣機率。
  top_p: float | None
  # 產生策略的 Top-k 取樣。
  top_k: int | None
  # 產生策略的最小機率。
  min_p: float | None
  # 對出現在提示和產生文本中的標記的懲罰。
  repetition_penalty: float | None
  # GRPO 每批次的迭代次數 (μ)。
  num_iterations: int | None
  # GRPO 演算法中用於剪取 (clipping) 的 epsilon 值。
  epsilon: float | None
  # GRPO 演算法中用於剪取的上限 epsilon 值。
  epsilon_high: float | None
  # 是否為 GRPO 使用 Liger loss。
  use_liger_loss: bool | None
  # 使用的損失公式。支援的值：grpo, bnpo, dr_grpo。
  loss_type: str | None
  # 是否從損失計算中排除被截斷的完成結果。
  mask_truncated_completions: bool = False
  # 啟用 vLLM 閒置時卸載 VRAM 的睡眠模式
  vllm_enable_sleep_mode: bool | None

vllm: VllmConfig | None
  # 對於 VllmConfig：
  # VLLM 使用的設備
  device: str | None = auto
  # VLLM 的張量平行大小 (tensor parallel size)
  tensor_parallel_size: int | None
  # VLLM 的資料平行大小 (data parallel size)
  data_parallel_size: int | None
  # VLLM 的 GPU 記憶體利用率
  gpu_memory_utilization: float | None = 0.9
  # VLLM 的資料類型
  dtype: str | None = auto
  # VLLM 的模型上下文最大長度
  max_model_len: int | None
  # 為 VLLM 啟用字首快取 (prefix caching)
  enable_prefix_caching: bool | None
  # vLLM 伺服器啟動的主機
  host: str | None = 0.0.0.0
  # vLLM 伺服器啟動的通訊埠
  port: int | None = 8000

  # 為 VLLM 啟用推理
  enable_reasoning: bool | None
  # VLLM 的推理解析器
  reasoning_parser: str | None

qat: QATConfig | None
  # 對於 QATConfig：
  # 用於激活量化的虛假量化佈局。
  activation_dtype: TorchAOQuantDType | None
  # 用於權重量化的虛假量化佈局。
  weight_dtype: TorchAOQuantDType = TorchAOQuantDType.int8
  # 量化嵌入
  quantize_embedding: bool | None = False
  # 每個組中用於逐組虛假量化的元素數量
  group_size: int | None = 32
  # 在多少步之後應用虛假量化
  fake_quant_after_n_steps: int | None

quantization: PTQConfig | None
  # 對於 PTQConfig：
  # 用於權重量化的虛假量化佈局。
  weight_dtype: TorchAOQuantDType = TorchAOQuantDType.int8
  # 用於激活量化的虛假量化佈局。
  activation_dtype: TorchAOQuantDType | None
  # 是否對嵌入層進行量化。
  quantize_embedding: bool | None
  # 每個組中用於逐組虛假量化的元素數量
  group_size: int | None = 32

# 獎勵建模：`True` 或 `False`
reward_model: bool | None
# 過程獎勵建模：`True` 或 `False`
process_reward_model: bool | None
# 激勵獎勵模型輸出均值為零獎勵的係數（由 https://huggingface.co/papers/2312.09244 提出）。推薦值：`0.01`。
center_rewards_coefficient: float | None
num_labels: int | None

# 是否在 DPO 訓練器中執行加權
dpo_use_weighting: bool | None
dpo_use_logits_to_keep: bool | None
dpo_label_smoothing: float | None
dpo_norm_loss: bool | None
dpo_padding_free: bool | None
dpo_generate_during_eval: bool | None

# 用於微調模型的一個或多個資料集列表
datasets: Annotated[list[SFTDataset | DPODataset | KTODataset | StepwiseSupervisedDataset], MinLen(1)] | None
  # 對於 SFTDataset：
  # HuggingFace 資料集 repo | s3:// | gs:// | 本地檔案或目錄路徑
  path: str | None
  # 要載入的資料集切分 (split) 名稱
  split: str | None
  # 用於訓練的提示類型。[alpaca, gpteacher, oasst, reflection]
  type: str | UserDefinedPrompterType | None
    # 對於 UserDefinedPrompterType：
    # 自定義使用者指令提示
    system_prompt: str | None
    # 使用 {system} 作為要替換的鍵
    system_format: str | None
    field_system: str | None
    field_instruction: str | None
    field_input: str | None
    field_output: str | None

    # 可自定義為單行或多行。使用 {instruction}/{input} 作為要替換的鍵。'format' 可以包含 {input}
    format: str | None
    # 'no_input_format' 不能包含 {input}
    no_input_format: str | None
  input_transform: str | None
  # 將資料集切分為 N 份（與 shards_idx 搭配使用）
  shards: int | None
  # 使用的切分資料集索引
  shards_idx: int | None
  # 為了記憶體效率，將資料集分 N 個連續區塊處理（與 `shards` 互斥）
  preprocess_shards: int | None
  conversation: str | None

  # 用於訓練的聊天模板名稱，支援以下值：
  # tokenizer_default：使用 tokenizer_config.json 中可用的聊天模板。
  # 如果標記器中沒有聊天模板，則會報錯。這是預設值。
  # alpaca/inst/chatml/gemma/cohere/llama3/phi_3/deepseek_v2/jamba：
  # 這些聊天模板可在 Axolotl 程式碼中的 src/axolotl/utils/chat_templates.py 找到。
  # tokenizer_default_fallback_*：其中 * 是當標記器沒有聊天模板時要備援使用的聊天模板名稱。
  # 例如 tokenizer_default_fallback_chatml。
  # jinja：為聊天模板使用自定義 jinja 模板。自定義 jinja 模板應在 chat_template_jinja 欄位中提供。
  chat_template: ChatTemplate | str | None
  # 自定義 jinja 聊天模板或 jinja 檔案路徑。僅在 `chat_template: jinja` 或留空時使用。
  chat_template_jinja: str | None
  # 來源數據檔案路徑
  data_files: str | list[str] | None
  input_format: str | None
  # 要載入的資料集配置名稱
  name: str | None
  # 當 path 是檔案時定義資料類型
  ds_type: str | None
  # 僅針對 `completion` 資料集，使用提供的欄位而非 `text` 列
  field: str | None
  field_human: str | None
  field_model: str | None
  # 包含訊息的鍵（預設："messages"）
  field_messages: str | None
  # 包含工具的鍵（預設："tools"）。必須是一個列表[dict]並遵循 JSON schema。
  field_tools: str | None
  # 包含推理軌跡的鍵（預設："reasoning_content"）。
  field_thinking: str | None
  # 聊天模板預期指示推理軌跡的鍵。
  template_thinking_key: str | None

  message_field_role: str | None

  message_field_content: str | None
  # 從輸入資料集到聊天模板的屬性映射。（預設：message_property_mappings={'role':'role', 'content':'content'}）
  # 如果模板中存在某個屬性但在此映射中不存在，系統將嘗試直接使用屬性名稱作為鍵從訊息中載入。
  # 範例：在下面的映射中，'from' 從輸入資料集載入並用作 'role'，而 'value' 被載入並用作聊天模板中的 'content'。
  message_property_mappings: dict[str, str] | None
  # 訊息輪次中的鍵，透過布林值指示該輪次的標記是否應用於訓練。
  # 除了 `roles_to_train` 之外，對於選擇性地在某些輪次進行訓練很有用。
  message_field_training: str | None
  # 訊息輪次中的鍵，包含訓練細節。對於選擇性地在輪次中的某些標記進行訓練很有用。
  # 該鍵的值是一個 List[Dict]，包含 `begin_offset` (內容中的起始字元索引)、
  # `end_offset` (內容中的結束字元索引) 和 `train` (是否訓練的布林值)。
  message_field_training_detail: str | None
  # (僅針對 Qwen3 模板) 是否根據分隔標籤內的推理軌跡拆分助理內容
  split_thinking: bool | None
  logprobs_field: str | None
  temperature: float | None
  # 要訓練的角色。這些角色的標記將被考慮用於損失計算。
  roles_to_train: list[str] | None
  # 對話中要訓練哪些 EOS 標記。可能的值有：all：訓練所有 EOS 標記，
  # turn (預設)：訓練每個可訓練輪次末尾的 EOS 標記，last：訓練對話中最後一個 EOS 標記
  train_on_eos: Literal['all', 'turn', 'last'] | None
  # 訊息中的角色映射。格式為 {target_role: [source_roles]}。所有來源角色都將映射到目標角色。
  # 預設為：user: ["human", "user"], assistant: ["gpt", "assistant"], system: ["system"], tool: ["tool"]
  roles: dict[str, list[str]] | None
  # 是否從資料集中捨棄系統訊息。僅適用於 chat_template。
  # 這不會捨棄 chat_template 中存在的預設系統訊息。如果您希望捨棄，我們建議使用移除了預設系統訊息的自定義 jinja 模板，或者新增一個內容為空的系統輪次。
  drop_system_message: bool | None
  # 為不信任的來源啟用 trust_remote_code
  trust_remote_code: bool | None = False
  # 從 Hugging Face Hub 載入時要使用的特定資料集版本。
  # 這可以是 commit hash、tag 或分支名稱。如果未指定，將使用最新版本。此參數對於本地資料集將被忽略。
  revision: str | None

  # 對於 DPODataset：
  path: str | None
  split: str | None
  type: UserDefinedDPOType | str | None
    # 對於 UserDefinedDPOType：
    field_system: str | None
    field_prompt: str | None
    field_chosen: str | None
    field_rejected: str | None
    prompt_format: str | None
    chosen_format: str | None
    rejected_format: str | None
  data_files: list[str] | None
  revision: str | None
  field_messages: str | None

  # 對於 KTODataset：
  path: str | None
  split: str | None
  type: UserDefinedKTOType | str | None
    # 對於 UserDefinedKTOType：
    field_system: str | None
    field_prompt: str | None
    field_completion: str | None
    field_label: bool | None
    prompt_format: str | None
    completion_format: str | None
  data_files: list[str] | None
  trust_remote_code: bool | None = False
  revision: str | None

  # 對於 StepwiseSupervisedDataset：
  path: str | None
  split: str | None
  data_files: list[str] | None
  revision: str | None
  step_separator: str | None
  max_completion_length: int | None
  train_on_last_step_only: bool | None

# 如果為 false，資料集將不會被打亂，並將保持其在 `datasets` 中的原始順序。
# 這同樣適用於 `test_datasets` 選項和 `pretraining_dataset` 選項。預設為 true。
shuffle_merged_datasets: bool | None = True
# 如果為 true，`datasets` 中的每個資料集將在合併前打亂。這允許在資料集層級應用課程學習 (curriculum learning) 策略。預設為 false。
shuffle_before_merging_datasets: bool | None = False
# Axolotl 嘗試在打包數據後將資料集儲存為 arrow，以便隨後的訓練嘗試載入更快，相對路徑
dataset_prepared_path: str | None
# 整個資料集的切分 (shards) 數量
dataset_shard_num: int | None
# 整個資料集要使用的切分索引
dataset_shard_idx: int | None
skip_prepare_dataset: bool | None = False
# 儲存準備好的資料集的切分數量
num_dataset_shards_to_save: int | None

# 設定為 HF 資料集類型：'completion' 用於串流而非預標記化
pretraining_dataset: Annotated[list[PretrainingDataset | SFTDataset], MinLen(1)] | None
  # 對於 PretrainingDataset：
  name: str | None
  path: str | None
  split: str | None = train
  text_column: str | None = text
  type: str | None = pretrain
  trust_remote_code: bool | None = False
  data_files: str | None
  skip: int | None

  # 對於 SFTDataset：
  # HuggingFace 資料集 repo | s3:// | gs:// | 本地檔案或目錄路徑
  path: str | None
  # 要載入的資料集切分名稱
  split: str | None
  # 用於訓練的提示類型。[alpaca, gpteacher, oasst, reflection]
  type: str | UserDefinedPrompterType | None
    # 對於 UserDefinedPrompterType：
    # 自定義使用者指令提示
    system_prompt: str | None
    # 使用 {system} 作為要替換的鍵
    system_format: str | None
    field_system: str | None
    field_instruction: str | None
    field_input: str | None
    field_output: str | None

    # 可自定義為單行或多行。使用 {instruction}/{input} 作為要替換的鍵。'format' 可以包含 {input}
    format: str | None
    # 'no_input_format' 不能包含 {input}
    no_input_format: str | None
  input_transform: str | None
  # 將資料集切分為 N 份（與 shards_idx 搭配使用）
  shards: int | None
  # 使用的切分資料集索引
  shards_idx: int | None
  # 為了記憶體效率，將資料集分 N 個連續區塊處理（與 `shards` 互斥）
  preprocess_shards: int | None
  conversation: str | None

  # 用於訓練的聊天模板名稱，支援以下值：
  # tokenizer_default：使用 tokenizer_config.json 中可用的聊天模板。
  # 如果標記器中沒有聊天模板，則會報錯。這是預設值。
  # alpaca/inst/chatml/gemma/cohere/llama3/phi_3/deepseek_v2/jamba：
  # 這些聊天模板可在 Axolotl 程式碼中的 src/axolotl/utils/chat_templates.py 找到。
  # tokenizer_default_fallback_*：其中 * 是當標記器沒有聊天模板時要備援使用的聊天模板名稱。
  # 例如 tokenizer_default_fallback_chatml。
  # jinja：為聊天模板使用自定義 jinja 模板。自定義 jinja 模板應在 chat_template_jinja 欄位中提供。
  chat_template: ChatTemplate | str | None
  # 自定義 jinja 聊天模板或 jinja 檔案路徑。僅在 `chat_template: jinja` 或留空時使用。
  chat_template_jinja: str | None
  # 來源數據檔案路徑
  data_files: str | list[str] | None
  input_format: str | None
  # 要載入的資料集配置名稱
  name: str | None
  # 當 path 是檔案時定義資料類型
  ds_type: str | None
  # 僅針對 `completion` 資料集，使用提供的欄位而非 `text` 列
  field: str | None
  field_human: str | None
  field_model: str | None
  # 包含訊息的鍵（預設："messages"）
  field_messages: str | None
  # 包含工具的鍵（預設："tools"）。必須是一個列表[dict]並遵循 JSON schema。
  field_tools: str | None
  # 包含推理軌跡的鍵（預設："reasoning_content"）。
  field_thinking: str | None
  # 聊天模板預期指示推理軌跡的鍵。
  template_thinking_key: str | None

  message_field_role: str | None

  message_field_content: str | None
  # 從輸入資料集到聊天模板的屬性映射。（預設：message_property_mappings={'role':'role', 'content':'content'}）
  # 如果模板中存在某個屬性但在此映射中不存在，系統將嘗試直接使用屬性名稱作為鍵從訊息中載入。
  # 範例：在下面的映射中，'from' 從輸入資料集載入並用作 'role'，而 'value' 被載入並用作聊天模板中的 'content'。
  message_property_mappings: dict[str, str] | None
  # 訊息輪次中的鍵，透過布林值指示該輪次的標記是否應用於訓練。
  # 除了 `roles_to_train` 之外，對於選擇性地在某些輪次進行訓練很有用。
  message_field_training: str | None
  # 訊息輪次中的鍵，包含訓練細節。對於選擇性地在輪次中的某些標記進行訓練很有用。
  # 該鍵的值是一個 List[Dict]，包含 `begin_offset` (內容中的起始字元索引)、
  # `end_offset` (內容中的結束字元索引) 和 `train` (是否訓練的布林值)。
  message_field_training_detail: str | None
  # (針對 Qwen3 模板) 是否根據分隔標籤內的推理軌跡拆分助理內容
  split_thinking: bool | None
  logprobs_field: str | None
  temperature: float | None
  # 要訓練的角色。這些角色的標記將被考慮用於損失計算。
  roles_to_train: list[str] | None
  # 對話中要訓練哪些 EOS 標記。可能的值有：all：訓練所有 EOS 標記，
  # turn (預設)：訓練每個可訓練輪次末尾的 EOS 標記，last：訓練對話中最後一個 EOS 標記
  train_on_eos: Literal['all', 'turn', 'last'] | None
  # 訊息中的角色映射。格式為 {target_role: [source_roles]}。所有來源角色都將映射到目標角色。
  # 預設為：user: ["human", "user"], assistant: ["gpt", "assistant"], system: ["system"], tool: ["tool"]
  roles: dict[str, list[str]] | None
  # 是否從資料集中捨棄系統訊息。僅適用於 chat_template。
  # 這不會捨棄 chat_template 中存在的預設系統訊息。如果您希望捨棄，我們建議使用移除了預設系統訊息的自定義 jinja 模板，或者新增一個內容為空的系統輪次。
  drop_system_message: bool | None
  # 為不信任的來源啟用 trust_remote_code
  trust_remote_code: bool | None = False
  # 從 Hugging Face Hub 載入時要使用的特定資料集版本。
  # 這可以是 commit hash、tag 或分支名稱。如果未指定，將使用最新版本。此參數對於本地資料集將被忽略。
  revision: str | None

# 預處理輸入資料集時要使用的最大進程數。如果未設定，預設為 `os.cpu_count()`。
# 對於 Runpod VM，將透過 RUNPOD_CPU_COUNT 預設為 vCPU 數量。
dataset_processes: int | None
# 預處理輸入資料集時要使用的最大進程數。如果未設定，預設為 `os.cpu_count()`。
# 對於 Runpod VM，將透過 RUNPOD_CPU_COUNT 預設為 vCPU 數量。
dataset_num_proc: int | None

# 將具有相同內容的 datasets 和 test_datasets 進行去重
dataset_exact_deduplication: bool | None
# 預處理時將資料集保留在記憶體中。僅在快取的資料集佔用過多儲存空間時才需要
dataset_keep_in_memory: bool | None
dataloader_pin_memory: bool | None
dataloader_num_workers: int | None
dataloader_prefetch_factor: int | None
dataloader_drop_last: bool | None

accelerator_config: dict[str, Any] | None

remove_unused_columns: bool | None

# 將準備好的資料集推送到 hub - repo_org/repo_name
push_dataset_to_hub: str | None
# 是否在載入資料集時使用 hf `use_auth_token`。用於獲取私有資料集。
# 與 `push_dataset_to_hub` 結合使用時必須為 true。
hf_use_auth_token: bool | None

device: Any | None
# 當未使用 accelerate 啟動時，傳遞給載入模型的 transformers。
# 訓練時使用模型平行 (model parallelism) 時使用 `sequential` 以限制記憶體
device_map: Any | None
world_size: int | None
# 請勿更改此項，這是給 accelerate 和 torchrun 使用的
local_rank: int | None
ddp: bool | None

# 用於可重複性的種子 (Seed)
seed: int | None
# 進階 DDP 參數 - 逾時 (timeout)
ddp_timeout: int | None
# 進階 DDP 參數 - bucket 容量 (以 MB 為單位)
ddp_bucket_cap_mb: int | None
# 進階 DDP 參數 - broadcast buffers
ddp_broadcast_buffers: bool | None
ddp_find_unused_parameters: bool | None

# 傳送到 wandb 的預估預測數量，取決於批次大小。大於 0 時啟用。預設為 0
eval_table_size: int | None
# 傳送到 wandb 的預測結果所產生的總標記數。預設為 128
eval_max_new_tokens: int | None
# 是否為 `eval_causal_lm_metrics` 中的指標執行因果語言模型評估
do_causal_lm_eval: bool | None
# 評估期間使用的 HF 評估指標。預設為 ['sacrebleu', 'comet', 'ter', 'chrf', 'perplexity']
eval_causal_lm_metrics: list[str] | None
do_bench_eval: bool | None
bench_dataset: str | None
bench_split: str | None
metric_for_best_model: str | None
greater_is_better: bool | None

# 高損失值，表示學習已崩潰（一個好的估計值是訓練開始時損失的約 2 倍）
loss_watchdog_threshold: float | None
# 在訓練器中止前，連續出現高損失步驟的次數（預設：3）
loss_watchdog_patience: int | None

# 每 `gc_steps` 步執行一次垃圾回收。-1 將在 epoch 結束和評估前執行。預設為 0（停用）。
gc_steps: int | None

# 使用 CUDA bf16。布林值，或用 'full' 表示 `bf16_full_eval`，或用 'auto' 進行自動偵測。
# 需要 >=ampere
bf16: Literal['auto'] | bool | None = auto
# 使用 CUDA fp16
fp16: bool | None
# 使用 TorchAO 啟用 FP8 混合精度訓練。最好與 torch.compile 結合使用。
fp8: bool | None
# 為 FP8 訓練啟用 FSDP float8 all-gather 優化。啟用 FSDP 時可將訓練速度提高 10-15%。
fp8_enable_fsdp_float8_all_gather: bool | None
# 無 AMP (自動混合精度) - 需要 >=ampere
bfloat16: bool | None
# 無 AMP (自動混合精度)
float16: bool | None
# 使用 CUDA tf32 - 需要 >=ampere
tf32: bool | None
float32: bool | None

# 是否使用梯度檢查點 (gradient checkpointing)。可用選項有：true, false, 'offload', 'offload_disk'。
# https://huggingface.co/docs/transformers/v4.18.0/en/performance#gradient-checkpointing
gradient_checkpointing: Literal['offload', 'offload_disk'] | bool | None = False
# 傳遞給訓練器用於梯度檢查點的其他關鍵字參數
gradient_checkpointing_kwargs: dict[str, Any] | None
# 是否卸載激活函數 (offload activations)。可用選項有：true, false, 'legacy', 'disk'。
activation_offloading: Literal['legacy', 'disk'] | bool | None = False

unfrozen_parameters: list[str] | None

# 用於訓練的輸入最大長度，這通常應小於 2048，因為大多數模型有 2048 的標記/上下文限制
sequence_len: int = 512
# 當標記化的行超過 sequence_len 時該怎麼辦。'drop' 移除該行；'truncate' 將張量截斷至 sequence_len。
# 為了向後相容性，預設為 'drop'。
excess_length_strategy: Literal['drop', 'truncate'] | None
# 用於評估的輸入最大長度。如果未指定，預設為 sequence_len
eval_sequence_len: int | None
min_sample_len: int | None
# RL 訓練的最大提示長度
max_prompt_len: int | None
# 使用塊對角線注意力 (block diagonal attention) 和每序列 position_ids 進行高效多重打包。推薦設為 'true'
sample_packing: bool | None
# 一次打包的樣本數量。增加以下值有助於打包，但通常效果有限 (<%1.)
sample_packing_group_size: int | None = 100000
# 可打包進一個序列的樣本數量。如果使用大 sequence_len 且有很多短樣本，請增加此值。
sample_packing_bin_size: int | None = 200
# 是否按順序打包樣本
sample_packing_sequentially: bool | None
# 用於打包的多進程啟動方法。應為 'fork', 'spawn' 或 'forkserver'
sample_packing_mp_start_method: str | None
# 如果在開啟 sample_packing 的評估過程中出錯，請設為 'false'
eval_sample_packing: bool | None
# 填充輸入，使每一步都使用恆定大小的緩衝區。這將減少記憶體碎片，並可能透過更高效地重用記憶體來防止 OOM。
# 如果啟用了 `sample_packing`，則預設為 True
pad_to_sequence_len: bool | None
# 是否使用順序採樣進行課程學習
curriculum_sampling: bool | None
multipack_real_batches: bool | None

# 不使用 sample_packing 時，使用批次扁平化 (batch flattening) 來加速
batch_flattening: Literal['auto'] | bool | None

use_pose: bool | None
pose_split_on_token_ids: list[int] | None
pose_max_context_len: int | None
pose_num_chunks: int | None

pretrain_multipack_buffer_size: int | None
# 預訓練期間是否防止打包序列的交叉注意力 (cross attention)
pretrain_multipack_attn: bool | None = True
# 預訓練期間是否串接樣本
pretraining_sample_concatenation: bool | None

# 使用串流模式載入資料集
streaming: bool | None
# 多重打包串流資料集的緩衝區大小
streaming_multipack_buffer_size: int | None = 10000

# 是否使用 xformers 注意力補丁 https://github.com/facebookresearch/xformers
xformers_attention: bool | None
# 是否使用縮放點積注意力 (scaled-dot-product attention) https://pytorch.org/docs/stable/generated/torch.nn.functional.scaled_dot_product_attention.html
sdp_attention: bool | None
# 偏移稀疏注意力 (Shifted-sparse attention) (僅針對 llama) - https://arxiv.org/pdf/2309.12307.pdf
s2_attention: bool | None
flex_attention: bool | None
flex_attn_compile_kwargs: dict[str, Any] | None
# 是否使用 flash attention 補丁 https://github.com/Dao-AILab/flash-attention
flash_attention: bool | None
# 是否使用 flash-attention 交叉熵實作 - 僅限進階使用
flash_attn_cross_entropy: bool | None
# 是否使用 flash-attention rms norm 實作 - 僅限進階使用
flash_attn_rms_norm: bool | None
# 是否將 MLP 的一部分融合到單個操作中
flash_attn_fuse_mlp: bool | None
# 是否使用 bettertransformers
flash_optimum: bool | None

eager_attention: bool | None

# 指定自定義注意力實作，主要用於核心 (kernels)。
attn_implementation: str | None

unsloth_cross_entropy_loss: bool | None
unsloth_lora_mlp: bool | None
unsloth_lora_qkv: bool | None
unsloth_lora_o: bool | None
unsloth_rms_norm: bool | None
unsloth_rope: bool | None

# 應用自定義 LoRA autograd 函數和激活函數 Triton 核心，以節省速度和記憶體。參見：https://docs.axolotl.ai/docs/lora_optims.html
lora_mlp_kernel: bool | None
# 應用自定義 LoRA autograd 函數和激活函數 Triton 核心，以節省速度和記憶體。參見：https://docs.axolotl.ai/docs/lora_optims.html
lora_qkv_kernel: bool | None
# 應用自定義 LoRA autograd 函數和激活函數 Triton 核心，以節省速度和記憶體。參見：https://docs.axolotl.ai/docs/lora_optims.html
lora_o_kernel: bool | None

# 是否使用分塊交叉熵損失以提高記憶體效率
chunked_cross_entropy: bool | None
# 用於分塊交叉熵損失的分塊數量
chunked_cross_entropy_num_chunks: int | None

# 是否使用 ALST 平鋪 MLP (tiled mlp) 以實現記憶體高效的長上下文
tiled_mlp: bool | None

# ALST 平鋪 MLP 使用的分片數量。如果未設定，將根據 seqlen/hidden_size 設定
tiled_mlp_num_shards: int | None

# 是否為 ALST 平鋪 MLP 使用原始 MLP。否則使用基於 llama 的通用 MLP。
tiled_mlp_use_original_mlp: bool | None = True

llama4_linearized_experts: bool | None

# Deepspeed 配置路徑。例如：deepspeed_configs/zero3.json
deepspeed: str | dict[str, Any] | None
# 是否使用 deepcompile 配合 deepspeed 進行更快訓練
deepcompile: bool | None
# FSDP 配置
fsdp: list[str] | None

# FSDP 配置選項
fsdp_config: FSDPConfig | None
  # 對於 FSDPConfig：
  # 啟用激活檢查點以在正向傳遞期間減少記憶體使用
  activation_checkpointing: bool | None
  # 將參數卸載到 CPU 以減少 GPU 記憶體使用
  offload_params: bool | None
  # 在所有進程中同步模組狀態
  sync_module_states: bool | None
  # 啟用 CPU RAM 高效載入以在模型載入期間減少記憶體使用
  cpu_ram_efficient_loading: bool | None
  # 當啟用 offload_params 時，停用此項可為資源受限的設定啟用 swap 記憶體使用。
  cpu_offload_pin_memory: bool | None
  # 使用原始參數而非扁平化參數
  use_orig_params: bool | None

  # 用於儲存/載入 checkpoint 的狀態字典類型
  state_dict_type: Literal['FULL_STATE_DICT', 'LOCAL_STATE_DICT', 'SHARDED_STATE_DICT'] | None
  # 訓練完成後使用的最終狀態字典類型
  final_state_dict_type: Literal['FULL_STATE_DICT', 'LOCAL_STATE_DICT', 'SHARDED_STATE_DICT'] | None

  # 自動用 FSDP 包裝模組的策略
  auto_wrap_policy: Literal['TRANSFORMER_BASED_WRAP', 'SIZE_BASED_WRAP'] | None
  # 要包裝的 transformer 層類別名稱（例如：'LlamaDecoderLayer'）
  transformer_layer_cls_to_wrap: str | None

  # 在正向傳遞後重新分片參數以節省記憶體
  reshard_after_forward: bool | None
  # FSDP 的混合精度策略（例如：'fp16', 'bf16'）
  mixed_precision_policy: str | None

# FSDP 版本
fsdp_version: int | None
fsdp_final_state_dict_type: Literal['FULL_STATE_DICT', 'LOCAL_STATE_DICT', 'SHARDED_STATE_DICT'] | None

# 資料集留作評估的比例。1 = 100%, 0.50 = 50% 等。0 表示不評估。
val_set_size: float | None = 0.0

# 分片設備數量。如果未設定，將使用所有可用設備。
dp_shard_size: int | None
# 複製設備數量。
dp_replicate_size: int | None
# 已棄用：請改用 `context_parallel_size`
sequence_parallel_degree: int | None
# 設定為可用 GPU 數量的因數，將序列拆分為大小相等的塊。
# 在長上下文訓練中使用，以防止序列無法裝入單個 GPU 的 VRAM 時發生 OOM。
# 例如，如果有 4 個 GPU 可用，將此值設為 2 將每個序列拆分為兩個大小相等的子序列，
# 或設為 4 拆分為四個大小相等的子序列。
# 更多詳情請參見 https://docs.axolotl.ai/docs/sequence_parallelism.html。
context_parallel_size: int | None
# 選填；在 key 維度上跨越步長。較大的值使用更多記憶體，但應能加快訓練速度。必須能整除模型中的 KV 頭數。
heads_k_stride: int | None
# 'varlen_llama3', 'batch_ring', 'batch_zigzag', 'batch_stripe' 之一。
# 在樣本打包情況下預設為 'varlen_llama3'，在非樣本打包情況下預設為 'batch_ring'。
ring_attn_func: RingAttnFunc | None
# TP 組中的張量平行進程數。僅 DeepSpeed AutoTP 支援。
tensor_parallel_size: int | None

# 新增或更改特殊標記。如果您在此處新增標記，則不需將它們新增至 `tokens` 列表。
special_tokens: SpecialTokensConfig | None
  # 對於 SpecialTokensConfig：
  bos_token: str | None
  eos_token: str | None
  pad_token: str | None
  unk_token: str | None
  additional_special_tokens: list[str] | None

# 為標記器新增額外標記
tokens: list[str] | None
# 將 token_id 映射到新的標記字串，以覆寫標記器中保留的 added_tokens。
# 僅適用於不屬於基礎詞彙表的標記（即 added_tokens）。
# 可以檢查它們是否存在於 tokenizer.json 的 added_tokens 中。
added_tokens_overrides: dict[int, str] | None

# 是否使用 torch.compile 以及使用哪個後端。設為 `auto` 將在 torch>=2.6.0 時啟用 torch compile
torch_compile: Literal['auto'] | bool | None
# torch.compile 使用的後端
torch_compile_backend: str | None
torch_compile_mode: Literal['default', 'reduce-overhead', 'max-autotune'] | None

# 訓練的最大迭代次數。它優先於 num_epochs，這意味著如果兩者都設定，num_epochs 將無法保證。
# 例如，當 1 個 epoch 是 1000 步時 => `num_epochs: 2` 且 `max_steps: 100` 將訓練 100 步
max_steps: int | None
# 熱身 (warmup) 步數。不能與 warmup_ratio 同時使用
warmup_steps: int | None
# 熱身比例。不能與 warmup_steps 同時使用
warmup_ratio: float | None
# 留空則每個 epoch 評估一次，整數表示每 N 步評估一次。浮點數表示總步數的比例
eval_steps: int | float | None
# 每個 epoch 執行評估的次數，與 eval_steps 互斥
evals_per_epoch: int | None
# 設為 `no` 跳過評估，`epoch` 在每個 epoch 結束時，留空則從 `eval_steps` 推斷
eval_strategy: str | None

# 留空則每個 epoch 儲存一次，整數表示每 N 步儲存一次。浮點數表示總步數的比例
save_steps: int | float | None
# 每個 epoch 儲存 checkpoint 的次數，與 save_steps 互斥
saves_per_epoch: int | None
# 設為 `no` 跳過儲存，`epoch` 在每個 epoch 結束時，`best` 在取得更好結果時，留空則從 `save_steps` 推斷
save_strategy: str | None
# 一次儲存的 checkpoint 總數限制
save_total_limit: int | None
# 是否在訓練第一步後儲存模型。預設為 False。
save_first_step: bool | None

# 日誌紀錄頻率
logging_steps: int | None
# 在連續這麼多次評估損失增加後停止訓練。參見 EarlyStoppingCallback
early_stopping_patience: int | None
load_best_model_at_end: bool | None = False
# 僅儲存模型權重，跳過優化器 (optimizer)。使用此項意味著您無法從 checkpoint 恢復訓練。
save_only_model: bool | None = False
# 使用 tensorboard 進行日誌紀錄
use_tensorboard: bool | None
# 啟用 pytorch 效能分析器 (profiler)，將訓練的前 N 步捕獲到 output_dir。
# 詳見 https://pytorch.org/blog/understanding-gpu-memory-1/。
# 快照可在 https://pytorch.org/memory_viz 視覺化。
profiler_steps: int | None
# 效能分析器開始的步數。對於僅捕獲執行中期的幾步很有用。
profiler_steps_start: int | None = 0
# 訓練結束時是否報告每秒標記數 (tokens per second)。預訓練資料集不支援此項。
include_tokens_per_second: bool | None
# 訓練期間是否透過測量非填補標記的吞吐量來報告每個 GPU 的每秒標記數。
include_tkps: bool | None = True
# NEFT https://arxiv.org/abs/2310.05914，設定此數值（論文預設為 5）以向嵌入新增噪聲。目前僅支援 Llama 和 Mistral
neftune_noise_alpha: float | None

# 控制 ORPO 損失中相對比例損失權重的參數。由於 trl 映射，會傳遞給 `ORPOConfig` 中的 `beta`。
orpo_alpha: float | None
# RPO 論文中損失項 NLL 的權重
rpo_alpha: float | None
# SimPO 損失的目標獎勵邊界 (reward margin)
simpo_gamma: float | None
# BC 正規化器的權重
cpo_alpha: float | None

# KTO 損失中期望損失項的係數
kto_desirable_weight: float | None
# KTO 損失中非期望損失項的係數
kto_undesirable_weight: float | None
# RL 訓練的 beta 參數
rl_beta: float | None

# 定義系統中每個 GPU 的最大記憶體使用量。載入模型時傳遞給 transformers。
max_memory: dict[int | Literal['cpu', 'disk'], int | str] | None
# 限制所有可用 GPU 的記憶體到此數值（如果是整數，單位為 GB）；預設：未設定
gpu_memory_limit: int | str | None
# 是否使用 low_cpu_mem_usage
low_cpu_mem_usage: bool | None

# 用於訓練的聊天模板名稱，支援以下值：
# tokenizer_default：使用 tokenizer_config.json 中可用的聊天模板。
# 如果標記器中沒有聊天模板，則會報錯。這是預設值。
# alpaca/inst/chatml/gemma/cohere/llama3/phi_3/deepseek_v2/jamba：
# 這些聊天模板可在 Axolotl 程式碼中的 src/axolotl/utils/chat_templates.py 找到。
# tokenizer_default_fallback_*：其中 * 是備援使用的聊天模板名稱。
# 例如 tokenizer_default_fallback_chatml。當標記器中沒有聊天模板時這很有用。
# jinja：為聊天模板使用自定義 jinja 模板。自定義 jinja 模板應在 chat_template_jinja 欄位中提供。
# 選定的聊天模板將儲存到 tokenizer_config.json 以便於推理
chat_template: ChatTemplate | Annotated[str, StringConstraints(pattern='^tokenizer_default_fallback_')] | None
# 聊天模板的自定義 jinja 模板或 jinja 檔案路徑。僅在 chat_template 設為 `jinja` 或 `null` 時使用。預設為 null。
chat_template_jinja: str | None
# 傳遞給聊天模板的其他關鍵字參數。對於自定義聊天模板很有用。例如，您可以傳遞 `thinking=False` 以向聊天模板新增產生提示。
chat_template_kwargs: dict[str, Any] | None
# 訓練期間要屏蔽/取消屏蔽的自定義 EOT (End-of-Turn) 標記。這些標記標記對話輪次之間的邊界。
# 例如：['/INST', '</s>', '[/SYSTEM_PROMPT]']。如果未指定，預設僅為模型的 eos_token。
# 這對於使用多個分隔標記的模板很有用。
eot_tokens: list[str] | None
# 更改預設系統訊息。目前僅支援 chatml。
default_system_message: str | None

# 標記索引，用於將嵌入權重調整為其他標記的平均值。當模型有未訓練的嵌入時很有用。
fix_untrained_tokens: int | list[int] | None

is_preprocess: bool | None
preprocess_iterable: bool | None

# 總標記數 - 內部使用
total_num_tokens: int | None
total_supervised_tokens: int | None
# 您可以在至少開始一次訓練後設定這些打包優化參數。訓練器將為這些值提供建議值。
sample_packing_eff_est: float | None
axolotl_config_path: str | None

# 僅限內部使用 - 用於識別模型基於何種架構
is_falcon_derived_model: bool | None
# 僅限內部使用 - 用於識別模型基於何種架構
is_llama_derived_model: bool | None
# 僅限內部使用 - 用於識別模型基於何種架構。請注意，如果您將此設為 true，`padding_side` 將預設設為 'left'
is_mistral_derived_model: bool | None
# 僅限內部使用 - 用於識別模型基於何種架構
is_qwen_derived_model: bool | None

# 新增插件以擴展管道。參見 `src/axolotl/integrations` 獲取可用插件或下方文件。
# https://docs.axolotl.ai/docs/custom_integrations.html
plugins: list[str] | None

# 這是包含 *.pt, *.safetensors 或 *.bin 檔案的 huggingface 模型。也可以是磁碟上模型的相對路徑
base_model: str (必填)
# 如果 hf hub 上的 base_model 儲存庫不包含配置 .json 檔案，您可以在此設定，或者留空以預設使用 base_model
base_model_config: str | None
cls_model_config: str | None
# 選填的標記器配置路徑，以防您想使用與基礎模型中定義的不同的標記器
tokenizer_config: str | None
# 從 from_pretrained 載入標記器時的 use_fast 選項，預設為 True
tokenizer_use_fast: bool | None
# 是否使用舊版標記器設定，預設為 True
tokenizer_legacy: bool | None
# 是否使用 mistral-common 標記器。如果設為 True，將使用 mistral-common 標記器。
tokenizer_use_mistral_common: bool | None
# 模型對應的標記器，AutoTokenizer 是一個好選擇
tokenizer_type: str | None
# transformers processor 類別
processor_type: str | None
# 是否為標記器儲存 jinja 檔案，transformers 預設為 True
tokenizer_save_jinja_files: bool | None = True
# 為不信任的來源啟用 trust_remote_code
trust_remote_code: bool | None

# 分片前不要將模型移動到設備上。設為 `false` 以恢復舊版行為。
experimental_skip_move_to_device: bool | None = True

# 使用自定義核心，例如 MegaBlocks。
use_kernels: bool | None

# 模型載入量化配置
model_quantization_config: Literal['Mxfp4Config'] | None
# 模型量化配置的關鍵字參數
model_quantization_config_kwargs: dict[str, Any] | None

# 全量微調模型儲存位置
output_dir: str = ./model-out
# 將 checkpoint 推送到 hub
hub_model_id: str | None
# 如何將 checkpoint 推送到 hub
hub_strategy: str | None
# 將模型儲存為 safetensors (需要 safetensors 套件)。預設為 True
save_safetensors: bool | None = True

# 這將嘗試將模型量化到 8 位元並使用 adam 8 位元優化器
load_in_8bit: bool | None = False
# 使用 bitsandbytes 4 位元
load_in_4bit: bool | None = False

# 如果您想使用 'lora' 或 'qlora'，或者留空以訓練原始模型中的所有參數
adapter: str | None
# 如果您已有訓練好的 lora 模型想要載入，請放在這裡。這意味著訓練後如果您想測試模型，應將其設為 `output_dir` 的值。
# 注意，如果您將適配器合併到基礎模型，將在 `output_dir` 下建立新的子目錄 `merged`。
lora_model_dir: str | None
lora_r: int | None
lora_alpha: int | None
lora_fan_in_fan_out: bool | None
lora_target_modules: str | list[str] | None
lora_target_parameters: str | list[str] | None
# 如果為 true，將以所有線性模組為目標
lora_target_linear: bool | None
# 如果您向標記器新增了新標記，您可能需要儲存一些 LoRA 模組，因為它們需要知道新標記。
# 對於 LLaMA 和 Mistral，您需要儲存 `embed_tokens` 和 `lm_head`。其他模型可能有所不同。
lora_modules_to_save: list[str] | None
lora_dropout: float | None = 0.0
# 要轉換的層索引，否則應用於所有層
peft_layers_to_transform: list[int] | None
peft_layers_pattern: list[str] | None

peft: PeftConfig | None
  # 對於 PeftConfig：
  # LoRA 的 loftq 初始化配置選項
  loftq_config: LoftQConfig | None
    # 對於 LoftQConfig：
    # 通常為 4 位元
    loftq_bits: int = 4

# 是否使用 DoRA。
peft_use_dora: bool | None
# 是否使用 RSLoRA。
peft_use_rslora: bool | None
# 要複製的層索引列表。
peft_layer_replication: list[tuple[int, int]] | None
# 如何初始化 LoRA 權重。預設為 True，即 MS 原始實作。
peft_init_lora_weights: bool | str | None
# 在 `embed_tokens` 層上進行微調的標記索引列表。否則為嵌入層名稱與其可訓練標記索引的映射字典。
peft_trainable_token_indices: list[int] | dict[str, list[int]] | None

# 使用 answer.ai 技術為 FSDP 以分片格式載入 qlora 模型。
qlora_sharded_model_loading: bool | None = False
# 在 CPU 上執行 LoRA/PEFT 載入 -- 如果基礎模型太大以至於佔用了大部分或全部可用 GPU VRAM（例如在模型與 LoRA 合併期間），則需要此項。
lora_on_cpu: bool | None
# 是否正在訓練 4 位元 GPTQ 量化模型
gptq: bool | None
# 對 bnb 4 位元量化配置的可選覆寫
bnb_config_kwargs: dict[str, Any] | None

# loraplus 學習率比例 lr_B / lr_A。推薦值為 2^4。
loraplus_lr_ratio: float | None
# loraplus 對 lora 嵌入層的學習率。預設值為 1e-6。
loraplus_lr_embedding: float | None = 1e-06

merge_lora: bool | None

# 是否使用 ReLoRA。配合 jagged_restart_*steps 選項使用。
relora: bool | None
# 剪枝時優化器量級的閾值
relora_prune_ratio: float | None
# 設為 True 可在重啟期間於 CPU 上執行 lora 權重合併，以節省少量 GPU 記憶體
relora_cpu_offload: bool | None

# 齒狀重啟 (jagged restarts) 的重置頻率
jagged_restart_steps: int | None
# 齒狀重啟重置後的熱身步數
jagged_restart_warmup_steps: int | None
# 齒狀重啟重置前的退火 (anneal) 步數
jagged_restart_anneal_steps: int | None

# 如果大於 1，將跳過反向傳播並在給定步數內累積梯度。
gradient_accumulation_steps: int | None = 1
# 每個批次中包含的樣本數。這是傳送到每個 GPU 的樣本數。
# 每個 GPU 的批次大小 = micro_batch_size * gradient_accumulation_steps
micro_batch_size: int | None = 1
# 總批次大小，我們不建議手動設定此項
batch_size: int | None
# 用於評估的每個 GPU 微批次大小，預設為 micro_batch_size 的值
eval_batch_size: int | None

# 是否尋找適合記憶體的批次大小。傳遞給底層的 transformers Trainer
auto_find_batch_size: bool | None

# 是否從訓練標籤中屏蔽或包含人類提示
train_on_inputs: bool | None = False
# 將大小相似的數據分組以減少填補。啟動可能較慢，因為必須下載並排序整個資料集。注意開啟此項後，訓練損失可能有震盪模式。
group_by_length: bool | None

learning_rate: str | float (必填)
embedding_lr: float | None
embedding_lr_scale: float | None
# 指定權重衰減 (weight decay)
weight_decay: float | None = 0.0
# 指定優化器
optimizer: OptimizerNames | CustomSupportedOptimizers | None = OptimizerNames.ADAMW_TORCH_FUSED
# 傳遞給優化器的參數字典
optim_args: str | dict[str, Any] | None
# 要優化的目標模組，即您想要訓練的模組名稱，目前僅用於 GaLore 演算法
optim_target_modules: list[str] | Literal['all_linear'] | None
# 優化器 'adamw_anyprecision' 的 torch distx 路徑
torchdistx_path: str | None
lr_scheduler: SchedulerType | Literal['one_cycle'] | Literal['rex'] | None = SchedulerType.COSINE
# 指定與優化器搭配使用的排程器和關鍵字參數
lr_scheduler_kwargs: dict[str, Any] | None
lr_quadratic_warmup: bool | None
# 將 lr 衰減到峰值 lr 的某個百分比，例如 cosine_min_lr_ratio=0.1 表示峰值 lr 的 10%
cosine_min_lr_ratio: float | None
# 在步驟的某個百分比凍結 lr，例如 cosine_constant_lr_ratio=0.8 表示從訓練步驟的 80% 開始 cosine_min_lr
cosine_constant_lr_ratio: float | None
# 學習率除數因子 (div factor)
lr_div_factor: float | None

lr_groups: list[LrGroup] | None
  # 對於 LrGroup：
  name: str (必填)
  modules: list[str] (必填)
  lr: float (必填)

# adamw 超參數
adam_epsilon: float | None
# 僅用於 CAME 優化器
adam_epsilon2: float | None
# adamw 超參數
adam_beta1: float | None
# adamw 超參數
adam_beta2: float | None
# 僅用於 CAME 優化器
adam_beta3: float | None

# Dion 優化器學習率
dion_lr: float | None
# Dion 優化器動量 (momentum)
dion_momentum: float | None
# Dion 優化器：用於低秩近似的 r/d 比例。用於計算低秩維度。
dion_rank_fraction: float | None = 1.0
# Dion 優化器：將低秩維度四捨五入到此數值的倍數。對於確保均勻分片很有用。
dion_rank_multiple_of: int | None = 1

# 梯度剪取 (Gradient clipping) 最大範數
max_grad_norm: float | None
num_epochs: float = 1.0

use_wandb: bool | None
# 設定 wandb run 名稱
wandb_name: str | None
# 設定 wandb run ID
wandb_run_id: str | None
# "offline" 在本地儲存 run 元數據而不同步到伺服器，"disabled" 關閉 wandb
wandb_mode: str | None
# 您的 wandb 專案名稱
wandb_project: str | None
# 如果使用團隊，設定 wandb 團隊名稱
wandb_entity: str | None
wandb_watch: str | None
# "checkpoint" 每 `save_steps` 步將模型記錄到 wandb Artifacts，或 "end" 僅在訓練結束時記錄
wandb_log_model: str | None

use_mlflow: bool | None
# mlflow 的 URI
mlflow_tracking_uri: str | None
# 您的實驗名稱
mlflow_experiment_name: str | None
# 您的 run 名稱
mlflow_run_name: str | None
# 設為 true 以在每次儲存時將每個儲存的 checkpoint 複製到 mlflow artifact 註冊表
hf_mlflow_log_artifacts: bool | None

# 啟用或停用 Comet 整合。
use_comet: bool | None
# Comet 的 API key。推薦透過 `comet login` 設定。
comet_api_key: str | None
# Comet 中的工作空間名稱。預設為使用者的預設工作空間。
comet_workspace: str | None
# Comet 中的專案名稱。預設為 Uncategorized。
comet_project_name: str | None
# 實驗的識別碼。用於將數據附加到現有實驗或控制新實驗的鍵。預設為隨機鍵。
comet_experiment_key: str | None
# 建立新實驗 ("create") 或記錄到現有實驗 ("get")。預設 ("get_or_create") 根據配置自動選擇。
comet_mode: str | None
# 設為 True 將數據記錄到 Comet 伺服器，或 False 用於離線儲存。預設為 True。
comet_online: bool | None
# 其他配置設定的字典，詳見文件。
comet_experiment_config: dict[str, Any] | None

# 啟用 OpenTelemetry 指標收集和 Prometheus 匯出
use_otel_metrics: bool | None = False
# OpenTelemetry 指標伺服器繫結的主機
otel_metrics_host: str | None = localhost
# Prometheus 指標 HTTP 伺服器的通訊埠
otel_metrics_port: int | None = 8000

# LISA 中激活層的數量
lisa_n_layers: int | None
# LISA 中切換層級的頻率
lisa_step_interval: int | None
# 訪問層級的模型路徑
lisa_layers_attribute: str | None = model.layers

gradio_title: str | None
gradio_share: bool | None
gradio_server_name: str | None
gradio_server_port: int | None
gradio_max_new_tokens: int | None
gradio_temperature: float | None

use_ray: bool = False
ray_run_name: str | None
ray_num_workers: int = 1
resources_per_worker: dict

# 要調整大小的圖像大小。可以是整數（調整為填補的正方形圖像）或元組 (寬, 高)。
# 如果未提供，我們將嘗試從 preprocessor.size 載入，否則圖像將不調整大小。
image_size: int | tuple[int, int] | None
# 用於圖像調整大小的重取樣演算法。預設為 bilinear。詳細資訊請參閱 PIL.Image.Resampling。
image_resize_algorithm: Literal['bilinear', 'bicubic', 'lanczos'] | Resampling | None

# 對基礎模型配置的可選覆寫
overrides_of_model_config: dict[str, Any] | None
# 對基礎模型載入 from_pretrained 的可選覆寫
overrides_of_model_kwargs: dict[str, Any] | None
# 如果您想指定載入的模型類型，AutoModelForCausalLM 也是一個好選擇
type_of_model: str | None
# 您可以選擇從 huggingface hub 選擇特定的模型版本 (revision)
revision_of_model: str | None

max_packed_sequence_len: int | None
rope_scaling: Any | None
noisy_embedding_alpha: float | None
dpo_beta: float | None
evaluation_strategy: str | None
```

---

## 

**URL:** https://docs.axolotl.ai

**內容：**
- 🎉 最新更新
- ✨ 概覽
- 🚀 快速開始 - 幾分鐘內完成 LLM 微調
  - Google Colab
  - 安裝
    - 使用 pip
    - 使用 Docker
    - 雲端提供商
  - 您的第一次微調
- 📚 文件

一個免費且開源的 LLM 微調框架

Axolotl 是一個免費且開源的工具，旨在簡化最新大型語言模型 (LLM) 的訓練後處理和微調。

使用 Docker 安裝可能比在您自己的環境中安裝更不容易出錯。

其他安裝方法在[此處]描述。

就這樣！查看我們的「開始使用指南」以獲取更詳細的逐步說明。

歡迎貢獻！請參閱我們的「貢獻指南」瞭解詳細資訊。

有興趣贊助嗎？請透過 [email protected] 聯繫我們。

如果您在研究或專案中使用 Axolotl，請按以下方式引用：

本專案根據 Apache 2.0 授權條款授權 - 詳見 LICENSE 檔案。

**範例：**

範例 1 (bash):
```bash
pip3 install -U packaging==23.2 setuptools==75.8.0 wheel ninja
pip3 install --no-build-isolation axolotl[flash-attn,deepspeed]

# 下載範例 axolotl 配置, deepspeed 配置
axolotl fetch examples
axolotl fetch deepspeed_configs  # 選填
```

範例 2 (bash):
```bash
docker run --gpus '"all"' --rm -it axolotlai/axolotl:main-latest
```

範例 3 (bash):
```bash
# 獲取 axolotl 範例
axolotl fetch examples

# 或者，指定自定義路徑
axolotl fetch examples --dest path/to/folder

# 使用 LoRA 訓練模型
axolotl train examples/llama-3/lora-1b.yml
```

範例 4 (unknown):
```unknown
@software{axolotl,
  title = {Axolotl: Open Source LLM Post-Training},
  author = {{Axolotl maintainers and contributors}},
  url = {https://github.com/axolotl-ai-cloud/axolotl},
  license = {Apache-2.0},
  year = {2023}
}
```

---

## 快速上手 (Quickstart)

**URL:** https://docs.axolotl.ai/docs/getting-started.html

**內容：**
- 快速上手
- 1 快速範例
- 2 瞭解過程
  - 2.1 配置文件
  - 2.2 訓練
- 3 您的第一次自定義訓練
- 4 常見任務
  - 4.1 測試您的模型
  - 4.2 使用 UI
  - 4.3 預處理數據

本指南將引導您完成第一個使用 Axolotl 的模型微調專案。

讓我們從使用 LoRA 微調一個小型語言模型開始。此範例使用一個 1B 參數的模型，以確保它能在大多數 GPU 上執行。假設已安裝 Axolotl（如果尚未安裝，請參閱我們的安裝指南）。

就這樣！讓我們來瞭解剛才發生了什麼。

YAML 配置文件控制關於訓練的一切。以下是我們範例配置的（部分）外觀：

load_in_8bit: true 和 adapter: lora 啟用了 LoRA 適配器微調。

詳見我們的配置選項。

當您執行 axolotl train 時，Axolotl 會：

讓我們為您自己的數據修改範例：

此特定配置用於使用 alpaca 資料集格式對模型進行 LoRA 微調，資料格式如下：

請參閱我們的「資料集格式」以獲取更多資料集格式以及如何格式化它們。

同一個 yaml 檔案可以用於訓練、推理和合併。

訓練後，測試您的模型：

更多詳細資訊可以在「推理」中找到。

啟動 Gradio 介面：

對於大型資料集，請先進行預處理：

請務必在配置中設定 dataset_prepared_path:，以設定儲存準備好的資料集的路徑。

更多詳細資訊可以在「資料集預處理」中找到。

要將 LoRA 權重合併回基礎模型，請執行：

合併後的模型將儲存在 {output_dir}/merged 目錄中。

更多詳細資訊可以在「合併 LoRA 權重」中找到。

既然您已經掌握了基礎知識，您可能想要：

查看我們的其他指南以獲取有關這些主題的詳細資訊：

**範例：**

範例 1 (bash):
```bash
axolotl fetch examples
```

範例 2 (bash):
```bash
axolotl train examples/llama-3/lora-1b.yml
```

範例 3 (yaml):
```yaml
base_model: NousResearch/Llama-3.2-1B

load_in_8bit: true
adapter: lora

datasets:
  - path: teknium/GPT4-LLM-Cleaned
    type: alpaca
dataset_prepared_path: last_run_prepared
val_set_size: 0.1
output_dir: ./outputs/lora-out
```

範例 4 (yaml):
```yaml
base_model: NousResearch/Nous-Hermes-llama-1b-v1

load_in_8bit: true
adapter: lora

# 訓練設定
micro_batch_size: 2
num_epochs: 3
learning_rate: 0.0003

# 您的資料集
datasets:
  - path: my_data.jsonl        # 您的本地資料檔案
    type: alpaca               # 或其他格式
```

---

## 多重打包 (Multipack) (樣本打包)

**URL:** https://docs.axolotl.ai/docs/multipack.html

**內容：**
- 多重打包 (樣本打包)
- 配合 Flash Attention 的多重打包視覺化
- 不配合 Flash Attention 的多重打包

因為 Flash Attention 只是捨棄了注意力遮罩，我們不需要構建 4D 注意力遮罩。我們只需要將序列串接到單個批次中，並讓 Flash Attention 知道每個新序列從哪裡開始。

4k 上下文, bsz = 4，每個字元代表 256 個標記，X 代表填補標記

在每一步填補到最長輸入後

使用打包 (注意每步有效標記數相同，但真正批次大小 bsz 為 1)

cu_seqlens: [[ 0, 11, 17, 24, 28, 36, 41 44, 48, 51, 55, 60, 64]]

即使不使用 Flash Attention 仍可實現多重打包，但由於在沒有 Flash Attention 的情況下受上下文長度限制，無法將多個批次合併為單個批次，因此打包效率較低。我們可以使用 Pytorch 的 Scaled Dot Product Attention 實作或原生 Pytorch 注意力實作，配合 4D 注意力遮罩將序列打包在一起，並避免交叉注意力。

**範例：**

範例 1 (unknown):
```unknown
0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
[[ A A A A A A A A A A A ]
   B B B B B B ]
   C C C C C C C ]
   D D D D ]]

[[ E E E E E E E E ]
 [ F F F F ]
 [ G G G ]
 [ H H H H ]]

[[ I I I ]
 [ J J J ]
 [ K K K K K]
 [ L L L ]]
```

範例 2 (unknown):
```unknown
0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
[[ A A A A A A A A A A A ]
   B B B B B B X X X X X X ]
   C C C C C C C X X X X ]
   D D D D X X X X X X X ]]

[[ E E E E E E E E ]
 [ F F F F X X X X ]
 [ G G G X X X X X ]
 [ H H H H X X X X ]]

[[ I I I X X ]
 [ J J J X X ]
 [ K K K K K ]
 [ L L L X X ]]
```

範例 3 (unknown):
```unknown
0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
[[ A A A A A A A A A A A B B B B B
   B C C C C C C C D D D D E E E E
   E E E E F F F F F G G G H H H H
   I I I J J J J K K K K K L L L X ]]
```

---

## 批次大小 vs 梯度累積 (Batch size vs Gradient accumulation)

**URL:** https://docs.axolotl.ai/docs/batch_vs_grad.html

**內容：**
- 批次大小 vs 梯度累積

梯度累積 (Gradient accumulation) 意味著在多個小批次 (mini-batches) 上累積梯度，然後再更新模型權重。當每個批次中的樣本具有多樣性時，此技術不會顯著影響學習。

此方法允許在不需要按比例增加記憶體的情況下，使用較大的有效批次大小進行有效訓練。原因如下：

批次大小與記憶體消耗：增加批次大小會影響記憶體的主要原因是中間激活函數 (intermediate activations) 的儲存需求。當您在網絡中前向傳播一個批次時，必須為批次中的每個樣本儲存每一層的激活函數，因為這些激活函數在反向傳播期間用於計算梯度。因此，較大的批次意味著更多的激活函數，導致更大的 GPU 記憶體消耗。

梯度累積：透過梯度累積，您實際上是透過在多個較小的批次（或微批次，micro-batches）上累積梯度來模擬較大的批次大小。然而，在任何給定時間，您僅在進行一個微批次的前向和反向傳播。這意味著您僅儲存該微批次的激活函數，而不是整個累積批次的激活函數。因此，您可以模擬大批次大小的效果，而無需承擔儲存大批次激活函數的記憶體成本。

範例 1：微批次大小：3，梯度累積步數：2，GPU 數量：3。總批次大小 = 3 * 2 * 3 = 18。

範例 2：微批次大小：2，梯度累積步數：1，GPU 數量：3。總批次大小 = 2 * 1 * 3 = 6。

**範例：**

範例 1 (unknown):
```unknown
| GPU 1          | GPU 2          | GPU 3          |
|----------------|----------------|----------------|
| S1, S2, S3     | S4, S5, S6     | S7, S8, S9     |
| e1, e2, e3     | e4, e5, e6     | e7, e8, e9     |
|----------------|----------------|----------------|
| → (累積)       | → (累積)       | → (累積)       |
|----------------|----------------|----------------|
| S10, S11, S12  | S13, S14, S15  | S16, S17, S18  |
| e10, e11, e12  | e13, e14, e15  | e16, e17, e18  |
|----------------|----------------|----------------|
| → (套用)       | → (套用)       | → (套用)       |

第二次迭代後權重 w1 的累積梯度（考慮所有 GPU）：
w1 的總梯度 = e1 + e2 + e3 + e4 + e5 + e6 + e7 + e8 + e9 + e10 + e11 + e12 + e13 + e14 + e15 + e16 + e17 + e18

w1 的權重更新：
w1_new = w1_old - 學習率 x (w1 的總梯度 / 18)
```

範例 2 (unknown):
```unknown
| GPU 1     | GPU 2     | GPU 3     |
|-----------|-----------|-----------|
| S1, S2    | S3, S4    | S5, S6    |
| e1, e2    | e3, e4    | e5, e6    |
|-----------|-----------|-----------|
| → (套用) | → (套用) | → (套用) |

權重 w1 的累積梯度（考慮所有 GPU）：
w1 的總梯度 = e1 + e2 + e3 + e4 + e5 + e6

w1 的權重更新：
w1_new = w1_old - 學習率 × (w1 的總梯度 / 6)
```

---

## 除錯 (Debugging)

**URL:** https://docs.axolotl.ai/docs/debugging.html

**內容：**
- 除錯
- 目錄
- 一般提示
- 使用 VSCode 除錯
  - 背景
  - 設定
    - 遠端主機
  - 配置
  - 自定義您的除錯器
  - 影片教學

本文件提供一些除錯 Axolotl 的提示和技巧。它還提供了一個使用 VSCode 進行除錯的範例配置。良好的除錯設定對於理解 Axolotl 程式碼在幕後如何運作至關重要。

除錯時，儘可能簡化您的測試情境是有幫助的。以下是一些建議：

[!Important] 所有這些提示都已整合到下方的 VSCode 除錯範例配置中。

確保您使用的是最新版本的 Axolotl：此專案經常變更，且錯誤修復速度很快。檢查您的 git 分支並確保您已從 main 獲取了最新更改。

消除並行性：將訓練和資料預處理的進程數限制為 1：

使用小型資料集：從 HF Hub 構建或使用小型資料集。使用小型資料集時，您通常必須確保 sample_packing: False 和 eval_sample_packing: False 以避免出錯。如果您時間緊迫且沒有時間構建小型資料集，但想使用 HF Hub 上的資料集，您可以對資料進行分片 (shard)（這仍會標記化整個資料集，但僅使用一小部分數據進行訓練。例如，要將資料集切分為 20 份，請在 Axolotl 配置中新增以下內容）：

使用小型模型：小型模型的一個好範例是 TinyLlama/TinyLlama-1.1B-Chat-v1.0。

最小化迭代時間：使用這些設定，確保訓練迴圈儘快完成。

清除快取：Axolotl 會快取某些步驟，底層的 HuggingFace 訓練器也是如此。除錯時您可能想要清除其中的一些快取。

以下範例顯示如何配置 VSCode 以除錯 chat_template 格式的資料預處理。當您的 Axolotl 配置中包含以下內容時，將使用此格式：

[!Important] 如果您已熟悉進階 VSCode 除錯，可以跳過以下說明，直接查看 .vscode/launch.json 和 .vscode/tasks.json 檔案中的範例配置。

[!Tip] 如果您更喜歡看影片而非閱讀，可以跳到下方的影片教學（但建議兩者都看）。

確保您已以可編輯模式安裝 Axolotl，這可確保您對程式碼所做的更改能在執行時反映出來。在專案根目錄執行以下命令：

如果您在遠端主機上開發，可以輕鬆使用 VSCode 進行遠端除錯。為此，您需要遵循此遠端 - SSH 指南。您也可以看下方的 Docker 和遠端 SSH 除錯影片。

最簡單的入門方法是修改此專案中的 .vscode/launch.json 檔案。這只是一個範例配置，因此您可能需要根據需求進行修改或複製。

例如，要模擬命令 cd devtools && CUDA_VISIBLE_DEVICES=0 accelerate launch -m axolotl.cli.train dev_chat_template.yml，您可以使用以下配置。注意，我們新增了額外的旗標來覆寫 Axolotl 配置並整合上述提示（見註解）。我們還將工作目錄設為 devtools，並將環境變數 HF_HOME 設為一個臨時資料夾，該資料夾稍後會被部分刪除。這是因為我們希望在每次執行前刪除 HF 資料集快取，以確保資料預處理程式碼是從頭開始執行的。

關於此配置的其他說明：

[!Tip] 您可能不想刪除這些資料夾。例如，如果您正在除錯模型訓練而非資料預處理，您可能不想刪除快取或輸出資料夾。您可能還需要根據用例向 tasks.json 檔案新增額外任務。

以下是定義了 cleanup-for-dataprep 任務的 ./vscode/tasks.json 檔案。當您使用上述配置時，此任務會在每個除錯階段之前執行。請注意這裡有兩個任務刪除了上述兩個資料夾。第三個任務 cleanup-for-dataprep 是一個複合任務，結合了前兩個任務。複合任務是必要的，因為 VSCode 不允許在 launch.json 檔案的 preLaunchTask 參數中指定多個任務。

您的除錯用例可能與上述範例不同。最簡單的做法是將您自己的 Axolotl 配置放在 devtools 資料夾中，並修改 launch.json 檔案以使用您的配置。您也可能想要修改 preLaunchTask 以刪除不同的資料夾或完全不刪除任何內容。

以下影片教學將引導您完成上述配置，並示範如何使用 VSCode 進行除錯（點擊下方圖像觀看）：

使用官方 Axolotl Docker 映像檔是除錯程式碼的一種絕佳方式，也是使用 Axolotl 的非常流行的方式。將 VSCode 連接到 Docker 需要額外的幾個步驟。

在執行 Axolotl 的主機上（例如，如果您使用的是遠端主機），複製 Axolotl 儲存庫並將目前目錄切換到根目錄：

[!Tip] 如果您的主機上已複製了 Axolotl，請確保您有最新的更改並進入專案根目錄。

接著，執行所需的 Docker 映像檔並掛載目前目錄。以下是您可以執行的 Docker 命令：

[!Tip] 要瞭解哪些容器可用，請參閱 README 的 Docker 章節和 DockerHub 儲存庫。有關 Docker 容器如何構建的詳細資訊，請參閱 Axolotl 的 Docker CI 建置。

您現在將進入容器中。接著，以可編輯模式安裝 Axolotl：

接著，如果您使用的是遠端主機，請使用 VSCode 遠端登入此主機。如果您使用的是本地主機，可以跳過此步驟。

接著，使用 VSCode 中的命令面板 (CMD + SHIFT + P) 選擇 Dev Containers: Attach to Running Container...。系統會提示您選擇要連接的容器。選擇您剛建立的容器。您現在將進入容器，工作目錄位於專案根目錄。您對程式碼所做的任何更改都將同時反映在容器和主機上。

現在您已準備好按照上述說明進行除錯（參見「使用 VSCode 除錯」）。

這裡有一段簡短的影片，示範如何連接到遠端主機上的 Docker 容器：

該配置實際上模擬了命令 CUDA_VISIBLE_DEVICES=0 python -m accelerate.commands.launch -m axolotl.cli.train devtools/chat_template.yml，但效果是一樣的。↩︎

當使用 nvidia-container-toolkit 時，以下許多旗標都是 Nvidia 推薦的最佳做法。您可以在此處閱讀更多關於這些旗標的資訊。↩︎

**範例：**

範例 1 (yaml):
```yaml
datasets:
    ...
    shards: 20
```

範例 2 (yaml):
```yaml
datasets:
  - path: <您的 chat_template 格式資料集路徑> # 例如 HF Hub 上的: fozziethebeat/alpaca_messages_2k_test
    type: chat_template
```

範例 3 (bash):
```bash
pip3 install packaging
pip3 install --no-build-isolation -e '.[flash-attn,deepspeed]'
```

範例 4 (json):
```json
// .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug axolotl prompt - chat_template",
            "type": "python",
            "module": "accelerate.commands.launch",
            "request": "launch",
            "args": [
                "-m", "axolotl.cli.train", "dev_chat_template.yml",
                // 以下旗標透過覆寫 Axolotl 配置來簡化除錯。
                // 根據需要進行修改。
                "--dataset_num_proc=1",      // 將資料預處理限制為單個進程
                "--max_steps=1",              // 將訓練限制為僅 1 步
                "--batch_size=1",             // 最小化批次大小
                "--micro_batch_size=1",       // 最小化微批次大小
                "--val_set_size=0",           // 停用驗證
                "--sample_packing=False",     // 停用樣本打包，這對於小型資料集是必要的
                "--eval_sample_packing=False",// 在評估集上停用樣本打包
                "--dataset_prepared_path=temp_debug/axolotl_outputs/data", // 將數據輸出傳送到臨時資料夾
                "--output_dir=temp_debug/axolotl_outputs/model" // 將模型輸出傳送到臨時資料夾
                ],
            "console": "integratedTerminal",      // 在整合終端機中顯示輸出
            "cwd": "${workspaceFolder}/devtools", // 將工作目錄設定為專案根目錄下的 devtools
            "justMyCode": true,                   // 僅步進 (step) 透過 Axolotl 程式碼
            "env": {"CUDA_VISIBLE_DEVICES": "0",  // 由於我們不進行分佈式訓練，因此需要限制為一個 GPU
                    "HF_HOME": "${workspaceFolder}/devtools/temp_debug/.hf-cache"}, // 將 HF 快取傳送到臨時資料夾
            "preLaunchTask": "cleanup-for-dataprep", // 刪除臨時資料夾（見下文）
        }
    ]
}
```

---

## Docker

**URL:** https://docs.axolotl.ai/docs/docker.html

**內容：**
- Docker
- Base
    - Image (映像檔)
    - 標籤格式
- Main
    - Image
    - 標籤格式
- Cloud
    - Image
    - 標籤格式

本章節介紹 AxolotlAI 在 Docker Hub 上發布的不同 Docker 映像檔。

對於 Blackwell GPU，請使用帶有 PyTorch 2.7.1 和 CUDA 12.8 的標籤。

Base 映像檔是可以安裝 Axolotl 的最簡映像檔。它基於 nvidia/cuda 映像檔。它包含 python, torch, git, git-lfs, awscli, pydantic 等。

Main 映像檔是用於執行 Axolotl 的映像檔。它基於 axolotlai/axolotl-base 映像檔，並包含 Axolotl 程式碼庫、相依項等。

映像檔名稱可能會附加一些額外標籤，例如 -vllm 表示安裝了這些套件。

Cloud 映像檔是用於在雲端執行 Axolotl 的映像檔。它基於 axolotlai/axolotl 映像檔，並針對不同的雲端供應商設定了環境變數，例如用於磁碟區掛載的 HuggingFace 快取目錄、tmux 等。

預設會執行 Jupyter lab。在環境變數中設定 JUPYTER_DISABLE=1 可將其停用。

這使用與 main 映像檔相同的標籤。

我們推薦將磁碟區掛載到 /workspace/data 以實現數據持久化。/workspace/axolotl 包含原始碼且是暫時性的 (ephemeral)。

這與 cloud 映像檔相同，但沒有 tmux。

命名可能有點令人困惑，因為它在末尾附加了 -term。

這使用與 cloud 映像檔相同的標籤。

**範例：**

範例 1 (unknown):
```unknown
axolotlai/axolotl-base
```

範例 2 (bash):
```bash
main-base-py{python_version}-cu{cuda_version}-{pytorch_version}
```

範例 3 (unknown):
```unknown
axolotlai/axolotl
```

範例 4 (bash):
```bash
# 推送到 main 時
main-py{python_version}-cu{cuda_version}-{pytorch_version}

# 最新 main（目前為 torch 2.6.0, python 3.11, cuda 12.4）
main-latest

# 每晚建置版 (nightly build)
{branch}-{date_in_YYYYMMDD}-py{python_version}-cu{cuda_version}-{pytorch_version}

# 標籤發布版 (tagged release)
{version}
```

---
