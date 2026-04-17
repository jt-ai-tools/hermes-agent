# Atropos BaseEnv 參考

來源：`atroposlib/envs/base.py` (約 2124 行)

## 抽象方法（必須實作）

| 方法 | 簽署 (Signature) | 描述 |
|--------|-----------|-------------|
| `get_next_item()` | `async def get_next_item(self) -> Item` | 返回軌跡 (Trajectory) 的下一個項目。返回 None 以暫停。 |
| `evaluate()` | `async def evaluate(self, *args, **kwargs)` | 每隔 steps_per_eval 步呼叫一次。 |
| `setup()` | `async def setup(self)` | 在開始時呼叫一次。用於載入資料集、初始化模型。 |
| `collect_trajectory()` | `async def collect_trajectory(self, item) -> Tuple[Optional[ScoredDataItem], List[Item]]` | 單次展開 (Rollout)。或者改為覆寫 collect_trajectories。 |

## 可覆寫的方法

| 方法 | 預設行為 | 何時覆寫 |
|--------|-----------------|---------------|
| `collect_trajectories()` | 並行執行 collect_trajectory 次數達 group_size 次 | 批次生成、MCTS、耦合展開 (Coupled rollouts) |
| `wandb_log()` | 紀錄完成長度、展開表格、效能統計 | 加入自定義指標（務必呼叫 super()） |
| `config_init()` | 返回 (env_config_cls(), ServerBaseline()) | 自定義預設值 + 伺服器配置 |
| `postprocess_histories()` | 直接傳遞 | 在發送至訓練器之前的最終處理 |
| `save_checkpoint()` | 將 JSON 儲存至 checkpoint_dir | 自定義序列化 |
| `cleanup()` | 無操作 (No-op) | 在每次展開後釋放資源 |

## ScoredDataGroup 結構

```python
ScoredDataGroup = TypedDict 包含：
    tokens:             List[List[int]]       # 每次展開的 Token ID
    masks:              List[List[int]]       # -100=提示 (Prompt), token_id=補全 (Completion)
    scores:             List[float]           # 每次展開的分數
    advantages:         Optional[...]         # 每個 Token 的優勢 (Advantages)
    ref_logprobs:       Optional[...]         # 參考模型的對數機率 (Logprobs)
    messages:           Optional[...]         # OpenAI 格式的訊息
    inference_logprobs: Optional[...]         # 推論對數機率
```

## BaseEnvConfig 關鍵欄位

| 欄位 | 預設值 | 描述 |
|-------|---------|-------------|
| `group_size` | 4 | 回答會被分組以便評分 |
| `steps_per_eval` | 100 | 兩次評估之間的步數 |
| `max_token_length` | 2048 | 生成內容的最大 Token 長度 |
| `total_steps` | 1000 | 總訓練步數 |
| `use_wandb` | True | 啟用 wandb 紀錄 |
| `tokenizer_name` | DeepHermes-3 | 用於 Token 編碼的 Tokenizer |
| `ensure_scores_are_not_same` | True | 跳過分數完全相同的小組 |
| `worker_timeout` | 600 | 任務超時時間（秒） |

## 資料流

```
env_manager() → add_train_workers() → handle_env()
    → collect_trajectories() → postprocess_histories()
    → handle_send_to_api() → 訓練伺服器
```

## Atropos 環境統計數據（分析了 82 個環境）

- 95% 實作了 setup, collect_trajectories, evaluate, get_next_item
- 76% 覆寫了 wandb_log
- 54% 具有自定義配置類別
- 大多數使用 collect_trajectories（複數），而非 collect_trajectory（單數）
- 常見的獎勵模式：LLM 判定 (~40), 正則表達式提取 (~35), 程式碼執行 (~12)
