{smcl}
{* *! version 1.0.0  01apr2026}{...}
{vieweralsosee "ltgm_setup" "help ltgm_setup"}{...}
{vieweralsosee "ltgm_run" "help ltgm_run"}{...}
{vieweralsosee "ltgm_compare" "help ltgm_compare"}{...}
{vieweralsosee "ltgm_export" "help ltgm_export"}{...}
{viewerjumpto "Syntax" "ltgm_graph##syntax"}{...}
{viewerjumpto "Description" "ltgm_graph##description"}{...}
{viewerjumpto "Options" "ltgm_graph##options"}{...}
{viewerjumpto "Examples" "ltgm_graph##examples"}{...}
{title:Title}

{phang}
{cmd:ltgm_graph} {hline 2} Graph LTGM simulation results


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:ltgm_graph}
[{cmd:,}
{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt scen:ario(string)}}primary scenario to plot; default {bf:"baseline"}{p_end}
{synopt:{opt over(string)}}overlay a second scenario on the same graph{p_end}
{synopt:{opt var(string)}}variable to plot; default {bf:y_pc}{p_end}
{synopt:{opt savep:ath(string)}}directory containing results files; default {bf:current directory}{p_end}
{synopt:{opt sav:ing(string)}}export graph to file (.png, .pdf, .gph){p_end}
{synopt:{opt title(string)}}custom graph title{p_end}
{synopt:{opt nodisplay}}suppress graph window (useful with saving){p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ltgm_graph} produces time-series line graphs from LTGM results datasets
produced by {cmd:ltgm_run}.  It can plot a single scenario or overlay two
scenarios for visual comparison.

{pstd}
All graph commands use Stata 13-compatible {cmd:twoway line} syntax.


{marker options}{...}
{title:Options}

{phang}
{opt var(string)} selects which output variable to plot.  Valid choices are:
{bf:y_pc} (GDP per capita, default),
{bf:g_y} (GDP per capita growth),
{bf:g_Y} (aggregate GDP growth),
{bf:ky} (capital-output ratio),
{bf:pov} (poverty headcount),
{bf:s_t} (savings rate).

{phang}
{opt over(string)} overlays a second scenario.  When specified, the graph shows
two lines with a legend identifying each scenario.

{phang}
{opt saving(string)} exports the current graph.  File extension determines format:
{bf:.png}, {bf:.pdf}, {bf:.eps}, or {bf:.gph}.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. ltgm_graph, scenario(baseline) var(y_pc)}

{phang}{cmd:. ltgm_graph, scenario(baseline) over(highsave) var(y_pc) title("Kenya: GDP per Capita")}

{phang}{cmd:. ltgm_graph, scenario(baseline) var(pov) saving(poverty_path.png)}

{phang}{cmd:. ltgm_graph, scenario(baseline) over(highsave) var(ky)}


{title:Also see}

{psee}
{space 2}Help:  {manhelp ltgm_setup R:ltgm_setup}, {manhelp ltgm_run R:ltgm_run}, {manhelp ltgm_compare R:ltgm_compare}, {manhelp ltgm_export R:ltgm_export}
{p_end}
