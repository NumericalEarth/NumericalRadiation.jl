include(joinpath(@__DIR__, "validation_results.jl"))

using NumericalRadiation
using Dates
using Printf

const REFERENCE_FLUX = [
    409.603597390974,
    426.6840071775796,
    437.83467672869256,
    435.2898904673263,
    0.0,
    25.466468757153145,
    63.77328698894907,
    108.28055731523656,
    28.356726997573666,
    33.127517648175974,
    40.09951686122467,
    48.120788923518965,
    680.5,
    582.4992058501363,
    481.2215765249881,
    401.00657436265806,
]

const REFERENCE_HEATING_DAY = [
    22.75820790507381,
    17.109079764626774,
    9.930325430182483,
]

const REFERENCE_TOA_FLUX = -242.5396756114523
const REFERENCE_SURFACE_FLUX = -25.876452287049325

function toy_case()
    nlayers = 3
    pressure_grid = [10_000.0, 20_000.0]
    temperature_grid = [250.0, 300.0]
    longwave_table = zeros(2, 2, 2, 2)
    shortwave_table = zeros(1, 2, 2, 2)

    for ig in axes(longwave_table, 1), j in axes(longwave_table, 2),
        ip in axes(longwave_table, 3), it in axes(longwave_table, 4)
        longwave_table[ig, j, ip, it] =
            0.01ig + 0.001j + 1.0e-7pressure_grid[ip] + 1.0e-5temperature_grid[it]
    end
    for ig in axes(shortwave_table, 1), j in axes(shortwave_table, 2),
        ip in axes(shortwave_table, 3), it in axes(shortwave_table, 4)
        shortwave_table[ig, j, ip, it] =
            0.02ig + 0.002j + 2.0e-7pressure_grid[ip] + 2.0e-5temperature_grid[it]
    end

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

    model = EcCKDTabulatedGasOpticsModel(
        gas_names = (:h2o, :co2),
        pressure_grid = pressure_grid,
        temperature_grid = temperature_grid,
        longwave_absorption = longwave_table,
        shortwave_absorption = shortwave_table,
        longwave_source_scale = [1.0, 1.1],
        longwave_weights = [0.45, 0.55],
        shortwave_weights = [1.0],
    )

    longwave = LongwaveOpticalProperties(zeros(2, nlayers), zeros(2, nlayers);
                                         weights = zeros(2))
    shortwave = ShortwaveOpticalProperties(zeros(1, nlayers); weights = zeros(1))
    fluxes = RadiativeFluxes(
        longwave_up = zeros(nlayers + 1),
        longwave_down = zeros(nlayers + 1),
        shortwave_up = zeros(nlayers + 1),
        shortwave_down = zeros(nlayers + 1),
    )
    heating = zeros(nlayers)

    optical_properties!(longwave, shortwave, model, atmosphere)
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

    candidate_flux = vcat(
        fluxes.longwave_up,
        fluxes.longwave_down,
        fluxes.shortwave_up,
        fluxes.shortwave_down,
    )
    candidate_heating_day = heating .* 86_400
    candidate_toa_flux = fluxes.longwave_up[1] - fluxes.longwave_down[1] -
                         fluxes.shortwave_down[1] + fluxes.shortwave_up[1]
    candidate_surface_flux = fluxes.longwave_up[end] - fluxes.longwave_down[end] -
                             fluxes.shortwave_down[end] + fluxes.shortwave_up[end]

    return (; candidate_flux, candidate_heating_day, candidate_toa_flux,
            candidate_surface_flux)
end

function metric_values(metrics)
    return (
        flux_rmse = metrics.flux_rmse,
        flux_max_abs = metrics.flux_max_abs,
        flux_bias = metrics.flux_bias,
        heating_rate_rmse = metrics.heating_rate_rmse,
        heating_rate_max_abs = metrics.heating_rate_max_abs,
        heating_rate_bias = metrics.heating_rate_bias,
        toa_forcing_error = metrics.toa_forcing_error,
        surface_forcing_error = metrics.surface_forcing_error,
    )
end

function threshold_values(thresholds)
    return (
        flux_rmse = thresholds.flux_rmse,
        flux_max_abs = thresholds.flux_max_abs,
        flux_abs_bias = thresholds.flux_abs_bias,
        heating_rate_rmse = thresholds.heating_rate_rmse,
        heating_rate_max_abs = thresholds.heating_rate_max_abs,
        heating_rate_abs_bias = thresholds.heating_rate_abs_bias,
        toa_forcing_abs_error = thresholds.toa_forcing_abs_error,
        surface_forcing_abs_error = thresholds.surface_forcing_abs_error,
    )
end

function json_value(value)
    if value isa AbstractString
        return "\"$value\""
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
    lines = String["{"]
    for (i, name) in enumerate(fields)
        comma = i == length(fields) ? "" : ","
        push!(lines, "  \"$(name)\": $(json_value(getproperty(result, name)))$(comma)")
    end
    push!(lines, "}")
    return join(lines, "\n")
end

function markdown_report(result)
    metrics = result.metrics
    thresholds = result.thresholds
    status = result.passed ? "pass" : "fail"
    return """
    # Toy ecCKD Validation

    Status: **$(status)**

    This is a deterministic toy fixture for the staged ecCKD tabulated gas-optics
    path. It is not an ecRad or CKDMIP scientific validation case.

    | Metric | Value | Threshold |
    |---|---:|---:|
    | Flux RMSE | $(@sprintf("%.12g", metrics.flux_rmse)) | $(@sprintf("%.12g", thresholds.flux_rmse)) |
    | Flux max abs | $(@sprintf("%.12g", metrics.flux_max_abs)) | $(@sprintf("%.12g", thresholds.flux_max_abs)) |
    | Flux bias | $(@sprintf("%.12g", metrics.flux_bias)) | $(@sprintf("%.12g", thresholds.flux_abs_bias)) |
    | Heating-rate RMSE | $(@sprintf("%.12g", metrics.heating_rate_rmse)) | $(@sprintf("%.12g", thresholds.heating_rate_rmse)) |
    | Heating-rate max abs | $(@sprintf("%.12g", metrics.heating_rate_max_abs)) | $(@sprintf("%.12g", thresholds.heating_rate_max_abs)) |
    | Heating-rate bias | $(@sprintf("%.12g", metrics.heating_rate_bias)) | $(@sprintf("%.12g", thresholds.heating_rate_abs_bias)) |
    | TOA forcing error | $(@sprintf("%.12g", metrics.toa_forcing_error)) | $(@sprintf("%.12g", thresholds.toa_forcing_abs_error)) |
    | Surface forcing error | $(@sprintf("%.12g", metrics.surface_forcing_error)) | $(@sprintf("%.12g", thresholds.surface_forcing_abs_error)) |

    Errors: $(isempty(result.errors) ? "none" : join(result.errors, "; "))
    """
end

function main()
    candidate = toy_case()
    thresholds = RadiationThresholds(
        flux_rmse = 1.0e-10,
        flux_max_abs = 1.0e-10,
        flux_abs_bias = 1.0e-10,
        heating_rate_rmse = 1.0e-10,
        heating_rate_max_abs = 1.0e-10,
        heating_rate_abs_bias = 1.0e-10,
        toa_forcing_abs_error = 1.0e-10,
        surface_forcing_abs_error = 1.0e-10,
    )
    metrics = radiation_error_metrics(
        candidate_flux = candidate.candidate_flux,
        reference_flux = REFERENCE_FLUX,
        candidate_heating_rate = candidate.candidate_heating_day,
        reference_heating_rate = REFERENCE_HEATING_DAY,
        candidate_toa_flux = candidate.candidate_toa_flux,
        reference_toa_flux = REFERENCE_TOA_FLUX,
        candidate_surface_flux = candidate.candidate_surface_flux,
        reference_surface_flux = REFERENCE_SURFACE_FLUX,
    )
    passed, errors = passes_thresholds(metrics, thresholds)
    result = (
        case = "toy_ecckd_tabulated_cloudless",
        date = string(Dates.now()),
        reference_kind = "stored deterministic toy fixture",
        passed = passed,
        metrics = metric_values(metrics),
        thresholds = threshold_values(thresholds),
        errors = errors,
    )

    results_dir = validation_results_dir()
    mkpath(results_dir)
    write(joinpath(results_dir, "latest.json"), json_object(result))
    write(joinpath(results_dir, "latest.md"), markdown_report(result))

    println("Toy ecCKD validation: $(passed ? "pass" : "fail")")
    println("flux RMSE: $(@sprintf("%.12g", metrics.flux_rmse))")
    println("heating-rate RMSE: $(@sprintf("%.12g", metrics.heating_rate_rmse))")
    passed || error("toy ecCKD validation failed: " * join(errors, "; "))
end

main()
