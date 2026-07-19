# Gate-4 A2 submission ledger

Status: **a2_submitted_awaiting_completion**

Submission event record only; no floor, proof, objective, or recovery
computation has run.

| Field | Value |
|---|---|
| Job ID | 4079 (`g4-a2-find-g-points`) |
| Submitted | 2026-07-19T05:51:51 (state at write: CONFIGURING) |
| Partition / limit | cpu-large / 12:00:00 |
| Excluded node | `cpu-large-dy-cpu-large-1` (4078's node; guardrail) |
| sbatch | `validation/results/gate4_a2_dryrun.sbatch` |
| sbatch sha256 | `03a751f0ff827eaabd6860dc25929bd01a022dc5107614b5192b4dd9189e8c3c` |
| HEAD at submission | `4e6aab7` (branch `glw/gate4-recovery`) |

Guardrail preflight: 4078 RUNNING on `cpu-large-dy-cpu-large-1`; nodes
`cpu-large-2/3/4` idle, so the monitor's at-least-one-other-idle-node
condition held and `--exclude` was applied. The sbatch operates only in an
isolated TESTCOPY (config.h sed-patched absolute); the 4078 working copy is
never mutated.

Scope: A2 runs reorder_spectrum + find_g_points ONLY (LW fsck tol 0.0161,
SW rgb tol 0.047). Candidates are sensitivity-only until all 10 exact
comparisons in the reproduction-proof scaffold pass.

Hygiene folded into this commit: stale May-config comment removed from the
checkpoint generator and the regenerated sbatch (comment-only diff; the
submitted file is the regenerated one).
