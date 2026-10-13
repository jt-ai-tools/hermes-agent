---
name: openclaw-migration
description: 將使用者的 OpenClaw 客製化足跡遷移至 Hermes Agent。匯入與 Hermes 相容的記憶、SOUL.md、命令核准清單、使用者技能以及從 ~/.openclaw 選取的工作區資產，並精確報告哪些內容無法遷移及其原因。
version: 1.0.0
author: Hermes Agent (Nous Research)
license: MIT
metadata:
  hermes:
    tags: [遷移, OpenClaw, Hermes, 記憶, 人格, 匯入]
    related_skills: [hermes-agent]
---

# OpenClaw -> Hermes 遷移

當使用者想要將其 OpenClaw 設定移至 Hermes Agent 且希望手動清理工作減至最少時，請使用此技能。

## CLI 命令

如需快速、非互動式的遷移，請使用內建的 CLI 命令：

```bash
hermes claw migrate              # 完整互動式遷移
hermes claw migrate --dry-run    # 預覽將被遷移的內容
hermes claw migrate --preset user-data   # 遷移但不包含機密
hermes claw migrate --overwrite  # 覆蓋現有的衝突
hermes claw migrate --source /自訂/路徑/.openclaw  # 自訂來源
```

該 CLI 命令會執行下方所述的相同遷移指令稿。當你想要透過 dry-run 預覽和逐項衝突解決來進行互動式、引導式的遷移時，請透過代理人使用此技能。

**首次設定：** `hermes setup` 精靈會自動偵測 `~/.openclaw`，並在設定開始前提供遷移選項。

## 此技能的作用

它使用 `scripts/openclaw_to_hermes.py` 來：

- 將 `SOUL.md` 匯入 Hermes 主目錄作為 `SOUL.md`
- 將 OpenClaw 的 `MEMORY.md` 和 `USER.md` 轉換為 Hermes 記憶條目
- 將 OpenClaw 命令核准模式合併到 Hermes 的 `command_allowlist` 中
- 遷移與 Hermes 相容的訊息傳遞設定，例如 `TELEGRAM_ALLOWED_USERS` 和 `MESSAGING_CWD`
- 將 OpenClaw 技能複製到 `~/.hermes/skills/openclaw-imports/`
- 選擇性地將 OpenClaw 工作區指令檔案複製到選定的 Hermes 工作區
- 將相容的工作區資產（如 `workspace/tts/`）鏡像到 `~/.hermes/tts/`
- 封存沒有直接 Hermes 目的地且非機密的文件
- 產生結構化報告，列出遷移的項目、衝突、跳過的項目及其原因

## 路徑解析

輔助指令稿位於此技能目錄中的：

- `scripts/openclaw_to_hermes.py`

當此技能從技能中心 (Skills Hub) 安裝時，正常位置為：

- `~/.hermes/skills/migration/openclaw-migration/scripts/openclaw_to_hermes.py`

請勿猜測像 `~/.hermes/skills/openclaw-migration/...` 這樣的較短路徑。

執行輔助程式前：

1. 優先使用安裝在 `~/.hermes/skills/migration/openclaw-migration/` 下的路徑。
2. 如果該路徑失敗，請檢查已安裝的技能目錄，並解析相對於已安裝 `SKILL.md` 的指令稿。
3. 僅在安裝位置缺失或技能被手動移動時，才將 `find` 作為最後手段。
4. 呼叫 terminal 工具時，請勿傳遞 `workdir: "~"`。請使用絕對目錄（如使用者的家目錄），或完全省略 `workdir`。

配合 `--migrate-secrets` 旗標，它還會匯入一小組受白名單保護且與 Hermes 相容的機密，目前包含：

- `TELEGRAM_BOT_TOKEN`

## 預設工作流程

1. 先透過 dry run 進行檢查。
2. 呈現簡單的摘要，說明哪些內容可以遷移、哪些內容無法遷移，以及哪些內容將被封存。
3. 如果 `clarify` 工具可用，請將其用於使用者決策，而非要求自由格式的文字回覆。
4. 如果 dry run 發現匯入的技能目錄存在衝突，請在執行前詢問如何處理。
5. 在執行前，請使用者在兩種受支援的遷移模式之間做出選擇。
6. 僅在使用者想要帶入工作區指令檔案時，才要求目標工作區路徑。
7. 使用符合的預設值 (preset) 和旗標執行遷移。
8. 總結結果，特別是：
   - 遷移了哪些內容
   - 封存了哪些內容供手動審查
   - 跳過了哪些內容及其原因

## 使用者互動協議

Hermes CLI 支援用於互動式提示的 `clarify` 工具，但其限制如下：

- 一次只能有一個選擇
- 最多 4 個預定義選項
- 一個自動產生的 `Other` 自由文字選項

它**不**支援在單個提示中進行真正的多選核取方塊。

對於每次 `clarify` 呼叫：

- 務必包含非空的 `question`
- 僅在真實的可選提示中包含 `choices`
- 保持 `choices` 為 2-4 個純文字選項
- 切勿發出佔位符或被截斷的選項（如 `...`）
- 切勿使用額外空格填充或裝飾選項
- 切勿在問題中包含虛假表單欄位（如「在此輸入目錄」、要填寫的空行或底線 `_____`）
- 對於開放式的路徑問題，僅詢問簡潔的句子；使用者在面板下方的正常 CLI 提示中輸入。

如果 `clarify` 呼叫返回錯誤，請檢查錯誤文字、修正負載 (payload)，然後使用有效的 `question` 和乾淨的選項重試一次。

當 `clarify` 可用且 dry run 顯示需要使用者決策時，你的**下一個動作必須是 `clarify` 工具呼叫**。
不要以正常的助理訊息結束該回合，例如：

- "Let me present the choices"
- "What would you like to do?"
- "Here are the options"

如果需要使用者決策，請在產生更多文字前透過 `clarify` 收集決策。
如果仍有多個未解決的決策，請勿在它們之間插入解釋性的助理訊息。收到一個 `clarify` 回應後，你的下一個動作通常應該是下一個必要的 `clarify` 呼叫。

每當 dry run 報告以下內容時，請將 `workspace-agents` 視為未解決的決策：

- `kind="workspace-agents"`
- `status="skipped"`
- reason 包含 `No workspace target was provided`

在這種情況下，你必須在執行前詢問工作區指令。不要默默地將其視為跳過的決定。

由於該限制，請使用此簡化的決策流程：

1. 對於 `SOUL.md` 衝突，使用 `clarify` 並提供如下選項：
   - `keep existing` (保留現有)
   - `overwrite with backup` (使用備份覆蓋)
   - `review first` (先審查)
2. 如果 dry run 顯示一個或多個 `kind="skill"` 項目具有 `status="conflict"`，使用 `clarify` 並提供如下選項：
   - `keep existing skills` (保留現有技能)
   - `overwrite conflicting skills with backup` (使用備份覆蓋衝突技能)
   - `import conflicting skills under renamed folders` (在重新命名後的資料夾下匯入衝突技能)
3. 對於工作區指令，使用 `clarify` 並提供如下選項：
   - `skip workspace instructions` (跳過工作區指令)
   - `copy to a workspace path` (複製到工作區路徑)
   - `decide later` (稍後決定)
4. 如果使用者選擇複製工作區指令，請發出開放式的 `clarify` 後續問題，要求提供**絕對路徑**。
5. 如果使用者選擇 `skip workspace instructions` 或 `decide later`，請在不帶 `--workspace-target` 的情況下繼續。
5. 對於遷移模式，使用 `clarify` 並提供這 3 個選項：
   - `user-data only` (僅使用者資料)
   - `full compatible migration` (完整相容遷移)
   - `cancel` (取消)
6. `user-data only` 表示：遷移使用者資料與相容設定，但**不**匯入白名單中的機密。
7. `full compatible migration` 表示：遷移相同的相容使用者資料，並在存在時匯入白名單中的機密。
8. 如果 `clarify` 不可用，請以正常文字詢問相同的問題，但仍將答案限制為 `user-data only`, `full compatible migration` 或 `cancel`。

執行守門員 (Execution gate)：

- 當 `No workspace target was provided` 導致的 `workspace-agents` 跳過仍未解決時，請勿執行。
- 解決它的唯一有效方式是：
  - 使用者明確選擇 `skip workspace instructions`
  - 使用者明確選擇 `decide later`
  - 使用者在選擇 `copy to a workspace path` 後提供工作區路徑
- dry run 中缺失工作區目標本身並非執行許可。
- 在任何必要的 `clarify` 決策未解決前，請勿執行。

使用這些確切的 `clarify` 負載形狀作為預設模式：

- `{"question":"您的現有 SOUL.md 與匯入的衝突。我該怎麼做？","choices":["keep existing","overwrite with backup","review first"]}`
- `{"question":"一個或多個匯入的 OpenClaw 技能在 Hermes 中已存在。我該如何處理這些技能衝突？","choices":["keep existing skills","overwrite conflicting skills with backup","import conflicting skills under renamed folders"]}`
- `{"question":"選擇遷移模式：僅遷移使用者資料，或執行包含白名單機密的完整相容遷移？","choices":["user-data only","full compatible migration","cancel"]}`
- `{"question":"您是否要將 OpenClaw 工作區指令檔案複製到某個 Hermes 工作區？","choices":["skip workspace instructions","copy to a workspace path","decide later"]}`
- `{"question":"請提供工作區指令應複製到的絕對路徑。"}`

## 決策與命令映射

精確地將使用者決策映射到命令旗標：

- 如果使用者針對 `SOUL.md` 選擇 `keep existing`，請**不要**加入 `--overwrite`。
- 如果使用者選擇 `overwrite with backup`，請加入 `--overwrite`。
- 如果使用者選擇 `review first`，請在執行前停止並審查相關檔案。
- If the user chooses `keep existing skills`, add `--skill-conflict skip`.
- If the user chooses `overwrite conflicting skills with backup`, add `--skill-conflict overwrite`.
- If the user chooses `import conflicting skills under renamed folders`, add `--skill-conflict rename`.
- 如果使用者選擇 `user-data only`，請使用 `--preset user-data` 執行，且**不要**加入 `--migrate-secrets`。
- 如果使用者選擇 `full compatible migration`，請使用 `--preset full --migrate-secrets` 執行。
- 僅在使用者明確提供絕對工作區路徑時，才加入 `--workspace-target`。
- 如果使用者選擇 `skip workspace instructions` 或 `decide later`，請不要加入 `--workspace-target`。

在執行前，請以純文字重申確切的命令計畫，並確保它符合使用者的選擇。

## 執行後報告規則

執行後，請將指令稿的 JSON 輸出視為事實來源。

1. 以 `report.summary` 為計數基礎。
2. 僅當項目的 `status` 確切為 `migrated` 時，才將其列在「成功遷移」下。
3. 除非報告顯示該項目為 `migrated`，否則不要宣稱衝突已解決。
4. 除非 `kind="soul"` 的報告項目具有 `status="migrated"`，否則不要說 `SOUL.md` 已被覆蓋。
5. 如果 `report.summary.conflict > 0`，請包含一個衝突章節，而不是默默暗示成功。
6. 如果計數與列出的項目不符，請在回應前修正清單以符合報告。
7. 在可用時包含報告中的 `output_dir` 路徑，以便使用者檢查 `report.json`, `summary.md`、備份和封存檔案。
8. 對於記憶或使用者設定檔溢位，除非報告明確顯示封存路徑，否則不要說條目已被封存。如果存在 `details.overflow_file`，請說明完整的溢位清單已匯出至該處。
9. 如果某項技能是在重新命名後的資料夾下匯入，請報告最終目的地並提及 `details.renamed_from`。
10. 如果存在 `report.skill_conflict_mode`，請將其視為選定匯入技能衝突政策的事實來源。
11. 如果某個項目的 `status="skipped"`，請勿將其描述為已覆蓋、已備份、已遷移或已解決。
12. 如果 `kind="soul"` 具有 `status="skipped"` 且原因為 `Target already matches source`，請說明其保持不變且不提及備份。
13. 如果重新命名的匯入技能其 `details.backup` 為空，請勿暗示現有的 Hermes 技能已被重新命名或備份。僅說明匯入的副本已被放置在新的目的地，並引用 `details.renamed_from` 作為保持在原位的預存資料夾。

## 遷移預設值 (Presets)

在正常使用中，優先使用這兩個預設值：

- `user-data`
- `full`

`user-data` 包含：

- `soul`
- `workspace-agents`
- `memory`
- `user-profile`
- `messaging-settings`
- `command-allowlist`
- `skills`
- `tts-assets`
- `archive`

`full` 包含 `user-data` 中的所有內容，加上：

- `secret-settings`

該輔助指令稿仍支援類別層級的 `--include` / `--exclude`，但請將其視為進階備用方案而非預設體驗。

## 命令

具備完整探索功能的 Dry run：

```bash
python3 ~/.hermes/skills/migration/openclaw-migration/scripts/openclaw_to_hermes.py
```

使用 terminal 工具時，優先使用絕對呼叫模式，例如：

```json
{"command":"python3 /home/USER/.hermes/skills/migration/openclaw-migration/scripts/openclaw_to_hermes.py","workdir":"/home/USER"}
```

使用 user-data 預設值的 Dry run：

```bash
python3 ~/.hermes/skills/migration/openclaw-migration/scripts/openclaw_to_hermes.py --preset user-data
```

執行 user-data 遷移：

```bash
python3 ~/.hermes/skills/migration/openclaw-migration/scripts/openclaw_to_hermes.py --execute --preset user-data --skill-conflict skip
```

執行完整相容遷移：

```bash
python3 ~/.hermes/skills/migration/openclaw-migration/scripts/openclaw_to_hermes.py --execute --preset full --migrate-secrets --skill-conflict skip
```

包含工作區指令的執行：

```bash
python3 ~/.hermes/skills/migration/openclaw-migration/scripts/openclaw_to_hermes.py --execute --preset user-data --skill-conflict rename --workspace-target "/absolute/workspace/path"
```

預設情況下，請勿使用 `$PWD` 或家目錄作為工作區目標。請先詢問明確的工作區路徑。

## 重要規則

1. 除非使用者明確要求立即繼續，否則在寫入前請先執行 dry run。
2. 預設情況下不要遷移機密。權杖、認證區塊、裝置憑證和原始網關設定應保留在 Hermes 之外，除非使用者明確要求遷移機密。
3. 除非使用者明確要求，否則不要默默覆蓋非空的 Hermes 目標。輔助指令稿在啟用覆蓋時會保留備份。
4. 務必向使用者提供跳過項目的報告。該報告是遷移的一部分，而非選配。
5. 優先使用主要的 OpenClaw 工作區 (`~/.openclaw/workspace/`) 而非 `workspace.default/`。僅在主要檔案缺失時才將預設工作區作為備選。
6. 即使在機密遷移模式下，也僅遷移具有乾淨 Hermes 目的地的機密。不支援的認證區塊仍必須報告為跳過。
7. 如果 dry run 顯示大型資產複製、衝突的 `SOUL.md` 或溢位的記憶條目，請在執行前單獨指出。
8. 如果使用者不確定，請預設為 `user-data only`。
9. 僅在使用者明確提供目的地工作區路徑時，才包含 `workspace-agents`。
10. 將類別層級的 `--include` / `--exclude` 視為進階逃生門，而非正常流程。
11. 如果 `clarify` 可用，不要以模糊的「您想做什麼？」結束 dry-run 摘要。請改用結構化的後續提示。
12. 當可以使用真正的選擇提示時，不要使用開放式的 `clarify` 提示。優先使用可選選項，自由文字僅用於絕對路徑或檔案審查請求。
13. 在 dry run 之後，如果仍有未解決的決策，絕不要在總結後停止。立即針對最高優先級的阻塞決策使用 `clarify`。
14. 後續問題的優先順序：
    - `SOUL.md` 衝突
    - 匯入技能衝突
    - 遷移模式
    - 工作區指令目的地
15. 不要承諾稍後在同一訊息中呈現選擇。應透過實際呼叫 `clarify` 來呈現。
16. 在遷移模式回答之後，明確檢查 `workspace-agents` 是否仍未解決。如果是，你的下一個動作必須是工作區指令的 `clarify` 呼叫。
17. 在任何 `clarify` 回答後，如果仍有另一個必要的決策，不要敘述剛決定的內容。立即詢問下一個必要的決策。

## 預期結果

成功執行後，使用者應具備：

- 已匯入的 Hermes 人格狀態
- 已填充 OpenClaw 轉換知識的 Hermes 記憶檔案
- 位於 `~/.hermes/skills/openclaw-imports/` 下的 OpenClaw 技能
- 一份顯示任何衝突、遺漏或不支援資料的遷移報告
