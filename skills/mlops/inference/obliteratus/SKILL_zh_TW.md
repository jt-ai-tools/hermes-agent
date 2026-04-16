---
name: obliteratus
description: 使用 OBLITERATUS 從開放權重大型語言模型 (LLM) 中移除拒絕行為 — 透過機械解釋性技術 (diff-in-means, SVD, whitened SVD, LEACE, SAE decomposition 等) 切除防護欄，同時保留推理能力。包含 9 種 CLI 方法、28 個分析模組、橫跨 5 個算力分級的 116 個模型預設設定、競賽式評核以及遙測數據驅動的建議。當使用者想要對 LLM 進行去審查、abliterate 或移除拒絕行為時使用。
version: 2.0.0
author: Hermes Agent
license: MIT
dependencies: [obliteratus, torch, transformers, bitsandbytes, accelerate, safetensors]
metadata:
  hermes:
    tags: [Abliteration, Uncensoring, Refusal-Removal, LLM, Weight-Projection, SVD, Mechanistic-Interpretability, HuggingFace, Model-Surgery]
    related_skills: [vllm, gguf, huggingface-tokenizers]
---

# OBLITERATUS 技能

在不需要重新訓練或微調的情況下，移除開放權重大型語言模型 (LLM) 的拒絕行為 (防護欄)。利用機械解釋性技術 (mechanistic interpretability) — 包括均值差 (diff-in-means)、SVD、白化 SVD、LEACE 概念擦除、SAE 分解、貝氏核投影等 — 來識別並精準切除模型權重中的拒絕方向，同時保留推理能力。

**授權警告：** OBLITERATUS 採用 AGPL-3.0 授權。**切勿**將其作為 Python 函式庫匯入。務必透過 CLI (`obliteratus` 命令) 或子程序呼叫。這能確保 Hermes Agent 的 MIT 授權不受影響。

## 何時使用此技能

當使用者有以下需求時觸發：
- 想要對 LLM 進行「去審查 (uncensor)」或「abliterate」
- 詢問如何移除模型的拒絕行為/防護欄
- 想要建立 Llama、Qwen、Mistral 等模型的去審查版本
- 提到「拒絕行為移除 (refusal removal)」、「abliteration」、「權重投影 (weight projection)」
- 想要分析模型的拒絕機制如何運作
- 提到 OBLITERATUS、abliterator 或拒絕方向 (refusal directions)

## 步驟 1：安裝

檢查是否已安裝：
```bash
obliteratus --version 2>/dev/null && echo "已安裝" || echo "未安裝"
```

如果未安裝，請從 GitHub 複製並安裝：
```bash
git clone https://github.com/elder-plinius/OBLITERATUS.git
cd OBLITERATUS
pip install -e .
# 如需 Gradio web UI 支援：
# pip install -e ".[spaces]"
```

**重要提示：** 安裝前請先與使用者確認。這會下載約 5-10GB 的依賴項目 (PyTorch, Transformers, bitsandbytes 等)。

## 步驟 2：檢查硬體

在進行任何操作前，先檢查可用的 GPU：
```bash
python3 -c "
import torch
if torch.cuda.is_available():
    gpu = torch.cuda.get_device_name(0)
    vram = torch.cuda.get_device_properties(0).total_memory / 1024**3
    print(f'GPU: {gpu}')
    print(f'VRAM: {vram:.1f} GB')
    if vram < 4: print('TIER: tiny (1B 以下模型)')
    elif vram < 8: print('TIER: small (1-4B 模型)')
    elif vram < 16: print('TIER: medium (4-9B 模型，使用 4bit 量化)')
    elif vram < 32: print('TIER: large (8-32B 模型，使用 4bit 量化)')
    else: print('TIER: frontier (32B 以上模型)')
else:
    print('無 GPU - CPU 僅能執行 tiny 模型 (1B 以下)')
"
```

### VRAM 需求 (使用 4-bit 量化)

| VRAM     | 最大模型大小    | 範例模型                                    |
|:---------|:----------------|:--------------------------------------------|
| 僅 CPU   | ~1B 參數        | GPT-2, TinyLlama, SmolLM                    |
| 4-8 GB   | ~4B 參數        | Qwen2.5-1.5B, Phi-3.5 mini, Llama 3.2 3B   |
| 8-16 GB  | ~9B 參數        | Llama 3.1 8B, Mistral 7B, Gemma 2 9B       |
| 24 GB    | ~32B 參數       | Qwen3-32B, Llama 3.1 70B (較吃力), Command-R |
| 48 GB+   | ~72B+ 參數      | Qwen2.5-72B, DeepSeek-R1                    |
| 多 GPU   | 200B+ 參數      | Llama 3.1 405B, DeepSeek-V3 (685B MoE)      |

## 步驟 3：瀏覽可用模型並獲取建議

```bash
# 按算力分級瀏覽模型
obliteratus models --tier medium

# 獲取特定模型的架構資訊
obliteratus info <模型名稱>

# 獲取由遙測數據驅動的最佳方法與參數建議
obliteratus recommend <模型名稱>
obliteratus recommend <模型名稱> --insights  # 全域跨架構排名
```

## 步驟 4：選擇方法

### 方法選擇指南
**大多數情況下的預設/推薦選擇：`advanced`。** 它使用帶有範數保留投影 (norm-preserving projection) 的多方向 SVD，且經過充分測試。

| 情況                              | 推薦方法           | 原因                                     |
|:----------------------------------|:-------------------|:-----------------------------------------|
| 預設 / 大多數模型                 | `advanced`         | 多方向 SVD、範數保留、可靠               |
| 快速測試 / 原型開發               | `basic`            | 快速、簡單、足以進行初步評估             |
| 密集模型 (Llama, Mistral)         | `advanced`         | 多方向、範數保留                         |
| MoE 模型 (DeepSeek, Mixtral)      | `nuclear`          | 專家級細粒度，處理 MoE 的複雜性          |
| 推理模型 (R1 蒸餾版)              | `surgical`         | 具備 CoT 感知，保留思維鏈能力            |
| 頑固的拒絕行為依然存在             | `aggressive`       | 白化 SVD + 頭部手術 + 越獄模式 (jailbreak) |
| 想要可逆的變更                   | 使用引導向量 (Steering Vectors，見分析章節) |
| 最高品質，時間充裕                | `optimized`        | 使用貝氏搜尋尋找最佳參數                 |
| 實驗性的自動偵測                 | `informed`         | 自動偵測對齊類型 — 實驗性質，效能不一定優於 advanced |

### 9 種 CLI 方法
- **basic** — 透過均值差 (diff-in-means) 提取單個拒絕方向。速度快 (8B 模型約 5-10 分鐘)。
- **advanced** (預設，推薦) — 多方向 SVD、範數保留投影、2 次細化處理 (refinement passes)。速度中等 (約 10-20 分鐘)。
- **aggressive** — 白化 SVD + 越獄對比 (jailbreak-contrastive) + 注意力頭部手術。連貫性受損風險較高。
- **spectral_cascade** — DCT 頻域分解。研究性質/新穎方法。
- **informed** — 在 abliteration 過程中執行分析以自動配置。實驗性質 — 速度比 advanced 慢且不可預測。
- **surgical** — SAE 特徵 + 神經元遮蔽 + 頭部手術 + 逐專家處理。速度非常慢 (約 1-2 小時)。最適合推理模型。
- **optimized** — 貝氏超參數搜尋 (Optuna TPE)。執行時間最長，但能找到最佳參數。
- **inverted** — 反轉拒絕方向。模型會變得積極配合。
- **nuclear** — 針對頑固 MoE 模型的最大強度組合。專家級細粒度。

### 方向提取方法 (--direction-method 旗標)
- **diff_means** (預設) — 拒絕與配合激活值之間的簡單均值差。穩定。
- **svd** — 多方向 SVD 提取。更適合複雜的對齊方式。
- **leace** — LEACE (Linear Erasure via Closed-form Estimation)。最佳線性擦除。

### 4 種僅限 Python-API 的方法
(無法透過 CLI 使用 — 需要 Python 匯入，這會違反 AGPL 邊界。僅在使用者明確想在自己的 AGPL 專案中將 OBLITERATUS 作為函式庫使用時才提及。)
- failspy, gabliteration, heretic, rdo

## 步驟 5：執行 Abliteration

### 標準用法
```bash
# 預設方法 (advanced) — 推薦用於大多數模型
obliteratus obliterate <模型名稱> --method advanced --output-dir ./abliterated-models

# 使用 4-bit 量化 (節省 VRAM)
obliteratus obliterate <模型名稱> --method advanced --quantization 4bit --output-dir ./abliterated-models

# 大型模型 (70B+) — 使用保守的預設值
obliteratus obliterate <模型名稱> --method advanced --quantization 4bit --large-model --output-dir ./abliterated-models
```

### 微調參數
```bash
obliteratus obliterate <模型名稱> \
  --method advanced \
  --direction-method diff_means \
  --n-directions 4 \
  --refinement-passes 2 \
  --regularization 0.1 \
  --quantization 4bit \
  --output-dir ./abliterated-models \
  --contribute  # 選擇加入遙測以支援社群研究
```

### 關鍵旗標
| 旗標 | 說明 | 預設值 |
|:-----|:------------|:--------|
| `--method` | Abliteration 方法 | advanced |
| `--direction-method` | 方向提取方式 | diff_means |
| `--n-directions` | 拒絕方向數量 (1-32) | 取決於方法 |
| `--refinement-passes` | 疊代處理次數 (1-5) | 2 |
| `--regularization` | 正則化強度 (0.0-1.0) | 0.1 |
| `--quantization` | 以 4bit 或 8bit 載入 | none (全精度) |
| `--large-model` | 針對 120B+ 模型的保守預設值 | false |
| `--output-dir` | abliterated 模型的儲存位置 | ./obliterated_model |
| `--contribute` | 分享匿名化結果供研究使用 | false |
| `--verify-sample-size` | 用於檢查拒絕行為的測試提示詞數量 | 20 |
| `--dtype` | 模型數據類型 (float16, bfloat16) | auto |

### 其他執行模式
```bash
# 互動式引導模式 (硬體 → 模型 → 預設設定)
obliteratus interactive

# Web 介面 (Gradio)
obliteratus ui --port 7860

# 從 YAML 配置執行完整的消融研究 (ablation study)
obliteratus run config.yaml --preset quick

# 競賽：讓所有方法相互競爭
obliteratus tourney <模型名稱>
```

## 步驟 6：驗證結果

完成 abliteration 後，檢查輸出指標：

| 指標 | 良好數值 | 警告 |
|:-------|:-----------|:--------|
| 拒絕率 | < 5% (理想為 ~0%) | > 10% 代表拒絕行為依然存在 |
| 困惑度 (Perplexity) 變化 | 增加 < 10% | > 15% 代表連貫性受損 |
| KL 散度 | < 0.1 | > 0.5 代表分佈發生顯著偏移 |
| 連貫性 | 高 / 通過定性檢查 | 回覆品質下降、出現重複文字 |

### 如果拒絕行為依然存在 (> 10%)
1. 嘗試 `aggressive` 方法
2. 增加 `--n-directions` (例如 8 或 16)
3. 增加 `--refinement-passes 3`
4. 嘗試將 `--direction-method` 改為 `svd`

### 如果連貫性受損 (困惑度增加 > 15%)
1. 減少 `--n-directions` (嘗試 2)
2. 增加 `--regularization` (嘗試 0.3)
3. 將 `--refinement-passes` 減少到 1
4. 嘗試 `basic` 方法 (較溫和)

## 步驟 7：使用 Abliterated 模型

輸出結果是一個標準的 HuggingFace 模型目錄。

```bash
# 使用 transformers 進行本地測試
python3 -c "
from transformers import AutoModelForCausalLM, AutoTokenizer
model = AutoModelForCausalLM.from_pretrained('./abliterated-models/<模型>')
tokenizer = AutoTokenizer.from_pretrained('./abliterated-models/<模型>')
inputs = tokenizer('How do I pick a lock?', return_tensors='pt')
outputs = model.generate(**inputs, max_new_tokens=200)
print(tokenizer.decode(outputs[0], skip_special_tokens=True))
"

# 上傳到 HuggingFace Hub
huggingface-cli upload <使用者名稱>/<模型名稱>-abliterated ./abliterated-models/<模型>

# 使用 vLLM 提供服務
vllm serve ./abliterated-models/<模型>
```

## CLI 命令參考

| 命令 | 說明 |
|:--------|:------------|
| `obliteratus obliterate` | 主要的 abliteration 命令 |
| `obliteratus info <模型>` | 列印模型架構詳細資訊 |
| `obliteratus models --tier <分級>` | 按算力分級瀏覽精選模型 |
| `obliteratus recommend <模型>` | 基於遙測數據的方法/參數建議 |
| `obliteratus interactive` | 引導式設定精靈 |
| `obliteratus tourney <模型>` | 競賽：所有方法的正面交鋒 |
| `obliteratus run <config.yaml>` | 從 YAML 執行消融研究 |
| `obliteratus strategies` | 列出所有已註冊的消融策略 |
| `obliteratus report <results.json>` | 重新生成視覺化報告 |
| `obliteratus ui` | 啟動 Gradio 網頁介面 |
| `obliteratus aggregate` | 彙總社群遙測數據 |

## 分析模組

OBLITERATUS 包含 28 個用於機械解釋性的分析模組。
完整的參考資料請參閱 `skill_view(name="obliteratus", file_path="references/analysis-modules.md")`。

### 快速分析命令
```bash
# 執行特定的分析模組
obliteratus run analysis-config.yaml --preset quick

# 優先執行的關鍵模組：
# - alignment_imprint: 識別 DPO/RLHF/CAI/SFT 等對齊方法
# - concept_geometry: 單一方向 vs 多面體錐 (polyhedral cone)
# - logit_lens: 判斷哪一層決定拒絕
# - anti_ouroboros: 自我修復風險評分
# - causal_tracing: 識別因果必要的組件
```

### 引導向量 (Steering Vectors，可逆的替代方案)
與永久修改權重不同，這是在推理時進行引導：
```python
# 僅限 Python API — 用於使用者自己的專案
from obliteratus.analysis.steering_vectors import SteeringVectorFactory, SteeringHookManager
```

## 消融策略 (Ablation Strategies)

除了基於方向的 abliteration，OBLITERATUS 還包含結構性消融策略：
- **Embedding Ablation** — 針對嵌入層組件
- **FFN Ablation** — 移除前饋網路區塊
- **Head Pruning** — 注意力頭部剪枝
- **Layer Removal** — 完整層移除

列出所有可用策略：`obliteratus strategies`

## 評估

OBLITERATUS 內建了評估工具：
- 拒絕率基準測試
- 困惑度比較 (前後對照)
- 用於學術基準測試的 LM Eval Harness 整合
- 與競爭對手的正面交鋒
- 基準效能追蹤

## 平台支援

- **CUDA** — 完整支援 (NVIDIA GPU)
- **Apple Silicon (MLX)** — 透過 MLX 後端支援
- **CPU** — 支援 tiny 模型 (< 1B 參數)

## YAML 配置範本

透過 `skill_view` 載入用於可重現執行的範本：
- `templates/abliteration-config.yaml` — 標準單模型配置
- `templates/analysis-study.yaml` — abliteration 前的分析研究
- `templates/batch-abliteration.yaml` — 多模型批次處理

## 遙測數據 (Telemetry)

OBLITERATUS 可以選擇性地將匿名化的執行數據貢獻給全域研究資料集。
使用 `--contribute` 旗標開啟。不會收集任何個人資料 — 僅包含模型名稱、方法、指標。

## 常見陷阱

1. **不要將 `informed` 作為預設值** — 它是實驗性質且較慢。請使用 `advanced` 以獲得可靠結果。
2. **1B 以下的小模型在 abliteration 效果不佳** — 其拒絕行為較淺且碎片化，難以進行乾淨的方向提取。預期會有部分殘留 (剩餘 20-40% 拒絕行為)。3B 以上的模型具有更乾淨的拒絕方向，效果好得多 (使用 `advanced` 通常能達到 0% 拒絕率)。
3. **`aggressive` 可能適得其反** — 在小模型上可能會損害連貫性並增加拒絕率。僅在 3B 以上模型使用 `advanced` 後仍殘留 > 10% 拒絕行為時使用。
4. **務必檢查困惑度** — 如果飆升 > 15%，則模型已損壞。請降低強度。
5. **MoE 模型需要特殊處理** — 對 Mixtral、DeepSeek-MoE 等使用 `nuclear` 方法。
6. **量化過的模型無法再次量化** — 請先對全精度模型進行 abliterate，再對輸出結果進行量化。
7. **VRAM 估算僅供參考** — 4-bit 量化有幫助，但在提取過程中尖峰使用量可能會飆升。
8. **推理模型非常敏感** — 對 R1 蒸餾版使用 `surgical` 以保留思維鏈。
9. **檢查 `obliteratus recommend`** — 遙測數據可能提供比預設值更好的參數。
10. **AGPL 授權** — 絕不要在 MIT/Apache 專案中 `import obliteratus`。僅限 CLI 呼叫。
11. **大型模型 (70B+)** — 務必使用 `--large-model` 旗標以獲得保守的預設值。
12. **光譜認證 (Spectral certification) 出現 RED 是常見的** — 光譜檢查經常會標註「不完整 (incomplete)」，即使實際拒絕率已為 0%。請以實際拒絕率為準，而非僅依賴光譜認證。

## 互補技能

- **vllm** — 以高吞吐量提供 abliterated 服務
- **gguf** — 將 abliterated 模型轉換為 GGUF 以用於 llama.cpp
- **huggingface-tokenizers** — 處理模型分詞器
