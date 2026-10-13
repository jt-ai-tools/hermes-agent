# Unsloth - Llms-Txt

**頁數：** 136

---

## !pip install huggingface_hub hf_transfer

**URL:** llms-txt#!pip-install-huggingface_hub-hf_transfer

```python
import os
os.environ["HF_HUB_ENABLE_HF_TRANSFER"] = "1"
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id = "unsloth/Llama-4-Scout-17B-16E-Instruct-GGUF",
    local_dir = "unsloth/Llama-4-Scout-17B-16E-Instruct-GGUF",
    allow_patterns = ["*IQ2_XXS*"],
)
```
```bash
./llama.cpp/llama-cli \
    --model unsloth/Llama-4-Scout-17B-16E-Instruct-GGUF/Llama-4-Scout-17B-16E-Instruct-UD-IQ2_XXS.gguf \
    --threads 32 \
    --ctx-size 16384 \
    --n-gpu-layers 99 \
    -ot ".ffn_.*_exps.=CPU" \
    --seed 3407 \
    --prio 3 \
    --temp 0.6 \
    --min-p 0.01 \
    --top-p 0.9 \
    -no-cnv \
    --prompt "<|header_start|>user<|header_end|>\n\nCreate a Flappy Bird game.<|eot|><|header_start|>assistant<|header_end|>\n\n"
```

{% hint style="success" %}
在以下連結閱讀更多關於執行 Llama 4 的資訊： <https://docs.unsloth.ai/basics/tutorial-how-to-run-and-fine-tune-llama-4>
{% endhint %}

**範例：**

範例 1 (未知):
```unknown
接著讓我們進行推理！

{% code overflow="wrap" %}
```

---

## 首先卸載先前函式庫安裝的 xformers

**URL:** llms-txt#first-uninstall-xformers-installed-by-previous-libraries

```bash
pip uninstall xformers -y
```

---

## (1) 儲存為 GGUF / 合併為 16bit 以用於 vLLM

**URL:** llms-txt#(1)-saving-to-gguf-/-merging-to-16bit-for-vllm

---

## Qwen3-Coder: 如何在本地執行

**URL:** llms-txt#qwen3-coder:-how-to-run-locally

**目錄：**
- 🖥️ **執行 Qwen3-Coder**
  - :gear: 建議設定
  - 執行 Qwen3-Coder-30B-A3B-Instruct:

使用 Unsloth 動態量化在本地執行 Qwen3-Coder-30B-A3B-Instruct 和 480B-A35B。

Qwen3-Coder 是 Qwen 的新系列程式碼代理模型，提供 30B (**Qwen3-Coder-Flash**) 和 480B 參數版本。**Qwen3-480B-A35B-Instruct** 實現了頂尖的程式碼效能，可與 Claude Sonnet-4、GPT-4.1 和 [Kimi K2](https://docs.unsloth.ai/models/tutorials-how-to-fine-tune-and-run-llms/kimi-k2-how-to-run-locally) 媲美，在 Aider Polygot 上達到 61.8%，並支援 256K（可擴展至 1M）token 的上下文。

我們還上傳了具有原生 <mark style="background-color:purple;">**1M 上下文長度**</mark>（透過 YaRN 擴展）的 Qwen3-Coder，以及全精度 8bit 和 16bit 版本。[Unsloth](https://github.com/unslothai/unsloth) 現在也支援 Qwen3-Coder 的微調和 [強化學習 (RL)](https://docs.unsloth.ai/get-started/reinforcement-learning-rl-guide)。

{% hint style="success" %}
[**更新：** 我們修復了 Qwen3-Coder 的工具呼叫 (tool-calling)！ ](#tool-calling-fixes)您現在可以在 llama.cpp、Ollama、LMStudio、Open WebUI、Jan 等工具中無縫使用工具呼叫。此問題具有普遍性，影響了所有上傳版本（不只是 Unsloth），我們已與 Qwen 團隊溝通了我們的修復方案！[閱讀更多](#tool-calling-fixes)
{% endhint %}

<a href="#run-qwen3-coder-30b-a3b-instruct" class="button secondary">執行 30B-A3B</a><a href="#run-qwen3-coder-480b-a35b-instruct" class="button secondary">執行 480B-A35B</a>

{% hint style="success" %}
**[Unsloth 動態量化](https://docs.unsloth.ai/basics/unsloth-dynamic-2.0-ggufs)** 有效嗎？是的，而且效果非常好。在 Aider Polyglot 基準測試的第三方測試中，**UD-Q4\_K\_XL (276GB)** 動態量化幾乎與 **全 bf16 (960GB)** 的 Qwen3-coder 模型持平，得分為 60.9% 對比 61.8%。[更多詳情請見此處。](https://huggingface.co/unsloth/Qwen3-Coder-480B-A35B-Instruct-GGUF/discussions/8)
{% endhint %}

#### **Qwen3 Coder - Unsloth Dynamic 2.0 GGUFs**:

| 動態 2.0 GGUF (可執行) | 1M 上下文動態 2.0 GGUF |
| ------------------------ | ---------------------- |
| <ul><li><a href="https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF">30B-A3B-Instruct</a></li><li><a href="https://huggingface.co/unsloth/Qwen3-Coder-480B-A35B-Instruct-GGUF">480B-A35B-Instruct</a></li></ul> | <ul><li><a href="https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-1M-GGUF">30B-A3B-Instruct</a></li><li><a href="https://huggingface.co/unsloth/Qwen3-Coder-480B-A35B-Instruct-1M-GGUF">480B-A35B-Instruct</a></li></ul> |

## 🖥️ **執行 Qwen3-Coder**

以下是模型 [**30B-A3B**](#run-qwen3-coder-30b-a3b-instruct) 和 [**480B-A35B**](#run-qwen3-coder-480b-a35b-instruct) 變體的指南。

### :gear: 建議設定

Qwen 建議對這兩個模型使用以下推理設定：

`temperature=0.7`, `top_p=0.8`, `top_k=20`, `repetition_penalty=1.05`

* <mark style="background-color:green;">**Temperature 為 0.7**</mark>
* Top\_K 為 20
* Min\_P 為 0.00（選填，但 0.01 效果很好，llama.cpp 預設為 0.1）
* Top\_P 為 0.8
* <mark style="background-color:green;">**Repetition Penalty 為 1.05**</mark>
* 對話模板：&#x20;

{% code overflow="wrap" %}

{% endcode %}
* 建議上下文輸出：65,536 tokens（可以增加）。詳情請見此處。

**未渲染換行符號的對話模板/提示格式**

{% code overflow="wrap" %}

<mark style="background-color:yellow;">**用於工具呼叫的對話模板**</mark>（取得舊金山的當前氣溫）。更多關於如何格式化工具呼叫的詳情請見此處。

{% hint style="info" %}
提醒：此模型僅支援非思考模式，且不會在輸出中產生 `<think></think>` 區塊。同時，不再需要指定 `enable_thinking=False`。
{% endhint %}

### 執行 Qwen3-Coder-30B-A3B-Instruct:

為了使我們的動態 4-bit 量化達到每秒 6+ token 的推理速度，請至少配備 **18GB 的統一記憶體**（VRAM 和 RAM 總和）或單獨 **18GB 的系統 RAM**。根據經驗，您的可用記憶體應等於或超過您所使用的模型大小。例如，UD\_Q8\_K\_XL 量化（全精度）大小為 32.5GB，將需要至少 **33GB 的統一記憶體** (VRAM + RAM) 或 **33GB 的 RAM** 以獲得最佳效能。

**注意：** 模型可以在小於其總大小的記憶體上執行，但這會降低推理速度。只有在追求最快速度時才需要最大記憶體。

鑑於這是一個非思考模型，不需要設定 `thinking=False`，模型也不會產生 `<think> </think>` 區塊。

{% hint style="info" %}
遵循[**上方的最佳實踐**](#recommended-settings)。它們與 480B 模型相同。
{% endhint %}

#### 🦙 Ollama: 執行 Qwen3-Coder-30B-A3B-Instruct 教學

1. 如果您尚未安裝，請安裝 `ollama`！您只能執行大小高達 32B 的模型。

2. 執行模型！注意，如果失敗，您可以在另一個終端機呼叫 `ollama serve`！我們在 Hugging Face 上傳的 `params` 中包含了所有修復和建議參數（temperature 等）！

#### :sparkles: Llama.cpp: 執行 Qwen3-Coder-30B-A3B-Instruct 教學

1. 在 [GitHub 這裡](https://github.com/ggml-org/llama.cpp) 取得最新的 `llama.cpp`。您也可以按照下方的構建說明操作。如果您沒有 GPU 或只想進行 CPU 推理，請將 `-DGGML_CUDA=ON` 更改為 `-DGGML_CUDA=OFF`。

2. 您可以直接從 HuggingFace 提取：

3. 透過（在安裝 `pip install huggingface_hub hf_transfer` 之後）下載模型。您可以選擇 UD\_Q4\_K\_XL 或其他量化版本。

**範例：**

範例 1 (未知):
```unknown
<|im_start|>user
  Hey there!<|im_end|>
  <|im_start|>assistant
  What is 1+1?<|im_end|>
  <|im_start|>user
  2<|im_end|>
  <|im_start|>assistant
```

範例 2 (未知):
```unknown
<|im_start|>user\nHey there!<|im_end|>\n<|im_start|>assistant\nWhat is 1+1?<|im_end|>\n<|im_start|>user\n2<|im_end|>\n<|im_start|>assistant\n
```

範例 3 (未知):
```unknown
<|im_start|>user
What's the temperature in San Francisco now? How about tomorrow?<|im_end|>
<|im_start|>assistant
<tool_call>\n<function=get_current_temperature>\n<parameter=location>\nSan Francisco, CA, USA
</parameter>\n</function>\n</tool_call><|im_end|>
<|im_start|>user
<tool_response>
{"temperature": 26.1, "location": "San Francisco, CA, USA", "unit": "celsius"}
</tool_response>\n<|im_end|>
```

範例 4 (bash):
```bash
apt-get update
apt-get install pciutils -y
curl -fsSL https://ollama.com/install.sh | sh
```

---

## 確保所有音訊取樣率皆為 24 kHz（Orpheus 的預期速率）

**URL:** llms-txt#ensure-all-audio-is-at-24-khz-sampling-rate-(orpheus’s-expected-rate)

**目錄：**
  - 使用 Unsloth 微調 TTS

```python
dataset = dataset.cast_column("audio", Audio(sampling_rate=24000))
```

filename,text
  0001.wav,Hello there!
  0002.wav,<sigh> I am very tired.
  python
  from datasets import Audio
  dataset = load_dataset("csv", data_files="mydata.csv", split="train")
  dataset = dataset.cast_column("filename", Audio(sampling_rate=24000))
  python
from unsloth import FastLanguageModel
import torch
dtype = None # None for auto detection. Float16 for Tesla T4, V100, Bfloat16 for Ampere+
load_in_4bit = False # Use 4bit quantization to reduce memory usage. Can be False.

model, tokenizer = FastLanguageModel.from_pretrained(
    model_name = "unsloth/orpheus-3b-0.1-ft",
    max_seq_length= 2048, # Choose any for long context!
    dtype = dtype,
    load_in_4bit = load_in_4bit,
    #token = "hf_...", # use one if using gated models like meta-llama/Llama-2-7b-hf
)

from datasets import load_dataset
dataset = load_dataset("MrDragonFox/Elise", split = "train")
python

**範例：**

範例 1 (未知):
```unknown
這將下載資料集（~328 MB，約 1.2k 個樣本）。`dataset` 中的每個項目都是一個至少包含以下內容的字典：

* `"audio"`: 音訊剪輯（波形陣列和取樣率等元數據），以及
* `"text"`: 轉錄字串

Orpheus 支援像 `<laugh>`、`<chuckle>`、`<sigh>`、`<cough>`、`<sniffle>`、`<groan>`、`<yawn>`、`<gasp>` 等標籤。例如：`"I missed you <laugh> so much!"`。這些標籤括在角括號中，並將被模型視為特殊 token（它們與 [Orpheus 的預期標籤](https://github.com/canopyai/Orpheus-TTS) 如 `<laugh>` 和 `<sigh>` 相匹配。在訓練期間，模型將學習將這些標籤與相應的音訊模式關聯起來。帶有標籤的 Elise 資料集已經有很多這樣的標籤（例如，其卡片中列出的 336 次 "laughs"、156 次 "sighs" 等）。如果您的資料集缺乏此類標籤，但您想要合併它們，您可以在音訊包含這些表達的地方手動標註轉錄。

**選項 2：準備自訂資料集** – 如果您有自己的音訊檔案和轉錄：

* 將音訊剪輯（WAV/FLAC 檔案）整理在一個資料夾中。
* 建立一個包含檔案路徑和轉錄兩欄的 CSV 或 TSV 檔案。例如：
```

範例 2 (未知):
```unknown
* 使用 `load_dataset("csv", data_files="mydata.csv", split="train")` 來載入它。您可能需要告訴資料集載入器如何處理音訊路徑。另一種方法是使用 `datasets.Audio` 功能隨時載入音訊資料：
```

範例 3 (未知):
```unknown
接著 `dataset[i]["audio"]` 將包含音訊陣列。
* **確保轉錄已正規化**（除了使用的情感標籤外，沒有分詞器可能不知道的異常字元）。還要確保所有音訊具有一致的取樣率（如有必要，請將其重取樣為模型預期的目標速率，例如 Orpheus 為 24kHz）。

總結來說，對於 **資料集準備**：

* 您需要一個 **(audio, text)** 對的列表。
* 使用 HF `datasets` 函式庫來處理載入和選填的預處理（如重取樣）。
* 在文字中包含您希望模型學習的任何 **特殊標籤**（確保它們採用 `<angle_brackets>` 格式，以便模型將其視為獨立的 token）。
* （選填）如果是多說話者，您可以在文字中包含說話者 ID token，或使用單獨的說話者嵌入方法，但這超出了本基礎指南的範圍（Elise 是單說話者）。

### 使用 Unsloth 微調 TTS

現在，讓我們開始微調！我們將使用 Python 程式碼進行說明（您可以在 Jupyter notebook、Colab 等環境中執行）。

**步驟 1：載入模型和資料集**

在我們所有的 TTS notebook 中，我們使用 `load_in_4bit = False` 啟用 LoRA (16-bit) 訓練並停用 QLoRA (4-bit) 訓練。這是為了讓模型通常能更好地學習您的資料集並獲得更高的精確度。
```

範例 4 (未知):
```unknown
{% hint style="info" %}
如果記憶體非常有限或資料集很大，您可以進行串流傳輸或分塊載入。在這裡，3 小時的音訊可以輕鬆裝入 RAM。如果使用您自己的資料集 CSV，請以類似方式載入。
{% endhint %}

**步驟 2：進階 - 為訓練預處理資料（選填）**

我們需要為 Trainer 準備輸入。對於文字轉語音，一種方法是以因果（causal）方式訓練模型：將文字和音訊 token ID 串接作為目標序列。然而，由於 Orpheus 是一個輸出音訊的 decoder-only LLM，我們可以將文字作為輸入（上下文），並將音訊 token id 作為標籤（labels）。在實作中，如果模型的配置將其識別為文字轉語音，Unsloth 的整合可能會自動執行此操作。如果沒有，我們可以執行如下操作：
```

---

## 我們所有的模型

**URL:** llms-txt#all-our-models

**目錄：**
  - 新型 & 建議模型：
  - DeepSeek 模型：
  - Llama 模型：
  - Gemma 模型：
  - Qwen 模型：
  - Mistral 模型：
  - Phi 模型：
  - 其他 (GLM, Orpheus, Smol, Llava 等) 模型：
  - 新型模型：
  - DeepSeek 模型

Unsloth 模型目錄，包含我們在 Hugging Face 上的所有 [Dynamic](https://docs.unsloth.ai/basics/unsloth-dynamic-2.0-ggufs) GGUF、4-bit、16-bit 模型。

{% tabs %}
{% tab title="• GGUF + 4-bit" %} <a href="#deepseek-models" class="button secondary">DeepSeek</a><a href="#llama-models" class="button secondary">Llama</a><a href="#gemma-models" class="button secondary">Gemma</a><a href="#qwen-models" class="button secondary">Qwen</a><a href="#mistral-models" class="button secondary">Mistral</a><a href="#phi-models" class="button secondary">Phi</a>

**GGUF** 讓您可以在 Ollama、Open WebUI 和 llama.cpp 等工具中執行模型。\
**Instruct (4-bit)** safetensors 可用於推理或微調。

### 新型 & 建議模型：

| 模型 | 變體 | GGUF | Instruct (4-bit) |
| ------------------------------------------------------------------------------------------ | ---------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| [**gpt-oss** ](https://docs.unsloth.ai/models/gpt-oss-how-to-run-and-fine-tune) | 120b | [連結](https://huggingface.co/unsloth/gpt-oss-120b-GGUF) | [連結](https://huggingface.co/unsloth/gpt-oss-120b-unsloth-bnb-4bit) |
| | 20b | [連結](https://huggingface.co/unsloth/gpt-oss-20b-GGUF) | [連結](https://huggingface.co/unsloth/gpt-oss-20b-unsloth-bnb-4bit) |
| [**DeepSeek-V3.1**](https://docs.unsloth.ai/models/deepseek-v3.1-how-to-run-locally) | Terminus | [連結](https://huggingface.co/unsloth/DeepSeek-V3.1-Terminus-GGUF) | — |
| | V3.1 | [連結](https://huggingface.co/unsloth/DeepSeek-V3.1-GGUF) | — |
| [**Qwen3-VL**](https://docs.unsloth.ai/models/qwen3-vl-how-to-run-and-fine-tune) | 2B-Instruct | [連結](https://huggingface.co/unsloth/Qwen3-VL-2B-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-VL-2B-Instruct-unsloth-bnb-4bit) |
| | 2B-Thinking | [連結](https://huggingface.co/unsloth/Qwen3-VL-2B-Thinking-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-VL-2B-Thinking-unsloth-bnb-4bit) |
| | 4B-Instruct | [連結](https://huggingface.co/unsloth/Qwen3-VL-4B-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-VL-4B-Instruct-unsloth-bnb-4bit) |
| | 4B-Thinking | [連結](https://huggingface.co/unsloth/Qwen3-VL-4B-Thinking-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-VL-4B-Thinking-unsloth-bnb-4bit) |
| | 8B-Instruct | [連結](https://huggingface.co/unsloth/Qwen3-VL-8B-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-VL-8B-Instruct-unsloth-bnb-4bit) |
| | 8B-Thinking | [連結](https://huggingface.co/unsloth/Qwen3-VL-8B-Thinking-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-VL-8B-Thinking-unsloth-bnb-4bit) |
| | 30B-A3B-Instruct | [連結](https://huggingface.co/unsloth/Qwen3-VL-30B-A3B-Instruct-GGUF) | — |
| | 30B-A3B-Thinking | [連結](https://huggingface.co/unsloth/Qwen3-VL-30B-A3B-Thinking-GGUF) | — |
| | 32B-Instruct | [連結](https://huggingface.co/unsloth/Qwen3-VL-32B-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-VL-32B-Instruct-unsloth-bnb-4bit) |
| | 32B-Thinking | [連結](https://huggingface.co/unsloth/Qwen3-VL-32B-Thinking-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-VL-32B-Thinking-unsloth-bnb-4bit) |
| | 235B-A22B-Instruct | [連結](https://huggingface.co/unsloth/Qwen3-VL-235B-A22B-Instruct-GGUF) | — |
| | 235B-A22B-Thinking | [連結](https://huggingface.co/unsloth/Qwen3-VL-235B-A22B-Thinking-GGUF) | — |
| [**Qwen3-2507**](https://docs.unsloth.ai/models/qwen3-how-to-run-and-fine-tune/qwen3-2507) | 30B-A3B-Instruct | [連結](https://huggingface.co/unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF) | — |
| | 30B-A3B-Thinking | [連結](https://huggingface.co/unsloth/Qwen3-30B-A3B-Thinking-2507-GGUF) | — |
| | 235B-A22B-Thinking | [連結](https://huggingface.co/unsloth/Qwen3-235B-A22B-Thinking-2507-GGUF/) | — |
| | 235B-A22B-Instruct | [連結](https://huggingface.co/unsloth/Qwen3-235B-A22B-Instruct-2507-GGUF/) | — |
| **Qwen3-Coder** | 30B-A3B | [連結](https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF) | — |
| | 480B-A35B | [連結](https://huggingface.co/unsloth/Qwen3-Coder-480B-A35B-Instruct-GGUF) | — |
| **Granite-4.0 (新)** | H-Small | [連結](https://huggingface.co/unsloth/granite-4.0-h-small-GGUF) | [連結](https://huggingface.co/unsloth/granite-4.0-h-small-unsloth-bnb-4bit) |
| **GLM (新)** | 4.6 | [連結](https://huggingface.co/unsloth/GLM-4.6-GGUF) | — |
| | 4.5-Air | [連結](https://huggingface.co/unsloth/GLM-4.5-Air-GGUF) | — |
| **Kimi-K2-0905** | 1T | [連結](https://huggingface.co/unsloth/Kimi-K2-Instruct-0905-GGUF) | — |
| **Gemma 3n** | E2B | [連結](https://huggingface.co/unsloth/gemma-3n-E2B-it-GGUF) | [連結](https://huggingface.co/unsloth/gemma-3n-E2B-it-unsloth-bnb-4bit) |
| | E4B | [連結](https://huggingface.co/unsloth/gemma-3n-E4B-it-GGUF) | [連結](https://huggingface.co/unsloth/gemma-3n-E4B-it-unsloth-bnb-4bit) |
| **DeepSeek-R1-0528** | R1-0528-Qwen3-8B | [連結](https://huggingface.co/unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF) | [連結](https://huggingface.co/unsloth/DeepSeek-R1-0528-Qwen3-8B-unsloth-bnb-4bit) |
| | R1-0528 | [連結](https://huggingface.co/unsloth/DeepSeek-R1-0528-GGUF) | — |
| **Mistral** | Magistral Small (2509) | [連結](https://huggingface.co/unsloth/Magistral-Small-2509-GGUF) | [連結](https://huggingface.co/unsloth/Magistral-Small-2509-unsloth-bnb-4bit) |
| | Magistral Small (2507) | [連結](https://huggingface.co/unsloth/Magistral-Small-2507-GGUF) | [連結](https://huggingface.co/unsloth/Magistral-Small-2507-unsloth-bnb-4bit) |
| | Small 3.2 24B (2506) | [連結](https://huggingface.co/unsloth/Mistral-Small-3.2-24B-Instruct-2506-GGUF) | [連結](https://huggingface.co/unsloth/Mistral-Small-3.2-24B-Instruct-2506-unsloth-bnb-4bit) |
| FLUX.1 | Kontext-dev | [連結](https://huggingface.co/unsloth/FLUX.1-Kontext-dev-GGUF) | — |
| **Qwen3** | 0.6 B | [連結](https://huggingface.co/unsloth/Qwen3-0.6B-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-0.6B-unsloth-bnb-4bit) |
| | 1.7 B | [連結](https://huggingface.co/unsloth/Qwen3-1.7B-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-1.7B-unsloth-bnb-4bit) |
| | 4 B | [連結](https://huggingface.co/unsloth/Qwen3-4B-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-4B-unsloth-bnb-4bit) |
| | 8 B | [連結](https://huggingface.co/unsloth/Qwen3-8B-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-8B-unsloth-bnb-4bit) |
| | 14 B | [連結](https://huggingface.co/unsloth/Qwen3-14B-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-14B-unsloth-bnb-4bit) |
| | 30B-A3B | [連結](https://huggingface.co/unsloth/Qwen3-30B-A3B-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-30B-A3B-bnb-4bit) |
| | 32 B | [連結](https://huggingface.co/unsloth/Qwen3-32B-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-32B-unsloth-bnb-4bit) |
| | 235B-A22B | [連結](https://huggingface.co/unsloth/Qwen3-235B-A22B-GGUF) | — |
| **Llama 4** | Scout 17B 16E | [連結](https://huggingface.co/unsloth/Llama-4-Scout-17B-16E-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/Llama-4-Scout-17B-16E-Instruct-unsloth-bnb-4bit) |
| | Maverick 17B 128E | [連結](https://huggingface.co/unsloth/Llama-4-Maverick-17B-128E-Instruct-GGUF) | — |
| **Grok 2** | 270B | [連結](https://huggingface.co/unsloth/grok-2-GGUF) | — |
| **Qwen-2.5 Omni** | 3 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Omni-3B-GGUF) | — |
| | 7 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Omni-7B-GGUF) | — |
| **Phi-4** | Reasoning-plus | [連結](https://huggingface.co/unsloth/Phi-4-reasoning-plus-GGUF) | [連結](https://huggingface.co/unsloth/Phi-4-reasoning-plus-unsloth-bnb-4bit) |
| | Reasoning | [連結](https://huggingface.co/unsloth/Phi-4-reasoning-GGUF) | [連結](https://huggingface.co/unsloth/phi-4-reasoning-unsloth-bnb-4bit) |

### DeepSeek 模型：

| 模型 | 變體 | GGUF | Instruct (4-bit) |
| ----------------- | ---------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| **DeepSeek-V3.1** | Terminus | [連結](https://huggingface.co/unsloth/DeepSeek-V3.1-Terminus-GGUF) | |
| | V3.1 | [連結](https://huggingface.co/unsloth/DeepSeek-V3.1-GGUF) | |
| **DeepSeek-V3** | V3-0324 | [連結](https://huggingface.co/unsloth/DeepSeek-V3-0324-GGUF) | — |
| | V3 | [連結](https://huggingface.co/unsloth/DeepSeek-V3-GGUF) | — |
| **DeepSeek-R1** | R1-0528 | [連結](https://huggingface.co/unsloth/DeepSeek-R1-0528-GGUF) | — |
| | R1-0528-Qwen3-8B | [連結](https://huggingface.co/unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF) | [連結](https://huggingface.co/unsloth/DeepSeek-R1-0528-Qwen3-8B-unsloth-bnb-4bit) |
| | R1 | [連結](https://huggingface.co/unsloth/DeepSeek-R1-GGUF) | — |
| | R1 Zero | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Zero-GGUF) | — |
| | Distill Llama 3 8 B | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Llama-8B-GGUF) | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Llama-8B-unsloth-bnb-4bit) |
| | Distill Llama 3.3 70 B | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Llama-70B-GGUF) | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Llama-70B-bnb-4bit) |
| | Distill Qwen 2.5 1.5 B | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-1.5B-GGUF) | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-1.5B-unsloth-bnb-4bit) |
| | Distill Qwen 2.5 7 B | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-7B-GGUF) | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-7B-unsloth-bnb-4bit) |
| | Distill Qwen 2.5 14 B | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-14B-GGUF) | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-14B-unsloth-bnb-4bit) |
| | Distill Qwen 2.5 32 B | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-32B-GGUF) | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-32B-bnb-4bit) |

### Llama 模型：

| 模型 | 變體 | GGUF | Instruct (4-bit) |
| ------------- | ------------------- | ------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------- |
| **Llama 4** | Scout 17 B-16 E | [連結](https://huggingface.co/unsloth/Llama-4-Scout-17B-16E-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/Llama-4-Scout-17B-16E-Instruct-unsloth-bnb-4bit) |
| | Maverick 17 B-128 E | [連結](https://huggingface.co/unsloth/Llama-4-Maverick-17B-128E-Instruct-GGUF) | — |
| **Llama 3.3** | 70 B | [連結](https://huggingface.co/unsloth/Llama-3.3-70B-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/Llama-3.3-70B-Instruct-bnb-4bit) |
| **Llama 3.2** | 1 B | [連結](https://huggingface.co/unsloth/Llama-3.2-1B-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/Llama-3.2-1B-Instruct-bnb-4bit) |
| | 3 B | [連結](https://huggingface.co/unsloth/Llama-3.2-3B-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/Llama-3.2-3B-Instruct-bnb-4bit) |
| | 11 B Vision | — | [連結](https://huggingface.co/unsloth/Llama-3.2-11B-Vision-Instruct-unsloth-bnb-4bit) |
| | 90 B Vision | — | [連結](https://huggingface.co/unsloth/Llama-3.2-90B-Vision-Instruct-bnb-4bit) |
| **Llama 3.1** | 8 B | [連結](https://huggingface.co/unsloth/Llama-3.1-8B-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/Meta-Llama-3.1-8B-Instruct-bnb-4bit) |
| | 70 B | — | [連結](https://huggingface.co/unsloth/Meta-Llama-3.1-70B-Instruct-bnb-4bit) |
| | 405 B | — | [連結](https://huggingface.co/unsloth/Meta-Llama-3.1-405B-Instruct-bnb-4bit) |
| **Llama 3** | 8 B | — | [連結](https://huggingface.co/unsloth/llama-3-8b-Instruct-bnb-4bit) |
| | 70 B | — | [連結](https://huggingface.co/unsloth/llama-3-70b-bnb-4bit) |
| **Llama 2** | 7 B | — | [連結](https://huggingface.co/unsloth/llama-2-7b-chat-bnb-4bit) |
| | 13 B | — | [連結](https://huggingface.co/unsloth/llama-2-13b-bnb-4bit) |
| **CodeLlama** | 7 B | — | [連結](https://huggingface.co/unsloth/codellama-7b-bnb-4bit) |
| | 13 B | — | [連結](https://huggingface.co/unsloth/codellama-13b-bnb-4bit) |
| | 34 B | — | [連結](https://huggingface.co/unsloth/codellama-34b-bnb-4bit) |

### Gemma 模型：

| 模型 | 變體 | GGUF | Instruct (4-bit) |
| ------------ | ------------- | ------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| **Gemma 3n** | E2B | ​[連結](https://huggingface.co/unsloth/gemma-3n-E2B-it-GGUF) | [連結](https://huggingface.co/unsloth/gemma-3n-E2B-it-unsloth-bnb-4bit) |
| | E4B | [連結](https://huggingface.co/unsloth/gemma-3n-E4B-it-GGUF) | [連結](https://huggingface.co/unsloth/gemma-3n-E4B-it-unsloth-bnb-4bit) |
| **Gemma 3** | 270M | [連結](https://huggingface.co/unsloth/gemma-3-270m-it-GGUF) | [連結](https://huggingface.co/unsloth/gemma-3-270m-it) |
| | 1 B | [連結](https://huggingface.co/unsloth/gemma-3-1b-it-GGUF) | [連結](https://huggingface.co/unsloth/gemma-3-1b-it-unsloth-bnb-4bit) |
| | 4 B | [連結](https://huggingface.co/unsloth/gemma-3-4b-it-GGUF) | [連結](https://huggingface.co/unsloth/gemma-3-4b-it-unsloth-bnb-4bit) |
| | 12 B | [連結](https://huggingface.co/unsloth/gemma-3-12b-it-GGUF) | [連結](https://huggingface.co/unsloth/gemma-3-12b-it-unsloth-bnb-4bit) |
| | 27 B | [連結](https://huggingface.co/unsloth/gemma-3-27b-it-GGUF) | [連結](https://huggingface.co/unsloth/gemma-3-27b-it-unsloth-bnb-4bit) |
| **MedGemma** | 4 B (vision) | [連結](https://huggingface.co/unsloth/medgemma-4b-it-GGUF) | [連結](https://huggingface.co/unsloth/medgemma-4b-it-unsloth-bnb-4bit) |
| | 27 B (vision) | [連結](https://huggingface.co/unsloth/medgemma-27b-it-GGUF) | [連結](https://huggingface.co/unsloth/medgemma-27b-text-it-unsloth-bnb-4bit) |
| **Gemma 2** | 2 B | [連結](https://huggingface.co/unsloth/gemma-2-it-GGUF) | [連結](https://huggingface.co/unsloth/gemma-2-2b-it-bnb-4bit) |
| | 9 B | — | [連結](https://huggingface.co/unsloth/gemma-2-9b-it-bnb-4bit) |
| | 27 B | — | [連結](https://huggingface.co/unsloth/gemma-2-27b-it-bnb-4bit) |

### Qwen 模型：

| 模型 | 變體 | GGUF | Instruct (4-bit) |
| -------------------------- | ---------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **Qwen 3** | 0.6 B | [連結](https://huggingface.co/unsloth/Qwen3-0.6B-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-0.6B-unsloth-bnb-4bit) |
| | 1.7 B | [連結](https://huggingface.co/unsloth/Qwen3-1.7B-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-1.7B-unsloth-bnb-4bit) |
| | 4 B | [連結](https://huggingface.co/unsloth/Qwen3-4B-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-4B-unsloth-bnb-4bit) |
| | 8 B | [連結](https://huggingface.co/unsloth/Qwen3-8B-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-8B-unsloth-bnb-4bit) |
| | 14 B | [連結](https://huggingface.co/unsloth/Qwen3-14B-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-14B-unsloth-bnb-4bit) |
| | 30 B-A3B | [連結](https://huggingface.co/unsloth/Qwen3-30B-A3B-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-30B-A3B-bnb-4bit) |
| | 32 B | [連結](https://huggingface.co/unsloth/Qwen3-32B-GGUF) | [連結](https://huggingface.co/unsloth/Qwen3-32B-unsloth-bnb-4bit) |
| | 235 B-A22B | [連結](https://huggingface.co/unsloth/Qwen3-235B-A22B-GGUF) | — |
| **Qwen 2.5 Omni** | 3 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Omni-3B-GGUF) | — |
| | 7 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Omni-7B-GGUF) | — |
| **Qwen 2.5 VL** | 3 B | [連結](https://huggingface.co/unsloth/Qwen2.5-VL-3B-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/Qwen2.5-VL-3B-Instruct-unsloth-bnb-4bit) |
| | 7 B | [連結](https://huggingface.co/unsloth/Qwen2.5-VL-7B-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/Qwen2.5-VL-7B-Instruct-unsloth-bnb-4bit) |
| | 32 B | [連結](https://huggingface.co/unsloth/Qwen2.5-VL-32B-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/Qwen2.5-VL-32B-Instruct-unsloth-bnb-4bit) |
| | 72 B | [連結](https://huggingface.co/unsloth/Qwen2.5-VL-72B-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/Qwen2.5-VL-72B-Instruct-unsloth-bnb-4bit) |
| **Qwen 2.5** | 0.5 B | — | [連結](https://huggingface.co/unsloth/Qwen2.5-0.5B-Instruct-bnb-4bit) |
| | 1.5 B | — | [連結](https://huggingface.co/unsloth/Qwen2.5-1.5B-Instruct-bnb-4bit) |
| | 3 B | — | [連結](https://huggingface.co/unsloth/Qwen2.5-3B-Instruct-bnb-4bit) |
| | 7 B | — | [連結](https://huggingface.co/unsloth/Qwen2.5-7B-Instruct-bnb-4bit) |
| | 14 B | — | [連結](https://huggingface.co/unsloth/Qwen2.5-14B-Instruct-bnb-4bit) |
| | 32 B | — | [連結](https://huggingface.co/unsloth/Qwen2.5-32B-Instruct-bnb-4bit) |
| | 72 B | — | [連結](https://huggingface.co/unsloth/Qwen2.5-72B-Instruct-bnb-4bit) |
| **Qwen 2.5 Coder (128 K)** | 0.5 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-0.5B-Instruct-128K-GGUF) | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-0.5B-Instruct-bnb-4bit) |
| | 1.5 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-1.5B-Instruct-128K-GGUF) | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-1.5B-Instruct-bnb-4bit) |
| | 3 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-3B-Instruct-128K-GGUF) | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-3B-Instruct-bnb-4bit) |
| | 7 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-7B-Instruct-128K-GGUF) | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-7B-Instruct-bnb-4bit) |
| | 14 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-14B-Instruct-128K-GGUF) | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-14B-Instruct-bnb-4bit) |
| | 32 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-32B-Instruct-128K-GGUF) | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-32B-Instruct-bnb-4bit) |
| **QwQ** | 32 B | [連結](https://huggingface.co/unsloth/QwQ-32B-GGUF) | [連結](https://huggingface.co/unsloth/QwQ-32B-unsloth-bnb-4bit) |
| **QVQ (預覽版)** | 72 B | — | [連結](https://huggingface.co/unsloth/QVQ-72B-Preview-bnb-4bit) |
| **Qwen 2 (chat)** | 1.5 B | — | [連結](https://huggingface.co/unsloth/Qwen2-1.5B-Instruct-bnb-4bit) |
| | 7 B | — | [連結](https://huggingface.co/unsloth/Qwen2-7B-Instruct-bnb-4bit) |
| | 72 B | — | [連結](https://huggingface.co/unsloth/Qwen2-72B-Instruct-bnb-4bit) |
| **Qwen 2 VL** | 2 B | — | [連結](https://huggingface.co/unsloth/Qwen2-VL-2B-Instruct-unsloth-bnb-4bit) |
| | 7 B | — | [連結](https://huggingface.co/unsloth/Qwen2-VL-7B-Instruct-unsloth-bnb-4bit) |
| | 72 B | — | [連結](https://huggingface.co/unsloth/Qwen2-VL-72B-Instruct-bnb-4bit) |

### Mistral 模型：

<table><thead><tr><th width="174">模型</th><th>變體</th><th>GGUF</th><th>Instruct (4-bit)</th></tr></thead><tbody><tr><td><strong>Mistral Small</strong></td><td>3.2-24 B (2506)</td><td><a href="https://huggingface.co/unsloth/Mistral-Small-3.2-24B-Instruct-2506-GGUF">連結</a></td><td><a href="https://huggingface.co/unsloth/Mistral-Small-3.2-24B-Instruct-2506-unsloth-bnb-4bit">連結</a></td></tr><tr><td></td><td>3.1-24 B (2503)</td><td><a href="https://huggingface.co/unsloth/Mistral-Small-3.1-24B-Instruct-2503-GGUF">連結</a></td><td><a href="https://huggingface.co/unsloth/Mistral-Small-3.1-24B-Instruct-2503-unsloth-bnb-4bit">連結</a></td></tr><tr><td></td><td>3-24 B (2501)</td><td><a href="https://huggingface.co/unsloth/Mistral-Small-24B-Instruct-2501-GGUF">連結</a></td><td><a href="https://huggingface.co/unsloth/Mistral-Small-24B-Instruct-2501-unsloth-bnb-4bit">連結</a></td></tr><tr><td><strong>Magistral</strong></td><td>Small-24 B (2506)</td><td><a href="https://huggingface.co/unsloth/Magistral-Small-2506-GGUF">連結</a></td><td><a href="https://huggingface.co/unsloth/Magistral-Small-2506-unsloth-bnb-4bit">連結</a></td></tr><tr><td><strong>Devstral</strong></td><td>Small-24 B (2507)</td><td><a href="https://huggingface.co/unsloth/Devstral-Small-2507-GGUF">連結</a></td><td><a href="https://huggingface.co/unsloth/Devstral-Small-2507-unsloth-bnb-4bit">連結</a></td></tr><tr><td></td><td>Small-24 B (2505)</td><td><a href="https://huggingface.co/unsloth/Devstral-Small-2505-GGUF">連結</a></td><td><a href="https://huggingface.co/unsloth/Devstral-Small-2505-unsloth-bnb-4bit">連結</a></td></tr><tr><td><strong>Pixtral</strong></td><td>12 B (2409)</td><td>—</td><td><a href="https://huggingface.co/unsloth/Pixtral-12B-2409-bnb-4bit">連結</a></td></tr><tr><td>Mistral <strong>Small</strong></td><td>2409-22 B</td><td>—</td><td><a href="https://huggingface.co/unsloth/Mistral-Small-Instruct-2409-bnb-4bit">連結</a></td></tr><tr><td>Mistral <strong>NeMo</strong></td><td>12 B (2407)</td><td>—</td><td><a href="https://huggingface.co/unsloth/Mistral-Nemo-Instruct-2407-bnb-4bit">連結</a></td></tr><tr><td><strong>Mixtral</strong></td><td>8x7 B (v0.1)</td><td>—</td><td><a href="https://huggingface.co/unsloth/mixtral-8x7b-instruct-v0.1-bnb-4bit">連結</a></td></tr><tr><td><strong>Mistral</strong></td><td>7 B (v0.3)</td><td>—</td><td><a href="https://huggingface.co/unsloth/mistral-7b-instruct-v0.3-bnb-4bit">連結</a></td></tr><tr><td></td><td>7 B (v0.2)</td><td>—</td><td><a href="https://huggingface.co/unsloth/mistral-7b-instruct-v0.2-bnb-4bit">連結</a></td></tr></tbody></table>

### Phi 模型：

| 模型 | 變體 | GGUF | Instruct (4-bit) |
| ----------- | ---------------- | ---------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| **Phi-4** | Reasoning-plus | [連結](https://huggingface.co/unsloth/Phi-4-reasoning-plus-GGUF) | [連結](https://huggingface.co/unsloth/Phi-4-reasoning-plus-unsloth-bnb-4bit) |
| | Reasoning | [連結](https://huggingface.co/unsloth/Phi-4-reasoning-GGUF) | [連結](https://huggingface.co/unsloth/phi-4-reasoning-unsloth-bnb-4bit) |
| | Mini-Reasoning | [連結](https://huggingface.co/unsloth/Phi-4-mini-reasoning-GGUF) | [連結](https://huggingface.co/unsloth/Phi-4-mini-reasoning-unsloth-bnb-4bit) |
| | Phi-4 (instruct) | [連結](https://huggingface.co/unsloth/phi-4-GGUF) | [連結](https://huggingface.co/unsloth/phi-4-unsloth-bnb-4bit) |
| | mini (instruct) | [連結](https://huggingface.co/unsloth/Phi-4-mini-instruct-GGUF) | [連結](https://huggingface.co/unsloth/Phi-4-mini-instruct-unsloth-bnb-4bit) |
| **Phi-3.5** | mini | — | [連結](https://huggingface.co/unsloth/Phi-3.5-mini-instruct-bnb-4bit) |
| **Phi-3** | mini | — | [連結](https://huggingface.co/unsloth/Phi-3-mini-4k-instruct-bnb-4bit) |
| | medium | — | [連結](https://huggingface.co/unsloth/Phi-3-medium-4k-instruct-bnb-4bit) |

### 其他 (GLM, Orpheus, Smol, Llava 等) 模型：

| 模型 | 變體 | GGUF | Instruct (4-bit) |
| -------------- | ----------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------- |
| GLM | 4.5-Air | [連結](https://huggingface.co/unsloth/GLM-4.5-Air-GGUF) | |
| | 4.5 | [4.5](https://huggingface.co/unsloth/GLM-4.5-GGUF) | |
| | 4-32B-0414 | [4-32B-0414](https://huggingface.co/unsloth/GLM-4-32B-0414-GGUF) | |
| Hunyuan | A13B | [連結](https://huggingface.co/unsloth/Hunyuan-A13B-Instruct-GGUF) | — |
| Orpheus | 0.1-ft (3B) | [連結](https://app.gitbook.com/o/HpyELzcNe0topgVLGCZY/s/xhOjnexMCB3dmuQFQ2Zq/) | [連結](https://huggingface.co/unsloth/orpheus-3b-0.1-ft-unsloth-bnb-4bit) |
| **LLava** | 1.5 (7 B) | — | [連結](https://huggingface.co/unsloth/llava-1.5-7b-hf-bnb-4bit) |
| | 1.6 Mistral (7 B) | — | [連結](https://huggingface.co/unsloth/llava-v1.6-mistral-7b-hf-bnb-4bit) |
| **TinyLlama** | Chat | — | [連結](https://huggingface.co/unsloth/tinyllama-chat-bnb-4bit) |
| **SmolLM 2** | 135 M | [連結](https://huggingface.co/unsloth/SmolLM2-135M-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/SmolLM2-135M-Instruct-bnb-4bit) |
| | 360 M | [連結](https://huggingface.co/unsloth/SmolLM2-360M-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/SmolLM2-360M-Instruct-bnb-4bit) |
| | 1.7 B | [連結](https://huggingface.co/unsloth/SmolLM2-1.7B-Instruct-GGUF) | [連結](https://huggingface.co/unsloth/SmolLM2-1.7B-Instruct-bnb-4bit) |
| **Zephyr-SFT** | 7 B | — | [連結](https://huggingface.co/unsloth/zephyr-sft-bnb-4bit) |
| **Yi** | 6 B (v1.5) | — | [連結](https://huggingface.co/unsloth/Yi-1.5-6B-bnb-4bit) |
| | 6 B (v1.0) | — | [連結](https://huggingface.co/unsloth/yi-6b-bnb-4bit) |
| | 34 B (chat) | — | [連結](https://huggingface.co/unsloth/yi-34b-chat-bnb-4bit) |
| | 34 B (base) | — | [連結](https://huggingface.co/unsloth/yi-34b-bnb-4bit) |
| {% endtab %} | | | |

{% tab title="• Instruct 16-bit" %}
16-bit 和 8-bit Instruct 模型用於推理或微調：

### 新型模型：

| 模型 | 變體 | Instruct (16-bit) |
| -------------------- | ---------------------- | -------------------------------------------------------------------------- |
| **gpt-oss** (新) | 20b | [連結](https://huggingface.co/unsloth/gpt-oss-20b) |
| | 120b | [連結](https://huggingface.co/unsloth/gpt-oss-120b) |
| **Gemma 3n** | E2B | [連結](https://huggingface.co/unsloth/gemma-3n-E4B-it) |
| | E4B | [連結](https://huggingface.co/unsloth/gemma-3n-E2B-it) |
| **DeepSeek-R1-0528** | R1-0528-Qwen3-8B | [連結](https://huggingface.co/unsloth/DeepSeek-R1-0528-Qwen3-8B) |
| | R1-0528 | [連結](https://huggingface.co/unsloth/DeepSeek-R1-0528) |
| **Mistral** | Small 3.2 24B (2506) | [連結](https://huggingface.co/unsloth/Mistral-Small-3.2-24B-Instruct-2506) |
| | Small 3.1 24B (2503) | [連結](https://huggingface.co/unsloth/Mistral-Small-3.1-24B-Instruct-2503) |
| | Small 3.0 24B (2501) | [連結](https://huggingface.co/unsloth/Mistral-Small-24B-Instruct-2501) |
| | Magistral Small (2506) | [連結](https://huggingface.co/unsloth/Magistral-Small-2506) |
| **Qwen 3** | 0.6 B | [連結](https://huggingface.co/unsloth/Qwen3-0.6B) |
| | 1.7 B | [連結](https://huggingface.co/unsloth/Qwen3-1.7B) |
| | 4 B | [連結](https://huggingface.co/unsloth/Qwen3-4B) |
| | 8 B | [連結](https://huggingface.co/unsloth/Qwen3-8B) |
| | 14 B | [連結](https://huggingface.co/unsloth/Qwen3-14B) |
| | 30B-A3B | [連結](https://huggingface.co/unsloth/Qwen3-30B-A3B) |
| | 32 B | [連結](https://huggingface.co/unsloth/Qwen3-32B) |
| | 235B-A22B | [連結](https://huggingface.co/unsloth/Qwen3-235B-A22B) |
| **Llama 4** | Scout 17B-16E | [連結](https://huggingface.co/unsloth/Llama-4-Scout-17B-16E-Instruct) |
| | Maverick 17B-128E | [連結](https://huggingface.co/unsloth/Llama-4-Maverick-17B-128E-Instruct) |
| **Qwen 2.5 Omni** | 3 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Omni-3B) |
| | 7 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Omni-7B) |
| **Phi-4** | Reasoning-plus | [連結](https://huggingface.co/unsloth/Phi-4-reasoning-plus) |
| | Reasoning | [連結](https://huggingface.co/unsloth/Phi-4-reasoning) |

### DeepSeek 模型

| 模型 | 變體 | Instruct (16-bit) |
| --------------- | --------------------- | -------------------------------------------------------------------- |
| **DeepSeek-V3** | V3-0324 | [連結](https://huggingface.co/unsloth/DeepSeek-V3-0324) |
| | V3 | [連結](https://huggingface.co/unsloth/DeepSeek-V3) |
| **DeepSeek-R1** | R1-0528 | [連結](https://huggingface.co/unsloth/DeepSeek-R1-0528) |
| | R1-0528-Qwen3-8B | [連結](https://huggingface.co/unsloth/DeepSeek-R1-0528-Qwen3-8B) |
| | R1 | [連結](https://huggingface.co/unsloth/DeepSeek-R1) |
| | R1 Zero | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Zero) |
| | Distill Llama 3 8B | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Llama-8B) |
| | Distill Llama 3.3 70B | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Llama-70B) |
| | Distill Qwen 2.5 1.5B | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-1.5B) |
| | Distill Qwen 2.5 7B | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-7B) |
| | Distill Qwen 2.5 14B | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-14B) |
| | Distill Qwen 2.5 32B | [連結](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-32B) |

### Llama 模型

| 家族 | 變體 | Instruct (16-bit) |
| ------------- | ----------------- | ------------------------------------------------------------------------- |
| **Llama 4** | Scout 17B-16E | [連結](https://huggingface.co/unsloth/Llama-4-Scout-17B-16E-Instruct) |
| | Maverick 17B-128E | [連結](https://huggingface.co/unsloth/Llama-4-Maverick-17B-128E-Instruct) |
| **Llama 3.3** | 70 B | [連結](https://huggingface.co/unsloth/Llama-3.3-70B-Instruct) |
| **Llama 3.2** | 1 B | [連結](https://huggingface.co/unsloth/Llama-3.2-1B-Instruct) |
| | 3 B | [連結](https://huggingface.co/unsloth/Llama-3.2-3B-Instruct) |
| | 11 B Vision | [連結](https://huggingface.co/unsloth/Llama-3.2-11B-Vision-Instruct) |
| | 90 B Vision | [連結](https://huggingface.co/unsloth/Llama-3.2-90B-Vision-Instruct) |
| **Llama 3.1** | 8 B | [連結](https://huggingface.co/unsloth/Meta-Llama-3.1-8B-Instruct) |
| | 70 B | [連結](https://huggingface.co/unsloth/Meta-Llama-3.1-70B-Instruct) |
| | 405 B | [連結](https://huggingface.co/unsloth/Meta-Llama-3.1-405B-Instruct) |
| **Llama 3** | 8 B | [連結](https://huggingface.co/unsloth/llama-3-8b-Instruct) |
| | 70 B | [連結](https://huggingface.co/unsloth/llama-3-70b-Instruct) |
| **Llama 2** | 7 B | [連結](https://huggingface.co/unsloth/llama-2-7b-chat) |

### Gemma 模型：

| 模型 | 變體 | Instruct (16-bit) |
| ------------ | ------- | ------------------------------------------------------ |
| **Gemma 3n** | E2B | [連結](https://huggingface.co/unsloth/gemma-3n-E4B-it) |
| | E4B | [連結](https://huggingface.co/unsloth/gemma-3n-E2B-it) |
| **Gemma 3** | 1 B | [連結](https://huggingface.co/unsloth/gemma-3-1b-it) |
| | 4 B | [連結](https://huggingface.co/unsloth/gemma-3-4b-it) |
| | 12 B | [連結](https://huggingface.co/unsloth/gemma-3-12b-it) |
| | 27 B | [連結](https://huggingface.co/unsloth/gemma-3-27b-it) |
| **Gemma 2** | 2 B | [連結](https://huggingface.co/unsloth/gemma-2b-it) |
| | 9 B | [連結](https://huggingface.co/unsloth/gemma-9b-it) |
| | 27 B | [連結](https://huggingface.co/unsloth/gemma-27b-it) |

### Qwen 模型：

| 家族 | 變體 | Instruct (16-bit) |
| ------------------------ | --------- | ----------------------------------------------------------------------- |
| **Qwen 3** | 0.6 B | [連結](https://huggingface.co/unsloth/Qwen3-0.6B) |
| | 1.7 B | [連結](https://huggingface.co/unsloth/Qwen3-1.7B) |
| | 4 B | [連結](https://huggingface.co/unsloth/Qwen3-4B) |
| | 8 B | [連結](https://huggingface.co/unsloth/Qwen3-8B) |
| | 14 B | [連結](https://huggingface.co/unsloth/Qwen3-14B) |
| | 30B-A3B | [連結](https://huggingface.co/unsloth/Qwen3-30B-A3B) |
| | 32 B | [連結](https://huggingface.co/unsloth/Qwen3-32B) |
| | 235B-A22B | [連結](https://huggingface.co/unsloth/Qwen3-235B-A22B) |
| **Qwen 2.5 Omni** | 3 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Omni-3B) |
| | 7 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Omni-7B) |
| **Qwen 2.5 VL** | 3 B | [連結](https://huggingface.co/unsloth/Qwen2.5-VL-3B-Instruct) |
| | 7 B | [連結](https://huggingface.co/unsloth/Qwen2.5-VL-7B-Instruct) |
| | 32 B | [連結](https://huggingface.co/unsloth/Qwen2.5-VL-32B-Instruct) |
| | 72 B | [連結](https://huggingface.co/unsloth/Qwen2.5-VL-72B-Instruct) |
| **Qwen 2.5** | 0.5 B | [連結](https://huggingface.co/unsloth/Qwen2.5-0.5B-Instruct) |
| | 1.5 B | [連結](https://huggingface.co/unsloth/Qwen2.5-1.5B-Instruct) |
| | 3 B | [連結](https://huggingface.co/unsloth/Qwen2.5-3B-Instruct) |
| | 7 B | [連結](https://huggingface.co/unsloth/Qwen2.5-7B-Instruct) |
| | 14 B | [連結](https://huggingface.co/unsloth/Qwen2.5-14B-Instruct) |
| | 32 B | [連結](https://huggingface.co/unsloth/Qwen2.5-32B-Instruct) |
| | 72 B | [連結](https://huggingface.co/unsloth/Qwen2.5-72B-Instruct) |
| **Qwen 2.5 Coder 128 K** | 0.5 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-0.5B-Instruct-128K) |
| | 1.5 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-1.5B-Instruct-128K) |
| | 3 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-3B-Instruct-128K) |
| | 7 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-7B-Instruct-128K) |
| | 14 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-14B-Instruct-128K) |
| | 32 B | [連結](https://huggingface.co/unsloth/Qwen2.5-Coder-32B-Instruct-128K) |
| **QwQ** | 32 B | [連結](https://huggingface.co/unsloth/QwQ-32B) |
| **QVQ (預覽版)** | 72 B | — |
| **Qwen 2 (Chat)** | 1.5 B | [連結](https://huggingface.co/unsloth/Qwen2-1.5B-Instruct) |
| | 7 B | [連結](https://huggingface.co/unsloth/Qwen2-7B-Instruct) |
| | 72 B | [連結](https://huggingface.co/unsloth/Qwen2-72B-Instruct) |
| **Qwen 2 VL** | 2 B | [連結](https://huggingface.co/unsloth/Qwen2-VL-2B-Instruct) |
| | 7 B | [連結](https://huggingface.co/unsloth/Qwen2-VL-7B-Instruct) |
| | 72 B | [連結](https://huggingface.co/unsloth/Qwen2-VL-72B-Instruct) |

### Mistral 模型：

| 模型 | 變體 | Instruct (16-bit) |
| ---------------- | -------------- | ------------------------------------------------------------------ |
| **Mistral** | Small 2409-22B | [連結](https://huggingface.co/unsloth/Mistral-Small-Instruct-2409) |
| **Mistral** | Large 2407 | [連結](https://huggingface.co/unsloth/Mistral-Large-Instruct-2407) |
| **Mistral** | 7B v0.3 | [連結](https://huggingface.co/unsloth/mistral-7b-instruct-v0.3) |
| **Mistral** | 7B v0.2 | [連結](https://huggingface.co/unsloth/mistral-7b-instruct-v0.2) |
| **Pixtral** | 12B 2409 | [連結](https://huggingface.co/unsloth/Pixtral-12B-2409) |
| **Mixtral** | 8×7B | [連結](https://huggingface.co/unsloth/Mixtral-8x7B-Instruct-v0.1) |
| **Mistral NeMo** | 12B 2407 | [連結](https://huggingface.co/unsloth/Mistral-Nemo-Instruct-2407) |
| **Devstral** | Small 2505 | [連結](https://huggingface.co/unsloth/Devstral-Small-2505) |

### Phi 模型：

| 模型 | 變體 | Instruct (16-bit) |
| ----------- | -------------- | --------------------------------------------------------------- |
| **Phi-4** | Reasoning-plus | [連結](https://huggingface.co/unsloth/Phi-4-reasoning-plus) |
| | Reasoning | [連結](https://huggingface.co/unsloth/Phi-4-reasoning) |
| | Phi-4 (核心) | [連結](https://huggingface.co/unsloth/Phi-4) |
| | Mini-Reasoning | [連結](https://huggingface.co/unsloth/Phi-4-mini-reasoning) |
| | Mini | [連結](https://huggingface.co/unsloth/Phi-4-mini) |
| **Phi-3.5** | Mini | [連結](https://huggingface.co/unsloth/Phi-3.5-mini-instruct) |
| **Phi-3** | Mini | [連結](https://huggingface.co/unsloth/Phi-3-mini-4k-instruct) |
| | Medium | [連結](https://huggingface.co/unsloth/Phi-3-medium-4k-instruct) |

### 文字轉語音 (TTS) 模型：

| 模型 | Instruct (16-bit) |
| ---------------------- | ---------------------------------------------------------------- |
| Orpheus-3B (v0.1 ft) | [連結](https://huggingface.co/unsloth/orpheus-3b-0.1-ft) |
| Orpheus-3B (v0.1 pt) | [連結](https://huggingface.co/unsloth/orpheus-3b-0.1-pretrained) |
| Sesame-CSM 1B | [連結](https://huggingface.co/unsloth/csm-1b) |
| Whisper Large V3 (STT) | [連結](https://huggingface.co/unsloth/whisper-large-v3) |
| Llasa-TTS 1B | [連結](https://huggingface.co/unsloth/Llasa-1B) |
| Spark-TTS 0.5B | [連結](https://huggingface.co/unsloth/Spark-TTS-0.5B) |
| Oute-TTS 1B | [連結](https://huggingface.co/unsloth/Llama-OuteTTS-1.0-1B) |
| {% endtab %} | |

{% tab title="• Base 4 + 16-bit" %}
Base 模型通常用於微調目的：

### 新型模型：

| 模型 | 變體 | Base (16-bit) | Base (4-bit) |
| ------------ | ----------------- | ---------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| **Gemma 3n** | E2B | [連結](https://huggingface.co/unsloth/gemma-3n-E2B) | [連結](https://huggingface.co/unsloth/gemma-3n-E2B-unsloth-bnb-4bit) |
| | E4B | [連結](https://huggingface.co/unsloth/gemma-3n-E4B) | [連結](https://huggingface.co/unsloth/gemma-3n-E4B-unsloth-bnb-4bit) |
| **Qwen 3** | 0.6 B | [連結](https://huggingface.co/unsloth/Qwen3-0.6B-Base) | [連結](https://huggingface.co/unsloth/Qwen3-0.6B-Base-unsloth-bnb-4bit) |
| | 1.7 B | [連結](https://huggingface.co/unsloth/Qwen3-1.7B-Base) | [連結](https://huggingface.co/unsloth/Qwen3-1.7B-Base-unsloth-bnb-4bit) |
| | 4 B | [連結](https://huggingface.co/unsloth/Qwen3-4B-Base) | [連結](https://huggingface.co/unsloth/Qwen3-4B-Base-unsloth-bnb-4bit) |
| | 8 B | [連結](https://huggingface.co/unsloth/Qwen3-8B-Base) | [連結](https://huggingface.co/unsloth/Qwen3-8B-Base-unsloth-bnb-4bit) |
| | 14 B | [連結](https://huggingface.co/unsloth/Qwen3-14B-Base) | [連結](https://huggingface.co/unsloth/Qwen3-14B-Base-unsloth-bnb-4bit) |
| | 30B-A3B | [連結](https://huggingface.co/unsloth/Qwen3-30B-A3B-Base) | [連結](https://huggingface.co/unsloth/Qwen3-30B-A3B-Base-bnb-4bit) |
| **Llama 4** | Scout 17B 16E | [連結](https://huggingface.co/unsloth/Llama-4-Scout-17B-16E) | [連結](https://huggingface.co/unsloth/Llama-4-Scout-17B-16E-Instruct-unsloth-bnb-4bit) |
| | Maverick 17B 128E | [連結](https://huggingface.co/unsloth/Llama-4-Maverick-17B-128E) | — |

### **Llama 模型：**

| 模型 | 變體 | Base (16-bit) | Base (4-bit) |
| ------------- | ----------------- | ---------------------------------------------------------------- | ----------------------------------------------------------- |
| **Llama 4** | Scout 17B 16E | [連結](https://huggingface.co/unsloth/Llama-4-Scout-17B-16E) | — |
| | Maverick 17B 128E | [連結](https://huggingface.co/unsloth/Llama-4-Maverick-17B-128E) | — |
| **Llama 3.3** | 70 B | [連結](https://huggingface.co/unsloth/Llama-3.3-70B) | — |
| **Llama 3.2** | 1 B | [連結](https://huggingface.co/unsloth/Llama-3.2-1B) | — |
| | 3 B | [連結](https://huggingface.co/unsloth/Llama-3.2-3B) | — |
| | 11 B Vision | [連結](https://huggingface.co/unsloth/Llama-3.2-11B-Vision) | — |
| | 90 B Vision | [連結](https://huggingface.co/unsloth/Llama-3.2-90B-Vision) | — |
| **Llama 3.1** | 8 B | [連結](https://huggingface.co/unsloth/Meta-Llama-3.1-8B) | — |
| | 70 B | [連結](https://huggingface.co/unsloth/Meta-Llama-3.1-70B) | — |
| **Llama 3** | 8 B | [連結](https://huggingface.co/unsloth/llama-3-8b) | [連結](https://huggingface.co/unsloth/llama-3-8b-bnb-4bit) |
| **Llama 2** | 7 B | [連結](https://huggingface.co/unsloth/llama-2-7b) | [連結](https://huggingface.co/unsloth/llama-2-7b-bnb-4bit) |
| | 13 B | [連結](https://huggingface.co/unsloth/llama-2-13b) | [連結](https://huggingface.co/unsloth/llama-2-13b-bnb-4bit) |

### **Qwen 模型：**

| 模型 | 變體 | Base (16-bit) | Base (4-bit) |
| ------------ | ------- | --------------------------------------------------------- | -------------------------------------------------------------------------- |
| **Qwen 3** | 0.6 B | [連結](https://huggingface.co/unsloth/Qwen3-0.6B-Base) | [連結](https://huggingface.co/unsloth/Qwen3-0.6B-Base-unsloth-bnb-4bit) |
| | 1.7 B | [連結](https://huggingface.co/unsloth/Qwen3-1.7B-Base) | [連結](https://huggingface.co/unsloth/Qwen3-1.7B-Base-unsloth-bnb-4bit) |
| | 4 B | [連結](https://huggingface.co/unsloth/Qwen3-4B-Base) | [連結](https://huggingface.co/unsloth/Qwen3-4B-Base-unsloth-bnb-4bit) |
| | 8 B | [連結](https://huggingface.co/unsloth/Qwen3-8B-Base) | [連結](https://huggingface.co/unsloth/Qwen3-8B-Base-unsloth-bnb-4bit) |
| | 14 B | [連結](https://huggingface.co/unsloth/Qwen3-14B-Base) | [連結](https://huggingface.co/unsloth/Qwen3-14B-Base-unsloth-bnb-4bit) |
| | 30B-A3B | [連結](https://huggingface.co/unsloth/Qwen3-30B-A3B-Base) | [連結](https://huggingface.co/unsloth/Qwen3-30B-A3B-Base-unsloth-bnb-4bit) |
| **Qwen 2.5** | 0.5 B | [連結](https://huggingface.co/unsloth/Qwen2.5-0.5B) | [連結](https://huggingface.co/unsloth/Qwen2.5-0.5B-bnb-4bit) |
| | 1.5 B | [連結](https://huggingface.co/unsloth/Qwen2.5-1.5B) | [連結](https://huggingface.co/unsloth/Qwen2.5-1.5B-bnb-4bit) |
| | 3 B | [連結](https://huggingface.co/unsloth/Qwen2.5-3B) | [連結](https://huggingface.co/unsloth/Qwen2.5-3B-bnb-4bit) |
| | 7 B | [連結](https://huggingface.co/unsloth/Qwen2.5-7B) | [連結](https://huggingface.co/unsloth/Qwen2.5-7B-bnb-4bit) |
| | 14 B | [連結](https://huggingface.co/unsloth/Qwen2.5-14B) | [連結](https://huggingface.co/unsloth/Qwen2.5-14B-bnb-4bit) |
| | 32 B | [連結](https://huggingface.co/unsloth/Qwen2.5-32B) | [連結](https://huggingface.co/unsloth/Qwen2.5-32B-bnb-4bit) |
| | 72 B | [連結](https://huggingface.co/unsloth/Qwen2.5-72B) | [連結](https://huggingface.co/unsloth/Qwen2.5-72B-bnb-4bit) |
| **Qwen 2** | 1.5 B | [連結](https://huggingface.co/unsloth/Qwen2-1.5B) | [連結](https://huggingface.co/unsloth/Qwen2-1.5B-bnb-4bit) |
| | 7 B | [連結](https://huggingface.co/unsloth/Qwen2-7B) | [連結](https://huggingface.co/unsloth/Qwen2-7B-bnb-4bit) |

### **Llama 模型：**

| 模型 | 變體 | Base (16-bit) | Base (4-bit) |
| ------------- | ----------------- | ---------------------------------------------------------------- | ----------------------------------------------------------- |
| **Llama 4** | Scout 17B 16E | [連結](https://huggingface.co/unsloth/Llama-4-Scout-17B-16E) | — |
| | Maverick 17B 128E | [連結](https://huggingface.co/unsloth/Llama-4-Maverick-17B-128E) | — |
| **Llama 3.3** | 70 B | [連結](https://huggingface.co/unsloth/Llama-3.3-70B) | — |
| **Llama 3.2** | 1 B | [連結](https://huggingface.co/unsloth/Llama-3.2-1B) | — |
| | 3 B | [連結](https://huggingface.co/unsloth/Llama-3.2-3B) | — |
| | 11 B Vision | [連結](https://huggingface.co/unsloth/Llama-3.2-11B-Vision) | — |
| | 90 B Vision | [連結](https://huggingface.co/unsloth/Llama-3.2-90B-Vision) | — |
| **Llama 3.1** | 8 B | [連結](https://huggingface.co/unsloth/Meta-Llama-3.1-8B) | — |
| | 70 B | [連結](https://huggingface.co/unsloth/Meta-Llama-3.1-70B) | — |
| **Llama 3** | 8 B | [連結](https://huggingface.co/unsloth/llama-3-8b) | [連結](https://huggingface.co/unsloth/llama-3-8b-bnb-4bit) |
| **Llama 2** | 7 B | [連結](https://huggingface.co/unsloth/llama-2-7b) | [連結](https://huggingface.co/unsloth/llama-2-7b-bnb-4bit) |
| | 13 B | [連結](https://huggingface.co/unsloth/llama-2-13b) | [連結](https://huggingface.co/unsloth/llama-2-13b-bnb-4bit) |

### **Gemma 模型**

| 模型 | 變體 | Base (16-bit) | Base (4-bit) |
| ----------- | ------- | ----------------------------------------------------- | ---------------------------------------------------------------------- |
| **Gemma 3** | 1 B | [連結](https://huggingface.co/unsloth/gemma-3-1b-pt) | [連結](https://huggingface.co/unsloth/gemma-3-1b-pt-unsloth-bnb-4bit) |
| | 4 B | [連結](https://huggingface.co/unsloth/gemma-3-4b-pt) | [連結](https://huggingface.co/unsloth/gemma-3-4b-pt-unsloth-bnb-4bit) |
| | 12 B | [連結](https://huggingface.co/unsloth/gemma-3-12b-pt) | [連結](https://huggingface.co/unsloth/gemma-3-12b-pt-unsloth-bnb-4bit) |
| | 27 B | [連結](https://huggingface.co/unsloth/gemma-3-27b-pt) | [連結](https://huggingface.co/unsloth/gemma-3-27b-pt-unsloth-bnb-4bit) |
| **Gemma 2** | 2 B | [連結](https://huggingface.co/unsloth/gemma-2-2b) | — |
| | 9 B | [連結](https://huggingface.co/unsloth/gemma-2-9b) | — |
| | 27 B | [連結](https://huggingface.co/unsloth/gemma-2-27b) | — |

### **Mistral 模型：**

| 模型 | 變體 | Base (16-bit) | Base (4-bit) |
| ----------- | ---------------- | ------------------------------------------------------------------ | --------------------------------------------------------------- |
| **Mistral** | Small 24B 2501 | [連結](https://huggingface.co/unsloth/Mistral-Small-24B-Base-2501) | — |
| | NeMo 12B 2407 | [連結](https://huggingface.co/unsloth/Mistral-Nemo-Base-2407) | — |
| | 7B v0.3 | [連結](https://huggingface.co/unsloth/mistral-7b-v0.3) | [連結](https://huggingface.co/unsloth/mistral-7b-v0.3-bnb-4bit) |
| | 7B v0.2 | [連結](https://huggingface.co/unsloth/mistral-7b-v0.2) | [連結](https://huggingface.co/unsloth/mistral-7b-v0.2-bnb-4bit) |
| | Pixtral 12B 2409 | [連結](https://huggingface.co/unsloth/Pixtral-12B-Base-2409) | — |

### **其他 (TTS, TinyLlama) 模型：**

| 模型 | 變體 | Base (16-bit) | Base (4-bit) |
| -------------- | -------------- | ---------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| **TinyLlama** | 1.1 B (Base) | [連結](https://huggingface.co/unsloth/tinyllama) | [連結](https://huggingface.co/unsloth/tinyllama-bnb-4bit) |
| **Orpheus-3b** | 0.1-pretrained | [連結](https://huggingface.co/unsloth/orpheus-3b-0.1-pretrained) | [連結](https://huggingface.co/unsloth/orpheus-3b-0.1-pretrained-unsloth-bnb-4bit) |
| {% endtab %} | | | |
| {% endtabs %} | | | |

---

## Windows 安裝

**URL:** llms-txt#windows-installation

**目錄：**
- 方法 #1 - Docker:
- 方法 #2 - 直接在 Windows 安裝:
  - **備註**
  - **進階/疑難排解**
- 方法 #3 - 在 Windows 使用 PowerShell:
- 方法 #4 - 透過 WSL 在 Windows 安裝:

瞭解如何在有或沒有 WSL 的情況下在 Windows 上安裝 Unsloth。

對於 Windows，`pip install unsloth` 現在可以運作，但您必須預先安裝 Pytorch。

## 方法 #1 - Docker:

Docker 對於 Windows 使用者來說可能是開始使用 Unsloth 最簡單的方法，因為不需要設定，也沒有依賴問題。[**`unsloth/unsloth`**](https://hub.docker.com/r/unsloth/unsloth) 是 Unsloth 唯一的 Docker 映像。對於 [Blackwell](https://docs.unsloth.ai/basics/fine-tuning-llms-with-blackwell-rtx-50-series-and-unsloth) 和 50 系列 GPU，請使用相同的映像 - 不需要單獨的映像。

有關安裝說明，請遵循我們的 [Docker 指南](https://docs.unsloth.ai/new/how-to-fine-tune-llms-with-unsloth-and-docker)，否則這裡有一個快速入門指南：

{% stepper %}
{% step %}

#### 安裝 Docker 和 NVIDIA Container Toolkit。

透過 [Linux](https://docs.docker.com/engine/install/) 或 [Desktop](https://docs.docker.com/desktop/) (其他) 安裝 Docker。\
接著安裝 [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installation)：

<pre class="language-bash"><code class="lang-bash"><strong>export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.17.8-1
</strong>sudo apt-get update &#x26;&#x26; sudo apt-get install -y \
  nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
  nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
  libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
  libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION}
</code></pre>

#### 執行容器。

[**`unsloth/unsloth`**](https://hub.docker.com/r/unsloth/unsloth) 是 Unsloth 唯一的 Docker 映像。

```bash
docker run -d -e JUPYTER_PASSWORD="mypassword" \
  -p 8888:8888 -p 2222:22 \
  -v $(pwd)/work:/workspace/work \
  --gpus all \
  unsloth/unsloth
```

#### 存取 Jupyter Lab

前往 [http://localhost:8888](http://localhost:8888/) 並開啟 Unsloth。存取 `unsloth-notebooks` 分頁以查看 Unsloth notebook。
{% endstep %}

#### 開始使用 Unsloth 進行訓練

如果您是新手，請遵循我們逐步的 [微調指南](https://docs.unsloth.ai/get-started/fine-tuning-llms-guide)、[RL 指南](https://docs.unsloth.ai/get-started/reinforcement-learning-rl-guide) 或僅儲存/複製我們任何預製的 [notebook](https://docs.unsloth.ai/get-started/unsloth-notebooks)。
{% endstep %}
{% endstepper %}

## 方法 #2 - 直接在 Windows 安裝:

{% hint style="info" %}
Python 3.13 現在可以與 Unsloth 配合使用！
{% endhint %}

{% stepper %}
{% step %}
**安裝 NVIDIA 視訊驅動程式**

您應該安裝最新版本的 GPU 驅動程式。在此下載驅動程式：[NVIDIA GPU 驅動程式](https://www.nvidia.com/Download/index.aspx)
{% endstep %}

{% step %}
**安裝 Visual Studio C++**

您將需要安裝了 C++ 的 Visual Studio。預設情況下，Visual Studio 不會安裝 C++，因此請確保選取所有 C++ 選項。同時選取 Windows 10/11 SDK 的選項。

* 在此啟動安裝程式： [Visual Studio Community Edition](https://visualstudio.microsoft.com/vs/community/)
* 在安裝程式中，導覽至個別元件並選取此處列出的所有選項：
  * **.NET Framework 4.8 SDK**
  * **.NET Framework 4.7.2 targeting pack**
  * **C# and Visual Basic Roslyn compilers**
  * **MSBuild**
  * **MSVC v143 - VS 2022 C++ x64/x86 build tools**
  * **C++ 2022 Redistributable Update**
  * **C++ CMake tools for Windows**
  * **C++/CLI support for v143 build tools (Latest)**
  * **MSBuild support for LLVM (clang-cl) toolset**
  * **C++ Clang Compiler for Windows (19.1.1)**
  * **Windows 11 SDK (10.0.22621.0)**
  * **Windows Universal CRT SDK**
  * **C++ 2022 Redistributable MSMs**

**較簡單的方法：** 或者您可以開啟具有提高權限的命令提示字元或 PowerShell：

* 搜尋 "cmd" 或 "PowerShell"，按右鍵點選它，然後選擇「以管理員身分執行」。
* 貼上並執行此指令（如有必要，請更新 Visual Studio 路徑）：

```
"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe" modify ^
--installPath "C:\Program Files\Microsoft Visual Studio\2022\Community" ^
--add Microsoft.Net.Component.4.8.SDK ^
--add Microsoft.Net.Component.4.7.2.TargetingPack ^
--add Microsoft.VisualStudio.Component.Roslyn.Compiler ^
--add Microsoft.Component.MSBuild ^
--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ^
--add Microsoft.VisualStudio.Component.VC.Redist.14.Latest ^
--add Microsoft.VisualStudio.Component.VC.CMake.Project ^
--add Microsoft.VisualStudio.Component.VC.CLI.Support ^
--add Microsoft.VisualStudio.Component.VC.Llvm.Clang ^
--add Microsoft.VisualStudio.ComponentGroup.ClangCL ^
--add Microsoft.VisualStudio.Component.Windows11SDK.22621 ^
--add Microsoft.VisualStudio.Component.Windows10SDK.19041 ^
--add Microsoft.VisualStudio.Component.UniversalCRT.SDK ^
--add Microsoft.VisualStudio.Component.VC.Redist.MSM
```

{% step %}
**安裝 Python 和 CUDA Toolkit**

按照說明安裝 [CUDA Toolkit](https://developer.nvidia.com/cuda-toolkit-archive)。

接著在此處安裝 Miniconda（包含 Python）：[https://www.anaconda.com/docs/getting-started/miniconda/install](https://www.anaconda.com/docs/getting-started/miniconda/install#quickstart-install-instructions)
{% endstep %}

{% step %}
**安裝 PyTorch**

您將需要與您的 CUDA 驅動程式相容的正確版本的 PyTorch，因此請務必仔細選擇。[安裝 PyTorch](https://pytorch.org/get-started/locally/)
{% endstep %}

{% step %}
**安裝 Unsloth**

開啟 Conda 命令提示字元或帶有 Python 的終端機並執行指令：

```
pip install "unsloth[windows] @ git+https://github.com/unslothai/unsloth.git"
```

{% endstep %}
{% endstepper %}

{% hint style="warning" %}
如果您正在使用 GRPO 或計劃使用 vLLM，目前 vLLM 不直接支援 Windows，僅能透過 WSL 或 Linux 支援。
{% endhint %}

要在 Windows 上直接執行 Unsloth：

* 從此 Windows 分支安裝 Triton，並遵循[此處](https://github.com/woct0rdho/triton-windows)的說明（請注意，Windows 分支需要 PyTorch >= 2.4 和 CUDA 12）
* 在 SFTTrainer 中，設定 `dataset_num_proc=1` 以避免當機問題：

```python
trainer = SFTTrainer(
    dataset_num_proc=1,
    ...
)
```

### **進階/疑難排解**

有關 **進階安裝說明** 或如果您在安裝過程中看到奇怪的錯誤：

1. 安裝 `torch` 和 `triton`。前往 <https://pytorch.org> 安裝。例如 `pip install torch torchvision torchaudio triton`
2. 確認 CUDA 是否安裝正確。嘗試 `nvcc`。如果失敗，您需要安裝 `cudatoolkit` 或 CUDA 驅動程式。
3. 手動安裝 `xformers`。您可以嘗試安裝 `vllm` 並查看 `vllm` 是否成功。使用 `python -m xformers.info` 檢查 `xformers` 是否成功。前往 <https://github.com/facebookresearch/xformers>。另一個選擇是為 Ampere GPU 安裝 `flash-attn`。
4. 仔細檢查您的 Python、CUDA、CUDNN、`torch`、`triton` 和 `xformers` 版本是否相互相容。[PyTorch 相容性矩陣](https://github.com/pytorch/pytorch/blob/main/RELEASE.md#release-compatibility-matrix) 可能會很有用。
5. 最後，安裝 `bitsandbytes` 並使用 `python -m bitsandbytes` 檢查。

## 方法 #3 - 在 Windows 使用 PowerShell:

#### **步驟 1：安裝先決條件**

1. **安裝 NVIDIA CUDA Toolkit**：
   * 從 [CUDA 下載](https://developer.nvidia.com/cuda-downloads) 下載並安裝適當版本的 **NVIDIA CUDA Toolkit**。
   * 如果出現提示，請在安裝後重新啟動系統。
   * **注意**：安裝後不需要為 Unsloth 進行額外設定。
2. **安裝 Microsoft C++ 構建工具**：
   * 從 [官方網站](https://visualstudio.microsoft.com/visual-cpp-build-tools/) 下載並安裝 **Microsoft Build Tools for Visual Studio**。
   * 在安裝期間，選取 **C++ 構建工具** 工作負載。\
     確保包含 **MSVC 編譯器工具集**。
3. **為 C++ 編譯器設定環境變數**：
   * 開啟 **系統屬性** 視窗（在「開始」功能表中搜尋「環境變數」）。
   * 點選 **「環境變數…」**。
   * 在 **系統變數** 下新增或更新以下內容：
     * **CC**：\
       `cl.exe` C++ 編譯器的路徑。\
       範例（如果您的版本不同，請調整）：

       ```plaintext
       C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.34.31933\bin\Hostx64\x64\cl.exe
       ```
     * **CXX**：\
       與 `CC` 路徑相同。
   * 點選 **確定** 儲存更改。
   * 驗證：開啟新終端機並輸入 `cl`。它應該會顯示版本資訊。
4. **安裝 Conda**
   1. 從 [官方網站](https://docs.anaconda.com/miniconda/install/#quick-command-line-install) 下載並安裝 **Miniconda**
   2. 按照網站上的安裝說明進行操作
   3. 要檢查是否已安裝 `conda`，您可以在 PowerShell 中使用 `conda` 進行測試

#### **步驟 2：執行 Unsloth 安裝指令碼**

1. **點選此連結下載 [unsloth\_windows.ps1](https://github.com/unslothai/notebooks/blob/main/unsloth_windows.ps1) PowerShell 指令碼**。
2. **以管理員身分開啟 PowerShell**：
   * 右鍵點選「開始」並選取 **「Windows PowerShell (管理員)」**。
3. 使用 `cd` **導覽至指令碼所在位置**：

   ```powershell
   cd path\to\script\folder
   ```
4. **執行指令碼**：

   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\unsloth_windows.ps1
   ```

#### **步驟 3：使用 Unsloth**

安裝完成後啟動環境：

```powershell
conda activate unsloth_env
```

**Unsloth 及其依賴項現在已就緒！**

***

## 方法 #4 - 透過 WSL 在 Windows 安裝:

WSL 是 Windows 的 Linux 子系統。

1. 透過 [Python 官方網站](https://www.python.org/downloads/windows/) 安裝 Python。
2. 啟動 WSL（應該已經預裝）。以管理員身分開啟命令提示字元，然後執行：

```
wsl -d ubuntu
```

選填：如果未預裝 WSL，請前往 Microsoft Store 搜尋 "Ubuntu"，顯示為 Ubuntu 的應用程式即為 WSL。安裝並執行它，然後從那裡繼續。

3. 更新 WSL：

```
sudo apt update && sudo apt upgrade -y
```

4. 安裝 pip：

```
sudo apt install python3-pip
```

5. 安裝 unsloth：

```
pip install unsloth
```

6. 選填：安裝 Jupyter Notebook 以在類似 Colab 的環境中執行：

```
pip3 install notebook
```

7. 啟動 Jupyter Notebook：

<pre><code><strong>jupyter notebook
</strong></code></pre>

8. 從 Unsloth 下載任何 Colab notebook，將其匯入您的 Jupyter Notebook，根據需要調整參數，然後執行指令碼。

**範例：**

範例 1 (bash):
```bash
docker run -d -e JUPYTER_PASSWORD="mypassword" \
  -p 8888:8888 -p 2222:22 \
  -v $(pwd)/work:/workspace/work \
  --gpus all \
  unsloth/unsloth
```

範例 2 (未知):
```unknown
"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe" modify ^
--installPath "C:\Program Files\Microsoft Visual Studio\2022\Community" ^
--add Microsoft.Net.Component.4.8.SDK ^
--add Microsoft.Net.Component.4.7.2.TargetingPack ^
--add Microsoft.VisualStudio.Component.Roslyn.Compiler ^
--add Microsoft.Component.MSBuild ^
--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ^
--add Microsoft.VisualStudio.Component.VC.Redist.14.Latest ^
--add Microsoft.VisualStudio.Component.VC.CMake.Project ^
--add Microsoft.VisualStudio.Component.VC.CLI.Support ^
--add Microsoft.VisualStudio.Component.VC.Llvm.Clang ^
--add Microsoft.VisualStudio.ComponentGroup.ClangCL ^
--add Microsoft.VisualStudio.Component.Windows11SDK.22621 ^
--add Microsoft.VisualStudio.Component.Windows10SDK.19041 ^
--add Microsoft.VisualStudio.Component.UniversalCRT.SDK ^
--add Microsoft.VisualStudio.Component.VC.Redist.MSM
```

範例 3 (未知):
```unknown
pip install "unsloth[windows] @ git+https://github.com/unslothai/unsloth.git"
```

範例 4 (python):
```python
trainer = SFTTrainer(
    dataset_num_proc=1,
    ...
)
```

---

## 使用您的影像檔準備批次輸入

**URL:** llms-txt#prepare-batched-input-with-your-image-file

```python
image_1 = Image.open("path/to/your/image_1.png").convert("RGB")
image_2 = Image.open("path/to/your/image_2.png").convert("RGB")
prompt = "<image>\nFree OCR."

model_input = [
    {
        "prompt": prompt,
        "multi_modal_data": {"image": image_1}
    },
    {
        "prompt": prompt,
        "multi_modal_data": {"image": image_2}
    }
]

sampling_param = SamplingParams(
    temperature=0.0,
    max_tokens=8192,
    # ngram logit processor args
    extra_args=dict(
        ngram_size=30,
        window_size=90,
        whitelist_token_ids={128821, 128822},  # whitelist: <td>, </td>
    ),
    skip_special_tokens=False,
)
```

---

## DeepSeek-V3-0324: 如何在本地執行

**URL:** llms-txt#deepseek-v3-0324:-how-to-run-locally

**目錄：**
- :gear: 官方建議設定
- 📖 教學：如何在 llama.cpp 中執行 DeepSeek-V3

如何使用我們可恢復精度的動態量化在本地執行 DeepSeek-V3-0324

{% hint style="info" %}
請參閱 <https://docs.unsloth.ai/basics/deepseek-r1-0528-how-to-run-locally>（2025 年 5 月 28 日更新）以瞭解如何更快速、更高效地執行 DeepSeek！
{% endhint %}

DeepSeek 又來了！在 2024 年 12 月和 2025 年 1 月發佈 V3、R1 Zero 和 R1 之後，DeepSeek 更新了 V3 的檢查點/模型，並發佈了 3 月更新！

根據 DeepSeek 的說法，MMLU-Pro 躍升了 +5.3% 達到 81.2%。**GPQA 提升了 +9.3%**。AIME 提升了 +19.8%，LiveCodeBench 提升了 +10.0%！他們提供了一張圖表，展示了他們與之前的 V3 檢查點以及 GPT 4.5 和 Claude Sonnet 3.7 等其他模型的對比。<mark style="background-color:blue;">**但我們該如何在本地執行一個擁有 6710 億參數的模型呢？**</mark>

<table data-full-width="true"><thead><tr><th>MoE 位元</th><th>類型</th><th>磁碟大小</th><th>精確度</th><th>連結</th><th>詳情</th></tr></thead><tbody><tr><td>1.78bit</td><td>IQ1_S</td><td><strong>173GB</strong></td><td>Ok</td><td><a href="https://huggingface.co/unsloth/DeepSeek-V3-0324-GGUF/tree/main/UD-IQ1_S">連結</a></td><td>2.06/1.56bit</td></tr><tr><td>1.93bit</td><td>IQ1_M</td><td><strong>183GB</strong></td><td>普通</td><td><a href="https://huggingface.co/unsloth/DeepSeek-V3-0324-GGUF/tree/main/UD-IQ1_M">連結</a></td><td>2.5/2.06/1.56</td></tr><tr><td>2.42bit</td><td>IQ2_XXS</td><td><strong>203GB</strong></td><td><mark style="background-color:blue;"><strong>建議</strong></mark></td><td><a href="https://huggingface.co/unsloth/DeepSeek-V3-0324-GGUF/tree/main/UD-IQ2_XXS">連結</a></td><td>2.5/2.06bit</td></tr><tr><td>2.71bit</td><td>Q2_K_XL</td><td><strong>231GB</strong></td><td><mark style="background-color:purple;"><strong>建議</strong></mark></td><td><a href="https://huggingface.co/unsloth/DeepSeek-V3-0324-GGUF/tree/main/UD-Q2_K_XL">連結</a></td><td> 3.5/2.5bit</td></tr><tr><td>3.5bit</td><td>Q3_K_XL</td><td><strong>320GB</strong></td><td>優異</td><td><a href="https://huggingface.co/unsloth/DeepSeek-V3-0324-GGUF/tree/main/UD-Q3_K_XL">連結</a></td><td> 4.5/3.5bit</td></tr><tr><td>4.5bit</td><td>Q4_K_XL</td><td><strong>406GB</strong></td><td>最佳</td><td><a href="https://huggingface.co/unsloth/DeepSeek-V3-0324-GGUF/tree/main/UD-Q4_K_XL">連結</a></td><td> 5.5/4.5bit</td></tr></tbody></table>

{% hint style="success" %}
DeepSeek V3 的原始上傳格式為 float8，佔用 715GB。使用 Q4\_K\_M 可將檔案大小減半至 404GB 左右，而我們的動態 1.78bit 量化僅需約 151GB。**我們建議使用我們的 2.7bit 量化來平衡大小和精確度！2.4bit 的版本效果也不錯！**
{% endhint %}

## :gear: 官方建議設定

根據 [DeepSeek](https://huggingface.co/deepseek-ai/DeepSeek-V3-0324) 的說明，以下是推理的建議設定：

* <mark style="background-color:blue;">**Temperature 為 0.3**</mark>（對於程式碼編寫，可能為 0.0，如[此處所示](https://api-docs.deepseek.com/quick_start/parameter_settings)）
* Min\_P 為 0.00（選填，但 0.01 效果很好，llama.cpp 預設為 0.1）
* 對話模板：`<｜User｜>Create a simple playable Flappy Bird Game in Python. Place the final game inside of a markdown section.<｜Assistant｜>`&#x20;
* 在分詞過程中會自動加入 `<｜begin▁of▁sentence｜>` 的 BOS token（請勿手動加入！）&#x20;
* DeepSeek 還提到了使用 <mark style="background-color:green;">**系統提示語 (system prompt)**</mark>（選填）- 它是中文的：`该助手为DeepSeek Chat，由深度求索公司创造。\n今天是3月24日，星期一。` 翻譯為：`此助理為 DeepSeek Chat，由 DeepSeek 創造。\n今天是 3 月 24 日，星期一。`&#x20;
* <mark style="background-color:orange;">**對於 KV 快取量化，請使用 8bit，而非 4bit - 我們發現後者的表現明顯較差。**</mark>

## 📖 教學：如何在 llama.cpp 中執行 DeepSeek-V3

1. 在 [GitHub 這裡](https://github.com/ggml-org/llama.cpp) 取得最新的 `llama.cpp`。您也可以按照下方的構建說明操作。如果您沒有 GPU 或只想進行 CPU 推理，請將 `-DGGML_CUDA=ON` 更改為 `-DGGML_CUDA=OFF`。

{% hint style="warning" %}
注意：對於 GPU 使用 `-DGGML_CUDA=ON` 可能需要 5 分鐘來編譯。CPU 僅需 1 分鐘。您可能會對 llama.cpp 的預編譯二進位檔感興趣。
{% endhint %}

2. 透過（在安裝 `pip install huggingface_hub hf_transfer` 之後）下載模型。您可以選擇 `UD-IQ1_S`（動態 1.78bit 量化）或其他量化版本如 `Q4_K_M`。<mark style="background-color:green;">**我建議使用我們的 2.7bit 動態量化**</mark><mark style="background-color:green;">**&#x20;**</mark><mark style="background-color:green;">**`UD-Q2_K_XL`**</mark><mark style="background-color:green;">**&#x20;**</mark><mark style="background-color:green;">**以平衡大小和精確度**</mark>。更多版本請見：<https://huggingface.co/unsloth/DeepSeek-V3-0324-GGUF>

{% code overflow="wrap" %}

**範例：**

範例 1 (bash):
```bash
apt-get update
apt-get install pciutils build-essential cmake curl libcurl4-openssl-dev -y
git clone https://github.com/ggml-org/llama.cpp
cmake llama.cpp -B llama.cpp/build \
    -DBUILD_SHARED_LIBS=OFF -DGGML_CUDA=ON -DLLAMA_CURL=ON
cmake --build llama.cpp/build --config Release -j --clean-first --target llama-quantize llama-cli llama-gguf-split
cp llama.cpp/build/bin/llama-* llama.cpp
```

---

## 量化感知訓練 (QAT)

**URL:** llms-txt#quantization-aware-training-(qat)

**目錄：**
  - :books:量化
  - :fire:更智慧的量化
  - :mag:量化感知訓練
  - :sparkles:QAT + LoRA 微調
  - :teapot:匯出 QAT 模型

使用 Unsloth 和 PyTorch 將模型量化為 4-bit 以恢復精度。

與 PyTorch 合作，我們在 Unsloth 中引入了 QAT (Quantization-Aware Training)，以實現 **可訓練量化**，從而盡可能恢復精確度。與標準 4-bit 樸素量化相比，這能顯著提升模型品質。QAT 可以恢復高達 <mark style="background-color:$success;">**70% 損失的精確度**</mark> 和 <mark style="background-color:$success;">**1–3%**</mark> 的模型效能提升，並在 GPQA 和 MMLU Pro 等基準測試中展現。

> **透過我們免費的** [**Qwen3 (4B) notebook**](https://colab.research.google.com/github/unslothai/notebooks/blob/main/nb/Qwen3_\(4B\)_Instruct-QAT.ipynb) **嘗試 QAT**

### :books:量化

{% columns %}
{% column width="50%" %}
樸素地量化模型被稱為 **訓練後量化** (Post-Training Quantization, PTQ)。例如，假設我們想要量化為 8bit 整數：

1. 尋找 `max(abs(W))`
2. 尋找 `a = 127/max(abs(W))`，其中 a 是 int8 的最大範圍，即 127
3. 透過 `qW = int8(round(W  * a))` 進行量化
   {% endcolumn %}

{% column width="50%" %}

<figure><img src="https://3215535692-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FxhOjnexMCB3dmuQFQ2Zq%2Fuploads%2FBRGG7dajyErOS6kUPRCn%2Fquant-freeze.png?alt=media&#x26;token=99013e3d-30cb-43c2-bef2-97f8770a2801" alt=""><figcaption></figcaption></figure>
{% endcolumn %}
{% endcolumns %}

反量化回 16bit 僅需透過 `float16(qW) / a` 執行反向操作。訓練後量化 (PTQ) 可以大幅降低儲存和推理成本，但在用較少位元表示高精度值時，通常會降低精確度 - 特別是在 4-bit 或更低位元時。解決此問題的一種方法是利用我們的 [**動態 GGUF 量化**](https://docs.unsloth.ai/basics/unsloth-dynamic-2.0-ggufs)，它使用校準資料集來更改量化程序，以為重要的權重分配更多權重。另一種方法是讓 **量化更智慧，使其成為可訓練或可學習的**！

### :fire:更智慧的量化

<div><figure><img src="https://3215535692-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FxhOjnexMCB3dmuQFQ2Zq%2Fuploads%2FD0KA3paC1csL6jM5doqL%2F4bit_QAT_recovery_sideways_clipped75_bigtext_all(1).png?alt=media&#x26;token=93c92a1b-e95f-488f-9289-996ffb309054" alt=""><figcaption></figcaption></figure> <figure><img src="https://3215535692-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FxhOjnexMCB3dmuQFQ2Zq%2Fuploads%2FAbhfUEY2QiKzj6ZenxLF%2FQLoRA_QAT_Accuracy_Boosts_v7_bigaxes_nogrid_600dpi.png?alt=media&#x26;token=24f79aff-4261-44a6-8bae-5bf85b247472" alt=""><figcaption></figcaption></figure></div>

為了實現更智慧的量化，我們與 [TorchAO](https://github.com/pytorch/ao) 團隊合作，直接在 Unsloth 內部加入 **量化感知訓練 (QAT)** - 因此現在您可以在 Unsloth 中微調模型，然後直接將其匯出為 4-bit QAT 格式，並獲得精確度提升！

事實上，**QAT 恢復了** Gemma3-4B 在 GPQA 上 **66.9%** 的損失，並將原始精確度提高了 +1.0%。Gemma3-12B 在 BBH 上恢復了 45.5%，並 **提高了原始精確度 +2.1%**。QAT 在推理期間沒有額外開銷，並且使用與普通樸素量化相同的磁碟和記憶體空間！因此，您獲得了低位元量化的所有好處，但精確度大大提高！

### :mag:量化感知訓練

QAT 透過在訓練期間對權重和（可選的）激活進行「**偽量化 (fake quantizing)**」來模擬真實的量化過程，這通常意味著將高精度值捨入為量化值（同時保持高精度 dtype，例如 bfloat16），然後立即對其進行反量化。

TorchAO 透過以下方式實現 QAT：(1) 在線性層中插入偽量化操作，以及 (2) 在訓練後將偽量化操作轉換為實際的量化和反量化操作，使其可用於推理。步驟 1 讓我們能夠訓練出更精確的量化表示。

<figure><img src="https://3215535692-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FxhOjnexMCB3dmuQFQ2Zq%2Fuploads%2FeFX8a2xVMhOqECznE0mR%2Fqat_diagram.png?alt=media&#x26;token=ee740048-7d2a-47fe-a8e6-d080e4fb57c1" alt=""><figcaption></figcaption></figure>

### :sparkles:QAT + LoRA 微調

Unsloth 中的 QAT 還可以與 LoRA 微調結合，以實現兩全其美的好處：在訓練期間顯著降低儲存和計算需求，同時減輕量化損失！我們透過 `qat_scheme` 支援多種方法，包括 `fp8-int4`、`fp8-fp8`、`int8-int4`、`int4`。我們還計劃在後續版本中加入 QAT 的自訂定義！

{% code overflow="wrap" %}

### :teapot:匯出 QAT 模型

在 Unsloth 中完成微調後，您可以呼叫 `model.save_pretrained_torchao` 以使用 TorchAO 的 PTQ 格式儲存您訓練好的模型。您也可以將這些模型上傳到 HuggingFace hub！我們支援任何配置，並計劃開發基於文字的方法，使過程對每個人都更簡單！但首先，我們必須透過以下方式準備用於最終轉換步驟的 QAT 模型：

{% code overflow="wrap" %}

現在我們可以選擇您想要的 QAT 風格：

{% code overflow="wrap" %}

**範例：**

範例 1 (python):
```python
from unsloth import FastLanguageModel
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name = "unsloth/Qwen3-4B-Instruct-2507",
    max_seq_length = 2048,
    load_in_16bit = True,
)
model = FastLanguageModel.get_peft_model(
    model,
    r = 16,
    target_modules = ["q_proj", "k_proj", "v_proj", "o_proj",
                      "gate_proj", "up_proj", "down_proj",],
    lora_alpha = 32,
    
    # 我們支援 fp8-int4, fp8-fp8, int8-int4, int4
    qat_scheme = "int4",
)
```

範例 2 (python):
```python
from torchao.quantization import quantize_
from torchao.quantization.qat import QATConfig
quantize_(model, QATConfig(step = "convert"))
```

---

## Qwen3-2507

**URL:** llms-txt#qwen3-2507

**目錄：**
- ⚙️最佳實踐
- 📖 執行 Qwen3-30B-A3B-2507 教學
  - Instruct: Qwen3-30B-A3B-Instruct-2507

在您的設備上本地執行 Qwen3-30B-A3B-2507 和 235B-A22B 的 Thinking 和 Instruct 版本！

Qwen 發佈了 2507（2025 年 7 月）更新，針對其 [Qwen3](https://docs.unsloth.ai/models/qwen3-how-to-run-and-fine-tune) 4B、30B 和 235B 模型，引入了「Thinking」和「Non-Thinking」變體。非思考型的 '**Qwen3-30B-A3B-Instruct-2507**' 和 '**Qwen3-235B-A22B-Instruct-2507'** 具有 256K 上下文視窗、改進的指令遵循能力、多語言能力和對齊。

思考型模型 '**Qwen3-30B-A3B-Thinking-2507**' 和 '**Qwen3-235B-A22B-Thinking-2507**' 擅長推理，其中 235B 在邏輯、數學、科學、程式編寫和進階學術任務中取得了頂尖 (SOTA) 結果。

[Unsloth](https://github.com/unslothai/unsloth) 現在也支援 Qwen3-2507 模型的微調和 [強化學習 (RL)](https://docs.unsloth.ai/get-started/reinforcement-learning-rl-guide) — 速度快 2 倍，節省 70% 的 VRAM，且上下文長度增加 8 倍。

<a href="#run-qwen3-30b-a3b-2507-tutorials" class="button secondary">執行 30B-A3B</a><a href="#run-qwen3-235b-a22b-thinking-2507" class="button secondary">執行 235B-A22B</a><a href="#fine-tuning-qwen3-2507-with-unsloth" class="button secondary">微調 Qwen3-2507</a>

**Unsloth** [**Dynamic 2.0**](https://docs.unsloth.ai/basics/unsloth-dynamic-2.0-ggufs) **GGUFs:**

| 模型 | GGUF (可執行): |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Qwen3-**4B-2507** | [Instruct](https://huggingface.co/unsloth/Qwen3-4B-Instruct-2507-GGUF) • [Thinking ](https://huggingface.co/unsloth/Qwen3-4B-Thinking-2507-GGUF) |
| Qwen3-**30B-A3B**-2507 | [Instruct](#llama.cpp-run-qwen3-30b-a3b-instruct-2507-tutorial) • [Thinking](https://huggingface.co/unsloth/Qwen3-30B-A3B-Thinking-2507-GGUF) |
| Qwen3-**235B-A22B**-2507 | [Instruct](https://huggingface.co/unsloth/Qwen3-235B-A22B-Instruct-2507-GGUF) • [Thinking](https://huggingface.co/unsloth/Qwen3-235B-A22B-Thinking-2507-GGUF) |

{% hint style="success" %}
Thinking 和 Instruct 模型的設定不同。\
Thinking 模型使用 temperature = 0.6，但 Instruct 模型使用 temperature = 0.7\
Thinking 模型使用 top\_p = 0.95，但 Instruct 模型使用 top\_p = 0.8
{% endhint %}

為了獲得最佳效能，Qwen 建議以下設定：

| Instruct 模型設定: | Thinking 模型設定: |
| ------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| <mark style="background-color:blue;">`Temperature = 0.7`</mark> | <mark style="background-color:blue;">`Temperature = 0.6`</mark> |
| `Min_P = 0.00` (llama.cpp 預設為 0.1) | `Min_P = 0.00` (llama.cpp 預設為 0.1) |
| `Top_P = 0.80` | `Top_P = 0.95` |
| `TopK = 20` | `TopK = 20` |
| `presence_penalty = 0.0 to 2.0`（llama.cpp 預設為關閉，但為了減少重複，您可以使用它） | `presence_penalty = 0.0 to 2.0`（llama.cpp 預設為關閉，但為了減少重複，您可以使用它） |

**充足的輸出長度**：對於大多數查詢，使用 `32,768` token 的輸出長度，這對大多數查詢來說是足夠的。

Thinking（思考型具有 `<think></think>`）和 Instruct 的對話模板如下：

## 📖 執行 Qwen3-30B-A3B-2507 教學

以下是模型 [Thinking](#thinking-qwen3-30b-a3b-thinking-2507) 和 [Instruct](#instruct-qwen3-30b-a3b-instruct-2507) 版本的指南。

### Instruct: Qwen3-30B-A3B-Instruct-2507

鑑於這是一個 non-thinking 模型，不需要設定 `thinking=False`，模型也不會產生 `<think> </think>` 區塊。

#### ⚙️最佳實踐

為了獲得最佳效能，Qwen 建議以下設定：

* &#x20;我們建議使用 `temperature=0.7, top_p=0.8, top_k=20, and min_p=0.0`。如果框架支援，`presence_penalty` 設在 0 到 2 之間，以減少無止盡的重複。
* <mark style="background-color:$success;">**`temperature = 0.7`**</mark>
* `top_k = 20`
* `min_p = 0.00` (llama.cpp 預設為 0.1)
* **`top_p = 0.80`**
* `presence_penalty = 0.0 to 2.0`（llama.cpp 預設為關閉，但為了減少重複，您可以使用它）例如嘗試 1.0。
* 原生支援高達 `262,144` 的上下文，但您可以將其設定為 `32,768` token 以減少 RAM 使用

#### 🦙 Ollama: 執行 Qwen3-30B-A3B-Instruct-2507 教學

1. 如果您尚未安裝，請安裝 `ollama`！您只能執行大小高達 32B 的模型。

2. 執行模型！注意，如果失敗，您可以在另一個終端機呼叫 `ollama serve`！我們在 Hugging Face 上傳的 `params` 中包含了所有修復和建議參數（temperature 等）！

#### :sparkles: Llama.cpp: 執行 Qwen3-30B-A3B-Instruct-2507 教學

1. 在 [GitHub 這裡](https://github.com/ggml-org/llama.cpp) 取得最新的 `llama.cpp`。您也可以按照下方的構建說明操作。如果您沒有 GPU 或只想進行 CPU 推理，請將 `-DGGML_CUDA=ON` 更改為 `-DGGML_CUDA=OFF`。

2. 您可以直接從 HuggingFace 提取：

3. 透過（在安裝 `pip install huggingface_hub hf_transfer` 之後）下載模型。您可以選擇 UD\_Q4\_K\_XL 或其他量化版本。

**範例：**

範例 1 (未知):
```unknown
<|im_start|>user
Hey there!<|im_end|>
<|im_start|>assistant
What is 1+1?<|im_end|>
<|im_start|>user
2<|im_end|>
<|im_start|>assistant
```

範例 2 (bash):
```bash
apt-get update
apt-get install pciutils -y
curl -fsSL https://ollama.com/install.sh | sh
```

範例 3 (bash):
```bash
ollama run hf.co/unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF:UD-Q4_K_XL
```

範例 4 (bash):
```bash
apt-get update
apt-get install pciutils build-essential cmake curl libcurl4-openssl-dev -y
git clone https://github.com/ggml-org/llama.cpp
cmake llama.cpp -B llama.cpp/build \
    -DBUILD_SHARED_LIBS=OFF -DGGML_CUDA=ON -DLLAMA_CURL=ON
cmake --build llama.cpp/build --config Release -j --clean-first --target llama-quantize llama-cli llama-gguf-split
cp llama.cpp/build/bin/llama-* llama.cpp
```

---

## 常數 (Constants):

**URL:** llms-txt#constants:

WIDTH, HEIGHT =456 ,702   #
BACKGROUND_COLOR_LIGHTS=['lightskyblue']
GAP_SIZE=189           #

BIRD_RADIUS=3.  
PIPE_SPEED=- ( )    ? 
class Game():
def __init__(self):
        self.screen_size=( )

def reset_game_vars():
    global current_scor e
   # 設定為零和其地初始狀態。

---

## tokenizer.push_to_hub("your_name/lora_model", token = "...") # 線上儲存

**URL:** llms-txt#tokenizer.push_to_hub("your_name/lora_model",-token-=-"...")-#-online-saving

**目錄：**
  - 微調語音模型 vs. 零樣本 (Zero-shot) 語音複製

這會儲存模型權重（對於 LoRA，如果基礎模型未完全微調，它可能僅儲存 adapter 權重）。如果您在 CLI 中使用了 `--push_model` 或使用了 `trainer.push_to_hub()`，您可以直接上傳到 Hugging Face Hub。

現在您應該在目錄中有一個微調後的 TTS 模型。下一步是進行測試，如果支援，您可以使用 llama.cpp 將其轉換為 GGUF 檔案。

### 微調語音模型 vs. 零樣本 (Zero-shot) 語音複製

人們說使用 XTTS 等模型只需 30 秒的音訊即可複製聲音 - 不需要訓練。這在技術上是正確的，但這忽略了重點。

零樣本語音複製（Orpheus 和 CSM 等模型也提供此功能）是一種近似值。它捕捉了說話者聲音的總體 **音調和音色**，但無法重現完整的表現力範圍。您會丟失說話速度、措辭、聲音怪癖和韻律細微差別等細節 - 這些是賦予聲音 **個性和獨特性** 的要素。

如果您只想要一個不同的聲音並且對相同的交付模式沒問題，那麼零樣本通常就足夠了。但語音仍將遵循 **模型的風格**，而不是說話者的風格。

對於任何更具個性化或表現力的需求，您需要使用 LoRA 等方法進行訓練，以真實捕捉某人的說話方式。

---

## 在 docker run 中使用公鑰

**URL:** llms-txt#use-the-public-key-in-docker-run

-e "SSH_KEY=$(cat ~/.ssh/container_key.pub)"

---

## 設定 CUDA 環境變數

**URL:** llms-txt#set-cuda-environment-variables

ENV CUDA_HOME=/usr/local/cuda-13.0/
ENV CUDA_PATH=$CUDA_HOME
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
ENV C_INCLUDE_PATH=$CUDA_HOME/include:$C_INCLUDE_PATH
ENV CPLUS_INCLUDE_PATH=$CUDA_HOME/include:$CPLUS_INCLUDE_PATH

---

## 產生 SSH 金鑰對

**URL:** llms-txt#generate-ssh-key-pair

ssh-keygen -t rsa -b 4096 -f ~/.ssh/container_key

---

## LoRA 熱插拔 (Hot Swapping) 指南

**URL:** llms-txt#lora-hot-swapping-guide

**目錄：**
  - :shaved\_ice: vLLM LoRA 熱插拔 / 動態 LoRA

### :shaved\_ice: vLLM LoRA 熱插拔 / 動態 LoRA

要啟用一次最多 4 個 LoRA 的服務（這些 LoRA 可以熱插拔/更改），請先設定環境變數旗標以允許熱插拔：

接著，以 LoRA 支援啟動服務：

要動態載入 LoRA（同時設定 lora 名稱），請執行：

要從池中移除它：

**範例：**

範例 1 (bash):
```bash
export VLLM_ALLOW_RUNTIME_LORA_UPDATING=True
```

範例 2 (bash):
```bash
export VLLM_ALLOW_RUNTIME_LORA_UPDATING=True
vllm serve unsloth/Llama-3.3-70B-Instruct \
    --quantization fp8 \
    --kv-cache-dtype fp8
    --gpu-memory-utilization 0.97 \
    --max-model-len 65536 \
    --enable-lora \
    --max-loras 4 \
    --max-lora-rank 64
```

範例 3 (bash):
```bash
curl -X POST http://localhost:8000/v1/load_lora_adapter \
    -H "Content-Type: application/json" \
    -d '{
        "lora_name": "LORA_NAME",
        "lora_path": "/path/to/LORA"
    }'
```

範例 4 (bash):
```bash
curl -X POST http://localhost:8000/v1/unload_lora_adapter \
    -H "Content-Type: application/json" \
    -d '{
        "lora_name": "LORA_NAME"
    }'
```

---

## 我應該使用哪個模型？

**URL:** llms-txt#what-model-should-i-use?

**目錄：**
- Llama, Qwen, Mistral, Phi or?
- 指令型 (Instruct) 或基礎 (Base) 模型？
  - 指令型模型 (Instruct Models)
  - **基礎模型 (Base Models)**
  - 我應該選擇指令型還是基礎型？
- 使用 Unsloth 微調模型
  - 實驗是關鍵

## Llama, Qwen, Mistral, Phi or?

在準備微調時，您面臨的首要決定之一就是選擇合適的模型。以下是協助您選擇的逐步指南：

{% stepper %}
{% step %}

#### 選擇一個符合您使用案例的模型

* 例如：對於基於影像的訓練，選取視覺模型如 *Llama 3.2 Vision*。對於程式碼資料集，選擇專門的模型如 *Qwen Coder 2.5*。
* **授權與需求**：不同的模型可能具有特定的授權條款和 [系統需求](https://docs.unsloth.ai/beginner-start-here/unsloth-requirements#system-requirements)。請務必仔細審閱這些內容，以避免相容性問題。
  {% endstep %}

#### **評估您的儲存空間、運算能力和資料集**

* 使用我們的 [VRAM 指南](https://docs.unsloth.ai/beginner-start-here/unsloth-requirements#approximate-vram-requirements-based-on-model-parameters) 來確定您正在考慮的模型的 VRAM 需求。
* 您的資料集將反映您將使用的模型類型以及訓練所需的時間。
  {% endstep %}

#### **選擇模型和參數**

* 我們建議使用最新模型以獲得最佳效能和功能。例如，截至 2025 年 1 月，領先的 70B 模型是 *Llama 3.3*。
* 您可以透過探索我們的 [模型目錄](https://docs.unsloth.ai/get-started/all-our-models) 來隨時瞭解最新且相關的選項。
  {% endstep %}

#### **在基礎模型和指令型模型之間進行選擇**

更多詳細資訊如下：
{% endstep %}
{% endstepper %}

## 指令型 (Instruct) 或基礎 (Base) 模型？

在準備微調時，首要面臨的決定之一是使用指令型模型 (instruct model) 還是基礎模型 (base model)。

### 指令型模型 (Instruct Models)

指令型模型已預先訓練好內建指令，無需任何微調即可使用。這些模型（包括 GGUF 和其他常用模型）針對直接使用進行了優化，並且開箱即用，能有效回應提示語。指令型模型支援 ChatML 或 ShareGPT 等對話聊天模板。

### **基礎模型 (Base Models)**

另一方面，基礎模型是未經指令微調的原始預訓練版本。這些模型專為透過微調進行自訂而設計，讓您可以根據獨特需求進行調整。基礎模型相容於 [Alpaca 或 Vicuna](https://docs.unsloth.ai/basics/chat-templates) 等指令式模板，但它們通常不直接支援開箱即用的對話聊天模板。

### 我應該選擇指令型還是基礎型？

決定通常取決於資料的數量、品質和類型：

* **1,000 筆以上的資料**：如果您擁有超過 1,000 筆資料的大型資料集，通常最好微調基礎模型。
* **300–1,000 筆高品質資料**：對於中等規模的高品質資料集，微調基礎模型或指令型模型都是可行的選擇。
* **少於 300 筆資料**：對於較小的資料集，通常指令型模型是更好的選擇。微調指令型模型可以使其符合特定需求，同時保留其內建的指令能力。這確保了除非您打算大幅更改其功能，否則它可以在沒有額外輸入的情況下遵循一般指令。
* 有關資料集應有多大的資訊，[請見此處](https://docs.unsloth.ai/get-started/datasets-guide#how-big-should-my-dataset-be)。

## 使用 Unsloth 微調模型

您可以透過與 Hugging Face 上的模型名稱（例如 'unsloth/llama-3.1-8b-unsloth-bnb-4bit'）匹配來將模型名稱更改為您喜歡的任何模型。

我們建議從 **指令型模型 (Instruct models)** 開始，因為它們允許使用對話式聊天模板（ChatML、ShareGPT 等）進行直接微調，並且與 **基礎模型 (Base models)**（使用 Alpaca、Vicuna 等）相比所需的資料更少。在[此處瞭解更多關於指令型和基礎模型之間的區別](#instruct-or-base-model)。

* 以 **`unsloth-bnb-4bit`** 結尾的模型名稱表示它們是 [**Unsloth 動態 4-bit**](https://unsloth.ai/blog/dynamic-4bit) **量化**。這些模型消耗的 VRAM 比標準 BitsAndBytes 4-bit 模型略多，但精確度顯著提高。
* 如果模型名稱僅以 **`bnb-4bit`** 結尾（沒有 "unsloth"），則它是指標準的 BitsAndBytes 4-bit 量化。
* **不帶後綴** 的模型是其原始的 **16-bit 或 8-bit 格式**。雖然它們是來自官方模型建立者的原始模型，但我們有時會包含重要的修復 - 例如聊天模板或分詞器 (tokenizer) 修復。因此建議在使用時優先選擇我們的版本。

### 實驗是關鍵

{% hint style="info" %}
我們建議盡可能對兩種模型都進行實驗。對每一種模型進行微調並評估輸出，看看哪一種更符合您的目標。
{% endhint %}

---

## 安裝 unsloth 和其他依賴項

**URL:** llms-txt#install-unsloth-and-other-dependencies

```bash
RUN pip install unsloth unsloth_zoo bitsandbytes==0.48.0 transformers==4.56.2 trl==0.22.2
```

---

## 教學：如何微調與執行 LLM

**URL:** llms-txt#tutorials:-how-to-fine-tune-&-run-llms

學習如何使用 Unsloth 100% 在本地執行和微調模型以獲得最佳效能。

<table data-view="cards"><thead><tr><th></th><th data-hidden data-card-cover data-type="image">封面影像</th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><a href="../new/deepseek-ocr-how-to-run-and-fine-tune">DeepSeek-OCR</a></td><td><a href="https://3215535692-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FxhOjnexMCB3dmuQFQ2Zq%2Fuploads%2FP6V5vkGfGPBdRlkpB35Q%2Fdeepseek%20ocr%20logo.png?alt=media&#x26;token=43a73901-37a9-4cb9-a25c-fa01cf03baea">deepseek ocr logo.png</a></td><td><a href="../new/deepseek-ocr-how-to-run-and-fine-tune">deepseek-ocr-how-to-run-and-fine-tune</a></td></tr><tr><td><a href="qwen3-vl-how-to-run-and-fine-tune">Qwen3-VL</a></td><td><a href="https://3215535692-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FxhOjnexMCB3dmuQFQ2Zq%2Fuploads%2FXrFygtnLnqHhVmEIidg3%2Fqwen3-vl%20promo.png?alt=media&#x26;token=82f58481-4e0c-4977-af26-2ea08a227ad2">qwen3-vl promo.png</a></td><td><a href="qwen3-vl-how-to-run-and-fine-tune">qwen3-vl-how-to-run-and-fine-tune</a></td></tr><tr><td><a href="../new/vision-reinforcement-learning-vlm-rl">視覺強化學習</a></td><td><a href="https://3215535692-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FxhOjnexMCB3dmuQFQ2Zq%2Fuploads%2FPOHnYqLRCh4d9TvBRNlY%2Fvision%20rl%20site.png?alt=media&#x26;token=26f859e5-53e5-444b-bf90-7f1901a9058a">vision rl site.png</a></td><td><a href="../new/vision-reinforcement-learning-vlm-rl">vision-reinforcement-learning-vlm-rl</a></td></tr><tr><td><a href="deepseek-v3.1-how-to-run-locally">DeepSeek-V3.1</a> Terminus</td><td><a href="https://3215535692-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FxhOjnexMCB3dmuQFQ2Zq%2Fuploads%2FOFWy2bZ6L6qr12m9fbEM%2Fdeepseek%20v3.1%20logo.png?alt=media&#x26;token=dd75f159-9266-4208-995f-b71d8e2ed4d3">deepseek v3.1 logo.png</a></td><td><a href="deepseek-v3.1-how-to-run-locally">deepseek-v3.1-how-to-run-locally</a></td></tr></tbody></table>

---

## 建立模型實例

**URL:** llms-txt#create-model-instance

```python
llm = LLM(
    model="unsloth/DeepSeek-OCR",
    enable_prefix_caching=False,
    mm_processor_cache_gb=0,
    logits_processors=[NGramPerReqLogitsProcessor]
)
```

---

## (3) 加入評估迴圈 / OOM

**URL:** llms-txt#(3)-adding-an-evaluation-loop-/-ooms

---

## 使用 Unsloth 進行多 GPU 訓練

**URL:** llms-txt#multi-gpu-training-with-unsloth

學習如何使用 Unsloth 在多個 GPU 上進行 LLM 微調和並行處理。

Unsloth 目前透過 Accelerate 和 DeepSpeed 等函式庫支援多 GPU 設定。這意味著您已經可以在 Unsloth 中利用 **FSDP** 和 **DDP** 等並行方法。

* 您可以使用我們的 [Magistral-2509 Kaggle notebook](https://docs.unsloth.ai/models/tutorials-how-to-fine-tune-and-run-llms/magistral-how-to-run-and-fine-tune#fine-tuning-magistral-with-unsloth) 作為範例，它利用多 GPU Unsloth 來適配 24B 參數模型。

然而，我們知道這個過程可能很複雜且需要手動設定。我們正在努力讓多 GPU 支援變得更簡單、更人性化，我們很快就會宣佈 Unsloth 的官方多 GPU 支援。

**在此期間**，要為 DDP 啟用多 GPU，請執行以下操作：

1. 將您的訓練指令碼儲存為 `train.py`，並在 `SFTConfig` 或 `TrainingArguments` 中將旗標 `ddp_find_unused_parameters = False`
2. 執行 `accelerate launch train.py` 或 `torchrun --nproc_per_node N_GPUS -m train.py`，其中 N\_GPUS 是您擁有的 GPU 數量。

**流水線 (Pipeline) / 模型切分載入** 也是允許的，所以如果您沒有足夠的 VRAM 讓 1 個 GPU 載入例如 Llama 70B，不用擔心 - 我們會為您在每個 GPU 上切分模型！要啟用此功能，請使用 `device_map = "balanced"` 旗標：

此外，多位貢獻者建立了倉庫來啟用或改進 Unsloth 的多 GPU 支援，包括：

* [unsloth-5090-multiple](https://github.com/thad0ctor/unsloth-5090-multiple): 一個讓 Unsloth 在多 GPU 系統上高效執行的分支，特別是針對 NVIDIA [RTX 5090](https://docs.unsloth.ai/basics/fine-tuning-llms-with-blackwell-rtx-50-series-and-unsloth) 和類似設定。
* [opensloth](https://github.com/anhvth/opensloth): 具有多 GPU 訓練支援（包括實驗性功能）的 Unsloth。

**請隨時關注我們的官方公告！**\
有關更多詳細資訊，請查看我們討論多 GPU 支援的現有 [Pull Request](https://github.com/unslothai/unsloth/issues/2435)。

**範例：**

範例 1 (python):
```python
from unsloth import FastLanguageModel
model, tokenizer = FastLanguageModel.from_pretrained(
    "unsloth/Llama-3.3-70B-Instruct",
    load_in_4bit = True,
    device_map = "balanced",
)
```

---

## (4) 自訂對話模板

**URL:** llms-txt#(4)-customized-chat-templates

---

## 初學者？從這裡開始！

**URL:** llms-txt#beginner?-start-here!

如果您是初學者，在您進行第一次微調之前，這裡可能是您會問的第一批問題。您也可以隨時加入我們的 [Reddit 頁面](https://www.reddit.com/r/unsloth/) 諮詢我們的社群。

<table data-view="cards"><thead><tr><th data-type="content-ref"></th><th></th><th></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td><a href="fine-tuning-llms-guide">fine-tuning-llms-guide</a></td><td>如何微調的逐步指南！</td><td>學習訓練的核心基礎。</td><td><a href="fine-tuning-llms-guide">fine-tuning-llms-guide</a></td></tr><tr><td><a href="fine-tuning-llms-guide/what-model-should-i-use">what-model-should-i-use</a></td><td>指令型還是基礎模型？</td><td>我的資料集應該有多大？</td><td><a href="fine-tuning-llms-guide/what-model-should-i-use">what-model-should-i-use</a></td></tr><tr><td><a href="../models/tutorials-how-to-fine-tune-and-run-llms">tutorials-how-to-fine-tune-and-run-llms</a></td><td>如何執行與微調 DeepSeek？</td><td>執行 Gemma 3 時應該設定哪些設定？</td><td><a href="../models/tutorials-how-to-fine-tune-and-run-llms">tutorials-how-to-fine-tune-and-run-llms</a></td></tr><tr><td><a href="beginner-start-here/faq-+-is-fine-tuning-right-for-me">faq-+-is-fine-tuning-right-for-me</a></td><td>微調能為我做什麼？</td><td>RAG vs. 微調？</td><td><a href="beginner-start-here/faq-+-is-fine-tuning-right-for-me">faq-+-is-fine-tuning-right-for-me</a></td></tr><tr><td><a href="install-and-update">install-and-update</a></td><td>如何在本地安裝 Unsloth？</td><td>如何更新 Unsloth？</td><td><a href="install-and-update">install-and-update</a></td></tr><tr><td><a href="fine-tuning-llms-guide/datasets-guide">datasets-guide</a></td><td>我該如何建構/準備我的資料集？</td><td>我該如何收集資料？</td><td></td></tr><tr><td><a href="beginner-start-here/unsloth-requirements">unsloth-requirements</a></td><td>Unsloth 可以在我的 GPU 上執行嗎？</td><td>我需要多少 VRAM？</td><td><a href="beginner-start-here/unsloth-requirements">unsloth-requirements</a></td></tr><tr><td><a href="../basics/running-and-saving-models">running-and-saving-models</a></td><td>如何儲存為 GGUF？</td><td>如何儲存以供 vLLM 使用？</td><td><a href="../basics/running-and-saving-models">running-and-saving-models</a></td></tr></tbody></table>

<figure><img src="https://3215535692-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FxhOjnexMCB3dmuQFQ2Zq%2Fuploads%2FjT759hR4zq8ygzg1oEwI%2FLarge%20sloth%20Question%20mark.png?alt=media&#x26;token=ca8d2f56-889a-4da8-8106-da88d22e69d2" alt="" width="188"><figcaption></figcaption></figure>

---

## 在 v0.11.1 版本發佈之前，您需要從 nightly build 安裝 vLLM

**URL:** llms-txt#until-v0.11.1-release,-you-need-to-install-vllm-from-nightly-build

```bash
uv pip install -U vllm --pre --extra-index-url https://wheels.vllm.ai/nightly
```
```python
from vllm import LLM, SamplingParams
from vllm.model_executor.models.deepseek_ocr import NGramPerReqLogitsProcessor
from PIL import Image
```

**範例：**

範例 1 (未知):
```unknown
2. 接著執行以下程式碼：

{% code overflow="wrap" %}
```

---

## 從最後一個檢查點開始微調

**URL:** llms-txt#finetuning-from-last-checkpoint

**目錄：**
  - Wandb 整合

檢查點 (Checkpointing) 允許您儲存微調進度，以便您可以暫停然後繼續。

您必須先編輯 `Trainer` 以加入 `save_strategy` 和 `save_steps`。以下每 50 個步驟將檢查點儲存到資料夾 `outputs`。

接著在 trainer 中執行：

這將從最新的檢查點開始並繼續訓練。

### Wandb 整合

**範例：**

範例 1 (python):
```python
trainer = SFTTrainer(
    ....
    args = TrainingArguments(
        ....
        output_dir = "outputs",
        save_strategy = "steps",
        save_steps = 50,
    ),
)
```

範例 2 (python):
```python
trainer_stats = trainer.train(resume_from_checkpoint = True)
```

---

## import os # 選填，用於加速下載

**URL:** llms-txt#import-os-#-optional-for-faster-downloading

---

## Unsloth 推理

**URL:** llms-txt#unsloth-inference

學習如何使用 Unsloth 的快速推理執行微調後的模型。

Unsloth 原生支援 2 倍速推理。關於我們的純推理 notebook，請點選 [此處](https://colab.research.google.com/drive/1aqlNQi7MMJbynFDyOQteD2t0yVfjb9Zh?usp=sharing)。

所有 QLoRA、LoRA 和非 LoRA 推理路徑都快 2 倍。這不需要更改程式碼或任何新的依賴項。

<pre class="language-python"><code class="lang-python"><strong>from unsloth import FastLanguageModel
</strong>model, tokenizer = FastLanguageModel.from_pretrained(
    model_name = "lora_model", # 您用於訓練的模型
    max_seq_length = max_seq_length,
    dtype = dtype,
    load_in_4bit = load_in_4bit,
)
FastLanguageModel.for_inference(model) # 啟用原生 2x 快速推理
text_streamer = TextStreamer(tokenizer)
_ = model.generate(**inputs, streamer = text_streamer, max_new_tokens = 64)
</code></pre>

#### NotImplementedError: 需要 UTF-8 區域設定 (locale)。取得的是 ANSI

有時執行儲存格時會出現[此錯誤](https://github.com/googlecolab/colabtools/issues/3409)。要解決此問題，請在新的儲存格中執行以下操作：

**範例：**

範例 1 (python):
```python
import locale
locale.getpreferredencoding = lambda: "UTF-8"
```

---

## DeepSeek-R1: 如何在本地執行

**URL:** llms-txt#deepseek-r1:-how-to-run-locally

**目錄：**
- 使用 llama.cpp (建議)

關於如何使用 llama.cpp 執行我們為 DeepSeek-R1 提供的 1.58-bit 動態量化的指南。

{% hint style="success" %}
請參閱 <https://docs.unsloth.ai/basics/deepseek-r1-0528-how-to-run-locally> 以獲取更新的 DeepSeek R1-0528 (2025 年 5 月 28 日版本)
{% endhint %}

## 使用 llama.cpp (建議)

1. 不要忘記 `<｜User｜>` 和 `<｜Assistant｜>` token！ - 或使用對話模板格式化工具
2. 在 [github.com/ggerganov/llama.cpp](https://github.com/ggerganov/llama.cpp) 取得最新的 `llama.cpp`。您也可以按照下方的構建說明操作：

3. 最好使用 `--min-p 0.05` 來抵消極其罕見的 token 預測 - 我發現這對 1.58bit 模型特別有效。
4. 透過以下方式下載模型：

**範例：**

範例 1 (bash):
```bash
apt-get update
apt-get install pciutils build-essential cmake curl libcurl4-openssl-dev -y
git clone https://github.com/ggerganov/llama.cpp
cmake llama.cpp -B llama.cpp/build \
    -DBUILD_SHARED_LIBS=ON -DGGML_CUDA=ON -DLLAMA_CURL=ON
cmake --build llama.cpp/build --config Release -j --clean-first --target llama-quantize llama-cli llama-gguf-split
cp llama.cpp/build/bin/llama-* llama.cpp
```

---

## 記憶體效率高的 RL

**URL:** llms-txt#memory-efficient-rl

**目錄：**
- :sparkles:如何啟用優化
- :mortar\_board:不再需要 `gpu_memory_utilization`！
- :interrobang:為什麼 RL 使用這麼多記憶體？
- 🦥Unsloth Standby
- :test_tube:效能實驗
  - H100 實驗
  - 先前的 A100 40GB 實驗
- :tada:其他優化
- :books:GRPO Notebooks

我們很高興在 Unsloth 中引入更高效的強化學習 (RL)，並帶來多項算法進步：

* **上下文長度增加 1.2 到 1.7 倍**，且不降速也不增加額外記憶體使用！
* **RL 訓練執行速度提升 10%**，歸功於改進的內核 (kernels) 和非同步資料移動
* 模型載入期間 **`torch.compile` 時間縮短 2 倍**

與所有使用 FA2 的其他設定相比，Unsloth **已經** 提高了 RL 訓練速度、上下文視窗並減少了 50-90% 的 VRAM 使用，但現在 [**Unsloth 的 Standby**](#unsloth-standby) 進一步改進了這一點。與其他實作相比，我們的 Standby 功能獨特地限制了速度下降，有時甚至使訓練更快！

現在，Qwen3-32B LoRA 16-bit 在單張 H100 80GB GPU 上可以達到 6,144 的上下文長度，而之前為 3,600 (**增加 1.7 倍**)。Llama-3.1-8B QLoRA 4bit 可以達到 47,500 的長度，而之前為 42,000 (增加 1.13 倍)。

我們透過各種內核優化使 RL 執行速度提高了 10%，並在從訓練模式切換到推理模式時移除了 CPU 和 GPU 之間的 LoRA 通訊通道。最後，我們使用了自訂的 `torch.compile` 旗標使 vLLM 的 rollout 速度提高了 10%，並將編譯時間縮短了 2 倍。

## :sparkles:如何啟用優化

要啟用 **Unsloth 的 Standby** 功能，請在任何 Unsloth 匯入之前設定環境變數 `UNSLOTH_VLLM_STANDBY`。接著設定 `gpu_memory_utilization = 0.95` 即可！

## :mortar\_board:不再需要 `gpu_memory_utilization`！

憑藉 Unsloth 新的 RL 改進，您再也不用擔心調整或設定 `gpu_memory_utilization` - 只需將其設定為 GPU 使用率的 90% 或 95% 即可 - 遺憾的是 100% 行不通，因為小張量（tensors）需要一些空間。以前必須在 30% 到 95% 之間進行調整 - 現在不用了！將其設定為最大值，Unsloth 將處理其餘部分！

## :interrobang:為什麼 RL 使用這麼多記憶體？

GRPO（以及許多 RL 變體）嚴重依賴主要由 vLLM 驅動的生成（generation）。但這代價高昂，因為它需要持續的 **GPU 記憶體來存放權重、激活值 (activations) 和 KV 快取**。

{% columns %}
{% column width="41.66666666666667%" %}
推理佔用大量 VRAM

<figure><img src="https://3215535692-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FxhOjnexMCB3dmuQFQ2Zq%2Fuploads%2FumvGGfls63zqeYBEDc6b%2Fimage.png?alt=media&#x26;token=a0c7488c-cf08-4b82-a3fd-fb66683e1cc7" alt=""><figcaption></figcaption></figure>
{% endcolumn %}

{% column width="58.33333333333333%" %}
而訓練同樣使用 VRAM！

<figure><img src="https://3215535692-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FxhOjnexMCB3dmuQFQ2Zq%2Fuploads%2FfP3mRsZNQLzXRJ9aV8au%2Ffig6-2.avif?alt=media&#x26;token=66d9fc0a-dbc6-4961-b483-d7b3da298e0c" alt=""><figcaption></figcaption></figure>
{% endcolumn %}
{% endcolumns %}

這意味著 RL 需要同時在 GPU 上保留 2 套 VRAM/記憶體：

1. 推理引擎（包含模型權重、KV 快取）
2. 訓練引擎（包含模型權重、激活值、梯度、優化器狀態）

目前的 RL 框架必須為 80GB GPU 進行 50/50 分割，50% 用於推理，50% 用於訓練。而將權重從訓練模式移至推理模式可能需要相當長的時間。

<table><thead><tr><th width="251.51666259765625">80GB GPU</th><th>推理引擎 (50%)</th><th>訓練引擎 (50%)</th></tr></thead><tbody><tr><td>模型權重</td><td>16GB</td><td>16GB</td></tr><tr><td>KV 快取</td><td>24GB</td><td></td></tr><tr><td>激活值、梯度、優化器狀態</td><td></td><td>24GB</td></tr></tbody></table>

之前的 Unsloth 版本已經巧妙地優化了上述內容，因為我們 **直接共享 vLLM 的權重空間，從而移除了模型權重的雙重記憶體使用**。這釋放了例如 16GB 的空間，可以用於增加上下文長度或提高生成速度。此外，我們不需要進行記憶體移動，這使得訓練更快。

| 80GB GPU                                 | 推理引擎 (50%)                                               | 訓練引擎 (50%)                                               |
| ---------------------------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------- |
| 模型權重                            | <mark style="background-color:$success;">**16GB 共享**</mark>      | <mark style="background-color:$success;">**<<< 共享**</mark>      |
| KV 快取                                 | 24GB + 8GB= <mark style="background-color:$success;">**32GB**</mark> |                                                                     |
| 激活值、梯度、優化器狀態 |                                                                      | 24GB + 8GB=<mark style="background-color:$success;">**32GB**</mark> |

但我們可以更進一步 - 我們首先注意到 RL 執行推理、然後訓練、然後推理、然後訓練等。

<figure><img src="https://3215535692-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FxhOjnexMCB3dmuQFQ2Zq%2Fuploads%2F0gTALcg01JbV9A9BVWxz%2F5b957843-eb58-4778-8b90-f25767c51495.png?alt=media&#x26;token=a502e83a-3179-4f5b-97c3-4daa7890affd" alt=""><figcaption></figcaption></figure>

這意味著推理和訓練的記憶體空間理論上可以重複使用，因為推理和訓練是獨立的模式 - 這就是 [vLLM 的睡眠模式 (sleep mode) 功能](https://docs.vllm.ai/en/latest/features/sleep_mode.html#rlhf-weight-updates) 發揮作用的地方，它有 2 個選項：

1. `level = 1` 將權重複製到 CPU 並刪除 KV 快取
2. `level = 2` 刪除權重並刪除 KV 快取

但提醒一下，在 Unsloth 中我們共享 vLLM 的權重記憶體空間 - 這意味著 we 需一種新方法來刪除 KV 快取，並忽略權重的刪除，我們稱之為 Unsloth Standby。

| 80GB GPU                                                                                                                                                            | 推理引擎                                                | 訓練引擎                                                |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- | -------------------------------------------------------------- |
| 模型權重                                                                                                                                                       | <mark style="background-color:$success;">**16GB 共享**</mark> | <mark style="background-color:$success;">**<<< 共享**</mark> |
| <p><mark style="background-color:purple;"><strong>多功能</strong></mark></p><p><mark style="background-color:purple;"><strong>64GB 空間</strong></mark></p> | KV 快取                                                        | 激活值、梯度、優化器狀態                       |

要啟用此功能，只需在任何 Unsloth 匯入之前，將以下內容加入到所有 RL / GRPO 訓練執行中：

## :test_tube:效能實驗

在這裡，您將瞭解我們如何對 GRPO 的記憶體使用量和上下文長度進行基準測試。請注意，我們 **針對每個提示執行 2 次生成，因為為了讓 GRPO 運作**，我們至少需要 2 次生成來計算樣本平均值和變異數。**沒有 2 次生成，單個樣本的標準差為 0**。這導致使用此公式的優勢 (advantages)：(reward - mean)/std **變成未定義 (undefined)**。

$$
Z=\frac{r\_i - \mu}{\sqrt{\frac{1}{n}\sum(r\_i-\mu)^2}} \\
Z\_{n=1}=\frac{r\_1 - \mu}{\sqrt{\frac{1}{1}\sum(r\_1-\mu)^2}}=\frac{0}{0}=\text{未定義}
$$

這意味著專門針對 GRPO，Qwen-3 32B 的 6,144 最大上下文長度實際上是 6,144 乘以 2 次生成，即 12,288 的長度。

我們在下方提供了 Llama-3.1 8B 在 LoRA (16bit) 和 QLoRA (4bit) 上的實驗：

<figure><img src="https://3215535692-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FxhOjnexMCB3dmuQFQ2Zq%2Fuploads%2FSheFuQuWSMXNXvKouF0O%2Foutput%20(10).png?alt=media&#x26;token=10f33092-137a-4d60-b652-377b5105af45" alt="" width="563"><figcaption></figcaption></figure>

**如果您注意到任何訓練時間差異，那並不明顯**。在我們的對等比較中，我們注意到訓練時間有 <1% 的減速甚至加速，這可以歸因於誤差範圍。

我們也理論上認為，由於記憶體壓力減輕，可能會減少 CUDA 記憶體分配器端的記憶體清理，從而實現加速。

<figure><img src="https://3215535692-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FxhOjnexMCB3dmuQFQ2Zq%2Fuploads%2FGABhMF8RjsTh8q8AFXEt%2Fgpu%20mem%20cofigure.png?alt=media&#x26;token=4c4ed00b-ea84-4eba-aba8-71f697f953ae" alt=""><figcaption></figcaption></figure>

在上圖中，您可以看到單張 T4 GPU 上 Qwen 3 4B 的基準線與 Standby 模式之間的差異。<mark style="background-color:green;">**我們可以將 vllm 的**</mark><mark style="background-color:green;">**&#x20;**</mark><mark style="background-color:green;">**`gpu_memory_utilisation`**</mark><mark style="background-color:green;">**&#x20;**</mark><mark style="background-color:green;">**延伸至高達 0.95，而無需擔心它會影響訓練**</mark>。這意味著您可以容納更高上下文長度的序列，並且可以處理更多序列。例如在第一種情況下，如果訓練允許，我們有足夠的記憶體來容納和處理 32K 長度的序列，而以前，任何長於 2K 的輸入都可能無法容納並導致 OOM（記憶體不足）。

<table data-full-width="true"><thead><tr><th>實驗</th><th>配置</th><th>狀態</th><th>GPU 記憶體使用量</th><th>評論</th></tr></thead><tbody><tr><td><ol><li><a href="https://colab.research.google.com/drive/18CssBY5C0mStnLvu2Hlt4aFLoPugRG0K?usp=sharing">u0.95gen2ga1s Qwen3_(4B)-GRPO.ipynb</a></li></ol></td><td><p><code>standby True</code></p><p><code>vllm_gpu_util 0.95</code></p><p><code>num_gen 2</code></p><p><code>grad_acc_steps 2</code></p></td><td>執行 40 個步驟 / 40 分鐘</td><td><p>14.5 GiB (由 vllm_gpu_util 設定)</p><p><br></p></td><td>足以容納 32K KVCache 配合 2-4K 的分塊，或例如 16K KVCache + 16K 分塊</td></tr><tr><td><ol start="2"><li><a href="https://colab.research.google.com/drive/1q0TOUychygfreI2wKpg51sqnRhs5cYnX?usp=sharing">u9ge2ga2s Qwen3_(4B)-GRPO.ipynb</a></li></ol></td><td><p><code>standby True</code></p><p><code>vllm_gpu_util 0.9</code></p><p><code>num_gen 2</code></p><p><code>grad_acc_steps 2</code></p></td><td>40 分鐘執行 32 個步驟</td><td>13.8 GiB (由...設定)</td><td>大約足以容納 ~28K KVCache 配合 2-4K 分塊，或例如 15K KVCache + 15K 分塊</td></tr><tr><td><ol start="3"><li><a href="https://colab.research.google.com/drive/12Uw8y5beLzPtx11mCWCYyh9Z_PEHHdId?usp=sharing">u9ge2ga2ns Qwen3_(4B)-GRPO.ipynb</a></li></ol></td><td><p><code>standby False</code></p><p><code>vllm_gpu_util 0.9</code></p><p><code>num_gen 2</code></p><p><code>grad_acc_steps 2</code></p></td><td>模型載入但無法訓練，因為即使 batch size 為 1 也無法容納</td><td>OOM</td><td><br></td></tr><tr><td><ol start="4"><li><a href="https://colab.research.google.com/drive/1GwTlaP5CLsW-BcE1LqZWkz6S8VTWYdJ2?usp=sharing">u8ge2ga2ns Qwen3_(4B)-GRPO.ipynb</a></li></ol></td><td><p><code>standby False</code></p><p><code>vllm_gpu_util 0.8</code></p><p><code>num_gen 2</code></p><p><code>grad_acc_steps 2</code></p></td><td>模型載入但無法訓練，因為即使 batch size 為 1 也無法容納</td><td>OOM</td><td><br></td></tr><tr><td><ol start="5"><li><... [truncated]

| 模型                | GPU                   | 序列長度 | 生成數量 | 梯度累積步數 |
| -------------------- | --------------------- | ------- | --------------- | -------------- |
| Qwen2.5-14B-Instruct | NVIDIA H100 80GB PCIe | 32,768  | 8               | 4              |

在下方的可摺疊結果中，您可以看到峰值記憶體使用量有 9GiB 的差異（請注意，在我們的案例中，90% 的時間裡，GPU 記憶體使用量等於峰值記憶體）。**為了更直觀地說明，使用 TRL 和 LoRA，我們最多只能微調上下文長度為 1024 的 8B 參數模型（少了 32 倍）。** 任何具有更高序列長度（具有類似配置）的操作都會導致程序因 OOM 而失敗。

<summary>點選展開 Unsloth Standby 模式對比無 Standby 的基準測試</summary>

下圖顯示了 Standby 與 Unsloth 非 Standby 訓練的對比。它是 3 次執行的平均值，以確保指標不會有雜訊。事實上，如果您縮放得足夠近，您會看到啟用 Standby 也會使其更快，這可能是由於如前所述的記憶體壓力減輕所致。

<figure><img src="https://3215535692-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FxhOjnexMCB3dmuQFQ2Zq%2Fuploads%2FLn0GXTYJvay21vPuGgRV%2Ftrainglobalstep.png?alt=media&#x26;token=2b532c3f-ab12-4d69-9258-f89b4f7a4261" alt=""><figcaption></figcaption></figure>

### 先前的 A100 40GB 實驗

在我們之前在 A100 40GB GPU 上使用 Qwen-2.5-3b-instruct 且每樣本進行 8 次生成的實驗中，我們觀察到在沒有 Standby 的情況下，GRPO 訓練（模型以 16bit 載入，LoRA，僅權重可訓練），我們只能容納 6K 的序列長度。憑藉我們的 Standby 功能，我們能夠容納 10K 甚至更多！**相比之下，TRL 在保持相同 batch size 的情況下只能為您提供高達 1K 的上下文長度。**

<figure><img src="https://3215535692-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FxhOjnexMCB3dmuQFQ2Zq%2Fuploads%2FInuI53Sf50kXcxfW1YCz%2Fqwen3%20gpu%20mem.png?alt=media&#x26;token=0c2b62ad-d31c-40b5-ab8c-55accfc88c65" alt="" width="563"><figcaption></figcaption></figure>

## :tada:其他優化

我們現在選擇更好的編譯旗標，並將編譯時間縮短了 50% 或更多。我們還設法動態修補任何 vLLM 版本以更好地處理 `gc.collect` 以實現向後相容，這受到了 [vLLM pull request](https://github.com/vllm-project/vllm/pull/21146) 的啟發。這將編譯時間從 2 分鐘縮短到 40 秒以內。

我們還優化了 `torch.compile` 旗標並嘗試開啟一些旗標 - 不幸的是 `combo_kernels` 和 `multi_kernel` 無法在 vLLM 0.10 和 Torch 2.8/2.9 nightly 上正確運作，而 `coordinate_descent_tuning` 使所有內核的自動調優變得戲劇性地緩慢。以前編譯只需不到一分鐘，但啟用它後需要超過 13 分鐘，且效能增益極小。

## :books:GRPO Notebooks

我們所有的 GRPO notebook 預設都開啟了 Unsloth Standby 和所有優化！請參閱 <https://docs.unsloth.ai/get-started/unsloth-notebooks> 獲取我們所有的 GRPO notebook，或嘗試以下內容：

* [**Qwen3 (4B)**](https://colab.research.google.com/github/unslothai/notebooks/blob/main/nb/Qwen3_\(4B\)-GRPO.ipynb) **-** 進階 GRPO LoRA
* [**DeepSeek-R1-0528-Qwen3 (8B)**](https://colab.research.google.com/github/unslothai/notebooks/blob/main/nb/DeepSeek_R1_0528_Qwen3_\(8B\)_GRPO.ipynb) (用於多語言案例)
* [Gemma 3 (1B)](https://colab.research.google.com/github/unslothai/notebooks/blob/main/nb/Gemma3_\(1B\)-GRPO.ipynb)
* [Llama 3.2 (3B)](https://colab.research.google.com/github/unslothai/notebooks/blob/main/nb/Advanced_Llama3_2_\(3B\)_GRPO_LoRA.ipynb) - 進階 GRPO LoRA
* [Llama 3.1 (8B)](https://colab.research.google.com/github/unslothai/notebooks/blob/main/nb/Llama3.1_\(8B\)-GRPO.ipynb)
* [Phi-4 (14B)](https://colab.research.google.com/github/unslothai/notebooks/blob/main/nb/Phi_4_\(14B\)-GRPO.ipynb)
* [Mistral v0.3 (7B)](https://colab.research.google.com/github/unslothai/notebooks/blob/main/nb/Mistral_v0.3_\(7B\)-GRPO.ipynb)
* [Qwen2.5 (3B)](https://colab.research.google.com/github/unslothai/notebooks/blob/main/nb/Qwen2.5_\(3B\)-GRPO.ipynb)

**範例：**

範例 1 (python):
```python
import os
os.environ["UNSLOTH_VLLM_STANDBY"] = "1"

from unsloth import FastLanguageModel
import torch
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name = "unsloth/Qwen3-8B-Base",
    max_seq_length = 2048, # 可以增加以獲取更長的推理軌跡
    load_in_4bit = False, # LoRA 16bit 為 False
    fast_inference = True,
    max_lora_rank = 32, # rank 越大 = 越聰明，但越慢
    gpu_memory_utilization = 0.95,
)
```

範例 2 (python):
```python
import os
os.environ["UNSLOTH_VLLM_STANDBY"] = "1"
```

範例 3 (未知):
```unknown
Standy 模式已啟用：

|===========================================================================|
|                  PyTorch CUDA 記憶體摘要，設備 ID 0                 |
|---------------------------------------------------------------------------|
|            CUDA OOM: 0            |        cudaMalloc 重試: 0         |
|===========================================================================|
|        指標         | 當前使用量  | 峰值使用量 | 總分配  | 總釋放  |
|---------------------------------------------------------------------------|
| 已分配記憶體      |  32249 MiB |  43042 MiB | 128336 GiB | 128305 GiB |
|       來自大池 |  31415 MiB |  42165 MiB | 127204 GiB | 127173 GiB |
|       來自小池 |    834 MiB |   1184 MiB |   1132 GiB |   1131 GiB |
|---------------------------------------------------------------------------|
| 活動記憶體         |  32249 MiB |  43042 MiB | 128336 GiB | 128305 GiB |
|       來自大池 |  31415 MiB |  42165 MiB | 127204 GiB | 127173 GiB |
|       來自小池 |    834 MiB |   1184 MiB |   1132 GiB |   1131 GiB |
|---------------------------------------------------------------------------|
| 請求記憶體      |  32199 MiB |  42987 MiB | 128176 GiB | 128145 GiB |
|       來自大池 |  31364 MiB |  42110 MiB | 127047 GiB | 127016 GiB |
|       來自小池 |    834 MiB |   1184 MiB |   1129 GiB |   1128 GiB |
|---------------------------------------------------------------------------|
| GPU 保留記憶體   |  37644 MiB |  47504 MiB | 705806 MiB | 668162 MiB |
|       來自大池 |  36376 MiB |  46588 MiB | 682818 MiB | 646442 MiB |
|       來自小池 |   1268 MiB |   1284 MiB |  22988 MiB |  21720 MiB |
|---------------------------------------------------------------------------|
| 不可釋放記憶體 | 713142 KiB |   4633 MiB | 103206 GiB | 103205 GiB |
|       來自大池 | 525312 KiB |   4594 MiB | 101923 GiB | 101922 GiB |
|       來自小池 | 187830 KiB |    250 MiB |   1283 GiB |   1283 GiB |
|---------------------------------------------------------------------------|
| 分配量           |    3460    |    4809    |   15606 K  |   15603 K  |
|       來自大池 |     395    |     563    |    2812 K  |    2811 K  |
|       來自小池 |    3065    |    4270    |   12794 K  |   12791 K  |
|---------------------------------------------------------------------------|
| 活動分配量         |    3460    |    4809    |   15606 K  |   15603 K  |
|       來自大池 |     395    |     563    |    2812 K  |    2811 K  |
|       來自小池 |    3065    |    4270    |   12794 K  |   12791 K  |
|---------------------------------------------------------------------------|
| GPU 保留段 |     913    |     920    |   13260    |   12347    |
|       來自大池 |     279    |     305    |    1766    |    1487    |
|       來自小池 |     634    |     642    |   11494    |   10860    |
|---------------------------------------------------------------------------|
| 不可釋放分配量 |     422    |     628    |    4766 K  |    4765 K  |
|       來自大池 |      66    |      92    |    1290 K  |    1289 K  |
|       來自小池 |     356    |     555    |    3476 K  |    3475 K  |
|---------------------------------------------------------------------------|
| 超大分配量  |       0    |       0    |       0    |       0    |
|---------------------------------------------------------------------------|
| 超大 GPU 段 |       0    |       0    |       0    |       0    |
|===========================================================================|


無 Standby：

|===========================================================================|
|                  PyTorch CUDA 記憶體摘要，設備 ID 0                 |
|---------------------------------------------------------------------------|
|            CUDA OOM: 0            |        cudaMalloc 重試: 0         |
|===========================================================================|
|        指標         | 當前使用量  | 峰值使用量 | 總分配  | 總釋放  |
|---------------------------------------------------------------------------|
| 已分配記憶體      |  32711 MiB |  52084 MiB | 142756 GiB | 142724 GiB |
|       來自大池 |  31877 MiB |  51207 MiB | 141499 GiB | 141467 GiB |
|       來自小池 |    834 MiB |   1184 MiB |   1257 GiB |   1256 GiB |
|---------------------------------------------------------------------------|
| 活動記憶體         |  32711 MiB |  52084 MiB | 142756 GiB | 142724 GiB |
|       來自大池 |  31877 MiB |  51207 MiB | 141499 GiB | 141467 GiB |
|       來自小池 |    834 MiB |   1184 MiB |   1257 GiB |   1256 GiB |
|---------------------------------------------------------------------------|
| 請求記憶體      |  32572 MiB |  51658 MiB | 141898 GiB | 141866 GiB |
|       來自大池 |  31738 MiB |  50780 MiB | 140644 GiB | 140613 GiB |
|       來自小池 |    833 MiB |   1184 MiB |   1253 GiB |   1252 GiB |
|---------------------------------------------------------------------------|
| GPU 保留記憶體   |  49552 MiB |  52188 MiB |  86354 MiB |  36802 MiB |
|       來自大池 |  48320 MiB |  51300 MiB |  84740 MiB |  36420 MiB |
|       來自小池 |   1232 MiB |   1232 MiB |   1614 MiB |    382 MiB |
|---------------------------------------------------------------------------|
| 不可釋放記憶體 |      0 B   |      0 B   |      0 B   |      0 B   |
|       來自大池 |      0 B   |      0 B   |      0 B   |      0 B   |
|       來自小池 |      0 B   |      0 B   |      0 B   |      0 B   |
|---------------------------------------------------------------------------|
| 分配量           |    3460    |    4809    |   17440 K  |   17437 K  |
|       來自大池 |     395    |     564    |    2742 K  |    2741 K  |
|       來自小池 |    3065    |    4270    |   14698 K  |   14695 K  |
|---------------------------------------------------------------------------|
| 活動分配量         |    3460    |    4809    |   17440 K  |   17437 K  |
|       來自大池 |     395    |     564    |    2742 K  |    2741 K  |
|       來自小池 |    3065    |    4270    |   14698 K  |   14695 K  |
|---------------------------------------------------------------------------|
| GPU 保留段 |       0    |       0    |       0    |       0    |
|       來自大池 |       0    |       0    |       0    |       0    |
|       來自小池 |       0    |       0    |       0    |       0    |
|---------------------------------------------------------------------------|
| 不可釋放分配量 |       0    |       0    |       0    |       0    |
|       來自大池 |       0    |       0    |       0    |       0    |
|       來自小池 |       0    |       0    |       0    |       0    |
|---------------------------------------------------------------------------|
| 超大分配量  |       0    |       0    |       0    |       0    |
