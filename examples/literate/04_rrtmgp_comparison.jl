# # ecCKD vs RRTMGP: clear-sky longwave
#
# This example asks one question: *for a single clear-sky column defined once
# physically, how do the ecCKD-32×32 staged path and RRTMGP (through the
# package's `NumericalRadiationRRTMGPExt` adapter) compare in longwave fluxes
# and heating rates?* Both are correlated-k implementations; they differ in
# their gas-optics tables (ecCKD's trained 32-g-point tables with a composite
# O₂/N₂ background versus RRTMGP's lookup with explicit O₂/N₂) and in their
# transfer implementations, so the result is an *inter-implementation
# difference* on this column, not an error measurement for either model.
#
# ## One physical column, two gas representations
#
# The shared definition is the physical state: pressures, temperatures, and
# per-gas **volume mixing ratios relative to dry air** (RRTMGP's native
# convention, established by its `compute_col_gas_kernel!`). RRTMGP consumes
# the VMRs directly; the ecCKD path consumes **layer molar amounts in
# mol m⁻²**, so the conversion between the two representations is written out
# explicitly below and cross-checked against RRTMGP's own column computation.

using NumericalRadiation
using NCDatasets     # NetCDF reader extension (ecCKD files)
using ClimaComms     # RRTMGP adapter extension trigger …
using RRTMGP         # … and RRTMGP itself
using Printf

nlayers = 48
p_i = collect(range(2_000.0, 101_325.0; length = nlayers + 1))   # Pa, TOA first
p_layers = 0.5 .* (p_i[1:end-1] .+ p_i[2:end])

Tsfc = 300.0
T_layers = clamp.(Tsfc .- 65.0 .* (1 .- (p_layers ./ 101325.0) .^ 0.286), 200.0, Tsfc)
T_interfaces = clamp.(Tsfc .- 65.0 .* (1 .- (p_i ./ 101325.0) .^ 0.286), 200.0, Tsfc)

vmr_h2o = @. 0.015 * (p_layers / 101325.0)^3 + 3.0e-6   # moist below, dry aloft
vmr_o3  = @. 3.0e-8 + 5.0e-6 * (2_000.0 / p_layers)     # crude ozone increase aloft
vmr_co2 = 420.0e-6
vmr_ch4 = 1.8e-6
vmr_n2o = 330.0e-9
nothing #hide

# The hydrostatic relation gives the dry-air molar amount of each layer. With
# `vmr` relative to dry air, the layer's mass per area is
# ``n_\mathrm{dry} (M_\mathrm{dry} + \mathrm{vmr}_{\mathrm{H_2O}} M_{\mathrm{H_2O}})``,
# so (dry-air molar-mass convention, matching RRTMGP):

const GRAVITY = 9.80665        # m s⁻²
const M_DRY = 0.028964         # kg mol⁻¹
const M_H2O = 0.018016         # kg mol⁻¹

dry_layer_amounts(vmr_h2o, p_i) =
    [(p_i[k + 1] - p_i[k]) / (GRAVITY * (M_DRY + M_H2O * vmr_h2o[k]))
     for k in 1:(length(p_i) - 1)]

n_dry = dry_layer_amounts(vmr_h2o, p_i)                  # mol m⁻²
nothing #hide

# Each representation gets its own `ColumnAtmosphere`. Gas-set parity needs
# care on the ecCKD side: the tabulated composite background *contains the
# reference contribution of every tabulated gas*, and activating a gas
# subtracts its reference mole fraction times the composite amount before
# adding the requested amount. A gas left out of `gas_names` is therefore
# kept at its reference abundance, not removed. So the full tuple is
# activated here: CH₄ and N₂O carry the same abundances as the RRTMGP side,
# and the CFCs are activated with zero amount — which removes their reference
# contribution — because RRTMGP's clear-sky lookup has no CFC fields. Both
# surfaces emit as blackbodies.

ecckd_atmosphere = ColumnAtmosphere(;
    pressure_layers = p_layers, pressure_interfaces = p_i,
    temperature_layers = T_layers, temperature_interfaces = T_interfaces,
    gases = (composite = n_dry,
             h2o = vmr_h2o .* n_dry,
             o3 = vmr_o3 .* n_dry,
             co2 = vmr_co2 .* n_dry,
             ch4 = vmr_ch4 .* n_dry,
             n2o = vmr_n2o .* n_dry,
             cfc11 = 0.0,
             cfc12 = 0.0),
    surface = (temperature = Tsfc,),
    geometry = (cos_zenith = 0.5,))

rrtmgp_atmosphere = ColumnAtmosphere(;
    pressure_layers = p_layers, pressure_interfaces = p_i,
    temperature_layers = T_layers, temperature_interfaces = T_interfaces,
    gases = (h2o = vmr_h2o, o3 = vmr_o3, co2 = vmr_co2,
             ch4 = vmr_ch4, n2o = vmr_n2o,
             o2 = 0.20946, n2 = 0.78084, co = 0.0),
    surface = (temperature = Tsfc,),
    geometry = (cos_zenith = 0.5,))
nothing #hide

# ## RRTMGP leg
#
# The adapter types live in the `NumericalRadiationRRTMGPExt` package
# extension:

EXT = Base.get_extension(NumericalRadiation, :NumericalRadiationRRTMGPExt)
rrtmgp_model = EXT.RRTMGPClearSkyModel(Float64)
rrtmgp_boundary = EXT.RRTMGPBoundaryConditions(surface_temperature = Tsfc,
                                               surface_emissivity = 1.0,
                                               surface_albedo = 0.0,
                                               toa_shortwave_down = 0.0,   # longwave-only page
                                               cos_zenith = 0.5)
workspace = radiation_workspace(rrtmgp_model, rrtmgp_atmosphere)
rrtmgp_fluxes = RadiativeFluxes(longwave_up = zeros(nlayers + 1),
                                longwave_down = zeros(nlayers + 1),
                                shortwave_up = zeros(nlayers + 1),
                                shortwave_down = zeros(nlayers + 1))
radiative_fluxes!(rrtmgp_fluxes, rrtmgp_model, rrtmgp_atmosphere,
                  rrtmgp_boundary, workspace)
nothing #hide

# Before using the fluxes, verify the representation bridge: the dry-air
# amounts computed by `dry_layer_amounts` must equal the dry column RRTMGP
# itself computed from the same pressures and VMRs (RRTMGP stores
# molecules cm⁻², and its levels are bottom-up, hence the unit factor and the
# index reversal):

AVOGADRO = 6.02214076e23
col_dry_rrtmgp = reverse(workspace.atmospheric_state.layerdata[1, :, 1])
col_dry_ours = n_dry .* AVOGADRO ./ 1e4
maxrel = maximum(abs.(col_dry_rrtmgp .- col_dry_ours) ./ col_dry_ours)
@assert maxrel < 1e-6
maxrel

# ## ecCKD leg

intended_gases = (:composite, :h2o, :o3, :co2, :ch4, :n2o, :cfc11, :cfc12)
gas_optics = read_official_ecckd_gas_optics("32x32"; gas_names = intended_gases)
@assert NumericalRadiation.gas_names(gas_optics) == intended_gases

ng_lw = length(gas_optics.longwave_weights)
ng_sw = length(gas_optics.shortwave_weights)
longwave = LongwaveOpticalProperties(zeros(ng_lw, nlayers), zeros(ng_lw, nlayers);
                                     source_top = zeros(ng_lw, nlayers),
                                     source_bottom = zeros(ng_lw, nlayers),
                                     weights = zeros(ng_lw))
shortwave = ShortwaveOpticalProperties(zeros(ng_sw, nlayers); weights = zeros(ng_sw))
ecckd_fluxes = RadiativeFluxes(longwave_up = zeros(nlayers + 1),
                               longwave_down = zeros(nlayers + 1),
                               shortwave_up = zeros(nlayers + 1),
                               shortwave_down = zeros(nlayers + 1))
optical_properties!(longwave, shortwave, gas_optics, ecckd_atmosphere)
σ = 5.670374419e-8
radiative_fluxes!(ecckd_fluxes, CloudlessLongwave(), longwave, ecckd_atmosphere,
                  LongwaveBoundaryConditions(surface_longwave_up = σ * Tsfc^4))
nothing #hide

# ## Longwave-only heating rates
#
# With a zero shortwave boundary the returned shortwave fluxes are zero, so
# `heating_rates!` (which differences the total net flux) sees longwave only:

@assert all(iszero, rrtmgp_fluxes.shortwave_up)
@assert all(iszero, rrtmgp_fluxes.shortwave_down)

heating_ecckd = zeros(nlayers)
heating_rrtmgp = zeros(nlayers)
heating_rates!(heating_ecckd, ecckd_fluxes, ecckd_atmosphere;
               gravity = GRAVITY, heat_capacity = 1004.0)
heating_rates!(heating_rrtmgp, rrtmgp_fluxes, rrtmgp_atmosphere;
               gravity = GRAVITY, heat_capacity = 1004.0)

@printf("OLR, ecCKD 32×32:   %7.2f W m⁻²\n", ecckd_fluxes.longwave_up[1])
@printf("OLR, RRTMGP:        %7.2f W m⁻²\n", rrtmgp_fluxes.longwave_up[1])
@printf("ΔOLR (ecCKD − RRTMGP): %+6.2f W m⁻²\n",
        ecckd_fluxes.longwave_up[1] - rrtmgp_fluxes.longwave_up[1])

# ## The comparison, panel by panel
#
# Left: both flux profiles. Middle: the signed flux differences. Right: the
# signed heating-rate difference. Units are homogeneous within each panel.

using CairoMakie

fig = Figure(size = (1000, 420))

ax1 = Axis(fig[1, 1]; xlabel = "longwave flux (W m⁻²)",
           ylabel = "pressure (hPa)", yreversed = true, title = "Fluxes")
lines!(ax1, ecckd_fluxes.longwave_up, p_i ./ 100;
       color = :firebrick, linewidth = 2, label = "up, ecCKD")
lines!(ax1, rrtmgp_fluxes.longwave_up, p_i ./ 100;
       color = :firebrick, linewidth = 2, linestyle = :dash, label = "up, RRTMGP")
lines!(ax1, ecckd_fluxes.longwave_down, p_i ./ 100;
       color = :steelblue4, linewidth = 2, label = "down, ecCKD")
lines!(ax1, rrtmgp_fluxes.longwave_down, p_i ./ 100;
       color = :steelblue4, linewidth = 2, linestyle = :dash, label = "down, RRTMGP")
axislegend(ax1; position = :lt, framevisible = false)

ax2 = Axis(fig[1, 2]; xlabel = "Δ flux, ecCKD − RRTMGP (W m⁻²)",
           ylabel = "pressure (hPa)", yreversed = true, title = "Flux difference")
vlines!(ax2, [0.0]; color = (:black, 0.4), linestyle = :dash)
lines!(ax2, ecckd_fluxes.longwave_up .- rrtmgp_fluxes.longwave_up, p_i ./ 100;
       color = :firebrick, linewidth = 2, label = "up")
lines!(ax2, ecckd_fluxes.longwave_down .- rrtmgp_fluxes.longwave_down, p_i ./ 100;
       color = :steelblue4, linewidth = 2, label = "down")
axislegend(ax2; position = :rb, framevisible = false)

ax3 = Axis(fig[1, 3]; xlabel = "Δ heating rate, ecCKD − RRTMGP (K day⁻¹)",
           ylabel = "pressure (hPa)", yreversed = true, title = "Heating difference")
vlines!(ax3, [0.0]; color = (:black, 0.4), linestyle = :dash)
lines!(ax3, (heating_ecckd .- heating_rrtmgp) .* 86400, p_layers ./ 100;
       color = :darkorange3, linewidth = 2)

save("rrtmgp_comparison.png", fig); nothing #hide

# ![ecCKD vs RRTMGP comparison](rrtmgp_comparison.png)

# The printed OLR values and the difference panels above are the result: on
# this one idealized clear-sky column, with matched pressures, temperatures,
# and treated-gas composition, the two implementations differ by the amounts
# shown. This experiment does not separate the gas-optics tables from the
# transfer implementations — each leg uses both as a whole — and nothing here
# ranks either implementation or measures an error against a reference; a
# line-by-line benchmark would be required for that.
