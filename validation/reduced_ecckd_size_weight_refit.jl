include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_subset_search.jl"))

const SIZE_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_size_weight_refit.json")
const SIZE_WEIGHT_REFIT_MD =
    validation_results_path("reduced_ecckd_size_weight_refit.md")

const SIZE_WEIGHT_REFIT_METHODS = ("even_select", "weighted_bins")
const SIZE_WEIGHT_REFIT_SW_GPOINTS = (16, 20, 24, 28, 30)

size_weight_refit_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_SIZE_WEIGHT_REFIT_ITERATIONS", "1200"))

function size_weight_refit_model(full_model, method, ng_sw)
    if method == "even_select"
        return selected_tabulated_model(full_model, 32, ng_sw)
    elseif method == "weighted_bins"
        return weighted_tabulated_model(full_model, 32, ng_sw)
    end
    throw(ArgumentError("unknown size-weight refit method $method"))
end

function size_weight_refit_row(full_model, method, ng_sw)
    model = size_weight_refit_model(full_model, method, ng_sw)
    initial_cases = [case_metrics(case, model) for case in REDUCED_CASES]
    initial_objective = maximum(exact_case_objective, initial_cases)
    refit_weights, approximate_objective =
        optimized_subset_weights_hardgate(
            search_context(model),
            collect(1:size(model.shortwave_absorption, 1));
            initial_weights = model.shortwave_weights,
            max_iterations = size_weight_refit_iterations(),
        )
    refit_model = with_shortwave_weights(model, refit_weights)
    refit_cases = [case_metrics(case, refit_model) for case in REDUCED_CASES]
    refit_objective = maximum(exact_case_objective, refit_cases)
    return (
        method = method,
        ng_lw = 32,
        ng_sw = ng_sw,
        iterations = size_weight_refit_iterations(),
        initial_objective = initial_objective,
        refit_objective = refit_objective,
        objective_reduction = initial_objective - refit_objective,
        approximate_hardgate_objective = approximate_objective,
        passed_hard_thresholds = all(case -> case.passed_hard_thresholds, refit_cases),
        worst_toa_forcing_error = maximum(case.toa_forcing_max_abs for case in refit_cases),
        worst_surface_forcing_error =
            maximum(case.surface_forcing_max_abs for case in refit_cases),
        worst_sw_up_rmse = maximum(case.variables.sw_up.rmse for case in refit_cases),
        worst_sw_down_rmse = maximum(case.variables.sw_down.rmse for case in refit_cases),
        refit_weights = collect(refit_weights),
        cases = refit_cases,
    )
end

function size_weight_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    rows = [
        size_weight_refit_row(full_model, method, ng_sw)
        for method in SIZE_WEIGHT_REFIT_METHODS
        for ng_sw in SIZE_WEIGHT_REFIT_SW_GPOINTS
    ]
    return (
        case = "radiative_heating_reduced_size_weight_refit",
        timestamp_utc = string(Dates.now()),
        status = any(row -> row.passed_hard_thresholds, rows) ?
            "reduced_pass_found" : "refit_still_failed",
        reference_scope = collect(REDUCED_CASE_NAMES),
        iterations = size_weight_refit_iterations(),
        rows = rows,
    )
end

function size_weight_refit_markdown(result)
    lines = String[
        "# Reduced ecCKD Size Weight Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "This diagnostic refits only shortwave weights for larger reduced",
        "official-g-point candidates. It tests whether the simple size-scan",
        "failures are caused by missing g-points or by naive weights.",
        "",
        "| Method | ng_lw | ng_sw | Passed | Initial objective | Refit objective | Worst TOA forcing error | Worst surface forcing error |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in result.rows
        push!(lines, "| $(row.method) | $(row.ng_lw) | $(row.ng_sw) | $(row.passed_hard_thresholds) | $(@sprintf("%.12g", row.initial_objective)) | $(@sprintf("%.12g", row.refit_objective)) | $(@sprintf("%.12g", row.worst_toa_forcing_error)) W m^-2 | $(@sprintf("%.12g", row.worst_surface_forcing_error)) W m^-2 |")
    end
    return join(lines, "\n") * "\n"
end

function write_size_weight_refit_artifacts(result)
    mkpath(dirname(SIZE_WEIGHT_REFIT_JSON))
    write(SIZE_WEIGHT_REFIT_JSON, json_object(result) * "\n")
    write(SIZE_WEIGHT_REFIT_MD, size_weight_refit_markdown(result))
    print(size_weight_refit_markdown(result))
    println("Wrote $SIZE_WEIGHT_REFIT_JSON")
    println("Wrote $SIZE_WEIGHT_REFIT_MD")
end

function main(; result = nothing)
    write_size_weight_refit_artifacts(
        result === nothing ? size_weight_refit_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
