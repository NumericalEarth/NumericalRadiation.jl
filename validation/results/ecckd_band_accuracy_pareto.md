# ecCKD Band-Count Accuracy Pareto

Status: **passed**

- Accuracy points: 7
- Passing accuracy points: 7
- Published ecCKD inventory entries: 6
- Plot: `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_band_accuracy_pareto.svg`
- CSV: `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_band_accuracy_pareto.csv`

This artifact plots the currently tracked ecCKD accuracy rows: the official 32x32 anchor from the reduced-accuracy registry and direct published-model accuracy diagnostics for the promoted official 32x32, 32x64, 32x96, 64x32, 64x64, and 64x96 combinations. Promoted published combinations are inventoried, recovered by the teacher-student scan, and pass the package-native clean reference gate against matched ecRad reference products. Frozen greedy-era reduced candidates are recorded in validation/FROZEN_DIAGNOSTICS.md; new band-count rows only count when produced by the recovered training pipeline.

The plot keeps boundary forcing on the y-axis because that is the user-facing radiative forcing criterion. The JSON and CSV also report `normalized_objective`, `objective_source`, and `limiting_metric`.

## Boundary-Forcing Pareto Front

| Total g-points | LW | SW | Passed | Worst boundary forcing error | Normalized objective | Limiting metric | Method |
|---:|---:|---:|---:|---:|---:|---|---|
| 64 | 32 | 32 | true | 0.0140334 | 0.182186 | heating_rate_max_abs | official ecCKD 32x32 baseline without shortwave reduction |
| 96 | 64 | 32 | true | 0.0137163 | 0.184824 | heating_rate_max_abs | official ecCKD 1.2/1.4 64-LW x 32-SW narrow/rgb model |

## Normalized-Objective Pareto Front

This front ranks the same rows by the full reported hard-gate objective when available. It can disagree with the boundary-forcing front when a row's limiting metric is not boundary forcing.

| Total g-points | LW | SW | Passed | Worst boundary forcing error | Normalized objective | Limiting metric | Method |
|---:|---:|---:|---:|---:|---:|---|---|
| 64 | 32 | 32 | true | 0.0140334 | 0.182186 | heating_rate_max_abs | official ecCKD 32x32 baseline without shortwave reduction |
| 128 | 64 | 64 | true | 0.0138231 | 0.15586 | heating_rate_max_abs | official ecCKD 1.2 64-LW x 64-SW climate model |

## Published Inventory

| File | Kind | Bands | G-points |
|---|---|---:|---:|
| `ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc` | longwave | 1 | 32 |
| `ecckd-1.0_sw_climate_rgb-32b_ckd-definition.nc` | shortwave | 5 | 32 |
| `ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc` | longwave | 13 | 64 |
| `ecckd-1.2_sw_climate_window-64b_ckd-definition.nc` | shortwave | 19 | 64 |
| `ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc` | shortwave | 5 | 32 |
| `ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc` | shortwave | 44 | 96 |
