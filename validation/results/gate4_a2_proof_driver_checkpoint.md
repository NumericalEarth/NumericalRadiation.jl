# Gate-4 A2 proof-driver checkpoint (dry-run)

Status: **a2_proof_driver_ready_awaiting_go**

dry-run script generation only; nothing submitted; no create_lut, comparison, objective, floor, or acceptance execution; submission requires explicit review/go per the standing protocol.

| Gate | Result |
|---|---|
| candidate_identity_pinned | passed |
| candidates_hashed | passed |
| create_lut_only | passed |
| headnode_refusal_guard | passed |
| no_execution_in_this_unit | passed |
| raw_outputs_absent_preproof | passed |
| raw_outputs_declared | passed |
| sbatch_refuses_stale_raw_outputs | passed |
| sbatch_written_not_submitted | passed |
| scaffold_ready_required | passed |
| testcopy_reused_not_recreated | passed |

Generated (unsubmitted) proof batch script: `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_a2_proof_dryrun.sbatch`

Pinned candidate identities:
- [lw] `ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5` sha256 `c96e64927c4d0d706d35f376be59f17517dae6d6d7041d0791d164641a017a3e`
- [sw] `ecckd-1.2_sw_gpoints_climate_rgb-tol0.047.h5` sha256 `13dd686acd0c3ca2201775270f876ce3e3a326576b58b24323b5ce95659b9b57`

Expected raw outputs: `ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc`, `ecckd-1.2_sw_raw-ckd-definition_climate_rgb-tol0.047.nc`

Version-skew note: pre-registered mismatch risk: published LW32 is ecckd-1.0, published SW32 is ecckd-1.4, pinned rerun toolchain is ecckd-1.2; content comparisons are name-agnostic but algorithmic drift across versions is a plausible mismatch cause; any mismatch -> sensitivity-only per the scaffold verdict rule

Provenance: branch `glw/gate4-recovery`, generated_from_head `2fb10c9` (pre-own-commit).
