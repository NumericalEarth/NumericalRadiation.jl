# ecCKD Teacher-Student Recovery Scan

Status: **passed**

| File | Status | Parameters | Initial loss | Final loss | Reactant | Worst log RMSE | Worst P99 relative error |
|---|---|---:|---:|---:|---|---:|---:|
| `ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc` | passed | 193344 | 0.00024991822308530507 | 1.568762111832774e-10 | passed | 1.2575276507817317e-5 | 2.343775376972281e-5 |
| `ecckd-1.0_sw_climate_rgb-32b_ckd-definition.nc` | passed | 172992 | 0.0002498636616492827 | 1.568419624147514e-10 | passed | 1.2571097109266255e-5 | 2.343559666256501e-5 |
| `ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc` | passed | 386688 | 0.0002499315122906845 | 1.5688455295263671e-10 | passed | 1.2536905174778592e-5 | 2.3706280711422934e-5 |
| `ecckd-1.2_sw_climate_window-64b_ckd-definition.nc` | passed | 345984 | 0.00024998166565541396 | 1.5691603472999055e-10 | passed | 1.225009033511529e-5 | 2.3417518605128862e-5 |
| `ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc` | passed | 172992 | 0.0002498636616492827 | 1.568419624147537e-10 | passed | 1.2571419279602349e-5 | 2.3427731855160456e-5 |
| `ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc` | passed | 518976 | 0.000249955462628674 | 1.5689958682354402e-10 | passed | 1.2230285701067969e-5 | 2.3468907725509056e-5 |

This scan applies the same perturbed-start, fixed-topology,
Enzyme-gradient teacher-student recovery gate to every published ecCKD
definition in the official data artifact.
