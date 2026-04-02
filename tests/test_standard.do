/**********************************************************************
 *  test_standard.do
 *  LTGM Stata Package -- Standard Model Steady-State Sanity Check
 *
 *  Theory:
 *    In the Solow model, the steady-state GDP per capita growth rate is:
 *      g_y_ss = g_tfp / (1 - alpha)
 *
 *    With alpha=0.35 and g_tfp=0.01:
 *      g_y_ss = 0.01 / 0.65 = 0.01538...
 *
 *    K/Y should converge to a constant in the long run.
 *
 *  Test setup:
 *    Run for 100 years (2000-2100) with constant parameters.
 *    No climate damage, no reach-target paths.
 *    Check convergence at the end of the simulation.
 *
 *  Assertions:
 *    1. K/Y at year 2100 is within 10% of K/Y at year 2090 (convergence)
 *    2. g_y at year 2100 is within 0.002 of 0.01538 (steady-state growth)
 *    3. GDP per capita is positive and increasing throughout
 *    4. Poverty is declining (with negative elasticity and positive growth)
 *
 *  Authors: Mustapha Wasseja / World Bank LTGM Team
 *  Date:    April 2026
 **********************************************************************/

clear all
set more off

display _n "============================================================"
display    "  LTGM Standard Model -- Steady-State Tests"
display    "============================================================" _n

local test_pass = 1
local n_tests   = 0
local n_pass    = 0

/* ==================================================================
   TEST 1: Basic steady-state convergence
   ================================================================== */

display as text "--- Test 1: Steady-state convergence ---"

ltgm_setup, model(standard) scenario(test_ss)            ///
    year0(2000) horizon(2100)                              ///
    alpha(0.35) s(0.20) delta(0.05)                        ///
    g_tfp(0.01) g_pop(0.02) g_lfp(0)                      ///
    ky0(2.5) y0(1000)                                      ///
    povshare(0.40) povelast(-2.0) povline(2.15)            ///
    climate(0)

ltgm_run, scenario(test_ss) nodisplay

* Find observations for years 2090 and 2100
* Dataset has year variable; _N is last obs
local nyears = _N

* K/Y at final year and 10 years before
local ky_final = ky[`nyears']
local ky_near  = ky[`nyears' - 10]

* Check K/Y convergence: |ky_final - ky_near| / ky_near < 0.10
local ky_pct_diff = abs(`ky_final' - `ky_near') / `ky_near'
local n_tests = `n_tests' + 1

if `ky_pct_diff' < 0.10 {
    display as result "  PASS: K/Y converged (diff = " %6.4f `ky_pct_diff' " < 0.10)"
    local n_pass = `n_pass' + 1
}
else {
    display as error "  FAIL: K/Y did not converge (diff = " %6.4f `ky_pct_diff' " >= 0.10)"
    display as error "    K/Y[2090] = " %8.4f `ky_near' ", K/Y[2100] = " %8.4f `ky_final'
    local test_pass = 0
}

* GDP per capita growth at final year vs theoretical steady state
local g_y_final = g_y[`nyears']
local g_y_ss    = 0.01 / (1 - 0.35)   /* = 0.015385 */
local g_y_diff  = abs(`g_y_final' - `g_y_ss')
local n_tests   = `n_tests' + 1

if `g_y_diff' < 0.002 {
    display as result "  PASS: g_y converged to steady state (diff = " %8.6f `g_y_diff' " < 0.002)"
    display as result "    g_y[2100] = " %8.6f `g_y_final' ", theoretical = " %8.6f `g_y_ss'
    local n_pass = `n_pass' + 1
}
else {
    display as error "  FAIL: g_y did not converge (diff = " %8.6f `g_y_diff' " >= 0.002)"
    display as error "    g_y[2100] = " %8.6f `g_y_final' ", theoretical = " %8.6f `g_y_ss'
    local test_pass = 0
}


/* ==================================================================
   TEST 2: GDP per capita is positive and increasing
   ================================================================== */

display _n as text "--- Test 2: GDP per capita positive and increasing ---"

local n_tests = `n_tests' + 1
local ypc_ok = 1

forvalues i = 2/`nyears' {
    if y_pc[`i'] <= 0 {
        display as error "  FAIL: y_pc <= 0 at observation `i'"
        local ypc_ok = 0
        local test_pass = 0
        continue, break
    }
    if y_pc[`i'] <= y_pc[`i'-1] {
        display as error "  FAIL: y_pc not increasing at observation `i'"
        display as error "    y_pc[`i'-1] = " y_pc[`i'-1] ", y_pc[`i'] = " y_pc[`i']
        local ypc_ok = 0
        local test_pass = 0
        continue, break
    }
}

if `ypc_ok' {
    display as result "  PASS: GDP per capita positive and strictly increasing for all " `nyears' " years"
    local n_pass = `n_pass' + 1
}


/* ==================================================================
   TEST 3: Poverty is declining
   ================================================================== */

display _n as text "--- Test 3: Poverty declining with positive growth ---"

local n_tests = `n_tests' + 1
local pov_ok = 1

forvalues i = 2/`nyears' {
    if pov[`i'] > pov[`i'-1] {
        display as error "  FAIL: poverty increased at observation `i'"
        display as error "    pov[`i'-1] = " pov[`i'-1] ", pov[`i'] = " pov[`i']
        local pov_ok = 0
        local test_pass = 0
        continue, break
    }
}

if `pov_ok' {
    display as result "  PASS: Poverty declining throughout simulation"
    display as result "    Initial poverty = " %6.2f pov[1]*100 "%, Final = " %6.2f pov[`nyears']*100 "%"
    local n_pass = `n_pass' + 1
}


/* ==================================================================
   TEST 4: Reach-target path interpolation
   ================================================================== */

display _n as text "--- Test 4: Reach-target path interpolation ---"

ltgm_setup, model(standard) scenario(test_ramp)           ///
    year0(2000) horizon(2050)                               ///
    alpha(0.35) s(0.20) delta(0.05)                         ///
    g_tfp(0.01) g_pop(0.02) g_lfp(0)                       ///
    ky0(2.5) y0(1000)                                       ///
    povshare(0.40) povelast(-2.0) povline(2.15)             ///
    climate(0)                                               ///
    s_target(0.30) s_year(2020)

ltgm_run, scenario(test_ramp) nodisplay

* At year 2020 (obs 21), s_t should be 0.30 (fully ramped)
* At year 2000 (obs 1), s_t should be 0.20 (initial)
* At year 2010 (obs 11), s_t should be 0.25 (midpoint)

local n_tests = `n_tests' + 1
local s_init    = s_t[1]
local s_mid     = s_t[11]
local s_reached = s_t[21]
local s_after   = s_t[31]

local ramp_ok = 1

* Check initial value
if abs(`s_init' - 0.20) > 0.001 {
    display as error "  FAIL: s_t[2000] = " %8.6f `s_init' " (expected 0.20)"
    local ramp_ok = 0
}

* Check midpoint
if abs(`s_mid' - 0.25) > 0.001 {
    display as error "  FAIL: s_t[2010] = " %8.6f `s_mid' " (expected 0.25)"
    local ramp_ok = 0
}

* Check target reached
if abs(`s_reached' - 0.30) > 0.001 {
    display as error "  FAIL: s_t[2020] = " %8.6f `s_reached' " (expected 0.30)"
    local ramp_ok = 0
}

* Check held constant after target year
if abs(`s_after' - 0.30) > 0.001 {
    display as error "  FAIL: s_t[2030] = " %8.6f `s_after' " (expected 0.30 -- constant after target)"
    local ramp_ok = 0
}

if `ramp_ok' {
    display as result "  PASS: Savings rate ramp correct"
    display as result "    s[2000]=0.20, s[2010]=0.25, s[2020]=0.30, s[2030]=0.30"
    local n_pass = `n_pass' + 1
}
else {
    local test_pass = 0
}


/* ==================================================================
   TEST 5: Climate damage reduces growth
   ================================================================== */

display _n as text "--- Test 5: Climate damage reduces growth ---"

* Run baseline (no climate)
ltgm_setup, model(standard) scenario(test_noclim)          ///
    year0(2000) horizon(2050)                               ///
    alpha(0.35) s(0.20) delta(0.05)                         ///
    g_tfp(0.01) g_pop(0.02) g_lfp(0)                       ///
    ky0(2.5) y0(1000)                                       ///
    povshare(0.40) povelast(-2.0) povline(2.15)             ///
    climate(0)

ltgm_run, scenario(test_noclim) nodisplay
local ypc_noclim = y_pc[_N]

* Run with climate damage
ltgm_setup, model(standard) scenario(test_clim)            ///
    year0(2000) horizon(2050)                               ///
    alpha(0.35) s(0.20) delta(0.05)                         ///
    g_tfp(0.01) g_pop(0.02) g_lfp(0)                       ///
    ky0(2.5) y0(1000)                                       ///
    povshare(0.40) povelast(-2.0) povline(2.15)             ///
    climate(0.30)

ltgm_run, scenario(test_clim) nodisplay
local ypc_clim = y_pc[_N]

local n_tests = `n_tests' + 1

if `ypc_clim' < `ypc_noclim' {
    display as result "  PASS: Climate damage reduces GDP per capita"
    display as result "    No climate: $" %10.2fc `ypc_noclim' "  With 30% damage: $" %10.2fc `ypc_clim'
    local n_pass = `n_pass' + 1
}
else {
    display as error "  FAIL: Climate damage did not reduce GDP per capita"
    local test_pass = 0
}


/* ==================================================================
   TEST 6: Compare command runs without error
   ================================================================== */

display _n as text "--- Test 6: Compare command ---"

local n_tests = `n_tests' + 1

capture ltgm_compare, base(test_noclim) alt(test_clim) nodisplay
if _rc == 0 {
    display as result "  PASS: ltgm_compare executed successfully"
    local n_pass = `n_pass' + 1
}
else {
    display as error "  FAIL: ltgm_compare returned error code " _rc
    local test_pass = 0
}


/* ==================================================================
   TEST 7: Burundi stress test (negative TFP, declining economy)
   ================================================================== */

display _n as text "--- Test 7: Burundi stress test (negative TFP) ---"

* Load Burundi's actual bundled parameters
ltgm_import, country(BDI)

* Verify we found Burundi
local n_tests = `n_tests' + 1
if r(found) > 0 {
    display as result "  PASS: Burundi found in bundled data"
    local n_pass = `n_pass' + 1
}
else {
    display as error "  FAIL: Burundi not found in bundled data"
    local test_pass = 0
}

* Confirm g_tfp is negative (the stress condition)
local bdi_gtfp = r(g_tfp)
local n_tests = `n_tests' + 1
if `bdi_gtfp' < 0 {
    display as result "  PASS: Burundi g_tfp is negative (" %8.6f `bdi_gtfp' ")"
    local n_pass = `n_pass' + 1
}
else {
    display as error "  FAIL: Expected negative g_tfp for Burundi; got " %8.6f `bdi_gtfp'
    local test_pass = 0
}

* (a) Run model without errors
ltgm_setup, model(standard) country(BDI) year0(2022) horizon(2050) scenario(test_bdi)
ltgm_run, scenario(test_bdi) nodisplay

local n_tests = `n_tests' + 1
display as result "  PASS: Burundi model ran without errors"
local n_pass = `n_pass' + 1

local bdi_nyears = _N

* (b) GDP per capita should be declining: y_pc[last] < y_pc[1]
local bdi_ypc_init  = y_pc[1]
local bdi_ypc_final = y_pc[`bdi_nyears']

local n_tests = `n_tests' + 1
if `bdi_ypc_final' < `bdi_ypc_init' {
    display as result "  PASS: GDP per capita declining ($" %6.0f `bdi_ypc_init' " -> $" %6.0f `bdi_ypc_final' ")"
    local n_pass = `n_pass' + 1
}
else {
    display as error "  FAIL: GDP per capita not declining (init=" %8.2f `bdi_ypc_init' " final=" %8.2f `bdi_ypc_final' ")"
    local test_pass = 0
}

* (c) Poverty should be rising: pov[last] > pov[1]
local bdi_pov_init  = pov[1]
local bdi_pov_final = pov[`bdi_nyears']

local n_tests = `n_tests' + 1
if `bdi_pov_final' > `bdi_pov_init' {
    display as result "  PASS: Poverty rising (" %5.1f `bdi_pov_init'*100 "% -> " %5.1f `bdi_pov_final'*100 "%)"
    local n_pass = `n_pass' + 1
}
else {
    display as error "  FAIL: Poverty not rising (init=" %6.4f `bdi_pov_init' " final=" %6.4f `bdi_pov_final' ")"
    local test_pass = 0
}

* (d) Poverty should be clamped at 1.0 (not exceed it)
quietly summarize pov
local bdi_pov_max = r(max)
local bdi_pov_min = r(min)

local n_tests = `n_tests' + 1
if `bdi_pov_max' <= 1.0001 {
    display as result "  PASS: Poverty clamped at 1.0 (max=" %6.4f `bdi_pov_max' ")"
    local n_pass = `n_pass' + 1
}
else {
    display as error "  FAIL: Poverty exceeded 1.0 (max=" %6.4f `bdi_pov_max' ")"
    local test_pass = 0
}

local n_tests = `n_tests' + 1
if `bdi_pov_min' >= -0.0001 {
    display as result "  PASS: Poverty non-negative (min=" %6.4f `bdi_pov_min' ")"
    local n_pass = `n_pass' + 1
}
else {
    display as error "  FAIL: Poverty went negative (min=" %6.4f `bdi_pov_min' ")"
    local test_pass = 0
}

* (e) Average GDP per capita growth should be negative
local bdi_avg_gy = (`bdi_ypc_final' / `bdi_ypc_init') ^ (1 / (`bdi_nyears' - 1)) - 1

local n_tests = `n_tests' + 1
if `bdi_avg_gy' < 0 {
    display as result "  PASS: Average g_y is negative (" %6.3f `bdi_avg_gy'*100 "%/yr)"
    local n_pass = `n_pass' + 1
}
else {
    display as error "  FAIL: Average g_y is not negative (" %6.4f `bdi_avg_gy' ")"
    local test_pass = 0
}


/* ==================================================================
   SUMMARY
   ================================================================== */

display _n "============================================================"
display    "  TEST SUMMARY"
display    "============================================================"
display    "  Tests run   : `n_tests'"
display    "  Tests passed: `n_pass'"
display    "  Tests failed: " `n_tests' - `n_pass'

if `test_pass' {
    display as result _n "  ALL TESTS PASSED" _n
}
else {
    display as error _n "  SOME TESTS FAILED" _n
}

display "============================================================" _n

* Clean up test files
capture erase _ltgm_params_test_ss.dta
capture erase _ltgm_results_test_ss.dta
capture erase _ltgm_params_test_ramp.dta
capture erase _ltgm_results_test_ramp.dta
capture erase _ltgm_params_test_noclim.dta
capture erase _ltgm_results_test_noclim.dta
capture erase _ltgm_params_test_clim.dta
capture erase _ltgm_results_test_clim.dta
capture erase _ltgm_params_test_bdi.dta
capture erase _ltgm_results_test_bdi.dta
