<!-- Title -->
<h1 align="center">
  NumericalRadiation.jl
</h1>

<!-- description -->
<p align="center">
  <strong>☀️ Atmospheric radiative transfer and gas optics in Julia, compatible with ECMWF's ecRad/ecCKD data, for CPUs and GPUs. https://NumericalEarth.github.io/NumericalRadiation.jl/dev</strong>
</p>

<!-- Information badges -->
<p align="center">
  <a href="https://github.com/NumericalEarth/NumericalRadiation.jl/releases">
    <img alt="GitHub tag (latest SemVer pre-release)" src="https://img.shields.io/github/v/tag/NumericalEarth/NumericalRadiation.jl?include_prereleases&label=latest%20version&logo=github&sort=semver&style=flat-square">
  </a>
  <a href="https://www.apache.org/licenses/LICENSE-2.0">
    <img alt="Apache 2.0 license" src="https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=flat-square">
  </a>
  <a href="https://github.com/SciML/ColPrac">
    <img alt="ColPrac: Contributor's Guide on Collaborative Practices for Community Packages" src="https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet?style=flat-square">
  </a>
</p>

<!-- Documentation -->
<p align="center">
  <a href="https://NumericalEarth.github.io/NumericalRadiation.jl/stable">
    <img alt="Stable documentation" src="https://img.shields.io/badge/documentation-stable%20release-blue?style=flat-square">
  </a>
  <a href="https://NumericalEarth.github.io/NumericalRadiation.jl/dev">
    <img alt="Development documentation" src="https://img.shields.io/badge/documentation-in%20development-orange?style=flat-square">
  </a>
</p>

<!-- Testing -->
<p align="center">
  <a href="https://github.com/NumericalEarth/NumericalRadiation.jl/actions/workflows/CI.yml">
    <img alt="CI" src="https://github.com/NumericalEarth/NumericalRadiation.jl/actions/workflows/CI.yml/badge.svg">
  </a>
  <a href="https://github.com/NumericalEarth/NumericalRadiation.jl/actions/workflows/Documenter.yml">
    <img alt="Documenter" src="https://github.com/NumericalEarth/NumericalRadiation.jl/actions/workflows/Documenter.yml/badge.svg">
  </a>
</p>

NumericalRadiation computes atmospheric radiative fluxes and heating rates. It ingests
reference ecCKD CKD-definition files into typed, `Adapt.jl`-aware look-up tables, evaluates
g-point optical properties through a staged runtime (`optical_properties!` → `radiative_fluxes!` →
`heating_rates!`), and solves clear-sky and cloud-overlap two-stream column transport.

It also bundles two analytic-band per-column schemes for intermediate-complexity models:

- **Longwave** — Williams (2026) *Simple Spectral Model*: a 41-wavenumber
  clear-sky two-stream Schwarzschild solver with analytic H₂O line,
  H₂O continuum and CO₂ absorption coefficients.
  Published in *J. Adv. Model. Earth Syst.*, doi:[10.1029/2025MS005405](https://doi.org/10.1029/2025MS005405).
- **Shortwave** — a one-band scheme after SPEEDY (Kucharski, Molteni & Bracco,
  *Quart. J. Roy. Meteor. Soc.*, 2006), with transparent, constant, or
  Kucharski-style background-transmissivity options and a diagnostic
  cloud/stratocumulus model.

The analytic-band solvers are pure scalar ingredients that a host model can
fuse into its own column loops or kernels, and the ecCKD path has the same
scalar form; see [Host kernels (Breeze)](#host-kernels-breeze) and
[With SpeedyWeather.jl](#with-speedyweatherjl) below.

## Contents

- [Installation instructions](#installation-instructions)
- [Running your first column](#running-your-first-column)
- [With SpeedyWeather.jl](#with-speedyweatherjl)
- [Host kernels (Breeze)](#host-kernels-breeze)
- [Schemes at a glance](#schemes-at-a-glance)
- [Getting help](#getting-help)
- [Running the tests](#running-the-tests)
- [Validation platform](#validation-platform)
- [License](#license)

## Installation instructions

NumericalRadiation is a [registered Julia package](https://julialang.org/packages/). So to install it,

1. [Download Julia](https://julialang.org/downloads/) (version 1.10 or later).

2. Launch Julia and type

```julia
julia> using Pkg

julia> Pkg.add("NumericalRadiation")
```

This installs the latest version that's _compatible with your current environment_.
Check which NumericalRadiation you installed with

```julia
julia> Pkg.status("NumericalRadiation")
```

## Running your first column

Bundle the grid, profile, surface, schemes, constants, and pre-allocated
buffers into a single `RadiativeTransferColumn` and call the solvers
with one argument:

```julia
using NumericalRadiation

Nz = 8
σ_half  = collect(range(0.0, 1.0, length=Nz + 1))
grid    = ColumnGrid(σ_half)

# Lapse-rate profile: top of atmosphere (k=1) cold, surface (k=Nz) warm.
profile = AtmosphereProfile(
    temperature      = collect(range(220.0, 295.0, length=Nz)),
    humidity         = fill(0.005, Nz),
    geopotential     = zeros(Nz),
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
column = RadiativeTransferColumn(; grid, profile, surface)

solve_longwave!(column)
solve_shortwave!(column)

@show column.longwave_diagnostics.outgoing_longwave        # W m⁻²
@show column.longwave_diagnostics.surface_longwave_down    # W m⁻²
@show column.shortwave_diagnostics.surface_shortwave_down  # W m⁻²
@show column.temperature_tendency                           # K s⁻¹ per layer
```

For the low-level kernel form (what host couplings such as SpeedyWeather's
`SpeedyWeatherNumericalRadiationExt` call internally), `solve_longwave!` and `solve_shortwave!` accept the
flattened `(temperature_tendency, diagnostics, scheme, profile, grid, surface, constants, …)`
signature directly, and the `constants` argument is duck-typed — any struct
or NamedTuple carrying `gravity`, `heat_capacity`, `stefan_boltzmann`,
`solar_constant` properties works. The staged runtime reads the same kind of
object from `ColumnAtmosphere.constants` (a `PhysicalConstants` by default,
which also carries `dry_air_molar_mass`, `water_molar_mass`,
`dry_air_gas_constant`, `universal_gas_constant` and `avogadro_number`), so
no physical constant is hard-coded anywhere on the radiation path.

All floating-point types default to `Float64`. To run in `Float32` (useful for
GPU kernels), pass the type as the first positional argument to the scheme
constructors and readers: `AnalyticBandLongwave(Float32)`,
`OneBandShortwave(Float32)`, `read_reference_ecckd_gas_optics(Float32, "32x32")`,
`SpectralCloudOptics(Float32, table, mapping; effective_radius)`, etc.

## With SpeedyWeather.jl

The coupling to [SpeedyWeather.jl](https://github.com/SpeedyWeather/SpeedyWeather.jl)
lives in SpeedyWeather as the extension `SpeedyWeatherNumericalRadiationExt`, activated
when both packages are loaded. It makes this package's `ClearSkyEcCKDRadiation` (clear-sky ecCKD gas
optics, longwave and shortwave from one gas-optics evaluation) and `AnalyticBandLongwave`
usable as SpeedyWeather radiation schemes and adds constructors from a `SpectralGrid`:

```julia
using SpeedyWeather, NumericalRadiation

spectral_grid = SpectralGrid(truncation = 32, nlayers = 8)
model = PrimitiveWetModel(spectral_grid; radiation = ClearSkyEcCKDRadiation(spectral_grid))   # or "64x96"
# or the analytic-band longwave next to SpeedyWeather's one-band shortwave:
longwave = AnalyticBandLongwave(spectral_grid)   # CO₂ from the model's greenhouse gases, else 280 ppm
model = PrimitiveWetModel(spectral_grid; radiation = Radiation(spectral_grid; longwave))
```

CO₂ follows the model's `greenhouse_gases`, ozone comes from an analytic default
profile (`ozone = p -> ...` to override), and further gases of the ecCKD model are
prescribed with `mole_fractions = (; ch4 = 1.8e-6)`; see `ClearSkyEcCKDRadiation`.
The full tests of the coupling (`test/speedyweather/`, an environment of its own
because they need SpeedyWeather ≥ 0.23 with its NumericalRadiation extension), the
example `examples/speedyweather_ecckd.jl` and the validation scripts in
`validation/` stay in this repository.

## Host kernels (Breeze)

The ecCKD gas optics and the clear-sky solvers are also exposed as scalar,
per-layer, per-g-point functions that a host model calls inside its own
column kernels without allocating: [`gas_optics_stencil`](https://NumericalEarth.github.io/NumericalRadiation.jl/dev/gas_optics/streaming_column_api/)
brackets a layer on the coefficient tables once, `longwave_optical_depth`,
`shortwave_optical_depth`, `rayleigh_optical_depth` and `longwave_source`
evaluate one g point at a time from a `NamedTuple` of scalar gas amounts, and
`streaming_longwave_fluxes!` / `streaming_shortwave_fluxes!` sweep one column
through layer-optics functors with caller-owned scratch (a
`TabulatedSurfaceEmission` surface source and a `ShortwaveColumnScratch`).
`SpectralCloudOptics` adds per-g-point cloud optics to the same loop. The
array methods (`optical_properties!`, `radiative_fluxes!`) are loops over
these functions, so the two paths agree bit for bit — the longwave path and
every shortwave g point that scatters; a shortwave g point with no scattering
at all takes a closed-form Beer–Lambert branch in the array solver that
treats the surface-reflected flux as a slant beam rather than diffuse, see the
streaming column API page. Every function is `@inline`, allocation-free and
`Adapt.jl`-aware, so the loop runs unchanged on GPU. This is the API the
`NumericalRadiation` extension of
[Breeze.jl](https://github.com/NumericalEarth/Breeze.jl) (in progress) is
built on; the
[streaming column API](https://NumericalEarth.github.io/NumericalRadiation.jl/dev/gas_optics/streaming_column_api/)
page walks through the loop on a two-layer column.

## Schemes at a glance

| Scheme | Purpose | References |
|---|---|---|
| `AnalyticBandLongwave` | 41-band clear-sky LW | Williams (2026); Armstrong (1968); Mlawer et al. (1997) |
| `NumericalRadiation.TransparentShortwave` (unexported) | Zero-atmosphere SW; surface-albedo only | — |
| `OneBandShortwave` | SPEEDY moist SW (diagnostic clouds + background transmissivity) | Kucharski, Molteni & Bracco (2006) |
| `NumericalRadiation.OneBandGreyShortwave` (unexported) | SPEEDY dry SW (no clouds, constant transmissivity) | Kucharski, Molteni & Bracco (2006) |
| `DiagnosticClouds` | Cloud cover from RH + precipitation; stratocumulus from DSE stability | SPEEDY §B4 |
| `BackgroundShortwaveTransmissivity` | Dry-air + aerosol + WV + cloud absorptivities, pressure-weighted | SPEEDY §B4 |
| `ConstantShortwaveTransmissivity` | Single-value column transmissivity | — |

## Getting help

* The [documentation](https://NumericalEarth.github.io/NumericalRadiation.jl/dev/) has a quickstart, the physics and numerics behind each scheme, and a library of every user-facing object and function.
* [Issues](https://github.com/NumericalEarth/NumericalRadiation.jl/issues) and [pull requests](https://github.com/NumericalEarth/NumericalRadiation.jl/pulls) record problems we've found, how we solved them, and what we're working on.
* The [NumericalEarth slack](https://join.slack.com/t/numericalearth/shared_invite/zt-3pwpvky4k-XX7RkgQgHLIUt~wtwGXN~Q) is a good place to ask questions.

## Running the tests

```julia
julia> using Pkg

julia> Pkg.test("NumericalRadiation")
```

## Validation platform

The development and validation harness — accuracy gates, reference manifests,
frozen evidence, and the training pipeline — lives on the
[`validation-platform`](https://github.com/NumericalEarth/NumericalRadiation.jl/tree/validation-platform)
branch; this branch carries only the package.

## License

Apache 2.0. See [LICENSE](./LICENSE).
