# Gate-4 design note: the two unevaluated acceptance gates

**Status: DESIGN ONLY — neither gate is implemented.** The acceptance
unit (`gate4_g3_acceptance_comparison.jl`) lists both as
`unevaluated_acceptance_gates` and caps its best post-run status at
`incomplete_pending` until they exist. This note is the read-only design
for the two follow-on units.

## Gate 1: final/target objective ratio ≤ 1.05

**Claim to evaluate**: the recovered model's value of the *reconstructed
original objective* is within 5% of the published model's value of the
same objective (the published model sits at/near the objective floor —
verified directionally in the P2/G1 objective-parity work).

**Design** (`gate4_g3_objective_ratio.jl`, refusing runner):
- Reuse the G1 machinery verbatim: `gate4_forward_map.jl` (upstream-exact
  fluxes/heating at Float32 storage precision, 16 parity gates green) and
  the objective assembly from `gate4_objective_assembly_g1.jl` (kernels +
  correlated prior + negative-OD penalty, options per pass from the
  verbatim optimizer spec: prior_error 8.0 LW / 2.0 SW, corr 0.8, per-pass
  flux weights).
- Objective definition = the **relative-base pass** objective with the
  faithful `TRAINING_BOTH=yes` training set (rel×6 + eval2 rel-415), per
  band — the pass whose floor the published model defines. Later-pass
  objectives are reported as diagnostics.
- Inputs: published + recovered ckd-definitions (hash-gated exactly as the
  acceptance unit: run-ledger schema + on-disk hash match); training flux
  files (all local post-G2c/G2d); no optimizer execution.
- Output: per-band `objective_recovered / objective_published` with the
  ≤ 1.05 verdict; plus the raw values and per-term breakdown for review.
- Self-tests: published-vs-published ratio == 1 exactly; a perturbed
  candidate must raise the objective (ratio > 1); malformed inputs
  fail-closed.

## Gate 2: true OD log-RMSE ≤ 0.02

**Claim to evaluate**: optical depths computed from the recovered LUT
match the published LUT's optical depths over the fixed evaluation
atmospheres (not merely the coefficient tables — interpolation and
concentration dependence included).

**Design** (`gate4_g3_true_od_rmse.jl`, refusing runner):
- OD evaluation via the G1-verified interpolation path
  (`gate4_forward_map.jl` `g4_bilinear_apply` chain — proven bit-faithful
  to upstream `run_ckd` per-gas ODs in the G1 OD parity gates, 8/8 gases).
- Atmospheres: the evaluation1 50-profile set (concentrations from the
  CKDMIP conc files already local); per-gas and total OD per (profile,
  layer, g-point).
- Metric: log-RMSE over strictly positive OD pairs with the
  `positive_eps` guard from `ecckd_recovery_metrics.jl`; aggregate = worst
  per-gas log-RMSE per band; verdict vs 0.02. Layer/g distributions
  reported for review.
- Alternative considered and rejected for the binding metric: running the
  pinned `run_ckd` binary on both definitions and comparing its
  `optical_depth` outputs — equivalent evidence but requires Slurm jobs;
  the in-Julia G1 path is bit-verified and read-only. `run_ckd`
  cross-check can be a non-binding confirmation stage.
- Self-tests: self-comparison exactly 0; coefficient-perturbed candidate
  must exceed 0.02; shape/structural mismatches fail-closed (reuse the
  acceptance unit's structural gate first).

## Shared preconditions (both gates)

Recovered outputs + reviewed `gate4_g3_run_ledger.json` (strict schema) —
identical gating to the acceptance unit; both units refuse without them.
No objective/OD evaluation of unreviewed artifacts.

## Sequencing

Implement after G3 outputs exist (they are pure post-processing), before
any acceptance verdict is finalized: acceptance = weight rel-L1 (done) ∧
objective ratio (gate 1) ∧ true OD (gate 2), all three bands-passing,
plus monitor review.
