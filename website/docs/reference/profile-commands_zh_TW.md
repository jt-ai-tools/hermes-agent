---
sidebar_position: 7
---

# 設定檔 (Profile) 指令參考

本頁面涵蓋了所有與 [Hermes 設定檔 (Profiles)](../user-guide/profiles.md) 相關的指令。關於一般的 CLI 指令，請參閱 [CLI 指令參考](./cli-commands.md)。

## `hermes profile`

```bash
hermes profile <subcommand>
```

用於管理設定檔的頂層指令。執行不帶子指令的 `hermes profile` 將顯示說明。

| 子指令 | 描述 |
|------------|-------------|
| `list` | 列出所有設定檔。 |
| `use` | 設置當前啟用的 (預設) 設定檔。 |
| `create` | 建立一個新的設定檔。 |
| `delete` | 刪除一個設定檔。 |
| `show` | 顯示設定檔的詳細資訊。 |
| `alias` | 重新生成設定檔的 shell 別名。 |
| `rename` | 重新命名設定檔。 |
| `export` | 將設定檔匯出為 tar.gz 封存檔。 |
| `import` | 從 tar.gz 封存檔匯入設定檔。 |

## `hermes profile list`

```bash
hermes profile list
```

列出所有設定檔。當前啟用的設定檔會以 `*` 標記。

**範例：**

```bash
$ hermes profile list
  default
* work
  dev
  personal
```

無選項。

## `hermes profile use`

```bash
hermes profile use <name>
```

將 `<name>` 設置為當前啟用的設定檔。後續所有 `hermes` 指令 (若不帶 `-p`) 都將使用此設定檔。

| 參數 | 描述 |
|----------|-------------|
| `<name>` | 要啟用的設定檔名稱。使用 `default` 可返回基礎設定檔。 |

**範例：**

```bash
hermes profile use work
hermes profile use default
```

## `hermes profile create`

```bash
hermes profile create <name> [options]
```

建立一個新的設定檔。

| 參數 / 選項 | 描述 |
|-------------------|-------------|
| `<name>` | 新設定檔的名稱。必須是有效的目錄名稱 (英數字、連字號、底線)。 |
| `--clone` | 從當前設定檔複製 `config.yaml`、`.env` 與 `SOUL.md`。 |
| `--clone-all` | 從當前設定檔複製所有內容 (配置、記憶、技能、工作階段、狀態)。 |
| `--clone-from <profile>` | 從指定的設定檔複製，而非當前設定檔。需與 `--clone` 或 `--clone-all` 配合使用。 |
| `--no-alias` | 跳過建立包裝腳本 (wrapper script)。 |

**範例：**

```bash
# 空白設定檔 — 需要完整設定
hermes profile create mybot

# 僅從當前設定檔複製配置
hermes profile create work --clone

# 從當前設定檔複製所有內容
hermes profile create backup --clone-all

# 從指定設定檔複製配置
hermes profile create work2 --clone --clone-from work
```

## `hermes profile delete`

```bash
hermes profile delete <name> [options]
```

刪除一個設定檔並移除其 shell 別名。

| 參數 / 選項 | 描述 |
|-------------------|-------------|
| `<name>` | 要刪除的設定檔名稱。 |
| `--yes`, `-y` | 跳過確認提示。 |

**範例：**

```bash
hermes profile delete mybot
hermes profile delete mybot --yes
```

:::warning 警告
這會永久刪除設定檔的整個目錄，包括所有配置、記憶、工作階段與技能。無法刪除當前啟用的設定檔。
:::

## `hermes profile show`

```bash
hermes profile show <name>
```

顯示設定檔的詳細資訊，包括其家目錄、配置的模型、網關狀態、技能數量以及配置文件狀態。

| 參數 | 描述 |
|----------|-------------|
| `<name>` | 要查看的設定檔名稱。 |

**範例：**

```bash
$ hermes profile show work
Profile: work
Path:    ~/.hermes/profiles/work
Model:   anthropic/claude-sonnet-4 (anthropic)
Gateway: stopped
Skills:  12
.env:    exists
SOUL.md: exists
Alias:   ~/.local/bin/work
```

## `hermes profile alias`

```bash
hermes profile alias <name> [options]
```

在 `~/.local/bin/<name>` 重新生成 shell 別名腳本。如果別名被誤刪，或在移動 Hermes 安裝路徑後需要更新，此指令非常有用。

| 參數 / 選項 | 描述 |
|-------------------|-------------|
| `<name>` | 要建立/更新別名的設定檔。 |
| `--remove` | 移除包裝腳本而非建立它。 |
| `--name <alias>` | 自定義別名名稱 (預設為設定檔名稱)。 |

**範例：**

```bash
hermes profile alias work
# 建立/更新 ~/.local/bin/work

hermes profile alias work --name mywork
# 建立 ~/.local/bin/mywork

hermes profile alias work --remove
# 移除包裝腳本
```

## `hermes profile rename`

```bash
hermes profile rename <old-name> <new-name>
```

重新命名設定檔。更新目錄與 shell 別名。

| 參數 | 描述 |
|----------|-------------|
| `<old-name>` | 當前設定檔名稱。 |
| `<new-name>` | 新的設定檔名稱。 |

**範例：**

```bash
hermes profile rename mybot assistant
# ~/.hermes/profiles/mybot → ~/.hermes/profiles/assistant
# ~/.local/bin/mybot → ~/.local/bin/assistant
```

## `hermes profile export`

```bash
hermes profile export <name> [options]
```

將設定檔匯出為壓縮的 tar.gz 封存檔。

| 參數 / 選項 | 描述 |
|-------------------|-------------|
| `<name>` | 要匯出的設定檔名稱。 |
| `-o`, `--output <path>` | 輸出檔案路徑 (預設為 `<name>.tar.gz`)。 |

**範例：**

```bash
hermes profile export work
# 在當前目錄建立 work.tar.gz

hermes profile export work -o ./work-2026-03-29.tar.gz
```

## `hermes profile import`

```bash
hermes profile import <archive> [options]
```

從 tar.gz 封存檔匯入設定檔。

| 參數 / 選項 | 描述 |
|-------------------|-------------|
| `<archive>` | 要匯入的 tar.gz 封存檔路徑。 |
| `--name <name>` | 匯入後的設定檔名稱 (預設從封存檔名推斷)。 |

**範例：**

```bash
hermes profile import ./work-2026-03-29.tar.gz
# 從封存檔名推斷設定檔名稱

hermes profile import ./work-2026-03-29.tar.gz --name work-restored
```

## `hermes -p` / `hermes --profile`

```bash
hermes -p <name> <command> [options]
hermes --profile <name> <command> [options]
```

全域旗標，用於在特定設定檔下執行任何 Hermes 指令，而不會更改固定的預設值。這會在指令執行期間覆蓋當前啟用的設定檔。

| 選項 | 描述 |
|--------|-------------|
| `-p <name>`, `--profile <name>` | 此指令要使用的設定檔名稱。 |

**範例：**

```bash
hermes -p work chat -q "檢查伺服器狀態"
hermes --profile dev gateway start
hermes -p personal skills list
hermes -p work config edit
```

## `hermes completion`

```bash
hermes completion <shell>
```

生成 shell 補全腳本。包含對設定檔名稱與設定檔子指令的補全。

| 參數 | 描述 |
|----------|-------------|
| `<shell>` | 要生成補全腳本的 shell 類型：`bash` 或 `zsh`。 |

**範例：**

```bash
# 安裝補全腳本
hermes completion bash >> ~/.bashrc
hermes completion zsh >> ~/.zshrc

# 重新載入 shell
source ~/.bashrc
```

安裝後，Tab 補全將適用於：
- `hermes profile <TAB>` — 子指令 (list, use, create 等)
- `hermes profile use <TAB>` — 設定檔名稱
- `hermes -p <TAB>` — 設定檔名稱

## 參閱

- [設定檔 (Profiles) 使用者指南](../user-guide/profiles.md)
- [CLI 指令參考](./cli-commands.md)
- [常見問題 (FAQ) — 設定檔章節](./faq.md#profiles)
