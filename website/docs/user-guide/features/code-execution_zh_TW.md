---
sidebar_position: 8
title: "程式碼執行"
description: "沙盒化的 Python 執行並透過 RPC 存取工具 —— 將多步驟工作流壓縮至單一輪次"
---

# 程式碼執行 (程式化工具呼叫)

`execute_code` 工具讓代理程式能編寫 Python 腳本，以程式化的方式呼叫 Hermes 工具，從而將多步驟工作流壓縮至單一 LLM 輪次。該腳本在代理程式主機的沙盒化子程序中執行，透過 Unix 域通訊端 (Domain Socket) RPC 進行通訊。

## 運作方式

1. 代理程式使用 `from hermes_tools import ...` 編寫 Python 腳本。
2. Hermes 生成一個帶有 RPC 函數的 `hermes_tools.py` 存根 (Stub) 模組。
3. Hermes 開啟一個 Unix 域通訊端並啟動一個 RPC 監聽執行緒。
4. 腳本在子程序中執行 —— 工具呼叫透過通訊端傳回 Hermes。
5. 僅腳本的 `print()` 輸出會返回給 LLM；中間工具的執行結果永遠不會進入上下文視窗 (Context Window)。

```python
# 代理程式可以編寫如下腳本：
from hermes_tools import web_search, web_extract

results = web_search("Python 3.13 features", limit=5)
for r in results["data"]["web"]:
    content = web_extract([r["url"]])
    # ... 過濾與處理 ...
print(summary)
```

**沙盒中可用的工具**：`web_search`、`web_extract`、`read_file`、`write_file`、`search_files`、`patch`、`terminal`（僅限前景執行）。

## 代理程式何時使用此功能

當發生以下情況時，代理程式會使用 `execute_code`：

- 需要進行 **3 次以上** 且中間帶有處理邏輯的工具呼叫。
- 進行大量資料過濾或條件分支。
- 對結果進行迴圈處理。

核心優勢：中間工具的執行結果永遠不會進入上下文視窗 —— 僅返回最終的 `print()` 輸出，大幅減少 Token 使用量。

## 實務範例

### 資料處理管線

```python
from hermes_tools import search_files, read_file
import json

# 尋找所有配置檔案並提取資料庫設定
matches = search_files("database", path=".", file_glob="*.yaml", limit=20)
configs = []
for match in matches.get("matches", []):
    content = read_file(match["path"])
    configs.append({"file": match["path"], "preview": content["content"][:200]})

print(json.dumps(configs, indent=2))
```

### 多步驟網頁研究

```python
from hermes_tools import web_search, web_extract
import json

# 在一輪內完成搜尋、提取與摘要
results = web_search("Rust async runtime comparison 2025", limit=5)
summaries = []
for r in results["data"]["web"]:
    page = web_extract([r["url"]])
    for p in page.get("results", []):
        if p.get("content"):
            summaries.append({
                "title": r["title"],
                "url": r["url"],
                "excerpt": p["content"][:500]
            })

print(json.dumps(summaries, indent=2))
```

### 大量檔案重構

```python
from hermes_tools import search_files, read_file, patch

# 尋找所有使用過時 API 的 Python 檔案並修復它們
matches = search_files("old_api_call", path="src/", file_glob="*.py")
fixed = 0
for match in matches.get("matches", []):
    result = patch(
        path=match["path"],
        old_string="old_api_call(",
        new_string="new_api_call(",
        replace_all=True
    )
    if "error" not in str(result):
        fixed += 1

print(f"在 {len(matches.get('matches', []))} 個匹配項中修復了 {fixed} 個檔案")
```

### 建構與測試管線

```python
from hermes_tools import terminal, read_file
import json

# 執行測試、解析結果並回報
result = terminal("cd /project && python -m pytest --tb=short -q 2>&1", timeout=120)
output = result.get("output", "")

# 解析測試輸出
passed = output.count(" passed")
failed = output.count(" failed")
errors = output.count(" error")

report = {
    "passed": passed,
    "failed": failed,
    "errors": errors,
    "exit_code": result.get("exit_code", -1),
    "summary": output[-500:] if len(output) > 500 else output
}

print(json.dumps(report, indent=2))
```

## 資源限制

| 資源 | 限制 | 備註 |
|----------|-------|-------|
| **逾時** | 5 分鐘 (300秒) | 腳本會先被發送 SIGTERM，5 秒寬限期後發送 SIGKILL |
| **Stdout** | 50 KB | 超出部分將截斷並提示 `[output truncated at 50KB]` |
| **Stderr** | 10 KB | 在非零結束碼時包含在輸出中以供除錯 |
| **工具呼叫** | 每次執行 50 次 | 達到限制時返回錯誤 |

所有限制均可透過 `config.yaml` 進行配置：

```yaml
# 在 ~/.hermes/config.yaml 中
code_execution:
  timeout: 300       # 每個腳本的最大秒數 (預設：300)
  max_tool_calls: 50 # 每次執行的最大工具呼叫次數 (預設：50)
```

## 腳本內的工具呼叫運作方式

當您的腳本呼叫如 `web_search("query")` 的函數時：

1. 呼叫被序列化為 JSON，並透過 Unix 域通訊端發送到父程序。
2. 父程序透過標準的 `handle_function_call` 處理程式進行發送。
3. 結果透過通訊端傳回。
4. 函數返回解析後的結果。

這意味著腳本內的工具呼叫與一般工具呼叫的行為完全一致 —— 相同的速率限制、相同的錯誤處理、相同的功能。唯一的限制是 `terminal()` 僅限前景執行（不支援 `background` 或 `pty` 參數）。

## 錯誤處理

當腳本執行失敗時，代理程式會收到結構化的錯誤資訊：

- **非零結束碼**：stderr 會包含在輸出中，以便代理程式看到完整的回溯 (Traceback)。
- **逾時**：腳本被強制終止，代理程式會看到 `"Script timed out after 300s and was killed."`。
- **中斷**：如果使用者在執行期間發送新訊息，腳本會終止，代理程式會看到 `[execution interrupted — user sent a new message]`。
- **工具呼叫限制**：當達到 50 次呼叫限制時，後續的工具呼叫將返回錯誤訊息。

回應內容始終包含 `status`（成功/錯誤/逾時/中斷）、`output`、`tool_calls_made` 以及 `duration_seconds`。

## 安全性

:::danger 安全模型
子程序在 **極簡環境** 下執行。API 金鑰、權杖 (Tokens) 和憑據預設會被移除。腳本僅能透過 RPC 通道存取工具 —— 除非明確允許，否則它無法從環境變數中讀取金鑰。
:::

環境變數名稱中包含 `KEY`、`TOKEN`、`SECRET`、`PASSWORD`、`CREDENTIAL`、`PASSWD` 或 `AUTH` 的變數都會被排除。僅傳遞安全的系統變數（如 `PATH`、`HOME`、`LANG`、`SHELL`、`PYTHONPATH`、`VIRTUAL_ENV` 等）。

### 技能環境變數透傳 (Passthrough)

當技能在 frontmatter 中宣告 `required_environment_variables` 時，這些變數在技能載入後會 **自動透傳** 到 `execute_code` 和 `terminal` 沙盒中。這讓技能可以使用其宣告的 API 金鑰，而不會降低任意程式碼執行的安全性。

對於非技能的使用案例，您可以在 `config.yaml` 中明確設定允許清單：

```yaml
terminal:
  env_passthrough:
    - MY_CUSTOM_KEY
    - ANOTHER_TOKEN
```

詳情請參閱 [安全性指南](/docs/user-guide/security#environment-variable-passthrough)。

腳本在臨時目錄中執行，執行完畢後會被清理。子程序在其獨立的程序組中執行，以便在逾時或中斷時能被乾淨地終止。

## execute_code vs terminal

| 使用案例 | execute_code | terminal |
|----------|-------------|----------|
| 帶有工具呼叫的多步驟工作流 | ✅ | ❌ |
| 簡單的 Shell 指令 | ❌ | ✅ |
| 過濾/處理大量的工具輸出 | ✅ | ❌ |
| 執行建構或測試套件 | ❌ | ✅ |
| 對搜尋結果進行迴圈處理 | ✅ | ❌ |
| 互動式/背景程序 | ❌ | ✅ |
| 需要環境變數中的 API 金鑰 | ⚠️ 僅透過 [透傳](/docs/user-guide/security#environment-variable-passthrough) | ✅ (大多數會透傳) |

**經驗法則**：當您需要程式化地呼叫具備中間邏輯的 Hermes 工具時，請使用 `execute_code`。當執行 Shell 指令、建構程序和一般程序時，請使用 `terminal`。

## 平台支援

程式碼執行需要 Unix 域通訊端，因此僅支援 **Linux 和 macOS**。該功能在 Windows 上會自動停用 —— 代理程式將退而使用一般的一連串工具呼叫。
