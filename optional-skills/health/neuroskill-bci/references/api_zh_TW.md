# NeuroSkill WebSocket 與 HTTP API 參考

NeuroSkill 運行於本地伺服器 (預設連接埠為 **8375**)，可透過 mDNS (`_skill._tcp`) 進行搜尋。它提供 WebSocket 與 HTTP 兩個端點。

---

## 伺服器搜尋

```bash
# 自動搜尋 (內建於 CLI 中 — 通常可以直接運作)
npx neuroskill status --json

# 手動連接埠搜尋
NEURO_PORT=$(lsof -i -n -P | grep neuroskill | grep LISTEN | awk '{print $9}' | cut -d: -f2 | head -1)
echo "NeuroSkill 運行於連接埠: $NEURO_PORT"
```

CLI 會自動搜尋連接埠。使用 `--port <N>` 可手動覆蓋。

---

## HTTP REST 端點

### 通用命令通道 (Universal Command Tunnel)
```bash
# POST / — 接受 JSON 格式的任何命令
curl -s -X POST http://127.0.0.1:8375/ \
  -H "Content-Type: application/json" \
  -d '{"command":"status"}'
```

### 便利端點 (Convenience Endpoints)
| 方法 | 端點 | 說明 |
|--------|----------|-------------|
| GET | `/v1/status` | 系統狀態 |
| GET | `/v1/sessions` | 列表工作階段 |
| POST | `/v1/label` | 建立標籤 |
| POST | `/v1/search` | ANN 搜尋 |
| POST | `/v1/compare` | A/B 比較 |
| POST | `/v1/sleep` | 睡眠分期 |
| POST | `/v1/notify` | OS 通知 |
| POST | `/v1/say` | 語音合成 (TTS) |
| POST | `/v1/calibrate` | 開啟校準 |
| POST | `/v1/timer` | 開啟專注計時器 |
| GET | `/v1/dnd` | 獲取 DND (請勿打擾) 狀態 |
| POST | `/v1/dnd` | 強制開啟/關閉 DND |
| GET | `/v1/calibrations` | 列表校準設定檔 |
| POST | `/v1/calibrations` | 建立設定檔 |
| GET | `/v1/calibrations/{id}` | 獲取設定檔 |
| PATCH | `/v1/calibrations/{id}` | 更新設定檔 |
| DELETE | `/v1/calibrations/{id}` | 刪除設定檔 |

---

## WebSocket 事件 (廣播)

連接至 `ws://127.0.0.1:8375/` 以接收即時事件：

### EXG (原始 EEG 樣本)
```json
{"event": "EXG", "electrode": 0, "samples": [12.3, -4.1, ...], "timestamp": 1740412800.512}
```

### PPG (光學心率感測)
```json
{"event": "PPG", "channel": 0, "samples": [...], "timestamp": 1740412800.512}
```

### IMU (慣性測量單元)
```json
{"event": "IMU", "ax": 0.01, "ay": -0.02, "az": 9.81, "gx": 0.1, "gy": -0.05, "gz": 0.02}
```

### Scores (計算出的指標)
```json
{
  "event": "scores",
  "focus": 0.70, "relaxation": 0.40, "engagement": 0.60,
  "rel_delta": 0.28, "rel_theta": 0.18, "rel_alpha": 0.32,
  "rel_beta": 0.17, "hr": 68.2, "snr": 14.3
}
```

### EXG Bands (頻譜分析)
```json
{"event": "EXG-bands", "channels": [...], "faa": 0.12}
```

### Labels (標籤)
```json
{"event": "label", "label_id": 42, "text": "meditation start", "created_at": 1740413100}
```

### Device Status (設備狀態)
```json
{"event": "muse-status", "state": "connected"}
```

---

## JSON 回應格式

### `status` (狀態)
```jsonc
{
  "command": "status", "ok": true,
  "device": {
    "state": "connected",     // "connected" | "connecting" | "disconnected"
    "name": "Muse-A1B2",
    "battery": 73,
    "firmware": "1.3.4",
    "EXG_samples": 195840,
    "ppg_samples": 30600,
    "imu_samples": 122400
  },
  "session": {
    "start_utc": 1740412800,
    "duration_secs": 1847,
    "n_epochs": 369
  },
  "signal_quality": {
    "tp9": 0.95, "af7": 0.88, "af8": 0.91, "tp10": 0.97
  },
  "scores": {
    "focus": 0.70, "relaxation": 0.40, "engagement": 0.60,
    "meditation": 0.52, "mood": 0.55, "cognitive_load": 0.33,
    "drowsiness": 0.10, "hr": 68.2, "snr": 14.3, "stillness": 0.88,
    "bands": { "rel_delta": 0.28, "rel_theta": 0.18, "rel_alpha": 0.32, "rel_beta": 0.17, "rel_gamma": 0.05 },
    "faa": 0.042, "tar": 0.56, "bar": 0.53, "tbr": 1.06,
    "apf": 10.1, "coherence": 0.614, "mu_suppression": 0.031
  },
  "embeddings": { "today": 342, "total": 14820, "recording_days": 31 },
  "labels": { "total": 58, "recent": [{"id": 42, "text": "meditation start", "created_at": 1740413100}] },
  "sleep": { "total_epochs": 1054, "wake_epochs": 134, "n1_epochs": 89, "n2_epochs": 421, "n3_epochs": 298, "rem_epochs": 112, "epoch_secs": 5 },
  "history": { "total_sessions": 63, "recording_days": 31, "current_streak_days": 7, "total_recording_hours": 94.2, "longest_session_min": 187, "avg_session_min": 89 }
}
```

### `sessions` (工作階段列表)
```jsonc
{
  "command": "sessions", "ok": true,
  "sessions": [
    { "day": "20260224", "start_utc": 1740412800, "end_utc": 1740415510, "n_epochs": 541 },
    { "day": "20260223", "start_utc": 1740380100, "end_utc": 1740382665, "n_epochs": 513 }
  ]
}
```

### `session` (單個工作階段詳情)
```jsonc
{
  "ok": true,
  "metrics": { "focus": 0.70, "relaxation": 0.40, "n_epochs": 541 /* ... 約 50 個指標 */ },
  "first":   { "focus": 0.64 /* 前半部分平均值 */ },
  "second":  { "focus": 0.76 /* 後半部分平均值 */ },
  "trends":  { "focus": "up", "relaxation": "down" /* "up" | "down" | "flat" */ }
}
```

### `compare` (A/B 比較)
```jsonc
{
  "command": "compare", "ok": true,
  "insights": {
    "deltas": {
      "focus": { "a": 0.62, "b": 0.71, "abs": 0.09, "pct": 14.5, "direction": "up" },
      "relaxation": { "a": 0.45, "b": 0.38, "abs": -0.07, "pct": -15.6, "direction": "down" }
    },
    "improved": ["focus", "engagement"],
    "declined": ["relaxation"]
  },
  "sleep_a": { /* 工作階段 A 的睡眠摘要 */ },
  "sleep_b": { /* 工作階段 B 的睡眠摘要 */ },
  "umap": { "job_id": "abc123" }
}
```

### `search` (ANN 相似度搜尋)
```jsonc
{
  "command": "search", "ok": true,
  "result": {
    "results": [{
      "neighbors": [{ "distance": 0.12, "metadata": {"device": "Muse-A1B2", "date": "20260223"} }]
    }],
    "analysis": {
      "distance_stats": { "mean": 0.15, "min": 0.08, "max": 0.42 },
      "temporal_distribution": { /* 一天中各小時的分佈 */ },
      "top_days": [["20260223", 5], ["20260222", 3]]
    }
  }
}
```

### `sleep` (睡眠分期)
```jsonc
{
  "command": "sleep", "ok": true,
  "summary": { "total_epochs": 1054, "wake_epochs": 134, "n1_epochs": 89, "n2_epochs": 421, "n3_epochs": 298, "rem_epochs": 112, "epoch_secs": 5 },
  "analysis": { "efficiency_pct": 87.3, "onset_latency_min": 12.5, "rem_latency_min": 65.0, "bouts": { /* 清醒/n3/rem 的次數與時長 */ } },
  "epochs": [{ "utc": 1740380100, "stage": 0, "rel_delta": 0.15, "rel_theta": 0.22, "rel_alpha": 0.38, "rel_beta": 0.20 }]
}
```

### `label` (建立標籤)
```json
{"command": "label", "ok": true, "label_id": 42}
```

### `search-labels` (語義標籤搜尋)
```jsonc
{
  "command": "search-labels", "ok": true,
  "results": [{
    "text": "deep focus block",
    "EXG_metrics": { "focus": 0.82, "relaxation": 0.35, "engagement": 0.75, "hr": 65.0, "mood": 0.60 },
    "EXG_start": 1740412800, "EXG_end": 1740412805,
    "created_at": 1740412802,
    "similarity": 0.92
  }]
}
```

### `umap` (3D 投影)
```jsonc
{
  "command": "umap", "ok": true,
  "result": {
    "points": [{ "x": 1.23, "y": -0.45, "z": 2.01, "session": "a", "utc": 1740412800 }],
    "analysis": {
      "separation_score": 1.84,
      "inter_cluster_distance": 2.31,
      "intra_spread_a": 0.82, "intra_spread_b": 0.94,
      "centroid_a": [1.23, -0.45, 2.01],
      "centroid_b": [-0.87, 1.34, -1.22]
    }
  }
}
```

---

## 實用的 `jq` 片段

```bash
# 僅獲取專注度分數
npx neuroskill status --json | jq '.scores.focus'

# 獲取所有頻帶功率
npx neuroskill status --json | jq '.scores.bands'

# 檢查設備電量
npx neuroskill status --json | jq '.device.battery'

# 獲取訊號品質
npx neuroskill status --json | jq '.signal_quality'

# 找出工作階段後提升的指標
npx neuroskill session 0 --json | jq '[.trends | to_entries[] | select(.value == "up") | .key]'

# 按提升比例排序比較增量
npx neuroskill compare --json | jq '.insights.deltas | to_entries | sort_by(.value.pct) | reverse'

# 獲取睡眠效率
npx neuroskill sleep --json | jq '.analysis.efficiency_pct'

# 尋找最接近的神經匹配
npx neuroskill search --json | jq '[.result.results[].neighbors[]] | sort_by(.distance) | .[0]'

# 從標記為「壓力」的時刻提取 TBR
npx neuroskill search-labels "stress" --json | jq '[.results[].EXG_metrics.tbr]'

# 獲取工作階段時間戳記以便手動比較
npx neuroskill sessions --json | jq '{start: .sessions[0].start_utc, end: .sessions[0].end_utc}'
```

---

## 數據存儲

- **本地數據庫**: `~/.skill/YYYYMMDD/` (SQLite + HNSW 索引)
- **ZUNA 嵌入 (Embeddings)**: 128 維向量，5 秒一期 (epoch)
- **標籤**: 存儲於 SQLite 中，使用 bge-small-en-v1.5 嵌入進行索引
- **所有數據皆存儲於本地** — 不會發送到外部伺服器
