*! ltgm_setup.ado  v2.0.0  2026-04-01
*! World Bank LTGM Stata Package -- Standard Model Setup
*! Sets up country parameters and writes a parameter dataset for ltgm_run
*! v2: Added auto-fill from bundled country data via ltgm_import
*!
*! Authors: Mustapha Wasseja / World Bank LTGM Team
*! Requires: Stata 13+

capture program drop ltgm_setup
program define ltgm_setup, rclass
    version 13.0

    /* ------------------------------------------------------------------ */
    /*  Syntax                                                             */
    /*  NOTE: We use -999 as sentinel defaults for numeric parameters.     */
    /*  If the user does not specify a value, the sentinel remains and     */
    /*  gets replaced by auto-fill data or hardcoded fallback defaults.    */
    /*  This is necessary because Stata's syntax command cannot            */
    /*  distinguish "user typed s(0.20)" from "default 0.20 applied".     */
    /* ------------------------------------------------------------------ */
    syntax , Model(string)                          ///
        [ Country(string)                           ///
          SCENario(string)                          ///
          YEAR0(integer 2020)                       ///
          HORizon(integer 2050)                     ///
          SUBmodel(integer 1)                       ///
          ALpha(real -999)                          ///
          S(real -999)                              ///
          DELta(real -999)                          ///
          G_tfp(real -999)                          ///
          G_pop(real -999)                          ///
          G_lfp(real -999)                          ///
          G_lfp_m(real -999)                        ///
          G_lfp_f(real -999)                        ///
          MALE_share(real -999)                     ///
          KY0(real -999)                            ///
          Y0(real -999)                             ///
          CLImate(real 0)                           ///
          POVshare(real -999)                       ///
          POVelast(real -2.0)                       ///
          POVline(real 2.15)                        ///
          S_target(real -1)                         ///
          S_year(integer -1)                        ///
          GTFP_target(real -1)                      ///
          GTFP_year(integer -1)                     ///
          GPOP_target(real -1)                      ///
          GPOP_year(integer -1)                     ///
          GLFP_target(real -1)                      ///
          GLFP_year(integer -1)                     ///
          SAVEPath(string)                          ///
          DATASource(string)                        ///
          NOAUTOfill                                ///
        ]

    /* ------------------------------------------------------------------ */
    /*  Model validation                                                   */
    /* ------------------------------------------------------------------ */
    if `"`model'"' != "standard" {
        display as error "ltgm_setup: only model(standard) is supported in this version"
        exit 198
    }

    if `"`scenario'"' == "" {
        local scenario "baseline"
    }

    if `"`country'"' == "" {
        local country "Custom"
    }

    if `"`savepath'"' == "" {
        local savepath `"`c(pwd)'"'
    }

    if `"`datasource'"' == "" {
        local datasource "bundled"
    }

    /* ------------------------------------------------------------------ */
    /*  Track which parameters the user explicitly set                     */
    /*  A value of -999 means "not specified by user"                      */
    /* ------------------------------------------------------------------ */
    local user_set_alpha    = (`alpha'      != -999)
    local user_set_s        = (`s'          != -999)
    local user_set_delta    = (`delta'      != -999)
    local user_set_g_tfp    = (`g_tfp'      != -999)
    local user_set_g_pop    = (`g_pop'      != -999)
    local user_set_g_lfp    = (`g_lfp'      != -999)
    local user_set_g_lfp_m  = (`g_lfp_m'    != -999)
    local user_set_g_lfp_f  = (`g_lfp_f'    != -999)
    local user_set_male_share = (`male_share' != -999)
    local user_set_ky0      = (`ky0'        != -999)
    local user_set_y0       = (`y0'         != -999)
    local user_set_povshare = (`povshare'   != -999)

    /* ------------------------------------------------------------------ */
    /*  AUTO-FILL from bundled data (if country specified and not Custom)  */
    /* ------------------------------------------------------------------ */
    local autofill_used = 0
    local autofill_note ""
    local data_year = .

    local _do_autofill = 0
    if `"`country'"' != "Custom" {
        if "`noautofill'" == "" {
            if "`datasource'" != "none" {
                local _do_autofill = 1
            }
        }
    }

    if `_do_autofill' {

        * Try to call ltgm_import -- capture in case data not available
        capture ltgm_import, country(`"`country'"') year0(`year0')
        local _import_rc = _rc

        * Extract r() values into locals immediately (they vanish quickly)
        local _af_found     = 0
        local _af_cname     ""
        local _af_dyear     = .
        local _af_y0        = .
        local _af_s         = .
        local _af_delta     = .
        local _af_alpha     = .
        local _af_ky0       = .
        local _af_g_tfp     = .
        local _af_g_pop     = .
        local _af_g_lfp     = .
        local _af_g_lfp_m   = .
        local _af_g_lfp_f   = .
        local _af_povshare  = .

        if `_import_rc' == 0 {
            capture local _af_found = r(found)
            if `_af_found' > 0 {
                local _af_cname  `"`r(country_name)'"'
                local _af_dyear  = r(data_year)
                local _af_y0     = r(y0)
                local _af_s      = r(s)
                local _af_delta  = r(delta)
                local _af_alpha  = r(alpha)
                local _af_ky0    = r(ky0)
                local _af_g_tfp  = r(g_tfp)
                local _af_g_pop  = r(g_pop)
                local _af_g_lfp  = r(g_lfp)
                local _af_g_lfp_m = r(g_lfp_m)
                local _af_g_lfp_f = r(g_lfp_f)
                local _af_povshare = r(povshare)
            }
        }

        if `_af_found' > 0 {
            local autofill_used = 1
            local country `"`_af_cname'"'
            local data_year = `_af_dyear'

            * Fill each parameter IF user did not explicitly set it
            * AND the data value is not missing (. in Stata)
            if !`user_set_y0' {
                if `_af_y0' < . {
                    local y0 = `_af_y0'
                }
            }
            if !`user_set_s' {
                if `_af_s' < . {
                    local s = `_af_s'
                }
            }
            if !`user_set_delta' {
                if `_af_delta' < . {
                    local delta = `_af_delta'
                }
            }
            if !`user_set_alpha' {
                if `_af_alpha' < . {
                    local alpha = `_af_alpha'
                }
            }
            if !`user_set_ky0' {
                if `_af_ky0' < . {
                    local ky0 = `_af_ky0'
                }
            }
            if !`user_set_g_tfp' {
                if `_af_g_tfp' < . {
                    local g_tfp = `_af_g_tfp'
                }
            }
            if !`user_set_g_pop' {
                if `_af_g_pop' < . {
                    local g_pop = `_af_g_pop'
                }
            }
            if !`user_set_g_lfp' {
                if `_af_g_lfp' < . {
                    local g_lfp = `_af_g_lfp'
                }
            }
            if !`user_set_g_lfp_m' {
                if `_af_g_lfp_m' < . {
                    local g_lfp_m = `_af_g_lfp_m'
                }
            }
            if !`user_set_g_lfp_f' {
                if `_af_g_lfp_f' < . {
                    local g_lfp_f = `_af_g_lfp_f'
                }
            }
            if !`user_set_povshare' {
                if `_af_povshare' < . {
                    local povshare = `_af_povshare'
                }
            }
        }
        else {
            * Country not found -- warn but continue with manual values
            display as text ""
            display as text "  Warning: country '`country'' not found in bundled data."
            display as text "  Using manually specified or default parameter values."
            display as text "  Use ltgm_countries to list available countries."
            display as text ""
        }
    }

    /* ------------------------------------------------------------------ */
    /*  Apply hardcoded fallback defaults for any still-sentinel values    */
    /* ------------------------------------------------------------------ */
    if `alpha'      == -999 {
        local alpha      = 0.35
    }
    if `s'          == -999 {
        local s          = 0.20
    }
    if `delta'      == -999 {
        local delta      = 0.05
    }
    if `g_tfp'      == -999 {
        local g_tfp      = 0.01
    }
    if `g_pop'      == -999 {
        local g_pop      = 0.02
    }
    if `g_lfp'      == -999 {
        local g_lfp      = 0
    }
    if `g_lfp_m'    == -999 {
        local g_lfp_m    = 0
    }
    if `g_lfp_f'    == -999 {
        local g_lfp_f    = 0
    }
    if `male_share' == -999 {
        local male_share = 0.5
    }
    if `ky0'        == -999 {
        local ky0        = 2.5
    }
    if `y0'         == -999 {
        local y0         = 1000
    }
    if `povshare'   == -999 {
        local povshare   = 0.40
    }

    /* ------------------------------------------------------------------ */
    /*  Validation                                                         */
    /* ------------------------------------------------------------------ */

    * alpha strictly in (0,1)
    if `alpha' <= 0 | `alpha' >= 1 {
        display as error "ltgm_setup: alpha must be strictly between 0 and 1; got `alpha'"
        exit 198
    }

    * s in (0,1)
    if `s' <= 0 | `s' >= 1 {
        display as error "ltgm_setup: savings rate s must be strictly between 0 and 1; got `s'"
        exit 198
    }

    * delta in (0,1)
    if `delta' <= 0 | `delta' >= 1 {
        display as error "ltgm_setup: depreciation delta must be strictly between 0 and 1; got `delta'"
        exit 198
    }

    * ky0 > 0
    if `ky0' <= 0 {
        display as error "ltgm_setup: initial K/Y ratio ky0 must be positive; got `ky0'"
        exit 198
    }

    * y0 > 0
    if `y0' <= 0 {
        display as error "ltgm_setup: initial GDP per capita y0 must be positive; got `y0'"
        exit 198
    }

    * year0 < horizon
    if `year0' >= `horizon' {
        display as error "ltgm_setup: year0 (`year0') must be strictly less than horizon (`horizon')"
        exit 198
    }

    * climate in [0,1]
    if `climate' < 0 | `climate' > 1 {
        display as error "ltgm_setup: climate damage factor must be in [0,1]; got `climate'"
        exit 198
    }

    * submodel in {1,2,3}
    if !inlist(`submodel', 1, 2, 3) {
        display as error "ltgm_setup: submodel must be 1, 2, or 3; got `submodel'"
        exit 198
    }

    * Reach-target year validation
    if `s_target' != -1 {
        if `s_year' == -1 {
            display as error "ltgm_setup: s_target specified but s_year not set"
            exit 198
        }
        if `s_year' <= `year0' | `s_year' > `horizon' {
            display as error "ltgm_setup: s_year must be in (`year0', `horizon']; got `s_year'"
            exit 198
        }
    }

    if `gtfp_target' != -1 {
        if `gtfp_year' == -1 {
            display as error "ltgm_setup: gtfp_target specified but gtfp_year not set"
            exit 198
        }
        if `gtfp_year' <= `year0' | `gtfp_year' > `horizon' {
            display as error "ltgm_setup: gtfp_year must be in (`year0', `horizon']; got `gtfp_year'"
            exit 198
        }
    }

    if `gpop_target' != -1 {
        if `gpop_year' == -1 {
            display as error "ltgm_setup: gpop_target specified but gpop_year not set"
            exit 198
        }
        if `gpop_year' <= `year0' | `gpop_year' > `horizon' {
            display as error "ltgm_setup: gpop_year must be in (`year0', `horizon']; got `gpop_year'"
            exit 198
        }
    }

    if `glfp_target' != -1 {
        if `glfp_year' == -1 {
            display as error "ltgm_setup: glfp_target specified but glfp_year not set"
            exit 198
        }
        if `glfp_year' <= `year0' | `glfp_year' > `horizon' {
            display as error "ltgm_setup: glfp_year must be in (`year0', `horizon']; got `glfp_year'"
            exit 198
        }
    }

    /* ------------------------------------------------------------------ */
    /*  Build parameter dataset (1 observation)                            */
    /* ------------------------------------------------------------------ */
    preserve
    clear
    quietly set obs 1

    quietly generate str20 model_lbl   = "`model'"
    quietly generate str60 country_lbl = `"`country'"'
    quietly generate str40 scenario_lbl = "`scenario'"

    quietly generate int year0    = `year0'
    quietly generate int horizon  = `horizon'
    quietly generate int submodel = `submodel'

    quietly generate double alpha      = `alpha'
    quietly generate double s          = `s'
    quietly generate double delta      = `delta'
    quietly generate double g_tfp      = `g_tfp'
    quietly generate double g_pop      = `g_pop'
    quietly generate double g_lfp      = `g_lfp'
    quietly generate double g_lfp_m    = `g_lfp_m'
    quietly generate double g_lfp_f    = `g_lfp_f'
    quietly generate double male_share = `male_share'
    quietly generate double ky0        = `ky0'
    quietly generate double y0         = `y0'
    quietly generate double climate    = `climate'

    quietly generate double povshare   = `povshare'
    quietly generate double povelast   = `povelast'
    quietly generate double povline    = `povline'

    quietly generate double s_target    = `s_target'
    quietly generate int    s_year      = `s_year'
    quietly generate double gtfp_target = `gtfp_target'
    quietly generate int    gtfp_year   = `gtfp_year'
    quietly generate double gpop_target = `gpop_target'
    quietly generate int    gpop_year   = `gpop_year'
    quietly generate double glfp_target = `glfp_target'
    quietly generate int    glfp_year   = `glfp_year'

    local paramfile `"`savepath'/_ltgm_params_`scenario'.dta"'
    quietly save `"`paramfile'"', replace
    restore

    /* ------------------------------------------------------------------ */
    /*  Display parameter summary                                          */
    /* ------------------------------------------------------------------ */
    display ""
    display as text "{hline 60}"
    display as result "  LTGM Standard Model - Parameter Setup"
    display as text "{hline 60}"
    display as text "  Country        : " as result `"`country'"'
    display as text "  Scenario       : " as result "`scenario'"
    display as text "  Sub-model      : " as result "`submodel'"
    display as text "  Period         : " as result "`year0' - `horizon'"
    local nyears = `horizon' - `year0' + 1
    display as text "  Years          : " as result "`nyears'"

    * Show auto-fill summary if data was used
    if `autofill_used' {
        display as text "{hline 60}"
        display as text "  Data source    : " as result "bundled (`data_year')"
        display as text ""
        display as text "  Auto-filled from bundled data:"

        * Helper macro for source tag
        local tag_y0  "[data]"
        local tag_s   "[data]"
        local tag_del "[data]"
        local tag_alp "[data]"
        local tag_ky  "[data]"
        local tag_tfp "[data]"
        local tag_pop "[data]"
        local tag_pov "[data]"
        if `user_set_y0' {
            local tag_y0  "[user]"
        }
        if `user_set_s' {
            local tag_s   "[user]"
        }
        if `user_set_delta' {
            local tag_del "[user]"
        }
        if `user_set_alpha' {
            local tag_alp "[user]"
        }
        if `user_set_ky0' {
            local tag_ky  "[user]"
        }
        if `user_set_g_tfp' {
            local tag_tfp "[user]"
        }
        if `user_set_g_pop' {
            local tag_pop "[user]"
        }
        if `user_set_povshare' {
            local tag_pov "[user]"
        }

        display as text "    y0      : " as result "$" %10.2fc `y0' as text "  `tag_y0'"
        display as text "    s       : " as result %8.4f `s' as text "  `tag_s'"
        display as text "    delta   : " as result %8.4f `delta' as text "  `tag_del'"
        display as text "    alpha   : " as result %8.4f `alpha' as text "  `tag_alp'"
        display as text "    ky0     : " as result %8.3f `ky0' as text "  `tag_ky'"
        display as text "    g_tfp   : " as result %8.4f `g_tfp' as text "  `tag_tfp'"
        display as text "    g_pop   : " as result %8.4f `g_pop' as text "  `tag_pop'"
        display as text "    povshare: " as result %8.4f `povshare' as text "  `tag_pov'"

        * Show overrides
        local has_override = 0
        foreach p in y0 s delta alpha ky0 g_tfp g_pop povshare {
            if `user_set_`p'' {
                if !`has_override' {
                    display ""
                    display as text "  Overridden by user:"
                    local has_override = 1
                }
                display as result "    `p'" as text " specified on command line"
            }
        }
    }

    display as text "{hline 60}"
    display as text "  Production parameters"
    display as text "    Capital share (alpha)    : " as result %6.4f `alpha'
    display as text "    Depreciation (delta)     : " as result %6.4f `delta' as text " (" as result %5.2f `delta'*100 as text "%)"
    display as text "    Initial K/Y ratio        : " as result %6.3f `ky0'
    display as text "    Initial GDP/cap (y0)     : " as result "$" %12.2fc `y0'
    display as text "{hline 60}"
    display as text "  Growth rates (annualised)"
    display as text "    Savings rate (s)         : " as result %6.4f `s' as text " (" as result %5.2f `s'*100 as text "%)"

    if `s_target' != -1 {
        display as text "      -> target s            : " as result %6.4f `s_target' as text " by " as result `s_year'
    }

    display as text "    TFP growth (g_tfp)       : " as result %6.4f `g_tfp' as text " (" as result %5.2f `g_tfp'*100 as text "%)"

    if `gtfp_target' != -1 {
        display as text "      -> target g_tfp        : " as result %6.4f `gtfp_target' as text " by " as result `gtfp_year'
    }

    display as text "    Population growth (g_pop): " as result %6.4f `g_pop' as text " (" as result %5.2f `g_pop'*100 as text "%)"

    if `gpop_target' != -1 {
        display as text "      -> target g_pop        : " as result %6.4f `gpop_target' as text " by " as result `gpop_year'
    }

    if `submodel' == 1 {
        display as text "    LFP growth (g_lfp)       : " as result %6.4f `g_lfp' as text " (" as result %5.2f `g_lfp'*100 as text "%)"
        if `glfp_target' != -1 {
            display as text "      -> target g_lfp        : " as result %6.4f `glfp_target' as text " by " as result `glfp_year'
        }
    }
    else if `submodel' == 2 {
        display as text "    Male LFP growth          : " as result %6.4f `g_lfp_m' as text " (" as result %5.2f `g_lfp_m'*100 as text "%)"
        display as text "    Female LFP growth        : " as result %6.4f `g_lfp_f' as text " (" as result %5.2f `g_lfp_f'*100 as text "%)"
        display as text "    Male share               : " as result %6.4f `male_share'
    }

    if `climate' > 0 {
        display as text "{hline 60}"
        display as text "  Climate damage"
        display as text "    Damage factor            : " as result %6.4f `climate' as text " (" as result %5.2f `climate'*100 as text "%)"
        local g_A_eff = `g_tfp' * (1 - `climate')
        display as text "    Effective g_A            : " as result %6.4f `g_A_eff' as text " (" as result %5.2f `g_A_eff'*100 as text "%)"
    }

    display as text "{hline 60}"
    display as text "  Poverty"
    display as text "    Headcount share          : " as result %6.4f `povshare' as text " (" as result %5.2f `povshare'*100 as text "%)"
    display as text "    Elasticity               : " as result %6.2f `povelast'
    display as text "    Poverty line             : " as result "$" %5.2f `povline' as text "/day"
    display as text "{hline 60}"
    display as text "  Parameter file : " as result `"`paramfile'"'
    display as text "{hline 60}"
    display ""

    /* ------------------------------------------------------------------ */
    /*  Return values                                                      */
    /* ------------------------------------------------------------------ */
    return local  paramfile  `"`paramfile'"'
    return local  model      "`model'"
    return local  country    `"`country'"'
    return local  scenario   "`scenario'"
    return scalar year0      = `year0'
    return scalar horizon    = `horizon'
    return scalar alpha      = `alpha'
    return scalar s          = `s'
    return scalar delta      = `delta'
    return scalar g_tfp      = `g_tfp'
    return scalar g_pop      = `g_pop'
    return scalar ky0        = `ky0'
    return scalar y0         = `y0'
    return scalar climate    = `climate'
    return scalar povshare   = `povshare'
    return scalar povelast   = `povelast'

end
