*! ltgm_countries.ado  v1.0.0  2026-04-01
*! World Bank LTGM Stata Package -- List Available Countries
*! Displays bundled country data with optional filtering
*!
*! Authors: Mustapha Wasseja / World Bank LTGM Team
*! Requires: Stata 13+

capture program drop ltgm_countries
program define ltgm_countries, rclass
    version 13.0

    /* ------------------------------------------------------------------ */
    /*  Syntax                                                             */
    /* ------------------------------------------------------------------ */
    syntax [, REGion(string) SEARch(string) DATAPath(string) ]

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
        capture quietly findfile ltgm_countries.ado
        if _rc == 0 {
            local ado_dir = subinstr(r(fn), "ltgm_countries.ado", "", .)
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
        capture quietly findfile ltgm_countries.ado
        if _rc == 0 {
            local ado_dir = subinstr(r(fn), "ltgm_countries.ado", "", .)
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
        display as error "ltgm_countries: cannot find ltgm_country_data.dta"
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

    /* ------------------------------------------------------------------ */
    /*  Load data                                                          */
    /* ------------------------------------------------------------------ */
    preserve
    quietly use `"`dtafile'"', clear

    /* ------------------------------------------------------------------ */
    /*  Apply filters                                                      */
    /* ------------------------------------------------------------------ */
    if `"`region'"' != "" {
        local region_upper = strupper(strtrim(`"`region'"'))
        quietly generate byte _keep = 0
        forvalues i = 1/`=_N' {
            local ig = strupper(strtrim(income_group[`i']))
            if strpos("`ig'", "`region_upper'") > 0 {
                quietly replace _keep = 1 in `i'
            }
        }
        quietly keep if _keep == 1
        quietly drop _keep
        if _N == 0 {
            display as error "ltgm_countries: no countries found matching region '`region''"
            display as text "  Available groups: Low income, Lower middle income, Upper middle income, High income"
            restore
            exit
        }
    }

    if `"`search'"' != "" {
        local search_upper = strupper(strtrim(`"`search'"'))
        quietly generate byte _keep = 0
        forvalues i = 1/`=_N' {
            local cn = strupper(strtrim(country_name[`i']))
            if strpos("`cn'", "`search_upper'") > 0 {
                quietly replace _keep = 1 in `i'
            }
        }
        quietly keep if _keep == 1
        quietly drop _keep
        if _N == 0 {
            display as text "  No countries found matching '`search''"
            restore
            exit
        }
    }

    /* ------------------------------------------------------------------ */
    /*  Display table                                                      */
    /* ------------------------------------------------------------------ */
    local n_display = _N

    display ""
    display as text "Available countries in LTGM bundled dataset (N=" as result `n_display' as text "):"
    display ""
    display as text "  {ralign 4:Code}" ///
        "  {lalign 35:Country}" ///
        "  {ralign 5:Year}" ///
        "  {ralign 10:GDP/cap}" ///
        "  {ralign 8:Inv rate}" ///
        "  {ralign 8:Pop gr}"
    display as text "  {hline 75}"

    forvalues i = 1/`n_display' {
        local cd  = iso3[`i']
        local cn  = country_name[`i']
        local dy  = data_year[`i']
        local vy0 = y0[`i']
        local vs  = s[`i']
        local vgp = g_pop[`i']

        * Format GDP/cap
        if "`vy0'" == "." | "`vy0'" == "" {
            local vy0_fmt "     n/a"
        }
        else {
            local vy0_fmt : display %8.0fc `vy0'
        }

        * Format investment rate as percentage
        if "`vs'" == "." | "`vs'" == "" {
            local vs_fmt "    n/a"
        }
        else {
            local vs_fmt : display %6.1f `vs'*100
            local vs_fmt "`vs_fmt'%"
        }

        * Format pop growth as percentage
        if "`vgp'" == "." | "`vgp'" == "" {
            local vgp_fmt "    n/a"
        }
        else {
            local vgp_fmt : display %6.2f `vgp'*100
            local vgp_fmt "`vgp_fmt'%"
        }

        display as text "  {ralign 4:`cd'}" ///
            as result "  {lalign 35:`cn'}" ///
            as text "  {ralign 5:`dy'}" ///
            as result "  {ralign 10:`vy0_fmt'}" ///
            as result "  {ralign 8:`vs_fmt'}" ///
            as result "  {ralign 8:`vgp_fmt'}"
    }

    display as text "  {hline 75}"
    display ""

    restore

    return scalar n_countries = `n_display'

end
