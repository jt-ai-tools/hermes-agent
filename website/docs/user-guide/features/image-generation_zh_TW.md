---
title: 圖片生成 (Image Generation)
description: 使用 FLUX 2 Pro 生成高品質圖片，並透過 FAL.ai 自動進行放大。
sidebar_label: 圖片生成
sidebar_position: 6
---

# 圖片生成 (Image Generation)

Hermes Agent 可以使用 FAL.ai 的 **FLUX 2 Pro** 模型根據文字提示詞生成圖片，並透過 **Clarity 放大器 (Clarity Upscaler)** 自動進行 2 倍放大以增強畫質。

## 設定

### 獲取 FAL API 金鑰

1. 在 [fal.ai](https://fal.ai/) 註冊帳號。
2. 從您的控制面板 (dashboard) 生成一個 API 金鑰。

### 配置金鑰

```bash
# 新增至 ~/.hermes/.env
FAL_KEY=您的-fal-api-key-在此
```

### 安裝用戶端函式庫

```bash
pip install fal-client
```

:::info
只要設置了 `FAL_KEY`，圖片生成工具就會自動可用。不需要額外的工具集 (toolset) 配置。
:::

## 運作原理

當您要求 Hermes 生成圖片時：

1. **生成** — 您的提示詞會被發送到 FLUX 2 Pro 模型 (`fal-ai/flux-2-pro`)。
2. **放大** — 生成的圖片會自動使用 Clarity 放大器 (`fal-ai/clarity-upscaler`) 進行 2 倍放大。
3. **交付** — 回傳放大後的圖片 URL。

如果放大因任何原因失敗，則會回傳原始圖片作為備援。

## 使用方式

只需直接要求 Hermes 建立圖片即可：

```text
幫我生成一張帶有櫻花的寧靜山景圖
```

```text
幫我畫一張智慧老鷹棲息在古老樹枝上的肖像
```

```text
幫我製作一張帶有飛行車和霓虹燈的未來感城市景觀
```

## 參數

`image_generate_tool` 接受以下參數：

| 參數 | 預設值 | 範圍 | 說明 |
|-----------|---------|-------|-------------|
| `prompt` | *(必填)* | — | 所需圖片的文字描述 |
| `aspect_ratio` | `"landscape"` | `landscape`, `square`, `portrait` | 圖片長寬比 |
| `num_inference_steps` | `50` | 1–100 | 去噪步數（越多則畫質越高，但速度較慢） |
| `guidance_scale` | `4.5` | 0.1–20.0 | 遵循提示詞的緊密程度 |
| `num_images` | `1` | 1–4 | 要生成的圖片數量 |
| `output_format` | `"png"` | `png`, `jpeg` | 圖片檔案格式 |
| `seed` | *(隨機)* | 任何整數 | 用於重現結果的隨機種子 |

## 長寬比 (Aspect Ratios)

該工具使用簡化的長寬比名稱，對應到 FLUX 2 Pro 的圖片尺寸：

| 長寬比 | 對應至 | 適用場景 |
|-------------|---------|----------|
| `landscape` | `landscape_16_9` | 桌布、橫幅、場景 |
| `square` | `square_hd` | 頭像、社群媒體貼文 |
| `portrait` | `portrait_16_9` | 角色藝術、手機桌布 |

:::tip
您也可以直接使用原始的 FLUX 2 Pro 尺寸預設值：`square_hd`、`square`、`portrait_4_3`、`portrait_16_9`、`landscape_4_3`、`landscape_16_9`。同時也支援最高達 2048x2048 的自定義尺寸。
:::

## 自動放大 (Automatic Upscaling)

每張生成的圖片都會使用 FAL.ai 的 Clarity 放大器根據以下設置自動進行 2 倍放大：

| 設置 | 值 |
|---------|-------|
| 放大倍率 (Upscale Factor) | 2x |
| 創意度 (Creativity) | 0.35 |
| 相似度 (Resemblance) | 0.6 |
| 引導比例 (Guidance Scale) | 4 |
| 推理步數 (Inference Steps) | 18 |
| 正向提示詞 (Positive Prompt) | `"masterpiece, best quality, highres"` + 您的原始提示詞 |
| 負向提示詞 (Negative Prompt) | `"(worst quality, low quality, normal quality:2)"` |

放大器在保持原始構圖的同時，增強細節和解析度。如果放大器失敗（網路問題、速率限制），系統會自動回傳原始解析度的圖片。

## 提示詞範例

這裡有一些可以嘗試的有效提示詞：

```text
一張留著粉紅色短髮、畫著大膽眼線的女性街頭寫實照片
```

```text
具有玻璃外牆的現代建築，夕陽光影
```

```text
色彩鮮豔、帶有幾何圖案的抽象藝術
```

```text
智慧老鷹棲息在古老樹枝上的肖像
```

```text
帶有飛行車和霓虹燈的未來感城市景觀
```

## 除錯 (Debugging)

為圖片生成啟用除錯日誌：

```bash
export IMAGE_TOOLS_DEBUG=true
```

除錯日誌會儲存在 `./logs/image_tools_debug_<session_id>.json` 中，包含每個生成請求的詳細資訊、參數、計時以及任何錯誤。

## 安全性設置

圖片生成工具在預設情況下會禁用安全性檢查（`safety_tolerance: 5`，最寬鬆的設置）。這是在程式碼層級配置的，使用者無法自行調整。

## 平台交付

生成的圖片會根據平台的不同以不同方式交付：

| 平台 | 交付方式 |
|----------|----------------|
| **CLI** | 圖片 URL 以 Markdown 格式印出 `![說明](url)` — 點擊即可在瀏覽器中開啟 |
| **Telegram** | 圖片作為照片訊息發送，並以提示詞作為標題 |
| **Discord** | 圖片嵌入在訊息中 |
| **Slack** | 訊息中的圖片 URL（Slack 會自動展開圖卡） |
| **WhatsApp** | 圖片作為媒體訊息發送 |
| **其他平台** | 以純文字顯示圖片 URL |

代理程式在回應中使用 `MEDIA:<url>` 語法，平台適配器 (platform adapter) 會將其轉換為相應的格式。

## 限制

- **需要 FAL API 金鑰** — 圖片生成會在您的 FAL.ai 帳號中產生 API 費用。
- **無圖片編輯功能** — 僅限文字生圖，不支援局部重繪 (inpainting) 或圖生圖 (img2img)。
- **基於 URL 的交付** — 圖片以 FAL.ai 的臨時 URL 回傳，不會儲存在本地。URL 在一段時間（通常是數小時）後會過期。
- **放大會增加延遲** — 自動 2 倍放大步驟會增加處理時間。
- **每次請求最多 4 張圖片** — `num_images` 的上限為 4。
