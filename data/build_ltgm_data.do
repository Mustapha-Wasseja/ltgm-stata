/**********************************************************************
 *  build_ltgm_data.do
 *  LTGM Stata Package -- Build Master Country Dataset
 *
 *  Reads standard_countries_v2.csv and extracts one row per country
 *  with preferred parameter values for the LTGM Standard Model.
 *
 *  Source selection strategy (following data_sources.json defaults):
 *    delta      : delta_pwt110          (PWT 11.0)
 *    alpha      : 1 - labsh_pwt110      (PWT 11.0 labour share)
 *    ky0        : ky_pwt110             (PWT 11.0)
 *    y0         : gni_pc_atlas          (WDI GNI Atlas method)
 *    s          : inv_gdp_wdi_10yr      (WDI 10-year average)
 *    g_tfp      : tfp_growth_pwt110_20yr (PWT 11.0 20-year average)
 *    g_pop      : pop_growth_med_2025   (UNWPP 2025 medium)
 *    povshare   : poverty_215           ($2.15/day threshold)
 *    lfp_total  : lfp_total             (total LFP rate)
 *    lfp_male   : lfp_male
 *    lfp_female : lfp_female
 *    gini       : gini
 *    income_group: income_group
 *
 *  Fallback cascade for y0: gni_pc_atlas -> gdp_pc_wdi -> gdp_pc_level
 *  Fallback cascade for s:  inv_gdp_wdi_10yr -> inv_gdp_pwt_10yr -> inv_gdp_wdi_20yr
 *  Fallback cascade for ky: ky_pwt110 -> ky_pwt100 -> ky_mfmod -> ky_fad
 *  Fallback cascade for delta: delta_pwt110 -> delta_pwt100 -> 0.05
 *  Fallback cascade for alpha: 1-labsh_pwt110 -> 1-labsh_pwt100 -> 0.35
 *  Fallback cascade for tfp: tfp_growth_pwt110_20yr -> tfp_growth_pwt110_10yr -> 0.01
 *
 *  Output: ltgm_country_data.dta  (one row per country)
 *
 *  Authors: Mustapha Wasseja / World Bank LTGM Team
 *  Date:    April 2026
 *  Requires: Stata 13+
 **********************************************************************/

clear all
set more off
version 13.0

* --- Locate data directory (run from ltgm_stata_package/data/) --------
local datadir `"`c(pwd)'"'

* If run from ltgm_stata_package/ root, adjust
capture confirm file "`datadir'/csv/standard_countries_v2.csv"
if _rc {
    capture confirm file "`datadir'/data/csv/standard_countries_v2.csv"
    if _rc == 0 {
        local datadir "`datadir'/data"
    }
    else {
        display as error "Cannot find standard_countries_v2.csv"
        display as error "Run this do-file from ltgm_stata_package/ or ltgm_stata_package/data/"
        exit 601
    }
}

display _n "Building LTGM master country dataset..."
display "  Data source: `datadir'/csv/"

/* ==================================================================
   LOAD standard_countries_v2.csv
   ================================================================== */

quietly import delimited using "`datadir'/csv/standard_countries_v2.csv", ///
    clear varnames(1) stringcols(1 2 3)

* Trim whitespace from string identifiers
quietly replace country     = strtrim(country)
quietly replace countrycode = strtrim(countrycode)
quietly replace income_group = strtrim(income_group)

* Drop rows with empty country code (header artifacts or blanks)
quietly drop if countrycode == "" | countrycode == "countrycode"

display "  Loaded " _N " countries from standard_countries_v2.csv"

/* ==================================================================
   FORCE NUMERIC CONVERSION
   All parameter columns come in as strings because of mixed content.
   Convert to double, setting non-numeric to missing.
   ================================================================== */

* List of all numeric columns we need
local numvars delta_pwt110 delta_pwt100 delta_pwt1001               ///
    labsh_pwt110 labsh_pwt100 labsh_pwt1001                         ///
    ky_pwt110 ky_pwt100 ky_pwt1001 ky_mfmod ky_fad                 ///
    gni_pc_atlas gdp_pc_level gdp_pc_wdi                            ///
    tfp_growth_pwt110_20yr tfp_growth_pwt110_10yr                   ///
    tfp_growth_pwt110_05yr                                          ///
    inv_gdp_wdi_10yr inv_gdp_pwt_10yr inv_gdp_wdi_20yr             ///
    inv_gdp_wdi_05yr inv_gdp_weo_forecast                          ///
    pop_growth_med_2024 pop_growth_med_2025                         ///
    pop_growth_med_2030 pop_growth_med_2035                         ///
    poverty_215 poverty_365 poverty_685 gini                        ///
    lfp_total lfp_male lfp_female                                   ///
    gdp_growth_10yr gdppc_growth_10yr                               ///
    hc_growth_pwt110_10yr hc_growth_pwt110_20yr

foreach v of local numvars {
    capture confirm string variable `v'
    if _rc == 0 {
        * It is a string -- convert to numeric
        quietly destring `v', replace force
    }
}

/* ==================================================================
   BUILD PREFERRED PARAMETER COLUMNS WITH FALLBACK CASCADES
   ================================================================== */

* --- y0: GDP per capita level ---
* Preference: GNI Atlas -> WDI GDP -> GDP level
quietly generate double y0 = gni_pc_atlas
quietly replace y0 = gdp_pc_wdi    if missing(y0)
quietly replace y0 = gdp_pc_level  if missing(y0)
label variable y0 "GDP per capita (current $)"

* --- s: Investment/savings rate (as fraction, 0-1) ---
* Note: CSV stores rates as fractions (0.22 not 22)
quietly generate double s = inv_gdp_wdi_10yr
quietly replace s = inv_gdp_pwt_10yr if missing(s)
quietly replace s = inv_gdp_wdi_20yr if missing(s)
quietly replace s = inv_gdp_wdi_05yr if missing(s)
quietly replace s = inv_gdp_weo_forecast if missing(s)
label variable s "Investment rate (I/GDP fraction)"

* Check if values look like percentages (>1) and convert
quietly summarize s, meanonly
if r(max) > 1 {
    quietly replace s = s / 100
}

* --- delta: Depreciation rate ---
quietly generate double delta = delta_pwt110
quietly replace delta = delta_pwt100  if missing(delta)
quietly replace delta = delta_pwt1001 if missing(delta)
quietly replace delta = 0.05 if missing(delta)
label variable delta "Depreciation rate"

* Check if stored as percentage
quietly summarize delta, meanonly
if r(max) > 1 {
    quietly replace delta = delta / 100
}

* --- alpha: Capital share = 1 - labour share ---
quietly generate double alpha = 1 - labsh_pwt110
quietly replace alpha = 1 - labsh_pwt100  if missing(alpha)
quietly replace alpha = 1 - labsh_pwt1001 if missing(alpha)
quietly replace alpha = 0.35 if missing(alpha)
* Clamp to reasonable range
quietly replace alpha = 0.35 if alpha <= 0.05 | alpha >= 0.95
label variable alpha "Capital share (1 - labour share)"

* --- ky0: Capital-output ratio ---
quietly generate double ky0 = ky_pwt110
quietly replace ky0 = ky_pwt100  if missing(ky0)
quietly replace ky0 = ky_pwt1001 if missing(ky0)
quietly replace ky0 = ky_mfmod   if missing(ky0)
quietly replace ky0 = ky_fad     if missing(ky0)
quietly replace ky0 = 2.5 if missing(ky0)
label variable ky0 "Initial capital-output ratio (K/Y)"

* --- g_tfp: TFP growth rate ---
* Primary source: PWT 11.0 20-year average.
* Plausibility floor: 0.005 (0.5%) applied ONLY when PWT 11.0 value is
* non-negative but suspiciously low (0 <= g_tfp < 0.005). PWT 11.0
* revisions to capital stock methodology produce implausibly low TFP for
* some countries (e.g. Vietnam 0.22%, vs 0.75% in PWT 10.0). In these
* cases we fall back to PWT 10.0 then PWT 9.0 which use earlier capital
* stock estimates.
* IMPORTANT: Negative TFP values are preserved as-is. Negative TFP is a
* real economic signal (technological regression, conflict, institutional
* decay) and should not be overridden by the plausibility floor.
quietly generate double g_tfp = tfp_growth_pwt110_20yr
* Plausibility cascade: if PWT 11.0 is non-negative but < 0.005, try older vintages
quietly replace g_tfp = tfp_growth_pwt100_20yr ///
    if !missing(tfp_growth_pwt100_20yr) & !missing(g_tfp) ///
    & g_tfp >= 0 & g_tfp < 0.005
quietly replace g_tfp = tfp_growth_pwt90_20yr ///
    if !missing(tfp_growth_pwt90_20yr) & !missing(g_tfp) ///
    & g_tfp >= 0 & g_tfp < 0.005
* If still missing, try shorter PWT 11.0 horizons
quietly replace g_tfp = tfp_growth_pwt110_10yr if missing(g_tfp)
quietly replace g_tfp = tfp_growth_pwt110_05yr if missing(g_tfp)
* Final fallback
quietly replace g_tfp = 0.01 if missing(g_tfp)
label variable g_tfp "TFP growth rate (annualised)"

* Check if stored as percentage
quietly summarize g_tfp, meanonly
if r(max) > 0.5 {
    quietly replace g_tfp = g_tfp / 100
}

* --- g_pop: Population growth rate ---
* Use 2025 medium variant as default base-year value
quietly generate double g_pop = pop_growth_med_2025
quietly replace g_pop = pop_growth_med_2024 if missing(g_pop)
quietly replace g_pop = pop_growth_med_2030 if missing(g_pop)
quietly replace g_pop = 0.02 if missing(g_pop)
label variable g_pop "Population growth rate"

* Check if stored as percentage
quietly summarize g_pop, meanonly
if r(max) > 0.5 {
    quietly replace g_pop = g_pop / 100
}

* --- povshare: Poverty headcount ($2.15/day) ---
quietly generate double povshare = poverty_215
* Convert from percentage to fraction if needed
quietly summarize povshare, meanonly
if r(max) > 1 {
    quietly replace povshare = povshare / 100
}
quietly replace povshare = 0 if missing(povshare)
label variable povshare "Poverty headcount ($2.15/day, fraction)"

* --- povline: Fixed at $2.15 ---
quietly generate double povline = 2.15
label variable povline "Poverty line ($/day)"

* --- LFP rates ---
* These are rates (fraction of working-age population), not growth rates
* Store as-is; growth rates default to 0
quietly generate double lfp_rate = lfp_total
quietly summarize lfp_rate, meanonly
if r(max) > 1 {
    quietly replace lfp_rate = lfp_rate / 100
}
quietly generate double lfp_male_rate = lfp_male
quietly summarize lfp_male_rate, meanonly
if r(max) > 1 {
    quietly replace lfp_male_rate = lfp_male_rate / 100
}
quietly generate double lfp_female_rate = lfp_female
quietly summarize lfp_female_rate, meanonly
if r(max) > 1 {
    quietly replace lfp_female_rate = lfp_female_rate / 100
}
label variable lfp_rate "LFP rate (total)"
label variable lfp_male_rate "LFP rate (male)"
label variable lfp_female_rate "LFP rate (female)"

* LFP growth defaults (not in CSV -- set to 0)
quietly generate double g_lfp   = 0
quietly generate double g_lfp_m = 0
quietly generate double g_lfp_f = 0
label variable g_lfp   "LFP growth rate (default 0)"
label variable g_lfp_m "Male LFP growth rate (default 0)"
label variable g_lfp_f "Female LFP growth rate (default 0)"

* --- hc_growth ---
quietly generate double hc_growth = hc_growth_pwt110_10yr
quietly replace hc_growth = hc_growth_pwt110_20yr if missing(hc_growth)
quietly replace hc_growth = 0.005 if missing(hc_growth)
label variable hc_growth "Human capital growth rate"

* Check if stored as percentage
quietly summarize hc_growth, meanonly
if r(max) > 0.5 {
    quietly replace hc_growth = hc_growth / 100
}

* --- Gini coefficient ---
quietly generate double gini_coef = gini
label variable gini_coef "Gini coefficient"

* --- GDP growth (for reference / TFP estimation check) ---
quietly generate double gdp_growth = gdp_growth_10yr
quietly summarize gdp_growth, meanonly
if r(max) > 0.5 {
    quietly replace gdp_growth = gdp_growth / 100
}
label variable gdp_growth "Recent GDP growth rate (10yr avg)"

/* ==================================================================
   RENAME AND KEEP FINAL VARIABLES
   ================================================================== */

rename country     country_name
rename countrycode iso3

* Data year: we use cross-section data; assign 2022 as the reference year
* (most recent year for majority of indicators in PWT 11.0 and WDI)
quietly generate int data_year = 2022
label variable data_year "Reference data year"

* Keep only the master dataset variables
keep country_name iso3 income_group data_year                        ///
     y0 s delta alpha ky0                                            ///
     g_tfp g_pop hc_growth                                           ///
     g_lfp g_lfp_m g_lfp_f                                          ///
     lfp_rate lfp_male_rate lfp_female_rate                          ///
     povshare povline gini_coef gdp_growth

* Sort by country name
sort country_name

* Label the dataset
label data "LTGM Master Country Dataset (built `c(current_date)')"

/* ==================================================================
   DIAGNOSTICS
   ================================================================== */

display _n "=== LTGM Master Country Dataset ==="
display "  Countries: " _N
display ""

* Count non-missing for key parameters
foreach v in y0 s delta alpha ky0 g_tfp g_pop povshare {
    quietly count if !missing(`v')
    local n_ok = r(N)
    quietly count if missing(`v')
    local n_miss = r(N)
    display "  `v'" _col(20) ": " `n_ok' " available, " `n_miss' " missing"
}

/* ==================================================================
   SAVE
   ================================================================== */

local outfile "`datadir'/ltgm_country_data.dta"
quietly save "`outfile'", replace
display _n "  Saved: `outfile'"
display "  Total countries: " _N
display ""
