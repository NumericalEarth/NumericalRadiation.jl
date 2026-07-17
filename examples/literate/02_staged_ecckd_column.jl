# # Staged ecCKD Column
#
# This tutorial runs the staged runtime API end-to-end. It uses a tiny
# synthetic tabulated gas-optics model so the documentation build does not need
# NetCDF data, but the staged calls are the same calls used by official ecCKD
# models loaded with `read_official_ecckd_gas_optics`.

using CairoMakie
using NumericalRadiation

const sigma_SB = 5.670374419e-8
const seconds_per_day = 86_400.0

# ## A top-down column
#
# Interface pressure increases from top of atmosphere to surface. Gas values in
# this minimal staged model are layer path amounts.

nlayers = 24
pressure_interfaces = collect(range(10_000.0, 100_000.0; length = nlayers + 1))
pressure_layers = 0.5 .* (pressure_interfaces[1:end-1] .+ pressure_interfaces[2:end])
temperature_layers = collect(range(220.0, 295.0; length = nlayers))
temperature_interfaces = collect(range(215.0, 300.0; length = nlayers + 1))

atmosphere = ColumnAtmosphere(
    pressure_layers = pressure_layers,
    pressure_interfaces = pressure_interfaces,
    temperature_layers = temperature_layers,
    temperature_interfaces = temperature_interfaces,
    gases = (
        h2o = collect(range(0.2, 2.2; length = nlayers)),
        co2 = fill(1.0, nlayers),
    ),
    surface = (temperature = temperature_interfaces[end],),
    geometry = (cos_zenith = 0.55,),
)

# ## A small tabulated gas-optics model

pressure_grid = [10_000.0, 100_000.0]
temperature_grid = [220.0, 300.0]
gas_names = (:h2o, :co2)

function synthetic_absorption(ng, ngas, pressure_grid, temperature_grid; scale)
    table = zeros(Float64, ng, ngas, length(pressure_grid), length(temperature_grid))
    for ig in 1:ng, j in 1:ngas, ip in eachindex(pressure_grid), it in eachindex(temperature_grid)
        pressure_factor = pressure_grid[ip] / maximum(pressure_grid)
        temperature_factor = temperature_grid[it] / maximum(temperature_grid)
        table[ig, j, ip, it] =
            scale * ig * (0.7 + 0.5j) * (0.4 + pressure_factor) *
            (0.8 + 0.3temperature_factor)
    end
    return table
end

model = EcCKDTabulatedGasOpticsModel(
    gas_names = gas_names,
    pressure_grid = pressure_grid,
    temperature_grid = temperature_grid,
    longwave_absorption = synthetic_absorption(2, 2, pressure_grid, temperature_grid; scale = 0.010),
    shortwave_absorption = synthetic_absorption(2, 2, pressure_grid, temperature_grid; scale = 0.006),
    shortwave_rayleigh_molar_scattering = [1.0e-7, 2.0e-7],
    longwave_weights = [0.45, 0.55],
    shortwave_weights = [0.55, 0.45],
)

# ## Caller-owned work arrays

longwave = LongwaveOpticalProperties(
    zeros(2, nlayers),
    zeros(2, nlayers);
    source_top = zeros(2, nlayers),
    source_bottom = zeros(2, nlayers),
    weights = zeros(2),
)

shortwave = ShortwaveOpticalProperties(
    zeros(2, nlayers);
    rayleigh_optical_depth = zeros(2, nlayers),
    scattering_asymmetry = zeros(2, nlayers),
    weights = zeros(2),
)

optical_properties!(longwave, shortwave, model, atmosphere)

fluxes = RadiativeFluxes(
    longwave_up = zeros(nlayers + 1),
    longwave_down = zeros(nlayers + 1),
    shortwave_up = zeros(nlayers + 1),
    shortwave_down = zeros(nlayers + 1),
)

radiative_fluxes!(
    fluxes,
    CloudlessLongwave(),
    longwave,
    atmosphere,
    LongwaveBoundaryConditions(
        surface_longwave_up = sigma_SB * atmosphere.surface.temperature^4,
        surface_albedo = 0.0,
    ),
)

radiative_fluxes!(
    fluxes,
    CloudlessShortwave(),
    shortwave,
    atmosphere,
    ShortwaveBoundaryConditions(
        toa_shortwave_down = 1361.0 * atmosphere.geometry.cos_zenith,
        surface_albedo = 0.15,
    ),
)

heating = zeros(nlayers)
heating_rates!(heating, fluxes, atmosphere; gravity = 9.80665, heat_capacity = 1004.0)
heating_day = seconds_per_day .* heating

net_flux = fluxes.longwave_down .- fluxes.longwave_up .+
           fluxes.shortwave_down .- fluxes.shortwave_up

println("TOA net flux:     ", round(net_flux[1]; digits = 3), " W m^-2")
println("Surface net flux: ", round(net_flux[end]; digits = 3), " W m^-2")
println("Heating range:    ",
        round(minimum(heating_day); digits = 3), " to ",
        round(maximum(heating_day); digits = 3), " K day^-1")

# ## Visualization

fig = Figure(size = (900, 420))

ax_flux = Axis(fig[1, 1],
    xlabel = "Net downward flux (W m^-2)",
    ylabel = "Pressure (hPa)",
    title = "Interface flux")
lines!(ax_flux, net_flux, pressure_interfaces ./ 100; linewidth = 2)
scatter!(ax_flux, net_flux, pressure_interfaces ./ 100; markersize = 5)
ax_flux.yreversed = true

ax_heat = Axis(fig[1, 2],
    xlabel = "Heating rate (K day^-1)",
    ylabel = "Pressure (hPa)",
    title = "Layer heating")
lines!(ax_heat, heating_day, pressure_layers ./ 100; linewidth = 2)
scatter!(ax_heat, heating_day, pressure_layers ./ 100; markersize = 5)
vlines!(ax_heat, [0.0]; color = (:gray50, 0.5), linestyle = :dash)
ax_heat.yreversed = true

function docs_asset_dir()
    repo_docs_src = normpath(joinpath(@__DIR__, "..", "..", "docs", "src"))
    path = if isdir(repo_docs_src)
        joinpath(repo_docs_src, "assets")
    else
        normpath(joinpath(@__DIR__, "..", "assets"))
    end
    mkpath(path)
    return path
end

save(joinpath(docs_asset_dir(), "staged_ecckd_column.png"), fig)

# The documentation build writes this image under `docs/src/assets`.
#
# ![Flux and heating diagnostics for the staged ecCKD column example](../assets/staged_ecckd_column.png)

# Official ecCKD files can be used in the same staged calls once available. The
# only replacement is the `model = ...` block above; the atmosphere, work arrays,
# fluxes, boundary conditions, and heating conversion stay the same.
