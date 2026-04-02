# LTGM -- Long-Term Growth Model for Stata

## Overview

The **Long-Term Growth Model (LTGM)** is a World Bank macroeconomic projection tool used by country economists, policy teams, and researchers to simulate long-run GDP per capita growth under alternative investment, productivity, and demographic assumptions. It implements a discrete-time Solow growth model with extensions for poverty, climate damage, and labour force participation.

This Stata package brings the LTGM into a reproducible, scriptable command-line environment. It ships with bundled country data for 218 economies, enabling zero-configuration baseline projections for any country -- type a country name and get results immediately. Every parameter can be overridden for scenario analysis.

## Installation

### From GitHub (Stata 14+)

```stata
net install ltgm, from("https://raw.githubusercontent.com/Mustapha-Wasseja/ltgm-stata/main/ado/") replace
```

### Stata 13 / manual install

1. Download the repository ZIP:
   https://github.com/Mustapha-Wasseja/ltgm-stata/archive/refs/heads/main.zip
2. Extract to a folder (e.g. `C:/ltgm-stata/`)
3. In Stata, add the `ado/` folder to your path:

```stata
adopath + "C:/ltgm-stata/ado"
```

## Quick Start

```stata
* Baseline projection for Kenya -- all parameters auto-filled from bundled data
ltgm_setup, model(standard) country(Kenya) year0(2023) scenario(baseline)
ltgm_run, scenario(baseline)

* What if Kenya raises investment to 30% of GDP?
ltgm_setup, model(standard) country(Kenya) year0(2023) scenario(high_inv) s(0.30)
ltgm_run, scenario(high_inv)

* Compare and visualise
ltgm_compare, base(baseline) alt(high_inv)
ltgm_graph, scenario(baseline) over(high_inv) var(y_pc)
ltgm_export, using(kenya_results.xlsx) scenarios(baseline high_inv)
```

## Commands

| Command | Purpose |
|---|---|
| `ltgm_setup` | Calibrate country parameters (manual or auto-filled from bundled data) |
| `ltgm_run` | Run the Solow growth model simulation |
| `ltgm_compare` | Compare baseline vs alternative scenario (tables and summary statistics) |
| `ltgm_graph` | Generate time-series line graphs (single or overlay two scenarios) |
| `ltgm_export` | Export results to Excel (.xlsx) via `putexcel` |
| `ltgm_import` | Load country parameters from bundled dataset (called internally by `ltgm_setup`) |
| `ltgm_countries` | List available countries with key indicators (filterable by region or name) |

## Models Available

| Model | Status |
|---|---|
| Standard (Solow) | **v1.0 -- Complete** |
| Public Capital | Planned for v1.1 |
| TFP Dimensions | Planned for v1.2 |
| Human Capital (cohort-based) | Planned for v1.3 |
| Natural Resources | Planned for v1.4 |

## Bundled Data

The package ships with country-level calibration data for **218 economies** sourced from:

- **Penn World Tables 11.0** -- TFP growth, capital share, depreciation, capital-output ratio
- **World Development Indicators (World Bank)** -- GDP per capita, investment rate, poverty headcount, Gini coefficient, labour force participation
- **UN World Population Prospects 2024** -- Population growth rates

Users auto-fill parameters by country name or ISO3 code. Any parameter can be overridden on the command line.

A plausibility check on TFP growth ensures that countries where PWT 11.0 produces implausibly low (but non-negative) estimates fall back to PWT 10.0 or 9.0 vintages. Genuinely negative TFP values (e.g. conflict-affected states) are preserved.

## Example Output

Ghana: baseline vs raising investment to 30% of GDP (2023-2050)

```
Scenario         GDP/cap 2023   GDP/cap 2050   Growth    Poverty 2050
---------------------------------------------------------------------------
Baseline          $2,320         $3,146         1.1%/yr    21.0%
High investment   $2,320         $4,423         2.4%/yr    10.2%
Difference                       +$1,277        +1.3pp    -10.8pp
```

## Data Sources

- Feenstra, R.C., R. Inklaar and M.P. Timmer (2015). "The Next Generation of the Penn World Table." *American Economic Review*, 105(10), 3150-3182. Available at [www.rug.nl/ggdc/productivity/pwt/](https://www.rug.nl/ggdc/productivity/pwt/)
- World Bank. *World Development Indicators*. Available at [data.worldbank.org](https://data.worldbank.org)
- United Nations, Department of Economic and Social Affairs, Population Division (2024). *World Population Prospects 2024*. Available at [population.un.org](https://population.un.org)

## Requirements

- **Stata 13** or higher
- No additional packages required (no SSC dependencies)
- Works on Windows, macOS, and Linux

## License

MIT License. See [LICENSE](LICENSE) file.
