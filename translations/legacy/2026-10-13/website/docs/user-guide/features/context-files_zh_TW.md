---
sidebar_position: 8
title: "上下文檔案"
description: "專案上下文檔案 — .hermes.md、AGENTS.md、CLAUDE.md、全域 SOUL.md 以及 .cursorrules — 會自動注入到每一次對話中"
---

# 上下文檔案 (Context Files)

Hermes Agent 會自動探索並載入決定其行為方式的上下文檔案。有些是專案本地檔案，從您的工作目錄中探索；而 `SOUL.md` 現在是 Hermes 實例的全域檔案，僅從 `HERMES_HOME` 載入。

## 支援的上下文檔案

| 檔案 | 用途 | 探索方式 |
|------|---------|-----------| 
| **.hermes.md** / **HERMES.md** | 專案指令（最高優先權） | 向上搜尋至 git 根目錄 |
| **AGENTS.md** | 專案指令、慣例、架構 | 啟動時搜尋 CWD + 隨後逐步探索子目錄 |
| **CLAUDE.md** | Claude Code 上下文檔案（亦可偵測） | 啟動時搜尋 CWD + 隨後逐步探索子目錄 |
| **SOUL.md** | 為此 Hermes 實例自定義全域個性與語氣 | 僅限 `HERMES_HOME/SOUL.md` |
| **.cursorrules** | Cursor IDE 編碼慣例 | 僅限當前工作目錄 (CWD) |
| **.cursor/rules/*.mdc** | Cursor IDE 規則模組 | 僅限當前工作目錄 (CWD) |

:::info 優先權系統
每個工作階段僅會載入 **一種** 專案上下文類型（以最先匹配者為準）：`.hermes.md` → `AGENTS.md` → `CLAUDE.md` → `.cursorrules`。**SOUL.md** 則一律作為代理身分（欄位 #1）獨立載入。
:::

## AGENTS.md

`AGENTS.md` 是主要的專案上下文檔案。它告知代理您的專案架構、應遵循的慣例以及任何特殊指令。

### 漸進式子目錄探索

在工作階段開始時，Hermes 會將當前工作目錄中的 `AGENTS.md` 載入到系統提示詞中。當代理在工作階段期間導覽至子目錄（透過 `read_file`、`terminal`、`search_files` 等工具）時，它會**漸進式探索**這些目錄中的上下文檔案，並在它們變得相關時將其注入對話中。

```
my-project/
├── AGENTS.md              ← 啟動時載入（系統提示詞）
├── frontend/
│   └── AGENTS.md          ← 當代理讀取 frontend/ 檔案時探索發現
├── backend/
│   └── AGENTS.md          ← 當代理讀取 backend/ 檔案時探索發現
└── shared/
    └── AGENTS.md          ← 當代理讀取 shared/ 檔案時探索發現
```

與啟動時載入所有內容相比，這種方法有兩個優點：
- **不會導致系統提示詞膨脹** — 子目錄提示僅在需要時出現
- **保留提示詞快取 (Prompt cache preservation)** — 系統提示詞在各個輪次之間保持穩定

每個子目錄在每個工作階段中最多檢查一次。探索也會向父目錄追溯，因此讀取 `backend/src/main.py` 會發現 `backend/AGENTS.md`，即使 `backend/src/` 本身沒有上下文檔案。

:::info
子目錄上下文檔案會經過與啟動上下文檔案相同的[安全掃描（提示詞注入防護）](#安全提示詞注入防護)。惡意檔案將被封鎖。
:::

### AGENTS.md 範例

```markdown
# 專案內容 (Project Context)

這是一個使用 Python FastAPI 後端的 Next.js 14 Web 應用程式。

## 架構
- 前端：使用 App Router 的 Next.js 14，位於 `/frontend`
- 後端：位於 `/backend` 的 FastAPI，使用 SQLAlchemy ORM
- 資料庫：PostgreSQL 16
- 部署：在 Hetzner VPS 上使用 Docker Compose

## 慣例
- 所有前端程式碼皆使用 TypeScript 嚴格模式
- Python 程式碼遵循 PEP 8，處處使用類型提示 (type hints)
- 所有 API 端點皆回傳 `{data, error, meta}` 格式的 JSON
- 測試存放在 `__tests__/` 目錄（前端）或 `tests/`（後端）

## 重要注意事項
- 切勿直接修改遷移檔案 (migration files) — 請使用 Alembic 指令
- `.env.local` 檔案包含真實的 API 金鑰，請勿提交
- 前端埠號為 3000，後端為 8000，資料庫為 5432
```

## SOUL.md

`SOUL.md` 控制代理的個性、語氣和溝通風格。詳情請參閱[個性 (Personality)](/docs/user-guide/features/personality) 頁面。

**位置：**

- `~/.hermes/SOUL.md`
- 或者，如果您使用自定義 Home 目錄執行 Hermes，則為 `$HERMES_HOME/SOUL.md`

重要細節：

- 如果尚不存在 `SOUL.md`，Hermes 會自動產生預設的檔案
- Hermes 僅從 `HERMES_HOME` 載入 `SOUL.md`
- Hermes 不會主動探測工作目錄中的 `SOUL.md`
- 如果檔案為空，則不會將 `SOUL.md` 的任何內容加入提示詞
- 如果檔案有內容，則在掃描和截斷後，內容將逐字注入

## .cursorrules

Hermes 相容於 Cursor IDE 的 `.cursorrules` 檔案和 `.cursor/rules/*.mdc` 規則模組。如果您的專案根目錄中存在這些檔案，且未找到更高優先權的上下文檔案（`.hermes.md`、`AGENTS.md` 或 `CLAUDE.md`），它們將作為專案內容載入。

這意味著您在使用 Hermes 時，現有的 Cursor 慣例會自動套用。

## 上下文檔案如何載入

### 在啟動時（系統提示詞）

上下文檔案由 `agent/prompt_builder.py` 中的 `build_context_files_prompt()` 載入：

1. **掃描工作目錄** — 依序檢查 `.hermes.md` → `AGENTS.md` → `CLAUDE.md` → `.cursorrules`（以最先匹配者為準）
2. **讀取內容** — 每個檔案皆以 UTF-8 文字讀取
3. **安全掃描** — 檢查內容是否存在提示詞注入模式
4. **截斷** — 超過 20,000 個字元的檔案將進行首尾截斷（首部 70%，尾部 20%，中間留有標記）
5. **組合** — 所有區塊皆合併於 `# Project Context` 標題下
6. **注入** — 組合後的內容將加入系統提示詞中

### 在工作階段期間（漸進式探索）

`agent/subdirectory_hints.py` 中的 `SubdirectoryHintTracker` 會監控工具呼叫參數中的檔案路徑：

1. **路徑提取** — 在每次工具呼叫後，從參數（`path`、`workdir`、shell 指令）中提取檔案路徑
2. **祖先追溯** — 檢查該目錄及其最多 5 層父目錄（在已造訪過的目錄處停止）
3. **提示載入** — 如果找到 `AGENTS.md`、`CLAUDE.md` 或 `.cursorrules`，則將其載入（每個目錄僅限最先匹配者）
4. **安全掃描** — 與啟動檔案相同的提示詞注入掃描
5. **截斷** — 每個檔案上限為 8,000 個字元
6. **注入** — 附加至工具執行結果，讓模型能自然地在上下文中看到它

最終的提示詞區塊大致如下：

```text
# Project Context

已載入以下專案上下文檔案，應予以遵循：

## AGENTS.md

[此處為您的 AGENTS.md 內容]

## .cursorrules

[此處為您的 .cursorrules 內容]

[此處為您的 SOUL.md 內容]
```

請注意，SOUL 內容是直接插入的，沒有額外的包裝文字。

## 安全：提示詞注入防護

所有上下文檔案在包含進來之前，都會經過潛在提示詞注入 (Prompt Injection) 的掃描。掃描器會檢查：

- **指令覆寫企圖**："ignore previous instructions"（忽略先前的指令）、"disregard your rules"（無視您的規則）
- **欺騙模式**："do not tell the user"（不要告訴使用者）
- **系統提示詞覆寫**："system prompt override"
- **隱藏的 HTML 註釋**：`<!-- ignore instructions -->`
- **隱藏的 div 元素**：`<div style="display:none">`
- **憑證外洩**：`curl ... $API_KEY`
- **機密檔案存取**：`cat .env`、`cat credentials`
- **隱形字元**：零寬空格 (zero-width spaces)、雙向覆蓋 (bidirectional overrides)、詞組連接符 (word joiners)

如果偵測到任何威脅模式，檔案將被封鎖：

```
[BLOCKED: AGENTS.md contained potential prompt injection (prompt_injection). Content not loaded.]
```

:::warning
此掃描器可防範常見的注入模式，但不能取代對共享存儲庫中上下文檔案的審查。請務必驗證您非作者之專案中的 AGENTS.md 內容。
:::

## 大小限制

| 限制 | 數值 |
|-------|-------|
| 每個檔案最大字元數 | 20,000（約 7,000 個標記/tokens） |
| 首部截斷比例 | 70% |
| 尾部截斷比例 | 20% |
| 截斷標記 | 10%（顯示字元數並建議使用檔案工具） |

當檔案超過 20,000 個字元時，截斷訊息會顯示：

```
[...truncated AGENTS.md: kept 14000+4000 of 25000 chars. Use file tools to read the full file.]
```

## 有效編寫上下文檔案的秘訣

:::tip AGENTS.md 最佳實踐
1. **保持簡潔** — 盡量遠低於 2 萬字元；代理在每一輪對話都會閱讀它
2. **使用標題結構** — 使用 `##` 區分架構、慣例、重要注意事項等章節
3. **包含具體範例** — 展示偏好的程式碼模式、API 格式、命名慣例
4. **提及「不要做」的事項** — 「切勿直接修改遷移檔案」
5. **列出關鍵路徑與埠號** — 代理會將這些用於終端機指令
6. **隨專案演進更新** — 過時的內容比沒有內容更糟
:::

### 每個子目錄的上下文

對於多專案存儲庫 (monorepos)，請將子目錄專屬的指令放在巢狀的 AGENTS.md 檔案中：

```markdown
<!-- frontend/AGENTS.md -->
# Frontend Context

- 使用 `pnpm` 而非 `npm` 進行套件管理
- 元件存放在 `src/components/`，頁面存放在 `src/app/`
- 使用 Tailwind CSS，切勿使用行內樣式 (inline styles)
- 使用 `pnpm test` 執行測試
```

```markdown
<!-- backend/AGENTS.md -->
# Backend Context

- 使用 `poetry` 進行依賴管理
- 使用 `poetry run uvicorn main:app --reload` 啟動開發伺服器
- 所有端點皆需 OpenAPI docstrings
- 資料庫模型位於 `models/`，結構 (schemas) 位於 `schemas/`
```
