# 新增通訊平台

將新通訊平台整合至 Hermes 閘道器的檢查清單。
在開發新的轉接器 (adapter) 時，請參考此清單 —— 這裡列出的每一項都是程式碼中存在的真實整合點。漏掉任何一項都會導致功能毀損、功能缺失或行為不一致。

---

## 1. 核心轉接器 (`gateway/platforms/<platform>.py`)

轉接器是 `gateway/platforms/base.py` 中 `BasePlatformAdapter` 的子類。

### 必要方法 (Required methods)

| 方法 | 用途 |
|--------|---------|
| `__init__(self, config)` | 解析設定，初始化狀態。呼叫 `super().__init__(config, Platform.YOUR_PLATFORM)` |
| `connect() -> bool` | 連接至平台，啟動監聽器。成功時回傳 True |
| `disconnect()` | 停止監聽器，關閉連接，取消任務 |
| `send(chat_id, text, ...) -> SendResult` | 發送文字訊息 |
| `send_typing(chat_id)` | 發送輸入中提示 |
| `send_image(chat_id, image_url, caption) -> SendResult` | 發送圖片 |
| `get_chat_info(chat_id) -> dict` | 回傳聊天的 `{name, type, chat_id}` |

### 選用方法 (Optional methods，基類已有預設 stub)

| 方法 | 用途 |
|--------|---------|
| `send_document(chat_id, path, caption)` | 發送檔案附件 |
| `send_voice(chat_id, path)` | 發送語音訊息 |
| `send_video(chat_id, path, caption)` | 發送影片 |
| `send_animation(chat_id, path, caption)` | 發送 GIF/動畫 |
| `send_image_file(chat_id, path, caption)` | 從本地檔案發送圖片 |

### 必要函式 (Required function)

```python
def check_<platform>_requirements() -> bool:
    """檢查此平台的依賴項是否可用。"""
```

### 應遵循的關鍵模式

- 使用 `self.build_source(...)` 構建 `SessionSource` 物件
- 呼叫 `self.handle_message(event)` 將傳入訊息發送至閘道器
- 使用來自 base 的 `MessageEvent`, `MessageType`, `SendResult`
- 使用 `cache_image_from_bytes`, `cache_audio_from_bytes`, `cache_document_from_bytes` 處理附件
- 過濾自身訊息（防止回覆無窮迴圈）
- 過濾同步/回顯訊息（如果平台有提供）
- 在所有日誌輸出中遮蔽敏感識別碼（電話號碼、權杖）
- 為串流連接實作具備指數退避 (exponential backoff) 與抖動 (jitter) 的重新連接機制
- 如果平台有訊息大小限制，請設定 `MAX_MESSAGE_LENGTH`

---

## 2. 平台列舉 (`gateway/config.py`)

將平台新增至 `Platform` 列舉中：

```python
class Platform(Enum):
    ...
    YOUR_PLATFORM = "your_platform"
```

在 `_apply_env_overrides()` 中新增環境變數載入邏輯：

```python
# 您的平台 (Your Platform)
your_token = os.getenv("YOUR_PLATFORM_TOKEN")
if your_token:
    if Platform.YOUR_PLATFORM not in config.platforms:
        config.platforms[Platform.YOUR_PLATFORM] = PlatformConfig()
    config.platforms[Platform.YOUR_PLATFORM].enabled = True
    config.platforms[Platform.YOUR_PLATFORM].token = your_token
```

如果您的平台不使用權杖或 API 金鑰（例如 WhatsApp 使用 `enabled` 旗標，Signal 使用 `extra` 字典），請更新 `get_connected_platforms()`。

---

## 3. 轉接器工廠 (`gateway/run.py`)

新增至 `_create_adapter()`：

```python
elif platform == Platform.YOUR_PLATFORM:
    from gateway.platforms.your_platform import YourAdapter, check_your_requirements
    if not check_your_requirements():
        logger.warning("Your Platform: 依賴項未滿足")
        return None
    return YourAdapter(config)
```

---

## 4. 授權對照表 (`gateway/run.py`)

將其新增至 `_is_user_authorized()` 中的兩個字典：

```python
platform_env_map = {
    ...
    Platform.YOUR_PLATFORM: "YOUR_PLATFORM_ALLOWED_USERS",
}
platform_allow_all_map = {
    ...
    Platform.YOUR_PLATFORM: "YOUR_PLATFORM_ALLOW_ALL_USERS",
}
```

---

## 5. 會話來源 (`gateway/session.py`)

如果您的平台需要額外的身份欄位（例如 Signal 的 UUID 與電話號碼），請將其新增至 `SessionSource` 資料類別中，並將預設值設為 `Optional`，同時更新 base.py 中的 `to_dict()`、`from_dict()` 和 `build_source()`。

---

## 6. 系統提示詞提示 (`agent/prompt_builder.py`)

新增 `PLATFORM_HINTS` 條目，讓代理知道它目前在哪個平台：

```python
PLATFORM_HINTS = {
    ...
    "your_platform": (
        "您目前正在使用 Your Platform。"
        "描述格式化功能、媒體支援等。"
    ),
}
```

如果沒有這個，代理將不知道它在哪個平台，並可能使用不適當的格式（例如在不支援渲染的平台上使用 Markdown）。

---

## 7. 工具集 (`toolsets.py`)

為您的平台新增一個具名的工具集：

```python
"hermes-your-platform": {
    "description": "Your Platform 機器人工具集",
    "tools": _HERMES_CORE_TOOLS,
    "includes": []
},
```

並將其新增至 `hermes-gateway` 組合中：

```python
"hermes-gateway": {
    "includes": [..., "hermes-your-platform"]
}
```

---

## 8. Cron 排程發送 (`cron/scheduler.py`)

新增至 `_deliver_result()` 中的 `platform_map`：

```python
platform_map = {
    ...
    "your_platform": Platform.YOUR_PLATFORM,
}
```

如果沒有這項設定，`cronjob(action="create", deliver="your_platform", ...)` 會發生靜默失敗。

---

## 9. 訊息發送工具 (`tools/send_message_tool.py`)

新增至 `send_message_tool()` 中的 `platform_map`：

```python
platform_map = {
    ...
    "your_platform": Platform.YOUR_PLATFORM,
}
```

在 `_send_to_platform()` 中新增路由：

```python
elif platform == Platform.YOUR_PLATFORM:
    return await _send_your_platform(pconfig, chat_id, message)
```

實作 `_send_your_platform()` —— 一個獨立的非同步函式，用於在不需要完整轉接器的情況下發送單條訊息（供排程任務和閘道器程序之外的 `send_message` 工具使用）。

更新工具架構中的 `target` 描述，以包含您的平台範例。

---

## 10. Cronjob 工具架構 (`tools/cronjob_tools.py`)

更新 `deliver` 參數的描述和文件字串，將您的平台列為發送選項之一。

---

## 11. 頻道目錄 (`gateway/channel_directory.py`)

如果您的平台無法列舉聊天列表（大多數平台無法做到），請將其新增至基於會話的搜索清單中：

```python
for plat_name in ("telegram", "whatsapp", "signal", "your_platform"):
```

---

## 12. 狀態顯示 (`hermes_cli/status.py`)

在「通訊平台 (Messaging Platforms)」區段的 `platforms` 字典中新增：

```python
platforms = {
    ...
    "Your Platform": ("YOUR_PLATFORM_TOKEN", "YOUR_PLATFORM_HOME_CHANNEL"),
}
```

---

## 13. 閘道器設定精靈 (`hermes_cli/gateway.py`)

新增至 `_PLATFORMS` 清單：

```python
{
    "key": "your_platform",
    "label": "Your Platform",
    "emoji": "📱",
    "token_var": "YOUR_PLATFORM_TOKEN",
    "setup_instructions": [...],
    "vars": [...],
}
```

如果您的平台需要自訂設定邏輯（連接性測試、QR code、政策選擇），請新增 `_setup_your_platform()` 函式並在平台選擇開關中路由至該函式。

如果您的平台「已設定」檢查與標準的 `bool(get_env_value(token_var))` 不同，請更新 `_platform_status()`。

---

## 14. 電話/識別碼遮蔽 (`agent/redact.py`)

如果您的平台使用敏感識別碼（電話號碼等），請在 `agent/redact.py` 中新增正則表達式模式和遮蔽函式。這能確保識別碼在「所有」日誌輸出中都被遮蓋，而不僅僅是您轉接器的日誌。

---

## 15. 文件

| 檔案 | 需更新內容 |
|------|---------------|
| `README.md` | 功能表與文件表中的平台清單 |
| `AGENTS.md` | 閘道器描述與環境變數設定章節 |
| `website/docs/user-guide/messaging/<platform>.md` | **新增** —— 完整設定指南（參考現有平台文件作為範本） |
| `website/docs/user-guide/messaging/index.md` | 架構圖、工具集表格、安全性範例、後續步驟連結 |
| `website/docs/reference/environment-variables.md` | 該平台的所有環境變數 |

---

## 16. 測試 (`tests/gateway/test_<platform>.py`)

建議的測試涵蓋範圍：

- 平台列舉值是否存在且正確
- 透過 `_apply_env_overrides` 從環境變數載入設定
- 轉接器初始化（設定解析、白名單處理、預設值）
- 輔助函式（遮蔽、解析、檔案類型偵測）
- 會話來源來回轉換 (to_dict → from_dict)
- 授權整合（白名單對照表中的平台）
- 訊息發送工具路由（platform_map 中的平台）

選用但具價值的測試：
- 訊息處理流程的非同步測試（模擬平台 API）
- SSE/WebSocket 重新連接邏輯
- 附件處理
- 群組訊息過濾

---

## 快速驗證

完成所有實作後，請執行以下指令進行驗證：

```bash
# 所有測試皆通過
python -m pytest tests/ -q

# 使用 grep 搜尋您的平台名稱，找出任何遺漏的整合點
grep -r "telegram\|discord\|whatsapp\|slack" gateway/ tools/ agent/ cron/ hermes_cli/ toolsets.py \
  --include="*.py" -l | sort -u
# 檢查輸出中的每個檔案 —— 如果該檔案提到了其他平台但沒提到您的平台，表示您漏掉了
```
