# 論文導讀影片工作流 (Paper Explainer Workflow)

如何將研究論文轉化為生動的動畫導讀影片。

## 為什麼要為論文製作動畫？

研究論文是為了精確性和完整性而優化的；而影片則是為了理解和記憶而優化的。這種轉化並非「搭配圖片朗讀論文」，而是「提取核心洞察，並透過視覺敘事讓它變得顯而易見」。

論文只有一個任務：證明主張是真實的。影片則有不同的任務：讓觀眾理解「為什麼」該主張是真實的，以及「為什麼」它很重要。

## 誰在看影片？

在開始之前，先決定受眾：

| 受眾 | 必備基礎 | 節奏 | 深度 |
|----------|--------------|--------|-------|
| 一般大眾 | 無 | 慢，使用大量類比 | 僅建立直覺，跳過證明 |
| 大學生 | 基礎數學/電腦科學 | 中等，包含一些正式語法 | 關鍵方程式，跳過推導 |
| 研究生 / 研究人員 | 領域專業知識 | 較快，使用更多符號 | 完整的方程式，概述證明 |

這決定了一切：詞彙、節奏、要動畫化哪些章節，以及要展示多少數學內容。

## 5 分鐘範本

大多數論文導讀影片都符合此結構（對於較長的影片，請按比例縮放時間）：

| 章節 | 時長 | 目的 |
|---------|----------|---------|
| **鉤子 (Hook)** | 0:00-0:30 | 令人驚訝的結果或具挑釁性的問題 |
| **問題 (Problem)** | 0:30-1:30 | 在這篇論文出現前，有什麼問題或遺漏 |
| **關鍵洞察 (Key insight)** | 1:30-3:00 | 核心思想，透過視覺化解釋 |
| **運作原理 (How it works)** | 3:00-4:00 | 方法/演算法，簡化版 |
| **證據 (Evidence)** | 4:00-4:30 | 證明它有效的關鍵結果 |
| **意義與影響 (Implications)** | 4:30-5:00 | 為什麼它很重要，它能實現什麼 |

### 應該跳過的內容

- 相關工作綜述 (Related work survey) —— 一句話概括：「之前的方法做了 X，但有 Y 問題。」
- 實作細節 —— 除非它們是主要的貢獻，否則跳過。
- 消融實驗 (Ablation studies) —— 最多展示一個圖表。
- 證明 —— 展示關鍵步驟，而非完整證明。
- 超參數調整 —— 完全跳過。

### 應該展開的內容

- 核心洞察 —— 這應該佔據最多的螢幕時間。
- 幾何/視覺直覺 —— 如果論文中有數學，請展示它的「含義」。
- 前後對比 —— 最具說服力的證據。

## 編碼前的工作流程

### 第一關：旁白腳本 (Narration script)

在寫任何程式碼之前，先寫好完整的旁白。每一句話都對應一個視覺節奏。如果您寫不出旁白，說明您對論文的理解還不足以將其動畫化。

```markdown
## 鉤子 (30秒)
「如果我告訴您，一個擁有 70 億參數的模型可以超越 700 億參數的模型 —— 
只要您用正確的資料來訓練它，您會怎麼想？」

## 問題 (60秒)
「標準做法是擴大模型。更多參數、更多運算資源。
[視覺效果：長條圖顯示模型大小呈指數級增長]
但 Chinchilla 研究告訴我們，大多數模型都訓練不足……」
```

### 第二關：場景清單 (Scene list)

寫好旁白後，將其拆分為場景。每個場景對應一個 Manim 類別 (Class)。

```markdown
場景 1：鉤子 —— 帶有動畫計數器的驚人統計數據
場景 2：問題 —— 模型大小長條圖不斷增長
場景 3：關鍵洞察 —— 訓練資料 vs 參數，動畫 2D 繪圖
場景 4：方法 —— 由左至右構建的流水線圖 (Pipeline diagram)
場景 5：結果 —— 帶有動畫長條圖的前後對比
場景 6：結語 —— 影響與意義的文字說明
```

### 第三關：樣式常數 (Style constants)

在編寫場景程式碼之前，先定義視覺語言：

```python
# style.py —— 在每個場景檔案中匯入
BG = "#0D1117"
PRIMARY = "#58C4DD"
SECONDARY = "#83C167"
ACCENT = "#FFFF00"
HIGHLIGHT = "#FF6B6B"
MONO = "Menlo"

# 針對「這篇」論文的顏色含義
MODEL_COLOR = PRIMARY      # 「模型」
DATA_COLOR = SECONDARY     # 「訓練資料」
BASELINE_COLOR = HIGHLIGHT # 「先前的方法」
RESULT_COLOR = ACCENT      # 「我們的結果」
```

## 第一原理方程式解釋 (First-principles equation explanation)

當論文中有關鍵方程式時，不要只是展示它 —— 從直覺開始構建：

### 「如果是您，您會怎麼做？」模式

1. 用通俗語言提出問題
2. 詢問最簡單的解決方案是什麼
3. 展示為什麼它行不通（動畫演示失敗過程）
4. 引入論文的解決方案作為修復方案
5. 「然後」再展示方程式 —— 此時展示便顯得理所當然

```python
# 場景：為什麼我們需要注意力機制（針對 Transformer 論文）
# 步驟 1：「我們如何讓每個單詞都關注到其他所有單詞？」
# 步驟 2：展示簡單做法（全連接 = 一切都是 O(n²)）
# 步驟 3：展示它失效了（資訊過載，缺乏選擇性）
# 步驟 4：「如果每個單詞可以「選擇」要關注哪些單詞呢？」
# 步驟 5：展示注意力機制方程式 —— Q, K, V 現在有了具體的含義
```

### 方程式揭曉策略

```python
# 先顯示調暗的方程式（完整目標）
eq = MathTex(r"Attention(Q,K,V) = softmax\left(\frac{QK^T}{\sqrt{d_k}}\right)V")
eq.set_opacity(0.15)
self.play(FadeIn(eq))

# 逐一突出顯示 Q, K, V，並搭配顏色和標籤
for part, color, label_text in [
    (r"Q", PRIMARY, "查詢 (Query)：我正在尋找什麼？"),
    (r"K", SECONDARY, "鍵 (Key)：我包含了什麼？"),
    (r"V", ACCENT, "值 (Value)：我輸出什麼？"),
]:
    eq.set_color_by_tex(part, color)
    label = Text(label_text, font_size=18, color=color, font=MONO)
    # 定位標籤、製作動畫、等待、然後調暗標籤
```

## 構建架構圖 (Building architecture diagrams)

### 漸進式構建模式

不要一次展示完整的架構。要逐步構建：

1. 第一個組件單獨出現 —— 解釋它
2. 箭頭生長 —— 「這會輸入到……」
3. 第二個組件出現 —— 解釋它
4. 重複直到完整

```python
# 組件工廠
def make_box(label, color, width=2.0, height=0.8):
    box = RoundedRectangle(corner_radius=0.1, width=width, height=height,
                           color=color, fill_opacity=0.1, stroke_width=1.5)
    text = Text(label, font_size=18, font=MONO, color=color).move_to(box)
    return Group(box, text)

encoder = make_box("編碼器 (Encoder)", PRIMARY)
decoder = make_box("解碼器 (Decoder)", SECONDARY).next_to(encoder, RIGHT, buff=1.5)
arrow = Arrow(encoder.get_right(), decoder.get_left(), color=DIM, stroke_width=1.5)

self.play(FadeIn(encoder))
self.wait(1)  # 解釋編碼器
self.play(GrowArrow(arrow))
self.play(FadeIn(decoder))
self.wait(1)  # 解釋解碼器
```

### 資料流動畫 (Data flow animation)

構建好圖表後，展示資料在其中的流動：

```python
# 沿著流水線移動的圓點
data_dot = Dot(color=ACCENT, radius=0.1).move_to(encoder)
self.play(FadeIn(data_dot))
self.play(MoveAlongPath(data_dot, arrow), run_time=1)
self.play(data_dot.animate.move_to(decoder), run_time=0.5)
self.play(Flash(data_dot.get_center(), color=ACCENT), run_time=0.3)
```

## 動畫化結果 (Animating results)

### 長條圖比較（最常見）

```python
# 之前/之後的長條
before_data = [45, 52, 38, 61]
after_data = [78, 85, 72, 91]
labels = ["任務 A", "任務 B", "任務 C", "任務 D"]

before_chart = BarChart(before_data, bar_names=labels,
    y_range=[0, 100, 20], bar_colors=[HIGHLIGHT]*4).scale(0.6).shift(LEFT*3)
after_chart = BarChart(after_data, bar_names=labels,
    y_range=[0, 100, 20], bar_colors=[SECONDARY]*4).scale(0.6).shift(RIGHT*3)

before_label = Text("基線 (Baseline)", font_size=20, color=HIGHLIGHT, font=MONO)
after_label = Text("我們的方法", font_size=20, color=SECONDARY, font=MONO)

# 先揭曉基線，再揭曉我們的方法（戲劇性的對比）
self.play(Create(before_chart), FadeIn(before_label))
self.wait(1.5)
self.play(Create(after_chart), FadeIn(after_label))
self.wait(0.5)

# 突出顯示改進效果
improvement = Text("平均提升 +35%", font_size=24, color=ACCENT, font=MONO)
self.play(FadeIn(improvement))
```

### 訓練曲線（針對機器學習論文）

```python
tracker = ValueTracker(0)
curve = always_redraw(lambda: axes.plot(
    lambda x: 1 - 0.8 * np.exp(-x / 3),
    x_range=[0, tracker.get_value()], color=PRIMARY
))
epoch_label = always_redraw(lambda: Text(
    f"訓練輪次 (Epoch) {int(tracker.get_value())}", font_size=18, font=MONO
).to_corner(UR))

self.add(curve, epoch_label)
self.play(tracker.animate.set_value(10), run_time=5, rate_func=linear)
```

## 領域特定模式

### 機器學習 (ML) 論文
- 展示通過模型的資料流（動畫流水線）
- 使用 `ValueTracker` 展示訓練曲線
- 將注意力熱圖顯示為彩色網格
- 將嵌入空間顯示為 2D 散佈圖 (PCA/t-SNE 視覺化)
- 將損失景觀 (Loss landscape) 顯示為帶有梯度下降點的 3D 曲面

### 物理/數學論文
- 使用 `LinearTransformationScene` 進行線性代數演示
- 使用 `ArrowVectorField` / `StreamLines` 演示向量場
- 使用 `NumberPlane` + 軌跡演示相位空間 (Phase spaces)
- 使用帶時間參數的繪圖演示波動方程 (Wave equations)

### 系統/架構論文
- 漸進式構建的流水線圖
- 使用 `ShowPassingFlash` 展示沿箭頭流動的資料
- 使用 `ZoomedScene` 放大組件細節
- 前後對比延遲/吞吐量

## 常見錯誤

1. **試圖涵蓋整篇論文。** 5 分鐘的影片可以很好地解釋「一個」核心洞察。涵蓋一切意味著什麼也解釋不清楚。
2. **將摘要作為旁白朗讀。** 學術寫作是為讀者設計的，而非聽眾。請用口語化的語言重寫。
3. **展示沒有含義的符號。** 在展示符號之前，務必先展示它在視覺上代表什麼。
4. **跳過動機說明。** 直接進入「這是我們的方法」，而不展示為什麼這個問題很重要。「問題」章節才是讓觀眾產生共鳴的關鍵。
5. **全程節奏一致。** 「鉤子」和「關鍵洞察」需要最強的視覺能量。「方法」章節可以快一點。「證據」應該落地有聲（在展示亮眼數據後稍作停頓）。
