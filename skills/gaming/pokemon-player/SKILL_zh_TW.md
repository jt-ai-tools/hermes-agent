---
name: pokemon-player
description: 透過 headless 模擬器自主玩 Pokemon 遊戲。啟動遊戲伺服器、從 RAM 讀取結構化遊戲狀態、做出策略決定並傳送按鍵輸入 —— 全都在終端機中完成。
tags: [gaming, pokemon, emulator, pyboy, gameplay, gameboy]
---
# Pokemon Player

使用 `pokemon-agent` 套件透過 headless 模擬器玩 Pokemon 遊戲。

## 何時使用
- 使用者說 "play pokemon"、"start pokemon"、"pokemon game"
- 使用者詢問關於 Pokemon Red、Blue、Yellow、FireRed 等版本
- 使用者想看 AI 玩 Pokemon
- 使用者提供 ROM 檔案 (.gb, .gbc, .gba)

## 啟動程序

### 1. 首次設定 (clone, venv, install)
GitHub 上的 Repo 是 NousResearch/pokemon-agent。複製它，然後設定 Python 3.10+ 虛擬環境。建議使用 uv (速度較快) 來建立 venv 並以 editable 模式安裝套件，並包含 pyboy extra。如果沒有 uv，則退而求其次使用 python3 -m venv + pip。

在這台機器上已經在 /home/teknium/pokemon-agent 設定好了且 venv 已就緒 —— 只要 cd 到該目錄並 source .venv/bin/activate 即可。

你還需要一個 ROM 檔案。詢問使用者的檔案。在這台機器上的該目錄內 roms/pokemon_red.gb 有一個。
絕對不要下載或提供 ROM 檔案 —— 務必詢問使用者。

### 2. 啟動遊戲伺服器
在啟動了 venv 的 pokemon-agent 目錄中，執行 `pokemon-agent serve`，並將 --rom 指向 ROM 檔案且 --port 設為 9876。使用 & 在背景執行。
若要從儲存的遊戲繼續，請加上 --load-state 並指定存檔名稱。
等待 4 秒啟動，然後透過 GET /health 驗證。

### 3. 為使用者設定即時儀表板 (Dashboard)
透過 localhost.run 使用 SSH 反向隧道，讓使用者可以在瀏覽器中查看儀表板。使用 ssh 連線，將本地連接埠 9876 轉發到遠端連接埠 80 (nokey@localhost.run)。將輸出重新導向到記錄檔，等待 10 秒，然後在記錄中 grep 找出 .lhr.life URL。提供 URL 給使用者，並在末尾加上 /dashboard/。
隧道 URL 每次都會更換 —— 如果重新啟動，請提供新的 URL 給使用者。

## 儲存與載入 (Save and Load)

### 何時儲存
- 每 15-20 回合遊戲
- 在道館戰、勁敵戰或冒險戰鬥之前「務必」儲存
- 進入新城鎮或迷宮之前
- 執行任何不確定的動作之前

### 如何儲存
使用 POST /save 並提供具描述性的名稱。良好的範例：
before_brock, route1_start, mt_moon_entrance, got_cut

### 如何載入
使用 POST /load 並提供存檔名稱。

### 列出可用存檔
GET /saves 會傳回所有儲存的狀態。

### 在伺服器啟動時載入
啟動伺服器時使用 --load-state 旗標自動載入存檔。這比啟動後透過 API 載入更快。

## 遊戲迴圈 (Gameplay Loop)

### 步驟 1：觀察 (OBSERVE) —— 檢查狀態「並」擷取螢幕截圖
GET /state 獲取位置、HP、戰鬥、對話。
GET /screenshot 並儲存至 /tmp/pokemon.png，然後使用 vision_analyze。
務必「兩者」都做 —— RAM 狀態提供數值，視覺 (vision) 提供空間感知。

### 步驟 2：定向 (ORIENT)
- 螢幕上的對話/文字 → 推進它
- 戰鬥中 → 戰鬥或逃跑
- 隊伍受傷 → 前往 Pokemon Center
- 接近目標 → 謹慎導航

### 步驟 3：決定 (DECIDE)
優先順序：對話 > 戰鬥 > 治療 > 劇情目標 > 訓練 > 探索

### 步驟 4：行動 (ACT) —— 最多移動 2-4 步，然後重新檢查
使用 POST /action 傳送「短」動作清單 (2-4 個動作，而非 10-15 個)。

### 步驟 5：驗證 (VERIFY) —— 每次移動序列後都要截圖
擷取螢幕截圖並使用 vision_analyze 確認你是否移動到預定位置。這是「最重要」的步驟。沒有視覺，你「一定」會迷路。

### 步驟 6：使用 PKM: 前綴記錄進度至記憶中

### 步驟 7：定期儲存

## 動作參考 (Action Reference)
- press_a —— 確認、交談、選擇
- press_b —— 取消、關閉選單
- press_start —— 開啟遊戲選單
- walk_up/down/left/right —— 移動一格 (tile)
- hold_b_N —— 按住 B 持續 N 幀 (用於加速對話文字)
- wait_60 —— 等待約 1 秒 (60 幀)
- a_until_dialog_end —— 重複按 A 直到對話結束

## 來自經驗的關鍵提示

### 持續使用視覺 (VISION)
- 每移動 2-4 步就擷取一次螢幕截圖
- RAM 狀態會告訴你位置和 HP，但「不會」告訴你周圍有什麼
- 平台、圍欄、告示牌、建築物門口、NPC —— 只能透過螢幕截圖看見
- 向視覺模型詢問具體問題：「我北邊的一格是什麼？」
- 卡住時，在嘗試隨機方向前務必先擷取螢幕截圖

### 地圖切換需要額外等待時間
走過門或樓梯時，地圖切換期間螢幕會變黑。你「務必」等待其完成。在任何門/樓梯傳送後加入 2-3 個 wait_60 動作。如果不等待，讀取到的位置會是舊的，你會以為還在舊地圖中。

### 建築物出口陷阱
走出建築物時，你會直接出現在門口「正前方」。如果你往北走，會直接走回室內。務必先向左或向右走 2 格「側步」，再朝預定方向前進。

### 對話處理
第一代 (Gen 1) 文字會逐字緩慢捲動。要加速對話，請按住 B 持續 120 幀然後按 A。視需要重複。按住 B 會讓文字以最高速顯示。然後按 A 推進到下一行。a_until_dialog_end 動作會檢查 RAM 的對話旗標，但此旗標並不適用於「所有」文字狀態。如果對話似乎卡住，請改用手動 hold_b + press_a 模式並透過螢幕截圖驗證。

### 平台是單向的
平台 (小懸崖邊緣) 只能跳「下」(南)，絕對不能爬「上」(北)。如果往北被平台擋住，你必須向左或向右尋找繞過去的缺口。使用視覺來識別缺口的方向。明確詢問視覺模型。

### 導航策略
- 一次移動 2-4 步，然後截圖檢查位置
- 進入新區域時，立即截圖以定向
- 詢問視覺模型：「往 [目的地] 的方向是哪邊？」
- 如果嘗試 3 次以上仍卡住，截圖並重新全面評估
- 不要連發 10-15 次移動 —— 你會衝過頭或卡住

### 從野外戰鬥逃跑
在戰鬥選單中，RUN (逃跑) 在右下角。從預設游標位置 (FIGHT，左上角) 移動到該處：按「下」再按「右」將游標移至 RUN，然後按 A。配合 hold_b 以加速文字/動畫。

### 戰鬥 (FIGHT)
在戰鬥選單中，FIGHT 在左上角 (預設游標位置)。按 A 進入招式選擇，再按一次 A 使用第一個招式。然後按住 B 加速攻擊動畫與文字。

## 戰鬥策略

### 決策樹
1. 想要捕捉？ → 削弱後投擲 Poke Ball
2. 不需要野怪？ → RUN (逃跑)
3. 屬性優勢？ → 使用效果絕佳 (super-effective) 的招式
4. 無優勢？ → 使用最強的本系屬性一致 (STAB) 招式
5. HP 低？ → 換人或使用 Potion (傷藥)

### 第一代 (Gen 1) 屬性表 (關鍵對決)
- 水剋火、地面、岩石
- 火剋草、蟲、冰
- 草剋水、地面、岩石
- 電剋水、飛行
- 地面剋火、電、岩石、毒
- 超能力剋格鬥、毒 (第一代的主宰屬性！)

### 第一代怪癖
- 特殊 (Special) 數值 = 特殊招式的攻擊「與」防禦
- 超能力屬性過強 (幽靈招式有 bug)
- 會心一擊 (Critical hits) 基於速度 (Speed) 數值
- 緊束 (Wrap) / 綁緊 (Bind) 會阻止對手行動
- 聚氣 (Focus Energy) bug：會「降低」會心一擊率而非提高

## 記憶慣例 (Memory Conventions)
| 前綴 | 用途 | 範例 |
|--------|---------|---------|
| PKM:OBJECTIVE | 目前目標 | 從 Viridian Mart 取得包裹 (Parcel) |
| PKM:MAP | 導航知識 | Viridian：商店在東北方 |
| PKM:STRATEGY | 戰鬥/隊伍計畫 | 在小霞 (Misty) 之前需要草系 |
| PKM:PROGRESS | 里程碑追蹤 | 擊敗勁敵，正前往 Viridian |
| PKM:STUCK | 卡住的情況 | 在 y=28 有平台，向右繞過 |
| PKM:TEAM | 隊伍筆記 | 傑尼龜 Lv6, 撞擊 + 搖尾巴 |

## 進度里程碑
- 選擇初始寶可夢
- 從 Viridian Mart 送達包裹，獲得寶可夢圖鑑 (Pokedex)
- 深灰徽章 (Boulder Badge) —— 小剛 (Brock，岩石) → 使用水/草
- 華藍徽章 (Cascade Badge) —— 小霞 (Misty，水) → 使用草/電
- 枯葉徽章 (Thunder Badge) —— 馬志士 (Lt. Surge，電) → 使用地面
- 彩虹徽章 (Rainbow Badge) —— 艾莉嘉 (Erika，草) → 使用火/冰/飛行
- 淺紅徽章 (Soul Badge) —— 阿桔 (Koga，毒) → 使用地面/超能力
- 金黃徽章 (Marsh Badge) —— 娜姿 (Sabrina，超能力) → 最難的道館
- 紅蓮徽章 (Volcano Badge) —— 夏伯 (Blaine，火) → 使用水/地面
- 常青徽章 (Earth Badge) —— 坂木 (Giovanni，地面) → 使用水/草/冰
- 四天王 → 冠軍！

## 停止遊玩
1. 使用 POST /save 以具描述性的名稱儲存遊戲
2. 使用 PKM:PROGRESS 更新記憶
3. 告知使用者：「遊戲已儲存為 [名稱]！說 'play pokemon' 即可繼續。」
4. 刪除伺服器與隧道背景程序

## 常見陷阱
- 絕對不要下載或提供 ROM 檔案
- 在檢查視覺前，不要傳送超過 4-5 個動作
- 走出建築物後務必先側步，再往北走
- 在門/樓梯傳送後務必加上 wait_60 x2-3
- 透過 RAM 偵測對話並不完全可靠 —— 務必透過螢幕截圖驗證
- 在冒險戰鬥前儲存
- 每次重新啟動隧道時，URL 都會更換
