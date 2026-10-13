# 從 OpenClaw 遷移至 Hermes Agent

本指南涵蓋如何將您的 OpenClaw 設定、記憶、技能和 API 金鑰匯入 Hermes Agent。

## 三種遷移方式

### 1. 自動遷移 (初次設定期間)

當您第一次執行 `hermes setup` 且 Hermes 偵測到 `~/.openclaw` 時，它會自動提議在開始配置前匯入您的 OpenClaw 資料。只需接受提示，一切都會為您處理妥當。

### 2. CLI 指令 (快速、可腳本化)

```bash
hermes claw migrate                      # 預覽後遷移 (一律先顯示預覽)
hermes claw migrate --dry-run            # 僅預覽，不進行變更
hermes claw migrate --preset user-data   # 遷移但不包含 API 金鑰/機密
hermes claw migrate --yes                # 跳過確認提示
```

遷移過程中一律會在進行任何變更前顯示完整預覽，說明將匯入哪些內容。您檢閱預覽並確認後才會寫入。

**所有選項：**

| 旗標 | 描述 |
|------|-------------|
| `--source PATH` | OpenClaw 目錄路徑 (預設值：`~/.openclaw`) |
| `--dry-run` | 僅預覽 —— 不修改任何檔案 |
| `--preset {user-data,full}` | 遷移預設集 (預設值：`full`)。`user-data` 排除機密 |
| `--overwrite` | 覆寫現有檔案 (預設值：跳過衝突) |
| `--migrate-secrets` | 包含加入白名單的機密 (在使用 `full` 預設集時自動啟用) |
| `--workspace-target PATH` | 將工作區指令 (AGENTS.md) 複製到此絕對路徑 |
| `--skill-conflict {skip,overwrite,rename}` | 如何處理技能名稱衝突 (預設值：`skip`) |
| `--yes`, `-y` | 跳過確認提示 |

### 3. 代理引導 (互動式，具備預覽)

要求代理程式為您執行遷移：

```
> 將我的 OpenClaw 設定遷移到 Hermes
```

代理程式將使用 `openclaw-migration` 技能來：
1. 先執行預覽以顯示將更改的內容
2. 詢問關於衝突解決的問題 (SOUL.md, 技能等)
3. 讓您在 `user-data` 和 `full` 預設集之間進行選擇
4. 根據您的選擇執行遷移
5. 列印已遷移內容的詳細摘要

## 哪些內容會被遷移

### `user-data` 預設集
| 項目 | 來源 | 目的地 |
|------|--------|-------------|
| SOUL.md | `~/.openclaw/workspace/SOUL.md` | `~/.hermes/SOUL.md` |
| 記憶條目 | `~/.openclaw/workspace/MEMORY.md` | `~/.hermes/memories/MEMORY.md` |
| 使用者個人檔案 | `~/.openclaw/workspace/USER.md` | `~/.hermes/memories/USER.md` |
| 技能 (Skills) | `~/.openclaw/workspace/skills/` | `~/.hermes/skills/openclaw-imports/` |
| 指令白名單 | `~/.openclaw/workspace/exec_approval_patterns.yaml` | 合併至 `~/.hermes/config.yaml` |
| 訊息傳遞設定 | `~/.openclaw/config.yaml` (TELEGRAM_ALLOWED_USERS, MESSAGING_CWD) | `~/.hermes/.env` |
| TTS 資產 | `~/.openclaw/workspace/tts/` | `~/.hermes/tts/` |

工作區檔案也會在 `workspace.default/` 和 `workspace-main/` 檢查作為備用路徑 (OpenClaw 在最近版本中將 `workspace/` 改名為 `workspace-main/`)。

### `full` 預設集 (在 `user-data` 基礎上增加)
| 項目 | 來源 | 目的地 |
|------|--------|-------------|
| Telegram 機器人 Token | `openclaw.json` 頻道配置 | `~/.hermes/.env` |
| OpenRouter API 金鑰 | `.env`, `openclaw.json`, 或 `openclaw.json["env"]` | `~/.hermes/.env` |
| OpenAI API 金鑰 | `.env`, `openclaw.json`, 或 `openclaw.json["env"]` | `~/.hermes/.env` |
| Anthropic API 金鑰 | `.env`, `openclaw.json`, 或 `openclaw.json["env"]` | `~/.hermes/.env` |
| ElevenLabs API 金鑰 | `.env`, `openclaw.json`, 或 `openclaw.json["env"]` | `~/.hermes/.env` |

API 金鑰會從四個來源搜尋：內嵌配置值、`~/.openclaw/.env`、`openclaw.json` 的 `"env"` 子物件，以及每個代理程式的驗證設定檔。

只有加入白名單的機密會被匯入。其他憑證會被跳過並記錄。

## OpenClaw Schema 相容性

遷移程式可處理舊版和目前的 OpenClaw 配置佈局：

- **頻道 Token**：從扁平路徑 (`channels.telegram.botToken`) 和較新的 `accounts.default` 佈局 (`channels.telegram.accounts.default.botToken`) 讀取
- **TTS 供應商**：OpenClaw 將 "edge" 改名為 "microsoft" —— 兩者都會被辨識並對應到 Hermes 的 "edge"
- **供應商 API 類型**：簡短值 (`openai`, `anthropic`) 和帶連字號的值 (`openai-completions`, `anthropic-messages`, `google-generative-ai`) 都會被正確對應
- **thinkingDefault**：處理所有列舉值，包括較新的值 (`minimal`, `xhigh`, `adaptive`)
- **Matrix**：使用 `accessToken` 欄位 (而非 `botToken`)
- **SecretRef 格式**：解析純字串、環境變數範本 (`${VAR}`) 和 `source: "env"` 的 SecretRefs。`source: "file"` 和 `source: "exec"` 的 SecretRefs 會產生警告 —— 遷移後請手動新增這些金鑰。

## 衝突處理

預設情況下，遷移 **不會覆寫** 現有的 Hermes 資料：

- **SOUL.md** —— 如果 `~/.hermes/` 中已存在，則跳過
- **記憶條目** —— 如果記憶已存在，則跳過 (以避免重複)
- **技能** —— 如果已存在同名技能，則跳過
- **API 金鑰** —— 如果金鑰已在 `~/.hermes/.env` 中設定，則跳過

若要覆寫衝突，請使用 `--overwrite`。遷移程式會在覆寫前建立備份。

對於技能，您也可以使用 `--skill-conflict rename` 來以新名稱匯入衝突的技能 (例如 `skill-name-imported`)。

## 遷移報告

每次遷移都會產生一份報告，顯示：
- **已遷移項目** —— 成功匯入的內容
- **衝突** —— 因已存在而跳過的項目
- **跳過項目** —— 在來源中未找到的項目
- **錯誤** —— 匯入失敗的項目

執行後的遷移，完整報告會儲存至 `~/.hermes/migration/openclaw/<時間戳記>/`。

## 遷移後注意事項

- **技能需要新會話** —— 匯入的技能會在重啟代理程式或開始新聊天後生效。
- **WhatsApp 需要重新配對** —— WhatsApp 使用 QR-Code 配對，而非基於 Token 的驗證。執行 `hermes whatsapp` 進行配對。
- **封存清理** —— 遷移後，系統會提議將 `~/.openclaw/` 重新命名為 `.openclaw.pre-migration/` 以防止狀態混淆。您稍後也可以執行 `hermes claw cleanup`。

## 疑難排解

### 「找不到 OpenClaw 目錄」
遷移程式預設尋找 `~/.openclaw`，然後嘗試 `~/.clawdbot` 和 `~/.moltbot`。如果您的 OpenClaw 安裝在其他地方，請使用 `--source`：
```bash
hermes claw migrate --source /path/to/.openclaw
```

### 「找不到遷移腳本」
遷移腳本隨 Hermes Agent 一同提供。如果您是透過 pip 安裝 (而非 git clone)，`optional-skills/` 目錄可能不存在。請從技能中心 (Skills Hub) 安裝該技能：
```bash
hermes skills install openclaw-migration
```

### 記憶溢位
如果您的 OpenClaw MEMORY.md 或 USER.md 超過 Hermes 的字元限制，多出的條目會匯出到遷移報告目錄中的溢位檔案。您可以手動檢閱並新增最重要的條目。

### 找不到 API 金鑰
金鑰可能儲存在不同的位置，取決於您的 OpenClaw 設定：
- `~/.openclaw/.env` 檔案
- 內嵌在 `openclaw.json` 的 `models.providers.*.apiKey` 中
- 在 `openclaw.json` 的 `"env"` 或 `"env.vars"` 子物件中
- 在 `~/.openclaw/agents/main/agent/auth-profiles.json` 中

遷移程式會檢查這四個位置。如果金鑰使用 `source: "file"` 或 `source: "exec"` 的 SecretRefs，則無法自動解析 —— 請透過 `hermes config set` 新增。
