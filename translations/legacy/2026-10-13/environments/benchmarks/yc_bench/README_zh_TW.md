# YC-Bench: 長週期代理基準測試 (Long-Horizon Agent Benchmark)

[Collinear AI](https://collinear.ai/) 開發的 [YC-Bench](https://github.com/collinear-ai/yc-bench) 是一個確定性的長週期基準測試，旨在測試 LLM 代理擔任科技新創公司執行長 (CEO) 的能力。代理需管理一家虛擬公司 1 到 3 年，針對資源分配、現金流、任務管理以及四大技能領域的聲望專業化做出具備累計影響的決策。

與 TerminalBench2（評估單項編碼能力，僅有二元的成功/失敗結果）不同，YC-Bench 衡量的是 **長期戰略連貫性** —— 代理是否能保持一致的策略、處理決策的連帶影響，並在數百個回合中持續調整計畫。

## 安裝

```bash
# 安裝 yc-bench (選配依賴項)
pip install "hermes-agent[yc-bench]"

# 或從原始碼安裝
git clone https://github.com/collinear-ai/yc-bench
cd yc-bench && pip install -e .

# 驗證安裝
yc-bench --help
```

## 執行

```bash
# 從專案根目錄執行：
bash environments/benchmarks/yc_bench/run_eval.sh

# 或直接執行：
python environments/benchmarks/yc_bench/yc_bench_env.py evaluate \
    --config environments/benchmarks/yc_bench/default.yaml

# 覆蓋模型：
bash environments/benchmarks/yc_bench/run_eval.sh \
    --openai.model_name anthropic/claude-opus-4-20250514

# 快速單次預設值測試：
bash environments/benchmarks/yc_bench/run_eval.sh \
    --env.presets '["fast_test"]' --env.seeds '[1]'
```

## 運作原理

### 架構

```
HermesAgentLoop (我們的代理)
  -> 終端工具 -> 子程序("yc-bench company status") -> JSON 輸出
  -> 終端工具 -> 子程序("yc-bench task accept --task-id X") -> JSON
  -> 終端工具 -> 子程序("yc-bench sim resume") -> JSON (推進時間)
  -> ... (每次執行約 100-500 回合)
```

環境透過 `yc-bench sim init` 初始化模擬（而非 `yc-bench run`，後者會啟動 yc-bench 內建的代理迴圈）。我們的 `HermesAgentLoop` 接著透過 CLI 命令引導所有互動。

### 模擬機制

- **4 大技能領域**：研究 (research)、推論 (inference)、數據環境 (data_environment)、訓練 (training)
- **聲望系統 (Prestige system)** (1.0-10.0)：限制獲得高報酬任務的門檻
- **員工管理**：初級/中級/高級，具備特定領域的技能速率
- **產出分配**：`effective_rate = base_rate / N`，N 為每位員工處理中的活動任務數
- **財務壓力**：每月發放薪資，破產即宣告遊戲結束
- **確定性**：基於 SHA256 的隨機數生成器 (RNG) —— 相同的種子 (seed) + 預設值 (preset) = 相同的世界

### 難度預設值

| 預設值 | 員工數 | 任務數 | 重點 |
|-----------|-----------|-------|-------|
| tutorial  | 3         | 50    | 基礎迴圈機制 |
| easy      | 5         | 100   | 產出意識 (Throughput awareness) |
| **medium**| 5         | 150   | 提升聲望 + 領域專業化 |
| **hard**  | 7         | 200   | 精確的 ETA 推理 |
| nightmare | 8         | 300   | 在薪資壓力下維持完美表現 |
| fast_test | (不固定)  | (不固定) | 快速驗證 (約 50 回合) |

預設評估會執行 **fast_test + medium + hard** 各 3 個種子，共計 9 次。

### 計分方式

```
綜合得分 (composite) = 0.5 × 生存率 (survival) + 0.5 × 正規化資金 (normalised_funds)
```

- **生存率 (Survival)** (二元)：公司是否避免了破產？
- **正規化資金 (Normalised funds)** (0.0-1.0)：相對於初始 25 萬美金資本的對數刻度 (log-scale)

## 設定

`default.yaml` 中的關鍵欄位：

| 欄位 | 預設值 | 描述 |
|-------|---------|-------------|
| `presets` | `["fast_test", "medium", "hard"]` | 要評估的預設值 |
| `seeds` | `[1, 2, 3]` | 每個預設值使用的 RNG 種子 |
| `max_agent_turns` | 200 | 每次執行最多的 LLM 呼叫次數 |
| `run_timeout` | 3600 | 每次執行的實際超時時間（秒） |
| `survival_weight` | 0.5 | 綜合得分中生存率的權重 |
| `funds_weight` | 0.5 | 綜合得分中資金的權重 |
| `horizon_years` | null | 覆蓋週期（null = 從預設值自動取得） |

## 成本與時間預估

每次執行包含 100-500 回合的 LLM 呼叫。按典型 API 費率計算的單次執行約略成本：

| 預設值 | 回合數 | 時間 | 預估成本 |
|--------|-------|------|-----------|
| fast_test | 約 50 | 5-10 分鐘 | $1-5 |
| medium | 約 200 | 20-40 分鐘 | $5-15 |
| hard | 約 300 | 30-60 分鐘 | $10-25 |

完整預設評估（9 次執行）：約 3-6 小時，費用約 $50-200，視選用模型而定。

## 參考資料

- [collinear-ai/yc-bench](https://github.com/collinear-ai/yc-bench) — 官方儲存庫
- [Collinear AI](https://collinear.ai/) — yc-bench 開發公司
- [TerminalBench2](../terminalbench_2/) — 單項編碼基準測試（互補性質）
