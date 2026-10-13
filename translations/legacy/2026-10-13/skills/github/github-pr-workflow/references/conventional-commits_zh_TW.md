# 約定式提交 (Conventional Commits) 快速參考

格式：`類型(範圍): 描述`

## 類型 (Types)

| 類型 | 何時使用 | 範例 |
|------|------------|---------|
| `feat` | 新功能或能力 | `feat(auth): 新增 OAuth2 登入流程` |
| `fix` | 錯誤修復 | `fix(api): 處理來自 /users 端點的空回傳值` |
| `refactor` | 程式碼重構，不影響行為 | `refactor(db): 將查詢建構器提取至獨立模組` |
| `docs` | 僅文件變更 | `docs: 更新 README 中的 API 使用範例` |
| `test` | 新增或更新測試 | `test(auth): 新增 token 重刷的整合測試` |
| `ci` | CI/CD 設定 | `ci: 將 Python 3.12 新增至測試矩陣` |
| `chore` | 維護、依賴項、工具鏈 | `chore: 將 pytest 升級至 8.x` |
| `perf` | 效能改進 | `perf(search): 在 users.email 欄位新增索引` |
| `style` | 格式化、空白字元、分號 | `style: 對 src/ 執行 black 格式化工具` |
| `build` | 建置系統或外部依賴 | `build: 從 setuptools 切換至 hatch` |
| `revert` | 撤銷先前的提交 | `revert: 撤銷 "feat(auth): 新增 OAuth2 登入流程"` |

## 範圍 (Scope)（選填）

程式碼庫區域的簡短識別碼：`auth`, `api`, `db`, `ui`, `cli` 等。

## 破壞性變更 (Breaking Changes)

在類型後方加上 `!`，或在頁尾加入 `BREAKING CHANGE:`：

```
feat(api)!: 將認證方式更改為使用 bearer tokens

BREAKING CHANGE: API 端點現在需要 Bearer token，而非 API key 標頭。
遷移指南：https://docs.example.com/migrate-auth
```

## 多行正文 (Multi-line Body)

每行不超過 72 個字元。使用項目符號列出多項變更：

```
feat(auth): 新增基於 JWT 的使用者驗證

- 新增帶有輸入驗證的登入/註冊端點
- 新增具有 argon2 密碼雜湊功能的使用者模型
- 為受保護的路由新增認證中間件
- 新增具有輪轉功能的 token 重刷端點

Closes #42
```

## 連結 Issue

在提交正文或頁尾中：

```
Closes #42          ← 合併時關閉 issue
Fixes #42           ← 效果相同
Refs #42            ← 僅引用但不關閉
Co-authored-by: 姓名 <電子郵件>
```

## 快速決策指南

- 新增了東西？ → `feat`
- 東西壞了而您修復了它？ → `fix`
- 更改了程式碼組織方式但未改變功能？ → `refactor`
- 只動到測試？ → `test`
- 只動到文件？ → `docs`
- 更新了 CI/CD 管線？ → `ci`
- 更新了依賴項或工具鏈？ → `chore`
- 讓東西變快了？ → `perf`
