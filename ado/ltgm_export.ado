*! ltgm_export.ado  v1.0.1  2026-04-01
*! World Bank LTGM Stata Package -- Export Results to Excel
*! Writes LTGM results datasets to .xlsx using Stata 13 putexcel
*!
*! Authors: Mustapha Wasseja / World Bank LTGM Team
*! Requires: Stata 13+

capture program drop ltgm_export
program define ltgm_export
    version 13.0

    /* ------------------------------------------------------------------ */
    /*  Syntax                                                             */
    /* ------------------------------------------------------------------ */
    syntax , Using(string) [ SCENarios(string) SAVEPath(string) ]

    /* ------------------------------------------------------------------ */
    /*  Defaults                                                           */
    /* ------------------------------------------------------------------ */
    if `"`scenarios'"' == "" {
        local scenarios "baseline"
    }

    if `"`savepath'"' == "" {
        local savepath `"`c(pwd)'"'
    }

    /* ------------------------------------------------------------------ */
    /*  Process each scenario as a separate sheet                          */
    /* ------------------------------------------------------------------ */
    local sheet_num = 0

    foreach scen of local scenarios {

        local sheet_num = `sheet_num' + 1
        local resultsfile `"`savepath'/_ltgm_results_`scen'.dta"'

        capture confirm file `"`resultsfile'"'
        if _rc {
            display as error "ltgm_export: results file not found: `resultsfile'"
            display as error "Run ltgm_run with scenario(`scen') first."
            exit 601
        }

        preserve
        quietly use `"`resultsfile'"', clear

        * Extract metadata
        local model_lbl   = model_lbl[1]
        local country_lbl = country_lbl[1]
        local nyears      = _N

        /* -------------------------------------------------------------- */
        /*  Set up putexcel for this sheet                                 */
        /* -------------------------------------------------------------- */
        * Truncate sheet name to 31 chars (Excel limit)
        local sheetname = substr("`scen'", 1, 31)

        if `sheet_num' == 1 {
            quietly putexcel set `"`using'"', sheet("`sheetname'") replace
        }
        else {
            quietly putexcel set `"`using'"', sheet("`sheetname'") modify
        }

        /* -------------------------------------------------------------- */
        /*  Write header row                                               */
        /*  Stata 13 putexcel requires expressions in parentheses:         */
        /*    putexcel A1 = ("string")   for strings                       */
        /*    putexcel A1 = (expression) for numbers                       */
        /* -------------------------------------------------------------- */
        * Row 1: metadata
        * Detect model type
        local _is_pc = 0
        capture confirm variable kg_y
        if _rc == 0 {
            local _is_pc = 1
        }

        if `_is_pc' {
            quietly putexcel A1 = ("LTGM Public Capital Model Results")
        }
        else {
            quietly putexcel A1 = ("LTGM Standard Model Results")
        }
        quietly putexcel A2 = ("Country:")
        quietly putexcel B2 = ("`country_lbl'")
        quietly putexcel A3 = ("Scenario:")
        quietly putexcel B3 = ("`scen'")
        quietly putexcel A4 = ("Model:")
        quietly putexcel B4 = ("`model_lbl'")

        * Row 6: column headers
        if `_is_pc' {
            quietly putexcel A6 = ("Year")
            quietly putexcel B6 = ("GDP/cap")
            quietly putexcel C6 = ("GDPpc Growth")
            quietly putexcel D6 = ("GDP Growth")
            quietly putexcel E6 = ("Kg/Y Ratio")
            quietly putexcel F6 = ("Kp/Y Ratio")
            quietly putexcel G6 = ("Pub Inv/GDP")
            quietly putexcel H6 = ("Priv Inv/GDP")
            quietly putexcel I6 = ("TFP Growth")
            quietly putexcel J6 = ("Labour Growth")
            quietly putexcel K6 = ("Poverty Rate")
        }
        else {
            quietly putexcel A6 = ("Year")
            quietly putexcel B6 = ("GDP/cap")
            quietly putexcel C6 = ("GDPpc Growth")
            quietly putexcel D6 = ("GDP Growth")
            quietly putexcel E6 = ("K/Y Ratio")
            quietly putexcel F6 = ("Savings Rate")
            quietly putexcel G6 = ("TFP Growth")
            quietly putexcel H6 = ("Labour Growth")
            quietly putexcel I6 = ("Poverty Rate")
        }

        /* -------------------------------------------------------------- */
        /*  Write data rows                                                */
        /* -------------------------------------------------------------- */
        forvalues i = 1/`nyears' {

            local row = `i' + 6

            quietly putexcel A`row' = (year[`i'])
            quietly putexcel B`row' = (y_pc[`i'])

            if `_is_pc' {
                quietly putexcel C`row' = (g_ypc[`i'])
                quietly putexcel D`row' = (g_Y[`i'])
                quietly putexcel E`row' = (kg_y[`i'])
                quietly putexcel F`row' = (kp_y[`i'])
                quietly putexcel G`row' = (pub_inv_t[`i'])
                quietly putexcel H`row' = (priv_inv_t[`i'])
                quietly putexcel I`row' = (g_tfp_t[`i'])
                quietly putexcel J`row' = (g_L_t[`i'])
                quietly putexcel K`row' = (pov[`i'])
            }
            else {
                quietly putexcel C`row' = (g_y[`i'])
                quietly putexcel D`row' = (g_Y[`i'])
                quietly putexcel E`row' = (ky[`i'])
                quietly putexcel F`row' = (s_t[`i'])
                quietly putexcel G`row' = (g_tfp_t[`i'])
                quietly putexcel H`row' = (g_L_t[`i'])
                quietly putexcel I`row' = (pov[`i'])
            }
        }

        restore
        display as text "  Sheet '`sheetname'' written (`nyears' rows)"
    }

    display ""
    display as text "Excel file saved: " as result `"`using'"'
    display ""

end
