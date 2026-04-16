# Whisper 語言支持指南

Whisper 多語言能力的完整指南。

## 支持的語言 (共 99 種)

### 頂級支持 (WER < 10%)

- 英文 (en)
- 西班牙文 (es)
- 法文 (fr)
- 德文 (de)
- 義大利文 (it)
- 葡萄牙文 (pt)
- 荷蘭文 (nl)
- 波蘭文 (pl)
- 俄文 (ru)
- 日文 (ja)
- 韓文 (ko)
- 中文 (zh)

### 良好支持 (WER 10-20%)

- 阿拉伯文 (ar)
- 土耳其文 (tr)
- 越南文 (vi)
- 瑞典文 (sv)
- 芬蘭文 (fi)
- 捷克文 (cs)
- 羅馬尼亞文 (ro)
- 匈牙利文 (hu)
- 丹麥文 (da)
- 挪威文 (no)
- 泰文 (th)
- 希伯來文 (he)
- 希臘文 (el)
- 印尼文 (id)
- 馬來文 (ms)

### 完整列表 (99 種語言)

南非荷蘭語 (Afrikaans), 阿爾巴尼亞語 (Albanian), 阿姆哈拉語 (Amharic), 阿拉伯語 (Arabic), 亞美尼亞語 (Armenian), 阿薩姆語 (Assamese), 阿塞拜疆語 (Azerbaijani), 巴什基爾語 (Bashkir), 巴斯克語 (Basque), 白俄羅斯語 (Belarusian), 孟加拉語 (Bengali), 波士尼亞語 (Bosnian), 布列塔尼語 (Breton), 保加利亞語 (Bulgarian), 緬甸語 (Burmese), 粵語 (Cantonese), 加泰羅尼亞語 (Catalan), 中文 (Chinese), 克羅埃西亞語 (Croatian), 捷克語 (Czech), 丹麥語 (Danish), 荷蘭語 (Dutch), 英語 (English), 愛沙尼亞語 (Estonian), 法羅語 (Faroese), 芬蘭語 (Finnish), 法語 (French), 加利西亞語 (Galician), 喬治亞語 (Georgian), 德語 (German), 希臘語 (Greek), 古吉拉特語 (Gujarati), 海地克里奧爾語 (Haitian Creole), 豪薩語 (Hausa), 夏威夷語 (Hawaiian), 希伯來語 (Hebrew), 印地語 (Hindi), 匈牙利語 (Hungarian), 冰島語 (Icelandic), 印尼語 (Indonesian), 義大利語 (Italian), 日語 (Japanese), 爪哇語 (Javanese), 坎那達語 (Kannada), 哈薩克語 (Kazakh), 高棉語 (Khmer), 韓語 (Korean), 寮國語 (Lao), 拉丁語 (Latin), 拉脫維亞語 (Latvian), 林加拉語 (Lingala), 立陶宛語 (Lithuanian), 盧森堡語 (Luxembourgish), 馬其頓語 (Macedonian), 馬達加斯加語 (Malagasy), 馬來語 (Malay), 馬拉雅拉姆語 (Malayalam), 馬爾他語 (Maltese), 毛利語 (Maori), 馬拉地語 (Marathi), 摩爾多瓦語 (Moldavian), 蒙古語 (Mongolian), 緬甸語 (Myanmar), 尼泊爾語 (Nepali), 挪威語 (Norwegian), 新挪威語 (Nynorsk), 奧克語 (Occitan), 普什圖語 (Pashto), 波斯語 (Persian), 波蘭語 (Polish), 葡萄牙語 (Portuguese), 旁遮普語 (Punjabi), 普什圖語 (Pushto), 羅馬尼亞語 (Romanian), 俄語 (Russian), 梵語 (Sanskrit), 塞爾維亞語 (Serbian), 修納語 (Shona), 信德語 (Sindhi), 僧伽羅語 (Sinhala), 斯洛伐克語 (Slovak), 斯洛維尼亞語 (Slovenian), 索馬利語 (Somali), 西班牙語 (Spanish), 巽他語 (Sundanese), 斯瓦希里語 (Swahili), 瑞典語 (Swedish), 塔加洛語 (Tagalog), 塔吉克語 (Tajik), 泰米爾語 (Tamil), 韃靼語 (Tatar), 泰盧固語 (Telugu), 泰語 (Thai), 藏語 (Tibetan), 土耳其語 (Turkish), 土庫曼語 (Turkmen), 烏克蘭語 (Ukrainian), 烏爾都語 (Urdu), 烏茲別克語 (Uzbek), 越南語 (Vietnamese), 威爾斯語 (Welsh), 意第緒語 (Yiddish), 約魯巴語 (Yoruba)

## 使用範例

### 自動偵測語言

```python
import whisper

model = whisper.load_model("turbo")

# 自動偵測語言
result = model.transcribe("audio.mp3")

print(f"Detected language: {result['language']}")
print(f"Text: {result['text']}")
```

### 指定語言（速度更快）

```python
# 指定語言以加速轉錄
result = model.transcribe("audio.mp3", language="es")  # 西班牙文
result = model.transcribe("audio.mp3", language="fr")  # 法文
result = model.transcribe("audio.mp3", language="ja")  # 日文
```

### 翻譯為英文

```python
# 將任何語言翻譯為英文
result = model.transcribe(
    "spanish_audio.mp3",
    task="translate"  # 翻譯為英文
)

print(f"Original language: {result['language']}")
print(f"English translation: {result['text']}")
```

## 特定語言技巧

### 中文 (Chinese)

```python
# 中文在較大的模型上表現更好
model = whisper.load_model("large")

result = model.transcribe(
    "chinese_audio.mp3",
    language="zh",
    initial_prompt="这是一段关于技术的讨论"  # 提供上下文有助於辨識
)
```

### 日文 (Japanese)

```python
# 日文受益於初始提示 (initial prompt)
result = model.transcribe(
    "japanese_audio.mp3",
    language="ja",
    initial_prompt="これは技術的な会議の録音です"
)
```

### 阿拉伯文 (Arabic)

```python
# 阿拉伯文：使用 large 模型以獲得最佳結果
model = whisper.load_model("large")

result = model.transcribe(
    "arabic_audio.mp3",
    language="ar"
)
```

## 模型大小建議

| 語言層級 | 建議模型 | WER |
|---------------|-------------------|-----|
| 頂級 (en, es, fr, de) | base/turbo | < 10% |
| 良好 (ar, tr, vi) | medium/large | 10-20% |
| 低資源語言 | large | 20-30% |

## 各語言效能

### 英文 (English)

- **tiny**: WER ~15%
- **base**: WER ~8%
- **small**: WER ~5%
- **medium**: WER ~4%
- **large**: WER ~3%
- **turbo**: WER ~3.5%

### 西班牙文 (Spanish)

- **tiny**: WER ~20%
- **base**: WER ~12%
- **medium**: WER ~6%
- **large**: WER ~4%

### 中文 (Chinese)

- **small**: WER ~15%
- **medium**: WER ~8%
- **large**: WER ~5%

## 最佳實踐

1. **使用僅限英文 (English-only) 模型** - 對於小型模型 (tiny/base) 效果更好。
2. **指定語言** - 比自動偵測更快。
3. **增加初始提示 (initial prompt)** - 改善技術術語的準確度。
4. **使用較大的模型** - 對於低資源語言。
5. **在樣本上測試** - 品質隨口音/方言而異。
6. **考慮音訊品質** - 清晰的音訊 = 更好的結果。
7. **檢查語言代碼** - 使用 ISO 639-1 代碼 (2 個字母)。

## 語言偵測

```python
# 僅偵測語言（不進行轉錄）
import whisper

model = whisper.load_model("base")

# 載入音訊
audio = whisper.load_audio("audio.mp3")
audio = whisper.pad_or_trim(audio)

# 製作 log-Mel 頻譜圖 (spectrogram)
mel = whisper.log_mel_spectrogram(audio).to(model.device)

# 偵測語言
_, probs = model.detect_language(mel)
detected_language = max(probs, key=probs.get)

print(f"Detected language: {detected_language}")
print(f"Confidence: {probs[detected_language]:.2%}")
```

## 資源

- **Paper**: https://arxiv.org/abs/2212.04356
- **GitHub**: https://github.com/openai/whisper
- **Model Card**: https://github.com/openai/whisper/blob/main/model-card.md
