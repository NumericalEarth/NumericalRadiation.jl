# Validation

## Running the package tests

The package test suite covers the solvers, ecCKD ingestion, cloud optics, and
the SpeedyWeather extension:

```
julia --project=. -e 'using Pkg; Pkg.test()'
```

The suite runs in about a minute and needs no manual data setup; the
official ecRad/ecCKD snapshots resolve through the lazy artifacts pinned in
`Artifacts.toml`.

## The validation platform

The development and validation harness — accuracy gates, reference manifests,
frozen evidence, and the training pipeline — is deliberately kept off this
branch; it lives on the
[`validation-platform`](https://github.com/NumericalEarth/NumericalRadiation.jl/tree/validation-platform)
branch.
