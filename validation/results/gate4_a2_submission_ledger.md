# Gate-4 A2 submission ledger

Status: **a2_attempt2_completed_candidates_collected**

Submission/completion event record only; no floor, proof, objective, or
recovery computation has run.

## Completion (2026-07-19T08:16:07Z)

Job 4082 COMPLETED, `A2 done rc=0`. All stages green: stage-0 preflight,
LW/SW merges (rayleigh overlay sha256 `36ad9c9a…ebdad2`), 7 LW + 9 SW
reorder outputs, LW/SW find_g_points. Candidates collected:

| Band | Candidate | Size | sha256 |
|---|---|---|---|
| LW | `ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5` | 58,404,939 | `c96e6492…a017a3e` |
| SW | `ecckd-1.2_sw_gpoints_climate_rgb-tol0.047.h5` | 25,458,368 | `13dd686a…59b9b57` |

Both carry a combined `g_point (32,)` structure (overlap step wrote global
G-points 0–31). Proof scaffold rerun twice post-completion: status
`a2_proof_scaffold_ready`, exactly one candidate per band. NO reproduction
proof, create_lut, objective, floor, or acceptance use has run — candidates
are sensitivity-only pending the 10 exact comparisons.

## Current: attempt 2

| Field | Value |
|---|---|
| Job ID | 4082 (`g4-a2-find-g-points`) |
| Submitted | 2026-07-19T06:08:43 (state at write: CONFIGURING) |
| Partition / limit | cpu-large / 12:00:00 |
| Excluded node | `cpu-large-dy-cpu-large-1` (4078's node; guardrail) |
| sbatch | `validation/results/gate4_a2_dryrun.sbatch` |
| sbatch sha256 | `adeb59a6ea91744c58d13e37ce964fd7a834c39b1346391245304936e7538649` |
| HEAD at submission | `55e0be7` (branch `glw/gate4-recovery`) |

Guardrail preflight: 4078 RUNNING on `cpu-large-dy-cpu-large-1` (3:09
elapsed); node 2 idle%, nodes 3–4 idle~, so the
at-least-one-other-node condition held and `--exclude` was applied. The
sbatch operates only in an isolated TESTCOPY with five config.h vars
sed-patched absolute (CKDMIP_DATA_DIR, WORK_DIR, BINDIR,
MMM_SW_SPECTRA_DIR → quarantined overlay, CLOUD_SPECTRUM); the 4078
working copy and the official data tree are never mutated.

Delta vs attempt 1: stage-1 `merge_well_mixed_{lw,sw}.sh` before reorders;
quarantined SW rayleigh input overlay (pinned `make_rayleigh_mmm.sh`
recipe) with `MMM_SW_SPECTRA_DIR` sed-patch; `CLOUD_SPECTRUM` sed-patched
absolute; in-job stage-0 binary+input preflight.

Scope: A2 runs merge_well_mixed + reorder_spectrum + find_g_points ONLY
(LW fsck tol 0.0161, SW rgb tol 0.047), plus quarantined-overlay rayleigh
input provisioning. Candidates are sensitivity-only until all 10 exact
comparisons in the reproduction-proof scaffold pass.

Next steps: monitor 4078 and 4082 (including the 4082 log's stage-0
preflight lines); on 4082 completion rerun the reproduction-proof scaffold
(should flip to `a2_proof_scaffold_ready`); on 4078 completion, install
check then preflight rerun toward G2/G3.

## History: attempt 1 (FAILED)

Job 4079, submitted 2026-07-19T05:51:51 from HEAD `4e6aab7` with the same
node exclusion; sbatch sha256 `03a751f0ff827eaabd6860dc25929bd01a022dc5107614b5192b4dd9189e8c3c`.
FAILED at LW reorder — missing stage-1 merge composites in the fresh
quarantined WORK_DIR; see `gate4_a2_failure_ledger_4079.md`. No candidates
produced, nothing promoted.
