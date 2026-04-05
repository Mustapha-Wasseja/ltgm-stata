{smcl}
{* *! version 1.0.0  04apr2026}{...}
{viewerjumpto "Syntax" "ltgm_pc_run##syntax"}{...}
{viewerjumpto "Description" "ltgm_pc_run##description"}{...}
{viewerjumpto "Options" "ltgm_pc_run##options"}{...}
{viewerjumpto "Examples" "ltgm_pc_run##examples"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col:{bf:ltgm_pc_run} {hline 2}}LTGM Public Capital Model simulation engine{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:ltgm_pc_run}
[{cmd:,}
{opt sc:enario(string)}
{opt savep:ath(string)}
{opt nosave}
{opt nod:isplay}
{opt mi:lestone(#)}]

{marker description}{...}
{title:Description}

{pstd}
{cmd:ltgm_pc_run} runs the LTGM Public Capital model simulation. It is called
internally by {cmd:ltgm_run} when the parameter file specifies {bf:model(pc)}.
Users should not normally call this command directly -- use {cmd:ltgm_run} instead.

{pstd}
The PC model extends the standard Solow model by splitting the capital stock into
public (Kg) and private (Kp) components with separate depreciation rates, investment
shares, and an efficiency parameter for public capital.

{pstd}
{bf:Production function:} Y = Kg^phi * Kp^(alpha-phi) * (A * HK * L)^(1-alpha)

{pstd}
{bf:Sub-model 1} (forward): Given public and private investment paths, computes
GDP per capita growth.

{pstd}
{bf:Sub-model 2} (inverse): Given a target GDP per capita growth rate, computes
the required public investment share of GDP.

{marker options}{...}
{title:Options}

{phang}
{opt scenario(string)} name of the scenario. Default is "baseline".

{phang}
{opt savepath(string)} directory for input/output files. Default is current directory.

{phang}
{opt nosave} do not save the results dataset.

{phang}
{opt nodisplay} suppress the milestone summary table.

{phang}
{opt milestone(#)} display results every # years (default 5).

{marker examples}{...}
{title:Examples}

{pstd}Setup and run PC model for Kenya:{p_end}
{phang2}{cmd:. ltgm_setup, model(pc) country(Kenya) year0(2023) scenario(pc_base)}{p_end}
{phang2}{cmd:. ltgm_run, scenario(pc_base)}{p_end}

{pstd}High public investment scenario:{p_end}
{phang2}{cmd:. ltgm_setup, model(pc) country(Kenya) year0(2023) scenario(pc_high) pub_inv(0.10)}{p_end}
{phang2}{cmd:. ltgm_run, scenario(pc_high)}{p_end}

{pstd}Compare scenarios:{p_end}
{phang2}{cmd:. ltgm_compare, base(pc_base) alt(pc_high)}{p_end}

{title:Also see}

{psee}
{manhelp ltgm_setup R}, {manhelp ltgm_run R}, {manhelp ltgm_compare R}
{p_end}
