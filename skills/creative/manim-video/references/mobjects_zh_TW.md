# Mobjects 參考指南

螢幕上所有可見的內容都是 Mobject。它們具有位置、顏色、不透明度等屬性，且可以進行動畫處理。

## 文字 (Text)

```python
title = Text("Hello World", font_size=48, color=BLUE)
eq = MathTex(r"E = mc^2", font_size=40)

# 多部分文字（用於選擇性著色）
eq = MathTex(r"a^2", r"+", r"b^2", r"=", r"c^2")
eq[0].set_color(RED)
eq[4].set_color(BLUE)

# 混合文字與數學公式
t = Tex(r"面積為 $\pi r^2$", font_size=36)

# 帶樣式的標記文字
t = MarkupText('<span foreground="#58C4DD">藍色</span> 文字', font_size=30)
```

**對於任何包含反斜線的字串，請務必使用原始字串 (`r""`)。**

## 形狀 (Shapes)

```python
circle = Circle(radius=1, color=BLUE, fill_opacity=0.5)
square = Square(side_length=2, color=RED)
rect = Rectangle(width=4, height=2, color=GREEN)
dot = Dot(point=ORIGIN, radius=0.08, color=YELLOW)
line = Line(LEFT * 2, RIGHT * 2, color=WHITE)
arrow = Arrow(LEFT, RIGHT, color=ORANGE)
rrect = RoundedRectangle(corner_radius=0.3, width=4, height=2)
brace = Brace(rect, DOWN, color=YELLOW)
```

## 多邊形與弧形 (Polygons and Arcs)

```python
# 從頂點建立任意多邊形
poly = Polygon(LEFT, UP * 2, RIGHT, color=GREEN, fill_opacity=0.3)

# 正 n 邊形
hexagon = RegularPolygon(n=6, color=TEAL, fill_opacity=0.4)

# 三角形（RegularPolygon(n=3) 的簡寫）
tri = Triangle(color=YELLOW, fill_opacity=0.5)

# 弧形（圓形的一部分）
arc = Arc(radius=2, start_angle=0, angle=PI / 2, color=BLUE)

# 兩點之間的弧形
arc_between = ArcBetweenPoints(LEFT * 2, RIGHT * 2, angle=TAU / 4, color=RED)

# 曲線箭頭（帶有箭頭的弧形）
curved_arrow = CurvedArrow(LEFT * 2, RIGHT * 2, color=ORANGE)
```

## 扇形與環形 (Sectors and Annuli)

```python
# 扇形
sector = Sector(outer_radius=2, start_angle=0, angle=PI / 3, fill_opacity=0.7, color=BLUE)

# 環形
ring = Annulus(inner_radius=1, outer_radius=2, fill_opacity=0.5, color=GREEN)

# 部分環形
partial_ring = AnnularSector(
    inner_radius=1, outer_radius=2,
    angle=PI / 2, start_angle=0,
    fill_opacity=0.7, color=TEAL
)

# 挖空（在形狀中打孔）
background = Square(side_length=4, fill_opacity=1, color=BLUE)
hole = Circle(radius=0.5)
cutout = Cutout(background, hole, fill_opacity=1, color=BLUE)
```

使用案例：圓格圖、環形進度指示器、帶有弧形的文氏圖、幾何證明。

## 定位 (Positioning)

```python
mob.move_to(ORIGIN)                        # 置中
mob.move_to(UP * 2 + RIGHT)               # 相對定位
label.next_to(circle, DOWN, buff=0.3)     # 放置在另一個組件旁邊
title.to_edge(UP, buff=0.5)               # 螢幕邊緣 (buff >= 0.5!)
mob.to_corner(UL, buff=0.5)               # 角落
```

## VGroup 與 Group

**VGroup** 用於形狀集合（僅限 VMobjects —— Circle, Square, Arrow, Line, MathTex）：
```python
shapes = VGroup(circle, square, arrow)
shapes.arrange(DOWN, buff=0.5)
shapes.set_color(BLUE)
```

**Group** 用於混合集合（文字 + 形狀，或任何 Mobject 類型）：
```python
# Text 物件是 Mobject 而非 VMobject —— 混合時請使用 Group
labeled_shape = Group(circle, Text("標籤").next_to(circle, DOWN))
labeled_shape.move_to(ORIGIN)

# 淡出螢幕上所有內容（可能包含混合類型）
self.play(FadeOut(Group(*self.mobjects)))
```

**規則：如果您的群組中包含任何 `Text()` 物件，請使用 `Group` 而非 `VGroup`。** 在 Manim CE v0.20+ 中，VGroup 會引發 TypeError。MathTex 和 Tex 是 VMobjects，可以與 VGroup 搭配使用。

兩者皆支援 `arrange()`、`arrange_in_grid()`、`set_opacity()`、`shift()`、`scale()`、`move_to()`。

## 樣式 (Styling)

```python
mob.set_color(BLUE)
mob.set_fill(RED, opacity=0.5)
mob.set_stroke(WHITE, width=2)
mob.set_opacity(0.4)
mob.set_z_index(1)                         # 圖層順序
```

## 特殊 Mobjects

```python
nl = NumberLine(x_range=[-3, 3, 1], length=8, include_numbers=True)
table = Table([["A", "B"], ["C", "D"]], row_labels=[Text("R1"), Text("R2")])
code = Code("example.py", tab_width=4, font_size=20, language="python")
highlight = SurroundingRectangle(target, color=YELLOW, buff=0.2)
bg = BackgroundRectangle(equation, fill_opacity=0.7, buff=0.2)
```

## 自定義 Mobjects

```python
class NetworkNode(Group):
    def __init__(self, label_text, color=BLUE, **kwargs):
        super().__init__(**kwargs)
        self.circle = Circle(radius=0.4, color=color, fill_opacity=0.3)
        self.label = Text(label_text, font_size=20).move_to(self.circle)
        self.add(self.circle, self.label)
```

## 矩陣 Mobjects (Matrix Mobjects)

將矩陣顯示為數字或 mobjects 網格：

```python
# 整數矩陣
m = IntegerMatrix([[1, 2], [3, 4]])

# 小數矩陣（控制小數位數）
m = DecimalMatrix([[1.5, 2.7], [3.1, 4.9]], element_to_mobject_config={"num_decimal_places": 2})

# Mobject 矩陣（每個單元格可以是任何 mobject）
m = MobjectMatrix([
    [MathTex(r"\pi"), MathTex(r"e")],
    [MathTex(r"\phi"), MathTex(r"\tau")]
])

# 括號類型："(" "[" "|" 或 "\\{"
m = IntegerMatrix([[1, 0], [0, 1]], left_bracket="[", right_bracket="]")
```

使用案例：線性代數、變換矩陣、方程組係數顯示。

## 常數 (Constants)

方向：`UP, DOWN, LEFT, RIGHT, ORIGIN, UL, UR, DL, DR`
顏色：`RED, BLUE, GREEN, YELLOW, WHITE, GRAY, ORANGE, PINK, PURPLE, TEAL, GOLD`
框架：`config.frame_width = 14.222, config.frame_height = 8.0`

## SVGMobject —— 匯入 SVG 檔案

```python
logo = SVGMobject("path/to/logo.svg")
logo.set_color(WHITE).scale(0.5).to_corner(UR)
self.play(FadeIn(logo))

# SVG 子物件可個別進行動畫處理
for part in logo.submobjects:
    self.play(part.animate.set_color(random_color()))
```

## ImageMobject —— 顯示圖片

```python
img = ImageMobject("screenshot.png")
img.set_height(3).to_edge(RIGHT)
self.play(FadeIn(img))
```

注意：圖片無法使用 `.animate` 進行動畫處理（它們是點陣圖而非向量圖）。僅限使用 `FadeIn`/`FadeOut` 以及 `shift`/`scale`。

## Variable —— 自動更新顯示

```python
var = Variable(0, Text("x"), num_decimal_places=2)
var.move_to(ORIGIN)
self.add(var)

# 針對數值進行動畫處理
self.play(var.tracker.animate.set_value(5), run_time=2)
# 顯示會自動更新為："x = 5.00"
```

對於帶標籤的數值顯示，這比手動結合 `DecimalNumber` + `add_updater` 更簡潔。

## 項目列表 (BulletedList)

```python
bullets = BulletedList(
    "第一個關鍵點",
    "第二個重要事實",
    "第三個結論",
    font_size=28
)
bullets.to_edge(LEFT, buff=1.0)
self.play(Write(bullets))

# 突出顯示個別項目
self.play(bullets[1].animate.set_color(YELLOW))
```

## 虛線與角度標記 (DashedLine and Angle Markers)

```python
# 虛線（漸近線、輔助線）
dashed = DashedLine(LEFT * 3, RIGHT * 3, color=SUBTLE, dash_length=0.15)

# 兩條線之間的角度標記
line1 = Line(ORIGIN, RIGHT * 2)
line2 = Line(ORIGIN, UP * 2 + RIGHT)
angle = Angle(line1, line2, radius=0.5, color=YELLOW)
angle_label = angle.get_value()  # 以弧度為單位返回角度值

# 直角標記
right_angle = RightAngle(line1, Line(ORIGIN, UP * 2), length=0.3, color=WHITE)
```

## 布林運算 (Boolean Operations - CSG)

合併、扣除或相交 2D 形狀：

```python
circle = Circle(radius=1.5, color=BLUE, fill_opacity=0.5).shift(LEFT * 0.5)
square = Square(side_length=2, color=RED, fill_opacity=0.5).shift(RIGHT * 0.5)

# 聯集 (Union)、交集 (Intersection)、差集 (Difference)、互斥 (Exclusion)
union = Union(circle, square, color=GREEN, fill_opacity=0.5)
intersect = Intersection(circle, square, color=YELLOW, fill_opacity=0.5)
diff = Difference(circle, square, color=PURPLE, fill_opacity=0.5)
exclude = Exclusion(circle, square, color=ORANGE, fill_opacity=0.5)
```

使用案例：文氏圖、集合論、幾何證明、面積計算。

## 帶標籤的箭頭/線條 (LabeledArrow / LabeledLine)

```python
# 帶有內建標籤（自動定位）的箭頭
arr = LabeledArrow(Text("力 (force)", font_size=18), start=LEFT, end=RIGHT, color=RED)

# 帶有標籤的線條
line = LabeledLine(Text("d = 5m", font_size=18), start=LEFT * 2, end=RIGHT * 2)
```

自動處理標籤定位 —— 比手動結合 `Arrow` + `Text().next_to()` 更簡潔。

## 針對子字串設定文字顏色/字體/樣式 (t2c, t2f, t2s, t2w)

```python
# 為特定單詞著色 (t2c = text-to-color)
text = Text(
    "梯度下降法可最小化損失函數",
    t2c={"梯度下降法": BLUE, "損失函數": RED}
)

# 為不同單詞設定不同字體 (t2f = text-to-font)
text = Text(
    "使用 Menlo 作為程式碼字體，Inter 作為內文字體",
    t2f={"Menlo": "Menlo", "Inter": "Inter"}
)

# 為個別單詞設定斜體/傾斜 (t2s = text-to-slant)
text = Text("一般文字與斜體文字", t2s={"斜體": ITALIC})

# 為個別單詞設定粗體 (t2w = text-to-weight)
text = Text("一般文字與粗體文字", t2w={"粗體": BOLD})
```

這比建立多個分開的 Text 物件再將其群組化要簡潔得多。

## 增加背景文字的可讀性 (Backstroke)

當文字與其他內容（圖表、圖示、圖片）重疊時，在其後方增加深色輪廓：

```python
# CE 語法：
label.set_stroke(BLACK, width=5, background=True)

# 套用到群組
for mob in labels:
    mob.set_stroke(BLACK, width=4, background=True)
```

這就是 3Blue1Brown 如何在不使用 BackgroundRectangle 的情況下，讓文字在複雜背景上保持清晰可讀的方法。

## 複數函數變換 (Complex Function Transforms)

將複數函數套用到整個 mobjects —— 這會改變平面：

```python
c_grid = ComplexPlane()
moving_grid = c_grid.copy()
moving_grid.prepare_for_nonlinear_transform()  # 增加更多取樣點以便平滑變形

self.play(
    moving_grid.animate.apply_complex_function(lambda z: z**2),
    run_time=5,
)

# 也適用於 R3->R3 函數：
self.play(grid.animate.apply_function(
    lambda p: [p[0] + 0.5 * math.sin(p[1]), p[1] + 0.5 * math.sin(p[0]), p[2]]
), run_time=5)
```

**至關重要：** 在套用非線性函數之前，請務必呼叫 `prepare_for_nonlinear_transform()` —— 否則網格的取樣點會太少，導致變形看起來有鋸齒感。
