---
name: subagent-driven-development
description: 用於執行具有獨立任務的實作計畫。針對每個任務分派全新的子代理 (delegate_task)，並進行兩階段審查（規格符合度與程式碼品質）。
version: 1.1.0
author: Hermes Agent (改編自 obra/superpowers)
license: MIT
metadata:
  hermes:
    tags: [delegation, subagent, implementation, workflow, parallel]
    related_skills: [writing-plans, requesting-code-review, test-driven-development]
---

# 子代理驅動開發 (Subagent-Driven Development)

## 概述

透過為每個任務分派全新的子代理，並配合系統化的兩階段審查，來執行實作計畫。

**核心原則：** 每個任務使用全新的子代理 + 兩階段審查（先規格、後品質）= 高品質、快速迭代。

## 何時使用

在以下情況下使用此技能：
- 你擁有一份實作計畫（來自 writing-plans 技能或使用者需求）。
- 任務大多彼此獨立。
- 品質與規格符合度 (spec compliance) 至關重要。
- 你希望在任務之間進行自動化審查。

**相對於手動執行的優勢：**
- 每個任務都有全新的上下文（不會因累積狀態而產生混淆）。
- 自動化審查流程能及早發現問題。
- 確保所有任務都有連貫的品質檢查。
- 子代理在開始工作前可以提出問題。

## 流程

### 1. 讀取並解析計畫

讀取計畫檔案。預先擷取所有任務及其完整的文字和上下文。建立一個待辦清單 (todo list)：

```python
# 讀取計畫
read_file("docs/plans/feature-plan.md")

# 建立包含所有任務的待辦清單
todo([
    {"id": "task-1", "content": "建立具有 email 欄位的 User 模型", "status": "pending"},
    {"id": "task-2", "content": "新增密碼雜湊 (hashing) 工具", "status": "pending"},
    {"id": "task-3", "content": "建立登入端點 (endpoint)", "status": "pending"},
])
```

**關鍵點：** 計畫只需讀取「一次」。擷取所有內容。不要讓子代理去讀取計畫檔案 — 應直接在上下文中提供完整的任務文字。

### 2. 逐項任務流程 (Per-Task Workflow)

針對計畫中的「每個」任務：

#### 步驟 1：分派實作子代理 (Implementer Subagent)

使用 `delegate_task` 並提供完整上下文：

```python
delegate_task(
    goal="執行任務 1：建立具有 email 和 password_hash 欄位的 User 模型",
    context="""
    來自計畫的任務：
    - 建立：src/models/user.py
    - 新增 User 類別，包含 email (str) 和 password_hash (str) 欄位
    - 使用 bcrypt 進行密碼雜湊
    - 包含用於偵錯的 __repr__

    遵循 TDD：
    1. 在 tests/models/test_user.py 中撰寫失敗的測試
    2. 執行：pytest tests/models/test_user.py -v (確認 FAIL)
    3. 撰寫最少量的實作程式碼
    4. 執行：pytest tests/models/test_user.py -v (確認 PASS)
    5. 執行：pytest tests/ -q (確認無迴歸)
    6. Commit：git add -A && git commit -m "feat: add User model with password hashing"

    專案上下文：
    - Python 3.11, Flask 應用程式位於 src/app.py
    - 現有模型位於 src/models/
    - 測試使用 pytest，從專案根目錄執行
    - bcrypt 已列在 requirements.txt 中
    """,
    toolsets=['terminal', 'file']
)
```

#### 步驟 2：分派規格符合度審查員 (Spec Compliance Reviewer)

實作者完成後，根據原始規格進行驗證：

```python
delegate_task(
    goal="審查實作是否符合計畫中的規格",
    context="""
    原始任務規格：
    - 建立包含 User 類別的 src/models/user.py
    - 欄位：email (str), password_hash (str)
    - 使用 bcrypt 進行密碼雜湊
    - 包含 __repr__

    檢查項：
    - [ ] 是否實作了規格中的所有要求？
    - [ ] 檔案路徑是否符合規格？
    - [ ] 函式簽章 (signatures) 是否符合規格？
    - [ ] 行為是否符合預期？
    - [ ] 是否未添加額外內容（無範疇蔓延 scope creep）？

    輸出：PASS 或列出需要修復的特定規格差距。
    """,
    toolsets=['file']
)
```

**如果發現規格問題：** 修復差距，然後重新執行規格審查。唯有符合規格後才能繼續。

#### 步驟 3：分派程式碼品質審查員 (Code Quality Reviewer)

通過規格符合度審查後：

```python
delegate_task(
    goal="審查任務 1 實作的程式碼品質",
    context="""
    待審查檔案：
    - src/models/user.py
    - tests/models/test_user.py

    檢查項：
    - [ ] 是否遵循專案慣例與風格？
    - [ ] 是否具備適當的錯誤處理？
    - [ ] 變數/函式命名是否清晰？
    - [ ] 測試涵蓋範圍是否足夠？
    - [ ] 是否無明顯 Bug 或遺漏的邊界情況？
    - [ ] 是否無安全問題？

    輸出格式：
    - 關鍵問題 (Critical Issues)：[繼續前必須修復]
    - 重要問題 (Important Issues)：[應該修復]
    - 次要問題 (Minor Issues)：[選填]
    - 判定結果 (Verdict)：APPROVED 或 REQUEST_CHANGES
    """,
    toolsets=['file']
)
```

**如果發現品質問題：** 修復問題，重新審查。唯有獲得核准後才能繼續。

#### 步驟 4：標記為完成

```python
todo([{"id": "task-1", "content": "建立具有 email 欄位的 User 模型", "status": "completed"}], merge=True)
```

### 3. 最終審查

當「所有」任務都完成後，分派一個最終整合審查員：

```python
delegate_task(
    goal="審查整個實作的一致性與整合問題",
    context="""
    計畫中的所有任務皆已完成。請審查完整實作：
    - 所有組件是否能協同運作？
    - 任務之間是否存在任何不一致之處？
    - 所有測試是否通過？
    - 是否準備好進行合併 (merge)？
    """,
    toolsets=['terminal', 'file']
)
```

### 4. 驗證與 Commit

```bash
# 執行完整測試套件
pytest tests/ -q

# 審查所有變更
git diff --stat

# 如有需要，進行最終 commit
git add -A && git commit -m "feat: complete [功能名稱] implementation"
```

## 任務粒度 (Task Granularity)

**每個任務 = 2 到 5 分鐘專注工作的量。**

**太大：**
- 「實作使用者身分驗證系統」

**合適大小：**
- 「建立具有 email 和 password 欄位的 User 模型」
- 「新增密碼雜湊函式」
- 「建立登入端點」
- 「新增 JWT token 產生功能」
- 「建立註冊端點」

## 警訊 — 絕對不要這樣做

- 在沒有計畫的情況下開始實作。
- 跳過審查（規格符合度或程式碼品質）。
- 在關鍵/重要問題未修復的情況下繼續後續任務。
- 為涉及相同檔案的任務分派多個實作子代理。
- 讓子代理去讀取計畫檔案（應在上下文中提供完整文字）。
- 跳過場景設定上下文（子代理需要了解任務所處的位置）。
- 忽略子代理的問題（應先回答問題再讓其繼續）。
- 在規格符合度上接受「差不多就好」。
- 跳過審查迴圈（審查員發現問題 → 實作者修復 → 再次審查）。
- 讓實作者的自我審查取代實際審查（兩者皆需要）。
- **在規格符合度通過「前」就開始程式碼品質審查**（順序錯誤）。
- 在任一審查仍有未解決問題時就移動到下一個任務。

## 處理問題

### 如果子代理提出問題

- 清晰且完整地回答。
- 如有需要，提供額外的上下文。
- 不要催促其開始實作。

### 如果審查員發現問題

- 由實作子代理（或新的子代理）進行修復。
- 審查員再次審查。
- 重複此過程直至獲得核准。
- 不要跳過重新審查的步驟。

### 如果子代理任務失敗

- 分派一個新的修復子代理，並針對錯誤處提供具體說明。
- 不要嘗試在控制台會話中手動修復（會造成上下文污染）。

## 效率說明

**為何每個任務使用全新的子代理：**
- 防止因累積狀態造成的上下文污染。
- 每個子代理都能獲得乾淨、專注的上下文。
- 不會受到先前任務的程式碼或推理干擾。

**為何採用兩階段審查：**
- 規格審查能及早發現實作不足或過度開發的問題。
- 品質審查確保實作架構良好。
- 在問題累積到後續任務前及早攔截。

**成本權衡：**
- 更多的子代理調用（每個任務需要實作者 + 2 個審查員）。
- 但能及早發現問題（這比稍後偵錯複雜的複合型問題更便宜）。

## 與其他技能的整合

### 與 writing-plans 整合

此技能「執行」由 writing-plans 技能建立的計畫：
1. 使用者需求 → writing-plans → 實作計畫
2. 實作計畫 → 子代理驅動開發 (subagent-driven-development) → 可運作的程式碼

### 與 test-driven-development 整合

實作子代理應遵循 TDD：
1. 先撰寫失敗的測試。
2. 實作最少量的程式碼。
3. 驗證測試通過。
4. Commit。

在每個實作者的上下文中都應包含 TDD 指令。

### 與 requesting-code-review 整合

兩階段審查流程本身「就是」程式碼審查。對於最終整合審查，可使用 requesting-code-review 技能中的審查維度。

### 與 systematic-debugging 整合

如果子代理在實作過程中遇到 Bug：
1. 遵循系統化偵錯 (systematic-debugging) 流程。
2. 在修復前找出根因。
3. 撰寫迴歸測試。
4. 恢復實作。

## 範例工作流

```
[讀取計畫：docs/plans/auth-feature.md]
[建立包含 5 個任務的待辦清單]

--- 任務 1：建立 User 模型 ---
[分派實作子代理]
  實作者：「email 欄位是否應為唯一值 (unique)？」
  你：「是的，email 必須唯一。」
  實作者：已實作，3/3 個測試通過，已 commit。

[分派規格審查員]
  規格審查員：✅ PASS — 符合所有要求

[分派品質審查員]
  品質審查員：✅ APPROVED — 程式碼乾淨，測試良好

[標記任務 1 為完成]

--- 任務 2：密碼雜湊 ---
[分派實作子代理]
  實作者：無問題，已實作，5/5 個測試通過。

[分派規格審查員]
  規格審查員：❌ 遺漏：密碼強度驗證（規格要求「至少 8 個字元」）

[實作者進行修復]
  實作者：已新增驗證，7/7 個測試通過。

[再次分派規格審查員]
  規格審查員：✅ PASS

[分派品質審查員]
  品質審查員：重要：出現魔術數字 8，應擷取為常數。
  實作者：已擷取 MIN_PASSWORD_LENGTH 常數。
  品質審查員：✅ APPROVED

[標記任務 2 為完成]

... (對所有任務重複此流程)

[所有任務完成後：分派最終整合審查員]
[執行完整測試套件：全部通過]
[完成！]
```

## 請記住

```
每個任務使用全新的子代理
每次都進行兩階段審查
規格符合度優先 (FIRST)
程式碼品質次之 (SECOND)
絕不跳過審查
及早攔截問題
```

**品質絕非偶然。它是系統化流程的結果。**
