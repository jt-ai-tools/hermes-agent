---
sidebar_position: 10
title: "語音模式"
description: "與 Hermes Agent 進行即時語音對話 — 支援 CLI、Telegram、Discord (私訊、文字頻道與語音頻道)"
---

# 語音模式

Hermes Agent 支援跨 CLI 與通訊平台的完整語音互動。您可以透過麥克風與 Agent 交談、聆聽語音回覆，並在 Discord 語音頻道中進行即時語音對話。

如果您想查看包含推薦設定與實際使用情境的安裝指南，請參閱 [搭配 Hermes 使用語音模式](/docs/guides/use-voice-mode-with-hermes)。

## 前置作業

在使用語音功能之前，請確保您已完成以下準備：

1. **已安裝 Hermes Agent** — `pip install hermes-agent` (請參閱 [安裝指南](/docs/getting-started/installation))
2. **已設定 LLM 供應商** — 執行 `hermes model` 或在 `~/.hermes/.env` 中設定偏好的供應商憑證
3. **基礎設定運作正常** — 在啟用語音前，先執行 `hermes` 驗證 Agent 能正常回應文字

:::tip 小撇步
當您第一次執行 `hermes` 時，系統會自動建立 `~/.hermes/` 目錄與預設的 `config.yaml`。您只需要手動建立 `~/.hermes/.env` 來存放 API 金鑰。
:::

## 概覽

| 功能 | 平台 | 描述 |
|---------|----------|-------------|
| **互動式語音** | CLI | 按 Ctrl+B 開始錄音，Agent 會自動偵測停頓並回應 |
| **自動語音回覆** | Telegram, Discord | Agent 在發送文字回應的同時，也會發送語音訊息 |
| **語音頻道** | Discord | Bot 加入語音頻道 (VC)，聆聽使用者說話並以語音回覆 |

## 需求項目

### Python 套件

```bash
# CLI 語音模式 (麥克風 + 音訊播放)
pip install "hermes-agent[voice]"

# Discord + Telegram 通訊 (包含支援語音頻道的 discord.py[voice])
pip install "hermes-agent[messaging]"

# 進階 TTS (ElevenLabs)
pip install "hermes-agent[tts-premium]"

# 本地 TTS (NeuTTS，選用)
python -m pip install -U neutts[all]

# 一次安裝所有功能
pip install "hermes-agent[all]"
```

| 擴充功能 | 套件 | 適用於 |
|-------|----------|-------------|
| `voice` | `sounddevice`, `numpy` | CLI 語音模式 |
| `messaging` | `discord.py[voice]`, `python-telegram-bot`, `aiohttp` | Discord 與 Telegram Bot |
| `tts-premium` | `elevenlabs` | ElevenLabs TTS 供應商 |

選用的本地 TTS 供應商：請透過 `python -m pip install -U neutts[all]` 獨立安裝 `neutts`。第一次使用時會自動下載模型。

:::info 資訊
`discord.py[voice]` 會自動安裝 **PyNaCl** (用於語音加密) 與 **opus 綁定**。這是支援 Discord 語音頻道所必需的。
:::

### 系統依賴項目

```bash
# macOS
brew install portaudio ffmpeg opus
brew install espeak-ng   # 適用於 NeuTTS

# Ubuntu/Debian
sudo apt install portaudio19-dev ffmpeg libopus0
sudo apt install espeak-ng   # 適用於 NeuTTS
```

| 依賴項目 | 用途 | 適用於 |
|-----------|---------|-------------|
| **PortAudio** | 麥克風輸入與音訊播放 | CLI 語音模式 |
| **ffmpeg** | 音訊格式轉換 (MP3 → Opus, PCM → WAV) | 所有平台 |
| **Opus** | Discord 語音編解碼器 | Discord 語音頻道 |
| **espeak-ng** | 音素化 (Phonemizer) 後端 | 本地 NeuTTS 供應商 |

### API 金鑰

請將以下內容新增至 `~/.hermes/.env`：

```bash
# 語音轉文字 (STT) — 本地供應商完全不需要金鑰
# pip install faster-whisper          # 免費，在本地執行，推薦使用
GROQ_API_KEY=your-key                 # Groq Whisper — 快速，有免費層級 (雲端)
VOICE_TOOLS_OPENAI_KEY=your-key       # OpenAI Whisper — 付費 (雲端)

# 文字轉語音 (TTS，選用 — Edge TTS 與 NeuTTS 不需要任何金鑰)
ELEVENLABS_API_KEY=***           # ElevenLabs — 頂級品質
# 上方的 VOICE_TOOLS_OPENAI_KEY 同樣可用於 OpenAI TTS
```

:::tip 小撇步
如果已安裝 `faster-whisper`，語音模式在 STT 方面不需要任何 API 金鑰即可運作。模型 (以 `base` 模型為例，約 150 MB) 會在第一次使用時自動下載。
:::

---

## CLI 語音模式

### 快速開始

啟動 CLI 並啟用語音模式：

```bash
hermes                # 啟動互動式 CLI
```

接著在 CLI 內部使用以下指令：

```
/voice          切換語音模式開啟/關閉
/voice on       啟用語音模式
/voice off      停用語音模式
/voice tts      切換 TTS 輸出
/voice status   顯示目前狀態
```

### 運作方式

1. 使用 `hermes` 啟動 CLI，並輸入 `/voice on` 啟用語音模式
2. **按下 Ctrl+B** — 播放一聲嗶聲 (880Hz)，錄音開始
3. **說話** — 畫面會顯示即時音量條：`● [▁▂▃▅▇▇▅▂] ❯`
4. **停止說話** — 偵測到 3 秒靜音後，錄音會自動停止
5. **播放兩聲嗶聲** (660Hz) 確認錄音結束
6. 音訊會透過 Whisper 轉錄並發送給 Agent
7. 如果啟用了 TTS，Agent 的回覆會以語音唸出
8. 錄音會 **自動重啟** — 再次說話即可，無需按任何鍵

此循環會持續進行，直到您在錄音期間按下 **Ctrl+B** (退出連續模式) 或連續 3 次錄音未偵測到任何語音。

:::tip 小撇步
錄音鍵可透過 `~/.hermes/config.yaml` 中的 `voice.record_key` 進行自定義 (預設為 `ctrl+b`)。
:::

### 靜音偵測

採用兩階段演算法偵測您何時結束說話：

1. **語音確認** — 等待音訊超過 RMS 閾值 (200) 持續至少 0.3 秒，容許音節間的短暫停頓
2. **結束偵測** — 語音確認後，若持續靜音達 3.0 秒則觸發停止

如果 15 秒內完全未偵測到語音，錄音會自動停止。

`silence_threshold` (靜音閾值) 與 `silence_duration` (靜音時長) 皆可在 `config.yaml` 中設定。

### 串流式 TTS

啟用 TTS 後，Agent 會在產生文字的同時，**逐句** 唸出其回覆 — 您不需要等待完整回應：

1. 將文字片段緩衝成完整的句子 (至少 20 個字元)
2. 移除 Markdown 格式與 `<think>` 區塊
3. 即時產生並播放各句子的音訊

### 幻覺過濾器 (Hallucination Filter)

Whisper 有時會從靜音或背景噪音中產生虛幻文字 (例如 "Thank you for watching"、"Subscribe" 等)。Agent 會使用一組包含多種語言的 26 個已知幻覺短語，以及可捕捉重複變體的正則表達式來過濾這些內容。

---

## 閘道器語音回覆 (Telegram & Discord)

如果您尚未設定通訊 Bot，請參閱各平台的設定指南：
- [Telegram 設定指南](../messaging/telegram.md)
- [Discord 設定指南](../messaging/discord.md)

啟動閘道器 (gateway) 以連線至您的通訊平台：

```bash
hermes gateway        # 啟動閘道器 (連線至已設定的平台)
hermes gateway setup  # 互動式設定精靈，用於首次設定
```

### Discord：頻道 vs 私訊 (DM)

Bot 在 Discord 上支援兩種互動模式：

| 模式 | 如何交談 | 是否需要標註 (@mention) | 設定 |
|------|------------|-----------------|-------|
| **私訊 (DM)** | 開啟 Bot 的個人檔案 → "發送訊息" | 否 | 立即生效 |
| **伺服器頻道** | 在有 Bot 的文字頻道中輸入文字 | 是 (`@bot名稱`) | 必須邀請 Bot 加入伺服器 |

**私訊 (推薦個人使用)：** 直接與 Bot 開啟私訊即可交談 — 不需要標註 (@mention)。語音回覆與所有指令運作方式皆與頻道相同。

**伺服器頻道：** 只有當您標註 (@mention) Bot 時 (例如 `@hermesbyt4 你好`)，Bot 才會回應。請務必從標註彈出視窗中選擇 **Bot 使用者**，而非同名的身分組。

:::tip 小撇步
若要在伺服器頻道中停用標註要求，請在 `~/.hermes/.env` 中加入：
```bash
DISCORD_REQUIRE_MENTION=false
```
或者將特定頻道設定為自由回應 (不需標註)：
```bash
DISCORD_FREE_RESPONSE_CHANNELS=123456789,987654321
```
:::

### 指令

這些指令適用於 Telegram 與 Discord (包含私訊與文字頻道)：

```
/voice          切換語音模式開啟/關閉
/voice on       僅在您發送語音訊息時才以語音回覆
/voice tts      對所有訊息都以語音回覆
/voice off      停用語音回覆
/voice status   顯示目前設定
```

### 模式

| 模式 | 指令 | 行為 |
|------|---------|----------|
| `off` | `/voice off` | 僅文字 (預設) |
| `voice_only` | `/voice on` | 僅在您發送語音訊息時才唸出回覆 |
| `all` | `/voice tts` | 對每條訊息都唸出回覆 |

語音模式設定在閘道器重啟後仍會保留。

### 平台傳送方式

| 平台 | 格式 | 備註 |
|----------|--------|-------|
| **Telegram** | 語音泡泡 (Opus/OGG) | 在聊天室中行內播放。如有需要，ffmpeg 會將 MP3 轉換為 Opus |
| **Discord** | 原生語音泡泡 (Opus/OGG) | 像一般使用者語音訊息一樣行內播放。若語音泡泡 API 失敗，則退回檔案附件 |

---

## Discord 語音頻道

最令人沉浸的語音功能：Bot 加入 Discord 語音頻道，聆聽使用者說話，將其語音轉錄，透過 Agent 處理，並在語音頻道中以語音回傳。

### 設定

#### 1. Discord Bot 權限

如果您已經為文字功能設定了 Discord Bot (請參閱 [Discord 設定指南](../messaging/discord.md))，您需要新增語音權限。

前往 [Discord 開發者入口網站](https://discord.com/developers/applications) → 您的應用程式 → **Installation** → **Default Install Settings** → **Guild Install**：

**在現有的文字權限中新增以下權限：**

| 權限 | 用途 | 是否必需 |
|-----------|---------|----------|
| **Connect** | 加入語音頻道 | 是 |
| **Speak** | 在語音頻道播放 TTS 音訊 | 是 |
| **Use Voice Activity** | 偵測使用者何時在說話 | 推薦 |

**更新後的權限整數值：**

| 層級 | 整數值 | 包含內容 |
|-------|---------|----------------|
| 僅文字 | `274878286912` | 檢視頻道、發送訊息、讀取歷史紀錄、嵌入連結、附加檔案、串文、反應 |
| 文字 + 語音 | `274881432640` | 以上所有權限 + 連接、說話 |

**使用更新後的權限 URL 重新邀請 Bot：**

```
https://discord.com/oauth2/authorize?client_id=YOUR_APP_ID&scope=bot+applications.commands&permissions=274881432640
```

將 `YOUR_APP_ID` 替換為開發者入口網站中的應用程式 ID。

:::warning 警告
重新邀請已在伺服器中的 Bot 會更新其權限，而不會將其移除。您不會遺失任何數據或設定。
:::

#### 2. 特權閘道器意圖 (Privileged Gateway Intents)

在 [開發者入口網站](https://discord.com/developers/applications) → 您的應用程式 → **Bot** → **Privileged Gateway Intents**，啟用以下三個選項：

| 意圖 | 用途 |
|--------|---------|
| **Presence Intent** | 偵測使用者上線/離線狀態 |
| **Server Members Intent** | 將語音 SSRC 標識符映射至 Discord 使用者 ID |
| **Message Content Intent** | 讀取頻道中的文字訊息內容 |

這三個意圖對於完整的語音頻道功能皆為必需。**Server Members Intent** 尤其關鍵 — 若無此意圖，Bot 將無法識別語音頻道中是誰在說話。

#### 3. Opus 編解碼器

執行閘道器的機器必須安裝 Opus 編解碼器函式庫：

```bash
# macOS (Homebrew)
brew install opus

# Ubuntu/Debian
sudo apt install libopus0
```

Bot 會自動從以下路徑載入編解碼器：
- **macOS:** `/opt/homebrew/lib/libopus.dylib`
- **Linux:** `libopus.so.0`

#### 4. 環境變數

```bash
# ~/.hermes/.env

# Discord Bot (已設定文字功能)
DISCORD_BOT_TOKEN=your-bot-token
DISCORD_ALLOWED_USERS=your-user-id

# STT — 本地供應商不需要金鑰 (pip install faster-whisper)
# GROQ_API_KEY=your-key            # 替代方案：雲端基礎，快速，有免費層級

# TTS — 選用。Edge TTS 與 NeuTTS 不需要金鑰。
# ELEVENLABS_API_KEY=***      # 頂級品質
# VOICE_TOOLS_OPENAI_KEY=***  # OpenAI TTS / Whisper
```

### 啟動閘道器

```bash
hermes gateway        # 使用現有設定啟動
```

Bot 應該會在幾秒鐘內在 Discord 上線。

### 指令

在 Bot 所在的 Discord 文字頻道中使用：

```
/voice join      Bot 加入您目前的語音頻道
/voice channel   /voice join 的別名
/voice leave     Bot 離開語音頻道
/voice status    顯示語音模式與連線頻道
```

:::info 資訊
在執行 `/voice join` 之前，您必須先進入一個語音頻道。Bot 會加入您所在的同一個頻道。
:::

### 運作方式

當 Bot 加入語音頻道後，它會：

1. 獨立 **聆聽** 每個使用者的音訊串流
2. **偵測靜音** — 在至少說話 0.5 秒後，靜音 1.5 秒即觸發處理
3. 透過 Whisper STT (本地、Groq 或 OpenAI) **轉錄** 音訊
4. 透過完整的 Agent 流程 (對話階段、工具、記憶) 進行 **處理**
5. 透過 TTS 將回覆 **唸出** 回語音頻道

### 文字頻道整合

當 Bot 在語音頻道中時：

- 轉錄內容會出現在文字頻道中：`[Voice] @使用者: 你說的話`
- Agent 的回應會以文字發送到頻道，同時在語音頻道中唸出
- 使用的文字頻道為發出 `/voice join` 指令的頻道

### 回音預防 (Echo Prevention)

Bot 在播放 TTS 回覆時會自動暫停其音訊聆聽功能，防止它聽到並重新處理自己的輸出。

### 存取控制

只有列在 `DISCORD_ALLOWED_USERS` 中的使用者才能透過語音進行互動。其他使用者的音訊會被靜默忽略。

```bash
# ~/.hermes/.env
DISCORD_ALLOWED_USERS=284102345871466496
```

---

## 設定參考

### config.yaml

```yaml
# 語音錄製 (CLI)
voice:
  record_key: "ctrl+b"            # 開始/停止錄音的按鍵
  max_recording_seconds: 120       # 最大錄音長度
  auto_tts: false                  # 語音模式啟動時自動啟用 TTS
  silence_threshold: 200           # RMS 級別 (0-32767)，低於此值視為靜音
  silence_duration: 3.0            # 自動停止前的靜音秒數

# 語音轉文字 (STT)
stt:
  provider: "local"                  # "local" (免費) | "groq" | "openai"
  local:
    model: "base"                    # tiny, base, small, medium, large-v3
  # model: "whisper-1"              # 舊版：未設定供應商時使用

# 文字轉語音 (TTS)
tts:
  provider: "edge"                 # "edge" (免費) | "elevenlabs" | "openai" | "neutts" | "minimax"
  edge:
    voice: "en-US-AriaNeural"      # 322 種語音，74 種語言
  elevenlabs:
    voice_id: "pNInz6obpgDQGcFmaJgB"    # Adam
    model_id: "eleven_multilingual_v2"
  openai:
    model: "gpt-4o-mini-tts"
    voice: "alloy"                 # alloy, echo, fable, onyx, nova, shimmer
    base_url: "https://api.openai.com/v1"  # 選用：覆蓋為自行託管或與 OpenAI 相容的端點
  neutts:
    ref_audio: ''
    ref_text: ''
    model: neuphonic/neutts-air-q4-gguf
    device: cpu
```

### 環境變數

```bash
# 語音轉文字供應商 (本地不需要金鑰)
# pip install faster-whisper        # 免費本地 STT — 不需要 API 金鑰
GROQ_API_KEY=...                    # Groq Whisper (快速，有免費層級)
VOICE_TOOLS_OPENAI_KEY=...         # OpenAI Whisper (付費)

# STT 進階覆蓋 (選用)
STT_GROQ_MODEL=whisper-large-v3-turbo    # 覆蓋預設的 Groq STT 模型
STT_OPENAI_MODEL=whisper-1               # 覆蓋預設的 OpenAI STT 模型
GROQ_BASE_URL=https://api.groq.com/openai/v1     # 自定義 Groq 端點
STT_OPENAI_BASE_URL=https://api.openai.com/v1    # 自定義 OpenAI STT 端點

# 文字轉語音供應商 (Edge TTS 與 NeuTTS 不需要金鑰)
ELEVENLABS_API_KEY=***             # ElevenLabs (頂級品質)
# 上方的 VOICE_TOOLS_OPENAI_KEY 同樣可用於 OpenAI TTS

# Discord 語音頻道
DISCORD_BOT_TOKEN=...
DISCORD_ALLOWED_USERS=...
```

### STT 供應商比較

| 供應商 | 模型 | 速度 | 品質 | 費用 | 需要金鑰 |
|----------|-------|-------|---------|------|---------|
| **本地 (Local)** | `base` | 快 (視 CPU/GPU 而定) | 良好 | 免費 | 否 |
| **本地 (Local)** | `small` | 中等 | 較佳 | 免費 | 否 |
| **本地 (Local)** | `large-v3` | 慢 | 最佳 | 免費 | 否 |
| **Groq** | `whisper-large-v3-turbo` | 極快 (~0.5s) | 良好 | 免費層級 | 是 |
| **Groq** | `whisper-large-v3` | 快 (~1s) | 較佳 | 免費層級 | 是 |
| **OpenAI** | `whisper-1` | 快 (~1s) | 良好 | 付費 | 是 |
| **OpenAI** | `gpt-4o-transcribe` | 中等 (~2s) | 最佳 | 付費 | 是 |

供應商優先權 (自動備援)：**local** > **groq** > **openai**

### TTS 供應商比較

| 供應商 | 品質 | 費用 | 延遲 | 需要金鑰 |
|----------|---------|------|---------|-------------|
| **Edge TTS** | 良好 | 免費 | ~1s | 否 |
| **ElevenLabs** | 極佳 | 付費 | ~2s | 是 |
| **OpenAI TTS** | 良好 | 付費 | ~1.5s | 是 |
| **NeuTTS** | 良好 | 免費 | 視 CPU/GPU 而定 | 否 |

NeuTTS 使用上述 `tts.neutts` 設定區塊。

---

## 疑難排解

### "No audio device found" (CLI)

未安裝 PortAudio：

```bash
brew install portaudio    # macOS
sudo apt install portaudio19-dev  # Ubuntu
```

### Bot 在 Discord 伺服器頻道中沒有回應

在伺服器頻道中，預設需要標註 (@mention) Bot。請確保：

1. 輸入 `@` 並選擇 **Bot 使用者** (帶有 #標籤)，而不是同名的 **身分組**
2. 或改用私訊 (DM) — 不需要標註
3. 或在 `~/.hermes/.env` 中設定 `DISCORD_REQUIRE_MENTION=false`

### Bot 加入語音頻道但聽不到我說話

- 檢查您的 Discord 使用者 ID 是否在 `DISCORD_ALLOWED_USERS` 中
- 確保您在 Discord 中沒有被靜音
- Bot 需要先從 Discord 接收到說話事件 (SPEAKING event) 才能映射您的音訊 — 加入後幾秒內請開始說話

### Bot 聽得到我說話但沒有回應

- 驗證 STT 是否可用：安裝 `faster-whisper` (不需金鑰) 或設定 `GROQ_API_KEY` / `VOICE_TOOLS_OPENAI_KEY`
- 檢查 LLM 模型是否已設定且可存取
- 查看閘道器日誌：`tail -f ~/.hermes/logs/gateway.log`

### Bot 有文字回應但語音頻道中沒聲音

- TTS 供應商可能失敗 — 檢查 API 金鑰與配額
- Edge TTS (免費，不需金鑰) 是預設的備援
- 檢查日誌中的 TTS 錯誤

### Whisper 傳回亂碼文字

幻覺過濾器會自動捕捉大多數情況。如果您仍收到幻覺轉錄內容：

- 在較安靜的環境中使用
- 調整設定中的 `silence_threshold` (靜音閾值，越高越不敏感)
- 嘗試不同的 STT 模型
