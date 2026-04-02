/**********************************************************************
 *  Demo 1 -- Simple User (country team economist)
 *  Ghana: baseline vs high investment
 **********************************************************************/
clear all
set more off

* --- Baseline: what happens if nothing changes ---
ltgm_setup, model(standard) country(Ghana) year0(2023) scenario(baseline)
ltgm_run, scenario(baseline)

* --- Scenario: what if Ghana raises investment to 30% of GDP ---
ltgm_setup, model(standard) country(Ghana) year0(2023) ///
    scenario(high_investment) s(0.30)
ltgm_run, scenario(high_investment)

* --- Comparison table ---
ltgm_compare, base(baseline) alt(high_investment)

* --- Graph 1: GDP per capita trajectories ---
ltgm_graph, scenario(baseline) over(high_investment) var(y_pc) ///
    title("Ghana: GDP per Capita Projections 2023-2050") ///
    saving(demo1_gdppc.png)

* --- Graph 2: Poverty trajectories ---
ltgm_graph, scenario(baseline) over(high_investment) var(pov) ///
    title("Ghana: Poverty Rate Projections 2023-2050") ///
    saving(demo1_poverty.png)

* --- Export ---
ltgm_export, using(demo1_ghana.xlsx) scenarios(baseline high_investment)

display _n "=== Demo 1 complete ===" _n
