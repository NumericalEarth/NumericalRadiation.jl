using NumericalRadiation

nlayers = 32
grid = ColumnGrid(collect(range(0.0, 1.0, length = nlayers + 1)))

profile = AtmosphereProfile(
    temperature = collect(range(215.0, 295.0, length = nlayers)),
    humidity = [0.018 * exp(-z / 2.0) for z in range(0.0, 8.0, length = nlayers)],
    geopotential = zeros(nlayers),
    surface_pressure = 100_000.0,
    CO₂ = 420.0,
)

surface = SurfaceState(
    sea_surface_temperature = 295.0,
    land_surface_temperature = 288.0,
    land_fraction = 0.25,
    ocean_albedo = 0.07,
    land_albedo = 0.22,
    cos_zenith = 0.5,
)

rtm = RadiativeTransferColumn(; grid, profile, surface)

elapsed = @elapsed radiative_heating!(rtm)

heating = similar(rtm.temperature_tendency)
heating_rates!(heating, rtm)

surface_lw_net = rtm.longwave_diagnostics.surface_longwave_down -
                 rtm.longwave_diagnostics.surface_longwave_up
surface_sw_net = rtm.shortwave_diagnostics.surface_shortwave_down -
                 rtm.shortwave_diagnostics.surface_shortwave_up
toa_net = rtm.shortwave_diagnostics.outgoing_shortwave +
          rtm.longwave_diagnostics.outgoing_longwave
column_integrated_heating = sum(heating .* grid.σ_thick) *
                            profile.surface_pressure *
                            rtm.physical_constants.heat_capacity /
                            rtm.physical_constants.gravity
toa_down = rtm.physical_constants.solar_constant * surface.cos_zenith
top_net_down = toa_down - toa_net
surface_net_down = surface_lw_net + surface_sw_net
energy_closure_residual = column_integrated_heating - (top_net_down - surface_net_down)

println("Analytic column metrics")
println("surface flux LW net: $(round(surface_lw_net, digits = 6)) W m^-2")
println("surface flux SW net: $(round(surface_sw_net, digits = 6)) W m^-2")
println("TOA flux outgoing: $(round(toa_net, digits = 6)) W m^-2")
println("column-integrated heating: $(round(column_integrated_heating, digits = 6)) W m^-2")
println("energy closure residual: $(round(energy_closure_residual, digits = 6)) W m^-2")
println("runtime: $(round(1e3 * elapsed, digits = 6)) ms")
