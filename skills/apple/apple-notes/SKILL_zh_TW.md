---
name: apple-notes
description: 在 macOS 上透過 memo CLI 管理 Apple 備忘錄（建立、檢視、搜尋、編輯）。
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos]
metadata:
  hermes:
    tags: [備忘錄, Apple, macOS, 筆記]
    related_skills: [obsidian]
prerequisites:
  commands: [memo]
---

# Apple 備忘錄

使用 `memo` 直接從終端機管理 Apple 備忘錄。備忘錄會透過 iCloud 在所有 Apple 裝置間同步。

## 先決條件

- 搭載備忘錄 App 的 **macOS**
- 安裝方法：`brew tap antoniorodr/memo && brew install antoniorodr/memo/memo`
- 提示時授權自動化存取備忘錄 App（系統設定 → 隱私權與安全性 → 自動化）

## 何時使用

- 使用者要求建立、檢視或搜尋 Apple 備忘錄
- 將資訊儲存到備忘錄 App 以供跨裝置存取
- 將備忘錄整理到資料夾中
- 將備忘錄匯出為 Markdown/HTML

## 何時不應使用

- Obsidian 保險箱管理 → 使用 `obsidian` 技能
- Bear Notes → 不同的應用程式（此處不支援）
- 僅限代理程式使用的快速筆記 → 請改用 `memory` 工具

## 快速參考

### 檢視備忘錄

```bash
memo notes                        # 列出所有備忘錄
memo notes -f "資料夾名稱"         # 按資料夾過濾
memo notes -s "查詢內容"           # 搜尋備忘錄 (模糊搜尋)
```

### 建立備忘錄

```bash
memo notes -a                     # 互動式編輯器
memo notes -a "備忘錄標題"          # 快速新增標題
```

### 編輯備忘錄

```bash
memo notes -e                     # 互動式選擇並編輯
```

### 刪除備忘錄

```bash
memo notes -d                     # 互動式選擇並刪除
```

### 移動備忘錄

```bash
memo notes -m                     # 將備忘錄移至資料夾 (互動式)
```

### 匯出備忘錄

```bash
memo notes -ex                    # 匯出為 HTML/Markdown
```

## 限制

- 無法編輯包含圖片或附件的備忘錄
- 互動式提示需要終端機存取權（如有需要，請使用 pty=true）
- 僅限 macOS — 需要 Apple 備忘錄 App

## 規則

1. 當使用者需要跨裝置同步（iPhone/iPad/Mac）時，優先選擇 Apple 備忘錄
2. 對於不需要同步的代理程式內部筆記，請使用 `memory` 工具
3. 對於以 Markdown 為核心的知識管理，請使用 `obsidian` 技能
