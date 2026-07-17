include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf
using Statistics

include(joinpath(@__DIR__, "ecrad_accuracy_gate.jl"))

function signed_stats(candidate, reference)
    error = vec(candidate .- reference)
    return (
        mean_bias = mean(error),
        min_bias = minimum(error),
        max_bias = maximum(error),
        mean_abs = mean(abs.(error)),
    )
end

function variable_bias_rows(path)
    dataset = NCDATASETS.NCDataset(reference_path(path))
    try
        variables = String.(collect(keys(dataset)))
        rows = NamedTuple[]
        for variable in COMPARISON_VARIABLES
            variable.name in variables || continue
            variable.candidate in variables || continue
            stats = signed_stats(Array(dataset[variable.candidate]), Array(dataset[variable.name]))
            push!(rows, (
                variable = variable.name,
                units = variable.units,
                mean_bias = stats.mean_bias,
                min_bias = stats.min_bias,
                max_bias = stats.max_bias,
                mean_abs = stats.mean_abs,
            ))
        end
        return rows
    finally
        close(dataset)
    end
end

function boundary_bias_rows(path)
    dataset = NCDATASETS.NCDataset(reference_path(path))
    try
        variables = String.(collect(keys(dataset)))
        reference_names = ("lw_up", "lw_down", "sw_up", "sw_down")
        candidate_names = CANDIDATE_PREFIX .* reference_names
        all(name -> name in variables, reference_names) || return NamedTuple[]
        all(name -> name in variables, candidate_names) || return NamedTuple[]

        rows = NamedTuple[]
        for boundary in (:toa, :surface)
            reference_net = net_flux(
                array_from_flux_var(dataset, "lw_up"),
                array_from_flux_var(dataset, "lw_down"),
                array_from_flux_var(dataset, "sw_up"),
                array_from_flux_var(dataset, "sw_down"),
                boundary,
            )
            candidate_net = net_flux(
                array_from_flux_var(dataset, CANDIDATE_PREFIX * "lw_up"),
                array_from_flux_var(dataset, CANDIDATE_PREFIX * "lw_down"),
                array_from_flux_var(dataset, CANDIDATE_PREFIX * "sw_up"),
                array_from_flux_var(dataset, CANDIDATE_PREFIX * "sw_down"),
                boundary,
            )
            stats = signed_stats(candidate_net, reference_net)
            push!(rows, (
                boundary = string(boundary),
                units = "W m^-2",
                mean_bias = stats.mean_bias,
                min_bias = stats.min_bias,
                max_bias = stats.max_bias,
                mean_abs = stats.mean_abs,
            ))
        end
        return rows
    finally
        close(dataset)
    end
end

function case_bias_status(case)
    manifest = case_status(case)
    if !manifest.schema_valid
        return (
            case = case.case,
            path = case.path,
            status = manifest.status,
            variable_biases = NamedTuple[],
            boundary_biases = NamedTuple[],
        )
    end
    return (
        case = case.case,
        path = case.path,
        status = "diagnosed",
        variable_biases = variable_bias_rows(case.path),
        boundary_biases = boundary_bias_rows(case.path),
    )
end

function run_flux_bias_diagnostics()
    cases = [case_bias_status(case) for case in REQUIRED_CASES]
    return (
        case = "ecrad_flux_bias_diagnostics",
        date = string(Dates.now()),
        candidate_prefix = CANDIDATE_PREFIX,
        cases = cases,
    )
end

function markdown_flux_bias_report(result)
    lines = String[
        "# ecRad Flux Bias Diagnostics",
        "",
        "This diagnostic reports signed candidate-minus-reference biases for `$(result.candidate_prefix)*` variables. It complements the hard absolute-threshold gate by showing error direction.",
    ]

    for case in result.cases
        append!(lines, [
            "",
            "## $(case.case)",
            "",
            "Path: `$(case.path)`",
            "",
            "### Boundary Net-Flux Bias",
            "",
            "| Boundary | Mean bias | Min bias | Max bias | Mean abs | Units |",
            "|---|---:|---:|---:|---:|---|",
        ])
        for row in case.boundary_biases
            push!(lines, "| $(row.boundary) | $(@sprintf("%.12g", row.mean_bias)) | $(@sprintf("%.12g", row.min_bias)) | $(@sprintf("%.12g", row.max_bias)) | $(@sprintf("%.12g", row.mean_abs)) | $(row.units) |")
        end

        append!(lines, [
            "",
            "### Variable Bias",
            "",
            "| Variable | Mean bias | Min bias | Max bias | Mean abs | Units |",
            "|---|---:|---:|---:|---:|---|",
        ])
        for row in case.variable_biases
            push!(lines, "| `$(row.variable)` | $(@sprintf("%.12g", row.mean_bias)) | $(@sprintf("%.12g", row.min_bias)) | $(@sprintf("%.12g", row.max_bias)) | $(@sprintf("%.12g", row.mean_abs)) | $(row.units) |")
        end
    end

    return join(lines, "\n") * "\n"
end

function flux_bias_diagnostics_main()
    result = run_flux_bias_diagnostics()
    results_dir = validation_results_dir()
    mkpath(results_dir)
    json_path = joinpath(results_dir, "ecrad_flux_bias_diagnostics.json")
    md_path = joinpath(results_dir, "ecrad_flux_bias_diagnostics.md")
    write(json_path, json_object(result))
    write(md_path, markdown_flux_bias_report(result))

    print(markdown_flux_bias_report(result))
    println("Wrote $json_path")
    println("Wrote $md_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    flux_bias_diagnostics_main()
end
