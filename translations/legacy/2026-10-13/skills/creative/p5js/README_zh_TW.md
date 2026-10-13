# p5.js 技能 (p5.js Skill)

使用 [p5.js](https://p5js.org/) 的互動式與生成式視覺藝術生產流程。

## 它的用途

根據文字提示詞建立基於瀏覽器的視覺藝術。代理程式處理完整的流水線：創意概念、程式碼生成、預覽、匯出以及迭代精進。輸出是一個單一且自包含的 HTML 檔案，可在任何瀏覽器中執行 —— 無需建構步驟、無需伺服器，除了 CDN 指令碼標籤外無任何依賴。

輸出的成果是真實的互動藝術，而非教學練習。這包含生成系統、粒子物理、雜訊場、著色器效果、動態排版 —— 並結合了刻意設計的調色盤、分層構圖以及視覺階層。

## 模式

| 模式 | 輸入 | 輸出 |
|------|-------|--------|
| **生成藝術** | 種子 / 參數 | 程序化視覺構圖 |
| **數據視覺化** | 資料集 / API | 互動式圖表、自定義數據顯示 |
| **互動體驗** | 無（使用者驅動） | 滑鼠/鍵盤/觸控驅動的草圖 |
| **動畫 / 動態圖形** | 時間軸 / 分鏡 | 定時序列、動態排版 |
| **3D 場景** | 概念描述 | WebGL 幾何體、燈光、著色器 |
| **影像處理** | 影像檔案 | 像素操作、濾鏡、點彩畫 |
| **音訊反應式** | 音訊檔案 / 麥克風 | 聲音驅動的生成視覺效果 |

## 匯出格式

| 格式 | 方法 |
|--------|--------|
| **HTML** | 自包含檔案，可在任何瀏覽器開啟 |
| **PNG** | `saveCanvas()` —— 按下 's' 鍵捕捉 |
| **GIF** | `saveGif()` —— 按下 'g' 鍵捕捉 |
| **MP4** | 影格序列 + 透過 `scripts/render.sh` 調用 ffmpeg |
| **SVG** | 使用 p5.js-svg 渲染器輸出向量圖 |

## 前置條件

一個現代瀏覽器。基礎使用僅需如此。

若要進行無頭匯出，則需安裝：Node.js、Puppeteer、ffmpeg。

```bash
bash skills/creative/p5js/scripts/setup.sh
```

## 檔案結構

```
├── SKILL_zh_TW.md                # 模式、工作流、創意指導、關鍵注意事項
├── README_zh_TW.md               # 本檔案
├── references/
│   ├── core-api_zh_TW.md          # 畫布、繪圖迴圈、變換、離屏緩衝區、數學
│   ├── shapes-and-geometry_zh_TW.md # 原語、頂點、曲線、向量、SDFs、剪裁
│   ├── visual-effects_zh_TW.md     # 雜訊、流場、粒子、像素、紋理、回饋
│   ├── animation_zh_TW.md          # 緩動、彈簧、狀態機、時間軸、轉場
│   ├── typography_zh_TW.md         # 字體、textToPoints、動態文字、文字遮罩
│   ├── color-systems_zh_TW.md      # HSB/RGB、調色盤、漸層、混合模式、精選色彩
│   ├── webgl-and-3d_zh_TW.md       # 3D 原語、攝影機、燈光、著色器、幀緩衝區
│   ├── interaction_zh_TW.md        # 滑鼠、鍵盤、觸控、DOM、音訊、捲動
│   ├── export-pipeline_zh_TW.md    # PNG、GIF、MP4、SVG、無頭、平鋪、批量匯出
│   └── troubleshooting_zh_TW.md    # 效能、常見錯誤、瀏覽器問題、偵錯
└── scripts/
    ├── setup.sh                 # 依賴驗證
    ├── serve.sh                 # 本地開發伺服器（用於載入本地資源）
    ├── render.sh                # 無頭渲染流水線 (HTML → 影格 → MP4)
    └── export-frames.js         # Puppeteer 影格捕捉 (Node.js)
```
