# ecCKD Runtime Workflow

This tutorial shows the public runtime path for published ecCKD models:
choose a model pair, load the reference CKD-definition files, allocate staged
work arrays, compute optical properties, solve fluxes, and convert flux
convergence to heating rates.

## Select a Model

The selector names are longwave-by-shortwave g-point counts. The published
pairs currently exposed are `"32x32"`, `"32x64"`, `"32x96"`, `"64x32"`,
`"64x64"`, and `"64x96"`.

```@example ecckd_runtime
using NumericalRadiation

spec = reference_ecckd_model_spec("32x32")
paths = reference_ecckd_definition_paths(spec; require = false)

(name = spec.name, longwave = spec.longwave, shortwave = spec.shortwave)
```

Compact selectors such as `"32x64"` and full selectors such as
`:climate_32x64` are equivalent; the published pairs are enumerable:

```@example ecckd_runtime
collect(keys(reference_ecckd_model_specs()))
```

Use the smallest model that meets your application's accuracy needs:
`"32x32"` is the lowest-cost published pair, the mixed pairs (`"32x64"`,
`"32x96"`, `"64x32"`) raise resolution on one side only, and `"64x96"` is the
largest promoted combination. Select once during setup, allocate radiation
work arrays once, and reuse them every update.

Use `require=false` for inventory and docs so Julia does not download data as
a side effect. Use the default `require=true` in a real run:

```julia
using NumericalRadiation
using NCDatasets

gas_optics = read_reference_ecckd_gas_optics("32x32";
    names = (:composite, :h2o, :co2),
    h2o_mole_fraction = 0.005,
)
```

Gases omitted from `names` are not removed: their reference abundances
remain represented through the `:composite` background. Include a gas
explicitly to vary its amount — or to set it to zero.

The loader returns an `EcCKDTabulatedGasOpticsModel`. That object is independent
of NetCDF after loading and can be moved into a host model's radiation state.
Because `:h2o` is in `names`, the reference H2O mole-fraction table
dimension is kept: at each radiation update, `optical_properties!` computes
the layer H2O mole fraction from the `h2o` and `composite` gas amounts and
interpolates the table per layer. The `h2o_mole_fraction` keyword is not a gas
input — it is accepted for compatibility/fallback sampling of non-dynamic
H2O tables.

Gas entries in [`ColumnAtmosphere`](@ref) are layer absorber amounts — column
amounts in mol m⁻² (mole fraction times the layer air column), not mole
fractions. All layer and interface arrays are ordered top-to-bottom, with
pressure increasing downward (index 1 = top of atmosphere).

## Complete Column Script

The complete runnable version lives at `examples/ecckd_column.jl`:

```bash
julia --project=examples examples/ecckd_column.jl
ECCKD_MODEL=64x32 julia --project=examples examples/ecckd_column.jl
```

The script selects a model, allocates the work arrays once, and then runs
the staged sequence documented on the [solvers page](../solvers.md) —
`optical_properties!` → `radiative_fluxes!` (longwave, then shortwave) →
`heating_rates!` — inside each radiation update. The fully executed version
of this construction is the [staged ecCKD column
example](../generated/staged_ecckd_column.md).

Host integrations should keep the same division of responsibility: select
and load the gas-optics model during setup, allocate work arrays once, then
call the staged methods inside each radiation update.
