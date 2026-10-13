# 實驗設計模式

從 Hermes 代理進行的大規模研究實驗中提取的模式與最佳實踐。這些內容涵蓋了實驗基礎設施、評估協議、監控以及失敗恢復。

---

## 實驗基礎設施

### 目錄結構

使用一致的結構組織實驗：

```
workspace/
  experiments/
    run_main.py                # 核心實驗運行腳本
    run_baselines.py           # 基準線（Baseline）比較
    run_ablation.py            # 消融研究（Ablation studies）
    strategies.py              # 方法實現
    config.yaml                # 共享配置
  results/
    <experiment_name>/
      <task_or_problem>/
        <strategy>/
          result.json          # 最終指標
          final_output.md      # 最終輸出成品
          history.json         # 完整軌跡/日誌
          pass_01/             # 每輪迭代的成品（如果是迭代式的）
            intermediate.md
  analysis/
    analyze_results.py         # 統計分析
    compute_stats.py           # 顯著性檢定
    make_charts.py             # 視覺化
  paper/
    paper.tex                  # LaTeX 源碼
    fig_*.pdf                  # 生成的圖表
```

### 腳本設計原則

**1. 增量儲存（崩潰恢復）**

每個實驗腳本都應在完成每個工作單元後儲存結果，並在重啟時跳過已完成的工作：

```python
import json, os
from pathlib import Path

def run_experiment(problems, strategies, output_dir):
    for problem in problems:
        for strategy in strategies:
            result_path = Path(output_dir) / problem["id"] / strategy / "result.json"
            if result_path.exists():
                print(f"跳過 {problem['id']}/{strategy}（已完成）")
                continue
            
            # 運行實驗
            result = execute_strategy(problem, strategy)
            
            # 立即儲存
            result_path.parent.mkdir(parents=True, exist_ok=True)
            with open(result_path, 'w') as f:
                json.dump(result, f, indent=2, ensure_ascii=False)
```

這種模式使重新運行變得安全且高效。如果程序在 47/150 個問題時崩潰，重啟將跳過前 46 個。

**2. 成品保留（Artifact Preservation）**

儲存所有中間輸出，而不僅僅是最終結果。這使得事後分析無需重新運行即可進行：

```python
def save_pass_artifacts(output_dir, pass_num, artifacts):
    """儲存迭代方法單次 pass 中的所有成品。"""
    pass_dir = Path(output_dir) / f"pass_{pass_num:02d}"
    pass_dir.mkdir(parents=True, exist_ok=True)
    
    for name, content in artifacts.items():
        with open(pass_dir / f"{name}.md", 'w') as f:
            f.write(content)
```

**3. 配置管理**

使用 YAML 配置文件以確保可重現性：

```yaml
# config.yaml
model: anthropic/claude-sonnet-4-20250514
author_temperature: 0.8
judge_temperature: 0.3
max_tokens: 4096
num_judges: 3
max_passes: 15
convergence_k: 2
```

```python
import yaml

with open("config.yaml") as f:
    config = yaml.safe_load(f)
```

**4. 關注點分離（Separation of Concerns）**

將生成、評估和視覺化保持在不同的腳本中：

| 腳本 | 用途 |
|--------|---------|
| `run_experiment.py` | 核心方法執行 |
| `run_baselines.py` | 在相同計算量下的基準線比較 |
| `run_eval.py` | 盲測評估 / 評審面板 |
| `analyze_results.py` | 統計分析 |
| `make_charts.py` | 圖表生成 |

這讓你可以重新運行評估而無需重新運行昂貴的生成過程，並且可以在不重新運行分析的情況下重新生成圖表。

---

## 評估協議

### 盲測評審面板（針對主觀任務）

在評估主觀輸出（寫作、分析、建議）時，使用盲測評審面板：

```python
import random

def run_blind_evaluation(outputs: dict, task_prompt: str, num_judges: int = 7):
    """
    對多個方法的輸出進行盲測評估。
    
    參數：
        outputs: {"method_name": "output_text", ...}
        task_prompt: 原始任務描述
        num_judges: 獨立評審評估的數量
    """
    rankings = []
    
    for judge_i in range(num_judges):
        # 隨機化每個評審的標籤和呈現順序
        methods = list(outputs.keys())
        random.shuffle(methods)
        labels = {m: chr(65 + i) for i, m in enumerate(methods)}  # A, B, C...
        
        # 以隨機標籤呈現給評審
        prompt = f"任務：{task_prompt}\n\n"
        for method in methods:
            prompt += f"--- 提案 {labels[method]} ---\n{outputs[method]}\n\n"
        prompt += "將所有提案從最好到最差進行排名。格式：RANKING: [最好], [第二], [最差]"
        
        ranking = call_judge(prompt)
        rankings.append({"labels": labels, "ranking": ranking})
    
    # 透過 Borda 計數法進行匯總
    return compute_borda(rankings)

def compute_borda(rankings, n_methods=3):
    """Borda 計數法：第 1/2/3 名分別獲得 3/2/1 分。"""
    scores = {}
    points = {0: n_methods, 1: n_methods - 1, 2: n_methods - 2}  # 根據 n_methods 調整
    
    for r in rankings:
        for position, method in enumerate(r["ranking"]):
            scores[method] = scores.get(method, 0) + points.get(position, 0)
    
    return scores
```

關鍵設計決策：
- **隨機化每個評審看到的標籤和順序**，以防止位置偏誤。
- **使用奇數個評審**（3, 5, 7）以打破平局。
- **保守的平局處理**：在平局時，原有的基準線（baseline）勝出（防止偽陽性）。
- **思維鏈（CoT）評審**在約 40% 的成本下可達到非 CoT 的品質（1 個 CoT 評審 ≈ 3 個標準評審）。

### 程式碼/客觀評估

針對具有標準答案評估的任務（程式碼、數學、事實性任務）：

```python
import subprocess

def evaluate_code(solution: str, test_cases: list, timeout: int = 30):
    """在沙盒執行環境中對程式碼解決方案運行測試用例。"""
    results = {"public": [], "private": []}
    
    for test in test_cases:
        try:
            proc = subprocess.run(
                ["python3", "-c", solution],
                input=test["input"],
                capture_output=True,
                timeout=timeout,
                text=True
            )
            actual = proc.stdout.strip()
            expected = test["expected"].strip()
            passed = actual == expected
        except subprocess.TimeoutExpired:
            passed = False
        
        category = "public" if test.get("public") else "private"
        results[category].append(passed)
    
    return {
        "public_pass_rate": sum(results["public"]) / max(len(results["public"]), 1),
        "private_pass_rate": sum(results["private"]) / max(len(results["private"]), 1),
    }
```

### 計算量匹配比較（Compute-Matched Comparison）

始終在相等的計算預算下比較方法。如果你的方法使用 N 次 API 調用，基準線也應該獲得 N 次調用：

| 方法 | 調用預算 | 分配方式 |
|--------|-----------|------------|
| 單次運行 (Single pass) | 6 次調用 | 6 次獨立生成 |
| 批判與修正 (Critique & revise) | 6 次調用 | 1 次生成 + 5 輪修正 |
| 自動推理 (Autoreason) | 6 次調用 | 1 次生成 + 1 次分析 + 4 次修正 |
| Best-of-N | 6 次調用 | 6 次獨立生成，在公開測試中選出最好的 |

### 人類評估設計

許多機器學習（ML）和自然語言處理（NLP）論文都需要人類評估，特別是對於主觀任務（文本生成、摘要、對話、創意寫作）。設計不良的人類評估是常見的退稿原因。

#### 何時需要人類評估

| 任務類型 | 是否需要？ | 備註 |
|-----------|-----------|-------|
| 文本生成（開放式） | 是 | 僅靠 LLM 評審不足以在 ACL/EMNLP 等會議中被接受 |
| 摘要 | 通常需要 | 至少針對輸出的一個子集 |
| 對話系統 | 是 | 使用者研究或標註 |
| 程式碼生成 | 否 | 測試套件是客觀的標準答案 |
| 分類 | 否 | 標準指標已足夠 |
| 任何具有主觀品質的任務 | 強烈建議 | 能顯著增強論文說服力 |

#### 標註協議設計

```
人類評估協議：
1. 定義評估維度（流暢度、相關性、事實準確性等）
2. 建立標註指南，並提供各分值級別的範例
3. 在 20-30 個範例上對 2-3 名標註員進行試驗運行
4. 計算試驗運行中的標註員間一致性——若一致性低，則修訂指南
5. 運行完整評估
6. 報告：標註員人數、一致性指標、報酬、每項花費時間
```

**評估維度**（挑選相關子集）：

| 維度 | 定義 | 量表 |
|-----------|-----------|-------|
| 流暢度 (Fluency) | 文法正確性與自然程度 | 1-5 李克特量表 (Likert) |
| 相關性 (Relevance) | 是否解決了任務？ | 1-5 李克特量表 |
| 事實準確性 | 陳述的事實是否正確？ | 二元 (Binary) 或 1-5 |
| 連貫性 (Coherence) | 邏輯流動與一致性 | 1-5 李克特量表 |
| 資訊量 (Informativeness) | 是否提供了有用的資訊？ | 1-5 李克特量表 |
| 整體偏好 | 哪個輸出更好？ | A/B/平局 (兩兩比較) |

**兩兩比較 (Pairwise comparison)**（優於絕對評分——更可靠）：
- 並排呈現兩個輸出（隨機化左右位置）。
- 詢問：「哪個更好？A / B / 平局」。
- 更具區分度，且較不易受標註員校準漂移（calibration drift）的影響。

#### 標註員間一致性 (Inter-Annotator Agreement)

務必報告一致性指標。若沒有這些指標，審稿人會認為你的標註不可靠。

```python
# Krippendorff's alpha（首選——可處理缺失數據、任何量表）
# pip install krippendorffs-alpha
import krippendorff

# 評分：列 = 標註員，行 = 項目，值 = 分數
ratings = [
    [3, 4, 1, 2, 5, None, 3],  # 標註員 1
    [3, 5, 1, 3, 5, 2, 3],     # 標註員 2
    [4, 4, 2, 2, 4, 2, None],  # 標註員 3
]
alpha = krippendorff.alpha(reliability_data=ratings, level_of_measurement="ordinal")
print(f"Krippendorff's alpha: {alpha:.3f}")
# 解讀：>0.80 優良, 0.67-0.80 可接受, <0.67 有疑問
```

```python
# Cohen's kappa（適用於恰好 2 名標註員，類別型數據）
from sklearn.metrics import cohen_kappa_score

annotator_1 = [1, 2, 3, 1, 2, 3, 2]
annotator_2 = [1, 2, 2, 1, 3, 3, 2]
kappa = cohen_kappa_score(annotator_1, annotator_2)
print(f"Cohen's kappa: {kappa:.3f}")
# 解讀：>0.80 卓越, 0.60-0.80 顯著, 0.40-0.60 中度
```

| 指標 | 何時使用 | 標註員人數 | 量表 |
|--------|------------|-----------|-------|
| Krippendorff's alpha | 預設選擇 | 任何數量 | 任何 (序位、類別、等比) |
| Cohen's kappa | 2 名標註員，類別型 | 恰好 2 名 | 類別/序位 |
| Fleiss' kappa | 3 名以上標註員，類別型 | 3 名以上 | 類別 |
| Pearson/Spearman | 連續分值 | 2 名 | 等距/等比 |

#### 群眾外包平台

| 平台 | 最適合 | 成本 | 品質 |
|----------|----------|------|---------|
| **Prolific** | 學術研究，品質較高 | $8-15/hr | 高——學術參與者群體 |
| **MTurk** | 大規模、周轉快 | $2-10/hr | 不穩定——需使用資格篩選 |
| **Surge AI** | NLP 特定標註 | 高價 | 高——受過培訓的標註員 |
| **專家標註員** | 特定領域（醫療、法律） | 最高 | 最高——但進度慢 |

**倫理要求**：
- 報告報酬率（必須至少達到當地最低工資）。
- 若相關，描述標註員的人口統計資訊。
- 若所屬機構要求，取得 IRB/倫理委員會批准。
- ACL 會議明確要求提供報酬證明文件。

#### 論文中應報告的內容

```
人類評估章節檢查清單：
- [ ] 標註員人數
- [ ] 標註員資格 / 招募方法
- [ ] 評估的項目數量
- [ ] 各評估維度的定義
- [ ] 使用的量表（李克特、兩兩比較、二元）
- [ ] 標註員間一致性（Krippendorff's alpha 或 Cohen's kappa）
- [ ] 報酬率
- [ ] 標註每個項目所需時間
- [ ] 標註員是否看到模型身份（應為盲測）
- [ ] 呈現順序的隨機化
```

---

## 統計分析

### 必要檢定

| 檢定 | 何時使用 | Python 實作 |
|------|------------|--------|
| McNemar 檢定 | 在相同問題上比較兩種方法 | 小樣本使用 `scipy.stats.binomtest` |
| 雙比例 z 檢定 | 比較成功率 | 自訂或使用 `statsmodels` |
| Fisher 精確檢定 | 小樣本的兩兩比較 | `scipy.stats.fisher_exact` |
| 自助法 (Bootstrap) CI | 任何指標的信賴區間 | 自訂 Bootstrap 程式碼 |
| Cohen's h | 比例的效應值 (Effect size) | 手動計算 |

### 標準分析腳本

```python
import numpy as np
from scipy import stats
from pathlib import Path
import json

def load_all_results(results_dir):
    """將所有結果加載到結構化格式中。"""
    results = {}
    for result_file in Path(results_dir).rglob("result.json"):
        parts = result_file.relative_to(results_dir).parts
        if len(parts) >= 3:
            experiment, task, strategy = parts[0], parts[1], parts[2]
            data = json.loads(result_file.read_text())
            results.setdefault(experiment, {}).setdefault(strategy, {})[task] = data
    return results

def pairwise_mcnemar(method_a_results, method_b_results):
    """針對配對二元結果的 McNemar 檢定。"""
    a_win_b_lose = sum(1 for a, b in zip(method_a_results, method_b_results) if a and not b)
    b_win_a_lose = sum(1 for a, b in zip(method_a_results, method_b_results) if b and not a)
    
    n = a_win_b_lose + b_win_a_lose
    if n < 25:
        # 針對小樣本使用精確二項檢定
        result = stats.binomtest(a_win_b_lose, n, 0.5)
        p_value = result.pvalue
    else:
        # 卡方近似
        chi2 = (abs(a_win_b_lose - b_win_a_lose) - 1)**2 / (a_win_b_lose + b_win_a_lose)
        p_value = 1 - stats.chi2.cdf(chi2, df=1)
    
    return {
        "a_wins": a_win_b_lose,
        "b_wins": b_win_a_lose,
        "n_discordant": n,
        "p_value": p_value,
        "significant": p_value < 0.05
    }

def bootstrap_ci(data, n_bootstrap=10000, ci=0.95):
    """均值的自助法 (Bootstrap) 信賴區間。"""
    means = []
    for _ in range(n_bootstrap):
        sample = np.random.choice(data, size=len(data), replace=True)
        means.append(np.mean(sample))
    lower = np.percentile(means, (1 - ci) / 2 * 100)
    upper = np.percentile(means, (1 + ci) / 2 * 100)
    return {"mean": np.mean(data), "ci_lower": lower, "ci_upper": upper}

def cohens_h(p1, p2):
    """兩個比例的 Cohen's h 效應值。"""
    return 2 * np.arcsin(np.sqrt(p1)) - 2 * np.arcsin(np.sqrt(p2))
```

### 報告標準

在論文中始終包含：
- **樣本大小**：n=X 個問題/任務。
- **運行次數**：如果適用，報告 K 次獨立運行。
- **誤差線 (Error bars)**：註明是標準差 (SD) 還是標準誤 (SE)。
- **信賴區間 (Confidence intervals)**：針對關鍵結果提供 95% CI。
- **顯著性檢定**：針對關鍵比較提供 p 值。
- **效應值 (Effect sizes)**：提供 Cohen's d 或 h 以展示實際顯著性。

---

## 監控 (Cron 模式)

### Cron 提示詞模板

對於每個實驗批次，建立一個監控提示詞：

```
檢查 [EXPERIMENT_NAME] 實驗的狀態：

1. 程序檢查：ps aux | grep [PROCESS_PATTERN]
2. 日誌檢查：tail -30 [LOG_FILE]
3. 結果檢查：ls [RESULT_DIR]/eval/ （或適當的結果路徑）
4. 如果結果可用：
   - 讀取結果 JSON 文件
   - 在表格中報告指標（Borda 分數、準確性等）
   - 計算方法間的關鍵比較
5. 如果此批次中的所有實驗均已完成：
   - git add -A && git commit -m "[COMMIT_MESSAGE]" && git push
   - 報告最終摘要
6. 關鍵問題：[具體的分析問題]

如果自上次檢查以來沒有任何變化，請回應 [SILENT]。
```

### 監控最佳實踐

1. **先檢查程序**——如果實驗仍在運行且結果不完整，不要讀取結果。
2. **讀取日誌末尾**——尋找錯誤、進度指示、完成訊息。
3. **統計完成與預期的數量**——「已完成 45/150 個問題」比「存在一些結果」更有用。
4. **以結構化表格報告**——始終在表格中包含關鍵指標。
5. **回答關鍵問題**——每個實驗完成後應有一個具體的分析問題需要回答。
6. **無消息時回應 [SILENT]**——當沒有任何變化時抑制通知。
7. **完成後提交**——每個完成的批次都應配上描述性訊息進行提交。

### 監控報告範例

```
## 程式碼實驗 (Haiku 3.5) - 已完成

| 策略 | 通過率 (150 個問題) | 對比單次運行 |
|----------|------------------------|-----------|
| single_pass | 38.0% | — |
| critique_revise | 35.2% | -2.8pp |
| **autoreason** | **40.0%** | **+2.0pp** |
| best_of_6 | 31.0% | -7.0pp |

關鍵發現：Autoreason 比單次運行提高了 2 個百分點，而 
Best-of-6 則因單一公開測試選擇問題而崩潰。

已提交：`git commit -m "新增 Haiku 程式碼結果 (150 個問題, 4 種策略)"`
下一步：對這些結果進行顯著性檢定。
```

---

## 失敗恢復

### 常見失敗與恢復方式

| 失敗類型 | 偵測方式 | 恢復方式 |
|---------|-----------|----------|
| **API 額度耗盡** | 日誌中的 402 錯誤，結果不完整 | 儲值額度，重新運行（自動跳過已完成部分） |
| **速率限制 (Rate limiting)** | 429 錯誤，進度緩慢 | 增加帶有指數退避的重試邏輯 |
| **程序崩潰** | PID 消失，日誌在問題中途停止 | 重新運行腳本（從最後一個檢查點恢復） |
| **錯誤的模型 ID** | 模型未找到錯誤 | 修正 ID（例如 `claude-opus-4-6` 而非 `claude-opus-4.6`） |
| **平行化導致的減速** | 每個實驗耗時變為 2 倍 | 將平行實驗減少到最多 2-3 個 |
| **安全性掃描阻攔** | 指令被安全機制攔截 | 使用 `execute_code` 取代管道化的 `terminal` 指令 |
| **委託失敗** | `delegate_task` 回傳錯誤 | 退而求其次直接執行工作 |
| **困難問題超時** | 程序卡住，日誌無進度 | 強制結束，跳過該問題，在結果中註記 |
| **資料集路徑不匹配** | 檔案未找到錯誤 | 在啟動前驗證路徑 |

### 重試命名慣例

重新運行失敗的實驗時，使用後綴追蹤輪次：

```
logs/experiment_haiku_0_50.log       # 第 1 輪
logs/experiment_haiku_0_50_r2.log    # 第 2 輪（額度耗盡後）
logs/experiment_haiku_0_50_r3.log    # 第 3 輪（修正 bug 後）
```

### 啟動前檢查清單

在啟動任何實驗批次前：

```
啟動前檢查：
- [ ] API 額度足以支付估計的調用量
- [ ] 模型 ID 正確（先用 1 個問題測試）
- [ ] 輸出目錄存在且可寫入
- [ ] 恢復邏輯有效（重新運行不會覆蓋現有結果）
- [ ] 日誌文件路徑唯一（不會覆蓋之前的日誌）
- [ ] 資料集/任務文件可存取
- [ ] 配置符合預期的實驗
```

---

## 任務/基準線設計

### 開放式任務（主觀評估）

設計目標明確但品質主觀的任務：

```markdown
# 任務：[標題]

## 背景
[具體情境及細節：公司規模、約束條件、時間表]

## 交付成果
[要求的精確格式與結構]

## 要求
- [具體、可衡量的要求]
- [不要含糊其詞——「內容全面」很糟糕，「必須包含 6 個章節」很好]
```

### 受限任務（用於測試範疇效應）

受限任務測試方法是否尊重範疇邊界。設計時包含：

- **固定事實**：「僅使用這 N 個數據點，不要添加其他任何內容」。
- **固定交付物**：特定格式（提案、檢討報告、備忘錄——而非「改進這個」）。
- **固定結構**：「按此順序排列這些章節，不要增加/刪除」。
- **固定修改項**：「精確處理這 N 個要點，不要涉及其他內容」。

**不要使用字數作為範疇約束。** 字數限制會導致偽收斂——輸出因長度而非品質被拒絕。應進一步約束範疇（包含什麼）而非長度。

### 範例：好的約束 vs 壞的約束

| 壞的約束 | 原因 | 好的約束 |
|---------------|-----|-----------------|
| 「最多 500 字」 | 評審會因長度拒絕 | 「精確包含 4 個章節，每個章節有 3 個編號項目」 |
| 「內容簡潔」 | 太過含糊 | 「每個禁令必須引用一個特定的基本事實」 |
| 「改進這個」 | 範疇無邊界 | 「按照此精確結構撰寫一份 600 字的事故檢討報告」 |
| 「讓它更好」 | 無明確標準 | 「精確解決這 3 個評審關注的問題」 |

---

## 視覺化最佳實踐

### 環境設定：SciencePlots + matplotlib

安裝 SciencePlots 以獲得出版品質的預設設定：

```bash
pip install SciencePlots matplotlib numpy
```

**選項 A：SciencePlots 樣式**（推薦——自動處理大多數預設）：

```python
import matplotlib.pyplot as plt
import scienceplots  # 註冊樣式

# 選擇一種樣式：
# 'science'        — 清潔的襯線字體，適用於大多數場合
# 'science+ieee'   — IEEE 風格（適合雙欄論文）
# 'science+nature' — Nature 風格
# 如果生成圖表的機器未安裝 LaTeX，請添加 'no-latex'

with plt.style.context(['science', 'no-latex']):
    fig, ax = plt.subplots(figsize=(3.5, 2.5))  # 單欄寬度
    # ... 繪圖 ...
    fig.savefig('paper/fig_results.pdf', bbox_inches='tight')
```

**選項 B：手動 rcParams**（當你需要完全控制時）：

```python
import matplotlib.pyplot as plt

plt.rcParams.update({
    'font.size': 10,
    'font.family': 'serif',
    'axes.labelsize': 11,
    'axes.titlesize': 11,
    'xtick.labelsize': 9,
    'ytick.labelsize': 9,
    'legend.fontsize': 9,
    'figure.figsize': (3.5, 2.5),    # 單欄預設
    'figure.dpi': 300,
    'savefig.dpi': 300,
    'savefig.bbox': 'tight',
    'savefig.pad_inches': 0.05,
    'axes.linewidth': 0.8,
    'lines.linewidth': 1.5,
    'lines.markersize': 5,
    'axes.grid': True,
    'grid.alpha': 0.3,
    'grid.linewidth': 0.5,
})
```

### 標準圖表尺寸（雙欄格式）

| 使用場景 | figsize | 備註 |
|----------|---------|-------|
| 單欄 (Single column) | `(3.5, 2.5)` | 適合雙欄版面中的一欄 |
| 雙欄 (Double column) | `(7.0, 3.0)` | 跨越整個頁面寬度 |
| 正方形（熱圖、混淆矩陣） | `(3.5, 3.5)` | 單欄 |
| 高型單欄（多行數據） | `(3.5, 5.0)` | 謹慎使用 |

### 色盲友善調色盤 (Okabe-Ito)

在所有論文圖表中使用此調色盤。它能被患有常見色覺障礙的人士分辨：

```python
COLORS = {
    'blue':    '#0072B2',
    'orange':  '#E69F00',
    'green':   '#009E73',
    'red':     '#D55E00',
    'purple':  '#CC79A7',
    'cyan':    '#56B4E9',
    'yellow':  '#F0E442',
    'black':   '#000000',
}

# 作為循環使用的列表：
COLOR_CYCLE = ['#0072B2', '#D55E00', '#009E73', '#E69F00', '#CC79A7', '#56B4E9']
```

同時透過**標記 (marker) 和線條樣式 (linestyle)** 而不僅僅是顏色來區分線條：
```python
STYLES = [
    {'color': '#0072B2', 'marker': 'o', 'linestyle': '-'},
    {'color': '#D55E00', 'marker': 's', 'linestyle': '--'},
    {'color': '#009E73', 'marker': '^', 'linestyle': '-.'},
    {'color': '#E69F00', 'marker': 'D', 'linestyle': ':'},
]
```

### 完整範例：方法比較長條圖

```python
import matplotlib.pyplot as plt
import numpy as np

try:
    import scienceplots
    style = ['science', 'no-latex']
except ImportError:
    style = 'default'

with plt.style.context(style):
    methods = ['Single Pass', 'Critique+Revise', 'Best-of-N', 'Ours']
    scores = [73.2, 74.1, 68.5, 77.0]
    errors = [2.1, 1.8, 3.2, 1.5]
    colors = ['#56B4E9', '#E69F00', '#CC79A7', '#0072B2']
    
    fig, ax = plt.subplots(figsize=(3.5, 2.5))
    bars = ax.bar(methods, scores, yerr=errors, capsize=3,
                  color=colors, edgecolor='black', linewidth=0.5)
    
    # 突出顯示 "Ours"
    bars[-1].set_edgecolor('#0072B2')
    bars[-1].set_linewidth(1.5)
    
    ax.set_ylabel('通過率 (%)')
    ax.set_ylim(60, 85)
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    
    fig.savefig('paper/fig_comparison.pdf', bbox_inches='tight')
```

### 完整範例：收斂/軌跡折線圖

```python
with plt.style.context(style):
    fig, ax = plt.subplots(figsize=(3.5, 2.5))
    
    passes = np.arange(1, 16)
    ours = [65, 72, 78, 82, 85, 87, 88, 89, 89.5, 90, 90, 90, 90, 90, 90]
    baseline = [65, 68, 70, 71, 69, 67, 66, 65, 64, 63, 62, 61, 60, 59, 58]
    
    ax.plot(passes, ours, **STYLES[0], label='Ours', markersize=4)
    ax.plot(passes, baseline, **STYLES[1], label='Critique+Revise', markersize=4)
    
    # 標記收斂點
    ax.axvline(x=10, color='gray', linestyle=':', alpha=0.5, linewidth=0.8)
    ax.annotate('收斂', xy=(10, 90), fontsize=8, ha='center',
                xytext=(10, 93), arrowprops=dict(arrowstyle='->', color='gray'))
    
    ax.set_xlabel('迭代次數')
    ax.set_ylabel('品質評分')
    ax.legend(loc='lower right')
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    
    fig.savefig('paper/fig_trajectory.pdf', bbox_inches='tight')
```

### 輸出規則

- **始終儲存為 PDF**：`fig.savefig('fig.pdf')`——向量圖形，在任何縮放倍率下都保持清晰。
- **論文圖表切勿儲存為 PNG**——點陣式 PNG 在列印或縮放時會顯得模糊。
- **例外**：截圖、相片或像素藝術視覺化→ 使用 600 DPI 的 PNG。
- **驗證灰階效果**：列印成灰階 PDF，檢查所有資訊是否仍然清晰可見。

### 常見比較的圖表類型

| 比較類型 | 圖表 | 備註 |
|----------------|-------|-------|
| 方法對比方法 | 分組長條圖 | 需包含誤差線 |
| 跨模型大小 | 帶有 CI 區間的折線圖 | 模型大小軸使用對數刻度 |
| 消融研究 | 堆疊/分組長條圖 | 突出顯示移除的組件 |
| 軌跡/收斂 | 跨迭代次數的折線圖 | 顯示每輪迭代的勝出者 |
| 各項任務分解 | 熱圖或分組長條圖 | 顯示不同任務間的變異量 |
