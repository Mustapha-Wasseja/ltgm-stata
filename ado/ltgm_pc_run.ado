*! ltgm_pc_run.ado  v1.0.0  2026-04-04
*! World Bank LTGM Stata Package -- Public Capital Model Engine
*! Dual capital stock Cobb-Douglas: Y = Kg^phi * Kp^(alpha-phi) * (A*HK*L)^(1-alpha)
*!
*! Sub-model 1: Growth given public & private investment (forward)
*! Sub-model 2: Required public investment given GDP growth target (inverse)
*!
*! Requires: Stata 13+

capture program drop ltgm_pc_run
program define ltgm_pc_run, rclass
    version 13.0

    /* ------------------------------------------------------------------ */
    /*  Syntax                                                             */
    /* ------------------------------------------------------------------ */
    syntax [, SCENario(string) SAVEPath(string)                         ///
              NOSave NODisplay MILestone(integer 5) ]

    if `"`scenario'"' == "" {
        local scenario "baseline"
    }
    if `"`savepath'"' == "" {
        local savepath `"`c(pwd)'"'
    }

    /* ------------------------------------------------------------------ */
    /*  Load parameters from setup file                                    */
    /* ------------------------------------------------------------------ */
    local paramfile `"`savepath'/_ltgm_params_`scenario'.dta"'
    capture confirm file `"`paramfile'"'
    if _rc {
        display as error "ltgm_pc_run: parameter file not found: `paramfile'"
        display as error "Run ltgm_setup first."
        exit 601
    }

    preserve
    quietly use `"`paramfile'"', clear

    * Extract all parameters into locals
    local model_lbl    = model_lbl[1]
    local country_lbl  = country_lbl[1]
    local scenario_lbl = scenario_lbl[1]
    local year0        = year0[1]
    local horizon      = horizon[1]
    local submodel     = submodel[1]
    local alpha        = alpha[1]
    local g_tfp0       = g_tfp[1]
    local g_pop0       = g_pop[1]
    local g_lfp0       = g_lfp[1]
    local y0           = y0[1]
    local climate      = climate[1]
    local povshare0    = povshare[1]
    local povelast     = povelast[1]
    local povline      = povline[1]

    * PC-specific parameters
    local phi            = phi[1]
    local pub_ky0        = pub_ky[1]
    local priv_ky0       = priv_ky[1]
    local delta_pub      = delta_pub[1]
    local delta_priv     = delta_priv[1]
    local pub_efficiency = pub_efficiency[1]
    local pub_inv0       = pub_inv[1]
    local priv_inv0      = priv_inv[1]
    local hc_growth0     = hc_growth[1]
    local g_watp0        = g_watp[1]

    * Reach-target parameters
    local s_target       = s_target[1]
    local s_year         = s_year[1]
    local gtfp_target    = gtfp_target[1]
    local gtfp_year      = gtfp_year[1]
    local gpop_target    = gpop_target[1]
    local gpop_year      = gpop_year[1]
    local glfp_target    = glfp_target[1]
    local glfp_year      = glfp_year[1]
    local pub_inv_target  = pub_inv_target[1]
    local pub_inv_year    = pub_inv_year[1]
    local priv_inv_target = priv_inv_target[1]
    local priv_inv_year   = priv_inv_year[1]
    local hc_target       = hc_target[1]
    local hc_year         = hc_year[1]
    local watp_target     = watp_target[1]
    local watp_year       = watp_year[1]
    local gdp_target      = gdp_target[1]
    local gdp_target_final = gdp_target_final[1]

    restore

    /* ------------------------------------------------------------------ */
    /*  Build output dataset                                               */
    /* ------------------------------------------------------------------ */
    local nyears = `horizon' - `year0' + 1

    * Preserve user's data; results will replace it via restore, not
    preserve
    clear
    quietly set obs `nyears'

    * Year index
    quietly generate int year = `year0' + _n - 1

    * Output variables
    quietly generate double y_pc         = .
    quietly generate double g_y          = .
    quietly generate double g_Y          = .
    quietly generate double g_ypc        = .
    quietly generate double kg_y         = .
    quietly generate double kp_y         = .
    quietly generate double pub_inv_t    = .
    quietly generate double priv_inv_t   = .
    quietly generate double total_inv_t  = .
    quietly generate double g_kg         = .
    quietly generate double g_kp         = .
    quietly generate double g_tfp_t      = .
    quietly generate double hc_growth_t  = .
    quietly generate double g_L_t        = .
    quietly generate double pov          = .
    quietly generate double avg_eff      = .

    * Labels
    quietly generate str40 scenario_lbl = "`scenario_lbl'"
    quietly generate str20 model_lbl    = "`model_lbl'"
    quietly generate str60 country_lbl  = `"`country_lbl'"'

    /* ------------------------------------------------------------------ */
    /*  Path interpolation for time-varying parameters                     */
    /* ------------------------------------------------------------------ */

    * g_tfp path
    quietly generate double _gtfp = `g_tfp0'
    if `gtfp_target' != -1 {
        quietly replace _gtfp = `g_tfp0' + (`gtfp_target' - `g_tfp0') * ///
            min(1, max(0, (year - `year0') / (`gtfp_year' - `year0')))
    }

    * g_pop path
    quietly generate double _gpop = `g_pop0'
    if `gpop_target' != -1 {
        quietly replace _gpop = `g_pop0' + (`gpop_target' - `g_pop0') * ///
            min(1, max(0, (year - `year0') / (`gpop_year' - `year0')))
    }

    * g_lfp path
    quietly generate double _glfp = `g_lfp0'
    if `glfp_target' != -1 {
        quietly replace _glfp = `g_lfp0' + (`glfp_target' - `g_lfp0') * ///
            min(1, max(0, (year - `year0') / (`glfp_year' - `year0')))
    }

    * g_watp path
    quietly generate double _gwatp = `g_watp0'
    if `watp_target' != -1 {
        quietly replace _gwatp = `g_watp0' + (`watp_target' - `g_watp0') * ///
            min(1, max(0, (year - `year0') / (`watp_year' - `year0')))
    }

    * hc_growth path
    quietly generate double _ghc = `hc_growth0'
    if `hc_target' != -1 {
        quietly replace _ghc = `hc_growth0' + (`hc_target' - `hc_growth0') * ///
            min(1, max(0, (year - `year0') / (`hc_year' - `year0')))
    }

    * public investment path
    quietly generate double _ig = `pub_inv0'
    if `pub_inv_target' != -1 {
        quietly replace _ig = `pub_inv0' + (`pub_inv_target' - `pub_inv0') * ///
            min(1, max(0, (year - `year0') / (`pub_inv_year' - `year0')))
    }

    * private investment path
    quietly generate double _ip = `priv_inv0'
    if `priv_inv_target' != -1 {
        quietly replace _ip = `priv_inv0' + (`priv_inv_target' - `priv_inv0') * ///
            min(1, max(0, (year - `year0') / (`priv_inv_year' - `year0')))
    }

    * GDP target path (for sub-model 2)
    if `gdp_target' != -1 {
        quietly generate double _gdp_tgt = `gdp_target'
        if `gdp_target_final' != -1 {
            quietly replace _gdp_tgt = `gdp_target' + (`gdp_target_final' - `gdp_target') * ///
                min(1, max(0, (_n - 1) / max(1, `nyears' - 1)))
        }
    }

    * Store time-varying params in output columns
    quietly replace g_tfp_t     = _gtfp
    quietly replace hc_growth_t = _ghc
    quietly replace pub_inv_t   = _ig
    quietly replace priv_inv_t  = _ip
    quietly replace total_inv_t = _ig + _ip

    /* ------------------------------------------------------------------ */
    /*  Simulation: Sub-model 1 (forward -- growth given investment)       */
    /* ------------------------------------------------------------------ */

    if `submodel' != 2 {

        * Initial conditions
        scalar _ltgm_kgy    = `pub_ky0'
        scalar _ltgm_kpy    = `priv_ky0'
        scalar _ltgm_ypc    = `y0'
        scalar _ltgm_pov    = `povshare0'
        scalar _ltgm_avgeff = `pub_efficiency'

        forvalues t = 1/`nyears' {

            * Read time-varying parameters
            scalar _ltgm_gtfp = _gtfp[`t']
            scalar _ltgm_gpop = _gpop[`t']
            scalar _ltgm_glfp = _glfp[`t']
            scalar _ltgm_gwtp = _gwatp[`t']
            scalar _ltgm_ghc  = _ghc[`t']
            scalar _ltgm_ig   = _ig[`t']
            scalar _ltgm_ip   = _ip[`t']

            * Apply climate damage to TFP
            scalar _ltgm_gA = _ltgm_gtfp * (1 - `climate')

            * Labour force growth: (1+g_L) = (1+g_pop)(1+g_watp)(1+g_lfp)
            scalar _ltgm_one_gL = (1 + _ltgm_gpop) * (1 + _ltgm_gwtp) * (1 + _ltgm_glfp)

            * Public capital per worker growth:
            * (1+g_kg) = ((1-delta_g) + eff*Ig_Y/Kg_Y) / (1+g_L)
            scalar _ltgm_one_gkg = ((1 - `delta_pub') + `pub_efficiency' * _ltgm_ig / _ltgm_kgy) / _ltgm_one_gL

            * Guard: capital accumulation factor must be positive
            if _ltgm_one_gkg <= 0 {
                display as error "ltgm_pc_run: public capital accumulation negative at year " year[`t']
                display as error "  Check delta_pub, pub_inv, pub_ky parameters."
                exit 499
            }

            * Private capital per worker growth:
            * (1+g_kp) = ((1-delta_p) + Ip_Y/Kp_Y) / (1+g_L)
            scalar _ltgm_one_gkp = ((1 - `delta_priv') + _ltgm_ip / _ltgm_kpy) / _ltgm_one_gL

            if _ltgm_one_gkp <= 0 {
                display as error "ltgm_pc_run: private capital accumulation negative at year " year[`t']
                display as error "  Check delta_priv, priv_inv, priv_ky parameters."
                exit 499
            }

            * GDP per worker growth (exact Cobb-Douglas):
            * (1+g_y) = (1+g_kg)^phi * (1+g_kp)^(alpha-phi) * ((1+g_A)(1+g_HK))^(1-alpha)
            scalar _ltgm_one_gy = _ltgm_one_gkg^`phi' * _ltgm_one_gkp^(`alpha' - `phi') * ///
                ((1 + _ltgm_gA) * (1 + _ltgm_ghc))^(1 - `alpha')

            * GDP per capita growth: (1+g_ypc) = (1+g_y)(1+g_watp)(1+g_lfp)
            scalar _ltgm_gypc = _ltgm_one_gy * (1 + _ltgm_gwtp) * (1 + _ltgm_glfp) - 1

            * Aggregate GDP growth: (1+g_Y) = (1+g_y)(1+g_L)
            scalar _ltgm_gY = _ltgm_one_gy * _ltgm_one_gL - 1

            * Public capital growth: (1+g_Kg) = (1+g_kg)(1+g_L)
            scalar _ltgm_gKg = _ltgm_one_gkg * _ltgm_one_gL - 1

            * Private capital growth: (1+g_Kp) = (1+g_kp)(1+g_L)
            scalar _ltgm_gKp = _ltgm_one_gkp * _ltgm_one_gL - 1

            * Store results
            quietly replace kg_y  = _ltgm_kgy    in `t'
            quietly replace kp_y  = _ltgm_kpy    in `t'
            quietly replace g_kg  = _ltgm_one_gkg - 1 in `t'
            quietly replace g_kp  = _ltgm_one_gkp - 1 in `t'
            quietly replace g_y   = _ltgm_one_gy - 1   in `t'
            quietly replace g_ypc = _ltgm_gypc   in `t'
            quietly replace g_Y   = _ltgm_gY     in `t'
            quietly replace avg_eff = _ltgm_avgeff in `t'

            * Update GDP per capita level
            if `t' == 1 {
                quietly replace y_pc = `y0' in 1
            }
            else {
                quietly replace y_pc = _ltgm_ypc * (1 + _ltgm_gypc) in `t'
                scalar _ltgm_ypc = _ltgm_ypc * (1 + _ltgm_gypc)
            }

            * Poverty update
            if `t' == 1 {
                quietly replace pov = `povshare0' in 1
            }
            else {
                scalar _ltgm_pov_new = _ltgm_pov * (1 + `povelast' * _ltgm_gypc)
                scalar _ltgm_pov_new = max(0, min(1, _ltgm_pov_new))
                quietly replace pov = _ltgm_pov_new in `t'
                scalar _ltgm_pov = _ltgm_pov_new
            }

            * Labour force growth for display
            quietly replace g_L_t = _ltgm_one_gL - 1 in `t'

            * Update K/Y ratios for next period
            if `t' < `nyears' {
                scalar _ltgm_kgy = _ltgm_kgy * (1 + _ltgm_gKg) / (1 + _ltgm_gY)
                scalar _ltgm_kpy = _ltgm_kpy * (1 + _ltgm_gKp) / (1 + _ltgm_gY)
            }

            * Update average efficiency of public capital stock
            if `t' < `nyears' {
                scalar _ltgm_new_share = `pub_efficiency' * _ltgm_ig / (_ltgm_kgy * (1 + _ltgm_gY))
                if _ltgm_new_share > 1 {
                    scalar _ltgm_new_share = 1
                }
                scalar _ltgm_old_share = 1 - _ltgm_new_share
                scalar _ltgm_avgeff = _ltgm_old_share * _ltgm_avgeff * (1 - `delta_pub') / ///
                    (1 + _ltgm_gKg) + _ltgm_new_share * `pub_efficiency'
                scalar _ltgm_avgeff = max(0, min(1, _ltgm_avgeff))
            }
        }
    }

    /* ------------------------------------------------------------------ */
    /*  Simulation: Sub-model 2 (inverse -- required public investment)    */
    /* ------------------------------------------------------------------ */

    else {

        * Validate: GDP target must be specified
        if `gdp_target' == -1 {
            display as error "ltgm_pc_run: sub-model 2 requires gdp_target()"
            display as error "  Specify the target GDP per capita growth rate."
            exit 198
        }

        scalar _ltgm_kgy = `pub_ky0'
        scalar _ltgm_kpy = `priv_ky0'
        scalar _ltgm_ypc = `y0'
        scalar _ltgm_pov = `povshare0'

        * Set avg_eff to constant for submodel 2 (no efficiency tracking)
        quietly replace avg_eff = `pub_efficiency'

        forvalues t = 1/`nyears' {

            * Read time-varying parameters
            scalar _ltgm_gpop = _gpop[`t']
            scalar _ltgm_glfp = _glfp[`t']
            scalar _ltgm_gwtp = _gwatp[`t']
            scalar _ltgm_ghc  = _ghc[`t']
            scalar _ltgm_gtfp = _gtfp[`t']
            scalar _ltgm_ip   = _ip[`t']

            * Apply climate damage
            scalar _ltgm_gA = _ltgm_gtfp * (1 - `climate')

            * Labour force growth
            scalar _ltgm_one_gL = (1 + _ltgm_gpop) * (1 + _ltgm_gwtp) * (1 + _ltgm_glfp)

            * Target GDP per capita growth
            scalar _ltgm_gypc = _gdp_tgt[`t']

            * GDP per worker growth: (1+g_y) = (1+g_ypc)/((1+g_watp)(1+g_lfp))
            scalar _ltgm_one_gy = (1 + _ltgm_gypc) / ((1 + _ltgm_gwtp) * (1 + _ltgm_glfp))

            * Aggregate GDP growth: (1+g_Y) = (1+g_y)(1+g_L)
            scalar _ltgm_gY = _ltgm_one_gy * _ltgm_one_gL - 1

            * Private capital per worker growth
            scalar _ltgm_one_gkp = ((1 - `delta_priv') + _ltgm_ip / _ltgm_kpy) / _ltgm_one_gL
            scalar _ltgm_gKp = _ltgm_one_gkp * _ltgm_one_gL - 1

            * Required public capital per worker growth (invert Cobb-Douglas):
            * (1+g_y) = (1+g_kg)^phi * (1+g_kp)^(alpha-phi) * ((1+gA)(1+gHK))^(1-alpha)
            * => (1+g_kg)^phi = (1+g_y) / ((1+g_kp)^(alpha-phi) * ((1+gA)(1+gHK))^(1-alpha))
            * => (1+g_kg) = [ratio]^(1/phi)
            scalar _ltgm_ratio = _ltgm_one_gy / ///
                (_ltgm_one_gkp^(`alpha' - `phi') * ///
                ((1 + _ltgm_gA) * (1 + _ltgm_ghc))^(1 - `alpha'))

            if _ltgm_ratio <= 0 {
                display as error "ltgm_pc_run: infeasible target at year " year[`t']
                display as error "  Required public capital growth would be negative."
                exit 499
            }

            scalar _ltgm_one_gkg = _ltgm_ratio^(1 / `phi')
            scalar _ltgm_gKg = _ltgm_one_gkg * _ltgm_one_gL - 1

            * Required public investment/GDP (invert capital accumulation):
            * (1+g_kg) = ((1-delta_g) + eff*Ig/KgY) / (1+g_L)
            * => eff*Ig/KgY = (1+g_kg)(1+g_L) - (1-delta_g)
            * => Ig/Y = ((1+g_kg)(1+g_L) - (1-delta_g)) * KgY / eff
            scalar _ltgm_req_ig = (_ltgm_one_gkg * _ltgm_one_gL - (1 - `delta_pub')) * ///
                _ltgm_kgy / `pub_efficiency'

            * Store results
            quietly replace kg_y      = _ltgm_kgy           in `t'
            quietly replace kp_y      = _ltgm_kpy           in `t'
            quietly replace g_kg      = _ltgm_one_gkg - 1   in `t'
            quietly replace g_kp      = _ltgm_one_gkp - 1   in `t'
            quietly replace g_y       = _ltgm_one_gy - 1    in `t'
            quietly replace g_ypc     = _ltgm_gypc           in `t'
            quietly replace g_Y       = _ltgm_gY             in `t'
            quietly replace pub_inv_t = _ltgm_req_ig         in `t'
            quietly replace total_inv_t = _ltgm_req_ig + _ltgm_ip in `t'
            quietly replace g_L_t     = _ltgm_one_gL - 1    in `t'

            * Update GDP per capita level
            if `t' == 1 {
                quietly replace y_pc = `y0' in 1
            }
            else {
                quietly replace y_pc = _ltgm_ypc * (1 + _ltgm_gypc) in `t'
                scalar _ltgm_ypc = _ltgm_ypc * (1 + _ltgm_gypc)
            }

            * Poverty update
            if `t' == 1 {
                quietly replace pov = `povshare0' in 1
            }
            else {
                scalar _ltgm_pov_new = _ltgm_pov * (1 + `povelast' * _ltgm_gypc)
                scalar _ltgm_pov_new = max(0, min(1, _ltgm_pov_new))
                quietly replace pov = _ltgm_pov_new in `t'
                scalar _ltgm_pov = _ltgm_pov_new
            }

            * Update K/Y ratios for next period
            if `t' < `nyears' {
                scalar _ltgm_kgy = _ltgm_kgy * (1 + _ltgm_gKg) / (1 + _ltgm_gY)
                scalar _ltgm_kpy = _ltgm_kpy * (1 + _ltgm_gKp) / (1 + _ltgm_gY)
            }
        }
    }

    /* ------------------------------------------------------------------ */
    /*  Drop temporary variables                                           */
    /* ------------------------------------------------------------------ */
    capture drop _gtfp _gpop _glfp _gwatp _ghc _ig _ip
    capture drop _gdp_tgt

    /* ------------------------------------------------------------------ */
    /*  Summary statistics                                                 */
    /* ------------------------------------------------------------------ */
    scalar _ltgm_y_init  = y_pc[1]
    scalar _ltgm_y_final = y_pc[`nyears']
    scalar _ltgm_p_final = pov[`nyears']
    scalar _ltgm_kg_final = kg_y[`nyears']
    scalar _ltgm_kp_final = kp_y[`nyears']
    scalar _ltgm_avg_gypc = (_ltgm_y_final / _ltgm_y_init)^(1 / (`nyears' - 1)) - 1

    /* ------------------------------------------------------------------ */
    /*  Display milestone table                                            */
    /* ------------------------------------------------------------------ */
    if "`nodisplay'" == "" {
        display ""
        display as text "{hline 90}"
        display as result "  LTGM Public Capital Model -- `country_lbl' -- `scenario_lbl'"
        if `submodel' == 2 {
            display as result "  Sub-model 2: Required Public Investment"
        }
        display as text "{hline 90}"
        display as text "  {ralign 6:Year}" ///
            "  {ralign 10:GDP/cap}" ///
            "  {ralign 8:g(ypc)}" ///
            "  {ralign 8:Kg/Y}" ///
            "  {ralign 8:Kp/Y}" ///
            "  {ralign 8:Ig/Y}" ///
            "  {ralign 8:Ip/Y}" ///
            "  {ralign 8:Poverty}" ///
            "  {ralign 8:Effic.}"
        display as text "  {hline 86}"

        forvalues t = 1/`nyears' {
            local yr = year[`t']
            local show = 0
            if `t' == 1 {
                local show = 1
            }
            if `t' == `nyears' {
                local show = 1
            }
            if `milestone' > 0 {
                if mod(`yr' - `year0', `milestone') == 0 {
                    local show = 1
                }
            }

            if `show' {
                local v_ypc  : display %10.2fc y_pc[`t']
                local v_gypc : display %7.2f g_ypc[`t'] * 100
                local v_kgy  : display %7.3f kg_y[`t']
                local v_kpy  : display %7.3f kp_y[`t']
                local v_ig   : display %7.2f pub_inv_t[`t'] * 100
                local v_ip   : display %7.2f priv_inv_t[`t'] * 100
                local v_pov  : display %7.2f pov[`t'] * 100
                local v_eff  : display %7.2f avg_eff[`t'] * 100

                display as text "  {ralign 6:`yr'}" ///
                    as result "  {ralign 10:`v_ypc'}" ///
                    as result "  {ralign 8:`v_gypc'%}" ///
                    as result "  {ralign 8:`v_kgy'}" ///
                    as result "  {ralign 8:`v_kpy'}" ///
                    as result "  {ralign 8:`v_ig'%}" ///
                    as result "  {ralign 8:`v_ip'%}" ///
                    as result "  {ralign 8:`v_pov'%}" ///
                    as result "  {ralign 8:`v_eff'%}"
            }
        }

        display as text "  {hline 86}"
        display ""
        local avg_fmt : display %6.2f _ltgm_avg_gypc * 100
        display as text "  Average GDP/cap growth : " as result "`avg_fmt'% per year"
        display as text "  Final GDP/cap          : " as result "$" %12.2fc _ltgm_y_final
        display as text "  Final poverty rate     : " as result %6.2f _ltgm_p_final * 100 "%"
        display as text "  Final Kg/Y             : " as result %6.3f _ltgm_kg_final
        display as text "  Final Kp/Y             : " as result %6.3f _ltgm_kp_final
        display as text "{hline 90}"
        display ""
    }

    /* ------------------------------------------------------------------ */
    /*  Save results and leave in memory                                   */
    /* ------------------------------------------------------------------ */
    local resultsfile `"`savepath'/_ltgm_results_`scenario_lbl'.dta"'

    if "`nosave'" == "" {
        quietly save `"`resultsfile'"', replace
    }

    * Break out of preserve to leave results in memory for the user
    restore, not

    /* ------------------------------------------------------------------ */
    /*  Return values                                                      */
    /* ------------------------------------------------------------------ */
    return local  resultsfile `"`resultsfile'"'
    return local  scenario    "`scenario_lbl'"
    return local  model       "`model_lbl'"
    return local  country     `"`country_lbl'"'
    return scalar year0       = `year0'
    return scalar horizon     = `horizon'
    return scalar y_pc_init   = _ltgm_y_init
    return scalar y_pc_final  = _ltgm_y_final
    return scalar pov_final   = _ltgm_p_final
    return scalar avg_g_ypc   = _ltgm_avg_gypc
    return scalar kg_y_final  = _ltgm_kg_final
    return scalar kp_y_final  = _ltgm_kp_final
    return scalar nyears      = `nyears'

end
