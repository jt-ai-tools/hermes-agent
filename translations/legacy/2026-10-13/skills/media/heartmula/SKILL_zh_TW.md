---
name: heartmula
description: 設定並執行 HeartMuLa，這是一個開源音樂生成模型系列（類似 Suno）。支援多語言，可從歌詞和標籤 (tags) 生成完整歌曲。
version: 1.0.0
metadata:
  hermes:
    tags: [music, audio, generation, ai, heartmula, heartcodec, lyrics, songs]
    related_skills: [audiocraft]
---

# HeartMuLa - 開源音樂生成

## 概述
HeartMuLa 是一個開源音樂基礎模型系列 (Apache-2.0)，可根據歌詞和標籤生成音樂。在開源領域可與 Suno 媲美。包含：
- **HeartMuLa** - 音韻語言模型 (3B/7B)，用於從歌詞 + 標籤生成音樂
- **HeartCodec** - 12.5Hz 音樂編解碼器，用於高保真音訊重建
- **HeartTranscriptor** - 基於 Whisper 的歌詞轉錄
- **HeartCLAP** - 音訊-文本對齊模型

## 使用時機
- 使用者想要從文字描述生成音樂/歌曲
- 使用者想要一個開源的 Suno 替代方案
- 使用者想要在本機/離線進行音樂生成
- 使用者詢問關於 HeartMuLa、heartlib 或 AI 音樂生成的相關問題

## 硬體需求
- **最低需求**：8GB VRAM 並使用 `--lazy_load true`（依序載入/解除載入模型）
- **建議需求**：16GB+ VRAM 以獲得舒適的單 GPU 使用體驗
- **多 GPU**：使用 `--mula_device cuda:0 --codec_device cuda:1` 將模型分散到不同的 GPU
- 使用 lazy_load 的 3B 模型峰值 VRAM 約為 6.2GB

## 安裝步驟

### 1. 複製儲存庫
```bash
cd ~/  # 或您想要的目錄
git clone https://github.com/HeartMuLa/heartlib.git
cd heartlib
```

### 2. 建立虛擬環境（需要 Python 3.10）
```bash
uv venv --python 3.10 .venv
. .venv/bin/activate
uv pip install -e .
```

### 3. 修復依賴套件衝突問題

**重要**：截至 2026 年 2 月，固定的依賴套件與較新的套件存在衝突。請套用以下修復：

```bash
# 升級 datasets（舊版本與目前的 pyarrow 不相容）
uv pip install --upgrade datasets

# 升級 transformers（huggingface-hub 1.x 相容性所需）
uv pip install --upgrade transformers
```

### 4. 修補原始碼（transformers 5.x 所需）

**修補 1 - RoPE 快取修復**，位於 `src/heartlib/heartmula/modeling_heartmula.py`：

在 `HeartMuLa` 類別的 `setup_caches` 方法中，在 `reset_caches` 的 try/except 區塊之後、`with device:` 區塊之前，新增 RoPE 重新初始化代碼：

```python
# 重新初始化在 meta-device 載入期間跳過的 RoPE 快取
from torchtune.models.llama3_1._position_embeddings import Llama3ScaledRoPE
for module in self.modules():
    if isinstance(module, Llama3ScaledRoPE) and not module.is_cache_built:
        module.rope_init()
        module.to(device)
```

**原因**：`from_pretrained` 會先在 meta 裝置上建立模型；`Llama3ScaledRoPE.rope_init()` 會跳過在 meta 張量上的快取建立，且在權重載入到真實裝置後永遠不會重建。

**修補 2 - HeartCodec 載入修復**，位於 `src/heartlib/pipelines/music_generation.py`：

在所有 `HeartCodec.from_pretrained()` 呼叫中新增 `ignore_mismatched_sizes=True`（共有 2 處：`__init__` 中的預先載入和 `codec` 屬性中的延遲載入）。

**原因**：VQ codebook `initted` 緩衝區在 checkpoint 中的形狀為 `[1]`，而在模型中為 `[]`。兩者數據相同，僅為純量 (scalar) 與 0-d 張量的區別。可以安全忽略。

### 5. 下載模型 Checkpoints
```bash
cd heartlib  # 專案根目錄
hf download --local-dir './ckpt' 'HeartMuLa/HeartMuLaGen'
hf download --local-dir './ckpt/HeartMuLa-oss-3B' 'HeartMuLa/HeartMuLa-oss-3B-happy-new-year'
hf download --local-dir './ckpt/HeartCodec-oss' 'HeartMuLa/HeartCodec-oss-20260123'
```

這三個可以並行下載。總大小為數 GB。

## GPU / CUDA

HeartMuLa 預設使用 CUDA (`--mula_device cuda --codec_device cuda`)。如果使用者已安裝支援 CUDA 的 NVIDIA GPU 和 PyTorch，則無需額外設定。

- 安裝的 `torch==2.4.1` 內建支援 CUDA 12.1
- `torchtune` 可能會顯示版本為 `0.4.0+cpu` — 這只是套件中繼資料，它仍然透過 PyTorch 使用 CUDA
- 若要確認是否使用了 GPU，請在輸出中尋找 "CUDA memory" 相關行（例如 "CUDA memory before unloading: 6.20 GB"）
- **沒有 GPU？** 您可以使用 `--mula_device cpu --codec_device cpu` 在 CPU 上執行，但預期生成速度會**極其緩慢**（單首歌曲可能需要 30-60 分鐘以上，而 GPU 僅需約 4 分鐘）。CPU 模式還需要大量記憶體（約 12GB+ 剩餘空間）。如果使用者沒有 NVIDIA GPU，建議使用雲端 GPU 服務（Google Colab 免費層 T4、Lambda Labs 等）或使用 https://heartmula.github.io/ 上的線上展示。

## 使用方法

### 基本生成
```bash
cd heartlib
. .venv/bin/activate
python ./examples/run_music_generation.py \
  --model_path=./ckpt \
  --version="3B" \
  --lyrics="./assets/lyrics.txt" \
  --tags="./assets/tags.txt" \
  --save_path="./assets/output.mp3" \
  --lazy_load true
```

### 輸入格式

**標籤 (Tags)**（以逗號分隔，不含空格）：
```
piano,happy,wedding,synthesizer,romantic
```
或
```
rock,energetic,guitar,drums,male-vocal
```

**歌詞 (Lyrics)**（使用方括號標記結構標籤）：
```
[Intro]

[Verse]
在此輸入您的歌詞...

[Chorus]
副歌歌詞...

[Bridge]
過渡段歌詞...

[Outro]
```

### 關鍵參數
| 參數 | 預設值 | 說明 |
|-----------|---------|-------------|
| `--max_audio_length_ms` | 240000 | 最大長度，單位為毫秒 (240s = 4 分鐘) |
| `--topk` | 50 | Top-k 取樣 |
| `--temperature` | 1.0 | 取樣溫度 |
| `--cfg_scale` | 1.5 | Classifier-free guidance 比例 |
| `--lazy_load` | false | 按需載入/解除載入模型（節省 VRAM） |
| `--mula_dtype` | bfloat16 | HeartMuLa 的數據類型（建議使用 bf16） |
| `--codec_dtype` | float32 | HeartCodec 的數據類型（建議使用 fp32 以確保品質） |

### 效能
- RTF (Real-Time Factor) ≈ 1.0 — 生成一首 4 分鐘的歌曲約需 4 分鐘
- 輸出格式：MP3, 48kHz stereo, 128kbps

## 常見陷阱
1. **請勿在 HeartCodec 使用 bf16** — 這會降低音訊品質。請使用 fp32（預設值）。
2. **標籤可能會被忽略** — 已知問題 (#90)。歌詞往往佔主導地位；請嘗試調整標籤順序。
3. **macOS 不支援 Triton** — 僅限 Linux/CUDA 支援 GPU 加速。
4. **RTX 5080 不相容**（根據上游回報）。
5. 依賴套件版本衝突需要執行上述的手動升級和修補。

## 相關連結
- 儲存庫：https://github.com/HeartMuLa/heartlib
- 模型：https://huggingface.co/HeartMuLa
- 論文：https://arxiv.org/abs/2601.10547
- 授權：Apache-2.0
