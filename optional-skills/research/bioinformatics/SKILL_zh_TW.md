---
name: bioinformatics
description: 存取來自 bioSkills 和 ClawBio 的 400 多項生物資訊技能。涵蓋基因體學、轉錄體學、單細胞、變異呼叫 (Variant Calling)、藥物基因體學、總體基因體學、結構生物學等。可按需獲取特定領域的參考資料。
version: 1.0.0
platforms: [linux, macos]
metadata:
  hermes:
    tags: [bioinformatics, genomics, sequencing, biology, research, science]
    category: research
---

# 生物資訊技能入口 (Bioinformatics Skills Gateway)

當被問及生物資訊、基因體學、定序、變異呼叫、基因表現、單細胞分析、蛋白質結構、藥物基因體學、總體基因體學、系統發生學或任何計算生物學任務時使用。

此技能是通往兩個開源生物資訊技能庫的入口。它不是捆綁數百個領域特定技能，而是對其進行索引並按需獲取你需要的技能。

## 來源

◆ **bioSkills** — 385 個參考技能（程式碼模式、參數指南、決策樹）
  Repo: https://github.com/GPTomics/bioSkills
  格式：每個主題一個 SKILL.md，包含程式碼範例。支援 Python/R/CLI。

◆ **ClawBio** — 33 個可執行的管線 (Pipeline) 技能（可執行腳本、可重現性組合包）
  Repo: https://github.com/ClawBio/ClawBio
  格式：帶有展示的 Python 腳本。每次分析都會匯出 report.md + commands.sh + environment.yml。

## 如何獲取並使用技能

1. 從下面的索引中識別領域和技能名稱。
2. 複製相關 Repo（使用淺層複製以節省時間）：
   ```bash
   # bioSkills (參考資料)
   git clone --depth 1 https://github.com/GPTomics/bioSkills.git /tmp/bioSkills

   # ClawBio (可執行管線)
   git clone --depth 1 https://github.com/ClawBio/ClawBio.git /tmp/ClawBio
   ```
3. 閱讀特定技能：
   ```bash
   # bioSkills — 每個技能位於：<category>/<skill-name>/SKILL.md
   cat /tmp/bioSkills/variant-calling/gatk-variant-calling/SKILL.md

   # ClawBio — 每個技能位於：skills/<skill-name>/
   cat /tmp/ClawBio/skills/pharmgx-reporter/README.md
   ```
4. 將獲取的技能作為參考資料。這些**不是** Hermes 格式的技能——請將其視為專家領域指南。它們包含正確的參數、適當的工具旗標和經過驗證的管線。

## 領域技能索引

### 序列基礎 (Sequence Fundamentals)
bioSkills:
  sequence-io/ — 讀取序列、寫入序列、格式轉換、批量處理、壓縮檔案、fastq 品質、過濾序列、雙端 fastq、序列統計
  sequence-manipulation/ — 序列物件、反向互補、轉錄-轉譯、模體搜尋 (Motif search)、密碼子使用、序列特性、序列切片
ClawBio:
  seq-wrangler — 序列 QC、比對和 BAM 處理（封裝了 FastQC, BWA, SAMtools）

### 讀取品質控制與比對 (Read QC & Alignment)
bioSkills:
  read-qc/ — 品質報告、fastp 工作流、轉接頭修剪 (Adapter trimming)、品質過濾、UMI 處理、污染篩選、rnaseq-qc
  read-alignment/ — bwa-alignment, star-alignment, hisat2-alignment, bowtie2-alignment
  alignment-files/ — sam-bam 基礎、比對排序、比對過濾、bam 統計、重複處理、pileup 生成

### 變異呼叫與註釋 (Variant Calling & Annotation)
bioSkills:
  variant-calling/ — gatk-variant-calling, deepvariant, variant-calling (bcftools), 聯合呼叫 (Joint-calling), 結構變異呼叫、過濾最佳實務、變異註釋、變異標準化、vcf 基礎、vcf 操作、vcf 統計、共識序列、臨床解釋
ClawBio:
  vcf-annotator — 具備祖源感知背景的 VEP + ClinVar + gnomAD 註釋
  variant-annotation — 變異註釋管線

### 差異表現分析 (Differential Expression, Bulk RNA-seq)
bioSkills:
  differential-expression/ — deseq2 基礎、edger 基礎、批次校正、差異表現結果、差異表現視覺化、時間序列差異表現
  rna-quantification/ — 無比對定量 (Salmon/kallisto)、featurecounts 計數、tximport 工作流、計數矩陣 QC
  expression-matrix/ — 計數攝取、基因 ID 映射、元數據合併、稀疏矩陣處理
ClawBio:
  rnaseq-de — 包含 QC、標準化和視覺化的完整差異表現管線
  diff-visualizer — 差異表現結果的豐富視覺化與報告

### 單細胞 RNA 定序 (Single-Cell RNA-seq)
bioSkills:
  single-cell/ — 預處理、分群、批次整合、細胞註釋、細胞通訊、雙細胞檢測、標記基因註釋、軌跡推斷、多模態整合、perturb-seq, scatac-analysis, 譜系追蹤、代謝物通訊、數據 I/O
ClawBio:
  scrna-orchestrator — 完整的 Scanpy 管線（QC、分群、標記基因、註釋）
  scrna-embedding — 基於 scVI 的潛在嵌入與批次整合

### 空間轉錄體學 (Spatial Transcriptomics)
bioSkills:
  spatial-transcriptomics/ — 空間數據 I/O、空間預處理、空間領域、空間反摺積 (Deconvolution)、空間通訊、空間鄰居、空間統計、空間視覺化、空間多體學、空間蛋白質體學、圖像分析

### 表觀基因體學 (Epigenomics)
bioSkills:
  chip-seq/ — 峰呼叫 (Peak-calling)、差異結合、模體分析、峰註釋、chipseq-qc、chipseq 視覺化、超級增強子
  atac-seq/ — atac 峰呼叫、atac-qc、差異可及性、足跡分析 (Footprinting)、模體偏差、核小體定位
  methylation-analysis/ — bismark 比對、甲基化呼叫、DMR 檢測、methylkit 分析
  hi-c-analysis/ — hic 數據 I/O、TAD 檢測、環呼叫 (Loop-calling)、分室分析 (Compartment analysis)、接觸對、矩陣操作、hic 視覺化、hic 差異分析
ClawBio:
  methylation-clock — 表觀遺傳時鐘 (Epigenetic age) 估計

### 藥物基因體學與臨床 (Pharmacogenomics & Clinical)
bioSkills:
  clinical-databases/ — clinvar 查詢、gnomad 頻率、dbsnp 查詢、藥物基因體學、多基因風險、HLA 分型、變異優先順序、體細胞特徵、腫瘤突變負荷、myvariant 查詢
ClawBio:
  pharmgx-reporter — 來自 23andMe/AncestryDNA 的 PGx 報告（12 個基因、31 個 SNP、51 種藥物）
  drug-photo — 藥物照片 → 個人化 PGx 劑量卡（透過視覺）
  clinpgx — 用於基因-藥物數據和 CPIC 指南的 ClinPGx API
  gwas-lookup — 跨 9 個基因體資料庫的聯合變異查詢
  gwas-prs — 來自消費級基因數據的多基因風險評分
  nutrigx_advisor — 來自消費級基因數據的個人化營養建議

### 群體遺傳學與 GWAS (Population Genetics & GWAS)
bioSkills:
  population-genetics/ — 關聯測試 (PLINK GWAS), plink 基礎、群體結構、連鎖不平衡、scikit-allel 分析、選汰統計
  causal-genomics/ — 孟德爾隨機化、精細映射 (Fine-mapping)、共定位分析、中介分析、多效性檢測
  phasing-imputation/ — 單倍型相位化 (Phasing)、基因型填補 (Imputation)、填補 QC、參考面板
ClawBio:
  claw-ancestry-pca — 相對於 SGDP 參考面板的祖源 PCA

### 總體基因體學與微生物體 (Metagenomics & Microbiome)
bioSkills:
  metagenomics/ — kraken 分類、metaphlan 概況分析、豐度估計、功能概況分析、AMR 檢測、菌株追蹤、總體基因體視覺化
  microbiome/ — 擴增子處理、多樣性分析、差異豐度、分類分配、功能預測、qiime2 工作流
ClawBio:
  claw-metagenomics — 散彈槍總體基因體概況分析（分類、耐藥體、功能途徑）

### 基因體組裝與註釋 (Genome Assembly & Annotation)
bioSkills:
  genome-assembly/ — hifi 組裝、長讀取組裝、短讀取組裝、總體基因體組裝、組裝拋光、組裝 QC、支架建構 (Scaffolding)、污染檢測
  genome-annotation/ — 真核生物基因預測、原核生物註釋、功能註釋、ncrna 註釋、重複序列註釋、註釋轉移
  long-read-sequencing/ — 鹼基識別 (Basecalling)、長讀取比對、長讀取 QC、clair3 變異、結構變異、medaka 拋光、奈米孔甲基化、isoseq 分析

### 結構生物學與化學資訊學 (Structural Biology & Chemoinformatics)
bioSkills:
  structural-biology/ — alphafold 預測、現代結構預測、結構 I/O、結構導覽、結構修改、幾何分析
  chemoinformatics/ — 分子 I/O、分子描述符、相似性搜尋、子結構搜尋、虛擬篩選、ADMET 預測、反應列舉
ClawBio:
  struct-predictor — 本地 AlphaFold/Boltz/Chai 結構預測與比較

### 蛋白質體學 (Proteomics)
bioSkills:
  proteomics/ — 數據導入、胜肽鑑定、蛋白質推斷、定量、差異豐度、DIA 分析、PTM 分析、蛋白質體學 QC、光譜庫
ClawBio:
  proteomics-de — 蛋白質體學差異表現

### 路徑分析與基因網路 (Pathway Analysis & Gene Networks)
bioSkills:
  pathway-analysis/ — GO 富集、GSEA, KEGG 路徑、Reactome 路徑、WikiPathways、富集視覺化
  gene-regulatory-networks/ — scenic regulons, 共表現網路、差異網路、多體學 GRN、擾動模擬

### 免疫資訊學 (Immunoinformatics)
bioSkills:
  immunoinformatics/ — MHC 結合預測、表位預測、新抗原預測、免疫原性評分、TCR-表位結合
  tcr-bcr-analysis/ — mixcr 分析、scirpy 分析、immcantation 分析、免疫庫視覺化、vdjtools 分析

### CRISPR 與基因體工程 (CRISPR & Genome Engineering)
bioSkills:
  crispr-screens/ — mageck 分析、jacks 分析、Hit 呼叫、篩選 QC、庫設計、crispresso 編輯、鹼基編輯分析、批次校正
  genome-engineering/ — grna 設計、脫靶預測、HDR 模板設計、鹼基編輯設計、引導編輯 (Prime editing) 設計

### 工作流管理 (Workflow Management)
bioSkills:
  workflow-management/ — snakemake 工作流、nextflow 管線、cwl 工作流、wdl 工作流
ClawBio:
  repro-enforcer — 將任何分析匯出為可重現性組合包（Conda 環境 + Singularity + 檢查碼）
  galaxy-bridge — 存取來自 usegalaxy.org 的 8,000 多個 Galaxy 工具

### 特殊領域 (Specialized Domains)
bioSkills:
  alternative-splicing/ — 剪接定量、差異剪接、異構體切換、sashimi 圖、單細胞剪接、剪接 QC
  ecological-genomics/ — edna 元條碼、景觀基因體學、保育遺傳學、生物多樣性指標、群落生態學、物種劃分
  epidemiological-genomics/ — 病原體分型、變異監測、系統動力學、傳播推斷、AMR 監測
  liquid-biopsy/ — cfdna 預處理、ctdna 突變檢測、片段分析、腫瘤比例估計、基於甲基化的檢測、縱向監測
  epitranscriptomics/ — m6a 峰呼叫、m6a 差異分析、m6anet 分析、merip 預處理、修飾視覺化
  metabolomics/ — xcms 預處理、代謝物註釋、標準化 QC、統計分析、路徑映射、脂質體學、標靶分析、msdial 預處理
  flow-cytometry/ — fcs 處理、門控分析 (Gating)、補償轉換、分群分型、差異分析、細胞計數 QC、雙細胞檢測、微珠標準化
  systems-biology/ — 通量平衡分析、代謝重建、基因必需性、背景特定模型、模型策展
  rna-structure/ — 二級結構預測、ncrna 搜尋、結構探測

### 數據視覺化與報告 (Data Visualization & Reporting)
bioSkills:
  data-visualization/ — ggplot2 基礎、熱圖分群、火山圖自定義、circos 圖、基因體瀏覽器軌跡、交互式視覺化、多面板圖表、網路視覺化、upset 圖、配色方案、特殊體學圖表、基因體軌跡
  reporting/ — rmarkdown 報告、quarto 報告、jupyter 報告、自動化 QC 報告、圖表匯出
ClawBio:
  profile-report — 分析概況報告
  data-extractor — 從科學圖表中提取數值數據（透過視覺）
  lit-synthesizer — PubMed/bioRxiv 搜尋、摘要、引用圖譜
  pubmed-summariser — 帶有結構化簡報的基因/疾病 PubMed 搜尋

### 資料庫存取 (Database Access)
bioSkills:
  database-access/ — entrez 搜尋、entrez 獲取、entrez 連結、blast 搜尋、本地 blast、sra 數據、geo 數據、uniprot 存取、批量下載、交互資料庫、序列相似性
ClawBio:
  ukb-navigator — 跨 12,000 多個 UK Biobank 欄位的語義搜尋
  clinical-trial-finder — 臨床試驗發現

### 實驗設計 (Experimental Design)
bioSkills:
  experimental-design/ — 檢定力分析 (Power analysis)、樣本數、批次設計、多重檢定

### 體學機器學習 (Machine Learning for Omics)
bioSkills:
  machine-learning/ — 體學分類器、生物標記發現、存活分析、模型驗證、預測解釋、地圖集映射
ClawBio:
  claw-semantic-sim — 疾病文獻的語義相似度索引 (PubMedBERT)
  omics-target-evidence-mapper — 聚合跨體學來源的標靶級證據

## 環境設定

這些技能假設使用的是生物資訊工作站。常見依賴項：

```bash
# Python
pip install biopython pysam cyvcf2 pybedtools pyBigWig scikit-allel anndata scanpy mygene

# R/Bioconductor
Rscript -e 'BiocManager::install(c("DESeq2","edgeR","Seurat","clusterProfiler","methylKit"))'

# CLI 工具 (Ubuntu/Debian)
sudo apt install samtools bcftools ncbi-blast+ minimap2 bedtools

# CLI 工具 (macOS)
brew install samtools bcftools blast minimap2 bedtools

# 或透過 Conda (建議用於可重現性)
conda install -c bioconda samtools bcftools blast minimap2 bedtools fastp kraken2
```

## 注意事項

- 獲取的技能**不是** Hermes SKILL.md 格式。它們使用自己的結構（bioSkills：程式碼模式食譜；ClawBio：README + Python 腳本）。請將其視為專家參考資料。
- bioSkills 是參考指南——它們展示了正確的參數和程式碼模式，但不是可執行的管線。
- ClawBio 技能是可執行的——許多具備 `--demo` 旗標，可以直接執行。
- 兩個 Repo 都假設已安裝生物資訊工具。在執行管線前請檢查前提條件。
- 對於 ClawBio，請先在複製的 Repo 中執行 `pip install -r requirements.txt`。
- 基因體數據檔案可能非常大。在下載參考基因體、SRA 數據集或建立索引時，請注意磁碟空間。
