# Gmail 搜尋語法

標準的 Gmail 搜尋運算子 (Search operators) 可在 `query` 引數中使用。

## 常用的運算子

| 運算子 | 範例 | 描述 |
|----------|---------|-------------|
| `is:unread` | `is:unread` | 未讀郵件 |
| `is:starred` | `is:starred` | 已加星號的郵件 |
| `is:important` | `is:important` | 重要郵件 |
| `in:inbox` | `in:inbox` | 僅限收件匣 |
| `in:sent` | `in:sent` | 寄件備份資料夾 |
| `in:drafts` | `in:drafts` | 草稿 |
| `in:trash` | `in:trash` | 垃圾桶 |
| `in:anywhere` | `in:anywhere` | 所有郵件，包含垃圾郵件和垃圾桶 |
| `from:` | `from:alice@example.com` | 寄件者 |
| `to:` | `to:bob@example.com` | 收件者 |
| `cc:` | `cc:team@example.com` | 副本 (CC) 收件者 |
| `subject:` | `subject:invoice` | 主旨包含 |
| `label:` | `label:work` | 具有標籤 |
| `has:attachment` | `has:attachment` | 包含附件 |
| `filename:` | `filename:pdf` | 附件檔名/類型 |
| `larger:` | `larger:5M` | 大於指定大小 |
| `smaller:` | `smaller:1M` | 小於指定大小 |

## 日期運算子

| 運算子 | 範例 | 描述 |
|----------|---------|-------------|
| `newer_than:` | `newer_than:7d` | 在過去 N 天 (d)、月 (m)、年 (y) 內 |
| `older_than:` | `older_than:30d` | 早於 N 天/月/年 |
| `after:` | `after:2026/02/01` | 在日期之後 (YYYY/MM/DD) |
| `before:` | `before:2026/03/01` | 在日期之前 |

## 組合語法

| 語法 | 範例 | 描述 |
|--------|---------|-------------|
| 空格 | `from:alice subject:meeting` | 且 (AND，隱式組合) |
| `OR` | `from:alice OR from:bob` | 或 (OR) |
| `-` | `-from:noreply@` | 否 (NOT，排除) |
| `()` | `(from:alice OR from:bob) subject:meeting` | 分組 |
| `""` | `"exact phrase"` | 精確字句匹配 |

## 常見模式

```
# 過去 1 天內的未讀郵件
is:unread newer_than:1d

# 來自特定寄件者且帶有 PDF 附件的郵件
from:accounting@company.com has:attachment filename:pdf

# 重要的未讀郵件 (排除促銷內容/社交網路)
is:unread -category:promotions -category:social

# 關於某個主題的郵件討論串
subject:"Q4 budget" newer_than:30d

# 需清理的大型附件
has:attachment larger:10M older_than:90d
```
