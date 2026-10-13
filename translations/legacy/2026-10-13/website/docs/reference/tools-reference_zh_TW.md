---
sidebar_position: 3
title: "內建工具參考"
description: "Hermes 內建工具的權威參考，按工具集分組"
---

# 內建工具參考

本頁面記錄了 Hermes 工具註冊表中的所有 47 個內建工具，按工具集分組。可用性因平台、憑證和啟用的工具集而異。

**快速統計：** 10 個瀏覽器工具、4 個檔案工具、10 個 RL 工具、4 個 Home Assistant 工具、2 個終端機工具、2 個網路工具，以及其他工具集中的 15 個獨立工具。

:::tip MCP 工具
除了內建工具外，Hermes 還可以從 MCP 伺服器動態載入工具。MCP 工具會帶有伺服器名稱前綴（例如，`github` MCP 伺服器的 `github_create_issue`）。有關配置請參閱 [MCP 整合](/docs/user-guide/features/mcp)。
:::

## `browser` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `browser_back` | 在瀏覽器歷史記錄中返回上一頁。需要先呼叫 browser_navigate。 | — |
| `browser_click` | 點擊由快照中的 ref ID（例如 '@e5'）識別的元素。ref ID 顯示在快照輸出的方括號中。需要先呼叫 browser_navigate 和 browser_snapshot。 | — |
| `browser_console` | 獲取當前頁面的瀏覽器控制台輸出和 JavaScript 錯誤。返回 console.log/warn/error/info 訊息和未捕獲的 JS 異常。使用此工具偵測靜默的 JavaScript 錯誤、失敗的 API 呼叫和應用程式警告。需要先呼叫 browser_navigate。 | — |
| `browser_get_images` | 獲取當前頁面上所有圖片的列表及其 URL 和替代文字。用於查找要使用視覺工具分析的圖片。需要先呼叫 browser_navigate。 | — |
| `browser_navigate` | 在瀏覽器中導航到一個 URL。初始化會話並載入頁面。必須在其他瀏覽器工具之前呼叫。對於簡單的資訊檢索，建議優先使用 web_search 或 web_extract（更快、更便宜）。當您需要處理... | — |
| `browser_press` | 按下鍵盤按鍵。用於提交表單 (Enter)、導航 (Tab) 或鍵盤快捷鍵。需要先呼叫 browser_navigate。 | — |
| `browser_scroll` | 朝某個方向滾動頁面。使用此工具顯示可能在當前視口下方或上方的更多內容。需要先呼叫 browser_navigate。 | — |
| `browser_snapshot` | 獲取當前頁面無障礙樹 (accessibility tree) 的文字快照。返回帶有 ref ID（如 @e1, @e2）的互動元素，用於 browser_click 和 browser_type。full=false（默認）：包含互動元素的精簡視圖。full=true：完整... | — |
| `browser_type` | 在由 ref ID 識別的輸入欄位中輸入文字。先清除欄位，然後輸入新文字。需要先呼叫 browser_navigate 和 browser_snapshot。 | — |
| `browser_vision` | 對當前頁面進行螢幕截圖並使用視覺 AI 進行分析。當您需要視覺化地理解頁面上的內容時使用此工具 - 對於驗證碼 (CAPTCHA)、視覺驗證挑戰、複雜佈局或文字快照...時特別有用。 | — |

## `clarify` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `clarify` | 當您在繼續之前需要澄清、回饋或決定時向用戶提問。支持兩種模式：1. **多選題** — 提供最多 4 個選項。用戶選擇一個或透過第 5 個「其他」選項輸入自己的答案。2. ... | — |

## `code_execution` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `execute_code` | 運行可以程式化呼叫 Hermes 工具的 Python 腳本。當您需要 3 個以上的工具呼叫且之間有處理邏輯、需要在大量工具輸出進入您的上下文之前進行過濾/減少、需要條件分支時使用此工具... | — |

## `cronjob` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `cronjob` | 統一的排程任務管理器。使用 `action="create"`、`"list"`、`"update"`、`"pause"`、`"resume"`、`"run"` 或 `"remove"` 來管理作業。支持帶有一個或多個附加技能的技能支援作業，更新時 `skills=[]` 會清除附加技能。Cron 運行在沒有當前聊天上下文的新會話中進行。 | — |

## `delegation` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `delegate_task` | 產生一個或多個子代理 (subagent) 在隔離的上下文中處理任務。每個子代理都有自己的對話、終端機工作階段和工具集。僅返回最終摘要 - 中間工具結果永遠不會進入您的上下文窗口。兩種... | — |

## `file` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `patch` | 對檔案進行有針對性的尋找並替換編輯。在終端機中以此代替 sed/awk。使用模糊匹配（9 種策略），因此微小的空格/縮進差異不會破壞它。返回統一差異 (unified diff)。編輯後自動運行語法檢查... | — |
| `read_file` | 讀取帶有行號和分頁的文字檔案。在終端機中以此代替 cat/head/tail。輸出格式：'行號\|內容'。如果找不到，會建議類似的檔名。對於大型檔案，使用 offset 和 limit。注意：無法讀取圖片或... | — |
| `search_files` | 搜尋檔案內容或按名稱查找檔案。在終端機中以此代替 grep/rg/find/ls。基於 ripgrep，比 shell 等效工具更快。內容搜尋 (target='content')：檔案內的正規表示式搜尋。輸出模式：帶有行號的完整匹配... | — |
| `write_file` | 將內容寫入檔案，完全替換現有內容。在終端機中以此代替 echo/cat heredoc。自動建立父目錄。**覆寫**整個檔案 — 有針對性的編輯請使用 'patch'。 | — |

## `homeassistant` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `ha_call_service` | 呼叫 Home Assistant 服務來控制設備。使用 ha_list_services 發現每個領域的可用服務及其參數。 | — |
| `ha_get_state` | 獲取單個 Home Assistant 實體的詳細狀態，包括所有屬性（亮度、顏色、溫度設定點、感測器讀數等）。 | — |
| `ha_list_entities` | 列出 Home Assistant 實體。可選擇按領域（light, switch, climate, sensor, binary_sensor, cover, fan 等）或按區域名稱（客廳、廚房、臥室等）進行過濾。 | — |
| `ha_list_services` | 列出用於設備控制的可用 Home Assistant 服務（動作）。顯示可以在每種設備類型上執行的動作及其接受的參數。使用此工具探索如何控制透過 ha_list_entities 找到的設備。 | — |

:::note
**Honcho 工具** (`honcho_conclude`, `honcho_context`, `honcho_profile`, `honcho_search`) 不再內建。它們可透過 `plugins/memory/honcho/` 的 Honcho 記憶提供者插件取得。有關安裝和使用，請參閱 [插件](../user-guide/features/plugins.md)。
:::

## `image_gen` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `image_generate` | 使用 FLUX 2 Pro 模型從文字提示生成高品質圖片，並自動進行 2 倍放大。建立詳細且具藝術感的圖片，並自動放大以獲得高解析度結果。返回單個放大後的圖片 URL。使用...顯示它 | FAL_KEY |

## `memory` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `memory` | 將重要資訊儲存到跨工作階段持久存在的持久記憶中。您的記憶在對話開始時出現在系統提示中 - 這是您在對話之間記住有關用戶和環境事物的方式。何時儲存... | — |

## `messaging` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `send_message` | 向連接的訊息平台發送訊息，或列出可用目標。重要：當用戶要求發送到特定頻道或人員（而不僅僅是基本的平台名稱）時，請先呼叫 send_message(action='list') 以查看可用目標... | — |

## `moa` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `mixture_of_agents` | 協作式地透過多個前沿 LLM 路由困難問題。進行 5 次 API 呼叫（4 個參考模型 + 1 個聚合器），並投入最大推理努力 - 謹慎地用於真正困難的問題。最適合：複雜數學、進階算法... | OPENROUTER_API_KEY |

## `rl` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `rl_check_status` | 獲取訓練運行的狀態和指標。速率限制：對同一次運行強制執行 30 分鐘的最小檢查間隔。返回 WandB 指標：step, state, reward_mean, loss, percent_correct。 | TINKER_API_KEY, WANDB_API_KEY |
| `rl_edit_config` | 更新配置欄位。先使用 rl_get_current_config() 查看所選環境的所有可用欄位。每個環境都有不同的可配置選項。基礎設施設定（tokenizer, URLs, lora_rank, learning_rate... | TINKER_API_KEY, WANDB_API_KEY |
| `rl_get_current_config` | 獲取當前環境配置。僅返回可以修改的欄位：group_size, max_token_length, total_steps, steps_per_eval, use_wandb, wandb_name, max_num_workers。 | TINKER_API_KEY, WANDB_API_KEY |
| `rl_get_results` | 獲取已完成訓練運行的最終結果和指標。返回最終指標和訓練權重的路徑。 | TINKER_API_KEY, WANDB_API_KEY |
| `rl_list_environments` | 列出所有可用的 RL 環境。返回環境名稱、路徑和描述。提示：使用檔案工具讀取 file_path 以了解每個環境的工作原理（驗證器、資料載入、獎勵）。 | TINKER_API_KEY, WANDB_API_KEY |
| `rl_list_runs` | 列出所有訓練運行（活動和已完成）及其狀態。 | TINKER_API_KEY, WANDB_API_KEY |
| `rl_select_environment` | 選擇一個 RL 環境進行訓練。載入環境的預設配置。選擇後，使用 rl_get_current_config() 查看設定，使用 rl_edit_config() 進行修改。 | TINKER_API_KEY, WANDB_API_KEY |
| `rl_start_training` | 使用當前環境和配置啟動新的 RL 訓練運行。大多數訓練參數（lora_rank, learning_rate 等）是固定的。在開始之前，使用 rl_edit_config() 設定 group_size, batch_size, wandb_project。警告：訓練... | TINKER_API_KEY, WANDB_API_KEY |
| `rl_stop_training` | 停止正在運行的訓練作業。如果指標看起來很差、訓練停滯或您想嘗試不同的設定，請使用此工具。 | TINKER_API_KEY, WANDB_API_KEY |
| `rl_test_inference` | 對任何環境進行快速推理測試。使用 OpenRouter 運行幾步推理 + 評分。默認：3 步 x 16 次完成 = 每個模型 48 個 rollout，測試 3 個模型 = 總共 144 個。測試環境載入、提示構建、推理... | TINKER_API_KEY, WANDB_API_KEY |

## `session_search` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `session_search` | 搜尋您過去對話的長期記憶。這是您的回想能力 — 每個過去的工作階段都是可搜尋的，且此工具會總結發生了什麼。在以下情況主動使用此工具：- 用戶說「我們之前做過這個」、「記得那次」、「上次... | — |

## `skills` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `skill_manage` | 管理技能（建立、更新、刪除）。技能是您的程序性記憶 — 針對重複性任務類型的可重複使用方法。新技能儲存在 ~/.hermes/skills/；現有技能可以在其所在地點進行修改。動作：create (完整 SKILL.m... | — |
| `skill_view` | 技能允許載入有關特定任務和工作流程的資訊，以及腳本和範本。載入技能的完整內容或存取其連結的檔案（參考、範本、腳本）。第一次呼叫返回 SKILL.md 內容加上... | — |
| `skills_list` | 列出可用技能（名稱 + 描述）。使用 skill_view(name) 載入完整內容。 | — |

## `terminal` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `process` | 管理使用 terminal(background=true) 啟動的背景程序。動作：'list'（顯示全部）、'poll'（檢查狀態 + 新輸出）、'log'（分頁顯示完整輸出）、'wait'（阻塞直到完成或超時）、'kill'（終止）、'write'（發送... | — |
| `terminal` | 在 Linux 環境中執行 shell 指令。檔案系統在呼叫之間保持不變。為長期運行的伺服器設定 `background=true`。設定 `notify_on_complete=true`（配合 `background=true`）在程序完成時獲取自動通知 — 無需輪詢。請勿使用 cat/head/tail — 使用 read_file。請勿使用 grep/rg/find — 使用 search_files。 | — |

## `todo` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `todo` | 管理當前工作階段的任務清單。用於具有 3 個以上步驟的複雜任務或當用戶提供多個任務時。不帶參數呼叫以讀取當前清單。寫入：- 提供 'todos' 陣列以建立/更新項目 - merge=... | — |

## `vision` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `vision_analyze` | 使用 AI 視覺分析圖片。提供全面的描述並回答有關圖片內容的特定問題。 | — |

## `web` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `web_search` | 在網路上搜尋有關任何主題的資訊。返回最多 5 個包含標題、URL 和描述的相關結果。 | EXA_API_KEY 或 PARALLEL_API_KEY 或 FIRECRAWL_API_KEY 或 TAVILY_API_KEY |
| `web_extract` | 從網頁 URL 提取內容。以 markdown 格式返回頁面內容。也適用於 PDF URL — 直接傳遞 PDF 連結，它會轉換為 markdown 文字。5000 字元以下的頁面返回完整 markdown；較大的頁面會由 LLM 進行摘要。 | EXA_API_KEY 或 PARALLEL_API_KEY 或 FIRECRAWL_API_KEY 或 TAVILY_API_KEY |

## `tts` 工具集

| 工具 | 描述 | 需要環境變數 |
|------|-------------|----------------------|
| `text_to_speech` | 將文字轉換為語音音訊。返回一個 MEDIA: 路徑，平台將其作為語音訊息傳送。在 Telegram 上它以語音氣泡播放，在 Discord/WhatsApp 上作為音訊附件。在 CLI 模式下，儲存到 ~/voice-memos/。語音和提供者... | — |
