# 使用模式 —— 測試環境與評估模型

## 模式 1：測試您的環境是否運作（process 模式）

使用 `process` 模式來驗證您的環境是否能端到端運行，然後再行提交。這會生成軌跡 (Trajectories)，而不需要 Atropos 訓練伺服器。

**執行前：** 請詢問使用者他們的推論設置（請參閱 SKILL.md 的 "Inference Setup" 章節）。將下方的 `<BASE_URL>`、`<MODEL>` 和 `<SERVER_TYPE>` 替換為他們選擇的值。

### 步驟 1：執行 1 條軌跡

```bash
cd ~/.hermes/hermes-agent
source venv/bin/activate

python environments/your_env.py process \
  --env.total_steps 1 \
  --env.group_size 1 \
  --env.use_wandb false \
  --env.data_path_to_save_groups /tmp/test_output.jsonl \
  --openai.base_url "<BASE_URL>" \
  --openai.model_name "<MODEL>" \
  --openai.server_type <SERVER_TYPE> \
  --openai.health_check false
```

### 步驟 2：驗證輸出

```python
import json
for line in open("/tmp/test_output.jsonl"):
    data = json.loads(line)
    print(f"分數 (Scores): {data.get('scores', [])}")
    print(f"Token 序列數: {len(data.get('tokens', []))}")
    # 檢查訊息是否包含工具呼叫
    for msg_list in data.get("messages", []):
        roles = [m.get("role") for m in msg_list]
        print(f"角色 (Roles): {roles}")
        for m in reversed(msg_list):
            if m.get("role") == "assistant" and m.get("content"):
                print(f"回答 (Response): {m['content'][:200]}...")
                break
```

### 檢查重點：
- **分數不全為 0.0** —— 若全為 0.0，則說明 compute_reward 已損壞
- **分數在 [0, 1] 範圍內** —— 不應為負數或大於 1
- **訊息中包含 "tool" 角色項目** —— 代理人使用了工具
- **Token 序列不為空**
- **在 .jsonl 檔案旁生成了 HTML 視覺化圖表**

### 常見失敗原因：
- `'AgentResult' object has no attribute 'X'` —— 存取了不存在的欄位。請參閱 agentresult-fields_zh_TW.md。
- 分數始終為 0.0 —— 獎勵函數在背景出錯
- 分數始終為 1.0 —— 驗證過於寬鬆或未運行


## 模式 2：評估模型（evaluate 模式）

使用 `evaluate` 模式，在您環境的評估分割 (Eval split) 上對模型進行基準測試。這會針對每個評估項目執行完整的工具代理人迴圈。

### 步驟 1：執行評估

```bash
python environments/your_env.py evaluate \
  --env.eval_size 20 \
  --env.use_wandb false \
  --env.data_dir_to_save_evals /tmp/eval_results \
  --openai.base_url "<BASE_URL>" \
  --openai.model_name "<MODEL>" \
  --openai.server_type <SERVER_TYPE> \
  --openai.health_check false
```

### 步驟 2：讀取結果

標準輸出 (Stdout) 會顯示與 lighteval 相容的表格：

```
評估結果：your-env_eval
|指標 (Metric)   |  數值|
|平均正確性      | 0.850 |
|平均獎勵        | 0.920 |
|平均工具呼叫次數 | 4.300 |
|項目數量 (n)    | 20    |
評估完成，耗時 367 秒
```

JSON 結果儲存於評估目錄中：

```python
import json
data = json.load(open("/tmp/eval_results/metrics.json"))
for metric, value in data["results"]["all"].items():
    print(f"{metric}: {value}")
```

### 步驟 3：比較模型

使用不同的模型執行 evaluate 並比較 metrics.json 檔案。

### 檢查重點：
- **"data_dir_to_save_evals is not set"** —— 您忘記設置該標誌，結果將不會被儲存
- **工具使用率 = 0** —— evaluate() 正在使用 chat_completion 而非 HermesAgentLoop
- **所有分數均相同** —— 判定器 (Judge) 失敗，回退至啟發式方法
- **速度非常慢** —— 每個項目都會執行完整的代理人迴圈（約 30-90 秒）。請使用 `--env.eval_size 5` 進行快速檢查。


## 模式 3：生成訓練資料（process 模式，較大規模）

為離線訓練或分析生成軌跡資料：

```bash
python environments/your_env.py process \
  --env.total_steps 50 \
  --env.group_size 4 \
  --env.use_wandb false \
  --env.data_path_to_save_groups data/trajectories.jsonl \
  --openai.base_url "<BASE_URL>" \
  --openai.model_name "<MODEL>" \
  --openai.server_type <SERVER_TYPE> \
  --openai.health_check false
```

### 分析分布：

```python
import json
scores = []
for line in open("data/trajectories.jsonl"):
    data = json.loads(line)
    scores.extend(data.get("scores", []))

print(f"總數: {len(scores)}, 平均值: {sum(scores)/len(scores):.3f}")
for bucket in [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]:
    count = sum(1 for s in scores if abs(s - bucket) < 0.1)
    print(f"  {bucket:.1f}: {'█' * count} ({count})")
```

### 檢查重點：
- **分數分布具有變異性** —— 強化學習 (RL) 需要分數變異性。完全相同的分數毫無用處。


## 模式 4：完整強化學習 (RL) 訓練（serve 模式）

針對使用 Atropos 進行的實際 RL 訓練：

```bash
# 終端機 1：啟動 Atropos API 伺服器
run-api

# 終端機 2：啟動您的環境
python environments/your_env.py serve \
  --config environments/your_env/default.yaml
```

使用 VLLM 進行第 2 階段：

```bash
# 終端機 1：VLLM 伺服器
python -m vllm.entrypoints.openai.api_server --model your-model --port 8000

# 終端機 2：Atropos API
run-api

# 終端機 3：環境
python environments/your_env.py serve \
  --openai.base_url http://localhost:8000/v1 \
  --openai.model_name your-model \
  --openai.server_type vllm
```


## 模式 5：快速冒煙測試 (Smoke Test)

在花錢進行 API 呼叫之前，先驗證匯入與配置：

```python
from environments.your_env import YourEnv
print(f"名稱: {YourEnv.name}")
cfg, servers = YourEnv.config_init()
print(f"工具集: {cfg.enabled_toolsets}")
print(f"伺服器: {servers[0].model_name}")
print("所有匯入均正常")
```


## 時間預期

| 模式 | 項目數量 | 每個項目的時間 | 總計 |
|------|-------|--------------|-------|
| process (1 個項目) | 1 | 30-90s | ~1 分鐘 |
| evaluate (5 個項目) | 5 | 30-90s | ~5 分鐘 |
| evaluate (20 個項目) | 20 | 30-90s | ~15-30 分鐘 |
| process (50 個項目) | 50 | 30-90s | ~30-75 分鐘 |

時間估算係針對使用 Claude Sonnet 等級模型的雲端 API。本地模型可能會依硬體效能而更快或更慢。
