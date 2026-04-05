*! ltgm_compare.ado  v1.0.0  2026-04-01
*! World Bank LTGM Stata Package -- Baseline vs Scenario Comparison
*! Loads two results files, computes differences, displays comparison table
*!
*! Authors: Mustapha Wasseja / World Bank LTGM Team
*! Requires: Stata 13+

capture program drop ltgm_compare
program define ltgm_compare, rclass
    version 13.0

    /* ------------------------------------------------------------------ */
    /*  Syntax                                                             */
    /* ------------------------------------------------------------------ */
    syntax , Base(string) Alt(string)               ///
        [ SAVEPath(string) YEARs(numlist) SAVing(string) NODisplay ]

    /* ------------------------------------------------------------------ */
    /*  Defaults                                                           */
    /* ------------------------------------------------------------------ */
    if `"`savepath'"' == "" {
        local savepath `"`c(pwd)'"'
    }

    /* ------------------------------------------------------------------ */
    /*  Locate and validate results files                                  */
    /* ------------------------------------------------------------------ */
    local basefile `"`savepath'/_ltgm_results_`base'.dta"'
    local altfile  `"`savepath'/_ltgm_results_`alt'.dta"'

    capture confirm file `"`basefile'"'
    if _rc {
        display as error "ltgm_compare: base results file not found: `basefile'"
        display as error "Run ltgm_run with scenario(`base') first."
        exit 601
    }

    capture confirm file `"`altfile'"'
    if _rc {
        display as error "ltgm_compare: alt results file not found: `altfile'"
        display as error "Run ltgm_run with scenario(`alt') first."
        exit 601
    }

    /* ------------------------------------------------------------------ */
    /*  Load base results                                                  */
    /* ------------------------------------------------------------------ */
    preserve
    quietly use `"`basefile'"', clear

    * Extract metadata from base
    local model_lbl   = model_lbl[1]
    local country_lbl = country_lbl[1]
    local year0       = year[1]
    local nyears      = _N
    local horizon     = year[`nyears']

    * Detect model type (standard vs PC)
    local _is_pc = 0
    capture confirm variable kg_y
    if _rc == 0 {
        local _is_pc = 1
    }

    * Rename numeric variables with _base suffix
    rename y_pc    y_pc_base
    rename g_y     g_y_base
    rename g_Y     g_Y_base
    rename pov     pov_base

    if `_is_pc' {
        rename kg_y       kg_y_base
        rename kp_y       kp_y_base
        rename pub_inv_t  pub_inv_base
        rename priv_inv_t priv_inv_base
        capture rename g_ypc g_ypc_base
        capture rename g_L_t g_L_t_base
        keep year y_pc_base g_y_base g_Y_base pov_base ///
             kg_y_base kp_y_base pub_inv_base priv_inv_base
    }
    else {
        rename ky      ky_base
        rename s_t     s_t_base
        capture rename g_tfp_t g_tfp_t_base
        capture rename g_L_t   g_L_t_base
        keep year y_pc_base g_y_base g_Y_base ky_base s_t_base pov_base
    }

    tempfile base_tmp
    quietly save `base_tmp'

    /* ------------------------------------------------------------------ */
    /*  Load alt results and merge                                         */
    /* ------------------------------------------------------------------ */
    quietly use `"`altfile'"', clear

    * Rename numeric variables with _alt suffix
    rename y_pc    y_pc_alt
    rename g_y     g_y_alt
    rename g_Y     g_Y_alt
    rename pov     pov_alt

    if `_is_pc' {
        rename kg_y       kg_y_alt
        rename kp_y       kp_y_alt
        rename pub_inv_t  pub_inv_alt
        rename priv_inv_t priv_inv_alt
        capture rename g_ypc g_ypc_alt
        capture rename g_L_t g_L_t_alt
        keep year y_pc_alt g_y_alt g_Y_alt pov_alt ///
             kg_y_alt kp_y_alt pub_inv_alt priv_inv_alt
    }
    else {
        rename ky      ky_alt
        rename s_t     s_t_alt
        capture rename g_tfp_t g_tfp_t_alt
        capture rename g_L_t   g_L_t_alt
        keep year y_pc_alt g_y_alt g_Y_alt ky_alt s_t_alt pov_alt
    }

    * Merge on year
    quietly merge 1:1 year using `base_tmp', nogenerate

    * Sort by year
    sort year

    /* ------------------------------------------------------------------ */
    /*  Compute comparison variables                                       */
    /* ------------------------------------------------------------------ */
    quietly generate double delta_y_pc = y_pc_alt - y_pc_base
    quietly generate double pct_y_pc   = (y_pc_alt / y_pc_base - 1) * 100
    quietly generate double delta_g_y  = (g_y_alt - g_y_base) * 100
    quietly generate double delta_pov  = (pov_alt - pov_base) * 100

    if `_is_pc' {
        quietly generate double delta_kg_y    = kg_y_alt - kg_y_base
        quietly generate double delta_kp_y    = kp_y_alt - kp_y_base
        quietly generate double delta_pub_inv = (pub_inv_alt - pub_inv_base) * 100
    }
    else {
        quietly generate double delta_ky   = ky_alt - ky_base
    }

    * Add metadata labels
    quietly generate str20 model_lbl    = "`model_lbl'"
    quietly generate str60 country_lbl  = `"`country_lbl'"'
    quietly generate str40 base_lbl     = "`base'"
    quietly generate str40 alt_lbl      = "`alt'"

    /* ------------------------------------------------------------------ */
    /*  Save comparison dataset                                            */
    /* ------------------------------------------------------------------ */
    if `"`saving'"' != "" {
        quietly save `"`saving'"', replace
    }

    /* ------------------------------------------------------------------ */
    /*  Determine which years to display                                   */
    /* ------------------------------------------------------------------ */
    local disp_nyears = _N

    /* ------------------------------------------------------------------ */
    /*  Display comparison table                                           */
    /* ------------------------------------------------------------------ */
    if "`nodisplay'" == "" {
        display ""
        display as text "{hline 80}"
        display as result "  LTGM Comparison: `base' vs `alt'"
        display as text "{hline 80}"
        display as text "  Country  : " as result `"`country_lbl'"'
        display as text "  Model    : " as result "`model_lbl'"
        display as text "  Period   : " as result "`year0' - `horizon'"
        display as text "{hline 80}"

        display as text "  {ralign 6:Year}" ///
            "  {ralign 11:Base GDP/c}" ///
            "  {ralign 11:Alt GDP/c}" ///
            "  {ralign 10:D GDP/c}" ///
            "  {ralign 9:D% GDP/c}" ///
            "  {ralign 9:Base Pov}" ///
            "  {ralign 9:Alt Pov}"
        display as text "  {hline 74}"

        * Determine display rows: use years() if provided, else every 5 + endpoints
        forvalues i = 1/`disp_nyears' {
            local yr = year[`i']
            local show = 0

            if `"`years'"' != "" {
                * Show only user-specified years
                foreach y of numlist `years' {
                    if `yr' == `y' {
                        local show = 1
                    }
                }
            }
            else {
                * Default: first, last, every 5 years
                if `i' == 1 {
                    local show = 1
                }
                else if `i' == `disp_nyears' {
                    local show = 1
                }
                else if mod(`yr' - `year0', 5) == 0 {
                    local show = 1
                }
            }

            if `show' {
                local v_ypc_b = y_pc_base[`i']
                local v_ypc_a = y_pc_alt[`i']
                local v_dypc  = delta_y_pc[`i']
                local v_pypc  = pct_y_pc[`i']
                local v_pov_b = pov_base[`i'] * 100
                local v_pov_a = pov_alt[`i'] * 100

                display as text "  {ralign 6:`yr'}" ///
                    as result "  {ralign 11:" %9.2fc `v_ypc_b' "}" ///
                    as result "  {ralign 11:" %9.2fc `v_ypc_a' "}" ///
                    as result "  {ralign 10:" %8.2fc `v_dypc' "}" ///
                    as result "  {ralign 9:" %7.2f `v_pypc' "}" ///
                    as result "  {ralign 9:" %7.2f `v_pov_b' "}" ///
                    as result "  {ralign 9:" %7.2f `v_pov_a' "}"
            }
        }

        display as text "  {hline 74}"

        * Summary at horizon
        local v_dypc_h  = delta_y_pc[`disp_nyears']
        local v_pypc_h  = pct_y_pc[`disp_nyears']
        local v_dpov_h  = delta_pov[`disp_nyears']

        display as text "  At horizon (`horizon'):"
        display as text "    GDP per capita difference : " ///
            as result "$" %10.2fc `v_dypc_h' as text " (" as result %6.2f `v_pypc_h' as text "%)"
        display as text "    Poverty headcount diff    : " ///
            as result %6.2f `v_dpov_h' as text " pp"

        if `_is_pc' {
            local v_dkgy_h = delta_kg_y[`disp_nyears']
            local v_dkpy_h = delta_kp_y[`disp_nyears']
            display as text "    Kg/Y difference           : " ///
                as result %6.3f `v_dkgy_h'
            display as text "    Kp/Y difference           : " ///
                as result %6.3f `v_dkpy_h'
        }
        else {
            local v_dky_h = delta_ky[`disp_nyears']
            display as text "    K/Y ratio difference      : " ///
                as result %6.3f `v_dky_h'
        }
        display as text "{hline 80}"
        display ""
    }

    /* ------------------------------------------------------------------ */
    /*  Leave comparison dataset in memory                                 */
    /* ------------------------------------------------------------------ */
    * Data is already in memory from the preserve block -- we need to
    * break out of preserve to leave it for the user
    restore, not

    /* ------------------------------------------------------------------ */
    /*  Return values (at horizon year)                                    */
    /* ------------------------------------------------------------------ */
    return local  base_scenario  "`base'"
    return local  alt_scenario   "`alt'"
    return local  model          "`model_lbl'"
    return local  country        `"`country_lbl'"'
    return scalar year0          = `year0'
    return scalar horizon        = `horizon'
    return scalar delta_y_pc     = delta_y_pc[`disp_nyears']
    return scalar pct_y_pc       = pct_y_pc[`disp_nyears']
    return scalar delta_pov      = delta_pov[`disp_nyears']

    if `_is_pc' {
        return scalar delta_kg_y = delta_kg_y[`disp_nyears']
        return scalar delta_kp_y = delta_kp_y[`disp_nyears']
    }
    else {
        return scalar delta_ky   = delta_ky[`disp_nyears']
    }

end
