---
title: 視覺與圖片貼上
description: 將剪貼簿中的圖片直接貼上至 Hermes CLI，進行多模態視覺分析。
sidebar_label: 視覺與圖片貼上
sidebar_position: 7
---

# 視覺與圖片貼上

Hermes Agent 支援 **多模態視覺** — 您可以直接將剪貼簿中的圖片貼上到 CLI 中，並要求 Agent 進行分析、描述或處理。圖片會以 base64 編碼的內容區塊發送給模型，因此任何具備視覺能力的模型都可以處理它們。

## 運作方式

1. 將圖片複製到剪貼簿 (螢幕截圖、瀏覽器圖片等)
2. 使用以下方法之一附加圖片
3. 輸入您的問題並按 Enter
4. 圖片會以 `[📎 Image #1]` 徽章的形式顯示在輸入框上方
5. 送出後，圖片會作為視覺內容區塊發送到模型

您可以在發送前附加多張圖片 — 每張圖片都會有自己的徽章。按 `Ctrl+C` 可清除所有附加的圖片。

圖片會以帶有時間戳記的檔名儲存為 PNG 檔案，路徑為 `~/.hermes/images/`。

## 貼上方法

附加圖片的方式取決於您的終端機環境。並非所有方法都適用於所有地方 — 以下是詳細說明：

### `/paste` 指令

**最可靠的方法。適用於所有環境。**

```
/paste
```

輸入 `/paste` 並按 Enter。Hermes 會檢查您的剪貼簿是否有圖片並將其附加。這在所有環境中都有效，因為它明確呼叫了剪貼簿後端 — 無需擔心終端機快捷鍵被攔截。

### Ctrl+V / Cmd+V (括號式貼上)

當您貼上剪貼簿中的文字且同時含有圖片時，Hermes 會自動檢查是否也有圖片。這在以下情況有效：
- 您的剪貼簿同時包含 **文字和圖片** (某些應用程式在複製時會將兩者都放入剪貼簿)
- 您的終端機支援括號式貼上 (大部分現代終端機都支援)

:::warning 警告
如果您的剪貼簿 **只有圖片** (沒有文字)，Ctrl+V 在大多數終端機中不會有任何反應。終端機只能貼上文字 — 目前沒有標準機制可以貼上二進位圖片數據。請改用 `/paste` 或 Alt+V。
:::

### Alt+V

Alt 組合鍵通常可以穿透大多數終端機模擬器 (它們會以 ESC + 鍵的形式發送，而不是被攔截)。按 `Alt+V` 即可檢查剪貼簿是否有圖片。

:::caution 注意
**不適用於 VSCode 的整合終端機。** VSCode 會攔截許多 Alt+鍵組合用於其自身的 UI。請改用 `/paste`。
:::

### Ctrl+V (原始模式 — 僅限 Linux)

在 Linux 桌面終端機 (GNOME Terminal, Konsole, Alacritty 等) 上，`Ctrl+V` **不是** 貼上快捷鍵 — `Ctrl+Shift+V` 才是。因此 `Ctrl+V` 會將原始位元組發送到應用程式，Hermes 會捕捉它並檢查剪貼簿。這僅適用於具有 X11 或 Wayland 剪貼簿存取權限的 Linux 桌面終端機。

## 平台相容性

| 環境 | `/paste` | Ctrl+V 文字+圖片 | Alt+V | 備註 |
|---|:---:|:---:|:---:|---|
| **macOS Terminal / iTerm2** | ✅ | ✅ | ✅ | 最佳體驗 — `osascript` 始終可用 |
| **Linux X11 桌面** | ✅ | ✅ | ✅ | 需要 `xclip` (`apt install xclip`) |
| **Linux Wayland 桌面** | ✅ | ✅ | ✅ | 需要 `wl-paste` (`apt install wl-clipboard`) |
| **WSL2 (Windows Terminal)** | ✅ | ✅¹ | ✅ | 使用 `powershell.exe` — 無需額外安裝 |
| **VSCode Terminal (本地)** | ✅ | ✅¹ | ❌ | VSCode 會攔截 Alt+鍵 |
| **VSCode Terminal (SSH)** | ❌² | ❌² | ❌ | 無法存取遠端剪貼簿 |
| **SSH 終端機 (任何)** | ❌² | ❌² | ❌² | 無法存取遠端剪貼簿 |

¹ 僅當剪貼簿同時包含文字和圖片時 (僅有圖片的剪貼簿 = 無反應)
² 請參閱下方的 [SSH 與遠端對話](#ssh-與遠端對話)

## 平台特定設定

### macOS

**無需設定。** Hermes 使用 `osascript` (macOS 內建) 來讀取剪貼簿。為了獲得更快的效能，您可以選擇安裝 `pngpaste`：

```bash
brew install pngpaste
```

### Linux (X11)

安裝 `xclip`：

```bash
# Ubuntu/Debian
sudo apt install xclip

# Fedora
sudo dnf install xclip

# Arch
sudo pacman -S xclip
```

### Linux (Wayland)

現代 Linux 桌面 (Ubuntu 22.04+, Fedora 34+) 通常預設使用 Wayland。請安裝 `wl-clipboard`：

```bash
# Ubuntu/Debian
sudo apt install wl-clipboard

# Fedora
sudo dnf install wl-clipboard

# Arch
sudo pacman -S wl-clipboard
```

:::tip 如何檢查您是否在使用 Wayland
```bash
echo $XDG_SESSION_TYPE
# "wayland" = Wayland, "x11" = X11, "tty" = 無顯示伺服器
```
:::

### WSL2

**無需額外設定。** Hermes 會自動偵測 WSL2 (透過 `/proc/version`)，並使用 `powershell.exe` 透過 .NET 的 `System.Windows.Forms.Clipboard` 存取 Windows 剪貼簿。這是 WSL2 內建的 Windows 互通功能 — `powershell.exe` 預設即為可用。

剪貼簿數據會透過 stdout 以 base64 編碼的 PNG 格式傳輸，因此不需要進行檔案路徑轉換或使用暫存檔。

:::info WSLg 說明
如果您正在執行 WSLg (具備 GUI 支援的 WSL2)，Hermes 會先嘗試 PowerShell 路徑，失敗後退而使用 `wl-paste`。WSLg 的剪貼簿橋接僅支援 BMP 格式圖片 — Hermes 會使用 Pillow (如果已安裝) 或 ImageMagick 的 `convert` 指令自動將 BMP 轉換為 PNG。
:::

#### 驗證 WSL2 剪貼簿存取

```bash
# 1. 檢查 WSL 偵測
grep -i microsoft /proc/version

# 2. 檢查 PowerShell 是否可存取
which powershell.exe

# 3. 複製一張圖片，然後執行以下指令檢查
powershell.exe -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Clipboard]::ContainsImage()"
# 應顯示 "True"
```

## SSH 與遠端對話

**剪貼簿貼上無法透過 SSH 運作。** 當您 SSH 進入遠端機器時，Hermes CLI 是在遠端主機上執行。所有的剪貼簿工具 (`xclip`, `wl-paste`, `powershell.exe`, `osascript`) 讀取的都是它們所在機器的剪貼簿 — 也就是遠端伺服器，而非您的在地機器。遠端環境無法存取您本地端的剪貼簿。

### SSH 的替代方案

1. **上傳圖片檔案** — 在本地儲存圖片，透過 `scp`、VSCode 檔案瀏覽器 (拖放) 或任何檔案傳輸方法上傳到遠端伺服器。然後透過路徑引用它。*(計畫在未來版本中加入 `/attach <filepath>` 指令。)*

2. **使用 URL** — 如果圖片可在網路上存取，只需在訊息中貼上 URL。Agent 可以使用 `vision_analyze` 直接查看任何圖片 URL。

3. **X11 轉發 (X11 forwarding)** — 使用 `ssh -X` 連線以轉發 X11。這讓遠端機器上的 `xclip` 可以存取您本地的 X11 剪貼簿。需要在本地端執行 X 伺服器 (macOS 為 XQuartz，Linux X11 桌面則內建)。對於大圖片，速度較慢。

4. **使用通訊平台** — 透過 Telegram、Discord、Slack 或 WhatsApp 向 Hermes 發送圖片。這些平台原生處理圖片上傳，不受剪貼簿或終端機限制的影響。

## 為什麼終端機無法貼上圖片

這是一個常見的困惑，以下是技術解釋：

終端機是 **以文字為基礎** 的介面。當您按 Ctrl+V (或 Cmd+V) 時，終端機模擬器會：

1. 讀取剪貼簿中的 **文字內容**
2. 將其包裹在 [括號式貼上 (bracketed paste)](https://en.wikipedia.org/wiki/Bracketed-paste) 逃逸序列中
3. 透過終端機的文字串流發送給應用程式

如果剪貼簿中只有圖片 (沒有文字)，終端機就沒有內容可以發送。目前沒有標準的終端機逃逸序列可用於傳輸二進位圖片數據。因此終端機不會有任何動作。

這就是為什麼 Hermes 使用獨立的剪貼簿檢查機制 — 它不是透過終端機貼上事件接收圖片數據，而是直接透過子程序呼叫作業系統層級的工具 (`osascript`, `powershell.exe`, `xclip`, `wl-paste`) 來獨立讀取剪貼簿。

## 支援的模型

圖片貼上適用於任何具備視覺能力的模型。圖片會以 OpenAI 視覺內容格式的 base64 編碼數據 URL 發送：

```json
{
  "type": "image_url",
  "image_url": {
    "url": "data:image/png;base64,..."
  }
}
```

大多數現代模型都支援此格式，包括 GPT-4 Vision、Claude (具備視覺能力)、Gemini，以及透過 OpenRouter 提供的開源多模態模型。
