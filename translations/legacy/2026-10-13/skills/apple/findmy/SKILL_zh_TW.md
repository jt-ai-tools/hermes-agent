---
name: findmy
description: 在 macOS 上透過 AppleScript 和螢幕截圖，經由「尋找」App 追蹤 Apple 裝置和 AirTag。
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos]
metadata:
  hermes:
    tags: [尋找, AirTag, 位置, 追蹤, macOS, Apple]
---

# 尋找 (Apple)

在 macOS 上透過「尋找」App 追蹤 Apple 裝置和 AirTag。由於 Apple 未提供「尋找」的 CLI，此技能使用 AppleScript 開啟應用程式，並透過螢幕截圖讀取裝置位置。

## 先決條件

- 搭載「尋找」App 且已登入 iCloud 的 **macOS**
- 裝置/AirTag 已在「尋找」中註冊
- 終端機的「螢幕錄製」權限（系統設定 → 隱私權與安全性 → 螢幕錄製）
- **選配但建議安裝**：安裝 `peekaboo` 以獲得更好的 UI 自動化體驗：
  `brew install steipete/tap/peekaboo`

## 何時使用

- 使用者詢問「我的 [裝置/貓/鑰匙/包包] 在哪裡？」
- 追蹤 AirTag 位置
- 檢查裝置位置（iPhone、iPad、Mac、AirPods）
- 監控寵物或物品隨時間移動的軌跡（AirTag 巡邏路線）

## 方法 1：AppleScript + 螢幕截圖（基本）

### 開啟「尋找」並導覽

```bash
# 開啟「尋找」App
osascript -e 'tell application "FindMy" to activate'

# 等待載入
sleep 3

# 擷取「尋找」視窗的螢幕截圖
screencapture -w -o /tmp/findmy.png
```

然後使用 `vision_analyze` 讀取截圖：
```
vision_analyze(image_url="/tmp/findmy.png", question="顯示了哪些裝置/物品，它們的位置在哪裡？")
```

### 切換分頁

```bash
# 切換至「裝置」分頁
osascript -e '
tell application "System Events"
    tell process "FindMy"
        click button "Devices" of toolbar 1 of window 1
    end tell
end tell'

# 切換至「物品」分頁 (AirTags)
osascript -e '
tell application "System Events"
    tell process "FindMy"
        click button "Items" of toolbar 1 of window 1
    end tell
end tell'
```

## 方法 2：Peekaboo UI 自動化（建議）

如果已安裝 `peekaboo`，請使用它來獲得更可靠的 UI 互動：

```bash
# 開啟「尋找」
osascript -e 'tell application "FindMy" to activate'
sleep 3

# 擷取並標註 UI
peekaboo see --app "FindMy" --annotate --path /tmp/findmy-ui.png

# 透過元件 ID 點擊特定的裝置/物品
peekaboo click --on B3 --app "FindMy"

# 擷取詳細視圖
peekaboo image --app "FindMy" --path /tmp/findmy-detail.png
```

然後透過視覺分析：
```
vision_analyze(image_url="/tmp/findmy-detail.png", question="此裝置/物品顯示的位置在哪裡？如果可見，請包含地址和座標。")
```

## 工作流程：追蹤 AirTag 隨時間變動的位置

監控 AirTag（例如：追蹤貓咪的巡邏路線）：

```bash
# 1. 開啟「尋找」並切換至「物品」分頁
osascript -e 'tell application "FindMy" to activate'
sleep 3

# 2. 點擊 AirTag 物品（保持在該頁面 — AirTag 僅在頁面開啟時更新）

# 3. 定期擷取位置
while true; do
    screencapture -w -o /tmp/findmy-$(date +%H%M%S).png
    sleep 300  # 每 5 分鐘一次
done
```

透過視覺分析每張截圖以提取座標，然後編譯成路線。

## 限制

- 「尋找」**沒有 CLI 或 API** — 必須使用 UI 自動化
- AirTag 僅在「尋找」頁面主動顯示時才會更新位置
- 位置準確度取決於「尋找」網路中附近的 Apple 裝置
- 截圖需要「螢幕錄製」權限
- AppleScript UI 自動化可能會因 macOS 版本更新而失效

## 規則

1. 追蹤 AirTag 時保持「尋找」App 在前景運行（最小化時會停止更新）
2. 使用 `vision_analyze` 讀取截圖內容 — 不要嘗試解析像素
3. 對於持續追蹤，請使用 cronjob 定期擷取並記錄位置
4. 尊重隱私 — 僅追蹤使用者擁有的裝置/物品
