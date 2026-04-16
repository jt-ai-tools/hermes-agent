# 軌跡格式 (Trajectory Format)

Hermes Agent 以 ShareGPT 相容的 JSONL 格式儲存對話軌跡，用於訓練數據、除錯產出以及增強學習 (reinforcement learning) 資料集。

原始碼檔案：`agent/trajectory.py`、`run_agent.py`（搜尋 `_save_trajectory`）、`batch_runner.py`


## 檔案命名慣例

軌跡會被寫入當前工作目錄下的檔案中：

| 檔案 | 時機 |
|------|------|
| `trajectory_samples.jsonl` | 成功完成的對話 (`completed=True`) |
| `failed_trajectories.jsonl` | 失敗或中斷的對話 (`completed=False`) |

批次執行器 (`batch_runner.py`) 會為每個批次寫入自定義的輸出檔案（例如 `batch_001_output.jsonl`），並包含額外的元數據 (metadata) 欄位。

您可以透過 `save_trajectory()` 中的 `filename` 參數覆蓋檔案名稱。


## JSONL 條目格式

檔案中的每一行都是一個獨立的 JSON 物件。有兩種變體：

### CLI/互動式格式 (來自 `_save_trajectory`)

```json
{
  "conversations": [ ... ],
  "timestamp": "2026-03-30T14:22:31.456789",
  "model": "anthropic/claude-sonnet-4.6",
  "completed": true
}
```

### 批次執行器格式 (來自 `batch_runner.py`)

```json
{
  "prompt_index": 42,
  "conversations": [ ... ],
  "metadata": { "prompt_source": "gsm8k", "difficulty": "hard" },
  "completed": true,
  "partial": false,
  "api_calls": 7,
  "toolsets_used": ["code_tools", "file_tools"],
  "tool_stats": {
    "terminal": {"count": 3, "success": 3, "failure": 0},
    "read_file": {"count": 2, "success": 2, "failure": 0},
    "write_file": {"count": 0, "success": 0, "failure": 0}
  },
  "tool_error_counts": {
    "terminal": 0,
    "read_file": 0,
    "write_file": 0
  }
}
```

`tool_stats` 和 `tool_error_counts` 字典經過標準化處理，包含來自 `model_tools.TOOL_TO_TOOLSET_MAP` 的**所有**可能工具，預設值為零，以確保在載入 HuggingFace 資料集時具有一致的綱要。


## 對話陣列 (ShareGPT 格式)

`conversations` 陣列使用 ShareGPT 角色慣例：

| API 角色 | ShareGPT `from` |
|----------|-----------------|
| system (系統) | `"system"` |
| user (使用者) | `"human"` |
| assistant (助理) | `"gpt"` |
| tool (工具) | `"tool"` |

### 完整範例

```json
{
  "conversations": [
    {
      "from": "system",
      "value": "You are a function calling AI model. You are provided with function signatures within <tools> </tools> XML tags. You may call one or more functions to assist with the user query. If available tools are not relevant in assisting with user query, just respond in natural conversational language. Don't make assumptions about what values to plug into functions. After calling & executing the functions, you will be provided with function results within <tool_response> </tool_response> XML tags. Here are the available tools:\n<tools>\n[{\"name\": \"terminal\", \"description\": \"Execute shell commands\", \"parameters\": {\"type\": \"object\", \"properties\": {\"command\": {\"type\": \"string\"}}}, \"required\": null}]\n</tools>\nFor each function call return a JSON object, with the following pydantic model json schema for each:\n{'title': 'FunctionCall', 'type': 'object', 'properties': {'name': {'title': 'Name', 'type': 'string'}, 'arguments': {'title': 'Arguments', 'type': 'object'}}, 'required': ['name', 'arguments']}\nEach function call should be enclosed within <tool_call> </tool_call> XML tags.\nExample:\n<tool_call>\n{'name': <function-name>,'arguments': <args-dict>}\n</tool_call>"
    },
    {
      "from": "human",
      "value": "已安裝的 Python 版本為何？"
    },
    {
      "from": "gpt",
      "value": "<think>\n使用者想知道 Python 版本。我應該執行 python3 --version。\n</think>\n<tool_call>\n{\"name\": \"terminal\", \"arguments\": {\"command\": \"python3 --version\"}}\n</tool_call>"
    },
    {
      "from": "tool",
      "value": "<tool_response>\n{\"tool_call_id\": \"call_abc123\", \"name\": \"terminal\", \"content\": \"Python 3.11.6\"}\n</tool_response>"
    },
    {
      "from": "gpt",
      "value": "<think>\n已取得版本。我現在可以回答使用者了。\n</think>\n此系統上安裝了 Python 3.11.6。"
    }
  ],
  "timestamp": "2026-03-30T14:22:31.456789",
  "model": "anthropic/claude-sonnet-4.6",
  "completed": true
}
```


## 標準化規則 (Normalization Rules)

### 推理內容標記 (Reasoning Content Markup)

軌跡轉換器會將**所有**推理內容標準化為 `<think>` 標籤，無論模型最初是如何產生的：

1. **原生思考標記 (Native thinking tokens)**（來自 Anthropic、OpenAI o 系列等供應商的 `msg["reasoning"]` 欄位）：封裝為 `<think>\n{reasoning}\n</think>\n` 並預置於內容之前。

2. **REASONING_SCRATCHPAD XML**（當停用原生思考且模型透過系統提示詞指示的 XML 進行推理時）：`<REASONING_SCRATCHPAD>` 標籤會透過 `convert_scratchpad_to_think()` 轉換為 `<think>`。

3. **空的思考區塊**：每個 `gpt` 回合都保證有一個 `<think>` 區塊。如果沒有產生推理內容，則插入一個空區塊：`<think>\n</think>\n` — 這確保了訓練數據格式的一致性。

### 工具呼叫標準化 (Tool Call Normalization)

來自 API 格式的工具呼叫（帶有 `tool_call_id`、函式名稱、JSON 字串形式的參數）會轉換為 XML 封裝的 JSON：

```
<tool_call>
{"name": "terminal", "arguments": {"command": "ls -la"}}
</tool_call>
```

- 參數會從 JSON 字串解析回物件（避免雙重編碼）。
- 如果 JSON 解析失敗（不應發生 — 已在對話期間驗證），則使用空的 `{}` 並記錄警告。
- 一個助理回合中的多個工具呼叫會在單個 `gpt` 訊息中產生多個 `<tool_call>` 區塊。

### 工具回應標準化 (Tool Response Normalization)

助理訊息之後的所有工具結果都會分組到一個單獨的 `tool` 回合中，並帶有 XML 封裝的 JSON 回應：

```
<tool_response>
{"tool_call_id": "call_abc123", "name": "terminal", "content": "output here"}
</tool_response>
```

- 如果工具內容看起來像 JSON（以 `{` 或 `[` 開頭），它會被解析，以便 `content` 欄位包含 JSON 物件/陣列而非字串。
- 多個工具結果會在一個訊息中以換行符號連接。
- 工具名稱會根據位置與父級助理的 `tool_calls` 陣列進行比對。

### 系統訊息 (System Message)

系統訊息是在儲存時產生的（而非取自對話）。它遵循 Hermes 函式呼叫提示範本，包含：

- 解釋函式呼叫協定的前導說明 (Preamble)
- 包含 JSON 工具定義的 `<tools>` XML 區塊
- `FunctionCall` 物件的綱要參考
- `<tool_call>` 範例

工具定義包含 `name`, `description`, `parameters`, 和 `required`（設置為 `null` 以符合標準格式）。


## 載入軌跡 (Loading Trajectories)

軌跡是標準的 JSONL 格式 — 可使用任何 JSON-lines 讀取器載入：

```python
import json

def load_trajectories(path: str):
    """從 JSONL 檔案載入軌跡條目。"""
    entries = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                entries.append(json.loads(line))
    return entries

# 僅過濾成功完成的條目
successful = [e for e in load_trajectories("trajectory_samples.jsonl")
              if e.get("completed")]

# 僅提取對話內容用於訓練
training_data = [e["conversations"] for e in successful]
```

### 為 HuggingFace 資料集載入

```python
from datasets import load_dataset

ds = load_dataset("json", data_files="trajectory_samples.jsonl")
```

標準化的 `tool_stats` 綱要確保所有條目都具有相同的欄位，防止在載入資料集時發生 Arrow 綱要不匹配錯誤。


## 控制軌跡儲存

在 CLI 中，軌跡儲存由以下方式控制：

```yaml
# config.yaml
agent:
  save_trajectories: true  # 預設：false
```

或透過 `--save-trajectories` 旗標控制。當代理以 `save_trajectories=True` 初始化時，會在每個對話回合結束時呼叫 `_save_trajectory()` 方法。

批次執行器始終儲存軌跡（這是其主要目的）。

所有回合中推理內容皆為空的樣本會被批次執行器自動捨棄，以避免用無推理的範例污染訓練數據。
