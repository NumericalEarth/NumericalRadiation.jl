# Gate-4 A2 proof-run submission ledger

Status: **proof_run_submitted_awaiting_completion**

Submission event record only; no comparison, objective, floor, or recovery
computation has run.

| Field | Value |
|---|---|
| Job ID | 4091 (`g4-a2-proof-create-lut`) |
| Submitted | 2026-07-20T07:28:45 (state at write: CONFIGURING) |
| Partition / limit | cpu-large / 08:00:00 |
| sbatch | `validation/results/gate4_a2_proof_dryrun.sbatch` |
| sbatch sha256 | `cd1d7ab1c28c54eeb60b879828d5fb105a8a5deda1d41435e907d834331d7cf6` |
| HEAD at submission | `ecf3973` (branch `glw/gate4-recovery`) |

Authorization: Greg, directly — "keep going for gate-4" (2026-07-20),
following the recommendation to submit. evaluation2 ruled consider-later
(out of the gate-4 acceptance chain). All four cpu-large nodes idle at
preflight (4078 completed rc=0 the previous day), so no node exclusion was
needed.

Guardrails: head-node refusal; 4082 TESTCOPY reused unchanged with all five
patched config vars grep-asserted; candidate sha256 identity check against
the 4082 ledger; stale-raw-output refusal (both outputs verified absent);
input-deps preflight; create_lut-only executable lines.

Scope: proof-only raw create_lut builds. On completion: log/hash review,
then the 10 elementwise-exact comparisons vs published LW32/SW32. All
exact → promotable subject to review; any mismatch → sensitivity-only
(pre-registered risk: ecckd version skew 1.0/1.4 published vs 1.2 pinned).
