---
sidebar_position: 4
title: "參與貢獻"
description: "如何參與 Hermes Agent 貢獻 — 開發環境架設、程式碼風格、PR 流程"
---

# 參與貢獻

感謝您為 Hermes Agent 做出貢獻！本指南涵蓋了開發環境架設、程式碼庫理解以及如何讓您的 PR 被合併。

## 貢獻優先級

我們按以下順序重視各項貢獻：

1. **Bug 修復** — 崩潰、錯誤行為、資料遺失
2. **跨平台相容性** — macOS、不同的 Linux 發行版、WSL2
3. **安全性強化** — Shell 注入、提示詞注入、路徑遍歷
4. **效能與穩健性** — 重試邏輯、錯誤處理、優雅降級
5. **新技能** — 具有廣泛用途的技能（參見 [建立技能](creating-skills.md)）
6. **新工具** — 較少需要；大多數功能應實作為技能
7. **文件** — 修復、澄清、新範例

## 常見貢獻路徑

- 想要開發新工具？請先參閱 [新增工具](./adding-tools.md)
- 想要開發新技能？請先參閱 [建立技能](./creating-skills.md)
- 想要開發新的推理提供者 (Inference Provider)？請先參閱 [新增提供者](./adding-providers.md)

## 開發環境架設

### 先決條件

| 需求 | 備註 |
|-------------|-------|
| **Git** | 需支援 `--recurse-submodules` |
| **Python 3.11+** | 若缺少，uv 會自動安裝 |
| **uv** | 高效的 Python 套件管理器 ([安裝指南](https://docs.astral.sh/uv/)) |
| **Node.js 18+** | 選配 — 瀏覽器工具與 WhatsApp 橋接器需要 |

### 複製與安裝

```bash
git clone --recurse-submodules https://github.com/NousResearch/hermes-agent.git
cd hermes-agent

# 使用 Python 3.11 建立虛擬環境 (venv)
uv venv venv --python 3.11
export VIRTUAL_ENV="$(pwd)/venv"

# 安裝所有額外組件 (訊息傳遞、Cron、CLI 選單、開發工具)
uv pip install -e ".[all,dev]"
uv pip install -e "./tinker-atropos"

# 選配：瀏覽器工具
npm install
```

### 開發配置

```bash
mkdir -p ~/.hermes/{cron,sessions,logs,memories,skills}
cp cli-config.yaml.example ~/.hermes/config.yaml
touch ~/.hermes/.env

# 至少新增一個 LLM 提供者金鑰：
echo 'OPENROUTER_API_KEY=sk-or-v1-your-key' >> ~/.hermes/.env
```

### 執行

```bash
# 建立全域存取的符號連結 (Symlink)
mkdir -p ~/.local/bin
ln -sf "$(pwd)/venv/bin/hermes" ~/.local/bin/hermes

# 驗證
hermes doctor
hermes chat -q "Hello"
```

### 執行測試

```bash
pytest tests/ -v
```

## 程式碼風格

- 遵循 **PEP 8**，但有實務上的例外（不強制執行嚴格的行長度限制）。
- **註釋**：僅在解釋非顯而易見的意圖、權衡取捨或 API 特性時使用。
- **錯誤處理**：捕捉特定的異常 (Exception)。對於非預期錯誤，使用 `logger.warning()`/`logger.error()` 並設定 `exc_info=True`。
- **跨平台**：絕不預設為 Unix 系統（見下文）。
- **設定檔安全路徑 (Profile-safe paths)**：絕不硬寫 `~/.hermes` — 程式碼路徑請使用 `hermes_constants` 中的 `get_hermes_home()`，使用者端訊息請使用 `display_hermes_home()`。完整規則請參閱 [AGENTS.md](https://github.com/NousResearch/hermes-agent/blob/main/AGENTS.md#profiles-multi-instance-support)。

## 跨平台相容性

Hermes 正式支援 Linux、macOS 與 WSL2。**不支援**原生 Windows，但程式碼中包含一些防禦性編碼模式，以避免在邊緣情況下發生崩潰。關鍵規則如下：

### 1. `termios` 與 `fcntl` 僅限 Unix

務必同時捕捉 `ImportError` 與 `NotImplementedError`：

```python
try:
    from simple_term_menu import TerminalMenu
    menu = TerminalMenu(options)
    idx = menu.show()
except (ImportError, NotImplementedError):
    # 降級方案：編號選單
    for i, opt in enumerate(options):
        print(f"  {i+1}. {opt}")
    idx = int(input("Choice: ")) - 1
```

### 2. 檔案編碼

某些環境可能會以非 UTF-8 編碼儲存 `.env` 檔案：

```python
try:
    load_dotenv(env_path)
except UnicodeDecodeError:
    load_dotenv(env_path, encoding="latin-1")
```

### 3. 程序管理

`os.setsid()`、`os.killpg()` 以及訊號處理在各平台間有所不同：

```python
import platform
if platform.system() != "Windows":
    kwargs["preexec_fn"] = os.setsid
```

### 4. 路徑分隔符

使用 `pathlib.Path` 取代以 `/` 進行字串拼接。

## 安全考量

Hermes 具備終端機存取權限，安全性至關重要。

### 現有的保護機制

| 層級 | 實作方式 |
|-------|---------------|
| **Sudo 密碼導引** | 使用 `shlex.quote()` 防止 Shell 注入 |
| **危險指令偵測** | 在 `tools/approval.py` 中使用正規表達式，並搭配使用者核准流程 |
| **Cron 提示詞注入** | 掃描器會阻斷指令覆蓋模式 (instruction-override patterns) |
| **寫入黑名單** | 透過 `os.path.realpath()` 解析受保護路徑，防止符號連結繞過 |
| **技能守衛 (Skills guard)** | 針對從 Hub 安裝的技能進行安全性掃描 |
| **程式碼執行沙盒** | 子程序執行時會剝離 API 金鑰 |
| **容器強化** | Docker：捨棄所有權限 (Capabilities)、禁止權限提升、限制 PID 數量 |

### 貢獻安全性敏感的程式碼

- 在將使用者輸入插入 Shell 指令時，務必使用 `shlex.quote()`。
- 在進行存取控制檢查前，使用 `os.path.realpath()` 解析符號連結。
- 不要記錄 (log) 祕密資訊。
- 在工具執行周圍捕捉廣泛的異常。
- 如果您的更動涉及檔案路徑或程序，請在所有平台上進行測試。

## Pull Request 流程

### 分支命名

```
fix/說明        # Bug 修復
feat/說明       # 新功能
docs/說明       # 文件
test/說明       # 測試
refactor/說明   # 程式碼重構
```

### 提交 PR 前

1. **執行測試**：`pytest tests/ -v`
2. **手動測試**：執行 `hermes` 並操作您修改過的程式碼路徑
3. **檢查跨平台影響**：考慮 macOS 與不同的 Linux 發行版
4. **保持 PR 專注**：一個 PR 只包含一個邏輯上的更動

### PR 說明

內容應包括：
- **修改了什麼**以及**為什麼**修改
- **如何測試**
- 您在**哪些平台**上測試過
- 引用任何相關的 Issue

### Commit 訊息

我們使用 [約定式提交 (Conventional Commits)](https://www.conventionalcommits.org/)：

```
<類型>(<範疇>): <說明>
```

| 類型 | 用途 |
|------|---------|
| `fix` | Bug 修復 |
| `feat` | 新功能 |
| `docs` | 文件 |
| `test` | 測試 |
| `refactor` | 程式碼重構 |
| `chore` | 建構、CI、相依套件更新 |

範疇 (Scopes)：`cli`, `gateway`, `tools`, `skills`, `agent`, `install`, `whatsapp`, `security`

範例：
```
fix(cli): prevent crash in save_config_value when model is a string
feat(gateway): add WhatsApp multi-user session isolation
fix(security): prevent shell injection in sudo password piping
```

## 回報問題

- 請使用 [GitHub Issues](https://github.com/NousResearch/hermes-agent/issues)
- 應包括：作業系統、Python 版本、Hermes 版本 (`hermes version`)、完整錯誤回溯 (traceback)
- 應包括重現步驟
- 建立新 Issue 前，請先檢查是否已有重複的 Issue
- 對於安全漏洞，請私下回報

## 社群

- **Discord**: [discord.gg/NousResearch](https://discord.gg/NousResearch)
- **GitHub Discussions**: 用於設計提案與架構討論
- **Skills Hub**: 上傳專門的技能並與社群分享

## 授權

參與貢獻即代表您同意您的貢獻將遵循 [MIT 授權條款](https://github.com/NousResearch/hermes-agent/blob/main/LICENSE)。
