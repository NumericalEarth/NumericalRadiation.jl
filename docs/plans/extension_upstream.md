# Plan: move the SpeedyWeather extension upstream into SpeedyWeather

Status: **in progress** (2026-09-22). Reviewed; decided to squash the removal into the bottom
PR of the stack (#16, `mg/speedy-update`) and propagate it upward, so no PR in the stack adds
the extension. The SpeedyWeather side is planned in that repository's
`docs/dev/2026-09/numericalradiation-extension.md` on branch `mg/numericalradiation-extension`.

## Why

The coupling code is SpeedyWeather-shaped: parameterization variables, the fused column
kernel, the `Radiation` bundle, host constants. It changes with SpeedyWeather's interface,
not with the radiation physics, and SpeedyWeather already hosts its couplings to other
packages (Terrarium) as extensions of its own. NumericalRadiation goes back to being a
host-neutral column library. What was learned about the package while writing the coupling
stays: the `src/` changes justified in
[src_changes_for_speedyweather.md](src_changes_for_speedyweather.md) are what any host
needs and remain.

## What leaves this repository

| path | fate |
|---|---|
| `ext/NumericalRadiationSpeedyWeatherExt` (one file on #16, a directory of three on #19) | moves to `SpeedyWeather/ext/SpeedyWeatherNumericalRadiationExt/` |
| `test/test_with_speedyweather.jl`, `test/speedyweather/` | **stay** (full unit tests of the coupling), now testing SpeedyWeather's extension: `AnalyticBandLongwave` and `ClearSkyEcCKDRadiation` as SpeedyWeather schemes, internals via `Base.get_extension(SpeedyWeather, :SpeedyWeatherNumericalRadiationExt)`; the environment pulls SpeedyWeather's `mg/numericalradiation-extension` branch |
| `examples/speedyweather_ecckd.jl`, `validation/speedyweather_*.jl` | **stay**, adapted to the exported names |
| `docs/src/assets/speedyweather_ecckd.png` (untracked) | dropped |

## What changes here

- `Project.toml`: remove the `SpeedyWeather` weak dependency, the
  `NumericalRadiationSpeedyWeatherExt` entry and the `SpeedyWeather = "0.23"` compat.
- `src/ecckd_radiation.jl` (new, decided 2026-09-22): `ClearSkyEcCKDRadiation`, the configured
  clear-sky ecCKD column scheme (tabulated gas optics, prescribed mole fractions of the gases
  the host does not carry with `o3` and `co2` defaults, surface emissivity), host-neutral, so
  that SpeedyWeather's extension adds methods to it like to `AnalyticBandLongwave` and
  SpeedyWeather needs no `src` type at all. On this bottom branch rather than #17 because the
  extension `import`s the name: without it the extension fails to load and the coupling test
  of this branch with it. Tests in `test/test_ecckd_radiation.jl`, docs in `docs/src/api/ecckd.md`.
- `test/runtests.jl`, `.github/workflows/CI.yml` (`speedyweather` job), `examples/Project.toml`,
  `validation/README.md`: unchanged; the coupling keeps being tested and validated from here.
- `README.md`: the "With SpeedyWeather.jl" section becomes a pointer: the coupling is
  SpeedyWeather's `SpeedyWeatherNumericalRadiationExt`, activated by
  `using SpeedyWeather, NumericalRadiation`, with `ClearSkyEcCKDRadiation(spectral_grid)` and
  `AnalyticBandLongwave(spectral_grid)` as the entry points; the intro line about the extension
  goes.
- `docs/plans/ecckd_speedyweather.md` and `speedyweather_upstream.md`: a note at the top
  that the extension moved (item U5), the rest stays as history.

## What stays

- Every `src/` change of the coupling work: `AtmosphereProfile` and `ColumnAtmosphere` with
  one array-type parameter per array, the optional caller-owned `scratch` of
  `radiative_fluxes!(…, CloudlessShortwave(), …)`, the two-stream singularity guard.
- `test/test_host_interface.jl`.
- The plan documents, as the record of the design and the validation results.

## Naming on the SpeedyWeather side

`EcCKDRadiation` becomes this package's `ClearSkyEcCKDRadiation` (`src/ecckd_radiation.jl`,
see above), the SpeedyWeather extension only adds methods and constructors from a
`SpectralGrid`. The longwave wrapper
`SpeedyAnalyticBandLongwave` goes without replacement (decided 2026-09-22, after a first
decision for a `WilliamsLongwave` wrapper): nothing in SpeedyWeather requires a longwave to
subtype its `AbstractLongwave`, so the extension adds `variables`, `initialize!` and
`parameterization!` methods to this package's `AnalyticBandLongwave` directly, plus a
constructor from a `SpectralGrid` (the time-step selection, which does need a SpeedyWeather
model component, is defined by the extension for the scheme types). CO₂ comes from the model's `greenhouse_gases.co2`, else
280 ppm (this package's `AtmosphereProfile` default). SpeedyWeather
[#1261](https://github.com/SpeedyWeather/SpeedyWeather.jl/pull/1261) is not needed for this.

## Order

**2026-09-24: the stack is collapsed into one PR.** With the extension gone from this
package, the three-PR split (package prep, extension, ecCKD component) no longer maps onto
anything: `mg/speedy-update` (#16, against `main`) is fast-forwarded to the fully merged top
of the stack, #17 and #19 are closed, the GitHub stack is dissolved. The steps below are the
record of how the branches were brought together.


1. Bottom branch `mg/speedy-update` (PR #16), uncommitted until reviewed: delete the
   extension, drop the weak dependency, point `test/speedyweather/` at SpeedyWeather's
   `mg/numericalradiation-extension`, adapt the coupling test and the README. Squash into #16.
2. Merge upward into `mg/adjust-to-speedy` (#17) and `mg/ecckd-speedy` (#19): the extension
   directory of #19 is deleted in the merge; its coupling test, example and validation scripts
   are adapted to `ClearSkyEcCKDRadiation` (extension internals used by the
   cross-check test via `Base.get_extension(SpeedyWeather, :SpeedyWeatherNumericalRadiationExt)`).
3. Tests: the core suite here (`Pkg.test`, unchanged), and `test/speedyweather/` against the
   SpeedyWeather branch once it is pushed.
4. Once NumericalRadiation is registered (maintainers, within days) and SpeedyWeather 0.23
   with the extension is released, both `[sources]` entries go.

## Open decisions

- None from the reviews of 2026-09-22; registration of this package is the remaining to-do.
