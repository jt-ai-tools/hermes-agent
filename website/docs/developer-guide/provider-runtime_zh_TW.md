---
sidebar_position: 4
title: "供應商執行階段解析"
description: "Hermes 如何在執行階段解析供應商、認證資訊、API 模式和輔助模型"
---

# 供應商執行階段解析 (Provider Runtime Resolution)

Hermes 擁有一個共用的供應商執行階段解析器 (provider runtime resolver)，用於：

- CLI
- 閘道器 (gateway)
- 排程任務 (cron jobs)
- ACP
- 輔助模型呼叫 (auxiliary model calls)

主要實作：

- `hermes_cli/runtime_provider.py` — 認證資訊解析、`_resolve_custom_runtime()`
- `hermes_cli/auth.py` — 供應商註冊表、`resolve_provider()`
- `hermes_cli/model_switch.py` — 共用的 `/model` 切換管線 (CLI + 閘道器)
- `agent/auxiliary_client.py` — 輔助模型路由

如果您嘗試添加一個新的第一類推論供應商，請同時閱讀 [添加供應商](./adding-providers.md) 頁面。

## 解析優先順序 (Resolution precedence)

在高層級上，供應商解析使用以下順序：

1. 明確的 CLI/執行階段請求
2. `config.yaml` 中的模型/供應商配置
3. 環境變數
4. 特定供應商的預設值或自動解析

這個順序很重要，因為 Hermes 將儲存的模型/供應商選擇視為正常運行的事實來源。這可以防止陳舊的 shell 匯出 (export) 靜默地覆蓋使用者上次在 `hermes model` 中選擇的端點 (endpoint)。

## 供應商 (Providers)

目前的供應商系列包括：

- AI Gateway (Vercel)
- OpenRouter
- Nous Portal
- OpenAI Codex
- Copilot / Copilot ACP
- Anthropic (原生)
- Google / Gemini
- Alibaba / DashScope
- DeepSeek
- Z.AI
- Kimi / Moonshot
- MiniMax
- MiniMax China
- Kilo Code
- Hugging Face
- OpenCode Zen / OpenCode Go
- 自定義 (`provider: custom`) — 適用於任何相容 OpenAI 端點的第一類供應商
- 命名的自定義供應商 (config.yaml 中的 `custom_providers` 列表)

## 執行階段解析的輸出

執行階段解析器會返回以下數據：

- `provider` (供應商)
- `api_mode` (API 模式)
- `base_url` (基礎 URL)
- `api_key` (API 金鑰)
- `source` (來源)
- 特定供應商的元數據，如過期/重新整理資訊

## 為什麼這很重要

這個解析器是 Hermes 能夠在以下各項之間共享認證/執行階段邏輯的主要原因：

- `hermes chat`
- 閘道器訊息處理
- 在新會話中運行的排程任務
- ACP 編輯器會話
- 輔助模型任務

## AI Gateway

在 `~/.hermes/.env` 中設置 `AI_GATEWAY_API_KEY`，並使用 `--provider ai-gateway` 運行。Hermes 會從閘道器的 `/models` 端點獲取可用模型，並過濾出支援工具使用的語言模型。

## OpenRouter、AI Gateway 和自定義 OpenAI 相容的基礎 URL

Hermes 包含邏輯，以避免在存在多個供應商金鑰（例如 `OPENROUTER_API_KEY`、`AI_GATEWAY_API_KEY` 和 `OPENAI_API_KEY`）時，將錯誤的 API 金鑰洩露給自定義端點。

每個供應商的 API 金鑰都限定在其自己的基礎 URL：

- `OPENROUTER_API_KEY` 僅發送到 `openrouter.ai` 端點
- `AI_GATEWAY_API_KEY` 僅發送到 `ai-gateway.vercel.sh` 端點
- `OPENAI_API_KEY` 用於自定義端點，並作為回退方案

Hermes 還區分以下兩者：

- 使用者選擇的真實自定義端點
- 未配置自定義端點時使用的 OpenRouter 回退路徑

這種區別對於以下情況尤為重要：

- 本地模型伺服器
- 非 OpenRouter/非 AI Gateway 的 OpenAI 相容 API
- 在不重新運行設置的情況下切換供應商
- 已儲存在配置中的自定義端點，即使當前 shell 中未匯出 `OPENAI_BASE_URL`，也應繼續工作

## 原生 Anthropic 路徑

Anthropic 不再僅僅是「透過 OpenRouter」。

當供應商解析選擇 `anthropic` 時，Hermes 會使用：

- `api_mode = anthropic_messages`
- 原生 Anthropic Messages API
- `agent/anthropic_adapter.py` 進行轉換

原生 Anthropic 的認證資訊解析現在優先選用可重新整理的 Claude Code 認證資訊，而非複製的環境變數標記（當兩者都存在時）。實務上這意味著：

- Claude Code 認證檔案在包含可重新整理的認證時被視為優先來源
- 手動設置的 `ANTHROPIC_TOKEN` / `CLAUDE_CODE_OAUTH_TOKEN` 值仍可作為明確的覆蓋
- Hermes 在進行原生 Messages API 呼叫前會先嘗試重新整理 Anthropic 認證資訊
- Hermes 在重建 Anthropic 客戶端後遇到 401 錯誤時仍會重試一次，作為回退路徑

## OpenAI Codex 路徑

Codex 使用獨立的 Responses API 路徑：

- `api_mode = codex_responses`
- 專用的認證資訊解析和認證存儲支援

## 輔助模型路由 (Auxiliary model routing)

輔助任務，例如：

- 視覺 (vision)
- 網頁提取摘要 (web extraction summarization)
- 上下文壓縮摘要 (context compression summaries)
- 會話搜尋摘要 (session search summarization)
- 技能中心操作 (skills hub operations)
- MCP 輔助操作
- 記憶清理 (memory flushes)

可以使用它們自己的供應商/模型路由，而不是主要對話模型。

當輔助任務被配置為供應商 `main` 時，Hermes 會透過與正常聊天相同的共用執行階段路徑進行解析。實務上這意味著：

- 由環境變數驅動的自定義端點仍然有效
- 透過 `hermes model` / `config.yaml` 儲存的自定義端點也有效
- 輔助路由可以分辨真實儲存的自定義端點與 OpenRouter 回退方案之間的區別

## 回退模型 (Fallback models)

Hermes 支援配置回退模型/供應商配對，當主要模型遇到錯誤時，允許執行階段故障轉移 (failover)。

### 內部運作方式

1. **存儲**：`AIAgent.__init__` 儲存 `fallback_model` 字典並設置 `_fallback_activated = False`。

2. **觸發點**：從 `run_agent.py` 主要重試迴圈的三個地方呼叫 `_try_activate_fallback()`：
   - 在無效 API 回應（無選擇、缺少內容）達到最大重試次數後
   - 發生不可重試的客戶端錯誤（HTTP 401, 403, 404）時
   - 發生瞬時錯誤（HTTP 429, 500, 502, 503）達到最大重試次數後

3. **啟用流程** (`_try_activate_fallback`)：
   - 如果已啟用或未配置，立即返回 `False`
   - 呼叫 `auxiliary_client.py` 中的 `resolve_provider_client()` 以使用正確的認證建立新客戶端
   - 確定 `api_mode`：openai-codex 使用 `codex_responses`，anthropic 使用 `anthropic_messages`，其餘使用 `chat_completions`
   - 就地更換：`self.model`, `self.provider`, `self.base_url`, `self.api_mode`, `self.client`, `self._client_kwargs`
   - 對於 anthropic 回退：建立原生 Anthropic 客戶端而非 OpenAI 相容客戶端
   - 重新評估提示詞快取（在 OpenRouter 上對 Claude 模型啟用）
   - 設置 `_fallback_activated = True` — 防止再次觸發
   - 將重試計數重置為 0 並繼續迴圈

4. **配置流程**：
   - CLI：`cli.py` 讀取 `CLI_CONFIG["fallback_model"]` → 傳遞給 `AIAgent(fallback_model=...)`
   - 閘道器：`gateway/run.py._load_fallback_model()` 讀取 `config.yaml` → 傳遞給 `AIAgent`
   - 驗證：`provider` 和 `model` 鍵都必須非空，否則回退功能會被停用

### 不支援回退的情況

- **子代理委派** (`tools/delegate_tool.py`)：子代理繼承父級供應商，但不繼承回退配置
- **排程任務** (`cron/`)：以固定的供應商運行，沒有回退機制
- **輔助任務**：使用其獨立的供應商自動檢測鏈（見上述「輔助模型路由」）

### 測試覆蓋率

請參閱 `tests/test_fallback_model.py` 以獲取涵蓋所有支援的供應商、單次語義和邊緣情況的全面測試。

## 相關文件

- [代理迴圈內部機制 (Agent Loop Internals)](./agent-loop.md)
- [ACP 內部機制 (ACP Internals)](./acp-internals.md)
- [上下文壓縮與提示詞快取 (Context Compression & Prompt Caching)](./context-compression-and-caching.md)
