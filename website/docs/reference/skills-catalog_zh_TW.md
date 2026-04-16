---
sidebar_position: 5
title: "內建技能目錄"
description: "Hermes Agent 隨附的內建技能目錄"
---

# 內建技能目錄

Hermes 隨附了一個龐大的內建技能庫，安裝時會複製到 `~/.hermes/skills/`。本頁面列出了儲存庫中 `skills/` 目錄下的內建技能。

## apple

Apple/macOS 專屬技能 — iMessage、提醒事項、備忘錄、尋找 (FindMy) 以及 macOS 自動化。這些技能僅在 macOS 系統上載入。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `apple-notes` | 在 macOS 上透過 memo CLI 管理 Apple 備忘錄 (建立、檢視、搜尋、編輯)。 | `apple/apple-notes` |
| `apple-reminders` | 透過 remindctl CLI 管理 Apple 提醒事項 (列表、新增、完成、刪除)。 | `apple/apple-reminders` |
| `findmy` | 在 macOS 上透過 AppleScript 與螢幕擷取，經由「尋找」應用程式追蹤 Apple 裝置與 AirTags。 | `apple/findmy` |
| `imessage` | 在 macOS 上透過 imsg CLI 發送與接收 iMessage/短訊。 | `apple/imessage` |

## 自助式 AI 代理 (autonomous-ai-agents)

用於生成與協調自主式 AI 程式碼編寫代理及多代理工作流的技能 — 執行獨立的代理程序、委派任務以及協調平行工作流。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `claude-code` | 將程式碼編寫任務委派給 Claude Code (Anthropic 的 CLI 代理)。用於構建功能、重構、PR 審查與迭代開發。需要安裝 claude CLI。 | `autonomous-ai-agents/claude-code` |
| `codex` | 將程式碼編寫任務委派給 OpenAI Codex CLI 代理。用於構建功能、重構、PR 審查與批次修復問題。需要安裝 codex CLI 與 git 儲存庫。 | `autonomous-ai-agents/codex` |
| `hermes-agent-spawning` | 生成額外的 Hermes Agent 實例作為自主子程序，處理獨立的長期任務。支援非互動式的單次模式 (-q) 與用於多輪協作的互動式 PTY 模式。這與 delegate_task 不同 — 這是執行一個完整的獨立 hermes 程序。 | `autonomous-ai-agents/hermes-agent` |
| `opencode` | 將程式碼編寫任務委派給 OpenCode CLI 代理，用於功能實作、重構、PR 審查與長期自主工作階段。需要安裝 OpenCode CLI 並完成驗證。 | `autonomous-ai-agents/opencode` |

## 數據科學 (data-science)

用於數據科學工作流的技能 — 互動式探索、Jupyter 筆記本、數據分析與視覺化。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `jupyter-live-kernel` | 透過 hamelnb 使用即時 Jupyter 核心進行有狀態、迭代式的 Python 執行。當任務涉及探索、迭代或檢查中間結果時載入此技能。 | `data-science/jupyter-live-kernel` |

## 創意 (creative)

創意內容生成 — ASCII 藝術、手繪風格圖表以及視覺設計工具。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `ascii-art` | 使用 pyfiglet (571 種字體)、cowsay、boxes、toilet、image-to-ascii、遠端 API (asciified, ascii.co.uk) 以及 LLM 備案生成 ASCII 藝術。無需 API 金鑰。 | `creative/ascii-art` |
| `ascii-video` | 各式格式的 ASCII 藝術影片生產流水線。將影片/音訊/圖片/生成式輸入轉換為彩色 ASCII 字元影片輸出 (MP4, GIF, 圖片序列)。涵蓋：影片轉 ASCII、音訊感應音樂視覺化、生成式 ASCII 藝術動畫等。 | `creative/ascii-video` |
| `excalidraw` | 使用 Excalidraw JSON 格式建立手繪風格圖表。生成用於架構圖、流程圖、時序圖、概念圖等的 .excalidraw 檔案。檔案可在 excalidraw.com 開啟或上傳獲取分享連結。 | `creative/excalidraw` |
| `p5js` | 使用 p5.js 進行互動式與生成式視覺藝術生產。建立草圖、透過無頭瀏覽器將其渲染為圖片/影片，並提供即時預覽。支援畫布動畫、數據視覺化與創意程式設計實驗。 | `creative/p5js` |

## 開發運維 (devops)

開發運維與基礎設施自動化技能。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `webhook-subscriptions` | 建立與管理 Webhook 訂閱，用於事件驅動的代理啟動。外部服務 (GitHub, Stripe, CI/CD, IoT) 發送 POST 事件以觸發代理運行。需要啟用 Webhook 平台。 | `devops/webhook-subscriptions` |

## 測試 (dogfood)

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `dogfood` | 對網頁應用程式進行系統性的探索式 QA 測試 — 尋找臭蟲、捕捉證據並生成結構化報告。 | `dogfood/dogfood` |
| `hermes-agent-setup` | 協助使用者配置 Hermes Agent — CLI 使用、設定精靈、模型/提供商選擇、工具、技能、語音/STT/TTS、網關以及疑難排解。 | `dogfood/hermes-agent-setup` |

## 電子郵件 (email)

用於從終端機發送、接收、搜尋與管理電子郵件的技能。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `himalaya` | 透過 IMAP/SMTP 管理電子郵件的 CLI。使用 himalaya 在終端機列出、閱讀、撰寫、回覆、轉寄、搜尋與整理郵件。支援多個帳號並使用 MML (MIME Meta Language) 撰寫訊息。 | `email/himalaya` |

## 遊戲 (gaming)

用於設置、配置與管理遊戲伺服器、模組包 (modpacks) 以及遊戲相關基礎設施的技能。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `minecraft-modpack-server` | 從 CurseForge/Modrinth 伺服器模組包 zip 檔案設置模組化 Minecraft 伺服器。涵蓋 NeoForge/Forge 安裝、Java 版本、JVM 調優、防火牆、區域網路配置、備份與啟動腳本。 | `gaming/minecraft-modpack-server` |
| `pokemon-player` | 透過無頭模擬自主地玩神奇寶貝 (Pokemon) 遊戲。啟動遊戲伺服器，從 RAM 讀取結構化遊戲狀態，做出戰略決策並發送按鍵輸入 — 全部都在終端機中完成。 | `gaming/pokemon-player` |

## GitHub

用於管理儲存庫、提取請求 (PR)、程式碼審查、問題 (Issues) 以及使用 gh CLI 與 git 在終端機管理 CI/CD 流水線的 GitHub 工作流技能。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `codebase-inspection` | 使用 pygount 檢查與分析程式碼庫，統計程式碼行數 (LOC)、語言細分以及程式碼與註解比例。當被要求檢查行數、儲存庫大小、語言組成或程式碼庫統計數據時使用。 | `github/codebase-inspection` |
| `github-auth` | 使用 git (通用) 或 gh CLI 為代理設置 GitHub 驗證。涵蓋 HTTPS 權杖、SSH 金鑰、憑證助手以及 gh auth — 並具備自動偵測流程以選擇正確方法。 | `github/github-auth` |
| `github-code-review` | 透過分析 git diffs、在 PR 上留下行內註解以及執行徹底的推送前審查來審查程式碼變更。支援 gh CLI，或備案使用 git + 透過 curl 呼叫 GitHub REST API。 | `github/github-code-review` |
| `github-issues` | 建立、管理、分類與關閉 GitHub Issues。搜尋現有問題、添加標籤、指派人員並連結至 PR。支援 gh CLI，或備案使用 git + 透過 curl 呼叫 GitHub REST API。 | `github/github-issues` |
| `github-pr-workflow` | 完整的提取請求生命週期 — 建立分支、提交變更、開啟 PR、監控 CI 狀態、自動修復失敗並合併。支援 gh CLI，或備案使用 git + 透過 curl 呼叫 GitHub REST API。 | `github/github-pr-workflow` |
| `github-repo-management` | 複製、建立、分叉 (fork)、配置與管理 GitHub 儲存庫。管理遠端倉庫、密鑰、發佈 (Releases) 與工作流。支援 gh CLI，或備案使用 git + 透過 curl 呼叫 GitHub REST API。 | `github/github-repo-management` |

## inference-sh

透過 inference.sh 雲端平台執行 AI 應用程式的技能。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `inference-sh-cli` | 透過 inference.sh CLI (infsh) 執行 150+ 個 AI 應用程式 — 圖片生成、影片製作、LLM、搜尋、3D、社群自動化。 | `inference-sh/cli` |

## 休閒 (leisure)

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `find-nearby` | 使用 OpenStreetMap 尋找附近的場所 (餐廳、咖啡廳、酒吧、藥局等)。支援經緯度座標、地址、城市、郵遞區號或 Telegram 位置釘點。無需 API 金鑰。 | `leisure/find-nearby` |

## MCP

用於處理 MCP (模型上下文協定) 伺服器、工具與整合的技能。包含內建的原生 MCP 用戶端 (在 config.yaml 中配置伺服器以自動探索工具) 以及用於臨時伺服器互動的 mcporter CLI 橋接器。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `mcporter` | 使用 mcporter CLI 直接 (透過 HTTP 或 stdio) 列出、配置、驗證與呼叫 MCP 伺服器/工具，包含臨時伺服器、設定編輯以及 CLI/類型生成。 | `mcp/mcporter` |
| `native-mcp` | 內建的 MCP (Model Context Protocol) 用戶端，可連接至外部 MCP 伺服器，探索其工具並將其註冊為原生 Hermes Agent 工具。支援 stdio 與 HTTP 傳輸，具有自動重連、安全過濾與零配置工具注入功能。 | `mcp/native-mcp` |

## 媒體 (media)

處理媒體內容的技能 — YouTube 逐字稿、GIF 搜尋、音樂生成與音訊視覺化。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `gif-search` | 使用 curl 從 Tenor 搜尋並下載 GIF。除 curl 與 jq 外無其他依賴。適用於尋找反應圖、製作視覺內容以及在聊天中發送 GIF。 | `media/gif-search` |
| `heartmula` | 設置並執行 HeartMuLa，開源音樂生成模型系列 (類似 Suno)。支援多語言，可根據歌詞與標籤生成完整歌曲。 | `media/heartmula` |
| `songsee` | 透過 CLI 從音訊檔案生成頻譜圖與音訊特徵視覺化 (mel, chroma, MFCC, tempogram 等)。適用於音訊分析、音樂製作除錯與視覺說明文件。 | `media/songsee` |
| `youtube-content` | 獲取 YouTube 影片逐字稿並將其轉換為結構化內容 (章節、摘要、貼文串、部落格文章)。 | `media/youtube-content` |

## 機器學習運維 (mlops)

通用型機器學習運維工具 — 模型中心管理、數據集操作與工作流協調。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `huggingface-hub` | Hugging Face Hub CLI (hf) — 搜尋、下載與上傳模型與數據集，管理儲存庫，部署推論端點。 | `mlops/huggingface-hub` |

## 機器學習運維/雲端 (mlops/cloud)

用於機器學習工作負載的 GPU 雲端供應商與無伺服器計算平台。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `lambda-labs-gpu-cloud` | 用於機器學習訓練與推論的預留與按需 GPU 雲端實例。當您需要具備簡單 SSH 存取、持久化檔案系統或用於大規模訓練的高效能多節點集群的專屬 GPU 實例時使用。 | `mlops/cloud/lambda-labs` |
| `modal-serverless-gpu` | 用於執行機器學習工作負載的無伺服器 GPU 雲端平台。當您需要按需使用 GPU 而無需管理基礎設施、將機器學習模型部署為 API 或執行具備自動擴展功能的批次作業時使用。 | `mlops/cloud/modal` |

## 機器學習運維/評估 (mlops/evaluation)

模型評估基準、實驗追蹤、數據策劃、分詞器 (tokenizers) 與可解釋性工具。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `evaluating-llms-harness` | 在 60 多個學術基準測試 (MMLU, HumanEval, GSM8K, TruthfulQA, HellaSwag) 中評估 LLM。用於基準化模型品質、比較模型、報告學術結果或追蹤訓練進度。EleutherAI、HuggingFace 與各大實驗室使用的業界標準。 | `mlops/evaluation/lm-evaluation-harness` |
| `huggingface-tokenizers` | 針對研究與生產優化的快速分詞器。基於 Rust 的實作可在 20 秒內處理 1GB 數據。支援 BPE、WordPiece 與 Unigram 演算法。可訓練自定義詞彙、追蹤對齊、處理填充/截斷。與 transformers 無縫整合。 | `mlops/evaluation/huggingface-tokenizers` |
| `nemo-curator` | 用於 LLM 訓練的 GPU 加速數據策劃。支援文字/圖片/影片/音訊。功能包含模糊去重 (快 16 倍)、品質過濾 (30+ 啟發式)、語義去重、PII 脫敏、NSFW 偵測。可使用 RAPIDS 跨 GPU 擴展。 | `mlops/evaluation/nemo-curator` |
| `sparse-autoencoder-training` | 提供使用 SAELens 訓練並分析稀疏自動編碼器 (SAEs) 的指引，將神經網路激活分解為可解釋的特徵。用於發現可解釋特徵、分析疊加 (superposition) 或研究語言模型中的單一語義表示。 | `mlops/evaluation/saelens` |
| `weights-and-biases` | 使用 W&B 追蹤機器學習實驗，包含自動記錄、即時視覺化訓練、透過 sweeps 優化超參數以及管理模型註冊表 — 一個協作式的 MLOps 平台。 | `mlops/evaluation/weights-and-biases` |

## 機器學習運維/推論 (mlops/inference)

模型提供、量化 (GGUF/GPTQ)、結構化輸出、推論優化與模型手術工具，用於部署與執行 LLM。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `gguf-quantization` | GGUF 格式與 llama.cpp 量化，用於高效的 CPU/GPU 推論。用於在消費級硬體、Apple Silicon 上部署模型，或在無需 GPU 的情況下需要 2-8 位元靈活量化時使用。 | `mlops/inference/gguf` |
| `guidance` | 使用正則表達式與語法控制 LLM 輸出，保證生成有效的 JSON/XML/程式碼，強制執行結構化格式，並使用 Guidance 建立多步驟工作流 — 這是微軟研究院的受限生成框架。 | `mlops/inference/guidance` |
| `instructor` | 透過 Pydantic 驗證從 LLM 回應中提取結構化數據，自動重試失敗的提取，具備類型安全性地解析複雜 JSON，並使用 Instructor 串流傳輸部分結果。 | `mlops/inference/instructor` |
| `llama-cpp` | 在 CPU、Apple Silicon 與消費級 GPU (無需 NVIDIA 硬體) 上執行 LLM 推論。用於邊緣部署、M1/M2/M3 Mac、AMD/Intel GPU，或 CUDA 不可用時。支援 GGUF 量化 (1.5-8 位元) 以減少記憶體佔用，且在 CPU 上比 PyTorch 快 4-10 倍。 | `mlops/inference/llama-cpp` |
| `obliteratus` | 使用 OBLITERATUS 從開源權重 LLM 中移除拒絕行為 — 運用機械式可解釋性技術 (diff-in-means, SVD, whitened SVD, LEACE, SAE 分解等) 在保留推理能力的同時切除安全護欄。包含 9 種 CLI 方法、28 個分析模組與 116 個模型預設。 | `mlops/inference/obliteratus` |
| `outlines` | 在生成過程中保證有效的 JSON/XML/程式碼結構，使用 Pydantic 模型實現類型安全輸出，支援本地模型 (Transformers, vLLM)，並使用 Outlines 最大化推論速度 — 這是 dottxt.ai 的結構化生成函式庫。 | `mlops/inference/outlines` |
| `serving-llms-vllm` | 使用 vLLM 的 PagedAttention 與連續批處理 (continuous batching) 高吞吐量地提供 LLM 服務。用於部署生產級 LLM API、優化推論延遲/吞吐量，或在 GPU 記憶體有限的情況下提供模型。支援 OpenAI 相容端點與量化 (GPTQ/AWQ/FP8)。 | `mlops/inference/vllm` |
| `tensorrt-llm` | 使用 NVIDIA TensorRT 優化 LLM 推論以實現最大吞吐量與最低延遲。用於 NVIDIA GPU (A100/H100) 上的生產部署，當您需要比 PyTorch 快 10-100 倍的推論，或用於量化 (FP8/INT4)、在線批處理與多節點推論。 | `mlops/inference/tensorrt-llm` |

## 機器學習運維/模型 (mlops/models)

特定模型架構與工具 — 電腦視覺 (CLIP, SAM, Stable Diffusion)、語音 (Whisper)、音訊生成 (AudioCraft) 以及多模態模型 (LLaVA)。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `audiocraft-audio-generation` | 用於音訊生成的 PyTorch 函式庫，包含文字轉音樂 (MusicGen) 與文字轉音效 (AudioGen)。當您需要從文字描述生成音樂、建立音效或執行基於旋律條件的音樂生成時使用。 | `mlops/models/audiocraft` |
| `clip` | OpenAI 連接視覺與語言的模型。支援零樣本圖片分類、圖文匹配與跨模態檢索。用於圖片搜尋、內容審核或無需微調的視覺語言任務。適用於通用目的。 | `mlops/models/clip` |
| `llava` | 大型語言與視覺助手。支援視覺指令微調與基於圖片的對話。結合了 CLIP 視覺編碼器與 Vicuna/LLaMA 語言模型。支援多輪圖片聊天、視覺問答與指令遵循。 | `mlops/models/llava` |
| `segment-anything-model` | 具備零樣本遷移能力的圖片分割基礎模型。當您需要使用點、方框或遮罩作為提示詞分割圖片中的任何物件，或自動生成圖片中所有物件遮罩時使用。 | `mlops/models/segment-anything` |
| `stable-diffusion-image-generation` | 透過 HuggingFace Diffusers 使用 Stable Diffusion 模型進行最先進的文字轉圖片生成。用於從文字提示生成圖片、執行圖轉圖翻譯、局部重繪 (inpainting) 或構建自定義擴擴散流水線。 | `mlops/models/stable-diffusion` |
| `whisper` | OpenAI 的通用語音識別模型。支援 99 種語言、轉錄、翻譯成英文與語言識別。提供從 tiny (39M 參數) 到 large (1550M 參數) 的六種模型大小。適用於語音轉文字、Podcast 轉錄或多語言音訊處理。 | `mlops/models/whisper` |

## 機器學習運維/研究 (mlops/research)

用於透過宣告式程式設計構建與優化 AI 系統的機器學習研究框架。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `dspy` | 使用宣告式程式設計構建複雜的 AI 系統、自動優化提示詞、建立模組化 RAG 系統與代理。這是史丹佛大學 NLP 實驗室開發的系統化語言模型程式設計框架。 | `mlops/research/dspy` |

## 機器學習運維/訓練 (mlops/training)

微調、RLHF/DPO/GRPO 訓練、分散式訓練框架，以及用於訓練 LLM 與其他模型的優化工具。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `axolotl` | 使用 Axolotl 進行 LLM 微調的專家指引 — YAML 配置、100+ 模型支援、LoRA/QLoRA、DPO/KTO/ORPO/GRPO 以及多模態支援。 | `mlops/training/axolotl` |
| `distributed-llm-pretraining-torchtitan` | 提供使用 torchtitan 進行原生 PyTorch 分散式 LLM 預訓練，支援 4D 並行 (FSDP2, TP, PP, CP)。用於從 8 到 512+ 個 GPU 規模化地預訓練 Llama 3.1、DeepSeek V3 或自定義模型。 | `mlops/training/torchtitan` |
| `fine-tuning-with-trl` | 使用 TRL 透過強化學習微調 LLM — 用於指令微調的 SFT、用於偏好對齊的 DPO、用於獎勵優化的 PPO/GRPO 以及獎勵模型訓練。適用於需要 RLHF 或根據人類回饋進行訓練。 | `mlops/training/trl-fine-tuning` |
| `grpo-rl-training` | 使用 TRL 進行 GRPO/RL 微調的專家指引，用於推理與特定任務模型訓練。 | `mlops/training/grpo-rl-training` |
| `hermes-atropos-environments` | 構建、測試並除錯用於 Atropos 訓練的 Hermes Agent RL 環境。涵蓋 HermesAgentBaseEnv 介面、獎勵函式、代理迴圈整合、工具評估、wandb 記錄等。 | `mlops/training/hermes-atropos-environments` |
| `huggingface-accelerate` | 最簡單的分散式訓練 API。只需 4 行程式碼即可為任何 PyTorch 腳本添加分散式支援。DeepSpeed/FSDP/Megatron/DDP 的統一 API。 | `mlops/training/accelerate` |
| `optimizing-attention-flash` | 使用 Flash Attention 優化 Transformer 注意力機制，實現 2-4 倍速提升與 10-20 倍記憶體減少。用於處理長序列 (>512 權杖) 或遇到 GPU 記憶體問題時。 | `mlops/training/flash-attention` |
| `peft-fine-tuning` | 使用 LoRA、QLoRA 等 25+ 種方法對 LLM 進行參數高效微調 (PEFT)。用於在 GPU 記憶體有限的情況下微調大型模型 (7B-70B)，或需要訓練 <1% 參數時。 | `mlops/training/peft` |
| `pytorch-fsdp` | 使用 PyTorch FSDP 進行全分片數據並行 (Fully Sharded Data Parallel) 訓練的專家指引 — 參數分片、混合精度、CPU 卸載、FSDP2。 | `mlops/training/pytorch-fsdp` |
| `pytorch-lightning` | 帶有 Trainer 類別的高階 PyTorch 框架，支援自動分散式訓練、回調系統與極簡範例程式碼。同一套程式碼可從筆記本電腦擴展至超級電腦。 | `mlops/training/pytorch-lightning` |
| `simpo-training` | 用於 LLM 對齊的簡單偏好優化 (Simple Preference Optimization)。DPO 的無參考模型替代方案，性能更好且比 DPO 更高效。 | `mlops/training/simpo` |
| `slime-rl-training` | 提供使用 slime (Megatron+SGLang 框架) 透過 RL 進行 LLM 後訓練的指引。用於訓練 GLM 模型、實作自定義數據生成工作流或需要緊密整合 Megatron-LM。 | `mlops/training/slime` |
| `unsloth` | 使用 Unsloth 進行快速微調的專家指引 — 訓練速度提升 2-5 倍，記憶體佔用減少 50-80%，專門優化 LoRA/QLoRA。 | `mlops/training/unsloth` |

## 機器學習運維/向量資料庫 (mlops/vector-databases)

用於 RAG、語義搜尋與 AI 應用程式後端的向量相似性搜尋與嵌入資料庫。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `chroma` | 用於 AI 應用程式的開源嵌入資料庫。存儲嵌入與元數據，執行向量與全文檢索，並可透過元數據過濾。從筆記本到生產集群皆可擴展。 | `mlops/vector-databases/chroma` |
| `faiss` | Facebook 用於稠密向量高效相似性搜尋與聚類的函式庫。支援數十億個向量、GPU 加速以及各種索引類型。用於快速 k-NN 搜尋或大規模向量檢索。 | `mlops/vector-databases/faiss` |
| `pinecone` | 用於生產級 AI 應用程式的託管式向量資料庫。全託管、自動擴展，支援混合搜尋、元數據過濾與命名空間。低延遲 (<100ms p95)。 | `mlops/vector-databases/pinecone` |
| `qdrant-vector-search` | 用於 RAG 與語義搜尋的高效能向量相似性搜尋引擎。用於構建需要快速最近鄰搜尋、帶過濾混合搜尋或可擴展向量存儲的生產級 RAG 系統。 | `mlops/vector-databases/qdrant` |

## 筆記 (note-taking)

筆記技能，用於儲存資訊、協助研究，以及協作進行多工作階段規劃與資訊分享。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `obsidian` | 讀取、搜尋並在 Obsidian 保險庫 (vault) 中建立筆記。 | `note-taking/obsidian` |

## 生產力 (productivity)

用於文件建立、簡報、試算表以及其他生產力工作流的技能。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `google-workspace` | 透過 Python 整合 Gmail、日曆、雲端硬碟、聯絡人、試算表與文件。使用 OAuth2 並具備自動權杖重新整理功能。在 Hermes 虛擬環境中完全以 Google 的 Python 用戶端程式庫執行。 | `productivity/google-workspace` |
| `linear` | 透過 GraphQL API 管理 Linear 問題、專案與團隊。建立、更新、搜尋與組織問題。 | `productivity/linear` |
| `nano-pdf` | 使用 nano-pdf CLI 透過自然語言指令編輯 PDF。修改文字、修正拼字錯誤、更新標題，並對特定頁面進行內容變更，無需手動編輯。 | `productivity/nano-pdf` |
| `notion` | 透過 curl 使用 Notion API 建立與管理頁面、資料庫與區塊。直接在終端機搜尋、建立、更新與查詢 Notion 工作區。 | `productivity/notion` |
| `ocr-and-documents` | 從 PDF 與掃描文件中提取文字。遠端 URL 使用 web_extract，本地文字型 PDF 使用 pymupdf，掃描文件則使用 marker-pdf。DOCX 使用 python-docx，PPTX 則參見 powerpoint 技能。 | `productivity/ocr-and-documents` |
| `powerpoint` | 用於涉及 .pptx 檔案的任何情況 — 包含輸入、輸出或兩者。包含建立投影片、簡報稿；讀取、解析或從任何 .pptx 檔案中提取文字。 | `productivity/powerpoint` |

## 研究 (research)

用於學術研究、論文發現、文獻綜述、網域偵查、市場數據、內容監控與科學知識檢索的技能。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `arxiv` | 使用免費 REST API 從 arXiv 搜尋並檢索學術論文。無需 API 金鑰。可按關鍵字、作者、類別或 ID 搜尋。可結合 web_extract 或 ocr-and-documents 技能閱讀全文。 | `research/arxiv` |
| `blogwatcher` | 使用 blogwatcher CLI 監控部落格與 RSS/Atom 饋送。添加部落格、掃描新文章並追蹤已讀內容。 | `research/blogwatcher` |
| `llm-wiki` | Karpathy 的 LLM Wiki — 構建並維護一個持久、互連的 Markdown 知識庫。攝取來源、查詢編譯好的知識並進行一致性檢查。作為 Obsidian 保險庫運作。 | `research/llm-wiki` |
| `domain-intel` | 使用 Python 標準函式庫進行被動網域偵查。子網域探索、SSL 憑證檢查、WHOIS 查詢、DNS 記錄、網域可用性檢查以及批次多網域分析。無需 API 金鑰。 | `research/domain-intel` |
| `duckduckgo-search` | 透過 DuckDuckGo 進行免費網頁搜尋 — 文字、新聞、圖片、影片。無需 API 金鑰。優先使用 `ddgs` CLI；僅在確認可用後才使用 Python 程式庫。 | `research/duckduckgo-search` |
| `ml-paper-writing` | 為 NeurIPS, ICML, ICLR, ACL, AAAI, COLM 撰寫具備發表品質的機器學習/AI 論文。包含 LaTeX 模板、審稿人指引與引用驗證。 | `research/ml-paper-writing` |
| `polymarket` | 查詢 Polymarket 預測市場數據 — 搜尋市場、獲取價格、掛單簿與價格歷史。透過公開 REST API 唯讀存取，無需 API 金鑰。 | `research/polymarket` |

## 紅隊測試 (red-teaming)

用於 LLM 紅隊測試、越獄 (jailbreaking) 與安全過濾繞過研究的技能。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `godmode` | 使用 G0DM0D3 技術越獄 API 提供的 LLM — 包含 Parseltongue 輸入混淆 (33 種技術)、GODMODE CLASSIC 系統提示詞模板、ULTRAPLINIAN 多模型競賽、編碼提升以及原生 prefill/系統提示詞整合。 | `red-teaming/godmode` |

## 智慧家居 (smart-home)

用於控制智慧家居裝置的技能 — 燈光、開關、感測器與家庭自動化系統。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `openhue` | 透過 OpenHue CLI 控制 Philips Hue 燈光、房間與場景。開關燈、調整亮度、顏色、色溫以及啟動場景。 | `smart-home/openhue` |

## 社群媒體 (social-media)

用於與社群平台互動的技能 — 發文、閱讀、監控與帳號操作。

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `xitter` | 透過 x-cli 終端機用戶端使用官方 X API 憑證與 X/Twitter 互動。 | `social-media/xitter` |

## 軟體開發 (software-development)

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `code-review` | 執行側重安全與品質的徹底程式碼審查的指引。 | `software-development/code-review` |
| `plan` | Hermes 的規劃模式 — 檢查上下文，在主動工作區/後端工作目錄的 `.hermes/plans/` 中撰寫 Markdown 規劃，且不執行實際工作。 | `software-development/plan` |
| `requesting-code-review` | 在完成任務、實作主要功能或合併前使用。透過系統性審查流程驗證工作是否符合要求。 | `software-development/requesting-code-review` |
| `subagent-driven-development` | 在執行具備獨立任務的實作規劃時使用。針對每個任務發送新的 delegate_task，並進行兩階段審查 (規範符合性後進行程式碼品質審查)。 | `software-development/subagent-driven-development` |
| `systematic-debugging` | 在遇到任何臭蟲、測試失敗或非預期行為時使用。包含四階段根因調查 — 在未理解問題前不進行任何修復。 | `software-development/systematic-debugging` |
| `test-driven-development` | 在實作任何功能或修復臭蟲前使用。透過測試先行的方法強制執行 紅-綠-重構 (RED-GREEN-REFACTOR) 迴圈。 | `software-development/test-driven-development` |
| `writing-plans` | 當您具備多步驟任務的規範或要求時使用。建立包含細分任務、精確檔案路徑與完整程式碼範例的綜合實作規劃。 | `software-development/writing-plans` |

---

# 選配技能

選配技能隨儲存庫的 `optional-skills/` 目錄提供，但 **預設不啟用**。它們涵蓋了較重型或利基型的使用案例。請透過以下指令安裝：

```bash
hermes skills install official/<category>/<skill>
```

## 自助式 AI 代理 (autonomous-ai-agents)

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `blackbox` | 將程式碼編寫任務委派給 Blackbox AI CLI 代理。內建評判機制的多模型代理，可透過多個 LLM 執行任務並選擇最佳結果。需要 blackbox CLI 與 Blackbox AI API 金鑰。 | `autonomous-ai-agents/blackbox` |

## 區塊鏈 (blockchain)

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `base` | 查詢 Base (Ethereum L2) 區區塊鏈數據並包含美元定價 — 錢包餘額、代幣資訊、交易細節、Gas 分析、合約檢查、巨鯨偵測以及即時網路統計。無需 API 金鑰。 | `blockchain/base` |
| `solana` | 查詢 Solana 區塊鏈數據並包含美元定價 — 錢包餘額、代幣投資組合、交易細節、NFT、巨鯨偵測以及即時網路統計。無需 API 金鑰。 | `blockchain/solana` |

## 創意 (creative)

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `blender-mcp` | 透過 socket 連線至 blender-mcp 附加元件，直接從 Hermes 控制 Blender。建立 3D 物件、材質、動畫，並執行任意 Blender Python (bpy) 程式碼。 | `creative/blender-mcp` |
| `meme-generation` | 透過選擇模板並使用 Pillow 疊加文字來生成真實的迷因圖片。產生實際的 .png 迷因檔案。 | `creative/meme-generation` |

## 開發運維 (devops)

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `docker-management` | 管理 Docker 容器、映像檔、磁碟卷、網路以及 Compose 堆疊 — 生命週期操作、除錯、清理以及 Dockerfile 優化。 | `devops/docker-management` |

## 電子郵件 (email)

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `agentmail` | 透過 AgentMail 賦予代理專屬的電子郵件信箱。自主地使用代理擁有的電子郵件地址發送、接收和管理郵件。 | `email/agentmail` |

## 健康 (health)

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `neuroskill-bci` | 連接至執行中的 NeuroSkill 實例，並將使用者的即時認知與情緒狀態 (專注力、放鬆程度、情緒等) 納入回應中。需要 BCI 穿戴裝置與 NeuroSkill 桌面應用程式。 | `health/neuroskill-bci` |

## MCP

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `fastmcp` | 使用 Python 中的 FastMCP 構建、測試、檢查、安裝與部署 MCP 伺服器。用於建立新伺服器、將 API 封裝為 MCP 工具、公開資源或提示詞等。 | `mcp/fastmcp` |

## 遷移 (migration)

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `openclaw-migration` | 將使用者的 OpenClaw 自訂軌跡遷移至 Hermes Agent。匯入記憶、SOUL.md、指令允許列表、使用者技能以及選定的工作區資產。 | `migration/openclaw-migration` |

## 生產力 (productivity)

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `telephony` | 賦予 Hermes 電話功能 — 配置並持久化 Twilio 號碼、發送與接收短訊/多媒體簡訊、撥打電話，並透過 Bland.ai 或 Vapi 進行 AI 驅動的外撥電話。 | `productivity/telephony` |

## 研究 (research)

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `bioinformatics` | 通往 bioSkills 與 ClawBio 超過 400 個生物資訊學技能的閘道。涵蓋基因組學、轉錄組學、單細胞、變異調用、藥物基因組學、宏基因組學、結構生物學等。 | `research/bioinformatics` |
| `qmd` | 使用 qmd 在本地搜尋個人知識庫、筆記、文件與會議記錄 — 這是一個結合 BM25、向量搜尋與 LLM 重排的混合檢索引擎。 | `research/qmd` |

## 安全 (security)

| 技能 | 描述 | 路徑 |
|-------|-------------|------|
| `1password` | 設置並使用 1Password CLI (op)。用於安裝 CLI、啟用桌面應用程式整合、登入並為指令讀取/注入密鑰。 | `security/1password` |
| `oss-forensics` | 為 GitHub 儲存庫提供供應鏈調查、證據恢復與取證分析。涵蓋已刪除提交恢復、強制推送偵測、IOC 提取與結構化取證報告。 | `security/oss-forensics` |
| `sherlock` | 在 400 多個社交網路中進行 OSINT 使用者名稱搜尋。透過使用者名稱追蹤社交媒體帳號。 | `security/sherlock` |
