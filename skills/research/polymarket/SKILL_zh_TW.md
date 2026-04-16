---
name: polymarket
description: 查詢 Polymarket 預測市場數據 —— 搜尋市場、獲取價格、訂單簿和價格歷史。透過公共 REST API 進行唯讀存取，無需 API key。
version: 1.0.0
author: Hermes Agent + Teknium
tags: [polymarket, 預測市場, 市場數據, 交易]
---

# Polymarket — 預測市場數據

使用 Polymarket 的公共 REST API 查詢其預測市場數據。
所有端點均為唯讀，且無需任何驗證。

請參閱 [references/api-endpoints_zh_TW.md](references/api-endpoints_zh_TW.md) 以獲取完整的端點參考和 curl 範例。

## 何時使用

- 使用者詢問有關預測市場、投注賠率或事件概率的問題時
- 使用者想知道「某事發生的機率是多少？」時
- 使用者專門詢問有關 Polymarket 的資訊時
- 使用者想要獲取市場價格、訂單簿數據或價格歷史時
- 使用者要求監測或追蹤預測市場的動向時

## 核心概念

- **事件 (Events)** 包含一個或多個 **市場 (Markets)** (1:多 關係)
- **市場 (Markets)** 是二元結果，其 Yes/No 價格介於 0.00 到 1.00 之間
- 價格即為概率：價格 0.65 意味著市場認為發生的可能性為 65%
- `outcomePrices` 欄位：JSON 編碼的陣列，例如 `["0.80", "0.20"]`
- `clobTokenIds` 欄位：JSON 編碼的兩個代幣 ID 陣列 [Yes, No]，用於價格/訂單簿查詢
- `conditionId` 欄位：十六進位字串，用於價格歷史查詢
- 成交量以 USDC (美元) 為單位

## 三個公共 API

1. **Gamma API** (網址為 `gamma-api.polymarket.com`) —— 發現、搜尋、瀏覽
2. **CLOB API** (網址為 `clob.polymarket.com`) —— 即時價格、訂單簿、歷史記錄
3. **Data API** (網址為 `data-api.polymarket.com`) —— 交易、未平倉合約 (open interest)

## 典型工作流

當使用者詢問預測市場賠率時：

1. **搜尋**：使用 Gamma API 的 `public-search` 端點進行查詢
2. **解析**：解析回應內容 —— 提取事件及其嵌套的市場
3. **呈現**：呈現市場問題、當前價格（以百分比表示）以及成交量
4. **深入研究**（如有要求）：使用 `clobTokenIds` 獲取訂單簿，使用 `conditionId` 獲取歷史記錄

## 呈現結果

為了提高可讀性，請將價格格式化為百分比：
- `outcomePrices` 為 `["0.652", "0.348"]` 時，呈現為 "Yes: 65.2%, No: 34.8%"
- 始終顯示市場問題和概率
- 如果可用，請包含成交量

範例：`"Will X happen?" — 65.2% Yes ($1.2M volume)`

## 解析雙重編碼欄位 (Double-Encoded Fields)

Gamma API 在 JSON 回應中將 `outcomePrices`、`outcomes` 和 `clobTokenIds` 以 JSON 字串的形式返回（雙重編碼）。使用 Python 處理時，請使用 `json.loads(market['outcomePrices'])` 來獲取實際陣列。

## 速率限制 (Rate Limits)

非常寬鬆 —— 正常使用不太可能觸及：
- Gamma：每 10 秒 4,000 次請求 (通用)
- CLOB：每 10 秒 9,000 次請求 (通用)
- Data：每 10 秒 1,000 次請求 (通用)

## 局限性

- 此技能為唯讀 —— 不支持進行交易
- 交易需要基於錢包的加密驗證 (EIP-712 簽章)
- 某些新市場的價格歷史記錄可能為空
- 交易功能受地理位置限制，但唯讀數據可全球存取
