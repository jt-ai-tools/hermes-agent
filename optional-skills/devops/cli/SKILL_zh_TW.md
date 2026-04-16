---
name: inference-sh-cli
description: "透過 inference.sh CLI (infsh) 執行 150+ 個 AI 應用程式 — 包含圖片生成、影片建立、LLM、搜尋、3D、社交自動化。使用 terminal 工具。觸發詞：inference.sh, infsh, ai apps, flux, veo, image generation, video generation, seedream, seedance, tavily"
version: 1.0.0
author: okaris
license: MIT
metadata:
  hermes:
    tags: [AI, 圖片生成, 影片, LLM, 搜尋, 推論, FLUX, Veo, Claude]
    related_skills: []
---

# inference.sh CLI

透過簡單的 CLI 在雲端執行 150+ 個 AI 應用程式。不需要 GPU。

所有命令皆使用 **terminal 工具** 來執行 `infsh` 命令。

## 何時使用

- 使用者要求生成圖片 (FLUX, Reve, Seedream, Grok, Gemini image)
- 使用者要求生成影片 (Veo, Wan, Seedance, OmniHuman)
- 使用者詢問關於 inference.sh 或 infsh 的資訊
- 使用者想要執行 AI 應用程式，但不希望管理各個供應商的 API
- 使用者要求 AI 驅動的搜尋 (Tavily, Exa)
- 使用者需要生成虛擬化身 (avatar) 或對嘴 (lipsync) 影片

## 先決條件

必須已安裝 `infsh` CLI 並完成驗證。請使用以下命令檢查：

```bash
infsh me
```

若未安裝：

```bash
curl -fsSL https://cli.inference.sh | sh
infsh login
```

完整設定細節請參閱 `references/authentication.md`。

## 工作流程

### 1. 務必先搜尋

切勿猜測應用程式名稱 — 務必先搜尋以找到正確的 App ID：

```bash
infsh app list --search flux
infsh app list --search video
infsh app list --search image
```

### 2. 執行應用程式

使用搜尋結果中確切的 App ID。務必使用 `--json` 以獲得機器可讀的輸出：

```bash
infsh app run <app-id> --input '{"prompt": "在此輸入提示詞"}' --json
```

### 3. 解析輸出

JSON 輸出包含生成的媒體 URL。使用 `MEDIA:<url>` 將其呈現給使用者以進行行內顯示。

## 常見命令

### 圖片生成

```bash
# 搜尋圖片相關應用程式
infsh app list --search image

# 使用 LoRA 的 FLUX Dev
infsh app run falai/flux-dev-lora --input '{"prompt": "山上的日落", "num_images": 1}' --json

# Gemini 圖片生成
infsh app run google/gemini-2-5-flash-image --input '{"prompt": "未來的城市", "num_images": 1}' --json

# Seedream (字節跳動)
infsh app run bytedance/seedream-5-lite --input '{"prompt": "自然場景"}' --json

# Grok Imagine (xAI)
infsh app run xai/grok-imagine-image --input '{"prompt": "抽象藝術"}' --json
```

### 影片生成

```bash
# 搜尋影片相關應用程式
infsh app list --search video

# Veo 3.1 (Google)
infsh app run google/veo-3-1-fast --input '{"prompt": "海岸線的空拍鏡頭"}' --json

# Seedance (字節跳動)
infsh app run bytedance/seedance-1-5-pro --input '{"prompt": "跳舞的人物", "resolution": "1080p"}' --json

# Wan 2.5
infsh app run falai/wan-2-5 --input '{"prompt": "穿過城市的人"}' --json
```

### 上傳本地檔案

當你提供路徑時，CLI 會自動上傳本地檔案：

```bash
# 放大本地圖片
infsh app run falai/topaz-image-upscaler --input '{"image": "/path/to/photo.jpg", "upscale_factor": 2}' --json

# 從本地檔案進行圖片轉影片
infsh app run falai/wan-2-5-i2v --input '{"image": "/path/to/image.png", "prompt": "讓它動起來"}' --json

# 結合音訊的虛擬化身
infsh app run bytedance/omnihuman-1-5 --input '{"audio": "/path/to/audio.mp3", "image": "/path/to/face.jpg"}' --json
```

### 搜尋與研究

```bash
infsh app list --search search
infsh app run tavily/tavily-search --input '{"query": "最新 AI 新聞"}' --json
infsh app run exa/exa-search --input '{"query": "機器學習論文"}' --json
```

### 其他類別

```bash
# 3D 生成
infsh app list --search 3d

# 音訊 / 文字轉語音 (TTS)
infsh app list --search tts

# Twitter/X 自動化
infsh app list --search twitter
```

## 注意事項 (Pitfalls)

1. **切勿猜測 App ID** — 務必先執行 `infsh app list --search <關鍵字>`。App ID 會變動，且會頻繁加入新應用程式。
2. **務必使用 `--json`** — 原始輸出難以解析。`--json` 旗標提供包含 URL 的結構化輸出。
3. **檢查驗證狀態** — 若命令因驗證錯誤而失敗，請執行 `infsh login` 或確認已設定 `INFSH_API_KEY`。
4. **長時間執行的應用程式** — 影片生成可能需要 30-120 秒。Terminal 工具的超時設定應該足夠，但請提醒使用者這可能需要一些時間。
5. **輸入格式** — `--input` 旗標接收 JSON 字串。請確保正確處理引號轉義。

## 參考文件

- `references/authentication.md` — 設定、登入、API 金鑰
- `references/app-discovery.md` — 搜尋與瀏覽應用程式目錄
- `references/running-apps.md` — 執行應用程式、輸入格式、輸出處理
- `references/cli-reference.md` — 完整的 CLI 命令參考
