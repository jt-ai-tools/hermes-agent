---
name: hermes-atropos-environments
description: 建構、測試和除錯用於 Atropos 訓練的 Hermes Agent RL 環境。涵蓋 HermesAgentBaseEnv 介面、獎勵函數、代理迴圈整合、工具評估、wandb 日誌記錄，以及三種 CLI 模式（serve/process/evaluate）。在 hermes-agent 儲存庫中建立、審查或修復 RL 環境時使用。
version: 1.1.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [atropos, rl, environments, training, reinforcement-learning, reward-functions]
    related_skills: [axolotl, grpo-rl-training, trl-fine-tuning, lm-evaluation-harness]
---

# Hermes Agent Atropos 環境

在 hermes-agent 儲存庫中建構與 Atropos 訓練框架整合的強化學習 (RL) 環境指南。

## 架構概觀

```
Atropos BaseEnv (atroposlib/envs/base.py)
    └── HermesAgentBaseEnv (environments/hermes_base_env.py)
            ├── 處理代理迴圈 (agent loop) 編排
            ├── 處理每個群組的工具解析
            ├── 處理用於獎勵驗證的 ToolContext
            └── 您的環境 (environments/your_env.py)
                    僅實作：setup, get_next_item, format_prompt,
                            compute_reward, evaluate, wandb_log
```

Hermes 環境非常特殊，因為它們運行 **具有工具調用的多輪代理迴圈** —— 而不僅僅是單輪補全。基礎環境處理迴圈；您則負責實作任務和評分。

## 檔案位置

| 檔案 | 用途 |
|------|---------|
| `environments/hermes_base_env.py` | 具有代理迴圈 + 工具解析的基礎類別 |
| `environments/agent_loop.py` | `HermesAgentLoop` + `AgentResult` 資料類別 |
| `environments/tool_context.py` | 用於獎勵驗證的 `ToolContext` |
| `environments/tool_call_parsers.py` | 第 2 階段工具調用解析器 (hermes, mistral 等) |
| `environments/your_env.py` | 您的環境實作 |

## 推論設定 —— 先詢問使用者

**重要：** 在運行任何測試、評估或資料生成命令之前，請務必詢問使用者希望如何處理推論。不要預設使用 OpenRouter 或任何特定端點。請提供以下選項：

1. **OpenRouter** —— 詢問他們想使用哪個模型（例如 `anthropic/claude-sonnet-4.5`, `google/gemini-2.5-pro`, `meta-llama/llama-3.3-70b-instruct` 等）。環境中需要 `OPENROUTER_API_KEY`。
2. **自我託管的 VLLM 端點** —— 詢問其基礎 URL（例如 `http://localhost:8000/v1`）和模型名稱。設定 `--openai.server_type vllm`。
3. **其他與 OpenAI 相容的 API** —— 詢問基礎 URL、模型名稱以及任何所需的 API 金鑰。設定 `--openai.server_type openai` 並將 `--openai.health_check` 設為 `false`。
4. **本地 Atropos 訓練伺服器** —— 用於具有實時訓練迴圈的 `serve` 模式。預設為 `http://localhost:8000/v1`。

一旦使用者告知其設定，請在該工作階段的所有 CLI 命令中使用這些值。範例提示：

> "在執行此操作之前，您希望如何處理推論？
> 1. OpenRouter（我需要您偏好的模型，例如 claude-sonnet-4.5）
> 2. 自我託管的 VLLM 端點（請提供 URL 和模型名稱）
> 3. 其他與 OpenAI 相容的 API（請提供 URL、模型和任何身份驗證詳細資訊）
> 4. 本地 Atropos 訓練伺服器 (serve 模式)"

### 各供應商的關鍵標記 (Flags)：

| 供應商 | `--openai.server_type` | `--openai.health_check` | `--openai.api_key` |
|----------|----------------------|------------------------|-------------------|
| OpenRouter | `openai` | `false` | `$OPENROUTER_API_KEY` |
| VLLM (自我託管) | `vllm` | (預設) | (不需要) |
| 其他 OpenAI 相容 | `openai` | `false` | 視需要而定 |
| 本地 Atropos | (預設) | (預設) | (不需要) |

## 必要方法

### 1. `setup()` —— 載入資料集並初始化狀態

```python
async def setup(self) -> None:
    """啟動時調用一次。載入資料集，初始化狀態。"""
    # 優先嘗試 HuggingFace，失敗則回退到內建範例
    try:
        from datasets import load_dataset
        ds = load_dataset("your/dataset", split="test")
        self._items = [...]
    except Exception:
        self._items = BUILTIN_SAMPLES

    # 務必分割為訓練/評估集
    random.shuffle(self._items)
    eval_size = max(20, int(len(self._items) * 0.1))
    self._eval_items = self._items[:eval_size]
    self._items = self._items[eval_size:]
```

### 2. `get_next_item()` —— 回傳下一個訓練項目

```python
async def get_next_item(self) -> dict:
    """回傳下一個項目，在資料集中循環。"""
    item = self._items[self._index % len(self._items)]
    self._index += 1
    return item
```

### 3. `format_prompt(item)` —— 將項目轉換為使用者訊息

```python
def format_prompt(self, item: dict) -> str:
    """將資料集項目轉換為面向使用者的提示語。"""
    return f"請研究這個問題：{item['question']}"
```

### 4. `compute_reward(item, result, ctx)` —— 為 Rollout 評分

**關鍵點**：`result` 是一個 `AgentResult` 對象，而非字典。它具有以下屬性：
- `result.messages` —— 訊息字典列表 (OpenAI 格式)
- `result.turns_used` —— 進行的 LLM 調用次數
- `result.finished_naturally` —— 如果模型自願停止則為 True
- `result.tool_errors` —— ToolError 對象列表

**AgentResult 不具備**：`final_response`, `tool_calls`, `tools_used` 屬性。
您必須從 `result.messages` 中擷取這些資訊：

```python
async def compute_reward(self, item, result: AgentResult, ctx: ToolContext) -> float:
    # 擷取最終回應（最後一條具有內容的 assistant 訊息）
    final_response = ""
    tools_used = []
    for msg in reversed(result.messages):
        if msg.get("role") == "assistant" and msg.get("content") and not final_response:
            final_response = msg["content"]
        if msg.get("role") == "assistant" and msg.get("tool_calls"):
            for tc in msg["tool_calls"]:
                fn = tc.get("function", {}) if isinstance(tc, dict) else {}
                name = fn.get("name", "")
                if name:
                    tools_used.append(name)

    # 使用 LLM 裁判 (judge)、啟發式方法或 ToolContext 驗證進行評分
    correctness = await self._llm_judge(item, final_response)
    return correctness
```

`ctx` (ToolContext) 讓您能夠訪問代理的沙盒以進行終端/檔案驗證：
```python
# 在代理的沙盒中執行測試
result = ctx.terminal("pytest /workspace/test.py")
return 1.0 if result["exit_code"] == 0 else 0.0
```

### 5. `evaluate()` —— 使用完整代理迴圈進行定期評估

**必須使用帶有工具的完整代理迴圈**，而不是單輪的 chat_completion。
hermes-agent 環境的核心價值在於具備代理能力的評估 (agentic evaluation)：

```python
async def evaluate(self, *args, **kwargs) -> None:
    import time, uuid
    from environments.agent_loop import HermesAgentLoop
    from environments.tool_context import ToolContext

    start_time = time.time()
    tools, valid_names = self._resolve_tools_for_group()
    samples = []

    for item in self._eval_items[:self.config.eval_size]:
        task_id = str(uuid.uuid4())
        messages = []
        if self.config.system_prompt:
            messages.append({"role": "system", "content": self.config.system_prompt})
        messages.append({"role": "user", "content": self.format_prompt(item)})

        agent = HermesAgentLoop(
            server=self.server,
            tool_schemas=tools,
            valid_tool_names=valid_names,
            max_turns=self.config.max_agent_turns,
            task_id=task_id,
            temperature=0.0,  # 評估時使用確定性結果
            max_tokens=self.config.max_token_length,
            extra_body=self.config.extra_body,
        )
        result = await agent.run(messages)

        ctx = ToolContext(task_id)
        try:
            reward = await self.compute_reward(item, result, ctx)
        finally:
            ctx.cleanup()

        samples.append({"prompt": ..., "response": ..., "reward": reward})

    eval_metrics = {"eval/mean_reward": ...}
    await self.evaluate_log(metrics=eval_metrics, samples=samples,
                            start_time=start_time, end_time=time.time())
```

### 6. `wandb_log()` —— 自定義指標日誌記錄

務必在最後調用 `super().wandb_log()`：

```python
async def wandb_log(self, wandb_metrics=None):
    if wandb_metrics is None:
        wandb_metrics = {}
    if self._reward_buffer:
        n = len(self._reward_buffer)
        wandb_metrics["train/mean_reward"] = sum(self._reward_buffer) / n
        self._reward_buffer.clear()
    await super().wandb_log(wandb_metrics)  # 務必調用 super
```

**陷阱**：`compute_reward` 會附加到指標緩衝區。在評估期間，這會污染訓練指標。請回溯評估期間新增的緩衝區項目。

## Config 類別

務必使用 Pydantic Field 描述符建立自定義設定子類別。您可以調整的關鍵繼承欄位：`enabled_toolsets`, `max_agent_turns`, `agent_temperature`, `system_prompt`, `terminal_backend`, `group_size`, `steps_per_eval`, `total_steps`。

## config_init() —— 預設組態

類別方法，回傳 `(YourEnvConfig, [APIServerConfig(...)])`。對於 OpenRouter/外部 API，將 server_type 設定為 "openai"。從環境變數載入 API 金鑰。

## 三種 CLI 模式

```bash
# SERVE —— 完整訓練迴圈（連接到 Atropos API 伺服器）
python environments/my_env.py serve --openai.base_url http://localhost:8000/v1

# PROCESS —— 離線資料生成（儲存為 JSONL）
python environments/my_env.py process --env.total_steps 10 --env.group_size 1 \
    --env.use_wandb false --env.data_path_to_save_groups output.jsonl \
    --openai.base_url "<USER_BASE_URL>" \
    --openai.model_name "<USER_MODEL>" \
    --openai.server_type <USER_SERVER_TYPE> --openai.health_check false

# EVALUATE —— 獨立評估（僅運行 setup + evaluate）
python environments/my_env.py evaluate --env.eval_size 20 \
    --env.data_dir_to_save_evals /tmp/eval_results \
    --openai.base_url "<USER_BASE_URL>" \
    --openai.model_name "<USER_MODEL>" \
    --openai.server_type <USER_SERVER_TYPE> --openai.health_check false
```

組態優先順序：CLI 參數 > YAML 檔案 > `config_init()` 預設值。

## 常見陷阱

1. **AgentResult 具有 .messages 而非 .final_response** —— 透過反向遍歷 `result.messages` 尋找最後一條具有內容的 assistant 訊息來擷取最終回應。

2. **evaluate() 必須使用 HermesAgentLoop，而非 chat_completion** —— 單輪 chat_completion 沒有工具。hermes-agent 基準測試的核心點在於使用工具的代理評估。

3. **不要調用 _llm_judge 兩次** —— 如果 `compute_reward` 已經調用了它，請從緩衝區中擷取分數，而不是在 `evaluate()` 中單獨調用裁判。

4. **評估污染訓練緩衝區** —— `compute_reward` 會附加到指標緩衝區。在評估期間，請回溯緩衝區項目以保持訓練指標乾淨。

5. **對於 OpenRouter 務必設定 health_check=false** —— OpenRouter 沒有 `/health` 端點。

6. **在 evaluate 模式下設定 data_dir_to_save_evals** —— 若未設定，結果將不會被儲存。

7. **default_toolsets 類別變數 vs enabled_toolsets 組態** —— 類別變數是一個提示；組態欄位才是實際控制工具解析的關鍵。

8. **訊息中的工具調用解析** —— 工具調用是具有 `{"function": {"name": ..., "arguments": ...}}` 結構的字典。務必檢查 `isinstance(tc, dict)`。

9. **ToolContext.cleanup()** —— 務必在 `finally` 區塊中調用，以釋放沙盒資源。

10. **外部 API 的 server_type 必須為 "openai"** —— 否則 Atropos 會假定是本地 VLLM 伺服器。

11. **務必詢問使用者的推論設定** —— 永遠不要硬編碼或預設特定的供應商/模型。請參閱上方的「推論設定」章節。

## 獎勵函數模式

### LLM 裁判 (Judge)（用於開放式任務）
使用 `self.server.chat_completion()` 並提供評分提示語。解析 JSON 回應以獲取浮點數分數。務必包含啟發式回退方案（關鍵字重疊），以防裁判調用失敗。

### 二元驗證（用於程式碼/終端任務）
使用 `ctx.terminal("pytest test.py -q")` 在代理的沙盒中運行測試。通過回傳 1.0，失敗回傳 0.0。

### 多重信號（結合多個指標）
加權計算正確性 (0.6) + 工具使用 (0.2) + 效率 (0.2) + 選用加分。將結果限制在 [0, 1] 範圍內。

## 測試您的環境

1. **匯入測試**：`python -c "from environments.my_env import MyEnv; print('OK')"`
2. **詢問使用者的推論設定**（參閱上方的「推論設定」章節）
3. **Process 模式** (1 個項目)：驗證 JSONL 輸出是否具有有效的 token、遮罩 (masks) 和分數
4. **Evaluate 模式**：驗證完整的代理迴圈是否隨工具運行，指標是否正確記錄
5. **檢查獎勵範圍**：分數應在 [0, 1] 之間，而非全部相同

## 最低限度實作檢查清單

```python
class MyEnv(HermesAgentBaseEnv):
    name = "my-env"
    env_config_cls = MyEnvConfig

    @classmethod
    def config_init(cls): ...          # 預設伺服器 + 環境組態
    async def setup(self): ...         # 載入資料集 + 訓練/評估分割
    async def get_next_item(self): ... # 循環訓練項目
    def format_prompt(self, item): ... # 項目 → 使用者訊息字串
    async def compute_reward(self, item, result, ctx): ...  # 為 Rollout 評分
    async def evaluate(self, *args, **kwargs): ...  # 完整代理迴圈評估
    async def wandb_log(self, metrics=None): ...    # 自定義指標 + super()

if __name__ == "__main__":
    MyEnv.cli()
```
