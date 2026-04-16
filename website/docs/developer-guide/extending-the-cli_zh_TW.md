---
sidebar_position: 8
title: "擴充 CLI"
description: "建立擴充 Hermes TUI 的包裝式 CLI，包含自訂元件、快捷鍵以及版面配置變更"
---

# 擴充 CLI

Hermes 在 `HermesCLI` 上公開了受保護的擴充掛鉤（Extension hooks），讓包裝式 CLI 可以新增元件、快捷鍵以及自訂版面配置，而無需覆寫長達 1000 多行的 `run()` 方法。這可以讓您的擴充功能與內部變更保持解耦。

## 擴充點

目前提供五個擴充接縫（Extension seams）：

| 掛鉤 | 用途 | 覆寫時機... |
|------|---------|------------------|
| `_get_extra_tui_widgets()` | 在版面配置中注入元件 | 您需要持久的 UI 元素（面板、狀態列、迷你播放器） |
| `_register_extra_tui_keybindings(kb, *, input_area)` | 新增鍵盤快捷鍵 | 您需要熱鍵（切換面板、傳輸控制、模態快捷鍵） |
| `_build_tui_layout_children(**widgets)` | 完全控制元件順序 | 您需要重新排序或包裝現有元件（較罕見） |
| `process_command()` | 新增自訂斜線指令 | 您需要處理 `/mycommand`（預有的掛鉤） |
| `_build_tui_style_dict()` | 自訂 prompt_toolkit 樣式 | 您需要自訂顏色或樣式（預有的掛鉤） |

前三個是新增的受保護掛鉤，後兩個是原有的。

## 快速上手：包裝式 CLI

```python
#!/usr/bin/env python3
"""my_cli.py — 擴充 Hermes 的包裝式 CLI 範例。"""

from cli import HermesCLI
from prompt_toolkit.layout import FormattedTextControl, Window
from prompt_toolkit.filters import Condition


class MyCLI(HermesCLI):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self._panel_visible = False

    def _get_extra_tui_widgets(self):
        """在狀態列上方新增一個可切換的資訊面板。"""
        cli_ref = self
        return [
            Window(
                FormattedTextControl(lambda: "📊 我的自訂面板內容"),
                height=1,
                filter=Condition(lambda: cli_ref._panel_visible),
            ),
        ]

    def _register_extra_tui_keybindings(self, kb, *, input_area):
        """按 F2 切換自訂面板。"""
        cli_ref = self

        @kb.add("f2")
        def _toggle_panel(event):
            cli_ref._panel_visible = not cli_ref._panel_visible

    def process_command(self, cmd: str) -> bool:
        """新增一個 /panel 斜線指令。"""
        if cmd.strip().lower() == "/panel":
            self._panel_visible = not self._panel_visible
            state = "顯示" if self._panel_visible else "隱藏"
            print(f"面板現在已{state}")
            return True
        return super().process_command(cmd)


if __name__ == "__main__":
    cli = MyCLI()
    cli.run()
```

執行方式：

```bash
cd ~/.hermes/hermes-agent
source .venv/bin/activate
python my_cli.py
```

## 掛鉤參考

### `_get_extra_tui_widgets()`

傳回一個要插入 TUI 版面配置的 prompt_toolkit 元件列表。元件會出現在**分隔區域（Spacer）與狀態列之間** — 也就是輸入區域上方，但在主輸出區域下方。

```python
def _get_extra_tui_widgets(self) -> list:
    return []  # 預設：無額外元件
```

每個元件都應該是一個 prompt_toolkit 容器（例如：`Window`, `ConditionalContainer`, `HSplit`）。使用 `ConditionalContainer` 或 `filter=Condition(...)` 來讓元件可切換顯示。

```python
from prompt_toolkit.layout import ConditionalContainer, Window, FormattedTextControl
from prompt_toolkit.filters import Condition

def _get_extra_tui_widgets(self):
    return [
        ConditionalContainer(
            Window(FormattedTextControl("狀態：已連線"), height=1),
            filter=Condition(lambda: self._show_status),
        ),
    ]
```

### `_register_extra_tui_keybindings(kb, *, input_area)`

在 Hermes 註冊其自身快捷鍵之後、建立版面配置之前呼叫。將您的快捷鍵新增至 `kb`。

```python
def _register_extra_tui_keybindings(self, kb, *, input_area):
    pass  # 預設：無額外快捷鍵
```

參數：
- **`kb`** — prompt_toolkit 應用程式的 `KeyBindings` 實例
- **`input_area`** — 主 `TextArea` 元件，如果您需要讀取或操作使用者輸入

```python
def _register_extra_tui_keybindings(self, kb, *, input_area):
    cli_ref = self

    @kb.add("f3")
    def _clear_input(event):
        input_area.text = ""

    @kb.add("f4")
    def _insert_template(event):
        input_area.text = "/search "
```

**避免與內建快捷鍵衝突**：`Enter` (送出)、`Escape Enter` (換行)、`Ctrl-C` (中斷)、`Ctrl-D` (結束)、`Tab` (接受自動建議)。功能鍵 F2 以上以及 Ctrl 組合鍵通常是安全的。

### `_build_tui_layout_children(**widgets)`

僅在您需要完全控制元件順序時覆寫此方法。大多數擴充功能應改用 `_get_extra_tui_widgets()`。

```python
def _build_tui_layout_children(self, *, sudo_widget, secret_widget,
    approval_widget, clarify_widget, spinner_widget, spacer,
    status_bar, input_rule_top, image_bar, input_area,
    input_rule_bot, voice_status_bar, completions_menu) -> list:
```

預設實作傳回：

```python
[
    Window(height=0),       # 定位點 (Anchor)
    sudo_widget,            # sudo 密碼提示 (條件式)
    secret_widget,          # 秘密輸入提示 (條件式)
    approval_widget,        # 危險指令核准 (條件式)
    clarify_widget,         # 釐清問題 UI (條件式)
    spinner_widget,         # 思考中圖示 (條件式)
    spacer,                 # 填滿剩餘垂直空間
    *self._get_extra_tui_widgets(),  # 您的元件放在這裡
    status_bar,             # 模型/Token/上下文狀態列
    input_rule_top,         # ─── 輸入框上方邊界
    image_bar,              # 附加圖片指示器
    input_area,             # 使用者文字輸入框
    input_rule_bot,         # ─── 輸入框下方邊界
    voice_status_bar,       # 語音模式狀態 (條件式)
    completions_menu,       # 自動完成下拉選單
]
```

## 版面配置圖示

預設版面配置由上至下依序為：

1. **輸出區域** — 捲動的對話歷史記錄
2. **分隔區域 (Spacer)**
3. **額外元件** — 來自 `_get_extra_tui_widgets()`
4. **狀態列** — 模型、內容百分比、經過時間
5. **圖片列** — 附加圖片數量
6. **輸入區域** — 使用者提示詞
7. **語音狀態** — 錄音指示器
8. **完成選單** — 自動完成建議

## 提示

- **狀態變更後重新整理顯示**：呼叫 `self._invalidate()` 來觸發 prompt_toolkit 重新繪製。
- **存取代理人狀態**：可以使用 `self.agent`, `self.model`, `self.conversation_history` 等。
- **自訂樣式**：覆寫 `_build_tui_style_dict()` 並為您的自訂樣式類別新增項目。
- **斜線指令**：覆寫 `process_command()`，處理您的指令，其餘則呼叫 `super().process_command(cmd)`。
- **除非絕對必要，否則請勿覆寫 `run()`** — 擴充掛鉤的存在就是為了避免這種耦合。
