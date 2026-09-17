# # Analytic band column
#
# A single-column run of the analytic Williams band radiation model. It reports
# the top-of-atmosphere and surface net fluxes, the column-integrated heating,
# and the energy-closure residual as a consistency check.

using NumericalRadiation

Nz = 32
grid = ColumnGrid(collect(range(0.0, 1.0, length = Nz + 1)))

profile = AtmosphereProfile(
    temperature = collect(range(215.0, 295.0, length = Nz)),
    humidity = [0.018 * exp(-z / 2.0) for z in range(0.0, 8.0, length = Nz)],
    geopotential = zeros(Nz),
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

column = RadiativeTransferColumn(; grid, profile, surface)

elapsed = @elapsed radiative_heating!(column)

heating = similar(column.temperature_tendency)
heating_rates!(heating, column)

surface_lw_net = column.longwave_diagnostics.surface_longwave_down -
                 column.longwave_diagnostics.surface_longwave_up
surface_sw_net = column.shortwave_diagnostics.surface_shortwave_down -
                 column.shortwave_diagnostics.surface_shortwave_up
toa_net = column.shortwave_diagnostics.outgoing_shortwave +
          column.longwave_diagnostics.outgoing_longwave
column_integrated_heating = sum(heating .* grid.σ_thick) *
                            profile.surface_pressure *
                            column.physical_constants.heat_capacity /
                            column.physical_constants.gravity
toa_down = column.physical_constants.solar_constant * surface.cos_zenith
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
