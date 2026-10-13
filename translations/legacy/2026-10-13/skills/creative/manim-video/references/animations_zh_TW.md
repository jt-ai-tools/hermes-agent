# 動畫 (Animations) 參考指南

## 核心概念

動畫是一個 Python 物件，它會計算 mobject 隨時間變化的中間視覺狀態。動畫是傳遞給 `self.play()` 的物件，而非函式。

`run_time` 控制動畫時長（以秒為單位，預設為 1 秒）。對於重要的動畫，請務必明確指定此參數。

## 建立動畫 (Creation Animations)

```python
self.play(Create(circle))          # 描繪輪廓
self.play(Write(equation))         # 模擬手寫（適用於 Text/MathTex）
self.play(FadeIn(group))           # 不透明度從 0 變為 1
self.play(GrowFromCenter(dot))     # 從中心開始，縮放比例從 0 變為 1
self.play(DrawBorderThenFill(sq))  # 先畫輪廓，再填充顏色
```

## 移除動畫 (Removal Animations)

```python
self.play(FadeOut(mobject))         # 不透明度從 1 變為 0
self.play(Uncreate(circle))        # Create 的反向動作
self.play(ShrinkToCenter(group))   # 縮放比例從 1 變為 0
```

## 變換動畫 (Transform Animations)

```python
# Transform —— 原地修改原始物件
self.play(Transform(circle, square))
# 動畫後：circle 物件變成了 square（同一個物件，新的外觀）

# ReplacementTransform —— 用新物件替換舊物件
self.play(ReplacementTransform(circle, square))
# 動畫後：circle 已移除，square 出現在螢幕上

# TransformMatchingTex —— 智慧型方程式變形
eq1 = MathTex(r"a^2 + b^2")
eq2 = MathTex(r"a^2 + b^2 = c^2")
self.play(TransformMatchingTex(eq1, eq2))
```

**至關重要：** 在 `Transform(A, B)` 之後，變數 `A` 指向螢幕上的 mobject。變數 `B` 則不在螢幕上。如果您之後想對 `B` 進行操作，請使用 `ReplacementTransform`。

## .animate 語法

```python
self.play(circle.animate.set_color(RED))
self.play(circle.animate.shift(RIGHT * 2).scale(0.5))  # 鏈式呼叫多個操作
```

## 其他建立動畫

```python
self.play(GrowFromPoint(circle, LEFT * 3))     # 從特定點開始，縮放比例從 0 變為 1
self.play(GrowFromEdge(rect, DOWN))             # 從某一邊緣生長
self.play(SpinInFromNothing(square))            # 旋轉同時放大（預設旋轉 PI/2）
self.play(GrowArrow(arrow))                     # 從起點到箭頭端生長箭頭
```

## 移動動畫 (Movement Animations)

```python
# 沿著任意路徑移動 mobject
path = Arc(radius=2, angle=PI)
self.play(MoveAlongPath(dot, path), run_time=2)

# 旋轉（作為 Transform，而非 .animate —— 支援 about_point）
self.play(Rotate(square, angle=PI / 2, about_point=ORIGIN), run_time=1.5)

# 旋轉中（持續旋轉，updater 風格 —— 適用於旋轉物體）
self.play(Rotating(gear, angle=TAU, run_time=4, rate_func=linear))
```

`MoveAlongPath` 接受任何 `VMobject` 作為路徑 —— 可使用 `Arc`、`CubicBezier`、`Line` 或自定義 `VMobject`。位置是透過 `path.point_from_proportion()` 計算的。

## 強調動畫 (Emphasis Animations)

```python
self.play(Indicate(mobject))             # 短暫的黃色閃爍並放大
self.play(Circumscribe(mobject))         # 在物件周圍畫一個矩形
self.play(Flash(point))                  # 放射狀閃爍
self.play(Wiggle(mobject))               # 左右搖擺
```

## 速率函數 (Rate Functions)

```python
self.play(FadeIn(mob), rate_func=smooth)          # 預設：淡入/淡出（平滑）
self.play(FadeIn(mob), rate_func=linear)           # 等速
self.play(FadeIn(mob), rate_func=rush_into)        # 先慢後快
self.play(FadeIn(mob), rate_func=rush_from)        # 先快後慢
self.play(FadeIn(mob), rate_func=there_and_back)   # 做完動畫後反向回原狀
```

## 動畫組合 (Composition)

```python
# 同步進行
self.play(FadeIn(title), Create(circle), run_time=2)

# 帶延遲的動畫群組 (AnimationGroup)
self.play(AnimationGroup(*[FadeIn(i) for i in items], lag_ratio=0.2))

# 逐一啟動 (LaggedStart)
self.play(LaggedStart(*[Write(l) for l in lines], lag_ratio=0.3, run_time=3))

# 接續進行 (Succession，在一次 play 呼叫中依序執行)
self.play(Succession(FadeIn(title), Wait(0.5), Write(subtitle)))
```

## 更新器 (Updaters)

```python
tracker = ValueTracker(0)
dot = Dot().add_updater(lambda m: m.move_to(axes.c2p(tracker.get_value(), 0)))
self.play(tracker.animate.set_value(5), run_time=3)
```

## 字幕 (Subtitles)

```python
# 方法 1：獨立新增
self.add_subcaption("關鍵洞察", duration=2)
self.play(Write(equation), run_time=2.0)

# 方法 2：內聯新增
self.play(Write(equation), subcaption="關鍵洞察", subcaption_duration=2)
```

Manim 會自動生成 `.srt` 字幕檔案。為了無障礙體驗，請務必加上子標題。

## 時機模式 (Timing Patterns)

```python
# 揭曉後的停頓
self.play(Write(key_equation), run_time=2.0)
self.wait(2.0)

# 調暗與聚焦 (Dim-and-focus)
self.play(old_content.animate.set_opacity(0.3), FadeIn(new_content))

# 乾淨退出
self.play(FadeOut(Group(*self.mobjects)), run_time=0.5)
self.wait(0.3)
```

## 反應式 Mobjects：always_redraw()

每影格都從頭重新構建一個 mobject —— 當其幾何形狀取決於其他正在進行動畫的物件時非常有用：

```python
# 會隨著正方形縮放而調整的括號 (Brace)
brace = always_redraw(Brace, square, UP)
self.add(brace)
self.play(square.animate.scale(2))  # 括號會自動調整

# 跟隨移動點的水平線
h_line = always_redraw(lambda: axes.get_h_line(dot.get_left()))

# 始終保持在另一個 mobject 旁邊的標籤
label = always_redraw(lambda: Text("這裡", font_size=20).next_to(dot, UP, buff=0.2))
```

注意：`always_redraw` 每影格都會重新建立物件。對於簡單的屬性追蹤，使用 `add_updater` 更有效率（開銷較小）：
```python
label.add_updater(lambda m: m.next_to(dot, UP))
```

## TracedPath —— 軌跡追蹤

繪製一個點所經過的路徑：

```python
dot = Dot(color=YELLOW)
path = TracedPath(dot.get_center, stroke_color=YELLOW, stroke_width=2)
self.add(dot, path)
self.play(dot.animate.shift(RIGHT * 3 + UP * 2), run_time=2)
# path 會顯示點移動後留下的痕跡

# 消失的痕跡（隨時間消散）：
path = TracedPath(dot.get_center, dissipating_time=0.5, stroke_opacity=[0, 1])
```

使用案例：梯度下降路徑、行星軌道、函數追蹤、粒子軌跡。

## FadeTransform —— 更平滑的交叉淡入淡出

`Transform` 在變形時有時會產生不好看的中間扭曲過程。`FadeTransform` 則會進行位置匹配的交叉淡入淡出 —— 當來源與目標外觀差異較大時使用：

```python
# 不好看：Transform 會將圓形扭曲成一團再變成正方形
self.play(Transform(circle, square))

# 平滑：FadeTransform 乾淨俐落地進行交叉淡入淡出
self.play(FadeTransform(circle, square))

# FadeTransformPieces：針對子物件 (submobject) 的 FadeTransform
self.play(FadeTransformPieces(group1, group2))

# TransformFromCopy：針對副本製作動畫，同時保留原始物件可見
self.play(TransformFromCopy(source, target))
# source 仍保留在螢幕上，其副本會變形為 target
```

**推薦做法：** 對於不同形狀，將 `FadeTransform` 作為預設選擇。僅在形狀相似（圓形→橢圓、方程式→方程式）時使用 `Transform`/`ReplacementTransform`。

## ApplyMatrix —— 線性變換視覺化

在 mobjects 上製作矩陣變換的動畫：

```python
# 將 2x2 矩陣套用到網格
matrix = [[2, 1], [1, 1]]
self.play(ApplyMatrix(matrix, number_plane), run_time=2)

# 也適用於個別 mobjects
self.play(ApplyMatrix([[0, -1], [1, 0]], square))  # 旋轉 90 度
```

與 `LinearTransformationScene` 搭配使用 —— 詳見 `camera-and-3d.md`。

## squish_rate_func —— 時間窗口交錯

將任何速率函數壓縮到動畫內的特定時間窗口中。無需 `LaggedStart` 即可實現重疊交錯效果：

```python
self.play(
    FadeIn(a, rate_func=squish_rate_func(smooth, 0, 0.5)),    # 0% 到 50%
    FadeIn(b, rate_func=squish_rate_func(smooth, 0.25, 0.75)), # 25% 到 75%
    FadeIn(c, rate_func=squish_rate_func(smooth, 0.5, 1.0)),  # 50% 到 100%
    run_time=2
)
```

當您需要精確控制重疊時，這比 `LaggedStart` 更精準。

## 其他速率函數 (Rate Functions)

```python
from manim import (
    smooth, linear, rush_into, rush_from,
    there_and_back, there_and_back_with_pause,
    running_start, double_smooth, wiggle,
    lingering, exponential_decay, not_quite_there,
    squish_rate_func
)

# running_start：在向前衝之前先向後拉（預備動作）
self.play(FadeIn(mob, rate_func=running_start))

# there_and_back_with_pause：衝過去，停一下，再回來
self.play(mob.animate.shift(UP), rate_func=there_and_back_with_pause)

# not_quite_there：動畫在完成一定比例後停止
self.play(FadeIn(mob, rate_func=not_quite_there(0.7)))
```

## ShowIncreasingSubsets / ShowSubmobjectsOneByOne

逐步揭曉群組成員 —— 非常適合演算法視覺化：

```python
# 逐一揭曉陣列元素
array = Group(*[Square() for _ in range(8)]).arrange(RIGHT)
self.play(ShowIncreasingSubsets(array), run_time=3)

# 逐一顯示子物件，並帶有交錯出現的效果
self.play(ShowSubmobjectsOneByOne(code_lines), run_time=4)
```

## ShowPassingFlash

一道閃光沿著路徑移動：

```python
# 閃光沿著曲線移動
self.play(ShowPassingFlash(curve.copy().set_color(YELLOW), time_width=0.3))

# 非常適用於：資料流、電子訊號、網路流量
```
