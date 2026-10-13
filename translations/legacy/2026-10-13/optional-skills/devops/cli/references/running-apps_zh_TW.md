# 執行應用程式 (Apps)

## 基本執行

```bash
infsh app run user/app-name --input input.json
```

## 行內 JSON

```bash
infsh app run falai/flux-dev-lora --input '{"prompt": "a sunset over mountains"}'
```

## 版本鎖定

```bash
infsh app run user/app-name@1.0.0 --input input.json
```

## 本地檔案上傳

當您提供檔案路徑而非 URL 時，CLI 會自動上傳本地檔案。任何接受 URL 的欄位也接受本地路徑：

```bash
# 放大本地圖像
infsh app run falai/topaz-image-upscaler --input '{"image": "/path/to/photo.jpg", "upscale_factor": 2}'

# 從本地檔案進行圖像轉影片
infsh app run falai/wan-2-5-i2v --input '{"image": "./my-image.png", "prompt": "make it move"}'

# 使用本地音訊和圖像生成虛擬化身
infsh app run bytedance/omnihuman-1-5 --input '{"audio": "/path/to/speech.mp3", "image": "/path/to/face.jpg"}'

# 發布帶有本地媒體的推文
infsh app run x/post-create --input '{"text": "Check this out!", "media": "./screenshot.png"}'
```

支援的路徑：
- 絕對路徑：`/home/user/images/photo.jpg`
- 相對路徑：`./image.png`, `../data/video.mp4`
- 家目錄：`~/Pictures/photo.jpg`

## 生成範例輸入

在執行之前，先生成一個範例輸入檔案：

```bash
infsh app sample falai/flux-dev-lora
```

儲存至檔案：

```bash
infsh app sample falai/flux-dev-lora --save input.json
```

接著編輯 `input.json` 並執行：

```bash
infsh app run falai/flux-dev-lora --input input.json
```

## 工作流程範例

### 使用 FLUX 進行圖像生成

```bash
# 1. 取得應用程式詳情
infsh app get falai/flux-dev-lora

# 2. 生成範例輸入
infsh app sample falai/flux-dev-lora --save input.json

# 3. 編輯 input.json
# {
#   "prompt": "a cat astronaut floating in space",
#   "num_images": 1,
#   "image_size": "landscape_16_9"
# }

# 4. 執行
infsh app run falai/flux-dev-lora --input input.json
```

### 使用 Veo 進行影片生成

```bash
# 1. 生成範例
infsh app sample google/veo-3-1-fast --save input.json

# 2. 編輯提示詞 (prompt)
# {
#   "prompt": "A drone shot flying over a forest at sunset"
# }

# 3. 執行
infsh app run google/veo-3-1-fast --input input.json
```

### 文字轉語音 (Text-to-Speech)

```bash
# 快速行內執行
infsh app run falai/kokoro-tts --input '{"text": "Hello, this is a test."}'
```

## 任務追蹤

當您執行應用程式時，CLI 會顯示任務 ID：

```
Running falai/flux-dev-lora
Task ID: abc123def456
```

對於執行時間較長的任務，您可以隨時檢查狀態：

```bash
# 檢查任務狀態
infsh task get abc123def456

# 以 JSON 格式取得結果
infsh task get abc123def456 --json

# 將結果儲存至檔案
infsh task get abc123def456 --save result.json
```

### 執行而不等待

對於非常耗時的任務，可以在背景執行：

```bash
# 提交並立即返回
infsh app run google/veo-3 --input input.json --no-wait

# 稍後檢查
infsh task get <task-id>
```

## 輸出

CLI 會直接返回應用程式的輸出。對於檔案輸出（圖像、影片、音訊），您將收到可供下載的 URL。

範例輸出：

```json
{
  "images": [
    {
      "url": "https://cloud.inference.sh/...",
      "content_type": "image/png"
    }
  ]
}
```

## 錯誤處理

| 錯誤 | 原因 | 解決方案 |
|-------|-------|----------|
| "invalid input" (輸入無效) | 架構不匹配 | 使用 `infsh app get` 檢查必要欄位 |
| "app not found" (找不到應用程式) | 應用程式名稱錯誤 | 使用 `infsh app list --search` 檢查 |
| "quota exceeded" (配額不足) | 額度已用盡 | 檢查帳戶餘額 |

## 相關文件

- [Running Apps](https://inference.sh/docs/apps/running) - 完整的執行應用程式指南
- [Streaming Results](https://inference.sh/docs/api/sdk/streaming) - 即時進度更新
- [Setup Parameters](https://inference.sh/docs/apps/setup-parameters) - 配置應用程式輸入
