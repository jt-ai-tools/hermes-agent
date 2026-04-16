---
name: canvas
description: Canvas LMS 整合 — 使用 API 權杖認證獲取已選修課程與作業。
version: 1.0.0
author: community
license: MIT
prerequisites:
  env_vars: [CANVAS_API_TOKEN, CANVAS_BASE_URL]
metadata:
  hermes:
    tags: [Canvas, LMS, Education, Courses, Assignments]
---

# Canvas LMS — 課程與作業存取

Canvas LMS 的唯讀存取，用於列出課程與作業。

## 腳本

- `scripts/canvas_api.py` — 用於 Canvas API 呼叫的 Python CLI

## 設定

1. 在瀏覽器中登入您的 Canvas 實例
2. 前往 **帳戶 → 設定** (點擊您的個人資料圖示，然後點擊設定)
3. 滾動至 **核准的整合 (Approved Integrations)** 並點擊 **+ 新增存取權杖 (+ New Access Token)**
4. 為權杖命名 (例如 "Hermes Agent")，設定可選的到期日，然後點擊 **產生權杖 (Generate Token)**
5. 複製權杖並新增至 `~/.hermes/.env`：

```
CANVAS_API_TOKEN=your_token_here
CANVAS_BASE_URL=https://yourschool.instructure.com
```

基礎 URL (Base URL) 是您登入 Canvas 時出現在瀏覽器中的網址 (末尾不含斜槓)。

## 使用方式

```bash
CANVAS="python $HERMES_HOME/skills/productivity/canvas/scripts/canvas_api.py"

# 列出所有進行中的課程
$CANVAS list_courses --enrollment-state active

# 列出所有課程 (不論狀態)
$CANVAS list_courses

# 列出特定課程的作業
$CANVAS list_assignments 12345

# 按截止日期排序並列出作業
$CANVAS list_assignments 12345 --order-by due_at
```

## 輸出格式

**list_courses** 回傳：
```json
[{"id": 12345, "name": "Intro to CS", "course_code": "CS101", "workflow_state": "available", "start_at": "...", "end_at": "..."}]
```

**list_assignments** 回傳：
```json
[{"id": 67890, "name": "Homework 1", "due_at": "2025-02-15T23:59:00Z", "points_possible": 100, "submission_types": ["online_upload"], "html_url": "...", "description": "...", "course_id": 12345}]
```

注意：作業說明會被截斷至 500 個字元。`html_url` 欄位連結至 Canvas 中的完整作業頁面。

## API 參考 (curl)

```bash
# 列出課程
curl -s -H "Authorization: Bearer $CANVAS_API_TOKEN" \
  "$CANVAS_BASE_URL/api/v1/courses?enrollment_state=active&per_page=10"

# 列出課程的作業
curl -s -H "Authorization: Bearer $CANVAS_API_TOKEN" \
  "$CANVAS_BASE_URL/api/v1/courses/COURSE_ID/assignments?per_page=10&order_by=due_at"
```

Canvas 使用 `Link` 標頭進行分頁。Python 腳本會自動處理分頁。

## 規則

- 此技能為 **唯讀** — 僅獲取數據，絕不修改課程或作業。
- 首次使用時，執行 `$CANVAS list_courses` 以驗證認證 — 若回傳 401 失敗，請引導用戶進行設定。
- Canvas 速率限制約為每 10 分鐘 700 次請求；若達到限制，請檢查 `X-Rate-Limit-Remaining` 標頭。

## 疑難排解

| 問題 | 修正方式 |
|---------|-----|
| 401 未授權 | 權杖無效或已過期 — 在 Canvas 設定中重新產生 |
| 403 被禁止 | 權杖缺少該課程的權限 |
| 課程清單為空 | 嘗試使用 `--enrollment-state active` 或省略該標記以查看所有狀態 |
| 錯誤的院校 | 驗證 `CANVAS_BASE_URL` 是否與瀏覽器中的 URL 相符 |
| 超時錯誤 | 檢查與您的 Canvas 實例的網路連線 |
