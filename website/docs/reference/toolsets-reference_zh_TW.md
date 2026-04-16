---
sidebar_position: 4
title: "工具集參考"
description: "Hermes 核心、複合、平台和動態工具集的參考"
---

# 工具集參考

工具集是控制代理人 (agent) 能力的具名工具套件。它們是針對每個平台、每個工作階段或每個任務配置工具可用性的主要機制。

## 工具集的工作原理

每個工具都恰好屬於一個工具集。當您啟用一個工具集時，該套件中的所有工具都將開放給代理人使用。工具集分為三種：

- **核心 (Core)** — 相關工具的單個邏輯分組（例如，`file` 套件包含 `read_file`、`write_file`、`patch`、`search_files`）
- **複合 (Composite)** — 為常見場景組合多個核心工具集（例如，`debugging` 套件包含檔案、終端機和網路工具）
- **平台 (Platform)** — 特定部署情境的完整工具配置（例如，`hermes-cli` 是互動式 CLI 工作階段的預設配置）

## 配置工具集

### 每個工作階段 (CLI)

```bash
hermes chat --toolsets web,file,terminal
hermes chat --toolsets debugging        # 複合 — 展開為 file + terminal + web
hermes chat --toolsets all              # 全部工具
```

### 每個平台 (config.yaml)

```yaml
toolsets:
  - hermes-cli          # CLI 的預設設定
  # - hermes-telegram   # 覆寫 Telegram 閘道的設定
```

### 互動式管理

```bash
hermes tools                            # curses 介面，可按平台啟用/禁用
```

或在工作階段中：

```
/tools list
/tools disable browser
/tools enable rl
```

## 核心工具集

| 工具集 | 工具 | 用途 |
|---------|-------|---------|
| `browser` | `browser_back`, `browser_click`, `browser_console`, `browser_get_images`, `browser_navigate`, `browser_press`, `browser_scroll`, `browser_snapshot`, `browser_type`, `browser_vision`, `web_search` | 完整的瀏覽器自動化。包含 `web_search` 作為快速查找的備案。 |
| `clarify` | `clarify` | 當代理人需要澄清時向用戶提問。 |
| `code_execution` | `execute_code` | 運行以程式化方式呼叫 Hermes 工具的 Python 腳本。 |
| `cronjob` | `cronjob` | 排程並管理定期任務。 |
| `delegation` | `delegate_task` | 產生隔離的子代理實例以進行並行工作。 |
| `file` | `patch`, `read_file`, `search_files`, `write_file` | 檔案讀取、寫入、搜尋和編輯。 |
| `homeassistant` | `ha_call_service`, `ha_get_state`, `ha_list_entities`, `ha_list_services` | 透過 Home Assistant 控制智慧家居。僅在設定 `HASS_TOKEN` 時可用。 |
| `image_gen` | `image_generate` | 透過 FAL.ai 進行文字轉圖片生成。 |
| `memory` | `memory` | 持久性的跨工作階段記憶管理。 |
| `messaging` | `send_message` | 從工作階段內向其他平台（Telegram、Discord 等）發送訊息。 |
| `moa` | `mixture_of_agents` | 透過代理人混合 (Mixture of Agents) 達成多模型共識。 |
| `rl` | `rl_check_status`, `rl_edit_config`, `rl_get_current_config`, `rl_get_results`, `rl_list_environments`, `rl_list_runs`, `rl_select_environment`, `rl_start_training`, `rl_stop_training`, `rl_test_inference` | RL 訓練環境管理 (Atropos)。 |
| `search` | `web_search` | 僅限網路搜尋（不含提取）。 |
| `session_search` | `session_search` | 搜尋過去的對話工作階段。 |
| `skills` | `skill_manage`, `skill_view`, `skills_list` | 技能的增刪改查 (CRUD) 與瀏覽。 |
| `terminal` | `process`, `terminal` | Shell 指令執行與背景程序管理。 |
| `todo` | `todo` | 工作階段內的任務清單管理。 |
| `tts` | `text_to_speech` | 文字轉語音音訊生成。 |
| `vision` | `vision_analyze` | 透過具備視覺能力的模型進行圖片分析。 |
| `web` | `web_extract`, `web_search` | 網路搜尋與網頁內容提取。 |

## 複合工具集

這些工具集展開為多個核心工具集，為常見場景提供便捷的縮寫：

| 工具集 | 展開為 | 使用案例 |
|---------|-----------|----------|
| `debugging` | `patch`, `process`, `read_file`, `search_files`, `terminal`, `web_extract`, `web_search`, `write_file` | 除錯工作階段 — 提供檔案存取、終端機和網路研究能力，且無瀏覽器或委派 (delegation) 開銷。 |
| `safe` | `image_generate`, `vision_analyze`, `web_extract`, `web_search` | 唯讀研究與媒體生成。無檔案寫入、無終端機存取、無程式碼執行。適用於不受信任或受限的環境。 |

## 平台工具集

平台工具集定義了部署目標的完整工具配置。大多數通訊平台使用與 `hermes-cli` 相同的設定：

| 工具集 | 與 `hermes-cli` 的差異 |
|---------|-------------------------------|
| `hermes-cli` | 完整工具集 — 包含 `clarify` 在內的所有 36 個工具。互動式 CLI 工作階段的預設值。 |
| `hermes-acp` | 移除 `clarify`、`cronjob`、`image_generate`、`send_message`、`text_to_speech` 及 Home Assistant 工具。專注於 IDE 情境中的編碼任務。 |
| `hermes-api-server` | 移除 `clarify`、`send_message` 和 `text_to_speech`。加入其他所有工具 — 適用於無法進行用戶互動的程式化存取。 |
| `hermes-telegram` | 與 `hermes-cli` 相同。 |
| `hermes-discord` | 與 `hermes-cli` 相同。 |
| `hermes-slack` | 與 `hermes-cli` 相同。 |
| `hermes-whatsapp` | 與 `hermes-cli` 相同。 |
| `hermes-signal` | 與 `hermes-cli` 相同。 |
| `hermes-matrix` | 與 `hermes-cli` 相同。 |
| `hermes-mattermost` | 與 `hermes-cli` 相同。 |
| `hermes-email` | 與 `hermes-cli` 相同。 |
| `hermes-sms` | 與 `hermes-cli` 相同。 |
| `hermes-dingtalk` | 與 `hermes-cli` 相同。 |
| `hermes-feishu` | 與 `hermes-cli` 相同。 |
| `hermes-wecom` | 與 `hermes-cli` 相同。 |
| `hermes-wecom-callback` | 企業微信回呼工具集 — 企業自建應用訊息傳遞（完整權限）。 |
| `hermes-weixin` | 與 `hermes-cli` 相同。 |
| `hermes-bluebubbles` | 與 `hermes-cli` 相同。 |
| `hermes-qqbot` | 與 `hermes-cli` 相同。 |
| `hermes-homeassistant` | 與 `hermes-cli` 相同。 |
| `hermes-webhook` | 與 `hermes-cli` 相同。 |
| `hermes-gateway` | 所有通訊平台工具集的聯集。當閘道需要最廣泛的工具集時在內部使用。 |

## 動態工具集

### MCP 伺服器工具集

每個配置的 MCP 伺服器都會在執行時生成一個 `mcp-<server>` 工具集。例如，如果您配置了一個 `github` MCP 伺服器，系統會建立一個 `mcp-github` 工具集，其中包含該伺服器公開的所有工具。

```yaml
# config.yaml
mcp:
  servers:
    github:
      command: npx
      args: ["-y", "@modelcontextprotocol/server-github"]
```

這會建立一個您可以在 `--toolsets` 或平台配置中引用的 `mcp-github` 工具集。

### 插件工具集

插件可以在初始化期間透過 `ctx.register_tool()` 註冊自己的工具集。這些工具集會與內建工具集一起出現，且可以用同樣的方式啟用/禁用。

### 自定義工具集

在 `config.yaml` 中定義自定義工具集，以建立專案特定的套件：

```yaml
toolsets:
  - hermes-cli
custom_toolsets:
  data-science:
    - file
    - terminal
    - code_execution
    - web
    - vision
```

### 萬用字元

- `all` 或 `*` — 展開為每個已註冊的工具集（內建 + 動態 + 插件）

## 與 `hermes tools` 的關係

`hermes tools` 指令提供了一個基於 curses 的使用者介面，用於按平台切換單個工具的開啟或關閉。此操作是在工具層級進行的（比工具集更細緻），並持久儲存到 `config.yaml` 中。被禁用的工具即使其所屬工具集已啟用，也會被過濾掉。

另請參閱：[工具參考](./tools-reference.md) 以獲取單個工具及其參數的完整列表。
