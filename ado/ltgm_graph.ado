*! ltgm_graph.ado  v1.0.0  2026-04-01
*! World Bank LTGM Stata Package -- Graph Results
*! Generates time-series graphs from LTGM results datasets
*!
*! Authors: Mustapha Wasseja / World Bank LTGM Team
*! Requires: Stata 13+

capture program drop ltgm_graph
program define ltgm_graph
    version 13.0

    /* ------------------------------------------------------------------ */
    /*  Syntax                                                             */
    /* ------------------------------------------------------------------ */
    syntax [, SCENario(string) OVER(string) VAR(string)             ///
              SAVEPath(string) SAVing(string) TItle(string)         ///
              NODisplay ]

    /* ------------------------------------------------------------------ */
    /*  Defaults                                                           */
    /* ------------------------------------------------------------------ */
    if `"`scenario'"' == "" {
        local scenario "baseline"
    }

    if `"`var'"' == "" {
        local var "y_pc"
    }

    if `"`savepath'"' == "" {
        local savepath `"`c(pwd)'"'
    }

    /* ------------------------------------------------------------------ */
    /*  Validate variable name                                             */
    /* ------------------------------------------------------------------ */
    local valid_vars "y_pc g_y g_Y ky pov s_t"
    local var_ok = 0
    foreach v of local valid_vars {
        if "`var'" == "`v'" {
            local var_ok = 1
        }
    }
    if !`var_ok' {
        display as error "ltgm_graph: var(`var') not recognised."
        display as error "Valid options: `valid_vars'"
        exit 198
    }

    /* ------------------------------------------------------------------ */
    /*  Set axis labels and titles by variable                             */
    /* ------------------------------------------------------------------ */
    if "`var'" == "y_pc" {
        local ytitle "GDP per capita ($)"
        local default_title "GDP per Capita"
    }
    else if "`var'" == "g_y" {
        local ytitle "GDP per capita growth (fraction)"
        local default_title "GDP per Capita Growth"
    }
    else if "`var'" == "g_Y" {
        local ytitle "Aggregate GDP growth (fraction)"
        local default_title "Aggregate GDP Growth"
    }
    else if "`var'" == "ky" {
        local ytitle "Capital-output ratio (K/Y)"
        local default_title "Capital-Output Ratio"
    }
    else if "`var'" == "pov" {
        local ytitle "Poverty headcount (fraction)"
        local default_title "Poverty Headcount"
    }
    else if "`var'" == "s_t" {
        local ytitle "Savings rate (fraction)"
        local default_title "Savings Rate"
    }

    if `"`title'"' == "" {
        local title "LTGM: `default_title'"
    }

    /* ------------------------------------------------------------------ */
    /*  Load primary scenario                                              */
    /* ------------------------------------------------------------------ */
    local file1 `"`savepath'/_ltgm_results_`scenario'.dta"'

    capture confirm file `"`file1'"'
    if _rc {
        display as error "ltgm_graph: results file not found: `file1'"
        display as error "Run ltgm_run with scenario(`scenario') first."
        exit 601
    }

    preserve
    quietly use `"`file1'"', clear

    local country_lbl = country_lbl[1]

    /* ------------------------------------------------------------------ */
    /*  Single scenario graph                                              */
    /* ------------------------------------------------------------------ */
    if `"`over'"' == "" {
        if "`nodisplay'" == "" {
            twoway (line `var' year,                        ///
                lcolor(navy) lwidth(medthick)               ///
                lpattern(solid)                             ///
                ),                                          ///
                title(`"`title'"')                          ///
                subtitle(`"`country_lbl' -- `scenario'"')    ///
                ytitle(`"`ytitle'"')                        ///
                xtitle("Year")                              ///
                legend(off)                                 ///
                graphregion(color(white))                   ///
                plotregion(color(white))                    ///
                scheme(s2color)
        }

        if `"`saving'"' != "" {
            quietly graph export `"`saving'"', replace
            display as text "Graph saved: `saving'"
        }

        restore
        exit
    }

    /* ------------------------------------------------------------------ */
    /*  Overlay graph: primary + over scenario                             */
    /* ------------------------------------------------------------------ */
    local file2 `"`savepath'/_ltgm_results_`over'.dta"'

    capture confirm file `"`file2'"'
    if _rc {
        display as error "ltgm_graph: overlay results file not found: `file2'"
        display as error "Run ltgm_run with scenario(`over') first."
        restore
        exit 601
    }

    * Rename primary variable
    rename `var' `var'_1

    * Keep only what we need
    keep year `var'_1

    tempfile graph_tmp
    quietly save `graph_tmp'

    * Load overlay scenario
    quietly use `"`file2'"', clear
    rename `var' `var'_2
    keep year `var'_2

    * Merge
    quietly merge 1:1 year using `graph_tmp', nogenerate
    sort year

    * Plot overlay
    if "`nodisplay'" == "" {
        twoway (line `var'_1 year,                          ///
                lcolor(navy) lwidth(medthick)               ///
                lpattern(solid)                             ///
            )                                               ///
            (line `var'_2 year,                              ///
                lcolor(cranberry) lwidth(medthick)           ///
                lpattern(dash)                              ///
            ),                                              ///
            title(`"`title'"')                              ///
            subtitle(`"`country_lbl'"')                     ///
            ytitle(`"`ytitle'"')                            ///
            xtitle("Year")                                  ///
            legend(order(1 "`scenario'" 2 "`over'")         ///
                position(6) rows(1))                        ///
            graphregion(color(white))                       ///
            plotregion(color(white))                        ///
            scheme(s2color)
    }

    if `"`saving'"' != "" {
        quietly graph export `"`saving'"', replace
        display as text "Graph saved: `saving'"
    }

    restore

end
