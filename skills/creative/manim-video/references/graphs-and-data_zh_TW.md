# 圖表、繪圖與數據視覺化

## 坐標軸 (Axes)

```python
axes = Axes(
    x_range=[-3, 3, 1], y_range=[-2, 2, 1],
    x_length=8, y_length=5,
    axis_config={"include_numbers": True, "font_size": 24}
)
axes.set_opacity(0.15)  # 作為結構元素
x_label = axes.get_x_axis_label(r"x")
```

## 繪圖 (Plotting)

```python
graph = axes.plot(lambda x: x**2, color=BLUE)
graph_label = axes.get_graph_label(graph, label=r"x^2", x_val=2)
area = axes.get_area(graph, x_range=[0, 2], color=BLUE, opacity=0.3)
```

## 動畫繪圖

```python
self.play(Create(graph), run_time=3)  # 追蹤繪製圖表

# 沿著曲線移動的點
dot = Dot(color=YELLOW).move_to(axes.c2p(0, 0))
self.play(MoveAlongPath(dot, graph), run_time=3)

# 動態參數
tracker = ValueTracker(1)
dynamic = always_redraw(lambda: axes.plot(lambda x: tracker.get_value() * x**2, color=BLUE))
self.add(dynamic)
self.play(tracker.animate.set_value(3), run_time=2)
```

## 柱狀圖 (Bar Charts)

```python
chart = BarChart(
    values=[4, 6, 2, 8, 5], bar_names=["A", "B", "C", "D", "E"],
    y_range=[0, 10, 2], bar_colors=[RED, GREEN, BLUE, YELLOW, PURPLE]
)
self.play(Create(chart), run_time=2)
self.play(chart.animate.change_bar_values([6, 3, 7, 4, 9]))
```

## 數線 (Number Lines)

```python
nl = NumberLine(x_range=[0, 10, 1], length=10, include_numbers=True)
pointer = Arrow(nl.n2p(3) + UP * 0.5, nl.n2p(3), color=RED, buff=0)
tracker = ValueTracker(3)
pointer.add_updater(lambda m: m.put_start_and_end_on(
    nl.n2p(tracker.get_value()) + UP * 0.5, nl.n2p(tracker.get_value())))
self.play(tracker.animate.set_value(8), run_time=2)
```

## 動畫計數器

```python
counter = DecimalNumber(0, font_size=72, num_decimal_places=0)
self.play(counter.animate.set_value(1000), run_time=3, rate_func=rush_from)
```

## 演算法視覺化模式

```python
values = [5, 2, 8, 1, 9, 3]
bars = VGroup(*[
    Rectangle(width=0.6, height=v * 0.4, color=BLUE, fill_opacity=0.7)
    for v in values
]).arrange(RIGHT, buff=0.2, aligned_edge=DOWN).move_to(ORIGIN)
self.play(LaggedStart(*[GrowFromEdge(b, DOWN) for b in bars], lag_ratio=0.1))
# 高亮、交換等操作
```

## 數據故事模式

```python
# 前後對比
before = BarChart(values=[3, 5, 2], bar_colors=[RED]*3).shift(LEFT * 3)
after = BarChart(values=[8, 9, 7], bar_colors=[GREEN]*3).shift(RIGHT * 3)
self.play(Create(before)); self.wait(1)
self.play(Create(after)); self.wait(1)
arrow = Arrow(before.get_right(), after.get_left(), color=YELLOW)
label = Text("+167%", font_size=36, color=YELLOW).next_to(arrow, UP)
self.play(GrowArrow(arrow), Write(label))
```

## Graph / DiGraph — 圖論視覺化 (Graph Theory)

內建自動佈局的圖形 mobjects：

```python
# 無向圖 (Undirected graph)
g = Graph(
    vertices=[1, 2, 3, 4, 5],
    edges=[(1, 2), (2, 3), (3, 4), (4, 5), (5, 1), (1, 3)],
    layout="spring",  # 或是 "circular", "kamada_kawai", "planar", "tree"
    labels=True,
    vertex_config={"fill_color": PRIMARY},
    edge_config={"stroke_color": SUBTLE},
)
self.play(Create(g))

# 有向圖 (Directed graph)
dg = DiGraph(
    vertices=["A", "B", "C"],
    edges=[("A", "B"), ("B", "C"), ("C", "A")],
    layout="circular",
    labels=True,
    edge_config={("A", "B"): {"stroke_color": RED}},
)

# 動態添加/移除頂點和邊
self.play(g.animate.add_vertices(6, positions={6: RIGHT * 2}))
self.play(g.animate.add_edges((1, 6)))
self.play(g.animate.remove_vertices(3))
```

佈局演算法：`"spring"`, `"circular"`, `"kamada_kawai"`, `"planar"`, `"spectral"`, `"tree"`（對於有根樹，請指定 `root=`）。

## ArrowVectorField / StreamLines — 向量場 (Vector Fields)

```python
# 箭頭場：顯示每個點方向的箭頭
field = ArrowVectorField(
    lambda pos: np.array([-pos[1], pos[0], 0]),  # 旋轉場
    x_range=[-3, 3], y_range=[-3, 3],
    colors=[BLUE, GREEN, YELLOW, RED]
)
self.play(Create(field))

# 流線：場中流動的粒子軌跡
stream = StreamLines(
    lambda pos: np.array([-pos[1], pos[0], 0]),
    stroke_width=2, max_anchors_per_line=30
)
self.add(stream)
stream.start_animation(warm_up=True, flow_speed=1.5)
self.wait(3)
stream.end_animation()
```

適用場景：電磁場、流體流動、梯度場、常微分方程相圖。

## ComplexPlane / PolarPlane

```python
# 帶有實部/虛部 (Re/Im) 標籤的複數平面
cplane = ComplexPlane().add_coordinates()
dot = Dot(cplane.n2p(2 + 1j), color=YELLOW)
label = Text("2+i", font_size=20).next_to(dot, UR, buff=0.1)

# 對平面套用複變函數
self.play(cplane.animate.apply_complex_function(lambda z: z**2), run_time=3)

# 極坐標平面
polar = PolarPlane(radius_max=3).add_coordinates()
```
