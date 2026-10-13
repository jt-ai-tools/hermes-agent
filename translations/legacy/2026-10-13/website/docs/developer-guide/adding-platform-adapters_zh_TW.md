---
sidebar_position: 9
---

# 新增平台適配器 (Adding a Platform Adapter)

本指南涵蓋了向 Hermes 閘道 (gateway) 新增通訊平台的操作。平台適配器 (platform adapter) 將 Hermes 連接到外部通訊服務（例如 Telegram、Discord、WeCom 等），以便使用者可以透過該服務與代理 (agent) 進行互動。

:::tip
新增一個平台適配器會涉及程式碼、配置和文件等 20 多個檔案。請將本指南當作檢核清單使用——適配器檔案本身通常僅佔工作量的 40%。
:::

## 架構概覽

```
使用者 ↔ 通訊平台 ↔ 平台適配器 ↔ 閘道執行器 ↔ AIAgent
```

每個適配器都繼承自 `gateway/platforms/base.py` 中的 `BasePlatformAdapter` 並實作以下內容：

- **`connect()`** — 建立連接（WebSocket、長輪詢、HTTP 伺服器等）
- **`disconnect()`** — 安全關閉
- **`send()`** — 向聊天發送文字訊息
- **`send_typing()`** — 顯示輸入中指示器（選用）
- **`get_chat_info()`** — 回傳聊天元數據 (metadata)

入站訊息由適配器接收，並透過 `self.handle_message(event)` 轉發，基類會將其路由到閘道執行器 (gateway runner)。

## 逐步操作清單

### 1. 平台列舉 (Platform Enum)

在 `gateway/config.py` 的 `Platform` 列舉中新增您的平台：

```python
class Platform(str, Enum):
    # ... 現有平台 ...
    NEWPLAT = "newplat"
```

### 2. 適配器檔案

建立 `gateway/platforms/newplat.py`：

```python
from gateway.config import Platform, PlatformConfig
from gateway.platforms.base import (
    BasePlatformAdapter, MessageEvent, MessageType, SendResult,
)

def check_newplat_requirements() -> bool:
    """若依賴項目可用則回傳 True。"""
    return SOME_SDK_AVAILABLE

class NewPlatAdapter(BasePlatformAdapter):
    def __init__(self, config: PlatformConfig):
        super().__init__(config, Platform.NEWPLAT)
        # 從 config.extra 字典讀取配置
        extra = config.extra or {}
        self._api_key = extra.get("api_key") or os.getenv("NEWPLAT_API_KEY", "")

    async def connect(self) -> bool:
        # 設定連接，開始輪詢/webhook
        self._mark_connected()
        return True

    async def disconnect(self) -> None:
        self._running = False
        self._mark_disconnected()

    async def send(self, chat_id, content, reply_to=None, metadata=None):
        # 透過平台 API 發送訊息
        return SendResult(success=True, message_id="...")

    async def get_chat_info(self, chat_id):
        return {"name": chat_id, "type": "dm"}
```

對於入站訊息，建立一個 `MessageEvent` 並呼叫 `self.handle_message(event)`：

```python
source = self.build_source(
    chat_id=chat_id,
    chat_name=name,
    chat_type="dm",  # 或 "group"
    user_id=user_id,
    user_name=user_name,
)
event = MessageEvent(
    text=content,
    message_type=MessageType.TEXT,
    source=source,
    message_id=msg_id,
)
await self.handle_message(event)
```

### 3. 閘道配置 (`gateway/config.py`)

三個修改點：

1. **`get_connected_platforms()`** — 為您的平台所需憑證新增檢查
2. **`load_gateway_config()`** — 新增權杖 (token) 環境映射條目：`Platform.NEWPLAT: "NEWPLAT_TOKEN"`
3. **`_apply_env_overrides()`** — 將所有 `NEWPLAT_*` 環境變數映射到配置

### 4. 閘道執行器 (`gateway/run.py`)

六個修改點：

1. **`_create_adapter()`** — 新增 `elif platform == Platform.NEWPLAT:` 分支
2. **`_is_user_authorized()` allowed_users 映射** — `Platform.NEWPLAT: "NEWPLAT_ALLOWED_USERS"`
3. **`_is_user_authorized()` allow_all 映射** — `Platform.NEWPLAT: "NEWPLAT_ALLOW_ALL_USERS"`
4. **早期環境檢查 `_any_allowlist` 元組** — 新增 `"NEWPLAT_ALLOWED_USERS"`
5. **早期環境檢查 `_allow_all` 元組** — 新增 `"NEWPLAT_ALLOW_ALL_USERS"`
6. **`_UPDATE_ALLOWED_PLATFORMS` 凍結集合 (frozenset)** — 新增 `Platform.NEWPLAT`

### 5. 跨平台遞送 (Cross-Platform Delivery)

1. **`gateway/platforms/webhook.py`** — 在遞送類型元組中新增 `"newplat"`
2. **`cron/scheduler.py`** — 新增到 `_KNOWN_DELIVERY_PLATFORMS` 凍結集合和 `_deliver_result()` 平台映射中

### 6. CLI 整合

1. **`hermes_cli/config.py`** — 將所有 `NEWPLAT_*` 變數新增到 `_EXTRA_ENV_KEYS`
2. **`hermes_cli/gateway.py`** — 在 `_PLATFORMS` 列表中新增條目，包含 key、label、emoji、token_var、setup_instructions 和 vars
3. **`hermes_cli/platforms.py`** — 新增 `PlatformInfo` 條目，包含 label 和 default_toolset（由 `skills_config` 和 `tools_config` TUI 使用）
4. **`hermes_cli/setup.py`** — 新增 `_setup_newplat()` 函式（可委派給 `gateway.py`）並將元組新增到通訊平台列表中
5. **`hermes_cli/status.py`** — 新增平台檢測條目：`"NewPlat": ("NEWPLAT_TOKEN", "NEWPLAT_HOME_CHANNEL")`
6. **`hermes_cli/dump.py`** — 在平台檢測字典中新增 `"newplat": "NEWPLAT_TOKEN"`

### 7. 工具 (Tools)

1. **`tools/send_message_tool.py`** — 在平台映射中新增 `"newplat": Platform.NEWPLAT`
2. **`tools/cronjob_tools.py`** — 在遞送目標描述字串中新增 `newplat`

### 8. 工具集 (Toolsets)

1. **`toolsets.py`** — 使用 `_HERMES_CORE_TOOLS` 新增 `"hermes-newplat"` 工具集定義
2. **`toolsets.py`** — 將 `"hermes-newplat"` 新增到 `"hermes-gateway"` 的包含列表中

### 9. 選用：平台提示 (Platform Hints)

**`agent/prompt_builder.py`** — 如果您的平台有特定的渲染限制（不支援 Markdown、訊息長度限制等），請在 `_PLATFORM_HINTS` 字典中新增條目。這會將平台專用的指引注入到系統提示詞中：

```python
_PLATFORM_HINTS = {
    # ...
    "newplat": (
        "您正透過 NewPlat 進行聊天。它支援 Markdown 格式，"
        "但有 4000 個字元的訊息限制。"
    ),
}
```

並非所有平台都需要提示——只有在代理的行為應該有所區別時才新增。

### 10. 測試 (Tests)

建立 `tests/gateway/test_newplat.py`，涵蓋：

- 從配置建構適配器
- 建立訊息事件 (Message event building)
- 發送方法（模擬外部 API）
- 平台專屬功能（加密、路由等）

### 11. 文件 (Documentation)

| 檔案 | 需要新增的內容 |
|------|-------------|
| `website/docs/user-guide/messaging/newplat.md` | 完整的平台設定頁面 |
| `website/docs/user-guide/messaging/index.md` | 平台比較表、架構圖、工具集表格、安全性章節、後續步驟連結 |
| `website/docs/reference/environment-variables.md` | 所有 NEWPLAT_* 環境變數 |
| `website/docs/reference/toolsets-reference.md` | hermes-newplat 工具集 |
| `website/docs/integrations/index.md` | 平台連結 |
| `website/sidebars.ts` | 文件頁面的側邊欄條目 |
| `website/docs/developer-guide/architecture.md` | 適配器計數與列表 |
| `website/docs/developer-guide/gateway-internals.md` | 適配器檔案列表 |

## 完整度審計 (Parity Audit)

在將新平台 PR 標記為完成之前，請針對現有平台執行完整度審計：

```bash
# 尋找所有提到參考平台 (例如 bluebubbles) 的 .py 檔案
search_files "bluebubbles" output_mode="files_only" file_glob="*.py"

# 尋找所有提到新平台 (newplat) 的 .py 檔案
search_files "newplat" output_mode="files_only" file_glob="*.py"

# 第一組檔案中出現但第二組未出現的檔案都是潛在的遺漏點
```

對 `.md` 和 `.ts` 檔案重複此操作。調查每個遺漏點——是需要更新的平台列舉，還是可以跳過的平台專屬引用？

## 常見模式

### 長輪詢適配器 (Long-Poll Adapters)

如果您的適配器使用長輪詢（如 Telegram 或微信），請使用輪詢迴圈任務：

```python
async def connect(self):
    self._poll_task = asyncio.create_task(self._poll_loop())
    self._mark_connected()

async def _poll_loop(self):
    while self._running:
        messages = await self._fetch_updates()
        for msg in messages:
            await self.handle_message(self._build_event(msg))
```

### 回呼/Webhook 適配器 (Callback/Webhook Adapters)

如果平台將訊息推送到您的端點（如 WeCom Callback），請執行 HTTP 伺服器：

```python
async def connect(self):
    self._app = web.Application()
    self._app.router.add_post("/callback", self._handle_callback)
    # ... 啟動 aiohttp 伺服器
    self._mark_connected()

async def _handle_callback(self, request):
    event = self._build_event(await request.text())
    await self._message_queue.put(event)
    return web.Response(text="success")  # 立即確認
```

對於回應時限緊迫的平台（例如 WeCom 的 5 秒限制），請務必立即確認收訖，稍後再透過 API 主動遞送代理的回覆。代理工作階段通常執行 3 到 30 分鐘——在回呼回應視窗內直接回覆是不切實際的。

### 權杖鎖 (Token Locks)

如果適配器使用唯一的憑證保持持久連接，請新增範圍鎖 (scoped lock) 以防止兩個設定檔 (profile) 使用相同的憑證：

```python
from gateway.status import acquire_scoped_lock, release_scoped_lock

async def connect(self):
    if not acquire_scoped_lock("newplat", self._token):
        logger.error("權杖已被另一個設定檔使用")
        return False
    # ... 連接

async def disconnect(self):
    release_scoped_lock("newplat", self._token)
```

## 參考實作

| 適配器 | 模式 | 複雜度 | 適合參考的對象 |
|---------|---------|------------|-------------------|
| `bluebubbles.py` | REST + webhook | 中等 | 簡單的 REST API 整合 |
| `weixin.py` | 長輪詢 + CDN | 高 | 媒體處理、加密 |
| `wecom_callback.py` | 回呼/webhook | 中等 | HTTP 伺服器、AES 加密、多應用程式 |
| `telegram.py` | 長輪詢 + Bot API | 高 | 功能完整的適配器，支援群組、討論串 |
