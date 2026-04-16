---
title: 提供者路由 (Provider Routing)
description: 設定 OpenRouter 提供者偏好，以優化成本、速度或品質。
sidebar_label: 提供者路由
sidebar_position: 7
---

# 提供者路由 (Provider Routing)

當使用 [OpenRouter](https://openrouter.ai) 作為您的大型語言模型 (LLM) 提供者時，Hermes Agent 支援**提供者路由** — 讓您能精細控制由哪些底層 AI 提供者處理您的請求以及如何安排其優先順序。

OpenRouter 將請求路由到許多提供者（例如 Anthropic、Google、AWS Bedrock、Together AI）。提供者路由讓您可以針對成本、速度、品質進行優化，或強制執行特定的提供者要求。

## 設定

在您的 `~/.hermes/config.yaml` 中新增 `provider_routing` 區段：

```yaml
provider_routing:
  sort: "price"           # 如何對提供者進行排名
  only: []                # 白名單：僅使用這些提供者
  ignore: []              # 黑名單：絕不使用這些提供者
  order: []               # 明確的提供者優先順序
  require_parameters: false  # 僅使用支援所有參數的提供者
  data_collection: null   # 控制數據收集（"allow" 或 "deny"）
```

:::info
提供者路由僅在使用 OpenRouter 時有效。若直接連線至提供者（例如直接連線到 Anthropic API），則此設定無效。
:::

## 選項

### `sort` (排序)

控制 OpenRouter 如何為您的請求對可用提供者進行排名。

| 值 (Value) | 描述 |
|-------|-------------|
| `"price"` | 最便宜的提供者優先 |
| `"throughput"` | 每秒權杖生成數 (tokens-per-second) 最快的優先 |
| `"latency"` | 首個權杖產出時間 (time-to-first-token) 最短的優先 |

```yaml
provider_routing:
  sort: "price"
```

### `only` (僅限)

提供者名稱白名單。設定後，**僅**會使用這些提供者。所有其他提供者都將被排除。

```yaml
provider_routing:
  only:
    - "Anthropic"
    - "Google"
```

### `ignore` (忽略)

提供者名稱黑名單。即使這些提供者提供最便宜或最快的選項，也**絕不**會被使用。

```yaml
provider_routing:
  ignore:
    - "Together"
    - "DeepInfra"
```

### `order` (順序)

明確的優先順序。排在前面的提供者將被優先考慮。未列出的提供者則作為備援使用。

```yaml
provider_routing:
  order:
    - "Anthropic"
    - "Google"
    - "AWS Bedrock"
```

### `require_parameters` (要求參數)

當設為 `true` 時，OpenRouter 僅會路由到支援您請求中**所有**參數（例如 `temperature`、`top_p`、`tools` 等）的提供者。這可以避免參數被無聲丟棄。

```yaml
provider_routing:
  require_parameters: true
```

### `data_collection` (數據收集)

控制提供者是否可以使用您的提示詞進行訓練。選項為 `"allow"` (允許) 或 `"deny"` (拒絕)。

```yaml
provider_routing:
  data_collection: "deny"
```

## 實際範例

### 優化成本

路由到最便宜的可用提供者。適合高用量場景和開發：

```yaml
provider_routing:
  sort: "price"
```

### 優化速度

針對互動式使用，優先考慮低延遲提供者：

```yaml
provider_routing:
  sort: "latency"
```

### 優化吞吐量

最適合需要高每秒權杖數的長文生成：

```yaml
provider_routing:
  sort: "throughput"
```

### 鎖定特定提供者

確保所有請求都通過特定提供者，以維持一致性：

```yaml
provider_routing:
  only:
    - "Anthropic"
```

### 避開特定提供者

排除您不想使用的提供者（例如出於數據隱私考量）：

```yaml
provider_routing:
  ignore:
    - "Together"
    - "Lepton"
  data_collection: "deny"
```

### 具備備援的優先順序

先嘗試您偏好的提供者，如果不可用則回退到其他提供者：

```yaml
provider_routing:
  order:
    - "Anthropic"
    - "Google"
  require_parameters: true
```

## 運作原理

提供者路由偏好會透過每次 API 呼叫中的 `extra_body.provider` 欄位傳遞給 OpenRouter API。這適用於：

- **命令列介面 (CLI) 模式** — 在 `~/.hermes/config.yaml` 中設定，啟動時載入
- **閘道 (Gateway) 模式** — 使用相同的設定檔，在閘道啟動時載入

路由設定會從 `config.yaml` 讀取，並在建立 `AIAgent` 時作為參數傳遞：

```
providers_allowed  ← 來自 provider_routing.only
providers_ignored  ← 來自 provider_routing.ignore
providers_order    ← 來自 provider_routing.order
provider_sort      ← 來自 provider_routing.sort
provider_require_parameters ← 來自 provider_routing.require_parameters
provider_data_collection    ← 來自 provider_routing.data_collection
```

:::tip
您可以結合多個選項。例如，按價格排序，但排除某些提供者並要求參數支援：

```yaml
provider_routing:
  sort: "price"
  ignore: ["Together"]
  require_parameters: true
  data_collection: "deny"
```
:::

## 預設行為

當未設定 `provider_routing` 區段（預設情況）時，OpenRouter 會使用其自身的預設路由邏輯，通常會自動平衡成本和可用性。

:::tip 提供者路由 vs. 備援模型
提供者路由控制的是 **OpenRouter 內部的子提供者** 如何處理您的請求。若要在主要模型完全失敗時自動切換到完全不同的提供者，請參閱 [備援提供者](/docs/user-guide/features/fallback-providers)。
:::
