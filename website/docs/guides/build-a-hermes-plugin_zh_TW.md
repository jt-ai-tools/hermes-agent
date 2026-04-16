---
sidebar_position: 9
sidebar_label: "建立外掛程式"
title: "建立 Hermes 外掛程式"
description: "建立包含工具、掛鉤 (Hooks)、資料檔案和技能的完整 Hermes 外掛程式分步指南"
---

# 建立 Hermes 外掛程式

本指南將帶領您從頭開始建立一個完整的 Hermes 外掛程式。最後，您將擁有一個包含多個工具、生命週期掛鉤、隨附資料檔案以及綑綁技能的實用外掛程式 — 涵蓋外掛系統支援的所有功能。

## 您將建立的內容

一個具有兩個工具的**計算機**外掛程式：
- `calculate` — 計算數學表達式（例如 `2**16`, `sqrt(144)`, `pi * 5**2`）
- `unit_convert` — 進行單位換算（例如 `100 F → 37.78 C`, `5 km → 3.11 mi`）

此外還包含一個紀錄每次工具調用的掛鉤，以及一個綑綁的技能檔案。

## 步驟 1：建立外掛程式目錄

```bash
mkdir -p ~/.hermes/plugins/calculator
cd ~/.hermes/plugins/calculator
```

## 步驟 2：撰寫資訊清單 (Manifest)

建立 `plugin.yaml`：

```yaml
name: calculator
version: 1.0.0
description: 數學計算機 — 計算表達式並進行單位換算
provides_tools:
  - calculate
  - unit_convert
provides_hooks:
  - post_tool_call
```

這告訴 Hermes：「我是一個名為 calculator 的外掛程式，我提供工具和掛鉤。」`provides_tools` 和 `provides_hooks` 欄位列出了該外掛程式註冊的內容。

您可以新增的可選欄位：
```yaml
author: 您的姓名
requires_env:          # 根據環境變數限制載入；在安裝時會提示
  - SOME_API_KEY       # 簡單格式 — 如果缺失則停用外掛
  - name: OTHER_KEY    # 豐富格式 — 安裝時顯示說明/URL
    description: "Other 服務的金鑰"
    url: "https://other.com/keys"
    secret: true
```

## 步驟 3：撰寫工具架構 (Schemas)

建立 `schemas.py` — 這是 LLM 用來決定何時調用工具的參考依據：

```python
"""工具架構 — LLM 看到的內容。"""

CALCULATE = {
    "name": "calculate",
    "description": (
        "計算數學表達式並回傳結果。"
        "支援算術運算 (+, -, *, /, **)、函數 (sqrt, sin, cos, "
        "log, abs, round, floor, ceil) 以及常數 (pi, e)。"
        "用於處理使用者詢問的任何數學運算。"
    ),
    "parameters": {
        "type": "object",
        "properties": {
            "expression": {
                "type": "string",
                "description": "要計算的數學表達式（例如：'2**10', 'sqrt(144)'）",
            },
        },
        "required": ["expression"],
    },
}

UNIT_CONVERT = {
    "name": "unit_convert",
    "description": (
        "在不同單位之間轉換數值。支援長度 (m, km, mi, ft, in)、"
        "重量 (kg, lb, oz, g)、溫度 (C, F, K)、資料 (B, KB, MB, GB, TB) "
        "以及時間 (s, min, hr, day)。"
    ),
    "parameters": {
        "type": "object",
        "properties": {
            "value": {
                "type": "number",
                "description": "要轉換的數值",
            },
            "from_unit": {
                "type": "string",
                "description": "來源單位（例如：'km', 'lb', 'F', 'GB'）",
            },
            "to_unit": {
                "type": "string",
                "description": "目標單位（例如：'mi', 'kg', 'C', 'MB'）",
            },
        },
        "required": ["value", "from_unit", "to_unit"],
    },
}
```

**為什麼架構很重要：** `description` 欄位是 LLM 決定何時使用工具的依據。請具體描述工具的功能和使用時機。`parameters` 則定義了 LLM 傳遞的參數。

## 步驟 4：撰寫工具處理器 (Handlers)

建立 `tools.py` — 這是 LLM 調用工具時實際執行的程式碼：

```python
"""工具處理器 — LLM 調用工具時執行的程式碼。"""

import json
import math

# 用於表達式計算的安全全域變數 — 禁止存取檔案/網路
_SAFE_MATH = {
    "abs": abs, "round": round, "min": min, "max": max,
    "pow": pow, "sqrt": math.sqrt, "sin": math.sin, "cos": math.cos,
    "tan": math.tan, "log": math.log, "log2": math.log2, "log10": math.log10,
    "floor": math.floor, "ceil": math.ceil,
    "pi": math.pi, "e": math.e,
    "factorial": math.factorial,
}


def calculate(args: dict, **kwargs) -> str:
    """安全地計算數學表達式。

    處理器規則：
    1. 接收 args (dict) — LLM 傳遞的參數
    2. 執行任務
    3. 回傳 JSON 字串 — 務必遵守，即使出錯也是
    4. 接受 **kwargs 以確保向前相容性
    """
    expression = args.get("expression", "").strip()
    if not expression:
        return json.dumps({"error": "未提供表達式"})

    try:
        result = eval(expression, {"__builtins__": {}}, _SAFE_MATH)
        return json.dumps({"expression": expression, "result": result})
    except ZeroDivisionError:
        return json.dumps({"expression": expression, "error": "除以零"})
    except Exception as e:
        return json.dumps({"expression": expression, "error": f"無效：{e}"})


# 換算表 — 數值皆以基本單位表示
_LENGTH = {"m": 1, "km": 1000, "mi": 1609.34, "ft": 0.3048, "in": 0.0254, "cm": 0.01}
_WEIGHT = {"kg": 1, "g": 0.001, "lb": 0.453592, "oz": 0.0283495}
_DATA = {"B": 1, "KB": 1024, "MB": 1024**2, "GB": 1024**3, "TB": 1024**4}
_TIME = {"s": 1, "ms": 0.001, "min": 60, "hr": 3600, "day": 86400}


def _convert_temp(value, from_u, to_u):
    # 標準化為攝氏 (Celsius)
    c = {"F": (value - 32) * 5/9, "K": value - 273.15}.get(from_u, value)
    # 轉換為目標單位
    return {"F": c * 9/5 + 32, "K": c + 273.15}.get(to_u, c)


def unit_convert(args: dict, **kwargs) -> str:
    """單位換算。"""
    value = args.get("value")
    from_unit = args.get("from_unit", "").strip()
    to_unit = args.get("to_unit", "").strip()

    if value is None or not from_unit or not to_unit:
        return json.dumps({"error": "需要數值、來源單位和目標單位"})

    try:
        # 溫度換算
        if from_unit.upper() in {"C","F","K"} and to_unit.upper() in {"C","F","K"}:
            result = _convert_temp(float(value), from_unit.upper(), to_unit.upper())
            return json.dumps({"input": f"{value} {from_unit}", "result": round(result, 4),
                             "output": f"{round(result, 4)} {to_unit}"})

        # 基於比例的換算
        for table in (_LENGTH, _WEIGHT, _DATA, _TIME):
            lc = {k.lower(): v for k, v in table.items()}
            if from_unit.lower() in lc and to_unit.lower() in lc:
                result = float(value) * lc[from_unit.lower()] / lc[to_unit.lower()]
                return json.dumps({"input": f"{value} {from_unit}",
                                 "result": round(result, 6),
                                 "output": f"{round(result, 6)} {to_unit}"})

        return json.dumps({"error": f"無法轉換 {from_unit} → {to_unit}"})
    except Exception as e:
        return json.dumps({"error": f"轉換失敗：{e}"})
```

**處理器關鍵規則：**
1. **簽章：** `def my_handler(args: dict, **kwargs) -> str`
2. **回傳：** 務必回傳 JSON 字串。成功和錯誤皆然。
3. **嚴禁 raise：** 捕捉所有異常，改為回傳錯誤 JSON。
4. **接受 `**kwargs`：** Hermes 未來可能會傳遞額外的上下文。

## 步驟 5：撰寫註冊邏輯

建立 `__init__.py` — 這將架構與處理器連結起來：

```python
"""計算機外掛程式 — 註冊。"""

import logging

from . import schemas, tools

logger = logging.getLogger(__name__)

# 透過掛鉤追蹤工具使用情況
_call_log = []

def _on_post_tool_call(tool_name, args, result, task_id, **kwargs):
    """掛鉤：在每次工具調用後運行（不限於我們自己的工具）。"""
    _call_log.append({"tool": tool_name, "session": task_id})
    if len(_call_log) > 100:
        _call_log.pop(0)
    logger.debug("工具調用：%s (對話 %s)", tool_name, task_id)


def register(ctx):
    """將架構連結至處理器並註冊掛鉤。"""
    ctx.register_tool(name="calculate",    toolset="calculator",
                      schema=schemas.CALCULATE,    handler=tools.calculate)
    ctx.register_tool(name="unit_convert", toolset="calculator",
                      schema=schemas.UNIT_CONVERT, handler=tools.unit_convert)

    # 此掛鉤針對所有工具調用觸發，而不僅限於我們的工具
    ctx.register_hook("post_tool_call", _on_post_tool_call)
```

**`register()` 的功能：**
- 在啟動時僅調用一次
- `ctx.register_tool()` 將您的工具放入註冊表中 — 模型會立即看到它
- `ctx.register_hook()` 訂閱生命週期事件
- `ctx.register_cli_command()` 註冊 CLI 子指令（例如 `hermes my-plugin <subcommand>`）
- 如果此函數崩潰，該外掛程式會被停用，但 Hermes 會繼續正常運行

## 步驟 6：進行測試

啟動 Hermes：

```bash
hermes
```

您應該會在橫幅的工具列表中看到 `calculator: calculate, unit_convert`。

嘗試以下提示詞：
```
2 的 16 次方是多少？
將 100 華氏度轉換為攝氏度
2 乘以 pi 的平方根是多少？
1.5 terabytes 是多少 gigabytes？
```

檢查外掛程式狀態：
```
/plugins
```

輸出：
```
Plugins (1):
  ✓ calculator v1.0.0 (2 tools, 1 hooks)
```

## 外掛程式的最終結構

```
~/.hermes/plugins/calculator/
├── plugin.yaml      # 「我是 calculator，我提供工具和掛鉤」
├── __init__.py      # 連結：架構 → 處理器，註冊掛鉤
├── schemas.py       # LLM 讀取的內容（說明 + 參數規格）
└── tools.py         # 執行的程式碼（calculate, unit_convert 函數）
```

四個檔案，職責分離：
- **資訊清單** 宣告外掛程式身分
- **架構** 為 LLM 描述工具
- **處理器** 實作實際邏輯
- **註冊** 連結所有組件

## 外掛程式還能做什麼？

### 隨附資料檔案

您可以將任何檔案放在外掛程式目錄中，並在匯入時讀取：

```python
# 在 tools.py 或 __init__.py 中
from pathlib import Path

_PLUGIN_DIR = Path(__file__).parent
_DATA_FILE = _PLUGIN_DIR / "data" / "languages.yaml"

with open(_DATA_FILE) as f:
    _DATA = yaml.safe_load(f)
```

### 綑綁技能

外掛程式可以隨附技能檔案，代理程式透過 `skill_view("plugin:skill")` 載入。在您的 `__init__.py` 中註冊它們：

```
~/.hermes/plugins/my-plugin/
├── __init__.py
├── plugin.yaml
└── skills/
    ├── my-workflow/
    │   └── SKILL.md
    └── my-checklist/
        └── SKILL.md
```

```python
from pathlib import Path

def register(ctx):
    skills_dir = Path(__file__).parent / "skills"
    for child in sorted(skills_dir.iterdir()):
        skill_md = child / "SKILL.md"
        if child.is_dir() and skill_md.exists():
            ctx.register_skill(child.name, skill_md)
```

代理程式現在可以使用其命名空間名稱載入您的技能：

```python
skill_view("my-plugin:my-workflow")   # → 外掛程式版本
skill_view("my-workflow")              # → 內建版本（不受影響）
```

**關鍵特性：**
- 外掛程式技能是**唯讀的** — 它們不會進入 `~/.hermes/skills/`，也無法透過 `skill_manage` 編輯。
- 外掛程式技能**不會**列在系統提示詞的 `<available_skills>` 索引中 — 它們需要明確載入。
- 裸技能名稱不受影響 — 命名空間可防止與內建技能發生衝突。
- 當代理程式載入外掛程式技能時，會預置一個綑綁上下文橫幅，列出同一外掛程式中的其他技能。

:::tip 舊有模式
舊有的 `shutil.copy2` 模式（將技能複製到 `~/.hermes/skills/`）仍然有效，但會增加與內建技能名稱衝突的風險。對於新的外掛程式，請優先使用 `ctx.register_skill()`。
:::

### 環境變數限制

如果您的外掛程式需要 API 金鑰：

```yaml
# plugin.yaml — 簡單格式（向下相容）
requires_env:
  - WEATHER_API_KEY
```

如果未設定 `WEATHER_API_KEY`，外掛程式將被停用並顯示明確訊息。不會崩潰，代理程式也不會報錯 — 僅顯示「外掛程式 weather 已停用（缺失：WEATHER_API_KEY）」。

當使用者執行 `hermes plugins install` 時，系統會**以互動方式提示**輸入任何缺失的 `requires_env` 變數。數值會自動儲存到 `.env` 中。

為了獲得更好的安裝體驗，請使用包含說明和註冊 URL 的豐富格式：

```yaml
# plugin.yaml — 豐富格式
requires_env:
  - name: WEATHER_API_KEY
    description: "OpenWeather 的 API 金鑰"
    url: "https://openweathermap.org/api"
    secret: true
```

| 欄位 | 必填 | 說明 |
|-------|----------|-------------|
| `name` | 是 | 環境變數名稱 |
| `description` | 否 | 在安裝提示時顯示給使用者 |
| `url` | 否 | 前往何處獲取憑證 |
| `secret` | 否 | 若為 `true`，輸入內容會隱藏（如密碼欄位） |

兩種格式可以在同一個清單中混用。已設定的變數會被靜默跳過。

### 有條件的工具可用性

對於依賴選用函式庫的工具：

```python
ctx.register_tool(
    name="my_tool",
    schema={...},
    handler=my_handler,
    check_fn=lambda: _has_optional_lib(),  # False = 對模型隱藏工具
)
```

### 註冊多個掛鉤

```python
def register(ctx):
    ctx.register_hook("pre_tool_call", before_any_tool)
    ctx.register_hook("post_tool_call", after_any_tool)
    ctx.register_hook("pre_llm_call", inject_memory)
    ctx.register_hook("on_session_start", on_new_session)
    ctx.register_hook("on_session_end", on_session_end)
```

### 掛鉤參考

每個掛鉤在 **[事件掛鉤參考](/docs/user-guide/features/hooks#plugin-hooks)** 中都有完整記錄 — 包含回呼簽章、參數表、觸發時機以及範例。以下是摘要：

| 掛鉤 | 觸發時機 | 回呼簽章 | 回傳值 |
|------|-----------|-------------------|---------|
| [`pre_tool_call`](/docs/user-guide/features/hooks#pre_tool_call) | 工具執行前 | `tool_name: str, args: dict, task_id: str` | 忽略 |
| [`post_tool_call`](/docs/user-guide/features/hooks#post_tool_call) | 工具回傳後 | `tool_name: str, args: dict, result: str, task_id: str` | 忽略 |
| [`pre_llm_call`](/docs/user-guide/features/hooks#pre_llm_call) | 每輪一次，在工具調用迴圈前 | `session_id: str, user_message: str, conversation_history: list, is_first_turn: bool, model: str, platform: str` | [上下文注入](#pre_llm_call-上下文注入) |
| [`post_llm_call`](/docs/user-guide/features/hooks#post_llm_call) | 每輪一次，在工具調用迴圈後（僅限成功的輪次） | `session_id: str, user_message: str, assistant_response: str, conversation_history: list, model: str, platform: str` | 忽略 |
| [`on_session_start`](/docs/user-guide/features/hooks#on_session_start) | 建立新對話（僅限第一輪） | `session_id: str, model: str, platform: str` | 忽略 |
| [`on_session_end`](/docs/user-guide/features/hooks#on_session_end) | 每次 `run_conversation` 調用結束 + CLI 退出時 | `session_id: str, completed: bool, interrupted: bool, model: str, platform: str` | 忽略 |
| [`pre_api_request`](/docs/user-guide/features/hooks#pre_api_request) | 在向 LLM 供應商發送每次 HTTP 請求前 | `method: str, url: str, headers: dict, body: dict` | 忽略 |
| [`post_api_request`](/docs/user-guide/features/hooks#post_api_request) | 在收到來自 LLM 供應商的每次 HTTP 回應後 | `method: str, url: str, status_code: int, response: dict` | 忽略 |

大多數掛鉤都是「觸發後即忘」的觀察者 — 它們的回傳值會被忽略。例外是 `pre_llm_call`，它可以向對話注入上下文。

所有回呼應接受 `**kwargs` 以確保向前相容性。如果掛鉤回呼崩潰，系統會記錄並跳過它。其他掛鉤和代理程式將正常繼續。

### `pre_llm_call` 上下文注入

這是唯一回傳值具有實際影響的掛鉤。當 `pre_llm_call` 回呼回傳一個包含 `"context"` 鍵的字典（或純字串）時，Hermes 會將該文本注入到**當前輪次的使用者訊息**中。這是記憶體外掛程式、RAG 整合、護欄以及任何需要向模型提供額外上下文的外掛程式採用的機制。

#### 回傳格式

```python
# 包含 context 鍵的字典
return {"context": "檢索到的記憶：\n- 使用者偏好深色模式\n- 上個專案：hermes-agent"}

# 純字串（相當於上述字典形式）
return "檢索到的記憶：\n- 使用者偏好深色模式"

# 回傳 None 或不回傳 → 不注入（僅觀察）
return None
```

任何非 None、非空的包含 `"context"` 鍵的結果（或純非空字串）都會被收集並附加到當前輪次的使用者訊息中。

#### 注入如何運作

注入的上下文會附加到**使用者訊息**，而非系統提示詞。這是一個刻意的設計選擇：

- **維護提示詞快取 (Prompt Cache)** — 系統提示詞在各輪之間保持完全相同。Anthropic 和 OpenRouter 會快取系統提示詞前綴，因此保持其穩定可在多輪對話中節省 75% 以上的輸入 token。如果外掛程式修改了系統提示詞，每一輪都會發生快取失效。
- **瞬時性** — 注入僅在 API 調用時發生。對話歷史中原始的使用者訊息絕不會被更動，也不會持久化到對話資料庫中。
- **系統提示詞是 Hermes 的領域** — 它包含模型特定的引導、工具執行規則、人格指令和快取的技能內容。外掛程式隨使用者輸入貢獻上下文，而非更改代理程式的核心指令。

#### 範例：記憶檢索外掛程式

```python
"""記憶外掛程式 — 從向量資料庫檢索相關上下文。"""

import httpx

MEMORY_API = "https://your-memory-api.example.com"

def recall_context(session_id, user_message, is_first_turn, **kwargs):
    """在每輪 LLM 調用前被觸發。回傳檢索到的記憶。"""
    try:
        resp = httpx.post(f"{MEMORY_API}/recall", json={
            "session_id": session_id,
            "query": user_message,
        }, timeout=3)
        memories = resp.json().get("results", [])
        if not memories:
            return None  # 無需注入

        text = "從先前對話檢索到的上下文：\n"
        text += "\n".join(f"- {m['text']}" for m in memories)
        return {"context": text}
    except Exception:
        return None  # 靜默失敗，不要中斷代理程式

def register(ctx):
    ctx.register_hook("pre_llm_call", recall_context)
```

#### 範例：護欄外掛程式

```python
"""護欄外掛程式 — 執行內容政策。"""

POLICY = """您在此對話中務必遵守以下內容政策：
- 絕不產生存取工作目錄以外檔案系統的程式碼
- 在執行破壞性操作前務必發出警告
- 拒絕涉及個人資料提取的請求"""

def inject_guardrails(**kwargs):
    """將政策文本注入每一輪對話。"""
    return {"context": POLICY}

def register(ctx):
    ctx.register_hook("pre_llm_call", inject_guardrails)
```

#### 範例：僅限觀察的掛鉤（無注入）

```python
"""分析外掛程式 — 在不注入上下文的情況下追蹤輪次元數據。"""

import logging
logger = logging.getLogger(__name__)

def log_turn(session_id, user_message, model, is_first_turn, **kwargs):
    """在每次 LLM 調用前觸發。回傳 None — 不注入上下文。"""
    logger.info("輪次：session=%s model=%s first=%s msg_len=%d",
                session_id, model, is_first_turn, len(user_message or ""))
    # 無回傳 → 無注入

def register(ctx):
    ctx.register_hook("pre_llm_call", log_turn)
```

#### 多個外掛程式回傳上下文

當多個外掛程式從 `pre_llm_call` 回傳上下文時，它們的輸出會以兩個換行符號連接，並一起附加到使用者訊息。順序遵循外掛程式探索順序（依外掛程式目錄名稱字母順序）。

### 註冊 CLI 指令

外掛程式可以新增自己的 `hermes <plugin>` 子指令樹：

```python
def _my_command(args):
    """hermes my-plugin <subcommand> 的處理器。"""
    sub = getattr(args, "my_command", None)
    if sub == "status":
        print("一切正常！")
    elif sub == "config":
        print("目前設定：...")
    else:
        print("用法：hermes my-plugin <status|config>")

def _setup_argparse(subparser):
    """為 hermes my-plugin 建立 argparse 樹。"""
    subs = subparser.add_subparsers(dest="my_command")
    subs.add_parser("status", help="顯示外掛程式狀態")
    subs.add_parser("config", help="顯示外掛程式設定")
    subparser.set_defaults(func=_my_command)

def register(ctx):
    ctx.register_tool(...)
    ctx.register_cli_command(
        name="my-plugin",
        help="管理我的外掛程式",
        setup_fn=_setup_argparse,
        handler_fn=_my_command,
    )
```

註冊後，使用者可以執行 `hermes my-plugin status`, `hermes my-plugin config` 等。

**記憶體供應商外掛程式** 採用基於約定的方法：在您的外掛程式 `cli.py` 檔案中新增 `register_cli(subparser)` 函數。記憶體外掛程式探索系統會自動找到它 — 無需調用 `ctx.register_cli_command()`。詳情請參閱 [記憶體供應商外掛程式指南](/docs/developer-guide/memory-provider-plugin#adding-cli-commands)。

**活動供應商限制：** 記憶體供應商 CLI 指令僅在其供應商為設定中活動的 `memory.provider` 時才會出現。如果使用者尚未設定您的供應商，您的 CLI 指令就不會出現在說明輸出中。

:::tip
本指南涵蓋**一般外掛程式**（工具、掛鉤、CLI 指令）。關於特殊外掛程式類型，請參閱：
- [記憶體供應商外掛程式](/docs/developer-guide/memory-provider-plugin) — 跨對話知識後端
- [上下文引擎外掛程式](/docs/developer-guide/context-engine-plugin) — 替代上下文管理策略
:::

### 透過 pip 發佈

若要公開分享外掛程式，請在您的 Python 專案中新增入口點 (Entry Point)：

```toml
# pyproject.toml
[project.entry-points."hermes_agent.plugins"]
my-plugin = "my_plugin_package"
```

```bash
pip install hermes-plugin-calculator
# 在下次 hermes 啟動時會自動探索外掛程式
```

## 常見錯誤

**處理器未回傳 JSON 字串：**
```python
# 錯誤 — 回傳字典
def handler(args, **kwargs):
    return {"result": 42}

# 正確 — 回傳 JSON 字串
def handler(args, **kwargs):
    return json.dumps({"result": 42})
```

**處理器簽章中缺失 `**kwargs`：**
```python
# 錯誤 — 如果 Hermes 傳遞額外上下文，程式會崩潰
def handler(args):
    ...

# 正確
def handler(args, **kwargs):
    ...
```

**處理器 raise 異常：**
```python
# 錯誤 — 異常傳播，工具調用失敗
def handler(args, **kwargs):
    result = 1 / int(args["value"])  # ZeroDivisionError!
    return json.dumps({"result": result})

# 正確 — 捕捉並回傳錯誤 JSON
def handler(args, **kwargs):
    try:
        result = 1 / int(args.get("value", 0))
        return json.dumps({"result": result})
    except Exception as e:
        return json.dumps({"error": str(e)})
```

**架構說明過於模糊：**
```python
# 差 — 模型不知道何時使用它
"description": "執行一些任務"

# 好 — 模型明確知道時機和方式
"description": "計算數學表達式。用於算術、三角函數、對數。支援：+, -, *, /, **, sqrt, sin, cos, log, pi, e。"
```
