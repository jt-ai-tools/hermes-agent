---
sidebar_position: 15
title: "網頁控制面板"
description: "基於瀏覽器的控制面板，用於管理設定、API 金鑰、對話階段、日誌、分析、Cron 工作與技能"
---

# 網頁控制面板

網頁控制面板是一個基於瀏覽器的 UI，用於管理您的 Hermes Agent 安裝。您不需要編輯 YAML 檔案或執行 CLI 指令，即可透過簡潔的網頁介面配置設定、管理 API 金鑰並監控對話階段。

## 快速開始

```bash
hermes dashboard
```

這會啟動一個本地網頁伺服器，並在您的瀏覽器中開啟 `http://127.0.0.1:9119`。控制面板完全在您的機器上執行 — 數據不會離開 localhost。

### 選項

| 旗標 | 預設值 | 描述 |
|------|---------|-------------|
| `--port` | `9119` | 網頁伺服器執行的連接埠 |
| `--host` | `127.0.0.1` | 綁定位址 |
| `--no-open` | — | 不要自動開啟瀏覽器 |

```bash
# 自定義連接埠
hermes dashboard --port 8080

# 綁定至所有介面 (在共用網路中請謹慎使用)
hermes dashboard --host 0.0.0.0

# 啟動但不開啟瀏覽器
hermes dashboard --no-open
```

## 前置作業

網頁控制面板需要 FastAPI 與 Uvicorn。請使用以下指令安裝：

```bash
pip install hermes-agent[web]
```

如果您是使用 `pip install hermes-agent[all]` 安裝的，則網頁相關依賴項目已經包含在內。

如果您在未安裝依賴項目的情況下執行 `hermes dashboard`，系統會提示您需要安裝哪些項目。如果前端尚未建置且環境中有 `npm`，系統會在首次啟動時自動建置。

## 頁面內容

### 狀態 (Status)

首頁顯示安裝狀況的即時概覽：

- **Agent 版本** 與發佈日期
- **閘道器狀態** — 執行中/已停止、PID、連線的平台及其狀態
- **活躍對話階段** — 過去 5 分鐘內活躍的對話數量
- **近期對話階段** — 最近 20 個對話階段的列表，包含模型、訊息數、Token 使用量及對話預覽

狀態頁面每 5 秒自動重整一次。

### 設定 (Config)

用於 `config.yaml` 的表單編輯器。超過 150 個設定欄位會從 `DEFAULT_CONFIG` 自動偵測，並歸類至分頁標籤中：

- **model** — 預設模型、供應商、基礎 URL、推理設定
- **terminal** — 後端 (local/docker/ssh/modal)、逾時、Shell 偏好設定
- **display** — 外觀方案 (skin)、工具進度、恢復顯示、載入動畫設定
- **agent** — 最大迭代次數、閘道器逾時、服務層級
- **delegation** — 子 Agent 限制、推理強度
- **memory** — 供應商選擇、上下文注入設定
- **approvals** — 危險指令核准模式 (ask/yolo/deny)
- 以及更多 — `config.yaml` 的每個部分都有對應的表單欄位

具有已知有效值的欄位 (如終端機後端、外觀方案、核准模式等) 會以底選單呈現。布林值以切換開關呈現。其餘則為文字輸入框。

**操作：**

- **儲存 (Save)** — 立即將變更寫入 `config.yaml`
- **重設為預設值 (Reset to defaults)** — 將所有欄位還原為預設值 (在按儲存前不會正式寫入)
- **匯出 (Export)** — 將目前設定下載為 JSON 檔案
- **匯入 (Import)** — 上傳 JSON 設定檔以替換目前數值

:::tip 小撇步
設定變更將在下一次 Agent 對話階段或閘道器重啟時生效。網頁控制面板編輯的是與 `hermes config set` 及閘道器讀取的同一個 `config.yaml` 檔案。
:::

### API 金鑰 (API Keys)

管理儲存 API 金鑰與憑證的 `.env` 檔案。金鑰依類別分組：

- **LLM 供應商** — OpenRouter, Anthropic, OpenAI, DeepSeek 等
- **工具 API 金鑰** — Browserbase, Firecrawl, Tavily, ElevenLabs 等
- **通訊平台** — Telegram, Discord, Slack 的 Bot Token 等
- **Agent 設定** — 非私密的環境變數，如 `API_SERVER_ENABLED`

每個金鑰會顯示：
- 目前是否已設定 (並隱藏部分數值的預覽)
- 用途說明
- 前往供應商註冊或取得金鑰頁面的連結
- 用於設定或更新數值的輸入框
- 刪除按鈕

進階或鮮少使用的金鑰預設會隱藏在切換開關後方。

### 對話階段 (Sessions)

瀏覽並檢查所有 Agent 對話階段。每一列顯示對話標題、來源平台圖示 (CLI, Telegram, Discord, Slack, cron)、模型名稱、訊息數、工具呼叫次數，以及多久前處於活躍狀態。進行中的對話會標有呼吸燈效果。

- **搜尋 (Search)** — 使用 FTS5 對所有訊息內容進行全文搜尋。搜尋結果會顯示醒目提示的片段，並在展開時自動捲動至第一個相符的訊息。
- **展開 (Expand)** — 點擊對話階段可載入完整的訊息歷史。訊息依角色 (使用者、助手、系統、工具) 進行顏色區分，並以 Markdown 格式呈現，支援語法醒目提示。
- **工具呼叫 (Tool calls)** — 帶有工具呼叫的助手訊息會顯示可摺疊的區塊，內含函式名稱與 JSON 參數。
- **刪除 (Delete)** — 使用垃圾桶圖示刪除對話階段及其訊息歷史。

### 日誌 (Logs)

查看 Agent、閘道器與錯誤日誌檔，支援過濾與即時追蹤 (live tailing)。

- **檔案 (File)** — 在 `agent`、`errors` 與 `gateway` 日誌檔之間切換
- **層級 (Level)** — 依日誌層級過濾：ALL, DEBUG, INFO, WARNING 或 ERROR
- **組件 (Component)** — 依來源組件過濾：all, gateway, agent, tools, cli 或 cron
- **行數 (Lines)** — 選擇要顯示的行數 (50, 100, 200 或 500)
- **自動重整 (Auto-refresh)** — 切換即時追蹤功能，每 5 秒輪詢一次新的日誌行
- **顏色區分** — 日誌行依嚴重程度標色 (錯誤為紅色、警告為黃色、調試為暗色)

### 分析 (Analytics)

從對話歷史計算的使用量與成本分析。選擇時間範圍 (7, 30 或 90 天) 以查看：

- **摘要卡片** — 總 Token 數 (輸入/輸出)、快取命中率、估計或實際總成本，以及總對話次數與日平均值
- **每日 Token 圖表** — 堆疊長條圖，顯示每日輸入與輸出的 Token 使用量，懸停時會顯示細節與成本
- **每日明細表** — 每一天的日期、對話數、輸入 Token、輸出 Token、快取命中率及成本
- **各模型明細** — 顯示所使用的各個模型及其對話數、Token 使用量及估計成本

### Cron 排程

建立與管理定期的 Cron 工作，依排程執行 Agent 提示詞。

- **建立** — 填入名稱 (選填)、提示詞、Cron 表達式 (例如 `0 9 * * *`) 及傳送目標 (local, Telegram, Discord, Slack 或 email)
- **工作列表** — 每個工作顯示其名稱、提示詞預覽、排程表達式、狀態標記 (已啟用/已暫停/錯誤)、傳送目標、上次執行時間及下次執行時間
- **暫停 / 恢復** — 在活躍與暫停狀態之間切換工作
- **立即觸發 (Trigger now)** — 在正常排程外立即執行工作
- **刪除** — 永久移除 Cron 工作

### 技能 (Skills)

瀏覽、搜尋並切換技能與工具集。技能從 `~/.hermes/skills/` 載入，並依類別分組。

- **搜尋** — 依名稱、說明或類別過濾技能與工具集
- **類別過濾** — 點擊類別標籤以縮小列表範圍 (例如 MLOps, MCP, Red Teaming, AI)
- **切換** — 使用開關啟用或停用個別技能。變更將在下一次對話階段生效。
- **工具集 (Toolsets)** — 獨立區塊顯示內建工具集 (檔案操作、網頁瀏覽等)，包含其活躍/停用狀態、設定需求及包含的工具清單

:::warning 安全警告
網頁控制面板會讀取並寫入您的 `.env` 檔案，其中包含 API 金鑰與機密資訊。它預設綁定至 `127.0.0.1` — 僅能從您的本地機器存取。如果您將其綁定至 `0.0.0.0`，您網路上的任何人都可以查看並修改您的憑證。此控制面板本身不具備身份驗證機制。
:::

## `/reload` 斜線指令

控制面板的 PR 也為互動式 CLI 新增了 `/reload` 斜線指令。在透過網頁控制面板 (或直接編輯 `.env`) 更改 API 金鑰後，您可以在活躍的 CLI 對話中使用 `/reload` 來載入變更，而無需重啟：

```
You → /reload
  Reloaded .env (3 var(s) updated)
```

這會將 `~/.hermes/.env` 重新讀取到執行中的程序環境中。當您透過控制面板新增了供應商金鑰並想立即使用時非常有用。

## REST API

網頁控制面板暴露了前端使用的 REST API。您也可以直接呼叫這些端點來進行自動化：

### GET /api/status

傳回 Agent 版本、閘道器狀態、平台狀態及活躍對話階段數量。

### GET /api/sessions

傳回最近 20 個對話階段及其後設數據 (模型、Token 計數、時間戳記、預覽)。

### GET /api/config

以 JSON 格式傳回目前的 `config.yaml` 內容。

### GET /api/config/defaults

傳回預設的設定值。

### GET /api/config/schema

傳回描述每個設定欄位的架構 (schema) — 包含類型、說明、類別及適用的選項。前端使用此架構來為每個欄位渲染正確的輸入元件。

### PUT /api/config

儲存新設定。Body: `{"config": {...}}`。

### GET /api/env

傳回所有已知的環境變數及其設定狀態、隱藏數值、說明與類別。

### PUT /api/env

設定環境變數。Body: `{"key": "VAR_NAME", "value": "secret"}`。

### DELETE /api/env

移除環境變數。Body: `{"key": "VAR_NAME"}`。

### GET /api/sessions/\{session_id\}

傳回單一對話階段的後設數據。

### GET /api/sessions/\{session_id\}/messages

傳回對話階段的完整訊息歷史，包含工具呼叫與時間戳記。

### GET /api/sessions/search

對訊息內容進行全文搜尋。查詢參數：`q`。傳回相符的對話階段 ID 與醒目提示的片段。

### DELETE /api/sessions/\{session_id\}

刪除對話階段及其訊息歷史。

### GET /api/logs

傳回日誌行。查詢參數：`file` (agent/errors/gateway), `lines` (數量), `level`, `component`。

### GET /api/analytics/usage

傳回 Token 使用量、成本與對話分析。查詢參數：`days` (預設 30)。回應包含每日明細與各模型加總。

### GET /api/cron/jobs

傳回所有配置的 Cron 工作及其狀態、排程與執行歷史。

### POST /api/cron/jobs

建立新的 Cron 工作。Body: `{"prompt": "...", "schedule": "0 9 * * *", "name": "...", "deliver": "local"}`。

### POST /api/cron/jobs/\{job_id\}/pause

暫停 Cron 工作。

### POST /api/cron/jobs/\{job_id\}/resume

恢復已暫停的 Cron 工作。

### POST /api/cron/jobs/\{job_id\}/trigger

在排程外立即觸發 Cron 工作。

### DELETE /api/cron/jobs/\{job_id\}

刪除 Cron 工作。

### GET /api/skills

傳回所有技能及其名稱、說明、類別與啟用狀態。

### PUT /api/skills/toggle

啟用或停用技能。Body: `{"name": "skill-name", "enabled": true}`。

### GET /api/tools/toolsets

傳回所有工具集及其標籤、說明、工具列表及活躍/配置狀態。

## CORS

網頁伺服器將 CORS 限制為僅限 localhost 來源：

- `http://localhost:9119` / `http://127.0.0.1:9119` (正式環境)
- `http://localhost:3000` / `http://127.0.0.1:3000`
- `http://localhost:5173` / `http://127.0.0.1:5173` (Vite 開發伺服器)

如果您在自定義連接埠上執行伺服器，該來源會自動被加入。

## 開發

如果您要為網頁控制面板的前端做貢獻：

```bash
# 終端機 1: 啟動後端 API
hermes dashboard --no-open

# 終端機 2: 啟動具備 HMR 的 Vite 開發伺服器
cd web/
npm install
npm run dev
```

位於 `http://localhost:5173` 的 Vite 開發伺服器會將 `/api` 請求代理至位於 `http://127.0.0.1:9119` 的 FastAPI 後端。

前端使用 React 19、TypeScript、Tailwind CSS v4 及 shadcn/ui 風格的元件建置。正式建置會輸出至 `hermes_cli/web_dist/`，由 FastAPI 伺服器作為靜態 SPA 提供服務。

## 更新時自動建置

當您執行 `hermes update` 時，如果環境中有 `npm`，網頁前端會自動重新建置。這能讓控制面板與程式碼更新保持同步。如果未安裝 `npm`，更新將跳過前端建置，`hermes dashboard` 會在首次啟動時進行建置。
