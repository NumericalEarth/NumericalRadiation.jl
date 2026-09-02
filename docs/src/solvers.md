# Column solvers

The staged solvers compute interface fluxes from precomputed optical
properties. They do not know where the optics came from: the same
[`radiative_fluxes!`](@ref) methods accept optical depths produced by ecCKD
tables, analytic bands, or a comparison model. All solvers write caller-owned
[`RadiativeFluxes`](@ref) arrays and follow the package conventions: arrays
are ordered top-to-bottom, with pressure increasing downward (index 1 = top of
atmosphere); interface flux arrays have `nlayers + 1` entries; fluxes are in
W m⁻².

## Data flow

```text
ColumnAtmosphere ── optical_properties! ──▶ LongwaveOpticalProperties
                                            ShortwaveOpticalProperties
                                                     │
                                            radiative_fluxes!
                                                     │
                                                     ▼
                                              RadiativeFluxes ── heating_rates! ──▶ K s⁻¹
```

A condensed version of `examples/ecckd_column.jl` (gas entries are layer
absorber amounts — column amounts in mol m⁻², i.e. mole fraction times the
layer air column):

```julia
using NumericalRadiation, NCDatasets

gas_optics = read_official_ecckd_gas_optics("32x32";
                                            gas_names = (:composite, :h2o, :co2))

atmosphere = ColumnAtmosphere(; pressure_layers, pressure_interfaces,
                              temperature_layers, temperature_interfaces,
                              gases = (composite = air_column,       # mol m⁻²
                                       h2o = x_h2o .* air_column,
                                       co2 = 420.0e-6 .* air_column),
                              surface = (temperature = 300.0,),
                              geometry = (cos_zenith = 0.55,))

ng_lw = length(gas_optics.longwave_weights)
longwave = LongwaveOpticalProperties(zeros(ng_lw, nlayers), zeros(ng_lw, nlayers);
                                     source_top = zeros(ng_lw, nlayers),
                                     source_bottom = zeros(ng_lw, nlayers),
                                     weights = zeros(ng_lw))
ng_sw = length(gas_optics.shortwave_weights)
shortwave = ShortwaveOpticalProperties(zeros(ng_sw, nlayers);
                                       rayleigh_optical_depth = zeros(ng_sw, nlayers),
                                       scattering_asymmetry = zeros(ng_sw, nlayers),
                                       weights = zeros(ng_sw))

optical_properties!(longwave, shortwave, gas_optics, atmosphere)
radiative_fluxes!(fluxes, CloudlessLongwave(), longwave, atmosphere, lw_boundary)
radiative_fluxes!(fluxes, CloudlessShortwave(), shortwave, atmosphere, sw_boundary)
heating_rates!(heating, fluxes, atmosphere; gravity = 9.80665, heat_capacity = 1004.0)
```

## Cloudless longwave

[`CloudlessLongwave`](@ref) is a plane-parallel clear-sky solver for
[`LongwaveOpticalProperties`](@ref). Optical depth and source arrays may be
vectors of length `nlayers` (broadband) or matrices shaped `(ng, nlayers)`;
`source` is the layer Planck source in flux units (``\pi B``, W m⁻²). The
atmosphere argument is accepted for interface consistency and is not inspected.

The solver has two paths:

- **No-scattering emission** (default). Fluxes follow the Schwarzschild
  recurrence ``F' = F\,t + S`` up and down the column. With optional
  `source_top`/`source_bottom` interface Planck sources, the solver reproduces
  ecRad's no-scattering longwave: layer transmittance ``t = e^{-D\tau}`` with
  diffusivity ``D = 1.66``, and emission linear in the source between the
  layer's interfaces (with a small-``\tau`` limit below ``\tau = 10^{-3}``).
  With only a layer-mean `source`, the stored optical depth is used as-is
  (``t = e^{-\tau}``), so callers on that path supply diffusivity-scaled
  optical depths.
- **Longwave scattering** (opt-in). Supplying `single_scattering_albedo` and
  `scattering_asymmetry` (both, and interface sources are then required)
  activates an ecRad-style two-stream adding path: per-layer reflectance and
  transmittance from ``\gamma_1 = D - \tfrac{D}{2}\omega(1+g)``,
  ``\gamma_2 = \tfrac{D}{2}\omega(1-g)``, a downward sweep accumulating the
  albedo and source of the stack below each interface, then a downward flux
  pass.

[`LongwaveBoundaryConditions`](@ref) carries the upwelling surface flux
(scalar or per-g-point), the downwelling TOA flux (default zero), and a
diffuse surface albedo (default zero, i.e. a blackbody surface).

## Cloudless shortwave

[`CloudlessShortwave`](@ref) transports the direct solar beam through
[`ShortwaveOpticalProperties`](@ref). When `atmosphere.geometry.cos_zenith`
is present, optical depths are scaled by the slant path ``1/\mu_0`` (with
``\mu_0`` clamped away from zero); otherwise the historical vertical-path
convention applies. `toa_shortwave_down` in
[`ShortwaveBoundaryConditions`](@ref) is the flux through a horizontal plane
at TOA (so ``S_0 \mu_0`` for solar constant ``S_0``).

- **Absorption only** (all `rayleigh_optical_depth` zero for a g-point):
  Beer–Lambert direct transmission down, reflection by the direct surface
  albedo, and upward transmission of the reflected beam through the same slant
  optical depths.
- **With scattering**: an ecRad-compatible two-stream with
  ``\gamma_1 = 2 - \omega(1.25 + 0.75 g)``,
  ``\gamma_2 = \omega(0.75 - 0.75 g)``, and
  ``\gamma_3 = 0.5 - 0.75\,\mu_0 g``, separate direct and diffuse streams, and
  the same adding method as the longwave scattering path. The single-scattering
  albedo and asymmetry of each layer are formed from the absorption and
  scattering optical-depth channels, so cloud and aerosol scattering added to
  those channels (see [Cloud and aerosol optics](cloud_optics.md)) is
  transported without solver changes.

Every layer is delta-Eddington scaled (Joseph, Wiscombe and Weinman 1976) before
the two-stream coefficients are formed. A fraction ``f = g^2`` of the phase
function is treated as an unscattered forward peak and removed,

```math
\tau' = (1 - \omega f)\,\tau, \qquad
\omega' = \frac{(1 - f)\,\omega}{1 - \omega f}, \qquad
g' = \frac{g - f}{1 - f}.
```

This is not only an accuracy refinement. A two-stream solution resolves the
phase function too coarsely to stay conservative at cloud-like asymmetries, so
without the scaling a non-absorbing layer returns more energy than it received —
by as much as 13 % of the incident beam at ``g = 0.95``. Rayleigh scattering has
``g = 0``, which makes ``f = 0`` and leaves clear-sky results unchanged.

The scaling is applied to the combined gas, cloud, and aerosol optics of a
layer, as RRTMGP does. ecRad instead defaults to scaling cloud and aerosol
optics before they are added to the gas optics, so that a cloud's forward peak
does not also thin the gas absorption; the two agree when scattering dominates
the layer and differ slightly when gas absorption does.

Surface albedos for diffuse and direct radiation are independent and may be
broadband scalars or per-g-point vectors.

## All-sky overlap solvers

The all-sky solvers operate on two-region optical properties:
[`LongwaveCloudOverlapOpticalProperties`](@ref) and
[`ShortwaveCloudOverlapOpticalProperties`](@ref) hold *clear* and *cloudy*
optics with the same `(ng, nlayers)` shape, plus three layer fields that stay
separate from the optical depths:

- `cloud_fraction` — one value per layer; never used to weaken cloudy-region
  optical depth before transport;
- `overlap_parameter` — the ecRad/Hogan–Illingworth ``\alpha`` between each
  pair of adjacent layers (`nlayers - 1` values, default 1);
- `fractional_std` — the fractional standard deviation of in-cloud condensate,
  used by the Tripleclouds split (default 1).

[`CloudOverlapShortwave`](@ref) supports six overlap modes, in increasing
fidelity:

- `:maximum` / `:average` — solve the clear and cloudy columns independently
  with the configured `clear_solver`, then blend each interface flux by an
  interface cloud fraction (maximum or mean of the adjacent layers).
- `:adding` — blend clear/cloudy layer reflectance, transmittance, and direct
  terms by layer cloud fraction, then run one adding pass.
- `:matrix_maximum` / `:matrix_alpha` — carry separate clear-region and
  cloudy-region fluxes through the adding pass, redistributing them between
  layers with a 2×2 overlap matrix built from the pair cloud cover
  ``C = \alpha \max(c_u, c_l) + (1 - \alpha)(c_u + c_l - c_u c_l)``;
  ``\alpha = 1`` (maximum overlap) for `:matrix_maximum`, the supplied
  per-interface `overlap_parameter` for `:matrix_alpha`.
- `:tripleclouds_alpha` — additionally split the cloudy region into optically
  thin and thick regions. The thin-region area fraction ramps from 0.5 to 0.9
  as `fractional_std` grows from 1.5 to 3.725, and the two regions scale the
  clear-to-cloudy optical-depth difference by ecRad's gamma-distribution
  factors (thin scaling ``0.025 + 0.975\,e^{-f(1 + f/2(1 + f/2))}`` for
  fractional standard deviation ``f``, thick scaling chosen to conserve the
  in-cloud mean). Overlap between the thin/thick sub-regions uses
  ``\alpha^n`` with the solver's `inhomogeneity_overlap_exponent` ``n``.

[`CloudOverlapLongwave`](@ref) supports `:adding` (blend layer reflectance,
transmittance, and source terms before a scalar adding pass) and
`:tripleclouds_alpha` (the same three-region gamma split, with paired overlap
matrices redistributing downward fluxes and upward sources).

These are deterministic diagnostic solvers — staged all-sky access points, not
a bit-for-bit ecRad McICA implementation (the source says as much in the
solver docstrings). Tight boundary-flux agreement with ecRad (≈10⁻⁵ W m⁻²) has
been demonstrated only for the reference-optics configuration validated on the
`validation-platform` branch, where the solver is fed ecRad's own saved
optical properties; see [Validation](validation.md).

## How ecCKD gas optics feed the solvers

Two runtime gas-optics models implement [`optical_properties!`](@ref):

- [`EcCKDGasOpticsModel`](@ref) holds fixed, already-interpolated `(ng, ngas)`
  coefficients — the path used by unit tests and teacher–student training.
- [`EcCKDTabulatedGasOpticsModel`](@ref) holds official
  `(ng, ngas, np, nt)` look-up tables. Per layer it brackets pressure on a
  logarithmic grid, interpolates bilinearly in pressure and temperature
  (supporting ecCKD's pressure-dependent temperature grids), and accumulates
  ``\tau_g = \sum_j \kappa_{g,j}(p, T)\, u_j`` over the gases with an unrolled,
  allocation-free sum. The ecCKD concentration conventions are applied at this
  point: the `composite` background gas, `relative-linear` gases as
  ``\kappa\,(u_j - r_j u_\mathrm{composite})`` with reference mole fraction
  ``r_j``, and the H2O look-up-table dimension interpolated per layer from the
  actual `h2o`/`composite` amounts. Shortwave Rayleigh optical depth is
  ``k_g\,\Delta p / (g M_\mathrm{air})`` from the per-g-point molar scattering
  table, and the longwave Planck source is interpolated from the file's
  source table at layer and interface temperatures.

The evaluation is *streaming*: the only spectral intermediates are the
caller-owned `(ng, nlayers)` optical-depth and source arrays. Solvers then
loop over g-points, carry running fluxes through the column, and accumulate
`weights[ig] * flux` directly into the broadband interface arrays — spectral
fluxes are never stored with shape `(ng, ninterfaces)`, and there are no
four-dimensional intermediates. Host models can fuse the same per-g-point
recurrences into
their own column kernels; the model types are `Adapt.jl`-aware so tables can
be moved to GPU device memory.
