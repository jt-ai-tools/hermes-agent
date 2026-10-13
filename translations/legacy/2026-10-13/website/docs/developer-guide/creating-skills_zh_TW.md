---
sidebar_position: 3
title: "建立技能"
description: "如何為 Hermes Agent 建立技能 — SKILL.md 格式、開發準則與發佈"
---

# 建立技能

技能 (Skills) 是為 Hermes Agent 增加新功能的首選方式。開發技能比開發工具更容易，不需要修改代理的程式碼，且可以與社群分享。

## 應該開發技能還是工具？

在以下情況，請選擇開發**技能**：
- 該功能可以透過指令、Shell 指令和現有工具來表達。
- 它封裝了一個外部 CLI 或 API，代理可以透過 `terminal` 或 `web_extract` 呼叫。
- 它不需要在代理中內置自定義 Python 整合或 API 金鑰管理。
- 範例：arXiv 搜尋、Git 工作流、Docker 管理、PDF 處理、透過 CLI 工具發送電子郵件。

在以下情況，請選擇開發**工具**：
- 它需要與 API 金鑰、認證流程或多組件配置進行端對端整合。
- 它需要每次都精確執行的自定義處理邏輯。
- 它處理二進位資料、串流或即時事件。
- 範例：瀏覽器自動化、TTS、視覺分析。

## 技能目錄結構

內建技能位於 `skills/` 目錄中，並按類別組織。官方選配技能在 `optional-skills/` 中使用相同的結構：

```text
skills/
├── research/
│   └── arxiv/
│       ├── SKILL.md              # 必填：主要指令說明
│       └── scripts/              # 選填：輔助腳本
│           └── search_arxiv.py
├── productivity/
│   └── ocr-and-documents/
│       ├── SKILL.md
│       ├── scripts/
│       └── references/
└── ...
```

## SKILL.md 格式

```markdown
---
name: my-skill
description: 簡短說明 (顯示於技能搜尋結果)
version: 1.0.0
author: 您的名字
license: MIT
platforms: [macos, linux]          # 選填 — 限制於特定的作業系統平台
                                   #   有效值：macos, linux, windows
                                   #   省略則在所有平台載入 (預設)
metadata:
  hermes:
    tags: [類別, 子類別, 關鍵字]
    related_skills: [其他技能名稱]
    requires_toolsets: [web]            # 選填 — 僅在這些工具集啟用時顯示
    requires_tools: [web_search]        # 選填 — 僅在這些工具可用時顯示
    fallback_for_toolsets: [browser]    # 選填 — 當這些工具集啟用時隱藏
    fallback_for_tools: [browser_navigate]  # 選填 — 當這些工具存在時隱藏
    config:                              # 選填 — 技能所需的 config.yaml 設定
      - key: my.setting
        description: "此設定控制的內容"
        default: "合理的預設值"
        prompt: "設定時顯示的提示文字"
required_environment_variables:          # 選填 — 技能所需的環境變數
  - name: MY_API_KEY
    prompt: "輸入您的 API 金鑰"
    help: "請至 https://example.com 取得"
    required_for: "API 存取權限"
---

# 技能標題

簡短介紹。

## 何時使用
觸發條件 — 代理何時應載入此技能？

## 快速參考
常見指令或 API 呼叫的表格。

## 程序
代理遵循的逐步說明。

## 常見陷阱
已知的失敗模式以及如何處理。

## 驗證
代理如何確認操作已成功。
```

### 特定平台的技能

技能可以透過 `platforms` 欄位限制僅在特定的作業系統上運作：

```yaml
platforms: [macos]            # 僅限 macOS (例如：iMessage, Apple Reminders)
platforms: [macos, linux]     # 支援 macOS 與 Linux
platforms: [windows]          # 僅限 Windows
```

設定後，在不相容的平台上，該技能會自動在系統提示詞、`skills_list()` 以及斜線指令中隱藏。如果省略或為空，則在所有平台上載入（向下相容）。

### 條件式技能啟用

技能可以宣告對特定工具或工具集的相依性。這控制了該技能是否出現在特定對話的系統提示詞中。

```yaml
metadata:
  hermes:
    requires_toolsets: [web]           # 如果 web 工具集未啟用則隱藏
    requires_tools: [web_search]       # 如果 web_search 工具不可用則隱藏
    fallback_for_toolsets: [browser]   # 如果 browser 工具集已啟用則隱藏
    fallback_for_tools: [browser_navigate]  # 如果 browser_navigate 可用則隱藏
```

| 欄位 | 行為 |
|-------|----------|
| `requires_toolsets` | 當列表中的任一工具集**不可用**時，技能會被**隱藏** |
| `requires_tools` | 當列表中的任一工具**不可用**時，技能會被**隱藏** |
| `fallback_for_toolsets` | 當列表中的任一工具集**可用**時，技能會被**隱藏** |
| `fallback_for_tools` | 當列表中的任一工具**可用**時，技能會被**隱藏** |

**`fallback_for_*` 的使用場景：** 建立一個作為主要工具不可用時的替代方案技能。例如，一個 `duckduckgo-search` 技能設定 `fallback_for_tools: [web_search]`，則僅在未配置需要 API 金鑰的網路搜尋工具時才會顯示。

**`requires_*` 的使用場景：** 建立一個僅在特定工具存在時才有意義的技能。例如，一個需要 `requires_toolsets: [web]` 的網頁抓取工作流技能，在停用網路工具時不會干擾提示詞。

### 環境變數需求

技能可以宣告其所需的環境變數。當透過 `skill_view` 載入技能時，其所需的變數會自動註冊，並透傳到沙盒執行環境（terminal, execute_code）。

```yaml
required_environment_variables:
  - name: TENOR_API_KEY
    prompt: "Tenor API 金鑰"               # 向使用者要求輸入時顯示
    help: "請至 https://tenor.com 取得金鑰"  # 說明文字或 URL
    required_for: "GIF 搜尋功能"           # 哪個功能需要此變數
```

每個條目支援：
- `name` (必填) — 環境變數名稱
- `prompt` (選填) — 向使用者詢問數值時的提示文字
- `help` (選填) — 取得數值的說明文字或 URL
- `required_for` (選填) — 描述哪個功能需要此變數

使用者也可以在 `config.yaml` 中手動配置透傳變數：

```yaml
terminal:
  env_passthrough:
    - MY_CUSTOM_VAR
    - ANOTHER_VAR
```

範例請參閱 `skills/apple/` 中的僅限 macOS 技能。

## 載入時的安全設定

當技能需要 API 金鑰或令牌時，請使用 `required_environment_variables`。缺少數值**不會**隱藏該技能，相反地，當在本地 CLI 中載入技能時，Hermes 會安全地提示輸入。

```yaml
required_environment_variables:
  - name: TENOR_API_KEY
    prompt: Tenor API key
    help: Get a key from https://developers.google.com/tenor
    required_for: full functionality
```

使用者可以跳過設定並繼續載入技能。Hermes 絕不會將原始祕密值暴露給模型。在閘道器與通訊對話中，會顯示本地設定指南，而不是在對話中收集祕密。

:::tip 沙盒透傳 (Sandbox Passthrough)
當您的技能載入時，任何已設定且宣告的 `required_environment_variables` 都會**自動透傳**到 `execute_code` 與 `terminal` 沙盒 — 包括 Docker 與 Modal 等遠端後端。您的技能腳本可以存取 `$TENOR_API_KEY` (或在 Python 中使用 `os.environ["TENOR_API_KEY"]`)，使用者無需額外配置。詳情請參閱 [環境變數透傳](/docs/user-guide/security#environment-variable-passthrough)。
:::

舊有的 `prerequisites.env_vars` 仍作為向下相容的別名受到支援。

### 配置設定 (config.yaml)

技能可以宣告儲存在 `config.yaml` 中 `skills.config` 命名空間下的非祕密設定。與環境變數（儲存在 `.env` 中的祕密）不同，配置設定用於路徑、偏好設定以及其他非敏感數值。

```yaml
metadata:
  hermes:
    config:
      - key: wiki.path
        description: LLM Wiki 知識庫目錄路徑
        default: "~/wiki"
        prompt: Wiki 目錄路徑
      - key: wiki.domain
        description: Wiki 涵蓋的領域
        default: ""
        prompt: Wiki 領域 (例如：AI/ML 研究)
```

每個條目支援：
- `key` (必填) — 設定的點路徑 (例如：`wiki.path`)
- `description` (必填) — 解釋此設定控制的內容
- `default` (選填) — 使用者未配置時的預設值
- `prompt` (選填) — 在執行 `hermes config migrate` 時顯示的提示文字；若未設定則降級使用 `description`

**運作方式：**

1. **儲存：** 數值會寫入 `config.yaml` 中的 `skills.config.<key>`：
   ```yaml
   skills:
     config:
       wiki:
         path: ~/my-research
   ```

2. **發現：** `hermes config migrate` 會掃描所有已啟用的技能，找出未配置的設定，並提示使用者輸入。設定也會出現在 `hermes config show` 的「Skill Settings」下方。

3. **運行時注入：** 當技能載入時，其配置值會被解析並附加到技能訊息中：
   ```
   [Skill config (from ~/.hermes/config.yaml):
     wiki.path = /home/user/my-research
   ]
   ```
   代理無需自行讀取 `config.yaml` 即可看到配置的數值。

4. **手動設定：** 使用者也可以直接設定數值：
   ```bash
   hermes config set skills.config.wiki.path ~/my-wiki
   ```

:::tip 該使用哪一個？
使用 `required_environment_variables` 處理 API 金鑰、令牌和其他**祕密**（儲存在 `~/.hermes/.env` 中，絕不顯示給模型）。使用 `config` 處理**路徑、偏好設定和非敏感設定**（儲存在 `config.yaml` 中，在 config show 中可見）。
:::

### 憑證檔案需求 (OAuth 令牌等)

使用 OAuth 或基於檔案憑證的技能，可以宣告需要掛載到遠端沙盒中的檔案。這適用於以**檔案**形式儲存的憑證（而非環境變數） — 通常是由設定腳本產生的 OAuth 令牌檔案。

```yaml
required_credential_files:
  - path: google_token.json
    description: Google OAuth2 令牌 (由設定腳本建立)
  - path: google_client_secret.json
    description: Google OAuth2 客戶端憑證
```

每個條目支援：
- `path` (必填) — 相對於 `~/.hermes/` 的檔案路徑
- `description` (選填) — 解釋該檔案內容及其建立方式

載入時，Hermes 會檢查這些檔案是否存在。缺少檔案會觸發 `setup_needed`。現有的檔案會自動：
- 作為唯讀綁定掛載 (bind mounts) **掛載至 Docker** 容器
- **同步至 Modal** 沙盒（在建立時與每個指令執行前，因此對話中途的 OAuth 仍可運作）
- 在**本地 (local)** 後端直接可用，無需特殊處理

:::tip 該使用哪一個？
使用 `required_environment_variables` 處理簡單的 API 金鑰與令牌（儲存在 `~/.hermes/.env` 中的字串）。使用 `required_credential_files` 處理 OAuth 令牌檔案、客戶端祕密 (client secrets)、服務帳戶 JSON、憑證 (certificates) 或磁碟上的任何憑證檔案。
:::

完整範例請參閱 `skills/productivity/google-workspace/SKILL.md`。

## 技能開發準則

### 無外部相依性

優先使用 Python 標準函式庫、curl 以及現有的 Hermes 工具 (`web_extract`, `terminal`, `read_file`)。如果需要相依套件，請在技能文件中記錄安裝步驟。

### 漸進式披露

將最常見的工作流放在首位。邊緣情況與進階用法放在底部。這能讓常見任務的 Token 使用量保持在較低水平。

### 包含輔助腳本

對於 XML/JSON 解析或複雜邏輯，請在 `scripts/` 中包含輔助腳本 — 不要期望 LLM 每次都能在對話中即時寫出解析器。

### 進行測試

執行技能並驗證代理是否正確遵循指令：

```bash
hermes chat --toolsets skills -q "Use the X skill to do Y"
```

## 技能應存放在哪裡？

內建技能 (在 `skills/` 中) 隨每個 Hermes 版本發佈。它們應該對**大多數使用者都具有廣泛用途**：

- 文件處理、網路研究、常見開發工作流、系統管理。
- 被廣泛的人群定期使用。

如果您的技能是官方的且有用，但並非每個人都需要（例如：付費服務整合、重量級相依套件），請將其放在 **`optional-skills/`** — 它會隨倉庫發佈，可透過 `hermes skills browse` 發現（標記為 "official"），並具備內建信任。

如果您的技能是專業領域、社群貢獻或分眾市場，則更適合放在**技能中心 (Skills Hub)** — 將其上傳至註冊表並透過 `hermes skills install` 分享。

## 發佈技能

### 發佈至技能中心

```bash
hermes skills publish skills/my-skill --to github --repo 使用者名稱/儲存庫名稱
```

### 發佈至自定義儲存庫

將您的儲存庫新增為 Tap：

```bash
hermes skills tap add 使用者名稱/儲存庫名稱
```

使用者隨後即可搜尋並從您的儲存庫安裝。

## 安全掃描

所有從 Hub 安裝的技能都會經過安全掃描器檢查：

- 資料外洩模式
- 提示詞注入企圖
- 破壞性指令
- Shell 注入

信任層級：
- `builtin` (內建) — 隨 Hermes 發佈（始終受信任）
- `official` (官方) — 來自倉庫中的 `optional-skills/`（內建信任，無第三方警告）
- `trusted` (受信任) — 來自 openai/skills, anthropics/skills
- `community` (社群) — 非危險發現可以使用 `--force` 覆蓋；標記為 `dangerous` 的判定仍會被阻斷

Hermes 現在可以從多個外部發現模型獲取第三方技能：
- 直接的 GitHub 標識符 (例如 `openai/skills/k8s`)
- `skills.sh` 標識符 (例如 `skills-sh/vercel-labs/json-render/json-render-react`)
- 從 `/.well-known/skills/index.json` 提供的知名端點 (well-known endpoints)

如果您希望您的技能在沒有 GitHub 專用安裝器的情況下被發現，請考慮除了在儲存庫或市場發佈外，也從知名端點提供這些技能。
