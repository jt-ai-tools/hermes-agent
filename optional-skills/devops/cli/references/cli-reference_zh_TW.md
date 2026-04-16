# CLI 參考指南

## 安裝

```bash
curl -fsSL https://cli.inference.sh | sh
```

## 全域命令 (Global Commands)

| 命令 | 描述 |
|---------|-------------|
| `infsh help` | 顯示說明 |
| `infsh version` | 顯示 CLI 版本 |
| `infsh update` | 更新 CLI 至最新版本 |
| `infsh login` | 進行身分驗證 |
| `infsh me` | 顯示當前使用者 |

## 應用程式命令 (App Commands)

### 探索 (Discovery)

| 命令 | 描述 |
|---------|-------------|
| `infsh app list` | 列出可用的應用程式 |
| `infsh app list --category <cat>` | 按類別篩選 (image, video, audio, text, other) |
| `infsh app search <query>` | 搜尋應用程式 |
| `infsh app list --search <query>` | 搜尋應用程式 (標記形式) |
| `infsh app list --featured` | 顯示精選應用程式 |
| `infsh app list --new` | 按最新順序排序 |
| `infsh app list --page <n>` | 分頁 |
| `infsh app list -l` | 詳細表格檢視 |
| `infsh app list --save <file>` | 儲存至 JSON 檔案 |
| `infsh app my` | 列出您已部署的應用程式 |
| `infsh app get <app>` | 取得應用程式詳情 |
| `infsh app get <app> --json` | 以 JSON 格式取得應用程式詳情 |

### 執行 (Execution)

| 命令 | 描述 |
|---------|-------------|
| `infsh app run <app> --input <file>` | 使用輸入檔案執行應用程式 |
| `infsh app run <app> --input '<json>'` | 使用行內 JSON 執行 |
| `infsh app run <app> --input <file> --no-wait` | 執行而不等待完成 |
| `infsh app sample <app>` | 顯示範例輸入 |
| `infsh app sample <app> --save <file>` | 將範例儲存至檔案 |

## 任務命令 (Task Commands)

| 命令 | 描述 |
|---------|-------------|
| `infsh task get <task-id>` | 取得任務狀態與結果 |
| `infsh task get <task-id> --json` | 以 JSON 格式取得任務資訊 |
| `infsh task get <task-id> --save <file>` | 將任務結果儲存至檔案 |

### 開發 (Development)

| 命令 | 描述 |
|---------|-------------|
| `infsh app init` | 建立新應用程式 (互動式) |
| `infsh app init <name>` | 建立指定名稱的新應用程式 |
| `infsh app test --input <file>` | 在本地測試應用程式 |
| `infsh app deploy` | 部署應用程式 |
| `infsh app deploy --dry-run` | 驗證而不部署 |
| `infsh app pull <id>` | 拉取應用程式原始碼 |
| `infsh app pull --all` | 拉取您所有的應用程式 |

## 環境變數

| 變數 | 描述 |
|----------|-------------|
| `INFSH_API_KEY` | API 金鑰 (優先級高於設定檔) |

## Shell 自動補全

```bash
# Bash
infsh completion bash > /etc/bash_completion.d/infsh

# Zsh
infsh completion zsh > "${fpath[1]}/_infsh"

# Fish
infsh completion fish > ~/.config/fish/completions/infsh.fish
```

## 應用程式名稱格式

應用程式使用 `命名空間/應用程式名稱` (namespace/app-name) 格式：

- `falai/flux-dev-lora` - fal.ai 的 FLUX 2 Dev
- `google/veo-3` - Google 的 Veo 3
- `infsh/sdxl` - inference.sh 的 SDXL
- `bytedance/seedance-1-5-pro` - 字節跳動的 Seedance
- `xai/grok-imagine-image` - xAI 的 Grok

版本鎖定：`namespace/app-name@version`

## 相關文件

- [CLI Setup](https://inference.sh/docs/extend/cli-setup) - 完整的 CLI 安裝指南
- [Running Apps](https://inference.sh/docs/apps/running) - 如何透過 CLI 執行應用程式
- [Creating an App](https://inference.sh/docs/extend/creating-app) - 建立您自己的應用程式
- [Deploying](https://inference.sh/docs/extend/deploying) - 將應用程式部署至雲端
