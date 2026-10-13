---
name: apple-reminders
description: 透過 remindctl CLI 管理 Apple 提醒事項（列出、新增、完成、刪除）。
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos]
metadata:
  hermes:
    tags: [提醒事項, 任務, 待辦事項, macOS, Apple]
prerequisites:
  commands: [remindctl]
---

# Apple 提醒事項

使用 `remindctl` 直接從終端機管理 Apple 提醒事項。任務會透過 iCloud 在所有 Apple 裝置間同步。

## 先決條件

- 搭載提醒事項 App 的 **macOS**
- 安裝方法：`brew install steipete/tap/remindctl`
- 提示時授權提醒事項存取權限
- 檢查狀態：`remindctl status` / 請求授權：`remindctl authorize`

## 何時使用

- 使用者提到「提醒事項」或「提醒事項 App」
- 建立具備到期日且會同步到 iOS 的個人待辦事項
- 管理 Apple 提醒事項列表
- 使用者希望任務出現在他們的 iPhone/iPad 上

## 何時不應使用

- 排定代理程式警報 → 請改用 cronjob 工具
- 日曆行程 → 請使用 Apple 日曆或 Google 日曆
- 專案任務管理 → 請使用 GitHub Issues、Notion 等
- 如果使用者說「提醒我」但指的是代理程式警報 → 請先釐清

## 快速參考

### 檢視提醒事項

```bash
remindctl                    # 今天的提醒事項
remindctl today              # 今天
remindctl tomorrow           # 明天
remindctl week               # 本週
remindctl overdue            # 已過期
remindctl all                # 全部
remindctl 2026-01-04         # 特定日期
```

### 管理列表

```bash
remindctl list               # 列出所有列表
remindctl list Work          # 顯示特定列表
remindctl list Projects --create    # 建立列表
remindctl list Work --delete        # 刪除列表
```

### 建立提醒事項

```bash
remindctl add "買牛奶"
remindctl add --title "打電話給媽媽" --list Personal --due tomorrow
remindctl add --title "會議準備" --due "2026-02-15 09:00"
```

### 完成 / 刪除

```bash
remindctl complete 1 2 3          # 依 ID 完成
remindctl delete 4A83 --force     # 依 ID 刪除
```

### 輸出格式

```bash
remindctl today --json       # 用於腳本編寫的 JSON
remindctl today --plain      # TSV 格式
remindctl today --quiet      # 僅計數
```

## 日期格式

`--due` 和日期過濾器接受：
- `today` (今天), `tomorrow` (明天), `yesterday` (昨天)
- `YYYY-MM-DD`
- `YYYY-MM-DD HH:mm`
- ISO 8601 (`2026-01-04T12:34:56Z`)

## 規則

1. 當使用者說「提醒我」時，請釐清：Apple 提醒事項（同步到手機）還是代理程式 cronjob 警報
2. 在建立提醒事項之前，務必確認內容和到期日
3. 程式化解析請使用 `--json`
