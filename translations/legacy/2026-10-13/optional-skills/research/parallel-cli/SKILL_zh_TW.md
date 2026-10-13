---
name: parallel-cli
description: Parallel CLI 的選用第三方技能 — 代理原生 (Agent-native) 網頁搜尋、擷取、深度研究、富集、FindAll 和監控。偏好 JSON 輸出和非交互式流程。
version: 1.1.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [Research, Web, Search, Deep-Research, Enrichment, CLI]
    related_skills: [duckduckgo-search, mcporter]
---

# Parallel CLI

當使用者明確要求使用 Parallel，或者終端原生工作流能從 Parallel 的第三方網頁搜尋、擷取、深度研究、富集、實體發現或監控技術棧中獲益時，請使用 `parallel-cli`。

這是一個選用的第三方工作流，不是 Hermes 的核心能力。

重要預期：
- Parallel 是一項付費服務（提供免費額度），而非完全免費的本地工具。
- 它與 Hermes 原生的 `web_search` / `web_extract` 功能重疊，因此預設情況下對於普通查詢，請勿優先選擇它。
- 當使用者特別提到 Parallel，或者需要 Parallel 的富集 (Enrichment)、FindAll 或監控工作流等功能時，請優先選擇此技能。

`parallel-cli` 是為代理 (Agents) 設計的：
- 透過 `--json` 提供 JSON 輸出
- 非交互式指令執行
- 透過 `--no-wait`、`status` 和 `poll` 支援非同步長時間執行任務
- 透過 `--previous-interaction-id` 進行內容鏈接
- 在一個 CLI 中整合搜尋、擷取、研究、富集、實體發現和監控

## 何時使用

在以下情況下優先選擇此技能：
- 使用者明確提到 Parallel 或 `parallel-cli`
- 任務需要比單次搜尋/擷取更豐富的工作流
- 你需要可以啟動並稍後輪詢的非同步深度研究任務
- 你需要結構化富集、FindAll 實體發現或監控

對於 Parallel 未明確要求的快速單次查詢，請優先選擇 Hermes 原生的 `web_search` / `web_extract`。

## 安裝

嘗試為環境選擇侵入性最小的安裝路徑。

### Homebrew

```bash
brew install parallel-web/tap/parallel-cli
```

### npm

```bash
npm install -g parallel-web-cli
```

### Python 套件

```bash
pip install "parallel-web-tools[cli]"
```

### 獨立安裝程式

```bash
curl -fsSL https://parallel.ai/install.sh | bash
```

如果你想要隔離的 Python 安裝，`pipx` 也可以：

```bash
pipx install "parallel-web-tools[cli]"
pipx ensurepath
```

## 認證

交互式登入：

```bash
parallel-cli login
```

無頭 (Headless) / SSH / CI：

```bash
parallel-cli login --device
```

API 金鑰環境變數：

```bash
export PARALLEL_API_KEY="***"
```

驗證當前認證狀態：

```bash
parallel-cli auth
```

如果認證需要瀏覽器交互，請使用 `pty=true` 執行。

## 核心規則集

1. 需要機器可讀的輸出時，務必偏好 `--json`。
2. 偏好明確的參數和非交互式流程。
3. 對於長時間執行的任務，使用 `--no-wait` 然後配合 `status` / `poll`。
4. 僅引用 CLI 輸出回傳的 URL。
5. 當可能有後續問題時，將大型 JSON 輸出儲存到暫存檔。
6. 僅對真正的長時間工作流使用背景程序；否則請在前台執行。
7. 除非使用者特別要求 Parallel 或需要 Parallel 專屬工作流，否則偏好 Hermes 原生工具。

## 快速參考

```text
parallel-cli
├── auth
├── login
├── logout
├── search
├── extract / fetch
├── research run|status|poll|processors
├── enrich run|status|poll|plan|suggest|deploy
├── findall run|ingest|status|poll|result|enrich|extend|schema|cancel
└── monitor create|list|get|update|delete|events|event-group|simulate
```

## 常見旗標與模式

常用旗標：
- `--json`：用於結構化輸出
- `--no-wait`：用於非同步任務
- `--previous-interaction-id <id>`：用於重用先前內容的後續任務
- `--max-results <n>`：搜尋結果數量
- `--mode one-shot|agentic`：搜尋行為模式
- `--include-domains domain1.com,domain2.com`
- `--exclude-domains domain1.com,domain2.com`
- `--after-date YYYY-MM-DD`

方便時從 stdin 讀取：

```bash
echo "What is the latest funding for Anthropic?" | parallel-cli search - --json
echo "Research question" | parallel-cli research run - --json
```

## 搜尋 (Search)

用於獲取具有結構化結果的當前網頁查詢。

```bash
parallel-cli search "What is Anthropic's latest AI model?" --json
parallel-cli search "SEC filings for Apple" --include-domains sec.gov --json
parallel-cli search "bitcoin price" --after-date 2026-01-01 --max-results 10 --json
parallel-cli search "latest browser benchmarks" --mode one-shot --json
parallel-cli search "AI coding agent enterprise reviews" --mode agentic --json
```

有用約束：
- `--include-domains`：縮小信任來源
- `--exclude-domains`：過濾雜訊網域
- `--after-date`：時效性過濾
- `--max-results`：需要更廣泛覆蓋時使用

如果你預期會有後續問題，請儲存輸出：

```bash
parallel-cli search "latest React 19 changes" --json -o /tmp/react-19-search.json
```

總結結果時：
- 優先給出答案
- 包含日期、名稱和具體事實
- 僅引用回傳的來源
- 避免捏造 URL 或來源標題

## 擷取 (Extraction)

用於從 URL 提取乾淨的內容或 Markdown。

```bash
parallel-cli extract https://example.com --json
parallel-cli extract https://company.com --objective "Find pricing info" --json
parallel-cli extract https://example.com --full-content --json
parallel-cli fetch https://example.com --json
```

當頁面內容廣泛且你只需要其中一部分資訊時，請使用 `--objective`。

## 深度研究 (Deep Research)

用於可能需要時間的深度多步驟研究任務。

常見處理器層級：
- `lite` / `base`：更快、更便宜的處理
- `core` / `pro`：更徹底的綜合分析
- `ultra`：最重的研究任務

### 同步

```bash
parallel-cli research run \
  "Compare the leading AI coding agents by pricing, model support, and enterprise controls" \
  --processor core \
  --json
```

### 非同步啟動 + 輪詢

```bash
parallel-cli research run \
  "Compare the leading AI coding agents by pricing, model support, and enterprise controls" \
  --processor ultra \
  --no-wait \
  --json

parallel-cli research status trun_xxx --json
parallel-cli research poll trun_xxx --json
parallel-cli research processors --json
```

### 內容鏈接 / 後續

```bash
parallel-cli research run "What are the top AI coding agents?" --json
parallel-cli research run \
  "What enterprise controls does the top-ranked one offer?" \
  --previous-interaction-id trun_xxx \
  --json
```

建議的 Hermes 工作流：
1. 使用 `--no-wait --json` 啟動
2. 擷取回傳的 run/task ID
3. 如果使用者想繼續其他工作，請繼續
4. 稍後呼叫 `status` 或 `poll`
5. 總結最終報告，並引用回傳來源

## 富集 (Enrichment)

當使用者有 CSV/JSON/表格輸入並希望根據網頁研究推論額外欄位時使用。

### 建議欄位

```bash
parallel-cli enrich suggest "Find the CEO and annual revenue" --json
```

### 規劃配置

```bash
parallel-cli enrich plan -o config.yaml
```

### 內嵌數據

```bash
parallel-cli enrich run \
  --data '[{"company": "Anthropic"}, {"company": "Mistral"}]' \
  --intent "Find headquarters and employee count" \
  --json
```

### 非交互式檔案執行

```bash
parallel-cli enrich run \
  --source-type csv \
  --source companies.csv \
  --target enriched.csv \
  --source-columns '[{"name": "company", "description": "Company name"}]' \
  --intent "Find the CEO and annual revenue"
```

### YAML 配置執行

```bash
parallel-cli enrich run config.yaml
```

### 狀態 / 輪詢

```bash
parallel-cli enrich status <task_group_id> --json
parallel-cli enrich poll <task_group_id> --json
```

非交互執行時，請對欄位定義使用明確的 JSON 陣列。
回報成功前請驗證輸出檔案。

## FindAll

用於網頁規模的實體發現，當使用者想要發現的數據集而非簡短答案時使用。

```bash
parallel-cli findall run "Find AI coding agent startups with enterprise offerings" --json
parallel-cli findall run "AI startups in healthcare" -n 25 --json
parallel-cli findall status <run_id> --json
parallel-cli findall poll <run_id> --json
parallel-cli findall result <run_id> --json
parallel-cli findall schema <run_id> --json
```

當使用者想要一組可以稍後查看、過濾或富集的實體時，這比普通搜尋更合適。

## 監控 (Monitor)

用於隨時間檢測持續變化。

```bash
parallel-cli monitor list --json
parallel-cli monitor get <monitor_id> --json
parallel-cli monitor events <monitor_id> --json
parallel-cli monitor delete <monitor_id> --json
```

建立通常是敏感部分，因為頻率和交付方式很重要：

```bash
parallel-cli monitor create --help
```

當使用者想要對頁面或來源進行定期追蹤而非單次擷取時，請使用此功能。

## 建議的 Hermes 使用模式

### 帶引用的快速答案
1. 執行 `parallel-cli search ... --json`
2. 解析標題、URL、日期、摘錄
3. 僅從回傳的 URL 中進行內嵌引用總結

### URL 調查
1. 執行 `parallel-cli extract URL --json`
2. 如果需要，重新執行並帶上 `--objective` 或 `--full-content`
3. 引用或總結提取的 Markdown

### 長時間研究工作流
1. 執行 `parallel-cli research run ... --no-wait --json`
2. 儲存回傳的 ID
3. 繼續其他工作或定期輪詢
4. 總結最終報告並附上引用

### 結構化富集工作流
1. 檢查輸入檔案和欄位
2. 使用 `enrich suggest` 或提供明確的富集欄位
3. 執行 `enrich run`
4. 如果需要，輪詢是否完成
5. 回報成功前請驗證輸出檔案

## 錯誤處理與退出碼

CLI 定義了以下退出碼：
- `0`：成功
- `2`：錯誤輸入
- `3`：認證錯誤
- `4`：API 錯誤
- `5`：逾時

如果遇到認證錯誤：
1. 檢查 `parallel-cli auth`
2. 確認 `PARALLEL_API_KEY` 或執行 `parallel-cli login` / `parallel-cli login --device`
3. 驗證 `parallel-cli` 是否在 `PATH` 中

## 維護

檢查當前認證 / 安裝狀態：

```bash
parallel-cli auth
parallel-cli --help
```

更新指令：

```bash
parallel-cli update
pip install --upgrade parallel-web-tools
parallel-cli config auto-update-check off
```

## 注意事項

- 除非使用者明確要求人類可讀格式，否則不要省略 `--json`。
- 不要引用 CLI 輸出中不存在的來源。
- `login` 可能需要 PTY/瀏覽器交互。
- 短時間任務偏好前台執行；不要過度使用背景程序。
- 對於大型結果集，將 JSON 儲存到 `/tmp/*.json` 而不是全部塞進內容中。
- 當 Hermes 原生工具已足夠時，不要默默選擇 Parallel。
- 請記住，這是一個第三方工作流，通常需要帳號認證以及超出免費額度的付費使用。
