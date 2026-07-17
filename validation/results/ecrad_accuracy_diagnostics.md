# ecRad Accuracy Diagnostics

Gate status: **missing_candidate_outputs**

This report ranks current `radiative_heating_*` errors by threshold exceedance. It is diagnostic only; the hard pass/fail source of truth remains `validation/ecrad_accuracy_gate.jl`.

Failed metric count: 24

## Case Summary

| Case | Failed metrics | Worst threshold ratio |
|---|---:|---:|
| ecckd_clear_sky_tropical_column | 12 | missing |
| ecckd_all_sky_tropical_column | 0 | 0.387294 |
| ecckd_rcemip_style_column_subset | 12 | missing |

## Worst Metrics

| Case | Metric | Value | Threshold | Ratio |
|---|---|---:|---:|---:|
| ecckd_all_sky_tropical_column | `toa_forcing_abs_error` | 0.116188256575 W m^-2 | 0.3 W m^-2 | 0.387294 |
| ecckd_all_sky_tropical_column | `heating_rate_max_abs` | 0.0768932793236 K day^-1 | 0.5 K day^-1 | 0.153787 |
| ecckd_all_sky_tropical_column | `heating_rate_rmse` | 0.00575848422228 K day^-1 | 0.05 K day^-1 | 0.11517 |
| ecckd_all_sky_tropical_column | `surface_forcing_abs_error` | 0.0128536244561 W m^-2 | 0.3 W m^-2 | 0.0428454 |
| ecckd_all_sky_tropical_column | `lw_up_rmse` | 0.0375781506742 W m^-2 | 1 W m^-2 | 0.0375782 |
| ecckd_all_sky_tropical_column | `lw_up_max_abs` | 0.147512483745 W m^-2 | 5 W m^-2 | 0.0295025 |
| ecckd_all_sky_tropical_column | `sw_up_rmse` | 0.00373486170379 W m^-2 | 1 W m^-2 | 0.00373486 |
| ecckd_all_sky_tropical_column | `sw_down_rmse` | 0.00327132394712 W m^-2 | 1 W m^-2 | 0.00327132 |
| ecckd_all_sky_tropical_column | `lw_down_rmse` | 0.00180318365204 W m^-2 | 1 W m^-2 | 0.00180318 |
| ecckd_all_sky_tropical_column | `sw_down_max_abs` | 0.00861447146133 W m^-2 | 5 W m^-2 | 0.00172289 |
| ecckd_all_sky_tropical_column | `lw_down_max_abs` | 0.00735432408447 W m^-2 | 5 W m^-2 | 0.00147086 |
| ecckd_all_sky_tropical_column | `sw_up_max_abs` | 0.00687483939132 W m^-2 | 5 W m^-2 | 0.00137497 |
