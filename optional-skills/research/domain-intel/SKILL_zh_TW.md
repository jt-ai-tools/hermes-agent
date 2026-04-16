---
name: domain-intel
description: 使用 Python 標準函式庫進行被動式網域偵查。包含子網域發現、SSL 憑證檢查、WHOIS 查詢、DNS 紀錄、網域可用性檢查以及批量多網域分析。無需 API 金鑰。
---

# 網域情報 (Domain Intelligence) — 被動式 OSINT

僅使用 Python 標準函式庫進行被動式網域偵查。
**零依賴。零 API 金鑰。適用於 Linux、macOS 和 Windows。**

## 輔助腳本

此技能包含 `scripts/domain_intel.py` — 一個用於所有網域情報操作的完整 CLI 工具。

```bash
# 透過憑證透明度 (Certificate Transparency) 日誌發現子網域
python3 SKILL_DIR/scripts/domain_intel.py subdomains example.com

# SSL 憑證檢查（過期時間、密碼、SAN、發行者）
python3 SKILL_DIR/scripts/domain_intel.py ssl example.com

# WHOIS 查詢（註冊商、日期、名稱伺服器 — 支援 100 多種 TLD）
python3 SKILL_DIR/scripts/domain_intel.py whois example.com

# DNS 紀錄 (A, AAAA, MX, NS, TXT, CNAME)
python3 SKILL_DIR/scripts/domain_intel.py dns example.com

# 網域可用性檢查（被動式：DNS + WHOIS + SSL 信號）
python3 SKILL_DIR/scripts/domain_intel.py available coolstartup.io

# 批量分析 — 並行對多個網域進行多項檢查
python3 SKILL_DIR/scripts/domain_intel.py bulk example.com github.com google.com
python3 SKILL_DIR/scripts/domain_intel.py bulk example.com github.com --checks ssl,dns
```

`SKILL_DIR` 是包含此 SKILL.md 檔案的目錄。所有輸出均為結構化 JSON。

## 可用指令

| 指令 | 用途 | 數據來源 |
|---------|-------------|-------------|
| `subdomains` | 從憑證日誌中尋找子網域 | crt.sh (HTTPS) |
| `ssl` | 檢查 TLS 憑證詳情 | 直接向目標發起 TCP:443 連線 |
| `whois` | 註冊資訊、註冊商、日期 | WHOIS 伺服器 (TCP:43) |
| `dns` | A, AAAA, MX, NS, TXT, CNAME 紀錄 | 系統 DNS + Google DoH |
| `available` | 檢查網域是否已註冊 | DNS + WHOIS + SSL 信號 |
| `bulk` | 對多個網域執行多項檢查 | 以上所有來源 |

## 何時使用此技能 vs 內建工具

- **使用此技能**：處理基礎設施問題：子網域、SSL 憑證、WHOIS、DNS 紀錄、可用性
- **使用 `web_search`**：進行關於網域/公司業務的一般性研究
- **使用 `web_extract`**：獲取網頁的實際內容
- **使用 `terminal` 搭配 `curl -I`**：進行簡單的「此 URL 是否可連通」檢查

| 任務 | 較佳工具 | 原因 |
|------|-------------|-----|
| 「example.com 是做什麼的？」 | `web_extract` | 獲取頁面內容，而非 DNS/WHOIS 數據 |
| 「尋找關於某公司的資訊」 | `web_search` | 一般性研究，而非網域特定資訊 |
| 「這個網站安全嗎？」 | `web_search` | 信譽檢查需要網頁內容背景 |
| 「檢查某 URL 是否可連通」 | `terminal` (curl -I) | 簡單的 HTTP 檢查 |
| 「尋找 X 的子網域」 | **此技能** | 唯一的被動來源 |
| 「SSL 憑證何時過期？」 | **此技能** | 內建工具無法檢查 TLS |
| 「誰註冊了這個網域？」 | **此技能** | 網頁搜尋中不含 WHOIS 數據 |
| 「coolstartup.io 可註冊嗎？」 | **此技能** | 透過 DNS+WHOIS+SSL 進行被動可用性檢查 |

## 平台相容性

純 Python 標準函式庫 (`socket`, `ssl`, `urllib`, `json`, `concurrent.futures`)。
在 Linux、macOS 和 Windows 上運作一致，無需額外依賴。

- **crt.sh 查詢**：使用 HTTPS (連接埠 443) — 可穿透大多數防火牆
- **WHOIS 查詢**：使用 TCP 連接埠 43 — 在限制較嚴格的網路上可能會被封鎖
- **DNS 查詢**：使用 Google DoH (HTTPS) 獲取 MX/NS/TXT — 防火牆友善
- **SSL 檢查**：連線至目標的連接埠 443 — 這是唯一一項「主動」操作

## 數據來源

所有查詢均為**被動式** — 無連接埠掃描，無漏洞測試：

- **crt.sh** — 憑證透明度日誌（子網域發現，僅限 HTTPS）
- **WHOIS 伺服器** — 直接 TCP 連線至 100 多個權威 TLD 註冊商
- **Google DNS-over-HTTPS** — MX, NS, TXT, CNAME 解析（防火牆友善）
- **系統 DNS** — A/AAAA 紀錄解析
- **SSL 檢查** — 唯一一項「主動」操作（向目標:443 發起 TCP 連線）

## 備註

- WHOIS 查詢使用 TCP 連接埠 43 — 在限制較嚴格的網路上可能會被封鎖。
- 某些 WHOIS 伺服器會遮蔽註冊人資訊 (GDPR) — 請向使用者說明此點。
- crt.sh 對於非常熱門的網域（數千張憑證）可能反應較慢 — 請設定合理的預期。
- 可用性檢查是基於啟發式 (Heuristic) 的（3 種被動信號）— 並非像註冊商 API 那樣具備權威性。

---

*貢獻者：[@FurkanL0](https://github.com/FurkanL0)*
