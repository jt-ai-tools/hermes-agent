---
sidebar_position: 1
title: "架構"
description: "Hermes Agent 內部機制 — 主要子系統、執行路徑、資料流，以及後續閱讀建議"
---

# 架構

本頁面是 Hermes Agent 內部機制的頂層地圖。請以此作為在程式碼庫中定位的參考，然後深入各子系統的專屬文件以瞭解實作細節。

## 系統概覽

```text
┌─────────────────────────────────────────────────────────────────────┐
│                          進入點 (Entry Points)                       │
│                                                                      │
│  CLI (cli.py)    閘道器 (gateway/run.py)     ACP (acp_adapter/)      │
│  批次執行器        API 伺服器                  Python 函式庫           │
└──────────┬──────────────┬───────────────────────┬───────────────────┘
           │              │                       │
           ▼              ▼                       ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     AIAgent (run_agent.py)                           │
│                                                                      │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐                │
│  │ 提示詞        │ │ 提供者       │ │ 工具         │                │
│  │ 構建器        │ │ 解析         │ │ 調度         │                │
│  │ (prompt_      │ │ (runtime_    │ │ (model_      │                │
│  │  builder.py)  │ │  provider.py)│ │  tools.py)   │                │
│  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘                │
│         │                │                │                          │
│  ┌──────┴───────┐ ┌──────┴───────┐ ┌──────┴───────┐                │
│  │ 壓縮與快取     │ │ 3 種 API 模式 │ │ 工具註冊表    │                │
│  │              │ │ chat_compl.  │ │ (registry.py)│                │
│  │              │ │ codex_resp.  │ │ 47 個工具     │                │
│  │              │ │ anthropic    │ │ 19 個工具集   │                │
│  └──────────────┘ └──────────────┘ └──────────────┘                │
└─────────────────────────────────────────────────────────────────────┘
           │                                    │
           ▼                                    ▼
┌───────────────────┐              ┌──────────────────────┐
│ 對話儲存           │              │ 工具後端 (Tool Backends)│
│ (SQLite + FTS5)   │              │ 終端機 (6 個後端)     │
│ hermes_state.py   │              │ 瀏覽器 (5 個後端)     │
│ gateway/session.py│              │ 網路 (4 個後端)       │
└───────────────────┘              │ MCP (動態)            │
                                   │ 檔案、視覺等          │
                                   └──────────────────────┘
```

## 目錄結構

```text
hermes-agent/
├── run_agent.py              # AIAgent — 核心對話迴圈 (~10,700 行)
├── cli.py                    # HermesCLI — 互動式終端機 UI (~10,000 行)
├── model_tools.py            # 工具發現、Schema 收集、調度
├── toolsets.py               # 工具分組與平台預設集
├── hermes_state.py           # 支援 FTS5 的 SQLite 對話/狀態資料庫
├── hermes_constants.py       # HERMES_HOME，感知設定檔 (profile) 的路徑
├── batch_runner.py           # 批次軌跡 (trajectory) 生成
│
├── agent/                    # 代理核心內部
│   ├── prompt_builder.py     # 系統提示詞組裝
│   ├── context_engine.py     # ContextEngine 抽象基底類別 (可插拔)
│   ├── context_compressor.py # 預設引擎 — 有損摘要
│   ├── prompt_caching.py     # Anthropic 提示詞快取
│   ├── auxiliary_client.py   # 用於輔助任務的輔助 LLM (視覺、摘要)
│   ├── model_metadata.py     # 模型上下文長度、Token 預估
│   ├── models_dev.py         # models.dev 註冊表整合
│   ├── anthropic_adapter.py  # Anthropic Messages API 格式轉換
│   ├── display.py            # KawaiiSpinner、工具預覽格式化
│   ├── skill_commands.py     # 技能斜線指令
│   ├── memory_manager.py     # 記憶管理器編排
│   ├── memory_provider.py    # 記憶提供者抽象基底類別
│   └── trajectory.py         # 軌跡儲存助手
│
├── hermes_cli/               # CLI 子指令與設定
│   ├── main.py               # 入口點 — 所有 `hermes` 子指令 (~6,000 行)
│   ├── config.py             # DEFAULT_CONFIG, OPTIONAL_ENV_VARS, 遷移
│   ├── commands.py           # COMMAND_REGISTRY — 中央斜線指令定義
│   ├── auth.py               # PROVIDER_REGISTRY, 憑證解析
│   ├── runtime_provider.py   # 提供者 → api_mode + 憑證
│   ├── models.py             # 模型目錄、提供者模型列表
│   ├── model_switch.py       # /model 指令邏輯 (CLI 與閘道器共享)
│   ├── setup.py              # 互動式設定精靈 (~3,100 行)
│   ├── skin_engine.py        # CLI 主題引擎
│   ├── skills_config.py      # hermes skills — 各平台啟用/停用
│   ├── skills_hub.py         # /skills 斜線指令
│   ├── tools_config.py       # hermes tools — 各平台啟用/停用
│   ├── plugins.py            # PluginManager — 發現、載入、鉤子 (hooks)
│   ├── callbacks.py          # 終端機回呼 (澄清、sudo、核准)
│   └── gateway.py            # hermes gateway 啟動/停止
│
├── tools/                    # 工具實作 (每個工具一個檔案)
│   ├── registry.py           # 中央工具註冊表
│   ├── approval.py           # 危險指令偵測
│   ├── terminal_tool.py      # 終端機編排
│   ├── process_registry.py   # 背景程序管理
│   ├── file_tools.py         # read_file, write_file, patch, search_files
│   ├── web_tools.py          # web_search, web_extract
│   ├── browser_tool.py       # 10 個瀏覽器自動化工具
│   ├── code_execution_tool.py # execute_code 沙盒
│   ├── delegate_tool.py      # 子代理委派
│   ├── mcp_tool.py           # MCP 客戶端 (~2,200 行)
│   ├── credential_files.py   # 檔案式憑證透傳
│   ├── env_passthrough.py    # 沙盒的環境變數透傳
│   ├── ansi_strip.py         # ANSI 轉義字元清除
│   └── environments/         # 終端機後端 (local, docker, ssh, modal, daytona, singularity)
│
├── gateway/                  # 訊息平台閘道器
│   ├── run.py                # GatewayRunner — 訊息分發 (~9,000 行)
│   ├── session.py            # SessionStore — 對話內容持久化
│   ├── delivery.py           # 出站訊息遞送
│   ├── pairing.py            # 私訊配對授權
│   ├── hooks.py              # 鉤子發現與生命週期事件
│   ├── mirror.py             # 跨對話訊息鏡像
│   ├── status.py             # 令牌鎖定、設定檔範圍的程序追蹤
│   ├── builtin_hooks/        # 始終註冊的鉤子
│   └── platforms/            # 18 個適配器：telegram, discord, slack, whatsapp,
│                             #   signal, matrix, mattermost, email, sms,
│                             #   dingtalk, feishu, wecom, wecom_callback, weixin,
│                             #   bluebubbles, qqbot, homeassistant, webhook, api_server
│
├── acp_adapter/              # ACP 伺服器 (VS Code / Zed / JetBrains)
├── cron/                     # 排程器 (jobs.py, scheduler.py)
├── plugins/memory/           # 記憶提供者插件
├── plugins/context_engine/   # 上下文引擎插件
├── environments/             # 強化學習 (RL) 訓練環境 (Atropos)
├── skills/                   # 內置技能 (始終可用)
├── optional-skills/          # 官方可選技能 (需顯式安裝)
├── website/                  # Docusaurus 文件網站
└── tests/                    # Pytest 測試套件 (~3,000+ 個測試)
```

## 資料流

### CLI 對話 (Session)

```text
使用者輸入 → HermesCLI.process_input()
  → AIAgent.run_conversation()
    → prompt_builder.build_system_prompt()
    → runtime_provider.resolve_runtime_provider()
    → API 呼叫 (chat_completions / codex_responses / anthropic_messages)
    → 需要呼叫工具？ → model_tools.handle_function_call() → 進入迴圈
    → 最終回應 → 顯示 → 儲存至 SessionDB
```

### 閘道器訊息

```text
平台事件 → 適配器.on_message() → MessageEvent
  → GatewayRunner._handle_message()
    → 授權使用者
    → 解析對話密鑰 (session key)
    → 使用對話歷史記錄建立 AIAgent
    → AIAgent.run_conversation()
    → 透過適配器將回應送回
```

### 排程任務 (Cron Job)

```text
排程器 Tick → 從 jobs.json 載入到期任務
  → 建立全新的 AIAgent (無歷史記錄)
  → 注入附加的技能作為上下文
  → 執行任務提示詞
  → 將回應傳送至目標平台
  → 更新任務狀態與下一次執行時間 (next_run)
```

## 建議閱讀順序

如果您是程式碼庫的新手：

1. **本頁面** — 定位導覽
2. **[代理迴圈內部機制](./agent-loop.md)** — AIAgent 如何運作
3. **[提示詞組裝](./prompt-assembly.md)** — 系統提示詞的構建方式
4. **[提供者運行時解析](./provider-runtime.md)** — 如何選擇提供者
5. **[新增提供者](./adding-providers.md)** — 新增提供者的實務指南
6. **[工具運行時](./tools-runtime.md)** — 工具註冊、分發與環境
7. **[對話儲存](./session-storage.md)** — SQLite Schema、FTS5 與對話血統
8. **[閘道器內部機制](./gateway-internals.md)** — 訊息平台閘道器
9. **[上下文壓縮與提示詞快取](./context-compression-and-caching.md)** — 壓縮與快取機制
10. **[ACP 內部機制](./acp-internals.md)** — IDE 整合
11. **[環境、基準測試與資料生成](./environments.md)** — 強化學習訓練相關

## 主要子系統

### 代理迴圈 (Agent Loop)

同步編排引擎 (`run_agent.py` 中的 `AIAgent`)。處理提供者選擇、提示詞構建、工具執行、重試、降級方案 (fallback)、回呼、壓縮以及持久化。針對不同提供者後端支援三種 API 模式。

→ [代理迴圈內部機制](./agent-loop.md)

### 提示詞系統

在整個對話生命週期中構建與維護提示詞：

- **`prompt_builder.py`** — 從以下內容組裝系統提示詞：人格 (SOUL.md)、記憶 (MEMORY.md, USER.md)、技能、上下文檔案 (AGENTS.md, .hermes.md)、工具使用指南以及特定模型的指令。
- **`prompt_caching.py`** — 套用 Anthropic 快取斷點以實現前綴快取。
- **`context_compressor.py`** — 當上下文超過閾值時摘要中間的對話輪次。

→ [提示詞組裝](./prompt-assembly.md), [上下文壓縮與提示詞快取](./context-compression-and-caching.md)

### 提供者解析 (Provider Resolution)

CLI、閘道器、排程器、ACP 與輔助呼叫所使用的共享運行時解析器。將 `(provider, model)` 元組映射至 `(api_mode, api_key, base_url)`。支援 18 種以上的提供者、OAuth 流程、憑證池以及別名解析。

→ [提供者運行時解析](./provider-runtime.md)

### 工具系統

中央工具註冊表 (`tools/registry.py`)，橫跨 19 個工具集，共有 47 個已註冊工具。每個工具檔案在載入時會自我註冊。註冊表處理 Schema 收集、調度、可用性檢查以及錯誤封裝。終端機工具支援 6 個後端 (local, Docker, SSH, Daytona, Modal, Singularity)。

→ [工具運行時](./tools-runtime.md)

### 對話持久化 (Session Persistence)

基於 SQLite 的對話儲存，支援 FTS5 全文檢索。對話具有血統追蹤 (跨壓縮的父子關係)、各平台隔離以及具備衝突處理能力的原子寫入。

→ [對話儲存](./session-storage.md)

### 訊息閘道器 (Messaging Gateway)

具有 18 個平台適配器的長期執行程序，提供統一的對話路由、使用者授權 (白名單 + 私訊配對)、斜線指令調度、鉤子系統、排程 Tick 以及背景維護。

→ [閘道器內部機制](./gateway-internals.md)

### 插件系統 (Plugin System)

三種發現來源：`~/.hermes/plugins/` (使用者)、`.hermes/plugins/` (專案) 以及 pip 進入點。插件透過上下文 API 註冊工具、鉤子與 CLI 指令。存在兩種特殊的插件類型：記憶提供者 (`plugins/memory/`) 與上下文引擎 (`plugins/context_engine/`)。兩者皆為單選模式 — 同一時間只能啟用一個，可透過 `hermes plugins` 或 `config.yaml` 進行配置。

→ [插件指南](/docs/guides/build-a-hermes-plugin), [記憶提供者插件](./memory-provider-plugin.md)

### 排程 (Cron)

一等代理任務 (並非 Shell 任務)。任務儲存為 JSON 格式，支援多種排程格式，可附加技能與腳本，並可傳送至任何平台。

→ [排程內部機制](./cron-internals.md)

### ACP 整合

透過 stdio/JSON-RPC 將 Hermes 公開為編輯器原生代理，適用於 VS Code、Zed 與 JetBrains。

→ [ACP 內部機制](./acp-internals.md)

### 強化學習 / 環境 / 軌跡

用於評估與強化學習 (RL) 訓練的完整環境框架。整合 Atropos，支援多種工具呼叫解析器，並生成 ShareGPT 格式的軌跡。

→ [環境、基準測試與資料生成](./environments.md), [軌跡與訓練格式](./trajectory-format.md)

## 設計原則

| 原則 | 實務意義 |
|-----------|--------------------------|
| **提示詞穩定性 (Prompt stability)** | 系統提示詞在對話中途不會改變。除了顯式的使用者動作 (`/model`) 外，不會有破壞快取的變動。 |
| **可觀察的執行 (Observable execution)** | 每一次工具呼叫都透過回呼對使用者可見。CLI (進度環) 與閘道器 (聊天訊息) 會顯示進度更新。 |
| **可中斷 (Interruptible)** | 使用者輸入或訊號可以隨時中斷正在進行中的 API 呼叫與工具執行。 |
| **平台無關的核心 (Platform-agnostic core)** | 同一個 AIAgent 類別服務於 CLI、閘道器、ACP、批次執行與 API 伺服器。平台差異存在於入口點，而非代理本身。 |
| **鬆散耦合 (Loose coupling)** | 選配子系統 (MCP、插件、記憶提供者、RL 環境) 使用註冊表模式與 check_fn 門控，而非硬性依賴。 |
| **設定檔隔離 (Profile isolation)** | 每個設定檔 (`hermes -p <名稱>`) 擁有專屬的 HERMES_HOME、配置、記憶、對話與閘道器 PID。多個設定檔可並行執行。 |

## 檔案依賴鏈

```text
tools/registry.py  (無依賴 — 由所有工具檔案載入)
       ↑
tools/*.py  (每個檔案在載入時呼叫 registry.register())
       ↑
model_tools.py  (載入 tools/registry + 觸發工具發現)
       ↑
run_agent.py, cli.py, batch_runner.py, environments/
```

這條鏈條意味著工具註冊發生在載入時，早於任何代理實例建立之前。任何包含頂層 `registry.register()` 呼叫的 `tools/*.py` 檔案都會被自動發現 — 無需手動維護載入列表。
