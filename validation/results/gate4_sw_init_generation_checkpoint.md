# Gate-4 SW init-generation checkpoint

Status: **sw_init_checkpoint_ready**

script generation only; nothing submitted by this unit; scale_lut only; no optimize_lut, objective, floor, or recovery computation.

Authorization: Option B decision record (Greg, 2026-07-20); this is its recorded next step

| Gate | Result |
|---|---|
| ckdmip_dir_localized | passed |
| ckdmip_sw_executable_preflight | passed |
| headnode_refusal_guard | passed |
| input_identity_pinned | passed |
| lbl_reference_hash_pinned | passed |
| lbl_reference_spec_matches_manifest | passed |
| option_b_prerequisite | passed |
| preload_scoped_to_scale_lut_only | passed |
| promoted_sw_raw_verified | passed |
| sbatch_written_not_submitted | passed |
| scale_lut_binary_hash_pinned | passed |
| scale_lut_only | passed |
| scaled_output_absent | passed |
| shim_source_embedded_and_minimal | passed |
| stale_output_refusal | passed |
| v14_scale_lut_binary_present | passed |

Generated (unsubmitted) batch script: `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_sw_init_dryrun.sbatch`

Expected outputs: LBL reference `ckdmip_mmm_sw_fluxes-raw_present_1.h5` (MMM median col 1, present, direct-only, mu0=0.5, albedo 0.15, no Rayleigh) and SW acceptance init `ecckd-1.4_sw_scaled-ckd-definition_climate_rgb-tol0.047.nc`.

Provenance: branch `glw/gate4-recovery`, generated_from_head `2905d31` (pre-own-commit).
