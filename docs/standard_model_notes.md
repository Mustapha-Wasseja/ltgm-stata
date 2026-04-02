# LTGM Standard Model -- Stata Implementation Notes

## Model Equations

The standard LTGM is a discrete-time Solow growth model with the following
core loop (iterated year by year from t=1 to T):

### Production Function (Cobb-Douglas)

    Y_t = K_t^alpha * (A_t * L_t)^(1 - alpha)

where:
- K = physical capital stock
- A = total factor productivity level
- L = effective labour force
- alpha = capital share (0 < alpha < 1)

### State Variables (carried forward each period)

1. **Capital-output ratio (ky)**:
   ```
   cap_factor_t = (1 - delta) + s_t / ky_t
   g_Y_t        = (1 + g_A_t) * cap_factor_t^alpha * (1 + g_L_t)^(1-alpha) - 1
   ky_{t+1}     = ky_t * cap_factor_t / (1 + g_Y_t)
   ```

2. **GDP per capita level (y_pc)**:
   ```
   g_y_t     = (1 + g_Y_t) / (1 + g_pop_t) - 1
   y_pc_{t+1} = y_pc_t * (1 + g_y_t)
   ```

3. **Poverty headcount (pov)**:
   ```
   pov_{t+1} = pov_t * (1 + povelast * g_y_t)   [clamped to 0-1]
   ```

### TFP with Climate Adjustment

    g_A_t = g_tfp_t * (1 - climate)

The climate parameter is a proportional reduction in TFP growth, applied
after any reach-target interpolation on g_tfp.

### Labour Force Growth (Sub-models)

- **Sub-model 1 (aggregate)**:  g_L = g_pop + g_lfp
- **Sub-model 2 (gendered)**:   g_L = g_pop + male_share * g_lfp_m + (1 - male_share) * g_lfp_f
- **Sub-model 3 (savings)**:    g_L = g_pop + g_lfp  (same as 1; savings variant handled elsewhere)

### Path Interpolation (Reach-Target)

For any parameter p with initial value p_0 and target p_target by year p_year:

    frac = min(1, max(0, (year - year0) / (p_year - year0)))
    p_t  = p_0 + (p_target - p_0) * frac

After p_year, p_t holds constant at p_target.

## Steady-State Properties

In the long run with constant parameters, the model converges to:

    g_y_ss = g_tfp / (1 - alpha)

This is the balanced growth path of the Solow model. K/Y converges to:

    ky_ss = s / (delta + g_Y_ss)

where g_Y_ss = (1 + g_A_ss) * ... (the balanced aggregate growth rate).

## Design Decisions

### State management
- Parameters: stored as 1-obs .dta file (_ltgm_params_{scenario}.dta)
- Results: stored as N-obs .dta file (_ltgm_results_{scenario}.dta)
- No globals used; all inter-command communication via files
- Internal loop state via scalars with _ltgm_ prefix, dropped after use

### Why not Mata for the inner loop?
The loop runs for 30-100 iterations. Ado-file performance is adequate.
Mata would add complexity without meaningful speed benefit at this scale.
If the package later adds Monte Carlo simulation or multi-country batch
processing, the inner loop should move to Mata.

### Stata 13 constraints
- putexcel: data only, no cell formatting (formatting added in Stata 14+)
- No frames: cannot hold baseline and scenario simultaneously in memory
- No subcmd parsing: using ltgm_* prefix family instead of ltgm subcommands
- version 13.0 statement in all .ado files ensures forward compatibility

### Comparison with R implementation
The R model (model_standard.R) uses the same equations but with vectorised
operations. The Stata implementation uses an explicit forvalues loop, which
is mathematically identical. Numerical results should match to IEEE 754
double precision (15-16 significant digits), with any differences arising
only from operation ordering in floating-point accumulation.

## File Inventory

| File | Purpose |
|---|---|
| ltgm_setup.ado | Parameter calibration and validation |
| ltgm_run.ado | Solow model simulation engine |
| ltgm_compare.ado | Baseline vs scenario comparison |
| ltgm_graph.ado | Time-series graphs |
| ltgm_export.ado | Excel export via putexcel |
| ltgm_setup.sthlp | Help for ltgm_setup |
| ltgm_run.sthlp | Help for ltgm_run |
| ltgm_compare.sthlp | Help for ltgm_compare |
| ltgm_graph.sthlp | Help for ltgm_graph |
| ltgm_export.sthlp | Help for ltgm_export |
| kenya_example.do | End-to-end worked example |
| test_standard.do | Steady-state and sanity tests |
| ltgm.pkg | Stata package descriptor |

## Future Extensions

1. **PC model** (_ltgm_pc.ado): dual capital stocks, efficiency tracking
2. **HC model** (_ltgm_hc.ado): cohort-based human capital in Mata
3. **NR model** (_ltgm_nr.ado): resource sectors, fiscal rules, GDI
4. **TFP model** (_ltgm_tfp.ado): determinant-based TFP projection
5. **Target solver** (ltgm_target.ado): bisection method in Mata
6. **Country data loader**: auto-calibrate from bundled CSV/DTA datasets
