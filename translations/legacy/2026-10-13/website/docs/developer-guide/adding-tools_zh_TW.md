---
sidebar_position: 2
title: "新增工具 (Adding Tools)"
description: "如何向 Hermes Agent 新增新工具——涵蓋結構描述 (Schema)、處理常式 (Handler)、註冊與工具集 (Toolsets)"
---

# 新增工具 (Adding Tools)

在編寫工具之前，請先問自己：**這是否應該是一個 [技能 (skill)](creating-skills.md)？**

當該能力可以透過指令 + 終端機指令 + 現有工具（如 arXiv 搜尋、Git 工作流、Docker 管理、PDF 處理）來表達時，請將其製作為 **技能 (Skill)**。

當它需要與 API 金鑰進行端到端整合、自定義處理邏輯、二進制數據處理或串流（如瀏覽器自動化、TTS、視覺分析）時，請將其製作為 **工具 (Tool)**。

## 概覽

新增工具涉及 **2 個檔案**：

1. **`tools/your_tool.py`** — 處理常式 (handler)、結構描述 (schema)、檢查函式、`registry.register()` 呼叫。
2. **`toolsets.py`** — 將工具名稱新增到 `_HERMES_CORE_TOOLS`（或特定工具集）。

任何在頂層呼叫 `registry.register()` 的 `tools/*.py` 檔案都會在啟動時被自動探索——不需要手動維護匯入列表。

## 步驟 1：建立工具檔案

每個工具檔案都遵循相同的結構：

```python
# tools/weather_tool.py
"""天氣工具 -- 查詢指定地點的當前天氣。"""

import json
import os
import logging

logger = logging.getLogger(__name__)


# --- 可用性檢查 ---

def check_weather_requirements() -> bool:
    """若工具的依賴項目可用則回傳 True。"""
    return bool(os.getenv("WEATHER_API_KEY"))


# --- 處理常式 (Handler) ---

def weather_tool(location: str, units: str = "metric") -> str:
    """獲取指定地點的天氣。回傳 JSON 字串。"""
    api_key = os.getenv("WEATHER_API_KEY")
    if not api_key:
        return json.dumps({"error": "尚未配置 WEATHER_API_KEY"})
    try:
        # ... 呼叫天氣 API ...
        return json.dumps({"location": location, "temp": 22, "units": units})
    except Exception as e:
        return json.dumps({"error": str(e)})


# --- 結構描述 (Schema) ---

WEATHER_SCHEMA = {
    "name": "weather",
    "description": "獲取指定地點的當前天氣。",
    "parameters": {
        "type": "object",
        "properties": {
            "location": {
                "type": "string",
                "description": "城市名稱或座標（例如 'London' 或 '51.5,-0.1'）"
            },
            "units": {
                "type": "string",
                "enum": ["metric", "imperial"],
                "description": "溫度單位（預設：metric）",
                "default": "metric"
            }
        },
        "required": ["location"]
    }
}


# --- 註冊 ---

from tools.registry import registry

registry.register(
    name="weather",
    toolset="weather",
    schema=WEATHER_SCHEMA,
    handler=lambda args, **kw: weather_tool(
        location=args.get("location", ""),
        units=args.get("units", "metric")),
    check_fn=check_weather_requirements,
    requires_env=["WEATHER_API_KEY"],
)
```

### 關鍵規則

:::danger 重要
- 處理常式 **必須** 回傳 JSON 字串（透過 `json.dumps()`），絕對不能回傳原始字典 (raw dicts)。
- 錯誤 **必須** 以 `{"error": "訊息內容"}` 的形式回傳，絕對不能作為異常 (exception) 拋出。
- `check_fn` 在建構工具定義時被呼叫——如果它回傳 `False`，該工具將被靜默排除。
- `handler` 接收 `(args: dict, **kwargs)`，其中 `args` 是 LLM 的工具呼叫參數。
:::

## 步驟 2：新增到工具集 (Toolset)

在 `toolsets.py` 中新增工具名稱：

```python
# 如果它應該在所有平台（CLI + 通訊平台）上都可用：
_HERMES_CORE_TOOLS = [
    ...
    "weather",  # <-- 在此處新增
]

# 或者建立一個新的獨立工具集：
"weather": {
    "description": "天氣查詢工具",
    "tools": ["weather"],
    "includes": []
},
```

## ~~步驟 3：新增探索匯入~~（不再需要）

在頂層呼叫 `registry.register()` 的工具模組會被 `tools/registry.py` 中的 `discover_builtin_tools()` 自動探索。不需要手動維護匯入列表——只需在 `tools/` 中建立檔案，它就會在啟動時被載入。

## 非同步處理常式 (Async Handlers)

如果您的處理常式需要執行非同步程式碼，請將其標記為 `is_async=True`：

```python
async def weather_tool_async(location: str) -> str:
    async with aiohttp.ClientSession() as session:
        ...
    return json.dumps(result)

registry.register(
    name="weather",
    toolset="weather",
    schema=WEATHER_SCHEMA,
    handler=lambda args, **kw: weather_tool_async(args.get("location", "")),
    check_fn=check_weather_requirements,
    is_async=True,  # registry 會自動呼叫 _run_async()
)
```

註冊表會透明地處理非同步橋接——您永遠不需要自己呼叫 `asyncio.run()`。

## 需要 task_id 的處理常式

管理每個工作階段狀態的工具會透過 `**kwargs` 接收 `task_id`：

```python
def _handle_weather(args, **kw):
    task_id = kw.get("task_id")
    return weather_tool(args.get("location", ""), task_id=task_id)

registry.register(
    name="weather",
    ...
    handler=_handle_weather,
)
```

## 代理迴圈攔截工具 (Agent-Loop Intercepted Tools)

某些工具（如 `todo`、`memory`、`session_search`、`delegate_task`）需要訪問每個工作階段的代理狀態。這些工具在到達註冊表之前會被 `run_agent.py` 攔截。註冊表仍然持有它們的結構描述，但如果繞過了攔截，`dispatch()` 將回傳備援錯誤。

## 選用：設定精靈整合

如果您的工具需要 API 金鑰，請將其新增到 `hermes_cli/config.py`：

```python
OPTIONAL_ENV_VARS = {
    ...
    "WEATHER_API_KEY": {
        "description": "用於天氣查詢的天氣 API 金鑰",
        "prompt": "天氣 API 金鑰",
        "url": "https://weatherapi.com/",
        "tools": ["weather"],
        "password": True,
    },
}
```

## 檢核清單

- [ ] 已建立包含處理常式、結構描述、檢查函式和註冊資訊的工具檔案。
- [ ] 已在 `toolsets.py` 中新增到適當的工具集。
- [ ] 已在 `model_tools.py` 中新增探索匯入。
- [ ] 處理常式回傳 JSON 字串，錯誤以 `{"error": "..."}` 形式回傳。
- [ ] 選用：已在 `hermes_cli/config.py` 的 `OPTIONAL_ENV_VARS` 中新增 API 金鑰。
- [ ] 選用：已為批次處理在 `toolset_distributions.py` 中新增。
- [ ] 已使用 `hermes chat -q "對倫敦使用天氣工具"` 進行測試。
