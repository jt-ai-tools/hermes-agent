---
name: songsee
description: 透過 CLI 從音訊檔案生成頻譜圖和音訊特徵視覺化（梅爾頻率、色譜、MFCC、節奏圖等）。可用於音訊分析、音樂製作除錯和視覺化文件。
version: 1.0.0
author: community
license: MIT
metadata:
  hermes:
    tags: [Audio, Visualization, Spectrogram, Music, Analysis]
    homepage: https://github.com/steipete/songsee
prerequisites:
  commands: [songsee]
---

# songsee

從音訊檔案生成頻譜圖和多面板音訊特徵視覺化。

## 前置作業

需要安裝 [Go](https://go.dev/doc/install)：
```bash
go install github.com/steipete/songsee/cmd/songsee@latest
```

選配：`ffmpeg` 用於處理 WAV/MP3 以外的格式。

## 快速開始

```bash
# 基本頻譜圖
songsee track.mp3

# 儲存至特定檔案
songsee track.mp3 -o spectrogram.png

# 多面板視覺化網格
songsee track.mp3 --viz spectrogram,mel,chroma,hpss,selfsim,loudness,tempogram,mfcc,flux

# 時間切片（從 12.5s 開始，持續 8s）
songsee track.mp3 --start 12.5 --duration 8 -o slice.jpg

# 從 stdin 輸入
cat track.mp3 | songsee - --format png -o out.png
```

## 視覺化類型

使用 `--viz` 並配合逗號分隔的值：

| 類型 | 說明 |
|------|-------------|
| `spectrogram` | 標準頻率頻譜圖 |
| `mel` | 梅爾比例頻譜圖 |
| `chroma` | 音高類別分佈 (Pitch class distribution) |
| `hpss` | 和聲/打擊樂分離 (Harmonic/percussive separation) |
| `selfsim` | 自相似矩陣 (Self-similarity matrix) |
| `loudness` | 隨時間變化的響度 |
| `tempogram` | 節奏估計 |
| `mfcc` | 梅爾頻率倒譜係數 (Mel-frequency cepstral coefficients) |
| `flux` | 頻譜通量 (Spectral flux，用於起始點偵測) |

多個 `--viz` 類型會以網格形式渲染在單張圖片中。

## 常見旗標 (Flags)

| 旗標 | 說明 |
|------|-------------|
| `--viz` | 視覺化類型（逗號分隔） |
| `--style` | 調色盤：`classic`、`magma`、`inferno`、`viridis`、`gray` |
| `--width` / `--height` | 輸出圖片尺寸 |
| `--window` / `--hop` | FFT 窗口與跳躍大小 |
| `--min-freq` / `--max-freq` | 頻率範圍過濾 |
| `--start` / `--duration` | 音訊的時間切片 |
| `--format` | 輸出格式：`jpg` 或 `png` |
| `-o` | 輸出檔案路徑 |

## 備註

- 原生支援解碼 WAV 和 MP3；其他格式需要 `ffmpeg`
- 輸出圖片可以使用 `vision_analyze` 進行自動化音訊分析
- 可用於比較音訊輸出、除錯合成過程或記錄音訊處理流水線 (pipelines)
