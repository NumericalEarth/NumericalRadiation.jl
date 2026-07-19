# Gate-4 A2 execution checkpoint (dry-run)

Status: **a2_execution_checkpoint_ready**

dry-run script generation only; nothing submitted; no find_g_points/create_lut/objective/floor execution; the generated script runs merge_well_mixed + reorder + find_g_points only; submission requires explicit authorization per the standing protocol.

| Gate | Result |
|---|---|
| composite_inputs_preflight | passed |
| config_copy_patched_not_env_only | passed |
| contention_policy_recorded | passed |
| headnode_refusal_guard | passed |
| merge_reorder_find_only | passed |
| no_mutation_of_4078_workcopy | passed |
| rayleigh_overlay_provisioned | passed |
| sbatch_written_not_submitted | passed |
| stage1_merge_before_reorder | passed |
| target_tolerances_narrowed | passed |
| workdir_quarantined | passed |

Generated (unsubmitted) batch script: `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_a2_dryrun.sbatch`

Composite-input preflight: 31/32 present (SW rayleigh provisioned in the quarantined overlay via the pinned recipe when absent).

Contention: 4078 running = true; A2 may run CONCURRENTLY with 4078 on a different cpu-large node (partition has 4 nodes); do not submit if the partition is saturated; never share the node running 4078

Follow-on proof plan: g-counts 32/32; gpoint_fraction and band arrays elementwise EXACT vs published; any mismatch -> sensitivity-only, no floor.

Provenance: branch `glw/gate4-recovery`, generated_from_head `42a74c3` (pre-own-commit).
