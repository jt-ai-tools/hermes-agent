---
name: base
description: 查詢 Base (Ethereum L2) 區塊鏈數據並包含美元定價 — 錢包餘額、代幣資訊、交易詳情、Gas 分析、合約檢查、巨鯨檢測和即時網絡統計。使用 Base RPC + CoinGecko。無需 API 金鑰。
version: 0.1.0
author: youssefea
license: MIT
metadata:
  hermes:
    tags: [Base, Blockchain, Crypto, Web3, RPC, DeFi, EVM, L2, Ethereum]
    related_skills: []
---

# Base 區塊鏈技能

查詢 Base (Ethereum L2) 鏈上數據，並透過 CoinGecko 強化美元 (USD) 定價資訊。
提供 8 個指令：錢包投資組合、代幣資訊、交易、Gas 分析、合約檢查、巨鯨檢測、網絡統計和價格查詢。

無需 API 金鑰。僅使用 Python 標準庫 (urllib, json, argparse)。

---

## 何時使用

- 用戶詢問 Base 錢包餘額、持有的代幣或投資組合價值。
- 用戶想要透過雜湊 (Hash) 檢查特定交易。
- 用戶想要獲取 ERC-20 代幣的元數據、價格、供應量或市值。
- 用戶想要了解 Base 的 Gas 成本和 L1 數據費用。
- 用戶想要檢查合約（ERC 類型檢測、代理指向解析）。
- 用戶想要尋找大型 ETH 轉帳（巨鯨檢測）。
- 用戶想要獲取 Base 網絡健康狀況、Gas 價格或 ETH 價格。
- 用戶詢問 "USDC/AERO/DEGEN/ETH 的價格是多少？"

---

## 前置要求

輔助腳本僅使用 Python 標準庫 (urllib, json, argparse)，無需安裝外部套件。

價格數據來自 CoinGecko 的免費 API（無需金鑰，速率限制約為每分鐘 10-30 次請求）。若需更快的查詢速度，請使用 `--no-prices` 標記。

---

## 快速參考

RPC 端點 (預設): https://mainnet.base.org
覆蓋設定: export BASE_RPC_URL=https://your-private-rpc.com

輔助腳本路徑: ~/.hermes/skills/blockchain/base/scripts/base_client.py

```
python3 base_client.py wallet   <address> [--limit N] [--all] [--no-prices]
python3 base_client.py tx       <hash>
python3 base_client.py token    <contract_address>
python3 base_client.py gas
python3 base_client.py contract <address>
python3 base_client.py whales   [--min-eth N]
python3 base_client.py stats
python3 base_client.py price    <contract_address_or_symbol>
```

---

## 程序

### 0. 設定檢查

```bash
python3 --version

# 可選：設置私有 RPC 以獲得更好的速率限制
export BASE_RPC_URL="https://mainnet.base.org"

# 確認連線性
python3 ~/.hermes/skills/blockchain/base/scripts/base_client.py stats
```

### 1. 錢包投資組合

獲取 ETH 餘額和帶有美元價值的 ERC-20 代幣持有量。
透過鏈上 `balanceOf` 呼叫檢查約 15 種知名的 Base 代幣（USDC, WETH, AERO, DEGEN 等）。代幣按價值排序，並過濾微量餘額 (Dust)。

```bash
python3 ~/.hermes/skills/blockchain/base/scripts/base_client.py \
  wallet 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045
```

標記：
- `--limit N` — 顯示前 N 個代幣（預設：20）
- `--all` — 顯示所有代幣，不過濾微量餘額，無數量限制
- `--no-prices` — 跳過 CoinGecko 價格查詢（速度更快，僅使用 RPC）

輸出包含：ETH 餘額 + 美元價值、按價值排序的代幣列表與價格、微量餘額數量、總投資組合美元價值。

注意：僅檢查已知代幣。無法發現未知的 ERC-20 代幣。對於任何特定代幣，請使用 `token` 指令配合合約地址。

### 2. 交易詳情

透過交易雜湊檢查完整交易。顯示轉帳的 ETH 價值、使用的 Gas、以 ETH/USD 計價的費用、狀態，以及解碼後的 ERC-20/ERC-721 轉帳。

```bash
python3 ~/.hermes/skills/blockchain/base/scripts/base_client.py \
  tx 0xabc123...your_tx_hash_here
```

輸出：雜湊、區塊、發送方、接收方、價值 (ETH + USD)、Gas 價格、已用 Gas、費用、狀態、合約建立地址（如有）、代幣轉帳。

### 3. 代幣資訊

獲取 ERC-20 代幣元數據：名稱、符號、小數位數、總供應量、價格、市值及合約代碼大小。

```bash
python3 ~/.hermes/skills/blockchain/base/scripts/base_client.py \
  token 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
```

輸出：名稱、符號、小數位數、總供應量、價格、市值。
透過 `eth_call` 直接從合約讀取名稱/符號/小數位數。

### 4. Gas 分析

包含常用操作成本預算的詳細 Gas 分析。顯示當前 Gas 價格、過去 10 個區塊的基礎費用 (Base Fee) 趨勢、區塊利用率，以及 ETH 轉帳、ERC-20 轉帳和交換 (Swap) 的預估成本。

```bash
python3 ~/.hermes/skills/blockchain/base/scripts/base_client.py gas
```

輸出：當前 Gas 價格、基礎費用、區塊利用率、10 區塊趨勢、以 ETH 和 USD 計價的預估成本。

注意：Base 是 L2 網絡 —— 實際交易成本包含 L1 數據發佈費，這取決於 Call Data 大小和 L1 Gas 價格。此處顯示的預估僅針對 L2 執行部分。

### 5. 合約檢查

檢查一個地址：判斷其為外部帳戶 (EOA) 還是合約、檢測 ERC-20/ERC-721/ERC-1155 介面、解析 EIP-1967 代理實作地址。

```bash
python3 ~/.hermes/skills/blockchain/base/scripts/base_client.py \
  contract 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
```

輸出：是否為合約、代碼大小、ETH 餘額、檢測到的介面 (ERC-20, ERC-721, ERC-1155)、ERC-20 元數據、代理實作地址。

### 6. 巨鯨檢測器

掃描最近一個區塊中帶有美元價值的大額 ETH 轉帳。

```bash
python3 ~/.hermes/skills/blockchain/base/scripts/base_client.py \
  whales --min-eth 1.0
```

注意：僅掃描最新區塊 —— 為特定時間點的快照，非歷史記錄。預設門檻為 1.0 ETH（低於 Solana 的預設值，因為 ETH 價值較高）。

### 7. 網絡統計

即時 Base 網絡健康狀況：最新區塊、鏈 ID (Chain ID)、Gas 價格、基礎費用、區塊利用率、交易數量和 ETH 價格。

```bash
python3 ~/.hermes/skills/blockchain/base/scripts/base_client.py stats
```

### 8. 價格查詢

透過合約地址或已知符號快速檢查任何代幣的價格。

```bash
python3 ~/.hermes/skills/blockchain/base/scripts/base_client.py price ETH
python3 ~/.hermes/skills/blockchain/base/scripts/base_client.py price USDC
python3 ~/.hermes/skills/blockchain/base/scripts/base_client.py price AERO
python3 ~/.hermes/skills/blockchain/base/scripts/base_client.py price DEGEN
python3 ~/.hermes/skills/blockchain/base/scripts/base_client.py price 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
```

已知符號：ETH, WETH, USDC, cbETH, AERO, DEGEN, TOSHI, BRETT, WELL, wstETH, rETH, cbBTC。

---

## 陷阱

- **CoinGecko 速率限制** — 免費方案允許每分鐘約 10-30 次請求。每次代幣價格查詢消耗 1 次請求。使用 `--no-prices` 可提高速度。
- **公共 RPC 速率限制** — Base 的公共 RPC 限制請求。對於生產用途，請將 `BASE_RPC_URL` 設置為私有端點 (Alchemy, QuickNode, Infura)。
- **錢包僅顯示已知代幣** — 與 Solana 不同，EVM 鏈沒有內建的 "獲取所有代幣" RPC。錢包指令透過 `balanceOf` 檢查約 15 種熱門 Base 代幣。未知的 ERC-20 不會出現。對於特定合約，請使用 `token` 指令。
- **從合約讀取代幣名稱** — 如果合約未實作 `name()` 或 `symbol()`，這些欄位可能為空。已知代幣有硬編碼標籤作為備份。
- **Gas 預估僅限 L2** — Base 交易成本包含 L1 數據發佈費（取決於 Call Data 大小和 L1 Gas 價格）。Gas 指令僅預估 L2 執行成本。
- **巨鯨檢測器僅掃描最新區塊** — 非歷史記錄。結果取決於您查詢的時刻。預設門檻為 1.0 ETH。
- **代理檢測** — 僅檢測 EIP-1967 代理。不檢查其他代理模式（EIP-1167 最小代理、自定義存儲槽）。
- **429 錯誤重試** — 遇到速率限制錯誤時，RPC 和 CoinGecko 呼叫皆會使用指數退避進行最多 2 次重試。

---

## 驗證

```bash
# 應打印出 Base 鏈 ID (8453)、最新區塊、Gas 價格和 ETH 價格
python3 ~/.hermes/skills/blockchain/base/scripts/base_client.py stats
```
