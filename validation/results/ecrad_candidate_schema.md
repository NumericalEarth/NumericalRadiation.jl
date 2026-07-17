# ecRad Candidate Schema Check

Status: **missing_or_mismatched_candidate_variables**

This report checks that each ecRad reference variable used by the hard accuracy gate has a matching `radiative_heating_*` candidate variable with the same array shape. It does not validate numerical accuracy.

| Case | Status | Passed | Path |
|---|---|---:|---|
| clear_sky_tropical_column | missing_or_mismatched_candidate_variables | false | `validation/reference/ecrad/clear_sky_tropical_column.nc` |
| all_sky_tropical_column | missing_or_mismatched_candidate_variables | false | `validation/reference/ecrad/all_sky_tropical_column.nc` |
| ecckd_clear_sky_tropical_column | missing_or_mismatched_candidate_variables | false | `validation/reference/ecrad/ecckd_clear_sky_tropical_column.nc` |
| ecckd_all_sky_tropical_column | passed | true | `validation/reference/ecrad/ecckd_all_sky_tropical_column.nc` |
| rcemip_style_column_subset | missing_or_mismatched_candidate_variables | false | `validation/reference/ecrad/rcemip_style_column_subset.nc` |
| ecckd_rcemip_style_column_subset | missing_or_mismatched_candidate_variables | false | `validation/reference/ecrad/ecckd_rcemip_style_column_subset.nc` |

## Candidate Variables

| Reference variable | Candidate variable | Shape rule |
|---|---|---|
| `lw_up` | `radiative_heating_lw_up` | exact shape match |
| `lw_down` | `radiative_heating_lw_down` | exact shape match |
| `sw_up` | `radiative_heating_sw_up` | exact shape match |
| `sw_down` | `radiative_heating_sw_down` | exact shape match |
| `heating_rate` | `radiative_heating_heating_rate` | exact shape match |
