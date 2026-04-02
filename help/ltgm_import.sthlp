{smcl}
{* *! version 1.0.0  01apr2026}{...}
{vieweralsosee "ltgm_setup" "help ltgm_setup"}{...}
{vieweralsosee "ltgm_countries" "help ltgm_countries"}{...}
{viewerjumpto "Syntax" "ltgm_import##syntax"}{...}
{viewerjumpto "Description" "ltgm_import##description"}{...}
{viewerjumpto "Examples" "ltgm_import##examples"}{...}
{title:Title}

{phang}
{cmd:ltgm_import} {hline 2} Import country parameters from LTGM bundled data


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:ltgm_import}
{cmd:,}
{opt country(string)}
[{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt country(string)}}country name or ISO3 code{p_end}

{syntab:Options}
{synopt:{opt year0(#)}}reference year; default {bf:2022}{p_end}
{synopt:{opt datap:ath(string)}}path to data directory containing ltgm_country_data.dta{p_end}
{synopt:{opt list}}list all available countries and exit{p_end}
{synopt:{opt noisy}}display parameter values found{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ltgm_import} loads the LTGM bundled country dataset and returns
parameters for the matched country.  Matching is case-insensitive and
supports ISO3 codes, exact country names, and substring matches.

{pstd}
If no match is found, the command suggests the closest alternative
and returns {cmd:r(found)} = 0.

{pstd}
This command is called internally by {cmd:ltgm_setup} when a country
is specified.  Direct use is optional.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. ltgm_import, country("Kenya") noisy}

{phang}{cmd:. ltgm_import, country("KEN")}

{phang}{cmd:. ltgm_import, country("Kenia")}
{pstd}(suggests "Kenya" if not found)

{phang}{cmd:. ltgm_import, list}


{title:Stored results}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(found)}}1=exact, 2=substring, 3=prefix, 0=not found{p_end}
{synopt:{cmd:r(y0)}}GDP per capita{p_end}
{synopt:{cmd:r(s)}}investment rate{p_end}
{synopt:{cmd:r(delta)}}depreciation rate{p_end}
{synopt:{cmd:r(alpha)}}capital share{p_end}
{synopt:{cmd:r(ky0)}}capital-output ratio{p_end}
{synopt:{cmd:r(g_tfp)}}TFP growth rate{p_end}
{synopt:{cmd:r(g_pop)}}population growth rate{p_end}
{synopt:{cmd:r(povshare)}}poverty headcount share{p_end}
{synopt:{cmd:r(povline)}}poverty line ($/day){p_end}
{synopt:{cmd:r(g_lfp)}}LFP growth rate{p_end}
{synopt:{cmd:r(data_year)}}reference data year{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(country_name)}}matched country name{p_end}
{synopt:{cmd:r(iso3)}}ISO3 country code{p_end}
{synopt:{cmd:r(income_group)}}World Bank income group{p_end}
{synopt:{cmd:r(match_type)}}exact, substring, or prefix{p_end}


{title:Also see}

{psee}
{space 2}Help:  {manhelp ltgm_setup R:ltgm_setup}, {manhelp ltgm_countries R:ltgm_countries}
{p_end}
