# Changes to `src/` made for the SpeedyWeather coupling, and why

Companion to [ecckd_speedyweather.md](ecckd_speedyweather.md). The guiding rule
for that work is to keep changes to the package's core small and to prefer the
extension or SpeedyWeather itself whenever that is possible without giving up
performance. This file lists every change to `src/` that was made anyway, what
forced it, what the alternative would have been, and how it is tested. Nothing
here changes numerical results of existing code paths.

Merged with `main` on 2026-09-22. `main` had meanwhile grown the streaming
column API (PR #20, Breeze coupling), which made items 3 and 4 redundant and
reduced item 5 to a few lines; the table and sections below reflect the
merged state.

| # | Change | Phase | Lines | Results changed |
|---|---|---|---|---|
| 1 | `AtmosphereProfile`: one array-type parameter per vector | 0 | ~10 | no |
| 2 | `ColumnAtmosphere`: one array-type parameter per array | 1 | ~12 | no |
| 3 | ~~`surface_longwave_emission!`~~ dropped at the merge: `main`'s `TabulatedSurfaceEmission` is the allocation-free per-g-point surface source | 1 | 0 | no |
| 4 | ~~`EcCKDTabulatedGasOpticsModel{FT}(model)`~~ dropped at the merge: `main` has the same method, `Adapt`-based and device-capable | 1 | 0 | no |
| 5 | Optional caller-owned `ShortwaveColumnScratch` argument of `radiative_fluxes!` (was a separate workspace type before the merge) | 2 | ~8 | no |
| 6 | New test file in the runner | 1 | ~1 | no |
| 7 | Two-stream direct-beam singularity guard moved to the band edge (`shortwave_reflectance_transmittance`) | 4 | ~8 | only within 1000 ulps of λ μ₀ = 1 |

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

## 3 and 4. Superseded by `main`

Both were written before `main` gained the streaming column API. At the merge
`main`'s versions won:

- `TabulatedSurfaceEmission(model, T; emissivity)` is a lazy `AbstractVector`
  whose `getindex(g)` evaluates the source table for one g point, so a host
  passes it as `surface_longwave_up`, or blends two of them per g point as the
  SpeedyWeather extension does for ocean and land, without any allocation.
- `EcCKDTabulatedGasOpticsModel{FT}(model)` on `main` converts every array
  through an `Adapt` storage adaptor, shares arrays already in `FT`, and works
  on device arrays too. The behavioural tests written here were kept.

## 5. Optional `scratch` argument of `radiative_fluxes!(…, CloudlessShortwave(), …)`

*File:* `src/solvers/cloudless_shortwave.jl`.

*What forced it.* The Rayleigh (scattering) path of the clear-sky shortwave
solver needs seven work vectors. Before `main`'s refactor they were allocated
per g-point and per column (about 400 allocations per column per step for the
32-g-point model); `main` now allocates one `ShortwaveColumnScratch` per
`radiative_fluxes!` call, i.e. seven vectors per column per step. Inside
SpeedyWeather's fused column kernel that is still the only allocation in the
hot loop on CPU and a compile failure on GPU, and the extension cannot avoid
it without dropping Rayleigh scattering.

*Alternative considered.* This branch originally carried its own
`CloudlessShortwaveWorkspace` type and a rewritten accumulation; at the merge
that was dropped in favour of `main`'s type.

*What changed.* `radiative_fluxes!` gained an optional last positional
argument `scratch::ShortwaveColumnScratch`, defaulting to the allocation
`main` already did. A host passes seven column views through the type's
positional constructor. No other line of the solver changed.

*Tests.* `test/test_host_interface.jl`, "CloudlessShortwave with a
caller-owned scratch": identical fluxes with and without the argument, zero
allocations with it, a scratch built from views.

## 7. Two-stream singularity guard (`shortwave_reflectance_transmittance`)

*File:* `src/solvers/cloudless_shortwave.jl`.

*What forced it.* Found in Phase 4: the coupled T31 L8 model produced NaN
shortwave fluxes after two to four days and blew up. Traced with a per-step
callback to one column with cos_zenith 0.50002 and one g-point/layer with
diffusion exponent k = 1.99993, i.e. k·μ0 = 1.0000012: the removable
singularity of the direct-beam two-stream terms, which divide by 1 - (kμ0)².
The existing guard detected |1 - kμ0| < 1000 ulps but then nudged μ0 by only
10 ulps, which in Float32 landed exactly on the singularity (0 × ∞ = NaN).

*Alternative considered.* None in the extension; the singularity is inside
the solver.

*What changed.* Inside the band, μ0 is moved to the edge of the band,
(1 ∓ 1000 ulps)/k, so the denominator is bounded away from zero by
construction. Outside the band nothing changes; the reference comparisons in
`test/test_solvers.jl` are unaffected.

*Tests.* `test/test_host_interface.jl`: scan of μ0 around 1/k for two
single-scattering albedos, two asymmetries, three optical depths, in Float32
and Float64; all outputs finite and within the clamps, and continuity across
the band edge.

## 6. Housekeeping

- `test/runtests.jl`: includes `test_host_interface.jl`.

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
