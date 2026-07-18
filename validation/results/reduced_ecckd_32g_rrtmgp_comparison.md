# 32-g ecCKD RRTMGP Comparison

Status: **passed**

- production target: official ecCKD 32-g gas optics
- frozen diagnostic: greedy-era reduced candidates (16-g canonical chain, 32x31 boundary polish) are frozen as evidence in validation/FROZEN_DIAGNOSTICS.md; no reduced row is tracked here
- RRTMGP role: direct CKD compatibility baseline, not line-by-line truth
- candidate source: radiative_heating_* NetCDF variables for official ecCKD 32/32
- official 32-g ecCKD hard gate passed: true
- RRTMGP comparison emitted: true

| Case | Columns | Official ecCKD flux RMSE | Official ecCKD heating RMSE | Official RRTMGP flux RMSE | Official RRTMGP heating RMSE |
|---|---:|---:|---:|---:|---:|
| ecckd_clear_sky_tropical_column | 10 | 0 | 0 | 152.024699952 | 0.000526827534315 |
| ecckd_rcemip_style_column_subset | 32 | 0 | 0 | 108.88158071 | 0.000361528610703 |
| ecckd_all_sky_tropical_column_clear_projection | 10 | 0.058640145211 | 6.93902562808e-08 | 153.585706296 | 0.000526321078334 |

The official 32-g ecCKD production target is accepted against the ecRad/ecCKD hard gate. RRTMGP is reported as a compatibility comparison between CKD models, not as the absolute-accuracy reference.
