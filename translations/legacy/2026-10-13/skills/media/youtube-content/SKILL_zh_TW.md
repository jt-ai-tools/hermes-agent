---
name: youtube-content
description: >
  獲取 YouTube 影片逐字稿並將其轉換為結構化內容（章節、摘要、討論串、部落格文章）。當使用者分享 YouTube URL 或影片連結、要求摘要影片、索取逐字稿，或想要從任何 YouTube 影片中提取並重新格式化內容時使用。
---

# YouTube 內容工具

從 YouTube 影片中提取逐字稿並將其轉換為實用的格式。

## 設定

```bash
pip install youtube-transcript-api
```

## 輔助腳本

`SKILL_DIR` 是包含此 SKILL.md 檔案的目錄。該腳本支援任何標準的 YouTube URL 格式、短網址 (youtu.be)、Shorts、嵌入式 (embeds)、直播連結或原始的 11 位元影片 ID。

```bash
# 包含中繼資料的 JSON 輸出
python3 SKILL_DIR/scripts/fetch_transcript.py "https://youtube.com/watch?v=VIDEO_ID"

# 純文字（適合導入進一步處理）
python3 SKILL_DIR/scripts/fetch_transcript.py "URL" --text-only

# 包含時間戳記
python3 SKILL_DIR/scripts/fetch_transcript.py "URL" --timestamps

# 指定語言及其回退順序 (fallback chain)
python3 SKILL_DIR/scripts/fetch_transcript.py "URL" --language tr,en
```

## 輸出格式

獲取逐字稿後，根據使用者的需求進行格式化：

- **章節**：依主題轉換分組，輸出帶有時間戳記的章節列表
- **摘要**：對整段影片進行 5-10 句話的簡潔概述
- **章節摘要**：章節列表，並為每個章節提供一段簡短的摘要
- **討論串**：Twitter/X 討論串格式 — 編號貼文，每篇不超過 280 個字元
- **部落格文章**：包含標題、各章節和重點摘要的完整文章
- **佳句**：帶有時間戳記的著名語錄

### 範例 — 章節輸出

```
00:00 Introduction — 主持人以問題陳述開場
03:45 Background — 先前的研究以及為何現有解決方案不足
12:20 Core method — 提出的方法演練
24:10 Results — 基準測試比較與重點總結
31:55 Q&A — 觀眾關於可擴充性和後續步驟的提問
```

## 工作流程

1. 使用帶有 `--text-only --timestamps` 的輔助腳本**獲取**逐字稿。
2. **驗證**：確認輸出非空且為預期語言。如果為空，請在不使用 `--language` 的情況下重試以獲取任何可用的逐字稿。如果仍然為空，請告知使用者該影片可能已停用逐字稿。
3. **必要時進行分段**：如果逐字稿超過 5 萬個字元，請將其拆分為重疊的段落（約 4 萬個字元，包含 2 千個字元的重疊），並在合併前摘要每個段落。
4. **轉換**為請求的輸出格式。如果使用者未指定格式，預設為摘要。
5. **核對**：在呈現之前，重新閱讀轉換後的輸出，檢查連貫性、正確的時間戳記和完整性。

## 錯誤處理

- **逐字稿已停用**：告知使用者；建議他們檢查影片頁面是否提供字幕。
- **私人/不可用的影片**：轉達錯誤並請使用者驗證 URL。
- **無匹配語言**：在不使用 `--language` 的情況下重試以獲取任何可用的逐字稿，然後向使用者註明實際語言。
- **遺漏依賴套件**：執行 `pip install youtube-transcript-api` 並重試。
