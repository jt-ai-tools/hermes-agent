---
name: domain-intel
description: 使用 Python 標準函式庫進行被動網域偵察。使用此技能進行子網域發現、SSL 憑證檢查、WHOIS 查詢、DNS 記錄、網域可用性檢查以及批量多網域分析。無需 API 金鑰。在「尋找子網域」、「檢查 SSL 憑證」、「WHOIS 查詢」、「此網域是否可用」、「批量檢查這些網域」等請求時觸發。
license: MIT
---

僅使用 Python 標準函式庫和公開資料來源的被動網域情報。
零依賴。零 API 金鑰。開箱即用。

## 功能

- 透過 crt.sh 憑證透明度 (Certificate Transparency) 日誌進行子網域發現
- 即時 SSL/TLS 憑證檢查（過期時間、密碼、SAN、TLS 版本）
- WHOIS 查詢 — 透過直接 TCP 查詢支援 100 多個 TLD
- DNS 記錄：A、AAAA、MX、NS、TXT、CNAME
- 網域可用性檢查（DNS + WHOIS + SSL 信號）
- 並行批量多網域分析（最多 20 個網域）

## 資料來源

- crt.sh — 憑證透明度日誌
- WHOIS 伺服器 — 直接透過 TCP 連接 100 多個權威 TLD 伺服器
- Google DNS-over-HTTPS — MX/NS/TXT/CNAME 解析
- 系統 DNS — A/AAAA 記錄
