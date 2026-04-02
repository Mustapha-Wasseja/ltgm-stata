*! ltgm_import.ado  v1.0.0  2026-04-01
*! World Bank LTGM Stata Package -- Import Country Parameters
*! Loads bundled country dataset and returns parameters for a given country
*!
*! Authors: Mustapha Wasseja / World Bank LTGM Team
*! Requires: Stata 13+

capture program drop ltgm_import
program define ltgm_import, rclass
    version 13.0

    /* ------------------------------------------------------------------ */
    /*  Syntax                                                             */
    /* ------------------------------------------------------------------ */
    syntax , Country(string) [ YEAR0(integer 2022) DATAPath(string)    ///
             LIST NOISY ]

    /* ------------------------------------------------------------------ */
    /*  Locate the data file                                               */
    /* ------------------------------------------------------------------ */
    local dtafile ""

    if `"`datapath'"' != "" {
        * User supplied explicit path
        local dtafile `"`datapath'/ltgm_country_data.dta"'
    }

    if `"`dtafile'"' == "" {
        * Primary: locate alongside the installed ado file via findfile
        capture quietly findfile ltgm_import.ado
        if _rc == 0 {
            local ado_dir = subinstr(r(fn), "ltgm_import.ado", "", .)
            capture confirm file `"`ado_dir'ltgm_country_data.dta"'
            if _rc == 0 {
                local dtafile `"`ado_dir'ltgm_country_data.dta"'
            }
        }
    }

    if `"`dtafile'"' == "" {
        * Fallback 1: PLUS ado directory (l/ subdirectory for net install)
        local plus_l `"`c(sysdir_plus)'l/"'
        capture confirm file `"`plus_l'ltgm_country_data.dta"'
        if _rc == 0 {
            local dtafile `"`plus_l'ltgm_country_data.dta"'
        }
    }

    if `"`dtafile'"' == "" {
        * Fallback 2: current working directory data/ subfolder (dev/manual)
        local datapath `"`c(pwd)'/data"'
        capture confirm file `"`datapath'/ltgm_country_data.dta"'
        if _rc == 0 {
            local dtafile `"`datapath'/ltgm_country_data.dta"'
        }
    }

    if `"`dtafile'"' == "" {
        * Fallback 3: one level up (running from ado/ or tests/)
        local datapath_up `"`c(pwd)'/../data"'
        capture confirm file `"`datapath_up'/ltgm_country_data.dta"'
        if _rc == 0 {
            local dtafile `"`datapath_up'/ltgm_country_data.dta"'
        }
    }

    if `"`dtafile'"' == "" {
        * Fallback 4: auto-download from GitHub via copy (Stata 14+ only)
        * Fires when net install skipped the binary, or when manually added adopath
        * Downloads once; subsequent calls find the file in the ado directory
        capture quietly findfile ltgm_import.ado
        if _rc == 0 {
            local ado_dir = subinstr(r(fn), "ltgm_import.ado", "", .)
            local dest `"`ado_dir'ltgm_country_data.dta"'
            local url "https://raw.githubusercontent.com/Mustapha-Wasseja/ltgm-stata/main/ado/ltgm_country_data.dta"
            display as text "  Note: ltgm_country_data.dta not found -- downloading from GitHub..."
            capture copy "`url'" `"`dest'"', replace
            if _rc == 0 {
                capture confirm file `"`dest'"'
                if _rc == 0 {
                    local dtafile `"`dest'"'
                    display as result "  Download complete. File saved to: `dest'"
                }
            }
            else {
                display as text "  Auto-download failed (rc=" _rc "). See manual install instructions below."
            }
        }
    }

    if `"`dtafile'"' == "" {
        display as error "ltgm_import: cannot find ltgm_country_data.dta"
        display as error ""
        display as text "  To fix this, choose one option:"
        display as text ""
        display as text "  Option 1 -- Stata 14+, re-install via net install:"
        display as text `"    net install ltgm, from("https://raw.githubusercontent.com/Mustapha-Wasseja/ltgm-stata/main/ado/") replace"'
        display as text ""
        display as text "  Option 2 -- Any Stata version, manual download:"
        display as text "    1. Download ltgm_country_data.dta from:"
        display as text "       https://github.com/Mustapha-Wasseja/ltgm-stata/raw/main/ado/ltgm_country_data.dta"
        display as text "    2. Place it in your Stata PLUS/l/ folder: " c(sysdir_plus) "l\"
        display as text "    3. Or use the datapath() option in this command"
        exit 601
    }

    capture confirm file `"`dtafile'"'
    if _rc {
        display as error "ltgm_import: data file not found: `dtafile'"
        exit 601
    }

    /* ------------------------------------------------------------------ */
    /*  Load the dataset (preserving user data)                            */
    /* ------------------------------------------------------------------ */
    preserve
    quietly use `"`dtafile'"', clear

    /* ------------------------------------------------------------------ */
    /*  LIST mode: show available countries and exit                        */
    /* ------------------------------------------------------------------ */
    if "`list'" != "" {
        display _n as text "Available countries in LTGM bundled dataset (" _N " countries):"
        display ""
        forvalues i = 1/`=_N' {
            local cn = country_name[`i']
            local cd = iso3[`i']
            display as text "  `cd'" _col(8) `"`cn'"'
        }
        display ""
        restore
        return scalar n_countries = _N
        exit
    }

    /* ------------------------------------------------------------------ */
    /*  Search for country match                                           */
    /* ------------------------------------------------------------------ */
    local country_clean = strtrim(`"`country'"')
    local country_upper = strupper(`"`country_clean'"')
    local found = 0
    local match_row = 0

    * First: exact match on iso3 (case-insensitive)
    forvalues i = 1/`=_N' {
        if strupper(strtrim(iso3[`i'])) == "`country_upper'" {
            local found = 1
            local match_row = `i'
            continue, break
        }
    }

    * Second: exact match on country_name (case-insensitive)
    if !`found' {
        forvalues i = 1/`=_N' {
            if strupper(strtrim(country_name[`i'])) == "`country_upper'" {
                local found = 1
                local match_row = `i'
                continue, break
            }
        }
    }

    * Third: substring match on country_name (case-insensitive)
    if !`found' {
        local best_pos = 0
        forvalues i = 1/`=_N' {
            local cn_upper = strupper(strtrim(country_name[`i']))
            if strpos("`cn_upper'", "`country_upper'") > 0 {
                local found = 2
                local match_row = `i'
                continue, break
            }
        }
    }

    * Fourth: fuzzy match -- find closest by checking if input is
    * a prefix or substring of country names, or vice versa
    if !`found' {
        * Try: does any country name START with the input?
        forvalues i = 1/`=_N' {
            local cn_upper = strupper(strtrim(country_name[`i']))
            if substr("`cn_upper'", 1, length("`country_upper'")) == "`country_upper'" {
                local found = 3
                local match_row = `i'
                continue, break
            }
        }
    }

    /* ------------------------------------------------------------------ */
    /*  Handle not-found case with suggestion                              */
    /* ------------------------------------------------------------------ */
    if !`found' {
        * Try simple Levenshtein-style: find closest by common letters
        * For simplicity, suggest first country starting with same letter
        local first_letter = substr("`country_upper'", 1, 1)
        local suggestion ""
        local suggestion_code ""
        forvalues i = 1/`=_N' {
            local cn_upper = strupper(strtrim(country_name[`i']))
            if substr("`cn_upper'", 1, 1) == "`first_letter'" {
                local suggestion = country_name[`i']
                local suggestion_code = iso3[`i']
                continue, break
            }
        }

        display as error `"ltgm_import: country '`country_clean'' not found in dataset."'
        if `"`suggestion'"' != "" {
            display as error `"  Did you mean '`suggestion'' (`suggestion_code')?"'
        }
        display as text "  Use ltgm_countries to list available countries."

        restore
        return scalar found = 0
        return local country_name `"`country_clean'"'
        exit
    }

    /* ------------------------------------------------------------------ */
    /*  Extract parameters from matched row                                */
    /* ------------------------------------------------------------------ */
    local r_country_name = country_name[`match_row']
    local r_iso3         = iso3[`match_row']
    local r_income_group = income_group[`match_row']
    local r_data_year    = data_year[`match_row']

    local r_y0        = y0[`match_row']
    local r_s         = s[`match_row']
    local r_delta     = delta[`match_row']
    local r_alpha     = alpha[`match_row']
    local r_ky0       = ky0[`match_row']
    local r_g_tfp     = g_tfp[`match_row']
    local r_g_pop     = g_pop[`match_row']
    local r_hc_growth = hc_growth[`match_row']
    local r_g_lfp     = g_lfp[`match_row']
    local r_g_lfp_m   = g_lfp_m[`match_row']
    local r_g_lfp_f   = g_lfp_f[`match_row']
    local r_povshare  = povshare[`match_row']
    local r_povline   = povline[`match_row']
    local r_gini      = gini_coef[`match_row']
    local r_lfp_rate  = lfp_rate[`match_row']

    * Match type label
    if `found' == 1 {
        local match_type "exact"
    }
    else if `found' == 2 {
        local match_type "substring"
    }
    else {
        local match_type "prefix"
    }

    restore

    /* ------------------------------------------------------------------ */
    /*  Display if noisy                                                   */
    /* ------------------------------------------------------------------ */
    if "`noisy'" != "" | `found' > 1 {
        if `found' > 1 {
            display as text `"  Note: '`country_clean'' matched to '`r_country_name'' (`r_iso3') via `match_type' match"'
        }
        display ""
        display as text "{hline 56}"
        display as result `"  Bundled data for `r_country_name' (`r_iso3')"'
        display as text "{hline 56}"
        display as text "  Income group  : " as result "`r_income_group'"
        display as text "  Data year     : " as result "`r_data_year'"
        display as text "{hline 56}"

        if "`r_y0'" != "" & "`r_y0'" != "." {
            display as text "  y0 (GDP/cap)  : " as result "$" %10.2fc `r_y0'
        }
        else {
            display as text "  y0 (GDP/cap)  : " as result "(missing -- use manual)"
        }

        if "`r_s'" != "" & "`r_s'" != "." {
            display as text "  s  (inv rate) : " as result %8.4f `r_s' as text " (" as result %5.2f `r_s'*100 as text "%)"
        }

        display as text "  delta (depr)  : " as result %8.4f `r_delta'
        display as text "  alpha (K shr) : " as result %8.4f `r_alpha'

        if "`r_ky0'" != "" & "`r_ky0'" != "." {
            display as text "  ky0   (K/Y)   : " as result %8.3f `r_ky0'
        }

        display as text "  g_tfp         : " as result %8.4f `r_g_tfp' as text " (" as result %5.2f `r_g_tfp'*100 as text "%)"
        display as text "  g_pop         : " as result %8.4f `r_g_pop' as text " (" as result %5.2f `r_g_pop'*100 as text "%)"
        display as text "  povshare      : " as result %8.4f `r_povshare' as text " (" as result %5.2f `r_povshare'*100 as text "%)"
        display as text "{hline 56}"
        display ""
    }

    /* ------------------------------------------------------------------ */
    /*  Return values                                                      */
    /* ------------------------------------------------------------------ */
    return scalar found     = `found'
    return local  match_type "`match_type'"
    return local  country_name `"`r_country_name'"'
    return local  iso3       "`r_iso3'"
    return local  income_group "`r_income_group'"
    return scalar data_year  = `r_data_year'

    * Numeric parameters -- return missing as . (Stata convention)
    return scalar y0         = `r_y0'
    return scalar s          = `r_s'
    return scalar delta      = `r_delta'
    return scalar alpha      = `r_alpha'
    return scalar ky0        = `r_ky0'
    return scalar g_tfp      = `r_g_tfp'
    return scalar g_pop      = `r_g_pop'
    return scalar hc_growth  = `r_hc_growth'
    return scalar g_lfp      = `r_g_lfp'
    return scalar g_lfp_m    = `r_g_lfp_m'
    return scalar g_lfp_f    = `r_g_lfp_f'
    return scalar povshare   = `r_povshare'
    return scalar povline    = `r_povline'
    return scalar gini       = `r_gini'

end
