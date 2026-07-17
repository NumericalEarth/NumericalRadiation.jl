include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_retained_capped_table_continuation.jl"))
include(joinpath(@__DIR__, "reduced_ecckd_subset_search.jl"))

const RETAINED_POST_CAPPED_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_retained_post_capped_weight_refit.json")
const RETAINED_POST_CAPPED_WEIGHT_REFIT_MD =
    validation_results_path("reduced_ecckd_retained_post_capped_weight_refit.md")

retained_post_capped_weight_refit_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_RETAINED_POST_CAPPED_WEIGHT_REFIT_ITERATIONS", "25000"))

function retained_post_capped_weight_refit_base(full_model)
    moves = vcat(
        latest_retained_capped_table_optimizer_moves(),
        latest_retained_capped_table_continuation_moves(),
    )
    return current_constrained_table_model(
        full_model,
        moves;
        base_mode = "retained_topology",
        sw_indices = WEIGHTED_GREEDY_SW_16_INDICES,
    )
end

function retained_post_capped_weight_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = retained_post_capped_weight_refit_base(full_model)
    base_cases = [case_metrics(case, base_model) for case in REDUCED_CASES]
    base_objective = maximum(exact_case_objective, base_cases)
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    refit_weights, approximate_objective =
        optimized_subset_weights_hardgate(
            search_context(base_model),
            collect(1:length(base_model.shortwave_weights));
            initial_weights = base_model.shortwave_weights,
            max_iterations = retained_post_capped_weight_refit_iterations(),
        )
    refit_model = with_shortwave_weights(base_model, refit_weights)
    refit_cases = [case_metrics(case, refit_model) for case in REDUCED_CASES]
    refit_objective = maximum(exact_case_objective, refit_cases)
    refit_toa = maximum(case.toa_forcing_max_abs for case in refit_cases)
    refit_surface = maximum(case.surface_forcing_max_abs for case in refit_cases)
    accepted = refit_objective < base_objective &&
        refit_toa <= base_toa &&
        refit_surface <= base_surface
    return (
        case = "reduced_ecckd_retained_post_capped_weight_refit",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = accepted ? "retained_post_capped_weight_refit_improved" :
                 "retained_post_capped_weight_refit_rejected",
        iterations = retained_post_capped_weight_refit_iterations(),
        base_objective = base_objective,
        final_objective = accepted ? refit_objective : base_objective,
        refit_objective = refit_objective,
        objective_reduction = base_objective - refit_objective,
        approximate_hardgate_objective = approximate_objective,
        base_worst_toa_forcing_error_w_m2 = base_toa,
        base_worst_surface_forcing_error_w_m2 = base_surface,
        refit_worst_toa_forcing_error_w_m2 = refit_toa,
        refit_worst_surface_forcing_error_w_m2 = refit_surface,
        final_worst_toa_forcing_error_w_m2 = accepted ? refit_toa : base_toa,
        final_worst_surface_forcing_error_w_m2 = accepted ? refit_surface : base_surface,
        accepted = accepted,
        max_abs_weight_delta = maximum(abs.(refit_weights .- base_model.shortwave_weights)),
        base_weights = collect(base_model.shortwave_weights),
        final_weights = accepted ? collect(refit_weights) : collect(base_model.shortwave_weights),
    )
end

function retained_post_capped_weight_refit_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Post-Capped Weight Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Iterations | $(result.iterations) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Refit objective | $(@sprintf("%.12g", result.refit_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Approximate hard-gate objective | $(@sprintf("%.12g", result.approximate_hardgate_objective)) |",
        "| Base TOA forcing | $(@sprintf("%.12g", result.base_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Base surface forcing | $(@sprintf("%.12g", result.base_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Refit TOA forcing | $(@sprintf("%.12g", result.refit_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Refit surface forcing | $(@sprintf("%.12g", result.refit_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Accepted | $(result.accepted) |",
        "| Max absolute weight delta | $(@sprintf("%.12g", result.max_abs_weight_delta)) |",
        "",
        "This diagnostic refits only the retained 16 shortwave quadrature weights",
        "after composing the retained capped-table optimizer and continuation",
        "moves. It is accepted only when the exact hard objective falls and",
        "neither worst TOA nor worst surface forcing error regresses.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? retained_post_capped_weight_refit_result() : result
    mkpath(dirname(RETAINED_POST_CAPPED_WEIGHT_REFIT_JSON))
    write(RETAINED_POST_CAPPED_WEIGHT_REFIT_JSON, json_object(result) * "\n")
    write(RETAINED_POST_CAPPED_WEIGHT_REFIT_MD,
          retained_post_capped_weight_refit_markdown(result))
    print(retained_post_capped_weight_refit_markdown(result))
    println("Wrote $RETAINED_POST_CAPPED_WEIGHT_REFIT_JSON")
    println("Wrote $RETAINED_POST_CAPPED_WEIGHT_REFIT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
