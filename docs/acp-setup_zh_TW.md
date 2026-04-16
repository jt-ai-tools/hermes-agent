# Hermes Agent — ACP (代理用戶端協定) 安裝指南

Hermes Agent 支援 **代理用戶端協定 (Agent Client Protocol, ACP)**，使其能夠在您的編輯器中作為
程式設計代理執行。ACP 讓您的 IDE 可以將任務發送給 Hermes，而
Hermes 則會以檔案編輯、終端機指令和解釋作為回應 —— 這些都會
原生顯示在編輯器 UI 中。

---

## 前提條件

- 已安裝並配置 Hermes Agent (已完成 `hermes setup`)
- 已在 `~/.hermes/.env` 中或透過 `hermes login` 設定 API 金鑰 / 供應商
- Python 3.11+

安裝 ACP 額外組件：

```bash
pip install -e ".[acp]"
```

---

## VS Code 設定

### 1. 安裝 ACP Client 擴充功能

開啟 VS Code 並從市集安裝 **ACP Client**：

- 按下 `Ctrl+Shift+X` (在 macOS 上為 `Cmd+Shift+X`)
- 搜尋 **"ACP Client"**
- 點擊 **安裝 (Install)**

或從命令列安裝：

```bash
code --install-extension anysphere.acp-client
```

### 2. 配置 settings.json

開啟您的 VS Code 設定 (`Ctrl+,` → 點擊 JSON 的 `{}` 圖示) 並新增：

```json
{
  "acpClient.agents": [
    {
      "name": "hermes-agent",
      "registryDir": "/path/to/hermes-agent/acp_registry"
    }
  ]
}
```

將 `/path/to/hermes-agent` 替換為您 Hermes Agent 安裝的
實際路徑 (例如 `~/.hermes/hermes-agent`)。

或者，如果 `hermes` 已在您的 PATH 中，ACP Client 可以透過註冊表目錄
自動發現它。

### 3. 重啟 VS Code

配置完成後，重啟 VS Code。您應該會看到 **Hermes Agent** 出現在
聊天/代理面板的 ACP 代理選取器中。

---

## Zed 設定

Zed 具備內建的 ACP 支援。

### 1. 配置 Zed 設定

開啟 Zed 設定 (macOS 上為 `Cmd+,`，Linux 上為 `Ctrl+,`) 並在您的
`settings.json` 中新增：

```json
{
  "agent_servers": {
    "hermes-agent": {
      "type": "custom",
      "command": "hermes",
      "args": ["acp"],
    },
  },
}
```

### 2. 重啟 Zed

Hermes Agent 將出現在代理面板中。選擇它並開始對話。

---

## JetBrains 設定 (IntelliJ, PyCharm, WebStorm 等)

### 1. 安裝 ACP 外掛程式

- 開啟 **Settings** → **Plugins** → **Marketplace**
- 搜尋 **"ACP"** 或 **"Agent Client Protocol"**
- 安裝並重啟 IDE

### 2. 配置代理程式

- 開啟 **Settings** → **Tools** → **ACP Agents**
- 點擊 **+** 新增代理程式
- 將註冊表目錄設定為您的 `acp_registry/` 資料夾：
  `/path/to/hermes-agent/acp_registry`
- 點擊 **OK**

### 3. 使用代理程式

開啟 ACP 面板 (通常在右側欄) 並選擇 **Hermes Agent**。

---

## 您將看到的內容

連線後，您的編輯器會提供一個原生的 Hermes Agent 介面：

### 聊天面板 (Chat Panel)
一個對話介面，您可以在其中描述任務、提出問題並給予指令。
Hermes 會以解釋和行動做出回應。

### 檔案差異 (File Diffs)
當 Hermes 編輯檔案時，您會在編輯器中看到標準的差異 (diff)；您可以：
- **接受 (Accept)** 個別變更
- **拒絕 (Reject)** 您不想要的變更
- 在套用前 **檢閱 (Review)** 完整差異

### 終端機指令 (Terminal Commands)
當 Hermes 需要執行 shell 指令 (建置、測試、安裝) 時，編輯器
會在整合終端機中顯示它們。根據您的設定：
- 指令可能會自動執行
- 或者可能會提示您 **核准 (approve)** 每個指令

### 核准流程 (Approval Flow)
對於潛在的具破壞性操作，編輯器會在 Hermes 繼續之前提示您
進行核准。這包括：
- 檔案刪除
- Shell 指令
- Git 操作

---

## 配置 (Configuration)

ACP 模式下的 Hermes Agent 使用與 CLI **相同的配置**：

- **API 金鑰 / 供應商**：`~/.hermes/.env`
- **代理配置**：`~/.hermes/config.yaml`
- **技能 (Skills)**：`~/.hermes/skills/`
- **會話 (Sessions)**：`~/.hermes/state.db`

您可以執行 `hermes setup` 來配置供應商，或直接編輯 `~/.hermes/.env`。

### 更改模型

編輯 `~/.hermes/config.yaml`：

```yaml
model: openrouter/nous/hermes-3-llama-3.1-70b
```

或者設定 `HERMES_MODEL` 環境變數。

### 工具集 (Toolsets)

ACP 會話預設使用精選的 `hermes-acp` 工具集。它是專為編輯器工作流程設計的，
並刻意排除了訊息傳遞、排程任務管理和音訊優先的 UX 功能等項目。

---

## 疑難排解 (Troubleshooting)

### 代理程式未出現在編輯器中

1. **檢查註冊表路徑** —— 確保編輯器設定中的 `acp_registry/` 目錄路徑
   正確且包含 `agent.json`。
2. **檢查 `hermes` 是否在 PATH 中** —— 在終端機執行 `which hermes`。
   如果找不到，您可能需要啟動虛擬環境或將其加入 PATH。
3. 更改設定後 **重啟編輯器**。

### 代理程式已啟動但立即報錯

1. 執行 `hermes doctor` 檢查您的配置。
2. 檢查您是否擁有有效的 API 金鑰：`hermes status`
3. 嘗試直接在終端機執行 `hermes acp` 以查看錯誤輸出。

### "Module not found" 錯誤

請確保您安裝了 ACP 額外組件：

```bash
pip install -e ".[acp]"
```

### 回應緩慢

- ACP 會串流輸出回應，因此您應該會看到漸進式的輸出。如果代理程式
  似乎卡住了，請檢查您的網路連線和 API 供應商狀態。
- 某些供應商有速率限制 (rate limits)。嘗試切換到不同的模型/供應商。

### 終端機指令權限被拒絕

如果編輯器封鎖了終端機指令，請檢查您的 ACP Client 擴充功能
設定中關於自動核准或手動核准的偏好設定。

### 日誌 (Logs)

在 ACP 模式下執行時，Hermes 日誌會寫入 stderr。請檢查：
- VS Code：**輸出 (Output)** 面板 → 選擇 **ACP Client** 或 **Hermes Agent**
- Zed：**檢視 (View)** → **切換終端機 (Toggle Terminal)** 並檢查程序輸出
- JetBrains：**Event Log** 或 ACP 工具視窗

您也可以啟用詳細記錄 (verbose logging)：

```bash
HERMES_LOG_LEVEL=DEBUG hermes acp
```

---

## 延伸閱讀

- [ACP 規格](https://github.com/anysphere/acp)
- [Hermes Agent 文件](https://github.com/NousResearch/hermes-agent)
- 執行 `hermes --help` 查看所有 CLI 選項
