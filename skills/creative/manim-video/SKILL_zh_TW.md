---
name: manim-video
description: "使用 Manim 社群版製作數學與技術動畫的生產流程。創建 3Blue1Brown 風格的解釋影片、演算法視覺化、公式推導、架構圖和數據故事。適用於使用者要求：動畫解釋、數學動畫、概念視覺化、演算法演示、技術說明、3Blue1Brown 風格影片，或任何具有幾何/數學內容的程式化動畫。"
version: 1.0.0
---

# Manim 影片製作流程

## 創意標準

這是教育電影。每一幀都在教學，每一段動畫都在揭示結構。

**在編寫任何一行程式碼之前**，請先構思敘事主軸。這段影片要糾正什麼誤解？「恍然大悟的瞬間 (aha moment)」在哪裡？什麼樣的視覺故事能引導觀眾從困惑走向理解？使用者的提示詞只是起點 —— 請以教學雄心來詮釋它。

**幾何先於代數。** 先展示形狀，再展示公式。視覺記憶的編碼速度比符號記憶快。當觀眾在看到公式前先理解了幾何模式，公式就會顯得理所當然。

**首繪即卓越是不可妥協的要求。** 輸出結果必須在不經過多輪修改的情況下，保持視覺清晰且美學統一。如果看起來雜亂、時機不當，或者像「AI 生成的投影片」，那就是錯誤的。

**不透明度分層引導注意力。** 永遠不要以全亮度顯示所有內容。主要元素設為 1.0，背景元素為 0.4，結構元素（坐標軸、網格）為 0.15。大腦會按層次處理視覺顯著性。

**呼吸空間。** 每段動畫之後都需要 `self.wait()`。觀眾需要時間吸收剛剛出現的內容。永遠不要匆忙地從一個動畫跳到下一個。在關鍵揭示後停頓 2 秒絕對不是浪費。

**統一的視覺語言。** 所有場景共享配色方案、一致的字體大小以及匹配的動畫速度。一個技術上正確但每個場景都使用隨機顏色的影片在美學上是失敗的。

## 前置要求

運行 `scripts/setup.sh` 來驗證所有依賴項。需要：Python 3.10+、Manim 社群版 v0.20+ (`pip install manim`)、LaTeX（Linux 上為 `texlive-full`，macOS 上為 `mactex`）以及 ffmpeg。參考文件已針對 Manim CE v0.20.1 進行測試。

## 模式

| 模式 | 輸入 | 輸出 | 參考文件 |
|------|-------|--------|-----------|
| **概念解釋** | 主題/概念 | 帶有幾何直覺的動畫解釋 | `references/scene-planning.md` |
| **公式推導** | 數學表達式 | 逐步動畫證明 | `references/equations.md` |
| **演算法視覺化** | 演算法描述 | 帶有數據結構的逐步執行過程 | `references/graphs-and-data_zh_TW.md` |
| **數據故事** | 數據/指標 | 動畫圖表、對比、計數器 | `references/graphs-and-data_zh_TW.md` |
| **架構圖** | 系統描述 | 組件及其連接的構建過程 | `references/mobjects.md` |
| **論文解釋** | 研究論文 | 動畫展示關鍵發現和方法 | `references/scene-planning.md` |
| **3D 視覺化** | 3D 概念 | 旋轉曲面、參數曲線、空間幾何 | `references/camera-and-3d.md` |

## 技術堆疊

每個專案單個 Python 腳本。不需要瀏覽器、Node.js 或 GPU。

| 層級 | 工具 | 用途 |
|-------|------|---------|
| 核心 | Manim 社群版 | 場景渲染、動畫引擎 |
| 數學 | LaTeX (texlive/MiKTeX) | 通過 `MathTex` 渲染公式 |
| 影片 I/O | ffmpeg | 場景拼接、格式轉換、音訊合成 |
| TTS | ElevenLabs / Qwen3-TTS (選填) | 旁白配音 |

## 流程

```
規劃 (PLAN) --> 編碼 (CODE) --> 渲染 (RENDER) --> 拼接 (STITCH) --> 音訊 (選填) --> 審核 (REVIEW)
```

1. **規劃 (PLAN)** — 編寫 `plan.md`，包含敘事主軸、場景列表、視覺元素、配色方案、旁白腳本
2. **編碼 (CODE)** — 編寫 `script.py`，每個場景一個類別 (class)，每個場景皆可獨立渲染
3. **渲染 (RENDER)** — 初稿使用 `manim -ql script.py Scene1 Scene2 ...`，正式輸出使用 `-qh`
4. **拼接 (STITCH)** — 使用 ffmpeg 將場景片段合併為 `final.mp4`
5. **音訊 (AUDIO)** (選填) — 通過 ffmpeg 添加旁白和/或背景音樂。參見 `references/rendering.md`
6. **審核 (REVIEW)** — 渲染預覽圖，對照計劃進行驗證並調整

## 專案結構

```
project-name/
  plan.md                # 敘事主軸、場景分解
  script.py              # 所有場景在同一個檔案中
  concat.txt             # ffmpeg 場景列表
  final.mp4              # 拼接後的輸出
  media/                 # 由 Manim 自動生成
    videos/script/480p15/
```

## 創意方向

### 配色方案 (Color Palettes)

| 方案 | 背景 | 主色 | 次色 | 強調色 | 適用場景 |
|---------|-----------|---------|-----------|--------|----------|
| **經典 3B1B** | `#1C1C1C` | `#58C4DD` (藍) | `#83C167` (綠) | `#FFFF00` (黃) | 通用數學/資訊科學 |
| **暖色學術** | `#2D2B55` | `#FF6B6B` | `#FFD93D` | `#6BCB77` | 親切感 |
| **霓虹科技** | `#0A0A0A` | `#00F5FF` | `#FF00FF` | `#39FF14` | 系統、架構 |
| **單色簡約** | `#1A1A2E` | `#EAEAEA` | `#888888` | `#FFFFFF` | 極簡主義 |

### 動畫速度

| 上下文 | run_time | 之後的 self.wait() |
|---------|----------|-------------------|
| 標題/引言出現 | 1.5s | 1.0s |
| 關鍵公式揭示 | 2.0s | 2.0s |
| 轉換/變形 (Transform/morph) | 1.5s | 1.5s |
| 輔助標籤 | 0.8s | 0.5s |
| FadeOut 清理 | 0.5s | 0.3s |
| 「恍然大悟」揭示 | 2.5s | 3.0s |

### 排版比例 (Typography Scale)

| 角色 | 字體大小 | 用法 |
|------|-----------|-------|
| 標題 | 48 | 場景標題、開場文字 |
| 副標題 | 36 | 場景內的區段標題 |
| 正文 | 30 | 解釋性文字 |
| 標籤 | 24 | 註釋、軸標籤 |
| 說明 | 20 | 字幕、細則文字 |

### 字體

**所有文字請使用等寬字體 (monospace)。** Manim 的 Pango 渲染器在所有尺寸下處理比例字體時都會產生不正確的字距。參見 `references/visual-design.md` 獲取完整建議。

```python
MONO = "Menlo"  # 在檔案頂部定義一次

Text("Fourier Series", font_size=48, font=MONO, weight=BOLD)  # 標題
Text("n=1: sin(x)", font_size=20, font=MONO)                  # 標籤
MathTex(r"\nabla L")                                            # 數學 (使用 LaTeX)
```

最低可讀字體大小為 `font_size=18`。

### 場景差異化

永遠不要為所有場景使用相同的配置。對於每個場景：
- 從配色方案中選擇**不同的主導顏色**
- 使用**不同的佈局** —— 不要總是把所有內容居中
- 使用**不同的動畫進入方式** —— 在 Write, FadeIn, GrowFromCenter, Create 之間切換
- 使用**不同的視覺權重** —— 有些場景密集，有些則留白

## 工作流程

### 步驟 1：規劃 (plan.md)

在編寫任何程式碼之前，先寫好 `plan.md`。參見 `references/scene-planning.md` 獲取完整的模板。

### 步驟 2：編碼 (script.py)

每個場景一個類別。每個場景皆可獨立渲染。

```python
from manim import *

BG = "#1C1C1C"
PRIMARY = "#58C4DD"
SECONDARY = "#83C167"
ACCENT = "#FFFF00"
MONO = "Menlo"

class Scene1_Introduction(Scene):
    def construct(self):
        self.camera.background_color = BG
        title = Text("為什麼這有效？", font_size=48, color=PRIMARY, weight=BOLD, font=MONO)
        self.add_subcaption("為什麼這有效？", duration=2)
        self.play(Write(title), run_time=1.5)
        self.wait(1.0)
        self.play(FadeOut(title), run_time=0.5)
```

關鍵模式：
- 在每個動畫上添加**字幕**：`self.add_subcaption("文字", duration=N)` 或在 `self.play()` 中使用 `subcaption="文字"`
- 在檔案頂部使用**共享顏色常量**，以保持跨場景的一致性
- 在每個場景中設置 **`self.camera.background_color`**
- **乾淨的退出** — 在場景結束時淡出所有物件：`self.play(FadeOut(Group(*self.mobjects)))`

### 步驟 3：渲染

```bash
manim -ql script.py Scene1_Introduction Scene2_CoreConcept  # 初稿
manim -qh script.py Scene1_Introduction Scene2_CoreConcept  # 正式輸出
```

### 步驟 4：拼接

```bash
cat > concat.txt << 'EOF'
file 'media/videos/script/480p15/Scene1_Introduction.mp4'
file 'media/videos/script/480p15/Scene2_CoreConcept.mp4'
EOF
ffmpeg -y -f concat -safe 0 -i concat.txt -c copy final.mp4
```

### 步驟 5：審核

```bash
manim -ql --format=png -s script.py Scene2_CoreConcept  # 預覽靜止圖
```

## 關鍵實作筆記

### LaTeX 使用原始字串 (Raw Strings)
```python
# 錯誤：MathTex("\frac{1}{2}")
# 正確：
MathTex(r"\frac{1}{2}")
```

### 邊緣文字使用 buff >= 0.5
```python
label.to_edge(DOWN, buff=0.5)  # 永遠不要 < 0.5
```

### 替換文字前先 FadeOut
```python
self.play(ReplacementTransform(note1, note2))  # 而不是直接在上面 Write(note2)
```

### 永遠不要動畫化未添加的 Mobjects
```python
self.play(Create(circle))  # 必須先添加 (或使用 Create)
self.play(circle.animate.set_color(RED))  # 然後再動畫化
```

## 效能目標

| 品質 | 解析度 | FPS | 速度 |
|---------|-----------|-----|-------|
| `-ql` (初稿) | 854x480 | 15 | 5-15s/場景 |
| `-qm` (中等) | 1280x720 | 30 | 15-60s/場景 |
| `-qh` (正式) | 1920x1080 | 60 | 30-120s/場景 |

開發時一律使用 `-ql` 進行迭代。僅在最終輸出時渲染 `-qh`。

## 參考文件

| 檔案 | 內容 |
|------|----------|
| `references/animations.md` | 核心動畫、速率函數、組合、`.animate` 語法、計時模式 |
| `references/mobjects.md` | 文字、形狀、VGroup/Group、定位、樣式、自定義 mobjects |
| `references/visual-design.md` | 12 條設計原則、不透明度分層、佈局模板、配色方案 |
| `references/equations.md` | Manim 中的 LaTeX、TransformMatchingTex、推導模式 |
| `references/graphs-and-data_zh_TW.md` | 坐標軸、繪圖、柱狀圖、動畫數據、演算法視覺化 |
| `references/camera-and-3d.md` | MovingCameraScene, ThreeDScene, 3D 曲面, 攝影機控制 |
| `references/scene-planning.md` | 敘事主軸、佈局模板、場景轉換、規劃模板 |
| `references/rendering.md` | CLI 參考、品質預設、ffmpeg、旁白工作流、GIF 導出 |
| `references/troubleshooting_zh_TW.md` | LaTeX 錯誤、動畫錯誤、常見錯誤、調試 |
| `references/animation-design-thinking.md` | 何時使用動畫與靜態展示、分解、節奏、旁白同步 |
| `references/updaters-and-trackers_zh_TW.md` | ValueTracker, add_updater, always_redraw, 基於時間的更新器、模式 |
| `references/paper-explainer.md` | 將研究論文轉換為動畫 —— 工作流、模板、領域模式 |
| `references/decorations.md` | SurroundingRectangle, Brace, 箭頭, DashedLine, Angle, 註釋生命週期 |
| `references/production-quality.md` | 程式碼前、渲染前、渲染後檢查表、空間佈局、顏色、節奏 |

---

## 創意發散 (僅在使用者要求實驗性/創意/獨特輸出時使用)

如果使用者要求創意、實驗性或非傳統的解釋方式，請在設計動畫之前先選擇一個策略並進行推理。

- **SCAMPER** — 當使用者想要對標準解釋進行全新嘗試時
- **假設反轉 (Assumption Reversal)** — 當使用者想要挑戰通常的教學方式時

### SCAMPER 轉換
採用標準的數學/技術視覺化並對其進行轉換：
- **替代 (Substitute)**: 替換標準的視覺隱喻（數線 → 蜿蜒的小徑，矩陣 → 城市網格）
- **組合 (Combine)**: 合併兩種解釋方法（同時進行代數 + 幾何解釋）
- **反轉 (Reverse)**: 逆向推導 —— 從結果開始並拆解回公理
- **修改 (Modify)**: 誇大某個參數以展示其重要性（10 倍學習率，1000 倍樣本量）
- **消除 (Eliminate)**: 移除所有符號 —— 純粹通過動畫和空間關係進行解釋

### 假設反轉
1. 列出關於該主題如何視覺化的「標準」方式（由左至右、2D、離散步驟、正式符號）
2. 挑選最基本的假設
3. 反轉它（由右至左推導、2D 概念的 3D 嵌入、連續變形而非離散步驟、零符號）
4. 探索這種反轉揭示了標準方法隱藏的哪些內容
