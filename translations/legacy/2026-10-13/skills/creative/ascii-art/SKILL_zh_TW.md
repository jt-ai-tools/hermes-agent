---
name: ascii-art
description: 使用 pyfiglet (571 種字體)、cowsay、boxes、toilet、圖像轉 ASCII、遠端 API (asciified, ascii.co.uk) 及 LLM 備案生成 ASCII 藝術。無需 API 金鑰。
version: 4.0.0
author: 0xbyt4, Hermes Agent
license: MIT
dependencies: []
metadata:
  hermes:
    tags: [ASCII, Art, Banners, Creative, Unicode, Text-Art, pyfiglet, figlet, cowsay, boxes]
    related_skills: [excalidraw]

---

# ASCII 藝術技能 (ASCII Art Skill)

提供多種工具以滿足不同的 ASCII 藝術需求。所有工具皆為本地 CLI 程式或免費的 REST API —— 無需 API 金鑰。

## 工具 1：文字橫幅 (pyfiglet —— 本地)

將文字渲染為大型 ASCII 藝術橫幅。內建 571 種字體。

### 設定

```bash
pip install pyfiglet --break-system-packages -q
```

### 用法

```bash
python3 -m pyfiglet "YOUR TEXT" -f slant
python3 -m pyfiglet "TEXT" -f doom -w 80    # 設定寬度
python3 -m pyfiglet --list_fonts             # 列出所有 571 種字體
```

### 推薦字體

| 風格 | 字體 | 最佳用途 |
|-------|------|----------|
| 簡潔現代 | `slant` | 專案名稱、標頭 |
| 大膽塊狀 | `doom` | 標題、標誌 (Logos) |
| 大型清晰 | `big` | 橫幅 |
| 經典橫幅 | `banner3` | 寬螢幕顯示 |
| 緊湊 | `small` | 副標題 |
| 網路龐克 | `cyberlarge` | 科技主題 |
| 3D 效果 | `3-d` | 啟動畫面 |
| 哥德風 | `gothic` | 戲劇性文字 |

### 提示

- 預覽 2-3 種字體並讓使用者挑選最喜歡的一種。
- 短文字 (1-8 個字元) 使用 `doom` 或 `block` 等細節豐富的字體效果最佳。
- 長文字使用 `small` 或 `mini` 等緊湊字體效果較好。

## 工具 2：文字橫幅 (asciified API —— 遠端，無需安裝)

將文字轉換為 ASCII 藝術的免費 REST API。支援 250 多種 FIGlet 字體。直接返回純文字 —— 無需解析。當未安裝 pyfiglet 或需要快速替代方案時使用。

### 用法 (透過終端機 curl)

```bash
# 基礎文字橫幅 (預設字體)
curl -s "https://asciified.thelicato.io/api/v2/ascii?text=Hello+World"

# 使用指定字體
curl -s "https://asciified.thelicato.io/api/v2/ascii?text=Hello&font=Slant"
curl -s "https://asciified.thelicato.io/api/v2/ascii?text=Hello&font=Doom"
curl -s "https://asciified.thelicato.io/api/v2/ascii?text=Hello&font=Star+Wars"
curl -s "https://asciified.thelicato.io/api/v2/ascii?text=Hello&font=3-D"
curl -s "https://asciified.thelicato.io/api/v2/ascii?text=Hello&font=Banner3"

# 列出所有可用字體 (返回 JSON 陣列)
curl -s "https://asciified.thelicato.io/api/v2/fonts"
```

### 提示

- 在 text 參數中將空格 URL 編碼為 `+`。
- 回應內容為純文字 ASCII 藝術 —— 無需 JSON 封裝，可直接顯示。
- 字體名稱區分大小寫；請使用 fonts 端點獲取精確名稱。
- 支援任何具備 curl 的終端機 —— 無需 Python 或 pip。

## 工具 3：Cowsay (訊息藝術)

經典工具，將文字封裝在對話氣泡中，並搭配 ASCII 字元。

### 設定

```bash
sudo apt install cowsay -y    # Debian/Ubuntu
# brew install cowsay         # macOS
```

### 用法

```bash
cowsay "Hello World"
cowsay -f tux "Linux rules"       # 企鵝 Tux
cowsay -f dragon "Rawr!"          # 恐龍
cowsay -f stegosaurus "Roar!"     # 劍龍
cowthink "Hmm..."                  # 思考氣泡
cowsay -l                          # 列出所有角色
```

### 可用角色 (50 多種)

`beavis.zen`, `bong`, `bunny`, `cheese`, `daemon`, `default`, `dragon`,
`dragon-and-cow`, `elephant`, `eyes`, `flaming-skull`, `ghostbusters`,
`hellokitty`, `kiss`, `kitty`, `koala`, `luke-koala`, `mech-and-cow`,
`meow`, `moofasa`, `moose`, `ren`, `sheep`, `skeleton`, `small`,
`stegosaurus`, `stimpy`, `supermilker`, `surgery`, `three-eyes`,
`turkey`, `turtle`, `tux`, `udder`, `vader`, `vader-koala`, `www`

### 眼睛/舌頭 修改器

```bash
cowsay -b "Borg"       # =_ = 眼睛
cowsay -d "Dead"       # x_x 眼睛
cowsay -g "Greedy"     # $_$ 眼睛
cowsay -p "Paranoid"   # @_@ 眼睛
cowsay -s "Stoned"     # *_* 眼睛
cowsay -w "Wired"      # O_O 眼睛
cowsay -e "OO" "Msg"   # 自定義眼睛
cowsay -T "U " "Msg"   # 自定義舌頭
```

## 工具 4：Boxes (裝飾性邊框)

在任何文字周圍繪製裝飾性的 ASCII 藝術邊框/外框。內建 70 多種設計。

### 設定

```bash
sudo apt install boxes -y    # Debian/Ubuntu
# brew install boxes         # macOS
```

### 用法

```bash
echo "Hello World" | boxes                    # 預設邊框
echo "Hello World" | boxes -d stone           # 石頭邊框
echo "Hello World" | boxes -d parchment       # 羊皮紙卷軸
echo "Hello World" | boxes -d cat             # 貓咪邊框
echo "Hello World" | boxes -d dog             # 狗狗邊框
echo "Hello World" | boxes -d unicornsay      # 獨角獸
echo "Hello World" | boxes -d diamonds        # 菱形圖案
echo "Hello World" | boxes -d c-cmt           # C 風格註釋
echo "Hello World" | boxes -d html-cmt        # HTML 註釋
echo "Hello World" | boxes -a c               # 文字置中
boxes -l                                       # 列出所有 70 多種設計
```

### 搭配 pyfiglet 或 asciified 使用

```bash
python3 -m pyfiglet "HERMES" -f slant | boxes -d stone
# 或者在未安裝 pyfiglet 的情況下：
curl -s "https://asciified.thelicato.io/api/v2/ascii?text=HERMES&font=Slant" | boxes -d stone
```

## 工具 5：TOIlet (彩色文字藝術)

類似 pyfiglet，但具備 ANSI 色彩效果和視覺濾鏡。非常適合美化終端機。

### 設定

```bash
sudo apt install toilet toilet-fonts -y    # Debian/Ubuntu
# brew install toilet                      # macOS
```

### 用法

```bash
toilet "Hello World"                    # 基礎文字藝術
toilet -f bigmono12 "Hello"            # 指定字體
toilet --gay "Rainbow!"                 # 彩虹上色
toilet --metal "Metal!"                 # 金屬質感效果
toilet -F border "Bordered"             # 加上邊框
toilet -F border --gay "Fancy!"         # 組合效果
toilet -f pagga "Block"                 # 方塊風格字體 (toilet 獨有)
toilet -F list                          # 列出可用濾鏡
```

### 濾鏡

`crop`, `gay` (彩虹), `metal`, `flip`, `flop`, `180`, `left`, `right`, `border`

**注意**：toilet 輸出的是用於色彩的 ANSI 轉義碼 —— 適用於終端機，但可能無法在所有情境下渲染（如純文字檔、部分聊天平台）。

## 工具 6：圖像轉 ASCII 藝術 (Image to ASCII Art)

將圖像 (PNG, JPEG, GIF, WEBP) 轉換為 ASCII 藝術。

### 選項 A：ascii-image-converter (推薦，現代化工具)

```bash
# 安裝
sudo snap install ascii-image-converter
# 或者：go install github.com/TheZoraiz/ascii-image-converter@latest
```

```bash
ascii-image-converter image.png                  # 基礎用法
ascii-image-converter image.png -C               # 彩色輸出
ascii-image-converter image.png -d 60,30         # 設定尺寸
ascii-image-converter image.png -b               # 點字 (Braille) 字元
ascii-image-converter image.png -n               # 負片/反相
ascii-image-converter https://url/image.jpg      # 直接輸入 URL
ascii-image-converter image.png --save-txt out   # 儲存為文字檔
```

### 選項 B：jp2a (輕量級，僅支援 JPEG)

```bash
sudo apt install jp2a -y
jp2a --width=80 image.jpg
jp2a --colors image.jpg              # 上色
```

## 工具 7：搜尋現成的 ASCII 藝術

從網路上搜尋精選的 ASCII 藝術。透過 `terminal` 使用 `curl`。

### 來源 A：ascii.co.uk (推薦用於尋找現成藝術)

收集了大量分類好的經典 ASCII 藝術。藝術內容位於 HTML 的 `<pre>` 標籤內。使用 curl 抓取頁面，再透過簡單的 Python 片段提取。

**URL 模式：** `https://ascii.co.uk/art/{subject}`

**步驟 1 —— 抓取頁面：**

```bash
curl -s 'https://ascii.co.uk/art/cat' -o /tmp/ascii_art.html
```

**步驟 2 —— 從 pre 標籤提取藝術內容：**

```python
import re, html
with open('/tmp/ascii_art.html') as f:
    text = f.read()
arts = re.findall(r'<pre[^>]*>(.*?)</pre>', text, re.DOTALL)
for art in arts:
    clean = re.sub(r'<[^>]+>', '', art)
    clean = html.unescape(clean).strip()
    if len(clean) > 30:
        print(clean)
        print('\n---\n')
```

**可用主題** (用於 URL 路徑)：
- 動物：`cat`, `dog`, `horse`, `bird`, `fish`, `dragon`, `snake`, `rabbit`, `elephant`, `dolphin`, `butterfly`, `owl`, `wolf`, `bear`, `penguin`, `turtle`
- 物品：`car`, `ship`, `airplane`, `rocket`, `guitar`, `computer`, `coffee`, `beer`, `cake`, `house`, `castle`, `sword`, `crown`, `key`
- 自然：`tree`, `flower`, `sun`, `moon`, `star`, `mountain`, `ocean`, `rainbow`
- 角色：`skull`, `robot`, `angel`, `wizard`, `pirate`, `ninja`, `alien`
- 節慶：`christmas`, `halloween`, `valentine`

**提示：**
- 保留藝術家的簽名/縮寫 —— 這是重要的禮儀。
- 每個頁面通常有多件作品 —— 為使用者挑選最合適的一件。
- 透過 curl 運作穩定，無需 JavaScript。

### 來源 B：GitHub Octocat API (有趣的彩蛋)

返回隨機的 GitHub Octocat 並附帶一句格言。無需認證。

```bash
curl -s https://api.github.com/octocat
```

## 工具 8：有趣的 ASCII 工具 (透過 curl)

這些免費服務會直接返回 ASCII 藝術 —— 非常適合作為趣味附加功能。

### QR Code 轉 ASCII 藝術

```bash
curl -s "qrenco.de/Hello+World"
curl -s "qrenco.de/https://example.com"
```

### 天氣轉 ASCII 藝術

```bash
curl -s "wttr.in/Taipei"          # 包含 ASCII 圖案的完整天氣報告
curl -s "wttr.in/Moon"            # ASCII 藝術形式的月相
curl -s "v2.wttr.in/Taipei"       # 詳細版本
```

## 工具 9：LLM 生成的自定義藝術 (備案)

當上述工具無法滿足需求時，使用這些 Unicode 字元直接生成 ASCII 藝術：

### 字元調色盤 (Character Palette)

**框線繪製：** `╔ ╗ ╚ ╝ ║ ═ ╠ ╣ ╦ ╩ ╬ ┌ ┐ └ ┘ │ ─ ├ ┤ ┬ ┴ ┼ ╭ ╮ ╰ ╯`

**方塊元素：** `░ ▒ ▓ █ ▄ ▀ ▌ ▐ ▖ ▗ ▘ ▝ ▚ ▞`

**幾何與符號：** `◆ ◇ ◈ ● ○ ◉ ■ □ ▲ △ ▼ ▽ ★ ☆ ✦ ✧ ◀ ▶ ◁ ▷ ⬡ ⬢ ⌂`

### 規則

- 最大寬度：每行 60 個字元 (終端機安全寬度)。
- 最大高度：橫幅 15 行，場景 25 行。
- 僅限等寬字體：輸出必須在固定寬度字體下正確顯示。

## 決策流程

1. **文字轉橫幅** → 若已安裝則使用 pyfiglet，否則透過 curl 使用 asciified API。
2. **訊息封裝在趣角色藝術中** → cowsay。
3. **加入裝飾性邊框/外框** → boxes (可搭配 pyfiglet/asciified 使用)。
4. **特定物品的藝術** (貓、火箭、龍) → 透過 curl 存取 ascii.co.uk 並進行解析。
5. **圖像轉 ASCII** → ascii-image-converter 或 jp2a。
6. **QR Code** → 透過 curl 存取 qrenco.de。
7. **天氣/月相藝術** → 透過 curl 存取 wttr.in。
8. **自定義/創意需求** → 使用 Unicode 調色盤透過 LLM 生成。
9. **工具未安裝** → 安裝它，或退而求其次選擇下一個選項。
