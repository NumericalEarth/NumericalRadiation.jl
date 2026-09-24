# Upstream changes to SpeedyWeather.jl

Companion to [ecckd_speedyweather.md](ecckd_speedyweather.md). Everything in
this file lands in SpeedyWeather.jl, not in NumericalRadiation. Link the
upstream issues and PRs next to each item as they are opened.

Status legend: `[ ]` open, `[~]` in progress, `[x]` done.

Created 2026-09-11. Base version: SpeedyWeather 0.22.1. The `Radiation`
bundle changes the model struct and is a breaking change for anyone who
passes `shortwave_radiation` / `longwave_radiation` or reads those fields, so
it should go into the next breaking release.

---

## U1. One `radiation` component bundling shortwave and longwave

Status: **in progress** (2026-09-11) on branch `mg/numericalradiation` in
`~/Nextcloud/SpeedyWeather/alt-version/SpeedyWeather.jl`; detailed implementation plan per that repo's
convention in its `docs/dev/2026-09/radiation-bundle.md`. Issue: _todo_ · PR: _todo_

### Motivation

Today `PrimitiveWetModel` and `PrimitiveDryModel` carry two independent
components, `shortwave_radiation <: AbstractShortwave` and
`longwave_radiation <: AbstractLongwave`, called back to back inside the
fused column kernel. A correlated-k scheme such as ecCKD computes gas optics
once for both streams; with two separate components that work is either done
twice or smuggled from one component to the other through scratch arrays and
a call-order assumption. A single `radiation` component removes that problem
and is also the natural home for future coupled schemes (clouds shared by
both streams, radiation sub-stepping, a combined ecRad-like driver).

The requirement for the first step is **bit-identical results** with the
existing schemes. Only after that is proven does NumericalRadiation plug in.

### Design

Types. `AbstractRadiation <: AbstractParameterization` already exists as the
common supertype of `AbstractShortwave` and `AbstractLongwave`. Add

```julia
export Radiation

"""Radiation scheme bundling a shortwave and a longwave scheme, called in that
order inside the fused column kernel. Either can be `nothing`."""
@parameterized @kwdef struct Radiation{SW, LW} <: AbstractRadiation
    @component shortwave::SW
    @component longwave::LW
end

Radiation(SG::SpectralGrid;
          shortwave = OneBandShortwave(SG),
          longwave  = OneBandLongwave(SG)) = Radiation(shortwave, longwave)

Adapt.@adapt_structure Radiation
Base.show(io::IO, R::Radiation) = show(io, R, values = false)

function initialize!(radiation::Radiation, model::PrimitiveEquation)
    initialize!(radiation.shortwave, model)
    initialize!(radiation.longwave, model)
    return nothing
end

# collect variables of both sub-schemes (duplicates are removed by identifier in filter_variables)
variables(radiation::Radiation, model::AbstractModel) =
    (variables(radiation.shortwave, model)..., variables(radiation.longwave, model)...)

@propagate_inbounds function parameterization!(ij, vars, radiation::Radiation, model)
    parameterization!(ij, vars, radiation.shortwave, model)   # same order as today
    parameterization!(ij, vars, radiation.longwave, model)
    return nothing
end
```

Diagnostics of third-party schemes. `variables(::AbstractShortwave)` and
`variables(::AbstractLongwave)` stay as they are (decision 2026-09-11: no
helper functions, no union default on `AbstractRadiation`). A scheme that
subtypes `AbstractRadiation` directly declares its own variables, e.g.

```julia
variables(::EcCKDRadiation) = (variables(OneBandShortwave(SG))..., variables(OneBandLongwave(SG))..., <work arrays>...)
```

so the ocean, land and output code find the standard fields.

Model structs. In `primitive_wet.jl` and `primitive_dry.jl` replace

```julia
@component shortwave_radiation::SW = OneBandShortwave(spectral_grid)
@component longwave_radiation::LW  = OneBandLongwave(spectral_grid)
```

with

```julia
@component radiation::RA = Radiation(spectral_grid)   # dry model: Radiation(spectral_grid; shortwave = OneBandGreyShortwave(spectral_grid), longwave = OneBandGreyLongwave(spectral_grid))
```

replace `:shortwave_radiation, :longwave_radiation` by `:radiation` in the
default `parameterizations` tuple, and the two `initialize!` calls by one.
Time-step selection (`get_prognostic_step(var, time_stepping, component)`)
is called by the inner schemes with themselves as component, so it is
unaffected.

Back-compat (decide upstream how much of this is wanted):

- An outer `PrimitiveWetModel(spectral_grid; shortwave_radiation, longwave_radiation, kwargs...)`
  method that wraps them into `Radiation` and emits a deprecation warning.
- Rewriting `:shortwave_radiation` / `:longwave_radiation` in a user-supplied
  `parameterizations` tuple to `:radiation` with a warning.
- Optionally `Base.getproperty(model, :longwave_radiation)` forwarding to
  `model.radiation.longwave` with a deprecation. Probably not worth it.

Blast radius in the repository (0.22.1): `src/models/primitive_wet.jl`,
`src/models/primitive_dry.jl`, three tests
(`test/parameterizations/{longwave,shortwave}_radiation.jl`,
`stochastic_physics.jl`), eight lines in `docs/src/radiation.md` and
`docs/src/parameterizations.md`. No output writer or surface model reads the
model fields; they read `vars.parameterizations.*`, which is unchanged.

### Proof of identical results

- [x] **Permanent unit test.** (`test/parameterizations/radiation.jl`, passes with bounds checks; GPU variant still open) Construct a model, allocate `vars` twice from
      the same state, run `parameterization!(ij, vars_a, sw, model)` then
      `parameterization!(ij, vars_a, lw, model)` on one copy and
      `parameterization!(ij, vars_b, Radiation(sw, lw), model)` on the other
      for all `ij`; assert `==` (not `≈`) on every tendency and every
      `vars.parameterizations` field. Run over the full matrix of existing
      schemes: `{TransparentShortwave, OneBandShortwave, OneBandGreyShortwave, nothing}`
      × `{UniformCooling, JeevanjeeRadiation, OneBandLongwave, OneBandGreyLongwave, nothing}`,
      Float32 and Float64, CPU. Add the GPU variant to the GPU test set.
- [x] **One-off release comparison in the PR.** (done 2026-09-11 against `1ef2a0e2`: wet and dry model, T31 L8, 2 days, all arrays identical) Run a fixed-seed
      `PrimitiveWetModel` and `PrimitiveDryModel` for a few days at T31 L8
      on the previous release and on the branch, write output to disk, and
      compare prognostic fields bitwise. Same for `PrimitiveDryModel`. Record
      the result in the PR description; the artifacts need not be kept.
- [ ] **Performance check.** Benchmark `parameterization_tendencies!` before
      and after on CPU (and GPU if available). Expected: no change; the extra
      call level inlines through `@propagate_inbounds`.

### Checklist

- [x] `Radiation` struct, constructors, `initialize!`, `variables`,
      `parameterization!`, `Adapt`, `show`.
- [x] Replace the two fields in both primitive models, `parameterizations`
      tuple, `initialize!`.
- [x] Back-compat constructor and deprecation warnings (keywords and
      `parameterizations` symbols; no field-access shim). Scope to be confirmed with maintainers.
- [x] Update the three tests; add the bit-identity test.
- [x] Update `docs/src/radiation.md`, `docs/src/parameterizations.md`,
      CHANGELOG entry (PR number still `#TBD`).
- [ ] Release. Then bump NumericalRadiation compat and port the extension
      (Phase 0 of the main plan).

### What NumericalRadiation gains

Once released, the extension defines a single
`EcCKDRadiation <: SpeedyWeather.AbstractRadiation` passed as
`radiation = EcCKDRadiation(...)`. It evaluates ecCKD gas optics once, solves
both streams, and declares the standard diagnostic fields plus its work
arrays in `variables(::EcCKDRadiation)`. Mixed setups remain possible, e.g.
`Radiation(spectral_grid; longwave = EcCKDLongwave(...))` next to the
existing one-band shortwave. This replaces the "split `optical_properties!`
per stream" item that was Phase 1.1 of the main plan.

---

## U2. Prescribed ozone

Issue: _todo_

ecCKD treats O3 as a linear gas that must be supplied; SpeedyWeather has no
ozone field. Options, to be decided with maintainers:

- [ ] A component modelled on `greenhouse_gases` holding a zonal-mean,
      pressure-dependent climatology (a `GridXYZ` parameterization variable
      filled at `initialize!`, optionally with a seasonal cycle).
- [ ] Ozone as a prescribed tracer, reusing the tracer infrastructure
      (`vars.grid.tracers[:o3]`) and `set!`.

Either way the radiation scheme reads a per-column mole-fraction profile.
Default data source still to be chosen (e.g. a zonal-mean climatology from
CKDMIP / ecRad test data).

## U3. Radiation call frequency

Issue: _todo_

A 32×32 g-point column per time step dominates cost at climate resolution.
Add a general mechanism for parameterizations that run every `N` steps and
hold their tendency and diagnostics in between:

- [ ] Option on `Radiation` (`every::Second` or `every::Int`), a stored
      tendency array (`GridXYZ`) and a step counter in the clock or
      component.
- [ ] Consistent with Leapfrog and the tendency step machinery
      (`get_tendency_step`); tendency is *added* each step from the stored
      array when not recomputed.
- [ ] Tested for exact equivalence with `N = 1`.

## U4. Work-array layout for g-point arrays

Issue: _todo_

Per-column optical properties are `(ng, nlayers)` in NumericalRadiation, but
`Grid4D(n)` allocates `(npoints, nlayers, n)`, so a column view is
`(nlayers, ng)` and needs a permuted view in the kernel. If that turns out to
be awkward or slow inside kernels:

- [ ] Add a dim type (`GridXNZ(n)` or similar) allocating
      `(npoints, n, nlayers)`, or
- [ ] make the ecCKD kernels in NumericalRadiation layout-agnostic via an
      indexing accessor (then no upstream change is needed).

## U5. Host the extension itself

Status: **in progress** (2026-09-22) on branch `mg/numericalradiation-extension`; plan there:
`docs/dev/2026-09/numericalradiation-extension.md`. The coupling code moves into SpeedyWeather
as `SpeedyWeatherNumericalRadiationExt`; NumericalRadiation becomes a weak dependency of
SpeedyWeather. Both scheme types are NumericalRadiation's own (`ClearSkyEcCKDRadiation`, the
configured clear-sky ecCKD scheme, and `AnalyticBandLongwave`); the extension adds the
methods SpeedyWeather calls and constructors from a `SpectralGrid`, SpeedyWeather's `src`
is untouched. To-do there: collapse the dedicated test environment
once NumericalRadiation is registered. See [extension_upstream.md](extension_upstream.md) for
this side.

## Already available upstream (no change needed)

- A user-extensible parameterization slot exists: `custom_parameterization`
  together with the user-settable `parameterizations` tuple, documented in
  `docs/src/parameterizations.md`. This covers the "extra slot before
  shortwave" idea from the first draft of the plan; with U1 it is not needed
  for radiation anyway.
- `variables(component, model)` two-argument form, so a component can size
  its work arrays from `model` (e.g. `nlayers + 1` interface arrays).
- Duplicate `ParameterizationVariable`s are de-duplicated by identifier in
  `filter_variables`, so `Radiation` can naively concatenate sub-scheme
  variables.
