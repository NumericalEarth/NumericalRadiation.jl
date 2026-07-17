# ecCKD Training and Recovery

The training/recovery workflow has two goals:

1. reconstruct the published ecCKD objective closely enough to recover an
   official reduced model, and
2. use the same pipeline to fill new g-point counts such as 48 or 96 when the
   published set does not contain the desired pair.

Recovery means that an in-house optimization pipeline starts from the same
training data and nearly the same objective as the published ecCKD workflow,
then produces coefficients and validation metrics that are quantitatively
close to a published model. Exact bitwise equality is not expected if optimizer
settings, stopping tolerances, compiler math, or line-search choices differ.
The intended controlled experiment is to keep everything except optimizer
settings as similar as possible.

## Inputs

Small inputs are artifact-backed:

- `ecrad_data` provides the published CKD-definition files used for parity
  checks.
- `ecckd_source` provides the upstream ecCKD source and training scripts.

Large CKDMIP line-by-line spectra are not default package artifacts. Set
`RH_CKDMIP_DATA_PATH` to a local or mounted CKDMIP tree before running exact
training-objective reconstruction:

```bash
export RH_CKDMIP_DATA_PATH=/path/to/ckdmip
julia --project=test validation/ckdmip_training_data_preflight.jl
```

The preflight distinguishes public upstream inputs from derived ecCKD training
fluxes. Files named like `5gas-*` and `rel-*` are generated products from the
ecCKD/CKDMIP toolchain, not public CKDMIP archive inputs.

## Objective Reconstruction

The generated [Training and Recovery Report](../generated/04_training_recovery_report.md)
embeds the current validation status and plots the best available
boundary-forcing row by total g-point count. Rebuild the docs to refresh it:

```bash
julia --project=docs docs/make.jl
```

The recovery pipeline should report the objective terms separately:

```bash
julia --project=test validation/ecckd_original_objective_terms.jl
julia --project=test validation/ecckd_training_recovery_targets.jl
```

The reports under `validation/results/` record which parts of the published
problem are available, which derived flux products are present, and which
accuracy gates can be evaluated.

## Quantitative Recovery Metrics

A recovery attempt should publish at least:

- coefficient-vector distance to the published model after matching bands and
  g points,
- objective value and per-term objective differences,
- TOA, surface, and interface flux error metrics,
- layer heating-rate error metrics,
- pass/fail status against the same thresholds used for published-model
  validation.

This is why optimizer settings matter: if all other inputs are held fixed and
the objective has one dominant minimum, the recovered model should be very
similar to the published model. If it is not, the difference becomes a useful
diagnostic of missing objective terms, data mismatch, or optimizer behavior.

## Developing New Models

After one published model is recovered, new models should follow the same
workflow:

1. choose the target g-point count,
2. initialize from a nearby published model or from a deterministic spectral
   partition,
3. optimize against the reconstructed objective,
4. evaluate against ecRad and RRTMGP reference states,
5. add the new model only after its reports and plots pass review.

The reduced-model accuracy plot should include every published and recovered
candidate so users can see the accuracy/cost curve rather than a single model
choice.
