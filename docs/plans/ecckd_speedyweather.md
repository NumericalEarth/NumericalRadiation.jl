# Plan: running ecCKD inside SpeedyWeather.jl

Status legend: `[ ]` open, `[~]` in progress, `[x]` done. Update the checkboxes
as work lands and link PRs next to the items.

Created 2026-09-11. Target versions: NumericalRadiation 0.1.x,
SpeedyWeather 0.22.x plus the upstream changes tracked in
[speedyweather_upstream.md](speedyweather_upstream.md).

Changes that land in SpeedyWeather itself are planned in that companion
file and only referenced here as **U1 … U4**.

**2026-09-22: the extension moved upstream.** The coupling now lives in SpeedyWeather as
`SpeedyWeatherNumericalRadiationExt` (this package's `ClearSkyEcCKDRadiation` and `AnalyticBandLongwave`
as SpeedyWeather schemes), see
[extension_upstream.md](extension_upstream.md) and item U5 of the companion file. Phases 0
and 2 below describe code that is now in SpeedyWeather; the package changes (Phase 1, the
`src` changes) and the tests, example and validation scripts of the coupling stay here.

## Background

**What exists.** NumericalRadiation already has a complete, host-neutral
ecCKD column path, the staged API in `src/runtime_interfaces.jl`:

1. `read_reference_ecckd_gas_optics` loads an `EcCKDTabulatedGasOpticsModel`
   from the lazy `ecrad_data` artifact (NCDatasets extension).
2. `optical_properties!` (`src/gas_optics/ecckd_forward.jl`) fills
   `LongwaveOptics` and `ShortwaveOptics`, shaped `(ng, nlayers)`, for both
   streams from one pass over the gas tables.
3. `radiative_fluxes!` with `CloudlessLongwave` / `CloudlessShortwave`.
4. `heating_rates!` converts flux convergence to K s⁻¹.

`examples/ecckd_column.jl` is exactly the call sequence the SpeedyWeather
kernel must reproduce per column. Gas inputs are per-layer molar amounts in
mol m⁻², `composite` is the dry-air column, and the H2O mole fraction is
derived from `h2o / composite`.

**What is stale.** `ext/NumericalRadiationSpeedyWeatherExt.jl` only wraps the
analytic-band longwave and targets SpeedyWeather 0.20: it reads
`vars.grid.temperature_prev`, `vars.grid.pressure_prev` and
`model.land_sea_mask.mask`, none of which exist in 0.22. `Project.toml` pins
compat to 0.20.x.

**SpeedyWeather 0.22 contract for a radiation scheme.**

- `parameterization!(ij, vars, scheme, model)` is called once per column,
  fused into one GPU kernel over all parameterizations, in the fixed order
  zenith, albedo, shortwave, longwave.
- Today longwave and shortwave are separate model components; **U1**
  replaces them with one `radiation` component so a scheme can do both
  streams in one call.
- State access: `get_prognostic_step(vars.grid.temperature, model.time_stepping, scheme)`,
  same for humidity; `vars.parameterizations.surface_pressure[ij]`;
  `model.land_sea_mask.land_fraction[ij]`; pressures via `pressure_half` /
  `pressure_thickness(k, pₛ, model.geometry.vertical_coordinates)` (sigma or
  hybrid sigma-pressure).
- Outputs go to `vars.parameterizations.*` fields declared by `variables`.
  Extra per-column work arrays are declared the same way, e.g.
  `Grid4D(n)` allocates `(npoints, nlayers, n)`, `Grid3D(n)` allocates
  `(npoints, n)`; `variables(component, model)` can size them from `model`.
- Available inputs: layer T, specific humidity, pₛ, `cos_zenith`, ocean and
  land albedo, SST, soil temperature, land fraction, scalar CO2 [ppm] in
  `vars.prognostic.greenhouse_gases.co2[]` (if configured), solar constant,
  gravity, heat capacity.
- Not available: ozone (**U2**), CH4, N2O, cloud state, interface
  temperatures, surface emissivity.

**Data.** The lazy `ecrad_data` artifact is not installed locally; the first
run downloads the ecRad source archive (override with `RH_ECRAD_DATA_PATH`).
Which gases the reference files carry must be read from their `gas_names`.
ecCKD climate models normally include h2o, co2, o3, ch4, n2o and CFCs on top
of `composite`. Gases with a reference mole fraction that are omitted from
`names` are implicitly held at that reference value (acceptable default for
CH4 / N2O). Ozone is a linear gas and must be supplied.

## Ordering

```
U1 Radiation bundle (SpeedyWeather, bit-identical)  ──►  release
        │
        ▼
Phase 0 port extension to new SpeedyWeather ──► Phase 1 package prep ──► Phase 2 EcCKDRadiation ──► Phase 4 validation
                                                                                   ▲
U2 ozone, U3 call frequency, U4 array layout (SpeedyWeather, in parallel) ─────────┘
```

Phase 1 does not depend on U1 and can start immediately.

## Phase 0. Port the extension to the post-U1 SpeedyWeather

Done 2026-09-11 against the local U1 branch (SpeedyWeather 0.23.0-DEV, developed
via `Pkg.develop`). Depends on **U1** being *released* only for CI.

- [x] Bump compat in `Project.toml` to `SpeedyWeather = "0.23"`. Pkg accepts the
      developed `0.23.0-DEV` under this compat. Until 0.23 is registered the
      extension tests live in their own environment, `test/speedyweather/`,
      whose `[sources]` entry pulls the `mg/numericalradiation` branch of
      SpeedyWeather.jl (monorepo subdir `SpeedyWeather`); `[sources]` needs
      Julia ≥ 1.11, so that environment runs in a dedicated CI job on 1.11,
      while the package and its core tests keep supporting Julia 1.10
      (`test/Project.toml` is registry-only and `test/runtests.jl` skips the
      extension tests when SpeedyWeather is absent). Fold the environment back
      into `test/Project.toml` once SpeedyWeather 0.23 is released.
- [x] Port `SpeedyAnalyticBandLongwave` to 0.22+ accessors
      (`get_prognostic_step` / `get_tendency_step`, `vars.parameterizations.surface_pressure`,
      `land_sea_mask.land_fraction`, `vars.dynamics.geopotential`, stepped SST) and to
      being used as `Radiation(spectral_grid; longwave = SpeedyAnalyticBandLongwave(...))`.
      The kernel is `@propagate_inbounds`.
- [x] Unplanned core change: `AtmosphereProfile` now has one array-type parameter
      per vector (`VT`, `VQ`, `VG`). SpeedyWeather's temperature/humidity views come
      from stepped 3D arrays and the geopotential view from a plain 2D field, so a
      single `V` no longer fits. No other code depended on the two-parameter form.
- [x] `test/test_with_speedyweather.jl` rewritten for the new API (longwave-only
      model, CO₂ forcing, and a 4-step full `run!`); 16 tests pass with
      `--check-bounds=yes`. Core solver (692) and misc (33) tests still pass.
- [x] README "With SpeedyWeather.jl" updated; unused `RingGrids` dep and its
      `=0.1.7` pin dropped from `test/Project.toml`.

## Phase 1. Prepare NumericalRadiation for a fused, allocation-free kernel

Re-scoped 2026-09-11: keep changes to the package small. Only what cannot live
in the extension goes into `src/`; host glue moves to Phase 2. Done on
`mg/adjust-to-speedy`, tests in `test/test_host_interface.jl`.

Merged with `main` 2026-09-22. `main` had meanwhile grown the streaming
column API for the Breeze coupling, which provides two of the three items
below; this branch adopts `main`'s versions and drops its own.

- [x] ~~Split `optical_properties!` per stream.~~ Not needed: with **U1** a
      single `EcCKDRadiation` component consumes both streams from one call,
      which is exactly what `optical_properties!` produces today.
- [x] ~~In-place `surface_longwave_emission!`.~~ Superseded by `main`'s
      `TabulatedSurfaceEmission`, a lazy per-g-point `AbstractVector` that
      evaluates the source table on indexing and allocates nothing; it is
      accepted directly as `surface_longwave_up` in `LongwaveBoundaryConditions`.
- [x] ~~Element-type conversion `EcCKDTabulatedGasOpticsModel{FT}(model)`.~~
      Superseded by `main`'s method of the same name, implemented with an
      `Adapt` storage adaptor so it also converts on the device; arrays already
      of type `FT` are shared. The tests written here for the conversion were
      kept since they test behaviour, not implementation.
- [x] `ColumnAtmosphere` with one array-type parameter per array (as done for
      `AtmosphereProfile` in Phase 0): a host's layer and interface views come
      from arrays of different shape and, for stepped prognostics, different
      rank. Combined at the merge with `main`'s new `constants` field, which
      carries the host's `PhysicalConstants` (gravity, molar masses, heat
      capacity) into the gas optics and `heating_rates!`.
- [ ] ~~Guard `check_ecckd_optics_shapes` behind `@boundscheck`.~~ Deferred:
      the checks are O(1) size comparisons, negligible on CPU, and
      `@boundscheck` would only elide them if `optical_properties!` were
      inlined into the `@inbounds` caller, which it is not. A GPU run needs a
      kernel-safe variant of the `throw` paths anyway; revisit with the first
      GPU test in Phase 4.
- [ ] ~~Layout-agnostic accessor (U4).~~ Deferred to Phase 2: a permuted view
      of the `(nlayers, ng)` column slice keeps the package's `[ig, k]`
      indexing without any package change.
- [x] Unit tests: converted Float32 model reproduces Float64 optics to 1e-4;
      `ColumnAtmosphere` from views of a 2D/3D host layout gives results
      identical to plain vectors through optics, fluxes and heating rates.

Moved to Phase 2 (extension, host glue): gas amounts from specific humidity,
interface temperatures from layer temperatures.

## Phase 2. `EcCKDRadiation` SpeedyWeather component in the extension

Depends on Phase 0 and Phase 1.

- [ ] `EcCKDRadiation <: SpeedyWeather.AbstractRadiation`, one component for
      both streams, holding the gas-optics model, with
      `Adapt.@adapt_structure`. Options: model pair (default `"32x32"`),
      gas names, default CO2 when the model has no `greenhouse_gases`,
      prescribed ozone profile (until **U2**), ocean and land emissivity.
      Passed as `PrimitiveWetModel(spectral_grid; radiation = EcCKDRadiation(...))`.
- [ ] Optionally also thin `EcCKDLongwave <: AbstractLongwave` /
      `EcCKDShortwave <: AbstractShortwave` wrappers for mixed setups such as
      `Radiation(spectral_grid; longwave = EcCKDLongwave(...))`. Lower
      priority; they redo gas optics per stream.
- [ ] Load tables in `initialize!`, not the constructor, and convert to the
      grid's `NF` there (keeps NCDatasets out of the hot path, one download).
- [ ] Extension helper: specific humidity + layer Δp + gravity + CO2 mole
      fraction → `composite`, `h2o`, `co2` molar amounts (mol m⁻²), written
      into per-column work arrays (moved here from Phase 1).
- [ ] Extension helper: interface temperatures from layer temperatures and
      surface temperature (top interface = T[1], bottom = T_surface), written
      into a per-column work array (moved here from Phase 1).
- [ ] `variables(::EcCKDRadiation, model)`: the standard shortwave and longwave
      diagnostics (as declared by `variables(::AbstractShortwave)` /
      `variables(::AbstractLongwave)`) plus work arrays: LW optical
      depth, layer source, top/bottom interface sources as
      `Grid4D(n = ng_lw)`; SW optical depth, Rayleigh optical depth,
      asymmetry as `Grid4D(n = ng_sw)`; interface fluxes (4) and interface
      pressures / temperatures as `Grid3D(n = nlayers + 1)`; per-g surface
      emission as `Grid3D(n = ng_lw)`. Column views of these give
      `LongwaveOptics`, `ShortwaveOptics`, `RadiativeFluxes`,
      `ColumnAtmosphere` without allocation.
- [ ] `parameterization!(ij, vars, ::EcCKDRadiation, model)`:
      1. pressures from vertical coordinates, gas amounts via the Phase 1
         helper, CO2 from `vars.prognostic.greenhouse_gases.co2` when present,
         interface temperatures via the Phase 1 helper;
      2. `optical_properties!` once for both streams;
      3. longwave: blended surface emission from SST and soil temperature
         weighted by land fraction, `radiative_fluxes!(CloudlessLongwave)`,
         write `outgoing_longwave`, `surface_longwave_down`,
         `surface_longwave_up` and the ocean / land splits;
      4. shortwave: skip when `cos_zenith == 0`, TOA down =
         `solar_constant * cos_zenith`, blended ocean / land albedo,
         `radiative_fluxes!(CloudlessShortwave)`, write surface down / up,
         `outgoing_shortwave`, `albedo` and the ocean / land splits;
      5. total net flux convergence → `dTdt[ij, k]` via SpeedyWeather's
         `flux_to_tendency`.
- [ ] Clear-sky only in this version. Cloud coupling (package has
      cloud-overlap solvers, SpeedyWeather has no cloud state) is a
      follow-up.
- [ ] Update README "With SpeedyWeather.jl" section and docs.

## Phase 3. Upstream SpeedyWeather changes

Tracked in [speedyweather_upstream.md](speedyweather_upstream.md):

- **U1** one `radiation` component bundling shortwave and longwave,
  bit-identical with the existing schemes first. Prerequisite for Phase 0
  and 2.
- **U2** prescribed ozone.
- **U3** radiation call frequency.
- **U4** work-array layout for g-point arrays (or make NumericalRadiation
  layout-agnostic instead, Phase 1).

## Phase 4. Validation

- [ ] Test: one SpeedyWeather column through `EcCKDRadiation` vs. the same
      inputs through the staged API directly; fluxes agree to tolerance.
- [ ] Aquaplanet run at low resolution with `radiation = EcCKDRadiation(...)`:
      global-mean OLR ≈ 240 W m⁻², closed TOA budget, side-by-side against
      the default `Radiation(OneBandShortwave, OneBandLongwave)`.
- [ ] Per-column benchmark for the 32x32 and 64x96 pairs to size the
      call-frequency decision (**U3**).
- [ ] CI: gate ecCKD tests on the artifact download; reuse
      `RH_ECRAD_DATA_PATH`.

## Open decisions

- Default reference model pair: proposed `climate_32x32`.
- Ozone source until **U2** lands: ship a zonal-mean profile in the extension
  or require the user to pass one.
- Scope of back-compat in **U1** (deprecation shims for the old keywords).
