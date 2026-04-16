---
name: memento-flashcards
description: >-
  間隔重複字卡系統。從事實或文本建立卡片，
  使用由代理評分的自由文本答案與字卡對話，
  從 YouTube 逐字稿生成測驗，依據自適應排程複習到期卡片，
  並可將牌組匯出/匯入為 CSV。
version: 1.0.0
author: Memento AI
license: MIT
platforms: [macos, linux]
metadata:
  hermes:
    tags: [Education, Flashcards, Spaced Repetition, Learning, Quiz, YouTube]
    requires_toolsets: [terminal]
    category: productivity
---

# Memento Flashcards — 間隔重複字卡技能

## 概覽

Memento 提供您一個本地的、基於文件的字卡系統，並具備間隔重複 (Spaced-Repetition) 排程功能。
用戶可以透過自由文本回答問題與字卡互動，並由代理對回答進行評分，隨後安排下次複習時間。
當用戶想要執行以下操作時請使用它：

- **記住一個事實** — 將任何陳述轉化為問答字卡
- **使用間隔重複學習** — 複習到期的卡片，使用自適應間隔和代理評分的自由文本答案
- **從 YouTube 影片進行測驗** — 獲取逐字稿並生成包含 5 個問題的測驗
- **管理牌組** — 將卡片組織成集合 (Collections)，匯出/匯入 CSV

所有卡片數據都儲存在單個 JSON 文件中。不需要外部 API 金鑰 — 由您（代理）直接生成字卡內容和測驗問題。

Memento Flashcards 的用戶面向回應風格：
- 僅使用純文本。在回覆用戶時請勿使用 Markdown 格式。
- 複習和測驗的反饋請保持簡短且中立。避免額外的讚美、鼓勵或冗長的解釋。

## 何時使用

當用戶想要執行以下操作時使用此技能：
- 將事實儲存為字卡以便日後複習
- 使用間隔重複複習到期的卡片
- 從 YouTube 影片逐字稿生成測驗
- 匯入、匯出、檢查或刪除字卡數據

請勿將此技能用於一般的問答、編碼幫助或非記憶性任務。

## 快速參考

| 用戶意圖 | 行動 |
|---|---|
| "記住 X" / "將此儲存為字卡" | 生成問答卡片，呼叫 `memento_cards.py add` |
| 發送事實但未提及字卡 | 詢問 "要我將此儲存為 Memento 字卡嗎？" — 僅在確認後建立 |
| "建立一張字卡" | 詢問問題 (Q)、答案 (A)、集合；呼叫 `memento_cards.py add` |
| "複習我的卡片" | 呼叫 `memento_cards.py due`，逐一展示卡片 |
| "考考我 [YouTube URL]" | 呼叫 `youtube_quiz.py fetch VIDEO_ID`，生成 5 個問題，呼叫 `memento_cards.py add-quiz` |
| "匯出我的卡片" | 呼叫 `memento_cards.py export --output PATH` |
| "從 CSV 匯入卡片" | 呼叫 `memento_cards.py import --file PATH --collection NAME` |
| "顯示我的統計數據" | 呼叫 `memento_cards.py stats` |
| "刪除一張卡片" | 呼叫 `memento_cards.py delete --id ID` |
| "刪除一個集合" | 呼叫 `memento_cards.py delete-collection --collection NAME` |

## 卡片儲存

卡片儲存在以下路徑的 JSON 文件中：

```
~/.hermes/skills/productivity/memento-flashcards/data/cards.json
```

**切勿直接編輯此文件。** 務必使用 `memento_cards.py` 子命令。該腳本處理原子寫入（先寫入臨時文件，然後重新命名）以防止數據損壞。

該文件在首次使用時會自動建立。

## 程序

### 從事實建立卡片

### 啟動規則

並非所有的事實陳述都應該變成字卡。請使用以下三層檢查：

1. **明確意圖** — 用戶提到 "memento"、"flashcard" (字卡)、"remember this" (記住這個)、"save this card" (儲存這張卡)、"add a card" (新增一張卡) 或類似明確要求字卡的措辭 → **直接建立卡片**，無需確認。
2. **隱含意圖** — 用戶發送事實陳述但未提及字卡（例如 "光速是 299,792 km/s"） → **先詢問**："要我將此儲存為 Memento 字卡嗎？" 僅在用戶確認後才建立卡片。
3. **無意圖** — 訊息是編碼任務、問題、指令、正常對話，或任何顯然不是需要記憶的事實 → **完全不要啟動此技能**。讓其他技能或預設行為處理。

當確認啟動時（第 1 層直接執行，第 2 層確認後執行），生成一張字卡：

**步驟 1：** 將陳述轉化為問答對。內部使用此格式：

```
將事實陳述轉化為正面-背面（問-答）對。
僅回傳兩行：
Q: <問題文本>
A: <答案文本>

陳述："{statement}"
```

規則：
- 問題應測試關鍵事實的回憶
- 答案應簡明扼要

**步驟 2：** 呼叫腳本儲存卡片：

```bash
python3 ~/.hermes/skills/productivity/memento-flashcards/scripts/memento_cards.py add \
  --question "第二次世界大戰在哪一年結束？" \
  --answer "1945" \
  --collection "歷史"
```

如果用戶未指定集合，則預設使用 `"General"`。

腳本會輸出 JSON 確認已建立的卡片。

### 手動建立卡片

當用戶明確要求建立字卡時，詢問他們：
1. 問題（卡片正面）
2. 答案（卡片背面）
3. 集合名稱（可選 — 預設為 `"General"`）

然後如上所述呼叫 `memento_cards.py add`。

### 複習到期的卡片

當用戶想要複習時，獲取所有到期的卡片：

```bash
python3 ~/.hermes/skills/productivity/memento-flashcards/scripts/memento_cards.py due
```

這會回傳一個 JSON 數組，其中包含 `next_review_at <= now` 的卡片。如果需要集合篩選：

```bash
python3 ~/.hermes/skills/productivity/memento-flashcards/scripts/memento_cards.py due --collection "歷史"
```

**複習流程（自由文本評分）：**

以下是您必須遵循的精確互動模式示例。用戶回答，您為其評分，告訴他們正確答案，然後對卡片進行評價。

**互動示例：**

> **代理：** 柏林圍牆在哪一年倒塌？
>
> **用戶：** 1991
>
> **代理：** 不太正確。柏林圍牆在 1989 年倒塌。下次複習是在明天。
> *(代理呼叫：memento_cards.py rate --id ABC --rating hard --user-answer "1991")*
>
> 下一個問題：誰是第一個在月球上行走的人？

**規則：**

1. 僅顯示問題。等待用戶回答。
2. 收到答案後，將其與預期答案進行比較並評分：
   - **correct** (正確) → 用戶答對了關鍵事實（即使措辭不同）
   - **partial** (部分正確) → 方向正確但遺漏了核心細節
   - **incorrect** (不正確) → 錯誤或離題
3. **您必須告訴用戶正確答案以及他們的表現。** 保持簡短且純文本。使用此格式：
   - 正確："正確。答案：{answer}。下次複習在 7 天後。"
   - 部分正確："接近了。答案：{answer}。{他們遺漏的部分}。下次複習在 3 天後。"
   - 不正確："不太正確。答案：{answer}。下次複習在明天。"
4. 然後呼叫評價命令：correct→easy，partial→good，incorrect→hard。
5. 接著顯示下一個問題。

```bash
python3 ~/.hermes/skills/productivity/memento-flashcards/scripts/memento_cards.py rate \
  --id CARD_ID --rating easy --user-answer "用戶說的話"
```

**切勿跳過步驟 3。** 在繼續之前，用戶必須始終看到正確答案和反饋。

如果沒有到期的卡片，告訴用戶："目前沒有到期需要複習的卡片。稍後再回來查看！"

**退休覆蓋 (Retire override)：** 用戶可以隨時說 "退休這張卡片" 以將其永久從複習中移除。對此請使用 `--rating retire`。

### 間隔重複演算法

評價決定下次複習的間隔：

| 評價 | 間隔 | 輕鬆連勝 (ease_streak) | 狀態變化 |
|---|---|---|---|
| **hard** | +1 天 | 重設為 0 | 保持學習中 |
| **good** | +3 天 | 重設為 0 | 保持學習中 |
| **easy** | +7 天 | +1 | 若 ease_streak >= 3 → 退休 |
| **retire** | 永久 | 重設為 0 | → 退休 |

- **learning**: 卡片正在主動循環中
- **retired**: 卡片不會出現在複習中（用戶已精通或手動使其退休）
- 連續三次 "easy" 評價會自動使卡片退休

### YouTube 測驗生成

當用戶發送 YouTube URL 並想要測驗時：

**步驟 1：** 從 URL 中提取影片 ID（例如從 `https://www.youtube.com/watch?v=dQw4w9WgXcQ` 提取 `dQw4w9WgXcQ`）。

**步驟 2：** 獲取逐字稿：

```bash
python3 ~/.hermes/skills/productivity/memento-flashcards/scripts/youtube_quiz.py fetch VIDEO_ID
```

這會回傳 `{"title": "...", "transcript": "..."}` 或錯誤。

如果腳本回報 `missing_dependency` (缺少依賴)，請告訴用戶安裝它：
```bash
pip install youtube-transcript-api
```

**步驟 3：** 從逐字稿中生成 5 個測驗問題。使用以下規則：

```
您正在為一個播客節目建立包含 5 個問題的測驗。
僅回傳一個包含精確 5 個物件的 JSON 數組。
每個物件必須包含 'question' (問題) 和 'answer' (答案) 鍵。

選擇標準：
- 優先考慮重要、令人驚訝或基礎的事實。
- 跳過填充詞、顯而易見的細節以及需要沈重背景知識的事實。
- 絕不回傳是非題。
- 絕不只詢問日期。

問題規則：
- 每個問題必須測試一個離散的事實。
- 使用清晰、無歧義的措辭。
- 優先使用 什麼 (What)、誰 (Who)、多少 (How many)、哪一個 (Which)。
- 避免開放式的 描述 (Describe) 或 解釋 (Explain) 提示。

答案規則：
- 每個答案必須在 240 個字元以內。
- 以答案本身開頭，不要有開場白。
- 僅在需要時添加極少的澄清細節。
```

使用逐字稿的前 15,000 個字元作為上下文。自行生成問題（您是 LLM）。

**步驟 4：** 驗證輸出是否為有效的 JSON，且包含精確 5 個項目，每個項目都有非空的 `question` 和 `answer` 字串。如果驗證失敗，請重試一次。

**步驟 5：** 儲存測驗卡片：

```bash
python3 ~/.hermes/skills/productivity/memento-flashcards/scripts/memento_cards.py add-quiz \
  --video-id "VIDEO_ID" \
  --questions '[{"question":"...","answer":"..."},...]' \
  --collection "測驗 - 影片標題"
```

腳本會根據 `video_id` 進行去重 — 如果該影片的卡片已存在，它會跳過建立並回報現有的卡片。

**步驟 6：** 使用相同的自由文本評分流程逐一展示問題：
1. 顯示 "問題 1/5: ..." 並等待用戶回答。切勿包含答案或任何有關揭曉答案的暗示。
2. 等待用戶用自己的話回答。
3. 使用評分提示對他們的答案進行評分（參見 "複習到期的卡片" 部分）。
4. **重要：您必須在執行任何其他操作之前回覆用戶反饋。** 展示等級、正確答案以及卡片下次到期時間。不要默默跳到下一個問題。保持簡短且純文本。例如："不太正確。答案：{answer}。下次複習在明天。"
5. **展示反饋後**，呼叫評價命令，然後在同一條訊息中顯示下一個問題：
```bash
python3 ~/.hermes/skills/productivity/memento-flashcards/scripts/memento_cards.py rate \
  --id CARD_ID --rating easy --user-answer "用戶說的話"
```
6. 重複此過程。每個答案都必須在下一個問題之前收到可見的反饋。

### 匯出/匯入 CSV

**匯出：**
```bash
python3 ~/.hermes/skills/productivity/memento-flashcards/scripts/memento_cards.py export \
  --output ~/flashcards.csv
```

產生一個 3 欄位的 CSV：`question,answer,collection` (無標題列)。

**匯入：**
```bash
python3 ~/.hermes/skills/productivity/memento-flashcards/scripts/memento_cards.py import \
  --file ~/flashcards.csv \
  --collection "匯入項目"
```

讀取包含以下欄位的 CSV：問題 (question)、答案 (answer)，以及可選的集合 (collection, 第 3 欄)。如果缺少集合欄位，則使用 `--collection` 參數。

### 統計數據

```bash
python3 ~/.hermes/skills/productivity/memento-flashcards/scripts/memento_cards.py stats
```

回傳包含以下內容的 JSON：
- `total`: 總卡片數
- `learning`: 主動循環中的卡片
- `retired`: 已精通的卡片
- `due_now`: 目前到期需要複習的卡片
- `collections`: 按集合名稱細分

## 陷阱

- **切勿直接編輯 `cards.json`** — 務必使用腳本子命令以避免數據損壞。
- **逐字稿失敗** — 某些 YouTube 影片沒有英文逐字稿或已禁用逐字稿；請告知用戶並建議另一個影片。
- **可選依賴** — `youtube_quiz.py` 需要 `youtube-transcript-api`；如果缺少，請告訴用戶執行 `pip install youtube-transcript-api`。
- **大型匯入** — 包含數千行的 CSV 匯入可以正常運作，但 JSON 輸出可能會很冗長；請為用戶摘要結果。
- **影片 ID 提取** — 支援 `youtube.com/watch?v=ID` 和 `youtu.be/ID` 兩種 URL 格式。

## 驗證

直接驗證輔助腳本：

```bash
python3 ~/.hermes/skills/productivity/memento-flashcards/scripts/memento_cards.py stats
python3 ~/.hermes/skills/productivity/memento-flashcards/scripts/memento_cards.py add --question "法國的首都是哪裡？" --answer "巴黎" --collection "General"
python3 ~/.hermes/skills/productivity/memento-flashcards/scripts/memento_cards.py due
```

如果您是在儲存庫簽出環境中進行測試，請執行：

```bash
pytest tests/skills/test_memento_cards.py tests/skills/test_youtube_quiz.py -q
```

代理層級驗證：
- 開始複習並確認反饋是純文本、簡短的，且在下一張卡片之前始終包含正確答案。
- 執行 YouTube 測驗流程並確認每個答案在下一個問題之前都收到可見的反饋。
