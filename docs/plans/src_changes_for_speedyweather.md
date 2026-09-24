# Changes to `src/` made for the SpeedyWeather coupling, and why

Companion to [ecckd_speedyweather.md](ecckd_speedyweather.md). The guiding rule
for that work is to keep changes to the package's core small and to prefer the
extension or SpeedyWeather itself whenever that is possible without giving up
performance. This file lists every change to `src/` on this branch
(`mg/adjust-to-speedy`, Phases 0 and 1 of the plan), what forced it, what the
alternative would have been, and how it is tested. Nothing here changes
numerical results of existing code paths. Later phases (the ecCKD coupling and
its validation) live on `mg/ecckd-speedy`, whose version of this file extends
the list. Since 2026-09-22 the coupling code itself lives in SpeedyWeather
(`SpeedyWeatherNumericalRadiationExt`, see [extension_upstream.md](extension_upstream.md)),
which added change 6 below.

| # | Change | Phase | Lines | Results changed |
|---|---|---|---|---|
| 1 | `AtmosphereProfile`: one array-type parameter per vector | 0 | ~10 | no |
| 2 | `ColumnAtmosphere`: one array-type parameter per array | 1 | ~12 | no |
| 3 | ~~`surface_longwave_emission!` (in place)~~ dropped on merging `main`, which provides `TabulatedSurfaceEmission` | 1 | 0 | no |
| 4 | ~~`EcCKDTabulatedGasOpticsModel{FT}(model)`~~ dropped on merging `main`, which added the same constructor | 1 | 0 | no |
| 5 | New test file in the runner | 1 | ~1 | no |
| 6 | `ClearSkyEcCKDRadiation`: configured clear-sky ecCKD scheme (new file `src/ecckd_radiation.jl`) | extension move | ~100 | no |

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

*What forced it.* The same problem for the staged interface, which the
`EcCKDRadiation` component of the next phase builds per column: layer
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

## 3 and 4. Superseded by `main`

Both were written before `main` gained the streaming column API (PR #20,
Breeze coupling). At the merge on 2026-09-22 `main`'s versions won:

- `TabulatedSurfaceEmission(model, T; emissivity)` is a lazy `AbstractVector`
  whose `getindex(g)` evaluates the source table for one g point, so a host
  passes it as `surface_longwave_up` without any allocation; the in-place
  `surface_longwave_emission!` of this branch became redundant.
- `EcCKDTabulatedGasOpticsModel{FT}(model)` on `main` converts every array
  through an `Adapt` storage adaptor, shares arrays already in `FT`, and works
  on device arrays too; the constructor-based version of this branch was
  dropped. The behavioural tests written here (field-wise conversion, reuse,
  absent tables stay absent, Float32 optics within 1e-4 of Float64) were kept.

## 5. Housekeeping

- `test/runtests.jl`: includes `test_host_interface.jl`.

## 6. `ClearSkyEcCKDRadiation` (new, `src/ecckd_radiation.jl`)

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
configuration), no existing code path changes. It is on the bottom branch of the
stack because the SpeedyWeather extension `import`s the name at load time.

*Tests.* `test/test_ecckd_radiation.jl` (construction, defaults, conversion,
missing-gas error); the coupling tests in `test/speedyweather/` and SpeedyWeather's
`test/numericalradiation/` use it end to end.

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
  no cost in the package.
- **Gas-amount and interface-temperature helpers.** Host glue; they belong in
  the extension.
