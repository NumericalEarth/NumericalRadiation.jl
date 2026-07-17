# ecCKD Model Selection

The high-level selection interface is meant to be the first stop for users who
want a published ecCKD model. It returns a named longwave/shortwave pair and
resolves the corresponding official CKD-definition files.

```@example ecckd_model_selection
using NumericalRadiation

spec = official_ecckd_model_spec("32x64")
(name = spec.name, longwave = spec.longwave, shortwave = spec.shortwave)
```

Compact selectors such as `"32x64"` and full selectors such as
`:climate_32x64` are equivalent. The available published pairs are:

```@example ecckd_model_selection
collect(keys(official_ecckd_model_specs()))
```

## Resolve Data Files

Use `require=false` when a script should only inspect local state. This avoids
triggering lazy artifact downloads during documentation builds or dry runs.

```@example ecckd_model_selection
paths = official_ecckd_definition_paths(spec; require = false)
(longwave = paths.longwave, shortwave = paths.shortwave)
```

For a real run, use the default `require=true`:

```julia
using NumericalRadiation
using NCDatasets

gas_optics = read_official_ecckd_gas_optics("32x64";
    gas_names = (:h2o, :co2),
    h2o_mole_fraction = 0.005,
)
```

The loader returns an [`EcCKDTabulatedGasOpticsModel`](@ref). After loading,
the model is ordinary Julia data and no longer needs an open NetCDF dataset.

## Choose a Pair

Use the smallest model that passes the validation criteria for your application.
The exposed pairs make the tradeoff explicit:

- `"32x32"` is the lowest-cost published pair exposed here.
- `"32x64"` and `"32x96"` keep the lower-cost longwave side while increasing
  shortwave resolution.
- `"64x32"` increases longwave resolution while keeping the lower-cost
  shortwave side.
- `"64x64"` and `"64x96"` are the highest-resolution longwave pairs exposed by
  the interface; `"64x96"` is the largest promoted official combination.

For production model coupling, select once during setup, allocate radiation
work arrays once, and reuse those arrays every radiation update.

## Water Vapor Tables

The convenience call above takes `h2o_mole_fraction` because it collapses
H2O-dependent official tables to a fixed reference value. That is appropriate
for simple examples and some validation checks. A host model with prognostic
water vapor should preserve the H2O table dimension and evaluate it from the
current atmospheric state inside [`optical_properties!`](@ref).
