---
title: 備援提供者 (Fallback Providers)
description: 設定當您的主要模型不可用時，自動故障轉移到備援大型語言模型 (LLM) 提供者。
sidebar_label: 備援提供者
sidebar_position: 8
---

# 備援提供者 (Fallback Providers)

Hermes Agent 擁有三層彈性機制，可在提供者出現問題時保持您的會話運行：

1. **[憑證池 (Credential pools)](./credential-pools.md)** — 在*同一個*提供者的多個 API 金鑰之間輪換（最先嘗試）。
2. **主模型備援** — 當您的主模型失敗時，自動切換到*不同*的提供者或模型。
3. **輔助任務備援** — 為視覺、壓縮和網頁擷取等輔助任務提供獨立的提供者解析機制。

憑證池處理同一個提供者的輪換（例如多個 OpenRouter 金鑰）。本頁面涵蓋跨提供者的備援機制。兩者皆為選用，且可獨立工作。

## 主模型備援

當您的主要 LLM 提供者遇到錯誤時（例如速率限制、伺服器過載、身份驗證失敗、連線中斷），Hermes 可以自動在會話中切換到備援提供者和模型配對，而不會丟失您的對話內容。

### 設定方式

在 `~/.hermes/config.yaml` 中新增 `fallback_model` 區段：

```yaml
fallback_model:
  provider: openrouter
  model: anthropic/claude-sonnet-4
```

`provider` 和 `model` 兩者皆為**必填**。如果缺少其中之一，則會停用備援機制。

### 支援的提供者

| 提供者 | 值 (Value) | 需求 |
|----------|-------|-------------|
| AI Gateway | `ai-gateway` | `AI_GATEWAY_API_KEY` |
| OpenRouter | `openrouter` | `OPENROUTER_API_KEY` |
| Nous Portal | `nous` | `hermes auth` (OAuth) |
| OpenAI Codex | `openai-codex` | `hermes model` (ChatGPT OAuth) |
| GitHub Copilot | `copilot` | `COPILOT_GITHUB_TOKEN`, `GH_TOKEN`, 或 `GITHUB_TOKEN` |
| GitHub Copilot ACP | `copilot-acp` | 外部程序（編輯器整合） |
| Anthropic | `anthropic` | `ANTHROPIC_API_KEY` 或 Claude Code 憑證 |
| z.ai / GLM | `zai` | `GLM_API_KEY` |
| Kimi / Moonshot | `kimi-coding` | `KIMI_API_KEY` |
| MiniMax | `minimax` | `MINIMAX_API_KEY` |
| MiniMax (China) | `minimax-cn` | `MINIMAX_CN_API_KEY` |
| DeepSeek | `deepseek` | `DEEPSEEK_API_KEY` |
| OpenCode Zen | `opencode-zen` | `OPENCODE_ZEN_API_KEY` |
| OpenCode Go | `opencode-go` | `OPENCODE_GO_API_KEY` |
| Kilo Code | `kilocode` | `KILOCODE_API_KEY` |
| Xiaomi MiMo | `xiaomi` | `XIAOMI_API_KEY` |
| Arcee AI | `arcee` | `ARCEEAI_API_KEY` |
| Alibaba / DashScope | `alibaba` | `DASHSCOPE_API_KEY` |
| Hugging Face | `huggingface` | `HF_TOKEN` |
| 自定義端點 | `custom` | `base_url` + `api_key_env`（見下文） |

### 自定義端點備援

對於相容於 OpenAI 的自定義端點，請新增 `base_url` 並且可以選填 `api_key_env`：

```yaml
fallback_model:
  provider: custom
  model: my-local-model
  base_url: http://localhost:8000/v1
  api_key_env: MY_LOCAL_KEY          # 包含 API 金鑰的環境變數名稱
```

### 備援觸發時機

當主模型因以下原因失敗時，備援會自動啟動：

- **速率限制 (Rate limits)** (HTTP 429) — 在耗盡重試次數後。
- **伺服器錯誤** (HTTP 500, 502, 503) — 在耗盡重試次數後。
- **身份驗證失敗** (HTTP 401, 403) — 立即觸發（重試無效）。
- **找不到項目 (Not found)** (HTTP 404) — 立即觸發。
- **無效的回應** — 當 API 重複返回格式錯誤或空回應時。

當觸發備援時，Hermes 會：

1. 解析備援提供者的憑證。
2. 建立新的 API 用戶端。
3. 原地更換模型、提供者和用戶端。
4. 重設重試計數器並繼續對話。

切換過程是無縫的 — 您的對話歷史記錄、工具調用和上下文都會被保留。代理程式會從中斷的地方繼續，只是改用不同的模型。

:::info 單次觸發 (One-Shot)
備援在每個會話中**最多啟動一次**。如果備援提供者也失敗了，則會由正常的錯誤處理接管（先重試，然後顯示錯誤訊息）。這可以防止產生級聯故障轉移迴圈。
:::

### 範例

**以 OpenRouter 作為 Anthropic 原生提供者的備援：**
```yaml
model:
  provider: anthropic
  default: claude-sonnet-4-6

fallback_model:
  provider: openrouter
  model: anthropic/claude-sonnet-4
```

**以 Nous Portal 作為 OpenRouter 的備援：**
```yaml
model:
  provider: openrouter
  default: anthropic/claude-opus-4

fallback_model:
  provider: nous
  model: nous-hermes-3
```

**以本地模型作為雲端服務的備援：**
```yaml
fallback_model:
  provider: custom
  model: llama-3.1-70b
  base_url: http://localhost:8000/v1
  api_key_env: LOCAL_API_KEY
```

**以 Codex OAuth 作為備援：**
```yaml
fallback_model:
  provider: openai-codex
  model: gpt-5.3-codex
```

### 支援備援的場景

| 上下文 | 支援備援 |
|---------|-------------------|
| CLI 會話 | ✔ |
| 通訊網關 (Telegram, Discord 等) | ✔ |
| 子代理委派 (Subagent delegation) | ✘ (子代理不會繼承備援設定) |
| 定時任務 (Cron jobs) | ✘ (以固定提供者執行) |
| 輔助任務 (視覺、壓縮) | ✘ (使用其自身的提供者鏈 — 見下文) |

:::tip
`fallback_model` 沒有環境變數設定 — 它是專門透過 `config.yaml` 配置的。這是刻意的設計：備援配置是一個審慎的選擇，不應該被過時的 shell 匯出環境變數所覆蓋。
:::

---

## 輔助任務備援

Hermes 為輔助任務使用獨立的輕量級模型。每個任務都有自己的提供者解析鏈，作為內建的備援系統。

### 具有獨立提供者解析機制的任務

| 任務 | 功能 | 設定金鑰 (Config Key) |
|------|-------------|-----------|
| 視覺 (Vision) | 圖片分析、瀏覽器截圖 | `auxiliary.vision` |
| 網頁擷取 (Web Extract) | 網頁摘要 | `auxiliary.web_extract` |
| 壓縮 (Compression) | 上下文壓縮摘要 | `auxiliary.compression` |
| 會話搜尋 (Session Search) | 過去會話的摘要 | `auxiliary.session_search` |
| 技能中心 (Skills Hub) | 技能搜尋與發現 | `auxiliary.skills_hub` |
| MCP | MCP 輔助操作 | `auxiliary.mcp` |
| 記憶體清除 (Memory Flush) | 記憶體合併 | `auxiliary.flush_memories` |

### 自動偵測鏈 (Auto-Detection Chain)

當任務的提供者設置為 `"auto"`（預設值）時，Hermes 會按順序嘗試提供者，直到其中一個成功為止：

**對於文字任務（壓縮、網頁擷取等）：**

```text
OpenRouter → Nous Portal → 自定義端點 → Codex OAuth →
API 金鑰提供者 (z.ai, Kimi, MiniMax, Xiaomi MiMo, Hugging Face, Anthropic) → 放棄
```

**對於視覺任務：**

```text
主要提供者（如果支援視覺能力）→ OpenRouter → Nous Portal →
Codex OAuth → Anthropic → 自定義端點 → 放棄
```

如果在調用時解析出的提供者失敗，Hermes 也會有內部重試機制：如果提供者不是 OpenRouter 且未設置明確的 `base_url`，它將嘗試 OpenRouter 作為最後手段的備援。

### 設定輔助提供者

每個任務都可以在 `config.yaml` 中獨立配置：

```yaml
auxiliary:
  vision:
    provider: "auto"              # auto | openrouter | nous | codex | main | anthropic
    model: ""                     # 例如 "openai/gpt-4o"
    base_url: ""                  # 直接端點（優先於提供者）
    api_key: ""                   # base_url 的 API 金鑰

  web_extract:
    provider: "auto"
    model: ""

  compression:
    provider: "auto"
    model: ""

  session_search:
    provider: "auto"
    model: ""

  skills_hub:
    provider: "auto"
    model: ""

  mcp:
    provider: "auto"
    model: ""

  flush_memories:
    provider: "auto"
    model: ""
```

上述每個任務都遵循相同的 **provider / model / base_url** 模式。上下文壓縮在 `auxiliary.compression` 下配置：

```yaml
auxiliary:
  compression:
    provider: main                                    # 與其他輔助任務相同的提供者選項
    model: google/gemini-3-flash-preview
    base_url: null                                    # 自定義相容於 OpenAI 的端點
```

而備援模型使用：

```yaml
fallback_model:
  provider: openrouter
  model: anthropic/claude-sonnet-4
  # base_url: http://localhost:8000/v1               # 選填自定義端點
```

這三者 — 輔助任務、壓縮、備援 — 的運作方式相同：設置 `provider` 來選擇處理請求的提供者，設置 `model` 來選擇模型，以及設置 `base_url` 來指向自定義端點（會覆蓋提供者）。

### 輔助任務的提供者選項

這些選項僅適用於 `auxiliary:`、`compression:` 和 `fallback_model:` 配置 — `"main"` **不是** 您頂層 `model.provider` 的有效值。對於自定義端點，請在您的 `model:` 區段中使用 `provider: custom`（參閱 [AI 提供者](/docs/integrations/providers)）。

| 提供者 | 說明 | 需求 |
|----------|-------------|-------------|
| `"auto"` | 按順序嘗試提供者，直到一個成功為止（預設） | 至少配置了一個提供者 |
| `"openrouter"` | 強制使用 OpenRouter | `OPENROUTER_API_KEY` |
| `"nous"` | 強制使用 Nous Portal | `hermes auth` |
| `"codex"` | 強制使用 Codex OAuth | `hermes model` → Codex |
| `"main"` | 使用主要代理使用的任何提供者（僅限輔助任務） | 已配置啟動中的主要提供者 |
| `"anthropic"` | 強制使用 Anthropic 原生提供者 | `ANTHROPIC_API_KEY` 或 Claude Code 憑證 |

### 直接端點覆蓋

對於任何輔助任務，設置 `base_url` 將跳過提供者解析，直接將請求發送到該端點：

```yaml
auxiliary:
  vision:
    base_url: "http://localhost:1234/v1"
    api_key: "local-key"
    model: "qwen2.5-vl"
```

`base_url` 的優先級高於 `provider`。Hermes 使用配置的 `api_key` 進行身份驗證，如果未設置，則退而求其次使用 `OPENAI_API_KEY`。它**不會**在自定義端點上重複使用 `OPENROUTER_API_KEY`。

---

## 上下文壓縮備援

上下文壓縮使用 `auxiliary.compression` 配置區塊來控制由哪個模型和提供者處理摘要：

```yaml
auxiliary:
  compression:
    provider: "auto"                              # auto | openrouter | nous | main
    model: "google/gemini-3-flash-preview"
```

:::info 舊版遷移
帶有 `compression.summary_model` / `compression.summary_provider` / `compression.summary_base_url` 的舊配置將在首次載入時自動遷移到 `auxiliary.compression.*`（配置版本 17）。
:::

如果沒有可用於壓縮的提供者，Hermes 將會直接丟棄中間的對話輪次而不生成摘要，而不是讓整個會話失敗。

---

## 委派提供者覆蓋

由 `delegate_task` 派生的子代理**不使用**主備援模型。但是，可以將它們導向到不同的提供者和模型配對，以優化成本：

```yaml
delegation:
  provider: "openrouter"                      # 為所有子代理覆蓋提供者
  model: "google/gemini-3-flash-preview"      # 覆蓋模型
  # base_url: "http://localhost:1234/v1"      # 或使用直接端點
  # api_key: "local-key"
```

如需完整配置詳細資訊，請參閱 [子代理委派](/docs/user-guide/features/delegation)。

---

## 定時任務提供者

定時任務 (Cron jobs) 以執行時配置的任何提供者運行。它們不支援備援模型。要為定時任務使用不同的提供者，請在定時任務本身配置 `provider` 和 `model` 覆蓋：

```python
cronjob(
    action="create",
    schedule="every 2h",
    prompt="檢查伺服器狀態",
    provider="openrouter",
    model="google/gemini-3-flash-preview"
)
```

如需完整配置詳細資訊，請參閱 [定時任務 (Cron)](/docs/user-guide/features/cron)。

---

## 總結

| 功能 | 備援機制 | 設定位置 |
|---------|-------------------|----------------|
| 主代理模型 | config.yaml 中的 `fallback_model` — 發生錯誤時單次故障轉移 | `fallback_model:` (頂層) |
| 視覺 (Vision) | 自動偵測鏈 + 內部 OpenRouter 重試 | `auxiliary.vision` |
| 網頁擷取 | 自動偵測鏈 + 內部 OpenRouter 重試 | `auxiliary.web_extract` |
| 上下文壓縮 | 自動偵測鏈，不可用時降級為不生成摘要 | `auxiliary.compression` |
| 會話搜尋 | 自動偵測鏈 | `auxiliary.session_search` |
| 技能中心 | 自動偵測鏈 | `auxiliary.skills_hub` |
| MCP 輔助工具 | 自動偵測鏈 | `auxiliary.mcp` |
| 記憶體清除 | 自動偵測鏈 | `auxiliary.flush_memories` |
| 委派 (Delegation) | 僅限提供者覆蓋（無自動備援） | `delegation.provider` / `delegation.model` |
| 定時任務 | 僅限個別任務提供者覆蓋（無自動備援） | 個別任務 `provider` / `model` |
