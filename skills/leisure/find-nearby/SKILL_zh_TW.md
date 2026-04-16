---
name: find-nearby
description: 使用 OpenStreetMap 尋找附近地點（餐廳、咖啡館、酒吧、藥局等）。支援座標、地址、城市、郵遞區號或 Telegram 定位點。無需 API 金鑰。
version: 1.0.0
metadata:
  hermes:
    tags: [location, maps, nearby, places, restaurants, local]
    related_skills: []
---

# 尋找附近 — 當地地點探索

尋找任何位置附近的餐廳、咖啡館、酒吧、藥局和其他地點。使用 OpenStreetMap（免費，無需 API 金鑰）。支援：

- 來自 Telegram 定位點的 **座標**（對話中的緯度/經度）
- **地址**（例如 "near 123 Main St, Springfield"）
- **城市**（例如 "restaurants in downtown Austin"）
- **郵遞區號**（例如 "pharmacies near 90210"）
- **地標**（例如 "cafes near Times Square"）

## 快速參考

```bash
# 透過座標（來自 Telegram 定位點或使用者提供）
python3 SKILL_DIR/scripts/find_nearby.py --lat <LAT> --lon <LON> --type restaurant --radius 1500

# 透過地址、城市或地標（自動地理編碼）
python3 SKILL_DIR/scripts/find_nearby.py --near "Times Square, New York" --type cafe

# 多種地點類型
python3 SKILL_DIR/scripts/find_nearby.py --near "downtown austin" --type restaurant --type bar --limit 10

# JSON 輸出
python3 SKILL_DIR/scripts/find_nearby.py --near "90210" --type pharmacy --json
```

### 參數

| 旗標 | 描述 | 預設值 |
|------|-------------|---------|
| `--lat`, `--lon` | 精確座標 | — |
| `--near` | 地址、城市、郵遞區號或地標（地理編碼） | — |
| `--type` | 地點類型（可重複以搜尋多種） | restaurant |
| `--radius` | 搜尋半徑（公尺） | 1500 |
| `--limit` | 最大結果數 | 15 |
| `--json` | 機器可讀的 JSON 輸出 | off |

### 常見地點類型

`restaurant`, `cafe`, `bar`, `pub`, `fast_food`, `pharmacy`, `hospital`, `bank`, `atm`, `fuel`, `parking`, `supermarket`, `convenience`, `hotel`

## 工作流程

1. **獲取位置。** 從 Telegram 定位點尋找座標（`latitude: ... / longitude: ...`），或詢問使用者的地址/城市/郵遞區號。

2. **詢問偏好**（僅在未說明時）：地點類型、願意前往的距離、任何細節（菜系、"現在營業" 等）。

3. **執行腳本** 並帶入適當的旗標。如果需要以程式化方式處理結果，請使用 `--json`。

4. **呈現結果**，包含名稱、距離和 Google Maps 連結。如果使用者詢問營業時間或 "現在營業"，請檢查結果中的 `hours` 欄位 — 如果缺失或不明確，請使用 `web_search` 進行驗證。

5. **導航路線**，使用結果中的 `directions_url`，或自行建構：`https://www.google.com/maps/dir/?api=1&origin=<LAT>,<LON>&destination=<LAT>,<LON>`

## 小技巧

- 如果結果稀疏，請擴大半徑（1500 → 3000m）。
- 對於 "現在營業" 的請求：檢查結果中的 `hours` 欄位，並與 `web_search` 相互參照以確保準確性，因為 OSM 的營業時間並不總是完整的。
- 僅靠郵遞區號在全球範圍內可能有歧義 — 如果結果看起來不對，請提示使用者提供國家/州。
- 該腳本使用由社群維護的 OpenStreetMap 數據；覆蓋範圍依地區而異。
