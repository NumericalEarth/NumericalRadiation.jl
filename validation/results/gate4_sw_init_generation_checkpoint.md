# Gate-4 SW init-generation checkpoint

Status: **sw_init_checkpoint_historical_executed**

READ-ONLY HISTORICAL VERIFICATION: generation already executed; this run verifies the accepted scaled output against the reviewed init provenance ledger and preserves the committed script; nothing generated or submitted; no optimize_lut, objective, floor, or recovery computation.

Authorization: Option B decision record (Greg, 2026-07-20); its recorded next step was EXECUTED (see historical_verification)

| Gate | Result |
|---|---|
| ckdmip_dir_localized | passed |
| ckdmip_sw_executable_preflight | passed |
| headnode_refusal_guard | passed |
| init_ledger_historical_evidence | passed |
| input_identity_pinned | passed |
| lbl_reference_hash_pinned | passed |
| lbl_reference_spec_matches_manifest | passed |
| option_b_prerequisite | passed |
| preload_scoped_to_scale_lut_only | passed |
| prerequisite_loader_fixture_tests | passed |
| promoted_sw_raw_verified | passed |
| sbatch_preserved_identical | passed |
| sbatch_written_not_submitted | passed |
| scale_lut_binary_hash_pinned | passed |
| scale_lut_only | passed |
| scaled_output_absent | historical_executed |
| shim_source_embedded_and_minimal | passed |
| stale_output_refusal | passed |
| v14_scale_lut_binary_present | passed |

NO script generated this run (mode historical); the file at `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_sw_init_dryrun.sbatch` is preserved historical output of an earlier run, not current.

Historical verification: live scaled output sha `74d8be65226f081f3d2882520ab374ed102d73cc3dd43bb2fa7c5a5c27602d74` == ledger-recorded acceptance sha (init provenance ledger, acceptance_inits_complete).

Verified executed output: SW acceptance init `ecckd-1.4_sw_scaled-ckd-definition_climate_rgb-tol0.047.nc` (ledger path-bound sha match); LBL reference `ckdmip_mmm_sw_fluxes-raw_present_1.h5` was its recorded scaling reference.

Provenance: branch `glw/gate4-recovery`, generated_from_head `c1d64c1` (pre-own-commit).
