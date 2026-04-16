---
name: solana
description: 查詢 Solana 區塊鏈數據並包含美元定價 — 錢包餘額、帶有價值的代幣投資組合、交易詳情、NFT、巨鯨檢測和即時網絡統計。使用 Solana RPC + CoinGecko。無需 API 金鑰。
version: 0.2.0
author: Deniz Alagoz (gizdusum), 由 Hermes Agent 強化
license: MIT
metadata:
  hermes:
    tags: [Solana, Blockchain, Crypto, Web3, RPC, DeFi, NFT]
    related_skills: []
---

# Solana 區塊鏈技能

查詢 Solana 鏈上數據，並透過 CoinGecko 強化美元 (USD) 定價資訊。
提供 8 個指令：錢包投資組合、代幣資訊、交易、活動、NFT、巨鯨檢測、網絡統計和價格查詢。

無需 API 金鑰。僅使用 Python 標準庫 (urllib, json, argparse)。

---

## 何時使用

- 用戶詢問 Solana 錢包餘額、持有的代幣或投資組合價值。
- 用戶想要透過簽名 (Signature) 檢查特定交易。
- 用戶想要獲取 SPL 代幣的元數據、價格、供應量或持幣大戶。
- 用戶想要獲取地址的近期交易歷史。
- 用戶想要獲取錢包擁有的 NFT。
- 用戶想要尋找大型 SOL 轉帳（巨鯨檢測）。
- 用戶想要獲取 Solana 網絡健康狀況、TPS、紀元 (Epoch) 或 SOL 價格。
- 用戶詢問 "BONK/JUP/SOL 的價格是多少？"

---

## 前置要求

輔助腳本僅使用 Python 標準庫 (urllib, json, argparse)，無需安裝外部套件。

價格數據來自 CoinGecko 的免費 API（無需金鑰，速率限制約為每分鐘 10-30 次請求）。若需更快的查詢速度，請使用 `--no-prices` 標記。

---

## 快速參考

RPC 端點 (預設): https://api.mainnet-beta.solana.com
覆蓋設定: export SOLANA_RPC_URL=https://your-private-rpc.com

輔助腳本路徑: ~/.hermes/skills/blockchain/solana/scripts/solana_client.py

```
python3 solana_client.py wallet   <address> [--limit N] [--all] [--no-prices]
python3 solana_client.py tx       <signature>
python3 solana_client.py token    <mint_address>
python3 solana_client.py activity <address> [--limit N]
python3 solana_client.py nft      <address>
python3 solana_client.py whales   [--min-sol N]
python3 solana_client.py stats
python3 solana_client.py price    <mint_or_symbol>
```

---

## 程序

### 0. 設定檢查

```bash
python3 --version

# 可選：設置私有 RPC 以獲得更好的速率限制
export SOLANA_RPC_URL="https://api.mainnet-beta.solana.com"

# 確認連線性
python3 ~/.hermes/skills/blockchain/solana/scripts/solana_client.py stats
```

### 1. 錢包投資組合

獲取 SOL 餘額、帶有美元價值的 SPL 代幣持有量、NFT 數量以及投資組合總額。代幣按價值排序，過濾微量餘額 (Dust)，已知代幣會標註名稱（如 BONK, JUP, USDC 等）。

```bash
python3 ~/.hermes/skills/blockchain/solana/scripts/solana_client.py \
  wallet 9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM
```

標記：
- `--limit N` — 顯示前 N 個代幣（預設：20）
- `--all` — 顯示所有代幣，不過濾微量餘額，無數量限制
- `--no-prices` — 跳過 CoinGecko 價格查詢（速度更快，僅使用 RPC）

輸出包含：SOL 餘額 + 美元價值、按價值排序的代幣列表與價格、微量餘額數量、NFT 摘要、總投資組合美元價值。

### 2. 交易詳情

透過 base58 簽名檢查完整交易。顯示 SOL 和美元價值的餘額變化。

```bash
python3 ~/.hermes/skills/blockchain/solana/scripts/solana_client.py \
  tx 5j7s8K...your_signature_here
```

輸出：槽位 (Slot)、時間戳記、費用、狀態、餘額變化 (SOL + USD)、程式呼叫 (Program Invocations)。

### 3. 代幣資訊

獲取 SPL 代幣元數據、當前價格、市值、供應量、小數位數、鑄幣/凍結權限以及前 5 大持有者。

```bash
python3 ~/.hermes/skills/blockchain/solana/scripts/solana_client.py \
  token DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263
```

輸出：名稱、符號、小數位數、供應量、價格、市值、前 5 大持有者及其持股比例。

### 4. 近期活動

列出地址的近期交易（預設：最後 10 筆，最大：25 筆）。

```bash
python3 ~/.hermes/skills/blockchain/solana/scripts/solana_client.py \
  activity 9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM --limit 25
```

### 5. NFT 投資組合

列出錢包擁有的 NFT（啟發式判斷：數量=1 且小數位數=0 的 SPL 代幣）。

```bash
python3 ~/.hermes/skills/blockchain/solana/scripts/solana_client.py \
  nft 9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM
```

注意：此啟發式方法無法檢測壓縮型 NFT (cNFTs)。

### 6. 巨鯨檢測器

掃描最近一個區塊中帶有美元價值的大額 SOL 轉帳。

```bash
python3 ~/.hermes/skills/blockchain/solana/scripts/solana_client.py \
  whales --min-sol 500
```

注意：僅掃描最新區塊 —— 為特定時間點的快照，非歷史記錄。

### 7. 網絡統計

即時 Solana 網絡健康狀況：當前槽位、紀元、TPS、供應量、驗證者版本、SOL 價格和市值。

```bash
python3 ~/.hermes/skills/blockchain/solana/scripts/solana_client.py stats
```

### 8. 價格查詢

透過鑄幣地址 (Mint Address) 或已知符號快速檢查任何代幣的價格。

```bash
python3 ~/.hermes/skills/blockchain/solana/scripts/solana_client.py price BONK
python3 ~/.hermes/skills/blockchain/solana/scripts/solana_client.py price JUP
python3 ~/.hermes/skills/blockchain/solana/scripts/solana_client.py price SOL
python3 ~/.hermes/skills/blockchain/solana/scripts/solana_client.py price DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263
```

已知符號：SOL, USDC, USDT, BONK, JUP, WETH, JTO, mSOL, stSOL, PYTH, HNT, RNDR, WEN, W, TNSR, DRIFT, bSOL, JLP, WIF, MEW, BOME, PENGU。

---

## 陷阱

- **CoinGecko 速率限制** — 免費方案允許每分鐘約 10-30 次請求。每次代幣價格查詢消耗 1 次請求。擁有眾多代幣的錢包可能無法獲取所有代幣的價格。使用 `--no-prices` 可提高速度。
- **公共 RPC 速率限制** — Solana 主網公共 RPC 限制請求。對於生產用途，請將 `SOLANA_RPC_URL` 設置為私有端點 (Helius, QuickNode, Triton)。
- **NFT 檢測為啟發式** — 依據數量=1 + 小數位數=0。壓縮型 NFT (cNFTs) 和 Token-2022 NFT 不會出現。
- **巨鯨檢測器僅掃描最新區塊** — 非歷史記錄。
- **交易歷史** — 公共 RPC 約保留 2 天數據。較舊的交易可能無法獲取。
- **代幣名稱** — 約有 25 種知名代幣標有名稱，其餘顯示縮寫的鑄幣地址。使用 `token` 指令獲取完整資訊。
- **429 錯誤重試** — 遇到速率限制錯誤時，RPC 和 CoinGecko 呼叫皆會使用指數退避進行最多 2 次重試。

---

## 驗證

```bash
# 應打印出當前 Solana 槽位、TPS 和 SOL 價格
python3 ~/.hermes/skills/blockchain/solana/scripts/solana_client.py stats
```
