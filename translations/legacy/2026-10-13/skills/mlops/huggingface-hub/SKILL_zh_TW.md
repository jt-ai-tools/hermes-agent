---
name: huggingface-hub
description: Hugging Face Hub CLI (hf) — 搜尋、下載及上傳模型與資料集、管理儲存庫、使用 SQL 查詢資料集、部署推論端點、管理 Spaces 及儲存貯體 (Buckets)。
version: 1.0.0
author: Hugging Face
license: MIT
tags: [huggingface, hf, models, datasets, hub, mlops]
---

# Hugging Face CLI (`hf`) 參考指南

`hf` 指令是與 Hugging Face Hub 互動的現代化命令列介面，提供管理儲存庫 (Repositories)、模型 (Models)、資料集 (Datasets) 及 Spaces 的工具。

> **重要提示：** `hf` 指令取代了目前已棄用的 `huggingface-cli` 指令。

## 快速入門
*   **安裝：** `curl -LsSf https://hf.co/cli/install.sh | bash -s`
*   **說明：** 使用 `hf --help` 查看所有可用功能及實際範例。
*   **認證：** 建議透過 `HF_TOKEN` 環境變數或 `--token` 旗標進行認證。

---

## 核心指令

### 一般操作
*   `hf download REPO_ID`：從 Hub 下載檔案。
*   `hf upload REPO_ID`：上傳檔案/資料夾 (建議用於單次提交)。
*   `hf upload-large-folder REPO_ID LOCAL_PATH`：建議用於大型目錄的可續傳上傳。
*   `hf sync`：同步本地目錄與儲存貯體 (Bucket) 之間的檔案。
*   `hf env` / `hf version`：查看環境與版本詳細資訊。

### 認證 (`hf auth`)
*   `login` / `logout`：使用來自 [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens) 的權杖 (Token) 管理工作階段。
*   `list` / `switch`：管理並切換多個儲存的存取權杖。
*   `whoami`：識別目前登入的帳戶。

### 儲存庫管理 (`hf repos`)
*   `create` / `delete`：建立或永久移除儲存庫。
*   `duplicate`：將模型、資料集或 Space 複製到新的 ID。
*   `move`：在命名空間之間移動儲存庫。
*   `branch` / `tag`：管理類似 Git 的分支與標籤參照。
*   `delete-files`：使用模式比對移除特定檔案。

---

## 專業 Hub 互動

### 資料集與模型
*   **資料集：** `hf datasets list`、`info` 及 `parquet` (列出 parquet 格式的 URL)。
*   **SQL 查詢：** `hf datasets sql SQL` — 透過 DuckDB 對資料集的 parquet URL 執行原始 SQL 查詢。
*   **模型：** `hf models list` 及 `info`。
*   **論文：** `hf papers list` — 查看每日論文。

### 討論與提取請求 (`hf discussions`)
*   管理 Hub 貢獻的生命週期：`list`、`create`、`info`、`comment`、`close`、`reopen` 及 `rename`。
*   `diff`：查看提取請求 (PR) 中的變更。
*   `merge`：完成並合併提取請求。

### 基礎架構與運算
*   **端點 (Endpoints)：** 部署與管理推論端點 (`deploy`、`pause`、`resume`、`scale-to-zero`、`catalog`)。
*   **工作 (Jobs)：** 在 HF 基礎架構上執行運算任務。包括 `hf jobs uv` (執行帶有內嵌相依性的 Python 腳本) 以及 `stats` (資源監控)。
*   **Spaces：** 管理互動式應用程式。包括 `dev-mode` 與 `hot-reload` (無需完全重啟即可更新 Python 檔案)。

### 儲存與自動化
*   **儲存貯體 (Buckets)：** 完整的類 S3 儲存貯體管理 (`create`、`cp`、`mv`、`rm`、`sync`)。
*   **快取 (Cache)：** 使用 `list`、`prune` (移除分離的修訂版本) 及 `verify` (總和檢查碼驗證) 管理本地儲存空間。
*   **網路勾點 (Webhooks)：** 透過管理 Hub 網路勾點來自動化工作流程 (`create`、`watch`、`enable`/`disable`)。
*   **收藏 (Collections)：** 將 Hub 項目組織成收藏集 (`add-item`、`update`、`list`)。

---

## 進階用法與技巧

### 全域旗標 (Global Flags)
*   `--format json`：產生機器可讀的輸出，以便於自動化處理。
*   `-q` / `--quiet`：僅輸出 ID，減少資訊干擾。

### 擴充功能與技能 (Extensions & Skills)
*   **擴充功能 (Extensions)：** 使用 `hf extensions install REPO_ID` 透過 GitHub 儲存庫擴展 CLI 功能。
*   **技能 (Skills)：** 使用 `hf skills add` 管理 AI 助理技能。
