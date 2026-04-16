# 惡意套件調查報告

---

## 📦 套件元數據 (Metadata)
- **套件名稱**: 
- **註冊表 (Registry)**: [NPM / PyPI / RubyGems / 等]
- **受影響版本**: 
- **惡意版本**: 
- **偵測時的下載量**: 
- **套件 URL**: 

---

## 🚩 入侵指標 (IOCs)
- **惡意 URL**: 
- **外洩資料類型**: [環境變數, ~/.ssh/id_rsa, /etc/shadow, 等]
- **外洩方法**: [DNS 隧道 (DNS tunneling), HTTP POST 傳送至 C2, 等]
- **C2 IP/網域**: 

---

## 🛠️ 分析摘要
- **主要機制**: [拼寫錯誤劫持 (Typosquatting) / 依賴混淆 (Dependency Confusion) / 維護者帳號遭劫持]
- **行為描述**: 
  - [範例：安裝後執行腳本 (postinstall script)，將環境變數外洩。]
  - [範例：修改 `setup.py` 以下載二次載荷 (secondary payload)。]

---

## 🔍 證據登記簿
| 證據 ID | 類型 | 來源 | 描述 |
|-------------|------|--------|-------------|
| EV-XXXX     | ioc  | NPM    | 套件安裝腳本快照 |
| EV-YYYY     | web  | Wayback| 歷史版本比較 |

---

## 🛡️ 建議緩解措施
1. [ ] 從註冊表中撤銷發布/檢舉該套件。
2. [ ] 稽核所有專案中的 `package-lock.json` 或 `requirements.txt`。
3. [ ] 更換透過環境變數外洩的機密資訊 (Secrets)。
4. [ ] 為關鍵任務的依賴項鎖定特定的雜湊值 (SHASUM)。
