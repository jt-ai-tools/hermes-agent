# 計費準確性架構 (Pricing Accuracy Architecture)

日期：2026-03-16

## 目標 (Goal)

Hermes 僅應在金額有使用者實際帳單路徑的官方來源支持時，才顯示美金成本。

此設計取代了目前以下檔案中靜態、啟發式的計費流程：

- `run_agent.py`
- `agent/usage_pricing.py`
- `agent/insights.py`
- `cli.py`

取而代之的是一個感知提供者 (provider-aware) 的計費系統，該系統能夠：

- 正確處理快取計費 (cache billing)
- 區分 `actual` (實際)、`estimated` (預估)、`included` (已包含) 與 `unknown` (未知)
- 當提供者公開權威計費數據時，進行事後成本對帳 (reconcile)
- 支援直接提供者 (direct providers)、OpenRouter、訂閱制、企業定價以及自定義端點

## 現有設計中的問題 (Problems In The Current Design)

目前的 Hermes 行為存在四個結構性問題：

1. 它僅儲存 `prompt_tokens` (提示詞代幣) 和 `completion_tokens` (補完代幣)，這對於分別計算快取讀取和快取寫入費用的提供者來說是不夠的。
2. 它使用靜態模型價格表和模糊的啟發式方法，這可能會與目前的官方定價產生偏差。
3. 它假設公開的 API 列表價格與使用者的實際帳單路徑相符。
4. 它無法區分即時預估成本與事後核定的已計費成本。

## 設計原則 (Design Principles)

1. 在計算價格前先對用量進行正規化 (Normalize)。
2. 絕不將快取的代幣併入普通的輸入成本中。
3. 明確追蹤確定性 (certainty)。
4. 將帳單路徑視為模型身分的一部分。
5. 偏好機器可讀的官方來源，而非爬取的文檔。
6. 在可用時使用事後的提供者成本 API。
7. 寧可顯示 `n/a` 也不要捏造精確度。

## 高層次架構 (High-Level Architecture)

新系統分為四層：

1. `usage_normalization` (用量正規化)
   將原始提供者用量轉換為標準用量記錄。
2. `pricing_source_resolution` (計費來源解析)
   確定帳單路徑、真實來源以及適用的計費來源。
3. `cost_estimation_and_reconciliation` (成本預估與對帳)
   盡可能產生即時預估，稍後再以實際計費成本替換或標註。
4. `presentation` (呈報)
   `/usage`、`/insights` 以及狀態列會顯示帶有確定性中繼資料的成本。

## 標準用量記錄 (Canonical Usage Record)

在進行任何計費運算之前，新增一個所有提供者路徑都會對應到的標準用量模型。

建議結構：

```python
@dataclass
class CanonicalUsage:
    provider: str
    billing_provider: str
    model: str
    billing_route: str

    input_tokens: int = 0
    output_tokens: int = 0
    cache_read_tokens: int = 0
    cache_write_tokens: int = 0
    reasoning_tokens: int = 0
    request_count: int = 1

    raw_usage: dict[str, Any] | None = None
    raw_usage_fields: dict[str, str] | None = None
    computed_fields: set[str] | None = None

    provider_request_id: str | None = None
    provider_generation_id: str | None = None
    provider_response_id: str | None = None
```

規則：

- `input_tokens` 僅指非快取的輸入。
- `cache_read_tokens` 和 `cache_write_tokens` 絕不併入 `input_tokens`。
- `output_tokens` 不含快取指標。
- `reasoning_tokens` 除非提供者官方明確分開計費，否則視為遙測數據。

這與 `opencode` 使用的正規化模式相同，並擴展了來源追蹤和對帳 ID。

## 提供者正規化規則 (Provider Normalization Rules)

### OpenAI 直接連線 (OpenAI Direct)

原始用量欄位：

- `prompt_tokens`
- `completion_tokens`
- `prompt_tokens_details.cached_tokens`

正規化：

- `cache_read_tokens = cached_tokens`
- `input_tokens = prompt_tokens - cached_tokens`
- 除非 OpenAI 在相關路徑中公開，否則 `cache_write_tokens = 0`
- `output_tokens = completion_tokens`

### Anthropic 直接連線 (Anthropic Direct)

原始用量欄位：

- `input_tokens`
- `output_tokens`
- `cache_read_input_tokens`
- `cache_creation_input_tokens`

正規化：

- `input_tokens = input_tokens`
- `output_tokens = output_tokens`
- `cache_read_tokens = cache_read_input_tokens`
- `cache_write_tokens = cache_creation_input_tokens`

### OpenRouter

預估時的用量正規化應盡可能使用與底層提供者相同規則的回應效能負載 (usage payload)。

對帳時的記錄也應儲存：

- OpenRouter generation id
- 可用時的原生代幣欄位
- `total_cost` (總成本)
- `cache_discount` (快取折扣)
- `upstream_inference_cost` (上游推論成本)
- `is_byok` (是否為自備金鑰)

### Gemini / Vertex

在可用時使用官方 Gemini 或 Vertex 用量欄位。

如果公開了快取內容代幣：

- 將其對應至 `cache_read_tokens`

如果某個路徑未公開快取建立指標：

- 儲存 `cache_write_tokens = 0`
- 保留原始用量負載以供日後擴充

### DeepSeek 以及其他直接提供者

僅正規化官方公開的欄位。

如果提供者未公開快取分桶 (cache buckets)：

- 除非提供者明確記錄如何推導，否則不要推斷它們。

### 訂閱制 / 包含成本的路徑 (Subscription / Included-Cost Routes)

這些仍使用標準用量模型。

代幣會正常追蹤。成本取決於計費模式，而非用量是否存在。

## 帳單路徑模型 (Billing Route Model)

Hermes 必須停止僅以 `model` 作為計費鍵。

引入帳單路徑描述項：

```python
@dataclass
class BillingRoute:
    provider: str
    base_url: str | None
    model: str
    billing_mode: str
    organization_hint: str | None = None
```

`billing_mode` 取值：

- `official_cost_api` (官方成本 API)
- `official_generation_api` (官方生成 API)
- `official_models_api` (官方模型 API)
- `official_docs_snapshot` (官方文件快照)
- `subscription_included` (訂閱包含)
- `user_override` (使用者覆寫)
- `custom_contract` (自定義合約)
- `unknown` (未知)

範例：

- 具有 Costs API 存取權限的 OpenAI 直接 API：`official_cost_api`
- 具有 Usage & Cost API 存取權限的 Anthropic 直接 API：`official_cost_api`
- 對帳前的 OpenRouter 請求：`official_models_api`
- 查詢生成後的 OpenRouter 請求：`official_generation_api`
- GitHub Copilot 風格的訂閱路徑：`subscription_included`
- 本地 OpenAI 相容伺服器：`unknown`
- 具有配置費率的企業合約：`custom_contract`

## 成本狀態模型 (Cost Status Model)

每個顯示的成本應具有：

```python
@dataclass
class CostResult:
    amount_usd: Decimal | None
    status: Literal["actual", "estimated", "included", "unknown"]
    source: Literal[
        "provider_cost_api",
        "provider_generation_api",
        "provider_models_api",
        "official_docs_snapshot",
        "user_override",
        "custom_contract",
        "none",
    ]
    label: str
    fetched_at: datetime | None
    pricing_version: str | None
    notes: list[str]
```

呈現規則：

- `actual`：將美金金額顯示為最終值
- `estimated`：顯示美金金額並標註預估
- `included`：根據 UX 選擇顯示 `included` 或 `$0.00 (included)`
- `unknown`：顯示 `n/a`

## 官方來源階層 (Official Source Hierarchy)

按以下順序解析成本：

1. 請求層級或帳戶層級的官方已計費成本
2. 官方機器可讀的模型定價
3. 官方文件快照
4. 使用者覆寫或自定義合約
5. 未知

如果當前帳單路徑存在較高信賴度的來源，系統絕不能跳至較低層級。

## 提供者特定的真實性規則 (Provider-Specific Truth Rules)

### OpenAI 直接連線 (OpenAI Direct)

偏好的真實來源：

1. 用於對帳支出的 Costs API
2. 用於即時預估的官方定價頁面

### Anthropic 直接連線 (Anthropic Direct)

偏好的真實來源：

1. 用於對帳支出的 Usage & Cost API
2. 用於即時預估的官方定價文件

### OpenRouter

偏好的真實來源：

1. 用於對帳後 `total_cost` 的 `GET /api/v1/generation`
2. 用於即時預估的 `GET /api/v1/models` 定價

不要使用底層提供者的公開定價作為 OpenRouter 帳單的真實來源。

### Gemini / Vertex

偏好的真實來源：

1. 該路徑可用時，用於對帳支出的官方帳單匯出或帳單 API
2. 用於預估的官方定價文件

### DeepSeek

偏好的真實來源：

1. 未來若有官方機器可讀成本來源則優先使用
2. 目前使用官方定價文件快照

### 訂閱包含的路徑 (Subscription-Included Routes)

偏好的真實來源：

1. 明確將模型標記為包含在訂閱中的路徑配置

這些應顯示為 `included`，而非 API 列表價格的預估值。

### 自定義端點 / 本地模型 (Custom Endpoint / Local Model)

偏好的真實來源：

1. 使用者覆寫
2. 自定義合約配置
3. 未知

這些應預設為 `unknown`。

## 定價型錄 (Pricing Catalog)

將目前的 `MODEL_PRICING` 字典替換為更豐富的定價型錄。

建議記錄：

```python
@dataclass
class PricingEntry:
    provider: str
    route_pattern: str
    model_pattern: str

    input_cost_per_million: Decimal | None = None
    output_cost_per_million: Decimal | None = None
    cache_read_cost_per_million: Decimal | None = None
    cache_write_cost_per_million: Decimal | None = None
    request_cost: Decimal | None = None
    image_cost: Decimal | None = None

    source: str = "official_docs_snapshot"
    source_url: str | None = None
    fetched_at: datetime | None = None
    pricing_version: str | None = None
```

型錄應具備路徑感知能力：

- `openai:gpt-5`
- `anthropic:claude-opus-4-6`
- `openrouter:anthropic/claude-opus-4.6`
- `copilot:gpt-4o`

這避免了將直接提供者計費與聚合器計費混為一談。

## 定價同步架構 (Pricing Sync Architecture)

引入一個定價同步子系統，而非手動維護單一硬編碼表。

建議模組：

- `agent/pricing/catalog.py`
- `agent/pricing/sources.py`
- `agent/pricing/sync.py`
- `agent/pricing/reconcile.py`
- `agent/pricing/types.py`

### 同步來源 (Sync Sources)

- OpenRouter models API
- 無 API 存在時的官方提供者文件快照
- 來自配置的使用者覆寫

### 同步輸出 (Sync Output)

將定價條目快取至本地，並包含：

- 來源 URL
- 獲取時間戳記
- 版本/雜湊值
- 信賴度/來源類型

### 同步頻率 (Sync Frequency)

- 啟動時預熱快取
- 根據來源每 6 至 24 小時背景重新整理
- 手動執行 `hermes pricing sync`

## 對帳架構 (Reconciliation Architecture)

即時請求最初可能僅產生預估值。當提供者公開實際已計費成本時，Hermes 應在稍後對其進行對帳。

建議流程：

1. 代理人呼叫完成。
2. Hermes 儲存標準用量以及對帳 ID。
3. 如果存在計費來源，Hermes 計算即時預估。
4. 對帳工作程式在支援時獲取實際成本。
5. 工作階段和訊息記錄更新為 `actual` 成本。

這可以執行於：

- 線內 (inline) 用於廉價的查詢
- 非同步用於延遲的提供者帳務處理

## 持久化變更 (Persistence Changes)

工作階段儲存應停止僅儲存總計提示詞/補完代幣。

為用量和成本確定性新增欄位：

- `input_tokens`
- `output_tokens`
- `cache_read_tokens`
- `cache_write_tokens`
- `reasoning_tokens`
- `estimated_cost_usd`
- `actual_cost_usd`
- `cost_status`
- `cost_source`
- `pricing_version`
- `billing_provider`
- `billing_mode`

如果架構擴展對於單個 PR 來說太大，請新增一個新的計費事件表：

```text
session_cost_events
  id
  session_id
  request_id
  provider
  model
  billing_mode
  input_tokens
  output_tokens
  cache_read_tokens
  cache_write_tokens
  estimated_cost_usd
  actual_cost_usd
  cost_status
  cost_source
  pricing_version
  created_at
  updated_at
```

## Hermes 觸及點 (Hermes Touchpoints)

### `run_agent.py`

目前職責：

- 解析原始提供者用量
- 更新工作階段代幣計數器

新職責：

- 建構 `CanonicalUsage`
- 更新標準計數器
- 儲存對帳 ID
- 向計費子系統發送用量事件

### `agent/usage_pricing.py`

目前職責：

- 靜態查詢表
- 直接成本運算

新職責：

- 移至或替換為計費型錄門面 (facade)
- 不再使用模糊的模型族群啟發式方法
- 在沒有帳單路徑內容的情況下不進行直接計費

### `cli.py`

目前職責：

- 直接從提示詞/補完總計計算工作階段成本

新職責：

- 顯示 `CostResult`
- 顯示狀態徽章：
  - `actual`
  - `estimated`
  - `included`
  - `n/a`

### `agent/insights.py`

目前職責：

- 從靜態定價重新計算歷史預估

新職責：

- 聚合已儲存的計費事件
- 優先使用實際成本而非預估值
- 僅在無法對帳時才呈現預估值

## UX 規則 (UX Rules)

### 狀態列 (Status Bar)

顯示以下內容之一：

- `$1.42`
- `~$1.42`
- `included`
- `cost n/a`

其中：

- `$1.42` 表示 `actual`
- `~$1.42` 表示 `estimated`
- `included` 表示訂閱支持或明確零成本的路徑
- `cost n/a` 表示未知

### `/usage`

顯示：

- 代幣分桶 (token buckets)
- 預估成本
- 可用時的實際成本
- 成本狀態
- 計費來源

### `/insights`

聚合：

- 實際成本總計
- 僅預估總計
- 未知成本的工作階段數量
- 包含成本的工作階段數量

## 配置與覆寫 (Config And Overrides)

在配置中新增使用者可配置的定價覆寫：

```yaml
pricing:
  mode: hybrid
  sync_on_startup: true
  sync_interval_hours: 12
  overrides:
    - provider: openrouter
      model: anthropic/claude-opus-4.6
      billing_mode: custom_contract
      input_cost_per_million: 4.25
      output_cost_per_million: 22.0
      cache_read_cost_per_million: 0.5
      cache_write_cost_per_million: 6.0
  included_routes:
    - provider: copilot
      model: "*"
    - provider: codex-subscription
      model: "*"
```

覆寫必須優先於符合之帳單路徑的型錄預設值。

## 推行計劃 (Rollout Plan)

### 第一階段

- 新增標準用量模型
- 在 `run_agent.py` 中拆分快取代幣分桶
- 停止對含快取的提示詞總計進行計費
- 保留目前的 UI，但改進後端運算

### 第二階段

- 新增路徑感知的定價型錄
- 整合 OpenRouter models API 同步
- 新增 `estimated` vs `included` vs `unknown`

### 第三階段

- 為 OpenRouter 生成成本新增對帳功能
- 新增實際成本持久化
- 更新 `/insights` 以優先使用實際成本

### 第四階段

- 新增直接 OpenAI 和 Anthropic 的對帳路徑
- 新增使用者覆寫和合約定價
- 新增定價同步 CLI 指令

## 測試策略 (Testing Strategy)

為以下內容新增測試：

- OpenAI 快取代幣扣除
- Anthropic 快取讀取/寫入分離
- OpenRouter 預估與實際對帳
- 訂閱支持的模型顯示 `included`
- 自定義端點顯示 `n/a`
- 覆寫優先順序
- 過期型錄回退行為

目前假設啟發式計費的測試應更換為路徑感知的預期值。

## 非目標 (Non-Goals)

- 在沒有官方來源或使用者覆寫的情況下重構精確的企業帳單
- 為缺乏快取分桶數據的舊工作階段補全完美的歷史成本
- 在請求時爬取任意提供者的網頁

## 建議 (Recommendation)

不要擴展現有的 `MODEL_PRICING` 字典。

該路徑無法滿足產品需求。Hermes 應轉而遷移至：

- 標準用量正規化
- 路徑感知的計費來源
- 先預估後對帳的成本生命週期
- UI 中明確的確定性狀態

這是能讓「Hermes 計費在可能的情況下由官方來源支持，否則會清楚標註」這一聲明立足的最小架構。
