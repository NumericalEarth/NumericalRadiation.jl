# Reduced ecCKD Shortwave Subset Search

Status: **failed_threshold**

Search objective: `flux_boundary_and_shortwave_heating_rate`

Selected shortwave g-points: `1, 3, 7, 9, 10, 11, 13, 15, 17, 19, 21, 25, 27, 29, 30, 31`

| Case | Passed | TOA forcing error | Surface forcing error | SW up RMSE | SW down RMSE | Heating RMSE | Heating max |
|---|---:|---:|---:|---:|---:|---:|---:|
| ecckd_clear_sky_tropical_column | false | 43.6453707645 W m^-2 | 83.7043553349 W m^-2 | 19.2127163769 W m^-2 | 34.8521101862 W m^-2 | 3.3021084947 K day^-1 | 14.0513914814 K day^-1 |
| ecckd_rcemip_style_column_subset | false | 43.6453707645 W m^-2 | 83.7043553349 W m^-2 | 12.6483783558 W m^-2 | 23.1915124672 W m^-2 | 2.66311973074 K day^-1 | 14.0513914814 K day^-1 |

## Weighted Subset Search

Selected shortwave g-points: `1, 3, 7, 9, 10, 11, 13, 15, 17, 19, 21, 25, 27, 29, 30, 31`

Boundary weight: `30`

| Case | Passed | TOA forcing error | Surface forcing error | SW up RMSE | SW down RMSE | Heating RMSE | Heating max |
|---|---:|---:|---:|---:|---:|---:|---:|
| ecckd_clear_sky_tropical_column | false | 77.4260134556 W m^-2 | 389.253432713 W m^-2 | 43.5318046083 W m^-2 | 287.119433792 W m^-2 | 1072.16546361 K day^-1 | 10499.5661277 K day^-1 |
| ecckd_rcemip_style_column_subset | false | 297.637489431 W m^-2 | 412.936720649 W m^-2 | 95.042047605 W m^-2 | 232.291865155 W m^-2 | 870.812182833 K day^-1 | 10499.5661277 K day^-1 |

A failed status means this deterministic subset search improved the current 16-g shortwave reduction but still does not satisfy the hard clean ecCKD thresholds. The current failure is useful evidence that simple subset selection is not enough; a real ecCKD reduction/optimization method is still required.

## Search History

| Pass | Approximate normalized score | Indices |
|---:|---:|---|
| 0 | 0.174537395935 | `1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31` |
| 1 | 0.174537395935 | `1, 3, 5, 7, 9, 10, 11, 13, 15, 17, 19, 21, 25, 27, 29, 31` |
| 2 | 0.174537395935 | `1, 3, 7, 9, 10, 11, 13, 15, 17, 19, 21, 25, 27, 29, 30, 31` |
| 3 | 0.174537395935 | `1, 3, 7, 9, 10, 11, 13, 15, 17, 19, 21, 25, 27, 29, 30, 31` |

## Boundary-Weight Trials

| Boundary weight | Approximate normalized score | Indices |
|---:|---:|---|
| 1 | 0.174537395935 | `1, 3, 7, 9, 10, 11, 13, 15, 17, 19, 21, 25, 27, 29, 30, 31` |
| 3 | 0.174537395935 | `1, 3, 7, 9, 10, 11, 13, 15, 17, 19, 21, 25, 27, 29, 30, 31` |
| 10 | 0.174537395935 | `1, 3, 7, 9, 10, 11, 13, 15, 17, 19, 21, 25, 27, 29, 30, 31` |
| 30 | 0.174537395935 | `1, 3, 7, 9, 10, 11, 13, 15, 17, 19, 21, 25, 27, 29, 30, 31` |

## Full-Fit Pruning Trial

Selected shortwave g-points: `1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16`

Boundary weight: `30`

| Case | Passed | TOA forcing error | Surface forcing error | SW up RMSE | SW down RMSE | Heating RMSE | Heating max |
|---|---:|---:|---:|---:|---:|---:|---:|
| ecckd_clear_sky_tropical_column | false | 73.8562070435 W m^-2 | 368.580551723 W m^-2 | 52.5049417479 W m^-2 | 153.268856288 W m^-2 | 8.0620551023 K day^-1 | 26.818262564 K day^-1 |
| ecckd_rcemip_style_column_subset | false | 184.803811019 W m^-2 | 368.580551723 W m^-2 | 63.1684981671 W m^-2 | 101.526080662 W m^-2 | 6.47014534851 K day^-1 | 26.818262564 K day^-1 |

## Hard-Gate Max-Norm Weight Trial

Selected shortwave g-points: `1, 3, 7, 9, 10, 11, 13, 15, 17, 19, 21, 25, 27, 29, 30, 31`

Source topology: `official-weight greedy subset`

Approximate normalized hard-gate objective: `0.182266517251`

| Case | Passed | TOA forcing error | Surface forcing error | SW up RMSE | SW down RMSE | Heating RMSE | Heating max |
|---|---:|---:|---:|---:|---:|---:|---:|
| ecckd_clear_sky_tropical_column | false | 43.6453707645 W m^-2 | 83.7043553349 W m^-2 | 19.2127163769 W m^-2 | 34.8521101862 W m^-2 | 3.3021084947 K day^-1 | 14.0513914814 K day^-1 |
| ecckd_rcemip_style_column_subset | false | 43.6453707645 W m^-2 | 83.7043553349 W m^-2 | 12.6483783558 W m^-2 | 23.1915124672 W m^-2 | 2.66311973074 K day^-1 | 14.0513914814 K day^-1 |
