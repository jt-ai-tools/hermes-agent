---
sidebar_position: 5
title: "將 Hermes 作為 Python 函式庫使用"
description: "將 AIAgent 嵌入到你自己的 Python 腳本、Web 應用或自動化流程中 —— 無需使用 CLI"
---

# 將 Hermes 作為 Python 函式庫使用

Hermes 不僅僅是一個 CLI 工具。你可以直接匯入 `AIAgent` 並以程式化方式將其應用於你自己的 Python 腳本、Web 應用程式或自動化流程中。本指南將向你展示如何操作。

---

## 安裝

直接從儲存庫安裝 Hermes：

```bash
pip install git+https://github.com/NousResearch/hermes-agent.git
```

或是使用 [uv](https://docs.astral.sh/uv/)：

```bash
uv pip install git+https://github.com/NousResearch/hermes-agent.git
```

你也可以將其固定在 `requirements.txt` 中：

```text
hermes-agent @ git+https://github.com/NousResearch/hermes-agent.git
```

:::tip
將 Hermes 作為函式庫使用時，仍需要 CLI 所使用的環境變數。至少需設置 `OPENROUTER_API_KEY`（或者如果使用供應商直連，則設置 `OPENAI_API_KEY` / `ANTHROPIC_API_KEY`）。
:::

---

## 基本用法

使用 Hermes 最簡單的方法是 `chat()` 方法 —— 傳入訊息，獲取字串回傳：

```python
from run_agent import AIAgent

agent = AIAgent(
    model="anthropic/claude-sonnet-4",
    quiet_mode=True,
)
response = agent.chat("法國的首都是哪裡？")
print(response)
```

`chat()` 會在內部處理完整的對話迴圈 (Conversation loop) —— 包含工具呼叫、重試等所有過程 —— 並僅回傳最終的文字回應。

:::warning
將 Hermes 嵌入到你自己的程式碼中時，請務必設置 `quiet_mode=True`。否則，代理會列印 CLI 等待動畫、進度指示器和其他終端機輸出，這會弄亂你的應用程式輸出。
:::

---

## 完整的對話控制

如果需要對對話進行更多控制，請直接使用 `run_conversation()`。它會回傳一個包含完整回應、訊息歷史紀錄和元數據 (Metadata) 的字典：

```python
agent = AIAgent(
    model="anthropic/claude-sonnet-4",
    quiet_mode=True,
)

result = agent.run_conversation(
    user_message="搜尋最近的 Python 3.13 特性",
    task_id="my-task-1",
)

print(result["final_response"])
print(f"交換的訊息數量：{len(result['messages'])}")
```

回傳的字典包含：
- **`final_response`** — 代理最終的文字回覆
- **`messages`** — 完整的訊息歷史紀錄（系統、使用者、助理、工具呼叫）
- **`task_id`** — 用於 VM 隔離的任務識別碼

你也可以傳遞一個自定義的系統訊息，該訊息會覆寫該次呼叫的臨時系統提示詞：

```python
result = agent.run_conversation(
    user_message="解釋快速排序 (Quicksort)",
    system_message="你是一位計算機科學導師。請使用簡單的比喻。",
)
```

---

## 配置工具

使用 `enabled_toolsets` 或 `disabled_toolsets` 來控制代理可以存取的工具集：

```python
# 僅啟用網路工具（瀏覽、搜尋）
agent = AIAgent(
    model="anthropic/claude-sonnet-4",
    enabled_toolsets=["web"],
    quiet_mode=True,
)

# 啟用除終端機存取外的所有功能
agent = AIAgent(
    model="anthropic/claude-sonnet-4",
    disabled_toolsets=["terminal"],
    quiet_mode=True,
)
```

:::tip
當你想要一個極簡且受限的代理（例如僅用於研究機器人的網路搜尋）時，請使用 `enabled_toolsets`。當你想要保留大部分能力但需要限制特定能力（例如在共享環境中禁止終端機存取）時，請使用 `disabled_toolsets`。
:::

---

## 多輪對話

透過將訊息歷史紀錄傳回，可以在多輪對話中保持對話狀態：

```python
agent = AIAgent(
    model="anthropic/claude-sonnet-4",
    quiet_mode=True,
)

# 第一輪
result1 = agent.run_conversation("我的名字是 Alice")
history = result1["messages"]

# 第二輪 — 代理會記住背景資訊
result2 = agent.run_conversation(
    "我的名字是什麼？",
    conversation_history=history,
)
print(result2["final_response"])  # "你的名字是 Alice。"
```

`conversation_history` 參數接受來自先前結果的 `messages` 列表。代理會在內部複製它，因此你的原始列表永遠不會被更改。

---

## 儲存軌跡 (Trajectories)

啟用軌跡儲存以 ShareGPT 格式擷取對話 —— 這對於生成訓練數據或進行除錯非常有用：

```python
agent = AIAgent(
    model="anthropic/claude-sonnet-4",
    save_trajectories=True,
    quiet_mode=True,
)

agent.chat("寫一個 Python 函式來對列表進行排序")
# 以 ShareGPT 格式儲存到 trajectory_samples.jsonl
```

每次對話都會作為單行 JSONL 附加，方便從自動化執行中收集數據集。

---

## 自定義系統提示詞

使用 `ephemeral_system_prompt` 設置自定義系統提示詞來引導代理行為，但該提示詞 **不會** 儲存到軌跡檔案中（保持訓練數據乾淨）：

```python
agent = AIAgent(
    model="anthropic/claude-sonnet-4",
    ephemeral_system_prompt="你是一位 SQL 專家。僅回答資料庫相關問題。",
    quiet_mode=True,
)

response = agent.chat("如何編寫 JOIN 查詢？")
print(response)
```

這非常適合構建專門的代理 —— 程式碼審查員、文件撰寫者、SQL 助手 —— 全部都使用相同的底層工具。

---

## 批次處理

為了平行執行多個提示詞，Hermes 包含了 `batch_runner.py`。它管理多個具備資源隔離能力的 `AIAgent` 實例：

```bash
python batch_runner.py --input prompts.jsonl --output results.jsonl
```

每個提示詞都有自己的 `task_id` 和隔離環境。如果你需要自定義批次邏輯，可以直接使用 `AIAgent` 構建：

```python
import concurrent.futures
from run_agent import AIAgent

prompts = [
    "解釋遞迴 (Recursion)",
    "什麼是雜湊表 (Hash table)？",
    "垃圾回收 (Garbage collection) 如何運作？",
]

def process_prompt(prompt):
    # 每個任務建立一個新的代理以確保執行緒安全 (Thread safety)
    agent = AIAgent(
        model="anthropic/claude-sonnet-4",
        quiet_mode=True,
        skip_memory=True,
    )
    return agent.chat(prompt)

with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
    results = list(executor.map(process_prompt, prompts))

for prompt, result in zip(prompts, results):
    print(f"Q: {prompt}\nA: {result}\n")
```

:::warning
請務必為 **每個執行緒或任務建立一個新的 `AIAgent` 實例**。代理維護內部狀態（對話歷史、工具對話階段、迭代計數器），共享這些實例並非執行緒安全 (Thread-safe)。
:::

---

## 整合範例

### FastAPI 端點

```python
from fastapi import FastAPI
from pydantic import BaseModel
from run_agent import AIAgent

app = FastAPI()

class ChatRequest(BaseModel):
    message: str
    model: str = "anthropic/claude-sonnet-4"

@app.post("/chat")
async def chat(request: ChatRequest):
    agent = AIAgent(
        model=request.model,
        quiet_mode=True,
        skip_context_files=True,
        skip_memory=True,
    )
    response = agent.chat(request.message)
    return {"response": response}
```

### Discord 機器人

```python
import discord
from run_agent import AIAgent

client = discord.Client(intents=discord.Intents.default())

@client.event
async def on_message(message):
    if message.author == client.user:
        return
    if message.content.startswith("!hermes "):
        query = message.content[8:]
        agent = AIAgent(
            model="anthropic/claude-sonnet-4",
            quiet_mode=True,
            skip_context_files=True,
            skip_memory=True,
            platform="discord",
        )
        response = agent.chat(query)
        await message.channel.send(response[:2000])

client.run("你的_DISCORD_TOKEN")
```

### CI/CD 管線步驟

```python
#!/usr/bin/env python3
"""CI 步驟：自動審查 PR diff。"""
import subprocess
from run_agent import AIAgent

diff = subprocess.check_output(["git", "diff", "main...HEAD"]).decode()

agent = AIAgent(
    model="anthropic/claude-sonnet-4",
    quiet_mode=True,
    skip_context_files=True,
    skip_memory=True,
    disabled_toolsets=["terminal", "browser"],
)

review = agent.chat(
    f"審查此 PR diff 是否存在 Bug、安全性問題和風格問題：\n\n{diff}"
)
print(review)
```

---

## 關鍵建構子參數

| 參數 | 類型 | 預設值 | 描述 |
|-----------|------|---------|-------------|
| `model` | `str` | `"anthropic/claude-opus-4.6"` | OpenRouter 格式的模型名稱 |
| `quiet_mode` | `bool` | `False` | 隱藏 CLI 輸出 |
| `enabled_toolsets` | `List[str]` | `None` | 白名單指定的工具集 |
| `disabled_toolsets` | `List[str]` | `None` | 黑名單指定的工具集 |
| `save_trajectories` | `bool` | `False` | 將對話儲存為 JSONL |
| `ephemeral_system_prompt` | `str` | `None` | 自定義系統提示詞（不儲存至軌跡檔案） |
| `max_iterations` | `int` | `90` | 每次對話的最大工具呼叫迭代次數 |
| `skip_context_files` | `bool` | `False` | 跳過載入 AGENTS.md 檔案 |
| `skip_memory` | `bool` | `False` | 停用持久記憶的讀寫 |
| `api_key` | `str` | `None` | API 金鑰（若未提供則回退至環境變數） |
| `base_url` | `str` | `None` | 自定義 API 端點 URL |
| `platform` | `str` | `None` | 平台提示（如 `"discord"`, `"telegram"` 等） |

---

## 重要筆記

:::tip
- 如果你不希望將工作目錄中的 `AGENTS.md` 檔案載入到系統提示詞中，請設置 **`skip_context_files=True`**。
- 設置 **`skip_memory=True`** 以防止代理讀取或寫入持久記憶 —— 建議在無狀態的 API 端點中使用。
- `platform` 參數（例如 `"discord"`, `"telegram"`）會注入平台特定的格式提示，使代理調整其輸出風格。
:::

:::warning
- **執行緒安全 (Thread safety)**：請為每個執行緒或任務建立一個 `AIAgent`。切勿在平行呼叫中共享實例。
- **資源清理**：當對話結束時，代理會自動清理資源（終端機對話階段、瀏覽器實例）。如果你在長時間執行的程序中運作，請確保每次對話都能正常完成。
- **迭代限制**：預設的 `max_iterations=90` 非常慷慨。對於簡單的問答場景，請考慮調低此值（例如 `max_iterations=10`），以防止出現失控的工具呼叫迴圈並控制成本。
:::
