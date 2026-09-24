# Changes to `src/` compared to `main`, and why

Companion to [ecckd_speedyweather.md](ecckd_speedyweather.md) and
[extension_upstream.md](extension_upstream.md). The guiding rule for the
SpeedyWeather coupling is to keep changes to the package's core small and to
prefer the host side (SpeedyWeather's `SpeedyWeatherNumericalRadiationExt`, where
the coupling code lives) whenever that is possible without giving up
performance. This file lists every change to `src/` that PR #16 makes relative
to `main` (as of `f3d6ff5`, 2026-09-24), what forced it, what the alternative
would have been, and how it is tested. Nothing here changes numerical results
of existing code paths; every change is a type-parameter relaxation, an optional
argument, or an addition.

| # | Change | File | Lines | Results changed |
|---|---|---|---|---|
| 1 | `AtmosphereProfile`: one array-type parameter per vector | `src/column_views.jl` | ~10 | no |
| 2 | `ColumnAtmosphere`: one array-type parameter per array | `src/runtime_interfaces.jl` | ~12 | no |
| 3 | Optional caller-owned `ShortwaveColumnScratch` argument of `radiative_fluxes!(…, CloudlessShortwave(), …)` | `src/solvers/cloudless_shortwave.jl` | ~8 | no |
| 4 | `ClearSkyEcCKDRadiation` and `default_ozone_profile`: the configured clear-sky ecCKD column scheme | `src/ecckd_radiation.jl` (new), `src/NumericalRadiation.jl` | ~105 | no (addition) |

Three further changes that this work carried at some point were superseded by
`main` and are no longer part of the diff; they are listed at the end.

## 1. `AtmosphereProfile{NF, VT, VQ, VG}` (was `{NF, V}`)

*File:* `src/column_views.jl`.

*What forced it.* The analytic-band adapter builds an `AtmosphereProfile` from
views into SpeedyWeather arrays. Since SpeedyWeather 0.22 the temperature and
humidity views come from stepped three-dimensional arrays
(`get_prognostic_step(vars.grid.temperature, ...)`) while the geopotential view
comes from a plain two-dimensional field. Their `SubArray` types differ, and
the old struct forced all three vectors to share one type `V`; construction
threw a `MethodError` in `convert`.

*Alternative considered.* Copying the geopotential into a scratch view of the
same shape as the temperature step view. That costs a copy per column per
step for a type-system artefact, and the scratch array would have to mirror
the time-step layout of the prognostic arrays.

*Why acceptable.* Only the type parameters changed; the constructor converts
`surface_pressure`, `rain_rate` and `CO₂` to `NF` as before. No code in the
package dispatched on the second parameter (`radiative_transfer_column.jl` and
`williams_longwave.jl` use `AtmosphereProfile{NF}`).

*Tests.* The extension test `test/test_with_speedyweather.jl` constructs the
profile from real SpeedyWeather views; the solver suite is unchanged.

## 2. `ColumnAtmosphere{FT, PL, PI, TL, TI, G, S, Geo}` (was `{FT, A, G, S, Geo}`)

*File:* `src/runtime_interfaces.jl`.

*What forced it.* The same problem for the staged interface: layer
temperature is a view into a stepped prognostic array, layer pressure a view
into a `(npoints, nlayers)` work array, interface quantities views into
`(npoints, nlayers + 1)` work arrays. Three different `SubArray` types where
the struct demanded one.

*Alternative considered.* Copying the layer temperature into a work array
every column. Same objection as in 1.

*Why acceptable.* `heating_rates!`, `optical_properties!` and the solvers read
the arrays element-wise and convert to their working precision; none of them
dispatched on the array type. The docstring states that `FT` is the element
type of `temperature_layers`.

*Tests.* `test/test_host_interface.jl`, "ColumnAtmosphere from differently
shaped host views": optics, fluxes and heating rates from views of a 2D/3D host
layout are identical to those from plain vectors.

## 3. Optional `scratch` argument of `radiative_fluxes!(…, CloudlessShortwave(), …)`

*File:* `src/solvers/cloudless_shortwave.jl`.

*What forced it.* The Rayleigh (scattering) path of the clear-sky shortwave
solver needs seven work vectors. Before `main`'s refactor they were allocated
per g-point and per column (about 400 allocations per column per step for the
32-g-point model); `main` now allocates one `ShortwaveColumnScratch` per
`radiative_fluxes!` call, i.e. seven vectors per column per step. Inside
SpeedyWeather's fused column kernel that is still the only allocation in the
hot loop on CPU and a compile failure on GPU, and the extension cannot avoid
it without dropping Rayleigh scattering.

*Alternative considered.* This work originally carried its own
`CloudlessShortwaveWorkspace` type and a rewritten accumulation; at the first
merge of `main` that was dropped in favour of `main`'s type.

*What changed.* `radiative_fluxes!` gained an optional last positional
argument `scratch::ShortwaveColumnScratch`, defaulting to the allocation
`main` already did. A host passes seven column views through the type's
positional constructor. No other line of the solver changed.

*Tests.* `test/test_host_interface.jl`, "CloudlessShortwave with a
caller-owned scratch": identical fluxes with and without the argument, zero
allocations with it, a scratch built from views.

## 4. `ClearSkyEcCKDRadiation` (new file `src/ecckd_radiation.jl`, one `include`)

*What forced it.* With the coupling moved into SpeedyWeather, the extension there
adds methods to this package's scheme types instead of defining wrapper types of
its own (`AnalyticBandLongwave` needed nothing). The ecCKD path had no scheme
type: `EcCKDTabulatedGasOpticsModel` is a coefficient table, and the coupling
needs configuration with no other home, the mole fractions of the gases a host
does not carry (ozone, further gases) and the surface emissivity, implicitly
also the solver pair. `ClearSkyEcCKDRadiation` bundles gas optics,
`mole_fractions` (numbers or functions of pressure, `o3` and `co2` defaults,
every further gas of the model required) and `surface_emissivity`; constructors
from a tabulated model, from a number format and reference model pair, and a
converting `{FT}` form; `default_ozone_profile` moved here from the extension.

*Alternative considered.* Keeping a SpeedyWeather-side type (needs an exported
type, an `ArgumentError` stub and a `src` file in SpeedyWeather for what is
NumericalRadiation configuration), or extending the coefficient table directly
with hard-coded defaults (no user configuration, and a type change once clouds
or emissivities become configurable).

*Why acceptable.* Purely additive, host-neutral (Breeze needs the same
configuration), no existing code path changes. The SpeedyWeather extension
`import`s the name at load time, so it has to be part of this PR.

*Tests.* `test/test_ecckd_radiation.jl` (construction, defaults, conversion,
missing-gas error); the coupling tests in `test/speedyweather/` and SpeedyWeather's
`test/numericalradiation/` use it end to end.

## Superseded by `main` during the merges

Written here first, then dropped when `main` provided the same:

- **`surface_longwave_emission!` (in place).** `main`'s streaming column API
  (PR #20, Breeze coupling) added `TabulatedSurfaceEmission(model, T; emissivity)`,
  a lazy `AbstractVector` whose `getindex(g)` evaluates the source table for one
  g point; a host passes it as `surface_longwave_up`, or blends two of them per g
  point as the SpeedyWeather extension does for ocean and land, without any
  allocation.
- **`EcCKDTabulatedGasOpticsModel{FT}(model)`.** `main` added the same method,
  converting every array through an `Adapt` storage adaptor, sharing arrays already
  in `FT`, and working on device arrays. The behavioural tests written here were kept.
- **Two-stream direct-beam singularity guard.** The Meador-Weaver direct-beam terms
  divide by `1 - (λμ₀)²`; the old guard detected μ₀ within 1000 ulps of the pole but
  nudged it by 10 ulps, which in Float32 could land exactly on the pole and produced
  NaN fluxes in a coupled SpeedyWeather run (found with
  `validation/speedyweather_nan_detector.jl`). This work moved μ₀ to the nearer edge
  of the band; `main` fixed the same pole independently (54b6a75, found in a Breeze
  Float32 run) by stepping to the lower edge with a branch-free `ifelse`. Same band,
  same escape size, so `main`'s version stands; the singularity scan in
  `test/test_host_interface.jl` stays as the regression test.

## Considered and deliberately not changed

- **`@boundscheck` around `check_ecckd_optics_shapes`.** The checks are O(1)
  size comparisons, negligible on CPU, and `@boundscheck` would only remove
  them if `optical_properties!` were inlined into the `@inbounds` caller, which
  it is not. Their `throw` paths need a kernel-safe variant for GPU anyway;
  revisit with the first GPU run.
- **Splitting `optical_properties!` per stream.** Unnecessary once SpeedyWeather
  bundles both streams into one component (upstream change U1): one call fills
  both streams, which is exactly what the component needs.
- **A `(ng, nlayers)`-major work-array layout accessor.** A `PermutedDimsArray`
  of the `(nlayers, ng)` column slice gives the package's `[ig, k]` indexing at
  no cost in the package; only if that shows up in profiles is a change
  warranted.
- **Gas-amount and interface-temperature helpers.** Host glue; they live in
  the extension (`gas_amounts!`, `interface_temperatures!`).
- **Broadcasts inside the solvers** (`fluxes.longwave_up .= 0` and the like).
  Fine on CPU; GPU kernels need scalar loops. Deferred to the GPU work in
  Phase 4 together with the bounds checks.
