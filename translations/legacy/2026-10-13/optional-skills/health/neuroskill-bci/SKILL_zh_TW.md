---
name: neuroskill-bci
description: >
  連接到執行中的 NeuroSkill 實例，並將使用者的即時認知與情緒狀態（專注度、放鬆度、情緒、認知負荷、嗜睡度、心率、HRV、睡眠分期以及 40 多個衍生的 EXG 分數）納入回應中。
  需要一個 BCI 穿戴式裝置（Muse 2/S 或 OpenBCI）以及在本地運行的 NeuroSkill 桌面應用程式。
version: 1.0.0
author: Hermes Agent + Nous Research
license: MIT
metadata:
  hermes:
    tags: [BCI, neurofeedback, health, focus, EEG, cognitive-state, biometrics, neuroskill]
    category: health
    related_skills: []
---

# NeuroSkill 腦機介面 (BCI) 整合

將 Hermes 連接到執行中的 [NeuroSkill](https://neuroskill.com/) 實例，以從 BCI 穿戴式裝置讀取即時的大腦和身體指標。利用這些數據提供具備認知感知的回應、建議干預措施，並追蹤長期的精神表現。

> **⚠️ 僅限研究使用** —— NeuroSkill 是一個開源研究工具。它**不是**醫療器材，且**尚未**獲得 FDA、CE 或任何監管機構的許可。切勿將這些指標用於臨床診斷或治療。

請參閱 `references/metrics.md` 取得完整指標參考，`references/protocols.md` 取得干預方案，以及 `references/api.md` 取得 WebSocket/HTTP API 說明。

---

## 前置要求

- 已安裝 **Node.js 20+** (`node --version`)
- **NeuroSkill 桌面應用程式**正在運行並已連接 BCI 裝置
- **BCI 硬體**：Muse 2, Muse S, 或 OpenBCI (透過 BLE 傳輸 4 通道 EEG + PPG + IMU)
- 執行 `npx neuroskill status` 能回傳資料且無錯誤

### 驗證設定
```bash
node --version                    # 必須為 20+
npx neuroskill status             # 系統完整快照
npx neuroskill status --json      # 機器可解析的 JSON
```

如果 `npx neuroskill status` 回傳錯誤，請告知使用者：
- 確保 NeuroSkill 桌面應用程式已開啟
- 確保 BCI 裝置已開機並透過藍牙連接
- 檢查訊號品質 —— NeuroSkill 中應顯示綠色指示燈（每個電極 ≥0.7）
- 如果提示 `command not found`，請安裝 Node.js 20+

---

## CLI 參考：`npx neuroskill <command>`

所有命令都支援 `--json`（原始 JSON，適用於管道傳輸）和 `--full`（人類可讀摘要 + JSON）。

| 命令 | 描述 |
|---------|-------------|
| `status` | 系統完整快照：裝置、分數、頻段、比率、睡眠、歷史記錄 |
| `session [N]` | 單個工作階段分析，包含前半段與後半段趨勢 (0 為最近一次) |
| `sessions` | 列出所有日期的所有記錄工作階段 |
| `search` | 使用 ANN 相似度搜尋神經狀態相似的歷史時刻 |
| `compare` | A/B 工作階段比較，包含指標差異與趨勢分析 |
| `sleep [N]` | 睡眠分期分類 (Wake/N1/N2/N3/REM) 與分析 |
| `label "text"` | 在當前時刻建立帶有時間戳記的註解 |
| `search-labels "query"` | 對過去的標籤進行語義向量搜尋 |
| `interactive "query"` | 跨模態 4 層圖搜尋 (文字 → EXG → 標籤) |
| `listen` | 即時事件串流 (預設 5 秒，使用 `--seconds N` 設定) |
| `umap` | 工作階段嵌入向量的 3D UMAP 投影 |
| `calibrate` | 開啟校準視窗並開始建立設定檔 |
| `timer` | 啟動專注計時器 (番茄鐘/深度工作/短暫專注預設值) |
| `notify "title" "body"` | 透過 NeuroSkill 應用程式發送系統通知 |
| `raw '{json}'` | 直接向伺服器傳送原始 JSON |

### 全域標記 (Global Flags)
| 標記 | 描述 |
|------|-------------|
| `--json` | 原始 JSON 輸出 (無 ANSI 碼，適用於管道) |
| `--full` | 人類可讀摘要 + 著色後的 JSON |
| `--port <N>` | 覆寫伺服器連接埠 (預設：自動偵測，通常為 8375) |
| `--ws` | 強制使用 WebSocket 傳輸 |
| `--http` | 強制使用 HTTP 傳輸 |
| `--k <N>` | 最近鄰居數量 (用於 search, search-labels) |
| `--seconds <N>` | listen 的持續時間 (預設：5) |
| `--trends` | 顯示每個工作階段的指標趨勢 (用於 sessions) |
| `--dot` | Graphviz DOT 格式輸出 (用於 interactive) |

---

## 1. 檢查目前狀態

### 獲取即時指標
```bash
npx neuroskill status --json
```

**務必使用 `--json`** 以確保解析可靠。預設輸出為著色後的人類可讀文本。

### 回應中的關鍵欄位

`scores` 對象包含所有即時指標（除非另有說明，否則範圍為 0-1）：

```jsonc
{
  "scores": {
    "focus": 0.70,           // β / (α + θ) —— 持續專注力
    "relaxation": 0.40,      // α / (β + θ) —— 清醒且冷靜
    "engagement": 0.60,      // 積極的精神投入
    "meditation": 0.52,      // Alpha + 靜止度 + HRV 一致性
    "mood": 0.55,            // 由 FAA, TAR, BAR 組成的綜合指標
    "cognitive_load": 0.33,  // 額葉 θ / 顳葉 α · f(FAA, TBR)
    "drowsiness": 0.10,      // TAR + TBR + 下降的頻譜質心
    "hr": 68.2,              // 心率 (bpm，來自 PPG)
    "snr": 14.3,             // 訊雜比 (dB)
    "stillness": 0.88,       // 0–1; 1 = 完全靜止
    "faa": 0.042,            // 額葉 Alpha 不對稱性 (+ = 趨近動機)
    "tar": 0.56,             // Theta/Alpha 比率
    "bar": 0.53,             // Beta/Alpha 比率
    "tbr": 1.06,             // Theta/Beta 比率 (ADHD 代理指標)
    "apf": 10.1,             // Alpha 峰值頻率 (Hz)
    "coherence": 0.614,      // 半球間一致性
    "bands": {
      "rel_delta": 0.28, "rel_theta": 0.18,
      "rel_alpha": 0.32, "rel_beta": 0.17, "rel_gamma": 0.05
    }
  }
}
```

還包括：`device` (狀態、電池、韌體)、`signal_quality` (每個電極 0-1)、`session` (持續時間、時段)、`embeddings` (嵌入向量)、`labels` (標籤)、`sleep` (睡眠摘要) 和 `history` (歷史記錄)。

### 解讀輸出

解析 JSON 並將指標轉譯為自然語言。切勿僅報告原始數據 —— 務必賦予其意義：

**推薦做法：**
> "您現在的專注度穩定在 0.70 —— 這是進入心流狀態 (flow state) 的範圍。心率穩定在 68 bpm，且您的 FAA 為正值，顯示具備良好的積極動機。現在是處理複雜任務的好時機。"

**避免做法：**
> "專注度：0.70，放鬆度：0.40，心率：68"

關鍵解讀閾值（完整指南請參閱 `references/metrics.md`）：
- **專注度 (Focus) > 0.70** → 進入心流區域，請保持
- **專注度 (Focus) < 0.40** → 建議休息或執行特定方案
- **嗜睡度 (Drowsiness) > 0.60** → 疲勞警示，有微睡眠 (micro-sleep) 風險
- **放鬆度 (Relaxation) < 0.30** → 需要壓力干預
- **持續的高認知負荷 (Cognitive Load) > 0.70** → 進行大腦清空或休息
- **TBR > 1.5** → Theta 波佔優勢，執行控制能力下降
- **FAA < 0** → 退縮/負面情緒 —— 考慮進行 FAA 平衡
- **SNR < 3 dB** → 訊號不可靠，建議重新調整電極位置

---

## 2. 工作階段分析

### 單個工作階段解析
```bash
npx neuroskill session --json         # 最近一次工作階段
npx neuroskill session 1 --json       # 前一次工作階段
npx neuroskill session 0 --json | jq '{focus: .metrics.focus, trend: .trends.focus}'
```

回傳完整的指標以及**前半段對比後半段的趨勢** (`"up"`, `"down"`, `"flat"`)。利用此資訊描述工作階段的演變：

> "您的專注度從開始的 0.64 攀升至結束時的 0.76 —— 呈現明顯的上升趨勢。認知負荷從 0.38 降至 0.28，這顯示隨著您進入狀態，任務處理變得更加自動化。"

### 列出所有工作階段
```bash
npx neuroskill sessions --json
npx neuroskill sessions --trends      # 顯示每個工作階段的指標趨勢
```

---

## 3. 歷史搜尋

### 神經相似度搜尋
```bash
npx neuroskill search --json                    # 預設：最後一個工作階段, k=5
npx neuroskill search --k 10 --json             # 搜尋 10 個最近鄰居
npx neuroskill search --start <UTC> --end <UTC> --json
```

使用 HNSW 近似最近鄰搜尋 (approximate nearest-neighbor search) 在 128 維 ZUNA 嵌入向量中尋找神經狀態相似的時刻。回傳距離統計、時間分佈（一天中的小時）和匹配度最高的日期。

當使用者問及以下問題時使用：
- "我上次處於這種狀態是什麼時候？"
- "幫我找出專注度最高的工作階段。"
- "我通常在下午什麼時候會感到精神不濟？"

### 語義標籤搜尋
```bash
npx neuroskill search-labels "深度專注" --k 10 --json
npx neuroskill search-labels "壓力" --json | jq '[.results[].EXG_metrics.tbr]'
```

使用向量嵌入搜尋標籤文本。回傳匹配的標籤及其在標記時相關聯的 EXG 指標。

### 跨模態圖搜尋
```bash
npx neuroskill interactive "深度專注" --json
npx neuroskill interactive "深度專注" --dot | dot -Tsvg > graph.svg
```

4 層圖：查詢 → 文本標籤 → EXG 點 → 附近的標籤。可使用 `--k-text`, `--k-EXG`, `--reach <分鐘>` 進行調整。

---

## 4. 工作階段比較
```bash
npx neuroskill compare --json                   # 預設：最近兩個工作階段
npx neuroskill compare --a-start <UTC> --a-end <UTC> --b-start <UTC> --b-end <UTC> --json
```

回傳約 50 個指標的差異值（絕對變化、百分比變化及方向）。還包括 `insights.improved[]` 和 `insights.declined[]` 陣列、兩個工作階段的睡眠分期以及 UMAP 作業 ID。

結合上下文解讀比較結果 —— 提及趨勢而非僅是數值差異：
> "昨天您有兩個強大的專注時段（上午 10 點和下午 2 點）。今天您有一個從 11 點開始且仍在持續的時段。您今天的整體投入程度較高，但壓力峰值更多 —— 您的壓力指數跳升了 15%，且 FAA 轉為負值的頻率更高。"

```bash
# 按進步百分比排序指標
npx neuroskill compare --json | jq '.insights.deltas | to_entries | sort_by(.value.pct) | reverse'
```

---

## 5. 睡眠資料
```bash
npx neuroskill sleep --json                     # 最近 24 小時
npx neuroskill sleep 0 --json                   # 最近一次睡眠工作階段
npx neuroskill sleep --start <UTC> --end <UTC> --json
```

回傳逐段睡眠分期（5 秒視窗）及分析：
- **分期代碼**：0=Wake, 1=N1, 2=N2, 3=N3 (深眠), 4=REM
- **分析**：睡眠效率百分比 (efficiency_pct)、入睡潛伏期 (onset_latency_min)、REM 潛伏期、睡眠中斷次數等
- **健康目標**：N3 佔 15–25%, REM 佔 20–25%, 效率 >85%, 入睡時間 <20 分鐘

```bash
npx neuroskill sleep --json | jq '.summary | {n3: .n3_epochs, rem: .rem_epochs}'
npx neuroskill sleep --json | jq '.analysis.efficiency_pct'
```

當使用者提到睡眠、疲累或恢復情況時使用。

---

## 6. 標記時刻
```bash
npx neuroskill label "突破"
npx neuroskill label "研究演算法"
npx neuroskill label "冥想後"
npx neuroskill label --json "專注時段開始"   # 回傳 label_id
```

在以下情況自動標記時刻：
- 使用者報告突破或洞察
- 使用者開始新類型的任務（例如「切換到程式碼審查」）
- 使用者完成了一項重要的方案
- 使用者要求您標記目前時刻
- 出現顯著的狀態轉變（進入/離開心流狀態）

標籤儲存在資料庫中，並建立索引以便稍後透過 `search-labels` 和 `interactive` 命令檢索。

---

## 7. 即時串流
```bash
npx neuroskill listen --seconds 30 --json
npx neuroskill listen --seconds 5 --json | jq '[.[] | select(.event == "scores")]'
```

在指定時間內串流即時 WebSocket 事件（EXG, PPG, IMU, 分數, 標籤）。需要 WebSocket 連接（不支援 `--http`）。

用於持續監控場景或在執行方案期間觀察即時指標變化。

---

## 8. UMAP 視覺化
```bash
npx neuroskill umap --json                      # 預設：最近兩個工作階段
npx neuroskill umap --a-start <UTC> --a-end <UTC> --b-start <UTC> --b-end <UTC> --json
```

GPU 加速的 ZUNA 嵌入向量 3D UMAP 投影。`separation_score` 指標顯示兩個工作階段在神經上的區別程度：
- **> 1.5** → 工作階段在神經狀態上截然不同
- **< 0.5** → 兩者俱備相似的大腦狀態

---

## 9. 主動狀態感知

### 工作階段開始檢查
在工作階段開始時，如果使用者提到他們正配戴裝置或詢問其狀態，可選用 status 檢查：
```bash
npx neuroskill status --json
```

加入簡短的狀態摘要：
> "快速檢查：專注度正建立在 0.62，放鬆度良好為 0.55，且您的 FAA 為正值 —— 積極動機已啟動。看起來是一個紮實的開始。"

### 何時主動提及狀態

**僅在**以下情況提及認知狀態：
- 使用者明確要求（「我現在狀態如何？」、「檢查我的專注度」）
- 使用者報告注意力不集中、壓力或疲勞
- 跨越關鍵閾值（嗜睡度 > 0.70，持續的專注度 < 0.30）
- 使用者即將執行高認知要求的任務並詢問準備情況

**切勿**中斷心流狀態來報告指標。如果專注度 > 0.75，請保護該工作階段 —— 保持沉默是正確的回應。

---

## 10. 建議方案 (Protocols)

當指標顯示有需求時，從 `references/protocols.md` 中建議一項方案。在開始之前務必徵詢意見 —— 切勿中斷心流狀態：

> "您的專注度在過去 15 分鐘內持續下降，且 TBR 已攀升超過 1.5 —— 這是 Theta 波主導和精神疲勞的跡象。需要我帶領您執行『Theta-Beta 神經回饋錨點』嗎？這是一個 90 秒的練習，透過節奏計數和呼吸來抑制 Theta 波並提升 Beta 波。"

關鍵觸發條件：
- **專注度 < 0.40, TBR > 1.5** → Theta-Beta 神經回饋錨點或方型呼吸 (Box Breathing)
- **放鬆度 < 0.30, 壓力指數高** → 心臟一致性 (Cardiac Coherence) 或 4-7-8 呼吸法
- **持續的高認知負荷 > 0.70** → 認知負荷卸載 (大腦清空)
- **嗜睡度 > 0.60** → 亞晝夜節律重置 (Ultradian Reset) 或清醒重置 (Wake Reset)
- **FAA < 0 (負值)** → FAA 平衡
- **心流狀態 (專注度 > 0.75, 投入度 > 0.70)** → 請勿中斷
- **高靜止度 + 頭痛指數** → 頸部釋放序列
- **低 RMSSD (< 25ms)** → 迷走神經調理 (Vagal Toning)

---

## 11. 額外工具

### 專注計時器
```bash
npx neuroskill timer --json
```
啟動專注計時器視窗，包含番茄鐘 (25/5)、深度工作 (50/10) 或短暫專注 (15/5) 預設值。

### 校準 (Calibration)
```bash
npx neuroskill calibrate
npx neuroskill calibrate --profile "Eyes Open"
```
開啟校準視窗。當訊號品質不佳或使用者想建立個人化基準線時非常有用。

### 系統通知
```bash
npx neuroskill notify "休息時間" "您的專注度已下降 20 分鐘"
```

### 原始 JSON 傳輸
```bash
npx neuroskill raw '{"command":"status"}' --json
```
用於任何尚未映射到 CLI 子命令的伺服器命令。

---

## 錯誤處理

| 錯誤 | 可能原因 | 修復方法 |
|-------|-------------|-----|
| `npx neuroskill status` 卡住 | NeuroSkill 應用程式未執行 | 開啟 NeuroSkill 桌面應用程式 |
| `device.state: "disconnected"` | BCI 裝置未連接 | 檢查藍牙、裝置電池 |
| 所有分數均回傳 0 | 電極接觸不良 | 重新調整頭帶位置、弄濕電極 |
| `signal_quality` 值 < 0.7 | 電極鬆動 | 調整貼合度、清潔電極接觸點 |
| SNR < 3 dB | 訊號干擾大 | 減少頭部運動、檢查周圍環境 |
| `command not found: npx` | 未安裝 Node.js | 安裝 Node.js 20+ |

---

## 互動範例

**「我現在的情況如何？」**
```bash
npx neuroskill status --json
```
→ 以自然的方式解讀分數，提及專注度、放鬆度、情緒以及任何顯著的比率（FAA, TBR）。僅在指標顯示有需求時建議行動。

**「我無法集中注意力」**
```bash
npx neuroskill status --json
```
→ 檢查指標是否證實此情況（高 Theta、低 Beta、上升的 TBR、高嗜睡度）。
→ 若證實，從 `references/protocols.md` 建議合適的方案。
→ 若指標看起來正常，問題可能是動力不足而非神經學原因。

**「比較今天和昨天的專注度」**
```bash
npx neuroskill compare --json
```
→ 解讀趨勢而非僅是數字。提到哪些方面進步了、哪些退步了，以及可能的原因。

**「我上次處於心流狀態是什麼時候？」**
```bash
npx neuroskill search-labels "flow" --json
npx neuroskill search --json
```
→ 報告時間戳記、相關指標以及使用者當時正在做什麼（來自標籤）。

**「我睡得好嗎？」**
```bash
npx neuroskill sleep --json
```
→ 報告睡眠結構 (N3%, REM%, 效率)，與健康目標進行比較，並記錄任何問題（高醒來次數、低 REM）。

**「標記這個時刻 —— 我剛有了一個突破」**
```bash
npx neuroskill label "breakthrough"
```
→ 確認標籤已儲存。可選用記錄目前的指標以便記住該狀態。

---

## 參考資料

- [NeuroSkill 論文 —— arXiv:2603.03212](https://arxiv.org/abs/2603.03212) (Kosmyna & Hauptmann, MIT Media Lab)
- [NeuroSkill 桌面應用程式](https://github.com/NeuroSkill-com/skill) (GPLv3)
- [NeuroLoop CLI 夥伴工具](https://github.com/NeuroSkill-com/neuroloop) (GPLv3)
- [MIT 媒體實驗室專案頁面](https://www.media.mit.edu/projects/neuroskill/overview/)
