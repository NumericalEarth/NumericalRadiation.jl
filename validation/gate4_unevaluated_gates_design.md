# Gate-4 design note: the two unevaluated acceptance gates (rev 2)

**Status: DESIGN ONLY — neither gate is implemented.** Rev 2 supersedes
the version in 99029f3 after monitor interface audit: the Gate-1 objective
definition there (recovered-upstream-objective / published-upstream-
objective, relative-base pass, "published floor") was WRONG and is
withdrawn; the Gate-2 OD-parity assumption overstated G1's SW coverage.

## Gate 1: final objective / hard target ≤ 1.05

**Canonical definition (from the archived campaign artifacts)**: the
PACKAGE-NATIVE normalized hard radiation objective —
`reduced_ecckd_optimization_preflight`'s `normalized_case_objective`
against a hard target of 1.0; `official_training` reports it as
"final objective / hard target". It is NOT a ratio of upstream optimizer
costs.

**Design** (`gate4_g3_objective_ratio.jl`, refusing runner):
- Load the recovered definitions via the package API
  (`read_ecckd_tabulated_gas_optics` on the recovered paths).
- Evaluate the package accuracy path: `REDUCED_CASES` → `case_metrics` →
  `hard_objective`; require `hard_objective.value / 1.0 <= 1.05`.
- Provenance gating identical to the acceptance unit (strict run-ledger +
  hash match). Self-tests: published models through the same path
  (recording their values as context), perturbed candidate must raise the
  objective, malformed inputs fail-closed.
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

**Parity precondition (monitor audit)**: G1 proved per-gas OD
reconstruction parity for **LW only**. The G1 SW section consumed
upstream-provided total gas OD + Rayleigh and validated direct RT — SW
candidate-side OD reconstruction is **not yet parity-proven**. A
parity-first stage is therefore mandatory before Gate 2 can bind for SW
(plan below).

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

## Parity-first true-OD plan (proposal)

1. **SW OD parity unit** (read-only): reconstruct SW per-gas and total
   ODs from the PUBLISHED SW32 definition via the g4 bilinear chain and
   compare against the pinned `run_ckd` smoke reference
   (`g1-references/sw32_run_ckd_smoke.nc`, which carries per-gas
   `optical_depth` for 8 gases × 54 layers × 50 columns) at Float32
   storage precision — the exact analog of the LW G1 OD gates. Only a
   green SW parity unit authorizes SW Gate-2 binding.
2. **Matched-state OD evaluator**: given a definition + a concentration
   scenario file, produce total absorption OD (ex-Rayleigh) on the
   scenario's (column, layer) states via the parity-proven chain; LW
   binding immediately, SW binding after step 1.
3. **Gate-2 runner**: acceptance-unit-style refusing runner over the
   agreed fixed dataset union, run-ledger gated, self-tests (self-zero,
   perturbation-fails, structural/shape fail-closed, excluded-pair
   accounting).

## Shared preconditions (both gates)

Recovered outputs + reviewed `gate4_g3_run_ledger.json` (strict schema,
as enforced by the acceptance unit) — both units refuse without them.

## Sequencing

Acceptance = weight rel-L1 (implemented) ∧ Gate 1 ∧ Gate 2, all bands,
plus monitor review. Gate-2 SW additionally requires the SW parity unit
green. Nothing here claims implementation or a pass.
