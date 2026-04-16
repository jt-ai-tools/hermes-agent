---
sidebar_position: 9
title: "語音與 TTS"
description: "跨所有平台的文字轉語音與語音訊息轉錄功能"
---

# 語音與 TTS

Hermes Agent 支援跨所有通訊平台的文字轉語音 (TTS) 輸出與語音訊息轉錄 (STT) 功能。

## 文字轉語音 (Text-to-Speech)

透過六個供應商將文字轉換為語音：

| 供應商 | 品質 | 費用 | API 金鑰 |
|----------|---------|------|---------|
| **Edge TTS** (預設) | 良好 | 免費 | 不需要 |
| **ElevenLabs** | 極佳 | 付費 | `ELEVENLABS_API_KEY` |
| **OpenAI TTS** | 良好 | 付費 | `VOICE_TOOLS_OPENAI_KEY` |
| **MiniMax TTS** | 極佳 | 付費 | `MINIMAX_API_KEY` |
| **Mistral (Voxtral TTS)** | 極佳 | 付費 | `MISTRAL_API_KEY` |
| **NeuTTS** | 良好 | 免費 | 不需要 |

### 平台傳送方式

| 平台 | 傳送方式 | 格式 |
|----------|----------|--------|
| Telegram | 語音泡泡 (行內播放) | Opus `.ogg` |
| Discord | 語音泡泡 (Opus/OGG)，失敗則退回檔案附件 | Opus/MP3 |
| WhatsApp | 音訊檔案附件 | MP3 |
| CLI | 儲存至 `~/.hermes/audio_cache/` | MP3 |

### 設定

```yaml
# 位於 ~/.hermes/config.yaml
tts:
  provider: "edge"              # "edge" | "elevenlabs" | "openai" | "minimax" | "mistral" | "neutts"
  speed: 1.0                    # 全域語音速度倍率 (供應商特定設定會覆蓋此項)
  edge:
    voice: "en-US-AriaNeural"   # 322 種語音，74 種語言
    speed: 1.0                  # 轉換為速率百分比 (+/-%)
  elevenlabs:
    voice_id: "pNInz6obpgDQGcFmaJgB"  # Adam
    model_id: "eleven_multilingual_v2"
  openai:
    model: "gpt-4o-mini-tts"
    voice: "alloy"              # alloy, echo, fable, onyx, nova, shimmer
    base_url: "https://api.openai.com/v1"  # 覆蓋為 OpenAI 相容的 TTS 端點
    speed: 1.0                  # 0.25 - 4.0
  minimax:
    model: "speech-2.8-hd"     # speech-2.8-hd (預設), speech-2.8-turbo
    voice_id: "English_Graceful_Lady"  # 請參閱 https://platform.minimax.io/faq/system-voice-id
    speed: 1                    # 0.5 - 2.0
    vol: 1                      # 0 - 10
    pitch: 0                    # -12 - 12
  mistral:
    model: "voxtral-mini-tts-2603"
    voice_id: "c69964a6-ab8b-4f8a-9465-ec0925096ec8"  # Paul - Neutral (預設)
  neutts:
    ref_audio: ''
    ref_text: ''
    model: neuphonic/neutts-air-q4-gguf
    device: cpu
```

**語音速度控制**：全域 `tts.speed` 值預設適用於所有供應商。每個供應商可以使用自己的 `speed` 設定進行覆蓋 (例如 `tts.openai.speed: 1.5`)。供應商特定的速度設定優先於全域值。預設為 `1.0` (正常速度)。

### Telegram 語音泡泡與 ffmpeg

Telegram 語音泡泡需要 Opus/OGG 音訊格式：

- **OpenAI、ElevenLabs 與 Mistral** 原生產生 Opus — 無需額外設定
- **Edge TTS** (預設) 輸出 MP3，需要 **ffmpeg** 進行轉換
- **MiniMax TTS** 輸出 MP3，需要 **ffmpeg** 轉換為 Telegram 語音泡泡格式
- **NeuTTS** 輸出 WAV，也需要 **ffmpeg** 轉換為 Telegram 語音泡泡格式

```bash
# Ubuntu/Debian
sudo apt install ffmpeg

# macOS
brew install ffmpeg

# Fedora
sudo dnf install ffmpeg
```

如果沒有 ffmpeg，Edge TTS、MiniMax TTS 與 NeuTTS 音訊將作為一般的音訊檔案發送 (可播放，但會顯示為長方形播放器而非語音泡泡)。

:::tip 小撇步
如果您想在不安裝 ffmpeg 的情況下使用語音泡泡，請切換至 OpenAI、ElevenLabs 或 Mistral 供應商。
:::

## 語音訊息轉錄 (STT)

在 Telegram、Discord、WhatsApp、Slack 或 Signal 上發送的語音訊息會自動轉錄並作為文字注入對話中。Agent 會將轉錄內容視為一般文字。

| 供應商 | 品質 | 費用 | API 金鑰 |
|----------|---------|------|---------| 
| **Local Whisper** (預設) | 良好 | 免費 | 不需要 |
| **Groq Whisper API** | 良好至極佳 | 免費層級 | `GROQ_API_KEY` |
| **OpenAI Whisper API** | 良好至極佳 | 付費 | `VOICE_TOOLS_OPENAI_KEY` 或 `OPENAI_API_KEY` |

:::info 零設定
安裝 `faster-whisper` 後，本地轉錄功能即可開箱即用。如果該套件不可用，Hermes 也可以使用來自常見安裝位置 (如 `/opt/homebrew/bin`) 的本地 `whisper` CLI，或透過 `HERMES_LOCAL_STT_COMMAND` 使用自定義指令。
:::

### 設定

```yaml
# 位於 ~/.hermes/config.yaml
stt:
  provider: "local"           # "local" | "groq" | "openai" | "mistral"
  local:
    model: "base"             # tiny, base, small, medium, large-v3
  openai:
    model: "whisper-1"        # whisper-1, gpt-4o-mini-transcribe, gpt-4o-transcribe
  mistral:
    model: "voxtral-mini-latest"  # voxtral-mini-latest, voxtral-mini-2602
```

### 供應商詳情

**本地 (faster-whisper)** — 透過 [faster-whisper](https://github.com/SYSTRAN/faster-whisper) 在本地執行 Whisper。預設使用 CPU，若有 GPU 則會優先使用。模型大小如下：

| 模型 | 大小 | 速度 | 品質 |
|-------|------|-------|---------|
| `tiny` | ~75 MB | 最快 | 基本 |
| `base` | ~150 MB | 快 | 良好 (預設) |
| `small` | ~500 MB | 中等 | 較佳 |
| `medium` | ~1.5 GB | 較慢 | 優異 |
| `large-v3` | ~3 GB | 最慢 | 最佳 |

**Groq API** — 需要 `GROQ_API_KEY`。當您需要免費的雲端託管 STT 選項時，這是一個很好的備援方案。

**OpenAI API** — 優先接受 `VOICE_TOOLS_OPENAI_KEY`，其次是 `OPENAI_API_KEY`。支援 `whisper-1`、`gpt-4o-mini-transcribe` 和 `gpt-4o-transcribe`。

**Mistral API (Voxtral Transcribe)** — 需要 `MISTRAL_API_KEY`。使用 Mistral 的 [Voxtral Transcribe](https://docs.mistral.ai/capabilities/audio/speech_to_text/) 模型。支援 13 種語言、說者識別 (speaker diarization) 和詞級時間戳記。請使用 `pip install hermes-agent[mistral]` 安裝。

**自定義本地 CLI 備援** — 如果您希望 Hermes 直接呼叫本地轉錄指令，請設定 `HERMES_LOCAL_STT_COMMAND`。指令範本支援 `{input_path}`、`{output_dir}`、`{language}` 和 `{model}` 佔位符。

### 備援行為

如果您設定的供應商不可用，Hermes 會自動啟動備援機制：
- **本地 faster-whisper 不可用** → 在嘗試雲端供應商之前，先嘗試本地 `whisper` CLI 或 `HERMES_LOCAL_STT_COMMAND`
- **未設定 Groq 金鑰** → 備援至本地轉錄，然後是 OpenAI
- **未設定 OpenAI 金鑰** → 備援至本地轉錄，然後是 Groq
- **未設定 Mistral 金鑰/SDK** → 在自動偵測中跳過，切換至下一個可用的供應商
- **全數不可用** → 語音訊息會直接傳送，並附帶一條說明給使用者
