---
sidebar_position: 10
title: "外觀與主題 (Skins & Themes)"
description: "使用內建和使用者定義的外觀來自定義 Hermes CLI"
---

# 外觀與主題 (Skins & Themes)

外觀 (Skins) 控制著 Hermes 命令列介面 (CLI) 的**視覺呈現**：橫幅顏色、旋轉圖示 (spinner) 的面孔與動詞、回應框標籤、品牌文本以及工具活動前綴。

對話風格與視覺風格是不同的概念：

- **性格 (Personality)** 改變代理程式的口吻和措辭。
- **外觀 (Skin)** 改變 CLI 的外觀。

## 切換外觀

```bash
/skin                # 顯示目前外觀並列出所有可用外觀
/skin ares           # 切換到內建外觀
/skin mytheme        # 切換到來自 ~/.hermes/skins/mytheme.yaml 的自定義外觀
```

或者在 `~/.hermes/config.yaml` 中設定預設外觀：

```yaml
display:
  skin: default
```

## 內建外觀

| 外觀 (Skin) | 描述 | 代理程式品牌名稱 | 視覺特性 |
|------|-------------|----------------|------------------|
| `default` | 經典 Hermes — 金色與可愛風 (kawaii) | `Hermes Agent` | 溫暖的金色邊框、玉米絲色 (cornsilk) 文本、旋轉圖示中的可愛表情。熟悉的雙蛇杖 (caduceus) 橫幅。乾淨且平易近人。 |
| `ares` | 戰神主題 — 深紅與青銅 | `Ares Agent` | 深紅邊框搭配青銅裝飾。強勢的旋轉圖示動詞（"鍛造中"、"行軍中"、"淬火鋼鐵"）。自定義的刀劍與盾牌 ASCII 藝術橫幅。 |
| `mono` | 單色 — 純淨灰階 | `Hermes Agent` | 全灰色 — 無彩色。邊框為 `#555555`，文本為 `#c9d1d9`。適合極簡終端設定或螢幕錄影。 |
| `slate` | 酷藍 — 工程師導向 | `Hermes Agent` | 寶藍色邊框 (`#4169e1`)，柔和藍色文本。沉穩且專業。無自定義旋轉圖示 — 使用預設面孔。 |
| `daylight` | 適用於亮色背景終端的亮色主題，具備深色文本與酷藍裝飾 | `Hermes Agent` | 專為白色或亮色終端設計。深石板色文本搭配藍色邊框、淺色狀態介面，以及在亮色終端配置中仍保持清晰可讀的自動補全選單。 |
| `warm-lightmode` | 適用於亮色背景終端的溫暖棕/金色文本 | `Hermes Agent` | 適用於亮色終端的溫暖羊皮紙色調。深棕色文本搭配馬鞍棕色裝飾、奶油色狀態介面。較為自然大地的風格，適合取代冷色調的 daylight 主題。 |
| `poseidon` | 海神主題 — 深藍與海泡綠 | `Poseidon Agent` | 深藍到海泡綠的漸層。海洋主題旋轉圖示（"測繪海流"、"探測深度"）。三叉戟 ASCII 藝術橫幅。 |
| `sisyphus` | 薛西弗斯主題 — 苦行般的灰階與堅持 | `Sisyphus Agent` | 淺灰色搭配強烈對比。巨石主題旋轉圖示（"推上山坡"、"重置巨石"、"忍受輪迴"）。巨石與山丘 ASCII 藝術橫幅。 |
| `charizard` | 火山主題 — 焦橙與餘燼色 | `Charizard Agent` | 溫暖焦橙到餘燼色的漸層。火焰主題旋轉圖示（"順著熱對流"、"測量燃燒"）。巨龍剪影 ASCII 藝術橫幅。 |

## 可配置鍵值的完整清單

### 顏色 (`colors:`)

控制整個 CLI 的所有顏色值。值為十六進位顏色字串。

| 鍵值 (Key) | 描述 | 預設 (`default` 外觀) |
|-----|-------------|--------------------------|
| `banner_border` | 啟動橫幅周圍的面板邊框 | `#CD7F32` (青銅色) |
| `banner_title` | 橫幅中的標題文字顏色 | `#FFD700` (金色) |
| `banner_accent` | 橫幅中的區段標題（可用工具等） | `#FFBF00` (琥珀色) |
| `banner_dim` | 橫幅中的暗淡文字（分隔符號、次要標籤） | `#B8860B` (暗金菊色) |
| `banner_text` | 橫幅中的本文文字（工具名稱、技能名稱） | `#FFF8DC` (玉米絲色) |
| `ui_accent` | 一般 UI 強調色（高亮顯示、活動元素） | `#FFBF00` |
| `ui_label` | UI 標籤和標籤 (tags) | `#4dd0e1` (鴨蛋藍) |
| `ui_ok` | 成功指示符（打勾符號、完成） | `#4caf50` (綠色) |
| `ui_error` | 錯誤指示符（失敗、被封鎖） | `#ef5350` (紅色) |
| `ui_warn` | 警告指示符（注意、核准提示） | `#ffa726` (橘色) |
| `prompt` | 互動式提示字元顏色 | `#FFF8DC` |
| `input_rule` | 輸入區域上方的水平線 | `#CD7F32` |
| `response_border` | 代理程式回應框周圍的邊框 (ANSI 跳脫序列) | `#FFD700` |
| `session_label` | 會話標籤顏色 | `#DAA520` |
| `session_border` | 會話 ID 暗淡邊框顏色 | `#8B8682` |
| `status_bar_bg` | TUI 狀態 / 用量列的背景顏色 | `#1a1a2e` |
| `voice_status_bg` | 語音模式狀態徽章的背景顏色 | `#1a1a2e` |
| `completion_menu_bg` | 自動補全選單清單的背景顏色 | `#1a1a2e` |
| `completion_menu_current_bg` | 活動自動補全列的背景顏色 | `#333355` |
| `completion_menu_meta_bg` | 自動補全元數據欄的背景顏色 | `#1a1a2e` |
| `completion_menu_meta_current_bg` | 活動自動補全元數據欄的背景顏色 | `#333355` |

### 旋轉圖示 (`spinner:`)

控制在等待 API 回應時顯示的動畫旋轉圖示。

| 鍵值 (Key) | 類型 | 描述 | 範例 |
|-----|------|-------------|---------|
| `waiting_faces` | 字串列表 | 等待 API 回應時循環顯示的面孔 | `["(⚔)", "(⛨)", "(▲)"]` |
| `thinking_faces` | 字串列表 | 模型推論期間循環顯示的面孔 | `["(⚔)", "(⌁)", "(<>)"]` |
| `thinking_verbs` | 字串列表 | 旋轉圖示訊息中顯示的動詞 | `["鍛造中", "策劃中", "錘鍊計劃中"]` |
| `wings` | [左, 右] 列表 | 旋轉圖示周圍的裝飾括號 | `[["⟪⚔", "⚔⟫"], ["⟪▲", "▲⟫"]]` |

當旋轉圖示的值為空（如 `default` 和 `mono`）時，會使用 `display.py` 中硬編碼的預設值。

### 品牌設定 (`branding:`)

在 CLI 介面中使用的文字字串。

| 鍵值 (Key) | 描述 | 預設值 |
|-----|-------------|---------|
| `agent_name` | 顯示在橫幅標題和狀態顯示中的名稱 | `Hermes Agent` |
| `welcome` | CLI 啟動時顯示的歡迎訊息 | `Welcome to Hermes Agent! Type your message or /help for commands.` |
| `goodbye` | 結束時顯示的訊息 | `Goodbye! ⚕` |
| `response_label` | 回應框頂部的標籤 | ` ⚕ Hermes ` |
| `prompt_symbol` | 使用者輸入提示前的符號 | `❯ ` |
| `help_header` | `/help` 指令輸出的標題文字 | `(^_^)? Available Commands` |

### 其他頂層鍵值

| 鍵值 (Key) | 類型 | 描述 | 預設值 |
|-----|------|-------------|---------|
| `tool_prefix` | 字串 | CLI 中工具輸出行前置的字元 | `┊` |
| `tool_emojis` | 字典 | 旋轉圖示和進度顯示的個別工具表情符號覆蓋 (`{tool_name: emoji}`) | `{}` |
| `banner_logo` | 字串 | 富文本標記 (Rich-markup) ASCII 藝術 Logo（取代預設的 HERMES_AGENT 橫幅） | `""` |
| `banner_hero` | 字串 | 富文本標記 (Rich-markup) 英雄圖案（取代預設的雙蛇杖藝術） | `""` |

## 自定義外觀

在 `~/.hermes/skins/` 下建立 YAML 檔案。使用者定義的外觀會繼承內建 `default` 外觀中缺失的值，因此您只需指定想要更改的鍵值。

### 完整自定義外觀 YAML 範本

```yaml
# ~/.hermes/skins/mytheme.yaml
# 完整的外觀範本 — 顯示所有鍵值。請刪除任何不需要的鍵值；
# 缺失的值會自動繼承自 'default' 外觀。

name: mytheme
description: 我的自定義主題

colors:
  banner_border: "#CD7F32"
  banner_title: "#FFD700"
  banner_accent: "#FFBF00"
  banner_dim: "#B8860B"
  banner_text: "#FFF8DC"
  ui_accent: "#FFBF00"
  ui_label: "#4dd0e1"
  ui_ok: "#4caf50"
  ui_error: "#ef5350"
  ui_warn: "#ffa726"
  prompt: "#FFF8DC"
  input_rule: "#CD7F32"
  response_border: "#FFD700"
  session_label: "#DAA520"
  session_border: "#8B8682"
  status_bar_bg: "#1a1a2e"
  voice_status_bg: "#1a1a2e"
  completion_menu_bg: "#1a1a2e"
  completion_menu_current_bg: "#333355"
  completion_menu_meta_bg: "#1a1a2e"
  completion_menu_meta_current_bg: "#333355"

spinner:
  waiting_faces:
    - "(⚔)"
    - "(⛨)"
    - "(▲)"
  thinking_faces:
    - "(⚔)"
    - "(⌁)"
    - "(<>)"
  thinking_verbs:
    - "處理中"
    - "分析中"
    - "計算中"
    - "評估中"
  wings:
    - ["⟪⚡", "⚡⟫"]
    - ["⟪●", "●⟫"]

branding:
  agent_name: "My Agent"
  welcome: "Welcome to My Agent! Type your message or /help for commands."
  goodbye: "See you later! ⚡"
  response_label: " ⚡ My Agent "
  prompt_symbol: "⚡ ❯ "
  help_header: "(⚡) Available Commands"

tool_prefix: "┊"

# 個別工具表情符號覆蓋（選填）
tool_emojis:
  terminal: "⚔"
  web_search: "🔮"
  read_file: "📄"

# 自定義 ASCII 藝術橫幅（選填，支援 Rich 標記）
# banner_logo: |
#   [bold #FFD700] MY AGENT [/]
# banner_hero: |
#   [#FFD700]  在此處放置自定義藝術  [/]
```

### 極簡自定義外觀範例

由於所有內容都繼承自 `default`，極簡外觀僅需更改不同之處：

```yaml
name: cyberpunk
description: 霓虹終端主題

colors:
  banner_border: "#FF00FF"
  banner_title: "#00FFFF"
  banner_accent: "#FF1493"

spinner:
  thinking_verbs: ["連線中", "解密中", "上傳中"]
  wings:
    - ["⟨⚡", "⚡⟩"]

branding:
  agent_name: "Cyber Agent"
  response_label: " ⚡ Cyber "

tool_prefix: "▏"
```

## Hermes Mod — 視覺化外觀編輯器

[Hermes Mod](https://github.com/cocktailpeanut/hermes-mod) 是一個由社群建立的網頁介面，用於視覺化地建立和管理外觀。您可以使用點擊式編輯器並獲得即時預覽，而無需手寫 YAML。

![Hermes Mod 外觀編輯器](https://raw.githubusercontent.com/cocktailpeanut/hermes-mod/master/nous.png)

**功能：**

- 列出所有內建與自定義外觀
- 在具備所有 Hermes 外觀欄位（顏色、旋轉圖示、品牌設定、工具前綴、工具表情符號）的視覺化編輯器中開啟任何外觀
- 根據文本提示生成 `banner_logo` 文字藝術
- 將上傳的圖像 (PNG, JPG, GIF, WEBP) 轉換為具備多種渲染風格（點字、ASCII 階梯、方塊、點點）的 `banner_hero` ASCII 藝術
- 直接儲存到 `~/.hermes/skins/`
- 透過更新 `~/.hermes/config.yaml` 來啟用外觀
- 顯示生成的 YAML 和即時預覽

### 安裝

**選項 1 — Pinokio (一鍵安裝)：**

在 [pinokio.computer](https://pinokio.computer) 上搜尋並一鍵安裝。

**選項 2 — npx (終端中最快的方式)：**

```bash
npx -y hermes-mod
```

**選項 3 — 手動安裝：**

```bash
git clone https://github.com/cocktailpeanut/hermes-mod.git
cd hermes-mod/app
npm install
npm start
```

### 使用方式

1. 啟動應用程式（透過 Pinokio 或終端）。
2. 開啟 **Skin Studio**。
3. 選擇要編輯的內建或自定義外觀。
4. 從文本生成 Logo 和/或上傳圖像作為英雄藝術。選擇渲染風格和寬度。
5. 編輯顏色、旋轉圖示、品牌設定和其他欄位。
6. 點擊 **Save** 將外觀 YAML 寫入到 `~/.hermes/skins/`。
7. 點擊 **Activate** 將其設定為目前外觀（更新 `config.yaml` 中的 `display.skin`）。

Hermes Mod 遵循 `HERMES_HOME` 環境變數，因此也適用於[個人設定檔 (profiles)](/docs/user-guide/profiles)。

## 運作備註

- 內建外觀從 `hermes_cli/skin_engine.py` 載入。
- 未知外觀會自動回退到 `default`。
- `/skin` 會立即為當前會話更新活動的 CLI 主題。
- `~/.hermes/skins/` 中的使用者外觀優先於同名的內建外觀。
- 透過 `/skin` 進行的外觀變更僅限於該會話。若要將外觀設定為永久預設值，請在 `config.yaml` 中進行設定。
- `banner_logo` 和 `banner_hero` 欄位支援 Rich 終端標記（例如 `[bold #FF0000]text[/]`），用於彩色 ASCII 藝術。
