# Design and acceptance criteria

This page is the distilled design contract for the ecRad/ecCKD radiation
platform built on this branch. It records what the package is, the
architecture rules the implementation must keep, the quantitative acceptance
criteria for every gate, and the current gate status with headline numbers.
The full campaign history — the pass-numbered working log, the goal/recovery
audits, and every optimizer-experiment artifact — is preserved on the archived
git ref `audit-trail-2026-07-17` (branch `audit-trail-pre-cleanup`). Frozen
quantitative endpoints of the retired greedy reduced-model program live in
`validation/FROZEN_DIAGNOSTICS.md`.

## What the package is

NumericalRadiation.jl is a standalone, GPU-capable, differentiable radiation
and gas-optics library. It contains two layers:

- **Analytic-band column schemes** for intermediate-complexity models: the
  Williams (2026) 41-wavenumber clear-sky longwave solver and a SPEEDY-style
  one-band shortwave with diagnostic clouds. These are pure scalar per-column
  operations, allocation-free and GPU-safe.
- **An ecRad-style radiative transfer platform**: staged runtime API, official
  ecCKD gas-optics ingestion, cloudless and cloud-overlap (Tripleclouds-style)
  solvers, cloud/aerosol optics, a package-native RRTMGP comparison surface,
  and the groundwork for Reactant.jl + Enzyme.jl ecCKD model training and
  recovery.

The package must not depend on Breeze. The Breeze integration is owned by
Breeze in `Breeze.jl/ext/BreezeRadiativeHeatingExt` (developed in a dedicated
checkout); this repository only exposes the stable runtime API surface that
extension calls.

## Architecture

The core dataflow is staged, and each stage is separately accessible:

```text
atmospheric state
    ↓
gas / cloud / aerosol optics
    ↓
optical properties
    ↓
radiative transfer solver
    ↓
fluxes
    ↓
heating rates
```

### Staged runtime API

`src/abstract_types.jl` defines the root abstractions
(`AbstractAtmosphericState`, `AbstractGasOpticsModel`,
`AbstractCloudOpticsModel`, `AbstractAerosolOpticsModel`,
`AbstractRadiativeTransferSolver`, `AbstractRadiationBackend`).
`src/runtime_interfaces.jl` defines `ColumnAtmosphere`, `RadiativeFluxes`, and
the staged entry points `optical_properties!`, `cloud_optical_properties!`,
`aerosol_optical_properties!`, `radiative_fluxes!`, `heating_rates!`,
`radiative_heating!`, and `radiation_workspace`. Host models may stop at any
layer: high-level (state + optics model + solver → heating rates), mid-level
(state + optics model → optical properties, host owns the solver), or
low-level (preallocated arrays/views into optimized kernels).

Two non-negotiable separations:

- **Runtime vs. offline generation.** The runtime path is fast, typed,
  allocation-free, GPU-capable, and does no I/O. Offline ecCKD model
  generation/training is data-heavy and CKDMIP-aware and never leaks into the
  runtime path.
- **Solvers do not know where optics came from.** Solvers accept optical
  properties and source terms whether they were produced by analytic bands,
  ecCKD tables, or a comparison model.

### ecCKD ingestion

`src/io/ecckd_definition.jl` provides dependency-free schema objects
(`EcCKDDefinition`, `validate_ecckd_definition`, `summarize_ecckd_definition`)
and official-data resolution (`ecrad_data_path`, `ecckd_source_path`,
`official_ecckd_definition_path`, `official_ecckd_model_inventory`).
`src/gas_optics/ecckd_forward.jl` provides the runtime models:
`EcCKDGasOpticsModel` (fixed-coefficient path for unit and teacher-student
work) and `EcCKDTabulatedGasOpticsModel` (official
pressure/temperature/H₂O-mole-fraction LUT path with Rayleigh, composite
background gas, and relative-linear gas handling).
`src/io/cloud_scattering.jl` reads the official Mie droplet and Baum ice
scattering tables and maps them to ecCKD g-point grids.

Official data resolves in this order: `RH_ECRAD_DATA_PATH` /
`RH_ECCKD_SOURCE_PATH` environment override → lazy artifact (`Artifacts.toml`
pins `ecmwf-ifs/ecrad` and `ecmwf-ifs/ecckd` snapshots) → local
`validation/external/{ecrad,ecckd}` checkout.

### Solvers

- `CloudlessLongwave` — ecRad-style adding with an opt-in longwave scattering
  path, scalar or spectral surface boundary fluxes, interface Planck sources.
- `CloudlessShortwave` — delta-Eddington/two-stream-style transport with
  Rayleigh scattering and ecRad-compatible direct/diffuse adding.
- `CloudOverlapLongwave` / `CloudOverlapShortwave` — clear/full/mixed-cloud
  paths with Tripleclouds-style modes and alpha-overlap parameters; verified
  against ecRad reference optical properties to ≈1e-5 W m⁻² at the boundaries.
- `src/solvers/cloud_optics.jl` — layer cloud and aerosol optics models with
  separate absorption/scattering/asymmetry channels composed onto gas optics.

### Extensions

- `NumericalRadiationNCDatasetsExt` — NetCDF readers
  (`read_ecckd_definition`, `read_ecckd_tabulated_gas_optics`,
  `read_cloud_scattering_table`, `read_ecckd_spectral_mapping`), so NCDatasets
  stays optional.
- `NumericalRadiationRRTMGPExt` — `RRTMGPClearSkyModel` and a
  `radiative_fluxes!` method computing RRTMGP clear-sky fluxes from the same
  `ColumnAtmosphere`, the package-native comparison surface for all
  RRTMGP-vs-ecCKD validation.
- `NumericalRadiationSpeedyWeatherExt` — wires the analytic-band longwave
  scheme into SpeedyWeather's per-column parameterization interface.

`src/metrics.jl` (`RadiationErrorMetrics`, `RadiationThresholds`,
`radiation_error_metrics`, `passes_thresholds`) is the common metric layer
used by every accuracy gate under `validation/`.

## Acceptance criteria

### Hard cloudless/no-aerosol ecRad gate

Applied by `validation/ecrad_cloudless_accuracy_gate.jl` (and the full gate in
`validation/ecrad_accuracy_gate.jl`) to the clean ecCKD tropical and
RCEMIP-style reference cases materialized from official ecRad outputs:

| Metric | Threshold |
|---|---:|
| Flux RMSE (each of `lw_up`, `lw_down`, `sw_up`, `sw_down`) | ≤ 1.0 W m⁻² |
| Flux max abs error | ≤ 5.0 W m⁻² |
| Heating-rate RMSE | ≤ 0.05 K day⁻¹ |
| Heating-rate max abs error | ≤ 0.5 K day⁻¹ |
| TOA forcing abs error | ≤ 0.3 W m⁻² |
| Surface forcing abs error | ≤ 0.3 W m⁻² |

### All-sky gate

`validation/ecrad_all_sky_ifs_gate.jl` requires, on the official ecCKD
all-sky references with IFS-style cloud/aerosol conventions:

- the official ecCKD all-sky hard gate (same thresholds as above) passes;
- cloud scattering table ingestion passes;
- the best cloud/aerosol/overlap sweep configuration passes with worst
  threshold ratio < 1;
- the reference-optics Tripleclouds solver (fed ecRad's saved optical
  properties) matches ecRad boundary fluxes.

### RRTMGP comparison

`validation/reduced_ecckd_32g_rrtmgp_comparison.jl` must emit direct
package-native RRTMGP metrics for the production ecCKD model on tropical,
RCEMIP-style, and all-sky-clear-projection column ensembles, with the
production model passing the hard gate: forcing errors ≤ 0.30 W m⁻² and
heating-rate RMSE ≤ 0.05 K day⁻¹. RRTMGP is a CKD-compatibility baseline, not
line-by-line truth.

### Published-model recovery (Reactant/Enzyme)

The training pipeline must recover at least one published ecCKD model while
keeping the published problem definition fixed — same CKDMIP/ecCKD source
data, objective terms, and evaluation cases — varying **only** optimizer
settings, schedules, and initialization ("optimizer-only delta" rule).
Quantitative criteria (from `validation/ecckd_training_recovery_targets.jl`):

| Metric | Acceptance |
|---|---:|
| Final objective / target | ≤ 1.05 |
| Relative L1 weight error | ≤ 0.02 |
| Optical-depth log RMSE | ≤ 0.02 |
| Forcing regression margin | ≤ 0.03 W m⁻² |
| Heating RMSE regression margin | ≤ 0.005 K day⁻¹ |

### New band-count schemes

New band-count rows for the accuracy-vs-band-count plot only count when they
are produced by the **recovered** training pipeline with source data,
objective terms, and evaluation cases fixed. Greedy/forward-evaluation
candidates (subset scans, accepted-move replay chains, coordinate polish) are
frozen as evidence in `validation/FROZEN_DIAGNOSTICS.md` and do not satisfy
these targets.

| Metric | Acceptance |
|---|---:|
| Hard-gate objective | ≤ 1.0 |
| TOA forcing abs error | ≤ 0.30 W m⁻² |
| Surface forcing abs error | ≤ 0.30 W m⁻² |
| Heating-rate RMSE | ≤ 0.05 K day⁻¹ |
| Required band-count points | 48, 96 |

## Gate status

### Gate 1 — clean ecCKD cloudless gate: **passed**

The focused cloudless/no-aerosol hard gate passes for the clean ecCKD tropical
and RCEMIP-style references. The official 32×32 baseline has worst TOA/surface
forcing errors ≈ 0.008 / 0.014 W m⁻². All six promoted published ecCKD
combinations (32×32, 32×64, 32×96, 64×32, 64×64, 64×96 LW×SW) pass the clean
package-native gate against matched spectral-boundary references with hard
objectives ≈ 0.16–0.19 (`validation/ecckd_published_model_accuracy.jl`).

### Gate 2 — 32-g production gas optics + RRTMGP comparison: **passed**

Production uses the validated official ecCKD 32-g gas-optics path. The direct
package-native RRTMGP comparison
(`validation/reduced_ecckd_32g_rrtmgp_comparison.jl`) records
`Status: passed` with the official 32-g hard gate passed on the tropical,
RCEMIP-style, and all-sky-clear-projection ensembles. The greedy-era 16-g and
32×31 reduced candidates are frozen as diagnostics in
`validation/FROZEN_DIAGNOSTICS.md`, not production rows.

### Gate 3 — all-sky + production Breeze H100: **passed**

`validation/ecrad_all_sky_ifs_gate.jl` records `Status: passed`: the
official ecCKD all-sky hard gate passes, cloud scattering tables pass, the
best cloud/aerosol/overlap sweep passes at worst threshold ratio ≈ 0.387, and
the reference-optics Tripleclouds solver matches ecRad to ≈ 1.4e-5 (TOA) /
2.6e-5 (surface) W m⁻². The RCEMIP-style H100 production benchmark in the
dedicated Breeze checkout passes the ≥ 4× gate with ≈ 31.3× speedup over
RRTMGP (median update 7.8 ms vs 244.0 ms on a 32×32×64 grid, official ecCKD
32/32 gas optics, Nsight Systems/Compute reports recorded).

### Gate 4 — published ecCKD model recovery: **outstanding**

The remaining work: recover one published ecCKD model (primary targets are the
32-g SW `rgb-32b` and LW `fsck-32b` CKD definitions) under the
optimizer-only-delta rule and the recovery metrics above, then use the
recovered pipeline to train the missing 48-g band-count row (48 and 96 are the
required plot points). All CKDMIP upstream and derived training flux products
are present (`ready_for_original_ecckd_objective`), teacher-student
coefficient recovery passes for all six published definitions, and the
AD-checked original-objective loss core exists; the current official/reduced
training path still sits at final objective / target ≈ 8.6 against the ≤ 1.05
recovery criterion.

## Future extensions

Two scoped extensions to the analytic-band layer, outside the current goal:

- **All-sky longwave** for the Williams (2026) scheme. Recommended first step
  is a gray-emissivity overlay: per-layer cloud emissivity
  `ε_c = 1 − exp(−κ_LW · LWP)` with liquid/ice mass absorption coefficients
  (optionally split at the 8–12 μm window), blended by cloud fraction in the
  existing sweeps (~2 days). Later steps: Geleyn–Hollingsworth maximum-random
  overlap (~1 week) and a scattering two-stream (~2 weeks, tridiagonal solve;
  usually unnecessary for LW).
- **Two-band shortwave**: split `OneBandShortwave` back into visible/near-IR
  bands (`TwoBandShortwave`) with per-band water-vapour absorptivity, cloud
  albedo (visible ≈ 0.7, near-IR ≈ 0.2), and surface albedo, recovering the
  SPEEDY pre-weighting constants; ~2× solver cost (~3 days). Restores the
  cloud-reflection/absorption band split and snow-albedo feedback. No ozone
  bands or explicit Rayleigh band — not worth the parameters at this
  complexity.

Recommended order: two-band shortwave first, then the gray-emissivity all-sky
longwave.

## Campaign history

The campaign that produced the current state — including the goal and
recovery-goal audit ledgers, the pass-numbered running review, the ~120
removed optimizer-experiment scripts and their artifacts, and the retired PR
working summary — is preserved on the archived ref `audit-trail-2026-07-17`
(branch `audit-trail-pre-cleanup`). The frozen quantitative endpoints of the
greedy reduced-model program (the failing 16-g canonical diagnostic and the
passing 32×31 leave-one-out boundary-polished candidate) are recorded in
`validation/FROZEN_DIAGNOSTICS.md`.
