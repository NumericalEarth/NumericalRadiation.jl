# 32-g ecCKD RRTMGP Comparison

Status: **passed**

- production target: official ecCKD 32-g gas optics and canonical 32x31 boundary-polished reduced model
- frozen diagnostic: 16-g canonical model remains a failing diagnostic; 32x31 boundary-polished model is the current passing reduced row
- RRTMGP role: direct CKD compatibility baseline, not line-by-line truth
- candidate source: radiative_heating_* NetCDF variables for official ecCKD 32/32 plus live recomputation of the canonical 32x31 boundary-polished reduced model
- official 32-g ecCKD hard gate passed: true
- reduced 32x31 ecCKD hard gate passed: true
- RRTMGP comparison emitted: true

| Case | Columns | Official ecCKD flux RMSE | Official ecCKD heating RMSE | Official RRTMGP flux RMSE | Official RRTMGP heating RMSE | Reduced ecCKD flux RMSE | Reduced ecCKD heating RMSE | Reduced RRTMGP flux RMSE | Reduced RRTMGP heating RMSE |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| ecckd_clear_sky_tropical_column | 10 | 0 | 0 | 152.024699952 | 0.000526827534315 | 0.0743011580095 | 5.76083741037e-07 | 152.016127098 | 0.000526810290982 |
| ecckd_rcemip_style_column_subset | 32 | 0 | 0 | 108.88158071 | 0.000361528610703 | 0.077367620869 | 5.76182161707e-07 | 108.880639613 | 0.000361479903254 |
| ecckd_all_sky_tropical_column_clear_projection | 10 | 0.058640145211 | 6.93902562808e-08 | 153.585706296 | 0.000526321078334 | 8.36475952417 | 2.73063346638e-06 | 152.002929918 | 0.000526801608443 |

The official 32-g ecCKD production target and the canonical 32x31 boundary-polished reduced model are accepted against the ecRad/ecCKD hard gate. RRTMGP is reported as a compatibility comparison between CKD models, not as the absolute-accuracy reference.
