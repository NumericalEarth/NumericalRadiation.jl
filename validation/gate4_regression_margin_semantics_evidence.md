# Regression-margin semantics: primary-source evidence memo

**Status: EVIDENCE ONLY — no aggregation semantics are chosen here.** This
memo supports the pending monitor ruling on acceptance thresholds 4–5
(`forcing_error_regression_margin_w_m2` ≤ 0.03,
`heating_rmse_regression_margin_k_day` ≤ 0.005). Per monitor directive:
absence of an implementation is treated as evidence; nothing below selects
semantics by inference.

## PROVEN (primary sources, exact locations)

### 1. The margins are declared as thresholds only — nowhere computed

- `validation/ecckd_training_recovery_targets.jl:35-36` — the
  `published_model_recovery_metrics` NamedTuple declares
  `forcing_error_regression_margin_w_m2 = 0.03` and
  `heating_rmse_regression_margin_k_day = 0.005`. Rendered as a table at
  lines 138-139. No computation.
- `validation/ecckd_published_recovery_target.jl:91-97` — fallback Dict in
  `recovery_acceptance_targets()` (lines 84-98) repeats the same five
  thresholds; the function otherwise reads them from the training-targets
  JSON. No computation.
- Prose restatements (tables only, no semantics):
  `docs/src/design.md:174-175`;
  `validation/results/ecckd_training_recovery_targets.md:19-20`;
  `validation/results/ecckd_published_recovery_target.md:12-13`.
- Repo-wide identifier census (unfiltered, this repo and the package repo,
  source + docs): every occurrence of either identifier is one of —
  **declaration** (`ecckd_training_recovery_targets.jl:35-36`,
  `ecckd_published_recovery_target.jl:95-96`), **render** of the declared
  value into a report (`ecckd_training_recovery_targets.jl:138-139` and the
  archived results tables), or **restatement** (`docs/src/design.md:174-175`,
  `validation/gate4_unevaluated_gates_design.md:96-97` rev 2, and this
  memo). **NO source file COMPUTES either quantity** — there is no
  "regression" aggregation definition anywhere. The origin commit `e944699`
  ("Add original-objective recovery framework + published-model accuracy
  gate") introduces both declaring files; its message records no margin
  semantics.
- Archived campaign records (all verified on ref `audit-trail-pre-cleanup`;
  the pass numbers were supplied by the monitor and independently
  confirmed here):
  - `RUNNING_REVIEW.md` pass #5414 (2026-05-22T19:20:34Z; file line 8273)
    records the contract's creation and lists the five numeric criteria
    verbatim — no aggregation semantics.
  - `PR_WORK_SUMMARY.md` (contract paragraph, ~lines 762-772) records the
    same five criteria verbatim — no aggregation semantics.
  - The introducing test `e944699:test/test_ecckd_training_recovery_targets.jl`
    asserts only the first two recovery thresholds
    (`final_objective_target_ratio_max == 1.05` at line 14,
    `weight_l1_relative_error_max == 0.02` at line 15); it never
    references the forcing or heating margins, let alone their
    aggregation.
- **Timeline fact (proven from RUNNING_REVIEW.md)**: the contract was
  declared at pass #5414 (19:20:34Z), while
  `validation/ecckd_published_model_accuracy.jl` — the published-model
  flux/heating evaluation path — was only added at pass #5417 (19:48:53Z,
  line 8276). At declaration time no published-model flux/heating
  evaluator existed; the only forcing/heating machinery was
  `reduced_ecckd_accuracy.jl`'s per-case/worst-case reporting. The margins
  therefore cannot have been declared against specific
  `published_model_result` aggregation fields.
- **Conclusion (proven): no canonical aggregation implementation exists,
  and no archived record defines the delta computation.**

### 2. The canonical evaluation path and its exact primitives

`validation/ecckd_published_recovery_target.jl:120-124`
(`next_required_work`) directs recovered models to "ecckd_recovery_metrics
plus the original-objective flux/heating criteria". The flux/heating
machinery that evaluates published models is:

- `validation/reduced_ecckd_accuracy.jl:12-16` — `REDUCED_CASES` = exactly
  two clear-sky cases: `ecckd_clear_sky_tropical_column`,
  `ecckd_rcemip_style_column_subset` (drawn from `REQUIRED_CASES`,
  `validation/ecrad_reference_manifest.jl:14`).
- `validation/reduced_ecckd_accuracy.jl:497-503` — `metric_pair`: RMSE
  pooled over ALL elements (layers × columns) of one case, plus max-abs.
- `validation/reduced_ecckd_accuracy.jl:485` — heating rate in K/day
  (86400 × K/s).
- `validation/reduced_ecckd_accuracy.jl:505-509` — `boundary_net`:
  BROADBAND combined net flux `lw_down - lw_up + sw_down - sw_up` at TOA or
  surface. "Forcing" in this path is therefore a **net-flux error vs the
  ecRad reference on one state** (candidate minus reference), NOT a
  scenario-pair (CKDMIP-style) forcing; it couples the LW and SW models
  jointly, consistent with "the recovered LW32+SW32 pair evaluated jointly"
  (design note rev 2).
- `validation/reduced_ecckd_accuracy.jl:511-553` — `case_metrics` per case:
  `variables.heating_rate.rmse` (pooled within-case), `toa_forcing_max_abs`
  = max over columns of |Δ net TOA| (line 529), `surface_forcing_max_abs`
  (lines 530-531).
- `validation/ecckd_published_model_accuracy.jl:318-343` —
  `published_model_result` model-level aggregation:
  `worst_toa_forcing_abs_error_w_m2 = maximum over cases` (335-336),
  `worst_surface_forcing_abs_error_w_m2` (337-338). TOA and surface are
  tracked SEPARATELY; **no combined scalar "forcing error" exists at model
  level**.
- `validation/ecckd_published_model_accuracy.jl:183-244` —
  `hard_objective(cases)`: the worst threshold-normalized (value/threshold)
  row across all (case, metric) pairs. This pins the Gate-1 quantity
  ("final objective / hard target"); heating RMSE enters it only
  threshold-normalized.
- **No model-level heating-RMSE aggregate exists in the canonical
  published-accuracy path** (`published_model_result`,
  `ecckd_published_model_accuracy.jl:318-343`) — there, heating RMSE is
  recorded per case only. A pooled aggregate DOES exist in other machinery:
  `reduced_ecckd_32g_rrtmgp_comparison.jl:140` computes
  `sqrt(mean(m.heating_rate_rmse^2 for m in metrics))` across its metric
  rows. That precedent belongs to the RRTMGP-comparison path and was never
  tied to thresholds 4-5; its existence shows pooling conventions VARY
  across the machinery, so a model-level heating-RMSE aggregation for
  threshold 5 remains a NEW choice for the canonical path, with two
  divergent in-repo precedents (per-case-only vs RMS-pooled).

### 3. Published 32×32 baseline numbers (archived)

Source: `validation/results/ecckd_published_model_accuracy.json` at git ref
`audit-trail-2026-07-17` (pruned from this branch by cleanup commit
`d1dfd16`; extracted copy sha256
`c16591d2264df0c25cf9c66d50627c0b78726fa2b5a9065bc451442c8e429801`).
Model "official ecCKD 1.0 32-LW x 32-SW climate model", status passed:

| Quantity | Value |
|---|---:|
| worst_toa_forcing_abs_error_w_m2 | 0.008063265919417972 |
| worst_surface_forcing_abs_error_w_m2 | 0.01403340276021936 |
| heating_rate RMSE, clear_sky_tropical_column | 0.005750190803338514 K/day |
| heating_rate RMSE, rcemip_style_column_subset | 0.004569757951831493 K/day |
| hard_objective | 0.18218645425029933 (heating_rate_max_abs, tropical, 0.0911/0.5) |

Scale context (arithmetic on proven numbers, no semantics implied): the
0.03 W/m² forcing margin is ~3.7× the published worst TOA error and ~2.1×
the published worst surface error; the 0.005 K/day heating margin is
comparable to the published per-case heating RMSEs themselves
(0.0046–0.0058).

**Unexplained observation (recorded, not interpreted)**: the archived
per-case `toa_forcing_max_abs` values are identical to full precision
across BOTH cases (0.008063265919417972), likewise `surface_forcing_max_abs`
(0.01403340276021936), while the heating RMSEs differ. Consistent with the
worst column being shared between the two case sets (the rcemip subset may
share columns with the tropical set), but this is unverified.

## OPEN AXES (require ruling; nothing in the archive selects among them)

1. **Pairing**: max over cases of the paired delta,
   `max_i(candidate_i − published_i)`, versus difference of the model-level
   worsts, `max_i(candidate_i) − max_i(published_i)`. The existing
   model-level fields (worst_toa/worst_surface) make the second directly
   expressible from archived artifacts; the first requires per-case pairing
   (also archived). Neither is precedented as a "regression" computation.
2. **Forcing combination**: threshold 4 names ONE margin, but the canonical
   path tracks TOA and surface separately. Options include: each boundary
   must independently satisfy the margin (conjunction), or the max of the
   two deltas. No combined scalar exists in any primary source.
3. **Heating RMSE aggregation**: per-case deltas each within margin, versus
   worst-case delta, versus pooled-across-cases RMSE. No cross-case pooled
   RMSE exists in the canonical published-accuracy path; the
   `sqrt(mean(rmse^2))` pooling at
   `reduced_ecckd_32g_rrtmgp_comparison.jl:140` is an in-repo precedent
   from a different path, never tied to thresholds 4-5.
4. (Interacts with the above) Whether signed deltas or absolute deltas are
   intended — "may not regress beyond" (design note rev 2) reads as signed
   candidate-minus-published upper bound, i.e. improvement is unbounded;
   this is the design note's recorded phrasing, not an implementation.

## Relation to the Gate-2 dataset question

These REDUCED_CASES (2 clear-sky ecRad reference cases) are a DIFFERENT
fixed set from the Gate-2 candidate dataset (36 evaluation1 + eval2 pair
optimizer-training union). Thresholds 4–5 are defined on REDUCED_CASES per
the design note; the Gate-2 dataset/aggregation ruling is a separate open
decision and is not affected by this memo.

## Next concrete work item

Monitor ruling on axes 1–4 above, recorded as a decision record; only then
implement the threshold-4/5 evaluator (acceptance-unit style, refusing,
self-tested) against the archived published baseline path
(`published_model_result` on the recovered pair with identical
REDUCED_CASES). No implementation before the ruling.
