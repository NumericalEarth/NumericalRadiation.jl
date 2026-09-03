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
# per-gas **dry-air volume mixing ratios** ``χ`` (RRTMGP's native convention,
# established by its `compute_col_gas_kernel!`). RRTMGP consumes the mixing
# ratios directly; the ecCKD path consumes **layer molar amounts in
# mol m⁻²**, so the conversion between the two representations is written out
# explicitly below and cross-checked against RRTMGP's own column computation.

using NumericalRadiation
using NCDatasets     # NetCDF reader extension (ecCKD files)
using ClimaComms     # RRTMGP adapter extension trigger …
using RRTMGP         # … and RRTMGP itself
using Printf

# The column: ``N`` layers with interface pressures ``pᵢ`` (Pa, top of
# atmosphere first), layer pressures ``p``, an idealized capped lapse rate,
# and analytic moisture and ozone mixing-ratio profiles:

N  = 48
pᵢ = collect(range(2_000, 101_325; length = N + 1))
p  = 0.5 .* (pᵢ[1:end-1] .+ pᵢ[2:end])

Tₛ = 300
T  = clamp.(Tₛ .- 65 .* (1 .- (p ./ 101_325) .^ 0.286), 200, Tₛ)
Tᵢ = clamp.(Tₛ .- 65 .* (1 .- (pᵢ ./ 101_325) .^ 0.286), 200, Tₛ)

χH₂O = @. 0.015 * (p / 101_325)^3 + 3e-6      # moist below, dry aloft
χO₃  = @. 3e-8 + 5e-6 * (2_000 / p)           # crude ozone increase aloft
χCO₂ = 420e-6
χCH₄ = 1.8e-6
χN₂O = 330e-9
nothing #hide

# The hydrostatic relation gives the dry-air molar amount ``nᵈ`` of each
# layer. With ``χ`` relative to dry air, the layer's mass per area is
# ``nᵈ (m^d + χ_{H₂O}\, m^v)``, so (dry-air molar-mass convention, matching
# RRTMGP):

g  = 9.80665         # m s⁻²
mᵈ = 0.028964        # kg mol⁻¹
mᵛ = 0.018016        # kg mol⁻¹

dry_air_amounts(χH₂O, pᵢ) =
    [(pᵢ[k + 1] - pᵢ[k]) / (g * (mᵈ + mᵛ * χH₂O[k])) for k in 1:(length(pᵢ) - 1)]

nᵈ = dry_air_amounts(χH₂O, pᵢ)                # mol m⁻²
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
    pressure_layers = p,
    pressure_interfaces = pᵢ,
    temperature_layers = T,
    temperature_interfaces = Tᵢ,
    gases = (composite = nᵈ,
             h2o = χH₂O .* nᵈ,
             o3 = χO₃ .* nᵈ,
             co2 = χCO₂ .* nᵈ,
             ch4 = χCH₄ .* nᵈ,
             n2o = χN₂O .* nᵈ,
             cfc11 = 0,
             cfc12 = 0),
    surface = (temperature = Tₛ,),
    geometry = (cos_zenith = 0.5,))

rrtmgp_atmosphere = ColumnAtmosphere(;
    pressure_layers = p,
    pressure_interfaces = pᵢ,
    temperature_layers = T,
    temperature_interfaces = Tᵢ,
    gases = (h2o = χH₂O, o3 = χO₃, co2 = χCO₂,
             ch4 = χCH₄, n2o = χN₂O,
             o2 = 0.20946, n2 = 0.78084, co = 0),
    surface = (temperature = Tₛ,),
    geometry = (cos_zenith = 0.5,))
nothing #hide

# ## RRTMGP leg
#
# The adapter types live in the `NumericalRadiationRRTMGPExt` package
# extension:

rrtmgp_extension = Base.get_extension(NumericalRadiation, :NumericalRadiationRRTMGPExt)
rrtmgp_model = rrtmgp_extension.RRTMGPClearSkyModel(Float64)
rrtmgp_boundary = rrtmgp_extension.RRTMGPBoundaryConditions(
    surface_temperature = Tₛ,
    surface_emissivity = 1,
    surface_albedo = 0,
    toa_shortwave_down = 0,   # longwave-only page
    cos_zenith = 0.5)
workspace = radiation_workspace(rrtmgp_model, rrtmgp_atmosphere)
rrtmgp_fluxes = RadiativeFluxes(longwave_up = zeros(N + 1),
                                longwave_down = zeros(N + 1),
                                shortwave_up = zeros(N + 1),
                                shortwave_down = zeros(N + 1))
radiative_fluxes!(rrtmgp_fluxes, rrtmgp_model, rrtmgp_atmosphere,
                  rrtmgp_boundary, workspace)
nothing #hide

# Before using the fluxes, verify the representation bridge: the dry-air
# amounts computed by `dry_air_amounts` must equal the dry column RRTMGP
# itself computed from the same pressures and mixing ratios (RRTMGP stores
# molecules cm⁻², and its levels are bottom-up, hence the unit factor with
# Avogadro's number ``Nᴬ`` and the index reversal):

Nᴬ = 6.02214076e23

molecular_column_rrtmgp = reverse(workspace.atmospheric_state.layerdata[1, :, 1])
molecular_column_ecckd = nᵈ .* Nᴬ ./ 1e4
relative_error = maximum(abs.(molecular_column_rrtmgp .- molecular_column_ecckd) ./
                         molecular_column_ecckd)
@assert relative_error < 1e-6
relative_error

# ## ecCKD leg

intended_gases = (:composite, :h2o, :o3, :co2, :ch4, :n2o, :cfc11, :cfc12)
gas_optics = read_official_ecckd_gas_optics("32x32"; gas_names = intended_gases)
@assert NumericalRadiation.gas_names(gas_optics) == intended_gases

longwave_gpoints = length(gas_optics.longwave_weights)
shortwave_gpoints = length(gas_optics.shortwave_weights)
longwave = LongwaveOpticalProperties(zeros(longwave_gpoints, N), zeros(longwave_gpoints, N);
                                     source_top = zeros(longwave_gpoints, N),
                                     source_bottom = zeros(longwave_gpoints, N),
                                     weights = zeros(longwave_gpoints))
shortwave = ShortwaveOpticalProperties(zeros(shortwave_gpoints, N);
                                       weights = zeros(shortwave_gpoints))
ecckd_fluxes = RadiativeFluxes(longwave_up = zeros(N + 1),
                               longwave_down = zeros(N + 1),
                               shortwave_up = zeros(N + 1),
                               shortwave_down = zeros(N + 1))
optical_properties!(longwave, shortwave, gas_optics, ecckd_atmosphere)
σ = 5.670374419e-8
radiative_fluxes!(ecckd_fluxes, CloudlessLongwave(), longwave, ecckd_atmosphere,
                  LongwaveBoundaryConditions(surface_longwave_up = σ * Tₛ^4))
nothing #hide

# ## Longwave-only heating rates
#
# With a zero shortwave boundary the returned shortwave fluxes are zero, so
# `heating_rates!` (which differences the total net flux) sees longwave only:

@assert all(iszero, rrtmgp_fluxes.shortwave_up)
@assert all(iszero, rrtmgp_fluxes.shortwave_down)

ecckd_heating = zeros(N)
rrtmgp_heating = zeros(N)
heating_rates!(ecckd_heating, ecckd_fluxes, ecckd_atmosphere;
               gravity = g, heat_capacity = 1004)
heating_rates!(rrtmgp_heating, rrtmgp_fluxes, rrtmgp_atmosphere;
               gravity = g, heat_capacity = 1004)

@printf("OLR, ecCKD 32×32:   %7.2f W m⁻²\n", ecckd_fluxes.longwave_up[1])
@printf("OLR, RRTMGP:        %7.2f W m⁻²\n", rrtmgp_fluxes.longwave_up[1])
@printf("ΔOLR (ecCKD − RRTMGP): %+6.2f W m⁻²\n",
        ecckd_fluxes.longwave_up[1] - rrtmgp_fluxes.longwave_up[1])

# ## The comparison, panel by panel
#
# Left: both flux profiles. Middle: the signed flux differences. Right: the
# signed heating-rate difference. Units are homogeneous within each panel,
# and the shared legend encodes direction by color and model by line style.

using CairoMakie

fig = Figure(size = (1000, 460))

pressure_ticks = [20, 50, 100, 200, 300, 500, 700, 1000]

ax1 = Axis(fig[1, 1]; xlabel = "Longwave flux (W m⁻²)",
           ylabel = "Pressure (hPa)", yscale = log10, yreversed = true,
           yticks = (pressure_ticks, string.(pressure_ticks)), title = "Fluxes")
lines!(ax1, ecckd_fluxes.longwave_up, pᵢ ./ 100;
       color = :firebrick, linewidth = 2)
lines!(ax1, rrtmgp_fluxes.longwave_up, pᵢ ./ 100;
       color = :firebrick, linewidth = 2, linestyle = :dash)
lines!(ax1, ecckd_fluxes.longwave_down, pᵢ ./ 100;
       color = :steelblue4, linewidth = 2)
lines!(ax1, rrtmgp_fluxes.longwave_down, pᵢ ./ 100;
       color = :steelblue4, linewidth = 2, linestyle = :dash)

ax2 = Axis(fig[1, 2]; xlabel = "Δ flux, ecCKD − RRTMGP (W m⁻²)",
           ylabel = "Pressure (hPa)", yscale = log10, yreversed = true,
           yticks = (pressure_ticks, string.(pressure_ticks)), title = "Flux difference")
vlines!(ax2, [0]; color = (:black, 0.4), linestyle = :dash)
lines!(ax2, ecckd_fluxes.longwave_up .- rrtmgp_fluxes.longwave_up, pᵢ ./ 100;
       color = :firebrick, linewidth = 2)
lines!(ax2, ecckd_fluxes.longwave_down .- rrtmgp_fluxes.longwave_down, pᵢ ./ 100;
       color = :steelblue4, linewidth = 2)

ax3 = Axis(fig[1, 3]; xlabel = "ΔṪ, ecCKD − RRTMGP (K day⁻¹)",
           ylabel = "Pressure (hPa)", yscale = log10, yreversed = true,
           yticks = (pressure_ticks, string.(pressure_ticks)), title = "Heating difference")
vlines!(ax3, [0]; color = (:black, 0.4), linestyle = :dash)
lines!(ax3, (ecckd_heating .- rrtmgp_heating) .* 86_400, p ./ 100;
       color = :darkorange3, linewidth = 2)

legend_entries = [LineElement(color = :firebrick, linewidth = 2),
                  LineElement(color = :steelblue4, linewidth = 2),
                  LineElement(color = :gray30, linewidth = 2, linestyle = :solid),
                  LineElement(color = :gray30, linewidth = 2, linestyle = :dash)]
Legend(fig[2, 1:3], legend_entries, ["up", "down", "ecCKD", "RRTMGP"];
       orientation = :horizontal, framevisible = false)

save("rrtmgp_comparison.png", fig); nothing #hide

# ![ecCKD vs RRTMGP comparison](rrtmgp_comparison.png)

# The printed OLR values and the difference panels above are the result: on
# this one idealized clear-sky column, with matched pressures, temperatures,
# and treated-gas composition, the two implementations differ by the amounts
# shown. This experiment does not separate the gas-optics tables from the
# transfer implementations — each leg uses both as a whole — and nothing here
# ranks either implementation or measures an error against a reference; a
# line-by-line benchmark would be required for that.
