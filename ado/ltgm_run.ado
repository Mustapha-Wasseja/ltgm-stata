*! ltgm_run.ado  v1.0.0  2026-04-01
*! World Bank LTGM Stata Package -- Standard Model Simulation
*! Reads parameters from ltgm_setup, runs Solow growth model, writes results
*!
*! Authors: Mustapha Wasseja / World Bank LTGM Team
*! Requires: Stata 13+

capture program drop ltgm_run
program define ltgm_run, rclass
    version 13.0

    /* ------------------------------------------------------------------ */
    /*  Syntax                                                             */
    /* ------------------------------------------------------------------ */
    syntax [, SCENario(string) SAVEPath(string) NOSave NODisplay   ///
              MILEstone(integer 5) ]

    /* ------------------------------------------------------------------ */
    /*  Defaults                                                           */
    /* ------------------------------------------------------------------ */
    if `"`scenario'"' == "" {
        local scenario "baseline"
    }

    if `"`savepath'"' == "" {
        local savepath `"`c(pwd)'"'
    }

    /* ------------------------------------------------------------------ */
    /*  Load parameter file                                                */
    /* ------------------------------------------------------------------ */
    local paramfile `"`savepath'/_ltgm_params_`scenario'.dta"'

    capture confirm file `"`paramfile'"'
    if _rc {
        display as error "ltgm_run: parameter file not found: `paramfile'"
        display as error "Run ltgm_setup first with scenario(`scenario')"
        exit 601
    }

    preserve
    quietly use `"`paramfile'"', clear

    * Extract all parameters into local macros
    local model_lbl    = model_lbl[1]
    local country_lbl  = country_lbl[1]
    local scenario_lbl = scenario_lbl[1]
    local year0        = year0[1]
    local horizon      = horizon[1]
    local submodel     = submodel[1]
    local alpha        = alpha[1]
    local s0           = s[1]
    local delta        = delta[1]
    local g_tfp0       = g_tfp[1]
    local g_pop0       = g_pop[1]
    local g_lfp0       = g_lfp[1]
    local g_lfp_m      = g_lfp_m[1]
    local g_lfp_f      = g_lfp_f[1]
    local male_share   = male_share[1]
    local ky0          = ky0[1]
    local y0           = y0[1]
    local climate      = climate[1]
    local povshare0    = povshare[1]
    local povelast     = povelast[1]
    local povline      = povline[1]

    * Reach-target parameters
    local s_target     = s_target[1]
    local s_year       = s_year[1]
    local gtfp_target  = gtfp_target[1]
    local gtfp_year    = gtfp_year[1]
    local gpop_target  = gpop_target[1]
    local gpop_year    = gpop_year[1]
    local glfp_target  = glfp_target[1]
    local glfp_year    = glfp_year[1]

    restore

    /* ------------------------------------------------------------------ */
    /*  Compute number of years and build results dataset                  */
    /* ------------------------------------------------------------------ */
    local nyears = `horizon' - `year0' + 1

    preserve
    clear
    quietly set obs `nyears'

    * Year variable
    quietly generate int year = `year0' + _n - 1

    * Allocate output variables
    quietly generate double y_pc    = .
    quietly generate double g_y     = .
    quietly generate double g_Y     = .
    quietly generate double ky      = .
    quietly generate double s_t     = .
    quietly generate double g_tfp_t = .
    quietly generate double g_L_t   = .
    quietly generate double pov     = .

    * String labels (constant across rows)
    quietly generate str40 scenario_lbl = "`scenario_lbl'"
    quietly generate str20 model_lbl    = "`model_lbl'"
    quietly generate str60 country_lbl  = `"`country_lbl'"'

    /* ------------------------------------------------------------------ */
    /*  Path interpolation helper: computes value at each year             */
    /*  For param p: if p_target == -1, hold constant at p0               */
    /*  Otherwise linear ramp from p0 to p_target over (year0, p_year]    */
    /* ------------------------------------------------------------------ */

    * Savings rate path
    if `s_target' != -1 {
        quietly replace s_t = `s0' + (`s_target' - `s0') *    ///
            min(1, max(0, (year - `year0') / (`s_year' - `year0')))
    }
    else {
        quietly replace s_t = `s0'
    }

    * TFP growth path (before climate adjustment)
    if `gtfp_target' != -1 {
        quietly replace g_tfp_t = `g_tfp0' + (`gtfp_target' - `g_tfp0') *    ///
            min(1, max(0, (year - `year0') / (`gtfp_year' - `year0')))
    }
    else {
        quietly replace g_tfp_t = `g_tfp0'
    }

    * Population growth path
    tempvar g_pop_t
    if `gpop_target' != -1 {
        quietly generate double `g_pop_t' = `g_pop0' + (`gpop_target' - `g_pop0') *    ///
            min(1, max(0, (year - `year0') / (`gpop_year' - `year0')))
    }
    else {
        quietly generate double `g_pop_t' = `g_pop0'
    }

    * LFP growth path
    tempvar g_lfp_t
    if `glfp_target' != -1 {
        quietly generate double `g_lfp_t' = `g_lfp0' + (`glfp_target' - `g_lfp0') *    ///
            min(1, max(0, (year - `year0') / (`glfp_year' - `year0')))
    }
    else {
        quietly generate double `g_lfp_t' = `g_lfp0'
    }

    /* ------------------------------------------------------------------ */
    /*  Compute effective labour force growth (g_L)                        */
    /* ------------------------------------------------------------------ */
    if `submodel' == 1 {
        * Sub-model 1: g_L = g_pop + g_lfp
        quietly replace g_L_t = `g_pop_t' + `g_lfp_t'
    }
    else if `submodel' == 2 {
        * Sub-model 2: g_L = g_pop + male_share*g_lfp_m + (1-male_share)*g_lfp_f
        quietly replace g_L_t = `g_pop_t' +    ///
            `male_share' * `g_lfp_m' + (1 - `male_share') * `g_lfp_f'
    }
    else {
        * Sub-model 3: same as sub-model 1 (placeholder for savings variant)
        quietly replace g_L_t = `g_pop_t' + `g_lfp_t'
    }

    /* ------------------------------------------------------------------ */
    /*  Initial conditions (year t=0, observation 1)                       */
    /* ------------------------------------------------------------------ */
    quietly replace y_pc = `y0'    in 1
    quietly replace ky   = `ky0'   in 1
    quietly replace pov  = `povshare0' in 1
    quietly replace g_y  = 0       in 1
    quietly replace g_Y  = 0       in 1

    /* ------------------------------------------------------------------ */
    /*  Solow growth loop: t = 2, ..., nyears                              */
    /*  Using scalars prefixed _ltgm_ for state, dropped after loop        */
    /* ------------------------------------------------------------------ */
    scalar _ltgm_ky  = `ky0'
    scalar _ltgm_ypc = `y0'
    scalar _ltgm_pov = `povshare0'

    forvalues t = 2/`nyears' {

        * Read time-varying parameters for period t
        scalar _ltgm_s_t     = s_t[`t']
        scalar _ltgm_gtfp_t  = g_tfp_t[`t']
        scalar _ltgm_gL_t    = g_L_t[`t']
        scalar _ltgm_gpop_t  = `g_pop_t'[`t']

        * Apply climate adjustment to TFP
        scalar _ltgm_gA_t = _ltgm_gtfp_t * (1 - `climate')

        * Capital accumulation factor: (1 - delta) + s/ky
        scalar _ltgm_capf = (1 - `delta') + _ltgm_s_t / _ltgm_ky

        * Guard: cap_factor must be positive
        if _ltgm_capf <= 0 {
            display as error "ltgm_run: capital factor <= 0 at year " year[`t']
            display as error "  s_t = " _ltgm_s_t ", ky = " _ltgm_ky ", delta = " `delta'
            display as error "  Capital is being destroyed faster than it is accumulated."
            scalar drop _ltgm_ky _ltgm_ypc _ltgm_pov     ///
                _ltgm_s_t _ltgm_gtfp_t _ltgm_gL_t        ///
                _ltgm_gpop_t _ltgm_gA_t _ltgm_capf
            restore
            exit 499
        }

        * Aggregate GDP growth: g_Y = (1+g_A) * capf^alpha * (1+g_L)^(1-alpha) - 1
        scalar _ltgm_gY = (1 + _ltgm_gA_t) *                          ///
            (_ltgm_capf ^ `alpha') *                                    ///
            ((1 + _ltgm_gL_t) ^ (1 - `alpha')) - 1

        * Update K/Y: ky_{t+1} = ky_t * capf / (1 + g_Y)
        scalar _ltgm_ky_new = _ltgm_ky * _ltgm_capf / (1 + _ltgm_gY)

        * GDP per capita growth: g_y = (1+g_Y)/(1+g_pop) - 1
        scalar _ltgm_gy = (1 + _ltgm_gY) / (1 + _ltgm_gpop_t) - 1

        * GDP per capita level
        scalar _ltgm_ypc = _ltgm_ypc * (1 + _ltgm_gy)

        * Poverty headcount: pov_{t+1} = pov_t * (1 + povelast * g_y)  [clamped 0-1]
        scalar _ltgm_pov = _ltgm_pov * (1 + `povelast' * _ltgm_gy)
        if _ltgm_pov < 0 {
            scalar _ltgm_pov = 0
        }
        if _ltgm_pov > 1 {
            scalar _ltgm_pov = 1
        }

        * Store results in dataset
        quietly replace g_Y  = _ltgm_gY        in `t'
        quietly replace g_y  = _ltgm_gy         in `t'
        quietly replace y_pc = _ltgm_ypc        in `t'
        quietly replace ky   = _ltgm_ky_new     in `t'
        quietly replace pov  = _ltgm_pov        in `t'

        * Advance K/Y state
        scalar _ltgm_ky = _ltgm_ky_new
    }

    * Clean up all _ltgm_ scalars
    capture scalar drop _ltgm_ky _ltgm_ypc _ltgm_pov
    capture scalar drop _ltgm_ky_new _ltgm_gY _ltgm_gy
    capture scalar drop _ltgm_s_t _ltgm_gtfp_t _ltgm_gL_t
    capture scalar drop _ltgm_gpop_t _ltgm_gA_t _ltgm_capf

    /* ------------------------------------------------------------------ */
    /*  Compute summary statistics for return values                       */
    /* ------------------------------------------------------------------ */
    local y_pc_init  = y_pc[1]
    local y_pc_final = y_pc[`nyears']
    local pov_final  = pov[`nyears']
    local ky_final   = ky[`nyears']

    * Annualised average GDP per capita growth (geometric mean)
    local avg_g_ypc = (`y_pc_final' / `y_pc_init') ^ (1 / (`nyears' - 1)) - 1

    /* ------------------------------------------------------------------ */
    /*  Save results dataset                                               */
    /* ------------------------------------------------------------------ */
    local resultsfile `"`savepath'/_ltgm_results_`scenario_lbl'.dta"'

    if "`nosave'" == "" {
        quietly save `"`resultsfile'"', replace
    }

    /* ------------------------------------------------------------------ */
    /*  Display milestone table                                            */
    /* ------------------------------------------------------------------ */
    if "`nodisplay'" == "" {
        display ""
        display as text "{hline 72}"
        display as result "  LTGM Standard Model -- Simulation Results"
        display as text "{hline 72}"
        display as text "  Country  : " as result `"`country_lbl'"'
        display as text "  Scenario : " as result "`scenario_lbl'"
        display as text "  Period   : " as result "`year0' - `horizon'"
        display as text "{hline 72}"
        display as text "  {ralign 6:Year}" ///
            "  {ralign 12:GDP/cap($)}" ///
            "  {ralign 10:GDPpc gr%}" ///
            "  {ralign 10:GDP gr%}" ///
            "  {ralign 8:K/Y}" ///
            "  {ralign 8:Pov%}"
        display as text "  {hline 66}"

        forvalues i = 1/`nyears' {
            local yr = year[`i']
            local show = 0

            * Show first year, last year, and milestone years
            if `i' == 1 {
                local show = 1
            }
            else if `i' == `nyears' {
                local show = 1
            }
            else if mod(`yr' - `year0', `milestone') == 0 {
                local show = 1
            }

            if `show' {
                local v_ypc  = y_pc[`i']
                local v_gy   = g_y[`i'] * 100
                local v_gY   = g_Y[`i'] * 100
                local v_ky   = ky[`i']
                local v_pov  = pov[`i'] * 100

                display as text "  {ralign 6:`yr'}" ///
                    as result "  {ralign 12:" %10.2fc `v_ypc' "}" ///
                    as result "  {ralign 10:" %8.3f `v_gy' "}" ///
                    as result "  {ralign 10:" %8.3f `v_gY' "}" ///
                    as result "  {ralign 8:" %6.3f `v_ky' "}" ///
                    as result "  {ralign 8:" %6.2f `v_pov' "}"
            }
        }

        display as text "  {hline 66}"
        display as text "  Avg GDPpc growth (annualised): " as result %6.3f `avg_g_ypc'*100 as text "%"
        display as text "  Final GDP per capita         : " as result "$" %12.2fc `y_pc_final'
        display as text "  Final poverty headcount      : " as result %6.2f `pov_final'*100 as text "%"
        display as text "{hline 72}"

        if "`nosave'" == "" {
            display as text "  Results saved: " as result `"`resultsfile'"'
        }
        display ""
    }

    * Leave results as the active dataset (restore was inside preserve block)
    * We need to rebuild outside preserve
    restore

    * Reload results into memory (replaces user data -- but user was warned
    * by the preserve/restore pattern inside the loop above)
    if "`nosave'" == "" {
        quietly use `"`resultsfile'"', clear
    }

    /* ------------------------------------------------------------------ */
    /*  Return values                                                      */
    /* ------------------------------------------------------------------ */
    return local  resultsfile `"`resultsfile'"'
    return local  scenario    "`scenario_lbl'"
    return local  model       "`model_lbl'"
    return local  country     `"`country_lbl'"'
    return scalar year0       = `year0'
    return scalar horizon     = `horizon'
    return scalar y_pc_final  = `y_pc_final'
    return scalar y_pc_init   = `y_pc_init'
    return scalar pov_final   = `pov_final'
    return scalar avg_g_ypc   = `avg_g_ypc'
    return scalar ky_final    = `ky_final'
    return scalar nyears      = `nyears'

end
