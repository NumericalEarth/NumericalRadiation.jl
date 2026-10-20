# # ecCKD model selection on a column
#
# Selects one of the reference ecCKD model pairs, loads its gas optics, and runs
# a single clear-sky column through the staged runtime, reporting the runtime
# g-point counts, the net fluxes, and the heating-rate range.

using NumericalRadiation
using NCDatasets

constants = PhysicalConstants()
S₀ = constants.solar_constant   # solar constant, W m⁻²
μ₀ = 0.55                       # cosine of the solar zenith angle

model_name = get(ENV, "ECCKD_MODEL", "32x32")
spec = reference_ecckd_model_spec(model_name)
paths = reference_ecckd_definition_paths(spec)

println("Selected ecCKD model: ", spec.name)
println("  LW: ", basename(paths.longwave))
println("  SW: ", basename(paths.shortwave))

gas_optics = read_reference_ecckd_gas_optics(spec; names=(:dry_air, :H₂O, :CO₂), water_vapor_mole_fraction=0.005)

Nz = 24
interface_pressures = collect(range(10_000.0, 100_000.0; length=Nz + 1))
layer_pressures = 0.5 .* (interface_pressures[1:end-1] .+ interface_pressures[2:end])
layer_temperatures = collect(range(220.0, 295.0; length=Nz))
interface_temperatures = collect(range(215.0, 300.0; length=Nz + 1))
air_column = hydrostatic_air_moles.(diff(interface_pressures), constants.gravity, constants.dry_air_molar_mass)

atmosphere = ColumnAtmosphere(;
    layer_pressures = layer_pressures,
    interface_pressures = interface_pressures,
    layer_temperatures = layer_temperatures,
    interface_temperatures = interface_temperatures,
    gases = (
        dry_air = air_column,
        H₂O = collect(range(0.002, 0.015; length=Nz)) .* air_column,
        CO₂ = fill(420.0e-6, Nz) .* air_column,
    ),
    surface = (temperature=interface_temperatures[end],),
    geometry = (cos_zenith=μ₀,),
    constants,
)

Ngˡʷ = length(gas_optics.longwave_weights)
Ngˢʷ = length(gas_optics.shortwave_weights)

longwave = LongwaveOptics(
    zeros(Ngˡʷ, Nz),
    zeros(Ngˡʷ, Nz);
    source_top = zeros(Ngˡʷ, Nz),
    source_bottom = zeros(Ngˡʷ, Nz),
    weights = zeros(Ngˡʷ),
)

shortwave = ShortwaveOptics(
    zeros(Ngˢʷ, Nz);
    rayleigh_optical_depth = zeros(Ngˢʷ, Nz),
    scattering_asymmetry = zeros(Ngˢʷ, Nz),
    weights = zeros(Ngˢʷ),
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
        toa_shortwave_down = S₀ * μ₀,
        surface_albedo = 0.15,
    ),
)

heating = zeros(Nz)
heating_rates!(heating, fluxes, atmosphere)

net_flux = fluxes.longwave_down .- fluxes.longwave_up .+ fluxes.shortwave_down .- fluxes.shortwave_up

println("Runtime g-points: ", Ngˡʷ, " LW, ", Ngˢʷ, " SW")
println("TOA net flux:     ", round(net_flux[1]; digits=3), " W m^-2")
println("Surface net flux: ", round(net_flux[end]; digits=3), " W m^-2")
println("Heating range:    ",
        round(86_400 * minimum(heating); digits=3), " to ",
        round(86_400 * maximum(heating); digits=3), " K day^-1")
