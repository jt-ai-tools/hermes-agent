# Hermes Agent — 網頁介面 (Web UI)

基於瀏覽器的儀表板，用於管理 Hermes Agent 配置、API 金鑰以及監控作用中的會話。

## 技術棧 (Stack)

- **Vite** + **React 19** + **TypeScript**
- 具備自訂深色主題的 **Tailwind CSS v4**
- **shadcn/ui** 風格的元件（手寫實作，不依賴 CLI）

## 開發

```bash
# 啟動後端 API 伺服器
cd ../
python -m hermes_cli.main web --no-open

# 在另一個終端機，啟動 Vite 開發伺服器（具備 HMR + API 代理）
cd web/
npm run dev
```

Vite 開發伺服器會將 `/api` 請求代理到 `http://127.0.0.1:9119`（FastAPI 後端）。

## 建置 (Build)

```bash
npm run build
```

這會輸出到 `../hermes_cli/web_dist/`，FastAPI 伺服器將其作為靜態單頁應用程式 (SPA) 提供服務。建置好的資產會透過 `pyproject.toml` 的 package-data 包含在 Python 套件中。

## 結構

```
src/
├── components/ui/   # 可重複使用的 UI 原語 (Card, Badge, Button, Input 等)
├── lib/
│   ├── api.ts       # API 用戶端 —— 為所有後端端點提供具類型的 fetch 封裝
│   └── utils.ts     # 用於 Tailwind 類別合併的 cn() 輔助函式
├── pages/
│   ├── StatusPage   # 代理程式狀態、作用中/最近的會話
│   ├── ConfigPage   # 動態配置編輯器（從後端讀取 Schema）
│   └── EnvPage      # API 金鑰管理，具備儲存/清除功能
├── App.tsx          # 主要佈局與導覽
├── main.tsx         # React 入口點
└── index.css        # Tailwind 匯入與主題變數
```
