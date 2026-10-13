---
sidebar_position: 7
title: "Gateway 內部運作機制"
description: "訊息通訊閘如何啟動、授權使用者、路由工作階段以及交付訊息"
---

# Gateway 內部運作機制

訊息通訊閘（Messaging Gateway）是一個長期運作的程序，透過統一架構將 Hermes 連接至 14 個以上的外部通訊平台。

## 關鍵檔案

| 檔案 | 用途 |
|------|---------|
| `gateway/run.py` | `GatewayRunner` — 主迴圈、斜線指令、訊息派發（約 9,000 行） |
| `gateway/session.py` | `SessionStore` — 對話持久化與工作階段金鑰建構 |
| `gateway/delivery.py` | 出站訊息交付至目標平台/頻道 |
| `gateway/pairing.py` | 用於使用者授權的私訊（DM）配對流程 |
| `gateway/channel_directory.py` | 將聊天 ID 對應至人類可讀的名稱，用於 Cron 交付 |
| `gateway/hooks.py` | 掛鉤（Hook）偵測、載入與生命週期事件派發 |
| `gateway/mirror.py` | 用於 `send_message` 的跨工作階段訊息鏡像 |
| `gateway/status.py` | 用於設定檔範圍（Profile-scoped）Gateway 實例的 Token 鎖定管理 |
| `gateway/builtin_hooks/` | 始終註冊的掛鉤（例如：BOOT.md 系統提示詞掛鉤） |
| `gateway/platforms/` | 平台適配器（每個通訊平台一個） |

## 架構概覽

```text
┌─────────────────────────────────────────────────┐
│                 GatewayRunner                     │
│                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ Telegram  │  │ Discord  │  │  Slack   │  ...  │
│  │ 適配器    │  │ 適配器    │  │ 適配器    │       │
│  └─────┬─────┘  └─────┬────┘  └─────┬────┘       │
│        │              │              │             │
│        └──────────────┼──────────────┘             │
│                       ▼                            │
│              _handle_message()                     │
│                       │                            │
│          ┌────────────┼────────────┐               │
│          ▼            ▼            ▼               │
│   斜線指令          AIAgent      佇列/背景         │
│     派發            建立         工作階段         │
│                       │                            │
│                       ▼                            │
│              SessionStore                          │
│           (SQLite 持久化儲存)                      │
└─────────────────────────────────────────────────┘
```

## 訊息流程

當訊息從任何平台到達時：

1. **平台適配器**接收原始事件，將其正規化為 `MessageEvent`。
2. **基礎適配器**檢查活動工作階段防護（Active Session Guard）：
   - 如果代理人正在為此工作階段執行 → 將訊息加入佇列，設定中斷事件。
   - 如果是 `/approve`, `/deny`, `/stop` → 繞過防護（直接派發執行）。
3. **GatewayRunner._handle_message()** 接收事件：
   - 透過 `_session_key_for_source()` 解析工作階段金鑰（格式：`agent:main:{platform}:{chat_type}:{chat_id}`）。
   - 檢查授權（參見下文「授權」章節）。
   - 檢查是否為斜線指令 → 派發至指令處理常式。
   - 檢查代理人是否已在執行中 → 攔截 `/stop`, `/status` 等指令。
   - 否則 → 建立 `AIAgent` 實例並執行對話。
4. **回應**透過平台適配器發送回原平台。

### 工作階段金鑰格式

工作階段金鑰編碼了完整的路由上下文：

```
agent:main:{platform}:{chat_type}:{chat_id}
```

例如：`agent:main:telegram:private:123456789`

支援討論串的平台（如 Telegram 論壇主題、Discord 討論串、Slack 討論串）可能會在 chat_id 部分包含討論串 ID。**切勿手動建構工作階段金鑰** — 請始終使用 `gateway/session.py` 中的 `build_session_key()`。

### 兩層級訊息防護

當代理人正在活動執行時，進站訊息會經過兩個循序的防護層：

1. **第 1 層 — 基礎適配器** (`gateway/platforms/base.py`)：檢查 `_active_sessions`。如果工作階段處於活動狀態，則將訊息放入 `_pending_messages` 佇列並設定中斷事件。這在訊息到達 Gateway Runner *之前* 就會進行攔截。

2. **第 2 層 — Gateway Runner** (`gateway/run.py`)：檢查 `_running_agents`。攔截特定指令（`/stop`, `/new`, `/queue`, `/status`, `/approve`, `/deny`）並進行適當路由。其餘所有內容都會觸發 `running_agent.interrupt()`。

在代理人被阻擋時必須到達 Runner 的指令（如 `/approve`）會透過 `await self._message_handler(event)` **直接（Inline）派發** — 它們會繞過背景任務系統以避免競爭條件。

## 授權

Gateway 使用多層授權檢查，依序評估：

1. **平台專屬全開旗標**（例如：`TELEGRAM_ALLOW_ALL_USERS`） — 若設定，該平台上的所有使用者皆獲得授權。
2. **平台允許列表**（例如：`TELEGRAM_ALLOWED_USERS`） — 以逗號分隔的使用者 ID。
3. **私訊（DM）配對** — 已認證的使用者可以透過配對碼配對新使用者。
4. **全域全開旗標** (`GATEWAY_ALLOW_ALL_USERS`) — 若設定，所有平台上的所有使用者皆獲得授權。
5. **預設：拒絕** — 未經授權的使用者將被拒絕。

### 私訊配對流程

```text
管理員: /pair
Gateway: "配對碼：ABC123。請分享給使用者。"
新使用者: ABC123
Gateway: "已配對！您現在已獲得授權。"
```

配對狀態持久化儲存於 `gateway/pairing.py` 中，重新啟動後依然有效。

## 斜線指令派發

Gateway 中的所有斜線指令都流經相同的解析管線：

1. `hermes_cli/commands.py` 中的 `resolve_command()` 將輸入映射至標準名稱（Canonical Name，處理別名與前綴匹配）。
2. 對照 `GATEWAY_KNOWN_COMMANDS` 檢查標準名稱。
3. `_handle_message()` 中的處理常式根據標準名稱進行派發。
4. 某些指令受設定控管（`CommandDef` 上的 `gateway_config_gate`）。

### 執行中代理人防護

在代理人處理期間**不得**執行的指令會被提早拒絕：

```python
if _quick_key in self._running_agents:
    if canonical == "model":
        return "⏳ 代理人正在執行中 — 請等待執行完成或先執行 /stop。"
```

繞過指令（`/stop`, `/new`, `/approve`, `/deny`, `/queue`, `/status`）具有特殊處理邏輯。

## 設定來源

Gateway 從多個來源讀取設定：

| 來源 | 提供內容 |
|--------|-----------------|
| `~/.hermes/.env` | API 金鑰、Bot Token、平台憑證 |
| `~/.hermes/config.yaml` | 模型設定、工具設定、顯示選項 |
| 環境變數 | 覆寫上述任何一項 |

與 CLI 不同（CLI 使用帶有硬編碼預設值的 `load_cli_config()`），Gateway 透過 YAML 載入器直接讀取 `config.yaml`。這意味著存在於 CLI 預設字典中但不存在於使用者設定檔中的設定鍵，在 CLI 與 Gateway 之間的行為可能有所不同。

## 平台適配器

每個通訊平台在 `gateway/platforms/` 中都有一個適配器：

```text
gateway/platforms/
├── base.py              # BaseAdapter — 所有平台共享的邏輯
├── telegram.py          # Telegram Bot API (長輪詢或 Webhook)
├── discord.py           # Discord Bot (透過 discord.py)
├── slack.py             # Slack Socket Mode
├── whatsapp.py          # WhatsApp Business Cloud API
├── signal.py            # Signal (透過 signal-cli REST API)
├── matrix.py            # Matrix (透過 mautrix，選配 E2EE)
├── mattermost.py        # Mattermost WebSocket API
├── email.py             # 電子郵件 (透過 IMAP/SMTP)
├── sms.py               # 簡訊 (透過 Twilio)
├── dingtalk.py          # 釘釘 (WebSocket)
├── feishu.py            # 飛書 (WebSocket 或 Webhook)
├── wecom.py             # 企業微信 (回調模式)
├── weixin.py            # 微信 (個人號，透過 iLink Bot API)
├── bluebubbles.py       # Apple iMessage (透過 BlueBubbles macOS 伺服器)
├── qqbot.py             # QQ 機器人 (騰訊 QQ，透過官方 API v2)
├── webhook.py           # 進站/出站 Webhook 適配器
├── api_server.py        # REST API 伺服器適配器
└── homeassistant.py     # Home Assistant 對話整合
```

適配器實作共同的介面：
- `connect()` / `disconnect()` — 生命週期管理
- `send_message()` — 出站訊息交付
- `on_message()` — 進站訊息正規化 → `MessageEvent`

### Token 鎖定

使用唯一憑證連線的適配器會在 `connect()` 中呼叫 `acquire_scoped_lock()`，並在 `disconnect()` 中呼叫 `release_scoped_lock()`。這可以防止兩個設定檔（Profiles）同時使用同一個 Bot Token。

## 交付路徑

出站交付 (`gateway/delivery.py`) 處理：

- **直接回覆** — 將回應發送回原始聊天。
- **主頻道交付** — 將 Cron 任務輸出與背景執行結果路由至設定的主頻道。
- **明確目標交付** — `send_message` 工具指定 `telegram:-1001234567890`。
- **跨平台交付** — 交付至與原始訊息不同的平台。

Cron 任務交付內容**不會**鏡像到 Gateway 工作階段歷史記錄中 — 它們僅存在於各自的 Cron 工作階段中。這是一項刻意的設計選擇，旨在避免違反訊息交替原則（Message Alternation Violations）。

## 掛鉤 (Hooks)

Gateway 掛鉤是回應生命週期事件的 Python 模組：

### Gateway 掛鉤事件

| 事件 | 觸發時機 |
|-------|-----------|
| `gateway:startup` | Gateway 程序啟動時 |
| `session:start` | 新的對話工作階段開始時 |
| `session:end` | 工作階段完成或逾時時 |
| `session:reset` | 使用者以 `/new` 重設工作階段時 |
| `agent:start` | 代理人開始處理訊息時 |
| `agent:step` | 代理人完成一次工具呼叫反覆運算時 |
| `agent:end` | 代理人完成並回傳回應時 |
| `command:*` | 執行任何斜線指令時 |

掛鉤從 `gateway/builtin_hooks/`（始終活動）與 `~/.hermes/hooks/`（使用者安裝）中偵測。每個掛鉤都是一個包含 `HOOK.yaml` 清單檔案與 `handler.py` 的目錄。

## 記憶體提供者整合

當啟用了記憶體提供者外掛（例如：Honcho）時：

1. Gateway 為每則訊息建立帶有工作階段 ID 的 `AIAgent`。
2. `MemoryManager` 使用工作階段上下文初始化提供者。
3. 提供者工具（例如：`honcho_profile`, `viking_search`）透過以下路徑路由：

```text
AIAgent._invoke_tool()
  → self._memory_manager.handle_tool_call(name, args)
    → provider.handle_tool_call(name, args)
```

4. 在工作階段結束/重設時，觸發 `on_session_end()` 以進行清理與最終資料排空（Flush）。

### 記憶體排空生命週期

當工作階段重設、恢復或過期時：
1. 內建記憶體排空至磁碟。
2. 觸發記憶體提供者的 `on_session_end()` 掛鉤。
3. 一個暫時的 `AIAgent` 執行僅限記憶體的對話輪次。
4. 之後捨棄或封存上下文。

## 背景維護

Gateway 在訊息處理的同時會執行定期維護：

- **Cron 週期觸發** — 檢查任務排程並觸發到期任務。
- **工作階段過期** — 在逾時後清理遭棄置的工作階段。
- **記憶體排空** — 在工作階段過期前主動排空記憶體。
- **快取更新** — 更新模型列表與提供者狀態。

## 程序管理

Gateway 作為一個長期運作的程序執行，管理方式如下：

- `hermes gateway start` / `hermes gateway stop` — 手動控制。
- `systemctl` (Linux) 或 `launchctl` (macOS) — 服務管理。
- PID 檔案位於 `~/.hermes/gateway.pid` — 設定檔範圍的程序追蹤。

**設定檔範圍 vs 全域**：`start_gateway()` 使用設定檔範圍的 PID 檔案。`hermes gateway stop` 僅停止目前設定檔的 Gateway。`hermes gateway stop --all` 使用全域 `ps aux` 掃描來終止所有 Gateway 程序（用於更新期間）。

## 相關文件

- [工作階段儲存](./session-storage.md)
- [Cron 內部運作機制](./cron-internals.md)
- [ACP 內部運作機制](./acp-internals.md)
- [代理人迴圈內部運作機制](./agent-loop.md)
- [訊息通訊閘 (使用者指南)](/docs/user-guide/messaging)
