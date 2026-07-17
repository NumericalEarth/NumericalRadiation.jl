include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_retained_post_weight_surface_table_refit.jl"))

const RETAINED_POST_WEIGHT_BOUNDED_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_retained_post_weight_bounded_weight_refit.json")
const RETAINED_POST_WEIGHT_BOUNDED_WEIGHT_REFIT_MD =
    validation_results_path("reduced_ecckd_retained_post_weight_bounded_weight_refit.md")

post_weight_bounded_weight_refit_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_POST_WEIGHT_BOUNDED_WEIGHT_REFIT_ITERATIONS", "50000"))

post_weight_bounded_weight_surface_cap() =
    parse(Float64, get(ENV, "RH_REDUCED_POST_WEIGHT_BOUNDED_WEIGHT_SURFACE_CAP", "2.03"))

post_weight_bounded_weight_toa_tolerance() =
    parse(Float64, get(ENV, "RH_REDUCED_POST_WEIGHT_BOUNDED_WEIGHT_TOA_TOLERANCE", "0.0"))

function post_weight_bounded_weight_refit_base(full_model)
    moves = vcat(
        post_weight_surface_table_base_moves(),
        latest_retained_post_weight_surface_table_refit_moves(),
    )
    base = current_constrained_table_model(
        full_model,
        moves;
        base_mode = "retained_topology",
        sw_indices = WEIGHTED_GREEDY_SW_16_INDICES,
    )
    weights = latest_retained_post_capped_weight_refit_weights()
    weights === nothing && error("accepted post-capped weight refit is required")
    base.shortwave_weights .= weights.weights
    return base
end

function retained_post_weight_bounded_weight_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = post_weight_bounded_weight_refit_base(full_model)
    base_cases = [case_metrics(case, base_model) for case in REDUCED_CASES]
    base_objective = maximum(exact_case_objective, base_cases)
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    refit_weights, approximate_objective =
        optimized_subset_weights_hardgate(
            search_context(base_model),
            collect(1:length(base_model.shortwave_weights));
            initial_weights = base_model.shortwave_weights,
            max_iterations = post_weight_bounded_weight_refit_iterations(),
        )
    refit_model = with_shortwave_weights(base_model, refit_weights)
    refit_cases = [case_metrics(case, refit_model) for case in REDUCED_CASES]
    refit_objective = maximum(exact_case_objective, refit_cases)
    refit_toa = maximum(case.toa_forcing_max_abs for case in refit_cases)
    refit_surface = maximum(case.surface_forcing_max_abs for case in refit_cases)
    surface_cap = post_weight_bounded_weight_surface_cap()
    toa_tolerance = post_weight_bounded_weight_toa_tolerance()
    accepted = refit_objective < base_objective &&
        refit_toa <= base_toa + toa_tolerance &&
        refit_surface <= surface_cap
    return (
        case = "reduced_ecckd_retained_post_weight_bounded_weight_refit",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = accepted ? "retained_post_weight_bounded_weight_refit_improved" :
                 "retained_post_weight_bounded_weight_refit_rejected",
        iterations = post_weight_bounded_weight_refit_iterations(),
        surface_cap_w_m2 = surface_cap,
        toa_tolerance_w_m2 = toa_tolerance,
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

function retained_post_weight_bounded_weight_refit_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Post-Weight Bounded Weight Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Iterations | $(result.iterations) |",
        "| Surface cap | $(@sprintf("%.12g", result.surface_cap_w_m2)) W m^-2 |",
        "| TOA tolerance | $(@sprintf("%.12g", result.toa_tolerance_w_m2)) W m^-2 |",
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
        "This diagnostic refits shortwave quadrature weights after the post-weight",
        "surface-table update. It accepts objective and TOA improvements while",
        "enforcing the configured absolute surface-forcing cap.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? retained_post_weight_bounded_weight_refit_result() : result
    mkpath(dirname(RETAINED_POST_WEIGHT_BOUNDED_WEIGHT_REFIT_JSON))
    write(RETAINED_POST_WEIGHT_BOUNDED_WEIGHT_REFIT_JSON, json_object(result) * "\n")
    write(RETAINED_POST_WEIGHT_BOUNDED_WEIGHT_REFIT_MD,
          retained_post_weight_bounded_weight_refit_markdown(result))
    print(retained_post_weight_bounded_weight_refit_markdown(result))
    println("Wrote $RETAINED_POST_WEIGHT_BOUNDED_WEIGHT_REFIT_JSON")
    println("Wrote $RETAINED_POST_WEIGHT_BOUNDED_WEIGHT_REFIT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
