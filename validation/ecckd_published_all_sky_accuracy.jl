include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf
using Statistics

include(joinpath(@__DIR__, "write_ecrad_candidates.jl"))
include(joinpath(@__DIR__, "ecrad_accuracy_gate.jl"))

const PUBLISHED_ALL_SKY_ACCURACY_JSON =
    validation_results_path("ecckd_published_all_sky_accuracy.json")
const PUBLISHED_ALL_SKY_ACCURACY_MD =
    validation_results_path("ecckd_published_all_sky_accuracy.md")

const PUBLISHED_ALL_SKY_CONFIG = Dict(
    "RH_CANDIDATE_GAS_OPTICS" => "official_ecckd",
    "RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
    "RH_CLOUD_OVERLAP_LONGWAVE" => "true",
    "RH_CLOUD_OVERLAP_LONGWAVE_RULE" => "tripleclouds_alpha",
    "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
    "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
    "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
    "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
    "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "2.0",
    "RH_LW_CLOUD_SCATTERING" => "true",
    "RH_AEROSOL_OPTICS" => "true",
    "RH_IFS_AEROSOL_TABLE_OPTICS" => "true",
)

const PUBLISHED_ALL_SKY_MODEL_SPECS = (
    (
        label = "official ecCKD 1.0 32-LW x 32-SW all-sky climate model",
        case = "ecckd_32x32_all_sky_tropical_column",
        path = "validation/reference/ecrad/ecckd_all_sky_tropical_column.nc",
        ng_lw = 32,
        ng_sw = 32,
        longwave_file = "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc",
        shortwave_file = "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc",
    ),
    (
        label = "official ecCKD 1.0/1.2 32-LW x 64-SW all-sky climate/window model",
        case = "ecckd_32x64_all_sky_tropical_column",
        path = "validation/reference/ecrad/ecckd_32x64_all_sky_tropical_column.nc",
        ng_lw = 32,
        ng_sw = 64,
        longwave_file = "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc",
        shortwave_file = "ecckd-1.2_sw_climate_window-64b_ckd-definition.nc",
    ),
    (
        label = "official ecCKD 1.0/1.4 32-LW x 96-SW all-sky climate/vfine model",
        case = "ecckd_32x96_all_sky_tropical_column",
        path = "validation/reference/ecrad/ecckd_32x96_all_sky_tropical_column.nc",
        ng_lw = 32,
        ng_sw = 96,
        longwave_file = "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc",
        shortwave_file = "ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc",
    ),
    (
        label = "official ecCKD 1.2/1.4 64-LW x 32-SW all-sky narrow/rgb model",
        case = "ecckd_64x32_all_sky_tropical_column",
        path = "validation/reference/ecrad/ecckd_64x32_all_sky_tropical_column.nc",
        ng_lw = 64,
        ng_sw = 32,
        longwave_file = "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc",
        shortwave_file = "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc",
    ),
    (
        label = "official ecCKD 1.2 64-LW x 64-SW all-sky climate model",
        case = "ecckd_64x64_all_sky_tropical_column",
        path = "validation/reference/ecrad/ecckd_64x64_all_sky_tropical_column.nc",
        ng_lw = 64,
        ng_sw = 64,
        longwave_file = "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc",
        shortwave_file = "ecckd-1.2_sw_climate_window-64b_ckd-definition.nc",
    ),
    (
        label = "official ecCKD 1.2/1.4 64-LW x 96-SW all-sky climate/vfine model",
        case = "ecckd_64x96_all_sky_tropical_column",
        path = "validation/reference/ecrad/ecckd_64x96_all_sky_tropical_column.nc",
        ng_lw = 64,
        ng_sw = 96,
        longwave_file = "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc",
        shortwave_file = "ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc",
    ),
)

function with_all_sky_model_environment(f, spec)
    env_keys = unique(vcat(collect(keys(PUBLISHED_ALL_SKY_CONFIG)),
                           ["RH_ECCKD_LW_PATH", "RH_ECCKD_SW_PATH",
                            "RH_CLOUD_LW_MAPPING_PATH", "RH_CLOUD_SW_MAPPING_PATH"]))
    previous = Dict(key => get(ENV, key, nothing) for key in env_keys)
    longwave_path = joinpath("validation", "external", "ecrad", "data",
                             spec.longwave_file)
    shortwave_path = joinpath("validation", "external", "ecrad", "data",
                              spec.shortwave_file)
    try
        for (key, value) in PUBLISHED_ALL_SKY_CONFIG
            ENV[key] = value
        end
        ENV["RH_ECCKD_LW_PATH"] = longwave_path
        ENV["RH_ECCKD_SW_PATH"] = shortwave_path
        ENV["RH_CLOUD_LW_MAPPING_PATH"] = longwave_path
        ENV["RH_CLOUD_SW_MAPPING_PATH"] = shortwave_path
        return f()
    finally
        for (key, value) in previous
            if value === nothing
                delete!(ENV, key)
            else
                ENV[key] = value
            end
        end
    end
end

function all_sky_case_for_spec(spec)
    base = first(case for case in REQUIRED_CASES
                 if case.case == "ecckd_all_sky_tropical_column")
    return merge(base, (case = spec.case, path = spec.path))
end

function hard_objective_from_status(status)
    ratios = Float64[]
    for comparison in status.comparisons
        comparison.rmse !== nothing &&
            push!(ratios, comparison.rmse / comparison.rmse_threshold)
        comparison.max_abs !== nothing &&
            push!(ratios, comparison.max_abs / comparison.max_abs_threshold)
    end
    for comparison in status.forcing_comparisons
        comparison.max_abs !== nothing &&
            push!(ratios, comparison.max_abs / comparison.threshold)
    end
    return isempty(ratios) ? Inf : maximum(ratios)
end

function limiting_metric_from_status(status)
    rows = NamedTuple[]
    for comparison in status.comparisons
        comparison.rmse !== nothing && push!(rows, (
            metric = "$(comparison.variable)_rmse",
            value = comparison.rmse,
            threshold = comparison.rmse_threshold,
            normalized_value = comparison.rmse / comparison.rmse_threshold,
        ))
        comparison.max_abs !== nothing && push!(rows, (
            metric = "$(comparison.variable)_max_abs",
            value = comparison.max_abs,
            threshold = comparison.max_abs_threshold,
            normalized_value = comparison.max_abs / comparison.max_abs_threshold,
        ))
    end
    for comparison in status.forcing_comparisons
        comparison.max_abs !== nothing && push!(rows, (
            metric = comparison.metric,
            value = comparison.max_abs,
            threshold = comparison.threshold,
            normalized_value = comparison.max_abs / comparison.threshold,
        ))
    end
    isempty(rows) && return (
        metric = "missing",
        value = nothing,
        threshold = nothing,
        normalized_value = Inf,
    )
    return rows[argmax([row.normalized_value for row in rows])]
end

function component_boundary_errors(path)
    NCDATASETS.NCDataset(reference_path(path)) do dataset
        rows = NamedTuple[]
        for component in ("lw", "sw")
            reference_net =
                Array(dataset["$(component)_down"]) .-
                Array(dataset["$(component)_up"])
            candidate_net =
                Array(dataset["radiative_heating_$(component)_down"]) .-
                Array(dataset["radiative_heating_$(component)_up"])
            for (boundary, index) in (("toa", 1), ("surface", size(reference_net, 1)))
                error = vec(candidate_net[index, :] .- reference_net[index, :])
                push!(rows, (
                    component = component,
                    boundary = boundary,
                    max_abs = maximum(abs, error),
                    mean_bias = mean(error),
                    mean_abs = mean(abs.(error)),
                ))
            end
        end
        return rows
    end
end

function all_sky_model_accuracy(spec)
    with_all_sky_model_environment(spec) do
        CLOUD_SCATTERING_CACHE[] = nothing
        empty!(LAYER_CLOUD_SCATTERING_CACHE[])
        IFS_AEROSOL_CACHE[] = nothing
        run_candidate_for_file!(spec.path)
    end
    status = case_accuracy_status(all_sky_case_for_spec(spec))
    toa = first(filter(row -> row.boundary == "toa", status.forcing_comparisons))
    surface = first(filter(row -> row.boundary == "surface",
                           status.forcing_comparisons))
    limiting = limiting_metric_from_status(status)
    component_errors = component_boundary_errors(spec.path)
    return (
        label = spec.label,
        case = spec.case,
        path = spec.path,
        ng_lw = spec.ng_lw,
        ng_sw = spec.ng_sw,
        longwave_file = spec.longwave_file,
        shortwave_file = spec.shortwave_file,
        passed = status.passed,
        status = status.status,
        hard_objective = hard_objective_from_status(status),
        toa_forcing_max_abs = toa.max_abs,
        surface_forcing_max_abs = surface.max_abs,
        limiting_metric = limiting.metric,
        limiting_metric_value = limiting.value,
        limiting_metric_threshold = limiting.threshold,
        limiting_metric_ratio = limiting.normalized_value,
        component_boundary_errors = component_errors,
        comparisons = status.comparisons,
        forcing_comparisons = status.forcing_comparisons,
    )
end

function component_error(row, component, boundary)
    return first(error for error in row.component_boundary_errors
                 if error.component == component && error.boundary == boundary)
end

function run_published_all_sky_accuracy()
    models = [all_sky_model_accuracy(spec) for spec in PUBLISHED_ALL_SKY_MODEL_SPECS]
    passed_count = count(model -> model.passed, models)
    return (
        case = "ecckd_published_all_sky_accuracy",
        timestamp_utc = string(Dates.now()),
        status = passed_count == length(models) ? "passed" : "failed_threshold",
        model_count = length(models),
        passed_count = passed_count,
        acceptance_thresholds = ACCEPTANCE_THRESHOLDS,
        configuration = [(variable = key, value = PUBLISHED_ALL_SKY_CONFIG[key])
                         for key in sort(collect(keys(PUBLISHED_ALL_SKY_CONFIG)))],
        models = models,
        note = "Each row rewrites package candidate variables into the matched all-sky ecRad reference using the same Tripleclouds/aerosol configuration as the current all-sky IFS gate, but with model-specific ecCKD gas-optics and cloud-scattering mapping files.",
    )
end

function markdown_report(result)
    lines = String[
        "# Published ecCKD All-Sky Accuracy",
        "",
        "Status: **$(result.status)**",
        "",
        result.note,
        "",
        "| Model | LW | SW | Passed | TOA forcing | Surface forcing | LW TOA | LW surface | SW TOA | SW surface | Hard objective | Limiting metric |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|",
    ]
    for row in result.models
        lw_toa = component_error(row, "lw", "toa").max_abs
        lw_surface = component_error(row, "lw", "surface").max_abs
        sw_toa = component_error(row, "sw", "toa").max_abs
        sw_surface = component_error(row, "sw", "surface").max_abs
        push!(lines,
              "| $(row.label) | $(row.ng_lw) | $(row.ng_sw) | $(row.passed) | $(@sprintf("%.12g", row.toa_forcing_max_abs)) W m^-2 | $(@sprintf("%.12g", row.surface_forcing_max_abs)) W m^-2 | $(@sprintf("%.12g", lw_toa)) | $(@sprintf("%.12g", lw_surface)) | $(@sprintf("%.12g", sw_toa)) | $(@sprintf("%.12g", sw_surface)) | $(@sprintf("%.12g", row.hard_objective)) | `$(row.limiting_metric)` |")
    end
    append!(lines, [
        "",
        "## Candidate Configuration",
        "",
        "| Environment variable | Value |",
        "|---|---|",
    ])
    for row in result.configuration
        push!(lines, "| `$(row.variable)` | `$(row.value)` |")
    end
    return join(lines, "\n") * "\n"
end

function main()
    result = run_published_all_sky_accuracy()
    mkpath(dirname(PUBLISHED_ALL_SKY_ACCURACY_JSON))
    write(PUBLISHED_ALL_SKY_ACCURACY_JSON, json_object(result) * "\n")
    write(PUBLISHED_ALL_SKY_ACCURACY_MD, markdown_report(result))
    print(markdown_report(result))
    println("Wrote $PUBLISHED_ALL_SKY_ACCURACY_JSON")
    println("Wrote $PUBLISHED_ALL_SKY_ACCURACY_MD")
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
