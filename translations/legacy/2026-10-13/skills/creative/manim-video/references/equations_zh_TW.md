# 方程式與 LaTeX 參考指南

## 基礎 LaTeX

```python
eq = MathTex(r"E = mc^2")
eq = MathTex(r"f(x) &= x^2 + 2x + 1 \\ &= (x + 1)^2")  # 多行對齊
```

**務必使用原始字串 (`r""`)。**

## 逐步推導 (Step-by-Step Derivations)

```python
step1 = MathTex(r"a^2 + b^2 = c^2")
step2 = MathTex(r"a^2 = c^2 - b^2")
self.play(Write(step1), run_time=1.5)
self.wait(1.5)
self.play(TransformMatchingTex(step1, step2), run_time=1.5)
```

## 選擇性著色

```python
eq = MathTex(r"a^2", r"+", r"b^2", r"=", r"c^2")
eq[0].set_color(RED)
eq[4].set_color(GREEN)
```

## 漸進式構建

```python
parts = MathTex(r"f(x)", r"=", r"\sum_{n=0}^{\infty}", r"\frac{f^{(n)}(a)}{n!}", r"(x-a)^n")
self.play(Write(parts[0:2]))
self.wait(0.5)
self.play(Write(parts[2]))
self.wait(0.5)
self.play(Write(parts[3:]))
```

## 突出顯示 (Highlighting)

```python
highlight = SurroundingRectangle(eq[2], color=YELLOW, buff=0.1)
self.play(Create(highlight))
self.play(Indicate(eq[4], color=YELLOW))
```

## 註釋 (Annotation)

```python
brace = Brace(eq, DOWN, color=YELLOW)
label = brace.get_text("基本定理", font_size=24)
self.play(GrowFromCenter(brace), Write(label))
```

## 常見 LaTeX

```python
MathTex(r"\frac{a}{b}")                  # 分數
MathTex(r"\alpha, \beta, \gamma")         # 希臘字母
MathTex(r"\sum_{i=1}^{n} x_i")           # 總和符號
MathTex(r"\int_{0}^{\infty} e^{-x} dx")  # 積分符號
MathTex(r"\vec{v}")                       # 向量
MathTex(r"\lim_{x \to \infty} f(x)")    # 極限符號
```

## 矩陣 (Matrices)

`MathTex` 透過 `amsmath`（預設載入）支援標準的 LaTeX 矩陣環境：

```python
# 中括號矩陣
MathTex(r"\begin{bmatrix} 1 & 0 \\ 0 & 1 \end{bmatrix}")

# 小括號矩陣
MathTex(r"\begin{pmatrix} a & b \\ c & d \end{pmatrix}")

# 行列式（垂直槓）
MathTex(r"\begin{vmatrix} a & b \\ c & d \end{vmatrix}")

# 無分隔符矩陣
MathTex(r"\begin{matrix} x_1 \\ x_2 \\ x_3 \end{matrix}")
```

如果您需要逐一製作矩陣元素的動畫或為個別項目著色，請改用 `IntegerMatrix`、`DecimalMatrix` 或 `MobjectMatrix` —— 詳見 [mobjects_zh_TW.md](mobjects_zh_TW.md)。

## 分段函數 (Cases and Piecewise Functions)

```python
MathTex(r"""
    f(x) = \begin{cases}
        x^2    & \text{如果 } x \geq 0 \\
        -x^2   & \text{如果 } x < 0
    \end{cases}
""")
```

## 對齊環境 (Aligned Environments)

對於需要對齊的多行推導，請在 `MathTex` 內使用 `aligned`：

```python
MathTex(r"""
    \begin{aligned}
        \nabla \cdot \mathbf{E} &= \frac{\rho}{\epsilon_0} \\
        \nabla \cdot \mathbf{B} &= 0 \\
        \nabla \times \mathbf{E} &= -\frac{\partial \mathbf{B}}{\partial t} \\
        \nabla \times \mathbf{B} &= \mu_0 \mathbf{J} + \mu_0 \epsilon_0 \frac{\partial \mathbf{E}}{\partial t}
    \end{aligned}
""")
```

注意：`MathTex` 預設會將內容封裝在 `align*` 中。如果需要，可以使用 `tex_environment` 進行覆寫：
```python
MathTex(r"...", tex_environment="gather*")
```

## 推導模式 (Derivation Pattern)

```python
class DerivationScene(Scene):
    def construct(self):
        self.camera.background_color = BG
        s1 = MathTex(r"ax^2 + bx + c = 0")
        self.play(Write(s1))
        self.wait(1.5)
        s2 = MathTex(r"x^2 + \frac{b}{a}x + \frac{c}{a} = 0")
        s2.next_to(s1, DOWN, buff=0.8)
        self.play(s1.animate.set_opacity(0.4), TransformMatchingTex(s1.copy(), s2))
```

## 針對複雜方程式使用 substrings_to_isolate

對於過於密集、難以手動拆分的方程式，可以使用 `substrings_to_isolate` 告知 Manim 將哪些子字串視為獨立元素進行追蹤：

```python
# 不使用 isolation —— 整個表達式被視為一個整體
lagrangian = MathTex(
    r"\mathcal{L} = \bar{\psi}(i \gamma^\mu D_\mu - m)\psi - \tfrac{1}{4}F_{\mu\nu}F^{\mu\nu}"
)

# 使用 isolation —— 每個命名的子字串都是獨立的子物件 (submobject)
lagrangian = MathTex(
    r"\mathcal{L} = \bar{\psi}(i \gamma^\mu D_\mu - m)\psi - \tfrac{1}{4}F_{\mu\nu}F^{\mu\nu}",
    substrings_to_isolate=[r"\psi", r"D_\mu", r"\gamma^\mu", r"F_{\mu\nu}"]
)
# 現在您可以為個別項著色
lagrangian.set_color_by_tex(r"\psi", BLUE)
lagrangian.set_color_by_tex(r"F_{\mu\nu}", YELLOW)
```

這對於在複雜方程式上使用 `TransformMatchingTex` 至關重要 —— 如果沒有 isolation，在密集表達式上的匹配將會失敗。

## 多行複雜方程式

對於包含多行相關內容的方程式，請將每一行作為獨立參數傳遞：

```python
maxwell = MathTex(
    r"\nabla \cdot \mathbf{E} = \frac{\rho}{\epsilon_0}",
    r"\nabla \times \mathbf{B} = \mu_0\mathbf{J} + \mu_0\epsilon_0\frac{\partial \mathbf{E}}{\partial t}"
).arrange(DOWN)

# 每一行都是獨立的子物件 —— 可以個別製作動畫
self.play(Write(maxwell[0]))
self.wait(1)
self.play(Write(maxwell[1]))
```

## 帶有 key_map 的 TransformMatchingTex

在變換過程中，手動對應來源方程式與目標方程式之間的特定子字串：

```python
eq1 = MathTex(r"A^2 + B^2 = C^2")
eq2 = MathTex(r"A^2 = C^2 - B^2")

self.play(TransformMatchingTex(
    eq1, eq2,
    key_map={"+": "-"},   # 將來源中的 "+" 對應到目標中的 "-"
    path_arc=PI / 2,      # 讓組件沿弧線移動到定位
))
```

## set_color_by_tex —— 根據子字串著色

```python
eq = MathTex(r"E = mc^2")
eq.set_color_by_tex("E", BLUE)
eq.set_color_by_tex("m", RED)
eq.set_color_by_tex("c", GREEN)
```

## 帶有 matched_keys 的 TransformMatchingTex

當匹配的子字串存在歧義時，明確指定哪些部分應該對齊：

```python
kw = dict(font_size=72, t2c={"A": BLUE, "B": TEAL, "C": GREEN})
lines = [
    MathTex(r"A^2 + B^2 = C^2", **kw),
    MathTex(r"A^2 = C^2 - B^2", **kw),
    MathTex(r"A^2 = (C + B)(C - B)", **kw),
    MathTex(r"A = \sqrt{(C + B)(C - B)}", **kw),
]

self.play(TransformMatchingTex(
    lines[0].copy(), lines[1],
    matched_keys=["A^2", "B^2", "C^2"],  # 明確匹配這些部分
    key_map={"+": "-"},                    # 將 + 對應到 -
    path_arc=PI / 2,                       # 讓組件沿弧線移動到定位
))
```

如果沒有 `matched_keys`，動畫會匹配最長公共子字串，這在複雜方程式上可能會產生非預期的結果（例如將一個項中的 "^2 = C^2" 與另一個項匹配）。
