# 常見問題排除 (Troubleshooting)

## LaTeX 錯誤

**缺少原始字串 (Raw string)** (最常見的錯誤)：
```python
# 錯誤：MathTex("\\frac{1}{2}")  -- \\f 會被視為換頁符
# 正確：MathTex(r"\frac{1}{2}")
```

**括號不匹配**：`MathTex(r"\frac{1}{2")` -- 缺少右括號。

**未安裝 LaTeX**：`which pdflatex` -- 請安裝 texlive-full 或 mactex。

**缺少套件**：添加到導言區 (preamble)：
```python
tex_template = TexTemplate()
tex_template.add_to_preamble(r"\usepackage{mathrsfs}")
MathTex(r"\mathscr{L}", tex_template=tex_template)
```

## VGroup TypeError

**錯誤：** `TypeError: Only values of type VMobject can be added as submobjects of VGroup`

**原因：** `Text()` 物件是 `Mobject`，而不是 `VMobject`。在 Manim CE v0.20+ 中，將 `Text` 與形狀混合放入 `VGroup` 會失敗。

```python
# 錯誤：Text 不是 VMobject
group = VGroup(circle, Text("標籤"))

# 正確：對於混合類型請使用 Group
group = Group(circle, Text("標籤"))

# 正確：VGroup 僅適用於純形狀
shapes = VGroup(circle, square, arrow)

# 正確：MathTex 是 VMobject — 可以使用 VGroup
equations = VGroup(MathTex(r"a"), MathTex(r"b"))
```

**原則：** 如果群組包含任何 `Text()`，請使用 `Group`。如果全是形狀或全是 `MathTex`，則 `VGroup` 沒問題。

**淡出所有物件 (FadeOut everything)：** 務必使用 `Group(*self.mobjects)`，而不是 `VGroup(*self.mobjects)`：
```python
self.play(FadeOut(Group(*self.mobjects)))  # 對於混合類型較安全
```

## Group 不支援 save_state() / restore()

**錯誤：** `NotImplementedError: Please override in a child class.`

**原因：** `Group.save_state()` 和 `Group.restore()` 在 Manim CE v0.20+ 中未實作。只有 `VGroup` 和個別的 `Mobject` 子類別支援 save/restore。

```python
# 錯誤：Group 不支援 save_state
group = Group(circle, Text("標籤"))
group.save_state()  # NotImplementedError!

# 正確：使用 FadeIn 配合 shift/scale，而不是 save_state/restore
self.play(FadeIn(group, shift=UP * 0.3, scale=0.8))

# 正確：或者在個別的 VMobjects 上使用 save/restore
circle.save_state()
self.play(circle.animate.shift(RIGHT))
self.play(Restore(circle))
```

## letter_spacing 不是有效的參數

**錯誤：** `TypeError: Mobject.__init__() got an unexpected keyword argument 'letter_spacing'`

**原因：** `Text()` 不接受 `letter_spacing`。Manim 使用 Pango 進行文字渲染，且未在 `Text()` 上公開字距控制。

```python
# 錯誤
Text("HERMES", letter_spacing=6)

# 正確：使用 MarkupText 配合 Pango 屬性來控制間距
MarkupText('<span letter_spacing="6000">HERMES</span>', font_size=18)
# 注意：Pango 的 letter_spacing 單位是 1/1024 點 (point)
```

## 動畫錯誤

**不可見的動畫** -- mobject 從未被添加到場景中：
```python
# 錯誤：circle = Circle(); self.play(circle.animate.set_color(RED))
# 正確：self.play(Create(circle)); self.play(circle.animate.set_color(RED))
```

**轉換 (Transform) 混淆** -- 在 `Transform(A, B)` 之後，畫面上的是 A，而 B 不在畫面上。如果你想要 B，請使用 `ReplacementTransform`。

**重複動畫** -- 在同一個 `play()` 中對同一個 mobject 進行兩次操作：
```python
# 錯誤：self.play(c.animate.shift(RIGHT), c.animate.set_color(RED))
# 正確：self.play(c.animate.shift(RIGHT).set_color(RED))
```

**更新器 (Updater) 與動畫衝突**：
```python
mob.suspend_updating()
self.play(mob.animate.shift(RIGHT))
mob.resume_updating()
```

## 渲染問題

**輸出模糊**：使用了 `-ql` (480p)。最終輸出請切換至 `-qm`/`-qh`。

**渲染緩慢**：開發期間請使用 `-ql`。降低曲面 (Surface) 解析度。縮短 `self.wait()` 時間。

**輸出未更新 (Stale output)**：使用 `manim -ql --disable_caching script.py Scene`

**ffmpeg 拼接失敗**：所有片段的解析度/FPS/編解碼器必須一致。

## 常見錯誤

**文字在邊緣被裁剪**：`.to_edge()` 時請確保 `buff >= 0.5`。

**文字重疊**：使用 `ReplacementTransform(old, new)`，而不是直接在舊文字上 `Write(new)`。

**畫面太擁擠**：畫面上最多顯示 5-6 個元素。拆分成多個場景或使用不透明度分層。

**缺乏呼吸空間**：揭示內容後至少 `self.wait(1.5)`，關鍵時刻建議 `self.wait(2.0)`。

**缺少背景顏色**：在每個場景中設置 `self.camera.background_color = BG`。

## 調試策略 (Debugging Strategy)

1. 渲染靜態圖：`manim -ql -s script.py Scene` -- 快速檢查佈局
2. 隔離故障場景 -- 僅渲染該場景
3. 將 `self.play()` 替換為 `self.add()` 以立即查看最終狀態
4. 打印位置：`print(mob.get_center())`
5. 清除快取：刪除 `media/` 目錄
