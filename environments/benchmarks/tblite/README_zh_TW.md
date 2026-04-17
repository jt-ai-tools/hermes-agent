# OpenThoughts-TBLite 評估環境

此環境用於在 [OpenThoughts-TBLite](https://huggingface.co/datasets/open-thoughts/OpenThoughts-TBLite) 基準測試上評估終端代理 (terminal agents)，該測試是 [Terminal-Bench 2.0](https://www.tbench.ai/leaderboard/terminal-bench/2.0) 的一個經過難度校準的子集。

## 來源

OpenThoughts-TBLite 由 [OpenThoughts](https://www.openthoughts.ai/) 代理團隊與 [Snorkel AI](https://snorkel.ai/) 及 [Bespoke Labs](https://bespokelabs.ai/) 合作開發。原始數據集和文件位於：

- **數據集 (來源):** [open-thoughts/OpenThoughts-TBLite](https://huggingface.co/datasets/open-thoughts/OpenThoughts-TBLite)
- **GitHub:** [open-thoughts/OpenThoughts-TBLite](https://github.com/open-thoughts/OpenThoughts-TBLite)
- **部落格文章:** [openthoughts.ai/blog/openthoughts-tblite](https://www.openthoughts.ai/blog/openthoughts-tblite)

## 我們的數據集

我們將原始數據轉換為與我們的 Terminal-Bench 2.0 環境相同的架構（預構建的 Docker Hub 映像、base64 編碼的測試 tarball 等），並發佈為：

- **數據集 (我們的):** [NousResearch/openthoughts-tblite](https://huggingface.co/datasets/NousResearch/openthoughts-tblite)
- **Docker 映像:** Docker Hub 上的 `nousresearch/tblite-<task-name>:latest`（100 個映像）

轉換腳本位於 `scripts/prepare_tblite_dataset.py`。

## 為什麼選擇 TBLite？

Terminal-Bench 2.0 是目前針對終端代理最強大的前沿評估工具之一，但當模型的得分接近底線時（例如 Qwen 3 8B 得分 <1%），許多變化在總分上看起來幾乎相同。TBLite 通過以 Claude Haiku 4.5 作為參考校準任務難度來解決這個問題：

| 難度 | 通過率範圍 | 任務數量 |
|------------|----------------|-------|
| 簡單 (Easy) | >= 70%         | 40    |
| 中等 (Medium) | 40-69%         | 26    |
| 困難 (Hard) | 10-39%         | 26    |
| 極限 (Extreme) | < 10%          | 8     |

這提供了足夠的可解任務來快速檢測微小的改進，同時保留了足夠的困難任務以避免分數飽和。TBLite 與 TB2 分數之間的相關性為 **r = 0.911**。

此外，TBLite 的執行速度比完整版 TB2 快 2.6 到 8 倍，非常適合用於迭代開發。

## 使用方法

```bash
# 執行完整基準測試
python environments/benchmarks/tblite/tblite_env.py evaluate

# 過濾特定任務
python environments/benchmarks/tblite/tblite_env.py evaluate \
    --env.task_filter "broken-python,pandas-etl"

# 使用不同模型
python environments/benchmarks/tblite/tblite_env.py evaluate \
    --server.model_name "qwen/qwen3-30b"
```

## 架構

`TBLiteEvalEnv` 是 `TerminalBench2EvalEnv` 的一個輕量級子類。所有的評估邏輯（代理迴圈、Docker 沙盒管理、測試驗證、指標）皆為繼承而來。僅有預設設定有所不同：

| 設定        | TB2                              | TBLite                                  |
|----------------|----------------------------------|-----------------------------------------|
| 數據集 (Dataset) | `NousResearch/terminal-bench-2`  | `NousResearch/openthoughts-tblite`      |
| 任務數量 (Tasks) | 89                               | 100                                     |
| 任務超時時間 | 1800s (30 分鐘)                   | 1200s (20 分鐘)                          |
| Wandb 名稱     | `terminal-bench-2`               | `openthoughts-tblite`                   |

## 引用

```bibtex
@software{OpenThoughts-TBLite,
  author = {OpenThoughts-Agent team, Snorkel AI, Bespoke Labs},
  month = Feb,
  title = {{OpenThoughts-TBLite: A High-Signal Benchmark for Iterating on Terminal Agents}},
  howpublished = {https://www.openthoughts.ai/blog/openthoughts-tblite},
  year = {2026}
}
```
