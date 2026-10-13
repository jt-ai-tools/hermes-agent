---
name: xitter
description: 透過 x-cli 終端機用戶端，使用官方 X API 憑證與 X/Twitter 互動。可用於發布、閱讀時間軸、搜尋推文、按讚、轉推、書籤、提及和使用者查詢。
version: 1.0.0
author: Siddharth Balyan + Hermes Agent
license: MIT
platforms: [linux, macos]
prerequisites:
  commands: [uv]
  env_vars: [X_API_KEY, X_API_SECRET, X_BEARER_TOKEN, X_ACCESS_TOKEN, X_ACCESS_TOKEN_SECRET]
metadata:
  hermes:
    tags: [twitter, x, social-media, x-cli]
    homepage: https://github.com/Infatoshi/x-cli
---

# Xitter — 透過 x-cli 使用 X/Twitter

使用 `x-cli` 透過終端機進行官方 X/Twitter API 互動。

此技能可用於：
- 發布推文、回覆和引用推文
- 搜尋推文和閱讀時間軸
- 查詢使用者、粉絲和正在追蹤的人
- 按讚和轉推
- 檢查提及和書籤

此技能刻意不將獨立的 CLI 實作內建於 Hermes。請安裝並使用上游的 `x-cli`。

## 重要費用 / 存取說明

對於大多數實際用途，X API 存取並非實質免費。請預期需要付費或預付的 X 開發者存取權限。如果命令因權限或配額錯誤而失敗，請先檢查您的 X 開發者方案。

## 安裝

使用 `uv` 安裝上游 `x-cli`：

```bash
uv tool install git+https://github.com/Infatoshi/x-cli.git
```

之後可透過以下命令升級：

```bash
uv tool upgrade x-cli
```

驗證：

```bash
x-cli --help
```

## 憑證

您需要從 X 開發者入口網站取得以下五個值：
- `X_API_KEY`
- `X_API_SECRET`
- `X_BEARER_TOKEN`
- `X_ACCESS_TOKEN`
- `X_ACCESS_TOKEN_SECRET`

從此處取得：
- https://developer.x.com/en/portal/dashboard

### 為什麼 X 需要 5 個密鑰？

遺憾的是，官方 X API 將認證分為應用程式級別和使用者級別的憑證：

- `X_API_KEY` + `X_API_SECRET` 用於識別您的應用程式
- `X_BEARER_TOKEN` 用於應用程式級別的讀取存取
- `X_ACCESS_TOKEN` + `X_ACCESS_TOKEN_SECRET` 讓 CLI 能代表您的使用者帳號執行寫入和已認證的操作

沒錯 — 對於單一整合來說，這確實需要很多密鑰，但這是穩定官方 API 的路徑，且仍優於使用 cookie/會話抓取。

入口網站設定要求：
1. 建立或開啟您的應用程式
2. 在使用者身份驗證設定中，將權限設為 `Read and write`
3. 在啟用寫入權限後，生成或重新生成存取權杖 (access token) + 存取權杖密鑰 (access token secret)
4. 仔細保存這五個值 — 缺少其中任何一個通常會導致混淆的認證或權限錯誤

注意：上游 `x-cli` 預期存在完整的憑證集，因此即使您主要只在乎唯讀命令，設定全部五個值是最簡單的做法。

## 費用 / 摩擦現實檢核

如果此設定讓您覺得比預期的更沈重，那是因為事實的確如此。X 的官方開發者流程具有較高的門檻且通常需要付費。此技能選擇官方 API 路徑，是因為它比瀏覽器 cookie/會話方法更穩定且更易於維護。

如果使用者想要最不脆弱的長期設定，請使用此技能。如果他們想要零設定或非官方路徑，那是另一種權衡，並非此技能的目的。


## 憑證儲存位置

`x-cli` 會在 `~/.config/x-cli/.env` 中尋找憑證。

如果您已將 X 憑證保存在 `~/.hermes/.env` 中，最簡潔的設定方式為：

```bash
mkdir -p ~/.config/x-cli
ln -sf ~/.hermes/.env ~/.config/x-cli/.env
```

或建立一個專用檔案：

```bash
mkdir -p ~/.config/x-cli
cat > ~/.config/x-cli/.env <<'EOF'
X_API_KEY=您的消費者金鑰
X_API_SECRET=您的私鑰
X_BEARER_TOKEN=您的持有人權杖
X_ACCESS_TOKEN=您的存取權杖
X_ACCESS_TOKEN_SECRET=您的存取權杖密鑰
EOF
chmod 600 ~/.config/x-cli/.env
```

## 快速驗證

```bash
x-cli user get openai
x-cli tweet search "from:NousResearch" --max 3
x-cli me mentions --max 5
```

如果讀取正常但寫入失敗，請在確認具備 `Read and write` 權限後重新生成存取權杖。

## 常見命令

### 推文

```bash
x-cli tweet post "hello world"
x-cli tweet get https://x.com/user/status/1234567890
x-cli tweet delete 1234567890
x-cli tweet reply 1234567890 "nice post"
x-cli tweet quote 1234567890 "worth reading"
x-cli tweet search "AI agents" --max 20
x-cli tweet metrics 1234567890
```

### 使用者

```bash
x-cli user get openai
x-cli user timeline openai --max 10
x-cli user followers openai --max 50
x-cli user following openai --max 50
```

### 本身 / 已認證使用者

```bash
x-cli me mentions --max 20
x-cli me bookmarks --max 20
x-cli me bookmark 1234567890
x-cli me unbookmark 1234567890
```

### 快速操作

```bash
x-cli like 1234567890
x-cli retweet 1234567890
```

## 輸出模式

當代理需要以程式化方式檢查欄位時，請使用結構化輸出：

```bash
x-cli -j tweet search "AI agents" --max 5
x-cli -p user get openai
x-cli -md tweet get 1234567890
x-cli -v -j tweet get 1234567890
```

建議的預設設定：
- `-j` 用於機器可讀輸出
- `-v` 當您需要時間戳記、指標或後設資料時
- 純文字/預設模式用於快速的人力檢查

## 代理工作流

1. 確認已安裝 `x-cli`
2. 確認憑證存在
3. 從讀取命令開始 (`user get`, `tweet search`, `me mentions`)
4. 提取後續步驟所需的欄位時使用 `-j`
5. 僅在確認目標推文/使用者以及使用者意圖後才執行寫入操作

## 常見陷阱

- **付費 API 存取**：許多失敗是方案/權限問題，而非程式碼問題。
- **403 oauth1-permissions**：在啟用 `Read and write` 後重新生成存取權杖。
- **回覆限制**：X 限制許多程式化回覆。`tweet quote` 通常比 `tweet reply` 更可靠。
- **速率限制**：請預期每個端點皆有其限制和冷卻時間。
- **憑證偏差**：如果您在 `~/.hermes/.env` 中輪換權杖，請確保 `~/.config/x-cli/.env` 仍指向目前檔案。

## 備註

- 偏好官方 API 工作流，而非 cookie/會話抓取。
- 推文 URL 或 ID 可交替使用 — `x-cli` 皆可接受。
- 如果上遊的書籤行為發生變化，請先檢查上遊的 README：
  https://github.com/Infatoshi/x-cli
