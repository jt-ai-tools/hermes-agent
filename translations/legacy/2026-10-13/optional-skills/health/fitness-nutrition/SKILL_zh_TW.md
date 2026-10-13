---
name: fitness-nutrition
description: >
  健身房訓練規劃與營養追蹤工具。透過 wger 資料庫，可依肌肉、器材或類別搜尋 690 多種運動項目。
  透過 USDA 食品資料中心，可查詢 38 萬多種食品的宏量營養素與熱量。
  可計算 BMI、TDEE、最大單次重量 (1RM)、宏量營養素分配以及體脂率 —— 純 Python 實作，無需額外安裝套件。
  專為追求增肌、減重或單純想吃得更健康的人士打造。
version: 1.0.0
authors:
  - haileymarshall
license: MIT
metadata:
  hermes:
    tags: [health, fitness, nutrition, gym, workout, diet, exercise]
    category: health
    prerequisites:
      commands: [curl, python3]
required_environment_variables:
  - name: USDA_API_KEY
    prompt: "USDA 食品資料中心 API 金鑰 (免費)"
    help: "您可以前往 https://fdc.nal.usda.gov/api-key-signup/ 免費獲取 —— 或者跳過此項直接使用具有較低頻率限制的 DEMO_KEY"
    required_for: "進行食品/營養查詢時獲得更高的頻率限制 (DEMO_KEY 無需註冊即可使用)"
    optional: true
---

# 健身與營養

專業健身教練與運動營養師技能。結合兩個資料庫來源與離線計算機 —— 健身者所需的一切功能皆彙整於此。

**資料來源（均為免費且無額外依賴）：**

- **wger** (https://wger.de/api/v2/) —— 開源運動項目資料庫，包含 690 多種運動項目，並提供肌肉、器材與圖片資訊。公開端點無需驗證即可存取。
- **USDA 食品資料中心 (FoodData Central)** (https://api.nal.usda.gov/fdc/v1/) —— 美國政府營養資料庫，收錄 38 萬多種食品。使用 `DEMO_KEY` 可立即開始；免費註冊後可獲得更高頻率限制。

**離線計算機（使用 Python 標準函式庫）：**

- BMI、TDEE (Mifflin-St Jeor 公式)、最大單次重量 1RM (Epley/Brzycki/Lombardi 公式)、宏量營養素分配、體脂率 % (美國海軍法)

---

## 何時使用

當使用者詢問以下內容時觸發此技能：
- 運動項目、訓練計畫、健身房流程、肌群、訓練分法 (splits)
- 食品宏量營養素、熱量、蛋白質含量、飲食規劃、熱量計算
- 身體組成：BMI、體脂、TDEE、熱量盈餘/赤字
- 最大單次重量 (1RM) 估計、訓練強度百分比、漸進式超負荷
- 減脂、增肌或維持期的宏量營養素比例

---

## 執行流程

### 運動項目查詢 (wger API)

所有 wger 的公開端點均回傳 JSON 且無需身分驗證。在查詢運動項目時，務必加上 `format=json` 和 `language=2`（英文）。

**步驟 1 —— 辨識使用者需求：**

- 依肌肉查詢 → 使用 `/api/v2/exercise/?muscles={id}&language=2&status=2&format=json`
- 依類別查詢 → 使用 `/api/v2/exercise/?category={id}&language=2&status=2&format=json`
- 依器材查詢 → 使用 `/api/v2/exercise/?equipment={id}&language=2&status=2&format=json`
- 依名稱搜尋 → 使用 `/api/v2/exercise/search/?term={query}&language=english&format=json`
- 取得完整詳情 → 使用 `/api/v2/exerciseinfo/{exercise_id}/?format=json`

**步驟 2 —— 參考 ID（避免額外的 API 調用）：**

運動類別 (Exercise categories)：

| ID | 類別    |
|----|-------------|
| 8  | 手臂 (Arms) |
| 9  | 腿部 (Legs) |
| 10 | 腹部 (Abs)  |
| 11 | 胸部 (Chest)|
| 12 | 背部 (Back) |
| 13 | 肩部 (Shoulders) |
| 14 | 小腿 (Calves) |
| 15 | 有氧 (Cardio) |

肌肉 (Muscles)：

| ID | 肌肉名稱                  | ID | 肌肉名稱                 |
|----|---------------------------|----|-------------------------|
| 1  | 肱二頭肌 (Biceps brachii)  | 2  | 前三角肌 (Anterior deltoid) |
| 3  | 前鋸肌 (Serratus anterior)| 4  | 胸大肌 (Pectoralis major)|
| 5  | 腹外斜肌 (Obliquus externus)| 6  | 腓腸肌 (Gastrocnemius)  |
| 7  | 腹直肌 (Rectus abdominis) | 8  | 臀大肌 (Gluteus maximus)|
| 9  | 斜方肌 (Trapezius)        | 10 | 股四頭肌 (Quadriceps femoris)|
| 11 | 股二頭肌 (Biceps femoris)  | 12 | 闊背肌 (Latissimus dorsi)|
| 13 | 肱肌 (Brachialis)         | 14 | 肱三頭肌 (Triceps brachii)|
| 15 | 比目魚肌 (Soleus)          |    |                         |

器材 (Equipment)：

| ID | 器材名稱      |
|----|----------------|
| 1  | 槓鈴 (Barbell) |
| 3  | 啞鈴 (Dumbbell)|
| 4  | 健身墊 (Gym mat)|
| 5  | 抗力球 (Swiss Ball)|
| 6  | 單槓 (Pull-up bar)|
| 7  | 無 (徒手訓練 bodyweight)|
| 8  | 長凳 (Bench)   |
| 9  | 斜凳 (Incline bench)|
| 10 | 壺鈴 (Kettlebell)|

**步驟 3 —— 獲取並呈現結果：**

```bash
# 依名稱搜尋運動項目
QUERY="$1"
ENCODED=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$QUERY")
curl -s "https://wger.de/api/v2/exercise/search/?term=${ENCODED}&language=english&format=json" \
  | python3 -c "
import json,sys
data=json.load(sys.stdin)
for s in data.get('suggestions',[])[:10]:
    d=s.get('data',{})
    print(f\"  ID {d.get('id','?'):>4} | {d.get('name','N/A'):<35} | 類別: {d.get('category','N/A')}\")
"
```

```bash
# 取得特定運動項目的完整詳情
EXERCISE_ID="$1"
curl -s "https://wger.de/api/v2/exerciseinfo/${EXERCISE_ID}/?format=json" \
  | python3 -c "
import json,sys,html,re
data=json.load(sys.stdin)
trans=[t for t in data.get('translations',[]) if t.get('language')==2]
t=trans[0] if trans else data.get('translations',[{}])[0]
desc=re.sub('<[^>]+>','',html.unescape(t.get('description','N/A')))
print(f\"運動項目  : {t.get('name','N/A')}\")
print(f\"類別      : {data.get('category',{}).get('name','N/A')}\")
print(f\"主要肌肉  : {', '.join(m.get('name_en','') for m in data.get('muscles',[])) or 'N/A'}\")
print(f\"次要肌肉  : {', '.join(m.get('name_en','') for m in data.get('muscles_secondary',[])) or '無'}\")
print(f\"器材      : {', '.join(e.get('name','') for e in data.get('equipment',[])) or '徒手訓練'}\")
print(f\"執行方法  : {desc[:500]}\")
imgs=data.get('images',[])
if imgs: print(f\"圖片連結  : {imgs[0].get('image','')}\")
"
```

```bash
# 依肌肉、類別或器材過濾列出運動項目
# 可視需求組合過濾條件: ?muscles=4&equipment=1&language=2&status=2
FILTER="$1"  # 例如 "muscles=4" 或 "category=11" 或 "equipment=3"
curl -s "https://wger.de/api/v2/exercise/?${FILTER}&language=2&status=2&limit=20&format=json" \
  | python3 -c "
import json,sys
data=json.load(sys.stdin)
print(f'找到 {data.get(\"count\",0)} 項運動項目。')
for ex in data.get('results',[]):
    print(f\"  ID {ex['id']:>4} | 肌肉: {ex.get('muscles',[])} | 器材: {ex.get('equipment',[])}\")
"
```

### 營養資訊查詢 (USDA 食品資料中心)

若有設定 `USDA_API_KEY` 環境變數則使用之，否則回退到 `DEMO_KEY`。
`DEMO_KEY` = 每小時 30 次請求。免費註冊金鑰 = 每小時 1,000 次請求。

```bash
# 依名稱搜尋食品
FOOD="$1"
API_KEY="${USDA_API_KEY:-DEMO_KEY}"
ENCODED=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$FOOD")
curl -s "https://api.nal.usda.gov/fdc/v1/foods/search?api_key=${API_KEY}&query=${ENCODED}&pageSize=5&dataType=Foundation,SR%20Legacy" \
  | python3 -c "
import json,sys
data=json.load(sys.stdin)
foods=data.get('foods',[])
if not foods: print('找不到該食品。'); sys.exit()
for f in foods:
    n={x['nutrientName']:x.get('value','?') for x in f.get('foodNutrients',[])}
    cal=n.get('Energy','?'); prot=n.get('Protein','?')
    fat=n.get('Total lipid (fat)','?'); carb=n.get('Carbohydrate, by difference','?')
    print(f\"{f.get('description','N/A')}\")
    print(f\"  每 100g：{cal} kcal | {prot}g 蛋白質 | {fat}g 脂肪 | {carb}g 碳水\")
    print(f\"  FDC ID：{f.get('fdcId','N/A')}\")
    print()
"
```

```bash
# 依 FDC ID 取得詳細營養分析
FDC_ID="$1"
API_KEY="${USDA_API_KEY:-DEMO_KEY}"
curl -s "https://api.nal.usda.gov/fdc/v1/food/${FDC_ID}?api_key=${API_KEY}" \
  | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(f\"食品名稱：{d.get('description','N/A')}\")
print(f\"{'營養素':<40} {'含量':>8} {'單位'}\")
print('-'*56)
for x in sorted(d.get('foodNutrients',[]),key=lambda x:x.get('nutrient',{}).get('rank',9999)):
    nut=x.get('nutrient',{}); amt=x.get('amount',0)
    if amt and float(amt)>0:
        print(f\"  {nut.get('name',''):<38} {amt:>8} {nut.get('unitName','')}\")
"
```

### 離線計算機

對於批次操作，請使用 `scripts/` 中的輔助腳本，對於單次計算則可直接執行：

- `python3 scripts/body_calc.py bmi <體重_kg> <身高_cm>`
- `python3 scripts/body_calc.py tdee <體重_kg> <身高_cm> <年齡> <M|F> <活動量 1-5>`
- `python3 scripts/body_calc.py 1rm <重量> <次數>`
- `python3 scripts/body_calc.py macros <tdee_kcal> <減脂 cut|維持 maintain|增肌 bulk>`
- `python3 scripts/body_calc.py bodyfat <M|F> <頸圍_cm> <腰圍_cm> [臀圍_cm] <身高_cm>`

各公式背後的科學依據請參閱 `references/FORMULAS.md`。

---

## 常見陷阱

- wger 運動項目端點預設會回傳**所有語言** —— 務必加上 `language=2` 以獲取英文資訊。
- wger 包含**未經核實的使用者提交內容** —— 加上 `status=2` 以僅獲取已核准的運動項目。
- USDA `DEMO_KEY` 有**每小時 30 次請求**的限制 —— 在批次請求之間加上 `sleep 2` 或註冊免費金鑰。
- USDA 資料是以**每 100g** 為單位 —— 請提醒使用者依其實際食用量進行縮放。
- BMI 無法區分肌肉與脂肪 —— 肌肉發達人士的高 BMI 並不一定代表不健康。
- 體脂率公式僅為**估計值** (±3-5%) —— 追求精確度時建議進行 DEXA 掃描。
- 1RM 公式在超過 10 次重複時精確度會下降 —— 建議使用 3-5 次的組數進行最佳估計。
- wger 的 `exercise/search` 端點使用的參數名稱是 `term` 而非 `query`。

---

## 驗證

執行運動項目搜尋後：確認結果包含運動名稱、肌群和器材。
執行營養資訊查詢後：確認回傳每 100g 的宏量營養素，包含熱量 (kcal)、蛋白質、脂肪、碳水。
執行計算機後：檢查輸出結果是否合理（例如大多數成人的 TDEE 應在 1500-3500 之間）。

---

## 快速參考

| 任務 | 來源 | 端點 (Endpoint) |
|------|--------|----------|
| 依名稱搜尋運動項目 | wger | `GET /api/v2/exercise/search/?term=&language=english` |
| 運動項目詳情 | wger | `GET /api/v2/exerciseinfo/{id}/` |
| 依肌肉過濾 | wger | `GET /api/v2/exercise/?muscles={id}&language=2&status=2` |
| 依器材過濾 | wger | `GET /api/v2/exercise/?equipment={id}&language=2&status=2` |
| 列出類別 | wger | `GET /api/v2/exercisecategory/` |
| 列出肌肉 | wger | `GET /api/v2/muscle/` |
| 搜尋食品 | USDA | `GET /fdc/v1/foods/search?query=&dataType=Foundation,SR Legacy` |
| 食品詳情 | USDA | `GET /fdc/v1/food/{fdcId}` |
| BMI / TDEE / 1RM / 宏量營養素 | 離線 | `python3 scripts/body_calc.py` |
