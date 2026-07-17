include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_subset_search.jl"))

const POST_TABLE_WEIGHT_JSON =
    validation_results_path("reduced_ecckd_post_table_weight_refit.json")
const POST_TABLE_WEIGHT_MD =
    validation_results_path("reduced_ecckd_post_table_weight_refit.md")

post_table_weight_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_POST_TABLE_WEIGHT_ITERATIONS", "2000"))

function current_table_refined_model(full_model)
    reduced = indexed_tabulated_model(
        full_model,
        collect(1:size(full_model.longwave_absorption, 1)),
        WEIGHTED_GREEDY_SW_16_INDICES,
    )
    parameters = latest_preflight_reduced_parameters()
    if parameters === nothing
        reduced.shortwave_weights .= WEIGHTED_GREEDY_SW_16_WEIGHTS
        scale_shortwave_coefficients!(
            reduced,
            WEIGHTED_GREEDY_SW_16_COEFFICIENT_SCALES,
        )
    else
        apply_weight_absorption_rayleigh_parameters!(reduced, parameters)
    end
    apply_pressure_band_table_moves!(
        reduced,
        latest_preflight_pressure_band_table_moves(),
    )
    apply_active_table_entry_moves!(
        reduced,
        best_available_active_table_entry_moves(),
    )
    apply_best_exact_weight_refit!(reduced)
    apply_gas_pressure_band_refinement_moves!(
        reduced,
        latest_gas_pressure_band_refinement_moves(),
    )
    apply_active_table_entry_moves!(
        reduced,
        latest_constrained_table_optimizer_moves(),
    )
    apply_post_constrained_weight_refit!(reduced)
    return reduced
end

function post_table_weight_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = current_table_refined_model(full_model)
    base_cases = [case_metrics(case, base_model) for case in REDUCED_CASES]
    base_objective = maximum(exact_case_objective, base_cases)
    refit_weights, approximate_objective =
        optimized_subset_weights_hardgate(
            search_context(base_model),
            collect(1:size(base_model.shortwave_absorption, 1));
            initial_weights = base_model.shortwave_weights,
            max_iterations = post_table_weight_iterations(),
        )
    refit_model = with_shortwave_weights(base_model, refit_weights)
    refit_cases = [case_metrics(case, refit_model) for case in REDUCED_CASES]
    refit_objective = maximum(exact_case_objective, refit_cases)
    accepted = refit_objective < base_objective
    return (
        case = "reduced_ecckd_post_table_weight_refit",
        status = "preflight_ready",
        iterations = post_table_weight_iterations(),
        base_objective = base_objective,
        refit_objective = refit_objective,
        objective_reduction = base_objective - refit_objective,
        accepted = accepted,
        approximate_hardgate_objective = approximate_objective,
        base_weights = collect(base_model.shortwave_weights),
        refit_weights = collect(refit_weights),
        base_cases = base_cases,
        refit_cases = refit_cases,
    )
end

function post_table_weight_markdown(result)
    base_toa = maximum(case.toa_forcing_max_abs for case in result.base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in result.base_cases)
    refit_toa = maximum(case.toa_forcing_max_abs for case in result.refit_cases)
    refit_surface = maximum(case.surface_forcing_max_abs for case in result.refit_cases)
    lines = String[
        "# Reduced ecCKD Post-Table Weight Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Iterations | $(result.iterations) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Refit objective | $(@sprintf("%.12g", result.refit_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Accepted | $(result.accepted) |",
        "| Approximate hard-gate objective | $(@sprintf("%.12g", result.approximate_hardgate_objective)) |",
        "| Base worst TOA forcing | $(@sprintf("%.12g", base_toa)) W m^-2 |",
        "| Base worst surface forcing | $(@sprintf("%.12g", base_surface)) W m^-2 |",
        "| Refit worst TOA forcing | $(@sprintf("%.12g", refit_toa)) W m^-2 |",
        "| Refit worst surface forcing | $(@sprintf("%.12g", refit_surface)) W m^-2 |",
        "",
        "This diagnostic refits only the 16 shortwave weights after applying the",
        "current coefficient scales, pressure-band table moves, and best available",
        "targeted active table-entry moves. The refit is accepted only if the exact",
        "hard-gate objective improves.",
    ]
    return join(lines, "\n") * "\n"
end

function write_post_table_weight_artifacts(result)
    mkpath(dirname(POST_TABLE_WEIGHT_JSON))
    write(POST_TABLE_WEIGHT_JSON, json_object(result) * "\n")
    write(POST_TABLE_WEIGHT_MD, post_table_weight_markdown(result))
    print(post_table_weight_markdown(result))
    println("Wrote $POST_TABLE_WEIGHT_JSON")
    println("Wrote $POST_TABLE_WEIGHT_MD")
end

function main(; result = nothing)
    write_post_table_weight_artifacts(
        result === nothing ? post_table_weight_refit_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
