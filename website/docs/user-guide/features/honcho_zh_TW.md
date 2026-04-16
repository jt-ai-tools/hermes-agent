---
sidebar_position: 99
title: "Honcho 記憶"
description: "透過 Honcho 實現 AI 原生持久性記憶 — 辯證式推理、多代理使用者建模與深度個人化"
---

# Honcho 記憶

[Honcho](https://github.com/plastic-labs/honcho) 是一個 AI 原生記憶後端，它在 Hermes 內建記憶系統的基礎上增加了辯證式推理 (dialectic reasoning) 和深度使用者建模功能。Honcho 不僅僅是簡單的鍵值 (key-value) 存儲，它還會透過對對話發生後的推理，維護一個使用者特徵模型 — 包括他們的偏好、溝通風格、目標和模式。

:::info Honcho 是一個記憶提供者插件
Honcho 已整合至 [記憶提供者 (Memory Providers)](./memory-providers.md) 系統中。以下所有功能均可透過統一的記憶提供者介面使用。
:::

## Honcho 增加的功能

| 能力 | 內建記憶 | Honcho |
|-----------|----------------|--------|
| 跨會話持久性 | ✔ 基於檔案的 MEMORY.md/USER.md | ✔ 具備 API 的伺服器端存儲 |
| 使用者設定檔 | ✔ 代理程式手動管理 | ✔ 自動辯證式推理 |
| 多代理隔離 | — | ✔ 每個對等端 (peer) 獨立設定檔 |
| 觀察模式 | — | ✔ 統一或定向觀察 |
| 結論 (派生洞察) | — | ✔ 針對模式進行伺服器端推理 |
| 跨歷史搜尋 | ✔ FTS5 會話搜尋 | ✔ 針對結論進行語義搜尋 |

**辯證式推理 (Dialectic reasoning)**：在每次對話後，Honcho 會分析交流過程並得出「結論 (conclusions)」— 關於使用者的偏好、習慣和目標的見解。這些結論會隨時間累積，使代理程式對使用者的理解不僅限於使用者明確表達的內容，而有更深層的認知。

**多代理設定檔 (Multi-agent profiles)**：當多個 Hermes 實例與同一個使用者交談時（例如：程式碼助理和個人助理），Honcho 會維護獨立的「對等端 (peer)」設定檔。每個對等端只能看到自己的觀察結果和結論，防止上下文交叉污染。

## 設定

```bash
hermes memory setup    # 從提供者清單中選擇 "honcho"
```

或手動配置：

```yaml
# ~/.hermes/config.yaml
memory:
  provider: honcho
```

```bash
echo "HONCHO_API_KEY=your-key" >> ~/.hermes/.env
```

請在 [honcho.dev](https://honcho.dev) 獲取 API 金鑰。

## 配置選項

```yaml
# ~/.hermes/config.yaml
honcho:
  observation: directional    # "unified" (新安裝的預設值) 或 "directional"
  peer_name: ""               # 從平台自動偵測，或手動設置
```

**觀察模式 (Observation modes):**
- `unified` — 所有觀察結果都進入單個池中。較簡單，適合單代理設置。
- `directional` — 觀察結果標註有方向（使用者→代理程式，代理程式→使用者）。可實現更豐富的對話動態分析。

## 工具

當 Honcho 作為活動中的記憶提供者時，會有四個額外的工具可用：

| 工具 | 用途 |
|------|---------|
| `honcho_conclude` | 觸發伺服器端對近期對話進行辯證式推理 |
| `honcho_context` | 從 Honcho 的記憶中檢索與目前對話相關的上下文 |
| `honcho_profile` | 查看或更新使用者的 Honcho 設定檔 |
| `honcho_search` | 針對所有存儲的結論和觀察結果進行語義搜尋 |

## CLI 指令

```bash
hermes honcho status          # 顯示連線狀態與配置
hermes honcho peer            # 為多代理設置更新對等端名稱
```

## 從 `hermes honcho` 遷移

如果您之前使用的是獨立的 `hermes honcho setup`：

1. 您現有的配置（`honcho.json` 或 `~/.honcho/config.json`）將被保留
2. 您的伺服器端數據（記憶、結論、使用者設定檔）保持不變
3. 在 config.yaml 中設置 `memory.provider: honcho` 以重新啟用

不需要重新登入或重新設定。執行 `hermes memory setup` 並選擇 "honcho" — 設定精靈會自動偵測您現有的配置。

## 完整文件

請參閱 [記憶提供者 — Honcho](./memory-providers.md#honcho) 以獲取完整參考。
