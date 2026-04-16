---
sidebar_position: 5
title: "新增提供者 (Adding Providers)"
description: "如何向 Hermes Agent 新增新的推論提供者——涵蓋身分驗證、執行期解析、CLI 流程、適配器、測試與文件"
---

# 新增提供者 (Adding Providers)

Hermes 已經可以透過自定義提供者路徑與任何相容 OpenAI 的端點進行通訊。除非您希望該服務具備一等公民的使用者體驗 (UX)，否則請勿新增內建提供者：

- 提供者專屬的身分驗證或權杖 (token) 重新整理
- 精選的模型型錄 (catalog)
- 設定 / `hermes model` 選單條目
- 用於 `provider:model` 語法的提供者別名
- 需要適配器的非 OpenAI API 格式

如果該提供者只是「另一個相容 OpenAI 的基礎 URL 和 API 金鑰」，那麼使用具名的自定義提供者可能就足夠了。

## 心智模型 (The mental model)

一個內建提供者必須在多個層次上保持一致：

1. `hermes_cli/auth.py` 決定如何尋找憑證。
2. `hermes_cli/runtime_provider.py` 將其轉換為執行期數據：
   - `provider`
   - `api_mode`
   - `base_url`
   - `api_key`
   - `source`
3. `run_agent.py` 使用 `api_mode` 來決定如何建構和發送請求。
4. `hermes_cli/models.py` 和 `hermes_cli/main.py` 讓提供者顯示在 CLI 中（`hermes_cli/setup.py` 會自動委派給 `main.py`——在那裡不需要任何更改）。
5. `agent/auxiliary_client.py` 和 `agent/model_metadata.py` 確保側邊任務 (side tasks) 和 Token 預算管理正常運作。

最重要的抽象概念是 `api_mode`。

- 大多數提供者使用 `chat_completions`。
- Codex 使用 `codex_responses`。
- Anthropic 使用 `anthropic_messages`。
- 新的非 OpenAI 協定通常意味著要新增一個適配器和一個新的 `api_mode` 分支。

## 先選擇實作路徑

### 路徑 A — 相容 OpenAI 的提供者

當提供者接受標準聊天補全 (chat-completions) 風格的請求時使用。

典型工作：

- 新增身分驗證元數據 (metadata)
- 新增模型型錄 / 別名
- 新增執行期解析 (runtime resolution)
- 新增 CLI 選單串接
- 新增輔助模型 (aux-model) 預設值
- 新增測試和使用者文件

通常不需要新的適配器或新的 `api_mode`。

### 路徑 B — 原生提供者 (Native provider)

當提供者的行為不像 OpenAI 聊天補全時使用。

目前程式庫中的範例：

- `codex_responses`
- `anthropic_messages`

此路徑包含路徑 A 的所有內容，外加：

- 位於 `agent/` 的提供者適配器
- `run_agent.py` 中用於請求建構、發送、用量提取、中斷處理和回應正規化的分支
- 適配器測試

## 檔案檢核清單

### 每個內建提供者都需要

1. `hermes_cli/auth.py`
2. `hermes_cli/models.py`
3. `hermes_cli/runtime_provider.py`
4. `hermes_cli/main.py`
5. `agent/auxiliary_client.py`
6. `agent/model_metadata.py`
7. 測試
8. `website/docs/` 下的使用者文件

:::tip
`hermes_cli/setup.py` **不需要** 更改。設定精靈會將提供者/模型選擇委派給 `main.py` 中的 `select_provider_and_model()`——在那裡新增的任何提供者都會自動在 `hermes setup` 中可用。
:::

### 原生 / 非 OpenAI 提供者額外需要

10. `agent/<provider>_adapter.py`
11. `run_agent.py`
12. 如果需要提供者 SDK，則需要修改 `pyproject.toml`

## 步驟 1：選擇一個規範的提供者識別碼 (Provider ID)

選擇一個唯一的提供者識別碼，並在所有地方使用它。

範例：

- `openai-codex`
- `kimi-coding`
- `minimax-cn`

同一個識別碼應出現在：

- `hermes_cli/auth.py` 中的 `PROVIDER_REGISTRY`
- `hermes_cli/models.py` 中的 `_PROVIDER_LABELS`
- `hermes_cli/auth.py` 和 `hermes_cli/models.py` 中的 `_PROVIDER_ALIASES`
- `hermes_cli/main.py` 中的 CLI `--provider` 選項
- 設定 / 模型選擇分支
- 輔助模型預設值
- 測試

如果識別碼在這些檔案之間不一致，提供者會顯得「串接不全」：身分驗證可能有效，但 `/model`、設定或執行期解析會默默地遺漏它。

## 步驟 2：在 `hermes_cli/auth.py` 中新增身分驗證元數據

對於 API 金鑰提供者，在 `PROVIDER_REGISTRY` 中新增一個 `ProviderConfig` 條目，包含：

- `id`
- `name`
- `auth_type="api_key"`
- `inference_base_url`
- `api_key_env_vars`
- 選用的 `base_url_env_var`

同時在 `_PROVIDER_ALIASES` 中新增別名。

參考現有的提供者作為模板：

- 簡單的 API 金鑰路徑：Z.AI, MiniMax
- 具備端點檢測的 API 金鑰路徑：Kimi, Z.AI
- 原生權杖解析：Anthropic
- OAuth / 憑證存儲路徑：Nous, OpenAI Codex

此處需要回答的問題：

- Hermes 應該檢查哪些環境變數？優先順序為何？
- 該提供者是否需要基礎 URL 覆蓋？
- 是否需要端點探測或權杖重新整理？
- 缺少憑證時的身分驗證錯誤訊息應為何？

如果提供者需要的內容不僅僅是「查找 API 金鑰」，請新增專用的憑證解析器，而不是將邏輯硬塞進無關的分支。

## 步驟 3：在 `hermes_cli/models.py` 中新增模型型錄和別名

更新提供者型錄，以便該提供者能在選單和 `provider:model` 語法中運作。

典型的編輯點：

- `_PROVIDER_MODELS`
- `_PROVIDER_LABELS`
- `_PROVIDER_ALIASES`
- `list_available_providers()` 內的提供者顯示順序
- 如果提供者支援即時獲取清單，則修改 `provider_model_ids()`

如果提供者提供即時模型列表，請優先使用，並將 `_PROVIDER_MODELS` 作為靜態回退 (fallback)。

這個檔案也決定了以下輸入是否能運作：

```text
anthropic:claude-sonnet-4-6
kimi:model-name
```

如果此處缺少別名，提供者可能驗證正確，但在解析 `/model` 時仍會失敗。

## 步驟 4：在 `hermes_cli/runtime_provider.py` 中解析執行期數據

`resolve_runtime_provider()` 是 CLI、閘道、cron、ACP 和輔助用戶端共用的路徑。

新增一個分支，回傳一個至少包含以下內容的字典：

```python
{
    "provider": "your-provider",
    "api_mode": "chat_completions",  # 或您的原生模式
    "base_url": "https://...",
    "api_key": "...",
    "source": "env|portal|auth-store|explicit",
    "requested_provider": requested_provider,
}
```

如果提供者相容 OpenAI，`api_mode` 通常應保持為 `chat_completions`。

請注意 API 金鑰的優先順序。Hermes 已經包含邏輯以避免將 OpenRouter 金鑰洩露到無關的端點。新提供者應同樣明確地指定哪個金鑰對應哪個基礎 URL。

## 步驟 5：在 `hermes_cli/main.py` 中串接 CLI

在互動式 `hermes model` 流程中顯示之前，提供者是不可被發現的。

在 `hermes_cli/main.py` 中更新以下內容：

- `provider_labels` 字典
- `select_provider_and_model()` 中的 `providers` 列表
- 提供者分派 (`if selected_provider == ...`)
- `--provider` 參數選項
- 如果提供者支援，則新增登入/登出選項
- 一個 `_model_flow_<provider>()` 函式，或者如果適用，重複使用 `_model_flow_api_key_provider()`

:::tip
`hermes_cli/setup.py` 不需要更改——它呼叫 `main.py` 中的 `select_provider_and_model()`，因此您的新提供者會自動出現在 `hermes model` 和 `hermes setup` 中。
:::

## 步驟 6：保持輔助呼叫正常運作

這裡涉及兩個檔案：

### `agent/auxiliary_client.py`

如果是直接使用 API 金鑰的提供者，請在 `_API_KEY_PROVIDER_AUX_MODELS` 中新增一個便宜且快速的預設輔助模型。

輔助任務包括：

- 視覺摘要 (vision summarization)
- 網頁提取摘要
- 上下文壓縮摘要
- 工作階段搜尋摘要
- 記憶體清除 (memory flushes)

如果提供者沒有合理的輔助預設值，側邊任務可能會回退到不理想的模型，或者意外使用昂貴的主模型。

### `agent/model_metadata.py`

新增提供者模型的上下文長度，以便 Token 預算管理、壓縮閾值和限制保持合理。

## 步驟 7：如果提供者是原生的，新增適配器和 `run_agent.py` 支援

如果提供者不是單純的聊天補全，請將提供者專屬的邏輯隔離在 `agent/<provider>_adapter.py` 中。

讓 `run_agent.py` 專注於編排。它應該呼叫適配器輔助程式，而不是在整個檔案中手動建構提供者的負載 (payload)。

原生提供者通常需要在以下地方進行工作：

### 新的適配器檔案

典型職責：

- 建構 SDK / HTTP 用戶端
- 解析權杖 (token)
- 將 OpenAI 風格的對話訊息轉換為提供者的請求格式
- 如果需要，轉換工具結構描述 (tool schemas)
- 將提供者回應正規化為 `run_agent.py` 預期的格式
- 提取用量和完成原因數據

### `run_agent.py`

搜尋 `api_mode` 並審核每個切換點。至少驗證：

- `__init__` 選擇新的 `api_mode`
- 用戶端建構對該提供者有效
- `_build_api_kwargs()` 知道如何格式化請求
- `_api_call_with_interrupt()` 分派到正確的用戶端呼叫
- 中斷 / 用戶端重建路徑運作正常
- 回應驗證接受提供者的格式
- 完成原因提取正確
- Token 用量提取正確
- 備援模型啟動能乾淨地切換到新提供者
- 摘要產生和記憶體清除路徑仍然有效

同時在 `run_agent.py` 中搜尋 `self.client.`。任何假設標準 OpenAI 用戶端存在的程式碼路徑，在原生提供者使用不同用戶端物件或 `self.client = None` 時都可能出錯。

### 提示詞快取與提供者專屬請求欄位

提示詞快取 (Prompt caching) 和提供者專屬旋鈕很容易發生迴歸 (regression)。

目前已有的範例：

- Anthropic 有原生的提示詞快取路徑
- OpenRouter 獲取提供者路由欄位
- 並非每個提供者都應接收每個請求側選項

當您新增原生提供者時，請再次檢查 Hermes 是否僅發送該提供者真正理解的欄位。

## 步驟 8：測試

至少要觸及保護提供者串接的測試。

常見位置：

- `tests/test_runtime_provider_resolution.py`
- `tests/test_cli_provider_resolution.py`
- `tests/test_cli_model_command.py`
- `tests/test_setup_model_selection.py`
- `tests/test_provider_parity.py`
- `tests/test_run_agent.py`
- 對於原生提供者，修改 `tests/test_<provider>_adapter.py`

重點是涵蓋：

- 身分驗證解析
- CLI 選單 / 提供者選擇
- 執行期提供者解析
- 代理執行路徑
- `provider:model` 解析
- 任何適配器專屬的訊息轉換

在禁用 xdist 的情況下執行測試：

```bash
source venv/bin/activate
python -m pytest tests/test_runtime_provider_resolution.py tests/test_cli_provider_resolution.py tests/test_cli_model_command.py tests/test_setup_model_selection.py -n0 -q
```

對於更深層次的更改，請在推送前執行完整測試套件：

```bash
source venv/bin/activate
python -m pytest tests/ -n0 -q
```

## 步驟 9：現場驗證

測試完成後，執行一次真實的冒煙測試 (smoke test)。

```bash
source venv/bin/activate
python -m hermes_cli.main chat -q "Say hello" --provider your-provider --model your-model
```

如果您更改了選單，也要測試互動式流程：

```bash
source venv/bin/activate
python -m hermes_cli.main model
python -m hermes_cli.main setup
```

對於原生提供者，請驗證至少一個工具呼叫，而不僅僅是純文字回應。

## 步驟 10：更新面向使用者的文件

如果該提供者旨在作為一等選項發布，請同時更新使用者文件：

- `website/docs/getting-started/quickstart.md`
- `website/docs/user-guide/configuration.md`
- `website/docs/reference/environment-variables.md`

開發者可能完美地串接了提供者，但仍讓使用者無法發現所需的環境變數或設定流程。

## 相容 OpenAI 的提供者檢核清單

如果提供者是標準聊天補全。

- [ ] 在 `hermes_cli/auth.py` 中新增 `ProviderConfig`
- [ ] 在 `hermes_cli/auth.py` 和 `hermes_cli/models.py` 中新增別名
- [ ] 在 `hermes_cli/models.py` 中新增模型型錄
- [ ] 在 `hermes_cli/runtime_provider.py` 中新增執行期分支
- [ ] 在 `hermes_cli/main.py` 中新增 CLI 串接（setup.py 自動繼承）
- [ ] 在 `agent/auxiliary_client.py` 中新增輔助模型
- [ ] 在 `agent/model_metadata.py` 中新增上下文長度
- [ ] 更新執行期 / CLI 測試
- [ ] 更新使用者文件

## 原生提供者檢核清單

當提供者需要新的協定路徑時使用。

- [ ] 完成「相容 OpenAI」檢核清單中的所有項目
- [ ] 在 `agent/<provider>_adapter.py` 中新增適配器
- [ ] 在 `run_agent.py` 中支援新的 `api_mode`
- [ ] 中斷 / 重建路徑運作正常
- [ ] 用量和完成原因提取運作正常
- [ ] 備援路徑運作正常
- [ ] 新增適配器測試
- [ ] 通過現場冒煙測試

## 常見陷阱 (Common pitfalls)

### 1. 將提供者新增到身分驗證，但未新增到模型解析

這會導致憑證解析正確，但 `/model` 和 `provider:model` 輸入失敗。

### 2. 忘記 `config["model"]` 可以是字串或字典

許多提供者選擇程式碼必須將這兩種形式正規化。

### 3. 假設必須新增內建提供者

如果服務只是相容 OpenAI，自定義提供者可能已經以較低的維護成本解決了使用者的問題。

### 4. 忘記輔助路徑

主聊天路徑可能運作正常，但摘要、記憶體清除或視覺輔助功能失敗，因為輔助路由從未更新。

### 5. 原生提供者分支隱藏在 `run_agent.py` 中

搜尋 `api_mode` 和 `self.client.`。不要假設明顯的請求路徑是唯一的。

### 6. 將僅限 OpenRouter 的旋鈕發送到其他提供者

諸如提供者路由之類的欄位僅屬於支援它們的提供者。

### 7. 更新了 `hermes model` 但未更新 `hermes setup`

兩個流程都需要知道該提供者。

## 實作時的良好搜尋目標

如果您正在尋找提供者涉及的所有位置，請搜尋這些符號：

- `PROVIDER_REGISTRY`
- `_PROVIDER_ALIASES`
- `_PROVIDER_MODELS`
- `resolve_runtime_provider`
- `_model_flow_`
- `select_provider_and_model`
- `api_mode`
- `_API_KEY_PROVIDER_AUX_MODELS`
- `self.client.`

## 相關文件

- [提供者執行期解析 (Provider Runtime Resolution)](./provider-runtime.md)
- [架構 (Architecture)](./architecture.md)
- [貢獻 (Contributing)](./contributing.md)
