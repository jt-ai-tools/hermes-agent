# 更新器與數值追蹤器 (Updaters and Value Trackers)

## 更新器要解決的問題

一般的動畫是離散的：`self.play()` 從狀態 A 變到狀態 B。但如果你需要連續的關係呢？例如：一個標籤始終懸浮在移動的點上方，或者一條線始終連接兩個動態的點。

如果不使用更新器，你必須在每次 `self.play()` 之前手動重新定位每個相依物件。如果有五段動畫移動一個點，你就得手動調用五次重新定位標籤。漏掉一次，標籤就會停在錯誤的位置。

更新器讓你只需聲明**一次**關係。Manim 會在**每一幀**（根據品質設定，每秒 15-60 幀）調用更新函數，無論場景中發生什麼，都會強制執行該關係。

## ValueTracker：隱形的控制台

ValueTracker 是一個持有單個浮點數的隱形 Mobject。它不會出現在螢幕上。它的存在是為了讓你能夠對它進行**動畫化 (animate)**，同時讓其他物件對其數值做出**反應 (react)**。

把它想像成一個滑桿：你把滑桿從 0 拖到 5，所有連結到它的物件都會即時響應。

```python
tracker = ValueTracker(0)        # 隱形，存儲 0.0
tracker.get_value()              # 讀取：0.0
tracker.set_value(5)             # 寫入：立即跳轉到 5.0
tracker.animate.set_value(5)     # 動畫化：平滑內插到 5.0
```

### 三步驟模式

每個 ValueTracker 的用法都遵循以下模式：

1. **創建追蹤器 (tracker)**（隱形的滑桿）
2. **創建可見物件，並通過更新器讀取追蹤器**
3. **對追蹤器進行動畫化** —— 所有相依物件都會自動更新

```python
# 步驟 1：創建追蹤器
x_tracker = ValueTracker(1)

# 步驟 2：創建相依物件
dot = always_redraw(lambda: Dot(axes.c2p(x_tracker.get_value(), 0), color=YELLOW))
v_line = always_redraw(lambda: axes.get_vertical_line(
    axes.c2p(x_tracker.get_value(), func(x_tracker.get_value())), color=BLUE
))
label = always_redraw(lambda: DecimalNumber(x_tracker.get_value(), font_size=24)
    .next_to(dot, UP))

self.add(dot, v_line, label)

# 步驟 3：對追蹤器進行動畫化 —— 所有內容都會隨之更新
self.play(x_tracker.animate.set_value(5), run_time=3)
```

## 更新器的類型

### Lambda 更新器（最常用）

每一幀運行一次函數，並傳入 mobject 本身：

```python
# 標籤始終保持在點的上方
label.add_updater(lambda m: m.next_to(dot, UP, buff=0.2))

# 線始終連接兩個點
line.add_updater(lambda m: m.put_start_and_end_on(
    point_a.get_center(), point_b.get_center()
))
```

### 基於時間的更新器 (使用 dt)

第二個參數 `dt` 是自上一幀以來的時間（60fps 下約為 0.017s）：

```python
# 持續旋轉
square.add_updater(lambda m, dt: m.rotate(0.5 * dt))

# 持續向右漂移
dot.add_updater(lambda m, dt: m.shift(RIGHT * 0.3 * dt))

# 擺動
dot.add_updater(lambda m, dt: m.move_to(
    axes.c2p(m.get_center()[0], np.sin(self.time))
))
```

對於物理模擬、持續運動和與時間相關的效果，請使用 `dt` 更新器。

### always_redraw：每一幀全量重建

每一幀都從頭開始創建一個新的 mobject。雖然比 `add_updater` 耗能，但適用於 mobject 結構發生變化（而不僅僅是位置/顏色）的情況：

```python
# 隨正方形大小調整的括號 (Brace)
brace = always_redraw(Brace, square, UP)

# 隨函數變化而更新的曲線下方區域
area = always_redraw(lambda: axes.get_area(
    graph, x_range=[0, x_tracker.get_value()], color=BLUE, opacity=0.3
))

# 重新構建文字的計數器標籤
counter = always_redraw(lambda: Text(
    f"n = {int(x_tracker.get_value())}", font_size=24, font="Menlo"
).to_corner(UR))
```

**如何選擇：**
- `add_updater` — 位置、顏色、不透明度變化（效能好，優先選擇）
- `always_redraw` — 當形狀/結構本身發生變化時（效能消耗較大，請節制使用）

## DecimalNumber：顯示即時數值

```python
# 追蹤 ValueTracker 的計數器
tracker = ValueTracker(0)
number = DecimalNumber(0, font_size=48, num_decimal_places=1, color=PRIMARY)
number.add_updater(lambda m: m.set_value(tracker.get_value()))
number.add_updater(lambda m: m.next_to(dot, RIGHT, buff=0.3))

self.add(number)
self.play(tracker.animate.set_value(100), run_time=3)
```

### Variable：帶有標籤的版本

```python
var = Variable(0, Text("x", font_size=24, font="Menlo"), num_decimal_places=2)
self.add(var)
self.play(var.tracker.animate.set_value(PI), run_time=2)
# 顯示：x = 3.14
```

## 移除更新器

```python
# 移除所有更新器
mobject.clear_updaters()

# 暫停更新（在會與更新器衝突的動畫期間）
mobject.suspend_updating()
self.play(mobject.animate.shift(RIGHT))
mobject.resume_updating()

# 移除特定的更新器（如果您保留了對該函數的引用）
def my_updater(m):
    m.next_to(dot, UP)
label.add_updater(my_updater)
# ... 稍後 ...
label.remove_updater(my_updater)
```

## 基於動畫的更新器 (Animation-based updaters)

### UpdateFromFunc / UpdateFromAlphaFunc

這些是**動畫**（傳遞給 `self.play`），而不是持久的更新器：

```python
# 在動畫的每一幀調用一個函數
self.play(UpdateFromFunc(mobject, lambda m: m.next_to(moving_target, UP)), run_time=3)

# 使用 alpha (0 到 1) —— 對於自定義插值非常有用
self.play(UpdateFromAlphaFunc(circle, lambda m, a: m.set_fill(opacity=a)), run_time=2)
```

### turn_animation_into_updater

將單次動畫轉換為持續運行的更新器：

```python
from manim import turn_animation_into_updater

# 這本來只會播放一次 —— 現在它會永遠循環
turn_animation_into_updater(Rotating(gear, rate=PI/4))
self.add(gear)
self.wait(5)  # 齒輪旋轉 5 秒
```

## 實用模式

### 模式 1：點追蹤函數曲線

```python
tracker = ValueTracker(0)
graph = axes.plot(np.sin, x_range=[0, 2*PI], color=PRIMARY)
dot = always_redraw(lambda: Dot(
    axes.c2p(tracker.get_value(), np.sin(tracker.get_value())),
    color=YELLOW
))
tangent = always_redraw(lambda: axes.get_secant_slope_group(
    x=tracker.get_value(), graph=graph, dx=0.01,
    secant_line_color=HIGHLIGHT, secant_line_length=3
))

self.add(graph, dot, tangent)
self.play(tracker.animate.set_value(2*PI), run_time=6, rate_func=linear)
```

### 模式 2：曲線下方即時區域

```python
tracker = ValueTracker(0.5)
area = always_redraw(lambda: axes.get_area(
    graph, x_range=[0, tracker.get_value()],
    color=PRIMARY, opacity=0.3
))
area_label = always_redraw(lambda: DecimalNumber(
    # 數值積分
    sum(func(x) * 0.01 for x in np.arange(0, tracker.get_value(), 0.01)),
    font_size=24
).next_to(axes, RIGHT))

self.add(area, area_label)
self.play(tracker.animate.set_value(4), run_time=5)
```

### 模式 3：連接的圖表

```python
# 可以移動的節點，邊會自動跟隨
node_a = Dot(LEFT * 2, color=PRIMARY)
node_b = Dot(RIGHT * 2, color=SECONDARY)
edge = Line().add_updater(lambda m: m.put_start_and_end_on(
    node_a.get_center(), node_b.get_center()
))
label = Text("邊", font_size=18, font="Menlo").add_updater(
    lambda m: m.move_to(edge.get_center() + UP * 0.3)
)

self.add(node_a, node_b, edge, label)
self.play(node_a.animate.shift(UP * 2), run_time=2)
self.play(node_b.animate.shift(DOWN + RIGHT), run_time=2)
# 邊和標籤會自動跟隨
```

### 模式 4：參數探索

```python
# 探索參數如何改變曲線
a_tracker = ValueTracker(1)
curve = always_redraw(lambda: axes.plot(
    lambda x: a_tracker.get_value() * np.sin(x),
    x_range=[0, 2*PI], color=PRIMARY
))
param_label = always_redraw(lambda: Text(
    f"a = {a_tracker.get_value():.1f}", font_size=24, font="Menlo"
).to_corner(UR))

self.add(curve, param_label)
self.play(a_tracker.animate.set_value(3), run_time=3)
self.play(a_tracker.animate.set_value(0.5), run_time=2)
self.play(a_tracker.animate.set_value(1), run_time=1)
```

## 常見錯誤

1. **更新器與動畫衝突：** 如果一個 mobject 擁有一個設置其位置的更新器，而您又嘗試對其進行移動動畫化，更新器每一幀都會勝出。請先暫停更新 (suspend updating)。

2. **對簡單移動使用 always_redraw：** 如果您只需要重新定位，請使用 `add_updater`。`always_redraw` 每一幀都會重建整個 mobject —— 對於位置追蹤來說過於昂貴且沒必要。

3. **忘記添加到場景：** 更新器僅在場景中的 mobject 上運行。`always_redraw` 創建了 mobject，但您仍然需要執行 `self.add()`。

4. **更新器創建新 mobjects 但未清理：** 如果您的更新器每一幀都創建 Text 物件，它們會不斷堆積。請使用 `always_redraw`（它會處理清理工作）或者原地更新屬性。
