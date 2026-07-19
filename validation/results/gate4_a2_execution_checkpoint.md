# Gate-4 A2 execution checkpoint (dry-run)

Status: **a2_execution_checkpoint_ready**

dry-run script generation only; nothing submitted; no find_g_points/create_lut/objective/floor execution; submission requires explicit authorization per the standing protocol.

| Gate | Result |
|---|---|
| config_copy_patched_not_env_only | passed |
| contention_policy_recorded | passed |
| headnode_refusal_guard | passed |
| no_mutation_of_4078_workcopy | passed |
| reorder_and_find_only | passed |
| sbatch_written_not_submitted | passed |
| target_tolerances_narrowed | passed |
| workdir_quarantined | passed |

Generated (unsubmitted) batch script: `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_a2_dryrun.sbatch`

Contention: 4078 running = true; A2 may run CONCURRENTLY with 4078 on a different cpu-large node (partition has 4 nodes); do not submit if the partition is saturated; never share the node running 4078

Follow-on proof plan: g-counts 32/32; gpoint_fraction and band arrays elementwise EXACT vs published; any mismatch -> sensitivity-only, no floor.

Provenance: branch `glw/gate4-recovery`, generated_from_head `bd4377a` (pre-own-commit).
