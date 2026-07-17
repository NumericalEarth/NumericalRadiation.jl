# ecRad Cloudless Accuracy Gate

Status: **missing_candidate_outputs**

This focused hard gate compares only cloudless/no-aerosol reference cases. It is the first required accuracy step before the full all-sky ecRad gate.

| Case | Status | Passed | Path |
|---|---|---:|---|
| ecckd_clear_sky_tropical_column | missing_candidate_outputs | false | `validation/reference/ecrad/ecckd_clear_sky_tropical_column.nc` |
| ecckd_rcemip_style_column_subset | missing_candidate_outputs | false | `validation/reference/ecrad/ecckd_rcemip_style_column_subset.nc` |

## Scope

- Included cases: `ecckd_clear_sky_tropical_column`, `ecckd_rcemip_style_column_subset`.
- Excluded here: all-sky cloud liquid/ice optics, aerosol optics, scattering, overlap, and McICA-style solver semantics.
- Thresholds are the same hard flux, heating-rate, TOA forcing, and surface forcing thresholds used by `validation/ecrad_accuracy_gate.jl`.

This gate must pass before reduced-model accuracy or all-sky convention work can close the `/goal`.

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
