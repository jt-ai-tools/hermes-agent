# CI 疑難排解快速參考

常見的 CI 失敗模式以及如何從日誌中進行診斷。

## 閱讀 CI 日誌

```bash
# 使用 gh
gh run view <RUN_ID> --log-failed

# 使用 curl — 下載並解壓縮
curl -sL -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GH_OWNER/$GH_REPO/actions/runs/<RUN_ID>/logs \
  -o /tmp/ci-logs.zip && unzip -o /tmp/ci-logs.zip -d /tmp/ci-logs
```

## 常見失敗模式

### 測試失敗 (Test Failures)

**日誌中的特徵：**
```
FAILED tests/test_foo.py::test_bar - AssertionError
E       assert 42 == 43
ERROR tests/test_foo.py - ModuleNotFoundError
```

**診斷方式：**
1. 從堆疊追蹤 (traceback) 中尋找測試檔案與行號
2. 使用 `read_file` 讀取失敗的測試
3. 檢查這是程式碼中的邏輯錯誤，還是測試斷言 (assertion) 已過時
4. 尋找 `ModuleNotFoundError` — 通常是 CI 中缺少的依賴項

**常見修復：**
- 更新斷言以符合新的預期行為
- 將缺少的依賴項新增至 requirements.txt / pyproject.toml
- 修復不穩定的測試 (flaky test)（新增重試機制、模擬外部服務、修復競態條件）

---

### Lint / 格式化失敗 (Lint / Formatting Failures)

**日誌中的特徵：**
```
src/auth.py:45:1: E302 expected 2 blank lines, got 1
src/models.py:12:80: E501 line too long (95 > 88 characters)
error: would reformat src/utils.py
```

**診斷方式：**
1. 讀取提及的特定 `檔案:行號`
2. 檢查是哪個 linter 發出警報 (flake8, ruff, black, isort, mypy)

**常見修復：**
- 在本地執行格式化工具：`black .`, `isort .`, `ruff check --fix .`
- 透過編輯檔案修復特定的風格違規
- 如果使用 `patch`，請確保符合現有的縮排風格

---

### 型別檢查失敗 (mypy / pyright)

**日誌中的特徵：**
```
src/api.py:23: error: Argument 1 to "process" has incompatible type "str"; expected "int"
src/models.py:45: error: Missing return statement
```

**診斷方式：**
1. 讀取提及行號處的檔案
2. 檢查函式簽章 (signature) 以及傳遞的內容

**常見修復：**
- 新增型別轉換 (type cast) 或轉型
- 修正函式簽章
- 作為最後手段，新增 `# type: ignore` 註釋（並附上說明）

---

### 建置 / 編譯失敗 (Build / Compilation Failures)

**日誌中的特徵：**
```
ModuleNotFoundError: No module named 'some_package'
ERROR: Could not find a version that satisfies the requirement foo==1.2.3
npm ERR! Could not resolve dependency
```

**診斷方式：**
1. 檢查 requirements.txt / package.json 是否有遺漏或不相容的依賴項
2. 比較本地與 CI 的 Python/Node 版本

**常見修復：**
- 將遺漏的依賴項新增至 requirements 檔案中
- 鎖定 (pin) 相容的版本
- 更新 lockfile (`pip freeze`, `npm install`)

---

### 權限 / 認證失敗 (Permission / Auth Failures)

**日誌中的特徵：**
```
fatal: could not read Username for 'https://github.com': No such device or address
Error: Resource not accessible by integration
403 Forbidden
```

**診斷方式：**
1. 檢查 workflow 是否需要特殊權限 (token 範圍)
2. 檢查 secrets 是否已設定（遺漏 `GITHUB_TOKEN` 或自定義 secrets）

**常見修復：**
- 在 workflow YAML 中新增 `permissions:` 區塊
- 驗證 secrets 是否存在：`gh secret list` 或檢查倉庫設定
- 對於 fork 的 PR：某些 secrets 出於安全考量預設不可用

---

### 逾時失敗 (Timeout Failures)

**日誌中的特徵：**
```
Error: The operation was canceled.
The job running on runner ... has exceeded the maximum execution time
```

**診斷方式：**
1. 檢查哪個步驟逾時
2. 尋找無窮迴圈、卡住的程序或緩慢的網路呼叫

**常見修復：**
- 為特定步驟新增逾時設定：`timeout-minutes: 10`
- 修復底層的效能問題
- 拆分為平行作業 (parallel jobs)

---

### Docker / 容器失敗 (Docker / Container Failures)

**日誌中的特徵：**
```
docker: Error response from daemon
failed to solve: ... not found
COPY failed: file not found in build context
```

**診斷方式：**
1. 檢查失敗步驟處的 Dockerfile
2. 驗證倉庫中是否存在引用的檔案

**常見修復：**
- 修正 COPY/ADD 指令中的路徑
- 更新基礎映像檔 (base image) 的標籤 (tag)
- 將遺漏的檔案新增至 `.dockerignore` 排除清單中，或從中移除

---

## 自動修復決策樹

```
CI 失敗
├── 測試失敗
│   ├── 斷言不匹配 → 更新測試或修復邏輯
│   └── 導入/模組錯誤 → 新增依賴項
├── Lint 失敗 → 執行格式化工具，修復風格
├── 型別錯誤 → 修復型別
├── 建置失敗
│   ├── 遺漏依賴項 → 新增至 requirements
│   └── 版本衝突 → 更新版本鎖定
├── 權限錯誤 → 更新 workflow 權限（需要使用者介入）
└── 逾時 → 調查效能（可能需要使用者輸入）
```

## 修復後重新執行

```bash
git add <修復的檔案> && git commit -m "fix: resolve CI failure" && git push

# 接著監控
gh pr checks --watch 2>/dev/null || \
  echo "輪詢指令: curl -s -H 'Authorization: token ...' https://api.github.com/repos/.../commits/$(git rev-parse HEAD)/status"
```
