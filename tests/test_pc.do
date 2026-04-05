/**********************************************************************
 *  test_pc.do -- LTGM Public Capital Model Tests
 *
 *  Tests:
 *   1. PC Model 1 basic (Kenya default parameters)
 *   2. PC Model 1 with custom investment split
 *   3. PC Model 2 inverse (required public investment for 3% growth)
 *   4. PC compare (baseline vs high public investment)
 *   5. PC graph
 *   6. PC export
 *   7. Manual parameters (no country auto-fill)
 *
 *  Requires: ltgm_setup, ltgm_run, ltgm_pc_run, ltgm_compare,
 *            ltgm_graph, ltgm_export in adopath
 *
 *  Run from ltgm_github/ directory:
 *    adopath + "ado"
 *    do tests/test_pc.do
 **********************************************************************/

clear all
set more off
discard

* Ensure ado/ is in path
capture adopath + "`c(pwd)'/ado"

local pass = 0
local fail = 0
local total = 7

display _n as text "{hline 60}"
display as result "  LTGM Public Capital Model -- Test Suite"
display as text "{hline 60}"

/* ==================================================================
   Test 1: PC Model 1 basic -- Kenya default parameters
   ================================================================== */
display _n as text "Test 1: PC Model 1 basic (Kenya defaults)" _n

capture {
    ltgm_setup, model(pc) country(Kenya) year0(2023) scenario(pc_test1)
    ltgm_run, scenario(pc_test1)
}
if _rc == 0 {
    * Verify output variables exist
    capture confirm variable y_pc kg_y kp_y pub_inv_t priv_inv_t g_ypc pov
    if _rc == 0 {
        * Check reasonable ranges
        local ypc_final = y_pc[_N]
        local kgy_final = kg_y[_N]
        local kpy_final = kp_y[_N]
        if `ypc_final' > 0 & `kgy_final' > 0 & `kpy_final' > 0 {
            display as result "  PASS: Kenya PC model produced valid results"
            display as text "    Final GDP/cap: $" %10.2fc `ypc_final'
            display as text "    Final Kg/Y: " %6.3f `kgy_final'
            display as text "    Final Kp/Y: " %6.3f `kpy_final'
            local pass = `pass' + 1
        }
        else {
            display as error "  FAIL: Results out of range"
            local fail = `fail' + 1
        }
    }
    else {
        display as error "  FAIL: Missing PC output variables"
        local fail = `fail' + 1
    }
}
else {
    display as error "  FAIL: PC setup/run failed rc=" _rc
    local fail = `fail' + 1
}

/* ==================================================================
   Test 2: PC Model 1 with custom investment split
   ================================================================== */
display _n as text "Test 2: PC Model 1 custom investment" _n

capture {
    ltgm_setup, model(pc) country(Kenya) year0(2023) scenario(pc_test2) ///
        pubinv(0.10) privinv(0.18) pubeff(0.80)
    ltgm_run, scenario(pc_test2)
}
if _rc == 0 {
    local ypc1 = y_pc[_N]
    * Higher investment + efficiency should produce higher GDP
    * (compared to default ~5% pub, ~13% priv)
    quietly use "_ltgm_results_pc_test1.dta", clear
    local ypc_base = y_pc[_N]
    quietly use "_ltgm_results_pc_test2.dta", clear
    if `ypc1' > `ypc_base' {
        display as result "  PASS: Higher inv produces higher GDP ($" %10.2fc `ypc1' " > $" %10.2fc `ypc_base' ")"
        local pass = `pass' + 1
    }
    else {
        display as error "  FAIL: Higher inv should produce higher GDP"
        display as error "    test2=$" %10.2fc `ypc1' " vs test1=$" %10.2fc `ypc_base'
        local fail = `fail' + 1
    }
}
else {
    display as error "  FAIL: Custom investment test failed rc=" _rc
    local fail = `fail' + 1
}

/* ==================================================================
   Test 3: PC Model 2 -- Required public investment for 3% growth
   ================================================================== */
display _n as text "Test 3: PC Model 2 inverse (3% GDP/cap target)" _n

capture {
    ltgm_setup, model(pc) country(Kenya) year0(2023) scenario(pc_test3) ///
        submodel(2) gdptarget(0.03)
    ltgm_run, scenario(pc_test3)
}
if _rc == 0 {
    capture confirm variable pub_inv_t
    if _rc == 0 {
        local req_ig = pub_inv_t[1]
        local gypc = g_ypc[1]
        if `req_ig' > 0 & `req_ig' < 1 {
            display as result "  PASS: Required Ig/Y = " %6.2f `req_ig'*100 "%"
            display as text "    Target g(ypc) = " %6.2f `gypc'*100 "%"
            local pass = `pass' + 1
        }
        else {
            display as error "  FAIL: Required Ig/Y out of range: " `req_ig'
            local fail = `fail' + 1
        }
    }
    else {
        display as error "  FAIL: pub_inv_t variable missing"
        local fail = `fail' + 1
    }
}
else {
    display as error "  FAIL: PC Model 2 failed rc=" _rc
    local fail = `fail' + 1
}

/* ==================================================================
   Test 4: PC compare
   ================================================================== */
display _n as text "Test 4: PC compare (baseline vs high pub investment)" _n

capture {
    ltgm_compare, base(pc_test1) alt(pc_test2)
}
if _rc == 0 {
    capture confirm variable delta_y_pc pct_y_pc delta_pov
    if _rc == 0 {
        local dy = delta_y_pc[_N]
        display as result "  PASS: PC compare works"
        display as text "    GDP/cap difference at horizon: $" %10.2fc `dy'
        local pass = `pass' + 1
    }
    else {
        display as error "  FAIL: Missing comparison variables"
        local fail = `fail' + 1
    }
}
else {
    display as error "  FAIL: PC compare failed rc=" _rc
    local fail = `fail' + 1
}

/* ==================================================================
   Test 5: PC graph
   ================================================================== */
display _n as text "Test 5: PC graph" _n

capture {
    ltgm_graph, scenario(pc_test1) var(y_pc) nodisplay
}
if _rc == 0 {
    display as result "  PASS: PC graph (y_pc) generated"
    local pass = `pass' + 1
}
else {
    display as error "  FAIL: PC graph failed rc=" _rc
    local fail = `fail' + 1
}

/* ==================================================================
   Test 6: PC export
   ================================================================== */
display _n as text "Test 6: PC export to Excel" _n

capture {
    ltgm_export, using("pc_test_results.xlsx") scenarios(pc_test1 pc_test2)
}
if _rc == 0 {
    capture confirm file "pc_test_results.xlsx"
    if _rc == 0 {
        display as result "  PASS: PC export to Excel successful"
        local pass = `pass' + 1
    }
    else {
        display as error "  FAIL: Excel file not created"
        local fail = `fail' + 1
    }
}
else {
    display as error "  FAIL: PC export failed rc=" _rc
    local fail = `fail' + 1
}

/* ==================================================================
   Test 7: Manual parameters (no country auto-fill)
   ================================================================== */
display _n as text "Test 7: Manual PC parameters (no auto-fill)" _n

capture {
    ltgm_setup, model(pc) scenario(pc_test7) noautofill ///
        y0(2000) alpha(0.40) g_tfp(0.01) g_pop(0.02) ///
        phi(0.08) pubky(0.80) privky(2.00) ///
        deppub(0.03) deppriv(0.05) ///
        pubeff(0.65) pubinv(0.06) privinv(0.14) ///
        hcgrowth(0.005) gwatp(0.001)
    ltgm_run, scenario(pc_test7)
}
if _rc == 0 {
    local ypc = y_pc[_N]
    if `ypc' > 0 {
        display as result "  PASS: Manual PC params work (final GDP/cap=$" %10.2fc `ypc' ")"
        local pass = `pass' + 1
    }
    else {
        display as error "  FAIL: GDP/cap not positive"
        local fail = `fail' + 1
    }
}
else {
    display as error "  FAIL: Manual PC test failed rc=" _rc
    local fail = `fail' + 1
}

/* ==================================================================
   Summary
   ================================================================== */
display _n as text "{hline 60}"
display as result "  PC Test Results: `pass'/`total' PASSED, `fail'/`total' FAILED"
display as text "{hline 60}"

if `fail' > 0 {
    display as error "  WARNING: Some tests failed!"
    exit 1
}
else {
    display as result "  All PC tests passed."
}

* Clean up temp files
capture erase "_ltgm_params_pc_test1.dta"
capture erase "_ltgm_params_pc_test2.dta"
capture erase "_ltgm_params_pc_test3.dta"
capture erase "_ltgm_params_pc_test7.dta"
capture erase "_ltgm_results_pc_test1.dta"
capture erase "_ltgm_results_pc_test2.dta"
capture erase "_ltgm_results_pc_test3.dta"
capture erase "_ltgm_results_pc_test7.dta"
capture erase "pc_test_results.xlsx"
