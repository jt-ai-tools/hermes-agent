# Hermes-Agent Atropos 環境 (Hermes-Agent Atropos Environments)

本目錄包含 **hermes-agent** 的工具呼叫能力與 **Atropos** 強化學習 (RL) 訓練框架之間的整合層。它提供了運行代理人導向 LLM 透過多回合工具呼叫迴圈所需的一切，並使用任意獎勵函式對其輸出進行評分，最後將結果餵入 Atropos 進行訓練或評估。

## 架構概覽 (Architecture Overview)

```
                        Atropos 框架
                    ┌───────────────────────┐
                    │       BaseEnv          │  (atroposlib)
                    │  - 伺服器管理          │
                    │  - 工作排程            │
                    │  - Wandb 日誌記錄      │
                    │  - CLI (serve/process/ │
                    │    evaluate)           │
                    └───────────┬───────────┘
                                │ 繼承
                    ┌───────────┴───────────┐
                    │  HermesAgentBaseEnv    │  hermes_base_env.py
                    │  - 終端機後端          │
                    │  - 工具解析            │
                    │  - 代理人迴圈          │
                    │  - 工具上下文          │
                    │  - 非同步修補程式      │
                    └───────────┬───────────┘
                                │ 繼承
              ┌─────────────────┼─────────────────┐
              │                 │                  │
     TerminalTestEnv     HermesSweEnv    TerminalBench2EvalEnv
     (堆疊測試)          (SWE 訓練)      (TB2 基準評估)
```

### 繼承鏈 (Inheritance Chain)

**BaseEnv** (源自 `atroposlib`) 是 Atropos 的基礎類別。它提供：
- 伺服器管理 (OpenAI 相容 API 伺服器, VLLM, SGLang)
- 用於並行推演 (Rollouts) 的工作排程
- 用於指標和推演日誌記錄的 Wandb 整合
- 具有三個子指令的 CLI 介面：`serve`、`process`、`evaluate`
- 用於將評估結果儲存至 JSON + samples.jsonl 的 `evaluate_log()`

**HermesAgentBaseEnv** (`hermes_base_env.py`) 擴展了 BaseEnv，並加入 hermes-agent 的特定內容：
- 設定 `os.environ["TERMINAL_ENV"]` 以配置終端機後端 (local, docker, modal, daytona, ssh, singularity)
- 透過 `_resolve_tools_for_group()` 解析 hermes-agent 工具集 (呼叫查詢 `tools/registry.py` 的 `get_tool_definitions()`)
- 實作 `collect_trajectory()`，執行完整的代理人迴圈並計算獎勵
- 支援兩階段運作 (第一階段：OpenAI 伺服器，第二階段：VLLM ManagedServer)
- 在匯入時套用非同步安全工具運作的猴子補丁 (Monkey patches)

具體的環境繼承自 `HermesAgentBaseEnv` 並實作：
- `setup()` -- 載入資料集，初始化狀態
- `get_next_item()` -- 回傳下一個用於推演的項目
- `format_prompt()` -- 將資料集項目轉換為使用者訊息
- `compute_reward()` -- 使用 ToolContext 為推演評分
- `evaluate()` -- 定期評估邏輯

## 核心組件 (Core Components)

### 代理人迴圈 (Agent Loop - `agent_loop.py`)

`HermesAgentLoop` 是可重用的多回合代理人引擎。它執行與 hermes-agent 的 `run_agent.py` 相同的模式：

1. 透過 `server.chat_completion()` 將訊息與工具傳送至 API
2. 如果回應包含 `tool_calls`，則透過 `handle_function_call()` 執行每一個呼叫 (這會委託給 `tools/registry.py` 的 `dispatch()`)
3. 將工具結果附加至對話中，並回到步驟 1
4. 如果回應中沒有 tool_calls，則代理人工作完成

工具呼叫在執行緒池 (`run_in_executor`) 中執行，因此內部使用 `asyncio.run()` 的後端 (如 Modal, Docker) 不會在 Atropos 的事件迴圈中發生死結。

回傳一個 `AgentResult`，包含完整的對話歷史、回合數、每回合推理內容、工具錯誤以及可選的 ManagedServer 狀態 (用於第二階段)。

### 工具上下文 (Tool Context - `tool_context.py`)

`ToolContext` 是每個推演的控制代碼，讓獎勵/驗證函式可以直接存取**所有** hermes-agent 工具，範圍限定於推演的 `task_id`。相同的 `task_id` 意味著終端機/瀏覽器工作階段與模型在其推演期間使用的是同一個 —— 所有的狀態（檔案、程序、瀏覽器分頁）都被保留下來。

```python
async def compute_reward(self, item, result, ctx: ToolContext):
    # 在模型的終端機沙箱中執行測試
    test = ctx.terminal("pytest -v")
    if test["exit_code"] == 0:
        return 1.0

    # 檢查檔案是否已建立
    content = ctx.read_file("/workspace/solution.py")
    if content.get("content"):
        return 0.5

    # 本地下載檔案以進行驗證 (二進位安全)
    ctx.download_file("/remote/output.bin", "/local/output.bin")

    return 0.0
```

可用方法：
- **終端機 (Terminal)**：`terminal(command, timeout)` -- 執行 shell 指令
- **檔案 (Files)**：`read_file(path)`, `write_file(path, content)`, `search(query, path)`
- **傳輸 (Transfers)**：`upload_file()`, `upload_dir()`, `download_file()`, `download_dir()` -- 主機與沙箱之間的二進位安全檔案傳輸
- **網路 (Web)**：`web_search(query)`, `web_extract(urls)`
- **瀏覽器 (Browser)**：`browser_navigate(url)`, `browser_snapshot()`
- **泛用 (Generic)**：`call_tool(name, args)` -- 透過名稱呼叫任何 hermes-agent 工具
- **清理 (Cleanup)**：`cleanup()` -- 釋放所有資源 (在 `compute_reward` 之後自動呼叫)

### 修補程式 (Patches - `patches.py`)

**問題**：某些 hermes-agent 工具內部使用 `asyncio.run()` (例如 Modal 後端)。當從 Atropos 的事件迴圈內部呼叫時，這會導致崩潰，因為 `asyncio.run()` 不能巢狀呼叫。

**解決方案**：`ModalEnvironment` 使用專用的 `_AsyncWorker` 背景執行緒及其自身的事件迴圈。呼叫程式碼看到的是同步介面，但在內部，所有非同步 Modal SDK 呼叫都發生在背景執行緒上，因此不會與 Atropos 的迴圈發生衝突。這已直接建構在 `tools/environments/modal.py` 中 —— 不需要猴子補丁。

`patches.py` 現在不執行任何操作 (僅保留以維持匯入相容性)。

### 工具呼叫解析器 (Tool Call Parsers - `tool_call_parsers/`)

客戶端解析器，用於從原始模型輸出文字中擷取結構化的 `tool_calls`。用於**第二階段** (VLLM 伺服器類型)，其中 ManagedServer 的 `/generate` 端點回傳原始文字，而沒有工具呼叫解析。

每個解析器都是對應 VLLM 解析器之 `extract_tool_calls()` 邏輯的獨立重新實作。無 VLLM 依賴 —— 僅使用標準函式庫 (`re`, `json`, `uuid`) 和 `openai` 類型。

可用解析器：
- `hermes` -- Hermes/ChatML `<tool_call>` XML 格式
- `mistral` -- Mistral `[TOOL_CALLS]` 格式
- `llama3_json` -- Llama 3 JSON 工具呼叫
- `qwen` -- Qwen 工具呼叫格式
- `qwen3_coder` -- Qwen3 Coder 格式
- `deepseek_v3` -- DeepSeek V3 格式
- `deepseek_v3_1` -- DeepSeek V3.1 格式
- `kimi_k2` -- Kimi K2 格式
- `longcat` -- Longcat 格式
- `glm45` / `glm47` -- GLM 模型格式

用法：
```python
from environments.tool_call_parsers import get_parser

parser = get_parser("hermes")
content, tool_calls = parser.parse(raw_model_output)
```

在第一階段 (OpenAI 伺服器類型) 中，不需要這些解析器 —— 伺服器會原生處理工具呼叫解析。

## 兩階段運作 (Two-Phase Operation)

### 第一階段：OpenAI 伺服器 (評估 / SFT 資料產生)

使用帶有 `tools=` 參數的 `server.chat_completion()`。伺服器 (VLLM, SGLang, OpenRouter, OpenAI) 原生處理工具呼叫解析。回傳具有結構化 `tool_calls` 的 `ChatCompletion` 物件。

- 適用於：評估、監督式微調 (SFT) 資料產生、測試
- 執行方式：使用 `serve` (搭配 `run-api`)、`process` 或 `evaluate` 子指令
- 為 Atropos 管線建立預留位置代幣

### 第二階段：VLLM ManagedServer (完整 RL 訓練)

透過 `/generate` 使用 ManagedServer 獲取精確的代幣 ID + 日誌機率 (Logprobs)。客戶端工具呼叫解析器 (源自 `tool_call_parsers/`) 從原始輸出重建結構化的 `tool_calls`。

- 適用於：使用 GRPO/PPO 的完整 RL 訓練
- 執行方式：使用 `serve` 子指令
- 真實代幣、遮罩與日誌機率流經管線

## 目錄結構 (Directory Structure)

```
environments/
├── README.md                     # 本檔案
├── __init__.py                   # 套件匯出
├── hermes_base_env.py            # 抽象基礎類別 (HermesAgentBaseEnv)
├── agent_loop.py                 # 多回合代理人引擎 (HermesAgentLoop)
├── tool_context.py               # 獎勵函式的每推演工具存取
├── patches.py                    # 用於 Modal 後端的非同步安全修補程式
│
├── tool_call_parsers/            # 第二階段客戶端解析器
│   ├── __init__.py               # 註冊表 + 基礎類別
│   ├── hermes_parser.py
│   ├── mistral_parser.py
│   ├── llama_parser.py
│   ├── qwen_parser.py
│   ├── qwen3_coder_parser.py
│   ├── deepseek_v3_parser.py
│   ├── deepseek_v3_1_parser.py
│   ├── kimi_k2_parser.py
│   ├── longcat_parser.py
│   ├── glm45_parser.py
│   └── glm47_parser.py
│
├── terminal_test_env/            # 堆疊驗證環境
│   └── terminal_test_env.py
│
├── hermes_swe_env/               # SWE-bench 風格的訓練環境
│   └── hermes_swe_env.py
│
└── benchmarks/                   # 評估基準
    ├── terminalbench_2/          # 89 個終端機任務, Modal 沙箱
    │   └── terminalbench2_env.py
    ├── tblite/                   # 100 個校準任務 (快速 TB2 代理)
    │   └── tblite_env.py
    └── yc_bench/                 # 長週期策略基準
        └── yc_bench_env.py
```

## 具體環境 (Concrete Environments)

### TerminalTestEnv (`terminal_test_env/`)

一個包含內建任務的自足環境（無需外部資料集），用於驗證整個堆疊的端到端運作。每個任務要求模型在已知路徑建立檔案，驗證程式會檢查內容是否相符。

```bash
# Serve 模式 (需要 run-api)
run-api
python environments/terminal_test_env/terminal_test_env.py serve

# Process 模式 (無需 run-api, 儲存至 JSONL)
python environments/terminal_test_env/terminal_test_env.py process \
    --env.data_path_to_save_groups terminal_test_output.jsonl
```

### HermesSweEnv (`hermes_swe_env/`)

SWE-bench 風格的訓練環境。模型接收一個編碼任務，使用終端機 + 檔案 + 網路工具來解決它，而獎勵函式在同一個 Modal 沙箱中執行測試。

```bash
python environments/hermes_swe_env/hermes_swe_env.py serve \
    --openai.model_name YourModel \
    --env.dataset_name bigcode/humanevalpack \
    --env.terminal_backend modal
```

### TerminalBench2EvalEnv (`benchmarks/terminalbench_2/`)

**僅限評估**的環境，用於 Terminal-Bench 2.0 基準測試 (89 個任務)。每個任務都有一個預先建構的 Docker Hub 映像檔、自然語言說明和測試套件。代理人使用終端機 + 檔案工具來解決任務，然後測試套件驗證正確性。

遵循標準的 Atropos 評估模式（如 GPQA, MMLU 等）：
- 透過 `evaluate` 子指令執行（無需 `run-api`）
- `setup()` 載入資料集，`evaluate()` 執行所有任務
- `rollout_and_score_eval()` 處理每個任務的代理人迴圈 + 測試驗證
- 本地下載驗證程式輸出，以進行可靠的獎勵檢查 (Harbor 模式)

```bash
# 執行完整基準測試
python environments/benchmarks/terminalbench_2/terminalbench2_env.py evaluate \
    --openai.model_name anthropic/claude-opus-4.6

# 執行部分任務
python environments/benchmarks/terminalbench_2/terminalbench2_env.py evaluate \
    --openai.model_name anthropic/claude-opus-4.6 \
    --env.task_filter fix-git,git-multibranch

# 跳過特定任務
python environments/benchmarks/terminalbench_2/terminalbench2_env.py evaluate \
    --openai.model_name anthropic/claude-opus-4.6 \
    --env.skip_tasks heavy-task,slow-task
```

## 建立新環境 (Creating a New Environment)

### 訓練環境

1. 在 `environments/` 下建立新目錄
2. 建立繼承自 `HermesAgentBaseEnv` 的環境檔案
3. 實作四個抽象方法 + `evaluate()`

```python
from environments.hermes_base_env import HermesAgentBaseEnv, HermesAgentEnvConfig

class MyEnvConfig(HermesAgentEnvConfig):
    pass  # 根據需要新增自定義欄位

class MyEnv(HermesAgentBaseEnv):
    name = "my-env"
    env_config_cls = MyEnvConfig

    @classmethod
    def config_init(cls):
        env_config = MyEnvConfig(
            enabled_toolsets=["terminal", "file"],
            terminal_backend="modal",
            # ... 其他配置
        )
        server_configs = [APIServerConfig(...)]
        return env_config, server_configs

    async def setup(self):
        self.dataset = load_dataset(...)
        self.iter = 0

    async def get_next_item(self):
        item = self.dataset[self.iter % len(self.dataset)]
        self.iter += 1
        return item

    def format_prompt(self, item):
        return item["instruction"]

    async def compute_reward(self, item, result, ctx):
        # ctx 讓你可以完全存取推演沙箱中的工具
        test = ctx.terminal("pytest -v")
        return 1.0 if test["exit_code"] == 0 else 0.0

    async def evaluate(self, *args, **kwargs):
        # 定期評估邏輯
        ...

if __name__ == "__main__":
    MyEnv.cli()
```

### 僅限評估環境 (基準測試)

對於評估基準，請遵循 `terminalbench2_env.py` 中的模式：
1. 在 `environments/benchmarks/your-benchmark/` 下建立
2. 繼承自 `HermesAgentBaseEnv`
3. 設定僅限評估的配置：`eval_handling=STOP_TRAIN`, `steps_per_eval=1`, `total_steps=1`
4. 預留訓練方法的 stub (`collect_trajectories`, `score`)
5. 實作 `rollout_and_score_eval()` 和 `evaluate()`
6. 使用 `evaluate` 子指令執行

## 關鍵配置欄位 (Key Config Fields)

| 欄位 | 說明 | 預設值 |
|-------|-------------|---------|
| `enabled_toolsets` | 要啟用的 hermes 工具集 | `None` (全部) |
| `disabled_toolsets` | 要停用的工具集 | `None` |
| `distribution` | 機率性工具集分配名稱 | `None` |
| `max_agent_turns` | 每次推演的最大 LLM 呼叫次數 | `30` |
| `agent_temperature` | 取樣溫度 | `1.0` |
| `terminal_backend` | `local`, `docker`, `modal`, `daytona`, `ssh`, `singularity` | `local` |
| `system_prompt` | 代理人的系統訊息 | `None` |
| `tool_call_parser` | 第二階段的解析器名稱 | `hermes` |
| `eval_handling` | `STOP_TRAIN`, `LIMIT_TRAIN`, `NONE` | `STOP_TRAIN` |
