# LTGM Stata Package -- Feasibility Assessment & Implementation Plan

**Date:** 2026-04-01
**Author:** Prepared for Mustapha Wasseja / World Bank LTGM Team
**Source Codebase:** LTGM Shiny Apps v2 (R/Shiny)
**Target:** Stata 13+ package

---

## 1. Feasibility

**Verdict: YES -- fully feasible.**

The LTGM R codebase is structurally well-suited for translation to Stata. Here is why:

1. **All five models share the same computational pattern:** year-by-year forward loops
   that accumulate capital stocks, growth rates, and levels. This is the natural pattern
   for Stata ado-file programming (forvalues loops over observations in a dataset).

2. **No deep R dependencies.** The R code uses no external optimization libraries, no
   machine learning packages, no complex statistical estimation. The core is arithmetic:
   Cobb-Douglas production functions, linear interpolation, cumulative products, and
   log-normal poverty calculations.

3. **Data is tabular and modest in size.** The 13 CSV files total ~8 MB. Stata handles
   this easily. Country parameter lookup is a simple merge or row filter.

4. **Stata 13 is sufficient.** The required operations (loops, scalars, matrices, file I/O,
   graphs, putexcel) are all available in Stata 13. No features from Stata 14+ are
   strictly necessary for the core package.

5. **The Shiny UI layer does NOT need translation.** The interactive UI (reactive inputs,
   tabs, dark mode, DataTables) is Shiny-specific and irrelevant to a Stata package.
   Stata users interact via command syntax, not GUI. This eliminates ~5,000 lines of
   module code from the translation scope.

**What actually needs translating:**

| R Source File          | Lines | Translation Needed? |
|------------------------|-------|---------------------|
| model_standard.R       | 237   | YES -- core engine   |
| model_pc.R             | 201   | YES -- core engine   |
| model_hc.R             | 212   | YES -- core engine   |
| model_nr.R             | 131   | YES -- core engine   |
| model_tfp.R            | 99    | YES -- core engine   |
| path_utils.R           | 46    | YES -- utility       |
| climate_damages.R      | 59    | YES -- utility       |
| comparison_utils.R     | 163   | PARTIAL -- comparison logic only, not Shiny UI helpers |
| data_loader.R          | 211   | YES -- reimplemented as Stata data ingest |
| 5 module files         | 4,867 | NO -- Shiny UI, not applicable |
| app.R                  | 243   | NO -- Shiny UI       |

**Effective translation scope: ~1,200 lines of R model code → ~2,000-3,000 lines of Stata ado/Mata.**

The expansion factor reflects Stata's more verbose syntax for loops and variable
manipulation compared to R's vectorized operations.

---

## 2. Translation Map

### R Component → Stata Equivalent

| R/Shiny Component | R Files | Stata Equivalent | Notes |
|---|---|---|---|
| **UI / Module logic** | mod_standard.R, mod_pc.R, mod_tfp.R, mod_nr.R, mod_hc.R, app.R | **Not translated.** Replaced by command-line syntax (`ltgm setup`, `ltgm run`, etc.) | Shiny reactivity has no Stata analog. User interaction is via typed commands and option() syntax. |
| **Model functions** | model_standard.R, model_pc.R, model_hc.R, model_nr.R, model_tfp.R | **ado files** (one per model) + shared **Mata library** for inner loops | Each `run_model*()` R function becomes one ado command or a sub-routine called by `ltgm run`. |
| **Data loading** | data_loader.R | **`ltgm_setup.ado`** -- imports CSVs, builds Stata .dta files, stores country parameters in scalars/macros | R's `read.csv()` → Stata's `import delimited`. Column aliasing done via `rename` / `label`. |
| **Comparison utilities** | comparison_utils.R | **`ltgm_compare.ado`** -- merges baseline and scenario datasets, computes diffs | `compute_comparison()` maps directly to a `merge` + `gen diff = sc - bl` pattern. |
| **Climate damage logic** | climate_damages.R | **`_ltgm_climate.ado`** (private helper) | `generate_damage_series()` → linear/exponential interpolation in a loop. `apply_climate_damages()` → adjust `g_K` variable. |
| **Path interpolation** | path_utils.R | **`_ltgm_path.ado`** (private helper) | `generate_path_choice()` → Stata `replace` with arithmetic for constant/reach_target/manual modes. |
| **Scenario handling** | Shiny module inputs + generate_path_choice() | **Command options:** `baseline` and `scenario()` options on `ltgm run` | In R, scenarios are reactive inputs. In Stata, they are option values passed at the command line. |
| **Optimization / target solving** | Not yet implemented (optim/nloptr noted as feasible) | **Mata bisection solver** in `ltgm_solver.mata` | Stata 13 has no built-in optimizer. Bisection or Brent's method in Mata is the pragmatic choice. |
| **Graphs** | Shiny renderPlot / comparison_utils.R `plot_comparison()` | **`ltgm_graph.ado`** using `twoway` commands | Stata graphs are static but publication-quality. Baseline/Scenario overlay is straightforward. |
| **Excel export** | openxlsx in R | **`ltgm_export.ado`** using `putexcel` (Stata 13+) | `putexcel` was introduced in Stata 13. Multi-sheet export is supported. |
| **Population series** | load_pop_series() -- time-series by country | **Stored as .dta file**, merged at setup time | `pop_watp_series.csv` → `ltgm_pop.dta`, filtered by country code. |

### Key Differences in Paradigm

| Concept | R/Shiny | Stata |
|---|---|---|
| State management | Reactive values in Shiny session | Datasets in memory + scalars/macros |
| Multiple scenarios | Switch between reactive inputs | Run `ltgm run` twice, once per scenario, store results in separate .dta files |
| Parameter passing | Named R lists | Stata command options + scalars |
| Year-indexed vectors | Named numeric vectors | Observations in a dataset (one row per year) |
| Return values | R data.frame returned by function | Dataset left in memory + `r()` scalars |
| Cohort × period matrix (HC) | 2D R matrix | Wide Stata dataset (one var per cohort, one obs per period) |

---

## 3. Recommended Stata Package Design

### Recommendation: Separate commands (not subcommands)

**Use the `ltgm_` prefix family:**

```
ltgm_setup
ltgm_run
ltgm_compare
ltgm_target
ltgm_graph
ltgm_export
```

**Why separate commands instead of `ltgm` with subcommands:**

1. **Stata 13 does not support the `subcmd` parsing introduced in Stata 15.** To use
   `ltgm setup` as a single command in Stata 13, you would need to parse the first
   positional argument manually. This is fragile and non-standard.

2. **Standard SSC convention.** The vast majority of Stata community packages use
   prefixed command families (`estout`, `esttab`, `eststo` or `graph_export`,
   `graph_combine`). Users expect this pattern.

3. **Independent help files.** Each `ltgm_*.ado` gets its own `ltgm_*.sthlp` file.
   Users type `help ltgm_run` and get targeted documentation. With subcommands,
   you would need a monolithic help file or custom routing.

4. **Tab-completion.** Stata's tab completion works on command names. Typing `ltgm_`
   and pressing Tab shows all available commands. Subcommands would not appear.

5. **Simpler maintenance.** Each ado file is self-contained with its own `syntax`
   statement and option parsing. No dispatcher/router code needed.

**Rejected alternative:** A single `ltgm` dispatcher command. While elegant, it adds
complexity for no user benefit in Stata 13, breaks help file conventions, and requires
custom argument parsing.

### Private helper commands

Internal commands not meant for direct user invocation use the `_ltgm_` prefix:

```
_ltgm_path.ado       -- path generation (constant/reach_target/manual)
_ltgm_climate.ado    -- climate damage series generation and application
_ltgm_validate.ado   -- input validation and range checking
_ltgm_standard.ado   -- standard model engine (called by ltgm_run)
_ltgm_pc.ado         -- public capital model engine
_ltgm_hc.ado         -- human capital model engine
_ltgm_nr.ado         -- natural resources model engine
_ltgm_tfp.ado        -- TFP model engine
```

The underscore prefix is the Stata convention for private/internal commands.

---

## 4. Proposed Command Syntax

### `ltgm_setup` -- Load country data and calibrate baseline

```stata
* Load all LTGM data and set up for Kenya
ltgm_setup, country("Kenya") datadir("C:/ltgm_data")

* Load with specific model focus
ltgm_setup, country("Kenya") model(standard) datadir("C:/ltgm_data")

* Load using country code instead of name
ltgm_setup, countrycode("KEN") datadir("C:/ltgm_data")

* After setup, baseline parameters are stored as scalars:
display r(alpha)          // capital share
display r(delta)          // depreciation rate
display r(ky_ratio)       // initial K/Y ratio
display r(gdppc)          // GDP per capita level
display r(inv_gdp)        // initial I/Y ratio
display "$ltgm_country"   // country name in global macro
```

**Options:**
- `country(string)` -- country name (fuzzy matched)
- `countrycode(string)` -- ISO3 code (exact match)
- `model(string)` -- which model: `standard` | `pc` | `tfp` | `nr` | `hc` | `all`
- `datadir(string)` -- path to CSV/DTA data directory
- `datasource(string)` -- preferred data source for multi-source parameters (e.g., "WDI", "PWT")
- `year(integer)` -- base year (default: latest available)
- `horizon(integer)` -- projection horizon in years (default: 30)

### `ltgm_run` -- Run a model simulation

```stata
* Run baseline with defaults from setup
ltgm_run, model(standard) scenario(baseline)

* Run scenario with modified parameters
ltgm_run, model(standard) scenario(scenario) ///
    inv_gdp(0.25) tfp_growth(0.015) horizon(30)

* Run with path choices
ltgm_run, model(standard) scenario(baseline) ///
    inv_gdp_path(reach_target) inv_gdp_target(0.28) ///
    tfp_growth_path(constant)

* Run public capital model
ltgm_run, model(pc) scenario(baseline) ///
    pub_inv_gdp(0.08) priv_inv_gdp(0.15) ///
    pub_efficiency(0.6) delta_pub(0.04) delta_priv(0.05)

* Run with climate damages
ltgm_run, model(standard) scenario(scenario) ///
    climate_damage_2030(0.005) climate_damage_2050(0.02)

* Run human capital model
ltgm_run, model(hc) scenario(moderate1) ///
    educ_years(10.5) educ_quality(400) asr(0.85) nsr(0.75)

* Run natural resources model
ltgm_run, model(nr) scenario(baseline) ///
    resource_share(0.15) tax_rate(0.3) ///
    depletion_rate(0.02) price_growth(0.01)

* Results left in memory as dataset:
list year g_gdppc gdppc_level in 1/5
```

**Key options by model:**

Standard: `inv_gdp()`, `tfp_growth()`, `hc_growth()`, `pop_growth()`, `lfp_growth()`,
`labor_share()`, `delta()`, `ky_ratio()`

PC: adds `pub_inv_gdp()`, `priv_inv_gdp()`, `pub_efficiency()`, `delta_pub()`,
`delta_priv()`, `phi()`

HC: `educ_years()`, `educ_quality()`, `asr()`, `nsr()`, `return_lays()`

NR: `resource_share()`, `tax_rate()`, `theta()`, `depletion_rate()`, `price_growth()`

TFP: `tfp_index()`, `tfp_target()`, `tfp_scenario()`

**Path options (for any parameter X):**
- `X(real)` -- initial value
- `X_target(real)` -- target value (for reach_target)
- `X_path(string)` -- `constant` | `reach_target` | `manual`
- `X_target_year(integer)` -- year to reach target

### `ltgm_compare` -- Compare baseline vs scenario

```stata
* Compare two previously saved results
ltgm_compare, baseline("baseline_results.dta") ///
    scenario("scenario_results.dta")

* Quick compare (runs both automatically)
ltgm_compare, model(standard) ///
    bl_inv_gdp(0.20) sc_inv_gdp(0.28)

* Results: dataset with _bl, _sc, _diff columns
list year g_gdppc_bl g_gdppc_sc g_gdppc_diff in 1/5
```

### `ltgm_target` -- Solve inverse questions

```stata
* What investment rate is needed for 5% GDP per capita growth?
ltgm_target, model(standard) target_var(g_gdppc) ///
    target_value(0.05) solve_for(inv_gdp) ///
    horizon(30)

* What TFP growth is needed for 7% total GDP growth?
ltgm_target, model(standard) target_var(g_gdp_total) ///
    target_value(0.07) solve_for(tfp_growth)

* Result:
display r(solved_value)    // e.g., 0.032
display r(iterations)      // solver iterations
display r(converged)       // 1 if converged
```

### `ltgm_graph` -- Generate output graphs

```stata
* Graph GDP per capita growth over time
ltgm_graph g_gdppc, title("GDP per Capita Growth") ///
    ylabel("Annual Growth Rate")

* Baseline vs Scenario comparison graph
ltgm_graph g_gdppc, compare ///
    baseline("baseline.dta") scenario("scenario.dta") ///
    title("Growth: Baseline vs Scenario")

* Multiple metrics
ltgm_graph g_gdppc gdppc_level inv_gdp, ///
    combine title("LTGM Projections for Kenya")

* Save graph
ltgm_graph g_gdppc, compare saving("kenya_growth.gph") ///
    export("kenya_growth.png")
```

### `ltgm_export` -- Export results to Excel

```stata
* Export current results to Excel
ltgm_export using "kenya_results.xlsx", ///
    model(standard) replace

* Export comparison
ltgm_export using "kenya_comparison.xlsx", ///
    compare baseline("baseline.dta") scenario("scenario.dta") ///
    replace

* Export with multiple sheets
ltgm_export using "kenya_full.xlsx", ///
    sheets(parameters results comparison) replace
```

---

## 5. Internal Architecture

### State Management Strategy for Stata 13

The package must manage several types of state: country parameters, baseline assumptions,
simulation outputs, and comparison outputs. Here is the recommended approach:

#### A. Country Parameters -- Scalars + Global Macros

After `ltgm_setup`, store calibration values as **returned scalars** in `r()` and
simultaneously copy them to **global macros** with the `ltgm_` prefix for persistence
across commands:

```
Scalars (r-class, transient):
  r(alpha), r(delta), r(ky_ratio), r(gdppc), r(inv_gdp), ...

Global macros (persistent across commands):
  $ltgm_country, $ltgm_countrycode, $ltgm_model
  $ltgm_alpha, $ltgm_delta, $ltgm_ky_ratio, ...
  $ltgm_datadir, $ltgm_horizon, $ltgm_base_year
```

**Why globals over `e()` or characteristics:** Stata 13's `e()` results are overwritten
by the next estimation command. Globals persist until explicitly cleared. The `ltgm_`
prefix avoids namespace collision.

#### B. Simulation Outputs -- Datasets in Memory + Saved .dta Files

Each `ltgm_run` execution leaves results as the **active dataset** in memory:

```
Observations = number of projection years (e.g., 31 for 2025-2055)
Variables = year, inv_gdp, hc_growth, tfp_growth, pop_growth, ky_ratio,
            g_capital_pw, g_gdp_pw, g_gdppc, g_gdp_total, gdppc_level,
            poverty_rate (if applicable)
```

Optionally saved to a .dta file via `saving()` option:

```stata
ltgm_run, model(standard) scenario(baseline) saving("kenya_bl.dta")
```

This mirrors R's pattern of returning a data.frame, but uses Stata's native
single-dataset-in-memory model.

#### C. Baseline Assumptions -- Parameter Dataset

`ltgm_setup` creates a small auxiliary dataset stored as a tempfile or named file:

```
_ltgm_params.dta:
  Obs 1: parameter="alpha",       value=0.35,  source="PWT"
  Obs 2: parameter="delta",       value=0.05,  source="WDI"
  Obs 3: parameter="ky_ratio",    value=3.2,   source="PWT"
  ...
```

This allows `ltgm_run` to read defaults without requiring the user to re-specify
every parameter.

#### D. Comparison Outputs -- Merged Dataset

`ltgm_compare` produces a dataset with `_bl`, `_sc`, and `_diff` suffixed variables:

```
year  g_gdppc_bl  g_gdppc_sc  g_gdppc_diff  gdppc_level_bl  gdppc_level_sc  ...
2025  0.045       0.045       0.000          2500            2500
2026  0.044       0.052       0.008          2612            2630
...
```

#### E. Tempfiles vs Named Files

Use **tempfiles** for intermediate calculations (within a single command execution)
and **named .dta files** for results the user wants to keep or compare later.

#### F. Why NOT Mata Structs for State

Mata structs would be cleaner architecturally but have drawbacks in Stata 13:
- Mata structs cannot be saved to disk in Stata 13 (no `mata matsave` for structs)
- Users cannot inspect struct contents without Mata knowledge
- Debugging is harder -- users expect to `list` or `describe` their data

**Recommendation:** Keep all user-visible state in datasets and scalars/macros.
Use Mata only for the inner computational loops where performance matters.

---

## 6. Numerical Engine

### What Stays in Ado vs What Goes to Mata

| Component | Implement In | Rationale |
|---|---|---|
| Command parsing, options, validation | **Ado** | Standard Stata `syntax` command handles this natively |
| Data loading and CSV import | **Ado** | `import delimited` is an ado-level command |
| Path generation (constant/reach_target) | **Ado** | Simple `replace` operations on dataset variables |
| Year-by-year model loop (Standard) | **Ado or Mata** | Ado is fine for 30-50 iterations. Mata gives ~10x speed but unnecessary for this scale. |
| Year-by-year model loop (PC) | **Ado or Mata** | Same as standard. Slightly more complex with dual capital stocks. |
| Cohort × period HC computation | **Mata** | Nested loop over 9 cohorts × ~10 periods, with interpolation. Matrix operations are natural in Mata. |
| TFP index computation | **Ado** | Simple weighted average of 5 dimension scores. |
| NR resource revenue accumulation | **Ado** | Single loop, straightforward. |
| Poverty headcount (log-normal) | **Mata** | Requires `ln()`, `normal()` (CDF), and accumulation. Mata is cleaner for this. |
| Climate damage series | **Ado** | Linear/exponential interpolation, simple loop. |
| Comparison merge and diff | **Ado** | Standard dataset merge + gen operations. |
| Graph generation | **Ado** | `twoway` commands are ado-level. |
| Excel export | **Ado** | `putexcel` is ado-level. |
| **Target solver (bisection)** | **Mata** | Requires calling the model repeatedly with different parameter values. Mata avoids the overhead of re-parsing commands. |
| **Future optimization (Solver-style)** | **Mata** | Brent's method or golden section search. Mata's speed matters when the objective function calls the full model. |

### Target Solver Design

The target solver (`ltgm_target`) needs to find parameter value X such that
model output Y = target. For example: "What investment rate gives 5% growth?"

**Algorithm: Bisection method in Mata**

```
1. User specifies: solve_for(inv_gdp), target_var(g_gdppc), target_value(0.05)
2. Set bounds: lower=0.01, upper=0.80 (reasonable range for I/Y)
3. Iterate:
   a. mid = (lower + upper) / 2
   b. Run model with inv_gdp = mid
   c. Extract average g_gdppc from results
   d. If g_gdppc > target: upper = mid, else: lower = mid
   e. Stop when |g_gdppc - target| < tolerance (e.g., 0.0001)
4. Return: r(solved_value) = mid, r(iterations) = n
```

**Why bisection over Newton-Raphson:** The LTGM models are monotonic in their key
parameters (more investment → more growth). Bisection is robust, requires no
derivatives, and converges in ~20 iterations to 4-digit precision. Good enough
for this application.

**Future optimization (multi-parameter):** If the package later needs to solve for
multiple parameters simultaneously (like Excel Solver), implement Nelder-Mead in
Mata. This is ~200 lines of Mata code and does not require Stata 14+ features.

### Interpolation

The HC model requires interpolation from 5-year periods to annual. In Stata 13:

```stata
* Option 1: ipolate command (built-in)
ipolate hc_index year, gen(hc_annual)

* Option 2: Manual linear interpolation in a loop
* (more control, works identically in all Stata versions)
```

`ipolate` has been available since Stata 8, so this is safe for Stata 13.

---

## 7. Risks and Redesign Needs

### What Translates Directly

| Component | Translation Difficulty | Notes |
|---|---|---|
| Standard model (Solow) equations | **Easy** | Direct arithmetic, same equations |
| PC model equations | **Easy** | Same pattern, just dual capital stocks |
| NR model equations | **Easy** | Single loop with resource revenue accumulation |
| TFP index computation | **Easy** | Weighted average |
| Path generation (constant/reach_target) | **Easy** | replace + arithmetic |
| Climate damage series | **Easy** | Linear interpolation loop |
| Comparison logic (merge + diff) | **Easy** | Standard merge operations |
| CSV data loading | **Easy** | import delimited + rename |
| Poverty headcount (log-normal) | **Moderate** | Need `invnormal()` / `normal()` -- available in Stata 13 |
| Excel export | **Moderate** | `putexcel` syntax differs from openxlsx but is capable |

### What Needs Redesign

| Component | Redesign Needed | Explanation |
|---|---|---|
| **Reactive parameter binding** | **Major** | R/Shiny auto-updates outputs when inputs change. Stata has no reactivity. Every parameter change requires re-running `ltgm_run`. This is expected by Stata users and is not a problem -- it's just a different paradigm. |
| **Multi-source data selection** | **Moderate** | The R app has dropdown menus for choosing between WDI, PWT, and other data sources per parameter. In Stata, this becomes a `datasource()` option or a separate `ltgm_setup` call. Need to design how parameter source selection works at the command line. |
| **Cohort aging (HC model)** | **Moderate** | The R code uses 2D matrix indexing `hc_matrix[cohort, period]`. In Stata, this maps to a wide dataset (one variable per cohort, one observation per period) or a Mata matrix. The Mata matrix approach is cleaner. |
| **Dynamic UI controls** | **Eliminated** | Collapsible panels, sliders, data source dropdowns -- none apply. Replaced by command options. |
| **Scenario presets (HC)** | **Minor** | R uses a named list of scenario definitions. Stata equivalent: hardcoded scalars in the ado file, selected by `scenario(status_quo|moderate1|moderate2|optimistic)`. |
| **Population series lookup** | **Minor** | R loads full CSV and filters. Stata: load .dta, keep if countrycode == "KEN", merge with model output on year. |
| **Flexible column matching** | **Minor** | R's data_loader uses regex pattern matching (`find_col`) for robust column lookup in CSVs. Stata: use explicit column names with `capture` for error handling. Less flexible but more predictable. |
| **Named return values** | **Minor** | R functions return named lists. Stata: use `r()` returns for scalars and leave datasets in memory. Need a clear convention for which results go where. |
| **Graph interactivity** | **Eliminated** | Shiny plots are interactive (hover, zoom). Stata graphs are static. This is fine -- World Bank economists expect static publication-quality graphs. |

### Technical Risks

| Risk | Severity | Mitigation |
|---|---|---|
| **Stata 13 putexcel limitations** | Medium | Stata 13's `putexcel` is basic (no formatting, no formulas). Stata 14+ added `putexcel` formatting. For Stata 13, the export will be data-only. Consider offering a Stata 14+ enhanced export path. |
| **No built-in optimizer in Stata 13** | Medium | Write bisection/Brent in Mata (~100 lines). Stata 16+ has `moptimize` but that is estimation-focused, not general-purpose. Custom Mata solver is the right approach for all versions. |
| **HC model complexity** | Medium | The cohort-based model with 9 age groups, 5-year intervals, and interpolation is the most complex component. Plan for extra testing time. |
| **Data format evolution** | Low | If the underlying CSVs change structure in future LTGM versions, the Stata loader breaks. Mitigation: version the data format and validate on load. |
| **Numerical precision** | Low | R and Stata use IEEE 754 double precision. Results should match to ~12 significant digits. Differences will arise only from operation ordering in accumulation loops. |
| **Package distribution** | Low | SSC (Statistical Software Components) is the standard distribution channel. Alternatively, distribute as a .zip with `net install` from a URL. Both work fine. |

---

## 8. Version Compatibility

### Can you build it in Stata 13? -- YES

Every feature required by the LTGM package is available in Stata 13:

| Feature | Required By | Stata Version |
|---|---|---|
| `import delimited` | Data loading | Stata 13+ (replaced `insheet`) |
| `putexcel` | Excel export | Stata 13+ (basic), Stata 14+ (formatting) |
| Mata language | Solver, HC model | Stata 9+ |
| `mata mlib` (compiled Mata libraries) | Performance | Stata 10+ |
| `syntax` command parsing | All commands | All versions |
| `forvalues` / `foreach` loops | Model engines | All versions |
| `ipolate` | HC interpolation | Stata 8+ |
| `twoway` graphs | ltgm_graph | Stata 8+ |
| `merge` | Data operations | All versions |
| `tempfile` / `tempname` | Internal state | All versions |
| `scalar` / `matrix` | Parameter storage | All versions |
| `r()` return values | Result passing | All versions |
| `normal()` / `invnormal()` | Poverty calculation | All versions |
| `program define` / `version` | Package structure | All versions |

### Stata 13+ Support Strategy

**Recommended: Target Stata 13 as minimum, with graceful enhancement for 14+.**

Every ado file should begin with:

```stata
*! ltgm_run v1.0.0  2026-04-01
*! World Bank LTGM Stata Package
program define ltgm_run, rclass
    version 13.0
    syntax , Model(string) Scenario(string) [options...]
    ...
end
```

The `version 13.0` statement tells Stata to interpret the code using version 13
semantics, even if the user is running Stata 17 or 18. This is the standard
forward-compatibility mechanism.

### What Stata 14+ Adds (Optional Enhancements)

| Feature | Stata Version | Enhancement |
|---|---|---|
| `putexcel` formatting (bold, colors, borders) | 14+ | Nicer Excel output |
| `frames` (multiple datasets in memory) | 16+ | Could hold baseline + scenario simultaneously |
| Unicode support | 14+ | Better country name handling |
| `collect` / `table` | 17+ | Fancier output tables |
| Transparent PNG graph export | 15+ | Better graph export |
| Python integration | 16+ | Could call Python for optimization (but Mata is better) |

**Strategy:** Build the core for Stata 13. Use `capture` + version checks to
enable enhancements where available:

```stata
if c(stata_version) >= 14 {
    * Use formatted putexcel
    putexcel A1 = "Country", bold
}
else {
    * Basic putexcel (Stata 13)
    putexcel A1 = "Country"
}
```

### Can It Support Older Than Stata 13?

**No -- not recommended.**

- Stata 12 and earlier lack `import delimited` (would need `insheet`, which has
  limitations with quoted strings and special characters)
- Stata 12 lacks `putexcel` entirely
- Stata 12's Mata is functional but has fewer built-in functions
- The user base on Stata 12 or earlier is negligible in 2026
- **Stata 13 is already 13 years old** -- supporting it is already generous

**Recommendation:** Set `version 13.0` as the minimum. Document this clearly in
the help files and package description.

---

## 9. Recommended Implementation Roadmap

### Phase 0: Data Preparation (1-2 days)

**Goal:** Convert CSV data to Stata .dta format and validate.

- Convert all 13 CSV files to .dta files using `import delimited`
- Verify variable names, types, and value ranges match R data_loader expectations
- Create a master `ltgm_data/` directory with versioned .dta files
- Write `_ltgm_validate.ado` to check data integrity on load
- **Deliverable:** `ltgm_data/*.dta` files + validation report

### Phase 1: Core Standard Model (3-5 days)

**Goal:** Working `ltgm_setup` + `ltgm_run` for the standard Solow model.

- Implement `ltgm_setup.ado` -- country parameter loading from .dta
- Implement `_ltgm_path.ado` -- path generation (constant / reach_target)
- Implement `_ltgm_standard.ado` -- standard model engine (Models 1, 2, 3)
- Implement `ltgm_run.ado` -- dispatcher that calls model-specific engine
- Implement poverty headcount calculation (log-normal)
- **Test:** Run Kenya baseline, compare output to R results row-by-row
- **Deliverable:** Working `ltgm_setup` + `ltgm_run` for standard model

### Phase 2: Comparison + Graphs + Export (2-3 days)

**Goal:** Complete the baseline vs scenario workflow for standard model.

- Implement `ltgm_compare.ado` -- merge and diff
- Implement `ltgm_graph.ado` -- single metric and comparison plots
- Implement `ltgm_export.ado` -- Excel export via putexcel
- **Test:** Full Kenya workflow: setup → baseline → scenario → compare → graph → export
- **Deliverable:** Complete standard model workflow

### Phase 3: PC Model Extension (2-3 days)

**Goal:** Add public capital model.

- Implement `_ltgm_pc.ado` -- dual capital stock engine
- Add efficiency tracking logic
- Extend `ltgm_run` to accept `model(pc)` with PC-specific options
- **Test:** Compare PC model output to R results
- **Deliverable:** Working PC model

### Phase 4: HC Model Extension (3-5 days)

**Goal:** Add human capital model (most complex).

- Implement `_ltgm_hc.ado` -- cohort-based HC engine in Mata
- Implement cohort aging logic (historical vs projected)
- Implement 5-year to annual interpolation
- Implement scenario presets (status_quo, moderate1, moderate2, optimistic)
- **Test:** Validate cohort HC values against R output for multiple countries
- **Deliverable:** Working HC model

### Phase 5: NR and TFP Models (2-3 days)

**Goal:** Add natural resources and TFP models.

- Implement `_ltgm_nr.ado` -- resource revenue, fiscal rules, GDI
- Implement `_ltgm_tfp.ado` -- TFP index, dimension scores, projection
- Extend `ltgm_run` for both
- **Test:** Compare against R results
- **Deliverable:** All 5 models working

### Phase 6: Target Solver (2-3 days)

**Goal:** Add inverse solving capability.

- Implement `ltgm_solver.mata` -- bisection method
- Implement `ltgm_target.ado` -- user-facing solver command
- Support solving for any single parameter given a target output metric
- **Test:** "What I/Y gives 5% growth?" should match R Model 2 results
- **Deliverable:** Working target solver

### Phase 7: Climate Damages (1 day)

**Goal:** Add climate damage overlay.

- Implement `_ltgm_climate.ado` -- damage series generation
- Integrate with model engines (adjust g_K)
- **Test:** Verify damage-adjusted results
- **Deliverable:** Climate damage extension

### Phase 8: Documentation + Examples + Package (3-5 days)

**Goal:** Publication-ready package.

- Write all .sthlp help files (one per command)
- Write example .do files (Kenya, Ghana, or other representative countries)
- Write test .do files (one per model, automated validation)
- Create `ltgm.pkg` and `stata.toc` for distribution
- Write installation instructions
- **Deliverable:** Distributable package

### Phase 9: Validation + Release (2-3 days)

**Goal:** Ensure R and Stata produce matching results.

- Run all 5 models for 10+ countries in both R and Stata
- Compare outputs to tolerance (max absolute difference < 0.001)
- Document any intentional differences
- Fix discrepancies
- **Deliverable:** Validation report + final package

### Total Estimated Scope: ~20-30 working days

**Critical path:** Phase 1 (standard model) → Phase 2 (workflow) → Phase 4 (HC model).
Everything else can be parallelized or reordered.

---

## Appendix A: Complete File Manifest

```
ltgm_stata_package/
├── planning/
│   └── assessment.md              ← this file
├── docs/
│   └── (future: user guide, validation report)
├── ado/
│   ├── ltgm_setup.ado             ← country data loading + calibration
│   ├── ltgm_run.ado               ← model simulation dispatcher
│   ├── ltgm_compare.ado           ← baseline vs scenario comparison
│   ├── ltgm_target.ado            ← inverse solver (find parameter for target)
│   ├── ltgm_graph.ado             ← output visualization
│   ├── ltgm_export.ado            ← Excel export
│   ├── _ltgm_standard.ado         ← standard Solow model engine
│   ├── _ltgm_pc.ado               ← public capital model engine
│   ├── _ltgm_hc.ado               ← human capital model engine
│   ├── _ltgm_nr.ado               ← natural resources model engine
│   ├── _ltgm_tfp.ado              ← TFP model engine
│   ├── _ltgm_path.ado             ← path generation utility
│   ├── _ltgm_climate.ado          ← climate damage utility
│   └── _ltgm_validate.ado         ← input validation utility
├── help/
│   ├── ltgm_setup.sthlp
│   ├── ltgm_run.sthlp
│   ├── ltgm_compare.sthlp
│   ├── ltgm_target.sthlp
│   ├── ltgm_graph.sthlp
│   └── ltgm_export.sthlp
├── mata/
│   ├── ltgm_core.mata             ← shared numerical routines
│   └── ltgm_solver.mata           ← bisection / Brent solver
├── examples/
│   ├── kenya_standard.do          ← full standard model workflow
│   ├── ghana_pc.do                ← public capital example
│   ├── ethiopia_hc.do             ← human capital example
│   ├── nigeria_nr.do              ← natural resources example
│   └── vietnam_tfp.do             ← TFP example
├── tests/
│   ├── test_standard.do
│   ├── test_pc.do
│   ├── test_hc.do
│   ├── test_nr.do
│   ├── test_tfp.do
│   ├── test_solver.do
│   └── test_compare.do
└── package/
    ├── ltgm.pkg                   ← Stata package descriptor
    └── stata.toc                  ← package table of contents
```

## Appendix B: R-to-Stata Equation Reference

### Standard Model Core Equations

| Equation | R Code | Stata Equivalent |
|---|---|---|
| Capital share | `alpha = 1 - labor_share` | `scalar alpha = 1 - labor_share` |
| Labor force growth | `g_L = pop + watp + lfp` | `gen g_L = pop_growth + watp_growth + lfp_growth` |
| Capital growth | `g_K = (I/Y) / (K/Y) - delta` | `gen g_K = inv_gdp / ky_ratio - delta` |
| K per worker growth | `g_k = g_K - g_L` | `gen g_k = g_K - g_L` |
| GDP per worker growth | `g_y = alpha*g_k + (1-alpha)*(tfp+hc)` | `gen g_y = alpha*g_k + (1-alpha)*(tfp_growth+hc_growth)` |
| GDP per capita growth | `g_ypc = g_y + watp + lfp` | `gen g_ypc = g_y + watp_growth + lfp_growth` |
| K/Y evolution | `ky[t+1] = ky[t]*(1+g_K)/(1+g_Y)` | `replace ky_ratio = ky_ratio[_n-1]*(1+g_K[_n-1])/(1+g_Y[_n-1]) if _n>1` |
| GDP level | `gdppc[t] = gdppc[t-1]*(1+g_ypc[t])` | `replace gdppc_level = gdppc_level[_n-1]*(1+g_ypc) if _n>1` |

### Poverty Calculation

| Step | R Code | Stata Equivalent |
|---|---|---|
| Sigma from Gini | `sigma = sqrt(2) * invnorm((1+gini)/2)` | `scalar sigma = sqrt(2) * invnormal((1+gini)/2)` |
| Mean income | `mu = ln(gdppc) - sigma^2/2` | `scalar mu = ln(gdppc) - sigma^2/2` |
| Poverty rate | `pnorm((ln(2.15) - mu) / sigma)` | `scalar pov = normal((ln(2.15) - mu) / sigma)` |

---

## Appendix C: Stata 13 Compatibility Checklist

| Feature | Available? | Notes |
|---|---|---|
| `version 13` statement | Yes | Standard forward compatibility |
| `program define, rclass` | Yes | Return scalars and macros |
| `syntax` with options | Yes | Full option parsing |
| `import delimited` | Yes | Introduced in Stata 13 |
| `putexcel` | Yes | Basic (no formatting until v14) |
| Mata `mata:` blocks | Yes | Full Mata language since Stata 9 |
| `mata mlib create` | Yes | Compiled Mata libraries |
| `tempfile`, `tempname` | Yes | Standard |
| `ipolate` | Yes | Since Stata 8 |
| `twoway` graphs | Yes | Full graphing |
| `normal()`, `invnormal()` | Yes | Standard math functions |
| `frames` | No | Stata 16+ only -- do not use |
| `collect` | No | Stata 17+ only -- do not use |
| `python` integration | No | Stata 16+ only -- do not use |
| `putexcel` formatting | No | Stata 14+ -- use conditionally |
| `unicode` functions | No | Stata 14+ -- avoid dependency |

---

*End of assessment. No code has been written. No existing files have been modified.
All planning content is isolated in `ltgm_stata_package/planning/`.*
