# RRTMGP Comparison

RRTMGP is a useful independent reference for reduced ecCKD models because it is
a mature correlated-k scheme with a different table construction path.
NumericalRadiation does not currently reimplement RRTMGP as a core solver.
Instead, validation scripts compare NumericalRadiation ecCKD outputs against
RRTMGP reference fluxes and heating rates where those data or host-model
bindings are available.

## What to Compare

Use the same atmosphere, gases, surface state, solar geometry, and cloud state
for both schemes. Compare at least:

- top-of-atmosphere and surface net flux errors,
- layer heating-rate error,
- max absolute and root-mean-square flux errors across interfaces,
- clear-sky and all-sky cases when cloud optics are active.

The validation metrics API records these quantities through
[`radiation_error_metrics`](@ref), [`radiative_flux_error_metrics`](@ref), and
[`passes_thresholds`](@ref).

## Example Workflow

The generated [RRTMGP validation report](../generated/03_rrtmgp_validation_report.md)
reads the current validation CSV and plots forcing error versus g-point count:

```bash
julia --project=docs docs/make.jl
```

Run the reduced-model comparison script from the repository root:

```bash
julia --project=test validation/reduced_ecckd_32g_rrtmgp_comparison.jl
```

The script writes machine-readable and Markdown reports under
`validation/results/`. Those reports are intended to feed the accuracy-versus-
g-points plot used by PR review and model-selection discussions.

For a full runtime RRTMGP comparison, run the standalone example:

```bash
julia --project=examples examples/rrtmgp_comparison.jl
```

That script builds a Breeze column with RRTMGP clear-sky longwave, runs the
analytic NumericalRadiation longwave model on the same column, and writes
`examples/rrtmgp_comparison.png`.

For exploratory work, compare multiple model pairs:

```bash
ECCKD_MODEL=32x32 julia --project=examples examples/ecckd_column.jl
ECCKD_MODEL=32x96 julia --project=examples examples/ecckd_column.jl
ECCKD_MODEL=64x64 julia --project=examples examples/ecckd_column.jl
```

The example prints the selected model, runtime g-point counts, net fluxes, and
heating-rate range. It is not a substitute for the RRTMGP validation script,
but it is a quick smoke test for model selection and artifact loading.

## Interpreting Results

RRTMGP agreement should be treated as a gate, not as the training target.
ecCKD parity with ecRad checks consistency with the published ecCKD/ecRad data
path, while RRTMGP comparison checks whether reduced models remain physically
reasonable against an independent reference over representative atmospheric
states.
