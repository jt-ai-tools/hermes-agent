---
name: meme-generation
description: 透過挑選模板並使用 Pillow 疊加文字來生成真實的迷因圖片。產出實際的 .png 迷因檔案。
version: 2.0.0
author: adanaleycio
license: MIT
metadata:
  hermes:
    tags: [creative, memes, humor, images]
    related_skills: [ascii-art, generative-widgets]
    category: creative
---

# 迷因生成 (Meme Generation)

根據主題生成實際的迷因圖片。挑選模板、撰寫文字，並渲染出帶有文字疊加的真實 .png 檔案。

## 何時使用

- 使用者要求製作或生成迷因
- 使用者想要關於特定主題、情境或挫折的迷因
- 使用者說「幫我做成迷因」或類似的要求

## 可用模板

此腳本支援**約 100 種熱門的 imgflip 模板**（可透過名稱或 ID 呼叫），以及 10 個經過手動調整文字位置的精選模板。

### 精選模板 (自定義文字放置)

| ID | 名稱 | 欄位 | 適用情境 |
|----|------|--------|----------|
| `this-is-fine` | This is Fine | top, bottom | 混亂、否認 |
| `drake` | Drake Hotline Bling | reject, approve | 拒絕／偏好 |
| `distracted-boyfriend` | Distracted Boyfriend | distraction, current, person | 誘惑、重點轉移 |
| `two-buttons` | Two Buttons | left, right, person | 困難的抉擇 |
| `expanding-brain` | Expanding Brain | 4 個階段 | 逐漸升級的諷刺 |
| `change-my-mind` | Change My Mind | statement | 爭議性見解 (Hot takes) |
| `woman-yelling-at-cat` | Woman Yelling at Cat | woman, cat | 爭吵 |
| `one-does-not-simply` | One Does Not Simply | top, bottom | 看似簡單實則困難的事 |
| `grus-plan` | Gru's Plan | step1-3, realization | 事與願違的計劃 |
| `batman-slapping-robin` | Batman Slapping Robin | robin, batman | 制止糟糕的想法 |

### 動態模板 (來自 imgflip API)

任何不在精選列表中的模板都可以透過名稱或 imgflip ID 使用。這些模板會獲得智慧預設文字位置（2 欄位為頂部/底部，3 欄位以上為均勻分布）。搜尋方式：
```bash
python "$SKILL_DIR/scripts/generate_meme.py" --search "disaster"
```

## 程序

### 模式 1：經典模板 (預設)

1. 閱讀使用者的主題並識別核心動態（混亂、兩難、偏好、諷刺等）。
2. 挑選最匹配的模板。參考「適用情境」欄位，或使用 `--search` 搜尋。
3. 為每個欄位撰寫簡短的標題（每個欄位最多 8-12 個字，越短越好）。
4. 找到技能的腳本目錄：
   ```
   SKILL_DIR=$(dirname "$(find ~/.hermes/skills -path '*/meme-generation/SKILL.md' 2>/dev/null | head -1)")
   ```
5. 執行生成器：
   ```bash
   python "$SKILL_DIR/scripts/generate_meme.py" <template_id> /tmp/meme.png "caption 1" "caption 2" ...
   ```
6. 使用 `MEDIA:/tmp/meme.png` 回傳圖片。

### 模式 2：自定義 AI 圖片 (當 image_generate 可用時)

當沒有經典模板適合，或使用者想要原創內容時使用此模式。

1. 先撰寫標題文字。
2. 使用 `image_generate` 建立符合迷因概念的場景。**不要**在圖片提示詞中包含任何文字——文字將由腳本加入。僅描述視覺場景。
3. 從 image_generate 結果 URL 找到生成的圖片路徑。如果需要，將其下載到本地路徑。
4. 執行腳本並帶上 `--image` 以疊加文字，選擇一種模式：
   - **Overlay** (文字直接在圖片上，白色帶黑邊)：
     ```bash
     python "$SKILL_DIR/scripts/generate_meme.py" --image /path/to/scene.png /tmp/meme.png "top text" "bottom text"
     ```
   - **Bars** (圖片上方/下方帶有白字黑條——更整潔，始終清晰易讀)：
     ```bash
     python "$SKILL_DIR/scripts/generate_meme.py" --image /path/to/scene.png --bars /tmp/meme.png "top text" "bottom text"
     ```
   當圖片背景複雜/細節豐富導致文字難以閱讀時，請使用 `--bars`。
5. **使用視覺驗證** (如果 `vision_analyze` 可用)：檢查結果是否良好：
   ```
   vision_analyze(image_url="/tmp/meme.png", question="文字是否清晰且位置正確？迷因在視覺上是否有效？")
   ```
   如果視覺模型回報問題（文字難以閱讀、位置不佳等），請嘗試另一種模式（在疊加和黑條之間切換）或重新生成場景。
6. 使用 `MEDIA:/tmp/meme.png` 回傳圖片。

## 範例

**「凌晨 2 點在生產環境除錯」：**
```bash
python generate_meme.py this-is-fine /tmp/meme.png "伺服器著火了" "沒事，一切都好"
```

**「在睡覺和再看一集之間抉擇」：**
```bash
python generate_meme.py drake /tmp/meme.png "睡滿 8 小時" "凌晨 3 點再看一集"
```

**「週一早晨的各個階段」：**
```bash
python generate_meme.py expanding-brain /tmp/meme.png "設一個鬧鐘" "設 5 個鬧鐘" "睡過頭無視所有鬧鐘" "在床上工作"
```

## 列出模板

查看所有可用模板：
```bash
python generate_meme.py --list
```

## 注意事項

- 標題保持簡短。文字太長的迷因看起來很糟。
- 文字參數的數量應與模板的欄位數量一致。
- 挑選符合笑話結構的模板，而不僅僅是符合主題。
- 不要生成仇恨、虐待或針對個人的內容。
- 腳本在第一次下載後會將模板圖片緩存在 `scripts/.cache/` 中。

## 驗證

如果滿足以下條件，則輸出正確：
- 在輸出路徑建立了一個 .png 檔案。
- 文字在模板上清晰易讀（白色帶黑邊）。
- 笑話成立——標題符合模板預期的結構。
- 檔案可透過 MEDIA: 路徑交付。
