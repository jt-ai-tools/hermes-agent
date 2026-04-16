# 視覺設計原則 (Visual Design Principles)

## 12 項核心原則

1. **幾何先於代數 (Geometry Before Algebra)** —— 先展示形狀，再展示方程式。
2. **不透明度分層 (Opacity Layering)** —— 主要內容 (PRIMARY)=1.0，背景上下文 (CONTEXT)=0.4，網格 (GRID)=0.15。透過亮度引導注意。
3. **每個場景一個新點子 (One New Idea Per Scene)** —— 每個場景僅介紹一個核心概念。
4. **空間一致性 (Spatial Consistency)** —— 相同的概念在整個過程中應佔據螢幕的相同區域。
5. **顏色即意義 (Color = Meaning)** —— 為概念分配顏色，而非為 mobjects。例如：如果速度是藍色的，它就應該一直保持藍色。
6. **漸進式揭示 (Progressive Disclosure)** —— 先展示最簡單的版本，再逐步增加複雜度。
7. **變換而非替換 (Transform, Don't Replace)** —— 使用 `Transform`/`ReplacementTransform` 來展示事物間的聯繫。
8. **呼吸空間 (Breathing Room)** —— 展示新內容後，至少停留 `self.wait(1.5)`。
9. **視覺重量平衡 (Visual Weight Balance)** —— 不要將所有內容都堆在其中一側。
10. **一致的動作語彙 (Consistent Motion Vocabulary)** —— 選擇一小組動畫類型並重複使用它們。
11. **深色背景、亮色內容 (Dark Background, Light Content)** —— 使用 `#1C1C1C` 到 `#2D2B55` 的背景以最大化對比度。
12. **刻意留白 (Intentional Empty Space)** —— 畫面中至少保留 15% 的空白區域。

## 佈局範本 (Layout Templates)

### 全置中 (FULL_CENTER)
一個主要元素置中，標題在上方，備註在下方。
最適用於：單一方程式、單一圖表、標題卡。

### 左右分佈 (LEFT_RIGHT)
兩個元素並排，分別位於 x=-3.5 和 x=3.5。
最適用於：方程式 + 視覺圖、前後對比、比較。

### 上下分佈 (TOP_BOTTOM)
主要元素位於 y=1.5，輔助內容位於 y=-1.5。
最適用於：概念 + 範例、定理 + 案例。

### 網格 (GRID)
透過 `arrange_in_grid()` 呈現多個元素。
最適用於：比較矩陣、多步驟流程。

### 漸進式 (PROGRESSIVE)
元素逐一出現，向下排列 (DOWN) 並靠左對齊 (aligned_edge=LEFT)。
最適用於：演算法、證明、逐步流程。

### 帶註釋的圖表 (ANNOTATED_DIAGRAM)
中心圖表搭配由箭頭連接的懸浮標籤。
最適用於：架構圖、附帶註釋的圖形。

## 顏色調色盤 (Color Palettes)

### 經典 3B1B 視覺風格
```python
BG="#1C1C1C"; PRIMARY=BLUE; SECONDARY=GREEN; ACCENT=YELLOW; HIGHLIGHT=RED
```

### 溫潤學術風格
```python
BG="#2D2B55"; PRIMARY="#FF6B6B"; SECONDARY="#FFD93D"; ACCENT="#6BCB77"
```

### 霓虹科技風格
```python
BG="#0A0A0A"; PRIMARY="#00F5FF"; SECONDARY="#FF00FF"; ACCENT="#39FF14"
```

## 字體選擇 (Font Selection)

**所有文字請使用等寬字體 (Monospace fonts)。** Manim 的 Pango 文字渲染器在處理比例字體（如 Helvetica, Inter, SF Pro, Arial）時，不論大小或解析度，都會產生錯誤的字距 (kerning) 渲染，導致字元重疊且間距不一致。這是 Pango 本身的基礎限制，而非 Manim 的錯誤。

等寬字體的字元寬度固定，設計上便解決了字距渲染問題。

### 推薦字體

| 使用案例 | 字體 | 備用字體 |
|----------|------|----------|
| **所有文字（預設）** | `"Menlo"` | `"Courier New"`, `"DejaVu Sans Mono"` |
| 程式碼、標籤 | `"JetBrains Mono"`, `"SF Mono"` | `"Menlo"` |
| 數學公式 | 使用 `MathTex`（透過 LaTeX 渲染，而非 Pango） | — |

```python
MONO = "Menlo"  # 在檔案頂部定義一次

title = Text("傅立葉級數 (Fourier Series)", font_size=48, color=PRIMARY, weight=BOLD, font=MONO)
label = Text("n=1: (4/pi) sin(x)", font_size=20, color=BLUE, font=MONO)
note = Text("不連續點的收斂性", font_size=18, color=DIM, font=MONO)

# 數學公式 —— 務必使用 MathTex 而非 Text
equation = MathTex(r"\nabla L = \frac{\partial L}{\partial w}")
```

### 何時可以使用比例字體 (Proportional Fonts)

字數較短（1-3 個詞）的大型標題文字 (font_size >= 48) 可以使用比例字體，而不會有明顯的字距問題。除此之外的任何內容 —— 標籤、描述、多詞文字、小尺寸文字 —— 請一律使用等寬字體。

### 字體可用性

- **macOS**: Menlo (內建), SF Mono
- **Linux**: DejaVu Sans Mono (內建), Liberation Mono
- **跨平台**: JetBrains Mono (可從 jetbrains.com 安裝)

`"Menlo"` 是最安全的預設選擇 —— 在 macOS 上為內建字體，而 Linux 系統則會自動回退至 DejaVu Sans Mono。

### 精細文字控制

`Text()` 不支援 `letter_spacing` 或字距參數。如需精細控制，請使用帶有 Pango 屬性的 `MarkupText`：

```python
# 字元間距 (Pango 單位：1/1024 點)
MarkupText('<span letter_spacing="6000">HERMES</span>', font_size=18, font="Menlo")

# 針對特定單詞加粗
MarkupText('這非常 <b>重要</b>', font_size=24, font="Menlo")

# 針對特定單詞著色
MarkupText('紅色 <span foreground="#FF6B6B">警告</span>', font_size=24, font="Menlo")
```

### 最小字體大小

`font_size=18` 是在任何解析度下保持文字可讀性的最小值。低於 18 時，字元在 `-ql` 下會變得模糊，即使在 `-qh` 下也難以閱讀。

## 視覺階層檢查清單

針對每一個畫面：
1. 使用者「唯一」該看的東西是什麼？（最亮/最大）
2. 什麼是背景上下文？（調暗至 0.3-0.4）
3. 什麼是結構性內容？（調暗至 0.15）
4. 留白是否足夠？（>15%）
5. 所有文字在手機尺寸下是否清晰可讀？
