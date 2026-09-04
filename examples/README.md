# Examples

Standalone scripts that exercise `NumericalRadiation` in richer settings
than the docs examples. They live in their own Julia environment
(`examples/Project.toml`) so the main package stays dep-light.

## `analytic_column.jl`

Run a single analytic-band column through the staged `radiative_heating!`
wrapper and print surface fluxes, TOA flux, column-integrated heating, energy
closure residual, and runtime.

```bash
julia --project=. examples/analytic_column.jl
```

## `ecckd_column.jl`

Select a published ecCKD model pair, load its reference CKD-definition files,
run one clear-sky staged column, and print flux/heating diagnostics.

```bash
julia --project=examples examples/ecckd_column.jl
ECCKD_MODEL=64x32 julia --project=examples examples/ecckd_column.jl
```
