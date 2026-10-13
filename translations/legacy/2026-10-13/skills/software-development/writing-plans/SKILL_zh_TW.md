---
name: writing-plans
description: 當你對於一個多步驟任務有規格或需求時使用。建立包含細分任務、確切檔案路徑與完整程式碼範例的全面實作計畫。
version: 1.1.0
author: Hermes Agent (改編自 obra/superpowers)
license: MIT
metadata:
  hermes:
    tags: [planning, design, implementation, workflow, documentation]
    related_skills: [subagent-driven-development, test-driven-development, requesting-code-review]
---

# 撰寫實作計畫 (Writing Implementation Plans)

## 概述

撰寫全面的實作計畫時，請假設實作者對目前的程式碼庫完全不了解，且其技術品味可能不穩定。請記錄他們所需的一切資訊：要動到哪些檔案、完整的程式碼、測試命令、要檢查的文件以及如何驗證。將任務拆解為「一口大小 (bite-sized)」的規模。遵循 DRY、YAGNI、TDD 原則，並維持頻繁的 commit。

假設實作者是一位有經驗的開發者，但對目前的工具集或問題領域幾乎一無所知。同時假設他們不太熟悉良好的測試設計。

**核心原則：** 一份好的計畫能讓實作變得顯而易見。如果實作者需要靠猜測，那計畫就是不完整的。

## 何時使用

**務必在以下情況前使用：**
- 實作多步驟的功能。
- 拆解複雜的需求。
- 透過 subagent-driven-development 將任務委派給子代理。

**不可跳過的情況：**
- 功能看起來很簡單（未經證實的假設常導致 Bug）。
- 即使計畫是由你親自實作（未來的你也需要指引）。
- 獨自工作時（文件化依然重要）。

## 「一口大小」任務粒度 (Bite-Sized Task Granularity)

**每個任務 = 2 到 5 分鐘專注工作的量。**

每一步都應是一個動作：
- 「撰寫失敗的測試」 — 步驟
- 「執行測試以確認其失敗」 — 步驟
- 「撰寫最少量的實作程式碼使測試通過」 — 步驟
- 「執行測試以確認其通過」 — 步驟
- 「Commit」 — 步驟

**太大了：**
```markdown
### 任務 1：建立身分驗證系統
[涉及 5 個檔案、50 行程式碼]
```

**合適的大小：**
```markdown
### 任務 1：建立具有 email 欄位的 User 模型
[1 個檔案、10 行程式碼]

### 任務 2：為 User 新增 password hash 欄位
[1 個檔案、8 行程式碼]

### 任務 3：建立密碼雜湊 (hashing) 工具
[1 個檔案、15 行程式碼]
```

## 計畫文件結構

### 標頭 (Required)

每份計畫「必須」以以下內容開頭：

```markdown
# [功能名稱] 實作計畫

> **給 Hermes：** 請使用 subagent-driven-development 技能來逐項執行此計畫任務。

**目標：** [用一句話描述要建置的內容]

**架構：** [用 2 到 3 句話說明實作方法]

**技術棧：** [關鍵技術/函式庫]

---
```

### 任務結構

每個任務遵循以下格式：

````markdown
### 任務 N：[具描述性的名稱]

**目標：** 此任務要達成的目的（一句話）

**檔案：**
- 建立：`確切/路徑/至/新檔案.py`
- 修改：`確切/路徑/至/現有檔案.py:45-67`（若已知，請註明行號）
- 測試：`tests/路徑/至/測試檔案.py`

**步驟 1：撰寫失敗的測試**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**步驟 2：執行測試並驗證其失敗**

執行：`pytest tests/path/test.py::test_specific_behavior -v`
預期結果：FAIL — 「function not defined」

**步驟 3：撰寫最少量的實作程式碼**

```python
def function(input):
    return expected
```

**步驟 4：執行測試並驗證其通過**

執行：`pytest tests/path/test.py::test_specific_behavior -v`
預期結果：PASS

**步驟 5：Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## 撰寫流程

### 步驟 1：理解需求

閱讀並理解：
- 功能需求
- 設計文件或使用者描述
- 驗收準則 (Acceptance criteria)
- 限制條件

### 步驟 2：探索程式碼庫

使用 Hermes 工具來了解專案：

```python
# 了解專案結構
search_files("*.py", target="files", path="src/")

# 查看類似的功能
search_files("similar_pattern", path="src/", file_glob="*.py")

# 檢查現有的測試
search_files("*.py", target="files", path="tests/")

# 閱讀關鍵檔案
read_file("src/app.py")
```

### 步驟 3：設計方法

決定：
- 架構模式
- 檔案組織結構
- 需要的依賴項目
- 測試策略

### 步驟 4：撰寫任務

依序建立任務：
1. 設定/基礎架構 (Infrastructure)
2. 核心功能（每個皆遵循 TDD）
3. 邊界情況 (Edge cases)
4. 整合
5. 清理/文件化

### 步驟 5：加入完整細節

針對每個任務，請包含：
- **確切的檔案路徑**（不要只寫「配置檔」，要寫 `src/config/settings.py`）
- **完整的程式碼範例**（不要只寫「新增驗證」，要提供實際程式碼）
- **確切的命令** 與預期輸出
- **驗證步驟**，證明該任務已完成並生效。

### 步驟 6：審查計畫

檢查：
- [ ] 任務是否具備順序性且邏輯通順。
- [ ] 每個任務是否為「一口大小」（2-5 分鐘）。
- [ ] 檔案路徑是否精確。
- [ ] 程式碼範例是否完整（可直接複製貼上）。
- [ ] 命令是否精確並附帶預期輸出。
- [ ] 是否無遺漏的上下文。
- [ ] 是否套用了 DRY、YAGNI、TDD 原則。

### 步驟 7：儲存計畫

```bash
mkdir -p docs/plans
# 將計畫儲存至 docs/plans/YYYY-MM-DD-feature-name.md
git add docs/plans/
git commit -m "docs: add implementation plan for [功能名稱]"
```

## 原則

### DRY (Don't Repeat Yourself)

**錯誤做法：** 在三個地方複製貼上相同的驗證邏輯。
**正確做法：** 擷取驗證函式，並在各處呼叫。

### YAGNI (You Aren't Gonna Need It)

**錯誤做法：** 為未來可能的需求預留「彈性」。
**正確做法：** 只實作目前需要的內容。

```python
# 錯誤做法 — 違反 YAGNI
class User:
    def __init__(self, name, email):
        self.name = name
        self.email = email
        self.preferences = {}  # 現在還不需要！
        self.metadata = {}     # 現在還不需要！

# 正確做法 — 遵循 YAGNI
class User:
    def __init__(self, name, email):
        self.name = name
        self.email = email
```

### TDD (Test-Driven Development)

每個會產生程式碼的任務都應包含完整的 TDD 循環：
1. 撰寫失敗的測試。
2. 執行並驗證其失敗。
3. 撰寫最少量的程式碼。
4. 執行並驗證其通過。

詳細資訊請參閱 `test-driven-development` 技能。

### 頻繁 Commit

在每個任務完成後進行 commit：
```bash
git add [files]
git commit -m "type: description"
```

## 常見錯誤

### 任務過於模糊

**錯誤做法：** 「新增身分驗證」
**正確做法：** 「建立具有 email 和 password_hash 欄位的 User 模型」

### 程式碼不完整

**錯誤做法：** 「步驟 1：新增驗證函式」
**正確做法：** 「步驟 1：新增驗證函式」，並隨後附上完整的函式程式碼。

### 缺少驗證

**錯誤做法：** 「步驟 3：測試其是否運作」
**正確做法：** 「步驟 3：執行 `pytest tests/test_auth.py -v`，預期結果：3 passed」

### 缺少檔案路徑

**錯誤做法：** 「建立模型檔案」
**正確做法：** 「建立：`src/models/user.py`」

## 執行交付 (Execution Handoff)

儲存計畫後，提供執行建議：

**「計畫已完成並儲存。準備好使用 subagent-driven-development 進行執行 — 我將為每個任務分派一個全新的子代理，並進行兩階段審查（規格符合度，隨後是程式碼品質）。請問是否繼續？」**

執行時，請使用 `subagent-driven-development` 技能：
- 每個任務使用全新的 `delegate_task` 並提供完整上下文。
- 每個任務完成後進行規格符合度審查。
- 規格通過後進行程式碼品質審查。
- 唯有兩項審查皆通過後才繼續下一項任務。

## 請記住

```
「一口大小」的任務（每個 2-5 分鐘）
確切的檔案路徑
完整的程式碼（可直接複製貼上）
確切的命令與預期輸出
驗證步驟
DRY, YAGNI, TDD
頻繁 Commit
```

**一份好的計畫能讓實作變得顯而易見。**
