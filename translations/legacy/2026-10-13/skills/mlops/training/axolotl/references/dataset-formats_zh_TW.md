# Axolotl - 資料集格式

**頁數：** 9

---

## 自定義預標記資料集 (Custom Pre-Tokenized Dataset)

**URL:** https://docs.axolotl.ai/docs/dataset-formats/tokenized.html

**內容：**
- 自定義預標記資料集

**範例：**

範例 1 (yaml):
```yaml
datasets:
  - path: /path/to/your/file.jsonl
    ds_type: json
    type:
```

範例 2 (json):
```json
{"input_ids":[271,299,99],"attention_mask":[1,1,1],"labels":[271,-100,99]}
{"input_ids":[87,227,8383,12],"attention_mask":[1,1,1,1],"labels":[87,227,8383,12]}
```

---

## 資料集格式 (Dataset Formats)

**URL:** https://docs.axolotl.ai/docs/dataset-formats/index.html

**內容：**
- 資料集格式
- 預訓練 (Pre-training)
  - 從 Hugging Face Hub 資料集進行預訓練
  - 從本地資料集檔案進行預訓練
  - 不使用串流的預訓練
  - 預訓練資料集配置技巧
    - 設定 max_steps
    - 按長度分組 (Group_by_length)
  - 參考資料
- 監督式微調 (SFT)

Axolotl 是一個訓練框架，旨在透過簡單地傳遞一個配置 YAML 檔案，使訓練過程對使用者來說既方便又靈活。

由於 Axolotl 中有很多可用選項，本指南旨在簡化使用者選擇合適選項的體驗。

Axolotl 支援 3 種訓練方法：預訓練 (Pre-training)、監督式微調 (Supervised fine-tuning) 以及基於偏好的訓練後處理 (例如 DPO、ORPO、PRMs)。每種方法都有其專屬的資料集格式，如下所述。

本指南將主要使用 JSONL 作為介紹。請參考資料集載入文件以瞭解如何從其他來源載入資料集。

關於 pretraining_dataset：具體請參考「預訓練」章節。

當旨在對大型文本資料集語料庫進行訓練時，預訓練是您的首選。由於這些資料集的大小，在開始訓練之前下載整個資料集將會非常耗時。Axolotl 支援串流 (Streaming)，以便一次僅載入批次資料到記憶體中。

預訓練資料集的範例格式如下：

通常建議將資料集儲存為 .jsonl，因為它具有靈活性且簡單。

Axolotl 支援從 Hugging Face Hub 儲存庫或從本地檔案載入。

例如，要使用 Hugging Face 資料集 hf_org/name 進行訓練，您可以傳遞以下配置：

假設有幾個語料庫檔案：A.jsonl、B.jsonl 和 C.jsonl，您的配置將如下所示：

雖然我們建議使用 .jsonl，但您也可以使用 Dataset.load_dataset 支援的其他格式（csv、parquet、arrow、SQL、Webdataset）。

如果資料集很小且可以完全載入到記憶體中，另一種執行預訓練的方法是使用 completion 格式。這意味著整個資料集是預先標記好的，而不是在串流中按需標記。

這樣做的一個好處是標記化可以單獨在僅限 CPU 的機器上執行，然後傳輸到 GPU 機器進行訓練以節省成本。

目前僅針對 completion，如果超過上下文長度，Axolotl 會將文本拆分為多個較小的提示。如果您有興趣為 pretraining_dataset 也提供此功能，請告訴我們或協助提交 PR！

在對大型資料集使用串流時，Axolotl 事先不知道資料集有多大，也不知道何時停止。

因此，有必要在您的配置中設定 max_steps: int 以供預訓練執行，這樣 Axolotl 才知道何時停止訓練。

一個步驟 (step) 等於 sequence_len * micro_batch_size * gradient_accumulation_steps * total_num_gpus 個標記 (tokens)。

如果是從 Hugging Face hub 下載，建議關閉此選項，因為它會下載整個資料集，而資料集可能非常大。

請參閱此處的文件。

監督式微調是訓練模型以回應指令或聊天輸入的過程。

由於資料集格式多種多樣，Axolotl 嘗試支援公共資料集中可用的大多數格式。

Axolotl 提供了四種載入資料集的方法，然而，從您現有的資料集反推來弄清楚應該使用哪種方法會更容易。

流程圖如下：

您是否已經將資料集標記化？如果是，請查看「預標記資料集」。

您是否想自己格式化資料集並手動選擇要屏蔽 (mask) 的每個部分？如果是，請查看「無模板資料集」。

您的資料集是否為「對話 (conversation)」格式，包含 list[messages]？如果是，請查看「對話資料集」。

您的資料集是否為「指令 (instruct)」格式，包含 { instruction, response }？如果是，請查看「指令資料集」。

如果您看過流程圖但沒有找到匹配的格式，建議將您的資料集預處理為上述格式之一，或者在 Github Discussion 上發起討論。

您可以在每種方法內或跨方法進行混合搭配，以在各種資料集上訓練模型。

當您想使用自己的預標記資料集時，我們建議採用此方法。

Axolotl 期望資料集具有三個鍵值：

確保在提示中加入 BOS/EOS 標記，並適當地屏蔽它。

對此的配置如下所示：

參考資料：預標記資料集文件。

當您想要對提示格式、特殊標記和屏蔽進行細粒度控制，同時讓 Axolotl 處理標記化時，我們推薦此方法。如果您的資料集具有不同樣本間互不相同的獨特提示，且單一通用模板無法滿足需求時，這非常有用。

在下面的範例中，您可以看到沒有適當的結構。同時，它非常靈活，因為對提示的外觀沒有限制。

每個提示必須有一個名為 segments 的鍵值，它是一個 { text, label } 列表。

參考資料：無模板文件。

對話訊息是一個列表，通常包含 role (角色) 和 content (內容) 鍵值。

有趣的事實：Axolotl 同義地將「聊天 (chat)」訊息稱為對話訊息，這是因為 FastChat 最初在建立 chat_templates 之前，使用了這個術語來建立廣泛使用的快速聊天對話方法，用於格式化聊天訊息。

目前最流行且最方便的推理方法是使用 chat_templates 來格式化提示。Axolotl 支援在訓練過程中使用 chat_templates，以確保模型在與推理相同的環境中運作。

以下是 chat_template 的簡要介紹：chat_template 是一個 Jinja2 模板，它將訊息列表格式化為提示。

以下可以看到格式化為流行的 ChatML 模板的提示範例：

單一提示（美化列印）：

ChatML 模板如下：

格式化為此模板的上述提示將產生：

透過使用分隔符號（<|im_start|> 和 <|im_end|>），提示將不同的說話者分開，這有助於模型識別哪一部分屬於誰。

具有以下格式的舊版對話資料集口語上被稱為 sharegpt 資料集。

較新的對話資料集通常遵循 OpenAI 格式。

Axolotl 支援兩者，並允許對任何類型的鍵值進行自定義。

要正確使用此方法，識別三件事很重要：

您會使用哪種 chat_template？

您資料集中的鍵值是什麼，以及可能的角色是什麼？例如，在 OpenAI 格式中，鍵值分別為 messages、role 和 content，而可能的角色為 system、user 和 assistant。

您想屏蔽什麼？例如，僅助理訊息、僅最後一條訊息，或什麼都不屏蔽。

市面上有很多 chat_templates。Axolotl 支援常見的：支援的聊天模板。例如，要使用 ChatML，它將是 chat_template: chatml。

但是，也可以透過指定 chat_template: tokenizer_default 來使用標記器中已經配置好的模板。如果您想要一個備援方案（以防某些標記器沒有預先配置），您可以執行 chat_template: tokenizer_default_fallback_chatml，如果在標記器中未找到模板，則回退到 ChatML 模板。

最後一個但功能強大的方法是帶入您自己的模板。這可以透過以下方式設定：

我們目前預設資料集鍵值使用 OpenAI 格式，因此如果您目前的資料集格式就是如此，這裡不需要做任何操作。

如果您的資料集格式不同，以下是您應該檢查的鍵值（及其預設值）：

在某些 chat_templates 中（例如 Gemma），角色被硬編碼為 user 和 assistant。因此，您可能會發現有必要將資料集中的角色映射到上述角色。我們目前有一些預設設定應該適用於常見資料集，但如果您遇到 KeyError，則有必要為您的角色增加映射。以下是範例：

在上面的範例中，所有的 gpt 和 model 值都被轉換為 assistant。所有的 human 值都被轉換為 user。

chat_template 的常見用途是聊天訊息，因此，通常會屏蔽所有非助理訊息。助理訊息是指您希望模型學習的機器人訊息。

要對所有助理訊息進行訓練，您將設定以下配置。

train_on_eos 配置意味著它將屏蔽非助理輪次的所有 EOS 標記。其他選項包括：all 和 last，用於選擇要訓練哪個 EOS。

也許您想對 assistant 和 narrator (旁白) 角色進行訓練，您只需將 narrator 加入 roles_to_train 列表即可。您還需要將其加入上面的角色映射中。

由於 chat_templates 可能使用與標記器 EOS 不同的硬編碼 EOS/EOT 標記，因此強烈建議設定它們。例如，ChatML 使用 <|im_end|> 來結束輪次。

完成上述所有步驟後，您可以將所有這些配置組合在一起，為您的自定義資料集形成量身定制的配置。

如果將此配置應用於上面的樣本資料集，輸出將如下所示（可以透過 axolotl preprocess config.yaml --debug 取得）：

第一個數字指的是標籤 (label)，第二個數字指的是標記 ID (token_id)。例如，-100 標籤出現在非助理部分，這意味著它們在訓練期間被屏蔽。對於助理部分，標籤與 token_id 相同。

如果預處理期間有很多 Could not find content __ boundary 的警告，請檢查 chat_templates 的常見問題 (FAQ) 章節。

請參閱此處的文件。

指令資料集用於訓練指令遵循模型，由包含指令的提示和單一回應組成。與可能是多輪的聊天資料集相比，指令資料集通常是單輪的。

常見格式 Alpaca 的範例：

使用這些鍵值，可以基於此構建提示。

可以這樣配置：

Axolotl 支援多種指令資料集。所有這些都可以在「指令資料集文件」中找到，並附有各自的類型和樣本列格式。

由於指令格式有無限可能，Axolotl 允許在不直接深入程式碼的情況下自定義您自己的指令格式。

在下面的範例中，使用一個樣本列以 mistral_v1 格式輸出。

配置設定 field_instruction 實際上命名為 input，而 field_input 是空的，因為我們在這個樣本中沒有輸入。通常，指令可以被認為是對模型的問題，輸入是額外資訊，而輸出是回應。並非必須要有輸入或系統提示。最後，最重要的部分是瞭解您想要什麼格式，以及如何根據您的用例對其進行自定義。

參考資料：自定義指令提示格式文件。

由於有多種 RLHF 方法，每種方法都有自己的資料集要求。詳情請參閱 RLHF 文件。

**範例：**

範例 1 (json):
```json
{"text": "first row"}
{"text": "second row"}
...
```

範例 2 (yaml):
```yaml
pretraining_dataset: hf_org/name
```

範例 3 (yaml):
```yaml
pretraining_dataset:
  - path: json
    data_files:
      - A.jsonl
      - B.jsonl
      - C.jsonl
```

範例 4 (yaml):
```yaml
datasets:
  - path: hf_org/name
    type: completion
```

---

## 對話 (Conversation)

**URL:** https://docs.axolotl.ai/docs/dataset-formats/conversation.html

**內容：**
- 對話
- chat_template
  - 從 sharegpt 遷移
  - 範例
    - 訓練最後一條訊息
    - 覆寫預設聊天模板
    - 使用帶備援的預設聊天模板
    - 自定義 Jinja 模板
    - 使用對 EOT 和 EOS 使用不同標記的模板
    - 使用工具呼叫 (tool use)

聊天模板 (Chat Template) 策略使用 jinja2 模板將訊息列表轉換為提示。支援使用標記器的模板、支援的模板或自定義 jinja2。

完整的配置和支援的模板請參閱配置說明。

大多數配置可以按如下方式調整：

我們建議查看以下範例以瞭解其他用例。

（舊版）在 OpenAI 訊息格式上使用 tokenizer_config.json 中的預設聊天模板，僅對最後一條訊息進行訓練。

如果您收到類似「chat_template choice is tokenizer_default but tokenizer’s chat_template is null.」的錯誤，這意味著標記器沒有預設的 chat_template。請按照下面的範例設定自定義 chat_template。

在 OpenAI 訊息格式上使用 gemma 聊天模板來覆寫 tokenizer_config.json 的聊天模板，對所有助理訊息進行訓練。

如果您想使用內建的 chat_template，請使用 chat_template: tokenizer_default（這是預設設定）。

如果在 OpenAI 訊息格式上，tokenizer_config.json 的聊天模板不存在，則使用其或 chatml 作為備援，對所有助理訊息進行訓練。

在 OpenAI 訊息格式上使用自定義 jinja 模板，對所有助理訊息進行訓練。

請確保您的 tokenizer.eos_token 與模板中的 EOS (End-of-Sequence) 標記相同。否則，請在 special_tokens: 下設定 eos_token。

關於訓練標記的「turn」、「last」和「all」選項的詳細說明，請參閱配置文件。

使用 eot_tokens 要求 chat_template 中存在的每個標記在標記器中都是單一標記。否則，標記器將拆分標記並導致意外行為。

您可以將這些標記作為新標記加入 tokens: 下，或（推薦）透過 added_tokens_overrides: 覆寫未使用的 added_tokens。詳情請參閱配置。

如果 EOS 標記僅出現在提示末尾，則 train_on_eos: last 等同於 train_on_eos: turn。因此，通常您可以保留其預設值並將其省略。

與其透過系統提示傳遞工具，另一種方法是將工具放在單獨的列中，並透過 chat_template 載入，讓模板動態構建它。

工具需要遵循 JSON 模式 (JSON schema)。

如果您有名稱相同但資料類型 (dtypes) 不同的工具參數（如 "time": string 和 "time": number），請將 arguments: 儲存為 JSON 字串，以防止資料集出現轉型問題。

Llama4 的範例配置：

查看您正在使用的 chat_template，瞭解它是否支援工具，以及工具答案的預期角色是什麼。在上面的範例中，對於 llama4 模板，預期工具答案在 tool 或 ipython 角色中。

（進階）在對話訓練中對標記和輪次進行精細控制

對於如下所示的資料樣本：

配置將如下所示：

並非必須同時設定 message_field_training 和 message_field_training_detail。

（僅適用於 Qwen3 模板）啟用推理拆分，將推理從內容中拆分出來，並作為單獨的欄位傳遞給模板。

例如，內容可能如下所示：

拆分後，它將如下所示：

ShareGPT 已棄用！請參閱 chat_template 章節。

**範例：**

範例 1 (json):
```json
{"messages": [{"role": "...", "content": "..."}, {"role": "...", "content": "..."}, ...]}
```

範例 2 (yaml):
```yaml
# 舊版
chat_template: chatml
datasets:
  - path: ...
    type: sharegpt
    conversation: chatml

# 新版（如果使用標記器的 chat_template）
datasets:
  - path: ...
    type: chat_template

    field_messages: conversations
    message_property_mappings:
      role: from
      content: value

# 新版（如果設定新的 chat_template 如 chatml, gemma 等）
chat_template: chatml
datasets:
  - path: ...
    type: chat_template

    field_messages: conversations
    message_property_mappings:
      role: from
      content: value
```

範例 3 (yaml):
```yaml
datasets:
  - path: ...
    type: chat_template
    roles_to_train:
    train_on_eos:
```

範例 4 (yaml):
```yaml
chat_template: gemma # 這會覆寫標記器的 chat_template
datasets:
  - path: ...
    type: chat_template
    roles_to_train: ["assistant"]  # 預設值
```

---

## 預訓練 (Pre-training)

**URL:** https://docs.axolotl.ai/docs/dataset-formats/pretraining.html

**內容：**
- 預訓練

對於預訓練，沒有提示模板或角色。唯一必填欄位是 text：

Axolotl 通常將整個資料集載入到記憶體中。這對於大型資料集將會具有挑戰性。請使用以下配置啟用串流：

**範例：**

範例 1 (json):
```json
{"text": "first row"}
{"text": "second row"}
...
```

範例 2 (yaml):
```yaml
pretraining_dataset:
  - name:
    path:
    split:
    text_column: # 資料集中包含數據的列，通常是 `text`
    type: pretrain
    trust_remote_code:
    skip: # 從頭開始跳過的數據行數
```

---

## 無模板 (Template-Free)

**URL:** https://docs.axolotl.ai/docs/dataset-formats/template_free.html

**內容：**
- 無模板
- 背景
  - 屏蔽輸入
  - 您可能不想使用提示模板
  - input_output 格式
- 用法
  - 1. 準備數據
  - 2. 使用 type: input_output
  - 3. 檢查提示

Axolotl 最受歡迎的功能之一是設定以下配置值：

如果您聲明資料集格式（如 alpaca 或 chatml），Axolotl 知道什麼是輸入（即人類）與輸出（即助理），並屏蔽輸入標籤，以便您的模型可以專注於僅預測輸出。

然而，在許多情況下，您並不想使用這些格式或模板。這是因為它們可能：

您可以透過使用 input_output 格式來構建不含模板的提示，只需在配置檔案中設定 type: input_output，如下所示：

與同樣無模板的 type: completion 不同，type: input_output 允許您屏蔽文本片段。關於其運作方式的更多細節描述如下。

以下是您可以使用 input_output 格式的方法：

要使用 input_output 格式，請將數據按以下格式收集到 jsonl 檔案中（以下是 output.jsonl 檔案中第一列的美化列印）：

當您想要屏蔽一段文本以便不對模型進行訓練時，請設定 label:false。一些需要記住的事項：

[!IMPORTANT] 1. EOS、BOS、空格、換行符等完全由您決定。Axolotl 會按原樣串接所有片段。標記器不會添加任何額外內容。請注意我是如何自己添加空格、換行符、<s> (BOS) 和 </s> (EOS) 的。2. 確保檢查實例化輸出，以驗證提示是否按照您喜歡的方式組裝。

讓我們透過在 Axolotl 配置中設定 type: input_output 來實例化 output.jsonl 檔案中的數據：

您可以使用以下命令實例化數據。--debug 標記將列印標記 (tokens) 以及標籤，以便您驗證正確的項目是否被忽略：

格式為 decoded_token(label, token_id)，例如，<s>(1, 1) 表示標記是 <s>，標籤是 1，token_id 是 1。當標籤為 -100 時，該標記在訓練中被忽略。

這是另一種檢查實例化輸出的方法：

我們可以透過比較標籤和每個標記來檢查正確的標記是否被忽略：

如果我們查看輸入數據，上表似乎是正確的！（為方便參考，下面重複 jsonl 版本）：

**範例：**

範例 1 (yaml):
```yaml
train_on_inputs: false
```

範例 2 (yaml):
```yaml
train_on_inputs: false # 屏蔽數據片段
datasets:
  - path: output.jsonl
    type: input_output  # 使用無模板提示構建
```

範例 3 (bash):
```bash
$ head -n1 output.jsonl | python -m json.tool
```

範例 4 (unknown):
```unknown
{
    "segments": [
        {
            "label": true,
            "text": "<s>Hello\n"
        },
        {
            "label": true,
            "text": "hi there!. "
        },
        {
            "label": false,
            "text": "goodbye "
        },
        {
            "label": true,
            "text": "farewell</s>"
        }
    ]
}
```

---

## 資料集格式 (Dataset Formats)

(此部分內容與上方重複，略過)

---

## 指令微調 (Instruction Tuning)

**URL:** https://docs.axolotl.ai/docs/dataset-formats/inst_tune.html

**內容：**
- 指令微調
- alpaca
- jeopardy
- oasst
- gpteacher
- reflection
- explainchoice
- concisechoice
- summarizetldr
- alpaca_chat

instruction; input(選填)

instruction; input(選填)

帶 reflect 的 instruction; input(選填)

question, choices, (solution 或 explanation)

question, choices, (solution 或 explanation)

用於 alpaca 聊天的基礎指令

用於 alpaca 聊天的問答

用於 alpaca 聊天的問答，針對簡潔答案

用於 alpaca 聊天的問答，針對 load_camel_ai

支援包含系統提示的 open orca 資料集，指令

來自文章的上下文問答

上下文問答（替代方案）

來自文章的上下文問答，針對上下文中無答案的情況提供預設回應

指令和修訂

指令，增加額外的 EOS 標記

對於為了指令目的而預處理的資料集：

您可以在 YAML 配置中使用此範例：

完整的配置選項請參閱此處。

**範例：**

範例 1 (json):
```json
{"instruction": "...", "input": "...", "output": "..."}
```

範例 2 (json):
```json
{"question": "...", "category": "...", "answer": "..."}
```

範例 3 (json):
```json
{"INSTRUCTION": "...", "RESPONSE": "..."}
```

範例 4 (json):
```json
{"instruction": "...", "input": "...", "response": "..."}
```

---

## 逐步監督格式 (Stepwise Supervised Format)

**URL:** https://docs.axolotl.ai/docs/dataset-formats/stepwise_supervised.html

**內容：**
- 逐步監督格式
- 逐步監督
  - 範例

逐步監督格式專為思維鏈 (COT) 推理資料集設計，其中每個範例包含多個完成步驟以及每個步驟的偏好標籤。

以下是逐步監督資料集項目的簡單範例：

**範例：**

範例 1 (json):
```json
{
  "prompt": "Which number is larger, 9.8 or 9.11?",
  "completions": [
    "The fractional part of 9.8 is 0.8, while the fractional part of 9.11 is 0.11.",
    "Since 0.11 is greater than 0.8, the number 9.11 is larger than 9.8."
  ],
  "labels": [true, false]
}
```

---
