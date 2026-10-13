# 攝影機與 3D (Camera and 3D) 參考指南

## MovingCameraScene (2D 攝影機控制)

```python
class ZoomExample(MovingCameraScene):
    def construct(self):
        circle = Circle(radius=2, color=BLUE)
        self.play(Create(circle))
        # 放大 (Zoom in)
        self.play(self.camera.frame.animate.set(width=4).move_to(circle.get_top()), run_time=2)
        self.wait(2)
        # 縮小回原位 (Zoom back out)
        self.play(self.camera.frame.animate.set(width=14.222).move_to(ORIGIN), run_time=2)
```

### 攝影機操作

```python
self.camera.frame.animate.set(width=6)     # 放大
self.camera.frame.animate.set(width=20)    # 縮小
self.camera.frame.animate.move_to(target)  # 平移 (Pan)
self.camera.frame.save_state()             # 儲存目前狀態
self.play(Restore(self.camera.frame))      # 恢復狀態
```

## ThreeDScene (3D 場景)

```python
class ThreeDExample(ThreeDScene):
    def construct(self):
        self.set_camera_orientation(phi=60*DEGREES, theta=-45*DEGREES)
        axes = ThreeDAxes()
        surface = Surface(
            lambda u, v: axes.c2p(u, v, np.sin(u) * np.cos(v)),
            u_range=[-PI, PI], v_range=[-PI, PI], resolution=(30, 30)
        )
        surface.set_color_by_gradient(BLUE, GREEN, YELLOW)
        self.play(Create(axes), Create(surface))
        self.begin_ambient_camera_rotation(rate=0.2)
        self.wait(5)
        self.stop_ambient_camera_rotation()
```

### 3D 攝影機控制

```python
self.set_camera_orientation(phi=70*DEGREES, theta=-45*DEGREES)
self.move_camera(phi=45*DEGREES, theta=30*DEGREES, run_time=2)
self.begin_ambient_camera_rotation(rate=0.2)
```

### 3D Mobjects

```python
sphere = Sphere(radius=1).set_color(BLUE).set_opacity(0.7)
cube = Cube(side_length=2, fill_color=GREEN, fill_opacity=0.5)
arrow = Arrow3D(start=ORIGIN, end=[2, 1, 1], color=RED)
# 面向攝影機的 2D 文字：
label = Text("標籤", font_size=30)
self.add_fixed_in_frame_mobjects(label)
```

### 參數曲線 (Parametric Curves)

```python
helix = ParametricFunction(
    lambda t: [np.cos(t), np.sin(t), t / (2*PI)],
    t_range=[0, 4*PI], color=YELLOW
)
```

## 何時使用 3D
- 曲面、向量場、空間幾何、3D 變換
## 何時「不」使用 3D
- 2D 概念、文字密集的場景、平面數據（長條圖、時間序列）

## ZoomedScene —— 局部放大圖

在保持全景可見的同時，顯示某個細節的放大圖：

```python
class ZoomExample(ZoomedScene):
    def __init__(self, **kwargs):
        super().__init__(
            zoom_factor=0.3,           # 放大框覆蓋場景的比例
            zoomed_display_height=3,   # 放大圖的大小
            zoomed_display_width=3,
            zoomed_camera_frame_starting_position=ORIGIN,
            **kwargs
        )

    def construct(self):
        self.camera.background_color = BG
        # ... 建立您的場景內容 ...

        # 啟動放大功能
        self.activate_zooming()

        # 將放大框移動到感興趣的點
        self.play(self.zoomed_camera.frame.animate.move_to(detail_point))
        self.wait(2)

        # 關閉放大功能
        self.play(self.get_zoomed_display_pop_out_animation(), rate_func=lambda t: smooth(1-t))
```

使用案例：放大方程式中的特定項、展示圖表中的微小細節、放大圖表中的某個區域。

## LinearTransformationScene —— 線性代數

預建場景，包含基底向量和網格，用於視覺化矩陣變換：

```python
class LinearTransformExample(LinearTransformationScene):
    def __init__(self, **kwargs):
        super().__init__(
            show_coordinates=True,
            show_basis_vectors=True,
            **kwargs
        )

    def construct(self):
        matrix = [[2, 1], [1, 1]]

        # 在套用變換前加入一個向量
        vector = self.get_vector([1, 2], color=YELLOW)
        self.add_vector(vector)

        # 套用矩陣變換 —— 網格、基底向量以及您的向量都會隨之變換
        self.apply_matrix(matrix)
        self.wait(2)
```

這能產生 3Blue1Brown 招牌的「線性代數的本質」視覺風格 —— 網格線變形、基底向量伸展、透過面積變化視覺化行列式。
