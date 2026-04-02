{smcl}
{* *! version 1.0.0  01apr2026}{...}
{vieweralsosee "ltgm_setup" "help ltgm_setup"}{...}
{vieweralsosee "ltgm_compare" "help ltgm_compare"}{...}
{vieweralsosee "ltgm_graph" "help ltgm_graph"}{...}
{vieweralsosee "ltgm_export" "help ltgm_export"}{...}
{viewerjumpto "Syntax" "ltgm_run##syntax"}{...}
{viewerjumpto "Description" "ltgm_run##description"}{...}
{viewerjumpto "Options" "ltgm_run##options"}{...}
{viewerjumpto "Model equations" "ltgm_run##equations"}{...}
{viewerjumpto "Examples" "ltgm_run##examples"}{...}
{title:Title}

{phang}
{cmd:ltgm_run} {hline 2} Run the LTGM Standard Model simulation


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:ltgm_run}
[{cmd:,}
{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt scen:ario(string)}}scenario label to run; default {bf:"baseline"}{p_end}
{synopt:{opt savep:ath(string)}}directory for results file; default {bf:current directory}{p_end}
{synopt:{opt nosave}}do not write results to disk{p_end}
{synopt:{opt nodisplay}}suppress the milestone table{p_end}
{synopt:{opt mile:stone(#)}}display interval in years; default {bf:5}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ltgm_run} reads the parameter file written by {cmd:ltgm_setup} for the
specified scenario and runs the LTGM Standard (Solow) growth model.  It
produces a results dataset with one observation per year from {it:year0}
to {it:horizon}.

{pstd}
After execution the results dataset is loaded into memory (replacing any
existing data) and optionally saved to {bf:_ltgm_results_{it:scenario}.dta}.

{pstd}
A milestone table showing GDP per capita, growth rates, K/Y ratio, and
poverty headcount is displayed at regular intervals.


{marker equations}{...}
{title:Model equations}

{pstd}
The core Solow loop iterates year by year:

{p 8 8 2}
{it:cap_factor_t} = (1 - delta) + s_t / ky_t

{p 8 8 2}
{it:g_Y_t} = (1 + g_A_t) * cap_factor_t^alpha * (1 + g_L_t)^(1-alpha) - 1

{p 8 8 2}
{it:ky_{t+1}} = ky_t * cap_factor_t / (1 + g_Y_t)

{p 8 8 2}
{it:g_y_t} = (1 + g_Y_t) / (1 + g_pop_t) - 1

{p 8 8 2}
{it:y_pc_{t+1}} = y_pc_t * (1 + g_y_t)

{p 8 8 2}
{it:pov_{t+1}} = pov_t * (1 + povelast * g_y_t)   [clamped to 0-1]

{pstd}
where g_A_t = g_tfp_t * (1 - climate), and g_L_t depends on the sub-model.


{marker options}{...}
{title:Options}

{phang}
{opt scenario(string)} identifies which parameter file to read.  The file
{bf:_ltgm_params_{it:scenario}.dta} must already exist from a prior
{cmd:ltgm_setup} call.

{phang}
{opt milestone(#)} controls the display interval.  The first year, last year,
and every {it:#}-th year are shown.

{phang}
{opt nosave} suppresses writing the results dataset to disk.  Results are
still loaded into memory.

{phang}
{opt nodisplay} suppresses the milestone summary table.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. ltgm_setup, model(standard) country("Kenya") scenario(baseline) s(0.22) g_tfp(0.008) g_pop(0.024) ky0(2.8) y0(2082) year0(2022) horizon(2050)}

{phang}{cmd:. ltgm_run, scenario(baseline)}

{phang}{cmd:. ltgm_run, scenario(baseline) milestone(10) nodisplay}


{title:Output variables}

{synoptset 16 tabbed}{...}
{synopt:{bf:year}}calendar year{p_end}
{synopt:{bf:y_pc}}GDP per capita level ($){p_end}
{synopt:{bf:g_y}}GDP per capita growth rate (fraction){p_end}
{synopt:{bf:g_Y}}aggregate GDP growth rate (fraction){p_end}
{synopt:{bf:ky}}capital-output ratio{p_end}
{synopt:{bf:s_t}}savings rate at time t{p_end}
{synopt:{bf:g_tfp_t}}TFP growth rate at time t (before climate){p_end}
{synopt:{bf:g_L_t}}effective labour force growth at time t{p_end}
{synopt:{bf:pov}}poverty headcount share{p_end}


{title:Stored results}

{pstd}
{cmd:ltgm_run} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(year0)}}base year{p_end}
{synopt:{cmd:r(horizon)}}final year{p_end}
{synopt:{cmd:r(y_pc_init)}}initial GDP per capita{p_end}
{synopt:{cmd:r(y_pc_final)}}final GDP per capita{p_end}
{synopt:{cmd:r(pov_final)}}final poverty headcount share{p_end}
{synopt:{cmd:r(avg_g_ypc)}}annualised average GDPpc growth (geometric){p_end}
{synopt:{cmd:r(ky_final)}}final K/Y ratio{p_end}
{synopt:{cmd:r(nyears)}}number of years in output{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(resultsfile)}}full path to saved results file{p_end}
{synopt:{cmd:r(scenario)}}scenario label{p_end}
{synopt:{cmd:r(model)}}model name{p_end}
{synopt:{cmd:r(country)}}country label{p_end}


{title:Also see}

{psee}
{space 2}Help:  {manhelp ltgm_setup R:ltgm_setup}, {manhelp ltgm_compare R:ltgm_compare}, {manhelp ltgm_graph R:ltgm_graph}, {manhelp ltgm_export R:ltgm_export}
{p_end}
