---
name: openhue
description: 透過 OpenHue CLI 控制 Philips Hue 燈光、房間和場景。開啟/關閉燈光，調整亮度、顏色、色溫，並啟動場景。
version: 1.0.0
author: community
license: MIT
metadata:
  hermes:
    tags: [Smart-Home, Hue, Lights, IoT, Automation]
    homepage: https://www.openhue.io/cli
prerequisites:
  commands: [openhue]
---

# OpenHue CLI

從終端機透過 Hue Bridge 控制 Philips Hue 燈光和場景。

## 前置要求

```bash
# Linux (預編譯二進位檔)
curl -sL https://github.com/openhue/openhue-cli/releases/latest/download/openhue-linux-amd64 -o ~/.local/bin/openhue && chmod +x ~/.local/bin/openhue

# macOS
brew install openhue/cli/openhue-cli
```

首次執行需要按下 Hue Bridge 上的按鈕進行配對。Bridge 必須位於同一個區域網路內。

## 使用時機

- 「開啟/關閉燈光」
- 「調暗客廳燈光」
- 「設定場景」或「電影模式」
- 控制特定的 Hue 房間、區域或個別燈泡
- 調整亮度、顏色或色溫

## 常見指令

### 列出資源

```bash
openhue get light       # 列出所有燈光
openhue get room        # 列出所有房間
openhue get scene       # 列出所有場景
```

### 控制燈光

```bash
# 開啟/關閉
openhue set light "Bedroom Lamp" --on
openhue set light "Bedroom Lamp" --off

# 亮度 (0-100)
openhue set light "Bedroom Lamp" --on --brightness 50

# 色溫 (暖色至冷色：153-500 mirek)
openhue set light "Bedroom Lamp" --on --temperature 300

# 顏色 (依名稱或十六進位)
openhue set light "Bedroom Lamp" --on --color red
openhue set light "Bedroom Lamp" --on --rgb "#FF5500"
```

### 控制房間

```bash
# 關閉整個房間
openhue set room "Bedroom" --off

# 設定房間亮度
openhue set room "Bedroom" --on --brightness 30
```

### 場景

```bash
openhue set scene "Relax" --room "Bedroom"
openhue set scene "Concentrate" --room "Office"
```

## 快速預設值

```bash
# 就寢時間 (調暗暖色)
openhue set room "Bedroom" --on --brightness 20 --temperature 450

# 工作模式 (亮冷色)
openhue set room "Office" --on --brightness 100 --temperature 250

# 電影模式 (調暗)
openhue set room "Living Room" --on --brightness 10

# 全部關閉
openhue set room "Bedroom" --off
openhue set room "Office" --off
openhue set room "Living Room" --off
```

## 注意事項

- Bridge 必須與執行 Hermes 的機器位於同一個區域網路
- 首次執行需要實際按下 Hue Bridge 上的按鈕以獲得授權
- 顏色調整僅適用於具備色彩能力的燈泡 (不適用於僅限白光的型號)
- 燈光和房間名稱區分大小寫 — 請使用 `openhue get light` 檢查正確名稱
- 非常適合與 cron 作業搭配用於排程照明 (例如：就寢時調暗，起床時調亮)
