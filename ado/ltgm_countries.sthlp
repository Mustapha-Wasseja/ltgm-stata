{smcl}
{* *! version 1.0.0  01apr2026}{...}
{vieweralsosee "ltgm_setup" "help ltgm_setup"}{...}
{vieweralsosee "ltgm_import" "help ltgm_import"}{...}
{viewerjumpto "Syntax" "ltgm_countries##syntax"}{...}
{viewerjumpto "Description" "ltgm_countries##description"}{...}
{viewerjumpto "Examples" "ltgm_countries##examples"}{...}
{title:Title}

{phang}
{cmd:ltgm_countries} {hline 2} List available countries in LTGM bundled data


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:ltgm_countries}
[{cmd:,}
{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt reg:ion(string)}}filter by income group (e.g., "Low income"){p_end}
{synopt:{opt sea:rch(string)}}substring search on country name{p_end}
{synopt:{opt datap:ath(string)}}path to data directory{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ltgm_countries} displays a table of all countries available in the
LTGM bundled dataset, showing ISO3 code, country name, data year,
GDP per capita, investment rate, and population growth.

{pstd}
Use {opt region()} to filter by World Bank income group and
{opt search()} to find countries by partial name match.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. ltgm_countries}

{phang}{cmd:. ltgm_countries, search("Kenya")}

{phang}{cmd:. ltgm_countries, region("Low income")}


{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(n_countries)}}number of countries listed{p_end}


{title:Also see}

{psee}
{space 2}Help:  {manhelp ltgm_setup R:ltgm_setup}, {manhelp ltgm_import R:ltgm_import}
{p_end}
