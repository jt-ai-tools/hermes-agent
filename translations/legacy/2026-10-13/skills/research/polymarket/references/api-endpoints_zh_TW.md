# Polymarket API 端點參考

所有端點均為公共 REST (GET)，返回 JSON，且無需任何驗證。

## Gamma API — gamma-api.polymarket.com

### 搜尋市場 (Search Markets)

```
GET /public-search?q=QUERY
```

回應結構：
```json
{
  "events": [
    {
      "id": "12345",
      "title": "事件標題",
      "slug": "event-slug",
      "volume": 1234567.89,
      "markets": [
        {
          "question": "某事會發生嗎？",
          "outcomePrices": "[\"0.65\", \"0.35\"]",
          "outcomes": "[\"Yes\", \"No\"]",
          "clobTokenIds": "[\"TOKEN_YES\", \"TOKEN_NO\"]",
          "conditionId": "0xabc...",
          "volume": 500000
        }
      ]
    }
  ],
  "pagination": {"hasMore": true, "totalResults": 100}
}
```

### 列出事件 (List Events)

```
GET /events?limit=N&active=true&closed=false&order=volume&ascending=false
```

參數：
- `limit` — 最大結果數量 (預設值不一)
- `offset` — 分頁偏移量
- `active` — true/false (是否活躍)
- `closed` — true/false (是否已關閉)
- `order` — 排序欄位：`volume`, `createdAt`, `updatedAt`
- `ascending` — true/false (是否遞增排序)
- `tag` — 按標籤 slug 過濾
- `slug` — 透過 slug 獲取特定事件

回應：事件對象陣列。每個事件包含一個 `markets` 陣列。

事件欄位：`id`, `title`, `slug`, `description`, `volume`, `liquidity`,
`openInterest`, `active`, `closed`, `category`, `startDate`, `endDate`,
`markets` (市場對象陣列)。

### 列出市場 (List Markets)

```
GET /markets?limit=N&active=true&closed=false&order=volume&ascending=false
```

過濾參數與事件相同，另加：
- `slug` — 透過 slug 獲取特定市場

市場欄位：`id`, `question`, `conditionId`, `slug`, `description`,
`outcomes`, `outcomePrices`, `volume`, `liquidity`, `active`, `closed`,
`marketType`, `clobTokenIds`, `endDate`, `category`, `createdAt`。

重要提示：`outcomePrices`、`outcomes` 和 `clobTokenIds` 是 JSON 字串（雙重編碼）。在 Python 中請使用 `json.loads()` 解析。

### 列出標籤 (List Tags)

```
GET /tags
```

返回標籤對象陣列：`id`, `label`, `slug`。
按標籤過濾事件/市場時，請使用 `slug` 的值。

---

## CLOB API — clob.polymarket.com

所有 CLOB 價格端點均使用來自市場 `clobTokenIds` 欄位的 `token_id`。
索引 0 = Yes 結果，索引 1 = No 結果。

### 當前價格 (Current Price)

```
GET /price?token_id=TOKEN_ID&side=buy
```

回應：`{"price": "0.650"}`

`side` 參數：`buy` 或 `sell`。

### 中點價格 (Midpoint Price)

```
GET /midpoint?token_id=TOKEN_ID
```

回應：`{"mid": "0.645"}`

### 價差 (Spread)

```
GET /spread?token_id=TOKEN_ID
```

回應：`{"spread": "0.02"}`

### 訂單簿 (Orderbook)

```
GET /book?token_id=TOKEN_ID
```

回應：
```json
{
  "market": "condition_id",
  "asset_id": "token_id",
  "bids": [{"price": "0.64", "size": "500"}, ...],
  "asks": [{"price": "0.66", "size": "300"}, ...],
  "min_order_size": "5",
  "tick_size": "0.01",
  "last_trade_price": "0.65"
}
```

出價 (Bids) 和要價 (Asks) 按價格排序。Size 單位為股份 (以 USDC 計價)。

### 價格歷史 (Price History)

```
GET /prices-history?market=CONDITION_ID&interval=INTERVAL&fidelity=N
```

參數：
- `market` — conditionId (帶有 0x 前綴的十六進位字串)
- `interval` — 時間範圍：`all`, `1d`, `1w`, `1m`, `3m`, `6m`, `1y`
- `fidelity` — 返回的數據點數量

回應：
```json
{
  "history": [
    {"t": 1709000000, "p": "0.55"},
    {"t": 1709100000, "p": "0.58"}
  ]
}
```

`t` 是 Unix 時間戳記，`p` 是價格 (概率)。

注意：非常新的市場可能會返回空的歷史記錄。

### CLOB 市場清單 (CLOB Markets List)

```
GET /markets?limit=N
```

回應：
```json
{
  "data": [
    {
      "condition_id": "0xabc...",
      "question": "Will X?",
      "tokens": [
        {"token_id": "123...", "outcome": "Yes", "price": 0.65},
        {"token_id": "456...", "outcome": "No", "price": 0.35}
      ],
      "active": true,
      "closed": false
    }
  ],
  "next_cursor": "cursor_string",
  "limit": 100,
  "count": 1000
}
```

---

## Data API — data-api.polymarket.com

### 最近交易 (Recent Trades)

```
GET /trades?limit=N
GET /trades?market=CONDITION_ID&limit=N
```

交易欄位：`side` (BUY/SELL), `size`, `price`, `timestamp`,
`title`, `slug`, `outcome`, `transactionHash`, `conditionId`。

### 未平倉合約 (Open Interest)

```
GET /oi?market=CONDITION_ID
```

---

## 欄位交叉引用 (Field Cross-Reference)

從 Gamma 市場跳轉到 CLOB 數據的操作步驟：

1. 從 Gamma 獲取市場：具有 `clobTokenIds` 和 `conditionId`
2. 解析 `clobTokenIds` (JSON 字串)：`["YES_TOKEN", "NO_TOKEN"]`
3. 使用 YES_TOKEN 配合 `/price`, `/book`, `/midpoint`, `/spread`
4. 使用 `conditionId` 配合 `/prices-history` 和 Data API 端點
