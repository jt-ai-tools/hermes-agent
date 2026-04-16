# 使用 MML (MIME Meta Language) 編寫郵件

Himalaya 使用 MML 來編寫電子郵件。MML 是一種簡單的 XML 語法，會編譯成 MIME 郵件。

## 基本郵件結構

一封電子郵件由一列**標頭 (headers)** 接著**本文 (body)** 組成，中間以一個空行隔開：

```
From: sender@example.com
To: recipient@example.com
Subject: 你好，世界

這是郵件本文。
```

## 標頭 (Headers)

常見標頭：

- `From`: 寄件者地址
- `To`: 主要收件者
- `Cc`: 副本收件者
- `Bcc`: 密件副本收件者
- `Subject`: 郵件主旨
- `Reply-To`: 回覆地址 (若與 From 不同)
- `In-Reply-To`: 正在回覆的郵件 ID

### 地址格式

```
To: user@example.com
To: John Doe <john@example.com>
To: "John Doe" <john@example.com>
To: user1@example.com, user2@example.com, "Jane" <jane@example.com>
```

## 純文字本文

簡單的純文字電子郵件：

```
From: alice@localhost
To: bob@localhost
Subject: 純文字範例

你好，這是一封純文字電子郵件。
不需要特殊的格式。

祝好，
Alice
```

## 用於豐富郵件的 MML

### 多部分郵件 (Multipart Messages)

替代性的 text/html 部分：

```
From: alice@localhost
To: bob@localhost
Subject: 多部分範例

<#multipart type=alternative>
這是純文字版本。
<#part type=text/html>
<html><body><h1>這是 HTML 版本</h1></body></html>
<#/multipart>
```

### 附件

附加檔案：

```
From: alice@localhost
To: bob@localhost
Subject: 包含附件

這是您要求的檔案。

<#part filename=/path/to/document.pdf><#/part>
```

使用自訂名稱的附件：

```
<#part filename=/path/to/file.pdf name=report.pdf><#/part>
```

多個附件：

```
<#part filename=/path/to/doc1.pdf><#/part>
<#part filename=/path/to/doc2.pdf><#/part>
```

### 內嵌圖片

內嵌圖片：

```
From: alice@localhost
To: bob@localhost
Subject: 內嵌圖片

<#multipart type=related>
<#part type=text/html>
<html><body>
<p>看看這張圖片：</p>
<img src="cid:image1">
</body></html>
<#part disposition=inline id=image1 filename=/path/to/image.png><#/part>
<#/multipart>
```

### 混合內容 (文字 + 附件)

```
From: alice@localhost
To: bob@localhost
Subject: 混合內容

<#multipart type=mixed>
<#part type=text/plain>
請查收附件檔案。

祝好，
Alice
<#part filename=/path/to/file1.pdf><#/part>
<#part filename=/path/to/file2.zip><#/part>
<#/multipart>
```

## MML 標籤參考

### `<#multipart>`

將多個部分組合在一起。

- `type=alternative`: 相同內容的不同呈現方式
- `type=mixed`: 獨立的部分 (文字 + 附件)
- `type=related`: 相互引用的部分 (HTML + 圖片)

### `<#part>`

定義一個郵件部分。

- `type=<mime-type>`: 內容類型 (例如：`text/html`, `application/pdf`)
- `filename=<path>`: 要附加的檔案
- `name=<name>`: 附件的顯示名稱
- `disposition=inline`: 直接顯示而非作為附件
- `id=<cid>`: 用於在 HTML 中引用的內容 ID

## 透過 CLI 編寫

### 互動式編寫

開啟您的 `$EDITOR`：

```bash
himalaya message write
```

### 回覆 (開啟編輯器並包含引用的郵件)

```bash
himalaya message reply 42
himalaya message reply 42 --all  # 回覆所有人
```

### 轉寄

```bash
himalaya message forward 42
```

### 從 stdin 發送

```bash
cat message.txt | himalaya template send
```

### 從 CLI 預填標頭

```bash
himalaya message write \
  -H "To:recipient@example.com" \
  -H "Subject:快速郵件" \
  "在此輸入郵件本文"
```

## 提示

- 編輯器開啟時會帶有範本；請填寫標頭與本文。
- 儲存並退出編輯器即可發送；不儲存直接退出則會取消。
- 發送時，MML 部分會被編譯成正確的 MIME 格式。
- 使用 `himalaya message export --full` 來檢查收到的電子郵件的原始 MIME 結構。
