---
sidebar_position: 3
title: "更新與解除安裝"
description: "如何將 Hermes Agent 更新至最新版本或解除安裝"
---

# 更新與解除安裝

## 更新

使用單一指令更新至最新版本：

```bash
hermes update
```

此指令會抓取最新的程式碼、更新依賴項，並提示你設定自上次更新以來新增的任何新選項。

:::tip
`hermes update` 會自動偵測新的配置選項並提示你新增。如果你跳過了該提示，可以手動執行 `hermes config check` 查看缺少的選項，然後執行 `hermes config migrate` 以互動方式新增它們。
:::

### 更新期間發生的情況

執行 `hermes update` 時，會執行以下步驟：

1. **Git pull** — 從 `main` 分支抓取最新的程式碼並更新子模組。
2. **安裝依賴項** — 執行 `uv pip install -e ".[all]"` 以獲取新增或變更的依賴項。
3. **配置遷移** — 偵測自你目前版本以來新增的新配置選項，並提示你設定。
4. **Gateway 自動重啟** — 如果 gateway 服務正在執行 (Linux 上的 systemd, macOS 上的 launchd)，更新完成後會**自動重啟**，使新程式碼立即生效。

預期輸出如下：

```
$ hermes update
Updating Hermes Agent...
📥 Pulling latest code...
Already up to date.  (或: Updating abc1234..def5678)
📦 Updating dependencies...
✅ Dependencies updated
🔍 Checking for new config options...
✅ Config is up to date  (或: Found 2 new options — running migration...)
🔄 Restarting gateway service...
✅ Gateway restarted
✅ Hermes Agent updated successfully!
```

### 建議的更新後驗證

`hermes update` 處理了主要的更新路徑，但進行快速驗證可確保一切皆正確就緒：

1. `git status --short` — 如果樹狀結構出現非預期的 dirty 狀態，請在繼續前進行檢查。
2. `hermes doctor` — 檢查配置、依賴項以及服務健康狀況。
3. `hermes --version` — 確認版本已如預期更新。
4. 如果你使用 gateway：`hermes gateway status`
5. 如果 `doctor` 報告 npm audit 問題：在標記的目錄中執行 `npm audit fix`。

:::warning 更新後工作樹 (working tree) 處於 dirty 狀態
如果執行 `hermes update` 後 `git status --short` 顯示非預期的變更，請停止並在繼續前檢查。這通常意味著本地修改被重新應用到更新後的程式碼之上，或是某個依賴步驟更新了 lockfile。
:::

### 檢查目前版本

```bash
hermes version
```

與 [GitHub 發布頁面 (releases page)](https://github.com/NousResearch/hermes-agent/releases) 上的最新版本進行比較，或檢查是否有可用更新：

```bash
hermes update --check
```

### 從訊息平台進行更新

你也可以直接從 Telegram, Discord, Slack 或 WhatsApp 發送以下訊息來進行更新：

```
/update
```

這會抓取最新程式碼、更新依賴項並重啟 gateway。機器人在重啟期間會短暫離線 (通常為 5–15 秒)，隨後恢復運作。

### 手動更新

如果你是手動安裝 (非透過快速安裝程式)：

```bash
cd /path/to/hermes-agent
export VIRTUAL_ENV="$(pwd)/venv"

# 抓取最新程式碼與子模組
git pull origin main
git submodule update --init --recursive

# 重新安裝 (獲取新的依賴項)
uv pip install -e ".[all]"
uv pip install -e "./tinker-atropos"

# 檢查新的配置選項
hermes config check
hermes config migrate   # 互動式新增任何缺少的選項
```

### 還原 (Rollback) 說明

如果更新引入了問題，你可以還原至先前的版本：

```bash
cd /path/to/hermes-agent

# 列出最近的版本
git log --oneline -10

# 還原至特定的 commit
git checkout <commit-hash>
git submodule update --init --recursive
uv pip install -e ".[all]"

# 重啟正在執行的 gateway
hermes gateway restart
```

還原至特定的 release tag：

```bash
git checkout v0.6.0
git submodule update --init --recursive
uv pip install -e ".[all]"
```

:::warning
如果新增了新選項，還原可能會導致配置不相容。還原後請執行 `hermes config check`，如果遇到錯誤，請從 `config.yaml` 中移除任何無法識別的選項。
:::

### Nix 使用者注意事項

如果你是透過 Nix flake 安裝，更新由 Nix 套件管理器管理：

```bash
# 更新 flake 輸入
nix flake update hermes-agent

# 或使用最新版本重建
nix profile upgrade hermes-agent
```

Nix 安裝是不可變的 (immutable)——還原由 Nix 的世代 (generation) 系統處理：

```bash
nix profile rollback
```

詳情請參閱 [Nix 設定](./nix-setup_zh_TW.md)。

---

## 解除安裝

```bash
hermes uninstall
```

解除安裝程式會讓你選擇是否保留設定檔 (`~/.hermes/`) 以供日後重新安裝使用。

### 手動解除安裝

```bash
rm -f ~/.local/bin/hermes
rm -rf /path/to/hermes-agent
rm -rf ~/.hermes            # 選用——如果你計畫重新安裝則予以保留
```

:::info
如果你將 gateway 安裝為系統服務，請先停止並停用它：
```bash
hermes gateway stop
# Linux: systemctl --user disable hermes-gateway
# macOS: launchctl remove ai.hermes.gateway
```
:::
