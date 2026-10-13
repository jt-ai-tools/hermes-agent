# GRPO/RL 訓練技能

**使用 TRL 進行群體相對策略最佳化 (GRPO) 的專家級指南**

## 📁 技能結構

```
grpo-rl-training/
├── SKILL.md                              # 主要技能文件（請先閱讀此文件）
├── README.md                             # 本文件
├── templates/
│   └── basic_grpo_training.py            # 生產級訓練模板
└── examples/
    └── reward_functions_library.py       # 20 多個獎勵函數範例
```

## 🚀 快速開始

1. **閱讀 SKILL.md** - 包含所有概念和模式的全面指南
2. **複製 `templates/basic_grpo_training.py`** - 從可運行的程式碼開始
3. **瀏覽 `examples/reward_functions_library.py`** - 為您的任務挑選獎勵函數
4. **根據您的案例進行修改** - 調整資料集、獎勵和組態

## 💡 內容摘要

### SKILL.md (主要文件)
- GRPO 核心概念與演算法基礎
- 完整的實作工作流程（資料集 → 獎勵 → 訓練 → 部署）
- 10 多個附帶程式碼的獎勵函數範例
- 超參數調校指南
- 訓練見解（損失值行為、指標、除錯）
- 疑難排解指南
- 生產環境最佳實踐

### 模板 (Templates)
- **basic_grpo_training.py**：極簡且可直接用於生產環境的訓練腳本
  - 使用 Qwen 2.5 1.5B Instruct
  - 包含 3 個獎勵函數（格式 + 正確性）
  - 使用 LoRA 進行高效訓練
  - 完整註釋，隨時可運行

### 範例 (Examples)
- **reward_functions_library.py**：20 多個經過實戰測試的獎勵函數
  - 正確性獎勵（精確匹配、模糊匹配、數值、程式碼執行）
  - 格式獎勵（XML、JSON、嚴格/寬鬆模式）
  - 長度獎勵（理想長度、最小/最大長度）
  - 風格獎勵（推理品質、引用、重複懲罰）
  - 組合獎勵（多目標優化）
  - 針對常見任務的預設集合

## 📖 Agent 使用說明

當載入此技能到您的 Agent 上下文時：

1. **實作前務必先閱讀 SKILL.md**
2. **從簡單開始** - 使用基於長度的獎勵來驗證設置
3. **增量構建** - 一次添加一個獎勵函數
4. **參考範例** - 從 `reward_functions_library.py` 複製模式
5. **監控訓練** - 觀察獎勵指標（而非損失值！）

## 🎯 常見使用案例

| 任務類型 | 建議獎勵 | 模板 |
|-----------|---------------------|----------|
| 數學推理 | `MATH_REASONING_REWARDS` 預設 | basic_grpo_training.py |
| 程式碼生成 | `CODE_GENERATION_REWARDS` 預設 | 修改模板中的資料集 |
| 摘要生成 | `SUMMARIZATION_REWARDS` 預設 | 調整提示詞 + 獎勵 |
| 問答 (Q&A) | `QA_REWARDS` 預設 | 使用模糊匹配 + 引用 |

## ⚠️ 關鍵提醒

- **訓練期間損失值 (Loss) 會上升** - 這是正常的（它是 KL 散度）
- **使用 3-5 個獎勵函數** - 單一獎勵通常會失敗
- **訓練前測試獎勵** - 獨立為每個函數進行除錯
- **監控 reward_std** - 應保持 > 0.1（避免模式塌陷）
- **從 num_generations=4-8 開始** - 如果顯存允許再擴大

## 🔗 外部資源

- [TRL 官方文件](https://huggingface.co/docs/trl)
- [DeepSeek R1 論文](https://arxiv.org/abs/2501.12948)
- [Open R1 實作](https://github.com/huggingface/open-r1)
- [Unsloth (快 2-3 倍)](https://docs.unsloth.ai/)

## 📝 版本

**v1.0.0** - 初始版本 (2025年1月)

## 👨‍💻 維護者

Orchestra Research
如有問題或建議，請造訪 https://orchestra.com

---

**授權協議：** MIT
**最後更新：** 2025年1月
