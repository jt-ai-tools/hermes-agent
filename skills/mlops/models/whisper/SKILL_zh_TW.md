---
name: whisper
description: OpenAI 的通用語音辨識模型。支持 99 種語言、轉錄、翻譯成英文以及語言識別。提供六種模型大小，從 tiny (39M 參數) 到 large (1550M 參數)。適用於語音轉文字、Podcast 轉錄或多語言音訊處理。最適合強健且多語言的 ASR。
version: 1.0.0
author: Orchestra Research
license: MIT
dependencies: [openai-whisper, transformers, torch]
metadata:
  hermes:
    tags: [Whisper, Speech Recognition, ASR, Multimodal, Multilingual, OpenAI, Speech-To-Text, Transcription, Translation, Audio Processing]

---

# Whisper - 強健的語音辨識

OpenAI 的多語言語音辨識模型。

## 何時使用 Whisper

**使用場景：**
- 語音轉文字 (Speech-to-text) 轉錄（支持 99 種語言）
- Podcast/影片轉錄
- 會議記錄自動化
- 翻譯為英文
- 帶噪音的音訊轉錄
- 多語言音訊處理

**指標**：
- **72,900+ GitHub stars**
- 支持 99 種語言
- 在 680,000 小時的音訊上進行訓練
- MIT License

**替代方案**：
- **AssemblyAI**: 託管型 API，支持講者識別 (speaker diarization)
- **Deepgram**: 即時串流 ASR
- **Google Speech-to-Text**: 雲端服務

## 快速開始

### 安裝

```bash
# 需要 Python 3.8-3.11
pip install -U openai-whisper

# 需要 ffmpeg
# macOS: brew install ffmpeg
# Ubuntu: sudo apt install ffmpeg
# Windows: choco install ffmpeg
```

### 基礎轉錄

```python
import whisper

# 載入模型
model = whisper.load_model("base")

# 轉錄
result = model.transcribe("audio.mp3")

# 輸出文字
print(result["text"])

# 訪問分段資訊
for segment in result["segments"]:
    print(f"[{segment['start']:.2f}s - {segment['end']:.2f}s] {segment['text']}")
```

## 模型大小

```python
# 可用的模型
models = ["tiny", "base", "small", "medium", "large", "turbo"]

# 載入特定模型
model = whisper.load_model("turbo")  # 速度最快，品質優良
```

| 模型 | 參數 | 僅限英文 | 多語言 | 速度 | VRAM |
|-------|------------|--------------|--------------|-------|------|
| tiny | 39M | ✓ | ✓ | ~32x | ~1 GB |
| base | 74M | ✓ | ✓ | ~16x | ~1 GB |
| small | 244M | ✓ | ✓ | ~6x | ~2 GB |
| medium | 769M | ✓ | ✓ | ~2x | ~5 GB |
| large | 1550M | ✗ | ✓ | 1x | ~10 GB |
| turbo | 809M | ✗ | ✓ | ~8x | ~6 GB |

**建議**：追求速度與品質的平衡請使用 `turbo`，原型開發請使用 `base`

## 轉錄選項

### 指定語言

```python
# 自動偵測語言
result = model.transcribe("audio.mp3")

# 指定語言（速度更快）
result = model.transcribe("audio.mp3", language="en")

# 支持：en, es, fr, de, it, pt, ru, ja, ko, zh 以及其他 89 種
```

### 任務選擇

```python
# 轉錄 (預設)
result = model.transcribe("audio.mp3", task="transcribe")

# 翻譯為英文
result = model.transcribe("spanish.mp3", task="translate")
# 輸入：西班牙文音訊 → 輸出：英文文字
```

### 初始提示 (Initial prompt)

```python
# 使用上下文提高準確度
result = model.transcribe(
    "audio.mp3",
    initial_prompt="This is a technical podcast about machine learning and AI."
)

# 有助於：
# - 專業術語
# - 專有名詞
# - 特定領域詞彙
```

### 時間戳記

```python
# 字級時間戳記
result = model.transcribe("audio.mp3", word_timestamps=True)

for segment in result["segments"]:
    for word in segment["words"]:
        print(f"{word['word']} ({word['start']:.2f}s - {word['end']:.2f}s)")
```

### 溫度回退 (Temperature fallback)

```python
# 如果信心度低，則嘗試使用不同的溫度進行重試
result = model.transcribe(
    "audio.mp3",
    temperature=(0.0, 0.2, 0.4, 0.6, 0.8, 1.0)
)
```

## 命令列用法

```bash
# 基礎轉錄
whisper audio.mp3

# 指定模型
whisper audio.mp3 --model turbo

# 輸出格式
whisper audio.mp3 --output_format txt     # 純文字
whisper audio.mp3 --output_format srt     # 字幕
whisper audio.mp3 --output_format vtt     # WebVTT
whisper audio.mp3 --output_format json    # 包含時間戳記的 JSON

# 語言
whisper audio.mp3 --language Spanish

# 翻譯
whisper spanish.mp3 --task translate
```

## 批次處理

```python
import os

audio_files = ["file1.mp3", "file2.mp3", "file3.mp3"]

for audio_file in audio_files:
    print(f"Transcribing {audio_file}...")
    result = model.transcribe(audio_file)

    # 儲存到檔案
    output_file = audio_file.replace(".mp3", ".txt")
    with open(output_file, "w") as f:
        f.write(result["text"])
```

## 即時轉錄

```python
# 對於串流音訊，使用 faster-whisper
# pip install faster-whisper

from faster_whisper import WhisperModel

model = WhisperModel("base", device="cuda", compute_type="float16")

# 串流轉錄
segments, info = model.transcribe("audio.mp3", beam_size=5)

for segment in segments:
    print(f"[{segment.start:.2f}s -> {segment.end:.2f}s] {segment.text}")
```

## GPU 加速

```python
import whisper

# 如果可用，會自動使用 GPU
model = whisper.load_model("turbo")

# 強制使用 CPU
model = whisper.load_model("turbo", device="cpu")

# 強制使用 GPU
model = whisper.load_model("turbo", device="cuda")

# 在 GPU 上快 10-20 倍
```

## 與其他工具整合

### 字幕生成

```bash
# 生成 SRT 字幕
whisper video.mp4 --output_format srt --language English

# 輸出：video.srt
```

### 與 LangChain 搭配

```python
from langchain.document_loaders import WhisperTranscriptionLoader

loader = WhisperTranscriptionLoader(file_path="audio.mp3")
docs = loader.load()

# 在 RAG 中使用轉錄內容
from langchain_chroma import Chroma
from langchain_openai import OpenAIEmbeddings

vectorstore = Chroma.from_documents(docs, OpenAIEmbeddings())
```

### 從影片中提取音訊

```bash
# 使用 ffmpeg 提取音訊
ffmpeg -i video.mp4 -vn -acodec pcm_s16le audio.wav

# 然後進行轉錄
whisper audio.wav
```

## 最佳實踐

1. **使用 turbo 模型** - 英文轉錄的最佳速度/品質比。
2. **指定語言** - 比自動偵測更快。
3. **增加初始提示 (initial prompt)** - 改善技術術語辨識。
4. **使用 GPU** - 速度快 10-20 倍。
5. **批次處理** - 效率更高。
6. **轉換為 WAV** - 相容性較好。
7. **切割長音訊** - 建議小於 30 分鐘一個區塊。
8. **檢查語言支持** - 不同語言的品質有所差異。
9. **使用 faster-whisper** - 比 openai-whisper 快 4 倍。
10. **監控 VRAM** - 根據硬體調整模型大小。

## 效能

| 模型 | 即時因子 (Real-time factor) (CPU) | 即時因子 (Real-time factor) (GPU) |
|-------|------------------------|------------------------|
| tiny | ~0.32 | ~0.01 |
| base | ~0.16 | ~0.01 |
| turbo | ~0.08 | ~0.01 |
| large | ~1.0 | ~0.05 |

*即時因子 (Real-time factor)：0.1 = 比即時快 10 倍*

## 語言支持

主要支持的語言：
- 英文 (en)
- 西班牙文 (es)
- 法文 (fr)
- 德文 (de)
- 義大利文 (it)
- 葡萄牙文 (pt)
- 俄文 (ru)
- 日文 (ja)
- 韓文 (ko)
- 中文 (zh)

完整列表：總共 99 種語言

## 限制

1. **幻覺 (Hallucinations)** - 可能會重複或編造文字。
2. **長篇轉錄準確度** - 在超過 30 分鐘的音訊中效能會下降。
3. **講者識別 (Speaker identification)** - 不包含講者分離 (diarization)。
4. **口音** - 品質因口音而異。
5. **背景噪音** - 可能影響準確度。
6. **即時延遲** - 不適用於現場直播字幕。

## 資源

- **GitHub**: https://github.com/openai/whisper ⭐ 72,900+
- **Paper**: https://arxiv.org/abs/2212.04356
- **Model Card**: https://github.com/openai/whisper/blob/main/model-card.md
- **Colab**: 可在 repo 中找到
- **License**: MIT
