---
sidebar_position: 3
title: "Nix & NixOS 設定"
description: "使用 Nix 安裝與部署 Hermes Agent——從快速的 `nix run` 到具備容器模式的全宣告式 NixOS 模組"
---

# Nix & NixOS 設定

Hermes Agent 提供了一個具備三種整合層級的 Nix flake：

| 層級 | 適用對象 | 你將獲得 |
|-------|-------------|--------------|
| **`nix run` / `nix profile install`** | 任何 Nix 使用者 (macOS, Linux) | 包含所有依賴項的預先建置二進位檔案——接著使用標準的 CLI 工作流 |
| **NixOS 模組 (原生)** | NixOS 伺服器部署 | 宣告式設定、強化的 systemd 服務、受管理的機密資訊 (secrets) |
| **NixOS 模組 (容器)** | 需要自我修改能力的代理 | 具備上述所有功能，外加一個持久性的 Ubuntu 容器，代理可以在其中執行 `apt`/`pip`/`npm install` |

:::info 與標準安裝有何不同
`curl | bash` 安裝程式會自行管理 Python、Node 與依賴項。Nix flake 則取代了這一切——每個 Python 依賴項都是由 [uv2nix](https://github.com/pyproject-nix/uv2nix) 建置的 Nix derivation，而運行時工具 (Node.js, git, ripgrep, ffmpeg) 則被封裝到二進位檔案的 PATH 中。沒有運行時的 pip，不需要啟用虛擬環境 (venv)，也不需要 `npm install`。

**對於非 NixOS 使用者**，這僅改變了安裝步驟。之後的一切 (`hermes setup`, `hermes gateway install`, 編輯設定) 與標準安裝完全相同。

**對於 NixOS 模組使用者**，整個生命週期都不同：設定位於 `configuration.nix`，機密資訊透過 sops-nix/agenix 處理，服務是一個 systemd 單元 (unit)，且 CLI 的設定指令會被封鎖。你管理 hermes 的方式與管理任何其他 NixOS 服務相同。
:::

## 前置條件

- **已啟用 flakes 功能的 Nix** —— 推薦使用 [Determinate Nix](https://install.determinate.systems) (預設啟用 flakes)
- 你想要使用的服務之 **API 金鑰** (至少需要一個 OpenRouter 或 Anthropic 金鑰)

---

## 快速入門 (適用於任何 Nix 使用者)

不需要複製 (clone) 儲存庫。Nix 會自動獲取、建置並執行一切：

```bash
# 直接執行 (第一次使用時會建置，之後會快取)
nix run github:NousResearch/hermes-agent -- setup
nix run github:NousResearch/hermes-agent -- chat

# 或持久性安裝
nix profile install github:NousResearch/hermes-agent
hermes setup
hermes chat
```

執行 `nix profile install` 後，`hermes`, `hermes-agent` 和 `hermes-acp` 就會出現在你的 PATH 中。從這裡開始，工作流與 [標準安裝](./installation_zh_TW.md) 相同——`hermes setup` 會引導你選擇提供商，`hermes gateway install` 會設定 launchd (macOS) 或 systemd 使用者服務，設定檔則位於 `~/.hermes/`。

<details>
<summary><strong>從本地複製建置</strong></summary>

```bash
git clone https://github.com/NousResearch/hermes-agent.git
cd hermes-agent
nix build
./result/bin/hermes setup
```

</details>

---

## NixOS 模組

此 flake 匯出了 `nixosModules.default` —— 一個完整的 NixOS 服務模組，能以宣告方式管理使用者建立、目錄、設定產生、機密資訊、文件以及服務生命週期。

:::note
此模組需要 NixOS。對於非 NixOS 系統 (macOS, 其他 Linux 發行版)，請使用上述的 `nix profile install` 及標準 CLI 工作流。
:::

### 新增 Flake 輸入

```nix
# /etc/nixos/flake.nix (或你的系統 flake)
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hermes-agent.url = "github:NousResearch/hermes-agent";
  };

  outputs = { nixpkgs, hermes-agent, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        hermes-agent.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

### 最簡配置

```nix
# configuration.nix
{ config, ... }: {
  services.hermes-agent = {
    enable = true;
    settings.model.default = "anthropic/claude-sonnet-4";
    environmentFiles = [ config.sops.secrets."hermes-env".path ];
    addToSystemPackages = true;
  };
}
```

就這樣。`nixos-rebuild switch` 會建立 `hermes` 使用者、產生 `config.yaml`、配置機密資訊，並啟動 gateway —— 這是一個長駐服務，負責將代理連接到訊息平台 (Telegram, Discord 等) 並監聽傳入的訊息。

:::warning 機密資訊是必要的
上面的 `environmentFiles` 行假設你已配置 [sops-nix](https://github.com/Mic92/sops-nix) 或 [agenix](https://github.com/ryantm/agenix)。檔案應包含至少一個 LLM 提供商金鑰 (例如 `OPENROUTER_API_KEY=sk-or-...`)。詳情請參閱 [機密資訊管理](#機密資訊管理)。如果你還沒有機密資訊管理程式，可以先使用普通檔案——只需確保它不具備全域讀取權限：

```bash
echo "OPENROUTER_API_KEY=sk-or-your-key" | sudo install -m 0600 -o hermes /dev/stdin /var/lib/hermes/env
```

```nix
services.hermes-agent.environmentFiles = [ "/var/lib/hermes/env" ];
```
:::

:::tip addToSystemPackages
設定 `addToSystemPackages = true` 會產生兩個作用：將 `hermes` CLI 放入系統 PATH，**並且**在系統範圍內設定 `HERMES_HOME`，使互動式 CLI 與 gateway 服務共享狀態 (sessions, skills, cron)。若不設定此項，在 shell 中執行 `hermes` 會建立一個獨立的 `~/.hermes/` 目錄。
:::

:::info 容器感知的 CLI
當 `container.enable = true` 且 `addToSystemPackages = true` 時，主機上的**每個** `hermes` 指令都會自動路由到受管理的容器中。這意味著你的互動式 CLI 會話將運行在與 gateway 服務相同的環境中——並可存取所有容器內安裝的套件與工具。

- 路由是透明的：`hermes chat`, `hermes sessions list`, `hermes version` 等指令在底層都會 exec 到容器中執行。
- 所有 CLI 標記 (flags) 都會原樣轉發。
- 如果容器未執行，CLI 會重試一段時間 (互動式使用為 5 秒並顯示旋轉圖示，指令稿為 10 秒且不顯示訊息)，然後失敗並顯示明確的錯誤——不會有靜默的回退 (silent fallback)。
- 對於開發 hermes 程式碼庫的開發者，請設定 `HERMES_DEV=1` 以繞過容器路由並直接執行本地版本。

設定 `container.hostUsers` 以建立連向服務狀態目錄的 `~/.hermes` 符號連結，使主機 CLI 與容器共享會話、設定與記憶：

```nix
services.hermes-agent = {
  container.enable = true;
  container.hostUsers = [ "your-username" ];
  addToSystemPackages = true;
};
```

`hostUsers` 中列出的使用者會自動加入 `hermes` 群組以取得檔案存取權限。

**Podman 使用者：** NixOS 服務會以 root 身份執行容器。Docker 使用者透過 `docker` 群組的通訊端 (socket) 取得存取權，但 Podman 的 root 容器需要 sudo。請為你的容器運行環境授權無密碼 sudo：

```nix
security.sudo.extraRules = [{
  users = [ "your-username" ];
  commands = [{
    command = "/run/current-system/sw/bin/podman";
    options = [ "NOPASSWD" ];
  }];
}];
```

CLI 會自動偵測何時需要 sudo 並透明地使用它。若無此設定，你將需要手動執行 `sudo hermes chat`。
:::

### 驗證運作

執行 `nixos-rebuild switch` 後，檢查服務是否正在執行：

```bash
# 檢查服務狀態
systemctl status hermes-agent

# 查看日誌 (按 Ctrl+C 停止)
journalctl -u hermes-agent -f

# 如果 addToSystemPackages 為 true，測試 CLI
hermes version
hermes config       # 顯示產生的設定
```

### 選擇部署模式

模組支援兩種模式，由 `container.enable` 控制：

| | **原生 (Native)** (預設) | **容器 (Container)** |
|---|---|---|
| 執行方式 | 主機上強化的 systemd 服務 | 持久性 Ubuntu 容器，並掛載 `/nix/store` |
| 安全性 | `NoNewPrivileges`, `ProtectSystem=strict`, `PrivateTmp` | 容器隔離，在內部以非特權使用者執行 |
| 代理可自行安裝套件 | 否——僅限 Nix 提供的 PATH 上的工具 | 是——`apt`, `pip`, `npm` 安裝在重啟後依然存在 |
| 設定介面 | 相同 | 相同 |
| 何時選擇 | 標準部署、最高安全性、可重現性 | 代理需要運行時安裝套件、具備可變環境、實驗性工具 |

要啟用容器模式，只需新增一行：

```nix
{
  services.hermes-agent = {
    enable = true;
    container.enable = true;
    # ... 其餘配置相同
  };
}
```

:::info
容器模式會透過 `mkDefault` 自動啟用 `virtualisation.docker.enable`。如果你改用 Podman，請設定 `container.backend = "podman"` 並將 `virtualisation.docker.enable` 設為 `false`。
:::

---

## 設定

### 宣告式設定

`settings` 選項接受任意的屬性集 (attrset)，並將其渲染為 `config.yaml`。它支援跨多個模組定義的深度合併 (透過 `lib.recursiveUpdate`)，因此你可以將設定分散在不同的檔案中：

```nix
# base.nix
services.hermes-agent.settings = {
  model.default = "anthropic/claude-sonnet-4";
  toolsets = [ "all" ];
  terminal = { backend = "local"; timeout = 180; };
};

# personality.nix
services.hermes-agent.settings = {
  display = { compact = false; personality = "kawaii"; };
  memory = { memory_enabled = true; user_profile_enabled = true; };
};
```

兩者在評估時會進行深度合併。Nix 宣告的鍵值 (keys) 永遠優先於磁碟上現有的 `config.yaml` 鍵值，但**Nix 未接觸的使用者自定義鍵值會被保留**。這意味著如果代理或手動編輯新增了如 `skills.disabled` 或 `streaming.enabled` 等鍵值，它們在 `nixos-rebuild switch` 後依然存在。

:::note 模型命名
`settings.model.default` 使用提供商期望的模型識別碼。對於 [OpenRouter](https://openrouter.ai) (預設)，這些識別碼類似於 `"anthropic/claude-sonnet-4"` 或 `"google/gemini-3-flash"`。如果你直接使用提供商 (Anthropic, OpenAI)，請設定 `settings.model.base_url` 指向其 API 並使用其原生模型 ID (例如 `"claude-sonnet-4-20250514"`)。未設定 `base_url` 時，Hermes 預設使用 OpenRouter。
:::

:::tip 探索可用的設定鍵值
執行 `nix build .#configKeys && cat result` 以查看從 Python 的 `DEFAULT_CONFIG` 擷取出的每個末端設定鍵值。你可以將現有的 `config.yaml` 內容貼到 `settings` 屬性集中——其結構是 1:1 對應的。
:::

<details>
<summary><strong>完整範例：所有常用自訂設定</strong></summary>

```nix
{ config, ... }: {
  services.hermes-agent = {
    enable = true;
    container.enable = true;

    # ── 模型 ──────────────────────────────────────────────────────────
    settings = {
      model = {
        base_url = "https://openrouter.ai/api/v1";
        default = "anthropic/claude-opus-4.6";
      };
      toolsets = [ "all" ];
      max_turns = 100;
      terminal = { backend = "local"; cwd = "."; timeout = 180; };
      compression = {
        enabled = true;
        threshold = 0.85;
        summary_model = "google/gemini-3-flash-preview";
      };
      memory = { memory_enabled = true; user_profile_enabled = true; };
      display = { compact = false; personality = "kawaii"; };
      agent = { max_turns = 60; verbose = false; };
    };

    # ── 機密資訊 ────────────────────────────────────────────────────────
    environmentFiles = [ config.sops.secrets."hermes-env".path ];

    # ── 文件 ──────────────────────────────────────────────────────
    documents = {
      "SOUL.md" = builtins.readFile /home/user/.hermes/SOUL.md;
      "USER.md" = ./documents/USER.md;
    };

    # ── MCP 伺服器 ────────────────────────────────────────────────────
    mcpServers.filesystem = {
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-filesystem" "/data/workspace" ];
    };

    # ── 容器選項 ──────────────────────────────────────────────
    container = {
      image = "ubuntu:24.04";
      backend = "docker";
      hostUsers = [ "your-username" ];
      extraVolumes = [ "/home/user/projects:/projects:rw" ];
      extraOptions = [ "--gpus" "all" ];
    };

    # ── 服務微調 ─────────────────────────────────────────────────
    addToSystemPackages = true;
    extraArgs = [ "--verbose" ];
    restart = "always";
    restartSec = 5;
  };
}
```

</details>

### 逃生艙：使用你自己的設定檔

如果你寧願完全在 Nix 之外管理 `config.yaml`，請使用 `configFile`：

```nix
services.hermes-agent.configFile = /etc/hermes/config.yaml;
```

這將完全繞過 `settings` —— 不會進行合併，也不會產生設定。檔案會在每次啟用時原樣複製到 `$HERMES_HOME/config.yaml`。

### 自訂備忘錄

Nix 使用者最常自訂之項目的快速參考：

| 我想要... | 選項 | 範例 |
|---|---|---|
| 更改 LLM 模型 | `settings.model.default` | `"anthropic/claude-sonnet-4"` |
| 使用不同的提供商端點 | `settings.model.base_url` | `"https://openrouter.ai/api/v1"` |
| 新增 API 金鑰 | `environmentFiles` | `[ config.sops.secrets."hermes-env".path ]` |
| 給代理一個個性 | `documents."SOUL.md"` | `builtins.readFile ./my-soul.md` |
| 新增 MCP 工具伺服器 | `mcpServers.<name>` | 參閱 [MCP 伺服器](#mcp-伺服器) |
| 將主機目錄掛載到容器 | `container.extraVolumes` | `[ "/data:/data:rw" ]` |
| 將 GPU 存取權傳遞給容器 | `container.extraOptions` | `[ "--gpus" "all" ]` |
| 使用 Podman 代替 Docker | `container.backend` | `"podman"` |
| 共享主機 CLI 與容器狀態 | `container.hostUsers` | `[ "sidbin" ]` |
| 新增工具到服務 PATH (僅限原生) | `extraPackages` | `[ pkgs.pandoc pkgs.imagemagick ]` |
| 使用自訂基礎映像檔 | `container.image` | `"ubuntu:24.04"` |
| 覆蓋 hermes 套件 | `package` | `inputs.hermes-agent.packages.${system}.default.override { ... }` |
| 更改狀態目錄 | `stateDir` | `"/opt/hermes"` |
| 設定代理的工作目錄 | `workingDirectory` | `"/home/user/projects"` |

---

## 機密資訊管理

:::danger 絕對不要將 API 金鑰放在 `settings` 或 `environment` 中
Nix 表達式中的值最終會進入 `/nix/store`，這是具備全域讀取權限的。請務必搭配機密資訊管理程式使用 `environmentFiles`。
:::

`environment` (非機密變數) 與 `environmentFiles` (機密檔案) 會在啟用時 (`nixos-rebuild switch`) 合併至 `$HERMES_HOME/.env`。Hermes 在每次啟動時都會讀取此檔案，因此變更會在 `systemctl restart hermes-agent` 後生效——不需要重新建立容器。

### sops-nix

```nix
{
  sops = {
    defaultSopsFile = ./secrets/hermes.yaml;
    age.keyFile = "/home/user/.config/sops/age/keys.txt";
    secrets."hermes-env" = { format = "yaml"; };
  };

  services.hermes-agent.environmentFiles = [
    config.sops.secrets."hermes-env".path
  ];
}
```

機密檔案包含鍵值對：

```yaml
# secrets/hermes.yaml (經 sops 加密)
hermes-env: |
    OPENROUTER_API_KEY=sk-or-...
    TELEGRAM_BOT_TOKEN=123456:ABC...
    ANTHROPIC_API_KEY=sk-ant-...
```

### agenix

```nix
{
  age.secrets.hermes-env.file = ./secrets/hermes-env.age;

  services.hermes-agent.environmentFiles = [
    config.age.secrets.hermes-env.path
  ];
}
```

### OAuth / 認證種子 (Auth Seeding)

對於需要 OAuth 的平台 (例如 Discord)，使用 `authFile` 在首次部署時置入憑證：

```nix
{
  services.hermes-agent = {
    authFile = config.sops.secrets."hermes/auth.json".path;
    # authFileForceOverwrite = true;  # 每次啟用時皆覆蓋
  };
}
```

僅當 `auth.json` 尚未存在時才會複製檔案 (除非 `authFileForceOverwrite = true`)。運行時的 OAuth 權杖 (token) 重新整理會寫入狀態目錄並在重建後保留。

---

## 文件

`documents` 選項會將檔案安裝到代理的工作目錄中 (代理將其視為工作區的 `workingDirectory`)。Hermes 依慣例尋找特定的檔名：

- **`SOUL.md`** —— 代理的系統提示 / 個性。Hermes 在啟動時會讀取此檔案，並將其作為塑造其在所有對話中行為的持久指令。
- **`USER.md`** —— 關於代理正在與之互動的使用者的上下文。
- 你放在這裡的任何其他檔案對代理來說都是可見的工作區檔案。

```nix
{
  services.hermes-agent.documents = {
    "SOUL.md" = ''
      你是一個專精於 NixOS 打包的得力研究助手。
      請務必引用來源並優先選擇可重現的解決方案。
    '';
    "USER.md" = ./documents/USER.md;  # 路徑引用，從 Nix store 複製
  };
}
```

值可以是內嵌字串或路徑引用。檔案會在每次 `nixos-rebuild switch` 時安裝。

---

## MCP 伺服器

`mcpServers` 選項以宣告方式配置 [MCP (模型上下文協議)](https://modelcontextprotocol.io) 伺服器。每個伺服器使用 **stdio** (本地指令) 或 **HTTP** (遠端 URL) 傳輸方式。

### Stdio 傳輸 (本地伺服器)

```nix
{
  services.hermes-agent.mcpServers = {
    filesystem = {
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-filesystem" "/data/workspace" ];
    };
    github = {
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-github" ];
      env.GITHUB_PERSONAL_ACCESS_TOKEN = "\${GITHUB_TOKEN}"; # 從 .env 解析
    };
  };
}
```

:::tip
`env` 值中的環境變數會在運行時從 `$HERMES_HOME/.env` 解析。請使用 `environmentFiles` 來注入機密資訊——絕對不要將權杖直接放入 Nix 設定中。
:::

### HTTP 傳輸 (遠端伺服器)

```nix
{
  services.hermes-agent.mcpServers.remote-api = {
    url = "https://mcp.example.com/v1/mcp";
    headers.Authorization = "Bearer \${MCP_REMOTE_API_KEY}";
    timeout = 180;
  };
}
```

### 具備 OAuth 的 HTTP 傳輸

對於使用 OAuth 2.1 的伺服器，請設定 `auth = "oauth"`。Hermes 實作了完整的 PKCE 流程——元數據發現、動態用戶端註冊、權杖交換以及自動重新整理。

```nix
{
  services.hermes-agent.mcpServers.my-oauth-server = {
    url = "https://mcp.example.com/mcp";
    auth = "oauth";
  };
}
```

權杖儲存在 `$HERMES_HOME/mcp-tokens/<server-name>.json` 中，並在重啟與重建後保留。

<details>
<summary><strong>在無前端伺服器上進行初始 OAuth 授權</strong></summary>

首次 OAuth 授權需要基於瀏覽器的同意流程。在無前端 (headless) 部署中，Hermes 會將授權 URL 列印到 stdout/日誌中，而不是開啟瀏覽器。

**選項 A：互動式引導** —— 透過 `docker exec` (容器) 或 `sudo -u hermes` (原生) 執行一次流程：

```bash
# 容器模式
docker exec -it hermes-agent \
  hermes mcp add my-oauth-server --url https://mcp.example.com/mcp --auth oauth

# 原生模式
sudo -u hermes HERMES_HOME=/var/lib/hermes/.hermes \
  hermes mcp add my-oauth-server --url https://mcp.example.com/mcp --auth oauth
```

容器使用 `--network=host`，因此主機瀏覽器可以存取 `127.0.0.1` 上的 OAuth 回呼監聽器。

**選項 B：預置權杖** —— 在工作站上完成流程，然後複製權杖：

```bash
hermes mcp add my-oauth-server --url https://mcp.example.com/mcp --auth oauth
scp ~/.hermes/mcp-tokens/my-oauth-server{,.client}.json \
    server:/var/lib/hermes/.hermes/mcp-tokens/
# 確保：chown hermes:hermes, chmod 0600
```

</details>

### 取樣 (Sampling，伺服器發起的 LLM 請求)

某些 MCP 伺服器可以向代理請求 LLM 完成 (completion)：

```nix
{
  services.hermes-agent.mcpServers.analysis = {
    command = "npx";
    args = [ "-y" "analysis-server" ];
    sampling = {
      enabled = true;
      model = "google/gemini-3-flash";
      max_tokens_cap = 4096;
      timeout = 30;
      max_rpm = 10;
    };
  };
}
```

---

## 受管理模式 (Managed Mode)

當 hermes 透過 NixOS 模組執行時，以下 CLI 指令會被**封鎖**，並顯示導向 `configuration.nix` 的說明錯誤：

| 被封鎖的指令 | 原因 |
|---|---|
| `hermes setup` | 設定是宣告式的——請編輯 Nix 設定中的 `settings` |
| `hermes config edit` | 設定是從 `settings` 產生的 |
| `hermes config set <key> <value>` | 設定是從 `settings` 產生的 |
| `hermes gateway install` | systemd 服務是由 NixOS 管理的 |
| `hermes gateway uninstall` | systemd 服務是由 NixOS 管理的 |

這可以防止 Nix 宣告的內容與磁碟上的內容發生偏差。偵測使用兩個訊號：

1. **`HERMES_MANAGED=true`** 環境變數 —— 由 systemd 服務設定，對 gateway 處理程序可見。
2. `HERMES_HOME` 中的 **`.managed` 標記檔案** —— 由啟用指令稿設定，對互動式 shell 可見 (例如，`docker exec -it hermes-agent hermes config set ...` 也會被封鎖)。

要更改設定，請編輯你的 Nix 設定並執行 `sudo nixos-rebuild switch`。

---

## 容器架構

:::info
本節僅在你使用 `container.enable = true` 時才相關。原生模式部署請跳過此節。
:::

啟用容器模式時，hermes 運行在一個持久性的 Ubuntu 容器中，並從主機唯讀掛載 Nix 建置的二進位檔案：

```
主機 (Host)                              容器 (Container)
────                                    ─────────
/nix/store/...-hermes-agent-0.1.0  ──►  /nix/store/... (ro)
~/.hermes -> /var/lib/hermes/.hermes       (符號連結橋接，依 hostUsers)
/var/lib/hermes/                    ──►  /data/          (rw)
  ├── current-package -> /nix/store/...    (符號連結，每次重建時更新)
  ├── .gc-root -> /nix/store/...           (防止 nix-collect-garbage)
  ├── .container-identity                  (sha256 雜湊，觸發重新建立)
  ├── .hermes/                             (HERMES_HOME)
  │   ├── .env                             (從 environment + environmentFiles 合併)
  │   ├── config.yaml                      (Nix 產生，啟用時進行深度合併)
  │   ├── .managed                         (標記檔案)
  │   ├── .container-mode                  (路由元數據：backend, exec_user 等)
  │   ├── state.db, sessions/, memories/   (運行時狀態)
  │   └── mcp-tokens/                      (MCP 伺服器的 OAuth 權杖)
  ├── home/                                ──►  /home/hermes    (rw)
  └── workspace/                           (MESSAGING_CWD)
      ├── SOUL.md                          (源自 documents 選項)
      └── (代理建立的檔案)

容器可寫層 (apt/pip/npm):   /usr, /usr/local, /tmp
```

Nix 建置的二進位檔案可以在 Ubuntu 容器中運作，是因為掛載了 `/nix/store` —— 它自備了解譯器與所有依賴項，因此不依賴容器的系統函式庫。容器進入點透過 `current-package` 符號連結進行解析：`/data/current-package/bin/hermes gateway run --replace`。在執行 `nixos-rebuild switch` 時，僅更新符號連結——容器會持續執行。

### 什麼內容在什麼情況下保留

| 事件 | 容器重新建立？ | `/data` (狀態) | `/home/hermes` | 可寫層 (`apt`/`pip`/`npm`) |
|---|---|---|---|---|
| `systemctl restart hermes-agent` | 否 | 保留 | 保留 | 保留 |
| `nixos-rebuild switch` (程式碼變更) | 否 (更新符號連結) | 保留 | 保留 | 保留 |
| 主機重啟 | 否 | 保留 | 保留 | 保留 |
| `nix-collect-garbage` | 否 (GC root) | 保留 | 保留 | 保留 |
| 映像檔變更 (`container.image`) | **是** | 保留 | 保留 | **遺失** |
| 磁碟卷/選項變更 | **是** | 保留 | 保留 | **遺失** |
| `environment`/`environmentFiles` 變更 | 否 | 保留 | 保留 | 保留 |

僅當容器的**識別雜湊 (identity hash)** 變更時才會重新建立容器。雜湊涵蓋：架構版本、映像檔、`extraVolumes`、`extraOptions` 以及進入點指令稿。環境變數、設定、文件或 hermes 套件本身的變更**不**會觸發重新建立。

:::warning 可寫層遺失
當識別雜湊變更 (映像檔升級、新磁碟卷、新容器選項) 時，容器會被銷毀，並從新抓取的 `container.image` 重新建立。可寫層中任何透過 `apt install`, `pip install` 或 `npm install` 安裝的套件都會遺失。`/data` 與 `/home/hermes` 中的狀態會保留 (這些是掛載的磁碟卷)。

如果代理依賴特定套件，請考慮將其封裝到自訂映像檔中 (`container.image = "my-registry/hermes-base:latest"`)，或是在代理的 SOUL.md 中撰寫安裝指令稿。
:::

### GC Root 保護

`preStart` 指令稿會在 `${stateDir}/.gc-root` 建立一個指向目前 hermes 套件的 GC root。這可以防止 `nix-collect-garbage` 移除正在運行的二進位檔案。如果 GC root 損毀，重啟服務會重新建立它。

---

## 開發

### 開發 Shell (Dev Shell)

flake 提供了一個具備 Python 3.11, uv, Node.js 以及所有運行時工具的開發 shell：

```bash
cd hermes-agent
nix develop

# Shell 提供：
#   - Python 3.11 + uv (第一次進入時依賴項會安裝到 .venv)
#   - PATH 上的 Node.js 20, ripgrep, git, openssh, ffmpeg
#   - 戳記檔案 (stamp-file) 優化：若依賴項未變動，再次進入幾乎是瞬間完成
hermes setup
hermes chat
```

### direnv (推薦)

內附的 `.envrc` 會自動啟用開發 shell：

```bash
cd hermes-agent
direnv allow    # 僅需執行一次
# 之後進入幾乎是瞬間完成 (戳記檔案會跳過依賴項安裝)
```

### Flake 檢查 (Flake Checks)

flake 包含在 CI 與本地端執行的建置時驗證：

```bash
# 執行所有檢查
nix flake check

# 個別檢查
nix build .#checks.x86_64-linux.package-contents   # 二進位檔案存在 + 版本
nix build .#checks.x86_64-linux.entry-points-sync  # pyproject.toml ↔ Nix 套件同步
nix build .#checks.x86_64-linux.cli-commands        # gateway/config 子指令
nix build .#checks.x86_64-linux.managed-guard       # HERMES_MANAGED 阻擋變動
nix build .#checks.x86_64-linux.bundled-skills      # 套件中包含技能
nix build .#checks.x86_64-linux.config-roundtrip    # 合併指令稿保留使用者鍵值
```

<details>
<summary><strong>各項檢查的驗證內容</strong></summary>

| 檢查項 | 測試內容 |
|---|---|
| `package-contents` | `hermes` 與 `hermes-agent` 二進位檔案存在且 `hermes version` 可執行 |
| `entry-points-sync` | `pyproject.toml` 中的每個 `[project.scripts]` 項目在 Nix 套件中都有封裝好的二進位檔案 |
| `cli-commands` | `hermes --help` 展示 `gateway` 與 `config` 子指令 |
| `managed-guard` | `HERMES_MANAGED=true hermes config set ...` 列印 NixOS 錯誤訊息 |
| `bundled-skills` | skills 目錄存在，包含 SKILL.md 檔案，且封裝程式中設定了 `HERMES_BUNDLED_SKILLS` |
| `config-roundtrip` | 7 種合併情境：全新安裝、Nix 覆蓋、使用者鍵值保留、混合合併、MCP 增量合併、巢狀深度合併、等冪性 (idempotency) |

</details>

---

## 選項參考

### 核心 (Core)

| 選項 | 類型 | 預設值 | 描述 |
|---|---|---|---|
| `enable` | `bool` | `false` | 啟用 hermes-agent 服務 |
| `package` | `package` | `hermes-agent` | 要使用的 hermes-agent 套件 |
| `user` | `str` | `"hermes"` | 系統使用者 |
| `group` | `str` | `"hermes"` | 系統群組 |
| `createUser` | `bool` | `true` | 自動建立使用者/群組 |
| `stateDir` | `str` | `"/var/lib/hermes"` | 狀態目錄 (`HERMES_HOME` 的上層) |
| `workingDirectory` | `str` | `"${stateDir}/workspace"` | 代理工作目錄 (`MESSAGING_CWD`) |
| `addToSystemPackages` | `bool` | `false` | 將 `hermes` CLI 新增到系統 PATH，並設定全域 `HERMES_HOME` |

### 配置設定

| 選項 | 類型 | 預設值 | 描述 |
|---|---|---|---|
| `settings` | `attrs` (深度合併) | `{}` | 渲染為 `config.yaml` 的宣告式設定。支援任意巢狀結構；多個定義透過 `lib.recursiveUpdate` 合併 |
| `configFile` | `null` 或 `path` | `null` | 現有 `config.yaml` 的路徑。設定後會完全覆蓋 `settings` |

### 機密資訊與環境變數

| 選項 | 類型 | 預設值 | 描述 |
|---|---|---|---|
| `environmentFiles` | `listOf str` | `[]` | 包含機密資訊的環境變數檔案路徑。在啟用時合併至 `$HERMES_HOME/.env` |
| `environment` | `attrsOf str` | `{}` | 非機密環境變數。**在 Nix store 中可見** —— 請勿放入機密資訊 |
| `authFile` | `null` 或 `path` | `null` | OAuth 憑證種子。僅在首次部署時複製 |
| `authFileForceOverwrite` | `bool` | `false` | 每次啟用時皆從 `authFile` 覆蓋 `auth.json` |

### 文件

| 選項 | 類型 | 預設值 | 描述 |
|---|---|---|---|
| `documents` | `attrsOf (either str path)` | `{}` | 工作區檔案。鍵名為檔名，值為內嵌字串或路徑。在啟用時安裝到 `workingDirectory` |

### MCP 伺服器

| 選項 | 類型 | 預設值 | 描述 |
|---|---|---|---|
| `mcpServers` | `attrsOf submodule` | `{}` | MCP 伺服器定義，合併至 `settings.mcp_servers` |
| `mcpServers.<name>.command` | `null` 或 `str` | `null` | 伺服器指令 (stdio 傳輸) |
| `mcpServers.<name>.args` | `listOf str` | `[]` | 指令引數 |
| `mcpServers.<name>.env` | `attrsOf str` | `{}` | 伺服器處理程序的環境變數 |
| `mcpServers.<name>.url` | `null` 或 `str` | `null` | 伺服器端點 URL (HTTP/StreamableHTTP 傳輸) |
| `mcpServers.<name>.headers` | `attrsOf str` | `{}` | HTTP 標頭，例如 `Authorization` |
| `mcpServers.<name>.auth` | `null` 或 `"oauth"` | `null` | 認證方式。`"oauth"` 啟用 OAuth 2.1 PKCE |
| `mcpServers.<name>.enabled` | `bool` | `true` | 啟用或停用此伺服器 |
| `mcpServers.<name>.timeout` | `null` 或 `int` | `null` | 工具調用逾時秒數 (預設：120) |
| `mcpServers.<name>.connect_timeout` | `null` 或 `int` | `null` | 連線逾時秒數 (預設：60) |
| `mcpServers.<name>.tools` | `null` 或 `submodule` | `null` | 工具過濾 (`include`/`exclude` 列表) |
| `mcpServers.<name>.sampling` | `null` 或 `submodule` | `null` | 伺服器發起的 LLM 請求的取樣配置 |

### 服務行為

| 選項 | 類型 | 預設值 | 描述 |
|---|---|---|---|
| `extraArgs` | `listOf str` | `[]` | `hermes gateway` 的額外引數 |
| `extraPackages` | `listOf package` | `[]` | 服務 PATH 上的額外套件 (僅限原生模式) |
| `restart` | `str` | `"always"` | systemd `Restart=` 策略 |
| `restartSec` | `int` | `5` | systemd `RestartSec=` 數值 |

### 容器

| 選項 | 類型 | 預設值 | 描述 |
|---|---|---|---|
| `container.enable` | `bool` | `false` | 啟用 OCI 容器模式 |
| `container.backend` | `enum ["docker" "podman"]` | `"docker"` | 容器運行環境 |
| `container.image` | `str` | `"ubuntu:24.04"` | 基礎映像檔 (運行時抓取) |
| `container.extraVolumes` | `listOf str` | `[]` | 額外掛載磁碟卷 (`host:container:mode`) |
| `container.extraOptions` | `listOf str` | `[]` | 傳遞給 `docker create` 的額外引數 |
| `container.hostUsers` | `listOf str` | `[]` | 取得 `~/.hermes` 符號連結並自動加入 `hermes` 群組的互動式使用者 |

---

## 目錄配置

### 原生模式

```
/var/lib/hermes/                     # stateDir (由 hermes:hermes 擁有, 0750)
├── .hermes/                         # HERMES_HOME
│   ├── config.yaml                  # Nix 產生 (每次重建時深度合併)
│   ├── .managed                     # 標記：禁止 CLI 設定變動
│   ├── .env                         # 從 environment + environmentFiles 合併
│   ├── auth.json                    # OAuth 憑證 (置入後由系統自行管理)
│   ├── gateway.pid
│   ├── state.db
│   ├── mcp-tokens/                  # MCP 伺服器的 OAuth 權杖
│   ├── sessions/
│   ├── memories/
│   ├── skills/
│   ├── cron/
│   └── logs/
├── home/                            # 代理 HOME
└── workspace/                       # MESSAGING_CWD
    ├── SOUL.md                      # 源自 documents 選項
    └── (代理建立的檔案)
```

### 容器模式

相同配置，掛載至容器中：

| 容器路徑 | 主機路徑 | 模式 | 備註 |
|---|---|---|---|
| `/nix/store` | `/nix/store` | `ro` | Hermes 二進位檔案 + 所有 Nix 依賴項 |
| `/data` | `/var/lib/hermes` | `rw` | 所有狀態、設定、工作區 |
| `/home/hermes` | `${stateDir}/home` | `rw` | 持久性的代理 home —— `pip install --user`, 工具快取 |
| `/usr`, `/usr/local`, `/tmp` | (可寫層) | `rw` | `apt`/`pip`/`npm` 安裝內容 —— 重啟後保留，重新建立時遺失 |

---

## 更新

```bash
# 更新 flake 輸入
nix flake update hermes-agent --flake /etc/nixos

# 重建
sudo nixos-rebuild switch
```

在容器模式下，`current-package` 符號連結會更新，代理重啟後會採用新的二進位檔案。不會重新建立容器，也不會遺失已安裝的套件。

---

## 疑難排解

:::tip Podman 使用者
下方的所有 `docker` 指令對於 `podman` 亦同。如果你設定了 `container.backend = "podman"`，請自行替換指令。
:::

### 服務日誌

```bash
# 兩種模式都使用相同的 systemd 單元
journalctl -u hermes-agent -f

# 容器模式：也可直接查看
docker logs -f hermes-agent
```

### 容器檢查

```bash
systemctl status hermes-agent
docker ps -a --filter name=hermes-agent
docker inspect hermes-agent --format='{{.State.Status}}'
docker exec -it hermes-agent bash
docker exec hermes-agent readlink /data/current-package
docker exec hermes-agent cat /data/.container-identity
```

### 強制重新建立容器

如果你需要重設可寫層 (全新的 Ubuntu)：

```bash
sudo systemctl stop hermes-agent
docker rm -f hermes-agent
sudo rm /var/lib/hermes/.container-identity
sudo systemctl start hermes-agent
```

### 驗證機密資訊已載入

如果代理已啟動但無法通過 LLM 提供商認證，請檢查 `.env` 檔案是否已正確合併：

```bash
# 原生模式
sudo -u hermes cat /var/lib/hermes/.hermes/.env

# 容器模式
docker exec hermes-agent cat /data/.hermes/.env
```

### GC Root 驗證

```bash
nix-store --query --roots $(docker exec hermes-agent readlink /data/current-package)
```

### 常見問題

| 症狀 | 原因 | 修復方法 |
|---|---|---|
| `Cannot save configuration: managed by NixOS` | CLI 防護已啟用 | 編輯 `configuration.nix` 並執行 `nixos-rebuild switch` |
| 容器非預期地重新建立 | `extraVolumes`, `extraOptions` 或 `image` 變更 | 這是預期行為——可寫層會重設。請重新安裝套件或使用自訂映像檔 |
| `hermes version` 顯示舊版本 | 容器未重啟 | `systemctl restart hermes-agent` |
| 對於 `/var/lib/hermes` 權限不足 | 狀態目錄權限為 `0750 hermes:hermes` | 使用 `docker exec` 或 `sudo -u hermes` |
| `nix-collect-garbage` 移除了 hermes | 遺失 GC root | 重啟服務 (preStart 會重新建立 GC root) |
| `no container with name or ID "hermes-agent"` (Podman) | 一般使用者看不到 Podman root 容器 | 為 podman 新增無密碼 sudo (參閱 [容器感知的 CLI](#容器感知的-cli) 小節) |
| `unable to find user hermes` | 容器仍在啟動中 (進入點尚未建立使用者) | 等待幾秒後重試 —— CLI 會自動重試 |
