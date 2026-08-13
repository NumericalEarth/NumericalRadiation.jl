# Gate-4 G3 scoped actual-input preflight

Status: **g3_scoped_preflight_ready**

input manifest only; no optimizer, LBL, objective, floor, or recovery computation; nothing submitted.

| Gate | Result |
|---|---|
| eval2_training_both_pair | passed |
| expected_sets_match_pinned_scripts | passed |
| fixtures | passed |
| fp_shim_so_hash | passed |
| g2d_commit_ancestry | passed |
| g2d_completion_ledger_green | passed |
| g2d_ledger_source_pin | passed |
| g2d_sbatch_pin_and_validator | passed |
| lw_gpoints | passed |
| lw_init | passed |
| lw_optimize_binary | passed |
| lw_training_fluxes_20 | passed |
| no_idealized_dependency | passed |
| sw_copies_byte_identical | passed |
| sw_gpoints_symlink | passed |
| sw_init | passed |
| sw_optimize_binary | passed |
| sw_training_fluxes_16 | passed |

Inventory: 46/46 inputs present; Eval2 readiness is FAIL-CLOSED (ledger + size/sha/schema/copy gates; no waiting state).

Scope: gates ONLY on inputs the pinned optimizer invocation actually reads (input=, gpointfile=, append_path training/work flux dirs) plus binaries and the FP-shim requirement; deliberately independent of idealized/ and the broad ckdmip_training_data_preflight layout, per the quota-recovery runbook's binding Path-D requirement

Provenance: branch `glw/gate4-recovery`, generated_from_head `7735a03` (pre-own-commit).
