---
sidebar_position: 1
title: "CLI 介面"
description: "精通 Hermes Agent 終端機介面 — 指令、快捷鍵、個性等"
---

# CLI 介面

Hermes Agent 的 CLI 是一個完整的終端機使用者介面 (TUI) — 而不是網頁 UI。它具有多行編輯、斜線指令自動補全、對話歷史記錄、中斷與重新導向以及串流工具輸出。專為生活在終端機中的人而設計。

## 執行 CLI

```bash
# 開始互動式階段 (預設)
hermes

# 單次查詢模式 (非互動式)
hermes chat -q "Hello"

# 使用特定模型
hermes chat --model "anthropic/claude-sonnet-4"

# 使用特定提供商
hermes chat --provider nous        # 使用 Nous Portal
hermes chat --provider openrouter  # 強制使用 OpenRouter

# 使用特定工具集
hermes chat --toolsets "web,terminal,skills"

# 啟動時預載一個或多個技能
hermes -s hermes-agent-dev,github-auth
hermes chat -s github-pr-workflow -q "open a draft PR"

# 恢復先前的會話
hermes --continue             # 恢復最近的 CLI 會話 (-c)
hermes --resume <session_id>  # 依 ID 恢復特定會話 (-r)

# 詳細模式 (偵錯輸出)
hermes chat --verbose

# 隔離的 git worktree (用於平行執行多個 Agent)
hermes -w                         # 在 worktree 中進行互動模式
hermes -w -q "Fix issue #123"     # 在 worktree 中進行單次查詢
```

## 介面佈局

<img className="docs-terminal-figure" src="/img/docs/cli-layout.svg" alt="Hermes CLI 佈局的風格化預覽，顯示橫幅、對話區域和固定輸入提示符。" />
<p className="docs-figure-caption">Hermes CLI 橫幅、對話流和固定輸入提示符渲染為穩定的文件圖表，而非脆弱的文字藝術。</p>

歡迎橫幅讓您一眼就能看到模型、終端機後端、工作目錄、可用工具和已安裝的技能。

### 狀態列

輸入區域上方有一個持久的狀態列，會即時更新：

```
 ⚕ claude-sonnet-4-20250514 │ 12.4K/200K │ [██████░░░░] 6% │ $0.06 │ 15m
```

| 元素 | 描述 |
|---------|-------------|
| 模型名稱 | 目前模型 (若超過 26 個字元則會被截斷) |
| Token 計數 | 已使用的上下文 Token / 最大上下文視窗 |
| 上下文列 | 帶有顏色編碼閾值的視覺填充指示器 |
| 費用 | 預估會話費用 (對於未知或零價模型則顯示 `n/a`) |
| 持續時間 | 會話已過時間 |

狀態列會根據終端機寬度進行調整 — 寬度 ≥ 76 行時顯示完整佈局，52–75 行為緊湊型，低於 52 行則為極簡型 (僅顯示模型 + 持續時間)。

**上下文顏色編碼：**

| 顏色 | 閾值 | 意義 |
|-------|-----------|---------|
| 綠色 | < 50% | 空間充裕 |
| 黃色 | 50–80% | 快滿了 |
| 橘色 | 80–95% | 接近限制 |
| 紅色 | ≥ 95% | 接近溢位 — 請考慮使用 `/compress` |

使用 `/usage` 查看詳細明細，包括各類別費用 (輸入與輸出 Token)。

### 會話恢復顯示

當恢復先前的會話 (`hermes -c` 或 `hermes --resume <id>`) 時，橫幅和輸入提示符之間會出現「先前對話 (Previous Conversation)」面板，顯示對話歷史記錄的緊湊回顧。有關詳細資訊和配置，請參閱 [會話 — 恢復時的對話回顧](sessions.md#conversation-recap-on-resume)。

## 快捷鍵

| 按鍵 | 動作 |
|-----|--------|
| `Enter` | 發送訊息 |
| `Alt+Enter` 或 `Ctrl+J` | 換行 (多行輸入) |
| `Alt+V` | 當終端機支援時，從剪貼簿貼上圖片 |
| `Ctrl+V` | 貼上文字並伺機附加剪貼簿圖片 |
| `Ctrl+B` | 啟用語音模式時開始/停止錄音 (`voice.record_key`，預設：`ctrl+b`) |
| `Ctrl+C` | 中斷 Agent (2秒內按兩次可強制退出) |
| `Ctrl+D` | 退出 |
| `Ctrl+Z` | 將 Hermes 暫停至背景 (僅限 Unix)。在 Shell 中執行 `fg` 以恢復。 |
| `Tab` | 接受自動建議 (灰字) 或自動補全斜線指令 |

## 斜線指令

輸入 `/` 即可看到自動補全選單。Hermes 支援大量的 CLI 斜線指令、動態技能指令和使用者定義的快速指令。

常見範例：

| 指令 | 描述 |
|---------|-------------|
| `/help` | 顯示指令說明 |
| `/model` | 顯示或變更目前模型 |
| `/tools` | 列出目前可用的工具 |
| `/skills browse` | 瀏覽技能中心和官方選用技能 |
| `/background <prompt>` | 在獨立的背景會話中執行提示詞 |
| `/skin` | 顯示或切換作用中的 CLI 外觀 (Skin) |
| `/voice on` | 啟動 CLI 語音模式 (按 `Ctrl+B` 錄音) |
| `/voice tts` | 切換 Hermes 回覆的語音播放 |
| `/reasoning high` | 增加推理力度 |
| `/title My Session` | 為目前會話命名 |

有關完整的內建 CLI 和通訊軟體清單，請參閱 [斜線指令參考](../reference/slash-commands.md)。

有關設定、提供商、靜音調整以及通訊軟體/Discord 語音使用，請參閱 [語音模式](features/voice-mode.md)。

:::tip
指令不分大小寫 — `/HELP` 與 `/help` 效果相同。安裝的技能也會自動變成斜線指令。
:::

## 快速指令 (Quick Commands)

您可以定義自訂指令，無需調用 LLM 即可立即執行 Shell 指令。這些指令在 CLI 和通訊平台 (Telegram、Discord 等) 中皆可運作。

```yaml
# ~/.hermes/config.yaml
quick_commands:
  status:
    type: exec
    command: systemctl status hermes-agent
  gpu:
    type: exec
    command: nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv,noheader
```

接著在任何聊天中輸入 `/status` 或 `/gpu` 即可。更多範例請參閱 [配置指南](/docs/user-guide/configuration#quick-commands)。

## 啟動時預載技能

如果您在會話開始前就已知要啟動哪些技能，請在啟動時傳入它們：

```bash
hermes -s hermes-agent-dev,github-auth
hermes chat -s github-pr-workflow -s github-auth
```

Hermes 會在第一輪對話前將每個命名的技能載入會話提示詞中。相同的標記在互動模式和單次查詢模式下均有效。

## 技能斜線指令

`~/.hermes/skills/` 中每個已安裝的技能都會自動註冊為斜線指令。技能名稱即為指令：

```
/gif-search funny cats
/axolotl help me fine-tune Llama 3 on my dataset
/github-pr-workflow create a PR for the auth refactor

# 僅輸入技能名稱即可載入，並讓 Agent 詢問您的需求：
/excalidraw
```

## 個性 (Personalities)

設定預定義的個性以改變 Agent 的語氣：

```
/personality pirate
/personality kawaii
/personality concise
```

內建個性包括：`helpful` (助人)、`concise` (簡潔)、`technical` (專業)、`creative` (創意)、`teacher` (教師)、`kawaii` (可愛)、`catgirl` (貓娘)、`pirate` (海盜)、`shakespeare` (莎士比亞)、`surfer` (衝浪手)、`noir` (黑色電影)、`uwu`、`philosopher` (哲學家)、`hype` (熱血)。

您也可以在 `~/.hermes/config.yaml` 中定義自訂個性：

```yaml
personalities:
  helpful: "您是一位樂於助人且友好的 AI 助手。"
  kawaii: "您是一位可愛的助手！請使用可愛的表情..."
  pirate: "船長 Hermes 在這兒跟您說話..."
  # 增加您自己的個性！
```

## 多行輸入

有兩種方式可以輸入多行訊息：

1. **`Alt+Enter` 或 `Ctrl+J`** — 插入新行
2. **反斜線延續** — 在行尾加上 `\` 以繼續：

```
❯ 寫一個函數：\
  1. 接收一組數字清單\
  2. 回傳總和
```

:::info
支援貼上多行文字 — 使用 `Alt+Enter` 或 `Ctrl+J` 插入換行符，或直接貼上內容。
:::

## 中斷 Agent

您可以在任何時間點中斷 Agent：

- **輸入新訊息 + Enter** (當 Agent 正在工作時) — 它會中斷並處理您的新指示
- **`Ctrl+C`** — 中斷目前操作 (2 秒內按兩次可強制退出)
- 進行中的終端機指令會立即被終止 (先傳送 SIGTERM，1 秒後傳送 SIGKILL)
- 在中斷期間輸入的多則訊息會合併成一個提示詞

### 忙碌輸入模式 (Busy Input Mode)

`display.busy_input_mode` 配置鍵控制當 Agent 正在工作時按下 Enter 會發生什麼事：

| 模式 | 行為 |
|------|----------|
| `"interrupt"` (預設) | 您的訊息會中斷目前操作並立即處理 |
| `"queue"` | 您的訊息會被靜默加入佇列，並在 Agent 完成後作為下一輪對話發送 |

```yaml
# ~/.hermes/config.yaml
display:
  busy_input_mode: "queue"   # 或 "interrupt" (預設)
```

佇列模式在您想準備後續訊息而不想意外取消進行中的工作時非常有用。未知值會回退到 `"interrupt"`。

### 暫停至背景

在 Unix 系統上，按 **`Ctrl+Z`** 可將 Hermes 暫停至背景 — 就像任何終端機程序一樣。Shell 會顯示確認訊息：

```
Hermes Agent has been suspended. Run `fg` to bring Hermes Agent back.
```

在您的 Shell 中輸入 `fg` 即可在先前離開的位置恢復會話。此功能在 Windows 上不支援。

## 工具進度顯示

CLI 在 Agent 工作時會顯示動畫回饋：

**思考動畫** (API 調用期間)：
```
  ◜ (｡•́︿•̀｡) 思考中... (1.2s)
  ◠ (⊙_⊙) 沉思中... (2.4s)
  ✧٩(ˊᗜˋ*)و✧ 懂了！ (3.1s)
```

**工具執行流：**
```
  ┊ 💻 terminal `ls -la` (0.3s)
  ┊ 🔍 web_search (1.2s)
  ┊ 📄 web_extract (2.1s)
```

使用 `/verbose` 切換顯示模式：`off → new → all → verbose`。此指令也可以為通訊平台開啟 — 請參閱 [配置](/docs/user-guide/configuration#display-settings)。

### 工具預覽長度

`display.tool_preview_length` 配置鍵控制工具調用預覽行 (例如檔案路徑、終端機指令) 顯示的最大字元數。預設為 `0`，表示不限制 — 顯示完整路徑和指令。

```yaml
# ~/.hermes/config.yaml
display:
  tool_preview_length: 80   # 將工具預覽截斷為 80 字元 (0 = 無限制)
```

這在窄螢幕終端機或工具參數包含極長路徑時非常有用。

## 會話管理

### 恢復會話

當您退出 CLI 會話時，系統會顯示恢復指令：

```
使用以下指令恢復此會話：
  hermes --resume 20260225_143052_a1b2c3

會話：        20260225_143052_a1b2c3
持續時間：    12m 34s
訊息數：      28 (5 次使用者，18 次工具調用)
```

恢復選項：

```bash
hermes --continue                          # 恢復最近的 CLI 會話
hermes -c                                  # 簡短形式
hermes -c "my project"                     # 恢復命名的會話 (血統中的最新會話)
hermes --resume 20260225_143052_a1b2c3     # 依 ID 恢復特定會話
hermes --resume "refactoring auth"         # 依標題恢復
hermes -r 20260225_143052_a1b2c3           # 簡短形式
```

恢復會恢復 SQLite 中的完整對話歷史記錄。Agent 會看到所有先前的訊息、工具調用和回應 — 就像您從未離開過一樣。

在聊天中使用 `/title My Session Name` 為目前會話命名，或從命令列執行 `hermes sessions rename <id> <title>`。使用 `hermes sessions list` 瀏覽過去的會話。

### 會話儲存

CLI 會話儲存在 `~/.hermes/state.db` 下的 Hermes SQLite 狀態資料庫中。該資料庫保存：

- 會話詮釋資料 (ID、標題、時間戳記、Token 計數器)
- 訊息歷史記錄
- 跨壓縮/恢復會話的血統
- `session_search` 使用的全文搜尋索引

某些通訊軟體配接器也會在資料庫旁保存各平台的轉錄檔案，但 CLI 本身是從 SQLite 會話存儲恢復。

### 上下文壓縮 (Context Compression)

當接近上下文限制時，長對話會自動進行摘要：

```yaml
# 在 ~/.hermes/config.yaml 中
compression:
  enabled: true
  threshold: 0.50    # 預設在上下文限制的 50% 時進行壓縮

# 在 auxiliary 下配置摘要模型：
auxiliary:
  compression:
    model: "google/gemini-3-flash-preview"  # 用於摘要的模型
```

當觸發壓縮時，中間的輪次會被摘要，而前 3 輪和後 4 輪則始終會被保留。

## 背景會話 (Background Sessions)

在獨立的背景會話中執行提示詞，同時繼續使用 CLI 進行其他工作：

```
/background 分析 /var/log 中的日誌並摘要今天的任何錯誤
```

Hermes 會立即確認任務並將提示符交還給您：

```
🔄 背景任務 #1 已啟動："分析 /var/log 中的日誌並摘要..."
   任務 ID：bg_143022_a1b2c3
```

### 運作方式

每個 `/background` 提示詞都會在守護執行緒中生成一個**完全獨立的 Agent 會話**：

- **隔離對話** — 背景 Agent 不知道您目前會話的歷史記錄。它僅接收您提供的提示詞。
- **相同配置** — 背景 Agent 會繼承目前會話的模型、提供商、工具集、推理設定和回退模型。
- **非阻塞** — 您的前景會話保持完全互動。您可以聊天、執行指令，甚至啟動更多背景任務。
- **多項任務** — 您可以同時執行多個背景任務。每個任務都有一個編號 ID。

### 結果

當背景任務完成時，結果會以面板形式出現在您的終端機中：

```
╭─ ⚕ Hermes (背景 #1) ──────────────────────────────────╮
│ 發現今天 syslog 中的 3 個錯誤：                             │
│ 1. 03:22 調用 OOM killer — 終止程序 nginx        │
│ 2. 07:15 /dev/sda1 發生磁碟 I/O 錯誤                      │
│ 3. 14:30 來自 192.168.1.50 的 SSH 登入失敗嘗試      │
╰──────────────────────────────────────────────────────────────╯
```

如果任務失敗，您會看到錯誤通知。如果您的配置中啟用了 `display.bell_on_complete`，則任務完成時終端機會鳴響。

### 使用場景

- **耗時的研究** — 在您編寫程式碼時執行 "/background 研究量子糾錯的最新進展"
- **檔案處理** — 在您繼續對話時執行 "/background 分析此儲存庫中的所有 Python 檔案並列出任何安全性問題"
- **平行調查** — 同時啟動多個背景任務以從不同角度進行探索

:::info
背景會話不會出現在您的主對話歷史記錄中。它們是具有自己任務 ID (例如 `bg_143022_a1b2c3`) 的獨立會話。
:::

## 安靜模式 (Quiet Mode)

預設情況下，CLI 以安靜模式執行，該模式會：
- 抑制來自工具的冗長日誌
- 啟動可愛風格 (Kawaii-style) 的動畫回饋
- 保持輸出乾淨且易於閱讀

若要查看偵錯輸出：
```bash
hermes chat --verbose
```
