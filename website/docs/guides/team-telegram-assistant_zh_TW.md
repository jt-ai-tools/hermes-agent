---
sidebar_position: 4
title: "教學：團隊 Telegram 助手"
description: "逐步指南：設定一個可供整個團隊使用的 Telegram 機器人，用於程式碼協助、研究、系統管理等功能"
---

# 設定團隊 Telegram 助手

本教學將引導您設定一個由 Hermes Agent 驅動、可供多個團隊成員使用的 Telegram 機器人。完成後，您的團隊將擁有一個共享的 AI 助手，他們可以透過訊息請求程式碼協助、研究、系統管理以及任何其他事務，並具備每位使用者的授權安全性。

## 我們要建立什麼

一個具備以下功能的 Telegram 機器人：

- **任何獲得授權的團隊成員**都可以傳送私訊尋求協助 —— 程式碼審查、研究、Shell 指令、除錯。
- **運行在您的伺服器上**並擁有完整的工具存取權限 —— 終端機、檔案編輯、網路搜尋、程式碼執行。
- **每位使用者獨立的工作階段** —— 每個人都有自己的對話上下文。
- **預設安全** —— 只有核准的使用者可以互動，具備兩種授權方法。
- **排程任務** —— 每日站立會議、健康檢查和提醒事項，並傳送到團隊頻道。

---

## 先決條件

在開始之前，請確保您擁有：

- **已安裝 Hermes Agent** 的伺服器或 VPS（不是您的筆記型電腦 —— 機器人需要保持運行）。如果您尚未安裝，請參考[安裝指南](/docs/getting-started/installation)。
- 您自己的 **Telegram 帳號**（機器人擁有者）。
- **已設定 LLM 提供者** —— 至少在 `~/.hermes/.env` 中設定了 OpenAI、Anthropic 或其他支援提供者的 API 金鑰。

:::tip 提示
每月 5 美元的 VPS 足以運行閘道器（Gateway）。Hermes 本身非常輕量 —— 昂貴的是 LLM API 呼叫，而這些是在遠端發生的。
:::

---

## 第 1 步：建立 Telegram 機器人

每個 Telegram 機器人都從 **@BotFather** 開始 —— 這是 Telegram 官方用於建立機器人的機器人。

1. **開啟 Telegram** 並搜尋 `@BotFather`，或前往 [t.me/BotFather](https://t.me/BotFather)。

2. **傳送 `/newbot`** —— BotFather 會詢問您兩件事：
   - **顯示名稱 (Display name)** —— 使用者看到的名稱（例如：`Team Hermes Assistant`）。
   - **使用者名稱 (Username)** —— 必須以 `bot` 結尾（例如：`myteam_hermes_bot`）。

3. **複製機器人權杖 (Bot Token)** —— BotFather 會回覆如下內容：
   ```
   Use this token to access the HTTP API:
   7123456789:AAH1bGciOiJSUzI1NiIsInR5cCI6Ikp...
   ```
   儲存此權杖 —— 您在下一步中會用到它。

4. **設定描述**（選填但建議執行）：
   ```
   /setdescription
   ```
   選擇您的機器人，然後輸入類似以下的內容：
   ```
   由 Hermes Agent 驅動的團隊 AI 助手。傳送私訊給我，以獲取程式碼、研究、除錯等方面的協助。
   ```

5. **設定機器人指令**（選填 —— 為使用者提供指令選單）：
   ```
   /setcommands
   ```
   選擇您的機器人，然後貼上：
   ```
   new - 開始新的對話
   model - 顯示或更改 AI 模型
   status - 顯示工作階段資訊
   help - 顯示可用指令
   stop - 停止當前任務
   ```

:::warning 警告
請務必保密您的機器人權杖。任何擁有權杖的人都可以控制該機器人。如果外洩，請在 BotFather 中使用 `/revoke` 生成新的權杖。
:::

---

## 第 2 步：設定閘道器 (Gateway)

您有兩個選擇：互動式設定精靈（推薦）或手動設定。

### 選項 A：互動式設定（推薦）

```bash
hermes gateway setup
```

這將引導您完成所有步驟（使用方向鍵選擇）。選擇 **Telegram**，貼上您的機器人權杖，並在提示時輸入您的使用者 ID。

### 選項 B：手動設定

將以下幾行添加到 `~/.hermes/.env`：

```bash
# 來自 BotFather 的 Telegram 機器人權杖
TELEGRAM_BOT_TOKEN=7123456789:AAH1bGciOiJSUzI1NiIsInR5cCI6Ikp...

# 您的 Telegram 使用者 ID (數字)
TELEGRAM_ALLOWED_USERS=123456789
```

### 尋找您的使用者 ID

您的 Telegram 使用者 ID 是一個數字（不是您的使用者名稱）。要找到它：

1. 在 Telegram 上傳送訊息給 [@userinfobot](https://t.me/userinfobot)。
2. 它會立即回覆您的數字使用者 ID。
3. 將該數字複製到 `TELEGRAM_ALLOWED_USERS` 中。

:::info 資訊
Telegram 使用者 ID 是永久的數字，例如 `123456789`。這與您的 `@username` 不同，後者是可以更改的。請務必使用數字 ID 進行允許列表設定。
:::

---

## 第 3 步：啟動閘道器 (Gateway)

### 快速測試

先在前台運行閘道器以確保一切正常：

```bash
hermes gateway
```

您應該會看到類似以下的輸出：

```
[Gateway] Starting Hermes Gateway...
[Gateway] Telegram adapter connected
[Gateway] Cron scheduler started (tick every 60s)
```

開啟 Telegram，找到您的機器人，並傳送一條訊息。如果它有回覆，就代表成功了。按下 `Ctrl+C` 停止運行。

### 生產環境：安裝為服務

為了讓程式在重啟後自動運行：

```bash
hermes gateway install
sudo hermes gateway install --system   # 僅限 Linux：開機啟動的系統服務
```

這會建立一個背景服務：在 Linux 上預設為使用者級別的 **systemd** 服務，在 macOS 上為 **launchd** 服務，或者如果您傳遞了 `--system` 參數，則為開機啟動的 Linux 系統服務。

```bash
# Linux —— 管理預設的使用者服務
hermes gateway start
hermes gateway stop
hermes gateway status

# 查看即時日誌
journalctl --user -u hermes-gateway -f

# SSH 登出後保持運行
sudo loginctl enable-linger $USER

# Linux 伺服器 —— 明確的系統服務指令
sudo hermes gateway start --system
sudo hermes gateway status --system
journalctl -u hermes-gateway -f
```

```bash
# macOS —— 管理服務
hermes gateway start
hermes gateway stop
tail -f ~/.hermes/logs/gateway.log
```

:::tip macOS PATH 提示
launchd plist 會在安裝時捕捉您的 Shell PATH，以便閘道器子程序可以找到 Node.js 和 ffmpeg 等工具。如果您稍後安裝了新工具，請重新執行 `hermes gateway install` 來更新 plist。
:::

### 驗證是否正在運行

```bash
hermes gateway status
```

然後在 Telegram 上向您的機器人傳送測試訊息。您應該在幾秒鐘內收到回覆。

---

## 第 4 步：設定團隊存取權限

現在讓我們給您的團隊成員存取權限。有兩種方法。

### 方法 A：靜態允許列表 (Allowlist)

收集每位團隊成員的 Telegram 使用者 ID（讓他們傳送訊息給 [@userinfobot](https://t.me/userinfobot)），並將其添加為以逗號分隔的列表：

```bash
# 在 ~/.hermes/.env 中
TELEGRAM_ALLOWED_USERS=123456789,987654321,555555555
```

更改後重啟閘道器：

```bash
hermes gateway stop && hermes gateway start
```

### 方法 B：私訊配對（推薦用於團隊）

私訊配對更靈活 —— 您不需要預先收集使用者 ID。其運作方式如下：

1. **團隊成員私訊機器人** —— 由於他們不在允許列表中，機器人會回覆一個一次性配對碼：
   ```
   🔐 配對碼：XKGH5N7P
   請將此代碼傳送給機器人擁有者進行核准。
   ```

2. **團隊成員將代碼傳送給您**（透過任何管道 —— Slack、電子郵件、面對面）。

3. **您在伺服器上核准它**：
   ```bash
   hermes pairing approve telegram XKGH5N7P
   ```

4. **他們加入成功** —— 機器人會立即開始回覆他們的訊息。

**管理配對的使用者：**

```bash
# 查看所有待處理和已核准的使用者
hermes pairing list

# 撤銷某人的存取權限
hermes pairing revoke telegram 987654321

# 清除過期的待處理代碼
hermes pairing clear-pending
```

:::tip 提示
私訊配對（DM Pairing）非常適合團隊，因為在添加新使用者時不需要重啟閘道器。核准會立即生效。
:::

### 安全考量

- **永遠不要在具有終端機存取權限的機器人上設定 `GATEWAY_ALLOW_ALL_USERS=true`** —— 任何發現您機器人的人都可以在您的伺服器上執行指令。
- 配對碼在 **1 小時**後過期，並使用加密隨機性。
- 速率限制可防止暴力破解攻擊：每位使用者每 10 分鐘 1 次請求，每個平台最多 3 個待處理代碼。
- 5 次核准嘗試失敗後，該平台將進入 1 小時的鎖定狀態。
- 所有配對數據均以 `chmod 0600` 權限儲存。

---

## 第 5 步：設定機器人

### 設定主頻道 (Home Channel)

**主頻道**是機器人傳送 Cron 任務結果和主動訊息的地方。如果沒有設定，排程任務將無處傳送輸出。

**選項 1：** 在機器人加入的任何 Telegram 群組或聊天中使用 `/sethome` 指令。

**選項 2：** 在 `~/.hermes/.env` 中手動設定：

```bash
TELEGRAM_HOME_CHANNEL=-1001234567890
TELEGRAM_HOME_CHANNEL_NAME="Team Updates"
```

要尋找群組 ID，請將 [@userinfobot](https://t.me/userinfobot) 加入群組 —— 它會報告該群組的聊天 ID。

### 設定工具進度顯示

控制機器人在使用工具時顯示多少細節。在 `~/.hermes/config.yaml` 中：

```yaml
display:
  tool_progress: new    # off | new | all | verbose
```

| 模式 | 您會看到什麼 |
|------|-------------|
| `off` | 僅顯示乾淨的回覆 —— 沒有工具活動 |
| `new` | 每個新工具呼叫的簡短狀態（推薦用於即時通訊軟體） |
| `all` | 每個工具呼叫的詳細資訊 |
| `verbose` | 完整的工具輸出，包含指令結果 |

使用者也可以在對話中使用 `/verbose` 指令更改個別工作階段的設定。

### 使用 SOUL.md 設定人格

透過編輯 `~/.hermes/SOUL.md` 來自訂機器人的溝通方式：

完整指南請參閱[在 Hermes 中使用 SOUL.md](/docs/guides/use-soul-with-hermes)。

```markdown
# Soul
你是一個得力的團隊助手。說話簡明扼要，且具備技術專業。
對任何程式碼都要使用程式碼區塊。跳過社交客套話 —— 團隊
看重直接。在除錯時，在猜測解決方案之前，請務必先詢問錯誤日誌。
```

### 添加專案上下文

如果您的團隊致力於特定專案，請建立上下文檔案，以便機器人了解您的技術棧：

```markdown
<!-- ~/.hermes/AGENTS.md -->
# 團隊上下文
- 我們使用 Python 3.12 搭配 FastAPI 和 SQLAlchemy
- 前端是 React 搭配 TypeScript
- CI/CD 運行在 GitHub Actions
- 生產環境部署到 AWS ECS
- 始終建議為新程式碼撰寫測試
```

:::info 資訊
上下文檔案會被注入到每個工作階段的系統提示語（System Prompt）中。請保持簡短 —— 每個字元都會消耗您的 Token 額度。
:::

---

## 第 6 步：設定排程任務

閘道器運行後，您可以安排循環任務，將結果傳送到您的團隊頻道。

### 每日站立會議摘要

在 Telegram 上向機器人發送訊息：

```
每個工作日早上 9 點，檢查 github.com/myorg/myproject 的 GitHub 儲存庫，查看：
1. 過去 24 小時內開啟或合併的 Pull Request
2. 建立或關閉的 Issue
3. 主分支上的任何 CI/CD 失敗
格式化為簡短的站立會議風格摘要。
```

Agent 會自動建立一個 Cron 任務，並將結果傳送到您提出要求的聊天視窗（或主頻道）。

### 伺服器健康檢查

```
每 6 小時，使用 'df -h' 檢查磁碟使用情況，使用 'free -h' 檢查記憶體，
並使用 'docker ps' 檢查 Docker 容器狀態。報告任何異常情況 ——
分區超過 80%、已重啟的容器或高記憶體使用率。
```

### 管理排程任務

```bash
# 從 CLI 執行
hermes cron list          # 查看所有排程任務
hermes cron status        # 檢查排程器是否正在運行

# 從 Telegram 聊天視窗執行
/cron list                # 查看任務
/cron remove <job_id>     # 移除任務
```

:::warning 警告
Cron 任務提示語在完全乾淨的工作階段中運行，沒有先前對話的記憶。請確保每個提示語都包含 Agent 所需的**所有**上下文 —— 檔案路徑、URL、伺服器位址和明確的指令。
:::

---

## 生產環境提示

### 為了安全使用 Docker

在團隊共用的機器人上，使用 Docker 作為終端機後端，以便 Agent 指令在容器中運行，而不是在您的宿主機上：

```bash
# 在 ~/.hermes/.env 中
TERMINAL_BACKEND=docker
TERMINAL_DOCKER_IMAGE=nikolaik/python-nodejs:python3.11-nodejs20
```

或者在 `~/.hermes/config.yaml` 中：

```yaml
terminal:
  backend: docker
  container_cpu: 1
  container_memory: 5120
  container_persistent: true
```

這樣，即使有人要求機器人執行破壞性操作，您的宿主機系統也會受到保護。

### 監控閘道器

```bash
# 檢查閘道器是否正在運行
hermes gateway status

# 查看即時日誌 (Linux)
journalctl --user -u hermes-gateway -f

# 查看即時日誌 (macOS)
tail -f ~/.hermes/logs/gateway.log
```

### 保持 Hermes 更新

從 Telegram 向機器人傳送 `/update` —— 它會抓取最新版本並重啟。或者從伺服器執行：

```bash
hermes update
hermes gateway stop && hermes gateway start
```

### 日誌位置

| 項目 | 位置 |
|------|----------|
| 閘道器日誌 | `journalctl --user -u hermes-gateway` (Linux) 或 `~/.hermes/logs/gateway.log` (macOS) |
| Cron 任務輸出 | `~/.hermes/cron/output/{job_id}/{timestamp}.md` |
| Cron 任務定義 | `~/.hermes/cron/jobs.json` |
| 配對數據 | `~/.hermes/pairing/` |
| 工作階段歷史 | `~/.hermes/sessions/` |

---

## 深入探索

您已經擁有一個可以運行的團隊 Telegram 助手。以下是一些後續步驟：

- **[安全指南](/docs/user-guide/security)** —— 深入了解授權、容器隔離和指令核准。
- **[訊息閘道器](/docs/user-guide/messaging)** —— 閘道器架構、工作階段管理和聊天指令的完整參考。
- **[Telegram 設定](/docs/user-guide/messaging/telegram)** —— 平台特定的細節，包含語音訊息和 TTS。
- **[排程任務](/docs/user-guide/features/cron)** —— 進階的 Cron 排程，包含交付選項和 Cron 表達式。
- **[上下文檔案](/docs/user-guide/features/context-files)** —— 用於專案知識的 AGENTS.md、SOUL.md 和 .cursorrules。
- **[個性設定](/docs/user-guide/features/personality)** —— 內建的人格預設和自定義人格定義。
- **添加更多平台** —— 同一個閘道器可以同時運行 [Discord](/docs/user-guide/messaging/discord)、[Slack](/docs/user-guide/messaging/slack) 和 [WhatsApp](/docs/user-guide/messaging/whatsapp)。

---

*有任何疑問或問題？請在 GitHub 上提出 Issue —— 歡迎貢獻。*
