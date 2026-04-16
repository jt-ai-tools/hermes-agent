---
sidebar_position: 2
title: "ACP 內部原理"
description: "ACP 適配器的工作原理：生命週期、工作階段、事件橋接、審核與工具渲染"
---

# ACP 內部原理 (ACP Internals)

ACP 適配器 (adapter) 將 Hermes 的同步 `AIAgent` 封裝在一個非同步的 JSON-RPC stdio 伺服器中。

關鍵實作檔案：

- `acp_adapter/entry.py`
- `acp_adapter/server.py`
- `acp_adapter/session.py`
- `acp_adapter/events.py`
- `acp_adapter/permissions.py`
- `acp_adapter/tools.py`
- `acp_adapter/auth.py`
- `acp_registry/agent.json`

## 啟動流程

```text
hermes acp / hermes-acp / python -m acp_adapter
  -> acp_adapter.entry.main()
  -> 載入 ~/.hermes/.env
  -> 設定 stderr 記錄 (logging)
  -> 建構 HermesACPAgent
  -> acp.run_agent(agent)
```

Stdout 保留給 ACP JSON-RPC 傳輸使用。人類可讀的日誌則輸出到 stderr。

## 主要組件

### `HermesACPAgent`

`acp_adapter/server.py` 實作了 ACP 代理協定。

職責：

- 初始化 / 身分驗證
- 新建/載入/恢復/分叉/列出/取消工作階段等方法
- 提示詞 (prompt) 執行
- 工作階段模型切換
- 將同步 AIAgent 回呼串接到 ACP 非同步通知中

### `SessionManager`

`acp_adapter/session.py` 追蹤活躍的 ACP 工作階段 (Session)。

每個工作階段存儲：

- `session_id`
- `agent`
- `cwd` (工作目錄)
- `model` (模型)
- `history` (歷史紀錄)
- `cancel_event` (取消事件)

該管理員是執行緒安全的，並支援：

- 建立 (create)
- 取得 (get)
- 移除 (remove)
- 分叉 (fork)
- 列出 (list)
- 清理 (cleanup)
- 工作目錄更新 (cwd updates)

### 事件橋接 (Event bridge)

`acp_adapter/events.py` 將 AIAgent 回呼轉換為 ACP `session_update` 事件。

橋接的回呼：

- `tool_progress_callback` (工具進度回呼)
- `thinking_callback` (思考回呼)
- `step_callback` (步驟回呼)
- `message_callback` (訊息回呼)

由於 `AIAgent` 在工作執行緒中執行，而 ACP I/O 位於主事件迴圈上，因此橋接器使用：

```python
asyncio.run_coroutine_threadsafe(...)
```

### 權限橋接 (Permission bridge)

`acp_adapter/permissions.py` 將危險終端機指令的審核提示轉換為 ACP 權限請求。

映射關係：

- `allow_once` -> Hermes `once` (允許一次)
- `allow_always` -> Hermes `always` (永遠允許)
- reject options -> Hermes `deny` (拒絕)

超時和橋接失敗預設為拒絕。

### 工具渲染輔助程式 (Tool rendering helpers)

`acp_adapter/tools.py` 將 Hermes 工具映射到 ACP 工具類型，並建立面向編輯器的內容。

範例：

- `patch` / `write_file` -> 檔案差異 (file diffs)
- `terminal` -> 終端機指令文字
- `read_file` / `search_files` -> 文字預覽
- 大型結果 -> 為了 UI 安全而截斷的文字區塊

## 工作階段生命週期

```text
new_session(cwd)
  -> 建立 SessionState
  -> 建立 AIAgent(platform="acp", enabled_toolsets=["hermes-acp"])
  -> 將 task_id/session_id 綁定到工作目錄覆蓋 (cwd override)

prompt(..., session_id)
  -> 從 ACP 內容區塊中提取文字
  -> 重設取消事件
  -> 安裝回呼與審核橋接
  -> 在 ThreadPoolExecutor 中執行 AIAgent
  -> 更新工作階段歷史紀錄
  -> 發送最終代理訊息區段
```

### 取消 (Cancelation)

`cancel(session_id)`：

- 設定工作階段取消事件
- 在可用時呼叫 `agent.interrupt()`
- 導致提示詞回應回傳 `stop_reason="cancelled"`

### 分叉 (Forking)

`fork_session()` 將訊息歷史深度複製到一個新的活躍工作階段中，在保留對話狀態的同時，為分叉提供其專屬的工作階段 ID 和工作目錄。

## 提供者/驗證行為

ACP 不實作自己的驗證存儲。

相反地，它重複使用 Hermes 的執行期解析器：

- `acp_adapter/auth.py`
- `hermes_cli/runtime_provider.py`

因此，ACP 會宣告並使用當前配置的 Hermes 提供者/憑證。

## 工作目錄綁定

ACP 工作階段攜帶編輯器工作目錄 (cwd)。

工作階段管理員透過任務範圍內的終端機/檔案覆蓋，將該工作目錄綁定到 ACP 工作階段 ID，因此檔案和終端機工具會相對於編輯器工作區進行操作。

## 重複的同名工具呼叫

事件橋接器按工具名稱追蹤工具 ID (FIFO)，而不僅僅是每個名稱一個 ID。這對於以下情況很重要：

- 平行執行的同名呼叫
- 在一個步驟中重複執行的同名呼叫

如果沒有 FIFO 佇列，完成事件將會附加到錯誤的工具調用上。

## 審核回呼恢復

ACP 在提示詞執行期間會暫時在終端機工具上安裝審核回呼，然後在執行後恢復先前的回呼。這避免了永久地在全域安裝 ACP 工作階段專用的審核處理常式。

## 當前限制

- 從 ACP 伺服器的角度來看，ACP 工作階段是程序本地 (process-local) 的
- 非文字提示區塊目前在請求文字提取時會被忽略
- 編輯器專用的使用者體驗 (UX) 因 ACP 用戶端實作而異

## 相關檔案

- `tests/acp/` — ACP 測試套件
- `toolsets.py` — `hermes-acp` 工具集定義
- `hermes_cli/main.py` — `hermes acp` CLI 子指令
- `pyproject.toml` — `[acp]` 選用依賴 + `hermes-acp` 腳本
