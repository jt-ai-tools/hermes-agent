# 選用技能 (Optional Skills)

由 Nous Research 維護的官方技能，**預設不啟用**。

這些技能隨附於 hermes-agent 儲存庫中，但在設定過程中不會複製到
`~/.hermes/skills/`。可以透過技能中心（Skills Hub）探索這些技能：

```bash
hermes skills browse               # 瀏覽所有技能，官方技能優先顯示
hermes skills browse --source official  # 僅瀏覽官方選用技能
hermes skills search <query>       # 尋找標記為 "official" 的選用技能
hermes skills install <identifier> # 複製到 ~/.hermes/skills/ 並啟用
```

## 為什麼是選用的？

有些技能雖然有用，但並非每個用戶都廣泛需要：

- **特定領域整合** — 特定付費服務、專業化工具
- **實驗性功能** — 具備前景但尚未經過充分驗證
- **重量級依賴項** — 需要繁瑣的設定（API 密鑰、安裝程序）

透過將其設為選用，我們能保持預設技能組的精簡，同時仍為有需要的用戶提供經過策劃、測試且官方支援的技能。
