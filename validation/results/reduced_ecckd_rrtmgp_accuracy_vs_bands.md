# Reduced ecCKD Accuracy vs Bands

Generated: 2026-05-28T01:41:45.268
Source artifact: `validation/results/reduced_ecckd_32g_rrtmgp_comparison.json`
Acceptance threshold: max abs CO2-doubling boundary forcing error <= 0.3 W m^-2

| model | LW g | SW g | total g | calibrated | CO2 scale | max forcing error | base flux RMSE | pass |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 32x32_calibrated | 32 | 32 | 64 | true | 1.400 | 0.143 | 3.431 | yes |
| 32x32_published | 32 | 32 | 64 | false | 1.000 | 0.461 | 2.792 | no |
| 32x64 | 32 | 64 | 96 | false | 1.000 | 0.620 | 2.904 | no |
| 64x32 | 64 | 32 | 96 | false | 1.000 | 0.265 | 3.687 | yes |
| 32x96 | 32 | 96 | 128 | false | 1.000 | 0.618 | 2.881 | no |
| 64x64 | 64 | 64 | 128 | false | 1.000 | 0.346 | 3.772 | no |
| 64x96 | 64 | 96 | 160 | false | 1.000 | 0.354 | 3.755 | no |

Best pair in this diagnostic: 32x32_calibrated with max forcing error 0.143 W m^-2.

## Scope
- Covers the published ecCKD LW/SW combinations available to `official_ecckd_definition_paths`.
- Also includes a calibrated 32x32 candidate formed by scaling LW CO2 coefficients by 1.4.
- Uses the same representative clear-sky RRTMGP comparison as `validation/results/reduced_ecckd_32g_rrtmgp_comparison.md`.
- This is a quantitative trend artifact. Passing pairs in this diagnostic: 32x32_calibrated, 64x32.
