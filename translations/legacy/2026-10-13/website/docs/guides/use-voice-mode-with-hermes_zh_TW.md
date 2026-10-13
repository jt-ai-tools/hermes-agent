---
sidebar_position: 8
title: "在 Hermes 中使用語音模式"
description: "在 CLI、Telegram、Discord 及其語音頻道中設定與使用 Hermes 語音模式的實用指南"
---

# 在 Hermes 中使用語音模式

本指南是[語音模式功能參考](/docs/user-guide/features/voice-mode)的實用操作手冊。

如果功能介紹頁面解釋了語音模式能做什麼，那麼本指南將向您展示如何實際且高效地使用它。

## 語音模式的適用場景

語音模式在以下情況特別有用：
- 您想要一個免持（Hands-free）的 CLI 工作流。
- 您希望在 Telegram 或 Discord 中獲得口說回應。
- 您希望 Hermes 加入 Discord 語音頻道進行即時對話。
- 當您在走路而非打字時，想要快速捕捉點子、進行除錯或來回對話。

## 選擇您的語音模式設定

Hermes 提供三種不同的語音體驗。

| 模式 | 最佳用途 | 平台 |
|---|---|---|
| 互動式麥克風迴圈 | 在編碼或研究時進行個人免持使用 | CLI |
| 聊天中的語音回覆 | 在一般訊息對話中獲得口說回應 | Telegram, Discord |
| 即時語音頻道機器人 | 在語音頻道（VC）中進行群組或個人即時對話 | Discord 語音頻道 |

建議的實作路徑：
1. 先確保文字模式運作正常。
2. 接著啟用語音回覆。
3. 最後，如果您想要完整體驗，再嘗試進入 Discord 語音頻道。

## 第 1 步：確保 Hermes 文字模式運作正常

在接觸語音模式之前，請先驗證：
- Hermes 可以啟動。
- 已設定模型提供者。
- Agent 可以正常回答文字提示語。

```bash
hermes
```

詢問一些簡單的問題：

```text
你有什麼可用的工具？
```

如果這部分還不穩定，請先修復文字模式。

## 第 2 步：安裝必要的額外組件

### CLI 麥克風 + 播放功能

```bash
pip install "hermes-agent[voice]"
```

### 即時通訊平台

```bash
pip install "hermes-agent[messaging]"
```

### 高階 ElevenLabs TTS

```bash
pip install "hermes-agent[tts-premium]"
```

### 本地 NeuTTS (選填)

```bash
python -m pip install -U neutts[all]
```

### 安裝所有組件

```bash
pip install "hermes-agent[all]"
```

## 第 3 步：安裝系統相依套件

### macOS

```bash
brew install portaudio ffmpeg opus
brew install espeak-ng
```

### Ubuntu / Debian

```bash
sudo apt install portaudio19-dev ffmpeg libopus0
sudo apt install espeak-ng
```

為什麼這些套件很重要：
- `portaudio` → 用於 CLI 語音模式的麥克風輸入與播放。
- `ffmpeg` → 用於 TTS 和訊息遞送的音訊轉檔。
- `opus` → 支援 Discord 語音編解碼器。
- `espeak-ng` → 作為 NeuTTS 的音位化（Phonemizer）後端。

## 第 4 步：選擇 STT 與 TTS 提供者

Hermes 支援本地端和雲端語音技術棧。

### 最簡單 / 最划算的設定

使用本地 STT 與免費的 Edge TTS：
- STT 提供者：`local`
- TTS 提供者：`edge`

這通常是最佳的起步選擇。

### 環境變數檔案 (.env) 範例

將以下內容添加到 `~/.hermes/.env`：

```bash
# 雲端 STT 選項 (使用本地 STT 不需要金鑰)
GROQ_API_KEY=***
VOICE_TOOLS_OPENAI_KEY=***

# 高階 TTS (選填)
ELEVENLABS_API_KEY=***
```

### 提供者建議

#### 語音轉文字 (STT)

- `local` → 重視隱私與零成本使用的最佳預設選擇。
- `groq` → 非常快速的雲端轉錄。
- `openai` → 不錯的付費備選方案。

#### 文字轉語音 (TTS)

- `edge` → 免費且對大多數使用者來說品質足夠。
- `neutts` → 免費的本地/裝置端 TTS。
- `elevenlabs` → 品質最佳。
- `openai` → 不錯的中庸之選。
- `mistral` → 支援多語言、原生 Opus。

### 如果您使用 `hermes setup`

如果您在設定精靈中選擇了 NeuTTS，Hermes 會檢查 `neutts` 是否已安裝。如果缺失，精靈會告知您 NeuTTS 需要 Python 套件 `neutts` 以及系統套件 `espeak-ng`，並詢問是否幫您安裝。它會透過您平台的套件管理員安裝 `espeak-ng`，然後執行：

```bash
python -m pip install -U neutts[all]
```

如果您跳過安裝或安裝失敗，精靈會退而使用 Edge TTS。

## 第 5 步：推薦設定

```yaml
voice:
  record_key: "ctrl+b"
  max_recording_seconds: 120
  auto_tts: false
  silence_threshold: 200
  silence_duration: 3.0

stt:
  provider: "local"
  local:
    model: "base"

tts:
  provider: "edge"
  edge:
    voice: "en-US-AriaNeural"
```

這是對大多數人來說不錯的保守預設值。

如果您想改用本地 TTS，請將 `tts` 區塊修改為：

```yaml
tts:
  provider: "neutts"
  neutts:
    ref_audio: ''
    ref_text: ''
    model: neuphonic/neutts-air-q4-gguf
    device: cpu
```

## 使用場景 1：CLI 語音模式

## 開啟功能

啟動 Hermes：

```bash
hermes
```

在 CLI 內部輸入：

```text
/voice on
```

### 錄音流程

預設按鍵：
- `Ctrl+B`

工作流：
1. 按下 `Ctrl+B`。
2. 說話。
3. 等待靜音偵測自動停止錄音。
4. Hermes 會轉錄並回應。
5. 如果 TTS 已開啟，它會讀出答案。
6. 迴圈可以自動重啟以實現連續使用。

### 常用指令

```text
/voice        # 查看語音狀態
/voice on     # 開啟語音
/voice off    # 關閉語音
/voice tts    # 切換 TTS 語音朗讀
/voice status # 查看語音詳細狀態
```

### 優秀的 CLI 工作流

#### 免持除錯 (Hands-free Debugging)

說：

```text
我一直遇到 Docker 權限錯誤，幫我除錯。
```

然後繼續免持對話：
- 「再讀一次最後一個錯誤。」
- 「用更簡單的方式解釋根本原因。」
- 「現在給我具體的修復方案。」

#### 研究 / 腦力激盪

非常適用於：
- 邊走路邊思考。
- 口述未成形的點子。
- 要求 Hermes 即時整理您的思緒。

#### 無障礙 / 低打字需求

如果您不方便打字，語音模式是留在完整 Hermes 工作流中最快的方法之一。

## 調整 CLI 行為

### 靜音閾值 (Silence threshold)

如果 Hermes 太頻繁地開始或停止錄音，請調整：

```yaml
voice:
  silence_threshold: 250
```

閾值越高 = 靈敏度越低。

### 靜音持續時間 (Silence duration)

如果您在句子之間經常停頓，請增加此數值：

```yaml
voice:
  silence_duration: 4.0
```

### 錄音按鍵 (Record key)

如果 `Ctrl+B` 與您的終端機或 tmux 快捷鍵衝突：

```yaml
voice:
  record_key: "ctrl+space"
```

## 使用場景 2：Telegram 或 Discord 的語音回覆

這種模式比完整的語音頻道簡單。

Hermes 仍然是普通的聊天機器人，但可以口說回覆。

### 啟動閘道器 (Gateway)

```bash
hermes gateway
```

### 開啟語音回覆

在 Telegram 或 Discord 內部輸入：

```text
/voice on
```

或

```text
/voice tts
```

### 模式

| 模式 | 意義 |
|---|---|
| `off` | 僅文字 |
| `voice_only` | 僅當使用者傳送語音訊息時才口說回覆 |
| `all` | 對每一則回覆都進行口說回應 |

### 何時使用哪種模式

- `/voice on`：如果您只希望對語音訊息進行口說回覆。
- `/voice tts`：如果您希望全程都有語音助手陪伴。

### 優秀的即時通訊工作流

#### 手機上的 Telegram 助手

適用場景：
- 您不在電腦前。
- 您想傳送語音筆記並獲得快速的口說回覆。
- 您想讓 Hermes 充當行動研究或運維助手。

#### Discord 私訊 (DMs) 口說輸出

當您想要私密互動，且不希望受到伺服器頻道標記（Mention）行為干擾時很有用。

## 使用場景 3：Discord 語音頻道

這是最高階的模式。

Hermes 加入 Discord 語音頻道，聆聽使用者說話並將其轉錄，執行正常的 Agent 流程，然後將回應說回頻道中。

## 必要的 Discord 權限

除了正常的文字機器人設定外，請確保機器人具備以下權限：
- Connect (連接)
- Speak (說話)
- 建議開啟 Use Voice Activity (使用語音活動偵測)

同時在開發者後台（Developer Portal）開啟特權意圖（Privileged Intents）：
- Presence Intent
- Server Members Intent
- Message Content Intent

## 加入與離開

在機器人所在的 Discord 文字頻道中輸入：

```text
/voice join
/voice leave
/voice status
```

### 加入頻道後會發生什麼

- 使用者在語音頻道（VC）中說話。
- Hermes 偵測語音邊界。
- 逐字稿會發佈在關聯的文字頻道中。
- Hermes 以文字和音訊進行回應。
- 關聯的文字頻道就是您執行 `/voice join` 的那個頻道。

### Discord 語音頻道使用最佳實踐

- 嚴格管控 `DISCORD_ALLOWED_USERS`。
- 一開始先使用專用的機器人/測試頻道。
- 在嘗試語音頻道模式之前，先驗證一般的文字聊天語音模式（STT 與 TTS）是否運作正常。

## 語音品質建議

### 最佳品質設定

- STT：本地端 `large-v3` 或 Groq `whisper-large-v3`
- TTS：ElevenLabs

### 最佳速度 / 便利性設定

- STT：本地端 `base` 或 Groq
- TTS：Edge

### 最佳零成本設定

- STT：本地端
- TTS：Edge

## 常見失敗模式

### 「找不到音訊裝置 (No audio device found)」

請安裝 `portaudio`。

### 「機器人加入了但聽不到任何聲音」

請檢查：
- 您的 Discord 使用者 ID 是否在 `DISCORD_ALLOWED_USERS` 中。
- 您是否靜音了自己。
- 特權意圖（Privileged Intents）是否已開啟。
- 機器人是否具備 Connect/Speak 權限。

### 「可以轉錄但不會說話」

請檢查：
- TTS 提供者設定。
- ElevenLabs 或 OpenAI 的 API 金鑰 / 額度。
- 是否已安裝 `ffmpeg`（Edge 轉換路徑需要）。

### 「Whisper 輸出垃圾內容」

嘗試：
- 更安靜的環境。
- 提高 `silence_threshold`。
- 更換不同的 STT 提供者或模型。
- 更短、更清晰的發言。

### 「在私訊中可行，但在伺服器頻道中不行」

這通常是標記（Mention）策略的問題。

預設情況下，除非另有設定，否則機器人在 Discord 伺服器文字頻道中需要 `@提及` 才會回應。

## 建議的首週設定

如果您想以最短的路徑達成目標：

1. 先確保 Hermes 文字模式運作正常。
2. 安裝 `hermes-agent[voice]`。
3. 使用 CLI 語音模式搭配本地 STT + Edge TTS。
4. 接著在 Telegram 或 Discord 中啟用 `/voice on`。
5. 完成後，再嘗試 Discord 語音頻道模式。

這樣的進程能將除錯範圍維持在最小。

## 後續閱讀

- [語音模式功能參考](/docs/user-guide/features/voice-mode)
- [訊息閘道器 (Gateway)](/docs/user-guide/messaging)
- [Discord 設定](/docs/user-guide/messaging/discord)
- [Telegram 設定](/docs/user-guide/messaging/telegram)
- [組態設定](/docs/user-guide/configuration)
