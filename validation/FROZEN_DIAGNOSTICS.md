# Frozen greedy-era reduced-model diagnostics

On 2026-07-18 the greedy reduced-model program was demoted: the reduced-model
registry in `validation/reduced_ecckd_accuracy.jl` now tracks only the
published official ecCKD 32x32 path, and the greedy construction/replay
machinery was deleted. This note freezes the quantitative endpoints of that
program as evidence.

## 16-g canonical diagnostic (frozen, failing)

The frozen 16-g canonical shortwave diagnostic (weighted-greedy subset of the
official 32-g shortwave g-points plus the accepted-move optimizer chain)
reached a hard-gate objective of about `7.006` — later `8.605` when re-scored
on the official 48-parameter training path — against a passing threshold of
`1.0`. It never approached the hard clean-sky gate (0.3 W m^-2 boundary
forcing, 0.05 K day^-1 heating-rate RMSE) and is retained only as evidence
that forward greedy scaling/subsetting of the published tables cannot reach
the gate at 16 shortwave g-points.

## 32x31 leave-one-out boundary-polished candidate (frozen, passing)

The 32-LW x 31-SW leave-one-out candidate (official shortwave support with
g-point 23 omitted, 17 accepted exact weight-coordinate boundary-polish moves)
passed the hard gate at objective `0.99942`:

- worst boundary forcing error `0.29983` / 0.3 W m^-2,
- worst heating-rate RMSE `0.04988` / 0.05 K day^-1,
- omitted shortwave g-point: 23; accepted moves: 17.

This proves 63 total g-points (32 LW + 31 SW) is feasible under the hard
gate. It is frozen rather than promoted because of how it was produced (see
below).

## Why these are frozen

Both results were produced by greedy/forward-evaluation methods (subset
scans, accepted-move replay chains, coordinate polish), not by the recovered
training pipeline. They are kept as evidence only. All producing scripts,
accepted-move JSON artifacts, and per-iteration logs live on the archived ref
`audit-trail-2026-07-17` (branch `audit-trail-pre-cleanup`).

## Rule for new band schemes

Per the design decision of 2026-07-18, new band-count schemes only count
toward the recovery targets (`validation/ecckd_training_recovery_targets.jl`,
currently band counts 48 and 96) when they are produced by the recovered
Reactant/Enzyme training pipeline with source data, objective terms, and
evaluation cases fixed — optimizer settings are the only allowed delta.
