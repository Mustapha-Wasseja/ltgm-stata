/**********************************************************************
 *  Demo 2 -- Senior Economist
 *  Nigeria three scenarios, Kenya gender LFP, cross-country batch
 **********************************************************************/
clear all
set more off

* ================================================================
*  NIGERIA: three scenarios
* ================================================================

* Baseline
ltgm_setup, model(standard) country(Nigeria) year0(2023) scenario(nga_base)
ltgm_run, scenario(nga_base) nodisplay

* Reform: investment rises to 30% by 2035, TFP improves to 1.5% by 2035
ltgm_setup, model(standard) country(Nigeria) year0(2023) ///
    scenario(nga_reform) ///
    s_target(0.30) s_year(2035) ///
    gtfp_target(0.015) gtfp_year(2035)
ltgm_run, scenario(nga_reform) nodisplay

* Climate stress: 20% of TFP growth lost to climate damage
ltgm_setup, model(standard) country(Nigeria) year0(2023) ///
    scenario(nga_climate) climate(0.20)
ltgm_run, scenario(nga_climate) nodisplay

* Compare baseline vs reform
ltgm_compare, base(nga_base) alt(nga_reform)

* Compare baseline vs climate stress
ltgm_compare, base(nga_base) alt(nga_climate)

* ================================================================
*  KENYA: gender LFP scenario (sub-model 2)
* ================================================================

* Baseline (sub-model 1)
ltgm_setup, model(standard) country(Kenya) year0(2023) scenario(ken_base)
ltgm_run, scenario(ken_base) nodisplay

* Female LFP improvement scenario
ltgm_setup, model(standard) country(Kenya) year0(2023) ///
    scenario(ken_lfp) submodel(2) ///
    g_lfp_f(0.008) g_lfp_m(0.001)
ltgm_run, scenario(ken_lfp) nodisplay

ltgm_compare, base(ken_base) alt(ken_lfp)

* ================================================================
*  CROSS-COUNTRY: batch baseline for 6 countries
* ================================================================

foreach c in Ghana Kenya Nigeria Tanzania Ethiopia Rwanda {
    ltgm_setup, model(standard) country("`c'") year0(2023) ///
        scenario(`c'_base)
    ltgm_run, scenario(`c'_base) nodisplay
}

* ================================================================
*  GRAPH 3: Nigeria three-scenario GDP comparison
* ================================================================

quietly use _ltgm_results_nga_base.dta, clear
rename y_pc y_base
keep year y_base

quietly merge 1:1 year using _ltgm_results_nga_reform.dta, keepusing(y_pc) nogenerate
rename y_pc y_reform

quietly merge 1:1 year using _ltgm_results_nga_climate.dta, keepusing(y_pc) nogenerate
rename y_pc y_climate

twoway ///
    (line y_base    year, lcolor(navy)  lwidth(medthick) lpattern(solid)) ///
    (line y_reform  year, lcolor(green) lwidth(medthick) lpattern(dash))  ///
    (line y_climate year, lcolor(red)   lwidth(medthick) lpattern(dot)),  ///
    legend(order(1 "Baseline" 2 "Reform (invest+TFP)" 3 "Climate stress") ///
           position(11) ring(0)) ///
    xtitle("Year") ytitle("GDP per capita (USD)") ///
    title("Nigeria: Three Scenarios 2023-2050") ///
    subtitle("Investment reform vs climate damage") ///
    graphregion(color(white)) plotregion(color(white)) scheme(s2color)
graph export demo2_nigeria.png, replace width(1200)

* ================================================================
*  GRAPH 4: Kenya female LFP dividend
* ================================================================

quietly use _ltgm_results_ken_base.dta, clear
rename y_pc y_base
keep year y_base

quietly merge 1:1 year using _ltgm_results_ken_lfp.dta, keepusing(y_pc) nogenerate
rename y_pc y_lfp

twoway ///
    (line y_base year, lcolor(navy)   lwidth(medthick) lpattern(solid)) ///
    (line y_lfp  year, lcolor(purple) lwidth(medthick) lpattern(dash)),  ///
    legend(order(1 "Baseline" 2 "Female LFP improvement") ///
           position(11) ring(0)) ///
    xtitle("Year") ytitle("GDP per capita (USD)") ///
    title("Kenya: Female Labour Force Participation Dividend") ///
    graphregion(color(white)) plotregion(color(white)) scheme(s2color)
graph export demo2_kenya_lfp.png, replace width(1200)

* ================================================================
*  GRAPH 5: Cross-country GDP per capita bar chart
* ================================================================

* Build summary dataset by appending one row per country
local clist "Ghana Kenya Nigeria Tanzania Ethiopia Rwanda"
local first = 1
foreach c of local clist {
    quietly use _ltgm_results_`c'_base.dta, clear
    local y23 = y_pc[1]
    local y50 = y_pc[_N]
    clear
    quietly set obs 1
    quietly generate str20 cname = "`c'"
    quietly generate double gdp2023 = `y23'
    quietly generate double gdp2050 = `y50'
    if `first' {
        quietly save _summary_temp.dta, replace
        local first = 0
    }
    else {
        quietly append using _summary_temp.dta
        quietly save _summary_temp.dta, replace
    }
}

use _summary_temp.dta, clear
gsort -gdp2050
generate id = _n

* Manual value labels (no labmask dependency)
label define clab 1 "" 2 "" 3 "" 4 "" 5 "" 6 ""
forvalues i = 1/`=_N' {
    local lbl = cname[`i']
    label define clab `i' "`lbl'", modify
}
label values id clab

twoway ///
    (bar gdp2050 id, barwidth(0.4) fcolor(eltgreen) lcolor(green)) ///
    (bar gdp2023 id, barwidth(0.4) fcolor(eltblue) lcolor(navy)),  ///
    xlabel(1/6, valuelabel angle(30)) ///
    legend(order(2 "2023" 1 "2050 (projected)") position(11) ring(0)) ///
    xtitle("") ytitle("GDP per capita (USD)") ///
    title("Baseline GDP per Capita: 2023 vs 2050") ///
    subtitle("Six Sub-Saharan African Countries") ///
    graphregion(color(white)) plotregion(color(white)) scheme(s2color)
graph export demo2_crosscountry.png, replace width(1200)

* ================================================================
*  EXPORT
* ================================================================

ltgm_export, using(demo2_nigeria.xlsx) scenarios(nga_base nga_reform nga_climate)
ltgm_export, using(demo2_kenya.xlsx) scenarios(ken_base ken_lfp)

* ================================================================
*  CLEANUP temp files
* ================================================================
capture erase _summary_temp.dta

display _n "=== Demo 2 complete ===" _n
