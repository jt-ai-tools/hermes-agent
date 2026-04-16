# 裝飾與視覺美化 (Decorations and Visual Polish)

裝飾性物件是指那些用於註釋、突出顯示或框住其他物件的 mobjects。它們能將一個「技術上正確」的動畫轉化為「視覺上精美」的作品。

## SurroundingRectangle (環繞矩陣)

在任何 mobject 周圍繪製一個矩形。這是突出顯示內容的首選方法：

```python
highlight = SurroundingRectangle(
    equation[2],            # 要突出顯示的項
    color=YELLOW,
    buff=0.15,              # 內容與邊框之間的間距
    corner_radius=0.1,      # 圓角
    stroke_width=2
)
self.play(Create(highlight))
self.wait(1)
self.play(FadeOut(highlight))
```

### 框住方程式的一部分

```python
eq = MathTex(r"E", r"=", r"m", r"c^2")
box = SurroundingRectangle(eq[2:], color=YELLOW, buff=0.1)  # 突出顯示 "mc²"
label = Text("質能 (mass-energy)", font_size=18, font="Menlo", color=YELLOW)
label.next_to(box, DOWN, buff=0.2)
self.play(Create(box), FadeIn(label))
```

## BackgroundRectangle (背景矩形)

在文字後方加入半透明背景，以提高在複雜場景中的可讀性：

```python
bg = BackgroundRectangle(equation, fill_opacity=0.7, buff=0.2, color=BLACK)
self.play(FadeIn(bg), Write(equation))

# 或者使用 set_stroke 為文字本身加入「背景輪廓」效果：
label.set_stroke(BLACK, width=5, background=True)
```

在圖表或圖形上方，使用 `set_stroke(background=True)` 的方法通常比背景矩形更顯簡潔。

## Brace 與 BraceLabel (大括號)

用於標註圖表或方程式特定部分的捲曲大括號：

```python
brace = Brace(equation[2:4], DOWN, color=YELLOW)
brace_label = brace.get_text("這些項", font_size=20)
self.play(GrowFromCenter(brace), FadeIn(brace_label))

# 在兩個特定點之間加入大括號
brace = BraceBetweenPoints(point_a, point_b, direction=UP)
```

### 大括號放置位置

```python
# 放在群組下方
Brace(group, DOWN)
# 放在群組上方
Brace(group, UP)
# 放在群組左側
Brace(group, LEFT)
# 放在群組右側
Brace(group, RIGHT)
```

## 用於標註的箭頭

### 指向 mobjects 的直線箭頭

```python
arrow = Arrow(
    start=label.get_bottom(),
    end=target.get_top(),
    color=YELLOW,
    stroke_width=2,
    buff=0.1,                    # 箭頭尖端與目標之間的間隙
    max_tip_length_to_length_ratio=0.15  # 較小的箭頭端
)
self.play(GrowArrow(arrow), FadeIn(label))
```

### 曲線箭頭

```python
arrow = CurvedArrow(
    start_point=source.get_right(),
    end_point=target.get_left(),
    angle=PI/4,                  # 曲線角度
    color=PRIMARY
)
```

### 使用箭頭進行標註

```python
# LabeledArrow：自帶文字標籤的箭頭
arr = LabeledArrow(
    Text("梯度 (gradient)", font_size=16, font="Menlo"),
    start=point_a, end=point_b, color=RED
)
```

## DashedLine 與 DashedVMobject (虛線)

```python
# 虛線（用於漸近線、輔助線、隱含連接等）
asymptote = DashedLine(
    axes.c2p(2, -3), axes.c2p(2, 3),
    color=YELLOW, dash_length=0.15
)

# 將任何 VMobject 轉為虛線形式
dashed_circle = DashedVMobject(Circle(radius=2, color=BLUE), num_dashes=30)
```

## 角度與直角標記 (Angle and RightAngle Markers)

```python
line1 = Line(ORIGIN, RIGHT * 2)
line2 = Line(ORIGIN, UP * 2 + RIGHT)

# 兩條線之間的圓弧角度標記
angle = Angle(line1, line2, radius=0.5, color=YELLOW)
angle_value = angle.get_value()  # 弧度值

# 直角標記（小正方形）
right_angle = RightAngle(line1, Line(ORIGIN, UP * 2), length=0.3, color=WHITE)
```

## Cross (刪除線/叉號)

將某物標記為錯誤或棄用：

```python
cross = Cross(old_equation, color=RED, stroke_width=4)
self.play(Create(cross))
# 然後顯示正確的版本
```

## Underline (下劃線)

```python
underline = Underline(important_text, color=ACCENT, stroke_width=3)
self.play(Create(underline))
```

## 顏色突出顯示工作流

### 方法 1：在建立時使用 t2c

```python
text = Text("這裡的梯度是負的", t2c={"梯度": BLUE, "負": RED})
```

### 方法 2：建立後使用 set_color_by_tex

```python
eq = MathTex(r"\nabla L = -\frac{\partial L}{\partial w}")
eq.set_color_by_tex(r"\nabla", BLUE)
eq.set_color_by_tex(r"\partial", RED)
```

### 方法 3：透過子物件索引 (submobjects)

```python
eq = MathTex(r"a", r"+", r"b", r"=", r"c")
eq[0].set_color(RED)    # "a"
eq[2].set_color(BLUE)   # "b"
eq[4].set_color(GREEN)  # "c"
```

## 組合註釋 (Combining Annotations)

疊加多個註釋以增強強調效果：

```python
# 依序突出顯示一個項、加上大括號、再加入箭頭
box = SurroundingRectangle(eq[2], color=YELLOW, buff=0.1)
brace = Brace(eq[2], DOWN, color=YELLOW)
label = brace.get_text("學習率 (learning rate)", font_size=18)

self.play(Create(box))
self.wait(0.5)
self.play(FadeOut(box), GrowFromCenter(brace), FadeIn(label))
self.wait(1.5)
self.play(FadeOut(brace), FadeOut(label))
```

### 註釋的生命週期

註釋應遵循一定的節奏：
1. **出現** —— 吸引注意力 (Create, GrowFromCenter)
2. **停留** —— 讓觀眾閱讀並理解 (self.wait)
3. **消失** —— 清理舞台以迎接下一個內容 (FadeOut)

絕不要讓註釋無限期地留在螢幕上 —— 一旦完成任務，它們就會變成視覺噪音。
