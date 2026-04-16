---
name: llm-wiki
description: "Karpathy 的 LLM Wiki —— 建立並維護一個持久、相互關聯的 markdown 知識庫。攝入來源、查詢編譯後的知識，並進行一致性檢查 (lint)。"
version: 2.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [wiki, 知識庫, 研究, 筆記, markdown, rag-alternative]
    category: research
    related_skills: [obsidian, arxiv, agentic-research-ideas]
    config:
      - key: wiki.path
        description: LLM Wiki 知識庫目錄的路徑
        default: "~/wiki"
        prompt: Wiki 目錄路徑
---

# Karpathy 的 LLM Wiki

建立並維護一個持久、不斷累積的知識庫，以相互關聯的 markdown 文件形式存在。
基於 [Andrej Karpathy 的 LLM Wiki 模式](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)。

與傳統的 RAG (每次查詢都從頭開始重新發現知識) 不同，wiki 只編譯一次知識並保持更新。交叉引用 (Cross-references) 已經存在。矛盾點已經被標記。綜合分析反映了所有已攝入的內容。

**分工：** 人類負責策劃來源並指導分析。Agent 負責總結、交叉引用、歸檔並維護一致性。

## 何時啟用此技能

當使用者執行以下操作時，請使用此技能：
- 要求建立、構建或啟動一個 wiki 或知識庫
- 要求攝入、添加或處理一個來源到他們的 wiki 中
- 提出問題且在配置的路徑中存在現有的 wiki
- 要求對其 wiki 進行檢查 (lint)、稽核或健康檢查
- 在研究背景下提到他們的 wiki、知識庫或「筆記」

## Wiki 位置

透過 `~/.hermes/config.yaml` 中的 `skills.config.wiki.path` 進行配置 (在 `hermes config migrate` 或 `hermes setup` 期間會提示)：

```yaml
skills:
  config:
    wiki:
      path: ~/wiki
```

預設為 `~/wiki`。當此技能載入時，會注入解析後的路徑 —— 請查看上方的 `[Skill config: ...]` 區塊以獲取當前值。

Wiki 僅是一個存放 markdown 文件的目錄 —— 可以使用 Obsidian、VS Code 或任何編輯器打開。不需要數據庫，也不需要特殊工具。

## 架構：三層結構

```
wiki/
├── SCHEMA.md           # 約定、結構規則、領域配置
├── index.md            # 分類內容目錄，附有一行摘要
├── log.md              # 按時間順序排列的操作日誌 (僅限追加，每年輪換一次)
├── raw/                # 第 1 層：不可變的原始素材
│   ├── articles/       # 網頁文章、剪報
│   ├── papers/         # PDF、arxiv 論文
│   ├── transcripts/    # 會議紀錄、訪談
│   └── assets/         # 來源中引用的圖片、圖表
├── entities/           # 第 2 層：實體頁面 (人物、組織、產品、模型)
├── concepts/           # 第 2 層：概念/主題頁面
├── comparisons/        # 第 2 層：並行分析 (side-by-side analyses)
└── queries/            # 第 2 層：值得保留的歸檔查詢結果
```

**第 1 層 —— 原始來源 (Raw Sources)：** 不可變。Agent 僅讀取但從不修改這些內容。
**第 2 層 —— Wiki：** 由 Agent 擁有的 markdown 文件。由 Agent 建立、更新並進行交叉引用。
**第 3 層 —— Schema：** `SCHEMA.md` 定義了結構、約定和標籤分類 (tag taxonomy)。

## 恢復現有的 Wiki (至關重要 —— 每次對話開始時都要做)

當使用者擁有現有的 wiki 時，**在執行任何操作之前，請務必先瞭解現況**：

① **閱讀 `SCHEMA.md`** —— 瞭解領域、約定和標籤分類。
② **閱讀 `index.md`** —— 瞭解現有哪些頁面及其摘要。
③ **掃描最近的 `log.md`** —— 閱讀最後 20-30 條記錄以瞭解最近的活動。

```bash
WIKI="${wiki_path:-$HOME/wiki}"
# 在對話開始時進行現況瞭解讀取
read_file "$WIKI/SCHEMA.md"
read_file "$WIKI/index.md"
read_file "$WIKI/log.md" offset=<最後 30 行>
```

只有在瞭解現況後，才應進行攝入、查詢或檢查。這可以防止：
- 為已存在的實體建立重複頁面
- 遺漏與現有內容的交叉引用
- 違反 Schema 的約定
- 重複執行已經記錄過的工作

對於大型 wiki (100 頁以上)，在建立任何新內容之前，也請針對相關主題快速執行 `search_files`。

## 初始化新的 Wiki

當使用者要求建立或啟動一個 wiki 時：

1. 確定 wiki 路徑 (從配置、環境變數或詢問使用者；預設為 `~/wiki`)
2. 建立上述目錄結構
3. 詢問使用者該 wiki 涵蓋的領域 —— 越具體越好
4. 編寫針對該領域定制的 `SCHEMA.md` (參見下方模板)
5. 編寫帶有分類標題的初始 `index.md`
6. 編寫帶有建立記錄的初始 `log.md`
7. 確認 wiki 已就緒，並建議首批可攝入的來源

### SCHEMA.md 模板

根據使用者的領域進行調整。Schema 會約束 Agent 的行為並確保一致性：

```markdown
# Wiki Schema

## 領域 (Domain)
[此 wiki 涵蓋的內容 —— 例如，「AI/ML 研究」、「個人健康」、「新創情報」]

## 約定 (Conventions)
- 檔案名稱：小寫、使用連字號、不使用空格 (例如：`transformer-architecture.md`)
- 每個 wiki 頁面都以 YAML frontmatter 開頭 (參見下方)
- 使用 `[[wikilinks]]` 在頁面之間建立連結 (每頁至少 2 個外部連結)
- 更新頁面時，務必更新 `updated` 日期
- 每個新頁面必須添加到 `index.md` 的正確分類下
- 每個操作必須追加到 `log.md` 中

## Frontmatter
  ```yaml
  ---
  title: 頁面標題
  created: YYYY-MM-DD
  updated: YYYY-MM-DD
  type: entity | concept | comparison | query | summary
  tags: [來自下方分類]
  sources: [raw/articles/source-name.md]
  ---
  ```

## 標籤分類 (Tag Taxonomy)
[為該領域定義 10-20 個頂級標籤。在使用新標籤之前，請先在此處添加。]

AI/ML 範例：
- 模型 (Models)：model, architecture, benchmark, training
- 人物/組織 (People/Orgs)：person, company, lab, open-source
- 技術 (Techniques)：optimization, fine-tuning, inference, alignment, data
- 元數據 (Meta)：comparison, column, timeline, controversy, prediction

規則：頁面上的每個標籤都必須出現在此分類中。如果需要新標籤，請先在此處添加，然後再使用。這可以防止標籤氾濫。

## 頁面建立門檻 (Page Thresholds)
- **建立頁面**：當實體/概念出現在 2 個以上的來源中，或者是單一來源的核心內容時
- **添加到現有頁面**：當來源提到已經涵蓋的內容時
- **不要建立頁面**：對於隨口提及、次要細節或領域之外的事物
- **拆分頁面**：當頁面超過約 200 行時 —— 拆分為帶有交叉連結的子主題
- **歸檔頁面**：當內容被完全取代時 —— 移動到 `_archive/` 並從索引中移除

## 實體頁面 (Entity Pages)
每個著名實體對應一個頁面。包括：
- 概述 / 它是什麼
- 關鍵事實和日期
- 與其他實體的關係 (`[[wikilinks]]`)
- 來源參考文獻

## 概念頁面 (Concept Pages)
每個概念或主題對應一個頁面。包括：
- 定義 / 解釋
- 當前的知識狀態
- 開放性問題或爭議
- 相關概念 (`[[wikilinks]]`)

## 比較頁面 (Comparison Pages)
並行分析。包括：
- 正在比較什麼以及原因
- 比較維度 (建議使用表格格式)
- 結論或綜合分析
- 來源

## 更新政策 (Update Policy)
當新資訊與現有內容衝突時：
1. 檢查日期 —— 較新的來源通常取代較舊的來源
2. 如果確實存在矛盾，請記錄這兩種觀點及其日期和來源
3. 在 frontmatter 中標記矛盾：`contradictions: [page-name]`
4. 在檢查 (lint) 報告中標記以供使用者審查
```

### index.md 模板

索引按類型分類。每條記錄佔一行：wikilink + 摘要。

```markdown
# Wiki Index

> 內容目錄。每個 wiki 頁面都按其類型列出，並附有一行摘要。
> 優先閱讀此文件以查找任何查詢的相關頁面。
> 最後更新：YYYY-MM-DD | 總頁數：N

## 實體 (Entities)
<!-- 區塊內按字母順序排列 -->

## 概念 (Concepts)

## 比較 (Comparisons)

## 查詢 (Queries)
```

**擴展規則：** 當任何區塊超過 50 條記錄時，按首字母或子領域將其拆分為子區塊。當索引總數超過 200 條時，建立 `_meta/topic-map.md` 按主題對頁面進行分組，以便更快速地導覽。

### log.md 模板

```markdown
# Wiki Log

> 所有 wiki 操作的年代紀錄。僅限追加。
> 格式：`## [YYYY-MM-DD] action | subject`
> 操作：ingest, update, query, lint, create, archive, delete
> 當此文件超過 500 條記錄時，進行輪換：重新命名為 log-YYYY.md 並重新開始。

## [YYYY-MM-DD] create | Wiki 已初始化
- 領域：[domain]
- 結構已建立，包含 SCHEMA.md, index.md, log.md
```

## 核心操作

### 1. 攝入 (Ingest)

當使用者提供來源 (URL、文件、貼上) 時，將其整合到 wiki 中：

① **擷取原始來源：**
   - URL → 使用 `web_extract` 獲取 markdown，儲存至 `raw/articles/`
   - PDF → 使用 `web_extract` (處理 PDF)，儲存至 `raw/papers/`
   - 貼上的文字 → 儲存至適當的 `raw/` 子目錄
   - 以具描述性的名稱命名文件：`raw/articles/karpathy-llm-wiki-2026.md`

② **與使用者討論要點** —— 領域中哪些內容有趣、哪些重要。(在自動化/cron 環境中跳過此步驟 —— 直接進行。)

③ **檢查已存在的內容** —— 搜尋 index.md 並使用 `search_files` 尋找所提及實體/概念的現有頁面。這是知識成長與重複堆積之間的區別。

④ **編寫或更新 wiki 頁面：**
   - **新實體/概念：** 僅在符合 SCHEMA.md 中的頁面建立門檻 (2 次以上提及或單一來源核心) 時建立頁面。
   - **現有頁面：** 添加新資訊、更新事實、更新 `updated` 日期。當新資訊與現有內容衝突時，遵循更新政策。
   - **交叉引用：** 每個新建立或更新的頁面必須透過 `[[wikilinks]]` 連結到至少 2 個其他頁面。檢查現有頁面是否也連結回來。
   - **標籤：** 僅使用 SCHEMA.md 分類中的標籤。

⑤ **更新導覽：**
   - 將新頁面按字母順序添加到 `index.md` 的正確分類下
   - 更新 index 標題中的「總頁數」和「最後更新」日期
   - 追加至 `log.md`：`## [YYYY-MM-DD] ingest | 來源標題`
   - 在日誌記錄中列出每個建立或更新的文件

⑥ **報告更改內容** —— 向使用者列出每個建立或更新的文件。

單一來源可能會觸發橫跨 5-15 個 wiki 頁面的更新。這是正常且理想的 —— 這就是累積效應。

### 2. 查詢 (Query)

當使用者詢問有關 wiki 領域的問題時：

① **閱讀 `index.md`** 以識別相關頁面。
② **對於擁有 100 頁以上的 wiki**，還應針對關鍵字對所有 `.md` 文件執行 `search_files` —— 僅靠索引可能會遺漏相關內容。
③ 使用 `read_file` **閱讀相關頁面**。
④ 從編譯後的知識中**綜合出答案**。引用您參考的 wiki 頁面：「根據 [[page-a]] 和 [[page-b]]……」
⑤ **將有價值的答案歸檔** —— 如果答案是實質性的比較、深入探究或新穎的綜合分析，請在 `queries/` 或 `comparisons/` 中建立頁面。不要歸檔瑣碎的查詢 —— 僅歸檔重新推導會很痛苦的答案。
⑥ **更新 log.md**，記錄查詢內容以及是否已歸檔。

### 3. 檢查 (Lint)

當使用者要求對 wiki 進行檢查 (lint)、健康檢查或稽核時：

① **孤立頁面 (Orphan pages)：** 尋找沒有被其他頁面透過 `[[wikilinks]]` 連結的頁面。
```python
# 使用 execute_code 進行此操作 —— 對所有 wiki 頁面進行程式化掃描
import os, re
from collections import defaultdict
wiki = "<WIKI_PATH>"
# 掃描 entities/, concepts/, comparisons/, queries/ 中的所有 .md 文件
# 提取所有 [[wikilinks]] —— 構建入站連結映射
# 入站連結為零的頁面即為孤立頁面
```

② **損壞的 wikilinks：** 尋找指向不存在頁面的 `[[links]]`。

③ **索引完整性：** 每個 wiki 頁面都應出現在 `index.md` 中。將檔案系統與索引條目進行比較。

④ **Frontmatter 驗證：** 每個 wiki 頁面都必須具有所有必填欄位 (title, created, updated, type, tags, sources)。標籤必須在分類中。

⑤ **陳舊內容：** `updated` 日期比提到相同實體的最早來源晚了 90 天以上的頁面。

⑥ **矛盾：** 同一主題上具有衝突主張的頁面。尋找共享標籤/實體但陳述不同事實的頁面。

⑦ **頁面大小：** 標記超過 200 行的頁面 —— 這些是拆分的候選對象。

⑧ **標籤稽核：** 列出所有正在使用的標籤，標記任何不在 SCHEMA.md 分類中的標籤。

⑨ **日誌輪換：** 如果 log.md 超過 500 條記錄，進行輪換。

⑩ **報告結果**，註明具體的檔案路徑和建議的操作，按嚴重程度分組 (損壞的連結 > 孤立頁面 > 陳舊內容 > 格式問題)。

⑪ **追加至 log.md**：`## [YYYY-MM-DD] lint | 發現 N 個問題`

## 使用 Wiki

### 搜尋

```bash
# 按內容查找頁面
search_files "transformer" path="$WIKI" file_glob="*.md"

# 按檔案名稱查找頁面
search_files "*.md" target="files" path="$WIKI"

# 按標籤查找頁面
search_files "tags:.*alignment" path="$WIKI" file_glob="*.md"

# 最近活動
read_file "$WIKI/log.md" offset=<最後 20 行>
```

### 批量攝入 (Bulk Ingest)

一次攝入多個來源時，請批次處理更新：
1. 先閱讀所有來源
2. 識別所有來源中的實體和概念
3. 檢查所有這些實體的現有頁面 (一次搜尋，而非 N 次)
4. 一次性建立/更新頁面 (避免重複更新)
5. 最後更新一次 index.md
6. 編寫一條涵蓋該批次的日誌記錄

### 歸檔

當內容被完全取代或領域範圍發生變化時：
1. 如果 `_archive/` 目錄不存在，請先建立
2. 將頁面移動到 `_archive/` 並保留其原始路徑 (例如：`_archive/entities/old-page.md`)
3. 從 `index.md` 中移除
4. 更新所有連結到它的頁面 —— 將 wikilink 替換為純文字 + "(archived)"
5. 記錄歸檔操作

### Obsidian 整合

Wiki 目錄可以開箱即用地作為 Obsidian 儲存庫 (vault) 使用：
- `[[wikilinks]]` 會渲染為可點擊的連結
- 關係圖譜 (Graph View) 會將知識網路視覺化
- YAML frontmatter 為 Dataview 查詢提供支援
- `raw/assets/` 資料夾存放透過 `![[image.png]]` 引用的圖片

為了獲得最佳效果：
- 將 Obsidian 的附件資料夾設置為 `raw/assets/`
- 在 Obsidian 設置中啟用 "Wikilinks" (通常預設啟用)
- 安裝 Dataview 插件以執行類似 `TABLE tags FROM "entities" WHERE contains(tags, "company")` 的查詢

如果同時使用 Obsidian 技能，請將 `OBSIDIAN_VAULT_PATH` 設置為與 wiki 路徑相同的目錄。

### Obsidian 無介面模式 (伺服器和無顯示器機器)

在沒有顯示器的機器上，使用 `obsidian-headless` 而非桌面應用程式。
它可以在沒有 GUI 的高度同步儲存庫 —— 非常適合在伺服器上運行的 Agent 在寫入 wiki 的同時，讓另一台設備上的 Obsidian 桌面版讀取。

**設定：**
```bash
# 需要 Node.js 22+
npm install -g obsidian-headless

# 登入 (需要具有 Sync 訂閱的 Obsidian 帳號)
ob login --email <email> --password '<password>'

# 為 wiki 建立遠端儲存庫
ob sync-create-remote --name "LLM Wiki"

# 將 wiki 目錄連接到儲存庫
cd ~/wiki
ob sync-setup --vault "<vault-id>"

# 初始同步
ob sync

# 持續同步 (前景運行 —— 背景運行請使用 systemd)
ob sync --continuous
```

**透過 systemd 進行持續背景同步：**
```ini
# ~/.config/systemd/user/obsidian-wiki-sync.service
[Unit]
Description=Obsidian LLM Wiki Sync
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/path/to/ob sync --continuous
WorkingDirectory=/home/user/wiki
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now obsidian-wiki-sync
# 啟用 linger 以便同步在登出後繼續：
sudo loginctl enable-linger $USER
```

這讓 Agent 可以寫入伺服器上的 `~/wiki`，同時您可以在筆記型電腦/手機上的 Obsidian 中瀏覽同一個儲存庫 —— 更改會在幾秒鐘內出現。

## 常見陷阱

- **絕不修改 `raw/` 中的文件** —— 來源是不可變的。修正應寫在 wiki 頁面中。
- **務必先瞭解現況** —— 在新對話中進行任何操作之前，請先閱讀 SCHEMA + 索引 + 最近的日誌。跳過此步驟會導致重複內容和遺漏交叉引用。
- **務必更新 index.md 和 log.md** —— 跳過此步驟會使 wiki 惡化。它們是導覽的骨幹。
- **不要為隨口提及建立頁面** —— 遵循 SCHEMA.md 中的頁面建立門檻。在腳註中出現一次的名字不需要實體頁面。
- **不要在沒有交叉引用的情況下建立頁面** —— 孤立的頁面是不可見的。每頁必須連結到至少 2 個其他頁面。
- **Frontmatter 是必需的** —— 它支持搜尋、過濾和陳舊內容檢測。
- **標籤必須來自分類** —— 自由形式的標籤會退化為雜訊。先將新標籤添加到 SCHEMA.md，然後再使用。
- **保持頁面易於瀏覽** —— 一個 wiki 頁面應該在 30 秒內讀完。拆分超過 200 行的頁面。將詳細分析移至專門的深度探究頁面。
- **在大量更新前詢問** —— 如果一次攝入會觸及 10 個以上的現有頁面，請先與使用者確認範圍。
- **輪換日誌** —— 當 log.md 超過 500 條記錄時，將其重新命名為 `log-YYYY.md` 並重新開始。Agent 應在 lint 期間檢查日誌大小。
- **明確處理矛盾** —— 不要默默覆寫。記錄這兩種主張及其日期，在 frontmatter 中標記，並標記供使用者審查。
