# Gate-4 SW optical-depth reconstruction parity

Status: **sw_od_parity_passed**

read-only SW OD reconstruction parity (per-gas raw, total raw, clamped-vs-emitted, raw negativity); authorizes (or refuses) SW binding of the Gate-2 true-OD metric; no optimizer, objective-value, floor, or recovery claims.

Per-gas RAW (unclamped) OD parity vs pinned run_ckd smoke reference, Float32 storage precision (abs floor 1.0e-9, rel tol 1.0e-6):

| Gas | conc code | max_abs | max_rel (above abs floor) | signed bias | gate |
|---|---|---|---|---|---|
| composite | 0 | 1.4817620130891385e-8 | 5.668876750666911e-8 | 0.007824074074074074 | passed |
| h2o | 2 | 4.7568398287012315e-7 | 5.8662862409280235e-8 | -0.002835249042145594 | passed |
| o3 | 1 | 1.1910219344102302e-7 | 5.733067860628769e-8 | 0.003111111111111111 | passed |
| co2 | 1 | 2.383849997400489e-7 | 5.883617470808254e-8 | 0.009333333333333334 | passed |
| ch4 | 3 | 3.63748617272959e-12 | 0.0 | 0.0039673278879813305 | passed |
| n2o | 3 | 2.903624075119987e-11 | 0.0 | -0.004717078295260263 | passed |

## Totals (ex-rayleigh)

| Term | max_abs | max_rel (above abs floor) | signed bias | gate |
|---|---|---|---|---|
| raw total vs ref per-gas sum | 4.778716728992549e-7 | 5.876539197068577e-8 | 0.002962962962962963 | passed |
| max(raw,0) vs emitted optical_depth | 4.7651509227364386e-7 | 5.909995467904316e-8 | -0.0012268518518518518 | passed |

Raw negative-total findings (gate passed): ours 0/86400 negative (min 8.351749835374495e-11); reference per-gas sum 0 negative (min 8.351750042413786e-11); sign mismatches beyond the Float32 band: 0 (worst excess 0.0); min-agreement diagnostic: true.

Rayleigh (informational only, excluded from parity targets and totals): max_abs 7.3994360638707235e-9, max_rel 5.819462964405937e-8.

Provenance: branch `glw/gate4-recovery`, generated_from_head `a247608` (pre-own-commit); reference: pinned run_ckd SW smoke output; definition `ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc`.
