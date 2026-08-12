# Gate-4 A2 proof-driver checkpoint — HISTORICAL (executed as job 4091)

Status: **a2_proof_driver_historical_executed**

HISTORICAL post-execution record: the generated sbatch was executed as authorized proof job 4091 (ledger-verified, not assumed); outputs verified against the reviewed finding ledger; the executed script is preserved, never regenerated; nothing submitted or executed by this unit.

| Gate | Result |
|---|---|
| candidate_identity_pinned | passed |
| candidates_hashed | passed |
| finding_outcome_completed_rc0 | passed |
| headnode_refusal_guard | passed |
| job_id_4091_verified | passed |
| ledger_case_ids_verified | passed |
| option_b_adoption_verified | passed |
| outputs_match_4091_finding_ledger | passed |
| preserved_sbatch_matches_submission_ledger | passed |
| sbatch_preserved_not_regenerated | passed |
| sbatch_refuses_stale_raw_outputs | passed |
| scaffold_ready_required | passed |

Executed proof batch script (preserved, ledger-verified): `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_a2_proof_dryrun.sbatch`

Execution (ledger-verified): job 4091; outcome: COMPLETED rc=0 at 2026-07-20T08:20:58Z; stage-0 candidate hash checks OK for both bands; log/hash review by the Codex monitor and locally, matching; strict finding status: a2_candidates_sensitivity_only_not_promotable; Option-B record adoption + explicit supersession of the scaffold verdict verified against gate4_option_b_decision_record.
- [lw] `ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc` sha256 `ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43` -- PROMOTED to the LW acceptance init under Option B
- [sw] `ecckd-1.2_sw_raw-ckd-definition_climate_rgb-tol0.047.nc` sha256 `3308cb7a53d95935e4a931ac63fe7237154075cc968c04b06a5d8881e8137922` -- v1.2 proof output; sensitivity evidence only -- the promoted SW raw is the v1.4 R2 output (job 4096)

Pinned candidate identities:
- [lw] `ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5` sha256 `c96e64927c4d0d706d35f376be59f17517dae6d6d7041d0791d164641a017a3e`
- [sw] `ecckd-1.2_sw_gpoints_climate_rgb-tol0.047.h5` sha256 `13dd686acd0c3ca2201775270f876ce3e3a326576b58b24323b5ce95659b9b57`

Provenance: branch `glw/gate4-recovery`, generated_from_head `5725179` (pre-own-commit).
