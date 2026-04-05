# LTGM Excel Workbooks -- Hidden Sheets Inventory

Discovered 2026-04-04. All LTGM Excel workbooks contain hidden sheets
with critical backing data that feeds the visible InputData sheets.
The NR workbook was previously unhidden; the other 4 had 9 hidden sheets total.

Unhidden copies saved alongside originals in `LTGM Shiny Apps v2/data/`.

---

## Summary

| Workbook | File | Size | Total Sheets | Hidden |
|---|---|---|---|---|
| Standard | LTGMv5-72.xlsx | 7.3 MB | 13 | 1 |
| Public Capital | LTGM-PC-v5-72.xlsx | 7.6 MB | 14 | 2 |
| TFP | LTGM-TFP-v1.xlsx | 2.5 MB | 5 | 2 |
| Human Capital | LTGM-HC-v1.xlsx | 2.0 MB | 8 | 4 |
| Natural Resources | LTGM-NR-v1-0-unhidden.xlsx | 8.3 MB | 38 | 0 (pre-unhidden) |

---

## Hidden Sheet Details

### 1. Standard & PC: `data` (242 x 2451)

- **Found in:** LTGMv5-72.xlsx, LTGM-PC-v5-72.xlsx (identical in both)
- **Feeds:** InputDataA_GeneralAssumptions (visible sheet)
- **Structure:** 241 countries x ~2451 parameter columns
- **Content:** Complete parameter matrix for all countries. Column headers are
  numeric (1-2451) mapping to every parameter variant: depreciation (PWT 9.0,
  10.0, 11.0), labour share, K/Y ratios, investment rates, TFP growth,
  population growth, poverty, LFP, Gini, etc. across multiple data sources
  and time horizons.
- **Already extracted to:** `csv/standard_countries_v2.csv` (102 selected columns)
- **Stata package:** `ltgm_country_data.dta` (20 preferred columns with fallback cascades)

### 2. PC: `data_pc` (240 x 56)

- **Found in:** LTGM-PC-v5-72.xlsx only
- **Feeds:** InputDataA_GeneralAssumptions (PC-specific rows), InputDataB
- **Structure:** ~238 countries x 56 columns (row 2 has variable names)
- **Content:**
  - Kg/Kp ratio (public-to-private capital) -- FAD source and IMF Paper source
  - Kg/K share (public capital share of total) -- FAD and IMF Paper
  - IEI (Infrastructure Efficiency Index)
  - PIMI (Public Investment Management Index)
  - Efficiency scores derived from both IEI and PIMI
  - Ig/I (public share of total investment) at 5yr, 10yr, 15yr, 20yr, current
  - Ip/Y (private investment / GDP)
  - I/Y (total investment / GDP)
  - Ig/Y (public investment / GDP)
- **Sources:** IMF FAD, An/Kangur/Papageorgiou (2019 EER)
- **Already extracted to:** `csv/pc_countries_v2.csv` (17 selected columns)
- **Stata package:** `ltgm_pc_data.dta` (23 columns including derived pub_ky_ratio, priv_ky_ratio)

### 3. TFP: `Data` (6064 x 87)

- **Found in:** LTGM-TFP-v1.xlsx
- **Feeds:** TFP model sheet, Indexes by income and region
- **Structure:** Country-year panel (~87 columns)
- **Content:** TFP determinant index database. Title row reads "Database for
  general variables and determinant indexes." Contains regional aggregates
  (OECD, East Asia & Pacific, Europe & Central Asia, LAC, MENA, South Asia,
  Sub-Saharan Africa) and income quintile breakdowns (Q1-Q5). Panel data
  for institutions, trade openness, financial development, innovation,
  education quality, infrastructure, and other TFP drivers.
- **Already extracted to:** `csv/tfp_data.csv` (partial)
- **Stata package:** Not yet built (planned for v1.2)

### 4. TFP: `Calculation` (78 x 147)

- **Found in:** LTGM-TFP-v1.xlsx
- **Feeds:** TFP model output
- **Structure:** 78 rows x 147 columns of formulas
- **Content:** TFP model calculation engine. Contains index aggregation
  formulas, weighting schemes, and scenario computations. This is the
  computational core that the visible "TFP model" sheet references.
- **Stata package:** Will be translated to `ltgm_tfp_run.ado` (planned v1.2)

### 5. HC: `data_humancapital` (4010 x 100)

- **Found in:** LTGM-HC-v1.xlsx
- **Feeds:** InputData_HC, Baseline, Scenario sheets
- **Structure:** ~4000 rows x ~100 columns (row 1 has Cohort_id + numeric headers)
- **Content:** Human capital stock data by cohort. Contains education quality,
  years of schooling, and human capital index values broken down by age
  cohort for demographic modeling. The cohort structure enables the HC model's
  cohort-based human capital accumulation (unlike the standard model's
  aggregate HC growth rate).
- **Already extracted to:** Not yet extracted as CSV
- **Stata package:** Not yet built (planned for v1.3)

### 6. HC: `data_demographics` (4017 x 90)

- **Found in:** LTGM-HC-v1.xlsx
- **Feeds:** InputData_HC (population projections)
- **Structure:** Country-specific population panels (~90 columns)
- **Content:** Population projections with age-sex breakdown. First column
  labeled "Population", second column appears to be country code (e.g. "BRA").
  Contains UN WPP medium variant projections and demographic structure data
  needed for the HC model's cohort-based simulation.
- **Already extracted to:** `csv/pop_watp_series.csv` (aggregate growth rates only)
- **Stata package:** Not yet built (planned for v1.3)

### 7. HC: `data_covidschoolclosures` (211 x 7)

- **Found in:** LTGM-HC-v1.xlsx
- **Feeds:** InputData_HC (COVID adjustment)
- **Structure:** 210 countries x 5 meaningful columns
- **Content:**
  - `countrycode` -- ISO3 country code
  - `years_lost` -- Years of schooling lost due to COVID closures
  - Source: UNESCO
- **Already extracted to:** `csv/covid_school.csv`
- **Stata package:** Not yet built (planned for v1.3)

### 8. HC: `HCI 2020 - MaleFemale` (201 x 23)

- **Found in:** LTGM-HC-v1.xlsx
- **Feeds:** InputData_HC (HCI baseline values)
- **Structure:** ~200 countries x 13 meaningful columns
- **Content:** World Bank Human Capital Index 2020:
  - Country Name, WB Code, Region, Income Group
  - Probability of Survival to Age 5
  - Expected Years of School
  - Harmonized Test Scores
  - Learning-Adjusted Years of School
  - Fraction of Children Under 5 Not Stunted
  - Adult Survival Rate
  - HCI 2020 (Lower Bound, Point Estimate, Upper Bound)
- **Already extracted to:** `csv/hci_data.csv`
- **Stata package:** Not yet built (planned for v1.3)

---

## Data Flow: Hidden Sheets to Stata Package

```
Excel hidden sheet          CSV extraction         Stata .dta
-------------------         ----------------       ----------------
Standard: data       --->   standard_countries_v2.csv ---> ltgm_country_data.dta
PC: data_pc          --->   pc_countries_v2.csv        ---> ltgm_pc_data.dta
TFP: Data            --->   tfp_data.csv               ---> (planned v1.2)
TFP: Calculation     --->   (formulas, not data)       ---> ltgm_tfp_run.ado
HC: data_humancapital -->   (not yet extracted)        ---> (planned v1.3)
HC: data_demographics -->   pop_watp_series.csv        ---> (planned v1.3)
HC: data_covidschool  -->   covid_school.csv           ---> (planned v1.3)
HC: HCI 2020         --->   hci_data.csv               ---> (planned v1.3)
NR: Dataset1-4       --->   nr_*.csv                   ---> (planned v1.4)
NR: Data             --->   (calibration values)       ---> (planned v1.4)
```

---

## Cross-Workbook Sheet Comparison

| Sheet | Standard | PC | TFP | HC | NR |
|---|---|---|---|---|---|
| data (main params) | 242x2451 H | 241x2451 H | -- | -- | -- |
| data_pc | -- | 240x56 H | -- | -- | -- |
| Data (TFP/NR) | -- | -- | 6064x87 H | -- | 1133x55 |
| Calculation | -- | -- | 78x147 H | -- | -- |
| data_humancapital | -- | -- | -- | 4010x100 H | -- |
| data_demographics | -- | -- | -- | 4017x90 H | -- |
| data_covidschool | -- | -- | -- | 211x7 H | -- |
| HCI 2020 | -- | -- | -- | 201x23 H | -- |
| DataSummary | 506x113 | 677x113 | -- | -- | -- |
| Dataset1 | -- | -- | -- | -- | 4534x51 |
| Dataset2 | -- | -- | -- | -- | 82695x73 |
| Dataset3 | -- | -- | -- | -- | 22872x56 |
| DataLegend | -- | -- | -- | -- | 95x18 |
| CountryDataAvailability | -- | -- | -- | -- | 42x22 |

H = was hidden (now unhidden in *-unhidden.xlsx copies)

---

## Unhidden Copies

Saved in `LTGM Shiny Apps v2/data/` (originals not modified):

- LTGMv5-72-unhidden.xlsx (6.3 MB)
- LTGM-PC-v5-72-unhidden.xlsx (6.5 MB)
- LTGM-TFP-v1-unhidden.xlsx (2.0 MB)
- LTGM-HC-v1-unhidden.xlsx (1.6 MB)
