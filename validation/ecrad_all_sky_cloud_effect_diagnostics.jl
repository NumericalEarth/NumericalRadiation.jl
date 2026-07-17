include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf
using Statistics

include(joinpath(@__DIR__, "ecrad_accuracy_gate.jl"))

const CLOUD_EFFECT_CASES = filter(case -> occursin("all_sky", case.case), REQUIRED_CASES)

function interface_net(dataset, up_name, down_name)
    return Array(dataset[down_name]) .- Array(dataset[up_name])
end

function cloud_effect(dataset, up_name, down_name, up_clear_name, down_clear_name)
    total_net = interface_net(dataset, up_name, down_name)
    clear_net = interface_net(dataset, up_clear_name, down_clear_name)
    return total_net .- clear_net
end

function error_summary(candidate, reference)
    error = vec(candidate .- reference)
    return (
        rmse = sqrt(mean(abs2, error)),
        max_abs = maximum(abs, error),
        mean_bias = mean(error),
        mean_abs = mean(abs.(error)),
    )
end

function boundary_cloud_effect_row(dataset, boundary, component)
    suffix = component == :lw ? ("lw_up", "lw_down", "lw_up_clear", "lw_down_clear") :
             component == :sw ? ("sw_up", "sw_down", "sw_up_clear", "sw_down_clear") :
             nothing

    if suffix === nothing
        reference_lw = cloud_effect(dataset, "lw_up", "lw_down", "lw_up_clear", "lw_down_clear")
        reference_sw = cloud_effect(dataset, "sw_up", "sw_down", "sw_up_clear", "sw_down_clear")
        candidate_lw = cloud_effect(dataset, CANDIDATE_PREFIX * "lw_up", CANDIDATE_PREFIX * "lw_down",
                                    CANDIDATE_PREFIX * "lw_up_clear", CANDIDATE_PREFIX * "lw_down_clear")
        candidate_sw = cloud_effect(dataset, CANDIDATE_PREFIX * "sw_up", CANDIDATE_PREFIX * "sw_down",
                                    CANDIDATE_PREFIX * "sw_up_clear", CANDIDATE_PREFIX * "sw_down_clear")
        reference = reference_lw .+ reference_sw
        candidate = candidate_lw .+ candidate_sw
    else
        up, down, up_clear, down_clear = suffix
        reference = cloud_effect(dataset, up, down, up_clear, down_clear)
        candidate = cloud_effect(dataset, CANDIDATE_PREFIX * up, CANDIDATE_PREFIX * down,
                                 CANDIDATE_PREFIX * up_clear, CANDIDATE_PREFIX * down_clear)
    end

    index = boundary == :toa ? firstindex(reference, 1) : lastindex(reference, 1)
    stats = error_summary(selectdim(candidate, 1, index), selectdim(reference, 1, index))
    return (
        boundary = string(boundary),
        component = string(component),
        rmse = stats.rmse,
        max_abs = stats.max_abs,
        mean_bias = stats.mean_bias,
        mean_abs = stats.mean_abs,
        units = "W m^-2",
    )
end

function profile_cloud_effect_row(dataset, component)
    if component == :lw
        reference = cloud_effect(dataset, "lw_up", "lw_down", "lw_up_clear", "lw_down_clear")
        candidate = cloud_effect(dataset, CANDIDATE_PREFIX * "lw_up", CANDIDATE_PREFIX * "lw_down",
                                 CANDIDATE_PREFIX * "lw_up_clear", CANDIDATE_PREFIX * "lw_down_clear")
        units = "W m^-2"
    elseif component == :sw
        reference = cloud_effect(dataset, "sw_up", "sw_down", "sw_up_clear", "sw_down_clear")
        candidate = cloud_effect(dataset, CANDIDATE_PREFIX * "sw_up", CANDIDATE_PREFIX * "sw_down",
                                 CANDIDATE_PREFIX * "sw_up_clear", CANDIDATE_PREFIX * "sw_down_clear")
        units = "W m^-2"
    elseif component == :total
        reference = cloud_effect(dataset, "lw_up", "lw_down", "lw_up_clear", "lw_down_clear") .+
                    cloud_effect(dataset, "sw_up", "sw_down", "sw_up_clear", "sw_down_clear")
        candidate = cloud_effect(dataset, CANDIDATE_PREFIX * "lw_up", CANDIDATE_PREFIX * "lw_down",
                                 CANDIDATE_PREFIX * "lw_up_clear", CANDIDATE_PREFIX * "lw_down_clear") .+
                    cloud_effect(dataset, CANDIDATE_PREFIX * "sw_up", CANDIDATE_PREFIX * "sw_down",
                                 CANDIDATE_PREFIX * "sw_up_clear", CANDIDATE_PREFIX * "sw_down_clear")
        units = "W m^-2"
    else
        reference = Array(dataset["heating_rate"]) .- Array(dataset["heating_rate_clear"])
        candidate = Array(dataset[CANDIDATE_PREFIX * "heating_rate"]) .-
                    Array(dataset[CANDIDATE_PREFIX * "heating_rate_clear"])
        units = "K day^-1"
    end

    stats = error_summary(candidate, reference)
    return (
        component = string(component),
        rmse = stats.rmse,
        max_abs = stats.max_abs,
        mean_bias = stats.mean_bias,
        mean_abs = stats.mean_abs,
        units = units,
    )
end

function missing_cloud_effect_variables(dataset)
    names = String.(collect(keys(dataset)))
    required = String[
        "lw_up", "lw_down", "sw_up", "sw_down", "heating_rate",
        "lw_up_clear", "lw_down_clear", "sw_up_clear", "sw_down_clear", "heating_rate_clear",
    ]
    append!(required, CANDIDATE_PREFIX .* required)
    return [name for name in required if !(name in names)]
end

function all_sky_cloud_effect_case_status(case)
    manifest = case_status(case)
    if !manifest.schema_valid
        return (
            case = case.case,
            path = case.path,
            status = manifest.status,
            missing_variables = manifest.missing_variables,
            boundary_cloud_effects = NamedTuple[],
            profile_cloud_effects = NamedTuple[],
        )
    end

    dataset = NCDATASETS.NCDataset(reference_path(case.path))
    try
        missing = missing_cloud_effect_variables(dataset)
        if !isempty(missing)
            return (
                case = case.case,
                path = case.path,
                status = "missing_cloud_effect_variable",
                missing_variables = missing,
                boundary_cloud_effects = NamedTuple[],
                profile_cloud_effects = NamedTuple[],
            )
        end

        boundary_rows = NamedTuple[
            boundary_cloud_effect_row(dataset, boundary, component)
            for boundary in (:toa, :surface)
            for component in (:lw, :sw, :total)
        ]
        profile_rows = NamedTuple[
            profile_cloud_effect_row(dataset, component)
            for component in (:lw, :sw, :total, :heating_rate)
        ]
        return (
            case = case.case,
            path = case.path,
            status = "diagnosed",
            missing_variables = String[],
            boundary_cloud_effects = boundary_rows,
            profile_cloud_effects = profile_rows,
        )
    finally
        close(dataset)
    end
end

function run_all_sky_cloud_effect_diagnostics()
    cases = NCDATASETS === nothing ? NamedTuple[] :
        [all_sky_cloud_effect_case_status(case) for case in CLOUD_EFFECT_CASES]
    return (
        case = "ecrad_all_sky_cloud_effect_diagnostics",
        date = string(Dates.now()),
        candidate_prefix = CANDIDATE_PREFIX,
        cases = cases,
    )
end

function markdown_all_sky_cloud_effect_report(result)
    lines = String[
        "# ecRad All-Sky Cloud-Effect Diagnostics",
        "",
        "This diagnostic compares cloud radiative effects, defined as total-sky net flux minus clear-sky net flux, between ecRad references and `$(result.candidate_prefix)*` candidate variables.",
    ]

    for case in result.cases
        append!(lines, [
            "",
            "## $(case.case)",
            "",
            "Status: **$(case.status)**",
            "",
            "Path: `$(case.path)`",
        ])
        if !isempty(case.missing_variables)
            push!(lines, "")
            push!(lines, "Missing variables: `$(join(case.missing_variables, "`, `"))`")
            continue
        end

        append!(lines, [
            "",
            "### Boundary Cloud Effect Error",
            "",
            "| Boundary | Component | RMSE | Max abs | Mean bias | Mean abs | Units |",
            "|---|---|---:|---:|---:|---:|---|",
        ])
        for row in case.boundary_cloud_effects
            push!(lines, "| $(row.boundary) | $(row.component) | $(@sprintf("%.12g", row.rmse)) | $(@sprintf("%.12g", row.max_abs)) | $(@sprintf("%.12g", row.mean_bias)) | $(@sprintf("%.12g", row.mean_abs)) | $(row.units) |")
        end

        append!(lines, [
            "",
            "### Profile Cloud Effect Error",
            "",
            "| Component | RMSE | Max abs | Mean bias | Mean abs | Units |",
            "|---|---:|---:|---:|---:|---|",
        ])
        for row in case.profile_cloud_effects
            push!(lines, "| $(row.component) | $(@sprintf("%.12g", row.rmse)) | $(@sprintf("%.12g", row.max_abs)) | $(@sprintf("%.12g", row.mean_bias)) | $(@sprintf("%.12g", row.mean_abs)) | $(row.units) |")
        end
    end
    return join(lines, "\n") * "\n"
end

function all_sky_cloud_effect_diagnostics_main()
    result = run_all_sky_cloud_effect_diagnostics()
    results_dir = validation_results_dir()
    mkpath(results_dir)
    json_path = joinpath(results_dir, "ecrad_all_sky_cloud_effect_diagnostics.json")
    md_path = joinpath(results_dir, "ecrad_all_sky_cloud_effect_diagnostics.md")
    write(json_path, json_object(result))
    write(md_path, markdown_all_sky_cloud_effect_report(result))

    print(markdown_all_sky_cloud_effect_report(result))
    println("Wrote $json_path")
    println("Wrote $md_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    all_sky_cloud_effect_diagnostics_main()
end
