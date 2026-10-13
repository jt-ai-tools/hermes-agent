---
name: research-paper-writing
title: 研究論文寫作流程 (Research Paper Writing Pipeline)
description: 機器學習/人工智慧研究論文寫作的端到端流程 — 從實驗設計到分析、起草、修訂與提交。涵蓋 NeurIPS、ICML、ICLR、ACL、AAAI、COLM。整合了自動化實驗監控、統計分析、迭代寫作與引用驗證。
version: 1.1.0
author: Orchestra Research
license: MIT
dependencies: [semanticscholar, arxiv, habanero, requests, scipy, numpy, matplotlib, SciencePlots]
platforms: [linux, macos]
metadata:
  hermes:
    tags: [Research, Paper Writing, Experiments, ML, AI, NeurIPS, ICML, ICLR, ACL, AAAI, COLM, LaTeX, Citations, Statistical Analysis]
    category: research
    related_skills: [arxiv, ml-paper-writing, subagent-driven-development, plan]
    requires_toolsets: [terminal, files]

---

# 研究論文寫作流程 (Research Paper Writing Pipeline)

針對 **NeurIPS、ICML、ICLR、ACL、AAAI 及 COLM** 等頂級會議，產出達到出版水準的 ML/AI 研究論文之端到端流程。本技能涵蓋完整的研究生命週期：實驗設計、執行、監控、分析、論文寫作、審查、修訂及提交。

這**不是一個線性的流程** — 它是個迭代的迴圈。結果會觸發新的實驗。審查會觸發新的分析。代理 (agent) 必須處理這些反饋迴圈。

```
┌─────────────────────────────────────────────────────────────┐
│                    RESEARCH PAPER PIPELINE                  │
│                                                             │
│  階段 0: 專案設置 ──► 階段 1: 文獻回顧      │
│       │                          │                          │
│       ▼                          ▼                          │
│  階段 2: 實驗設計        階段 5: 論文起草 ◄──┐      │
│       │                          ▼                   │      │
│       ▼                    階段 6: 自我審查      │      │
│  階段 3: 執行與監控             與修訂 ──────────┘      │
│       │                          │                          │
│       ▼                    階段 7: 提交               │
│  階段 4: 分析 ─────► (回饋至階段 2 或 5)     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 何時使用此技能

當遇到以下情況時請使用此技能：
- **開始撰寫新的研究論文**，基於現有程式碼庫或想法
- **設計與執行實驗**以支持論文的聲明
- **撰寫或修訂**研究論文的任何章節
- **準備提交**至特定的會議或工作坊
- **回應審查意見**，補充額外實驗或修訂
- **轉換**不同會議格式間的論文
- **撰寫非實證類論文** — 理論、綜述、基準測試 (benchmark) 或立場論文（參見 [實證 ML 以外的論文類型](#paper-types-beyond-empirical-ml)）
- **設計人類評估** (human evaluations)，針對 NLP、HCI 或對齊 (alignment) 研究
- **準備接受後的交付物** — 海報、演講、程式碼發布

## 核心理念

1. **主動出擊。** 交付完整的草稿，而不是提出問題。科學家們很忙 — 產出具體的東西讓他們能夠做出反應，然後再進行迭代。
2. **絕不幻覺 (hallucinate) 引用。** AI 生成的引用約有 40% 的錯誤率。永遠透過程式化方式獲取。將無法驗證的引用標記為 `[CITATION NEEDED]`。
3. **論文是一個故事，而不是實驗的集合。** 每篇論文都需要用一句話清楚陳述一個主要貢獻。如果你做不到，代表論文還沒準備好。
4. **實驗是為了支持聲明。** 每個實驗都必須明確說明它支持哪個聲明。絕不執行與論文敘事無關的實驗。
5. **及早提交 (commit)，頻繁提交。** 每個完成的實驗批次、每次論文草稿更新 — 都要帶有具描述性的提交訊息。Git 日誌就是實驗的歷史記錄。

### 主動性與協作

**預設：主動出擊。先寫草稿，然後帶著草稿提問。**

| 信心水準 | 行動 |
|-----------------|--------|
| **高** (清晰的儲存庫、明顯的貢獻) | 撰寫完整草稿，交付，根據反饋進行迭代 |
| **中** (有些模糊不清) | 撰寫標有不確定性的草稿，繼續進行 |
| **低** (重大的未知數) | 透過 `clarify` 詢問 1-2 個針對性的問題，然後起草 |

| 章節 | 是否自主起草？ | 隨草稿標記 |
|---------|-------------------|-----------------|
| 摘要 (Abstract) | 是 | "將貢獻定調為 X — 若有需要請調整" |
| 簡介 (Introduction) | 是 | "強調了問題 Y — 若有誤請指正" |
| 方法 (Methods) | 是 | "包含了細節 A, B, C — 請補充遺漏的部分" |
| 實驗 (Experiments) | 是 | "強調了結果 1, 2, 3 — 若有需要請重新排序" |
| 相關工作 (Related Work) | 是 | "引用了論文 X, Y, Z — 請補充我遺漏的任何文獻" |

**僅在以下情況中斷以等待輸入**：目標發表場合不明確、存在多個矛盾的框架、結果似乎不完整、明確要求先進行審查。

---

## 階段 0: 專案設置 (Project Setup)

**目標**：建立工作空間、理解現有工作、確定貢獻。

### 步驟 0.1: 探索儲存庫

```bash
# 理解專案結構
ls -la
find . -name "*.py" | head -30
find . -name "*.md" -o -name "*.txt" | xargs grep -l -i "result\|conclusion\|finding"
```

尋找：
- `README.md` — 專案概述與聲明
- `results/`、`outputs/`、`experiments/` — 現有的發現
- `configs/` — 實驗設定
- `.bib` 檔案 — 現有的引用
- 草稿文件或筆記

### 步驟 0.2: 整理工作空間

建立一致的工作空間結構：

```
workspace/
  paper/               # LaTeX 源碼、圖表、編譯後的 PDFs
  experiments/         # 實驗執行腳本
  code/                # 核心方法實作
  results/             # 原始實驗結果 (自動生成)
  tasks/               # 任務/基準測試定義
  human_eval/          # 人類評估材料 (若有需要)
```

### 步驟 0.3: 設置版本控制

```bash
git init  # 若尚未初始化
git remote add origin <repo-url>
git checkout -b paper-draft  # 或 main
```

**Git 規範**：每個完成的實驗批次都要帶有具描述性的訊息進行提交。範例：
```
Add Monte Carlo constrained results (5 runs, Sonnet 4.6, policy memo task)
Add Haiku baseline comparison: autoreason vs refinement baselines at cheap model tier
```

### 步驟 0.4: 確定貢獻

在撰寫任何內容之前，請清晰陳述：
- **內容 (The What)**：這篇論文貢獻的單一事項是什麼？
- **原因 (The Why)**：有什麼證據支持它？
- **意義 (The So What)**：讀者為什麼要在意？

> 向科學家提議："根據我的理解，主要的貢獻是：[一句話]。關鍵結果顯示 [Y]。這是您想要的定調嗎？"

### 步驟 0.5: 建立 TODO 列表

使用 `todo` 工具建立結構化的專案計劃：

```
Research Paper TODO:
- [ ] 定義一句話的貢獻
- [ ] 文獻回顧 (相關工作 + 基準方法)
- [ ] 設計核心實驗
- [ ] 執行實驗
- [ ] 分析結果
- [ ] 撰寫初稿
- [ ] 自我審查 (模擬審查員)
- [ ] 根據審查進行修訂
- [ ] 提交準備
```

在整個專案過程中更新此列表。它作為跨工作階段的持久狀態。

### 步驟 0.6: 估算運算預算

在執行實驗之前，估算總成本與時間：

```
Compute Budget Checklist:
- [ ] API 成本：(每標記模型價格) × (預估每輪執行的標記數) × (執行輪數)
- [ ] GPU 時數：(每個實驗的時間) × (實驗數量) × (種子數量)
- [ ] 人類評估成本：(標註者人數) × (小時) × (時薪)
- [ ] 總預算上限與預備金 (為重新執行預留 30-50%)
```

在實驗執行時追蹤實際支出：
```python
# 簡單的成本追蹤模式
import json, os
from datetime import datetime

COST_LOG = "results/cost_log.jsonl"

def log_cost(experiment: str, model: str, input_tokens: int, output_tokens: int, cost_usd: float):
    entry = {
        "timestamp": datetime.now().isoformat(),
        "experiment": experiment,
        "model": model,
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "cost_usd": cost_usd,
    }
    with open(COST_LOG, "a") as f:
        f.write(json.dumps(entry) + "\n")
```

**當預算緊張時**：在投入完整的大規模測試前，先執行先導實驗 (pilot experiments) (1-2 個種子，部分任務)。使用較便宜的模型偵錯流程，然後切換到目標模型進行最終執行。

### 步驟 0.7: 多作者協調 (Multi-Author Coordination)

大多數論文有 3-10 位作者。儘早建立工作流程：

| 工作流程 | 工具 | 何時使用 |
|----------|------|-------------|
| **Overleaf** | 基於瀏覽器 | 多位作者同時編輯，無 git 經驗 |
| **Git + LaTeX** | 搭配 `.gitignore` 的 `git` | 技術團隊，需要基於分支的審查 |
| **Overleaf + Git 同步** | Overleaf 進階版 | 兩者兼得 — 具備版本歷史的即時協作 |

**章節所有權**：為每個章節指派一名主要作者。其他人可以評論但不要直接編輯。防止合併衝突與風格不一致。

```
Author Coordination Checklist:
- [ ] 同意章節所有權 (誰寫什麼)
- [ ] 設置共享工作空間 (Overleaf 或 git 儲存庫)
- [ ] 建立符號慣例 (在任何人開始寫作前)
- [ ] 安排內部審查輪次 (不只是在最後)
- [ ] 指定一人進行最終格式檢查
- [ ] 在建立圖表前同意其風格 (顏色、字體、大小)
```

**儘早達成共識的 LaTeX 慣例**：
- 使用 `\method{}` 巨集以保持一致的方法命名
- 引用風格：`\citet{}` 與 `\citep{}` 的用法
- 數學符號：向量用小寫粗體，矩陣用大寫粗體等
- 英式與美式拼寫

---

## 階段 1: 文獻回顧 (Literature Review)

**目標**：尋找相關工作、確定基準方法、收集引用。

### 步驟 1.1: 確定種子論文 (Seed Papers)

從程式碼庫中已經引用的論文開始：

```bash
# 透過終端機：
grep -r "arxiv\|doi\|cite" --include="*.md" --include="*.bib" --include="*.py"
find . -name "*.bib"
```

### 步驟 1.2: 搜尋相關工作

**載入 `arxiv` 技能**以進行結構化的論文探索：`skill_view("arxiv")`。它提供 arXiv REST API 搜尋、Semantic Scholar 引用圖、作者簡介及 BibTeX 生成。

使用 `web_search` 進行廣泛探索，使用 `web_extract` 獲取特定論文：

```
# 透過 web_search：
web_search("[main technique] + [application domain] site:arxiv.org")
web_search("[baseline method] comparison ICML NeurIPS 2024")

# 透過 web_extract (針對特定論文)：
web_extract("https://arxiv.org/abs/2303.17651")
```

可以嘗試的其他搜尋查詢：

```
Search queries:
- "[main technique] + [application domain]"
- "[baseline method] comparison"
- "[problem name] state-of-the-art"
- 現有引用中的作者姓名
```

**推薦**：安裝 **Exa MCP** 進行即時學術搜尋：
```bash
claude mcp add exa -- npx -y mcp-remote "https://mcp.exa.ai/mcp"
```

### 步驟 1.2b: 深化搜尋 (先廣度後深度)

平面式搜尋 (一輪查詢) 通常會漏掉重要的相關工作。使用受深度研究流程啟發的「先廣度後深度」迭代模式：

```
Iterative Literature Search:

第一輪 (廣度)：4-6 個平行查詢，涵蓋不同角度
  - "[method] + [domain]"
  - "[problem name] state-of-the-art 2024 2025"
  - "[baseline method] comparison"
  - "[alternative approach] vs [your approach]"
  → 收集論文，提取關鍵概念與術語

第二輪 (深度)：根據第一輪的學習生成後續查詢
  - 在第一輪論文中發現的新術語
  - 被第一輪最相關結果所引用的論文
  - 需要調查的矛盾發現
  → 收集論文，識別剩餘的差距

第三輪 (針對性)：填補特定差距
  - 識別出第一、二輪中缺失的基準方法
  - 同期工作 (過去 6 個月，針對相同問題)
  - 關鍵的負面結果或失敗的方法
  → 當新查詢返回的多半是您已看過的論文時停止
```

**何時停止**：如果一輪返回的論文中超過 80% 已在您的收藏中，代表搜尋已飽和。通常 2-3 輪就足夠了。對於綜述論文，預計需要 4-5 輪。

**針對代理型工作流程**：透過 `delegate_task` 平行委派每一輪的查詢。收集結果、去重，然後從合併的學習中生成下一輪的查詢。

### 步驟 1.3: 驗證每項引用

**絕不從記憶中生成 BibTeX。務必透過程式化方式獲取。**

針對每項引用，遵循強制性的 5 步驟流程：

```
Citation Verification (每項引用皆為強制性)：
1. 搜尋 (SEARCH) → 使用特定關鍵字查詢 Semantic Scholar 或 Exa MCP
2. 驗證 (VERIFY) → 確認論文存在於 2 個以上的來源 (Semantic Scholar + arXiv/CrossRef)
3. 獲取 (RETRIEVE) → 透過 DOI 內容協商獲取 BibTeX (程式化獲取，非憑記憶)
4. 確效 (VALIDATE) → 確認您所引用的聲明確實出現在論文中
5. 新增 (ADD) → 將驗證過的 BibTeX 加入參考書目
如果任何步驟失敗 → 標記為 [CITATION NEEDED]，告知科學家
```

```python
# 透過 DOI 獲取 BibTeX
import requests

def doi_to_bibtex(doi: str) -> str:
    response = requests.get(
        f"https://doi.org/{doi}",
        headers={"Accept": "application/x-bibtex"}
    )
    response.raise_for_status()
    return response.text
```

如果您無法驗證引用：

```latex
\cite{PLACEHOLDER_author2024_verify_this}  % TODO: Verify this citation exists
```

**務必告知科學家**："我已將 [X] 個引用標記為需要驗證的佔位符。"

參閱 [references/citation-workflow_zh_TW.md](references/citation-workflow_zh_TW.md) 了解完整的 API 文件與完整的 `CitationManager` 類別。

### 步驟 1.4: 整理相關工作

按方法論將論文分組，而不是逐篇列出：

**佳**："有一系列工作使用了 X 的假設 [refs]，而我們使用 Y 的假設是因為..."
**欠佳**："Smith 等人引入了 X。Jones 等人引入了 Y。我們結合了兩者。"

---

## 階段 2: 實驗設計 (Experiment Design)

**目標**：設計能直接支持論文聲明的實驗。每個實驗都必須回答一個特定的問題。

### 步驟 2.1: 將聲明映射至實驗

建立明確的映射關係：

| 聲明 | 實驗 | 預期證據 |
|-------|-----------|-------------------|
| "我們的方法優於基準方法" | 主要對比 (Table 1) | 勝率、統計顯著性 |
| "模型越弱，效果越顯著" | 模型縮放研究 (Model scaling study) | 單調改進曲線 |
| "收斂需要範圍限制" | 受限 vs 未受限 | 收斂速度對比 |

**規則**：如果一個實驗無法映射到聲明，就不要執行它。

### 步驟 2.2: 設計基準方法 (Baselines)

強大的基準方法是區分被接受與被拒絕論文的關鍵。審查員會問："他們是否與 X 進行了比較？"

標準基準方法類別：
- **樸素基準 (Naive baseline)**：最簡單的方法
- **強大基準 (Strong baseline)**：現有的最佳方法
- **消融基準 (Ablation baselines)**：您的方法減去一個組件
- **等效算力基準 (Compute-matched baselines)**：相同的運算預算，不同的分配方式

### 步驟 2.3: 定義評估協議 (Evaluation Protocol)

在執行任何操作前，請指定：
- **指標 (Metrics)**：您測量的內容、方向符號 (越高/越低越好)
- **聚合方式**：如何跨執行/任務合併結果
- **統計檢定**：哪些檢定將建立顯著性
- **樣本大小**：多少輪執行/問題/任務

### 步驟 2.4: 撰寫實驗腳本

遵循成功研究流程中的模式：

**增量儲存** — 每個步驟後儲存結果以便當機後恢復：
```python
# 每個問題/任務後儲存
result_path = f"results/{task}/{strategy}/result.json"
if os.path.exists(result_path):
    continue  # 跳過已完成的工作
# ... 執行實驗 ...
with open(result_path, 'w') as f:
    json.dump(result, f, indent=2)
```

**產物保存** — 儲存所有中間輸出：
```
results/<experiment>/
  <task>/
    <strategy>/
      final_output.md          # 最終結果
      history.json             # 完整軌跡
      pass_01/                 # 每輪迭代的產物
        version_a.md
        version_b.md
        critic.md
```

**關注點分離** — 保持生成、評估與視覺化的分離：
```
run_experiment.py              # 核心實驗執行器
run_baselines.py               # 基準方法對比
run_comparison_judge.py        # 雙盲評估
analyze_results.py             # 統計分析
make_charts.py                 # 視覺化
```

參閱 [references/experiment-patterns.md](references/experiment-patterns.md) 了解完整的設計模式、cron 監控與錯誤恢復。

### 步驟 2.5: 設計人類評估 (若適用)

許多 NLP、HCI 與對齊論文需要人類評估作為主要或補充證據。在執行自動化實驗前設計好這一點 — 人類評估通常需要較長的備置時間 (IRB 批准、標註者招募)。

**何時需要人類評估：**
- 自動化指標無法捕捉您關注的內容 (流暢度、幫助性、安全性)
- 您的貢獻與人類導向的品質有關 (可讀性、偏好、信任度)
- NLP 會議 (ACL, EMNLP) 的審查員期望在生成任務中看到它

**關鍵設計決策：**

| 決策 | 選項 | 指導建議 |
|----------|---------|----------|
| **標註者類型** | 專家、群眾外包人員、終端用戶 | 與您的聲明需求相匹配 |
| **量表** | 李克特量表 (1-5)、成對比較、排名 | 對於 LLM 輸出，成對比較比李克特量表更可靠 |
| **樣本大小** | 每位標註者的數量與總項目數 | 檢定力分析 (Power analysis) 或至少 100 個項目，3 位以上標註者 |
| **一致性指標** | Cohen's kappa, Krippendorff's alpha, ICC | 標註者超過 2 人時使用 Krippendorff's alpha；也要報告原始一致性 |
| **平台** | Prolific, MTurk, 內部團隊 | 追求品質用 Prolific；追求規模用 MTurk；追求領域專業用內部團隊 |

**標註指南檢查表：**
```
- [ ] 帶有範例 (正面與負面) 的清晰任務描述
- [ ] 模糊案例的決策標準
- [ ] 每個類別至少 2 個示範範例
- [ ] 注意力檢查 / 黃金標準項目 (總數的 10-15%)
- [ ] 資格任務或篩選輪次
- [ ] 預估每個項目的時間與公平報酬 (>= 當地最低工資)
- [ ] 若所屬機構要求，需進行 IRB/倫理審查
```

**報告要求** (審查員會檢查所有項目)：
- 標註者人數及其資格
- 標註者間的一致性 (具備特定指標與數值)
- 報酬細節 (金額、預估時薪)
- 標註介面描述或螢幕截圖 (附錄)
- 總標註時間

參閱 [references/human-evaluation_zh_TW.md](references/human-evaluation_zh_TW.md) 了解完整指南，包括針對人類評估數據的統計檢定、群眾外包品質控制模式及 IRB 指導。

---

## 階段 3: 實驗執行與監控 (Experiment Execution & Monitoring)

**目標**：可靠地執行實驗、監控進度、從失敗中恢復。

### 步驟 3.1: 啟動實驗

針對長時間執行的實驗使用 `nohup`：

```bash
nohup python run_experiment.py --config config.yaml > logs/experiment_01.log 2>&1 &
echo $!  # 記錄 PID
```

**平行執行**：同時執行獨立的實驗，但要注意 API 速率限制。在同一個 API 上同時進行 4 個以上的實驗會降低各自的速度。

### 步驟 3.2: 設置監控 (Cron 模式)

針對長時間執行的實驗，設置定期的狀態檢查。cron 提示詞應遵循此模板：

```
Monitor Prompt Template:
1. 檢查程序是否仍在執行：ps aux | grep <pattern>
2. 讀取日誌最後 30 行：tail -30 <logfile>
3. 檢查已完成的結果：ls <result_dir>
4. 若結果存在，讀取並報告：cat <result_file>
5. 若全部完成，提交：git add -A && git commit -m "<descriptive message>" && git push
6. 以結構化格式報告 (包含關鍵指標的表格)
7. 回答針對此實驗的關鍵分析問題
```

**靜默模式**：若自上次檢查以來無任何更動，回應 `[SILENT]` 以抑制對用戶的通知。僅在有消息時報告。

### 步驟 3.3: 處理失敗

常見的失敗模式與恢復：

| 失敗 | 偵測 | 恢復 |
|---------|-----------|----------|
| API 速率限制 / 額度用罄 | 日誌中的 402/429 錯誤 | 等待後重新執行 (腳本會跳過已完成的工作) |
| 程序崩潰 | PID 消失，結果不完整 | 從最後的檢查點重新執行 |
| 困難問題逾時 | 程序卡住，日誌無進度 | 終止並跳過，在結果中註明 |
| 錯誤的模型 ID | 引用模型名稱的錯誤 | 修正 ID 並重新執行 |

**關鍵**：腳本應始終檢查現有結果並跳過已完成的工作。這使得重新執行變得安全且高效。

### 步驟 3.4: 提交完成的結果

在每個實驗批次完成後：

```bash
git add -A
git commit -m "Add <experiment name>: <key finding in 1 line>"
git push
```

### 步驟 3.5: 維持實驗日誌 (Experiment Journal)

Git 提交追蹤了發生了什麼，但沒追蹤到**探索樹 (exploration tree)** — 即根據所學知識決定下一步嘗試什麼的決策。維持一個捕捉此樹的結構化實驗日誌：

```json
// experiment_journal.jsonl — 每個實驗嘗試追加一個條目
{
  "id": "exp_003",
  "parent": "exp_001",
  "timestamp": "2025-05-10T14:30:00Z",
  "hypothesis": "添加範圍限制將修正 exp_001 中的收斂失敗",
  "plan": "使用 max_tokens=2000 與固定的結構模板重新執行 autoreason",
  "config": {"model": "haiku", "strategy": "autoreason", "max_tokens": 2000},
  "status": "completed",
  "result_path": "results/exp_003/",
  "key_metrics": {"win_rate": 0.85, "convergence_rounds": 3},
  "analysis": "範圍限制修正了收斂問題。勝率從 0.42 躍升至 0.85。",
  "next_steps": ["在 Sonnet 上嘗試相同的限制", "測試不使用結構模板的情況"],
  "figures": ["figures/exp003_convergence.pdf"]
}
```

**為什麼需要日誌而不僅僅是 git？** Git 追蹤檔案變更。日誌則追蹤推理過程：為什麼嘗試 X、學到了什麼，以及這對下一個實驗意味著什麼。在撰寫論文時，這棵樹對於方法 (Methods) 章節 ("我們觀察到 X，這促使了 Y") 與誠實報告失敗非常寶貴。

**選擇最佳路徑**：當日誌顯示出一棵分叉樹時 (exp_001 → exp_002a, exp_002b, exp_003)，識別出最能支持論文聲明的路徑。在附錄中將死路分支記錄為消融實驗或負面結果。

**每次實驗對程式碼進行快照**：在每次執行後複製實驗腳本：
```bash
cp experiment.py results/exp_003/experiment_snapshot.py
```
這確保了即使在隨後的程式碼更改後也能準確重現。

---

## 階段 4: 結果分析 (Result Analysis)

**目標**：提取發現、計算統計數據、找出故事主軸。

### 步驟 4.1: 聚合結果

撰寫分析腳本以：
1. 從批次中載入所有結果檔案
2. 計算每個任務及整體的指標
3. 生成摘要表格

```python
# 標準分析模式
import json, os
from pathlib import Path

results = {}
for result_file in Path("results/").rglob("result.json"):
    data = json.loads(result_file.read_text())
    strategy = result_file.parent.name
    task = result_file.parent.parent.name
    results.setdefault(strategy, {})[task] = data

# 計算整體指標
for strategy, tasks in results.items():
    scores = [t["score"] for t in tasks.values()]
    print(f"{strategy}: mean={np.mean(scores):.1f}, std={np.std(scores):.1f}")
```

### 步驟 4.2: 統計顯著性

務必計算：
- **誤差線 (Error bars)**：標準差或標準誤，並註明是哪一種
- **信賴區間 (Confidence intervals)**：針對關鍵結果提供 95% CI
- **成對檢定 (Pairwise tests)**：用於比較兩種方法的 McNemar's 檢定
- **效果量 (Effect sizes)**：針對實務顯著性計算 Cohen's d 或 h

參閱 [references/experiment-patterns.md](references/experiment-patterns.md) 了解 McNemar's 檢定、自助法 (bootstrapped) CIs 與 Cohen's h 的完整實作。

### 步驟 4.3: 找出故事主軸

分析後，明確回答：
1. **主要發現是什麼？** 用一句話陳述它。
2. **什麼讓您驚訝？** 出乎意料的結果往往能成就最棒的論文。
3. **什麼失敗了？** 失敗的實驗可能最具資訊量。誠實報告失敗會增強論文的說服力。
4. **還需要哪些後續實驗？** 結果往往會引發新的問題。

#### 處理負面或虛無結果 (Negative or Null Results)

當您的假設錯誤或結果不明確時，您有三個選擇：

| 情況 | 行動 | 適合的場合 |
|-----------|--------|-----------|
| 假設錯誤但**原因**具有資訊量 | 以「為何如此」的分析為核心建構論文 | NeurIPS, ICML (若分析嚴謹) |
| 方法未擊敗基準但**揭示了新事物** | 將貢獻重新定調為理解/分析 | ICLR (重視理解), 工作坊論文 |
| 針對流行聲明的乾淨負面結果 | 寫下來 — 該領域需要知道這一點 | NeurIPS Datasets & Benchmarks, TMLR, 工作坊 |
| 結果不明確，無清晰故事 | 轉向 — 執行不同的實驗或重新定調 | 不要強行撰寫不存在的論文 |

**如何撰寫負面結果論文：**
- 以社群目前的認知以及測試它的重要性作為開場
- 描述您嚴謹的方法論 (必須無懈可擊 — 審查員會審查得更嚴格)
- 以統計證據清晰呈現虛無結果
- 分析**為何**預期結果沒有出現
- 討論對該領域的影響

**明確歡迎負面結果的場合**：NeurIPS (Datasets & Benchmarks 軌道), TMLR, ML 可重現性挑戰賽, 各大會議的工作坊。有些工作坊會專門徵求負面結果。

### 步驟 4.4: 建立圖表與表格

**圖表**：
- 所有繪圖皆使用向量圖 (PDF)：`plt.savefig('fig.pdf')`
- 使用色盲友善的調色盤 (Okabe-Ito 或 Paul Tol)
- 圖說 (caption) 應自成一體 — 讀者應在不看正文的情況下也能理解
- 圖表內不要有標題 — 圖說已承擔此功能

**表格**：
- 使用 `booktabs` LaTeX 套件
- 針對每個指標將最佳值加粗
- 包含方向符號 (越高/越低越好)
- 保持一致的小數位精度

```latex
\usepackage{booktabs}
\begin{tabular}{lcc}
\toprule
Method & Accuracy $\uparrow$ & Latency $\downarrow$ \\
\midrule
Baseline & 85.2 & 45ms \\
\textbf{Ours} & \textbf{92.1} & 38ms \\
\bottomrule
\end{tabular}
```

### 步驟 4.5: 決定：更多實驗還是開始寫作？

| 情況 | 行動 |
|-----------|--------|
| 核心聲明獲得支持，結果具顯著性 | 進入階段 5 (寫作) |
| 結果不明確，需要更多數據 | 回到階段 2 (設計) |
| 意外的發現暗示了新方向 | 回到階段 2 (設計) |
| 缺少一項審查員會要求的消融實驗 | 執行它，然後進入階段 5 |
| 所有實驗已完成但部分失敗 | 記錄失敗，進入階段 5 |

### 步驟 4.6: 撰寫實驗紀錄 (銜接寫作的橋樑)

在進入論文寫作之前，建立一個將結果橋接至散文的結構化實驗紀錄。這是實驗與初稿之間最重要的連結組織 — 若缺少它，寫作代理必須從原始結果檔案中重新推導故事。

**建立 `experiment_log.md`**，結構如下：

```markdown
# 實驗紀錄 (Experiment Log)

## 貢獻 (一句話)
[論文的主要聲明]

## 已執行的實驗

### 實驗 1: [名稱]
- **測試的聲明**: [支持論文中的哪個聲明]
- **設置**: [模型、資料集、設定、執行輪數]
- **關鍵結果**: [帶有數據的一句話]
- **結果檔案**: results/exp1/final_info.json
- **生成的圖表**: figures/exp1_comparison.pdf
- **令人驚訝的發現**: [任何出乎意料的事項]

### 實驗 2: [名稱]
...

## 圖表
| 檔名 | 描述 | 屬於哪個章節 |
|----------|-------------|---------------------------|
| figures/main_comparison.pdf | 在基準測試 X 上比較所有方法的柱狀圖 | 結果 (Results), Figure 2 |
| figures/ablation.pdf | 移除組件 A, B, C 的消融實驗 | 結果 (Results), Figure 3 |
...

## 失敗的實驗 (為了誠實性而記錄)
- [嘗試了什麼、為什麼失敗、這告訴了我們什麼]

## 未決問題
- [結果中引發的任何論文應探討的問題]
```

**為什麼這很重要**：起草時，代理 (或委派的子代理) 可以將 `experiment_log.md` 連同 LaTeX 模板一起載入，並產出一份立足於實際結果的初稿。若無此橋樑，寫作代理必須解析原始的 JSON/CSV 檔案並推斷故事 — 這是幻覺或誤報數據的常見來源。

**Git 規範**：將此紀錄連同它所描述的結果一起提交。

---

## 迭代改進：策略選擇 (Strategy Selection)

此流程中的任何輸出 — 論文草稿、實驗腳本、分析 — 都可以進行迭代改進。autoreason 研究為每種改進策略何時有效、何時失敗提供了實證證據。請使用此章節選擇正確的方法。

### 快速決策表

| 您的情況 | 策略 | 為什麼 |
|---------------|----------|-----|
| 中階模型 + 受限任務 | **Autoreason** | 甜蜜點。生成與評估之間的差距最大。基準方法會主動破壞弱模型的輸出。 |
| 中階模型 + 開放式任務 | 增加範圍限制的 **Autoreason** | 增加固定的事實、結構或交付物以限制改進空間。 |
| 頂尖模型 + 受限任務 | **Autoreason** | 即使在頂尖模型上，也能贏得 2/3 的受限任務。 |
| 頂尖模型 + 未受限任務 | **批評與修訂 (Critique-and-revise)** 或 **單次生成** | Autoreason 效果最差。模型自我評估能力已足夠。 |
| 具體的技術任務 (系統設計) | **批評與修訂** | 直接的「發現並修復」迴圈更有效率。 |
| 填充模板任務 (單一正確結構) | **單次生成** 或 **保守型** | 決策空間極小。迭代不會增加價值。 |
| 帶有測試案例的程式碼 | **Autoreason (程式碼變體)** | 在修復前對失敗原因進行結構化分析。恢復率 62% vs 43%。 |
| 極弱的模型 (Llama 8B 級別) | **單次生成** | 模型太弱，無法生成多樣化的候選者。應投資於生成品質。 |

### 生成-評估差距

**核心洞察**：Autoreason 的價值取決於模型生成能力與其自我評估能力之間的差距。

```
模型層級          │ 生成能力 │ 自我評估 │ 差距    │ Autoreason 價值
──────────────────┼────────────┼───────────┼────────┼─────────────────
弱 (Llama 8B)     │ 差         │ 差         │ 小      │ 無 — 無法生成多樣化候選者
中階 (Haiku 3.5)  │ 尚可       │ 差         │ 極大    │ 最大 — 42/42 完美 Borda
中階 (Gemini Flash)│ 尚可       │ 中等       │ 大      │ 高 — 贏得 2/3
強 (Sonnet 4)     │ 好         │ 尚可       │ 中等    │ 適中 — 贏得 3/5
頂尖 (S4.6)       │ 極佳       │ 好         │ 小      │ 僅在受限情況下
```

這種差距是結構性的，而非暫時的。隨著成本下降，今日的頂尖模型將成為明日的中階模型。甜蜜點會移動，但永遠不會消失。

### Autoreason 迴圈摘要

每一輪都會從全新的、隔離的代理中產生三個候選者：

1. **批評者 (Critic)** → 找出現任版 A 的問題 (不修正)
2. **作者 B (Author B)** → 根據批評修訂 A
3. **綜合者 (Synthesizer)** → 合併 A 與 B (標籤隨機化)
4. **評審小組 (Judge Panel)** → 3 位雙盲 CoT 評審對 A, B, AB 進行排名 (Borda count)
5. **收斂** → A 連續兩輪 (k=2) 勝出 → 完成

**關鍵參數：**
- k=2 收斂 (k=1 太早，k=3 太貴且無品質提升)
- 務必使用 CoT 評審 (收斂速度快 3 倍)
- 作者溫度 0.8，評審溫度 0.3
- 保守型平手處理：現任版勝出
- 每個角色都是全新的代理，無共享上下文

### 應用於論文草稿

當透過 autoreason 精煉論文本身時：
- **向批評者提供地面事實 (ground truth)**：實際的實驗數據、結果 JSONs、統計輸出。若無這些，模型會幻覺出編造的消融研究與虛假的信賴區間。
- **至少使用 3 位有效評審**：損壞的評審解析器不僅會增加雜訊 — 它會完全阻止平衡的達成。
- **對修訂進行範圍限制**："解決這些具體的弱點" 而不是 "改進論文"。

### 失敗模式

| 失敗 | 偵測 | 修正 |
|---------|-----------|-----|
| 無法收斂 (A 從不勝出) | A 在 20 輪以上的勝率 <15% | 對任務增加範圍限制 |
| 綜合版漂移 | 字數無限制增長 | 限制結構與交付物 |
| 品質退化至單次生成以下 | 基準方法得分高於迭代輸出 | 切換至單次生成；模型可能太弱 |
| 過度擬合 (程式碼) | 公開測試通過率高，私有測試低 | 使用結構化分析，而非僅依賴測試反饋 |
| 評審損壞 | 解析失敗導致有效小組成員少於 3 位 | 在繼續前修復解析器 |

參閱 [references/autoreason-methodology_zh_TW.md](references/autoreason-methodology_zh_TW.md) 了解完整的提示詞、Borda 計分細節、模型選擇指南、範圍限制設計模式以及運算預算參考。

---

## 階段 5: 論文起草 (Paper Drafting)

**目標**：撰寫一份完整的、達到出版水準的論文。

### 大型專案的上下文管理

一個擁有 50 多個實驗檔案、多個結果目錄以及廣泛文獻筆記的論文專案，很容易超出代理的上下文窗口。請主動管理：

**每個起草任務應載入上下文的內容：**

| 起草任務 | 載入上下文 | 不要載入 |
|---------------|------------------|-------------|
| 撰寫簡介 (Introduction) | `experiment_log.md`、貢獻聲明、5-10 篇最相關的論文摘要 | 原始結果 JSONs、完整的實驗腳本、所有文獻筆記 |
| 撰寫方法 (Methods) | 實驗設定、偽程式碼、架構描述 | 原始日誌、來自其他實驗的結果 |
| 撰寫結果 (Results) | `experiment_log.md`、結果摘要表、圖表列表 | 完整的分析腳本、中間數據 |
| 撰寫相關工作 (Related Work) | 整理好的引用筆記 (步驟 1.4 的產出)、.bib 檔案 | 實驗檔案、原始 PDFs |
| 修訂輪次 | 完整的論文草稿、特定的審查員疑慮 | 其他所有內容 |

**原則：**
- **`experiment_log.md` 是主要的上下文橋樑** — 它總結了寫作所需的一切，而無需載入原始數據檔案 (見步驟 4.6)
- **委派時一次載入一個章節的上下文**。起草「方法」的子代理不需要「文獻回顧」的筆記。
- **總結，不要包含原始檔案**。對於 200 行的結果 JSON，載入 10 行的摘要表。對於 50 頁的相關論文，載入 5 句摘要 + 您關於其相關性的 2 行筆記。
- **針對超大型專案**：建立一個帶有預壓縮摘要的 `context/` 目錄：
  ```
  context/
    contribution.md          # 1 句話
    experiment_summary.md    # 關鍵結果表 (來自 experiment_log.md)
    literature_map.md        # 整理好的引用筆記
    figure_inventory.md      # 帶有描述的圖表清單
  ```

### 敘事原則 (The Narrative Principle)

**單一最重要的洞察**：您的論文不是實驗的集合 — 它是一個帶有單一清晰貢獻並由證據支持的故事。

每篇成功的 ML 論文都以 Neel Nanda 所稱的「敘事 (the narrative)」為中心：一個簡短、嚴謹、基於證據的技術故事，且具備讀者在意的結論。

**三大支柱 (在簡介結束前必須清晰明確)：**

| 支柱 | 描述 | 測試 |
|--------|-------------|------|
| **內容 (The What)** | 1-3 個特定的創新聲明 | 您能否用一句話陳述它們？ |
| **原因 (The Why)** | 嚴謹的實證證據 | 實驗是否將您的假設與其他替代方案區分開來？ |
| **意義 (The So What)** | 讀者為什麼要在意 | 這是否與社群公認的問題相關聯？ |

**如果您無法用一句話陳述您的貢獻，說明您還沒準備好寫論文。**

### 這些指導方針背後的來源

本技能綜合了在頂尖場合發表過大量論文的研究者的寫作哲學。寫作哲學層最初由 [Orchestra Research](https://github.com/orchestra-research) 編譯為 `ml-paper-writing` 技能。

| 來源 | 關鍵貢獻 | 連結 |
|--------|-----------------|------|
| **Neel Nanda** (Google DeepMind) | 敘事原則、What/Why/So What 框架 | [How to Write ML Papers](https://www.alignmentforum.org/posts/eJGptPbbFPZGLpjsp/highly-opinionated-advice-on-how-to-write-ml-papers) |
| **Sebastian Farquhar** (DeepMind) | 5 句話摘要公式 | [How to Write ML Papers](https://sebastianfarquhar.com/on-research/2024/11/04/how_to_write_ml_papers/) |
| **Gopen & Swan** | 讀者期望的 7 大原則 | [Science of Scientific Writing](https://cseweb.ucsd.edu/~swanson/papers/science-of-writing.pdf) |
| **Zachary Lipton** | 用字選擇、消除模稜兩可的語氣 (hedging) | [Heuristics for Scientific Writing](https://www.approximatelycorrect.com/2018/01/29/heuristics-technical-scientific-writing-machine-learning-perspective/) |
| **Jacob Steinhardt** (UC Berkeley) | 精確性、一致的術語 | [Writing Tips](https://bounded-regret.ghost.io/) |
| **Ethan Perez** (Anthropic) | 微觀層面的清晰度技巧 | [Easy Paper Writing Tips](https://ethanperez.net/easy-paper-writing-tips/) |
| **Andrej Karpathy** | 專注於單一貢獻 | 各種講座 |

**欲深入了解其中任何一項，請參閱：**
- [references/writing-guide_zh_TW.md](references/writing-guide_zh_TW.md) — 帶有範例的完整解釋
- [references/sources_zh_TW.md](references/sources_zh_TW.md) — 完整的參考書目

### 時間分配

在以下每一項上花費約**相等的時間**：
1. 摘要 (Abstract)
2. 簡介 (Introduction)
3. 圖表 (Figures)
4. 其他所有內容的總和

**為什麼？** 大多數審查員在看到您的方法之前就已經形成了判斷。讀者接觸您論文的順序是：標題 → 摘要 → 簡介 → 圖表 → 也許是剩下的部分。

### 寫作工作流程

```
Paper Writing Checklist:
- [ ] 步驟 1：定義一句話的貢獻
- [ ] 步驟 2：起草 Figure 1 (核心想法或最引人注目的結果)
- [ ] 步驟 3：起草摘要 (5 句話公式)
- [ ] 步驟 4：起草簡介 (最多 1-1.5 頁)
- [ ] 步驟 5：起草方法
- [ ] 步驟 6：起草實驗與結果
- [ ] 步驟 7：起草相關工作
- [ ] 步驟 8：起草結論與討論
- [ ] 步驟 9：起草限制 (所有場合皆為必填)
- [ ] 步驟 10：規劃附錄 (證明、額外實驗、細節)
- [ ] 步驟 11：完成論文檢查表
- [ ] 步驟 12：最終審查
```

### 兩階段精煉模式 (Two-Pass Refinement Pattern)

當使用 AI 代理進行起草時，使用**兩階段**方法 (這在 SakanaAI 的 AI-Scientist 流程中被證明是有效的)：

**第一階段 — 每個章節寫作 + 立即精煉：**
針對每個章節，撰寫完整的草稿，然後立即在相同的上下文中進行精煉。這能在該章節記憶猶新時捕捉到局部問題 (清晰度、流暢性、完整性)。

**第二階段 — 具備全篇論文意識的全域精煉：**
在所有章節起草完成後，在意識到整篇論文的情況下重新審視每個章節。這能捕捉到跨章節的問題：冗餘、術語不一致、敘事流動性，以及某個章節做出了承諾而另一個章節未交付的差距。

```
第二階段精煉提示詞 (針對每個章節)：
"在整篇論文的背景下審核 [SECTION]。
- 它是否與論文的其他部分銜接？是否與其他章節存在冗餘？
- 術語是否與簡介和方法保持一致？
- 是否有任何內容可以在不削弱訊息的情況下被刪減？
- 敘事是否從前一章節流向下一章節？
進行微小、針對性的編輯。不要從頭重寫。"
```

### LaTeX 錯誤檢查表

將此檢查表附加到每個精煉提示詞。這些是 LLM 撰寫 LaTeX 時最常見的錯誤：

```
LaTeX Quality Checklist (每次編輯後驗證)：
- [ ] 無未閉合的數學符號 ($ 符號需成對)
- [ ] 僅引用存在的圖/表 (\ref 與 \label 匹配)
- [ ] 無捏造的引用 (\cite 與 .bib 中的條目匹配)
- [ ] 每個 \begin{env} 都有匹配的 \end{env} (特別是 figure, table, algorithm)
- [ ] 無 HTML 污染 (例如 </end{figure}> 而非 \end{figure})
- [ ] 在數學模式之外無未跳脫的下劃線 (在文字中使用 \_)
- [ ] 無重複的 \label 定義
- [ ] 無重複的章節標題
- [ ] 文字中的數字與實際實驗結果相符
- [ ] 所有圖表皆有圖說與標籤
- [ ] 無過長的行導致 overfull hbox 警告
```

### 步驟 5.0: 標題 (Title)

標題是論文中閱讀量最高的單一元素。它決定了是否有人會點擊查看摘要。

**佳標題**：
- 陳述貢獻或發現："Autoreason: When Iterative LLM Refinement Works and Why It Fails"
- 強調令人驚訝的結果："Scaling Data-Constrained Language Models" (暗示您可以做到)
- 命名方法 + 它的功能："DPO: Direct Preference Optimization of Language Models"

**欠佳標題**：
- 太過籠統："An Approach to Improving Language Model Outputs"
- 太長：任何超過 ~15 個字的標題
- 只有術語："Asymptotic Convergence of Iterative Stochastic Policy Refinement" (這是給誰看的？)

**規則**：
- 如果您有名稱，請包含您的方法名稱 (為了可引用性)
- 包含 1-2 個審查員會搜尋的關鍵字
- 避免使用冒號，除非前後兩部分都具有意義
- 測試：審查員能否僅憑標題就了解領域與貢獻？

### 步驟 5.1: 摘要 (5 句話公式)

來自 Sebastian Farquhar (DeepMind)：

```
1. 您取得了什麼成就："We introduce...", "We prove...", "We demonstrate..."
2. 為什麼這很困難且重要
3. 您是如何做到的 (帶有專業關鍵字以便被檢索)
4. 您有什麼證據
5. 您最顯著的數據/結果
```

**刪除** 諸如 "Large language models have achieved remarkable success..." 之類的通用開場白。

### 步驟 5.2: Figure 1

Figure 1 是大多數讀者（在摘要之後）看的第二件事。在撰寫簡介之前起草它 — 這會強迫您釐清核心想法。

| Figure 1 類型 | 何時使用 | 範例 |
|---------------|-------------|---------|
| **方法圖** | 新架構或流程 | 顯示您系統的 TikZ 流程圖 |
| **結果預告** | 一個引人注目的結果道盡一切 | 柱狀圖："我們 vs 基準方法" 且有明顯差距 |
| **問題插圖** | 問題是不直觀的 | 顯示您所修復的失敗模式之「前/後」對比 |
| **概念圖** | 抽象貢獻需要視覺落地 | 方法屬性的 2x2 矩陣 |

**規則**：Figure 1 必須在不閱讀任何文字的情況下就能被理解。圖說本身就應傳達核心想法。有目的地使用顏色 — 不要只是裝飾。

### 步驟 5.3: 簡介 (最多 1-1.5 頁)

必須包含：
- 清晰的問題陳述
- 簡要的方法概述
- 2-4 個點列式的貢獻列表 (在雙欄格式中每項最多 1-2 行)
- 「方法」章節應在第 2-3 頁開始

### 步驟 5.4: 方法 (Methods)

使他人能夠重新實作：
- 概念大綱或偽程式碼
- 列出所有超參數
- 足以重現的架構細節
- 呈現最終的設計決策；消融實驗放在實驗章節

### 步驟 5.5: 實驗與結果 (Experiments & Results)

針對每個實驗，明確說明：
- **它支持哪個聲明**
- 它如何與主要貢獻建立聯繫
- 觀察重點："藍線顯示了 X，這證明了 Y"

要求：
- 帶有方法論的誤差線 (標準差 vs 標準誤)
- 超參數搜尋範圍
- 運算基礎設施 (GPU 類型、總時數)
- 種子設置方法

### 步驟 5.6: 相關工作 (Related Work)

按方法論進行組織，而不是逐篇列出。慷慨地引用 — 審查員很可能就是相關論文的作者。

### 步驟 5.7: 限制 (Limitations) (必填)

所有主要會議都要求此部分。誠實有所幫助：
- 審查員被指示不要懲罰誠實承認限制的行為
- 透過先識別弱點來預防批評
- 解釋為什麼限制不會削弱核心聲明

### 步驟 5.8: 結論與討論 (Conclusion & Discussion)

**結論** (必填，0.5-1 頁)：
- 用一句話重述貢獻 (用詞應與摘要不同)
- 總結關鍵發現 (2-3 句話，不是列表)
- 影響：這對該領域意味著什麼？
- 未來工作：2-3 個具體的後續步驟 (不是模糊的 "we leave X for future work")

**討論** (選填，有時與結論合併)：
- 超出立即結果的更廣泛影響
- 與其他子領域的聯繫
- 對方法何時有效、何時無效的誠實評估
- 實際部署的考量

**切勿**在結論中引入新的結果或聲明。

### 步驟 5.9: 附錄策略 (Appendix Strategy)

在所有主要場合，附錄都是無限制的，且對於可重現性至關重要。結構：

| 附錄章節 | 內容 |
|-----------------|---------------|
| **證明與推導** | 對於正文來說太長的完整證明。正文可以陳述定理並標註 "proof in Appendix A"。 |
| **額外實驗** | 消融實驗、縮放曲線、每個資料集的細節、超參數敏感性 |
| **實作細節** | 完整的超參數表格、訓練細節、硬體規格、隨機種子 |
| **資料集文件** | 資料收集過程、標註指南、授權、預處理 |
| **提示詞與模板** | 使用的確切提示詞 (針對基於 LLM 的方法)、評估模板 |
| **人類評估** | 標註介面截圖、給標註者的說明、IRB 細節 |
| **額外圖表** | 每個任務的細節、軌跡視覺化、失敗案例範例 |

**規則**：
- 主論文必須自成一體 — 審查員不被要求閱讀附錄
- 絕不要只將關鍵證據放在附錄中
- 交叉引用："完整結果見 Table 5 (Appendix B)" 而不僅是 "see appendix"
- 使用 `\appendix` 指令，然後是 `\section{A: Proofs}` 等

### 頁數預算管理

當超出頁數限制時：

| 刪減策略 | 節省 | 風險 |
|-------------|-------|------|
| 將證明移至附錄 | 0.5-2 頁 | 低 — 這是標準做法 |
| 縮減相關工作 | 0.5-1 頁 | 中 — 可能遺漏關鍵引用 |
| 將表格與子圖合併 | 0.25-0.5 頁 | 低 — 通常能提高可讀性 |
| 謹慎使用 `\vspace{-Xpt}` | 0.1-0.3 頁 | 若不明顯則低，若明顯則高 |
| 移除定性範例 | 0.5-1 頁 | 中 — 審查員喜歡範例 |
| 縮小圖表大小 | 0.25-0.5 頁 | 高 — 圖表必須保持可讀 |

**切勿**：縮小字體大小、更改邊距、移除必要章節 (限制、更廣泛的影響)，或在正文中使用 `\small`/`\footnotesize`。

### 步驟 5.10: 倫理與更廣泛的影響聲明 (Ethics & Broader Impact Statement)

大多數場合現在要求或強烈建議提供倫理/更廣泛的影響聲明。這不是公式化的文字 — 審查員會閱讀它，並可能標出會導致直接拒稿的倫理疑慮。

**應包含的內容：**

| 組件 | 內容 | 要求者 |
|-----------|---------|-------------|
| **正面社會影響** | 您的工作如何造福社會 | NeurIPS, ICML |
| **潛在負面影響** | 濫用風險、雙重用途疑慮、失敗模式 | NeurIPS, ICML |
| **公平性與偏見** | 您的方法/資料是否有已知偏見？ | 所有場合 (隱含) |
| **環境影響** | 大規模訓練的運算碳足跡 | ICML, NeurIPS 亦日益重視 |
| **隱私** | 您的工作是否使用或啟用了個人數據處理？ | ACL, NeurIPS |
| **LLM 揭露** | 寫作或實驗中是否使用了 AI？ | ICLR (強制), ACL |

**撰寫聲明：**

```latex
\section*{Broader Impact Statement}
% NeurIPS/ICML: 放在結論後，不計入頁數限制

% 1. 正面應用 (1-2 句話)
This work enables [specific application] which may benefit [specific group].

% 2. 風險與緩解 (1-3 句話，需具體)
[Method/model] could potentially be misused for [specific risk]. We mitigate
this by [specific mitigation, e.g., releasing only model weights above size X,
including safety filters, documenting failure modes].

% 3. 影響聲明的局限性 (1 句話)
Our evaluation is limited to [specific domain]; broader deployment would
require [specific additional work].
```

**常見錯誤：**
- 撰寫 "we foresee no negative impacts" (幾乎從不屬實 — 審查員不信任此說法)
- 語意模糊："這可能會被濫用" 但未指明如何被濫用
- 忽視大規模工作的運算成本
- 在要求的場合忘記揭露 LLM 的使用

**計算碳足跡** (針對訓練密集型論文)：
```python
# 使用 ML CO2 Impact 工具的方法論進行估算
gpu_hours = 1000  # 總 GPU 時數
gpu_tdp_watts = 400  # 例如 A100 = 400W
pue = 1.1  # 電能使用效率 (資料中心開銷)
carbon_intensity = 0.429  # kg CO2/kWh (美國平均；隨地區變化)

energy_kwh = (gpu_hours * gpu_tdp_watts * pue) / 1000
carbon_kg = energy_kwh * carbon_intensity
print(f"Energy: {energy_kwh:.0f} kWh, Carbon: {carbon_kg:.0f} kg CO2eq")
```

### 步驟 5.11: 資料單 (Datasheets) 與模型卡 (Model Cards) (若適用)

如果您的論文引入了**新資料集**或**發布了模型**，請包含結構化文件。審查員日益期望看到這些，且 NeurIPS Datasets & Benchmarks 軌道對此有強制要求。

**針對資料集的資料單 (Datasheets for Datasets)** (Gebru et al., 2021) — 包含在附錄中：

```
Dataset Documentation (Appendix):
- Motivation: 為什麼建立此資料集？它支持什麼任務？
- Composition: 實例是什麼？有多少？什麼資料類型？
- Collection: 資料是如何收集的？來源是什麼？
- Preprocessing: 應用了哪些清洗/過濾？
- Distribution: 資料集如何分發？基於什麼授權？
- Maintenance: 誰負責維護？如何報告問題？
- Ethical considerations: 包含個人數據？是否取得同意？
  潛在危害？已知偏見？
```

**模型卡 (Model Cards)** (Mitchell et al., 2019) — 針對模型發布包含在附錄中：

```
Model Card (Appendix):
- Model details: 架構、訓練資料、訓練程序
- Intended use: 主要使用案例、超出範圍的用途
- Metrics: 基準測試中的評估指標與結果
- Ethical considerations: 已知偏見、公平性評估
- Limitations: 已知失敗模式、模型表現不佳的領域
```

### 寫作風格

**句子層級的清晰度 (Gopen & Swan 的 7 大原則)：**

| 原則 | 規則 |
|-----------|------|
| 主謂接近性 | 保持主詞與動詞靠近 |
| 強調位置 | 將重點放在句尾 |
| 主題位置 | 背景資訊在前，新資訊在後 |
| 先舊後新 | 熟悉的資訊 → 不熟悉的資訊 |
| 一單元一功能 | 每個段落只表達一個重點 |
| 動詞體現動作 | 使用動詞，而非名詞化 |
| 先背景後新知 | 在呈現新內容前先鋪陳背景 |

**用字選擇 (Lipton, Steinhardt)：**
- 具體化："準確度 (accuracy)" 而非 "效能 (performance)"
- 消除模稜兩可：除非真的不確定，否則去掉 "may"
- 全篇術語保持一致
- 避免使用漸進式詞彙："開發 (develop)"，而非 "結合 (combine)"

**帶有範例的完整寫作指南**：參見 [references/writing-guide_zh_TW.md](references/writing-guide_zh_TW.md)

### 使用 LaTeX 模板

**務必先複製整個模板目錄，然後在其內部編寫。**

```
Template Setup Checklist:
- [ ] 步驟 1：將整個模板目錄複製到新專案
- [ ] 步驟 2：驗證模板能否按原樣編譯 (在進行任何更改前)
- [ ] 步驟 3：閱讀模板的範例內容以理解結構
- [ ] 步驟 4：逐章替換範例內容
- [ ] 步驟 5：使用模板巨集 (檢查導言區中的 \newcommand 定義)
- [ ] 步驟 6：僅在最後清理模板產物
```

**步驟 1：複製完整模板**

```bash
cp -r templates/neurips2025/ ~/papers/my-paper/
cd ~/papers/my-paper/
ls -la  # 應看到：main.tex, neurips.sty, Makefile 等
```

複製整個目錄，而不僅是 .tex 檔案。模板包含樣式檔 (.sty)、參考文獻格式檔 (.bst)、範例內容及 Makefile。

**步驟 2：先驗證模板編譯**

在進行任何更改前：
```bash
latexmk -pdf main.tex
# 或手動：pdflatex main.tex && bibtex main && pdflatex main.tex && pdflatex main.tex
```

若未修改的模板無法編譯，請先修復它 (通常是缺失 TeX 套件 — 透過 `tlmgr install <package>` 安裝)。

**步驟 3：保留模板內容作為參考**

不要立即刪除範例內容。將其註解掉並作為格式參考：
```latex
% Template example (keep for reference):
% \begin{figure}[t]
%   \centering
%   \includegraphics[width=0.8\linewidth]{example-image}
%   \caption{Template shows caption style}
% \end{figure}

% 您的實際圖表：
\begin{figure}[t]
  \centering
  \includegraphics[width=0.8\linewidth]{your-figure.pdf}
  \caption{您的圖說遵循相同的風格。}
\end{figure}
```

**步驟 4：逐章替換內容**

系統地進行：標題/作者 → 摘要 → 簡介 → 方法 → 實驗 → 相關工作 → 結論 → 參考文獻 → 附錄。每完成一個章節就編譯一次。

**步驟 5：使用模板巨集**

```latex
\newcommand{\method}{YourMethodName}  % 一致的方法命名
\newcommand{\eg}{e.g.,\xspace}        % 正確的縮寫
\newcommand{\ie}{i.e.,\xspace}
```

### 模板陷阱

| 陷阱 | 問題 | 解決方案 |
|---------|---------|----------|
| 僅複製 `.tex` 檔案 | 缺少 `.sty`，無法編譯 | 複製整個目錄 |
| 修改 `.sty` 檔案 | 破壞會議格式 | 絕不要編輯樣式檔 |
| 隨意添加套件 | 衝突，破壞模板 | 僅在必要時添加 |
| 過早刪除模板內容 | 失去格式參考 | 保留為註解直到完成 |
| 未頻繁編譯 | 錯誤累積 | 每個章節後編譯一次 |
| 圖表使用點陣圖 PNG | 論文中會模糊 | 務必透過 `savefig('fig.pdf')` 使用向量 PDF |

### 快速模板參考

| 會議 | 主要檔案 | 樣式檔案 | 頁數限制 |
|------------|-----------|------------|------------|
| NeurIPS 2025 | `main.tex` | `neurips.sty` | 9 頁 |
| ICML 2026 | `example_paper.tex` | `icml2026.sty` | 8 頁 |
| ICLR 2026 | `iclr2026_conference.tex` | `iclr2026_conference.sty` | 9 頁 |
| ACL 2025 | `acl_latex.tex` | `acl.sty` | 8 頁 (long) |
| AAAI 2026 | `aaai2026-unified-template.tex` | `aaai2026.sty` | 7 頁 |
| COLM 2025 | `colm2025_conference.tex` | `colm2025_conference.sty` | 9 頁 |

**通用規則**：雙盲審查、參考文獻不計入頁數、附錄無限制、要求使用 LaTeX。

模板位於 `templates/` 目錄中。參閱 [templates/README.md](templates/README.md) 了解編譯設置 (VS Code, CLI, Overleaf, 其他 IDEs)。

### 表格與圖表

**表格** — 使用 `booktabs` 進行專業格式化：

```latex
\usepackage{booktabs}
\begin{tabular}{lcc}
\toprule
Method & Accuracy $\uparrow$ & Latency $\downarrow$ \\
\midrule
Baseline & 85.2 & 45ms \\
\textbf{Ours} & \textbf{92.1} & 38ms \\
\bottomrule
\end{tabular}
```

規則：
- 針對每個指標將最佳值加粗
- 包含方向符號 ($\uparrow$ 越高越好, $\downarrow$ 越低越好)
- 數值欄位向右對齊
- 保持一致的小數位精度

**圖表**：
- 所有繪圖與圖解皆使用**向量圖** (PDF, EPS) — `plt.savefig('fig.pdf')`
- 僅對照片使用**點陣圖** (PNG 600 DPI)
- 使用**色盲友善的調色盤** (Okabe-Ito 或 Paul Tol)
- 驗證**灰階可讀性** (8% 的男性有色覺障礙)
- **圖表內不要有標題** — 圖說已承擔此功能
- **圖說應自成一體** — 讀者應在不看正文的情況下也能理解

### 會議重新提交

關於在不同發表場合之間轉換，請參閱階段 7 (提交準備) — 它涵蓋了完整的轉換工作流程、頁數變動表及被拒稿後的指導。

### 專業 LaTeX 導言區 (Professional LaTeX Preamble)

將這些套件添加到任何論文中以提升專業品質。它們與所有主要的會議樣式檔相容：

```latex
% --- Professional Packages (add after conference style file) ---

% Typography
\usepackage{microtype}              % 微排版改進 (突起、擴展)
                                     % 使文字顯著更加精緻 — 務必包含

% Tables
\usepackage{booktabs}               % 專業表格線條 (\toprule, \midrule, \bottomrule)
\usepackage{siunitx}                % 一致的數字格式、小數點對齊
                                     % 用法：\num{12345} → 12,345; \SI{3.5}{GHz} → 3.5 GHz
                                     % 表格對齊：小數點對齊數值的 S 欄位類型

% Figures
\usepackage{graphicx}               % 包含圖形 (\includegraphics)
\usepackage{subcaption}             % 帶有 (a), (b), (c) 標籤的子圖
                                     % 用法：\begin{subfigure}{0.48\textwidth} ... \end{subfigure}

% Diagrams and Algorithms
\usepackage{tikz}                   % 可程式化的向量圖解
\usetikzlibrary{arrows.meta, positioning, shapes.geometric, calc, fit, backgrounds}
\usepackage[ruled,vlined]{algorithm2e}  % 專業偽程式碼
                                     % 替代方案：若模板捆綁了 algorithmicx 則使用 \usepackage{algorithmicx}

% Cross-references
\usepackage{cleveref}               % 智慧引用：\cref{fig:x} → "Figure 1"
                                     % 務必在 hyperref 之後載入
                                     % 處理對象：圖、表、章節、等式、演算法

% Math (通常會議 .sty 已包含，但請驗證)
\usepackage{amsmath,amssymb}        % AMS 數學環境與符號
\usepackage{mathtools}              % 擴展 amsmath (dcases, coloneqq 等)

% Colors (針對圖表與圖解)
\usepackage{xcolor}                 % 顏色管理
% Okabe-Ito 色盲友善調色盤：
\definecolor{okblue}{HTML}{0072B2}
\definecolor{okorange}{HTML}{E69F00}
\definecolor{okgreen}{HTML}{009E73}
\definecolor{okred}{HTML}{D55E00}
\definecolor{okpurple}{HTML}{CC79A7}
\definecolor{okcyan}{HTML}{56B4E9}
\definecolor{okyellow}{HTML}{F0E442}
```

**備註：**
- `microtype` 是對視覺品質影響最大的單一套件。它在子像素層級調整字符間距。務必包含它。
- `siunitx` 透過 `S` 欄位類型處理表格中的小數點對齊 — 消除了手動調整間距的需要。
- `cleveref` 必須在 `hyperref` **之後**載入。大多數會議 .sty 檔案會載入 hyperref，因此將 cleveref 放在最後。
- 檢查會議模板是否已載入其中任何套件 (特別是 `algorithm`, `amsmath`, `graphicx`)。不要重複載入。

### siunitx 表格對齊

`siunitx` 讓充滿數字的表格可讀性顯著提升：

```latex
\begin{tabular}{l S[table-format=2.1] S[table-format=2.1] S[table-format=2.1]}
\toprule
Method & {Accuracy $\uparrow$} & {F1 $\uparrow$} & {Latency (ms) $\downarrow$} \\
\midrule
Baseline         & 85.2  & 83.7  & 45.3 \\
Ablation (no X)  & 87.1  & 85.4  & 42.1 \\
\textbf{Ours}    & \textbf{92.1} & \textbf{90.8} & \textbf{38.7} \\
\bottomrule
\end{tabular}
```

`S` 欄位類型會自動在小數點上對齊。使用 `{}` 包裹的標頭則會避開對齊。

### 子圖 (Subfigures)

並排圖表的標準模式：

```latex
\begin{figure}[t]
  \centering
  \begin{subfigure}[b]{0.48\textwidth}
    \centering
    \includegraphics[width=\textwidth]{fig_results_a.pdf}
    \caption{在資料集 A 上的結果。}
    \label{fig:results-a}
  \end{subfigure}
  \hfill
  \begin{subfigure}[b]{0.48\textwidth}
    \centering
    \includegraphics[width=\textwidth]{fig_results_b.pdf}
    \caption{在資料集 B 上的結果。}
    \label{fig:results-b}
  \end{subfigure}
  \caption{我們的方法在兩個資料集上的比較。(a) 顯示了縮放行為，(b) 顯示了消融實驗結果。兩者皆使用 5 個隨機種子。}
  \label{fig:results}
\end{figure}
```

使用 `\cref{fig:results}` → "Figure 1", `\cref{fig:results-a}` → "Figure 1a"。

### 使用 algorithm2e 編寫偽程式碼

```latex
\begin{algorithm}[t]
\caption{Iterative Refinement with Judge Panel}
\label{alg:method}
\KwIn{Task $T$, model $M$, judges $J_1 \ldots J_n$, convergence threshold $k$}
\KwOut{Final output $A^*$}
$A \gets M(T)$ \tcp*{Initial generation}
$\text{streak} \gets 0$\;
\While{$\text{streak} < k$}{
  $C \gets \text{Critic}(A, T)$ \tcp*{Identify weaknesses}
  $B \gets M(T, C)$ \tcp*{Revised version addressing critique}
  $AB \gets \text{Synthesize}(A, B)$ \tcp*{Merge best elements}
  \ForEach{judge $J_i$}{
    $\text{rank}_i \gets J_i(\text{shuffle}(A, B, AB))$ \tcp*{Blind ranking}
  }
  $\text{winner} \gets \text{BordaCount}(\text{ranks})$\;
  \eIf{$\text{winner} = A$}{
    $\text{streak} \gets \text{streak} + 1$\;
  }{
    $A \gets \text{winner}$; $\text{streak} \gets 0$\;
  }
}
\Return{$A$}\;
\end{algorithm}
```

### TikZ 圖解模式 (TikZ Diagram Patterns)

TikZ 是 ML 論文中方法圖的標準。常見模式：

**流程圖 (Pipeline/Flow Diagram)** (ML 論文中最常見)：

```latex
\begin{figure}[t]
\centering
\begin{tikzpicture}[
  node distance=1.8cm,
  box/.style={rectangle, draw, rounded corners, minimum height=1cm, 
              minimum width=2cm, align=center, font=\small},
  arrow/.style={-{Stealth[length=3mm]}, thick},
]
  \node[box, fill=okcyan!20] (input) {Input\\$x$};
  \node[box, fill=okblue!20, right of=input] (encoder) {Encoder\\$f_\theta$};
  \node[box, fill=okgreen!20, right of=encoder] (latent) {Latent\\$z$};
  \node[box, fill=okorange!20, right of=latent] (decoder) {Decoder\\$g_\phi$};
  \node[box, fill=okred!20, right of=decoder] (output) {Output\\$\hat{x}$};
  
  \draw[arrow] (input) -- (encoder);
  \draw[arrow] (encoder) -- (latent);
  \draw[arrow] (latent) -- (decoder);
  \draw[arrow] (decoder) -- (output);
\end{tikzpicture}
\caption{架構概覽。編碼器將輸入 $x$ 映射至潛在表示 $z$，解碼器對其進行重建。}
\label{fig:architecture}
\end{figure}
```

**對比/矩陣圖解 (Comparison/Matrix Diagram)** (用於顯示方法變體)：

```latex
\begin{tikzpicture}[
  cell/.style={rectangle, draw, minimum width=2.5cm, minimum height=1cm, 
               align=center, font=\small},
  header/.style={cell, fill=gray!20, font=\small\bfseries},
]
  % Headers
  \node[header] at (0, 0) {Method};
  \node[header] at (3, 0) {Converges?};
  \node[header] at (6, 0) {Quality?};
  % Rows
  \node[cell] at (0, -1) {Single Pass};
  \node[cell, fill=okgreen!15] at (3, -1) {N/A};
  \node[cell, fill=okorange!15] at (6, -1) {Baseline};
  \node[cell] at (0, -2) {Critique+Revise};
  \node[cell, fill=okred!15] at (3, -2) {No};
  \node[cell, fill=okred!15] at (6, -2) {Degrades};
  \node[cell] at (0, -3) {Ours};
  \node[cell, fill=okgreen!15] at (3, -3) {Yes ($k$=2)};
  \node[cell, fill=okgreen!15] at (6, -3) {Improves};
\end{tikzpicture}
```

**迭代迴圈圖解 (Iterative Loop Diagram)** (針對具有反饋的方法)：

```latex
\begin{tikzpicture}[
  node distance=2cm,
  box/.style={rectangle, draw, rounded corners, minimum height=0.8cm, 
              minimum width=1.8cm, align=center, font=\small},
  arrow/.style={-{Stealth[length=3mm]}, thick},
  label/.style={font=\scriptsize, midway, above},
]
  \node[box, fill=okblue!20] (gen) {Generator};
  \node[box, fill=okred!20, right=2.5cm of gen] (critic) {Critic};
  \node[box, fill=okgreen!20, below=1.5cm of $(gen)!0.5!(critic)$] (judge) {Judge Panel};
  
  \draw[arrow] (gen) -- node[label] {output $A$} (critic);
  \draw[arrow] (critic) -- node[label, right] {critique $C$} (judge);
  \draw[arrow] (judge) -| node[label, left, pos=0.3] {winner} (gen);
\end{tikzpicture}
```

### 使用 latexdiff 進行修訂追蹤

對於反駁 (rebuttals) 至關重要 — 產出一份標註有版本間更動的 PDF：

```bash
# 安裝
# macOS: brew install latexdiff (或隨附於 TeX Live)
# Linux: sudo apt install latexdiff

# 生成差異
latexdiff paper_v1.tex paper_v2.tex > paper_diff.tex
pdflatex paper_diff.tex

# 針對多檔案專案 (帶有 \input{} 或 \include{})
latexdiff --flatten paper_v1.tex paper_v2.tex > paper_diff.tex
```

這會產出一份 PDF，刪除內容為紅色刪除線，新增內容為藍色 — 這是反駁補充材料的標準格式。

### 針對 matplotlib 的 SciencePlots

安裝並使用以產出達到出版品質的繪圖：

```bash
pip install SciencePlots
```

```python
import matplotlib.pyplot as plt
import scienceplots  # 註冊樣式

# 使用 science 樣式 (類似 IEEE, 簡潔)
with plt.style.context(['science', 'no-latex']):
    fig, ax = plt.subplots(figsize=(3.5, 2.5))  # 單欄寬度
    ax.plot(x, y, label='Ours', color='#0072B2')
    ax.plot(x, y2, label='Baseline', color='#D55E00', linestyle='--')
    ax.set_xlabel('Training Steps')
    ax.set_ylabel('Accuracy')
    ax.legend()
    fig.savefig('paper/fig_results.pdf', bbox_inches='tight')

# 可用樣式：'science', 'ieee', 'nature', 'science+ieee'
# 若生成圖表的機器未安裝 LaTeX，請添加 'no-latex'
```

**標準圖表大小** (雙欄格式)：
- 單欄：`figsize=(3.5, 2.5)` — 適合放入一欄中
- 雙欄：`figsize=(7.0, 3.0)` — 橫跨兩欄
- 正方形：`figsize=(3.5, 3.5)` — 適合熱圖、混淆矩陣

---

## 階段 6: 自我審查與修訂 (Self-Review & Revision)

**目標**：在提交前模擬審查流程。儘早發現弱點。

### 步驟 6.1: 模擬審查 (整合模式 Ensemble Pattern)

從多個角度生成審查意見。來自自動化研究流程 (特別是 SakanaAI 的 AI-Scientist) 的關鍵洞察：**相較於單次審查，結合元審查員 (meta-reviewer) 的整合式審查能產出校準度更高的反饋。**

**步驟 1：生成 N 個獨立審查意見** (N=3-5)

使用不同的模型或溫度設定。每位審查員只看論文，不看其他人的審查。**預設為負面偏見** — LLMs 在評估中具有被廣泛記錄的正向偏見 (positivity bias)。

```
您是 [VENUE] 的專家審查員。您為人嚴謹且徹底。
若論文有弱點或您對某項聲明不確定，請清晰標出
並將其反映在您的評分中。不要給予疑點利益。

根據官方審查指南審核這篇論文。評估：

1. Soundness (聲明是否獲得良好支持？基準方法是否公平且強大？)
2. Clarity (論文是否寫得好？專家能否重現？)
3. Significance (這對社群重要嗎？)
4. Originality (是否有新見解，而不僅是漸進式的結合？)

以結構化的 JSON 提供您的審查：
{
  "summary": "2-3 句總結",
  "strengths": ["優點 1", "優點 2", ...],
  "weaknesses": ["弱點 1 (最關鍵)", "弱點 2", ...],
  "questions": ["給作者的問題 1", ...],
  "missing_references": ["應被引用的論文", ...],
  "soundness": 1-4,
  "presentation": 1-4,
  "contribution": 1-4,
  "overall": 1-10,
  "confidence": 1-5
}
```

**步驟 2：元審查 (Meta-review) (領域主席 Area Chair 彙整)**

將所有 N 個審查意見餵給元審查員：

```
您是 [VENUE] 的領域主席。您收到了對一篇論文的 [N] 份獨立審查意見。
您的工作是：

1. 識別出審查員之間共識的優點與弱點
2. 透過直接檢查論文來解決分歧
3. 產出一份代表綜合判斷的元審查
4. 使用所有審查意見的平均數值評分

保持保守：若審查員對於某個弱點是否嚴重存在分歧，
請將其視為嚴重問題，直到作者解決它為止。

Reviews:
[review_1]
[review_2]
...
```

**步驟 3：反思迴圈 (Reflection loop)** (選填，2-3 輪)

每位審查員在看到元審查後可以精煉自己的審查意見。使用提早終止符號：若審查員回應 "I am done" (無變動)，則停止迭代。

**審查的模型選擇**：審查最好使用最強大的可用模型，即使您是用較便宜的模型撰寫論文。審查模型應獨立於寫作模型。

**少樣本校準 (Few-shot calibration)**：若可行，包含 1-2 份來自目標發表場合的真實發表審查意見作為範例。這能顯著改善評分校準。參閱 [references/reviewer-guidelines_zh_TW.md](references/reviewer-guidelines_zh_TW.md) 了解範例審查意見。

### 步驟 6.1b: 視覺審查輪次 (VLM)

僅限文字的審查會漏掉一整類問題：圖表品質、排版問題、視覺一致性。如果您具備視覺能力的模型存取權，請對編譯後的 PDF 執行單獨的**視覺審查**：

```
您正在審核這篇研究論文 PDF 的視覺呈現。
檢查：
1. 圖表品質：繪圖是否可讀？標籤是否清晰？顏色是否易於區分？
2. 圖表-圖說對齊：每個圖說是否準確描述了對應的圖表？
3. 排版問題：孤立的章節標題、尷尬的分頁、圖表遠離其引用處
4. 表格格式：對齊的欄位、一致的小數位精度、最佳結果加粗
5. 視覺一致性：全篇圖表使用相同的配色方案、一致的字體大小
6. 灰階可讀性：若以黑白列印，圖表是否仍能被理解？

針對每個問題，請指明頁碼與確切位置。
```

這能捕捉到文字審查無法發現的問題：座標軸標籤不清晰的繪圖、距離首次引用處 3 頁遠的圖表、Figure 2 與 Figure 5 之間不一致的調色盤，或是明顯寬於欄寬的表格。

### 步驟 6.1c: 聲明驗證輪次 (Claim Verification Pass)

在模擬審查之後，執行單獨的驗證輪次。這能捕捉到審查員可能漏掉的事實錯誤：

```
Claim Verification Protocol:
1. 從論文中提取每個事實聲明 (數字、對比、趨勢)
2. 針對每個聲明，將其追溯至支持它的具體實驗/結果
3. 驗證論文中的數字與實際結果檔案相符
4. 將任何無法追溯來源的聲明標記為 [VERIFY]
```

針對代理型工作流程：將驗證委派給一個**全新的子代理**，該代理僅接收論文文字與原始結果檔案。全新的上下文能防止確認偏誤 (confirmation bias) — 驗證者不會「記得」結果應該是什麼。

### 步驟 6.2: 排定反饋優先級

收集審查意見後，進行分類：

| 優先級 | 行動 |
|----------|--------|
| **關鍵 (Critical)** (技術缺陷、缺失基準方法) | 必須修正。可能需要新的實驗 → 回到階段 2 |
| **高 (High)** (清晰度問題、缺失消融實驗) | 應在本次修訂中修正 |
| **中 (Medium)** (輕微寫作問題、額外實驗) | 若時間允許則修正 |
| **低 (Low)** (風格偏好、邊緣建議) | 記錄下來供未來工作參考 |

### 步驟 6.3: 修訂週期

針對每個關鍵/高優先級問題：
1. 識別受影響的具體章節
2. 起草修正方案
3. 驗證修正不會破壞其他聲明
4. 更新論文
5. 根據審查員的疑慮重新檢查

### 步驟 6.4: 撰寫反駁 (Rebuttal Writing)

在回應實際的審查意見時 (提交後)，撰寫反駁是不同於修訂的一種技能：

**格式**：逐點回應。針對每個審查員疑慮：
```
> R1-W1: "The paper lacks comparison with Method X."

We thank the reviewer for this suggestion. We have added a comparison with 
Method X in Table 3 (revised). Our method outperforms X by 3.2pp on [metric] 
(p<0.05). We note that X requires 2x our compute budget.
```

**規則**：
- 回應每一個疑慮 — 審查員會注意到您是否跳過了一項
- 以最強的回應開頭
- 保持簡潔直接 — 審查員會閱讀數十份反駁
- 如果您在反駁期間執行了實驗，請包含新結果
- 絕不要表現出防禦性或輕蔑，即使是微弱的批評
- 使用 `latexdiff` 生成一份標註有變動的 PDF (見專業 LaTeX 工具章節)
- 感謝審查員提供具體、可操作的反饋 (而非泛泛的讚美)

**切勿採取的行為**：在沒有證據的情況下說 "We respectfully disagree"。在沒有解釋的情況下說 "This is out of scope"。忽視弱點而只回應優點。

### 步驟 6.5: 論文演進追蹤

在關鍵里程碑儲存快照：
```
paper/
  paper.tex                    # 當前工作版本
  paper_v1_first_draft.tex     # 第一份完整草稿
  paper_v2_post_review.tex     # 模擬審查後
  paper_v3_pre_submission.tex  # 提交前的最終版
  paper_v4_camera_ready.tex    # 接受後的最終版
```

---

## 階段 7: 提交準備 (Submission Preparation)

**目標**：最終檢查、格式調整與提交。

### 步驟 7.1: 會議檢查表

每個發表場合都有強制性的檢查表。請仔細完成它們 — 不完整的檢查表可能導致直接拒稿。

參閱 [references/checklists_zh_TW.md](references/checklists_zh_TW.md) 了解：
- NeurIPS 16 項論文檢查表
- ICML 更廣泛影響 + 可重現性
- ICLR LLM 揭露政策
- ACL 強制性的限制章節
- 通用提交前檢查表

### 步驟 7.2: 匿名化檢查表 (Anonymization Checklist)

雙盲審查意味著審查員不能知道作者是誰。檢查以下所有項目：

```
Anonymization Checklist:
- [ ] PDF 中任何地方都沒有作者姓名或所屬機構
- [ ] 無致謝章節 (接受後再添加)
- [ ] 自我引用以第三人稱撰寫："Smith et al. [1] showed..." 而非 "We previously showed [1]..."
- [ ] 無指向您個人儲存庫的 GitHub/GitLab URL
- [ ] 對程式碼連結使用 Anonymous GitHub (https://anonymous.4open.science/)
- [ ] 圖表中無機構標誌或識別符
- [ ] 檔案元資料不包含作者姓名 (檢查 PDF 屬性)
- [ ] 無 "our previous work" 或 "in our earlier paper" 之類的措辭
- [ ] 資料集名稱不洩露機構 (若有需要請重新命名)
- [ ] 補充材料不包含識別資訊
```

**常見錯誤**：在補充程式碼中可見 Git 提交訊息、來自機構工具的帶浮水印圖表、從前一稿遺留下來的致謝、在匿名期前發布 arXiv 預印本。

### 步驟 7.3: 格式驗證

```
Pre-Submission Format Check:
- [ ] 遵守頁數限制 (不計參考文獻與附錄)
- [ ] 所有圖表皆為向量圖 (PDF) 或高解析度點陣圖 (600 DPI PNG)
- [ ] 所有圖表在灰階下皆可讀
- [ ] 所有表格皆使用 booktabs
- [ ] 參考文獻編譯正確 (引用中無 "?")
- [ ] 在關鍵區域無 overfull hbox
- [ ] 附錄已清晰標註且分離
- [ ] 必填章節已具備 (限制、更廣泛影響等)
```

### 步驟 7.4: 編譯前確效 (Pre-Compilation Validation)

在嘗試執行 `pdflatex` **之前**執行這些自動化檢查。在這裡捕捉錯誤比偵錯編譯器輸出更快。

```bash
# 1. 使用 chktex 進行 lint 檢查 (捕捉常見 LaTeX 錯誤)
# 抑制吵雜的警告：-n2 (句尾), -n24 (括號), -n13 (句間), -n1 (指令終止)
chktex main.tex -q -n2 -n24 -n13 -n1

# 2. 驗證所有引用都存在於 .bib 中
# 從 .tex 中提取 \cite{...}，逐一檢查 .bib
python3 -c "
import re
tex = open('main.tex').read()
bib = open('references.bib').read()
cites = set(re.findall(r'\\\\cite[tp]?{([^}]+)}', tex))
for cite_group in cites:
    for cite in cite_group.split(','):
        cite = cite.strip()
        if cite and cite not in bib:
            print(f'WARNING: \\\\cite{{{cite}}} not found in references.bib')
"

# 3. 驗證所有引用的圖表都存在於硬碟上
python3 -c "
import re, os
tex = open('main.tex').read()
figs = re.findall(r'\\\\includegraphics(?:\[.*?\])?{([^}]+)}', tex)
for fig in figs:
    if not os.path.exists(fig):
        print(f'WARNING: Figure file not found: {fig}')
"

# 4. 檢查重複的 \label 定義
python3 -c "
import re
from collections import Counter
tex = open('main.tex').read()
labels = re.findall(r'\\\\label{([^}]+)}', tex)
dupes = {k: v for k, v in Counter(labels).items() if v > 1}
for label, count in dupes.items():
    print(f'WARNING: Duplicate label: {label} (appears {count} times)')
"
```

在繼續前修復任何警告。針對代理型工作流程：將 chktex 輸出餵回給代理，並指示其進行最小幅度的修復。

### 步驟 7.5: 最終編譯

```bash
# 清理編譯
rm -f *.aux *.bbl *.blg *.log *.out *.pdf
latexmk -pdf main.tex

# 或手動 (執行三次 pdflatex + bibtex 以處理交叉引用)
pdflatex -interaction=nonstopmode main.tex
bibtex main
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex

# 驗證輸出是否存在且具有內容
ls -la main.pdf
```

**若編譯失敗**：解析 `.log` 檔案以找出第一個錯誤。常見修復：
- "Undefined control sequence" → 缺少套件或指令名稱拼寫錯誤
- "Missing $ inserted" → 數學符號出現在數學模式之外
- "File not found" → 圖表路徑錯誤或缺少 .sty 檔案
- "Citation undefined" → 缺少 .bib 條目或未執行 bibtex

### 步驟 7.6: 各大發表場合的特殊要求

| 發表場合 | 特殊要求 |
|-------|---------------------|
| **NeurIPS** | 附錄中需有論文檢查表，若被接受需提供平易近人的總結 |
| **ICML** | 更廣泛影響聲明 (放在結論後，不計入頁數限制) |
| **ICLR** | 要求揭露 LLM 的使用，互惠審查協議 |
| **ACL** | 強制性的限制 (Limitations) 章節，負責任的 NLP 檢查表 |
| **AAAI** | 嚴格的樣式檔 — 絕對不允許進行任何修改 |
| **COLM** | 針對語言模型社群建立貢獻框架 |

### 步驟 7.7: 會議重新提交與格式轉換

在不同發表場合之間進行轉換時，**絕不要將 LaTeX 導言區複製到新模板中**：

```bash
# 1. 從目標模板重新開始
cp -r templates/icml2026/ new_submission/

# 2. 僅複製內容章節 (而非導言區)
#    - 摘要文字、章節內容、圖表、表格、參考文獻條目

# 3. 根據頁數限制進行調整
# 4. 添加發表場合要求的必填章節
# 5. 更新參考文獻
```

| 原場合 → 新場合 | 頁數變動 | 關鍵調整 |
|-----------|-------------|-----------------|
| NeurIPS → ICML | 9 → 8 | 刪減 1 頁，添加更廣泛影響 |
| ICML → ICLR | 8 → 9 | 擴充實驗，添加 LLM 揭露 |
| NeurIPS → ACL | 9 → 8 | 根據 NLP 慣例重新結構化，添加限制 |
| ICLR → AAAI | 9 → 7 | 重大刪減，嚴格遵守樣式 |
| 任何場合 → COLM | 視情況 → 9 | 重新定調以專注於語言模型 |

當刪減頁數時：將證明移至附錄、縮減相關工作、合併表格、使用子圖。
當擴充頁數時：添加消融實驗、擴充限制說明、包含額外的基準方法、添加定性範例。

**被拒稿後**：在新版本中解決審查員的疑慮，但不要包含「更動」章節或提及之前的提交 (雙盲審查)。

### 步驟 7.8: Camera-Ready 準備 (接受後)

被接受後，準備 camera-ready 版本：

```
Camera-Ready Checklist:
- [ ] 去匿名化：添加作者姓名、所屬機構、電子郵件地址
- [ ] 添加致謝章節 (補助、算力捐贈、提供幫助的審查員)
- [ ] 添加公開的程式碼/資料 URL (真實的 GitHub，而非匿名的)
- [ ] 解決元審查員提出的任何強制性修訂
- [ ] 將模板切換至 camera-ready 模式 (若適用 — 例如 AAAI \anon → \camera)
- [ ] 若場合要求則添加版權聲明
- [ ] 更新文字中任何 "anonymous" 佔位符
- [ ] 驗證最終 PDF 能乾淨編譯
- [ ] 檢查 camera-ready 的頁數限制 (有時與提交時不同)
- [ ] 向會議入口網站上傳補充材料 (程式碼、資料、附錄)
```

### 步驟 7.9: arXiv 與預印本策略 (Preprint Strategy)

在 ML 領域將論文上傳至 arXiv 是標準做法，但有重要的時間與匿名性考量。

**時機決策樹：**

| 情況 | 建議 |
|-----------|---------------|
| 提交至雙盲發表場合 (NeurIPS, ICML, ACL) | 在提交截止日期**之後**上傳至 arXiv，而非之前。在之前發布技術上可能違反匿名性政策，儘管執行力度各異。 |
| 提交至 ICLR | ICLR 明確允許在提交前發布 arXiv。但在提交的文件本身中不要放入作者姓名。 |
| 論文已在 arXiv 上，正提交至新場合 | 在大多數場合都是可以接受的。在審查期間不要更新 arXiv 版本以包含引用審查意見的變動。 |
| 工作坊論文 | arXiv 隨時都可以發布 — 工作坊通常不是雙盲審查。 |
| 想要建立優先權 | 若擔心被搶先發表 (scooping) 則立即發布 — 但要接受匿名性的妥協。 |

**arXiv 類別選擇** (針對 ML/AI 論文)：

| 類別 | 代碼 | 最適合 |
|----------|------|----------|
| Machine Learning | `cs.LG` | 一般的 ML 方法 |
| Computation and Language | `cs.CL` | NLP, 語言模型 |
| Artificial Intelligence | `cs.AI` | 推理、規劃、代理人 |
| Computer Vision | `cs.CV` | 視覺模型 |
| Information Retrieval | `cs.IR` | 搜尋、推薦 |

**列出主要的 + 1-2 個交叉列出的類別。** 更多類別 = 更多曝光度，但僅限於真正相關的類別。

**版本策略：**
- **v1**：初始提交 (與會議提交相匹配)
- **v2**：帶有 camera-ready 修正的接受後版本 (在摘要中加入 "accepted at [Venue]")
- 審查期間不要發布包含明確回應審查員反饋的變動之 v2 版本。

```bash
# 在選擇標題前，檢查您的標題是否已在 arXiv 上被佔用
pip install arxiv
python -c "
import arxiv
results = list(arxiv.Search(query='ti:\"Your Exact Title\"', max_results=5).results())
print(f'Found {len(results)} matches')
for r in results: print(f'  {r.title} ({r.published.year})')
"
```

### 步驟 7.10: 研究程式碼封裝

發布乾淨、可執行的程式碼能顯著增加引用量與審查員的信任度。在提交 camera-ready 版本的同時封裝程式碼。

**儲存庫結構：**

```
your-method/
  README.md              # 設置、用法、重現說明
  requirements.txt       # 或針對 conda 的 environment.yml
  setup.py               # 針對可 pip 安裝的套件
  LICENSE                # 針對研究建議使用 MIT 或 Apache 2.0
  configs/               # 實驗設定
  src/                   # 核心方法實作
  scripts/               # 訓練、評估、分析腳本
    train.py
    evaluate.py
    reproduce_table1.sh  # 每個主要結果一個腳本
  data/                  # 小型資料或下載腳本
    download_data.sh
  results/               # 用於驗證的預期輸出
```

**研究程式碼的 README 模板：**

```markdown
# [Paper Title]

Official implementation of "[Paper Title]" (Venue Year).

## Setup
[Exact commands to set up environment]

## Reproduction
To reproduce Table 1: `bash scripts/reproduce_table1.sh`
To reproduce Figure 2: `python scripts/make_figure2.py`

## Citation
[BibTeX entry]
```

**發布前檢查表：**
```
- [ ] 程式碼能從乾淨的複製中執行 (在乾淨的機器或 Docker 上測試)
- [ ] 所有依賴項皆鎖定特定版本
- [ ] 無硬編碼的絕對路徑
- [ ] 儲存庫中無 API 金鑰、憑據或個人資料
- [ ] README 涵蓋了設置、重現與引用
- [ ] 具備 LICENSE 檔案 (為了最大化重用，推薦 MIT 或 Apache 2.0)
- [ ] 結果在預期變異範圍內可重現
- [ ] .gitignore 排除資料檔案、檢查點、日誌
```

**提交時的匿名程式碼** (接受前)：
```bash
# 針對雙盲審查使用 Anonymous GitHub
# https://anonymous.4open.science/
# 上傳您的儲存庫 → 取得匿名 URL → 放入論文中
```

---

## 階段 8: 接受後的交付物 (Post-Acceptance Deliverables)

**目標**：透過展示材料與社群參與，最大化您被接受論文的影響力。

### 步驟 8.1: 會議海報 (Conference Poster)

大多數會議要求進行海報展示。海報設計原則：

| 元素 | 指導原則 |
|---------|-----------|
| **大小** | 檢查發表場合的要求 (通常為 24"x36" 或 A0 縱向/橫向) |
| **內容** | 標題、作者、1 句話的貢獻、方法圖、2-3 個關鍵結果、結論 |
| **流向** | 左上至右下 (Z 字型) 或欄位式 |
| **文字** | 標題在 3m 外可讀，正文在 1m 外可讀。不要放整段文字 — 僅限點列式。 |
| **圖表** | 重新使用論文中的圖表但提高解析度。放大關鍵結果。 |

**工具**：LaTeX (`beamerposter` 套件)、PowerPoint/Keynote、Figma、Canva。

**製作**：在會議前 2 週以上訂購。布質海報較輕便於旅行。許多會議現在也支持虛擬/數位海報。

### 步驟 8.2: 會議演講 / Spotlight

若獲得口頭 (oral) 或 spotlight 報告機會：

| 演講類型 | 續航時間 | 內容 |
|-----------|----------|---------|
| **Spotlight** | 5 分鐘 | 問題、方法、一個關鍵結果。排練至精確 5 分鐘。 |
| **Oral** | 15-20 分鐘 | 完整故事：問題、方法、關鍵結果、消融實驗、限制。 |
| **工作坊演講** | 10-15 分鐘 | 根據工作坊受眾進行調整 — 可能需要更多背景知識。 |

**投影片設計規則：**
- 一張投影片一個想法
- 盡量減少文字 — 講述細節，而非投影它們
- 對關鍵圖表進行動畫處理，逐步建立理解
- 在結尾包含「要點 (takeaway)」投影片 (一句話的貢獻)
- 針對預期問題準備備用投影片

### 步驟 8.3: 部落格文章 / 社群媒體

易於理解的總結能顯著增加影響力：

- **Twitter/X 串文**：5-8 則推文。先講結果，而非方法。包含 Figure 1 與關鍵結果圖。
- **部落格文章**：800-1500 字。為 ML 從業人員而寫，而非審查員。跳過形式化描述，強調直覺與實際影響。
- **專案頁面**：帶有摘要、圖表、展示、程式碼連結、BibTeX 的 HTML 頁面。使用 GitHub Pages。

**時機**：在論文出現在會議論文集或 arXiv camera-ready 版後的 1-2 天內發布。

---

## 工作坊與短篇論文 (Workshop & Short Papers)

工作坊論文與短篇論文 (例如 ACL short papers, Findings papers) 遵循相同的流程，但具有不同的限制與期望。

### 工作坊論文

| 屬性 | 工作坊 | 主會議 |
|----------|----------|-----------------|
| **頁數限制** | 4-6 頁 (通常) | 7-9 頁 |
| **審查標準** | 對完整性的要求較低 | 必須完整、徹底 |
| **審查流程** | 通常為單盲或輕量化審查 | 雙盲、嚴謹 |
| **重視的內容** | 有趣的想法、初步結果、立場性文章 | 具備強大基準方法的完整實證故事 |
| **arXiv** | 隨時可以發布 | 時機至關重要 (見 arXiv 策略) |
| **貢獻門檻** | 新的方向、有趣的負面結果、進展中的工作 | 具備強大證據的重大進展 |

**何時將目標鎖定在工作坊：**
- 想要在完成完整論文前獲得反饋的早期階段想法
- 無法支撐 8 頁以上篇幅的負面結果
- 針對及時主題的立場性文章或觀點
- 複製性研究 (replication study) 或可重現性報告

### ACL 短篇論文與 Findings

ACL 發表場合有不同的提交類型：

| 類型 | 頁數 | 期望內容 |
|------|-------|-----------------|
| **長篇論文** | 8 | 完整的研究、強大的基準方法、消融實驗 |
| **短篇論文** | 4 | 專注的貢獻：一個帶有證據的清晰論點 |
| **Findings** | 8 | 扎實工作但稍遜於主會議的要求 |

**短篇論文策略**：挑選一個聲明並徹底地支持它。不要嘗試將長篇論文壓縮到 4 頁中 — 撰寫一篇不同且更專注的論文。

---

## 實證 ML 以外的論文類型 (Paper Types Beyond Empirical ML)

上述主要流程針對實證 ML 論文。其他論文類型需要不同的結構與證據標準。參閱 [references/paper-types_zh_TW.md](references/paper-types_zh_TW.md) 了解每種類型的詳細指導。

### 理論論文 (Theory Papers)

**結構**：簡介 → 預備知識 (定義、符號) → 主要結果 (定理) → 證明草圖 → 討論 → 完整證明 (附錄)

**與實證論文的關鍵差異：**
- 貢獻是一個定理、界限或不可能結果 — 而非實驗數據
- 「方法」章節由「預備知識」與「主要結果」取代
- 證明就是證據，而非實驗 (儘管對理論進行實證驗證是受歡迎的)
- 在主文中使用證明草圖、在附錄中使用完整證明是標準做法
- 實驗章節是選填，但若能驗證理論預測則能增強論文

**證明撰寫原則：**
- 正式陳述定理，並顯化所有假設
- 在正式證明前提供直覺 ("The key insight is...")
- 證明草圖應在 0.5-1 頁內傳達主要想法
- 使用 `\begin{proof}...\end{proof}` 環境
- 對假設進行編號並在定理中引用它們："Under Assumptions 1-3, ..."

### 綜述 / 教學論文 (Survey / Tutorial Papers)

**結構**：簡介 → 分類法 / 組織結構 → 詳細涵蓋範圍 → 開放式問題 → 結論

**關鍵差異：**
- 貢獻是組織結構、綜合分析與開放式問題的識別 — 而非新方法
- 在範圍內必須具有全面性 (審查員會檢查是否遺漏引用)
- 需要一個清晰的分類法或組織框架
- 價值來自於個別論文未建立的作品間聯繫
- 最佳發表場合：TMLR (survey 軌道), JMLR, Foundations and Trends in ML, ACM Computing Surveys

### 基準測試論文 (Benchmark Papers)

**結構**：簡介 → 任務定義 → 資料集構建 → 基準評估 → 分析 → 預期用途與限制

**關鍵差異：**
- 貢獻是基準測試本身 — 它必須填補真實的評估差距
- 資料集文件是強制性的，而非選填 (見資料單，步驟 5.11)
- 必須證明基準測試具有挑戰性 (基準方法不會使其飽和)
- 必須證明基準測試測量了您聲稱測量的內容 (構念效度 construct validity)
- 最佳發表場合：NeurIPS Datasets & Benchmarks 軌道, ACL (資源論文), LREC-COLING

### 立場論文 (Position Papers)

**結構**：簡介 → 背景 → 論點 / 主張 → 支持證據 → 反論點 → 影響

**關鍵差異：**
- 貢獻是一個論點，而非結果
- 必須認真處理反論點
- 證據可以是實證、理論或邏輯分析
- 最佳發表場合：ICML (position 軌道), 工作坊, TMLR

---

## Hermes 代理整合 (Hermes Agent Integration)

本技能專為 Hermes 代理設計。它利用 Hermes 工具、委派、排程與記憶體來處理完整的研究生命週期。

### 相關技能

將此技能與針對特定階段的其他 Hermes 技能組合使用：

| 技能 | 何時使用 | 如何載入 |
|-------|-------------|-------------|
| **arxiv** | 階段 1 (文獻回顧)：搜尋 arXiv、生成 BibTeX、透過 Semantic Scholar 尋找相關論文 | `skill_view("arxiv")` |
| **subagent-driven-development** | 階段 5 (起草)：平行進行章節寫作與兩階段審查 (規格合規性後接品質審查) | `skill_view("subagent-driven-development")` |
| **plan** | 階段 0 (設置)：在執行前建立結構化計劃。寫入 `.hermes/plans/` | `skill_view("plan")` |
| **qmd** | 階段 1 (文獻)：透過 BM25+向量混合搜尋本地知識庫 (筆記、逐字稿、文件) | 安裝：`skill_manage("install", "qmd")` |
| **diagramming** | 階段 4-5：建立基於 Excalidraw 的圖表與架構圖 | `skill_view("diagramming")` |
| **data-science** | 階段 4 (分析)：用於互動式分析與視覺化的 Jupyter 即時核心 | `skill_view("data-science")` |

**本技能取代了 `ml-paper-writing`** — 它包含了 ml-paper-writing 的所有內容，外加完整的實驗/分析流程與 autoreason 方法論。

### Hermes 工具參考

| 工具 | 在此流程中的用法 |
|------|----------------------|
| **`terminal`** | LaTeX 編譯 (`latexmk -pdf`)、git 操作、啟動實驗 (`nohup python run.py &`)、程序檢查 |
| **`process`** | 背景實驗管理：`process("start", ...)`、`process("poll", pid)`、`process("log", pid)`、`process("kill", pid)` |
| **`execute_code`** | 執行 Python 進行引用驗證、統計分析、資料聚合。具備透過 RPC 的工具存取權。 |
| **`read_file`** / **`write_file`** / **`patch`** | 論文編輯、實驗腳本、結果檔案。針對大型 .tex 檔案的針對性編輯使用 `patch`。 |
| **`web_search`** | 文獻探索：`web_search("transformer attention mechanism 2024")` |
| **`web_extract`** | 獲取論文內容、驗證引用：`web_extract("https://arxiv.org/abs/2303.17651")` |
| **`delegate_task`** | **平行章節起草** — 為每個章節產生隔離的子代理。也用於並行引用驗證。 |
| **`todo`** | 跨工作階段的主要狀態追蹤器。在每個階段轉換後更新。 |
| **`memory`** | 跨工作階段保存關鍵決策：貢獻定調、場合選擇、審查員反饋。 |
| **`cronjob`** | 安排實驗監控、截止日期倒數、自動化 arXiv 檢查。 |
| **`clarify`** | 當遇到阻礙時向用戶詢問針對性問題 (場合選擇、貢獻定調)。 |
| **`send_message`** | 當實驗完成或草擬就緒時通知用戶，即使其不在聊天中。 |

### 工具使用模式

**實驗監控** (最常見)：
```
terminal("ps aux | grep <pattern>")
→ terminal("tail -30 <logfile>")
→ terminal("ls results/")
→ execute_code("analyze results JSON, compute metrics")
→ terminal("git add -A && git commit -m '<descriptive message>' && git push")
→ send_message("Experiment complete: <summary>")
```

**平行章節起草** (使用委派)：
```
delegate_task("根據這些實驗腳本與設定起草「方法」章節。
  包含：偽程式碼、所有超參數、足以重現的架構細節。
  使用 neurips2025 模板慣例以 LaTeX 撰寫。")

delegate_task("起草「相關工作」章節。使用 web_search 與 web_extract 
  尋找論文。透過 Semantic Scholar 驗證每項引用。按方法論分組。")

delegate_task("起草「實驗」章節。讀取 results/ 下的所有結果檔案。
  陳述每個實驗支持哪個聲明。包含誤差線與顯著性。")
```

每個委派對象作為**全新的子代理**執行，無共享上下文 — 請在提示詞中提供所有必要資訊。收集輸出並進行整合。

**引用驗證** (使用 execute_code)：
```python
# 在 execute_code 中：
from semanticscholar import SemanticScholar
import requests

sch = SemanticScholar()
results = sch.search_paper("attention mechanism transformers", limit=5)
for paper in results:
    doi = paper.externalIds.get('DOI', 'N/A')
    if doi != 'N/A':
        bibtex = requests.get(f"https://doi.org/{doi}", 
                              headers={"Accept": "application/x-bibtex"}).text
        print(bibtex)
```

### 使用 `memory` 與 `todo` 進行狀態管理

**`memory` 工具** — 保存關鍵決策 (受限：MEMORY.md 約 2200 字元)：

```
memory("add", "Paper: autoreason. Venue: NeurIPS 2025 (9 pages). 
  Contribution: structured refinement works when generation-evaluation gap is wide.
  Key results: Haiku 42/42, Sonnet 3/5, S4.6 constrained 2/3.
  Status: Phase 5 — drafting Methods section.")
```

在重大決策或階段轉換後更新記憶。這會跨工作階段持久保存。

**`todo` 工具** — 追蹤細粒度進度：

```
todo("add", "針對 Sonnet 4.6 設計受限任務實驗")
todo("add", "執行 Haiku 基準方法對比")
todo("add", "起草方法章節")
todo("update", id=3, status="in_progress")
todo("update", id=1, status="completed")
```

**工作階段啟動協議：**
```
1. todo("list")                           # 檢查當前任務列表
2. memory("read")                         # 回想關鍵決策
3. terminal("git log --oneline -10")      # 檢查最近的提交
4. terminal("ps aux | grep python")       # 檢查正在執行的實驗
5. terminal("ls results/ | tail -20")     # 檢查新結果
6. 向用戶報告狀態，尋求指導
```

### 使用 `cronjob` 進行 Cron 監控

使用 `cronjob` 工具安排定期的實驗檢查：

```
cronjob("create", {
  "schedule": "*/30 * * * *",  # 每 30 分鐘
  "prompt": "檢查實驗狀態：
    1. ps aux | grep run_experiment
    2. tail -30 logs/experiment_haiku.log
    3. ls results/haiku_baselines/
    4. 若完成：讀取結果、計算 Borda 分數、
       git add -A && git commit -m 'Add Haiku results' && git push
    5. 報告：結果表格、關鍵發現、下一步
    6. 若無變動：回應 [SILENT]"
})
```

**[SILENT] 協議**：當自上次檢查以來無任何更動時，回應確切的 `[SILENT]`。這會抑制對用戶的通知發送。僅在有真正值得知道的變動時才報告。

**截止日期追蹤：**
```
cronjob("create", {
  "schedule": "0 9 * * *",  # 每天早上 9 點
  "prompt": "NeurIPS 2025 截止日期：5 月 22 日。今天是 {date}。
    剩餘天數：{compute}。
    檢查待辦事項列表 — 我們是否按進度進行？
    若 <7 天：就剩餘任務向用戶發出警告。"
})
```

### 溝通模式

**何時通知用戶** (透過 `send_message` 或直接回應)：
- 實驗批次完成 (附帶結果表)
- 需要決策的意外發現或失敗
- 章節草擬就緒可供審核
- 截止日期臨近且任務未完成

**何時不通知：**
- 實驗仍在執行，無新結果 → `[SILENT]`
- 無變動的例行監控 → `[SILENT]`
- 不需要關注的中間步驟

**報告格式** — 始終包含結構化數據：
```
## 實驗：<名稱>
狀態：完成 / 執行中 / 失敗

| 任務 | 方法 A | 方法 B | 方法 C |
|------|---------|---------|---------|
| Task 1 | 85.2 | 82.1 | **89.4** |

關鍵發現：<一句話>
下一步：<後續動作>
```

### 需要人類輸入的決策點

當真正遇到阻礙時，使用 `clarify` 提出針對性問題：

| 決策 | 何時詢問 |
|----------|-------------|
| 目標發表場合 | 開始寫論文前 (影響頁數限制、框架) |
| 貢獻定調 | 當存在多個有效的框架時 |
| 實驗優先級 | 當 TODO 列表中的實驗多於可用時間時 |
| 提交就緒度 | 最終提交前 |

**不要詢問以下內容** (應主動出擊，做出選擇，並標註它)：
- 用字選擇、章節排序
- 具體強調哪些結果
- 引用完整性 (以找到的內容起草，註明差距)

---

## 審查員評估標準

理解審查員關注的重點有助於集中精力：

| 準則 | 檢查重點 |
|-----------|----------------|
| **品質 (Quality)** | 技術嚴謹性、獲良好支持的聲明、公平的基準方法 |
| **清晰度 (Clarity)** | 清晰的寫作、專家可重現、符號一致性 |
| **意義 (Significance)** | 社群影響力、增進理解 |
| **創新性 (Originality)** | 新見解 (不需要全新的方法) |

**評分 (NeurIPS 6 分制)：**
- 6：強烈接受 (Strong Accept) — 具開創性、無暇
- 5：接受 (Accept) — 技術扎實、高影響力
- 4：邊緣接受 (Borderline Accept) — 扎實、評估有限
- 3：邊緣拒絕 (Borderline Reject) — 弱點大於優點
- 2：拒絕 (Reject) — 技術缺陷
- 1：強烈拒絕 (Strong Reject) — 已知結果或倫理問題

參閱 [references/reviewer-guidelines_zh_TW.md](references/reviewer-guidelines_zh_TW.md) 了解詳細準則、常見疑慮與反駁策略。

---

## 常見問題與解決方案

| 問題 | 解決方案 |
|-------|----------|
| 摘要太過通用 | 刪除第一句話，如果它可以放在任何 ML 論文前。從您的具體貢獻開始。 |
| 簡介超過 1.5 頁 | 將背景知識移至「相關工作」。將貢獻點列提到最前方。 |
| 實驗缺乏明確聲明 | 添加："此實驗測試 [具體聲明] 是否成立..." 在每個實驗前。 |
| 審查員認為論文難以理解 | 增加導引指示 (signposting)、使用一致的術語、使圖表圖說能自成一體。 |
| 缺失統計顯著性 | 添加誤差線、執行輪數、統計檢定、信賴區間。 |
| 實驗範圍蔓延 | 每個實驗必須對應一個特定聲明。刪減無關的實驗。 |
| 論文被拒，需要重新提交 | 參見階段 7 中的「會議重新提交」。在不引用審查意見的情況下解決審查員疑慮。 |
| 缺失更廣泛影響聲明 | 參見步驟 5.10。大多數場合皆有要求。"No negative impacts" 幾乎從不可信。 |
| 人類評估被批評太弱 | 參見步驟 2.5 與 [references/human-evaluation_zh_TW.md](references/human-evaluation_zh_TW.md)。報告一致性指標、標註者細節、報酬。 |
| 審查員質疑可重現性 | 發布程式碼 (步驟 7.9)、記錄所有超參數、包含種子與運算細節。 |
| 理論論文缺乏直覺 | 在正式證明前增加帶有平白語言解釋的證明草圖。參見 [references/paper-types_zh_TW.md](references/paper-types_zh_TW.md)。 |
| 結果是負面/虛無的 | 參見 4.3 節關於處理負面結果的內容。考慮投稿工作坊、TMLR 或重新定調為分析。 |

---

## 參考文件 (Reference Documents)

| 文件 | 內容 |
|----------|----------|
| [references/writing-guide_zh_TW.md](references/writing-guide_zh_TW.md) | Gopen & Swan 7 大原則、Perez 微觀技巧、Lipton 用字選擇、Steinhardt 精確性、圖表設計 |
| [references/citation-workflow_zh_TW.md](references/citation-workflow_zh_TW.md) | 引用 APIs、Python 程式碼、CitationManager 類別、BibTeX 管理 |
| [references/checklists_zh_TW.md](references/checklists_zh_TW.md) | NeurIPS 16 項、ICML、ICLR、ACL 要求、通用提交前檢查表 |
| [references/reviewer-guidelines_zh_TW.md](references/reviewer-guidelines_zh_TW.md) | 評估準則、評分、常見疑慮、反駁模板 |
| [references/sources_zh_TW.md](references/sources_zh_TW.md) | 所有寫作指南、會議準則、APIs 的完整參考書目 |
| [references/experiment-patterns_zh_TW.md](references/experiment-patterns_zh_TW.md) | 實驗設計模式、評估協議、監控、錯誤恢復 |
| [references/autoreason-methodology_zh_TW.md](references/autoreason-methodology_zh_TW.md) | Autoreason 迴圈、策略選擇、模型指南、提示詞、範圍限制、Borda 計分 |
| [references/human-evaluation_zh_TW.md](references/human-evaluation_zh_TW.md) | 人類評估設計、標註指南、一致性指標、群眾外包品質控制、IRB 指導 |
| [references/paper-types_zh_TW.md](references/paper-types_zh_TW.md) | 理論論文 (證明撰寫、定理結構)、綜述論文、基準測試論文、立場論文 |

### LaTeX 模板

在 `templates/` 中的模板：**NeurIPS 2025**, **ICML 2026**, **ICLR 2026**, **ACL**, **AAAI 2026**, **COLM 2025**。

參閱 [templates/README.md](templates/README.md) 了解編譯說明。

### 關鍵外部來源

**寫作哲學：**
- [Neel Nanda: How to Write ML Papers](https://www.alignmentforum.org/posts/eJGptPbbFPZGLpjsp/highly-opinionated-advice-on-how-to-write-ml-papers)
- [Sebastian Farquhar: How to Write ML Papers](https://sebastianfarquhar.com/on-research/2024/11/04/how_to_write_ml_papers/)
- [Gopen & Swan: Science of Scientific Writing](https://cseweb.ucsd.edu/~swanson/papers/science-of-writing.pdf)
- [Lipton: Heuristics for Scientific Writing](https://www.approximatelycorrect.com/2018/01/29/heuristics-technical-scientific-writing-machine-learning-perspective/)
- [Perez: Easy Paper Writing Tips](https://ethanperez.net/easy-paper-writing-tips/)

**APIs:** [Semantic Scholar](https://api.semanticscholar.org/api-docs/) | [CrossRef](https://www.crossref.org/documentation/retrieve-metadata/rest-api/) | [arXiv](https://info.arxiv.org/help/api/basics.html)

**發表場合：** [NeurIPS](https://neurips.cc/Conferences/2025/PaperInformation/StyleFiles) | [ICML](https://icml.cc/Conferences/2025/AuthorInstructions) | [ICLR](https://iclr.cc/Conferences/2026/AuthorGuide) | [ACL](https://github.com/acl-org/acl-style-files)
