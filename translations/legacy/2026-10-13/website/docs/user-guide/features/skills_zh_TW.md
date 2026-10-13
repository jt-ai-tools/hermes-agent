---
sidebar_position: 2
title: "技能系統"
description: "隨選知識文件 — 漸進式揭露、代理程式管理的技能以及技能中心 (Skills Hub)"
---

# 技能系統

技能 (Skills) 是代理程式在需要時可以載入的隨選知識文件。它們遵循**漸進式揭露 (progressive disclosure)** 模式以最小化權杖 (token) 使用量，並且與 [agentskills.io](https://agentskills.io/specification) 開放標準相容。

所有技能都存放在 **`~/.hermes/skills/`** — 這是主要的目錄和單一事實來源 (source of truth)。在全新安裝時，內置技能會從儲存庫中複製過來。從中心安裝和代理程式建立的技能也都會放在這裡。代理程式可以修改或刪除任何技能。

您也可以讓 Hermes 指向**外部技能目錄** — 即除了本地目錄外同時掃描的其他資料夾。請參閱下文的[外部技能目錄](#外部技能目錄)。

另請參閱：

- [內置技能目錄](/docs/reference/skills-catalog)
- [官方選用技能目錄](/docs/reference/optional-skills-catalog)

## 使用技能

每個安裝的技能都會自動作為斜線指令 (slash command) 使用：

```bash
# 在 CLI 或任何通訊平台中：
/gif-search funny cats
/axolotl help me fine-tune Llama 3 on my dataset
/github-pr-workflow create a PR for the auth refactor
/plan design a rollout for migrating our auth provider

# 僅輸入技能名稱會載入該技能，並讓代理程式詢問您的需求：
/excalidraw
```

內置的 `plan` 技能是具備自定義行為的技能型斜線指令的一個很好的例子。執行 `/plan [request]` 會告訴 Hermes 在需要時檢查上下文，撰寫一份 Markdown 格式的實作計劃而非直接執行任務，並將結果儲存在相對於活動工作空間/後端工作目錄的 `.hermes/plans/` 下。

您也可以透過自然對話與技能互動：

```bash
hermes chat --toolsets skills -q "你有什麼技能？"
hermes chat --toolsets skills -q "顯示 axolotl 技能給我看"
```

## 漸進式揭露

技能使用權杖效率極高的載入模式：

```
第 0 層：skills_list()           → [{name, description, category}, ...]   (約 3k 權杖)
第 1 層：skill_view(name)        → 完整內容 + 元數據 (metadata)            (視情況而定)
第 2 層：skill_view(name, path)  → 特定的參考檔案                          (視情況而定)
```

代理程式僅在真正需要時才會載入完整的技能內容。

## SKILL.md 格式

```markdown
---
name: my-skill
description: 此技能用途的簡短描述
version: 1.0.0
platforms: [macos, linux]     # 選填 — 限制在特定的作業系統平台
metadata:
  hermes:
    tags: [python, automation]
    category: devops
    fallback_for_toolsets: [web]    # 選填 — 條件式啟用（見下文）
    requires_toolsets: [terminal]   # 選填 — 條件式啟用（見下文）
    config:                          # 選填 — config.yaml 設定
      - key: my.setting
        description: "此項控制什麼"
        default: "value"
        prompt: "設定時的提示"
---

# 技能標題

## 何時使用
此技能的觸發條件。

## 程序
1. 第一步
2. 第二步

## 常見問題
- 已知的失敗模式與修復方法

## 驗證
如何確認其已奏效。
```

### 平台特定技能

技能可以使用 `platforms` 欄位將自身限制在特定的作業系統上：

| 值 | 匹配 |
|-------|---------|
| `macos` | macOS (Darwin) |
| `linux` | Linux |
| `windows` | Windows |

```yaml
platforms: [macos]            # 僅限 macOS（例如 iMessage, Apple Reminders, FindMy）
platforms: [macos, linux]     # macOS 和 Linux
```

設定後，該技能在不相容的平台上會自動從系統提示詞、`skills_list()` 和斜線指令中隱藏。如果省略，則技能會在所有平台上載入。

### 條件式啟用（備援技能）

技能可以根據目前會話中可用的工具自動顯示或隱藏。這對於**備援技能 (fallback skills)** 最為有用 — 即僅在付費或特定工具不可用時才應出現的免費或本地替代方案。

```yaml
metadata:
  hermes:
    fallback_for_toolsets: [web]      # 僅當這些工具集不可用時顯示
    requires_toolsets: [terminal]     # 僅當這些工具集可用時顯示
    fallback_for_tools: [web_search]  # 僅當這些特定工具不可用時顯示
    requires_tools: [terminal]        # 僅當這些特定工具可用時顯示
```

| 欄位 | 行為 |
|-------|----------|
| `fallback_for_toolsets` | 當列出的工具集可用時，技能會被**隱藏**。當它們缺失時顯示。 |
| `fallback_for_tools` | 同上，但檢查個別工具而非工具集。 |
| `requires_toolsets` | 當列出的工具集不可用時，技能會被**隱藏**。當它們存在時顯示。 |
| `requires_tools` | 同上，但檢查個別工具。 |

**範例：** 內建的 `duckduckgo-search` 技能使用 `fallback_for_toolsets: [web]`。當您設定了 `FIRECRAWL_API_KEY` 時，`web` 工具集可用，代理程式會使用 `web_search` — 此時 DuckDuckGo 技能保持隱藏。如果 API 金鑰缺失，`web` 工具集不可用，DuckDuckGo 技能則會自動顯示作為備援。

沒有任何條件欄位的技能行為與以前完全相同 — 它們總是會顯示。

## 載入時的安全設定

技能可以宣告所需的環境變數，而不會從探索清單中消失：

```yaml
required_environment_variables:
  - name: TENOR_API_KEY
    prompt: Tenor API key
    help: 從 https://developers.google.com/tenor 取得金鑰
    required_for: 完整功能
```

當遇到缺失值時，僅當技能在本地 CLI 中實際載入時，Hermes 才會安全地詢問該值。您可以跳過設定並繼續使用該技能。通訊平台介面絕不會在聊天中詢問秘密資訊 — 它們會告訴您在本地使用 `hermes setup` 或修改 `~/.hermes/.env`。

設定完成後，宣告的環境變數會**自動傳遞**到 `execute_code` 和 `terminal` 沙盒中 — 技能的指令碼可以直接使用 `$TENOR_API_KEY`。對於非技能環境變數，請使用 `terminal.env_passthrough` 設定選項。詳情請參閱[環境變數傳遞](/docs/user-guide/security#environment-variable-passthrough)。

### 技能配置設定

技能還可以宣告儲存在 `config.yaml` 中的非機密配置設定（路徑、偏好）：

```yaml
metadata:
  hermes:
    config:
      - key: wiki.path
        description: Wiki 目錄的路徑
        default: "~/wiki"
        prompt: Wiki 目錄路徑
```

設定儲存在 config.yaml 中的 `skills.config` 下。`hermes config migrate` 會提示配置未設定的項目，而 `hermes config show` 會顯示它們。當技能載入時，其解析後的配置值會被注入到上下文中，以便代理程式自動知曉已配置的值。

詳情請參閱 [技能設定](/docs/user-guide/configuration#skill-settings) 和 [建立技能 — 配置設定](/docs/developer-guide/creating-skills#config-settings-configyaml)。

## 技能目錄結構

```text
~/.hermes/skills/                  # 單一事實來源
├── mlops/                         # 分類目錄
│   ├── axolotl/
│   │   ├── SKILL.md               # 主要說明 (必填)
│   │   ├── references/            # 額外文件
│   │   ├── templates/             # 輸出格式
│   │   ├── scripts/               # 可從技能呼叫的輔助指令碼
│   │   └── assets/                # 補充檔案
│   └── vllm/
│       └── SKILL.md
├── devops/
│   └── deploy-k8s/                # 代理程式建立的技能
│       ├── SKILL.md
│       └── references/
├── .hub/                          # 技能中心 (Skills Hub) 狀態
│   ├── lock.json
│   ├── quarantine/
│   └── audit.log
└── .bundled_manifest              # 追蹤植入的內置技能
```

## 外部技能目錄

如果您在 Hermes 之外維護技能 — 例如多個 AI 工具共用的 `~/.agents/skills/` 目錄 — 您可以告訴 Hermes 同時掃描這些目錄。

在 `~/.hermes/config.yaml` 的 `skills` 區段下新增 `external_dirs`：

```yaml
skills:
  external_dirs:
    - ~/.agents/skills
    - /home/shared/team-skills
    - ${SKILLS_REPO}/skills
```

路徑支援 `~` 展開和 `${VAR}` 環境變數替換。

### 運作原理

- **唯讀**：外部目錄僅用於技能探索。當代理程式建立或編輯技能時，它總是寫入到 `~/.hermes/skills/`。
- **本地優先**：如果本地目錄和外部目錄中存在相同的技能名稱，則以本地版本為準。
- **完整整合**：外部技能會出現在系統提示詞索引、`skills_list`、`skill_view` 以及 `/skill-name` 斜線指令中 — 與本地技能沒有區別。
- **自動跳過不存在的路徑**：如果配置的目錄不存在，Hermes 會忽略它且不報錯。這對於可能不一定存在於每台機器上的選用共用目錄非常有用。

### 範例

```text
~/.hermes/skills/               # 本地 (主要, 可讀寫)
├── devops/deploy-k8s/
│   └── SKILL.md
└── mlops/axolotl/
    └── SKILL.md

~/.agents/skills/               # 外部 (唯讀, 共用)
├── my-custom-workflow/
│   └── SKILL.md
└── team-conventions/
    └── SKILL.md
```

所有四個技能都會出現在您的技能索引中。如果您在本地建立了一個名為 `my-custom-workflow` 的新技能，它會覆蓋外部版本。

## 代理程式管理的技能 (skill_manage 工具)

代理程式可以透過 `skill_manage` 工具建立、更新和刪除自己的技能。這是代理程式的**程序性記憶 (procedural memory)** — 當它摸索出一個非平凡的工作流程時，它會將該方法儲存為技能以便將來重複使用。

### 代理程式何時建立技能

- 成功完成一項複雜任務（超過 5 次工具呼叫）後。
- 當它遇到錯誤或死胡同並找到了可行路徑時。
- 當使用者糾正了它的方法時。
- 當它發現了一個非平凡的工作流程時。

### 操作動作

| 動作 | 用途 | 關鍵參數 |
|--------|---------|------------|
| `create` | 從頭開始建立新技能 | `name`, `content` (完整 SKILL.md), 選填 `category` |
| `patch` | 針對性修復（優先推薦） | `name`, `old_string`, `new_string` |
| `edit` | 重大的結構性重寫 | `name`, `content` (替換完整 SKILL.md) |
| `delete` | 完全移除一項技能 | `name` |
| `write_file` | 新增/更新支援檔案 | `name`, `file_path`, `file_content` |
| `remove_file` | 移除一個支援檔案 | `name`, `file_path` |

:::tip
更新時建議優先使用 `patch` 動作 — 它比 `edit` 更節省權杖，因為工具呼叫中僅會出現更改的文字。
:::

## 技能中心 (Skills Hub)

從線上註冊表、`skills.sh`、直接知名的技能端點以及官方選用技能中瀏覽、搜尋、安裝和管理技能。

### 常用指令

```bash
hermes skills browse                              # 瀏覽所有中心技能（官方優先）
hermes skills browse --source official            # 僅瀏覽官方選用技能
hermes skills search kubernetes                   # 搜尋所有來源
hermes skills search react --source skills-sh     # 搜尋 skills.sh 目錄
hermes skills search https://mintlify.com/docs --source well-known
hermes skills inspect openai/skills/k8s           # 安裝前預覽
hermes skills install openai/skills/k8s           # 包含安全掃描的安裝
hermes skills install official/security/1password
hermes skills install skills-sh/vercel-labs/json-render/json-render-react --force
hermes skills install well-known:https://mintlify.com/docs/.well-known/skills/mintlify
hermes skills list --source hub                   # 列出從中心安裝的技能
hermes skills check                               # 檢查已安裝的中心技能是否有上游更新
hermes skills update                              # 在需要時根據上游更改重新安裝中心技能
hermes skills audit                               # 重新對所有中心技能進行安全掃描
hermes skills uninstall k8s                       # 移除一個中心技能
hermes skills publish skills/my-skill --to github --repo owner/repo
hermes skills snapshot export setup.json          # 匯出技能配置
hermes skills tap add myorg/skills-repo           # 新增自定義 GitHub 來源
```

### 支援的中心來源

| 來源 | 範例 | 備註 |
|--------|---------|-------|
| `official` | `official/security/1password` | 隨 Hermes 提供的選用技能。 |
| `skills-sh` | `skills-sh/vercel-labs/agent-skills/vercel-react-best-practices` | 可透過 `hermes skills search <query> --source skills-sh` 搜尋。當 skills.sh 的代稱 (slug) 與儲存庫資料夾不同時，Hermes 會解析別名風格的技能。 |
| `well-known` | `well-known:https://mintlify.com/docs/.well-known/skills/mintlify` | 直接從網站上的 `/.well-known/skills/index.json` 提供的技能。使用站點或文件網址進行搜尋。 |
| `github` | `openai/skills/k8s` | 直接從 GitHub 儲存庫/路徑安裝以及自定義分流 (taps)。 |
| `clawhub`, `lobehub`, `claude-marketplace` | 來源特定的識別碼 | 社群或市場整合。 |

### 整合的中心與註冊表

Hermes 目前與以下技能生態系統和探索來源整合：

#### 1. 官方選用技能 (`official`)

這些技能在 Hermes 儲存庫本身中維護，安裝時具備內建信任。

- 目錄：[官方選用技能目錄](../../reference/optional-skills-catalog)
- 儲存庫中的來源：`optional-skills/`
- 範例：

```bash
hermes skills browse --source official
hermes skills install official/security/1password
```

#### 2. skills.sh (`skills-sh`)

這是 Vercel 的公共技能目錄。Hermes 可以直接搜尋它、檢查技能詳情頁面、解析別名風格的代稱，並從底層來源儲存庫安裝。

- 目錄：[skills.sh](https://skills.sh/)
- CLI/工具儲存庫：[vercel-labs/skills](https://github.com/vercel-labs/skills)
- 官方 Vercel 技能儲存庫：[vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)
- 範例：

```bash
hermes skills search react --source skills-sh
hermes skills inspect skills-sh/vercel-labs/json-render/json-render-react
hermes skills install skills-sh/vercel-labs/json-render/json-render-react --force
```

#### 3. 知名技能端點 (`well-known`)

這是來自發佈 `/.well-known/skills/index.json` 之網站的基於網址的探索方式。它不是單一的中心化中心，而是一種網頁探索慣例。

- 範例即時端點：[Mintlify 文件技能索引](https://mintlify.com/docs/.well-known/skills/index.json)
- 參考伺服器實作：[vercel-labs/skills-handler](https://github.com/vercel-labs/skills-handler)
- 範例：

```bash
hermes skills search https://mintlify.com/docs --source well-known
hermes skills inspect well-known:https://mintlify.com/docs/.well-known/skills/mintlify
hermes skills install well-known:https://mintlify.com/docs/.well-known/skills/mintlify
```

#### 4. 直接從 GitHub 獲取技能 (`github`)

Hermes 可以直接從 GitHub 儲存庫和基於 GitHub 的分流 (taps) 安裝。這在您已知儲存庫/路徑或想要新增自己的自定義來源儲存庫時非常有用。

預設分流（無需任何設定即可瀏覽）：
- [openai/skills](https://github.com/openai/skills)
- [anthropics/skills](https://github.com/anthropics/skills)
- [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)
- [garrytan/gstack](https://github.com/garrytan/gstack)

- 範例：

```bash
hermes skills install openai/skills/k8s
hermes skills tap add myorg/skills-repo
```

#### 5. ClawHub (`clawhub`)

作為社群來源整合的第三方技能市場。

- 網站：[clawhub.ai](https://clawhub.ai/)
- Hermes 來源 ID：`clawhub`

#### 6. Claude 市場風格儲存庫 (`claude-marketplace`)

Hermes 支援發佈與 Claude 相容之插件/市場清單的市場儲存庫。

已整合的已知來源包括：
- [anthropics/skills](https://github.com/anthropics/skills)
- [aiskillstore/marketplace](https://github.com/aiskillstore/marketplace)

Hermes 來源 ID：`claude-marketplace`

#### 7. LobeHub (`lobehub`)

Hermes 可以搜尋 LobeHub 公共目錄中的代理程式項目，並將其轉換為可安裝的 Hermes 技能。

- 網站：[LobeHub](https://lobehub.com/)
- 公共代理程式索引：[chat-agents.lobehub.com](https://chat-agents.lobehub.com/)
- 底層儲存庫：[lobehub/lobe-chat-agents](https://github.com/lobehub/lobe-chat-agents)
- Hermes 來源 ID：`lobehub`

### 安全掃描與 `--force`

所有從中心安裝的技能都會經過**安全掃描器**，檢查是否有數據外洩、提示詞注入、破壞性指令、供應鏈信號以及其他威脅。

`hermes skills inspect ...` 現在也會顯示可用的上游元數據：
- 儲存庫網址 (repo URL)
- skills.sh 詳情頁面網址
- 安裝指令
- 每週安裝量
- 上游安全稽核狀態
- 知名索引/端點網址

當您已審核過第三方技能並希望覆蓋非危險策略封鎖時，請使用 `--force`：

```bash
hermes skills install skills-sh/anthropics/skills/pdf --force
```

重要行為：
- `--force` 可以針對「注意/警告」風格的發現覆蓋策略封鎖。
- `--force` **不能**覆蓋「危險 (dangerous)」掃描判定。
- 官方選用技能 (`official/...`) 被視為內建信任，不會顯示第三方警告面板。

### 信任層級

| 層級 | 來源 | 策略 |
|-------|--------|--------|
| `builtin` | 隨 Hermes 出貨 | 始終信任 |
| `official` | 儲存庫中的 `optional-skills/` | 內建信任，無第三方警告 |
| `trusted` | 信任的註冊表/儲存庫，如 `openai/skills`, `anthropics/skills` | 比社群來源更寬鬆的策略 |
| `community` | 其他所有來源（`skills.sh`, 知名端點, 自定義 GitHub 儲存庫, 大多數市場） | 非危險發現可以使用 `--force` 覆蓋；「危險」判定保持封鎖 |

### 更新週期

中心現在會追蹤足夠的來源出處 (provenance)，以便重新檢查已安裝技能的上游副本：

```bash
hermes skills check          # 報告哪些已安裝的中心技能在上游發生了變化
hermes skills update         # 僅重新安裝有可用更新的技能
hermes skills update react   # 更新一項特定的已安裝中心技能
```

這會使用儲存的來源識別碼加上目前上游套裝內容的雜湊值來偵測偏移 (drift)。

:::tip GitHub 頻率限制
技能中心的操作使用 GitHub API，未經身份驗證的使用者每小時限制 60 次請求。如果您在安裝或搜尋期間看到頻率限制錯誤，請在 `.env` 檔案中設定 `GITHUB_TOKEN` 以將限制增加到每小時 5,000 次請求。發生這種情況時，錯誤訊息中會包含可操作的提示。
:::

### 斜線指令（在聊天中）

所有相同的指令都可以在 `/skills` 中使用：

```text
/skills browse
/skills search react --source skills-sh
/skills search https://mintlify.com/docs --source well-known
/skills inspect skills-sh/vercel-labs/json-render/json-render-react
/skills install openai/skills/skill-creator --force
/skills check
/skills update
/skills list
```

官方選用技能仍使用如 `official/security/1password` 和 `official/migration/openclaw-migration` 之類的識別碼。
