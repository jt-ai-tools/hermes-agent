---
sidebar_position: 13
title: "委派與平行工作"
description: "何時以及如何使用子代理委派 —— 用於平行研究、程式碼審查和多檔案工作的模式"
---

# 委派與平行工作

Hermes 可以生成獨立的子代理 (Subagent) 來平行處理任務。每個子代理都有自己的對話、終端機對話階段 (Terminal Session) 和工具集。只有最終的總結會回傳 —— 中間的工具呼叫永遠不會進入你的上下文視窗 (Context Window)。

如需完整的功參考，請參閱 [子代理委派 (Subagent Delegation)](/docs/user-guide/features/delegation)。

---

## 何時進行委派

**適合委派的候選任務：**
- 重推理的子任務（除錯、程式碼審查、研究綜合）
- 會讓你的上下文充斥大量中間數據的任務
- 平行的獨立工作流（同時進行研究 A 和 B）
- 需要全新背景的任務，你希望代理在沒有偏見的情況下處理

**建議使用其他方式的情況：**
- 單個工具呼叫 → 直接使用該工具即可
- 步驟間帶有邏輯的機械化多步驟工作 → 使用 `execute_code`
- 需要使用者互動的任務 → 子代理無法使用 `clarify` (澄清)
- 快速的檔案編輯 → 直接進行編輯

---

## 模式：平行研究

同時研究三個主題並獲取結構化的總結：

```
平行研究這三個主題：
1. 瀏覽器之外的 WebAssembly 現狀
2. 2025 年 RISC-V 伺服器晶片的採用情況
3. 實用的量子計算應用

重點關注近期發展和主要參與者。
```

在幕後，Hermes 使用：

```python
delegate_task(tasks=[
    {
        "goal": "研究 2025 年瀏覽器之外的 WebAssembly",
        "context": "重點關注：執行環境 (Wasmtime, Wasmer)、雲端/邊緣使用案例、WASI 進展",
        "toolsets": ["web"]
    },
    {
        "goal": "研究 RISC-V 伺服器晶片的採用情況",
        "context": "重點關注：已出貨的伺服器晶片、雲端供應商的採用情況、軟體生態系統",
        "toolsets": ["web"]
    },
    {
        "goal": "研究實用的量子計算應用",
        "context": "重點關注：糾錯技術的突破、實際應用案例、關鍵公司",
        "toolsets": ["web"]
    }
])
```

這三個任務同時執行。每個子代理獨立搜尋網路並回傳總結。主代理隨後將它們綜合為一份連貫的簡報。

---

## 模式：程式碼審查 (Code Review)

將安全審查委派給一個具備全新背景的子代理，讓它在沒有預設框架的情況下審查程式碼：

```
審查 src/auth/ 的身分驗證模組是否存在安全性問題。
檢查 SQL 注入、JWT 驗證問題、密碼處理和對話管理 (Session Management)。
修復你發現的所有問題並執行測試。
```

關鍵在於 `context` 欄位 —— 它必須包含子代理所需的所有資訊：

```python
delegate_task(
    goal="審查 src/auth/ 的安全性問題並修復發現的所有問題",
    context="""專案路徑為 /home/user/webapp。使用 Python 3.11, Flask, PyJWT, bcrypt。
    身分驗證相關檔案：src/auth/login.py, src/auth/jwt.py, src/auth/middleware.py
    測試指令：pytest tests/auth/ -v
    重點關注：SQL 注入、JWT 驗證、密碼雜湊、對話管理。
    修復發現的問題並驗證測試是否通過。""",
    toolsets=["terminal", "file"]
)
```

:::warning 上下文問題
子代理對你的對話 **完全一無所知**。它們從完全乾淨的狀態開始。如果你委派「修復我們正在討論的錯誤」，子代理不知道你指的是哪個錯誤。請務必明確傳遞檔案路徑、錯誤訊息、專案結構和限制條件。
:::

---

## 模式：比較替代方案

平行評估解決同一問題的多種方法，然後選擇最佳方案：

```
我需要為我們的 Django 應用添加全文檢索功能。請平行評估三種方法：
1. PostgreSQL tsvector (內建)
2. 透過 django-elasticsearch-dsl 使用 Elasticsearch
3. 透過 meilisearch-python 使用 Meilisearch

針對每一項評估：設置複雜度、查詢能力、資源需求和維護開銷。比較它們並推薦一個方案。
```

每個子代理獨立研究一個選項。因為它們是隔離的，所以不會產生交叉干擾 —— 每個評估都基於自身的優點。主代理獲取這三個總結並進行比較。

---

## 模式：多檔案重構 (Multi-File Refactoring)

將大型重構任務拆分給多個平行的子代理，每個代理處理程式碼庫的不同部分：

```python
delegate_task(tasks=[
    {
        "goal": "重構所有 API 端點處理常式以使用新的回應格式",
        "context": """專案路徑為 /home/user/api-server。
        檔案：src/handlers/users.py, src/handlers/auth.py, src/handlers/billing.py
        舊格式：return {"data": result, "status": "ok"}
        新格式：return APIResponse(data=result, status=200).to_dict()
        匯入語句：from src.responses import APIResponse
        修改後執行測試：pytest tests/handlers/ -v""",
        "toolsets": ["terminal", "file"]
    },
    {
        "goal": "更新所有用戶端 SDK 方法以處理新的回應格式",
        "context": """專案路徑為 /home/user/api-server。
        檔案：sdk/python/client.py, sdk/python/models.py
        舊解析方式：result = response.json()["data"]
        新解析方式：result = response.json()["data"] (鍵名相同，但需增加狀態碼檢查)
        同時更新 sdk/python/tests/test_client.py""",
        "toolsets": ["terminal", "file"]
    },
    {
        "goal": "更新 API 文件以反映新的回應格式",
        "context": """專案路徑為 /home/user/api-server。
        文件路徑：docs/api/。格式：帶程式碼範例的 Markdown。
        將所有回應範例從舊格式更新為新格式。
        在 docs/api/overview.md 中添加「回應格式」章節來解釋架構。""",
        "toolsets": ["terminal", "file"]
    }
])
```

:::tip
每個子代理都有自己的終端機對話階段。只要它們編輯不同的檔案，就可以在同一個專案目錄中工作而不會互相干擾。如果兩個子代理可能觸及同一個檔案，請在平行工作完成後由你自己處理該檔案。
:::

---

## 模式：先收集再分析

使用 `execute_code` 進行機械性的數據收集，然後將重推理的分析工作委派出去：

```python
# 步驟 1：機械性收集（此處適合使用 execute_code —— 不需要推理）
execute_code("""
from hermes_tools import web_search, web_extract

results = []
for query in ["AI funding Q1 2026", "AI startup acquisitions 2026", "AI IPOs 2026"]:
    r = web_search(query, limit=5)
    for item in r["data"]["web"]:
        results.append({"title": item["title"], "url": item["url"], "desc": item["description"]})

# 從前 5 個最相關的結果中提取全文
urls = [r["url"] for r in results[:5]]
content = web_extract(urls)

# 儲存以供分析步驟使用
import json
with open("/tmp/ai-funding-data.json", "w") as f:
    json.dump({"search_results": results, "extracted": content["results"]}, f)
print(f"收集了 {len(results)} 個結果，提取了 {len(content['results'])} 個頁面")
""")

# 步驟 2：重推理的分析（此處適合使用委派）
delegate_task(
    goal="分析 AI 融資數據並編寫市場報告",
    context="""位於 /tmp/ai-funding-data.json 的原始數據包含關於 2026 年第一季 AI 融資、
    收購和 IPO 的搜尋結果和提取的網頁。
    撰寫一份結構化的市場報告：關鍵交易、趨勢、知名參與者和展望。
    重點關注超過 1 億美元的交易。""",
    toolsets=["terminal", "file"]
)
```

這通常是最有效的模式：`execute_code` 以較低的成本處理 10 個以上的連續工具呼叫，然後子代理在乾淨的背景下執行單個昂貴的推理任務。

---

## 工具集選擇

根據子代理的需求選擇工具集：

| 任務類型 | 工具集 | 原因 |
|-----------|----------|-----|
| 網路研究 | `["web"]` | 僅需 web_search + web_extract |
| 程式碼工作 | `["terminal", "file"]` | Shell 存取 + 檔案操作 |
| 全端工作 | `["terminal", "file", "web"]` | 除訊息傳遞外的所有工具 |
| 唯讀分析 | `["file"]` | 只能讀取檔案，無 Shell 權限 |

限制工具集可以讓子代理保持專注，並防止意外的副作用（例如研究子代理執行 Shell 指令）。

---

## 限制條件

- **預設為 3 個平行任務** — 批次處理預設為同時執行 3 個子代理（可透過 config.yaml 中的 `delegation.max_concurrent_children` 配置）
- **禁止巢狀委派** — 子代理無法呼叫 `delegate_task`、`clarify`、`memory`、`send_message` 或 `execute_code`
- **獨立的終端機** — 每個子代理都有自己的終端機對話階段，具備獨立的工作目錄和狀態
- **沒有對話歷史** — 子代理只能看到你在 `goal` 和 `context` 中提供的內容
- **預設為 50 次迭代** — 對於簡單任務，可將 `max_iterations` 設低一些以節省成本

---

## 小撇步

**目標要具體。** 「修復錯誤」太過模糊。「修復 api/handlers.py 第 47 行的 TypeError，其中 process_request() 從 parse_body() 接收到 None」能提供子代理足夠的資訊來開展工作。

**包含檔案路徑。** 子代理不知道你的專案結構。請務必包含相關檔案的絕對路徑、專案根目錄和測試指令。

**利用委派實現背景隔離。** 有時你想要一個全新的視角。委派迫使你清晰地闡述問題，子代理會在沒有對話累積假設的情況下處理問題。

**檢查結果。** 子代理的總結僅僅是總結。如果子代理說「已修復錯誤且測試通過」，請務必親自執行測試或閱讀差異 (diff) 來驗證。

---

*如需完整的委派參考 —— 包含所有參數、ACP 整合和進階配置 —— 請參閱 [子代理委派 (Subagent Delegation)](/docs/user-guide/features/delegation)。*
