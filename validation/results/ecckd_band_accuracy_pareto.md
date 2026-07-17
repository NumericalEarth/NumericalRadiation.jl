# ecCKD Band-Count Accuracy Pareto

Status: **passed**

- Accuracy points: 109
- Passing accuracy points: 11
- Published ecCKD inventory entries: 6
- Plot: `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_band_accuracy_pareto.svg`
- CSV: `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_band_accuracy_pareto.csv`

This artifact plots all currently available ecCKD accuracy rows, including reduced candidates, size scans, leave-one-out official shortwave g-point scans, and direct published-model accuracy diagnostics for the promoted official 32x32, 32x64, 32x96, 64x32, 64x64, and 64x96 combinations. Promoted published combinations are inventoried, recovered by the teacher-student scan, and now pass the package-native clean reference gate once evaluated against matched ecRad reference products; newly trained intermediate models remain future work.

The plot keeps boundary forcing on the y-axis because that is the user-facing radiative forcing criterion. The JSON and CSV also report `normalized_objective`, `objective_source`, and `limiting_metric`; for leave-one-out reduced models, the reported ecCKD hard-gate objective can remain above threshold even when boundary forcing is small because the scan artifact does not expose every max-abs/heating component separately.

## Boundary-Forcing Pareto Front

| Total g-points | LW | SW | Passed | Worst boundary forcing error | Normalized objective | Limiting metric | Method |
|---:|---:|---:|---:|---:|---:|---|---|
| 32 | 16 | 16 | false | 156.746 | 522.488 | surface_forcing | adjacent official ecCKD g-point bins with spectral-weighted coefficient averages |
| 48 | 32 | 16 | false | 2.07524 | 6.91747 | toa_forcing | weighted greedy 16 shortwave g-point subset with boundary-aware table, component, structural, objective-probe, surface-probe, capped table, continuation, post-capped weight, post-weight surface-table, bounded weight, four current component-scale refits, selected current gas-pressure component scan refit, gas-pressure continuation refit, weighted gas-pressure continuation refit, and high-weight gas-pressure continuation refit |
| 63 | 32 | 31 | false | 0.0242812 | 12.3325 | reported_refit_hardgate_objective | leave-one-out official SW g-point scan with weight refit: omit g25 |
| 64 | 32 | 32 | true | 0.0140334 | 0.182186 | heating_rate_max_abs | official ecCKD 1.0 32-LW x 32-SW climate model |
| 96 | 64 | 32 | true | 0.0137163 | 0.184824 | heating_rate_max_abs | official ecCKD 1.2/1.4 64-LW x 32-SW narrow/rgb model |

## Normalized-Objective Pareto Front

This front ranks the same rows by the full reported hard-gate objective when available. It can disagree with the boundary-forcing front: the 32×31 omitted-g25 row has the smallest boundary forcing, while the omitted-g23 row is the closest 32×31 row to satisfying the full hard gate.

| Total g-points | LW | SW | Passed | Worst boundary forcing error | Normalized objective | Limiting metric | Method |
|---:|---:|---:|---:|---:|---:|---|---|
| 32 | 16 | 16 | false | 156.746 | 522.488 | surface_forcing | adjacent official ecCKD g-point bins with spectral-weighted coefficient averages |
| 48 | 32 | 16 | false | 2.07524 | 6.91747 | toa_forcing | weighted greedy 16 shortwave g-point subset with boundary-aware table, component, structural, objective-probe, surface-probe, capped table, continuation, post-capped weight, post-weight surface-table, bounded weight, four current component-scale refits, selected current gas-pressure component scan refit, gas-pressure continuation refit, weighted gas-pressure continuation refit, and high-weight gas-pressure continuation refit |
| 63 | 32 | 31 | true | 0.299827 | 0.999422 | toa_forcing | official ecCKD 32x31 leave-one-out g23 support with exact boundary-polished quadrature weights |
| 64 | 32 | 32 | true | 0.0140335 | 0.0467785 | surface_forcing | size scan: even_select |

## Published Inventory

| File | Kind | Bands | G-points |
|---|---|---:|---:|
| `ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc` | longwave | 1 | 32 |
| `ecckd-1.0_sw_climate_rgb-32b_ckd-definition.nc` | shortwave | 5 | 32 |
| `ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc` | longwave | 13 | 64 |
| `ecckd-1.2_sw_climate_window-64b_ckd-definition.nc` | shortwave | 19 | 64 |
| `ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc` | shortwave | 5 | 32 |
| `ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc` | shortwave | 44 | 96 |
