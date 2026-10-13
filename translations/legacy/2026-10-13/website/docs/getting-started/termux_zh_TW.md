---
sidebar_position: 3
title: "Android / Termux"
description: "透過 Termux 在 Android 手機上直接執行 Hermes Agent"
---

# 在 Android 上透過 Termux 執行 Hermes

這是透過 [Termux](https://termux.dev/) 在 Android 手機上直接執行 Hermes Agent 經過測試的路徑。

它能為你在手機上提供一個可運作的本地 CLI，以及目前已知能在 Android 上正常安裝的核心額外組件 (extras)。

## 經過測試的路徑支援哪些功能？

經過測試的 Termux 組合包會安裝：
- Hermes CLI
- cron 支援
- PTY/背景終端機支援
- MCP 支援
- Honcho 記憶支援
- ACP 支援

具體而言，它對應於：

```bash
python -m pip install -e '.[termux]' -c constraints-termux.txt
```

## 哪些功能尚未包含在經過測試的路徑中？

有些功能仍需要桌上型電腦或伺服器等級的依賴項，這些依賴項尚未針對 Android 發布，或是尚未在手機上完成驗證：

- 目前 Android 尚不支援 `.[all]`
- `voice` 額外組件因 `faster-whisper -> ctranslate2` 而受阻，且 `ctranslate2` 並未發布 Android 版本的 wheel
- Termux 安裝程式會跳過自動瀏覽器 / Playwright 引導 (bootstrap)
- Termux 內部無法使用基於 Docker 的終端機隔離

這並不妨礙 Hermes 成為一個出色的手機原生 CLI 代理——這只是意味著推薦的手機版安裝範圍刻意比桌機/伺服器版更窄。

---

## 選項 1：單行安裝指令

Hermes 現在提供了支援 Termux 的安裝路徑：

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

在 Termux 上，安裝程式會自動：
- 使用 `pkg` 處理系統套件
- 使用 `python -m venv` 建立虛擬環境 (venv)
- 使用 `pip` 安裝 `.[termux]`
- 將 `hermes` 連結到 `$PREFIX/bin`，使其保留在你的 Termux PATH 中
- 跳過未經測試的瀏覽器 / WhatsApp 引導程式

如果你想要明確的指令或需要偵測安裝失敗的原因，請使用下方的上手動路徑。

---

## 選項 2：手動安裝 (完全明確)

### 1. 更新 Termux 並安裝系統套件

```bash
pkg update
pkg install -y git python clang rust make pkg-config libffi openssl nodejs ripgrep ffmpeg
```

為什麼需要這些套件？
- `python` — 運行時 + venv 支援
- `git` — clone/更新儲存庫
- `clang`, `rust`, `make`, `pkg-config`, `libffi`, `openssl` — 在 Android 上編譯部分 Python 依賴項所需
- `nodejs` — 選用的 Node 運行時，用於超越測試核心路徑以外的實驗
- `ripgrep` — 快速檔案搜尋
- `ffmpeg` — 媒體 / TTS 轉換

### 2. Clone Hermes

```bash
git clone --recurse-submodules https://github.com/NousResearch/hermes-agent.git
cd hermes-agent
```

如果你已經在沒有使用子模組的情況下完成 clone：

```bash
git submodule update --init --recursive
```

### 3. 建立虛擬環境

```bash
python -m venv venv
source venv/bin/activate
export ANDROID_API_LEVEL="$(getprop ro.build.version.sdk)"
python -m pip install --upgrade pip setuptools wheel
```

`ANDROID_API_LEVEL` 對於 `jiter` 等基於 Rust / maturin 的套件非常重要。

### 4. 安裝經過測試的 Termux 組合包

```bash
python -m pip install -e '.[termux]' -c constraints-termux.txt
```

如果你只需要最簡核心代理，以下指令也行：

```bash
python -m pip install -e '.' -c constraints-termux.txt
```

### 5. 將 `hermes` 加入你的 Termux PATH

```bash
ln -sf "$PWD/venv/bin/hermes" "$PREFIX/bin/hermes"
```

`$PREFIX/bin` 已經在 Termux 的 PATH 中，因此這可以讓 `hermes` 指令在新的 shell 中持續有效，而無需每次都重新啟用 (activate) 虛擬環境。

### 6. 驗證安裝

```bash
hermes version
hermes doctor
```

### 7. 啟動 Hermes

```bash
hermes
```

---

## 推薦的後續設定

### 配置模型

```bash
hermes model
```

或直接在 `~/.hermes/.env` 中設定金鑰。

### 稍後重新執行完整互動式設定精靈

```bash
hermes setup
```

### 手動安裝選用的 Node 依賴項

經過測試的 Termux 路徑刻意跳過了 Node/瀏覽器引導。如果你稍後想嘗試瀏覽器工具：

```bash
pkg install nodejs-lts
npm install
```

瀏覽器工具會自動將 Termux 目錄 (`/data/data/com.termux/files/usr/bin`) 納入其 PATH 搜尋，因此無需額外設定 PATH 即可偵測到 `agent-browser` 與 `npx`。

在另有說明前，請將 Android 上的瀏覽器 / WhatsApp 工具視為實驗性功能。

---

## 疑難排解

### 安裝 `.[all]` 時出現 `No solution found`

請改用經過測試的 Termux 組合包：

```bash
python -m pip install -e '.[termux]' -c constraints-termux.txt
```

目前的阻礙是 `voice` 額外組件：
- `voice` 會引入 `faster-whisper`
- `faster-whisper` 依賴 `ctranslate2`
- `ctranslate2` 並未發布 Android 版本的 wheel

### 在 Android 上執行 `uv pip install` 失敗

請改用標準函式庫的 venv + `pip` 的 Termux 路徑：

```bash
python -m venv venv
source venv/bin/activate
export ANDROID_API_LEVEL="$(getprop ro.build.version.sdk)"
python -m pip install --upgrade pip setuptools wheel
python -m pip install -e '.[termux]' -c constraints-termux.txt
```

### `jiter` / `maturin` 抱怨 `ANDROID_API_LEVEL`

在安裝前明確設定 API 層級：

```bash
export ANDROID_API_LEVEL="$(getprop ro.build.version.sdk)"
python -m pip install -e '.[termux]' -c constraints-termux.txt
```

### `hermes doctor` 提示缺少 ripgrep 或 Node

使用 Termux 套件安裝它們：

```bash
pkg install ripgrep nodejs
```

### 安裝 Python 套件時出現編譯失敗

確保已安裝編譯工具鏈：

```bash
pkg install clang rust make pkg-config libffi openssl
```

然後重試：

```bash
python -m pip install -e '.[termux]' -c constraints-termux.txt
```

---

## 手機上的已知限制

- 無法使用 Docker 後端
- 經過測試的路徑中無法使用透過 `faster-whisper` 進行的本地語音轉錄
- 安裝程式刻意跳過了瀏覽器自動化設定
- 部分選用的額外組件可能可以運作，但目前僅有 `.[termux]` 被列為經過測試的 Android 組合包

如果你遇到新的 Android 特有問題，請開啟 GitHub issue 並提供：
- 你的 Android 版本
- `termux-info` 的輸出
- `python --version`
- `hermes doctor` 的輸出
- 完整的安裝指令及完整的錯誤輸出
