---
sidebar_position: 12
title: "使用技能 (Skills)"
description: "尋找、安裝、使用以及建立技能 —— 為 Hermes 提供隨選知識，教導它新的工作流"
---

# 使用技能 (Skills)

技能（Skills）是隨選的知識文件，用於教導 Hermes 如何處理特定任務 —— 從生成 ASCII 藝術到管理 GitHub Pull Request。本指南將引導您如何在日常工作中使用它們。

如需完整的技術參考，請參閱[技能系統](/docs/user-guide/features/skills)。

---

## 尋找技能

每個安裝好的 Hermes 都內建了一些技能。您可以查看有哪些可用技能：

```bash
# 在任何聊天工作階段中輸入：
/skills

# 或從 CLI 執行：
hermes skills list
```

這將顯示包含名稱和說明的精簡列表：

```
ascii-art         使用 pyfiglet, cowsay, boxes 等生成 ASCII 藝術...
arxiv             從 arXiv 搜尋並檢索學術論文...
github-pr-workflow 完整的 PR 生命週期 —— 建立分支、提交程式碼...
plan              計畫模式 —— 檢查上下文、撰寫 Markdown 計畫...
excalidraw        使用 Excalidraw 建立手繪風格的圖表...
```

### 搜尋技能

```bash
# 透過關鍵字搜尋
/skills search docker
/skills search music
```

### 技能中心 (Skills Hub)

官方的可選技能（較大型或利基型技能，預設未啟用）可以透過中心（Hub）獲取：

```bash
# 瀏覽官方的可選技能
/skills browse

# 搜尋技能中心
/skills search blockchain
```

---

## 使用技能

每個已安裝的技能都會自動成為一個斜線指令（Slash Command）。只需輸入其名稱即可：

```bash
# 載入技能並賦予任務
/ascii-art 製作一個顯示 "HELLO WORLD" 的橫幅
/plan 為待辦事項應用程式設計一個 REST API
/github-pr-workflow 為 auth 重構建立一個 PR

# 僅輸入技能名稱（不包含任務）會載入該技能，讓您接著描述需求
/excalidraw
```

您也可以透過自然對話來觸發技能 —— 要求 Hermes 使用特定技能，它會透過 `skill_view` 工具來載入它。

### 漸進式呈現 (Progressive Disclosure)

技能使用節省 Token 的載入模式。Agent 不會一次載入所有內容：

1. **`skills_list()`** —— 所有技能的精簡列表（約 3,000 個 Token）。在工作階段開始時載入。
2. **`skill_view(name)`** —— 單一技能的完整 SKILL.md 內容。當 Agent 決定需要該技能時才載入。
3. **`skill_view(name, file_path)`** —— 技能中特定的參考檔案。僅在需要時載入。

這意味著技能在實際使用之前不會消耗 Token。

---

## 從中心安裝

官方的可選技能雖然隨附於 Hermes，但預設並未啟用。您需要明確安裝它們：

```bash
# 安裝官方可選技能
hermes skills install official/research/arxiv

# 在聊天工作階段中從中心安裝
/skills install official/creative/songwriting-and-ai-music
```

安裝過程如下：
1. 技能目錄會被複製到 `~/.hermes/skills/`。
2. 它會出現在您的 `skills_list` 輸出中。
3. 它會成為一個可用的斜線指令。

:::tip 提示
安裝的技能會在新的工作階段中生效。如果您想在當前工作階段中使用它，請使用 `/reset` 重新開始，或者添加 `--now` 參數立即失效提示語快取（這在下一輪對話會消耗更多 Token）。
:::

### 驗證安裝

```bash
# 檢查是否已存在
hermes skills list | grep arxiv

# 或在聊天中輸入
/skills search arxiv
```

---

## 外掛程式提供的技能

外掛程式（Plugins）可以使用具備命名空間的名稱（`plugin:skill`）來綑綁自己的技能。這可以防止與內建技能發生名稱衝突。

```bash
# 透過完整名稱載入外掛技能
skill_view("superpowers:writing-plans")

# 具有相同基本名稱的內建技能不受影響
skill_view("writing-plans")
```

外掛技能**不會**列在系統提示語中，也不會出現在 `skills_list` 中。它們是「選擇性加入」的 —— 當您知道某個外掛程式提供該技能時，請明確載入它。載入後，Agent 會看到一個橫幅，列出同一外掛程式中的其他相關技能。

關於如何在您自己的外掛程式中提供技能，請參閱[建立 Hermes 外掛程式 → 綑綁技能](/docs/guides/build-a-hermes-plugin#bundle-skills)。

---

## 設定技能選項

某些技能在它們的前導資料（Frontmatter）中聲明了所需的設定：

```yaml
metadata:
  hermes:
    config:
      - key: tenor.api_key
        description: "用於搜尋 GIF 的 Tenor API 金鑰"
        prompt: "輸入您的 Tenor API 金鑰"
        url: "https://developers.google.com/tenor/guides/quickstart"
```

當帶有設定的技能第一次被載入時，Hermes 會提示您輸入相關數值。這些數值會儲存在 `config.yaml` 的 `skills.config.*` 下。

您可以透過 CLI 管理技能設定：

```bash
# 針對特定技能進行互動式設定
hermes skills config gif-search

# 查看所有技能設定
hermes config get skills.config
```

---

## 建立您自己的技能

技能只是帶有 YAML 前導資料的 Markdown 檔案。建立一個技能只需不到五分鐘。

### 1. 建立目錄

```bash
mkdir -p ~/.hermes/skills/my-category/my-skill
```

### 2. 撰寫 SKILL.md

```markdown title="~/.hermes/skills/my-category/my-skill/SKILL.md"
---
name: my-skill
description: 簡要描述此技能的功能
version: 1.0.0
metadata:
  hermes:
    tags: [my-tag, automation]
    category: my-category
---

# 我的技能 (My Skill)

## 何時使用
當使用者詢問關於 [特定主題] 或需要執行 [特定任務] 時，請使用此技能。

## 程序
1. 首先，檢查 [先決條件] 是否可用。
2. 執行 `command --with-flags`。
3. 解析輸出並呈現結果。

## 常見陷阱
- 常見失敗原因：[描述]。解決方法：[方案]。
- 注意 [邊緣情況]。

## 驗證
執行 `check-command` 來確認結果是否正確。
```

### 3. 添加參考檔案 (選填)

技能可以包含 Agent 視需求載入的支援檔案：

```
my-skill/
├── SKILL.md                    # 主要技能文件
├── references/
│   ├── api-docs.md             # Agent 可以參考的 API 文件
│   └── examples.md             # 範例輸入/輸出
├── templates/
│   └── config.yaml             # Agent 可以使用的模板檔案
└── scripts/
    └── setup.sh                # Agent 可以執行的腳本
```

在您的 SKILL.md 中引用這些檔案：

```markdown
如需 API 細節，請載入參考資料：`skill_view("my-skill", "references/api-docs.md")`
```

### 4. 測試技能

開始一個新的工作階段並嘗試您的技能：

```bash
hermes chat -q "/my-skill 幫我處理那件事"
```

技能會自動出現 —— 不需要註冊。只需將其放入 `~/.hermes/skills/` 目錄即可生效。

:::info 資訊
Agent 也可以使用 `skill_manage` 工具自行建立和更新技能。在解決了一個複雜問題後，Hermes 可能會主動提議將該方法儲存為技能，以便下次使用。
:::

---

## 針對各平台的技能管理

控制哪些技能在哪些平台上可用：

```bash
hermes skills
```

這會開啟一個互動式的終端機介面（TUI），您可以在其中針對每個平台（CLI、Telegram、Discord 等）啟用或停用技能。當您只希望某些技能在特定上下文中使用時（例如：不要在 Telegram 上提供開發類技能），這非常有用。

---

## 技能 vs 記憶 (Skills vs Memory)

兩者都能跨工作階段持久存在，但用途不同：

| | 技能 (Skills) | 記憶 (Memory) |
|---|---|---|
| **內容** | 程序性知識 —— 如何做事 | 事實性知識 —— 事情是什麼 |
| **時機** | 隨選載入，僅在相關時載入 | 自動注入到每個工作階段 |
| **大小** | 可以很大（數百行） | 應保持精簡（僅限關鍵事實） |
| **成本** | 載入前不消耗 Token | 小規模但持續消耗 Token |
| **範例** | 「如何部署到 Kubernetes」 | 「使用者偏好深色模式，居住在 PST 時區」 |
| **建立者** | 您、Agent 或從中心安裝 | Agent 根據對話內容建立 |

**經驗法則：** 如果您會把它放在參考文件中，它就是一項「技能」。如果您會把它寫在便利貼上，它就是一段「記憶」。

---

## 提示

**保持技能聚焦。** 一個試圖涵蓋「所有 DevOps 知識」的技能會太過冗長且模糊。一個涵蓋「將 Python 應用程式部署到 Fly.io」的技能則足夠具體，能發揮實質作用。

**讓 Agent 建立技能。** 在完成一個複雜的多步驟任務後，Hermes 通常會提議將該方法儲存為技能。請接受建議 —— 這些由 Agent 撰寫的技能能捕捉精確的工作流，包含在過程中發現的陷阱。

**使用分類。** 將技能組織到子目錄中（`~/.hermes/skills/devops/`、`~/.hermes/skills/research/` 等）。這能讓列表保持整潔，並幫助 Agent 更快找到相關技能。

**及時更新過時的技能。** 如果您在使用技能時遇到了技能未涵蓋的問題，請告訴 Hermes 使用您學到的新知識來更新該技能。未經維護的技能會變成負資產。

---

*如需完整的技能參考 —— 前導資料欄位、條件式啟用、外部目錄等 —— 請參閱[技能系統](/docs/user-guide/features/skills)。*
