---
name: sherlock
description: 在 400 多個社群網路中進行 OSINT 使用者名稱搜尋。透過使用者名稱追蹤社群媒體帳號。
version: 1.0.0
author: unmodeled-tyler
license: MIT
metadata:
  hermes:
    tags: [osint, 安全, 使用者名稱, 社群媒體, 偵查]
    category: 安全
prerequisites:
  commands: [sherlock]
---

# Sherlock OSINT 使用者名稱搜尋

使用 [Sherlock 專案](https://github.com/sherlock-project/sherlock) 在 400 多個社群網路中透過使用者名稱追蹤社群媒體帳號。

## 何時使用

- 使用者要求尋找與某個使用者名稱關聯的帳號。
- 使用者想要檢查跨平台的使用者名稱可用性。
- 使用者正在進行 OSINT 或偵查研究。
- 使用者詢問「這個使用者名稱是在哪裡註冊的？」或類似問題。

## 需求

- 已安裝 Sherlock CLI：`pipx install sherlock-project` 或 `pip install sherlock-project`
- 或者：可使用 Docker (`docker run -it --rm sherlock/sherlock`)
- 具有查詢社群平台的網路存取權限。

## 程序

### 1. 檢查是否已安裝 Sherlock

**在執行其他任何操作之前**，請驗證 sherlock 是否可用：

```bash
sherlock --version
```

如果命令失敗：
- 提議安裝：`pipx install sherlock-project` (推薦) 或 `pip install sherlock-project`
- **不要**嘗試多種安裝方法 — 選擇一個並繼續。
- 如果安裝失敗，請告知使用者並停止。

### 2. 擷取使用者名稱

**如果使用者的訊息中明確說明了使用者名稱，請直接從中擷取。**

**不應**使用 clarify (釐清) 工具的範例：
- "Find accounts for nasa" → 使用者名稱為 `nasa`
- "Search for johndoe123" → 使用者名稱為 `johndoe123`
- "Check if alice exists on social media" → 使用者名稱為 `alice`
- "Look up user bob on social networks" → 使用者名稱為 `bob`

**僅在以下情況使用 clarify：**
- 提到多個潛在的使用者名稱 ("search for alice or bob")
- 語意模糊 ("search for my username" 卻未指定名稱)
- 完全沒有提到使用者名稱 ("do an OSINT search")

擷取時，請採用與說明**完全一致**的使用者名稱 — 保留大小寫、數字、底線等。

### 3. 建構命令

**預設命令** (除非使用者特別要求，否則請使用此命令)：
```bash
sherlock --print-found --no-color "<username>" --timeout 90
```

**選用旗標** (僅在使用者明確要求時加入)：
- `--nsfw` — 包含 NSFW 網站 (僅在使用者要求時)
- `--tor` — 透過 Tor 路由 (僅在使用者要求匿名時)

**不要透過 clarify 詢問選項** — 直接執行預設搜尋即可。使用者如有需要，可以要求特定選項。

### 4. 執行搜尋

透過 `terminal` 工具執行。視網路狀況和網站數量而定，該命令通常需要 30-120 秒。

**Terminal 呼叫範例：**
```json
{
  "command": "sherlock --print-found --no-color \"target_username\"",
  "timeout": 180
}
```

### 5. 解析與呈現結果

Sherlock 以簡單的格式輸出找到的帳號。解析輸出並呈現：

1. **摘要行：** "Found X accounts for username 'Y'"
2. **分類連結：** 如果有助於閱讀，請按平台類型分組 (社群、專業、論壇等)。
3. **輸出檔案位置：** Sherlock 預設將結果儲存至 `<username>.txt`。

**輸出解析範例：**
```
[+] Instagram: https://instagram.com/username
[+] Twitter: https://twitter.com/username
[+] GitHub: https://github.com/username
```

盡可能將發現的內容呈現為可點擊的連結。

## 注意事項 (Pitfalls)

### 未找到結果
如果 Sherlock 沒有找到任何帳號，這通常是正確的 — 該使用者名稱可能未在受檢測的平台註冊。建議：
- 檢查拼寫/變體。
- 使用 `?` 萬用字元嘗試類似的使用者名稱：`sherlock "user?name"`
- 使用者可能設定了隱私保護或已刪除帳號。

### 超時問題
某些網站速度較慢或會阻擋自動化請求。使用 `--timeout 120` 增加等待時間，或使用 `--site` 限制搜尋範圍。

### Tor 設定
`--tor` 需要 Tor 守護程序 (daemon) 正在執行。如果使用者需要匿名但 Tor 不可用，建議：
- 安裝 Tor 服務。
- 使用 `--proxy` 配合替代代理。

### 誤報 (False Positives)
由於某些網站的回應結構，它們總會返回「已找到」。請配合手動檢查來交叉驗證非預期的結果。

### 速率限制
激進的搜尋可能會觸發速率限制。對於大量的使用者名稱搜尋，請在呼叫之間增加延遲，或使用 `--local` 配合快取資料。

## 安裝

### pipx (推薦)
```bash
pipx install sherlock-project
```

### pip
```bash
pip install sherlock-project
```

### Docker
```bash
docker pull sherlock/sherlock
docker run -it --rm sherlock/sherlock <username>
```

### Linux 套件
可用於 Debian 13+, Ubuntu 22.10+, Homebrew, Kali, BlackArch。

## 道德使用

此工具僅用於合法的 OSINT 和研究目的。提醒使用者：
- 僅搜尋他們擁有或獲得授權調查的使用者名稱。
- 尊重服務條款。
- 不要用於騷擾、跟蹤或非法活動。
- 在分享結果前考慮隱私影響。

## 驗證

執行 sherlock 後，驗證：
1. 輸出清單列出了找到的網站及其 URL。
2. 若使用了檔案輸出，應建立了 `<username>.txt` 檔案 (預設輸出)。
3. 若使用了 `--print-found`，輸出應僅包含符合項目的 `[+]` 行。

## 互動範例

**使用者：** "Can you check if the username 'johndoe123' exists on social media?"

**代理人程序：**
1. 檢查 `sherlock --version` (驗證已安裝)。
2. 已提供使用者名稱 — 直接繼續。
3. 執行：`sherlock --print-found --no-color "johndoe123" --timeout 90`
4. 解析輸出並呈現連結。

**回應格式：**
> Found 12 accounts for username 'johndoe123':
>
> • https://twitter.com/johndoe123
> • https://github.com/johndoe123
> • https://instagram.com/johndoe123
> • [... 其他連結]
>
> 結果已儲存至：johndoe123.txt

---

**使用者：** "Search for username 'alice' including NSFW sites"

**代理人程序：**
1. 檢查已安裝 sherlock。
2. 已提供使用者名稱與 NSFW 旗標。
3. 執行：`sherlock --print-found --no-color --nsfw "alice" --timeout 90`
4. 呈現結果。
