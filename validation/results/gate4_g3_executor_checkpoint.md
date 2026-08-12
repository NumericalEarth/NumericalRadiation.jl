# Gate-4 G3 executor checkpoint (dry-run)

Status: **g3_executor_waiting_for_eval2**

script generation only; nothing submitted or executed; no objective, floor, or recovery computation in this unit.

| Gate | Result |
|---|---|
| lw_flock_single_flight | passed |
| lw_gate_code_pinned | passed |
| lw_headnode_refusal | passed |
| lw_input_hash_gate | passed |
| lw_mode_list | passed |
| lw_optimize_only | passed |
| lw_quota_health_gate | passed |
| lw_readonly_gates_before_lock | passed |
| lw_runtime_ready_preflight | passed |
| lw_shim_wrapper | passed |
| lw_source_pins | passed |
| lw_stale_output_refusal | passed |
| lw_training_both_sed | passed |
| quota_health_fixture_tests | passed |
| sbatch_written_not_submitted | passed |
| scoped_preflight_prerequisite | waiting |
| sw_flock_single_flight | passed |
| sw_gate_code_pinned | passed |
| sw_headnode_refusal | passed |
| sw_input_hash_gate | passed |
| sw_mode_list | passed |
| sw_optimize_only | passed |
| sw_quota_health_gate | passed |
| sw_readonly_gates_before_lock | passed |
| sw_runtime_ready_preflight | passed |
| sw_script_version_identity | passed |
| sw_shim_wrapper | passed |
| sw_source_pins | passed |
| sw_stale_output_refusal | passed |
| sw_training_both_sed | passed |
| token_gated_submit | passed |

Generated (unsubmitted): `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_g3_lw_optimizer.sbatch`, `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_g3_sw_optimizer.sbatch`

Authorization: token `g3_recovery_go` + scoped preflight ready + review.

final/target <= 1.05, weight L1 <= 0.02, OD log-RMSE <= 0.02 vs published models -- evaluated by a separate post-run comparison unit, never inside the executor

Provenance: branch `glw/gate4-recovery`, generated_from_head `a5316b7` (pre-own-commit).
