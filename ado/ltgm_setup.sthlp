{smcl}
{* *! version 1.0.0  01apr2026}{...}
{vieweralsosee "ltgm_run" "help ltgm_run"}{...}
{vieweralsosee "ltgm_compare" "help ltgm_compare"}{...}
{vieweralsosee "ltgm_graph" "help ltgm_graph"}{...}
{vieweralsosee "ltgm_export" "help ltgm_export"}{...}
{viewerjumpto "Syntax" "ltgm_setup##syntax"}{...}
{viewerjumpto "Description" "ltgm_setup##description"}{...}
{viewerjumpto "Options" "ltgm_setup##options"}{...}
{viewerjumpto "Examples" "ltgm_setup##examples"}{...}
{title:Title}

{phang}
{cmd:ltgm_setup} {hline 2} Set up parameters for the LTGM Standard Model


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:ltgm_setup}
{cmd:,}
{opt mod:el(string)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt mod:el(string)}}model type; currently only {bf:standard} is supported{p_end}

{syntab:Identification}
{synopt:{opt c:ountry(string)}}country name or ISO3 code; triggers auto-fill from bundled data{p_end}
{synopt:{opt scen:ario(string)}}scenario label; default {bf:"baseline"}{p_end}

{syntab:Data source}
{synopt:{opt datas:ource(string)}}data source for auto-fill; {bf:"bundled"} (default) or {bf:"none"}{p_end}
{synopt:{opt noautofill}}skip auto-fill even if country() is specified{p_end}

{syntab:Time horizon}
{synopt:{opt year0(#)}}base year; default {bf:2020}{p_end}
{synopt:{opt hor:izon(#)}}final projection year; default {bf:2050}{p_end}

{syntab:Model variant}
{synopt:{opt sub:model(#)}}sub-model: 1=aggregate LFP, 2=male/female LFP, 3=savings; default {bf:1}{p_end}

{syntab:Production parameters}
{synopt:{opt al:pha(#)}}capital share in (0,1); default {bf:0.35}{p_end}
{synopt:{opt s(#)}}initial savings/investment rate in (0,1); default {bf:0.20}{p_end}
{synopt:{opt del:ta(#)}}depreciation rate in (0,1); default {bf:0.05}{p_end}
{synopt:{opt ky0(#)}}initial capital-output ratio K/Y > 0; default {bf:2.5}{p_end}
{synopt:{opt y0(#)}}initial GDP per capita > 0; default {bf:1000}{p_end}

{syntab:Growth rates}
{synopt:{opt g_tfp(#)}}initial TFP growth rate; default {bf:0.01}{p_end}
{synopt:{opt g_pop(#)}}initial population growth rate; default {bf:0.02}{p_end}
{synopt:{opt g_lfp(#)}}initial LFP growth rate (sub-model 1); default {bf:0}{p_end}
{synopt:{opt g_lfp_m(#)}}male LFP growth rate (sub-model 2); default {bf:0}{p_end}
{synopt:{opt g_lfp_f(#)}}female LFP growth rate (sub-model 2); default {bf:0}{p_end}
{synopt:{opt male_share(#)}}male share of labour force (sub-model 2); default {bf:0.5}{p_end}

{syntab:Climate}
{synopt:{opt cli:mate(#)}}climate damage factor in [0,1]; default {bf:0}{p_end}

{syntab:Poverty}
{synopt:{opt povshare(#)}}initial poverty headcount share; default {bf:0.40}{p_end}
{synopt:{opt povelast(#)}}poverty-growth elasticity; default {bf:-2.0}{p_end}
{synopt:{opt povline(#)}}poverty line in $/day; default {bf:2.15}{p_end}

{syntab:Reach-target paths}
{synopt:{opt s_target(#)}}target savings rate (-1 = constant); default {bf:-1}{p_end}
{synopt:{opt s_year(#)}}year to reach s_target; required if s_target != -1{p_end}
{synopt:{opt gtfp_target(#)}}target TFP growth (-1 = constant); default {bf:-1}{p_end}
{synopt:{opt gtfp_year(#)}}year to reach gtfp_target{p_end}
{synopt:{opt gpop_target(#)}}target population growth (-1 = constant); default {bf:-1}{p_end}
{synopt:{opt gpop_year(#)}}year to reach gpop_target{p_end}
{synopt:{opt glfp_target(#)}}target LFP growth (-1 = constant); default {bf:-1}{p_end}
{synopt:{opt glfp_year(#)}}year to reach glfp_target{p_end}

{syntab:Output}
{synopt:{opt savep:ath(string)}}directory for parameter file; default {bf:current directory}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ltgm_setup} calibrates and stores parameters for the World Bank Long Term
Growth Model (LTGM) Standard Model.  It writes a single-observation Stata
dataset ({bf:_ltgm_params_{it:scenario}.dta}) containing all parameter values,
which is then read by {cmd:ltgm_run}.

{pstd}
Run {cmd:ltgm_setup} once for each scenario you wish to simulate (e.g.,
"baseline" and "highsave"), then call {cmd:ltgm_run} for each.

{pstd}
Reach-target parameters allow any growth rate or the savings rate to
transition linearly from its initial value to a target value by a specified
year.  Set the target to {bf:-1} (the default) to hold the parameter constant.


{marker options}{...}
{title:Options}

{phang}
{opt model(standard)} is required.  Only the standard Solow growth model is
currently supported.

{phang}
{opt scenario(string)} labels the parameter set.  The label is embedded in the
output filename ({bf:_ltgm_params_{it:label}.dta}) so you can maintain
multiple scenarios side by side.

{phang}
{opt alpha(#)} is the Cobb-Douglas capital share (1 minus labour share).
Must be strictly between 0 and 1.

{phang}
{opt climate(#)} is a proportional reduction applied to TFP growth each
period.  Effective TFP = g_tfp * (1 - climate).  Set to 0 for no climate
damage.


{marker examples}{...}
{title:Examples}

    {it:Auto-fill from bundled data (simplest workflow):}

{phang}{cmd:. ltgm_setup, model(standard) country(Kenya) year0(2022) scenario(baseline)}{p_end}
{pstd}All parameters auto-filled from bundled data for Kenya.

{phang}{cmd:. ltgm_setup, model(standard) country(Kenya) year0(2022) scenario(high_inv) s(0.30)}{p_end}
{pstd}Auto-fill Kenya, but override investment rate to 30%.

    {it:Fully manual (no auto-fill):}

{phang}{cmd:. ltgm_setup, model(standard) country("Kenya") scenario(baseline) year0(2022) horizon(2050) alpha(0.35) s(0.22) delta(0.05) g_tfp(0.008) g_pop(0.024) g_lfp(0.002) ky0(2.8) y0(2082)}

{phang}{cmd:. ltgm_setup, model(standard) scenario(ramp) s(0.20) s_target(0.30) s_year(2040) year0(2020) horizon(2050)}


{title:Stored results}

{pstd}
{cmd:ltgm_setup} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(year0)}}base year{p_end}
{synopt:{cmd:r(horizon)}}final year{p_end}
{synopt:{cmd:r(alpha)}}capital share{p_end}
{synopt:{cmd:r(s)}}initial savings rate{p_end}
{synopt:{cmd:r(delta)}}depreciation rate{p_end}
{synopt:{cmd:r(g_tfp)}}initial TFP growth{p_end}
{synopt:{cmd:r(g_pop)}}initial population growth{p_end}
{synopt:{cmd:r(ky0)}}initial K/Y ratio{p_end}
{synopt:{cmd:r(y0)}}initial GDP per capita{p_end}
{synopt:{cmd:r(climate)}}climate damage factor{p_end}
{synopt:{cmd:r(povshare)}}initial poverty share{p_end}
{synopt:{cmd:r(povelast)}}poverty-growth elasticity{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(paramfile)}}full path to saved parameter file{p_end}
{synopt:{cmd:r(model)}}model name{p_end}
{synopt:{cmd:r(country)}}country label{p_end}
{synopt:{cmd:r(scenario)}}scenario label{p_end}


{title:Also see}

{psee}
{space 2}Help:  {manhelp ltgm_run R:ltgm_run}, {manhelp ltgm_compare R:ltgm_compare}, {manhelp ltgm_graph R:ltgm_graph}, {manhelp ltgm_export R:ltgm_export}
{p_end}
