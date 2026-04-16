---
sidebar_position: 14
title: "AWS Bedrock"
description: "將 Hermes Agent 與 Amazon Bedrock 搭配使用 — 原生 Converse API、IAM 身份驗證、護欄 (Guardrails) 和跨區域推論"
---

# AWS Bedrock

Hermes Agent 支援將 Amazon Bedrock 作為原生供應商，使用的是 **Converse API** — 而非 OpenAI 相容的端點。這讓您可以完全存取 Bedrock 生態系統：IAM 身份驗證、護欄 (Guardrails)、跨區域推論描述檔以及所有的基礎模型。

## 先決條件

- **AWS 憑證** — [boto3 憑證鏈](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/credentials.html) 支援的任何來源：
  - IAM 實例角色 (EC2, ECS, Lambda — 無需額外設定)
  - `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` 環境變數
  - 用於 SSO 或具名描述檔的 `AWS_PROFILE`
  - 用於本地開發的 `aws configure`
- **boto3** — 使用 `pip install hermes-agent[bedrock]` 進行安裝
- **IAM 權限** — 至少包含：
  - `bedrock:InvokeModel` 和 `bedrock:InvokeModelWithResponseStream`（用於推論）
  - `bedrock:ListFoundationModels` 和 `bedrock:ListInferenceProfiles`（用於模型探索）

:::tip EC2 / ECS / Lambda
在 AWS 運算資源上，只需附加具有 `AmazonBedrockFullAccess` 權限的 IAM 角色即可完成設定。無需 API 金鑰，也無需配置 `.env` — Hermes 會自動偵測實例角色。
:::

## 快速入門

```bash
# 安裝 Bedrock 支援
pip install hermes-agent[bedrock]

# 選擇 Bedrock 作為供應商
hermes model
# → 選擇 "More providers..." → "AWS Bedrock"
# → 選擇您的區域和模型

# 開始對話
hermes chat
```

## 設定

執行 `hermes model` 後，您的 `~/.hermes/config.yaml` 將包含：

```yaml
model:
  default: us.anthropic.claude-sonnet-4-6
  provider: bedrock
  base_url: https://bedrock-runtime.us-east-2.amazonaws.com

bedrock:
  region: us-east-2
```

### 區域 (Region)

可以透過以下任何方式設定 AWS 區域（優先級由高到低）：

1. `config.yaml` 中的 `bedrock.region`
2. `AWS_REGION` 環境變數
3. `AWS_DEFAULT_REGION` 環境變數
4. 預設值：`us-east-1`

### 護欄 (Guardrails)

若要將 [Amazon Bedrock 護欄](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html) 套用到所有模型調用：

```yaml
bedrock:
  region: us-east-2
  guardrail:
    guardrail_identifier: "abc123def456"  # 來自 Bedrock 主控台
    guardrail_version: "1"                # 版本號碼或 "DRAFT"
    stream_processing_mode: "async"       # "sync" 或 "async"
    trace: "disabled"                     # "enabled", "disabled" 或 "enabled_full"
```

### 模型探索 (Model Discovery)

Hermes 會透過 Bedrock 控制平面自動探索可用的模型。您可以自定義探索行為：

```yaml
bedrock:
  discovery:
    enabled: true
    provider_filter: ["anthropic", "amazon"]  # 僅顯示這些供應商
    refresh_interval: 3600                     # 快取 1 小時
```

## 可用模型

Bedrock 模型使用**推論描述檔 ID (Inference Profile IDs)** 進行隨選調用。`hermes model` 選擇器會自動顯示這些 ID，並將推薦模型置於頂端：

| 模型 | ID | 備註 |
|-------|-----|-------|
| Claude Sonnet 4.6 | `us.anthropic.claude-sonnet-4-6` | 推薦 — 速度與能力的最佳平衡 |
| Claude Opus 4.6 | `us.anthropic.claude-opus-4-6-v1` | 能力最強大 |
| Claude Haiku 4.5 | `us.anthropic.claude-haiku-4-5-20251001-v1:0` | 速度最快的 Claude |
| Amazon Nova Pro | `us.amazon.nova-pro-v1:0` | Amazon 的旗艦模型 |
| Amazon Nova Micro | `us.amazon.nova-micro-v1:0` | 速度最快、價格最便宜 |
| DeepSeek V3.2 | `deepseek.v3.2` | 強大的開源模型 |
| Llama 4 Scout 17B | `us.meta.llama4-scout-17b-instruct-v1:0` | Meta 的最新模型 |

:::info 跨區域推論
以 `us.` 開頭的模型使用跨區域推論描述檔，可在 AWS 區域之間提供更好的容量和自動容錯移轉。以 `global.` 開頭的模型則會在全球所有可用區域之間進行路由。
:::

## 在對話中切換模型

在對話過程中使用 `/model` 指令：

```
/model us.amazon.nova-pro-v1:0
/model deepseek.v3.2
/model us.anthropic.claude-opus-4-6-v1
```

## 診斷

```bash
hermes doctor
```

診斷工具會檢查：
- AWS 憑證是否可用（環境變數、IAM 角色、SSO）
- 是否已安裝 `boto3`
- Bedrock API 是否可連通 (ListFoundationModels)
- 您所在區域內可用模型的數量

## 閘道 (即時通訊平台)

Bedrock 支援所有 Hermes 閘道平台（Telegram, Discord, Slack, 飛書等）。將 Bedrock 設定為您的供應商，然後正常啟動閘道：

```bash
hermes gateway setup
hermes gateway start
```

閘道會讀取 `config.yaml` 並使用相同的 Bedrock 供應商設定。

## 故障排除

### "No API key found" / "No AWS credentials"

Hermes 按以下順序檢查憑證：
1. `AWS_BEARER_TOKEN_BEDROCK`
2. `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY`
3. `AWS_PROFILE`
4. EC2 實例元數據 (IMDS)
5. ECS 容器憑證
6. Lambda 執行角色

如果皆未發現憑證，請執行 `aws configure` 或為您的運算實例附加 IAM 角色。

### "Invocation of model ID ... with on-demand throughput isn't supported"

請使用**推論描述檔 ID**（以 `us.` 或 `global.` 開頭），而非原始的基礎模型 ID。例如：
- ❌ `anthropic.claude-sonnet-4-6`
- ✅ `us.anthropic.claude-sonnet-4-6`

### "ThrottlingException"

您已達到 Bedrock 的單一模型速率限制。Hermes 會自動進行退避重試。若要調高限制，請在 [AWS Service Quotas 主控台](https://console.aws.amazon.com/servicequotas/) 中提出配額增加請求。
