---
sidebar_position: 1
title: "小技巧與最佳實踐"
description: "充分發揮 Hermes Agent 效能的實用建議 —— 提示語技巧、CLI 快捷鍵、上下文檔案、記憶功能、成本優化以及安全設定"
---

# 小技巧與最佳實踐

這是一份能讓您立即提升 Hermes Agent 使用效率的實用技巧清單。每個章節都針對不同層面 —— 請瀏覽標題並跳轉至您感興趣的部分。

---

## 獲得最佳結果

### 明確說明您的需求

模糊的提示語（Prompt）會產生模糊的結果。與其說「修復程式碼」，不如說「修復 `api/handlers.py` 第 47 行的 TypeError —— `process_request()` 函式從 `parse_body()` 接收到了 `None`」。您提供的上下文越多，所需的迭代（Iteration）次數就越少。

### 預先提供上下文

在請求的最開始就提供相關細節：檔案路徑、錯誤訊息、預期行為。一則精心編寫的訊息勝過三輪的澄清對話。直接貼上錯誤追蹤資訊（Traceback）—— Agent 可以解析它們。

### 對重複性指令使用上下文檔案

如果您發現自己一直在重複相同的指令（例如：「使用 Tab 而非空格」、「我們使用 pytest」、「API 位址在 `/api/v2`」），請將它們放入 `AGENTS.md` 檔案中。Agent 在每個工作階段都會自動讀取它 —— 設定一次，勞永逸。

### 讓 Agent 使用它的工具

不要試圖手把手教它每一步。說「找出並修復失敗的測試」，而不是說「開啟 `tests/test_foo.py`，查看第 42 行，然後...」。Agent 具備檔案搜尋、終端機存取和程式碼執行能力 —— 讓它去探索和迭代。

### 對複雜工作流使用技能 (Skills)

在撰寫長篇大論來解釋如何執行某項任務之前，先檢查是否已有現成的技能。輸入 `/skills` 來瀏覽可用技能，或者直接呼叫技能，例如 `/axolotl` 或 `/github-pr-workflow`。

## CLI 進階使用者技巧

### 多行輸入

按下 **Alt+Enter**（或 **Ctrl+J**）可在不傳送訊息的情況下換行。這讓您可以撰寫多行提示語、貼上程式碼區塊，或在按下 Enter 傳送前組織複雜的請求。

### 貼上偵測

CLI 會自動偵測多行貼上。只需直接貼上程式碼區塊或錯誤追蹤資訊 —— 它不會將每一行視為個別訊息傳送。貼上的內容會被緩衝並作為單一訊息傳送。

### 中斷與重導向

按下一次 **Ctrl+C** 可在中斷 Agent 回應。接著您可以輸入新訊息來引導它轉向。在 2 秒內連按兩次 Ctrl+C 可強制結束。當 Agent 開始走錯路時，這項功能非常寶貴。

### 使用 `-c` 恢復工作階段

忘了上個工作階段的內容？執行 `hermes -c` 即可恢復到上次離開時的狀態，並還原完整的對話歷史。您也可以透過標題恢復：`hermes -r "我的研究專案"`。

### 剪貼簿圖片貼上

按下 **Ctrl+V** 可直接將剪貼簿中的圖片貼上到對話中。Agent 會使用視覺（Vision）能力來分析螢幕截圖、圖表、錯誤彈出視窗或 UI 草圖 —— 無需先儲存為檔案。

### 斜線指令自動補完

輸入 `/` 並按下 **Tab** 鍵即可查看所有可用指令。這包括內建指令（`/compress`、`/model`、`/title`）以及所有已安裝的技能。您不需要背誦任何內容 —— Tab 補完功能會幫您搞定。

:::tip 提示
使用 `/verbose` 來循環切換工具輸出顯示模式：**off → new → all → verbose**。「all」模式非常適合觀察 Agent 的運作；「off」則最適合簡單的問答。
:::

## 上下文檔案 (Context Files)

### AGENTS.md：專案的大腦

在您的專案根目錄中建立一個 `AGENTS.md`，包含架構決策、編碼規範和專案特定的指令。這會自動注入到每個工作階段中，因此 Agent 始終了解您的專案規則。

```markdown
# 專案上下文
- 這是一個使用 SQLAlchemy ORM 的 FastAPI 後端
- 對資料庫操作始終使用 async/await
- 測試放在 tests/ 目錄並使用 pytest-asyncio
- 永遠不要提交 .env 檔案
```

### SOUL.md：自訂人格

想讓 Hermes 擁有穩定的預設語氣嗎？編輯 `~/.hermes/SOUL.md`（如果您使用自訂的 Hermes Home，則編輯 `$HERMES_HOME/SOUL.md`）。Hermes 現在會自動生成一份初始的 SOUL 檔案，並將該全域檔案作為整個實例的人格來源。

完整說明請參閱[在 Hermes 中使用 SOUL.md](/docs/guides/use-soul-with-hermes)。

```markdown
# Soul
你是一位資深後端工程師。說話簡潔直接。
除非被要求，否則跳過解釋。偏好一行程式碼解決方案，而非冗長的說明。
始終考慮錯誤處理和邊緣情況。
```

使用 `SOUL.md` 設定持久的人格。使用 `AGENTS.md` 設定專案特定的指令。

### .cursorrules 相容性

已經有 `.cursorrules` 或 `.cursor/rules/*.mdc` 檔案了？Hermes 也會讀取這些檔案。無需重複您的編碼規範 —— 它們會自動從工作目錄載入。

### 探索機制

Hermes 會在工作階段開始時從當前工作目錄載入頂層的 `AGENTS.md`。子目錄中的 `AGENTS.md` 檔案則會在工具呼叫期間延遲探索（透過 `subdirectory_hints.py`）並注入到工具結果中 —— 它們不會預先載入到系統提示語（System Prompt）中。

:::tip 提示
請保持上下文檔案精簡聚焦。每個字元都會消耗您的 Token 額度，因為它們會被注入到每一則訊息中。
:::

## 記憶與技能 (Memory & Skills)

### 記憶 vs. 技能：該放在哪裡

**記憶（Memory）**是用於儲存「事實」：您的環境、偏好、專案位置以及 Agent 了解到的關於您的事情。**技能（Skills）**則是用於「程序」：多步驟的工作流、特定工具的指令以及可重複使用的方案。對於「是什麼」使用記憶，對於「怎麼做」使用技能。

### 何時建立技能

如果您發現某項任務需要 5 個以上的步驟且您會再次執行它，請讓 Agent 為其建立技能。說「將你剛才的操作儲存為名為 `deploy-staging` 的技能」。下次只需輸入 `/deploy-staging`，Agent 就會載入完整的程序。

### 管理記憶容量

記憶容量是有意限制的（MEMORY.md 約 2,200 字元，USER.md 約 1,375 字元）。當容量滿了，Agent 會整合舊項目。您可以透過說「清理你的記憶」或「替換掉舊的 Python 3.9 筆記 —— 我們現在使用 3.12 了」來提供協助。

### 讓 Agent 記住

在一個高效的工作階段結束後，說「記住這點以備下次使用」，Agent 就會儲存關鍵要點。您也可以更具體一點：「將『我們的 CI 使用 GitHub Actions 搭配 deploy.yml 工作流』儲存到記憶中」。

:::warning 警告
記憶是凍結的快照 —— 在工作階段中所做的更改直到下一個工作階段開始前，不會出現在系統提示語中。Agent 會立即寫入磁碟，但提示語快取（Prompt Cache）在工作階段中途不會失效。
:::

## 效能與成本

### 不要破壞提示語快取 (Prompt Cache)

大多數 LLM 提供者會快取系統提示語前綴。如果您保持系統提示語穩定（相同的上下文檔案、相同的記憶），工作階段中後續的訊息將獲得顯著便宜的**快取命中（Cache Hits）**。避免在工作階段中途更改模型或系統提示語。

### 在達到限制前使用 /compress

長對話會累積 Token。當您注意到回應變慢或被截斷時，請執行 `/compress`。這會總結對話歷史，保留關鍵上下文，同時大幅減少 Token 數量。使用 `/usage` 檢查您的當前狀態。

### 使用委派進行平行工作

需要同時研究三個主題？讓 Agent 使用具備平行子任務的 `delegate_task`。每個子 Agent 都會在自己的上下文中獨立運行，只有最終摘要會返回 —— 這能大幅減少您主要對話的 Token 使用量。

### 對批次操作使用 execute_code

與其逐一執行終端機指令，不如讓 Agent 撰寫一個腳本一次完成所有操作。與逐一重新命名檔案相比，「撰寫一個 Python 腳本將所有 `.jpeg` 檔案重新命名為 `.jpg` 並執行它」更便宜且更快速。

### 選擇正確的模型

使用 `/model` 在工作階段中途切換模型。對於複雜的推理和架構決策，使用頂尖模型（Claude Sonnet/Opus, GPT-4o）。對於簡單任務（如格式化、重新命名或生成模板程式碼），切換到更快的模型。

:::tip 提示
定期執行 `/usage` 以查看您的 Token 消耗情況。執行 `/insights` 以查看過去 30 天使用模式的更廣泛視圖。
:::

## 訊息平台技巧

### 設定主頻道 (Home Channel)

在您偏好的 Telegram 或 Discord 聊天中使用 `/sethome` 將其指定為主頻道。Cron 任務結果和排程任務輸出將會遞送到這裡。若未設定，Agent 將無處傳送主動訊息。

### 使用 /title 組織工作階段

使用 `/title auth-refactor` 或 `/title research-llm-quantization` 為您的工作階段命名。具名工作階段很容易透過 `hermes sessions list` 找到，並透過 `hermes -r "auth-refactor"` 恢復。未命名的工作階段會堆積如山，難以分辨。

### 使用私訊配對提供團隊存取權限

與其手動收集使用者 ID 來設定允許列表（Allowlist），不如啟用私訊配對（DM Pairing）。當團隊成員私訊機器人時，他們會收到一個一次性配對碼。您只需使用 `hermes pairing approve telegram XKGH5N7P` 進行核准 —— 簡單且安全。

### 工具進度顯示模式

使用 `/verbose` 來控制您看到的工具活動量。在訊息平台上，通常越少越好 —— 保持在「new」模式以僅查看新的工具呼叫。在 CLI 中，「all」模式能讓您即時看到 Agent 的所有操作。

:::tip 提示
在訊息平台上，工作階段會在閒置一段時間後（預設：24 小時）或每天凌晨 4 點自動重設。如果您需要更長的工作階段，請在 `~/.hermes/config.yaml` 中針對各平台進行調整。
:::

## 安全性

### 對不信任的程式碼使用 Docker

當處理不信任的儲存庫或執行不熟悉的程式碼時，請使用 Docker 或 Daytona 作為您的終端機後端。在您的 `.env` 中設定 `TERMINAL_BACKEND=docker`。容器內的破壞性指令不會傷害您的宿主機系統。

```bash
# 在您的 .env 中：
TERMINAL_BACKEND=docker
TERMINAL_DOCKER_IMAGE=hermes-sandbox:latest
```

### 避免 Windows 編碼陷阱

在 Windows 上，某些預設編碼（如 `cp125x`）無法表示所有 Unicode 字元，這在測試或腳本中寫入檔案時可能會導致 `UnicodeEncodeError`。

- 建議在開啟檔案時明確指定 UTF-8 編碼：

```python
with open("results.txt", "w", encoding="utf-8") as f:
    f.write("✓ All good\n")
```

- 在 PowerShell 中，您也可以將當前工作階段的控制台和原生指令輸出切換為 UTF-8：

```powershell
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
```

這能讓 PowerShell 和子程序保持在 UTF-8 編碼，並有助於避免僅在 Windows 上出現的失敗。

### 在選擇「Always」前請三思

當 Agent 觸發危險指令核准（如 `rm -rf`、`DROP TABLE` 等）時，您會看到四個選項：**once（一次）**、**session（工作階段）**、**always（始終）**、**deny（拒絕）**。在選擇「always」之前請仔細考慮 —— 這會永久允許該模式。在您感到放心之前，請先從「session」開始。

### 指令核准是您的安全網

Hermes 在執行前會根據一份精心整理的危險模式列表檢查每一條指令。這包括遞迴刪除、SQL 刪除（Drop）、將 curl 導向 Shell 等等。請不要在生產環境中停用此功能 —— 它的存在有其充分理由。

:::warning 警告
當運行在容器後端（Docker、Singularity、Modal, Daytona）時，危險指令檢查會被**跳過**，因為容器本身就是安全邊界。請確保您的容器映像檔已妥善鎖定。
:::

### 對訊息機器人使用允許列表 (Allowlist)

永遠不要在具有終端機存取權限的機器人上設定 `GATEWAY_ALLOW_ALL_USERS=true`。始終使用平台特定的允許列表（`TELEGRAM_ALLOWED_USERS`、`DISCORD_ALLOWED_USERS`）或私訊配對來控制誰可以與您的 Agent 互動。

```bash
# 推薦：針對各個平台設定明確的允許列表
TELEGRAM_ALLOWED_USERS=123456789,987654321
DISCORD_ALLOWED_USERS=123456789012345678

# 或者使用跨平台允許列表
GATEWAY_ALLOWED_USERS=123456789,987654321
```

---

*有建議應該收錄在此頁面嗎？歡迎提出 Issue 或 PR —— 社群貢獻深受歡迎。*
