# Plan: running ecCKD inside SpeedyWeather.jl

Status legend: `[ ]` open, `[~]` in progress, `[x]` done. Update the checkboxes
as work lands and link PRs next to the items.

Created 2026-09-11. Target versions: NumericalRadiation 0.1.x,
SpeedyWeather 0.22.x plus the upstream changes tracked in
[speedyweather_upstream.md](speedyweather_upstream.md).

Changes that land in SpeedyWeather itself are planned in that companion
file and only referenced here as **U1 … U4**.

Every change made to this package's `src/` for the coupling is listed and
justified in [src_changes_for_speedyweather.md](src_changes_for_speedyweather.md).

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

Implemented 2026-09-11 on `mg/adjust-to-speedy`, clear-sky, CPU.

- [x] `EcCKDRadiation{NF} <: SpeedyWeather.AbstractRadiation` in
      `ext/NumericalRadiationSpeedyWeatherExt/ecckd_radiation.jl` (the extension
      is now a directory: module file, `analytic_band_longwave.jl`,
      `ecckd_radiation.jl`): one component for both
      streams holding the tabulated gas optics (converted to the grid's `NF` at
      construction), `Adapt.@adapt_structure`. Options: `CO₂` default [ppm]
      (used when the model has no `greenhouse_gases.co2`), `ozone` (function of
      pressure or constant; crude Chapman-layer default), `mole_fractions` for
      any further gas of the ecCKD model (required, checked at construction),
      ocean / land emissivity, molar masses. Constructors take a gas-optics
      model, a reference pair name (`"32x32"`, loads via NCDatasets), or nothing
      (default pair). Used as `PrimitiveWetModel(spectral_grid; radiation = EcCKDRadiation(spectral_grid))`.
- [ ] ~~Thin `EcCKDLongwave` / `EcCKDShortwave` wrappers.~~ Not done; low
      priority, they would redo gas optics per stream.
- [x] ~~Load tables in `initialize!`.~~ Changed: tables are loaded and
      converted in the constructor instead. Keeps the struct immutable and
      GPU-adaptable, and `variables` needs the g-point counts before
      `initialize!` runs. NCDatasets stays out of the hot path either way.
- [x] Extension helper `gas_amounts!`: specific humidity, layer Δp, gravity and
      the CO₂ mole fraction → per-layer molar amounts of every gas of the
      model, unrolled over the gas names with a `@generated` function;
      `composite` = dry air, `h2o` from `q`, `co2` from ppm, others from
      `mole_fractions`.
- [x] Extension helper `interface_temperatures!`: linear in pressure between
      layer centres, `T[1]` at the top, air temperature extrapolated in
      pressure at the bottom. The first version used the blended skin
      temperature at the bottom half level (as IFS does with its metre-thin
      lowest layer); with SpeedyWeather's 100 hPa lowest layer that made the
      layer radiate downward at skin temperature, land surfaces ran away to
      400 K and the model went NaN within a day (found in Phase 4).
- [x] `variables(::EcCKDRadiation, model)`: standard shortwave and longwave
      diagnostics plus a `:ecckd` namespace of work arrays: layer pressure
      (`GridXYZ`), interface pressure and temperature, four interface fluxes,
      one per-g surface-emission vector (`Grid3D`), gas amounts and the seven
      optical-property arrays (`Grid4D(n = ngas | ng)`), and the seven shortwave
      adding-method work arrays. Column views of these build
      `ColumnAtmosphere`, `LongwaveOptics`, `ShortwaveOptics`, `RadiativeFluxes`
      and `ShortwaveColumnScratch` without allocation; the `(nlayers, ng)`
      column slice is wrapped in a `PermutedDimsArray` for `[ig, k]` indexing.
- [x] `parameterization!(ij, vars, ::EcCKDRadiation, model)`, split into
      `ecckd_surface_state`, `ecckd_column_atmosphere!`, `ecckd_column_optics`,
      `ecckd_longwave!`, `ecckd_shortwave!`, `ecckd_heating!`: pressures from
      the vertical coordinates, gas amounts, CO₂ from the greenhouse-gas
      variable, interface temperatures; `optical_properties!` once; longwave
      with spectral surface emission blended over ocean and land (two lazy
      `TabulatedSurfaceEmission` vectors blended per g point); shortwave only for `cos_zenith > 0`
      with TOA down = `solar_constant * cos_zenith` and blended albedo;
      diagnostics including the ocean / land splits; net flux convergence of
      both streams into `dTdt` via SpeedyWeather's `flux_to_tendency`.
- [x] Package change, revised at the merge with `main` (2026-09-22): the
      Rayleigh path of `CloudlessShortwave` used to allocate its work vectors
      per g-point and per column. This branch first added a
      `CloudlessShortwaveWorkspace`; `main` meanwhile introduced
      `ShortwaveColumnScratch` for the streaming API and allocates one per
      `radiative_fluxes!` call. The merged version keeps `main`'s type and only
      adds an optional caller-owned `scratch` argument to `radiative_fluxes!`,
      so the extension passes seven column views and the call is
      allocation-free (checked in `test/test_host_interface.jl`).
- [x] Clear-sky only in this version. Cloud coupling (package has
      cloud-overlap solvers, SpeedyWeather has no cloud state) is a follow-up.
- [x] Tests in `test/test_with_speedyweather.jl`: construction and work-array
      sizes on the reference 32x32 model, missing-gas error; a realistic column
      (OLR range, surface budget signs, shortwave transmission, moderate heating
      rates, column energy conservation to 1e-3, night = zero shortwave with
      unchanged longwave, 4×CO₂ reduces OLR by a few W/m²); fluxes of one
      column agree with the staged API called directly on the same inputs; a
      4-step full model run.
- [x] README "With SpeedyWeather.jl" updated.

Known limitations of this first version: clear sky; ozone from an analytic
default profile (**U2**); the package's shape checks and broadcasts inside
`optical_properties!` / `radiative_fluxes!` are not yet GPU-safe (Phase 4);
`co2` is a single global value from `greenhouse_gases`.

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

Started 2026-09-11 on `mg/adjust-to-speedy`. Scripts in `validation/`
(`speedyweather_ecckd_budget.jl`, `speedyweather_ecckd_benchmark.jl`,
`speedyweather_nan_detector.jl`), to be
run in an environment that develops NumericalRadiation and the U1 SpeedyWeather
branch with NCDatasets and Statistics.

- [x] Test: one SpeedyWeather column through `EcCKDRadiation` vs. the same
      inputs through the staged API directly; fluxes agree to 2e-3 (Float32 vs
      Float64). Done as part of the Phase 2 tests.
- [x] **Stability.** The first 20-day comparison went NaN after 1 to 4 days.
      Two causes, both fixed:
      1. *Bottom interface temperature.* Using the skin temperature for the
         lowest half level (as IFS does) makes SpeedyWeather's 100 hPa thick
         lowest layer radiate downward at skin temperature; land ran away to
         400 K within a day. Now the air temperature is extrapolated in
         pressure; the skin temperature enters only through the surface
         emission.
      2. *Two-stream singularity (package bug, `src` change 7; re-applied to
         `main`'s `shortwave_reflectance_transmittance` at the merge).* One column
         with cos_zenith = 0.50002 hit k·μ0 = 1.0000012 in one g-point; the
         guard's 10-ulp nudge was smaller than its 1000-ulp detection band and
         landed on the singularity in Float32, giving NaN shortwave fluxes that
         poisoned the state within one step. Found with a per-step callback
         dumping the first non-finite column. The guard now moves μ0 to the
         band edge. With both fixes a 12-day run with the detector shows no
         non-finite value.
      Control: SpeedyWeather's own one-band scheme without clouds runs 10 days
      stably with land surfaces reaching 360 K, so the hot land under clear
      skies is a host property (bucket land model, no clouds), not a coupling
      error.
- [x] Budget comparison at T31 L8, 10 days spin-up + 10 days of daily
      snapshots (instantaneous global means of insolation are exact since the
      global mean of cos_zenith is 1/4 at any instant): one-band default,
      ecCKD 32x32, ecCKD 32x32 without ozone, ecCKD 64x96. Results below.
- [x] Per-column benchmark of one-band, analytic-band longwave, ecCKD 32x32
      and 64x96 inside `column_parameterizations!`. Results below.
- [x] ~~GPU smoke test.~~ Not possible on this machine: SpeedyWeather itself
      fails to compile for Metal (`initialize_hyperdiffusion_kernel!` uses
      Float64 constants, "unsupported use of double value") before any
      radiation code runs. Needs a CUDA machine; the known blockers on our
      side (throwing shape checks, broadcasts in the solvers) are unchanged.
- [ ] CI: gate ecCKD tests on the artifact download; reuse
      `RH_ECRAD_DATA_PATH`.
- [x] `examples/speedyweather_ecckd.jl`: a five-plus-five-day version of the
      budget comparison (one-band vs ecCKD 32x32) with a figure of zonal-mean
      outgoing fluxes and the temperature profile; listed in `examples/README.md`,
      not in the docs build.

### Results (2026-09-11, T31 L8, Float32, Apple M3, single thread)

Global means over days 11 to 20, W m⁻² unless noted:

| config | OLR | OSR | TOA net ↓ | albedo | sfc SW ↓ | sfc LW ↓ | T(k=1) K | T(k=8) K | s/step |
|---|---|---|---|---|---|---|---|---|---|
| one-band default (with clouds) | 251.1 | 79.0 | 11.2 | 0.231 | 205.4 | 339.7 | 210.3 | 280.4 | 0.029 |
| ecCKD 32x32 | 246.8 | 36.1 | 58.3 | 0.106 | 247.1 | 303.1 | 213.0 | 282.9 | 0.097 |
| ecCKD 32x32, no ozone | 253.1 | 41.5 | 46.6 | 0.122 | 256.8 | 301.4 | 192.9 | 282.9 | 0.092 |
| ecCKD 64x96 | 246.5 | 36.6 | 58.1 | 0.107 | 247.2 | 303.1 | 211.9 | 282.9 | 0.202 |

TOA insolation 341.2 in all cases (S₀ = 1365).

Reading:
- The ecCKD numbers are what a clear-sky atmosphere should give: planetary
  albedo 0.11 from Rayleigh scattering plus a mostly ocean surface, OLR
  247. The +58 W m⁻² TOA imbalance is the missing cloud effect (clouds are
  worth roughly −45 W m⁻² net in the real budget), not a coupling error; it is
  the argument for the cloud follow-up.
- Ozone matters at this vertical resolution: the top layer is 20 K colder
  without it (193 vs 213 K, the one-band model sits at 210 K). The analytic
  default profile is a placeholder, but leaving ozone out is worse (**U2**).
- 64x96 is indistinguishable from 32x32 in this configuration (OLR within
  0.3 W m⁻², temperatures within 1 K) at twice the cost: 32x32 is the right
  default.
- Antarctic OLR (checked 2026-09-11 because the example's zonal mean showed
  245 W m⁻² at 85°S against 185 for one-band): after 5 days the ecCKD run's
  Antarctic land is at 280 K (one-band: 251 K) because it receives 420 W m⁻²
  of clear-sky shortwave in polar day against 237 under the one-band's
  diagnostic clouds, and SpeedyWeather's bucket land has no ice-sheet albedo.
  The radiation itself is consistent: spectral surface emission integrates to
  0.98 σT⁴ of the soil temperature, downward longwave is 124 W m⁻² for a dry
  210–245 K column (one-band: 132), and the upward flux is attenuated from
  340 at the surface to 234 at the top. A host limitation (land albedo over
  ice sheets, no clouds), not a coupling error.

Per-column cost of `column_parameterizations!` with radiation as the only
column parameterization (3168 columns, 8 layers):

| scheme | μs per column | allocations per call |
|---|---|---|
| one-band shortwave + longwave | 0.3 | 0 |
| analytic-band longwave | 20.3 | 101 376 |
| ecCKD 32x32 | 23.9 | 0 |
| ecCKD 64x96 | 60.8 | 0 |

ecCKD 32x32 makes the whole model 3.3× slower at T31 L8 (0.029 → 0.097 s per
step), i.e. radiation is then ~70 % of the run time. Calling it every third
step (**U3**) would bring the total back to roughly 0.05 s per step; at
higher resolution the ratio stays similar since both dynamics and radiation
scale with the number of columns. Side finding: the analytic-band longwave
adapter allocates (~32 allocations per column, from `LongwaveDiagnostics` and
the profile views); worth fixing separately.

## Open decisions

- Default reference model pair: proposed `climate_32x32`.
- Ozone source until **U2** lands: ship a zonal-mean profile in the extension
  or require the user to pass one.
- Scope of back-compat in **U1** (deprecation shims for the old keywords).
