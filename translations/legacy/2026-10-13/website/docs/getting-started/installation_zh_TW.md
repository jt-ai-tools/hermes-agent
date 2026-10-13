---
sidebar_position: 2
title: "安裝"
description: "在 Linux, macOS, WSL2 或 Android (透過 Termux) 上安裝 Hermes Agent"
---

# 安裝

使用單行安裝程式在兩分鐘內啟動並執行 Hermes Agent，或按照手動步驟進行全面控制。

## 快速安裝

### Linux / macOS / WSL2

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

### Android / Termux

Hermes 現在也提供支援 Termux 的安裝路徑：

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

安裝程式會自動偵測 Termux 並切換到經過測試的 Android 流程：
- 使用 Termux `pkg` 處理系統依賴項 (`git`, `python`, `nodejs`, `ripgrep`, `ffmpeg`, 編譯工具)
- 使用 `python -m venv` 建立虛擬環境 (virtualenv)
- 自動為 Android wheel 建置匯出 `ANDROID_API_LEVEL`
- 使用 `pip` 安裝精選的 `.[termux]` 額外組件
- 預設跳過未經測試的瀏覽器 / WhatsApp 引導程式 (bootstrap)

如果你想要完全明確的路徑，請參閱專屬的 [Termux 指南](./termux_zh_TW.md)。

:::warning Windows
**不支援**原生 Windows。請安裝 [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) 並在其中運行 Hermes Agent。上述安裝指令可在 WSL2 內部運行。
:::

### 安裝程式的作用

安裝程式會自動處理一切——所有依賴項 (Python, Node.js, ripgrep, ffmpeg)、儲存庫複製 (repo clone)、虛擬環境、全域 `hermes` 指令設定以及 LLM 提供商配置。完成後，你就可以開始對談了。

### 安裝後

重新載入你的 shell 並開始對話：

```bash
source ~/.bashrc   # 或：source ~/.zshrc
hermes             # 開始對話！
```

稍後要重新設定個別選項，請使用專屬指令：

```bash
hermes model          # 選擇你的 LLM 提供商與模型
hermes tools          # 設定啟用的工具
hermes gateway setup  # 設定訊息平台
hermes config set     # 設定個別配置值
hermes setup          # 或執行完整設定精靈來一次配置所有選項
```

---

## 前置條件

唯一的前置條件是 **Git**。安裝程式會自動處理其他所有事項：

- **uv** (快速的 Python 套件管理器)
- **Python 3.11** (透過 uv，不需要 sudo)
- **Node.js v22** (用於瀏覽器自動化與 WhatsApp 橋接)
- **ripgrep** (快速檔案搜尋)
- **ffmpeg** (用於 TTS 的音訊格式轉換)

:::info
你**不需要**手動安裝 Python, Node.js, ripgrep 或 ffmpeg。安裝程式會偵測缺少的部分並為你安裝。只需確保 `git` 可用即可 (`git --version`)。
:::

:::tip Nix 使用者
如果你使用 Nix (在 NixOS, macOS 或 Linux 上)，有一個具備 Nix flake、宣告式 NixOS 模組以及選用容器模式的專屬設定路徑。請參閱 **[Nix & NixOS 設定](./nix-setup_zh_TW.md)** 指南。
:::

---

## 手動安裝

如果你希望完全控制安裝過程，請按照以下步驟操作。

### 步驟 1：複製儲存庫 (Clone Repository)

使用 `--recurse-submodules` 參數進行 clone，以獲取必要的子模組：

```bash
git clone --recurse-submodules https://github.com/NousResearch/hermes-agent.git
cd hermes-agent
```

如果你已經在沒有使用 `--recurse-submodules` 的情況下完成 clone：
```bash
git submodule update --init --recursive
```

### 步驟 2：安裝 uv 並建立虛擬環境

```bash
# 安裝 uv (如果尚未安裝)
curl -LsSf https://astral.sh/uv/install.sh | sh

# 使用 Python 3.11 建立虛擬環境 (如果不存在，uv 會自動下載——不需要 sudo)
uv venv venv --python 3.11
```

:::tip
你**不需要**啟用 (activate) 虛擬環境就能使用 `hermes`。進入點 (entry point) 有一個指向虛擬環境 Python 的硬編碼 shebang，因此一旦建立符號連結 (symlink) 即可全域運作。
:::

### 步驟 3：安裝 Python 依賴項

```bash
# 告訴 uv 安裝到哪個虛擬環境
export VIRTUAL_ENV="$(pwd)/venv"

# 安裝所有額外組件
uv pip install -e ".[all]"
```

如果你只需要核心代理 (不需要 Telegram/Discord/cron 支援)：
```bash
uv pip install -e "."
```

<details>
<summary><strong>選用額外組件 (extras) 細項</strong></summary>

| 額外組件 | 新增功能 | 安裝指令 |
|-------|-------------|-----------------|
| `all` | 包含下方所有內容 | `uv pip install -e ".[all]"` |
| `messaging` | Telegram, Discord & Slack 閘道器 | `uv pip install -e ".[messaging]"` |
| `cron` | 用於排程任務的 Cron 表達式解析 | `uv pip install -e ".[cron]"` |
| `cli` | 設定精靈使用的終端選單 UI | `uv pip install -e ".[cli]"` |
| `modal` | Modal 雲端執行後端 | `uv pip install -e ".[modal]"` |
| `tts-premium` | ElevenLabs 高級語音 | `uv pip install -e ".[tts-premium]"` |
| `voice` | CLI 麥克風輸入 + 音訊播放 | `uv pip install -e ".[voice]"` |
| `pty` | PTY 終端支援 | `uv pip install -e ".[pty]"` |
| `termux` | 經過測試的 Android / Termux 組合 (`cron`, `cli`, `pty`, `mcp`, `honcho`, `acp`) | `python -m pip install -e ".[termux]" -c constraints-termux.txt` |
| `honcho` | AI 原生記憶 (Honcho 整合) | `uv pip install -e ".[honcho]"` |
| `mcp` | 模型上下文協議 (Model Context Protocol) 支援 | `uv pip install -e ".[mcp]"` |
| `homeassistant` | Home Assistant 整合 | `uv pip install -e ".[homeassistant]"` |
| `acp` | ACP 編輯器整合支援 | `uv pip install -e ".[acp]"` |
| `slack` | Slack 訊息功能 | `uv pip install -e ".[slack]"` |
| `dev` | pytest & 測試公用程式 | `uv pip install -e ".[dev]"` |

你可以組合額外組件：`uv pip install -e ".[messaging,cron]"`

:::tip Termux 使用者
目前 Android 上不支援 `.[all]`，因為 `voice` 額外組件會引入 `faster-whisper`，而它依賴的 `ctranslate2` wheel 尚未針對 Android 發布。請使用 `.[termux]` 作為經過測試的行動裝置安裝路徑，然後僅根據需要新增個別額外組件。
:::

</details>

### 步驟 4：安裝選用的子模組 (如有需要)

```bash
# RL 訓練後端 (選用)
uv pip install -e "./tinker-atropos"
```

這兩者都是選用的——如果你跳過它們，對應的工具集將無法使用。

### 步驟 5：安裝 Node.js 依賴項 (選用)

僅在需要 **瀏覽器自動化** (由 Browserbase 驅動) 和 **WhatsApp 橋接** 時才需要：

```bash
npm install
```

### 步驟 6：建立設定目錄

```bash
# 建立目錄結構
mkdir -p ~/.hermes/{cron,sessions,logs,memories,skills,pairing,hooks,image_cache,audio_cache,whatsapp/session}

# 複製範例設定檔
cp cli-config.yaml.example ~/.hermes/config.yaml

# 為 API 金鑰建立一個空的 .env 檔案
touch ~/.hermes/.env
```

### 步驟 7：新增你的 API 金鑰

開啟 `~/.hermes/.env` 並至少新增一個 LLM 提供商金鑰：

```bash
# 必要——至少一個 LLM 提供商：
OPENROUTER_API_KEY=sk-or-v1-your-key-here

# 選用——啟用額外工具：
FIRECRAWL_API_KEY=fc-your-key          # 網路搜尋與擷取 (或自行架設，請參閱文件)
FAL_KEY=your-fal-key                   # 影像生成 (FLUX)
```

或透過 CLI 設定：
```bash
hermes config set OPENROUTER_API_KEY sk-or-v1-your-key-here
```

### 步驟 8：將 `hermes` 新增到你的 PATH

```bash
mkdir -p ~/.local/bin
ln -sf "$(pwd)/venv/bin/hermes" ~/.local/bin/hermes
```

如果 `~/.local/bin` 不在你的 PATH 中，請將其新增到你的 shell 設定中：

```bash
# Bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc

# Zsh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc

# Fish
fish_add_path $HOME/.local/bin
```

### 步驟 9：設定你的提供商

```bash
hermes model       # 選擇你的 LLM 提供商與模型
```

### 步驟 10：驗證安裝

```bash
hermes version    # 檢查指令是否可用
hermes doctor     # 執行診斷以驗證一切運作正常
hermes status     # 檢查你的設定
hermes chat -q "Hello! What tools do you have available?"
```

---

## 快速參考：手動安裝 (簡略版)

給那些只需要指令的使用者：

```bash
# 安裝 uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Clone 並進入目錄
git clone --recurse-submodules https://github.com/NousResearch/hermes-agent.git
cd hermes-agent

# 使用 Python 3.11 建立虛擬環境
uv venv venv --python 3.11
export VIRTUAL_ENV="$(pwd)/venv"

# 安裝所有內容
uv pip install -e ".[all]"
uv pip install -e "./tinker-atropos"
npm install  # 選用，用於瀏覽器工具與 WhatsApp

# 配置設定
mkdir -p ~/.hermes/{cron,sessions,logs,memories,skills,pairing,hooks,image_cache,audio_cache,whatsapp/session}
cp cli-config.yaml.example ~/.hermes/config.yaml
touch ~/.hermes/.env
echo 'OPENROUTER_API_KEY=sk-or-v1-your-key' >> ~/.hermes/.env

# 使 hermes 全域可用
mkdir -p ~/.local/bin
ln -sf "$(pwd)/venv/bin/hermes" ~/.local/bin/hermes

# 驗證
hermes doctor
hermes
```

---

## 疑難排解

| 問題 | 解決方案 |
|---------|----------|
| `hermes: command not found` | 重新載入 shell (`source ~/.bashrc`) 或檢查 PATH |
| `API key not set` | 執行 `hermes model` 設定你的提供商，或 `hermes config set OPENROUTER_API_KEY your_key` |
| 更新後缺少設定 | 執行 `hermes config check` 然後執行 `hermes config migrate` |

欲了解更多診斷資訊，請執行 `hermes doctor`——它會告訴你缺少什麼以及如何修復。
