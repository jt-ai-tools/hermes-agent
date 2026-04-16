---
sidebar_position: 11
title: "ACP 編輯器整合"
description: "在 VS Code、Zed 和 JetBrains 等支援 ACP 的編輯器中使用 Hermes Agent"
---

# ACP 編輯器整合

Hermes Agent 可以作為 ACP 伺服器執行，讓支援 ACP 的編輯器透過 stdio 與 Hermes 通訊並呈現：

- 聊天訊息
- 工具活動
- 檔案差異 (diffs)
- 終端機指令
- 核准提示
- 串流思考 / 回應區塊

如果您希望 Hermes 的行為像編輯器原生的程式碼助理，而不是獨立的 CLI 或通訊機器人，ACP 是一個很好的選擇。

## Hermes 在 ACP 模式中提供的功能

Hermes 執行時使用專為編輯器工作流設計的 `hermes-acp` 工具集。它包括：

- 檔案工具：`read_file`、`write_file`、`patch`、`search_files`
- 終端機工具：`terminal`、`process`
- 網路/瀏覽器工具
- 記憶、待辦事項、工作階段搜尋
- 技能 (Skills)
- `execute_code` 與 `delegate_task`
- 視覺 (Vision)

它刻意排除了不適合典型編輯器使用者體驗的功能，例如訊息傳送和 cron 排程管理。

## 安裝

正常安裝 Hermes，然後添加 ACP 額外組件：

```bash
pip install -e '.[acp]'
```

這會安裝 `agent-client-protocol` 依賴項並啟用：

- `hermes acp`
- `hermes-acp`
- `python -m acp_adapter`

## 啟動 ACP 伺服器

以下任何指令都可以啟動 ACP 模式下的 Hermes：

```bash
hermes acp
```

```bash
hermes-acp
```

```bash
python -m acp_adapter
```

Hermes 將日誌輸出到 stderr，以便將 stdout 留給 ACP JSON-RPC 流量使用。

## 編輯器設定

### VS Code

安裝 ACP 用戶端擴充功能，然後將其指向儲存庫的 `acp_registry/` 目錄。

設定片段範例：

```json
{
  "acpClient.agents": [
    {
      "name": "hermes-agent",
      "registryDir": "/path/to/hermes-agent/acp_registry"
    }
  ]
}
```

### Zed

設定片段範例：

```json
{
  "agent_servers": {
    "hermes-agent": {
      "type": "custom",
      "command": "hermes",
      "args": ["acp"],
    },
  },
}
```

### JetBrains

使用支援 ACP 的外掛程式並將其指向：

```text
/path/to/hermes-agent/acp_registry
```

## 註冊清單 (Registry Manifest)

ACP 註冊清單位於：

```text
acp_registry/agent.json
```

它宣告了一個基於指令的代理，其啟動指令為：

```text
hermes acp
```

## 配置與憑據

ACP 模式使用與 CLI 相同的 Hermes 配置：

- `~/.hermes/.env`
- `~/.hermes/config.yaml`
- `~/.hermes/skills/`
- `~/.hermes/state.db`

提供者解析使用 Hermes 的正常執行時期解析器，因此 ACP 會繼承目前配置的提供者和憑據。

## 工作階段 (Session) 行為

在伺服器執行期間，ACP 工作階段由 ACP 轉接器 (Adapter) 的記憶體工作階段管理員追蹤。

每個工作階段儲存：

- 工作階段 ID
- 工作目錄
- 選定的模型
- 目前對話歷史
- 取消事件

底層的 `AIAgent` 仍使用 Hermes 的正常持久化/日誌路徑，但 ACP 的 `list/load/resume/fork` 僅限於目前執行的 ACP 伺服器程序。

## 工作目錄行為

ACP 工作階段將編輯器的工作目錄 (CWD) 與 Hermes 任務 ID 綁定，因此檔案和終端機工具是相對於編輯器工作區執行的，而不是伺服器程序的工作目錄。

## 核准

危險的終端機指令可以作為核准提示路由回編輯器。ACP 核准選項比 CLI 流程更簡單：

- 允許一次 (Allow once)
- 永遠允許 (Allow always)
- 拒絕 (Deny)

逾時或發生錯誤時，核准橋接器會拒絕請求。

## 故障排除

### ACP 代理未出現在編輯器中

請檢查：

- 編輯器是否指向正確的 `acp_registry/` 路徑
- Hermes 是否已安裝且位於您的 PATH 中
- 是否已安裝 ACP 額外組件 (`pip install -e '.[acp]'`)

### ACP 已啟動但立即報錯

嘗試以下檢查：

```bash
hermes doctor
hermes status
hermes acp
```

### 遺失憑據

ACP 模式沒有自己的登入流程。它使用 Hermes 現有的提供者設定。請使用以下方式配置憑據：

```bash
hermes model
```

或編輯 `~/.hermes/.env`。

## 另請參閱

- [ACP 內部機制](../../developer-guide/acp-internals.md)
- [提供者執行時期解析](../../developer-guide/provider-runtime.md)
- [工具執行時期](../../developer-guide/tools-runtime.md)
