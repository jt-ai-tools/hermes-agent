<p align="center">
  <img src="assets/banner.png" alt="Hermes Agent" width="100%">
</p>

# Hermes Agent ☤ (中文版)

<p align="center">
  <a href="https://hermes-agent.nousresearch.com/docs/"><img src="https://img.shields.io/badge/文檔-hermes--agent.nousresearch.com-FFD700?style=for-the-badge" alt="Documentation"></a>
  <a href="https://discord.gg/NousResearch"><img src="https://img.shields.io/badge/Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"></a>
  <a href="https://github.com/NousResearch/hermes-agent/blob/main/LICENSE"><img src="https://img.shields.io/badge/授權-MIT-green?style=for-the-badge" alt="License: MIT"></a>
  <a href="https://nousresearch.com"><img src="https://img.shields.io/badge/由-Nous%20Research%20開發-blueviolet?style=for-the-badge" alt="Built by Nous Research"></a>
</p>

**由 [Nous Research](https://nousresearch.com) 開發的自我進步 AI 代理。** 這是唯一內建學習迴圈的代理程式 —— 它能從經驗中創造技能、在使用過程中改進技能、提醒自己持久化知識、搜尋過去的對話記錄，並在不同對話間建立關於你的深層模型。它可以運行在 5 美元的 VPS、GPU 集群，或是閒置時幾乎不產生費用的無伺服器基礎架構上。它不侷限於你的筆記型電腦 —— 當它在雲端虛擬機運行時，你可以透過 Telegram 與它對話。

使用任何你想要的模型 —— [Nous Portal](https://portal.nousresearch.com)、[OpenRouter](https://openrouter.ai)（支援 200 多個模型）、[Xiaomi MiMo](https://platform.xiaomimimo.com)、[z.ai/GLM](https://z.ai)、[Kimi/Moonshot](https://platform.moonshot.ai)、[MiniMax](https://www.minimax.io)、[Hugging Face](https://huggingface.co)、OpenAI，或是你自己的端點。使用 `hermes model` 即可切換 —— 無需更改程式碼，不受供應商綁定。

<table>
<tr><td><b>真實的終端介面</b></td><td>完整的 TUI，支援多行編輯、斜線指令自動補全、對話歷史紀錄、中斷與重新導向，以及串流化的工具輸出。</td></tr>
<tr><td><b>與你隨時同在</b></td><td>Telegram、Discord、Slack、WhatsApp、Signal 與 CLI —— 全部由單一網關進程驅動。語音訊息轉錄、跨平台的對話連貫性。</td></tr>
<tr><td><b>閉環學習系統</b></td><td>由代理程式策劃的記憶，並帶有週期性提醒。在完成複雜任務後自主創建技能。技能在使用中會自我改進。支援 FTS5 會話搜尋與 LLM 摘要，實現跨對話的回憶。採用 <a href="https://github.com/plastic-labs/honcho">Honcho</a> 辯證使用者建模。兼容 <a href="https://agentskills.io">agentskills.io</a> 開放標準。</td></tr>
<tr><td><b>排程自動化</b></td><td>內建 cron 排程器，可傳送至任何平台。每日報告、每晚備份、每週審核 —— 全部使用自然語言描述，無人值守運行。</td></tr>
<tr><td><b>委派與並行處理</b></td><td>為並行工作流生成隔離的子代理。編寫 Python 腳本透過 RPC 調用工具，將多步流程縮減為零上下文成本的對話回合。</td></tr>
<tr><td><b>隨處運行，不只是筆記型電腦</b></td><td>六種終端後端 —— 本地、Docker、SSH、Daytona、Singularity 與 Modal。Daytona 與 Modal 提供無伺服器持久化 —— 你的代理環境在閒置時休眠，隨需求喚醒，對話間幾乎不產生費用。可運行在 5 美元的 VPS 或 GPU 集群上。</td></tr>
<tr><td><b>研究導向</b></td><td>批次軌跡生成、Atropos RL 環境、軌跡壓縮，用於訓練下一代工具調用模型。</td></tr>
</table>

---

## 快速安裝

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

支援 Linux、macOS、WSL2 以及透過 Termux 運行的 Android。安裝程式會自動處理平台相關的設定。

> **Android / Termux:** 經過測試的手動安裝路徑記錄在 [Termux 指南](https://hermes-agent.nousresearch.com/docs/getting-started/termux)中。在 Termux 上，Hermes 會安裝精選的 `.[termux]` 額外組件，因為完整的 `.[all]` 目前會引入與 Android 不相容的語音依賴。
>
> **Windows:** 不支援原生 Windows。請安裝 [WSL2](https://learn.microsoft.com/zh-tw/windows/wsl/install) 並執行上述指令。

安裝完成後：

```bash
source ~/.bashrc    # 重新載入 shell (或: source ~/.zshrc)
hermes              # 開始聊天！
```

---

## 入門指南

```bash
hermes              # 互動式 CLI —— 開始對話
hermes model        # 選擇你的 LLM 供應商與模型
hermes tools        # 設定啟用的工具
hermes config set   # 設定個別配置值
hermes gateway      # 啟動通訊網關 (Telegram, Discord 等)
hermes setup        # 執行完整安裝精靈 (一次設定所有內容)
hermes claw migrate # 從 OpenClaw 遷移 (如果你是 OpenClaw 用戶)
hermes update       # 更新至最新版本
hermes doctor       # 診斷任何問題
```

📖 **[完整文件 (英文) →](https://hermes-agent.nousresearch.com/docs/)**

## CLI 與通訊平台快速對照

Hermes 有兩個入口：使用 `hermes` 啟動終端 UI，或執行網關並透過 Telegram、Discord、Slack、WhatsApp、Signal 或電子郵件與它交談。一旦進入對話，許多斜線指令在兩個介面中都是通用的。

| 行動 | CLI | 通訊平台 |
|---------|-----|---------------------|
| 開始聊天 | `hermes` | 執行 `hermes gateway setup` + `hermes gateway start`，然後向機器人發送訊息 |
| 開啟新對話 | `/new` 或 `/reset` | `/new` 或 `/reset` |
| 更換模型 | `/model [供應商:模型]` | `/model [供應商:模型]` |
| 設定人格 | `/personality [名稱]` | `/personality [名稱]` |
| 重試或撤銷上一步 | `/retry`, `/undo` | `/retry`, `/undo` |
| 壓縮上下文 / 檢查用量 | `/compress`, `/usage`, `/insights [--days N]` | `/compress`, `/usage`, `/insights [天數]` |
| 瀏覽技能 | `/skills` 或 `/<技能名稱>` | `/skills` 或 `/<技能名稱>` |
| 中斷目前工作 | `Ctrl+C` 或發送新訊息 | `/stop` 或發送新訊息 |
| 平台特定狀態 | `/platforms` | `/status`, `/sethome` |

如需完整指令列表，請參閱 [CLI 指南](https://hermes-agent.nousresearch.com/docs/user-guide/cli) 與 [通訊網關指南](https://hermes-agent.nousresearch.com/docs/user-guide/messaging)。

---

## 文件

所有文件皆位於 **[hermes-agent.nousresearch.com/docs](https://hermes-agent.nousresearch.com/docs/)** (英文版)：

| 章節 | 涵蓋內容 |
|---------|---------------|
| [快速入門](https://hermes-agent.nousresearch.com/docs/getting-started/quickstart) | 安裝 → 設定 → 2 分鐘內開始第一次對話 |
| [CLI 使用指南](https://hermes-agent.nousresearch.com/docs/user-guide/cli) | 指令、按鍵綁定、人格、會話 |
| [配置設定](https://hermes-agent.nousresearch.com/docs/user-guide/configuration) | 配置檔案、供應商、模型、所有選項 |
| [通訊網關](https://hermes-agent.nousresearch.com/docs/user-guide/messaging) | Telegram, Discord, Slack, WhatsApp, Signal, Home Assistant |
| [安全性](https://hermes-agent.nousresearch.com/docs/user-guide/security) | 指令核准、DM 配對、容器隔離 |
| [工具與工具集](https://hermes-agent.nousresearch.com/docs/user-guide/features/tools) | 40+ 工具、工具集系統、終端後端 |
| [技能系統](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills) | 程序性記憶、技能中心 (Skills Hub)、建立技能 |
| [記憶](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory) | 持久記憶、使用者個人檔案、最佳實踐 |
| [MCP 整合](https://hermes-agent.nousresearch.com/docs/user-guide/features/mcp) | 連接任何 MCP 伺服器以擴展能力 |
| [Cron 排程](https://hermes-agent.nousresearch.com/docs/user-guide/features/cron) | 排程任務與平台遞送 |
| [上下文檔案](https://hermes-agent.nousresearch.com/docs/user-guide/features/context-files) | 形塑每次對話的專案背景資訊 |
| [架構](https://hermes-agent.nousresearch.com/docs/developer-guide/architecture) | 專案結構、代理迴圈、關鍵類別 |
| [貢獻指南](https://hermes-agent.nousresearch.com/docs/developer-guide/contributing) | 開發環境設定、PR 流程、程式碼風格 |
| [CLI 參考](https://hermes-agent.nousresearch.com/docs/reference/cli-commands) | 所有指令與旗標 |
| [環境變數](https://hermes-agent.nousresearch.com/docs/reference/environment-variables) | 完整的環境變數參考 |

---

## 從 OpenClaw 遷移

如果你來自 OpenClaw，Hermes 可以自動匯入你的設定、記憶、技能與 API 金鑰。

**在首次設定期間：** 安裝精靈 (`hermes setup`) 會自動偵測 `~/.openclaw` 並在配置開始前提供遷移選項。

**安裝後的任何時間：**

```bash
hermes claw migrate              # 互動式遷移 (完整預設)
hermes claw migrate --dry-run    # 預覽將遷移的內容
hermes claw migrate --preset user-data   # 遷移不含機密資訊
hermes claw migrate --overwrite  # 覆蓋現有衝突
```

匯入內容包括：
- **SOUL.md** —— 人格檔案
- **記憶** —— MEMORY.md 與 USER.md 條目
- **技能** —— 使用者建立的技能 → `~/.hermes/skills/openclaw-imports/`
- **指令允許清單** —— 核准模式
- **通訊設定** —— 平台配置、允許的使用者、工作目錄
- **API 金鑰** —— 允許清單中的機密 (Telegram, OpenRouter, OpenAI, Anthropic, ElevenLabs)
- **TTS 素材** —— 工作區音訊檔案
- **工作區指令** —— AGENTS.md (配合 `--workspace-target`)

參閱 `hermes claw migrate --help` 以了解所有選項，或使用 `openclaw-migration` 技能進行互動式代理引導遷移與預覽。

---

## 貢獻

我們歡迎貢獻！請參閱 [貢獻指南](https://hermes-agent.nousresearch.com/docs/developer-guide/contributing) 了解開發設定、程式碼風格與 PR 流程。

貢獻者快速入門：

```bash
git clone https://github.com/NousResearch/hermes-agent.git
cd hermes-agent
curl -LsSf https://astral.sh/uv/install.sh | sh
uv venv venv --python 3.11
source venv/bin/activate
uv pip install -e ".[all,dev]"
python -m pytest tests/ -q
```

> **RL 訓練 (選用):** 若要參與 RL/Tinker-Atropos 整合開發：
> ```bash
> git submodule update --init tinker-atropos
> uv pip install -e "./tinker-atropos"
> ```

---

## 社群

- 💬 [Discord](https://discord.gg/NousResearch)
- 📚 [技能中心 (Skills Hub)](https://agentskills.io)
- 🐛 [問題回報 (Issues)](https://github.com/NousResearch/hermes-agent/issues)
- 💡 [討論 (Discussions)](https://github.com/NousResearch/hermes-agent/discussions)
- 🔌 [HermesClaw](https://github.com/AaronWong1999/hermesclaw) —— 社群微信橋接器：在同一個微信帳號上運行 Hermes Agent 與 OpenClaw。

---

## 授權

MIT —— 參閱 [LICENSE](LICENSE)。

由 [Nous Research](https://nousresearch.com) 開發。
