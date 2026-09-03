using NumericalRadiation
using NCDatasets

const σ_SB = 5.670374419e-8

model_name = get(ENV, "ECCKD_MODEL", "32x32")
spec = official_ecckd_model_spec(model_name)
paths = official_ecckd_definition_paths(spec)

println("Selected ecCKD model: ", spec.name)
println("  LW: ", basename(paths.longwave))
println("  SW: ", basename(paths.shortwave))

gas_optics = read_official_ecckd_gas_optics(spec;
    gas_names = (:composite, :h2o, :co2),
    h2o_mole_fraction = 0.005,
)

nlayers = 24
pressure_interfaces = collect(range(10_000.0, 100_000.0; length = nlayers + 1))
pressure_layers = 0.5 .* (pressure_interfaces[1:end-1] .+ pressure_interfaces[2:end])
temperature_layers = collect(range(220.0, 295.0; length = nlayers))
temperature_interfaces = collect(range(215.0, 300.0; length = nlayers + 1))
air_column = (pressure_interfaces[2:end] .- pressure_interfaces[1:end-1]) ./ (9.80665 * 0.0289647)

atmosphere = ColumnAtmosphere(
    pressure_layers = pressure_layers,
    pressure_interfaces = pressure_interfaces,
    temperature_layers = temperature_layers,
    temperature_interfaces = temperature_interfaces,
    gases = (
        composite = air_column,
        h2o = collect(range(0.002, 0.015; length = nlayers)) .* air_column,
        co2 = fill(420.0e-6, nlayers) .* air_column,
    ),
    surface = (temperature = temperature_interfaces[end],),
    geometry = (cos_zenith = 0.55,),
)

ng_lw = length(gas_optics.longwave_weights)
ng_sw = length(gas_optics.shortwave_weights)

longwave = LongwaveOpticalProperties(
    zeros(ng_lw, nlayers),
    zeros(ng_lw, nlayers);
    source_top = zeros(ng_lw, nlayers),
    source_bottom = zeros(ng_lw, nlayers),
    weights = zeros(ng_lw),
)

shortwave = ShortwaveOpticalProperties(
    zeros(ng_sw, nlayers);
    rayleigh_optical_depth = zeros(ng_sw, nlayers),
    scattering_asymmetry = zeros(ng_sw, nlayers),
    weights = zeros(ng_sw),
)

optical_properties!(longwave, shortwave, gas_optics, atmosphere)

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
        surface_longwave_up = surface_longwave_emission(
            gas_optics, atmosphere.surface.temperature)),
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

net_flux = fluxes.longwave_down .- fluxes.longwave_up .+
           fluxes.shortwave_down .- fluxes.shortwave_up

println("Runtime g-points: ", ng_lw, " LW, ", ng_sw, " SW")
println("TOA net flux:     ", round(net_flux[1]; digits = 3), " W m^-2")
println("Surface net flux: ", round(net_flux[end]; digits = 3), " W m^-2")
println("Heating range:    ",
        round(86_400 * minimum(heating); digits = 3), " to ",
        round(86_400 * maximum(heating); digits = 3), " K day^-1")
