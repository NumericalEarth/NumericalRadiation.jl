# ecCKD Runtime Workflow

This tutorial shows the public runtime path for published ecCKD models:
choose a model pair, load the official CKD-definition files, allocate staged
work arrays, compute optical properties, solve fluxes, and convert flux
convergence to heating rates.

## Select a Model

The selector names are longwave-by-shortwave g-point counts. The published
pairs currently exposed are `"32x32"`, `"32x64"`, `"32x96"`, `"64x32"`,
`"64x64"`, and `"64x96"`.

```@example ecckd_runtime
using NumericalRadiation

spec = official_ecckd_model_spec("32x32")
paths = official_ecckd_definition_paths(spec; require = false)

(name = spec.name, longwave = spec.longwave, shortwave = spec.shortwave)
```

Use `require=false` for inventory and docs so Julia does not download data as
a side effect. Use the default `require=true` in a real run:

```julia
using NumericalRadiation
using NCDatasets

gas_optics = read_official_ecckd_gas_optics("32x32";
    gas_names = (:h2o, :co2),
    h2o_mole_fraction = 0.005,
)
```

The loader returns an `EcCKDTabulatedGasOpticsModel`. That object is independent
of NetCDF after loading and can be moved into a host model's radiation state.
Because `:h2o` is in `gas_names`, the official H2O mole-fraction table
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

The script follows this structure:

```julia
spec = official_ecckd_model_spec("32x32")
gas_optics = read_official_ecckd_gas_optics(spec;
    gas_names = (:h2o, :co2),
    h2o_mole_fraction = 0.005,
)

ng_lw = length(gas_optics.longwave_weights)
ng_sw = length(gas_optics.shortwave_weights)

longwave = LongwaveOpticalProperties(
    zeros(ng_lw, nlayers),
    zeros(ng_lw, nlayers);
    source_top = zeros(ng_lw, nlayers),
    source_bottom = zeros(ng_lw, nlayers),
    weights = zeros(ng_lw),
)

shortwave = ShortwaveOpticalProperties(
    zeros(ng_sw, nlayers);
    rayleigh_optical_depth = zeros(ng_sw, nlayers),
    scattering_asymmetry = zeros(ng_sw, nlayers),
    weights = zeros(ng_sw),
)

optical_properties!(longwave, shortwave, gas_optics, atmosphere)
radiative_fluxes!(fluxes, CloudlessLongwave(), longwave, atmosphere, longwave_boundary)
radiative_fluxes!(fluxes, CloudlessShortwave(), shortwave, atmosphere, shortwave_boundary)
heating_rates!(heating, fluxes, atmosphere; gravity = 9.80665, heat_capacity = 1004.0)
```

Host integrations such as Breeze should keep the same division of
responsibility: select and load the gas-optics model during setup, allocate
work arrays once, then call the staged methods inside each radiation update.
