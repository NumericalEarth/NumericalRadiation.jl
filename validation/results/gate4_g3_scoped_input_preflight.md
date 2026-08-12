# Gate-4 G3 scoped actual-input preflight

Status: **g3_scoped_preflight_waiting_for_eval2**

input manifest only; no optimizer, LBL, objective, floor, or recovery computation; nothing submitted.

| Gate | Result |
|---|---|
| eval2_training_both_pair | waiting |
| fp_shim_required_noted | passed |
| lw_gpoints | passed |
| lw_init | passed |
| lw_optimize_binary | passed |
| lw_training_fluxes_20 | passed |
| no_idealized_dependency | passed |
| sw_gpoints_symlink | passed |
| sw_init | passed |
| sw_optimize_binary | passed |
| sw_training_fluxes_16 | passed |

Inventory: 42/45 inputs present (missing items are the eval2 rel-415 pair pending G2c/G2d).

Scope: gates ONLY on inputs the pinned optimizer invocation actually reads (input=, gpointfile=, append_path training/work flux dirs) plus binaries and the FP-shim requirement; deliberately independent of idealized/ and the broad ckdmip_training_data_preflight layout, per the quota-recovery runbook's binding Path-D requirement

Provenance: branch `glw/gate4-recovery`, generated_from_head `57fbd2c` (pre-own-commit).
