# ADMET 參考指南

藥物研發中吸收、分佈、代謝、排泄和毒性（ADMET）分析的全面參考。

## 藥物相似性規則集

### 利平斯基五倍律 (Lipinski's Rule of Five, Ro5)

| 屬性 | 門檻 |
|----------|-----------|
| 分子量 (MW) | ≤ 500 Da |
| 親脂性 (LogP) | ≤ 5 |
| 氫鍵供體 (HBD) | ≤ 5 |
| 氫鍵受體 (HBA) | ≤ 10 |

參考文獻：Lipinski et al., Adv. Drug Deliv. Rev. 23, 3–25 (1997).

### 韋伯口服生物利用度規則 (Veber's Oral Bioavailability Rules)

| 屬性 | 門檻 |
|----------|-----------|
| 極性分子表面積 (TPSA) | ≤ 140 Å² |
| 可旋轉鍵 (Rotatable Bonds) | ≤ 10 |

參考文獻：Veber et al., J. Med. Chem. 45, 2615–2623 (2002).

### 中樞神經系統滲透 (CNS Penetration / BBB)

| 屬性 | CNS 最佳值 |
|----------|-------------|
| 分子量 (MW) | ≤ 400 Da |
| LogP | 1–3 |
| TPSA | < 90 Å² |
| 氫鍵供體 (HBD) | ≤ 3 |

## 細胞色素 P450 代謝 (CYP450 Metabolism)

| 同工酶 | 藥物佔比 % | 著名抑制劑 |
|---------|---------|-------------------|
| CYP3A4 | ~50% | 葡萄柚、酮康唑 (Ketoconazole) |
| CYP2D6 | ~25% | 氟西汀 (Fluoxetine)、帕羅西汀 (Paroxetine) |
| CYP2C9 | ~15% | 氟康唑 (Fluconazole)、胺碘酮 (Amiodarone) |
| CYP2C19 | ~10% | 奧美拉唑 (Omeprazole)、氟西汀 (Fluoxetine) |
| CYP1A2 | ~5% | 氟伏沙明 (Fluvoxamine)、環丙沙星 (Ciprofloxacin) |

## hERG 心臟毒性風險

結構警示：鹼性氮原子 (pKa 7–9) + 芳香環 + 疏水性部分，LogP > 3.5 + 鹼性胺。

緩解方法：降低鹼性、引入極性基團、破壞平面性。

## 常見的生物等排體替代 (Common Bioisosteric Replacements)

| 原始基團 | 生物等排體 | 目的 |
|----------|-------------|---------|
| -COOH | 四唑 (tetrazole)、-SO₂NH₂ | 提高滲透性 |
| -OH (苯酚) | -F、-CN | 減少葡萄糖醛酸結合 (Glucuronidation) |
| 苯基 | 吡啶 (Pyridine)、噻吩 (Thiophene) | 降低 LogP |
| 酯 | -CONHR | 減少水解 |

## 關鍵 API

- ChEMBL: https://www.ebi.ac.uk/chembl/api/data/
- PubChem: https://pubchem.ncbi.nlm.nih.gov/rest/pug/
- OpenFDA: https://api.fda.gov/drug/
- OpenTargets GraphQL: https://api.platform.opentargets.org/api/v4/graphql
