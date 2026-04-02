{smcl}
{* *! version 1.0.0  01apr2026}{...}
{vieweralsosee "ltgm_setup" "help ltgm_setup"}{...}
{vieweralsosee "ltgm_run" "help ltgm_run"}{...}
{vieweralsosee "ltgm_compare" "help ltgm_compare"}{...}
{vieweralsosee "ltgm_graph" "help ltgm_graph"}{...}
{viewerjumpto "Syntax" "ltgm_export##syntax"}{...}
{viewerjumpto "Description" "ltgm_export##description"}{...}
{viewerjumpto "Options" "ltgm_export##options"}{...}
{viewerjumpto "Examples" "ltgm_export##examples"}{...}
{title:Title}

{phang}
{cmd:ltgm_export} {hline 2} Export LTGM results to Excel


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:ltgm_export}
{cmd:,}
{opt using(filename)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt using(filename)}}Excel output file (include .xlsx extension){p_end}

{syntab:Options}
{synopt:{opt scen:arios(string)}}space-delimited list of scenario labels; default {bf:"baseline"}{p_end}
{synopt:{opt savep:ath(string)}}directory containing results files; default {bf:current directory}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ltgm_export} writes LTGM results datasets to an Excel workbook using
Stata 13's {cmd:putexcel} command.  Each scenario is placed on a separate
sheet.

{pstd}
The export includes metadata (country, scenario, model) in the first rows
followed by column headers and all output variables.

{pstd}
{bf:Note:} Stata 13's {cmd:putexcel} supports data values only (no cell
formatting, bold, or colours).  Enhanced formatting is available in Stata 14+.


{marker options}{...}
{title:Options}

{phang}
{opt using(filename)} is required and must include the .xlsx extension.

{phang}
{opt scenarios(string)} lists one or more scenario labels separated by spaces.
Each label must have a corresponding {bf:_ltgm_results_{it:label}.dta} file.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. ltgm_export, using(kenya_results.xlsx) scenarios(baseline)}

{phang}{cmd:. ltgm_export, using(kenya_results.xlsx) scenarios(baseline highsave)}

{phang}{cmd:. ltgm_export, using(output.xlsx) scenarios(baseline highsave climate) savepath(C:/ltgm_output)}


{title:Also see}

{psee}
{space 2}Help:  {manhelp ltgm_setup R:ltgm_setup}, {manhelp ltgm_run R:ltgm_run}, {manhelp ltgm_compare R:ltgm_compare}, {manhelp ltgm_graph R:ltgm_graph}
{p_end}
