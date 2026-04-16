---
sidebar_position: 9
title: "選配技能目錄"
description: "隨 hermes-agent 出貨的官方選配技能 — 透過 hermes skills install official/<category>/<skill> 安裝"
---

# 選配技能目錄

官方選配技能隨 hermes-agent 儲存庫的 `optional-skills/` 目錄提供，但 **預設不啟用**。請顯示安裝：

```bash
hermes skills install official/<category>/<skill>
```

例如：

```bash
hermes skills install official/blockchain/solana
hermes skills install official/mlops/flash-attention
```

安裝後，該技能會出現在代理的技能清單中，並可在偵測到相關任務時自動載入。

卸載指令：

```bash
hermes skills uninstall <skill-name>
```

---

## 自助式 AI 代理 (Autonomous AI Agents)

| 技能 | 描述 |
|-------|-------------|
| **blackbox** | 將程式碼編寫任務委派給 Blackbox AI CLI 代理。這是一個多模型代理，內建評判機制，可透過多個 LLM 執行任務並選擇最佳結果。 |
| **honcho** | 配置並在 Hermes 中使用 Honcho 記憶 — 跨工作階段使用者建模、多設定檔對等隔離、觀察配置以及辯證推理。 |

## 區塊鏈 (Blockchain)

| 技能 | 描述 |
|-------|-------------|
| **base** | 查詢 Base (Ethereum L2) 區塊鏈數據並包含美元定價 — 錢包餘額、代幣資訊、交易細節、Gas 分析、合約檢查、巨鯨偵測以及即時網路統計。無需 API 金鑰。 |
| **solana** | 查詢 Solana 區塊鏈數據並包含美元定價 — 錢包餘額、代幣投資組合、交易細節、NFT、巨鯨偵測以及即時網路統計。無需 API 金鑰。 |

## 溝通 (Communication)

| 技能 | 描述 |
|-------|-------------|
| **one-three-one-rule** | 用於提案與決策的結構化溝通框架 (1-3-1 原則)。 |

## 創意 (Creative)

| 技能 | 描述 |
|-------|-------------|
| **blender-mcp** | 透過 socket 連線至 blender-mcp 附加元件，直接從 Hermes 控制 Blender。建立 3D 物件、材質、動畫，並執行任意 Blender Python (bpy) 程式碼。 |
| **meme-generation** | 透過選擇模板並使用 Pillow 疊加文字來生成真實的迷因圖片。產生實際的 `.png` 迷因檔案。 |

## 開發運維 (DevOps)

| 技能 | 描述 |
|-------|-------------|
| **cli** | 透過 inference.sh CLI (infsh) 執行 150+ 個 AI 應用程式 — 圖片生成、影片製作、LLM、搜尋、3D 以及社群自動化。 |
| **docker-management** | 管理 Docker 容器、映像檔、磁碟卷、網路以及 Compose 堆疊 — 生命週期操作、除錯、清理以及 Dockerfile 優化。 |

## 電子郵件 (Email)

| 技能 | 描述 |
|-------|-------------|
| **agentmail** | 透過 AgentMail 賦予代理專屬的電子郵件信箱。自主地使用代理擁有的電子郵件地址發送、接收和管理郵件。 |

## 健康 (Health)

| 技能 | 描述 |
|-------|-------------|
| **neuroskill-bci** | 用於神經科學研究工作流的腦機介面 (BCI) 整合。 |

## MCP

| 技能 | 描述 |
|-------|-------------|
| **fastmcp** | 使用 Python 中的 FastMCP 構建、測試、檢查、安裝與部署 MCP 伺服器。涵蓋將 API 或資料庫封裝為 MCP 工具、公開資源或提示詞以及部署。 |

## 遷移 (Migration)

| 技能 | 描述 |
|-------|-------------|
| **openclaw-migration** | 將使用者的 OpenClaw 自訂軌跡遷移至 Hermes Agent。匯入記憶、SOUL.md、指令允許列表、使用者技能以及選定的工作區資產。 |

## 機器學習運維 (MLOps)

最大的選配類別 — 涵蓋從數據策劃到生產推論的完整 ML 流程。

| 技能 | 描述 |
|-------|-------------|
| **accelerate** | 最簡單的分散式訓練 API。只需 4 行程式碼即可為任何 PyTorch 腳本添加分散式支援。DeepSpeed/FSDP/Megatron/DDP 的統一 API。 |
| **chroma** | 開源嵌入 (embedding) 資料庫。存儲嵌入和元數據，執行向量與全文檢索。用於 RAG 和語義搜尋的簡單 4 函式 API。 |
| **faiss** | Facebook 用於稠密向量高效相似性搜尋與聚類的函式庫。支援數十億個向量、GPU 加速以及各種索引類型 (Flat, IVF, HNSW)。 |
| **flash-attention** | 使用 Flash Attention 優化 Transformer 注意力機制，實現 2-4 倍速提升與 10-20 倍記憶體減少。支援 PyTorch SDPA、flash-attn 函式庫、H100 FP8 以及滑動視窗。 |
| **hermes-atropos-environments** | 構建、測試並除錯用於 Atropos 訓練的 Hermes Agent RL 環境。涵蓋 HermesAgentBaseEnv 介面、獎勵函式、代理迴圈整合以及評估。 |
| **huggingface-tokenizers** | 用於研究與生產的快速 Rust 型分詞器 (tokenizers)。20 秒內可處理 1GB 數據。支援 BPE、WordPiece 與 Unigram 演算法。 |
| **instructor** | 透過 Pydantic 驗證從 LLM 回應中提取結構化數據，自動重試失敗的提取，並串流傳輸部分結果。 |
| **lambda-labs** | 用於 ML 訓練與推論的預留及按需 GPU 雲端實例。支援 SSH 存取、持久化檔案系統以及多節點集群。 |
| **llava** | 大型語言與視覺助手 (Large Language and Vision Assistant) — 結合 CLIP 視覺與 LLaMA 語言模型的視覺指令微調與基於圖片的對話。 |
| **nemo-curator** | 用於 LLM 訓練的 GPU 加速數據策劃。模糊去重 (快 16 倍)、質量過濾 (30+ 啟發式)、語義去重、PII 脫敏。可隨 RAPIDS 擴展。 |
| **pinecone** | 用於生產環境 AI 的託管式向量資料庫。支援自動擴展、混合搜尋 (稠密 + 稀疏)、元數據過濾以及低延遲 (p95 低於 100ms)。 |
| **pytorch-lightning** | 帶有 Trainer 類別的高階 PyTorch 框架，支援自動分散式訓練 (DDP/FSDP/DeepSpeed)、回調 (callbacks) 以及極簡的範例程式碼。 |
| **qdrant** | 高效能向量相似性搜尋引擎。由 Rust 驅動，具有快速最近鄰搜尋、帶過濾的混合搜尋以及可擴展的向量存儲。 |
| **saelens** | 使用 SAELens 訓練並分析稀疏自動編碼器 (SAEs)，將神經網路激活分解為可解釋的特徵。 |
| **simpo** | 簡單偏好優化 (Simple Preference Optimization) — DPO 的無參考模型替代方案，具有更好的性能 (在 AlpacaEval 2.0 上提升 6.4 分)。無需參考模型。 |
| **slime** | 使用 Megatron+SGLang 框架透過 RL 進行 LLM 後訓練。自定義數據生成工作流以及用於 RL 擴展的緊密 Megatron-LM 整合。 |
| **tensorrt-llm** | 使用 NVIDIA TensorRT 優化 LLM 推論以實現最大吞吐量。在 A100/H100 上比 PyTorch 快 10-100 倍，支援量化 (FP8/INT4) 與在線批處理 (in-flight batching)。 |
| **torchtitan** | 原生 PyTorch 分散式 LLM 預訓練，支援 4D 並行 (FSDP2, TP, PP, CP)。可使用 Float8 與 torch.compile 從 8 個 GPU 擴展至 512+ 個 GPU。 |

## 生產力 (Productivity)

| 技能 | 描述 |
|-------|-------------|
| **canvas** | Canvas LMS 整合 — 使用 API 權杖驗證獲取已選課程與作業。 |
| **memento-flashcards** | 用於學習與知識鞏固的間隔重複 (Spaced repetition) 字卡系統。 |
| **siyuan** | 思源筆記 (SiYuan Note) API，用於在自託管知識庫中搜尋、讀取、建立與管理區塊與文件。 |
| **telephony** | 賦予 Hermes 電話功能 — 配置 Twilio 號碼、發送/接收短訊/多媒體簡訊、撥打電話，並透過 Bland.ai 或 Vapi 進行 AI 驅動的外撥電話。 |

## 研究 (Research)

| 技能 | 描述 |
|-------|-------------|
| **bioinformatics** | 通往 bioSkills 與 ClawBio 超過 400 個生物資訊學技能的閘道。涵蓋基因組學、轉錄組學、單細胞、變異調用、藥物基因組學、宏基因組學與結構生物學。 |
| **domain-intel** | 使用 Python 標準函式庫進行被動網域偵查。子網域探索、SSL 憑證檢查、WHOIS 查詢、DNS 記錄以及批次多網域分析。無需 API 金鑰。 |
| **duckduckgo-search** | 透過 DuckDuckGo 進行免費網頁搜尋 — 文字、新聞、圖片、影片。無需 API 金鑰。 |
| **gitnexus-explorer** | 使用 GitNexus 為程式碼庫建立索引，並透過網頁介面與 Cloudflare 隧道提供互動式知識圖譜。 |
| **parallel-cli** | Parallel CLI 供應商技能 — 代理原生的網頁搜尋、提取、深度研究、豐富化與監控。 |
| **qmd** | 使用 qmd 在本地搜尋個人知識庫、筆記、文件與會議記錄 — 這是一個結合 BM25、向量搜尋與 LLM 重排 (reranking) 的混合檢索引擎。 |
| **scrapling** | 使用 Scrapling 進行網頁抓取 — HTTP 獲取、隱身瀏覽器自動化、繞過 Cloudflare 以及透過 CLI 和 Python 進行爬蟲抓取。 |

## 安全 (Security)

| 技能 | 描述 |
|-------|-------------|
| **1password** | 設置並使用 1Password CLI (op)。安裝 CLI、啟用桌面應用程式整合、登入並為指令讀取/注入密鑰。 |
| **oss-forensics** | 開源軟體取證 — 分析套件、依賴關係以及供應鏈風險。 |
| **sherlock** | 在 400 多個社交網路中進行 OSINT 使用者名稱搜尋。透過使用者名稱追蹤社交媒體帳號。 |

---

## 貢獻選配技能

若要向儲存庫新增新的選配技能：

1. 在 `optional-skills/<category>/<skill-name>/` 下建立目錄
2. 新增一個帶有標準前導資料 (frontmatter) (名稱、描述、版本、作者) 的 `SKILL.md`
3. 在 `references/`、`templates/` 或 `scripts/` 子目錄中包含任何支援檔案
4. 提交提取請求 (Pull Request) — 技能合併後將出現在此目錄中
