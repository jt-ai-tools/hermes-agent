---
name: dogfood
description: Web 應用程式的系統化探索式 QA 測試 —— 尋找錯誤、擷取證據並產生結構化報告
version: 1.0.0
metadata:
  hermes:
    tags: [qa, testing, browser, web, dogfood]
    related_skills: []
---

# Dogfood: 系統化 Web 應用程式 QA 測試

## 總覽

本技能引導你使用瀏覽器工具集對 Web 應用程式進行系統化的探索式 QA 測試。你將導航應用程式、與元素互動、擷取問題證據，並產出結構化的錯誤報告。

## 先決條件

- 必須可使用瀏覽器工具集 (`browser_navigate`, `browser_snapshot`, `browser_click`, `browser_type`, `browser_vision`, `browser_console`, `browser_scroll`, `browser_back`, `browser_press`)
- 使用者提供目標 URL 和測試範圍

## 輸入

使用者提供：
1. **目標 URL** —— 測試的入口點
2. **範圍** —— 要關注哪些區域/功能（或輸入 "full site" 進行全面測試）
3. **輸出目錄**（選填） —— 儲存螢幕截圖和報告的位置（預設：`./dogfood-output`）

## 工作流程

遵循以下 5 階段系統化工作流程：

### 階段 1：計畫 (Plan)

1. 建立輸出目錄結構：
   ```
   {output_dir}/
   ├── screenshots/       # 證據螢幕截圖
   └── report.md          # 最終報告（在階段 5 產生）
   ```
2. 根據使用者輸入識別測試範圍。
3. 透過計畫要測試哪些頁面和功能來建立初步網站地圖：
   - 到達頁 (Landing page) / 首頁
   - 導航連結（頁首、頁尾、側邊欄）
   - 關鍵使用者流程（註冊、登入、搜尋、結帳等）
   - 表單與互動元素
   - 邊緣案例（空狀態、錯誤頁面、404 頁面）

### 階段 2：探索 (Explore)

針對計畫中的每個頁面或功能：

1. **導航**至該頁面：
   ```
   browser_navigate(url="https://example.com/page")
   ```

2. **擷取快照 (Snapshot)** 以了解 DOM 結構：
   ```
   browser_snapshot()
   ```

3. **檢查主控台 (Console)** 是否有 JavaScript 錯誤：
   ```
   browser_console(clear=true)
   ```
   在每次導航後以及每次重大互動後都要執行此操作。靜默的 JS 錯誤是高價值的發現。

4. **擷取具註解的螢幕截圖**以視覺化評估頁面並識別互動元素：
   ```
   browser_vision(question="描述頁面佈局，識別任何視覺問題、損壞的元素或無障礙疑慮", annotate=true)
   ```
   `annotate=true` 旗標會在互動元素上疊加編號 `[N]` 標籤。每個 `[N]` 都對應到後續瀏覽器指令的參考點 `@eN`。

5. **系統化測試互動元素**：
   - 點擊按鈕和連結：`browser_click(ref="@eN")`
   - 填寫表單：`browser_type(ref="@eN", text="test input")`
   - 測試鍵盤導航：`browser_press(key="Tab")`, `browser_press(key="Enter")`
   - 捲動內容：`browser_scroll(direction="down")`
   - 使用無效輸入測試表單驗證
   - 測試空值提交

6. **每次互動後**，檢查：
   - 主控台錯誤：`browser_console()`
   - 視覺變化：`browser_vision(question="互動後發生了什麼變化？")`
   - 預期行為 vs 實際行為

### 階段 3：收集證據 (Collect Evidence)

針對發現的每個問題：

1. **擷取螢幕截圖**顯示該問題：
   ```
   browser_vision(question="擷取並描述此頁面上可見的問題", annotate=false)
   ```
   儲存回應中的 `screenshot_path` —— 你將在報告中引用它。

2. **記錄細節**：
   - 發生問題的 URL
   - 重現步驟
   - 預期行為
   - 實際行為
   - 主控台錯誤（如有）
   - 螢幕截圖路徑

3. **分類問題**，使用問題分類法（參見 `references/issue-taxonomy_zh_TW.md`）：
   - 嚴重性：Critical (緊急) / High (高) / Medium (中) / Low (低)
   - 類別：Functional (功能) / Visual (視覺) / Accessibility (無障礙) / Console (主控台) / UX (使用者體驗) / Content (內容)

### 階段 4：歸類 (Categorize)

1. 審核所有收集到的問題。
2. 去重 —— 合併在不同地方呈現的相同錯誤。
3. 為每個問題分配最終的嚴重性和類別。
4. 按嚴重性排序（Critical 優先，然後是 High、Medium、Low）。
5. 按嚴重性和類別統計問題數量，用於執行摘要。

### 階段 5：報告 (Report)

使用 `templates/dogfood-report-template_zh_TW.md` 中的範本產生最終報告。

報告必須包含：
1. **執行摘要**：包含總問題數、按嚴重性劃分的細分以及測試範圍
2. **各別問題區段**：
   - 問題編號與標題
   - 嚴重性與類別徽章
   - 觀察到問題的 URL
   - 問題描述
   - 重現步驟
   - 預期 vs 實際行為
   - 螢幕截圖引用（使用 `MEDIA:<screenshot_path>` 顯示行內圖片）
   - 相關的主控台錯誤（如有）
3. **所有問題的摘要表**
4. **測試筆記** —— 測試了什麼、沒測試什麼、任何阻礙因素

將報告儲存至 `{output_dir}/report.md`。

## 工具參考

| 工具 | 用途 |
|------|---------|
| `browser_navigate` | 前往 URL |
| `browser_snapshot` | 獲取 DOM 文字快照 (無障礙樹) |
| `browser_click` | 透過參考點 (`@eN`) 或文字點擊元素 |
| `browser_type` | 在輸入欄位輸入文字 |
| `browser_scroll` | 在頁面上向上/下捲動 |
| `browser_back` | 在瀏覽器歷史記錄中返回 |
| `browser_press` | 按下鍵盤按鍵 |
| `browser_vision` | 螢幕截圖 + AI 分析；使用 `annotate=true` 獲取元素標籤 |
| `browser_console` | 獲取 JS 主控台輸出與錯誤 |

## 提示

- **導航後及重大互動後務必檢查 `browser_console()`。** 靜默的 JS 錯誤是最有價值的發現之一。
- 當你需要推論互動元素的位置或快照參考點不明確時，**在 `browser_vision` 中使用 `annotate=true`**。
- **使用有效與無效輸入進行測試** —— 表單驗證錯誤非常常見。
- **捲動長頁面** —— 第一屏以下的內容可能會有渲染問題。
- **測試導航流程** —— 從頭到尾點擊完成多步驟程序。
- 透過留意螢幕截圖中可見的佈局問題來**檢查響應式行為**。
- **別忘了邊緣案例**：空狀態、極長文字、特殊字元、快速點擊。
- 向使用者報告螢幕截圖時，包含 `MEDIA:<screenshot_path>` 以便他們能行內查看證據。
