---
name: gitnexus-explorer
description: 使用 GitNexus 索引程式碼庫，並透過網頁 UI + Cloudflare 隧道 (Tunnel) 提供互動式知識圖譜。
version: 1.0.0
author: Hermes Agent + Teknium
license: MIT
metadata:
  hermes:
    tags: [gitnexus, code-intelligence, knowledge-graph, visualization]
    related_skills: [native-mcp, codebase-inspection]
---

# GitNexus 瀏覽器 (GitNexus Explorer)

將任何程式碼庫索引為知識圖譜，並提供互動式網頁 UI 以探索標識符 (Symbols)、呼叫鏈、群集和執行流。透過 Cloudflare 隧道進行遠端存取。

## 何時使用

- 使用者想要視覺化探索程式碼庫的架構
- 使用者要求獲取 Repo 的知識圖譜 / 依賴圖
- 使用者想要與他人分享互動式程式碼庫瀏覽器

## 前提條件

- **Node.js** (v18+) — GitNexus 和代理伺服器所需
- **git** — Repo 必須包含 `.git` 目錄
- **cloudflared** — 用於隧道（如果缺失，會自動安裝至 ~/.local/bin）

## 大小警告

網頁 UI 在瀏覽器中渲染所有節點。檔案數在 5,000 以下的 Repo 運作良好。大型 Repo（30,000+ 節點）會導致瀏覽器分頁變得遲鈍或崩潰。CLI/MCP 工具可在任何規模下運作 — 僅網頁視覺化有此限制。

## 步驟

### 1. 複製並建置 GitNexus (一次性設定)

```bash
GITNEXUS_DIR="${GITNEXUS_DIR:-$HOME/.local/share/gitnexus}"

if [ ! -d "$GITNEXUS_DIR/gitnexus-web/dist" ]; then
  git clone https://github.com/abhigyanpatwari/GitNexus.git "$GITNEXUS_DIR"
  cd "$GITNEXUS_DIR/gitnexus-shared" && npm install && npm run build
  cd "$GITNEXUS_DIR/gitnexus-web" && npm install
fi
```

### 2. 修補網頁 UI 以供遠端存取

網頁 UI 預設使用 `localhost:4747` 進行 API 呼叫。請將其修補為使用同源 (Same-origin)，使其能透過隧道/代理運作：

**檔案：`$GITNEXUS_DIR/gitnexus-web/src/config/ui-constants.ts`**
修改：
```typescript
export const DEFAULT_BACKEND_URL = 'http://localhost:4747';
```
改為：
```typescript
export const DEFAULT_BACKEND_URL = typeof window !== 'undefined' && window.location.hostname !== 'localhost' ? window.location.origin : 'http://localhost:4747';
```

**檔案：`$GITNEXUS_DIR/gitnexus-web/vite.config.ts`**
在 `server: { }` 區塊內加入 `allowedHosts: true`（僅在執行開發模式而非生產建置時需要）：
```typescript
server: {
    allowedHosts: true,
    // ... 現有配置
},
```

然後建置生產版本：
```bash
cd "$GITNEXUS_DIR/gitnexus-web" && npx vite build
```

### 3. 索引目標 Repo

```bash
cd /path/to/target-repo
npx gitnexus analyze --skip-agents-md
rm -rf .claude/    # 移除 Claude Code 專屬成品
```

加入 `--embeddings` 以支援語義搜尋（較慢 — 需要幾分鐘而非幾秒鐘）。

索引儲存在 Repo 內的 `.gitnexus/`（會自動被 gitignore）。

### 4. 建立代理腳本 (Proxy Script)

將以下內容寫入檔案（例如 `$GITNEXUS_DIR/proxy.mjs`）。它會提供生產網頁 UI 並將 `/api/*` 轉發至 GitNexus 後端 — 同源、無 CORS 問題、不需要 sudo、不需要 nginx。

```javascript
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';

const API_PORT = parseInt(process.env.API_PORT || '4747');
const DIST_DIR = process.argv[2] || './dist';
const PORT = parseInt(process.argv[3] || '8888');

const MIME = {
  '.html': 'text/html', '.js': 'application/javascript', '.css': 'text/css',
  '.json': 'application/json', '.png': 'image/png', '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon', '.woff2': 'font/woff2', '.woff': 'font/woff',
  '.wasm': 'application/wasm',
};

function proxyToApi(req, res) {
  const opts = {
    hostname: '127.0.0.1', port: API_PORT,
    path: req.url, method: req.method, headers: req.headers,
  };
  const proxy = http.request(opts, (upstream) => {
    res.writeHead(upstream.statusCode, upstream.headers);
    upstream.pipe(res, { end: true });
  });
  proxy.on('error', () => { res.writeHead(502); res.end('Backend unavailable'); });
  req.pipe(proxy, { end: true });
}

function serveStatic(req, res) {
  let filePath = path.join(DIST_DIR, req.url === '/' ? 'index.html' : req.url.split('?')[0]);
  if (!fs.existsSync(filePath)) filePath = path.join(DIST_DIR, 'index.html');
  const ext = path.extname(filePath);
  const mime = MIME[ext] || 'application/octet-stream';
  try {
    const data = fs.readFileSync(filePath);
    res.writeHead(200, { 'Content-Type': mime, 'Cache-Control': 'public, max-age=3600' });
    res.end(data);
  } catch { res.writeHead(404); res.end('Not found'); }
}

http.createServer((req, res) => {
  if (req.url.startsWith('/api')) proxyToApi(req, res);
  else serveStatic(req, res);
}).listen(PORT, () => console.log(`GitNexus proxy on http://localhost:${PORT}`));
```

### 5. 啟動服務

```bash
# 終端機 1: GitNexus 後端 API
npx gitnexus serve &

# 終端機 2: 代理 (網頁 UI + API 整合在同一連接埠)
node "$GITNEXUS_DIR/proxy.mjs" "$GITNEXUS_DIR/gitnexus-web/dist" 8888 &
```

驗證：`curl -s http://localhost:8888/api/repos` 應回傳已索引的 Repo。

### 6. 使用 Cloudflare 建立隧道 (選用 — 用於遠端存取)

```bash
# 如果需要，安裝 cloudflared (不需要 sudo)
if ! command -v cloudflared &>/dev/null; then
  mkdir -p ~/.local/bin
  curl -sL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    -o ~/.local/bin/cloudflared
  chmod +x ~/.local/bin/cloudflared
  export PATH="$HOME/.local/bin:$PATH"
fi

# 啟動隧道 (--config /dev/null 可避免與現有的具名隧道配置衝突)
cloudflared tunnel --config /dev/null --url http://localhost:8888 --no-autoupdate --protocol http2
```

隧道 URL（例如 `https://random-words.trycloudflare.com`）會輸出至 stderr。分享此連結 — 任何擁有連結的人都能探索圖譜。

### 7. 清理

```bash
# 停止服務
pkill -f "gitnexus serve"
pkill -f "proxy.mjs"
pkill -f cloudflared

# 從目標 Repo 移除索引
cd /path/to/target-repo
npx gitnexus clean
rm -rf .claude/
```

## 注意事項

- **cloudflared 需要 `--config /dev/null`**：如果使用者在 `~/.cloudflared/config.yml` 已有具名隧道配置，則需要此參數。否則配置中的全方位 ingress 規則會導致所有快速隧道請求回傳 404。

- **隧道必須使用生產建置 (Production build)**：Vite 開發伺服器預設會封鎖非 localhost 的主機 (`allowedHosts`)。使用生產建置 + Node 代理伺服器可完全避免此問題。

- **網頁 UI 不會建立 `.claude/` 或 `CLAUDE.md`**：這些是由 `npx gitnexus analyze` 建立的。使用 `--skip-agents-md` 可隱藏 Markdown 檔案，再手動執行 `rm -rf .claude/` 清除剩餘檔案。這些是 Claude Code 整合，hermes-agent 使用者不需要。

- **瀏覽器記憶體限制**：網頁 UI 會將整個圖譜載入瀏覽器記憶體中。檔案數超過 5,000 的 Repo 可能會變遲鈍；超過 30,000 可能導致分頁崩潰。

- **嵌入 (Embeddings) 為選用項**：`--embeddings` 支援語義搜尋，但在大型 Repo 上需要幾分鐘時間。若只需快速探索可跳過；若想透過 AI 對話面板進行自然語言查詢則需加上。

- **多個 Repo**：`gitnexus serve` 會提供所有已索引的 Repo。你可以索引多個 Repo，啟動一次服務，網頁 UI 即可讓你切換。
