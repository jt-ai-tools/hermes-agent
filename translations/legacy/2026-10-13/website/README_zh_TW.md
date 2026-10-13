# 網站 (Website)

本網站使用 [Docusaurus](https://docusaurus.io/) 建置，這是一個現代化的靜態網站產生器。

## 安裝 (Installation)

```bash
yarn
```

## 本地開發 (Local Development)

```bash
yarn start
```

此指令會啟動本地開發伺服器並開啟瀏覽器視窗。大多數的變更都會即時反映，無需重啟伺服器。

## 建置 (Build)

```bash
yarn build
```

此指令會將靜態內容產生至 `build` 目錄中，並可透過任何靜態內容代管服務進行部署。

## 部署 (Deployment)

使用 SSH：

```bash
USE_SSH=true yarn deploy
```

不使用 SSH：

```bash
GIT_USER=<您的 GitHub 使用者名稱> yarn deploy
```

如果您使用 GitHub Pages 進行代管，此指令是建置網站並推送到 `gh-pages` 分支的便捷方式。

## 圖表排版檢查 (Diagram Linting)

CI 會執行 `ascii-guard` 來檢查文件中的 ASCII 方塊圖。請使用 Mermaid (````mermaid`) 或純文字清單/表格來替代 ASCII 方塊，以避免 CI 檢查失敗。
