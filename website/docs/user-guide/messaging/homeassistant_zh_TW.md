---
title: Home Assistant
description: 透過 Home Assistant 整合，使用 Hermes Agent 控制您的智慧家庭。
sidebar_label: Home Assistant
sidebar_position: 5
---

# Home Assistant 整合

Hermes Agent 透過兩種方式與 [Home Assistant](https://www.home-assistant.io/) 整合：

1. **網關平台 (Gateway platform)** — 透過 WebSocket 訂閱即時狀態變更並對事件做出回應。
2. **智慧家庭工具** — 四個可供 LLM 呼叫的工具，用於透過 REST API 查詢和控制裝置。

## 設定

### 1. 建立長期存取權杖 (Long-Lived Access Token)

1. 開啟您的 Home Assistant 實例。
2. 前往您的**個人資料**（點擊側邊欄中您的名字）。
3. 捲動到**長期存取權杖 (Long-Lived Access Tokens)**。
4. 點擊**建立權杖**，命名為「Hermes Agent」。
5. 複製權杖。

### 2. 設定環境變數

```bash
# 新增到 ~/.hermes/.env

# 必要：您的長期存取權杖
HASS_TOKEN=your-long-lived-access-token

# 選填：HA URL (預設值：http://homeassistant.local:8123)
HASS_URL=http://192.168.1.100:8123
```

:::info
當設定了 `HASS_TOKEN` 時，`homeassistant` 工具集會自動啟用。網關平台和裝置控制工具都會透過這單一個權杖啟動。
:::

### 3. 啟動網關

```bash
hermes gateway
```

Home Assistant 將與其他通訊平台（Telegram、Discord 等）一起顯示為已連線的平台。

## 可用工具

Hermes Agent 註冊了四個用於智慧家庭控制的工具：

### `ha_list_entities`

列出 Home Assistant 實體，可選擇按領域 (Domain) 或區域 (Area) 進行過濾。

**參數：**
- `domain` *(選填)* — 按實體領域過濾：`light`、`switch`、`climate`、`sensor`、`binary_sensor`、`cover`、`fan`、`media_player` 等。
- `area` *(選填)* — 按區域/房間名稱過濾（與易記名稱匹配）：`living room`（客廳）、`kitchen`（廚房）、`bedroom`（臥室）等。

**範例：**
```
列出客廳裡的所有燈
```

傳回實體 ID、狀態和易記名稱。

### `ha_get_state`

獲取單個實體的詳細狀態，包括所有屬性（亮度、顏色、溫度設定點、感測器讀數等）。

**參數：**
- `entity_id` *(必要)* — 要查詢的實體，例如 `light.living_room`、`climate.thermostat`、`sensor.temperature`。

**範例：**
```
目前 climate.thermostat 的狀態是什麼？
```

傳回：狀態、所有屬性、最後更改/更新的時間戳。

### `ha_list_services`

列出可用於裝置控制的服務（動作）。顯示可以在每種裝置類型上執行的動作及其接受的參數。

**參數：**
- `domain` *(選填)* — 按領域過濾，例如 `light`、`climate`、`switch`。

**範例：**
```
空調 (climate) 裝置有哪些可用服務？
```

### `ha_call_service`

呼叫 Home Assistant 服務來控制裝置。

**參數：**
- `domain` *(必要)* — 服務領域：`light`、`switch`、`climate`、`cover`、`media_player`、`fan`、`scene`、`script`。
- `service` *(必要)* — 服務名稱：`turn_on`、`turn_off`、`toggle`、`set_temperature`、`set_hvac_mode`、`open_cover`、`close_cover`、`set_volume_level`。
- `entity_id` *(選填)* — 目標實體，例如 `light.living_room`。
- `data` *(選填)* — 作為 JSON 物件的其他參數。

**範例：**

```
打開客廳的燈
→ ha_call_service(domain="light", service="turn_on", entity_id="light.living_room")
```

```
將恆溫器設定為暖氣模式 22 度
→ ha_call_service(domain="climate", service="set_temperature",
    entity_id="climate.thermostat", data={"temperature": 22, "hvac_mode": "heat"})
```

```
將客廳的燈設定為藍色，亮度為 50%
→ ha_call_service(domain="light", service="turn_on",
    entity_id="light.living_room", data={"brightness": 128, "color_name": "blue"})
```

## 網關平台：即時事件

Home Assistant 網關適配器透過 WebSocket 連線並訂閱 `state_changed` 事件。當裝置狀態發生更改且符合您的過濾條件時，它將作為訊息轉發給代理。

### 事件過濾

:::warning 必要設定
預設情況下，**不會轉發任何事件**。您必須至少設定 `watch_domains`、`watch_entities` 或 `watch_all` 其中之一才能接收事件。如果沒有設定過濾器，啟動時會記錄警告，並且所有狀態更改都會被靜默丟棄。
:::

在 `~/.hermes/config.yaml` 的 Home Assistant 平台 `extra` 區段中設定代理可看到的事件：

```yaml
platforms:
  homeassistant:
    enabled: true
    extra:
      watch_domains:
        - climate
        - binary_sensor
        - alarm_control_panel
        - light
      watch_entities:
        - sensor.front_door_battery
      ignore_entities:
        - sensor.uptime
        - sensor.cpu_usage
        - sensor.memory_usage
      cooldown_seconds: 30
```

| 設定 | 預設值 | 描述 |
|---------|---------|-------------|
| `watch_domains` | *(無)* | 僅監看這些實體領域（例如 `climate`、`light`、`binary_sensor`） |
| `watch_entities` | *(無)* | 僅監看這些特定的實體 ID |
| `watch_all` | `false` | 設定為 `true` 以接收**所有**狀態更改（不推薦用於大多數設定） |
| `ignore_entities` | *(無)* | 始終忽略這些實體（在領域/實體過濾器之前應用） |
| `cooldown_seconds` | `30` | 同一實體事件之間的最小間隔秒數 |

:::tip
從一組重點領域開始 — `climate`、`binary_sensor` 和 `alarm_control_panel` 涵蓋了最有用的自動化。根據需要新增更多。使用 `ignore_entities` 來抑制吵雜的感測器，如 CPU 溫度或運行時間計數器。
:::

### 事件格式

狀態更改會根據領域格式化為易於閱讀的訊息：

| 領域 | 格式 |
|--------|--------|
| `climate` | "HVAC mode changed from 'off' to 'heat' (current: 21, target: 23)" |
| `sensor` | "changed from 21°C to 22°C" |
| `binary_sensor` | "triggered" / "cleared" |
| `light`, `switch`, `fan` | "turned on" / "turned off" |
| `alarm_control_panel` | "alarm state changed from 'armed_away' to 'triggered'" |
| *(其他)* | "changed from 'old' to 'new'" |

### 代理回應

來自代理的出站訊息會以 **Home Assistant 持久通知** 的形式傳送（透過 `persistent_notification.create`）。這些通知會出現在 HA 通知面板中，標題為「Hermes Agent」。

### 連線管理

- **WebSocket** 帶有 30 秒心跳，用於即時事件。
- **自動重新連線** 帶有退避機制：5s → 10s → 30s → 60s。
- **REST API** 用於出站通知（獨立階段以避免 WebSocket 衝突）。
- **授權** — HA 事件始終是經過授權的（不需要使用者允許清單，因為 `HASS_TOKEN` 已對連線進行身分驗證）。

## 安全性

Home Assistant 工具強制執行安全性限制：

:::warning 封鎖的領域 (Domains)
以下服務領域被**封鎖**，以防止在 HA 主機上執行任意程式碼：

- `shell_command` — 任意 shell 指令
- `command_line` — 執行指令的感測器/開關
- `python_script` — 指令碼化的 Python 執行
- `pyscript` — 更廣泛的指令碼整合
- `hassio` — 附加元件控制、主機關機/重啟
- `rest_command` — 來自 HA 伺服器的 HTTP 請求 (SSRF 向量)

嘗試呼叫這些領域中的服務將傳回錯誤。
:::

實體 ID 會根據模式 `^[a-z_][a-z0-9_]*\.[a-z0-9_]+$` 進行驗證，以防止注入攻擊。

## 自動化範例

### 晨間例行公事

```
使用者：啟動我的晨間例行公事

代理：
1. ha_call_service(domain="light", service="turn_on",
     entity_id="light.bedroom", data={"brightness": 128})
2. ha_call_service(domain="climate", service="set_temperature",
     entity_id="climate.thermostat", data={"temperature": 22})
3. ha_call_service(domain="media_player", service="turn_on",
     entity_id="media_player.kitchen_speaker")
```

### 安全檢查

```
使用者：房子安全嗎？

代理：
1. ha_list_entities(domain="binary_sensor")
     → 檢查門窗感測器
2. ha_get_state(entity_id="alarm_control_panel.home")
     → 檢查警報狀態
3. ha_list_entities(domain="lock")
     → 檢查鎖的狀態
4. 報告：「所有門窗已關閉，警報已設為離家模式，所有鎖已鎖上。」
```

### 反應式自動化（透過網關事件）

當作為網關平台連線時，代理可以對事件做出反應：

```
[Home Assistant] 正門：triggered (was cleared)

代理自動執行：
1. ha_get_state(entity_id="binary_sensor.front_door")
2. ha_call_service(domain="light", service="turn_on",
     entity_id="light.hallway")
3. 傳送通知：「正門已開啟。玄關燈已打開。」
```
