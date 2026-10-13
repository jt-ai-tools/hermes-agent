---
title: "AI 提供商"
sidebar_label: "AI 提供商"
sidebar_position: 1
---

# AI 提供商

本頁面介紹如何為 Hermes Agent 設定推論提供商 — 從 OpenRouter 和 Anthropic 等雲端 API，到 Ollama 和 vLLM 等自代管端點，再到進階的路由和備援配置。您至少需要配置一個提供商才能使用 Hermes。

## 推論提供商

您至少需要一種連接到 LLM 的方式。使用 `hermes model` 互動式地切換提供商和模型，或直接配置：

| 提供商 | 設定方式 |
|----------|-------|
| **Nous Portal** | `hermes model` (基於 OAuth，訂閱制) |
| **OpenAI Codex** | `hermes model` (ChatGPT OAuth，使用 Codex 模型) |
| **GitHub Copilot** | `hermes model` (OAuth 裝置代碼流、`COPILOT_GITHUB_TOKEN`、`GH_TOKEN` 或 `gh auth token`) |
| **GitHub Copilot ACP** | `hermes model` (啟動在地的 `copilot --acp --stdio`) |
| **Anthropic** | `hermes model` (透過 Claude Code 驗證使用 Claude Pro/Max、Anthropic API 金鑰或手動 setup-token) |
| **OpenRouter** | `~/.hermes/.env` 中的 `OPENROUTER_API_KEY` |
| **AI Gateway** | `~/.hermes/.env` 中的 `AI_GATEWAY_API_KEY` (提供商：`ai-gateway`) |
| **z.ai / GLM (智譜清言)** | `~/.hermes/.env` 中的 `GLM_API_KEY` (提供商：`zai`) |
| **Kimi / Moonshot (月之暗面)** | `~/.hermes/.env` 中的 `KIMI_API_KEY` (提供商：`kimi-coding`) |
| **Kimi / Moonshot (中國)** | `~/.hermes/.env` 中的 `KIMI_CN_API_KEY` (提供商：`kimi-coding-cn`；別名：`kimi-cn`、`moonshot-cn`) |
| **Arcee AI** | `~/.hermes/.env` 中的 `ARCEEAI_API_KEY` (提供商：`arcee`；別名：`arcee-ai`、`arceeai`) |
| **MiniMax** | `~/.hermes/.env` 中的 `MINIMAX_API_KEY` (提供商：`minimax`) |
| **MiniMax 中國** | `~/.hermes/.env` 中的 `MINIMAX_CN_API_KEY` (提供商：`minimax-cn`) |
| **阿里巴巴雲 (通義千問)** | `~/.hermes/.env` 中的 `DASHSCOPE_API_KEY` (提供商：`alibaba`，別名：`dashscope`、`qwen`) |
| **Kilo Code** | `~/.hermes/.env` 中的 `KILOCODE_API_KEY` (提供商：`kilocode`) |
| **小米 MiMo** | `~/.hermes/.env` 中的 `XIAOMI_API_KEY` (提供商：`xiaomi`，別名：`mimo`、`xiaomi-mimo`) |
| **OpenCode Zen** | `~/.hermes/.env` 中的 `OPENCODE_ZEN_API_KEY` (提供商：`opencode-zen`) |
| **OpenCode Go** | `~/.hermes/.env` 中的 `OPENCODE_GO_API_KEY` (提供商：`opencode-go`) |
| **DeepSeek (深度求索)** | `~/.hermes/.env` 中的 `DEEPSEEK_API_KEY` (提供商：`deepseek`) |
| **Hugging Face** | `~/.hermes/.env` 中的 `HF_TOKEN` (提供商：`huggingface`，別名：`hf`) |
| **Google / Gemini** | `~/.hermes/.env` 中的 `GOOGLE_API_KEY` (或 `GEMINI_API_KEY`) (提供商：`gemini`) |
| **自定義端點** | `hermes model` → 選擇 "Custom endpoint" (儲存在 `config.yaml` 中) |

:::tip 模型鍵值別名
在 `model:` 配置區段中，您可以使用 `default:` 或 `model:` 作為模型 ID 的鍵名。`model: { default: my-model }` 和 `model: { model: my-model }` 的效果完全相同。
:::

:::info Codex 說明
OpenAI Codex 提供商透過裝置代碼進行驗證（開啟網址，輸入代碼）。Hermes 將產生的憑證儲存在其位於 `~/.hermes/auth.json` 的驗證儲存庫中，並可以從 `~/.codex/auth.json` 匯入現有的 Codex CLI 憑證（如果存在）。無需安裝 Codex CLI。
:::

:::warning
即使使用 Nous Portal、Codex 或自定義端點，某些工具（視覺、網頁摘要、MoA）也會使用單獨的「輔助」模型 — 預設是透過 OpenRouter 使用 Gemini Flash。設定 `OPENROUTER_API_KEY` 即可自動啟用這些工具。您也可以配置這些工具使用的模型和提供商 — 請參閱 [輔助模型](/docs/user-guide/configuration#auxiliary-models)。
:::

### 模型管理的兩個指令

Hermes 有 **兩個** 模型指令，分別用於不同目的：

| 指令 | 運行位置 | 功能 |
|---------|-------------|--------------|
| **`hermes model`** | 您的終端機 (工作階段之外) | 完整設定精靈 — 新增提供商、運行 OAuth、輸入 API 金鑰、配置端點 |
| **`/model`** | Hermes 聊天工作階段內 | 快速切換 **已配置** 的提供商和模型 |

如果您嘗試切換到尚未設定的提供商（例如，您只配置了 OpenRouter 且想要使用 Anthropic），您需要使用 `hermes model` 而非 `/model`。請先退出工作階段 (`Ctrl+C` 或 `/quit`)，運行 `hermes model`，完成提供商設定，然後啟動新的工作階段。

### Anthropic (原生支援)

直接透過 Anthropic API 使用 Claude 模型 — 無需 OpenRouter 代理。支援三種驗證方式：

```bash
# 使用 API 金鑰 (按 Token 付費)
export ANTHROPIC_API_KEY=***
hermes chat --provider anthropic --model claude-sonnet-4-6

# 偏好方式：透過 `hermes model` 進行驗證
# Hermes 將在可用時直接使用 Claude Code 的憑證儲存庫
hermes model

# 使用 setup-token 手動覆蓋 (備用 / 舊版)
export ANTHROPIC_TOKEN=***  # setup-token 或手動 OAuth token
hermes chat --provider anthropic

# 自動偵測 Claude Code 憑證 (如果您已使用 Claude Code)
hermes chat --provider anthropic  # 會自動讀取 Claude Code 憑證檔案
```

當您透過 `hermes model` 選擇 Anthropic OAuth 時，Hermes 偏好使用 Claude Code 自身的憑證儲存庫，而不是將權杖複製到 `~/.hermes/.env` 中。這能保持可刷新的 Claude 憑證能夠正常刷新。

或永久設定：
```yaml
model:
  provider: "anthropic"
  default: "claude-sonnet-4-6"
```

:::tip 別名
`--provider claude` 和 `--provider claude-code` 也可以作為 `--provider anthropic` 的簡寫。
:::

### GitHub Copilot

Hermes 將 GitHub Copilot 作為一等公民提供商支援，具備兩種模式：

**`copilot` — 直接呼叫 Copilot API** (建議)。使用您的 GitHub Copilot 訂閱，透過 Copilot API 存取 GPT-5.x、Claude、Gemini 和其他模型。

```bash
hermes chat --provider copilot --model gpt-5.4
```

**驗證選項** (按此順序檢查)：

1. `COPILOT_GITHUB_TOKEN` 環境變數
2. `GH_TOKEN` 環境變數
3. `GITHUB_TOKEN` 環境變數
4. `gh auth token` CLI 備援

如果未找到權杖，`hermes model` 提供 **OAuth 裝置代碼登入** — 與 Copilot CLI 和 opencode 使用的流程相同。

:::warning 權杖類型
Copilot API **不支援** 傳統的個人存取權杖 (PAT，`ghp_*`)。支援的權杖類型：

| 類型 | 前綴 | 如何獲取 |
|------|--------|------------|
| OAuth 權杖 | `gho_` | `hermes model` → GitHub Copilot → 使用 GitHub 登入 |
| 細粒度 PAT | `github_pat_` | GitHub 設定 → Developer settings → Fine-grained tokens (需要 **Copilot Requests** 權限) |
| GitHub App 權杖 | `ghu_` | 透過安裝 GitHub App 獲取 |

如果您的 `gh auth token` 返回 `ghp_*` 權杖，請改用 `hermes model` 透過 OAuth 進行驗證。
:::

**API 路由**：GPT-5+ 模型（`gpt-5-mini` 除外）自動使用 Responses API。所有其他模型（GPT-4o、Claude、Gemini 等）使用 Chat Completions。模型是從即時的 Copilot 目錄中自動偵測的。

**`copilot-acp` — Copilot ACP 代理後端**。啟動在地 Copilot CLI 作為子程序：

```bash
hermes chat --provider copilot-acp --model copilot-acp
# 需要 PATH 中有 GitHub Copilot CLI 且已有 `copilot login` 工作階段
```

**永久配置：**
```yaml
model:
  provider: "copilot"
  default: "gpt-5.4"
```

| 環境變數 | 描述 |
|---------------------|-------------|
| `COPILOT_GITHUB_TOKEN` | 用於 Copilot API 的 GitHub 權杖 (最高優先級) |
| `HERMES_COPILOT_ACP_COMMAND` | 覆蓋 Copilot CLI 二進制檔案路徑 (預設：`copilot`) |
| `HERMES_COPILOT_ACP_ARGS` | 覆蓋 ACP 參數 (預設：`--acp --stdio`) |

### 一等公民中文 AI 提供商

這些提供商內建支援專用的提供商 ID。設定 API 金鑰並使用 `--provider` 進行選擇：

```bash
# z.ai / 智譜清言 GLM
hermes chat --provider zai --model glm-5
# 需要：~/.hermes/.env 中的 GLM_API_KEY

# Kimi / 月之暗面 AI (國際版：api.moonshot.ai)
hermes chat --provider kimi-coding --model kimi-for-coding
# 需要：~/.hermes/.env 中的 KIMI_API_KEY

# Kimi / 月之暗面 AI (中國版：api.moonshot.cn)
hermes chat --provider kimi-coding-cn --model kimi-k2.5
# 需要：~/.hermes/.env 中的 KIMI_CN_API_KEY

# MiniMax (全球端點)
hermes chat --provider minimax --model MiniMax-M2.7
# 需要：~/.hermes/.env 中的 MINIMAX_API_KEY

# MiniMax (中國端點)
hermes chat --provider minimax-cn --model MiniMax-M2.7
# 需要：~/.hermes/.env 中的 MINIMAX_CN_API_KEY

# 阿里巴巴雲 / DashScope (通義千問模型)
hermes chat --provider alibaba --model qwen3.5-plus
# 需要：~/.hermes/.env 中的 DASHSCOPE_API_KEY

# 小米 MiMo
hermes chat --provider xiaomi --model mimo-v2-pro
# 需要：~/.hermes/.env 中的 XIAOMI_API_KEY

# Arcee AI (Trinity 模型)
hermes chat --provider arcee --model trinity-large-thinking
# 需要：~/.hermes/.env 中的 ARCEEAI_API_KEY
```

或者在 `config.yaml` 中永久設定提供商：
```yaml
model:
  provider: "zai"       # 或：kimi-coding, kimi-coding-cn, minimax, minimax-cn, alibaba, xiaomi, arcee
  default: "glm-5"
```

基本 URL 可以透過 `GLM_BASE_URL`、`KIMI_BASE_URL`、`MINIMAX_BASE_URL`、`MINIMAX_CN_BASE_URL`、`DASHSCOPE_BASE_URL` 或 `XIAOMI_BASE_URL` 環境變數來覆蓋。

:::note Z.AI 端點自動偵測
使用 Z.AI / GLM 提供商時，Hermes 會自動探測多個端點（全球、中國、編碼變體）以找到接受您的 API 金鑰的端點。您無需手動設定 `GLM_BASE_URL` — 有效的端點將被自動偵測並快取。
:::

### xAI (Grok) 提示詞快取

當使用 xAI 作為提供商（任何包含 `x.ai` 的基本 URL）時，Hermes 會在每個 API 請求中發送 `x-grok-conv-id` 標頭，自動啟用提示詞快取。這會將請求路由到聊天工作階段中的同一台伺服器，讓 xAI 的基礎設施能夠重用快取的系統提示詞和對話歷史。

無需額外配置 — 當偵測到 xAI 端點且有工作階段 ID 時，快取將自動啟動。這能降低多輪對話的延遲和成本。

### Hugging Face 推論提供商

[Hugging Face 推論提供商](https://huggingface.co/docs/inference-providers) 透過統一的 OpenAI 相容端點 (`router.huggingface.co/v1`) 路由到 20 多個開放模型。請求會自動路由到最快的可用後端（Groq、Together、SambaNova 等），並具備自動備援功能。

```bash
# 使用任何可用模型
hermes chat --provider huggingface --model Qwen/Qwen3-235B-A22B-Thinking-2507
# 需要：~/.hermes/.env 中的 HF_TOKEN

# 簡短別名
hermes chat --provider hf --model deepseek-ai/DeepSeek-V3.2
```

或者在 `config.yaml` 中永久設定：
```yaml
model:
  provider: "huggingface"
  default: "Qwen/Qwen3-235B-A22B-Thinking-2507"
```

在 [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens) 獲取您的權杖 — 請務必啟用 "Make calls to Inference Providers" 權限。包含免費方案（每月 0.10 美元額度，不對提供商費率加價）。

您可以在模型名稱後添加路由後綴：`:fastest`（預設）、`:cheapest` 或 `:provider_name` 以強制使用特定後端。

基本 URL 可以透過 `HF_BASE_URL` 覆蓋。

## 自定義與自代管 LLM 提供商

Hermes Agent 支援 **任何 OpenAI 相容的 API 端點**。只要伺服器實現了 `/v1/chat/completions`，您就可以將 Hermes 指向它。這意味著您可以使用在地模型、GPU 推論伺服器、多提供商路由或任何第三方 API。

### 通用設定

配置自定義端點的三種方式：

**互動式設定 (建議)：**
```bash
hermes model
# 選擇 "Custom endpoint (self-hosted / VLLM / etc.)"
# 輸入：API 基本 URL、API 金鑰、模型名稱
```

**手動配置 (`config.yaml`)：**
```yaml
# 位於 ~/.hermes/config.yaml
model:
  default: your-model-name
  provider: custom
  base_url: http://localhost:8000/v1
  api_key: your-key-or-leave-empty-for-local
```

:::warning 舊版環境變數
`.env` 中的 `OPENAI_BASE_URL` 和 `LLM_MODEL` 已 **移除**。Hermes 的任何部分都不會再讀取這兩者 — `config.yaml` 是模型和端點配置的唯一事實來源。如果您在 `.env` 中有舊條目，它們將在下一次 `hermes setup` 或配置遷移時自動清除。請使用 `hermes model` 或直接編輯 `config.yaml`。
:::

兩種方法都會持久化到 `config.yaml` 中，它是模型、提供商和基本 URL 的事實來源。

### 使用 `/model` 切換模型

:::warning hermes model vs /model
**`hermes model`** (從您的終端機運行，在任何聊天工作階段之外) 是 **完整的提供商設定精靈**。使用它來新增提供商、運行 OAuth 流程、輸入 API 金鑰以及配置自定義端點。

**`/model`** (在活動的 Hermes 聊天工作階段中輸入) 只能在 **您已經設定好的提供商和模型之間切換**。它無法新增提供商、運行 OAuth 或提示輸入 API 金鑰。如果您只配置了一個提供商（例如 OpenRouter），`/model` 將僅顯示該提供商的模型。

**若要新增提供商：** 請先退出您的工作階段 (`Ctrl+C` 或 `/quit`)，運行 `hermes model`，設定新提供商，然後啟動新工作階段。
:::

一旦您配置了至少一個自定義端點，您就可以在工作階段中途切換模型：

```
/model custom:qwen-2.5          # 切換到您自定義端點上的模型
/model custom                    # 從端點自動偵測模型
/model openrouter:claude-sonnet-4 # 切換回雲端提供商
```

如果您配置了 **命名的自定義提供商** (見下文)，請使用三重語法：

```
/model custom:local:qwen-2.5    # 使用模型 qwen-2.5 的 "local" 自定義提供商
/model custom:work:llama3       # 使用 llama3 的 "work" 自定義提供商
```

切換提供商時，Hermes 會將基本 URL 和提供商持久化到配置中，以便在重啟後繼續有效。當從自定義端點切換回內建提供商時，過時的基本 URL 會自動清除。

:::tip
`/model custom` (僅此名稱，無模型名稱) 會查詢端點的 `/models` API，如果僅載入了一個模型，則會自動選擇該模型。這對於運行單個模型的在地伺服器非常有用。
:::

以下內容皆遵循此模式 — 只需更改網址、金鑰和模型名稱。

---

### Ollama — 在地模型，零配置

[Ollama](https://ollama.com/) 僅需一個指令即可在地運行開放權重模型。最適合：快速在地實驗、隱私敏感工作、離線使用。透過 OpenAI 相容 API 支援工具呼叫 (Tool Calling)。

```bash
# 安裝並運行模型
ollama pull qwen2.5-coder:32b
ollama serve   # 在埠 11434 啟動
```

然後配置 Hermes：

```bash
hermes model
# 選擇 "Custom endpoint (self-hosted / VLLM / etc.)"
# 輸入網址：http://localhost:11434/v1
# 跳過 API 金鑰 (Ollama 不需要)
# 輸入模型名稱 (例如 qwen2.5-coder:32b)
```

或直接配置 `config.yaml`：

```yaml
model:
  default: qwen2.5-coder:32b
  provider: custom
  base_url: http://localhost:11434/v1
  context_length: 32768   # 請參閱下方的警告
```

:::caution Ollama 預設使用非常低的上下文長度
Ollama 預設 **不會** 使用模型的完整上下文窗口。根據您的 VRAM，預設值為：

| 可用 VRAM | 預設上下文 |
|----------------|----------------|
| 少於 24 GB | **4,096 tokens** |
| 24–48 GB | 32,768 tokens |
| 48+ GB | 256,000 tokens |

對於帶有工具的代理用途，**您至少需要 16k–32k 的上下文**。在 4k 時，僅系統提示詞 + 工具結構定義 (schemas) 就可能填滿窗口，導致沒有對話空間。

**如何增加它** (選擇其一)：

```bash
# 選項 1：透過環境變數進行全伺服器設定 (建議)
OLLAMA_CONTEXT_LENGTH=32768 ollama serve

# 選項 2：針對 systemd 管理的 Ollama
sudo systemctl edit ollama.service
# 添加：Environment="OLLAMA_CONTEXT_LENGTH=32768"
# 然後：sudo systemctl daemon-reload && sudo systemctl restart ollama

# 選項 3：將其封裝在自定義模型中 (針對每個模型持久化)
echo -e "FROM qwen2.5-coder:32b\nPARAMETER num_ctx 32768" > Modelfile
ollama create qwen2.5-coder-32k -f Modelfile
```

**您無法透過 OpenAI 相容 API (`/v1/chat/completions`) 設定上下文長度**。它必須在伺服器端或透過 Modelfile 配置。這是將 Ollama 與 Hermes 等工具整合時最常見的困惑來源。
:::

**驗證您的上下文設定是否正確：**

```bash
ollama ps
# 查看 CONTEXT 欄位 — 它應該顯示您配置的值
```

:::tip
使用 `ollama list` 列出可用模型。使用 `ollama pull <model>` 從 [Ollama library](https://ollama.com/library) 獲取任何模型。Ollama 會自動處理 GPU 卸載 (offloading) — 大多數設定無需配置。
:::

---

### vLLM — 高效能 GPU 推論

[vLLM](https://docs.vllm.ai/) 是生產環境 LLM 服務的標準。最適合：在 GPU 硬體上實現最大吞吐量、服務大型模型、連續批次處理。

```bash
pip install vllm
vllm serve meta-llama/Llama-3.1-70B-Instruct \
  --port 8000 \
  --max-model-len 65536 \
  --tensor-parallel-size 2 \
  --enable-auto-tool-choice \
  --tool-call-parser hermes
```

然後配置 Hermes：

```bash
hermes model
# 選擇 "Custom endpoint (self-hosted / VLLM / etc.)"
# 輸入網址：http://localhost:8000/v1
# 跳過 API 金鑰 (或者輸入金鑰，如果您為 vLLM 配置了 --api-key)
# 輸入模型名稱：meta-llama/Llama-3.1-70B-Instruct
```

**上下文長度：** vLLM 預設讀取模型的 `max_position_embeddings`。如果超過您的 GPU 記憶體，它會報錯並要求您調低 `--max-model-len`。您也可以使用 `--max-model-len auto` 來自動尋找適合的最大值。設定 `--gpu-memory-utilization 0.95` (預設 0.9) 以將更多上下文擠入 VRAM。

**工具呼叫需要顯式標記：**

| 標記 | 用途 |
|------|---------|
| `--enable-auto-tool-choice` | `tool_choice: "auto"` 所必需 (Hermes 的預設值) |
| `--tool-call-parser <name>` | 模型工具呼叫格式的解析器 |

支援的解析器：`hermes` (Qwen 2.5, Hermes 2/3)、`llama3_json` (Llama 3.x)、`mistral`、`deepseek_v3`、`deepseek_v31`、`xlam`、`pythonic`。沒有這些標記，工具呼叫將無法運作 — 模型將以文字形式輸出工具呼叫。

:::tip
vLLM 支援人類可讀的大小：`--max-model-len 64k` (小寫 k = 1000, 大寫 K = 1024)。
:::

---

### SGLang — 具備 RadixAttention 的快速服務

[SGLang](https://github.com/sgl-project/sglang) 是具備 RadixAttention 功能的 vLLM 替代方案，可用於 KV 快取重用。最適合：多輪對話 (前綴快取)、受限解碼、結構化輸出。

```bash
pip install "sglang[all]"
python -m sglang.launch_server \
  --model meta-llama/Llama-3.1-70B-Instruct \
  --port 30000 \
  --context-length 65536 \
  --tp 2 \
  --tool-call-parser qwen
```

然後配置 Hermes：

```bash
hermes model
# 選擇 "Custom endpoint (self-hosted / VLLM / etc.)"
# 輸入網址：http://localhost:30000/v1
# 輸入模型名稱：meta-llama/Llama-3.1-70B-Instruct
```

**上下文長度：** SGLang 預設從模型配置中讀取。使用 `--context-length` 進行覆蓋。如果您需要超過模型聲明的最大值，請設定 `SGLANG_ALLOW_OVERWRITE_LONGER_CONTEXT_LEN=1`。

**工具呼叫：** 針對您的模型系列使用 `--tool-call-parser` 配合適當的解析器：`qwen` (Qwen 2.5)、`llama3`、`llama4`、`deepseekv3`、`mistral`、`glm`。沒有此標記，工具呼叫將作為純文字返回。

:::caution SGLang 預設最大輸出 tokens 為 128
如果回應似乎被截斷，請在請求中添加 `max_tokens` 或在伺服器上設定 `--default-max-tokens`。如果請求中未指定，SGLang 的預設值僅為每個回應 128 個 tokens。
:::

---

### llama.cpp / llama-server — CPU 與 Metal 推論

[llama.cpp](https://github.com/ggml-org/llama.cpp) 在 CPU、Apple Silicon (Metal) 和消費級 GPU 上運行量化模型。最適合：在沒有資料中心 GPU 的情況下運行模型、Mac 使用者、邊緣部署。

```bash
# 編譯並啟動 llama-server
cmake -B build && cmake --build build --config Release
./build/bin/llama-server \
  --jinja -fa \
  -c 32768 \
  -ngl 99 \
  -m models/qwen2.5-coder-32b-instruct-Q4_K_M.gguf \
  --port 8080 --host 0.0.0.0
```

**上下文長度 (`-c`)：** 最近的版本預設為 `0`，這會從 GGUF 元數據中讀取模型的訓練上下文。對於具備 128k+ 訓練上下文的模型，這可能會在嘗試分配完整的 KV 快取時導致記憶體不足 (OOM)。請將 `-c` 顯式設定為您需要的大小 (32k–64k 是代理使用的合適範圍)。如果使用平行槽 (`-np`)，總上下文會分配給各個槽 — 使用 `-c 32768 -np 4`，每個槽僅獲得 8k。

然後將 Hermes 指向它：

```bash
hermes model
# 選擇 "Custom endpoint (self-hosted / VLLM / etc.)"
# 輸入網址：http://localhost:8080/v1
# 跳過 API 金鑰 (在地伺服器不需要)
# 輸入模型名稱 — 或者如果僅載入了一個模型，則留空以自動偵測
```

這會將端點儲存到 `config.yaml` 中，以便跨工作階段持久存在。

:::caution 工具呼叫需要 `--jinja`
沒有 `--jinja`，llama-server 會完全忽略 `tools` 參數。模型會嘗試在回應文字中編寫 JSON 來呼叫工具，但 Hermes 不會將其識別為工具呼叫 — 您會看到原始 JSON (如 `{"name": "web_search", ...}`) 被印出為訊息，而不是實際的搜尋。

原生工具呼叫支援 (效能最佳)：Llama 3.x、Qwen 2.5 (包括 Coder)、Hermes 2/3、Mistral、DeepSeek、Functionary。所有其他模型使用通用處理程序，雖然可行但效能較低。請參閱 [llama.cpp 函式呼叫文件](https://github.com/ggml-org/llama.cpp/blob/master/docs/function-calling.md) 以獲取完整列表。

您可以透過檢查 `http://localhost:8080/props` 來驗證工具支援是否已啟用 — `chat_template` 欄位應該存在。
:::

:::tip
從 [Hugging Face](https://huggingface.co/models?library=gguf) 下載 GGUF 模型。Q4_K_M 量化在品質與記憶體使用量之間提供了最佳平衡。
:::

---

### LM Studio — 具備在地模型的桌面應用程式

[LM Studio](https://lmstudio.ai/) 是一款具有 GUI 且可運行在地模型的桌面應用程式。最適合：偏好視覺介面的使用者、快速模型測試、macOS/Windows/Linux 開發者。

從 LM Studio 應用程式啟動伺服器 (Developer 標籤 → Start Server)，或使用 CLI：

```bash
lms server start                        # 在埠 1234 啟動
lms load qwen2.5-coder --context-length 32768
```

然後配置 Hermes：

```bash
hermes model
# 選擇 "Custom endpoint (self-hosted / VLLM / etc.)"
# 輸入網址：http://localhost:1234/v1
# 跳過 API 金鑰 (LM Studio 不需要)
# 輸入模型名稱
```

:::caution 上下文長度通常預設為 2048
LM Studio 從模型的元數據中讀取上下文長度，但許多 GGUF 模型報告的預設值很低 (2048 或 4096)。**請務必顯式設定上下文長度**：

1. 點擊模型選擇器旁的齒輪圖示
2. 將 "Context Length" 設定為至少 16384 (建議 32768)
3. 重新載入模型以使更改生效

或者使用 CLI：`lms load model-name --context-length 32768`

若要設定每個模型的永久預設值：My Models 標籤 → 模型上的齒輪圖示 → 設定 context size。
:::

**工具呼叫：** 自 LM Studio 0.3.6 起支援。經過原生工具呼叫訓練的模型 (Qwen 2.5, Llama 3.x, Mistral, Hermes) 會被自動偵測並顯示工具圖標。其他模型使用通用備援，可能較不可靠。

---

### WSL2 網路 (Windows 使用者)

由於 Hermes Agent 需要 Unix 環境，Windows 使用者需在 WSL2 中運行。如果您的模型伺服器 (Ollama, LM Studio 等) 運行在 **Windows 主機**上，您需要彌補網路差距 — WSL2 使用具備自身子網的虛擬網路介面卡，因此 WSL2 內部的 `localhost` 指的是 Linux VM，而非 Windows 主機。

:::tip 兩者都在 WSL2 中？沒問題。
如果您的模型伺服器也運行在 WSL2 中 (vLLM、SGLang 和 llama-server 常用)，`localhost` 將按預期運作 — 它們共享同一個網路命名空間。請跳過本節。
:::

#### 選項 1：鏡像網路模式 (鏡像模式，推薦)

在 **Windows 11 22H2+** 中可用，鏡像模式使 `localhost` 在 Windows 和 WSL2 之間雙向運作 — 這是最簡單的修復方法。

1. 建立或編輯 `%USERPROFILE%\.wslconfig` (例如 `C:\Users\您的名稱\.wslconfig`)：
   ```ini
   [wsl2]
   networkingMode=mirrored
   ```

2. 從 PowerShell 重啟 WSL：
   ```powershell
   wsl --shutdown
   ```

3. 重新開啟 WSL2 終端機。`localhost` 現在可以存取 Windows 服務：
   ```bash
   curl http://localhost:11434/v1/models   # Windows 上的 Ollama — 有效
   ```

:::note Hyper-V 防火牆
在某些 Windows 11 版本上，Hyper-V 防火牆預設會阻擋鏡像連接。如果啟用鏡像模式後 `localhost` 仍無法運作，請在 **管理員 PowerShell** 中運行以下指令：
```powershell
Set-NetFirewallHyperVVMSetting -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -DefaultInboundAction Allow
```
:::

#### 選項 2：使用 Windows 主機 IP (Windows 10 / 較舊版本)

如果您無法使用鏡像模式，請從 WSL2 內部找到 Windows 主機 IP，並使用該 IP 代替 `localhost`：

```bash
# 獲取 Windows 主機 IP (WSL2 虛擬網路的預設閘道)
ip route show | grep -i default | awk '{ print $3 }'
# 範例輸出：172.29.192.1
```

在您的 Hermes 配置中使用該 IP：

```yaml
model:
  default: qwen2.5-coder:32b
  provider: custom
  base_url: http://172.29.192.1:11434/v1   # 使用 Windows 主機 IP，而非 localhost
```

:::tip 動態輔助工具
主機 IP 可能隨 WSL2 重啟而改變。您可以在 shell 中動態獲取：
```bash
export WSL_HOST=$(ip route show | grep -i default | awk '{ print $3 }')
echo "Windows host at: $WSL_HOST"
curl http://$WS_HOST:11434/v1/models   # 測試 Ollama
```

或使用您機器的 mDNS 名稱 (需要在 WSL2 中安裝 `libnss-mdns`)：
```bash
sudo apt install libnss-mdns
curl http://$(hostname).local:11434/v1/models
```
:::

#### 伺服器綁定地址 (NAT 模式必需)

如果您使用 **選項 2** (具備主機 IP 的 NAT 模式)，Windows 上的模型伺服器必須接受來自 `127.0.0.1` 以外的連接。預設情況下，大多數伺服器僅監聽 localhost — NAT 模式下的 WSL2 連接來自不同的虛擬子網，將被拒絕。在鏡像模式下，`localhost` 會直接映射，因此預設的 `127.0.0.1` 綁定可以正常工作。

| 伺服器 | 預設綁定 | 如何修復 |
|--------|-------------|------------|
| **Ollama** | `127.0.0.1` | 在啟動 Ollama 前設定 `OLLAMA_HOST=0.0.0.0` 環境變數 (Windows 系統設定 → 環境變數，或編輯 Ollama 服務) |
| **LM Studio** | `127.0.0.1` | 在 Developer 標籤 → Server settings 中啟用 **"Serve on Network"** |
| **llama-server** | `127.0.0.1` | 在啟動指令中添加 `--host 0.0.0.0` |
| **vLLM** | `0.0.0.0` | 預設已綁定到所有介面 |
| **SGLang** | `127.0.0.1` | 在啟動指令中添加 `--host 0.0.0.0` |

**Windows 上的 Ollama (詳細步驟)：** Ollama 作為 Windows 服務運行。若要設定 `OLLAMA_HOST`：
1. 開啟 **系統屬性** → **環境變數**
2. 新增 **系統變數**：`OLLAMA_HOST` = `0.0.0.0`
3. 重啟 Ollama 服務 (或重啟電腦)

#### Windows 防火牆

Windows 防火牆將 WSL2 視為單獨的網路 (無論是 NAT 還是鏡像模式)。如果完成上述步驟後連接仍失敗，請為您的模型伺服器埠添加防火牆規則：

```powershell
# 在管理員 PowerShell 中運行 — 將 PORT 替換為您的伺服器埠
New-NetFirewallRule -DisplayName "Allow WSL2 to Model Server" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 11434
```

常見埠：Ollama `11434`、vLLM `8000`、SGLang `30000`、llama-server `8080`、LM Studio `1234`。

#### 快速驗證

從 WSL2 內部，測試您是否可以連上模型伺服器：

```bash
# 將網址替換為您的伺服器位址與埠
curl http://localhost:11434/v1/models          # 鏡像模式
curl http://172.29.192.1:11434/v1/models       # NAT 模式 (使用您的實際主機 IP)
```

如果您收到列出模型的 JSON 回應，則表示成功。請將該網址作為 Hermes 配置中的 `base_url`。

---

### 在地模型疑難排解

這些問題會影響所有與 Hermes 配合使用的在地推論伺服器。

#### 從 WSL2 到 Windows 代管模型伺服器的 "Connection refused"

如果您在 WSL2 中運行 Hermes 並在 Windows 主機上運行模型伺服器，`http://localhost:<port>` 在 WSL2 預設的 NAT 網路模式下將無法運作。請參閱上方的 [WSL2 網路](#wsl2-網路-windows-使用者) 進行修復。

#### 工具呼叫顯示為文字而非執行

模型輸出了類似 `{"name": "web_search", "arguments": {...}}` 的訊息，而不是實際呼叫工具。

**原因：** 您的伺服器未啟用工具呼叫，或者模型不支援透過該伺服器的工具呼叫實作。

| 伺服器 | 修復方法 |
|--------|-----|
| **llama.cpp** | 在啟動指令中添加 `--jinja` |
| **vLLM** | 添加 `--enable-auto-tool-choice --tool-call-parser hermes` |
| **SGLang** | 添加 `--tool-call-parser qwen` (或適當的解析器) |
| **Ollama** | 工具呼叫預設已啟用 — 請確保模型支援 (透過 `ollama show model-name` 檢查) |
| **LM Studio** | 更新至 0.3.6+ 並使用具備原生工具支援的模型 |

#### 模型似乎遺忘上下文或給出不連貫的回應

**原因：** 上下文窗口太小。當對話超過上下文限制時，大多數伺服器會默默丟棄較舊的訊息。Hermes 的系統提示詞 + 工具結構定義僅此兩項就可能使用 4k–8k tokens。

**診斷方式：**

```bash
# 檢查 Hermes 認定的上下文大小
# 查看啟動行："Context limit: X tokens"

# 檢查您伺服器的實際上下文
# Ollama：ollama ps (CONTEXT 欄位)
# llama.cpp：curl http://localhost:8080/props | jq '.default_generation_settings.n_ctx'
# vLLM：檢查啟動參數中的 --max-model-len
```

**修復：** 針對代理用途，將上下文設定為至少 **32,768 tokens**。請參閱上方各伺服器章節中的特定標記。

#### 啟動時顯示 "Context limit: 2048 tokens"

Hermes 從您伺服器的 `/v1/models` 端點自動偵測上下文長度。如果伺服器報告的值很低 (或根本沒報告)，Hermes 會使用模型聲明的限制，但這可能是錯誤的。

**修復：** 在 `config.yaml` 中顯式設定：

```yaml
model:
  default: your-model
  provider: custom
  base_url: http://localhost:11434/v1
  context_length: 32768
```

#### 回應在句中被切斷

**可能原因：**
1. **伺服器上的輸出上限 (`max_tokens`) 太低** — SGLang 預設每個回應 128 tokens。在伺服器上設定 `--default-max-tokens` 或在 config.yaml 中配置 Hermes 的 `model.max_tokens`。注意：`max_tokens` 僅控制回應長度 — 它與對話歷史長度 (`context_length`) 無關。
2. **上下文耗盡** — 模型填滿了其上下文窗口。請增加 `model.context_length` 或在 Hermes 中啟用 [上下文壓縮](/docs/user-guide/configuration#context-compression)。

---

### LiteLLM Proxy — 多提供商網關

[LiteLLM](https://docs.litellm.ai/) 是一款相容 OpenAI 的代理工具，可將 100 多個 LLM 提供商整合在單一 API 後。最適合：無需更改配置即可切換提供商、負載均衡、備援鏈、預算控制。

```bash
# 安裝並啟動
pip install "litellm[proxy]"
litellm --model anthropic/claude-sonnet-4 --port 4000

# 或者使用配置檔案管理多個模型：
litellm --config litellm_config.yaml --port 4000
```

然後透過 `hermes model` → Custom endpoint → `http://localhost:4000/v1` 配置 Hermes。

包含備援機制的 `litellm_config.yaml` 範例：
```yaml
model_list:
  - model_name: "best"
    litellm_params:
      model: anthropic/claude-sonnet-4
      api_key: sk-ant-...
  - model_name: "best"
    litellm_params:
      model: openai/gpt-4o
      api_key: sk-...
router_settings:
  routing_strategy: "latency-based-routing"
```

---

### ClawRouter — 成本優化路由

BlockRunAI 的 [ClawRouter](https://github.com/BlockRunAI/ClawRouter) 是一款在地路由代理，可根據查詢複雜度自動選擇模型。它從 14 個維度對請求進行分類，並路由到能處理該任務的最便宜模型。支付方式為 USDC 加密貨幣 (無需 API 金鑰)。

```bash
# 安裝並啟動
npx @blockrun/clawrouter    # 在埠 8402 啟動
```

然後透過 `hermes model` → Custom endpoint → `http://localhost:8402/v1` → 模型名稱 `blockrun/auto` 配置 Hermes。

路由配置文件：
| 配置文件 | 策略 | 節省比例 |
|---------|----------|---------|
| `blockrun/auto` | 平衡品質/成本 | 74-100% |
| `blockrun/eco` | 盡可能最便宜 | 95-100% |
| `blockrun/premium` | 最佳品質模型 | 0% |
| `blockrun/free` | 僅限免費模型 | 100% |
| `blockrun/agentic` | 針對工具呼叫優化 | 變動 |

:::note
ClawRouter 需要在 Base 或 Solana 上擁有 USDC 資金的錢包來支付。所有請求都透過 BlockRun 的後端 API 路由。運行 `npx @blockrun/clawrouter doctor` 檢查錢包狀態。
:::

---

### 其他相容提供商

任何具有 OpenAI 相容 API 的服務皆可使用。一些熱門選項：

| 提供商 | 基本 URL | 說明 |
|----------|----------|-------|
| [Together AI](https://together.ai) | `https://api.together.xyz/v1` | 雲端代管的開放模型 |
| [Groq](https://groq.com) | `https://api.groq.com/openai/v1` | 極速推論 |
| [DeepSeek (深度求索)](https://deepseek.com) | `https://api.deepseek.com/v1` | DeepSeek 模型 |
| [Fireworks AI](https://fireworks.ai) | `https://api.fireworks.ai/inference/v1` | 快速開放模型代管 |
| [Cerebras](https://cerebras.ai) | `https://api.cerebras.ai/v1` | 晶圓級晶片推論 |
| [Mistral AI](https://mistral.ai) | `https://api.mistral.ai/v1` | Mistral 模型 |
| [OpenAI](https://openai.com) | `https://api.openai.com/v1` | 直接存取 OpenAI |
| [Azure OpenAI](https://azure.microsoft.com) | `https://YOUR.openai.azure.com/` | 企業級 OpenAI |
| [LocalAI](https://localai.io) | `http://localhost:8080/v1` | 自代管、多模型 |
| [Jan](https://jan.ai) | `http://localhost:1337/v1` | 具備在地模型的桌面應用程式 |

透過 `hermes model` → Custom endpoint 或在 `config.yaml` 中配置上述任何一項：

```yaml
model:
  default: meta-llama/Llama-3.1-70B-Instruct-Turbo
  provider: custom
  base_url: https://api.together.xyz/v1
  api_key: your-together-key
```

---

### 上下文長度偵測

:::note 兩個容易混淆的設定
**`context_length`** 是 **總上下文窗口** — 輸入 *與* 輸出 tokens 的組合預算 (例如 Claude Opus 4.6 為 200,000)。Hermes 利用此設定來決定何時壓縮歷史記錄以及驗證 API 請求。

**`model.max_tokens`** 是 **輸出上限** — 模型在 *單次回應* 中可生成的最大 token 數量。它與對話歷史長度無關。業界標準名稱 `max_tokens` 是常見的混淆來源；Anthropic 的原生 API 已將其更名為 `max_output_tokens` 以求清晰。

當自動偵測的窗口大小不正確時，請設定 `context_length`。
僅在需要限制單次回應長度時設定 `model.max_tokens`。
:::

Hermes 使用多源解析鏈來偵測模型和提供商正確的上下文窗口：

1. **Config 覆蓋** — config.yaml 中的 `model.context_length` (最高優先級)
2. **按模型的自定義提供商** — `custom_providers[].models.<id>.context_length`
3. **持久化快取** — 先前偵測到的值 (在重啟後保留)
4. **端點 `/models`** — 查詢您的伺服器 API (在地/自定義端點)
5. **Anthropic `/v1/models`** — 向 Anthropic API 查詢 `max_input_tokens` (僅限 API 金鑰使用者)
6. **OpenRouter API** — 來自 OpenRouter 的即時模型元數據
7. **Nous Portal** — 將 Nous 模型 ID 的後綴與 OpenRouter 元數據進行匹配
8. **[models.dev](https://models.dev)** — 社群維護的註冊庫，包含 100 多個提供商、3800 多個模型的特定上下文長度
9. **備援預設值** — 廣泛的模型系列模式 (預設 128K)

對於大多數設定，這都是開箱即用的。該系統具備提供商感知能力 — 根據提供商的不同，同一個模型可能會有不同的上下文限制 (例如，`claude-opus-4.6` 在 Anthropic 直接存取時為 1M，但在 GitHub Copilot 上為 128K)。

若要顯式設定上下文長度，請在模型配置中添加 `context_length`：

```yaml
model:
  default: "qwen3.5:9b"
  base_url: "http://localhost:8080/v1"
  context_length: 131072  # tokens
```

針對自定義端點，您也可以為每個模型設定上下文長度：

```yaml
custom_providers:
  - name: "My Local LLM"
    base_url: "http://localhost:11434/v1"
    models:
      qwen3.5:27b:
        context_length: 32768
      deepseek-r1:70b:
        context_length: 65536
```

`hermes model` 在配置自定義端點時會提示輸入上下文長度。留空則使用自動偵測。

:::tip 何時需要手動設定
- 您在 Ollama 中設定了低於模型最大值的自定義 `num_ctx`
- 您想將上下文限制在模型最大值以下 (例如在 128k 模型上設為 8k 以節省 VRAM)
- 您正在不公開 `/v1/models` 的代理伺服器後方運行
:::

---

### 命名的自定義提供商

如果您使用多個自定義端點 (例如一個在地開發伺服器和一個遠端 GPU 伺服器)，您可以在 `config.yaml` 中將其定義為命名的自定義提供商：

```yaml
custom_providers:
  - name: local
    base_url: http://localhost:8080/v1
    # api_key 已省略 — Hermes 對於無需金鑰的在地伺服器使用 "no-key-required"
  - name: work
    base_url: https://gpu-server.internal.corp/v1
    api_key: corp-api-key
    api_mode: chat_completions   # 選填，從網址自動偵測
  - name: anthropic-proxy
    base_url: https://proxy.example.com/anthropic
    api_key: proxy-key
    api_mode: anthropic_messages  # 用於 Anthropic 相容代理
```

在工作階段中途使用三重語法在它們之間切換：

```
/model custom:local:qwen-2.5       # 使用 "local" 端點配合 qwen-2.5
/model custom:work:llama3-70b      # 使用 "work" 端點配合 llama3-70b
/model custom:anthropic-proxy:claude-sonnet-4  # 使用代理伺服器
```

您也可以從 `hermes model` 互動選單中選擇命名的自定義提供商。

---

### 選擇正確的設定

| 使用情境 | 建議方案 |
|----------|-------------|
| **只想能用就好** | OpenRouter (預設) 或 Nous Portal |
| **在地模型，簡易設定** | Ollama |
| **生產環境 GPU 服務** | vLLM 或 SGLang |
| **Mac / 無 GPU** | Ollama 或 llama.cpp |
| **多提供商路由** | LiteLLM Proxy 或 OpenRouter |
| **成本優化** | ClawRouter 或具備 `sort: "price"` 的 OpenRouter |
| **最大程度隱私** | Ollama, vLLM 或 llama.cpp (完全在地) |
| **企業級 / Azure** | 具備自定義端點的 Azure OpenAI |
| **中文 AI 模型** | z.ai (智譜清言), Kimi/Moonshot (`kimi-coding` 或 `kimi-coding-cn`), MiniMax 或 小米 MiMo (一等公民提供商) |

:::tip
您可以隨時透過 `hermes model` 切換提供商 — 無需重啟。無論您使用哪個提供商，您的對話歷史、記憶和技能都會保留。
:::

## 選填 API 金鑰

| 功能 | 提供商 | 環境變數 |
|---------|----------|--------------|
| 網頁爬取 | [Firecrawl](https://firecrawl.dev/) | `FIRECRAWL_API_KEY`, `FIRECRAWL_API_URL` |
| 瀏覽器自動化 | [Browserbase](https://browserbase.com/) | `BROWSERBASE_API_KEY`, `BROWSERBASE_PROJECT_ID` |
| 圖片生成 | [FAL](https://fal.ai/) | `FAL_KEY` |
| 進階 TTS 音色 | [ElevenLabs](https://elevenlabs.io/) | `ELEVENLABS_API_KEY` |
| OpenAI TTS + 語音轉錄 | [OpenAI](https://platform.openai.com/api-keys) | `VOICE_TOOLS_OPENAI_KEY` |
| Mistral TTS + 語音轉錄 | [Mistral](https://console.mistral.ai/) | `MISTRAL_API_KEY` |
| RL 訓練 | [Tinker](https://tinker-console.thinkingmachines.ai/) + [WandB](https://wandb.ai/) | `TINKER_API_KEY`, `WANDB_API_KEY` |
| 跨工作階段使用者建模 | [Honcho](https://honcho.dev/) | `HONCHO_API_KEY` |
| 語義長期記憶 | [Supermemory](https://supermemory.ai) | `SUPERMEMORY_API_KEY` |

### 自代管 Firecrawl

預設情況下，Hermes 使用 [Firecrawl 雲端 API](https://firecrawl.dev/) 進行網頁搜尋和爬取。如果您偏好在地運行 Firecrawl，可以將 Hermes 指向自代管實例。請參閱 Firecrawl 的 [SELF_HOST.md](https://github.com/firecrawl/firecrawl/blob/main/SELF_HOST.md) 瞭解完整設定說明。

**優點：** 無需 API 金鑰、無速率限制、無單頁成本、完全的數據主權。

**缺點：** 雲端版本使用 Firecrawl 專有的 "Fire-engine" 來進行進階的反機器人繞過 (Cloudflare, CAPTCHAs, IP 輪換)。自代管版本使用基礎的 fetch + Playwright，因此某些受保護的網站可能會失敗。搜尋功能會使用 DuckDuckGo 而非 Google。

**設定步驟：**

1. 複製並啟動 Firecrawl Docker 堆疊 (5 個容器：API、Playwright、Redis、RabbitMQ、PostgreSQL — 需要約 4-8 GB RAM)：
   ```bash
   git clone https://github.com/firecrawl/firecrawl
   cd firecrawl
   # 在 .env 中設定：USE_DB_AUTHENTICATION=false, HOST=0.0.0.0, PORT=3002
   docker compose up -d
   ```

2. 將 Hermes 指向您的實例 (無需 API 金鑰)：
   ```bash
   hermes config set FIRECRAWL_API_URL http://localhost:3002
   ```

如果您的自代管實例啟用了驗證，您也可以同時設定 `FIRECRAWL_API_KEY` 和 `FIRECRAWL_API_URL`。

## OpenRouter 提供商路由

使用 OpenRouter 時，您可以控制請求如何在提供商之間進行路由。在 `~/.hermes/config.yaml` 中添加 `provider_routing` 區段：

```yaml
provider_routing:
  sort: "throughput"          # "price" (預設), "throughput" 或 "latency"
  # only: ["anthropic"]      # 僅使用這些提供商
  # ignore: ["deepinfra"]    # 跳過這些提供商
  # order: ["anthropic", "google"]  # 按此順序嘗試提供商
  # require_parameters: true  # 僅使用支援所有請求參數的提供商
  # data_collection: "deny"   # 排除可能儲存/訓練數據的提供商
```

**簡寫：** 在任何模型名稱後加上 `:nitro` 以按吞吐量排序 (例如 `anthropic/claude-sonnet-4:nitro`)，或加上 `:floor` 以按價格排序。

## 備用模型 (Fallback Model)

配置備用提供商:模型，當您的主模型失敗 (速率限制、伺服器錯誤、驗證失敗) 時，Hermes 會自動切換到該模型：

```yaml
fallback_model:
  provider: openrouter                    # 必需
  model: anthropic/claude-sonnet-4        # 必需
  # base_url: http://localhost:8000/v1    # 選填，用於自定義端點
  # api_key_env: MY_CUSTOM_KEY           # 選填，用於自定義端點 API 金鑰的環境變數名稱
```

當啟動時，備用機制會在工作階段中途切換模型和提供商，且不會丟失對話。每個工作階段 **最多觸發一次**。

支援的提供商：`openrouter`、`nous`、`openai-codex`、`copilot`、`copilot-acp`、`anthropic`、`huggingface`、`zai`、`kimi-coding`、`kimi-coding-cn`、`minimax`、`minimax-cn`、`deepseek`、`ai-gateway`、`opencode-zen`、`opencode-go`、`kilocode`、`xiaomi`、`arcee`、`alibaba`、`custom`。

:::tip
備用機制僅透過 `config.yaml` 配置 — 沒有對應的環境變數。關於何時觸發、支援的提供商以及它如何與輔助任務和委派互動的完整詳細資訊，請參閱 [備用提供商](/docs/user-guide/features/fallback-providers)。
:::

## 智慧模型路由 (Smart Model Routing)

選配的「便宜對比強大」路由讓 Hermes 能夠將複雜工作交給主模型，而將非常簡短/簡單的對話發送給較便宜的模型。

```yaml
smart_model_routing:
  enabled: true
  max_simple_chars: 160
  max_simple_words: 28
  cheap_model:
    provider: openrouter
    model: google/gemini-2.5-flash
    # base_url: http://localhost:8000/v1  # 選填自定義端點
    # api_key_env: MY_CUSTOM_KEY          # 選填該端點的 API 金鑰環境變數
```

工作原理：
- 如果對話簡短、單行，且看起來不像是沉重的代碼/工具/除錯任務，Hermes 可能會將其路由到 `cheap_model`
- 如果對話看起來很複雜，Hermes 會保留在您的主模型/提供商上
- 如果便宜路由無法清晰解析，Hermes 會自動退回到主模型

此功能被設計為保守的。它旨在用於快速、低風險的對話，例如：
- 簡短的事實性問題
- 快速改寫
- 輕量級摘要

它會避免路由如下提示：
- 代碼/除錯工作
- 頻繁使用工具的請求
- 長篇或多行的分析要求

當您想要較低延遲或成本，但不想完全更改預設模型時，請使用此功能。

---

## 另請參閱

- [配置](/docs/user-guide/configuration) — 一般配置 (目錄結構、配置優先級、終端機後端、記憶、壓縮等)
- [環境變數](/docs/reference/environment-variables) — 所有環境變數的完整參考
