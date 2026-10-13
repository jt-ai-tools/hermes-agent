# 編輯簡報

## 基於範本的工作流

當使用現有簡報作為範本時：

1. **分析現有投影片**：
   ```bash
   python scripts/thumbnail.py template.pptx
   python -m markitdown template.pptx
   ```
   查看 `thumbnails.jpg` 以了解版面配置，並查看 `markitdown` 的輸出來識別佔位文字。

2. **規劃投影片對應**：為每個內容區段選擇一個範本投影片。

   ⚠️ **使用多樣化的版面配置** — 單調的簡報是常見的失敗模式。不要預設使用基本的「標題 + 條列」投影片。主動尋找：
   - 多欄位版面（雙欄、三欄）
   - 圖片 + 文字組合
   - 滿版圖片搭配文字疊加
   - 引言或標註投影片
   - 章節分隔頁
   - 數據/數字標註
   - 圖示網格或圖示 + 文字列

   **避免：** 每張投影片都重複使用文字密集的相同版面。

   將內容類型與版面風格進行匹配（例如：關鍵點 → 條列式投影片，團隊資訊 → 多欄位，客戶見證 → 引言投影片）。

3. **解壓縮 (Unpack)**：`python scripts/office/unpack.py template.pptx unpacked/`

4. **建構簡報**（請親自執行，不要交給子代理人）：
   - 刪除不想要的投影片（從 `<p:sldIdLst>` 中移除）
   - 複製想要重複使用的投影片 (`add_slide.py`)
   - 在 `<p:sldIdLst>` 中重新排序投影片
   - **在步驟 5 之前完成所有結構性變更**

5. **編輯內容**：更新每個 `slide{N}.xml` 中的文字。
   **如果可用，請在此處使用子代理人** — 投影片是獨立的 XML 檔案，因此子代理人可以並行編輯。

6. **清理 (Clean)**：`python scripts/clean.py unpacked/`

7. **打包 (Pack)**：`python scripts/office/pack.py unpacked/ output.pptx --original template.pptx`

---

## 指令碼

| 指令碼 | 用途 |
|--------|---------|
| `unpack.py` | 擷取並美化 (pretty-print) PPTX |
| `add_slide.py` | 複製投影片或從版面配置建立 |
| `clean.py` | 移除孤立檔案 |
| `pack.py` | 重新打包並進行驗證 |
| `thumbnail.py` | 建立投影片的視覺網格 |

### unpack.py

```bash
python scripts/office/unpack.py input.pptx unpacked/
```

擷取 PPTX，美化 XML，並轉義智慧引號 (smart quotes)。

### add_slide.py

```bash
python scripts/add_slide.py unpacked/ slide2.xml      # 複製投影片
python scripts/add_slide.py unpacked/ slideLayout2.xml # 從版面配置建立
```

列印 `<p:sldId>` 以便新增到 `<p:sldIdLst>` 的指定位置。

### clean.py

```bash
python scripts/clean.py unpacked/
```

移除不在 `<p:sldIdLst>` 中的投影片、未被引用的媒體檔案以及孤立的關係定義 (rels)。

### pack.py

```bash
python scripts/office/pack.py unpacked/ output.pptx --original input.pptx
```

驗證、修復、壓縮 XML，並重新編碼智慧引號。

### thumbnail.py

```bash
python scripts/thumbnail.py input.pptx [輸出前綴] [--cols N]
```

建立 `thumbnails.jpg`，並以投影片檔名作為標籤。預設為 3 欄，每個網格最多 12 張。

**僅用於範本分析**（選擇版面配置）。對於視覺 QA，請使用 `soffice` + `pdftoppm` 來建立全解析度的單張投影片圖片 — 請參閱 SKILL_zh_TW.md。

---

## 投影片操作

投影片順序位於 `ppt/presentation.xml` → `<p:sldIdLst>` 中。

**重新排序**：重新排列 `<p:sldId>` 元素。

**刪除**：移除 `<p:sldId>`，然後執行 `clean.py`。

**新增**：使用 `add_slide.py`。絕不要手動複製投影片檔案 — 該指令碼會處理備註引用、`Content_Types.xml` 以及手動複製會遺漏的關係 ID。

---

## 編輯內容

**子代理人 (Subagents)**：如果可用，請在完成步驟 4 後使用。每張投影片都是獨立的 XML 檔案，因此子代理人可以並行編輯。在給子代理人的提示詞中，應包含：
- 要編輯的投影片檔案路徑
- **「所有變更均使用 Edit 工具」**
- 下方的格式規則和常見陷阱

針對每張投影片：
1. 讀取投影片的 XML
2. 識別「所有」佔位內容 — 文字、圖片、圖表、圖示、說明
3. 將每個佔位符替換為最終內容

**使用 Edit 工具，而非 `sed` 或 Python 指令碼。** Edit 工具強制要求明確指定替換內容及其位置，可靠性更高。

### 格式規則

- **標題、子標題和行內標籤使用粗體**：在 `<a:rPr>` 上使用 `b="1"`。這包括：
  - 投影片標題
  - 投影片內的區段標題
  - 位於行首的行內標籤（例如：「狀態：」、「描述：」）
- **絕對不要使用 Unicode 項目符號 (•)**：使用帶有 `<a:buChar>` 或 `<a:buAutoNum>` 的正確列表格式
- **項目符號一致性**：讓項目符號從版面配置繼承。僅在必要時指定 `<a:buChar>` 或 `<a:buNone>`。

---

## 常見陷阱

### 範本適配

當來源內容的項目少於範本時：
- **完全移除多餘的元素**（圖片、形狀、文字方塊），而不僅僅是清除文字
- 清除文字內容後，檢查是否有遺留的視覺效果
- 執行視覺 QA 以捕捉數量不匹配的問題

當使用不同長度的內容替換文字時：
- **較短的替換**：通常是安全的
- **較長的替換**：可能會溢出或產生非預期的換行
- 文字變更後，進行視覺 QA 測試
- 考慮截斷或分割內容，以符合範本的設計限制

**範本插槽 ≠ 來源項目**：如果範本有 4 個團隊成員，但來源只有 3 個，請刪除第 4 個成員的「整個」群組（圖片 + 文字方塊），而不僅僅是文字。

### 多個項目的內容

如果來源有多個項目（編號列表、多個區段），請為每個項目建立獨立的 `<a:p>` 元素 — **絕對不要連接成一個字串**。

**❌ 錯誤** — 所有項目都在同一個段落中：
```xml
<a:p>
  <a:r><a:rPr .../><a:t>步驟 1：執行第一件事。步驟 2：執行第二件事。</a:t></a:r>
</a:p>
```

**✅ 正確** — 使用帶有粗體標題的獨立段落：
```xml
<a:p>
  <a:pPr algn="l"><a:lnSpc><a:spcPts val="3919"/></a:lnSpc></a:pPr>
  <a:r><a:rPr lang="en-US" sz="2799" b="1" .../><a:t>步驟 1</a:t></a:r>
</a:p>
<a:p>
  <a:pPr algn="l"><a:lnSpc><a:spcPts val="3919"/></a:lnSpc></a:pPr>
  <a:r><a:rPr lang="en-US" sz="2799" .../><a:t>執行第一件事。</a:t></a:r>
</a:p>
<a:p>
  <a:pPr algn="l"><a:lnSpc><a:spcPts val="3919"/></a:lnSpc></a:pPr>
  <a:r><a:rPr lang="en-US" sz="2799" b="1" .../><a:t>步驟 2</a:t></a:r>
</a:p>
<!-- 延續此模式 -->
```

從原始段落複製 `<a:pPr>` 以保留行間距。在標題上使用 `b="1"`。

### 智慧引號 (Smart Quotes)

由 unpack/pack 自動處理。但 Edit 工具會將智慧引號轉換為 ASCII。

**新增包含引號的新文字時，請使用 XML 實體：**

```xml
<a:t>the &#x201C;Agreement&#x201D;</a:t>
```

| 字元 | 名稱 | Unicode | XML 實體 |
|-----------|------|---------|------------|
| `“` | 左雙引號 | U+201C | `&#x201C;` |
| `”` | 右雙引號 | U+201D | `&#x201D;` |
| `‘` | 左單引號 | U+2018 | `&#x2018;` |
| `’` | 右單引號 | U+2019 | `&#x2019;` |

### 其他

- **空白字元**：在帶有前導或尾隨空格的 `<a:t>` 上使用 `xml:space="preserve"`
- **XML 解析**：使用 `defusedxml.minidom`，不要使用 `xml.etree.ElementTree`（會損壞命名空間）
