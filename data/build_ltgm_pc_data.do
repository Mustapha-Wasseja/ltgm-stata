/**********************************************************************
 *  build_ltgm_pc_data.do
 *  LTGM Stata Package -- Build Public Capital Country Dataset
 *
 *  Merges pc_countries_v2.csv with standard_countries_v2.csv to create
 *  a single bundled dataset for the PC model.
 *
 *  PC-specific columns from pc_countries_v2.csv:
 *    kg_k_share  : public capital share of total capital (Kg/K)
 *    iei         : Infrastructure Efficiency Index (proxy for efficiency)
 *    ig_y        : public investment / GDP
 *    ip_y        : private investment / GDP
 *    i_y         : total investment / GDP
 *    ig_i_10yr   : public share of total investment (10yr avg)
 *
 *  Derived parameters:
 *    pub_ky_ratio  = kg_k_share * ky0     (public K/Y)
 *    priv_ky_ratio = (1-kg_k_share) * ky0 (private K/Y)
 *    pub_inv_gdp   = ig_y   (or ig_i_10yr * s)
 *    priv_inv_gdp  = ip_y   (or (1-ig_i_10yr) * s)
 *
 *  Output: ltgm_pc_data.dta (one row per country)
 *
 *  Requires: Stata 13+
 **********************************************************************/

clear all
set more off
version 13.0

log using "build_ltgm_pc_data.log", text replace

* --- Locate data directory ---
local datadir `"`c(pwd)'"'

capture confirm file "`datadir'/csv/pc_countries_v2.csv"
if _rc {
    capture confirm file "`datadir'/data/csv/pc_countries_v2.csv"
    if _rc == 0 {
        local datadir "`datadir'/data"
    }
    else {
        display as error "Cannot find pc_countries_v2.csv"
        display as error "Run from ltgm_stata_package/ or ltgm_github/data/"
        exit 601
    }
}

display _n "Building LTGM Public Capital country dataset..."
display "  Data source: `datadir'/csv/"

/* ==================================================================
   STEP 1: Load and prepare PC-specific data
   ================================================================== */

quietly import delimited using "`datadir'/csv/pc_countries_v2.csv", ///
    clear varnames(1) stringcols(1 2)

* Drop duplicate header rows and blanks
quietly drop if countrycode == "" | countrycode == "countrycode"

* Force numeric conversion for all PC columns
local pc_numvars kg_kp_ratio kg_k_share kg_kp_fad kg_k_fad    ///
    iei pimi efficiency_pimi                                    ///
    ig_i_20yr ig_i_15yr ig_i_10yr ig_i_5yr ig_i_current        ///
    ip_y i_y ig_y

foreach v of local pc_numvars {
    capture confirm string variable `v'
    if _rc == 0 {
        quietly destring `v', replace force
    }
}

display "  Loaded " _N " countries from pc_countries_v2.csv"

* Rename for merge
rename countrycode iso3
rename country_name pc_country_name

* Keep only essential PC columns
keep iso3 pc_country_name kg_k_share iei ig_y ip_y i_y ig_i_10yr ig_i_20yr

* Save as tempfile
tempfile pcdata
quietly save `pcdata'

/* ==================================================================
   STEP 2: Load standard country data (same source as build_ltgm_data.do)
   ================================================================== */

quietly import delimited using "`datadir'/csv/standard_countries_v2.csv", ///
    clear varnames(1) stringcols(1 2 3)

quietly replace country     = strtrim(country)
quietly replace countrycode = strtrim(countrycode)
quietly replace income_group = strtrim(income_group)

quietly drop if countrycode == "" | countrycode == "countrycode"

display "  Loaded " _N " countries from standard_countries_v2.csv"

* Force numeric conversion (same as build_ltgm_data.do)
local numvars delta_pwt110 delta_pwt100 delta_pwt1001               ///
    labsh_pwt110 labsh_pwt100 labsh_pwt1001                         ///
    ky_pwt110 ky_pwt100 ky_pwt1001 ky_mfmod ky_fad                 ///
    gni_pc_atlas gdp_pc_level gdp_pc_wdi                            ///
    tfp_growth_pwt110_20yr tfp_growth_pwt110_10yr                   ///
    tfp_growth_pwt110_05yr                                          ///
    tfp_growth_pwt90_20yr tfp_growth_pwt91_20yr                    ///
    tfp_growth_pwt100_20yr                                          ///
    inv_gdp_wdi_10yr inv_gdp_pwt_10yr inv_gdp_wdi_20yr             ///
    inv_gdp_wdi_05yr inv_gdp_weo_forecast                          ///
    pop_growth_med_2024 pop_growth_med_2025                         ///
    pop_growth_med_2030 pop_growth_med_2035                         ///
    poverty_215 gini                                                ///
    lfp_total lfp_male lfp_female                                   ///
    hc_growth_pwt110_10yr hc_growth_pwt110_20yr                     ///
    watp_1564_med_2025 watp_1564_med_2030

foreach v of local numvars {
    capture confirm string variable `v'
    if _rc == 0 {
        quietly destring `v', replace force
    }
}

* Build standard parameters (same fallback cascades)
quietly generate double y0 = gni_pc_atlas
quietly replace y0 = gdp_pc_wdi   if missing(y0)
quietly replace y0 = gdp_pc_level if missing(y0)

quietly generate double s = inv_gdp_wdi_10yr
quietly replace s = inv_gdp_pwt_10yr if missing(s)
quietly replace s = inv_gdp_wdi_20yr if missing(s)
quietly replace s = inv_gdp_wdi_05yr if missing(s)
quietly replace s = inv_gdp_weo_forecast if missing(s)
quietly summarize s, meanonly
if r(max) > 1 {
    quietly replace s = s / 100
}

quietly generate double delta = delta_pwt110
quietly replace delta = delta_pwt100  if missing(delta)
quietly replace delta = delta_pwt1001 if missing(delta)
quietly replace delta = 0.05 if missing(delta)
quietly summarize delta, meanonly
if r(max) > 1 {
    quietly replace delta = delta / 100
}

quietly generate double alpha = 1 - labsh_pwt110
quietly replace alpha = 1 - labsh_pwt100  if missing(alpha)
quietly replace alpha = 1 - labsh_pwt1001 if missing(alpha)
quietly replace alpha = 0.35 if missing(alpha)
quietly replace alpha = 0.35 if alpha <= 0.05 | alpha >= 0.95

quietly generate double ky0 = ky_pwt110
quietly replace ky0 = ky_pwt100  if missing(ky0)
quietly replace ky0 = ky_pwt1001 if missing(ky0)
quietly replace ky0 = ky_mfmod   if missing(ky0)
quietly replace ky0 = ky_fad     if missing(ky0)
quietly replace ky0 = 2.5 if missing(ky0)

quietly generate double g_tfp = tfp_growth_pwt110_20yr
quietly replace g_tfp = tfp_growth_pwt100_20yr ///
    if !missing(tfp_growth_pwt100_20yr) & !missing(g_tfp) ///
    & g_tfp >= 0 & g_tfp < 0.005
quietly replace g_tfp = tfp_growth_pwt90_20yr ///
    if !missing(tfp_growth_pwt90_20yr) & !missing(g_tfp) ///
    & g_tfp >= 0 & g_tfp < 0.005
quietly replace g_tfp = tfp_growth_pwt110_10yr if missing(g_tfp)
quietly replace g_tfp = tfp_growth_pwt110_05yr if missing(g_tfp)
quietly replace g_tfp = 0.01 if missing(g_tfp)
quietly summarize g_tfp, meanonly
if r(max) > 0.5 {
    quietly replace g_tfp = g_tfp / 100
}

quietly generate double g_pop = pop_growth_med_2025
quietly replace g_pop = pop_growth_med_2024 if missing(g_pop)
quietly replace g_pop = pop_growth_med_2030 if missing(g_pop)
quietly replace g_pop = 0.02 if missing(g_pop)
quietly summarize g_pop, meanonly
if r(max) > 0.5 {
    quietly replace g_pop = g_pop / 100
}

quietly generate double hc_growth = hc_growth_pwt110_10yr
quietly replace hc_growth = hc_growth_pwt110_20yr if missing(hc_growth)
quietly replace hc_growth = 0.005 if missing(hc_growth)
quietly summarize hc_growth, meanonly
if r(max) > 0.5 {
    quietly replace hc_growth = hc_growth / 100
}

quietly generate double g_watp = watp_1564_med_2025
quietly replace g_watp = watp_1564_med_2030 if missing(g_watp)
quietly replace g_watp = 0 if missing(g_watp)

quietly generate double povshare = poverty_215
quietly summarize povshare, meanonly
if r(max) > 1 {
    quietly replace povshare = povshare / 100
}
quietly replace povshare = 0 if missing(povshare)

quietly generate double gini_coef = gini

quietly generate double lfp_rate = lfp_total
quietly generate double g_lfp = 0

* Rename for merge
rename countrycode iso3
rename country country_name

/* ==================================================================
   STEP 3: Merge PC data with standard data
   ================================================================== */

quietly merge 1:1 iso3 using `pcdata', nogenerate

display "  After merge: " _N " countries"

/* ==================================================================
   STEP 4: Derive PC parameters
   ================================================================== */

* Public capital share: default to 0.30 if missing
quietly replace kg_k_share = 0.30 if missing(kg_k_share)
label variable kg_k_share "Public capital share (Kg/K)"

* Public and private K/Y ratios
quietly generate double pub_ky_ratio  = kg_k_share * ky0
quietly generate double priv_ky_ratio = (1 - kg_k_share) * ky0
label variable pub_ky_ratio  "Public capital-output ratio (Kg/Y)"
label variable priv_ky_ratio "Private capital-output ratio (Kp/Y)"

* Public investment/GDP
* Prefer ig_y from PC data; fallback: ig_i_10yr * s
quietly generate double pub_inv_gdp = ig_y
quietly replace pub_inv_gdp = ig_i_10yr * s ///
    if missing(pub_inv_gdp) & !missing(ig_i_10yr) & !missing(s)
quietly replace pub_inv_gdp = ig_i_20yr * s ///
    if missing(pub_inv_gdp) & !missing(ig_i_20yr) & !missing(s)
quietly replace pub_inv_gdp = 0.05 if missing(pub_inv_gdp)
label variable pub_inv_gdp "Public investment / GDP"

* Private investment/GDP
* Prefer ip_y; fallback: s - pub_inv_gdp
quietly generate double priv_inv_gdp = ip_y
quietly replace priv_inv_gdp = s - pub_inv_gdp ///
    if missing(priv_inv_gdp) & !missing(s)
quietly replace priv_inv_gdp = max(0.01, priv_inv_gdp)
quietly replace priv_inv_gdp = 0.15 if missing(priv_inv_gdp)
label variable priv_inv_gdp "Private investment / GDP"

* Infrastructure efficiency index: default 0.60
quietly generate double pub_efficiency = iei
quietly replace pub_efficiency = 0.60 if missing(pub_efficiency)
* Clamp to [0.1, 1.0]
quietly replace pub_efficiency = max(0.1, min(1.0, pub_efficiency))
label variable pub_efficiency "Public capital efficiency (IEI)"

* Data year
quietly generate int data_year = 2022
label variable data_year "Reference data year"

/* ==================================================================
   STEP 5: Keep final variables and save
   ================================================================== */

keep iso3 country_name income_group data_year                       ///
     y0 s delta alpha ky0                                           ///
     g_tfp g_pop g_watp hc_growth g_lfp                            ///
     lfp_rate povshare gini_coef                                    ///
     kg_k_share pub_ky_ratio priv_ky_ratio                         ///
     pub_inv_gdp priv_inv_gdp pub_efficiency

sort country_name

label data "LTGM Public Capital Country Dataset (built `c(current_date)')"

/* ==================================================================
   DIAGNOSTICS
   ================================================================== */

display _n "=== LTGM Public Capital Country Dataset ==="
display "  Countries: " _N
display ""

foreach v in y0 s ky0 g_tfp g_pop pub_ky_ratio priv_ky_ratio ///
             pub_inv_gdp priv_inv_gdp pub_efficiency kg_k_share {
    quietly count if !missing(`v')
    local n_ok = r(N)
    quietly count if missing(`v')
    local n_miss = r(N)
    display "  `v'" _col(22) ": " `n_ok' " available, " `n_miss' " missing"
}

/* ==================================================================
   SAVE
   ================================================================== */

local outfile "`datadir'/ltgm_pc_data.dta"
quietly save "`outfile'", replace
display _n "  Saved: `outfile'"
display "  Total countries: " _N
display ""

log close
exit, clear STATA
