include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_accuracy.jl"))

const SIZE_SCAN_METHODS = ("even_select", "weighted_bins")
const SIZE_SCAN_SW_GPOINTS = (16, 20, 24, 28, 30, 32)

function size_scan_model(full_model, method, ng_sw)
    if method == "even_select"
        return selected_tabulated_model(full_model, 32, ng_sw)
    elseif method == "weighted_bins"
        return weighted_tabulated_model(full_model, 32, ng_sw)
    end
    error("unknown size-scan method $method")
end

function size_scan_row(full_model, method, ng_sw)
    model = size_scan_model(full_model, method, ng_sw)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return (
        method = method,
        ng_lw = 32,
        ng_sw = ng_sw,
        passed_hard_thresholds = all(case -> case.passed_hard_thresholds, cases),
        worst_toa_forcing_error = maximum(case.toa_forcing_max_abs for case in cases),
        worst_surface_forcing_error = maximum(case.surface_forcing_max_abs for case in cases),
        worst_sw_up_rmse = maximum(case.variables.sw_up.rmse for case in cases),
        worst_sw_down_rmse = maximum(case.variables.sw_down.rmse for case in cases),
        cases = cases,
    )
end

function markdown_size_scan(result)
    lines = String[
        "# Reduced ecCKD Size Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "This scan evaluates simple official-gpoint reduction strategies against the clean ecCKD hard gate. It is diagnostic evidence only; passing the reduced-model goal still requires a reduced 16-term method that meets the hard thresholds.",
        "",
        "| Method | ng_lw | ng_sw | Passed | Worst TOA forcing error | Worst surface forcing error | Worst SW up RMSE | Worst SW down RMSE |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in result.rows
        push!(lines, "| $(row.method) | $(row.ng_lw) | $(row.ng_sw) | $(row.passed_hard_thresholds) | $(@sprintf("%.12g", row.worst_toa_forcing_error)) W m^-2 | $(@sprintf("%.12g", row.worst_surface_forcing_error)) W m^-2 | $(@sprintf("%.12g", row.worst_sw_up_rmse)) W m^-2 | $(@sprintf("%.12g", row.worst_sw_down_rmse)) W m^-2 |")
    end
    return join(lines, "\n") * "\n"
end

function reduced_size_scan_main()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    rows = [size_scan_row(full_model, method, ng_sw)
            for method in SIZE_SCAN_METHODS
            for ng_sw in SIZE_SCAN_SW_GPOINTS]
    reduced_rows = filter(row -> row.ng_sw < 32, rows)
    status = any(row -> row.passed_hard_thresholds, reduced_rows) ?
        "reduced_pass_found" : "only_full_32_sw_passes"
    result = (
        case = "radiative_heating_reduced_size_scan",
        timestamp_utc = string(Dates.now()),
        status = status,
        reference_scope = collect(REDUCED_CASE_NAMES),
        rows = rows,
    )

    results_dir = validation_results_dir()
    mkpath(results_dir)
    json_path = joinpath(results_dir, "reduced_ecckd_size_scan.json")
    md_path = joinpath(results_dir, "reduced_ecckd_size_scan.md")
    write(json_path, json_object(result))
    write(md_path, markdown_size_scan(result))

    print(markdown_size_scan(result))
    println("Wrote $json_path")
    println("Wrote $md_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    reduced_size_scan_main()
end
