/**********************************************************************
 *  kenya_example.do
 *  LTGM Stata Package -- Full End-to-End Example for Kenya
 *
 *  Demonstrates both the simple (auto-fill) and manual workflows.
 *
 *  Authors: Mustapha Wasseja / World Bank LTGM Team
 *  Date:    April 2026
 **********************************************************************/

clear all
set more off

display _n "============================================================"
display    "  LTGM Stata Package - Kenya Example"
display    "============================================================" _n


/* ==================================================================
   PART A: SIMPLE WORKFLOW (with bundled data auto-fill)
   Zero manual parameter entry needed
   ================================================================== */

display _n "--- Part A: Simple workflow with auto-fill ---" _n

* Step 1: Baseline -- all parameters auto-filled from bundled Kenya data
ltgm_setup, model(standard) country(Kenya) year0(2022) horizon(2050) ///
    scenario(baseline)

* Step 2: Run baseline
ltgm_run, scenario(baseline)

* Step 3: High-investment scenario -- override only what you want to test
ltgm_setup, model(standard) country(Kenya) year0(2022) horizon(2050) ///
    scenario(high_investment) s(0.30)

* Step 4: Run high-investment scenario
ltgm_run, scenario(high_investment)

* Step 5: Compare
ltgm_compare, base(baseline) alt(high_investment)

* Step 6: Graph
ltgm_graph, scenario(baseline) over(high_investment) var(y_pc) ///
    title("Kenya: GDP per Capita Projections")

* Step 7: Export
ltgm_export, using(kenya_results.xlsx) scenarios(baseline high_investment)


/* ==================================================================
   PART B: MANUAL WORKFLOW (explicit parameter entry, no auto-fill)
   Still works exactly as before
   ================================================================== */

display _n "--- Part B: Manual workflow (for reference) ---" _n

ltgm_setup, model(standard) country("Kenya") scenario(manual_bl) ///
    year0(2022) horizon(2050) noautofill                          ///
    alpha(0.35) s(0.22) delta(0.05)                               ///
    g_tfp(0.008) g_pop(0.024) g_lfp(0.002)                       ///
    ky0(2.8) y0(2082)                                             ///
    povshare(0.36) povelast(-2.5) povline(2.15)

ltgm_run, scenario(manual_bl)


/* ==================================================================
   Summary
   ================================================================== */

display _n "============================================================"
display    "  Kenya example complete."
display    "  Files created:"
display    "    _ltgm_params_baseline.dta"
display    "    _ltgm_params_high_investment.dta"
display    "    _ltgm_params_manual_bl.dta"
display    "    _ltgm_results_baseline.dta"
display    "    _ltgm_results_high_investment.dta"
display    "    _ltgm_results_manual_bl.dta"
display    "    kenya_results.xlsx"
display    "============================================================" _n
