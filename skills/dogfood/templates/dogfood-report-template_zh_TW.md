# Dogfood QA 報告

**目標：** {target_url}
**日期：** {date}
**範圍：** {scope_description}
**測試員：** Hermes Agent (自動化探索式 QA)

---

## 執行摘要 (Executive Summary)

| 嚴重性 | 數量 |
|----------|-------|
| 🔴 Critical (緊急) | {critical_count} |
| 🟠 High (高) | {high_count} |
| 🟡 Medium (中) | {medium_count} |
| 🔵 Low (低) | {low_count} |
| **總計** | **{total_count}** |

**整體評估：** {one_sentence_assessment}

---

## 問題詳情 (Issues)

<!-- 重複此區段以記錄發現的每個問題，按嚴重性排序（Critical 優先） -->

### 問題 #{issue_number}：{issue_title}

| 欄位 | 數值 |
|-------|-------|
| **嚴重性** | {severity} |
| **類別** | {category} |
| **URL** | {url_where_found} |

**描述：**
{detailed_description_of_the_issue}

**重現步驟：**
1. {step_1}
2. {step_2}
3. {step_3}

**預期行為：**
{what_should_happen}

**實際行為：**
{what_actually_happens}

**螢幕截圖：**
MEDIA:{screenshot_path}

**主控台錯誤**（如適用）：
```
{console_error_output}
```

---

<!-- 問題詳情區段結束 -->

## 問題摘要表 (Issues Summary Table)

| # | 標題 | 嚴重性 | 類別 | URL |
|---|-------|----------|----------|-----|
| {n} | {title} | {severity} | {category} | {url} |

## 測試覆蓋範圍 (Testing Coverage)

### 已測試頁面
- {list_of_pages_visited}

### 已測試功能
- {list_of_features_exercised}

### 未測試 / 超出範圍
- {areas_not_covered_and_why}

### 阻礙因素 (Blockers)
- {any_issues_that_prevented_testing_certain_areas}

---

## 備註 (Notes)

{any_additional_observations_or_recommendations}
