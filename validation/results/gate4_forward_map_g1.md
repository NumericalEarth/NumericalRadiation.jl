# Gate-4 forward map G1 (increment 1: per-gas OD parity)

Status: **g1_od_and_lw_flux_parity_passed**

term-resolved OD and LW flux/derived-heating parity; no objective-value, floor, or recovery claims; SW parity limited to direct-down in a later increment.

| Gas | max_abs | max_rel (above abs floor) | signed bias | gate |
|---|---|---|---|---|
| cfc11 | 2.884306920906965e-11 | 0.0 | -0.0018181818181818182 | passed |
| cfc12 | 1.455136873626181e-11 | 0.0 | 0.002108262108262108 | passed |
| ch4 | 3.7093903365592595e-9 | 5.808530289395586e-8 | 0.002215999025934494 | passed |
| co2 | 7.5982707699040475e-6 | 5.931739946656874e-8 | -0.0005095541401273885 | passed |
| composite | 4.764991974326449e-7 | 5.9199810344545984e-8 | 0.001574074074074074 | passed |
| h2o | 1.4010364736805059e-5 | 5.923122202435551e-8 | 0.0008796296296296296 | passed |
| n2o | 5.81878469019248e-11 | 0.0 | -0.005396732788798133 | passed |
| o3 | 1.1829560353504576e-7 | 5.7952849428986206e-8 | 0.0003935185185185185 | passed |

Provenance: branch `glw/gate4-recovery`, generated_from_head `a1a0a68` (pre-own-commit); reference: pinned run_ckd smoke output.
