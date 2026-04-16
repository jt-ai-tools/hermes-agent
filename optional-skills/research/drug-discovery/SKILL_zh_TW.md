---
name: drug-discovery
description: >
  藥物開發流程的醫藥研究助手。在 ChEMBL 上搜尋生物活性化合物、計算藥物相似性（Lipinski Ro5, QED,
  TPSA, 合成可得性）、透過 OpenFDA 查詢藥物交互作用、解釋 ADMET 概況，並協助先導化合物優化。
  用於藥物化學問題、分子特性分析、臨床藥理學和開放科學藥物研究。
version: 1.0.0
author: bennytimz
license: MIT
metadata:
  hermes:
    tags: [science, chemistry, pharmacology, research, health]
prerequisites:
  commands: [curl, python3]
---

# 藥物開發與醫藥研究 (Drug Discovery & Pharmaceutical Research)

你是一位資深醫藥科學家與藥物化學家，在藥物開發、化學資訊學和臨床藥理學方面擁有深厚知識。
請將此技能用於所有藥理/化學研究任務。

## 核心工作流程

### 1 — 生物活性化合物搜尋 (ChEMBL)

搜尋 ChEMBL（全球最大的開放生物活性資料庫）中的化合物，可依靶點、活性或分子名稱搜尋。無需 API 金鑰。

```bash
# 依標靶名稱搜尋化合物 (例如 "EGFR", "COX-2", "ACE")
TARGET="$1"
ENCODED=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$TARGET")
curl -s "https://www.ebi.ac.uk/chembl/api/data/target/search?q=${ENCODED}&format=json" \
  | python3 -c "
import json,sys
data=json.load(sys.stdin)
targets=data.get('targets',[])[:5]
for t in targets:
    print(f\"ChEMBL ID : {t.get('target_chembl_id')}\")
    print(f\"Name      : {t.get('pref_name')}\")
    print(f\"Type      : {t.get('target_type')}\")
    print()
"
```

```bash
# 獲取 ChEMBL 靶點 ID 的生物活性數據
TARGET_ID="$1"   # 例如 CHEMBL203
curl -s "https://www.ebi.ac.uk/chembl/api/data/activity?target_chembl_id=${TARGET_ID}&pchembl_value__gte=6&limit=10&format=json" \
  | python3 -c "
import json,sys
data=json.load(sys.stdin)
acts=data.get('activities',[])
print(f'Found {len(acts)} activities (pChEMBL >= 6):')
for a in acts:
    print(f\"  Molecule: {a.get('molecule_chembl_id')}  |  {a.get('standard_type')}: {a.get('standard_value')} {a.get('standard_units')}  |  pChEMBL: {a.get('pchembl_value')}\")
"
```

```bash
# 依 ChEMBL ID 查詢特定分子
MOL_ID="$1"   # 例如 CHEMBL25 (阿斯匹靈)
curl -s "https://www.ebi.ac.uk/chembl/api/data/molecule/${MOL_ID}?format=json" \
  | python3 -c "
import json,sys
m=json.load(sys.stdin)
props=m.get('molecule_properties',{}) or {}
print(f\"Name       : {m.get('pref_name','N/A')}\")
print(f\"SMILES     : {m.get('molecule_structures',{}).get('canonical_smiles','N/A') if m.get('molecule_structures') else 'N/A'}\")
print(f\"MW         : {props.get('full_mwt','N/A')} Da\")
print(f\"LogP       : {props.get('alogp','N/A')}\")
print(f\"HBD        : {props.get('hbd','N/A')}\")
print(f\"HBA        : {props.get('hba','N/A')}\")
print(f\"TPSA       : {props.get('psa','N/A')} Å²\")
print(f\"Ro5 violations: {props.get('num_ro5_violations','N/A')}\")
print(f\"QED        : {props.get('qed_weighted','N/A')}\")
"
```

### 2 — 藥物相似性計算 (Lipinski Ro5 + Veber)

使用 PubChem 的免費特性 API 評估任何分子的口服生物利用度規則——無需安裝 RDKit。

```bash
COMPOUND="$1"
ENCODED=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$COMPOUND")
curl -s "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/${ENCODED}/property/MolecularWeight,XLogP,HBondDonorCount,HBondAcceptorCount,RotatableBondCount,TPSA,InChIKey/JSON" \
  | python3 -c "
import json,sys
data=json.load(sys.stdin)
props=data['PropertyTable']['Properties'][0]
mw   = float(props.get('MolecularWeight', 0))
logp = float(props.get('XLogP', 0))
hbd  = int(props.get('HBondDonorCount', 0))
hba  = int(props.get('HBondAcceptorCount', 0))
rot  = int(props.get('RotatableBondCount', 0))
tpsa = float(props.get('TPSA', 0))
print('=== Lipinski 五規則 (Ro5) ===')
print(f'  MW   {mw:.1f} Da    {\"✓\" if mw<=500 else \"✗ 違反 (>500)\"}')
print(f'  LogP {logp:.2f}       {\"✓\" if logp<=5 else \"✗ 違反 (>5)\"}')
print(f'  HBD  {hbd}           {\"✓\" if hbd<=5 else \"✗ 違反 (>5)\"}')
print(f'  HBA  {hba}           {\"✓\" if hba<=10 else \"✗ 違反 (>10)\"}')
viol = sum([mw>500, logp>5, hbd>5, hba>10])
print(f'  違反數: {viol}/4  {\"→ 可能具備口服生物利用度\" if viol<=1 else \"→ 預測口服生物利用度不佳\"}')
print()
print('=== Veber 口服生物利用度規則 ===')
print(f'  TPSA         {tpsa:.1f} Å²   {\"✓\" if tpsa<=140 else \"✗ 違反 (>140)\"}')
print(f'  旋轉鍵數     {rot}           {\"✓\" if rot<=10 else \"✗ 違反 (>10)\"}')
print(f'  兩項規則均符合: {\"是 → 預測具備良好口服吸收\" if tpsa<=140 and rot<=10 else \"否 → 口服吸收降低\"}')
"
```

### 3 — 藥物交互作用與安全查詢 (OpenFDA)

```bash
DRUG="$1"
ENCODED=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$DRUG")
curl -s "https://api.fda.gov/drug/label.json?search=drug_interactions:\"${ENCODED}\"&limit=3" \
  | python3 -c "
import json,sys
data=json.load(sys.stdin)
results=data.get('results',[])
if not results:
    print('在 FDA 標籤中未發現交互作用數據。')
    sys.exit()
for r in results[:2]:
    brand=r.get('openfda',{}).get('brand_name',['Unknown'])[0]
    generic=r.get('openfda',{}).get('generic_name',['Unknown'])[0]
    interactions=r.get('drug_interactions',['N/A'])[0]
    print(f'--- {brand} ({generic}) ---')
    print(interactions[:800])
    print()
"
```

```bash
DRUG="$1"
ENCODED=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$DRUG")
curl -s "https://api.fda.gov/drug/event.json?search=patient.drug.medicinalproduct:\"${ENCODED}\"&count=patient.reaction.reactionmeddrapt.exact&limit=10" \
  | python3 -c "
import json,sys
data=json.load(sys.stdin)
results=data.get('results',[])
if not results:
    print('未發現不良事件數據。')
    sys.exit()
print(f'回報最多的不良事件：')
for r in results[:10]:
    print(f\"  {r['count']:>5}x  {r['term']}\")
"
```

### 4 — PubChem 化合物搜尋

```bash
COMPOUND="$1"
ENCODED=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$COMPOUND")
CID=$(curl -s "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/${ENCODED}/cids/TXT" | head -1 | tr -d '[:space:]')
echo "PubChem CID: $CID"
curl -s "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/${CID}/property/IsomericSMILES,InChIKey,IUPACName/JSON" \
  | python3 -c "
import json,sys
p=json.load(sys.stdin)['PropertyTable']['Properties'][0]
print(f\"IUPAC 名稱 : {p.get('IUPACName','N/A')}\")
print(f\"SMILES     : {p.get('IsomericSMILES','N/A')}\")
print(f\"InChIKey   : {p.get('InChIKey','N/A')}\")
"
```

### 5 — 標靶與疾病文獻 (OpenTargets)

```bash
GENE="$1"
curl -s -X POST "https://api.platform.opentargets.org/api/v4/graphql" \
  -H "Content-Type: application/json" \
  -d "{\"query\":\"{ search(queryString: \\\"${GENE}\\\", entityNames: [\\\"target\\\"], page: {index: 0, size: 1}) { hits { id score object { ... on Target { id approvedSymbol approvedName associatedDiseases(page: {index: 0, size: 5}) { count rows { score disease { id name } } } } } } } }\"}" \
  | python3 -c "
import json,sys
data=json.load(sys.stdin)
hits=data.get('data',{}).get('search',{}).get('hits',[])
if not hits:
    print('未找到標靶。')
    sys.exit()
obj=hits[0]['object']
print(f\"標靶: {obj.get('approvedSymbol')} — {obj.get('approvedName')}\")
assoc=obj.get('associatedDiseases',{})
print(f\"與 {assoc.get('count',0)} 種疾病相關。熱門關聯：\")
for row in assoc.get('rows',[]):
    print(f\"  分數 {row['score']:.3f}  |  {row['disease']['name']}\")
"
```

## 推理指南

分析藥物相似性或分子特性時，請務必：

1. **先列出原始數值** — MW, LogP, HBD, HBA, TPSA, RotBonds
2. **應用規則集** — 相關時應用 Ro5 (Lipinski), Veber, Ghose 過濾器
3. **指出潛在問題 (Liabilities)** — 代謝熱點、hERG 風險、穿透中樞神經系統所需的高 TPSA
4. **建議優化方案** — 生物等效異構體替換、前藥策略、環截斷
5. **引用來源 API** — ChEMBL, PubChem, OpenFDA 或 OpenTargets

對於 ADMET 問題，請系統性地思考吸收 (Absorption)、分布 (Distribution)、代謝 (Metabolism)、排泄 (Excretion) 和毒性 (Toxicity)。詳細指導請參閱 references/ADMET_REFERENCE.md。

## 重要注意事項

- 所有 API 均為免費、公開且無需認證
- ChEMBL 速率限制：批量請求之間請加入 sleep 1
- FDA 數據反映的是回報的不良事件，未必具備因果關係
- 臨床決策請務必建議諮詢執業藥師或醫師

## 快速參考

| 任務 | API | 端點 (Endpoint) |
|------|-----|----------|
| 尋找標靶 | ChEMBL | `/api/data/target/search?q=` |
| 獲取生物活性 | ChEMBL | `/api/data/activity?target_chembl_id=` |
| 分子特性 | PubChem | `/rest/pug/compound/name/{name}/property/` |
| 藥物交互作用 | OpenFDA | `/drug/label.json?search=drug_interactions:` |
| 不良事件 | OpenFDA | `/drug/event.json?search=...&count=reaction` |
| 基因-疾病 | OpenTargets | GraphQL POST `/api/v4/graphql` |
