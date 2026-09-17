# # ecCKD model selection on a column
#
# Selects one of the reference ecCKD model pairs, loads its gas optics, and runs
# a single clear-sky column through the staged runtime, reporting the runtime
# g-point counts, the net fluxes, and the heating-rate range.

using NumericalRadiation
using NCDatasets

constants = PhysicalConstants()

model_name = get(ENV, "ECCKD_MODEL", "32x32")
spec = reference_ecckd_model_spec(model_name)
paths = reference_ecckd_definition_paths(spec)

println("Selected ecCKD model: ", spec.name)
println("  LW: ", basename(paths.longwave))
println("  SW: ", basename(paths.shortwave))

gas_optics = read_reference_ecckd_gas_optics(spec;
                                             names = (:composite, :h2o, :co2),
                                             water_vapor_mole_fraction = 0.005,
)

Nz = 24
pressure_interfaces = collect(range(10_000.0, 100_000.0; length = Nz + 1))
pressure_layers = 0.5 .* (pressure_interfaces[1:end-1] .+ pressure_interfaces[2:end])
temperature_layers = collect(range(220.0, 295.0; length = Nz))
temperature_interfaces = collect(range(215.0, 300.0; length = Nz + 1))
air_column = hydrostatic_air_moles.(diff(pressure_interfaces), constants.gravity, constants.dry_air_molar_mass)

atmosphere = ColumnAtmosphere(;
    pressure_layers = pressure_layers,
    pressure_interfaces = pressure_interfaces,
    temperature_layers = temperature_layers,
    temperature_interfaces = temperature_interfaces,
    gases = (
        composite = air_column,
        h2o = collect(range(0.002, 0.015; length = Nz)) .* air_column,
        co2 = fill(420.0e-6, Nz) .* air_column,
    ),
    surface = (temperature = temperature_interfaces[end],),
    geometry = (cos_zenith = 0.55,),
    constants,
)

Nlongwave_gpoints = length(gas_optics.longwave_weights)
Nshortwave_gpoints = length(gas_optics.shortwave_weights)

longwave = LongwaveOptics(
    zeros(Nlongwave_gpoints, Nz),
    zeros(Nlongwave_gpoints, Nz);
    source_top = zeros(Nlongwave_gpoints, Nz),
    source_bottom = zeros(Nlongwave_gpoints, Nz),
    weights = zeros(Nlongwave_gpoints),
)

shortwave = ShortwaveOptics(
    zeros(Nshortwave_gpoints, Nz);
    rayleigh_optical_depth = zeros(Nshortwave_gpoints, Nz),
    scattering_asymmetry = zeros(Nshortwave_gpoints, Nz),
    weights = zeros(Nshortwave_gpoints),
)

optical_properties!(longwave, shortwave, gas_optics, atmosphere)

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
        surface_longwave_up = surface_longwave_emission(
            gas_optics, atmosphere.surface.temperature)),
)

radiative_fluxes!(
    fluxes,
    CloudlessShortwave(),
    shortwave,
    atmosphere,
    ShortwaveBoundaryConditions(
        toa_shortwave_down = constants.solar_constant * atmosphere.geometry.cos_zenith,
        surface_albedo = 0.15,
    ),
)

heating = zeros(Nz)
heating_rates!(heating, fluxes, atmosphere)

net_flux = fluxes.longwave_down .- fluxes.longwave_up .+
           fluxes.shortwave_down .- fluxes.shortwave_up

println("Runtime g-points: ", Nlongwave_gpoints, " LW, ", Nshortwave_gpoints, " SW")
println("TOA net flux:     ", round(net_flux[1]; digits = 3), " W m^-2")
println("Surface net flux: ", round(net_flux[end]; digits = 3), " W m^-2")
println("Heating range:    ",
        round(86_400 * minimum(heating); digits = 3), " to ",
        round(86_400 * maximum(heating); digits = 3), " K day^-1")
