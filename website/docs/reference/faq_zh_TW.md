---
sidebar_position: 3
title: "常見問題與疑難排解"
description: "Hermes Agent 的常見問題與常見問題解決方案"
---

# 常見問題與疑難排解

針對最常見問題與疑難的快速解答與修復。

---

## 常見問題

### Hermes 支援哪些 LLM 提供商？

Hermes Agent 可與任何相容於 OpenAI 的 API 配合使用。支援的提供商包括：

- **[OpenRouter](https://openrouter.ai/)** — 透過一個 API 金鑰存取數百種模型 (建議使用以獲得最大靈活性)
- **Nous Portal** — Nous Research 自己的推論端點
- **OpenAI** — GPT-4o, o1, o3 等
- **Anthropic** — Claude 模型 (透過 OpenRouter 或相容代理)
- **Google** — Gemini 模型 (透過 OpenRouter 或相容代理)
- **z.ai / 智譜清言** — GLM 模型
- **Kimi / 月之暗面 AI** — Kimi 模型
- **MiniMax** — 全球與中國端點
- **在地模型** — 透過 [Ollama](https://ollama.com/), [vLLM](https://docs.vllm.ai/), [llama.cpp](https://github.com/ggerganov/llama.cpp), [SGLang](https://github.com/sgl-project/sglang) 或任何相容於 OpenAI 的伺服器

使用 `hermes model` 或編輯 `~/.hermes/.env` 來設定您的提供商。請參閱 [環境變數](./environment-variables.md) 參考以查看所有提供商金鑰。

### 它可以在 Windows 上執行嗎？

**無法原生執行。** Hermes Agent 需要類 Unix 環境。在 Windows 上，請安裝 [WSL2](https://learn.microsoft.com/zh-tw/windows/wsl/install) 並在其中運行 Hermes。標準安裝指令在 WSL2 中運作良好：

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

### 它可以在 Android / Termux 上執行嗎？

可以 — Hermes 現在擁有針對 Android 手機且經過測試的 Termux 安裝路徑。

快速安裝：

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

有關詳盡的手動步驟、支援的擴展件和當前限制，請參閱 [Termux 指南](../getting-started/termux.md)。

重要提示：完整的 `.[all]` 擴展目前在 Android 上不可用，因為 `voice` 擴展依賴於 `faster-whisper` → `ctranslate2`，而 `ctranslate2` 未發佈 Android 版本的 wheel。請改用經過測試的 `.[termux]` 擴展。

### 我的數據會被送到哪裡嗎？

API 呼叫 **僅會發送到您配置的 LLM 提供商** (例如 OpenRouter, 您在地的 Ollama 實例)。Hermes Agent 不會收集遙測數據、使用數據或分析。您的對話、記憶和技能都儲存在在地的 `~/.hermes/` 中。

### 我可以離線使用 / 搭配在地模型嗎？

可以。執行 `hermes model`，選擇 **Custom endpoint**，並輸入您伺服器的網址：

```bash
hermes model
# 選擇：Custom endpoint (手動輸入網址)
# API 基本網址：http://localhost:11434/v1
# API 金鑰：ollama
# 模型名稱：qwen3.5:27b
# 上下文長度：32768   ← 設定為符合您伺服器實際的上下文視窗大小
```

或直接在 `config.yaml` 中配置：

```yaml
model:
  default: qwen3.5:27b
  provider: custom
  base_url: http://localhost:11434/v1
```

Hermes 會將端點、提供商和基本網址持久化在 `config.yaml` 中，因此在重啟後仍然有效。如果您的在地伺服器僅載入了一個模型，`/model custom` 會自動偵測。您也可以在 config.yaml 中設定 `provider: custom` — 它是一個一等公民提供商，而非任何其他服務的別名。

這適用於 Ollama, vLLM, llama.cpp 伺服器, SGLang, LocalAI 等。詳情請參閱 [配置指南](../user-guide/configuration.md)。

:::tip Ollama 使用者
如果您在 Ollama 中設定了自定義 `num_ctx` (例如 `ollama run --num_ctx 16384`)，請確保在 Hermes 中設定相符的上下文長度 — Ollama 的 `/api/show` 報告的是模型的 *最大* 上下文，而非您配置的有效 `num_ctx`。
:::

:::tip 在地模型超時問題
Hermes 會自動偵測在地端點並放寬串流超時 (讀取超時從 120s 提高到 1800s，停用失效串流偵測)。如果您在極大上下文下仍遇到超時，請在您的 `.env` 中設定 `HERMES_STREAM_READ_TIMEOUT=1800`。詳情請參閱 [在地 LLM 指南](../guides/local-llm-on-mac.md#timeouts)。
:::

### 費用是多少？

Hermes Agent 本身是 **免費且開源的** (MIT 授權)。您僅需支付所選提供商的 LLM API 使用費用。在地模型則完全可以免費執行。

### 多個人可以共用一個實例嗎？

可以。[即時通訊網關](../user-guide/messaging/index.md) 允許多個使用者透過 Telegram, Discord, Slack, WhatsApp 或 Home Assistant 與同一個 Hermes Agent 實例互動。存取權限透過白名單 (特定使用者 ID) 和私訊配對 (第一個發送訊息的使用者獲得存取權) 來控制。

### 記憶 (memory) 與技能 (skills) 有什麼區別？

- **記憶** 儲存 **事實** — 代理了解到的關於您、您的專案和偏好的事情。記憶會根據相關性自動被檢索。
- **技能** 儲存 **程序** — 關於如何執行任務的步驟說明。當代理遇到類似任務時會回想技能。

兩者都會跨工作階段持久存在。詳情請參閱 [記憶](/docs/user-guide/features/memory) 和 [技能](/docs/user-guide/features/skills)。

### 我可以在我自己的 Python 專案中使用它嗎？

可以。匯入 `AIAgent` 類別並以程式化方式使用 Hermes：

```python
from run_agent import AIAgent

agent = AIAgent(model="openrouter/nous/hermes-3-llama-3.1-70b")
response = agent.chat("簡短解釋量子運算")
```

請參閱 [Python 函式庫指南](../user-guide/features/code-execution.md) 以瞭解完整的 API 用法。

---

## 疑難排解

### 安裝問題

#### 安裝後顯示 `hermes: command not found`

**原因：** 您的 shell 尚未重新載入更新後的 PATH。

**解決方案：**
```bash
# 重新載入您的 shell 設定檔
source ~/.bashrc    # bash
source ~/.zshrc     # zsh

# 或者開啟一個新的終端機視窗
```

如果仍然無效，請驗證安裝位置：
```bash
which hermes
ls ~/.local/bin/hermes
```

:::tip
安裝程式會將 `~/.local/bin` 添加到您的 PATH。如果您使用非標準的 shell 配置，請手動添加 `export PATH="$HOME/.local/bin:$PATH"`。
:::

#### Python 版本過舊

**原因：** Hermes 需要 Python 3.11 或更高版本。

**解決方案：**
```bash
python3 --version   # 檢查當前版本

# 安裝較新版本的 Python
sudo apt install python3.12   # Ubuntu/Debian
brew install python@3.12      # macOS
```

安裝程式通常會自動處理此問題 — 如果您在手動安裝時看到此錯誤，請先升級 Python。

#### `uv: command not found`

**原因：** `uv` 套件管理器未安裝或不在 PATH 中。

**解決方案：**
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
```

#### 安裝期間發生權限遭拒 (Permission denied) 錯誤

**原因：** 權限不足，無法寫入安裝目錄。

**解決方案：**
```bash
# 不要對安裝程式使用 sudo — 它會安裝到 ~/.local/bin
# 如果您先前使用了 sudo 安裝，請清理：
sudo rm /usr/local/bin/hermes
# 然後重新執行標準安裝程式
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

---

### 提供商與模型問題

#### `/model` 僅顯示一個提供商 / 無法切換提供商

**原因：** `/model` (在聊天工作階段中) 只能在 **您已配置好的** 提供商之間切換。如果您僅設定了 OpenRouter，則 `/model` 僅會顯示 OpenRouter。

**解決方案：** 退出您的工作階段，並從終端機使用 `hermes model` 來新增提供商：

```bash
# 先退出 Hermes 聊天工作階段 (Ctrl+C 或 /quit)

# 執行完整的提供商設定精靈
hermes model

# 這可以讓您：新增提供商、執行 OAuth、輸入 API 金鑰、配置端點
```

透過 `hermes model` 新增提供商後，啟動新的聊天工作階段 — 此時 `/model` 將顯示您所有已配置的提供商。

:::tip 快速參考
| 想要... | 使用指令 |
|-----------|-----|
| 新增提供商 | `hermes model` (終端機) |
| 輸入/更改 API 金鑰 | `hermes model` (終端機) |
| 工作階段中切換模型 | `/model <名稱>` (聊天內) |
| 切換到其他已配置的提供商 | `/model provider:model` (聊天內) |
:::

#### API 金鑰無效

**原因：** 金鑰缺失、已過期、設定錯誤，或對應了錯誤的提供商。

**解決方案：**
```bash
# 檢查您的配置
hermes config show

# 重新配置您的提供商
hermes model

# 或直接設定
hermes config set OPENROUTER_API_KEY sk-or-v1-xxxxxxxxxxxx
```

:::warning
請確保金鑰與提供商匹配。OpenAI 金鑰無法用於 OpenRouter，反之亦然。請檢查 `~/.hermes/.env` 中是否有衝突的項目。
:::

#### 找不到模型 / 模型不可用

**原因：** 模型標識符不正確或在您的提供商上不可用。

**解決方案：**
```bash
# 列出您提供商的可用模型
hermes model

# 設定有效的模型
hermes config set HERMES_MODEL openrouter/nous/hermes-3-llama-3.1-70b

# 或在單一工作階段中指定
hermes chat --model openrouter/meta-llama/llama-3.1-70b-instruct
```

#### 速率限制 (429 錯誤)

**原因：** 您超過了提供商的速率限制。

**解決方案：** 稍等片刻後重試。對於持續使用，請考慮：
- 升級您的提供商方案
- 切換到不同的模型或提供商
- 使用 `hermes chat --provider <替代方案>` 路由到不同的後端

#### 超過上下文長度 (Context length exceeded)

**原因：** 對話長度已超過模型的上下文視窗大小，或者 Hermes 偵測到了錯誤的模型上下文長度。

**解決方案：**
```bash
# 壓縮當前工作階段
/compress

# 或者開啟一個全新的工作階段
hermes chat

# 使用具備更大上下文視窗的模型
hermes chat --model openrouter/google/gemini-3-flash-preview
```

如果這發生在第一次長對話中，可能是 Hermes 獲取了錯誤的模型上下文長度。請檢查偵測到的結果：

查看 CLI 啟動行 — 它會顯示偵測到的上下文長度 (例如 `📊 Context limit: 128000 tokens`)。您也可以在工作階段中使用 `/usage` 檢查。

若要修復上下文偵測，請明確設定：

```yaml
# 位於 ~/.hermes/config.yaml
model:
  default: your-model-name
  context_length: 131072  # 您模型的實際上下文視窗大小
```

或者對於自定義端點，按模型添加：

```yaml
custom_providers:
  - name: "My Server"
    base_url: "http://localhost:11434/v1"
    models:
      qwen3.5:27b:
        context_length: 32768
```

請參閱 [上下文長度偵測](../integrations/providers.md#context-length-detection) 以瞭解自動偵測的工作原理及所有覆蓋選項。

---

### 終端機問題

#### 指令因危險而被阻擋

**原因：** Hermes 偵測到具有潛在破壞性的指令 (例如 `rm -rf`, `DROP TABLE`)。這是一項安全功能。

**解決方案：** 看到提示時，請檢查指令並輸入 `y` 核准執行。您也可以：
- 要求代理使用更安全的替代方案
- 在 [安全文件](../user-guide/security.md) 中查看完整的危險模式列表

:::tip
這符合設計預期 — Hermes 絕不會默默執行破壞性指令。核准提示會向您展示即將執行的具體內容。
:::

#### 透過通訊網關使用 `sudo` 無效

**原因：** 通訊網關在沒有互動式終端機的情況下運行，因此 `sudo` 無法提示輸入密碼。

**解決方案：**
- 避免在通訊中使用 `sudo` — 要求代理尋找替代方案
- 如果必須使用 `sudo`，請在 `/etc/sudoers` 中為特定指令配置免密碼 sudo
- 或切換到終端機介面執行管理任務：`hermes chat`

#### Docker 後端無法連接

**原因：** Docker 守護程序未執行或使用者缺乏權限。

**解決方案：**
```bash
# 檢查 Docker 是否正在執行
docker info

# 將您的使用者添加到 docker 群組
sudo usermod -aG docker $USER
newgrp docker

# 驗證
docker run hello-world
```

---

### 即時通訊問題

#### 機器人不回應訊息

**原因：** 機器人未執行、未經授權，或者您的使用者不在白名單中。

**解決方案：**
```bash
# 檢查網關是否正在執行
hermes gateway status

# 啟動網關
hermes gateway start

# 檢查日誌中的錯誤
cat ~/.hermes/logs/gateway.log | tail -50
```

#### 訊息未送達

**原因：** 網路問題、機器人權杖過期，或平台 Webhook 配置錯誤。

**解決方案：**
- 使用 `hermes gateway setup` 驗證您的機器人權杖是否有效
- 檢查網關日誌：`cat ~/.hermes/logs/gateway.log | tail -50`
- 對於基於 Webhook 的平台 (Slack, WhatsApp)，確保您的伺服器可以從外部存取

#### 權限困惑 — 誰可以與機器人對話？

**原因：** 授權模式決定了誰能獲得存取權。

**解決方案：**

| 模式 | 工作方式 |
|------|-------------|
| **白名單 (Allowlist)** | 僅配置中列出的使用者 ID 可以互動 |
| **私訊配對 (DM pairing)** | 第一個在私訊中發送訊息的使用者獲得獨佔存取權 |
| **開放 (Open)** | 任何人都可以互動 (不建議用於正式環境) |

在 `~/.hermes/config.yaml` 的網關設定中進行配置。請參閱 [即時通訊文件](../user-guide/messaging/index.md)。

#### 網關無法啟動

**原因：** 缺少依賴項、埠號衝突或權杖配置錯誤。

**解決方案：**
```bash
# 安裝即時通訊依賴項
pip install "hermes-agent[telegram]"   # 或 [discord], [slack], [whatsapp]

# 檢查埠號衝突
lsof -i :8080

# 驗證配置
hermes config show
```

#### WSL：網關頻繁斷線或 `hermes gateway start` 失敗

**原因：** WSL 的 systemd 支援並不穩定。許多 WSL2 安裝未啟用 systemd，即使啟用了，服務也可能無法在 WSL 重啟或 Windows 閒置關閉後存活。

**解決方案：** 使用前景模式而非 systemd 服務：

```bash
# 選項 1：直接在前景執行 (最簡單)
hermes gateway run

# 選項 2：透過 tmux 實現持久化 (關閉終端機後仍會執行)
tmux new -s hermes 'hermes gateway run'
# 稍後重新連接：tmux attach -t hermes

# 選項 3：透過 nohup 在背景執行
nohup hermes gateway run > ~/.hermes/logs/gateway.log 2>&1 &
```

如果您仍想嘗試 systemd，請確保已將其啟用：

1. 開啟 `/etc/wsl.conf` (如果不存在則建立)
2. 添加：
   ```ini
   [boot]
   systemd=true
   ```
3. 在 PowerShell 執行：`wsl --shutdown`
4. 重新開啟 WSL 終端機
5. 驗證：`systemctl is-system-running` 應該顯示 "running" 或 "degraded"

:::tip Windows 開機自動啟動
為了獲得穩定的自動啟動，請使用 Windows 工作排程器在登入時啟動 WSL 和網關：
1. 建立一個執行 `wsl -d Ubuntu -- bash -lc 'hermes gateway run'` 的任務
2. 設定為使用者登入時觸發
:::

#### macOS：網關找不到 Node.js / ffmpeg / 其他工具

**原因：** launchd 服務繼承了極簡的 PATH (`/usr/bin:/bin:/usr/sbin:/sbin`)，其中不包含 Homebrew, nvm, cargo 或其他使用者安裝工具的目錄。這通常會導致 WhatsApp 橋接器 (`node not found`) 或語音轉錄 (`ffmpeg not found`) 損壞。

**解決方案：** 網關在您執行 `hermes gateway install` 時會捕捉您當前的 shell PATH。如果您在設定網關後安裝了工具，請重新執行安裝以捕捉更新後的 PATH：

```bash
hermes gateway install    # 重新捕捉當前 PATH 並建立快照
hermes gateway start      # 偵測更新後的 plist 並重新載入
```

您可以驗證 plist 是否具備正確的 PATH：
```bash
/usr/libexec/PlistBuddy -c "Print :EnvironmentVariables:PATH" \
  ~/Library/LaunchAgents/ai.hermes.gateway.plist
```

---

### 效能問題

#### 回應緩慢

**原因：** 模型太大、API 伺服器地理距離太遠，或帶有許多工具的沉重系統提示詞。

**解決方案：**
- 嘗試較快/較小的模型：`hermes chat --model openrouter/meta-llama/llama-3.1-8b-instruct`
- 減少啟動的工具集：`hermes chat -t "terminal"`
- 檢查您到提供商的網路延遲
- 對於在地模型，確保您擁有足夠的 GPU VRAM

#### Token 使用量過高

**原因：** 長對話、過於詳細的系統提示詞，或頻繁呼叫工具導致上下文累積。

**解決方案：**
```bash
# 壓縮對話以減少 Token
/compress

# 檢查工作階段的 Token 使用情況
/usage
```

:::tip
在長對話期間定期使用 `/compress`。它會摘要對話歷史，在保留上下文的同時顯著減少 Token 使用量。
:::

#### 工作階段變得過長

**原因：** 長時間的對話累積了大量訊息和工具輸出，接近上下文限制。

**解決方案：**
```bash
# 壓縮當前工作階段 (保留關鍵上下文)
/compress

# 開啟一個引用舊對話的新工作階段
hermes chat

# 如果需要，稍後恢復特定工作階段
hermes chat --continue
```

---

### MCP 問題

#### MCP 伺服器無法連接

**原因：** 找不到伺服器二進位檔案、指令路徑錯誤或缺少執行環境。

**解決方案：**
```bash
# 確保已安裝 MCP 依賴項 (標準安裝已包含)
cd ~/.hermes/hermes-agent && uv pip install -e ".[mcp]"

# 對於基於 npm 的伺服器，請確保 Node.js 可用
node --version
npx --version

# 手動測試伺服器
npx -y @modelcontextprotocol/server-filesystem /tmp
```

驗證您 `~/.hermes/config.yaml` 中的 MCP 配置：
```yaml
mcp_servers:
  filesystem:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-filesystem", "/home/user/docs"]
```

#### MCP 伺服器的工具未顯示

**原因：** 伺服器已啟動但工具偵測失敗、工具被配置過濾掉，或者伺服器不支援您預期的 MCP 功能。

**解決方案：**
- 檢查網關/代理日誌中的 MCP 連接錯誤
- 確保伺服器會回應 `tools/list` RPC 方法
- 檢查該伺服器下的任何 `tools.include`, `tools.exclude`, `tools.resources`, `tools.prompts` 或 `enabled` 設定
- 請記住，資源/提示詞公用工具僅在工作階段實際支援這些功能時才會註冊
- 更改配置後使用 `/reload-mcp`

```bash
# 驗證 MCP 伺服器已配置
hermes config show | grep -A 12 mcp_servers

# 配置更改後重啟 Hermes 或重新載入 MCP
hermes chat
```

另請參閱：
- [MCP (Model Context Protocol)](/docs/user-guide/features/mcp)
- [在 Hermes 中使用 MCP](/docs/guides/use-mcp-with-hermes)
- [MCP 配置參考](/docs/reference/mcp-config-reference)

#### MCP 超時錯誤

**原因：** MCP 伺服器回應時間過長，或者在執行期間崩潰。

**解決方案：**
- 如果支援，請在您的 MCP 伺服器配置中增加超時時間
- 檢查 MCP 伺服器進程是否仍在執行
- 對於遠端 HTTP MCP 伺服器，請檢查網路連線性

:::warning
如果 MCP 伺服器在請求中途崩潰，Hermes 將回報超時。請檢查伺服器自身的日誌 (而不僅僅是 Hermes 日誌) 來診斷根本原因。
:::

---

## 設定檔 (Profiles)

### 設定檔與僅設定 HERMES_HOME 有什麼區別？

設定檔是在 `HERMES_HOME` 之上的一層管理。您可以手動在每個指令前設定 `HERMES_HOME=/some/path`，但設定檔為您處理了所有繁瑣工作：建立目錄結構、產生 shell 別名 (`hermes-work`)、在 `~/.hermes/active_profile` 中追蹤活動設定檔，以及跨設定檔自動同步技能更新。它們還整合了 tab 補全功能，讓您無需記憶路徑。

### 兩個設定檔可以共用同一個機器人權杖嗎？

不行。每個通訊平台 (Telegram, Discord 等) 都需要對機器人權杖具備獨佔存取權。如果兩個設定檔同時嘗試使用同一個權杖，第二個網關將無法連接。請為每個設定檔建立獨立的機器人 — 對於 Telegram，請諮詢 [@BotFather](https://t.me/BotFather) 來建立更多機器人。

### 設定檔之間會共用記憶或工作階段嗎？

不會。每個設定檔都有自己的記憶儲存空間、工作階段資料庫和技能目錄。它們是完全隔離的。如果您想使用現有的記憶和工作階段啟動一個新設定檔，請使用 `hermes profile create newname --clone-all` 來複製當前設定檔的所有內容。

### 執行 `hermes update` 時會發生什麼？

`hermes update` 會獲取最新代碼並重新安裝依賴項 **一次** (而非按設定檔)。然後它會自動將更新後的技能同步到所有設定檔。您只需執行一次 `hermes update` — 它會涵蓋機器上的每個設定檔。

### 我可以將設定檔移動到另一台機器嗎？

可以。將設定檔匯出為可攜式存檔，然後在另一台機器上匯入：

```bash
# 在來源機器上
hermes profile export work ./work-backup.tar.gz

# 將檔案複製到目標機器，然後執行：
hermes profile import ./work-backup.tar.gz work
```

匯入的設定檔將擁有備份中的所有配置、記憶、工作階段和技能。如果新機器的環境不同，您可能需要更新路徑或重新驗證提供商。

### 我可以運行多少個設定檔？

沒有硬性限制。每個設定檔只是 `~/.hermes/profiles/` 下的一個目錄。實際限制取決於您的磁碟空間以及您的系統可以處理多少個併行的網關 (每個網關都是一個輕量級 Python 進程)。執行數十個設定檔也沒問題；每個閒置的設定檔都不會消耗資源。

---

## 工作流與模式

### 針對不同任務使用不同模型 (多模型工作流)

**場景：** 您將 GPT-5.4 作為主要工具，但 Gemini 或 Grok 編寫社交媒體內容的效果更好。每次手動切換模型非常繁瑣。

**解決方案：委派配置 (Delegation config)。** Hermes 可以自動將子代理路由到不同的模型。在 `~/.hermes/config.yaml` 中設定：

```yaml
delegation:
  model: "google/gemini-3-flash-preview"   # 子代理使用此模型
  provider: "openrouter"                    # 子代理的提供商
```

現在，當您告訴 Hermes「幫我寫一段關於 X 的 Twitter 推文串」且它啟動一個 `delegate_task` 子代理時，該子代理將在 Gemini 上運行，而非您的主模型。您的主對話仍保留在 GPT-5.4 上。

您也可以在提示詞中明確指定：*"委派一個編寫我們產品發布社交媒體貼文的任務。使用您的子代理進行實際編寫。"* 代理將使用 `delegate_task`，它會自動套用委派配置。

對於不涉及委派的一次性模型切換，請在 CLI 中使用 `/model`：

```bash
/model google/gemini-3-flash-preview    # 為此工作階段切換
# ... 編寫內容 ...
/model openai/gpt-5.4                   # 切換回來
```

請參閱 [子代理委派](../user-guide/features/delegation.md) 以瞭解更多委派工作原理。

### 在一個 WhatsApp 號碼上運行多個代理 (按聊天綁定)

**場景：** 在 OpenClaw 中，您可以將多個獨立代理綁定到特定的 WhatsApp 聊天 — 一個用於家庭購物清單群組，另一個用於您的私人聊天。Hermes 可以做到嗎？

**當前限制：** Hermes 的每個設定檔都需要自己的 WhatsApp 號碼/工作階段。您無法在同一個 WhatsApp 號碼上將多個設定檔綁定到不同的聊天 — WhatsApp 橋接器 (Baileys) 每個號碼使用一個經過驗證的工作階段。

**解決方案：**

1. **使用具備人格切換功能的單一設定檔。** 建立不同的 `AGENTS.md` 上下文檔案或使用 `/personality` 指令來按聊天更改行為。代理會偵測它所在的聊天並進行調整。

2. **針對特殊任務使用 cron 任務。** 對於購物清單追蹤，設定一個監視特定聊天並管理清單的 cron 任務 — 不需要單獨的代理。

3. **使用不同的號碼。** 如果您需要真正獨立的代理，請為每個設定檔配對各自的 WhatsApp 號碼。像 Google Voice 這樣的虛擬號碼服務可以用於此目的。

4. **改用 Telegram 或 Discord。** 這些平台更自然地支援按聊天綁定 — 每個 Telegram 群組或 Discord 頻道都有自己的工作階段內容，您可以在同一個帳戶上運行多個機器人權杖 (每個設定檔一個)。

請參閱 [設定檔 (Profiles)](../user-guide/profiles.md) 和 [WhatsApp 設定](../user-guide/messaging/whatsapp.md) 以瞭解更多詳情。

### 控制 Telegram 中顯示的內容 (隱藏日誌與推理內容)

**場景：** 您在 Telegram 中看到了網關執行日誌、Hermes 推理內容和工具呼叫詳情，而不是最終輸出。

**解決方案：** `config.yaml` 中的 `display.tool_progress` 設定控制顯示多少工具活動：

```yaml
display:
  tool_progress: "off"   # 選項：off, new, all, verbose
```

- **`off`** — 僅顯示最終回應。不顯示工具呼叫、不顯示推理內容、不顯示日誌。
- **`new`** — 隨進度顯示新的工具呼叫 (簡短的單行)。
- **`all`** — 顯示所有工具活動，包括結果。
- **`verbose`** — 完整細節，包括工具參數和輸出。

對於通訊平台，通常建議使用 `off` 或 `new`。編輯 `config.yaml` 後，重啟網關使更改生效。

您也可以在工作階段中透過 `/verbose` 指令 (如果已啟用) 來切換：

```yaml
display:
  tool_progress_command: true   # 在網關中啟用 /verbose
```

### 在 Telegram 上管理技能 (斜線指令限制)

**場景：** Telegram 具備 100 個斜線指令限制，而您的技能數量已超過此限制。您想在 Telegram 上停用不需要的技能，但 `hermes skills config` 的設定似乎沒生效。

**解決方案：** 使用 `hermes skills config` 按平台停用技能。這會寫入 `config.yaml`：

```yaml
skills:
  disabled: []                    # 全域停用的技能
  platform_disabled:
    telegram: [skill-a, skill-b]  # 僅在 telegram 停用
```

更改後，**重啟網關** (`hermes gateway restart` 或殺死進程並重新啟動)。Telegram 機器人指令選單會在啟動時重新建立。

:::tip
描述過長的技能在 Telegram 選單中會被截斷為 40 個字元，以符合酬載大小限制。如果技能未出現，可能是總酬載大小問題而非 100 個指令數量的限制 — 停用不使用的技能對這兩者都有幫助。
:::

### 共享討論串工作階段 (多個使用者，同一個對話)

**場景：** 您有一個 Telegram 或 Discord 討論串，多個人在其中提及 (mention) 機器人。您希望該討論串中的所有提及都屬於一個共享的對話，而非各個使用者的獨立工作階段。

**當前行為：** Hermes 在大多數平台上會根據使用者 ID 來鍵入 (key) 工作階段，因此每個人都有自己的對話上下文。這是為了隱私和內容隔離而設計的。

**解決方案：**

1. **使用 Slack。** Slack 的工作階段是按討論串 (thread) 而非按使用者鍵入的。同一個討論串中的多個使用者會共享一個對話 — 這正是您所描述的行為。這是最自然的解決方案。

2. **在群組聊天中使用單一使用者。** 如果由一位特定的人員擔任「操作員」來轉述問題，對話上下文將保持統一。其他人可以旁觀。

3. **使用 Discord 頻道。** Discord 工作階段按頻道鍵入，因此同一頻道中的所有使用者都會共享上下文。請為共享對話使用專用的頻道。

### 將 Hermes 匯出到另一台機器

**場景：** 您已在某台機器上建立了技能、cron 任務和記憶，並想將所有內容搬移到新的專用 Linux 機器上。

**解決方案：**

1. 在新機器上安裝 Hermes Agent：
   ```bash
   curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
   ```

2. 複製您的整個 `~/.hermes/` 目錄，**但排除** `hermes-agent` 子目錄 (那是代碼儲存庫 — 新安裝會有自己的代碼)：
   ```bash
   # 在來源機器上
   rsync -av --exclude='hermes-agent' ~/.hermes/ newmachine:~/.hermes/
   ```

   或者使用設定檔匯出/匯入：
   ```bash
   # 在來源機器上
   hermes profile export default ./hermes-backup.tar.gz

   # 在目標機器上
   hermes profile import ./hermes-backup.tar.gz default
   ```

3. 在新機器上執行 `hermes setup` 驗證 API 金鑰和提供商配置是否正常。重新驗證任何即時通訊平台 (特別是使用 QR 配對的 WhatsApp)。

`~/.hermes/` 目錄包含所有內容：`config.yaml`, `.env`, `SOUL.md`, `memories/`, `skills/`, `state.db` (工作階段), `cron/` 以及任何自定義外掛程式。代碼本身位於 `~/.hermes/hermes-agent/` 並會重新安裝。

### 安裝後重新載入 shell 時權限遭拒

**場景：** 執行 Hermes 安裝程式後，`source ~/.zshrc` 顯示權限遭拒 (permission denied) 錯誤。

**原因：** 這通常是因為 `~/.zshrc` (或 `~/.bashrc`) 的檔案權限不正確，或者安裝程式無法乾淨地寫入其中。這不是 Hermes 特有的問題 — 它是 shell 配置檔案的權限問題。

**解決方案：**
```bash
# 檢查權限
ls -la ~/.zshrc

# 如有需要請修復 (應該是 -rw-r--r-- 或 644)
chmod 644 ~/.zshrc

# 然後重新載入
source ~/.zshrc

# 或者直接開啟一個新的終端機視窗 — 它會自動載入 PATH 更改
```

如果安裝程式添加了 PATH 行但權限錯誤，您可以手動添加：
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

### 第一次執行代理時出現 Error 400

**場景：** 設定過程順利完成，但第一次聊天嘗試失敗並顯示 HTTP 400。

**原因：** 通常是模型名稱不匹配 — 配置的模型在您的提供商中不存在，或者 API 金鑰不具備存取該模型的權限。

**解決方案：**
```bash
# 檢查配置的模型與提供商
hermes config show | head -20

# 重新執行模型選擇
hermes model

# 或者使用已知良好的模型進行測試
hermes chat -q "hello" --model anthropic/claude-sonnet-4.6
```

如果使用 OpenRouter，請確保您的 API 金鑰中有額度。OpenRouter 傳回的 400 通常意味著該模型需要付費方案或模型 ID 拼寫錯誤。

---

## 仍有疑問？

如果您的問題未涵蓋在此：

1. **搜尋現有的 issue：** [GitHub Issues](https://github.com/NousResearch/hermes-agent/issues)
2. **詢問社群：** [Nous Research Discord](https://discord.gg/nousresearch)
3. **提交錯誤回報：** 請包含您的作業系統、Python 版本 (`python3 --version`)、Hermes 版本 (`hermes --version`) 和完整的錯誤訊息。
