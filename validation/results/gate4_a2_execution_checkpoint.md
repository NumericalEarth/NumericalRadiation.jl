# Gate-4 A2 execution checkpoint — HISTORICAL (executed as job 4082; attempt 1 = job 4079 on an earlier script)

Status: **a2_execution_checkpoint_historical_executed**

HISTORICAL post-execution record: the generated sbatch was executed as job 4082 (submission-ledger-verified; attempt 1 was 4079 on an earlier script revision); the executed script is preserved, never regenerated; read-only with respect to execution artifacts (this unit writes only its own JSON/MD); nothing executed or submitted.

| Gate | Result |
|---|---|
| attempt1_distinct_script_verified | passed |
| completion_marker_verified | passed |
| config_copy_patched_not_env_only | passed |
| contention_policy_recorded | passed |
| headnode_refusal_guard | passed |
| job_id_4082_verified | passed |
| later_disposition_verified | passed |
| ledger_candidate_shas_wellformed | passed |
| merge_reorder_find_only | passed |
| no_mutation_of_4078_workcopy | passed |
| prerequisite_loader_fixture_tests | passed |
| preserved_sbatch_matches_submission_ledger | passed |
| rayleigh_overlay_input_artifact_verified | passed |
| rayleigh_overlay_provisioned | passed |
| sbatch_not_regenerated_or_submitted | passed |
| sbatch_preserved_not_regenerated | passed |
| stage1_merge_before_reorder | passed |
| submission_ledger_completed_verified | passed |
| target_tolerances_narrowed | passed |
| two_gpoint_candidates_match_submission_ledger | passed |
| workdir_quarantined | passed |

Executed batch script (preserved; byte-verified against the submission ledger's recorded sha): `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_a2_dryrun.sbatch` sha256 `adeb59a6ea91744c58d13e37ce964fd7a834c39b1346391245304936e7538649`

Ledger-verified outcome: COMPLETED, log marker 'A2 done rc=0' at 2026-07-19T08:16:07Z; all stages green (stage-0 preflight, LW/SW merges, 7 LW + 9 SW reorder outputs, LW/SW find_g_points)

Exactly TWO g-point candidates (find_g_points only; no create_lut output is attributable to 4082):
- [lw] `ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5` sha256 `c96e64927c4d0d706d35f376be59f17517dae6d6d7041d0791d164641a017a3e`
- [sw] `ecckd-1.2_sw_gpoints_climate_rgb-tol0.047.h5` sha256 `13dd686acd0c3ca2201775270f876ce3e3a326576b58b24323b5ce95659b9b57`

Rayleigh overlay (input-generation artifact, NOT a candidate): sha256 `36ad9c9a958aeae60f6bef6115f83ec4e1f49e193b00cf1cf9049b5f66ebdad2`

Later disposition (separately verified): follow-on exact-reproduction proof EXECUTED via the proof-driver chain (job 4091): strict verdict a2_candidates_sensitivity_only_not_promotable; subsequently Greg-authorized Option B (option_b_adopted_candidates_promoted) accepted the two candidates as structure sources for ACCEPTANCE-INIT SELECTION (it did not alter the strict finding's record)

Follow-on proof plan (at-checkpoint text): g-counts 32/32; gpoint_fraction and band arrays elementwise EXACT vs published; any mismatch -> sensitivity-only, no floor.

Provenance: branch `glw/gate4-recovery`, generated_from_head `06681c4` (pre-own-commit).
