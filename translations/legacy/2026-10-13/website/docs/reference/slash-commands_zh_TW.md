---
sidebar_position: 2
title: "斜線指令參考"
description: "互動式 CLI 與即時通訊斜線指令的完整參考說明"
---

# 斜線指令參考

Hermes 有兩個斜線指令介面，均由 `hermes_cli/commands.py` 中的中央 `COMMAND_REGISTRY` 驅動：

- **互動式 CLI 斜線指令** — 由 `cli.py` 分派，並具有來自註冊表的自動補全功能。
- **即時通訊斜線指令** — 由 `gateway/run.py` 分派，說明文字與平台選單均由註冊表生成。

已安裝的技能也會在兩個介面上以動態斜線指令的形式公開。這包含內建技能如 `/plan`，它會開啟規劃模式，並在相對於主動工作區/後端工作目錄的 `.hermes/plans/` 下儲存 Markdown 規劃檔案。

## 互動式 CLI 斜線指令

在 CLI 中輸入 `/` 以開啟自動補全選單。內建指令不區分大小寫。

### 工作階段 (Session)

| 指令 | 描述 |
|---------|-------------|
| `/new` (別名：`/reset`) | 開始新工作階段 (新的工作階段 ID 與歷史記錄) |
| `/clear` | 清除螢幕並開始新工作階段 |
| `/history` | 顯示對話歷史 |
| `/save` | 儲存當前對話 |
| `/retry` | 重試最後一則訊息 (重新發送給代理) |
| `/undo` | 移除最後一次的使用者/助手對話 |
| `/title` | 為當前工作階段設置標題 (用法：/title 我的對話名稱) |
| `/compress [焦點主題]` | 手動壓縮對話上下文 (清除記憶 + 摘要)。選填的焦點主題可縮小摘要保留的內容。 |
| `/rollback` | 列出或還原檔案系統檢查點 (用法：/rollback [編號]) |
| `/snapshot [create\|restore <id>\|prune]` (別名：`/snap`) | 建立或還原 Hermes 配置/狀態的快照。`create [標籤]` 儲存快照，`restore <id>` 還原至該快照，`prune [N]` 移除舊快照，若不帶參數則列出所有快照。 |
| `/stop` | 結束所有正在執行的背景程序 |
| `/queue <prompt>` (別名：`/q`) | 將提示詞排入下一輪 (不會中斷當前的代理回應)。**注意：** `/q` 同時被 `/queue` 與 `/quit` 使用；以最後註冊的為準，實際上 `/q` 會解析為 `/quit`。請明確使用 `/queue`。 |
| `/resume [名稱]` | 恢復先前命名的工作階段 |
| `/status` | 顯示工作階段資訊 |
| `/snapshot` (別名：`/snap`) | 建立或還原 Hermes 配置/狀態的快照 (用法：/snapshot [create\|restore \<id\>\|prune]) |
| `/background <prompt>` (別名：`/bg`) | 在獨立的背景工作階段執行提示詞。代理會獨立處理您的提示詞 — 當前工作階段仍可用於其他工作。任務完成後結果會以面板形式出現。參閱 [CLI 背景工作階段](/docs/user-guide/cli#background-sessions)。 |
| `/btw <問題>` | 使用工作階段上下文的臨時側向問題 (不使用工具，不持久化)。適用於快速澄清而不會影響對話歷史。 |
| `/plan [請求]` | 載入內建的 `plan` 技能以撰寫 Markdown 規劃而非執行工作。規劃檔案儲存在相對於主動工作區/後端工作目錄的 `.hermes/plans/` 下。 |
| `/branch [名稱]` (別名：`/fork`) | 分支當前工作階段 (探索不同的路徑) |

### 配置 (Configuration)

| 指令 | 描述 |
|---------|-------------|
| `/config` | 顯示當前配置 |
| `/model [模型名稱]` | 顯示或變更當前模型。支援：`/model claude-sonnet-4`、`/model provider:model` (切換提供商)、`/model custom:model` (自定義端點)、`/model custom:name:model` (具名自定義提供商)、`/model custom` (從端點自動偵測)。使用 `--global` 將變更永久保存至 config.yaml。**注意：** `/model` 僅能切換已配置的提供商。若要新增提供商，請退出工作階段並從終端機執行 `hermes model`。 |
| `/provider` | 顯示可用的提供商與當前提供商 |
| `/personality` | 設置預定義的個性 |
| `/verbose` | 循環切換工具進度顯示：off → new → all → verbose。可透過配置為 [即時通訊平台啟用](#注意事項)。 |
| `/fast` | 切換快速模式 — OpenAI 優先處理 / Anthropic 快速模式 (用法：/fast [normal\|fast\|status]) |
| `/reasoning` | 管理推理強度與顯示 (用法：/reasoning [level\|show\|hide]) |
| `/fast [normal\|fast\|status]` | 切換快速模式 — OpenAI 優先處理 / Anthropic 快速模式。選項：`normal`, `fast`, `status`, `on`, `off`。 |
| `/skin` | 顯示或變更顯示面板皮膚/主題 |
| `/statusbar` (別名：`/sb`) | 切換上下文/模型狀態列的開啟或關閉 |
| `/voice [on\|off\|tts\|status]` | 切換 CLI 語音模式與語音播放。錄音使用 `voice.record_key` (預設：`Ctrl+B`)。 |
| `/yolo` | 切換 YOLO 模式 — 跳過所有危險指令的核准提示。 |

### 工具與技能 (Tools & Skills)

| 指令 | 描述 |
|---------|-------------|
| `/tools [list\|disable\|enable] [名稱...]` | 管理工具：列出可用工具，或為當前工作階段停用/啟用特定工具。停用工具會將其從代理的工具集中移除並觸發工作階段重設。 |
| `/toolsets` | 列出可用的工具集 |
| `/browser [connect\|disconnect\|status]` | 管理本地 Chrome CDP 連線。`connect` 將瀏覽器工具附加至執行中的 Chrome 實例 (預設：`ws://localhost:9222`)。`disconnect` 斷開連線。`status` 顯示當前連線。若未偵測到除錯器則自動啟動 Chrome。 |
| `/skills` | 從線上註冊表搜尋、安裝、檢查或管理技能 |
| `/cron` | 管理排程任務 (列出、新增/建立、編輯、暫停、恢復、執行、移除) |
| `/reload-mcp` (別名：`/reload_mcp`) | 從 config.yaml 重新載入 MCP 伺服器 |
| `/reload` | 將 `.env` 變數重新載入至執行中的工作階段 (無需重啟即可套用新的 API 金鑰) |
| `/plugins` | 列出已安裝的插件及其狀態 |

### 資訊 (Info)

| 指令 | 描述 |
|---------|-------------|
| `/help` | 顯示此說明訊息 |
| `/usage` | 顯示權杖使用量、成本細分與工作階段時長 |
| `/insights` | 顯示使用見解與分析 (最近 30 天) |
| `/platforms` (別名：`/gateway`) | 顯示網關/即時通訊平台狀態 |
| `/paste` | 檢查剪貼簿中的圖片並附加 |
| `/image <路徑>` | 為下一則提示詞附加本地圖片檔案。 |
| `/debug` | 上傳除錯報告 (系統資訊 + 日誌) 並獲取分享連結。亦可用於即時通訊。 |
| `/profile` | 顯示主動設定檔名稱與家目錄 |

### 結束 (Exit)

| 指令 | 描述 |
|---------|-------------|
| `/quit` | 退出 CLI (亦可使用：`/exit`)。請參閱上方 `/queue` 指令中關於 `/q` 的說明。 |

### 動態 CLI 斜線指令

| 指令 | 描述 |
|---------|-------------|
| `/<技能名稱>` | 將任何已安裝的技能作為按需指令載入。例如：`/gif-search`, `/github-pr-workflow`, `/excalidraw`。 |
| `/skills ...` | 從註冊表與官方選配技能目錄中搜尋、瀏覽、檢查、安裝、稽核、發佈與配置技能。 |

### 快速指令 (Quick Commands)

使用者定義的快速指令可將短別名映射到較長的提示詞。請在 `~/.hermes/config.yaml` 中配置：

```yaml
quick_commands:
  review: "審查我最新的 git diff 並提供改進建議"
  deploy: "執行 scripts/deploy.sh 中的部署腳本並驗證輸出"
  morning: "檢查我的行事曆、未讀郵件並摘要今日的優先事項"
```

然後在 CLI 中輸入 `/review`, `/deploy` 或 `/morning`。快速指令在分派時解析，且不會顯示在內建的自動補全/說明表格中。

### 別名解析 (Alias Resolution)

指令支援字首匹配：輸入 `/h` 會解析為 `/help`，`/mod` 會解析為 `/model`。當字首具備歧義 (匹配多個指令) 時，以註冊表順序中的第一個匹配項為準。完整指令名稱與已註冊的別名始終優先於字首匹配。

## 即時通訊斜線指令 (Messaging slash commands)

即時通訊網關在 Telegram、Discord、Slack、WhatsApp、Signal、電子郵件以及 Home Assistant 聊天中支援以下內建指令：

| 指令 | 描述 |
|---------|-------------|
| `/new` | 開始新對話。 |
| `/reset` | 重設對話歷史。 |
| `/status` | 顯示工作階段資訊。 |
| `/stop` | 結束所有正在執行的背景程序並中斷執行中的代理。 |
| `/model [provider:model]` | 顯示或變更模型。支援提供商切換 (`/model zai:glm-5`)、自定義端點 (`/model custom:model`)、具名自定義提供商 (`/model custom:local:qwen`) 以及自動偵測 (`/model custom`)。使用 `--global` 將變更永久保存至 config.yaml。**注意：** `/model` 僅能切換已配置的提供商。若要新增提供商或設置 API 金鑰，請從終端機執行 `hermes model` (在聊天工作階段之外)。 |
| `/provider` | 顯示提供商可用性與驗證狀態。 |
| `/personality [名稱]` | 為工作階段設置個性化疊加。 |
| `/fast [normal\|fast\|status]` | 切換快速模式 — OpenAI 優先處理 / Anthropic 快速模式。 |
| `/retry` | 重試最後一則訊息。 |
| `/undo` | 移除最後一次對話。 |
| `/sethome` (別名：`/set-home`) | 將當前聊天標記為平台的通訊家目錄頻道，用於傳遞訊息。 |
| `/compress [焦點主題]` | 手動壓縮對話上下文。選填的焦點主題可縮小摘要保留的內容。 |
| `/title [名稱]` | 設置或顯示工作階段標題。 |
| `/resume [名稱]` | 恢復先前命名的工作階段。 |
| `/usage` | 顯示權杖使用量、預估成本細分 (輸入/輸出)、上下文視窗狀態與工作階段時長。 |
| `/insights [天數]` | 顯示使用分析。 |
| `/reasoning [level\|show\|hide]` | 變更推理強度或切換推理顯示。 |
| `/voice [on\|off\|tts\|join\|channel\|leave\|status]` | 控制聊天中的語音回覆。`join`/`channel`/`leave` 用於管理 Discord 語音頻道模式。 |
| `/rollback [編號]` | 列出或還原檔案系統檢查點。 |
| `/snapshot [create\|restore <id>\|prune]` (別名：`/snap`) | 建立或還原 Hermes 配置/狀態的快照。 |
| `/background <prompt>` | 在獨立的背景工作階段執行提示詞。任務完成後結果會傳回至同一個聊天。參閱 [即時通訊背景工作階段](/docs/user-guide/messaging/#background-sessions)。 |
| `/plan [請求]` | 載入內建的 `plan` 技能以撰寫 Markdown 規劃而非執行工作。規劃檔案儲存在相對於主動工作區/後端工作目錄的 `.hermes/plans/` 下。 |
| `/reload-mcp` (別名：`/reload_mcp`) | 從配置中重新載入 MCP 伺服器。 |
| `/reload` | 將 `.env` 變數重新載入至執行中的工作階段。 |
| `/yolo` | 切換 YOLO 模式 — 跳過所有危險指令的核准提示。 |
| `/commands [頁碼]` | 瀏覽所有指令與技能 (分頁顯示)。 |
| `/approve [session\|always]` | 核准並執行待處理的危險指令。`session` 僅針對此工作階段核准；`always` 則將其加入永久允許列表。 |
| `/deny` | 拒絕待處理的危險指令。 |
| `/update` | 將 Hermes Agent 更新至最新版本。 |
| `/restart` | 在排空主動執行項後優雅地重啟網關。網關重新上線後會向請求者的聊天/執行緒發送確認。 |
| `/debug` | 上傳除錯報告 (系統資訊 + 日誌) 並獲取分享連結。 |
| `/help` | 顯示即時通訊說明。 |
| `/<技能名稱>` | 依名稱呼叫任何已安裝的技能。 |

## 注意事項

- `/skin`, `/tools`, `/toolsets`, `/browser`, `/config`, `/cron`, `/skills`, `/platforms`, `/paste`, `/image`, `/statusbar`, 與 `/plugins` 是 **僅限 CLI** 的指令。
- `/verbose` **預設為僅限 CLI**，但可透過在 `config.yaml` 中設置 `display.tool_progress_command: true` 為即時通訊平台啟用。啟用後，它會循環切換 `display.tool_progress` 模式並儲存至配置。
- `/sethome`, `/update`, `/restart`, `/approve`, `/deny`, 與 `/commands` 是 **僅限即時通訊** 的指令。
- `/status`, `/background`, `/voice`, `/reload-mcp`, `/rollback`, `/snapshot`, `/debug`, `/fast`, 與 `/yolo` 在 CLI 與即時通訊網關中 **均可使用**。
- `/voice join`, `/voice channel`, 與 `/voice leave` 僅在 Discord 中有意義。
