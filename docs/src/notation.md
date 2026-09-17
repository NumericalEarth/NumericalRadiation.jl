# Notation

`NumericalRadiation` follows the [NumericalEarth.jl notation
guide](https://github.com/NumericalEarth/NumericalEarth.jl/blob/main/docs/src/appendix/notation.md)
for symbolic names in math, in docstring equations, and in plot labels. Julia
struct fields stay descriptive snake_case (matching Breeze's public API
convention), but the mapping to the symbolic notation is always unambiguous.

## Naming scheme

Every identifier — field, keyword, local variable, function name — is either
**mathematical** or **English**, never a Latin-letter spelling or truncation
of either:

* Mathematical names are the unicode symbols of the equations, optionally
  with an English descriptor naming a component or a state: `τ`, `ω`, `g`,
  `κ`, `μ₀`, `γ₁`, `Tₛ`, `τ_absorption`, `τ_scattering`, `ω_clear`,
  `g_cloudy`, `κˡ`, `ωⁱ`. Subscripts and superscripts are unicode (`μ₀`,
  `i₀ᵖ`), never ASCII glued on (`mu0`, `gamma1`, `ip0`).
* English names are whole snake_case words: `optical_depth`,
  `transmittance`, `source_up`, `water_path`, `effective_radius`,
  `cloud_fraction`, `gpoint`, `longwave_…`, `shortwave_…`.

| Quantity | Math | English | Never |
|:---------|:-----|:--------|:------|
| Optical depth (layer; absorption; scattering) | `τ`, `τ_absorption`, `τ_scattering`, `Δτ` | `optical_depth`, `scattering_optical_depth` | `tau`, `od` |
| Single-scattering albedo | `ω` | `single_scattering_albedo` | `ssa` |
| Asymmetry factor | `g`, `g_cloud`, `gˡ`, `gⁱ` | `scattering_asymmetry`, `asymmetry_factor` | `asym` |
| Mass-extinction coefficient | `κ`, `κˡ`, `κⁱ` | `mass_extinction_coefficient` | `ext`, `mass_ext`, `kappa` |
| Reflectance, transmittance | — | `reflectance`, `transmittance`, `direct_reflectance`, `direct_transmittance`, `direct_diffuse_transmittance` | `tr`, `ref_dir`, `trans_dir_diff` |
| Layer Planck source (flux units) | `B`, `B_top`, `B_bottom` | `source`, `source_up`, `source_down` | `src`, `s_up` |
| Mass paths (kg m⁻²) | — | `water_path`, `liquid_path`, `ice_path`, `liquid_water_path`, `ice_water_path`, `cloud_water_path` | `wp`, `lwp`, `iwp`, `cwp` |
| Cloud fraction, in-cloud variability | — | `cloud_fraction`, `fractional_standard_deviation`, `region_fraction` | `cf`, `fsd`, `frac`, `std` |
| Cosine of the solar zenith angle | `μ₀` | `cos_zenith` (stored field) | `μ0`, `mu0` |
| Two-stream coefficients | `γ₁, γ₂, γ₃, γ₄, α₁, α₂, k`, `Dτ` | — | `gamma1`, `alpha1`, `coeff` |
| g-point index | — | `gpoint` | `ig`, `g`, `n` |
| Layer and generic indices | `k` (layer, top down), `i`, `j` | — | — |
| Table stencil: lower index, upper index, weight | `(i₀ᵖ, i₁ᵖ, wᵖ)` pressure, `(i₀ᵀ, i₁ᵀ, wᵀ)` temperature, `(i₀ᴴ, i₁ᴴ, wᴴ)` H₂O; grid loop indices `iᵖ, iᵀ, iᴴ`; bracket bounds `lower`, `upper` | — | `ip`, `it`, `wt`, `ih`, `lo`, `hi` |
| Counts (Oceananigans capital-`N` notation) | `Nz` (layers of a column; interfaces are `Nz + 1`) | `Ngpoints`, `Ngases`, `Nradii`, `Ncolumns`, `Npressures`, `Ntemperatures`, `Nwater_vapor`, `Nwavenumbers`, `Nintervals`, `Nlongwave_gpoints`, `Nshortwave_gpoints`, `Nprofiles`, `Nsites`, `Nzenith` | `nlayers`, `N`, `nlev`, `ninterfaces`, `ng`, `nr`, `ncol`, `ngas`, `np`, `nt`, `nwav`, `nsites` |
| Spectral regions | — | `longwave_…`, `shortwave_…` | `lw_…`, `sw_…` |
| Surface, top of atmosphere | `Tₛ`, `pₛ` | `surface_…`, `toa_…` (TOA, OLR and RMSE are accepted acronyms) | `sfc`, `surf` |
| Objects | — | `column` (a `RadiativeTransferColumn`), `diagnostics`, `temperature_tendency`, `geometry`, `constants`, `dataset` | `rtm`, `diag`, `dTdt`, `geom`, `ds` |

Per-g-point, per-layer accessors of the array optics are one English family
dispatched on the optics type — `optical_depth_at(optics, gpoint, k)`,
`source_top_at`, `single_scattering_albedo_at`, `scattering_asymmetry_at`,
`number_of_gpoints`, `number_of_layers` — with no `lw_`/`sw_` prefix. Names
that mirror an external file or library keep the upstream spelling: the
ecCKD NetCDF variable and dimension names (`h2o`, `lw_gpoints`), the CKDMIP
`mu0` coordinate, RRTMGP struct fields and keywords (`vmr_h2o`, `ncol`,
`nbnd_lw`), SpeedyWeather fields and keywords (`SpectralGrid(nlayers = 8)`,
`spectral_grid.nlayers`), and the Williams (2026) Table 1 parameters
of [`AnalyticBandLongwave`](@ref) (`κ_rot`, `l_vr1`, `p_ref`, ...), which are
documented field by field.

## Radiative fluxes

| Math | Where it appears in code | NumericalEarth symbol |
|:-----|:-------------------------|:----------------------|
| `ℐꜜˡʷ` at surface | [`LongwaveDiagnostics`](@ref) `.surface_longwave_down` | `\scrI\^downarrow\^l\^w` |
| `ℐꜛˡʷ` at surface | [`LongwaveDiagnostics`](@ref) `.surface_longwave_up`, `.ocean_surface_longwave_up`, `.land_surface_longwave_up` | `\scrI\^uparrow\^l\^w` |
| `ℐꜛˡʷ` at TOA (OLR) | [`LongwaveDiagnostics`](@ref) `.outgoing_longwave` | `\scrI\^uparrow\^l\^w` at top of atmosphere |
| `ℐꜜˢʷ` at surface | [`ShortwaveDiagnostics`](@ref) `.surface_shortwave_down` | `\scrI\^downarrow\^s\^w` |
| `ℐꜛˢʷ` at surface | [`ShortwaveDiagnostics`](@ref) `.surface_shortwave_up` | `\scrI\^uparrow\^s\^w` |
| `ℐꜛˢʷ` at TOA | [`ShortwaveDiagnostics`](@ref) `.outgoing_shortwave` | reflected-to-space shortwave |

## State and surface variables

| Math | Code | Description |
|:-----|:-----|:------------|
| `T` | `AtmosphereProfile.temperature` | Layer air temperature (K) |
| `q` | `AtmosphereProfile.humidity` | Specific humidity (kg kg⁻¹) |
| `p` | `AtmosphereProfile.surface_pressure`; `ColumnGrid.σ_*·pₛ` in-code | Pressure (Pa) |
| `α` | `SurfaceState.ocean_albedo`, `land_albedo` | Surface albedo |
| `ϵ` | `SurfaceState.ocean_emissivity`, `land_emissivity` | Surface emissivity |
| `σ` (Stefan–Boltzmann) | `PhysicalConstants.stefan_boltzmann` | W m⁻² K⁻⁴ |
| `g` | `PhysicalConstants.gravity` | m s⁻² |
| `cₚ` | `PhysicalConstants.heat_capacity` | Isobaric specific heat (J kg⁻¹ K⁻¹) |
| `S₀` | `PhysicalConstants.solar_constant` | W m⁻² |
| `mᵈ`, `mᵛ` | `PhysicalConstants.dry_air_molar_mass`, `.water_molar_mass` | kg mol⁻¹ |
| `Rᵈ` | `PhysicalConstants.dry_air_gas_constant` | J kg⁻¹ K⁻¹ |
| `R` | `PhysicalConstants.universal_gas_constant` | J mol⁻¹ K⁻¹ |
| `Nᴬ` | `PhysicalConstants.avogadro_number` | mol⁻¹ |
| `h`, `c`, `k_B`, `c₂` | `PLANCK_CONSTANT`, `SPEED_OF_LIGHT`, `BOLTZMANN_CONSTANT`, `SECOND_RADIATION_CONSTANT` | Universal constants (module constants, not fields) |

Physical constants are never numeric literals at a call site or in a kernel:
they live once, as the defaults of [`PhysicalConstants`](@ref) and
[`ThermodynamicConstants`](@ref), and propagate from a host's constants
object — through `ColumnAtmosphere.constants` on the staged path, the
`constants` argument of the column schemes, the `stefan_boltzmann` field of
the ecCKD gas-optics models, and the `constants` keyword of the RRTMGP
adapter. Examples and tests bind them once at the top of a file
(`constants = PhysicalConstants()`, then `g = constants.gravity`).

## Sigma-coordinate vertical grid

The vertical grid is stored in [`ColumnGrid`](@ref) using the
pressure-normalized `σ = p / pₛ` convention inherited from SpeedyWeather.

| Math | Code | Description |
|:-----|:-----|:------------|
| `σₖ` at midpoints | `σ_full` | Length `Nz` |
| `σₖ₊½` at interfaces | `σ_half` | Length `Nz + 1`, monotonic from 0 (TOA) to 1 (surface) |
| `Δσₖ` | `σ_thick` | Layer thickness, `= diff(σ_half)` |

Note: the package uses `σ` for the vertical coordinate *and* `σ` in context
for the Stefan–Boltzmann constant (e.g. `PhysicalConstants.stefan_boltzmann`).
Local variables in the solvers disambiguate with `σ_SB`.

## Column-example symbols

The executable documentation examples share one vocabulary for column state,
defined at first use on each page:

| Symbol | Meaning |
|:-------|:--------|
| `Nz` | Number of layers; interface arrays have length `Nz + 1` |
| `pᵢ`, `p` | Interface and layer pressures (Pa), top-down, increasing downward |
| `Tᵢ`, `T`, `Tₛ` | Interface, layer, and surface temperatures (K) |
| `χH₂O`, `χO₃`, `χCO₂`, … | Mole fractions relative to dry air (dry-air volume mixing ratios) |
| `nᵈ` | Dry-air molar amount per layer (mol m⁻²); gas amounts are `χ .* nᵈ` |
| `Ṫ` | Temperature tendency (K s⁻¹); example plots show `Ṫ * 86_400` in K day⁻¹ |
| `mᵈ`, `mᵛ` | Dry-air and water molar masses (kg mol⁻¹), from `PhysicalConstants` |
| `μ₀` | Cosine of the solar zenith angle |
| `Rᵈ` | Dry-air gas constant (J kg⁻¹ K⁻¹), from `PhysicalConstants` |
| `S₀` | Prescribed TOA downwelling shortwave flux (W m⁻²), `PhysicalConstants.solar_constant` |
| `Γ` | Critical lapse rate (K m⁻¹) |
| `Cₛ` | Surface slab heat capacity (J m⁻² K⁻¹) |
| `longwave_gpoints`, `shortwave_gpoints` | g-point counts of the loaded gas-optics model |

## Chemical species

Identifiers — struct fields, function names, keyword arguments, local
variables — name a species in English words, never by chemical formula:
`water_vapor`, `carbon_dioxide`, `ozone`, `methane`, `nitrous_oxide`, and
`mole_fraction` for what RRTMGP calls a volume mixing ratio (`VmrGM`). Math
notation and prose use the formula with subscripts: `H₂O`, `CO₂`, `O₃`, `CH₄`,
`N₂O`, `χ_H₂O`. RRTMGP's own field names (`state.vmr.vmr_h2o`) and
SpeedyWeather's (`greenhouse_gases.co2`) are used as they are when addressing
those packages' structs.

| Species | Identifier | Math / prose |
|:--------|:-----------|:-------------|
| Water vapor | `water_vapor`, `water_vapor_mole_fraction` | `H₂O`, `χ_H₂O` |
| Carbon dioxide | `carbon_dioxide` | `CO₂` |
| Ozone | `ozone` | `O₃` |
| Methane | `methane` | `CH₄` |
| Nitrous oxide | `nitrous_oxide` | `N₂O` |
| Volume mixing ratio | `mole_fraction`, `mole_fractions` | `χ` |

The gas-name `Symbol`s of the ecCKD models — `:h2o`, `:co2`, `:o3`, `:ch4`,
`:n2o`, `:cfc11`, `:cfc12`, `:composite` in `names`, [`gas_names`](@ref) and
the `gases` `NamedTuple` of a [`ColumnAtmosphere`](@ref) — are the one
exception: they mirror the ecCKD NetCDF variable prefixes
(`h2o_molar_absorption_coeff`) and the CKDMIP/RFMIP file variables, see
[ecCKD files](gas_optics/ecckd_files.md).

## Longwave spectroscopy

| Math | Code | Description |
|:-----|:-----|:------------|
| `ν̃` | `ν̃` | Wavenumber (cm⁻¹) |
| `B(T, ν̃)` | [`planck_wavenumber`](@ref) | Spectral Planck radiance |
| `κ_line^ref(ν̃)` | [`water_vapor_line_absorption_reference`](@ref) | Reference H₂O line absorption |
| `κ_cnt^ref(ν̃)` | [`water_vapor_continuum_absorption_reference`](@ref) | Reference H₂O continuum absorption |
| `κ_CO₂^ref(ν̃)` | [`carbon_dioxide_absorption_reference`](@ref) | Reference CO₂ absorption |
| `Δτ` | [`NumericalRadiation.williams_optical_depth_increment`](@ref) | Layer optical-depth increment |
| `τ(p)` | integrated internally | Optical depth |
| `D` | `AnalyticBandLongwave.diffusivity` | Two-stream diffusivity factor (≈ 1.5) |

Loop-internal scalar accumulators in [`solve_longwave!`](@ref) use compact
names `U` and `D` for `ℐꜛ` and `ℐꜜ` in the spectral sweep. Comments in the
solver tie them to the math.
