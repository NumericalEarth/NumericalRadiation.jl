# NumericalRadiation.jl

[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://NumericalEarth.github.io/NumericalRadiation.jl/dev/)
[![CI](https://github.com/NumericalEarth/NumericalRadiation.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/NumericalEarth/NumericalRadiation.jl/actions/workflows/CI.yml)
[![Documenter](https://github.com/NumericalEarth/NumericalRadiation.jl/actions/workflows/Documenter.yml/badge.svg)](https://github.com/NumericalEarth/NumericalRadiation.jl/actions/workflows/Documenter.yml)

Analytic-band atmospheric radiation for intermediate-complexity models.

This package bundles two per-column radiation schemes:

- **Longwave** — Williams (2026) *Simple Spectral Model*: a 41-wavenumber
  clear-sky two-stream Schwarzschild solver with analytic H₂O line,
  H₂O continuum and CO₂ absorption coefficients.
  Published in *J. Adv. Model. Earth Syst.*, doi:[10.1029/2025MS005405](https://doi.org/10.1029/2025MS005405).
- **Shortwave** — a one-band scheme after SPEEDY (Kucharski, Molteni & Bracco,
  *Quart. J. Roy. Meteor. Soc.*, 2006), with transparent, constant, or
  Kucharski-style background-transmissivity options and a diagnostic
  cloud/stratocumulus model.

The column solvers are pure scalar operations — no allocations, no host-side
loops, GPU-safe — so the same code can be driven by
[SpeedyWeather.jl](https://github.com/SpeedyWeather/SpeedyWeather.jl) (which
dispatches per column via `parameterization!(ij, vars, scheme, model)`) or by
[Breeze](https://github.com/NumericalEarth/Breeze.jl) (which launches a
KernelAbstractions kernel per column inside `_update_radiation!`).

Package extensions wire each host automatically when both packages are loaded.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/NumericalEarth/NumericalRadiation.jl")
```

## Standalone usage (single column)

Bundle the grid, profile, surface, schemes, constants, and pre-allocated
buffers into a single [`RadiativeTransferColumn`](@ref) and call the solvers
with one argument:

```julia
using NumericalRadiation

nlayers = 8
σ_half  = collect(range(0.0, 1.0, length = nlayers + 1))
grid    = ColumnGrid(σ_half)

# Lapse-rate profile: top of atmosphere (k=1) cold, surface (k=nlayers) warm.
profile = AtmosphereProfile(
    temperature      = collect(range(220.0, 295.0, length = nlayers)),
    humidity         = fill(0.005, nlayers),
    geopotential     = zeros(nlayers),
    surface_pressure = 100_000.0,
    CO₂              = 280.0,
)

surface = SurfaceState(
    sea_surface_temperature  = 295.0,
    land_surface_temperature = 285.0,
    land_fraction            = 0.3,
    ocean_albedo             = 0.07,
    land_albedo              = 0.25,
    cos_zenith               = 0.5,
)

# Schemes, constants, and output buffers all wrap up here.
rtm = RadiativeTransferColumn(; grid, profile, surface)

solve_longwave!(rtm)
solve_shortwave!(rtm)

@show rtm.longwave_diagnostics.outgoing_longwave        # W m⁻²
@show rtm.longwave_diagnostics.surface_longwave_down    # W m⁻²
@show rtm.shortwave_diagnostics.surface_shortwave_down  # W m⁻²
@show rtm.temperature_tendency                           # K s⁻¹ per layer
```

For the low-level kernel form (what hosts like SpeedyWeather / Breeze extensions
call internally), `solve_longwave!` and `solve_shortwave!` accept the
flattened `(dTdt, diagnostics, scheme, profile, grid, surface, constants, …)`
signature directly, and the `constants` argument is duck-typed — any struct
or NamedTuple carrying `gravity`, `heat_capacity`, `stefan_boltzmann`,
`solar_constant` properties works.

All floating-point types default to `Float64`. To run in `Float32` (useful for
GPU kernels), pass the type as a positional argument to the scheme
constructors: `AnalyticBandLongwave(Float32)`,
`OneBandShortwave(Float32)`, etc.

## With SpeedyWeather.jl

The `NumericalRadiationSpeedyWeatherExt` extension defines a
`SpeedyAnalyticBandLongwave` scheme that subtypes `SpeedyWeather.AbstractLongwave`
and can be passed directly to `PrimitiveWetModel`:

```julia
using SpeedyWeather, NumericalRadiation
const SpeedyExt = Base.get_extension(NumericalRadiation,
                                     :NumericalRadiationSpeedyWeatherExt)

spectral_grid = SpectralGrid(trunc = 31, nlayers = 8)
longwave      = SpeedyExt.SpeedyAnalyticBandLongwave(spectral_grid)
model         = PrimitiveWetModel(spectral_grid; longwave_radiation = longwave)
```

## With Breeze

The Breeze extension is a scaffold: it defines `SpectralOptics`, the
`RadiativeTransferModel(grid, ::SpectralOptics, constants; …)` constructor,
and the kernel skeleton. Full integration (ZFaceField flux allocation,
reference-pressure plumbing, surface albedo handling) is tracked as a
follow-up and will mirror the
[BreezeRRTMGPExt](https://github.com/NumericalEarth/Breeze.jl/tree/main/ext/BreezeRRTMGPExt)
gray-radiation constructor.

## Schemes at a glance

| Scheme | Purpose | References |
|---|---|---|
| `WilliamsLongwave` | 41-band clear-sky LW | Williams (2026); Armstrong (1968); Mlawer et al. (1997) |
| `TransparentShortwave` | Zero-atmosphere SW; surface-albedo only | — |
| `OneBandShortwave` | SPEEDY moist SW (diagnostic clouds + background transmissivity) | Kucharski, Molteni & Bracco (2006) |
| `OneBandGreyShortwave` | SPEEDY dry SW (no clouds, constant transmissivity) | Kucharski, Molteni & Bracco (2006) |
| `DiagnosticClouds` | Cloud cover from RH + precipitation; stratocumulus from DSE stability | SPEEDY §B4 |
| `BackgroundShortwaveTransmissivity` | Dry-air + aerosol + WV + cloud absorptivities, pressure-weighted | SPEEDY §B4 |
| `ConstantShortwaveTransmissivity` | Single-value column transmissivity | — |

## Tests

```
julia --project=. -e 'using Pkg; Pkg.test()'
```

## Validation platform

The development and validation harness — the ecRad/ecCKD accuracy gates, the
frozen evidence and diagnostics they produced, and the gate-4 CKDMIP training
pipeline (published ecCKD model recovery) — lives on the
[`validation-platform`](https://github.com/NumericalEarth/NumericalRadiation.jl/tree/validation-platform)
branch. This branch carries only the package. The ecRad reference NetCDF data
used by that platform is distributed as the `validation-data-v1` release
(the lazy `ecrad_reference_data` artifact pinned in `Artifacts.toml`).

## License

MIT. See [LICENSE](./LICENSE).
