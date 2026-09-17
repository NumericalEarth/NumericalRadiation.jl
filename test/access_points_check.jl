using NumericalRadiation
using Dates

# Reports go to NUMERICAL_RADIATION_VALIDATION_RESULTS_DIR when set (the test
# harness points it at a temporary directory), otherwise to a fresh temporary
# directory.
function validation_results_dir()
    return normpath(get(ENV, "NUMERICAL_RADIATION_VALIDATION_RESULTS_DIR") do
        mktempdir()
    end)
end

const REQUIRED_EXPORTS = (
    :AbstractAtmosphericState,
    :AbstractGasOpticsModel,
    :AbstractCloudOpticsModel,
    :AbstractAerosolOpticsModel,
    :AbstractRadiativeTransferSolver,
    :AbstractRadiationBackend,
    :ColumnAtmosphere,
    :RadiativeFluxes,
    :LongwaveOptics,
    :ShortwaveOptics,
    :ShortwaveCloudOverlapOptics,
    :CloudOptics,
    :CloudyRegionCloudOptics,
    :AerosolOptics,
    :CloudScatteringTable,
    :EcCKDSpectralMapping,
    :EcCKDGasOpticsModel,
    :LayerCloudOpticsModel,
    :LayerLiquidIceCloudOpticsModel,
    :LayerAerosolOpticsModel,
    :CloudlessLongwave,
    :CloudlessShortwave,
    :CloudOverlapShortwave,
    :optical_properties!,
    :cloud_optical_properties!,
    :cloudy_region_optical_properties!,
    :aerosol_optical_properties!,
    :read_cloud_scattering_table,
    :read_ecckd_spectral_mapping,
    :cloud_scattering_properties,
    :cloud_scattering_gpoint_properties,
    :radiative_fluxes!,
    :heating_rates!,
    :radiative_heating!,
    :radiation_workspace,
    :add_mapped_cloud_scattering!,
    :GasOpticsStencil,
    :gas_optics_stencil,
    :layer_gases,
    :gas_names,
    :longwave_optical_depth,
    :shortwave_optical_depth,
    :h2o_table_optical_depth,
    :rayleigh_optical_depth,
    :longwave_source,
    :source_table_bracket,
    :TabulatedSurfaceEmission,
    :streaming_longwave_fluxes!,
    :ShortwaveColumnScratch,
    :streaming_shortwave_fluxes!,
    :SpectralCloudOptics,
    :effective_radius_bracket,
    :cloud_layer_optics,
    :add_scattering_layer,
    :add_cloud_scattering_layer,
    :cloud_absorption_optical_depth,
    :ecrad_test_file,
)

function exported_symbol_status(name)
    names = Base.names(NumericalRadiation)
    return (
        name = string(name),
        exported = name in names,
        defined = isdefined(NumericalRadiation, name),
    )
end

# Layer-optics functors over precomputed `(ng, nlayers)` matrices, in the
# `(ig, k)` form a host kernel hands to the streaming solvers: longwave
# `(τ, B_top, B_bottom)` and shortwave `(τ_absorption, τ_scattering, asymmetry)`.
struct LongwaveMatrixOptics{L}
    optics :: L
end

(layer::LongwaveMatrixOptics)(ig, k) = (layer.optics.optical_depth[ig, k],
                                        layer.optics.source_top[ig, k],
                                        layer.optics.source_bottom[ig, k])

struct ShortwaveMatrixOptics{S}
    optics :: S
end

(layer::ShortwaveMatrixOptics)(ig, k) = (layer.optics.optical_depth[ig, k],
                                         layer.optics.rayleigh_optical_depth[ig, k],
                                         layer.optics.scattering_asymmetry[ig, k])

# The streaming (kernel-facing) solvers against the array solvers on the same
# optics. The array longwave solver streams each g point through
# `streaming_longwave_fluxes!` when interface Planck sources are present, and
# the array shortwave solver through the same adding step as
# `streaming_shortwave_fluxes!` for every g point that scatters, so both
# comparisons are bitwise.
function streaming_matches_array(gas_model, atmosphere, cloud, aerosol)
    nlayers = length(atmosphere.temperature_layers)
    ng_lw, ng_sw = length(gas_model.longwave_weights), length(gas_model.shortwave_weights)
    longwave = LongwaveOptics(zeros(ng_lw, nlayers), zeros(ng_lw, nlayers);
                              source_top = zeros(ng_lw, nlayers),
                              source_bottom = zeros(ng_lw, nlayers),
                              weights = zeros(ng_lw))
    shortwave = ShortwaveOptics(zeros(ng_sw, nlayers); weights = zeros(ng_sw))
    optical_properties!(longwave, shortwave, gas_model, atmosphere)
    add_cloud_optical_depths!(longwave, shortwave, cloud)
    add_aerosol_optical_depths!(longwave, shortwave, aerosol)

    surface_temperature, emissivity, longwave_albedo = 295.0, 0.98, 0.02
    μ0, toa_irradiance, shortwave_albedo = 0.5, 680.5, 0.1
    surface_emission = TabulatedSurfaceEmission(gas_model, surface_temperature; emissivity)

    fluxes = RadiativeFluxes(longwave_up = zeros(nlayers + 1),
                             longwave_down = zeros(nlayers + 1),
                             shortwave_up = zeros(nlayers + 1),
                             shortwave_down = zeros(nlayers + 1))
    radiative_fluxes!(fluxes, CloudlessLongwave(), longwave, atmosphere,
                      LongwaveBoundaryConditions(surface_longwave_up = surface_emission,
                                                 surface_albedo = longwave_albedo))
    radiative_fluxes!(fluxes, CloudlessShortwave(), shortwave, atmosphere,
                      ShortwaveBoundaryConditions(toa_shortwave_down = toa_irradiance,
                                                  surface_albedo = shortwave_albedo))

    longwave_up, longwave_down = zeros(nlayers + 1), zeros(nlayers + 1)
    streaming_longwave_fluxes!(longwave_up, longwave_down, LongwaveMatrixOptics(longwave),
                               surface_emission, longwave_albedo, 0.0,
                               longwave.weights, ng_lw, nlayers, zeros(nlayers), zeros(nlayers))
    shortwave_up, shortwave_down = zeros(nlayers + 1), zeros(nlayers + 1)
    streaming_shortwave_fluxes!(shortwave_up, shortwave_down, ShortwaveMatrixOptics(shortwave),
                                μ0, toa_irradiance, shortwave_albedo, shortwave_albedo,
                                shortwave.weights, ng_sw, nlayers, ShortwaveColumnScratch(Float64, nlayers))

    return (
        streaming_longwave_matches_array = all(isfinite, longwave_up) &&
                                           !all(iszero, longwave_up) &&
                                           longwave_up == fluxes.longwave_up &&
                                           longwave_down == fluxes.longwave_down,
        streaming_shortwave_matches_array = all(isfinite, shortwave_up) &&
                                            !all(iszero, shortwave_up) &&
                                            shortwave_up == fluxes.shortwave_up &&
                                            shortwave_down == fluxes.shortwave_down,
    )
end

function component_smoke()
    atmosphere = ColumnAtmosphere(
        pressure_layers = [20_000.0, 70_000.0],
        pressure_interfaces = [1_000.0, 45_000.0, 100_000.0],
        temperature_layers = [240.0, 285.0],
        temperature_interfaces = [230.0, 260.0, 295.0],
        gases = (; h2o = [0.002, 0.014], co2 = 420.0e-6),
        surface = (; temperature = 295.0, albedo = 0.1),
        geometry = (; cos_zenith = 0.5),
    )
    gas_model = EcCKDGasOpticsModel(
        names = (:h2o, :co2),
        longwave_absorption = [0.08 0.004; 0.03 0.002],
        shortwave_absorption = [0.010 0.0008],
        longwave_source_scale = [1.0, 1.05],
        longwave_weights = [0.55, 0.45],
        shortwave_weights = [1.0],
    )
    cloud_model = LayerLiquidIceCloudOpticsModel(
        liquid_water_path = [0.015, 0.0],
        ice_water_path = [0.005, 0.0],
        cloud_fraction = [0.8, 0.0],
        liquid_longwave_mass_absorption = 0.1,
        ice_longwave_mass_absorption = 0.2,
        liquid_shortwave_mass_extinction = 0.2,
        ice_shortwave_mass_extinction = 0.3,
        liquid_shortwave_single_scattering_albedo = 0.8,
        ice_shortwave_single_scattering_albedo = 0.6,
        liquid_shortwave_scattering_asymmetry = 0.85,
        ice_shortwave_scattering_asymmetry = 0.75,
    )
    aerosol_model = LayerAerosolOpticsModel(aerosol_path = [0.01, 0.03],
                                            longwave_mass_absorption = 0.05,
                                            shortwave_mass_extinction = 0.1,
                                            shortwave_single_scattering_albedo = 0.7,
                                            shortwave_scattering_asymmetry = 0.6)
    longwave = LongwaveOptics(zeros(2, 2), zeros(2, 2); weights = zeros(2))
    shortwave = ShortwaveOptics(zeros(1, 2); weights = zeros(1))
    cloud = CloudOptics(zeros(2), zeros(2))
    cloudy_region_cloud = CloudyRegionCloudOptics(zeros(2), zeros(1),
                                                             zeros(2), zeros(2))
    aerosol = AerosolOptics(zeros(2), zeros(2))
    fluxes = RadiativeFluxes(
        longwave_up = zeros(3),
        longwave_down = zeros(3),
        shortwave_up = zeros(3),
        shortwave_down = zeros(3),
    )
    heating = zeros(2)

    optical_properties!(longwave, shortwave, gas_model, atmosphere)
    cloud_optical_properties!(cloud, cloud_model, atmosphere)
    cloudy_region_optical_properties!(cloudy_region_cloud, cloud_model,
                                      (; overlap_parameter = [0.8]))
    aerosol_optical_properties!(aerosol, aerosol_model, atmosphere)
    add_cloud_optical_depths!(longwave, shortwave, cloud)
    add_aerosol_optical_depths!(longwave, shortwave, aerosol)
    radiative_fluxes!(fluxes, CloudlessLongwave(), longwave, atmosphere,
                      LongwaveBoundaryConditions(surface_longwave_up = 5.670374419e-8 * 295.0^4))
    radiative_fluxes!(fluxes, CloudlessShortwave(), shortwave, atmosphere,
                      ShortwaveBoundaryConditions(toa_shortwave_down = 680.5, surface_albedo = 0.1))
    heating_rates!(heating, fluxes, atmosphere; gravity = 9.80665, heat_capacity = 1004.0)
    streaming = streaming_matches_array(gas_model, atmosphere, cloud, aerosol)

    return (
        optical_properties_callable = all(isfinite, longwave.optical_depth) &&
                                      all(isfinite, shortwave.optical_depth),
        cloud_optics_callable = all(isfinite, cloud.longwave_optical_depth) &&
                                all(isfinite, cloud.shortwave_optical_depth) &&
                                all(isfinite, cloud.shortwave_scattering_optical_depth) &&
                                all(isfinite, cloud.shortwave_scattering_asymmetry),
        cloudy_region_cloud_optics_callable =
            all(isfinite, cloudy_region_cloud.cloud_fraction) &&
            all(isfinite, cloudy_region_cloud.overlap_parameter) &&
            all(isfinite, cloudy_region_cloud.longwave_optical_depth) &&
            !all(iszero, cloudy_region_cloud.longwave_optical_depth),
        aerosol_optics_callable = all(isfinite, aerosol.longwave_optical_depth) &&
                                  all(isfinite, aerosol.shortwave_optical_depth) &&
                                  all(isfinite, aerosol.shortwave_scattering_optical_depth) &&
                                  all(isfinite, aerosol.shortwave_scattering_asymmetry) &&
                                  !all(iszero, aerosol.shortwave_optical_depth),
        solvers_callable = all(isfinite, fluxes.longwave_up) &&
                           all(isfinite, fluxes.shortwave_down),
        heating_rates_callable = all(isfinite, heating),
        host_can_stop_after_gas_optics = !all(iszero, longwave.optical_depth) &&
                                         !all(iszero, shortwave.optical_depth),
        host_can_replace_solver_or_vertical_integral = all(isfinite, heating),
        streaming...,
    )
end

function json_value(value)
    if value === nothing
        return "null"
    elseif value isa AbstractString
        return "\"" * replace(value, "\"" => "\\\"") * "\""
    elseif value isa Bool
        return value ? "true" : "false"
    elseif value isa NamedTuple
        return json_object(value)
    elseif value isa AbstractVector || value isa Tuple
        return "[" * join(json_value.(value), ", ") * "]"
    else
        return string(value)
    end
end

function json_object(result)
    names = propertynames(result)
    lines = ["{"]
    for (i, name) in enumerate(names)
        comma = i == length(names) ? "" : ","
        push!(lines, "  \"$(name)\": $(json_value(getproperty(result, name)))$(comma)")
    end
    push!(lines, "}")
    return join(lines, "\n")
end

function markdown_report(result)
    lines = String[
        "# Host-Model Access Points Check",
        "",
        "Status: **$(result.status)**",
        "",
        "| Symbol | Exported | Defined |",
        "|---|---:|---:|",
    ]
    for item in result.exports
        push!(lines, "| `$(item.name)` | $(item.exported) | $(item.defined) |")
    end
    append!(lines, [
        "",
        "## Component Smoke",
        "",
        "| Capability | Result |",
        "|---|---:|",
        "| Gas optical properties callable | $(result.component_smoke.optical_properties_callable) |",
        "| Cloud optical properties callable | $(result.component_smoke.cloud_optics_callable) |",
        "| Cloudy-region cloud optical properties callable | $(result.component_smoke.cloudy_region_cloud_optics_callable) |",
        "| Aerosol optical properties callable | $(result.component_smoke.aerosol_optics_callable) |",
        "| Solvers callable separately | $(result.component_smoke.solvers_callable) |",
        "| Heating rates callable separately | $(result.component_smoke.heating_rates_callable) |",
        "| Host can stop after gas optics | $(result.component_smoke.host_can_stop_after_gas_optics) |",
        "| Host can replace solver or vertical integral | $(result.component_smoke.host_can_replace_solver_or_vertical_integral) |",
        "| Streaming longwave equals the array solver | $(result.component_smoke.streaming_longwave_matches_array) |",
        "| Streaming shortwave equals the array solver | $(result.component_smoke.streaming_shortwave_matches_array) |",
    ])
    return join(lines, "\n") * "\n"
end

function main()
    export_status = [exported_symbol_status(name) for name in REQUIRED_EXPORTS]
    smoke = component_smoke()
    passed = all(item -> item.exported && item.defined, export_status) &&
             all(value -> value === true, values(smoke))
    result = (
        case = "host_model_access_points_check",
        date = string(Dates.now()),
        status = passed ? "passed" : "failed",
        passed = passed,
        exports = export_status,
        component_smoke = smoke,
    )

    results_dir = validation_results_dir()
    mkpath(results_dir)
    json_path = joinpath(results_dir, "access_points_check.json")
    md_path = joinpath(results_dir, "access_points_check.md")
    write(json_path, json_object(result))
    write(md_path, markdown_report(result))

    print(markdown_report(result))
    println("Wrote $json_path")
    println("Wrote $md_path")
    passed || error("host-model access point check failed")
end

main()
