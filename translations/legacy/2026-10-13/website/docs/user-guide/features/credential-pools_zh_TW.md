---
title: 憑證池
description: 為每個供應商配置多個 API 金鑰或 OAuth 權杖，以實現自動輪轉與速率限制恢復。
sidebar_label: 憑證池
sidebar_position: 9
---

# 憑證池 (Credential Pools)

憑證池允許您為同一個供應商註冊多個 API 金鑰或 OAuth 權杖。當其中一個金鑰達到速率限制 (Rate limit) 或計費額度時，Hermes 會自動輪轉到下一個健康的金鑰 — 讓您的對話持續進行，而無需切換供應商。

這與[備援供應商 (Fallback Providers)](./fallback-providers.md) 不同，後者會切換到完全**不同**的供應商。憑證池是同供應商內的輪轉；而備援供應商則是跨供應商的故障移轉 (Failover)。系統會優先嘗試憑證池 — 若池中所有金鑰皆已耗盡，*才會* 啟用備援供應商。

## 運作方式

```
您的請求
  → 從池中挑選金鑰 (round_robin / least_used / fill_first / random)
  → 發送至供應商
  → 遇到 429 速率限制？
      → 嘗試重新使用同一金鑰一次（可能是暫時性波動）
      → 第二次 429 → 輪轉至池中下一個金鑰
      → 所有金鑰皆耗盡 → fallback_model（切換至不同供應商）
  → 遇到 402 計費錯誤？
      → 立即輪轉至下一個金鑰（設有 24 小時冷卻期）
  → 遇到 401 認證過期？
      → 嘗試重新整理權杖 (OAuth)
      → 重新整理失敗 → 輪轉至下一個金鑰
  → 成功 → 正常繼續
```

## 快速上手

如果您已在 `.env` 中設定了 API 金鑰，Hermes 會自動將其識別為僅含 1 個金鑰的憑證池。若要發揮憑證池的優勢，請新增更多金鑰：

```bash
# 新增第二個 OpenRouter 金鑰
hermes auth add openrouter --api-key sk-or-v1-your-second-key

# 新增第二個 Anthropic 金鑰
hermes auth add anthropic --type api-key --api-key sk-ant-api03-your-second-key

# 新增 Anthropic OAuth 憑證（Claude Code 訂閱）
hermes auth add anthropic --type oauth
# 這會開啟瀏覽器進行 OAuth 登入
```

檢查您的憑證池：

```bash
hermes auth list
```

輸出範例：
```
openrouter (2 credentials):
  #1  OPENROUTER_API_KEY   api_key env:OPENROUTER_API_KEY ←
  #2  backup-key           api_key manual

anthropic (3 credentials):
  #1  hermes_pkce          oauth   hermes_pkce ←
  #2  claude_code          oauth   claude_code
  #3  ANTHROPIC_API_KEY    api_key env:ANTHROPIC_API_KEY
```

標記 `←` 表示目前選用的憑證。

## 互動式管理

直接執行 `hermes auth`（不加子指令）即可開啟互動式管理精靈：

```bash
hermes auth
```

這會顯示完整的憑證池狀態並提供選單：

```
What would you like to do?
  1. Add a credential (新增憑證)
  2. Remove a credential (移除憑證)
  3. Reset cooldowns for a provider (重設供應商冷卻時間)
  4. Set rotation strategy for a provider (設定供應商輪轉策略)
  5. Exit (退出)
```

對於支援 API 金鑰與 OAuth 的供應商（如 Anthropic、Nous、Codex），新增流程會詢問類型：

```
anthropic supports both API keys and OAuth login.
  1. API key (貼上供應商儀表板提供的金鑰)
  2. OAuth login (透過瀏覽器認證)
Type [1/2]:
```

## CLI 指令參考

| 指令 | 描述 |
|---------|-------------|
| `hermes auth` | 互動式憑證池管理精靈 |
| `hermes auth list` | 顯示所有憑證池與憑證 |
| `hermes auth list <provider>` | 顯示特定供應商的憑證池 |
| `hermes auth add <provider>` | 新增憑證（會提示類型與金鑰） |
| `hermes auth add <provider> --type api-key --api-key <key>` | 以非互動方式新增 API 金鑰 |
| `hermes auth add <provider> --type oauth` | 透過瀏覽器登入新增 OAuth 憑證 |
| `hermes auth remove <provider> <index>` | 透過索引編號（從 1 開始）移除憑證 |
| `hermes auth reset <provider>` | 清除所有冷卻中/已耗盡的狀態 |

## 輪轉策略 (Rotation Strategies)

可透過 `hermes auth` → "Set rotation strategy" 設定，或直接修改 `config.yaml`：

```yaml
credential_pool_strategies:
  openrouter: round_robin
  anthropic: least_used
```

| 策略 | 行為 |
|----------|----------|
| `fill_first` (預設) | 優先使用第一個健康的金鑰直到耗盡，再換下一個 |
| `round_robin` | 輪流使用每個金鑰，每次選取後即進行切換 |
| `least_used` | 一律選取請求次數最少的金鑰 |
| `random` | 在健康金鑰中隨機選取 |

## 錯誤恢復機制

憑證池會針對不同錯誤採取不同行動：

| 錯誤類型 | 行為 | 冷卻期 |
|-------|----------|----------|
| **429 速率限制** | 重新嘗試同一金鑰一次。若連續出現第二次 429 則輪轉至下一金鑰 | 1 小時 |
| **402 計費/額度不足** | 立即輪轉至下一個金鑰 | 24 小時 |
| **401 認證過期** | 優先嘗試重新整理 OAuth 權杖。僅在重新整理失敗時輪轉 | — |
| **所有金鑰耗盡** | 若有配置 `fallback_model`，則切換至該備援模型 | — |

`has_retried_429` 標記會在每次 API 呼叫成功後重設，因此單次的暫時性 429 不會觸發輪轉。

## 自定義端點憑證池

相容於 OpenAI 的自定義端點（如 Together.ai、RunPod、本地伺服器）擁有各自的憑證池，其鍵值為 `config.yaml` 中 `custom_providers` 的名稱。

當您透過 `hermes model` 設定自定義端點時，系統會自動生成如 "Together.ai" 或 "Local (localhost:8080)" 的名稱，該名稱即為憑證池的鍵值。

```bash
# 透過 hermes model 設定自定義端點後：
hermes auth list
# 顯示：
#   Together.ai (1 credential):
#     #1  config key    api_key config:Together.ai ←

# 為同一個端點新增第二組金鑰：
hermes auth add Together.ai --api-key sk-together-second-key
```

自定義端點憑證池存放在 `auth.json` 的 `credential_pool` 中，並帶有 `custom:` 前綴：

```json
{
  "credential_pool": {
    "openrouter": [...],
    "custom:together.ai": [...]
  }
}
```

## 自動探索

Hermes 啟動時會從多個來源自動探索憑證並填充至憑證池：

| 來源 | 範例 | 是否自動填充？ |
|--------|---------|-------------|
| 環境變數 | `OPENROUTER_API_KEY`, `ANTHROPIC_API_KEY` | 是 |
| OAuth 權杖 (auth.json) | Codex 裝置代碼, Nous 裝置代碼 | 是 |
| Claude Code 憑證 | `~/.claude/.credentials.json` | 是 (Anthropic) |
| Hermes PKCE OAuth | `~/.hermes/auth.json` | 是 (Anthropic) |
| 自定義端點配置 | `config.yaml` 中的 `model.api_key` | 是 (自定義端點) |
| 手動輸入項目 | 透過 `hermes auth add` 新增 | 持久化存於 auth.json |

自動填充的項目會在每次載入憑證池時更新 — 如果您移除了某個環境變數，對應的項目也會自動被剔除。手動新增的項目（透過 `hermes auth add`）則絕不會被自動剔除。

## 委派與子代理共享 (Delegation & Subagent Sharing)

當代理透過 `delegate_task` 建立子代理時，父代理的憑證池會自動共享給子代理：

- **相同供應商** — 子代理接收父代理完整的憑證池，使其能在遇到速率限制時輪轉金鑰。
- **不同供應商** — 子代理載入該供應商自身的憑證池（若有配置）。
- **未配置憑證池** — 子代理退而使用繼承的單一 API 金鑰。

這表示子代理無需額外設定即可享有與父代理相同的速率限制抗性。透過「每項任務憑證租賃」機制，可確保子代理在並行輪轉金鑰時不會發生衝突。

## 執行緒安全 (Thread Safety)

憑證池對所有狀態變更（`select()`、`mark_exhausted_and_rotate()`、`try_refresh_current()`、`mark_used()`）皆使用了執行緒鎖 (Threading lock)。這確保了當閘道器 (Gateway) 同時處理多個聊天階段時，並行存取是安全的。

## 架構說明

完整的資料流圖請參閱存儲庫中的 [`docs/credential-pool-flow.excalidraw`](https://excalidraw.com/#json=2Ycqhqpi6f12E_3ITyiwh,c7u9jSt5BwrmiVzHGbm87g)。

憑證池整合在供應商解析層：

1. **`agent/credential_pool.py`** — 憑證池管理員：負責儲存、選取、輪轉及冷卻。
2. **`hermes_cli/auth_commands.py`** — CLI 指令與互動式精靈。
3. **`hermes_cli/runtime_provider.py`** — 具備憑證池感知的憑證解析。
4. **`run_agent.py`** — 錯誤恢復：處理 429/402/401 錯誤 → 執行憑證池輪轉 → 執行備援方案。

## 儲存位置

憑證池狀態儲存在 `~/.hermes/auth.json` 的 `credential_pool` 鍵值下：

```json
{
  "version": 1,
  "credential_pool": {
    "openrouter": [
      {
        "id": "abc123",
        "label": "OPENROUTER_API_KEY",
        "auth_type": "api_key",
        "priority": 0,
        "source": "env:OPENROUTER_API_KEY",
        "access_token": "sk-or-v1-...",
        "last_status": "ok",
        "request_count": 142
      }
    ]
  }
}
```

輪轉策略儲存在 `config.yaml`（而非 `auth.json`）：

```yaml
credential_pool_strategies:
  openrouter: round_robin
  anthropic: least_used
```
