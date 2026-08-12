# Gate-4 design note: the two unevaluated acceptance gates (rev 3)

**Status (rev 3, 2026-08-12): PARTIALLY IMPLEMENTED — both gates remain
UNEVALUATED on recovered outputs.** Implementation state:

- **Gate 1: runner IMPLEMENTED** (`gate4_g1_objective_ratio.jl`) as a
  refusing runner: its live recovered result refuses pending the G3
  optimizer outputs and a reviewed run ledger
  (`g1_waiting_for_optimizer_outputs`). Self-tests are green, including
  bit-exact reproduction of the archived published-pair baseline
  (0.18218645425029933, rel diff 0.0) — published numbers are self-test
  context only, never recovered acceptance.
- **Gate 2: the SW parity precondition is SATISFIED**
  (`gate4_sw_od_parity.jl`, 13/13) **and the aggregation-independent
  matched-state OD evaluator is IMPLEMENTED**
  (`gate4_g2_matched_state_od_evaluator.jl`, 28/28). The BINDING Gate-2
  runner (dataset choice, aggregation, log-RMSE computation) remains
  UNRESOLVED and UNIMPLEMENTED pending the recorded dataset/aggregation
  rulings.

Rev 2 superseded the version in 99029f3 after monitor interface audit:
the Gate-1 objective definition there (recovered-upstream-objective /
published-upstream-objective, relative-base pass, "published floor") was
WRONG and is withdrawn; the Gate-2 OD-parity assumption overstated G1's
SW coverage.

## Gate 1: final objective / hard target ≤ 1.05

**Canonical definition (from the archived campaign artifacts)**: the
PACKAGE-NATIVE normalized hard radiation objective —
`reduced_ecckd_optimization_preflight`'s `normalized_case_objective`
against a hard target of 1.0; `official_training` reports it as
"final objective / hard target". It is NOT a ratio of upstream optimizer
costs.

**IMPLEMENTED** as `gate4_g1_objective_ratio.jl` (refusing runner):
- Loads the recovered definitions via the package API
  (`read_ecckd_tabulated_gas_optics` on the recovered paths).
- Evaluates the package accuracy path: `REDUCED_CASES` → `case_metrics` →
  `hard_objective`; requires `hard_objective.value / 1.0 <= 1.05` on the
  recovered pair evaluated JOINTLY.
- Provenance gating identical to the acceptance unit (strict run-ledger +
  hash match, structural gate before evaluation, boundary-compat
  flag-pattern equality with the published pair). Self-tests green:
  published pair through the same path reproduces the archived baseline
  bit-exactly (context only), perturbed candidate raises the objective,
  malformed inputs fail-closed (six-rung refusal ladder fixtures).
- Live status refuses honestly until G3 outputs + reviewed ledger exist.
- NOTE (outstanding, separate validation): the full real-data UPSTREAM
  objective/floor comparison remains unimplemented and unclaimed —
  `gate4_objective_assembly_g1` is explicitly synthetic and supports
  term-wise parity only, not floor claims. Upstream's own cost values
  printed in the G3 optimizer logs are future cross-check evidence, not a
  current gate.

## Gate 2: true OD log-RMSE ≤ 0.02

**Binding quantity**: TOTAL absorption optical depth (Rayleigh EXCLUDED)
computed from recovered vs published definitions on MATCHED states.
Per-gas ODs are DIAGNOSTICS only: relative-linear minor-gas contributions
can legitimately be negative, so per-gas log comparisons are not
well-posed as a binding metric.

**Parity precondition (monitor audit): SATISFIED.** G1 proved per-gas OD
reconstruction parity for LW (8/8); the SW gap it left was closed by
`gate4_sw_od_parity.jl` (13/13 green, commit 47a5671) — SW binding of
Gate 2 is now authorized on the parity axis.

**Dataset**: UNRESOLVED pending review — the candidate fixed set is the
exact union of the optimizer training scenarios (20 LW plain + 16 SW rgb
evaluation1 scenarios + eval2 rel-415 both bands), i.e. the states the
optimizer actually fits; the alternative (a single present-day 50-column
file) is explicitly NOT the campaign set. The binding choice, plus the
aggregation (worst-case vs pooled log-RMSE across scenarios), needs a
recorded decision before implementation.

**Numerics to justify explicitly in the implementation**: positive-pair
selection / epsilon clamping (the `positive_eps` pattern) applied to
TOTAL OD only, with counts of excluded pairs reported; no silent
clamping of negative totals (a negative total absorption OD is a
finding, not a clamp).

## Parity-first true-OD plan (status)

1. **SW OD parity unit — DONE** (`gate4_sw_od_parity.jl`, 13/13 green):
   reconstructed SW per-gas and total ODs from the PUBLISHED SW32
   definition via the g4 bilinear chain against the pinned `run_ckd`
   smoke reference (six gases, 32 g-points × 54 layers × 50 columns) at
   Float32 storage precision. SW Gate-2 binding authorized.
2. **Matched-state OD evaluator — DONE**
   (`gate4_g2_matched_state_od_evaluator.jl`, 28/28 green,
   aggregation-independent): definition + stacked-axis scenario file →
   total absorption OD ex-Rayleigh on the matched states; caller-explicit
   `active_absorption_gases` (upstream-pinned gas-scope semantics, never
   a definition∩scenario intersection); per-file constituent_id mapping;
   canonical-schema invariants; raw totals unclamped with negativity
   findings.
3. **Gate-2 runner — UNIMPLEMENTED (pending rulings)**:
   acceptance-unit-style refusing runner over the agreed fixed dataset
   union, run-ledger gated, self-tests (self-zero, perturbation-fails,
   structural/shape fail-closed, excluded-pair accounting). Requires the
   recorded BINDING dataset choice and aggregation decision before
   implementation.

## Shared preconditions (binding campaign runners)

Recovered outputs + reviewed `gate4_g3_run_ledger.json` (strict schema,
as enforced by the acceptance unit) — the BINDING CAMPAIGN RUNNERS
(Gate-1 objective-ratio runner, G3 acceptance unit, and the future
Gate-2 binding runner) refuse without them. The matched-state OD
evaluator is exempt by design: it is a non-binding library evaluating
caller-supplied files with no ledger requirement of its own.

## The FIVE canonical acceptance thresholds (complete conjunction)

Canonical recovery acceptance has FIVE thresholds (declared in
`ecckd_training_recovery_targets.jl` `published_model_recovery_metrics`
and `ecckd_published_recovery_target.jl`), not three:

1. `final_objective_target_ratio_max` ≤ 1.05 (Gate 1 above)
2. `weight_l1_relative_error_max` ≤ 0.02 (implemented, acceptance unit)
3. `optical_depth_log_rmse_max` ≤ 0.02 (Gate 2 above)
4. `forcing_error_regression_margin_w_m2` ≤ 0.03
5. `heating_rmse_regression_margin_k_day` ≤ 0.005

Thresholds 4–5 are candidate-minus-published comparisons on IDENTICAL
`REDUCED_CASES`: the recovered pair's forcing errors / heating RMSE may
not regress beyond the margins relative to the published pair evaluated
through the same path. **Exact aggregation UNRESOLVED**: the full
primary-source evidence audit is recorded in
`gate4_regression_margin_semantics_evidence.md` — no source computes
either margin quantity, the declarations predate the published-model
evaluator, and four open axes (paired-max vs difference-of-maxima;
TOA/surface combination; per-case vs pooled heating RMSE; signed vs
absolute deltas) require a recorded ruling before implementation, not
invention. Gate 1 (`hard_objective ≤ 1.05`) is NOT assumed to subsume
them.

## Sequencing

Acceptance = the FIVE-threshold conjunction over **the recovered
LW32+SW32 pair evaluated jointly**, plus monitor review. The SW parity
requirement for Gate-2 is satisfied; the Gate-2 binding runner and
thresholds 4–5 additionally require the recorded dataset/aggregation
rulings. Nothing here claims a recovered pass: the implemented CAMPAIGN
RUNNERS (Gate-1 objective-ratio, G3 acceptance comparison) refuse until
a reviewed run ledger and recovered pair exist, while the matched-state
OD evaluator remains a NON-BINDING aggregation-independent library that
evaluates caller-supplied files and carries no campaign-ledger refusal
of its own.
