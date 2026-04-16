---
sidebar_position: 5
title: "提示詞組合"
description: "Hermes 如何構建系統提示詞、保持快取穩定性並注入臨時層"
---

# 提示詞組合 (Prompt Assembly)

Hermes 刻意分離了：

- **快取的系統提示詞狀態 (cached system prompt state)**
- **API 呼叫時的臨時添加內容 (ephemeral API-call-time additions)**

這是專案中最重要的設計選擇之一，因為它影響了：

- 標記 (token) 使用量
- 提示詞快取 (prompt caching) 的有效性
- 會話連續性
- 記憶的正確性

主要檔案：

- `run_agent.py`
- `agent/prompt_builder.py`
- `tools/memory_tool.py`

## 快取的系統提示詞層 (Cached system prompt layers)

快取的系統提示詞大致按以下順序組合：

1. 代理身分 (agent identity) — 當 `HERMES_HOME` 中有 `SOUL.md` 時使用它，否則回退到 `prompt_builder.py` 中的 `DEFAULT_AGENT_IDENTITY`
2. 工具感知行為引導 (tool-aware behavior guidance)
3. Honcho 靜態區塊 (當啟用時)
4. 選用系統訊息
5. 凍結的記憶 (MEMORY) 快照
6. 凍結的使用者個人資料 (USER profile) 快照
7. 技能索引 (skills index)
8. 上下文檔案 (`AGENTS.md`, `.cursorrules`, `.cursor/rules/*.mdc`) — 如果 `SOUL.md` 在步驟 1 中已作為身分載入，則**不**包含在此處
9. 時間戳記 / 選用會話 ID
10. 平台提示 (platform hint)

當設置了 `skip_context_files` 時（例如子代理委派），不會載入 `SOUL.md`，而是使用硬編碼的 `DEFAULT_AGENT_IDENTITY`。

### 具體範例：組合後的系統提示詞

以下是當所有層都存在時，最終系統提示詞的簡化視圖（註解顯示了每個部分的來源）：

```
# 第 1 層：代理身分 (來自 ~/.hermes/SOUL.md)
You are Hermes, an AI assistant created by Nous Research.
You are an expert software engineer and researcher.
You value correctness, clarity, and efficiency.
...

# 第 2 層：工具感知行為引導
You have persistent memory across sessions. Save durable facts using
the memory tool: user preferences, environment details, tool quirks,
and stable conventions. Memory is injected into every turn, so keep
it compact and focused on facts that will still matter later.
...
When the user references something from a past conversation or you
suspect relevant cross-session context exists, use session_search
to recall it before asking them to repeat themselves.

# 工具使用強制執行 (僅適用於 GPT/Codex 模型)
You MUST use your tools to take action — do not describe what you
would do or plan to do without actually doing it.
...

# 第 3 層：Honcho 靜態區塊 (當啟用時)
[Honcho 個性/上下文數據]

# 第 4 層：選用系統訊息 (來自配置或 API)
[使用者配置的系統訊息覆蓋]

# 第 5 層：凍結的記憶 (MEMORY) 快照
## Persistent Memory
- User prefers Python 3.12, uses pyproject.toml
- Default editor is nvim
- Working on project "atlas" in ~/code/atlas
- Timezone: US/Pacific

# 第 6 層：凍結的使用者個人資料 (USER profile) 快照
## User Profile
- Name: Alice
- GitHub: alice-dev

# 第 7 層：技能索引
## Skills (mandatory)
Before replying, scan the skills below. If one clearly matches
your task, load it with skill_view(name) and follow its instructions.
...
<available_skills>
  software-development:
    - code-review: Structured code review workflow
    - test-driven-development: TDD methodology
  research:
    - arxiv: Search and summarize arXiv papers
</available_skills>

# 第 8 層：上下文檔案 (來自專案目錄)
# Project Context
The following project context files have been loaded and should be followed:

## AGENTS.md
This is the atlas project. Use pytest for testing. The main
entry point is src/atlas/main.py. Always run `make lint` before
committing.

# 第 9 層：時間戳記 + 會話
Current time: 2026-03-30T14:30:00-07:00
Session: abc123

# 第 10 層：平台提示
You are a CLI AI Agent. Try not to use markdown but simple text
renderable inside a terminal.
```

## SOUL.md 如何出現在提示詞中

`SOUL.md` 位於 `~/.hermes/SOUL.md`，作為代理的身分 — 系統提示詞的第一部分。`prompt_builder.py` 中的載入邏輯如下：

```python
# 來自 agent/prompt_builder.py (簡化版)
def load_soul_md() -> Optional[str]:
    soul_path = get_hermes_home() / "SOUL.md"
    if not soul_path.exists():
        return None
    content = soul_path.read_text(encoding="utf-8").strip()
    content = _scan_context_content(content, "SOUL.md")  # 安全掃描
    content = _truncate_content(content, "SOUL.md")       # 限制在 20k 字元
    return content
```

當 `load_soul_md()` 返回內容時，它會替換硬編碼的 `DEFAULT_AGENT_IDENTITY`。接著呼叫 `build_context_files_prompt()` 並設置 `skip_soul=True`，以防止 `SOUL.md` 出現兩次（一次作為身分，一次作為上下文檔案）。

如果 `SOUL.md` 不存在，系統會回退到：

```
You are Hermes Agent, an intelligent AI assistant created by Nous Research.
You are helpful, knowledgeable, and direct. You assist users with a wide
range of tasks including answering questions, writing and editing code,
analyzing information, creative work, and executing actions via your tools.
You communicate clearly, admit uncertainty when appropriate, and prioritize
being genuinely useful over being verbose unless otherwise directed below.
Be targeted and efficient in your exploration and investigations.
```

## 上下文檔案如何注入

`build_context_files_prompt()` 使用**優先級系統** — 僅載入一種專案上下文類型（第一個匹配項獲勝）：

```python
# 來自 agent/prompt_builder.py (簡化版)
def build_context_files_prompt(cwd=None, skip_soul=False):
    cwd_path = Path(cwd).resolve()

    # 優先級：第一個匹配項獲勝 — 僅載入一個專案上下文
    project_context = (
        _load_hermes_md(cwd_path)       # 1. .hermes.md / HERMES.md (向上尋找到 git 根目錄)
        or _load_agents_md(cwd_path)    # 2. AGENTS.md (僅限當前目錄)
        or _load_claude_md(cwd_path)    # 3. CLAUDE.md (僅限當前目錄)
        or _load_cursorrules(cwd_path)  # 4. .cursorrules / .cursor/rules/*.mdc
    )

    sections = []
    if project_context:
        sections.append(project_context)

    # 來自 HERMES_HOME 的 SOUL.md (與專案上下文無關)
    if not skip_soul:
        soul_content = load_soul_md()
        if soul_content:
            sections.append(soul_content)

    if not sections:
        return ""

    return (
        "# Project Context\n\n"
        "The following project context files have been loaded "
        "and should be followed:\n\n"
        + "\n".join(sections)
    )
```

### 上下文檔案尋找詳情

| 優先級 | 檔案 | 搜尋範圍 | 備註 |
|----------|-------|-------------|-------|
| 1 | `.hermes.md`, `HERMES.md` | 當前目錄向上至 git 根目錄 | Hermes 原生專案配置 |
| 2 | `AGENTS.md` | 僅限當前目錄 | 常見的代理指令檔案 |
| 3 | `CLAUDE.md` | 僅限當前目錄 | Claude Code 相容性 |
| 4 | `.cursorrules`, `.cursor/rules/*.mdc` | 僅限當前目錄 | Cursor 相容性 |

所有上下文檔案都會：
- **經過安全掃描** — 檢查提示詞注入模式（不可見的 unicode、「忽略先前指令」、憑證竊取企圖）
- **進行截斷** — 使用 70/20 的頭/尾比例並加上截斷標記，限制在 20,000 個字元內
- **剝離 YAML frontmatter** — 移除 `.hermes.md` 的 frontmatter（保留供未來配置覆蓋使用）

## 僅限 API 呼叫時的層 (API-call-time-only layers)

這些內容刻意*不*作為快取系統提示詞的一部分持久化：

- `ephemeral_system_prompt` (臨時系統提示詞)
- 預填訊息 (prefill messages)
- 來自閘道器 (gateway) 的會話上下文覆蓋
- 稍後回合注入到當前回合使用者訊息中的 Honcho 召回內容

這種分離使穩定的前綴保持穩定，以便進行快取。

## 記憶快照 (Memory snapshots)

本地記憶和使用者個人資料數據在會話開始時作為凍結快照注入。會話中途的寫入會更新磁碟狀態，但在新會話或強制重新構建發生之前，不會更改已構建的系統提示詞。

## 技能索引 (Skills index)

當技能工具可用時，技能系統會向提示詞貢獻一個精簡的技能索引。

## 為什麼提示詞組合要這樣拆分

該架構刻意進行了優化，以：

- 保留供應商端的提示詞快取
- 避免不必要的歷史變動
- 使記憶語義易於理解
- 允許閘道器/ACP/CLI 添加上下文，而不污染持久的提示詞狀態

## 相關文件

- [上下文壓縮與提示詞快取 (Context Compression & Prompt Caching)](./context-compression-and-caching.md)
- [會話存儲 (Session Storage)](./session-storage.md)
- [閘道器內部機制 (Gateway Internals)](./gateway-internals.md)
