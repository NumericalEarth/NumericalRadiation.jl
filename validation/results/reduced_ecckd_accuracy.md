# Reduced ecCKD Accuracy

Status: **passed**

Reference scope: clean ecCKD cloudless/no-aerosol tropical and RCEMIP-style cases.

| ng_lw | ng_sw | Method | Passed | Worst TOA forcing error | Worst surface forcing error |
|---:|---:|---|---:|---:|---:|
| 32 | 32 | official ecCKD 32x32 baseline without shortwave reduction | true | 0.00806326591942 W m^-2 | 0.0140334027602 W m^-2 |

Only the published official ecCKD path is tracked here. The frozen greedy-era reduced diagnostics are recorded in `validation/FROZEN_DIAGNOSTICS.md`; new band-count schemes only count when produced by the recovered training pipeline.
