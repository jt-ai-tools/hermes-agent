# 探索應用程式 (Apps)

## 列出所有應用程式

```bash
infsh app list
```

## 分頁

```bash
infsh app list --page 2
```

## 按類別篩選

```bash
infsh app list --category image
infsh app list --category video
infsh app list --category audio
infsh app list --category text
infsh app list --category other
```

## 搜尋

```bash
infsh app search "flux"
infsh app search "video generation"
infsh app search "tts" -l
infsh app search "image" --category image
```

或者使用標記形式：

```bash
infsh app list --search "flux"
infsh app list --search "video generation"
infsh app list --search "tts"
```

## 精選應用程式

```bash
infsh app list --featured
```

## 最新優先

```bash
infsh app list --new
```

## 詳細檢視

```bash
infsh app list -l
```

顯示包含應用程式名稱、類別、描述和精選狀態的表格。

## 儲存至檔案

```bash
infsh app list --save apps.json
```

## 您的應用程式

列出您已部署的應用程式：

```bash
infsh app my
infsh app my -l  # 詳細資訊
```

## 取得應用程式詳情

```bash
infsh app get falai/flux-dev-lora
infsh app get falai/flux-dev-lora --json
```

顯示完整的應用程式資訊，包括輸入/輸出架構 (Schema)。

## 各類別熱門應用程式

### 圖像生成 (Image Generation)
- `falai/flux-dev-lora` - FLUX.2 Dev (高品質)
- `falai/flux-2-klein-lora` - FLUX.2 Klein (最快)
- `infsh/sdxl` - Stable Diffusion XL
- `google/gemini-3-pro-image-preview` - Gemini 3 Pro
- `xai/grok-imagine-image` - Grok 圖像生成

### 影片生成 (Video Generation)
- `google/veo-3-1-fast` - Veo 3.1 Fast
- `google/veo-3` - Veo 3
- `bytedance/seedance-1-5-pro` - Seedance 1.5 Pro
- `infsh/ltx-video-2` - LTX Video 2 (含音訊)
- `bytedance/omnihuman-1-5` - OmniHuman 虛擬化身

### 音訊 (Audio)
- `infsh/dia-tts` - 對話式文字轉語音 (TTS)
- `infsh/kokoro-tts` - Kokoro 文字轉語音 (TTS)
- `infsh/fast-whisper-large-v3` - 快速逐字稿
- `infsh/diffrythm` - 音樂生成

## 相關文件

- [Browsing the Grid](https://inference.sh/docs/apps/browsing-grid) - 視覺化應用程式瀏覽
- [Apps Overview](https://inference.sh/docs/apps/overview) - 了解應用程式
- [Running Apps](https://inference.sh/docs/apps/running) - 如何執行應用程式
