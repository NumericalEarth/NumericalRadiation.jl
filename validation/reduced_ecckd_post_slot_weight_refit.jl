include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_slot_blend_refinement.jl"))

const POST_SLOT_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_post_slot_weight_refit.json")
const POST_SLOT_WEIGHT_REFIT_MD =
    validation_results_path("reduced_ecckd_post_slot_weight_refit.md")

post_slot_weight_refit_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_POST_SLOT_WEIGHT_REFIT_ITERATIONS", "12"))

function post_slot_weight_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_blends = latest_slot_blend_refinement_moves()
    base_model = slot_blend_model(full_model, base_blends; include_existing = false)
    current_logits = logits_from_weights(base_model.shortwave_weights)
    initial_objective, initial_cases = exact_weight_objective(base_model, current_logits)
    current_objective = initial_objective
    best_logits = copy(current_logits)
    trajectory = NamedTuple[]

    for iteration in 1:post_slot_weight_refit_iterations()
        scan = exact_weight_coordinate_scan(base_model, best_logits, current_objective)
        accepted = scan.best.objective < current_objective
        push!(trajectory, (
            iteration = iteration,
            initial_objective = current_objective,
            best_local_index = scan.best.local_index,
            best_step = scan.best.step,
            best_direction = scan.best.direction,
            best_objective = scan.best.objective,
            best_improvement = current_objective - scan.best.objective,
            accepted = accepted,
        ))
        accepted || break
        direction = scan.best.direction == "negative" ? -1.0 : 1.0
        best_logits[scan.best.local_index] += direction * scan.best.step
        current_objective = scan.best.objective
    end

    final_weights = weights_from_logits(best_logits)
    final_model = with_shortwave_weights(base_model, final_weights)
    final_cases = [case_metrics(case, final_model) for case in REDUCED_CASES]
    final_objective = maximum(exact_case_objective, final_cases)
    return (
        case = "reduced_ecckd_post_slot_weight_refit",
        status = final_objective < initial_objective ?
                 "post_slot_weight_refit_improved" :
                 "post_slot_weight_refit_rejected",
        base_blend_count = length(base_blends),
        iterations_requested = post_slot_weight_refit_iterations(),
        iterations_completed = length(trajectory),
        steps = exact_weight_refit_steps(),
        initial_objective = initial_objective,
        final_objective = final_objective,
        objective_reduction = initial_objective - final_objective,
        accepted = final_objective < initial_objective,
        initial_weights = collect(base_model.shortwave_weights),
        final_weights = collect(final_weights),
        initial_cases = initial_cases,
        final_cases = final_cases,
        trajectory = trajectory,
    )
end

function post_slot_weight_refit_markdown(result)
    initial_toa = maximum(case.toa_forcing_max_abs for case in result.initial_cases)
    initial_surface = maximum(case.surface_forcing_max_abs for case in result.initial_cases)
    final_toa = maximum(case.toa_forcing_max_abs for case in result.final_cases)
    final_surface = maximum(case.surface_forcing_max_abs for case in result.final_cases)
    lines = String[
        "# Reduced ecCKD Post-Slot Weight Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base blend count | $(result.base_blend_count) |",
        "| Iterations requested | $(result.iterations_requested) |",
        "| Iterations completed | $(result.iterations_completed) |",
        "| Initial objective | $(@sprintf("%.12g", result.initial_objective)) |",
        "| Final objective | $(@sprintf("%.12g", result.final_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Accepted | $(result.accepted) |",
        "| Initial worst TOA forcing | $(@sprintf("%.12g", initial_toa)) W m^-2 |",
        "| Initial worst surface forcing | $(@sprintf("%.12g", initial_surface)) W m^-2 |",
        "| Final worst TOA forcing | $(@sprintf("%.12g", final_toa)) W m^-2 |",
        "| Final worst surface forcing | $(@sprintf("%.12g", final_surface)) W m^-2 |",
        "",
        "This diagnostic refits only the 16 shortwave weights after the accepted",
        "slot-blend state and accepts only if the exact nonlinear hard objective",
        "improves.",
    ]
    return join(lines, "\n") * "\n"
end

function write_post_slot_weight_refit_artifacts(result)
    mkpath(dirname(POST_SLOT_WEIGHT_REFIT_JSON))
    write(POST_SLOT_WEIGHT_REFIT_JSON, json_object(result) * "\n")
    write(POST_SLOT_WEIGHT_REFIT_MD, post_slot_weight_refit_markdown(result))
    print(post_slot_weight_refit_markdown(result))
    println("Wrote $POST_SLOT_WEIGHT_REFIT_JSON")
    println("Wrote $POST_SLOT_WEIGHT_REFIT_MD")
end

function main(; result = nothing)
    write_post_slot_weight_refit_artifacts(
        result === nothing ? post_slot_weight_refit_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
