# Gemini OAuth 提供者 — 實作計劃 (Gemini OAuth Provider — Implementation Plan)

## 目標 (Goal)
新增一個第一級的 `gemini` 提供者，透過 Google OAuth 進行身分驗證，使用標準的 Gemini API（而非 Cloud Code Assist）。擁有 Google AI 訂閱或 Gemini API 存取權限的使用者可以透過瀏覽器進行身分驗證，而無需手動複製 API 金鑰。

## 架構決策 (Architecture Decision)
- **路徑 A (已選定)：** 位於 `generativelanguage.googleapis.com/v1beta/openai/` 的標準 Gemini API。
- **非路徑 B：** Cloud Code Assist (`cloudcode-pa.googleapis.com`) —— 存在流量限制的免費層級、內部 API、帳號遭封禁風險。
- 透過 OpenAI SDK 使用標準的 `chat_completions` api_mode —— 無需新增 api_mode。
- 使用我們自己的 OAuth 憑證 —— **不**與 Gemini CLI 共享權杖 (Token)。

## OAuth 流程 (OAuth Flow)
- **類型：** 授權碼 (Authorization Code) + PKCE (S256) —— 與 clawdbot/pi-mono 相同的模式。
- **認證 URL：** `https://accounts.google.com/o/oauth2/v2/auth`
- **權杖 URL：** `https://oauth2.googleapis.com/token`
- **重新導向：** `http://localhost:8085/oauth2callback` (本地回呼伺服器)。
- **回退方案：** 針對遠端/WSL/無介面 (headless) 環境，支援手動貼上 URL。
- **權限範圍 (Scopes)：** `https://www.googleapis.com/auth/cloud-platform`, `https://www.googleapis.com/auth/userinfo.email`
- **PKCE：** S256 程式碼挑戰 (code challenge)，32 位元組隨機驗證器 (verifier)。

## 用戶端 ID (Client ID)
- 需要在 Nous Research GCP 專案上註冊一個「桌面應用程式 (Desktop app)」OAuth 用戶端。
- 在程式碼中包含 client_id + client_secret (Google 認為安裝的應用程式密鑰是非機密的)。
- 替代方案：接受透過環境變數提供使用者自定義的 client_id 作為覆寫。

## 權杖生命週期 (Token Lifecycle)
- 儲存於 `~/.hermes/gemini_oauth.json` (不與 `~/.gemini/oauth_creds.json` 共享)。
- 欄位：`client_id`, `client_secret`, `refresh_token`, `access_token`, `expires_at`, `email`
- 檔案權限：0o600。
- 在每次 API 呼叫前：檢查是否過期，若距離過期不到 5 分鐘則進行重新整理 (Refresh)。
- 重新整理：向權杖 URL 發送帶有 `grant_type=refresh_token` 的 POST 請求。
- 針對並行存取（多個代理人工作階段）使用檔案鎖定 (File locking)。

## API 整合 (API Integration)
- 基礎 URL (Base URL)：`https://generativelanguage.googleapis.com/v1beta/openai/`
- 認證：`Authorization: Bearer <access_token>` (作為 `api_key` 傳遞給 OpenAI SDK)。
- api_mode：`chat_completions` (標準)。
- 模型：gemini-2.5-pro, gemini-2.5-flash, gemini-2.0-flash 等。

## 需建立/修改的檔案

### 新增檔案
1. `agent/google_oauth.py` — OAuth 流程 (PKCE, 本地伺服器, 權杖交換, 重新整理)
   - `start_oauth_flow()` — 開啟瀏覽器，啟動回呼伺服器
   - `exchange_code()` — 程式碼 → 權杖
   - `refresh_access_token()` — 重新整理流程
   - `load_credentials()` / `save_credentials()` — 具備鎖定機制的檔案 I/O
   - `get_valid_access_token()` — 檢查過期，必要時進行重新整理
   - 約 200 行

### 需修改的既有檔案
2. `hermes_cli/auth.py` — 為 "gemini" 新增 ProviderConfig，設定 auth_type="oauth_google"
3. `hermes_cli/models.py` — 新增 Gemini 模型目錄
4. `hermes_cli/runtime_provider.py` — 新增 gemini 分支 (讀取 OAuth 權杖, 建構 OpenAI 客戶端)
5. `hermes_cli/main.py` — 新增 `_model_flow_gemini()`，並加入提供者選項
6. `hermes_cli/setup.py` — 新增 gemini 認證流程 (觸發瀏覽器 OAuth)
7. `run_agent.py` — 在 API 呼叫前重新整理權杖 (參考 Copilot 模式)
8. `agent/auxiliary_client.py` — 在輔助解析鏈中加入 gemini
9. `agent/model_metadata.py` — 新增 Gemini 模型上下文長度

### 測試
10. `tests/agent/test_google_oauth.py` — OAuth 流程單元測試
11. `tests/test_api_key_providers.py` — 新增 gemini 提供者測試

### 文檔 (Docs)
12. `website/docs/getting-started/quickstart.md` — 在提供者對照表中加入 gemini
13. `website/docs/user-guide/configuration.md` — Gemini 設定章節
14. `website/docs/reference/environment-variables.md` — 新增環境變數

## 預估規模
~400 行新程式碼, ~150 行修改, ~100 行測試, ~50 行文檔 = 總計約 700 行

## 必要條件 (Prerequisites)
- 註冊了桌面 OAuth 用戶端的 Nous Research GCP 專案
- 或者：接受透過 `HERMES_GEMINI_CLIENT_ID` 環境變數提供的用戶端 ID

## 參考實作
- clawdbot: `extensions/google/oauth.flow.ts` (PKCE + 本地伺服器)
- pi-mono: `packages/ai/src/utils/oauth/google-gemini-cli.ts` (相同流程)
- hermes-agent Copilot OAuth: `hermes_cli/main.py` `_copilot_device_flow()` (不同流程類型，但生命週期模式相同)
