# # The staged interface: an ecCKD column, call by call
#
# One radiation update in this package is *staged*: it is split into three
# explicit calls on caller-owned arrays — [`optical_properties!`](@ref)
# fills the g-point optics, [`radiative_fluxes!`](@ref) solves each stream's
# transport, and [`heating_rates!`](@ref) converts the flux convergence into
# a temperature tendency. Nothing is hidden inside a monolithic solver, and
# a host model can own, reuse, or replace any stage. This tutorial runs the
# three stages end-to-end on a tiny synthetic tabulated gas-optics model, so
# the documentation build needs no NetCDF data — but these are exactly the
# calls used by reference ecCKD models loaded with
# `read_reference_ecckd_gas_optics`.

using CairoMakie
using NumericalRadiation

day = 86_400         # s

# ## A top-down column
#
# The ``Nz``-layer column has interface pressures ``pᵢ`` increasing from top
# of atmosphere to surface, layer pressures ``p`` at their midpoints, and
# layer and interface temperatures ``T`` and ``Tᵢ``. Gas values in this
# minimal staged model are layer path amounts. The column carries the
# physical constants the later stages read (gravity and heat capacity for
# the heating rates; the solar constant for the shortwave boundary).

constants = PhysicalConstants()
S₀ = constants.solar_constant   # solar constant, W m⁻²
μ₀ = 0.55                       # cosine of the solar zenith angle
Nz = 24
pᵢ = collect(range(10_000, 100_000; length = Nz + 1))
p  = 0.5 .* (pᵢ[1:end-1] .+ pᵢ[2:end])
T  = collect(range(220, 295; length = Nz))
Tᵢ = collect(range(215, 300; length = Nz + 1))

atmosphere = ColumnAtmosphere(;
    pressure_layers = p,
    pressure_interfaces = pᵢ,
    temperature_layers = T,
    temperature_interfaces = Tᵢ,
    gases = (
        h2o = collect(range(0.2, 2.2; length = Nz)),
        co2 = fill(1, Nz),
    ),
    surface = (temperature = Tᵢ[end],),
    geometry = (cos_zenith = μ₀,),
    constants,
)

# ## A small tabulated gas-optics model
#
# The element type is chosen once. The constructor stores the grids exactly
# as given (it does not convert them), so they are built as `FT` vectors:

FT = Float64
pressure_grid = FT[10_000, 100_000]
temperature_grid = FT[220, 300]
names = (:h2o, :co2)

function synthetic_absorption(Ngpoints, Ngases, pressure_grid, temperature_grid; scale)
    table = zeros(FT, Ngpoints, Ngases, length(pressure_grid), length(temperature_grid))
    for gpoint in 1:Ngpoints, j in 1:Ngases, iᵖ in eachindex(pressure_grid), iᵀ in eachindex(temperature_grid)
        pressure_factor = pressure_grid[iᵖ] / maximum(pressure_grid)
        temperature_factor = temperature_grid[iᵀ] / maximum(temperature_grid)
        table[gpoint, j, iᵖ, iᵀ] = scale * gpoint * (0.7 + 0.5 * j) * (0.4 + pressure_factor) * (0.8 + 0.3 * temperature_factor)
    end
    return table
end

model = EcCKDTabulatedGasOpticsModel(;
    names,
    pressure_grid = pressure_grid,
    temperature_grid = temperature_grid,
    longwave_absorption = synthetic_absorption(2, 2, pressure_grid, temperature_grid; scale = 0.010),
    shortwave_absorption = synthetic_absorption(2, 2, pressure_grid, temperature_grid; scale = 0.006),
    shortwave_rayleigh_molar_scattering = [1e-7, 2e-7],
    longwave_weights = [0.45, 0.55],
    shortwave_weights = [0.55, 0.45],
)

# ## Caller-owned work arrays

longwave = LongwaveOptics(
    zeros(2, Nz),
    zeros(2, Nz);
    source_top = zeros(2, Nz),
    source_bottom = zeros(2, Nz),
    weights = zeros(2),
)

shortwave = ShortwaveOptics(
    zeros(2, Nz);
    rayleigh_optical_depth = zeros(2, Nz),
    scattering_asymmetry = zeros(2, Nz),
    weights = zeros(2),
)

optical_properties!(longwave, shortwave, model, atmosphere)

fluxes = RadiativeFluxes(
    longwave_up = zeros(Nz + 1),
    longwave_down = zeros(Nz + 1),
    shortwave_up = zeros(Nz + 1),
    shortwave_down = zeros(Nz + 1),
)

radiative_fluxes!(
    fluxes,
    CloudlessLongwave(),
    longwave,
    atmosphere,
    LongwaveBoundaryConditions(
        surface_longwave_up = surface_longwave_emission(model,
                                                        atmosphere.surface.temperature),
        surface_albedo = 0,
    ),
)

radiative_fluxes!(
    fluxes,
    CloudlessShortwave(),
    shortwave,
    atmosphere,
    ShortwaveBoundaryConditions(
        toa_shortwave_down = S₀ * μ₀,
        surface_albedo = 0.15,
    ),
)

Ṫ = zeros(Nz)
heating_rates!(Ṫ, fluxes, atmosphere)     # gravity and heat capacity from atmosphere.constants
daily_heating_rate = day .* Ṫ

net_flux = fluxes.longwave_down .- fluxes.longwave_up .+
           fluxes.shortwave_down .- fluxes.shortwave_up

println("TOA net flux:     ", round(net_flux[1]; digits = 3), " W m⁻²")
println("Surface net flux: ", round(net_flux[end]; digits = 3), " W m⁻²")
println("Heating range:    ",
        round(minimum(daily_heating_rate); digits = 3), " to ",
        round(maximum(daily_heating_rate); digits = 3), " K day⁻¹")

# ## Visualization

fig = Figure(size = (900, 420))

ax_flux = Axis(fig[1, 1],
               xlabel = "Net downward flux (W m⁻²)",
               ylabel = "Pressure (hPa)",
               title = "Interface flux")
lines!(ax_flux, net_flux, pᵢ ./ 100; linewidth = 2)
scatter!(ax_flux, net_flux, pᵢ ./ 100; markersize = 5)
ax_flux.yreversed = true

ax_heat = Axis(fig[1, 2],
               xlabel = "Heating rate (K day⁻¹)",
               ylabel = "Pressure (hPa)",
               title = "Layer heating")
lines!(ax_heat, daily_heating_rate, p ./ 100; linewidth = 2)
scatter!(ax_heat, daily_heating_rate, p ./ 100; markersize = 5)
vlines!(ax_heat, [0]; color = (:gray50, 0.5), linestyle = :dash)
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

# Reference ecCKD files can be used in the same staged calls once available. The
# only replacement is the `model = ...` block above; the atmosphere, work arrays,
# fluxes, boundary conditions, and heating conversion stay the same.
