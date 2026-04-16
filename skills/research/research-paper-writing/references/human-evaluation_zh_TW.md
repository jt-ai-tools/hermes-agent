# 機器學習/人工智慧研究的人類評估指南

本指南全面介紹了如何在機器學習（ML）和人工智慧（AI）論文中設計、運行及報告人類評估。人類評估是許多自然語言處理（NLP）、人機互動（HCI）及對齊（Alignment）論文的核心證據，且日益被視為所有機器學習領域的重要補充證據。

---

## 目錄

- [何時需要人類評估](#何時需要人類評估)
- [研究設計](#研究設計)
- [標註指南](#標註指南)
- [平台與招募](#平台與招募)
- [品質控制](#品質控制)
- [一致性指標](#一致性指標)
- [人類評估的統計分析](#人類評估的統計分析)
- [報告要求](#報告要求)
- [IRB 與倫理](#irb-與倫理)
- [常見陷阱](#常見陷阱)

---

## 何時需要人類評估

| 場景 | 是否需要人類評估？ | 備註 |
|----------|---------------------|-------|
| 文本生成品質（流暢度、連貫性） | **是** | 自動化指標（BLEU, ROUGE）與人類判斷的相關性較差 |
| 生成文本的事實準確性 | **強烈建議** | 自動化事實查核目前仍不可靠 |
| 安全性/毒性評估 | **針對細微案例是必要的** | 分類器常遺漏與語境相關的傷害 |
| 兩個系統間的偏好 | **是** | 比較 LLM 輸出最可靠的方法 |
| 摘要品質 | **是** | ROUGE 無法很好地捕捉忠實度或相關性 |
| 任務達成度（UI、代理程式） | **是** | 使用者研究是黃金標準 |
| 分類準確性 | **通常不需要** | 標準答案標籤已足夠；人類評估只會增加成本而無額外洞察 |
| 困惑度（Perplexity）或損失（Loss）比較 | **否** | 自動化指標才是正確的評估方式 |

---

## 研究設計

### 評估類型

| 類型 | 何時使用 | 優點 | 缺點 |
|------|-------------|------|------|
| **兩兩比較 (Pairwise comparison)** | 比較兩個系統 | 最可靠，能將量表偏誤降至最低 | 僅能成對比較，系統數量多時呈平方級增長 |
| **李克特量表 (Likert scale)** (1-5 或 1-7) | 評定單個輸出 | 易於匯總 | 主觀錨定效應（anchoring），量表壓縮（scale compression） |
| **排名 (Ranking)** | 對 3 個以上系統進行排序 | 捕捉完整的偏好順序 | 認知負荷隨項目增加而增加 |
| **最佳-最差縮放 (Best-worst scaling)** | 高效比較多個系統 | 比李克特量表更可靠，隨項目呈線性增長 | 需要仔細挑選項目 |
| **二元判斷 (Binary judgment)** | 是/否決策（文法正確？事實正確？） | 簡單，一致性高 | 失去細微差別 |
| **錯誤標註 (Error annotation)** | 識別特定的錯誤類型 | 提供豐富的診斷資訊 | 昂貴，需要受過培訓的標註員 |

**對大多數 ML 論文的建議**：兩兩比較是最具說服力的方法。審稿人很少會質疑其有效性。對於李克特量表，務必同時報告平均值與分佈。

### 樣本量規劃

**最小可行樣本量：**

| 研究類型 | 最小項目數 | 最小標註員數 | 備註 |
|------------|--------------|-------------------|-------|
| 兩兩比較 | 100 對 | 每對 3 名 | 可在 p<0.05 下偵測到約 10% 的勝率差異 |
| 李克特評分 | 100 項 | 每項 3 名 | 足以獲得具意義的平均值 |
| 排名 | 50 組 | 每組 3 名 | 每組包含所有待比較的系統 |
| 錯誤標註 | 200 項 | 每項 2 名 | 結構化方案應預期有更高的一致性 |

**檢定力分析 (Power analysis)**（用於更精確的規劃）：

```python
from scipy import stats
import numpy as np

def sample_size_pairwise(effect_size=0.10, alpha=0.05, power=0.80):
    """
    估算兩兩比較的樣本量（符號檢定）。
    effect_size: 預期的勝率與 0.50 的差異
    """
    p_expected = 0.50 + effect_size
    # 二項分佈的正態近似
    z_alpha = stats.norm.ppf(1 - alpha / 2)
    z_beta = stats.norm.ppf(power)
    n = ((z_alpha * np.sqrt(0.25) + z_beta * np.sqrt(p_expected * (1 - p_expected))) ** 2) / (effect_size ** 2)
    return int(np.ceil(n))

print(f"10% 效應值的樣本量：{sample_size_pairwise(0.10)}")  # 約 200
print(f"15% 效應值的樣本量：{sample_size_pairwise(0.15)}")  # 約 90
print(f"20% 效應值的樣本量：{sample_size_pairwise(0.20)}")  # 約 50
```

### 偏誤控制

| 偏誤類型 | 緩解措施 |
|------|-----------|
| **順序偏誤**（傾向第一個項目） | 對每位標註員隨機化呈現順序 |
| **長度偏誤**（越長越好） | 控制字數或分開進行分析 |
| **錨定效應**（首個標註設定了標準） | 包含不計分的練習項目 |
| **疲勞效應**（品質隨時間下降） | 限制單次時間（最長 30-45 分鐘），隨機化項目順序 |
| **標註員專業度** | 報告標註員背景；使用資格測試任務 |

---

## 標註指南

撰寫良好的標註指南是決定評估品質的最單一關鍵因素。請在此投入大量時間。

### 優秀指南的結構

```markdown
# [任務名稱] 標註指南

## 概述
[用 1-2 句話描述任務]

## 定義
[定義標註員判斷時會用到的所有術語]
- 品質：[本研究中的具體定義]
- 流暢度：[具體定義]
- 事實性：[具體定義]

## 評分量表
[針對每個量表點，提供：]
- 數值
- 標籤（例如：「優秀」、「良好」、「可接受」、「較差」、「不可接受」）
- 獲得此評分的定義準則
- 1-2 個該層級的具體範例

## 範例

### 範例 1：[評分 = 5]
輸入：[精確輸入]
輸出：[精確輸出]
評分：5
解釋：[為什麼評為 5 分]

### 範例 2：[評分 = 2]
輸入：[精確輸入]
輸出：[精確輸出]
評分：2
解釋：[為什麼評為 2 分]

[每個評分等級至少包含 2 個範例，並涵蓋邊緣案例]

## 邊緣案例
- 如果輸出是 [模糊案例]：[處理指令]
- 如果輸入是 [異常案例]：[處理指令]

## 常見錯誤
- 不要 [標註員常犯的錯誤]
- 不要讓 [偏誤] 影響您的評分
```

### 試驗運行 (Pilot Testing)

在正式研究之前，**務必進行試驗運行**：
1. 招募 3-5 名標註員，選取 20-30 個項目。
2. 計算一致性指標。
3. 在小組會議中討論分歧點。
4. 根據混淆點修訂指南。
5. 若一致性過低（kappa < 0.40），進行第二次試驗運行。

---

## 平台與招募

| 平台 | 最適合 | 成本 | 品質 |
|----------|----------|------|---------|
| **Prolific** | 一般標註、問卷調查 | $8-15/hr | 高（專注於學術的參與者群體） |
| **Amazon MTurk** | 大規模簡單任務 | $5-12/hr | 不穩定（需要強力的品質控制） |
| **Surge AI** | NLP 特定標註 | $15-25/hr | 非常高（受過培訓的標註員） |
| **Scale AI** | 生產級標註 | 變動 | 高（受管理的勞動力） |
| **內部團隊** | 需要領域專業知識時 | 變動 | 針對專業任務品質最高 |
| **Upwork/承包商** | 長期標註專案 | $10-30/hr | 取決於招聘品質 |

**公平補酬**：務必支付至少等同於標註員所在地最低工資的報酬。許多會議（特別是 ACL）現在會詢問標註員的補酬情況。支付低於最低工資會有倫理風險。

**Prolific 設定（推薦用於大多數 ML 論文）：**
1. 在 prolific.co 建立研究。
2. 設定預篩選過濾器（語言、國家、批准率 >95%）。
3. 根據試驗運行估計每項任務的時間 → 設定公平的報酬。
4. 使用 Prolific 內建的注意力檢查或添加自訂檢查。
5. 收集 Prolific ID 以進行品質追蹤（但不要在論文中公開）。

---

## 品質控制

### 注意力檢查 (Attention Checks)

包含正確答案明確的項目：

```python
# 注意力檢查的類型
attention_checks = {
    "instructed_response": "對於此項，請無視內容並選擇『非常同意』。",
    "obvious_quality": "評定這段明顯不通順的文字：『貓狗房子綠色昨天。』",  # 應獲得最低分
    "gold_standard": "專家已有共識的項目（由作者預先標註）",
    "trap_question": "晴天的天空是什麼顏色？（嵌入在標註介面中）"
}

# 建議：總項目中應包含 10-15% 的檢查項
# 排除標準：失敗 2 次以上注意力檢查 → 排除該標註員
```

### 標註員資格審核

針對需要專業知識的任務：

```
資格任務設計：
1. 建立一組 20-30 個具有正確標籤的項目。
2. 要求標註員在正式任務前完成此項。
3. 設定門檻：與標準標籤的一致性 ≥80% 始具備資格。
4. 記錄資格分數以便在報告中使用。
```

### 收集過程中的監控

```python
# 即時品質監控
def monitor_quality(annotations):
    """在收集過程中檢查標註品質問題。"""
    issues = []
    
    # 1. 檢查直線性標註 (Straight-lining)（所有答案都一樣）
    for annotator_id, items in annotations.groupby('annotator'):
        if items['rating'].nunique() <= 1:
            issues.append(f"標註員 {annotator_id}：偵測到直線性標註")
    
    # 2. 檢查每項花費時間（太快 = 沒在看）
    median_time = annotations['time_seconds'].median()
    fast_annotators = annotations.groupby('annotator')['time_seconds'].median()
    for ann_id, time in fast_annotators.items():
        if time < median_time * 0.3:
            issues.append(f"標註員 {ann_id}：速度異常快 ({time:.0f}s vs 中位數 {median_time:.0f}s)")
    
    # 3. 檢查注意力檢查的表現
    checks = annotations[annotations['is_attention_check']]
    for ann_id, items in checks.groupby('annotator'):
        accuracy = (items['rating'] == items['gold_rating']).mean()
        if accuracy < 0.80:
            issues.append(f"標註員 {ann_id}：注意力檢查失敗 ({accuracy:.0%})")
    
    return issues
```

---

## 一致性指標

### 應使用哪種指標

| 指標 | 何時使用 | 解讀 |
|--------|-------------|---------------|
| **Cohen's kappa (κ)** | 恰好 2 名標註員，類別型 | 排除偶然性後的一致性 |
| **Fleiss' kappa** | 3 名以上標註員，皆評定相同項目，類別型 | Cohen's kappa 的多標註員擴展版 |
| **Krippendorff's alpha (α)** | 任何數量的標註員，可處理缺失數據 | 最通用；推薦作為預設值 |
| **ICC (Intraclass Correlation)** | 連續評分（李克特量表） | 評分者間的一致性 |
| **百分比一致性 (Percent agreement)** | 與 kappa/alpha 一併報告 | 原始一致性（未排除偶然性） |
| **Kendall's W** | 排名 | 排名者間的諧和度 |

**務必至少報告兩項**：一項排除偶然性的指標（kappa 或 alpha）以及原始的百分比一致性。

### 解讀指南

| 數值 | Krippendorff's α / Cohen's κ | 品質 |
|-------|-------------------------------|---------|
| > 0.80 | 卓越的一致性 | 對大多數用途皆屬可靠 |
| 0.67 - 0.80 | 良好的一致性 | 對大多數 ML 論文皆可接受 |
| 0.40 - 0.67 | 中度的一致性 | 臨界狀態；需在論文中討論 |
| < 0.40 | 較差的一致性 | 應修訂指南並重新進行標註 |

**註記**：Krippendorff 建議 α > 0.667 作為得出初步結論的最低門檻。涉及主觀判斷（流暢度、幫助程度）的 NLP 任務通常達到 0.40-0.70。

### 程式碼實現

```python
import numpy as np
from sklearn.metrics import cohen_kappa_score
import krippendorff  # pip install krippendorff

def compute_agreement(annotations_matrix):
    """
    annotations_matrix: 形狀為 (n_items, n_annotators)
    值為評分 (int 或 float)。缺失值使用 np.nan。
    """
    results = {}
    
    # Krippendorff's alpha（處理缺失數據，支援任意標註員數量）
    results['krippendorff_alpha'] = krippendorff.alpha(
        annotations_matrix.T,  # krippendorff 預期格式為 (annotators, items)
        level_of_measurement='ordinal'  # 或 'nominal', 'interval', 'ratio'
    )
    
    # 兩兩 Cohen's kappa（一次針對 2 名標註員）
    n_annotators = annotations_matrix.shape[1]
    kappas = []
    for i in range(n_annotators):
        for j in range(i + 1, n_annotators):
            mask = ~np.isnan(annotations_matrix[:, i]) & ~np.isnan(annotations_matrix[:, j])
            if mask.sum() > 0:
                k = cohen_kappa_score(
                    annotations_matrix[mask, i].astype(int),
                    annotations_matrix[mask, j].astype(int)
                )
                kappas.append(k)
    results['mean_pairwise_kappa'] = np.mean(kappas) if kappas else None
    
    # 原始百分比一致性
    agree_count = 0
    total_count = 0
    for item in range(annotations_matrix.shape[0]):
        ratings = annotations_matrix[item, ~np.isnan(annotations_matrix[item, :])]
        if len(ratings) >= 2:
            # 所有標註員皆一致
            if len(set(ratings.astype(int))) == 1:
                agree_count += 1
            total_count += 1
    results['percent_agreement'] = agree_count / total_count if total_count > 0 else None
    
    return results
```

---

## 人類評估的統計分析

### 兩兩比較

```python
from scipy import stats

def analyze_pairwise(wins_a, wins_b, ties=0):
    """
    分析兩兩比較結果。
    wins_a: 系統 A 勝出的次數
    wins_b: 系統 B 勝出的次數
    ties: 平局次數（從符號檢定中排除）
    """
    n = wins_a + wins_b  # 排除平局
    
    # 符號檢定 (Sign test, 精確二項檢定)
    p_value = stats.binom_test(wins_a, n, 0.5, alternative='two-sided')
    
    # 帶有 95% CI 的勝率 (Wilson score interval)
    win_rate = wins_a / n if n > 0 else 0.5
    z = 1.96
    denominator = 1 + z**2 / n
    center = (win_rate + z**2 / (2 * n)) / denominator
    margin = z * np.sqrt((win_rate * (1 - win_rate) + z**2 / (4 * n)) / n) / denominator
    ci_lower = center - margin
    ci_upper = center + margin
    
    return {
        'win_rate_a': win_rate,
        'win_rate_b': 1 - win_rate,
        'p_value': p_value,
        'ci_95': (ci_lower, ci_upper),
        'significant': p_value < 0.05,
        'n_comparisons': n,
        'ties': ties,
    }
```

### 李克特量表分析

```python
def analyze_likert(ratings_a, ratings_b):
    """比較兩個系統間的李克特評分（配對數據）。"""
    # Wilcoxon 符號秩檢定（無母數，配對）
    stat, p_value = stats.wilcoxon(ratings_a, ratings_b, alternative='two-sided')
    
    # 效應值 (Rank-biserial correlation)
    n = len(ratings_a)
    r = 1 - (2 * stat) / (n * (n + 1))
    
    return {
        'mean_a': np.mean(ratings_a),
        'mean_b': np.mean(ratings_b),
        'std_a': np.std(ratings_a),
        'std_b': np.std(ratings_b),
        'wilcoxon_stat': stat,
        'p_value': p_value,
        'effect_size_r': r,
        'significant': p_value < 0.05,
    }
```

### 多重比較校正

當比較超過兩個系統時：

```python
from statsmodels.stats.multitest import multipletests

# 在計算所有成對比較的 p 值後
p_values = [0.03, 0.001, 0.08, 0.04, 0.15, 0.002]
rejected, corrected_p, _, _ = multipletests(p_values, method='holm')
# 在論文中使用校正後的 p 值
```

---

## 報告要求

NLP 領域的會議（ACL, EMNLP, NAACL）審稿人會檢查以下所有項。ML 領域的會議（NeurIPS, ICML）也日益要求這些內容。

### 強制性報告項

```latex
% 在論文的人類評估章節中：
\paragraph{Annotators.} 我們透過 [平台] 招募了 [N] 名標註員。
[描述資格或篩選過程。] 標註員的補酬為每小時 [X] 美元，
高於 [國家] 的最低工資。

\paragraph{Agreement.} 標註員間的一致性為 [指標] = [數值]
(Krippendorff's $\alpha$ = [數值]; 原始一致性 = [數值]\%)。
[若一致性較低：解釋為何該任務具有主觀性，以及您如何處理分歧。]

\paragraph{Evaluation Protocol.} 每個 [項目類型] 由 [N] 名標註員
在 [量表描述] 上進行評定。我們在 [N 個項目] 中共收集了 [總數] 條標註。
[描述隨機化與盲測過程。]
```

### 應放入附錄的內容

```
附錄：人類評估詳情
- 完整標註指南（逐字稿）
- 標註介面的截圖
- 資格任務細節與門檻
- 注意力檢查項目與失敗率
- 每位標註員的一致性分析
- 完整結果表格（而不僅是平均值）
- 補酬計算方式
- IRB 批准編號（若適用）
```

---

## IRB 與倫理

### 何時需要 IRB 批准

| 情況 | 是否需要 IRB？ |
|-----------|---------------|
| 群眾外包人員評定文本品質 | **通常不需要**（在大多數機構中不被視為「人類受試者研究」） |
| 涉及真實使用者的使用者研究 | **是**（在大多數美、歐機構中） |
| 收集個人資訊 | **是** |
| 研究標註員的行為/認知 | **是**（標註員本身成為研究對象） |
| 使用現有的已標註數據 | **通常不需要**（次級數據分析） |

**請檢查您所屬機構的政策。**「人類受試者研究」的定義各有不同。如有疑慮，請提交 IRB 方案——對於極低風險的研究，審核通常很快。

### 人類評估的倫理檢查清單

```
- [ ] 標註員已被告知任務目的（非誤導性）
- [ ] 標註員可隨時退出且不受懲罰
- [ ] 除了平台 ID 外，未收集任何可識別個人身分的資訊 (PII)
- [ ] 被評估的內容不會使標註員暴露於傷害中
  （若有：提供內容警告 + 退出機制 + 更高補酬）
- [ ] 公平補酬（≥ 所在地最低工資）
- [ ] 數據安全存儲，存取權限僅限研究團隊
- [ ] 若所屬機構要求，已取得 IRB 批准
```

---

## 常見陷阱

| 陷阱 | 問題點 | 修正方法 |
|---------|---------|-----|
| 標註員太少 (1-2 名) | 無法計算一致性指標 | 每個項目至少 3 名標註員 |
| 無注意力檢查 | 無法偵測低品質標註 | 包含 10-15% 的注意力檢查項 |
| 未報告補酬情況 | 審稿人會質疑倫理問題 | 務必報告時薪 |
| 僅對生成內容使用自動化指標 | 審稿人會要求人類評估 | 至少增加兩兩比較評估 |
| 未對指南進行試驗運行 | 一致性低，浪費預算 | 務必先與 3-5 人進行試驗運行 |
| 僅報告平均值 | 掩蓋了標註員間的分歧 | 同時報告分佈與一致性指標 |
| 未控制順序/位置 | 位置偏誤會扭曲結果 | 隨機化呈現順序 |
| 將標註員一致性與標準答案混為一談 | 高一致性不代表正確 | 應與專家判斷進行驗證 |
