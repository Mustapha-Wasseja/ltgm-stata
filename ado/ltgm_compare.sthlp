{smcl}
{* *! version 1.0.0  01apr2026}{...}
{vieweralsosee "ltgm_setup" "help ltgm_setup"}{...}
{vieweralsosee "ltgm_run" "help ltgm_run"}{...}
{vieweralsosee "ltgm_graph" "help ltgm_graph"}{...}
{vieweralsosee "ltgm_export" "help ltgm_export"}{...}
{viewerjumpto "Syntax" "ltgm_compare##syntax"}{...}
{viewerjumpto "Description" "ltgm_compare##description"}{...}
{viewerjumpto "Options" "ltgm_compare##options"}{...}
{viewerjumpto "Examples" "ltgm_compare##examples"}{...}
{title:Title}

{phang}
{cmd:ltgm_compare} {hline 2} Compare baseline and alternative LTGM scenarios


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:ltgm_compare}
{cmd:,}
{opt base(string)}
{opt alt(string)}
[{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt base(string)}}scenario label for the baseline{p_end}
{synopt:{opt alt(string)}}scenario label for the alternative{p_end}

{syntab:Options}
{synopt:{opt savep:ath(string)}}directory containing results files; default {bf:current directory}{p_end}
{synopt:{opt years(numlist)}}specific years to display{p_end}
{synopt:{opt sav:ing(string)}}save comparison dataset to file{p_end}
{synopt:{opt nodisplay}}suppress comparison table{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ltgm_compare} loads two results datasets produced by {cmd:ltgm_run}
(one for {it:base} and one for {it:alt}), merges them on year, and computes
level differences, percentage differences, and percentage-point differences
in key output variables.

{pstd}
The comparison dataset is left in memory after execution.  Optionally it can
be saved to a named file via {opt saving()}.


{marker options}{...}
{title:Options}

{phang}
{opt base(string)} and {opt alt(string)} identify the two scenario labels.
Files {bf:_ltgm_results_{it:base}.dta} and {bf:_ltgm_results_{it:alt}.dta}
must exist.

{phang}
{opt years(numlist)} restricts the display to specific years.  By default the
table shows the first year, every 5th year, and the last year.

{phang}
{opt saving(string)} writes the comparison dataset to a .dta file.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. ltgm_compare, base(baseline) alt(highsave)}

{phang}{cmd:. ltgm_compare, base(baseline) alt(highsave) years(2022 2030 2040 2050)}

{phang}{cmd:. ltgm_compare, base(baseline) alt(highsave) saving(kenya_comparison.dta)}


{title:Output variables}

{synoptset 20 tabbed}{...}
{synopt:{bf:year}}calendar year{p_end}
{synopt:{bf:y_pc_base}}GDP per capita in base scenario{p_end}
{synopt:{bf:y_pc_alt}}GDP per capita in alt scenario{p_end}
{synopt:{bf:delta_y_pc}}level difference (alt - base){p_end}
{synopt:{bf:pct_y_pc}}percentage difference{p_end}
{synopt:{bf:delta_g_y}}growth rate difference in pp{p_end}
{synopt:{bf:delta_pov}}poverty headcount difference in pp{p_end}
{synopt:{bf:delta_ky}}K/Y ratio difference{p_end}
{synopt:{bf:pov_base}}poverty in base scenario{p_end}
{synopt:{bf:pov_alt}}poverty in alt scenario{p_end}


{title:Stored results}

{pstd}
{cmd:ltgm_compare} stores the following in {cmd:r()} (evaluated at the horizon year):

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(year0)}}base year{p_end}
{synopt:{cmd:r(horizon)}}horizon year{p_end}
{synopt:{cmd:r(delta_y_pc)}}GDP per capita difference at horizon{p_end}
{synopt:{cmd:r(pct_y_pc)}}percentage difference at horizon{p_end}
{synopt:{cmd:r(delta_pov)}}poverty headcount difference (pp) at horizon{p_end}
{synopt:{cmd:r(delta_ky)}}K/Y difference at horizon{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(base_scenario)}}base scenario label{p_end}
{synopt:{cmd:r(alt_scenario)}}alt scenario label{p_end}
{synopt:{cmd:r(model)}}model name{p_end}
{synopt:{cmd:r(country)}}country label{p_end}


{title:Also see}

{psee}
{space 2}Help:  {manhelp ltgm_setup R:ltgm_setup}, {manhelp ltgm_run R:ltgm_run}, {manhelp ltgm_graph R:ltgm_graph}, {manhelp ltgm_export R:ltgm_export}
{p_end}
