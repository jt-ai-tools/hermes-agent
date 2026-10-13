# AgentResult 欄位參考

`AgentResult` 定義於 `environments/agent_loop.py` 中，是一個資料類別 (Dataclass)。

## 欄位

| 欄位 | 類型 | 描述 |
|-------|------|-------------|
| `messages` | `List[Dict[str, Any]]` | OpenAI 訊息格式的完整對話歷史 |
| `managed_state` | `Optional[Dict]` | 如果是第 2 階段則為 ManagedServer.get_state()，否則為 None |
| `turns_used` | `int` | 迴圈期間進行的 LLM 呼叫次數 |
| `finished_naturally` | `bool` | 如果模型自行停止呼叫工具，則為 True |
| `reasoning_per_turn` | `List[Optional[str]]` | 每一輪提取的推理內容 |
| `tool_errors` | `List[ToolError]` | 迴圈期間遇到的工具錯誤 |

## ToolError 欄位

| 欄位 | 類型 | 描述 |
|-------|------|-------------|
| `turn` | `int` | 錯誤發生的輪次 |
| `tool_name` | `str` | 失敗的工具名稱 |
| `arguments` | `str` | 傳遞給工具的參數 |
| `error` | `str` | 錯誤訊息 |
| `tool_result` | `str` | 返回給模型的工具結果 |

## 從訊息中提取資料

訊息遵循 OpenAI 格式。常見模式如下：

```python
# 獲取最終的助手回答
for msg in reversed(result.messages):
    if msg.get("role") == "assistant" and msg.get("content"):
        final_response = msg["content"]
        break

# 獲取所有使用的工具名稱
tools = []
for msg in result.messages:
    if msg.get("role") == "assistant" and msg.get("tool_calls"):
        for tc in msg["tool_calls"]:
            fn = tc.get("function", {}) if isinstance(tc, dict) else {}
            tools.append(fn.get("name", ""))

# 獲取工具結果
for msg in result.messages:
    if msg.get("role") == "tool":
        tool_output = msg.get("content", "")
        call_id = msg.get("tool_call_id", "")
```

## 不存在的欄位

這些是常見的錯誤 —— AgentResult **不具備**以下欄位：
- `final_response` —— 請從 messages 中提取
- `tool_calls` —— 請從 messages 中提取
- `tools_used` —— 請從 messages 中提取
- `output` —— 請從 messages 中提取
- `response` —— 請從 messages 中提取
