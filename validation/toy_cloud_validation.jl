include(joinpath(@__DIR__, "validation_results.jl"))

using NumericalRadiation
using Dates
using Printf

const REFERENCE_CLOUD_FLUX = [
    399.81806644681944,
    428.6162262826473,
    436.0181064274543,
    435.2898904673263,
    0.0,
    41.48704652779837,
    65.07475468790977,
    81.19095993416929,
    13.937238488556766,
    26.911784761399936,
    32.478043807932224,
    33.7359584860953,
    680.5,
    352.42147169170175,
    292.0216145883299,
    281.1329873841275,
]

const REFERENCE_CLOUD_HEATING_DAY = [
    79.17506832592838,
    10.502631307688977,
    -1.1327511652761317,
]

const REFERENCE_CLEAR_SURFACE_SHORTWAVE = 401.00657436265806
const REFERENCE_CLOUD_SURFACE_SHORTWAVE = 281.1329873841275

function cloud_case()
    nlayers = 3
    atmosphere = ColumnAtmosphere(
        pressure_layers = [12_000.0, 15_000.0, 19_000.0],
        pressure_interfaces = [10_000.0, 13_500.0, 17_500.0, 21_000.0],
        temperature_layers = [255.0, 275.0, 295.0],
        temperature_interfaces = [250.0, 265.0, 285.0, 300.0],
        gases = (
            h2o = [1.0, 2.0, 1.5],
            co2 = 4.0,
        ),
        surface = (; temperature = 296.0, albedo = 0.12),
        geometry = (; cos_zenith = 0.5),
    )

    gas_model = EcCKDGasOpticsModel(
        gas_names = (:h2o, :co2),
        longwave_absorption = [0.018 0.004;
                               0.012 0.006],
        shortwave_absorption = [0.020 0.002],
        longwave_source_scale = [1.0, 1.1],
        longwave_weights = [0.45, 0.55],
        shortwave_weights = [1.0],
    )
    cloud_model = LayerCloudOpticsModel(
        cloud_water_path = [0.18, 0.04, 0.0],
        longwave_mass_absorption = 0.8,
        shortwave_mass_extinction = 3.5,
    )

    longwave = LongwaveOpticalProperties(zeros(2, nlayers), zeros(2, nlayers);
                                         weights = zeros(2))
    shortwave = ShortwaveOpticalProperties(zeros(1, nlayers); weights = zeros(1))
    cloud = CloudOpticalProperties(zeros(nlayers), zeros(nlayers))
    fluxes = RadiativeFluxes(
        longwave_up = zeros(nlayers + 1),
        longwave_down = zeros(nlayers + 1),
        shortwave_up = zeros(nlayers + 1),
        shortwave_down = zeros(nlayers + 1),
    )
    heating = zeros(nlayers)

    optical_properties!(longwave, shortwave, gas_model, atmosphere)
    cloud_optical_properties!(cloud, cloud_model, atmosphere)
    add_cloud_optical_depths!(longwave, shortwave, cloud)
    radiative_fluxes!(
        fluxes,
        CloudlessLongwave(),
        longwave,
        atmosphere,
        LongwaveBoundaryConditions(
            surface_longwave_up = 5.670374419e-8 * atmosphere.surface.temperature^4,
        ),
    )
    radiative_fluxes!(
        fluxes,
        CloudlessShortwave(),
        shortwave,
        atmosphere,
        ShortwaveBoundaryConditions(
            toa_shortwave_down = 1361.0 * atmosphere.geometry.cos_zenith,
            surface_albedo = atmosphere.surface.albedo,
        ),
    )
    heating_rates!(heating, fluxes, atmosphere; gravity = 9.80665, heat_capacity = 1004.0)

    candidate_flux = vcat(fluxes.longwave_up,
                          fluxes.longwave_down,
                          fluxes.shortwave_up,
                          fluxes.shortwave_down)
    return (
        candidate_flux = candidate_flux,
        candidate_heating_day = heating .* 86_400,
        surface_shortwave_down = fluxes.shortwave_down[end],
    )
end

function rmse(a, b)
    return sqrt(sum(abs2, a .- b) / length(a))
end

function json_value(value)
    if value isa AbstractString
        return "\"" * replace(value, "\"" => "\\\"") * "\""
    elseif value isa Bool
        return value ? "true" : "false"
    elseif value isa NamedTuple
        return json_object(value)
    elseif value isa AbstractVector
        return "[" * join(json_value.(value), ", ") * "]"
    else
        return string(value)
    end
end

function json_object(result)
    fields = propertynames(result)
    lines = ["{"]
    for (i, name) in enumerate(fields)
        comma = i == length(fields) ? "" : ","
        push!(lines, "  \"$(name)\": $(json_value(getproperty(result, name)))$(comma)")
    end
    push!(lines, "}")
    return join(lines, "\n")
end

function markdown_report(result)
    return """
    # Toy Cloud Validation

    Status: **$(result.passed ? "pass" : "fail")**

    This deterministic fixture validates the absorptive cloud-optics scaffold.
    It is not an ecRad all-sky validation case and does not include scattering,
    cloud overlap, or microphysics coupling.

    | Metric | Value | Threshold |
    |---|---:|---:|
    | Flux RMSE | $(@sprintf("%.12g", result.flux_rmse)) | $(@sprintf("%.12g", result.flux_rmse_threshold)) |
    | Heating-rate RMSE | $(@sprintf("%.12g", result.heating_rate_rmse)) | $(@sprintf("%.12g", result.heating_rate_rmse_threshold)) |
    | Clear surface SW down | $(@sprintf("%.12g", result.clear_surface_shortwave_down)) | |
    | Cloudy surface SW down | $(@sprintf("%.12g", result.cloudy_surface_shortwave_down)) | |
    | Surface SW reduction | $(@sprintf("%.12g", result.surface_shortwave_reduction)) | > 0 |

    Errors: $(isempty(result.errors) ? "none" : join(result.errors, "; "))
    """
end

function main()
    candidate = cloud_case()
    flux_error = rmse(candidate.candidate_flux, REFERENCE_CLOUD_FLUX)
    heating_error = rmse(candidate.candidate_heating_day, REFERENCE_CLOUD_HEATING_DAY)
    surface_reduction = REFERENCE_CLEAR_SURFACE_SHORTWAVE - candidate.surface_shortwave_down
    flux_threshold = 1.0e-10
    heating_threshold = 1.0e-10
    errors = String[]
    flux_error <= flux_threshold ||
        push!(errors, "flux RMSE $(flux_error) exceeds $(flux_threshold)")
    heating_error <= heating_threshold ||
        push!(errors, "heating-rate RMSE $(heating_error) exceeds $(heating_threshold)")
    surface_reduction > 0 ||
        push!(errors, "cloudy surface shortwave is not below clear reference")

    result = (
        case = "toy_absorptive_cloud_column",
        date = string(Dates.now()),
        reference_kind = "stored deterministic toy fixture",
        passed = isempty(errors),
        flux_rmse = flux_error,
        flux_rmse_threshold = flux_threshold,
        heating_rate_rmse = heating_error,
        heating_rate_rmse_threshold = heating_threshold,
        clear_surface_shortwave_down = REFERENCE_CLEAR_SURFACE_SHORTWAVE,
        cloudy_surface_shortwave_down = candidate.surface_shortwave_down,
        reference_cloudy_surface_shortwave_down = REFERENCE_CLOUD_SURFACE_SHORTWAVE,
        surface_shortwave_reduction = surface_reduction,
        errors = errors,
    )

    results_dir = validation_results_dir()
    mkpath(results_dir)
    write(joinpath(results_dir, "toy_cloud_validation.json"), json_object(result))
    write(joinpath(results_dir, "toy_cloud_validation.md"), markdown_report(result))

    println("Toy cloud validation: $(result.passed ? "pass" : "fail")")
    println("flux RMSE: $(@sprintf("%.12g", flux_error))")
    println("heating-rate RMSE: $(@sprintf("%.12g", heating_error))")
    result.passed || error("toy cloud validation failed: " * join(errors, "; "))
end

main()
