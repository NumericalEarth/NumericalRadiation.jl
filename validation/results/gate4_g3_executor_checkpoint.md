# Gate-4 G3 executor checkpoint (dry-run)

Status: **g3_executor_ready_awaiting_go**

script generation only; nothing submitted or executed; no objective, floor, or recovery computation in this unit.

| Gate | Result |
|---|---|
| failure_ledger_pin_live | passed |
| lw_bash_syntax | passed |
| lw_child_status_surfacing | passed |
| lw_config_asserts | passed |
| lw_failure_ledger_pinned | passed |
| lw_final_only_publish | passed |
| lw_flock_single_flight | passed |
| lw_gate_code_pinned | passed |
| lw_headnode_refusal | passed |
| lw_input_hash_gate | passed |
| lw_input_manifest_counts | passed |
| lw_input_size_gate | passed |
| lw_loader_resolution_gate | passed |
| lw_mode_list | passed |
| lw_netlib_preload_order | passed |
| lw_netlib_sha_pins | passed |
| lw_optimize_only | passed |
| lw_private_runroot | passed |
| lw_private_workdir | passed |
| lw_quota_health_gate | passed |
| lw_readonly_gates_before_lock | passed |
| lw_runroot_staging | passed |
| lw_runtime_ready_preflight | passed |
| lw_shim_wrapper | passed |
| lw_source_pins | passed |
| lw_stale_output_refusal | passed |
| lw_training_both_sed | passed |
| lw_wrapper_in_runroot | passed |
| netlib_pins_live | passed |
| preflight_loader_fixture_tests | passed |
| preflight_source_pin | passed |
| quota_health_fixture_tests | passed |
| reviewed_commit_ancestry | passed |
| sbatch_written_not_submitted | passed |
| scoped_preflight_prerequisite | passed |
| sw_bash_syntax | passed |
| sw_child_status_surfacing | passed |
| sw_config_asserts | passed |
| sw_failure_ledger_pinned | passed |
| sw_final_only_publish | passed |
| sw_flock_single_flight | passed |
| sw_gate_code_pinned | passed |
| sw_headnode_refusal | passed |
| sw_input_hash_gate | passed |
| sw_input_manifest_counts | passed |
| sw_input_size_gate | passed |
| sw_loader_resolution_gate | passed |
| sw_mode_list | passed |
| sw_netlib_preload_order | passed |
| sw_netlib_sha_pins | passed |
| sw_optimize_only | passed |
| sw_private_runroot | passed |
| sw_private_workdir | passed |
| sw_quota_health_gate | passed |
| sw_readonly_gates_before_lock | passed |
| sw_runroot_staging | passed |
| sw_runtime_ready_preflight | passed |
| sw_script_version_identity | passed |
| sw_shim_wrapper | passed |
| sw_source_pins | passed |
| sw_stale_output_refusal | passed |
| sw_training_both_sed | passed |
| sw_wrapper_in_runroot | passed |
| token_gated_submit | passed |

Generated (unsubmitted): `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_g3_lw_optimizer.sbatch` (28654 B, sha256 ccfa0d7c79b45aa203bf7c21582e13ea8eb4ebddc2da20defb4347bdb38c713e), `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_g3_sw_optimizer.sbatch` (26638 B, sha256 464fe754e60f7581585bc096ac745932175c9abd4607e1b1364ae9fdc635228a)

Input manifests: LW 31 entries, SW 27 entries (path/size/sha/role in JSON; every entry embedded as runtime sha+size pins).

Authorization: token `g3_recovery_go` + review; READY is the only generation state.

FIVE canonical thresholds, evaluated by separate post-run runners, never inside the executor: (1) final/target objective ratio <= 1.05; (2) weight rel-L1 <= 0.02; (3) true OD log-RMSE <= 0.02; (4) forcing regression margin <= 0.03 W/m2; (5) heating-RMSE regression margin <= 0.005 K/day (aggregation semantics pending ruling)

Provenance: branch `glw/gate4-recovery`, generated_from_head `8fc6cec` (pre-own-commit).
