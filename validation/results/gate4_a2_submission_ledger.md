# Gate-4 A2 submission ledger

Status at ledger write: **a2_attempt2_completed_candidates_collected**

> **Current disposition (updated 2026-08-12, additive annotation)**: the
> submission/completion event record below (scope, next steps) is
> preserved verbatim as event-time truth. Since then, all three "next
> steps" resolved -- each grounded in a verified dependency artifact: the
> reproduction proof **EXECUTED as job 4091** (COMPLETED rc=0 per
> `gate4_a2_proof_finding_ledger`) with strict verdict
> `a2_candidates_sensitivity_only_not_promotable`; Greg-authorized
> **Option B** (`gate4_option_b_decision_record`,
> `option_b_adopted_candidates_promoted`) subsequently accepted the
> exactly **two** 4082 g-point candidates (LW + SW; the rayleigh overlay
> is an input-generation artifact, not a candidate) as structure sources
> for ACCEPTANCE-INIT SELECTION under the amended rule, the strict
> finding record standing unmodified; and the job-4078 watch closed --
> 4078 completed rc=0 per the at-write record in
> `gate4_a2_proof_submission_ledger` (that ledger's own status,
> `proof_run_submitted_awaiting_completion`, is at-write: awaiting proof
> completion), with the 18 derived training flux products **present** per
> the post-4078 `ckdmip_training_data_preflight`
> (2026-07-19T20:44:47.920; 18/18 present, no derived-flux-generation
> blockers; that artifact records no hashes, so presence only -- no
> byte-identity claim is made).

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

Next steps: monitor 4078 (dedicated watcher); proof execution is a
separate unit requiring explicit review/go — mechanism-1 verification
(candidates already sit in `WORK_*_GPOINTS_DIR` under the exact
script-derived filenames, so placement reduces to a sha256 identity
check), `create_lut_{lw,sw}.sh` on Slurm, then the 10 exact comparisons;
NO proof has run yet. On 4078 completion: install check, then preflight
rerun toward G2/G3.

## History: attempt 1 (FAILED)

Job 4079, submitted 2026-07-19T05:51:51 from HEAD `4e6aab7` with the same
node exclusion; sbatch sha256 `03a751f0ff827eaabd6860dc25929bd01a022dc5107614b5192b4dd9189e8c3c`.
FAILED at LW reorder — missing stage-1 merge composites in the fresh
quarantined WORK_DIR; see `gate4_a2_failure_ledger_4079.md`. No candidates
produced, nothing promoted.
