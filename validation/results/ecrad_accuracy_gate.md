# ecRad Accuracy Gate

Status: **missing_candidate_outputs**

This report applies hard acceptance thresholds to official ecCKD ecRad reference variables and `radiative_heating_*` candidate variables in the same NetCDF files. It does not run ecRad.

Hard gate scope: `official_ecCKD_hard_gate`. Legacy non-ecCKD references remain diagnostics and do not control this pass/fail status.

| Case | Status | Passed | Path |
|---|---|---:|---|
| ecckd_clear_sky_tropical_column | missing_candidate_outputs | false | `validation/reference/ecrad/ecckd_clear_sky_tropical_column.nc` |
| ecckd_all_sky_tropical_column | passed | true | `validation/reference/ecrad/ecckd_all_sky_tropical_column.nc` |
| ecckd_rcemip_style_column_subset | missing_candidate_outputs | false | `validation/reference/ecrad/ecckd_rcemip_style_column_subset.nc` |

## Variable Thresholds

| Variable | Candidate variable | RMSE threshold | Max abs threshold |
|---|---|---:|---:|
| `lw_up` | `radiative_heating_lw_up` | 1 W m^-2 | 5 W m^-2 |
| `lw_down` | `radiative_heating_lw_down` | 1 W m^-2 | 5 W m^-2 |
| `sw_up` | `radiative_heating_sw_up` | 1 W m^-2 | 5 W m^-2 |
| `sw_down` | `radiative_heating_sw_down` | 1 W m^-2 | 5 W m^-2 |
| `heating_rate` | `radiative_heating_heating_rate` | 0.05 K day^-1 | 0.5 K day^-1 |

## Boundary Net-Flux Thresholds

| Metric | Boundary | Max abs threshold |
|---|---|---:|
| TOA forcing abs error | first interface | 0.3 W m^-2 |
| Surface forcing abs error | last interface | 0.3 W m^-2 |

A file must include the ecRad variables from `validation/ecrad_reference_manifest.jl` and matching candidate variables named `radiative_heating_lw_up`, `radiative_heating_lw_down`, `radiative_heating_sw_up`, `radiative_heating_sw_down`, and `radiative_heating_heating_rate`.

## Diagnostic Cases Outside This Hard Gate

| Case | Path |
|---|---|
| clear_sky_tropical_column | `validation/reference/ecrad/clear_sky_tropical_column.nc` |
| all_sky_tropical_column | `validation/reference/ecrad/all_sky_tropical_column.nc` |
| rcemip_style_column_subset | `validation/reference/ecrad/rcemip_style_column_subset.nc` |
