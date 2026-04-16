---
sidebar_position: 1
title: "快速入門"
description: "你的第一次 Hermes Agent 對話——從安裝到對談只需 2 分鐘"
---

# 快速入門

本指南將引導你安裝 Hermes Agent、設定提供商並進行第一次對話。完成後，你將了解關鍵功能以及如何進一步探索。

## 1. 安裝 Hermes Agent

執行單行安裝指令：

```bash
# Linux / macOS / WSL2 / Android (Termux)
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

:::tip Android / Termux
如果你是在手機上安裝，請參閱專屬的 [Termux 指南](./termux_zh_TW.md) 以了解經過測試的手動路徑、支援的額外組件以及目前 Android 特有的限制。
:::

:::tip Windows 使用者
請先安裝 [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install)，然後在 WSL2 終端機中執行上述指令。
:::

安裝完成後，重新載入你的 shell：

```bash
source ~/.bashrc   # 或 source ~/.zshrc
```

## 2. 設定提供商 (Provider)

安裝程式會自動設定你的 LLM 提供商。若日後需要更改，請使用以下其中一個指令：

```bash
hermes model       # 選擇你的 LLM 提供商與模型
hermes tools       # 設定啟用的工具
hermes setup       # 或一次設定所有選項
```

`hermes model` 會引導你選擇推論提供商：

| 提供商 | 說明 | 如何設定 |
|----------|-----------|---------------|
| **Nous Portal** | 訂閱制，零設定 | 透過 `hermes model` 進行 OAuth 登入 |
| **OpenAI Codex** | ChatGPT OAuth，使用 Codex 模型 | 透過 `hermes model` 進行裝置代碼認證 |
| **Anthropic** | 直接使用 Claude 模型 (Pro/Max 或 API 金鑰) | 使用 Claude Code 認證的 `hermes model`，或 Anthropic API 金鑰 |
| **OpenRouter** | 跨多種模型的提供商路由 | 輸入你的 API 金鑰 |
| **Z.AI** | GLM / 智譜 (Zhipu) 託管模型 | 設定 `GLM_API_KEY` / `ZAI_API_KEY` |
| **Kimi / Moonshot** | Moonshot 託管的編碼與對話模型 | 設定 `KIMI_API_KEY` |
| **Kimi / Moonshot China** | 中國地區 Moonshot 端點 | 設定 `KIMI_CN_API_KEY` |
| **Arcee AI** | Trinity 模型 | 設定 `ARCEEAI_API_KEY` |
| **MiniMax** | 國際版 MiniMax 端點 | 設定 `MINIMAX_API_KEY` |
| **MiniMax China** | 中國地區 MiniMax 端點 | 設定 `MINIMAX_CN_API_KEY` |
| **Alibaba Cloud** | 透過 DashScope 使用通義千問 (Qwen) 模型 | 設定 `DASHSCOPE_API_KEY` |
| **Hugging Face** | 透過統一路由使用 20+ 開放模型 (Qwen, DeepSeek, Kimi 等) | 設定 `HF_TOKEN` |
| **Kilo Code** | KiloCode 託管模型 | 設定 `KILOCODE_API_KEY` |
| **OpenCode Zen** | 隨收隨付存取精選模型 | 設定 `OPENCODE_ZEN_API_KEY` |
| **OpenCode Go** | 每月 10 美元訂閱開放模型 | 設定 `OPENCODE_GO_API_KEY` |
| **DeepSeek** | 直接存取 DeepSeek API | 設定 `DEEPSEEK_API_KEY` |
| **GitHub Copilot** | GitHub Copilot 訂閱 (GPT-5.x, Claude, Gemini 等) | 透過 `hermes model` 進行 OAuth，或 `COPILOT_GITHUB_TOKEN` / `GH_TOKEN` |
| **GitHub Copilot ACP** | Copilot ACP 代理後端 (產生本地 `copilot` CLI) | `hermes model` (需要 `copilot` CLI + `copilot login`) |
| **Vercel AI Gateway** | Vercel AI Gateway 路由 | 設定 `AI_GATEWAY_API_KEY` |
| **Custom Endpoint** | VLLM, SGLang, Ollama 或任何 OpenAI 相容 API | 設定基礎 URL + API 金鑰 |

:::caution 最低上下文要求：64K 權杖 (tokens)
Hermes Agent 需要具備至少 **64,000 權杖** 上下文的模型。視窗較小的模型無法為多步驟工具調用工作流維持足夠的工作記憶，啟動時會被拒絕。大多數託管模型 (Claude, GPT, Gemini, Qwen, DeepSeek) 都能輕鬆滿足此要求。如果你運行本地模型，請將其上下文大小設定為至少 64K (例如 llama.cpp 的 `--ctx-size 65536` 或 Ollama 的 `-c 65536`)。
:::

:::tip
你可以隨時使用 `hermes model` 切換提供商——無需更改程式碼，無平台鎖定。配置自訂端點時，Hermes 會詢問上下文視窗大小，並在可能的情況下自動偵測。詳情請參閱 [上下文長度偵測](../integrations/providers_zh_TW.md#context-length-detection)。
:::

## 3. 開始對話

```bash
hermes
```

就這樣！你將看到歡迎橫幅，其中包含你的模型、可用工具與技能。輸入訊息並按 Enter。

```
❯ 你能幫我做什麼？
```

代理開箱即用，可存取網路搜尋、檔案操作、終端指令等工具。

## 4. 嘗試關鍵功能

### 請求它使用終端機

```
❯ 我的磁碟使用量是多少？顯示前 5 個最大的目錄。
```

代理將代表你執行終端指令並向你展示結果。

### 使用斜線指令 (Slash Commands)

輸入 `/` 即可看到所有指令的自動完成下拉選單：

| 指令 | 作用 |
|---------|-------------|
| `/help` | 顯示所有可用指令 |
| `/tools` | 列出可用工具 |
| `/model` | 互動式切換模型 |
| `/personality pirate` | 嘗試有趣的個性 (例如海盜) |
| `/save` | 儲存對話 |

### 多行輸入

按下 `Alt+Enter` 或 `Ctrl+J` 即可換行。非常適合貼上程式碼或撰寫詳細的提示詞。

### 中斷代理

如果代理執行時間太長，只需輸入新訊息並按 Enter——它會中斷目前任務並切換到你的新指令。`Ctrl+C` 同樣有效。

### 恢復會話

退出時，hermes 會列印恢復指令：

```bash
hermes --continue    # 恢復最近一次會話
hermes -c            # 簡短形式
```

## 5. 進一步探索

以下是一些可以嘗試的內容：

### 設定沙盒終端機

為了安全起見，可以在 Docker 容器或遠端伺服器上執行代理：

```bash
hermes config set terminal.backend docker    # Docker 隔離
hermes config set terminal.backend ssh       # 遠端伺服器
```

### 連接訊息平台

透過 Telegram, Discord, Slack, WhatsApp, Signal, Email 或 Home Assistant 從手機或其他介面與 Hermes 對談：

```bash
hermes gateway setup    # 互動式平台配置
```

### 新增語音模式

想要在 CLI 中使用麥克風輸入，或在訊息平台中獲取語音回覆？

```bash
pip install "hermes-agent[voice]"
# 包含用於免費本地語音轉文字的 faster-whisper
```

接著啟動 Hermes 並在 CLI 中啟用它：

```text
/voice on
```

按下 `Ctrl+B` 進行錄音，或使用 `/voice tts` 讓 Hermes 讀出回覆。參閱 [語音模式](../user-guide/features/voice-mode_zh_TW.md) 以了解 CLI, Telegram, Discord 及 Discord 語音頻道的完整設定。

### 排定自動化任務

```
❯ 每天早上 9 點檢查 Hacker News 的 AI 新聞，並在 Telegram 上發送摘要給我。
```

代理將設定一個 cron 任務，透過 gateway 自動執行。

### 瀏覽並安裝技能

```bash
hermes skills search kubernetes
hermes skills search react --source skills-sh
hermes skills search https://mintlify.com/docs --source well-known
hermes skills install openai/skills/k8s
hermes skills install official/security/1password
hermes skills install skills-sh/vercel-labs/json-render/json-render-react --force
```

技巧：
- 使用 `--source skills-sh` 搜尋公開的 `skills.sh` 目錄。
- 使用 `--source well-known` 搭配文件/網站 URL 來發現來自 `/.well-known/skills/index.json` 的技能。
- 僅在審閱過第三方技能後才使用 `--force`。它可以繞過非危險性的政策阻擋，但無法繞過 `dangerous` (危險) 的掃描判定。

或在對話中使用 `/skills` 斜線指令。

### 透過 ACP 在編輯器中使用 Hermes

Hermes 也可以作為 ACP 伺服器，用於 VS Code, Zed 和 JetBrains 等相容於 ACP 的編輯器：

```bash
pip install -e '.[acp]'
hermes acp
```

設定詳情請參閱 [ACP 編輯器整合](../user-guide/features/acp_zh_TW.md)。

### 嘗試 MCP 伺服器

透過模型上下文協議 (Model Context Protocol) 連接外部工具：

```yaml
# 新增到 ~/.hermes/config.yaml
mcp_servers:
  github:
    command: npx
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: "ghp_xxx"
```

---

## 快速參考

| 指令 | 描述 |
|---------|-------------|
| `hermes` | 開始對話 |
| `hermes model` | 選擇你的 LLM 提供商與模型 |
| `hermes tools` | 設定每個平台啟用的工具 |
| `hermes setup` | 完整設定精靈 (一次配置所有選項) |
| `hermes doctor` | 診斷問題 |
| `hermes update` | 更新至最新版本 |
| `hermes gateway` | 啟動訊息閘道器 |
| `hermes --continue` | 恢復上一次會話 |

## 下一步

- **[CLI 指南](../user-guide/cli_zh_TW.md)** — 精通終端機介面
- **[配置設定](../user-guide/configuration_zh_TW.md)** — 自訂你的設定
- **[訊息閘道器](../user-guide/messaging/index_zh_TW.md)** — 連接 Telegram, Discord, Slack, WhatsApp, Signal, Email 或 Home Assistant
- **[工具與工具集](../user-guide/features/tools_zh_TW.md)** — 探索可用功能
