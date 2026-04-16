---
name: telephony
description: 為 Hermes 提供電話功能，無需更改核心工具。配置並持久化 Twilio 號碼、發送與接收 SMS/MMS、進行直接通話，並透過 Bland.ai 或 Vapi 撥打 AI 驅動的外撥電話。
version: 1.0.0
author: Nous Research
license: MIT
metadata:
  hermes:
    tags: [telephony, phone, sms, mms, voice, twilio, bland.ai, vapi, calling, texting]
    related_skills: [find-nearby, google-workspace, agentmail]
    category: productivity
---

# 電話通訊 (Telephony) — 無需更改核心工具即可擁有號碼、通話與簡訊功能

此選用技能為 Hermes 提供實用的電話功能，同時將電話通訊排除在核心工具列表之外。

它附帶一個輔助腳本 `scripts/telephony.py`，具有以下功能：
- 將服務商憑證儲存至 `~/.hermes/.env`
- 搜尋並購買 Twilio 電話號碼
- 記住擁有的號碼以供後續對話使用
- 從擁有的號碼發送 SMS / MMS
- 輪詢該號碼的收件簡訊，無需 Webhook 伺服器
- 使用 TwiML `<Say>` 或 `<Play>` 進行直接 Twilio 通話
- 將擁有的 Twilio 號碼匯入 Vapi
- 透過 Bland.ai 或 Vapi 撥打外撥 AI 電話

## 這解決了什麼問題

此技能旨在涵蓋用戶實際需要的實用電話任務：
- 外撥電話
- 傳送簡訊
- 擁有一個可重複使用的代理號碼
- 檢查稍後送達該號碼的訊息
- 在對話階段之間保留該號碼及相關 ID
- 為未來的入站 SMS 輪詢和其他自動化提供友善的電話身份

它 **並非** 將 Hermes 變成一個即時入站電話網關。入站 SMS 是透過輪詢 Twilio REST API 處理的。這對於許多工作流（包括通知和某些一次性驗證碼檢索）來說已經足夠，且無需增加核心 Webhook 基礎架構。

## 安全規則 — 強制執行

1. 在撥打電話或傳送簡訊前，務必進行確認。
2. 絕不撥打緊急號碼。
3. 絕不將電話功能用於騷擾、垃圾郵件、冒充或任何非法行為。
4. 將第三方電話號碼視為敏感操作數據：
   - 不要將它們儲存至 Hermes 記憶 (memory) 中
   - 除非用戶明確要求，否則不要將它們包含在技能文件、摘要或後續筆記中
5. 持久化 **代理擁有的 Twilio 號碼** 是可以接受的，因為那是用戶配置的一部分。
6. VoIP 號碼 **不保證** 能用於所有第三方 2FA（雙重驗證）流程。請謹慎使用並明確告知用戶預期。

## 決策樹 — 該使用哪種服務？

請使用此邏輯而非硬編碼的服務商路由：

### 1) "我希望 Hermes 擁有一個真實的電話號碼"
使用 **Twilio**。

原因：
- 購買並保留號碼的最簡單路徑
- 最佳的 SMS / MMS 支援
- 最簡單的入站 SMS 輪詢方案
- 通往未來入站 Webhook 或通話處理的最清晰路徑

使用情境：
- 稍後接收簡訊
- 發送部署警報 / Cron 通知
- 為代理維護一個可重複使用的電話身份
- 稍後實驗基於電話的認證流程

### 2) "我現在只需要最簡單的外撥 AI 電話"
使用 **Bland.ai**。

原因：
- 設定最快
- 只需要一個 API 金鑰
- 無需先自行購買/匯入號碼

權衡：
- 靈活性較低
- 語音品質尚可，但不是最好的

### 3) "我想要最好的對話式 AI 語音品質"
使用 **Twilio + Vapi**。

原因：
- Twilio 提供擁有的號碼
- Vapi 提供更好的對話式 AI 通話品質以及更多的語音/模型靈活性

建議流程：
1. 購買/儲存一個 Twilio 號碼
2. 將其匯入 Vapi
3. 儲存回傳的 `VAPI_PHONE_NUMBER_ID`
4. 使用 `ai-call --provider vapi`

### 4) "我想要撥打帶有自定義預錄語音訊息的電話"
使用帶有公開音訊 URL 的 **Twilio 直接通話 (direct call)**。

原因：
- 播放自定義 MP3 的最簡單方式
- 與 Hermes `text_to_speech` 搭配公開文件代管或隧道 (tunnel) 效果極佳

## 文件與持久化狀態

此技能在兩個位置持久化電話通訊狀態：

### `~/.hermes/.env`
用於長效服務商憑證和擁有的號碼 ID，例如：
- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `TWILIO_PHONE_NUMBER`
- `TWILIO_PHONE_NUMBER_SID`
- `BLAND_API_KEY`
- `VAPI_API_KEY`
- `VAPI_PHONE_NUMBER_ID`
- `PHONE_PROVIDER` (AI 通話服務商：bland 或 vapi)

### `~/.hermes/telephony_state.json`
用於僅限技能的狀態，應跨會話保留，例如：
- 記住的預設 Twilio 號碼 / SID
- 記住的 Vapi 電話號碼 ID
- 用於收件匣輪詢檢查點的最後一條入站訊息 SID/日期

這意味著：
- 下次載入技能時，`diagnose` 可以告訴你已配置的號碼
- `twilio-inbox --since-last --mark-seen` 可以從之前的檢查點繼續

## 定位輔助腳本

安裝此技能後，請依此方式定位腳本：

```bash
SCRIPT="$(find ~/.hermes/skills -path '*/telephony/scripts/telephony.py' -print -quit)"
```

如果 `SCRIPT` 為空，則表示技能尚未安裝。

## 安裝

這是一個官方選用技能，請從技能中心 (Skills Hub) 安裝：

```bash
hermes skills search telephony
hermes skills install official/productivity/telephony
```

## 服務商設定

### Twilio — 擁有的號碼、SMS/MMS、直接通話、入站 SMS 輪詢

請至以下網址註冊：
- https://www.twilio.com/try-twilio

然後將憑證儲存至 Hermes：

```bash
python3 "$SCRIPT" save-twilio ACXXXXXXXXXXXXXXXXXXXXXXXXXXXX your_auth_token_here
```

搜尋可用號碼：

```bash
python3 "$SCRIPT" twilio-search --country US --area-code 702 --limit 5
```

購買並記住號碼：

```bash
python3 "$SCRIPT" twilio-buy "+17025551234" --save-env
```

列出擁有的號碼：

```bash
python3 "$SCRIPT" twilio-owned
```

之後將其中之一設為預設：

```bash
python3 "$SCRIPT" twilio-set-default "+17025551234" --save-env
# 或
python3 "$SCRIPT" twilio-set-default PNXXXXXXXXXXXXXXXXXXXXXXXXXXXX --save-env
```

### Bland.ai — 最簡單的外撥 AI 通話

請至以下網址註冊：
- https://app.bland.ai

儲存配置：

```bash
python3 "$SCRIPT" save-bland your_bland_api_key --voice mason
```

### Vapi — 更好的對話式語音品質

請至以下網址註冊：
- https://dashboard.vapi.ai

先儲存 API 金鑰：

```bash
python3 "$SCRIPT" save-vapi your_vapi_api_key
```

將你擁有的 Twilio 號碼匯入 Vapi 並持久化回傳的電話號碼 ID：

```bash
python3 "$SCRIPT" vapi-import-twilio --save-env
```

如果你已知 Vapi 電話號碼 ID，直接儲存：

```bash
python3 "$SCRIPT" save-vapi your_vapi_api_key --phone-number-id vapi_phone_number_id_here
```

## 診斷當前狀態

隨時檢查技能已知內容：

```bash
python3 "$SCRIPT" diagnose
```

在後續對話恢復工作時，請先執行此命令。

## 常見工作流

### A. 購買代理號碼並在以後持續使用

1. 儲存 Twilio 憑證：
```bash
python3 "$SCRIPT" save-twilio AC... auth_token_here
```

2. 搜尋號碼：
```bash
python3 "$SCRIPT" twilio-search --country US --area-code 702 --limit 10
```

3. 購買號碼並儲存至 `~/.hermes/.env` + 狀態：
```bash
python3 "$SCRIPT" twilio-buy "+17025551234" --save-env
```

4. 下個對話，執行：
```bash
python3 "$SCRIPT" diagnose
```
這將顯示記住的預設號碼和收件匣檢查點狀態。

### B. 從代理號碼發送簡訊

```bash
python3 "$SCRIPT" twilio-send-sms "+15551230000" "您的部署已成功完成。"
```

包含多媒體：

```bash
python3 "$SCRIPT" twilio-send-sms "+15551230000" "這是圖表。" --media-url "https://example.com/chart.png"
```

### C. 稍後檢查入站簡訊，無需 Webhook 伺服器

輪詢預設 Twilio 號碼的收件匣：

```bash
python3 "$SCRIPT" twilio-inbox --limit 20
```

僅顯示上次檢查點之後抵達的訊息，並在讀取完畢後更新檢查點：

```bash
python3 "$SCRIPT" twilio-inbox --since-last --mark-seen
```

這是「下次載入技能時，我如何存取該號碼收到的訊息？」的主要解答。

### D. 使用內建 TTS 進行直接 Twilio 通話

```bash
python3 "$SCRIPT" twilio-call "+15551230000" --message "您好！這是 Hermes 撥打的狀態更新電話。" --voice Polly.Joanna
```

### E. 撥打帶有預錄 / 自定義語音訊息的電話

這是重複使用 Hermes 現有 `text_to_speech` 支援的主要路徑。

適用於以下情況：
- 你希望通話使用 Hermes 配置的 TTS 語音，而非 Twilio 的 `<Say>`
- 你需要單向語音遞送（簡報、警報、笑話、提醒、狀態更新）
- 你 **不需要** 即時對話式電話通話

單獨生成或託管音訊，然後：

```bash
python3 "$SCRIPT" twilio-call "+155****0000" --audio-url "https://example.com/briefing.mp3"
```

建議的 Hermes TTS -> Twilio Play 工作流：

1. 使用 Hermes `text_to_speech` 生成音訊。
2. 使產生的 MP3 可公開存取。
3. 使用 `--audio-url` 撥打 Twilio 電話。

代理工作流示例：
- 要求 Hermes 使用 `text_to_speech` 建立訊息音訊
- 如果需要，透過臨時靜態託管 / 隧道 / 物件儲存 URL 公開文件
- 使用 `twilio-call --audio-url ...` 透過電話遞送

適合 MP3 的代管選項：
- 臨時公開的物件/儲存 URL
- 指向本地靜態文件伺服器的短期隧道
- 電話服務商可以直接獲取的任何現有 HTTPS URL

重要提示：
- Hermes TTS 非常適合預錄的外撥訊息
- Bland/Vapi 更適合 **即時對話式 AI 通話**，因為它們自行處理即時電話音訊棧
- Hermes STT/TTS 本身在這裡不被用作全雙工電話對話引擎；這需要比此技能嘗試引入的更重的串流/Webhook 整合

### F. 使用 Twilio 直接通話導覽電話樹 / IVR

如果通話接通後需要按鍵，請使用 `--send-digits`。
Twilio 將 `w` 解釋為短暫等待。

```bash
python3 "$SCRIPT" twilio-call "+18005551234" --message "正在連接到計費部門。" --send-digits "ww1w2w3"
```

這對於在移交給人工或遞送簡短狀態訊息之前抵達特定的選單分支非常有用。

### G. 使用 Bland.ai 進行外撥 AI 電話

```bash
python3 "$SCRIPT" ai-call "+15551230000" "撥打牙科診所，預約週二下午的洗牙。如果他們週二沒有空，請詢問週三或週四。" --provider bland --voice mason --max-duration 3
```

檢查狀態：

```bash
python3 "$SCRIPT" ai-status <call_id> --provider bland
```

完成後向 Bland 提出分析問題：

```bash
python3 "$SCRIPT" ai-status <call_id> --provider bland --analyze "預約確認了嗎？,日期和時間是什麼？,有任何特殊指示嗎？"
```

### H. 使用 Vapi 透過你擁有的號碼撥打外撥 AI 電話

1. 將你的 Twilio 號碼匯入 Vapi：
```bash
python3 "$SCRIPT" vapi-import-twilio --save-env
```

2. 撥打電話：
```bash
python3 "$SCRIPT" ai-call "+15551230000" "您正在打電話預約兩位在晚上 7:30 的晚餐。如果該時間不行，請詢問 6:30 到 8:30 之間最接近的時間。" --provider vapi --max-duration 4
```

3. 檢查結果：
```bash
python3 "$SCRIPT" ai-status <call_id> --provider vapi
```

## 建議的代理程序

當用戶要求撥打電話或傳送簡訊時：

1. 透過決策樹確定哪條路徑符合要求。
2. 如果配置狀態不明，執行 `diagnose`。
3. 收集完整的任務詳情。
4. 在撥號或傳送簡訊前與用戶確認。
5. 使用正確的命令。
6. 如果需要，輪詢結果。
7. 摘要結果，且不要將第三方號碼持久化到 Hermes 記憶中。

## 此技能仍無法做到的事

- 即時入站電話接聽
- 基於 Webhook 的即時 SMS 推送到代理循環
- 保證支援任意第三方 2FA 提供商

這些將需要比純選用技能更多的基礎設施。

## 陷阱

- Twilio 試用帳戶和區域規則可能會限制你可以撥打/傳送簡訊的對象。
- 某些服務會拒絕 VoIP 號碼進行 2FA。
- `twilio-inbox` 是輪詢 REST API；它不是即時推送。
- Vapi 外撥電話仍然依賴於擁有有效的匯入號碼。
- Bland 最簡單，但語音聽起來並不總是最好的。
- 不要將任意第三方電話號碼儲存在 Hermes 記憶中。

## 驗證清單

設定完成後，你應該能夠僅憑此技能完成以下所有操作：

1. `diagnose` 顯示服務商就緒情況和記住的狀態
2. 搜尋並購買 Twilio 號碼
3. 將該號碼持久化到 `~/.hermes/.env`
4. 從擁有的號碼發送 SMS
5. 稍後輪詢擁有的號碼的入站簡訊
6. 進行直接 Twilio 通話
7. 透過 Bland 或 Vapi 撥打 AI 電話

## 參考資料

- Twilio 電話號碼：https://www.twilio.com/docs/phone-numbers/api
- Twilio 簡訊：https://www.twilio.com/docs/messaging/api/message-resource
- Twilio 語音：https://www.twilio.com/docs/voice/api/call-resource
- Vapi 文件：https://docs.vapi.ai/
- Bland.ai：https://app.bland.ai/
