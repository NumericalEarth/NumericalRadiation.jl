# Notation and conventions

This appendix establishes a common notation across the documentation and the
source code of `NumericalRadiation`. Each entry lists a mathematical symbol,
the Unicode form used in code, the accessor or field that holds the quantity
where one exists, and a description. Symbols shared with
[Breeze](https://github.com/NumericalEarth/Breeze.jl) — the host these
solvers are written for — are spelled exactly as Breeze's
[notation appendix](https://numericalearth.github.io/Breeze.jl/dev/appendix/notation/)
spells them, and `NumericalRadiation` follows the
[NumericalEarth.jl notation guide](https://github.com/NumericalEarth/NumericalEarth.jl/blob/main/docs/src/appendix/notation.md)
for symbolic names in math, docstring equations and plot labels.

The conventions the table relies on:

* **Unicode sub- and superscripts in code.** A digit or letter that is a
  subscript or superscript in the mathematics is a subscript or superscript
  glyph in the identifier: `μ₀`, `γ₁`, `c₀₀`, `i₀ᵖ`, `Tˢ`, `κˡ`, never
  `mu0`, `gamma1`, `c00`, `ip0`, `Ts`, `kappa_l`.
* **One register per function.** Within a function or struct a quantity is
  named either by the unicode symbol of the equation in its docstring, with
  its phase, process and interface labels as sub- and superscripts (`ωˡ`,
  `κⁱ`, `τₛᶜ`, `Bₖ₊₁`), or by whole English words (`optical_depth`,
  `water_path`, `cloud_fraction`). An identifier is never half of each — no
  `_` in a symbolic name, no symbol in an English one — and the two registers
  never meet in one expression. Struct fields and caller-owned arrays are
  descriptive snake_case (public storage, matching Breeze); reading
  `optics.single_scattering_albedo[g, k]` into a local `ω` is the boundary
  between the registers. Where a docstring writes an equation, the code below
  it uses those exact symbols.
* **Processes and interfaces are subscripts**: `ₐ` absorption, `ₛ`
  scattering and `ₑ` extinction (`τₐ`, `τₛ`, `τₑ`, `κₛ`, `Σκₛ`); a layer's
  top and bottom interfaces are `ₖ` and `ₖ₊₁` (`Bₖ`, `Bₖ₊₁`, `Sꜛₖ`, `ℐₖ₊₁`).
* **Reference quantities** take a subscript ``r`` (`p_ref`, `T_ref` are the
  Williams (2026) Table 1 names and the one exception).
* **Phase and region labels are superscripts**: `ˡ` liquid, `ⁱ` ice, `ᶜ`
  cloud (liquid + ice mixture), `ᵈ` dry air, `ᵛ` water vapor, `ˡʷ` longwave,
  `ˢʷ` shortwave, and `ˢ` is reserved for the *surface* (`Tˢ`, `pˢ`, `Bˢ`),
  as in Breeze. A subscript `i` (`pᵢ`, `Tᵢ`) is an interface value, which
  never collides with the ice superscript.
* **Counts** use the Oceananigans capital-`N` form, short where the indexed
  quantity has a one-letter symbol: `Nz` layers in a column (interfaces are
  `Nz + 1`), `Ng` g points (`Ngˡʷ`, `Ngˢʷ` for the longwave and shortwave
  sets), `Nr` effective-radius nodes, and otherwise an English word: `Ngases`,
  `Ncolumns`, `Npressures`, `Ntemperatures`, `Nwater_vapor`, `Nwavenumbers`,
  `Nintervals`, `Nnodes`, `Nprofiles`, `Nsites`, `Nlongwave_bands`,
  `Nshortwave_bands`.
* **Columns are top-down**: layer `k = 1` is at the top of the atmosphere,
  interfaces run `k = 1:Nz + 1` with interface `1` at the top and `Nz + 1`
  at the surface, and pressure increases with `k`.
* **Fluxes are positive in their own direction**: `ℐꜜ` is positive downward,
  `ℐꜛ` positive upward, and the net flux `ℐ = ℐꜜ - ℐꜛ` is positive
  downward; a positive heating rate warms the layer.
* **Gas amounts are molar column amounts** in mol m⁻² per layer, under the
  *dry column-amount convention* of the ecCKD tables: the dry air of a
  hydrostatic layer is `nᵈ = Δp / (g mᵈ)` (`hydrostatic_air_moles`, the
  `:composite` entry of the gas container) and every gas is `χ nᵈ` with `χ`
  its mole fraction relative to dry air (`h2o = χH₂O nᵈ`, and so on).
* `constants` is a [`PhysicalConstants`](@ref); physical constants are never
  numeric literals at a call site or in a kernel, they propagate from a host's
  constants object (`ColumnAtmosphere.constants`, the `constants` argument of
  the column schemes, the `stefan_boltzmann` field of the ecCKD models, the
  `constants` keyword of the RRTMGP adapter). Examples and tests bind them
  once at the top of a file (`constants = PhysicalConstants()`, then
  `g = constants.gravity`).

The letter `g` is spoken for twice, and the table records how the package
keeps the two apart. **`g` is the g-point index** — the cumulative-probability
coordinate of the correlated-*k* method is literally `g`, so loops read
`for g in 1:Ng` and a layer-optics functor is called as `layer_optics(g, k)` —
and `g` is also **gravity** in the hydrostatic and heating-rate functions
(`hydrostatic_air_moles`, `heating_rates!`); no function has both in scope. The
scattering **asymmetry factor is therefore `𝒢`** (U+1D4A2, `\mathcal{G}`):
`g` is taken, and `γ` is the two-stream coefficient family `γ₁ … γ₄`. Bare
**`σ` is the Stefan–Boltzmann constant** while the sigma coordinate is never
bound to bare `σ` (it lives in the `ColumnGrid.σ_full`, `σ_half`, `σ_thick`
fields inherited from SpeedyWeather, in `σ_level` arguments, and in `Δσ_k`).

| LaTeX math | Unicode code form | Accessor or field | Description |
|:-----------|:------------------|:------------------|:------------|
| **Constants** | | | |
| ``g`` | `g` | `constants.gravity` | Gravitational acceleration, m s⁻² (Breeze), in the hydrostatic and heating-rate functions only; elsewhere `g` is the g-point index (below). Never the asymmetry factor, which is `𝒢` |
| ``c^p`` | `cᵖ` | `constants.heat_capacity` | Isobaric specific heat of dry air, J kg⁻¹ K⁻¹ (Breeze) |
| ``\sigma`` | `σ` | `constants.stefan_boltzmann`, `model.stefan_boltzmann` | Stefan–Boltzmann constant, W m⁻² K⁻⁴ (Breeze). Also the sigma coordinate of `ColumnGrid`, which is never bound to bare `σ` |
| ``S_0`` | `S₀` | `constants.solar_constant` | Solar constant, W m⁻²; the horizontal TOA flux is `ℐꜜ_toa = S₀ μ₀` |
| ``m^d``, ``m^v`` | `mᵈ`, `mᵛ` | `constants.dry_air_molar_mass`, `constants.water_molar_mass` | Molar masses of dry air and water vapor, kg mol⁻¹ (Breeze) |
| ``m^v / m^d`` | `mᵛ_over_mᵈ` | `AnalyticBandLongwave.water_vapor_molar_mass_ratio` | Water-to-dry-air molar mass ratio of the vapor partial pressure (`ε` is emissivity, not this ratio) |
| ``R^d`` | `Rᵈ` | `constants.dry_air_gas_constant` | Dry-air gas constant, J kg⁻¹ K⁻¹ (Breeze) |
| ``\mathcal{R}`` | `ℛ` | `constants.universal_gas_constant` | Universal (molar) gas constant, J mol⁻¹ K⁻¹ (Breeze); `ℛ` is also the layer reflectance of the two-stream functions, which never see the gas constant |
| ``N_A`` | `Nᴬ` | `constants.avogadro_number` | Avogadro number, mol⁻¹ |
| ``h``, ``c``, ``k_B`` | `h`, `c`, `kᴮ` | `PLANCK_CONSTANT`, `SPEED_OF_LIGHT`, `BOLTZMANN_CONSTANT` | Planck constant, speed of light, Boltzmann constant (module constants, CODATA 2018) |
| ``c_2`` | `c₂` | `SECOND_RADIATION_CONSTANT` | Second radiation constant `100 h c / kᴮ`, cm K |
| ``D`` | `D` | `AnalyticBandLongwave.diffusivity`; `D = 1.66` in the ecCKD longwave path | Two-stream diffusivity factor; `Dτ` is the diffusivity-scaled optical depth |
| **Column state and grid** | | | |
| ``N_z`` | `Nz` | `number_of_layers(optics)` | Number of layers; interface arrays have length `Nz + 1` |
| ``k`` | `k` | | Layer index, top down; `k` and `k + 1` are a layer's top and bottom interfaces |
| ``p`` | `p`, `p_k` | `ColumnAtmosphere.pressure_layers` | Layer pressure, Pa, increasing downward |
| ``p_i`` | `pᵢ` | `ColumnAtmosphere.pressure_interfaces` | Interface pressure, Pa, length `Nz + 1` |
| ``\Delta p`` | `Δp`, `Δp_k` | `diff(pressure_interfaces)` | Layer pressure thickness, Pa |
| ``p^s`` | `pˢ` | `AtmosphereProfile.surface_pressure` | Surface pressure, Pa (Breeze) |
| ``T`` | `T`, `T_k` | `ColumnAtmosphere.temperature_layers`, `AtmosphereProfile.temperature` | Layer temperature, K (Breeze) |
| ``T_i`` | `Tᵢ` | `ColumnAtmosphere.temperature_interfaces` | Interface temperature, K |
| ``T^s`` | `Tˢ` | `surface.temperature`, `SurfaceState.sea_surface_temperature`, `land_surface_temperature` | Surface temperature, K |
| ``\dot T`` | `Ṫ` | `temperature_tendency`, `heating_rates!` | Temperature tendency, K s⁻¹ (example plots show `Ṫ * 86_400` in K day⁻¹) |
| ``q^v`` | `q`, `q_k` | `AtmosphereProfile.humidity` | Specific humidity, kg kg⁻¹ (Breeze's `qᵛ`; the column schemes write `q`) |
| ``p^{v}`` | `pᵛ_k` | | Vapor partial pressure, Pa (Breeze) |
| ``p^{v+}`` | `pᵛ⁺` | `saturation_vapor_pressure` | Saturation vapor pressure, Pa (Breeze) |
| ``\Phi`` | `Φ` | `AtmosphereProfile.geopotential` | Geopotential, m² s⁻² |
| ``\sigma_k``, ``\sigma_{k+\frac12}``, ``\Delta\sigma_k`` | `σ_full`, `σ_half`, `σ_thick`, `Δσ_k`, `σ_level` | `ColumnGrid.σ_full`, `.σ_half`, `.σ_thick` | Sigma coordinate `p / pˢ` at layer midpoints (length `Nz`), interfaces (length `Nz + 1`, 0 at the top, 1 at the surface) and the layer thickness `diff(σ_half)`; a generic level is `σ_level` |
| ``\chi`` | `χ`, `χH₂O`, `χCO₂`, `χO₃`, `χCH₄`, `χN₂O` | `mole_fractions`, `water_vapor_mole_fraction` | Mole fraction relative to dry air (dry-air volume mixing ratio; RRTMGP's `vmr`), formula glued as in `H₂O` |
| ``n^d`` | `nᵈ`, `air_moles`, `dry_air_moles` | `gases.composite`, [`hydrostatic_air_moles`](@ref) | Dry-air molar amount of a layer, mol m⁻², `Δp / (g mᵈ)` |
| ``n`` | `n`, `gases`, `layer_gases` | `ColumnAtmosphere.gases`, [`layer_gases`](@ref) | Molar amount of a gas in a layer, mol m⁻², `χ nᵈ`; keyed `:composite :h2o :co2 :o3 :ch4 :n2o :cfc11 :cfc12` after the ecCKD files |
| ``\mathrm{CO_2}`` | `CO₂`, `default_CO₂` | `AtmosphereProfile.CO₂` | CO₂ concentration of the column schemes, ppmv |
| ``\zeta`` | `ζ` | `OneBandShortwaveRadiativeTransfer.ozone_distribution` | Ozone vertical distribution over the sigma coordinate, `∫ ζ dσ_level = 1`; `ozone_absorption_k` is the fraction of the TOA flux it absorbs in layer `k` |
| **Gas optics** | | | |
| ``\tau`` | `τ`, `τᶜ` | `optical_depth`, [`longwave_optical_depth`](@ref), [`shortwave_optical_depth`](@ref) | Layer optical depth, absorption plus scattering (the two-stream functions take this total with `ω` and `𝒢`) |
| ``\Delta\tau`` | `Δτ`, `Δτ_k`, `Δτ_bottom`, `Δτ_H₂O_line`, `Δτ_H₂O_continuum`, `Δτ_CO₂` | [`NumericalRadiation.williams_optical_depth_increment`](@ref) | Layer optical-depth increment, by absorber in the Williams scheme (`q_CO₂` is its CO₂ mass mixing ratio) |
| ``\tau^{lw}``, ``\tau^{sw}`` | `τˡʷ`, `τˢʷ`, `τₐˢʷ`, `τₛˢʷ`, `τₑˢʷ` | `CloudOptics.longwave_optical_depth`, `shortwave_optical_depth`, `shortwave_scattering_optical_depth` | Longwave and shortwave optical depths (Breeze) |
| ``\kappa`` | `κ`, `κ_line`, `κ_continuum`, `κ_CO₂` | `mass_extinction_coefficient`, `longwave_mass_absorption`, `shortwave_mass_extinction`, table `longwave_absorption`/`shortwave_absorption` | Mass (m² kg⁻¹) or molar (m² mol⁻¹) absorption or extinction coefficient |
| ``(i_0, i_1, w)`` | `(i₀, i₁, w)`, `(i₀ᵖ, i₁ᵖ, wᵖ)`, `(i₀ᵀ, i₁ᵀ, wᵀ)`, `(i₀ᴴ, i₁ᴴ, wᴴ)` | [`GasOpticsStencil`](@ref) `.pressure`, `.temperature`, `.water_vapor`; [`effective_radius_bracket`](@ref); [`source_table_bracket`](@ref) | Table bracket: lower node, upper node and interpolation weight; `w₀ = 1 - w`; `T₁` is the first node of the Planck source-table temperature grid, below which the source is scaled linearly to zero |
| ``i^p, i^T, i^H`` | `iᵖ`, `iᵀ`, `iᴴ` | | Loop indices over the pressure, temperature and H₂O table grids |
| ``c_{00}, \ldots, c_{111}``; ``c_0, c_1`` | `c₀₀ … c₁₁`, `c₀₀₀ … c₁₁₁`; `c₀`, `c₁` | | Table corner values, subscripts naming the pressure, temperature (and H₂O) nodes; partial interpolants at the nodes still to be interpolated |
| ``B`` | `B`, `Bₖ`, `Bₖ₊₁`, `Bˢ` | [`longwave_source`](@ref), `LongwaveOptics.source`, `source_top`, `source_bottom`, [`planck_wavenumber`](@ref) | Planck source in flux units at a layer, at its top and bottom interfaces `k`, `k + 1`, or at the surface; `σT⁴` is the gray fallback; `πB(T, ν̃)` the hemispheric spectral flux |
| ``\partial B`` | `∂B` | | Planck gradient along optical depth in a layer, `(Bₖ₊₁ - Bₖ) / (Dτ)` |
| ``w_g`` | `w`, `weights` | `model.longwave_weights`, `shortwave_weights`, `optics.weights` | Spectral quadrature weight of a g point |
| ``g`` | `g`, `Ng`, `Ngˡʷ`, `Ngˢʷ` | [`gas_names`](@ref), `number_of_gpoints(optics)` | Index and count of correlated-*k* quadrature points: `g` is the cumulative-probability coordinate of the correlated-*k* method, so the g-point index is literally `g` (`for g in 1:Ng`, `layer_optics(g, k)`); never in scope together with gravity |
| ``\tilde\nu`` | `ν̃`, `ν̃ₘ`, `Δν̃`, `ν̃₀`, `ν̃₁`, `ν̃₂` | `wavenumber1`, `wavenumber2`, `wavenumber_min`, `wavenumber_max` | Wavenumber, cm⁻¹ (`ν̃ₘ` in m⁻¹), spectral step, and the bounds of neighbouring spectral intervals `interval₀`, `interval₁`, `interval₂` |
| ``\tau_\mathrm{Rayleigh}`` | `τₛ` | [`rayleigh_optical_depth`](@ref), `ShortwaveOptics.rayleigh_optical_depth` | Rayleigh (clear-sky) scattering optical depth |
| ``\kappa_\mathrm{rot}, l_\mathrm{rot}, \ldots`` | `κ_rot l_rot κ_vr l_vr1 l_vr2 κ_cnt1 κ_cnt2 κ_CO₂ l_CO₂ ν̃_CO₂ p_ref pv_ref T_ref σ_cont` | [`AnalyticBandLongwave`](@ref) fields | Williams (2026) Table 1 parameters, spelled as in the paper and documented field by field |
| **Radiative transfer and two-stream coefficients** | | | |
| ``\mu_0`` | `μ₀` | `geometry.cos_zenith`, `SurfaceState.cos_zenith`, [`cosine_solar_zenith`](@ref) | Cosine of the solar zenith angle (Breeze); `1/μ₀` is the direct-beam slant-path factor |
| ``\omega`` | `ω`, `ωˡ`, `ωⁱ`, `ωᶜ` | `single_scattering_albedo`, `shortwave_single_scattering_albedo` | Single-scattering albedo, `τₛ / (τₐ + τₛ)`; one symbol, never `ω₀` |
| ``\mathcal{G}`` | `𝒢`, `𝒢ˡ`, `𝒢ⁱ`, `𝒢ᶜ` | `asymmetry_factor`, `scattering_asymmetry`, `shortwave_scattering_asymmetry` | Scattering asymmetry factor; `𝒢` because `g` is the g-point index (and gravity) and `γ` is the two-stream coefficient family |
| ``f`` | `f` | | Delta-Eddington forward-peak fraction `f = 𝒢²`; scaled optics are `τ′ ω′ 𝒢′` |
| ``\gamma_1, \gamma_2, \gamma_3, \gamma_4`` | `γ₁`, `γ₂`, `γ₃`, `γ₄` | | Two-stream coefficients (practical improved flux method in the shortwave, hemispheric mean with `D` in the longwave) |
| ``\alpha_1, \alpha_2`` | `α₁`, `α₂` | | Meador–Weaver direct-beam coefficients `γ₁γ₄ + γ₂γ₃`, `γ₁γ₃ + γ₂γ₄` |
| ``\lambda`` | `λ`, `λμ₀` | | Two-stream eigenvalue `√((γ₁ - γ₂)(γ₁ + γ₂))` (`k` is the layer index) |
| ``\mathcal{R}``, ``\mathcal{T}`` | `ℛ`, `𝒯`, `𝒯_k`, `𝒯[k]` | `reflectance`, `transmittance`, `transmissivity_scratch` | Diffuse reflectance and transmittance of a layer |
| ``\mathcal{R}^0``, ``\mathcal{T}^0`` | `ℛ⁰`, `𝒯⁰` | `direct_reflectance`, `direct_diffuse_transmittance` | Direct-beam reflectance and direct-to-diffuse transmittance |
| ``\mathcal{D}`` | `𝒟` | | Direct transmittance `e^{-τ/μ₀}` of a layer; `ShortwaveColumnScratch.direct_flux` holds its running product times the incoming normal flux |
| ``S^\uparrow``, ``S^\downarrow`` | `Sꜛ`, `Sꜜ`, `Sꜛₖ`, `Sꜜₖ₊₁`, `S` | `source_up`, `source_down`, `source` | Upward and downward layer emission (longwave); `S` when both directions coincide |
| ``e, e^2, m_1, m_2, d`` | `e`, `e₂`, `m₁`, `m₂`, `d` | | `e^{-λτ}`, `e^{-2λτ}`, `1 - e^{-λτ}`, `1 - e^{-2λτ}`, `1 - e^{-τ/μ₀}` (the conservative-limit rearrangement of the shortwave layer solution) |
| ``\alpha`` | `α` | `overlap_parameter` | ecRad/Hogan–Illingworth cloud-overlap parameter between adjacent layers (also the surface albedo, below; the two never meet in one function) |
| ``\mathcal{R}_\infty`` | `ℛ∞`, `Σℛ∞` | | Reflectance of a semi-infinite layer used by ecRad's thick averaging, and its weighted sum |
| ``\Sigma`` | `Σκ`, `Σκₛ`, `Σκₛ𝒢`, `Σw` | | Weighted sums over spectral intervals when mapping cloud properties onto g points |
| **Cloud and aerosol optics** | | | |
| ``\kappa^l``, ``\kappa^i`` | `κˡ`, `κⁱ` | `liquid_shortwave_mass_extinction`, `ice_shortwave_mass_extinction`, `mass_extinction_coefficient` | Liquid and ice mass-extinction coefficients, m² kg⁻¹ |
| ``\tau_a``, ``\tau_s``, ``\tau_e`` | `τₐ`, `τₛ`, `τₑ`, `τₑˡ`, `τₛⁱ`, `τₐᶜ`, `τₛᶜ`, `τₐ′` | `optical_depth`, `rayleigh_optical_depth` | Absorption, scattering and extinction optical depths of a layer, a phase or the cloud mixture; a prime marks the value after folding in a constituent |
| ``\tau^c``, ``\omega^c``, ``\mathcal{G}^c`` | `τᶜ`, `ωᶜ`, `𝒢ᶜ` | | Optics of the combined liquid + ice cloud |
| ``W`` | `W`, `Wˡ`, `Wⁱ` | `water_path`, `liquid_water_path`, `ice_water_path`, `cloud_water_path`, `aerosol_path` | Condensed-water or aerosol mass path of a layer, kg m⁻² |
| ``r_e`` | `effective_radius`, `radius_bracket`, `Nr` | `SpectralCloudOptics.effective_radius`, [`effective_radius_bracket`](@ref) | Effective radius, m, its node bracket, and the count `Nr` of tabulated effective-radius nodes |
| ``c`` | `cloud_fraction`, `cloud_cover` | `cloud_fraction`, `ShortwaveDiagnostics.cloud_cover` | Layer cloud fraction and column cloud cover |
| ``f_\mathrm{sd}`` | `fractional_standard_deviation` | `fractional_standard_deviation` | In-cloud optical-depth variability of the Tripleclouds split |
| **Fluxes and heating rates** | | | |
| ``\mathscr{I}^\uparrow``, ``\mathscr{I}^\downarrow`` | `ℐꜛ`, `ℐꜜ`, `ℐꜛ_new`, `ℐꜜ_surface`, `ℐꜛ_reflected` | `RadiativeFluxes.longwave_up`, `longwave_down`, `shortwave_up`, `shortwave_down`; `flux_up`, `flux_down`; `up`, `down` | Upward and downward radiative flux, W m⁻² (Breeze), positive in its own direction |
| ``\mathscr{I}^{\uparrow lw}``, ``\mathscr{I}^{\downarrow lw}`` | `ℐꜛˡʷ`, `ℐꜜˡʷ` | `LongwaveDiagnostics.outgoing_longwave` (TOA), `surface_longwave_up`, `ocean_surface_longwave_up`, `land_surface_longwave_up`, `surface_longwave_down` | Longwave fluxes (Breeze) |
| ``\mathscr{I}^{\uparrow sw}``, ``\mathscr{I}^{\downarrow sw}`` | `ℐꜛˢʷ`, `ℐꜜˢʷ` | `ShortwaveDiagnostics.outgoing_shortwave` (TOA), `surface_shortwave_up`, `surface_shortwave_down`, `ocean_surface_shortwave_up`, `land_surface_shortwave_down`, … | Shortwave fluxes (Breeze) |
| ``\mathscr{I}^\downarrow_\mathrm{toa}`` | `ℐꜜ_toa` | `toa_shortwave_down`, `toa_irradiance` | Downwelling shortwave flux through a horizontal surface at the top of the atmosphere, `S₀ μ₀` |
| ``\mathscr{I}`` | `ℐ`, `ℐₖ`, `ℐₖ₊₁` | | Net downward flux `ℐꜜ - ℐꜛ` summed over the longwave and shortwave, at a layer's interfaces `k`, `k + 1` |
| ``F_{\mathscr{I}}`` | `Ṫ`, `heating` | [`heating_rates!`](@ref), [`radiative_heating!`](@ref) | Radiative heating rate `g / cᵖ (ℐₖ - ℐₖ₊₁) / Δp`, K s⁻¹ (Breeze's `Fℐ`) |
| ``\mathrm{OLR}`` | `outgoing_longwave`, `OLR`, `olr₁` | `LongwaveDiagnostics.outgoing_longwave` | Outgoing longwave radiation at the top of the atmosphere (an accepted acronym, like TOA and RMSE) |
| **Surface and geometry** | | | |
| ``\varepsilon`` | `ε`, `ε_ocean`, `ε_land` | `emissivity`, `SurfaceState.ocean_emissivity`, `land_emissivity` | Surface emissivity; the surface source is `ε B(Tˢ)` |
| ``\alpha`` | `α`, `α_ocean`, `α_land`, `α_cloud`, `α_stratocumulus`, `α_direct`, `α_diffuse` | `surface_albedo`, `surface_albedo_direct`, `SurfaceState.ocean_albedo`, `land_albedo`, `ShortwaveDiagnostics.albedo`, `stack_albedo` | Albedo of the surface (Lambertian; diffuse and direct), of a cloud, or of the stack below an interface |
| ``\mathcal{R}_\mathrm{cloud}`` | `ℛ_cloud` | | Cloud-top reflectance `α_cloud cloud_cover` of the one-band shortwave scheme |
| ``\delta`` | `δ` | [`solar_declination`](@ref) | Solar declination, rad |
| ``\gamma`` | `γ` | `fractional_year_angle` | Fractional-year angle `2π (day - 1) / days_per_year`, rad |
| | `hour_angle`, `time_correction` | [`equation_of_time`](@ref) | Hour angle and equation-of-time correction, rad |
| | `land_fraction` | `SurfaceState.land_fraction` | Land fraction of the surface, weighting ocean and land albedos and emissivities |

## Exceptions

Names that mirror an external file or library keep the upstream spelling,
and are the only identifiers exempt from the rules above:

* the ecCKD, CKDMIP and RFMIP NetCDF variable, dimension and attribute names
  (`h2o_molar_absorption_coeff`, `lw_gpoints`, `planck_function`,
  `wavenumber1`, `wavenumber2`, the CKDMIP `"mu0"` coordinate string) and the
  gas `Symbol`s `:h2o :co2 :o3 :ch4 :n2o :cfc11 :cfc12 :composite` of the
  ecCKD models' `names`, [`gas_names`](@ref) and the `gases` container of a
  [`ColumnAtmosphere`](@ref), which mirror the file variable prefixes (see
  [ecCKD files](gas_optics/ecckd_files.md));
* RRTMGP struct fields and keywords (`vmr_h2o`, `ncol`, `nbnd_lw`, `grav`,
  `molmass_dryair`, `Stefan`);
* SpeedyWeather fields and keywords (`σ_levels_full`, `σ_levels_half`, `σ_levels_thick`, `mol_mass_dry_air`,
  `R_dry`, `greenhouse_gases.co2`, `SpectralGrid(nlayers=8)`,
  `spectral_grid.nlayers`);
* the Williams (2026) Table 1 parameters of [`AnalyticBandLongwave`](@ref)
  listed in the table, and the SPEEDY Fortran names quoted in the docstrings of
  the one-band shortwave scheme (`GSES0`, `absdry`, `azen`, `nzen`);
* the option `Symbol`s `:matrix_alpha`, `:tripleclouds_alpha`,
  `:matrix_maximum`, which are public API values;
* the column schemes ported from SPEEDY and the Williams (2026) scheme
  (`src/shortwave`, `src/longwave`, `column_views.jl`), which keep descriptor
  suffixes such as `q_k`, `ℐꜛ_surface`, `α_ocean` and `Δσ_k`.

Identifiers otherwise never spell a species by chemical formula — they say
`water_vapor`, `carbon_dioxide`, `ozone`, `methane`, `nitrous_oxide` — while
mathematics and prose use the formula with subscripts (`H₂O`, `CO₂`, `χH₂O`).

## Layout

Two layout rules, borrowed from Oceananigans, hold throughout the source,
tests, examples and documentation:

* **A statement that fits in about 120 characters is written on one line.**
  An assignment is never split after `=`, a guard `cond || throw(...)` is
  not broken before `throw`, a call or signature is not spread over several
  lines, and a tuple is not written one field per line when the whole fits.
  A statement that does not fit keeps either the first operand on the `=`
  line with the operator continuations aligned under it, or `=` closing the
  line and a four-space body (long short-form methods and destructurings).
* **Continuation lines align with the first argument** after the opening
  bracket of a call, signature, type-parameter list or literal (`f(; a,` aligns
  with `a`), and with the first operand of a multi-line expression. Keyword
  lists written across several lines are spaced, `a = 1`; keywords inside a
  call on one line are not, `f(x=1)`, and neither are keyword defaults in a
  one-line signature or fields of a one-line named tuple, `(; a=1, b=2)`.
